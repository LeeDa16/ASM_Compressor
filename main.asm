include pq.inc
include mapper.inc
include md5.inc


print_msg macro msg
	mov edx, offset msg
	call WriteString
print_msg endm

usage proto

compress proto, file_name: ptr byte, password: ptr byte

decompress proto, file_name: ptr byte, password: ptr byte

append_tql proto, origin_file_name: ptr byte

.data
nl EQU <0dh, 0ah>
usage_msg byte				"Usage:", nl,
							"  compress filename",nl,
							"  decompress filename", nl,
							"  compress filename [ -p password ]", nl,
							"  decompress filename [ -p password ]", nl
failed_no_such_file byte	"[ FAILED ]: No such file named [ %s ] ...", nl
info_compressing byte		"[ INFO ]: Compressing ...", nl
info_compressed_into byte	"[ INFO ]: File [ %s ] was compressed into [ %s ] successfully...", nl
failed_no_permission byte	"[ FAILED ]: You have NO permission to decompress the file.", nl
info_decompressing byte		"[ INFO ]: Decompressing ...", nl
info_decompressed_into byte "[ INFO ]: File [ %s ] was decompressed into [ %s ] successfully...", nl

.code


append_tql proc uses eax ebx, origin_file_name: ptr byte
	local temp_ptr: ptr byte
	invoke Str_length, origin_file_name
	mov ebx, eax
	invoke crt_malloc, ebx + 5
	invoke Str_copy, origin_file_name, eax
	mov ebx, origin_file_name
	mov temp_ptr, ebx
	mov origin_file_name, eax
	invoke crt_free, temp_ptr
	mov [eax + ebx], "."
	mov [eax + ebx + 1], "t"
	mov [eax + ebx + 2], "q"
	mov [eax + ebx + 3], "l"
	mov [eax + ebx + 4], 0

	ret
append_tql endp

compress proc uses eax ebx edx, file_name: ptr byte, password: ptr byte
	local md5_code: ptr byte, decompressed_size: sdword,
		q: ptr pq, forest: ptr huffman_forest,
		mappers: ptr mapper, data_buffer: ptr huffman_buffer,
		info_buffer: ptr huffman_buffer, compressed_file_name: ptr byte

	invoke md5, password
	mov md5_code, eax
	mov decompressed_size, 0
	invoke char_statistics, file_name, addr decompressed_size
	mov q, eax
	.if q != 0
		print_msg failed_no_such_file
		ret
	.endif
	print_msg info_compressing
	invoke huffman_forest_create, q
	mov forest, eax
	invoke mapper_init
	mov mappers, eax
	invoke mapper_set_all, mappers, forest

	invoke huffman_buffer_create, decompressed_size * 2
	mov data_buffer, eax
	invoke compress_into_buffer, file_name, data_buffer, mappers
	invoke get_compressed_size, data_buffer
	mov compressed_size, eax
	invoke huffman_buffer_create, DECODE_INFO_BUFFER_SIZE
	mov info_buffer, eax
	invoke save_encode_info_into_buffer, info_buffer, decompressed_size, 
		compressed_size, md5_code, mappers

	invoke Str_length, file_name
	mov ebx, eax
	invoke crt_malloc, ebx + 4 + 1
	mov compressed_file_name, eax
	invoke Str_copy, compressed_file_name, file_name
	invoke append_tql, compressed_file_name
	invoke write_into_file, info_buffer, data_buffer, compressed_file_name
	print_msg info_compressed_into

	invoke crt_free, mdt_code
	invoke pq_destroy, q
	invoke huffman_forest_destroy, forest
	invoke mapper_destroy, mappers
	invoke huffman_buffer_destroy, data_buffer
	invoke huffman_buffer_destroy, info_buffer
	invoke crt_free, compressed_file_name

	ret
compress endp

decompress proc, file_name: ptr byte, password: ptr byte
	local data_buffer: ptr huffman_buffer, info_buffer: ptr huffman_buffer,
		q: ptr pq, forest: ptr huffman_forest, decompressed_buffer: ptr huffman_buffer,
		mappers: ptr mapper, decompressed_file_name: ptr byte

	mov data_buffer, 0
	mov info_buffer, 0
	invoke read_from_file, addr info_buffer, addr data_buffer, file_name
	.if eax == 0
		print_msg failed_no_such_file
		ret
	.endif
	invoke password_is_valid, password, info_buffer
	.if eax == 0
		print_msg failed_no_permission
		invoke huffman_buffer_destroy, data_buffer
		invoke huffman_buffer_destroy, info_buffer
		ret
	.else
		print_msg info_decompressing
	.endif

	invoke rebuild_pq, info_buffer
	mov q, eax
	invoke huffman_forest_create, q
	mov forest, eax
	invoke decompress_into_buffer, info_buffer, data_buffer, forest
	mov decompressed_buffer, eax
	invoke mapper_init
	mov mappers, eax
	invoke mapper_set_all, mappers, forest

	invoke Str_length, file_name
	mov ebx, eax
	invoke crt_malloc, ebx + 1
	mov decompressed_file_name, eax
	invoke Str_copy, decompressed_file_name, file_name
	mov decompressed_file_name[ebx - 4], 0
	
	invoke write_into_file, 0, decompressed_buffer, decompressed_file_name
	print_msg info_decompressed_into

	invoke pq_destroy, q
	invoke huffman_forest_destroy, forest
	invoke huffman_buffer_destroy, decompressed_buffer
	invoke mapper_destroy, mappers
	invoke crt_free, decompressed_file_name

	ret
decompress endp

end