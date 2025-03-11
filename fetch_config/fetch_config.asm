;Fetch config
;Lesmes Torres Gonzalez

;-----------------------------------
;Seccion de paquetes
%include "Linux64.inc"    ;Operaciones de impresion y cierra de archivo 
%include "syscalls.inc" ;Compilacion de llamadas al sistema 

; Sección de datos
section .data
    archivo_config db "configuracion.txt", 0
    var_fetch_config db 0, 0 ; contador de variables se crea en 0

    ; Variables de recuperación
    nota_apro db 3
    nota_repo db 3
    tam_grupo db 3
    escala db 3
    orden db 3

; Sección de datos no inicializados
section .bss
    leer resb 4   ; variable de 4 bytes para los datos leídos

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

; Bucle de lectura de configuracion.txt
bucle_lectura_byte:
    mov rdi, rbx         ; Cargar el descriptor del archivo
    mov rax, SYS_READ    ; Llamada para leer un byte
    mov rsi, leer        ; Dirección de la variable para leer
    mov rdx, 1           ; Leer 1 byte
    syscall	

    ; Verificación de lectura de bytes
    test rax, rax        ; Verificar si se leyeron bytes
    jz  cerrar_archivo   ; Salir si no se leyeron bytes (fin de archivo)
    
    ; Verificar si se leyó ":"
    mov al, byte[leer]
    cmp al, ":"
    jne bucle_lectura_byte ; NO es ":"

contador_config:
    mov al, byte[var_fetch_config] ; cargo el contador
    
  ;  comp al, 4
  ;  jh cerrar_archivo


    cmp al, 0   ; es cero?
    je fetch_nota_apro 

    cmp al, 1   ; es uno?
    je fetch_nota_repo

    cmp al, 2   ; es dos?
    je fetch_tam_grupo 

    cmp al, 3   ; es tres?
    je fetch_escala 

    cmp al, 4   ; es cuatro?
    je fetch_orden 

    jmp cerrar_archivo

fetch_nota_apro:
    call captura_dato
    mov [nota_apro + 1], al  ; Guardar segundo byte
    mov [nota_apro + 2], bl  ; Guardar tercer byte
    mov [nota_apro + 3], cl  ; Guardar cuarto byte

    
    add byte[var_fetch_config],1 ; Avanzar el contador
    jmp cerrar_archivo

fetch_nota_repo:
    inc byte[var_fetch_config] ; Avanzar el contador
    call captura_dato
    mov [nota_repo + 1], al  ; Guardar segundo byte
    mov [nota_repo + 2], bl  ; Guardar tercer byte
    mov [nota_repo + 3], cl  ; Guardar cuarto byte
    jmp cerrar_archivo

fetch_tam_grupo:
    inc byte[var_fetch_config]
    call captura_dato
    mov [tam_grupo + 1], al  ; Guardar segundo byte
    mov [tam_grupo + 2], bl  ; Guardar tercer byte
    mov [tam_grupo + 3], cl  ; Guardar cuarto byte
    jmp bucle_lectura_byte

fetch_escala:
    inc byte[var_fetch_config]
    call captura_dato
    mov [escala + 1], al  ; Guardar segundo byte
    mov [escala + 2], bl  ; Guardar tercer byte
    mov [escala + 3], cl  ; Guardar cuarto byte
    jmp bucle_lectura_byte

fetch_orden:
    inc byte[var_fetch_config]
    call captura_dato
    mov [orden + 1], al  ; Guardar segundo byte
    mov [orden + 2], bl  ; Guardar tercer byte
    mov [orden + 3], cl  ; Guardar cuarto byte
    jmp cerrar_archivo

;-------------------------
; Función captura_dato
;-------------------------
captura_dato:
    ; Leer 4 bytes
    mov rdi, rbx         ; Cargar el descriptor del archivo
    mov rax, SYS_READ    ; Llamada al sistema para leer
    mov rsi, leer        ; Dirección para almacenar los bytes leídos
    mov rdx, 4           ; Leer 4 bytes
    syscall
    
    ; Verificación de lectura de bytes
    test rax, rax        ; Verificar si se leyeron bytes
    jz cerrar_archivo    ; Salir si no se leyeron bytes (fin de archivo)

filtro:
    ; Se salta el primer byte por ser un espacio
    mov al, byte [leer + 1] ; Segundo byte

    ; Verificar si se leyeron dos "saltos de línea" (caso valor menor a 10)
    mov bl, byte[leer + 2] ; Tercer byte
    cmp bl, 0x0A ; Comparar con Salto de línea (0x0A)
    je corregir_salto_linea_dos; Si es, ir a corregir salto línea
    
    ; Verificar si se leyó un "salto de línea" (caso valor menor a 100)
    mov cl, byte[leer + 3] ; Cuarto byte
    cmp cl, 0x0A ; Salto de línea 0x0A
    je corregir_salto_linea_uno; Si es, ir a corregir salto línea
    
    jmp guardando

corregir_salto_linea_uno:
    mov cl, 0
    jmp guardando

corregir_salto_linea_dos:
    mov bl, 0 ; pone un espacio vacío
    mov cl, 0
    
    jmp guardando

guardando:
    ret

cerrar_archivo:
    impresion:
        print nota_apro
        ;print nota_repo
        ; print tam_grupo
        ; print escala
        ; print orden

    mov rdi, rbx         ; Cargar descriptor del archivo
    mov rax, SYS_CLOSE   ; Llamada para cerrar el archivo
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
