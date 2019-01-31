.data

hello:
    .asciz "hello world\n"

digit:
    .asciz "%c\n"

.text


.globl main
main:
    ldr r0, =hello
    
    push {ip, lr}
    bl write_out
    pop {ip, lr}
 
    mov r7, #1 @ exit system call code
    svc #0 @ call to supervisor mode

.globl read_in @ read in, outputs a buffer, no args
read_in:
    @ Prologue
    push {fp}
    mov fp, sp
    push {r4-r10}

    @ Body of function
    ldr r0, [fp, #-12]
    ldr r1, [fp, #-8]
    ldr r2, [fp, #-4]
    
    @ Call to supervisor mode for read (3)
    mov r1, #0 @ file descriptor to bring input from stdin 
    mov r7, #3
    svc #0

    @ Epilogue
    mov r0, r1
    pop {r4-r10}
    mov sp, fp
    pop {fp}
    bx lr

.globl write_out @ write to stdout, takes buffer as argument
write_out:
    @ Prologue
    push {fp} 
    mov fp, sp
    push {r0}
    push {r4-r10}

    @ Body of function
    ldr r0, [fp, #-4] @ allocated buffer

    @ Function to find the length of the buffer
    push {ip, lr}
    bl strlen
    pop {ip, lr}

    add r2, r0, #1

    @ Call to supervisor mode for write (4)
    mov r0, #1 @ file descriptor to output to stdout
    ldr r1, [fp, #-4]
    mov r7, #4
    svc #0

    @ Epilogue
    mov r0, r1
    pop {r4-r10}
    mov sp, fp
    pop {fp}
    bx lr

.globl strlen @ find length of string, one argument
strlen:
    @ Prologue
    push {fp}
    mov fp, sp
    push {r0}
    push {r4-r10}
    
    @ body
    @ r0 sits as the accumulator
    @ r1 holds the string address
    mov r0, #0
    ldr r1, [fp, #-4]
    
strlen_loop:
    ldrb r2, [r1], #1

    cmp r2, #0
    beq strlen_epi
    add r0, r0, #1
    b strlen_loop

strlen_epi:
    @ Epilogue
    pop {r4-r10}
    mov sp, fp
    pop {fp}
    bx lr

.globl itos @ take in number, and output a string
itos:
    @ Prologue
    push {fp}
    mov fp, sp
    push {r0}
    push {r4-r10}

    ldr r4, [fp, #-4] @ number
    mov r5, #0 @ length counter
    mov r6, #1 @ order of magnitude

itos_len_count:
    mov r7, #10
    mul r6, r6, r7

    mov r0, r4 @ get args ready for division
    mov r1, r6
    push {ip, lr}
    bl div
    pop {ip, lr}
    
    add r5, r5, #1 @ increment counter
    cmp r0, #0 @ repeat if not at end
    bne itos_len_count

    ldr r4, [fp, #-4] @ reload for sanity
    cmp r4, #0 @ see if negative
    bge itos_alloc
    add r5, r5, #1
    mov r6, #-1
    mul r4, r4, r6 @ change sign for next step

itos_alloc:
    add r5, r5, #1
    push {ip, lr} @ allocate some space for this string
    mov r1, r5
    mov r0, #45
    svc #0
    pop {ip, lr}
    
    cmp r6, #0 @ if was found to be negative, put a "-" in front
    bne itos_fill_buffer
    mov r6, #45
    strb r6, [r0], #1 @ load the dash in
    sub r5, r5, #1

itos_fill_buffer:
    mov r7, r5
    mov r6, #0 @ load in the null character
    strb r6, [r0, r7] @ load null character at the end
    sub r7, r7, #1
    mov r6, #10
    mov r5, r4 @ shift everything up to make room
    mov r4, r0 @ change address register because of all the function calls

itos_place_char:
    mov r0, r4
    mov r1, r6
    push {ip, lr} @ allocate some space for this string
    bl mod
    pop {ip, lr}

    add r0, r0, #48
    strb r0, [r0, r7] @ load the number character
    sub r7, r7, #1
    cmp r7, #0
    blt itos_done
   
    mov r0, r4
    mov r1, r6 
    push {ip, lr} @ allocate some space for this string
    bl div
    pop {ip, lr}

    mov r4, r0

itos_done:
    

itos_epi:
    @ Epilogue
    pop {r4-r10}
    mov sp, fp
    pop {fp}
    bx lr

.globl div @ divide two numbers, two inputs quotient, divisor, output one
div:
    @ Prologue
    push {fp}
    mov fp, sp
    push {r0, r1}
    push {r4-r10}

    @ body
    mov r0, #0 @ accumulator
    ldr r1, [fp, #-8] @ quotient
    ldr r2, [fp, #-4] @ divisor
    mov r3, #1 @ sign adjustor
    mov r7, #-1

    @ check for negative in quotient
    cmp r2, #0
    beq div_epi
    cmp r1, #0
    bge quot_pos
    mul r1, r1, r7
    mul r3, r7

quot_pos:
    @ check for negative in divisor
    cmp r2, #0
    bge div_pos
    mul r2, r2, r7
    mul r3, r7

div_pos:
    cmp r1, r2
    blt div_comp
    add r0, r0, #1
    sub r1, r1, r2
    b div_pos

div_comp:
    mul r0, r0, r3 @ multiply by the sign adjustor

div_epi:
    @ Epilogue
    pop {r4-r10}
    mov sp, fp
    pop {fp}
    bx lr

.globl mod @ modulo two numbers, two inputs quotient, divisor, output one
mod:
    @ Prologue
    push {fp}
    mov fp, sp
    push {r0, r1}
    push {r4-r10}

    @ body
    ldr r1, [fp, #-8] @ quotient
    ldr r2, [fp, #-4] @ divisor
    mov r3, #1 @ sign adjustor
    mov r4, #1
    mov r7, #-1

    @ check for negative in quotient
    cmp r1, #0
    bge mod_pos
    mul r1, r1, r7
    mul r3, r7

mod_pos:
    @ check for negative in divisor
    cmp r2, #0
    bge mod_div_pos
    mul r2, r2, r7
    mul r4, r7

mod_div_pos:
    @ subtract until r1 is less than divisor
    cmp r1, r2
    blt mod_comp
    sub r1, r1, r2
    b mod_div_pos

mod_comp:
    mov r0, r1
    @ check to see if signs are the same
    cmp r3, r4
    bne mod_signs_diff
    @ if not, check if negative, and flip if negative
    cmp r3, #0
    bge mod_epi
    mul r0, r0, r7
    b mod_epi

mod_signs_diff:
    @ get value of result from divisor
    sub r0, r2, r0
    @ flip if divisor is negative
    cmp r4, #0
    bge mod_epi
    mul r0, r0, r7

mod_epi:
    @ Epilogue
    pop {r4-r10}
    mov sp, fp
    pop {fp}
    bx lr
