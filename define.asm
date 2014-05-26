.macro printString (%mess)
		li	$v0, 4
		la	$a0, %mess
		syscall
.end_macro

.macro readString (%buf, %size)
		li	$v0, 8
		la	$a0, %buf
		li	$a1, %size
		syscall
.end_macro

.macro readInt
		li	$v0, 5
		syscall
.end_macro

.eqv RO 0
.eqv RW 1
.macro openFile (%filename, %flag)
		li	$v0, 13
		la	$a0, %filename
		li	$a1, %flag
		syscall
.endmacro

.macro readFile (%handler, %buffer, %bytes)
		li	$v0, 14
		move	$a0, %handler
		la	$a1, %buffer
		move	$a2, %bytes
		syscall
.endmacro

.macro writeFile (%handler, %buffer, %bytes)
		li	$v0, 15
		move	$a0, %handler
		la	$a1, %buffer
		move	$a2, %bytes
		syscall
.endmacro

.macro malloc (%size)
		li	$v0, 9
		li	$a0, %size
		syscall
.endmacro

.macro exit (%imm)
		li	$v0, 17
		li	$a0, %imm
		syscall
.end_macro
