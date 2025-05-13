#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

#define SIZE 6000
#define SIZEM2 (SIZE*SIZE)

#define OUTSIDE 3072
#define OUTAREA (OUTSIDE*OUTSIDE)
#define OUTTILE_SIDE 256
#define OUTTILE_SIDE_COUNT 12

float *inpix;
uint32_t *outpix;
uint32_t *rawlayer;

float devs[]={1000,500,100,50, 20, 10, 5,  2.5, 1, 0.1};
int colors[]={255, 255,210,180,170,140,100,50,  40,30};
int radius[]={2,   2,  2,  2,  1,  1,  1,  1,   1, 1};

uint32_t *colorize;
uint32_t gradients[][2]={
{0xfd0acf,0x1bfa99},
{0x0868a1,0xb27d98},
{0xbcdee2,0x574cad},
{0xf47860,0x9a8022},
{0x3c0484,0xb5b071},
{0xd11b34,0x3b1368},
{0xae773f,0x36a37a},
{0x74225a,0x5c00ab},
{0x700b06,0x3d4269},
{0x0408e0,0x5d4dce},
{0x1dec7f,0xe88d1c},
{0x482c42,0xb20f09},
{0xff7b71,0x29df14},
{0xbf3ea5,0x18b34d},
{0x1028fa,0xb59de2},
{0x408ab9,0x147b54},
{0x9d6eab,0x25ac5b},
{0xc8b4f3,0xbd60ba},
{0x9a6620,0xd7e279},
{0x7bfd3e,0x867b42},
{0xbd4539,0x25758a},
{0xfdf9d4,0xf75838},
{0x069647,0xf508f6},
{0x1e7e39,0xe3b59c},
{0xc56f71,0xda6795},
{0x0f04ef,0x5b62e5},
{0xf7d552,0x6058f9},
{0x6f8ba3,0xe388f0},
{0x4707e0,0xed676c},
{0xdde7e0,0xab9d86},
{0x85c90d,0xfec4df}
};


void save_image(uint32_t *pic,char *filename){
printf("Writing output image \"%s\"...\n",filename);
FILE *out=fopen("heightlines.gray","wb");
fwrite(pic,1,OUTAREA*4,out);
fclose(out);

char cmd[256];
sprintf(cmd,"ffmpeg -f rawvideo -pix_fmt bgra -s %dx%d -i heightlines.gray -y %s",OUTSIDE,OUTSIDE,filename);
system(cmd);
}

void draw_point(int ox, int oy, int color, int r){
int a,s,p,r2=r*3,len;
ox=ox*OUTSIDE/SIZE;
oy=oy*OUTSIDE/SIZE;
if(ox<0 || ox>=OUTSIDE || oy<0 || oy>=OUTSIDE){return;}
p=ox+oy*OUTSIDE;
if(outpix[p]){return;}
for(s=-r2;s<=r2;s++){
for(a=-r2;a<=r2;a++){
if(ox+a<0 || ox+a>=OUTSIDE || oy+s<0 || oy+s>=OUTSIDE){continue;}
p=ox+a+(oy+s)*OUTSIDE;
if(outpix[p] && outpix[p]!=color){return;}
}
}

if(r>1){
/*
for(s=-r;s<=r;s++){
for(a=-r;a<=r;a++){
if(ox+a<0 || ox+a>=SIZE || oy+s<0 || oy+s>=SIZE){continue;}
len=(int)(sqrt(pow(a,2)+pow(s,2))+.5);
if(len>r){continue;}
p=ox+a+(oy+s)*SIZE;
outpix[p]=color;
}
}
*/

for(s=0;s<r;s++){
for(a=0;a<r;a++){
if(ox+a<0 || ox+a>=OUTSIDE || oy+s<0 || oy+s>=OUTSIDE){continue;}
p=ox+a+(oy+s)*OUTSIDE;
outpix[p]=color;
}
}



}

p=ox+oy*OUTSIDE;
outpix[p]=color;

}

void gen_colorize(){
int q,e;
int sr,sg,sb;
int tr,tg,tb;
int r,g,b;
float ph,iph;

colorize=malloc(2000*4);

for(q=0;q<2000;q++){
e=q/100;
ph=(double)(q%100)/100.0;
iph=1.0-ph;
sr=(gradients[e][0]>>16)&0xFF;
sg=(gradients[e][0]>>8)&0xFF;
sb=(gradients[e][0]&0xFF);

tr=(gradients[e][1]>>16)&0xFF;
tg=(gradients[e][1]>>8)&0xFF;
tb=(gradients[e][1]&0xFF);

r=(int)((double)sr*iph+(double)tr*ph);
g=(int)((double)sg*iph+(double)tg*ph);
b=(int)((double)sb*iph+(double)tb*ph);
#define clamp(v,min,max) if(v<min){v=min;}if(v>max){v=max;}

clamp(r,0,255);
clamp(g,0,255);
clamp(b,0,255);
#undef clamp
colorize[q]=r<<16|(g<<8)|(b)|0xFF000000;
}
}


int main(void){
char filename[256];
int d,q,w,e,op,p,ox,oy;

srand(time(0));

inpix=malloc(SIZEM2*4);
outpix=malloc(OUTAREA*4);
rawlayer=malloc(OUTAREA*4);
memset(outpix,0,OUTAREA*4);
FILE *in=fopen("heightmap.bin","rb");
fread(inpix,1,SIZEM2*4,in);
fclose(in);

gen_colorize();



float dev=10;
float sm[4];
int matrix[][2]={
{-1,-1},
{0,-1},
{-1,0},
{0,0}
};

int sign;
uint32_t color;

// draw gradient filler
for(w=0;w<SIZE;w++){
for(q=0;q<SIZE;q++){
color=(int)((inpix[q+w*SIZE]+1000.0));
if(color<0){color=0;}
if(color>=2000){color=1999;}
ox=q*OUTSIDE/SIZE;
oy=(6000-1-w)*OUTSIDE/SIZE;
rawlayer[ox+oy*OUTSIDE]=colorize[color];
}
}
save_image(rawlayer,"filler.png");

exit(0);
for(d=0;d<sizeof(colors)/sizeof(colors[0]);d++){
dev=devs[d];
printf("Pass %d, devider: %f\n",d,dev);

// draw raw layer
for(w=0;w<SIZE;w++){
for(q=0;q<SIZE;q++){
color=(int)((inpix[q+w*SIZE]+1000.0)/dev);
color=color&1?0xFF:0;
color=color|(color<<8)|(color<<16)|0xFF000000;
ox=q*OUTSIDE/SIZE;
oy=(6000-1-w)*OUTSIDE/SIZE;
rawlayer[ox+oy*OUTSIDE]=color;
}
}
sprintf(filename,"layer-%d.png",d);
save_image(rawlayer,filename);

color=colors[d]|(colors[d]<<8)|(colors[d]<<16)|0xFF000000;
// draw isolines
for(w=0;w<SIZE;w++){
for(q=0;q<SIZE;q++){
for(e=0;e<4;e++){
if(q && w){
sm[e]=(int)((inpix[q+matrix[e][0]+(w+matrix[e][1])*SIZE]+1000.0)/dev);
} else {
sm[e]=(int)((inpix[q+w*SIZE]+1000.0)/dev);
}

//if(sm[e]>3){sm[e]=0;}
//if(sm[e]<0){sm[e]=0;}

}

// sm0 sm1
// sm2 sm3

#define dd(op) ox=q+matrix[op][0];oy=SIZE-1-(w+matrix[op][1]);draw_point(ox,oy,color,radius[d]);

if(sm[0]<sm[3]){dd(0);}
if(sm[0]>sm[3]){dd(3);}
if(sm[1]<sm[2]){dd(1);}
if(sm[1]>sm[2]){dd(2);}
if(sm[0]<sm[1]){dd(0);}
if(sm[0]>sm[1]){dd(1);}
if(sm[0]<sm[2]){dd(0);}
if(sm[0]>sm[2]){dd(2);}
#undef dd

}
}
}

/*
// make contrask outline
printf("Creating contrast outline...\n");
int luma,lumamax;
int a,s;
for(w=0;w<OUTSIDE;w++){
for(q=0;q<OUTSIDE;q++){
if(outpix[q+w*OUTSIDE]){continue;}
lumamax=0;
for(s=-1;s<=1;s++){
for(a=-1;a<=1;a++){
p=q+a+(w+s)*OUTSIDE;
if(p<0||p>OUTAREA){continue;}
if((outpix[p]>>24)!=0xFF){continue;}
luma=outpix[p]&0xFF;
if(lumamax<luma){lumamax=luma;}
}
}
if(!lumamax){continue;}
luma=lumamax>128?255:0;
color=luma|(luma<<8)|(luma<<16)|0x11000000;
//color=lumamax>128?0x55FF0000:0x5500FF00;
outpix[q+w*OUTSIDE]=color;
}
}
*/

save_image(outpix,"test.png");


return 0;
}

