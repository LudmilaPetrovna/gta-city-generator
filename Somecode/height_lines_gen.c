#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#define SIZE 6000
#define SIZEM2 (SIZE*SIZE)

#define OUTSIDE 3072
#define OUTAREA (OUTSIDE*OUTSIDE)
#define OUTTILE_SIDE 256
#define OUTTILE_SIDE_COUNT 12

float *inpix;
uint32_t *outpix;

float devs[]={1000,500,100,50, 20, 10, 5,  2.5, 1, 0.1};
int colors[]={255, 255,210,180,170,140,100,50,  40,30};
int radius[]={2,   2,  2,  2,  1,  1,  1,  1,   1, 1};

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

int main(void){
FILE *in=fopen("heightmap.bin","rb");
FILE *out=fopen("heightlines.gray","wb");
inpix=malloc(SIZEM2*4);
outpix=malloc(OUTAREA*4);
fread(inpix,1,SIZEM2*4,in);
memset(outpix,0,OUTAREA*4);

int d,q,w,e,op,p,ox,oy;
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
for(d=0;d<sizeof(colors)/sizeof(colors[0]);d++){
dev=devs[d];
color=colors[d]|(colors[d]<<8)|(colors[d]<<16)|0xFF000000;
printf("Pass %d, devider: %f\n",d,dev);
for(w=0;w<SIZE;w++){
for(q=0;q<SIZE;q++){
for(e=0;e<4;e++){
if(q && w){
sm[e]=inpix[q+matrix[e][0]+(w+matrix[e][1])*SIZE];
sign=sm[e]<0?-1:1;
sm[e]=(int)(sm[e]/dev);
if(d==0 && sign<0){
sm[e]-=10;
}
} else {
sm[e]=(int)(inpix[q+w*SIZE]/dev);
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



printf("Writing output...\n");
// write result
fwrite(outpix,1,OUTAREA*4,out);
fclose(in);
fclose(out);

char cmd[256];
sprintf(cmd,"ffmpeg -f rawvideo -pix_fmt bgra -s %dx%d -i heightlines.gray -y test.png",OUTSIDE,OUTSIDE);
system(cmd);

return 0;
}

