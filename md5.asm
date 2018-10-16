include md5.inc

calc_md5 proto, block_size: sdword, datablock: ptr byte, dest_hash: ptr byte

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

end
