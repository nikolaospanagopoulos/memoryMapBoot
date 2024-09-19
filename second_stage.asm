org 0x7E00


mov ax, 0x0000
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00  ; 0x0000:0x7c00 (0x0000 * 16) + 0x7c00 
;stack grows downwards so (0x7c00) => (31744 / 1024) = 31kb

mmap_ent equ 0x0500

call display_memory_map

jmp $

display_memory_map:
    call do_e820
    mov si, memory_map_str
    call print_string
    mov di, 0x0504
    mov cx, [mmap_ent]
print_entries:
    cmp cx, 0
    je end_display
    mov si, base_address_str
    call print_string
    mov eax, [es:di + 4]     ; Print Base Address (upper 32 bits)
    call print_hex
    mov eax, [es:di]         ; Print Base Address (lower 32 bits)
    call print_hex

    mov si, length_of_region_str
    call print_string
    mov eax, [es:di + 12]    ; Print Length (upper 32 bits)
    call print_hex
    mov eax, [es:di + 8]     ; Print Length (lower 32 bits)
    call print_hex

    mov si, type_str
    call print_string
    mov eax, [es:di + 16]    ; Print Type
    call print_hex

    add di, 24
    dec cx
    jmp print_entries
end_display:
    jmp $

do_e820:
    pusha
    ; STEPS before using int 0x15
    mov di, 0x0504           ; Set di to 0x8004 Otherwise this code will get stuck in `int 0x15` after some entries are fetched 
    xor ebx, ebx             ; ebx must be 0 to start
    xor bp, bp               ; keep an entry count in bp | make it 0
    mov edx, 0x534D4150      ; Place "SMAP" into edx | The "SMAP" signature ensures that the BIOS provides the correct memory map format
    mov eax, 0xe820          ; Function to get memory map
    mov dword [es:di + 20], 1 ; force a valid ACPI 3.X entry | allows us to get additional information (extended attributes)
    mov ecx, 24              ; ask for 24 bytes | size of buffer for result | we want 24 to get ACPI 3.X entry with extra information
    int 0x15                 ; using interrupt
    jc short .failed         ; carry set on first call means "unsupported function"
    mov edx, 0x534D4150      ; Some BIOSes apparently trash this register? lets set it again
    cmp eax, edx             ; on success, eax must have been reset to "SMAP"
    jne short .failed
    test ebx, ebx            ; ebx = 0 implies list is only 1 entry long (worthless)
    je short .failed
    jmp short .jmpin
.e820lp:
    mov eax, 0xe820          ; eax, ecx get trashed on every int 0x15 call
    mov dword [es:di + 20], 1 ; force a valid ACPI 3.X entry
    mov ecx, 24              ; ask for 24 bytes again
    int 0x15
    jc short .e820f          ; carry set means "end of list already reached"
    mov edx, 0x534D4150      ; repair potentially trashed register
.jmpin:
    jcxz .skipent            ; skip any 0 length entries (If ecx is zero, skip this entry (indicates an invalid entry length))
    cmp cl, 20               ; got a 24 byte ACPI 3.X response?
    jbe short .notext
    test byte [es:di + 20], 1 ;if bit 0 is clear, the entry should be ignored
    je short .skipent         ; jump if bit 0 is clear 
.notext:
    mov eax, [es:di + 8]     ; get lower uint32_t of memory region length
    or eax, [es:di + 12]     ; "or" it with upper uint32_t to test for zero and form 64 bits (little endian)
    jz .skipent              ; if length uint64_t is 0, skip entry
    inc bp                   ; got a good entry: ++count, move to next storage spot
    add di, 24               ; move next entry into buffer
.skipent:
    test ebx, ebx            ; if ebx resets to 0, list is complete
    jne short .e820lp
.e820f:
    mov [mmap_ent], bp       ; store the entry count
    clc                      ; there is "jc" on end of list to this point, so the carry must be cleared

    popa
    ret
.failed:
    stc                      ; "function unsupported" error exit
    ret
;print 32 bit hexadecimal values
print_hex:
    pusha                  ; Save all registers

    mov ecx, 8             ; We will print 8 hex digits (32 bits)
    mov ebx, eax           ; Copy the value to be printed into ebx

print_hex_loop:
    rol ebx, 4             ; Rotate left to bring the next nibble to the lowest 4 bits
    mov al, bl             ; Get the lowest 4 bits
    and al, 0x0F           ; Mask out everything except the lowest 4 bits
    cmp al, 10
    jl print_digit         ; If al < 10, it's a number
    add al, 'A' - 10       ; Convert 10-15 to 'A'-'F'
    jmp print_hex_digit
print_digit:
    add al, '0'            ; Convert 0-9 to '0'-'9'

print_hex_digit:
    mov ah, 0x0E           ; BIOS teletype function
    int 0x10               ; BIOS interrupt to print character
    loop print_hex_loop    ; Loop until all digits are printed

    popa                   ; Restore all registers
    ret

print_string:
	call print
	ret
print:
.loop:  
	lodsb   ;read character to al and then increment
	cmp al ,0 ;check if we reached the end
	je .done  ;we reached null terminator, finish
	call print_char ;print character
	jmp .loop   ;jump back into the loop
.done:
	ret
print_char:
	mov ah, 0eh
	int 0x10
	ret


buffer: db 12 dup(0), 0xA, 0xD, 0
menu_str: db 0xA, 0xD, 'M) display memory map', 0xA, 0xD, 'C) Do checks', 0xA, 0xD, 'D) end program', 0xA, 0xD, 'P) Enter into protected mode',0xA,0xD,0
base_address_str: db 'Base Address: ', 0
length_of_region_str: db ' Length of region: ', 0
new_line_str: db 0xA, 0xD, 0
type_str: db ' Type: ', 0
memory_map_str: db 0xA, 0xD, "Memory Map:", 0xA, 0xD, 0
empty_command_str: db ''

times 2560 - ($-$$) db 0

