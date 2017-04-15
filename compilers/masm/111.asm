    include \masm32\include\masm32rt.inc

    .data

in_format db "%d %d", 0
out_format db "%d", 0
bytes_read dd 1
var_a dd 1
var_b dd 1
buffer db 128 dup(?)

    .code
    
start:
        invoke GetStdHandle, STD_INPUT_HANDLE
        invoke ReadFile, EAX, ADDR buffer, 128, ADDR bytes_read, 0
        invoke crt_sscanf, ADDR buffer, ADDR in_format, ADDR var_a, ADDR var_b
        mov eax, var_a        
        add eax, var_b
        invoke crt_sprintf, ADDR buffer, ADDR out_format, eax
        print ADDR buffer
        exit
   
end start
