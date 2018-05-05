CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, ES:DATA, SS:ASTACK
START: 
	JMP BEGIN
;подготовка и освобождение места в памяти 
FrMem PROC 
		lea 	BX,Last_byte 
		mov 	AX,ES 
		sub 	BX,AX
		mov 	CL,4h
		shr 	BX,CL 

		mov 	AH,4AH 
		int 	21h
		jnc 	EndFrMem ;проверка CF

		cmp 	AX,7
		lea 	DX, ErMem7
		je 		ErMemFound
		cmp 	AX,8
		lea 	DX, ErMem8
		je 		ErMemFound
		cmp 	AX,9
		lea 	DX, ErMem9
		
ErMemFound:
		call 	PRINT_A_STR
		xor 	AL,AL
		mov 	AH,4Ch
		int 	21H
EndFrMem:
		ret
FrMem ENDP
;заполнение блока параметров
CreateParBl PROC
		mov 	AX, ES
		mov 	ParBl,0
		mov 	ParBl+2, 80h
		mov 	ParBl+4, AX
		mov 	ParBl+6, 5Ch  
		mov 	ParBl+8, AX
		mov 	ParBl+10, 6Ch 
		mov 	ParBl+12, AX
		ret
CreateParBl ENDP

callLr2 PROC 
		;подготовка строки, содержащей путь и имя вызываемой программы
		lea 	DX, Path
		push 	DS
		pop 	ES 
		lea 	BX, ParBl

		;сохранение содержимого регистров SS и SP в переменных
		mov 	KeepSP, SP
		mov 	KeepSS, SS
		
		;вызов загрузчика OS
		mov 	AX,4B00h
		int 	21h
		jnc 	NoErrcall 

		push 	AX
		mov 	AX,DATA
		mov 	DS,AX
		pop 	AX
		mov 	SS,KeepSS
		mov 	SP,KeepSP
		
		cmp 	AX,1
		lea 	DX, Ercall1
		je 		ErcallFound
		cmp 	AX,2
		lea 	DX, Ercall2
		je 		ErcallFound
		cmp 	AX,5
		lea 	DX, Ercall5
		je 		ErcallFound
		cmp 	AX,8 
		lea 	DX, Ercall8
		je 		ErcallFound
		cmp 	AX,10 
		lea 	DX, Ercall10
		je 		ErcallFound
		cmp 	AX,11 
		lea 	DX, Ercall11
		
	ErcallFound:
		call 	PRINT_A_STR
		xor 	AL,AL
		mov 	AH,4Ch
		int 	21h
			
	NoErrcall:
		mov 	AX,4d00h
		int 	21h
	
		cmp 	AH,0
		lea 	DX, ResEnd0
		je 		Exit
		cmp 	AH,1
		lea 	DX, ResEnd1
		je 		Exit
		cmp 	AH,2
		lea 	DX, ResEnd2
		je 		Exit
		cmp 	AH,3
		lea 	DX, ResEnd3

Exit:
		call 	PRINT_A_STR
		ret
callLr2 ENDP

PRINT_A_STR PROC NEAR
		push 	AX
		mov 	AH, 09h
		int 	21h
		pop 	AX
		ret
PRINT_A_STR ENDP

BEGIN:
		mov 	AX,DATA
		mov		DS, AX
		push	ES
		mov 	ES, ES:[2CH]
		xor 	SI, SI
		lea 	DI, Path
Skip: 
		inc 	SI      
		cmp 	WORD PTR ES:[SI], 0000H
		jne 	Skip
		add 	SI, 4       
FileName:
		cmp 	BYTE PTR ES:[SI], 00H
		je 		EndFN
		mov 	DL, ES:[SI]
		mov 	[DI], DL
		inc 	SI
		inc 	DI
		jmp 	FileName   	
EndFN:
		sub 	DI, 7
		mov 	[DI], 'rl'
		add 	DI, 2
		mov 	[DI], '.2'
		add 	DI, 2
		mov 	[DI], 'OC'
		add 	DI, 2
		mov 	BYTE PTR[DI], 'M'
		inc 	DI
		mov 	DL, '$'
		mov 	[DI], DL
		pop 	ES
		call 	FrMem 
		call 	CreateParBl
		call 	callLr2
		xor 	AL,AL
		mov 	AH,4Ch ;выход 
		int 	21h
Last_byte:
	CODE ENDS

ASTACK SEGMENT STACK
	DW 64 DUP (?)
ASTACK ENDS

DATA SEGMENT
	ParBl dw ? ;сегментный адрес среды
	dd ? ;сегмент и смещение командной строки
	dd ? ;сегмент и смещение первого FCB
	dd ? ;сегмент и смещение второго FCB
	ErMem7     DB 0DH, 0AH,'MCB destroyed',0DH,0AH,'$'
	ErMem8     DB 0DH, 0AH,'Not enough memory for processing',0DH,0AH,'$'
	ErMem9     DB 0DH, 0AH,'Wrong address',0DH,0AH,'$'
	Ercall1    DB 0DH, 0AH,'Wrong number of function',0DH,0AH,'$'
	Ercall2    DB 0DH, 0AH,'File not found',0DH,0AH,'$'
	Ercall5    DB 0DH, 0AH,'Disk error',0DH,0AH,'$'
	Ercall8    DB 0DH, 0AH,'Not enough memory',0DH,0AH,'$'
	Ercall10   DB 0DH, 0AH,'Incorrect environment string',0DH,0AH,'$'
	Ercall11   DB 0DH, 0AH,'Wrong format',0DH,0AH,'$'
	ResEnd0    DB 0DH, 0AH,'Normal end',0DH,0AH,'$'
	ResEnd1    DB 0DH, 0AH,'Ctrl-Break end',0DH,0AH,'$'
	ResEnd2    DB 0DH, 0AH,'Device error end!',0DH,0AH,'$'
	ResEnd3    DB 0DH, 0AH,'Function 31h end!',0DH,0AH,'$'
	Path 	   DB 50 dup(0)
	KeepSS     DW 0
	KeepSP     DW 0
DATA ENDS
	END START