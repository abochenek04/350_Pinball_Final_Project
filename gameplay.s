# ============================================================================
# PINBALL MACHINE MIPS CODE
# Digital Systems Final Project
# ============================================================================
# Register Allocations:
# $r0  = zero (always 0)
# $r1  = 1 (constant)
# $r2  = score (output to VGA display)
# $r3  = bumper_1 input state (temp from JD port)
# $r4  = bumper_2 input state (temp from JD port)
# $r5  = lives counter (starts at 3, decrements on drain)
# $r6  = bumper_3 input state (temp from JD port)
# $r7  = bumper_4 input state (temp from JD port)
# $r8  = bumper_5 input state (temp from JD port)
# $r11 = FSM state (0=waiting for b1, 1=waiting for b2, 2=waiting for b3)
# $r12 = temp register for FSM comparisons
# $r18 = drain debounce flag (edge detection for ball loss)
# $r19 = drain switch input (1=ball in drain, 0=clear)
# $r20 = on/off switch input (1=game active, 0=game paused/off)
# $r21 = reset switch input (1=reset pressed, 0=not pressed)
# $r22 = bumper_1 marked flag (0=available, 1=already scored this cycle)
# $r23 = bumper_2 marked flag (0=available, 1=already scored this cycle)
# $r24 = bumper_3 marked flag (0=available, 1=already scored this cycle)
# $r25 = bumper_4 marked flag (0=available, 1=already scored this cycle)
# $r26 = bumper_5 marked flag (0=available, 1=already scored this cycle)

start:
    addi $r1, $r0, 1

    addi $r2, $r0, 0
    addi $r5, $r0, 3
    addi $r9, $r0, 0
    addi $r18, $r0, 0
    addi $r11, $r0, 0

    addi $r22, $r0, 0
    addi $r23, $r0, 0
    addi $r24, $r0, 0
    addi $r25, $r0, 0
    addi $r26, $r0, 0

#check reset button
main_loop:
    lw $r21, 0($r21)
    bne $r21, $r1, check_drain

    #otherwise, reset
    addi $r2, $r0, 0
    addi $r5, $r0, 3
    addi $r22, $r0, 0
    addi $r23, $r0, 0
    addi $r24, $r0, 0
    addi $r25, $r0, 0
    addi $r26, $r0, 0
    addi $r9, $r0, 0
    addi $r18, $r0, 0
    addi $r11, $r0, 0
    j main_loop

#check if life lost, decrement if so, with delatch
check_drain:
    lw $r19, 0($r19)
    
    bne $r19, $r1, drain_Not_Pressed
    bne $r18, $r0, drain_Pressed

    addi $r18, $r0, 1
    addi $r5, $r5, -1
    j check_game_over

#reset drain_bounce state
drain_Not_Pressed:
    addi $r18, $r0, 0
    j check_game_over

#drain is still pressed, ignore for double counting
drain_Pressed:
    j check_game_over

#if lives reached zero, end game
check_game_over:
    bne $r5, $r0, check_ON_OFF
    j game_OVER

#reading from JD port ON/OFF switch state
check_ON_OFF:
    lw $r20, 0($r20)

    bne $r20, $r1, game_OVER
    j process_bumper_hit

process_bumper_hit:
    #Read individual bumper states from JD ports into temp registers
    lw $r3, 0($r3)       # Bumper 1 state (temp read into $r3)
    lw $r4, 0($r4)       # Bumper 2 state (temp read into $r4)
    lw $r6, 0($r6)       # Bumper 3 state (temp read into $r6)
    lw $r7, 0($r7)       # Bumper 4 state (temp read into $r7)
    lw $r8, 0($r8)       # Bumper 5 state (temp read into $r8)
    j check_bumper_1

#check bumper 1 (first mushroom)
check_bumper_1:
    bne $r3, $r1, check_bumper_2    # If bumper 1 not pressed, check bumper 2
    bne $r22, $r0, check_bumper_2   # If bumper 1 already hit, skip to bumper 2
    
    # Bumper 1 pressed and not yet marked in this cycle
    addi $r22, $r0, 1               # Mark bumper_1 as hit
    addi $r2, $r2, 100              # Always award 100 points
    addi $r11, $r0, 1               # FSM state = 1 (watching for bumper 2)

check_bumper_2:
    bne $r4, $r1, check_bumper_3    # If bumper 2 not pressed, check bumper 3
    bne $r23, $r0, check_bumper_3   # If bumper 2 already hit, skip to bumper 3
    
    # Bumper 2 pressed and not yet marked in this cycle
    addi $r23, $r0, 1               # Mark bumper_2 as hit
    addi $r2, $r2, 100              # Always award 100 points
    
    # If FSM is in state 1 (bumper 1 was hit), advance to state 2
    bne $r11, $r1, check_bumper_3   # If FSM != 1, don't advance
    addi $r11, $r0, 2               # FSM state = 2 (watching for bumper 3)

check_bumper_3:
    bne $r6, $r1, check_bumper_4    # If bumper 3 not pressed, check bumper 4
    bne $r24, $r0, check_bumper_4   # If bumper 3 already hit, skip to bumper 4
    
    # Bumper 3 pressed and not yet marked in this cycle
    addi $r24, $r0, 1               # Mark bumper_3 as hit
    addi $r2, $r2, 100              # Always award 100 points
    
    # Check if FSM is in state 2 (bumpers 1 and 2 were hit in sequence)
    addi $r12, $r0, 2
    bne $r11, $r12, check_bumper_4  # If FSM != 2, skip bonus
    
    # Bonus awarded - sequence 1->2->3 detected!
    addi $r2, $r2, 1000             # Award 1000 bonus points
    addi $r11, $r0, 0               # Reset FSM to 0 for next sequence

check_bumper_4:
    bne $r7, $r1, check_bumper_5    # If bumper 4 not pressed, check bumper 5
    bne $r25, $r0, check_bumper_5   # If bumper 4 already hit, skip to bumper 5
    
    # Bumper 4 pressed and not yet marked in this cycle
    addi $r25, $r0, 1               # Mark bumper_4 as hit
    addi $r2, $r2, 100              # Award 100 points
    j main_loop

check_bumper_5:
    bne $r8, $r1, main_loop         # If bumper 5 not pressed, go back to main
    bne $r26, $r0, main_loop        # If bumper 5 already hit, skip to main loop
    
    # Bumper 5 pressed and not yet marked in this cycle
    addi $r26, $r0, 1               # Mark bumper_5 as hit
    addi $r2, $r2, 100              # Award 100 points
    j main_loop


#game does not process anything further until RESET, then yes
game_OVER:
    lw $r21, 0($r21)
    bne $r21, $r1, game_OVER
    j start

