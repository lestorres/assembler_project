;Fetch config
;Lesmes Torres Gonzalez

;-----------------------------------
;Seccion de paquetes
%include "Linux64.inc"    ;Operaciones de impresion y cierra de archivo 
%include "syscalls.inc" ;Compilacion de llamadas al sistema 


;-----------------------------------
;Seccion de datos inicializados
section .data
	archivo_config db "configuracion.txt",0
	var_fetch_config db 0, 0 ;contador de variables se crea en 0

	;Variables de recuperacion
	nota_apro db  3
	nota_repo db  3
	tam_grupo db  3
	escala    db  3
	orden     db  3
;-----------------------------

section .bss
    	leer resb 4   ; variable leer de 4 bytes para los datos leídos

section .text
    	global _start

_start:
; Abrir archivo configuracion.txt
apertura:
    	mov rax, SYS_OPEN    ; Llamada al sistema para abrir el archivo
    	mov rdi, archivo_config ; Nombre del archivo
    	mov rsi, O_RDONLY    ; Solo lectura
    	mov rdx, 0           ; No flags adicionales
    	syscall

    	; Verificacion de apertura del archivo
    	test rax, rax        ; Verificar si la apertura fue exitosa
    	js  salida_error     ; Salir si hubo un error
    	mov rbx, rax         ; Guardar descriptor del archivo

; Inicio de bucle de lectura de configuracion.txt
bucle_lectura_byte:
    	mov rdi, rbx         ; Cargar el descriptor del archivo
    	mov rax, SYS_READ    ; Llamada para leer un byte
    	mov rsi, leer    ; Dirección de la variable para leer
    	mov rdx, 1           ; Leer 1 byte
    	syscall
    
    	;verificacion de lectura Bytes
    	test rax, rax        ; Verificar si se leyeron bytes
    	jz  cerrar_archivo   ; Salir si no se leyeron bytes (fin de archivo)
    
    	; Verificar si se leyó ":"
    	mov al, byte[leer]
   	cmp al, ":"
   	jne bucle_lectura_byte
    	je  captura_dato     ; Si es ":", ir a captura_dato

captura_dato:
    	; Leer 4 bytes
    	mov rdi, rbx         ; Cargar el descriptor del archivo
    	mov rax, SYS_READ    ; Llamada al sistema para leer
    	mov rsi, leer    ; Dirección para almacenar los bytes leídos
    	mov rdx, 4           ; Leer 4 bytes
    	syscall
    
    	;verificacion de lectura Bytes
    	test rax, rax        ; Verificar si se leyeron bytes
    	jz cerrar_archivo    ; Salir si no se leyeron bytes (fin de archivo)

    
filtro:
    	;Se salta el primer byte por ser un espacio
    	
	mov al, byte [leer + 1]	;Segundo byte

    	; Verificar si se leyeron dos "salto de linea" (caso valor menor a 10)
	mov bl, byte[leer + 2] ; Tercer byte
   	cmp bl, 0x0A ;compara con Salto de linea (0x0A)
    	je corregir_salto_linea_dos; Si es, ir a corregir salto linea
    	
       	; Verificar si se leyó un "salto de linea" (caso valor menor a 100)
    	mov cl, byte[leer + 3] ; Cuarto byte
   	cmp cl, 0x0A ; Salto de linea 0x0A
    	je corregir_salto_linea_uno; Si es, ir a corregir salto linea
	
	jmp fetch_datos

corregir_salto_linea_uno:
	mov cl, 0
	jmp fetch_datos

corregir_salto_linea_dos:
	mov bl, 0 ; pone un espacio vacio
	mov cl, 0
	jmp fetch_datos

fetch_datos:

fetch_nota_apro:

    	mov [nota_apro + 1], al  ; Guardar segundo byte
    	mov [nota_apro + 2], bl  ; Guardar tercer byte
    	mov [nota_apro + 3], cl  ; Guardar cuarto byte
impresion:
    	print nota_apro

cerrar_archivo:
    	mov rdi, rbx         ; Cargar descriptor del archivo
    	mov rax, SYS_CLOSE   ; Llamada para cerrar el archivo
    	syscall

Terminar:

    	; Salir del programa
    	mov rax, SYS_EXIT
    	xor rdi, rdi         ; Código de salida 0
    	syscall
    
  
salida_error:
    	; Manejo de error de apertura de archivo
    	mov rax, SYS_EXIT
    	mov rdi, 1           ; Código de salida 1 (error)
    	syscall


