
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
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
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
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
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0206028 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02064a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	73f010ef          	jal	ra,ffffffffc0201faa <memset>
    dtb_init();
ffffffffc0200070:	40e000ef          	jal	ra,ffffffffc020047e <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3fc000ef          	jal	ra,ffffffffc0200470 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	f4850513          	addi	a0,a0,-184 # ffffffffc0201fc0 <etext+0x4>
ffffffffc0200080:	090000ef          	jal	ra,ffffffffc0200110 <cputs>

    print_kerninfo();
ffffffffc0200084:	0dc000ef          	jal	ra,ffffffffc0200160 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7b2000ef          	jal	ra,ffffffffc020083a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	7a2010ef          	jal	ra,ffffffffc020182e <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7aa000ef          	jal	ra,ffffffffc020083a <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	39a000ef          	jal	ra,ffffffffc020042e <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	796000ef          	jal	ra,ffffffffc020082e <intr_enable>

    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000a6:	3cc000ef          	jal	ra,ffffffffc0200472 <cons_putc>
    (*cnt) ++;
ffffffffc02000aa:	401c                	lw	a5,0(s0)
}
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ca:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000cc:	1af010ef          	jal	ra,ffffffffc0201a7a <vprintfmt>
    return cnt;
}
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000da:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000de:	8e2a                	mv	t3,a0
ffffffffc02000e0:	f42e                	sd	a1,40(sp)
ffffffffc02000e2:	f832                	sd	a2,48(sp)
ffffffffc02000e4:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	004c                	addi	a1,sp,4
ffffffffc02000f0:	869a                	mv	a3,t1
ffffffffc02000f2:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000f4:	ec06                	sd	ra,24(sp)
ffffffffc02000f6:	e0ba                	sd	a4,64(sp)
ffffffffc02000f8:	e4be                	sd	a5,72(sp)
ffffffffc02000fa:	e8c2                	sd	a6,80(sp)
ffffffffc02000fc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000fe:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200100:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200102:	179010ef          	jal	ra,ffffffffc0201a7a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200106:	60e2                	ld	ra,24(sp)
ffffffffc0200108:	4512                	lw	a0,4(sp)
ffffffffc020010a:	6125                	addi	sp,sp,96
ffffffffc020010c:	8082                	ret

ffffffffc020010e <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010e:	a695                	j	ffffffffc0200472 <cons_putc>

ffffffffc0200110 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e426                	sd	s1,8(sp)
ffffffffc0200118:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020011a:	00054503          	lbu	a0,0(a0)
ffffffffc020011e:	c51d                	beqz	a0,ffffffffc020014c <cputs+0x3c>
ffffffffc0200120:	0405                	addi	s0,s0,1
ffffffffc0200122:	4485                	li	s1,1
ffffffffc0200124:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200126:	34c000ef          	jal	ra,ffffffffc0200472 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	00044503          	lbu	a0,0(s0)
ffffffffc020012e:	008487bb          	addw	a5,s1,s0
ffffffffc0200132:	0405                	addi	s0,s0,1
ffffffffc0200134:	f96d                	bnez	a0,ffffffffc0200126 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200136:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020013a:	4529                	li	a0,10
ffffffffc020013c:	336000ef          	jal	ra,ffffffffc0200472 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	64a2                	ld	s1,8(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020014c:	4405                	li	s0,1
ffffffffc020014e:	b7f5                	j	ffffffffc020013a <cputs+0x2a>

ffffffffc0200150 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200150:	1141                	addi	sp,sp,-16
ffffffffc0200152:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200154:	326000ef          	jal	ra,ffffffffc020047a <cons_getc>
ffffffffc0200158:	dd75                	beqz	a0,ffffffffc0200154 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020015a:	60a2                	ld	ra,8(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200160:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200162:	00002517          	auipc	a0,0x2
ffffffffc0200166:	e7e50513          	addi	a0,a0,-386 # ffffffffc0201fe0 <etext+0x24>
void print_kerninfo(void) {
ffffffffc020016a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020016c:	f6dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200170:	00000597          	auipc	a1,0x0
ffffffffc0200174:	ee458593          	addi	a1,a1,-284 # ffffffffc0200054 <kern_init>
ffffffffc0200178:	00002517          	auipc	a0,0x2
ffffffffc020017c:	e8850513          	addi	a0,a0,-376 # ffffffffc0202000 <etext+0x44>
ffffffffc0200180:	f59ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200184:	00002597          	auipc	a1,0x2
ffffffffc0200188:	e3858593          	addi	a1,a1,-456 # ffffffffc0201fbc <etext>
ffffffffc020018c:	00002517          	auipc	a0,0x2
ffffffffc0200190:	e9450513          	addi	a0,a0,-364 # ffffffffc0202020 <etext+0x64>
ffffffffc0200194:	f45ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200198:	00006597          	auipc	a1,0x6
ffffffffc020019c:	e9058593          	addi	a1,a1,-368 # ffffffffc0206028 <free_area>
ffffffffc02001a0:	00002517          	auipc	a0,0x2
ffffffffc02001a4:	ea050513          	addi	a0,a0,-352 # ffffffffc0202040 <etext+0x84>
ffffffffc02001a8:	f31ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001ac:	00006597          	auipc	a1,0x6
ffffffffc02001b0:	2f458593          	addi	a1,a1,756 # ffffffffc02064a0 <end>
ffffffffc02001b4:	00002517          	auipc	a0,0x2
ffffffffc02001b8:	eac50513          	addi	a0,a0,-340 # ffffffffc0202060 <etext+0xa4>
ffffffffc02001bc:	f1dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c0:	00006597          	auipc	a1,0x6
ffffffffc02001c4:	6df58593          	addi	a1,a1,1759 # ffffffffc020689f <end+0x3ff>
ffffffffc02001c8:	00000797          	auipc	a5,0x0
ffffffffc02001cc:	e8c78793          	addi	a5,a5,-372 # ffffffffc0200054 <kern_init>
ffffffffc02001d0:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d4:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001d8:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001da:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001de:	95be                	add	a1,a1,a5
ffffffffc02001e0:	85a9                	srai	a1,a1,0xa
ffffffffc02001e2:	00002517          	auipc	a0,0x2
ffffffffc02001e6:	e9e50513          	addi	a0,a0,-354 # ffffffffc0202080 <etext+0xc4>
}
ffffffffc02001ea:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ec:	b5f5                	j	ffffffffc02000d8 <cprintf>

ffffffffc02001ee <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ee:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001f0:	00002617          	auipc	a2,0x2
ffffffffc02001f4:	ec060613          	addi	a2,a2,-320 # ffffffffc02020b0 <etext+0xf4>
ffffffffc02001f8:	04d00593          	li	a1,77
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	ecc50513          	addi	a0,a0,-308 # ffffffffc02020c8 <etext+0x10c>
void print_stackframe(void) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200206:	1cc000ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc020020a <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020020a:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020c:	00002617          	auipc	a2,0x2
ffffffffc0200210:	ed460613          	addi	a2,a2,-300 # ffffffffc02020e0 <etext+0x124>
ffffffffc0200214:	00002597          	auipc	a1,0x2
ffffffffc0200218:	eec58593          	addi	a1,a1,-276 # ffffffffc0202100 <etext+0x144>
ffffffffc020021c:	00002517          	auipc	a0,0x2
ffffffffc0200220:	eec50513          	addi	a0,a0,-276 # ffffffffc0202108 <etext+0x14c>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200224:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200226:	eb3ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020022a:	00002617          	auipc	a2,0x2
ffffffffc020022e:	eee60613          	addi	a2,a2,-274 # ffffffffc0202118 <etext+0x15c>
ffffffffc0200232:	00002597          	auipc	a1,0x2
ffffffffc0200236:	f0e58593          	addi	a1,a1,-242 # ffffffffc0202140 <etext+0x184>
ffffffffc020023a:	00002517          	auipc	a0,0x2
ffffffffc020023e:	ece50513          	addi	a0,a0,-306 # ffffffffc0202108 <etext+0x14c>
ffffffffc0200242:	e97ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200246:	00002617          	auipc	a2,0x2
ffffffffc020024a:	f0a60613          	addi	a2,a2,-246 # ffffffffc0202150 <etext+0x194>
ffffffffc020024e:	00002597          	auipc	a1,0x2
ffffffffc0200252:	f2258593          	addi	a1,a1,-222 # ffffffffc0202170 <etext+0x1b4>
ffffffffc0200256:	00002517          	auipc	a0,0x2
ffffffffc020025a:	eb250513          	addi	a0,a0,-334 # ffffffffc0202108 <etext+0x14c>
ffffffffc020025e:	e7bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020026a:	1141                	addi	sp,sp,-16
ffffffffc020026c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020026e:	ef3ff0ef          	jal	ra,ffffffffc0200160 <print_kerninfo>
    return 0;
}
ffffffffc0200272:	60a2                	ld	ra,8(sp)
ffffffffc0200274:	4501                	li	a0,0
ffffffffc0200276:	0141                	addi	sp,sp,16
ffffffffc0200278:	8082                	ret

ffffffffc020027a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020027a:	1141                	addi	sp,sp,-16
ffffffffc020027c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020027e:	f71ff0ef          	jal	ra,ffffffffc02001ee <print_stackframe>
    return 0;
}
ffffffffc0200282:	60a2                	ld	ra,8(sp)
ffffffffc0200284:	4501                	li	a0,0
ffffffffc0200286:	0141                	addi	sp,sp,16
ffffffffc0200288:	8082                	ret

ffffffffc020028a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020028a:	7115                	addi	sp,sp,-224
ffffffffc020028c:	ed5e                	sd	s7,152(sp)
ffffffffc020028e:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200290:	00002517          	auipc	a0,0x2
ffffffffc0200294:	ef050513          	addi	a0,a0,-272 # ffffffffc0202180 <etext+0x1c4>
kmonitor(struct trapframe *tf) {
ffffffffc0200298:	ed86                	sd	ra,216(sp)
ffffffffc020029a:	e9a2                	sd	s0,208(sp)
ffffffffc020029c:	e5a6                	sd	s1,200(sp)
ffffffffc020029e:	e1ca                	sd	s2,192(sp)
ffffffffc02002a0:	fd4e                	sd	s3,184(sp)
ffffffffc02002a2:	f952                	sd	s4,176(sp)
ffffffffc02002a4:	f556                	sd	s5,168(sp)
ffffffffc02002a6:	f15a                	sd	s6,160(sp)
ffffffffc02002a8:	e962                	sd	s8,144(sp)
ffffffffc02002aa:	e566                	sd	s9,136(sp)
ffffffffc02002ac:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ae:	e2bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b2:	00002517          	auipc	a0,0x2
ffffffffc02002b6:	ef650513          	addi	a0,a0,-266 # ffffffffc02021a8 <etext+0x1ec>
ffffffffc02002ba:	e1fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc02002be:	000b8563          	beqz	s7,ffffffffc02002c8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c2:	855e                	mv	a0,s7
ffffffffc02002c4:	756000ef          	jal	ra,ffffffffc0200a1a <print_trapframe>
ffffffffc02002c8:	00002c17          	auipc	s8,0x2
ffffffffc02002cc:	f50c0c13          	addi	s8,s8,-176 # ffffffffc0202218 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d0:	00002917          	auipc	s2,0x2
ffffffffc02002d4:	f0090913          	addi	s2,s2,-256 # ffffffffc02021d0 <etext+0x214>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00002497          	auipc	s1,0x2
ffffffffc02002dc:	f0048493          	addi	s1,s1,-256 # ffffffffc02021d8 <etext+0x21c>
        if (argc == MAXARGS - 1) {
ffffffffc02002e0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e2:	00002b17          	auipc	s6,0x2
ffffffffc02002e6:	efeb0b13          	addi	s6,s6,-258 # ffffffffc02021e0 <etext+0x224>
        argv[argc ++] = buf;
ffffffffc02002ea:	00002a17          	auipc	s4,0x2
ffffffffc02002ee:	e16a0a13          	addi	s4,s4,-490 # ffffffffc0202100 <etext+0x144>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002f4:	854a                	mv	a0,s2
ffffffffc02002f6:	307010ef          	jal	ra,ffffffffc0201dfc <readline>
ffffffffc02002fa:	842a                	mv	s0,a0
ffffffffc02002fc:	dd65                	beqz	a0,ffffffffc02002f4 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002fe:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200302:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200304:	e1bd                	bnez	a1,ffffffffc020036a <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200306:	fe0c87e3          	beqz	s9,ffffffffc02002f4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	6582                	ld	a1,0(sp)
ffffffffc020030c:	00002d17          	auipc	s10,0x2
ffffffffc0200310:	f0cd0d13          	addi	s10,s10,-244 # ffffffffc0202218 <commands>
        argv[argc ++] = buf;
ffffffffc0200314:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200316:	4401                	li	s0,0
ffffffffc0200318:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031a:	437010ef          	jal	ra,ffffffffc0201f50 <strcmp>
ffffffffc020031e:	c919                	beqz	a0,ffffffffc0200334 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200320:	2405                	addiw	s0,s0,1
ffffffffc0200322:	0b540063          	beq	s0,s5,ffffffffc02003c2 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200326:	000d3503          	ld	a0,0(s10)
ffffffffc020032a:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032c:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032e:	423010ef          	jal	ra,ffffffffc0201f50 <strcmp>
ffffffffc0200332:	f57d                	bnez	a0,ffffffffc0200320 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200334:	00141793          	slli	a5,s0,0x1
ffffffffc0200338:	97a2                	add	a5,a5,s0
ffffffffc020033a:	078e                	slli	a5,a5,0x3
ffffffffc020033c:	97e2                	add	a5,a5,s8
ffffffffc020033e:	6b9c                	ld	a5,16(a5)
ffffffffc0200340:	865e                	mv	a2,s7
ffffffffc0200342:	002c                	addi	a1,sp,8
ffffffffc0200344:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200348:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020034a:	fa0555e3          	bgez	a0,ffffffffc02002f4 <kmonitor+0x6a>
}
ffffffffc020034e:	60ee                	ld	ra,216(sp)
ffffffffc0200350:	644e                	ld	s0,208(sp)
ffffffffc0200352:	64ae                	ld	s1,200(sp)
ffffffffc0200354:	690e                	ld	s2,192(sp)
ffffffffc0200356:	79ea                	ld	s3,184(sp)
ffffffffc0200358:	7a4a                	ld	s4,176(sp)
ffffffffc020035a:	7aaa                	ld	s5,168(sp)
ffffffffc020035c:	7b0a                	ld	s6,160(sp)
ffffffffc020035e:	6bea                	ld	s7,152(sp)
ffffffffc0200360:	6c4a                	ld	s8,144(sp)
ffffffffc0200362:	6caa                	ld	s9,136(sp)
ffffffffc0200364:	6d0a                	ld	s10,128(sp)
ffffffffc0200366:	612d                	addi	sp,sp,224
ffffffffc0200368:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020036a:	8526                	mv	a0,s1
ffffffffc020036c:	429010ef          	jal	ra,ffffffffc0201f94 <strchr>
ffffffffc0200370:	c901                	beqz	a0,ffffffffc0200380 <kmonitor+0xf6>
ffffffffc0200372:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200376:	00040023          	sb	zero,0(s0)
ffffffffc020037a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020037c:	d5c9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc020037e:	b7f5                	j	ffffffffc020036a <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200380:	00044783          	lbu	a5,0(s0)
ffffffffc0200384:	d3c9                	beqz	a5,ffffffffc0200306 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200386:	033c8963          	beq	s9,s3,ffffffffc02003b8 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020038a:	003c9793          	slli	a5,s9,0x3
ffffffffc020038e:	0118                	addi	a4,sp,128
ffffffffc0200390:	97ba                	add	a5,a5,a4
ffffffffc0200392:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200396:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020039a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039c:	e591                	bnez	a1,ffffffffc02003a8 <kmonitor+0x11e>
ffffffffc020039e:	b7b5                	j	ffffffffc020030a <kmonitor+0x80>
ffffffffc02003a0:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003a4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a6:	d1a5                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003a8:	8526                	mv	a0,s1
ffffffffc02003aa:	3eb010ef          	jal	ra,ffffffffc0201f94 <strchr>
ffffffffc02003ae:	d96d                	beqz	a0,ffffffffc02003a0 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b0:	00044583          	lbu	a1,0(s0)
ffffffffc02003b4:	d9a9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003b6:	bf55                	j	ffffffffc020036a <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b8:	45c1                	li	a1,16
ffffffffc02003ba:	855a                	mv	a0,s6
ffffffffc02003bc:	d1dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02003c0:	b7e9                	j	ffffffffc020038a <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c2:	6582                	ld	a1,0(sp)
ffffffffc02003c4:	00002517          	auipc	a0,0x2
ffffffffc02003c8:	e3c50513          	addi	a0,a0,-452 # ffffffffc0202200 <etext+0x244>
ffffffffc02003cc:	d0dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc02003d0:	b715                	j	ffffffffc02002f4 <kmonitor+0x6a>

ffffffffc02003d2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003d2:	00006317          	auipc	t1,0x6
ffffffffc02003d6:	06e30313          	addi	t1,t1,110 # ffffffffc0206440 <is_panic>
ffffffffc02003da:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003de:	715d                	addi	sp,sp,-80
ffffffffc02003e0:	ec06                	sd	ra,24(sp)
ffffffffc02003e2:	e822                	sd	s0,16(sp)
ffffffffc02003e4:	f436                	sd	a3,40(sp)
ffffffffc02003e6:	f83a                	sd	a4,48(sp)
ffffffffc02003e8:	fc3e                	sd	a5,56(sp)
ffffffffc02003ea:	e0c2                	sd	a6,64(sp)
ffffffffc02003ec:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003ee:	020e1a63          	bnez	t3,ffffffffc0200422 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003f2:	4785                	li	a5,1
ffffffffc02003f4:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003f8:	8432                	mv	s0,a2
ffffffffc02003fa:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003fc:	862e                	mv	a2,a1
ffffffffc02003fe:	85aa                	mv	a1,a0
ffffffffc0200400:	00002517          	auipc	a0,0x2
ffffffffc0200404:	e6050513          	addi	a0,a0,-416 # ffffffffc0202260 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200408:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020040a:	ccfff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020040e:	65a2                	ld	a1,8(sp)
ffffffffc0200410:	8522                	mv	a0,s0
ffffffffc0200412:	ca7ff0ef          	jal	ra,ffffffffc02000b8 <vcprintf>
    cprintf("\n");
ffffffffc0200416:	00002517          	auipc	a0,0x2
ffffffffc020041a:	c9250513          	addi	a0,a0,-878 # ffffffffc02020a8 <etext+0xec>
ffffffffc020041e:	cbbff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200422:	412000ef          	jal	ra,ffffffffc0200834 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200426:	4501                	li	a0,0
ffffffffc0200428:	e63ff0ef          	jal	ra,ffffffffc020028a <kmonitor>
    while (1) {
ffffffffc020042c:	bfed                	j	ffffffffc0200426 <__panic+0x54>

ffffffffc020042e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020042e:	1141                	addi	sp,sp,-16
ffffffffc0200430:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200432:	02000793          	li	a5,32
ffffffffc0200436:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	285010ef          	jal	ra,ffffffffc0201eca <sbi_set_timer>
}
ffffffffc020044a:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020044c:	00006797          	auipc	a5,0x6
ffffffffc0200450:	fe07be23          	sd	zero,-4(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200454:	00002517          	auipc	a0,0x2
ffffffffc0200458:	e2c50513          	addi	a0,a0,-468 # ffffffffc0202280 <commands+0x68>
}
ffffffffc020045c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020045e:	b9ad                	j	ffffffffc02000d8 <cprintf>

ffffffffc0200460 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200460:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	953e                	add	a0,a0,a5
ffffffffc020046c:	25f0106f          	j	ffffffffc0201eca <sbi_set_timer>

ffffffffc0200470 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200470:	8082                	ret

ffffffffc0200472 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200472:	0ff57513          	zext.b	a0,a0
ffffffffc0200476:	23b0106f          	j	ffffffffc0201eb0 <sbi_console_putchar>

ffffffffc020047a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020047a:	26b0106f          	j	ffffffffc0201ee4 <sbi_console_getchar>

ffffffffc020047e <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020047e:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200480:	00002517          	auipc	a0,0x2
ffffffffc0200484:	e2050513          	addi	a0,a0,-480 # ffffffffc02022a0 <commands+0x88>
void dtb_init(void) {
ffffffffc0200488:	fc86                	sd	ra,120(sp)
ffffffffc020048a:	f8a2                	sd	s0,112(sp)
ffffffffc020048c:	e8d2                	sd	s4,80(sp)
ffffffffc020048e:	f4a6                	sd	s1,104(sp)
ffffffffc0200490:	f0ca                	sd	s2,96(sp)
ffffffffc0200492:	ecce                	sd	s3,88(sp)
ffffffffc0200494:	e4d6                	sd	s5,72(sp)
ffffffffc0200496:	e0da                	sd	s6,64(sp)
ffffffffc0200498:	fc5e                	sd	s7,56(sp)
ffffffffc020049a:	f862                	sd	s8,48(sp)
ffffffffc020049c:	f466                	sd	s9,40(sp)
ffffffffc020049e:	f06a                	sd	s10,32(sp)
ffffffffc02004a0:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004a2:	c37ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004a6:	00006597          	auipc	a1,0x6
ffffffffc02004aa:	b5a5b583          	ld	a1,-1190(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc02004ae:	00002517          	auipc	a0,0x2
ffffffffc02004b2:	e0250513          	addi	a0,a0,-510 # ffffffffc02022b0 <commands+0x98>
ffffffffc02004b6:	c23ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004ba:	00006417          	auipc	s0,0x6
ffffffffc02004be:	b4e40413          	addi	s0,s0,-1202 # ffffffffc0206008 <boot_dtb>
ffffffffc02004c2:	600c                	ld	a1,0(s0)
ffffffffc02004c4:	00002517          	auipc	a0,0x2
ffffffffc02004c8:	dfc50513          	addi	a0,a0,-516 # ffffffffc02022c0 <commands+0xa8>
ffffffffc02004cc:	c0dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004d0:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	e0450513          	addi	a0,a0,-508 # ffffffffc02022d8 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02004dc:	120a0463          	beqz	s4,ffffffffc0200604 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004e0:	57f5                	li	a5,-3
ffffffffc02004e2:	07fa                	slli	a5,a5,0x1e
ffffffffc02004e4:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004e8:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ea:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ee:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004f4:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f8:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fc:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200506:	8ec9                	or	a3,a3,a0
ffffffffc0200508:	0087979b          	slliw	a5,a5,0x8
ffffffffc020050c:	1b7d                	addi	s6,s6,-1
ffffffffc020050e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200512:	8dd5                	or	a1,a1,a3
ffffffffc0200514:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200516:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020051c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc0200520:	10f59163          	bne	a1,a5,ffffffffc0200622 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200524:	471c                	lw	a5,8(a4)
ffffffffc0200526:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200528:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020052e:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200532:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053a:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053e:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200542:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200546:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020054a:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020054e:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200552:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200554:	01146433          	or	s0,s0,a7
ffffffffc0200558:	0086969b          	slliw	a3,a3,0x8
ffffffffc020055c:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200560:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200562:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200566:	8c49                	or	s0,s0,a0
ffffffffc0200568:	0166f6b3          	and	a3,a3,s6
ffffffffc020056c:	00ca6a33          	or	s4,s4,a2
ffffffffc0200570:	0167f7b3          	and	a5,a5,s6
ffffffffc0200574:	8c55                	or	s0,s0,a3
ffffffffc0200576:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057a:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020057c:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057e:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200580:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200584:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200586:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200588:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020058c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020058e:	00002917          	auipc	s2,0x2
ffffffffc0200592:	d9a90913          	addi	s2,s2,-614 # ffffffffc0202328 <commands+0x110>
ffffffffc0200596:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200598:	4d91                	li	s11,4
ffffffffc020059a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020059c:	00002497          	auipc	s1,0x2
ffffffffc02005a0:	d8448493          	addi	s1,s1,-636 # ffffffffc0202320 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005a4:	000a2703          	lw	a4,0(s4)
ffffffffc02005a8:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ac:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005b0:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b4:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b8:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005bc:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005c0:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005c6:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005ca:	8fd5                	or	a5,a5,a3
ffffffffc02005cc:	00eb7733          	and	a4,s6,a4
ffffffffc02005d0:	8fd9                	or	a5,a5,a4
ffffffffc02005d2:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005d4:	09778c63          	beq	a5,s7,ffffffffc020066c <dtb_init+0x1ee>
ffffffffc02005d8:	00fbea63          	bltu	s7,a5,ffffffffc02005ec <dtb_init+0x16e>
ffffffffc02005dc:	07a78663          	beq	a5,s10,ffffffffc0200648 <dtb_init+0x1ca>
ffffffffc02005e0:	4709                	li	a4,2
ffffffffc02005e2:	00e79763          	bne	a5,a4,ffffffffc02005f0 <dtb_init+0x172>
ffffffffc02005e6:	4c81                	li	s9,0
ffffffffc02005e8:	8a56                	mv	s4,s5
ffffffffc02005ea:	bf6d                	j	ffffffffc02005a4 <dtb_init+0x126>
ffffffffc02005ec:	ffb78ee3          	beq	a5,s11,ffffffffc02005e8 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005f0:	00002517          	auipc	a0,0x2
ffffffffc02005f4:	db050513          	addi	a0,a0,-592 # ffffffffc02023a0 <commands+0x188>
ffffffffc02005f8:	ae1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005fc:	00002517          	auipc	a0,0x2
ffffffffc0200600:	ddc50513          	addi	a0,a0,-548 # ffffffffc02023d8 <commands+0x1c0>
}
ffffffffc0200604:	7446                	ld	s0,112(sp)
ffffffffc0200606:	70e6                	ld	ra,120(sp)
ffffffffc0200608:	74a6                	ld	s1,104(sp)
ffffffffc020060a:	7906                	ld	s2,96(sp)
ffffffffc020060c:	69e6                	ld	s3,88(sp)
ffffffffc020060e:	6a46                	ld	s4,80(sp)
ffffffffc0200610:	6aa6                	ld	s5,72(sp)
ffffffffc0200612:	6b06                	ld	s6,64(sp)
ffffffffc0200614:	7be2                	ld	s7,56(sp)
ffffffffc0200616:	7c42                	ld	s8,48(sp)
ffffffffc0200618:	7ca2                	ld	s9,40(sp)
ffffffffc020061a:	7d02                	ld	s10,32(sp)
ffffffffc020061c:	6de2                	ld	s11,24(sp)
ffffffffc020061e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200620:	bc65                	j	ffffffffc02000d8 <cprintf>
}
ffffffffc0200622:	7446                	ld	s0,112(sp)
ffffffffc0200624:	70e6                	ld	ra,120(sp)
ffffffffc0200626:	74a6                	ld	s1,104(sp)
ffffffffc0200628:	7906                	ld	s2,96(sp)
ffffffffc020062a:	69e6                	ld	s3,88(sp)
ffffffffc020062c:	6a46                	ld	s4,80(sp)
ffffffffc020062e:	6aa6                	ld	s5,72(sp)
ffffffffc0200630:	6b06                	ld	s6,64(sp)
ffffffffc0200632:	7be2                	ld	s7,56(sp)
ffffffffc0200634:	7c42                	ld	s8,48(sp)
ffffffffc0200636:	7ca2                	ld	s9,40(sp)
ffffffffc0200638:	7d02                	ld	s10,32(sp)
ffffffffc020063a:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	cbc50513          	addi	a0,a0,-836 # ffffffffc02022f8 <commands+0xe0>
}
ffffffffc0200644:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200646:	bc49                	j	ffffffffc02000d8 <cprintf>
                int name_len = strlen(name);
ffffffffc0200648:	8556                	mv	a0,s5
ffffffffc020064a:	0d1010ef          	jal	ra,ffffffffc0201f1a <strlen>
ffffffffc020064e:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200650:	4619                	li	a2,6
ffffffffc0200652:	85a6                	mv	a1,s1
ffffffffc0200654:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200656:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200658:	117010ef          	jal	ra,ffffffffc0201f6e <strncmp>
ffffffffc020065c:	e111                	bnez	a0,ffffffffc0200660 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020065e:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200660:	0a91                	addi	s5,s5,4
ffffffffc0200662:	9ad2                	add	s5,s5,s4
ffffffffc0200664:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200668:	8a56                	mv	s4,s5
ffffffffc020066a:	bf2d                	j	ffffffffc02005a4 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020066c:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200670:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200674:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200678:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067c:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200680:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200684:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200688:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200690:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200694:	00eaeab3          	or	s5,s5,a4
ffffffffc0200698:	00fb77b3          	and	a5,s6,a5
ffffffffc020069c:	00faeab3          	or	s5,s5,a5
ffffffffc02006a0:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006a2:	000c9c63          	bnez	s9,ffffffffc02006ba <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006a6:	1a82                	slli	s5,s5,0x20
ffffffffc02006a8:	00368793          	addi	a5,a3,3
ffffffffc02006ac:	020ada93          	srli	s5,s5,0x20
ffffffffc02006b0:	9abe                	add	s5,s5,a5
ffffffffc02006b2:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006b6:	8a56                	mv	s4,s5
ffffffffc02006b8:	b5f5                	j	ffffffffc02005a4 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ba:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006be:	85ca                	mv	a1,s2
ffffffffc02006c0:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006ce:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d2:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006d6:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d8:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006dc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e0:	8d59                	or	a0,a0,a4
ffffffffc02006e2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006e6:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006e8:	1502                	slli	a0,a0,0x20
ffffffffc02006ea:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ec:	9522                	add	a0,a0,s0
ffffffffc02006ee:	063010ef          	jal	ra,ffffffffc0201f50 <strcmp>
ffffffffc02006f2:	66a2                	ld	a3,8(sp)
ffffffffc02006f4:	f94d                	bnez	a0,ffffffffc02006a6 <dtb_init+0x228>
ffffffffc02006f6:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006a6 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006fa:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006fe:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200702:	00002517          	auipc	a0,0x2
ffffffffc0200706:	c2e50513          	addi	a0,a0,-978 # ffffffffc0202330 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc020070a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200712:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200716:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020071a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0187d693          	srli	a3,a5,0x18
ffffffffc020072a:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020072e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200732:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0106561b          	srliw	a2,a2,0x10
ffffffffc020073a:	010f6f33          	or	t5,t5,a6
ffffffffc020073e:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200742:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200746:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074a:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074e:	0186f6b3          	and	a3,a3,s8
ffffffffc0200752:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200756:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020075e:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200762:	8361                	srli	a4,a4,0x18
ffffffffc0200764:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200768:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020076c:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200770:	00cb7633          	and	a2,s6,a2
ffffffffc0200774:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200778:	0085959b          	slliw	a1,a1,0x8
ffffffffc020077c:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200780:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200784:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200790:	011b78b3          	and	a7,s6,a7
ffffffffc0200794:	005eeeb3          	or	t4,t4,t0
ffffffffc0200798:	00c6e733          	or	a4,a3,a2
ffffffffc020079c:	006c6c33          	or	s8,s8,t1
ffffffffc02007a0:	010b76b3          	and	a3,s6,a6
ffffffffc02007a4:	00bb7b33          	and	s6,s6,a1
ffffffffc02007a8:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007ac:	016c6b33          	or	s6,s8,s6
ffffffffc02007b0:	01146433          	or	s0,s0,a7
ffffffffc02007b4:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007b6:	1702                	slli	a4,a4,0x20
ffffffffc02007b8:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007ba:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007bc:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007be:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007c0:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007c4:	0167eb33          	or	s6,a5,s6
ffffffffc02007c8:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007ca:	90fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007ce:	85a2                	mv	a1,s0
ffffffffc02007d0:	00002517          	auipc	a0,0x2
ffffffffc02007d4:	b8050513          	addi	a0,a0,-1152 # ffffffffc0202350 <commands+0x138>
ffffffffc02007d8:	901ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007dc:	014b5613          	srli	a2,s6,0x14
ffffffffc02007e0:	85da                	mv	a1,s6
ffffffffc02007e2:	00002517          	auipc	a0,0x2
ffffffffc02007e6:	b8650513          	addi	a0,a0,-1146 # ffffffffc0202368 <commands+0x150>
ffffffffc02007ea:	8efff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007ee:	008b05b3          	add	a1,s6,s0
ffffffffc02007f2:	15fd                	addi	a1,a1,-1
ffffffffc02007f4:	00002517          	auipc	a0,0x2
ffffffffc02007f8:	b9450513          	addi	a0,a0,-1132 # ffffffffc0202388 <commands+0x170>
ffffffffc02007fc:	8ddff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200800:	00002517          	auipc	a0,0x2
ffffffffc0200804:	bd850513          	addi	a0,a0,-1064 # ffffffffc02023d8 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200808:	00006797          	auipc	a5,0x6
ffffffffc020080c:	c487b423          	sd	s0,-952(a5) # ffffffffc0206450 <memory_base>
        memory_size = mem_size;
ffffffffc0200810:	00006797          	auipc	a5,0x6
ffffffffc0200814:	c567b423          	sd	s6,-952(a5) # ffffffffc0206458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200818:	b3f5                	j	ffffffffc0200604 <dtb_init+0x186>

ffffffffc020081a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020081a:	00006517          	auipc	a0,0x6
ffffffffc020081e:	c3653503          	ld	a0,-970(a0) # ffffffffc0206450 <memory_base>
ffffffffc0200822:	8082                	ret

ffffffffc0200824 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200824:	00006517          	auipc	a0,0x6
ffffffffc0200828:	c3453503          	ld	a0,-972(a0) # ffffffffc0206458 <memory_size>
ffffffffc020082c:	8082                	ret

ffffffffc020082e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020082e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200832:	8082                	ret

ffffffffc0200834 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200834:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200838:	8082                	ret

ffffffffc020083a <idt_init>:
}

/* 初始化 IDT 和异常向量 */
void idt_init(void) {
    extern void __alltraps(void);
    write_csr(sscratch, 0);        // 内核模式标记
ffffffffc020083a:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc020083e:	00000797          	auipc	a5,0x0
ffffffffc0200842:	3aa78793          	addi	a5,a5,938 # ffffffffc0200be8 <__alltraps>
ffffffffc0200846:	10579073          	csrw	stvec,a5
}
ffffffffc020084a:	8082                	ret

ffffffffc020084c <print_regs>:
    cprintf("  cause    0x%08lx\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    #define PRINT_REG(r) cprintf("  " #r "  0x%08lx\n", gpr->r)
    PRINT_REG(zero); PRINT_REG(ra); PRINT_REG(sp); PRINT_REG(gp); PRINT_REG(tp);
ffffffffc020084c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020084e:	1141                	addi	sp,sp,-16
ffffffffc0200850:	e022                	sd	s0,0(sp)
ffffffffc0200852:	842a                	mv	s0,a0
    PRINT_REG(zero); PRINT_REG(ra); PRINT_REG(sp); PRINT_REG(gp); PRINT_REG(tp);
ffffffffc0200854:	00002517          	auipc	a0,0x2
ffffffffc0200858:	b9c50513          	addi	a0,a0,-1124 # ffffffffc02023f0 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc020085c:	e406                	sd	ra,8(sp)
    PRINT_REG(zero); PRINT_REG(ra); PRINT_REG(sp); PRINT_REG(gp); PRINT_REG(tp);
ffffffffc020085e:	87bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200862:	640c                	ld	a1,8(s0)
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	ba450513          	addi	a0,a0,-1116 # ffffffffc0202408 <commands+0x1f0>
ffffffffc020086c:	86dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200870:	680c                	ld	a1,16(s0)
ffffffffc0200872:	00002517          	auipc	a0,0x2
ffffffffc0200876:	ba650513          	addi	a0,a0,-1114 # ffffffffc0202418 <commands+0x200>
ffffffffc020087a:	85fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020087e:	6c0c                	ld	a1,24(s0)
ffffffffc0200880:	00002517          	auipc	a0,0x2
ffffffffc0200884:	ba850513          	addi	a0,a0,-1112 # ffffffffc0202428 <commands+0x210>
ffffffffc0200888:	851ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020088c:	700c                	ld	a1,32(s0)
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	baa50513          	addi	a0,a0,-1110 # ffffffffc0202438 <commands+0x220>
ffffffffc0200896:	843ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    PRINT_REG(t0); PRINT_REG(t1); PRINT_REG(t2); PRINT_REG(s0); PRINT_REG(s1);
ffffffffc020089a:	740c                	ld	a1,40(s0)
ffffffffc020089c:	00002517          	auipc	a0,0x2
ffffffffc02008a0:	bac50513          	addi	a0,a0,-1108 # ffffffffc0202448 <commands+0x230>
ffffffffc02008a4:	835ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02008a8:	780c                	ld	a1,48(s0)
ffffffffc02008aa:	00002517          	auipc	a0,0x2
ffffffffc02008ae:	bae50513          	addi	a0,a0,-1106 # ffffffffc0202458 <commands+0x240>
ffffffffc02008b2:	827ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02008b6:	7c0c                	ld	a1,56(s0)
ffffffffc02008b8:	00002517          	auipc	a0,0x2
ffffffffc02008bc:	bb050513          	addi	a0,a0,-1104 # ffffffffc0202468 <commands+0x250>
ffffffffc02008c0:	819ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02008c4:	602c                	ld	a1,64(s0)
ffffffffc02008c6:	00002517          	auipc	a0,0x2
ffffffffc02008ca:	bb250513          	addi	a0,a0,-1102 # ffffffffc0202478 <commands+0x260>
ffffffffc02008ce:	80bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02008d2:	642c                	ld	a1,72(s0)
ffffffffc02008d4:	00002517          	auipc	a0,0x2
ffffffffc02008d8:	bb450513          	addi	a0,a0,-1100 # ffffffffc0202488 <commands+0x270>
ffffffffc02008dc:	ffcff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    PRINT_REG(a0); PRINT_REG(a1); PRINT_REG(a2); PRINT_REG(a3); PRINT_REG(a4);
ffffffffc02008e0:	682c                	ld	a1,80(s0)
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	bb650513          	addi	a0,a0,-1098 # ffffffffc0202498 <commands+0x280>
ffffffffc02008ea:	feeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02008ee:	6c2c                	ld	a1,88(s0)
ffffffffc02008f0:	00002517          	auipc	a0,0x2
ffffffffc02008f4:	bb850513          	addi	a0,a0,-1096 # ffffffffc02024a8 <commands+0x290>
ffffffffc02008f8:	fe0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02008fc:	702c                	ld	a1,96(s0)
ffffffffc02008fe:	00002517          	auipc	a0,0x2
ffffffffc0200902:	bba50513          	addi	a0,a0,-1094 # ffffffffc02024b8 <commands+0x2a0>
ffffffffc0200906:	fd2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020090a:	742c                	ld	a1,104(s0)
ffffffffc020090c:	00002517          	auipc	a0,0x2
ffffffffc0200910:	bbc50513          	addi	a0,a0,-1092 # ffffffffc02024c8 <commands+0x2b0>
ffffffffc0200914:	fc4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200918:	782c                	ld	a1,112(s0)
ffffffffc020091a:	00002517          	auipc	a0,0x2
ffffffffc020091e:	bbe50513          	addi	a0,a0,-1090 # ffffffffc02024d8 <commands+0x2c0>
ffffffffc0200922:	fb6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    PRINT_REG(a5); PRINT_REG(a6); PRINT_REG(a7);
ffffffffc0200926:	7c2c                	ld	a1,120(s0)
ffffffffc0200928:	00002517          	auipc	a0,0x2
ffffffffc020092c:	bc050513          	addi	a0,a0,-1088 # ffffffffc02024e8 <commands+0x2d0>
ffffffffc0200930:	fa8ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200934:	604c                	ld	a1,128(s0)
ffffffffc0200936:	00002517          	auipc	a0,0x2
ffffffffc020093a:	bc250513          	addi	a0,a0,-1086 # ffffffffc02024f8 <commands+0x2e0>
ffffffffc020093e:	f9aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200942:	644c                	ld	a1,136(s0)
ffffffffc0200944:	00002517          	auipc	a0,0x2
ffffffffc0200948:	bc450513          	addi	a0,a0,-1084 # ffffffffc0202508 <commands+0x2f0>
ffffffffc020094c:	f8cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    PRINT_REG(s2); PRINT_REG(s3); PRINT_REG(s4); PRINT_REG(s5); PRINT_REG(s6);
ffffffffc0200950:	684c                	ld	a1,144(s0)
ffffffffc0200952:	00002517          	auipc	a0,0x2
ffffffffc0200956:	bc650513          	addi	a0,a0,-1082 # ffffffffc0202518 <commands+0x300>
ffffffffc020095a:	f7eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020095e:	6c4c                	ld	a1,152(s0)
ffffffffc0200960:	00002517          	auipc	a0,0x2
ffffffffc0200964:	bc850513          	addi	a0,a0,-1080 # ffffffffc0202528 <commands+0x310>
ffffffffc0200968:	f70ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020096c:	704c                	ld	a1,160(s0)
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	bca50513          	addi	a0,a0,-1078 # ffffffffc0202538 <commands+0x320>
ffffffffc0200976:	f62ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020097a:	744c                	ld	a1,168(s0)
ffffffffc020097c:	00002517          	auipc	a0,0x2
ffffffffc0200980:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0202548 <commands+0x330>
ffffffffc0200984:	f54ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200988:	784c                	ld	a1,176(s0)
ffffffffc020098a:	00002517          	auipc	a0,0x2
ffffffffc020098e:	bce50513          	addi	a0,a0,-1074 # ffffffffc0202558 <commands+0x340>
ffffffffc0200992:	f46ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    PRINT_REG(s7); PRINT_REG(s8); PRINT_REG(s9); PRINT_REG(s10); PRINT_REG(s11);
ffffffffc0200996:	7c4c                	ld	a1,184(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	bd050513          	addi	a0,a0,-1072 # ffffffffc0202568 <commands+0x350>
ffffffffc02009a0:	f38ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02009a4:	606c                	ld	a1,192(s0)
ffffffffc02009a6:	00002517          	auipc	a0,0x2
ffffffffc02009aa:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202578 <commands+0x360>
ffffffffc02009ae:	f2aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02009b2:	646c                	ld	a1,200(s0)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	bd450513          	addi	a0,a0,-1068 # ffffffffc0202588 <commands+0x370>
ffffffffc02009bc:	f1cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02009c0:	686c                	ld	a1,208(s0)
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	bd650513          	addi	a0,a0,-1066 # ffffffffc0202598 <commands+0x380>
ffffffffc02009ca:	f0eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02009ce:	6c6c                	ld	a1,216(s0)
ffffffffc02009d0:	00002517          	auipc	a0,0x2
ffffffffc02009d4:	bd850513          	addi	a0,a0,-1064 # ffffffffc02025a8 <commands+0x390>
ffffffffc02009d8:	f00ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    PRINT_REG(t3); PRINT_REG(t4); PRINT_REG(t5); PRINT_REG(t6);
ffffffffc02009dc:	706c                	ld	a1,224(s0)
ffffffffc02009de:	00002517          	auipc	a0,0x2
ffffffffc02009e2:	bda50513          	addi	a0,a0,-1062 # ffffffffc02025b8 <commands+0x3a0>
ffffffffc02009e6:	ef2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02009ea:	746c                	ld	a1,232(s0)
ffffffffc02009ec:	00002517          	auipc	a0,0x2
ffffffffc02009f0:	bdc50513          	addi	a0,a0,-1060 # ffffffffc02025c8 <commands+0x3b0>
ffffffffc02009f4:	ee4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02009f8:	786c                	ld	a1,240(s0)
ffffffffc02009fa:	00002517          	auipc	a0,0x2
ffffffffc02009fe:	bde50513          	addi	a0,a0,-1058 # ffffffffc02025d8 <commands+0x3c0>
ffffffffc0200a02:	ed6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200a06:	7c6c                	ld	a1,248(s0)
    #undef PRINT_REG
}
ffffffffc0200a08:	6402                	ld	s0,0(sp)
ffffffffc0200a0a:	60a2                	ld	ra,8(sp)
    PRINT_REG(t3); PRINT_REG(t4); PRINT_REG(t5); PRINT_REG(t6);
ffffffffc0200a0c:	00002517          	auipc	a0,0x2
ffffffffc0200a10:	bdc50513          	addi	a0,a0,-1060 # ffffffffc02025e8 <commands+0x3d0>
}
ffffffffc0200a14:	0141                	addi	sp,sp,16
    PRINT_REG(t3); PRINT_REG(t4); PRINT_REG(t5); PRINT_REG(t6);
ffffffffc0200a16:	ec2ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a1a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a1a:	1141                	addi	sp,sp,-16
ffffffffc0200a1c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a1e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a20:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	bd650513          	addi	a0,a0,-1066 # ffffffffc02025f8 <commands+0x3e0>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a2a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2c:	eacff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a30:	8522                	mv	a0,s0
ffffffffc0200a32:	e1bff0ef          	jal	ra,ffffffffc020084c <print_regs>
    cprintf("  status   0x%08lx\n", tf->status);
ffffffffc0200a36:	10043583          	ld	a1,256(s0)
ffffffffc0200a3a:	00002517          	auipc	a0,0x2
ffffffffc0200a3e:	bd650513          	addi	a0,a0,-1066 # ffffffffc0202610 <commands+0x3f8>
ffffffffc0200a42:	e96ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08lx\n", tf->epc);
ffffffffc0200a46:	10843583          	ld	a1,264(s0)
ffffffffc0200a4a:	00002517          	auipc	a0,0x2
ffffffffc0200a4e:	bde50513          	addi	a0,a0,-1058 # ffffffffc0202628 <commands+0x410>
ffffffffc0200a52:	e86ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08lx\n", tf->badvaddr);
ffffffffc0200a56:	11043583          	ld	a1,272(s0)
ffffffffc0200a5a:	00002517          	auipc	a0,0x2
ffffffffc0200a5e:	be650513          	addi	a0,a0,-1050 # ffffffffc0202640 <commands+0x428>
ffffffffc0200a62:	e76ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08lx\n", tf->cause);
ffffffffc0200a66:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a6a:	6402                	ld	s0,0(sp)
ffffffffc0200a6c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08lx\n", tf->cause);
ffffffffc0200a6e:	00002517          	auipc	a0,0x2
ffffffffc0200a72:	bea50513          	addi	a0,a0,-1046 # ffffffffc0202658 <commands+0x440>
}
ffffffffc0200a76:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08lx\n", tf->cause);
ffffffffc0200a78:	e60ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a7c <interrupt_handler>:

/* 中断处理 */
void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1; // 清除最高位
ffffffffc0200a7c:	11853783          	ld	a5,280(a0)
ffffffffc0200a80:	472d                	li	a4,11
ffffffffc0200a82:	0786                	slli	a5,a5,0x1
ffffffffc0200a84:	8385                	srli	a5,a5,0x1
ffffffffc0200a86:	0cf76063          	bltu	a4,a5,ffffffffc0200b46 <interrupt_handler+0xca>
ffffffffc0200a8a:	00002717          	auipc	a4,0x2
ffffffffc0200a8e:	d4a70713          	addi	a4,a4,-694 # ffffffffc02027d4 <commands+0x5bc>
ffffffffc0200a92:	078a                	slli	a5,a5,0x2
ffffffffc0200a94:	97ba                	add	a5,a5,a4
ffffffffc0200a96:	439c                	lw	a5,0(a5)
ffffffffc0200a98:	97ba                	add	a5,a5,a4
ffffffffc0200a9a:	8782                	jr	a5
        case IRQ_U_TIMER: cprintf("User timer interrupt\n"); break;
        case IRQ_H_TIMER: cprintf("Hypervisor timer interrupt\n"); break;
        case IRQ_M_TIMER: cprintf("Machine timer interrupt\n"); break;
        case IRQ_U_EXT: cprintf("User external interrupt\n"); break;
        case IRQ_S_EXT: cprintf("Supervisor external interrupt\n"); break;
        case IRQ_H_EXT: cprintf("Hypervisor external interrupt\n"); break;
ffffffffc0200a9c:	00002517          	auipc	a0,0x2
ffffffffc0200aa0:	cfc50513          	addi	a0,a0,-772 # ffffffffc0202798 <commands+0x580>
ffffffffc0200aa4:	e34ff06f          	j	ffffffffc02000d8 <cprintf>
        case IRQ_M_EXT: cprintf("Machine external interrupt\n"); break;
ffffffffc0200aa8:	00002517          	auipc	a0,0x2
ffffffffc0200aac:	d1050513          	addi	a0,a0,-752 # ffffffffc02027b8 <commands+0x5a0>
ffffffffc0200ab0:	e28ff06f          	j	ffffffffc02000d8 <cprintf>
        case IRQ_U_SOFT: cprintf("User software interrupt\n"); break;
ffffffffc0200ab4:	00002517          	auipc	a0,0x2
ffffffffc0200ab8:	bcc50513          	addi	a0,a0,-1076 # ffffffffc0202680 <commands+0x468>
ffffffffc0200abc:	e1cff06f          	j	ffffffffc02000d8 <cprintf>
        case IRQ_S_SOFT: cprintf("Supervisor software interrupt\n"); break;
ffffffffc0200ac0:	00002517          	auipc	a0,0x2
ffffffffc0200ac4:	be050513          	addi	a0,a0,-1056 # ffffffffc02026a0 <commands+0x488>
ffffffffc0200ac8:	e10ff06f          	j	ffffffffc02000d8 <cprintf>
        case IRQ_H_SOFT: cprintf("Hypervisor software interrupt\n"); break;
ffffffffc0200acc:	00002517          	auipc	a0,0x2
ffffffffc0200ad0:	bf450513          	addi	a0,a0,-1036 # ffffffffc02026c0 <commands+0x4a8>
ffffffffc0200ad4:	e04ff06f          	j	ffffffffc02000d8 <cprintf>
        case IRQ_M_SOFT: cprintf("Machine software interrupt\n"); break;
ffffffffc0200ad8:	00002517          	auipc	a0,0x2
ffffffffc0200adc:	c0850513          	addi	a0,a0,-1016 # ffffffffc02026e0 <commands+0x4c8>
ffffffffc0200ae0:	df8ff06f          	j	ffffffffc02000d8 <cprintf>
        case IRQ_U_TIMER: cprintf("User timer interrupt\n"); break;
ffffffffc0200ae4:	00002517          	auipc	a0,0x2
ffffffffc0200ae8:	c1c50513          	addi	a0,a0,-996 # ffffffffc0202700 <commands+0x4e8>
ffffffffc0200aec:	decff06f          	j	ffffffffc02000d8 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200af0:	1141                	addi	sp,sp,-16
ffffffffc0200af2:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc0200af4:	96dff0ef          	jal	ra,ffffffffc0200460 <clock_set_next_event>
            timer_ticks++;
ffffffffc0200af8:	00006717          	auipc	a4,0x6
ffffffffc0200afc:	96c70713          	addi	a4,a4,-1684 # ffffffffc0206464 <timer_ticks>
ffffffffc0200b00:	431c                	lw	a5,0(a4)
            if (timer_ticks >= TICK_NUM) {
ffffffffc0200b02:	06300693          	li	a3,99
            timer_ticks++;
ffffffffc0200b06:	0017861b          	addiw	a2,a5,1
            if (timer_ticks >= TICK_NUM) {
ffffffffc0200b0a:	02c6cf63          	blt	a3,a2,ffffffffc0200b48 <interrupt_handler+0xcc>
            timer_ticks++;
ffffffffc0200b0e:	c310                	sw	a2,0(a4)

        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b10:	60a2                	ld	ra,8(sp)
ffffffffc0200b12:	0141                	addi	sp,sp,16
ffffffffc0200b14:	8082                	ret
        case IRQ_H_TIMER: cprintf("Hypervisor timer interrupt\n"); break;
ffffffffc0200b16:	00002517          	auipc	a0,0x2
ffffffffc0200b1a:	c0250513          	addi	a0,a0,-1022 # ffffffffc0202718 <commands+0x500>
ffffffffc0200b1e:	dbaff06f          	j	ffffffffc02000d8 <cprintf>
        case IRQ_M_TIMER: cprintf("Machine timer interrupt\n"); break;
ffffffffc0200b22:	00002517          	auipc	a0,0x2
ffffffffc0200b26:	c1650513          	addi	a0,a0,-1002 # ffffffffc0202738 <commands+0x520>
ffffffffc0200b2a:	daeff06f          	j	ffffffffc02000d8 <cprintf>
        case IRQ_U_EXT: cprintf("User external interrupt\n"); break;
ffffffffc0200b2e:	00002517          	auipc	a0,0x2
ffffffffc0200b32:	c2a50513          	addi	a0,a0,-982 # ffffffffc0202758 <commands+0x540>
ffffffffc0200b36:	da2ff06f          	j	ffffffffc02000d8 <cprintf>
        case IRQ_S_EXT: cprintf("Supervisor external interrupt\n"); break;
ffffffffc0200b3a:	00002517          	auipc	a0,0x2
ffffffffc0200b3e:	c3e50513          	addi	a0,a0,-962 # ffffffffc0202778 <commands+0x560>
ffffffffc0200b42:	d96ff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200b46:	bdd1                	j	ffffffffc0200a1a <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b48:	06400593          	li	a1,100
ffffffffc0200b4c:	00002517          	auipc	a0,0x2
ffffffffc0200b50:	b2450513          	addi	a0,a0,-1244 # ffffffffc0202670 <commands+0x458>
                timer_ticks = 0;
ffffffffc0200b54:	00006797          	auipc	a5,0x6
ffffffffc0200b58:	9007a823          	sw	zero,-1776(a5) # ffffffffc0206464 <timer_ticks>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b5c:	d7cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
                timer_prints++;
ffffffffc0200b60:	00006717          	auipc	a4,0x6
ffffffffc0200b64:	90070713          	addi	a4,a4,-1792 # ffffffffc0206460 <timer_prints>
ffffffffc0200b68:	431c                	lw	a5,0(a4)
                if (timer_prints >= MAX_PRINTS) {
ffffffffc0200b6a:	46a5                	li	a3,9
                timer_prints++;
ffffffffc0200b6c:	0017861b          	addiw	a2,a5,1
ffffffffc0200b70:	c310                	sw	a2,0(a4)
                if (timer_prints >= MAX_PRINTS) {
ffffffffc0200b72:	f8c6dfe3          	bge	a3,a2,ffffffffc0200b10 <interrupt_handler+0x94>
                    sbi_shutdown();
ffffffffc0200b76:	38a010ef          	jal	ra,ffffffffc0201f00 <sbi_shutdown>
                    while (1); // 防止返回
ffffffffc0200b7a:	a001                	j	ffffffffc0200b7a <interrupt_handler+0xfe>

ffffffffc0200b7c <trap>:
    }
}

/* 分发 trap */
static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0)
ffffffffc0200b7c:	11853783          	ld	a5,280(a0)
ffffffffc0200b80:	0207cd63          	bltz	a5,ffffffffc0200bba <trap+0x3e>
    else
        exception_handler(tf);
}

/* trap 入口 */
void trap(struct trapframe *tf) {
ffffffffc0200b84:	1141                	addi	sp,sp,-16
ffffffffc0200b86:	e022                	sd	s0,0(sp)
ffffffffc0200b88:	e406                	sd	ra,8(sp)
    switch (tf->cause) {
ffffffffc0200b8a:	4709                	li	a4,2
ffffffffc0200b8c:	842a                	mv	s0,a0
ffffffffc0200b8e:	02e78b63          	beq	a5,a4,ffffffffc0200bc4 <trap+0x48>
ffffffffc0200b92:	470d                	li	a4,3
ffffffffc0200b94:	02e79463          	bne	a5,a4,ffffffffc0200bbc <trap+0x40>
            cprintf("Breakpoint at 0x%08lx\n", tf->epc);
ffffffffc0200b98:	10853583          	ld	a1,264(a0)
ffffffffc0200b9c:	00002517          	auipc	a0,0x2
ffffffffc0200ba0:	c8c50513          	addi	a0,a0,-884 # ffffffffc0202828 <commands+0x610>
ffffffffc0200ba4:	d34ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
            tf->epc += 4; // 跳过断点
ffffffffc0200ba8:	10843783          	ld	a5,264(s0)
    trap_dispatch(tf);
}
ffffffffc0200bac:	60a2                	ld	ra,8(sp)
            tf->epc += 4; // 跳过断点
ffffffffc0200bae:	0791                	addi	a5,a5,4
ffffffffc0200bb0:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200bb4:	6402                	ld	s0,0(sp)
ffffffffc0200bb6:	0141                	addi	sp,sp,16
ffffffffc0200bb8:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200bba:	b5c9                	j	ffffffffc0200a7c <interrupt_handler>
}
ffffffffc0200bbc:	6402                	ld	s0,0(sp)
ffffffffc0200bbe:	60a2                	ld	ra,8(sp)
ffffffffc0200bc0:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200bc2:	bda1                	j	ffffffffc0200a1a <print_trapframe>
            cprintf("Illegal instruction at 0x%08lx\n", tf->epc);
ffffffffc0200bc4:	10853583          	ld	a1,264(a0)
ffffffffc0200bc8:	00002517          	auipc	a0,0x2
ffffffffc0200bcc:	c4050513          	addi	a0,a0,-960 # ffffffffc0202808 <commands+0x5f0>
ffffffffc0200bd0:	d08ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
            tf->epc += 4; // 跳过非法指令
ffffffffc0200bd4:	10843783          	ld	a5,264(s0)
}
ffffffffc0200bd8:	60a2                	ld	ra,8(sp)
            tf->epc += 4; // 跳过非法指令
ffffffffc0200bda:	0791                	addi	a5,a5,4
ffffffffc0200bdc:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200be0:	6402                	ld	s0,0(sp)
ffffffffc0200be2:	0141                	addi	sp,sp,16
ffffffffc0200be4:	8082                	ret
	...

ffffffffc0200be8 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200be8:	14011073          	csrw	sscratch,sp
ffffffffc0200bec:	712d                	addi	sp,sp,-288
ffffffffc0200bee:	e002                	sd	zero,0(sp)
ffffffffc0200bf0:	e406                	sd	ra,8(sp)
ffffffffc0200bf2:	ec0e                	sd	gp,24(sp)
ffffffffc0200bf4:	f012                	sd	tp,32(sp)
ffffffffc0200bf6:	f416                	sd	t0,40(sp)
ffffffffc0200bf8:	f81a                	sd	t1,48(sp)
ffffffffc0200bfa:	fc1e                	sd	t2,56(sp)
ffffffffc0200bfc:	e0a2                	sd	s0,64(sp)
ffffffffc0200bfe:	e4a6                	sd	s1,72(sp)
ffffffffc0200c00:	e8aa                	sd	a0,80(sp)
ffffffffc0200c02:	ecae                	sd	a1,88(sp)
ffffffffc0200c04:	f0b2                	sd	a2,96(sp)
ffffffffc0200c06:	f4b6                	sd	a3,104(sp)
ffffffffc0200c08:	f8ba                	sd	a4,112(sp)
ffffffffc0200c0a:	fcbe                	sd	a5,120(sp)
ffffffffc0200c0c:	e142                	sd	a6,128(sp)
ffffffffc0200c0e:	e546                	sd	a7,136(sp)
ffffffffc0200c10:	e94a                	sd	s2,144(sp)
ffffffffc0200c12:	ed4e                	sd	s3,152(sp)
ffffffffc0200c14:	f152                	sd	s4,160(sp)
ffffffffc0200c16:	f556                	sd	s5,168(sp)
ffffffffc0200c18:	f95a                	sd	s6,176(sp)
ffffffffc0200c1a:	fd5e                	sd	s7,184(sp)
ffffffffc0200c1c:	e1e2                	sd	s8,192(sp)
ffffffffc0200c1e:	e5e6                	sd	s9,200(sp)
ffffffffc0200c20:	e9ea                	sd	s10,208(sp)
ffffffffc0200c22:	edee                	sd	s11,216(sp)
ffffffffc0200c24:	f1f2                	sd	t3,224(sp)
ffffffffc0200c26:	f5f6                	sd	t4,232(sp)
ffffffffc0200c28:	f9fa                	sd	t5,240(sp)
ffffffffc0200c2a:	fdfe                	sd	t6,248(sp)
ffffffffc0200c2c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c30:	100024f3          	csrr	s1,sstatus
ffffffffc0200c34:	14102973          	csrr	s2,sepc
ffffffffc0200c38:	143029f3          	csrr	s3,stval
ffffffffc0200c3c:	14202a73          	csrr	s4,scause
ffffffffc0200c40:	e822                	sd	s0,16(sp)
ffffffffc0200c42:	e226                	sd	s1,256(sp)
ffffffffc0200c44:	e64a                	sd	s2,264(sp)
ffffffffc0200c46:	ea4e                	sd	s3,272(sp)
ffffffffc0200c48:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c4a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c4c:	f31ff0ef          	jal	ra,ffffffffc0200b7c <trap>

ffffffffc0200c50 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c50:	6492                	ld	s1,256(sp)
ffffffffc0200c52:	6932                	ld	s2,264(sp)
ffffffffc0200c54:	10049073          	csrw	sstatus,s1
ffffffffc0200c58:	14191073          	csrw	sepc,s2
ffffffffc0200c5c:	60a2                	ld	ra,8(sp)
ffffffffc0200c5e:	61e2                	ld	gp,24(sp)
ffffffffc0200c60:	7202                	ld	tp,32(sp)
ffffffffc0200c62:	72a2                	ld	t0,40(sp)
ffffffffc0200c64:	7342                	ld	t1,48(sp)
ffffffffc0200c66:	73e2                	ld	t2,56(sp)
ffffffffc0200c68:	6406                	ld	s0,64(sp)
ffffffffc0200c6a:	64a6                	ld	s1,72(sp)
ffffffffc0200c6c:	6546                	ld	a0,80(sp)
ffffffffc0200c6e:	65e6                	ld	a1,88(sp)
ffffffffc0200c70:	7606                	ld	a2,96(sp)
ffffffffc0200c72:	76a6                	ld	a3,104(sp)
ffffffffc0200c74:	7746                	ld	a4,112(sp)
ffffffffc0200c76:	77e6                	ld	a5,120(sp)
ffffffffc0200c78:	680a                	ld	a6,128(sp)
ffffffffc0200c7a:	68aa                	ld	a7,136(sp)
ffffffffc0200c7c:	694a                	ld	s2,144(sp)
ffffffffc0200c7e:	69ea                	ld	s3,152(sp)
ffffffffc0200c80:	7a0a                	ld	s4,160(sp)
ffffffffc0200c82:	7aaa                	ld	s5,168(sp)
ffffffffc0200c84:	7b4a                	ld	s6,176(sp)
ffffffffc0200c86:	7bea                	ld	s7,184(sp)
ffffffffc0200c88:	6c0e                	ld	s8,192(sp)
ffffffffc0200c8a:	6cae                	ld	s9,200(sp)
ffffffffc0200c8c:	6d4e                	ld	s10,208(sp)
ffffffffc0200c8e:	6dee                	ld	s11,216(sp)
ffffffffc0200c90:	7e0e                	ld	t3,224(sp)
ffffffffc0200c92:	7eae                	ld	t4,232(sp)
ffffffffc0200c94:	7f4e                	ld	t5,240(sp)
ffffffffc0200c96:	7fee                	ld	t6,248(sp)
ffffffffc0200c98:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c9a:	10200073          	sret

ffffffffc0200c9e <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c9e:	00005797          	auipc	a5,0x5
ffffffffc0200ca2:	38a78793          	addi	a5,a5,906 # ffffffffc0206028 <free_area>
ffffffffc0200ca6:	e79c                	sd	a5,8(a5)
ffffffffc0200ca8:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200caa:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200cae:	8082                	ret

ffffffffc0200cb0 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200cb0:	00005517          	auipc	a0,0x5
ffffffffc0200cb4:	38856503          	lwu	a0,904(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200cb8:	8082                	ret

ffffffffc0200cba <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200cba:	715d                	addi	sp,sp,-80
ffffffffc0200cbc:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200cbe:	00005417          	auipc	s0,0x5
ffffffffc0200cc2:	36a40413          	addi	s0,s0,874 # ffffffffc0206028 <free_area>
ffffffffc0200cc6:	641c                	ld	a5,8(s0)
ffffffffc0200cc8:	e486                	sd	ra,72(sp)
ffffffffc0200cca:	fc26                	sd	s1,56(sp)
ffffffffc0200ccc:	f84a                	sd	s2,48(sp)
ffffffffc0200cce:	f44e                	sd	s3,40(sp)
ffffffffc0200cd0:	f052                	sd	s4,32(sp)
ffffffffc0200cd2:	ec56                	sd	s5,24(sp)
ffffffffc0200cd4:	e85a                	sd	s6,16(sp)
ffffffffc0200cd6:	e45e                	sd	s7,8(sp)
ffffffffc0200cd8:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cda:	2c878763          	beq	a5,s0,ffffffffc0200fa8 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0200cde:	4481                	li	s1,0
ffffffffc0200ce0:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200ce2:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ce6:	8b09                	andi	a4,a4,2
ffffffffc0200ce8:	2c070463          	beqz	a4,ffffffffc0200fb0 <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0200cec:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200cf0:	679c                	ld	a5,8(a5)
ffffffffc0200cf2:	2905                	addiw	s2,s2,1
ffffffffc0200cf4:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cf6:	fe8796e3          	bne	a5,s0,ffffffffc0200ce2 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200cfa:	89a6                	mv	s3,s1
ffffffffc0200cfc:	2f9000ef          	jal	ra,ffffffffc02017f4 <nr_free_pages>
ffffffffc0200d00:	71351863          	bne	a0,s3,ffffffffc0201410 <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d04:	4505                	li	a0,1
ffffffffc0200d06:	271000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200d0a:	8a2a                	mv	s4,a0
ffffffffc0200d0c:	44050263          	beqz	a0,ffffffffc0201150 <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d10:	4505                	li	a0,1
ffffffffc0200d12:	265000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200d16:	89aa                	mv	s3,a0
ffffffffc0200d18:	70050c63          	beqz	a0,ffffffffc0201430 <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d1c:	4505                	li	a0,1
ffffffffc0200d1e:	259000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200d22:	8aaa                	mv	s5,a0
ffffffffc0200d24:	4a050663          	beqz	a0,ffffffffc02011d0 <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d28:	2b3a0463          	beq	s4,s3,ffffffffc0200fd0 <default_check+0x316>
ffffffffc0200d2c:	2aaa0263          	beq	s4,a0,ffffffffc0200fd0 <default_check+0x316>
ffffffffc0200d30:	2aa98063          	beq	s3,a0,ffffffffc0200fd0 <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d34:	000a2783          	lw	a5,0(s4)
ffffffffc0200d38:	2a079c63          	bnez	a5,ffffffffc0200ff0 <default_check+0x336>
ffffffffc0200d3c:	0009a783          	lw	a5,0(s3)
ffffffffc0200d40:	2a079863          	bnez	a5,ffffffffc0200ff0 <default_check+0x336>
ffffffffc0200d44:	411c                	lw	a5,0(a0)
ffffffffc0200d46:	2a079563          	bnez	a5,ffffffffc0200ff0 <default_check+0x336>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d4a:	00005797          	auipc	a5,0x5
ffffffffc0200d4e:	7267b783          	ld	a5,1830(a5) # ffffffffc0206470 <pages>
ffffffffc0200d52:	40fa0733          	sub	a4,s4,a5
ffffffffc0200d56:	870d                	srai	a4,a4,0x3
ffffffffc0200d58:	00002597          	auipc	a1,0x2
ffffffffc0200d5c:	2705b583          	ld	a1,624(a1) # ffffffffc0202fc8 <error_string+0x38>
ffffffffc0200d60:	02b70733          	mul	a4,a4,a1
ffffffffc0200d64:	00002617          	auipc	a2,0x2
ffffffffc0200d68:	26c63603          	ld	a2,620(a2) # ffffffffc0202fd0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200d6c:	00005697          	auipc	a3,0x5
ffffffffc0200d70:	6fc6b683          	ld	a3,1788(a3) # ffffffffc0206468 <npage>
ffffffffc0200d74:	06b2                	slli	a3,a3,0xc
ffffffffc0200d76:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d78:	0732                	slli	a4,a4,0xc
ffffffffc0200d7a:	28d77b63          	bgeu	a4,a3,ffffffffc0201010 <default_check+0x356>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d7e:	40f98733          	sub	a4,s3,a5
ffffffffc0200d82:	870d                	srai	a4,a4,0x3
ffffffffc0200d84:	02b70733          	mul	a4,a4,a1
ffffffffc0200d88:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d8a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d8c:	4cd77263          	bgeu	a4,a3,ffffffffc0201250 <default_check+0x596>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d90:	40f507b3          	sub	a5,a0,a5
ffffffffc0200d94:	878d                	srai	a5,a5,0x3
ffffffffc0200d96:	02b787b3          	mul	a5,a5,a1
ffffffffc0200d9a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d9c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d9e:	30d7f963          	bgeu	a5,a3,ffffffffc02010b0 <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0200da2:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200da4:	00043c03          	ld	s8,0(s0)
ffffffffc0200da8:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200dac:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200db0:	e400                	sd	s0,8(s0)
ffffffffc0200db2:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200db4:	00005797          	auipc	a5,0x5
ffffffffc0200db8:	2807a223          	sw	zero,644(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200dbc:	1bb000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200dc0:	2c051863          	bnez	a0,ffffffffc0201090 <default_check+0x3d6>
    free_page(p0);
ffffffffc0200dc4:	4585                	li	a1,1
ffffffffc0200dc6:	8552                	mv	a0,s4
ffffffffc0200dc8:	1ed000ef          	jal	ra,ffffffffc02017b4 <free_pages>
    free_page(p1);
ffffffffc0200dcc:	4585                	li	a1,1
ffffffffc0200dce:	854e                	mv	a0,s3
ffffffffc0200dd0:	1e5000ef          	jal	ra,ffffffffc02017b4 <free_pages>
    free_page(p2);
ffffffffc0200dd4:	4585                	li	a1,1
ffffffffc0200dd6:	8556                	mv	a0,s5
ffffffffc0200dd8:	1dd000ef          	jal	ra,ffffffffc02017b4 <free_pages>
    assert(nr_free == 3);
ffffffffc0200ddc:	4818                	lw	a4,16(s0)
ffffffffc0200dde:	478d                	li	a5,3
ffffffffc0200de0:	28f71863          	bne	a4,a5,ffffffffc0201070 <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200de4:	4505                	li	a0,1
ffffffffc0200de6:	191000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200dea:	89aa                	mv	s3,a0
ffffffffc0200dec:	26050263          	beqz	a0,ffffffffc0201050 <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200df0:	4505                	li	a0,1
ffffffffc0200df2:	185000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200df6:	8aaa                	mv	s5,a0
ffffffffc0200df8:	3a050c63          	beqz	a0,ffffffffc02011b0 <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200dfc:	4505                	li	a0,1
ffffffffc0200dfe:	179000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200e02:	8a2a                	mv	s4,a0
ffffffffc0200e04:	38050663          	beqz	a0,ffffffffc0201190 <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0200e08:	4505                	li	a0,1
ffffffffc0200e0a:	16d000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200e0e:	36051163          	bnez	a0,ffffffffc0201170 <default_check+0x4b6>
    free_page(p0);
ffffffffc0200e12:	4585                	li	a1,1
ffffffffc0200e14:	854e                	mv	a0,s3
ffffffffc0200e16:	19f000ef          	jal	ra,ffffffffc02017b4 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200e1a:	641c                	ld	a5,8(s0)
ffffffffc0200e1c:	20878a63          	beq	a5,s0,ffffffffc0201030 <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0200e20:	4505                	li	a0,1
ffffffffc0200e22:	155000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200e26:	30a99563          	bne	s3,a0,ffffffffc0201130 <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0200e2a:	4505                	li	a0,1
ffffffffc0200e2c:	14b000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200e30:	2e051063          	bnez	a0,ffffffffc0201110 <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0200e34:	481c                	lw	a5,16(s0)
ffffffffc0200e36:	2a079d63          	bnez	a5,ffffffffc02010f0 <default_check+0x436>
    free_page(p);
ffffffffc0200e3a:	854e                	mv	a0,s3
ffffffffc0200e3c:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200e3e:	01843023          	sd	s8,0(s0)
ffffffffc0200e42:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200e46:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200e4a:	16b000ef          	jal	ra,ffffffffc02017b4 <free_pages>
    free_page(p1);
ffffffffc0200e4e:	4585                	li	a1,1
ffffffffc0200e50:	8556                	mv	a0,s5
ffffffffc0200e52:	163000ef          	jal	ra,ffffffffc02017b4 <free_pages>
    free_page(p2);
ffffffffc0200e56:	4585                	li	a1,1
ffffffffc0200e58:	8552                	mv	a0,s4
ffffffffc0200e5a:	15b000ef          	jal	ra,ffffffffc02017b4 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200e5e:	4515                	li	a0,5
ffffffffc0200e60:	117000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200e64:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200e66:	26050563          	beqz	a0,ffffffffc02010d0 <default_check+0x416>
ffffffffc0200e6a:	651c                	ld	a5,8(a0)
ffffffffc0200e6c:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200e6e:	8b85                	andi	a5,a5,1
ffffffffc0200e70:	54079063          	bnez	a5,ffffffffc02013b0 <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200e74:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e76:	00043b03          	ld	s6,0(s0)
ffffffffc0200e7a:	00843a83          	ld	s5,8(s0)
ffffffffc0200e7e:	e000                	sd	s0,0(s0)
ffffffffc0200e80:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200e82:	0f5000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200e86:	50051563          	bnez	a0,ffffffffc0201390 <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200e8a:	05098a13          	addi	s4,s3,80
ffffffffc0200e8e:	8552                	mv	a0,s4
ffffffffc0200e90:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200e92:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200e96:	00005797          	auipc	a5,0x5
ffffffffc0200e9a:	1a07a123          	sw	zero,418(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200e9e:	117000ef          	jal	ra,ffffffffc02017b4 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ea2:	4511                	li	a0,4
ffffffffc0200ea4:	0d3000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200ea8:	4c051463          	bnez	a0,ffffffffc0201370 <default_check+0x6b6>
ffffffffc0200eac:	0589b783          	ld	a5,88(s3)
ffffffffc0200eb0:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200eb2:	8b85                	andi	a5,a5,1
ffffffffc0200eb4:	48078e63          	beqz	a5,ffffffffc0201350 <default_check+0x696>
ffffffffc0200eb8:	0609a703          	lw	a4,96(s3)
ffffffffc0200ebc:	478d                	li	a5,3
ffffffffc0200ebe:	48f71963          	bne	a4,a5,ffffffffc0201350 <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200ec2:	450d                	li	a0,3
ffffffffc0200ec4:	0b3000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200ec8:	8c2a                	mv	s8,a0
ffffffffc0200eca:	46050363          	beqz	a0,ffffffffc0201330 <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc0200ece:	4505                	li	a0,1
ffffffffc0200ed0:	0a7000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200ed4:	42051e63          	bnez	a0,ffffffffc0201310 <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0200ed8:	418a1c63          	bne	s4,s8,ffffffffc02012f0 <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200edc:	4585                	li	a1,1
ffffffffc0200ede:	854e                	mv	a0,s3
ffffffffc0200ee0:	0d5000ef          	jal	ra,ffffffffc02017b4 <free_pages>
    free_pages(p1, 3);
ffffffffc0200ee4:	458d                	li	a1,3
ffffffffc0200ee6:	8552                	mv	a0,s4
ffffffffc0200ee8:	0cd000ef          	jal	ra,ffffffffc02017b4 <free_pages>
ffffffffc0200eec:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200ef0:	02898c13          	addi	s8,s3,40
ffffffffc0200ef4:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200ef6:	8b85                	andi	a5,a5,1
ffffffffc0200ef8:	3c078c63          	beqz	a5,ffffffffc02012d0 <default_check+0x616>
ffffffffc0200efc:	0109a703          	lw	a4,16(s3)
ffffffffc0200f00:	4785                	li	a5,1
ffffffffc0200f02:	3cf71763          	bne	a4,a5,ffffffffc02012d0 <default_check+0x616>
ffffffffc0200f06:	008a3783          	ld	a5,8(s4)
ffffffffc0200f0a:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200f0c:	8b85                	andi	a5,a5,1
ffffffffc0200f0e:	3a078163          	beqz	a5,ffffffffc02012b0 <default_check+0x5f6>
ffffffffc0200f12:	010a2703          	lw	a4,16(s4)
ffffffffc0200f16:	478d                	li	a5,3
ffffffffc0200f18:	38f71c63          	bne	a4,a5,ffffffffc02012b0 <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200f1c:	4505                	li	a0,1
ffffffffc0200f1e:	059000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200f22:	36a99763          	bne	s3,a0,ffffffffc0201290 <default_check+0x5d6>
    free_page(p0);
ffffffffc0200f26:	4585                	li	a1,1
ffffffffc0200f28:	08d000ef          	jal	ra,ffffffffc02017b4 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200f2c:	4509                	li	a0,2
ffffffffc0200f2e:	049000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200f32:	32aa1f63          	bne	s4,a0,ffffffffc0201270 <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc0200f36:	4589                	li	a1,2
ffffffffc0200f38:	07d000ef          	jal	ra,ffffffffc02017b4 <free_pages>
    free_page(p2);
ffffffffc0200f3c:	4585                	li	a1,1
ffffffffc0200f3e:	8562                	mv	a0,s8
ffffffffc0200f40:	075000ef          	jal	ra,ffffffffc02017b4 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f44:	4515                	li	a0,5
ffffffffc0200f46:	031000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200f4a:	89aa                	mv	s3,a0
ffffffffc0200f4c:	48050263          	beqz	a0,ffffffffc02013d0 <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0200f50:	4505                	li	a0,1
ffffffffc0200f52:	025000ef          	jal	ra,ffffffffc0201776 <alloc_pages>
ffffffffc0200f56:	2c051d63          	bnez	a0,ffffffffc0201230 <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0200f5a:	481c                	lw	a5,16(s0)
ffffffffc0200f5c:	2a079a63          	bnez	a5,ffffffffc0201210 <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200f60:	4595                	li	a1,5
ffffffffc0200f62:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200f64:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200f68:	01643023          	sd	s6,0(s0)
ffffffffc0200f6c:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200f70:	045000ef          	jal	ra,ffffffffc02017b4 <free_pages>
    return listelm->next;
ffffffffc0200f74:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f76:	00878963          	beq	a5,s0,ffffffffc0200f88 <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200f7a:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f7e:	679c                	ld	a5,8(a5)
ffffffffc0200f80:	397d                	addiw	s2,s2,-1
ffffffffc0200f82:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f84:	fe879be3          	bne	a5,s0,ffffffffc0200f7a <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0200f88:	26091463          	bnez	s2,ffffffffc02011f0 <default_check+0x536>
    assert(total == 0);
ffffffffc0200f8c:	46049263          	bnez	s1,ffffffffc02013f0 <default_check+0x736>
}
ffffffffc0200f90:	60a6                	ld	ra,72(sp)
ffffffffc0200f92:	6406                	ld	s0,64(sp)
ffffffffc0200f94:	74e2                	ld	s1,56(sp)
ffffffffc0200f96:	7942                	ld	s2,48(sp)
ffffffffc0200f98:	79a2                	ld	s3,40(sp)
ffffffffc0200f9a:	7a02                	ld	s4,32(sp)
ffffffffc0200f9c:	6ae2                	ld	s5,24(sp)
ffffffffc0200f9e:	6b42                	ld	s6,16(sp)
ffffffffc0200fa0:	6ba2                	ld	s7,8(sp)
ffffffffc0200fa2:	6c02                	ld	s8,0(sp)
ffffffffc0200fa4:	6161                	addi	sp,sp,80
ffffffffc0200fa6:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fa8:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200faa:	4481                	li	s1,0
ffffffffc0200fac:	4901                	li	s2,0
ffffffffc0200fae:	b3b9                	j	ffffffffc0200cfc <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200fb0:	00002697          	auipc	a3,0x2
ffffffffc0200fb4:	89068693          	addi	a3,a3,-1904 # ffffffffc0202840 <commands+0x628>
ffffffffc0200fb8:	00002617          	auipc	a2,0x2
ffffffffc0200fbc:	89860613          	addi	a2,a2,-1896 # ffffffffc0202850 <commands+0x638>
ffffffffc0200fc0:	0f000593          	li	a1,240
ffffffffc0200fc4:	00002517          	auipc	a0,0x2
ffffffffc0200fc8:	8a450513          	addi	a0,a0,-1884 # ffffffffc0202868 <commands+0x650>
ffffffffc0200fcc:	c06ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200fd0:	00002697          	auipc	a3,0x2
ffffffffc0200fd4:	93068693          	addi	a3,a3,-1744 # ffffffffc0202900 <commands+0x6e8>
ffffffffc0200fd8:	00002617          	auipc	a2,0x2
ffffffffc0200fdc:	87860613          	addi	a2,a2,-1928 # ffffffffc0202850 <commands+0x638>
ffffffffc0200fe0:	0bd00593          	li	a1,189
ffffffffc0200fe4:	00002517          	auipc	a0,0x2
ffffffffc0200fe8:	88450513          	addi	a0,a0,-1916 # ffffffffc0202868 <commands+0x650>
ffffffffc0200fec:	be6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ff0:	00002697          	auipc	a3,0x2
ffffffffc0200ff4:	93868693          	addi	a3,a3,-1736 # ffffffffc0202928 <commands+0x710>
ffffffffc0200ff8:	00002617          	auipc	a2,0x2
ffffffffc0200ffc:	85860613          	addi	a2,a2,-1960 # ffffffffc0202850 <commands+0x638>
ffffffffc0201000:	0be00593          	li	a1,190
ffffffffc0201004:	00002517          	auipc	a0,0x2
ffffffffc0201008:	86450513          	addi	a0,a0,-1948 # ffffffffc0202868 <commands+0x650>
ffffffffc020100c:	bc6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201010:	00002697          	auipc	a3,0x2
ffffffffc0201014:	95868693          	addi	a3,a3,-1704 # ffffffffc0202968 <commands+0x750>
ffffffffc0201018:	00002617          	auipc	a2,0x2
ffffffffc020101c:	83860613          	addi	a2,a2,-1992 # ffffffffc0202850 <commands+0x638>
ffffffffc0201020:	0c000593          	li	a1,192
ffffffffc0201024:	00002517          	auipc	a0,0x2
ffffffffc0201028:	84450513          	addi	a0,a0,-1980 # ffffffffc0202868 <commands+0x650>
ffffffffc020102c:	ba6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201030:	00002697          	auipc	a3,0x2
ffffffffc0201034:	9c068693          	addi	a3,a3,-1600 # ffffffffc02029f0 <commands+0x7d8>
ffffffffc0201038:	00002617          	auipc	a2,0x2
ffffffffc020103c:	81860613          	addi	a2,a2,-2024 # ffffffffc0202850 <commands+0x638>
ffffffffc0201040:	0d900593          	li	a1,217
ffffffffc0201044:	00002517          	auipc	a0,0x2
ffffffffc0201048:	82450513          	addi	a0,a0,-2012 # ffffffffc0202868 <commands+0x650>
ffffffffc020104c:	b86ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201050:	00002697          	auipc	a3,0x2
ffffffffc0201054:	85068693          	addi	a3,a3,-1968 # ffffffffc02028a0 <commands+0x688>
ffffffffc0201058:	00001617          	auipc	a2,0x1
ffffffffc020105c:	7f860613          	addi	a2,a2,2040 # ffffffffc0202850 <commands+0x638>
ffffffffc0201060:	0d200593          	li	a1,210
ffffffffc0201064:	00002517          	auipc	a0,0x2
ffffffffc0201068:	80450513          	addi	a0,a0,-2044 # ffffffffc0202868 <commands+0x650>
ffffffffc020106c:	b66ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 3);
ffffffffc0201070:	00002697          	auipc	a3,0x2
ffffffffc0201074:	97068693          	addi	a3,a3,-1680 # ffffffffc02029e0 <commands+0x7c8>
ffffffffc0201078:	00001617          	auipc	a2,0x1
ffffffffc020107c:	7d860613          	addi	a2,a2,2008 # ffffffffc0202850 <commands+0x638>
ffffffffc0201080:	0d000593          	li	a1,208
ffffffffc0201084:	00001517          	auipc	a0,0x1
ffffffffc0201088:	7e450513          	addi	a0,a0,2020 # ffffffffc0202868 <commands+0x650>
ffffffffc020108c:	b46ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201090:	00002697          	auipc	a3,0x2
ffffffffc0201094:	93868693          	addi	a3,a3,-1736 # ffffffffc02029c8 <commands+0x7b0>
ffffffffc0201098:	00001617          	auipc	a2,0x1
ffffffffc020109c:	7b860613          	addi	a2,a2,1976 # ffffffffc0202850 <commands+0x638>
ffffffffc02010a0:	0cb00593          	li	a1,203
ffffffffc02010a4:	00001517          	auipc	a0,0x1
ffffffffc02010a8:	7c450513          	addi	a0,a0,1988 # ffffffffc0202868 <commands+0x650>
ffffffffc02010ac:	b26ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010b0:	00002697          	auipc	a3,0x2
ffffffffc02010b4:	8f868693          	addi	a3,a3,-1800 # ffffffffc02029a8 <commands+0x790>
ffffffffc02010b8:	00001617          	auipc	a2,0x1
ffffffffc02010bc:	79860613          	addi	a2,a2,1944 # ffffffffc0202850 <commands+0x638>
ffffffffc02010c0:	0c200593          	li	a1,194
ffffffffc02010c4:	00001517          	auipc	a0,0x1
ffffffffc02010c8:	7a450513          	addi	a0,a0,1956 # ffffffffc0202868 <commands+0x650>
ffffffffc02010cc:	b06ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 != NULL);
ffffffffc02010d0:	00002697          	auipc	a3,0x2
ffffffffc02010d4:	96868693          	addi	a3,a3,-1688 # ffffffffc0202a38 <commands+0x820>
ffffffffc02010d8:	00001617          	auipc	a2,0x1
ffffffffc02010dc:	77860613          	addi	a2,a2,1912 # ffffffffc0202850 <commands+0x638>
ffffffffc02010e0:	0f800593          	li	a1,248
ffffffffc02010e4:	00001517          	auipc	a0,0x1
ffffffffc02010e8:	78450513          	addi	a0,a0,1924 # ffffffffc0202868 <commands+0x650>
ffffffffc02010ec:	ae6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc02010f0:	00002697          	auipc	a3,0x2
ffffffffc02010f4:	93868693          	addi	a3,a3,-1736 # ffffffffc0202a28 <commands+0x810>
ffffffffc02010f8:	00001617          	auipc	a2,0x1
ffffffffc02010fc:	75860613          	addi	a2,a2,1880 # ffffffffc0202850 <commands+0x638>
ffffffffc0201100:	0df00593          	li	a1,223
ffffffffc0201104:	00001517          	auipc	a0,0x1
ffffffffc0201108:	76450513          	addi	a0,a0,1892 # ffffffffc0202868 <commands+0x650>
ffffffffc020110c:	ac6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201110:	00002697          	auipc	a3,0x2
ffffffffc0201114:	8b868693          	addi	a3,a3,-1864 # ffffffffc02029c8 <commands+0x7b0>
ffffffffc0201118:	00001617          	auipc	a2,0x1
ffffffffc020111c:	73860613          	addi	a2,a2,1848 # ffffffffc0202850 <commands+0x638>
ffffffffc0201120:	0dd00593          	li	a1,221
ffffffffc0201124:	00001517          	auipc	a0,0x1
ffffffffc0201128:	74450513          	addi	a0,a0,1860 # ffffffffc0202868 <commands+0x650>
ffffffffc020112c:	aa6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201130:	00002697          	auipc	a3,0x2
ffffffffc0201134:	8d868693          	addi	a3,a3,-1832 # ffffffffc0202a08 <commands+0x7f0>
ffffffffc0201138:	00001617          	auipc	a2,0x1
ffffffffc020113c:	71860613          	addi	a2,a2,1816 # ffffffffc0202850 <commands+0x638>
ffffffffc0201140:	0dc00593          	li	a1,220
ffffffffc0201144:	00001517          	auipc	a0,0x1
ffffffffc0201148:	72450513          	addi	a0,a0,1828 # ffffffffc0202868 <commands+0x650>
ffffffffc020114c:	a86ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201150:	00001697          	auipc	a3,0x1
ffffffffc0201154:	75068693          	addi	a3,a3,1872 # ffffffffc02028a0 <commands+0x688>
ffffffffc0201158:	00001617          	auipc	a2,0x1
ffffffffc020115c:	6f860613          	addi	a2,a2,1784 # ffffffffc0202850 <commands+0x638>
ffffffffc0201160:	0b900593          	li	a1,185
ffffffffc0201164:	00001517          	auipc	a0,0x1
ffffffffc0201168:	70450513          	addi	a0,a0,1796 # ffffffffc0202868 <commands+0x650>
ffffffffc020116c:	a66ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201170:	00002697          	auipc	a3,0x2
ffffffffc0201174:	85868693          	addi	a3,a3,-1960 # ffffffffc02029c8 <commands+0x7b0>
ffffffffc0201178:	00001617          	auipc	a2,0x1
ffffffffc020117c:	6d860613          	addi	a2,a2,1752 # ffffffffc0202850 <commands+0x638>
ffffffffc0201180:	0d600593          	li	a1,214
ffffffffc0201184:	00001517          	auipc	a0,0x1
ffffffffc0201188:	6e450513          	addi	a0,a0,1764 # ffffffffc0202868 <commands+0x650>
ffffffffc020118c:	a46ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201190:	00001697          	auipc	a3,0x1
ffffffffc0201194:	75068693          	addi	a3,a3,1872 # ffffffffc02028e0 <commands+0x6c8>
ffffffffc0201198:	00001617          	auipc	a2,0x1
ffffffffc020119c:	6b860613          	addi	a2,a2,1720 # ffffffffc0202850 <commands+0x638>
ffffffffc02011a0:	0d400593          	li	a1,212
ffffffffc02011a4:	00001517          	auipc	a0,0x1
ffffffffc02011a8:	6c450513          	addi	a0,a0,1732 # ffffffffc0202868 <commands+0x650>
ffffffffc02011ac:	a26ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011b0:	00001697          	auipc	a3,0x1
ffffffffc02011b4:	71068693          	addi	a3,a3,1808 # ffffffffc02028c0 <commands+0x6a8>
ffffffffc02011b8:	00001617          	auipc	a2,0x1
ffffffffc02011bc:	69860613          	addi	a2,a2,1688 # ffffffffc0202850 <commands+0x638>
ffffffffc02011c0:	0d300593          	li	a1,211
ffffffffc02011c4:	00001517          	auipc	a0,0x1
ffffffffc02011c8:	6a450513          	addi	a0,a0,1700 # ffffffffc0202868 <commands+0x650>
ffffffffc02011cc:	a06ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011d0:	00001697          	auipc	a3,0x1
ffffffffc02011d4:	71068693          	addi	a3,a3,1808 # ffffffffc02028e0 <commands+0x6c8>
ffffffffc02011d8:	00001617          	auipc	a2,0x1
ffffffffc02011dc:	67860613          	addi	a2,a2,1656 # ffffffffc0202850 <commands+0x638>
ffffffffc02011e0:	0bb00593          	li	a1,187
ffffffffc02011e4:	00001517          	auipc	a0,0x1
ffffffffc02011e8:	68450513          	addi	a0,a0,1668 # ffffffffc0202868 <commands+0x650>
ffffffffc02011ec:	9e6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(count == 0);
ffffffffc02011f0:	00002697          	auipc	a3,0x2
ffffffffc02011f4:	99868693          	addi	a3,a3,-1640 # ffffffffc0202b88 <commands+0x970>
ffffffffc02011f8:	00001617          	auipc	a2,0x1
ffffffffc02011fc:	65860613          	addi	a2,a2,1624 # ffffffffc0202850 <commands+0x638>
ffffffffc0201200:	12500593          	li	a1,293
ffffffffc0201204:	00001517          	auipc	a0,0x1
ffffffffc0201208:	66450513          	addi	a0,a0,1636 # ffffffffc0202868 <commands+0x650>
ffffffffc020120c:	9c6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc0201210:	00002697          	auipc	a3,0x2
ffffffffc0201214:	81868693          	addi	a3,a3,-2024 # ffffffffc0202a28 <commands+0x810>
ffffffffc0201218:	00001617          	auipc	a2,0x1
ffffffffc020121c:	63860613          	addi	a2,a2,1592 # ffffffffc0202850 <commands+0x638>
ffffffffc0201220:	11a00593          	li	a1,282
ffffffffc0201224:	00001517          	auipc	a0,0x1
ffffffffc0201228:	64450513          	addi	a0,a0,1604 # ffffffffc0202868 <commands+0x650>
ffffffffc020122c:	9a6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201230:	00001697          	auipc	a3,0x1
ffffffffc0201234:	79868693          	addi	a3,a3,1944 # ffffffffc02029c8 <commands+0x7b0>
ffffffffc0201238:	00001617          	auipc	a2,0x1
ffffffffc020123c:	61860613          	addi	a2,a2,1560 # ffffffffc0202850 <commands+0x638>
ffffffffc0201240:	11800593          	li	a1,280
ffffffffc0201244:	00001517          	auipc	a0,0x1
ffffffffc0201248:	62450513          	addi	a0,a0,1572 # ffffffffc0202868 <commands+0x650>
ffffffffc020124c:	986ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201250:	00001697          	auipc	a3,0x1
ffffffffc0201254:	73868693          	addi	a3,a3,1848 # ffffffffc0202988 <commands+0x770>
ffffffffc0201258:	00001617          	auipc	a2,0x1
ffffffffc020125c:	5f860613          	addi	a2,a2,1528 # ffffffffc0202850 <commands+0x638>
ffffffffc0201260:	0c100593          	li	a1,193
ffffffffc0201264:	00001517          	auipc	a0,0x1
ffffffffc0201268:	60450513          	addi	a0,a0,1540 # ffffffffc0202868 <commands+0x650>
ffffffffc020126c:	966ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201270:	00002697          	auipc	a3,0x2
ffffffffc0201274:	8d868693          	addi	a3,a3,-1832 # ffffffffc0202b48 <commands+0x930>
ffffffffc0201278:	00001617          	auipc	a2,0x1
ffffffffc020127c:	5d860613          	addi	a2,a2,1496 # ffffffffc0202850 <commands+0x638>
ffffffffc0201280:	11200593          	li	a1,274
ffffffffc0201284:	00001517          	auipc	a0,0x1
ffffffffc0201288:	5e450513          	addi	a0,a0,1508 # ffffffffc0202868 <commands+0x650>
ffffffffc020128c:	946ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201290:	00002697          	auipc	a3,0x2
ffffffffc0201294:	89868693          	addi	a3,a3,-1896 # ffffffffc0202b28 <commands+0x910>
ffffffffc0201298:	00001617          	auipc	a2,0x1
ffffffffc020129c:	5b860613          	addi	a2,a2,1464 # ffffffffc0202850 <commands+0x638>
ffffffffc02012a0:	11000593          	li	a1,272
ffffffffc02012a4:	00001517          	auipc	a0,0x1
ffffffffc02012a8:	5c450513          	addi	a0,a0,1476 # ffffffffc0202868 <commands+0x650>
ffffffffc02012ac:	926ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02012b0:	00002697          	auipc	a3,0x2
ffffffffc02012b4:	85068693          	addi	a3,a3,-1968 # ffffffffc0202b00 <commands+0x8e8>
ffffffffc02012b8:	00001617          	auipc	a2,0x1
ffffffffc02012bc:	59860613          	addi	a2,a2,1432 # ffffffffc0202850 <commands+0x638>
ffffffffc02012c0:	10e00593          	li	a1,270
ffffffffc02012c4:	00001517          	auipc	a0,0x1
ffffffffc02012c8:	5a450513          	addi	a0,a0,1444 # ffffffffc0202868 <commands+0x650>
ffffffffc02012cc:	906ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02012d0:	00002697          	auipc	a3,0x2
ffffffffc02012d4:	80868693          	addi	a3,a3,-2040 # ffffffffc0202ad8 <commands+0x8c0>
ffffffffc02012d8:	00001617          	auipc	a2,0x1
ffffffffc02012dc:	57860613          	addi	a2,a2,1400 # ffffffffc0202850 <commands+0x638>
ffffffffc02012e0:	10d00593          	li	a1,269
ffffffffc02012e4:	00001517          	auipc	a0,0x1
ffffffffc02012e8:	58450513          	addi	a0,a0,1412 # ffffffffc0202868 <commands+0x650>
ffffffffc02012ec:	8e6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02012f0:	00001697          	auipc	a3,0x1
ffffffffc02012f4:	7d868693          	addi	a3,a3,2008 # ffffffffc0202ac8 <commands+0x8b0>
ffffffffc02012f8:	00001617          	auipc	a2,0x1
ffffffffc02012fc:	55860613          	addi	a2,a2,1368 # ffffffffc0202850 <commands+0x638>
ffffffffc0201300:	10800593          	li	a1,264
ffffffffc0201304:	00001517          	auipc	a0,0x1
ffffffffc0201308:	56450513          	addi	a0,a0,1380 # ffffffffc0202868 <commands+0x650>
ffffffffc020130c:	8c6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201310:	00001697          	auipc	a3,0x1
ffffffffc0201314:	6b868693          	addi	a3,a3,1720 # ffffffffc02029c8 <commands+0x7b0>
ffffffffc0201318:	00001617          	auipc	a2,0x1
ffffffffc020131c:	53860613          	addi	a2,a2,1336 # ffffffffc0202850 <commands+0x638>
ffffffffc0201320:	10700593          	li	a1,263
ffffffffc0201324:	00001517          	auipc	a0,0x1
ffffffffc0201328:	54450513          	addi	a0,a0,1348 # ffffffffc0202868 <commands+0x650>
ffffffffc020132c:	8a6ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201330:	00001697          	auipc	a3,0x1
ffffffffc0201334:	77868693          	addi	a3,a3,1912 # ffffffffc0202aa8 <commands+0x890>
ffffffffc0201338:	00001617          	auipc	a2,0x1
ffffffffc020133c:	51860613          	addi	a2,a2,1304 # ffffffffc0202850 <commands+0x638>
ffffffffc0201340:	10600593          	li	a1,262
ffffffffc0201344:	00001517          	auipc	a0,0x1
ffffffffc0201348:	52450513          	addi	a0,a0,1316 # ffffffffc0202868 <commands+0x650>
ffffffffc020134c:	886ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201350:	00001697          	auipc	a3,0x1
ffffffffc0201354:	72868693          	addi	a3,a3,1832 # ffffffffc0202a78 <commands+0x860>
ffffffffc0201358:	00001617          	auipc	a2,0x1
ffffffffc020135c:	4f860613          	addi	a2,a2,1272 # ffffffffc0202850 <commands+0x638>
ffffffffc0201360:	10500593          	li	a1,261
ffffffffc0201364:	00001517          	auipc	a0,0x1
ffffffffc0201368:	50450513          	addi	a0,a0,1284 # ffffffffc0202868 <commands+0x650>
ffffffffc020136c:	866ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201370:	00001697          	auipc	a3,0x1
ffffffffc0201374:	6f068693          	addi	a3,a3,1776 # ffffffffc0202a60 <commands+0x848>
ffffffffc0201378:	00001617          	auipc	a2,0x1
ffffffffc020137c:	4d860613          	addi	a2,a2,1240 # ffffffffc0202850 <commands+0x638>
ffffffffc0201380:	10400593          	li	a1,260
ffffffffc0201384:	00001517          	auipc	a0,0x1
ffffffffc0201388:	4e450513          	addi	a0,a0,1252 # ffffffffc0202868 <commands+0x650>
ffffffffc020138c:	846ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201390:	00001697          	auipc	a3,0x1
ffffffffc0201394:	63868693          	addi	a3,a3,1592 # ffffffffc02029c8 <commands+0x7b0>
ffffffffc0201398:	00001617          	auipc	a2,0x1
ffffffffc020139c:	4b860613          	addi	a2,a2,1208 # ffffffffc0202850 <commands+0x638>
ffffffffc02013a0:	0fe00593          	li	a1,254
ffffffffc02013a4:	00001517          	auipc	a0,0x1
ffffffffc02013a8:	4c450513          	addi	a0,a0,1220 # ffffffffc0202868 <commands+0x650>
ffffffffc02013ac:	826ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(!PageProperty(p0));
ffffffffc02013b0:	00001697          	auipc	a3,0x1
ffffffffc02013b4:	69868693          	addi	a3,a3,1688 # ffffffffc0202a48 <commands+0x830>
ffffffffc02013b8:	00001617          	auipc	a2,0x1
ffffffffc02013bc:	49860613          	addi	a2,a2,1176 # ffffffffc0202850 <commands+0x638>
ffffffffc02013c0:	0f900593          	li	a1,249
ffffffffc02013c4:	00001517          	auipc	a0,0x1
ffffffffc02013c8:	4a450513          	addi	a0,a0,1188 # ffffffffc0202868 <commands+0x650>
ffffffffc02013cc:	806ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02013d0:	00001697          	auipc	a3,0x1
ffffffffc02013d4:	79868693          	addi	a3,a3,1944 # ffffffffc0202b68 <commands+0x950>
ffffffffc02013d8:	00001617          	auipc	a2,0x1
ffffffffc02013dc:	47860613          	addi	a2,a2,1144 # ffffffffc0202850 <commands+0x638>
ffffffffc02013e0:	11700593          	li	a1,279
ffffffffc02013e4:	00001517          	auipc	a0,0x1
ffffffffc02013e8:	48450513          	addi	a0,a0,1156 # ffffffffc0202868 <commands+0x650>
ffffffffc02013ec:	fe7fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(total == 0);
ffffffffc02013f0:	00001697          	auipc	a3,0x1
ffffffffc02013f4:	7a868693          	addi	a3,a3,1960 # ffffffffc0202b98 <commands+0x980>
ffffffffc02013f8:	00001617          	auipc	a2,0x1
ffffffffc02013fc:	45860613          	addi	a2,a2,1112 # ffffffffc0202850 <commands+0x638>
ffffffffc0201400:	12600593          	li	a1,294
ffffffffc0201404:	00001517          	auipc	a0,0x1
ffffffffc0201408:	46450513          	addi	a0,a0,1124 # ffffffffc0202868 <commands+0x650>
ffffffffc020140c:	fc7fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201410:	00001697          	auipc	a3,0x1
ffffffffc0201414:	47068693          	addi	a3,a3,1136 # ffffffffc0202880 <commands+0x668>
ffffffffc0201418:	00001617          	auipc	a2,0x1
ffffffffc020141c:	43860613          	addi	a2,a2,1080 # ffffffffc0202850 <commands+0x638>
ffffffffc0201420:	0f300593          	li	a1,243
ffffffffc0201424:	00001517          	auipc	a0,0x1
ffffffffc0201428:	44450513          	addi	a0,a0,1092 # ffffffffc0202868 <commands+0x650>
ffffffffc020142c:	fa7fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201430:	00001697          	auipc	a3,0x1
ffffffffc0201434:	49068693          	addi	a3,a3,1168 # ffffffffc02028c0 <commands+0x6a8>
ffffffffc0201438:	00001617          	auipc	a2,0x1
ffffffffc020143c:	41860613          	addi	a2,a2,1048 # ffffffffc0202850 <commands+0x638>
ffffffffc0201440:	0ba00593          	li	a1,186
ffffffffc0201444:	00001517          	auipc	a0,0x1
ffffffffc0201448:	42450513          	addi	a0,a0,1060 # ffffffffc0202868 <commands+0x650>
ffffffffc020144c:	f87fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201450 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201450:	1141                	addi	sp,sp,-16
ffffffffc0201452:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201454:	14058a63          	beqz	a1,ffffffffc02015a8 <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0201458:	00259693          	slli	a3,a1,0x2
ffffffffc020145c:	96ae                	add	a3,a3,a1
ffffffffc020145e:	068e                	slli	a3,a3,0x3
ffffffffc0201460:	96aa                	add	a3,a3,a0
ffffffffc0201462:	87aa                	mv	a5,a0
ffffffffc0201464:	02d50263          	beq	a0,a3,ffffffffc0201488 <default_free_pages+0x38>
ffffffffc0201468:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020146a:	8b05                	andi	a4,a4,1
ffffffffc020146c:	10071e63          	bnez	a4,ffffffffc0201588 <default_free_pages+0x138>
ffffffffc0201470:	6798                	ld	a4,8(a5)
ffffffffc0201472:	8b09                	andi	a4,a4,2
ffffffffc0201474:	10071a63          	bnez	a4,ffffffffc0201588 <default_free_pages+0x138>
        p->flags = 0;
ffffffffc0201478:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020147c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201480:	02878793          	addi	a5,a5,40
ffffffffc0201484:	fed792e3          	bne	a5,a3,ffffffffc0201468 <default_free_pages+0x18>
    base->property = n;
ffffffffc0201488:	2581                	sext.w	a1,a1
ffffffffc020148a:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020148c:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201490:	4789                	li	a5,2
ffffffffc0201492:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201496:	00005697          	auipc	a3,0x5
ffffffffc020149a:	b9268693          	addi	a3,a3,-1134 # ffffffffc0206028 <free_area>
ffffffffc020149e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02014a0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02014a2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02014a6:	9db9                	addw	a1,a1,a4
ffffffffc02014a8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014aa:	0ad78863          	beq	a5,a3,ffffffffc020155a <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc02014ae:	fe878713          	addi	a4,a5,-24
ffffffffc02014b2:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02014b6:	4581                	li	a1,0
            if (base < page) {
ffffffffc02014b8:	00e56a63          	bltu	a0,a4,ffffffffc02014cc <default_free_pages+0x7c>
    return listelm->next;
ffffffffc02014bc:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02014be:	06d70263          	beq	a4,a3,ffffffffc0201522 <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc02014c2:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014c4:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02014c8:	fee57ae3          	bgeu	a0,a4,ffffffffc02014bc <default_free_pages+0x6c>
ffffffffc02014cc:	c199                	beqz	a1,ffffffffc02014d2 <default_free_pages+0x82>
ffffffffc02014ce:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02014d2:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02014d4:	e390                	sd	a2,0(a5)
ffffffffc02014d6:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02014d8:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02014da:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02014dc:	02d70063          	beq	a4,a3,ffffffffc02014fc <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc02014e0:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02014e4:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc02014e8:	02081613          	slli	a2,a6,0x20
ffffffffc02014ec:	9201                	srli	a2,a2,0x20
ffffffffc02014ee:	00261793          	slli	a5,a2,0x2
ffffffffc02014f2:	97b2                	add	a5,a5,a2
ffffffffc02014f4:	078e                	slli	a5,a5,0x3
ffffffffc02014f6:	97ae                	add	a5,a5,a1
ffffffffc02014f8:	02f50f63          	beq	a0,a5,ffffffffc0201536 <default_free_pages+0xe6>
    return listelm->next;
ffffffffc02014fc:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02014fe:	00d70f63          	beq	a4,a3,ffffffffc020151c <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0201502:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201504:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201508:	02059613          	slli	a2,a1,0x20
ffffffffc020150c:	9201                	srli	a2,a2,0x20
ffffffffc020150e:	00261793          	slli	a5,a2,0x2
ffffffffc0201512:	97b2                	add	a5,a5,a2
ffffffffc0201514:	078e                	slli	a5,a5,0x3
ffffffffc0201516:	97aa                	add	a5,a5,a0
ffffffffc0201518:	04f68863          	beq	a3,a5,ffffffffc0201568 <default_free_pages+0x118>
}
ffffffffc020151c:	60a2                	ld	ra,8(sp)
ffffffffc020151e:	0141                	addi	sp,sp,16
ffffffffc0201520:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201522:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201524:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201526:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201528:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020152a:	02d70563          	beq	a4,a3,ffffffffc0201554 <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc020152e:	8832                	mv	a6,a2
ffffffffc0201530:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201532:	87ba                	mv	a5,a4
ffffffffc0201534:	bf41                	j	ffffffffc02014c4 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc0201536:	491c                	lw	a5,16(a0)
ffffffffc0201538:	0107883b          	addw	a6,a5,a6
ffffffffc020153c:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201540:	57f5                	li	a5,-3
ffffffffc0201542:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201546:	6d10                	ld	a2,24(a0)
ffffffffc0201548:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc020154a:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020154c:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc020154e:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201550:	e390                	sd	a2,0(a5)
ffffffffc0201552:	b775                	j	ffffffffc02014fe <default_free_pages+0xae>
ffffffffc0201554:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201556:	873e                	mv	a4,a5
ffffffffc0201558:	b761                	j	ffffffffc02014e0 <default_free_pages+0x90>
}
ffffffffc020155a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020155c:	e390                	sd	a2,0(a5)
ffffffffc020155e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201560:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201562:	ed1c                	sd	a5,24(a0)
ffffffffc0201564:	0141                	addi	sp,sp,16
ffffffffc0201566:	8082                	ret
            base->property += p->property;
ffffffffc0201568:	ff872783          	lw	a5,-8(a4)
ffffffffc020156c:	ff070693          	addi	a3,a4,-16
ffffffffc0201570:	9dbd                	addw	a1,a1,a5
ffffffffc0201572:	c90c                	sw	a1,16(a0)
ffffffffc0201574:	57f5                	li	a5,-3
ffffffffc0201576:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020157a:	6314                	ld	a3,0(a4)
ffffffffc020157c:	671c                	ld	a5,8(a4)
}
ffffffffc020157e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201580:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201582:	e394                	sd	a3,0(a5)
ffffffffc0201584:	0141                	addi	sp,sp,16
ffffffffc0201586:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201588:	00001697          	auipc	a3,0x1
ffffffffc020158c:	62868693          	addi	a3,a3,1576 # ffffffffc0202bb0 <commands+0x998>
ffffffffc0201590:	00001617          	auipc	a2,0x1
ffffffffc0201594:	2c060613          	addi	a2,a2,704 # ffffffffc0202850 <commands+0x638>
ffffffffc0201598:	08300593          	li	a1,131
ffffffffc020159c:	00001517          	auipc	a0,0x1
ffffffffc02015a0:	2cc50513          	addi	a0,a0,716 # ffffffffc0202868 <commands+0x650>
ffffffffc02015a4:	e2ffe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc02015a8:	00001697          	auipc	a3,0x1
ffffffffc02015ac:	60068693          	addi	a3,a3,1536 # ffffffffc0202ba8 <commands+0x990>
ffffffffc02015b0:	00001617          	auipc	a2,0x1
ffffffffc02015b4:	2a060613          	addi	a2,a2,672 # ffffffffc0202850 <commands+0x638>
ffffffffc02015b8:	08000593          	li	a1,128
ffffffffc02015bc:	00001517          	auipc	a0,0x1
ffffffffc02015c0:	2ac50513          	addi	a0,a0,684 # ffffffffc0202868 <commands+0x650>
ffffffffc02015c4:	e0ffe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc02015c8 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02015c8:	c959                	beqz	a0,ffffffffc020165e <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02015ca:	00005597          	auipc	a1,0x5
ffffffffc02015ce:	a5e58593          	addi	a1,a1,-1442 # ffffffffc0206028 <free_area>
ffffffffc02015d2:	0105a803          	lw	a6,16(a1)
ffffffffc02015d6:	862a                	mv	a2,a0
ffffffffc02015d8:	02081793          	slli	a5,a6,0x20
ffffffffc02015dc:	9381                	srli	a5,a5,0x20
ffffffffc02015de:	00a7ee63          	bltu	a5,a0,ffffffffc02015fa <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02015e2:	87ae                	mv	a5,a1
ffffffffc02015e4:	a801                	j	ffffffffc02015f4 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc02015e6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02015ea:	02071693          	slli	a3,a4,0x20
ffffffffc02015ee:	9281                	srli	a3,a3,0x20
ffffffffc02015f0:	00c6f763          	bgeu	a3,a2,ffffffffc02015fe <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02015f4:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02015f6:	feb798e3          	bne	a5,a1,ffffffffc02015e6 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02015fa:	4501                	li	a0,0
}
ffffffffc02015fc:	8082                	ret
    return listelm->prev;
ffffffffc02015fe:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201602:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201606:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc020160a:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc020160e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201612:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201616:	02d67b63          	bgeu	a2,a3,ffffffffc020164c <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc020161a:	00261693          	slli	a3,a2,0x2
ffffffffc020161e:	96b2                	add	a3,a3,a2
ffffffffc0201620:	068e                	slli	a3,a3,0x3
ffffffffc0201622:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0201624:	41c7073b          	subw	a4,a4,t3
ffffffffc0201628:	ca98                	sw	a4,16(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020162a:	00868613          	addi	a2,a3,8
ffffffffc020162e:	4709                	li	a4,2
ffffffffc0201630:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201634:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201638:	01868613          	addi	a2,a3,24
        nr_free -= n;
ffffffffc020163c:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0201640:	e310                	sd	a2,0(a4)
ffffffffc0201642:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0201646:	f298                	sd	a4,32(a3)
    elm->prev = prev;
ffffffffc0201648:	0116bc23          	sd	a7,24(a3)
ffffffffc020164c:	41c8083b          	subw	a6,a6,t3
ffffffffc0201650:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201654:	5775                	li	a4,-3
ffffffffc0201656:	17c1                	addi	a5,a5,-16
ffffffffc0201658:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020165c:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020165e:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201660:	00001697          	auipc	a3,0x1
ffffffffc0201664:	54868693          	addi	a3,a3,1352 # ffffffffc0202ba8 <commands+0x990>
ffffffffc0201668:	00001617          	auipc	a2,0x1
ffffffffc020166c:	1e860613          	addi	a2,a2,488 # ffffffffc0202850 <commands+0x638>
ffffffffc0201670:	06200593          	li	a1,98
ffffffffc0201674:	00001517          	auipc	a0,0x1
ffffffffc0201678:	1f450513          	addi	a0,a0,500 # ffffffffc0202868 <commands+0x650>
default_alloc_pages(size_t n) {
ffffffffc020167c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020167e:	d55fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201682 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0201682:	1141                	addi	sp,sp,-16
ffffffffc0201684:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201686:	c9e1                	beqz	a1,ffffffffc0201756 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201688:	00259693          	slli	a3,a1,0x2
ffffffffc020168c:	96ae                	add	a3,a3,a1
ffffffffc020168e:	068e                	slli	a3,a3,0x3
ffffffffc0201690:	96aa                	add	a3,a3,a0
ffffffffc0201692:	87aa                	mv	a5,a0
ffffffffc0201694:	00d50f63          	beq	a0,a3,ffffffffc02016b2 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201698:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020169a:	8b05                	andi	a4,a4,1
ffffffffc020169c:	cf49                	beqz	a4,ffffffffc0201736 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc020169e:	0007a823          	sw	zero,16(a5)
ffffffffc02016a2:	0007b423          	sd	zero,8(a5)
ffffffffc02016a6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02016aa:	02878793          	addi	a5,a5,40
ffffffffc02016ae:	fed795e3          	bne	a5,a3,ffffffffc0201698 <default_init_memmap+0x16>
    base->property = n;
ffffffffc02016b2:	2581                	sext.w	a1,a1
ffffffffc02016b4:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016b6:	4789                	li	a5,2
ffffffffc02016b8:	00850713          	addi	a4,a0,8
ffffffffc02016bc:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02016c0:	00005697          	auipc	a3,0x5
ffffffffc02016c4:	96868693          	addi	a3,a3,-1688 # ffffffffc0206028 <free_area>
ffffffffc02016c8:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016ca:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02016cc:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02016d0:	9db9                	addw	a1,a1,a4
ffffffffc02016d2:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02016d4:	04d78a63          	beq	a5,a3,ffffffffc0201728 <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc02016d8:	fe878713          	addi	a4,a5,-24
ffffffffc02016dc:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02016e0:	4581                	li	a1,0
            if (base < page) {
ffffffffc02016e2:	00e56a63          	bltu	a0,a4,ffffffffc02016f6 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc02016e6:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02016e8:	02d70263          	beq	a4,a3,ffffffffc020170c <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc02016ec:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016ee:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016f2:	fee57ae3          	bgeu	a0,a4,ffffffffc02016e6 <default_init_memmap+0x64>
ffffffffc02016f6:	c199                	beqz	a1,ffffffffc02016fc <default_init_memmap+0x7a>
ffffffffc02016f8:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016fc:	6398                	ld	a4,0(a5)
}
ffffffffc02016fe:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201700:	e390                	sd	a2,0(a5)
ffffffffc0201702:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201704:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201706:	ed18                	sd	a4,24(a0)
ffffffffc0201708:	0141                	addi	sp,sp,16
ffffffffc020170a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020170c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020170e:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201710:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201712:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201714:	00d70663          	beq	a4,a3,ffffffffc0201720 <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201718:	8832                	mv	a6,a2
ffffffffc020171a:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020171c:	87ba                	mv	a5,a4
ffffffffc020171e:	bfc1                	j	ffffffffc02016ee <default_init_memmap+0x6c>
}
ffffffffc0201720:	60a2                	ld	ra,8(sp)
ffffffffc0201722:	e290                	sd	a2,0(a3)
ffffffffc0201724:	0141                	addi	sp,sp,16
ffffffffc0201726:	8082                	ret
ffffffffc0201728:	60a2                	ld	ra,8(sp)
ffffffffc020172a:	e390                	sd	a2,0(a5)
ffffffffc020172c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020172e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201730:	ed1c                	sd	a5,24(a0)
ffffffffc0201732:	0141                	addi	sp,sp,16
ffffffffc0201734:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201736:	00001697          	auipc	a3,0x1
ffffffffc020173a:	4a268693          	addi	a3,a3,1186 # ffffffffc0202bd8 <commands+0x9c0>
ffffffffc020173e:	00001617          	auipc	a2,0x1
ffffffffc0201742:	11260613          	addi	a2,a2,274 # ffffffffc0202850 <commands+0x638>
ffffffffc0201746:	04900593          	li	a1,73
ffffffffc020174a:	00001517          	auipc	a0,0x1
ffffffffc020174e:	11e50513          	addi	a0,a0,286 # ffffffffc0202868 <commands+0x650>
ffffffffc0201752:	c81fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc0201756:	00001697          	auipc	a3,0x1
ffffffffc020175a:	45268693          	addi	a3,a3,1106 # ffffffffc0202ba8 <commands+0x990>
ffffffffc020175e:	00001617          	auipc	a2,0x1
ffffffffc0201762:	0f260613          	addi	a2,a2,242 # ffffffffc0202850 <commands+0x638>
ffffffffc0201766:	04600593          	li	a1,70
ffffffffc020176a:	00001517          	auipc	a0,0x1
ffffffffc020176e:	0fe50513          	addi	a0,a0,254 # ffffffffc0202868 <commands+0x650>
ffffffffc0201772:	c61fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201776 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201776:	100027f3          	csrr	a5,sstatus
ffffffffc020177a:	8b89                	andi	a5,a5,2
ffffffffc020177c:	e799                	bnez	a5,ffffffffc020178a <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020177e:	00005797          	auipc	a5,0x5
ffffffffc0201782:	cfa7b783          	ld	a5,-774(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201786:	6f9c                	ld	a5,24(a5)
ffffffffc0201788:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc020178a:	1141                	addi	sp,sp,-16
ffffffffc020178c:	e406                	sd	ra,8(sp)
ffffffffc020178e:	e022                	sd	s0,0(sp)
ffffffffc0201790:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201792:	8a2ff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201796:	00005797          	auipc	a5,0x5
ffffffffc020179a:	ce27b783          	ld	a5,-798(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020179e:	6f9c                	ld	a5,24(a5)
ffffffffc02017a0:	8522                	mv	a0,s0
ffffffffc02017a2:	9782                	jalr	a5
ffffffffc02017a4:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02017a6:	888ff0ef          	jal	ra,ffffffffc020082e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02017aa:	60a2                	ld	ra,8(sp)
ffffffffc02017ac:	8522                	mv	a0,s0
ffffffffc02017ae:	6402                	ld	s0,0(sp)
ffffffffc02017b0:	0141                	addi	sp,sp,16
ffffffffc02017b2:	8082                	ret

ffffffffc02017b4 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017b4:	100027f3          	csrr	a5,sstatus
ffffffffc02017b8:	8b89                	andi	a5,a5,2
ffffffffc02017ba:	e799                	bnez	a5,ffffffffc02017c8 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02017bc:	00005797          	auipc	a5,0x5
ffffffffc02017c0:	cbc7b783          	ld	a5,-836(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02017c4:	739c                	ld	a5,32(a5)
ffffffffc02017c6:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02017c8:	1101                	addi	sp,sp,-32
ffffffffc02017ca:	ec06                	sd	ra,24(sp)
ffffffffc02017cc:	e822                	sd	s0,16(sp)
ffffffffc02017ce:	e426                	sd	s1,8(sp)
ffffffffc02017d0:	842a                	mv	s0,a0
ffffffffc02017d2:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02017d4:	860ff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02017d8:	00005797          	auipc	a5,0x5
ffffffffc02017dc:	ca07b783          	ld	a5,-864(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc02017e0:	739c                	ld	a5,32(a5)
ffffffffc02017e2:	85a6                	mv	a1,s1
ffffffffc02017e4:	8522                	mv	a0,s0
ffffffffc02017e6:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02017e8:	6442                	ld	s0,16(sp)
ffffffffc02017ea:	60e2                	ld	ra,24(sp)
ffffffffc02017ec:	64a2                	ld	s1,8(sp)
ffffffffc02017ee:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02017f0:	83eff06f          	j	ffffffffc020082e <intr_enable>

ffffffffc02017f4 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017f4:	100027f3          	csrr	a5,sstatus
ffffffffc02017f8:	8b89                	andi	a5,a5,2
ffffffffc02017fa:	e799                	bnez	a5,ffffffffc0201808 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02017fc:	00005797          	auipc	a5,0x5
ffffffffc0201800:	c7c7b783          	ld	a5,-900(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc0201804:	779c                	ld	a5,40(a5)
ffffffffc0201806:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201808:	1141                	addi	sp,sp,-16
ffffffffc020180a:	e406                	sd	ra,8(sp)
ffffffffc020180c:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020180e:	826ff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201812:	00005797          	auipc	a5,0x5
ffffffffc0201816:	c667b783          	ld	a5,-922(a5) # ffffffffc0206478 <pmm_manager>
ffffffffc020181a:	779c                	ld	a5,40(a5)
ffffffffc020181c:	9782                	jalr	a5
ffffffffc020181e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201820:	80eff0ef          	jal	ra,ffffffffc020082e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201824:	60a2                	ld	ra,8(sp)
ffffffffc0201826:	8522                	mv	a0,s0
ffffffffc0201828:	6402                	ld	s0,0(sp)
ffffffffc020182a:	0141                	addi	sp,sp,16
ffffffffc020182c:	8082                	ret

ffffffffc020182e <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020182e:	00001797          	auipc	a5,0x1
ffffffffc0201832:	3d278793          	addi	a5,a5,978 # ffffffffc0202c00 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201836:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201838:	7179                	addi	sp,sp,-48
ffffffffc020183a:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020183c:	00001517          	auipc	a0,0x1
ffffffffc0201840:	3fc50513          	addi	a0,a0,1020 # ffffffffc0202c38 <default_pmm_manager+0x38>
    pmm_manager = &default_pmm_manager;
ffffffffc0201844:	00005417          	auipc	s0,0x5
ffffffffc0201848:	c3440413          	addi	s0,s0,-972 # ffffffffc0206478 <pmm_manager>
void pmm_init(void) {
ffffffffc020184c:	f406                	sd	ra,40(sp)
ffffffffc020184e:	ec26                	sd	s1,24(sp)
ffffffffc0201850:	e44e                	sd	s3,8(sp)
ffffffffc0201852:	e84a                	sd	s2,16(sp)
ffffffffc0201854:	e052                	sd	s4,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201856:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201858:	881fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc020185c:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020185e:	00005497          	auipc	s1,0x5
ffffffffc0201862:	c3248493          	addi	s1,s1,-974 # ffffffffc0206490 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201866:	679c                	ld	a5,8(a5)
ffffffffc0201868:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020186a:	57f5                	li	a5,-3
ffffffffc020186c:	07fa                	slli	a5,a5,0x1e
ffffffffc020186e:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc0201870:	fabfe0ef          	jal	ra,ffffffffc020081a <get_memory_base>
ffffffffc0201874:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201876:	faffe0ef          	jal	ra,ffffffffc0200824 <get_memory_size>
    if (mem_size == 0) {
ffffffffc020187a:	16050163          	beqz	a0,ffffffffc02019dc <pmm_init+0x1ae>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020187e:	892a                	mv	s2,a0
    cprintf("physcial memory map:\n");
ffffffffc0201880:	00001517          	auipc	a0,0x1
ffffffffc0201884:	40050513          	addi	a0,a0,1024 # ffffffffc0202c80 <default_pmm_manager+0x80>
ffffffffc0201888:	851fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020188c:	01298a33          	add	s4,s3,s2
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201890:	864e                	mv	a2,s3
ffffffffc0201892:	fffa0693          	addi	a3,s4,-1
ffffffffc0201896:	85ca                	mv	a1,s2
ffffffffc0201898:	00001517          	auipc	a0,0x1
ffffffffc020189c:	40050513          	addi	a0,a0,1024 # ffffffffc0202c98 <default_pmm_manager+0x98>
ffffffffc02018a0:	839fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02018a4:	c80007b7          	lui	a5,0xc8000
ffffffffc02018a8:	8652                	mv	a2,s4
ffffffffc02018aa:	0d47e863          	bltu	a5,s4,ffffffffc020197a <pmm_init+0x14c>
ffffffffc02018ae:	00006797          	auipc	a5,0x6
ffffffffc02018b2:	bf178793          	addi	a5,a5,-1039 # ffffffffc020749f <end+0xfff>
ffffffffc02018b6:	757d                	lui	a0,0xfffff
ffffffffc02018b8:	8d7d                	and	a0,a0,a5
ffffffffc02018ba:	8231                	srli	a2,a2,0xc
ffffffffc02018bc:	00005597          	auipc	a1,0x5
ffffffffc02018c0:	bac58593          	addi	a1,a1,-1108 # ffffffffc0206468 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018c4:	00005817          	auipc	a6,0x5
ffffffffc02018c8:	bac80813          	addi	a6,a6,-1108 # ffffffffc0206470 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02018cc:	e190                	sd	a2,0(a1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02018ce:	00a83023          	sd	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018d2:	000807b7          	lui	a5,0x80
ffffffffc02018d6:	02f60663          	beq	a2,a5,ffffffffc0201902 <pmm_init+0xd4>
ffffffffc02018da:	4701                	li	a4,0
ffffffffc02018dc:	4781                	li	a5,0
ffffffffc02018de:	4305                	li	t1,1
ffffffffc02018e0:	fff808b7          	lui	a7,0xfff80
        SetPageReserved(pages + i);
ffffffffc02018e4:	953a                	add	a0,a0,a4
ffffffffc02018e6:	00850693          	addi	a3,a0,8 # fffffffffffff008 <end+0x3fdf8b68>
ffffffffc02018ea:	4066b02f          	amoor.d	zero,t1,(a3)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018ee:	6190                	ld	a2,0(a1)
ffffffffc02018f0:	0785                	addi	a5,a5,1
        SetPageReserved(pages + i);
ffffffffc02018f2:	00083503          	ld	a0,0(a6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02018f6:	011606b3          	add	a3,a2,a7
ffffffffc02018fa:	02870713          	addi	a4,a4,40
ffffffffc02018fe:	fed7e3e3          	bltu	a5,a3,ffffffffc02018e4 <pmm_init+0xb6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201902:	00261693          	slli	a3,a2,0x2
ffffffffc0201906:	96b2                	add	a3,a3,a2
ffffffffc0201908:	fec007b7          	lui	a5,0xfec00
ffffffffc020190c:	97aa                	add	a5,a5,a0
ffffffffc020190e:	068e                	slli	a3,a3,0x3
ffffffffc0201910:	96be                	add	a3,a3,a5
ffffffffc0201912:	c02007b7          	lui	a5,0xc0200
ffffffffc0201916:	0af6e763          	bltu	a3,a5,ffffffffc02019c4 <pmm_init+0x196>
ffffffffc020191a:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020191c:	77fd                	lui	a5,0xfffff
ffffffffc020191e:	00fa75b3          	and	a1,s4,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201922:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201924:	04b6ee63          	bltu	a3,a1,ffffffffc0201980 <pmm_init+0x152>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201928:	601c                	ld	a5,0(s0)
ffffffffc020192a:	7b9c                	ld	a5,48(a5)
ffffffffc020192c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020192e:	00001517          	auipc	a0,0x1
ffffffffc0201932:	3f250513          	addi	a0,a0,1010 # ffffffffc0202d20 <default_pmm_manager+0x120>
ffffffffc0201936:	fa2fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020193a:	00003597          	auipc	a1,0x3
ffffffffc020193e:	6c658593          	addi	a1,a1,1734 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201942:	00005797          	auipc	a5,0x5
ffffffffc0201946:	b4b7b323          	sd	a1,-1210(a5) # ffffffffc0206488 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020194a:	c02007b7          	lui	a5,0xc0200
ffffffffc020194e:	0af5e363          	bltu	a1,a5,ffffffffc02019f4 <pmm_init+0x1c6>
ffffffffc0201952:	6090                	ld	a2,0(s1)
}
ffffffffc0201954:	7402                	ld	s0,32(sp)
ffffffffc0201956:	70a2                	ld	ra,40(sp)
ffffffffc0201958:	64e2                	ld	s1,24(sp)
ffffffffc020195a:	6942                	ld	s2,16(sp)
ffffffffc020195c:	69a2                	ld	s3,8(sp)
ffffffffc020195e:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201960:	40c58633          	sub	a2,a1,a2
ffffffffc0201964:	00005797          	auipc	a5,0x5
ffffffffc0201968:	b0c7be23          	sd	a2,-1252(a5) # ffffffffc0206480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020196c:	00001517          	auipc	a0,0x1
ffffffffc0201970:	3d450513          	addi	a0,a0,980 # ffffffffc0202d40 <default_pmm_manager+0x140>
}
ffffffffc0201974:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201976:	f62fe06f          	j	ffffffffc02000d8 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020197a:	c8000637          	lui	a2,0xc8000
ffffffffc020197e:	bf05                	j	ffffffffc02018ae <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201980:	6705                	lui	a4,0x1
ffffffffc0201982:	177d                	addi	a4,a4,-1
ffffffffc0201984:	96ba                	add	a3,a3,a4
ffffffffc0201986:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201988:	00c6d793          	srli	a5,a3,0xc
ffffffffc020198c:	02c7f063          	bgeu	a5,a2,ffffffffc02019ac <pmm_init+0x17e>
    pmm_manager->init_memmap(base, n);
ffffffffc0201990:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201992:	fff80737          	lui	a4,0xfff80
ffffffffc0201996:	973e                	add	a4,a4,a5
ffffffffc0201998:	00271793          	slli	a5,a4,0x2
ffffffffc020199c:	97ba                	add	a5,a5,a4
ffffffffc020199e:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02019a0:	8d95                	sub	a1,a1,a3
ffffffffc02019a2:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02019a4:	81b1                	srli	a1,a1,0xc
ffffffffc02019a6:	953e                	add	a0,a0,a5
ffffffffc02019a8:	9702                	jalr	a4
}
ffffffffc02019aa:	bfbd                	j	ffffffffc0201928 <pmm_init+0xfa>
        panic("pa2page called with invalid pa");
ffffffffc02019ac:	00001617          	auipc	a2,0x1
ffffffffc02019b0:	34460613          	addi	a2,a2,836 # ffffffffc0202cf0 <default_pmm_manager+0xf0>
ffffffffc02019b4:	06b00593          	li	a1,107
ffffffffc02019b8:	00001517          	auipc	a0,0x1
ffffffffc02019bc:	35850513          	addi	a0,a0,856 # ffffffffc0202d10 <default_pmm_manager+0x110>
ffffffffc02019c0:	a13fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02019c4:	00001617          	auipc	a2,0x1
ffffffffc02019c8:	30460613          	addi	a2,a2,772 # ffffffffc0202cc8 <default_pmm_manager+0xc8>
ffffffffc02019cc:	07100593          	li	a1,113
ffffffffc02019d0:	00001517          	auipc	a0,0x1
ffffffffc02019d4:	2a050513          	addi	a0,a0,672 # ffffffffc0202c70 <default_pmm_manager+0x70>
ffffffffc02019d8:	9fbfe0ef          	jal	ra,ffffffffc02003d2 <__panic>
        panic("DTB memory info not available");
ffffffffc02019dc:	00001617          	auipc	a2,0x1
ffffffffc02019e0:	27460613          	addi	a2,a2,628 # ffffffffc0202c50 <default_pmm_manager+0x50>
ffffffffc02019e4:	05a00593          	li	a1,90
ffffffffc02019e8:	00001517          	auipc	a0,0x1
ffffffffc02019ec:	28850513          	addi	a0,a0,648 # ffffffffc0202c70 <default_pmm_manager+0x70>
ffffffffc02019f0:	9e3fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02019f4:	86ae                	mv	a3,a1
ffffffffc02019f6:	00001617          	auipc	a2,0x1
ffffffffc02019fa:	2d260613          	addi	a2,a2,722 # ffffffffc0202cc8 <default_pmm_manager+0xc8>
ffffffffc02019fe:	08c00593          	li	a1,140
ffffffffc0201a02:	00001517          	auipc	a0,0x1
ffffffffc0201a06:	26e50513          	addi	a0,a0,622 # ffffffffc0202c70 <default_pmm_manager+0x70>
ffffffffc0201a0a:	9c9fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201a0e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201a0e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a12:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201a14:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a18:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a1a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a1e:	f022                	sd	s0,32(sp)
ffffffffc0201a20:	ec26                	sd	s1,24(sp)
ffffffffc0201a22:	e84a                	sd	s2,16(sp)
ffffffffc0201a24:	f406                	sd	ra,40(sp)
ffffffffc0201a26:	e44e                	sd	s3,8(sp)
ffffffffc0201a28:	84aa                	mv	s1,a0
ffffffffc0201a2a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a2c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201a30:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201a32:	03067e63          	bgeu	a2,a6,ffffffffc0201a6e <printnum+0x60>
ffffffffc0201a36:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201a38:	00805763          	blez	s0,ffffffffc0201a46 <printnum+0x38>
ffffffffc0201a3c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201a3e:	85ca                	mv	a1,s2
ffffffffc0201a40:	854e                	mv	a0,s3
ffffffffc0201a42:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201a44:	fc65                	bnez	s0,ffffffffc0201a3c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a46:	1a02                	slli	s4,s4,0x20
ffffffffc0201a48:	00001797          	auipc	a5,0x1
ffffffffc0201a4c:	33878793          	addi	a5,a5,824 # ffffffffc0202d80 <default_pmm_manager+0x180>
ffffffffc0201a50:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201a54:	9a3e                	add	s4,s4,a5
}
ffffffffc0201a56:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a58:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201a5c:	70a2                	ld	ra,40(sp)
ffffffffc0201a5e:	69a2                	ld	s3,8(sp)
ffffffffc0201a60:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a62:	85ca                	mv	a1,s2
ffffffffc0201a64:	87a6                	mv	a5,s1
}
ffffffffc0201a66:	6942                	ld	s2,16(sp)
ffffffffc0201a68:	64e2                	ld	s1,24(sp)
ffffffffc0201a6a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201a6c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201a6e:	03065633          	divu	a2,a2,a6
ffffffffc0201a72:	8722                	mv	a4,s0
ffffffffc0201a74:	f9bff0ef          	jal	ra,ffffffffc0201a0e <printnum>
ffffffffc0201a78:	b7f9                	j	ffffffffc0201a46 <printnum+0x38>

ffffffffc0201a7a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a7a:	7119                	addi	sp,sp,-128
ffffffffc0201a7c:	f4a6                	sd	s1,104(sp)
ffffffffc0201a7e:	f0ca                	sd	s2,96(sp)
ffffffffc0201a80:	ecce                	sd	s3,88(sp)
ffffffffc0201a82:	e8d2                	sd	s4,80(sp)
ffffffffc0201a84:	e4d6                	sd	s5,72(sp)
ffffffffc0201a86:	e0da                	sd	s6,64(sp)
ffffffffc0201a88:	fc5e                	sd	s7,56(sp)
ffffffffc0201a8a:	f06a                	sd	s10,32(sp)
ffffffffc0201a8c:	fc86                	sd	ra,120(sp)
ffffffffc0201a8e:	f8a2                	sd	s0,112(sp)
ffffffffc0201a90:	f862                	sd	s8,48(sp)
ffffffffc0201a92:	f466                	sd	s9,40(sp)
ffffffffc0201a94:	ec6e                	sd	s11,24(sp)
ffffffffc0201a96:	892a                	mv	s2,a0
ffffffffc0201a98:	84ae                	mv	s1,a1
ffffffffc0201a9a:	8d32                	mv	s10,a2
ffffffffc0201a9c:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a9e:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201aa2:	5b7d                	li	s6,-1
ffffffffc0201aa4:	00001a97          	auipc	s5,0x1
ffffffffc0201aa8:	310a8a93          	addi	s5,s5,784 # ffffffffc0202db4 <default_pmm_manager+0x1b4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201aac:	00001b97          	auipc	s7,0x1
ffffffffc0201ab0:	4e4b8b93          	addi	s7,s7,1252 # ffffffffc0202f90 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ab4:	000d4503          	lbu	a0,0(s10)
ffffffffc0201ab8:	001d0413          	addi	s0,s10,1
ffffffffc0201abc:	01350a63          	beq	a0,s3,ffffffffc0201ad0 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201ac0:	c121                	beqz	a0,ffffffffc0201b00 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201ac2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ac4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201ac6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201ac8:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201acc:	ff351ae3          	bne	a0,s3,ffffffffc0201ac0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ad0:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201ad4:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201ad8:	4c81                	li	s9,0
ffffffffc0201ada:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201adc:	5c7d                	li	s8,-1
ffffffffc0201ade:	5dfd                	li	s11,-1
ffffffffc0201ae0:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201ae4:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ae6:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201aea:	0ff5f593          	zext.b	a1,a1
ffffffffc0201aee:	00140d13          	addi	s10,s0,1
ffffffffc0201af2:	04b56263          	bltu	a0,a1,ffffffffc0201b36 <vprintfmt+0xbc>
ffffffffc0201af6:	058a                	slli	a1,a1,0x2
ffffffffc0201af8:	95d6                	add	a1,a1,s5
ffffffffc0201afa:	4194                	lw	a3,0(a1)
ffffffffc0201afc:	96d6                	add	a3,a3,s5
ffffffffc0201afe:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201b00:	70e6                	ld	ra,120(sp)
ffffffffc0201b02:	7446                	ld	s0,112(sp)
ffffffffc0201b04:	74a6                	ld	s1,104(sp)
ffffffffc0201b06:	7906                	ld	s2,96(sp)
ffffffffc0201b08:	69e6                	ld	s3,88(sp)
ffffffffc0201b0a:	6a46                	ld	s4,80(sp)
ffffffffc0201b0c:	6aa6                	ld	s5,72(sp)
ffffffffc0201b0e:	6b06                	ld	s6,64(sp)
ffffffffc0201b10:	7be2                	ld	s7,56(sp)
ffffffffc0201b12:	7c42                	ld	s8,48(sp)
ffffffffc0201b14:	7ca2                	ld	s9,40(sp)
ffffffffc0201b16:	7d02                	ld	s10,32(sp)
ffffffffc0201b18:	6de2                	ld	s11,24(sp)
ffffffffc0201b1a:	6109                	addi	sp,sp,128
ffffffffc0201b1c:	8082                	ret
            padc = '0';
ffffffffc0201b1e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201b20:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b24:	846a                	mv	s0,s10
ffffffffc0201b26:	00140d13          	addi	s10,s0,1
ffffffffc0201b2a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b2e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b32:	fcb572e3          	bgeu	a0,a1,ffffffffc0201af6 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201b36:	85a6                	mv	a1,s1
ffffffffc0201b38:	02500513          	li	a0,37
ffffffffc0201b3c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201b3e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201b42:	8d22                	mv	s10,s0
ffffffffc0201b44:	f73788e3          	beq	a5,s3,ffffffffc0201ab4 <vprintfmt+0x3a>
ffffffffc0201b48:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201b4c:	1d7d                	addi	s10,s10,-1
ffffffffc0201b4e:	ff379de3          	bne	a5,s3,ffffffffc0201b48 <vprintfmt+0xce>
ffffffffc0201b52:	b78d                	j	ffffffffc0201ab4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201b54:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201b58:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b5c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b5e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b62:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b66:	02d86463          	bltu	a6,a3,ffffffffc0201b8e <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201b6a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b6e:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201b72:	0186873b          	addw	a4,a3,s8
ffffffffc0201b76:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b7a:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201b7c:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b80:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b82:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201b86:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b8a:	fed870e3          	bgeu	a6,a3,ffffffffc0201b6a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201b8e:	f40ddce3          	bgez	s11,ffffffffc0201ae6 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201b92:	8de2                	mv	s11,s8
ffffffffc0201b94:	5c7d                	li	s8,-1
ffffffffc0201b96:	bf81                	j	ffffffffc0201ae6 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201b98:	fffdc693          	not	a3,s11
ffffffffc0201b9c:	96fd                	srai	a3,a3,0x3f
ffffffffc0201b9e:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ba2:	00144603          	lbu	a2,1(s0)
ffffffffc0201ba6:	2d81                	sext.w	s11,s11
ffffffffc0201ba8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201baa:	bf35                	j	ffffffffc0201ae6 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201bac:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bb0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201bb4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bb6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201bb8:	bfd9                	j	ffffffffc0201b8e <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201bba:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bbc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bc0:	01174463          	blt	a4,a7,ffffffffc0201bc8 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201bc4:	1a088e63          	beqz	a7,ffffffffc0201d80 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201bc8:	000a3603          	ld	a2,0(s4)
ffffffffc0201bcc:	46c1                	li	a3,16
ffffffffc0201bce:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201bd0:	2781                	sext.w	a5,a5
ffffffffc0201bd2:	876e                	mv	a4,s11
ffffffffc0201bd4:	85a6                	mv	a1,s1
ffffffffc0201bd6:	854a                	mv	a0,s2
ffffffffc0201bd8:	e37ff0ef          	jal	ra,ffffffffc0201a0e <printnum>
            break;
ffffffffc0201bdc:	bde1                	j	ffffffffc0201ab4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201bde:	000a2503          	lw	a0,0(s4)
ffffffffc0201be2:	85a6                	mv	a1,s1
ffffffffc0201be4:	0a21                	addi	s4,s4,8
ffffffffc0201be6:	9902                	jalr	s2
            break;
ffffffffc0201be8:	b5f1                	j	ffffffffc0201ab4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201bea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201bf0:	01174463          	blt	a4,a7,ffffffffc0201bf8 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201bf4:	18088163          	beqz	a7,ffffffffc0201d76 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201bf8:	000a3603          	ld	a2,0(s4)
ffffffffc0201bfc:	46a9                	li	a3,10
ffffffffc0201bfe:	8a2e                	mv	s4,a1
ffffffffc0201c00:	bfc1                	j	ffffffffc0201bd0 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c02:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201c06:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c08:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c0a:	bdf1                	j	ffffffffc0201ae6 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201c0c:	85a6                	mv	a1,s1
ffffffffc0201c0e:	02500513          	li	a0,37
ffffffffc0201c12:	9902                	jalr	s2
            break;
ffffffffc0201c14:	b545                	j	ffffffffc0201ab4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c16:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201c1a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c1c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c1e:	b5e1                	j	ffffffffc0201ae6 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201c20:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c22:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c26:	01174463          	blt	a4,a7,ffffffffc0201c2e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201c2a:	14088163          	beqz	a7,ffffffffc0201d6c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201c2e:	000a3603          	ld	a2,0(s4)
ffffffffc0201c32:	46a1                	li	a3,8
ffffffffc0201c34:	8a2e                	mv	s4,a1
ffffffffc0201c36:	bf69                	j	ffffffffc0201bd0 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201c38:	03000513          	li	a0,48
ffffffffc0201c3c:	85a6                	mv	a1,s1
ffffffffc0201c3e:	e03e                	sd	a5,0(sp)
ffffffffc0201c40:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c42:	85a6                	mv	a1,s1
ffffffffc0201c44:	07800513          	li	a0,120
ffffffffc0201c48:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c4a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201c4c:	6782                	ld	a5,0(sp)
ffffffffc0201c4e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c50:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201c54:	bfb5                	j	ffffffffc0201bd0 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c56:	000a3403          	ld	s0,0(s4)
ffffffffc0201c5a:	008a0713          	addi	a4,s4,8
ffffffffc0201c5e:	e03a                	sd	a4,0(sp)
ffffffffc0201c60:	14040263          	beqz	s0,ffffffffc0201da4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201c64:	0fb05763          	blez	s11,ffffffffc0201d52 <vprintfmt+0x2d8>
ffffffffc0201c68:	02d00693          	li	a3,45
ffffffffc0201c6c:	0cd79163          	bne	a5,a3,ffffffffc0201d2e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c70:	00044783          	lbu	a5,0(s0)
ffffffffc0201c74:	0007851b          	sext.w	a0,a5
ffffffffc0201c78:	cf85                	beqz	a5,ffffffffc0201cb0 <vprintfmt+0x236>
ffffffffc0201c7a:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c7e:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c82:	000c4563          	bltz	s8,ffffffffc0201c8c <vprintfmt+0x212>
ffffffffc0201c86:	3c7d                	addiw	s8,s8,-1
ffffffffc0201c88:	036c0263          	beq	s8,s6,ffffffffc0201cac <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201c8c:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c8e:	0e0c8e63          	beqz	s9,ffffffffc0201d8a <vprintfmt+0x310>
ffffffffc0201c92:	3781                	addiw	a5,a5,-32
ffffffffc0201c94:	0ef47b63          	bgeu	s0,a5,ffffffffc0201d8a <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201c98:	03f00513          	li	a0,63
ffffffffc0201c9c:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c9e:	000a4783          	lbu	a5,0(s4)
ffffffffc0201ca2:	3dfd                	addiw	s11,s11,-1
ffffffffc0201ca4:	0a05                	addi	s4,s4,1
ffffffffc0201ca6:	0007851b          	sext.w	a0,a5
ffffffffc0201caa:	ffe1                	bnez	a5,ffffffffc0201c82 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201cac:	01b05963          	blez	s11,ffffffffc0201cbe <vprintfmt+0x244>
ffffffffc0201cb0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201cb2:	85a6                	mv	a1,s1
ffffffffc0201cb4:	02000513          	li	a0,32
ffffffffc0201cb8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201cba:	fe0d9be3          	bnez	s11,ffffffffc0201cb0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cbe:	6a02                	ld	s4,0(sp)
ffffffffc0201cc0:	bbd5                	j	ffffffffc0201ab4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201cc2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201cc4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201cc8:	01174463          	blt	a4,a7,ffffffffc0201cd0 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201ccc:	08088d63          	beqz	a7,ffffffffc0201d66 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201cd0:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201cd4:	0a044d63          	bltz	s0,ffffffffc0201d8e <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201cd8:	8622                	mv	a2,s0
ffffffffc0201cda:	8a66                	mv	s4,s9
ffffffffc0201cdc:	46a9                	li	a3,10
ffffffffc0201cde:	bdcd                	j	ffffffffc0201bd0 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201ce0:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201ce4:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201ce6:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201ce8:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201cec:	8fb5                	xor	a5,a5,a3
ffffffffc0201cee:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201cf2:	02d74163          	blt	a4,a3,ffffffffc0201d14 <vprintfmt+0x29a>
ffffffffc0201cf6:	00369793          	slli	a5,a3,0x3
ffffffffc0201cfa:	97de                	add	a5,a5,s7
ffffffffc0201cfc:	639c                	ld	a5,0(a5)
ffffffffc0201cfe:	cb99                	beqz	a5,ffffffffc0201d14 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201d00:	86be                	mv	a3,a5
ffffffffc0201d02:	00001617          	auipc	a2,0x1
ffffffffc0201d06:	0ae60613          	addi	a2,a2,174 # ffffffffc0202db0 <default_pmm_manager+0x1b0>
ffffffffc0201d0a:	85a6                	mv	a1,s1
ffffffffc0201d0c:	854a                	mv	a0,s2
ffffffffc0201d0e:	0ce000ef          	jal	ra,ffffffffc0201ddc <printfmt>
ffffffffc0201d12:	b34d                	j	ffffffffc0201ab4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201d14:	00001617          	auipc	a2,0x1
ffffffffc0201d18:	08c60613          	addi	a2,a2,140 # ffffffffc0202da0 <default_pmm_manager+0x1a0>
ffffffffc0201d1c:	85a6                	mv	a1,s1
ffffffffc0201d1e:	854a                	mv	a0,s2
ffffffffc0201d20:	0bc000ef          	jal	ra,ffffffffc0201ddc <printfmt>
ffffffffc0201d24:	bb41                	j	ffffffffc0201ab4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201d26:	00001417          	auipc	s0,0x1
ffffffffc0201d2a:	07240413          	addi	s0,s0,114 # ffffffffc0202d98 <default_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d2e:	85e2                	mv	a1,s8
ffffffffc0201d30:	8522                	mv	a0,s0
ffffffffc0201d32:	e43e                	sd	a5,8(sp)
ffffffffc0201d34:	200000ef          	jal	ra,ffffffffc0201f34 <strnlen>
ffffffffc0201d38:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201d3c:	01b05b63          	blez	s11,ffffffffc0201d52 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201d40:	67a2                	ld	a5,8(sp)
ffffffffc0201d42:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d46:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201d48:	85a6                	mv	a1,s1
ffffffffc0201d4a:	8552                	mv	a0,s4
ffffffffc0201d4c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d4e:	fe0d9ce3          	bnez	s11,ffffffffc0201d46 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d52:	00044783          	lbu	a5,0(s0)
ffffffffc0201d56:	00140a13          	addi	s4,s0,1
ffffffffc0201d5a:	0007851b          	sext.w	a0,a5
ffffffffc0201d5e:	d3a5                	beqz	a5,ffffffffc0201cbe <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201d60:	05e00413          	li	s0,94
ffffffffc0201d64:	bf39                	j	ffffffffc0201c82 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201d66:	000a2403          	lw	s0,0(s4)
ffffffffc0201d6a:	b7ad                	j	ffffffffc0201cd4 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201d6c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d70:	46a1                	li	a3,8
ffffffffc0201d72:	8a2e                	mv	s4,a1
ffffffffc0201d74:	bdb1                	j	ffffffffc0201bd0 <vprintfmt+0x156>
ffffffffc0201d76:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d7a:	46a9                	li	a3,10
ffffffffc0201d7c:	8a2e                	mv	s4,a1
ffffffffc0201d7e:	bd89                	j	ffffffffc0201bd0 <vprintfmt+0x156>
ffffffffc0201d80:	000a6603          	lwu	a2,0(s4)
ffffffffc0201d84:	46c1                	li	a3,16
ffffffffc0201d86:	8a2e                	mv	s4,a1
ffffffffc0201d88:	b5a1                	j	ffffffffc0201bd0 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201d8a:	9902                	jalr	s2
ffffffffc0201d8c:	bf09                	j	ffffffffc0201c9e <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201d8e:	85a6                	mv	a1,s1
ffffffffc0201d90:	02d00513          	li	a0,45
ffffffffc0201d94:	e03e                	sd	a5,0(sp)
ffffffffc0201d96:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d98:	6782                	ld	a5,0(sp)
ffffffffc0201d9a:	8a66                	mv	s4,s9
ffffffffc0201d9c:	40800633          	neg	a2,s0
ffffffffc0201da0:	46a9                	li	a3,10
ffffffffc0201da2:	b53d                	j	ffffffffc0201bd0 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201da4:	03b05163          	blez	s11,ffffffffc0201dc6 <vprintfmt+0x34c>
ffffffffc0201da8:	02d00693          	li	a3,45
ffffffffc0201dac:	f6d79de3          	bne	a5,a3,ffffffffc0201d26 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201db0:	00001417          	auipc	s0,0x1
ffffffffc0201db4:	fe840413          	addi	s0,s0,-24 # ffffffffc0202d98 <default_pmm_manager+0x198>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201db8:	02800793          	li	a5,40
ffffffffc0201dbc:	02800513          	li	a0,40
ffffffffc0201dc0:	00140a13          	addi	s4,s0,1
ffffffffc0201dc4:	bd6d                	j	ffffffffc0201c7e <vprintfmt+0x204>
ffffffffc0201dc6:	00001a17          	auipc	s4,0x1
ffffffffc0201dca:	fd3a0a13          	addi	s4,s4,-45 # ffffffffc0202d99 <default_pmm_manager+0x199>
ffffffffc0201dce:	02800513          	li	a0,40
ffffffffc0201dd2:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201dd6:	05e00413          	li	s0,94
ffffffffc0201dda:	b565                	j	ffffffffc0201c82 <vprintfmt+0x208>

ffffffffc0201ddc <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201ddc:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201dde:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201de2:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201de4:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201de6:	ec06                	sd	ra,24(sp)
ffffffffc0201de8:	f83a                	sd	a4,48(sp)
ffffffffc0201dea:	fc3e                	sd	a5,56(sp)
ffffffffc0201dec:	e0c2                	sd	a6,64(sp)
ffffffffc0201dee:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201df0:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201df2:	c89ff0ef          	jal	ra,ffffffffc0201a7a <vprintfmt>
}
ffffffffc0201df6:	60e2                	ld	ra,24(sp)
ffffffffc0201df8:	6161                	addi	sp,sp,80
ffffffffc0201dfa:	8082                	ret

ffffffffc0201dfc <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201dfc:	715d                	addi	sp,sp,-80
ffffffffc0201dfe:	e486                	sd	ra,72(sp)
ffffffffc0201e00:	e0a6                	sd	s1,64(sp)
ffffffffc0201e02:	fc4a                	sd	s2,56(sp)
ffffffffc0201e04:	f84e                	sd	s3,48(sp)
ffffffffc0201e06:	f452                	sd	s4,40(sp)
ffffffffc0201e08:	f056                	sd	s5,32(sp)
ffffffffc0201e0a:	ec5a                	sd	s6,24(sp)
ffffffffc0201e0c:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201e0e:	c901                	beqz	a0,ffffffffc0201e1e <readline+0x22>
ffffffffc0201e10:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201e12:	00001517          	auipc	a0,0x1
ffffffffc0201e16:	f9e50513          	addi	a0,a0,-98 # ffffffffc0202db0 <default_pmm_manager+0x1b0>
ffffffffc0201e1a:	abefe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
readline(const char *prompt) {
ffffffffc0201e1e:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e20:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201e22:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201e24:	4aa9                	li	s5,10
ffffffffc0201e26:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201e28:	00004b97          	auipc	s7,0x4
ffffffffc0201e2c:	218b8b93          	addi	s7,s7,536 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e30:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201e34:	b1cfe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201e38:	00054a63          	bltz	a0,ffffffffc0201e4c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e3c:	00a95a63          	bge	s2,a0,ffffffffc0201e50 <readline+0x54>
ffffffffc0201e40:	029a5263          	bge	s4,s1,ffffffffc0201e64 <readline+0x68>
        c = getchar();
ffffffffc0201e44:	b0cfe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201e48:	fe055ae3          	bgez	a0,ffffffffc0201e3c <readline+0x40>
            return NULL;
ffffffffc0201e4c:	4501                	li	a0,0
ffffffffc0201e4e:	a091                	j	ffffffffc0201e92 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201e50:	03351463          	bne	a0,s3,ffffffffc0201e78 <readline+0x7c>
ffffffffc0201e54:	e8a9                	bnez	s1,ffffffffc0201ea6 <readline+0xaa>
        c = getchar();
ffffffffc0201e56:	afafe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201e5a:	fe0549e3          	bltz	a0,ffffffffc0201e4c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e5e:	fea959e3          	bge	s2,a0,ffffffffc0201e50 <readline+0x54>
ffffffffc0201e62:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201e64:	e42a                	sd	a0,8(sp)
ffffffffc0201e66:	aa8fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i ++] = c;
ffffffffc0201e6a:	6522                	ld	a0,8(sp)
ffffffffc0201e6c:	009b87b3          	add	a5,s7,s1
ffffffffc0201e70:	2485                	addiw	s1,s1,1
ffffffffc0201e72:	00a78023          	sb	a0,0(a5)
ffffffffc0201e76:	bf7d                	j	ffffffffc0201e34 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201e78:	01550463          	beq	a0,s5,ffffffffc0201e80 <readline+0x84>
ffffffffc0201e7c:	fb651ce3          	bne	a0,s6,ffffffffc0201e34 <readline+0x38>
            cputchar(c);
ffffffffc0201e80:	a8efe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i] = '\0';
ffffffffc0201e84:	00004517          	auipc	a0,0x4
ffffffffc0201e88:	1bc50513          	addi	a0,a0,444 # ffffffffc0206040 <buf>
ffffffffc0201e8c:	94aa                	add	s1,s1,a0
ffffffffc0201e8e:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201e92:	60a6                	ld	ra,72(sp)
ffffffffc0201e94:	6486                	ld	s1,64(sp)
ffffffffc0201e96:	7962                	ld	s2,56(sp)
ffffffffc0201e98:	79c2                	ld	s3,48(sp)
ffffffffc0201e9a:	7a22                	ld	s4,40(sp)
ffffffffc0201e9c:	7a82                	ld	s5,32(sp)
ffffffffc0201e9e:	6b62                	ld	s6,24(sp)
ffffffffc0201ea0:	6bc2                	ld	s7,16(sp)
ffffffffc0201ea2:	6161                	addi	sp,sp,80
ffffffffc0201ea4:	8082                	ret
            cputchar(c);
ffffffffc0201ea6:	4521                	li	a0,8
ffffffffc0201ea8:	a66fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            i --;
ffffffffc0201eac:	34fd                	addiw	s1,s1,-1
ffffffffc0201eae:	b759                	j	ffffffffc0201e34 <readline+0x38>

ffffffffc0201eb0 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201eb0:	4781                	li	a5,0
ffffffffc0201eb2:	00004717          	auipc	a4,0x4
ffffffffc0201eb6:	16673703          	ld	a4,358(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201eba:	88ba                	mv	a7,a4
ffffffffc0201ebc:	852a                	mv	a0,a0
ffffffffc0201ebe:	85be                	mv	a1,a5
ffffffffc0201ec0:	863e                	mv	a2,a5
ffffffffc0201ec2:	00000073          	ecall
ffffffffc0201ec6:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201ec8:	8082                	ret

ffffffffc0201eca <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201eca:	4781                	li	a5,0
ffffffffc0201ecc:	00004717          	auipc	a4,0x4
ffffffffc0201ed0:	5cc73703          	ld	a4,1484(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201ed4:	88ba                	mv	a7,a4
ffffffffc0201ed6:	852a                	mv	a0,a0
ffffffffc0201ed8:	85be                	mv	a1,a5
ffffffffc0201eda:	863e                	mv	a2,a5
ffffffffc0201edc:	00000073          	ecall
ffffffffc0201ee0:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201ee2:	8082                	ret

ffffffffc0201ee4 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201ee4:	4501                	li	a0,0
ffffffffc0201ee6:	00004797          	auipc	a5,0x4
ffffffffc0201eea:	12a7b783          	ld	a5,298(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201eee:	88be                	mv	a7,a5
ffffffffc0201ef0:	852a                	mv	a0,a0
ffffffffc0201ef2:	85aa                	mv	a1,a0
ffffffffc0201ef4:	862a                	mv	a2,a0
ffffffffc0201ef6:	00000073          	ecall
ffffffffc0201efa:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201efc:	2501                	sext.w	a0,a0
ffffffffc0201efe:	8082                	ret

ffffffffc0201f00 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201f00:	4781                	li	a5,0
ffffffffc0201f02:	00004717          	auipc	a4,0x4
ffffffffc0201f06:	11e73703          	ld	a4,286(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201f0a:	88ba                	mv	a7,a4
ffffffffc0201f0c:	853e                	mv	a0,a5
ffffffffc0201f0e:	85be                	mv	a1,a5
ffffffffc0201f10:	863e                	mv	a2,a5
ffffffffc0201f12:	00000073          	ecall
ffffffffc0201f16:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201f18:	8082                	ret

ffffffffc0201f1a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201f1a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201f1e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201f20:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201f22:	cb81                	beqz	a5,ffffffffc0201f32 <strlen+0x18>
        cnt ++;
ffffffffc0201f24:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201f26:	00a707b3          	add	a5,a4,a0
ffffffffc0201f2a:	0007c783          	lbu	a5,0(a5)
ffffffffc0201f2e:	fbfd                	bnez	a5,ffffffffc0201f24 <strlen+0xa>
ffffffffc0201f30:	8082                	ret
    }
    return cnt;
}
ffffffffc0201f32:	8082                	ret

ffffffffc0201f34 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201f34:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f36:	e589                	bnez	a1,ffffffffc0201f40 <strnlen+0xc>
ffffffffc0201f38:	a811                	j	ffffffffc0201f4c <strnlen+0x18>
        cnt ++;
ffffffffc0201f3a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201f3c:	00f58863          	beq	a1,a5,ffffffffc0201f4c <strnlen+0x18>
ffffffffc0201f40:	00f50733          	add	a4,a0,a5
ffffffffc0201f44:	00074703          	lbu	a4,0(a4)
ffffffffc0201f48:	fb6d                	bnez	a4,ffffffffc0201f3a <strnlen+0x6>
ffffffffc0201f4a:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201f4c:	852e                	mv	a0,a1
ffffffffc0201f4e:	8082                	ret

ffffffffc0201f50 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f50:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f54:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f58:	cb89                	beqz	a5,ffffffffc0201f6a <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201f5a:	0505                	addi	a0,a0,1
ffffffffc0201f5c:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f5e:	fee789e3          	beq	a5,a4,ffffffffc0201f50 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f62:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201f66:	9d19                	subw	a0,a0,a4
ffffffffc0201f68:	8082                	ret
ffffffffc0201f6a:	4501                	li	a0,0
ffffffffc0201f6c:	bfed                	j	ffffffffc0201f66 <strcmp+0x16>

ffffffffc0201f6e <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f6e:	c20d                	beqz	a2,ffffffffc0201f90 <strncmp+0x22>
ffffffffc0201f70:	962e                	add	a2,a2,a1
ffffffffc0201f72:	a031                	j	ffffffffc0201f7e <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201f74:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f76:	00e79a63          	bne	a5,a4,ffffffffc0201f8a <strncmp+0x1c>
ffffffffc0201f7a:	00b60b63          	beq	a2,a1,ffffffffc0201f90 <strncmp+0x22>
ffffffffc0201f7e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201f82:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f84:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201f88:	f7f5                	bnez	a5,ffffffffc0201f74 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f8a:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201f8e:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f90:	4501                	li	a0,0
ffffffffc0201f92:	8082                	ret

ffffffffc0201f94 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f94:	00054783          	lbu	a5,0(a0)
ffffffffc0201f98:	c799                	beqz	a5,ffffffffc0201fa6 <strchr+0x12>
        if (*s == c) {
ffffffffc0201f9a:	00f58763          	beq	a1,a5,ffffffffc0201fa8 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201f9e:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201fa2:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201fa4:	fbfd                	bnez	a5,ffffffffc0201f9a <strchr+0x6>
    }
    return NULL;
ffffffffc0201fa6:	4501                	li	a0,0
}
ffffffffc0201fa8:	8082                	ret

ffffffffc0201faa <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201faa:	ca01                	beqz	a2,ffffffffc0201fba <memset+0x10>
ffffffffc0201fac:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201fae:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201fb0:	0785                	addi	a5,a5,1
ffffffffc0201fb2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201fb6:	fec79de3          	bne	a5,a2,ffffffffc0201fb0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201fba:	8082                	ret
