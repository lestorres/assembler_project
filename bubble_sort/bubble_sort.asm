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

fetch_orden:
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

;leer el archivo
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


ordenamiento_datos:
    print msg_lista_orden_open
    print mensaje

;------------------estructurar_datos-------------------------------
estructurar_datos:
    ;Separar las líneas y almacenar sus direcciones en arreglo_dir_datos --
    mov rsi, leer_texto_datos       ; Puntero al inicio del buffer
    lea rdi, [arreglo_dir_datos]    ; Array para guardar punteros
    xor rcx, rcx                    ; Contador de líneas = 0

    ; Calcular la dirección final del buffer usando 'contador_bytes'
    mov rdx, leer_texto_datos       ; rdx = inicio del buffer
    movzx r8, word [contador_bytes]  ; r8 = cantidad de bytes leídos
    add rdx, r8                     ; rdx = dirección final del buffer

separa_lineas_loop:
    cmp rsi, rdx                    ; Si se alcanzó el final, salir
    jae comprobar_orden
    
    ; Guardar la dirección de inicio de la línea actual
    mov qword [arreglo_dir_datos + rcx*8], rsi
    inc rcx

    ; Buscar el final de la línea o retorno de carro
encontrar_linea:
    cmp rsi, rdx
    jae separa_lineas_loop

    mov al, [rsi]
    cmp al, 0x0A ;salto de linea?
    je nueva_linea_encontrada
    cmp al, 0x0D ; retorno de carro?
    je nueva_linea_encontrada

    inc rsi
    jmp encontrar_linea

nueva_linea_encontrada:
    ; Poner un caracter 0x00 de fin de línea por nulo y avanzar
    mov byte [rsi], 0
    inc rsi
    jmp separa_lineas_loop
;---------------------------------------------------------------------------

comprobar_orden:
    push rax ;preservar el rax en el stack
    ;para comprobar el bit de orden    

    ;es orden alfabetico?
    mov al, byte[orden] 
    cmp al, 0x61	;Revisa si el ordenamiento es una "a" de Alfabetico
    je bubble_sort_alfabetico

    
    cmp al, 0x41        ;Reovisa si el ordenamiento es una "A" de Alfabetico
    je bubble_sort_alfabetico

    pop rax ; liberar el rax del stack

;Sino es "a" o "alfabetico" se ordena como numerico por notas

bubble_sort_numerico:
;--------------Inicio del bubblesort numerico--------------

    mov r8, rcx     ; Numero total líneas en r8
    mov r9, 0       ; indice i

outer_loop:
    cmp r9, r8
    jge print_sorted_notas_lista
    mov r10, 0      ; indice j

inner_loop:
    mov r11, r8
    dec r11
    cmp r10, r11
    jge next_outer

    ; Cargar punteros de dos líneas consecutivas
    mov rax, [arreglo_dir_datos + r10*8]      ; Linea actual
    mov rbx, [arreglo_dir_datos + (r10+1)*8]    ; línea que sigue

    ; Extraer nota de la linea actual
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
    pop rcx ;regresar del stack
    pop r8
    inc r10
    jmp inner_loop

next_outer:
    inc r9
    jmp outer_loop

;--------------------Imprimir la lista ordenada-------------------
print_sorted_notas_lista:
    mov rsi, 0   ; Índice = 0

print_loop:
    cmp rsi, r8
    jge fin_n          ; Si se han impreso todas las líneas, salir

    ; Obtener el puntero a la línea ordenada e imprimirla
    mov rax, [arreglo_dir_datos + rsi*8]
    print rax             ; Imprime la línea
    print nl              ; Imprime un salto de línea

    inc rsi
    jmp print_loop

fin_n:
    jmp terminar   
;---------------------------------------------------------------------------



;--------------Inicio del Bubble Sort Alfabético --------------------------

bubble_sort_alfabetico:
    mov r8, rcx         ; Número total de líneas en r8 (el número de nombres)
    mov r9, 0           ; Índice i (bucle externo)

outer_loop_a:
    cmp r9, r8
    jge imprimir_a
    mov r10, 0          ; Índice j (bucle interno)

inner_loop_a:
    mov r11, r8
    dec r11
    cmp r10, r11
    jge next_outer_a

    ; Cargar punteros de dos cadenas consecutivas
    mov rax, [arreglo_dir_datos + r10*8]    ;Línea actual (nombre actual)
    mov rbx, [arreglo_dir_datos + (r10+1)*8];Línea siguiente (nombre siguiente)

    ; Cargar la primera letra 
    mov al, [rax]  ; primera letra de nombre actual
    mov bl, [rbx]  ; primera letra de nombre siguiente
    cmp al, bl
    jg swap_a  ; Si la primera letra de actual es mayor, intercambiar
    jl no_swap_a ; Si es menor, no intercambiar 
    
    ; Si son iguales, comparar la segunda letra
    mov ah, [rax + 1] ; segunda letra de nombre actual
    mov bh, [rbx + 1] ; segunda letra de nombre siguiente
    cmp ah, bh
    jg swap_a  ; Si la segunda letra de actual es mayor, intercambiar
    jl no_swap_a ; Si es menor, no intercambiar 
 
no_swap_a:
    inc r10               ; Incrementar el índice j
    jmp inner_loop_a      ; Continuar con el siguiente par de cadenas

swap_a:
    ; Intercambiar si nombre actual debe ir después
    mov rdx, [arreglo_dir_datos + r10*8]
    mov rbx, [arreglo_dir_datos + (r10+1)*8]
    mov [arreglo_dir_datos + r10*8], rbx
    mov [arreglo_dir_datos + (r10+1)*8], rdx

    jmp inner_loop_a      ; Continuar con el siguiente par de cadenas

next_outer_a:
    inc r9                ; Incrementar el índice i
    jmp outer_loop_a      ; Volver al bucle externo

imprimir_a:
    ; Código para imprimir la lista ordenada
    mov r10, 0              ; Índice de impresión

print_sorted_list_a:
    mov rax, [arreglo_dir_datos + r10*8]    ; Cargar puntero de la cadena
    print rax
    print nl
    
    inc r10 ;incrementa para otra lineac
    cmp r10, r8
    jl print_sorted_list_a   ; continuar con otra linea

    ; Fin de la impresión
    jmp fin_a

fin_a:
    jmp terminar    

;--------------final del programa---------------------------
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

find_opening_of_string:
; find_end_of_string:
;   Entrada: r12 = puntero al inicio de la cadena.
;   Salida: r12 = puntero al carácter nulo (fin de cadena).i

find_end_of_string:

bucle_busca_final:
;leer hasta encontrar el null de la linea
    cmp byte [r12], 0
    je end_find
    inc r12
    jmp bucle_busca_final
encontro_final_linea:
    ret

; transformae de ascii_to_int:
;acá transformo los
;   3 dígitos ASCII (apuntados por r13) a un entero.
;   Resultado: r15 = número entero.
ascii_to_int:
    ; Primer dígito (centecimas)
    movzx rax, byte [r13]; move with extend zero(pone ceros lo que no se llno)
    sub rax, '0' ; al restarle 0 se encuentra su valor numerico
    imul rax, 100 ; multiplica las centenas

    ; Segundo dígito (decimas)
    movzx rcx, byte [r13+1]
    sub rcx, '0'
    imul rcx, 10
    add rax, rcx

    ; Tercer dígito (unidades)
    movzx rcx, byte [r13+2]
    sub rcx, '0'
    add rax, rcx
    mov r15, rax
    ret
