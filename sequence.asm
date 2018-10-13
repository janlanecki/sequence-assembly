            global _start
            
%macro      read_number 0
            ; Reads one number from the buffer, updates the buffer
            ; if necessary. Number is in rbx. If read was unsuccessful exits 
            ; program with code 0 if the last number was 0, code 1 otherwise.
            cmp r12, 0
            jne %%fill_re; don't refill buffer because it's not empty

%%fill:; Fills buffer until it's full or until the end of file.
            mov rax, SYS_READ
            syscall
            mov r12, rax; unread numbers = number of characters read by syscall
            xor r10, r10; position in buffer becomes 0
            cmp r12, 0
            je no_number; if there are no more numbers after refilling
            
%%fill_re:  mov bl, BYTE [buffer + r10]
            inc r10
            dec r12   
%endmacro    

%macro      check_sets 2
            ; Reads every set after the first one until the end of file
            ; or until a set differs from the first one.
            ; First argument has to be 1 for uneven sets and 2 for even.
            ; Second argument has to be -1 for uneven sets and 1 for even.
            mov r8, r9; set the number of elements in current set to that in M
            
%%read_set: ; Reads one set untill error or 0 occurs.
            ; For even numbered set (counting from 1) adds 1 to relevant
            ; positions in set M (which contains 1 on these positions). 
            ; For uneven numbered sets subtracts 1 from relevant 
            ; positions in set M (which contains 2 on these positions).
            read_number
            cmp rbx, 0
            je %%finish_set
            cmp BYTE [pattern + rbx], 0
            je exit1; number is not in the pattern so exit with code 1
            cmp BYTE [pattern + rbx], %1; check if number already in current set
            je exit1; the number is already in the set so exit with code 1
            dec r8; decrease the number of elements in the current set
            add BYTE [pattern + rbx], %2; mark the number in the set M 
            jmp %%read_set
            
%%finish_set:; For a complete set checks if it had a correct number of elements.
            cmp r8, 0; number of elements in current set is equal to that in M
            jne exit1
%endmacro            

            section .bss
            buffer resb 8192
            pattern resb 256
            filedesc resb 8
            
            section .rodata 
            O_RDONLY equ 0
            SYS_READ equ 0
            SYS_OPEN equ 2
            SYS_CLOSE equ 3
            SYS_EXIT equ 60
            BUF_SIZE equ 8192

            section .text
_start:
            cmp QWORD [rsp], 2; checks if there is an argument with a filename
            jne exit1; didn't specify the filename or gave too many arguments
            
open:; Opens file specified in argument, saves descriptor to filedesc variable.
            mov rax, SYS_OPEN
            mov rdi, [rsp + 16]; address of the filename argument on stack
            mov rsi, O_RDONLY
            syscall
            cmp rax, 0
            jl  exit1; if file descriptor is lesser than 0 open failed
            mov [filedesc], rax
            
initialize: push rbx
            push r12
            mov rbx, 1; contains last number read (1 so empty file doesn't pass)
            ; r8 contains number of elements that aren't in the current set yet
            xor r9, r9; contains number of elements in the set M
            ; r10 contains current POSITION in the buffer
            xor r12, r12; contains number of UNREAD elements in the buffer
            mov rdi, [filedesc]
            mov rsi, buffer
            mov rdx, BUF_SIZE

read_pattern:; Puts all numbers before the first '0' to the pattern array
             ; and the number of elements in the set M to r9 register.
            read_number

            cmp rbx, 0
            je finish_pattern; if there are no more numbers in the file
            cmp BYTE [pattern + rbx], 0
            jne exit1; if number is already in the set M exit with code 1
            inc BYTE [pattern + rbx]; add element to the set M
            inc r9; new element in set M
            jmp read_pattern     
finish_pattern:

read_sets:; Compares rest of the sets with the first one.
            check_sets 2, 1; check even set
            check_sets 1, -1; check uneven set
            jmp read_sets

no_number:; Exits with code 0 if last number was 0, otherwise with code 1.
            cmp rbx, 0
            jne exit1; if last number wasn't 0 exit with code 1
            ; the previous set was OK, so exit with code 0
      
exit0:; Exits with code 0.
            xor rdi, rdi
            jmp exit
            
exit1:; Exits with code 1.
            mov rdi, 1

exit:; Closes the file descriptor and exits with the code in rdi register.
            pop r12; reverts the values of these registers as expected
            pop rbx
            push rdi; keeps the initial rdi value to then use it as exit code
            mov rax, SYS_CLOSE
            mov rdi, [filedesc]
            syscall
            pop rdi
            mov rax, SYS_EXIT
            syscall
