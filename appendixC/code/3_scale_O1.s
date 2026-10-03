	.text
	.file	"scale.c"
	.globl	scale                           # -- Begin function scale
	.p2align	4, 0x90
	.type	scale,@function
scale:                                  # @scale
# %bb.0:
	testq	%rdx, %rdx
	jle	.LBB0_3
# %bb.1:
	xorl	%eax, %eax
	.p2align	4, 0x90
.LBB0_2:                                # =>This Inner Loop Header: Depth=1
	movsd	(%rsi,%rax,8), %xmm0            # xmm0 = mem[0],zero
	addsd	%xmm0, %xmm0
	movsd	%xmm0, (%rdi,%rax,8)
	incq	%rax
	cmpq	%rax, %rdx
	jne	.LBB0_2
.LBB0_3:
	retq
.Lfunc_end0:
	.size	scale, .Lfunc_end0-scale
                                        # -- End function
	.ident	"Ubuntu clang version 18.1.3 (1ubuntu1)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
