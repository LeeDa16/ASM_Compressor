include huffman.inc

; macro's return value will be stored in eax
; in macros, only eax will be modified

parent macro i
	mov eax, i
	sub eax, 1
	shr eax, 1
endm parent


last_internal macro n
	push ebx
	mov  ebx, n
	sub	 ebx, 1
	parent ebx
	pop ebx
endm last_internal


lchild macro i
	mov eax, i
	shl eax, 1
	add eax, 1
endm lchild


rchild macro i
	mov eax, i
	add eax, 1
	shl eax, 1
endm rchild

; ---------------------------------------------------------------

.code

in_heap proc n: dword, i: dword
	mov eax, i
	.if eax < 0
	.else
		.if eax < n
			mov eax, 1
			ret
		.endif
	.endif
	mov eax, 0
	ret
in_heap endp


lchild_valid proc, n: dword, i: dword
	push ebx
	push ecx
	mov ebx, n
	mov ecx, i
	lchild ecx
	invoke in_heap, ebx, eax
	pop ecx
	pop ebx
	ret
lchild_valid endp


rchild_valid proc, n: dword, i: dword
	push ebx
	push ecx
	mov ebx, n
	mov ecx, i
	rchild ecx
	invoke in_heap, ebx, eax
	pop ecx
	pop ebx
	ret
rchild_valid endp


bigger proc, q: ptr priority_queue, i: dword, j: dword
	push ebx
	push ecx
	push edx
	
	mov eax, j  
	mov ecx, q  
	mov edx, [ecx + eax * 4 + 4]  
	mov eax, i  
	mov ecx, q  
	mov eax, [ecx + eax * 4 + 4]  
	mov ecx, [edx + 1] ; j
	mov ebx, [eax + 1] ; i 

	.if ecx < ebx
		mov eax, j
	.else
		mov eax, i
	.endif
	
	pop edx
	pop ecx
	pop ebx
	ret
bigger endp


properparent proc, q: ptr priority_queue, n: dword, i: dword
	push ebx
	invoke rchild_valid, n, i
	.if eax == 1
		lchild i
		invoke bigger, q, i, eax
		mov ebx, eax
		rchild i
		invoke bigger, q, ebx, eax
	.else
		invoke lchild_valid, n, i
		.if eax == 1
			lchild i
			invoke bigger, q, i, eax
		.else
			mov eax, i
		.endif
	.endif
	pop ebx
	ret
properparent endp

; ---------------------------------------------------------------

; return ptr huffman_node
huffman_node_create_external_node proc uses ecx, n: dword
	invoke crt_malloc, size huffman_node
	mov ecx, n 
	mov (huffman_node ptr [eax]).key, cl
	mov (huffman_node ptr [eax]).weight, 0
	mov (huffman_node ptr [eax]).left_child, 0
	mov (huffman_node ptr [eax]).right_child, 0
	ret
huffman_node_create_external_node endp


; return ptr huffman_node
huffman_node_create_internal_node proc uses ebx ecx, left_child: ptr huffman_node, right_child: ptr huffman_node
	invoke crt_malloc, size huffman_node
	mov (huffman_node ptr [eax]).key, 0
	mov ecx, 0
	mov ebx, left_child
	mov ecx, (huffman_node ptr [ebx]).weight
	mov ebx, right_child
	add ecx, (huffman_node ptr [ebx]).weight
	; 不同于 ...
	; mov ecx, (huffman_node ptr [left_child]).weight
	; add ecx, (huffman_node ptr [right_child]).weight
	mov (huffman_node ptr [eax]).weight, ecx
	mov ebx, left_child
	mov (huffman_node ptr [eax]).left_child, ebx
	mov ebx, right_child
	mov (huffman_node ptr [eax]).right_child, ebx
	ret
huffman_node_create_internal_node endp


; return nothing
huffman_node_destroy proc, node: ptr huffman_node
	.if node != 0
		invoke crt_free, node
	.endif
	ret
huffman_node_destroy endp


; return ptr priority_queue
pq_create proc uses ebx ecx
	mov ecx, size priority_queue
	invoke crt_malloc, (size priority_queue)
	mov (priority_queue ptr [eax]).node_size, 0
	mov ebx, eax
	add ebx, 4
	mov ecx, 256
set0:
	mov dword ptr [ebx], 0
	add ebx, 4
	loop set0
	ret
pq_create endp 


; return nothing
pq_destroy proc uses ebx ecx, q: ptr priority_queue
	mov ecx, (priority_queue ptr q).node_size
	mov ebx, q
	add ebx, 4
node_free:
	; invoke crt_free, dword ptr[ebx]
	add ebx, 4
	loop node_free
	invoke crt_free, q
	ret
pq_destroy endp


; return dword
pq_percolate_up proc uses ecx edx esi, q: ptr priority_queue, i: dword
	local j: dword, temp: ptr huffman_node
up:
	cmp	i, 0  
	jle done
    ; 将 i 之父记作 j
	parent i
	mov dword ptr j, eax  
    ; if (q->nodes[j]->weight < q->nodesi->weight)
	mov eax, j  
	mov ecx, q  
	mov edx, [ecx + eax * 4 + 4]  
	mov eax, i  
	mov ecx, q  
	mov eax, [ecx + eax * 4 + 4]  
	mov ecx, [edx + 1]  
	cmp ecx, [eax + 1]  
	jge continue
    ; 一旦当前父子不再逆序，上滤旋即完成
	jmp done
continue:
    ; swap
    ; huffman_node * t = q->nodesi;
	mov eax, i  
	mov ecx, q  
	mov edx, [ecx + eax * 4 + 4]  
	mov temp, edx  
    ; q->nodesi = q->nodes[j];
	mov eax, i  
	mov ecx, q  
	mov edx, j  
	mov esi, q  
	mov edx, [esi + edx * 4 + 4]  
	mov [ecx + eax * 4 + 4], edx  
    ; q->nodesj= t;
	mov eax, j  
	mov ecx, q  
	mov edx, temp  
	mov [ecx + eax * 4 + 4], edx  
    ; 否则，父子交换位置，并继续考查上一层
	mov eax, j  
	mov i, eax  
	jmp up  
    ; 返回上滤最终抵达的位置
done:
	mov eax,i 
	ret
pq_percolate_up endp 
	

; return dword
pq_percolate_down proc uses ecx edx esi, q: ptr priority_queue, n: dword, i: dword
	local j: dword, temp:dword
down:
	invoke properparent, q, n, i
	mov j, eax
	cmp i, eax
	je done
	; swap
    ; huffman_node * t = q->nodesi;
	mov eax, i  
	mov ecx, q  
	mov edx, [ecx + eax * 4 + 4]  
	mov temp, edx  
    ; q->nodesi = q->nodes[j];
	mov eax, i  
	mov ecx, q  
	mov edx, j 
	mov esi, q  
	mov edx, [esi + edx * 4 + 4]  
	mov  [ecx + eax * 4 + 4], edx  
    ; q->nodes[j]= t;
	mov eax, j 
	; q->nodes[j]= t;
	mov ecx, q  
	mov edx, temp  
	mov  [ecx + eax * 4 + 4], edx  
	; i = j;
	mov eax, j 
	mov i, eax  
	; 二者换位，并继续考查下降后的i
	jmp down  
	done:
	; 返回下滤抵达的位置（亦i亦j）
	mov eax, i  
	ret
pq_percolate_down endp 


; return nothing
pq_heapify proc, q: ptr priority_queue, n: dword
	local i: dword
	last_internal n
	mov i, eax
heapify:
	invoke in_heap, n, i
	cmp eax, 0
	je done
	invoke pq_percolate_down, q, n, i
	sub i, 1
	jmp heapify
done:
	ret
pq_heapify endp 


; return nothing
pq_insert proc uses ebx ecx edx, q: ptr priority_queue, node: ptr huffman_node
	; 首先将新词条接至向量末尾
	mov ebx, q
	mov ecx, [ebx]
	mov edx, node
	mov [ebx + 4 + 4 * ecx], edx
	inc ecx
	mov [ebx], ecx
	dec ecx
	; 再对该词条实施上滤调整
	invoke pq_percolate_up, q, ecx
	ret
pq_insert endp 


; return ptr huffman_node
pq_delmax proc uses ebx ecx edx, q: ptr priority_queue
	local max: ptr huffman_node
	mov ebx, q
	
	; huffman_node * max = q->nodes[0];
	mov edx, [ebx + 4]
	mov max, edx

    ; q->nodes[0] = q->nodes[--(q->size)]; // 摘除堆顶（首词条），代之以末词条
	mov ecx, [ebx + 0]
	dec ecx
	mov [ebx + 0], ecx
	mov edx, [ebx + 4 + 4 * ecx]
	mov [ebx + 4], edx

    ; pq_percolate_down(q, q->size, 0); // 对新堆顶实施下滤
	invoke pq_percolate_down, ebx, ecx, 0

    ; return max; // 返回此前备份的最大词条，需要外部释放
	mov eax, max
	ret
pq_delmax endp 


.data
rb_flag byte "rb", 0
.code
; return ptr priority_queue
char_statistics proc uses ebx ecx edx esi, file_name: ptr byte, byte_count: ptr dword
	local q: ptr priority_queue, nodes: ptr ptr huffman_node, file_stream: dword, char: dword
	invoke crt_malloc, 1024
	mov nodes, eax

	mov ebx, byte_count
	mov ecx, 0
	mov [ebx + 0], ecx
	
	; 初始化 pq
	invoke pq_create
	mov q, eax
	mov ecx, 256
	mov ebx, 0
create_external_node:
	invoke huffman_node_create_external_node, ebx
	mov edx, [nodes + 0]
	mov [edx + ebx * 4 + 0], eax
	inc ebx
	loop create_external_node

	; 从文件流中读取
	mov file_stream, 0
	invoke crt_fopen, file_name, offset rb_flag
	mov file_stream, eax
	cmp eax, 0
	je release

	mov char, 0
read_byte:
	invoke crt_fgetc, file_stream
	mov char, eax
	.if eax == 0ffffffffh
		jmp build_pq
	.endif
	mov edx, [nodes + 0]
	mov esi, [edx + eax * 4]
	mov ecx, [esi + 1]
	inc ecx
	mov [esi + 1], ecx

	mov edx, byte_count
	mov ecx, [edx]
	inc ecx
	mov [edx], ecx
	jmp read_byte

build_pq:
	invoke crt_fclose, file_stream
	mov ecx, 256
	mov ebx, 0
build:
	mov edx, nodes
	invoke pq_insert, q, [edx + 4 * ebx]
	inc ebx
	loop build

	invoke crt_free, nodes	
	mov eax, q
	ret

release:
	mov eax, 0
	ret
char_statistics endp 


; return ptr huffman_node
huffman_forest_create proc uses ebx ecx, q: ptr priority_queue
	local first: ptr huffman_node, second: ptr huffman_node
	mov ebx, q
	.if ebx == 0
		jmp ret_0
	.endif
	mov ecx, [ebx]
	.if ecx == 0
		jmp ret_0
	.endif
build:
	mov ecx, [ebx]
	.if ecx <= 1
		jmp done
	.endif
	invoke pq_delmax, q
	mov first, eax
	invoke pq_delmax, q
	mov second, eax
	invoke huffman_node_create_internal_node, first, second
	invoke pq_insert, q, eax	
	jmp build
done:
	invoke pq_delmax, q
	ret
ret_0: 
	mov eax, 0
	ret
huffman_forest_create endp 


; return nothing
huffman_forest_destroy proc uses ebx edx, forest: ptr huffman_node
	.if forest == 0
		ret
	.endif
	mov ebx, forest
	mov edx, [ebx + 5]
	.if edx != 0
		invoke huffman_forest_destroy, edx
	.endif
	mov edx, [ebx + 9]
	.if edx != 0
		invoke huffman_forest_destroy, edx
	.endif
	invoke huffman_node_destroy, forest
	ret
huffman_forest_destroy endp 


end
