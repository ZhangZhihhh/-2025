#include <mmu.h>
#include <memlayout.h>

    .section .text.entry,"ax",%progbits
    .globl kern_entry
kern_entry:
    # We are loaded at 0x80200000 but linked at 0xFFFFFFFFC0200000
    # First, compute the offset between link address and load address
    # This lets us access data before paging is enabled
    
    # a0 = hartid, a1 = dtb (from OpenSBI)
    # We need to save these before enabling paging
    # Compute physical address of boot_hartid
    # Method: get link VA, subtract 0xFFFFFFFF40000000
    
    lui t0, %hi(boot_hartid)
    addi t0, t0, %lo(boot_hartid)
    li t1, 0x40000000
    li t2, -1
    slli t2, t2, 32
    add t1, t1, t2          # t1 = 0xFFFFFFFF40000000
    sub t0, t0, t1          # t0 = PA of boot_hartid
    sd a0, 0(t0)            # Save hartid
    
    # Save dtb - also use physical address
    lui t0, %hi(boot_dtb)
    addi t0, t0, %lo(boot_dtb)
    li t1, 0x40000000
    li t2, -1
    slli t2, t2, 32
    add t1, t1, t2          # t1 = 0xFFFFFFFF40000000
    sub t0, t0, t1          # t0 = PA of boot_dtb
    sd a1, 0(t0)            # Save dtb
    
    # Now set up paging
    # Compute PA of boot_page_table_sv39
    lui t0, %hi(boot_page_table_sv39)
    addi t0, t0, %lo(boot_page_table_sv39)
    sub t0, t0, t1          # t0 = PA of page table
    
    # Set up satp
    srli t0, t0, 12         # PPN  
    li t1, 8
    slli t1, t1, 60         # Sv39 mode
    or t0, t0, t1
    csrw satp, t0
    sfence.vma
    
    # After enabling paging, PC is still at physical ~0x80200xxx
    # This is OK because VPN[2]=2 provides identity mapping
    
    # Now jump to virtual address
    # Use absolute load to ensure correct address
    la t0, va_start
    jr t0

.align 2
va_start:
    # Now at virtual address space
    la sp, bootstacktop
    tail kern_init

.section .data
    # .align 2^12
    .align PGSHIFT
    .global bootstack
bootstack:
    .space KSTACKSIZE
    .global bootstacktop
bootstacktop:

    # 由于我们要把这个页表放到一个页里面，因此必须 12 位对齐
    .align PGSHIFT
    .global boot_page_table_sv39
# 分配 4KiB 内存给预设的三级页表
boot_page_table_sv39:
    # 0x00000000_80000000 map to 0x00000000_80000000 (1G)
    # PTE: (0x80000 << 10) | 0xcf
    # Entry 2: VPN[2] = 2 for address 0x80000000
    .quad 0
    .quad 0
    .quad (0x80000 << 10) | 0xcf # VPN[2] = 2: 0x80000000 -> 0x80000000
    .zero 8 * 508
    
    # 0xFFFFFFFFC0000000 map to 0x00000000_80000000 (1G)  
    # VPN[2] = 511 (0x1FF) for kernel high address
    .quad (0x80000 << 10) | 0xcf # VPN[2] = 511: kernel space

# Put boot parameters in a separate section to preserve them across memset
.section .data.boot_params
    .align 3  # 8-byte alignment
    .global boot_hartid
boot_hartid:
    .quad 0
    .global boot_dtb
boot_dtb:
    .quad 0
    # 设置最后一个页表项，0xffffffff_c0000000 map to 0x80000000 (1G)
    .quad (0x80000 << 10) | 0xcf # VRWXAD