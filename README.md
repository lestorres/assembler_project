# Descripción General del proyecto

## Programa en Ensamblador x86_64
Este programa fue desarrollado en lenguaje ensamblador x86_64, utilizando el ensamblador NASM y ejecutándose sobre el sistema operativo Linux.  

Para el análisis y depuración del código, se empleó **GDB (GNU Debugger)**, lo que permitió inspeccionar el estado de los registros, la memoria y el flujo de ejecución.  

## Funcionalidades implementadas

- Lectura y recuperación del contenido de archivos de texto.
- Ordenamiento de datos utilizando los algoritmos **Bubblesort** y **Selection-sort**.
- Bosquejo General de un histograma

## Organización de Archivos

### Directiorio: proyecto
- En este directorio se encuentran todo el codigo fuente y las dependencias necesarias para la ejecución del proyecto

### Directiorio: flujo_trabajo
- En este directorio se encuentran todo el codigo fuente y las dependencia necesarias para la ejecución de distintas etapas en el desarrollo del proyecto, entre ellas: la lectura de los archivos, la impresión por pantalla, los ordenamientos, entre otros.


## Anexos
### Organización de Registros x86_64  

| **64-bit** | **32-bit** | **16-bit** | **8-bit alto** | **8-bit bajo** | **Nombre**            | **Propósito**                                |
|------------------|------------------|-----------------|----------------------|----------------------|-----------------------|----------------------------------------------|
| RAX              | EAX              | AX              | AH                   | AL                   | Accumulator reg.      | Operaciones aritméticas                      |
| RCX              | ECX              | CX              | CH                   | CL                   | Counter reg.          | Contador                                     |
| RDX              | EDX              | DX              | DH                   | DL                   | Data reg.             | Operaciones aritméticas y E/S                |
| RBX              | EBX              | BX              | BH                   | BL                   | Base reg.             | Puntero                                      |
| RSP              | ESP              | SP              | —                    | —                    | Stack Pointer         | Puntero de pila                              |
| RBP              | EBP              | BP              | —                    | —                    | Stack Base Pointer    | Base de la pila                              |
| RSI              | ESI              | SI              | —                    | —                    | Source Index          | Puntero a fuente de datos                    |
| RDI              | EDI              | DI              | —                    | —                    | Destination Index     | Puntero a destino de datos                   |
