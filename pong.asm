.equ BALL,    0x1000 ; ball state (its position and velocity)
.equ PADDLES, 0x1010 ; paddles position
.equ SCORES,  0x1018 ; game scores
.equ LEDS,    0x2000 ; LED addresses
.equ BUTTONS, 0x2030 ; Button addresses

; BEGIN:main
main:
	addi t0, zero, 10
	ldw t1, SCORES(zero)
	ldw t2, SCORES+4(zero)
	beq t1, t0, main_end
	beq t2, t0, main_end ; if either score is 10 go to the end
	addi sp, zero, LEDS
	addi t0, zero, 0x0005
	addi t1, zero, 0x0001
	addi t2, zero, -1
	stw t0, BALL(zero)
	stw t0, BALL+4(zero)
	stw t1, BALL+8(zero)
	stw t2, BALL+12(zero)
	addi t0, zero, 3
	stw t0, PADDLES(zero) ; left paddle at y = 3
	addi t0, zero, 2
	stw t0, PADDLES+4(zero) ; right paddle at y = 2
ball_loop:
	call hit_test
	addi t0, zero, 1
	bne t0, v0, no_score_update_left ; if v0 is not 1 left player didn't score
	ldw t0, SCORES(zero)
	addi t0, t0, 1
	stw t0, SCORES(zero) ; else increase his score by 1
	call display_score ; display the score
	;call wait_long
	jmpi main ; and restart the game
no_score_update_left:
	addi t0, zero, 2
	bne t0, v0, no_score_update_right ; if v0 is not 2 right player didn't score
	ldw t0, SCORES+4(zero)
	addi t0, t0, 1
	stw t0, SCORES+4(zero) ; else increase his score by 1
	call display_score ; display the score
	;call wait_long
	jmpi main ; and restart the game
no_score_update_right:
	call move_ball
	call move_paddles
	call clear_leds
	ldw a0, BALL(zero)
	ldw a1, BALL+4(zero)
	call set_pixel
	call draw_paddles
	;call wait
	call ball_loop
main_end:
	ret

; END:main

; BEGIN:clear_leds
clear_leds:
	stw zero, LEDS(zero)
	stw zero, LEDS+4(zero)
	stw zero, LEDS+8(zero)
	ret

; END:clear_leds

; BEGIN:set_pixel
set_pixel:
	andi t0, a0, 0x0003 	; save x modulo 4 in t0
	slli t0, t0, 3 				; multiply t0 by 8
	add t0, t0, a1 				; add y to previous value. t0 should now be the pixel index within the word
	andi t1, a0, 0x000C 	; mask the x coord to keep only values 0, 4 and 8
	addi t1, t1, LEDS 		; add the previous value to LEDS to find the correct LED word
	ldw t3, 0(t1) 				; load the correct LED word in t3
	addi t2, zero, 0x0001
	sll t2, t2, t0 				; prepare a mask for the correct pixel index in t2
	or t3, t3, t2 				; set the correct pixel index to 1 via an or operation with t2
	stw t3, 0(t1) 				; save the new word in the correct LED address
	ret

; END:set_pixel

; BEGIN:hit_test
hit_test:
	ldw t0, BALL(zero) 		; load the ball x position in t0
	ldw t1, BALL+4(zero) 	; load the ball y position in t1
	ldw t2, BALL+8(zero) 	; load the ball x velocity in t2
	ldw t3, BALL+12(zero) ; load the ball y velocity in t3
walls:
	addi t5, zero, 11 ; store the max x in t5
	addi t6, zero, 7 ; store the max y in t6
	addi t7, zero, -1 ; make a full 1 register for XOR inversions
	bne t1, zero, no_up_bounce ; if the ball is not at the top, no bounce
	xor t3, t3, t7 ; invert all the bits of t3
	addi t3, t3, 1 ; add 1 (this combined with the above operation inverts t3)
no_up_bounce:
	bne t1, t6, no_down_bounce ; if the ball is not at the bottom, no bounce
	xor t3, t3, t7 ; invert all the bits of t3
	addi t3, t3, 1 ; add 1 (this combined with the above operation inverts t3)
no_down_bounce:
	bne t0, zero, no_left_bounce ; if the ball is not at the left, no bounce
	xor t2, t2, t7 ; invert all the bits of t2
	addi t2, t2, 1 ; add 1 (this combined with the above operation inverts t2)
no_left_bounce:
	bne t0, t5, no_right_bounce ; if the ball is not at the right, no up bounce
	xor t2, t2, t7 ; invert all the bits of t2
	addi t2, t2, 1 ; add 1 (this combined with the above operation inverts t2)
no_right_bounce:
	addi v0, zero, 0 ; set v0 to 0 (default value)
left:
	addi t4, zero, 1 ; store the x coord where left goals may happen in t4 (x=1)
	bne t0, t4, right ; if x is not 1, no risk of a left goal
	beq t2, t4, right ; if the x velocity is positive, no risk of a left goal
	ldw t4, PADDLES(zero) ; load the left paddle middle y coord in t4
	addi t5, t4, 1 ; left paddle bottom y coord in t5
	addi t6, t4, -1 ; left paddle top y coord in t6
	add t7, t1, t3 ; t7 is the virtual next ball y position
	beq t7, t4, no_left_goal
	beq t7, t5, no_left_goal
	beq t7, t6, no_left_goal ; if the virtual next ball y position is in the paddle, no goal
	addi v0, zero, 2 ; else, goal for player 2
	jmpi hit_end
no_left_goal:
	beq t1, t4, invert_x
	beq t1, t5, invert_x
	beq t1, t6, invert_x ; if there is paddle to the left of the ball, invert only x velocity
	beq t1, zero, invert_x
	addi t7, zero, 7
	beq t1, t7, invert_x ; if the ball is at the top or the bottom invert only x
	jmpi invert_y
right:
	addi t4, zero, 10 ; store the x coord where left goals may happen in t4 (x=10)
	bne t0, t4, hit_end ; if x is not 10, no risk of a right goal
	addi t4, zero, -1
	beq t2, t4, hit_end ; if the x velocity is negative, no risk of a right goal
	ldw t4, PADDLES+4(zero) ; load the right paddle middle y coord in t4
	addi t5, t4, 1 ; right paddle bottom y coord in t5
	addi t6, t4, -1 ; right paddle top y coord in t6
	add t7, t1, t3 ; t7 is the virtual next ball y position
	beq t7, t4, no_right_goal
	beq t7, t5, no_right_goal
	beq t7, t6, no_right_goal ; if the virtual next ball y position is in the paddle, no goal
	addi v0, zero, 1 ; else, goal for player 1
	jmpi hit_end
no_right_goal:
	beq t1, t4, invert_x
	beq t1, t5, invert_x
	beq t1, t6, invert_x ; if there is paddle to the right of the ball, invert only x velocity
	beq t1, zero, invert_x
	addi t7, zero, 7
	beq t1, t7, invert_x ; if the ball is at the top or the bottom invert only x
invert_y:
	addi t7, zero, -1 ; make a full 1 register for XOR inversions
	xor t3, t3, t7 ; invert all the bits of t3
	addi t3, t3, 1 ; add 1 (this combined with the above operation inverts t3)
invert_x:
	addi t7, zero, -1 ; make a full 1 register for XOR inversions
	xor t2, t2, t7 ; invert all the bits of t2
	addi t2, t2, 1 ; add 1 (this combined with the above operation inverts t2)
	jmpi hit_end
hit_end:
	stw t2, BALL+8(zero) ; save the new ball x velocity
	stw t3, BALL+12(zero) ; save the new ball y velocity
	ret

; END:hit_test

; BEGIN:move_ball
move_ball:
	ldw t0, BALL(zero) 		; load the ball x position in t0
	ldw t1, BALL+4(zero) 	; load the ball y position in t1
	ldw t2, BALL+8(zero) 	; load the ball x velocity in t2
	ldw t3, BALL+12(zero) ; load the ball y velocity in t3
	add t0, t0, t2			 	; update x position
	add t1, t1, t3 				; update y position
	stw t0, BALL(zero) 		; store new ball x position
	stw t1, BALL+4(zero) 	; store new ball y position
	ret

; END:move_ball

; BEGIN:move_paddles
move_paddles:
	ldw t0, PADDLES(zero) 	; load the left paddle y coord in t0
	ldw t1, PADDLES+4(zero) ; load the right paddle y coord in t1
	ldw t2, BUTTONS+4(zero)	; load the buttons edgecapture in t2
	addi t4, zero, 1 				; minimum y coord
	addi t5, zero, 6				; maximum y coord
	andi t3, t2, 0x0001 		; mask to take only the last bit of t2 and store in t3 (this is left paddle up)
	beq t3, zero, no_left_paddle_up ; if no input, we don't want the paddle to move
	beq t0, t4, no_left_paddle_up 	; if the paddle is already at the top it doesn't go up
	addi t0, t0, -1 								; make the left paddle go up

no_left_paddle_up:
	srli t2, t2, 1 										; shift buttons to the right to take the next button
	andi t3, t2, 0x0001 							; mask to take only the last bit of t2 and store in t3 (this is left paddle down)
	beq t3, zero, no_left_paddle_down ; if no input, we don't want the paddle to move
	beq t0, t5, no_left_paddle_down 	; if the paddle is already at the bottom it doesn't go down
	addi t0, t0, 1 										; make the left paddle go down

no_left_paddle_down:
	srli t2, t2, 1 										; shift buttons to the right to take the next button
	andi t3, t2, 0x0001 							; mask to take only the last bit of t2 and store in t3 (this is right paddle up)
	beq t3, zero, no_right_paddle_up 	; if no input, we don't want the paddle to move
	beq t1, t4, no_right_paddle_up 		; if the paddle is already at the top it doesn't go up
	addi t1, t1, -1 									; make the right paddle go up

no_right_paddle_up:
	srli t2, t2, 1 											; shift buttons to the right to take the next button
	andi t3, t2, 0x0001 								; mask to take only the last bit of t2 and store in t3 (this is right paddle down)
	beq t3, zero, no_right_paddle_down 	; if no input, we don't want the paddle to move
	beq t1, t5, no_right_paddle_down 		; if the paddle is already at the top it doesn't go up
	addi t1, t1, 1 											; make the left paddle go down

no_right_paddle_down:
	stw t0, PADDLES(zero) 							; store the new right paddle y coord
	stw t1, PADDLES+4(zero) 						; store the new left paddle y coord
	srli t2, t2, 1
	slli t2, t2, 4 											; replace the last 4 bits of buttons edgecapture with 0
	stw t2, BUTTONS+4(zero) 						; reset buttons edgecapture last 4 bits
	ret

; END:move_paddles

; BEGIN:draw_paddles
draw_paddles:
	addi sp, sp, -12 				; make room for 3 items on stack
	stw ra, 8(sp) ; push ra on stack
	stw a0, 4(sp) 					; push a0 on stack
	stw a1, 0(sp) 					; push a1 on stack
	ldw a1, PADDLES(zero) 	; load the left paddle y coord in a1
	addi a0, zero, 0 				; store the left paddle x coord in a0
	call set_pixel 					; draw the middle pixel of the left paddle
	addi a1, a1, 1
	call set_pixel 					; draw the bottom pixel of the left paddle
	addi a1, a1, -2
	call set_pixel 					; draw the top pixel of the left paddle
	ldw a1, PADDLES+4(zero) ; load the right paddle y coord in a1
	addi a0, zero, 11 			; store the right paddle x coord in a0
	call set_pixel 					; draw the middle pixel of the right paddle
	addi a1, a1, 1
	call set_pixel 					; draw the bottom pixel of the right paddle
	addi a1, a1, -2
	call set_pixel 					; draw the top pixel of the right paddle
	ldw ra, 8(sp) ; preserve ra on call
	ldw a0, 4(sp) 					; preserve a0 on call
	ldw a1, 0(sp) 					; preserve a1 on call
	addi sp, sp, 12				; hand back stack space
	ret

; END:draw_paddles

; BEGIN:display_score
display_score:
	addi sp, sp, -8 ;make room for 2 items on stack
	stw ra, 4(sp) ; push ra on stack
	stw a0, 0(sp) ; push a0 on stack
	ldw a0, SCORES(zero) ; load left player score in a0
	call get_font
	stw v0, LEDS(zero) ; store left player score
	ldw a0, SCORES+4(zero) ; load right player score in a0
	call get_font
	stw v0, LEDS+8(zero) ; store left player score
	ldw t0, font_data+64(zero)
	stw t0, LEDS+4(zero) ; store separator
	ldw ra, 4(sp) ; preserve ra on call
	ldw a0, 0(sp) ; preserve a0 on call
	addi sp, sp, 8 ; hand back stack space
	ret

get_font:
	addi t0, zero, 0
	ldw v0, font_data(zero)
	beq a0, t0, font_end ; 0
	addi t0, t0, 1
	ldw v0, font_data+4(zero)
	beq a0, t0, font_end ; 1
	addi t0, t0, 1
	ldw v0, font_data+8(zero)
	beq a0, t0, font_end ; 2
	addi t0, t0, 1
	ldw v0, font_data+12(zero)
	beq a0, t0, font_end ; 3
	addi t0, t0, 1
	ldw v0, font_data+16(zero)
	beq a0, t0, font_end ; 4
	addi t0, t0, 1
	ldw v0, font_data+20(zero)
	beq a0, t0, font_end ; 5
	addi t0, t0, 1
	ldw v0, font_data+24(zero)
	beq a0, t0, font_end ; 6
	addi t0, t0, 1
	ldw v0, font_data+28(zero)
	beq a0, t0, font_end ; 7
	addi t0, t0, 1
	ldw v0, font_data+32(zero)
	beq a0, t0, font_end ; 8
	addi t0, t0, 1
	ldw v0, font_data+36(zero)
	beq a0, t0, font_end ; 9
	addi t0, t0, 1
	ldw v0, font_data+40(zero)
	beq a0, t0, font_end ; A
	addi t0, t0, 1
	ldw v0, font_data+44(zero)
	beq a0, t0, font_end ; B
	addi t0, t0, 1
	ldw v0, font_data+48(zero)
	beq a0, t0, font_end ; C
	addi t0, t0, 1
	ldw v0, font_data+52(zero)
	beq a0, t0, font_end ; D
	addi t0, t0, 1
	ldw v0, font_data+56(zero)
	beq a0, t0, font_end ; E
	addi t0, t0, 1
	ldw v0, font_data+60(zero) ; F
font_end:
	ret
; END:display_score

wait:
	addi t0, zero, 1
	slli t0, t0, 21
loop:
	addi t0, t0, -1
	bne t0, zero, loop
end_loop:
	ret

wait_long:
	addi t0, zero, 1
	slli t0, t0, 29
loop_long:
	addi t0, t0, -1
	bne t0, zero, loop_long
end_loop_long:
	ret

font_data:
.word 0x7E427E00 ; 0
.word 0x407E4400 ; 1
.word 0x4E4A7A00 ; 2
.word 0x7E4A4200 ; 3
.word 0x7E080E00 ; 4
.word 0x7A4A4E00 ; 5
.word 0x7A4A7E00 ; 6
.word 0x7E020600 ; 7
.word 0x7E4A7E00 ; 8
.word 0x7E4A4E00 ; 9
.word 0x7E127E00 ; A
.word 0x344A7E00 ; B
.word 0x42423C00 ; C
.word 0x3C427E00 ; D
.word 0x424A7E00 ; E
.word 0x020A7E00 ; F
.word 0x00181800 ; separator