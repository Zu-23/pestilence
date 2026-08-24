#include<stdio.h>
#include<stdlib.h>
#include<string.h>

static void been_integrated(char *dst, const unsigned char *enc, size_t len, unsigned char key)
{
    for (size_t i = 0; i < len; i++)
        dst[i] = enc[i] ^ key;
    dst[len] = '\0';
}

int main()
{
  char *path;
    path = append_path("hello", "/tmp/test/", strlen("/tmp/test/"));
    printf("path %s\n", path);
} 

