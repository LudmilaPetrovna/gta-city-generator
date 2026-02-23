#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mad.h>

#define INPUT_BUFFER_SIZE  (5*8192)
#define OUTPUT_BUFFER_SIZE 8192

static signed short mad_fixed_to_s16(mad_fixed_t sample)
{
    /* Clipping */
    if (sample >= MAD_F_ONE)
        sample = MAD_F_ONE - 1;
    if (sample < -MAD_F_ONE)
        sample = -MAD_F_ONE;

    /* Convert from fixed point to signed 16-bit */
    sample = sample >> (MAD_F_FRACBITS + 1 - 16);
    return (signed short)sample;
}

int main(int argc, char *argv[])
{
    if (argc != 3) {
        fprintf(stderr, "Usage: %s input.mp3 output.pcm\n", argv[0]);
        return 1;
    }

    FILE *fin  = fopen(argv[1], "rb");
    FILE *fout = fopen(argv[2], "wb");

    if (!fin || !fout) {
        perror("File open error");
        return 1;
    }

    unsigned char input_buffer[INPUT_BUFFER_SIZE + MAD_BUFFER_GUARD];
    size_t read_size, remaining = 0;

    struct mad_stream stream;
    struct mad_frame frame;
    struct mad_synth synth;

    mad_stream_init(&stream);
    mad_frame_init(&frame);
    mad_synth_init(&synth);

    while (1) {
        if (stream.buffer == NULL || stream.error == MAD_ERROR_BUFLEN) {

            memmove(input_buffer, stream.next_frame, remaining);

            read_size = fread(input_buffer + remaining, 1,
                              INPUT_BUFFER_SIZE - remaining, fin);

            if (read_size == 0) {
                memset(input_buffer + remaining, 0, MAD_BUFFER_GUARD);
                read_size = MAD_BUFFER_GUARD;
break;
            }

            mad_stream_buffer(&stream, input_buffer,
                              read_size + remaining);

            stream.error = MAD_ERROR_NONE;
            remaining = 0;
        }

        if (mad_frame_decode(&frame, &stream)) {

            if (MAD_RECOVERABLE(stream.error))
                continue;

            if (stream.error == MAD_ERROR_BUFLEN)
                continue;

            fprintf(stderr, "Unrecoverable error: %s\n",
                    mad_stream_errorstr(&stream));
            break;
        }

        mad_synth_frame(&synth, &frame);

        unsigned int nsamples = synth.pcm.length;
        unsigned int nchannels = synth.pcm.channels;

        for (unsigned int i = 0; i < nsamples; i++) {
            for (unsigned int ch = 0; ch < nchannels; ch++) {

                signed short s =
                    mad_fixed_to_s16(synth.pcm.samples[ch][i]);

                fwrite(&s, sizeof(s), 1, fout);
            }
        }
    }

    mad_synth_finish(&synth);
    mad_frame_finish(&frame);
    mad_stream_finish(&stream);

    fclose(fin);
    fclose(fout);

    return 0;
}
