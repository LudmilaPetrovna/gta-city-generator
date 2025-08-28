#define _GNU_SOURCE
#include <string.h>

#include <stdio.h>
#include <ctype.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define DUMMY_SAMPLERATE 8000
#define REPACKED_SAMPLE_RATE 8000
#define STREAM_FULLHEADER_SIZE 8068

typedef struct{
uint32_t pack_id,meta_offset,audio_len;
}STLK;

void gen_dummy(){
system("echo \"zz z  zz  z z z z zzzz   z z z z  z27834569237465 2398475 69237845692387456293745692348752369457623 \" | ffmpeg -v 0 -f s8 -ac 1 -ar 80 -i - -t 1 -ac 1 -ar 8000 -qscale:a 0 -compression_level 10 -application voip -map_metadata -1 -y dummy0.ogg");
system("oggz-comment -d -a dummy0.ogg -o dummy.ogg");
unlink("dummy0.ogg");

system("ffmpeg -ss 100 -f s16le -ac 1 -ar 8000 -i /proc/kcore -af volume=3 -ab 8000 -t 1 -y dummy.ogg");

}

void gen_dummy_pack(char *filename, uint8_t *dummy, int dummy_len, uint8_t *key){
int q,p=0;
static uint8_t buf[8068];
uint32_t *beats=(uint32_t*)buf;
memset(buf,0,sizeof(buf));
for(q=0;q<1000;q++){
beats[q*2]=0xFFFFFFFF;
}
beats[2000]=dummy_len;
beats[2001]=DUMMY_SAMPLERATE; // 8000 hz of dummy
for(q=2002;q<2016;q++){
beats[q]=0xCDCDCDCD;
}
beats[2016]=0xCDCD0001;

for(q=0;q<STREAM_FULLHEADER_SIZE;q++){
buf[q]^=key[p&0xF];
p++;
}

FILE *out=fopen(filename,"wb");
fwrite(buf,1,STREAM_FULLHEADER_SIZE,out);

memcpy(buf,dummy,dummy_len);

for(q=0;q<dummy_len;q++){
buf[q]^=key[p&0xF];
p++;
}
fwrite(buf,1,dummy_len,out);

fclose(out);
}

void hexdump(const void *buf, size_t len) {
    const unsigned char *p = buf;
    for (size_t i = 0; i < len; i += 16) {
        printf("%08zx  ", i);
        for (size_t j = 0; j < 16; j++) {
            if (i + j < len)
                printf("%02x ", p[i + j]);
            else
                printf("   ");
        }
        printf("|");
        for (size_t j = 0; j < 16 && i + j < len; j++) {
            unsigned char c = p[i + j];
            printf("%c", isprint(c) ? c : '.');
        }
        printf("\n");
    }
}

uint32_t crc32_slow(const void *data, size_t length) {
    uint32_t crc = 0xFFFFFFFF;
    const uint8_t *buf = data;
    for (size_t i = 0; i < length; i++) {
        crc ^= buf[i];
        for (int j = 0; j < 8; j++)
            crc = (crc >> 1) ^ (0xEDB88320 & -(crc & 1));
    }
    return ~crc;
}


void read_file_to_pointer(char *filepath, uint8_t **dst, int *outsize){
int f=open(filepath,O_RDONLY);
struct stat st;
fstat(f,&st);
int filesize=(int)st.st_size;
uint8_t *file=malloc(filesize);
read(f,file,filesize);
close(f);
*dst=file;
if(outsize){
*outsize=filesize;
}
}

void extract_key(char *filepath, uint8_t *dst){
uint8_t sigs[]={0xEA,0x3B,0xC6,0xC6,0x44,0x24};
uint8_t fsign[16];
uint8_t *file;
int filesize;
int q,w;

read_file_to_pointer(filepath,&file,&filesize);

for(q=0;q<3;q++){
for(w=0;w<3;w++){
fsign[q*5+w]=sigs[w+3];
}
fsign[q*5+3]=q+8;
fsign[q*5+4]=sigs[q];
}

uint8_t *h1=memmem(file,filesize,fsign,15);
int offset=h1-file;
printf("pointer:%p, offset:%d\n",h1,offset);
if(offset==0xf0b5d){printf("Version 1.0US detected\n");}

for(q=0;q<16;q++){
dst[q]=q^file[offset+q*5+4];
}
free(file);
}

int main(int argc, char *argv[]) {

gen_dummy();
mkdir("repack",0777);
mkdir("repack/CONFIG",0777);
mkdir("repack/streams",0777);
mkdir("tmp",0777);

uint8_t key[16];
extract_key("gta_sa.exe",key);


uint8_t *dummy;
int dummy_len;
read_file_to_pointer("dummy.ogg",&dummy,&dummy_len);

uint8_t *strm_packs;
read_file_to_pointer("/root/GTASA_DIST/audio/CONFIG/StrmPaks.dat",&strm_packs,NULL);

uint8_t *strm_lk;
int strm_lklen;

read_file_to_pointer("/root/GTASA_DIST/audio/CONFIG/TrakLkup.dat",&strm_lk,&strm_lklen);
STLK *ti, *to;

uint8_t *repacked_lk=malloc(strm_lklen);
int repacked_pos=0;

uint8_t buf[BUFSIZ];
uint8_t beats[8000];
uint8_t header[68];
int l1,l2;
int q,p=0;
int pk;
int ok;
uint32_t *num;
uint32_t beats_sum,header_sum;


char *pack_name;
char stream_filename[1024];
char out_filename[1024];
int is_repack;
int last_pack=-1;
FILE *fi=NULL;
FILE *fo=NULL;
FILE *tmp_ogg;

while(p<strm_lklen){
ti=(STLK*)&strm_lk[p];
to=(STLK*)&repacked_lk[p];
ti->pack_id&=0xFF;
pack_name=(char*)&strm_packs[ti->pack_id*16];

if(last_pack!=ti->pack_id){
last_pack=ti->pack_id;
is_repack=ti->pack_id==3 || ti->pack_id==4?1:0;  /* AMBIENT or BEATS*/
sprintf(stream_filename,"/root/GTASA_DIST/audio/streams/%s",pack_name);
sprintf(out_filename,"repack/streams/%s",pack_name);
if(fi){
fclose(fi);
}
fi=fopen(stream_filename,"rb");
if(!is_repack){ //write dummy file
gen_dummy_pack(out_filename,dummy,dummy_len,key);
} else {
if(fo){
fclose(fo);
}
fo=fopen(out_filename,"wb");
repacked_pos=0;
ok=0;
}
}


// calc beat sum

fseek(fi,ti->meta_offset,SEEK_SET);
fread(beats,1,8000,fi);
fread(header,1,68,fi);
pk=ti->meta_offset;
for(q=0;q<8000;q++){
beats[q]^=key[pk&0xf];
pk++;
}
for(q=0;q<68;q++){
header[q]^=key[pk&0xf];
pk++;
}

beats_sum=crc32_slow(beats,8000);
header_sum=crc32_slow(header,68);

// print info
printf("sound at %d, pack: %d (%s), beats: %08x, header:%08x, offset: %d, len: %d\n",p/12,ti->pack_id,pack_name,beats_sum,header_sum,ti->meta_offset,ti->audio_len);


if(!is_repack){
to->pack_id=ti->pack_id|0xCDCDCD00;
to->meta_offset=0;
to->audio_len=dummy_len;
}

if(is_repack){

sprintf(out_filename,"tmp/%s_%d.ogg",pack_name,p/12);


struct stat tmp_stat;
if(stat(out_filename,&tmp_stat)!=0){

// unpack first
tmp_ogg=fopen(out_filename,"wb");
fseek(fi,ti->meta_offset+8068,SEEK_SET);
int len=ti->audio_len;
int chunk;
pk=ti->meta_offset+8068;
while(len>0){
chunk=len;
if(chunk>BUFSIZ){
chunk=BUFSIZ;
}
l1=fread(buf,1,chunk,fi);
for(q=0;q<l1;q++){
buf[q]^=key[pk&0xf];
pk++;
}
l2=fwrite(buf,1,l1,tmp_ogg);
if(l1!=l2 || l1!=chunk){
abort();
}

len-=l1;
}

fclose(tmp_ogg);

static char repack_cmd[10240];
sprintf(repack_cmd,"perl repack_track.pl %d %d \"%s\"",REPACKED_SAMPLE_RATE,ti->pack_id,out_filename);
printf("command: \"%s\"\n",repack_cmd);
system(repack_cmd);
}

// then pack again...

num=(uint32_t*)header;

uint8_t *repacked_file;
int repacked_file_len=0;
read_file_to_pointer(out_filename,&repacked_file,&repacked_file_len);

num[0]=repacked_file_len;
num[1]=REPACKED_SAMPLE_RATE;
for(q=2;q<16;q++){
num[q]=0xCDCDCDCD;
}
num[16]=0xCDCD0001;

for(q=0;q<8000;q++){
beats[q]^=key[ok&0xf];
ok++;
}

for(q=0;q<68;q++){
header[q]^=key[ok&0xf];
ok++;
}

for(q=0;q<repacked_file_len;q++){
repacked_file[q]^=key[ok&0xf];
ok++;
}

fwrite(beats,1,8000,fo);
fwrite(header,1,68,fo);
fwrite(repacked_file,1,repacked_file_len,fo);
free(repacked_file);

to->pack_id=ti->pack_id|0xCDCDCD00;
to->meta_offset=repacked_pos;
to->audio_len=repacked_file_len;
repacked_pos+=repacked_file_len+STREAM_FULLHEADER_SIZE;

}


p+=12;
}


fclose(fi);
if(fo){
fclose(fo);
}

FILE *out_lk=fopen("repack/CONFIG/TrakLkup.dat","wb");
fwrite(repacked_lk,1,strm_lklen,out_lk);
fclose(out_lk);

return 0;
}

















