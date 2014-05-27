.macro	itofix(%fix, %int)
	sll	%fix, %int, 16
.end_macro

.macro	fixtoi(%int, %fix)
	srl	%int, %fix, 16
.end_macro

.macro	fix_add(%result, %arg1, %arg2)
	addu	%result, %arg1, %arg2
.end_macro

.macro	fix_sub(%result, %arg1, %arg2)
	subu	%result, %arg1, %arg2
.end_macro

.macro	fix_mult(%result, %arg1, %arg2, %aux)
	mulu	%aux, %arg1, %arg2
	srl	%result, %aux, 16
	mfhi	%aux
	sll	%aux, %aux, 16
	or	%result, %result, %aux
.end_macro

.macro	fix_div_int(%result, %arg1, %arg2)
	divu	%result, %arg1, %arg2
.end_macro
