.model flat, c

include msvcrt.inc
includelib msvcrt.lib

usage proto

compress proto, file_name: ptr byte, password: ptr byte

decompress proto, file_name: ptr byte, password: ptr byte