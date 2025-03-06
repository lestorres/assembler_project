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
	var_fetch_config db 0, 0 ;contador de variables

	
;-----------------------------------
;Sección de datos no inicializados
section .bss 
	nota_apro db  3
	nota_repo db  ?
	tam_grupo db  ?
	escala    db  ?
	orden     db  ?
	
	leer_dos resb 24 ; variable de lectura de 2 bytes
	leer_tres resb 3 ; variable de lectura de 3 bytes
;-----------------------------------
;Sección de ejecucion

section .text
	global _start

_start:
; Abrir archivo

apertura: mov rax, SYS_OPEN
	  mov rdi, archivo_config
	  mov rsi, O_RDONLY
	  mov rdx, 0
	  syscall
	
	;Verifica que haya contenido dentro del archivo 
	test rax, rax
	js apertura_error


;Leer archivo

lectura: push rax    		
	 mov rdi, rax		;cargo la apertura
	 mov rax, SYS_READ	
	 mov rsi, leer_dos	;Almaceno los 20 bytes
	 mov rdx, 24		;almaceno la dir.memoria
	 syscall
	
	;Verificar si se leyeron 0 bytes, fin del archivo
	test rax,rax
	jz cerrado


; Guardar datos en nota_apro de la primera linea leida

Guardado_datos:	
	mov rsi, leer_dos
	mov rdi, nota_apro
	mov rcx, 24
	cld
	rep movsb ; copia los bytes de leer dos a nota_apro
	
;cerrar archivo
cerrado: pop rdi
	 mov rax, SYS_CLOSE
	 syscall

; imprimir nota_apro
imprimir:
	print nota_apro
	
;salir del programa
salir:	 mov rax, SYS_EXIT
	 xor rdi, rdi
	 syscall	

apertura_error:
	mov rax, SYS_EXIT
	mov rdi, 1
	syscall
