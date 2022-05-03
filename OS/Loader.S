LOADER_BASE_ADDR	equ 0x900
section loader vstart=LOADER_BASE_ADDR

cli                     ; 屏蔽中断

;打开A20
mov dx,92h
mov al,02
out dx,al

lgdt [gdt_descriptor]   ; 初始化GDT
 
; 把 cr0 的最低位置为 1，开启保护模式
mov eax, cr0
or eax, 0x1
mov cr0, eax
 
jmp 08h:PModeMain
 
[bits 32]
PModeMain:
    mov ax, 0x10        ; 将数据段寄存器ds和附加段寄存器es置为0x10
    mov ds, ax         
    mov es, ax
    mov fs, ax          ; fs和gs寄存器由操作系统使用，这里统一设成0x10
    mov gs, ax
    mov ax, 0x18        ; 将栈段寄存器ss置为0x18
    mov ss, ax
    mov ebp, 0x7c00     ; 现在栈顶指向 0x7c00
    mov esp, ebp
    jmp PModeTest
 
PModeTest:
    push TEST_STRING             ; 被打印字符的地址
    call print
PModePause:
    hlt
    jmp PModePause
 
; 打印字符串
; @param 被打印的字符串
print:
    push ebp
    mov ebp, esp
    mov ebx, [ebp+8]    ; [ebp+8]即传入的字符串参数
    xor ecx, ecx
    mov ah, 0x0f        ; ah为打印的颜色属性，0x0f为白字黑底
    mov edx, 0xb8000    ; 显存的地址
loop1_begin:
    mov al, [ebx]       ; al为被打印的字符
    cmp al, 0           ; 若al为0，结束打印
    je loop1_end
    mov [edx], ax       ; 向显存中写入字符及其颜色属性（2字节）
    inc ebx
    add edx, 2
    jmp loop1_begin
loop1_end:
    mov esp, ebp
    pop ebp
    ret
 
TEST_STRING db 'protected mode', 0
 
gdt_start:
; 第一个描述符必须是空描述符
gdt_null:
    dd 0
    dd 0
; 代码段描述符
gdt_code:
    dw 0xffff ; Limit (bits 0-15)
    dw 0x0 ; Base (bits 0-15)
    db 0x0 ; Base (bits 16-23)
    db 10011010b ; Access Byte
    db 11001111b ; Flags , Limit (bits 16-19)
    db 0x0 ; Base (bits 24-31)
; 数据段描述符
gdt_data:
    dw 0xffff ; Limit (bits 0-15)
    dw 0x0 ; Base (bits 0-15)
    db 0x0 ; Base (bits 16-23)
    db 10010010b ; Access Byte
    db 11001111b ; Flags , Limit (bits 16-19)
    db 0x0 ; Base (bits 24-31)
; 栈段描述符
gdt_stack:
    dw 0x7c00 ; Limit (bits 0-15)
    dw 0x0 ; Base (bits 0-15)
    db 0x0 ; Base (bits 16-23)
    db 10010010b ; Access Byte
    db 01000000b ; Flags , Limit (bits 16-19)
    db 0x0 ; Base (bits 24-31)
gdt_end:
 
; GDT descriptior
gdt_descriptor:
dw gdt_end - gdt_start - 1 ; Size of our GDT, always less one of the true size
dd gdt_start ; Start address of our GDT