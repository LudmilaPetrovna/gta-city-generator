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

uint8_t key[16];
extract_key("/dev/shm/t/gta/Grand Theft Auto - San Andreas/gta_sa.exe",key);

uint8_t *strm_packs;
read_file_to_pointer("/root/GTASA_DIST/audio/CONFIG/StrmPaks.dat",&strm_packs,NULL);

uint8_t *strm_lk;
int strm_lklen;

read_file_to_pointer("/root/GTASA_DIST/audio/CONFIG/TrakLkup.dat",&strm_lk,&strm_lklen);
STLK *ti;

uint8_t buf[BUFSIZ];
uint8_t header[68];
int l1,l2;
int q,p=0;
int pk;
//int ok;
uint32_t *num;
int last_endpost;
//int is_beat;

char *pack_name;
char stream_filename[1024];
char out_filename[1024];
char opus_filename[1024];
//int is_repack;
int last_pack=-1;
FILE *fi=NULL;
//FILE *fo=NULL;
FILE *tmp_ogg;

while(p<strm_lklen){
ti=(STLK*)&strm_lk[p];
ti->pack_id&=0xFF;
pack_name=(char*)&strm_packs[ti->pack_id*16];

if(last_pack!=ti->pack_id){
last_pack=ti->pack_id;
sprintf(stream_filename,"/root/GTASA_DIST/audio/streams/%s",pack_name);
if(fi){
fclose(fi);
}
fi=fopen(stream_filename,"rb");
last_endpost=0;
}

fseek(fi,ti->meta_offset+8000,SEEK_SET);
fread(header,1,68,fi);
pk=ti->meta_offset+8000;
for(q=0;q<68;q++){
header[q]^=key[pk&0xf];
pk++;
}

num=(uint32_t*)header;
int infilesize=num[0];
int samplerate=num[1];
int endpos=ti->meta_offset+ti->audio_len+8068;
for(q=0;q<8;q++){
infilesize=num[q*2];
samplerate=num[q*2+1];
if(infilesize!=samplerate && samplerate!=0xcdcdcdcd){break;}
}

// print info
printf("sound at %d, pack: %d (%s), offset: %d, len: %d, inpacklen:%d, end: %d (diff %d), samplerate: %d\n",p/12,ti->pack_id,pack_name,
ti->meta_offset,ti->audio_len,infilesize,
endpos,ti->meta_offset-last_endpost,samplerate
);

last_endpost=endpos;

sprintf(out_filename,"%s_%d.ogg",pack_name,p/12);

struct stat tmp_stat;
if(stat(out_filename,&tmp_stat)!=0){

// unpack first
tmp_ogg=fopen(out_filename,"wb");
int len=infilesize;
int chunk;
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
printf("We expect: %d, we got %d, we wrote: %d\n",chunk,l1,l2);
abort();
}

len-=l1;
}

fclose(tmp_ogg);

}


p+=12;
}

fclose(fi);

return 0;
}

















