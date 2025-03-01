%macro read_file 3  
; El macro toma tres(3) parámetros:
; nombre de archivo, variable de texto y cantidad de bytes a leer.

    ; Abrir el archivo
    mov rax, SYS_OPEN
    mov rdi, %1         ; Nombre del archivo (primer parámetro)
    mov rsi, O_RDONLY   ; Modo de solo lectura
    mov rdx, 0          ; Sin permisos adicionales
    syscall

    ; Leer desde el archivo
    push rax            ; Guardar el descriptor de archivo (se encuentra en rax)
    mov rdi, rax        ; Descriptor de archivo
    mov rax, SYS_READ
    mov rsi, %2         ; Espacio donde se almacenará el texto leído (segundo parámetro)
    mov rdx, %3         ; Número de bytes a leer (tercer parámetro)
    syscall

    ; Cerrar el archivo
    mov rax, SYS_CLOSE
    pop rdi             ; Recuperar descriptor de archivo
    syscall
    ret

%endmacro

