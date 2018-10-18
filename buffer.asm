.data
huffman_buffer struct
	current_byte_size 	sdword 0
	byte_capacity 		sdword 0
	buffer 				ptr byte 1 dup(?)
huffman_buffer end


huffman_buffer_create proto, max_byte_count: sdword
huffman_buffer_destroy proto, buffer: ptr huffman_buffer
huffman_buffer_insert proto, buffer: ptr huffman_buffer, bit_count: sdword, bits: ptr byte
get_compress_size proto, data_buffer: ptr huffman_buffer

.code
huffman_buffer_create proc, max_byte_count: sdword
	local buffer: ptr huffman_buffer
	pushad
	invoke crt_malloc, sizeof huffman_buffer
	mov buffer, eax
	mov sdword ptr [buffer], 0
	mov sdword ptr [buffer + 4], 0
	invoke crt_malloc, sizeof max_byte_count
	mov edi, eax
	mov ecx, max_byte_count
L1:
	mov byte ptr [edi], 0
	inc edi
	loop L1

	mov ptr byte ptr [buffer + 8], eax
	popad
	mov eax, huffman_buffer ptr buffer
	ret
huffman_buffer_create endp

huffman_buffer_destroy proc, buffer: ptr huffman_buffer
	pushad
	mov eax, huffman_buffer
	.if eax != 0
		.if [eax + 8] != 0
			invoke crt_free, [eax + 8]
		.endif
		invoke crt_free, eax
	.endif
	popad
	ret
huffman_buffer_destroy end

huffman_buffer_insert proc, buffer: ptr huffman_buffer, bit_count: sdword, bits: ptr byte
	local i: sdword
	pushad
	mov i, 0
forloop:
	.if i >= bit_count
		jmp Exit
	.endif
	.if byte ptr [bits + i] == 1
		mov esi, buffer + 8
		mov eax, sdword ptr [buffer]
		sar eax, 3
		mov ebx, sdword ptr [buffer]
		and ebx, 0x00000007h
		mov ecx, 1
		sal ecx, ebx
		add eax, esi
		or [eax], ecx
	.endif
	inc [buffer]

	inc i
	jmp ForLoop
exit:
	popad
	ret
huffman_buffer_insert endp

get_compress_size proc, buffer: ptr huffman_buffer
	push ebx

	mov eax, sdword ptr [buffer]
	sar eax, 3
	
	mov ebx, sdword ptr [buffer]
	and ebx, 0x00000007h
	
	.if ebx != 0
		inc eax
	.endif
	
	pop ebx
	ret
get_compress_size endp
