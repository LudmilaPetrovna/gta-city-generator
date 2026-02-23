#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <stdlib.h>

#define FREQ 440.0
#define DUR 15
#define SAMPLERATE 48000


int main(){
int16_t *samples=malloc(SAMPLERATE*DUR*2);
int len=SAMPLERATE*DUR;
int q,sample;
for(q=0;q<len;q++){

sample=sin((double)q*FREQ/SAMPLERATE*2.0*M_PI)*32768.0;
if(sample>32767){sample=32767;}
if(sample<-32768){sample=-32768;}
samples[q]=sample;
}

fwrite(samples,2,len,stdout);

return 0;
}