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
uint32_t *rawlayer;

float devs[]={1000,500,100,50, 20, 10, 5,  2.5, 1, 0.1};
int colors[]={255, 255,210,180,170,140,100,50,  40,30};
int radius[]={2,   2,  2,  2,  1,  1,  1,  1,   1, 1};


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

int main(void){
inpix=malloc(SIZEM2*4);
outpix=malloc(OUTAREA*4);
rawlayer=malloc(OUTAREA*4);
memset(outpix,0,OUTAREA*4);
FILE *in=fopen("heightmap.bin","rb");
fread(inpix,1,SIZEM2*4,in);
fclose(in);

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
char filename[256];
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

