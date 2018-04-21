TESTPC SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
	ORG 100H
START:
	jmp BEGIN
;ДАННЫЕ
AvailableMemory			db		'Amount of available memory: $'
STRavailableMemory		db		'?????? B',10,13,'$'
ExtendedMemory			db		'Size of extended memory: $'
STRextendedMemory		db		'????? Kb',10,13,'$'
ControlBlocks			db		'Chain of memory control blocks:',10,13,'$'
INFOcontrolBlocks		db		'ADDRESS  OWNER  SIZE   NAME ',10,13,'$'
STRcontrolBlocks		db		'                                        ',10,13,'$'
STRerror				db		'Error.',10,13,'$'
FreeSpace				db		'0000h - FreeSpace',10,13,'$'
BelongDriver			db		'0006h - Space belongs to the driver',10,13,'$'
ExclusionDriver			db		'0007h - Space is the excluded upper memory of drivers',10,13,'$'
BelingMsDos				db		'0008h - Space belongs MS DOS',10,13,'$'
Occur386MAX				db		'FFFAh - Space is occupied by the control block 386MAX UMB',10,13,'$'
Block386MAX				db		'FFFDh - Space blocks 386MAX ',10,13,'$'
Belong386MAX			db		'FFFEh - Space belongs 386MAX UMB',10,13,'$'
;ПРОЦЕДУРЫ
;----------------------------------------------------- 
TETR_TO_HEX		PROC  near
			and      AL,0Fh
			cmp      AL,09
			jbe      NEXT
			add      AL,07 
NEXT:      	add      AL,30h
			ret 
TETR_TO_HEX		ENDP 
;------------------------------- 
BYTE_TO_HEX		PROC  near 
;байт в AL переводится в два символа шестн. числа в AX
            push     CX
            mov      AH,AL
            call     TETR_TO_HEX 
			xchg     AL,AH      
			mov      CL,4      
			shr      AL,CL    
			call     TETR_TO_HEX ;в AL старшая цифра
			pop      CX          ;в AH младшая           
			ret 
BYTE_TO_HEX		ENDP
;------------------------------- 
WRD_TO_HEX		PROC  near 
;перевод в 16 с/с 16-ти разрядного числа
;в AX-число, DI-адрес последнего символа
            push     BX
			mov      BH,AH
			call     BYTE_TO_HEX 
			mov      [DI],AH   
			dec      DI       
			mov      [DI],AL    
			dec      DI        
			mov      AL,BH      
			call     BYTE_TO_HEX   
			mov      [DI],AH       
			dec      DI           
			mov      [DI],AL        
			pop      BX          
			ret 
WRD_TO_HEX		ENDP 
;-------------------------------------------------- 
BYTE_TO_DEC		PROC  near 
;перевод в 10 с/с, SI-адрес поля младшей цифры    
			push     CX      
			push     DX         
			xor      AH,AH     
			xor      DX,DX     
			mov      CX,10 
loop_bd:    div      CX 
            or       DL,30h
            mov      [SI],DL
            dec      SI
            xor      DX,DX  
			cmp      AX,10  
			jae      loop_bd   
			cmp      AL,00h    
			je       end_l     
			or       AL,30h    
			mov      [SI],AL 
end_l:      pop      DX 
            pop      CX 
			ret 
BYTE_TO_DEC		ENDP
;--------------------------------------------------
TWO_BYTE_TO_DEC	PROC near
;перевод в 10 с/с, SI-адрес поля младшей цифры  
;DX:AX
			push 	 AX
			push     CX      
			push     DX  
			mov      CX,10 
loop_bd2:   div      CX 
            or       DL,30h
            mov      [SI],DL
            dec      SI
            xor      DX,DX  
			cmp      AX,10  
			jae      loop_bd2   
			cmp      AL,00h    
			je       end_l2     
			or       AL,30h
			mov      [SI],AL 
end_l2:     pop      DX 
            pop      CX 
			pop		 AX
			ret 
TWO_BYTE_TO_DEC	ENDP
;--------------------------------------------------
PRINT_A_STR		PROC near
			mov 	AH,09h
            int 	21h
			ret
PRINT_A_STR		ENDP
;--------------------------------------------------
; Количество доступной памяти
AM			PROC	near
			mov 	dx, offset AvailableMemory
			call 	PRINT_A_STR
			mov 	ah,4ah
			mov		bx,0ffffh ;Заведомо большая память
			int		21h	;Получение объема доступной памяти в регистр bx
			mov 	ax,bx
			xor 	dx,dx
			mov 	bx,10h
			mul 	bx	;DX:AX = AX * BX (умножаем на 16, параграф = 16 байт)
			mov 	si, offset STRavailableMemory + 5
			call 	TWO_BYTE_TO_DEC
			mov 	dx, offset STRavailableMemory
			call 	PRINT_A_STR

			ret
AM			ENDP
;--------------------------------------------------
; Размер расширенной памяти
EM			PROC	near
			mov 	dx, offset ExtendedMemory
			call 	PRINT_A_STR
			mov		al,30h 	; запись адреса ячейки CMOS
			out 	70h, al
			in		al, 71h ; чтение младшего байта
			mov		bl,al 	; размер расширенной памяти
			mov		al, 31h ; запись адреса ячейки CMOS
			out		70h, al
			in 		al, 71h ; чтение старшего байта
							; размер расширенной памяти
			mov		ah, al	
			mov		al, bl	; в ax - размер допустимой памяти
			xor     dx, dx
			mov		si, offset STRextendedMemory+4
			call 	TWO_BYTE_TO_DEC
			mov 	dx, offset STRextendedMemory
			call 	PRINT_A_STR
			
			ret
EM			ENDP
;--------------------------------------------------
; Цепочка блоков управления памятью
CB			PROC	near
			mov 	dx, offset ControlBlocks
			call 	PRINT_A_STR
			mov     dx, offset INFOcontrolBlocks
			call 	PRINT_A_STR
			mov		ah, 52h
			int		21h
			
			mov		ax, es:[bx-2]
			mov		es, ax
			mov 	dx, es
			xor 	bx, bx
	
Cycle:
			push 	ax
			push 	dx
			push 	bx
			push 	si
			push 	es
			push 	di
	
			mov 	di,offset STRcontrolBlocks+3 ; ADDRESS
			mov 	ax,es
			call 	WRD_TO_HEX
	
			mov 	di,offset STRcontrolBlocks+12 ; OWNER
			mov 	ax,es:[01h]
			cmp 	ax, 0000h
			je 		Con1
			cmp 	ax, 0006h
			je 		Con2
			cmp 	ax, 0007h
			je 		Con3
			cmp 	ax, 0008h
			je 		Con4
		  	cmp 	ax, 0FFFAh
		  	je 		Con5
		  	cmp 	ax, 0FFFDh
		  	je 		Con6
		  	cmp 	ax, 0FFFEh
		  	je 		Con7
		  	
		  	jmp 	Continion
Con1:
			push	ax
			push	dx
		  	mov 	dx, offset FreeSpace
		  	call 	PRINT_A_STR
			pop		dx
			pop		ax
		  	jmp 	Continion
Con2:
			push	ax
			push	dx
		  	mov 	dx, offset BelongDriver
		  	call 	PRINT_A_STR
			pop		dx
			pop		ax
		  	jmp 	Continion
Con3:
			push	ax
			push	dx
		  	mov 	dx, offset ExclusionDriver
		  	call 	PRINT_A_STR
			pop		dx
			pop		ax
		  	jmp 	Continion
Con4:
			push	ax
			push	dx
		  	mov 	dx, offset BelingMsDos
		  	call 	PRINT_A_STR
			pop		dx
			pop		ax
		  	jmp 	Continion
Con5:
			push	ax
			push	dx
		  	mov 	dx, offset Occur386MAX
		  	call 	PRINT_A_STR
			pop		dx
			pop		ax
		  	jmp 	Continion
Con6:
			push	ax
			push	dx
		  	mov 	dx, offset Block386MAX
		  	call 	PRINT_A_STR
			pop		dx
			pop		ax
		  	jmp 	Continion
Con7:
			push	ax
			push	dx
		  	mov 	dx, offset Belong386MAX
		  	call 	PRINT_A_STR
			pop		dx
			pop		ax
			
			
Continion:
			call 	WRD_TO_HEX
	
			mov 	si,offset STRcontrolBlocks+20 ; SIZE
			mov 	ax,es:[03h]

			mov 	bx,10h
			mul 	bx
			call 	TWO_BYTE_TO_DEC
			
			mov 	si,offset STRcontrolBlocks+23 ; NAME
			mov		bx, 08h
			mov		cx, 4
Cycle2:
			mov		ax, es:[bx]
			mov		[si], ax
			add		bx, 2h
			add		si, 2h
			loop	Cycle2
			
			mov 	dx,offset STRcontrolBlocks
			call 	PRINT_A_STR
			
			pop 	di
			pop 	es
			pop 	si
			pop 	bx
			pop 	dx
			pop 	ax
			
			cmp 	byte ptr es:[00h],5Ah
			je 		Exit
			inc 	dx
			add 	dx,es:[03h]
			mov 	es,dx
			
			jmp 	Cycle
Exit:

			ret
CB			ENDP
;--------------------------------------------------
;КОД
BEGIN:			
			call 	AM
			call 	EM
			call 	CB
;Вывод в DOS
			xor     AL,AL   
			mov     AH,4Ch   
			int     21H
TESTPC 		ENDS           
			END START     ;конец модуля , START - точка входа