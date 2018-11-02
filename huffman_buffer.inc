.model flat, c

include msvcrt.inc
include mapper.inc
include huffman.inc
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
compress_into_buffer PROTO, file_name: PTR BYTE, buffer: PTR huffman_buffer, mappers: PTR mapper
DECODE_INFO_BUFFER_SIZE = 2 * 4 + 16 + 4 * 256
save_encode_info_into_buffer PROTO, buffer: PTR huffman_buffer, decompressed_size: SDWORD, compressed_size: SDWORD, password: PTR BYTE, mappers: PTR mapper
write_into_file PROTO, info_buffer: PTR huffman_buffer, data_buffer: PTR huffman_buffer, file_name: PTR BYTE
read_from_file PROTO, info_buffer: PTR PTR huffman_buffer, data_buffer: PTR PTR huffman_buffer, file_name: PTR BYTE
huffman_buffer_get_next_bit PROTO, data_buffer: PTR huffman_buffer
huffman_buffer_get_next_byte PROTO, data_buffer: PTR huffman_buffer, forest: PTR huffman_node
decompress_into_buffer PROTO, data_buffer: PTR huffman_buffer, info_buffer: PTR huffman_buffer, forest: PTR huffman_node
rebuild_pq PROTO, info_buffer: PTR huffman_buffer