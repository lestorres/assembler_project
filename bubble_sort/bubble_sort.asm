; Recuperar datos, ordenarlos y listarlos 
; Lesmes Torres Gonzalez

;-----------------------------------
; Sección de paquetes
%include "Linux64.inc"    ; Operaciones de impresión y cierre de archivo 
%include "syscalls.inc"   ; Compilación de llamadas al sistema 

; Sección de datos inicializados
section .data
    archivo_config db "configuracion.txt", 0
    archivo_datos  db "datos.txt", 0

    ; Mensajes del sistema		
    msg_inicio_programa      db "---Programa Iniciado---", 0xA, 0
    msg_config_open          db "---Inicio de la configuración---", 0xA, 0
    msg_lista_des_open       db "---Inicio de la lista desordenada---", 0xA, 0
    msg_lista_orden_open     db "---Inicio de la lista ordenada---", 0xA, 0
    msg_final_programa       db "---Programa Terminado---", 0xA, 0

    mensaje                  db "             Imprimiendo...", 0xA, 0

    nl db 0xA, 0  ; Salto de línea para ordenar

; Sección de datos no inicializados
section .bss
    leer_texto_config resb 154       ; leer la configuracion configuracion.txt   
    leer_texto_datos  resb 2048       ; Leer datos para datos.txt   

    ; Variables de recuperación de configuración
    nota_apro resb 3
    nota_repo resb 3
    tam_grupo resb 3
    escala    resb 3
    orden     resb 1

    ; array de los punteros a cada línea (8 bytes por puntero)
    arreglo_dir_datos resq 120 
    contador_bytes    resw 1          ; Almacena cantidad de bytes leídos

    ; Variables para estructurar los datos:

; Sección de código
section .text
    global _start

_start:
    print msg_inicio_programa

;---------------------Leer Configuración------------------
fetch_configuracion:
    mov rax, SYS_OPEN
    mov rdi, archivo_config
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall

    test rax, rax
    js salida_error
    mov rbx, rax  ; Descriptor del archivo

lectura_texto_config:
    mov rdi, rbx
    mov rax, SYS_READ
    mov rsi, leer_texto_config
    mov rdx, 154
    syscall

    test rax, rax
    jz cerrar_archivo_config

    mov rsi, leer_texto_config

;-----------Recuperar losw datos de configuración--------------------
fetch_nota_apro: 
    mov eax, [rsi+22]      ; Nota de aprobación
    mov [nota_apro], eax

fetch_nota_repo: 
    mov eax, [rsi+49]      ; Nota de reposición
    mov [nota_repo], eax

fetch_tam_grupo: 
    mov eax, [rsi+87]      ; Tamaño de grupo
    mov [tam_grupo], eax

fetch_escala:
    mov eax, [rsi+114]     ; Escala del gráfico
    mov [escala], eax

    mov al, [rsi+133]      ; Ordenamiento
    mov [orden], al

;------------------imprimir la configuración------------------------

    print msg_config_open
impresion_config:
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, leer_texto_config
    mov rdx, 154
    syscall

cerrar_archivo_config:
    mov rdi, rbx
    mov rax, SYS_CLOSE
    syscall

;------------------Leer lo datos de lista de estudiantes-----------------------
fetch_lista_de_datos:
    mov rax, SYS_OPEN
    mov rdi, archivo_datos
    mov rsi, O_RDONLY
    mov rdx, 0
    syscall

    test rax, rax
    js salida_error

    mov rbx, rax  ; carga el descriptor del archivo

    ; Leer el contenido completo del archivo
lectura_lista:
    mov rax, SYS_READ
    mov rdi, rbx
    mov rsi, leer_texto_datos
    mov rdx, 2048
    syscall

    ; Guardar la cantidad de bytes leídos en 'contador_bytes'
    mov [contador_bytes], ax

    ; Agregar terminador nulo al final 
    mov rcx, rax
    mov byte [leer_texto_datos + rcx], 0
    
    print nl
    print msg_lista_des_open
    print mensaje
    print leer_texto_datos

    mov rdi, rbx
    mov rax, SYS_CLOSE
    syscall


ordenamiento:
    print msg_lista_orden_open
    print mensaje
;------------------estructurar_datos-------------------------------
Estructurar_datos:
    ;-- Separar las líneas y almacenar sus direcciones en arreglo_dir_datos --
    mov rsi, leer_texto_datos       ; Puntero al inicio del buffer
    lea rdi, [arreglo_dir_datos]    ; Array para guardar punteros
    xor rcx, rcx                    ; Contador de líneas = 0

    ; Calcular la dirección final del buffer usando 'contador_bytes'
    mov rdx, leer_texto_datos       ; rdx = inicio del buffer
    movzx r8, word [contador_bytes]  ; r8 = cantidad de bytes leídos
    add rdx, r8                     ; rdx = dirección final del buffer

separa_lineas_loop:
    cmp rsi, rdx                    ; Si se alcanzó el final, salir
    jae bubble_sort  

    ; Guardar la dirección de inicio de la línea actual
    mov qword [arreglo_dir_datos + rcx*8], rsi
    inc rcx

    ; Buscar el final de la línea (LF o CR)
find_newline:
    cmp rsi, rdx
    jae separa_lineas_loop

    mov al, [rsi]
    cmp al, 0x0A
    je found_newline
    cmp al, 0x0D
    je found_newline

    inc rsi
    jmp find_newline

found_newline:
    ; Poner un caracter 0x00 de fin de línea por nulo y avanzar
    mov byte [rsi], 0
    inc rsi
    jmp separa_lineas_loop



bubble_sort:
;-----------------Inicio del bubblesort---------------

    mov r8, rcx     ; Número total de líneas en r8
    mov r9, 0       ; Índice i

outer_loop:
    cmp r9, r8
    jge print_sorted_list
    mov r10, 0      ; Índice j

inner_loop:
    mov r11, r8
    dec r11
    cmp r10, r11
    jge next_outer

    ; Cargar punteros de dos líneas consecutivas
    mov rax, [arreglo_dir_datos + r10*8]      ; Línea actual
    mov rbx, [arreglo_dir_datos + (r10+1)*8]    ; Siguiente línea

    ; Extraer nota de la línea actual
    push r8       ; Preservar r8
    push rcx      ; Preservar contador de líneas

    mov r12, rax
    call find_end_of_string    ; r12 apunta al fin de la cadena
    mov r13, r12
    sub r13, 3                 ; R13 apunta a los 3 dígitos de la nota
    call ascii_to_int          ; Resultado en r15 (nota actual)
    mov r14, r15               ; Guardar nota actual

    ; Extraer nota de la siguiente línea
    mov r12, rbx
    call find_end_of_string
    mov r13, r12
    sub r13, 3
    call ascii_to_int          ; Resultado en r15 (nota siguiente)

    ; Comparar notas (orden ascendente)
    cmp r14, r15
    jle no_swap

    ; Intercambiar punteros si la nota actual es mayor que la siguiente
    mov rdx, [arreglo_dir_datos + r10*8]
    mov [arreglo_dir_datos + r10*8], rbx
    mov [arreglo_dir_datos + (r10+1)*8], rdx

no_swap:
    pop rcx
    pop r8
    inc r10
    jmp inner_loop

next_outer:
    inc r9
    jmp outer_loop

;--------------------Imprimir la lista ordenada-------------------
print_sorted_list:
    mov rsi, 0   ; Índice = 0

print_loop:
    cmp rsi, r8
    jge terminar          ; Si se han impreso todas las líneas, salir

    ; Obtener el puntero a la línea ordenada e imprimirla
    mov rax, [arreglo_dir_datos + rsi*8]
    print rax             ; Imprime la línea
    print nl              ; Imprime un salto de línea

    inc rsi
    jmp print_loop

terminar:
    print msg_final_programa    
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

salida_error:
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

;------------------Subrutinas auxiliares-------------------------------

; find_end_of_string:
;   Entrada: r12 = puntero al inicio de la cadena.
;   Salida: r12 = puntero al carácter nulo (fin de cadena).
find_end_of_string:
find_end_loop:
    cmp byte [r12], 0
    je end_find
    inc r12
    jmp find_end_loop
end_find:
    ret

; ascii_to_int:
;   Convierte 3 dígitos ASCII (apuntados por r13) a entero.
;   Resultado: r15 = número entero.
ascii_to_int:
    ; Primer dígito
    movzx rax, byte [r13]
    sub rax, '0'
    imul rax, 100
    ; Segundo dígito
    movzx rcx, byte [r13+1]
    sub rcx, '0'
    imul rcx, 10
    add rax, rcx
    ; Tercer dígito
    movzx rcx, byte [r13+2]
    sub rcx, '0'
    add rax, rcx
    mov r15, rax
    ret
