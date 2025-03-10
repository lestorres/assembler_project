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
    leer_uno resb 4   ; Reservar 4 bytes para los datos leídos

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
    mov rsi, leer_uno    ; Dirección de la variable para leer
    mov rdx, 1           ; Leer 1 byte
    syscall
    
    ;verificacion de lectura Bytes
    test rax, rax        ; Verificar si se leyeron bytes
    jz  fin_lectura      ; Salir si no se leyeron bytes (fin de archivo)
    
    ; Verificar si se leyó ":"
    mov al, byte [leer_uno]
    cmp al, ":"
    jne bucle_lectura_byte
    je  captura_dato     ; Si es ":", ir a captura_dato

captura_dato:
    ; Leer 4 bytes
    mov rdi, rbx         ; Cargar el descriptor del archivo
    mov rax, SYS_READ    ; Llamada al sistema para leer
    mov rsi, leer_uno    ; Dirección para almacenar los bytes leídos
    mov rdx, 4           ; Leer 4 bytes
    syscall
    
    ;verificacion de lectura Bytes
    test rax, rax        ; Verificar si se leyeron bytes
    jz  fin_lectura      ; Salir si no se leyeron bytes (fin de archivo)

    
filtro:
    ; Guardar los datos en las variables correspondientes
    mov al, byte [leer_uno + 1]
    mov [nota_apro + 1], al  ; Guardar segundo byte
    mov bl, byte [leer_uno + 2]
    mov [nota_apro + 2], bl  ; Guardar tercer byte
    mov cl, byte [leer_uno + 3]
    mov [nota_apro + 3], cl  ; Guardar cuarto byte

impresion:
    print nota_apro

Cerrar_archivo:
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
