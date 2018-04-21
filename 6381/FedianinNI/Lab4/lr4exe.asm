EOL 	EQU 	'$'
CODE	SEGMENT
        ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack
		
RStack 	DB 	32 	DUP (0)
;-------------------------------------------------------------------------
PRINT_A_STR	PROC	NEAR
		push	AX
		mov		AH,09H
		int		21H
		pop		AX
		ret
PRINT_A_STR	ENDP
;-------------------------------------------------------------------------
; ������� ������ ������� �� AL
OutputAL PROC
		push 	AX
		push 	BX
		push 	CX
		mov 	AH, 09H   ;������ ������ � ������� ������� �������
		mov 	BH, 0     ;����� ����� ��������
		mov 	CX, 1     ;����� ����������� ������� ��� ������
		int 	10h       ;��������� �������
		pop 	CX
		pop 	BX
		pop 	AX
		ret
OutputAL ENDP
;-------------------------------------------------------------------------
; ��������� ������� �������
; ����: BH = ����� ��������
; �����: DH, DL = ������� ������, ������� �������
;		 CH, CL = ������� ���������, �������� ������
GetCursor PROC
		push 	AX
		push 	BX
		push 	CX
		mov 	AH, 03H
		mov 	BH, 0
		int 	10H
		pop 	CX
		pop 	BX
		pop 	AX
GetCursor ENDP
;-------------------------------------------------------------------------
; ��������� ������� �������
SetCursor PROC
		push 	AX
		push 	BX
		;push 	DX
		push 	CX
		mov 	AH,02h
		mov 	BH,0
		int 	10h
		pop 	CX
		;pop 	DX
		pop 	BX
		pop 	AX
		ret
SetCursor ENDP
;-------------------------------------------------------------------------
; ��������� ����������� ����������
Rout 		PROC 	FAR

jmp RoutCode

;������
Signature 		DB 'AAAA'
KeepCS 			DW 0
KeepIP 			DW 0
KeepPSP			DW 0
DeleteFlag 		DB 0
Counter 		DB 0		;��� ���������� ����������
KeepSP			DW 0
KeepSS			DW 0
	
RoutCode:
		mov 	KeepSP, SP
		mov 	KeepSS, SS
		mov 	AX, CS
		mov 	SS, AX
		mov 	SP, 20h
		push 	AX
		push 	DX
		push 	DS
		push 	ES
		
		cmp 	DeleteFlag, 1
		je 		Del
		
		call 	GetCursor
		push 	DX
		;DH, DL = ������, �������
		mov 	DH, 14h
		mov 	DL, 22h
		call 	SetCursor
		
		cmp 	Counter, 0AH
		jl 		Skip
		mov 	Counter, 0H		
Skip:
		mov 	AL,Counter
		or 		AL,30H
		call 	OutputAL
		pop 	DX
		call 	SetCursor
		inc 	Counter
	
		jmp R_END
	
Del: ;��������������� ����������� ������ ����������:
		CLI
		push	DS 
		mov 	DX, KeepIP
		mov 	AX, KeepCS
		mov 	DS, AX
		mov 	AX, 251CH
		int 	21H 			;��������������� ������
		pop		DS
		;����������� ������:
		;����� ���������� �����
		mov 	ES, KeepPSP 
		mov 	ES, ES:[2CH] 	
		mov 	AH, 49H         
		int 	21H
		;����� ����������� ���������
		mov 	ES, KeepPSP 
		mov 	AH, 49H
		int 	21H	
		STI
		
R_END:
		pop 	ES
		pop 	DS
		pop 	DX
		pop 	AX 
		mov 	SP, KeepSP
		mov 	SS, KeepSS
		mov		AL, 20H
		out		20H, AL
		iret
Rout 	ENDP
;-------------------------------------------------------------------------
; ��������� ���������� 
SetINT 	PROC
		push 	DS
		mov 	AH, 35H
		mov 	AL, 1CH
		int 	21H
		mov 	KeepIP, BX
		mov 	KeepCS, ES
 
		;���������
		mov 	DX, OFFSET Rout 
		mov 	AX, SEG Rout
		mov 	DS, AX
		mov 	AH, 25H
		mov 	AL, 1CH
		int 	21H
		pop 	DS
		ret
SetINT 	ENDP 
;-------------------------------------------------------------------------
CheckSignature 	PROC
		; �������� 1ch
		mov 	AH, 35H
		mov 	AL, 1CH
		int 	21H 
	
		mov 	SI, OFFSET Signature
		sub 	SI, OFFSET Rout 
	
		; �������� ��������� ('AAAA'):
		; ES - ������� ������� ����������
		; BX - �������� ������� ����������
		; SI - �������� ��������� ������������ ������ ������� ����������
		mov 	AX, 'AA'
		cmp 	AX, ES:[BX+SI]
		jne 	MarkNotLoaded
		cmp 	AX, ES:[BX+SI+2]
		jne 	MarkNotLoaded
		jmp 	MarkLoaded 
	
MarkNotLoaded:
		;��������� ���������������� ������� ����������
		mov 	DX, OFFSET Loaded
		call 	PRINT_A_STR
		call 	SetINT
		;���������� ������������ ���������� ������ ��� ����������� ���������:
		mov 	DX, OFFSET END_BYTE 
		mov 	CL, 4
		shr 	DX, CL
		inc 	DX	 				
		add 	DX, CODE 			
		sub 	DX, KeepPSP 		
		
		xor 	AL, AL
		mov 	AH, 31H
		int 	21H 
		
MarkLoaded:
		;Check for /un
		push 	ES
		push 	BX
		mov 	BX, KeepPSP
		mov 	ES, BX
		cmp 	BYTE PTR ES:[82H],'/'
		jne 	NoDelete
		cmp 	BYTE PTR ES:[83H],'u'
		jne 	NoDelete
		cmp 	BYTE PTR ES:[84H],'n'
		je 		Delete
		
NoDelete:
		pop 	BX
		pop 	ES
	
		mov 	DX, OFFSET AlreadyLoaded
		call 	PRINT_A_STR
		ret

;���� un - ������� ���������������� ����������
Delete:
		pop 	BX
		pop 	ES
		mov 	BYTE PTR ES:[BX+SI+10], 1
		mov 	DX, OFFSET Unloaded
		call 	PRINT_A_STR
		ret
CheckSignature 	ENDP
;-------------------------------------------------------------------------
DATA	SEGMENT
	Loaded 			DB 'User interruption is loaded',0DH,0AH,'$'
	AlreadyLoaded 	DB 'User interruption is already loaded',0DH,0AH,'$'
	Unloaded 		DB 'User interruption is unloaded',0DH,0AH,'$'
DATA 	ENDS
		
AStack	SEGMENT  STACK
        DW 512 DUP(?)			
AStack  ENDS
;-------------------------------------------------------------------------
Main	PROC  	FAR
		mov 	AX, data
		mov 	DS, AX
		mov 	KeepPSP, ES
	
		call 	CheckSignature
	
		xor 	AL,AL
		mov 	AH,4CH
		int 	21H
	
END_BYTE:
		ret
Main    		ENDP
CODE			ENDS
				END Main