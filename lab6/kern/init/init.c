#include <defs.h>
#include <stdio.h>
#include <string.h>
#include <console.h>
#include <kdebug.h>
#include <picirq.h>
#include <trap.h>
#include <clock.h>
#include <intr.h>
#include <pmm.h>
#include <dtb.h>
#include <vmm.h>
#include <proc.h>
#include <kmonitor.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void)
{
    extern uint64_t boot_hartid, boot_dtb;
    // Save boot parameters before memset clears BSS
    uint64_t saved_hartid = boot_hartid;
    uint64_t saved_dtb = boot_dtb;
    
    extern char edata[], end[];
    memset(edata, 0, end - edata);
    
    // Restore boot parameters
    boot_hartid = saved_hartid;
    boot_dtb = saved_dtb;
    
    cons_init(); // init the console

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);

    print_kerninfo();

    // grade_backtrace();

    dtb_init(); // init dtb

    pmm_init(); // init physical memory management

    pic_init(); // init interrupt controller
    idt_init(); // init interrupt descriptor table

    vmm_init(); // init virtual memory management
    sched_init();
    proc_init(); // init process table

    clock_init();  // init clock interrupt
    intr_enable(); // enable irq interrupt

    cpu_idle(); // run idle process
}
