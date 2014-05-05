		.data
buffer:	.space 128
	
		.globl main
		.text
###
# zamiana gwiazdek na kolejne liczby
# $t1  -- wskaznik iterujacy po ciagu
# $t2  -- licznik napotkanych gwiazdek
# $t4  -- obslugiwany znak
main:
#read input
		la $a0 buffer
		li $a1 128
		li $v0 8
		syscall
		
#init
		la $t1 buffer
		li $t2 '1'

.loop:
		lb $t4 ($t1)
		blt $t4 ' ' .loop_end
		bne $t4 '*' .loop_incr
		
		move $t4 $t2
		addiu $t2 $t2 1
		sb $t4 ($t1)
		
.loop_incr:
		addiu $t1 $t1 1
		b .loop
.loop_end:	

#print output
		la $a0 buffer
		li $v0 4
		syscall
		
#exit
		li $v0 10
		syscall