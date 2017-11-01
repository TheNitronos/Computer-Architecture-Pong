.equ BALL,    0x1000 ; ball state (its position and velocity)
.equ PADDLES, 0x1010 ; paddles position
.equ SCORES,  0x1018 ; game scores
.equ LEDS,    0x2000 ; LED addresses
.equ BUTTONS, 0x2030 ; Button addresses

; BEGIN:clear_leds
clear_leds:
	sw zero, LEDS
	sw zero, LEDS+4
	sw zero, LEDS+8
	ret
; END:clear_leds

; BEGIN:set_pixel
set_pixel:
	andi $t0, $a0, 0x0003 ; save x modulo 4 in t0
	sll $t0, $t0, 3 ; multiply t0 by 8
	add $t0, $t0, $a1 ; add y to previous value. t0 should now be the pixel index within the word
	andi $t1, $a0, 0x0012 ; mask the x coord to keep only values 0, 4 and 8
	add $t1, LEDS, $t1 ; add the previous value to LEDS to find the correct LED word
	ret
; END:set_pixel
