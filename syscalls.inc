; syscalls.inc - Definiciones de llamadas al sistema y flags de apertura de archivos

; -------------------------------
; Definiciones de file descriptors estándar
; -------------------------------
%define STDIN  equ 0
%define STDOUT equ 1
%define STDERR equ 2


; -------------------------------
; Llamadas al sistema (syscalls)
; -------------------------------
%define SYS_READ   0
%define SYS_WRITE  1
%define SYS_OPEN   2
%define SYS_CLOSE  3
%define SYS_EXIT   60

; -------------------------------
; Flags para abrir archivos
; -------------------------------
%define O_RDONLY  0    ; Solo lectura
%define O_WRONLY  1    ; Solo escritura
%define O_RDWR    2    ; Lectura y escritura
%define O_CREAT   64   ; Crear archivo si no existe
%define O_TRUNC   512  ; Truncar archivo si existe
