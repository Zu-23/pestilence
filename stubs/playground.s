section .data
dir db "hello", 0


section .text
global _start

_start:
    mov rax, 1
    mov rdi, 1
    mov rsi, dir
    mov rdx, 6
    syscall