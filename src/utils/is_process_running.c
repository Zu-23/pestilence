#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <stdlib.h>
#include <ctype.h>
#include "../../pestilence.h"
int is_process_running(const char *target_process)
{
    DIR *dir;
    struct dirent *ent;
    char path_buffer[512];
    char process_name[256];
    int exists = 0;

    dir = opendir("/proc");
    if (dir == NULL)
    {
        perror("Failed to open /proc");
        return 0;
    }
    while ((ent = readdir(dir)) != NULL)
    {
        int is_pid = 1;
        for (int i = 0; ent->d_name[i] != '\0'; i++)
        {
            if (!isdigit(ent->d_name[i]))
            {
                is_pid = 0;
                break;
            }
        }
        if (is_pid)
        {
            snprintf(path_buffer, sizeof(path_buffer), "/proc/%s/comm", ent->d_name);
            FILE *fp = fopen(path_buffer, "r");
            if (fp)
            {
                if (fgets(process_name, sizeof(process_name), fp) != NULL)
                {
                    process_name[strcspn(process_name, "\n")] = 0;
                    if (strcmp(process_name, target_process) == 0)
                    {
                        exists = 1;
                        fclose(fp);
                        break;
                    }
                }
                fclose(fp);
            }
        }
    }
    closedir(dir);
    return exists;
}

