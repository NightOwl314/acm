TITLE Integer Summation Program		      (Sum2.asm)

; This program inputs multiple integers from the user,
; stores them in an array, calculates the sum of the
; array, and displays the sum.

INCLUDE Irvine32.inc

.code
main PROC
	call ReadInt		; read integer into EAX
	mov ebx,eax
	call ReadInt		; read integer into EAX
	add eax, ebx		; add ebx to eax
	call WriteInt     ; write integer from EAX
	exit
main ENDP

END main
