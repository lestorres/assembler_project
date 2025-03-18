;Recuperar datos
;Lesmes Torres Gonzalez

;-----------------------------------
;Seccion de paquetes
%include "Linux64.inc"    ;Operaciones de impresion y cierra de archivo 
%include "syscalls.inc" ;Compilacion de llamadas al sistema 

; Sección de datos inicializados
section .data
    	archivo_config db "configuracion.txt", 0

; Sección de datos no inicializados
section .bss
    	leer_texto_config resb 154 ; variable para leer el texto_config   
    
; Variables de recuperación
   	nota_apro resb 3
    	nota_repo resb 3
    	tam_grupo resb 3
    	escala resb 3
    	orden resb 1



; Sección de código
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

; Verificación de apertura del archivo
    	test rax, rax        ; Verificar si la apertura fue exitosa
    	js  salida_error     ; Salir si hubo un error
    	mov rbx, rax         ; Guardar descriptor del archivo

;-------------------------------------------------------------------
    
lectura_texto_config:
    	mov rdi, rbx                  ; Cargar el descriptor del archivo
    	mov rax, SYS_READ             ; Llamada para leer
    	mov rsi, leer_texto_config    ; Dirección de la variable para leer
    	mov rdx, 154                   ; Leer 30 bytes
	 syscall                       ; Realizar la lectura

; Verificación de lectura de bytes si no hay cierra el archivo
    	test rax, rax        ; Verificar si se leyeron bytes
    	jz  cerrar_archivo   ; Salir si no se leyeron bytes (fin de archivo)
     
	mov rsi, leer_texto_config ; cargo los bytes leídos de la linea
;-------------------------------------------------------------------
fetch_nota_apro: 
    	mov eax,[rsi+22]      ; Guardar nota apro
    	mov [nota_apro], eax

fetch_nota_repo: 
    	mov eax, [rsi+49]      ; Guardar nota repo
    	mov [nota_repo],eax

fetch_tam_grupo: 
    	mov eax, [rsi+87]      ; Guardar tam_grupo
    	mov [tam_grupo],eax

fetch_escala:
    	mov eax, [rsi+114]      ; Guardar escala
    	mov [escala], eax

fetch_orden:
    	mov al, [rsi+133]      ; Guardar orden
    	mov [orden],al
;-------------------------------------------------------------
jmp cerrar_archivo



cerrar_archivo:
    ;print nota_repo
    ;print tam_grupo
    ;print escala
    ;print orden
    ;rint nota_apro

    mov rdi, rbx         ; Cargar descriptor del archivo
    mov rax, SYS_CLOSE   ; Llamada para cerrar el archivo
    syscall

impresionn:
    mov rdi, 1                 ; fd = 1 (stdout)
    mov rax, SYS_WRITE         ; syscall: sys_write
    mov rsi, tam_grupo	       ; Dirección de la cadena a imprimir
    mov rdx, 3                 ; Longitud de la cadena (número de caracteres)
    syscall

terminar:
    ; Salir del programa
    mov rax, SYS_EXIT
    xor rdi, rdi         ; Código de salida 0
    syscall
    
salida_error:
    ; Manejo de error de apertura de archivo
    mov rax, SYS_EXIT
    mov rdi, 1           ; Código de salida 1 (error)
    syscall
