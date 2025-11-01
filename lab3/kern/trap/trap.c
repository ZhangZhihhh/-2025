#include <assert.h>
#include <clock.h>
#include <console.h>
#include <defs.h>
#include <kdebug.h>
#include <memlayout.h>
#include <mmu.h>
#include <riscv.h>
#include <sbi.h>
#include <stdio.h>
#include <trap.h>

#define TICK_NUM 100
#define MAX_PRINTS 10

static int timer_ticks = 0;    // 每次中断计数
static int timer_prints = 0;   // 打印次数

static void print_ticks() {
    cprintf("%d ticks\n", TICK_NUM);
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}

/* 初始化 IDT 和异常向量 */
void idt_init(void) {
    extern void __alltraps(void);
    write_csr(sscratch, 0);        // 内核模式标记
    write_csr(stvec, &__alltraps);
}

/* 判断 trap 是否在内核发生 */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
}

void print_trapframe(struct trapframe *tf) {
    cprintf("trapframe at %p\n", tf);
    print_regs(&tf->gpr);
    cprintf("  status   0x%08lx\n", tf->status);
    cprintf("  epc      0x%08lx\n", tf->epc);
    cprintf("  badvaddr 0x%08lx\n", tf->badvaddr);
    cprintf("  cause    0x%08lx\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    #define PRINT_REG(r) cprintf("  " #r "  0x%08lx\n", gpr->r)
    PRINT_REG(zero); PRINT_REG(ra); PRINT_REG(sp); PRINT_REG(gp); PRINT_REG(tp);
    PRINT_REG(t0); PRINT_REG(t1); PRINT_REG(t2); PRINT_REG(s0); PRINT_REG(s1);
    PRINT_REG(a0); PRINT_REG(a1); PRINT_REG(a2); PRINT_REG(a3); PRINT_REG(a4);
    PRINT_REG(a5); PRINT_REG(a6); PRINT_REG(a7);
    PRINT_REG(s2); PRINT_REG(s3); PRINT_REG(s4); PRINT_REG(s5); PRINT_REG(s6);
    PRINT_REG(s7); PRINT_REG(s8); PRINT_REG(s9); PRINT_REG(s10); PRINT_REG(s11);
    PRINT_REG(t3); PRINT_REG(t4); PRINT_REG(t5); PRINT_REG(t6);
    #undef PRINT_REG
}

/* 中断处理 */
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1; // 清除最高位
    switch (cause) {
        case IRQ_S_TIMER:
            // 设置下一次时钟中断
            clock_set_next_event();

            // 更新计数器
            timer_ticks++;

            // 每 TICK_NUM 次打印一次
            if (timer_ticks >= TICK_NUM) {
                timer_ticks = 0;
                print_ticks();
                timer_prints++;
                if (timer_prints >= MAX_PRINTS) {
                    sbi_shutdown();
                    while (1); // 防止返回
                }
            }
            break;

        case IRQ_U_SOFT: cprintf("User software interrupt\n"); break;
        case IRQ_S_SOFT: cprintf("Supervisor software interrupt\n"); break;
        case IRQ_H_SOFT: cprintf("Hypervisor software interrupt\n"); break;
        case IRQ_M_SOFT: cprintf("Machine software interrupt\n"); break;
        case IRQ_U_TIMER: cprintf("User timer interrupt\n"); break;
        case IRQ_H_TIMER: cprintf("Hypervisor timer interrupt\n"); break;
        case IRQ_M_TIMER: cprintf("Machine timer interrupt\n"); break;
        case IRQ_U_EXT: cprintf("User external interrupt\n"); break;
        case IRQ_S_EXT: cprintf("Supervisor external interrupt\n"); break;
        case IRQ_H_EXT: cprintf("Hypervisor external interrupt\n"); break;
        case IRQ_M_EXT: cprintf("Machine external interrupt\n"); break;

        default:
            print_trapframe(tf);
            break;
    }
}

/* 异常处理 */
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        case CAUSE_ILLEGAL_INSTRUCTION:
            cprintf("Illegal instruction at 0x%08lx\n", tf->epc);
            tf->epc += 4; // 跳过非法指令
            break;
        case CAUSE_BREAKPOINT:
            cprintf("Breakpoint at 0x%08lx\n", tf->epc);
            tf->epc += 4; // 跳过断点
            break;
        default:
            print_trapframe(tf);
            break;
    }
}

/* 分发 trap */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0)
        interrupt_handler(tf);
    else
        exception_handler(tf);
}

/* trap 入口 */
void trap(struct trapframe *tf) {
    trap_dispatch(tf);
}
