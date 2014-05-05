		.data
buffer:	.space 128
		.globl main
		.text
###
# odwracanie ciagow w nawiasach
#
# FAZA 1:
# $t1  -- wskaznik petli glownej
# $t2  -- odczytany znak
# $t3  -- wskaznik wprzod petli wewnetrznej
# $t4  -- wskaznik wspak petli wewnetrznej
# $t5  -- znak czytany wprzod
# $t6  -- znak czytany wspak
#
# FAZA 2:
# $t1  -- wskaznik czytajacy
# $t2  -- wskaznik piszacy
# $t3  -- obslugiwany znak
main:
#read input
		la $a0 buffer
		li $a1 128
		li $v0 8
		syscall

#init loop1
		la $t1 buffer

.loop1_outer:
		lb $t2 ($t1)
		beq $t2 0 .end_loop1_outer
		bne $t2 '<' .loop1_outer_continue
# $t2 == '<'
		addiu $t3 $t1 1		#$t3 = $t2 + 1
		move $t4 $t3
# $t4 search for '>'
.loop1_inner_search:
		lb $t6 ($t4)
		beq $t6 0 .end_loop1_outer
		beq $t6 '>' .loop1_end_inner_search
		addiu $t4 $t4 1
		b .loop1_inner_search
.loop1_end_inner_search:
		move $t1 $t4
		subiu $t4 $t4 1

# swap
.loop1_inner_swap:
		ble $t4 $t3 .loop1_end_inner_swap
		lb $t5 ($t3)
		lb $t6 ($t4)
		sb $t5 ($t4)
		sb $t6 ($t3)
		addiu $t3 $t3 1
		subiu $t4 $t4 1
		b .loop1_inner_swap
.loop1_end_inner_swap:
		
.loop1_outer_continue:
		addiu $t1 $t1 1
		b .loop1_outer

.end_loop1_outer:

# init loop2
		la $t1 buffer
		move $t2 $t1

.loop2:
		lb $t3 ($t1)
		beq $t3 0 .end_loop2
		beq $t3 '<' .loop2_skip_write
		beq $t3 '>' .loop2_skip_write
#do write
		sb $t3 ($t2)
		addiu $t2 $t2 1
.loop2_skip_write:
		addiu $t1 $t1 1
		b .loop2
		
.end_loop2:
		li $t3 0
		sb $t3 ($t2)
		
#write output
		la $a0 buffer
		li $v0 4
		syscall
		
#exit
		li $v0 10
		syscall