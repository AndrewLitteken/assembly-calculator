.data

shell_prompt:
    .asciz "asm-calc > "

errno:
    .word 0x00000000

errmsg:
    .asciz "Something went wrong.\n"

err_paren:
    .asciz "Parentheses must match.\n"

err_whitespace:
    .asciz "Must have whitespace between inputs.\n" 

err_int:
    .asciz "Must be a number 0-9. \n"

err_oper:
    .asciz "Invalid operator, valid operators are +-*%/. \n"

number:
    .asciz "2018"

newline:
    .asciz "\n"

buffer:
    .word 0x00000000

.text

@ A NOTE: If we need to, we can do and input buffer and an output buffer

.globl main
main:
    @ brk to get some space for the buffer
    mov r7, #45
    mov r0, #0
    svc #0

    ldr r1, =#1024
    add r0, r0, r1
    mov r7, #45
    svc #0

    @ put it in the buffer location
    ldr r1, =#1024
    sub r0, r0, r1
    ldr r1, =buffer
    str r0, [r1]

    @ zero the buffer
    
    push {ip, lr}
    bl zero_buffer
    pop {ip, lr}

    ldr r5, =shell_prompt
main_io_loop:
    
    mov r1, #0
    mov r0, r5
    push {ip, lr}
    bl write_out
    pop {ip, lr}

    push {ip, lr}
    bl read_in
    pop {ip, lr}
    @ result is in r0 now

    @ Calls to calculator stuff go in here
    push {ip, lr}
    bl eval_expr
    pop {ip, lr}

    ldr r2, =errno
    ldr r3, [r2]
    cmp r3, #0
    beq main_write_out
    mov r0, #0
    str r0, [r2]

    mov r1, #0

error_paren:
    cmp r3, #-2
    bne error_whitespace
    ldr r0, =err_paren
    b error_out

error_whitespace:
    cmp r3, #-3
    bne error_int
    ldr r0, =err_whitespace
    b error_out

error_int: 
@ must be 0-9
    cmp r3, #-4
    bne error_oper
    ldr r0, =err_int
    b error_out

error_oper:
@ invalid operator
    cmp r3, #-5
    bne error_general
    ldr r0, =err_oper
    b error_out

error_general:
@ generalized error message

    ldr r0, =errmsg

error_out:
    
    push {ip, lr}
    bl write_out
    pop {ip, lr}
    b main_io_loop


main_write_out:
    mov r1, #1
    push {ip, lr}
    bl write_out
    pop {ip, lr}

    ldr r0, =newline
    mov r1, #0
    push {ip, lr}
    bl write_out
    pop {ip, lr}

    b main_io_loop

    mov r7, #1 @ exit system call code
    svc #0 @ call to supervisor mode

.globl zero_buffer @ just zero the buffer entirely
zero_buffer:
    @ Prologue
    push {fp}
    mov fp, sp
    push {r4-r10}
   
    @ basically just count up and put a null character in each
    ldr r0, =#1024
    mov r1, #0
    ldr r2, =buffer
    ldr r2, [r2]
    mov r3, #0

zero_loop:
    cmp r1, r0
    beq zero_done
    strb r3, [r2, r1]
    add r1, r1, #1
    b zero_loop

zero_done: 
    @ Epilogue
    pop {r4-r10}
    mov sp, fp
    pop {fp}
    bx lr
    

.globl read_in @ read in, outputs a buffer, no args
read_in:
    @ Prologue
    push {fp}
    mov fp, sp
    push {r4-r10}

    @ Call to supervisor mode for read (3)
    ldr r1, =buffer @ get address of address of buffer
    ldr r1, [r1] @ get address to buffer

    mov r4, r1
    push {ip, lr}
    bl zero_buffer
    pop {ip, lr}
    mov r1, r4
    

read_in_loop:
    mov r0, #0 @ load in file descriptor
    ldr r2, =#1024 @ space to place
    mov r7, #3 @ r7 for read
    svc #0

    ldr r1, =buffer @ load in address to address to buffer
    ldr r1, [r1] @ load in address to buffer

    ldr r0, [r1] @ load in first byte
    cmp r0, #0 @ check to see if still 0
    beq read_in_loop @ if is zero, repeat
    
    @ Epilogue
    mov r0, r1 @ move address to buffer to r0
    pop {r4-r10}
    mov sp, fp
    pop {fp}
    bx lr

.globl eval_expr @ takes pointer to string start as argument
@ returns value
eval_expr:
    @ Prologue
    push {fp}
    mov fp, sp
    push {r0}
    sub sp, sp, #8
    push {r4-r10}
    ldrb r4, [r0]
    mov r5, #0     @ length
    cmp r4, #45    @ 45 is "-"
    blt eval_expr_paren
    @ should be a number, not another expression
    bne eval_expr_check_number
    add r5, r5, #1
    add r0, r0, #1

eval_expr_check_number:
    ldrb r4, [r0]
    cmp r4, #32       @ if we find a space or a newline or right paren, return
    beq eval_expr_value_return
    cmp r4, #10
    beq eval_expr_value_return
    cmp r4, #41
    beq eval_expr_value_return
    cmp r4, #48
    mov r2, #-4
    blt eval_expr_error
    cmp r4, #57
    bgt eval_expr_error
    add r5, r5, #1
    add r0, r0, #1
    b eval_expr_check_number

eval_expr_value_return:
    mov r6, r0     @ save end of number
    ldr r0, [fp, #-4]
    mov r1, r5

    push {ip, lr}
    bl stoi
    pop {ip, lr}   @ r0 contains value
    mov r1, r6
    b eval_expr_return_epilogue

eval_expr_return_epilogue:
    @ Epilogue
    pop {r4-r10}
    mov sp, fp
    pop {fp}
    bx lr

eval_expr_paren:
    add r0, r0, #1   @ find first non-space
    ldrb r4, [r0]
    cmp r4, #32
    beq eval_expr_paren
    ldrb r10, [r0]

    add r0, r0, #1
    ldrb r4, [r0]
    cmp r4, #32
    mov r2, #-3
    bne eval_expr_error

eval_expr_first_arg:
    add r0, r0, #1   @ find first non-space
    ldrb r4, [r0]
    cmp r4, #32
    beq eval_expr_first_arg

    push {ip, lr}  @time to recurse
    bl eval_expr
    pop {ip, lr}   @we have the value
    str r0, [fp, #-8]

    ldr r2, =errno
    ldr r2, [r2]
    cmp r2, #0
    bne eval_expr_return_epilogue

    mov r0, r1     @new starting point

    ldrb r4, [r0]
    cmp r4, #32
    beq eval_expr_second_arg
    mov r2, #-3
    cmp r4, #41
    bne eval_expr_error
    mov r2, #-2
    b eval_expr_error

eval_expr_second_arg:
    add r0, r0, #1   @ find first non-space
    ldrb r4, [r0]
    cmp r4, #32
    beq eval_expr_second_arg

    push {ip, lr}  @time to recurse
    bl eval_expr
    pop {ip, lr}   @we have the value
    str r0, [fp, #-12]

    ldr r2, =errno
    ldr r2, [r2]
    cmp r2, #0
    bne eval_expr_return_epilogue


    mov r0, r1     @new starting point

eval_expr_find_end:
    ldrb r4, [r0]
    cmp r4, #32
    add r0, r0, #1   @ find first non-space
    beq eval_expr_second_arg

    cmp r4, #41      @ was it a close paren?
    mov r2, #-2      @ specific error value
    bne eval_expr_error
    mov r9, r0

    ldr r0, [fp, #-8]
    ldr r1, [fp, #-12]

    cmp r10, #43
    beq eval_expr_add
    cmp r10, #45
    beq eval_expr_sub
    cmp r10, #42
    beq eval_expr_mul
    cmp r10, #47
    beq eval_expr_div
    cmp r10, #37
    beq eval_expr_mod
    mov r2, #-5
    b eval_expr_error

eval_expr_add:
    add r0, r0, r1
    mov r1, r9
    b eval_expr_return_epilogue

eval_expr_sub:
    sub r0, r0, r1
    mov r1, r9
    b eval_expr_return_epilogue

eval_expr_mul:
    mul r0, r1, r0
    mov r1, r9
    b eval_expr_return_epilogue

eval_expr_div:
    push {ip, lr}
    bl div
    pop {ip, lr}
    mov r1, r9
    b eval_expr_return_epilogue

eval_expr_mod:
    push {ip, lr}
    bl mod
    pop {ip, lr}
    mov r1, r9
    b eval_expr_return_epilogue

eval_expr_error:
    ldr r1, =errno
    @loaded custom error number
    str r2, [r1]
    b eval_expr_return_epilogue

.globl write_out @ write to stdout, takes buffer, and type as argument
@ type is 0 for string and 1 for integer
write_out:
    @ Prologue
    push {fp} 
    mov fp, sp
    push {r0, r1}
    push {r4-r10}

    @ Body of function
    ldr r0, [fp, #-8] @ allocated buffer
    ldr r1, [fp, #-4] @ type of string
    @ convert to string if it is not
    cmp r1, #0
    beq write_out_no_int
    
    push {ip, lr}
    bl itos
    pop {ip, lr}
    @ buffer now in r0

write_out_no_int:
    mov r4, r0
    @ Function to find the length of the buffer
    push {ip, lr}
    bl strlen
    pop {ip, lr}

    @ add one for the null charactr
    add r2, r0, #1
    mov r1, r4

    @ Call to supervisor mode for write (4)
    mov r0, #1 @ file descriptor to output to stdout
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
    @ loop over each byte until you find the null character
    ldrb r2, [r1], #1

    @ increment for each non null character
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

.globl stoi @ take in string address, and length of string, give back number
stoi:
    @ Prologue
    push {fp}
    mov fp, sp
    push {r0, r1}
    push {r4-r10}
    
    mov r0, #0 @ accumulator
    ldr r1, [fp, #-8] @ string address
    ldr r2, [fp, #-4] @ length
    mov r3, #1 @ multiplier
    mov r7, #10 @ immediate holder

    sub r2, r2, #1 @ subtract one off th length of correct address calc

stoi_count_back:
    @ if is less than ero move to the next step
    cmp r2, #0
    blt stoi_epi
   
    @ get number from current place in string 
    ldrb r4, [r1, r2] @ get a number
    @ if it is a dash at the beginning
    cmp r4, #45
    beq stoi_done_neg
    @ adjust for ascii, adjust with multiplier and add to accumulator
    sub r4, r4, #48
    mul r4, r3, r4
    add r0, r0, r4
    sub r2, r2, #1
    @ adjust accumulator and start again
    mul r3, r7, r3
    b stoi_count_back

@ multiply by one if found a dash
stoi_done_neg:
    mov r7, #-1
    mul r0, r7, r0    

stoi_epi:
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

    push {ip, lr}
    bl zero_buffer
    pop {ip, lr}

    ldr r4, [fp, #-4] @ number
    mov r5, #0 @ length counter
    mov r6, #1 @ order of magnitude
    mov r7, #10

itos_len_count:
    add r5, r5, #1 @ increment counter
    mul r6, r7, r6 @ increment multiplier

    mov r0, r4 @ get args ready for division
    mov r1, r6
    push {ip, lr}
    bl div
    pop {ip, lr}
    
    cmp r0, #0 @ repeat if not at end
    bne itos_len_count

    ldr r4, [fp, #-4] @ reload for sanity
    cmp r4, #0 @ see if negative
    bge itos_alloc
    @ add one and set flag if negative
    add r5, r5, #1
    mov r6, #-1
    mul r4, r6, r4 @ change sign for next step

itos_alloc:
    @ load buffer and get character
    ldr r0, =buffer
    ldr r0, [r0]
    @ add one space for the null character
    add r5, r5, #1
    cmp r6, #0 @ if was found to be negative, put a "-" in front
    bge itos_fill_buffer
    mov r6, #45
    strb r6, [r0], #1 @ load the dash in
    @ subtract from end address and above add to buffer address
    sub r5, r5, #1

itos_fill_buffer:
    @ subtract one for pointer arithmetic
    sub r5, r5, #1
    mov r7, r5
    mov r6, #0 @ load in the null character
    strb r6, [r0, r7] @ store null character at the end
    sub r7, r7, #1
    mov r6, #10
    mov r5, r4 @ shift everything up to make room
    mov r4, r0 @ change address register because of all the function calls

itos_place_char:
    
    mov r0, r5
    mov r1, r6
    push {ip, lr} @ find current ones place
    bl mod
    pop {ip, lr}
    
    add r0, r0, #48 @ add because ASCII
    strb r0, [r4, r7] @ store the number character
    sub r7, r7, #1 @ subtract one for address calc
    cmp r7, #0 @ see if done the last character
    blt itos_done
   
    @ remove the current ones place
    mov r0, r5
    mov r1, r6 
    push {ip, lr} @ take off order of magnitude
    bl div
    pop {ip, lr}

    mov r5, r0
    b itos_place_char

itos_done:
    @ reset to the beginning of the buffer
    ldr r0, =buffer
    ldr r0, [r0]

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
    mul r1, r7, r1
    mul r3, r7

quot_pos:
    @ check for negative in divisor
    cmp r2, #0
    bge div_pos
    mul r2, r7, r2
    mul r3, r7

div_pos:
    cmp r1, r2
    blt div_comp
    add r0, r0, #1
    sub r1, r1, r2
    b div_pos

div_comp:
    mul r0, r3, r0 @ multiply by the sign adjustor

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
    mul r1, r7, r1
    mul r3, r7

mod_pos:
    @ check for negative in divisor
    cmp r2, #0
    bge mod_div_pos
    mul r2, r7, r2
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
    mul r0, r7, r0
    b mod_epi

mod_signs_diff:
    @ get value of result from divisor
    sub r0, r2, r0
    @ flip if divisor is negative
    cmp r4, #0
    bge mod_epi
    mul r0, r7, r0

mod_epi:
    @ Epilogue
    pop {r4-r10}
    mov sp, fp
    pop {fp}
    bx lr
