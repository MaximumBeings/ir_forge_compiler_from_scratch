scale:                                  # @scale
# %bb.0:
	test	rdx, rdx
	jle	.LBB0_3
# %bb.1:
	xor	eax, eax
.LBB0_2:                                # =>This Inner Loop Header: Depth=1
	movsd	xmm0, qword ptr [rsi + 8*rax]   # xmm0 = mem[0],zero
	addsd	xmm0, xmm0
	movsd	qword ptr [rdi + 8*rax], xmm0
	inc	rax
	cmp	rdx, rax
	jne	.LBB0_2
.LBB0_3:
	ret
