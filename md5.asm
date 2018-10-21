include md5.inc
include Irvine32.inc

calc_md5 proto, block_size: sdword, datablock: ptr byte, dest_hash: ptr byte

md5 proto, password: ptr byte

password_is_valid proto, input_password: ptr byte, info_buffer: ptr huffman_buffer
	local md5_stored: ptr byte, md5_input: ptr byte


.code 
calc_md5 proc, block_size: sdword, datablock: ptr byte, dest_hash: ptr byte
	pushad
	push block_size                                  
	push datablock                
	push dest_hash                                           
	call _rwf_md5
	popad
	ret
calc_md5 endp

;----------------------------
;------------WSY-------------

md5 proc, password: ptr byte
	local len: sdword
	invoke Str_length, password
	mov len, eax
	invoke crt_malloc, 16
	invoke calc_md5, len, password, eax
	ret
ma5 endp

password_is_valid proc uses ecx, input_password: ptr byte, info_buffer: ptr huffman_buffer
	local md5_stored: ptr byte, md5_input: ptr byte
	;mov eax, 0
	;是否需要对eax的置零操作？
	mov eax, (huffman_buffer ptr info_buffer).buffer + 8 ;2 *sizeof(int)
	mov md5_stored, eax
	invoke md5, input_password
	mov md5_input, eax
	mov ecx, 16
L1: .if md5_stored[ecx - 1] != md5_input[ecx - 1]
		mov eax, 0
		ret
	.endif
	loop L1
	invoke crt_free, md5_input
	mov eax, 1
	ret
password_is_valid endp

;-----------WSY--------------
;----------------------------
end
