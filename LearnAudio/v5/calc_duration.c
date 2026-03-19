#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/stat.h>

#define SILENCE_THRESHOLD 24000  // 48000 / 2

int main(int argc, char **argv)
{
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input.pcm>\n", argv[0]);
        return 1;
    }

    const char *filename = argv[1];

    // --- stat ---
    struct stat st;
    if (stat(filename, &st) != 0) {
        perror("stat");
        return 1;
    }

    if (!S_ISREG(st.st_mode)) {
        fprintf(stderr, "Error: not a regular file\n");
        return 1;
    }

    off_t file_size = st.st_size;

    if (file_size <= 0) {
        fprintf(stderr, "Error: empty file\n");
        return 1;
    }

    // проверка кратности 2 (s16)
    if (file_size % 2 != 0) {
        fprintf(stderr, "Error: file size is not aligned to 16-bit samples\n");
        return 1;
    }

    size_t total_samples = (size_t)(file_size / 2);

    // --- читаем файл ---
    FILE *f = fopen(filename, "rb");
    if (!f) {
        perror("fopen");
        return 1;
    }

    int16_t *data = (int16_t *)malloc((size_t)file_size);
    if (!data) {
        fprintf(stderr, "Memory allocation failed\n");
        fclose(f);
        return 1;
    }

    size_t read = fread(data, 1, (size_t)file_size, f);
    fclose(f);

    if (read != (size_t)file_size) {
        fprintf(stderr, "Error reading file\n");
        free(data);
        return 1;
    }

    // --- анализ ---

    size_t leading_zeros = 0;
    size_t trailing_zeros = 0;
    int silence_flag = 0;
    int useful_length = 0;
    size_t first_nonzero = -1;

    // нули в начале
    while (leading_zeros < total_samples && data[leading_zeros] == 0) {
        leading_zeros++;
    }

    // нули в конце
    while (trailing_zeros < total_samples &&
           data[total_samples - 1 - trailing_zeros] == 0) {
        trailing_zeros++;
    }

    first_nonzero = leading_zeros;

    useful_length = total_samples - leading_zeros - trailing_zeros;

    int q;
int cursilence=0;
for(q=first_nonzero;q<useful_length;q++){
if(data[q]==0){cursilence++;} else {
if(cursilence>SILENCE_THRESHOLD){
silence_flag=1;
}
cursilence=0;
}

}

    free(data);
printf("%d %d %d %d %d %d\n",total_samples,leading_zeros,trailing_zeros,first_nonzero,useful_length,silence_flag);

/*
    // --- вывод ---
    printf("total_samples=%zu\n", total_samples);
    printf("leading_zeros=%zu\n", leading_zeros);
    printf("trailing_zeros=%zu\n", trailing_zeros);
    printf("first_nonzero=%zu\n", first_nonzero);
    printf("useful_length=%zu\n", useful_length);
    printf("silence_flag=%d\n", silence_flag);
*/


    return 0;
}
