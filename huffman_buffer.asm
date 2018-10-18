.data
huffman_buffer STRUCT
	current_byte_size 	SDWORD 0
	byte_capacity 		SDWORD 0
	buffer 				PTR END 1 dup(?)
huffman_buffer END

mapper STRUCT
mapper END


huffman_buffer_create PROTO, max_byte_count: SDWORD
huffman_buffer_destroy PROTO, buffer: PTR huffman_buffer
huffman_buffer_insert PROTO, buffer: PTR huffman_buffer, bit_count: SDWORD, bits: PTR BYTE
get_compress_size PROTO, data_buffer: PTR huffman_buffer
compress_into_buffer PROTO, file_name: PTR BYTE, buffer: PTR huffman_buffer, mappers: PTR mapper
save_encode_into_buffer PROTO, buffer: PTR huffman_buffer, decompressed_size: SDWORD, compressed_size: SDWORD, password: PTR BYTE, mappers: PTR mapper
write_into_file PROTO, info_buffer: PTR huffman_buffer, data_buffer: PTR huffman_buffer, file_name: PTR BYTE

.code
huffman_buffer_create PROC, max_byte_count: SDWORD
	LOCAL buffer: PTR huffman_buffer
	pushad
	INVOKE crt_malloc, sizeof huffman_buffer
	mov buffer, eax
	mov SDWORD PTR [buffer], 0
	mov SDWORD PTR [buffer + 4], 0
	INVOKE crt_malloc, sizeof max_byte_count
	mov edi, eax
	mov ecx, max_byte_count
L1:
	mov BYTE PTR [edi], 0
	inc edi
	loop L1

	mov PTR BYTE PTR [buffer + 8], eax
	popad
	mov eax, huffman_buffer PTR buffer
	ret
huffman_buffer_create ENDP

huffman_buffer_destroy PROC, buffer: PTR huffman_buffer
	pushad
	mov eax, huffman_buffer
	.IF eax != 0
		.IF [eax + 8] != 0
			INVOKE crt_free, [eax + 8]
		.ENDIF
		INVOKE crt_free, eax
	.ENDIF
	popad
	ret
huffman_buffer_destroy END

huffman_buffer_insert PROC, buffer: PTR huffman_buffer, bit_count: SDWORD, bits: PTR BYTE
	LOCAL i: SDWORD
	pushad
	mov i, 0
forloop:
	.IF i >= bit_count
		jmp quit
	.ENDIF
	.IF BYTE PTR [bits + i] == 1
		mov esi, buffer + 8
		mov eax, SDWORD PTR [buffer]
		sar eax, 3
		mov ebx, SDWORD PTR [buffer]
		and ebx, 00000007h
		mov ecx, 1
		sal ecx, ebx
		add eax, esi
		or [eax], ecx
	.ENDIF
	inc [buffer]

	inc i
	jmp ForLoop
quit:
	popad
	ret
huffman_buffer_insert ENDP

get_compress_size PROC, buffer: PTR huffman_buffer
	push ebx

	mov eax, SDWORD PTR [buffer]
	sar eax, 3
	
	mov ebx, SDWORD PTR [buffer]
	and ebx, 00000007h
	
	.IF ebx != 0
		inc eax
	.ENDIF
	
	pop ebx
	ret
get_compress_size ENDP

compress_into_buffer PROC, file_name: PTR BYTE, buffer: PTR huffman_buffer, mappers: PTR mapper
	LOCAL file_stream: HANDLE
	LOCAL mode: BYTE "rb", 0
	LOCAL c: SDWORD
	pushad
	
	mov file_stream, 0
	INVOKE crt_fopen, file_name, OFFSET mode
	.IF	eax == 0
		jmp quit
	.ENDIF
	mov file_stream, eax

L1:
	INVOKE crt_fgetc, file_stream
	mov c, eax
	.IF c == -1
		jmp quit
	.ENDIF

	mov esi, mapper
	add esi, c
	INVOKE huffman_buffer_insert, buffer, SDWORD PTR [esi], PTR BYTE PTR [esi + 4]
	jmp L1

quit:
	INVOKE crt_fclose, file_stream
	popad
	ret
compress_into_buffer ENDP

DECODE_INFO_BUFFER_SIZE = 2 * 4 + 16 + 4 * 256

save_encode_into_buffer PROC, buffer: PTR huffman_buffer, decompressed_size: SDWORD, compressed_size: SDWORD, password: PTR BYTE, mappers: PTR mapper
	LOCAL password_offset: PTR BYTE
	LOCAL data_offset: PTR BYTE
	pushad
	mov esi, buffer
	add esi, 8
	mov SDWORD PTR [esi], decompressed_size
	mov SDWORD PTR [esi + 4], compressed_size

	add esi, 4
	mov password_offset, esi

	mov esi, 0
L1:
	.IF esi >= 16
		jmp quit_loop1
	.ENDIF
	mov password_offset[esi], password[esi]
	inc esi
	jmp L1

quit_loop1:
	mov data_offset, password_offset + 16

	mov ecx, 0
L2:
	.IF ecx >= 256
		jmp quit_loop2
	.ENDIF
	mov edi, ecx
	sal edi, 2

	imul esi, ecx, SIZEOF mapper
	mov esi, OFFSET mappers[esi]
	add esi, 260

	mov SDWORD PTR data_offset[edi], SDWORD PTR [esi]
	inc ecx
	jmp L2

quit_loop2:
	mov eax, DECODE_INFO_BUFFER_SIZE
	shl eax
	add PTR SDWORD [buffer], eax

	popad
	ret
save_encode_into_buffer ENDP

write_into_file PROC, info_buffer: PTR huffman_buffer, data_buffer: PTR huffman_buffer, file_name: PTR BYTE
	LOCAL file_stream: HANDLE
	LOCAL mode: BYTE "wb", 0
	LOCAL count: SDWORD
	pushad
	mov file_stream, 0
	INVOKE crt_fopen, file_name, OFFSET mode
	.IF eax == 0
		jmp quit
	.ENDIF

	.IF info_buffer != 0
		mov eax, SDWORD PTR [info_buffer]
		sar eax, 3

		mov ebx, SDWORD PTR [info_buffer]
		and ebx, 00000007h

		.IF ebx != 0
			inc eax
		.ENDIF

		mov count, eax
		mov ecx, 0
		mov esi, info_buffer
		add esi, 8
L1:
		.IF ecx >= count
			jmp quit_loop1
		.ENDIF
		add esi, ecx
		push esi
		push ecx
		INVOKE crt_fputc, esi, file_stream
		pop ecx
		pop esi

		inc ecx
		jmp L1
quit_loop1:
	.ENDIF

	.IF data_buffer != 0
		mov eax, SDWORD PTR [data_buffer]
		sar eax, 3

		mov ebx, SDWORD PTR [data_buffer]
		and ebx, 00000007h

		.IF ebx != 0
			inc eax
		.ENDIF

		mov count, eax
		mov ecx, 0
		mov esi, data_buffer
		add esi, 8

L2:
		.IF ecx >= count
			jmp
		.ENDIF
		add esi, ecx
		push esi
		push ecx
		INVOKE crt_fputc, esi, file_stream
		pop ecx
		pop esi

		inc ecx
		jmp L2
quit_loop2:
	.ENDIF
quit:
	INVOKE crt_fclose, file_stream
	popad
	ret
write_into_file ENDP

