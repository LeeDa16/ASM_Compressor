include mapper.inc

comment ~
; mapper.asm内的函数
mapper_init proto

mapper_destroy proto, mappers: ptr mapper

mapper_set proto, mappers: ptr mapper, order: byte, 
	bit_length: sdword, bits: ptr byte, weight: sdword

_mapper_set_all proto, mappers: ptr mapper, forest: ptr huffman_node,
	depth: sdword, bits: ptr byte

mapper_set_all proto, mappers: ptr mapper, forest: huffman_node

~
.code

mapper_init proc uses ecx esi
	invoke crt_malloc, (size mapper) * 256
	mov ecx, 256
	mov esi, 0
L1: mov (mapper ptr [eax + size_mapper * esi]).bit_length, 0
	mov (mapper ptr [eax + size_mapper * esi]).weight, 0
	loop L1
	ret
mapper_init endp

mapper_destroy proc uses ecx esi, mappers: ptr mapper
	.if mapper != 0
		invoke crt_free, mapper
	.endif
	ret
mapper_destroy endp

mapper_set proc uses ecx ebx esi, mappers: ptr mapper, order: byte, 
	bit_length: sdword, bits: ptr byte, weight: sdword
	mov esi, mappers + size_mapper * order
	mov ebx, bit_length
	mov (mapper ptr [esi]).bit_length, ebx
	mov ebx, weight
	mov (mapper ptr [esi]).weight, ebx
	mov ecx, bit_length
L1: mov bh, bits[ecx]
	mov (mapper ptr [esi]).bits[ecx - 1], bh
	loop L1
	ret
mapper_set endp

_mapper_set_all proc uses ebx, mappers: ptr mapper, 
	forest: ptr huffman_node, depth: sdword, bits: ptr byte
	.if (huffman_node ptr forest).left_child == 0 && (huffman_node ptr forest).right_child == 0
		invoke mapper_set, mappers, (huffman_node ptr forest).key, depth + 1,
			bits, (huffman_node ptr forest).weight
		ret
	.endif
	.if (huffman_node ptr forest).left_child != 0
		mov bits[depth + 1], 0
		invoke _mapper_set_all, mappers, (huffman_node ptr forest).left_child,
			depth + 1, bits
	.endif
	.if (huffman_node ptr forest).right_child != 0
		mov bits[depth + 1], 1
		invoke _mapper_set_all, mappers, (huffman_node ptr forest).right_child,
			depth + 1, bits
	.endif
	ret
_mapper_set_all endp

mapper_set_all proc uses ecx, mappers: ptr mapper, forest: huffman_node
	local bits[256]: byte 
;------------------------------
;初始化一个字符数组，不知道能否优化
	mov ecx, 256
L1: mov bits[ecx - 1], 0
	loop L1
;------------------------------
	invoke _mapper_set_all, mappers, forest, 0, bits
	ret
mapper_set_all endp

end