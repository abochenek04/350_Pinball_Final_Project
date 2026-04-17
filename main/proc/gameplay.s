# ==========================================
# Pinball Machine Program
# Register-mapped input version
# ==========================================
#
# Register map:
# r26 = ON switch
# r27 = RESET switch
# r28 = bumper 1
# r29 = bumper 2
# r30 = bumper 3
# r31 = bumper 4
# r2  = VGA score output
#
# Behavior:
# - If ON switch is off, game idles
# - If RESET switch is on, score resets to 0
# - Each bumper adds points once per press
# - Score is always stored in r2
#
# ==========================================

        nop
        nop
        nop

# ------------------------------------------
# Startup
# ------------------------------------------
start:
        addi r2, r0, 0
        addi r3, r0, 0
        addi r4, r0, 0
        addi r5, r0, 0
        addi r6, r0, 0
        addi r7, r0, 0

        nop
        nop
        nop

# ------------------------------------------
# Main game loop
# ------------------------------------------
main_loop:
        beq r26, r0, power_off
        bne r27, r0, do_reset
        j check_bumper1

# ------------------------------------------
# Power off state
# Stay here until ON switch is enabled
# ------------------------------------------
power_off:
        addi r3, r0, 0
        addi r4, r0, 0
        addi r5, r0, 0
        addi r6, r0, 0
        addi r7, r0, 0
        beq r26, r0, power_off_wait
        j main_loop

power_off_wait:
        nop
        nop
        nop
        beq r26, r0, power_off_wait
        j main_loop

# ------------------------------------------
# Reset score
# ------------------------------------------
do_reset:
        addi r2, r0, 0
        addi r3, r0, 0
        addi r4, r0, 0
        nop
        nop
        bne r27, r0, reset_wait
        j main_loop

reset_wait:
        nop
        nop
        nop
        bne r27, r0, reset_wait
        j main_loop

# ------------------------------------------
# Check bumper 1
# ------------------------------------------
check_bumper1:
        beq r28, r0, check_bumper2
        addi r2, r2, 10
        addi r3, r3, 1
        j wait_bumper1_release

wait_bumper1_release:
        bne r28, r0, wait_bumper1_release
        nop
        nop
        j check_bumper2

# ------------------------------------------
# Check bumper 2
# ------------------------------------------
check_bumper2:
        beq r29, r0, check_bumper3
        addi r2, r2, 20
        addi r4, r4, 1
        j wait_bumper2_release

wait_bumper2_release:
        bne r29, r0, wait_bumper2_release
        nop
        nop
        j check_bumper3

# ------------------------------------------
# Check bumper 3
# ------------------------------------------
check_bumper3:
        beq r30, r0, check_bumper4
        addi r2, r2, 30
        addi r5, r5, 1
        j wait_bumper3_release

wait_bumper3_release:
        bne r30, r0, wait_bumper3_release
        nop
        nop
        j check_bumper4

# ------------------------------------------
# Check bumper 4
# ------------------------------------------
check_bumper4:
        beq r31, r0, end_loop
        addi r2, r2, 40
        addi r6, r6, 1
        j wait_bumper4_release

wait_bumper4_release:
        bne r31, r0, wait_bumper4_release
        nop
        nop
        j end_loop

# ------------------------------------------
# End of one pass through game logic
# ------------------------------------------
end_loop:
        addi r7, r2, 0
        nop
        nop
        nop
        j main_loop