.model flat, c

include huffman.inc
include msvcrt.inc
includelib msvcrt.lib

mapper struct
	bit_length	sdword		?
	bits		byte		256 dup(?)
	weight		sdword		?
mapper ends

size_mapper = size mapper

mapper_init proto

mapper_destroy proto, mappers: ptr mapper

mapper_set proto, mappers: ptr mapper, order: byte, bit_length: sdword, bits: ptr byte, weight: sdword

;_mapper_set_all proto, mappers: ptr mapper, forest: ptr huffman_node, depth: sdword, bits: ptr byte

;mapper_set_all proto, mappers: ptr mapper, forest: ptr huffman_node
