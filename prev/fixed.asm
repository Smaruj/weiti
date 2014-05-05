itofix: # ($a0)
	sll	$v0, $a0, 16
	jr	$ra

fixtoi: # ($a0)
	srl	$v0, $a0, 16
	jr	$ra

fix_add: # ($a0, $a1)
	addu	$v0, $a0, $a1
	jr	$ra

fix_sub: # ($a0, $a1)
	subu	$v0, $a0, $a1
	jr	$ra

fix_mult: # ($a0, $a1)
	mulu	$t0, $a0, $a1
	srl	$v0, $t0, 16
	mfhi	$t0
	sll	$t0, $t0, 16
	or	$v0, $v0, $t0
	jr	$ra

fix_divint: # ($a0, $a1)
	divu	$v0, $a0, $a1
	jr	$ra

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
