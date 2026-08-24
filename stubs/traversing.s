section .data
dir_path db "/tmp/test", 0, 10


section .text
global _start

;1- get the path
;2- open the path using open and then passing the fd to getdent syscall 
;3- parse the getdent struct and traverse it
_start:
   mov rax, 2
   mov rdi, dir_path
   mov rsi, 0x10000
   syscall
   cmp rax, 0
   je error_exit
   ;reading the directory
   mov r14, rax ;directory fd
   sub rsp, 1024 ;buffer allocation
   mov rax, 78 ;getdent64
   mov rdi, r14 ;fd
   mov rsi, rsp ;buffer pointer
   mov rdx, 1024 ;buffer size
   syscall
   cmp rax, 0
   jel error_exit_dir_open
   mov r13, rax ;size of files/dirs read in the directory
    xor r12, r12
files_processing:
    cmp r12, r13
    jge do_something
    mov rcx, [r12 + offset_to_size_of_file]
    mov rax, [r12 + offset_to_file_type]
    cmp rax, file_type 
    jne files_processing
    mov r10, rax
    mov rax, 257 ;openat
    mov rdi, r14 ;directory fd
    mov rsi, r10
    mov rdx, 2 ;O_WRITE might be wrong but you get the idea
    syscall
    cmp rax, 0
    jl error_exit
    ;parse the file

error_exit:
    mov rax, 60
    mov rdi, 1
    syscall
error_exit_dir_open
    add rsp, 1024
    jmp error_exit


