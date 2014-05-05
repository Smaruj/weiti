.macro printString (%mess)
		li	$v0, 4
		la	$a0, %mess
		syscall
.end_macro

.macro printChar (%val)
		li	$v0, 11
		li	$a0, %val
		syscall
.end_macro

.macro readString (%buf, %size)
		li	$v0, 8
		la	$a0, %buf
		li	$a1, %size
		syscall
.end_macro

.macro printInt (%reg)
		li	$v0, 1
		move	$a0, %reg
		syscall
.end_macro

.macro readInt
		li	$v0, 5
		syscall
.end_macro

.macro exit (%imm)
		li	$v0, 17
		li	$a0, %imm
		syscall
.end_macro
