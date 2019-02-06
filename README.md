# Assembly Calculator

This is an calculator that takes in scheme like input (`(+ 1 2)`) that can have nested expression to calculate a final result.  It is written in ARM assembly language and does not make use of any external C calls or libraries.  It has no dependencies and only makes calls to external OS functionality for allocated space to the heap, reading from the input, and writing to the output.  It was ultimately designed with the Raspberry Pi system in mind.

## Building and Use

This file `arm_calc.s` can be deployed by using your ARM based system and an ARM assembler that will take the assembly code and create a binary.  GCC works fine for this task.  The only command you need: `gcc arm_calc.s -o arm_calc`.

To run this, simply type `./arm_calc` and you're off to the races.  This takes in expressions as input.  An expression is defined, in our cases, as a integer literal, or a triple of operator, expression, expression, enclosed in parentheses, each argument separated by white space.

As example use:
```
arm-calc > (+ 1 2)
3
arm-calc > (+ (* 2 2) 2)
6
```

## Context and Historical Importance

