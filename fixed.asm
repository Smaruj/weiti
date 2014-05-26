.macro	itofix(%fix, %int)
	sll	%fix, %int, 16
.endmacro

.macro	fixtoi(%int, %fix)
	srl	%int, %fix, 16
.endmacro

.macro	fix_add(%result, %arg1, %arg2)
	addu	%result, %arg1, %arg2
.endmacro

.macro	fix_sub(%result, %arg1, %arg2)
	subu	%result, %arg1, %arg2
.endmacro

.macro	fix_mult(%result, %arg1, %arg2, %aux)
	mulu	%aux, %arg1, %arg2
	srl	%result, %aux, 16
	mfhi	%aux
	sll	%aux, %aux, 16
	or	%result, %result, %aux
.endmacro

.macro	fix_div_int(%result, %arg1, %arg2)
	divu	%result, %arg1, %arg2
.endmacro

fix_div: # ($a0, $a1)
	divu	$a0, $a1
	mflo	$v0
	mfhi	$t0
	li	$t1, 16
.fixdivloop:
	sll	$v0, $v0, 1
	sll	$t0, $t0, 1
	blt	$t0, $a1, .fixdivloop_skip
	or	$v0, $v0, 0x0001
	subu	$t0, $t0, $a1
.fixdivloop_skip:
	addiu	$t1, $t1, -1
	bnez	$t1, .fixdivloop
	jr	$ra
