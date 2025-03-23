section .bss
digitSpace resb 100
digitSpacePos resb 8
printSpace resb 8

; -------------------------------
; Macro para imprimir una cadena
; Uso: print cadena
; -------------------------------

%macro print 1
    mov rax, %1
    mov [printSpace], rax
    mov rbx, 0
%%printLoop:
    mov cl, [rax]
    cmp cl, 0
    je %%endPrintLoop
    inc rbx
    inc rax
    jmp %%printLoop
%%endPrintLoop:
    mov rax, 1       ; SYS_WRITE
    mov rdi, 1       ; STDOUT
    mov rsi, [printSpace]
    mov rdx, rbx
    syscall
%endmacro

; ------------------------------------
; Macro para imprimir un valor numérico
; Uso: printVal numero
; ------------------------------------
%macro printVal 1
    mov rax, %1
%%printRAX:
    mov rcx, digitSpace
    mov rbx, 10
    mov [rcx], rbx
    inc rcx
    mov [digitSpacePos], rcx
%%printRAXLoop:
    mov rdx, 0
    mov rbx, 10
    div rbx
    push rax
    add rdx, 48
    mov rcx, [digitSpacePos]
    mov [rcx], dl
    inc rcx
    mov [digitSpacePos], rcx
    pop rax
    cmp rax, 0
    jne %%printRAXLoop
%%printRAXLoop2:
    mov rcx, [digitSpacePos]
    mov rax, 1
    mov rdi, 1
    mov rsi, rcx
    mov rdx, 1
    syscall
    mov rcx, [digitSpacePos]
    dec rcx
    mov [digitSpacePos], rcx
    cmp rcx, digitSpace
    jge %%printRAXLoop2
%endmacro

; -------------------------------
; Macro para salir del programa
; Uso: exit
; -------------------------------
%macro exit 0
    mov rax, 60  ; SYS_EXIT
    mov rdi, 0
    syscall
%endmacro

