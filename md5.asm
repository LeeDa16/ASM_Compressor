include md5.inc
include msvcrt.inc

calc_md5 proto, block_size: sdword, datablock: ptr byte, dest_hash: ptr byte

huffman_buffer STRUCT
	current_byte_size 	SDWORD 0
	byte_capacity 		SDWORD 0
	buffer 				dword ?
huffman_buffer ENDS

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
;

md5 proc, password: ptr byte
	local len: sdword
	invoke crt_strlen, password
	mov len, eax
	invoke crt_malloc, 16
	invoke calc_md5, len, password, eax
	ret
md5 endp

password_is_valid proc uses ecx edx ebx, input_password: ptr byte, info_buffer: ptr huffman_buffer
	local md5_stored: ptr byte, md5_input: ptr byte
	;mov eax, 0
	;是否需要对eax的置零操作？
	mov eax, (huffman_buffer ptr info_buffer).buffer + 8 ;2 *sizeof(int)
	mov md5_stored, eax
	invoke md5, input_password
	mov md5_input, eax
	mov ecx, 16
L1: mov edx, ecx
	dec edx
	mov ebx, md5_stored[edx]
	.if ebx != md5_input[edx]
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
