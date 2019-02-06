# Assembly Calculator

This is an calculator that takes in scheme like input (`(+ 1 2)`) that can have nested expression to calculate a final result.  It is written in ARM assembly language and does not make use of any external C calls or libraries.  It has no dependencies and only makes calls to external OS functionality for allocated space to the heap, reading from the input, and writing to the output.  It was ultimately designed with the Raspberry Pi system in mind.

## Building and Use

This file `arm_calc.s` can be deployed by using your ARM based system and an ARM assembler that will take the assembly code and create a binary.  GCC works fine for this task.  The only command you need: `gcc arm_calc.s -o arm_calc`.

To run this, simply type `./arm_calc` and you're off to the races.  This takes in expressions as input.  An expression is defined, in our cases, as a integer literal, or a triple of operator, expression, expression, enclosed in parentheses, each argument separated by white space.

As example use:
```
arm-calc> 42
42
arm-calc> (+ 30 12)
42
arm-calc> (+ (* 8 5) 2)
42
arm-calc> (    + (  *   8   5  ) 2  )
42
```

## Context and Historical Importance
This calculator takes a step back into the days before compilers, and when code had to be painstakingly debugged.  Thankfully, we did not have to share a massive mainframe with other people, and we do not have to punch our code onto cards, but it did teach us the value of the resources that we have at out disposal.

Assembly lanaguage is still at the crux of all computing that is done today.  It may not be as understood by everyone that is programming a computer, but an understanding of it can be essential in developing and creating new tools.  Without this understanding, we risk becoming lazy and taking the systems underlying our current tools for granted.

Additionally, this project illuminates how to properly manage the resources, and the benefits of the systems that have been develop over time to make sure that programs are not clobbering their own data values, and can be as efficient as we desire them to be.  Without the guidelines that have been brough about, assembly language would be even more inscrutable than it already is.
