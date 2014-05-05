		.data
buffer:	.space 128
		.globl main
		.text
###
# usuwanie dużych liter
# $t1  -- wskaznik czytajacy
# $t2  -- wskaznik piszacy
# $t3  -- obslugiwany znak
main:
#read input
		la $a0 buffer
		li $a1 128
		li $v0 8
		syscall
		
#init
		la $t1 buffer
		move $t2 $t1
		
.loop:
		lb $t3 ($t1)
		beq $t3 0 .end_loop
		blt $t3 'a' .skip_write
		bgt $t3 'z' .skip_write
#do write		
		sb $t3 ($t2)
		addiu $t2 $t2 1
.skip_write:
		addiu $t1 $t1 1
		b .loop
.end_loop:
		li $t3 0
		sb $t3 ($t2)

#write output
		la $a0 buffer
		li $v0 4
		syscall
		
#exit
		li $v0 10
		syscall