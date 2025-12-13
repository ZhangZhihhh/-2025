
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0206337          	lui	t1,0xc0206
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息
    memset(edata, 0, end - edata);
ffffffffc0200054:	00007517          	auipc	a0,0x7
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0207028 <free_area>
ffffffffc020005c:	00007617          	auipc	a2,0x7
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02074a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	116020ef          	jal	ra,ffffffffc0202182 <memset>
    dtb_init();
ffffffffc0200070:	444000ef          	jal	ra,ffffffffc02004b4 <dtb_init>

    cons_init();  // 初始化控制台
ffffffffc0200074:	432000ef          	jal	ra,ffffffffc02004a6 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	1d850513          	addi	a0,a0,472 # ffffffffc0202250 <etext+0xbc>
ffffffffc0200080:	0c6000ef          	jal	ra,ffffffffc0200146 <cputs>

    print_kerninfo();
ffffffffc0200084:	112000ef          	jal	ra,ffffffffc0200196 <print_kerninfo>

    idt_init();  // 初始化中断描述符表
ffffffffc0200088:	7e8000ef          	jal	ra,ffffffffc0200870 <idt_init>

    pmm_init();  // 初始化物理内存管理
ffffffffc020008c:	17b010ef          	jal	ra,ffffffffc0201a06 <pmm_init>

    idt_init();  // 再次初始化中断描述符表（防止被覆盖）
ffffffffc0200090:	7e0000ef          	jal	ra,ffffffffc0200870 <idt_init>

    clock_init();   // 初始化时钟中断
ffffffffc0200094:	3d0000ef          	jal	ra,ffffffffc0200464 <clock_init>
    intr_enable();  // 开启中断
ffffffffc0200098:	7cc000ef          	jal	ra,ffffffffc0200864 <intr_enable>
     /* ------------------- Challenge 3 验证代码开始 ------------------- */
    cprintf("\n=== Challenge 3: Testing Exception Handling ===\n");
ffffffffc020009c:	00002517          	auipc	a0,0x2
ffffffffc02000a0:	0fc50513          	addi	a0,a0,252 # ffffffffc0202198 <etext+0x4>
ffffffffc02000a4:	06a000ef          	jal	ra,ffffffffc020010e <cprintf>

    // 测试非法指令异常
    cprintf("Testing illegal instruction exception...\n");
ffffffffc02000a8:	00002517          	auipc	a0,0x2
ffffffffc02000ac:	12850513          	addi	a0,a0,296 # ffffffffc02021d0 <etext+0x3c>
ffffffffc02000b0:	05e000ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02000b4:	0000                	unimp
ffffffffc02000b6:	0000                	unimp
    asm volatile(".word 0x00000000");   // 强制执行非法指令

    // 测试断点异常
    cprintf("Testing breakpoint exception...\n");
ffffffffc02000b8:	00002517          	auipc	a0,0x2
ffffffffc02000bc:	14850513          	addi	a0,a0,328 # ffffffffc0202200 <etext+0x6c>
ffffffffc02000c0:	04e000ef          	jal	ra,ffffffffc020010e <cprintf>
    asm volatile("ebreak");             // 执行断点指令
ffffffffc02000c4:	9002                	ebreak

    cprintf("=== Challenge 3: Tests Finished ===\n\n");
ffffffffc02000c6:	00002517          	auipc	a0,0x2
ffffffffc02000ca:	16250513          	addi	a0,a0,354 # ffffffffc0202228 <etext+0x94>
ffffffffc02000ce:	040000ef          	jal	ra,ffffffffc020010e <cprintf>
    /* ------------------- Challenge 3 验证代码结束 ------------------- */

    while (1)
ffffffffc02000d2:	a001                	j	ffffffffc02000d2 <kern_init+0x7e>

ffffffffc02000d4 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000d4:	1141                	addi	sp,sp,-16
ffffffffc02000d6:	e022                	sd	s0,0(sp)
ffffffffc02000d8:	e406                	sd	ra,8(sp)
ffffffffc02000da:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000dc:	3cc000ef          	jal	ra,ffffffffc02004a8 <cons_putc>
    (*cnt) ++;
ffffffffc02000e0:	401c                	lw	a5,0(s0)
}
ffffffffc02000e2:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000e4:	2785                	addiw	a5,a5,1
ffffffffc02000e6:	c01c                	sw	a5,0(s0)
}
ffffffffc02000e8:	6402                	ld	s0,0(sp)
ffffffffc02000ea:	0141                	addi	sp,sp,16
ffffffffc02000ec:	8082                	ret

ffffffffc02000ee <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ee:	1101                	addi	sp,sp,-32
ffffffffc02000f0:	862a                	mv	a2,a0
ffffffffc02000f2:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f4:	00000517          	auipc	a0,0x0
ffffffffc02000f8:	fe050513          	addi	a0,a0,-32 # ffffffffc02000d4 <cputch>
ffffffffc02000fc:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000fe:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200100:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200102:	351010ef          	jal	ra,ffffffffc0201c52 <vprintfmt>
    return cnt;
}
ffffffffc0200106:	60e2                	ld	ra,24(sp)
ffffffffc0200108:	4532                	lw	a0,12(sp)
ffffffffc020010a:	6105                	addi	sp,sp,32
ffffffffc020010c:	8082                	ret

ffffffffc020010e <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020010e:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200110:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200114:	8e2a                	mv	t3,a0
ffffffffc0200116:	f42e                	sd	a1,40(sp)
ffffffffc0200118:	f832                	sd	a2,48(sp)
ffffffffc020011a:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020011c:	00000517          	auipc	a0,0x0
ffffffffc0200120:	fb850513          	addi	a0,a0,-72 # ffffffffc02000d4 <cputch>
ffffffffc0200124:	004c                	addi	a1,sp,4
ffffffffc0200126:	869a                	mv	a3,t1
ffffffffc0200128:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020012a:	ec06                	sd	ra,24(sp)
ffffffffc020012c:	e0ba                	sd	a4,64(sp)
ffffffffc020012e:	e4be                	sd	a5,72(sp)
ffffffffc0200130:	e8c2                	sd	a6,80(sp)
ffffffffc0200132:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200134:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200136:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200138:	31b010ef          	jal	ra,ffffffffc0201c52 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020013c:	60e2                	ld	ra,24(sp)
ffffffffc020013e:	4512                	lw	a0,4(sp)
ffffffffc0200140:	6125                	addi	sp,sp,96
ffffffffc0200142:	8082                	ret

ffffffffc0200144 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200144:	a695                	j	ffffffffc02004a8 <cons_putc>

ffffffffc0200146 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200146:	1101                	addi	sp,sp,-32
ffffffffc0200148:	e822                	sd	s0,16(sp)
ffffffffc020014a:	ec06                	sd	ra,24(sp)
ffffffffc020014c:	e426                	sd	s1,8(sp)
ffffffffc020014e:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200150:	00054503          	lbu	a0,0(a0)
ffffffffc0200154:	c51d                	beqz	a0,ffffffffc0200182 <cputs+0x3c>
ffffffffc0200156:	0405                	addi	s0,s0,1
ffffffffc0200158:	4485                	li	s1,1
ffffffffc020015a:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020015c:	34c000ef          	jal	ra,ffffffffc02004a8 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200160:	00044503          	lbu	a0,0(s0)
ffffffffc0200164:	008487bb          	addw	a5,s1,s0
ffffffffc0200168:	0405                	addi	s0,s0,1
ffffffffc020016a:	f96d                	bnez	a0,ffffffffc020015c <cputs+0x16>
    (*cnt) ++;
ffffffffc020016c:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200170:	4529                	li	a0,10
ffffffffc0200172:	336000ef          	jal	ra,ffffffffc02004a8 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200176:	60e2                	ld	ra,24(sp)
ffffffffc0200178:	8522                	mv	a0,s0
ffffffffc020017a:	6442                	ld	s0,16(sp)
ffffffffc020017c:	64a2                	ld	s1,8(sp)
ffffffffc020017e:	6105                	addi	sp,sp,32
ffffffffc0200180:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200182:	4405                	li	s0,1
ffffffffc0200184:	b7f5                	j	ffffffffc0200170 <cputs+0x2a>

ffffffffc0200186 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200186:	1141                	addi	sp,sp,-16
ffffffffc0200188:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020018a:	326000ef          	jal	ra,ffffffffc02004b0 <cons_getc>
ffffffffc020018e:	dd75                	beqz	a0,ffffffffc020018a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200190:	60a2                	ld	ra,8(sp)
ffffffffc0200192:	0141                	addi	sp,sp,16
ffffffffc0200194:	8082                	ret

ffffffffc0200196 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200196:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200198:	00002517          	auipc	a0,0x2
ffffffffc020019c:	0d850513          	addi	a0,a0,216 # ffffffffc0202270 <etext+0xdc>
void print_kerninfo(void) {
ffffffffc02001a0:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001a2:	f6dff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001a6:	00000597          	auipc	a1,0x0
ffffffffc02001aa:	eae58593          	addi	a1,a1,-338 # ffffffffc0200054 <kern_init>
ffffffffc02001ae:	00002517          	auipc	a0,0x2
ffffffffc02001b2:	0e250513          	addi	a0,a0,226 # ffffffffc0202290 <etext+0xfc>
ffffffffc02001b6:	f59ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001ba:	00002597          	auipc	a1,0x2
ffffffffc02001be:	fda58593          	addi	a1,a1,-38 # ffffffffc0202194 <etext>
ffffffffc02001c2:	00002517          	auipc	a0,0x2
ffffffffc02001c6:	0ee50513          	addi	a0,a0,238 # ffffffffc02022b0 <etext+0x11c>
ffffffffc02001ca:	f45ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001ce:	00007597          	auipc	a1,0x7
ffffffffc02001d2:	e5a58593          	addi	a1,a1,-422 # ffffffffc0207028 <free_area>
ffffffffc02001d6:	00002517          	auipc	a0,0x2
ffffffffc02001da:	0fa50513          	addi	a0,a0,250 # ffffffffc02022d0 <etext+0x13c>
ffffffffc02001de:	f31ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001e2:	00007597          	auipc	a1,0x7
ffffffffc02001e6:	2be58593          	addi	a1,a1,702 # ffffffffc02074a0 <end>
ffffffffc02001ea:	00002517          	auipc	a0,0x2
ffffffffc02001ee:	10650513          	addi	a0,a0,262 # ffffffffc02022f0 <etext+0x15c>
ffffffffc02001f2:	f1dff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001f6:	00007597          	auipc	a1,0x7
ffffffffc02001fa:	6a958593          	addi	a1,a1,1705 # ffffffffc020789f <end+0x3ff>
ffffffffc02001fe:	00000797          	auipc	a5,0x0
ffffffffc0200202:	e5678793          	addi	a5,a5,-426 # ffffffffc0200054 <kern_init>
ffffffffc0200206:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020020a:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020020e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200210:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200214:	95be                	add	a1,a1,a5
ffffffffc0200216:	85a9                	srai	a1,a1,0xa
ffffffffc0200218:	00002517          	auipc	a0,0x2
ffffffffc020021c:	0f850513          	addi	a0,a0,248 # ffffffffc0202310 <etext+0x17c>
}
ffffffffc0200220:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200222:	b5f5                	j	ffffffffc020010e <cprintf>

ffffffffc0200224 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200224:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	11a60613          	addi	a2,a2,282 # ffffffffc0202340 <etext+0x1ac>
ffffffffc020022e:	04d00593          	li	a1,77
ffffffffc0200232:	00002517          	auipc	a0,0x2
ffffffffc0200236:	12650513          	addi	a0,a0,294 # ffffffffc0202358 <etext+0x1c4>
void print_stackframe(void) {
ffffffffc020023a:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020023c:	1cc000ef          	jal	ra,ffffffffc0200408 <__panic>

ffffffffc0200240 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200240:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200242:	00002617          	auipc	a2,0x2
ffffffffc0200246:	12e60613          	addi	a2,a2,302 # ffffffffc0202370 <etext+0x1dc>
ffffffffc020024a:	00002597          	auipc	a1,0x2
ffffffffc020024e:	14658593          	addi	a1,a1,326 # ffffffffc0202390 <etext+0x1fc>
ffffffffc0200252:	00002517          	auipc	a0,0x2
ffffffffc0200256:	14650513          	addi	a0,a0,326 # ffffffffc0202398 <etext+0x204>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020025c:	eb3ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200260:	00002617          	auipc	a2,0x2
ffffffffc0200264:	14860613          	addi	a2,a2,328 # ffffffffc02023a8 <etext+0x214>
ffffffffc0200268:	00002597          	auipc	a1,0x2
ffffffffc020026c:	16858593          	addi	a1,a1,360 # ffffffffc02023d0 <etext+0x23c>
ffffffffc0200270:	00002517          	auipc	a0,0x2
ffffffffc0200274:	12850513          	addi	a0,a0,296 # ffffffffc0202398 <etext+0x204>
ffffffffc0200278:	e97ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc020027c:	00002617          	auipc	a2,0x2
ffffffffc0200280:	16460613          	addi	a2,a2,356 # ffffffffc02023e0 <etext+0x24c>
ffffffffc0200284:	00002597          	auipc	a1,0x2
ffffffffc0200288:	17c58593          	addi	a1,a1,380 # ffffffffc0202400 <etext+0x26c>
ffffffffc020028c:	00002517          	auipc	a0,0x2
ffffffffc0200290:	10c50513          	addi	a0,a0,268 # ffffffffc0202398 <etext+0x204>
ffffffffc0200294:	e7bff0ef          	jal	ra,ffffffffc020010e <cprintf>
    }
    return 0;
}
ffffffffc0200298:	60a2                	ld	ra,8(sp)
ffffffffc020029a:	4501                	li	a0,0
ffffffffc020029c:	0141                	addi	sp,sp,16
ffffffffc020029e:	8082                	ret

ffffffffc02002a0 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a0:	1141                	addi	sp,sp,-16
ffffffffc02002a2:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002a4:	ef3ff0ef          	jal	ra,ffffffffc0200196 <print_kerninfo>
    return 0;
}
ffffffffc02002a8:	60a2                	ld	ra,8(sp)
ffffffffc02002aa:	4501                	li	a0,0
ffffffffc02002ac:	0141                	addi	sp,sp,16
ffffffffc02002ae:	8082                	ret

ffffffffc02002b0 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002b0:	1141                	addi	sp,sp,-16
ffffffffc02002b2:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002b4:	f71ff0ef          	jal	ra,ffffffffc0200224 <print_stackframe>
    return 0;
}
ffffffffc02002b8:	60a2                	ld	ra,8(sp)
ffffffffc02002ba:	4501                	li	a0,0
ffffffffc02002bc:	0141                	addi	sp,sp,16
ffffffffc02002be:	8082                	ret

ffffffffc02002c0 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002c0:	7115                	addi	sp,sp,-224
ffffffffc02002c2:	ed5e                	sd	s7,152(sp)
ffffffffc02002c4:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002c6:	00002517          	auipc	a0,0x2
ffffffffc02002ca:	14a50513          	addi	a0,a0,330 # ffffffffc0202410 <etext+0x27c>
kmonitor(struct trapframe *tf) {
ffffffffc02002ce:	ed86                	sd	ra,216(sp)
ffffffffc02002d0:	e9a2                	sd	s0,208(sp)
ffffffffc02002d2:	e5a6                	sd	s1,200(sp)
ffffffffc02002d4:	e1ca                	sd	s2,192(sp)
ffffffffc02002d6:	fd4e                	sd	s3,184(sp)
ffffffffc02002d8:	f952                	sd	s4,176(sp)
ffffffffc02002da:	f556                	sd	s5,168(sp)
ffffffffc02002dc:	f15a                	sd	s6,160(sp)
ffffffffc02002de:	e962                	sd	s8,144(sp)
ffffffffc02002e0:	e566                	sd	s9,136(sp)
ffffffffc02002e2:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002e4:	e2bff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002e8:	00002517          	auipc	a0,0x2
ffffffffc02002ec:	15050513          	addi	a0,a0,336 # ffffffffc0202438 <etext+0x2a4>
ffffffffc02002f0:	e1fff0ef          	jal	ra,ffffffffc020010e <cprintf>
    if (tf != NULL) {
ffffffffc02002f4:	000b8563          	beqz	s7,ffffffffc02002fe <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002f8:	855e                	mv	a0,s7
ffffffffc02002fa:	756000ef          	jal	ra,ffffffffc0200a50 <print_trapframe>
ffffffffc02002fe:	00002c17          	auipc	s8,0x2
ffffffffc0200302:	1aac0c13          	addi	s8,s8,426 # ffffffffc02024a8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200306:	00002917          	auipc	s2,0x2
ffffffffc020030a:	15a90913          	addi	s2,s2,346 # ffffffffc0202460 <etext+0x2cc>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030e:	00002497          	auipc	s1,0x2
ffffffffc0200312:	15a48493          	addi	s1,s1,346 # ffffffffc0202468 <etext+0x2d4>
        if (argc == MAXARGS - 1) {
ffffffffc0200316:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200318:	00002b17          	auipc	s6,0x2
ffffffffc020031c:	158b0b13          	addi	s6,s6,344 # ffffffffc0202470 <etext+0x2dc>
        argv[argc ++] = buf;
ffffffffc0200320:	00002a17          	auipc	s4,0x2
ffffffffc0200324:	070a0a13          	addi	s4,s4,112 # ffffffffc0202390 <etext+0x1fc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200328:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020032a:	854a                	mv	a0,s2
ffffffffc020032c:	4a9010ef          	jal	ra,ffffffffc0201fd4 <readline>
ffffffffc0200330:	842a                	mv	s0,a0
ffffffffc0200332:	dd65                	beqz	a0,ffffffffc020032a <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200334:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200338:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033a:	e1bd                	bnez	a1,ffffffffc02003a0 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc020033c:	fe0c87e3          	beqz	s9,ffffffffc020032a <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200340:	6582                	ld	a1,0(sp)
ffffffffc0200342:	00002d17          	auipc	s10,0x2
ffffffffc0200346:	166d0d13          	addi	s10,s10,358 # ffffffffc02024a8 <commands>
        argv[argc ++] = buf;
ffffffffc020034a:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034c:	4401                	li	s0,0
ffffffffc020034e:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200350:	5d9010ef          	jal	ra,ffffffffc0202128 <strcmp>
ffffffffc0200354:	c919                	beqz	a0,ffffffffc020036a <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200356:	2405                	addiw	s0,s0,1
ffffffffc0200358:	0b540063          	beq	s0,s5,ffffffffc02003f8 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020035c:	000d3503          	ld	a0,0(s10)
ffffffffc0200360:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200362:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200364:	5c5010ef          	jal	ra,ffffffffc0202128 <strcmp>
ffffffffc0200368:	f57d                	bnez	a0,ffffffffc0200356 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020036a:	00141793          	slli	a5,s0,0x1
ffffffffc020036e:	97a2                	add	a5,a5,s0
ffffffffc0200370:	078e                	slli	a5,a5,0x3
ffffffffc0200372:	97e2                	add	a5,a5,s8
ffffffffc0200374:	6b9c                	ld	a5,16(a5)
ffffffffc0200376:	865e                	mv	a2,s7
ffffffffc0200378:	002c                	addi	a1,sp,8
ffffffffc020037a:	fffc851b          	addiw	a0,s9,-1
ffffffffc020037e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200380:	fa0555e3          	bgez	a0,ffffffffc020032a <kmonitor+0x6a>
}
ffffffffc0200384:	60ee                	ld	ra,216(sp)
ffffffffc0200386:	644e                	ld	s0,208(sp)
ffffffffc0200388:	64ae                	ld	s1,200(sp)
ffffffffc020038a:	690e                	ld	s2,192(sp)
ffffffffc020038c:	79ea                	ld	s3,184(sp)
ffffffffc020038e:	7a4a                	ld	s4,176(sp)
ffffffffc0200390:	7aaa                	ld	s5,168(sp)
ffffffffc0200392:	7b0a                	ld	s6,160(sp)
ffffffffc0200394:	6bea                	ld	s7,152(sp)
ffffffffc0200396:	6c4a                	ld	s8,144(sp)
ffffffffc0200398:	6caa                	ld	s9,136(sp)
ffffffffc020039a:	6d0a                	ld	s10,128(sp)
ffffffffc020039c:	612d                	addi	sp,sp,224
ffffffffc020039e:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a0:	8526                	mv	a0,s1
ffffffffc02003a2:	5cb010ef          	jal	ra,ffffffffc020216c <strchr>
ffffffffc02003a6:	c901                	beqz	a0,ffffffffc02003b6 <kmonitor+0xf6>
ffffffffc02003a8:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003ac:	00040023          	sb	zero,0(s0)
ffffffffc02003b0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b2:	d5c9                	beqz	a1,ffffffffc020033c <kmonitor+0x7c>
ffffffffc02003b4:	b7f5                	j	ffffffffc02003a0 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003b6:	00044783          	lbu	a5,0(s0)
ffffffffc02003ba:	d3c9                	beqz	a5,ffffffffc020033c <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02003bc:	033c8963          	beq	s9,s3,ffffffffc02003ee <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02003c0:	003c9793          	slli	a5,s9,0x3
ffffffffc02003c4:	0118                	addi	a4,sp,128
ffffffffc02003c6:	97ba                	add	a5,a5,a4
ffffffffc02003c8:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003cc:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003d0:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003d2:	e591                	bnez	a1,ffffffffc02003de <kmonitor+0x11e>
ffffffffc02003d4:	b7b5                	j	ffffffffc0200340 <kmonitor+0x80>
ffffffffc02003d6:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003da:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003dc:	d1a5                	beqz	a1,ffffffffc020033c <kmonitor+0x7c>
ffffffffc02003de:	8526                	mv	a0,s1
ffffffffc02003e0:	58d010ef          	jal	ra,ffffffffc020216c <strchr>
ffffffffc02003e4:	d96d                	beqz	a0,ffffffffc02003d6 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003e6:	00044583          	lbu	a1,0(s0)
ffffffffc02003ea:	d9a9                	beqz	a1,ffffffffc020033c <kmonitor+0x7c>
ffffffffc02003ec:	bf55                	j	ffffffffc02003a0 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003ee:	45c1                	li	a1,16
ffffffffc02003f0:	855a                	mv	a0,s6
ffffffffc02003f2:	d1dff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02003f6:	b7e9                	j	ffffffffc02003c0 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003f8:	6582                	ld	a1,0(sp)
ffffffffc02003fa:	00002517          	auipc	a0,0x2
ffffffffc02003fe:	09650513          	addi	a0,a0,150 # ffffffffc0202490 <etext+0x2fc>
ffffffffc0200402:	d0dff0ef          	jal	ra,ffffffffc020010e <cprintf>
    return 0;
ffffffffc0200406:	b715                	j	ffffffffc020032a <kmonitor+0x6a>

ffffffffc0200408 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200408:	00007317          	auipc	t1,0x7
ffffffffc020040c:	03830313          	addi	t1,t1,56 # ffffffffc0207440 <is_panic>
ffffffffc0200410:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200414:	715d                	addi	sp,sp,-80
ffffffffc0200416:	ec06                	sd	ra,24(sp)
ffffffffc0200418:	e822                	sd	s0,16(sp)
ffffffffc020041a:	f436                	sd	a3,40(sp)
ffffffffc020041c:	f83a                	sd	a4,48(sp)
ffffffffc020041e:	fc3e                	sd	a5,56(sp)
ffffffffc0200420:	e0c2                	sd	a6,64(sp)
ffffffffc0200422:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200424:	020e1a63          	bnez	t3,ffffffffc0200458 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200428:	4785                	li	a5,1
ffffffffc020042a:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc020042e:	8432                	mv	s0,a2
ffffffffc0200430:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200432:	862e                	mv	a2,a1
ffffffffc0200434:	85aa                	mv	a1,a0
ffffffffc0200436:	00002517          	auipc	a0,0x2
ffffffffc020043a:	0ba50513          	addi	a0,a0,186 # ffffffffc02024f0 <commands+0x48>
    va_start(ap, fmt);
ffffffffc020043e:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200440:	ccfff0ef          	jal	ra,ffffffffc020010e <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200444:	65a2                	ld	a1,8(sp)
ffffffffc0200446:	8522                	mv	a0,s0
ffffffffc0200448:	ca7ff0ef          	jal	ra,ffffffffc02000ee <vcprintf>
    cprintf("\n");
ffffffffc020044c:	00002517          	auipc	a0,0x2
ffffffffc0200450:	dac50513          	addi	a0,a0,-596 # ffffffffc02021f8 <etext+0x64>
ffffffffc0200454:	cbbff0ef          	jal	ra,ffffffffc020010e <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200458:	412000ef          	jal	ra,ffffffffc020086a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020045c:	4501                	li	a0,0
ffffffffc020045e:	e63ff0ef          	jal	ra,ffffffffc02002c0 <kmonitor>
    while (1) {
ffffffffc0200462:	bfed                	j	ffffffffc020045c <__panic+0x54>

ffffffffc0200464 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200464:	1141                	addi	sp,sp,-16
ffffffffc0200466:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200468:	02000793          	li	a5,32
ffffffffc020046c:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200470:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200474:	67e1                	lui	a5,0x18
ffffffffc0200476:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020047a:	953e                	add	a0,a0,a5
ffffffffc020047c:	427010ef          	jal	ra,ffffffffc02020a2 <sbi_set_timer>
}
ffffffffc0200480:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200482:	00007797          	auipc	a5,0x7
ffffffffc0200486:	fc07b323          	sd	zero,-58(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020048a:	00002517          	auipc	a0,0x2
ffffffffc020048e:	08650513          	addi	a0,a0,134 # ffffffffc0202510 <commands+0x68>
}
ffffffffc0200492:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200494:	b9ad                	j	ffffffffc020010e <cprintf>

ffffffffc0200496 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200496:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020049a:	67e1                	lui	a5,0x18
ffffffffc020049c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004a0:	953e                	add	a0,a0,a5
ffffffffc02004a2:	4010106f          	j	ffffffffc02020a2 <sbi_set_timer>

ffffffffc02004a6 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004a6:	8082                	ret

ffffffffc02004a8 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc02004a8:	0ff57513          	zext.b	a0,a0
ffffffffc02004ac:	3dd0106f          	j	ffffffffc0202088 <sbi_console_putchar>

ffffffffc02004b0 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc02004b0:	40d0106f          	j	ffffffffc02020bc <sbi_console_getchar>

ffffffffc02004b4 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004b4:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004b6:	00002517          	auipc	a0,0x2
ffffffffc02004ba:	07a50513          	addi	a0,a0,122 # ffffffffc0202530 <commands+0x88>
void dtb_init(void) {
ffffffffc02004be:	fc86                	sd	ra,120(sp)
ffffffffc02004c0:	f8a2                	sd	s0,112(sp)
ffffffffc02004c2:	e8d2                	sd	s4,80(sp)
ffffffffc02004c4:	f4a6                	sd	s1,104(sp)
ffffffffc02004c6:	f0ca                	sd	s2,96(sp)
ffffffffc02004c8:	ecce                	sd	s3,88(sp)
ffffffffc02004ca:	e4d6                	sd	s5,72(sp)
ffffffffc02004cc:	e0da                	sd	s6,64(sp)
ffffffffc02004ce:	fc5e                	sd	s7,56(sp)
ffffffffc02004d0:	f862                	sd	s8,48(sp)
ffffffffc02004d2:	f466                	sd	s9,40(sp)
ffffffffc02004d4:	f06a                	sd	s10,32(sp)
ffffffffc02004d6:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004d8:	c37ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004dc:	00007597          	auipc	a1,0x7
ffffffffc02004e0:	b245b583          	ld	a1,-1244(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc02004e4:	00002517          	auipc	a0,0x2
ffffffffc02004e8:	05c50513          	addi	a0,a0,92 # ffffffffc0202540 <commands+0x98>
ffffffffc02004ec:	c23ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004f0:	00007417          	auipc	s0,0x7
ffffffffc02004f4:	b1840413          	addi	s0,s0,-1256 # ffffffffc0207008 <boot_dtb>
ffffffffc02004f8:	600c                	ld	a1,0(s0)
ffffffffc02004fa:	00002517          	auipc	a0,0x2
ffffffffc02004fe:	05650513          	addi	a0,a0,86 # ffffffffc0202550 <commands+0xa8>
ffffffffc0200502:	c0dff0ef          	jal	ra,ffffffffc020010e <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200506:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020050a:	00002517          	auipc	a0,0x2
ffffffffc020050e:	05e50513          	addi	a0,a0,94 # ffffffffc0202568 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc0200512:	120a0463          	beqz	s4,ffffffffc020063a <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200516:	57f5                	li	a5,-3
ffffffffc0200518:	07fa                	slli	a5,a5,0x1e
ffffffffc020051a:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020051e:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200520:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200524:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200526:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020052a:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052e:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200532:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053a:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053c:	8ec9                	or	a3,a3,a0
ffffffffc020053e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200542:	1b7d                	addi	s6,s6,-1
ffffffffc0200544:	0167f7b3          	and	a5,a5,s6
ffffffffc0200548:	8dd5                	or	a1,a1,a3
ffffffffc020054a:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc020054c:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200550:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200552:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed8a4d>
ffffffffc0200556:	10f59163          	bne	a1,a5,ffffffffc0200658 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020055a:	471c                	lw	a5,8(a4)
ffffffffc020055c:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc020055e:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200560:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200564:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200568:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020056c:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200570:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200574:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200578:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020057c:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200580:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200584:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200588:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058a:	01146433          	or	s0,s0,a7
ffffffffc020058e:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200592:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200596:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200598:	0087979b          	slliw	a5,a5,0x8
ffffffffc020059c:	8c49                	or	s0,s0,a0
ffffffffc020059e:	0166f6b3          	and	a3,a3,s6
ffffffffc02005a2:	00ca6a33          	or	s4,s4,a2
ffffffffc02005a6:	0167f7b3          	and	a5,a5,s6
ffffffffc02005aa:	8c55                	or	s0,s0,a3
ffffffffc02005ac:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b0:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005b2:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b4:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005b6:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005ba:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005bc:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005be:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc02005c2:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005c4:	00002917          	auipc	s2,0x2
ffffffffc02005c8:	ff490913          	addi	s2,s2,-12 # ffffffffc02025b8 <commands+0x110>
ffffffffc02005cc:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005ce:	4d91                	li	s11,4
ffffffffc02005d0:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005d2:	00002497          	auipc	s1,0x2
ffffffffc02005d6:	fde48493          	addi	s1,s1,-34 # ffffffffc02025b0 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005da:	000a2703          	lw	a4,0(s4)
ffffffffc02005de:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e2:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005e6:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ea:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ee:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f2:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005f6:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f8:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005fc:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200600:	8fd5                	or	a5,a5,a3
ffffffffc0200602:	00eb7733          	and	a4,s6,a4
ffffffffc0200606:	8fd9                	or	a5,a5,a4
ffffffffc0200608:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020060a:	09778c63          	beq	a5,s7,ffffffffc02006a2 <dtb_init+0x1ee>
ffffffffc020060e:	00fbea63          	bltu	s7,a5,ffffffffc0200622 <dtb_init+0x16e>
ffffffffc0200612:	07a78663          	beq	a5,s10,ffffffffc020067e <dtb_init+0x1ca>
ffffffffc0200616:	4709                	li	a4,2
ffffffffc0200618:	00e79763          	bne	a5,a4,ffffffffc0200626 <dtb_init+0x172>
ffffffffc020061c:	4c81                	li	s9,0
ffffffffc020061e:	8a56                	mv	s4,s5
ffffffffc0200620:	bf6d                	j	ffffffffc02005da <dtb_init+0x126>
ffffffffc0200622:	ffb78ee3          	beq	a5,s11,ffffffffc020061e <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200626:	00002517          	auipc	a0,0x2
ffffffffc020062a:	00a50513          	addi	a0,a0,10 # ffffffffc0202630 <commands+0x188>
ffffffffc020062e:	ae1ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200632:	00002517          	auipc	a0,0x2
ffffffffc0200636:	03650513          	addi	a0,a0,54 # ffffffffc0202668 <commands+0x1c0>
}
ffffffffc020063a:	7446                	ld	s0,112(sp)
ffffffffc020063c:	70e6                	ld	ra,120(sp)
ffffffffc020063e:	74a6                	ld	s1,104(sp)
ffffffffc0200640:	7906                	ld	s2,96(sp)
ffffffffc0200642:	69e6                	ld	s3,88(sp)
ffffffffc0200644:	6a46                	ld	s4,80(sp)
ffffffffc0200646:	6aa6                	ld	s5,72(sp)
ffffffffc0200648:	6b06                	ld	s6,64(sp)
ffffffffc020064a:	7be2                	ld	s7,56(sp)
ffffffffc020064c:	7c42                	ld	s8,48(sp)
ffffffffc020064e:	7ca2                	ld	s9,40(sp)
ffffffffc0200650:	7d02                	ld	s10,32(sp)
ffffffffc0200652:	6de2                	ld	s11,24(sp)
ffffffffc0200654:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200656:	bc65                	j	ffffffffc020010e <cprintf>
}
ffffffffc0200658:	7446                	ld	s0,112(sp)
ffffffffc020065a:	70e6                	ld	ra,120(sp)
ffffffffc020065c:	74a6                	ld	s1,104(sp)
ffffffffc020065e:	7906                	ld	s2,96(sp)
ffffffffc0200660:	69e6                	ld	s3,88(sp)
ffffffffc0200662:	6a46                	ld	s4,80(sp)
ffffffffc0200664:	6aa6                	ld	s5,72(sp)
ffffffffc0200666:	6b06                	ld	s6,64(sp)
ffffffffc0200668:	7be2                	ld	s7,56(sp)
ffffffffc020066a:	7c42                	ld	s8,48(sp)
ffffffffc020066c:	7ca2                	ld	s9,40(sp)
ffffffffc020066e:	7d02                	ld	s10,32(sp)
ffffffffc0200670:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200672:	00002517          	auipc	a0,0x2
ffffffffc0200676:	f1650513          	addi	a0,a0,-234 # ffffffffc0202588 <commands+0xe0>
}
ffffffffc020067a:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020067c:	bc49                	j	ffffffffc020010e <cprintf>
                int name_len = strlen(name);
ffffffffc020067e:	8556                	mv	a0,s5
ffffffffc0200680:	273010ef          	jal	ra,ffffffffc02020f2 <strlen>
ffffffffc0200684:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200686:	4619                	li	a2,6
ffffffffc0200688:	85a6                	mv	a1,s1
ffffffffc020068a:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc020068c:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020068e:	2b9010ef          	jal	ra,ffffffffc0202146 <strncmp>
ffffffffc0200692:	e111                	bnez	a0,ffffffffc0200696 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200694:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200696:	0a91                	addi	s5,s5,4
ffffffffc0200698:	9ad2                	add	s5,s5,s4
ffffffffc020069a:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020069e:	8a56                	mv	s4,s5
ffffffffc02006a0:	bf2d                	j	ffffffffc02005da <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a2:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a6:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006aa:	0087d71b          	srliw	a4,a5,0x8
ffffffffc02006ae:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b2:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b6:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ba:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006be:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006ca:	00eaeab3          	or	s5,s5,a4
ffffffffc02006ce:	00fb77b3          	and	a5,s6,a5
ffffffffc02006d2:	00faeab3          	or	s5,s5,a5
ffffffffc02006d6:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006d8:	000c9c63          	bnez	s9,ffffffffc02006f0 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006dc:	1a82                	slli	s5,s5,0x20
ffffffffc02006de:	00368793          	addi	a5,a3,3
ffffffffc02006e2:	020ada93          	srli	s5,s5,0x20
ffffffffc02006e6:	9abe                	add	s5,s5,a5
ffffffffc02006e8:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006ec:	8a56                	mv	s4,s5
ffffffffc02006ee:	b5f5                	j	ffffffffc02005da <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006f0:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f4:	85ca                	mv	a1,s2
ffffffffc02006f6:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006f8:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006fc:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200700:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200704:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200708:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020070c:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070e:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200716:	8d59                	or	a0,a0,a4
ffffffffc0200718:	00fb77b3          	and	a5,s6,a5
ffffffffc020071c:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020071e:	1502                	slli	a0,a0,0x20
ffffffffc0200720:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200722:	9522                	add	a0,a0,s0
ffffffffc0200724:	205010ef          	jal	ra,ffffffffc0202128 <strcmp>
ffffffffc0200728:	66a2                	ld	a3,8(sp)
ffffffffc020072a:	f94d                	bnez	a0,ffffffffc02006dc <dtb_init+0x228>
ffffffffc020072c:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006dc <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200730:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200734:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200738:	00002517          	auipc	a0,0x2
ffffffffc020073c:	e8850513          	addi	a0,a0,-376 # ffffffffc02025c0 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc0200740:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200744:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200748:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074c:	0187de1b          	srliw	t3,a5,0x18
ffffffffc0200750:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200754:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200758:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020075c:	0187d693          	srli	a3,a5,0x18
ffffffffc0200760:	01861f1b          	slliw	t5,a2,0x18
ffffffffc0200764:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200768:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020076c:	0106561b          	srliw	a2,a2,0x10
ffffffffc0200770:	010f6f33          	or	t5,t5,a6
ffffffffc0200774:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200778:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077c:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200780:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200784:	0186f6b3          	and	a3,a3,s8
ffffffffc0200788:	01859e1b          	slliw	t3,a1,0x18
ffffffffc020078c:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200790:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200794:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200798:	8361                	srli	a4,a4,0x18
ffffffffc020079a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020079e:	0105d59b          	srliw	a1,a1,0x10
ffffffffc02007a2:	01e6e6b3          	or	a3,a3,t5
ffffffffc02007a6:	00cb7633          	and	a2,s6,a2
ffffffffc02007aa:	0088181b          	slliw	a6,a6,0x8
ffffffffc02007ae:	0085959b          	slliw	a1,a1,0x8
ffffffffc02007b2:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007b6:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ba:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007be:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c2:	0088989b          	slliw	a7,a7,0x8
ffffffffc02007c6:	011b78b3          	and	a7,s6,a7
ffffffffc02007ca:	005eeeb3          	or	t4,t4,t0
ffffffffc02007ce:	00c6e733          	or	a4,a3,a2
ffffffffc02007d2:	006c6c33          	or	s8,s8,t1
ffffffffc02007d6:	010b76b3          	and	a3,s6,a6
ffffffffc02007da:	00bb7b33          	and	s6,s6,a1
ffffffffc02007de:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007e2:	016c6b33          	or	s6,s8,s6
ffffffffc02007e6:	01146433          	or	s0,s0,a7
ffffffffc02007ea:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007ec:	1702                	slli	a4,a4,0x20
ffffffffc02007ee:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f0:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007f2:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007f4:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007f6:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007fa:	0167eb33          	or	s6,a5,s6
ffffffffc02007fe:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200800:	90fff0ef          	jal	ra,ffffffffc020010e <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200804:	85a2                	mv	a1,s0
ffffffffc0200806:	00002517          	auipc	a0,0x2
ffffffffc020080a:	dda50513          	addi	a0,a0,-550 # ffffffffc02025e0 <commands+0x138>
ffffffffc020080e:	901ff0ef          	jal	ra,ffffffffc020010e <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200812:	014b5613          	srli	a2,s6,0x14
ffffffffc0200816:	85da                	mv	a1,s6
ffffffffc0200818:	00002517          	auipc	a0,0x2
ffffffffc020081c:	de050513          	addi	a0,a0,-544 # ffffffffc02025f8 <commands+0x150>
ffffffffc0200820:	8efff0ef          	jal	ra,ffffffffc020010e <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200824:	008b05b3          	add	a1,s6,s0
ffffffffc0200828:	15fd                	addi	a1,a1,-1
ffffffffc020082a:	00002517          	auipc	a0,0x2
ffffffffc020082e:	dee50513          	addi	a0,a0,-530 # ffffffffc0202618 <commands+0x170>
ffffffffc0200832:	8ddff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200836:	00002517          	auipc	a0,0x2
ffffffffc020083a:	e3250513          	addi	a0,a0,-462 # ffffffffc0202668 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc020083e:	00007797          	auipc	a5,0x7
ffffffffc0200842:	c087b923          	sd	s0,-1006(a5) # ffffffffc0207450 <memory_base>
        memory_size = mem_size;
ffffffffc0200846:	00007797          	auipc	a5,0x7
ffffffffc020084a:	c167b923          	sd	s6,-1006(a5) # ffffffffc0207458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc020084e:	b3f5                	j	ffffffffc020063a <dtb_init+0x186>

ffffffffc0200850 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc0200850:	00007517          	auipc	a0,0x7
ffffffffc0200854:	c0053503          	ld	a0,-1024(a0) # ffffffffc0207450 <memory_base>
ffffffffc0200858:	8082                	ret

ffffffffc020085a <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc020085a:	00007517          	auipc	a0,0x7
ffffffffc020085e:	bfe53503          	ld	a0,-1026(a0) # ffffffffc0207458 <memory_size>
ffffffffc0200862:	8082                	ret

ffffffffc0200864 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200864:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200868:	8082                	ret

ffffffffc020086a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020086a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020086e:	8082                	ret

ffffffffc0200870 <idt_init>:

/* 初始化 IDT 和异常向量 */
void idt_init(void) {
    /*LAB3 2313411*/
    extern void __alltraps(void);
    write_csr(sscratch, 0);        // 内核模式标记
ffffffffc0200870:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200874:	00000797          	auipc	a5,0x0
ffffffffc0200878:	54c78793          	addi	a5,a5,1356 # ffffffffc0200dc0 <__alltraps>
ffffffffc020087c:	10579073          	csrw	stvec,a5
}
ffffffffc0200880:	8082                	ret

ffffffffc0200882 <print_regs>:
    cprintf("  cause    0x%08lx\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    #define PRINT_REG(r) cprintf("  " #r "  0x%08lx\n", gpr->r)
    PRINT_REG(zero); PRINT_REG(ra); PRINT_REG(sp); PRINT_REG(gp); PRINT_REG(tp);
ffffffffc0200882:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200884:	1141                	addi	sp,sp,-16
ffffffffc0200886:	e022                	sd	s0,0(sp)
ffffffffc0200888:	842a                	mv	s0,a0
    PRINT_REG(zero); PRINT_REG(ra); PRINT_REG(sp); PRINT_REG(gp); PRINT_REG(tp);
ffffffffc020088a:	00002517          	auipc	a0,0x2
ffffffffc020088e:	df650513          	addi	a0,a0,-522 # ffffffffc0202680 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200892:	e406                	sd	ra,8(sp)
    PRINT_REG(zero); PRINT_REG(ra); PRINT_REG(sp); PRINT_REG(gp); PRINT_REG(tp);
ffffffffc0200894:	87bff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200898:	640c                	ld	a1,8(s0)
ffffffffc020089a:	00002517          	auipc	a0,0x2
ffffffffc020089e:	dfe50513          	addi	a0,a0,-514 # ffffffffc0202698 <commands+0x1f0>
ffffffffc02008a2:	86dff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008a6:	680c                	ld	a1,16(s0)
ffffffffc02008a8:	00002517          	auipc	a0,0x2
ffffffffc02008ac:	e0050513          	addi	a0,a0,-512 # ffffffffc02026a8 <commands+0x200>
ffffffffc02008b0:	85fff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008b4:	6c0c                	ld	a1,24(s0)
ffffffffc02008b6:	00002517          	auipc	a0,0x2
ffffffffc02008ba:	e0250513          	addi	a0,a0,-510 # ffffffffc02026b8 <commands+0x210>
ffffffffc02008be:	851ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008c2:	700c                	ld	a1,32(s0)
ffffffffc02008c4:	00002517          	auipc	a0,0x2
ffffffffc02008c8:	e0450513          	addi	a0,a0,-508 # ffffffffc02026c8 <commands+0x220>
ffffffffc02008cc:	843ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(t0); PRINT_REG(t1); PRINT_REG(t2); PRINT_REG(s0); PRINT_REG(s1);
ffffffffc02008d0:	740c                	ld	a1,40(s0)
ffffffffc02008d2:	00002517          	auipc	a0,0x2
ffffffffc02008d6:	e0650513          	addi	a0,a0,-506 # ffffffffc02026d8 <commands+0x230>
ffffffffc02008da:	835ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008de:	780c                	ld	a1,48(s0)
ffffffffc02008e0:	00002517          	auipc	a0,0x2
ffffffffc02008e4:	e0850513          	addi	a0,a0,-504 # ffffffffc02026e8 <commands+0x240>
ffffffffc02008e8:	827ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008ec:	7c0c                	ld	a1,56(s0)
ffffffffc02008ee:	00002517          	auipc	a0,0x2
ffffffffc02008f2:	e0a50513          	addi	a0,a0,-502 # ffffffffc02026f8 <commands+0x250>
ffffffffc02008f6:	819ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008fa:	602c                	ld	a1,64(s0)
ffffffffc02008fc:	00002517          	auipc	a0,0x2
ffffffffc0200900:	e0c50513          	addi	a0,a0,-500 # ffffffffc0202708 <commands+0x260>
ffffffffc0200904:	80bff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200908:	642c                	ld	a1,72(s0)
ffffffffc020090a:	00002517          	auipc	a0,0x2
ffffffffc020090e:	e0e50513          	addi	a0,a0,-498 # ffffffffc0202718 <commands+0x270>
ffffffffc0200912:	ffcff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(a0); PRINT_REG(a1); PRINT_REG(a2); PRINT_REG(a3); PRINT_REG(a4);
ffffffffc0200916:	682c                	ld	a1,80(s0)
ffffffffc0200918:	00002517          	auipc	a0,0x2
ffffffffc020091c:	e1050513          	addi	a0,a0,-496 # ffffffffc0202728 <commands+0x280>
ffffffffc0200920:	feeff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200924:	6c2c                	ld	a1,88(s0)
ffffffffc0200926:	00002517          	auipc	a0,0x2
ffffffffc020092a:	e1250513          	addi	a0,a0,-494 # ffffffffc0202738 <commands+0x290>
ffffffffc020092e:	fe0ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200932:	702c                	ld	a1,96(s0)
ffffffffc0200934:	00002517          	auipc	a0,0x2
ffffffffc0200938:	e1450513          	addi	a0,a0,-492 # ffffffffc0202748 <commands+0x2a0>
ffffffffc020093c:	fd2ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200940:	742c                	ld	a1,104(s0)
ffffffffc0200942:	00002517          	auipc	a0,0x2
ffffffffc0200946:	e1650513          	addi	a0,a0,-490 # ffffffffc0202758 <commands+0x2b0>
ffffffffc020094a:	fc4ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc020094e:	782c                	ld	a1,112(s0)
ffffffffc0200950:	00002517          	auipc	a0,0x2
ffffffffc0200954:	e1850513          	addi	a0,a0,-488 # ffffffffc0202768 <commands+0x2c0>
ffffffffc0200958:	fb6ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(a5); PRINT_REG(a6); PRINT_REG(a7);
ffffffffc020095c:	7c2c                	ld	a1,120(s0)
ffffffffc020095e:	00002517          	auipc	a0,0x2
ffffffffc0200962:	e1a50513          	addi	a0,a0,-486 # ffffffffc0202778 <commands+0x2d0>
ffffffffc0200966:	fa8ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc020096a:	604c                	ld	a1,128(s0)
ffffffffc020096c:	00002517          	auipc	a0,0x2
ffffffffc0200970:	e1c50513          	addi	a0,a0,-484 # ffffffffc0202788 <commands+0x2e0>
ffffffffc0200974:	f9aff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200978:	644c                	ld	a1,136(s0)
ffffffffc020097a:	00002517          	auipc	a0,0x2
ffffffffc020097e:	e1e50513          	addi	a0,a0,-482 # ffffffffc0202798 <commands+0x2f0>
ffffffffc0200982:	f8cff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(s2); PRINT_REG(s3); PRINT_REG(s4); PRINT_REG(s5); PRINT_REG(s6);
ffffffffc0200986:	684c                	ld	a1,144(s0)
ffffffffc0200988:	00002517          	auipc	a0,0x2
ffffffffc020098c:	e2050513          	addi	a0,a0,-480 # ffffffffc02027a8 <commands+0x300>
ffffffffc0200990:	f7eff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200994:	6c4c                	ld	a1,152(s0)
ffffffffc0200996:	00002517          	auipc	a0,0x2
ffffffffc020099a:	e2250513          	addi	a0,a0,-478 # ffffffffc02027b8 <commands+0x310>
ffffffffc020099e:	f70ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009a2:	704c                	ld	a1,160(s0)
ffffffffc02009a4:	00002517          	auipc	a0,0x2
ffffffffc02009a8:	e2450513          	addi	a0,a0,-476 # ffffffffc02027c8 <commands+0x320>
ffffffffc02009ac:	f62ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009b0:	744c                	ld	a1,168(s0)
ffffffffc02009b2:	00002517          	auipc	a0,0x2
ffffffffc02009b6:	e2650513          	addi	a0,a0,-474 # ffffffffc02027d8 <commands+0x330>
ffffffffc02009ba:	f54ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009be:	784c                	ld	a1,176(s0)
ffffffffc02009c0:	00002517          	auipc	a0,0x2
ffffffffc02009c4:	e2850513          	addi	a0,a0,-472 # ffffffffc02027e8 <commands+0x340>
ffffffffc02009c8:	f46ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(s7); PRINT_REG(s8); PRINT_REG(s9); PRINT_REG(s10); PRINT_REG(s11);
ffffffffc02009cc:	7c4c                	ld	a1,184(s0)
ffffffffc02009ce:	00002517          	auipc	a0,0x2
ffffffffc02009d2:	e2a50513          	addi	a0,a0,-470 # ffffffffc02027f8 <commands+0x350>
ffffffffc02009d6:	f38ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009da:	606c                	ld	a1,192(s0)
ffffffffc02009dc:	00002517          	auipc	a0,0x2
ffffffffc02009e0:	e2c50513          	addi	a0,a0,-468 # ffffffffc0202808 <commands+0x360>
ffffffffc02009e4:	f2aff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009e8:	646c                	ld	a1,200(s0)
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	e2e50513          	addi	a0,a0,-466 # ffffffffc0202818 <commands+0x370>
ffffffffc02009f2:	f1cff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009f6:	686c                	ld	a1,208(s0)
ffffffffc02009f8:	00002517          	auipc	a0,0x2
ffffffffc02009fc:	e3050513          	addi	a0,a0,-464 # ffffffffc0202828 <commands+0x380>
ffffffffc0200a00:	f0eff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200a04:	6c6c                	ld	a1,216(s0)
ffffffffc0200a06:	00002517          	auipc	a0,0x2
ffffffffc0200a0a:	e3250513          	addi	a0,a0,-462 # ffffffffc0202838 <commands+0x390>
ffffffffc0200a0e:	f00ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(t3); PRINT_REG(t4); PRINT_REG(t5); PRINT_REG(t6);
ffffffffc0200a12:	706c                	ld	a1,224(s0)
ffffffffc0200a14:	00002517          	auipc	a0,0x2
ffffffffc0200a18:	e3450513          	addi	a0,a0,-460 # ffffffffc0202848 <commands+0x3a0>
ffffffffc0200a1c:	ef2ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200a20:	746c                	ld	a1,232(s0)
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	e3650513          	addi	a0,a0,-458 # ffffffffc0202858 <commands+0x3b0>
ffffffffc0200a2a:	ee4ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200a2e:	786c                	ld	a1,240(s0)
ffffffffc0200a30:	00002517          	auipc	a0,0x2
ffffffffc0200a34:	e3850513          	addi	a0,a0,-456 # ffffffffc0202868 <commands+0x3c0>
ffffffffc0200a38:	ed6ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200a3c:	7c6c                	ld	a1,248(s0)
    #undef PRINT_REG
}
ffffffffc0200a3e:	6402                	ld	s0,0(sp)
ffffffffc0200a40:	60a2                	ld	ra,8(sp)
    PRINT_REG(t3); PRINT_REG(t4); PRINT_REG(t5); PRINT_REG(t6);
ffffffffc0200a42:	00002517          	auipc	a0,0x2
ffffffffc0200a46:	e3650513          	addi	a0,a0,-458 # ffffffffc0202878 <commands+0x3d0>
}
ffffffffc0200a4a:	0141                	addi	sp,sp,16
    PRINT_REG(t3); PRINT_REG(t4); PRINT_REG(t5); PRINT_REG(t6);
ffffffffc0200a4c:	ec2ff06f          	j	ffffffffc020010e <cprintf>

ffffffffc0200a50 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a50:	1141                	addi	sp,sp,-16
ffffffffc0200a52:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a54:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a56:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a58:	00002517          	auipc	a0,0x2
ffffffffc0200a5c:	e3050513          	addi	a0,a0,-464 # ffffffffc0202888 <commands+0x3e0>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a60:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a62:	eacff0ef          	jal	ra,ffffffffc020010e <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a66:	8522                	mv	a0,s0
ffffffffc0200a68:	e1bff0ef          	jal	ra,ffffffffc0200882 <print_regs>
    cprintf("  status   0x%08lx\n", tf->status);
ffffffffc0200a6c:	10043583          	ld	a1,256(s0)
ffffffffc0200a70:	00002517          	auipc	a0,0x2
ffffffffc0200a74:	e3050513          	addi	a0,a0,-464 # ffffffffc02028a0 <commands+0x3f8>
ffffffffc0200a78:	e96ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  epc      0x%08lx\n", tf->epc);
ffffffffc0200a7c:	10843583          	ld	a1,264(s0)
ffffffffc0200a80:	00002517          	auipc	a0,0x2
ffffffffc0200a84:	e3850513          	addi	a0,a0,-456 # ffffffffc02028b8 <commands+0x410>
ffffffffc0200a88:	e86ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  badvaddr 0x%08lx\n", tf->badvaddr);
ffffffffc0200a8c:	11043583          	ld	a1,272(s0)
ffffffffc0200a90:	00002517          	auipc	a0,0x2
ffffffffc0200a94:	e4050513          	addi	a0,a0,-448 # ffffffffc02028d0 <commands+0x428>
ffffffffc0200a98:	e76ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  cause    0x%08lx\n", tf->cause);
ffffffffc0200a9c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200aa0:	6402                	ld	s0,0(sp)
ffffffffc0200aa2:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08lx\n", tf->cause);
ffffffffc0200aa4:	00002517          	auipc	a0,0x2
ffffffffc0200aa8:	e4450513          	addi	a0,a0,-444 # ffffffffc02028e8 <commands+0x440>
}
ffffffffc0200aac:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08lx\n", tf->cause);
ffffffffc0200aae:	e60ff06f          	j	ffffffffc020010e <cprintf>

ffffffffc0200ab2 <interrupt_handler>:

/* 中断处理 */
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1; // 清除最高位
ffffffffc0200ab2:	11853783          	ld	a5,280(a0)
ffffffffc0200ab6:	472d                	li	a4,11
ffffffffc0200ab8:	0786                	slli	a5,a5,0x1
ffffffffc0200aba:	8385                	srli	a5,a5,0x1
ffffffffc0200abc:	0cf76063          	bltu	a4,a5,ffffffffc0200b7c <interrupt_handler+0xca>
ffffffffc0200ac0:	00002717          	auipc	a4,0x2
ffffffffc0200ac4:	fa470713          	addi	a4,a4,-92 # ffffffffc0202a64 <commands+0x5bc>
ffffffffc0200ac8:	078a                	slli	a5,a5,0x2
ffffffffc0200aca:	97ba                	add	a5,a5,a4
ffffffffc0200acc:	439c                	lw	a5,0(a5)
ffffffffc0200ace:	97ba                	add	a5,a5,a4
ffffffffc0200ad0:	8782                	jr	a5
        case IRQ_U_TIMER: cprintf("User timer interrupt\n"); break;
        case IRQ_H_TIMER: cprintf("Hypervisor timer interrupt\n"); break;
        case IRQ_M_TIMER: cprintf("Machine timer interrupt\n"); break;
        case IRQ_U_EXT: cprintf("User external interrupt\n"); break;
        case IRQ_S_EXT: cprintf("Supervisor external interrupt\n"); break;
        case IRQ_H_EXT: cprintf("Hypervisor external interrupt\n"); break;
ffffffffc0200ad2:	00002517          	auipc	a0,0x2
ffffffffc0200ad6:	f5650513          	addi	a0,a0,-170 # ffffffffc0202a28 <commands+0x580>
ffffffffc0200ada:	e34ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_M_EXT: cprintf("Machine external interrupt\n"); break;
ffffffffc0200ade:	00002517          	auipc	a0,0x2
ffffffffc0200ae2:	f6a50513          	addi	a0,a0,-150 # ffffffffc0202a48 <commands+0x5a0>
ffffffffc0200ae6:	e28ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_U_SOFT: cprintf("User software interrupt\n"); break;
ffffffffc0200aea:	00002517          	auipc	a0,0x2
ffffffffc0200aee:	e2650513          	addi	a0,a0,-474 # ffffffffc0202910 <commands+0x468>
ffffffffc0200af2:	e1cff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_S_SOFT: cprintf("Supervisor software interrupt\n"); break;
ffffffffc0200af6:	00002517          	auipc	a0,0x2
ffffffffc0200afa:	e3a50513          	addi	a0,a0,-454 # ffffffffc0202930 <commands+0x488>
ffffffffc0200afe:	e10ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_H_SOFT: cprintf("Hypervisor software interrupt\n"); break;
ffffffffc0200b02:	00002517          	auipc	a0,0x2
ffffffffc0200b06:	e4e50513          	addi	a0,a0,-434 # ffffffffc0202950 <commands+0x4a8>
ffffffffc0200b0a:	e04ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_M_SOFT: cprintf("Machine software interrupt\n"); break;
ffffffffc0200b0e:	00002517          	auipc	a0,0x2
ffffffffc0200b12:	e6250513          	addi	a0,a0,-414 # ffffffffc0202970 <commands+0x4c8>
ffffffffc0200b16:	df8ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_U_TIMER: cprintf("User timer interrupt\n"); break;
ffffffffc0200b1a:	00002517          	auipc	a0,0x2
ffffffffc0200b1e:	e7650513          	addi	a0,a0,-394 # ffffffffc0202990 <commands+0x4e8>
ffffffffc0200b22:	decff06f          	j	ffffffffc020010e <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200b26:	1141                	addi	sp,sp,-16
ffffffffc0200b28:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc0200b2a:	96dff0ef          	jal	ra,ffffffffc0200496 <clock_set_next_event>
            timer_ticks++;
ffffffffc0200b2e:	00007717          	auipc	a4,0x7
ffffffffc0200b32:	93670713          	addi	a4,a4,-1738 # ffffffffc0207464 <timer_ticks>
ffffffffc0200b36:	431c                	lw	a5,0(a4)
            if (timer_ticks >= TICK_NUM) {
ffffffffc0200b38:	06300693          	li	a3,99
            timer_ticks++;
ffffffffc0200b3c:	0017861b          	addiw	a2,a5,1
            if (timer_ticks >= TICK_NUM) {
ffffffffc0200b40:	02c6cf63          	blt	a3,a2,ffffffffc0200b7e <interrupt_handler+0xcc>
            timer_ticks++;
ffffffffc0200b44:	c310                	sw	a2,0(a4)

        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b46:	60a2                	ld	ra,8(sp)
ffffffffc0200b48:	0141                	addi	sp,sp,16
ffffffffc0200b4a:	8082                	ret
        case IRQ_H_TIMER: cprintf("Hypervisor timer interrupt\n"); break;
ffffffffc0200b4c:	00002517          	auipc	a0,0x2
ffffffffc0200b50:	e5c50513          	addi	a0,a0,-420 # ffffffffc02029a8 <commands+0x500>
ffffffffc0200b54:	dbaff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_M_TIMER: cprintf("Machine timer interrupt\n"); break;
ffffffffc0200b58:	00002517          	auipc	a0,0x2
ffffffffc0200b5c:	e7050513          	addi	a0,a0,-400 # ffffffffc02029c8 <commands+0x520>
ffffffffc0200b60:	daeff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_U_EXT: cprintf("User external interrupt\n"); break;
ffffffffc0200b64:	00002517          	auipc	a0,0x2
ffffffffc0200b68:	e8450513          	addi	a0,a0,-380 # ffffffffc02029e8 <commands+0x540>
ffffffffc0200b6c:	da2ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_S_EXT: cprintf("Supervisor external interrupt\n"); break;
ffffffffc0200b70:	00002517          	auipc	a0,0x2
ffffffffc0200b74:	e9850513          	addi	a0,a0,-360 # ffffffffc0202a08 <commands+0x560>
ffffffffc0200b78:	d96ff06f          	j	ffffffffc020010e <cprintf>
            print_trapframe(tf);
ffffffffc0200b7c:	bdd1                	j	ffffffffc0200a50 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b7e:	06400593          	li	a1,100
ffffffffc0200b82:	00002517          	auipc	a0,0x2
ffffffffc0200b86:	d7e50513          	addi	a0,a0,-642 # ffffffffc0202900 <commands+0x458>
                timer_ticks = 0;
ffffffffc0200b8a:	00007797          	auipc	a5,0x7
ffffffffc0200b8e:	8c07ad23          	sw	zero,-1830(a5) # ffffffffc0207464 <timer_ticks>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b92:	d7cff0ef          	jal	ra,ffffffffc020010e <cprintf>
                timer_prints++;
ffffffffc0200b96:	00007717          	auipc	a4,0x7
ffffffffc0200b9a:	8ca70713          	addi	a4,a4,-1846 # ffffffffc0207460 <timer_prints>
ffffffffc0200b9e:	431c                	lw	a5,0(a4)
                if (timer_prints >= MAX_PRINTS) {
ffffffffc0200ba0:	46a5                	li	a3,9
                timer_prints++;
ffffffffc0200ba2:	0017861b          	addiw	a2,a5,1
ffffffffc0200ba6:	c310                	sw	a2,0(a4)
                if (timer_prints >= MAX_PRINTS) {
ffffffffc0200ba8:	f8c6dfe3          	bge	a3,a2,ffffffffc0200b46 <interrupt_handler+0x94>
}
ffffffffc0200bac:	60a2                	ld	ra,8(sp)
ffffffffc0200bae:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200bb0:	5280106f          	j	ffffffffc02020d8 <sbi_shutdown>

ffffffffc0200bb4 <exception_handler>:

/* 异常处理 */
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200bb4:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200bb8:	1141                	addi	sp,sp,-16
ffffffffc0200bba:	e022                	sd	s0,0(sp)
ffffffffc0200bbc:	e406                	sd	ra,8(sp)
ffffffffc0200bbe:	472d                	li	a4,11
ffffffffc0200bc0:	842a                	mv	s0,a0
ffffffffc0200bc2:	1cf76863          	bltu	a4,a5,ffffffffc0200d92 <exception_handler+0x1de>
ffffffffc0200bc6:	00002717          	auipc	a4,0x2
ffffffffc0200bca:	26270713          	addi	a4,a4,610 # ffffffffc0202e28 <commands+0x980>
ffffffffc0200bce:	078a                	slli	a5,a5,0x2
ffffffffc0200bd0:	97ba                	add	a5,a5,a4
ffffffffc0200bd2:	439c                	lw	a5,0(a5)
            tf->epc += 4;
            break;

        case CAUSE_MACHINE_ECALL:
            // M 模式系统调用
            cprintf("Machine ECALL at 0x%08lx\n", tf->epc);
ffffffffc0200bd4:	10853583          	ld	a1,264(a0)
ffffffffc0200bd8:	97ba                	add	a5,a5,a4
ffffffffc0200bda:	8782                	jr	a5
            cprintf("Hypervisor ECALL at 0x%08lx\n", tf->epc);
ffffffffc0200bdc:	00002517          	auipc	a0,0x2
ffffffffc0200be0:	1a450513          	addi	a0,a0,420 # ffffffffc0202d80 <commands+0x8d8>
ffffffffc0200be4:	d2aff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Hypervisor ECALL\n");
ffffffffc0200be8:	00002517          	auipc	a0,0x2
ffffffffc0200bec:	1b850513          	addi	a0,a0,440 # ffffffffc0202da0 <commands+0x8f8>
ffffffffc0200bf0:	d1eff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200bf4:	10843783          	ld	a5,264(s0)
ffffffffc0200bf8:	0791                	addi	a5,a5,4
ffffffffc0200bfa:	10f43423          	sd	a5,264(s0)
            print_trapframe(tf);
            cprintf("Unknown exception type: %ld\n", tf->cause);
            tf->epc += 4;
            break;
    }
}
ffffffffc0200bfe:	60a2                	ld	ra,8(sp)
ffffffffc0200c00:	6402                	ld	s0,0(sp)
ffffffffc0200c02:	0141                	addi	sp,sp,16
ffffffffc0200c04:	8082                	ret
            cprintf("Machine ECALL at 0x%08lx\n", tf->epc);
ffffffffc0200c06:	00002517          	auipc	a0,0x2
ffffffffc0200c0a:	1c250513          	addi	a0,a0,450 # ffffffffc0202dc8 <commands+0x920>
ffffffffc0200c0e:	d00ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Machine ECALL\n");
ffffffffc0200c12:	00002517          	auipc	a0,0x2
ffffffffc0200c16:	1d650513          	addi	a0,a0,470 # ffffffffc0202de8 <commands+0x940>
ffffffffc0200c1a:	cf4ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200c1e:	10843783          	ld	a5,264(s0)
ffffffffc0200c22:	0791                	addi	a5,a5,4
ffffffffc0200c24:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200c28:	bfd9                	j	ffffffffc0200bfe <exception_handler+0x4a>
            cprintf("Misaligned instruction fetch at 0x%08lx\n", tf->epc);
ffffffffc0200c2a:	00002517          	auipc	a0,0x2
ffffffffc0200c2e:	e6e50513          	addi	a0,a0,-402 # ffffffffc0202a98 <commands+0x5f0>
ffffffffc0200c32:	cdcff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: misaligned instruction fetch\n");
ffffffffc0200c36:	00002517          	auipc	a0,0x2
ffffffffc0200c3a:	e9250513          	addi	a0,a0,-366 # ffffffffc0202ac8 <commands+0x620>
ffffffffc0200c3e:	cd0ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200c42:	10843783          	ld	a5,264(s0)
ffffffffc0200c46:	0791                	addi	a5,a5,4
ffffffffc0200c48:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200c4c:	bf4d                	j	ffffffffc0200bfe <exception_handler+0x4a>
            cprintf("Instruction access fault at 0x%08lx\n", tf->epc);
ffffffffc0200c4e:	00002517          	auipc	a0,0x2
ffffffffc0200c52:	eaa50513          	addi	a0,a0,-342 # ffffffffc0202af8 <commands+0x650>
ffffffffc0200c56:	cb8ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Instruction access fault\n");
ffffffffc0200c5a:	00002517          	auipc	a0,0x2
ffffffffc0200c5e:	ec650513          	addi	a0,a0,-314 # ffffffffc0202b20 <commands+0x678>
ffffffffc0200c62:	cacff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200c66:	10843783          	ld	a5,264(s0)
ffffffffc0200c6a:	0791                	addi	a5,a5,4
ffffffffc0200c6c:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200c70:	b779                	j	ffffffffc0200bfe <exception_handler+0x4a>
            cprintf("Illegal instruction caught at 0x%08lx\n", tf->epc);
ffffffffc0200c72:	00002517          	auipc	a0,0x2
ffffffffc0200c76:	ede50513          	addi	a0,a0,-290 # ffffffffc0202b50 <commands+0x6a8>
ffffffffc0200c7a:	c94ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200c7e:	00002517          	auipc	a0,0x2
ffffffffc0200c82:	efa50513          	addi	a0,a0,-262 # ffffffffc0202b78 <commands+0x6d0>
ffffffffc0200c86:	c88ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;  // 跳过非法指令，防止死循环
ffffffffc0200c8a:	10843783          	ld	a5,264(s0)
ffffffffc0200c8e:	0791                	addi	a5,a5,4
ffffffffc0200c90:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200c94:	b7ad                	j	ffffffffc0200bfe <exception_handler+0x4a>
            cprintf("ebreak caught at 0x%08lx\n", tf->epc);
ffffffffc0200c96:	00002517          	auipc	a0,0x2
ffffffffc0200c9a:	f0a50513          	addi	a0,a0,-246 # ffffffffc0202ba0 <commands+0x6f8>
ffffffffc0200c9e:	c70ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: breakpoint\n");
ffffffffc0200ca2:	00002517          	auipc	a0,0x2
ffffffffc0200ca6:	f1e50513          	addi	a0,a0,-226 # ffffffffc0202bc0 <commands+0x718>
ffffffffc0200caa:	c64ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 2;  // 跳过断点指令
ffffffffc0200cae:	10843783          	ld	a5,264(s0)
ffffffffc0200cb2:	0789                	addi	a5,a5,2
ffffffffc0200cb4:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200cb8:	b799                	j	ffffffffc0200bfe <exception_handler+0x4a>
            cprintf("Misaligned load at 0x%08lx\n", tf->epc);
ffffffffc0200cba:	00002517          	auipc	a0,0x2
ffffffffc0200cbe:	f2650513          	addi	a0,a0,-218 # ffffffffc0202be0 <commands+0x738>
ffffffffc0200cc2:	c4cff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: misaligned load\n");
ffffffffc0200cc6:	00002517          	auipc	a0,0x2
ffffffffc0200cca:	f3a50513          	addi	a0,a0,-198 # ffffffffc0202c00 <commands+0x758>
ffffffffc0200cce:	c40ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200cd2:	10843783          	ld	a5,264(s0)
ffffffffc0200cd6:	0791                	addi	a5,a5,4
ffffffffc0200cd8:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200cdc:	b70d                	j	ffffffffc0200bfe <exception_handler+0x4a>
            cprintf("Load access fault at 0x%08lx\n", tf->epc);
ffffffffc0200cde:	00002517          	auipc	a0,0x2
ffffffffc0200ce2:	f4a50513          	addi	a0,a0,-182 # ffffffffc0202c28 <commands+0x780>
ffffffffc0200ce6:	c28ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Load access fault\n");
ffffffffc0200cea:	00002517          	auipc	a0,0x2
ffffffffc0200cee:	f5e50513          	addi	a0,a0,-162 # ffffffffc0202c48 <commands+0x7a0>
ffffffffc0200cf2:	c1cff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200cf6:	10843783          	ld	a5,264(s0)
ffffffffc0200cfa:	0791                	addi	a5,a5,4
ffffffffc0200cfc:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200d00:	bdfd                	j	ffffffffc0200bfe <exception_handler+0x4a>
            cprintf("Misaligned store at 0x%08lx\n", tf->epc);
ffffffffc0200d02:	00002517          	auipc	a0,0x2
ffffffffc0200d06:	f6e50513          	addi	a0,a0,-146 # ffffffffc0202c70 <commands+0x7c8>
ffffffffc0200d0a:	c04ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: misaligned store\n");
ffffffffc0200d0e:	00002517          	auipc	a0,0x2
ffffffffc0200d12:	f8250513          	addi	a0,a0,-126 # ffffffffc0202c90 <commands+0x7e8>
ffffffffc0200d16:	bf8ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200d1a:	10843783          	ld	a5,264(s0)
ffffffffc0200d1e:	0791                	addi	a5,a5,4
ffffffffc0200d20:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200d24:	bde9                	j	ffffffffc0200bfe <exception_handler+0x4a>
            cprintf("Store access fault at 0x%08lx\n", tf->epc);
ffffffffc0200d26:	00002517          	auipc	a0,0x2
ffffffffc0200d2a:	f9250513          	addi	a0,a0,-110 # ffffffffc0202cb8 <commands+0x810>
ffffffffc0200d2e:	be0ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Store access fault\n");
ffffffffc0200d32:	00002517          	auipc	a0,0x2
ffffffffc0200d36:	fa650513          	addi	a0,a0,-90 # ffffffffc0202cd8 <commands+0x830>
ffffffffc0200d3a:	bd4ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200d3e:	10843783          	ld	a5,264(s0)
ffffffffc0200d42:	0791                	addi	a5,a5,4
ffffffffc0200d44:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200d48:	bd5d                	j	ffffffffc0200bfe <exception_handler+0x4a>
            cprintf("User ECALL at 0x%08lx\n", tf->epc);
ffffffffc0200d4a:	00002517          	auipc	a0,0x2
ffffffffc0200d4e:	fb650513          	addi	a0,a0,-74 # ffffffffc0202d00 <commands+0x858>
ffffffffc0200d52:	bbcff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: User ECALL\n");
ffffffffc0200d56:	00002517          	auipc	a0,0x2
ffffffffc0200d5a:	fc250513          	addi	a0,a0,-62 # ffffffffc0202d18 <commands+0x870>
ffffffffc0200d5e:	bb0ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200d62:	10843783          	ld	a5,264(s0)
ffffffffc0200d66:	0791                	addi	a5,a5,4
ffffffffc0200d68:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200d6c:	bd49                	j	ffffffffc0200bfe <exception_handler+0x4a>
            cprintf("Supervisor ECALL at 0x%08lx\n", tf->epc);
ffffffffc0200d6e:	00002517          	auipc	a0,0x2
ffffffffc0200d72:	fca50513          	addi	a0,a0,-54 # ffffffffc0202d38 <commands+0x890>
ffffffffc0200d76:	b98ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Supervisor ECALL\n");
ffffffffc0200d7a:	00002517          	auipc	a0,0x2
ffffffffc0200d7e:	fde50513          	addi	a0,a0,-34 # ffffffffc0202d58 <commands+0x8b0>
ffffffffc0200d82:	b8cff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200d86:	10843783          	ld	a5,264(s0)
ffffffffc0200d8a:	0791                	addi	a5,a5,4
ffffffffc0200d8c:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200d90:	b5bd                	j	ffffffffc0200bfe <exception_handler+0x4a>
            print_trapframe(tf);
ffffffffc0200d92:	cbfff0ef          	jal	ra,ffffffffc0200a50 <print_trapframe>
            cprintf("Unknown exception type: %ld\n", tf->cause);
ffffffffc0200d96:	11843583          	ld	a1,280(s0)
ffffffffc0200d9a:	00002517          	auipc	a0,0x2
ffffffffc0200d9e:	06e50513          	addi	a0,a0,110 # ffffffffc0202e08 <commands+0x960>
ffffffffc0200da2:	b6cff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200da6:	10843783          	ld	a5,264(s0)
ffffffffc0200daa:	0791                	addi	a5,a5,4
ffffffffc0200dac:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200db0:	b5b9                	j	ffffffffc0200bfe <exception_handler+0x4a>

ffffffffc0200db2 <trap>:


/* 分发 trap */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0)
ffffffffc0200db2:	11853783          	ld	a5,280(a0)
ffffffffc0200db6:	0007c363          	bltz	a5,ffffffffc0200dbc <trap+0xa>
        interrupt_handler(tf);
    else
        exception_handler(tf);
ffffffffc0200dba:	bbed                	j	ffffffffc0200bb4 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200dbc:	b9dd                	j	ffffffffc0200ab2 <interrupt_handler>
	...

ffffffffc0200dc0 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200dc0:	14011073          	csrw	sscratch,sp
ffffffffc0200dc4:	712d                	addi	sp,sp,-288
ffffffffc0200dc6:	e002                	sd	zero,0(sp)
ffffffffc0200dc8:	e406                	sd	ra,8(sp)
ffffffffc0200dca:	ec0e                	sd	gp,24(sp)
ffffffffc0200dcc:	f012                	sd	tp,32(sp)
ffffffffc0200dce:	f416                	sd	t0,40(sp)
ffffffffc0200dd0:	f81a                	sd	t1,48(sp)
ffffffffc0200dd2:	fc1e                	sd	t2,56(sp)
ffffffffc0200dd4:	e0a2                	sd	s0,64(sp)
ffffffffc0200dd6:	e4a6                	sd	s1,72(sp)
ffffffffc0200dd8:	e8aa                	sd	a0,80(sp)
ffffffffc0200dda:	ecae                	sd	a1,88(sp)
ffffffffc0200ddc:	f0b2                	sd	a2,96(sp)
ffffffffc0200dde:	f4b6                	sd	a3,104(sp)
ffffffffc0200de0:	f8ba                	sd	a4,112(sp)
ffffffffc0200de2:	fcbe                	sd	a5,120(sp)
ffffffffc0200de4:	e142                	sd	a6,128(sp)
ffffffffc0200de6:	e546                	sd	a7,136(sp)
ffffffffc0200de8:	e94a                	sd	s2,144(sp)
ffffffffc0200dea:	ed4e                	sd	s3,152(sp)
ffffffffc0200dec:	f152                	sd	s4,160(sp)
ffffffffc0200dee:	f556                	sd	s5,168(sp)
ffffffffc0200df0:	f95a                	sd	s6,176(sp)
ffffffffc0200df2:	fd5e                	sd	s7,184(sp)
ffffffffc0200df4:	e1e2                	sd	s8,192(sp)
ffffffffc0200df6:	e5e6                	sd	s9,200(sp)
ffffffffc0200df8:	e9ea                	sd	s10,208(sp)
ffffffffc0200dfa:	edee                	sd	s11,216(sp)
ffffffffc0200dfc:	f1f2                	sd	t3,224(sp)
ffffffffc0200dfe:	f5f6                	sd	t4,232(sp)
ffffffffc0200e00:	f9fa                	sd	t5,240(sp)
ffffffffc0200e02:	fdfe                	sd	t6,248(sp)
ffffffffc0200e04:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e08:	100024f3          	csrr	s1,sstatus
ffffffffc0200e0c:	14102973          	csrr	s2,sepc
ffffffffc0200e10:	143029f3          	csrr	s3,stval
ffffffffc0200e14:	14202a73          	csrr	s4,scause
ffffffffc0200e18:	e822                	sd	s0,16(sp)
ffffffffc0200e1a:	e226                	sd	s1,256(sp)
ffffffffc0200e1c:	e64a                	sd	s2,264(sp)
ffffffffc0200e1e:	ea4e                	sd	s3,272(sp)
ffffffffc0200e20:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e22:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e24:	f8fff0ef          	jal	ra,ffffffffc0200db2 <trap>

ffffffffc0200e28 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e28:	6492                	ld	s1,256(sp)
ffffffffc0200e2a:	6932                	ld	s2,264(sp)
ffffffffc0200e2c:	10049073          	csrw	sstatus,s1
ffffffffc0200e30:	14191073          	csrw	sepc,s2
ffffffffc0200e34:	60a2                	ld	ra,8(sp)
ffffffffc0200e36:	61e2                	ld	gp,24(sp)
ffffffffc0200e38:	7202                	ld	tp,32(sp)
ffffffffc0200e3a:	72a2                	ld	t0,40(sp)
ffffffffc0200e3c:	7342                	ld	t1,48(sp)
ffffffffc0200e3e:	73e2                	ld	t2,56(sp)
ffffffffc0200e40:	6406                	ld	s0,64(sp)
ffffffffc0200e42:	64a6                	ld	s1,72(sp)
ffffffffc0200e44:	6546                	ld	a0,80(sp)
ffffffffc0200e46:	65e6                	ld	a1,88(sp)
ffffffffc0200e48:	7606                	ld	a2,96(sp)
ffffffffc0200e4a:	76a6                	ld	a3,104(sp)
ffffffffc0200e4c:	7746                	ld	a4,112(sp)
ffffffffc0200e4e:	77e6                	ld	a5,120(sp)
ffffffffc0200e50:	680a                	ld	a6,128(sp)
ffffffffc0200e52:	68aa                	ld	a7,136(sp)
ffffffffc0200e54:	694a                	ld	s2,144(sp)
ffffffffc0200e56:	69ea                	ld	s3,152(sp)
ffffffffc0200e58:	7a0a                	ld	s4,160(sp)
ffffffffc0200e5a:	7aaa                	ld	s5,168(sp)
ffffffffc0200e5c:	7b4a                	ld	s6,176(sp)
ffffffffc0200e5e:	7bea                	ld	s7,184(sp)
ffffffffc0200e60:	6c0e                	ld	s8,192(sp)
ffffffffc0200e62:	6cae                	ld	s9,200(sp)
ffffffffc0200e64:	6d4e                	ld	s10,208(sp)
ffffffffc0200e66:	6dee                	ld	s11,216(sp)
ffffffffc0200e68:	7e0e                	ld	t3,224(sp)
ffffffffc0200e6a:	7eae                	ld	t4,232(sp)
ffffffffc0200e6c:	7f4e                	ld	t5,240(sp)
ffffffffc0200e6e:	7fee                	ld	t6,248(sp)
ffffffffc0200e70:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200e72:	10200073          	sret

ffffffffc0200e76 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e76:	00006797          	auipc	a5,0x6
ffffffffc0200e7a:	1b278793          	addi	a5,a5,434 # ffffffffc0207028 <free_area>
ffffffffc0200e7e:	e79c                	sd	a5,8(a5)
ffffffffc0200e80:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e82:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e86:	8082                	ret

ffffffffc0200e88 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200e88:	00006517          	auipc	a0,0x6
ffffffffc0200e8c:	1b056503          	lwu	a0,432(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200e90:	8082                	ret

ffffffffc0200e92 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e92:	715d                	addi	sp,sp,-80
ffffffffc0200e94:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e96:	00006417          	auipc	s0,0x6
ffffffffc0200e9a:	19240413          	addi	s0,s0,402 # ffffffffc0207028 <free_area>
ffffffffc0200e9e:	641c                	ld	a5,8(s0)
ffffffffc0200ea0:	e486                	sd	ra,72(sp)
ffffffffc0200ea2:	fc26                	sd	s1,56(sp)
ffffffffc0200ea4:	f84a                	sd	s2,48(sp)
ffffffffc0200ea6:	f44e                	sd	s3,40(sp)
ffffffffc0200ea8:	f052                	sd	s4,32(sp)
ffffffffc0200eaa:	ec56                	sd	s5,24(sp)
ffffffffc0200eac:	e85a                	sd	s6,16(sp)
ffffffffc0200eae:	e45e                	sd	s7,8(sp)
ffffffffc0200eb0:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eb2:	2c878763          	beq	a5,s0,ffffffffc0201180 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200eb6:	4481                	li	s1,0
ffffffffc0200eb8:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200eba:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ebe:	8b09                	andi	a4,a4,2
ffffffffc0200ec0:	2c070463          	beqz	a4,ffffffffc0201188 <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200ec4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ec8:	679c                	ld	a5,8(a5)
ffffffffc0200eca:	2905                	addiw	s2,s2,1
ffffffffc0200ecc:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ece:	fe8796e3          	bne	a5,s0,ffffffffc0200eba <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200ed2:	89a6                	mv	s3,s1
ffffffffc0200ed4:	2f9000ef          	jal	ra,ffffffffc02019cc <nr_free_pages>
ffffffffc0200ed8:	71351863          	bne	a0,s3,ffffffffc02015e8 <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200edc:	4505                	li	a0,1
ffffffffc0200ede:	271000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0200ee2:	8a2a                	mv	s4,a0
ffffffffc0200ee4:	44050263          	beqz	a0,ffffffffc0201328 <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ee8:	4505                	li	a0,1
ffffffffc0200eea:	265000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0200eee:	89aa                	mv	s3,a0
ffffffffc0200ef0:	70050c63          	beqz	a0,ffffffffc0201608 <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ef4:	4505                	li	a0,1
ffffffffc0200ef6:	259000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0200efa:	8aaa                	mv	s5,a0
ffffffffc0200efc:	4a050663          	beqz	a0,ffffffffc02013a8 <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f00:	2b3a0463          	beq	s4,s3,ffffffffc02011a8 <default_check+0x316>
ffffffffc0200f04:	2aaa0263          	beq	s4,a0,ffffffffc02011a8 <default_check+0x316>
ffffffffc0200f08:	2aa98063          	beq	s3,a0,ffffffffc02011a8 <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f0c:	000a2783          	lw	a5,0(s4)
ffffffffc0200f10:	2a079c63          	bnez	a5,ffffffffc02011c8 <default_check+0x336>
ffffffffc0200f14:	0009a783          	lw	a5,0(s3)
ffffffffc0200f18:	2a079863          	bnez	a5,ffffffffc02011c8 <default_check+0x336>
ffffffffc0200f1c:	411c                	lw	a5,0(a0)
ffffffffc0200f1e:	2a079563          	bnez	a5,ffffffffc02011c8 <default_check+0x336>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f22:	00006797          	auipc	a5,0x6
ffffffffc0200f26:	54e7b783          	ld	a5,1358(a5) # ffffffffc0207470 <pages>
ffffffffc0200f2a:	40fa0733          	sub	a4,s4,a5
ffffffffc0200f2e:	870d                	srai	a4,a4,0x3
ffffffffc0200f30:	00002597          	auipc	a1,0x2
ffffffffc0200f34:	6b05b583          	ld	a1,1712(a1) # ffffffffc02035e0 <error_string+0x38>
ffffffffc0200f38:	02b70733          	mul	a4,a4,a1
ffffffffc0200f3c:	00002617          	auipc	a2,0x2
ffffffffc0200f40:	6ac63603          	ld	a2,1708(a2) # ffffffffc02035e8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f44:	00006697          	auipc	a3,0x6
ffffffffc0200f48:	5246b683          	ld	a3,1316(a3) # ffffffffc0207468 <npage>
ffffffffc0200f4c:	06b2                	slli	a3,a3,0xc
ffffffffc0200f4e:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f50:	0732                	slli	a4,a4,0xc
ffffffffc0200f52:	28d77b63          	bgeu	a4,a3,ffffffffc02011e8 <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f56:	40f98733          	sub	a4,s3,a5
ffffffffc0200f5a:	870d                	srai	a4,a4,0x3
ffffffffc0200f5c:	02b70733          	mul	a4,a4,a1
ffffffffc0200f60:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f62:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f64:	4cd77263          	bgeu	a4,a3,ffffffffc0201428 <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f68:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f6c:	878d                	srai	a5,a5,0x3
ffffffffc0200f6e:	02b787b3          	mul	a5,a5,a1
ffffffffc0200f72:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f74:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f76:	30d7f963          	bgeu	a5,a3,ffffffffc0201288 <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200f7a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f7c:	00043c03          	ld	s8,0(s0)
ffffffffc0200f80:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f84:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200f88:	e400                	sd	s0,8(s0)
ffffffffc0200f8a:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200f8c:	00006797          	auipc	a5,0x6
ffffffffc0200f90:	0a07a623          	sw	zero,172(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f94:	1bb000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0200f98:	2c051863          	bnez	a0,ffffffffc0201268 <default_check+0x3d6>
    free_page(p0);
ffffffffc0200f9c:	4585                	li	a1,1
ffffffffc0200f9e:	8552                	mv	a0,s4
ffffffffc0200fa0:	1ed000ef          	jal	ra,ffffffffc020198c <free_pages>
    free_page(p1);
ffffffffc0200fa4:	4585                	li	a1,1
ffffffffc0200fa6:	854e                	mv	a0,s3
ffffffffc0200fa8:	1e5000ef          	jal	ra,ffffffffc020198c <free_pages>
    free_page(p2);
ffffffffc0200fac:	4585                	li	a1,1
ffffffffc0200fae:	8556                	mv	a0,s5
ffffffffc0200fb0:	1dd000ef          	jal	ra,ffffffffc020198c <free_pages>
    assert(nr_free == 3);
ffffffffc0200fb4:	4818                	lw	a4,16(s0)
ffffffffc0200fb6:	478d                	li	a5,3
ffffffffc0200fb8:	28f71863          	bne	a4,a5,ffffffffc0201248 <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fbc:	4505                	li	a0,1
ffffffffc0200fbe:	191000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0200fc2:	89aa                	mv	s3,a0
ffffffffc0200fc4:	26050263          	beqz	a0,ffffffffc0201228 <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fc8:	4505                	li	a0,1
ffffffffc0200fca:	185000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0200fce:	8aaa                	mv	s5,a0
ffffffffc0200fd0:	3a050c63          	beqz	a0,ffffffffc0201388 <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fd4:	4505                	li	a0,1
ffffffffc0200fd6:	179000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0200fda:	8a2a                	mv	s4,a0
ffffffffc0200fdc:	38050663          	beqz	a0,ffffffffc0201368 <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0200fe0:	4505                	li	a0,1
ffffffffc0200fe2:	16d000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0200fe6:	36051163          	bnez	a0,ffffffffc0201348 <default_check+0x4b6>
    free_page(p0);
ffffffffc0200fea:	4585                	li	a1,1
ffffffffc0200fec:	854e                	mv	a0,s3
ffffffffc0200fee:	19f000ef          	jal	ra,ffffffffc020198c <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ff2:	641c                	ld	a5,8(s0)
ffffffffc0200ff4:	20878a63          	beq	a5,s0,ffffffffc0201208 <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0200ff8:	4505                	li	a0,1
ffffffffc0200ffa:	155000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0200ffe:	30a99563          	bne	s3,a0,ffffffffc0201308 <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0201002:	4505                	li	a0,1
ffffffffc0201004:	14b000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0201008:	2e051063          	bnez	a0,ffffffffc02012e8 <default_check+0x456>
    assert(nr_free == 0);
ffffffffc020100c:	481c                	lw	a5,16(s0)
ffffffffc020100e:	2a079d63          	bnez	a5,ffffffffc02012c8 <default_check+0x436>
    free_page(p);
ffffffffc0201012:	854e                	mv	a0,s3
ffffffffc0201014:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201016:	01843023          	sd	s8,0(s0)
ffffffffc020101a:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020101e:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201022:	16b000ef          	jal	ra,ffffffffc020198c <free_pages>
    free_page(p1);
ffffffffc0201026:	4585                	li	a1,1
ffffffffc0201028:	8556                	mv	a0,s5
ffffffffc020102a:	163000ef          	jal	ra,ffffffffc020198c <free_pages>
    free_page(p2);
ffffffffc020102e:	4585                	li	a1,1
ffffffffc0201030:	8552                	mv	a0,s4
ffffffffc0201032:	15b000ef          	jal	ra,ffffffffc020198c <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201036:	4515                	li	a0,5
ffffffffc0201038:	117000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc020103c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020103e:	26050563          	beqz	a0,ffffffffc02012a8 <default_check+0x416>
ffffffffc0201042:	651c                	ld	a5,8(a0)
ffffffffc0201044:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0201046:	8b85                	andi	a5,a5,1
ffffffffc0201048:	54079063          	bnez	a5,ffffffffc0201588 <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020104c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020104e:	00043b03          	ld	s6,0(s0)
ffffffffc0201052:	00843a83          	ld	s5,8(s0)
ffffffffc0201056:	e000                	sd	s0,0(s0)
ffffffffc0201058:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc020105a:	0f5000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc020105e:	50051563          	bnez	a0,ffffffffc0201568 <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201062:	05098a13          	addi	s4,s3,80
ffffffffc0201066:	8552                	mv	a0,s4
ffffffffc0201068:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc020106a:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020106e:	00006797          	auipc	a5,0x6
ffffffffc0201072:	fc07a523          	sw	zero,-54(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201076:	117000ef          	jal	ra,ffffffffc020198c <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020107a:	4511                	li	a0,4
ffffffffc020107c:	0d3000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0201080:	4c051463          	bnez	a0,ffffffffc0201548 <default_check+0x6b6>
ffffffffc0201084:	0589b783          	ld	a5,88(s3)
ffffffffc0201088:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020108a:	8b85                	andi	a5,a5,1
ffffffffc020108c:	48078e63          	beqz	a5,ffffffffc0201528 <default_check+0x696>
ffffffffc0201090:	0609a703          	lw	a4,96(s3)
ffffffffc0201094:	478d                	li	a5,3
ffffffffc0201096:	48f71963          	bne	a4,a5,ffffffffc0201528 <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020109a:	450d                	li	a0,3
ffffffffc020109c:	0b3000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc02010a0:	8c2a                	mv	s8,a0
ffffffffc02010a2:	46050363          	beqz	a0,ffffffffc0201508 <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc02010a6:	4505                	li	a0,1
ffffffffc02010a8:	0a7000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc02010ac:	42051e63          	bnez	a0,ffffffffc02014e8 <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc02010b0:	418a1c63          	bne	s4,s8,ffffffffc02014c8 <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010b4:	4585                	li	a1,1
ffffffffc02010b6:	854e                	mv	a0,s3
ffffffffc02010b8:	0d5000ef          	jal	ra,ffffffffc020198c <free_pages>
    free_pages(p1, 3);
ffffffffc02010bc:	458d                	li	a1,3
ffffffffc02010be:	8552                	mv	a0,s4
ffffffffc02010c0:	0cd000ef          	jal	ra,ffffffffc020198c <free_pages>
ffffffffc02010c4:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02010c8:	02898c13          	addi	s8,s3,40
ffffffffc02010cc:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010ce:	8b85                	andi	a5,a5,1
ffffffffc02010d0:	3c078c63          	beqz	a5,ffffffffc02014a8 <default_check+0x616>
ffffffffc02010d4:	0109a703          	lw	a4,16(s3)
ffffffffc02010d8:	4785                	li	a5,1
ffffffffc02010da:	3cf71763          	bne	a4,a5,ffffffffc02014a8 <default_check+0x616>
ffffffffc02010de:	008a3783          	ld	a5,8(s4)
ffffffffc02010e2:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02010e4:	8b85                	andi	a5,a5,1
ffffffffc02010e6:	3a078163          	beqz	a5,ffffffffc0201488 <default_check+0x5f6>
ffffffffc02010ea:	010a2703          	lw	a4,16(s4)
ffffffffc02010ee:	478d                	li	a5,3
ffffffffc02010f0:	38f71c63          	bne	a4,a5,ffffffffc0201488 <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02010f4:	4505                	li	a0,1
ffffffffc02010f6:	059000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc02010fa:	36a99763          	bne	s3,a0,ffffffffc0201468 <default_check+0x5d6>
    free_page(p0);
ffffffffc02010fe:	4585                	li	a1,1
ffffffffc0201100:	08d000ef          	jal	ra,ffffffffc020198c <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201104:	4509                	li	a0,2
ffffffffc0201106:	049000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc020110a:	32aa1f63          	bne	s4,a0,ffffffffc0201448 <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc020110e:	4589                	li	a1,2
ffffffffc0201110:	07d000ef          	jal	ra,ffffffffc020198c <free_pages>
    free_page(p2);
ffffffffc0201114:	4585                	li	a1,1
ffffffffc0201116:	8562                	mv	a0,s8
ffffffffc0201118:	075000ef          	jal	ra,ffffffffc020198c <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020111c:	4515                	li	a0,5
ffffffffc020111e:	031000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc0201122:	89aa                	mv	s3,a0
ffffffffc0201124:	48050263          	beqz	a0,ffffffffc02015a8 <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0201128:	4505                	li	a0,1
ffffffffc020112a:	025000ef          	jal	ra,ffffffffc020194e <alloc_pages>
ffffffffc020112e:	2c051d63          	bnez	a0,ffffffffc0201408 <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0201132:	481c                	lw	a5,16(s0)
ffffffffc0201134:	2a079a63          	bnez	a5,ffffffffc02013e8 <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201138:	4595                	li	a1,5
ffffffffc020113a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020113c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201140:	01643023          	sd	s6,0(s0)
ffffffffc0201144:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201148:	045000ef          	jal	ra,ffffffffc020198c <free_pages>
    return listelm->next;
ffffffffc020114c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020114e:	00878963          	beq	a5,s0,ffffffffc0201160 <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201152:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201156:	679c                	ld	a5,8(a5)
ffffffffc0201158:	397d                	addiw	s2,s2,-1
ffffffffc020115a:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020115c:	fe879be3          	bne	a5,s0,ffffffffc0201152 <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0201160:	26091463          	bnez	s2,ffffffffc02013c8 <default_check+0x536>
    assert(total == 0);
ffffffffc0201164:	46049263          	bnez	s1,ffffffffc02015c8 <default_check+0x736>
}
ffffffffc0201168:	60a6                	ld	ra,72(sp)
ffffffffc020116a:	6406                	ld	s0,64(sp)
ffffffffc020116c:	74e2                	ld	s1,56(sp)
ffffffffc020116e:	7942                	ld	s2,48(sp)
ffffffffc0201170:	79a2                	ld	s3,40(sp)
ffffffffc0201172:	7a02                	ld	s4,32(sp)
ffffffffc0201174:	6ae2                	ld	s5,24(sp)
ffffffffc0201176:	6b42                	ld	s6,16(sp)
ffffffffc0201178:	6ba2                	ld	s7,8(sp)
ffffffffc020117a:	6c02                	ld	s8,0(sp)
ffffffffc020117c:	6161                	addi	sp,sp,80
ffffffffc020117e:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201180:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201182:	4481                	li	s1,0
ffffffffc0201184:	4901                	li	s2,0
ffffffffc0201186:	b3b9                	j	ffffffffc0200ed4 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201188:	00002697          	auipc	a3,0x2
ffffffffc020118c:	cd068693          	addi	a3,a3,-816 # ffffffffc0202e58 <commands+0x9b0>
ffffffffc0201190:	00002617          	auipc	a2,0x2
ffffffffc0201194:	cd860613          	addi	a2,a2,-808 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201198:	0f000593          	li	a1,240
ffffffffc020119c:	00002517          	auipc	a0,0x2
ffffffffc02011a0:	ce450513          	addi	a0,a0,-796 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02011a4:	a64ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011a8:	00002697          	auipc	a3,0x2
ffffffffc02011ac:	d7068693          	addi	a3,a3,-656 # ffffffffc0202f18 <commands+0xa70>
ffffffffc02011b0:	00002617          	auipc	a2,0x2
ffffffffc02011b4:	cb860613          	addi	a2,a2,-840 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02011b8:	0bd00593          	li	a1,189
ffffffffc02011bc:	00002517          	auipc	a0,0x2
ffffffffc02011c0:	cc450513          	addi	a0,a0,-828 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02011c4:	a44ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011c8:	00002697          	auipc	a3,0x2
ffffffffc02011cc:	d7868693          	addi	a3,a3,-648 # ffffffffc0202f40 <commands+0xa98>
ffffffffc02011d0:	00002617          	auipc	a2,0x2
ffffffffc02011d4:	c9860613          	addi	a2,a2,-872 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02011d8:	0be00593          	li	a1,190
ffffffffc02011dc:	00002517          	auipc	a0,0x2
ffffffffc02011e0:	ca450513          	addi	a0,a0,-860 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02011e4:	a24ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02011e8:	00002697          	auipc	a3,0x2
ffffffffc02011ec:	d9868693          	addi	a3,a3,-616 # ffffffffc0202f80 <commands+0xad8>
ffffffffc02011f0:	00002617          	auipc	a2,0x2
ffffffffc02011f4:	c7860613          	addi	a2,a2,-904 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02011f8:	0c000593          	li	a1,192
ffffffffc02011fc:	00002517          	auipc	a0,0x2
ffffffffc0201200:	c8450513          	addi	a0,a0,-892 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201204:	a04ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201208:	00002697          	auipc	a3,0x2
ffffffffc020120c:	e0068693          	addi	a3,a3,-512 # ffffffffc0203008 <commands+0xb60>
ffffffffc0201210:	00002617          	auipc	a2,0x2
ffffffffc0201214:	c5860613          	addi	a2,a2,-936 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201218:	0d900593          	li	a1,217
ffffffffc020121c:	00002517          	auipc	a0,0x2
ffffffffc0201220:	c6450513          	addi	a0,a0,-924 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201224:	9e4ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201228:	00002697          	auipc	a3,0x2
ffffffffc020122c:	c9068693          	addi	a3,a3,-880 # ffffffffc0202eb8 <commands+0xa10>
ffffffffc0201230:	00002617          	auipc	a2,0x2
ffffffffc0201234:	c3860613          	addi	a2,a2,-968 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201238:	0d200593          	li	a1,210
ffffffffc020123c:	00002517          	auipc	a0,0x2
ffffffffc0201240:	c4450513          	addi	a0,a0,-956 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201244:	9c4ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(nr_free == 3);
ffffffffc0201248:	00002697          	auipc	a3,0x2
ffffffffc020124c:	db068693          	addi	a3,a3,-592 # ffffffffc0202ff8 <commands+0xb50>
ffffffffc0201250:	00002617          	auipc	a2,0x2
ffffffffc0201254:	c1860613          	addi	a2,a2,-1000 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201258:	0d000593          	li	a1,208
ffffffffc020125c:	00002517          	auipc	a0,0x2
ffffffffc0201260:	c2450513          	addi	a0,a0,-988 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201264:	9a4ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201268:	00002697          	auipc	a3,0x2
ffffffffc020126c:	d7868693          	addi	a3,a3,-648 # ffffffffc0202fe0 <commands+0xb38>
ffffffffc0201270:	00002617          	auipc	a2,0x2
ffffffffc0201274:	bf860613          	addi	a2,a2,-1032 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201278:	0cb00593          	li	a1,203
ffffffffc020127c:	00002517          	auipc	a0,0x2
ffffffffc0201280:	c0450513          	addi	a0,a0,-1020 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201284:	984ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201288:	00002697          	auipc	a3,0x2
ffffffffc020128c:	d3868693          	addi	a3,a3,-712 # ffffffffc0202fc0 <commands+0xb18>
ffffffffc0201290:	00002617          	auipc	a2,0x2
ffffffffc0201294:	bd860613          	addi	a2,a2,-1064 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201298:	0c200593          	li	a1,194
ffffffffc020129c:	00002517          	auipc	a0,0x2
ffffffffc02012a0:	be450513          	addi	a0,a0,-1052 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02012a4:	964ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(p0 != NULL);
ffffffffc02012a8:	00002697          	auipc	a3,0x2
ffffffffc02012ac:	da868693          	addi	a3,a3,-600 # ffffffffc0203050 <commands+0xba8>
ffffffffc02012b0:	00002617          	auipc	a2,0x2
ffffffffc02012b4:	bb860613          	addi	a2,a2,-1096 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02012b8:	0f800593          	li	a1,248
ffffffffc02012bc:	00002517          	auipc	a0,0x2
ffffffffc02012c0:	bc450513          	addi	a0,a0,-1084 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02012c4:	944ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(nr_free == 0);
ffffffffc02012c8:	00002697          	auipc	a3,0x2
ffffffffc02012cc:	d7868693          	addi	a3,a3,-648 # ffffffffc0203040 <commands+0xb98>
ffffffffc02012d0:	00002617          	auipc	a2,0x2
ffffffffc02012d4:	b9860613          	addi	a2,a2,-1128 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02012d8:	0df00593          	li	a1,223
ffffffffc02012dc:	00002517          	auipc	a0,0x2
ffffffffc02012e0:	ba450513          	addi	a0,a0,-1116 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02012e4:	924ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012e8:	00002697          	auipc	a3,0x2
ffffffffc02012ec:	cf868693          	addi	a3,a3,-776 # ffffffffc0202fe0 <commands+0xb38>
ffffffffc02012f0:	00002617          	auipc	a2,0x2
ffffffffc02012f4:	b7860613          	addi	a2,a2,-1160 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02012f8:	0dd00593          	li	a1,221
ffffffffc02012fc:	00002517          	auipc	a0,0x2
ffffffffc0201300:	b8450513          	addi	a0,a0,-1148 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201304:	904ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201308:	00002697          	auipc	a3,0x2
ffffffffc020130c:	d1868693          	addi	a3,a3,-744 # ffffffffc0203020 <commands+0xb78>
ffffffffc0201310:	00002617          	auipc	a2,0x2
ffffffffc0201314:	b5860613          	addi	a2,a2,-1192 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201318:	0dc00593          	li	a1,220
ffffffffc020131c:	00002517          	auipc	a0,0x2
ffffffffc0201320:	b6450513          	addi	a0,a0,-1180 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201324:	8e4ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201328:	00002697          	auipc	a3,0x2
ffffffffc020132c:	b9068693          	addi	a3,a3,-1136 # ffffffffc0202eb8 <commands+0xa10>
ffffffffc0201330:	00002617          	auipc	a2,0x2
ffffffffc0201334:	b3860613          	addi	a2,a2,-1224 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201338:	0b900593          	li	a1,185
ffffffffc020133c:	00002517          	auipc	a0,0x2
ffffffffc0201340:	b4450513          	addi	a0,a0,-1212 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201344:	8c4ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201348:	00002697          	auipc	a3,0x2
ffffffffc020134c:	c9868693          	addi	a3,a3,-872 # ffffffffc0202fe0 <commands+0xb38>
ffffffffc0201350:	00002617          	auipc	a2,0x2
ffffffffc0201354:	b1860613          	addi	a2,a2,-1256 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201358:	0d600593          	li	a1,214
ffffffffc020135c:	00002517          	auipc	a0,0x2
ffffffffc0201360:	b2450513          	addi	a0,a0,-1244 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201364:	8a4ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201368:	00002697          	auipc	a3,0x2
ffffffffc020136c:	b9068693          	addi	a3,a3,-1136 # ffffffffc0202ef8 <commands+0xa50>
ffffffffc0201370:	00002617          	auipc	a2,0x2
ffffffffc0201374:	af860613          	addi	a2,a2,-1288 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201378:	0d400593          	li	a1,212
ffffffffc020137c:	00002517          	auipc	a0,0x2
ffffffffc0201380:	b0450513          	addi	a0,a0,-1276 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201384:	884ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201388:	00002697          	auipc	a3,0x2
ffffffffc020138c:	b5068693          	addi	a3,a3,-1200 # ffffffffc0202ed8 <commands+0xa30>
ffffffffc0201390:	00002617          	auipc	a2,0x2
ffffffffc0201394:	ad860613          	addi	a2,a2,-1320 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201398:	0d300593          	li	a1,211
ffffffffc020139c:	00002517          	auipc	a0,0x2
ffffffffc02013a0:	ae450513          	addi	a0,a0,-1308 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02013a4:	864ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013a8:	00002697          	auipc	a3,0x2
ffffffffc02013ac:	b5068693          	addi	a3,a3,-1200 # ffffffffc0202ef8 <commands+0xa50>
ffffffffc02013b0:	00002617          	auipc	a2,0x2
ffffffffc02013b4:	ab860613          	addi	a2,a2,-1352 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02013b8:	0bb00593          	li	a1,187
ffffffffc02013bc:	00002517          	auipc	a0,0x2
ffffffffc02013c0:	ac450513          	addi	a0,a0,-1340 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02013c4:	844ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(count == 0);
ffffffffc02013c8:	00002697          	auipc	a3,0x2
ffffffffc02013cc:	dd868693          	addi	a3,a3,-552 # ffffffffc02031a0 <commands+0xcf8>
ffffffffc02013d0:	00002617          	auipc	a2,0x2
ffffffffc02013d4:	a9860613          	addi	a2,a2,-1384 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02013d8:	12500593          	li	a1,293
ffffffffc02013dc:	00002517          	auipc	a0,0x2
ffffffffc02013e0:	aa450513          	addi	a0,a0,-1372 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02013e4:	824ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(nr_free == 0);
ffffffffc02013e8:	00002697          	auipc	a3,0x2
ffffffffc02013ec:	c5868693          	addi	a3,a3,-936 # ffffffffc0203040 <commands+0xb98>
ffffffffc02013f0:	00002617          	auipc	a2,0x2
ffffffffc02013f4:	a7860613          	addi	a2,a2,-1416 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02013f8:	11a00593          	li	a1,282
ffffffffc02013fc:	00002517          	auipc	a0,0x2
ffffffffc0201400:	a8450513          	addi	a0,a0,-1404 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201404:	804ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201408:	00002697          	auipc	a3,0x2
ffffffffc020140c:	bd868693          	addi	a3,a3,-1064 # ffffffffc0202fe0 <commands+0xb38>
ffffffffc0201410:	00002617          	auipc	a2,0x2
ffffffffc0201414:	a5860613          	addi	a2,a2,-1448 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201418:	11800593          	li	a1,280
ffffffffc020141c:	00002517          	auipc	a0,0x2
ffffffffc0201420:	a6450513          	addi	a0,a0,-1436 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201424:	fe5fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201428:	00002697          	auipc	a3,0x2
ffffffffc020142c:	b7868693          	addi	a3,a3,-1160 # ffffffffc0202fa0 <commands+0xaf8>
ffffffffc0201430:	00002617          	auipc	a2,0x2
ffffffffc0201434:	a3860613          	addi	a2,a2,-1480 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201438:	0c100593          	li	a1,193
ffffffffc020143c:	00002517          	auipc	a0,0x2
ffffffffc0201440:	a4450513          	addi	a0,a0,-1468 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201444:	fc5fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201448:	00002697          	auipc	a3,0x2
ffffffffc020144c:	d1868693          	addi	a3,a3,-744 # ffffffffc0203160 <commands+0xcb8>
ffffffffc0201450:	00002617          	auipc	a2,0x2
ffffffffc0201454:	a1860613          	addi	a2,a2,-1512 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201458:	11200593          	li	a1,274
ffffffffc020145c:	00002517          	auipc	a0,0x2
ffffffffc0201460:	a2450513          	addi	a0,a0,-1500 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201464:	fa5fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201468:	00002697          	auipc	a3,0x2
ffffffffc020146c:	cd868693          	addi	a3,a3,-808 # ffffffffc0203140 <commands+0xc98>
ffffffffc0201470:	00002617          	auipc	a2,0x2
ffffffffc0201474:	9f860613          	addi	a2,a2,-1544 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201478:	11000593          	li	a1,272
ffffffffc020147c:	00002517          	auipc	a0,0x2
ffffffffc0201480:	a0450513          	addi	a0,a0,-1532 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201484:	f85fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201488:	00002697          	auipc	a3,0x2
ffffffffc020148c:	c9068693          	addi	a3,a3,-880 # ffffffffc0203118 <commands+0xc70>
ffffffffc0201490:	00002617          	auipc	a2,0x2
ffffffffc0201494:	9d860613          	addi	a2,a2,-1576 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201498:	10e00593          	li	a1,270
ffffffffc020149c:	00002517          	auipc	a0,0x2
ffffffffc02014a0:	9e450513          	addi	a0,a0,-1564 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02014a4:	f65fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014a8:	00002697          	auipc	a3,0x2
ffffffffc02014ac:	c4868693          	addi	a3,a3,-952 # ffffffffc02030f0 <commands+0xc48>
ffffffffc02014b0:	00002617          	auipc	a2,0x2
ffffffffc02014b4:	9b860613          	addi	a2,a2,-1608 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02014b8:	10d00593          	li	a1,269
ffffffffc02014bc:	00002517          	auipc	a0,0x2
ffffffffc02014c0:	9c450513          	addi	a0,a0,-1596 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02014c4:	f45fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014c8:	00002697          	auipc	a3,0x2
ffffffffc02014cc:	c1868693          	addi	a3,a3,-1000 # ffffffffc02030e0 <commands+0xc38>
ffffffffc02014d0:	00002617          	auipc	a2,0x2
ffffffffc02014d4:	99860613          	addi	a2,a2,-1640 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02014d8:	10800593          	li	a1,264
ffffffffc02014dc:	00002517          	auipc	a0,0x2
ffffffffc02014e0:	9a450513          	addi	a0,a0,-1628 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02014e4:	f25fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014e8:	00002697          	auipc	a3,0x2
ffffffffc02014ec:	af868693          	addi	a3,a3,-1288 # ffffffffc0202fe0 <commands+0xb38>
ffffffffc02014f0:	00002617          	auipc	a2,0x2
ffffffffc02014f4:	97860613          	addi	a2,a2,-1672 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02014f8:	10700593          	li	a1,263
ffffffffc02014fc:	00002517          	auipc	a0,0x2
ffffffffc0201500:	98450513          	addi	a0,a0,-1660 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201504:	f05fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201508:	00002697          	auipc	a3,0x2
ffffffffc020150c:	bb868693          	addi	a3,a3,-1096 # ffffffffc02030c0 <commands+0xc18>
ffffffffc0201510:	00002617          	auipc	a2,0x2
ffffffffc0201514:	95860613          	addi	a2,a2,-1704 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201518:	10600593          	li	a1,262
ffffffffc020151c:	00002517          	auipc	a0,0x2
ffffffffc0201520:	96450513          	addi	a0,a0,-1692 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201524:	ee5fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201528:	00002697          	auipc	a3,0x2
ffffffffc020152c:	b6868693          	addi	a3,a3,-1176 # ffffffffc0203090 <commands+0xbe8>
ffffffffc0201530:	00002617          	auipc	a2,0x2
ffffffffc0201534:	93860613          	addi	a2,a2,-1736 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201538:	10500593          	li	a1,261
ffffffffc020153c:	00002517          	auipc	a0,0x2
ffffffffc0201540:	94450513          	addi	a0,a0,-1724 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201544:	ec5fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201548:	00002697          	auipc	a3,0x2
ffffffffc020154c:	b3068693          	addi	a3,a3,-1232 # ffffffffc0203078 <commands+0xbd0>
ffffffffc0201550:	00002617          	auipc	a2,0x2
ffffffffc0201554:	91860613          	addi	a2,a2,-1768 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201558:	10400593          	li	a1,260
ffffffffc020155c:	00002517          	auipc	a0,0x2
ffffffffc0201560:	92450513          	addi	a0,a0,-1756 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201564:	ea5fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201568:	00002697          	auipc	a3,0x2
ffffffffc020156c:	a7868693          	addi	a3,a3,-1416 # ffffffffc0202fe0 <commands+0xb38>
ffffffffc0201570:	00002617          	auipc	a2,0x2
ffffffffc0201574:	8f860613          	addi	a2,a2,-1800 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201578:	0fe00593          	li	a1,254
ffffffffc020157c:	00002517          	auipc	a0,0x2
ffffffffc0201580:	90450513          	addi	a0,a0,-1788 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201584:	e85fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201588:	00002697          	auipc	a3,0x2
ffffffffc020158c:	ad868693          	addi	a3,a3,-1320 # ffffffffc0203060 <commands+0xbb8>
ffffffffc0201590:	00002617          	auipc	a2,0x2
ffffffffc0201594:	8d860613          	addi	a2,a2,-1832 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201598:	0f900593          	li	a1,249
ffffffffc020159c:	00002517          	auipc	a0,0x2
ffffffffc02015a0:	8e450513          	addi	a0,a0,-1820 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02015a4:	e65fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015a8:	00002697          	auipc	a3,0x2
ffffffffc02015ac:	bd868693          	addi	a3,a3,-1064 # ffffffffc0203180 <commands+0xcd8>
ffffffffc02015b0:	00002617          	auipc	a2,0x2
ffffffffc02015b4:	8b860613          	addi	a2,a2,-1864 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02015b8:	11700593          	li	a1,279
ffffffffc02015bc:	00002517          	auipc	a0,0x2
ffffffffc02015c0:	8c450513          	addi	a0,a0,-1852 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02015c4:	e45fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(total == 0);
ffffffffc02015c8:	00002697          	auipc	a3,0x2
ffffffffc02015cc:	be868693          	addi	a3,a3,-1048 # ffffffffc02031b0 <commands+0xd08>
ffffffffc02015d0:	00002617          	auipc	a2,0x2
ffffffffc02015d4:	89860613          	addi	a2,a2,-1896 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02015d8:	12600593          	li	a1,294
ffffffffc02015dc:	00002517          	auipc	a0,0x2
ffffffffc02015e0:	8a450513          	addi	a0,a0,-1884 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc02015e4:	e25fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(total == nr_free_pages());
ffffffffc02015e8:	00002697          	auipc	a3,0x2
ffffffffc02015ec:	8b068693          	addi	a3,a3,-1872 # ffffffffc0202e98 <commands+0x9f0>
ffffffffc02015f0:	00002617          	auipc	a2,0x2
ffffffffc02015f4:	87860613          	addi	a2,a2,-1928 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc02015f8:	0f300593          	li	a1,243
ffffffffc02015fc:	00002517          	auipc	a0,0x2
ffffffffc0201600:	88450513          	addi	a0,a0,-1916 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201604:	e05fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201608:	00002697          	auipc	a3,0x2
ffffffffc020160c:	8d068693          	addi	a3,a3,-1840 # ffffffffc0202ed8 <commands+0xa30>
ffffffffc0201610:	00002617          	auipc	a2,0x2
ffffffffc0201614:	85860613          	addi	a2,a2,-1960 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201618:	0ba00593          	li	a1,186
ffffffffc020161c:	00002517          	auipc	a0,0x2
ffffffffc0201620:	86450513          	addi	a0,a0,-1948 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc0201624:	de5fe0ef          	jal	ra,ffffffffc0200408 <__panic>

ffffffffc0201628 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201628:	1141                	addi	sp,sp,-16
ffffffffc020162a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020162c:	14058a63          	beqz	a1,ffffffffc0201780 <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0201630:	00259693          	slli	a3,a1,0x2
ffffffffc0201634:	96ae                	add	a3,a3,a1
ffffffffc0201636:	068e                	slli	a3,a3,0x3
ffffffffc0201638:	96aa                	add	a3,a3,a0
ffffffffc020163a:	87aa                	mv	a5,a0
ffffffffc020163c:	02d50263          	beq	a0,a3,ffffffffc0201660 <default_free_pages+0x38>
ffffffffc0201640:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201642:	8b05                	andi	a4,a4,1
ffffffffc0201644:	10071e63          	bnez	a4,ffffffffc0201760 <default_free_pages+0x138>
ffffffffc0201648:	6798                	ld	a4,8(a5)
ffffffffc020164a:	8b09                	andi	a4,a4,2
ffffffffc020164c:	10071a63          	bnez	a4,ffffffffc0201760 <default_free_pages+0x138>
        p->flags = 0;
ffffffffc0201650:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201654:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201658:	02878793          	addi	a5,a5,40
ffffffffc020165c:	fed792e3          	bne	a5,a3,ffffffffc0201640 <default_free_pages+0x18>
    base->property = n;
ffffffffc0201660:	2581                	sext.w	a1,a1
ffffffffc0201662:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201664:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201668:	4789                	li	a5,2
ffffffffc020166a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020166e:	00006697          	auipc	a3,0x6
ffffffffc0201672:	9ba68693          	addi	a3,a3,-1606 # ffffffffc0207028 <free_area>
ffffffffc0201676:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201678:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020167a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020167e:	9db9                	addw	a1,a1,a4
ffffffffc0201680:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201682:	0ad78863          	beq	a5,a3,ffffffffc0201732 <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201686:	fe878713          	addi	a4,a5,-24
ffffffffc020168a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020168e:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201690:	00e56a63          	bltu	a0,a4,ffffffffc02016a4 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc0201694:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201696:	06d70263          	beq	a4,a3,ffffffffc02016fa <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc020169a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020169c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016a0:	fee57ae3          	bgeu	a0,a4,ffffffffc0201694 <default_free_pages+0x6c>
ffffffffc02016a4:	c199                	beqz	a1,ffffffffc02016aa <default_free_pages+0x82>
ffffffffc02016a6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016aa:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016ac:	e390                	sd	a2,0(a5)
ffffffffc02016ae:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02016b0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016b2:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02016b4:	02d70063          	beq	a4,a3,ffffffffc02016d4 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc02016b8:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02016bc:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc02016c0:	02081613          	slli	a2,a6,0x20
ffffffffc02016c4:	9201                	srli	a2,a2,0x20
ffffffffc02016c6:	00261793          	slli	a5,a2,0x2
ffffffffc02016ca:	97b2                	add	a5,a5,a2
ffffffffc02016cc:	078e                	slli	a5,a5,0x3
ffffffffc02016ce:	97ae                	add	a5,a5,a1
ffffffffc02016d0:	02f50f63          	beq	a0,a5,ffffffffc020170e <default_free_pages+0xe6>
    return listelm->next;
ffffffffc02016d4:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02016d6:	00d70f63          	beq	a4,a3,ffffffffc02016f4 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02016da:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02016dc:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02016e0:	02059613          	slli	a2,a1,0x20
ffffffffc02016e4:	9201                	srli	a2,a2,0x20
ffffffffc02016e6:	00261793          	slli	a5,a2,0x2
ffffffffc02016ea:	97b2                	add	a5,a5,a2
ffffffffc02016ec:	078e                	slli	a5,a5,0x3
ffffffffc02016ee:	97aa                	add	a5,a5,a0
ffffffffc02016f0:	04f68863          	beq	a3,a5,ffffffffc0201740 <default_free_pages+0x118>
}
ffffffffc02016f4:	60a2                	ld	ra,8(sp)
ffffffffc02016f6:	0141                	addi	sp,sp,16
ffffffffc02016f8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016fa:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016fc:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02016fe:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201700:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201702:	02d70563          	beq	a4,a3,ffffffffc020172c <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201706:	8832                	mv	a6,a2
ffffffffc0201708:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020170a:	87ba                	mv	a5,a4
ffffffffc020170c:	bf41                	j	ffffffffc020169c <default_free_pages+0x74>
            p->property += base->property;
ffffffffc020170e:	491c                	lw	a5,16(a0)
ffffffffc0201710:	0107883b          	addw	a6,a5,a6
ffffffffc0201714:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201718:	57f5                	li	a5,-3
ffffffffc020171a:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020171e:	6d10                	ld	a2,24(a0)
ffffffffc0201720:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc0201722:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201724:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201726:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201728:	e390                	sd	a2,0(a5)
ffffffffc020172a:	b775                	j	ffffffffc02016d6 <default_free_pages+0xae>
ffffffffc020172c:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020172e:	873e                	mv	a4,a5
ffffffffc0201730:	b761                	j	ffffffffc02016b8 <default_free_pages+0x90>
}
ffffffffc0201732:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201734:	e390                	sd	a2,0(a5)
ffffffffc0201736:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201738:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020173a:	ed1c                	sd	a5,24(a0)
ffffffffc020173c:	0141                	addi	sp,sp,16
ffffffffc020173e:	8082                	ret
            base->property += p->property;
ffffffffc0201740:	ff872783          	lw	a5,-8(a4)
ffffffffc0201744:	ff070693          	addi	a3,a4,-16
ffffffffc0201748:	9dbd                	addw	a1,a1,a5
ffffffffc020174a:	c90c                	sw	a1,16(a0)
ffffffffc020174c:	57f5                	li	a5,-3
ffffffffc020174e:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201752:	6314                	ld	a3,0(a4)
ffffffffc0201754:	671c                	ld	a5,8(a4)
}
ffffffffc0201756:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201758:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc020175a:	e394                	sd	a3,0(a5)
ffffffffc020175c:	0141                	addi	sp,sp,16
ffffffffc020175e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201760:	00002697          	auipc	a3,0x2
ffffffffc0201764:	a6868693          	addi	a3,a3,-1432 # ffffffffc02031c8 <commands+0xd20>
ffffffffc0201768:	00001617          	auipc	a2,0x1
ffffffffc020176c:	70060613          	addi	a2,a2,1792 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201770:	08300593          	li	a1,131
ffffffffc0201774:	00001517          	auipc	a0,0x1
ffffffffc0201778:	70c50513          	addi	a0,a0,1804 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc020177c:	c8dfe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(n > 0);
ffffffffc0201780:	00002697          	auipc	a3,0x2
ffffffffc0201784:	a4068693          	addi	a3,a3,-1472 # ffffffffc02031c0 <commands+0xd18>
ffffffffc0201788:	00001617          	auipc	a2,0x1
ffffffffc020178c:	6e060613          	addi	a2,a2,1760 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201790:	08000593          	li	a1,128
ffffffffc0201794:	00001517          	auipc	a0,0x1
ffffffffc0201798:	6ec50513          	addi	a0,a0,1772 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc020179c:	c6dfe0ef          	jal	ra,ffffffffc0200408 <__panic>

ffffffffc02017a0 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017a0:	c959                	beqz	a0,ffffffffc0201836 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02017a2:	00006597          	auipc	a1,0x6
ffffffffc02017a6:	88658593          	addi	a1,a1,-1914 # ffffffffc0207028 <free_area>
ffffffffc02017aa:	0105a803          	lw	a6,16(a1)
ffffffffc02017ae:	862a                	mv	a2,a0
ffffffffc02017b0:	02081793          	slli	a5,a6,0x20
ffffffffc02017b4:	9381                	srli	a5,a5,0x20
ffffffffc02017b6:	00a7ee63          	bltu	a5,a0,ffffffffc02017d2 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02017ba:	87ae                	mv	a5,a1
ffffffffc02017bc:	a801                	j	ffffffffc02017cc <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc02017be:	ff87a703          	lw	a4,-8(a5)
ffffffffc02017c2:	02071693          	slli	a3,a4,0x20
ffffffffc02017c6:	9281                	srli	a3,a3,0x20
ffffffffc02017c8:	00c6f763          	bgeu	a3,a2,ffffffffc02017d6 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02017cc:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02017ce:	feb798e3          	bne	a5,a1,ffffffffc02017be <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02017d2:	4501                	li	a0,0
}
ffffffffc02017d4:	8082                	ret
    return listelm->prev;
ffffffffc02017d6:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017da:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02017de:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02017e2:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc02017e6:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02017ea:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02017ee:	02d67b63          	bgeu	a2,a3,ffffffffc0201824 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc02017f2:	00261693          	slli	a3,a2,0x2
ffffffffc02017f6:	96b2                	add	a3,a3,a2
ffffffffc02017f8:	068e                	slli	a3,a3,0x3
ffffffffc02017fa:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc02017fc:	41c7073b          	subw	a4,a4,t3
ffffffffc0201800:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201802:	00868613          	addi	a2,a3,8
ffffffffc0201806:	4709                	li	a4,2
ffffffffc0201808:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc020180c:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201810:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc0201814:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201818:	e310                	sd	a2,0(a4)
ffffffffc020181a:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020181e:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc0201820:	0116bc23          	sd	a7,24(a3)
ffffffffc0201824:	41c8083b          	subw	a6,a6,t3
ffffffffc0201828:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020182c:	5775                	li	a4,-3
ffffffffc020182e:	17c1                	addi	a5,a5,-16
ffffffffc0201830:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201834:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201836:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201838:	00002697          	auipc	a3,0x2
ffffffffc020183c:	98868693          	addi	a3,a3,-1656 # ffffffffc02031c0 <commands+0xd18>
ffffffffc0201840:	00001617          	auipc	a2,0x1
ffffffffc0201844:	62860613          	addi	a2,a2,1576 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc0201848:	06200593          	li	a1,98
ffffffffc020184c:	00001517          	auipc	a0,0x1
ffffffffc0201850:	63450513          	addi	a0,a0,1588 # ffffffffc0202e80 <commands+0x9d8>
default_alloc_pages(size_t n) {
ffffffffc0201854:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201856:	bb3fe0ef          	jal	ra,ffffffffc0200408 <__panic>

ffffffffc020185a <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020185a:	1141                	addi	sp,sp,-16
ffffffffc020185c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020185e:	c9e1                	beqz	a1,ffffffffc020192e <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201860:	00259693          	slli	a3,a1,0x2
ffffffffc0201864:	96ae                	add	a3,a3,a1
ffffffffc0201866:	068e                	slli	a3,a3,0x3
ffffffffc0201868:	96aa                	add	a3,a3,a0
ffffffffc020186a:	87aa                	mv	a5,a0
ffffffffc020186c:	00d50f63          	beq	a0,a3,ffffffffc020188a <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201870:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201872:	8b05                	andi	a4,a4,1
ffffffffc0201874:	cf49                	beqz	a4,ffffffffc020190e <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201876:	0007a823          	sw	zero,16(a5)
ffffffffc020187a:	0007b423          	sd	zero,8(a5)
ffffffffc020187e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201882:	02878793          	addi	a5,a5,40
ffffffffc0201886:	fed795e3          	bne	a5,a3,ffffffffc0201870 <default_init_memmap+0x16>
    base->property = n;
ffffffffc020188a:	2581                	sext.w	a1,a1
ffffffffc020188c:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020188e:	4789                	li	a5,2
ffffffffc0201890:	00850713          	addi	a4,a0,8
ffffffffc0201894:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201898:	00005697          	auipc	a3,0x5
ffffffffc020189c:	79068693          	addi	a3,a3,1936 # ffffffffc0207028 <free_area>
ffffffffc02018a0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018a2:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02018a4:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02018a8:	9db9                	addw	a1,a1,a4
ffffffffc02018aa:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02018ac:	04d78a63          	beq	a5,a3,ffffffffc0201900 <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc02018b0:	fe878713          	addi	a4,a5,-24
ffffffffc02018b4:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02018b8:	4581                	li	a1,0
            if (base < page) {
ffffffffc02018ba:	00e56a63          	bltu	a0,a4,ffffffffc02018ce <default_init_memmap+0x74>
    return listelm->next;
ffffffffc02018be:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02018c0:	02d70263          	beq	a4,a3,ffffffffc02018e4 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc02018c4:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02018c6:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02018ca:	fee57ae3          	bgeu	a0,a4,ffffffffc02018be <default_init_memmap+0x64>
ffffffffc02018ce:	c199                	beqz	a1,ffffffffc02018d4 <default_init_memmap+0x7a>
ffffffffc02018d0:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02018d4:	6398                	ld	a4,0(a5)
}
ffffffffc02018d6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018d8:	e390                	sd	a2,0(a5)
ffffffffc02018da:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02018dc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018de:	ed18                	sd	a4,24(a0)
ffffffffc02018e0:	0141                	addi	sp,sp,16
ffffffffc02018e2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02018e4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018e6:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02018e8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02018ea:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02018ec:	00d70663          	beq	a4,a3,ffffffffc02018f8 <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc02018f0:	8832                	mv	a6,a2
ffffffffc02018f2:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02018f4:	87ba                	mv	a5,a4
ffffffffc02018f6:	bfc1                	j	ffffffffc02018c6 <default_init_memmap+0x6c>
}
ffffffffc02018f8:	60a2                	ld	ra,8(sp)
ffffffffc02018fa:	e290                	sd	a2,0(a3)
ffffffffc02018fc:	0141                	addi	sp,sp,16
ffffffffc02018fe:	8082                	ret
ffffffffc0201900:	60a2                	ld	ra,8(sp)
ffffffffc0201902:	e390                	sd	a2,0(a5)
ffffffffc0201904:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201906:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201908:	ed1c                	sd	a5,24(a0)
ffffffffc020190a:	0141                	addi	sp,sp,16
ffffffffc020190c:	8082                	ret
        assert(PageReserved(p));
ffffffffc020190e:	00002697          	auipc	a3,0x2
ffffffffc0201912:	8e268693          	addi	a3,a3,-1822 # ffffffffc02031f0 <commands+0xd48>
ffffffffc0201916:	00001617          	auipc	a2,0x1
ffffffffc020191a:	55260613          	addi	a2,a2,1362 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc020191e:	04900593          	li	a1,73
ffffffffc0201922:	00001517          	auipc	a0,0x1
ffffffffc0201926:	55e50513          	addi	a0,a0,1374 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc020192a:	adffe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(n > 0);
ffffffffc020192e:	00002697          	auipc	a3,0x2
ffffffffc0201932:	89268693          	addi	a3,a3,-1902 # ffffffffc02031c0 <commands+0xd18>
ffffffffc0201936:	00001617          	auipc	a2,0x1
ffffffffc020193a:	53260613          	addi	a2,a2,1330 # ffffffffc0202e68 <commands+0x9c0>
ffffffffc020193e:	04600593          	li	a1,70
ffffffffc0201942:	00001517          	auipc	a0,0x1
ffffffffc0201946:	53e50513          	addi	a0,a0,1342 # ffffffffc0202e80 <commands+0x9d8>
ffffffffc020194a:	abffe0ef          	jal	ra,ffffffffc0200408 <__panic>

ffffffffc020194e <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020194e:	100027f3          	csrr	a5,sstatus
ffffffffc0201952:	8b89                	andi	a5,a5,2
ffffffffc0201954:	e799                	bnez	a5,ffffffffc0201962 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201956:	00006797          	auipc	a5,0x6
ffffffffc020195a:	b227b783          	ld	a5,-1246(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc020195e:	6f9c                	ld	a5,24(a5)
ffffffffc0201960:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0201962:	1141                	addi	sp,sp,-16
ffffffffc0201964:	e406                	sd	ra,8(sp)
ffffffffc0201966:	e022                	sd	s0,0(sp)
ffffffffc0201968:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020196a:	f01fe0ef          	jal	ra,ffffffffc020086a <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020196e:	00006797          	auipc	a5,0x6
ffffffffc0201972:	b0a7b783          	ld	a5,-1270(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201976:	6f9c                	ld	a5,24(a5)
ffffffffc0201978:	8522                	mv	a0,s0
ffffffffc020197a:	9782                	jalr	a5
ffffffffc020197c:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020197e:	ee7fe0ef          	jal	ra,ffffffffc0200864 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201982:	60a2                	ld	ra,8(sp)
ffffffffc0201984:	8522                	mv	a0,s0
ffffffffc0201986:	6402                	ld	s0,0(sp)
ffffffffc0201988:	0141                	addi	sp,sp,16
ffffffffc020198a:	8082                	ret

ffffffffc020198c <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020198c:	100027f3          	csrr	a5,sstatus
ffffffffc0201990:	8b89                	andi	a5,a5,2
ffffffffc0201992:	e799                	bnez	a5,ffffffffc02019a0 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201994:	00006797          	auipc	a5,0x6
ffffffffc0201998:	ae47b783          	ld	a5,-1308(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc020199c:	739c                	ld	a5,32(a5)
ffffffffc020199e:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02019a0:	1101                	addi	sp,sp,-32
ffffffffc02019a2:	ec06                	sd	ra,24(sp)
ffffffffc02019a4:	e822                	sd	s0,16(sp)
ffffffffc02019a6:	e426                	sd	s1,8(sp)
ffffffffc02019a8:	842a                	mv	s0,a0
ffffffffc02019aa:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02019ac:	ebffe0ef          	jal	ra,ffffffffc020086a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02019b0:	00006797          	auipc	a5,0x6
ffffffffc02019b4:	ac87b783          	ld	a5,-1336(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02019b8:	739c                	ld	a5,32(a5)
ffffffffc02019ba:	85a6                	mv	a1,s1
ffffffffc02019bc:	8522                	mv	a0,s0
ffffffffc02019be:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02019c0:	6442                	ld	s0,16(sp)
ffffffffc02019c2:	60e2                	ld	ra,24(sp)
ffffffffc02019c4:	64a2                	ld	s1,8(sp)
ffffffffc02019c6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02019c8:	e9dfe06f          	j	ffffffffc0200864 <intr_enable>

ffffffffc02019cc <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019cc:	100027f3          	csrr	a5,sstatus
ffffffffc02019d0:	8b89                	andi	a5,a5,2
ffffffffc02019d2:	e799                	bnez	a5,ffffffffc02019e0 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02019d4:	00006797          	auipc	a5,0x6
ffffffffc02019d8:	aa47b783          	ld	a5,-1372(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02019dc:	779c                	ld	a5,40(a5)
ffffffffc02019de:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02019e0:	1141                	addi	sp,sp,-16
ffffffffc02019e2:	e406                	sd	ra,8(sp)
ffffffffc02019e4:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02019e6:	e85fe0ef          	jal	ra,ffffffffc020086a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02019ea:	00006797          	auipc	a5,0x6
ffffffffc02019ee:	a8e7b783          	ld	a5,-1394(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02019f2:	779c                	ld	a5,40(a5)
ffffffffc02019f4:	9782                	jalr	a5
ffffffffc02019f6:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02019f8:	e6dfe0ef          	jal	ra,ffffffffc0200864 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02019fc:	60a2                	ld	ra,8(sp)
ffffffffc02019fe:	8522                	mv	a0,s0
ffffffffc0201a00:	6402                	ld	s0,0(sp)
ffffffffc0201a02:	0141                	addi	sp,sp,16
ffffffffc0201a04:	8082                	ret

ffffffffc0201a06 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201a06:	00002797          	auipc	a5,0x2
ffffffffc0201a0a:	81278793          	addi	a5,a5,-2030 # ffffffffc0203218 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201a0e:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201a10:	7179                	addi	sp,sp,-48
ffffffffc0201a12:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201a14:	00002517          	auipc	a0,0x2
ffffffffc0201a18:	83c50513          	addi	a0,a0,-1988 # ffffffffc0203250 <default_pmm_manager+0x38>
    pmm_manager = &default_pmm_manager;
ffffffffc0201a1c:	00006417          	auipc	s0,0x6
ffffffffc0201a20:	a5c40413          	addi	s0,s0,-1444 # ffffffffc0207478 <pmm_manager>
void pmm_init(void) {
ffffffffc0201a24:	f406                	sd	ra,40(sp)
ffffffffc0201a26:	ec26                	sd	s1,24(sp)
ffffffffc0201a28:	e44e                	sd	s3,8(sp)
ffffffffc0201a2a:	e84a                	sd	s2,16(sp)
ffffffffc0201a2c:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201a2e:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201a30:	edefe0ef          	jal	ra,ffffffffc020010e <cprintf>
    pmm_manager->init();
ffffffffc0201a34:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201a36:	00006497          	auipc	s1,0x6
ffffffffc0201a3a:	a5a48493          	addi	s1,s1,-1446 # ffffffffc0207490 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201a3e:	679c                	ld	a5,8(a5)
ffffffffc0201a40:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201a42:	57f5                	li	a5,-3
ffffffffc0201a44:	07fa                	slli	a5,a5,0x1e
ffffffffc0201a46:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201a48:	e09fe0ef          	jal	ra,ffffffffc0200850 <get_memory_base>
ffffffffc0201a4c:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201a4e:	e0dfe0ef          	jal	ra,ffffffffc020085a <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201a52:	16050163          	beqz	a0,ffffffffc0201bb4 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201a56:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201a58:	00002517          	auipc	a0,0x2
ffffffffc0201a5c:	84050513          	addi	a0,a0,-1984 # ffffffffc0203298 <default_pmm_manager+0x80>
ffffffffc0201a60:	eaefe0ef          	jal	ra,ffffffffc020010e <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201a64:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201a68:	864e                	mv	a2,s3
ffffffffc0201a6a:	fffa0693          	addi	a3,s4,-1
ffffffffc0201a6e:	85ca                	mv	a1,s2
ffffffffc0201a70:	00002517          	auipc	a0,0x2
ffffffffc0201a74:	84050513          	addi	a0,a0,-1984 # ffffffffc02032b0 <default_pmm_manager+0x98>
ffffffffc0201a78:	e96fe0ef          	jal	ra,ffffffffc020010e <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201a7c:	c80007b7          	lui	a5,0xc8000
ffffffffc0201a80:	8652                	mv	a2,s4
ffffffffc0201a82:	0d47e863          	bltu	a5,s4,ffffffffc0201b52 <pmm_init+0x14c>
ffffffffc0201a86:	00007797          	auipc	a5,0x7
ffffffffc0201a8a:	a1978793          	addi	a5,a5,-1511 # ffffffffc020849f <end+0xfff>
ffffffffc0201a8e:	757d                	lui	a0,0xfffff
ffffffffc0201a90:	8d7d                	and	a0,a0,a5
ffffffffc0201a92:	8231                	srli	a2,a2,0xc
ffffffffc0201a94:	00006597          	auipc	a1,0x6
ffffffffc0201a98:	9d458593          	addi	a1,a1,-1580 # ffffffffc0207468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201a9c:	00006817          	auipc	a6,0x6
ffffffffc0201aa0:	9d480813          	addi	a6,a6,-1580 # ffffffffc0207470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201aa4:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201aa6:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201aaa:	000807b7          	lui	a5,0x80
ffffffffc0201aae:	02f60663          	beq	a2,a5,ffffffffc0201ada <pmm_init+0xd4>
ffffffffc0201ab2:	4701                	li	a4,0
ffffffffc0201ab4:	4781                	li	a5,0
ffffffffc0201ab6:	4305                	li	t1,1
ffffffffc0201ab8:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201abc:	953a                	add	a0,a0,a4
ffffffffc0201abe:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b68>
ffffffffc0201ac2:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201ac6:	6190                	ld	a2,0(a1)
ffffffffc0201ac8:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0201aca:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201ace:	011606b3          	add	a3,a2,a7
ffffffffc0201ad2:	02870713          	addi	a4,a4,40
ffffffffc0201ad6:	fed7e3e3          	bltu	a5,a3,ffffffffc0201abc <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201ada:	00261693          	slli	a3,a2,0x2
ffffffffc0201ade:	96b2                	add	a3,a3,a2
ffffffffc0201ae0:	fec007b7          	lui	a5,0xfec00
ffffffffc0201ae4:	97aa                	add	a5,a5,a0
ffffffffc0201ae6:	068e                	slli	a3,a3,0x3
ffffffffc0201ae8:	96be                	add	a3,a3,a5
ffffffffc0201aea:	c02007b7          	lui	a5,0xc0200
ffffffffc0201aee:	0af6e763          	bltu	a3,a5,ffffffffc0201b9c <pmm_init+0x196>
ffffffffc0201af2:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201af4:	77fd                	lui	a5,0xfffff
ffffffffc0201af6:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201afa:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201afc:	04b6ee63          	bltu	a3,a1,ffffffffc0201b58 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201b00:	601c                	ld	a5,0(s0)
ffffffffc0201b02:	7b9c                	ld	a5,48(a5)
ffffffffc0201b04:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201b06:	00002517          	auipc	a0,0x2
ffffffffc0201b0a:	83250513          	addi	a0,a0,-1998 # ffffffffc0203338 <default_pmm_manager+0x120>
ffffffffc0201b0e:	e00fe0ef          	jal	ra,ffffffffc020010e <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201b12:	00004597          	auipc	a1,0x4
ffffffffc0201b16:	4ee58593          	addi	a1,a1,1262 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201b1a:	00006797          	auipc	a5,0x6
ffffffffc0201b1e:	96b7b723          	sd	a1,-1682(a5) # ffffffffc0207488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201b22:	c02007b7          	lui	a5,0xc0200
ffffffffc0201b26:	0af5e363          	bltu	a1,a5,ffffffffc0201bcc <pmm_init+0x1c6>
ffffffffc0201b2a:	6090                	ld	a2,0(s1)
}
ffffffffc0201b2c:	7402                	ld	s0,32(sp)
ffffffffc0201b2e:	70a2                	ld	ra,40(sp)
ffffffffc0201b30:	64e2                	ld	s1,24(sp)
ffffffffc0201b32:	6942                	ld	s2,16(sp)
ffffffffc0201b34:	69a2                	ld	s3,8(sp)
ffffffffc0201b36:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201b38:	40c58633          	sub	a2,a1,a2
ffffffffc0201b3c:	00006797          	auipc	a5,0x6
ffffffffc0201b40:	94c7b223          	sd	a2,-1724(a5) # ffffffffc0207480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201b44:	00002517          	auipc	a0,0x2
ffffffffc0201b48:	81450513          	addi	a0,a0,-2028 # ffffffffc0203358 <default_pmm_manager+0x140>
}
ffffffffc0201b4c:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201b4e:	dc0fe06f          	j	ffffffffc020010e <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201b52:	c8000637          	lui	a2,0xc8000
ffffffffc0201b56:	bf05                	j	ffffffffc0201a86 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201b58:	6705                	lui	a4,0x1
ffffffffc0201b5a:	177d                	addi	a4,a4,-1
ffffffffc0201b5c:	96ba                	add	a3,a3,a4
ffffffffc0201b5e:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201b60:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201b64:	02c7f063          	bgeu	a5,a2,ffffffffc0201b84 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc0201b68:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201b6a:	fff80737          	lui	a4,0xfff80
ffffffffc0201b6e:	973e                	add	a4,a4,a5
ffffffffc0201b70:	00271793          	slli	a5,a4,0x2
ffffffffc0201b74:	97ba                	add	a5,a5,a4
ffffffffc0201b76:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201b78:	8d95                	sub	a1,a1,a3
ffffffffc0201b7a:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201b7c:	81b1                	srli	a1,a1,0xc
ffffffffc0201b7e:	953e                	add	a0,a0,a5
ffffffffc0201b80:	9702                	jalr	a4
}
ffffffffc0201b82:	bfbd                	j	ffffffffc0201b00 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc0201b84:	00001617          	auipc	a2,0x1
ffffffffc0201b88:	78460613          	addi	a2,a2,1924 # ffffffffc0203308 <default_pmm_manager+0xf0>
ffffffffc0201b8c:	06b00593          	li	a1,107
ffffffffc0201b90:	00001517          	auipc	a0,0x1
ffffffffc0201b94:	79850513          	addi	a0,a0,1944 # ffffffffc0203328 <default_pmm_manager+0x110>
ffffffffc0201b98:	871fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201b9c:	00001617          	auipc	a2,0x1
ffffffffc0201ba0:	74460613          	addi	a2,a2,1860 # ffffffffc02032e0 <default_pmm_manager+0xc8>
ffffffffc0201ba4:	07100593          	li	a1,113
ffffffffc0201ba8:	00001517          	auipc	a0,0x1
ffffffffc0201bac:	6e050513          	addi	a0,a0,1760 # ffffffffc0203288 <default_pmm_manager+0x70>
ffffffffc0201bb0:	859fe0ef          	jal	ra,ffffffffc0200408 <__panic>
        panic("DTB memory info not available");
ffffffffc0201bb4:	00001617          	auipc	a2,0x1
ffffffffc0201bb8:	6b460613          	addi	a2,a2,1716 # ffffffffc0203268 <default_pmm_manager+0x50>
ffffffffc0201bbc:	05a00593          	li	a1,90
ffffffffc0201bc0:	00001517          	auipc	a0,0x1
ffffffffc0201bc4:	6c850513          	addi	a0,a0,1736 # ffffffffc0203288 <default_pmm_manager+0x70>
ffffffffc0201bc8:	841fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201bcc:	86ae                	mv	a3,a1
ffffffffc0201bce:	00001617          	auipc	a2,0x1
ffffffffc0201bd2:	71260613          	addi	a2,a2,1810 # ffffffffc02032e0 <default_pmm_manager+0xc8>
ffffffffc0201bd6:	08c00593          	li	a1,140
ffffffffc0201bda:	00001517          	auipc	a0,0x1
ffffffffc0201bde:	6ae50513          	addi	a0,a0,1710 # ffffffffc0203288 <default_pmm_manager+0x70>
ffffffffc0201be2:	827fe0ef          	jal	ra,ffffffffc0200408 <__panic>

ffffffffc0201be6 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201be6:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201bea:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201bec:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201bf0:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201bf2:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201bf6:	f022                	sd	s0,32(sp)
ffffffffc0201bf8:	ec26                	sd	s1,24(sp)
ffffffffc0201bfa:	e84a                	sd	s2,16(sp)
ffffffffc0201bfc:	f406                	sd	ra,40(sp)
ffffffffc0201bfe:	e44e                	sd	s3,8(sp)
ffffffffc0201c00:	84aa                	mv	s1,a0
ffffffffc0201c02:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201c04:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201c08:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201c0a:	03067e63          	bgeu	a2,a6,ffffffffc0201c46 <printnum+0x60>
ffffffffc0201c0e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201c10:	00805763          	blez	s0,ffffffffc0201c1e <printnum+0x38>
ffffffffc0201c14:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201c16:	85ca                	mv	a1,s2
ffffffffc0201c18:	854e                	mv	a0,s3
ffffffffc0201c1a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201c1c:	fc65                	bnez	s0,ffffffffc0201c14 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201c1e:	1a02                	slli	s4,s4,0x20
ffffffffc0201c20:	00001797          	auipc	a5,0x1
ffffffffc0201c24:	77878793          	addi	a5,a5,1912 # ffffffffc0203398 <default_pmm_manager+0x180>
ffffffffc0201c28:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201c2c:	9a3e                	add	s4,s4,a5
}
ffffffffc0201c2e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201c30:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201c34:	70a2                	ld	ra,40(sp)
ffffffffc0201c36:	69a2                	ld	s3,8(sp)
ffffffffc0201c38:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201c3a:	85ca                	mv	a1,s2
ffffffffc0201c3c:	87a6                	mv	a5,s1
}
ffffffffc0201c3e:	6942                	ld	s2,16(sp)
ffffffffc0201c40:	64e2                	ld	s1,24(sp)
ffffffffc0201c42:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201c44:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201c46:	03065633          	divu	a2,a2,a6
ffffffffc0201c4a:	8722                	mv	a4,s0
ffffffffc0201c4c:	f9bff0ef          	jal	ra,ffffffffc0201be6 <printnum>
ffffffffc0201c50:	b7f9                	j	ffffffffc0201c1e <printnum+0x38>

ffffffffc0201c52 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201c52:	7119                	addi	sp,sp,-128
ffffffffc0201c54:	f4a6                	sd	s1,104(sp)
ffffffffc0201c56:	f0ca                	sd	s2,96(sp)
ffffffffc0201c58:	ecce                	sd	s3,88(sp)
ffffffffc0201c5a:	e8d2                	sd	s4,80(sp)
ffffffffc0201c5c:	e4d6                	sd	s5,72(sp)
ffffffffc0201c5e:	e0da                	sd	s6,64(sp)
ffffffffc0201c60:	fc5e                	sd	s7,56(sp)
ffffffffc0201c62:	f06a                	sd	s10,32(sp)
ffffffffc0201c64:	fc86                	sd	ra,120(sp)
ffffffffc0201c66:	f8a2                	sd	s0,112(sp)
ffffffffc0201c68:	f862                	sd	s8,48(sp)
ffffffffc0201c6a:	f466                	sd	s9,40(sp)
ffffffffc0201c6c:	ec6e                	sd	s11,24(sp)
ffffffffc0201c6e:	892a                	mv	s2,a0
ffffffffc0201c70:	84ae                	mv	s1,a1
ffffffffc0201c72:	8d32                	mv	s10,a2
ffffffffc0201c74:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c76:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201c7a:	5b7d                	li	s6,-1
ffffffffc0201c7c:	00001a97          	auipc	s5,0x1
ffffffffc0201c80:	750a8a93          	addi	s5,s5,1872 # ffffffffc02033cc <default_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c84:	00002b97          	auipc	s7,0x2
ffffffffc0201c88:	924b8b93          	addi	s7,s7,-1756 # ffffffffc02035a8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c8c:	000d4503          	lbu	a0,0(s10)
ffffffffc0201c90:	001d0413          	addi	s0,s10,1
ffffffffc0201c94:	01350a63          	beq	a0,s3,ffffffffc0201ca8 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201c98:	c121                	beqz	a0,ffffffffc0201cd8 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201c9a:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c9c:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201c9e:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ca0:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201ca4:	ff351ae3          	bne	a0,s3,ffffffffc0201c98 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ca8:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201cac:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201cb0:	4c81                	li	s9,0
ffffffffc0201cb2:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201cb4:	5c7d                	li	s8,-1
ffffffffc0201cb6:	5dfd                	li	s11,-1
ffffffffc0201cb8:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201cbc:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cbe:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201cc2:	0ff5f593          	zext.b	a1,a1
ffffffffc0201cc6:	00140d13          	addi	s10,s0,1
ffffffffc0201cca:	04b56263          	bltu	a0,a1,ffffffffc0201d0e <vprintfmt+0xbc>
ffffffffc0201cce:	058a                	slli	a1,a1,0x2
ffffffffc0201cd0:	95d6                	add	a1,a1,s5
ffffffffc0201cd2:	4194                	lw	a3,0(a1)
ffffffffc0201cd4:	96d6                	add	a3,a3,s5
ffffffffc0201cd6:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201cd8:	70e6                	ld	ra,120(sp)
ffffffffc0201cda:	7446                	ld	s0,112(sp)
ffffffffc0201cdc:	74a6                	ld	s1,104(sp)
ffffffffc0201cde:	7906                	ld	s2,96(sp)
ffffffffc0201ce0:	69e6                	ld	s3,88(sp)
ffffffffc0201ce2:	6a46                	ld	s4,80(sp)
ffffffffc0201ce4:	6aa6                	ld	s5,72(sp)
ffffffffc0201ce6:	6b06                	ld	s6,64(sp)
ffffffffc0201ce8:	7be2                	ld	s7,56(sp)
ffffffffc0201cea:	7c42                	ld	s8,48(sp)
ffffffffc0201cec:	7ca2                	ld	s9,40(sp)
ffffffffc0201cee:	7d02                	ld	s10,32(sp)
ffffffffc0201cf0:	6de2                	ld	s11,24(sp)
ffffffffc0201cf2:	6109                	addi	sp,sp,128
ffffffffc0201cf4:	8082                	ret
            padc = '0';
ffffffffc0201cf6:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201cf8:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cfc:	846a                	mv	s0,s10
ffffffffc0201cfe:	00140d13          	addi	s10,s0,1
ffffffffc0201d02:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201d06:	0ff5f593          	zext.b	a1,a1
ffffffffc0201d0a:	fcb572e3          	bgeu	a0,a1,ffffffffc0201cce <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201d0e:	85a6                	mv	a1,s1
ffffffffc0201d10:	02500513          	li	a0,37
ffffffffc0201d14:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201d16:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201d1a:	8d22                	mv	s10,s0
ffffffffc0201d1c:	f73788e3          	beq	a5,s3,ffffffffc0201c8c <vprintfmt+0x3a>
ffffffffc0201d20:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201d24:	1d7d                	addi	s10,s10,-1
ffffffffc0201d26:	ff379de3          	bne	a5,s3,ffffffffc0201d20 <vprintfmt+0xce>
ffffffffc0201d2a:	b78d                	j	ffffffffc0201c8c <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201d2c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201d30:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d34:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201d36:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201d3a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201d3e:	02d86463          	bltu	a6,a3,ffffffffc0201d66 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201d42:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201d46:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201d4a:	0186873b          	addw	a4,a3,s8
ffffffffc0201d4e:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201d52:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201d54:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201d58:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201d5a:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201d5e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201d62:	fed870e3          	bgeu	a6,a3,ffffffffc0201d42 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201d66:	f40ddce3          	bgez	s11,ffffffffc0201cbe <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201d6a:	8de2                	mv	s11,s8
ffffffffc0201d6c:	5c7d                	li	s8,-1
ffffffffc0201d6e:	bf81                	j	ffffffffc0201cbe <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201d70:	fffdc693          	not	a3,s11
ffffffffc0201d74:	96fd                	srai	a3,a3,0x3f
ffffffffc0201d76:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d7a:	00144603          	lbu	a2,1(s0)
ffffffffc0201d7e:	2d81                	sext.w	s11,s11
ffffffffc0201d80:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201d82:	bf35                	j	ffffffffc0201cbe <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201d84:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d88:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201d8c:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d8e:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201d90:	bfd9                	j	ffffffffc0201d66 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201d92:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d94:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201d98:	01174463          	blt	a4,a7,ffffffffc0201da0 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201d9c:	1a088e63          	beqz	a7,ffffffffc0201f58 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201da0:	000a3603          	ld	a2,0(s4)
ffffffffc0201da4:	46c1                	li	a3,16
ffffffffc0201da6:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201da8:	2781                	sext.w	a5,a5
ffffffffc0201daa:	876e                	mv	a4,s11
ffffffffc0201dac:	85a6                	mv	a1,s1
ffffffffc0201dae:	854a                	mv	a0,s2
ffffffffc0201db0:	e37ff0ef          	jal	ra,ffffffffc0201be6 <printnum>
            break;
ffffffffc0201db4:	bde1                	j	ffffffffc0201c8c <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201db6:	000a2503          	lw	a0,0(s4)
ffffffffc0201dba:	85a6                	mv	a1,s1
ffffffffc0201dbc:	0a21                	addi	s4,s4,8
ffffffffc0201dbe:	9902                	jalr	s2
            break;
ffffffffc0201dc0:	b5f1                	j	ffffffffc0201c8c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201dc2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201dc4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201dc8:	01174463          	blt	a4,a7,ffffffffc0201dd0 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201dcc:	18088163          	beqz	a7,ffffffffc0201f4e <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201dd0:	000a3603          	ld	a2,0(s4)
ffffffffc0201dd4:	46a9                	li	a3,10
ffffffffc0201dd6:	8a2e                	mv	s4,a1
ffffffffc0201dd8:	bfc1                	j	ffffffffc0201da8 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201dda:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201dde:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201de0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201de2:	bdf1                	j	ffffffffc0201cbe <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201de4:	85a6                	mv	a1,s1
ffffffffc0201de6:	02500513          	li	a0,37
ffffffffc0201dea:	9902                	jalr	s2
            break;
ffffffffc0201dec:	b545                	j	ffffffffc0201c8c <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201dee:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201df2:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201df4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201df6:	b5e1                	j	ffffffffc0201cbe <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201df8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201dfa:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201dfe:	01174463          	blt	a4,a7,ffffffffc0201e06 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201e02:	14088163          	beqz	a7,ffffffffc0201f44 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201e06:	000a3603          	ld	a2,0(s4)
ffffffffc0201e0a:	46a1                	li	a3,8
ffffffffc0201e0c:	8a2e                	mv	s4,a1
ffffffffc0201e0e:	bf69                	j	ffffffffc0201da8 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201e10:	03000513          	li	a0,48
ffffffffc0201e14:	85a6                	mv	a1,s1
ffffffffc0201e16:	e03e                	sd	a5,0(sp)
ffffffffc0201e18:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201e1a:	85a6                	mv	a1,s1
ffffffffc0201e1c:	07800513          	li	a0,120
ffffffffc0201e20:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201e22:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201e24:	6782                	ld	a5,0(sp)
ffffffffc0201e26:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201e28:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201e2c:	bfb5                	j	ffffffffc0201da8 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201e2e:	000a3403          	ld	s0,0(s4)
ffffffffc0201e32:	008a0713          	addi	a4,s4,8
ffffffffc0201e36:	e03a                	sd	a4,0(sp)
ffffffffc0201e38:	14040263          	beqz	s0,ffffffffc0201f7c <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201e3c:	0fb05763          	blez	s11,ffffffffc0201f2a <vprintfmt+0x2d8>
ffffffffc0201e40:	02d00693          	li	a3,45
ffffffffc0201e44:	0cd79163          	bne	a5,a3,ffffffffc0201f06 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e48:	00044783          	lbu	a5,0(s0)
ffffffffc0201e4c:	0007851b          	sext.w	a0,a5
ffffffffc0201e50:	cf85                	beqz	a5,ffffffffc0201e88 <vprintfmt+0x236>
ffffffffc0201e52:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e56:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e5a:	000c4563          	bltz	s8,ffffffffc0201e64 <vprintfmt+0x212>
ffffffffc0201e5e:	3c7d                	addiw	s8,s8,-1
ffffffffc0201e60:	036c0263          	beq	s8,s6,ffffffffc0201e84 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201e64:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e66:	0e0c8e63          	beqz	s9,ffffffffc0201f62 <vprintfmt+0x310>
ffffffffc0201e6a:	3781                	addiw	a5,a5,-32
ffffffffc0201e6c:	0ef47b63          	bgeu	s0,a5,ffffffffc0201f62 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201e70:	03f00513          	li	a0,63
ffffffffc0201e74:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e76:	000a4783          	lbu	a5,0(s4)
ffffffffc0201e7a:	3dfd                	addiw	s11,s11,-1
ffffffffc0201e7c:	0a05                	addi	s4,s4,1
ffffffffc0201e7e:	0007851b          	sext.w	a0,a5
ffffffffc0201e82:	ffe1                	bnez	a5,ffffffffc0201e5a <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201e84:	01b05963          	blez	s11,ffffffffc0201e96 <vprintfmt+0x244>
ffffffffc0201e88:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201e8a:	85a6                	mv	a1,s1
ffffffffc0201e8c:	02000513          	li	a0,32
ffffffffc0201e90:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201e92:	fe0d9be3          	bnez	s11,ffffffffc0201e88 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201e96:	6a02                	ld	s4,0(sp)
ffffffffc0201e98:	bbd5                	j	ffffffffc0201c8c <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201e9a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201e9c:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201ea0:	01174463          	blt	a4,a7,ffffffffc0201ea8 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201ea4:	08088d63          	beqz	a7,ffffffffc0201f3e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201ea8:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201eac:	0a044d63          	bltz	s0,ffffffffc0201f66 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201eb0:	8622                	mv	a2,s0
ffffffffc0201eb2:	8a66                	mv	s4,s9
ffffffffc0201eb4:	46a9                	li	a3,10
ffffffffc0201eb6:	bdcd                	j	ffffffffc0201da8 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201eb8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ebc:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201ebe:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201ec0:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201ec4:	8fb5                	xor	a5,a5,a3
ffffffffc0201ec6:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201eca:	02d74163          	blt	a4,a3,ffffffffc0201eec <vprintfmt+0x29a>
ffffffffc0201ece:	00369793          	slli	a5,a3,0x3
ffffffffc0201ed2:	97de                	add	a5,a5,s7
ffffffffc0201ed4:	639c                	ld	a5,0(a5)
ffffffffc0201ed6:	cb99                	beqz	a5,ffffffffc0201eec <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201ed8:	86be                	mv	a3,a5
ffffffffc0201eda:	00001617          	auipc	a2,0x1
ffffffffc0201ede:	4ee60613          	addi	a2,a2,1262 # ffffffffc02033c8 <default_pmm_manager+0x1b0>
ffffffffc0201ee2:	85a6                	mv	a1,s1
ffffffffc0201ee4:	854a                	mv	a0,s2
ffffffffc0201ee6:	0ce000ef          	jal	ra,ffffffffc0201fb4 <printfmt>
ffffffffc0201eea:	b34d                	j	ffffffffc0201c8c <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201eec:	00001617          	auipc	a2,0x1
ffffffffc0201ef0:	4cc60613          	addi	a2,a2,1228 # ffffffffc02033b8 <default_pmm_manager+0x1a0>
ffffffffc0201ef4:	85a6                	mv	a1,s1
ffffffffc0201ef6:	854a                	mv	a0,s2
ffffffffc0201ef8:	0bc000ef          	jal	ra,ffffffffc0201fb4 <printfmt>
ffffffffc0201efc:	bb41                	j	ffffffffc0201c8c <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201efe:	00001417          	auipc	s0,0x1
ffffffffc0201f02:	4b240413          	addi	s0,s0,1202 # ffffffffc02033b0 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201f06:	85e2                	mv	a1,s8
ffffffffc0201f08:	8522                	mv	a0,s0
ffffffffc0201f0a:	e43e                	sd	a5,8(sp)
ffffffffc0201f0c:	200000ef          	jal	ra,ffffffffc020210c <strnlen>
ffffffffc0201f10:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201f14:	01b05b63          	blez	s11,ffffffffc0201f2a <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201f18:	67a2                	ld	a5,8(sp)
ffffffffc0201f1a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201f1e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201f20:	85a6                	mv	a1,s1
ffffffffc0201f22:	8552                	mv	a0,s4
ffffffffc0201f24:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201f26:	fe0d9ce3          	bnez	s11,ffffffffc0201f1e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201f2a:	00044783          	lbu	a5,0(s0)
ffffffffc0201f2e:	00140a13          	addi	s4,s0,1
ffffffffc0201f32:	0007851b          	sext.w	a0,a5
ffffffffc0201f36:	d3a5                	beqz	a5,ffffffffc0201e96 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201f38:	05e00413          	li	s0,94
ffffffffc0201f3c:	bf39                	j	ffffffffc0201e5a <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201f3e:	000a2403          	lw	s0,0(s4)
ffffffffc0201f42:	b7ad                	j	ffffffffc0201eac <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201f44:	000a6603          	lwu	a2,0(s4)
ffffffffc0201f48:	46a1                	li	a3,8
ffffffffc0201f4a:	8a2e                	mv	s4,a1
ffffffffc0201f4c:	bdb1                	j	ffffffffc0201da8 <vprintfmt+0x156>
ffffffffc0201f4e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201f52:	46a9                	li	a3,10
ffffffffc0201f54:	8a2e                	mv	s4,a1
ffffffffc0201f56:	bd89                	j	ffffffffc0201da8 <vprintfmt+0x156>
ffffffffc0201f58:	000a6603          	lwu	a2,0(s4)
ffffffffc0201f5c:	46c1                	li	a3,16
ffffffffc0201f5e:	8a2e                	mv	s4,a1
ffffffffc0201f60:	b5a1                	j	ffffffffc0201da8 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201f62:	9902                	jalr	s2
ffffffffc0201f64:	bf09                	j	ffffffffc0201e76 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201f66:	85a6                	mv	a1,s1
ffffffffc0201f68:	02d00513          	li	a0,45
ffffffffc0201f6c:	e03e                	sd	a5,0(sp)
ffffffffc0201f6e:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201f70:	6782                	ld	a5,0(sp)
ffffffffc0201f72:	8a66                	mv	s4,s9
ffffffffc0201f74:	40800633          	neg	a2,s0
ffffffffc0201f78:	46a9                	li	a3,10
ffffffffc0201f7a:	b53d                	j	ffffffffc0201da8 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201f7c:	03b05163          	blez	s11,ffffffffc0201f9e <vprintfmt+0x34c>
ffffffffc0201f80:	02d00693          	li	a3,45
ffffffffc0201f84:	f6d79de3          	bne	a5,a3,ffffffffc0201efe <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201f88:	00001417          	auipc	s0,0x1
ffffffffc0201f8c:	42840413          	addi	s0,s0,1064 # ffffffffc02033b0 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201f90:	02800793          	li	a5,40
ffffffffc0201f94:	02800513          	li	a0,40
ffffffffc0201f98:	00140a13          	addi	s4,s0,1
ffffffffc0201f9c:	bd6d                	j	ffffffffc0201e56 <vprintfmt+0x204>
ffffffffc0201f9e:	00001a17          	auipc	s4,0x1
ffffffffc0201fa2:	413a0a13          	addi	s4,s4,1043 # ffffffffc02033b1 <default_pmm_manager+0x199>
ffffffffc0201fa6:	02800513          	li	a0,40
ffffffffc0201faa:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201fae:	05e00413          	li	s0,94
ffffffffc0201fb2:	b565                	j	ffffffffc0201e5a <vprintfmt+0x208>

ffffffffc0201fb4 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201fb4:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201fb6:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201fba:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201fbc:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201fbe:	ec06                	sd	ra,24(sp)
ffffffffc0201fc0:	f83a                	sd	a4,48(sp)
ffffffffc0201fc2:	fc3e                	sd	a5,56(sp)
ffffffffc0201fc4:	e0c2                	sd	a6,64(sp)
ffffffffc0201fc6:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201fc8:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201fca:	c89ff0ef          	jal	ra,ffffffffc0201c52 <vprintfmt>
}
ffffffffc0201fce:	60e2                	ld	ra,24(sp)
ffffffffc0201fd0:	6161                	addi	sp,sp,80
ffffffffc0201fd2:	8082                	ret

ffffffffc0201fd4 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201fd4:	715d                	addi	sp,sp,-80
ffffffffc0201fd6:	e486                	sd	ra,72(sp)
ffffffffc0201fd8:	e0a6                	sd	s1,64(sp)
ffffffffc0201fda:	fc4a                	sd	s2,56(sp)
ffffffffc0201fdc:	f84e                	sd	s3,48(sp)
ffffffffc0201fde:	f452                	sd	s4,40(sp)
ffffffffc0201fe0:	f056                	sd	s5,32(sp)
ffffffffc0201fe2:	ec5a                	sd	s6,24(sp)
ffffffffc0201fe4:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201fe6:	c901                	beqz	a0,ffffffffc0201ff6 <readline+0x22>
ffffffffc0201fe8:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201fea:	00001517          	auipc	a0,0x1
ffffffffc0201fee:	3de50513          	addi	a0,a0,990 # ffffffffc02033c8 <default_pmm_manager+0x1b0>
ffffffffc0201ff2:	91cfe0ef          	jal	ra,ffffffffc020010e <cprintf>
readline(const char *prompt) {
ffffffffc0201ff6:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ff8:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201ffa:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201ffc:	4aa9                	li	s5,10
ffffffffc0201ffe:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0202000:	00005b97          	auipc	s7,0x5
ffffffffc0202004:	040b8b93          	addi	s7,s7,64 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0202008:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020200c:	97afe0ef          	jal	ra,ffffffffc0200186 <getchar>
        if (c < 0) {
ffffffffc0202010:	00054a63          	bltz	a0,ffffffffc0202024 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0202014:	00a95a63          	bge	s2,a0,ffffffffc0202028 <readline+0x54>
ffffffffc0202018:	029a5263          	bge	s4,s1,ffffffffc020203c <readline+0x68>
        c = getchar();
ffffffffc020201c:	96afe0ef          	jal	ra,ffffffffc0200186 <getchar>
        if (c < 0) {
ffffffffc0202020:	fe055ae3          	bgez	a0,ffffffffc0202014 <readline+0x40>
            return NULL;
ffffffffc0202024:	4501                	li	a0,0
ffffffffc0202026:	a091                	j	ffffffffc020206a <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0202028:	03351463          	bne	a0,s3,ffffffffc0202050 <readline+0x7c>
ffffffffc020202c:	e8a9                	bnez	s1,ffffffffc020207e <readline+0xaa>
        c = getchar();
ffffffffc020202e:	958fe0ef          	jal	ra,ffffffffc0200186 <getchar>
        if (c < 0) {
ffffffffc0202032:	fe0549e3          	bltz	a0,ffffffffc0202024 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0202036:	fea959e3          	bge	s2,a0,ffffffffc0202028 <readline+0x54>
ffffffffc020203a:	4481                	li	s1,0
            cputchar(c);
ffffffffc020203c:	e42a                	sd	a0,8(sp)
ffffffffc020203e:	906fe0ef          	jal	ra,ffffffffc0200144 <cputchar>
            buf[i ++] = c;
ffffffffc0202042:	6522                	ld	a0,8(sp)
ffffffffc0202044:	009b87b3          	add	a5,s7,s1
ffffffffc0202048:	2485                	addiw	s1,s1,1
ffffffffc020204a:	00a78023          	sb	a0,0(a5)
ffffffffc020204e:	bf7d                	j	ffffffffc020200c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0202050:	01550463          	beq	a0,s5,ffffffffc0202058 <readline+0x84>
ffffffffc0202054:	fb651ce3          	bne	a0,s6,ffffffffc020200c <readline+0x38>
            cputchar(c);
ffffffffc0202058:	8ecfe0ef          	jal	ra,ffffffffc0200144 <cputchar>
            buf[i] = '\0';
ffffffffc020205c:	00005517          	auipc	a0,0x5
ffffffffc0202060:	fe450513          	addi	a0,a0,-28 # ffffffffc0207040 <buf>
ffffffffc0202064:	94aa                	add	s1,s1,a0
ffffffffc0202066:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020206a:	60a6                	ld	ra,72(sp)
ffffffffc020206c:	6486                	ld	s1,64(sp)
ffffffffc020206e:	7962                	ld	s2,56(sp)
ffffffffc0202070:	79c2                	ld	s3,48(sp)
ffffffffc0202072:	7a22                	ld	s4,40(sp)
ffffffffc0202074:	7a82                	ld	s5,32(sp)
ffffffffc0202076:	6b62                	ld	s6,24(sp)
ffffffffc0202078:	6bc2                	ld	s7,16(sp)
ffffffffc020207a:	6161                	addi	sp,sp,80
ffffffffc020207c:	8082                	ret
            cputchar(c);
ffffffffc020207e:	4521                	li	a0,8
ffffffffc0202080:	8c4fe0ef          	jal	ra,ffffffffc0200144 <cputchar>
            i --;
ffffffffc0202084:	34fd                	addiw	s1,s1,-1
ffffffffc0202086:	b759                	j	ffffffffc020200c <readline+0x38>

ffffffffc0202088 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0202088:	4781                	li	a5,0
ffffffffc020208a:	00005717          	auipc	a4,0x5
ffffffffc020208e:	f8e73703          	ld	a4,-114(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0202092:	88ba                	mv	a7,a4
ffffffffc0202094:	852a                	mv	a0,a0
ffffffffc0202096:	85be                	mv	a1,a5
ffffffffc0202098:	863e                	mv	a2,a5
ffffffffc020209a:	00000073          	ecall
ffffffffc020209e:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02020a0:	8082                	ret

ffffffffc02020a2 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc02020a2:	4781                	li	a5,0
ffffffffc02020a4:	00005717          	auipc	a4,0x5
ffffffffc02020a8:	3f473703          	ld	a4,1012(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc02020ac:	88ba                	mv	a7,a4
ffffffffc02020ae:	852a                	mv	a0,a0
ffffffffc02020b0:	85be                	mv	a1,a5
ffffffffc02020b2:	863e                	mv	a2,a5
ffffffffc02020b4:	00000073          	ecall
ffffffffc02020b8:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc02020ba:	8082                	ret

ffffffffc02020bc <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc02020bc:	4501                	li	a0,0
ffffffffc02020be:	00005797          	auipc	a5,0x5
ffffffffc02020c2:	f527b783          	ld	a5,-174(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc02020c6:	88be                	mv	a7,a5
ffffffffc02020c8:	852a                	mv	a0,a0
ffffffffc02020ca:	85aa                	mv	a1,a0
ffffffffc02020cc:	862a                	mv	a2,a0
ffffffffc02020ce:	00000073          	ecall
ffffffffc02020d2:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc02020d4:	2501                	sext.w	a0,a0
ffffffffc02020d6:	8082                	ret

ffffffffc02020d8 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc02020d8:	4781                	li	a5,0
ffffffffc02020da:	00005717          	auipc	a4,0x5
ffffffffc02020de:	f4673703          	ld	a4,-186(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc02020e2:	88ba                	mv	a7,a4
ffffffffc02020e4:	853e                	mv	a0,a5
ffffffffc02020e6:	85be                	mv	a1,a5
ffffffffc02020e8:	863e                	mv	a2,a5
ffffffffc02020ea:	00000073          	ecall
ffffffffc02020ee:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc02020f0:	8082                	ret

ffffffffc02020f2 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02020f2:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02020f6:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02020f8:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02020fa:	cb81                	beqz	a5,ffffffffc020210a <strlen+0x18>
        cnt ++;
ffffffffc02020fc:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02020fe:	00a707b3          	add	a5,a4,a0
ffffffffc0202102:	0007c783          	lbu	a5,0(a5)
ffffffffc0202106:	fbfd                	bnez	a5,ffffffffc02020fc <strlen+0xa>
ffffffffc0202108:	8082                	ret
    }
    return cnt;
}
ffffffffc020210a:	8082                	ret

ffffffffc020210c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020210c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020210e:	e589                	bnez	a1,ffffffffc0202118 <strnlen+0xc>
ffffffffc0202110:	a811                	j	ffffffffc0202124 <strnlen+0x18>
        cnt ++;
ffffffffc0202112:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202114:	00f58863          	beq	a1,a5,ffffffffc0202124 <strnlen+0x18>
ffffffffc0202118:	00f50733          	add	a4,a0,a5
ffffffffc020211c:	00074703          	lbu	a4,0(a4)
ffffffffc0202120:	fb6d                	bnez	a4,ffffffffc0202112 <strnlen+0x6>
ffffffffc0202122:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0202124:	852e                	mv	a0,a1
ffffffffc0202126:	8082                	ret

ffffffffc0202128 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202128:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020212c:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202130:	cb89                	beqz	a5,ffffffffc0202142 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0202132:	0505                	addi	a0,a0,1
ffffffffc0202134:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202136:	fee789e3          	beq	a5,a4,ffffffffc0202128 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020213a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020213e:	9d19                	subw	a0,a0,a4
ffffffffc0202140:	8082                	ret
ffffffffc0202142:	4501                	li	a0,0
ffffffffc0202144:	bfed                	j	ffffffffc020213e <strcmp+0x16>

ffffffffc0202146 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202146:	c20d                	beqz	a2,ffffffffc0202168 <strncmp+0x22>
ffffffffc0202148:	962e                	add	a2,a2,a1
ffffffffc020214a:	a031                	j	ffffffffc0202156 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc020214c:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020214e:	00e79a63          	bne	a5,a4,ffffffffc0202162 <strncmp+0x1c>
ffffffffc0202152:	00b60b63          	beq	a2,a1,ffffffffc0202168 <strncmp+0x22>
ffffffffc0202156:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc020215a:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020215c:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0202160:	f7f5                	bnez	a5,ffffffffc020214c <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202162:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0202166:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202168:	4501                	li	a0,0
ffffffffc020216a:	8082                	ret

ffffffffc020216c <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc020216c:	00054783          	lbu	a5,0(a0)
ffffffffc0202170:	c799                	beqz	a5,ffffffffc020217e <strchr+0x12>
        if (*s == c) {
ffffffffc0202172:	00f58763          	beq	a1,a5,ffffffffc0202180 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0202176:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc020217a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020217c:	fbfd                	bnez	a5,ffffffffc0202172 <strchr+0x6>
    }
    return NULL;
ffffffffc020217e:	4501                	li	a0,0
}
ffffffffc0202180:	8082                	ret

ffffffffc0202182 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0202182:	ca01                	beqz	a2,ffffffffc0202192 <memset+0x10>
ffffffffc0202184:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0202186:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0202188:	0785                	addi	a5,a5,1
ffffffffc020218a:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020218e:	fec79de3          	bne	a5,a2,ffffffffc0202188 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0202192:	8082                	ret
