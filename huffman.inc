.model flat, c

include msvcrt.inc
includelib msvcrt.lib

huffman_node struct
	key				byte  ?
	weight			dword ?
	left_child		dword ?
	right_child		dword ?
huffman_node ends

priority_queue struct
	node_size		dword ?
	nodes			dword 256 dup(?)
priority_queue ends

; ---------------------------------------------------------------
; proc's return value will be stored in eax
; ---------------------------------------------------------------

; return ptr huffman_node
huffman_node_create_external_node proto, n: dword

; return ptr huffman_node
huffman_node_create_internal_node proto, left_child: ptr huffman_node, right_child: ptr huffman_node

; return nothing
huffman_node_destory proto, node: ptr huffman_node

; return ptr priority_queue
pq_create proto

; return nothing
pq_destory proto, q: ptr priority_queue
	
; return dword
pq_percolate_up proto, q: ptr priority_queue, i: dword

; return dword
pq_percolate_down proto, q: ptr priority_queue, n: dword, i: dword

; return nothing
pq_heapify proto, q: ptr priority_queue, n: dword

; return nothing
pq_insert proto, q: ptr priority_queue, node: ptr huffman_node

; return ptr huffman_node
pq_delmax proto, q: ptr priority_queue

; return ptr priority_queue
char_statistics proto, file_name: ptr byte, byte_count: ptr dword

; return ptr huffman_node
huffman_forest_create proto, q: ptr priority_queue

; return nothing
huffman_forest_destory proto, forest: ptr huffman_node
