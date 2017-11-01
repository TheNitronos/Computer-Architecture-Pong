.equ BALL,    0x1000 ; ball state (its position and velocity)
.equ PADDLES, 0x1010 ; paddles position
.equ SCORES,  0x1018 ; game scores
.equ LEDS,    0x2000 ; LED addresses
.equ BUTTONS, 0x2030 ; Button addresses

; BEGIN:clear_leds
clear_leds:
	lui LEDS 0
	lui LEDS+4 0
	lui LEDS+8 0 
	ret
; END:clear_leds