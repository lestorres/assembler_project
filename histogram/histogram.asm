; Recuperar datos, ordenarlos, listarlos y graficarlos
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
    msg_histogram     	     db "---Inicio del histograma---", 0xA, 0
    msg_final_programa       db "---Programa Terminado---", 0xA, 0

    mensaje                  db "             Imprimiendo...", 0xA, 0
    nl db 0xA, 0  ; Salto de línea para ordenar
    espacio db " " ,0      ; espacio

; Varibles definidas para histograma

    msg_estudiantes  db "Numero de estudiantes", 0xA , 0
    msg_notas db "--> Notas", 0xA, 0

; Códigos ANSI para colores de letras "x"
    color_verde   db 0x1b, "[32m", 0
    color_naranja db 0x1b, "[33m", 0
    color_rojo    db 0x1b, "[31m", 0
    color_reset   db 0x1b, "[37m", 0

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
    contador_lineas   resb 1

; Variables de histograma
    int_nota_apro resq 1
    int_nota_repo resq 1
    int_tam_grupo resq 1
    int_escala    resq 1

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
    print nl
    print msg_lista_orden_open
    print mensaje

;------------------estructurar_datos-------------------------------
estructurar_datos:
    mov byte [contador_lineas], 0
    ;Separar las líneas y almacenar sus direcciones en arreglo_dir_datos --
    mov rsi, leer_texto_datos       ; Puntero al inicio del buffer
    lea rdi, [arreglo_dir_datos]    ; Array para guardar punteros
    movzx rcx, byte[contador_lineas]  ; Contador de líneas = 0

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
    inc byte[contador_lineas]

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

;Sino es "a" o "alfabetico" se ordena como numerico por notas ->


;--------------------Inicio del Selection Sort Numérico--------------------
selection_sort_numerico:
    ; Cargar el número total de líneas desde contador_lineas en R8
    movzx r8, byte [contador_lineas] ; r8 = total de líneas
    mov r9, 0                          ; i = 0 (índice del elemento a llenar)

sel_outer: ; bucle externo
    cmp r9, r8
    jge print_sorted_notas_lista       ; Si i >= total, terminar
    mov r10, r9                        ; min_index = i
    mov r11, r9                        ; j = i

sel_inner: ;bucle interno
    inc r11                            ; j = j + 1
    cmp r11, r8
    jge sel_swap                       ; Si j >= total, saltar a swap
    ; Comparar la nota en posición j con la nota en posición min_index

    ; Extraer nota del elemento en j:
    mov rax, [arreglo_dir_datos + r11*8]
    push r8
    push rcx
    mov r12, rax
    call find_end_of_string           ; R12 apunta al nulo
    mov r13, r12
    sub r13, 3                        ; R13 apunta a los 3 dígitos de la nota
    call ascii_to_int                 ; Resultado en r15: nota_j
    mov r14, r15                      ; Guardar nota_j en r14
    pop rcx
    pop r8

    ; Extraer nota del elemento en min_index (r10):
    mov rax, [arreglo_dir_datos + r10*8]
    push r8
    push rcx
    mov r12, rax
    call find_end_of_string           ; R12 apunta al nulo
    mov r13, r12
    sub r13, 3                        ; R13 apunta a los 3 dígitos de la nota
    call ascii_to_int                 ; Resultado en r15: nota_min
    mov r15, r15                      ; nota_min en r15 
    pop rcx
    pop r8

    cmp r14, r15
    jl update_min_index              ; Si nota_j < nota_min, actualizar min_index
    jmp sel_inner

update_min_index:
    mov r10, r11                     ; min_index = j
    jmp sel_inner

sel_swap:
    ; Si el mínimo encontrado no está en la posición i, intercambiar
    cmp r9, r10
    je no_swap_sel
    mov rax, [arreglo_dir_datos + r9*8]
    mov rbx, [arreglo_dir_datos + r10*8]
    mov [arreglo_dir_datos + r9*8], rbx
    mov [arreglo_dir_datos + r10*8], rax

no_swap_sel:
    inc r9                           ; i = i + 1
    jmp sel_outer

;--------------------Imprimir la Lista Ordenada Numéricamente--------------------
print_sorted_notas_lista:
    mov r10, 0                       ; Índice para recorrer el arreglo
    movzx r8, byte [contador_lineas] ; r8 = total de líneas

print_loop_num:
    cmp r10, r8
    je fin_n
   
    mov rax,    [arreglo_dir_datos + (r10)*8]
    print rax   ; Imprime la línea completa
    print nl
    inc r10

    jmp print_loop_num

fin_n:
    jmp histograma   
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
    jmp histograma   





;-----------------------histograma--------------------------
histograma:
    print nl
    print msg_histogram
    print nl

convertir_config_ints:

; Convertir nota_apro
mov r13, nota_apro       ; r13 apunta a la cadena "nota_apro"
call ascii_to_int        ; convierte y coloca el valor en r15
mov [int_nota_apro], r15 ; guarda el entero convertido

; Convertir nota_repo
mov r13, nota_repo
call ascii_to_int
mov [int_nota_repo], r15

; Convertir tam_grupo
mov r13, tam_grupo
call ascii_to_int
mov [int_tam_grupo], r15

; Convertir escala
mov r13, escala
call ascii_to_int
mov [int_escala], r15

;-------impresion del marco del histograma ----------
print msg_estudiantes
calculo_ejes:
    ; Inicializamos las variables
    mov r8, [int_escala]      ; r8 = escala
    mov r9, [int_tam_grupo]   ; r9 = tam_grupo

    ; --- Imprimir las divisiones del eje Y ---
    ; Empezamos desde 100 y restamos la escala en cada paso hasta llegar a 0
    mov r10, 100              ; r10 = 100 (inicio del eje Y)

y_loop:
    ; Imprimir valor actual en el eje Y
    mov rsi, r10              ; rsi = valor actual para eje Y
    printVal rsi              ; Imprime el valor de r10
    sub r10, r8               ; Restar la escala (r8)
    cmp r10, 0                ; Comparar si hemos llegado a 0
    jg y_loop                 ; Si r10 > 0, continuar en el bucle

    ; --- Imprimir salto de línea para separar ejes ---
    ;print nl

    ; --- Imprimir las divisiones del eje X ---
    ; Comenzamos desde 0 y sumamos tam_grupo hasta llegar a 100
    mov r10, 0              ; r10 = 0 (inicio del eje X)

x_loop:
    ;Imprimir el valor actual de r10 en la misma línea
    printValInline r10

    add r10, r9         ; Sumar el valor de r9 al número en r10

    ; Comparar si r11 > 100
    cmp r10, 100
    jg x_end            ; Si r10 > 100, salir del bucle

    ; Continuar en el bucle
    jmp x_loop

x_end:


print msg_notas

;--------------final del programa---------------------------
terminar:
    print nl
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
    je encontro_final_linea
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
