# Regfile
## Name
Allan Bochenek

## Description of Design
This is a general 32 bit register file. Within the file itself, there is a write_enable, reset, and clock as general inputs to the register file, as well as the actual 32 bit input to the register itself. Additonal inputs include 32 bit read registers that, when decoded into their individual bits, act as the enables for tri-state buffers that monitor the outputs of the 32 registers inside the register file.

Spekaing of which, the inside of the register file has 32 active registers, each storing a 32 bit value. Using a decoder, we chose which register to write to on a clock edge, with that value being stored in the register and outputted as an input to the tristate buffer mentioned above.

Each register file within the set of 32 is composed of 32 individual D Flip-Flops that each store one bit of the value recieved. These flip flops are enabled when the decoder activiates the register (all of which are on the same clock/clear), which ensures the values get stored and are ready to be outputted when needed.

## Bugs
There are no bugs in the final design. Upon building, the only real bugs I encountered were syntax bugs (minor mistakes here and there with shifting and generating) and problems with remmembering the inputs/ouputs and naming policies for modules. It was confusing to keep track of clear, clock, enable, writing, reading, etc., so I initilly had bugs that were just wrongly named items being used as the inputs/outputs. These bugs were quickly fixed, though.
