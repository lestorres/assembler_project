; Recuperar datos, ordenarlos, listarlos y graficarlos
; Lesmes Torres Gonzalez

;--------------------------------------------------------------------
; Sección de paquetes
%include "Linux64.inc"    ; Operaciones de impresión y cierre de archivo 
%include "syscalls.inc"   ; Compilación de llamadas al sistema 

;----------------------------------------------------------------------
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

; Varibles definidas para histograma

    msg_estudiantes  db "Numero de estudiantes", 0xA , 0
    msg_notas db "--> Notas", 0xA, 0




; Códigos ANSI para colores de letras "x"
    color_verde   db 0x1b, "[32m", 0
    color_naranja db 0x1b, "[33m", 0
    color_rojo    db 0x1b, "[31m", 0
    color_reset   db 0x1b, "[37m", 0





;-------------------------------------------------------------------
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


;Variables de recuperación de datos

    arreglo_dir_datos resq 120  ; array de los punteros para datos ordenados  
    contador_bytes    resw 1     ; Almacena cantidad de bytes leídos
    contador_lineas   resb 1     ;CONTADOR DE LINEAS

; Variables de histograma
    int_nota_apro resq 1
    int_nota_repo resq 1
    int_tam_grupo resq 1
    int_escala    resq 1

    arreglo_notas resd 120  ; notas convertidos a enteros de 4 bytes

    num_de_grupos resd 1    ; Numero de grupos
    arreglo_contadores resd 21   ; arreglo de contadores eje x (tam_grupo lo define)

  
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
    jmp histogram   
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
    jmp histogram    


;-----------------------histograma--------------------------
histogram:
    print nl
    print msg_histogram

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

extractor_de_notas:
;---------------------------------------------------------
; Extraer notas y convertirlas a enteros
; A este punto tengo:
; + Las líneas de datos almacenadas en arreglo_dir_datos
; + Cada línea termina con un '\0' o null 
; + La nota ocupa los ultimos 3 caracteres
; + El contador de líneas está en 'contador_lineas'
;----------------------------------------------------------

extraer_notas:
    ; r8 = total de líneas
    movzx r8, byte [contador_lineas]  ;mover con extension de ceros
    xor rdi, rdi               ; Índice i = 0, va a ser el contador

extraer_notas_loop:
    cmp rdi, r8                ; ¿i >= total de líneas?
    jge fin_extraer_notas

    mov rax, [arreglo_dir_datos + rdi*8] ; dirección de la línea actual

    ; buscar el final de linea
    mov r12, rax
    call find_end_of_string    ; Al regresar, r12 apunta al carácter nulo

    ; Retroceder 3 bytes para posicionarse en los dígitos de la nota
    mov r13, r12
    sub r13, 3               ; r13 ahora apunta a los 3 dígitos

    ; Llamar a ascii_to_int: el entero resultante se obtiene en r15
    call ascii_to_int

    ; Guardar la nota convertida en el array de notas
    ; Cada nota es un entero (4 bytes), así que usamos rdi*4 como offset.
    mov [arreglo_notas + rdi*4], r15

    inc rdi                  ; Incrementar el índice
    jmp extraer_notas_loop

fin_extraer_notas:
	printVal arreglo_notas




definir_grupos_notas:

definir_grupos:
    mov ebx, [int_tam_grupo]  ;  Cargar el tamaño del grupo EBX = tam_grupo

    ; Dividir 100 entre tam_grupo.
    ; EAX contendrá el cociente, EDX el residuo.
    mov eax, 100
    xor edx, edx
    div ebx                   ; EAX = 100 / tam_grupo, EDX = residuo

    ; Si hay residuo, se requiere un grupo adicional.
    cmp edx, 0
    je grupos_calculados
    inc eax                   ; EAX = número total de grupos

grupos_calculados:
    mov [num_de_grupos], eax     ; Guardar el número total de grupos


; Suponiendo que en EBX se encuentre tam_grupo (ya cargado desde int_tam_grupo)
; y que en [num_de_grupos] esté el total de grupos.
definir_rangos:
    ; Cargar tam_grupo en EBX
    mov ebx, [int_tam_grupo]
    
    ; Cargar número total de grupos en ECX
    mov ecx, [num_de_grupos]   ; ECX = total de grupos
    xor edi, edi            ; EDI = índice i (inicia en 0)

rango_loop:
    cmp edi, ecx
    jge fin_rangos          ; Si i >= número de grupos, salimos

    ; Calcular: upper = 100 - i*tam_grupo
    ; Usamos EDI en EAX
    mov eax, edi
    imul eax, ebx           ; eax = i * tam_grupo
    mov edx, 100
    sub edx, eax            ; edx = 100 - (i * tam_grupo)
    ; Guardamos el valor superior en, por ejemplo, [temp_upper] (variable temporal en .bss o en registro)
    ; Para este ejemplo, usaremos EDX directamente.
    
    ; Calcular: lower = upper - tam_grupo + 1
    mov eax, edx            ; eax = upper
    sub eax, ebx            ; eax = upper - tam_grupo
    inc eax                 ; eax = upper - tam_grupo + 1

    ; Si el valor lower es negativo, ajustarlo a 0
    cmp eax, 0
    jge sin_ajuste
    mov eax, 0
sin_ajuste:
    ; En este punto:
    ; EDX tiene el límite superior del grupo (upper)
    ; EAX tiene el límite inferior del grupo (lower)
    ; Aquí podrías, por ejemplo, imprimir el rango o guardarlo en alguna estructura.
    ; Por ejemplo:
    ; print "Grupo i: upper - lower"
    ; (Utiliza tus rutinas de impresión para mostrar estos valores)
    
    ; Incrementar índice de grupo
    inc edi
    jmp rango_loop

fin_rangos:
    ; Aquí ya se han definido los rangos para cada grupo.

printVal num_de_grupos

distribucion_de_los_grupos_de_notas:
;---------------------------------------------------------
; Distribuir notas en grupos
;---------------------------------------------------------
distribuir_en_grupos:
    ; Se asume que:
    ; - [int_tam_grupo] contiene el tamaño del grupo (por ejemplo, 10).
    ; - [num_groups] contiene el número total de grupos.
    ; - El total de notas leídas está en 'contador_lineas'.
    
    ; Guardar en un registro el tam_grupo para usarlo en las divisiones
    mov ebx, [int_tam_grupo]    ; EBX = tam_grupo

    ; Obtener el total de notas leídas (contador_lineas)
    movzx rcx, byte [contador_lineas]  ; RCX = total de notas

    xor rdi, rdi              ; Índice i = 0

distribuir_loop:
    cmp rdi, rcx
    jge fin_distribuir        ; Si i >= total de notas, terminar

    ; Cargar la nota actual desde notas_array
    mov eax, [notas_array + rdi*4]  ; EAX = nota actual

    ; Calcular grupo: (100 - nota) / tam_grupo
    mov edx, 0                ; Limpiar EDX antes de la división
    mov edi, eax              ; Mover la nota a EDI para operar
    ; Restar la nota de 100
    mov eax, 100              ; EAX = 100
    sub eax, edi              ; EAX = 100 - nota

    ; Dividir entre tam_grupo (EBX)
    xor edx, edx              ; Asegurarse de que EDX = 0
    div ebx                   ; EAX = (100 - nota) / tam_grupo, residuo en EDX

    ; Ahora EAX contiene el índice del grupo.
    ; Opcional: Si deseas limitar el índice al número máximo de grupos, podrías comparar con [num_groups]
    ; Aquí asumiremos que la fórmula es válida para todas las notas.
    
    ; Incrementar el contador del grupo correspondiente en array_contadores
    ; Cada contador es un entero de 4 bytes
    mov esi, [array_contadores + eax*4] ; Cargar el contador actual para ese grupo
    inc esi                             ; Incrementar el contador
    mov [array_contadores + eax*4], esi ; Guardar el nuevo valor

    inc rdi                           ; Siguiente nota
    jmp distribuir_loop

fin_distribuir:
    ; Al finalizar, array_contadores tendrá la cantidad de notas en cada grupo.





































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
