;Recuperar datos, ordenarlos y listarlos 
;Lesmes Torres Gonzalez

;-----------------------------------
;Seccion de paquetes
%include "Linux64.inc"    ;Operaciones de impresion y cierra de archivo 
%include "syscalls.inc" ;Compilacion de llamadas al sistema 

; Sección de datos inicializados
section .data
	 
	
    	archivo_config db "configuracion.txt", 0
    	archivo_datos db "datos.txt", 0
	
	;Mensajes del sistema		
	msg_inicio_programa db "---Programa Iniciado---", 0xA, 0
	msg_config_open db "---Inicio de la configuración---", 0xA, 0
	msg_lista_des_open db "---Inicio de la lista desordenada---", 0xA, 0
	msg_lista_orden_open db "---Inicio de la lista ordenada---", 0xA, 0
        msg_histo_open db "---Inicio del histograma---", 0xA, 0
	msg_final_programa db "---Programa Terminado---", 0xA, 0


	;Variable de busqueda para la notas en ordenamiento
	nota_buscada db "nota: "

; Sección de datos no inicializados
section .bss
    	leer_texto_config resb 154 ; variable para leer configuracion.txt   
	leer_texto_datos resb 2048 ; Variable para leer datos en datos.txt   
	
	

; Variables de recuperación
   	nota_apro resb 3
    	nota_repo resb 3
    	tam_grupo resb 3
    	escala resb 3
    	orden resb 1

	lista_estudiantes resb 2400

;Variables del ordenamiento por notas
	estudiantes resb 2048  	;Espacio para las lineas de estudiantes 
	notas resb 12	       	;Espacio para la nota como entero
	lineas_count resb 1	;Cuenta lineas
	nota_str resb 4		;espacio para nota como string
	temp_line resb 128	;Espacio temporal de 1 estudiante+nota
	
	student_struc resb 2048 ;Estructura para almacenar estudiantes+notas
	idx resb 1		;Indice de la linea
	line_offset resb 4	;Puntero temporal para iterar en el arreglo estudiantes


; Sección de código
section .text
    	global _start

_start:

	print msg_inicio_programa

;---------------------leer_Configuracion------------------ 
fetch_configuracion:
; Abrir archivo configuracion.txt
    	mov rax, SYS_OPEN    ; Llamada al sistema para abrir el archivo
    	mov rdi, archivo_config ; Nombre del archivo
    	mov rsi, O_RDONLY    ; Solo lectura
    	mov rdx, 0           ; No flags adicionales
    	syscall

; Verificación de apertura del archivo
    	test rax, rax        ; Verificar si la apertura fue exitosa
    	js  salida_error     ; Salir si hubo un error
    	mov rbx, rax         ; Guardar descriptor del archivo

lectura_texto_config:
    	mov rdi, rbx                  ; Cargar el descriptor del archivo
    	mov rax, SYS_READ             ; Llamada para leer
    	mov rsi, leer_texto_config    ; Dirección de la variable para leer
    	mov rdx, 154                   ; Leer 30 bytes
	 syscall                       ; Realizar la lectura

; Verificación de lectura de bytes si no hay cierra el archivo
    	test rax, rax        	    ; Verificar si se leyeron bytes
    	jz  cerrar_archivo_config   ; Salir si no se leyeron bytes (fin de archivo)
     
;capturar_str_config
	mov rsi, leer_texto_config ; cargo los bytes leídos de la linea


;-----------Recuperar datos--------------------
    
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

;------------------mostrar la configuracion------------------------

	print msg_config_open
impresion_config:
    	mov rax, SYS_WRITE               ; syscall number para write
    	mov rdi, 1                 ; Descriptor de salida (stdout)
    	mov rsi, leer_texto_config ; Dirección del mensaje
    	mov rdx, 154                ; Longitud del mensaje
    	syscall                    ; Llamada al sistema

cerrar_archivo_config:
    	mov rdi, rbx         ; Cargar descriptor del archivo
    	mov rax, SYS_CLOSE   ; Llamada para cerrar el archivo
    	syscall



;LISTAR LOS ESTUDIANTES
;------------------------------------------------------------
fetch_lista_de_datos:
; Abrir el archivo
    	mov rax, SYS_OPEN
    	mov rdi, archivo_datos
    	mov rsi, O_RDONLY  ; Solo lectura
    	mov rdx, 0         ; No flags adicionales
    	syscall

    	test rax, rax   ;Revisar si se logró leer
    	js salida_error

    	mov rbx, rax  ; Guardar descriptor del archivo

    ; Leer las líneas del archivo
lectura_lista:

;Leer lineas
    	mov rax, SYS_READ        ; Llamada para leer
    	mov rdi, rbx             ; Descriptor del archivo
   	mov rsi, leer_texto_datos      ; Dirección del buffer
    	mov rdx, 2048            ; Leer hasta 248 bytes
    	syscall
	
	print msg_lista_des_open ; imprime mensaje guía   
    	print leer_texto_datos	 ;imprime la lista de datos desordenada

cerrar_archivo_datos:
    	mov rdi, rbx         ; Cargar descriptor del archivo
    	mov rax, SYS_CLOSE   ; Llamada para cerrar el archivo
    	syscall

;Estructurar lista









;-------------Ordenamiento--------------
ordenamiento:
    	print msg_lista_orden_open    


histograma:
;---histrograma----
;    	print msg_histo_open


terminar:

    	; Salir del programa
    	print msg_final_programa    
    	mov rax, SYS_EXIT
    	xor rdi, rdi         ; Código de salida 0
    	syscall
    
salida_error:
    	; Manejo de error de apertura de archivo
    	mov rax, SYS_EXIT
    	mov rdi, 1           ; Código de salida 1 (error)
    	syscall
