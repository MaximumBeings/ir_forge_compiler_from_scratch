	.text
	.intel_syntax noprefix
	.file	"scale.c"
	.globl	scale                           # -- Begin function scale
	.p2align	4, 0x90
	.type	scale,@function
scale:                                  # @scale
# %bb.0:
	test	rdx, rdx
	jle	.LBB0_3
# %bb.1:
	xor	eax, eax
	.p2align	4, 0x90
.LBB0_2:                                # =>This Inner Loop Header: Depth=1
	movsd	xmm0, qword ptr [rsi + 8*rax]   # xmm0 = mem[0],zero
	addsd	xmm0, xmm0
	movsd	qword ptr [rdi + 8*rax], xmm0
	inc	rax
	cmp	rdx, rax
	jne	.LBB0_2
.LBB0_3:
	ret
.Lfunc_end0:
	.size	scale, .Lfunc_end0-scale
                                        # -- End function
	.ident	"Ubuntu clang version 18.1.3 (1ubuntu1)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
