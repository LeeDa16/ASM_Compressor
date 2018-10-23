include huffman_buffer.inc

.data
rb_mode BYTE "rb", 0
wb_mode BYTE "wb", 0

.code
huffman_buffer_create PROC USES ebx ecx esi, max_byte_count: SDWORD
	LOCAL buffer: DWORD
	mov ebx, max_byte_count
	pushad
	INVOKE crt_malloc, SIZE huffman_buffer
	mov (huffman_buffer PTR [eax]).current_byte_size, 0
	mov (huffman_buffer PTR [eax]).byte_capacity, ebx
	mov buffer, eax
	popad

	INVOKE crt_malloc, max_byte_count
	mov ebx, buffer
	mov (huffman_buffer PTR [ebx]).buffer, eax
	.IF max_byte_count == 0
		jmp quit
	.ENDIF
	mov esi, eax
	mov ecx, max_byte_count
L1:
	; mov BYTE PTR (huffman_buffer PTR [ebx]).buffer[ecx - 1], 0
	mov BYTE PTR [esi + ecx - 1], 0
	loop L1

quit:
	mov eax, buffer
	ret
huffman_buffer_create ENDP

huffman_buffer_destroy PROC USES esi, buffer: PTR huffman_buffer
	.IF buffer != 0
		mov esi, buffer
		mov esi, (huffman_buffer PTR [esi]).buffer
		.IF esi != 0
			INVOKE crt_free, esi
		.ENDIF
		mov esi, buffer
		INVOKE crt_free, esi
	.ENDIF
	ret
huffman_buffer_destroy ENDP

huffman_buffer_insert PROC USES ebx ecx esi, buffer: PTR huffman_buffer, bit_count: SDWORD, bits: PTR BYTE
	LOCAL i: SDWORD
	mov i, 0
forloop:
	mov esi, buffer
	mov eax, i
	mov ebx, bit_count
	.IF eax >= ebx
		jmp quit
	.ENDIF
	mov ebx, bits
	add ebx, i
	.IF BYTE PTR [ebx] == 1
		mov eax, (huffman_buffer PTR [esi]).current_byte_size
		sar eax, 3

		mov ecx, (huffman_buffer PTR [esi]).current_byte_size
		and ecx, 00000007h
.IF		ecx != 0
		mov ebx, 1
L1:
		sal ebx, 1
		loop L1
.ENDIF
		; or BYTE PTR (huffman_buffer PTR [esi]).buffer[eax], bl
		; mov esi, buffer
		mov esi, (huffman_buffer PTR [esi]).buffer
		or BYTE PTR [esi + eax], bl
	.ENDIF
	inc (huffman_buffer PTR [esi]).current_byte_size

	inc i
	jmp forloop
quit:
	ret
huffman_buffer_insert ENDP

get_compressed_size PROC USES ebx esi, buffer: PTR huffman_buffer
	mov esi, buffer
	mov eax, SDWORD PTR [esi]
	sar eax, 3

	mov ebx, SDWORD PTR [esi]
	and ebx, 00000007h

	.IF ebx != 0
		inc eax
	.ENDIF
	ret	
get_compressed_size ENDP


compress_into_buffer PROC USES esi edi, file_name: PTR BYTE, buffer: PTR huffman_buffer, mappers: PTR mapper
	LOCAL file_stream: DWORD
	LOCAL char: SDWORD
	
	mov file_stream, 0
	pushad
	INVOKE crt_fopen, file_name, OFFSET rb_mode
	.IF	eax == 0
		ret
	.ENDIF
	mov file_stream, eax
	popad

L1:
	pushad
	INVOKE crt_fgetc, file_stream
	mov char, eax
	popad
	.IF char == -1
		jmp quit
	.ENDIF

	mov esi, SIZE mapper
	imul esi, char
	add esi, mappers
	mov edi, esi
	add esi, 4
	; mov esi, mappers
	; add esi, char
	; mov edi, esi
	; add esi, 4
	INVOKE huffman_buffer_insert, buffer, (mapper PTR [edi]).bit_length, esi
	jmp L1

quit:
	INVOKE crt_fclose, file_stream
	ret
compress_into_buffer ENDP

save_encode_info_into_buffer PROC USES ebx ecx edx esi, buffer: PTR huffman_buffer, decompressed_size: SDWORD, compressed_size: SDWORD, password: PTR BYTE, mappers: PTR mapper
	LOCAL password_offset: PTR BYTE
	LOCAL data_offset: PTR BYTE
	
	mov eax, buffer
	mov eax, (huffman_buffer PTR [eax]).buffer
	mov ebx, decompressed_size
	mov SDWORD PTR [eax], ebx
	add eax, 4
	mov ebx, compressed_size
	mov SDWORD PTR [eax], ebx

	add eax, 4
	mov password_offset, eax

 	mov ecx, 16
	mov esi, password
	mov edi, password_offset
L1:
	mov eax, 16
	sub eax, ecx
	mov bl, BYTE PTR [esi + eax]
	mov BYTE PTR [edi + eax], bl
	loop L1

	mov data_offset, edi
	add data_offset, 16

	mov ecx, 256
	mov esi, mappers
L2:
	; push ecx
	; dec ecx

	; mov eax, SIZE mapper
	; mul ecx

	; mov esi, mappers
	; add esi, eax
	; mov eax, (mapper PTR [esi]).weight

	; mov ebx, ecx
	; ; imul ebx, 4
	; sal ebx, 2
	; add ebx, data_offset
	; mov SDWORD PTR [ebx], eax
	; pop ecx

	mov eax, 256
	sub eax, ecx
	mov ebx, eax
	mov edx, SIZE mapper
	mul edx
	; add esi, eax
	mov eax, (mapper PTR [esi + eax]).weight
	imul ebx, 4
	add ebx, data_offset
	mov SDWORD PTR [ebx], eax
	loop L2

	mov ebx, DECODE_INFO_BUFFER_SIZE
	sal ebx, 3
	mov eax, buffer
	add (huffman_buffer PTR [eax]).current_byte_size, ebx
	ret
save_encode_info_into_buffer ENDP

write_into_file PROC USES ebx ecx esi, info_buffer: PTR huffman_buffer, data_buffer: PTR huffman_buffer, file_name: PTR BYTE
	LOCAL file_stream: DWORD
	LOCAL count: SDWORD
	
	mov file_stream, 0
	pushad
	INVOKE crt_fopen, file_name, OFFSET wb_mode
	mov file_stream, eax
	popad
	.IF file_stream == 0
		ret
	.ENDIF

	.IF info_buffer != 0
		mov eax, info_buffer
		mov eax, (huffman_buffer PTR [eax]).current_byte_size
		mov ebx, eax
		sar eax, 3
		and ebx, 00000007h
		.IF ebx != 0
			inc eax
		.ENDIF

		mov count, eax
		.IF count == 0
			jmp quit
		.ENDIF
		mov ecx, count
L1:
		mov eax, count
		sub eax, ecx
		mov esi, info_buffer
		mov esi, (huffman_buffer PTR [esi]).buffer
		add esi, eax
		pushad
		INVOKE crt_fputc, BYTE PTR [esi], file_stream
		popad

		loop L1
	.ENDIF

	.IF data_buffer != 0
		mov eax, data_buffer
		mov eax, (huffman_buffer PTR [eax]).current_byte_size
		mov ebx, eax
		sar eax, 3
		and ebx, 00000007h
		.IF ebx != 0
			inc eax
		.ENDIF

		mov count, eax
		.IF count == 0
			jmp quit
		.ENDIF
		mov ecx, count
L2:
		mov count, eax
		sub eax, ecx
		mov esi, data_buffer
		mov esi, (huffman_buffer PTR [esi]).buffer
		add esi, eax
		pushad
		INVOKE crt_fputc, esi, file_stream
		popad

		loop L2
	.ENDIF
quit:
	pushad
	INVOKE crt_fclose, file_stream
	popad

	ret
write_into_file ENDP

; read_from_file PROC USES ecx esi, info_buffer: PTR PTR huffman_buffer, data_buffer: PTR PTR huffman_buffer, file_name: PTR BYTE
; 	LOCAL file_stream: DWORD
; 	LOCAL tmpc: BYTE
; 	LOCAL m_size: SDWORD

; 	mov file_stream, 0
; 	pushad
; 	INVOKE crt_fopen, file_name
; 	mov file_stream, eax
; 	popad
; 	.IF file_stream == 0
; 		ret
; 	.ENDIF

; 	.IF info_buffer != 0
; 		INVOKE huffman_buffer_create, DECODE_INFO_BUFFER_SIZE
; 		mov [info_buffer], eax

; 		mov ecx, DECODE_INFO_BUFFER_SIZE
; L1:
; 		mov eax, DECODE_INFO_BUFFER_SIZE
; 		sub eax, ecx

; 		mov esi, [info_buffer]
; 		mov esi, (huffman_buffer PTR [esi]).buffer
; 		add esi, eax

; 		pushad
; 		INVOKE crt_fgetc, file_stream
; 		mov tmpc, al
; 		popad
; 		mov al, tmpc
; 		mov BYTE PTR [esi], al
; 		loop L1
; 	.ENDIF

; 	.IF data_buffer != 0
; 		mov esi, [info_buffer]
; 		mov esi, (huffman_buffer PTR [esi]).buffer
; 		add esi, 4
; 		mov esi, SDWORD PTR [esi]
; 		mov m_size, esi

; 		INVOKE huffman_buffer_create, m_size
; 		mov [data_buffer], eax

; 		mov ecx, m_size
; L2:
; 		mov eax, m_size
; 		sub eax, ecx

; 		mov esi, [data_buffer]
; 		mov esi, (huffman_buffer PTR [esi]).buffer
; 		add esi, eax

; 		pushad
; 		INVOKE crt_fgetc, file_stream
; 		mov tmpc, al
; 		popad
; 		mov al, tmpc
; 		mov	BYTE PTR [esi], al
; 		loop L2
; 	.ENDIF

; 	INVOKE crt_fclose, file_stream
; 	mov eax, 1
; 	ret
; read_from_file ENDP

; huffman_buffer_get_next_bit PROC USES ebx ecx, data_buffer: PTR huffman_buffer
; 	LOCAL return: BYTE
; 	mov eax, (huffman_buffer PTR data_buffer).buffer
; 	mov ebx, (huffman_buffer PTR data_buffer).current_byte_size
; 	mov ecx, ebx
; 	sar ebx, 3
; 	add eax, ebx
; 	mov eax, [eax]
; 	.IF eax == 0
; 		mov eax, 1
; 	.ELSE
; 		mov eax, 0
; 	.ENDIF

; 	.IF eax == 0
; 		mov eax, 1
; 	.ELSE
; 		mov eax, 0
; 	.ENDIF
; 	mov return, al

; 	add ecx, 00000007h
; 	mov eax, 1
; L1:
; 	sal eax, 1
; 	loop L1
	
; 	and al, return
; 	movzx eax, al

; 	inc (huffman_buffer PTR data_buffer).current_byte_size
; 	ret

; huffman_buffer_get_next_bit ENDP

; huffman_buffer_get_next_byte PROC, data_buffer: PTR huffman_buffer, forest: PTR huffman_node
; 	LOCAL current: DWORD
; 	LOCAL bit: BYTE
; 	INVOKE huffman_buffer_get_next_bit, data_buffer
; 	.IF eax != 0
; 		mov eax, (huffman_node PTR [forest]).right_child
; 		mov current, eax
; 	.ELSE
; 		mov eax, forest
; 		mov current, eax
; 	.ENDIF
	
; L1:
; 	mov eax, (huffman_node PTR current).left_child
; 	.IF eax == 0
; 		mov eax, (huffman_node PTR current).right_child
; 		.IF eax == 0
; 			jmp quit
; 		.ENDIF
; 	.ENDIF

; 	INVOKE huffman_buffer_get_next_bit, data_buffer
; 	mov bit, al
; 	.IF bit == 0
; 		mov eax, (huffman_node PTR current).left_child
; 		mov current, eax
; 	.ELSE
; 		mov eax, (huffman_node PTR current).right_child
; 		mov current, eax
; 	.ENDIF
; 	jmp L1
; quit:
; 	xor eax, eax
; 	mov al, (huffman_node PTR current).key
; 	ret	
; huffman_buffer_get_next_byte ENDP

; decompress_into_buffer PROC USES ebx ecx esi, info_buffer: PTR huffman_buffer, data_buffer: PTR huffman_buffer, forest: PTR huffman_node
; 	LOCAL decompressed_size: SDWORD
; 	LOCAL decompressed_buffer: DWORD
; 	LOCAL char: BYTE

; 	mov eax, (huffman_buffer PTR info_buffer).buffer
; 	mov decompressed_size, SDWORD PTR eax

; 	INVOKE huffman_buffer_create, decompressed_size
; 	mov decompressed_buffer, eax

; 	mov ecx, decompressed_size
; L1:
; 	mov ebx, decompressed_size
; 	sub ebx, ecx
	
; 	INVOKE huffman_buffer_get_next_byte, data_buffer, forest
; 	mov char, al

; 	mov esi, (huffman_buffer PTR decompressed_buffer).buffer
; 	add esi, ebx
; 	mov BYTE PTR [esi], al

; 	inc ebx
; 	sal ebx, 3

; 	mov (huffman_buffer PTR decompressed_buffer).current_byte_size, ebx
; 	loop L1

; 	mov eax, decompressed_buffer
; decompress_into_buffer ENDP
END