		.data
input_pt:	.asciiz "Podaj nazwe wejsciowego pliku BMP: "
output_pt:	.asciiz "Podaj nazwe wyjsciowego pliku BMP: "
settings_pt:	.asciiz "Podaj parametry algorytmu rozjasniena...\n"
lower_pt:	.asciiz "Jasnosc czerni: "
upper_pt:	.asciiz "Jasnosc bieli: "

read_buffer:	.align 2
		.space 120	# BITMAPV5HEADER

		.globl main
		.text

main:
.include "./define.asm"
.include "./fixed.asm"

##################################################
# Czytanie nazwy pliku wejsciowego
		printString(input_pt)
		li		$s7, 120
		readString(read_buffer, $s7)
		jal sanitizeString

		openFile(read_buffer, RO)
		move		$s0, $v0
		
##################################################
# Czytanie nazwy pliku wyjsciowego
		printString(output_pt)
		readString(read_buffer, $s7)
		jal sanitizeString

		openFile(read_buffer, RW)
		move		$s1, $v0

		move		$s2, $zero

##################################################
# Naglowek pliku pozostaje bez zmian: przepisujemy
		li		$s7, 2
		la		$t7, read_buffer
		readFile ($s0, $t7, $s7)
		addiu		$s2, $s2, 2
		writeFile($s1, $t7, $s7) # "BM"

		li		$s7, 12
		readFile ($s0, $t7, $s7)
		addiu		$s2, $s2, 12
		lw		$s3, 0($t7) # rozmiar pliku
		lw		$s4, 8($t7) # offset mapy pikseli
		writeFile($s1, $t7, $s7)

		li		$s7, 4
		readFile ($s0, $t7, $s7)
		writeFile($s1, $t7, $s7)
		lw		$s7, ($t7)
		addu		$s2, $s2, $s7
		subiu		$s7, $s7, 4
		readFile ($s0, $t7, $s7)
		writeFile($s1, $t7, $s7)
		lw		$s5,  ($t7) # szerokosc mapy
		lw		$s6, 4($t7) # wysokosc mapy

##################################################
# Przepisujemy wszystko pomiedzy koncem naglowka
# DIB a poczatkiem mapy pikseli
		subu		$t0, $s4, $s2
		li		$t1, 120
		beqz		$t0, .skip_GAP1
.GAP1_loop:	move		$s7, $t0
		ble		$t0, $t1, .GAP1_fits
		move		$s7, $t1
.GAP1_fits:	readFile ($s0, $t7, $s7)
		addu		$s2, $s2, $s7
		subu		$t0, $t0, $s7
		writeFile($s1, $t7, $s7)
		bgtz		$t0, .GAP1_loop
.skip_GAP1:

##################################################
# Policzmy rozmiar wiersza mapy w bajtach
		sll		$t0, $s5, 1
		addu		$t0, $t0, $s5
		sll		$t0, $t0, 3	# $t0 = 24 × $s5
		addiu		$t0, $t0, 31
		srl		$t0, $t0, 5
		sll		$t8, $t0, 2

##################################################
# Jesli mniejszy od 120, to mozemy uzyc juz
# istniejacego bufora statycznego
		li		$t0, 120
		ble		$t8, $t0, .use_static
		malloc ($t8)
		move		$t7, $v0
.use_static:

##################################################
# Wartosc bezwzgledna wysokosci mapy
		abs		$t9, $s6

##################################################
# Czytanie parametrow algorytmu
		printString(settings_pt)
		printString(lower_pt)
		readInt()
		move		$t5, $v0
		printString(upper_pt)
		readInt()
		move		$t6, $v0

##################################################
# Wyliczenie mnożnika dla interpolacji
		li		$t0, 255
		itofix ($t1, $t0)
		subu		$t0, $t6, $t5
		fix_div_int ($t4, $t1, $t0)	

##################################################
# Adres w buforze, bedacy koncem wiersza mapy
# pikseli -- do sprawdzania warunku konca petli
		sll		$t0, $s5, 1
		addu		$t0, $t0, $s5	# $t0 = 3 × $s5
		addu		$t3, $t7, $t0

##################################################
# Filtrujemy plik zgodnie z algorytmem
.filter_loop:	readFile ($s0, $t7, $t8)
		addu		$s2, $s2, $t8
		subiu		$t9, $t9, 1
		move		$t1, $t7
.filtr_inner:	lbu		$t0, ($t1)
		bge		$t0, $t6, .to_ones
		subu		$t0, $t0, $t5
		blez		$t0, .to_zeros
		itofix ($t2, $t0)
		fix_mult ($t2, $t2, $t4, $t0)
		fixtoi ($t0, $t2)
		b		.inc
.to_zeros:	move		$t0, $zero
		b		.inc
.to_ones:	li		$t0, 0xFF
.inc:		sb		$t0, ($t1)
		addiu		$t1, $t1, 1
		bne		$t1, $t3, .filtr_inner
		writeFile($s1, $t7, $t8)
		bnez		$t9, .filter_loop

##################################################
# Przepisujemy wszystko miedzy koncem mapy
# pikseli a koncem pliku
		subu		$t0, $s3, $s2
		li		$t1, 120
		beqz		$t0, .skip_GAP2
		la		$t7, read_buffer
.GAP2_loop:	move		$s7, $t0
		ble		$t0, $t1, .GAP2_fits
		move		$s7, $t1
.GAP2_fits:	readFile ($s0, $t7, $s7)
		addu		$s2, $s2, $s7
		subu		$t0, $t0, $s7
		writeFile($s1, $t7, $s7)
		bgtz		$t0, .GAP2_loop
.skip_GAP2:

		closeFile($s0)
		closeFile($s1)
		exit(0)

sanitizeString:
.sanit_loop:	lb	$t0, ($a0)
		addiu	$a0, $a0, 1
		bge	$t0, ' ', .sanit_loop
		li	$t0, 0
		addiu	$a0, $a0, -1
		sb	$t0, ($a0)
		jr	$ra
		
