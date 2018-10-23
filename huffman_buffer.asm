include huffman_buffer.inc

.code
huffman_buffer_create PROC USES ecx, max_byte_count: SDWORD
	LOCAL buffer: PTR huffman_buffer
	mov ecx, max_byte_count
	INVOKE crt_malloc, size huffman_buffer
	mov (huffman_buffer PTR [eax]).current_byte_size, 0
	mov (huffman_buffer PTR [eax]).byte_capacity, ecx
	mov buffer, eax

	INVOKE crt_malloc, max_byte_count
	mov (huffman_buffer PTR [buffer]).buffer, eax
	; mov ecx, max_byte_count
L1:
	mov BYTE PTR (huffman_buffer PTR [buffer]).buffer[ecx - 1], 0
	loop L1

	mov eax, buffer
	ret
huffman_buffer_create ENDP

huffman_buffer_destroy PROC, buffer: PTR huffman_buffer
	.IF buffer != 0
		mov eax, (huffman_buffer PTR [buffer]).buffer
		.IF eax != 0
			INVOKE crt_free, eax
		.ENDIF
		INVOKE crt_free, buffer
	.ENDIF
	ret
huffman_buffer_destroy ENDP

huffman_buffer_insert PROC USES ebx ecx esi, buffer: PTR huffman_buffer, bit_count: SDWORD, bits: PTR BYTE
	LOCAL i: SDWORD
	LOCAL n: SDWORD
	mov i, 0
	mov esi, buffer
forloop:
	mov eax, i
	mov ebx, bit_count
	.IF eax >= ebx
		jmp quit
	.ENDIF
	.IF BYTE PTR bits[i] == 1
		mov eax, (huffman_buffer PTR [esi]).current_byte_size
		sar eax, 3

		mov ecx, (huffman_buffer PTR [esi]).current_byte_size
		and ecx, 00000007h
		mov ebx, 1
L1:
		sal ebx, 1
		loop L1

		or BYTE PTR (huffman_buffer PTR [esi]).buffer[eax], bl
	.ENDIF
	inc (huffman_buffer PTR [esi]).current_byte_size

	inc i
	jmp forloop
quit:
	ret
huffman_buffer_insert ENDP

get_compressed_size PROC USES ebx, buffer: PTR huffman_buffer
	mov eax, SDWORD PTR [buffer]
	sar eax, 3

	mov ebx, SDWORD PTR [buffer]
	and ebx, 00000007h

	.IF ebx != 0
		inc eax
	.ENDIF
	ret	
get_compressed_size ENDP
END