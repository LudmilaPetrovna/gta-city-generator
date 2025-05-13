#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#define SIZE 6000
#define SIZEM2 (SIZE*SIZE)

float *inpix;
uint8_t *outpix;

float devs[]={1000,500,100,50, 10, 5, 2.5};
int colors[]={255, 255,210,180,140,100,70};
int radius[]={3,   2,  1,  1,  1,  1, 1};

void draw_point(int ox, int oy, int color, int r){
int a,s,p,r2=r*2,len;
if(ox<0 || ox>=SIZE || oy<0 || oy>=SIZE){return;}
p=ox+oy*SIZE;
if(outpix[p]){return;}
for(s=-r2;s<=r2;s++){
for(a=-r2;a<=r2;a++){
if(ox+a<0 || ox+a>=SIZE || oy+s<0 || oy+s>=SIZE){continue;}
p=ox+a+(oy+s)*SIZE;
if(outpix[p] && outpix[p]!=color){return;}
}
}

if(r>1){

for(s=-r;s<=r;s++){
for(a=-r;a<=r;a++){
if(ox+a<0 || ox+a>=SIZE || oy+s<0 || oy+s>=SIZE){continue;}
len=(int)(sqrt(pow(a,2)+pow(s,2))+.5);
if(len>r){continue;}
p=ox+a+(oy+s)*SIZE;
outpix[p]=color;
}
}

}

p=ox+oy*SIZE;
outpix[p]=color;

}

int main(void){
FILE *in=fopen("heightmap.bin","rb");
FILE *out=fopen("heightlines.gray","wb");
inpix=malloc(SIZEM2*4);
outpix=malloc(SIZEM2);
fread(inpix,1,SIZEM2*4,in);
memset(outpix,0,SIZEM2);

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
for(d=0;d<7;d++){
dev=devs[d];
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

#define dd(op) ox=q+matrix[op][0];oy=SIZE-1-(w+matrix[op][1]);draw_point(ox,oy,colors[d],radius[d]);

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

// pass shade levels
int shade;
for(w=0;w<SIZE;w++){
for(q=0;q<SIZE;q++){
shade=(int)(inpix[q+w*SIZE]/dev);
if(shade>3 || shade<0){shade=0;}
int shade_color=255-shade*75;
if(shade_color>200){shade_color=200;}
if(!outpix[q+(SIZE-w-1)*SIZE]){
//outpix[q+(SIZE-w-1)*SIZE]=shade_color;
}
}
}

// write result
fwrite(outpix,1,SIZEM2,out);
fclose(in);
fclose(out);

system("ffmpeg -f rawvideo -pix_fmt gray -s 6000x6000 -i heightlines.gray -y test.png");

return 0;
}

