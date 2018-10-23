.data
huffman_buffer STRUCT
	current_byte_size 	SDWORD 0
	byte_capacity 		SDWORD 0
	buffer 				PTR BYTE 1 dup(?)
huffman_buffer ENDS

	mode_rb	BYTE "rb", 0
	mode_wb BYTE "wb", 0

mapper STRUCT
mapper ENDS

priority_queue STRUCT
priority_queue ENDS

huffman_node STRUCT
huffman_node ENDS

pq = priority_queue


huffman_buffer_create PROTO, max_byte_count: SDWORD
huffman_buffer_destroy PROTO, buffer: PTR huffman_buffer
huffman_buffer_insert PROTO, buffer: PTR huffman_buffer, bit_count: SDWORD, bits: PTR BYTE
get_compress_size PROTO, data_buffer: PTR huffman_buffer
compress_into_buffer PROTO, file_name: PTR BYTE, buffer: PTR huffman_buffer, mappers: PTR mapper
save_encode_into_buffer PROTO, buffer: PTR huffman_buffer, decompressed_size: SDWORD, compressed_size: SDWORD, password: PTR BYTE, mappers: PTR mapper
write_into_file PROTO, info_buffer: PTR huffman_buffer, data_buffer: PTR huffman_buffer, file_name: PTR BYTE
read_from_file PROTO, info_buffer: PTR PTR huffman_buffer, data_buffer: PTR PTR huffman_buffer, file_name: PTR BYTE
rebuild_pq PROTO, info_buffer: PTR huffman_buffer
pq_ctreate PROTO
huffman_node_create_external_node PROTO, n: SDWORD
pq_insert PROTO, q: PTR pq, node: PTR huffman_node
huffman_buffer_get_next_bit PROTO, data_buffer: PTR huffman_buffer
huffman_buffer_get_next_bytes PROTO, data_buffer: PTR huffman_buffer, forest: PTR huffman_node
decompress_into_buffer PROTO, data_buffer: PTR huffman_buffer, info_buffer: PTR huffman_buffer, forest: PTR huffman_node


.code
huffman_buffer_create PROC USES ecx, max_byte_count: SDWORD
	LOCAL buffer: PTR huffman_buffer
	INVOKE crt_malloc, size huffman_buffer
	mov (huffman_buffer PTR [eax]).current_byte_size, 0
	mov (huffman_buffer PTR [eax]).byte_capacity, max_byte_count
	mov buffer, eax

	INVOKE crt_malloc, max_byte_count
	mov (huffman_buffer PTR [buffer]).buffer, eax
	mov ecx, max_byte_count
L1:
	mov BYTE PTR (huffman_buffer PTR [buffer]).buffer[ecx - 1], 0
	loop L1

	mov eax, buffer
	ret
huffman_buffer_create ENDP

huffman_buffer_destroy PROC, buffer: PTR huffman_buffer
	.IF buffer != 0
		.IF (huffman_buffer PTR [buffer]).buffer != 0
			INVOKE crt_free, (huffman_buffer PTR [buffer]).buffer
		.ENDIF
		INVOKE crt_free, buffer
	.ENDIF
	ret
	; pushad
	; mov eax, huffman_buffer
	; .IF eax != 0
	; 	.IF [eax + 8] != 0
	; 		INVOKE crt_free, [eax + 8]
	; 	.ENDIF
	; 	INVOKE crt_free, eax
	; .ENDIF
	; popad
	; ret
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

	imul esi, ecx, SIZE mapper
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
		; add esi, ecx
		push esi
		push ecx
		INVOKE crt_fputc, esi, file_stream
		pop ecx
		pop esi

		inc esi
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
		; add esi, ecx
		push esi
		push ecx
		INVOKE crt_fputc, esi, file_stream
		pop ecx
		pop esi

		inc esi
		inc ecx
		jmp L2
quit_loop2:
	.ENDIF
quit:
	INVOKE crt_fclose, file_stream
	popad
	ret
write_into_file ENDP

read_from_file PROC, info_buffer: PTR PTR huffman_buffer, data_buffer: PTR PTR huffman_buffer, file_name: PTR BYTE
	LOCAL file_stream: HANDLE
	LOCAL mode: BYTE "rb", 0
	LOCAL size: SDWORD
	pushad
	
	mov file_stream, 0
	INVOKE crt_fopen, file_name, OFFSET mode
	mov file_stream, eax
	.IF file_stream == 0
		popad
		mov eax, 0
		ret
	.ENDIF

	.IF info_buffer != 0
		INVOKE huffman_buffer_create, DECODE_INFO_BUFFER_SIZE
		mov PTR huffman_buffer PTR info_buffer, eax

		mov ecx, 0
		mov esi, PTR huffman_buffer PTR info_buffer
		add esi, 8
L1:
		.IF ecx >= DECODE_INFO_BUFFER_SIZE
			jmp quit_loop1
		.ENDIF

		push ecx
		push esi
		INVOKE crt_fgetc, file_stream
		pop esi
		pop ecx

		mov BYTE PTR [esi], al

		inc esi
		inc ecx
		jmp L1
quit_loop1:
	.ENDIF

	.IF data_buffer != 0
		mov esi, PTR huffman_buffer PTR info_buffer
		add esi, 8
		mov size, SDWORD PTR [esi + 4]

		INVOKE huffman_buffer_create, size
		mov PTR huffman_buffer PTR data_buffer, eax

		mov ecx, 0
		mov esi, PTR huffman_buffer PTR info_buffer
		add esi, 8

L2:	
		.IF ecx >= size
			jmp quit_loop2
		.ENDIF

		push ecx
		push esi
		INVOKE crt_fgetc, file_stream
		pop esi
		pop ecx
		
		mov BYTE PTR [esi], al

		inc esi
		inc ecx
quit_loop2:
	.ENDIF
	INVOKE crt_fclose, file_stream
	popad
	mov eax, 1
	ret
read_from_file ENDP

rebuild_pq PROC, info_buffer: PTR huffman_buffer
	LOCAL q: PTR pq
	LOCAL data_offset: PTR BYTE
	LOCAL nodes[256]: PTR huffman_node
	pushad
	INVOKE pq_ctreate
	mov q, eax
	mov data_offset, [info_buffer].buffer
	add data_offset, 2 * 4  + 16

	mov ecx, 256
L1:
	push ecx
	INVOKE huffman_node_create_external_node, ecx - 1
	pop ecx
	mov nodes[ecx - 1], eax
	mov nodes[ecx - 1].weight, (SDWORD PTR data_offset)[ecx - 1]
	loop L1

	mov ecx, 256
L2:
	push ecx
	INVOKE pq_insert, q, nodes[ecx - 1]
	pop ecx
	loop L2

	popad
	mov eax, q
	ret
	; pushad
	; INVOKE pq_ctreate
	; mov pq, eax
	; imul eax, SIZEOF huffman_node, 256
	; add esp, eax
	; mov nodes, esp

	; mov data_offset, info_buffer
	; add data_offset, 8
	; add data_offset, 2 * 4 + 16

	; mov ecx, 0
	; mov esi, data_offset

; L1:
; 	.IF ecx >= 256
; 		jmp quit_loop1
; 	.ENDIF
	
; 	push ecx
; 	push esi
; 	INVOKE huffman_node_create_external_node, ecx
; 	pop esi
; 	pop ecx

; 	mov huffman_node PTR nodes[ecx], eax
; 	mov SDWORD PTR nodes[ecx].weight, SDWORD PTR [esi]

; quit_loop1:

	popad
	ret
rebuild_pq ENDP

huffman_buffer_get_next_bit PROC, data_buffer
	push ebx
	mov eax, [data_buffer].current_byte_size
	sar eax, 3
	mov eax, [data_buffer].buffer[eax]
	not eax
	not eax
	mov ebx, [data_buffer].current_byte_size
	and	ebx, 00000007h
	sal ebx, 1
	and eax, ebx
	pop ebx
	ret
huffman_buffer_get_next_bit ENDP

huffman_buffer_get_next_bytes PROC, data_buffer: PTR huffman_buffer, forest: PTR huffman_node
	LOCAL current: PTR huffman_node
	LOCAL bit: BYTE
	pushad
	INVOKE huffman_buffer_get_next_bit, data_buffer
	popad

	.IF eax == 0
		mov current, forest
	.ELSE
	 	mov current, [forest].right_child
	.ENDIF

L1:
	.IF [eax].left_child == 0
		.IF [eax].right_child == 0
			jmp quit_loop1
		.ENDIF
	.ENDIF

	INVOKE huffman_buffer_get_next_bit, data_buffer
	mov bit, eax
	.IF bit == 0
		mov current, [current].left_child
	.ELSE
		mov current, [current].right_child
	.ENDIF
quit_loop1:
	mov eax, [current].key
	ret
huffman_buffer_get_next_bytes ENDP

decompress_into_buffer PROC, data_buffer: PTR huffman_buffer, info_buffer: PTR huffman_buffer, forest: PTR huffman_node
	LOCAL decompressed_size: SDWORD
	LOCAL decompressed_buffer: PTR huffman_buffer
	LOCAL c: BYTE
	mov decompressed_size, SDWORD PTR [[info_buffer].buffer]
	pushad
	INVOKE huffman_buffer_create, decompressed_size
	mov decompressed_buffer, eax
	popad
	mov ecx, decompressed_size
L1:
	pushad
	INVOKE huffman_buffer_get_next_bytes, data_buffer, forest
	mov c, eax
	popad
	mov BYTE PTR [decompressed_buffer].buffer[ecx], c
	add [decompressed_buffer].current_byte_size, 8
	loop L1

	mov eax, decompressed_buffer
	ret
decompress_into_buffer ENDP