.model flat, c

include msvcrt.inc
includelib msvcrt.lib

huffman_buffer STRUCT
	current_byte_size 	SDWORD 0
	byte_capacity 		SDWORD 0
	buffer 				DWORD 0
huffman_buffer ENDS

huffman_buffer_create PROTO, max_byte_count: SDWORD
huffman_buffer_destroy PROTO, buffer: PTR huffman_buffer
huffman_buffer_insert PROTO, buffer: PTR huffman_buffer, bit_count: SDWORD, bits: PTR BYTE
get_compressed_size PROTO, buffer: PTR huffman_buffer
