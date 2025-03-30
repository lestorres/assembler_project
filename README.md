## Organización de Registros x86_64  

| **64-bit (RAX)** | **32-bit (EAX)** | **16-bit (AX)** | **8-bit alto (AH)** | **8-bit bajo (AL)** | **Nombre**            | **Propósito**                                |
|------------------|------------------|-----------------|----------------------|----------------------|-----------------------|----------------------------------------------|
| RAX              | EAX              | AX              | AH                   | AL                   | Accumulator reg.      | Operaciones aritméticas                      |
| RCX              | ECX              | CX              | CH                   | CL                   | Counter reg.          | Contador                                     |
| RDX              | EDX              | DX              | DH                   | DL                   | Data reg.             | Operaciones aritméticas y E/S                |
| RBX              | EBX              | BX              | BH                   | BL                   | Base reg.             | Puntero                                      |
| RSP              | ESP              | SP              | —                    | —                    | Stack Pointer         | Puntero de pila                              |
| RBP              | EBP              | BP              | —                    | —                    | Stack Base Pointer    | Base de la pila                              |
| RSI              | ESI              | SI              | —                    | —                    | Source Index          | Puntero a fuente de datos                    |
| RDI              | EDI              | DI              | —                    | —                    | Destination Index     | Puntero a destino de datos                   |
