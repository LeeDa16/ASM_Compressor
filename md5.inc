comment  ~
----------------------------------------------------------------------------
|                     The MD5 Message-Digest Algorithm                     |
----------------------------------------------------------------------------
|   Description:                                                           |
|   ============                                                           |
|                                                                          |
|   The MD5 algorithm is designed to be quite fast on 32-bit machines. In  |
|   addition,  the MD5 algorithm  does not require any large substitution  |
|   tables, the algorithm can be coded quite compactly.                    |
|                                                                          |
|   The MD5 algorithm is an extension of the MD4 message-digest algorithm  |
|   1,2]. MD5 is  slightly slower than MD4, but is more "conservative" in  |
|   design. MD5  was designed  because it  was felt  that MD4 was perhaps  |
|   being adopted  for use more  quickly than  justified by  the existing  |
|   critical  review, because MD4  was designed to be exceptionally fast,  |
|   it  is "at the edge"  in terms of  risking  successful  cryptanalytic  |
|   attack.  MD5 backs off  a bit, giving up a little in speed for a much  |
|   greater   likelihood  of  ultimate  security.  It  incorporates  some  |
|   suggestions  made  by  various  reviewers,  and  contains  additional  |
|   optimizations. The MD5 algorithm is being placed in the public domain  |
|   for review and possible adoption as a standard.                        |
|                                                                          |
----------------------------------------------------------------------------
|   Implementation based on rfc1321 (fully rewritten in asm, not ripped :))|
----------------------------------------------------------------------------
|   Usage:                                                                 |
|   ======                                                                 |
|                                                                          |
|   Simply include this file to your project:                              |
|   exp: include \..path..\rewolf_md5.inc                                  |
|                                                                          |
|   Target compiler...: MASM                                               |
|   Calling convention:                                                    |
|                                                                          |
|	push	size of datablock							                   |
|	push	offset datablock                                               |
|	push	offset destHash                                                |
|	call	_rwf_md5                                                       |
|                                                                          |
|   datablock -> (input)  -> buffer that contains data to hash             |
|   destHash  -> (output) -> 16-bytes buffer for hashed data               |
|                                                                          |
|   Modified registers: none                                               |
|   Stack is automatically cleared                                         |
----------------------------------------------------------------------------
|   Coder.: ReWolf^HTB                                                     |
|   Date..: 17.XII.2004                                                    |
|   E-mail: rewolf@poczta.onet.pl                                          |
|   WWW...: http://www.rewolf.prv.pl                                       |
----------------------------------------------------------------------------
~

.model flat, c

S11 = 7
S12 = 12
S13 = 17
S14 = 22
S21 = 5
S22 = 9
S23 = 14
S24 = 20
S31 = 4
S32 = 11
S33 = 16
S34 = 23
S41 = 6
S42 = 10
S43 = 15
S44 = 21

FF macro a,b,c,d,k,s,i
	mov	edi,b
	mov	ebp,b
	and	edi,c
	not	ebp
	and	ebp,d
	or	edi,ebp
	lea	a,dword ptr [a+edi+i]
	add	a,dword ptr [esi+k*4]
	rol	a,s
	add	a,b
endm FF

GG macro a,b,c,d,k,s,i
	mov	edi,d
	mov	ebp,d
	and	edi,b
	not	ebp
	and	ebp,c
	or	edi,ebp
	lea	a,dword ptr [a+edi+i]
	add	a,dword ptr [esi+k*4]
	rol	a,s
	add	a,b
endm GG

HH macro a,b,c,d,k,s,i
	mov	ebp,b
	xor	ebp,c
	xor	ebp,d
	lea	a,dword ptr [a+ebp+i]
	add	a,dword ptr [esi+k*4]
	rol	a,s
	add	a,b
endm HH

II macro a,b,c,d,k,s,i
	mov	ebp,d
	not	ebp
	or	ebp,b
	xor	ebp,c
	lea	a,dword ptr [a+ebp+i]
	add	a,dword ptr [esi+k*4]
	rol	a,s
	add	a,b
endm II

md5 proto, password: ptr byte

password_is_valid proto, input_password: ptr byte, info_buffer: ptr huffman_buffer

calc_md5 proto, block_size: sdword, datablock: ptr byte, dest_hash: ptr byte


.code

