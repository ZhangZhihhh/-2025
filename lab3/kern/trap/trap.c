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
    /*LAB3 2313411*/
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
            /*LAB3 2313411*/
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

        case CAUSE_MISALIGNED_FETCH:
            // 指令地址未对齐异常
            cprintf("Misaligned instruction fetch at 0x%08lx\n", tf->epc);
            cprintf("Exception type: misaligned instruction fetch\n");
            tf->epc += 4;
            break;

        case CAUSE_FAULT_FETCH:
            // 指令取指异常（访问非法地址）
            cprintf("Instruction access fault at 0x%08lx\n", tf->epc);
            cprintf("Exception type: Instruction access fault\n");
            tf->epc += 4;
            break;

        case CAUSE_ILLEGAL_INSTRUCTION:
            // 非法指令异常
            /*LAB3 2313411*/
            cprintf("Illegal instruction caught at 0x%08lx\n", tf->epc);
            cprintf("Exception type: Illegal instruction\n");
            tf->epc += 4;  // 跳过非法指令，防止死循环
            break;

        case CAUSE_BREAKPOINT:
            // 断点异常
            /*LAB3 2313411*/
            cprintf("ebreak caught at 0x%08lx\n", tf->epc);
            cprintf("Exception type: breakpoint\n");
            tf->epc += 2;  // 跳过断点指令
            break;


        case CAUSE_MISALIGNED_LOAD:
            // 加载地址未对齐
            cprintf("Misaligned load at 0x%08lx\n", tf->epc);
            cprintf("Exception type: misaligned load\n");
            tf->epc += 4;
            break;

        case CAUSE_FAULT_LOAD:
            // 加载访问异常
            cprintf("Load access fault at 0x%08lx\n", tf->epc);
            cprintf("Exception type: Load access fault\n");
            tf->epc += 4;
            break;

        case CAUSE_MISALIGNED_STORE:
            // 存储地址未对齐
            cprintf("Misaligned store at 0x%08lx\n", tf->epc);
            cprintf("Exception type: misaligned store\n");
            tf->epc += 4;
            break;

        case CAUSE_FAULT_STORE:
            // 存储访问异常
            cprintf("Store access fault at 0x%08lx\n", tf->epc);
            cprintf("Exception type: Store access fault\n");
            tf->epc += 4;
            break;

        case CAUSE_USER_ECALL:
            // 用户态系统调用
            cprintf("User ECALL at 0x%08lx\n", tf->epc);
            cprintf("Exception type: User ECALL\n");
            tf->epc += 4;
            break;

        case CAUSE_SUPERVISOR_ECALL:
            // S 模式系统调用
            cprintf("Supervisor ECALL at 0x%08lx\n", tf->epc);
            cprintf("Exception type: Supervisor ECALL\n");
            tf->epc += 4;
            break;

        case CAUSE_HYPERVISOR_ECALL:
            // H 模式系统调用（通常未实现）
            cprintf("Hypervisor ECALL at 0x%08lx\n", tf->epc);
            cprintf("Exception type: Hypervisor ECALL\n");
            tf->epc += 4;
            break;

        case CAUSE_MACHINE_ECALL:
            // M 模式系统调用
            cprintf("Machine ECALL at 0x%08lx\n", tf->epc);
            cprintf("Exception type: Machine ECALL\n");
            tf->epc += 4;
            break;

        default:
            // 其他未知异常类型
            print_trapframe(tf);
            cprintf("Unknown exception type: %ld\n", tf->cause);
            tf->epc += 4;
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
