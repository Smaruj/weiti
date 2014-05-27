		.data
pre_prompt:	.asciiz "Podaj "
post_prompt:	.asciiz "\n"

pre_BMP_prompt:		.asciiz "nazwe "
input_BMP_prompt:	.asciiz "wejsciowego "
output_BMP_prompt:	.asciiz "wyjsciowego "
post_BMP_prompt:	.asciiz "pliku BMP"

cutoff_l_prompt:	.asciiz "dolna "
cutoff_u_prompt:	.asciiz "gorna "
post_cutoff_prompt:	.asciiz "jasnosc graniczna"

pre_cutoff_notice:	.asciiz "Wartosc z przedzialu ["
post_cutoff_notice:	.asciiz "]\n"

input_BMP:	.space	40
output_BMP:	.space	40

static_buffer:	.align	2
		.space	4

.eqv	BMP_HEAD_SIZE	0
.eqv	BMP_HEAD_PIXMAP	8
BMP_head_template:
		.space	4			# (+0) size of file in bytes
		.byte	0x00 0x00		# (+4)
			0x00 0x00
		.space  4			# (+8) pixel array offset

.eqv	DIB_HEAD_WIDTH	4
.eqv	DIB_HEAD_HEIGHT	8
.eqv	DIB_HEAD_BPP	14
.eqv	DIB_HEAD_SIZE	20

.include "./define.asm"
.macro printBmpPrompt(%mess)
		printString (pre_prompt)
		printString (pre_BMP_prompt)
		printString (%mess)
		printString (post_BMP_prompt)
		printString (post_prompt)
.end_macro

.macro printCutoffPrompt(%mess, %l, %u)
		printString (pre_prompt)
		printString (%mess)
		printString (post_cutoff_prompt)
		printString (post_prompt)
		printString (pre_cutoff_notice)
		printInt(%l)
		printChar('-')
		printInt(%u)
		printString (post_cutoff_notice)
.end_macro

		.globl	main
		.text
main:
#####
# get input file name
		printBmpPrompt (input_BMP_prompt)
		readString (input_BMP, 40)
		la	$a0, input_BMP
		jal	sanitizeString
#####
# get output filename
		printBmpPrompt (output_BMP_prompt)
		readString (output_BMP, 40)
		la	$a0, output_BMP
		jal	sanitizeString
#####
# get cutoff points, store in $t6 and $t7
		li	$t6, 0		# initial lower bound
		li	$t7, 255	# initial upper bound

		printCutoffPrompt (cutoff_l_prompt, $t6, $t7)
		readInt()

		move	$a0, $v0	# integer
		move	$a1, $t0	# lower bound
		move	$a2, $t1	# upper bound
		jal	trim
		sw	$v0, -4($fp)
		move	$t0, $v0	# cutoff_l ≤ cutoff_u

		printCutoffPrompt (cutoff_u_prompt, $t0, $t1)
		readInt()

		move	$a0, $v0	# integer
		move	$a1, $t0	# lower bound
		move	$a2, $t1	# upper bound
		jal	trim
		sw	$v0, -8($fp)
#####
# 1. Open input for reading, fd in $s0, bytes read so far in $s7
		li	$v0, 13
		la	$a0, input_BMP
		li	$a1, 0		# read-only flag
		li	$a2, 0
		syscall
		move	$s0, $v0
		li	$s7, 0

#####
# 2. Parse bitmap header, file size in $s1, pixel map offset in $s2
		move	$a0, $s0	# fd
		la	$a1, static_buffer
		la	$a2, BMP_head_template
		jal	parseBmpHeader
		move	$s1, $v0
		move	$s2, $v1
		addiu	$s7, $s7, 14	# BMP header is always 14 bytes

#####
# 3. Read DIB header, memory address in $s3
		li	$v0, 14
		move	$a0, $s0
		la	$a1, static_buffer
		li	$a2, 4
		syscall	# read first field of DIB header (size of header) into static_buffer
		li	$v0, 9
		lw	$a0, ($a1)
		syscall	# allocate space for DIB header on the heap
		move	$s3, $v0
		sw	$a0, 0($s3)	# since it was the first field, we store it...
		addu	$s7, $s7, $a0	# (we will read as many bytes into the file in total)
		addiu	$a2, $a0, -4	# ... and lower bytes still to be read by its size
		li	$v0, 14
		move	$a0, $s0
		addiu	$a1, $s3, 4	# ... and also we will read into memory offset by one word
		syscall

#####
# 4. Store anything in-between DIB header and DIB pixel map, memory address in $s4, size in -12($fp) if nonzero
		subu	$a0, $s2, $s7	# gap = pixmap offset - bytes read so far
		li	$s4, 0
		beqz	$a0, .skip_DIB_gap
		sw	$a0, -12($fp)
		li	$v0, 9
		syscall
		move	$s4, $v0
		move	$a2, $a0
		li	$v0, 14
		move	$a0, $s0
		move	$a1, $s4
		syscall
		addu	$s7, $s7, $a2
.skip_DIB_gap:

#####
# 5. Store DIB pixel map, memory address in $s5
		li	$v0, 9
		lw	$a0, DIB_HEAD_SIZE($s3)
		syscall
		move	$s5, $v0
		move	$a2, $a0
		li	$v0, 14
		move	$a0, $s0
		move	$a1, $s5
		syscall
		addu	$s7, $s7, $a2

#####
# 6. Store the rest of the file, memory address in $s6, size in -16($fp) if nonzero
		subu	$a0, $s1, $s7	# remainder = file size - bytes read so far
		li	$s6, 0
		beqz	$a0, .skip_DIB_end
		sw	$a0, -16($fp)
		li	$v0, 9
		syscall
		move	$s6, $v0
		move	$a2, $a0
		li	$v0, 14
		move	$a0, $s0
		move	$a1, $s6
		syscall
		addu	$s7, $s7, $a2
.skip_DIB_end:

# close the fd!!!
		li	$v0, 16
		move	$a0, $s0
		syscall

#####
# 7. Stretch the histogram (it's finally here!)
		move	$a0, $s3
		move	$a1, $s5
		lw	$a2, -4($fp)
		lw	$a3, -8($fp)
		jal	stretch

#####
# 8. Open output BMP for writing, file descriptor in $s0 again
		li	$v0, 13
		la	$a0, output_BMP
		li	$a1, 1		# write flag
		li	$a2, 0
		syscall
		move	$s0, $v0

#####
# 9. Write all the things
		li	$v0, 15
		move	$a0, $s0
		la	$a1, BMP_head_template
		li	$a2, 14
		syscall
		li	$v0, 15
		move	$a1, $s3
		lw	$a2, 0($s3)
		syscall
		beqz	$s4, .skip_write_DIB_gap
		li	$v0, 15
		move	$a1, $s4
		lw	$a2, -12($fp)
		syscall
.skip_write_DIB_gap:
		li	$v0, 15
		move	$a1, $s5
		lw	$a2, DIB_HEAD_SIZE($s3)
		syscall
		beqz	$s6, .skip_write_DIB_end
		li	$v0, 15
		move	$a1, $s6
		lw	$a2, -16($fp)
		syscall
.skip_write_DIB_end:
# close the fd!!!
		li	$v0, 16
		move	$a0, $s0
		syscall

		exit(0)

.include "./fixed.asm"

trim:
#####
# returns $a0 if within [$a1, $a2]
#         $a1 if $a0 < $a1
#         $a2 if $a0 > $a2
# QUIRK: if $a2 < $a1 will return $a2
# LEAF, NO STACK
		bge	$a0, $a1, .no_trim_left
		move	$a0, $a1
.no_trim_left:	ble	$a0, $a2, .no_trim_right
		move	$a0, $a2
.no_trim_right:	move	$v0, $a0
		jr	$ra

sanitizeString:
#####
# changes the first non-printable character into 0
# $a0 -- memory address with string
# LEAF, NO STACK
.sanit_loop:	lb	$t0, ($a0)
		addiu	$a0, $a0, 1
		bge	$t0, ' ', .sanit_loop
		li	$t0, 0
		addiu	$a0, $a0, -1
		sb	$t0, ($a0)
		jr	$ra

parseBmpHeader:
#####
# Parses the standard 14-byte BMP header
# $a0 -- file descriptor
# $a1 -- working buffer able to fit at least 4 bytes
# $a2 -- memory address of BMP header template structure
# $v0 -- file size
# $v1 -- pixel map offset
		addiu	$sp, $sp, -8
		sw	$ra, 4($sp)	# -4($fp)
		sw	$fp, 0($sp)	# -8($fp)
		addiu	$fp, $sp, 8
		
		sw	$a0, 0($fp)	# fd
		sw	$a1, 4($fp)	# static buffer
		sw	$a2, 8($fp)	# bmp header
		
		li	$v0, 14
		li	$a2, 2		# read two bytes ('BM')
		syscall
		
		li	$v0, 14
		lw	$a0, 0($fp)
		lw	$a1, 4($fp)
		li	$a2, 4		# read four bytes
		syscall
		lw	$t0, ($a1)
		lw	$t2, 8($fp)
		usw	$t0, BMP_HEAD_SIZE($t2)		# fill in the bmp template with file size
		li	$v0, 14
		syscall			# read another four bytes, ignore
		li	$v0, 14
		syscall			# read another four bytes
		lw	$t1, ($a1)
		usw	$t1, BMP_HEAD_PIXMAP($t2)	# fill in the bmp template with pixel map offset
		
		move	$v0, $t0
		move	$v1, $t1
		
		move	$sp, $fp
		lw	$fp, -8($sp)
		lw	$ra, -4($sp)
		
		jr	$ra

stretch:
#####
# $a0 -- DIB header
# $a1 -- pixel map
# $a2 -- cutoff_l
# $a3 -- cutoff_u
		addiu	$sp, $sp, -40
		sw	$ra, 36($sp)	# -4($fp)
		sw	$fp, 32($sp)	# -8($fp)
		addiu	$fp, $sp, 40
		sw	$s0, -12($fp)
		sw	$s1, -16($fp)
		sw	$s2, -20($fp)
		sw	$s3, -24($fp)

		sw	$a0, 0($fp)
		sw	$a1, 4($fp)
		sw	$a2, 8($fp)
		sw	$a3, 12($fp)

# Calculate row size, store in $s0 (pixel-width in $s3)
		lw	$s3, DIB_HEAD_WIDTH($a0)
		sll	$t0, $s3, 1
		addu	$s0, $s3, $t0
		sll	$s0, $s0, 3
		addiu	$s0, $s0, 31
		srl	$s0, $s0, 5
		sll	$s0, $s0, 2
# Store address of start of current row in $s1
		move	$s1, $a1
# Store past-the-end address in $s2
		move	$s2, $s1
		lw	$t0, DIB_HEAD_SIZE($a0)
		addu	$s2, $s2, $t0

.stretch_loop:	move	$a0, $s1
		move	$a1, $s3
		jal	stretchRow
		addu	$s1, $s1, $s0
		bne	$s1, $s2, .stretch_loop

		lw	$s3, -24($fp)
		lw	$s2, -20($fp)
		lw	$s1, -16($fp)
		lw	$s0, -12($fp)
		move	$sp, $fp
		lw	$fp, -8($sp)
		lw	$ra, -4($sp)
		jr	$ra

stretchRow:
#####
# $a0 - start of row		-> $s0 (moving pointer)
# $a1 - pixel width of row	-> $s1 (loop iterator)
# $a2 - cutoff_l
# $a3 - cutoff_u
		addiu	$sp, $sp, -56
		sw	$ra, 52($sp)
		sw	$fp, 48($sp)
		addiu	$fp, $sp, 56
		sw	$s0, -12($fp)
		sw	$s1, -16($fp)
		sw	$s2, -20($fp)
		sw	$s3, -24($fp)
		sw	$s4, -28($fp)
		sw	$s5, -32($fp)
		sw	$s6, -36($fp)
		sw	$s7, -40($fp)

		move	$s0, $a0
		move	$s1, $a1
		subu	$s6, $a3, $a2	# s6 = cutoff_u - cutoff_l
.stretchrow_loop:
# calculate lightness of the pixel
		lbu	$s2, 0($s0)	#BLUE
		lbu	$s3, 1($s0)	#GREEN
		lbu	$s4, 2($s0)	#RED
		addu	$s5, $s2, $s3
		addu	$s5, $s5, $s4	#R+G+B
# maybe below cutoff_l
		bgeu	$s5, $a2, .pixelnotblack
		sb	$zero, 0($s0)
		sb	$zero, 1($s0)
		sb	$zero, 2($s0)
		b	.stretchrow_iterate
.pixelnotblack:
		bleu	$s5, $a3, .pixelnotwhite
		li	$t0, 0xFF
		sb	$t0, 0($s0)
		sb	$t0, 1($s0)
		sb	$t0, 2($s0)
		b	.stretchrow_iterate
.pixelnotwhite:
# linear interpolation of desired lightness
		subu	$a0, $s5, $a2
		jal	itofix
		move	$a0, $v0
		move	$a1, $s6
		jal	fix_divint
		move	$s7, $v0	# result
# lightness change factor
		li	$a0, 765
		jal	itofix
		move	$a0, $v0
		move	$a1, $s5
		jal	fix_divint
		move	$a0, $s7
		move	$a1, $v0
		jal	fix_mult
		move	$s5, $v0	# result

# apply new lightness to pixel
# BLUE
		move	$a0, $s2
		jal	itofix
		move	$a0, $v0
		move	$a1, $s5
		jal	fix_mult
		move	$a0, $v0
		jal	fixtoi
		sb	$v0, 0($s0)
		
		move	$a0, $s3
		jal	itofix
		move	$a0, $v0
		move	$a1, $s5
		jal	fix_mult
		move	$a0, $v0
		jal	fixtoi
		sb	$v0, 1($s0)
		
		move	$a0, $s4
		jal	itofix
		move	$a0, $v0
		move	$a1, $s5
		jal	fix_mult
		move	$a0, $v0
		jal	fixtoi
		sb	$v0, 2($s0)
.stretchrow_iterate:
		addiu	$s0, $s0, 3
		addiu	$s1, $s1, -1
		bnez	$s1, .stretchrow_loop
		
		lw	$s7, -40($fp)
		lw	$s6, -36($fp)
		lw	$s5, -32($fp)
		lw	$s4, -28($fp)
		lw	$s3, -24($fp)
		lw	$s2, -20($fp)
		lw	$s1, -16($fp)
		lw	$s0, -12($fp)
		move	$sp, $fp
		lw	$ra, -4($sp)
		lw	$fp, -8($sp)
		jr	$ra
