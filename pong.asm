.equ BALL,    0x1000 ; ball state (its position and velocity)
.equ PADDLES, 0x1010 ; paddles position
.equ SCORES,  0x1018 ; game scores
.equ LEDS,    0x2000 ; LED addresses
.equ BUTTONS, 0x2030 ; Button addresses

; BEGIN:main
main:
	addi t0, zero, 0x0005
	addi t1, zero, 0x0001
	stw t0, BALL(zero)
	stw t0, BALL+4(zero)
	stw t1, BALL+8(zero)
	stw t1, BALL+8(zero)
ball_loop:
	call clear_leds
	call move_ball
	ldw a0, BALL(zero)
	ldw a1, BALL+4(zero)
	call set_pixel
	call hit_test
	call ball_loop
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
	andi t0, a0, 0x0003 ; save x modulo 4 in t0
	slli t0, t0, 3 ; multiply t0 by 8
	add t0, t0, a1 ; add y to previous value. t0 should now be the pixel index within the word
	andi t1, a0, 0x000C ; mask the x coord to keep only values 0, 4 and 8
	addi t1, t1, LEDS ; add the previous value to LEDS to find the correct LED word
	ldw t3, 0(t1) ; load the correct LED word in t3
	addi t2, zero, 0x0001
	sll t2, t2, t0 ; prepare a mask for the correct pixel index in t2
	or t3, t3, t2 ; set the correct pixel index to 1 via an or operation with t2
	stw t3, 0(t1) ; save the new word in the correct LED address
	ret
; END:set_pixel

; BEGIN:hit_test
hit_test
	ldw t1, BALL						; store x-axis position in t1
	ldw t2, BALL(4)					; store y-axis position in t2
	beq t1, zero, invert_y 	; hit y-axis left
	beq t1, 11, invert_y		; hit y-axis right
	beq t2, zero, invert_x 	; hit x-axis up
	beq t2, 7, invert_x			; hit x-axis bottom
	call move_ball	 				; then move the ball
	ret

invert_x:
	ldw t1, BALL(8)
	not t2, t1
	add t2, t2, 1
	stw BALL(8), t2
	ret

invert_y:
	ldw t1, BALL(12)
	not t2, t1
	add t2, t2, 1
	stw BALL(12), t2
	ret

; END:hit_test

; BEGIN:move_ball
move_ball:
	ldw t0, BALL(zero) ; load the ball x position in t0
	ldw t1, BALL+4(zero) ; load the ball y position in t1
	ldw t2, BALL+8(zero) ; load the ball x velocity in t2
	ldw t3, BALL+12(zero) ; load the ball y velocity in t3
	add t0, t0, t2 ; update x position
	add t1, t1, t3 ; update y position
	stw t0, BALL(zero) ; store new ball x position
	stw t1, BALL+4(zero) ; store new ball y position
	ret
; END:move_ball

; BEGIN:move_paddles
move_paddles:
	ret
; END:move_paddles