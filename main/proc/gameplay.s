addi $r1, $r0, 3 # lives_reg = 3
addi $r2, $r0, 0 # score = 0
addi $r4, $r0, 0 # bumper_old_reg = 0
addi $r6, $r0, 0 # ball_lost_old_reg = 0
addi $r8, $r0, 1 # constant 1
addi $r9, $r0, 100 # constant 100

main_loop:
    bne $r7, $r8, done #while onswitch on
    blt $r0, $r1, check_bumper_rise
    j done

check_bumper_rise:
    # if bumper_current_reg == 1 and bumper_old_reg == 0
    bne  $r3, $r8, check_bumper_fall
    bne  $r4, $r0, check_bumper_fall
    add  $r2, $r2, $r9 # score add  100
    addi $r4, $r0, 1  # set bumper_old_reg = 1 to avoid multiple hits

check_bumper_fall:
    # if bumper_current_reg == 0 and bumper_old_reg == 1
    bne  $r3, $r0, check_ball_islost
    bne  $r4, $r8, check_ball_islost
    addi $r4, $r0, 0        # bumper_old_reg = 0

check_ball_islost:
    # if ball_lost_reg == 1 and ball_lost_old_reg == 0
    bne  $r5, $r8, check_ball_islostend 
    bne  $r6, $r0, check_ball_islostend 
    addi $r1, $r1, -1   # lives_reg -= 1
    addi $r6, $r0, 1  # ball_lost_old_reg = 1

check_ball_islostend:
    # if ball_lost_reg == 0 and ball_lost_old_reg == 1
    bne  $r5, $r0, loop_back
    bne  $r6, $r8, loop_back
    addi $r6, $r0, 0        # ball_lost_old_reg = 0

loop_back:
    j main_loop

done:
    j done