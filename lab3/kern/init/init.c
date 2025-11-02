#include <clock.h>
#include <console.h>
#include <defs.h>
#include <intr.h>
#include <kdebug.h>
#include <kmonitor.h>
#include <pmm.h>
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <dtb.h>

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息
    memset(edata, 0, end - edata);
    dtb_init();

    cons_init();  // 初始化控制台
    const char *message = "(THU.CST) os is loading ...\0";
    cputs(message);

    print_kerninfo();

    idt_init();  // 初始化中断描述符表

    pmm_init();  // 初始化物理内存管理

    idt_init();  // 再次初始化中断描述符表（防止被覆盖）

    clock_init();   // 初始化时钟中断
    intr_enable();  // 开启中断

    while (1)
        ;
}


void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
    mon_backtrace(0, NULL, NULL);
}

void __attribute__((noinline)) grade_backtrace1(int arg0, int arg1) {
    grade_backtrace2(arg0, (uintptr_t)&arg0, arg1, (uintptr_t)&arg1);
}

void __attribute__((noinline)) grade_backtrace0(int arg0, int arg1, int arg2) {
    grade_backtrace1(arg0, arg2);
}

void grade_backtrace(void) { grade_backtrace0(0, (uintptr_t)kern_init, 0xffff0000); }

