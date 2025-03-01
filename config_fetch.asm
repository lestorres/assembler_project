; Lectura de archivo configuracion.txt

;---------------------------paquetes---------------------------
;Seccion de bibliotecas o paquetes necesarios

%include "Linux64.inc"
%include "syscalls.inc"
%include "read_file.inc"

;----------------variables inicializadas------------------------
;Constantes que se van a usar en el programa
section .data
    config_file_name db "configuracion.txt", 0 ;Nombre del archivo de config 
    cons_config_bytes: db 154 ;Espacio de texto a leer configuracion.txt

;----------------variables no inicializadas---------------------
section .bss
    config_text resb cons_config_bytes ; Espacio para almacenar el texto leído
                   ;147-n 149-a 154-max

;-------------------Segmento de codigo---------------------
;Comienzo de la ejecución del programa
;La ejecucion inicia en la etiqueta "_start"

section .text
global _start

_start
	;Llamar al macro read_file
	read_file config_file_name, config_text, cons_config_bytes

_fetch_config_
	
	print config_text
	;por hacer

_end_program
	mov rax, SYS_CLOSE ; llamada 60d (sys_exit) en rax
	pop rdi ; saca el valor de rdi
	syscall

;fin del programa
