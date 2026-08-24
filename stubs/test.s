; -----------------------------------------------------------------------------
; SYSTEM CALL DEFINITIONS
; -----------------------------------------------------------------------------
%define SYS_OPEN         2
%define SYS_OPENAT       257
%define SYS_CLOSE        3
%define SYS_FSTAT        5
%define SYS_MMAP         9
%define SYS_MUNMAP       11
%define SYS_EXIT         60
%define SYS_GETDENTS64   217

%define O_RDONLY         0
%define O_DIRECTORY      0x10000
%define DT_REG           8

%define PROT_READ        0x1
%define MAP_PRIVATE      0x2

; -----------------------------------------------------------------------------
; ELF CONSTANTS
; -----------------------------------------------------------------------------
%define ELFMAG0          0x7f
%define ELFMAG1          'E'
%define ELFMAG2          'L'
%define ELFMAG3          'F'
%define ELFCLASS64       2
%define PT_LOAD          1
%define PF_X             1

; -----------------------------------------------------------------------------
; LINUX DIRENT64 STRUCTURE
; -----------------------------------------------------------------------------
struc linux_dirent64
    .d_ino:    resq 1
    .d_off:    resq 1
    .d_reclen: resw 1
    .d_type:   resb 1
    .d_name:   resb 1
endstruc

; -----------------------------------------------------------------------------
; struct stat (only the fields we need — offsets match x86-64 Linux ABI)
; -----------------------------------------------------------------------------
struc stat_buf
    .st_dev:     resq 1
    .st_ino:     resq 1
    .st_nlink:   resq 1
    .st_mode:    resd 1
    .st_uid:     resd 1
    .st_gid:     resd 1
    .st_rdev:    resq 1
    .st_size:    resq 1
    resb 128        ; remaining fields we don't care about
endstruc

; -----------------------------------------------------------------------------
; Elf64_Ehdr
; -----------------------------------------------------------------------------
struc elf64_ehdr
    .e_ident:     resb 16
    .e_type:      resw 1
    .e_machine:   resw 1
    .e_version:   resd 1
    .e_entry:     resq 1
    .e_phoff:     resq 1
    .e_shoff:     resq 1
    .e_flags:     resd 1
    .e_ehsize:    resw 1
    .e_phentsize: resw 1
    .e_phnum:     resw 1
    .e_shentsize: resw 1
    .e_shnum:     resw 1
    .e_shstrndx:  resw 1
endstruc

; -----------------------------------------------------------------------------
; Elf64_Phdr
; -----------------------------------------------------------------------------
struc elf64_phdr
    .p_type:   resd 1
    .p_flags:  resd 1
    .p_offset: resq 1
    .p_vaddr:  resq 1
    .p_paddr:  resq 1
    .p_filesz: resq 1
    .p_memsz:  resq 1
    .p_align:  resq 1
endstruc

section .text
global _start

_start:
    push rbp
    mov rbp, rsp
    sub rsp, 1024 + stat_buf_size    ; getdents buffer + stat buffer

    ; local layout inside our stack frame:
    ;   [rsp .. rsp+1023]                 -> getdents64 buffer
    ;   [rsp+1024 .. rsp+1024+stat_size)  -> struct stat

    lea rdi, [rel dir_path]
    mov rax, SYS_OPEN
    mov rsi, O_RDONLY | O_DIRECTORY
    xor rdx, rdx
    syscall

    cmp rax, 0
    jl exit_error
    mov r12, rax                      ; r12 = directory fd

read_loop:
    mov rax, SYS_GETDENTS64
    mov rdi, r12
    mov rsi, rsp
    mov rdx, 1024
    syscall

    cmp rax, 0
    jle close_dir
    mov r13, rax
    xor r14, r14

process_entries:
    cmp r14, r13
    jge read_loop

    mov r15, rsp
    add r15, r14

    movzx rcx, word [r15 + linux_dirent64.d_reclen]

    mov al, byte [r15 + linux_dirent64.d_type]
    cmp al, DT_REG
    jne skip_entry

    lea rsi, [r15 + linux_dirent64.d_name]

    mov rax, SYS_OPENAT
    mov rdi, r12
    mov rdx, O_RDONLY
    xor r10, r10
    syscall

    cmp rax, 0
    jl skip_entry
    mov rbx, rax                      ; rbx = target file fd

parse_elf:
    ; ---- 1. fstat to get file size ----
    lea rsi, [rsp + 1024]             ; stat buffer
    mov rax, SYS_FSTAT
    mov rdi, rbx
    syscall

    cmp rax, 0
    jl close_target                   ; fstat failed, bail

    mov r8, [rsp + 1024 + stat_buf.st_size]
    cmp r8, elf64_ehdr_size
    jl close_target                   ; file too small to hold an ELF header

    ; ---- 2. mmap the file read-only ----
    xor rdi, rdi                      ; addr = NULL, let kernel choose
    mov rsi, r8                       ; length = file size
    mov rdx, PROT_READ
    mov r10, MAP_PRIVATE
    mov r8d, ebx                      ; fd (32-bit, upper bits cleared)
    xor r9, r9                        ; offset = 0
    mov rax, SYS_MMAP
    syscall

    cmp rax, 0
    jl close_target                   ; mmap failed
    mov r9, rax                       ; r9 = mapped base address
    mov r10, [rsp + 1024 + stat_buf.st_size] ; keep size around for munmap

    ; ---- 3. validate ELF magic ----
    cmp byte [r9 + elf64_ehdr.e_ident + 0], ELFMAG0
    jne unmap_and_close
    cmp byte [r9 + elf64_ehdr.e_ident + 1], ELFMAG1
    jne unmap_and_close
    cmp byte [r9 + elf64_ehdr.e_ident + 2], ELFMAG2
    jne unmap_and_close
    cmp byte [r9 + elf64_ehdr.e_ident + 3], ELFMAG3
    jne unmap_and_close

    ; ---- 4. validate 64-bit class ----
    cmp byte [r9 + elf64_ehdr.e_ident + 4], ELFCLASS64
    jne unmap_and_close

    ; ---- 5. walk program headers looking for an executable PT_LOAD segment ----
    mov rax, [r9 + elf64_ehdr.e_phoff]
    add rax, r9                       ; rax = first Phdr address
    movzx rcx, word [r9 + elf64_ehdr.e_phnum]
    xor r11, r11                      ; r11 = loop index

phdr_loop:
    cmp r11, rcx
    jge unmap_and_close                ; no candidate segment found

    mov edx, dword [rax + elf64_phdr.p_type]
    cmp edx, PT_LOAD
    jne phdr_next

    mov edx, dword [rax + elf64_phdr.p_flags]
    test edx, PF_X
    jz phdr_next                       ; not executable, skip

    ; -------------------------------------------------------------
    ; Found an executable PT_LOAD segment at [rax]:
    ;   [rax + elf64_phdr.p_offset] -> file offset of segment
    ;   [rax + elf64_phdr.p_filesz] -> size of segment in file
    ;   [rax + elf64_phdr.p_vaddr]  -> virtual address at runtime
    ;
    ; This is the segment you'd scan for a code cave (find_cave)
    ; and where you'd compute injection offsets (inject) in your
    ; C-side t_type_handler equivalent.
    ; -------------------------------------------------------------
    jmp unmap_and_close                ; placeholder: hand off to your
                                        ; cave-finding / injection logic here

phdr_next:
    inc r11
    movzx rdx, word [r9 + elf64_ehdr.e_phentsize]
    add rax, rdx
    jmp phdr_loop

unmap_and_close:
    mov rax, SYS_MUNMAP
    mov rdi, r9
    mov rsi, r10
    syscall

close_target:
    mov rax, SYS_CLOSE
    mov rdi, rbx
    syscall

skip_entry:
    add r14, rcx
    jmp process_entries

close_dir:
    mov rax, SYS_CLOSE
    mov rdi, r12
    syscall

exit_success:
    mov rsp, rbp
    pop rbp
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

exit_error:
    mov rsp, rbp
    pop rbp
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

; -----------------------------------------------------------------------------
; STRINGS
; -----------------------------------------------------------------------------
section .rodata

dir_path:
    db "/tmp/test", 0