; This is a bcm43xx microcode assembly example.
;
; In this example file, r0 and r1 are always input
; registers and r2 is output.
; For input we can always have constant values or (one) memory
; operand instead of the input registers shown here.
;
; Registers:
;	GPRs:			r0 - r63
;	Offset Registers:	off0 - off5
;	SPRs:			spr000
;
; To access memory, two methods can be used. Examples follow.
; Direct linear:
;	mov r0,[0xCA]
; Indirect through Offset Register (pointer):
;	mov r0,[0xCA,off0]
;


; The target architecture. Supported versions are 5 and 15
%arch	5

; Program entry point
%start	testlabel

#define	PSM_BRC		spr848

#define ECOND_MAC_ON	0x24


.text

label:
	; ADD instructions
	add	r0,r1,r2	; add
	add.	r0,r1,r2	; add, set carry
	addc	r0,r1,r2	; add with carry
	addc.	r0,r1,r2	; add with carry, set carry

testlabel:
	; SUB instructions
	sub	r0,r1,r2	; sub
	sub.	r0,r1,r2	; sub, set carry
	subc	r0,r1,r2	; sub with carry
	subc.	r0,r1,r2	; sub with carry, set carry

	sra	r0,r1,r2	; arithmetic rightshift

	; Logical instructions
	or	r0,r1,r2	; bitwise OR
	and	r0,r1,r2	; bitwise AND
	xor	r0,r1,r2	; bitwise XOR
	sr	r0,r1,r2	; rightshift
	sl	r0,r1,r2	; leftshift

	srx	7,8,r0,r1,r2	; eXtended right shift (two input regs)

	rl	r0,r1,r2	; rotate left
	rr	r0,r1,r2	; rotate right
	nand	r0,r1,r2	; clear bits (notmask + and)

	orx	7,8,r0,r1,r2	; eXtended OR

	; Copy instruction. This is a virtual instruction
	; translated to more lowlevel stuff like OR.
	mov	r0,r2		; copy data

	; Jumps
	jmp	label		; unconditional jump
	jand	r0,r1,label	; jump if binary AND
	jnand	r0,r1,label	; jump if not binary AND
	js	r0,r1,label	; jump if all bits set
	jns	r0,r1,label	; jump if not all bits set
	je	r0,r1,label	; jump if equal
	jne	r0,r1,label	; jump if not equal
	jls	r0,r1,label	; jump if less (signed)
	jges	r0,r1,label	; jump if greater or equal (signed)
	jgs	r0,r1,label	; jump if greater (signed)
	jles	r0,r1,label	; jump if less or equal (signed)
	jl	r0,r1,label	; jump if less
	jge	r0,r1,label	; jump if greater or equal
	jg	r0,r1,label	; jump if greater
	jle	r0,r1,label	; jump if less or equal

	jzx	7,8,r0,r1,label	; Jump if zero after shift and mask
	jnzx	7,8,r0,r1,label	; Jump if nonzero after shift and mask

	; jump on external conditions
	jext	ECOND_MAC_ON,r0,r0,label  ; jump if external condition is TRUE
	jnext	ECOND_MAC_ON,r0,r0,label  ; jump if external condition is FALSE

	; Subroutines
	call	lr0,label	; store PC in lr0, call func at label
	ret	lr0,lr1		; store PC in lr0, return to lr1
				; Both link registers can be the same
				; and don't interfere.

	; TKIP sbox lookup
	tkiph	r0,r2		; Lookup high
	tkiphs	r0,r2		; Lookup high, byteswap
	tkipl	r0,r2		; Lookup low
	tkipls	r0,r2		; Lookup low, byteswap

	nap			; sleep until event

	; raw instruction
	@160	r0,r1,r2	; equivalent to  or r0,r1,r2
	@1C0	@C11, @C22, @BC3


	; Support for directional jumps.
	; Directional jumps can be used to conveniently jump inside of
	; functions without using function specific label prefixes. Note
	; that this does not establish a sub-namespace, though. "loop"
	; and "out" are still in the global namespace and can't be used
	; anymore for absolute jumps (Assembler will warn about duplication).
function_a:
	jl r0, r1, out+
 loop:
	nap
	jmp loop-
 out:
	ret lr0, lr1

function_b:
	jl r0, r1, out+
 loop:
	nap
	jmp loop-
 out:
	ret lr0, lr1


; The assembler has support for fancy assemble-time
; immediate constant expansion. This is called "complex immediates".
; Complex immediates are _always_ clamped by parentheses. There is no
; operator precedence. You must use parentheses to tell precedence.
	mov	(2 + 3),r0
	mov	(6 - 2),r0
	mov	(2 * 3),r0
	mov	(10 / 5),r0
	mov	(1 | 2),r0
	mov	(3 & 2),r0
	mov	(3 ^ 2),r0
	mov	(~1),r0
	mov	(2 << 3),r0
	mov	(8 >> 2),r0
	mov	(1 << (0x3 + 2)),r0
	mov	(1 + (2 + (3 + 4))),r0
	mov	(4 >> (((((~5 | 0x21)))) | (~((10) & 2)))),r0


; Some regression testing for the assembler follows
	mov	2,off0			; test memory stuff
	xor	0x124,r1,[0x0,off0]	; test memory stuff
	xor	0x124,r0,[0x0]		; test memory stuff
	mov	-34,r0			; negative dec numbers are supported
	or	r0,r1,@BC2		; We also support single raw operands
	mov	0xEEEE,r0		; MOV supports up to 16bit
	jand	0x3800,r0,label		; This is emulated by jnzx
	jnand	0x3800,r0,label 	; This is emulated by jzx
	or	spr06c,0,spr06c		; Can have one spr input and one spr output
	or	[0],0,[0]		; Can have one mem input and one mem output
	mov	testlabel, r0		; Can use label as immediate value


; The .initvals section generates an "Initial Values" file
; with the name "foobar" in this example, which is uploaded
; by the kernel driver on load. This is useful for writing ucode
; specific values to the chip without bloating the small ucode
; memory space with this initialization stuff.
; Values are written in order they appear here.
.initvals(foobar)
	mmio16	0x1234, 0xABC			; Write 0x1234 to MMIO register 0xABC
	mmio32	0x12345678, 0xABC		; Write 0x12345678 to MMIO register 0xABC
	phy	0x1234, 0xABC			; Write 0x1234 to PHY register 0xABC
	radio	0x1234, 0xABC			; Write 0x1234 to RADIO register 0xABC
	shm16	0x1234, 0x0001, 0x0002		; Write 0x1234 to SHM routing 0x0001, register 0x0002
	shm32	0x12345678, 0x0001, 0x0002	; Write 0x12345678 to SHM routing 0x0001, register 0x0002
