
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
ffffffffc020006c:	112020ef          	jal	ra,ffffffffc020217e <memset>
    dtb_init();
ffffffffc0200070:	444000ef          	jal	ra,ffffffffc02004b4 <dtb_init>

    cons_init();  // 初始化控制台
ffffffffc0200074:	432000ef          	jal	ra,ffffffffc02004a6 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	1d050513          	addi	a0,a0,464 # ffffffffc0202248 <etext+0xb8>
ffffffffc0200080:	0c6000ef          	jal	ra,ffffffffc0200146 <cputs>

    print_kerninfo();
ffffffffc0200084:	112000ef          	jal	ra,ffffffffc0200196 <print_kerninfo>

    idt_init();  // 初始化中断描述符表
ffffffffc0200088:	7e8000ef          	jal	ra,ffffffffc0200870 <idt_init>

    pmm_init();  // 初始化物理内存管理
ffffffffc020008c:	177010ef          	jal	ra,ffffffffc0201a02 <pmm_init>

    idt_init();  // 再次初始化中断描述符表（防止被覆盖）
ffffffffc0200090:	7e0000ef          	jal	ra,ffffffffc0200870 <idt_init>

    clock_init();   // 初始化时钟中断
ffffffffc0200094:	3d0000ef          	jal	ra,ffffffffc0200464 <clock_init>
    intr_enable();  // 开启中断
ffffffffc0200098:	7cc000ef          	jal	ra,ffffffffc0200864 <intr_enable>

    /* ------------------- Challenge 3 验证代码开始 ------------------- */
    cprintf("\n=== Challenge 3: Testing Exception Handling ===\n");
ffffffffc020009c:	00002517          	auipc	a0,0x2
ffffffffc02000a0:	0f450513          	addi	a0,a0,244 # ffffffffc0202190 <etext>
ffffffffc02000a4:	06a000ef          	jal	ra,ffffffffc020010e <cprintf>

    // 测试非法指令异常
    cprintf("Testing illegal instruction exception...\n");
ffffffffc02000a8:	00002517          	auipc	a0,0x2
ffffffffc02000ac:	12050513          	addi	a0,a0,288 # ffffffffc02021c8 <etext+0x38>
ffffffffc02000b0:	05e000ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02000b4:	0000                	unimp
ffffffffc02000b6:	0000                	unimp
    asm volatile(".word 0x00000000");   // 强制执行非法指令

    // 测试断点异常
    cprintf("Testing breakpoint exception...\n");
ffffffffc02000b8:	00002517          	auipc	a0,0x2
ffffffffc02000bc:	14050513          	addi	a0,a0,320 # ffffffffc02021f8 <etext+0x68>
ffffffffc02000c0:	04e000ef          	jal	ra,ffffffffc020010e <cprintf>
    asm volatile("ebreak");             // 执行断点指令
ffffffffc02000c4:	9002                	ebreak

    cprintf("=== Challenge 3: Tests Finished ===\n\n");
ffffffffc02000c6:	00002517          	auipc	a0,0x2
ffffffffc02000ca:	15a50513          	addi	a0,a0,346 # ffffffffc0202220 <etext+0x90>
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
ffffffffc0200102:	34d010ef          	jal	ra,ffffffffc0201c4e <vprintfmt>
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
ffffffffc0200138:	317010ef          	jal	ra,ffffffffc0201c4e <vprintfmt>
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
ffffffffc020019c:	0d050513          	addi	a0,a0,208 # ffffffffc0202268 <etext+0xd8>
void print_kerninfo(void) {
ffffffffc02001a0:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001a2:	f6dff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001a6:	00000597          	auipc	a1,0x0
ffffffffc02001aa:	eae58593          	addi	a1,a1,-338 # ffffffffc0200054 <kern_init>
ffffffffc02001ae:	00002517          	auipc	a0,0x2
ffffffffc02001b2:	0da50513          	addi	a0,a0,218 # ffffffffc0202288 <etext+0xf8>
ffffffffc02001b6:	f59ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001ba:	00002597          	auipc	a1,0x2
ffffffffc02001be:	fd658593          	addi	a1,a1,-42 # ffffffffc0202190 <etext>
ffffffffc02001c2:	00002517          	auipc	a0,0x2
ffffffffc02001c6:	0e650513          	addi	a0,a0,230 # ffffffffc02022a8 <etext+0x118>
ffffffffc02001ca:	f45ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001ce:	00007597          	auipc	a1,0x7
ffffffffc02001d2:	e5a58593          	addi	a1,a1,-422 # ffffffffc0207028 <free_area>
ffffffffc02001d6:	00002517          	auipc	a0,0x2
ffffffffc02001da:	0f250513          	addi	a0,a0,242 # ffffffffc02022c8 <etext+0x138>
ffffffffc02001de:	f31ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001e2:	00007597          	auipc	a1,0x7
ffffffffc02001e6:	2be58593          	addi	a1,a1,702 # ffffffffc02074a0 <end>
ffffffffc02001ea:	00002517          	auipc	a0,0x2
ffffffffc02001ee:	0fe50513          	addi	a0,a0,254 # ffffffffc02022e8 <etext+0x158>
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
ffffffffc020021c:	0f050513          	addi	a0,a0,240 # ffffffffc0202308 <etext+0x178>
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
ffffffffc020022a:	11260613          	addi	a2,a2,274 # ffffffffc0202338 <etext+0x1a8>
ffffffffc020022e:	04d00593          	li	a1,77
ffffffffc0200232:	00002517          	auipc	a0,0x2
ffffffffc0200236:	11e50513          	addi	a0,a0,286 # ffffffffc0202350 <etext+0x1c0>
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
ffffffffc0200246:	12660613          	addi	a2,a2,294 # ffffffffc0202368 <etext+0x1d8>
ffffffffc020024a:	00002597          	auipc	a1,0x2
ffffffffc020024e:	13e58593          	addi	a1,a1,318 # ffffffffc0202388 <etext+0x1f8>
ffffffffc0200252:	00002517          	auipc	a0,0x2
ffffffffc0200256:	13e50513          	addi	a0,a0,318 # ffffffffc0202390 <etext+0x200>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020025c:	eb3ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200260:	00002617          	auipc	a2,0x2
ffffffffc0200264:	14060613          	addi	a2,a2,320 # ffffffffc02023a0 <etext+0x210>
ffffffffc0200268:	00002597          	auipc	a1,0x2
ffffffffc020026c:	16058593          	addi	a1,a1,352 # ffffffffc02023c8 <etext+0x238>
ffffffffc0200270:	00002517          	auipc	a0,0x2
ffffffffc0200274:	12050513          	addi	a0,a0,288 # ffffffffc0202390 <etext+0x200>
ffffffffc0200278:	e97ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc020027c:	00002617          	auipc	a2,0x2
ffffffffc0200280:	15c60613          	addi	a2,a2,348 # ffffffffc02023d8 <etext+0x248>
ffffffffc0200284:	00002597          	auipc	a1,0x2
ffffffffc0200288:	17458593          	addi	a1,a1,372 # ffffffffc02023f8 <etext+0x268>
ffffffffc020028c:	00002517          	auipc	a0,0x2
ffffffffc0200290:	10450513          	addi	a0,a0,260 # ffffffffc0202390 <etext+0x200>
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
ffffffffc02002ca:	14250513          	addi	a0,a0,322 # ffffffffc0202408 <etext+0x278>
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
ffffffffc02002ec:	14850513          	addi	a0,a0,328 # ffffffffc0202430 <etext+0x2a0>
ffffffffc02002f0:	e1fff0ef          	jal	ra,ffffffffc020010e <cprintf>
    if (tf != NULL) {
ffffffffc02002f4:	000b8563          	beqz	s7,ffffffffc02002fe <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002f8:	855e                	mv	a0,s7
ffffffffc02002fa:	756000ef          	jal	ra,ffffffffc0200a50 <print_trapframe>
ffffffffc02002fe:	00002c17          	auipc	s8,0x2
ffffffffc0200302:	1a2c0c13          	addi	s8,s8,418 # ffffffffc02024a0 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200306:	00002917          	auipc	s2,0x2
ffffffffc020030a:	15290913          	addi	s2,s2,338 # ffffffffc0202458 <etext+0x2c8>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030e:	00002497          	auipc	s1,0x2
ffffffffc0200312:	15248493          	addi	s1,s1,338 # ffffffffc0202460 <etext+0x2d0>
        if (argc == MAXARGS - 1) {
ffffffffc0200316:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200318:	00002b17          	auipc	s6,0x2
ffffffffc020031c:	150b0b13          	addi	s6,s6,336 # ffffffffc0202468 <etext+0x2d8>
        argv[argc ++] = buf;
ffffffffc0200320:	00002a17          	auipc	s4,0x2
ffffffffc0200324:	068a0a13          	addi	s4,s4,104 # ffffffffc0202388 <etext+0x1f8>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200328:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020032a:	854a                	mv	a0,s2
ffffffffc020032c:	4a5010ef          	jal	ra,ffffffffc0201fd0 <readline>
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
ffffffffc0200346:	15ed0d13          	addi	s10,s10,350 # ffffffffc02024a0 <commands>
        argv[argc ++] = buf;
ffffffffc020034a:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034c:	4401                	li	s0,0
ffffffffc020034e:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200350:	5d5010ef          	jal	ra,ffffffffc0202124 <strcmp>
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
ffffffffc0200364:	5c1010ef          	jal	ra,ffffffffc0202124 <strcmp>
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
ffffffffc02003a2:	5c7010ef          	jal	ra,ffffffffc0202168 <strchr>
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
ffffffffc02003e0:	589010ef          	jal	ra,ffffffffc0202168 <strchr>
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
ffffffffc02003fe:	08e50513          	addi	a0,a0,142 # ffffffffc0202488 <etext+0x2f8>
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
ffffffffc020043a:	0b250513          	addi	a0,a0,178 # ffffffffc02024e8 <commands+0x48>
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
ffffffffc0200450:	da450513          	addi	a0,a0,-604 # ffffffffc02021f0 <etext+0x60>
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
ffffffffc020047c:	423010ef          	jal	ra,ffffffffc020209e <sbi_set_timer>
}
ffffffffc0200480:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200482:	00007797          	auipc	a5,0x7
ffffffffc0200486:	fc07b323          	sd	zero,-58(a5) # ffffffffc0207448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020048a:	00002517          	auipc	a0,0x2
ffffffffc020048e:	07e50513          	addi	a0,a0,126 # ffffffffc0202508 <commands+0x68>
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
ffffffffc02004a2:	3fd0106f          	j	ffffffffc020209e <sbi_set_timer>

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
ffffffffc02004ac:	3d90106f          	j	ffffffffc0202084 <sbi_console_putchar>

ffffffffc02004b0 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc02004b0:	4090106f          	j	ffffffffc02020b8 <sbi_console_getchar>

ffffffffc02004b4 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004b4:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc02004b6:	00002517          	auipc	a0,0x2
ffffffffc02004ba:	07250513          	addi	a0,a0,114 # ffffffffc0202528 <commands+0x88>
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
ffffffffc02004e8:	05450513          	addi	a0,a0,84 # ffffffffc0202538 <commands+0x98>
ffffffffc02004ec:	c23ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004f0:	00007417          	auipc	s0,0x7
ffffffffc02004f4:	b1840413          	addi	s0,s0,-1256 # ffffffffc0207008 <boot_dtb>
ffffffffc02004f8:	600c                	ld	a1,0(s0)
ffffffffc02004fa:	00002517          	auipc	a0,0x2
ffffffffc02004fe:	04e50513          	addi	a0,a0,78 # ffffffffc0202548 <commands+0xa8>
ffffffffc0200502:	c0dff0ef          	jal	ra,ffffffffc020010e <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200506:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020050a:	00002517          	auipc	a0,0x2
ffffffffc020050e:	05650513          	addi	a0,a0,86 # ffffffffc0202560 <commands+0xc0>
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
ffffffffc02005c8:	fec90913          	addi	s2,s2,-20 # ffffffffc02025b0 <commands+0x110>
ffffffffc02005cc:	49bd                	li	s3,15
        switch (token) {
ffffffffc02005ce:	4d91                	li	s11,4
ffffffffc02005d0:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02005d2:	00002497          	auipc	s1,0x2
ffffffffc02005d6:	fd648493          	addi	s1,s1,-42 # ffffffffc02025a8 <commands+0x108>
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
ffffffffc020062a:	00250513          	addi	a0,a0,2 # ffffffffc0202628 <commands+0x188>
ffffffffc020062e:	ae1ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200632:	00002517          	auipc	a0,0x2
ffffffffc0200636:	02e50513          	addi	a0,a0,46 # ffffffffc0202660 <commands+0x1c0>
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
ffffffffc0200676:	f0e50513          	addi	a0,a0,-242 # ffffffffc0202580 <commands+0xe0>
}
ffffffffc020067a:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020067c:	bc49                	j	ffffffffc020010e <cprintf>
                int name_len = strlen(name);
ffffffffc020067e:	8556                	mv	a0,s5
ffffffffc0200680:	26f010ef          	jal	ra,ffffffffc02020ee <strlen>
ffffffffc0200684:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200686:	4619                	li	a2,6
ffffffffc0200688:	85a6                	mv	a1,s1
ffffffffc020068a:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc020068c:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020068e:	2b5010ef          	jal	ra,ffffffffc0202142 <strncmp>
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
ffffffffc0200724:	201010ef          	jal	ra,ffffffffc0202124 <strcmp>
ffffffffc0200728:	66a2                	ld	a3,8(sp)
ffffffffc020072a:	f94d                	bnez	a0,ffffffffc02006dc <dtb_init+0x228>
ffffffffc020072c:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006dc <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200730:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200734:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200738:	00002517          	auipc	a0,0x2
ffffffffc020073c:	e8050513          	addi	a0,a0,-384 # ffffffffc02025b8 <commands+0x118>
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
ffffffffc020080a:	dd250513          	addi	a0,a0,-558 # ffffffffc02025d8 <commands+0x138>
ffffffffc020080e:	901ff0ef          	jal	ra,ffffffffc020010e <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200812:	014b5613          	srli	a2,s6,0x14
ffffffffc0200816:	85da                	mv	a1,s6
ffffffffc0200818:	00002517          	auipc	a0,0x2
ffffffffc020081c:	dd850513          	addi	a0,a0,-552 # ffffffffc02025f0 <commands+0x150>
ffffffffc0200820:	8efff0ef          	jal	ra,ffffffffc020010e <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200824:	008b05b3          	add	a1,s6,s0
ffffffffc0200828:	15fd                	addi	a1,a1,-1
ffffffffc020082a:	00002517          	auipc	a0,0x2
ffffffffc020082e:	de650513          	addi	a0,a0,-538 # ffffffffc0202610 <commands+0x170>
ffffffffc0200832:	8ddff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200836:	00002517          	auipc	a0,0x2
ffffffffc020083a:	e2a50513          	addi	a0,a0,-470 # ffffffffc0202660 <commands+0x1c0>
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
ffffffffc0200878:	54878793          	addi	a5,a5,1352 # ffffffffc0200dbc <__alltraps>
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
ffffffffc020088e:	dee50513          	addi	a0,a0,-530 # ffffffffc0202678 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200892:	e406                	sd	ra,8(sp)
    PRINT_REG(zero); PRINT_REG(ra); PRINT_REG(sp); PRINT_REG(gp); PRINT_REG(tp);
ffffffffc0200894:	87bff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200898:	640c                	ld	a1,8(s0)
ffffffffc020089a:	00002517          	auipc	a0,0x2
ffffffffc020089e:	df650513          	addi	a0,a0,-522 # ffffffffc0202690 <commands+0x1f0>
ffffffffc02008a2:	86dff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008a6:	680c                	ld	a1,16(s0)
ffffffffc02008a8:	00002517          	auipc	a0,0x2
ffffffffc02008ac:	df850513          	addi	a0,a0,-520 # ffffffffc02026a0 <commands+0x200>
ffffffffc02008b0:	85fff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008b4:	6c0c                	ld	a1,24(s0)
ffffffffc02008b6:	00002517          	auipc	a0,0x2
ffffffffc02008ba:	dfa50513          	addi	a0,a0,-518 # ffffffffc02026b0 <commands+0x210>
ffffffffc02008be:	851ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008c2:	700c                	ld	a1,32(s0)
ffffffffc02008c4:	00002517          	auipc	a0,0x2
ffffffffc02008c8:	dfc50513          	addi	a0,a0,-516 # ffffffffc02026c0 <commands+0x220>
ffffffffc02008cc:	843ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(t0); PRINT_REG(t1); PRINT_REG(t2); PRINT_REG(s0); PRINT_REG(s1);
ffffffffc02008d0:	740c                	ld	a1,40(s0)
ffffffffc02008d2:	00002517          	auipc	a0,0x2
ffffffffc02008d6:	dfe50513          	addi	a0,a0,-514 # ffffffffc02026d0 <commands+0x230>
ffffffffc02008da:	835ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008de:	780c                	ld	a1,48(s0)
ffffffffc02008e0:	00002517          	auipc	a0,0x2
ffffffffc02008e4:	e0050513          	addi	a0,a0,-512 # ffffffffc02026e0 <commands+0x240>
ffffffffc02008e8:	827ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008ec:	7c0c                	ld	a1,56(s0)
ffffffffc02008ee:	00002517          	auipc	a0,0x2
ffffffffc02008f2:	e0250513          	addi	a0,a0,-510 # ffffffffc02026f0 <commands+0x250>
ffffffffc02008f6:	819ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02008fa:	602c                	ld	a1,64(s0)
ffffffffc02008fc:	00002517          	auipc	a0,0x2
ffffffffc0200900:	e0450513          	addi	a0,a0,-508 # ffffffffc0202700 <commands+0x260>
ffffffffc0200904:	80bff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200908:	642c                	ld	a1,72(s0)
ffffffffc020090a:	00002517          	auipc	a0,0x2
ffffffffc020090e:	e0650513          	addi	a0,a0,-506 # ffffffffc0202710 <commands+0x270>
ffffffffc0200912:	ffcff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(a0); PRINT_REG(a1); PRINT_REG(a2); PRINT_REG(a3); PRINT_REG(a4);
ffffffffc0200916:	682c                	ld	a1,80(s0)
ffffffffc0200918:	00002517          	auipc	a0,0x2
ffffffffc020091c:	e0850513          	addi	a0,a0,-504 # ffffffffc0202720 <commands+0x280>
ffffffffc0200920:	feeff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200924:	6c2c                	ld	a1,88(s0)
ffffffffc0200926:	00002517          	auipc	a0,0x2
ffffffffc020092a:	e0a50513          	addi	a0,a0,-502 # ffffffffc0202730 <commands+0x290>
ffffffffc020092e:	fe0ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200932:	702c                	ld	a1,96(s0)
ffffffffc0200934:	00002517          	auipc	a0,0x2
ffffffffc0200938:	e0c50513          	addi	a0,a0,-500 # ffffffffc0202740 <commands+0x2a0>
ffffffffc020093c:	fd2ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200940:	742c                	ld	a1,104(s0)
ffffffffc0200942:	00002517          	auipc	a0,0x2
ffffffffc0200946:	e0e50513          	addi	a0,a0,-498 # ffffffffc0202750 <commands+0x2b0>
ffffffffc020094a:	fc4ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc020094e:	782c                	ld	a1,112(s0)
ffffffffc0200950:	00002517          	auipc	a0,0x2
ffffffffc0200954:	e1050513          	addi	a0,a0,-496 # ffffffffc0202760 <commands+0x2c0>
ffffffffc0200958:	fb6ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(a5); PRINT_REG(a6); PRINT_REG(a7);
ffffffffc020095c:	7c2c                	ld	a1,120(s0)
ffffffffc020095e:	00002517          	auipc	a0,0x2
ffffffffc0200962:	e1250513          	addi	a0,a0,-494 # ffffffffc0202770 <commands+0x2d0>
ffffffffc0200966:	fa8ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc020096a:	604c                	ld	a1,128(s0)
ffffffffc020096c:	00002517          	auipc	a0,0x2
ffffffffc0200970:	e1450513          	addi	a0,a0,-492 # ffffffffc0202780 <commands+0x2e0>
ffffffffc0200974:	f9aff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200978:	644c                	ld	a1,136(s0)
ffffffffc020097a:	00002517          	auipc	a0,0x2
ffffffffc020097e:	e1650513          	addi	a0,a0,-490 # ffffffffc0202790 <commands+0x2f0>
ffffffffc0200982:	f8cff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(s2); PRINT_REG(s3); PRINT_REG(s4); PRINT_REG(s5); PRINT_REG(s6);
ffffffffc0200986:	684c                	ld	a1,144(s0)
ffffffffc0200988:	00002517          	auipc	a0,0x2
ffffffffc020098c:	e1850513          	addi	a0,a0,-488 # ffffffffc02027a0 <commands+0x300>
ffffffffc0200990:	f7eff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200994:	6c4c                	ld	a1,152(s0)
ffffffffc0200996:	00002517          	auipc	a0,0x2
ffffffffc020099a:	e1a50513          	addi	a0,a0,-486 # ffffffffc02027b0 <commands+0x310>
ffffffffc020099e:	f70ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009a2:	704c                	ld	a1,160(s0)
ffffffffc02009a4:	00002517          	auipc	a0,0x2
ffffffffc02009a8:	e1c50513          	addi	a0,a0,-484 # ffffffffc02027c0 <commands+0x320>
ffffffffc02009ac:	f62ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009b0:	744c                	ld	a1,168(s0)
ffffffffc02009b2:	00002517          	auipc	a0,0x2
ffffffffc02009b6:	e1e50513          	addi	a0,a0,-482 # ffffffffc02027d0 <commands+0x330>
ffffffffc02009ba:	f54ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009be:	784c                	ld	a1,176(s0)
ffffffffc02009c0:	00002517          	auipc	a0,0x2
ffffffffc02009c4:	e2050513          	addi	a0,a0,-480 # ffffffffc02027e0 <commands+0x340>
ffffffffc02009c8:	f46ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(s7); PRINT_REG(s8); PRINT_REG(s9); PRINT_REG(s10); PRINT_REG(s11);
ffffffffc02009cc:	7c4c                	ld	a1,184(s0)
ffffffffc02009ce:	00002517          	auipc	a0,0x2
ffffffffc02009d2:	e2250513          	addi	a0,a0,-478 # ffffffffc02027f0 <commands+0x350>
ffffffffc02009d6:	f38ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009da:	606c                	ld	a1,192(s0)
ffffffffc02009dc:	00002517          	auipc	a0,0x2
ffffffffc02009e0:	e2450513          	addi	a0,a0,-476 # ffffffffc0202800 <commands+0x360>
ffffffffc02009e4:	f2aff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009e8:	646c                	ld	a1,200(s0)
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	e2650513          	addi	a0,a0,-474 # ffffffffc0202810 <commands+0x370>
ffffffffc02009f2:	f1cff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc02009f6:	686c                	ld	a1,208(s0)
ffffffffc02009f8:	00002517          	auipc	a0,0x2
ffffffffc02009fc:	e2850513          	addi	a0,a0,-472 # ffffffffc0202820 <commands+0x380>
ffffffffc0200a00:	f0eff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200a04:	6c6c                	ld	a1,216(s0)
ffffffffc0200a06:	00002517          	auipc	a0,0x2
ffffffffc0200a0a:	e2a50513          	addi	a0,a0,-470 # ffffffffc0202830 <commands+0x390>
ffffffffc0200a0e:	f00ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    PRINT_REG(t3); PRINT_REG(t4); PRINT_REG(t5); PRINT_REG(t6);
ffffffffc0200a12:	706c                	ld	a1,224(s0)
ffffffffc0200a14:	00002517          	auipc	a0,0x2
ffffffffc0200a18:	e2c50513          	addi	a0,a0,-468 # ffffffffc0202840 <commands+0x3a0>
ffffffffc0200a1c:	ef2ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200a20:	746c                	ld	a1,232(s0)
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	e2e50513          	addi	a0,a0,-466 # ffffffffc0202850 <commands+0x3b0>
ffffffffc0200a2a:	ee4ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200a2e:	786c                	ld	a1,240(s0)
ffffffffc0200a30:	00002517          	auipc	a0,0x2
ffffffffc0200a34:	e3050513          	addi	a0,a0,-464 # ffffffffc0202860 <commands+0x3c0>
ffffffffc0200a38:	ed6ff0ef          	jal	ra,ffffffffc020010e <cprintf>
ffffffffc0200a3c:	7c6c                	ld	a1,248(s0)
    #undef PRINT_REG
}
ffffffffc0200a3e:	6402                	ld	s0,0(sp)
ffffffffc0200a40:	60a2                	ld	ra,8(sp)
    PRINT_REG(t3); PRINT_REG(t4); PRINT_REG(t5); PRINT_REG(t6);
ffffffffc0200a42:	00002517          	auipc	a0,0x2
ffffffffc0200a46:	e2e50513          	addi	a0,a0,-466 # ffffffffc0202870 <commands+0x3d0>
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
ffffffffc0200a5c:	e2850513          	addi	a0,a0,-472 # ffffffffc0202880 <commands+0x3e0>
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
ffffffffc0200a74:	e2850513          	addi	a0,a0,-472 # ffffffffc0202898 <commands+0x3f8>
ffffffffc0200a78:	e96ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  epc      0x%08lx\n", tf->epc);
ffffffffc0200a7c:	10843583          	ld	a1,264(s0)
ffffffffc0200a80:	00002517          	auipc	a0,0x2
ffffffffc0200a84:	e3050513          	addi	a0,a0,-464 # ffffffffc02028b0 <commands+0x410>
ffffffffc0200a88:	e86ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  badvaddr 0x%08lx\n", tf->badvaddr);
ffffffffc0200a8c:	11043583          	ld	a1,272(s0)
ffffffffc0200a90:	00002517          	auipc	a0,0x2
ffffffffc0200a94:	e3850513          	addi	a0,a0,-456 # ffffffffc02028c8 <commands+0x428>
ffffffffc0200a98:	e76ff0ef          	jal	ra,ffffffffc020010e <cprintf>
    cprintf("  cause    0x%08lx\n", tf->cause);
ffffffffc0200a9c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200aa0:	6402                	ld	s0,0(sp)
ffffffffc0200aa2:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08lx\n", tf->cause);
ffffffffc0200aa4:	00002517          	auipc	a0,0x2
ffffffffc0200aa8:	e3c50513          	addi	a0,a0,-452 # ffffffffc02028e0 <commands+0x440>
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
ffffffffc0200ac4:	f9c70713          	addi	a4,a4,-100 # ffffffffc0202a5c <commands+0x5bc>
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
ffffffffc0200ad6:	f4e50513          	addi	a0,a0,-178 # ffffffffc0202a20 <commands+0x580>
ffffffffc0200ada:	e34ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_M_EXT: cprintf("Machine external interrupt\n"); break;
ffffffffc0200ade:	00002517          	auipc	a0,0x2
ffffffffc0200ae2:	f6250513          	addi	a0,a0,-158 # ffffffffc0202a40 <commands+0x5a0>
ffffffffc0200ae6:	e28ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_U_SOFT: cprintf("User software interrupt\n"); break;
ffffffffc0200aea:	00002517          	auipc	a0,0x2
ffffffffc0200aee:	e1e50513          	addi	a0,a0,-482 # ffffffffc0202908 <commands+0x468>
ffffffffc0200af2:	e1cff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_S_SOFT: cprintf("Supervisor software interrupt\n"); break;
ffffffffc0200af6:	00002517          	auipc	a0,0x2
ffffffffc0200afa:	e3250513          	addi	a0,a0,-462 # ffffffffc0202928 <commands+0x488>
ffffffffc0200afe:	e10ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_H_SOFT: cprintf("Hypervisor software interrupt\n"); break;
ffffffffc0200b02:	00002517          	auipc	a0,0x2
ffffffffc0200b06:	e4650513          	addi	a0,a0,-442 # ffffffffc0202948 <commands+0x4a8>
ffffffffc0200b0a:	e04ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_M_SOFT: cprintf("Machine software interrupt\n"); break;
ffffffffc0200b0e:	00002517          	auipc	a0,0x2
ffffffffc0200b12:	e5a50513          	addi	a0,a0,-422 # ffffffffc0202968 <commands+0x4c8>
ffffffffc0200b16:	df8ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_U_TIMER: cprintf("User timer interrupt\n"); break;
ffffffffc0200b1a:	00002517          	auipc	a0,0x2
ffffffffc0200b1e:	e6e50513          	addi	a0,a0,-402 # ffffffffc0202988 <commands+0x4e8>
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
ffffffffc0200b50:	e5450513          	addi	a0,a0,-428 # ffffffffc02029a0 <commands+0x500>
ffffffffc0200b54:	dbaff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_M_TIMER: cprintf("Machine timer interrupt\n"); break;
ffffffffc0200b58:	00002517          	auipc	a0,0x2
ffffffffc0200b5c:	e6850513          	addi	a0,a0,-408 # ffffffffc02029c0 <commands+0x520>
ffffffffc0200b60:	daeff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_U_EXT: cprintf("User external interrupt\n"); break;
ffffffffc0200b64:	00002517          	auipc	a0,0x2
ffffffffc0200b68:	e7c50513          	addi	a0,a0,-388 # ffffffffc02029e0 <commands+0x540>
ffffffffc0200b6c:	da2ff06f          	j	ffffffffc020010e <cprintf>
        case IRQ_S_EXT: cprintf("Supervisor external interrupt\n"); break;
ffffffffc0200b70:	00002517          	auipc	a0,0x2
ffffffffc0200b74:	e9050513          	addi	a0,a0,-368 # ffffffffc0202a00 <commands+0x560>
ffffffffc0200b78:	d96ff06f          	j	ffffffffc020010e <cprintf>
            print_trapframe(tf);
ffffffffc0200b7c:	bdd1                	j	ffffffffc0200a50 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b7e:	06400593          	li	a1,100
ffffffffc0200b82:	00002517          	auipc	a0,0x2
ffffffffc0200b86:	d7650513          	addi	a0,a0,-650 # ffffffffc02028f8 <commands+0x458>
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
                    sbi_shutdown();
ffffffffc0200bac:	528010ef          	jal	ra,ffffffffc02020d4 <sbi_shutdown>
                    while (1); // 防止返回
ffffffffc0200bb0:	a001                	j	ffffffffc0200bb0 <interrupt_handler+0xfe>

ffffffffc0200bb2 <exception_handler>:

/* 异常处理 */
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200bb2:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200bb6:	1141                	addi	sp,sp,-16
ffffffffc0200bb8:	e022                	sd	s0,0(sp)
ffffffffc0200bba:	e406                	sd	ra,8(sp)
ffffffffc0200bbc:	472d                	li	a4,11
ffffffffc0200bbe:	842a                	mv	s0,a0
ffffffffc0200bc0:	1cf76863          	bltu	a4,a5,ffffffffc0200d90 <exception_handler+0x1de>
ffffffffc0200bc4:	00002717          	auipc	a4,0x2
ffffffffc0200bc8:	25c70713          	addi	a4,a4,604 # ffffffffc0202e20 <commands+0x980>
ffffffffc0200bcc:	078a                	slli	a5,a5,0x2
ffffffffc0200bce:	97ba                	add	a5,a5,a4
ffffffffc0200bd0:	439c                	lw	a5,0(a5)
            tf->epc += 4;
            break;

        case CAUSE_MACHINE_ECALL:
            // M 模式系统调用
            cprintf("Machine ECALL at 0x%08lx\n", tf->epc);
ffffffffc0200bd2:	10853583          	ld	a1,264(a0)
ffffffffc0200bd6:	97ba                	add	a5,a5,a4
ffffffffc0200bd8:	8782                	jr	a5
            cprintf("Hypervisor ECALL at 0x%08lx\n", tf->epc);
ffffffffc0200bda:	00002517          	auipc	a0,0x2
ffffffffc0200bde:	19e50513          	addi	a0,a0,414 # ffffffffc0202d78 <commands+0x8d8>
ffffffffc0200be2:	d2cff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Hypervisor ECALL\n");
ffffffffc0200be6:	00002517          	auipc	a0,0x2
ffffffffc0200bea:	1b250513          	addi	a0,a0,434 # ffffffffc0202d98 <commands+0x8f8>
ffffffffc0200bee:	d20ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200bf2:	10843783          	ld	a5,264(s0)
ffffffffc0200bf6:	0791                	addi	a5,a5,4
ffffffffc0200bf8:	10f43423          	sd	a5,264(s0)
            print_trapframe(tf);
            cprintf("Unknown exception type: %ld\n", tf->cause);
            tf->epc += 4;
            break;
    }
}
ffffffffc0200bfc:	60a2                	ld	ra,8(sp)
ffffffffc0200bfe:	6402                	ld	s0,0(sp)
ffffffffc0200c00:	0141                	addi	sp,sp,16
ffffffffc0200c02:	8082                	ret
            cprintf("Machine ECALL at 0x%08lx\n", tf->epc);
ffffffffc0200c04:	00002517          	auipc	a0,0x2
ffffffffc0200c08:	1bc50513          	addi	a0,a0,444 # ffffffffc0202dc0 <commands+0x920>
ffffffffc0200c0c:	d02ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Machine ECALL\n");
ffffffffc0200c10:	00002517          	auipc	a0,0x2
ffffffffc0200c14:	1d050513          	addi	a0,a0,464 # ffffffffc0202de0 <commands+0x940>
ffffffffc0200c18:	cf6ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200c1c:	10843783          	ld	a5,264(s0)
ffffffffc0200c20:	0791                	addi	a5,a5,4
ffffffffc0200c22:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200c26:	bfd9                	j	ffffffffc0200bfc <exception_handler+0x4a>
            cprintf("Misaligned instruction fetch at 0x%08lx\n", tf->epc);
ffffffffc0200c28:	00002517          	auipc	a0,0x2
ffffffffc0200c2c:	e6850513          	addi	a0,a0,-408 # ffffffffc0202a90 <commands+0x5f0>
ffffffffc0200c30:	cdeff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: misaligned instruction fetch\n");
ffffffffc0200c34:	00002517          	auipc	a0,0x2
ffffffffc0200c38:	e8c50513          	addi	a0,a0,-372 # ffffffffc0202ac0 <commands+0x620>
ffffffffc0200c3c:	cd2ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200c40:	10843783          	ld	a5,264(s0)
ffffffffc0200c44:	0791                	addi	a5,a5,4
ffffffffc0200c46:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200c4a:	bf4d                	j	ffffffffc0200bfc <exception_handler+0x4a>
            cprintf("Instruction access fault at 0x%08lx\n", tf->epc);
ffffffffc0200c4c:	00002517          	auipc	a0,0x2
ffffffffc0200c50:	ea450513          	addi	a0,a0,-348 # ffffffffc0202af0 <commands+0x650>
ffffffffc0200c54:	cbaff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Instruction access fault\n");
ffffffffc0200c58:	00002517          	auipc	a0,0x2
ffffffffc0200c5c:	ec050513          	addi	a0,a0,-320 # ffffffffc0202b18 <commands+0x678>
ffffffffc0200c60:	caeff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200c64:	10843783          	ld	a5,264(s0)
ffffffffc0200c68:	0791                	addi	a5,a5,4
ffffffffc0200c6a:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200c6e:	b779                	j	ffffffffc0200bfc <exception_handler+0x4a>
            cprintf("Illegal instruction caught at 0x%08lx\n", tf->epc);
ffffffffc0200c70:	00002517          	auipc	a0,0x2
ffffffffc0200c74:	ed850513          	addi	a0,a0,-296 # ffffffffc0202b48 <commands+0x6a8>
ffffffffc0200c78:	c96ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Illegal instruction\n");
ffffffffc0200c7c:	00002517          	auipc	a0,0x2
ffffffffc0200c80:	ef450513          	addi	a0,a0,-268 # ffffffffc0202b70 <commands+0x6d0>
ffffffffc0200c84:	c8aff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;  // 跳过非法指令，防止死循环
ffffffffc0200c88:	10843783          	ld	a5,264(s0)
ffffffffc0200c8c:	0791                	addi	a5,a5,4
ffffffffc0200c8e:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200c92:	b7ad                	j	ffffffffc0200bfc <exception_handler+0x4a>
            cprintf("ebreak caught at 0x%08lx\n", tf->epc);
ffffffffc0200c94:	00002517          	auipc	a0,0x2
ffffffffc0200c98:	f0450513          	addi	a0,a0,-252 # ffffffffc0202b98 <commands+0x6f8>
ffffffffc0200c9c:	c72ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: breakpoint\n");
ffffffffc0200ca0:	00002517          	auipc	a0,0x2
ffffffffc0200ca4:	f1850513          	addi	a0,a0,-232 # ffffffffc0202bb8 <commands+0x718>
ffffffffc0200ca8:	c66ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 2;  // 跳过断点指令
ffffffffc0200cac:	10843783          	ld	a5,264(s0)
ffffffffc0200cb0:	0789                	addi	a5,a5,2
ffffffffc0200cb2:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200cb6:	b799                	j	ffffffffc0200bfc <exception_handler+0x4a>
            cprintf("Misaligned load at 0x%08lx\n", tf->epc);
ffffffffc0200cb8:	00002517          	auipc	a0,0x2
ffffffffc0200cbc:	f2050513          	addi	a0,a0,-224 # ffffffffc0202bd8 <commands+0x738>
ffffffffc0200cc0:	c4eff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: misaligned load\n");
ffffffffc0200cc4:	00002517          	auipc	a0,0x2
ffffffffc0200cc8:	f3450513          	addi	a0,a0,-204 # ffffffffc0202bf8 <commands+0x758>
ffffffffc0200ccc:	c42ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200cd0:	10843783          	ld	a5,264(s0)
ffffffffc0200cd4:	0791                	addi	a5,a5,4
ffffffffc0200cd6:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200cda:	b70d                	j	ffffffffc0200bfc <exception_handler+0x4a>
            cprintf("Load access fault at 0x%08lx\n", tf->epc);
ffffffffc0200cdc:	00002517          	auipc	a0,0x2
ffffffffc0200ce0:	f4450513          	addi	a0,a0,-188 # ffffffffc0202c20 <commands+0x780>
ffffffffc0200ce4:	c2aff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Load access fault\n");
ffffffffc0200ce8:	00002517          	auipc	a0,0x2
ffffffffc0200cec:	f5850513          	addi	a0,a0,-168 # ffffffffc0202c40 <commands+0x7a0>
ffffffffc0200cf0:	c1eff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200cf4:	10843783          	ld	a5,264(s0)
ffffffffc0200cf8:	0791                	addi	a5,a5,4
ffffffffc0200cfa:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200cfe:	bdfd                	j	ffffffffc0200bfc <exception_handler+0x4a>
            cprintf("Misaligned store at 0x%08lx\n", tf->epc);
ffffffffc0200d00:	00002517          	auipc	a0,0x2
ffffffffc0200d04:	f6850513          	addi	a0,a0,-152 # ffffffffc0202c68 <commands+0x7c8>
ffffffffc0200d08:	c06ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: misaligned store\n");
ffffffffc0200d0c:	00002517          	auipc	a0,0x2
ffffffffc0200d10:	f7c50513          	addi	a0,a0,-132 # ffffffffc0202c88 <commands+0x7e8>
ffffffffc0200d14:	bfaff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200d18:	10843783          	ld	a5,264(s0)
ffffffffc0200d1c:	0791                	addi	a5,a5,4
ffffffffc0200d1e:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200d22:	bde9                	j	ffffffffc0200bfc <exception_handler+0x4a>
            cprintf("Store access fault at 0x%08lx\n", tf->epc);
ffffffffc0200d24:	00002517          	auipc	a0,0x2
ffffffffc0200d28:	f8c50513          	addi	a0,a0,-116 # ffffffffc0202cb0 <commands+0x810>
ffffffffc0200d2c:	be2ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Store access fault\n");
ffffffffc0200d30:	00002517          	auipc	a0,0x2
ffffffffc0200d34:	fa050513          	addi	a0,a0,-96 # ffffffffc0202cd0 <commands+0x830>
ffffffffc0200d38:	bd6ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200d3c:	10843783          	ld	a5,264(s0)
ffffffffc0200d40:	0791                	addi	a5,a5,4
ffffffffc0200d42:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200d46:	bd5d                	j	ffffffffc0200bfc <exception_handler+0x4a>
            cprintf("User ECALL at 0x%08lx\n", tf->epc);
ffffffffc0200d48:	00002517          	auipc	a0,0x2
ffffffffc0200d4c:	fb050513          	addi	a0,a0,-80 # ffffffffc0202cf8 <commands+0x858>
ffffffffc0200d50:	bbeff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: User ECALL\n");
ffffffffc0200d54:	00002517          	auipc	a0,0x2
ffffffffc0200d58:	fbc50513          	addi	a0,a0,-68 # ffffffffc0202d10 <commands+0x870>
ffffffffc0200d5c:	bb2ff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200d60:	10843783          	ld	a5,264(s0)
ffffffffc0200d64:	0791                	addi	a5,a5,4
ffffffffc0200d66:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200d6a:	bd49                	j	ffffffffc0200bfc <exception_handler+0x4a>
            cprintf("Supervisor ECALL at 0x%08lx\n", tf->epc);
ffffffffc0200d6c:	00002517          	auipc	a0,0x2
ffffffffc0200d70:	fc450513          	addi	a0,a0,-60 # ffffffffc0202d30 <commands+0x890>
ffffffffc0200d74:	b9aff0ef          	jal	ra,ffffffffc020010e <cprintf>
            cprintf("Exception type: Supervisor ECALL\n");
ffffffffc0200d78:	00002517          	auipc	a0,0x2
ffffffffc0200d7c:	fd850513          	addi	a0,a0,-40 # ffffffffc0202d50 <commands+0x8b0>
ffffffffc0200d80:	b8eff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200d84:	10843783          	ld	a5,264(s0)
ffffffffc0200d88:	0791                	addi	a5,a5,4
ffffffffc0200d8a:	10f43423          	sd	a5,264(s0)
            break;
ffffffffc0200d8e:	b5bd                	j	ffffffffc0200bfc <exception_handler+0x4a>
            print_trapframe(tf);
ffffffffc0200d90:	cc1ff0ef          	jal	ra,ffffffffc0200a50 <print_trapframe>
            cprintf("Unknown exception type: %ld\n", tf->cause);
ffffffffc0200d94:	11843583          	ld	a1,280(s0)
ffffffffc0200d98:	00002517          	auipc	a0,0x2
ffffffffc0200d9c:	06850513          	addi	a0,a0,104 # ffffffffc0202e00 <commands+0x960>
ffffffffc0200da0:	b6eff0ef          	jal	ra,ffffffffc020010e <cprintf>
            tf->epc += 4;
ffffffffc0200da4:	10843783          	ld	a5,264(s0)
ffffffffc0200da8:	0791                	addi	a5,a5,4
ffffffffc0200daa:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200dae:	b5b9                	j	ffffffffc0200bfc <exception_handler+0x4a>

ffffffffc0200db0 <trap>:


/* 分发 trap */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0)
ffffffffc0200db0:	11853783          	ld	a5,280(a0)
ffffffffc0200db4:	0007c363          	bltz	a5,ffffffffc0200dba <trap+0xa>
        interrupt_handler(tf);
    else
        exception_handler(tf);
ffffffffc0200db8:	bbed                	j	ffffffffc0200bb2 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200dba:	b9e5                	j	ffffffffc0200ab2 <interrupt_handler>

ffffffffc0200dbc <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200dbc:	14011073          	csrw	sscratch,sp
ffffffffc0200dc0:	712d                	addi	sp,sp,-288
ffffffffc0200dc2:	e002                	sd	zero,0(sp)
ffffffffc0200dc4:	e406                	sd	ra,8(sp)
ffffffffc0200dc6:	ec0e                	sd	gp,24(sp)
ffffffffc0200dc8:	f012                	sd	tp,32(sp)
ffffffffc0200dca:	f416                	sd	t0,40(sp)
ffffffffc0200dcc:	f81a                	sd	t1,48(sp)
ffffffffc0200dce:	fc1e                	sd	t2,56(sp)
ffffffffc0200dd0:	e0a2                	sd	s0,64(sp)
ffffffffc0200dd2:	e4a6                	sd	s1,72(sp)
ffffffffc0200dd4:	e8aa                	sd	a0,80(sp)
ffffffffc0200dd6:	ecae                	sd	a1,88(sp)
ffffffffc0200dd8:	f0b2                	sd	a2,96(sp)
ffffffffc0200dda:	f4b6                	sd	a3,104(sp)
ffffffffc0200ddc:	f8ba                	sd	a4,112(sp)
ffffffffc0200dde:	fcbe                	sd	a5,120(sp)
ffffffffc0200de0:	e142                	sd	a6,128(sp)
ffffffffc0200de2:	e546                	sd	a7,136(sp)
ffffffffc0200de4:	e94a                	sd	s2,144(sp)
ffffffffc0200de6:	ed4e                	sd	s3,152(sp)
ffffffffc0200de8:	f152                	sd	s4,160(sp)
ffffffffc0200dea:	f556                	sd	s5,168(sp)
ffffffffc0200dec:	f95a                	sd	s6,176(sp)
ffffffffc0200dee:	fd5e                	sd	s7,184(sp)
ffffffffc0200df0:	e1e2                	sd	s8,192(sp)
ffffffffc0200df2:	e5e6                	sd	s9,200(sp)
ffffffffc0200df4:	e9ea                	sd	s10,208(sp)
ffffffffc0200df6:	edee                	sd	s11,216(sp)
ffffffffc0200df8:	f1f2                	sd	t3,224(sp)
ffffffffc0200dfa:	f5f6                	sd	t4,232(sp)
ffffffffc0200dfc:	f9fa                	sd	t5,240(sp)
ffffffffc0200dfe:	fdfe                	sd	t6,248(sp)
ffffffffc0200e00:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e04:	100024f3          	csrr	s1,sstatus
ffffffffc0200e08:	14102973          	csrr	s2,sepc
ffffffffc0200e0c:	143029f3          	csrr	s3,stval
ffffffffc0200e10:	14202a73          	csrr	s4,scause
ffffffffc0200e14:	e822                	sd	s0,16(sp)
ffffffffc0200e16:	e226                	sd	s1,256(sp)
ffffffffc0200e18:	e64a                	sd	s2,264(sp)
ffffffffc0200e1a:	ea4e                	sd	s3,272(sp)
ffffffffc0200e1c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e1e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e20:	f91ff0ef          	jal	ra,ffffffffc0200db0 <trap>

ffffffffc0200e24 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e24:	6492                	ld	s1,256(sp)
ffffffffc0200e26:	6932                	ld	s2,264(sp)
ffffffffc0200e28:	10049073          	csrw	sstatus,s1
ffffffffc0200e2c:	14191073          	csrw	sepc,s2
ffffffffc0200e30:	60a2                	ld	ra,8(sp)
ffffffffc0200e32:	61e2                	ld	gp,24(sp)
ffffffffc0200e34:	7202                	ld	tp,32(sp)
ffffffffc0200e36:	72a2                	ld	t0,40(sp)
ffffffffc0200e38:	7342                	ld	t1,48(sp)
ffffffffc0200e3a:	73e2                	ld	t2,56(sp)
ffffffffc0200e3c:	6406                	ld	s0,64(sp)
ffffffffc0200e3e:	64a6                	ld	s1,72(sp)
ffffffffc0200e40:	6546                	ld	a0,80(sp)
ffffffffc0200e42:	65e6                	ld	a1,88(sp)
ffffffffc0200e44:	7606                	ld	a2,96(sp)
ffffffffc0200e46:	76a6                	ld	a3,104(sp)
ffffffffc0200e48:	7746                	ld	a4,112(sp)
ffffffffc0200e4a:	77e6                	ld	a5,120(sp)
ffffffffc0200e4c:	680a                	ld	a6,128(sp)
ffffffffc0200e4e:	68aa                	ld	a7,136(sp)
ffffffffc0200e50:	694a                	ld	s2,144(sp)
ffffffffc0200e52:	69ea                	ld	s3,152(sp)
ffffffffc0200e54:	7a0a                	ld	s4,160(sp)
ffffffffc0200e56:	7aaa                	ld	s5,168(sp)
ffffffffc0200e58:	7b4a                	ld	s6,176(sp)
ffffffffc0200e5a:	7bea                	ld	s7,184(sp)
ffffffffc0200e5c:	6c0e                	ld	s8,192(sp)
ffffffffc0200e5e:	6cae                	ld	s9,200(sp)
ffffffffc0200e60:	6d4e                	ld	s10,208(sp)
ffffffffc0200e62:	6dee                	ld	s11,216(sp)
ffffffffc0200e64:	7e0e                	ld	t3,224(sp)
ffffffffc0200e66:	7eae                	ld	t4,232(sp)
ffffffffc0200e68:	7f4e                	ld	t5,240(sp)
ffffffffc0200e6a:	7fee                	ld	t6,248(sp)
ffffffffc0200e6c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200e6e:	10200073          	sret

ffffffffc0200e72 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e72:	00006797          	auipc	a5,0x6
ffffffffc0200e76:	1b678793          	addi	a5,a5,438 # ffffffffc0207028 <free_area>
ffffffffc0200e7a:	e79c                	sd	a5,8(a5)
ffffffffc0200e7c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e7e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e82:	8082                	ret

ffffffffc0200e84 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200e84:	00006517          	auipc	a0,0x6
ffffffffc0200e88:	1b456503          	lwu	a0,436(a0) # ffffffffc0207038 <free_area+0x10>
ffffffffc0200e8c:	8082                	ret

ffffffffc0200e8e <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e8e:	715d                	addi	sp,sp,-80
ffffffffc0200e90:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e92:	00006417          	auipc	s0,0x6
ffffffffc0200e96:	19640413          	addi	s0,s0,406 # ffffffffc0207028 <free_area>
ffffffffc0200e9a:	641c                	ld	a5,8(s0)
ffffffffc0200e9c:	e486                	sd	ra,72(sp)
ffffffffc0200e9e:	fc26                	sd	s1,56(sp)
ffffffffc0200ea0:	f84a                	sd	s2,48(sp)
ffffffffc0200ea2:	f44e                	sd	s3,40(sp)
ffffffffc0200ea4:	f052                	sd	s4,32(sp)
ffffffffc0200ea6:	ec56                	sd	s5,24(sp)
ffffffffc0200ea8:	e85a                	sd	s6,16(sp)
ffffffffc0200eaa:	e45e                	sd	s7,8(sp)
ffffffffc0200eac:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eae:	2c878763          	beq	a5,s0,ffffffffc020117c <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200eb2:	4481                	li	s1,0
ffffffffc0200eb4:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200eb6:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200eba:	8b09                	andi	a4,a4,2
ffffffffc0200ebc:	2c070463          	beqz	a4,ffffffffc0201184 <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200ec0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ec4:	679c                	ld	a5,8(a5)
ffffffffc0200ec6:	2905                	addiw	s2,s2,1
ffffffffc0200ec8:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eca:	fe8796e3          	bne	a5,s0,ffffffffc0200eb6 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200ece:	89a6                	mv	s3,s1
ffffffffc0200ed0:	2f9000ef          	jal	ra,ffffffffc02019c8 <nr_free_pages>
ffffffffc0200ed4:	71351863          	bne	a0,s3,ffffffffc02015e4 <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ed8:	4505                	li	a0,1
ffffffffc0200eda:	271000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0200ede:	8a2a                	mv	s4,a0
ffffffffc0200ee0:	44050263          	beqz	a0,ffffffffc0201324 <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ee4:	4505                	li	a0,1
ffffffffc0200ee6:	265000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0200eea:	89aa                	mv	s3,a0
ffffffffc0200eec:	70050c63          	beqz	a0,ffffffffc0201604 <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ef0:	4505                	li	a0,1
ffffffffc0200ef2:	259000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0200ef6:	8aaa                	mv	s5,a0
ffffffffc0200ef8:	4a050663          	beqz	a0,ffffffffc02013a4 <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200efc:	2b3a0463          	beq	s4,s3,ffffffffc02011a4 <default_check+0x316>
ffffffffc0200f00:	2aaa0263          	beq	s4,a0,ffffffffc02011a4 <default_check+0x316>
ffffffffc0200f04:	2aa98063          	beq	s3,a0,ffffffffc02011a4 <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f08:	000a2783          	lw	a5,0(s4)
ffffffffc0200f0c:	2a079c63          	bnez	a5,ffffffffc02011c4 <default_check+0x336>
ffffffffc0200f10:	0009a783          	lw	a5,0(s3)
ffffffffc0200f14:	2a079863          	bnez	a5,ffffffffc02011c4 <default_check+0x336>
ffffffffc0200f18:	411c                	lw	a5,0(a0)
ffffffffc0200f1a:	2a079563          	bnez	a5,ffffffffc02011c4 <default_check+0x336>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f1e:	00006797          	auipc	a5,0x6
ffffffffc0200f22:	5527b783          	ld	a5,1362(a5) # ffffffffc0207470 <pages>
ffffffffc0200f26:	40fa0733          	sub	a4,s4,a5
ffffffffc0200f2a:	870d                	srai	a4,a4,0x3
ffffffffc0200f2c:	00002597          	auipc	a1,0x2
ffffffffc0200f30:	6ac5b583          	ld	a1,1708(a1) # ffffffffc02035d8 <error_string+0x38>
ffffffffc0200f34:	02b70733          	mul	a4,a4,a1
ffffffffc0200f38:	00002617          	auipc	a2,0x2
ffffffffc0200f3c:	6a863603          	ld	a2,1704(a2) # ffffffffc02035e0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f40:	00006697          	auipc	a3,0x6
ffffffffc0200f44:	5286b683          	ld	a3,1320(a3) # ffffffffc0207468 <npage>
ffffffffc0200f48:	06b2                	slli	a3,a3,0xc
ffffffffc0200f4a:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f4c:	0732                	slli	a4,a4,0xc
ffffffffc0200f4e:	28d77b63          	bgeu	a4,a3,ffffffffc02011e4 <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f52:	40f98733          	sub	a4,s3,a5
ffffffffc0200f56:	870d                	srai	a4,a4,0x3
ffffffffc0200f58:	02b70733          	mul	a4,a4,a1
ffffffffc0200f5c:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f5e:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f60:	4cd77263          	bgeu	a4,a3,ffffffffc0201424 <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200f64:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f68:	878d                	srai	a5,a5,0x3
ffffffffc0200f6a:	02b787b3          	mul	a5,a5,a1
ffffffffc0200f6e:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f70:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f72:	30d7f963          	bgeu	a5,a3,ffffffffc0201284 <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200f76:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f78:	00043c03          	ld	s8,0(s0)
ffffffffc0200f7c:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f80:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200f84:	e400                	sd	s0,8(s0)
ffffffffc0200f86:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200f88:	00006797          	auipc	a5,0x6
ffffffffc0200f8c:	0a07a823          	sw	zero,176(a5) # ffffffffc0207038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f90:	1bb000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0200f94:	2c051863          	bnez	a0,ffffffffc0201264 <default_check+0x3d6>
    free_page(p0);
ffffffffc0200f98:	4585                	li	a1,1
ffffffffc0200f9a:	8552                	mv	a0,s4
ffffffffc0200f9c:	1ed000ef          	jal	ra,ffffffffc0201988 <free_pages>
    free_page(p1);
ffffffffc0200fa0:	4585                	li	a1,1
ffffffffc0200fa2:	854e                	mv	a0,s3
ffffffffc0200fa4:	1e5000ef          	jal	ra,ffffffffc0201988 <free_pages>
    free_page(p2);
ffffffffc0200fa8:	4585                	li	a1,1
ffffffffc0200faa:	8556                	mv	a0,s5
ffffffffc0200fac:	1dd000ef          	jal	ra,ffffffffc0201988 <free_pages>
    assert(nr_free == 3);
ffffffffc0200fb0:	4818                	lw	a4,16(s0)
ffffffffc0200fb2:	478d                	li	a5,3
ffffffffc0200fb4:	28f71863          	bne	a4,a5,ffffffffc0201244 <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fb8:	4505                	li	a0,1
ffffffffc0200fba:	191000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0200fbe:	89aa                	mv	s3,a0
ffffffffc0200fc0:	26050263          	beqz	a0,ffffffffc0201224 <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fc4:	4505                	li	a0,1
ffffffffc0200fc6:	185000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0200fca:	8aaa                	mv	s5,a0
ffffffffc0200fcc:	3a050c63          	beqz	a0,ffffffffc0201384 <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fd0:	4505                	li	a0,1
ffffffffc0200fd2:	179000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0200fd6:	8a2a                	mv	s4,a0
ffffffffc0200fd8:	38050663          	beqz	a0,ffffffffc0201364 <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0200fdc:	4505                	li	a0,1
ffffffffc0200fde:	16d000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0200fe2:	36051163          	bnez	a0,ffffffffc0201344 <default_check+0x4b6>
    free_page(p0);
ffffffffc0200fe6:	4585                	li	a1,1
ffffffffc0200fe8:	854e                	mv	a0,s3
ffffffffc0200fea:	19f000ef          	jal	ra,ffffffffc0201988 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200fee:	641c                	ld	a5,8(s0)
ffffffffc0200ff0:	20878a63          	beq	a5,s0,ffffffffc0201204 <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0200ff4:	4505                	li	a0,1
ffffffffc0200ff6:	155000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0200ffa:	30a99563          	bne	s3,a0,ffffffffc0201304 <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0200ffe:	4505                	li	a0,1
ffffffffc0201000:	14b000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0201004:	2e051063          	bnez	a0,ffffffffc02012e4 <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0201008:	481c                	lw	a5,16(s0)
ffffffffc020100a:	2a079d63          	bnez	a5,ffffffffc02012c4 <default_check+0x436>
    free_page(p);
ffffffffc020100e:	854e                	mv	a0,s3
ffffffffc0201010:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201012:	01843023          	sd	s8,0(s0)
ffffffffc0201016:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020101a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020101e:	16b000ef          	jal	ra,ffffffffc0201988 <free_pages>
    free_page(p1);
ffffffffc0201022:	4585                	li	a1,1
ffffffffc0201024:	8556                	mv	a0,s5
ffffffffc0201026:	163000ef          	jal	ra,ffffffffc0201988 <free_pages>
    free_page(p2);
ffffffffc020102a:	4585                	li	a1,1
ffffffffc020102c:	8552                	mv	a0,s4
ffffffffc020102e:	15b000ef          	jal	ra,ffffffffc0201988 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201032:	4515                	li	a0,5
ffffffffc0201034:	117000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0201038:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020103a:	26050563          	beqz	a0,ffffffffc02012a4 <default_check+0x416>
ffffffffc020103e:	651c                	ld	a5,8(a0)
ffffffffc0201040:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0201042:	8b85                	andi	a5,a5,1
ffffffffc0201044:	54079063          	bnez	a5,ffffffffc0201584 <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201048:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020104a:	00043b03          	ld	s6,0(s0)
ffffffffc020104e:	00843a83          	ld	s5,8(s0)
ffffffffc0201052:	e000                	sd	s0,0(s0)
ffffffffc0201054:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0201056:	0f5000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc020105a:	50051563          	bnez	a0,ffffffffc0201564 <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020105e:	05098a13          	addi	s4,s3,80
ffffffffc0201062:	8552                	mv	a0,s4
ffffffffc0201064:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201066:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc020106a:	00006797          	auipc	a5,0x6
ffffffffc020106e:	fc07a723          	sw	zero,-50(a5) # ffffffffc0207038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201072:	117000ef          	jal	ra,ffffffffc0201988 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201076:	4511                	li	a0,4
ffffffffc0201078:	0d3000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc020107c:	4c051463          	bnez	a0,ffffffffc0201544 <default_check+0x6b6>
ffffffffc0201080:	0589b783          	ld	a5,88(s3)
ffffffffc0201084:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201086:	8b85                	andi	a5,a5,1
ffffffffc0201088:	48078e63          	beqz	a5,ffffffffc0201524 <default_check+0x696>
ffffffffc020108c:	0609a703          	lw	a4,96(s3)
ffffffffc0201090:	478d                	li	a5,3
ffffffffc0201092:	48f71963          	bne	a4,a5,ffffffffc0201524 <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201096:	450d                	li	a0,3
ffffffffc0201098:	0b3000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc020109c:	8c2a                	mv	s8,a0
ffffffffc020109e:	46050363          	beqz	a0,ffffffffc0201504 <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc02010a2:	4505                	li	a0,1
ffffffffc02010a4:	0a7000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc02010a8:	42051e63          	bnez	a0,ffffffffc02014e4 <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc02010ac:	418a1c63          	bne	s4,s8,ffffffffc02014c4 <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010b0:	4585                	li	a1,1
ffffffffc02010b2:	854e                	mv	a0,s3
ffffffffc02010b4:	0d5000ef          	jal	ra,ffffffffc0201988 <free_pages>
    free_pages(p1, 3);
ffffffffc02010b8:	458d                	li	a1,3
ffffffffc02010ba:	8552                	mv	a0,s4
ffffffffc02010bc:	0cd000ef          	jal	ra,ffffffffc0201988 <free_pages>
ffffffffc02010c0:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02010c4:	02898c13          	addi	s8,s3,40
ffffffffc02010c8:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010ca:	8b85                	andi	a5,a5,1
ffffffffc02010cc:	3c078c63          	beqz	a5,ffffffffc02014a4 <default_check+0x616>
ffffffffc02010d0:	0109a703          	lw	a4,16(s3)
ffffffffc02010d4:	4785                	li	a5,1
ffffffffc02010d6:	3cf71763          	bne	a4,a5,ffffffffc02014a4 <default_check+0x616>
ffffffffc02010da:	008a3783          	ld	a5,8(s4)
ffffffffc02010de:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02010e0:	8b85                	andi	a5,a5,1
ffffffffc02010e2:	3a078163          	beqz	a5,ffffffffc0201484 <default_check+0x5f6>
ffffffffc02010e6:	010a2703          	lw	a4,16(s4)
ffffffffc02010ea:	478d                	li	a5,3
ffffffffc02010ec:	38f71c63          	bne	a4,a5,ffffffffc0201484 <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02010f0:	4505                	li	a0,1
ffffffffc02010f2:	059000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc02010f6:	36a99763          	bne	s3,a0,ffffffffc0201464 <default_check+0x5d6>
    free_page(p0);
ffffffffc02010fa:	4585                	li	a1,1
ffffffffc02010fc:	08d000ef          	jal	ra,ffffffffc0201988 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201100:	4509                	li	a0,2
ffffffffc0201102:	049000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc0201106:	32aa1f63          	bne	s4,a0,ffffffffc0201444 <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc020110a:	4589                	li	a1,2
ffffffffc020110c:	07d000ef          	jal	ra,ffffffffc0201988 <free_pages>
    free_page(p2);
ffffffffc0201110:	4585                	li	a1,1
ffffffffc0201112:	8562                	mv	a0,s8
ffffffffc0201114:	075000ef          	jal	ra,ffffffffc0201988 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201118:	4515                	li	a0,5
ffffffffc020111a:	031000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc020111e:	89aa                	mv	s3,a0
ffffffffc0201120:	48050263          	beqz	a0,ffffffffc02015a4 <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0201124:	4505                	li	a0,1
ffffffffc0201126:	025000ef          	jal	ra,ffffffffc020194a <alloc_pages>
ffffffffc020112a:	2c051d63          	bnez	a0,ffffffffc0201404 <default_check+0x576>

    assert(nr_free == 0);
ffffffffc020112e:	481c                	lw	a5,16(s0)
ffffffffc0201130:	2a079a63          	bnez	a5,ffffffffc02013e4 <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201134:	4595                	li	a1,5
ffffffffc0201136:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201138:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc020113c:	01643023          	sd	s6,0(s0)
ffffffffc0201140:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201144:	045000ef          	jal	ra,ffffffffc0201988 <free_pages>
    return listelm->next;
ffffffffc0201148:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020114a:	00878963          	beq	a5,s0,ffffffffc020115c <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020114e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201152:	679c                	ld	a5,8(a5)
ffffffffc0201154:	397d                	addiw	s2,s2,-1
ffffffffc0201156:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201158:	fe879be3          	bne	a5,s0,ffffffffc020114e <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc020115c:	26091463          	bnez	s2,ffffffffc02013c4 <default_check+0x536>
    assert(total == 0);
ffffffffc0201160:	46049263          	bnez	s1,ffffffffc02015c4 <default_check+0x736>
}
ffffffffc0201164:	60a6                	ld	ra,72(sp)
ffffffffc0201166:	6406                	ld	s0,64(sp)
ffffffffc0201168:	74e2                	ld	s1,56(sp)
ffffffffc020116a:	7942                	ld	s2,48(sp)
ffffffffc020116c:	79a2                	ld	s3,40(sp)
ffffffffc020116e:	7a02                	ld	s4,32(sp)
ffffffffc0201170:	6ae2                	ld	s5,24(sp)
ffffffffc0201172:	6b42                	ld	s6,16(sp)
ffffffffc0201174:	6ba2                	ld	s7,8(sp)
ffffffffc0201176:	6c02                	ld	s8,0(sp)
ffffffffc0201178:	6161                	addi	sp,sp,80
ffffffffc020117a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020117c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020117e:	4481                	li	s1,0
ffffffffc0201180:	4901                	li	s2,0
ffffffffc0201182:	b3b9                	j	ffffffffc0200ed0 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201184:	00002697          	auipc	a3,0x2
ffffffffc0201188:	ccc68693          	addi	a3,a3,-820 # ffffffffc0202e50 <commands+0x9b0>
ffffffffc020118c:	00002617          	auipc	a2,0x2
ffffffffc0201190:	cd460613          	addi	a2,a2,-812 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201194:	0f000593          	li	a1,240
ffffffffc0201198:	00002517          	auipc	a0,0x2
ffffffffc020119c:	ce050513          	addi	a0,a0,-800 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02011a0:	a68ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011a4:	00002697          	auipc	a3,0x2
ffffffffc02011a8:	d6c68693          	addi	a3,a3,-660 # ffffffffc0202f10 <commands+0xa70>
ffffffffc02011ac:	00002617          	auipc	a2,0x2
ffffffffc02011b0:	cb460613          	addi	a2,a2,-844 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02011b4:	0bd00593          	li	a1,189
ffffffffc02011b8:	00002517          	auipc	a0,0x2
ffffffffc02011bc:	cc050513          	addi	a0,a0,-832 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02011c0:	a48ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011c4:	00002697          	auipc	a3,0x2
ffffffffc02011c8:	d7468693          	addi	a3,a3,-652 # ffffffffc0202f38 <commands+0xa98>
ffffffffc02011cc:	00002617          	auipc	a2,0x2
ffffffffc02011d0:	c9460613          	addi	a2,a2,-876 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02011d4:	0be00593          	li	a1,190
ffffffffc02011d8:	00002517          	auipc	a0,0x2
ffffffffc02011dc:	ca050513          	addi	a0,a0,-864 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02011e0:	a28ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02011e4:	00002697          	auipc	a3,0x2
ffffffffc02011e8:	d9468693          	addi	a3,a3,-620 # ffffffffc0202f78 <commands+0xad8>
ffffffffc02011ec:	00002617          	auipc	a2,0x2
ffffffffc02011f0:	c7460613          	addi	a2,a2,-908 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02011f4:	0c000593          	li	a1,192
ffffffffc02011f8:	00002517          	auipc	a0,0x2
ffffffffc02011fc:	c8050513          	addi	a0,a0,-896 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201200:	a08ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201204:	00002697          	auipc	a3,0x2
ffffffffc0201208:	dfc68693          	addi	a3,a3,-516 # ffffffffc0203000 <commands+0xb60>
ffffffffc020120c:	00002617          	auipc	a2,0x2
ffffffffc0201210:	c5460613          	addi	a2,a2,-940 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201214:	0d900593          	li	a1,217
ffffffffc0201218:	00002517          	auipc	a0,0x2
ffffffffc020121c:	c6050513          	addi	a0,a0,-928 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201220:	9e8ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201224:	00002697          	auipc	a3,0x2
ffffffffc0201228:	c8c68693          	addi	a3,a3,-884 # ffffffffc0202eb0 <commands+0xa10>
ffffffffc020122c:	00002617          	auipc	a2,0x2
ffffffffc0201230:	c3460613          	addi	a2,a2,-972 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201234:	0d200593          	li	a1,210
ffffffffc0201238:	00002517          	auipc	a0,0x2
ffffffffc020123c:	c4050513          	addi	a0,a0,-960 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201240:	9c8ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(nr_free == 3);
ffffffffc0201244:	00002697          	auipc	a3,0x2
ffffffffc0201248:	dac68693          	addi	a3,a3,-596 # ffffffffc0202ff0 <commands+0xb50>
ffffffffc020124c:	00002617          	auipc	a2,0x2
ffffffffc0201250:	c1460613          	addi	a2,a2,-1004 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201254:	0d000593          	li	a1,208
ffffffffc0201258:	00002517          	auipc	a0,0x2
ffffffffc020125c:	c2050513          	addi	a0,a0,-992 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201260:	9a8ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201264:	00002697          	auipc	a3,0x2
ffffffffc0201268:	d7468693          	addi	a3,a3,-652 # ffffffffc0202fd8 <commands+0xb38>
ffffffffc020126c:	00002617          	auipc	a2,0x2
ffffffffc0201270:	bf460613          	addi	a2,a2,-1036 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201274:	0cb00593          	li	a1,203
ffffffffc0201278:	00002517          	auipc	a0,0x2
ffffffffc020127c:	c0050513          	addi	a0,a0,-1024 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201280:	988ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201284:	00002697          	auipc	a3,0x2
ffffffffc0201288:	d3468693          	addi	a3,a3,-716 # ffffffffc0202fb8 <commands+0xb18>
ffffffffc020128c:	00002617          	auipc	a2,0x2
ffffffffc0201290:	bd460613          	addi	a2,a2,-1068 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201294:	0c200593          	li	a1,194
ffffffffc0201298:	00002517          	auipc	a0,0x2
ffffffffc020129c:	be050513          	addi	a0,a0,-1056 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02012a0:	968ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(p0 != NULL);
ffffffffc02012a4:	00002697          	auipc	a3,0x2
ffffffffc02012a8:	da468693          	addi	a3,a3,-604 # ffffffffc0203048 <commands+0xba8>
ffffffffc02012ac:	00002617          	auipc	a2,0x2
ffffffffc02012b0:	bb460613          	addi	a2,a2,-1100 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02012b4:	0f800593          	li	a1,248
ffffffffc02012b8:	00002517          	auipc	a0,0x2
ffffffffc02012bc:	bc050513          	addi	a0,a0,-1088 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02012c0:	948ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(nr_free == 0);
ffffffffc02012c4:	00002697          	auipc	a3,0x2
ffffffffc02012c8:	d7468693          	addi	a3,a3,-652 # ffffffffc0203038 <commands+0xb98>
ffffffffc02012cc:	00002617          	auipc	a2,0x2
ffffffffc02012d0:	b9460613          	addi	a2,a2,-1132 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02012d4:	0df00593          	li	a1,223
ffffffffc02012d8:	00002517          	auipc	a0,0x2
ffffffffc02012dc:	ba050513          	addi	a0,a0,-1120 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02012e0:	928ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012e4:	00002697          	auipc	a3,0x2
ffffffffc02012e8:	cf468693          	addi	a3,a3,-780 # ffffffffc0202fd8 <commands+0xb38>
ffffffffc02012ec:	00002617          	auipc	a2,0x2
ffffffffc02012f0:	b7460613          	addi	a2,a2,-1164 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02012f4:	0dd00593          	li	a1,221
ffffffffc02012f8:	00002517          	auipc	a0,0x2
ffffffffc02012fc:	b8050513          	addi	a0,a0,-1152 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201300:	908ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201304:	00002697          	auipc	a3,0x2
ffffffffc0201308:	d1468693          	addi	a3,a3,-748 # ffffffffc0203018 <commands+0xb78>
ffffffffc020130c:	00002617          	auipc	a2,0x2
ffffffffc0201310:	b5460613          	addi	a2,a2,-1196 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201314:	0dc00593          	li	a1,220
ffffffffc0201318:	00002517          	auipc	a0,0x2
ffffffffc020131c:	b6050513          	addi	a0,a0,-1184 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201320:	8e8ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201324:	00002697          	auipc	a3,0x2
ffffffffc0201328:	b8c68693          	addi	a3,a3,-1140 # ffffffffc0202eb0 <commands+0xa10>
ffffffffc020132c:	00002617          	auipc	a2,0x2
ffffffffc0201330:	b3460613          	addi	a2,a2,-1228 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201334:	0b900593          	li	a1,185
ffffffffc0201338:	00002517          	auipc	a0,0x2
ffffffffc020133c:	b4050513          	addi	a0,a0,-1216 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201340:	8c8ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201344:	00002697          	auipc	a3,0x2
ffffffffc0201348:	c9468693          	addi	a3,a3,-876 # ffffffffc0202fd8 <commands+0xb38>
ffffffffc020134c:	00002617          	auipc	a2,0x2
ffffffffc0201350:	b1460613          	addi	a2,a2,-1260 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201354:	0d600593          	li	a1,214
ffffffffc0201358:	00002517          	auipc	a0,0x2
ffffffffc020135c:	b2050513          	addi	a0,a0,-1248 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201360:	8a8ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201364:	00002697          	auipc	a3,0x2
ffffffffc0201368:	b8c68693          	addi	a3,a3,-1140 # ffffffffc0202ef0 <commands+0xa50>
ffffffffc020136c:	00002617          	auipc	a2,0x2
ffffffffc0201370:	af460613          	addi	a2,a2,-1292 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201374:	0d400593          	li	a1,212
ffffffffc0201378:	00002517          	auipc	a0,0x2
ffffffffc020137c:	b0050513          	addi	a0,a0,-1280 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201380:	888ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201384:	00002697          	auipc	a3,0x2
ffffffffc0201388:	b4c68693          	addi	a3,a3,-1204 # ffffffffc0202ed0 <commands+0xa30>
ffffffffc020138c:	00002617          	auipc	a2,0x2
ffffffffc0201390:	ad460613          	addi	a2,a2,-1324 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201394:	0d300593          	li	a1,211
ffffffffc0201398:	00002517          	auipc	a0,0x2
ffffffffc020139c:	ae050513          	addi	a0,a0,-1312 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02013a0:	868ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013a4:	00002697          	auipc	a3,0x2
ffffffffc02013a8:	b4c68693          	addi	a3,a3,-1204 # ffffffffc0202ef0 <commands+0xa50>
ffffffffc02013ac:	00002617          	auipc	a2,0x2
ffffffffc02013b0:	ab460613          	addi	a2,a2,-1356 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02013b4:	0bb00593          	li	a1,187
ffffffffc02013b8:	00002517          	auipc	a0,0x2
ffffffffc02013bc:	ac050513          	addi	a0,a0,-1344 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02013c0:	848ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(count == 0);
ffffffffc02013c4:	00002697          	auipc	a3,0x2
ffffffffc02013c8:	dd468693          	addi	a3,a3,-556 # ffffffffc0203198 <commands+0xcf8>
ffffffffc02013cc:	00002617          	auipc	a2,0x2
ffffffffc02013d0:	a9460613          	addi	a2,a2,-1388 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02013d4:	12500593          	li	a1,293
ffffffffc02013d8:	00002517          	auipc	a0,0x2
ffffffffc02013dc:	aa050513          	addi	a0,a0,-1376 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02013e0:	828ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(nr_free == 0);
ffffffffc02013e4:	00002697          	auipc	a3,0x2
ffffffffc02013e8:	c5468693          	addi	a3,a3,-940 # ffffffffc0203038 <commands+0xb98>
ffffffffc02013ec:	00002617          	auipc	a2,0x2
ffffffffc02013f0:	a7460613          	addi	a2,a2,-1420 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02013f4:	11a00593          	li	a1,282
ffffffffc02013f8:	00002517          	auipc	a0,0x2
ffffffffc02013fc:	a8050513          	addi	a0,a0,-1408 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201400:	808ff0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201404:	00002697          	auipc	a3,0x2
ffffffffc0201408:	bd468693          	addi	a3,a3,-1068 # ffffffffc0202fd8 <commands+0xb38>
ffffffffc020140c:	00002617          	auipc	a2,0x2
ffffffffc0201410:	a5460613          	addi	a2,a2,-1452 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201414:	11800593          	li	a1,280
ffffffffc0201418:	00002517          	auipc	a0,0x2
ffffffffc020141c:	a6050513          	addi	a0,a0,-1440 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201420:	fe9fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201424:	00002697          	auipc	a3,0x2
ffffffffc0201428:	b7468693          	addi	a3,a3,-1164 # ffffffffc0202f98 <commands+0xaf8>
ffffffffc020142c:	00002617          	auipc	a2,0x2
ffffffffc0201430:	a3460613          	addi	a2,a2,-1484 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201434:	0c100593          	li	a1,193
ffffffffc0201438:	00002517          	auipc	a0,0x2
ffffffffc020143c:	a4050513          	addi	a0,a0,-1472 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201440:	fc9fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201444:	00002697          	auipc	a3,0x2
ffffffffc0201448:	d1468693          	addi	a3,a3,-748 # ffffffffc0203158 <commands+0xcb8>
ffffffffc020144c:	00002617          	auipc	a2,0x2
ffffffffc0201450:	a1460613          	addi	a2,a2,-1516 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201454:	11200593          	li	a1,274
ffffffffc0201458:	00002517          	auipc	a0,0x2
ffffffffc020145c:	a2050513          	addi	a0,a0,-1504 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201460:	fa9fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201464:	00002697          	auipc	a3,0x2
ffffffffc0201468:	cd468693          	addi	a3,a3,-812 # ffffffffc0203138 <commands+0xc98>
ffffffffc020146c:	00002617          	auipc	a2,0x2
ffffffffc0201470:	9f460613          	addi	a2,a2,-1548 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201474:	11000593          	li	a1,272
ffffffffc0201478:	00002517          	auipc	a0,0x2
ffffffffc020147c:	a0050513          	addi	a0,a0,-1536 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201480:	f89fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201484:	00002697          	auipc	a3,0x2
ffffffffc0201488:	c8c68693          	addi	a3,a3,-884 # ffffffffc0203110 <commands+0xc70>
ffffffffc020148c:	00002617          	auipc	a2,0x2
ffffffffc0201490:	9d460613          	addi	a2,a2,-1580 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201494:	10e00593          	li	a1,270
ffffffffc0201498:	00002517          	auipc	a0,0x2
ffffffffc020149c:	9e050513          	addi	a0,a0,-1568 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02014a0:	f69fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014a4:	00002697          	auipc	a3,0x2
ffffffffc02014a8:	c4468693          	addi	a3,a3,-956 # ffffffffc02030e8 <commands+0xc48>
ffffffffc02014ac:	00002617          	auipc	a2,0x2
ffffffffc02014b0:	9b460613          	addi	a2,a2,-1612 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02014b4:	10d00593          	li	a1,269
ffffffffc02014b8:	00002517          	auipc	a0,0x2
ffffffffc02014bc:	9c050513          	addi	a0,a0,-1600 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02014c0:	f49fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014c4:	00002697          	auipc	a3,0x2
ffffffffc02014c8:	c1468693          	addi	a3,a3,-1004 # ffffffffc02030d8 <commands+0xc38>
ffffffffc02014cc:	00002617          	auipc	a2,0x2
ffffffffc02014d0:	99460613          	addi	a2,a2,-1644 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02014d4:	10800593          	li	a1,264
ffffffffc02014d8:	00002517          	auipc	a0,0x2
ffffffffc02014dc:	9a050513          	addi	a0,a0,-1632 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02014e0:	f29fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014e4:	00002697          	auipc	a3,0x2
ffffffffc02014e8:	af468693          	addi	a3,a3,-1292 # ffffffffc0202fd8 <commands+0xb38>
ffffffffc02014ec:	00002617          	auipc	a2,0x2
ffffffffc02014f0:	97460613          	addi	a2,a2,-1676 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02014f4:	10700593          	li	a1,263
ffffffffc02014f8:	00002517          	auipc	a0,0x2
ffffffffc02014fc:	98050513          	addi	a0,a0,-1664 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201500:	f09fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201504:	00002697          	auipc	a3,0x2
ffffffffc0201508:	bb468693          	addi	a3,a3,-1100 # ffffffffc02030b8 <commands+0xc18>
ffffffffc020150c:	00002617          	auipc	a2,0x2
ffffffffc0201510:	95460613          	addi	a2,a2,-1708 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201514:	10600593          	li	a1,262
ffffffffc0201518:	00002517          	auipc	a0,0x2
ffffffffc020151c:	96050513          	addi	a0,a0,-1696 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201520:	ee9fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201524:	00002697          	auipc	a3,0x2
ffffffffc0201528:	b6468693          	addi	a3,a3,-1180 # ffffffffc0203088 <commands+0xbe8>
ffffffffc020152c:	00002617          	auipc	a2,0x2
ffffffffc0201530:	93460613          	addi	a2,a2,-1740 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201534:	10500593          	li	a1,261
ffffffffc0201538:	00002517          	auipc	a0,0x2
ffffffffc020153c:	94050513          	addi	a0,a0,-1728 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201540:	ec9fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201544:	00002697          	auipc	a3,0x2
ffffffffc0201548:	b2c68693          	addi	a3,a3,-1236 # ffffffffc0203070 <commands+0xbd0>
ffffffffc020154c:	00002617          	auipc	a2,0x2
ffffffffc0201550:	91460613          	addi	a2,a2,-1772 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201554:	10400593          	li	a1,260
ffffffffc0201558:	00002517          	auipc	a0,0x2
ffffffffc020155c:	92050513          	addi	a0,a0,-1760 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201560:	ea9fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201564:	00002697          	auipc	a3,0x2
ffffffffc0201568:	a7468693          	addi	a3,a3,-1420 # ffffffffc0202fd8 <commands+0xb38>
ffffffffc020156c:	00002617          	auipc	a2,0x2
ffffffffc0201570:	8f460613          	addi	a2,a2,-1804 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201574:	0fe00593          	li	a1,254
ffffffffc0201578:	00002517          	auipc	a0,0x2
ffffffffc020157c:	90050513          	addi	a0,a0,-1792 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201580:	e89fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201584:	00002697          	auipc	a3,0x2
ffffffffc0201588:	ad468693          	addi	a3,a3,-1324 # ffffffffc0203058 <commands+0xbb8>
ffffffffc020158c:	00002617          	auipc	a2,0x2
ffffffffc0201590:	8d460613          	addi	a2,a2,-1836 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201594:	0f900593          	li	a1,249
ffffffffc0201598:	00002517          	auipc	a0,0x2
ffffffffc020159c:	8e050513          	addi	a0,a0,-1824 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02015a0:	e69fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015a4:	00002697          	auipc	a3,0x2
ffffffffc02015a8:	bd468693          	addi	a3,a3,-1068 # ffffffffc0203178 <commands+0xcd8>
ffffffffc02015ac:	00002617          	auipc	a2,0x2
ffffffffc02015b0:	8b460613          	addi	a2,a2,-1868 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02015b4:	11700593          	li	a1,279
ffffffffc02015b8:	00002517          	auipc	a0,0x2
ffffffffc02015bc:	8c050513          	addi	a0,a0,-1856 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02015c0:	e49fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(total == 0);
ffffffffc02015c4:	00002697          	auipc	a3,0x2
ffffffffc02015c8:	be468693          	addi	a3,a3,-1052 # ffffffffc02031a8 <commands+0xd08>
ffffffffc02015cc:	00002617          	auipc	a2,0x2
ffffffffc02015d0:	89460613          	addi	a2,a2,-1900 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02015d4:	12600593          	li	a1,294
ffffffffc02015d8:	00002517          	auipc	a0,0x2
ffffffffc02015dc:	8a050513          	addi	a0,a0,-1888 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc02015e0:	e29fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(total == nr_free_pages());
ffffffffc02015e4:	00002697          	auipc	a3,0x2
ffffffffc02015e8:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0202e90 <commands+0x9f0>
ffffffffc02015ec:	00002617          	auipc	a2,0x2
ffffffffc02015f0:	87460613          	addi	a2,a2,-1932 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc02015f4:	0f300593          	li	a1,243
ffffffffc02015f8:	00002517          	auipc	a0,0x2
ffffffffc02015fc:	88050513          	addi	a0,a0,-1920 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201600:	e09fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201604:	00002697          	auipc	a3,0x2
ffffffffc0201608:	8cc68693          	addi	a3,a3,-1844 # ffffffffc0202ed0 <commands+0xa30>
ffffffffc020160c:	00002617          	auipc	a2,0x2
ffffffffc0201610:	85460613          	addi	a2,a2,-1964 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201614:	0ba00593          	li	a1,186
ffffffffc0201618:	00002517          	auipc	a0,0x2
ffffffffc020161c:	86050513          	addi	a0,a0,-1952 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201620:	de9fe0ef          	jal	ra,ffffffffc0200408 <__panic>

ffffffffc0201624 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201624:	1141                	addi	sp,sp,-16
ffffffffc0201626:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201628:	14058a63          	beqz	a1,ffffffffc020177c <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020162c:	00259693          	slli	a3,a1,0x2
ffffffffc0201630:	96ae                	add	a3,a3,a1
ffffffffc0201632:	068e                	slli	a3,a3,0x3
ffffffffc0201634:	96aa                	add	a3,a3,a0
ffffffffc0201636:	87aa                	mv	a5,a0
ffffffffc0201638:	02d50263          	beq	a0,a3,ffffffffc020165c <default_free_pages+0x38>
ffffffffc020163c:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020163e:	8b05                	andi	a4,a4,1
ffffffffc0201640:	10071e63          	bnez	a4,ffffffffc020175c <default_free_pages+0x138>
ffffffffc0201644:	6798                	ld	a4,8(a5)
ffffffffc0201646:	8b09                	andi	a4,a4,2
ffffffffc0201648:	10071a63          	bnez	a4,ffffffffc020175c <default_free_pages+0x138>
        p->flags = 0;
ffffffffc020164c:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201650:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201654:	02878793          	addi	a5,a5,40
ffffffffc0201658:	fed792e3          	bne	a5,a3,ffffffffc020163c <default_free_pages+0x18>
    base->property = n;
ffffffffc020165c:	2581                	sext.w	a1,a1
ffffffffc020165e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201660:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201664:	4789                	li	a5,2
ffffffffc0201666:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020166a:	00006697          	auipc	a3,0x6
ffffffffc020166e:	9be68693          	addi	a3,a3,-1602 # ffffffffc0207028 <free_area>
ffffffffc0201672:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201674:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201676:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020167a:	9db9                	addw	a1,a1,a4
ffffffffc020167c:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020167e:	0ad78863          	beq	a5,a3,ffffffffc020172e <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201682:	fe878713          	addi	a4,a5,-24
ffffffffc0201686:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020168a:	4581                	li	a1,0
            if (base < page) {
ffffffffc020168c:	00e56a63          	bltu	a0,a4,ffffffffc02016a0 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc0201690:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201692:	06d70263          	beq	a4,a3,ffffffffc02016f6 <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201696:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201698:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020169c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201690 <default_free_pages+0x6c>
ffffffffc02016a0:	c199                	beqz	a1,ffffffffc02016a6 <default_free_pages+0x82>
ffffffffc02016a2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016a6:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016a8:	e390                	sd	a2,0(a5)
ffffffffc02016aa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02016ac:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016ae:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02016b0:	02d70063          	beq	a4,a3,ffffffffc02016d0 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc02016b4:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02016b8:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc02016bc:	02081613          	slli	a2,a6,0x20
ffffffffc02016c0:	9201                	srli	a2,a2,0x20
ffffffffc02016c2:	00261793          	slli	a5,a2,0x2
ffffffffc02016c6:	97b2                	add	a5,a5,a2
ffffffffc02016c8:	078e                	slli	a5,a5,0x3
ffffffffc02016ca:	97ae                	add	a5,a5,a1
ffffffffc02016cc:	02f50f63          	beq	a0,a5,ffffffffc020170a <default_free_pages+0xe6>
    return listelm->next;
ffffffffc02016d0:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02016d2:	00d70f63          	beq	a4,a3,ffffffffc02016f0 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02016d6:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02016d8:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02016dc:	02059613          	slli	a2,a1,0x20
ffffffffc02016e0:	9201                	srli	a2,a2,0x20
ffffffffc02016e2:	00261793          	slli	a5,a2,0x2
ffffffffc02016e6:	97b2                	add	a5,a5,a2
ffffffffc02016e8:	078e                	slli	a5,a5,0x3
ffffffffc02016ea:	97aa                	add	a5,a5,a0
ffffffffc02016ec:	04f68863          	beq	a3,a5,ffffffffc020173c <default_free_pages+0x118>
}
ffffffffc02016f0:	60a2                	ld	ra,8(sp)
ffffffffc02016f2:	0141                	addi	sp,sp,16
ffffffffc02016f4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02016f6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02016f8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02016fa:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02016fc:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016fe:	02d70563          	beq	a4,a3,ffffffffc0201728 <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0201702:	8832                	mv	a6,a2
ffffffffc0201704:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201706:	87ba                	mv	a5,a4
ffffffffc0201708:	bf41                	j	ffffffffc0201698 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc020170a:	491c                	lw	a5,16(a0)
ffffffffc020170c:	0107883b          	addw	a6,a5,a6
ffffffffc0201710:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201714:	57f5                	li	a5,-3
ffffffffc0201716:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020171a:	6d10                	ld	a2,24(a0)
ffffffffc020171c:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc020171e:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201720:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201722:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201724:	e390                	sd	a2,0(a5)
ffffffffc0201726:	b775                	j	ffffffffc02016d2 <default_free_pages+0xae>
ffffffffc0201728:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020172a:	873e                	mv	a4,a5
ffffffffc020172c:	b761                	j	ffffffffc02016b4 <default_free_pages+0x90>
}
ffffffffc020172e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201730:	e390                	sd	a2,0(a5)
ffffffffc0201732:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201734:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201736:	ed1c                	sd	a5,24(a0)
ffffffffc0201738:	0141                	addi	sp,sp,16
ffffffffc020173a:	8082                	ret
            base->property += p->property;
ffffffffc020173c:	ff872783          	lw	a5,-8(a4)
ffffffffc0201740:	ff070693          	addi	a3,a4,-16
ffffffffc0201744:	9dbd                	addw	a1,a1,a5
ffffffffc0201746:	c90c                	sw	a1,16(a0)
ffffffffc0201748:	57f5                	li	a5,-3
ffffffffc020174a:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020174e:	6314                	ld	a3,0(a4)
ffffffffc0201750:	671c                	ld	a5,8(a4)
}
ffffffffc0201752:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201754:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201756:	e394                	sd	a3,0(a5)
ffffffffc0201758:	0141                	addi	sp,sp,16
ffffffffc020175a:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020175c:	00002697          	auipc	a3,0x2
ffffffffc0201760:	a6468693          	addi	a3,a3,-1436 # ffffffffc02031c0 <commands+0xd20>
ffffffffc0201764:	00001617          	auipc	a2,0x1
ffffffffc0201768:	6fc60613          	addi	a2,a2,1788 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc020176c:	08300593          	li	a1,131
ffffffffc0201770:	00001517          	auipc	a0,0x1
ffffffffc0201774:	70850513          	addi	a0,a0,1800 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201778:	c91fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(n > 0);
ffffffffc020177c:	00002697          	auipc	a3,0x2
ffffffffc0201780:	a3c68693          	addi	a3,a3,-1476 # ffffffffc02031b8 <commands+0xd18>
ffffffffc0201784:	00001617          	auipc	a2,0x1
ffffffffc0201788:	6dc60613          	addi	a2,a2,1756 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc020178c:	08000593          	li	a1,128
ffffffffc0201790:	00001517          	auipc	a0,0x1
ffffffffc0201794:	6e850513          	addi	a0,a0,1768 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201798:	c71fe0ef          	jal	ra,ffffffffc0200408 <__panic>

ffffffffc020179c <default_alloc_pages>:
    assert(n > 0);
ffffffffc020179c:	c959                	beqz	a0,ffffffffc0201832 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc020179e:	00006597          	auipc	a1,0x6
ffffffffc02017a2:	88a58593          	addi	a1,a1,-1910 # ffffffffc0207028 <free_area>
ffffffffc02017a6:	0105a803          	lw	a6,16(a1)
ffffffffc02017aa:	862a                	mv	a2,a0
ffffffffc02017ac:	02081793          	slli	a5,a6,0x20
ffffffffc02017b0:	9381                	srli	a5,a5,0x20
ffffffffc02017b2:	00a7ee63          	bltu	a5,a0,ffffffffc02017ce <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02017b6:	87ae                	mv	a5,a1
ffffffffc02017b8:	a801                	j	ffffffffc02017c8 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc02017ba:	ff87a703          	lw	a4,-8(a5)
ffffffffc02017be:	02071693          	slli	a3,a4,0x20
ffffffffc02017c2:	9281                	srli	a3,a3,0x20
ffffffffc02017c4:	00c6f763          	bgeu	a3,a2,ffffffffc02017d2 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02017c8:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02017ca:	feb798e3          	bne	a5,a1,ffffffffc02017ba <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02017ce:	4501                	li	a0,0
}
ffffffffc02017d0:	8082                	ret
    return listelm->prev;
ffffffffc02017d2:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017d6:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02017da:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02017de:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc02017e2:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02017e6:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02017ea:	02d67b63          	bgeu	a2,a3,ffffffffc0201820 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc02017ee:	00261693          	slli	a3,a2,0x2
ffffffffc02017f2:	96b2                	add	a3,a3,a2
ffffffffc02017f4:	068e                	slli	a3,a3,0x3
ffffffffc02017f6:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc02017f8:	41c7073b          	subw	a4,a4,t3
ffffffffc02017fc:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017fe:	00868613          	addi	a2,a3,8
ffffffffc0201802:	4709                	li	a4,2
ffffffffc0201804:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201808:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020180c:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc0201810:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201814:	e310                	sd	a2,0(a4)
ffffffffc0201816:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc020181a:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc020181c:	0116bc23          	sd	a7,24(a3)
ffffffffc0201820:	41c8083b          	subw	a6,a6,t3
ffffffffc0201824:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201828:	5775                	li	a4,-3
ffffffffc020182a:	17c1                	addi	a5,a5,-16
ffffffffc020182c:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0201830:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0201832:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201834:	00002697          	auipc	a3,0x2
ffffffffc0201838:	98468693          	addi	a3,a3,-1660 # ffffffffc02031b8 <commands+0xd18>
ffffffffc020183c:	00001617          	auipc	a2,0x1
ffffffffc0201840:	62460613          	addi	a2,a2,1572 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc0201844:	06200593          	li	a1,98
ffffffffc0201848:	00001517          	auipc	a0,0x1
ffffffffc020184c:	63050513          	addi	a0,a0,1584 # ffffffffc0202e78 <commands+0x9d8>
default_alloc_pages(size_t n) {
ffffffffc0201850:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201852:	bb7fe0ef          	jal	ra,ffffffffc0200408 <__panic>

ffffffffc0201856 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201856:	1141                	addi	sp,sp,-16
ffffffffc0201858:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020185a:	c9e1                	beqz	a1,ffffffffc020192a <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc020185c:	00259693          	slli	a3,a1,0x2
ffffffffc0201860:	96ae                	add	a3,a3,a1
ffffffffc0201862:	068e                	slli	a3,a3,0x3
ffffffffc0201864:	96aa                	add	a3,a3,a0
ffffffffc0201866:	87aa                	mv	a5,a0
ffffffffc0201868:	00d50f63          	beq	a0,a3,ffffffffc0201886 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020186c:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020186e:	8b05                	andi	a4,a4,1
ffffffffc0201870:	cf49                	beqz	a4,ffffffffc020190a <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201872:	0007a823          	sw	zero,16(a5)
ffffffffc0201876:	0007b423          	sd	zero,8(a5)
ffffffffc020187a:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020187e:	02878793          	addi	a5,a5,40
ffffffffc0201882:	fed795e3          	bne	a5,a3,ffffffffc020186c <default_init_memmap+0x16>
    base->property = n;
ffffffffc0201886:	2581                	sext.w	a1,a1
ffffffffc0201888:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020188a:	4789                	li	a5,2
ffffffffc020188c:	00850713          	addi	a4,a0,8
ffffffffc0201890:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201894:	00005697          	auipc	a3,0x5
ffffffffc0201898:	79468693          	addi	a3,a3,1940 # ffffffffc0207028 <free_area>
ffffffffc020189c:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020189e:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02018a0:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02018a4:	9db9                	addw	a1,a1,a4
ffffffffc02018a6:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02018a8:	04d78a63          	beq	a5,a3,ffffffffc02018fc <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc02018ac:	fe878713          	addi	a4,a5,-24
ffffffffc02018b0:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02018b4:	4581                	li	a1,0
            if (base < page) {
ffffffffc02018b6:	00e56a63          	bltu	a0,a4,ffffffffc02018ca <default_init_memmap+0x74>
    return listelm->next;
ffffffffc02018ba:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02018bc:	02d70263          	beq	a4,a3,ffffffffc02018e0 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc02018c0:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02018c2:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02018c6:	fee57ae3          	bgeu	a0,a4,ffffffffc02018ba <default_init_memmap+0x64>
ffffffffc02018ca:	c199                	beqz	a1,ffffffffc02018d0 <default_init_memmap+0x7a>
ffffffffc02018cc:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02018d0:	6398                	ld	a4,0(a5)
}
ffffffffc02018d2:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02018d4:	e390                	sd	a2,0(a5)
ffffffffc02018d6:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02018d8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018da:	ed18                	sd	a4,24(a0)
ffffffffc02018dc:	0141                	addi	sp,sp,16
ffffffffc02018de:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02018e0:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02018e2:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02018e4:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02018e6:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02018e8:	00d70663          	beq	a4,a3,ffffffffc02018f4 <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc02018ec:	8832                	mv	a6,a2
ffffffffc02018ee:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02018f0:	87ba                	mv	a5,a4
ffffffffc02018f2:	bfc1                	j	ffffffffc02018c2 <default_init_memmap+0x6c>
}
ffffffffc02018f4:	60a2                	ld	ra,8(sp)
ffffffffc02018f6:	e290                	sd	a2,0(a3)
ffffffffc02018f8:	0141                	addi	sp,sp,16
ffffffffc02018fa:	8082                	ret
ffffffffc02018fc:	60a2                	ld	ra,8(sp)
ffffffffc02018fe:	e390                	sd	a2,0(a5)
ffffffffc0201900:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201902:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201904:	ed1c                	sd	a5,24(a0)
ffffffffc0201906:	0141                	addi	sp,sp,16
ffffffffc0201908:	8082                	ret
        assert(PageReserved(p));
ffffffffc020190a:	00002697          	auipc	a3,0x2
ffffffffc020190e:	8de68693          	addi	a3,a3,-1826 # ffffffffc02031e8 <commands+0xd48>
ffffffffc0201912:	00001617          	auipc	a2,0x1
ffffffffc0201916:	54e60613          	addi	a2,a2,1358 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc020191a:	04900593          	li	a1,73
ffffffffc020191e:	00001517          	auipc	a0,0x1
ffffffffc0201922:	55a50513          	addi	a0,a0,1370 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201926:	ae3fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    assert(n > 0);
ffffffffc020192a:	00002697          	auipc	a3,0x2
ffffffffc020192e:	88e68693          	addi	a3,a3,-1906 # ffffffffc02031b8 <commands+0xd18>
ffffffffc0201932:	00001617          	auipc	a2,0x1
ffffffffc0201936:	52e60613          	addi	a2,a2,1326 # ffffffffc0202e60 <commands+0x9c0>
ffffffffc020193a:	04600593          	li	a1,70
ffffffffc020193e:	00001517          	auipc	a0,0x1
ffffffffc0201942:	53a50513          	addi	a0,a0,1338 # ffffffffc0202e78 <commands+0x9d8>
ffffffffc0201946:	ac3fe0ef          	jal	ra,ffffffffc0200408 <__panic>

ffffffffc020194a <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020194a:	100027f3          	csrr	a5,sstatus
ffffffffc020194e:	8b89                	andi	a5,a5,2
ffffffffc0201950:	e799                	bnez	a5,ffffffffc020195e <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201952:	00006797          	auipc	a5,0x6
ffffffffc0201956:	b267b783          	ld	a5,-1242(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc020195a:	6f9c                	ld	a5,24(a5)
ffffffffc020195c:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc020195e:	1141                	addi	sp,sp,-16
ffffffffc0201960:	e406                	sd	ra,8(sp)
ffffffffc0201962:	e022                	sd	s0,0(sp)
ffffffffc0201964:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201966:	f05fe0ef          	jal	ra,ffffffffc020086a <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020196a:	00006797          	auipc	a5,0x6
ffffffffc020196e:	b0e7b783          	ld	a5,-1266(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201972:	6f9c                	ld	a5,24(a5)
ffffffffc0201974:	8522                	mv	a0,s0
ffffffffc0201976:	9782                	jalr	a5
ffffffffc0201978:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc020197a:	eebfe0ef          	jal	ra,ffffffffc0200864 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020197e:	60a2                	ld	ra,8(sp)
ffffffffc0201980:	8522                	mv	a0,s0
ffffffffc0201982:	6402                	ld	s0,0(sp)
ffffffffc0201984:	0141                	addi	sp,sp,16
ffffffffc0201986:	8082                	ret

ffffffffc0201988 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201988:	100027f3          	csrr	a5,sstatus
ffffffffc020198c:	8b89                	andi	a5,a5,2
ffffffffc020198e:	e799                	bnez	a5,ffffffffc020199c <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201990:	00006797          	auipc	a5,0x6
ffffffffc0201994:	ae87b783          	ld	a5,-1304(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc0201998:	739c                	ld	a5,32(a5)
ffffffffc020199a:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020199c:	1101                	addi	sp,sp,-32
ffffffffc020199e:	ec06                	sd	ra,24(sp)
ffffffffc02019a0:	e822                	sd	s0,16(sp)
ffffffffc02019a2:	e426                	sd	s1,8(sp)
ffffffffc02019a4:	842a                	mv	s0,a0
ffffffffc02019a6:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02019a8:	ec3fe0ef          	jal	ra,ffffffffc020086a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02019ac:	00006797          	auipc	a5,0x6
ffffffffc02019b0:	acc7b783          	ld	a5,-1332(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02019b4:	739c                	ld	a5,32(a5)
ffffffffc02019b6:	85a6                	mv	a1,s1
ffffffffc02019b8:	8522                	mv	a0,s0
ffffffffc02019ba:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02019bc:	6442                	ld	s0,16(sp)
ffffffffc02019be:	60e2                	ld	ra,24(sp)
ffffffffc02019c0:	64a2                	ld	s1,8(sp)
ffffffffc02019c2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02019c4:	ea1fe06f          	j	ffffffffc0200864 <intr_enable>

ffffffffc02019c8 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019c8:	100027f3          	csrr	a5,sstatus
ffffffffc02019cc:	8b89                	andi	a5,a5,2
ffffffffc02019ce:	e799                	bnez	a5,ffffffffc02019dc <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02019d0:	00006797          	auipc	a5,0x6
ffffffffc02019d4:	aa87b783          	ld	a5,-1368(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02019d8:	779c                	ld	a5,40(a5)
ffffffffc02019da:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02019dc:	1141                	addi	sp,sp,-16
ffffffffc02019de:	e406                	sd	ra,8(sp)
ffffffffc02019e0:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02019e2:	e89fe0ef          	jal	ra,ffffffffc020086a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02019e6:	00006797          	auipc	a5,0x6
ffffffffc02019ea:	a927b783          	ld	a5,-1390(a5) # ffffffffc0207478 <pmm_manager>
ffffffffc02019ee:	779c                	ld	a5,40(a5)
ffffffffc02019f0:	9782                	jalr	a5
ffffffffc02019f2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02019f4:	e71fe0ef          	jal	ra,ffffffffc0200864 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02019f8:	60a2                	ld	ra,8(sp)
ffffffffc02019fa:	8522                	mv	a0,s0
ffffffffc02019fc:	6402                	ld	s0,0(sp)
ffffffffc02019fe:	0141                	addi	sp,sp,16
ffffffffc0201a00:	8082                	ret

ffffffffc0201a02 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201a02:	00002797          	auipc	a5,0x2
ffffffffc0201a06:	80e78793          	addi	a5,a5,-2034 # ffffffffc0203210 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201a0a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201a0c:	7179                	addi	sp,sp,-48
ffffffffc0201a0e:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201a10:	00002517          	auipc	a0,0x2
ffffffffc0201a14:	83850513          	addi	a0,a0,-1992 # ffffffffc0203248 <default_pmm_manager+0x38>
    pmm_manager = &default_pmm_manager;
ffffffffc0201a18:	00006417          	auipc	s0,0x6
ffffffffc0201a1c:	a6040413          	addi	s0,s0,-1440 # ffffffffc0207478 <pmm_manager>
void pmm_init(void) {
ffffffffc0201a20:	f406                	sd	ra,40(sp)
ffffffffc0201a22:	ec26                	sd	s1,24(sp)
ffffffffc0201a24:	e44e                	sd	s3,8(sp)
ffffffffc0201a26:	e84a                	sd	s2,16(sp)
ffffffffc0201a28:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201a2a:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201a2c:	ee2fe0ef          	jal	ra,ffffffffc020010e <cprintf>
    pmm_manager->init();
ffffffffc0201a30:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201a32:	00006497          	auipc	s1,0x6
ffffffffc0201a36:	a5e48493          	addi	s1,s1,-1442 # ffffffffc0207490 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201a3a:	679c                	ld	a5,8(a5)
ffffffffc0201a3c:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201a3e:	57f5                	li	a5,-3
ffffffffc0201a40:	07fa                	slli	a5,a5,0x1e
ffffffffc0201a42:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201a44:	e0dfe0ef          	jal	ra,ffffffffc0200850 <get_memory_base>
ffffffffc0201a48:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201a4a:	e11fe0ef          	jal	ra,ffffffffc020085a <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201a4e:	16050163          	beqz	a0,ffffffffc0201bb0 <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201a52:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201a54:	00002517          	auipc	a0,0x2
ffffffffc0201a58:	83c50513          	addi	a0,a0,-1988 # ffffffffc0203290 <default_pmm_manager+0x80>
ffffffffc0201a5c:	eb2fe0ef          	jal	ra,ffffffffc020010e <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201a60:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201a64:	864e                	mv	a2,s3
ffffffffc0201a66:	fffa0693          	addi	a3,s4,-1
ffffffffc0201a6a:	85ca                	mv	a1,s2
ffffffffc0201a6c:	00002517          	auipc	a0,0x2
ffffffffc0201a70:	83c50513          	addi	a0,a0,-1988 # ffffffffc02032a8 <default_pmm_manager+0x98>
ffffffffc0201a74:	e9afe0ef          	jal	ra,ffffffffc020010e <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201a78:	c80007b7          	lui	a5,0xc8000
ffffffffc0201a7c:	8652                	mv	a2,s4
ffffffffc0201a7e:	0d47e863          	bltu	a5,s4,ffffffffc0201b4e <pmm_init+0x14c>
ffffffffc0201a82:	00007797          	auipc	a5,0x7
ffffffffc0201a86:	a1d78793          	addi	a5,a5,-1507 # ffffffffc020849f <end+0xfff>
ffffffffc0201a8a:	757d                	lui	a0,0xfffff
ffffffffc0201a8c:	8d7d                	and	a0,a0,a5
ffffffffc0201a8e:	8231                	srli	a2,a2,0xc
ffffffffc0201a90:	00006597          	auipc	a1,0x6
ffffffffc0201a94:	9d858593          	addi	a1,a1,-1576 # ffffffffc0207468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201a98:	00006817          	auipc	a6,0x6
ffffffffc0201a9c:	9d880813          	addi	a6,a6,-1576 # ffffffffc0207470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0201aa0:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201aa2:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201aa6:	000807b7          	lui	a5,0x80
ffffffffc0201aaa:	02f60663          	beq	a2,a5,ffffffffc0201ad6 <pmm_init+0xd4>
ffffffffc0201aae:	4701                	li	a4,0
ffffffffc0201ab0:	4781                	li	a5,0
ffffffffc0201ab2:	4305                	li	t1,1
ffffffffc0201ab4:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc0201ab8:	953a                	add	a0,a0,a4
ffffffffc0201aba:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf7b68>
ffffffffc0201abe:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201ac2:	6190                	ld	a2,0(a1)
ffffffffc0201ac4:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc0201ac6:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201aca:	011606b3          	add	a3,a2,a7
ffffffffc0201ace:	02870713          	addi	a4,a4,40
ffffffffc0201ad2:	fed7e3e3          	bltu	a5,a3,ffffffffc0201ab8 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201ad6:	00261693          	slli	a3,a2,0x2
ffffffffc0201ada:	96b2                	add	a3,a3,a2
ffffffffc0201adc:	fec007b7          	lui	a5,0xfec00
ffffffffc0201ae0:	97aa                	add	a5,a5,a0
ffffffffc0201ae2:	068e                	slli	a3,a3,0x3
ffffffffc0201ae4:	96be                	add	a3,a3,a5
ffffffffc0201ae6:	c02007b7          	lui	a5,0xc0200
ffffffffc0201aea:	0af6e763          	bltu	a3,a5,ffffffffc0201b98 <pmm_init+0x196>
ffffffffc0201aee:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201af0:	77fd                	lui	a5,0xfffff
ffffffffc0201af2:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201af6:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201af8:	04b6ee63          	bltu	a3,a1,ffffffffc0201b54 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201afc:	601c                	ld	a5,0(s0)
ffffffffc0201afe:	7b9c                	ld	a5,48(a5)
ffffffffc0201b00:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201b02:	00002517          	auipc	a0,0x2
ffffffffc0201b06:	82e50513          	addi	a0,a0,-2002 # ffffffffc0203330 <default_pmm_manager+0x120>
ffffffffc0201b0a:	e04fe0ef          	jal	ra,ffffffffc020010e <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201b0e:	00004597          	auipc	a1,0x4
ffffffffc0201b12:	4f258593          	addi	a1,a1,1266 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0201b16:	00006797          	auipc	a5,0x6
ffffffffc0201b1a:	96b7b923          	sd	a1,-1678(a5) # ffffffffc0207488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201b1e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201b22:	0af5e363          	bltu	a1,a5,ffffffffc0201bc8 <pmm_init+0x1c6>
ffffffffc0201b26:	6090                	ld	a2,0(s1)
}
ffffffffc0201b28:	7402                	ld	s0,32(sp)
ffffffffc0201b2a:	70a2                	ld	ra,40(sp)
ffffffffc0201b2c:	64e2                	ld	s1,24(sp)
ffffffffc0201b2e:	6942                	ld	s2,16(sp)
ffffffffc0201b30:	69a2                	ld	s3,8(sp)
ffffffffc0201b32:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201b34:	40c58633          	sub	a2,a1,a2
ffffffffc0201b38:	00006797          	auipc	a5,0x6
ffffffffc0201b3c:	94c7b423          	sd	a2,-1720(a5) # ffffffffc0207480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201b40:	00002517          	auipc	a0,0x2
ffffffffc0201b44:	81050513          	addi	a0,a0,-2032 # ffffffffc0203350 <default_pmm_manager+0x140>
}
ffffffffc0201b48:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201b4a:	dc4fe06f          	j	ffffffffc020010e <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201b4e:	c8000637          	lui	a2,0xc8000
ffffffffc0201b52:	bf05                	j	ffffffffc0201a82 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201b54:	6705                	lui	a4,0x1
ffffffffc0201b56:	177d                	addi	a4,a4,-1
ffffffffc0201b58:	96ba                	add	a3,a3,a4
ffffffffc0201b5a:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201b5c:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201b60:	02c7f063          	bgeu	a5,a2,ffffffffc0201b80 <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc0201b64:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201b66:	fff80737          	lui	a4,0xfff80
ffffffffc0201b6a:	973e                	add	a4,a4,a5
ffffffffc0201b6c:	00271793          	slli	a5,a4,0x2
ffffffffc0201b70:	97ba                	add	a5,a5,a4
ffffffffc0201b72:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201b74:	8d95                	sub	a1,a1,a3
ffffffffc0201b76:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201b78:	81b1                	srli	a1,a1,0xc
ffffffffc0201b7a:	953e                	add	a0,a0,a5
ffffffffc0201b7c:	9702                	jalr	a4
}
ffffffffc0201b7e:	bfbd                	j	ffffffffc0201afc <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc0201b80:	00001617          	auipc	a2,0x1
ffffffffc0201b84:	78060613          	addi	a2,a2,1920 # ffffffffc0203300 <default_pmm_manager+0xf0>
ffffffffc0201b88:	06b00593          	li	a1,107
ffffffffc0201b8c:	00001517          	auipc	a0,0x1
ffffffffc0201b90:	79450513          	addi	a0,a0,1940 # ffffffffc0203320 <default_pmm_manager+0x110>
ffffffffc0201b94:	875fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201b98:	00001617          	auipc	a2,0x1
ffffffffc0201b9c:	74060613          	addi	a2,a2,1856 # ffffffffc02032d8 <default_pmm_manager+0xc8>
ffffffffc0201ba0:	07100593          	li	a1,113
ffffffffc0201ba4:	00001517          	auipc	a0,0x1
ffffffffc0201ba8:	6dc50513          	addi	a0,a0,1756 # ffffffffc0203280 <default_pmm_manager+0x70>
ffffffffc0201bac:	85dfe0ef          	jal	ra,ffffffffc0200408 <__panic>
        panic("DTB memory info not available");
ffffffffc0201bb0:	00001617          	auipc	a2,0x1
ffffffffc0201bb4:	6b060613          	addi	a2,a2,1712 # ffffffffc0203260 <default_pmm_manager+0x50>
ffffffffc0201bb8:	05a00593          	li	a1,90
ffffffffc0201bbc:	00001517          	auipc	a0,0x1
ffffffffc0201bc0:	6c450513          	addi	a0,a0,1732 # ffffffffc0203280 <default_pmm_manager+0x70>
ffffffffc0201bc4:	845fe0ef          	jal	ra,ffffffffc0200408 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201bc8:	86ae                	mv	a3,a1
ffffffffc0201bca:	00001617          	auipc	a2,0x1
ffffffffc0201bce:	70e60613          	addi	a2,a2,1806 # ffffffffc02032d8 <default_pmm_manager+0xc8>
ffffffffc0201bd2:	08c00593          	li	a1,140
ffffffffc0201bd6:	00001517          	auipc	a0,0x1
ffffffffc0201bda:	6aa50513          	addi	a0,a0,1706 # ffffffffc0203280 <default_pmm_manager+0x70>
ffffffffc0201bde:	82bfe0ef          	jal	ra,ffffffffc0200408 <__panic>

ffffffffc0201be2 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201be2:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201be6:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201be8:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201bec:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201bee:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201bf2:	f022                	sd	s0,32(sp)
ffffffffc0201bf4:	ec26                	sd	s1,24(sp)
ffffffffc0201bf6:	e84a                	sd	s2,16(sp)
ffffffffc0201bf8:	f406                	sd	ra,40(sp)
ffffffffc0201bfa:	e44e                	sd	s3,8(sp)
ffffffffc0201bfc:	84aa                	mv	s1,a0
ffffffffc0201bfe:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201c00:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201c04:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201c06:	03067e63          	bgeu	a2,a6,ffffffffc0201c42 <printnum+0x60>
ffffffffc0201c0a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201c0c:	00805763          	blez	s0,ffffffffc0201c1a <printnum+0x38>
ffffffffc0201c10:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201c12:	85ca                	mv	a1,s2
ffffffffc0201c14:	854e                	mv	a0,s3
ffffffffc0201c16:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201c18:	fc65                	bnez	s0,ffffffffc0201c10 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201c1a:	1a02                	slli	s4,s4,0x20
ffffffffc0201c1c:	00001797          	auipc	a5,0x1
ffffffffc0201c20:	77478793          	addi	a5,a5,1908 # ffffffffc0203390 <default_pmm_manager+0x180>
ffffffffc0201c24:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201c28:	9a3e                	add	s4,s4,a5
}
ffffffffc0201c2a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201c2c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201c30:	70a2                	ld	ra,40(sp)
ffffffffc0201c32:	69a2                	ld	s3,8(sp)
ffffffffc0201c34:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201c36:	85ca                	mv	a1,s2
ffffffffc0201c38:	87a6                	mv	a5,s1
}
ffffffffc0201c3a:	6942                	ld	s2,16(sp)
ffffffffc0201c3c:	64e2                	ld	s1,24(sp)
ffffffffc0201c3e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201c40:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201c42:	03065633          	divu	a2,a2,a6
ffffffffc0201c46:	8722                	mv	a4,s0
ffffffffc0201c48:	f9bff0ef          	jal	ra,ffffffffc0201be2 <printnum>
ffffffffc0201c4c:	b7f9                	j	ffffffffc0201c1a <printnum+0x38>

ffffffffc0201c4e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201c4e:	7119                	addi	sp,sp,-128
ffffffffc0201c50:	f4a6                	sd	s1,104(sp)
ffffffffc0201c52:	f0ca                	sd	s2,96(sp)
ffffffffc0201c54:	ecce                	sd	s3,88(sp)
ffffffffc0201c56:	e8d2                	sd	s4,80(sp)
ffffffffc0201c58:	e4d6                	sd	s5,72(sp)
ffffffffc0201c5a:	e0da                	sd	s6,64(sp)
ffffffffc0201c5c:	fc5e                	sd	s7,56(sp)
ffffffffc0201c5e:	f06a                	sd	s10,32(sp)
ffffffffc0201c60:	fc86                	sd	ra,120(sp)
ffffffffc0201c62:	f8a2                	sd	s0,112(sp)
ffffffffc0201c64:	f862                	sd	s8,48(sp)
ffffffffc0201c66:	f466                	sd	s9,40(sp)
ffffffffc0201c68:	ec6e                	sd	s11,24(sp)
ffffffffc0201c6a:	892a                	mv	s2,a0
ffffffffc0201c6c:	84ae                	mv	s1,a1
ffffffffc0201c6e:	8d32                	mv	s10,a2
ffffffffc0201c70:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c72:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201c76:	5b7d                	li	s6,-1
ffffffffc0201c78:	00001a97          	auipc	s5,0x1
ffffffffc0201c7c:	74ca8a93          	addi	s5,s5,1868 # ffffffffc02033c4 <default_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c80:	00002b97          	auipc	s7,0x2
ffffffffc0201c84:	920b8b93          	addi	s7,s7,-1760 # ffffffffc02035a0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c88:	000d4503          	lbu	a0,0(s10)
ffffffffc0201c8c:	001d0413          	addi	s0,s10,1
ffffffffc0201c90:	01350a63          	beq	a0,s3,ffffffffc0201ca4 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201c94:	c121                	beqz	a0,ffffffffc0201cd4 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201c96:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c98:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201c9a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201c9c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201ca0:	ff351ae3          	bne	a0,s3,ffffffffc0201c94 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ca4:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201ca8:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201cac:	4c81                	li	s9,0
ffffffffc0201cae:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201cb0:	5c7d                	li	s8,-1
ffffffffc0201cb2:	5dfd                	li	s11,-1
ffffffffc0201cb4:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201cb8:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cba:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201cbe:	0ff5f593          	zext.b	a1,a1
ffffffffc0201cc2:	00140d13          	addi	s10,s0,1
ffffffffc0201cc6:	04b56263          	bltu	a0,a1,ffffffffc0201d0a <vprintfmt+0xbc>
ffffffffc0201cca:	058a                	slli	a1,a1,0x2
ffffffffc0201ccc:	95d6                	add	a1,a1,s5
ffffffffc0201cce:	4194                	lw	a3,0(a1)
ffffffffc0201cd0:	96d6                	add	a3,a3,s5
ffffffffc0201cd2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201cd4:	70e6                	ld	ra,120(sp)
ffffffffc0201cd6:	7446                	ld	s0,112(sp)
ffffffffc0201cd8:	74a6                	ld	s1,104(sp)
ffffffffc0201cda:	7906                	ld	s2,96(sp)
ffffffffc0201cdc:	69e6                	ld	s3,88(sp)
ffffffffc0201cde:	6a46                	ld	s4,80(sp)
ffffffffc0201ce0:	6aa6                	ld	s5,72(sp)
ffffffffc0201ce2:	6b06                	ld	s6,64(sp)
ffffffffc0201ce4:	7be2                	ld	s7,56(sp)
ffffffffc0201ce6:	7c42                	ld	s8,48(sp)
ffffffffc0201ce8:	7ca2                	ld	s9,40(sp)
ffffffffc0201cea:	7d02                	ld	s10,32(sp)
ffffffffc0201cec:	6de2                	ld	s11,24(sp)
ffffffffc0201cee:	6109                	addi	sp,sp,128
ffffffffc0201cf0:	8082                	ret
            padc = '0';
ffffffffc0201cf2:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201cf4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201cf8:	846a                	mv	s0,s10
ffffffffc0201cfa:	00140d13          	addi	s10,s0,1
ffffffffc0201cfe:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201d02:	0ff5f593          	zext.b	a1,a1
ffffffffc0201d06:	fcb572e3          	bgeu	a0,a1,ffffffffc0201cca <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201d0a:	85a6                	mv	a1,s1
ffffffffc0201d0c:	02500513          	li	a0,37
ffffffffc0201d10:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201d12:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201d16:	8d22                	mv	s10,s0
ffffffffc0201d18:	f73788e3          	beq	a5,s3,ffffffffc0201c88 <vprintfmt+0x3a>
ffffffffc0201d1c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201d20:	1d7d                	addi	s10,s10,-1
ffffffffc0201d22:	ff379de3          	bne	a5,s3,ffffffffc0201d1c <vprintfmt+0xce>
ffffffffc0201d26:	b78d                	j	ffffffffc0201c88 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201d28:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201d2c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d30:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201d32:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201d36:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201d3a:	02d86463          	bltu	a6,a3,ffffffffc0201d62 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201d3e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201d42:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201d46:	0186873b          	addw	a4,a3,s8
ffffffffc0201d4a:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201d4e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201d50:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201d54:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201d56:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201d5a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201d5e:	fed870e3          	bgeu	a6,a3,ffffffffc0201d3e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201d62:	f40ddce3          	bgez	s11,ffffffffc0201cba <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201d66:	8de2                	mv	s11,s8
ffffffffc0201d68:	5c7d                	li	s8,-1
ffffffffc0201d6a:	bf81                	j	ffffffffc0201cba <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201d6c:	fffdc693          	not	a3,s11
ffffffffc0201d70:	96fd                	srai	a3,a3,0x3f
ffffffffc0201d72:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d76:	00144603          	lbu	a2,1(s0)
ffffffffc0201d7a:	2d81                	sext.w	s11,s11
ffffffffc0201d7c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201d7e:	bf35                	j	ffffffffc0201cba <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201d80:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d84:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201d88:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201d8a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201d8c:	bfd9                	j	ffffffffc0201d62 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201d8e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d90:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201d94:	01174463          	blt	a4,a7,ffffffffc0201d9c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201d98:	1a088e63          	beqz	a7,ffffffffc0201f54 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201d9c:	000a3603          	ld	a2,0(s4)
ffffffffc0201da0:	46c1                	li	a3,16
ffffffffc0201da2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201da4:	2781                	sext.w	a5,a5
ffffffffc0201da6:	876e                	mv	a4,s11
ffffffffc0201da8:	85a6                	mv	a1,s1
ffffffffc0201daa:	854a                	mv	a0,s2
ffffffffc0201dac:	e37ff0ef          	jal	ra,ffffffffc0201be2 <printnum>
            break;
ffffffffc0201db0:	bde1                	j	ffffffffc0201c88 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201db2:	000a2503          	lw	a0,0(s4)
ffffffffc0201db6:	85a6                	mv	a1,s1
ffffffffc0201db8:	0a21                	addi	s4,s4,8
ffffffffc0201dba:	9902                	jalr	s2
            break;
ffffffffc0201dbc:	b5f1                	j	ffffffffc0201c88 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201dbe:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201dc0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201dc4:	01174463          	blt	a4,a7,ffffffffc0201dcc <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201dc8:	18088163          	beqz	a7,ffffffffc0201f4a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201dcc:	000a3603          	ld	a2,0(s4)
ffffffffc0201dd0:	46a9                	li	a3,10
ffffffffc0201dd2:	8a2e                	mv	s4,a1
ffffffffc0201dd4:	bfc1                	j	ffffffffc0201da4 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201dd6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201dda:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ddc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201dde:	bdf1                	j	ffffffffc0201cba <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201de0:	85a6                	mv	a1,s1
ffffffffc0201de2:	02500513          	li	a0,37
ffffffffc0201de6:	9902                	jalr	s2
            break;
ffffffffc0201de8:	b545                	j	ffffffffc0201c88 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201dea:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201dee:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201df0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201df2:	b5e1                	j	ffffffffc0201cba <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201df4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201df6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201dfa:	01174463          	blt	a4,a7,ffffffffc0201e02 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201dfe:	14088163          	beqz	a7,ffffffffc0201f40 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201e02:	000a3603          	ld	a2,0(s4)
ffffffffc0201e06:	46a1                	li	a3,8
ffffffffc0201e08:	8a2e                	mv	s4,a1
ffffffffc0201e0a:	bf69                	j	ffffffffc0201da4 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201e0c:	03000513          	li	a0,48
ffffffffc0201e10:	85a6                	mv	a1,s1
ffffffffc0201e12:	e03e                	sd	a5,0(sp)
ffffffffc0201e14:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201e16:	85a6                	mv	a1,s1
ffffffffc0201e18:	07800513          	li	a0,120
ffffffffc0201e1c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201e1e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201e20:	6782                	ld	a5,0(sp)
ffffffffc0201e22:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201e24:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201e28:	bfb5                	j	ffffffffc0201da4 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201e2a:	000a3403          	ld	s0,0(s4)
ffffffffc0201e2e:	008a0713          	addi	a4,s4,8
ffffffffc0201e32:	e03a                	sd	a4,0(sp)
ffffffffc0201e34:	14040263          	beqz	s0,ffffffffc0201f78 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201e38:	0fb05763          	blez	s11,ffffffffc0201f26 <vprintfmt+0x2d8>
ffffffffc0201e3c:	02d00693          	li	a3,45
ffffffffc0201e40:	0cd79163          	bne	a5,a3,ffffffffc0201f02 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e44:	00044783          	lbu	a5,0(s0)
ffffffffc0201e48:	0007851b          	sext.w	a0,a5
ffffffffc0201e4c:	cf85                	beqz	a5,ffffffffc0201e84 <vprintfmt+0x236>
ffffffffc0201e4e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e52:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e56:	000c4563          	bltz	s8,ffffffffc0201e60 <vprintfmt+0x212>
ffffffffc0201e5a:	3c7d                	addiw	s8,s8,-1
ffffffffc0201e5c:	036c0263          	beq	s8,s6,ffffffffc0201e80 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201e60:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e62:	0e0c8e63          	beqz	s9,ffffffffc0201f5e <vprintfmt+0x310>
ffffffffc0201e66:	3781                	addiw	a5,a5,-32
ffffffffc0201e68:	0ef47b63          	bgeu	s0,a5,ffffffffc0201f5e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201e6c:	03f00513          	li	a0,63
ffffffffc0201e70:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e72:	000a4783          	lbu	a5,0(s4)
ffffffffc0201e76:	3dfd                	addiw	s11,s11,-1
ffffffffc0201e78:	0a05                	addi	s4,s4,1
ffffffffc0201e7a:	0007851b          	sext.w	a0,a5
ffffffffc0201e7e:	ffe1                	bnez	a5,ffffffffc0201e56 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201e80:	01b05963          	blez	s11,ffffffffc0201e92 <vprintfmt+0x244>
ffffffffc0201e84:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201e86:	85a6                	mv	a1,s1
ffffffffc0201e88:	02000513          	li	a0,32
ffffffffc0201e8c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201e8e:	fe0d9be3          	bnez	s11,ffffffffc0201e84 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201e92:	6a02                	ld	s4,0(sp)
ffffffffc0201e94:	bbd5                	j	ffffffffc0201c88 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201e96:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201e98:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201e9c:	01174463          	blt	a4,a7,ffffffffc0201ea4 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201ea0:	08088d63          	beqz	a7,ffffffffc0201f3a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201ea4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201ea8:	0a044d63          	bltz	s0,ffffffffc0201f62 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201eac:	8622                	mv	a2,s0
ffffffffc0201eae:	8a66                	mv	s4,s9
ffffffffc0201eb0:	46a9                	li	a3,10
ffffffffc0201eb2:	bdcd                	j	ffffffffc0201da4 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201eb4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201eb8:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201eba:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201ebc:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201ec0:	8fb5                	xor	a5,a5,a3
ffffffffc0201ec2:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ec6:	02d74163          	blt	a4,a3,ffffffffc0201ee8 <vprintfmt+0x29a>
ffffffffc0201eca:	00369793          	slli	a5,a3,0x3
ffffffffc0201ece:	97de                	add	a5,a5,s7
ffffffffc0201ed0:	639c                	ld	a5,0(a5)
ffffffffc0201ed2:	cb99                	beqz	a5,ffffffffc0201ee8 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201ed4:	86be                	mv	a3,a5
ffffffffc0201ed6:	00001617          	auipc	a2,0x1
ffffffffc0201eda:	4ea60613          	addi	a2,a2,1258 # ffffffffc02033c0 <default_pmm_manager+0x1b0>
ffffffffc0201ede:	85a6                	mv	a1,s1
ffffffffc0201ee0:	854a                	mv	a0,s2
ffffffffc0201ee2:	0ce000ef          	jal	ra,ffffffffc0201fb0 <printfmt>
ffffffffc0201ee6:	b34d                	j	ffffffffc0201c88 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201ee8:	00001617          	auipc	a2,0x1
ffffffffc0201eec:	4c860613          	addi	a2,a2,1224 # ffffffffc02033b0 <default_pmm_manager+0x1a0>
ffffffffc0201ef0:	85a6                	mv	a1,s1
ffffffffc0201ef2:	854a                	mv	a0,s2
ffffffffc0201ef4:	0bc000ef          	jal	ra,ffffffffc0201fb0 <printfmt>
ffffffffc0201ef8:	bb41                	j	ffffffffc0201c88 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201efa:	00001417          	auipc	s0,0x1
ffffffffc0201efe:	4ae40413          	addi	s0,s0,1198 # ffffffffc02033a8 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201f02:	85e2                	mv	a1,s8
ffffffffc0201f04:	8522                	mv	a0,s0
ffffffffc0201f06:	e43e                	sd	a5,8(sp)
ffffffffc0201f08:	200000ef          	jal	ra,ffffffffc0202108 <strnlen>
ffffffffc0201f0c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201f10:	01b05b63          	blez	s11,ffffffffc0201f26 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201f14:	67a2                	ld	a5,8(sp)
ffffffffc0201f16:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201f1a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201f1c:	85a6                	mv	a1,s1
ffffffffc0201f1e:	8552                	mv	a0,s4
ffffffffc0201f20:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201f22:	fe0d9ce3          	bnez	s11,ffffffffc0201f1a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201f26:	00044783          	lbu	a5,0(s0)
ffffffffc0201f2a:	00140a13          	addi	s4,s0,1
ffffffffc0201f2e:	0007851b          	sext.w	a0,a5
ffffffffc0201f32:	d3a5                	beqz	a5,ffffffffc0201e92 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201f34:	05e00413          	li	s0,94
ffffffffc0201f38:	bf39                	j	ffffffffc0201e56 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201f3a:	000a2403          	lw	s0,0(s4)
ffffffffc0201f3e:	b7ad                	j	ffffffffc0201ea8 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201f40:	000a6603          	lwu	a2,0(s4)
ffffffffc0201f44:	46a1                	li	a3,8
ffffffffc0201f46:	8a2e                	mv	s4,a1
ffffffffc0201f48:	bdb1                	j	ffffffffc0201da4 <vprintfmt+0x156>
ffffffffc0201f4a:	000a6603          	lwu	a2,0(s4)
ffffffffc0201f4e:	46a9                	li	a3,10
ffffffffc0201f50:	8a2e                	mv	s4,a1
ffffffffc0201f52:	bd89                	j	ffffffffc0201da4 <vprintfmt+0x156>
ffffffffc0201f54:	000a6603          	lwu	a2,0(s4)
ffffffffc0201f58:	46c1                	li	a3,16
ffffffffc0201f5a:	8a2e                	mv	s4,a1
ffffffffc0201f5c:	b5a1                	j	ffffffffc0201da4 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201f5e:	9902                	jalr	s2
ffffffffc0201f60:	bf09                	j	ffffffffc0201e72 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201f62:	85a6                	mv	a1,s1
ffffffffc0201f64:	02d00513          	li	a0,45
ffffffffc0201f68:	e03e                	sd	a5,0(sp)
ffffffffc0201f6a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201f6c:	6782                	ld	a5,0(sp)
ffffffffc0201f6e:	8a66                	mv	s4,s9
ffffffffc0201f70:	40800633          	neg	a2,s0
ffffffffc0201f74:	46a9                	li	a3,10
ffffffffc0201f76:	b53d                	j	ffffffffc0201da4 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201f78:	03b05163          	blez	s11,ffffffffc0201f9a <vprintfmt+0x34c>
ffffffffc0201f7c:	02d00693          	li	a3,45
ffffffffc0201f80:	f6d79de3          	bne	a5,a3,ffffffffc0201efa <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201f84:	00001417          	auipc	s0,0x1
ffffffffc0201f88:	42440413          	addi	s0,s0,1060 # ffffffffc02033a8 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201f8c:	02800793          	li	a5,40
ffffffffc0201f90:	02800513          	li	a0,40
ffffffffc0201f94:	00140a13          	addi	s4,s0,1
ffffffffc0201f98:	bd6d                	j	ffffffffc0201e52 <vprintfmt+0x204>
ffffffffc0201f9a:	00001a17          	auipc	s4,0x1
ffffffffc0201f9e:	40fa0a13          	addi	s4,s4,1039 # ffffffffc02033a9 <default_pmm_manager+0x199>
ffffffffc0201fa2:	02800513          	li	a0,40
ffffffffc0201fa6:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201faa:	05e00413          	li	s0,94
ffffffffc0201fae:	b565                	j	ffffffffc0201e56 <vprintfmt+0x208>

ffffffffc0201fb0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201fb0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201fb2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201fb6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201fb8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201fba:	ec06                	sd	ra,24(sp)
ffffffffc0201fbc:	f83a                	sd	a4,48(sp)
ffffffffc0201fbe:	fc3e                	sd	a5,56(sp)
ffffffffc0201fc0:	e0c2                	sd	a6,64(sp)
ffffffffc0201fc2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201fc4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201fc6:	c89ff0ef          	jal	ra,ffffffffc0201c4e <vprintfmt>
}
ffffffffc0201fca:	60e2                	ld	ra,24(sp)
ffffffffc0201fcc:	6161                	addi	sp,sp,80
ffffffffc0201fce:	8082                	ret

ffffffffc0201fd0 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201fd0:	715d                	addi	sp,sp,-80
ffffffffc0201fd2:	e486                	sd	ra,72(sp)
ffffffffc0201fd4:	e0a6                	sd	s1,64(sp)
ffffffffc0201fd6:	fc4a                	sd	s2,56(sp)
ffffffffc0201fd8:	f84e                	sd	s3,48(sp)
ffffffffc0201fda:	f452                	sd	s4,40(sp)
ffffffffc0201fdc:	f056                	sd	s5,32(sp)
ffffffffc0201fde:	ec5a                	sd	s6,24(sp)
ffffffffc0201fe0:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201fe2:	c901                	beqz	a0,ffffffffc0201ff2 <readline+0x22>
ffffffffc0201fe4:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201fe6:	00001517          	auipc	a0,0x1
ffffffffc0201fea:	3da50513          	addi	a0,a0,986 # ffffffffc02033c0 <default_pmm_manager+0x1b0>
ffffffffc0201fee:	920fe0ef          	jal	ra,ffffffffc020010e <cprintf>
readline(const char *prompt) {
ffffffffc0201ff2:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ff4:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201ff6:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201ff8:	4aa9                	li	s5,10
ffffffffc0201ffa:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201ffc:	00005b97          	auipc	s7,0x5
ffffffffc0202000:	044b8b93          	addi	s7,s7,68 # ffffffffc0207040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0202004:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0202008:	97efe0ef          	jal	ra,ffffffffc0200186 <getchar>
        if (c < 0) {
ffffffffc020200c:	00054a63          	bltz	a0,ffffffffc0202020 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0202010:	00a95a63          	bge	s2,a0,ffffffffc0202024 <readline+0x54>
ffffffffc0202014:	029a5263          	bge	s4,s1,ffffffffc0202038 <readline+0x68>
        c = getchar();
ffffffffc0202018:	96efe0ef          	jal	ra,ffffffffc0200186 <getchar>
        if (c < 0) {
ffffffffc020201c:	fe055ae3          	bgez	a0,ffffffffc0202010 <readline+0x40>
            return NULL;
ffffffffc0202020:	4501                	li	a0,0
ffffffffc0202022:	a091                	j	ffffffffc0202066 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0202024:	03351463          	bne	a0,s3,ffffffffc020204c <readline+0x7c>
ffffffffc0202028:	e8a9                	bnez	s1,ffffffffc020207a <readline+0xaa>
        c = getchar();
ffffffffc020202a:	95cfe0ef          	jal	ra,ffffffffc0200186 <getchar>
        if (c < 0) {
ffffffffc020202e:	fe0549e3          	bltz	a0,ffffffffc0202020 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0202032:	fea959e3          	bge	s2,a0,ffffffffc0202024 <readline+0x54>
ffffffffc0202036:	4481                	li	s1,0
            cputchar(c);
ffffffffc0202038:	e42a                	sd	a0,8(sp)
ffffffffc020203a:	90afe0ef          	jal	ra,ffffffffc0200144 <cputchar>
            buf[i ++] = c;
ffffffffc020203e:	6522                	ld	a0,8(sp)
ffffffffc0202040:	009b87b3          	add	a5,s7,s1
ffffffffc0202044:	2485                	addiw	s1,s1,1
ffffffffc0202046:	00a78023          	sb	a0,0(a5)
ffffffffc020204a:	bf7d                	j	ffffffffc0202008 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020204c:	01550463          	beq	a0,s5,ffffffffc0202054 <readline+0x84>
ffffffffc0202050:	fb651ce3          	bne	a0,s6,ffffffffc0202008 <readline+0x38>
            cputchar(c);
ffffffffc0202054:	8f0fe0ef          	jal	ra,ffffffffc0200144 <cputchar>
            buf[i] = '\0';
ffffffffc0202058:	00005517          	auipc	a0,0x5
ffffffffc020205c:	fe850513          	addi	a0,a0,-24 # ffffffffc0207040 <buf>
ffffffffc0202060:	94aa                	add	s1,s1,a0
ffffffffc0202062:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0202066:	60a6                	ld	ra,72(sp)
ffffffffc0202068:	6486                	ld	s1,64(sp)
ffffffffc020206a:	7962                	ld	s2,56(sp)
ffffffffc020206c:	79c2                	ld	s3,48(sp)
ffffffffc020206e:	7a22                	ld	s4,40(sp)
ffffffffc0202070:	7a82                	ld	s5,32(sp)
ffffffffc0202072:	6b62                	ld	s6,24(sp)
ffffffffc0202074:	6bc2                	ld	s7,16(sp)
ffffffffc0202076:	6161                	addi	sp,sp,80
ffffffffc0202078:	8082                	ret
            cputchar(c);
ffffffffc020207a:	4521                	li	a0,8
ffffffffc020207c:	8c8fe0ef          	jal	ra,ffffffffc0200144 <cputchar>
            i --;
ffffffffc0202080:	34fd                	addiw	s1,s1,-1
ffffffffc0202082:	b759                	j	ffffffffc0202008 <readline+0x38>

ffffffffc0202084 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0202084:	4781                	li	a5,0
ffffffffc0202086:	00005717          	auipc	a4,0x5
ffffffffc020208a:	f9273703          	ld	a4,-110(a4) # ffffffffc0207018 <SBI_CONSOLE_PUTCHAR>
ffffffffc020208e:	88ba                	mv	a7,a4
ffffffffc0202090:	852a                	mv	a0,a0
ffffffffc0202092:	85be                	mv	a1,a5
ffffffffc0202094:	863e                	mv	a2,a5
ffffffffc0202096:	00000073          	ecall
ffffffffc020209a:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc020209c:	8082                	ret

ffffffffc020209e <sbi_set_timer>:
    __asm__ volatile (
ffffffffc020209e:	4781                	li	a5,0
ffffffffc02020a0:	00005717          	auipc	a4,0x5
ffffffffc02020a4:	3f873703          	ld	a4,1016(a4) # ffffffffc0207498 <SBI_SET_TIMER>
ffffffffc02020a8:	88ba                	mv	a7,a4
ffffffffc02020aa:	852a                	mv	a0,a0
ffffffffc02020ac:	85be                	mv	a1,a5
ffffffffc02020ae:	863e                	mv	a2,a5
ffffffffc02020b0:	00000073          	ecall
ffffffffc02020b4:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc02020b6:	8082                	ret

ffffffffc02020b8 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc02020b8:	4501                	li	a0,0
ffffffffc02020ba:	00005797          	auipc	a5,0x5
ffffffffc02020be:	f567b783          	ld	a5,-170(a5) # ffffffffc0207010 <SBI_CONSOLE_GETCHAR>
ffffffffc02020c2:	88be                	mv	a7,a5
ffffffffc02020c4:	852a                	mv	a0,a0
ffffffffc02020c6:	85aa                	mv	a1,a0
ffffffffc02020c8:	862a                	mv	a2,a0
ffffffffc02020ca:	00000073          	ecall
ffffffffc02020ce:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc02020d0:	2501                	sext.w	a0,a0
ffffffffc02020d2:	8082                	ret

ffffffffc02020d4 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc02020d4:	4781                	li	a5,0
ffffffffc02020d6:	00005717          	auipc	a4,0x5
ffffffffc02020da:	f4a73703          	ld	a4,-182(a4) # ffffffffc0207020 <SBI_SHUTDOWN>
ffffffffc02020de:	88ba                	mv	a7,a4
ffffffffc02020e0:	853e                	mv	a0,a5
ffffffffc02020e2:	85be                	mv	a1,a5
ffffffffc02020e4:	863e                	mv	a2,a5
ffffffffc02020e6:	00000073          	ecall
ffffffffc02020ea:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc02020ec:	8082                	ret

ffffffffc02020ee <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02020ee:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02020f2:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02020f4:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02020f6:	cb81                	beqz	a5,ffffffffc0202106 <strlen+0x18>
        cnt ++;
ffffffffc02020f8:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02020fa:	00a707b3          	add	a5,a4,a0
ffffffffc02020fe:	0007c783          	lbu	a5,0(a5)
ffffffffc0202102:	fbfd                	bnez	a5,ffffffffc02020f8 <strlen+0xa>
ffffffffc0202104:	8082                	ret
    }
    return cnt;
}
ffffffffc0202106:	8082                	ret

ffffffffc0202108 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0202108:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020210a:	e589                	bnez	a1,ffffffffc0202114 <strnlen+0xc>
ffffffffc020210c:	a811                	j	ffffffffc0202120 <strnlen+0x18>
        cnt ++;
ffffffffc020210e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0202110:	00f58863          	beq	a1,a5,ffffffffc0202120 <strnlen+0x18>
ffffffffc0202114:	00f50733          	add	a4,a0,a5
ffffffffc0202118:	00074703          	lbu	a4,0(a4)
ffffffffc020211c:	fb6d                	bnez	a4,ffffffffc020210e <strnlen+0x6>
ffffffffc020211e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0202120:	852e                	mv	a0,a1
ffffffffc0202122:	8082                	ret

ffffffffc0202124 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202124:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202128:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020212c:	cb89                	beqz	a5,ffffffffc020213e <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020212e:	0505                	addi	a0,a0,1
ffffffffc0202130:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202132:	fee789e3          	beq	a5,a4,ffffffffc0202124 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202136:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020213a:	9d19                	subw	a0,a0,a4
ffffffffc020213c:	8082                	ret
ffffffffc020213e:	4501                	li	a0,0
ffffffffc0202140:	bfed                	j	ffffffffc020213a <strcmp+0x16>

ffffffffc0202142 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202142:	c20d                	beqz	a2,ffffffffc0202164 <strncmp+0x22>
ffffffffc0202144:	962e                	add	a2,a2,a1
ffffffffc0202146:	a031                	j	ffffffffc0202152 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0202148:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020214a:	00e79a63          	bne	a5,a4,ffffffffc020215e <strncmp+0x1c>
ffffffffc020214e:	00b60b63          	beq	a2,a1,ffffffffc0202164 <strncmp+0x22>
ffffffffc0202152:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0202156:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202158:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020215c:	f7f5                	bnez	a5,ffffffffc0202148 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020215e:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0202162:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202164:	4501                	li	a0,0
ffffffffc0202166:	8082                	ret

ffffffffc0202168 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0202168:	00054783          	lbu	a5,0(a0)
ffffffffc020216c:	c799                	beqz	a5,ffffffffc020217a <strchr+0x12>
        if (*s == c) {
ffffffffc020216e:	00f58763          	beq	a1,a5,ffffffffc020217c <strchr+0x14>
    while (*s != '\0') {
ffffffffc0202172:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0202176:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0202178:	fbfd                	bnez	a5,ffffffffc020216e <strchr+0x6>
    }
    return NULL;
ffffffffc020217a:	4501                	li	a0,0
}
ffffffffc020217c:	8082                	ret

ffffffffc020217e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020217e:	ca01                	beqz	a2,ffffffffc020218e <memset+0x10>
ffffffffc0202180:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0202182:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0202184:	0785                	addi	a5,a5,1
ffffffffc0202186:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020218a:	fec79de3          	bne	a5,a2,ffffffffc0202184 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020218e:	8082                	ret
