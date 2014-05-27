.macro printString (%mess)
		li	$v0, 4
		la	$a0, %mess
		syscall
.end_macro

.macro readString (%buf, %size)
		li	$v0, 8
		la	$a0, %buf
		move	$a1, %size
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
.end_macro

.macro closeFile (%filehandle)
		li	$v0, 16
		move	$a0, %filehandle
		syscall
.end_macro

.macro readFile (%handler, %buffer, %bytes)
		li	$v0, 14
		move	$a0, %handler
		move	$a1, %buffer
		move	$a2, %bytes
		syscall
.end_macro

.macro writeFile (%handler, %buffer, %bytes)
		li	$v0, 15
		move	$a0, %handler
		move	$a1, %buffer
		move	$a2, %bytes
		syscall
.end_macro

.macro malloc (%size)
		li	$v0, 9
		move	$a0, %size
		syscall
.end_macro

.macro exit (%imm)
		li	$v0, 17
		li	$a0, %imm
		syscall
.end_macro
