; -------------------------------
; Definiciones de file descriptors estándar
; -------------------------------
%define STDIN  equ 0     ; Descritor de archivo estándar de entrada
%define STDOUT equ 1     ; Descritor de archivo estándar de salida
%define STDERR equ 2     ; Descritor de archivo estándar de error


; -------------------------------
; Llamadas al sistema (syscalls)
; -------------------------------
%define SYS_READ   0     ; Llamada al sistema para leer desde un archivo (leer bytes)
%define SYS_WRITE  1     ; Llamada al sistema para escribir en un archivo (escribir bytes)
%define SYS_OPEN   2     ; Llamada al sistema para abrir un archivo
%define SYS_CLOSE  3     ; Llamada al sistema para cerrar un archivo
%define SYS_EXIT   60    ; Llamada al sistema para terminar el programa
%define SYS_LSEEK  8    ; Llamada al sistema para mover el puntero de archivo (seek)


; -------------------------------
; Flags para abrir archivos
; -------------------------------
%define O_RDONLY  0     ; Solo lectura
%define O_WRONLY  1     ; Solo escritura
%define O_RDWR    2     ; Lectura y escritura
%define O_CREAT   64    ; Crear archivo si no existe
%define O_TRUNC   512   ; Truncar archivo si existe


; -------------------------------
; Definiciones de SEEK para el uso de SYS_LSEEK
; -------------------------------
%define SEEK_SET 0    ; Desde el inicio del archivo
%define SEEK_CUR 1    ; Desde la posición actual del archivo
%define SEEK_END 2    ; Desde el final del archivo
