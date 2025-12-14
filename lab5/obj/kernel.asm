
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00097517          	auipc	a0,0x97
ffffffffc020004e:	1a650513          	addi	a0,a0,422 # ffffffffc02971f0 <buf>
ffffffffc0200052:	0009b617          	auipc	a2,0x9b
ffffffffc0200056:	64660613          	addi	a2,a2,1606 # ffffffffc029b698 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0209ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	025050ef          	jal	ffffffffc0205886 <memset>
    dtb_init();
ffffffffc0200066:	552000ef          	jal	ffffffffc02005b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	4dc000ef          	jal	ffffffffc0200546 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00006597          	auipc	a1,0x6
ffffffffc0200072:	84258593          	addi	a1,a1,-1982 # ffffffffc02058b0 <etext>
ffffffffc0200076:	00006517          	auipc	a0,0x6
ffffffffc020007a:	85a50513          	addi	a0,a0,-1958 # ffffffffc02058d0 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1a4000ef          	jal	ffffffffc0200226 <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	760020ef          	jal	ffffffffc02027e6 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	081000ef          	jal	ffffffffc020090a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	07f000ef          	jal	ffffffffc020090c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	24d030ef          	jal	ffffffffc0203ade <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	731040ef          	jal	ffffffffc0204fc6 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	45a000ef          	jal	ffffffffc02004f4 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	061000ef          	jal	ffffffffc02008fe <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	0ce050ef          	jal	ffffffffc0205170 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	7179                	addi	sp,sp,-48
ffffffffc02000a8:	f406                	sd	ra,40(sp)
ffffffffc02000aa:	f022                	sd	s0,32(sp)
ffffffffc02000ac:	ec26                	sd	s1,24(sp)
ffffffffc02000ae:	e84a                	sd	s2,16(sp)
ffffffffc02000b0:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000b2:	c901                	beqz	a0,ffffffffc02000c2 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000b4:	85aa                	mv	a1,a0
ffffffffc02000b6:	00006517          	auipc	a0,0x6
ffffffffc02000ba:	82250513          	addi	a0,a0,-2014 # ffffffffc02058d8 <etext+0x28>
ffffffffc02000be:	0d6000ef          	jal	ffffffffc0200194 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c2:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c4:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc02000c6:	00097997          	auipc	s3,0x97
ffffffffc02000ca:	12a98993          	addi	s3,s3,298 # ffffffffc02971f0 <buf>
        c = getchar();
ffffffffc02000ce:	148000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc02000d2:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d4:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d8:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000dc:	ff650693          	addi	a3,a0,-10
ffffffffc02000e0:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc02000e4:	02054963          	bltz	a0,ffffffffc0200116 <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e8:	02a95f63          	bge	s2,a0,ffffffffc0200126 <readline+0x80>
ffffffffc02000ec:	cf0d                	beqz	a4,ffffffffc0200126 <readline+0x80>
            cputchar(c);
ffffffffc02000ee:	0da000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i ++] = c;
ffffffffc02000f2:	009987b3          	add	a5,s3,s1
ffffffffc02000f6:	00878023          	sb	s0,0(a5)
ffffffffc02000fa:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc02000fc:	11a000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc0200100:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0200102:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200106:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc020010a:	ff650693          	addi	a3,a0,-10
ffffffffc020010e:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0200112:	fc055be3          	bgez	a0,ffffffffc02000e8 <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc0200116:	70a2                	ld	ra,40(sp)
ffffffffc0200118:	7402                	ld	s0,32(sp)
ffffffffc020011a:	64e2                	ld	s1,24(sp)
ffffffffc020011c:	6942                	ld	s2,16(sp)
ffffffffc020011e:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200120:	4501                	li	a0,0
}
ffffffffc0200122:	6145                	addi	sp,sp,48
ffffffffc0200124:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc0200126:	eb81                	bnez	a5,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc0200128:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc020012a:	00905663          	blez	s1,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc020012e:	09a000ef          	jal	ffffffffc02001c8 <cputchar>
            i --;
ffffffffc0200132:	34fd                	addiw	s1,s1,-1
ffffffffc0200134:	bf69                	j	ffffffffc02000ce <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc0200136:	c291                	beqz	a3,ffffffffc020013a <readline+0x94>
ffffffffc0200138:	fa59                	bnez	a2,ffffffffc02000ce <readline+0x28>
            cputchar(c);
ffffffffc020013a:	8522                	mv	a0,s0
ffffffffc020013c:	08c000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i] = '\0';
ffffffffc0200140:	00097517          	auipc	a0,0x97
ffffffffc0200144:	0b050513          	addi	a0,a0,176 # ffffffffc02971f0 <buf>
ffffffffc0200148:	94aa                	add	s1,s1,a0
ffffffffc020014a:	00048023          	sb	zero,0(s1)
}
ffffffffc020014e:	70a2                	ld	ra,40(sp)
ffffffffc0200150:	7402                	ld	s0,32(sp)
ffffffffc0200152:	64e2                	ld	s1,24(sp)
ffffffffc0200154:	6942                	ld	s2,16(sp)
ffffffffc0200156:	69a2                	ld	s3,8(sp)
ffffffffc0200158:	6145                	addi	sp,sp,48
ffffffffc020015a:	8082                	ret

ffffffffc020015c <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015c:	1101                	addi	sp,sp,-32
ffffffffc020015e:	ec06                	sd	ra,24(sp)
ffffffffc0200160:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200162:	3e6000ef          	jal	ffffffffc0200548 <cons_putc>
    (*cnt)++;
ffffffffc0200166:	65a2                	ld	a1,8(sp)
}
ffffffffc0200168:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc020016a:	419c                	lw	a5,0(a1)
ffffffffc020016c:	2785                	addiw	a5,a5,1
ffffffffc020016e:	c19c                	sw	a5,0(a1)
}
ffffffffc0200170:	6105                	addi	sp,sp,32
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe250513          	addi	a0,a0,-30 # ffffffffc020015c <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	2e4050ef          	jal	ffffffffc020546c <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40
{
ffffffffc020019a:	f42e                	sd	a1,40(sp)
ffffffffc020019c:	f832                	sd	a2,48(sp)
ffffffffc020019e:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a0:	862a                	mv	a2,a0
ffffffffc02001a2:	004c                	addi	a1,sp,4
ffffffffc02001a4:	00000517          	auipc	a0,0x0
ffffffffc02001a8:	fb850513          	addi	a0,a0,-72 # ffffffffc020015c <cputch>
ffffffffc02001ac:	869a                	mv	a3,t1
{
ffffffffc02001ae:	ec06                	sd	ra,24(sp)
ffffffffc02001b0:	e0ba                	sd	a4,64(sp)
ffffffffc02001b2:	e4be                	sd	a5,72(sp)
ffffffffc02001b4:	e8c2                	sd	a6,80(sp)
ffffffffc02001b6:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02001b8:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001bc:	2b0050ef          	jal	ffffffffc020546c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c0:	60e2                	ld	ra,24(sp)
ffffffffc02001c2:	4512                	lw	a0,4(sp)
ffffffffc02001c4:	6125                	addi	sp,sp,96
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001c8:	a641                	j	ffffffffc0200548 <cons_putc>

ffffffffc02001ca <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001ca:	1101                	addi	sp,sp,-32
ffffffffc02001cc:	e822                	sd	s0,16(sp)
ffffffffc02001ce:	ec06                	sd	ra,24(sp)
ffffffffc02001d0:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d2:	00054503          	lbu	a0,0(a0)
ffffffffc02001d6:	c51d                	beqz	a0,ffffffffc0200204 <cputs+0x3a>
ffffffffc02001d8:	e426                	sd	s1,8(sp)
ffffffffc02001da:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc02001dc:	4481                	li	s1,0
    cons_putc(c);
ffffffffc02001de:	36a000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e2:	00044503          	lbu	a0,0(s0)
ffffffffc02001e6:	0405                	addi	s0,s0,1
ffffffffc02001e8:	87a6                	mv	a5,s1
    (*cnt)++;
ffffffffc02001ea:	2485                	addiw	s1,s1,1
    while ((c = *str++) != '\0')
ffffffffc02001ec:	f96d                	bnez	a0,ffffffffc02001de <cputs+0x14>
    cons_putc(c);
ffffffffc02001ee:	4529                	li	a0,10
    (*cnt)++;
ffffffffc02001f0:	0027841b          	addiw	s0,a5,2
ffffffffc02001f4:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001f6:	352000ef          	jal	ffffffffc0200548 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fa:	60e2                	ld	ra,24(sp)
ffffffffc02001fc:	8522                	mv	a0,s0
ffffffffc02001fe:	6442                	ld	s0,16(sp)
ffffffffc0200200:	6105                	addi	sp,sp,32
ffffffffc0200202:	8082                	ret
    cons_putc(c);
ffffffffc0200204:	4529                	li	a0,10
ffffffffc0200206:	342000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc020020a:	4405                	li	s0,1
}
ffffffffc020020c:	60e2                	ld	ra,24(sp)
ffffffffc020020e:	8522                	mv	a0,s0
ffffffffc0200210:	6442                	ld	s0,16(sp)
ffffffffc0200212:	6105                	addi	sp,sp,32
ffffffffc0200214:	8082                	ret

ffffffffc0200216 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200216:	1141                	addi	sp,sp,-16
ffffffffc0200218:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020021a:	362000ef          	jal	ffffffffc020057c <cons_getc>
ffffffffc020021e:	dd75                	beqz	a0,ffffffffc020021a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200220:	60a2                	ld	ra,8(sp)
ffffffffc0200222:	0141                	addi	sp,sp,16
ffffffffc0200224:	8082                	ret

ffffffffc0200226 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc0200226:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	00005517          	auipc	a0,0x5
ffffffffc020022c:	6b850513          	addi	a0,a0,1720 # ffffffffc02058e0 <etext+0x30>
{
ffffffffc0200230:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200232:	f63ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200236:	00000597          	auipc	a1,0x0
ffffffffc020023a:	e1458593          	addi	a1,a1,-492 # ffffffffc020004a <kern_init>
ffffffffc020023e:	00005517          	auipc	a0,0x5
ffffffffc0200242:	6c250513          	addi	a0,a0,1730 # ffffffffc0205900 <etext+0x50>
ffffffffc0200246:	f4fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024a:	00005597          	auipc	a1,0x5
ffffffffc020024e:	66658593          	addi	a1,a1,1638 # ffffffffc02058b0 <etext>
ffffffffc0200252:	00005517          	auipc	a0,0x5
ffffffffc0200256:	6ce50513          	addi	a0,a0,1742 # ffffffffc0205920 <etext+0x70>
ffffffffc020025a:	f3bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020025e:	00097597          	auipc	a1,0x97
ffffffffc0200262:	f9258593          	addi	a1,a1,-110 # ffffffffc02971f0 <buf>
ffffffffc0200266:	00005517          	auipc	a0,0x5
ffffffffc020026a:	6da50513          	addi	a0,a0,1754 # ffffffffc0205940 <etext+0x90>
ffffffffc020026e:	f27ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200272:	0009b597          	auipc	a1,0x9b
ffffffffc0200276:	42658593          	addi	a1,a1,1062 # ffffffffc029b698 <end>
ffffffffc020027a:	00005517          	auipc	a0,0x5
ffffffffc020027e:	6e650513          	addi	a0,a0,1766 # ffffffffc0205960 <etext+0xb0>
ffffffffc0200282:	f13ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200286:	00000717          	auipc	a4,0x0
ffffffffc020028a:	dc470713          	addi	a4,a4,-572 # ffffffffc020004a <kern_init>
ffffffffc020028e:	0009c797          	auipc	a5,0x9c
ffffffffc0200292:	80978793          	addi	a5,a5,-2039 # ffffffffc029ba97 <end+0x3ff>
ffffffffc0200296:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200298:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020029c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029e:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a2:	95be                	add	a1,a1,a5
ffffffffc02002a4:	85a9                	srai	a1,a1,0xa
ffffffffc02002a6:	00005517          	auipc	a0,0x5
ffffffffc02002aa:	6da50513          	addi	a0,a0,1754 # ffffffffc0205980 <etext+0xd0>
}
ffffffffc02002ae:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b0:	b5d5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002b2 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b4:	00005617          	auipc	a2,0x5
ffffffffc02002b8:	6fc60613          	addi	a2,a2,1788 # ffffffffc02059b0 <etext+0x100>
ffffffffc02002bc:	04f00593          	li	a1,79
ffffffffc02002c0:	00005517          	auipc	a0,0x5
ffffffffc02002c4:	70850513          	addi	a0,a0,1800 # ffffffffc02059c8 <etext+0x118>
{
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ca:	17c000ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02002ce <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002ce:	1101                	addi	sp,sp,-32
ffffffffc02002d0:	e822                	sd	s0,16(sp)
ffffffffc02002d2:	e426                	sd	s1,8(sp)
ffffffffc02002d4:	ec06                	sd	ra,24(sp)
ffffffffc02002d6:	00007417          	auipc	s0,0x7
ffffffffc02002da:	3da40413          	addi	s0,s0,986 # ffffffffc02076b0 <commands>
ffffffffc02002de:	00007497          	auipc	s1,0x7
ffffffffc02002e2:	41a48493          	addi	s1,s1,1050 # ffffffffc02076f8 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	6410                	ld	a2,8(s0)
ffffffffc02002e8:	600c                	ld	a1,0(s0)
ffffffffc02002ea:	00005517          	auipc	a0,0x5
ffffffffc02002ee:	6f650513          	addi	a0,a0,1782 # ffffffffc02059e0 <etext+0x130>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f2:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002f4:	ea1ff0ef          	jal	ffffffffc0200194 <cprintf>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f8:	fe9417e3          	bne	s0,s1,ffffffffc02002e6 <mon_help+0x18>
    }
    return 0;
}
ffffffffc02002fc:	60e2                	ld	ra,24(sp)
ffffffffc02002fe:	6442                	ld	s0,16(sp)
ffffffffc0200300:	64a2                	ld	s1,8(sp)
ffffffffc0200302:	4501                	li	a0,0
ffffffffc0200304:	6105                	addi	sp,sp,32
ffffffffc0200306:	8082                	ret

ffffffffc0200308 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200308:	1141                	addi	sp,sp,-16
ffffffffc020030a:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020030c:	f1bff0ef          	jal	ffffffffc0200226 <print_kerninfo>
    return 0;
}
ffffffffc0200310:	60a2                	ld	ra,8(sp)
ffffffffc0200312:	4501                	li	a0,0
ffffffffc0200314:	0141                	addi	sp,sp,16
ffffffffc0200316:	8082                	ret

ffffffffc0200318 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200318:	1141                	addi	sp,sp,-16
ffffffffc020031a:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020031c:	f97ff0ef          	jal	ffffffffc02002b2 <print_stackframe>
    return 0;
}
ffffffffc0200320:	60a2                	ld	ra,8(sp)
ffffffffc0200322:	4501                	li	a0,0
ffffffffc0200324:	0141                	addi	sp,sp,16
ffffffffc0200326:	8082                	ret

ffffffffc0200328 <kmonitor>:
{
ffffffffc0200328:	7131                	addi	sp,sp,-192
ffffffffc020032a:	e952                	sd	s4,144(sp)
ffffffffc020032c:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032e:	00005517          	auipc	a0,0x5
ffffffffc0200332:	6c250513          	addi	a0,a0,1730 # ffffffffc02059f0 <etext+0x140>
{
ffffffffc0200336:	fd06                	sd	ra,184(sp)
ffffffffc0200338:	f922                	sd	s0,176(sp)
ffffffffc020033a:	f526                	sd	s1,168(sp)
ffffffffc020033c:	ed4e                	sd	s3,152(sp)
ffffffffc020033e:	e556                	sd	s5,136(sp)
ffffffffc0200340:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200342:	e53ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200346:	00005517          	auipc	a0,0x5
ffffffffc020034a:	6d250513          	addi	a0,a0,1746 # ffffffffc0205a18 <etext+0x168>
ffffffffc020034e:	e47ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc0200352:	000a0563          	beqz	s4,ffffffffc020035c <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc0200356:	8552                	mv	a0,s4
ffffffffc0200358:	79c000ef          	jal	ffffffffc0200af4 <print_trapframe>
ffffffffc020035c:	00007a97          	auipc	s5,0x7
ffffffffc0200360:	354a8a93          	addi	s5,s5,852 # ffffffffc02076b0 <commands>
        if (argc == MAXARGS - 1)
ffffffffc0200364:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL)
ffffffffc0200366:	00005517          	auipc	a0,0x5
ffffffffc020036a:	6da50513          	addi	a0,a0,1754 # ffffffffc0205a40 <etext+0x190>
ffffffffc020036e:	d39ff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc0200372:	842a                	mv	s0,a0
ffffffffc0200374:	d96d                	beqz	a0,ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200376:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020037a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020037c:	e99d                	bnez	a1,ffffffffc02003b2 <kmonitor+0x8a>
    int argc = 0;
ffffffffc020037e:	8b26                	mv	s6,s1
    if (argc == 0)
ffffffffc0200380:	fe0b03e3          	beqz	s6,ffffffffc0200366 <kmonitor+0x3e>
ffffffffc0200384:	00007497          	auipc	s1,0x7
ffffffffc0200388:	32c48493          	addi	s1,s1,812 # ffffffffc02076b0 <commands>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020038c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc020038e:	6582                	ld	a1,0(sp)
ffffffffc0200390:	6088                	ld	a0,0(s1)
ffffffffc0200392:	486050ef          	jal	ffffffffc0205818 <strcmp>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc0200396:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc0200398:	c149                	beqz	a0,ffffffffc020041a <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020039a:	2405                	addiw	s0,s0,1
ffffffffc020039c:	04e1                	addi	s1,s1,24
ffffffffc020039e:	fef418e3          	bne	s0,a5,ffffffffc020038e <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003a2:	6582                	ld	a1,0(sp)
ffffffffc02003a4:	00005517          	auipc	a0,0x5
ffffffffc02003a8:	6cc50513          	addi	a0,a0,1740 # ffffffffc0205a70 <etext+0x1c0>
ffffffffc02003ac:	de9ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc02003b0:	bf5d                	j	ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003b2:	00005517          	auipc	a0,0x5
ffffffffc02003b6:	69650513          	addi	a0,a0,1686 # ffffffffc0205a48 <etext+0x198>
ffffffffc02003ba:	4ba050ef          	jal	ffffffffc0205874 <strchr>
ffffffffc02003be:	c901                	beqz	a0,ffffffffc02003ce <kmonitor+0xa6>
ffffffffc02003c0:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc02003c4:	00040023          	sb	zero,0(s0)
ffffffffc02003c8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ca:	d9d5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003cc:	b7dd                	j	ffffffffc02003b2 <kmonitor+0x8a>
        if (*buf == '\0')
ffffffffc02003ce:	00044783          	lbu	a5,0(s0)
ffffffffc02003d2:	d7d5                	beqz	a5,ffffffffc020037e <kmonitor+0x56>
        if (argc == MAXARGS - 1)
ffffffffc02003d4:	03348b63          	beq	s1,s3,ffffffffc020040a <kmonitor+0xe2>
        argv[argc++] = buf;
ffffffffc02003d8:	00349793          	slli	a5,s1,0x3
ffffffffc02003dc:	978a                	add	a5,a5,sp
ffffffffc02003de:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e0:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc02003e4:	2485                	addiw	s1,s1,1
ffffffffc02003e6:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e8:	e591                	bnez	a1,ffffffffc02003f4 <kmonitor+0xcc>
ffffffffc02003ea:	bf59                	j	ffffffffc0200380 <kmonitor+0x58>
ffffffffc02003ec:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc02003f0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003f2:	d5d1                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003f4:	00005517          	auipc	a0,0x5
ffffffffc02003f8:	65450513          	addi	a0,a0,1620 # ffffffffc0205a48 <etext+0x198>
ffffffffc02003fc:	478050ef          	jal	ffffffffc0205874 <strchr>
ffffffffc0200400:	d575                	beqz	a0,ffffffffc02003ec <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200402:	00044583          	lbu	a1,0(s0)
ffffffffc0200406:	dda5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc0200408:	b76d                	j	ffffffffc02003b2 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040a:	45c1                	li	a1,16
ffffffffc020040c:	00005517          	auipc	a0,0x5
ffffffffc0200410:	64450513          	addi	a0,a0,1604 # ffffffffc0205a50 <etext+0x1a0>
ffffffffc0200414:	d81ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200418:	b7c1                	j	ffffffffc02003d8 <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041a:	00141793          	slli	a5,s0,0x1
ffffffffc020041e:	97a2                	add	a5,a5,s0
ffffffffc0200420:	078e                	slli	a5,a5,0x3
ffffffffc0200422:	97d6                	add	a5,a5,s5
ffffffffc0200424:	6b9c                	ld	a5,16(a5)
ffffffffc0200426:	fffb051b          	addiw	a0,s6,-1
ffffffffc020042a:	8652                	mv	a2,s4
ffffffffc020042c:	002c                	addi	a1,sp,8
ffffffffc020042e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200430:	f2055be3          	bgez	a0,ffffffffc0200366 <kmonitor+0x3e>
}
ffffffffc0200434:	70ea                	ld	ra,184(sp)
ffffffffc0200436:	744a                	ld	s0,176(sp)
ffffffffc0200438:	74aa                	ld	s1,168(sp)
ffffffffc020043a:	69ea                	ld	s3,152(sp)
ffffffffc020043c:	6a4a                	ld	s4,144(sp)
ffffffffc020043e:	6aaa                	ld	s5,136(sp)
ffffffffc0200440:	6b0a                	ld	s6,128(sp)
ffffffffc0200442:	6129                	addi	sp,sp,192
ffffffffc0200444:	8082                	ret

ffffffffc0200446 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc0200446:	0009b317          	auipc	t1,0x9b
ffffffffc020044a:	1d233303          	ld	t1,466(t1) # ffffffffc029b618 <is_panic>
{
ffffffffc020044e:	715d                	addi	sp,sp,-80
ffffffffc0200450:	ec06                	sd	ra,24(sp)
ffffffffc0200452:	f436                	sd	a3,40(sp)
ffffffffc0200454:	f83a                	sd	a4,48(sp)
ffffffffc0200456:	fc3e                	sd	a5,56(sp)
ffffffffc0200458:	e0c2                	sd	a6,64(sp)
ffffffffc020045a:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc020045c:	02031e63          	bnez	t1,ffffffffc0200498 <__panic+0x52>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200460:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200462:	103c                	addi	a5,sp,40
ffffffffc0200464:	e822                	sd	s0,16(sp)
ffffffffc0200466:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200468:	862e                	mv	a2,a1
ffffffffc020046a:	85aa                	mv	a1,a0
ffffffffc020046c:	00005517          	auipc	a0,0x5
ffffffffc0200470:	6ac50513          	addi	a0,a0,1708 # ffffffffc0205b18 <etext+0x268>
    is_panic = 1;
ffffffffc0200474:	0009b697          	auipc	a3,0x9b
ffffffffc0200478:	1ae6b223          	sd	a4,420(a3) # ffffffffc029b618 <is_panic>
    va_start(ap, fmt);
ffffffffc020047c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020047e:	d17ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200482:	65a2                	ld	a1,8(sp)
ffffffffc0200484:	8522                	mv	a0,s0
ffffffffc0200486:	cefff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020048a:	00005517          	auipc	a0,0x5
ffffffffc020048e:	6ae50513          	addi	a0,a0,1710 # ffffffffc0205b38 <etext+0x288>
ffffffffc0200492:	d03ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200496:	6442                	ld	s0,16(sp)
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200498:	4501                	li	a0,0
ffffffffc020049a:	4581                	li	a1,0
ffffffffc020049c:	4601                	li	a2,0
ffffffffc020049e:	48a1                	li	a7,8
ffffffffc02004a0:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004a4:	460000ef          	jal	ffffffffc0200904 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004a8:	4501                	li	a0,0
ffffffffc02004aa:	e7fff0ef          	jal	ffffffffc0200328 <kmonitor>
    while (1)
ffffffffc02004ae:	bfed                	j	ffffffffc02004a8 <__panic+0x62>

ffffffffc02004b0 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004b0:	715d                	addi	sp,sp,-80
ffffffffc02004b2:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	02810313          	addi	t1,sp,40
{
ffffffffc02004b8:	8432                	mv	s0,a2
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004ba:	862e                	mv	a2,a1
ffffffffc02004bc:	85aa                	mv	a1,a0
ffffffffc02004be:	00005517          	auipc	a0,0x5
ffffffffc02004c2:	68250513          	addi	a0,a0,1666 # ffffffffc0205b40 <etext+0x290>
{
ffffffffc02004c6:	ec06                	sd	ra,24(sp)
ffffffffc02004c8:	f436                	sd	a3,40(sp)
ffffffffc02004ca:	f83a                	sd	a4,48(sp)
ffffffffc02004cc:	fc3e                	sd	a5,56(sp)
ffffffffc02004ce:	e0c2                	sd	a6,64(sp)
ffffffffc02004d0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02004d2:	e41a                	sd	t1,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004d4:	cc1ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004d8:	65a2                	ld	a1,8(sp)
ffffffffc02004da:	8522                	mv	a0,s0
ffffffffc02004dc:	c99ff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004e0:	00005517          	auipc	a0,0x5
ffffffffc02004e4:	65850513          	addi	a0,a0,1624 # ffffffffc0205b38 <etext+0x288>
ffffffffc02004e8:	cadff0ef          	jal	ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc02004ec:	60e2                	ld	ra,24(sp)
ffffffffc02004ee:	6442                	ld	s0,16(sp)
ffffffffc02004f0:	6161                	addi	sp,sp,80
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004f4:	67e1                	lui	a5,0x18
ffffffffc02004f6:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xe4e8>
ffffffffc02004fa:	0009b717          	auipc	a4,0x9b
ffffffffc02004fe:	12f73323          	sd	a5,294(a4) # ffffffffc029b620 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200502:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200506:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200508:	953e                	add	a0,a0,a5
ffffffffc020050a:	4601                	li	a2,0
ffffffffc020050c:	4881                	li	a7,0
ffffffffc020050e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200512:	02000793          	li	a5,32
ffffffffc0200516:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020051a:	00005517          	auipc	a0,0x5
ffffffffc020051e:	64650513          	addi	a0,a0,1606 # ffffffffc0205b60 <etext+0x2b0>
    ticks = 0;
ffffffffc0200522:	0009b797          	auipc	a5,0x9b
ffffffffc0200526:	1007b323          	sd	zero,262(a5) # ffffffffc029b628 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020052a:	b1ad                	j	ffffffffc0200194 <cprintf>

ffffffffc020052c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020052c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200530:	0009b797          	auipc	a5,0x9b
ffffffffc0200534:	0f07b783          	ld	a5,240(a5) # ffffffffc029b620 <timebase>
ffffffffc0200538:	4581                	li	a1,0
ffffffffc020053a:	4601                	li	a2,0
ffffffffc020053c:	953e                	add	a0,a0,a5
ffffffffc020053e:	4881                	li	a7,0
ffffffffc0200540:	00000073          	ecall
ffffffffc0200544:	8082                	ret

ffffffffc0200546 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200546:	8082                	ret

ffffffffc0200548 <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200548:	100027f3          	csrr	a5,sstatus
ffffffffc020054c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020054e:	0ff57513          	zext.b	a0,a0
ffffffffc0200552:	e799                	bnez	a5,ffffffffc0200560 <cons_putc+0x18>
ffffffffc0200554:	4581                	li	a1,0
ffffffffc0200556:	4601                	li	a2,0
ffffffffc0200558:	4885                	li	a7,1
ffffffffc020055a:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc020055e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200560:	1101                	addi	sp,sp,-32
ffffffffc0200562:	ec06                	sd	ra,24(sp)
ffffffffc0200564:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200566:	39e000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020056a:	6522                	ld	a0,8(sp)
ffffffffc020056c:	4581                	li	a1,0
ffffffffc020056e:	4601                	li	a2,0
ffffffffc0200570:	4885                	li	a7,1
ffffffffc0200572:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200576:	60e2                	ld	ra,24(sp)
ffffffffc0200578:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc020057a:	a651                	j	ffffffffc02008fe <intr_enable>

ffffffffc020057c <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020057c:	100027f3          	csrr	a5,sstatus
ffffffffc0200580:	8b89                	andi	a5,a5,2
ffffffffc0200582:	eb89                	bnez	a5,ffffffffc0200594 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200584:	4501                	li	a0,0
ffffffffc0200586:	4581                	li	a1,0
ffffffffc0200588:	4601                	li	a2,0
ffffffffc020058a:	4889                	li	a7,2
ffffffffc020058c:	00000073          	ecall
ffffffffc0200590:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200592:	8082                	ret
int cons_getc(void) {
ffffffffc0200594:	1101                	addi	sp,sp,-32
ffffffffc0200596:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200598:	36c000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020059c:	4501                	li	a0,0
ffffffffc020059e:	4581                	li	a1,0
ffffffffc02005a0:	4601                	li	a2,0
ffffffffc02005a2:	4889                	li	a7,2
ffffffffc02005a4:	00000073          	ecall
ffffffffc02005a8:	2501                	sext.w	a0,a0
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ac:	352000ef          	jal	ffffffffc02008fe <intr_enable>
}
ffffffffc02005b0:	60e2                	ld	ra,24(sp)
ffffffffc02005b2:	6522                	ld	a0,8(sp)
ffffffffc02005b4:	6105                	addi	sp,sp,32
ffffffffc02005b6:	8082                	ret

ffffffffc02005b8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005b8:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc02005ba:	00005517          	auipc	a0,0x5
ffffffffc02005be:	5c650513          	addi	a0,a0,1478 # ffffffffc0205b80 <etext+0x2d0>
void dtb_init(void) {
ffffffffc02005c2:	f406                	sd	ra,40(sp)
ffffffffc02005c4:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c6:	bcfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005ca:	0000b597          	auipc	a1,0xb
ffffffffc02005ce:	a365b583          	ld	a1,-1482(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc02005d2:	00005517          	auipc	a0,0x5
ffffffffc02005d6:	5be50513          	addi	a0,a0,1470 # ffffffffc0205b90 <etext+0x2e0>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005da:	0000b417          	auipc	s0,0xb
ffffffffc02005de:	a2e40413          	addi	s0,s0,-1490 # ffffffffc020b008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005e2:	bb3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e6:	600c                	ld	a1,0(s0)
ffffffffc02005e8:	00005517          	auipc	a0,0x5
ffffffffc02005ec:	5b850513          	addi	a0,a0,1464 # ffffffffc0205ba0 <etext+0x2f0>
ffffffffc02005f0:	ba5ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005f4:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f6:	00005517          	auipc	a0,0x5
ffffffffc02005fa:	5c250513          	addi	a0,a0,1474 # ffffffffc0205bb8 <etext+0x308>
    if (boot_dtb == 0) {
ffffffffc02005fe:	10070163          	beqz	a4,ffffffffc0200700 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200602:	57f5                	li	a5,-3
ffffffffc0200604:	07fa                	slli	a5,a5,0x1e
ffffffffc0200606:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200608:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020060a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020060e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfe44855>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200612:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200616:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020061e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200622:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200628:	8e49                	or	a2,a2,a0
ffffffffc020062a:	0ff7f793          	zext.b	a5,a5
ffffffffc020062e:	8dd1                	or	a1,a1,a2
ffffffffc0200630:	07a2                	slli	a5,a5,0x8
ffffffffc0200632:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200634:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc0200638:	0cd59863          	bne	a1,a3,ffffffffc0200708 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020063c:	4710                	lw	a2,8(a4)
ffffffffc020063e:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200640:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200642:	0086541b          	srliw	s0,a2,0x8
ffffffffc0200646:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	01865e1b          	srliw	t3,a2,0x18
ffffffffc020064e:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200652:	0186151b          	slliw	a0,a2,0x18
ffffffffc0200656:	0186959b          	slliw	a1,a3,0x18
ffffffffc020065a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200662:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200666:	0106d69b          	srliw	a3,a3,0x10
ffffffffc020066a:	01c56533          	or	a0,a0,t3
ffffffffc020066e:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200672:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200676:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067e:	0ff6f693          	zext.b	a3,a3
ffffffffc0200682:	8c49                	or	s0,s0,a0
ffffffffc0200684:	0622                	slli	a2,a2,0x8
ffffffffc0200686:	8fcd                	or	a5,a5,a1
ffffffffc0200688:	06a2                	slli	a3,a3,0x8
ffffffffc020068a:	8c51                	or	s0,s0,a2
ffffffffc020068c:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020068e:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200690:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200692:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200694:	9381                	srli	a5,a5,0x20
ffffffffc0200696:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200698:	4301                	li	t1,0
        switch (token) {
ffffffffc020069a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020069c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020069e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc02006a2:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a4:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006aa:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ae:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	8ed1                	or	a3,a3,a2
ffffffffc02006c0:	0ff77713          	zext.b	a4,a4
ffffffffc02006c4:	8fd5                	or	a5,a5,a3
ffffffffc02006c6:	0722                	slli	a4,a4,0x8
ffffffffc02006c8:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc02006ca:	05178763          	beq	a5,a7,ffffffffc0200718 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ce:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc02006d0:	00f8e963          	bltu	a7,a5,ffffffffc02006e2 <dtb_init+0x12a>
ffffffffc02006d4:	07c78d63          	beq	a5,t3,ffffffffc020074e <dtb_init+0x196>
ffffffffc02006d8:	4709                	li	a4,2
ffffffffc02006da:	00e79763          	bne	a5,a4,ffffffffc02006e8 <dtb_init+0x130>
ffffffffc02006de:	4301                	li	t1,0
ffffffffc02006e0:	b7d1                	j	ffffffffc02006a4 <dtb_init+0xec>
ffffffffc02006e2:	4711                	li	a4,4
ffffffffc02006e4:	fce780e3          	beq	a5,a4,ffffffffc02006a4 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006e8:	00005517          	auipc	a0,0x5
ffffffffc02006ec:	59850513          	addi	a0,a0,1432 # ffffffffc0205c80 <etext+0x3d0>
ffffffffc02006f0:	aa5ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f4:	64e2                	ld	s1,24(sp)
ffffffffc02006f6:	6942                	ld	s2,16(sp)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	5c050513          	addi	a0,a0,1472 # ffffffffc0205cb8 <etext+0x408>
}
ffffffffc0200700:	7402                	ld	s0,32(sp)
ffffffffc0200702:	70a2                	ld	ra,40(sp)
ffffffffc0200704:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200706:	b479                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200708:	7402                	ld	s0,32(sp)
ffffffffc020070a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020070c:	00005517          	auipc	a0,0x5
ffffffffc0200710:	4cc50513          	addi	a0,a0,1228 # ffffffffc0205bd8 <etext+0x328>
}
ffffffffc0200714:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200716:	bcbd                	j	ffffffffc0200194 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200718:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020071e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200732:	8ed1                	or	a3,a3,a2
ffffffffc0200734:	0ff77713          	zext.b	a4,a4
ffffffffc0200738:	8fd5                	or	a5,a5,a3
ffffffffc020073a:	0722                	slli	a4,a4,0x8
ffffffffc020073c:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020073e:	04031463          	bnez	t1,ffffffffc0200786 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200742:	1782                	slli	a5,a5,0x20
ffffffffc0200744:	9381                	srli	a5,a5,0x20
ffffffffc0200746:	043d                	addi	s0,s0,15
ffffffffc0200748:	943e                	add	s0,s0,a5
ffffffffc020074a:	9871                	andi	s0,s0,-4
                break;
ffffffffc020074c:	bfa1                	j	ffffffffc02006a4 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc020074e:	8522                	mv	a0,s0
ffffffffc0200750:	e01a                	sd	t1,0(sp)
ffffffffc0200752:	080050ef          	jal	ffffffffc02057d2 <strlen>
ffffffffc0200756:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200758:	4619                	li	a2,6
ffffffffc020075a:	8522                	mv	a0,s0
ffffffffc020075c:	00005597          	auipc	a1,0x5
ffffffffc0200760:	4a458593          	addi	a1,a1,1188 # ffffffffc0205c00 <etext+0x350>
ffffffffc0200764:	0e8050ef          	jal	ffffffffc020584c <strncmp>
ffffffffc0200768:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020076a:	0411                	addi	s0,s0,4
ffffffffc020076c:	0004879b          	sext.w	a5,s1
ffffffffc0200770:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200772:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200776:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200778:	00a36333          	or	t1,t1,a0
                break;
ffffffffc020077c:	00ff0837          	lui	a6,0xff0
ffffffffc0200780:	488d                	li	a7,3
ffffffffc0200782:	4e05                	li	t3,1
ffffffffc0200784:	b705                	j	ffffffffc02006a4 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200786:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200788:	00005597          	auipc	a1,0x5
ffffffffc020078c:	48058593          	addi	a1,a1,1152 # ffffffffc0205c08 <etext+0x358>
ffffffffc0200790:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200792:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200796:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020079e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a6:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007aa:	8ed1                	or	a3,a3,a2
ffffffffc02007ac:	0ff77713          	zext.b	a4,a4
ffffffffc02007b0:	0722                	slli	a4,a4,0x8
ffffffffc02007b2:	8d55                	or	a0,a0,a3
ffffffffc02007b4:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007b6:	1502                	slli	a0,a0,0x20
ffffffffc02007b8:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	954a                	add	a0,a0,s2
ffffffffc02007bc:	e01a                	sd	t1,0(sp)
ffffffffc02007be:	05a050ef          	jal	ffffffffc0205818 <strcmp>
ffffffffc02007c2:	67a2                	ld	a5,8(sp)
ffffffffc02007c4:	473d                	li	a4,15
ffffffffc02007c6:	6302                	ld	t1,0(sp)
ffffffffc02007c8:	00ff0837          	lui	a6,0xff0
ffffffffc02007cc:	488d                	li	a7,3
ffffffffc02007ce:	4e05                	li	t3,1
ffffffffc02007d0:	f6f779e3          	bgeu	a4,a5,ffffffffc0200742 <dtb_init+0x18a>
ffffffffc02007d4:	f53d                	bnez	a0,ffffffffc0200742 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007d6:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007da:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007de:	00005517          	auipc	a0,0x5
ffffffffc02007e2:	43250513          	addi	a0,a0,1074 # ffffffffc0205c10 <etext+0x360>
           fdt32_to_cpu(x >> 32);
ffffffffc02007e6:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ea:	0087d31b          	srliw	t1,a5,0x8
ffffffffc02007ee:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02007f2:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f6:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fa:	0187959b          	slliw	a1,a5,0x18
ffffffffc02007fe:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200802:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200806:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080e:	01037333          	and	t1,t1,a6
ffffffffc0200812:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200816:	01e5e5b3          	or	a1,a1,t5
ffffffffc020081a:	0ff7f793          	zext.b	a5,a5
ffffffffc020081e:	01de6e33          	or	t3,t3,t4
ffffffffc0200822:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200826:	01067633          	and	a2,a2,a6
ffffffffc020082a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020082e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	07a2                	slli	a5,a5,0x8
ffffffffc0200834:	0108d89b          	srliw	a7,a7,0x10
ffffffffc0200838:	0186df1b          	srliw	t5,a3,0x18
ffffffffc020083c:	01875e9b          	srliw	t4,a4,0x18
ffffffffc0200840:	8ddd                	or	a1,a1,a5
ffffffffc0200842:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200846:	0186979b          	slliw	a5,a3,0x18
ffffffffc020084a:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084e:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200862:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200866:	08a2                	slli	a7,a7,0x8
ffffffffc0200868:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020086c:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200870:	0ff6f693          	zext.b	a3,a3
ffffffffc0200874:	01de6833          	or	a6,t3,t4
ffffffffc0200878:	0ff77713          	zext.b	a4,a4
ffffffffc020087c:	01166633          	or	a2,a2,a7
ffffffffc0200880:	0067e7b3          	or	a5,a5,t1
ffffffffc0200884:	06a2                	slli	a3,a3,0x8
ffffffffc0200886:	01046433          	or	s0,s0,a6
ffffffffc020088a:	0722                	slli	a4,a4,0x8
ffffffffc020088c:	8fd5                	or	a5,a5,a3
ffffffffc020088e:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200890:	1582                	slli	a1,a1,0x20
ffffffffc0200892:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200894:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200896:	9201                	srli	a2,a2,0x20
ffffffffc0200898:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020089a:	1402                	slli	s0,s0,0x20
ffffffffc020089c:	00b7e4b3          	or	s1,a5,a1
ffffffffc02008a0:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008a2:	8f3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008a6:	85a6                	mv	a1,s1
ffffffffc02008a8:	00005517          	auipc	a0,0x5
ffffffffc02008ac:	38850513          	addi	a0,a0,904 # ffffffffc0205c30 <etext+0x380>
ffffffffc02008b0:	8e5ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008b4:	01445613          	srli	a2,s0,0x14
ffffffffc02008b8:	85a2                	mv	a1,s0
ffffffffc02008ba:	00005517          	auipc	a0,0x5
ffffffffc02008be:	38e50513          	addi	a0,a0,910 # ffffffffc0205c48 <etext+0x398>
ffffffffc02008c2:	8d3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c6:	009405b3          	add	a1,s0,s1
ffffffffc02008ca:	15fd                	addi	a1,a1,-1
ffffffffc02008cc:	00005517          	auipc	a0,0x5
ffffffffc02008d0:	39c50513          	addi	a0,a0,924 # ffffffffc0205c68 <etext+0x3b8>
ffffffffc02008d4:	8c1ff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc02008d8:	0009b797          	auipc	a5,0x9b
ffffffffc02008dc:	d697b023          	sd	s1,-672(a5) # ffffffffc029b638 <memory_base>
        memory_size = mem_size;
ffffffffc02008e0:	0009b797          	auipc	a5,0x9b
ffffffffc02008e4:	d487b823          	sd	s0,-688(a5) # ffffffffc029b630 <memory_size>
ffffffffc02008e8:	b531                	j	ffffffffc02006f4 <dtb_init+0x13c>

ffffffffc02008ea <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008ea:	0009b517          	auipc	a0,0x9b
ffffffffc02008ee:	d4e53503          	ld	a0,-690(a0) # ffffffffc029b638 <memory_base>
ffffffffc02008f2:	8082                	ret

ffffffffc02008f4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02008f4:	0009b517          	auipc	a0,0x9b
ffffffffc02008f8:	d3c53503          	ld	a0,-708(a0) # ffffffffc029b630 <memory_size>
ffffffffc02008fc:	8082                	ret

ffffffffc02008fe <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008fe:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200902:	8082                	ret

ffffffffc0200904 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200904:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200908:	8082                	ret

ffffffffc020090a <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020090a:	8082                	ret

ffffffffc020090c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020090c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200910:	00000797          	auipc	a5,0x0
ffffffffc0200914:	55c78793          	addi	a5,a5,1372 # ffffffffc0200e6c <__alltraps>
ffffffffc0200918:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020091c:	000407b7          	lui	a5,0x40
ffffffffc0200920:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200924:	8082                	ret

ffffffffc0200926 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200926:	610c                	ld	a1,0(a0)
{
ffffffffc0200928:	1141                	addi	sp,sp,-16
ffffffffc020092a:	e022                	sd	s0,0(sp)
ffffffffc020092c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020092e:	00005517          	auipc	a0,0x5
ffffffffc0200932:	3a250513          	addi	a0,a0,930 # ffffffffc0205cd0 <etext+0x420>
{
ffffffffc0200936:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200938:	85dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020093c:	640c                	ld	a1,8(s0)
ffffffffc020093e:	00005517          	auipc	a0,0x5
ffffffffc0200942:	3aa50513          	addi	a0,a0,938 # ffffffffc0205ce8 <etext+0x438>
ffffffffc0200946:	84fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020094a:	680c                	ld	a1,16(s0)
ffffffffc020094c:	00005517          	auipc	a0,0x5
ffffffffc0200950:	3b450513          	addi	a0,a0,948 # ffffffffc0205d00 <etext+0x450>
ffffffffc0200954:	841ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200958:	6c0c                	ld	a1,24(s0)
ffffffffc020095a:	00005517          	auipc	a0,0x5
ffffffffc020095e:	3be50513          	addi	a0,a0,958 # ffffffffc0205d18 <etext+0x468>
ffffffffc0200962:	833ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200966:	700c                	ld	a1,32(s0)
ffffffffc0200968:	00005517          	auipc	a0,0x5
ffffffffc020096c:	3c850513          	addi	a0,a0,968 # ffffffffc0205d30 <etext+0x480>
ffffffffc0200970:	825ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200974:	740c                	ld	a1,40(s0)
ffffffffc0200976:	00005517          	auipc	a0,0x5
ffffffffc020097a:	3d250513          	addi	a0,a0,978 # ffffffffc0205d48 <etext+0x498>
ffffffffc020097e:	817ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200982:	780c                	ld	a1,48(s0)
ffffffffc0200984:	00005517          	auipc	a0,0x5
ffffffffc0200988:	3dc50513          	addi	a0,a0,988 # ffffffffc0205d60 <etext+0x4b0>
ffffffffc020098c:	809ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200990:	7c0c                	ld	a1,56(s0)
ffffffffc0200992:	00005517          	auipc	a0,0x5
ffffffffc0200996:	3e650513          	addi	a0,a0,998 # ffffffffc0205d78 <etext+0x4c8>
ffffffffc020099a:	ffaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020099e:	602c                	ld	a1,64(s0)
ffffffffc02009a0:	00005517          	auipc	a0,0x5
ffffffffc02009a4:	3f050513          	addi	a0,a0,1008 # ffffffffc0205d90 <etext+0x4e0>
ffffffffc02009a8:	fecff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009ac:	642c                	ld	a1,72(s0)
ffffffffc02009ae:	00005517          	auipc	a0,0x5
ffffffffc02009b2:	3fa50513          	addi	a0,a0,1018 # ffffffffc0205da8 <etext+0x4f8>
ffffffffc02009b6:	fdeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009ba:	682c                	ld	a1,80(s0)
ffffffffc02009bc:	00005517          	auipc	a0,0x5
ffffffffc02009c0:	40450513          	addi	a0,a0,1028 # ffffffffc0205dc0 <etext+0x510>
ffffffffc02009c4:	fd0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c8:	6c2c                	ld	a1,88(s0)
ffffffffc02009ca:	00005517          	auipc	a0,0x5
ffffffffc02009ce:	40e50513          	addi	a0,a0,1038 # ffffffffc0205dd8 <etext+0x528>
ffffffffc02009d2:	fc2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d6:	702c                	ld	a1,96(s0)
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	41850513          	addi	a0,a0,1048 # ffffffffc0205df0 <etext+0x540>
ffffffffc02009e0:	fb4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009e4:	742c                	ld	a1,104(s0)
ffffffffc02009e6:	00005517          	auipc	a0,0x5
ffffffffc02009ea:	42250513          	addi	a0,a0,1058 # ffffffffc0205e08 <etext+0x558>
ffffffffc02009ee:	fa6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009f2:	782c                	ld	a1,112(s0)
ffffffffc02009f4:	00005517          	auipc	a0,0x5
ffffffffc02009f8:	42c50513          	addi	a0,a0,1068 # ffffffffc0205e20 <etext+0x570>
ffffffffc02009fc:	f98ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a00:	7c2c                	ld	a1,120(s0)
ffffffffc0200a02:	00005517          	auipc	a0,0x5
ffffffffc0200a06:	43650513          	addi	a0,a0,1078 # ffffffffc0205e38 <etext+0x588>
ffffffffc0200a0a:	f8aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a0e:	604c                	ld	a1,128(s0)
ffffffffc0200a10:	00005517          	auipc	a0,0x5
ffffffffc0200a14:	44050513          	addi	a0,a0,1088 # ffffffffc0205e50 <etext+0x5a0>
ffffffffc0200a18:	f7cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a1c:	644c                	ld	a1,136(s0)
ffffffffc0200a1e:	00005517          	auipc	a0,0x5
ffffffffc0200a22:	44a50513          	addi	a0,a0,1098 # ffffffffc0205e68 <etext+0x5b8>
ffffffffc0200a26:	f6eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a2a:	684c                	ld	a1,144(s0)
ffffffffc0200a2c:	00005517          	auipc	a0,0x5
ffffffffc0200a30:	45450513          	addi	a0,a0,1108 # ffffffffc0205e80 <etext+0x5d0>
ffffffffc0200a34:	f60ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a38:	6c4c                	ld	a1,152(s0)
ffffffffc0200a3a:	00005517          	auipc	a0,0x5
ffffffffc0200a3e:	45e50513          	addi	a0,a0,1118 # ffffffffc0205e98 <etext+0x5e8>
ffffffffc0200a42:	f52ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a46:	704c                	ld	a1,160(s0)
ffffffffc0200a48:	00005517          	auipc	a0,0x5
ffffffffc0200a4c:	46850513          	addi	a0,a0,1128 # ffffffffc0205eb0 <etext+0x600>
ffffffffc0200a50:	f44ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a54:	744c                	ld	a1,168(s0)
ffffffffc0200a56:	00005517          	auipc	a0,0x5
ffffffffc0200a5a:	47250513          	addi	a0,a0,1138 # ffffffffc0205ec8 <etext+0x618>
ffffffffc0200a5e:	f36ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a62:	784c                	ld	a1,176(s0)
ffffffffc0200a64:	00005517          	auipc	a0,0x5
ffffffffc0200a68:	47c50513          	addi	a0,a0,1148 # ffffffffc0205ee0 <etext+0x630>
ffffffffc0200a6c:	f28ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a70:	7c4c                	ld	a1,184(s0)
ffffffffc0200a72:	00005517          	auipc	a0,0x5
ffffffffc0200a76:	48650513          	addi	a0,a0,1158 # ffffffffc0205ef8 <etext+0x648>
ffffffffc0200a7a:	f1aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a7e:	606c                	ld	a1,192(s0)
ffffffffc0200a80:	00005517          	auipc	a0,0x5
ffffffffc0200a84:	49050513          	addi	a0,a0,1168 # ffffffffc0205f10 <etext+0x660>
ffffffffc0200a88:	f0cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a8c:	646c                	ld	a1,200(s0)
ffffffffc0200a8e:	00005517          	auipc	a0,0x5
ffffffffc0200a92:	49a50513          	addi	a0,a0,1178 # ffffffffc0205f28 <etext+0x678>
ffffffffc0200a96:	efeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a9a:	686c                	ld	a1,208(s0)
ffffffffc0200a9c:	00005517          	auipc	a0,0x5
ffffffffc0200aa0:	4a450513          	addi	a0,a0,1188 # ffffffffc0205f40 <etext+0x690>
ffffffffc0200aa4:	ef0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa8:	6c6c                	ld	a1,216(s0)
ffffffffc0200aaa:	00005517          	auipc	a0,0x5
ffffffffc0200aae:	4ae50513          	addi	a0,a0,1198 # ffffffffc0205f58 <etext+0x6a8>
ffffffffc0200ab2:	ee2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab6:	706c                	ld	a1,224(s0)
ffffffffc0200ab8:	00005517          	auipc	a0,0x5
ffffffffc0200abc:	4b850513          	addi	a0,a0,1208 # ffffffffc0205f70 <etext+0x6c0>
ffffffffc0200ac0:	ed4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200ac4:	746c                	ld	a1,232(s0)
ffffffffc0200ac6:	00005517          	auipc	a0,0x5
ffffffffc0200aca:	4c250513          	addi	a0,a0,1218 # ffffffffc0205f88 <etext+0x6d8>
ffffffffc0200ace:	ec6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200ad2:	786c                	ld	a1,240(s0)
ffffffffc0200ad4:	00005517          	auipc	a0,0x5
ffffffffc0200ad8:	4cc50513          	addi	a0,a0,1228 # ffffffffc0205fa0 <etext+0x6f0>
ffffffffc0200adc:	eb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200ae2:	6402                	ld	s0,0(sp)
ffffffffc0200ae4:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae6:	00005517          	auipc	a0,0x5
ffffffffc0200aea:	4d250513          	addi	a0,a0,1234 # ffffffffc0205fb8 <etext+0x708>
}
ffffffffc0200aee:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200af0:	ea4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200af4 <print_trapframe>:
{
ffffffffc0200af4:	1141                	addi	sp,sp,-16
ffffffffc0200af6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af8:	85aa                	mv	a1,a0
{
ffffffffc0200afa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200afc:	00005517          	auipc	a0,0x5
ffffffffc0200b00:	4d450513          	addi	a0,a0,1236 # ffffffffc0205fd0 <etext+0x720>
{
ffffffffc0200b04:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b06:	e8eff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b0a:	8522                	mv	a0,s0
ffffffffc0200b0c:	e1bff0ef          	jal	ffffffffc0200926 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b10:	10043583          	ld	a1,256(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	4d450513          	addi	a0,a0,1236 # ffffffffc0205fe8 <etext+0x738>
ffffffffc0200b1c:	e78ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b20:	10843583          	ld	a1,264(s0)
ffffffffc0200b24:	00005517          	auipc	a0,0x5
ffffffffc0200b28:	4dc50513          	addi	a0,a0,1244 # ffffffffc0206000 <etext+0x750>
ffffffffc0200b2c:	e68ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b30:	11043583          	ld	a1,272(s0)
ffffffffc0200b34:	00005517          	auipc	a0,0x5
ffffffffc0200b38:	4e450513          	addi	a0,a0,1252 # ffffffffc0206018 <etext+0x768>
ffffffffc0200b3c:	e58ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b40:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b44:	6402                	ld	s0,0(sp)
ffffffffc0200b46:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b48:	00005517          	auipc	a0,0x5
ffffffffc0200b4c:	4e050513          	addi	a0,a0,1248 # ffffffffc0206028 <etext+0x778>
}
ffffffffc0200b50:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b52:	e42ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b56 <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200b56:	11853783          	ld	a5,280(a0)
ffffffffc0200b5a:	472d                	li	a4,11
ffffffffc0200b5c:	0786                	slli	a5,a5,0x1
ffffffffc0200b5e:	8385                	srli	a5,a5,0x1
ffffffffc0200b60:	08f76e63          	bltu	a4,a5,ffffffffc0200bfc <interrupt_handler+0xa6>
ffffffffc0200b64:	00007717          	auipc	a4,0x7
ffffffffc0200b68:	b9470713          	addi	a4,a4,-1132 # ffffffffc02076f8 <commands+0x48>
ffffffffc0200b6c:	078a                	slli	a5,a5,0x2
ffffffffc0200b6e:	97ba                	add	a5,a5,a4
ffffffffc0200b70:	439c                	lw	a5,0(a5)
ffffffffc0200b72:	97ba                	add	a5,a5,a4
ffffffffc0200b74:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	52a50513          	addi	a0,a0,1322 # ffffffffc02060a0 <etext+0x7f0>
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b82:	00005517          	auipc	a0,0x5
ffffffffc0200b86:	4fe50513          	addi	a0,a0,1278 # ffffffffc0206080 <etext+0x7d0>
ffffffffc0200b8a:	e0aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b8e:	00005517          	auipc	a0,0x5
ffffffffc0200b92:	4b250513          	addi	a0,a0,1202 # ffffffffc0206040 <etext+0x790>
ffffffffc0200b96:	dfeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b9a:	00005517          	auipc	a0,0x5
ffffffffc0200b9e:	4c650513          	addi	a0,a0,1222 # ffffffffc0206060 <etext+0x7b0>
ffffffffc0200ba2:	df2ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200ba6:	1141                	addi	sp,sp,-16
ffffffffc0200ba8:	e406                	sd	ra,8(sp)
        /* 时间片轮转： 
        *(1) 设置下一次时钟中断（clock_set_next_event）
        *(2) ticks 计数器自增
        *(3) 每 TICK_NUM 次中断（如 100 次），进行判断当前是否有进程正在运行，如果有则标记该进程需要被重新调度（current->need_resched）
        */
        clock_set_next_event();
ffffffffc0200baa:	983ff0ef          	jal	ffffffffc020052c <clock_set_next_event>
        if (++ticks % TICK_NUM == 0) {
ffffffffc0200bae:	0009b697          	auipc	a3,0x9b
ffffffffc0200bb2:	a7a6b683          	ld	a3,-1414(a3) # ffffffffc029b628 <ticks>
ffffffffc0200bb6:	28f5c737          	lui	a4,0x28f5c
ffffffffc0200bba:	28f70713          	addi	a4,a4,655 # 28f5c28f <_binary_obj___user_exit_out_size+0x28f520d7>
ffffffffc0200bbe:	5c28f7b7          	lui	a5,0x5c28f
ffffffffc0200bc2:	5c378793          	addi	a5,a5,1475 # 5c28f5c3 <_binary_obj___user_exit_out_size+0x5c28540b>
ffffffffc0200bc6:	0685                	addi	a3,a3,1
ffffffffc0200bc8:	1702                	slli	a4,a4,0x20
ffffffffc0200bca:	973e                	add	a4,a4,a5
ffffffffc0200bcc:	0026d793          	srli	a5,a3,0x2
ffffffffc0200bd0:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc0200bd4:	06400593          	li	a1,100
ffffffffc0200bd8:	0009b717          	auipc	a4,0x9b
ffffffffc0200bdc:	a4d73823          	sd	a3,-1456(a4) # ffffffffc029b628 <ticks>
ffffffffc0200be0:	8389                	srli	a5,a5,0x2
ffffffffc0200be2:	02b787b3          	mul	a5,a5,a1
ffffffffc0200be6:	00f68c63          	beq	a3,a5,ffffffffc0200bfe <interrupt_handler+0xa8>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200bea:	60a2                	ld	ra,8(sp)
ffffffffc0200bec:	0141                	addi	sp,sp,16
ffffffffc0200bee:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bf0:	00005517          	auipc	a0,0x5
ffffffffc0200bf4:	4e050513          	addi	a0,a0,1248 # ffffffffc02060d0 <etext+0x820>
ffffffffc0200bf8:	d9cff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200bfc:	bde5                	j	ffffffffc0200af4 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200bfe:	00005517          	auipc	a0,0x5
ffffffffc0200c02:	4c250513          	addi	a0,a0,1218 # ffffffffc02060c0 <etext+0x810>
ffffffffc0200c06:	d8eff0ef          	jal	ffffffffc0200194 <cprintf>
            if (current) {
ffffffffc0200c0a:	0009b797          	auipc	a5,0x9b
ffffffffc0200c0e:	a767b783          	ld	a5,-1418(a5) # ffffffffc029b680 <current>
ffffffffc0200c12:	dfe1                	beqz	a5,ffffffffc0200bea <interrupt_handler+0x94>
                current->need_resched = 1;
ffffffffc0200c14:	4705                	li	a4,1
ffffffffc0200c16:	ef98                	sd	a4,24(a5)
ffffffffc0200c18:	bfc9                	j	ffffffffc0200bea <interrupt_handler+0x94>

ffffffffc0200c1a <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200c1a:	11853783          	ld	a5,280(a0)
ffffffffc0200c1e:	473d                	li	a4,15
ffffffffc0200c20:	1af76663          	bltu	a4,a5,ffffffffc0200dcc <exception_handler+0x1b2>
ffffffffc0200c24:	00007717          	auipc	a4,0x7
ffffffffc0200c28:	b0470713          	addi	a4,a4,-1276 # ffffffffc0207728 <commands+0x78>
ffffffffc0200c2c:	078a                	slli	a5,a5,0x2
ffffffffc0200c2e:	97ba                	add	a5,a5,a4
ffffffffc0200c30:	439c                	lw	a5,0(a5)
{
ffffffffc0200c32:	1141                	addi	sp,sp,-16
ffffffffc0200c34:	e022                	sd	s0,0(sp)
    switch (tf->cause)
ffffffffc0200c36:	97ba                	add	a5,a5,a4
{
ffffffffc0200c38:	e406                	sd	ra,8(sp)
ffffffffc0200c3a:	842a                	mv	s0,a0
    switch (tf->cause)
ffffffffc0200c3c:	8782                	jr	a5
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	5ea50513          	addi	a0,a0,1514 # ffffffffc0206228 <etext+0x978>
ffffffffc0200c46:	d4eff0ef          	jal	ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200c4a:	10843783          	ld	a5,264(s0)
    cprintf("killed by kernel.\n");
    if (current != NULL) {
        do_exit(-E_KILLED);
    }
    panic("do_exit failed.\n");
}
ffffffffc0200c4e:	60a2                	ld	ra,8(sp)
        tf->epc += 4;
ffffffffc0200c50:	0791                	addi	a5,a5,4
ffffffffc0200c52:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200c56:	6402                	ld	s0,0(sp)
ffffffffc0200c58:	0141                	addi	sp,sp,16
        syscall();
ffffffffc0200c5a:	71a0406f          	j	ffffffffc0205374 <syscall>
        cprintf("Environment call from H-mode\n");
ffffffffc0200c5e:	00005517          	auipc	a0,0x5
ffffffffc0200c62:	5ea50513          	addi	a0,a0,1514 # ffffffffc0206248 <etext+0x998>
}
ffffffffc0200c66:	6402                	ld	s0,0(sp)
ffffffffc0200c68:	60a2                	ld	ra,8(sp)
ffffffffc0200c6a:	0141                	addi	sp,sp,16
        cprintf("Environment call from M-mode\n");
ffffffffc0200c6c:	d28ff06f          	j	ffffffffc0200194 <cprintf>
ffffffffc0200c70:	00005517          	auipc	a0,0x5
ffffffffc0200c74:	5f850513          	addi	a0,a0,1528 # ffffffffc0206268 <etext+0x9b8>
ffffffffc0200c78:	b7fd                	j	ffffffffc0200c66 <exception_handler+0x4c>
        cprintf("Instruction page fault\n");
ffffffffc0200c7a:	00005517          	auipc	a0,0x5
ffffffffc0200c7e:	60e50513          	addi	a0,a0,1550 # ffffffffc0206288 <etext+0x9d8>
ffffffffc0200c82:	d12ff0ef          	jal	ffffffffc0200194 <cprintf>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c86:	10043783          	ld	a5,256(s0)
ffffffffc0200c8a:	1007f793          	andi	a5,a5,256
    if (trap_in_kernel(tf)) {
ffffffffc0200c8e:	c3c5                	beqz	a5,ffffffffc0200d2e <exception_handler+0x114>
        panic("Exception in kernel mode\n");
ffffffffc0200c90:	00005617          	auipc	a2,0x5
ffffffffc0200c94:	64060613          	addi	a2,a2,1600 # ffffffffc02062d0 <etext+0xa20>
ffffffffc0200c98:	0e700593          	li	a1,231
ffffffffc0200c9c:	00005517          	auipc	a0,0x5
ffffffffc0200ca0:	51c50513          	addi	a0,a0,1308 # ffffffffc02061b8 <etext+0x908>
ffffffffc0200ca4:	fa2ff0ef          	jal	ffffffffc0200446 <__panic>
        cprintf("Load page fault\n");
ffffffffc0200ca8:	00005517          	auipc	a0,0x5
ffffffffc0200cac:	5f850513          	addi	a0,a0,1528 # ffffffffc02062a0 <etext+0x9f0>
ffffffffc0200cb0:	ce4ff0ef          	jal	ffffffffc0200194 <cprintf>
        goto killed;
ffffffffc0200cb4:	bfc9                	j	ffffffffc0200c86 <exception_handler+0x6c>
        cprintf("Store/AMO page fault\n");
ffffffffc0200cb6:	00005517          	auipc	a0,0x5
ffffffffc0200cba:	60250513          	addi	a0,a0,1538 # ffffffffc02062b8 <etext+0xa08>
ffffffffc0200cbe:	cd6ff0ef          	jal	ffffffffc0200194 <cprintf>
        goto killed;
ffffffffc0200cc2:	b7d1                	j	ffffffffc0200c86 <exception_handler+0x6c>
        cprintf("Instruction address misaligned\n");
ffffffffc0200cc4:	00005517          	auipc	a0,0x5
ffffffffc0200cc8:	42c50513          	addi	a0,a0,1068 # ffffffffc02060f0 <etext+0x840>
ffffffffc0200ccc:	cc8ff0ef          	jal	ffffffffc0200194 <cprintf>
        goto killed;
ffffffffc0200cd0:	bf5d                	j	ffffffffc0200c86 <exception_handler+0x6c>
        cprintf("Instruction access fault\n");
ffffffffc0200cd2:	00005517          	auipc	a0,0x5
ffffffffc0200cd6:	43e50513          	addi	a0,a0,1086 # ffffffffc0206110 <etext+0x860>
ffffffffc0200cda:	cbaff0ef          	jal	ffffffffc0200194 <cprintf>
        goto killed;
ffffffffc0200cde:	b765                	j	ffffffffc0200c86 <exception_handler+0x6c>
        cprintf("Illegal instruction\n");
ffffffffc0200ce0:	00005517          	auipc	a0,0x5
ffffffffc0200ce4:	45050513          	addi	a0,a0,1104 # ffffffffc0206130 <etext+0x880>
ffffffffc0200ce8:	cacff0ef          	jal	ffffffffc0200194 <cprintf>
        goto killed;
ffffffffc0200cec:	bf69                	j	ffffffffc0200c86 <exception_handler+0x6c>
        cprintf("Breakpoint\n");
ffffffffc0200cee:	00005517          	auipc	a0,0x5
ffffffffc0200cf2:	45a50513          	addi	a0,a0,1114 # ffffffffc0206148 <etext+0x898>
ffffffffc0200cf6:	c9eff0ef          	jal	ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200cfa:	6458                	ld	a4,136(s0)
ffffffffc0200cfc:	47a9                	li	a5,10
ffffffffc0200cfe:	0af70463          	beq	a4,a5,ffffffffc0200da6 <exception_handler+0x18c>
}
ffffffffc0200d02:	60a2                	ld	ra,8(sp)
ffffffffc0200d04:	6402                	ld	s0,0(sp)
ffffffffc0200d06:	0141                	addi	sp,sp,16
ffffffffc0200d08:	8082                	ret
        cprintf("Load address misaligned\n");
ffffffffc0200d0a:	00005517          	auipc	a0,0x5
ffffffffc0200d0e:	44e50513          	addi	a0,a0,1102 # ffffffffc0206158 <etext+0x8a8>
ffffffffc0200d12:	c82ff0ef          	jal	ffffffffc0200194 <cprintf>
        goto killed;
ffffffffc0200d16:	bf85                	j	ffffffffc0200c86 <exception_handler+0x6c>
        cprintf("Load access fault\n");
ffffffffc0200d18:	00005517          	auipc	a0,0x5
ffffffffc0200d1c:	46050513          	addi	a0,a0,1120 # ffffffffc0206178 <etext+0x8c8>
ffffffffc0200d20:	c74ff0ef          	jal	ffffffffc0200194 <cprintf>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d24:	10043783          	ld	a5,256(s0)
ffffffffc0200d28:	1007f793          	andi	a5,a5,256
        if (trap_in_kernel(tf)) {
ffffffffc0200d2c:	e3cd                	bnez	a5,ffffffffc0200dce <exception_handler+0x1b4>
    cprintf("killed by kernel.\n");
ffffffffc0200d2e:	00005517          	auipc	a0,0x5
ffffffffc0200d32:	5da50513          	addi	a0,a0,1498 # ffffffffc0206308 <etext+0xa58>
ffffffffc0200d36:	c5eff0ef          	jal	ffffffffc0200194 <cprintf>
    if (current != NULL) {
ffffffffc0200d3a:	0009b797          	auipc	a5,0x9b
ffffffffc0200d3e:	9467b783          	ld	a5,-1722(a5) # ffffffffc029b680 <current>
ffffffffc0200d42:	c781                	beqz	a5,ffffffffc0200d4a <exception_handler+0x130>
        do_exit(-E_KILLED);
ffffffffc0200d44:	555d                	li	a0,-9
ffffffffc0200d46:	7d8030ef          	jal	ffffffffc020451e <do_exit>
    panic("do_exit failed.\n");
ffffffffc0200d4a:	00005617          	auipc	a2,0x5
ffffffffc0200d4e:	5a660613          	addi	a2,a2,1446 # ffffffffc02062f0 <etext+0xa40>
ffffffffc0200d52:	0ed00593          	li	a1,237
ffffffffc0200d56:	00005517          	auipc	a0,0x5
ffffffffc0200d5a:	46250513          	addi	a0,a0,1122 # ffffffffc02061b8 <etext+0x908>
ffffffffc0200d5e:	ee8ff0ef          	jal	ffffffffc0200446 <__panic>
        cprintf("AMO address misaligned\n");
ffffffffc0200d62:	00005517          	auipc	a0,0x5
ffffffffc0200d66:	46e50513          	addi	a0,a0,1134 # ffffffffc02061d0 <etext+0x920>
ffffffffc0200d6a:	c2aff0ef          	jal	ffffffffc0200194 <cprintf>
        goto killed;
ffffffffc0200d6e:	bf21                	j	ffffffffc0200c86 <exception_handler+0x6c>
        cprintf("Store/AMO access fault\n");
ffffffffc0200d70:	00005517          	auipc	a0,0x5
ffffffffc0200d74:	47850513          	addi	a0,a0,1144 # ffffffffc02061e8 <etext+0x938>
ffffffffc0200d78:	c1cff0ef          	jal	ffffffffc0200194 <cprintf>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d7c:	10043783          	ld	a5,256(s0)
ffffffffc0200d80:	1007f793          	andi	a5,a5,256
        if (trap_in_kernel(tf)) {
ffffffffc0200d84:	d7cd                	beqz	a5,ffffffffc0200d2e <exception_handler+0x114>
            panic("Store/AMO access fault in kernel mode\n");
ffffffffc0200d86:	00005617          	auipc	a2,0x5
ffffffffc0200d8a:	47a60613          	addi	a2,a2,1146 # ffffffffc0206200 <etext+0x950>
ffffffffc0200d8e:	0c300593          	li	a1,195
ffffffffc0200d92:	00005517          	auipc	a0,0x5
ffffffffc0200d96:	42650513          	addi	a0,a0,1062 # ffffffffc02061b8 <etext+0x908>
ffffffffc0200d9a:	eacff0ef          	jal	ffffffffc0200446 <__panic>
}
ffffffffc0200d9e:	6402                	ld	s0,0(sp)
ffffffffc0200da0:	60a2                	ld	ra,8(sp)
ffffffffc0200da2:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200da4:	bb81                	j	ffffffffc0200af4 <print_trapframe>
            tf->epc += 4;
ffffffffc0200da6:	10843783          	ld	a5,264(s0)
ffffffffc0200daa:	0791                	addi	a5,a5,4
ffffffffc0200dac:	10f43423          	sd	a5,264(s0)
            syscall();
ffffffffc0200db0:	5c4040ef          	jal	ffffffffc0205374 <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200db4:	0009b717          	auipc	a4,0x9b
ffffffffc0200db8:	8cc73703          	ld	a4,-1844(a4) # ffffffffc029b680 <current>
ffffffffc0200dbc:	8522                	mv	a0,s0
}
ffffffffc0200dbe:	6402                	ld	s0,0(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dc0:	6b0c                	ld	a1,16(a4)
}
ffffffffc0200dc2:	60a2                	ld	ra,8(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dc4:	6789                	lui	a5,0x2
ffffffffc0200dc6:	95be                	add	a1,a1,a5
}
ffffffffc0200dc8:	0141                	addi	sp,sp,16
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200dca:	aa85                	j	ffffffffc0200f3a <kernel_execve_ret>
        print_trapframe(tf);
ffffffffc0200dcc:	b325                	j	ffffffffc0200af4 <print_trapframe>
            panic("Load access fault in kernel mode\n");
ffffffffc0200dce:	00005617          	auipc	a2,0x5
ffffffffc0200dd2:	3c260613          	addi	a2,a2,962 # ffffffffc0206190 <etext+0x8e0>
ffffffffc0200dd6:	0ba00593          	li	a1,186
ffffffffc0200dda:	00005517          	auipc	a0,0x5
ffffffffc0200dde:	3de50513          	addi	a0,a0,990 # ffffffffc02061b8 <etext+0x908>
ffffffffc0200de2:	e64ff0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0200de6 <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200de6:	0009b717          	auipc	a4,0x9b
ffffffffc0200dea:	89a73703          	ld	a4,-1894(a4) # ffffffffc029b680 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dee:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200df2:	cf21                	beqz	a4,ffffffffc0200e4a <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200df4:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200df8:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200dfc:	1101                	addi	sp,sp,-32
ffffffffc0200dfe:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e00:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200e04:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e06:	e432                	sd	a2,8(sp)
ffffffffc0200e08:	e042                	sd	a6,0(sp)
ffffffffc0200e0a:	0205c763          	bltz	a1,ffffffffc0200e38 <trap+0x52>
        exception_handler(tf);
ffffffffc0200e0e:	e0dff0ef          	jal	ffffffffc0200c1a <exception_handler>
ffffffffc0200e12:	6622                	ld	a2,8(sp)
ffffffffc0200e14:	6802                	ld	a6,0(sp)
ffffffffc0200e16:	0009b697          	auipc	a3,0x9b
ffffffffc0200e1a:	86a68693          	addi	a3,a3,-1942 # ffffffffc029b680 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200e1e:	6298                	ld	a4,0(a3)
ffffffffc0200e20:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200e24:	e619                	bnez	a2,ffffffffc0200e32 <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200e26:	0b072783          	lw	a5,176(a4)
ffffffffc0200e2a:	8b85                	andi	a5,a5,1
ffffffffc0200e2c:	e79d                	bnez	a5,ffffffffc0200e5a <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200e2e:	6f1c                	ld	a5,24(a4)
ffffffffc0200e30:	e38d                	bnez	a5,ffffffffc0200e52 <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200e32:	60e2                	ld	ra,24(sp)
ffffffffc0200e34:	6105                	addi	sp,sp,32
ffffffffc0200e36:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200e38:	d1fff0ef          	jal	ffffffffc0200b56 <interrupt_handler>
ffffffffc0200e3c:	6802                	ld	a6,0(sp)
ffffffffc0200e3e:	6622                	ld	a2,8(sp)
ffffffffc0200e40:	0009b697          	auipc	a3,0x9b
ffffffffc0200e44:	84068693          	addi	a3,a3,-1984 # ffffffffc029b680 <current>
ffffffffc0200e48:	bfd9                	j	ffffffffc0200e1e <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e4a:	0005c363          	bltz	a1,ffffffffc0200e50 <trap+0x6a>
        exception_handler(tf);
ffffffffc0200e4e:	b3f1                	j	ffffffffc0200c1a <exception_handler>
        interrupt_handler(tf);
ffffffffc0200e50:	b319                	j	ffffffffc0200b56 <interrupt_handler>
}
ffffffffc0200e52:	60e2                	ld	ra,24(sp)
ffffffffc0200e54:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200e56:	4320406f          	j	ffffffffc0205288 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200e5a:	555d                	li	a0,-9
ffffffffc0200e5c:	6c2030ef          	jal	ffffffffc020451e <do_exit>
            if (current->need_resched)
ffffffffc0200e60:	0009b717          	auipc	a4,0x9b
ffffffffc0200e64:	82073703          	ld	a4,-2016(a4) # ffffffffc029b680 <current>
ffffffffc0200e68:	b7d9                	j	ffffffffc0200e2e <trap+0x48>
	...

ffffffffc0200e6c <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200e6c:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200e70:	00011463          	bnez	sp,ffffffffc0200e78 <__alltraps+0xc>
ffffffffc0200e74:	14002173          	csrr	sp,sscratch
ffffffffc0200e78:	712d                	addi	sp,sp,-288
ffffffffc0200e7a:	e002                	sd	zero,0(sp)
ffffffffc0200e7c:	e406                	sd	ra,8(sp)
ffffffffc0200e7e:	ec0e                	sd	gp,24(sp)
ffffffffc0200e80:	f012                	sd	tp,32(sp)
ffffffffc0200e82:	f416                	sd	t0,40(sp)
ffffffffc0200e84:	f81a                	sd	t1,48(sp)
ffffffffc0200e86:	fc1e                	sd	t2,56(sp)
ffffffffc0200e88:	e0a2                	sd	s0,64(sp)
ffffffffc0200e8a:	e4a6                	sd	s1,72(sp)
ffffffffc0200e8c:	e8aa                	sd	a0,80(sp)
ffffffffc0200e8e:	ecae                	sd	a1,88(sp)
ffffffffc0200e90:	f0b2                	sd	a2,96(sp)
ffffffffc0200e92:	f4b6                	sd	a3,104(sp)
ffffffffc0200e94:	f8ba                	sd	a4,112(sp)
ffffffffc0200e96:	fcbe                	sd	a5,120(sp)
ffffffffc0200e98:	e142                	sd	a6,128(sp)
ffffffffc0200e9a:	e546                	sd	a7,136(sp)
ffffffffc0200e9c:	e94a                	sd	s2,144(sp)
ffffffffc0200e9e:	ed4e                	sd	s3,152(sp)
ffffffffc0200ea0:	f152                	sd	s4,160(sp)
ffffffffc0200ea2:	f556                	sd	s5,168(sp)
ffffffffc0200ea4:	f95a                	sd	s6,176(sp)
ffffffffc0200ea6:	fd5e                	sd	s7,184(sp)
ffffffffc0200ea8:	e1e2                	sd	s8,192(sp)
ffffffffc0200eaa:	e5e6                	sd	s9,200(sp)
ffffffffc0200eac:	e9ea                	sd	s10,208(sp)
ffffffffc0200eae:	edee                	sd	s11,216(sp)
ffffffffc0200eb0:	f1f2                	sd	t3,224(sp)
ffffffffc0200eb2:	f5f6                	sd	t4,232(sp)
ffffffffc0200eb4:	f9fa                	sd	t5,240(sp)
ffffffffc0200eb6:	fdfe                	sd	t6,248(sp)
ffffffffc0200eb8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200ebc:	100024f3          	csrr	s1,sstatus
ffffffffc0200ec0:	14102973          	csrr	s2,sepc
ffffffffc0200ec4:	143029f3          	csrr	s3,stval
ffffffffc0200ec8:	14202a73          	csrr	s4,scause
ffffffffc0200ecc:	e822                	sd	s0,16(sp)
ffffffffc0200ece:	e226                	sd	s1,256(sp)
ffffffffc0200ed0:	e64a                	sd	s2,264(sp)
ffffffffc0200ed2:	ea4e                	sd	s3,272(sp)
ffffffffc0200ed4:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200ed6:	850a                	mv	a0,sp
    jal trap
ffffffffc0200ed8:	f0fff0ef          	jal	ffffffffc0200de6 <trap>

ffffffffc0200edc <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200edc:	6492                	ld	s1,256(sp)
ffffffffc0200ede:	6932                	ld	s2,264(sp)
ffffffffc0200ee0:	1004f413          	andi	s0,s1,256
ffffffffc0200ee4:	e401                	bnez	s0,ffffffffc0200eec <__trapret+0x10>
ffffffffc0200ee6:	1200                	addi	s0,sp,288
ffffffffc0200ee8:	14041073          	csrw	sscratch,s0
ffffffffc0200eec:	10049073          	csrw	sstatus,s1
ffffffffc0200ef0:	14191073          	csrw	sepc,s2
ffffffffc0200ef4:	60a2                	ld	ra,8(sp)
ffffffffc0200ef6:	61e2                	ld	gp,24(sp)
ffffffffc0200ef8:	7202                	ld	tp,32(sp)
ffffffffc0200efa:	72a2                	ld	t0,40(sp)
ffffffffc0200efc:	7342                	ld	t1,48(sp)
ffffffffc0200efe:	73e2                	ld	t2,56(sp)
ffffffffc0200f00:	6406                	ld	s0,64(sp)
ffffffffc0200f02:	64a6                	ld	s1,72(sp)
ffffffffc0200f04:	6546                	ld	a0,80(sp)
ffffffffc0200f06:	65e6                	ld	a1,88(sp)
ffffffffc0200f08:	7606                	ld	a2,96(sp)
ffffffffc0200f0a:	76a6                	ld	a3,104(sp)
ffffffffc0200f0c:	7746                	ld	a4,112(sp)
ffffffffc0200f0e:	77e6                	ld	a5,120(sp)
ffffffffc0200f10:	680a                	ld	a6,128(sp)
ffffffffc0200f12:	68aa                	ld	a7,136(sp)
ffffffffc0200f14:	694a                	ld	s2,144(sp)
ffffffffc0200f16:	69ea                	ld	s3,152(sp)
ffffffffc0200f18:	7a0a                	ld	s4,160(sp)
ffffffffc0200f1a:	7aaa                	ld	s5,168(sp)
ffffffffc0200f1c:	7b4a                	ld	s6,176(sp)
ffffffffc0200f1e:	7bea                	ld	s7,184(sp)
ffffffffc0200f20:	6c0e                	ld	s8,192(sp)
ffffffffc0200f22:	6cae                	ld	s9,200(sp)
ffffffffc0200f24:	6d4e                	ld	s10,208(sp)
ffffffffc0200f26:	6dee                	ld	s11,216(sp)
ffffffffc0200f28:	7e0e                	ld	t3,224(sp)
ffffffffc0200f2a:	7eae                	ld	t4,232(sp)
ffffffffc0200f2c:	7f4e                	ld	t5,240(sp)
ffffffffc0200f2e:	7fee                	ld	t6,248(sp)
ffffffffc0200f30:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200f32:	10200073          	sret

ffffffffc0200f36 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200f36:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200f38:	b755                	j	ffffffffc0200edc <__trapret>

ffffffffc0200f3a <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200f3a:	ee058593          	addi	a1,a1,-288

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200f3e:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200f42:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200f46:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200f4a:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200f4e:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200f52:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200f56:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200f5a:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200f5e:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200f60:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200f62:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200f64:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200f66:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200f68:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200f6a:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200f6c:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200f6e:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200f70:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200f72:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200f74:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200f76:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200f78:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200f7a:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200f7c:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200f7e:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f80:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f82:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f84:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f86:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f88:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f8a:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f8c:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f8e:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f90:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f92:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f94:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f96:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f98:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f9a:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f9c:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f9e:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200fa0:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200fa2:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200fa4:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200fa6:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200fa8:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200faa:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200fac:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200fae:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200fb0:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200fb2:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200fb4:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200fb6:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200fb8:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200fba:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200fbc:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200fbe:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200fc0:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200fc2:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200fc4:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200fc6:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200fc8:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200fca:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200fcc:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200fce:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200fd0:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200fd2:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200fd4:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200fd6:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200fd8:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200fda:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200fdc:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200fde:	812e                	mv	sp,a1
ffffffffc0200fe0:	bdf5                	j	ffffffffc0200edc <__trapret>

ffffffffc0200fe2 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200fe2:	00096797          	auipc	a5,0x96
ffffffffc0200fe6:	60e78793          	addi	a5,a5,1550 # ffffffffc02975f0 <free_area>
ffffffffc0200fea:	e79c                	sd	a5,8(a5)
ffffffffc0200fec:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200fee:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200ff2:	8082                	ret

ffffffffc0200ff4 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200ff4:	00096517          	auipc	a0,0x96
ffffffffc0200ff8:	60c56503          	lwu	a0,1548(a0) # ffffffffc0297600 <free_area+0x10>
ffffffffc0200ffc:	8082                	ret

ffffffffc0200ffe <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200ffe:	711d                	addi	sp,sp,-96
ffffffffc0201000:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0201002:	00096917          	auipc	s2,0x96
ffffffffc0201006:	5ee90913          	addi	s2,s2,1518 # ffffffffc02975f0 <free_area>
ffffffffc020100a:	00893783          	ld	a5,8(s2)
ffffffffc020100e:	ec86                	sd	ra,88(sp)
ffffffffc0201010:	e8a2                	sd	s0,80(sp)
ffffffffc0201012:	e4a6                	sd	s1,72(sp)
ffffffffc0201014:	fc4e                	sd	s3,56(sp)
ffffffffc0201016:	f852                	sd	s4,48(sp)
ffffffffc0201018:	f456                	sd	s5,40(sp)
ffffffffc020101a:	f05a                	sd	s6,32(sp)
ffffffffc020101c:	ec5e                	sd	s7,24(sp)
ffffffffc020101e:	e862                	sd	s8,16(sp)
ffffffffc0201020:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0201022:	2f278363          	beq	a5,s2,ffffffffc0201308 <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0201026:	4401                	li	s0,0
ffffffffc0201028:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020102a:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020102e:	8b09                	andi	a4,a4,2
ffffffffc0201030:	2e070063          	beqz	a4,ffffffffc0201310 <default_check+0x312>
        count++, total += p->property;
ffffffffc0201034:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201038:	679c                	ld	a5,8(a5)
ffffffffc020103a:	2485                	addiw	s1,s1,1
ffffffffc020103c:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020103e:	ff2796e3          	bne	a5,s2,ffffffffc020102a <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0201042:	89a2                	mv	s3,s0
ffffffffc0201044:	741000ef          	jal	ffffffffc0201f84 <nr_free_pages>
ffffffffc0201048:	73351463          	bne	a0,s3,ffffffffc0201770 <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020104c:	4505                	li	a0,1
ffffffffc020104e:	6c5000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc0201052:	8a2a                	mv	s4,a0
ffffffffc0201054:	44050e63          	beqz	a0,ffffffffc02014b0 <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201058:	4505                	li	a0,1
ffffffffc020105a:	6b9000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc020105e:	89aa                	mv	s3,a0
ffffffffc0201060:	72050863          	beqz	a0,ffffffffc0201790 <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201064:	4505                	li	a0,1
ffffffffc0201066:	6ad000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc020106a:	8aaa                	mv	s5,a0
ffffffffc020106c:	4c050263          	beqz	a0,ffffffffc0201530 <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201070:	40a987b3          	sub	a5,s3,a0
ffffffffc0201074:	40aa0733          	sub	a4,s4,a0
ffffffffc0201078:	0017b793          	seqz	a5,a5
ffffffffc020107c:	00173713          	seqz	a4,a4
ffffffffc0201080:	8fd9                	or	a5,a5,a4
ffffffffc0201082:	30079763          	bnez	a5,ffffffffc0201390 <default_check+0x392>
ffffffffc0201086:	313a0563          	beq	s4,s3,ffffffffc0201390 <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020108a:	000a2783          	lw	a5,0(s4)
ffffffffc020108e:	2a079163          	bnez	a5,ffffffffc0201330 <default_check+0x332>
ffffffffc0201092:	0009a783          	lw	a5,0(s3)
ffffffffc0201096:	28079d63          	bnez	a5,ffffffffc0201330 <default_check+0x332>
ffffffffc020109a:	411c                	lw	a5,0(a0)
ffffffffc020109c:	28079a63          	bnez	a5,ffffffffc0201330 <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc02010a0:	0009a797          	auipc	a5,0x9a
ffffffffc02010a4:	5d07b783          	ld	a5,1488(a5) # ffffffffc029b670 <pages>
ffffffffc02010a8:	00007617          	auipc	a2,0x7
ffffffffc02010ac:	a1863603          	ld	a2,-1512(a2) # ffffffffc0207ac0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02010b0:	0009a697          	auipc	a3,0x9a
ffffffffc02010b4:	5b86b683          	ld	a3,1464(a3) # ffffffffc029b668 <npage>
ffffffffc02010b8:	40fa0733          	sub	a4,s4,a5
ffffffffc02010bc:	8719                	srai	a4,a4,0x6
ffffffffc02010be:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc02010c0:	0732                	slli	a4,a4,0xc
ffffffffc02010c2:	06b2                	slli	a3,a3,0xc
ffffffffc02010c4:	2ad77663          	bgeu	a4,a3,ffffffffc0201370 <default_check+0x372>
    return page - pages + nbase;
ffffffffc02010c8:	40f98733          	sub	a4,s3,a5
ffffffffc02010cc:	8719                	srai	a4,a4,0x6
ffffffffc02010ce:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010d0:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010d2:	4cd77f63          	bgeu	a4,a3,ffffffffc02015b0 <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc02010d6:	40f507b3          	sub	a5,a0,a5
ffffffffc02010da:	8799                	srai	a5,a5,0x6
ffffffffc02010dc:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010de:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010e0:	32d7f863          	bgeu	a5,a3,ffffffffc0201410 <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc02010e4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010e6:	00093c03          	ld	s8,0(s2)
ffffffffc02010ea:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc02010ee:	00096b17          	auipc	s6,0x96
ffffffffc02010f2:	512b2b03          	lw	s6,1298(s6) # ffffffffc0297600 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc02010f6:	01293023          	sd	s2,0(s2)
ffffffffc02010fa:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc02010fe:	00096797          	auipc	a5,0x96
ffffffffc0201102:	5007a123          	sw	zero,1282(a5) # ffffffffc0297600 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201106:	60d000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc020110a:	2e051363          	bnez	a0,ffffffffc02013f0 <default_check+0x3f2>
    free_page(p0);
ffffffffc020110e:	8552                	mv	a0,s4
ffffffffc0201110:	4585                	li	a1,1
ffffffffc0201112:	63b000ef          	jal	ffffffffc0201f4c <free_pages>
    free_page(p1);
ffffffffc0201116:	854e                	mv	a0,s3
ffffffffc0201118:	4585                	li	a1,1
ffffffffc020111a:	633000ef          	jal	ffffffffc0201f4c <free_pages>
    free_page(p2);
ffffffffc020111e:	8556                	mv	a0,s5
ffffffffc0201120:	4585                	li	a1,1
ffffffffc0201122:	62b000ef          	jal	ffffffffc0201f4c <free_pages>
    assert(nr_free == 3);
ffffffffc0201126:	00096717          	auipc	a4,0x96
ffffffffc020112a:	4da72703          	lw	a4,1242(a4) # ffffffffc0297600 <free_area+0x10>
ffffffffc020112e:	478d                	li	a5,3
ffffffffc0201130:	2af71063          	bne	a4,a5,ffffffffc02013d0 <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201134:	4505                	li	a0,1
ffffffffc0201136:	5dd000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc020113a:	89aa                	mv	s3,a0
ffffffffc020113c:	26050a63          	beqz	a0,ffffffffc02013b0 <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201140:	4505                	li	a0,1
ffffffffc0201142:	5d1000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc0201146:	8aaa                	mv	s5,a0
ffffffffc0201148:	3c050463          	beqz	a0,ffffffffc0201510 <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020114c:	4505                	li	a0,1
ffffffffc020114e:	5c5000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc0201152:	8a2a                	mv	s4,a0
ffffffffc0201154:	38050e63          	beqz	a0,ffffffffc02014f0 <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc0201158:	4505                	li	a0,1
ffffffffc020115a:	5b9000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc020115e:	36051963          	bnez	a0,ffffffffc02014d0 <default_check+0x4d2>
    free_page(p0);
ffffffffc0201162:	4585                	li	a1,1
ffffffffc0201164:	854e                	mv	a0,s3
ffffffffc0201166:	5e7000ef          	jal	ffffffffc0201f4c <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020116a:	00893783          	ld	a5,8(s2)
ffffffffc020116e:	1f278163          	beq	a5,s2,ffffffffc0201350 <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc0201172:	4505                	li	a0,1
ffffffffc0201174:	59f000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc0201178:	8caa                	mv	s9,a0
ffffffffc020117a:	30a99b63          	bne	s3,a0,ffffffffc0201490 <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc020117e:	4505                	li	a0,1
ffffffffc0201180:	593000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc0201184:	2e051663          	bnez	a0,ffffffffc0201470 <default_check+0x472>
    assert(nr_free == 0);
ffffffffc0201188:	00096797          	auipc	a5,0x96
ffffffffc020118c:	4787a783          	lw	a5,1144(a5) # ffffffffc0297600 <free_area+0x10>
ffffffffc0201190:	2c079063          	bnez	a5,ffffffffc0201450 <default_check+0x452>
    free_page(p);
ffffffffc0201194:	8566                	mv	a0,s9
ffffffffc0201196:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201198:	01893023          	sd	s8,0(s2)
ffffffffc020119c:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc02011a0:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc02011a4:	5a9000ef          	jal	ffffffffc0201f4c <free_pages>
    free_page(p1);
ffffffffc02011a8:	8556                	mv	a0,s5
ffffffffc02011aa:	4585                	li	a1,1
ffffffffc02011ac:	5a1000ef          	jal	ffffffffc0201f4c <free_pages>
    free_page(p2);
ffffffffc02011b0:	8552                	mv	a0,s4
ffffffffc02011b2:	4585                	li	a1,1
ffffffffc02011b4:	599000ef          	jal	ffffffffc0201f4c <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc02011b8:	4515                	li	a0,5
ffffffffc02011ba:	559000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc02011be:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc02011c0:	26050863          	beqz	a0,ffffffffc0201430 <default_check+0x432>
ffffffffc02011c4:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc02011c6:	8b89                	andi	a5,a5,2
ffffffffc02011c8:	54079463          	bnez	a5,ffffffffc0201710 <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02011cc:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02011ce:	00093b83          	ld	s7,0(s2)
ffffffffc02011d2:	00893b03          	ld	s6,8(s2)
ffffffffc02011d6:	01293023          	sd	s2,0(s2)
ffffffffc02011da:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc02011de:	535000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc02011e2:	50051763          	bnez	a0,ffffffffc02016f0 <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02011e6:	08098a13          	addi	s4,s3,128
ffffffffc02011ea:	8552                	mv	a0,s4
ffffffffc02011ec:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02011ee:	00096c17          	auipc	s8,0x96
ffffffffc02011f2:	412c2c03          	lw	s8,1042(s8) # ffffffffc0297600 <free_area+0x10>
    nr_free = 0;
ffffffffc02011f6:	00096797          	auipc	a5,0x96
ffffffffc02011fa:	4007a523          	sw	zero,1034(a5) # ffffffffc0297600 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02011fe:	54f000ef          	jal	ffffffffc0201f4c <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201202:	4511                	li	a0,4
ffffffffc0201204:	50f000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc0201208:	4c051463          	bnez	a0,ffffffffc02016d0 <default_check+0x6d2>
ffffffffc020120c:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201210:	8b89                	andi	a5,a5,2
ffffffffc0201212:	48078f63          	beqz	a5,ffffffffc02016b0 <default_check+0x6b2>
ffffffffc0201216:	0909a503          	lw	a0,144(s3)
ffffffffc020121a:	478d                	li	a5,3
ffffffffc020121c:	48f51a63          	bne	a0,a5,ffffffffc02016b0 <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201220:	4f3000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc0201224:	8aaa                	mv	s5,a0
ffffffffc0201226:	46050563          	beqz	a0,ffffffffc0201690 <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc020122a:	4505                	li	a0,1
ffffffffc020122c:	4e7000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc0201230:	44051063          	bnez	a0,ffffffffc0201670 <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc0201234:	415a1e63          	bne	s4,s5,ffffffffc0201650 <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201238:	4585                	li	a1,1
ffffffffc020123a:	854e                	mv	a0,s3
ffffffffc020123c:	511000ef          	jal	ffffffffc0201f4c <free_pages>
    free_pages(p1, 3);
ffffffffc0201240:	8552                	mv	a0,s4
ffffffffc0201242:	458d                	li	a1,3
ffffffffc0201244:	509000ef          	jal	ffffffffc0201f4c <free_pages>
ffffffffc0201248:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020124c:	8b89                	andi	a5,a5,2
ffffffffc020124e:	3e078163          	beqz	a5,ffffffffc0201630 <default_check+0x632>
ffffffffc0201252:	0109aa83          	lw	s5,16(s3)
ffffffffc0201256:	4785                	li	a5,1
ffffffffc0201258:	3cfa9c63          	bne	s5,a5,ffffffffc0201630 <default_check+0x632>
ffffffffc020125c:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201260:	8b89                	andi	a5,a5,2
ffffffffc0201262:	3a078763          	beqz	a5,ffffffffc0201610 <default_check+0x612>
ffffffffc0201266:	010a2703          	lw	a4,16(s4)
ffffffffc020126a:	478d                	li	a5,3
ffffffffc020126c:	3af71263          	bne	a4,a5,ffffffffc0201610 <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201270:	8556                	mv	a0,s5
ffffffffc0201272:	4a1000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc0201276:	36a99d63          	bne	s3,a0,ffffffffc02015f0 <default_check+0x5f2>
    free_page(p0);
ffffffffc020127a:	85d6                	mv	a1,s5
ffffffffc020127c:	4d1000ef          	jal	ffffffffc0201f4c <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201280:	4509                	li	a0,2
ffffffffc0201282:	491000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc0201286:	34aa1563          	bne	s4,a0,ffffffffc02015d0 <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc020128a:	4589                	li	a1,2
ffffffffc020128c:	4c1000ef          	jal	ffffffffc0201f4c <free_pages>
    free_page(p2);
ffffffffc0201290:	04098513          	addi	a0,s3,64
ffffffffc0201294:	85d6                	mv	a1,s5
ffffffffc0201296:	4b7000ef          	jal	ffffffffc0201f4c <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020129a:	4515                	li	a0,5
ffffffffc020129c:	477000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc02012a0:	89aa                	mv	s3,a0
ffffffffc02012a2:	48050763          	beqz	a0,ffffffffc0201730 <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc02012a6:	8556                	mv	a0,s5
ffffffffc02012a8:	46b000ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc02012ac:	2e051263          	bnez	a0,ffffffffc0201590 <default_check+0x592>

    assert(nr_free == 0);
ffffffffc02012b0:	00096797          	auipc	a5,0x96
ffffffffc02012b4:	3507a783          	lw	a5,848(a5) # ffffffffc0297600 <free_area+0x10>
ffffffffc02012b8:	2a079c63          	bnez	a5,ffffffffc0201570 <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02012bc:	854e                	mv	a0,s3
ffffffffc02012be:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc02012c0:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc02012c4:	01793023          	sd	s7,0(s2)
ffffffffc02012c8:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc02012cc:	481000ef          	jal	ffffffffc0201f4c <free_pages>
    return listelm->next;
ffffffffc02012d0:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02012d4:	01278963          	beq	a5,s2,ffffffffc02012e6 <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02012d8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02012dc:	679c                	ld	a5,8(a5)
ffffffffc02012de:	34fd                	addiw	s1,s1,-1
ffffffffc02012e0:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012e2:	ff279be3          	bne	a5,s2,ffffffffc02012d8 <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc02012e6:	26049563          	bnez	s1,ffffffffc0201550 <default_check+0x552>
    assert(total == 0);
ffffffffc02012ea:	46041363          	bnez	s0,ffffffffc0201750 <default_check+0x752>
}
ffffffffc02012ee:	60e6                	ld	ra,88(sp)
ffffffffc02012f0:	6446                	ld	s0,80(sp)
ffffffffc02012f2:	64a6                	ld	s1,72(sp)
ffffffffc02012f4:	6906                	ld	s2,64(sp)
ffffffffc02012f6:	79e2                	ld	s3,56(sp)
ffffffffc02012f8:	7a42                	ld	s4,48(sp)
ffffffffc02012fa:	7aa2                	ld	s5,40(sp)
ffffffffc02012fc:	7b02                	ld	s6,32(sp)
ffffffffc02012fe:	6be2                	ld	s7,24(sp)
ffffffffc0201300:	6c42                	ld	s8,16(sp)
ffffffffc0201302:	6ca2                	ld	s9,8(sp)
ffffffffc0201304:	6125                	addi	sp,sp,96
ffffffffc0201306:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201308:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020130a:	4401                	li	s0,0
ffffffffc020130c:	4481                	li	s1,0
ffffffffc020130e:	bb1d                	j	ffffffffc0201044 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0201310:	00005697          	auipc	a3,0x5
ffffffffc0201314:	01068693          	addi	a3,a3,16 # ffffffffc0206320 <etext+0xa70>
ffffffffc0201318:	00005617          	auipc	a2,0x5
ffffffffc020131c:	01860613          	addi	a2,a2,24 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201320:	11000593          	li	a1,272
ffffffffc0201324:	00005517          	auipc	a0,0x5
ffffffffc0201328:	02450513          	addi	a0,a0,36 # ffffffffc0206348 <etext+0xa98>
ffffffffc020132c:	91aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201330:	00005697          	auipc	a3,0x5
ffffffffc0201334:	0d868693          	addi	a3,a3,216 # ffffffffc0206408 <etext+0xb58>
ffffffffc0201338:	00005617          	auipc	a2,0x5
ffffffffc020133c:	ff860613          	addi	a2,a2,-8 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201340:	0dc00593          	li	a1,220
ffffffffc0201344:	00005517          	auipc	a0,0x5
ffffffffc0201348:	00450513          	addi	a0,a0,4 # ffffffffc0206348 <etext+0xa98>
ffffffffc020134c:	8faff0ef          	jal	ffffffffc0200446 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201350:	00005697          	auipc	a3,0x5
ffffffffc0201354:	18068693          	addi	a3,a3,384 # ffffffffc02064d0 <etext+0xc20>
ffffffffc0201358:	00005617          	auipc	a2,0x5
ffffffffc020135c:	fd860613          	addi	a2,a2,-40 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201360:	0f700593          	li	a1,247
ffffffffc0201364:	00005517          	auipc	a0,0x5
ffffffffc0201368:	fe450513          	addi	a0,a0,-28 # ffffffffc0206348 <etext+0xa98>
ffffffffc020136c:	8daff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201370:	00005697          	auipc	a3,0x5
ffffffffc0201374:	0d868693          	addi	a3,a3,216 # ffffffffc0206448 <etext+0xb98>
ffffffffc0201378:	00005617          	auipc	a2,0x5
ffffffffc020137c:	fb860613          	addi	a2,a2,-72 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201380:	0de00593          	li	a1,222
ffffffffc0201384:	00005517          	auipc	a0,0x5
ffffffffc0201388:	fc450513          	addi	a0,a0,-60 # ffffffffc0206348 <etext+0xa98>
ffffffffc020138c:	8baff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201390:	00005697          	auipc	a3,0x5
ffffffffc0201394:	05068693          	addi	a3,a3,80 # ffffffffc02063e0 <etext+0xb30>
ffffffffc0201398:	00005617          	auipc	a2,0x5
ffffffffc020139c:	f9860613          	addi	a2,a2,-104 # ffffffffc0206330 <etext+0xa80>
ffffffffc02013a0:	0db00593          	li	a1,219
ffffffffc02013a4:	00005517          	auipc	a0,0x5
ffffffffc02013a8:	fa450513          	addi	a0,a0,-92 # ffffffffc0206348 <etext+0xa98>
ffffffffc02013ac:	89aff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02013b0:	00005697          	auipc	a3,0x5
ffffffffc02013b4:	fd068693          	addi	a3,a3,-48 # ffffffffc0206380 <etext+0xad0>
ffffffffc02013b8:	00005617          	auipc	a2,0x5
ffffffffc02013bc:	f7860613          	addi	a2,a2,-136 # ffffffffc0206330 <etext+0xa80>
ffffffffc02013c0:	0f000593          	li	a1,240
ffffffffc02013c4:	00005517          	auipc	a0,0x5
ffffffffc02013c8:	f8450513          	addi	a0,a0,-124 # ffffffffc0206348 <etext+0xa98>
ffffffffc02013cc:	87aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 3);
ffffffffc02013d0:	00005697          	auipc	a3,0x5
ffffffffc02013d4:	0f068693          	addi	a3,a3,240 # ffffffffc02064c0 <etext+0xc10>
ffffffffc02013d8:	00005617          	auipc	a2,0x5
ffffffffc02013dc:	f5860613          	addi	a2,a2,-168 # ffffffffc0206330 <etext+0xa80>
ffffffffc02013e0:	0ee00593          	li	a1,238
ffffffffc02013e4:	00005517          	auipc	a0,0x5
ffffffffc02013e8:	f6450513          	addi	a0,a0,-156 # ffffffffc0206348 <etext+0xa98>
ffffffffc02013ec:	85aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013f0:	00005697          	auipc	a3,0x5
ffffffffc02013f4:	0b868693          	addi	a3,a3,184 # ffffffffc02064a8 <etext+0xbf8>
ffffffffc02013f8:	00005617          	auipc	a2,0x5
ffffffffc02013fc:	f3860613          	addi	a2,a2,-200 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201400:	0e900593          	li	a1,233
ffffffffc0201404:	00005517          	auipc	a0,0x5
ffffffffc0201408:	f4450513          	addi	a0,a0,-188 # ffffffffc0206348 <etext+0xa98>
ffffffffc020140c:	83aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201410:	00005697          	auipc	a3,0x5
ffffffffc0201414:	07868693          	addi	a3,a3,120 # ffffffffc0206488 <etext+0xbd8>
ffffffffc0201418:	00005617          	auipc	a2,0x5
ffffffffc020141c:	f1860613          	addi	a2,a2,-232 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201420:	0e000593          	li	a1,224
ffffffffc0201424:	00005517          	auipc	a0,0x5
ffffffffc0201428:	f2450513          	addi	a0,a0,-220 # ffffffffc0206348 <etext+0xa98>
ffffffffc020142c:	81aff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != NULL);
ffffffffc0201430:	00005697          	auipc	a3,0x5
ffffffffc0201434:	0e868693          	addi	a3,a3,232 # ffffffffc0206518 <etext+0xc68>
ffffffffc0201438:	00005617          	auipc	a2,0x5
ffffffffc020143c:	ef860613          	addi	a2,a2,-264 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201440:	11800593          	li	a1,280
ffffffffc0201444:	00005517          	auipc	a0,0x5
ffffffffc0201448:	f0450513          	addi	a0,a0,-252 # ffffffffc0206348 <etext+0xa98>
ffffffffc020144c:	ffbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc0201450:	00005697          	auipc	a3,0x5
ffffffffc0201454:	0b868693          	addi	a3,a3,184 # ffffffffc0206508 <etext+0xc58>
ffffffffc0201458:	00005617          	auipc	a2,0x5
ffffffffc020145c:	ed860613          	addi	a2,a2,-296 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201460:	0fd00593          	li	a1,253
ffffffffc0201464:	00005517          	auipc	a0,0x5
ffffffffc0201468:	ee450513          	addi	a0,a0,-284 # ffffffffc0206348 <etext+0xa98>
ffffffffc020146c:	fdbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201470:	00005697          	auipc	a3,0x5
ffffffffc0201474:	03868693          	addi	a3,a3,56 # ffffffffc02064a8 <etext+0xbf8>
ffffffffc0201478:	00005617          	auipc	a2,0x5
ffffffffc020147c:	eb860613          	addi	a2,a2,-328 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201480:	0fb00593          	li	a1,251
ffffffffc0201484:	00005517          	auipc	a0,0x5
ffffffffc0201488:	ec450513          	addi	a0,a0,-316 # ffffffffc0206348 <etext+0xa98>
ffffffffc020148c:	fbbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201490:	00005697          	auipc	a3,0x5
ffffffffc0201494:	05868693          	addi	a3,a3,88 # ffffffffc02064e8 <etext+0xc38>
ffffffffc0201498:	00005617          	auipc	a2,0x5
ffffffffc020149c:	e9860613          	addi	a2,a2,-360 # ffffffffc0206330 <etext+0xa80>
ffffffffc02014a0:	0fa00593          	li	a1,250
ffffffffc02014a4:	00005517          	auipc	a0,0x5
ffffffffc02014a8:	ea450513          	addi	a0,a0,-348 # ffffffffc0206348 <etext+0xa98>
ffffffffc02014ac:	f9bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02014b0:	00005697          	auipc	a3,0x5
ffffffffc02014b4:	ed068693          	addi	a3,a3,-304 # ffffffffc0206380 <etext+0xad0>
ffffffffc02014b8:	00005617          	auipc	a2,0x5
ffffffffc02014bc:	e7860613          	addi	a2,a2,-392 # ffffffffc0206330 <etext+0xa80>
ffffffffc02014c0:	0d700593          	li	a1,215
ffffffffc02014c4:	00005517          	auipc	a0,0x5
ffffffffc02014c8:	e8450513          	addi	a0,a0,-380 # ffffffffc0206348 <etext+0xa98>
ffffffffc02014cc:	f7bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014d0:	00005697          	auipc	a3,0x5
ffffffffc02014d4:	fd868693          	addi	a3,a3,-40 # ffffffffc02064a8 <etext+0xbf8>
ffffffffc02014d8:	00005617          	auipc	a2,0x5
ffffffffc02014dc:	e5860613          	addi	a2,a2,-424 # ffffffffc0206330 <etext+0xa80>
ffffffffc02014e0:	0f400593          	li	a1,244
ffffffffc02014e4:	00005517          	auipc	a0,0x5
ffffffffc02014e8:	e6450513          	addi	a0,a0,-412 # ffffffffc0206348 <etext+0xa98>
ffffffffc02014ec:	f5bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014f0:	00005697          	auipc	a3,0x5
ffffffffc02014f4:	ed068693          	addi	a3,a3,-304 # ffffffffc02063c0 <etext+0xb10>
ffffffffc02014f8:	00005617          	auipc	a2,0x5
ffffffffc02014fc:	e3860613          	addi	a2,a2,-456 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201500:	0f200593          	li	a1,242
ffffffffc0201504:	00005517          	auipc	a0,0x5
ffffffffc0201508:	e4450513          	addi	a0,a0,-444 # ffffffffc0206348 <etext+0xa98>
ffffffffc020150c:	f3bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201510:	00005697          	auipc	a3,0x5
ffffffffc0201514:	e9068693          	addi	a3,a3,-368 # ffffffffc02063a0 <etext+0xaf0>
ffffffffc0201518:	00005617          	auipc	a2,0x5
ffffffffc020151c:	e1860613          	addi	a2,a2,-488 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201520:	0f100593          	li	a1,241
ffffffffc0201524:	00005517          	auipc	a0,0x5
ffffffffc0201528:	e2450513          	addi	a0,a0,-476 # ffffffffc0206348 <etext+0xa98>
ffffffffc020152c:	f1bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201530:	00005697          	auipc	a3,0x5
ffffffffc0201534:	e9068693          	addi	a3,a3,-368 # ffffffffc02063c0 <etext+0xb10>
ffffffffc0201538:	00005617          	auipc	a2,0x5
ffffffffc020153c:	df860613          	addi	a2,a2,-520 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201540:	0d900593          	li	a1,217
ffffffffc0201544:	00005517          	auipc	a0,0x5
ffffffffc0201548:	e0450513          	addi	a0,a0,-508 # ffffffffc0206348 <etext+0xa98>
ffffffffc020154c:	efbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(count == 0);
ffffffffc0201550:	00005697          	auipc	a3,0x5
ffffffffc0201554:	11868693          	addi	a3,a3,280 # ffffffffc0206668 <etext+0xdb8>
ffffffffc0201558:	00005617          	auipc	a2,0x5
ffffffffc020155c:	dd860613          	addi	a2,a2,-552 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201560:	14600593          	li	a1,326
ffffffffc0201564:	00005517          	auipc	a0,0x5
ffffffffc0201568:	de450513          	addi	a0,a0,-540 # ffffffffc0206348 <etext+0xa98>
ffffffffc020156c:	edbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc0201570:	00005697          	auipc	a3,0x5
ffffffffc0201574:	f9868693          	addi	a3,a3,-104 # ffffffffc0206508 <etext+0xc58>
ffffffffc0201578:	00005617          	auipc	a2,0x5
ffffffffc020157c:	db860613          	addi	a2,a2,-584 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201580:	13a00593          	li	a1,314
ffffffffc0201584:	00005517          	auipc	a0,0x5
ffffffffc0201588:	dc450513          	addi	a0,a0,-572 # ffffffffc0206348 <etext+0xa98>
ffffffffc020158c:	ebbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201590:	00005697          	auipc	a3,0x5
ffffffffc0201594:	f1868693          	addi	a3,a3,-232 # ffffffffc02064a8 <etext+0xbf8>
ffffffffc0201598:	00005617          	auipc	a2,0x5
ffffffffc020159c:	d9860613          	addi	a2,a2,-616 # ffffffffc0206330 <etext+0xa80>
ffffffffc02015a0:	13800593          	li	a1,312
ffffffffc02015a4:	00005517          	auipc	a0,0x5
ffffffffc02015a8:	da450513          	addi	a0,a0,-604 # ffffffffc0206348 <etext+0xa98>
ffffffffc02015ac:	e9bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02015b0:	00005697          	auipc	a3,0x5
ffffffffc02015b4:	eb868693          	addi	a3,a3,-328 # ffffffffc0206468 <etext+0xbb8>
ffffffffc02015b8:	00005617          	auipc	a2,0x5
ffffffffc02015bc:	d7860613          	addi	a2,a2,-648 # ffffffffc0206330 <etext+0xa80>
ffffffffc02015c0:	0df00593          	li	a1,223
ffffffffc02015c4:	00005517          	auipc	a0,0x5
ffffffffc02015c8:	d8450513          	addi	a0,a0,-636 # ffffffffc0206348 <etext+0xa98>
ffffffffc02015cc:	e7bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02015d0:	00005697          	auipc	a3,0x5
ffffffffc02015d4:	05868693          	addi	a3,a3,88 # ffffffffc0206628 <etext+0xd78>
ffffffffc02015d8:	00005617          	auipc	a2,0x5
ffffffffc02015dc:	d5860613          	addi	a2,a2,-680 # ffffffffc0206330 <etext+0xa80>
ffffffffc02015e0:	13200593          	li	a1,306
ffffffffc02015e4:	00005517          	auipc	a0,0x5
ffffffffc02015e8:	d6450513          	addi	a0,a0,-668 # ffffffffc0206348 <etext+0xa98>
ffffffffc02015ec:	e5bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02015f0:	00005697          	auipc	a3,0x5
ffffffffc02015f4:	01868693          	addi	a3,a3,24 # ffffffffc0206608 <etext+0xd58>
ffffffffc02015f8:	00005617          	auipc	a2,0x5
ffffffffc02015fc:	d3860613          	addi	a2,a2,-712 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201600:	13000593          	li	a1,304
ffffffffc0201604:	00005517          	auipc	a0,0x5
ffffffffc0201608:	d4450513          	addi	a0,a0,-700 # ffffffffc0206348 <etext+0xa98>
ffffffffc020160c:	e3bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201610:	00005697          	auipc	a3,0x5
ffffffffc0201614:	fd068693          	addi	a3,a3,-48 # ffffffffc02065e0 <etext+0xd30>
ffffffffc0201618:	00005617          	auipc	a2,0x5
ffffffffc020161c:	d1860613          	addi	a2,a2,-744 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201620:	12e00593          	li	a1,302
ffffffffc0201624:	00005517          	auipc	a0,0x5
ffffffffc0201628:	d2450513          	addi	a0,a0,-732 # ffffffffc0206348 <etext+0xa98>
ffffffffc020162c:	e1bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201630:	00005697          	auipc	a3,0x5
ffffffffc0201634:	f8868693          	addi	a3,a3,-120 # ffffffffc02065b8 <etext+0xd08>
ffffffffc0201638:	00005617          	auipc	a2,0x5
ffffffffc020163c:	cf860613          	addi	a2,a2,-776 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201640:	12d00593          	li	a1,301
ffffffffc0201644:	00005517          	auipc	a0,0x5
ffffffffc0201648:	d0450513          	addi	a0,a0,-764 # ffffffffc0206348 <etext+0xa98>
ffffffffc020164c:	dfbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201650:	00005697          	auipc	a3,0x5
ffffffffc0201654:	f5868693          	addi	a3,a3,-168 # ffffffffc02065a8 <etext+0xcf8>
ffffffffc0201658:	00005617          	auipc	a2,0x5
ffffffffc020165c:	cd860613          	addi	a2,a2,-808 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201660:	12800593          	li	a1,296
ffffffffc0201664:	00005517          	auipc	a0,0x5
ffffffffc0201668:	ce450513          	addi	a0,a0,-796 # ffffffffc0206348 <etext+0xa98>
ffffffffc020166c:	ddbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201670:	00005697          	auipc	a3,0x5
ffffffffc0201674:	e3868693          	addi	a3,a3,-456 # ffffffffc02064a8 <etext+0xbf8>
ffffffffc0201678:	00005617          	auipc	a2,0x5
ffffffffc020167c:	cb860613          	addi	a2,a2,-840 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201680:	12700593          	li	a1,295
ffffffffc0201684:	00005517          	auipc	a0,0x5
ffffffffc0201688:	cc450513          	addi	a0,a0,-828 # ffffffffc0206348 <etext+0xa98>
ffffffffc020168c:	dbbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201690:	00005697          	auipc	a3,0x5
ffffffffc0201694:	ef868693          	addi	a3,a3,-264 # ffffffffc0206588 <etext+0xcd8>
ffffffffc0201698:	00005617          	auipc	a2,0x5
ffffffffc020169c:	c9860613          	addi	a2,a2,-872 # ffffffffc0206330 <etext+0xa80>
ffffffffc02016a0:	12600593          	li	a1,294
ffffffffc02016a4:	00005517          	auipc	a0,0x5
ffffffffc02016a8:	ca450513          	addi	a0,a0,-860 # ffffffffc0206348 <etext+0xa98>
ffffffffc02016ac:	d9bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02016b0:	00005697          	auipc	a3,0x5
ffffffffc02016b4:	ea868693          	addi	a3,a3,-344 # ffffffffc0206558 <etext+0xca8>
ffffffffc02016b8:	00005617          	auipc	a2,0x5
ffffffffc02016bc:	c7860613          	addi	a2,a2,-904 # ffffffffc0206330 <etext+0xa80>
ffffffffc02016c0:	12500593          	li	a1,293
ffffffffc02016c4:	00005517          	auipc	a0,0x5
ffffffffc02016c8:	c8450513          	addi	a0,a0,-892 # ffffffffc0206348 <etext+0xa98>
ffffffffc02016cc:	d7bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02016d0:	00005697          	auipc	a3,0x5
ffffffffc02016d4:	e7068693          	addi	a3,a3,-400 # ffffffffc0206540 <etext+0xc90>
ffffffffc02016d8:	00005617          	auipc	a2,0x5
ffffffffc02016dc:	c5860613          	addi	a2,a2,-936 # ffffffffc0206330 <etext+0xa80>
ffffffffc02016e0:	12400593          	li	a1,292
ffffffffc02016e4:	00005517          	auipc	a0,0x5
ffffffffc02016e8:	c6450513          	addi	a0,a0,-924 # ffffffffc0206348 <etext+0xa98>
ffffffffc02016ec:	d5bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016f0:	00005697          	auipc	a3,0x5
ffffffffc02016f4:	db868693          	addi	a3,a3,-584 # ffffffffc02064a8 <etext+0xbf8>
ffffffffc02016f8:	00005617          	auipc	a2,0x5
ffffffffc02016fc:	c3860613          	addi	a2,a2,-968 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201700:	11e00593          	li	a1,286
ffffffffc0201704:	00005517          	auipc	a0,0x5
ffffffffc0201708:	c4450513          	addi	a0,a0,-956 # ffffffffc0206348 <etext+0xa98>
ffffffffc020170c:	d3bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201710:	00005697          	auipc	a3,0x5
ffffffffc0201714:	e1868693          	addi	a3,a3,-488 # ffffffffc0206528 <etext+0xc78>
ffffffffc0201718:	00005617          	auipc	a2,0x5
ffffffffc020171c:	c1860613          	addi	a2,a2,-1000 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201720:	11900593          	li	a1,281
ffffffffc0201724:	00005517          	auipc	a0,0x5
ffffffffc0201728:	c2450513          	addi	a0,a0,-988 # ffffffffc0206348 <etext+0xa98>
ffffffffc020172c:	d1bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201730:	00005697          	auipc	a3,0x5
ffffffffc0201734:	f1868693          	addi	a3,a3,-232 # ffffffffc0206648 <etext+0xd98>
ffffffffc0201738:	00005617          	auipc	a2,0x5
ffffffffc020173c:	bf860613          	addi	a2,a2,-1032 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201740:	13700593          	li	a1,311
ffffffffc0201744:	00005517          	auipc	a0,0x5
ffffffffc0201748:	c0450513          	addi	a0,a0,-1020 # ffffffffc0206348 <etext+0xa98>
ffffffffc020174c:	cfbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == 0);
ffffffffc0201750:	00005697          	auipc	a3,0x5
ffffffffc0201754:	f2868693          	addi	a3,a3,-216 # ffffffffc0206678 <etext+0xdc8>
ffffffffc0201758:	00005617          	auipc	a2,0x5
ffffffffc020175c:	bd860613          	addi	a2,a2,-1064 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201760:	14700593          	li	a1,327
ffffffffc0201764:	00005517          	auipc	a0,0x5
ffffffffc0201768:	be450513          	addi	a0,a0,-1052 # ffffffffc0206348 <etext+0xa98>
ffffffffc020176c:	cdbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201770:	00005697          	auipc	a3,0x5
ffffffffc0201774:	bf068693          	addi	a3,a3,-1040 # ffffffffc0206360 <etext+0xab0>
ffffffffc0201778:	00005617          	auipc	a2,0x5
ffffffffc020177c:	bb860613          	addi	a2,a2,-1096 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201780:	11300593          	li	a1,275
ffffffffc0201784:	00005517          	auipc	a0,0x5
ffffffffc0201788:	bc450513          	addi	a0,a0,-1084 # ffffffffc0206348 <etext+0xa98>
ffffffffc020178c:	cbbfe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201790:	00005697          	auipc	a3,0x5
ffffffffc0201794:	c1068693          	addi	a3,a3,-1008 # ffffffffc02063a0 <etext+0xaf0>
ffffffffc0201798:	00005617          	auipc	a2,0x5
ffffffffc020179c:	b9860613          	addi	a2,a2,-1128 # ffffffffc0206330 <etext+0xa80>
ffffffffc02017a0:	0d800593          	li	a1,216
ffffffffc02017a4:	00005517          	auipc	a0,0x5
ffffffffc02017a8:	ba450513          	addi	a0,a0,-1116 # ffffffffc0206348 <etext+0xa98>
ffffffffc02017ac:	c9bfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02017b0 <default_free_pages>:
{
ffffffffc02017b0:	1141                	addi	sp,sp,-16
ffffffffc02017b2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02017b4:	14058663          	beqz	a1,ffffffffc0201900 <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc02017b8:	00659713          	slli	a4,a1,0x6
ffffffffc02017bc:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02017c0:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc02017c2:	c30d                	beqz	a4,ffffffffc02017e4 <default_free_pages+0x34>
ffffffffc02017c4:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017c6:	8b05                	andi	a4,a4,1
ffffffffc02017c8:	10071c63          	bnez	a4,ffffffffc02018e0 <default_free_pages+0x130>
ffffffffc02017cc:	6798                	ld	a4,8(a5)
ffffffffc02017ce:	8b09                	andi	a4,a4,2
ffffffffc02017d0:	10071863          	bnez	a4,ffffffffc02018e0 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc02017d4:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02017d8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02017dc:	04078793          	addi	a5,a5,64
ffffffffc02017e0:	fed792e3          	bne	a5,a3,ffffffffc02017c4 <default_free_pages+0x14>
    base->property = n;
ffffffffc02017e4:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02017e6:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017ea:	4789                	li	a5,2
ffffffffc02017ec:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02017f0:	00096717          	auipc	a4,0x96
ffffffffc02017f4:	e1072703          	lw	a4,-496(a4) # ffffffffc0297600 <free_area+0x10>
ffffffffc02017f8:	00096697          	auipc	a3,0x96
ffffffffc02017fc:	df868693          	addi	a3,a3,-520 # ffffffffc02975f0 <free_area>
    return list->next == list;
ffffffffc0201800:	669c                	ld	a5,8(a3)
ffffffffc0201802:	9f2d                	addw	a4,a4,a1
ffffffffc0201804:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc0201806:	0ad78163          	beq	a5,a3,ffffffffc02018a8 <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc020180a:	fe878713          	addi	a4,a5,-24
ffffffffc020180e:	4581                	li	a1,0
ffffffffc0201810:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0201814:	00e56a63          	bltu	a0,a4,ffffffffc0201828 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201818:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc020181a:	04d70c63          	beq	a4,a3,ffffffffc0201872 <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc020181e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201820:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201824:	fee57ae3          	bgeu	a0,a4,ffffffffc0201818 <default_free_pages+0x68>
ffffffffc0201828:	c199                	beqz	a1,ffffffffc020182e <default_free_pages+0x7e>
ffffffffc020182a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020182e:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201830:	e390                	sd	a2,0(a5)
ffffffffc0201832:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc0201834:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201836:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc0201838:	00d70d63          	beq	a4,a3,ffffffffc0201852 <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc020183c:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201840:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201844:	02059813          	slli	a6,a1,0x20
ffffffffc0201848:	01a85793          	srli	a5,a6,0x1a
ffffffffc020184c:	97b2                	add	a5,a5,a2
ffffffffc020184e:	02f50c63          	beq	a0,a5,ffffffffc0201886 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0201852:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201854:	00d78c63          	beq	a5,a3,ffffffffc020186c <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201858:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc020185a:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020185e:	02061593          	slli	a1,a2,0x20
ffffffffc0201862:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201866:	972a                	add	a4,a4,a0
ffffffffc0201868:	04e68c63          	beq	a3,a4,ffffffffc02018c0 <default_free_pages+0x110>
}
ffffffffc020186c:	60a2                	ld	ra,8(sp)
ffffffffc020186e:	0141                	addi	sp,sp,16
ffffffffc0201870:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201872:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201874:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201876:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201878:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020187a:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc020187c:	02d70f63          	beq	a4,a3,ffffffffc02018ba <default_free_pages+0x10a>
ffffffffc0201880:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201882:	87ba                	mv	a5,a4
ffffffffc0201884:	bf71                	j	ffffffffc0201820 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201886:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201888:	5875                	li	a6,-3
ffffffffc020188a:	9fad                	addw	a5,a5,a1
ffffffffc020188c:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201890:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201894:	01853803          	ld	a6,24(a0)
ffffffffc0201898:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc020189a:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020189c:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_exit_out_size+0xfe5e50>
    return listelm->next;
ffffffffc02018a0:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc02018a2:	0105b023          	sd	a6,0(a1)
ffffffffc02018a6:	b77d                	j	ffffffffc0201854 <default_free_pages+0xa4>
}
ffffffffc02018a8:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02018aa:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02018ae:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02018b0:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02018b2:	e398                	sd	a4,0(a5)
ffffffffc02018b4:	e798                	sd	a4,8(a5)
}
ffffffffc02018b6:	0141                	addi	sp,sp,16
ffffffffc02018b8:	8082                	ret
ffffffffc02018ba:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02018bc:	873e                	mv	a4,a5
ffffffffc02018be:	bfad                	j	ffffffffc0201838 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc02018c0:	ff87a703          	lw	a4,-8(a5)
ffffffffc02018c4:	56f5                	li	a3,-3
ffffffffc02018c6:	9f31                	addw	a4,a4,a2
ffffffffc02018c8:	c918                	sw	a4,16(a0)
ffffffffc02018ca:	ff078713          	addi	a4,a5,-16
ffffffffc02018ce:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018d2:	6398                	ld	a4,0(a5)
ffffffffc02018d4:	679c                	ld	a5,8(a5)
}
ffffffffc02018d6:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02018d8:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02018da:	e398                	sd	a4,0(a5)
ffffffffc02018dc:	0141                	addi	sp,sp,16
ffffffffc02018de:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02018e0:	00005697          	auipc	a3,0x5
ffffffffc02018e4:	db068693          	addi	a3,a3,-592 # ffffffffc0206690 <etext+0xde0>
ffffffffc02018e8:	00005617          	auipc	a2,0x5
ffffffffc02018ec:	a4860613          	addi	a2,a2,-1464 # ffffffffc0206330 <etext+0xa80>
ffffffffc02018f0:	09400593          	li	a1,148
ffffffffc02018f4:	00005517          	auipc	a0,0x5
ffffffffc02018f8:	a5450513          	addi	a0,a0,-1452 # ffffffffc0206348 <etext+0xa98>
ffffffffc02018fc:	b4bfe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201900:	00005697          	auipc	a3,0x5
ffffffffc0201904:	d8868693          	addi	a3,a3,-632 # ffffffffc0206688 <etext+0xdd8>
ffffffffc0201908:	00005617          	auipc	a2,0x5
ffffffffc020190c:	a2860613          	addi	a2,a2,-1496 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201910:	09000593          	li	a1,144
ffffffffc0201914:	00005517          	auipc	a0,0x5
ffffffffc0201918:	a3450513          	addi	a0,a0,-1484 # ffffffffc0206348 <etext+0xa98>
ffffffffc020191c:	b2bfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201920 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201920:	c951                	beqz	a0,ffffffffc02019b4 <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc0201922:	00096597          	auipc	a1,0x96
ffffffffc0201926:	cde5a583          	lw	a1,-802(a1) # ffffffffc0297600 <free_area+0x10>
ffffffffc020192a:	86aa                	mv	a3,a0
ffffffffc020192c:	02059793          	slli	a5,a1,0x20
ffffffffc0201930:	9381                	srli	a5,a5,0x20
ffffffffc0201932:	00a7ef63          	bltu	a5,a0,ffffffffc0201950 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc0201936:	00096617          	auipc	a2,0x96
ffffffffc020193a:	cba60613          	addi	a2,a2,-838 # ffffffffc02975f0 <free_area>
ffffffffc020193e:	87b2                	mv	a5,a2
ffffffffc0201940:	a029                	j	ffffffffc020194a <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc0201942:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0201946:	00d77763          	bgeu	a4,a3,ffffffffc0201954 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc020194a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc020194c:	fec79be3          	bne	a5,a2,ffffffffc0201942 <default_alloc_pages+0x22>
        return NULL;
ffffffffc0201950:	4501                	li	a0,0
}
ffffffffc0201952:	8082                	ret
        if (page->property > n)
ffffffffc0201954:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc0201958:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc020195c:	6798                	ld	a4,8(a5)
ffffffffc020195e:	02089313          	slli	t1,a7,0x20
ffffffffc0201962:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc0201966:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc020196a:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc020196e:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc0201972:	0266fa63          	bgeu	a3,t1,ffffffffc02019a6 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc0201976:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc020197a:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc020197e:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201980:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201984:	00870313          	addi	t1,a4,8
ffffffffc0201988:	4889                	li	a7,2
ffffffffc020198a:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020198e:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc0201992:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc0201996:	0068b023          	sd	t1,0(a7)
ffffffffc020199a:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc020199e:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc02019a2:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc02019a6:	9d95                	subw	a1,a1,a3
ffffffffc02019a8:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02019aa:	5775                	li	a4,-3
ffffffffc02019ac:	17c1                	addi	a5,a5,-16
ffffffffc02019ae:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc02019b2:	8082                	ret
{
ffffffffc02019b4:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02019b6:	00005697          	auipc	a3,0x5
ffffffffc02019ba:	cd268693          	addi	a3,a3,-814 # ffffffffc0206688 <etext+0xdd8>
ffffffffc02019be:	00005617          	auipc	a2,0x5
ffffffffc02019c2:	97260613          	addi	a2,a2,-1678 # ffffffffc0206330 <etext+0xa80>
ffffffffc02019c6:	06c00593          	li	a1,108
ffffffffc02019ca:	00005517          	auipc	a0,0x5
ffffffffc02019ce:	97e50513          	addi	a0,a0,-1666 # ffffffffc0206348 <etext+0xa98>
{
ffffffffc02019d2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019d4:	a73fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02019d8 <default_init_memmap>:
{
ffffffffc02019d8:	1141                	addi	sp,sp,-16
ffffffffc02019da:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019dc:	c9e1                	beqz	a1,ffffffffc0201aac <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc02019de:	00659713          	slli	a4,a1,0x6
ffffffffc02019e2:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02019e6:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc02019e8:	cf11                	beqz	a4,ffffffffc0201a04 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02019ea:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02019ec:	8b05                	andi	a4,a4,1
ffffffffc02019ee:	cf59                	beqz	a4,ffffffffc0201a8c <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02019f0:	0007a823          	sw	zero,16(a5)
ffffffffc02019f4:	0007b423          	sd	zero,8(a5)
ffffffffc02019f8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02019fc:	04078793          	addi	a5,a5,64
ffffffffc0201a00:	fed795e3          	bne	a5,a3,ffffffffc02019ea <default_init_memmap+0x12>
    base->property = n;
ffffffffc0201a04:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201a06:	4789                	li	a5,2
ffffffffc0201a08:	00850713          	addi	a4,a0,8
ffffffffc0201a0c:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201a10:	00096717          	auipc	a4,0x96
ffffffffc0201a14:	bf072703          	lw	a4,-1040(a4) # ffffffffc0297600 <free_area+0x10>
ffffffffc0201a18:	00096697          	auipc	a3,0x96
ffffffffc0201a1c:	bd868693          	addi	a3,a3,-1064 # ffffffffc02975f0 <free_area>
    return list->next == list;
ffffffffc0201a20:	669c                	ld	a5,8(a3)
ffffffffc0201a22:	9f2d                	addw	a4,a4,a1
ffffffffc0201a24:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a26:	04d78663          	beq	a5,a3,ffffffffc0201a72 <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a2a:	fe878713          	addi	a4,a5,-24
ffffffffc0201a2e:	4581                	li	a1,0
ffffffffc0201a30:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0201a34:	00e56a63          	bltu	a0,a4,ffffffffc0201a48 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201a38:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a3a:	02d70263          	beq	a4,a3,ffffffffc0201a5e <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc0201a3e:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a40:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a44:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a38 <default_init_memmap+0x60>
ffffffffc0201a48:	c199                	beqz	a1,ffffffffc0201a4e <default_init_memmap+0x76>
ffffffffc0201a4a:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a4e:	6398                	ld	a4,0(a5)
}
ffffffffc0201a50:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a52:	e390                	sd	a2,0(a5)
ffffffffc0201a54:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc0201a56:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201a58:	f11c                	sd	a5,32(a0)
ffffffffc0201a5a:	0141                	addi	sp,sp,16
ffffffffc0201a5c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a5e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a60:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a62:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a64:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201a66:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a68:	00d70e63          	beq	a4,a3,ffffffffc0201a84 <default_init_memmap+0xac>
ffffffffc0201a6c:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201a6e:	87ba                	mv	a5,a4
ffffffffc0201a70:	bfc1                	j	ffffffffc0201a40 <default_init_memmap+0x68>
}
ffffffffc0201a72:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a74:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201a78:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a7a:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201a7c:	e398                	sd	a4,0(a5)
ffffffffc0201a7e:	e798                	sd	a4,8(a5)
}
ffffffffc0201a80:	0141                	addi	sp,sp,16
ffffffffc0201a82:	8082                	ret
ffffffffc0201a84:	60a2                	ld	ra,8(sp)
ffffffffc0201a86:	e290                	sd	a2,0(a3)
ffffffffc0201a88:	0141                	addi	sp,sp,16
ffffffffc0201a8a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a8c:	00005697          	auipc	a3,0x5
ffffffffc0201a90:	c2c68693          	addi	a3,a3,-980 # ffffffffc02066b8 <etext+0xe08>
ffffffffc0201a94:	00005617          	auipc	a2,0x5
ffffffffc0201a98:	89c60613          	addi	a2,a2,-1892 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201a9c:	04b00593          	li	a1,75
ffffffffc0201aa0:	00005517          	auipc	a0,0x5
ffffffffc0201aa4:	8a850513          	addi	a0,a0,-1880 # ffffffffc0206348 <etext+0xa98>
ffffffffc0201aa8:	99ffe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201aac:	00005697          	auipc	a3,0x5
ffffffffc0201ab0:	bdc68693          	addi	a3,a3,-1060 # ffffffffc0206688 <etext+0xdd8>
ffffffffc0201ab4:	00005617          	auipc	a2,0x5
ffffffffc0201ab8:	87c60613          	addi	a2,a2,-1924 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201abc:	04700593          	li	a1,71
ffffffffc0201ac0:	00005517          	auipc	a0,0x5
ffffffffc0201ac4:	88850513          	addi	a0,a0,-1912 # ffffffffc0206348 <etext+0xa98>
ffffffffc0201ac8:	97ffe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201acc <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201acc:	c531                	beqz	a0,ffffffffc0201b18 <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201ace:	e9b9                	bnez	a1,ffffffffc0201b24 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ad0:	100027f3          	csrr	a5,sstatus
ffffffffc0201ad4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ad6:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ad8:	efb1                	bnez	a5,ffffffffc0201b34 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ada:	00095797          	auipc	a5,0x95
ffffffffc0201ade:	7067b783          	ld	a5,1798(a5) # ffffffffc02971e0 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ae2:	873e                	mv	a4,a5
ffffffffc0201ae4:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ae6:	02a77a63          	bgeu	a4,a0,ffffffffc0201b1a <slob_free+0x4e>
ffffffffc0201aea:	00f56463          	bltu	a0,a5,ffffffffc0201af2 <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aee:	fef76ae3          	bltu	a4,a5,ffffffffc0201ae2 <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201af2:	4110                	lw	a2,0(a0)
ffffffffc0201af4:	00461693          	slli	a3,a2,0x4
ffffffffc0201af8:	96aa                	add	a3,a3,a0
ffffffffc0201afa:	0ad78463          	beq	a5,a3,ffffffffc0201ba2 <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201afe:	4310                	lw	a2,0(a4)
ffffffffc0201b00:	e51c                	sd	a5,8(a0)
ffffffffc0201b02:	00461693          	slli	a3,a2,0x4
ffffffffc0201b06:	96ba                	add	a3,a3,a4
ffffffffc0201b08:	08d50163          	beq	a0,a3,ffffffffc0201b8a <slob_free+0xbe>
ffffffffc0201b0c:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201b0e:	00095797          	auipc	a5,0x95
ffffffffc0201b12:	6ce7b923          	sd	a4,1746(a5) # ffffffffc02971e0 <slobfree>
    if (flag)
ffffffffc0201b16:	e9a5                	bnez	a1,ffffffffc0201b86 <slob_free+0xba>
ffffffffc0201b18:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b1a:	fcf574e3          	bgeu	a0,a5,ffffffffc0201ae2 <slob_free+0x16>
ffffffffc0201b1e:	fcf762e3          	bltu	a4,a5,ffffffffc0201ae2 <slob_free+0x16>
ffffffffc0201b22:	bfc1                	j	ffffffffc0201af2 <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201b24:	25bd                	addiw	a1,a1,15
ffffffffc0201b26:	8191                	srli	a1,a1,0x4
ffffffffc0201b28:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b2a:	100027f3          	csrr	a5,sstatus
ffffffffc0201b2e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b30:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b32:	d7c5                	beqz	a5,ffffffffc0201ada <slob_free+0xe>
{
ffffffffc0201b34:	1101                	addi	sp,sp,-32
ffffffffc0201b36:	e42a                	sd	a0,8(sp)
ffffffffc0201b38:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201b3a:	dcbfe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201b3e:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b40:	00095797          	auipc	a5,0x95
ffffffffc0201b44:	6a07b783          	ld	a5,1696(a5) # ffffffffc02971e0 <slobfree>
ffffffffc0201b48:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b4a:	873e                	mv	a4,a5
ffffffffc0201b4c:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b4e:	06a77663          	bgeu	a4,a0,ffffffffc0201bba <slob_free+0xee>
ffffffffc0201b52:	00f56463          	bltu	a0,a5,ffffffffc0201b5a <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b56:	fef76ae3          	bltu	a4,a5,ffffffffc0201b4a <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201b5a:	4110                	lw	a2,0(a0)
ffffffffc0201b5c:	00461693          	slli	a3,a2,0x4
ffffffffc0201b60:	96aa                	add	a3,a3,a0
ffffffffc0201b62:	06d78363          	beq	a5,a3,ffffffffc0201bc8 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201b66:	4310                	lw	a2,0(a4)
ffffffffc0201b68:	e51c                	sd	a5,8(a0)
ffffffffc0201b6a:	00461693          	slli	a3,a2,0x4
ffffffffc0201b6e:	96ba                	add	a3,a3,a4
ffffffffc0201b70:	06d50163          	beq	a0,a3,ffffffffc0201bd2 <slob_free+0x106>
ffffffffc0201b74:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201b76:	00095797          	auipc	a5,0x95
ffffffffc0201b7a:	66e7b523          	sd	a4,1642(a5) # ffffffffc02971e0 <slobfree>
    if (flag)
ffffffffc0201b7e:	e1a9                	bnez	a1,ffffffffc0201bc0 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b80:	60e2                	ld	ra,24(sp)
ffffffffc0201b82:	6105                	addi	sp,sp,32
ffffffffc0201b84:	8082                	ret
        intr_enable();
ffffffffc0201b86:	d79fe06f          	j	ffffffffc02008fe <intr_enable>
		cur->units += b->units;
ffffffffc0201b8a:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b8c:	853e                	mv	a0,a5
ffffffffc0201b8e:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201b90:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b94:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201b96:	00095797          	auipc	a5,0x95
ffffffffc0201b9a:	64e7b523          	sd	a4,1610(a5) # ffffffffc02971e0 <slobfree>
    if (flag)
ffffffffc0201b9e:	ddad                	beqz	a1,ffffffffc0201b18 <slob_free+0x4c>
ffffffffc0201ba0:	b7dd                	j	ffffffffc0201b86 <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201ba2:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201ba4:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201ba6:	9eb1                	addw	a3,a3,a2
ffffffffc0201ba8:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201baa:	4310                	lw	a2,0(a4)
ffffffffc0201bac:	e51c                	sd	a5,8(a0)
ffffffffc0201bae:	00461693          	slli	a3,a2,0x4
ffffffffc0201bb2:	96ba                	add	a3,a3,a4
ffffffffc0201bb4:	f4d51ce3          	bne	a0,a3,ffffffffc0201b0c <slob_free+0x40>
ffffffffc0201bb8:	bfc9                	j	ffffffffc0201b8a <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201bba:	f8f56ee3          	bltu	a0,a5,ffffffffc0201b56 <slob_free+0x8a>
ffffffffc0201bbe:	b771                	j	ffffffffc0201b4a <slob_free+0x7e>
}
ffffffffc0201bc0:	60e2                	ld	ra,24(sp)
ffffffffc0201bc2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201bc4:	d3bfe06f          	j	ffffffffc02008fe <intr_enable>
		b->units += cur->next->units;
ffffffffc0201bc8:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201bca:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201bcc:	9eb1                	addw	a3,a3,a2
ffffffffc0201bce:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201bd0:	bf59                	j	ffffffffc0201b66 <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201bd2:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201bd4:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201bd6:	00c687bb          	addw	a5,a3,a2
ffffffffc0201bda:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201bdc:	bf61                	j	ffffffffc0201b74 <slob_free+0xa8>

ffffffffc0201bde <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bde:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201be0:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201be2:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201be6:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201be8:	32a000ef          	jal	ffffffffc0201f12 <alloc_pages>
	if (!page)
ffffffffc0201bec:	c91d                	beqz	a0,ffffffffc0201c22 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201bee:	0009a697          	auipc	a3,0x9a
ffffffffc0201bf2:	a826b683          	ld	a3,-1406(a3) # ffffffffc029b670 <pages>
ffffffffc0201bf6:	00006797          	auipc	a5,0x6
ffffffffc0201bfa:	eca7b783          	ld	a5,-310(a5) # ffffffffc0207ac0 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201bfe:	0009a717          	auipc	a4,0x9a
ffffffffc0201c02:	a6a73703          	ld	a4,-1430(a4) # ffffffffc029b668 <npage>
    return page - pages + nbase;
ffffffffc0201c06:	8d15                	sub	a0,a0,a3
ffffffffc0201c08:	8519                	srai	a0,a0,0x6
ffffffffc0201c0a:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201c0c:	00c51793          	slli	a5,a0,0xc
ffffffffc0201c10:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201c12:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201c14:	00e7fa63          	bgeu	a5,a4,ffffffffc0201c28 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201c18:	0009a797          	auipc	a5,0x9a
ffffffffc0201c1c:	a487b783          	ld	a5,-1464(a5) # ffffffffc029b660 <va_pa_offset>
ffffffffc0201c20:	953e                	add	a0,a0,a5
}
ffffffffc0201c22:	60a2                	ld	ra,8(sp)
ffffffffc0201c24:	0141                	addi	sp,sp,16
ffffffffc0201c26:	8082                	ret
ffffffffc0201c28:	86aa                	mv	a3,a0
ffffffffc0201c2a:	00005617          	auipc	a2,0x5
ffffffffc0201c2e:	ab660613          	addi	a2,a2,-1354 # ffffffffc02066e0 <etext+0xe30>
ffffffffc0201c32:	07100593          	li	a1,113
ffffffffc0201c36:	00005517          	auipc	a0,0x5
ffffffffc0201c3a:	ad250513          	addi	a0,a0,-1326 # ffffffffc0206708 <etext+0xe58>
ffffffffc0201c3e:	809fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201c42 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201c42:	7179                	addi	sp,sp,-48
ffffffffc0201c44:	f406                	sd	ra,40(sp)
ffffffffc0201c46:	f022                	sd	s0,32(sp)
ffffffffc0201c48:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c4a:	01050713          	addi	a4,a0,16
ffffffffc0201c4e:	6785                	lui	a5,0x1
ffffffffc0201c50:	0af77e63          	bgeu	a4,a5,ffffffffc0201d0c <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201c54:	00f50413          	addi	s0,a0,15
ffffffffc0201c58:	8011                	srli	s0,s0,0x4
ffffffffc0201c5a:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c5c:	100025f3          	csrr	a1,sstatus
ffffffffc0201c60:	8989                	andi	a1,a1,2
ffffffffc0201c62:	edd1                	bnez	a1,ffffffffc0201cfe <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201c64:	00095497          	auipc	s1,0x95
ffffffffc0201c68:	57c48493          	addi	s1,s1,1404 # ffffffffc02971e0 <slobfree>
ffffffffc0201c6c:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c6e:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201c70:	4314                	lw	a3,0(a4)
ffffffffc0201c72:	0886da63          	bge	a3,s0,ffffffffc0201d06 <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201c76:	00e60a63          	beq	a2,a4,ffffffffc0201c8a <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c7a:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c7c:	4394                	lw	a3,0(a5)
ffffffffc0201c7e:	0286d863          	bge	a3,s0,ffffffffc0201cae <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201c82:	6090                	ld	a2,0(s1)
ffffffffc0201c84:	873e                	mv	a4,a5
ffffffffc0201c86:	fee61ae3          	bne	a2,a4,ffffffffc0201c7a <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201c8a:	e9b1                	bnez	a1,ffffffffc0201cde <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c8c:	4501                	li	a0,0
ffffffffc0201c8e:	f51ff0ef          	jal	ffffffffc0201bde <__slob_get_free_pages.constprop.0>
ffffffffc0201c92:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201c94:	c915                	beqz	a0,ffffffffc0201cc8 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c96:	6585                	lui	a1,0x1
ffffffffc0201c98:	e35ff0ef          	jal	ffffffffc0201acc <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c9c:	100025f3          	csrr	a1,sstatus
ffffffffc0201ca0:	8989                	andi	a1,a1,2
ffffffffc0201ca2:	e98d                	bnez	a1,ffffffffc0201cd4 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201ca4:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ca6:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201ca8:	4394                	lw	a3,0(a5)
ffffffffc0201caa:	fc86cce3          	blt	a3,s0,ffffffffc0201c82 <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201cae:	04d40563          	beq	s0,a3,ffffffffc0201cf8 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201cb2:	00441613          	slli	a2,s0,0x4
ffffffffc0201cb6:	963e                	add	a2,a2,a5
ffffffffc0201cb8:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201cba:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201cbc:	9e81                	subw	a3,a3,s0
ffffffffc0201cbe:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201cc0:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201cc2:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201cc4:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201cc6:	ed99                	bnez	a1,ffffffffc0201ce4 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201cc8:	70a2                	ld	ra,40(sp)
ffffffffc0201cca:	7402                	ld	s0,32(sp)
ffffffffc0201ccc:	64e2                	ld	s1,24(sp)
ffffffffc0201cce:	853e                	mv	a0,a5
ffffffffc0201cd0:	6145                	addi	sp,sp,48
ffffffffc0201cd2:	8082                	ret
        intr_disable();
ffffffffc0201cd4:	c31fe0ef          	jal	ffffffffc0200904 <intr_disable>
			cur = slobfree;
ffffffffc0201cd8:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201cda:	4585                	li	a1,1
ffffffffc0201cdc:	b7e9                	j	ffffffffc0201ca6 <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201cde:	c21fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201ce2:	b76d                	j	ffffffffc0201c8c <slob_alloc.constprop.0+0x4a>
ffffffffc0201ce4:	e43e                	sd	a5,8(sp)
ffffffffc0201ce6:	c19fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201cea:	67a2                	ld	a5,8(sp)
}
ffffffffc0201cec:	70a2                	ld	ra,40(sp)
ffffffffc0201cee:	7402                	ld	s0,32(sp)
ffffffffc0201cf0:	64e2                	ld	s1,24(sp)
ffffffffc0201cf2:	853e                	mv	a0,a5
ffffffffc0201cf4:	6145                	addi	sp,sp,48
ffffffffc0201cf6:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201cf8:	6794                	ld	a3,8(a5)
ffffffffc0201cfa:	e714                	sd	a3,8(a4)
ffffffffc0201cfc:	b7e1                	j	ffffffffc0201cc4 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201cfe:	c07fe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201d02:	4585                	li	a1,1
ffffffffc0201d04:	b785                	j	ffffffffc0201c64 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201d06:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201d08:	8732                	mv	a4,a2
ffffffffc0201d0a:	b755                	j	ffffffffc0201cae <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201d0c:	00005697          	auipc	a3,0x5
ffffffffc0201d10:	a0c68693          	addi	a3,a3,-1524 # ffffffffc0206718 <etext+0xe68>
ffffffffc0201d14:	00004617          	auipc	a2,0x4
ffffffffc0201d18:	61c60613          	addi	a2,a2,1564 # ffffffffc0206330 <etext+0xa80>
ffffffffc0201d1c:	06300593          	li	a1,99
ffffffffc0201d20:	00005517          	auipc	a0,0x5
ffffffffc0201d24:	a1850513          	addi	a0,a0,-1512 # ffffffffc0206738 <etext+0xe88>
ffffffffc0201d28:	f1efe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201d2c <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201d2c:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201d2e:	00005517          	auipc	a0,0x5
ffffffffc0201d32:	a2250513          	addi	a0,a0,-1502 # ffffffffc0206750 <etext+0xea0>
{
ffffffffc0201d36:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201d38:	c5cfe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201d3c:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d3e:	00005517          	auipc	a0,0x5
ffffffffc0201d42:	a2a50513          	addi	a0,a0,-1494 # ffffffffc0206768 <etext+0xeb8>
}
ffffffffc0201d46:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d48:	c4cfe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201d4c <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201d4c:	4501                	li	a0,0
ffffffffc0201d4e:	8082                	ret

ffffffffc0201d50 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201d50:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d52:	6685                	lui	a3,0x1
{
ffffffffc0201d54:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d56:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7bc1>
ffffffffc0201d58:	04a6f963          	bgeu	a3,a0,ffffffffc0201daa <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d5c:	e42a                	sd	a0,8(sp)
ffffffffc0201d5e:	4561                	li	a0,24
ffffffffc0201d60:	e822                	sd	s0,16(sp)
ffffffffc0201d62:	ee1ff0ef          	jal	ffffffffc0201c42 <slob_alloc.constprop.0>
ffffffffc0201d66:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201d68:	c541                	beqz	a0,ffffffffc0201df0 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201d6a:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201d6c:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201d6e:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d70:	00f75763          	bge	a4,a5,ffffffffc0201d7e <kmalloc+0x2e>
ffffffffc0201d74:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201d78:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d7a:	fef74de3          	blt	a4,a5,ffffffffc0201d74 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201d7e:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d80:	e5fff0ef          	jal	ffffffffc0201bde <__slob_get_free_pages.constprop.0>
ffffffffc0201d84:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201d86:	cd31                	beqz	a0,ffffffffc0201de2 <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d88:	100027f3          	csrr	a5,sstatus
ffffffffc0201d8c:	8b89                	andi	a5,a5,2
ffffffffc0201d8e:	eb85                	bnez	a5,ffffffffc0201dbe <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201d90:	0009a797          	auipc	a5,0x9a
ffffffffc0201d94:	8b07b783          	ld	a5,-1872(a5) # ffffffffc029b640 <bigblocks>
		bigblocks = bb;
ffffffffc0201d98:	0009a717          	auipc	a4,0x9a
ffffffffc0201d9c:	8a873423          	sd	s0,-1880(a4) # ffffffffc029b640 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201da0:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201da2:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201da4:	60e2                	ld	ra,24(sp)
ffffffffc0201da6:	6105                	addi	sp,sp,32
ffffffffc0201da8:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201daa:	0541                	addi	a0,a0,16
ffffffffc0201dac:	e97ff0ef          	jal	ffffffffc0201c42 <slob_alloc.constprop.0>
ffffffffc0201db0:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201db2:	0541                	addi	a0,a0,16
ffffffffc0201db4:	fbe5                	bnez	a5,ffffffffc0201da4 <kmalloc+0x54>
		return 0;
ffffffffc0201db6:	4501                	li	a0,0
}
ffffffffc0201db8:	60e2                	ld	ra,24(sp)
ffffffffc0201dba:	6105                	addi	sp,sp,32
ffffffffc0201dbc:	8082                	ret
        intr_disable();
ffffffffc0201dbe:	b47fe0ef          	jal	ffffffffc0200904 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201dc2:	0009a797          	auipc	a5,0x9a
ffffffffc0201dc6:	87e7b783          	ld	a5,-1922(a5) # ffffffffc029b640 <bigblocks>
		bigblocks = bb;
ffffffffc0201dca:	0009a717          	auipc	a4,0x9a
ffffffffc0201dce:	86873b23          	sd	s0,-1930(a4) # ffffffffc029b640 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201dd2:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201dd4:	b2bfe0ef          	jal	ffffffffc02008fe <intr_enable>
		return bb->pages;
ffffffffc0201dd8:	6408                	ld	a0,8(s0)
}
ffffffffc0201dda:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201ddc:	6442                	ld	s0,16(sp)
}
ffffffffc0201dde:	6105                	addi	sp,sp,32
ffffffffc0201de0:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201de2:	8522                	mv	a0,s0
ffffffffc0201de4:	45e1                	li	a1,24
ffffffffc0201de6:	ce7ff0ef          	jal	ffffffffc0201acc <slob_free>
		return 0;
ffffffffc0201dea:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dec:	6442                	ld	s0,16(sp)
ffffffffc0201dee:	b7e9                	j	ffffffffc0201db8 <kmalloc+0x68>
ffffffffc0201df0:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201df2:	4501                	li	a0,0
ffffffffc0201df4:	b7d1                	j	ffffffffc0201db8 <kmalloc+0x68>

ffffffffc0201df6 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201df6:	c571                	beqz	a0,ffffffffc0201ec2 <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201df8:	03451793          	slli	a5,a0,0x34
ffffffffc0201dfc:	e3e1                	bnez	a5,ffffffffc0201ebc <kfree+0xc6>
{
ffffffffc0201dfe:	1101                	addi	sp,sp,-32
ffffffffc0201e00:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e02:	100027f3          	csrr	a5,sstatus
ffffffffc0201e06:	8b89                	andi	a5,a5,2
ffffffffc0201e08:	e7c1                	bnez	a5,ffffffffc0201e90 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e0a:	0009a797          	auipc	a5,0x9a
ffffffffc0201e0e:	8367b783          	ld	a5,-1994(a5) # ffffffffc029b640 <bigblocks>
    return 0;
ffffffffc0201e12:	4581                	li	a1,0
ffffffffc0201e14:	cbad                	beqz	a5,ffffffffc0201e86 <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201e16:	0009a617          	auipc	a2,0x9a
ffffffffc0201e1a:	82a60613          	addi	a2,a2,-2006 # ffffffffc029b640 <bigblocks>
ffffffffc0201e1e:	a021                	j	ffffffffc0201e26 <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e20:	01070613          	addi	a2,a4,16
ffffffffc0201e24:	c3a5                	beqz	a5,ffffffffc0201e84 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201e26:	6794                	ld	a3,8(a5)
ffffffffc0201e28:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201e2a:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201e2c:	fea69ae3          	bne	a3,a0,ffffffffc0201e20 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201e30:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201e32:	edb5                	bnez	a1,ffffffffc0201eae <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201e34:	c02007b7          	lui	a5,0xc0200
ffffffffc0201e38:	0af56263          	bltu	a0,a5,ffffffffc0201edc <kfree+0xe6>
ffffffffc0201e3c:	0009a797          	auipc	a5,0x9a
ffffffffc0201e40:	8247b783          	ld	a5,-2012(a5) # ffffffffc029b660 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201e44:	0009a697          	auipc	a3,0x9a
ffffffffc0201e48:	8246b683          	ld	a3,-2012(a3) # ffffffffc029b668 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201e4c:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201e4e:	00c55793          	srli	a5,a0,0xc
ffffffffc0201e52:	06d7f963          	bgeu	a5,a3,ffffffffc0201ec4 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e56:	00006617          	auipc	a2,0x6
ffffffffc0201e5a:	c6a63603          	ld	a2,-918(a2) # ffffffffc0207ac0 <nbase>
ffffffffc0201e5e:	0009a517          	auipc	a0,0x9a
ffffffffc0201e62:	81253503          	ld	a0,-2030(a0) # ffffffffc029b670 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201e66:	4314                	lw	a3,0(a4)
ffffffffc0201e68:	8f91                	sub	a5,a5,a2
ffffffffc0201e6a:	079a                	slli	a5,a5,0x6
ffffffffc0201e6c:	4585                	li	a1,1
ffffffffc0201e6e:	953e                	add	a0,a0,a5
ffffffffc0201e70:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201e74:	e03a                	sd	a4,0(sp)
ffffffffc0201e76:	0d6000ef          	jal	ffffffffc0201f4c <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e7a:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e7c:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e7e:	45e1                	li	a1,24
}
ffffffffc0201e80:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e82:	b1a9                	j	ffffffffc0201acc <slob_free>
ffffffffc0201e84:	e185                	bnez	a1,ffffffffc0201ea4 <kfree+0xae>
}
ffffffffc0201e86:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e88:	1541                	addi	a0,a0,-16
ffffffffc0201e8a:	4581                	li	a1,0
}
ffffffffc0201e8c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e8e:	b93d                	j	ffffffffc0201acc <slob_free>
        intr_disable();
ffffffffc0201e90:	e02a                	sd	a0,0(sp)
ffffffffc0201e92:	a73fe0ef          	jal	ffffffffc0200904 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e96:	00099797          	auipc	a5,0x99
ffffffffc0201e9a:	7aa7b783          	ld	a5,1962(a5) # ffffffffc029b640 <bigblocks>
ffffffffc0201e9e:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201ea0:	4585                	li	a1,1
ffffffffc0201ea2:	fbb5                	bnez	a5,ffffffffc0201e16 <kfree+0x20>
ffffffffc0201ea4:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201ea6:	a59fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201eaa:	6502                	ld	a0,0(sp)
ffffffffc0201eac:	bfe9                	j	ffffffffc0201e86 <kfree+0x90>
ffffffffc0201eae:	e42a                	sd	a0,8(sp)
ffffffffc0201eb0:	e03a                	sd	a4,0(sp)
ffffffffc0201eb2:	a4dfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201eb6:	6522                	ld	a0,8(sp)
ffffffffc0201eb8:	6702                	ld	a4,0(sp)
ffffffffc0201eba:	bfad                	j	ffffffffc0201e34 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ebc:	1541                	addi	a0,a0,-16
ffffffffc0201ebe:	4581                	li	a1,0
ffffffffc0201ec0:	b131                	j	ffffffffc0201acc <slob_free>
ffffffffc0201ec2:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201ec4:	00005617          	auipc	a2,0x5
ffffffffc0201ec8:	8ec60613          	addi	a2,a2,-1812 # ffffffffc02067b0 <etext+0xf00>
ffffffffc0201ecc:	06900593          	li	a1,105
ffffffffc0201ed0:	00005517          	auipc	a0,0x5
ffffffffc0201ed4:	83850513          	addi	a0,a0,-1992 # ffffffffc0206708 <etext+0xe58>
ffffffffc0201ed8:	d6efe0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201edc:	86aa                	mv	a3,a0
ffffffffc0201ede:	00005617          	auipc	a2,0x5
ffffffffc0201ee2:	8aa60613          	addi	a2,a2,-1878 # ffffffffc0206788 <etext+0xed8>
ffffffffc0201ee6:	07700593          	li	a1,119
ffffffffc0201eea:	00005517          	auipc	a0,0x5
ffffffffc0201eee:	81e50513          	addi	a0,a0,-2018 # ffffffffc0206708 <etext+0xe58>
ffffffffc0201ef2:	d54fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201ef6 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201ef6:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201ef8:	00005617          	auipc	a2,0x5
ffffffffc0201efc:	8b860613          	addi	a2,a2,-1864 # ffffffffc02067b0 <etext+0xf00>
ffffffffc0201f00:	06900593          	li	a1,105
ffffffffc0201f04:	00005517          	auipc	a0,0x5
ffffffffc0201f08:	80450513          	addi	a0,a0,-2044 # ffffffffc0206708 <etext+0xe58>
pa2page(uintptr_t pa)
ffffffffc0201f0c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201f0e:	d38fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201f12 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f12:	100027f3          	csrr	a5,sstatus
ffffffffc0201f16:	8b89                	andi	a5,a5,2
ffffffffc0201f18:	e799                	bnez	a5,ffffffffc0201f26 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f1a:	00099797          	auipc	a5,0x99
ffffffffc0201f1e:	72e7b783          	ld	a5,1838(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201f22:	6f9c                	ld	a5,24(a5)
ffffffffc0201f24:	8782                	jr	a5
{
ffffffffc0201f26:	1101                	addi	sp,sp,-32
ffffffffc0201f28:	ec06                	sd	ra,24(sp)
ffffffffc0201f2a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201f2c:	9d9fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f30:	00099797          	auipc	a5,0x99
ffffffffc0201f34:	7187b783          	ld	a5,1816(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201f38:	6522                	ld	a0,8(sp)
ffffffffc0201f3a:	6f9c                	ld	a5,24(a5)
ffffffffc0201f3c:	9782                	jalr	a5
ffffffffc0201f3e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f40:	9bffe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f44:	60e2                	ld	ra,24(sp)
ffffffffc0201f46:	6522                	ld	a0,8(sp)
ffffffffc0201f48:	6105                	addi	sp,sp,32
ffffffffc0201f4a:	8082                	ret

ffffffffc0201f4c <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f4c:	100027f3          	csrr	a5,sstatus
ffffffffc0201f50:	8b89                	andi	a5,a5,2
ffffffffc0201f52:	e799                	bnez	a5,ffffffffc0201f60 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f54:	00099797          	auipc	a5,0x99
ffffffffc0201f58:	6f47b783          	ld	a5,1780(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201f5c:	739c                	ld	a5,32(a5)
ffffffffc0201f5e:	8782                	jr	a5
{
ffffffffc0201f60:	1101                	addi	sp,sp,-32
ffffffffc0201f62:	ec06                	sd	ra,24(sp)
ffffffffc0201f64:	e42e                	sd	a1,8(sp)
ffffffffc0201f66:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201f68:	99dfe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f6c:	00099797          	auipc	a5,0x99
ffffffffc0201f70:	6dc7b783          	ld	a5,1756(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201f74:	65a2                	ld	a1,8(sp)
ffffffffc0201f76:	6502                	ld	a0,0(sp)
ffffffffc0201f78:	739c                	ld	a5,32(a5)
ffffffffc0201f7a:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f7c:	60e2                	ld	ra,24(sp)
ffffffffc0201f7e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f80:	97ffe06f          	j	ffffffffc02008fe <intr_enable>

ffffffffc0201f84 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f84:	100027f3          	csrr	a5,sstatus
ffffffffc0201f88:	8b89                	andi	a5,a5,2
ffffffffc0201f8a:	e799                	bnez	a5,ffffffffc0201f98 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f8c:	00099797          	auipc	a5,0x99
ffffffffc0201f90:	6bc7b783          	ld	a5,1724(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201f94:	779c                	ld	a5,40(a5)
ffffffffc0201f96:	8782                	jr	a5
{
ffffffffc0201f98:	1101                	addi	sp,sp,-32
ffffffffc0201f9a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201f9c:	969fe0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201fa0:	00099797          	auipc	a5,0x99
ffffffffc0201fa4:	6a87b783          	ld	a5,1704(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201fa8:	779c                	ld	a5,40(a5)
ffffffffc0201faa:	9782                	jalr	a5
ffffffffc0201fac:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201fae:	951fe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201fb2:	60e2                	ld	ra,24(sp)
ffffffffc0201fb4:	6522                	ld	a0,8(sp)
ffffffffc0201fb6:	6105                	addi	sp,sp,32
ffffffffc0201fb8:	8082                	ret

ffffffffc0201fba <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201fba:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201fbe:	1ff7f793          	andi	a5,a5,511
ffffffffc0201fc2:	078e                	slli	a5,a5,0x3
ffffffffc0201fc4:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201fc8:	6314                	ld	a3,0(a4)
{
ffffffffc0201fca:	7139                	addi	sp,sp,-64
ffffffffc0201fcc:	f822                	sd	s0,48(sp)
ffffffffc0201fce:	f426                	sd	s1,40(sp)
ffffffffc0201fd0:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201fd2:	0016f793          	andi	a5,a3,1
{
ffffffffc0201fd6:	842e                	mv	s0,a1
ffffffffc0201fd8:	8832                	mv	a6,a2
ffffffffc0201fda:	00099497          	auipc	s1,0x99
ffffffffc0201fde:	68e48493          	addi	s1,s1,1678 # ffffffffc029b668 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201fe2:	ebd1                	bnez	a5,ffffffffc0202076 <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fe4:	16060d63          	beqz	a2,ffffffffc020215e <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201fe8:	100027f3          	csrr	a5,sstatus
ffffffffc0201fec:	8b89                	andi	a5,a5,2
ffffffffc0201fee:	16079e63          	bnez	a5,ffffffffc020216a <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ff2:	00099797          	auipc	a5,0x99
ffffffffc0201ff6:	6567b783          	ld	a5,1622(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201ffa:	4505                	li	a0,1
ffffffffc0201ffc:	e43a                	sd	a4,8(sp)
ffffffffc0201ffe:	6f9c                	ld	a5,24(a5)
ffffffffc0202000:	e832                	sd	a2,16(sp)
ffffffffc0202002:	9782                	jalr	a5
ffffffffc0202004:	6722                	ld	a4,8(sp)
ffffffffc0202006:	6842                	ld	a6,16(sp)
ffffffffc0202008:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc020200a:	14078a63          	beqz	a5,ffffffffc020215e <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc020200e:	00099517          	auipc	a0,0x99
ffffffffc0202012:	66253503          	ld	a0,1634(a0) # ffffffffc029b670 <pages>
ffffffffc0202016:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020201a:	00099497          	auipc	s1,0x99
ffffffffc020201e:	64e48493          	addi	s1,s1,1614 # ffffffffc029b668 <npage>
ffffffffc0202022:	40a78533          	sub	a0,a5,a0
ffffffffc0202026:	8519                	srai	a0,a0,0x6
ffffffffc0202028:	9546                	add	a0,a0,a7
ffffffffc020202a:	6090                	ld	a2,0(s1)
ffffffffc020202c:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0202030:	4585                	li	a1,1
ffffffffc0202032:	82b1                	srli	a3,a3,0xc
ffffffffc0202034:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0202036:	0532                	slli	a0,a0,0xc
ffffffffc0202038:	1ac6f763          	bgeu	a3,a2,ffffffffc02021e6 <get_pte+0x22c>
ffffffffc020203c:	00099697          	auipc	a3,0x99
ffffffffc0202040:	6246b683          	ld	a3,1572(a3) # ffffffffc029b660 <va_pa_offset>
ffffffffc0202044:	6605                	lui	a2,0x1
ffffffffc0202046:	4581                	li	a1,0
ffffffffc0202048:	9536                	add	a0,a0,a3
ffffffffc020204a:	ec42                	sd	a6,24(sp)
ffffffffc020204c:	e83e                	sd	a5,16(sp)
ffffffffc020204e:	e43a                	sd	a4,8(sp)
ffffffffc0202050:	037030ef          	jal	ffffffffc0205886 <memset>
    return page - pages + nbase;
ffffffffc0202054:	00099697          	auipc	a3,0x99
ffffffffc0202058:	61c6b683          	ld	a3,1564(a3) # ffffffffc029b670 <pages>
ffffffffc020205c:	67c2                	ld	a5,16(sp)
ffffffffc020205e:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202062:	6722                	ld	a4,8(sp)
ffffffffc0202064:	40d786b3          	sub	a3,a5,a3
ffffffffc0202068:	8699                	srai	a3,a3,0x6
ffffffffc020206a:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020206c:	06aa                	slli	a3,a3,0xa
ffffffffc020206e:	6862                	ld	a6,24(sp)
ffffffffc0202070:	0116e693          	ori	a3,a3,17
ffffffffc0202074:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202076:	c006f693          	andi	a3,a3,-1024
ffffffffc020207a:	6098                	ld	a4,0(s1)
ffffffffc020207c:	068a                	slli	a3,a3,0x2
ffffffffc020207e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202082:	14e7f663          	bgeu	a5,a4,ffffffffc02021ce <get_pte+0x214>
ffffffffc0202086:	00099897          	auipc	a7,0x99
ffffffffc020208a:	5da88893          	addi	a7,a7,1498 # ffffffffc029b660 <va_pa_offset>
ffffffffc020208e:	0008b603          	ld	a2,0(a7)
ffffffffc0202092:	01545793          	srli	a5,s0,0x15
ffffffffc0202096:	1ff7f793          	andi	a5,a5,511
ffffffffc020209a:	96b2                	add	a3,a3,a2
ffffffffc020209c:	078e                	slli	a5,a5,0x3
ffffffffc020209e:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc02020a0:	6394                	ld	a3,0(a5)
ffffffffc02020a2:	0016f613          	andi	a2,a3,1
ffffffffc02020a6:	e659                	bnez	a2,ffffffffc0202134 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020a8:	0a080b63          	beqz	a6,ffffffffc020215e <get_pte+0x1a4>
ffffffffc02020ac:	10002773          	csrr	a4,sstatus
ffffffffc02020b0:	8b09                	andi	a4,a4,2
ffffffffc02020b2:	ef71                	bnez	a4,ffffffffc020218e <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020b4:	00099717          	auipc	a4,0x99
ffffffffc02020b8:	59473703          	ld	a4,1428(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc02020bc:	4505                	li	a0,1
ffffffffc02020be:	e43e                	sd	a5,8(sp)
ffffffffc02020c0:	6f18                	ld	a4,24(a4)
ffffffffc02020c2:	9702                	jalr	a4
ffffffffc02020c4:	67a2                	ld	a5,8(sp)
ffffffffc02020c6:	872a                	mv	a4,a0
ffffffffc02020c8:	00099897          	auipc	a7,0x99
ffffffffc02020cc:	59888893          	addi	a7,a7,1432 # ffffffffc029b660 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020d0:	c759                	beqz	a4,ffffffffc020215e <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc02020d2:	00099697          	auipc	a3,0x99
ffffffffc02020d6:	59e6b683          	ld	a3,1438(a3) # ffffffffc029b670 <pages>
ffffffffc02020da:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020de:	608c                	ld	a1,0(s1)
ffffffffc02020e0:	40d706b3          	sub	a3,a4,a3
ffffffffc02020e4:	8699                	srai	a3,a3,0x6
ffffffffc02020e6:	96c2                	add	a3,a3,a6
ffffffffc02020e8:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc02020ec:	4505                	li	a0,1
ffffffffc02020ee:	8231                	srli	a2,a2,0xc
ffffffffc02020f0:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc02020f2:	06b2                	slli	a3,a3,0xc
ffffffffc02020f4:	10b67663          	bgeu	a2,a1,ffffffffc0202200 <get_pte+0x246>
ffffffffc02020f8:	0008b503          	ld	a0,0(a7)
ffffffffc02020fc:	6605                	lui	a2,0x1
ffffffffc02020fe:	4581                	li	a1,0
ffffffffc0202100:	9536                	add	a0,a0,a3
ffffffffc0202102:	e83a                	sd	a4,16(sp)
ffffffffc0202104:	e43e                	sd	a5,8(sp)
ffffffffc0202106:	780030ef          	jal	ffffffffc0205886 <memset>
    return page - pages + nbase;
ffffffffc020210a:	00099697          	auipc	a3,0x99
ffffffffc020210e:	5666b683          	ld	a3,1382(a3) # ffffffffc029b670 <pages>
ffffffffc0202112:	6742                	ld	a4,16(sp)
ffffffffc0202114:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202118:	67a2                	ld	a5,8(sp)
ffffffffc020211a:	40d706b3          	sub	a3,a4,a3
ffffffffc020211e:	8699                	srai	a3,a3,0x6
ffffffffc0202120:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202122:	06aa                	slli	a3,a3,0xa
ffffffffc0202124:	0116e693          	ori	a3,a3,17
ffffffffc0202128:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020212a:	6098                	ld	a4,0(s1)
ffffffffc020212c:	00099897          	auipc	a7,0x99
ffffffffc0202130:	53488893          	addi	a7,a7,1332 # ffffffffc029b660 <va_pa_offset>
ffffffffc0202134:	c006f693          	andi	a3,a3,-1024
ffffffffc0202138:	068a                	slli	a3,a3,0x2
ffffffffc020213a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020213e:	06e7fc63          	bgeu	a5,a4,ffffffffc02021b6 <get_pte+0x1fc>
ffffffffc0202142:	0008b783          	ld	a5,0(a7)
ffffffffc0202146:	8031                	srli	s0,s0,0xc
ffffffffc0202148:	1ff47413          	andi	s0,s0,511
ffffffffc020214c:	040e                	slli	s0,s0,0x3
ffffffffc020214e:	96be                	add	a3,a3,a5
}
ffffffffc0202150:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202152:	00868533          	add	a0,a3,s0
}
ffffffffc0202156:	7442                	ld	s0,48(sp)
ffffffffc0202158:	74a2                	ld	s1,40(sp)
ffffffffc020215a:	6121                	addi	sp,sp,64
ffffffffc020215c:	8082                	ret
ffffffffc020215e:	70e2                	ld	ra,56(sp)
ffffffffc0202160:	7442                	ld	s0,48(sp)
ffffffffc0202162:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0202164:	4501                	li	a0,0
}
ffffffffc0202166:	6121                	addi	sp,sp,64
ffffffffc0202168:	8082                	ret
        intr_disable();
ffffffffc020216a:	e83a                	sd	a4,16(sp)
ffffffffc020216c:	ec32                	sd	a2,24(sp)
ffffffffc020216e:	f96fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202172:	00099797          	auipc	a5,0x99
ffffffffc0202176:	4d67b783          	ld	a5,1238(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc020217a:	4505                	li	a0,1
ffffffffc020217c:	6f9c                	ld	a5,24(a5)
ffffffffc020217e:	9782                	jalr	a5
ffffffffc0202180:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202182:	f7cfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202186:	6862                	ld	a6,24(sp)
ffffffffc0202188:	6742                	ld	a4,16(sp)
ffffffffc020218a:	67a2                	ld	a5,8(sp)
ffffffffc020218c:	bdbd                	j	ffffffffc020200a <get_pte+0x50>
        intr_disable();
ffffffffc020218e:	e83e                	sd	a5,16(sp)
ffffffffc0202190:	f74fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202194:	00099717          	auipc	a4,0x99
ffffffffc0202198:	4b473703          	ld	a4,1204(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc020219c:	4505                	li	a0,1
ffffffffc020219e:	6f18                	ld	a4,24(a4)
ffffffffc02021a0:	9702                	jalr	a4
ffffffffc02021a2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02021a4:	f5afe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02021a8:	6722                	ld	a4,8(sp)
ffffffffc02021aa:	67c2                	ld	a5,16(sp)
ffffffffc02021ac:	00099897          	auipc	a7,0x99
ffffffffc02021b0:	4b488893          	addi	a7,a7,1204 # ffffffffc029b660 <va_pa_offset>
ffffffffc02021b4:	bf31                	j	ffffffffc02020d0 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02021b6:	00004617          	auipc	a2,0x4
ffffffffc02021ba:	52a60613          	addi	a2,a2,1322 # ffffffffc02066e0 <etext+0xe30>
ffffffffc02021be:	0fa00593          	li	a1,250
ffffffffc02021c2:	00004517          	auipc	a0,0x4
ffffffffc02021c6:	60e50513          	addi	a0,a0,1550 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02021ca:	a7cfe0ef          	jal	ffffffffc0200446 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02021ce:	00004617          	auipc	a2,0x4
ffffffffc02021d2:	51260613          	addi	a2,a2,1298 # ffffffffc02066e0 <etext+0xe30>
ffffffffc02021d6:	0ed00593          	li	a1,237
ffffffffc02021da:	00004517          	auipc	a0,0x4
ffffffffc02021de:	5f650513          	addi	a0,a0,1526 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02021e2:	a64fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021e6:	86aa                	mv	a3,a0
ffffffffc02021e8:	00004617          	auipc	a2,0x4
ffffffffc02021ec:	4f860613          	addi	a2,a2,1272 # ffffffffc02066e0 <etext+0xe30>
ffffffffc02021f0:	0e900593          	li	a1,233
ffffffffc02021f4:	00004517          	auipc	a0,0x4
ffffffffc02021f8:	5dc50513          	addi	a0,a0,1500 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02021fc:	a4afe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202200:	00004617          	auipc	a2,0x4
ffffffffc0202204:	4e060613          	addi	a2,a2,1248 # ffffffffc02066e0 <etext+0xe30>
ffffffffc0202208:	0f700593          	li	a1,247
ffffffffc020220c:	00004517          	auipc	a0,0x4
ffffffffc0202210:	5c450513          	addi	a0,a0,1476 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0202214:	a32fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0202218 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202218:	1141                	addi	sp,sp,-16
ffffffffc020221a:	e022                	sd	s0,0(sp)
ffffffffc020221c:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020221e:	4601                	li	a2,0
{
ffffffffc0202220:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202222:	d99ff0ef          	jal	ffffffffc0201fba <get_pte>
    if (ptep_store != NULL)
ffffffffc0202226:	c011                	beqz	s0,ffffffffc020222a <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202228:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020222a:	c511                	beqz	a0,ffffffffc0202236 <get_page+0x1e>
ffffffffc020222c:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020222e:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202230:	0017f713          	andi	a4,a5,1
ffffffffc0202234:	e709                	bnez	a4,ffffffffc020223e <get_page+0x26>
}
ffffffffc0202236:	60a2                	ld	ra,8(sp)
ffffffffc0202238:	6402                	ld	s0,0(sp)
ffffffffc020223a:	0141                	addi	sp,sp,16
ffffffffc020223c:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc020223e:	00099717          	auipc	a4,0x99
ffffffffc0202242:	42a73703          	ld	a4,1066(a4) # ffffffffc029b668 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202246:	078a                	slli	a5,a5,0x2
ffffffffc0202248:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020224a:	00e7ff63          	bgeu	a5,a4,ffffffffc0202268 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc020224e:	00099517          	auipc	a0,0x99
ffffffffc0202252:	42253503          	ld	a0,1058(a0) # ffffffffc029b670 <pages>
ffffffffc0202256:	60a2                	ld	ra,8(sp)
ffffffffc0202258:	6402                	ld	s0,0(sp)
ffffffffc020225a:	079a                	slli	a5,a5,0x6
ffffffffc020225c:	fe000737          	lui	a4,0xfe000
ffffffffc0202260:	97ba                	add	a5,a5,a4
ffffffffc0202262:	953e                	add	a0,a0,a5
ffffffffc0202264:	0141                	addi	sp,sp,16
ffffffffc0202266:	8082                	ret
ffffffffc0202268:	c8fff0ef          	jal	ffffffffc0201ef6 <pa2page.part.0>

ffffffffc020226c <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc020226c:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020226e:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202272:	e486                	sd	ra,72(sp)
ffffffffc0202274:	e0a2                	sd	s0,64(sp)
ffffffffc0202276:	fc26                	sd	s1,56(sp)
ffffffffc0202278:	f84a                	sd	s2,48(sp)
ffffffffc020227a:	f44e                	sd	s3,40(sp)
ffffffffc020227c:	f052                	sd	s4,32(sp)
ffffffffc020227e:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202280:	03479713          	slli	a4,a5,0x34
ffffffffc0202284:	ef61                	bnez	a4,ffffffffc020235c <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc0202286:	00200a37          	lui	s4,0x200
ffffffffc020228a:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020228e:	0145b733          	sltu	a4,a1,s4
ffffffffc0202292:	0017b793          	seqz	a5,a5
ffffffffc0202296:	8fd9                	or	a5,a5,a4
ffffffffc0202298:	842e                	mv	s0,a1
ffffffffc020229a:	84b2                	mv	s1,a2
ffffffffc020229c:	e3e5                	bnez	a5,ffffffffc020237c <unmap_range+0x110>
ffffffffc020229e:	4785                	li	a5,1
ffffffffc02022a0:	07fe                	slli	a5,a5,0x1f
ffffffffc02022a2:	0785                	addi	a5,a5,1
ffffffffc02022a4:	892a                	mv	s2,a0
ffffffffc02022a6:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022a8:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc02022ac:	0cf67863          	bgeu	a2,a5,ffffffffc020237c <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02022b0:	4601                	li	a2,0
ffffffffc02022b2:	85a2                	mv	a1,s0
ffffffffc02022b4:	854a                	mv	a0,s2
ffffffffc02022b6:	d05ff0ef          	jal	ffffffffc0201fba <get_pte>
ffffffffc02022ba:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc02022bc:	cd31                	beqz	a0,ffffffffc0202318 <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc02022be:	6118                	ld	a4,0(a0)
ffffffffc02022c0:	ef11                	bnez	a4,ffffffffc02022dc <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02022c2:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc02022c4:	c019                	beqz	s0,ffffffffc02022ca <unmap_range+0x5e>
ffffffffc02022c6:	fe9465e3          	bltu	s0,s1,ffffffffc02022b0 <unmap_range+0x44>
}
ffffffffc02022ca:	60a6                	ld	ra,72(sp)
ffffffffc02022cc:	6406                	ld	s0,64(sp)
ffffffffc02022ce:	74e2                	ld	s1,56(sp)
ffffffffc02022d0:	7942                	ld	s2,48(sp)
ffffffffc02022d2:	79a2                	ld	s3,40(sp)
ffffffffc02022d4:	7a02                	ld	s4,32(sp)
ffffffffc02022d6:	6ae2                	ld	s5,24(sp)
ffffffffc02022d8:	6161                	addi	sp,sp,80
ffffffffc02022da:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc02022dc:	00177693          	andi	a3,a4,1
ffffffffc02022e0:	d2ed                	beqz	a3,ffffffffc02022c2 <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc02022e2:	00099697          	auipc	a3,0x99
ffffffffc02022e6:	3866b683          	ld	a3,902(a3) # ffffffffc029b668 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02022ea:	070a                	slli	a4,a4,0x2
ffffffffc02022ec:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc02022ee:	0ad77763          	bgeu	a4,a3,ffffffffc020239c <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc02022f2:	00099517          	auipc	a0,0x99
ffffffffc02022f6:	37e53503          	ld	a0,894(a0) # ffffffffc029b670 <pages>
ffffffffc02022fa:	071a                	slli	a4,a4,0x6
ffffffffc02022fc:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202300:	9736                	add	a4,a4,a3
ffffffffc0202302:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202304:	4118                	lw	a4,0(a0)
ffffffffc0202306:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd64967>
ffffffffc0202308:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020230a:	cb19                	beqz	a4,ffffffffc0202320 <unmap_range+0xb4>
        *ptep = 0;
ffffffffc020230c:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202310:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0202314:	944e                	add	s0,s0,s3
ffffffffc0202316:	b77d                	j	ffffffffc02022c4 <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202318:	9452                	add	s0,s0,s4
ffffffffc020231a:	01547433          	and	s0,s0,s5
            continue;
ffffffffc020231e:	b75d                	j	ffffffffc02022c4 <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202320:	10002773          	csrr	a4,sstatus
ffffffffc0202324:	8b09                	andi	a4,a4,2
ffffffffc0202326:	eb19                	bnez	a4,ffffffffc020233c <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc0202328:	00099717          	auipc	a4,0x99
ffffffffc020232c:	32073703          	ld	a4,800(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc0202330:	4585                	li	a1,1
ffffffffc0202332:	e03e                	sd	a5,0(sp)
ffffffffc0202334:	7318                	ld	a4,32(a4)
ffffffffc0202336:	9702                	jalr	a4
    if (flag)
ffffffffc0202338:	6782                	ld	a5,0(sp)
ffffffffc020233a:	bfc9                	j	ffffffffc020230c <unmap_range+0xa0>
        intr_disable();
ffffffffc020233c:	e43e                	sd	a5,8(sp)
ffffffffc020233e:	e02a                	sd	a0,0(sp)
ffffffffc0202340:	dc4fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202344:	00099717          	auipc	a4,0x99
ffffffffc0202348:	30473703          	ld	a4,772(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc020234c:	6502                	ld	a0,0(sp)
ffffffffc020234e:	4585                	li	a1,1
ffffffffc0202350:	7318                	ld	a4,32(a4)
ffffffffc0202352:	9702                	jalr	a4
        intr_enable();
ffffffffc0202354:	daafe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202358:	67a2                	ld	a5,8(sp)
ffffffffc020235a:	bf4d                	j	ffffffffc020230c <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020235c:	00004697          	auipc	a3,0x4
ffffffffc0202360:	48468693          	addi	a3,a3,1156 # ffffffffc02067e0 <etext+0xf30>
ffffffffc0202364:	00004617          	auipc	a2,0x4
ffffffffc0202368:	fcc60613          	addi	a2,a2,-52 # ffffffffc0206330 <etext+0xa80>
ffffffffc020236c:	12000593          	li	a1,288
ffffffffc0202370:	00004517          	auipc	a0,0x4
ffffffffc0202374:	46050513          	addi	a0,a0,1120 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0202378:	8cefe0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020237c:	00004697          	auipc	a3,0x4
ffffffffc0202380:	49468693          	addi	a3,a3,1172 # ffffffffc0206810 <etext+0xf60>
ffffffffc0202384:	00004617          	auipc	a2,0x4
ffffffffc0202388:	fac60613          	addi	a2,a2,-84 # ffffffffc0206330 <etext+0xa80>
ffffffffc020238c:	12100593          	li	a1,289
ffffffffc0202390:	00004517          	auipc	a0,0x4
ffffffffc0202394:	44050513          	addi	a0,a0,1088 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0202398:	8aefe0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc020239c:	b5bff0ef          	jal	ffffffffc0201ef6 <pa2page.part.0>

ffffffffc02023a0 <exit_range>:
{
ffffffffc02023a0:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023a2:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02023a6:	ed06                	sd	ra,152(sp)
ffffffffc02023a8:	e922                	sd	s0,144(sp)
ffffffffc02023aa:	e526                	sd	s1,136(sp)
ffffffffc02023ac:	e14a                	sd	s2,128(sp)
ffffffffc02023ae:	fcce                	sd	s3,120(sp)
ffffffffc02023b0:	f8d2                	sd	s4,112(sp)
ffffffffc02023b2:	f4d6                	sd	s5,104(sp)
ffffffffc02023b4:	f0da                	sd	s6,96(sp)
ffffffffc02023b6:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02023b8:	17d2                	slli	a5,a5,0x34
ffffffffc02023ba:	22079263          	bnez	a5,ffffffffc02025de <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc02023be:	00200937          	lui	s2,0x200
ffffffffc02023c2:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc02023c6:	0125b733          	sltu	a4,a1,s2
ffffffffc02023ca:	0017b793          	seqz	a5,a5
ffffffffc02023ce:	8fd9                	or	a5,a5,a4
ffffffffc02023d0:	26079263          	bnez	a5,ffffffffc0202634 <exit_range+0x294>
ffffffffc02023d4:	4785                	li	a5,1
ffffffffc02023d6:	07fe                	slli	a5,a5,0x1f
ffffffffc02023d8:	0785                	addi	a5,a5,1
ffffffffc02023da:	24f67d63          	bgeu	a2,a5,ffffffffc0202634 <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02023de:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02023e2:	ffe007b7          	lui	a5,0xffe00
ffffffffc02023e6:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02023e8:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02023ea:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc02023ee:	00099a97          	auipc	s5,0x99
ffffffffc02023f2:	27aa8a93          	addi	s5,s5,634 # ffffffffc029b668 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023f6:	400009b7          	lui	s3,0x40000
ffffffffc02023fa:	a809                	j	ffffffffc020240c <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc02023fc:	013487b3          	add	a5,s1,s3
ffffffffc0202400:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc0202404:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc0202406:	c3f1                	beqz	a5,ffffffffc02024ca <exit_range+0x12a>
ffffffffc0202408:	0cc7f163          	bgeu	a5,a2,ffffffffc02024ca <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc020240c:	01e4d413          	srli	s0,s1,0x1e
ffffffffc0202410:	1ff47413          	andi	s0,s0,511
ffffffffc0202414:	040e                	slli	s0,s0,0x3
ffffffffc0202416:	9452                	add	s0,s0,s4
ffffffffc0202418:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc020241c:	0018f793          	andi	a5,a7,1
ffffffffc0202420:	dff1                	beqz	a5,ffffffffc02023fc <exit_range+0x5c>
ffffffffc0202422:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202426:	088a                	slli	a7,a7,0x2
ffffffffc0202428:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc020242c:	20f8f263          	bgeu	a7,a5,ffffffffc0202630 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202430:	fff802b7          	lui	t0,0xfff80
ffffffffc0202434:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc0202438:	000803b7          	lui	t2,0x80
ffffffffc020243c:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202440:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202444:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc0202446:	1cf77863          	bgeu	a4,a5,ffffffffc0202616 <exit_range+0x276>
ffffffffc020244a:	00099f97          	auipc	t6,0x99
ffffffffc020244e:	216f8f93          	addi	t6,t6,534 # ffffffffc029b660 <va_pa_offset>
ffffffffc0202452:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc0202456:	4e85                	li	t4,1
ffffffffc0202458:	6b05                	lui	s6,0x1
ffffffffc020245a:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020245c:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc0202460:	01585713          	srli	a4,a6,0x15
ffffffffc0202464:	1ff77713          	andi	a4,a4,511
ffffffffc0202468:	070e                	slli	a4,a4,0x3
ffffffffc020246a:	9772                	add	a4,a4,t3
ffffffffc020246c:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc020246e:	0017f693          	andi	a3,a5,1
ffffffffc0202472:	e6bd                	bnez	a3,ffffffffc02024e0 <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc0202474:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc0202476:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202478:	00080863          	beqz	a6,ffffffffc0202488 <exit_range+0xe8>
ffffffffc020247c:	879a                	mv	a5,t1
ffffffffc020247e:	00667363          	bgeu	a2,t1,ffffffffc0202484 <exit_range+0xe4>
ffffffffc0202482:	87b2                	mv	a5,a2
ffffffffc0202484:	fcf86ee3          	bltu	a6,a5,ffffffffc0202460 <exit_range+0xc0>
            if (free_pd0)
ffffffffc0202488:	f60e8ae3          	beqz	t4,ffffffffc02023fc <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc020248c:	000ab783          	ld	a5,0(s5)
ffffffffc0202490:	1af8f063          	bgeu	a7,a5,ffffffffc0202630 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202494:	00099517          	auipc	a0,0x99
ffffffffc0202498:	1dc53503          	ld	a0,476(a0) # ffffffffc029b670 <pages>
ffffffffc020249c:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020249e:	100027f3          	csrr	a5,sstatus
ffffffffc02024a2:	8b89                	andi	a5,a5,2
ffffffffc02024a4:	10079b63          	bnez	a5,ffffffffc02025ba <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc02024a8:	00099797          	auipc	a5,0x99
ffffffffc02024ac:	1a07b783          	ld	a5,416(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc02024b0:	4585                	li	a1,1
ffffffffc02024b2:	e432                	sd	a2,8(sp)
ffffffffc02024b4:	739c                	ld	a5,32(a5)
ffffffffc02024b6:	9782                	jalr	a5
ffffffffc02024b8:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc02024ba:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc02024be:	013487b3          	add	a5,s1,s3
ffffffffc02024c2:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc02024c6:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc02024c8:	f3a1                	bnez	a5,ffffffffc0202408 <exit_range+0x68>
}
ffffffffc02024ca:	60ea                	ld	ra,152(sp)
ffffffffc02024cc:	644a                	ld	s0,144(sp)
ffffffffc02024ce:	64aa                	ld	s1,136(sp)
ffffffffc02024d0:	690a                	ld	s2,128(sp)
ffffffffc02024d2:	79e6                	ld	s3,120(sp)
ffffffffc02024d4:	7a46                	ld	s4,112(sp)
ffffffffc02024d6:	7aa6                	ld	s5,104(sp)
ffffffffc02024d8:	7b06                	ld	s6,96(sp)
ffffffffc02024da:	6be6                	ld	s7,88(sp)
ffffffffc02024dc:	610d                	addi	sp,sp,160
ffffffffc02024de:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02024e0:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024e4:	078a                	slli	a5,a5,0x2
ffffffffc02024e6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024e8:	14a7f463          	bgeu	a5,a0,ffffffffc0202630 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02024ec:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc02024ee:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc02024f2:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02024f6:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc02024fa:	10abf263          	bgeu	s7,a0,ffffffffc02025fe <exit_range+0x25e>
ffffffffc02024fe:	000fb783          	ld	a5,0(t6)
ffffffffc0202502:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202504:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc0202508:	629c                	ld	a5,0(a3)
ffffffffc020250a:	8b85                	andi	a5,a5,1
ffffffffc020250c:	f7ad                	bnez	a5,ffffffffc0202476 <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020250e:	06a1                	addi	a3,a3,8
ffffffffc0202510:	fea69ce3          	bne	a3,a0,ffffffffc0202508 <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc0202514:	00099517          	auipc	a0,0x99
ffffffffc0202518:	15c53503          	ld	a0,348(a0) # ffffffffc029b670 <pages>
ffffffffc020251c:	952e                	add	a0,a0,a1
ffffffffc020251e:	100027f3          	csrr	a5,sstatus
ffffffffc0202522:	8b89                	andi	a5,a5,2
ffffffffc0202524:	e3b9                	bnez	a5,ffffffffc020256a <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc0202526:	00099797          	auipc	a5,0x99
ffffffffc020252a:	1227b783          	ld	a5,290(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc020252e:	4585                	li	a1,1
ffffffffc0202530:	e0b2                	sd	a2,64(sp)
ffffffffc0202532:	739c                	ld	a5,32(a5)
ffffffffc0202534:	fc1a                	sd	t1,56(sp)
ffffffffc0202536:	f846                	sd	a7,48(sp)
ffffffffc0202538:	f47a                	sd	t5,40(sp)
ffffffffc020253a:	f072                	sd	t3,32(sp)
ffffffffc020253c:	ec76                	sd	t4,24(sp)
ffffffffc020253e:	e842                	sd	a6,16(sp)
ffffffffc0202540:	e43a                	sd	a4,8(sp)
ffffffffc0202542:	9782                	jalr	a5
    if (flag)
ffffffffc0202544:	6722                	ld	a4,8(sp)
ffffffffc0202546:	6842                	ld	a6,16(sp)
ffffffffc0202548:	6ee2                	ld	t4,24(sp)
ffffffffc020254a:	7e02                	ld	t3,32(sp)
ffffffffc020254c:	7f22                	ld	t5,40(sp)
ffffffffc020254e:	78c2                	ld	a7,48(sp)
ffffffffc0202550:	7362                	ld	t1,56(sp)
ffffffffc0202552:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202554:	fff802b7          	lui	t0,0xfff80
ffffffffc0202558:	000803b7          	lui	t2,0x80
ffffffffc020255c:	00099f97          	auipc	t6,0x99
ffffffffc0202560:	104f8f93          	addi	t6,t6,260 # ffffffffc029b660 <va_pa_offset>
ffffffffc0202564:	00073023          	sd	zero,0(a4)
ffffffffc0202568:	b739                	j	ffffffffc0202476 <exit_range+0xd6>
        intr_disable();
ffffffffc020256a:	e4b2                	sd	a2,72(sp)
ffffffffc020256c:	e09a                	sd	t1,64(sp)
ffffffffc020256e:	fc46                	sd	a7,56(sp)
ffffffffc0202570:	f47a                	sd	t5,40(sp)
ffffffffc0202572:	f072                	sd	t3,32(sp)
ffffffffc0202574:	ec76                	sd	t4,24(sp)
ffffffffc0202576:	e842                	sd	a6,16(sp)
ffffffffc0202578:	e43a                	sd	a4,8(sp)
ffffffffc020257a:	f82a                	sd	a0,48(sp)
ffffffffc020257c:	b88fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202580:	00099797          	auipc	a5,0x99
ffffffffc0202584:	0c87b783          	ld	a5,200(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0202588:	7542                	ld	a0,48(sp)
ffffffffc020258a:	4585                	li	a1,1
ffffffffc020258c:	739c                	ld	a5,32(a5)
ffffffffc020258e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202590:	b6efe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202594:	6722                	ld	a4,8(sp)
ffffffffc0202596:	6626                	ld	a2,72(sp)
ffffffffc0202598:	6306                	ld	t1,64(sp)
ffffffffc020259a:	78e2                	ld	a7,56(sp)
ffffffffc020259c:	7f22                	ld	t5,40(sp)
ffffffffc020259e:	7e02                	ld	t3,32(sp)
ffffffffc02025a0:	6ee2                	ld	t4,24(sp)
ffffffffc02025a2:	6842                	ld	a6,16(sp)
ffffffffc02025a4:	00099f97          	auipc	t6,0x99
ffffffffc02025a8:	0bcf8f93          	addi	t6,t6,188 # ffffffffc029b660 <va_pa_offset>
ffffffffc02025ac:	000803b7          	lui	t2,0x80
ffffffffc02025b0:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc02025b4:	00073023          	sd	zero,0(a4)
ffffffffc02025b8:	bd7d                	j	ffffffffc0202476 <exit_range+0xd6>
        intr_disable();
ffffffffc02025ba:	e832                	sd	a2,16(sp)
ffffffffc02025bc:	e42a                	sd	a0,8(sp)
ffffffffc02025be:	b46fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02025c2:	00099797          	auipc	a5,0x99
ffffffffc02025c6:	0867b783          	ld	a5,134(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc02025ca:	6522                	ld	a0,8(sp)
ffffffffc02025cc:	4585                	li	a1,1
ffffffffc02025ce:	739c                	ld	a5,32(a5)
ffffffffc02025d0:	9782                	jalr	a5
        intr_enable();
ffffffffc02025d2:	b2cfe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02025d6:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc02025d8:	00043023          	sd	zero,0(s0)
ffffffffc02025dc:	b5cd                	j	ffffffffc02024be <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025de:	00004697          	auipc	a3,0x4
ffffffffc02025e2:	20268693          	addi	a3,a3,514 # ffffffffc02067e0 <etext+0xf30>
ffffffffc02025e6:	00004617          	auipc	a2,0x4
ffffffffc02025ea:	d4a60613          	addi	a2,a2,-694 # ffffffffc0206330 <etext+0xa80>
ffffffffc02025ee:	13500593          	li	a1,309
ffffffffc02025f2:	00004517          	auipc	a0,0x4
ffffffffc02025f6:	1de50513          	addi	a0,a0,478 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02025fa:	e4dfd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc02025fe:	00004617          	auipc	a2,0x4
ffffffffc0202602:	0e260613          	addi	a2,a2,226 # ffffffffc02066e0 <etext+0xe30>
ffffffffc0202606:	07100593          	li	a1,113
ffffffffc020260a:	00004517          	auipc	a0,0x4
ffffffffc020260e:	0fe50513          	addi	a0,a0,254 # ffffffffc0206708 <etext+0xe58>
ffffffffc0202612:	e35fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202616:	86f2                	mv	a3,t3
ffffffffc0202618:	00004617          	auipc	a2,0x4
ffffffffc020261c:	0c860613          	addi	a2,a2,200 # ffffffffc02066e0 <etext+0xe30>
ffffffffc0202620:	07100593          	li	a1,113
ffffffffc0202624:	00004517          	auipc	a0,0x4
ffffffffc0202628:	0e450513          	addi	a0,a0,228 # ffffffffc0206708 <etext+0xe58>
ffffffffc020262c:	e1bfd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202630:	8c7ff0ef          	jal	ffffffffc0201ef6 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202634:	00004697          	auipc	a3,0x4
ffffffffc0202638:	1dc68693          	addi	a3,a3,476 # ffffffffc0206810 <etext+0xf60>
ffffffffc020263c:	00004617          	auipc	a2,0x4
ffffffffc0202640:	cf460613          	addi	a2,a2,-780 # ffffffffc0206330 <etext+0xa80>
ffffffffc0202644:	13600593          	li	a1,310
ffffffffc0202648:	00004517          	auipc	a0,0x4
ffffffffc020264c:	18850513          	addi	a0,a0,392 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0202650:	df7fd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0202654 <page_remove>:
{
ffffffffc0202654:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202656:	4601                	li	a2,0
{
ffffffffc0202658:	e822                	sd	s0,16(sp)
ffffffffc020265a:	ec06                	sd	ra,24(sp)
ffffffffc020265c:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020265e:	95dff0ef          	jal	ffffffffc0201fba <get_pte>
    if (ptep != NULL)
ffffffffc0202662:	c511                	beqz	a0,ffffffffc020266e <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc0202664:	6118                	ld	a4,0(a0)
ffffffffc0202666:	87aa                	mv	a5,a0
ffffffffc0202668:	00177693          	andi	a3,a4,1
ffffffffc020266c:	e689                	bnez	a3,ffffffffc0202676 <page_remove+0x22>
}
ffffffffc020266e:	60e2                	ld	ra,24(sp)
ffffffffc0202670:	6442                	ld	s0,16(sp)
ffffffffc0202672:	6105                	addi	sp,sp,32
ffffffffc0202674:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202676:	00099697          	auipc	a3,0x99
ffffffffc020267a:	ff26b683          	ld	a3,-14(a3) # ffffffffc029b668 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc020267e:	070a                	slli	a4,a4,0x2
ffffffffc0202680:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202682:	06d77563          	bgeu	a4,a3,ffffffffc02026ec <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202686:	00099517          	auipc	a0,0x99
ffffffffc020268a:	fea53503          	ld	a0,-22(a0) # ffffffffc029b670 <pages>
ffffffffc020268e:	071a                	slli	a4,a4,0x6
ffffffffc0202690:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202694:	9736                	add	a4,a4,a3
ffffffffc0202696:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202698:	4118                	lw	a4,0(a0)
ffffffffc020269a:	377d                	addiw	a4,a4,-1
ffffffffc020269c:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc020269e:	cb09                	beqz	a4,ffffffffc02026b0 <page_remove+0x5c>
        *ptep = 0;
ffffffffc02026a0:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026a4:	12040073          	sfence.vma	s0
}
ffffffffc02026a8:	60e2                	ld	ra,24(sp)
ffffffffc02026aa:	6442                	ld	s0,16(sp)
ffffffffc02026ac:	6105                	addi	sp,sp,32
ffffffffc02026ae:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026b0:	10002773          	csrr	a4,sstatus
ffffffffc02026b4:	8b09                	andi	a4,a4,2
ffffffffc02026b6:	eb19                	bnez	a4,ffffffffc02026cc <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc02026b8:	00099717          	auipc	a4,0x99
ffffffffc02026bc:	f9073703          	ld	a4,-112(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc02026c0:	4585                	li	a1,1
ffffffffc02026c2:	e03e                	sd	a5,0(sp)
ffffffffc02026c4:	7318                	ld	a4,32(a4)
ffffffffc02026c6:	9702                	jalr	a4
    if (flag)
ffffffffc02026c8:	6782                	ld	a5,0(sp)
ffffffffc02026ca:	bfd9                	j	ffffffffc02026a0 <page_remove+0x4c>
        intr_disable();
ffffffffc02026cc:	e43e                	sd	a5,8(sp)
ffffffffc02026ce:	e02a                	sd	a0,0(sp)
ffffffffc02026d0:	a34fe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc02026d4:	00099717          	auipc	a4,0x99
ffffffffc02026d8:	f7473703          	ld	a4,-140(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc02026dc:	6502                	ld	a0,0(sp)
ffffffffc02026de:	4585                	li	a1,1
ffffffffc02026e0:	7318                	ld	a4,32(a4)
ffffffffc02026e2:	9702                	jalr	a4
        intr_enable();
ffffffffc02026e4:	a1afe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02026e8:	67a2                	ld	a5,8(sp)
ffffffffc02026ea:	bf5d                	j	ffffffffc02026a0 <page_remove+0x4c>
ffffffffc02026ec:	80bff0ef          	jal	ffffffffc0201ef6 <pa2page.part.0>

ffffffffc02026f0 <page_insert>:
{
ffffffffc02026f0:	7139                	addi	sp,sp,-64
ffffffffc02026f2:	f426                	sd	s1,40(sp)
ffffffffc02026f4:	84b2                	mv	s1,a2
ffffffffc02026f6:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026f8:	4605                	li	a2,1
{
ffffffffc02026fa:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026fc:	85a6                	mv	a1,s1
{
ffffffffc02026fe:	fc06                	sd	ra,56(sp)
ffffffffc0202700:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202702:	8b9ff0ef          	jal	ffffffffc0201fba <get_pte>
    if (ptep == NULL)
ffffffffc0202706:	cd61                	beqz	a0,ffffffffc02027de <page_insert+0xee>
    page->ref += 1;
ffffffffc0202708:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc020270a:	611c                	ld	a5,0(a0)
ffffffffc020270c:	66a2                	ld	a3,8(sp)
ffffffffc020270e:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7baf>
ffffffffc0202712:	c010                	sw	a2,0(s0)
ffffffffc0202714:	0017f613          	andi	a2,a5,1
ffffffffc0202718:	872a                	mv	a4,a0
ffffffffc020271a:	e61d                	bnez	a2,ffffffffc0202748 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc020271c:	00099617          	auipc	a2,0x99
ffffffffc0202720:	f5463603          	ld	a2,-172(a2) # ffffffffc029b670 <pages>
    return page - pages + nbase;
ffffffffc0202724:	8c11                	sub	s0,s0,a2
ffffffffc0202726:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202728:	200007b7          	lui	a5,0x20000
ffffffffc020272c:	042a                	slli	s0,s0,0xa
ffffffffc020272e:	943e                	add	s0,s0,a5
ffffffffc0202730:	8ec1                	or	a3,a3,s0
ffffffffc0202732:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202736:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202738:	12048073          	sfence.vma	s1
    return 0;
ffffffffc020273c:	4501                	li	a0,0
}
ffffffffc020273e:	70e2                	ld	ra,56(sp)
ffffffffc0202740:	7442                	ld	s0,48(sp)
ffffffffc0202742:	74a2                	ld	s1,40(sp)
ffffffffc0202744:	6121                	addi	sp,sp,64
ffffffffc0202746:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202748:	00099617          	auipc	a2,0x99
ffffffffc020274c:	f2063603          	ld	a2,-224(a2) # ffffffffc029b668 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202750:	078a                	slli	a5,a5,0x2
ffffffffc0202752:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202754:	08c7f763          	bgeu	a5,a2,ffffffffc02027e2 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202758:	00099617          	auipc	a2,0x99
ffffffffc020275c:	f1863603          	ld	a2,-232(a2) # ffffffffc029b670 <pages>
ffffffffc0202760:	fe000537          	lui	a0,0xfe000
ffffffffc0202764:	079a                	slli	a5,a5,0x6
ffffffffc0202766:	97aa                	add	a5,a5,a0
ffffffffc0202768:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc020276c:	00a40963          	beq	s0,a0,ffffffffc020277e <page_insert+0x8e>
    page->ref -= 1;
ffffffffc0202770:	411c                	lw	a5,0(a0)
ffffffffc0202772:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_exit_out_size+0x1fff5e47>
ffffffffc0202774:	c11c                	sw	a5,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202776:	c791                	beqz	a5,ffffffffc0202782 <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202778:	12048073          	sfence.vma	s1
}
ffffffffc020277c:	b765                	j	ffffffffc0202724 <page_insert+0x34>
ffffffffc020277e:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc0202780:	b755                	j	ffffffffc0202724 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202782:	100027f3          	csrr	a5,sstatus
ffffffffc0202786:	8b89                	andi	a5,a5,2
ffffffffc0202788:	e39d                	bnez	a5,ffffffffc02027ae <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc020278a:	00099797          	auipc	a5,0x99
ffffffffc020278e:	ebe7b783          	ld	a5,-322(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0202792:	4585                	li	a1,1
ffffffffc0202794:	e83a                	sd	a4,16(sp)
ffffffffc0202796:	739c                	ld	a5,32(a5)
ffffffffc0202798:	e436                	sd	a3,8(sp)
ffffffffc020279a:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc020279c:	00099617          	auipc	a2,0x99
ffffffffc02027a0:	ed463603          	ld	a2,-300(a2) # ffffffffc029b670 <pages>
ffffffffc02027a4:	66a2                	ld	a3,8(sp)
ffffffffc02027a6:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027a8:	12048073          	sfence.vma	s1
ffffffffc02027ac:	bfa5                	j	ffffffffc0202724 <page_insert+0x34>
        intr_disable();
ffffffffc02027ae:	ec3a                	sd	a4,24(sp)
ffffffffc02027b0:	e836                	sd	a3,16(sp)
ffffffffc02027b2:	e42a                	sd	a0,8(sp)
ffffffffc02027b4:	950fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027b8:	00099797          	auipc	a5,0x99
ffffffffc02027bc:	e907b783          	ld	a5,-368(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc02027c0:	6522                	ld	a0,8(sp)
ffffffffc02027c2:	4585                	li	a1,1
ffffffffc02027c4:	739c                	ld	a5,32(a5)
ffffffffc02027c6:	9782                	jalr	a5
        intr_enable();
ffffffffc02027c8:	936fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02027cc:	00099617          	auipc	a2,0x99
ffffffffc02027d0:	ea463603          	ld	a2,-348(a2) # ffffffffc029b670 <pages>
ffffffffc02027d4:	6762                	ld	a4,24(sp)
ffffffffc02027d6:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027d8:	12048073          	sfence.vma	s1
ffffffffc02027dc:	b7a1                	j	ffffffffc0202724 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc02027de:	5571                	li	a0,-4
ffffffffc02027e0:	bfb9                	j	ffffffffc020273e <page_insert+0x4e>
ffffffffc02027e2:	f14ff0ef          	jal	ffffffffc0201ef6 <pa2page.part.0>

ffffffffc02027e6 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02027e6:	00005797          	auipc	a5,0x5
ffffffffc02027ea:	f8278793          	addi	a5,a5,-126 # ffffffffc0207768 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027ee:	638c                	ld	a1,0(a5)
{
ffffffffc02027f0:	7159                	addi	sp,sp,-112
ffffffffc02027f2:	f486                	sd	ra,104(sp)
ffffffffc02027f4:	e8ca                	sd	s2,80(sp)
ffffffffc02027f6:	e4ce                	sd	s3,72(sp)
ffffffffc02027f8:	f85a                	sd	s6,48(sp)
ffffffffc02027fa:	f0a2                	sd	s0,96(sp)
ffffffffc02027fc:	eca6                	sd	s1,88(sp)
ffffffffc02027fe:	e0d2                	sd	s4,64(sp)
ffffffffc0202800:	fc56                	sd	s5,56(sp)
ffffffffc0202802:	f45e                	sd	s7,40(sp)
ffffffffc0202804:	f062                	sd	s8,32(sp)
ffffffffc0202806:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202808:	00099b17          	auipc	s6,0x99
ffffffffc020280c:	e40b0b13          	addi	s6,s6,-448 # ffffffffc029b648 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202810:	00004517          	auipc	a0,0x4
ffffffffc0202814:	01850513          	addi	a0,a0,24 # ffffffffc0206828 <etext+0xf78>
    pmm_manager = &default_pmm_manager;
ffffffffc0202818:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020281c:	979fd0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202820:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202824:	00099997          	auipc	s3,0x99
ffffffffc0202828:	e3c98993          	addi	s3,s3,-452 # ffffffffc029b660 <va_pa_offset>
    pmm_manager->init();
ffffffffc020282c:	679c                	ld	a5,8(a5)
ffffffffc020282e:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202830:	57f5                	li	a5,-3
ffffffffc0202832:	07fa                	slli	a5,a5,0x1e
ffffffffc0202834:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202838:	8b2fe0ef          	jal	ffffffffc02008ea <get_memory_base>
ffffffffc020283c:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020283e:	8b6fe0ef          	jal	ffffffffc02008f4 <get_memory_size>
    if (mem_size == 0)
ffffffffc0202842:	70050e63          	beqz	a0,ffffffffc0202f5e <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202846:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202848:	00004517          	auipc	a0,0x4
ffffffffc020284c:	01850513          	addi	a0,a0,24 # ffffffffc0206860 <etext+0xfb0>
ffffffffc0202850:	945fd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202854:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202858:	864a                	mv	a2,s2
ffffffffc020285a:	85a6                	mv	a1,s1
ffffffffc020285c:	fff40693          	addi	a3,s0,-1
ffffffffc0202860:	00004517          	auipc	a0,0x4
ffffffffc0202864:	01850513          	addi	a0,a0,24 # ffffffffc0206878 <etext+0xfc8>
ffffffffc0202868:	92dfd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc020286c:	c80007b7          	lui	a5,0xc8000
ffffffffc0202870:	8522                	mv	a0,s0
ffffffffc0202872:	5287ed63          	bltu	a5,s0,ffffffffc0202dac <pmm_init+0x5c6>
ffffffffc0202876:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202878:	0009a617          	auipc	a2,0x9a
ffffffffc020287c:	e1f60613          	addi	a2,a2,-481 # ffffffffc029c697 <end+0xfff>
ffffffffc0202880:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc0202882:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202884:	00099b97          	auipc	s7,0x99
ffffffffc0202888:	decb8b93          	addi	s7,s7,-532 # ffffffffc029b670 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020288c:	00099497          	auipc	s1,0x99
ffffffffc0202890:	ddc48493          	addi	s1,s1,-548 # ffffffffc029b668 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202894:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202898:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020289a:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020289e:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028a0:	02f50763          	beq	a0,a5,ffffffffc02028ce <pmm_init+0xe8>
ffffffffc02028a4:	4701                	li	a4,0
ffffffffc02028a6:	4585                	li	a1,1
ffffffffc02028a8:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02028ac:	00671793          	slli	a5,a4,0x6
ffffffffc02028b0:	97b2                	add	a5,a5,a2
ffffffffc02028b2:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_exit_out_size+0x75e50>
ffffffffc02028b4:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028b8:	6088                	ld	a0,0(s1)
ffffffffc02028ba:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028bc:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02028c0:	00d507b3          	add	a5,a0,a3
ffffffffc02028c4:	fef764e3          	bltu	a4,a5,ffffffffc02028ac <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028c8:	079a                	slli	a5,a5,0x6
ffffffffc02028ca:	00f606b3          	add	a3,a2,a5
ffffffffc02028ce:	c02007b7          	lui	a5,0xc0200
ffffffffc02028d2:	16f6eee3          	bltu	a3,a5,ffffffffc020324e <pmm_init+0xa68>
ffffffffc02028d6:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02028da:	77fd                	lui	a5,0xfffff
ffffffffc02028dc:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02028de:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02028e0:	4e86ed63          	bltu	a3,s0,ffffffffc0202dda <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02028e4:	00004517          	auipc	a0,0x4
ffffffffc02028e8:	fbc50513          	addi	a0,a0,-68 # ffffffffc02068a0 <etext+0xff0>
ffffffffc02028ec:	8a9fd0ef          	jal	ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02028f0:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02028f4:	00099917          	auipc	s2,0x99
ffffffffc02028f8:	d6490913          	addi	s2,s2,-668 # ffffffffc029b658 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02028fc:	7b9c                	ld	a5,48(a5)
ffffffffc02028fe:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202900:	00004517          	auipc	a0,0x4
ffffffffc0202904:	fb850513          	addi	a0,a0,-72 # ffffffffc02068b8 <etext+0x1008>
ffffffffc0202908:	88dfd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020290c:	00007697          	auipc	a3,0x7
ffffffffc0202910:	6f468693          	addi	a3,a3,1780 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc0202914:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202918:	c02007b7          	lui	a5,0xc0200
ffffffffc020291c:	2af6eee3          	bltu	a3,a5,ffffffffc02033d8 <pmm_init+0xbf2>
ffffffffc0202920:	0009b783          	ld	a5,0(s3)
ffffffffc0202924:	8e9d                	sub	a3,a3,a5
ffffffffc0202926:	00099797          	auipc	a5,0x99
ffffffffc020292a:	d2d7b523          	sd	a3,-726(a5) # ffffffffc029b650 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020292e:	100027f3          	csrr	a5,sstatus
ffffffffc0202932:	8b89                	andi	a5,a5,2
ffffffffc0202934:	48079963          	bnez	a5,ffffffffc0202dc6 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202938:	000b3783          	ld	a5,0(s6)
ffffffffc020293c:	779c                	ld	a5,40(a5)
ffffffffc020293e:	9782                	jalr	a5
ffffffffc0202940:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202942:	6098                	ld	a4,0(s1)
ffffffffc0202944:	c80007b7          	lui	a5,0xc8000
ffffffffc0202948:	83b1                	srli	a5,a5,0xc
ffffffffc020294a:	66e7e663          	bltu	a5,a4,ffffffffc0202fb6 <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020294e:	00093503          	ld	a0,0(s2)
ffffffffc0202952:	64050263          	beqz	a0,ffffffffc0202f96 <pmm_init+0x7b0>
ffffffffc0202956:	03451793          	slli	a5,a0,0x34
ffffffffc020295a:	62079e63          	bnez	a5,ffffffffc0202f96 <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020295e:	4601                	li	a2,0
ffffffffc0202960:	4581                	li	a1,0
ffffffffc0202962:	8b7ff0ef          	jal	ffffffffc0202218 <get_page>
ffffffffc0202966:	240519e3          	bnez	a0,ffffffffc02033b8 <pmm_init+0xbd2>
ffffffffc020296a:	100027f3          	csrr	a5,sstatus
ffffffffc020296e:	8b89                	andi	a5,a5,2
ffffffffc0202970:	44079063          	bnez	a5,ffffffffc0202db0 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202974:	000b3783          	ld	a5,0(s6)
ffffffffc0202978:	4505                	li	a0,1
ffffffffc020297a:	6f9c                	ld	a5,24(a5)
ffffffffc020297c:	9782                	jalr	a5
ffffffffc020297e:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202980:	00093503          	ld	a0,0(s2)
ffffffffc0202984:	4681                	li	a3,0
ffffffffc0202986:	4601                	li	a2,0
ffffffffc0202988:	85d2                	mv	a1,s4
ffffffffc020298a:	d67ff0ef          	jal	ffffffffc02026f0 <page_insert>
ffffffffc020298e:	280511e3          	bnez	a0,ffffffffc0203410 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202992:	00093503          	ld	a0,0(s2)
ffffffffc0202996:	4601                	li	a2,0
ffffffffc0202998:	4581                	li	a1,0
ffffffffc020299a:	e20ff0ef          	jal	ffffffffc0201fba <get_pte>
ffffffffc020299e:	240509e3          	beqz	a0,ffffffffc02033f0 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc02029a2:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02029a4:	0017f713          	andi	a4,a5,1
ffffffffc02029a8:	58070f63          	beqz	a4,ffffffffc0202f46 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc02029ac:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02029ae:	078a                	slli	a5,a5,0x2
ffffffffc02029b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02029b2:	58e7f863          	bgeu	a5,a4,ffffffffc0202f42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02029b6:	000bb683          	ld	a3,0(s7)
ffffffffc02029ba:	079a                	slli	a5,a5,0x6
ffffffffc02029bc:	fe000637          	lui	a2,0xfe000
ffffffffc02029c0:	97b2                	add	a5,a5,a2
ffffffffc02029c2:	97b6                	add	a5,a5,a3
ffffffffc02029c4:	14fa1ae3          	bne	s4,a5,ffffffffc0203318 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc02029c8:	000a2683          	lw	a3,0(s4) # 200000 <_binary_obj___user_exit_out_size+0x1f5e48>
ffffffffc02029cc:	4785                	li	a5,1
ffffffffc02029ce:	12f695e3          	bne	a3,a5,ffffffffc02032f8 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02029d2:	00093503          	ld	a0,0(s2)
ffffffffc02029d6:	77fd                	lui	a5,0xfffff
ffffffffc02029d8:	6114                	ld	a3,0(a0)
ffffffffc02029da:	068a                	slli	a3,a3,0x2
ffffffffc02029dc:	8efd                	and	a3,a3,a5
ffffffffc02029de:	00c6d613          	srli	a2,a3,0xc
ffffffffc02029e2:	0ee67fe3          	bgeu	a2,a4,ffffffffc02032e0 <pmm_init+0xafa>
ffffffffc02029e6:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029ea:	96e2                	add	a3,a3,s8
ffffffffc02029ec:	0006ba83          	ld	s5,0(a3)
ffffffffc02029f0:	0a8a                	slli	s5,s5,0x2
ffffffffc02029f2:	00fafab3          	and	s5,s5,a5
ffffffffc02029f6:	00cad793          	srli	a5,s5,0xc
ffffffffc02029fa:	0ce7f6e3          	bgeu	a5,a4,ffffffffc02032c6 <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029fe:	4601                	li	a2,0
ffffffffc0202a00:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a02:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a04:	db6ff0ef          	jal	ffffffffc0201fba <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202a08:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202a0a:	05851ee3          	bne	a0,s8,ffffffffc0203266 <pmm_init+0xa80>
ffffffffc0202a0e:	100027f3          	csrr	a5,sstatus
ffffffffc0202a12:	8b89                	andi	a5,a5,2
ffffffffc0202a14:	3e079b63          	bnez	a5,ffffffffc0202e0a <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202a18:	000b3783          	ld	a5,0(s6)
ffffffffc0202a1c:	4505                	li	a0,1
ffffffffc0202a1e:	6f9c                	ld	a5,24(a5)
ffffffffc0202a20:	9782                	jalr	a5
ffffffffc0202a22:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202a24:	00093503          	ld	a0,0(s2)
ffffffffc0202a28:	46d1                	li	a3,20
ffffffffc0202a2a:	6605                	lui	a2,0x1
ffffffffc0202a2c:	85e2                	mv	a1,s8
ffffffffc0202a2e:	cc3ff0ef          	jal	ffffffffc02026f0 <page_insert>
ffffffffc0202a32:	06051ae3          	bnez	a0,ffffffffc02032a6 <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a36:	00093503          	ld	a0,0(s2)
ffffffffc0202a3a:	4601                	li	a2,0
ffffffffc0202a3c:	6585                	lui	a1,0x1
ffffffffc0202a3e:	d7cff0ef          	jal	ffffffffc0201fba <get_pte>
ffffffffc0202a42:	040502e3          	beqz	a0,ffffffffc0203286 <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc0202a46:	611c                	ld	a5,0(a0)
ffffffffc0202a48:	0107f713          	andi	a4,a5,16
ffffffffc0202a4c:	7e070163          	beqz	a4,ffffffffc020322e <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc0202a50:	8b91                	andi	a5,a5,4
ffffffffc0202a52:	7a078e63          	beqz	a5,ffffffffc020320e <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202a56:	00093503          	ld	a0,0(s2)
ffffffffc0202a5a:	611c                	ld	a5,0(a0)
ffffffffc0202a5c:	8bc1                	andi	a5,a5,16
ffffffffc0202a5e:	78078863          	beqz	a5,ffffffffc02031ee <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc0202a62:	000c2703          	lw	a4,0(s8)
ffffffffc0202a66:	4785                	li	a5,1
ffffffffc0202a68:	76f71363          	bne	a4,a5,ffffffffc02031ce <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a6c:	4681                	li	a3,0
ffffffffc0202a6e:	6605                	lui	a2,0x1
ffffffffc0202a70:	85d2                	mv	a1,s4
ffffffffc0202a72:	c7fff0ef          	jal	ffffffffc02026f0 <page_insert>
ffffffffc0202a76:	72051c63          	bnez	a0,ffffffffc02031ae <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc0202a7a:	000a2703          	lw	a4,0(s4)
ffffffffc0202a7e:	4789                	li	a5,2
ffffffffc0202a80:	70f71763          	bne	a4,a5,ffffffffc020318e <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202a84:	000c2783          	lw	a5,0(s8)
ffffffffc0202a88:	6e079363          	bnez	a5,ffffffffc020316e <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a8c:	00093503          	ld	a0,0(s2)
ffffffffc0202a90:	4601                	li	a2,0
ffffffffc0202a92:	6585                	lui	a1,0x1
ffffffffc0202a94:	d26ff0ef          	jal	ffffffffc0201fba <get_pte>
ffffffffc0202a98:	6a050b63          	beqz	a0,ffffffffc020314e <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a9c:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a9e:	00177793          	andi	a5,a4,1
ffffffffc0202aa2:	4a078263          	beqz	a5,ffffffffc0202f46 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202aa6:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202aa8:	00271793          	slli	a5,a4,0x2
ffffffffc0202aac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aae:	48d7fa63          	bgeu	a5,a3,ffffffffc0202f42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ab2:	000bb683          	ld	a3,0(s7)
ffffffffc0202ab6:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202aba:	97d6                	add	a5,a5,s5
ffffffffc0202abc:	079a                	slli	a5,a5,0x6
ffffffffc0202abe:	97b6                	add	a5,a5,a3
ffffffffc0202ac0:	66fa1763          	bne	s4,a5,ffffffffc020312e <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202ac4:	8b41                	andi	a4,a4,16
ffffffffc0202ac6:	64071463          	bnez	a4,ffffffffc020310e <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202aca:	00093503          	ld	a0,0(s2)
ffffffffc0202ace:	4581                	li	a1,0
ffffffffc0202ad0:	b85ff0ef          	jal	ffffffffc0202654 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202ad4:	000a2c83          	lw	s9,0(s4)
ffffffffc0202ad8:	4785                	li	a5,1
ffffffffc0202ada:	60fc9a63          	bne	s9,a5,ffffffffc02030ee <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202ade:	000c2783          	lw	a5,0(s8)
ffffffffc0202ae2:	5e079663          	bnez	a5,ffffffffc02030ce <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202ae6:	00093503          	ld	a0,0(s2)
ffffffffc0202aea:	6585                	lui	a1,0x1
ffffffffc0202aec:	b69ff0ef          	jal	ffffffffc0202654 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202af0:	000a2783          	lw	a5,0(s4)
ffffffffc0202af4:	52079d63          	bnez	a5,ffffffffc020302e <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202af8:	000c2783          	lw	a5,0(s8)
ffffffffc0202afc:	50079963          	bnez	a5,ffffffffc020300e <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202b00:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202b04:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b06:	000a3783          	ld	a5,0(s4)
ffffffffc0202b0a:	078a                	slli	a5,a5,0x2
ffffffffc0202b0c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b0e:	42e7fa63          	bgeu	a5,a4,ffffffffc0202f42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b12:	000bb503          	ld	a0,0(s7)
ffffffffc0202b16:	97d6                	add	a5,a5,s5
ffffffffc0202b18:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202b1a:	00f506b3          	add	a3,a0,a5
ffffffffc0202b1e:	4294                	lw	a3,0(a3)
ffffffffc0202b20:	4d969763          	bne	a3,s9,ffffffffc0202fee <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202b24:	8799                	srai	a5,a5,0x6
ffffffffc0202b26:	00080637          	lui	a2,0x80
ffffffffc0202b2a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b2c:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202b30:	4ae7f363          	bgeu	a5,a4,ffffffffc0202fd6 <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202b34:	0009b783          	ld	a5,0(s3)
ffffffffc0202b38:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b3a:	639c                	ld	a5,0(a5)
ffffffffc0202b3c:	078a                	slli	a5,a5,0x2
ffffffffc0202b3e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b40:	40e7f163          	bgeu	a5,a4,ffffffffc0202f42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b44:	8f91                	sub	a5,a5,a2
ffffffffc0202b46:	079a                	slli	a5,a5,0x6
ffffffffc0202b48:	953e                	add	a0,a0,a5
ffffffffc0202b4a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b4e:	8b89                	andi	a5,a5,2
ffffffffc0202b50:	30079863          	bnez	a5,ffffffffc0202e60 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202b54:	000b3783          	ld	a5,0(s6)
ffffffffc0202b58:	4585                	li	a1,1
ffffffffc0202b5a:	739c                	ld	a5,32(a5)
ffffffffc0202b5c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b5e:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202b62:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b64:	078a                	slli	a5,a5,0x2
ffffffffc0202b66:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b68:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202f42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b6c:	000bb503          	ld	a0,0(s7)
ffffffffc0202b70:	fe000737          	lui	a4,0xfe000
ffffffffc0202b74:	079a                	slli	a5,a5,0x6
ffffffffc0202b76:	97ba                	add	a5,a5,a4
ffffffffc0202b78:	953e                	add	a0,a0,a5
ffffffffc0202b7a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b7e:	8b89                	andi	a5,a5,2
ffffffffc0202b80:	2c079463          	bnez	a5,ffffffffc0202e48 <pmm_init+0x662>
ffffffffc0202b84:	000b3783          	ld	a5,0(s6)
ffffffffc0202b88:	4585                	li	a1,1
ffffffffc0202b8a:	739c                	ld	a5,32(a5)
ffffffffc0202b8c:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b8e:	00093783          	ld	a5,0(s2)
ffffffffc0202b92:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd63968>
    asm volatile("sfence.vma");
ffffffffc0202b96:	12000073          	sfence.vma
ffffffffc0202b9a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b9e:	8b89                	andi	a5,a5,2
ffffffffc0202ba0:	28079a63          	bnez	a5,ffffffffc0202e34 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202ba4:	000b3783          	ld	a5,0(s6)
ffffffffc0202ba8:	779c                	ld	a5,40(a5)
ffffffffc0202baa:	9782                	jalr	a5
ffffffffc0202bac:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202bae:	4d441063          	bne	s0,s4,ffffffffc020306e <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202bb2:	00004517          	auipc	a0,0x4
ffffffffc0202bb6:	05650513          	addi	a0,a0,86 # ffffffffc0206c08 <etext+0x1358>
ffffffffc0202bba:	ddafd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0202bbe:	100027f3          	csrr	a5,sstatus
ffffffffc0202bc2:	8b89                	andi	a5,a5,2
ffffffffc0202bc4:	24079e63          	bnez	a5,ffffffffc0202e20 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bc8:	000b3783          	ld	a5,0(s6)
ffffffffc0202bcc:	779c                	ld	a5,40(a5)
ffffffffc0202bce:	9782                	jalr	a5
ffffffffc0202bd0:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bd2:	609c                	ld	a5,0(s1)
ffffffffc0202bd4:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bd8:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bda:	00c79713          	slli	a4,a5,0xc
ffffffffc0202bde:	6a85                	lui	s5,0x1
ffffffffc0202be0:	02e47c63          	bgeu	s0,a4,ffffffffc0202c18 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202be4:	00c45713          	srli	a4,s0,0xc
ffffffffc0202be8:	30f77063          	bgeu	a4,a5,ffffffffc0202ee8 <pmm_init+0x702>
ffffffffc0202bec:	0009b583          	ld	a1,0(s3)
ffffffffc0202bf0:	00093503          	ld	a0,0(s2)
ffffffffc0202bf4:	4601                	li	a2,0
ffffffffc0202bf6:	95a2                	add	a1,a1,s0
ffffffffc0202bf8:	bc2ff0ef          	jal	ffffffffc0201fba <get_pte>
ffffffffc0202bfc:	32050363          	beqz	a0,ffffffffc0202f22 <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202c00:	611c                	ld	a5,0(a0)
ffffffffc0202c02:	078a                	slli	a5,a5,0x2
ffffffffc0202c04:	0147f7b3          	and	a5,a5,s4
ffffffffc0202c08:	2e879d63          	bne	a5,s0,ffffffffc0202f02 <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202c0c:	609c                	ld	a5,0(s1)
ffffffffc0202c0e:	9456                	add	s0,s0,s5
ffffffffc0202c10:	00c79713          	slli	a4,a5,0xc
ffffffffc0202c14:	fce468e3          	bltu	s0,a4,ffffffffc0202be4 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202c18:	00093783          	ld	a5,0(s2)
ffffffffc0202c1c:	639c                	ld	a5,0(a5)
ffffffffc0202c1e:	42079863          	bnez	a5,ffffffffc020304e <pmm_init+0x868>
ffffffffc0202c22:	100027f3          	csrr	a5,sstatus
ffffffffc0202c26:	8b89                	andi	a5,a5,2
ffffffffc0202c28:	24079863          	bnez	a5,ffffffffc0202e78 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c2c:	000b3783          	ld	a5,0(s6)
ffffffffc0202c30:	4505                	li	a0,1
ffffffffc0202c32:	6f9c                	ld	a5,24(a5)
ffffffffc0202c34:	9782                	jalr	a5
ffffffffc0202c36:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c38:	00093503          	ld	a0,0(s2)
ffffffffc0202c3c:	4699                	li	a3,6
ffffffffc0202c3e:	10000613          	li	a2,256
ffffffffc0202c42:	85a2                	mv	a1,s0
ffffffffc0202c44:	aadff0ef          	jal	ffffffffc02026f0 <page_insert>
ffffffffc0202c48:	46051363          	bnez	a0,ffffffffc02030ae <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202c4c:	4018                	lw	a4,0(s0)
ffffffffc0202c4e:	4785                	li	a5,1
ffffffffc0202c50:	42f71f63          	bne	a4,a5,ffffffffc020308e <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202c54:	00093503          	ld	a0,0(s2)
ffffffffc0202c58:	6605                	lui	a2,0x1
ffffffffc0202c5a:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7ab0>
ffffffffc0202c5e:	4699                	li	a3,6
ffffffffc0202c60:	85a2                	mv	a1,s0
ffffffffc0202c62:	a8fff0ef          	jal	ffffffffc02026f0 <page_insert>
ffffffffc0202c66:	72051963          	bnez	a0,ffffffffc0203398 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202c6a:	4018                	lw	a4,0(s0)
ffffffffc0202c6c:	4789                	li	a5,2
ffffffffc0202c6e:	70f71563          	bne	a4,a5,ffffffffc0203378 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c72:	00004597          	auipc	a1,0x4
ffffffffc0202c76:	0de58593          	addi	a1,a1,222 # ffffffffc0206d50 <etext+0x14a0>
ffffffffc0202c7a:	10000513          	li	a0,256
ffffffffc0202c7e:	389020ef          	jal	ffffffffc0205806 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c82:	6585                	lui	a1,0x1
ffffffffc0202c84:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7ab0>
ffffffffc0202c88:	10000513          	li	a0,256
ffffffffc0202c8c:	38d020ef          	jal	ffffffffc0205818 <strcmp>
ffffffffc0202c90:	6c051463          	bnez	a0,ffffffffc0203358 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202c94:	000bb683          	ld	a3,0(s7)
ffffffffc0202c98:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202c9c:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202c9e:	40d406b3          	sub	a3,s0,a3
ffffffffc0202ca2:	8699                	srai	a3,a3,0x6
ffffffffc0202ca4:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202ca6:	00c69793          	slli	a5,a3,0xc
ffffffffc0202caa:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202cac:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202cae:	32e7f463          	bgeu	a5,a4,ffffffffc0202fd6 <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202cb2:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cb6:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202cba:	97b6                	add	a5,a5,a3
ffffffffc0202cbc:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_exit_out_size+0x75f48>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202cc0:	313020ef          	jal	ffffffffc02057d2 <strlen>
ffffffffc0202cc4:	66051a63          	bnez	a0,ffffffffc0203338 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202cc8:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202ccc:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cce:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd63968>
ffffffffc0202cd2:	078a                	slli	a5,a5,0x2
ffffffffc0202cd4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cd6:	26e7f663          	bgeu	a5,a4,ffffffffc0202f42 <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202cda:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202cde:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202fd6 <pmm_init+0x7f0>
ffffffffc0202ce2:	0009b783          	ld	a5,0(s3)
ffffffffc0202ce6:	00f689b3          	add	s3,a3,a5
ffffffffc0202cea:	100027f3          	csrr	a5,sstatus
ffffffffc0202cee:	8b89                	andi	a5,a5,2
ffffffffc0202cf0:	1e079163          	bnez	a5,ffffffffc0202ed2 <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202cf4:	000b3783          	ld	a5,0(s6)
ffffffffc0202cf8:	8522                	mv	a0,s0
ffffffffc0202cfa:	4585                	li	a1,1
ffffffffc0202cfc:	739c                	ld	a5,32(a5)
ffffffffc0202cfe:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d00:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202d04:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d06:	078a                	slli	a5,a5,0x2
ffffffffc0202d08:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d0a:	22e7fc63          	bgeu	a5,a4,ffffffffc0202f42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d0e:	000bb503          	ld	a0,0(s7)
ffffffffc0202d12:	fe000737          	lui	a4,0xfe000
ffffffffc0202d16:	079a                	slli	a5,a5,0x6
ffffffffc0202d18:	97ba                	add	a5,a5,a4
ffffffffc0202d1a:	953e                	add	a0,a0,a5
ffffffffc0202d1c:	100027f3          	csrr	a5,sstatus
ffffffffc0202d20:	8b89                	andi	a5,a5,2
ffffffffc0202d22:	18079c63          	bnez	a5,ffffffffc0202eba <pmm_init+0x6d4>
ffffffffc0202d26:	000b3783          	ld	a5,0(s6)
ffffffffc0202d2a:	4585                	li	a1,1
ffffffffc0202d2c:	739c                	ld	a5,32(a5)
ffffffffc0202d2e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d30:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202d34:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d36:	078a                	slli	a5,a5,0x2
ffffffffc0202d38:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d3a:	20e7f463          	bgeu	a5,a4,ffffffffc0202f42 <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d3e:	000bb503          	ld	a0,0(s7)
ffffffffc0202d42:	fe000737          	lui	a4,0xfe000
ffffffffc0202d46:	079a                	slli	a5,a5,0x6
ffffffffc0202d48:	97ba                	add	a5,a5,a4
ffffffffc0202d4a:	953e                	add	a0,a0,a5
ffffffffc0202d4c:	100027f3          	csrr	a5,sstatus
ffffffffc0202d50:	8b89                	andi	a5,a5,2
ffffffffc0202d52:	14079863          	bnez	a5,ffffffffc0202ea2 <pmm_init+0x6bc>
ffffffffc0202d56:	000b3783          	ld	a5,0(s6)
ffffffffc0202d5a:	4585                	li	a1,1
ffffffffc0202d5c:	739c                	ld	a5,32(a5)
ffffffffc0202d5e:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202d60:	00093783          	ld	a5,0(s2)
ffffffffc0202d64:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d68:	12000073          	sfence.vma
ffffffffc0202d6c:	100027f3          	csrr	a5,sstatus
ffffffffc0202d70:	8b89                	andi	a5,a5,2
ffffffffc0202d72:	10079e63          	bnez	a5,ffffffffc0202e8e <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d76:	000b3783          	ld	a5,0(s6)
ffffffffc0202d7a:	779c                	ld	a5,40(a5)
ffffffffc0202d7c:	9782                	jalr	a5
ffffffffc0202d7e:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d80:	1e8c1b63          	bne	s8,s0,ffffffffc0202f76 <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d84:	00004517          	auipc	a0,0x4
ffffffffc0202d88:	04450513          	addi	a0,a0,68 # ffffffffc0206dc8 <etext+0x1518>
ffffffffc0202d8c:	c08fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202d90:	7406                	ld	s0,96(sp)
ffffffffc0202d92:	70a6                	ld	ra,104(sp)
ffffffffc0202d94:	64e6                	ld	s1,88(sp)
ffffffffc0202d96:	6946                	ld	s2,80(sp)
ffffffffc0202d98:	69a6                	ld	s3,72(sp)
ffffffffc0202d9a:	6a06                	ld	s4,64(sp)
ffffffffc0202d9c:	7ae2                	ld	s5,56(sp)
ffffffffc0202d9e:	7b42                	ld	s6,48(sp)
ffffffffc0202da0:	7ba2                	ld	s7,40(sp)
ffffffffc0202da2:	7c02                	ld	s8,32(sp)
ffffffffc0202da4:	6ce2                	ld	s9,24(sp)
ffffffffc0202da6:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202da8:	f85fe06f          	j	ffffffffc0201d2c <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202dac:	853e                	mv	a0,a5
ffffffffc0202dae:	b4e1                	j	ffffffffc0202876 <pmm_init+0x90>
        intr_disable();
ffffffffc0202db0:	b55fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202db4:	000b3783          	ld	a5,0(s6)
ffffffffc0202db8:	4505                	li	a0,1
ffffffffc0202dba:	6f9c                	ld	a5,24(a5)
ffffffffc0202dbc:	9782                	jalr	a5
ffffffffc0202dbe:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dc0:	b3ffd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dc4:	be75                	j	ffffffffc0202980 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202dc6:	b3ffd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dca:	000b3783          	ld	a5,0(s6)
ffffffffc0202dce:	779c                	ld	a5,40(a5)
ffffffffc0202dd0:	9782                	jalr	a5
ffffffffc0202dd2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202dd4:	b2bfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dd8:	b6ad                	j	ffffffffc0202942 <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202dda:	6705                	lui	a4,0x1
ffffffffc0202ddc:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7bb1>
ffffffffc0202dde:	96ba                	add	a3,a3,a4
ffffffffc0202de0:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202de2:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202de6:	14a77e63          	bgeu	a4,a0,ffffffffc0202f42 <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202dea:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202dee:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202df0:	071a                	slli	a4,a4,0x6
ffffffffc0202df2:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202df6:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202df8:	6a9c                	ld	a5,16(a3)
ffffffffc0202dfa:	00c45593          	srli	a1,s0,0xc
ffffffffc0202dfe:	00e60533          	add	a0,a2,a4
ffffffffc0202e02:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202e04:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202e08:	bcf1                	j	ffffffffc02028e4 <pmm_init+0xfe>
        intr_disable();
ffffffffc0202e0a:	afbfd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e0e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e12:	4505                	li	a0,1
ffffffffc0202e14:	6f9c                	ld	a5,24(a5)
ffffffffc0202e16:	9782                	jalr	a5
ffffffffc0202e18:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e1a:	ae5fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e1e:	b119                	j	ffffffffc0202a24 <pmm_init+0x23e>
        intr_disable();
ffffffffc0202e20:	ae5fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e24:	000b3783          	ld	a5,0(s6)
ffffffffc0202e28:	779c                	ld	a5,40(a5)
ffffffffc0202e2a:	9782                	jalr	a5
ffffffffc0202e2c:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e2e:	ad1fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e32:	b345                	j	ffffffffc0202bd2 <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202e34:	ad1fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e38:	000b3783          	ld	a5,0(s6)
ffffffffc0202e3c:	779c                	ld	a5,40(a5)
ffffffffc0202e3e:	9782                	jalr	a5
ffffffffc0202e40:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e42:	abdfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e46:	b3a5                	j	ffffffffc0202bae <pmm_init+0x3c8>
ffffffffc0202e48:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e4a:	abbfd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e4e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e52:	6522                	ld	a0,8(sp)
ffffffffc0202e54:	4585                	li	a1,1
ffffffffc0202e56:	739c                	ld	a5,32(a5)
ffffffffc0202e58:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e5a:	aa5fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e5e:	bb05                	j	ffffffffc0202b8e <pmm_init+0x3a8>
ffffffffc0202e60:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e62:	aa3fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e66:	000b3783          	ld	a5,0(s6)
ffffffffc0202e6a:	6522                	ld	a0,8(sp)
ffffffffc0202e6c:	4585                	li	a1,1
ffffffffc0202e6e:	739c                	ld	a5,32(a5)
ffffffffc0202e70:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e72:	a8dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e76:	b1e5                	j	ffffffffc0202b5e <pmm_init+0x378>
        intr_disable();
ffffffffc0202e78:	a8dfd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e7c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e80:	4505                	li	a0,1
ffffffffc0202e82:	6f9c                	ld	a5,24(a5)
ffffffffc0202e84:	9782                	jalr	a5
ffffffffc0202e86:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e88:	a77fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e8c:	b375                	j	ffffffffc0202c38 <pmm_init+0x452>
        intr_disable();
ffffffffc0202e8e:	a77fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e92:	000b3783          	ld	a5,0(s6)
ffffffffc0202e96:	779c                	ld	a5,40(a5)
ffffffffc0202e98:	9782                	jalr	a5
ffffffffc0202e9a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e9c:	a63fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202ea0:	b5c5                	j	ffffffffc0202d80 <pmm_init+0x59a>
ffffffffc0202ea2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ea4:	a61fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202ea8:	000b3783          	ld	a5,0(s6)
ffffffffc0202eac:	6522                	ld	a0,8(sp)
ffffffffc0202eae:	4585                	li	a1,1
ffffffffc0202eb0:	739c                	ld	a5,32(a5)
ffffffffc0202eb2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202eb4:	a4bfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202eb8:	b565                	j	ffffffffc0202d60 <pmm_init+0x57a>
ffffffffc0202eba:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ebc:	a49fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202ec0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ec4:	6522                	ld	a0,8(sp)
ffffffffc0202ec6:	4585                	li	a1,1
ffffffffc0202ec8:	739c                	ld	a5,32(a5)
ffffffffc0202eca:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ecc:	a33fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202ed0:	b585                	j	ffffffffc0202d30 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202ed2:	a33fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202ed6:	000b3783          	ld	a5,0(s6)
ffffffffc0202eda:	8522                	mv	a0,s0
ffffffffc0202edc:	4585                	li	a1,1
ffffffffc0202ede:	739c                	ld	a5,32(a5)
ffffffffc0202ee0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ee2:	a1dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202ee6:	bd29                	j	ffffffffc0202d00 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ee8:	86a2                	mv	a3,s0
ffffffffc0202eea:	00003617          	auipc	a2,0x3
ffffffffc0202eee:	7f660613          	addi	a2,a2,2038 # ffffffffc02066e0 <etext+0xe30>
ffffffffc0202ef2:	24f00593          	li	a1,591
ffffffffc0202ef6:	00004517          	auipc	a0,0x4
ffffffffc0202efa:	8da50513          	addi	a0,a0,-1830 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0202efe:	d48fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202f02:	00004697          	auipc	a3,0x4
ffffffffc0202f06:	d6668693          	addi	a3,a3,-666 # ffffffffc0206c68 <etext+0x13b8>
ffffffffc0202f0a:	00003617          	auipc	a2,0x3
ffffffffc0202f0e:	42660613          	addi	a2,a2,1062 # ffffffffc0206330 <etext+0xa80>
ffffffffc0202f12:	25000593          	li	a1,592
ffffffffc0202f16:	00004517          	auipc	a0,0x4
ffffffffc0202f1a:	8ba50513          	addi	a0,a0,-1862 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0202f1e:	d28fd0ef          	jal	ffffffffc0200446 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202f22:	00004697          	auipc	a3,0x4
ffffffffc0202f26:	d0668693          	addi	a3,a3,-762 # ffffffffc0206c28 <etext+0x1378>
ffffffffc0202f2a:	00003617          	auipc	a2,0x3
ffffffffc0202f2e:	40660613          	addi	a2,a2,1030 # ffffffffc0206330 <etext+0xa80>
ffffffffc0202f32:	24f00593          	li	a1,591
ffffffffc0202f36:	00004517          	auipc	a0,0x4
ffffffffc0202f3a:	89a50513          	addi	a0,a0,-1894 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0202f3e:	d08fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202f42:	fb5fe0ef          	jal	ffffffffc0201ef6 <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202f46:	00004617          	auipc	a2,0x4
ffffffffc0202f4a:	a8260613          	addi	a2,a2,-1406 # ffffffffc02069c8 <etext+0x1118>
ffffffffc0202f4e:	07f00593          	li	a1,127
ffffffffc0202f52:	00003517          	auipc	a0,0x3
ffffffffc0202f56:	7b650513          	addi	a0,a0,1974 # ffffffffc0206708 <etext+0xe58>
ffffffffc0202f5a:	cecfd0ef          	jal	ffffffffc0200446 <__panic>
        panic("DTB memory info not available");
ffffffffc0202f5e:	00004617          	auipc	a2,0x4
ffffffffc0202f62:	8e260613          	addi	a2,a2,-1822 # ffffffffc0206840 <etext+0xf90>
ffffffffc0202f66:	06500593          	li	a1,101
ffffffffc0202f6a:	00004517          	auipc	a0,0x4
ffffffffc0202f6e:	86650513          	addi	a0,a0,-1946 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0202f72:	cd4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202f76:	00004697          	auipc	a3,0x4
ffffffffc0202f7a:	c6a68693          	addi	a3,a3,-918 # ffffffffc0206be0 <etext+0x1330>
ffffffffc0202f7e:	00003617          	auipc	a2,0x3
ffffffffc0202f82:	3b260613          	addi	a2,a2,946 # ffffffffc0206330 <etext+0xa80>
ffffffffc0202f86:	26a00593          	li	a1,618
ffffffffc0202f8a:	00004517          	auipc	a0,0x4
ffffffffc0202f8e:	84650513          	addi	a0,a0,-1978 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0202f92:	cb4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f96:	00004697          	auipc	a3,0x4
ffffffffc0202f9a:	96268693          	addi	a3,a3,-1694 # ffffffffc02068f8 <etext+0x1048>
ffffffffc0202f9e:	00003617          	auipc	a2,0x3
ffffffffc0202fa2:	39260613          	addi	a2,a2,914 # ffffffffc0206330 <etext+0xa80>
ffffffffc0202fa6:	21100593          	li	a1,529
ffffffffc0202faa:	00004517          	auipc	a0,0x4
ffffffffc0202fae:	82650513          	addi	a0,a0,-2010 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0202fb2:	c94fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202fb6:	00004697          	auipc	a3,0x4
ffffffffc0202fba:	92268693          	addi	a3,a3,-1758 # ffffffffc02068d8 <etext+0x1028>
ffffffffc0202fbe:	00003617          	auipc	a2,0x3
ffffffffc0202fc2:	37260613          	addi	a2,a2,882 # ffffffffc0206330 <etext+0xa80>
ffffffffc0202fc6:	21000593          	li	a1,528
ffffffffc0202fca:	00004517          	auipc	a0,0x4
ffffffffc0202fce:	80650513          	addi	a0,a0,-2042 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0202fd2:	c74fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202fd6:	00003617          	auipc	a2,0x3
ffffffffc0202fda:	70a60613          	addi	a2,a2,1802 # ffffffffc02066e0 <etext+0xe30>
ffffffffc0202fde:	07100593          	li	a1,113
ffffffffc0202fe2:	00003517          	auipc	a0,0x3
ffffffffc0202fe6:	72650513          	addi	a0,a0,1830 # ffffffffc0206708 <etext+0xe58>
ffffffffc0202fea:	c5cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202fee:	00004697          	auipc	a3,0x4
ffffffffc0202ff2:	bc268693          	addi	a3,a3,-1086 # ffffffffc0206bb0 <etext+0x1300>
ffffffffc0202ff6:	00003617          	auipc	a2,0x3
ffffffffc0202ffa:	33a60613          	addi	a2,a2,826 # ffffffffc0206330 <etext+0xa80>
ffffffffc0202ffe:	23800593          	li	a1,568
ffffffffc0203002:	00003517          	auipc	a0,0x3
ffffffffc0203006:	7ce50513          	addi	a0,a0,1998 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020300a:	c3cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020300e:	00004697          	auipc	a3,0x4
ffffffffc0203012:	b5a68693          	addi	a3,a3,-1190 # ffffffffc0206b68 <etext+0x12b8>
ffffffffc0203016:	00003617          	auipc	a2,0x3
ffffffffc020301a:	31a60613          	addi	a2,a2,794 # ffffffffc0206330 <etext+0xa80>
ffffffffc020301e:	23600593          	li	a1,566
ffffffffc0203022:	00003517          	auipc	a0,0x3
ffffffffc0203026:	7ae50513          	addi	a0,a0,1966 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020302a:	c1cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020302e:	00004697          	auipc	a3,0x4
ffffffffc0203032:	b6a68693          	addi	a3,a3,-1174 # ffffffffc0206b98 <etext+0x12e8>
ffffffffc0203036:	00003617          	auipc	a2,0x3
ffffffffc020303a:	2fa60613          	addi	a2,a2,762 # ffffffffc0206330 <etext+0xa80>
ffffffffc020303e:	23500593          	li	a1,565
ffffffffc0203042:	00003517          	auipc	a0,0x3
ffffffffc0203046:	78e50513          	addi	a0,a0,1934 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020304a:	bfcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc020304e:	00004697          	auipc	a3,0x4
ffffffffc0203052:	c3268693          	addi	a3,a3,-974 # ffffffffc0206c80 <etext+0x13d0>
ffffffffc0203056:	00003617          	auipc	a2,0x3
ffffffffc020305a:	2da60613          	addi	a2,a2,730 # ffffffffc0206330 <etext+0xa80>
ffffffffc020305e:	25300593          	li	a1,595
ffffffffc0203062:	00003517          	auipc	a0,0x3
ffffffffc0203066:	76e50513          	addi	a0,a0,1902 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020306a:	bdcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020306e:	00004697          	auipc	a3,0x4
ffffffffc0203072:	b7268693          	addi	a3,a3,-1166 # ffffffffc0206be0 <etext+0x1330>
ffffffffc0203076:	00003617          	auipc	a2,0x3
ffffffffc020307a:	2ba60613          	addi	a2,a2,698 # ffffffffc0206330 <etext+0xa80>
ffffffffc020307e:	24000593          	li	a1,576
ffffffffc0203082:	00003517          	auipc	a0,0x3
ffffffffc0203086:	74e50513          	addi	a0,a0,1870 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020308a:	bbcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 1);
ffffffffc020308e:	00004697          	auipc	a3,0x4
ffffffffc0203092:	c4a68693          	addi	a3,a3,-950 # ffffffffc0206cd8 <etext+0x1428>
ffffffffc0203096:	00003617          	auipc	a2,0x3
ffffffffc020309a:	29a60613          	addi	a2,a2,666 # ffffffffc0206330 <etext+0xa80>
ffffffffc020309e:	25800593          	li	a1,600
ffffffffc02030a2:	00003517          	auipc	a0,0x3
ffffffffc02030a6:	72e50513          	addi	a0,a0,1838 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02030aa:	b9cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02030ae:	00004697          	auipc	a3,0x4
ffffffffc02030b2:	bea68693          	addi	a3,a3,-1046 # ffffffffc0206c98 <etext+0x13e8>
ffffffffc02030b6:	00003617          	auipc	a2,0x3
ffffffffc02030ba:	27a60613          	addi	a2,a2,634 # ffffffffc0206330 <etext+0xa80>
ffffffffc02030be:	25700593          	li	a1,599
ffffffffc02030c2:	00003517          	auipc	a0,0x3
ffffffffc02030c6:	70e50513          	addi	a0,a0,1806 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02030ca:	b7cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030ce:	00004697          	auipc	a3,0x4
ffffffffc02030d2:	a9a68693          	addi	a3,a3,-1382 # ffffffffc0206b68 <etext+0x12b8>
ffffffffc02030d6:	00003617          	auipc	a2,0x3
ffffffffc02030da:	25a60613          	addi	a2,a2,602 # ffffffffc0206330 <etext+0xa80>
ffffffffc02030de:	23200593          	li	a1,562
ffffffffc02030e2:	00003517          	auipc	a0,0x3
ffffffffc02030e6:	6ee50513          	addi	a0,a0,1774 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02030ea:	b5cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02030ee:	00004697          	auipc	a3,0x4
ffffffffc02030f2:	91a68693          	addi	a3,a3,-1766 # ffffffffc0206a08 <etext+0x1158>
ffffffffc02030f6:	00003617          	auipc	a2,0x3
ffffffffc02030fa:	23a60613          	addi	a2,a2,570 # ffffffffc0206330 <etext+0xa80>
ffffffffc02030fe:	23100593          	li	a1,561
ffffffffc0203102:	00003517          	auipc	a0,0x3
ffffffffc0203106:	6ce50513          	addi	a0,a0,1742 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020310a:	b3cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc020310e:	00004697          	auipc	a3,0x4
ffffffffc0203112:	a7268693          	addi	a3,a3,-1422 # ffffffffc0206b80 <etext+0x12d0>
ffffffffc0203116:	00003617          	auipc	a2,0x3
ffffffffc020311a:	21a60613          	addi	a2,a2,538 # ffffffffc0206330 <etext+0xa80>
ffffffffc020311e:	22e00593          	li	a1,558
ffffffffc0203122:	00003517          	auipc	a0,0x3
ffffffffc0203126:	6ae50513          	addi	a0,a0,1710 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020312a:	b1cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020312e:	00004697          	auipc	a3,0x4
ffffffffc0203132:	8c268693          	addi	a3,a3,-1854 # ffffffffc02069f0 <etext+0x1140>
ffffffffc0203136:	00003617          	auipc	a2,0x3
ffffffffc020313a:	1fa60613          	addi	a2,a2,506 # ffffffffc0206330 <etext+0xa80>
ffffffffc020313e:	22d00593          	li	a1,557
ffffffffc0203142:	00003517          	auipc	a0,0x3
ffffffffc0203146:	68e50513          	addi	a0,a0,1678 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020314a:	afcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020314e:	00004697          	auipc	a3,0x4
ffffffffc0203152:	94268693          	addi	a3,a3,-1726 # ffffffffc0206a90 <etext+0x11e0>
ffffffffc0203156:	00003617          	auipc	a2,0x3
ffffffffc020315a:	1da60613          	addi	a2,a2,474 # ffffffffc0206330 <etext+0xa80>
ffffffffc020315e:	22c00593          	li	a1,556
ffffffffc0203162:	00003517          	auipc	a0,0x3
ffffffffc0203166:	66e50513          	addi	a0,a0,1646 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020316a:	adcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020316e:	00004697          	auipc	a3,0x4
ffffffffc0203172:	9fa68693          	addi	a3,a3,-1542 # ffffffffc0206b68 <etext+0x12b8>
ffffffffc0203176:	00003617          	auipc	a2,0x3
ffffffffc020317a:	1ba60613          	addi	a2,a2,442 # ffffffffc0206330 <etext+0xa80>
ffffffffc020317e:	22b00593          	li	a1,555
ffffffffc0203182:	00003517          	auipc	a0,0x3
ffffffffc0203186:	64e50513          	addi	a0,a0,1614 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020318a:	abcfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc020318e:	00004697          	auipc	a3,0x4
ffffffffc0203192:	9c268693          	addi	a3,a3,-1598 # ffffffffc0206b50 <etext+0x12a0>
ffffffffc0203196:	00003617          	auipc	a2,0x3
ffffffffc020319a:	19a60613          	addi	a2,a2,410 # ffffffffc0206330 <etext+0xa80>
ffffffffc020319e:	22a00593          	li	a1,554
ffffffffc02031a2:	00003517          	auipc	a0,0x3
ffffffffc02031a6:	62e50513          	addi	a0,a0,1582 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02031aa:	a9cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02031ae:	00004697          	auipc	a3,0x4
ffffffffc02031b2:	97268693          	addi	a3,a3,-1678 # ffffffffc0206b20 <etext+0x1270>
ffffffffc02031b6:	00003617          	auipc	a2,0x3
ffffffffc02031ba:	17a60613          	addi	a2,a2,378 # ffffffffc0206330 <etext+0xa80>
ffffffffc02031be:	22900593          	li	a1,553
ffffffffc02031c2:	00003517          	auipc	a0,0x3
ffffffffc02031c6:	60e50513          	addi	a0,a0,1550 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02031ca:	a7cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02031ce:	00004697          	auipc	a3,0x4
ffffffffc02031d2:	93a68693          	addi	a3,a3,-1734 # ffffffffc0206b08 <etext+0x1258>
ffffffffc02031d6:	00003617          	auipc	a2,0x3
ffffffffc02031da:	15a60613          	addi	a2,a2,346 # ffffffffc0206330 <etext+0xa80>
ffffffffc02031de:	22700593          	li	a1,551
ffffffffc02031e2:	00003517          	auipc	a0,0x3
ffffffffc02031e6:	5ee50513          	addi	a0,a0,1518 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02031ea:	a5cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02031ee:	00004697          	auipc	a3,0x4
ffffffffc02031f2:	8fa68693          	addi	a3,a3,-1798 # ffffffffc0206ae8 <etext+0x1238>
ffffffffc02031f6:	00003617          	auipc	a2,0x3
ffffffffc02031fa:	13a60613          	addi	a2,a2,314 # ffffffffc0206330 <etext+0xa80>
ffffffffc02031fe:	22600593          	li	a1,550
ffffffffc0203202:	00003517          	auipc	a0,0x3
ffffffffc0203206:	5ce50513          	addi	a0,a0,1486 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020320a:	a3cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_W);
ffffffffc020320e:	00004697          	auipc	a3,0x4
ffffffffc0203212:	8ca68693          	addi	a3,a3,-1846 # ffffffffc0206ad8 <etext+0x1228>
ffffffffc0203216:	00003617          	auipc	a2,0x3
ffffffffc020321a:	11a60613          	addi	a2,a2,282 # ffffffffc0206330 <etext+0xa80>
ffffffffc020321e:	22500593          	li	a1,549
ffffffffc0203222:	00003517          	auipc	a0,0x3
ffffffffc0203226:	5ae50513          	addi	a0,a0,1454 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020322a:	a1cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_U);
ffffffffc020322e:	00004697          	auipc	a3,0x4
ffffffffc0203232:	89a68693          	addi	a3,a3,-1894 # ffffffffc0206ac8 <etext+0x1218>
ffffffffc0203236:	00003617          	auipc	a2,0x3
ffffffffc020323a:	0fa60613          	addi	a2,a2,250 # ffffffffc0206330 <etext+0xa80>
ffffffffc020323e:	22400593          	li	a1,548
ffffffffc0203242:	00003517          	auipc	a0,0x3
ffffffffc0203246:	58e50513          	addi	a0,a0,1422 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020324a:	9fcfd0ef          	jal	ffffffffc0200446 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020324e:	00003617          	auipc	a2,0x3
ffffffffc0203252:	53a60613          	addi	a2,a2,1338 # ffffffffc0206788 <etext+0xed8>
ffffffffc0203256:	08100593          	li	a1,129
ffffffffc020325a:	00003517          	auipc	a0,0x3
ffffffffc020325e:	57650513          	addi	a0,a0,1398 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0203262:	9e4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0203266:	00003697          	auipc	a3,0x3
ffffffffc020326a:	7ba68693          	addi	a3,a3,1978 # ffffffffc0206a20 <etext+0x1170>
ffffffffc020326e:	00003617          	auipc	a2,0x3
ffffffffc0203272:	0c260613          	addi	a2,a2,194 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203276:	21f00593          	li	a1,543
ffffffffc020327a:	00003517          	auipc	a0,0x3
ffffffffc020327e:	55650513          	addi	a0,a0,1366 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0203282:	9c4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203286:	00004697          	auipc	a3,0x4
ffffffffc020328a:	80a68693          	addi	a3,a3,-2038 # ffffffffc0206a90 <etext+0x11e0>
ffffffffc020328e:	00003617          	auipc	a2,0x3
ffffffffc0203292:	0a260613          	addi	a2,a2,162 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203296:	22300593          	li	a1,547
ffffffffc020329a:	00003517          	auipc	a0,0x3
ffffffffc020329e:	53650513          	addi	a0,a0,1334 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02032a2:	9a4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02032a6:	00003697          	auipc	a3,0x3
ffffffffc02032aa:	7aa68693          	addi	a3,a3,1962 # ffffffffc0206a50 <etext+0x11a0>
ffffffffc02032ae:	00003617          	auipc	a2,0x3
ffffffffc02032b2:	08260613          	addi	a2,a2,130 # ffffffffc0206330 <etext+0xa80>
ffffffffc02032b6:	22200593          	li	a1,546
ffffffffc02032ba:	00003517          	auipc	a0,0x3
ffffffffc02032be:	51650513          	addi	a0,a0,1302 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02032c2:	984fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02032c6:	86d6                	mv	a3,s5
ffffffffc02032c8:	00003617          	auipc	a2,0x3
ffffffffc02032cc:	41860613          	addi	a2,a2,1048 # ffffffffc02066e0 <etext+0xe30>
ffffffffc02032d0:	21e00593          	li	a1,542
ffffffffc02032d4:	00003517          	auipc	a0,0x3
ffffffffc02032d8:	4fc50513          	addi	a0,a0,1276 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02032dc:	96afd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02032e0:	00003617          	auipc	a2,0x3
ffffffffc02032e4:	40060613          	addi	a2,a2,1024 # ffffffffc02066e0 <etext+0xe30>
ffffffffc02032e8:	21d00593          	li	a1,541
ffffffffc02032ec:	00003517          	auipc	a0,0x3
ffffffffc02032f0:	4e450513          	addi	a0,a0,1252 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02032f4:	952fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02032f8:	00003697          	auipc	a3,0x3
ffffffffc02032fc:	71068693          	addi	a3,a3,1808 # ffffffffc0206a08 <etext+0x1158>
ffffffffc0203300:	00003617          	auipc	a2,0x3
ffffffffc0203304:	03060613          	addi	a2,a2,48 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203308:	21b00593          	li	a1,539
ffffffffc020330c:	00003517          	auipc	a0,0x3
ffffffffc0203310:	4c450513          	addi	a0,a0,1220 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0203314:	932fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203318:	00003697          	auipc	a3,0x3
ffffffffc020331c:	6d868693          	addi	a3,a3,1752 # ffffffffc02069f0 <etext+0x1140>
ffffffffc0203320:	00003617          	auipc	a2,0x3
ffffffffc0203324:	01060613          	addi	a2,a2,16 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203328:	21a00593          	li	a1,538
ffffffffc020332c:	00003517          	auipc	a0,0x3
ffffffffc0203330:	4a450513          	addi	a0,a0,1188 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0203334:	912fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203338:	00004697          	auipc	a3,0x4
ffffffffc020333c:	a6868693          	addi	a3,a3,-1432 # ffffffffc0206da0 <etext+0x14f0>
ffffffffc0203340:	00003617          	auipc	a2,0x3
ffffffffc0203344:	ff060613          	addi	a2,a2,-16 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203348:	26100593          	li	a1,609
ffffffffc020334c:	00003517          	auipc	a0,0x3
ffffffffc0203350:	48450513          	addi	a0,a0,1156 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0203354:	8f2fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203358:	00004697          	auipc	a3,0x4
ffffffffc020335c:	a1068693          	addi	a3,a3,-1520 # ffffffffc0206d68 <etext+0x14b8>
ffffffffc0203360:	00003617          	auipc	a2,0x3
ffffffffc0203364:	fd060613          	addi	a2,a2,-48 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203368:	25e00593          	li	a1,606
ffffffffc020336c:	00003517          	auipc	a0,0x3
ffffffffc0203370:	46450513          	addi	a0,a0,1124 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0203374:	8d2fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0203378:	00004697          	auipc	a3,0x4
ffffffffc020337c:	9c068693          	addi	a3,a3,-1600 # ffffffffc0206d38 <etext+0x1488>
ffffffffc0203380:	00003617          	auipc	a2,0x3
ffffffffc0203384:	fb060613          	addi	a2,a2,-80 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203388:	25a00593          	li	a1,602
ffffffffc020338c:	00003517          	auipc	a0,0x3
ffffffffc0203390:	44450513          	addi	a0,a0,1092 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0203394:	8b2fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203398:	00004697          	auipc	a3,0x4
ffffffffc020339c:	95868693          	addi	a3,a3,-1704 # ffffffffc0206cf0 <etext+0x1440>
ffffffffc02033a0:	00003617          	auipc	a2,0x3
ffffffffc02033a4:	f9060613          	addi	a2,a2,-112 # ffffffffc0206330 <etext+0xa80>
ffffffffc02033a8:	25900593          	li	a1,601
ffffffffc02033ac:	00003517          	auipc	a0,0x3
ffffffffc02033b0:	42450513          	addi	a0,a0,1060 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02033b4:	892fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02033b8:	00003697          	auipc	a3,0x3
ffffffffc02033bc:	58068693          	addi	a3,a3,1408 # ffffffffc0206938 <etext+0x1088>
ffffffffc02033c0:	00003617          	auipc	a2,0x3
ffffffffc02033c4:	f7060613          	addi	a2,a2,-144 # ffffffffc0206330 <etext+0xa80>
ffffffffc02033c8:	21200593          	li	a1,530
ffffffffc02033cc:	00003517          	auipc	a0,0x3
ffffffffc02033d0:	40450513          	addi	a0,a0,1028 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02033d4:	872fd0ef          	jal	ffffffffc0200446 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02033d8:	00003617          	auipc	a2,0x3
ffffffffc02033dc:	3b060613          	addi	a2,a2,944 # ffffffffc0206788 <etext+0xed8>
ffffffffc02033e0:	0c900593          	li	a1,201
ffffffffc02033e4:	00003517          	auipc	a0,0x3
ffffffffc02033e8:	3ec50513          	addi	a0,a0,1004 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02033ec:	85afd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02033f0:	00003697          	auipc	a3,0x3
ffffffffc02033f4:	5a868693          	addi	a3,a3,1448 # ffffffffc0206998 <etext+0x10e8>
ffffffffc02033f8:	00003617          	auipc	a2,0x3
ffffffffc02033fc:	f3860613          	addi	a2,a2,-200 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203400:	21900593          	li	a1,537
ffffffffc0203404:	00003517          	auipc	a0,0x3
ffffffffc0203408:	3cc50513          	addi	a0,a0,972 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020340c:	83afd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203410:	00003697          	auipc	a3,0x3
ffffffffc0203414:	55868693          	addi	a3,a3,1368 # ffffffffc0206968 <etext+0x10b8>
ffffffffc0203418:	00003617          	auipc	a2,0x3
ffffffffc020341c:	f1860613          	addi	a2,a2,-232 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203420:	21600593          	li	a1,534
ffffffffc0203424:	00003517          	auipc	a0,0x3
ffffffffc0203428:	3ac50513          	addi	a0,a0,940 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020342c:	81afd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203430 <copy_range>:
{
ffffffffc0203430:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203432:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203436:	f486                	sd	ra,104(sp)
ffffffffc0203438:	f0a2                	sd	s0,96(sp)
ffffffffc020343a:	eca6                	sd	s1,88(sp)
ffffffffc020343c:	e8ca                	sd	s2,80(sp)
ffffffffc020343e:	e4ce                	sd	s3,72(sp)
ffffffffc0203440:	e0d2                	sd	s4,64(sp)
ffffffffc0203442:	fc56                	sd	s5,56(sp)
ffffffffc0203444:	f85a                	sd	s6,48(sp)
ffffffffc0203446:	f45e                	sd	s7,40(sp)
ffffffffc0203448:	f062                	sd	s8,32(sp)
ffffffffc020344a:	ec66                	sd	s9,24(sp)
ffffffffc020344c:	e86a                	sd	s10,16(sp)
ffffffffc020344e:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203450:	03479713          	slli	a4,a5,0x34
ffffffffc0203454:	20071f63          	bnez	a4,ffffffffc0203672 <copy_range+0x242>
    assert(USER_ACCESS(start, end));
ffffffffc0203458:	002007b7          	lui	a5,0x200
ffffffffc020345c:	00d63733          	sltu	a4,a2,a3
ffffffffc0203460:	00f637b3          	sltu	a5,a2,a5
ffffffffc0203464:	00173713          	seqz	a4,a4
ffffffffc0203468:	8fd9                	or	a5,a5,a4
ffffffffc020346a:	8432                	mv	s0,a2
ffffffffc020346c:	8936                	mv	s2,a3
ffffffffc020346e:	1e079263          	bnez	a5,ffffffffc0203652 <copy_range+0x222>
ffffffffc0203472:	4785                	li	a5,1
ffffffffc0203474:	07fe                	slli	a5,a5,0x1f
ffffffffc0203476:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e49>
ffffffffc0203478:	1cf6fd63          	bgeu	a3,a5,ffffffffc0203652 <copy_range+0x222>
ffffffffc020347c:	5b7d                	li	s6,-1
ffffffffc020347e:	8baa                	mv	s7,a0
ffffffffc0203480:	8a2e                	mv	s4,a1
ffffffffc0203482:	6a85                	lui	s5,0x1
ffffffffc0203484:	00cb5b13          	srli	s6,s6,0xc
    if (PPN(pa) >= npage)
ffffffffc0203488:	00098c97          	auipc	s9,0x98
ffffffffc020348c:	1e0c8c93          	addi	s9,s9,480 # ffffffffc029b668 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203490:	00098c17          	auipc	s8,0x98
ffffffffc0203494:	1e0c0c13          	addi	s8,s8,480 # ffffffffc029b670 <pages>
ffffffffc0203498:	fff80d37          	lui	s10,0xfff80
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020349c:	4601                	li	a2,0
ffffffffc020349e:	85a2                	mv	a1,s0
ffffffffc02034a0:	8552                	mv	a0,s4
ffffffffc02034a2:	b19fe0ef          	jal	ffffffffc0201fba <get_pte>
ffffffffc02034a6:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc02034a8:	0e050a63          	beqz	a0,ffffffffc020359c <copy_range+0x16c>
        if (*ptep & PTE_V)
ffffffffc02034ac:	611c                	ld	a5,0(a0)
ffffffffc02034ae:	8b85                	andi	a5,a5,1
ffffffffc02034b0:	e78d                	bnez	a5,ffffffffc02034da <copy_range+0xaa>
        start += PGSIZE;
ffffffffc02034b2:	9456                	add	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc02034b4:	c019                	beqz	s0,ffffffffc02034ba <copy_range+0x8a>
ffffffffc02034b6:	ff2463e3          	bltu	s0,s2,ffffffffc020349c <copy_range+0x6c>
    return 0;
ffffffffc02034ba:	4501                	li	a0,0
}
ffffffffc02034bc:	70a6                	ld	ra,104(sp)
ffffffffc02034be:	7406                	ld	s0,96(sp)
ffffffffc02034c0:	64e6                	ld	s1,88(sp)
ffffffffc02034c2:	6946                	ld	s2,80(sp)
ffffffffc02034c4:	69a6                	ld	s3,72(sp)
ffffffffc02034c6:	6a06                	ld	s4,64(sp)
ffffffffc02034c8:	7ae2                	ld	s5,56(sp)
ffffffffc02034ca:	7b42                	ld	s6,48(sp)
ffffffffc02034cc:	7ba2                	ld	s7,40(sp)
ffffffffc02034ce:	7c02                	ld	s8,32(sp)
ffffffffc02034d0:	6ce2                	ld	s9,24(sp)
ffffffffc02034d2:	6d42                	ld	s10,16(sp)
ffffffffc02034d4:	6da2                	ld	s11,8(sp)
ffffffffc02034d6:	6165                	addi	sp,sp,112
ffffffffc02034d8:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02034da:	4605                	li	a2,1
ffffffffc02034dc:	85a2                	mv	a1,s0
ffffffffc02034de:	855e                	mv	a0,s7
ffffffffc02034e0:	adbfe0ef          	jal	ffffffffc0201fba <get_pte>
ffffffffc02034e4:	c165                	beqz	a0,ffffffffc02035c4 <copy_range+0x194>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02034e6:	0004b983          	ld	s3,0(s1)
    if (!(pte & PTE_V))
ffffffffc02034ea:	0019f793          	andi	a5,s3,1
ffffffffc02034ee:	14078663          	beqz	a5,ffffffffc020363a <copy_range+0x20a>
    if (PPN(pa) >= npage)
ffffffffc02034f2:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02034f6:	00299793          	slli	a5,s3,0x2
ffffffffc02034fa:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02034fc:	12e7f363          	bgeu	a5,a4,ffffffffc0203622 <copy_range+0x1f2>
    return &pages[PPN(pa) - nbase];
ffffffffc0203500:	000c3483          	ld	s1,0(s8)
ffffffffc0203504:	97ea                	add	a5,a5,s10
ffffffffc0203506:	079a                	slli	a5,a5,0x6
ffffffffc0203508:	94be                	add	s1,s1,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020350a:	100027f3          	csrr	a5,sstatus
ffffffffc020350e:	8b89                	andi	a5,a5,2
ffffffffc0203510:	efc9                	bnez	a5,ffffffffc02035aa <copy_range+0x17a>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203512:	00098797          	auipc	a5,0x98
ffffffffc0203516:	1367b783          	ld	a5,310(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc020351a:	4505                	li	a0,1
ffffffffc020351c:	6f9c                	ld	a5,24(a5)
ffffffffc020351e:	9782                	jalr	a5
ffffffffc0203520:	8daa                	mv	s11,a0
            assert(page != NULL);
ffffffffc0203522:	c0e5                	beqz	s1,ffffffffc0203602 <copy_range+0x1d2>
            assert(npage != NULL);
ffffffffc0203524:	0a0d8f63          	beqz	s11,ffffffffc02035e2 <copy_range+0x1b2>
    return page - pages + nbase;
ffffffffc0203528:	000c3783          	ld	a5,0(s8)
ffffffffc020352c:	00080637          	lui	a2,0x80
    return KADDR(page2pa(page));
ffffffffc0203530:	000cb703          	ld	a4,0(s9)
    return page - pages + nbase;
ffffffffc0203534:	40f486b3          	sub	a3,s1,a5
ffffffffc0203538:	8699                	srai	a3,a3,0x6
ffffffffc020353a:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020353c:	0166f5b3          	and	a1,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203540:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203542:	08e5f463          	bgeu	a1,a4,ffffffffc02035ca <copy_range+0x19a>
    return page - pages + nbase;
ffffffffc0203546:	40fd87b3          	sub	a5,s11,a5
ffffffffc020354a:	8799                	srai	a5,a5,0x6
ffffffffc020354c:	97b2                	add	a5,a5,a2
    return KADDR(page2pa(page));
ffffffffc020354e:	0167f633          	and	a2,a5,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203552:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203554:	06e67a63          	bgeu	a2,a4,ffffffffc02035c8 <copy_range+0x198>
ffffffffc0203558:	00098517          	auipc	a0,0x98
ffffffffc020355c:	10853503          	ld	a0,264(a0) # ffffffffc029b660 <va_pa_offset>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0203560:	6605                	lui	a2,0x1
ffffffffc0203562:	00a685b3          	add	a1,a3,a0
ffffffffc0203566:	953e                	add	a0,a0,a5
ffffffffc0203568:	330020ef          	jal	ffffffffc0205898 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc020356c:	01f9f693          	andi	a3,s3,31
ffffffffc0203570:	85ee                	mv	a1,s11
ffffffffc0203572:	8622                	mv	a2,s0
ffffffffc0203574:	855e                	mv	a0,s7
ffffffffc0203576:	97aff0ef          	jal	ffffffffc02026f0 <page_insert>
            assert(ret == 0);
ffffffffc020357a:	dd05                	beqz	a0,ffffffffc02034b2 <copy_range+0x82>
ffffffffc020357c:	00004697          	auipc	a3,0x4
ffffffffc0203580:	88c68693          	addi	a3,a3,-1908 # ffffffffc0206e08 <etext+0x1558>
ffffffffc0203584:	00003617          	auipc	a2,0x3
ffffffffc0203588:	dac60613          	addi	a2,a2,-596 # ffffffffc0206330 <etext+0xa80>
ffffffffc020358c:	1ae00593          	li	a1,430
ffffffffc0203590:	00003517          	auipc	a0,0x3
ffffffffc0203594:	24050513          	addi	a0,a0,576 # ffffffffc02067d0 <etext+0xf20>
ffffffffc0203598:	eaffc0ef          	jal	ffffffffc0200446 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020359c:	002007b7          	lui	a5,0x200
ffffffffc02035a0:	97a2                	add	a5,a5,s0
ffffffffc02035a2:	ffe00437          	lui	s0,0xffe00
ffffffffc02035a6:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc02035a8:	b731                	j	ffffffffc02034b4 <copy_range+0x84>
        intr_disable();
ffffffffc02035aa:	b5afd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02035ae:	00098797          	auipc	a5,0x98
ffffffffc02035b2:	09a7b783          	ld	a5,154(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc02035b6:	4505                	li	a0,1
ffffffffc02035b8:	6f9c                	ld	a5,24(a5)
ffffffffc02035ba:	9782                	jalr	a5
ffffffffc02035bc:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc02035be:	b40fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02035c2:	b785                	j	ffffffffc0203522 <copy_range+0xf2>
                return -E_NO_MEM;
ffffffffc02035c4:	5571                	li	a0,-4
ffffffffc02035c6:	bddd                	j	ffffffffc02034bc <copy_range+0x8c>
ffffffffc02035c8:	86be                	mv	a3,a5
ffffffffc02035ca:	00003617          	auipc	a2,0x3
ffffffffc02035ce:	11660613          	addi	a2,a2,278 # ffffffffc02066e0 <etext+0xe30>
ffffffffc02035d2:	07100593          	li	a1,113
ffffffffc02035d6:	00003517          	auipc	a0,0x3
ffffffffc02035da:	13250513          	addi	a0,a0,306 # ffffffffc0206708 <etext+0xe58>
ffffffffc02035de:	e69fc0ef          	jal	ffffffffc0200446 <__panic>
            assert(npage != NULL);
ffffffffc02035e2:	00004697          	auipc	a3,0x4
ffffffffc02035e6:	81668693          	addi	a3,a3,-2026 # ffffffffc0206df8 <etext+0x1548>
ffffffffc02035ea:	00003617          	auipc	a2,0x3
ffffffffc02035ee:	d4660613          	addi	a2,a2,-698 # ffffffffc0206330 <etext+0xa80>
ffffffffc02035f2:	19500593          	li	a1,405
ffffffffc02035f6:	00003517          	auipc	a0,0x3
ffffffffc02035fa:	1da50513          	addi	a0,a0,474 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02035fe:	e49fc0ef          	jal	ffffffffc0200446 <__panic>
            assert(page != NULL);
ffffffffc0203602:	00003697          	auipc	a3,0x3
ffffffffc0203606:	7e668693          	addi	a3,a3,2022 # ffffffffc0206de8 <etext+0x1538>
ffffffffc020360a:	00003617          	auipc	a2,0x3
ffffffffc020360e:	d2660613          	addi	a2,a2,-730 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203612:	19400593          	li	a1,404
ffffffffc0203616:	00003517          	auipc	a0,0x3
ffffffffc020361a:	1ba50513          	addi	a0,a0,442 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020361e:	e29fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203622:	00003617          	auipc	a2,0x3
ffffffffc0203626:	18e60613          	addi	a2,a2,398 # ffffffffc02067b0 <etext+0xf00>
ffffffffc020362a:	06900593          	li	a1,105
ffffffffc020362e:	00003517          	auipc	a0,0x3
ffffffffc0203632:	0da50513          	addi	a0,a0,218 # ffffffffc0206708 <etext+0xe58>
ffffffffc0203636:	e11fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020363a:	00003617          	auipc	a2,0x3
ffffffffc020363e:	38e60613          	addi	a2,a2,910 # ffffffffc02069c8 <etext+0x1118>
ffffffffc0203642:	07f00593          	li	a1,127
ffffffffc0203646:	00003517          	auipc	a0,0x3
ffffffffc020364a:	0c250513          	addi	a0,a0,194 # ffffffffc0206708 <etext+0xe58>
ffffffffc020364e:	df9fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203652:	00003697          	auipc	a3,0x3
ffffffffc0203656:	1be68693          	addi	a3,a3,446 # ffffffffc0206810 <etext+0xf60>
ffffffffc020365a:	00003617          	auipc	a2,0x3
ffffffffc020365e:	cd660613          	addi	a2,a2,-810 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203662:	17c00593          	li	a1,380
ffffffffc0203666:	00003517          	auipc	a0,0x3
ffffffffc020366a:	16a50513          	addi	a0,a0,362 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020366e:	dd9fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203672:	00003697          	auipc	a3,0x3
ffffffffc0203676:	16e68693          	addi	a3,a3,366 # ffffffffc02067e0 <etext+0xf30>
ffffffffc020367a:	00003617          	auipc	a2,0x3
ffffffffc020367e:	cb660613          	addi	a2,a2,-842 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203682:	17b00593          	li	a1,379
ffffffffc0203686:	00003517          	auipc	a0,0x3
ffffffffc020368a:	14a50513          	addi	a0,a0,330 # ffffffffc02067d0 <etext+0xf20>
ffffffffc020368e:	db9fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203692 <pgdir_alloc_page>:
{
ffffffffc0203692:	7139                	addi	sp,sp,-64
ffffffffc0203694:	f426                	sd	s1,40(sp)
ffffffffc0203696:	f04a                	sd	s2,32(sp)
ffffffffc0203698:	ec4e                	sd	s3,24(sp)
ffffffffc020369a:	fc06                	sd	ra,56(sp)
ffffffffc020369c:	f822                	sd	s0,48(sp)
ffffffffc020369e:	892a                	mv	s2,a0
ffffffffc02036a0:	84ae                	mv	s1,a1
ffffffffc02036a2:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02036a4:	100027f3          	csrr	a5,sstatus
ffffffffc02036a8:	8b89                	andi	a5,a5,2
ffffffffc02036aa:	ebb5                	bnez	a5,ffffffffc020371e <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc02036ac:	00098417          	auipc	s0,0x98
ffffffffc02036b0:	f9c40413          	addi	s0,s0,-100 # ffffffffc029b648 <pmm_manager>
ffffffffc02036b4:	601c                	ld	a5,0(s0)
ffffffffc02036b6:	4505                	li	a0,1
ffffffffc02036b8:	6f9c                	ld	a5,24(a5)
ffffffffc02036ba:	9782                	jalr	a5
ffffffffc02036bc:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc02036be:	c5b9                	beqz	a1,ffffffffc020370c <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc02036c0:	86ce                	mv	a3,s3
ffffffffc02036c2:	854a                	mv	a0,s2
ffffffffc02036c4:	8626                	mv	a2,s1
ffffffffc02036c6:	e42e                	sd	a1,8(sp)
ffffffffc02036c8:	828ff0ef          	jal	ffffffffc02026f0 <page_insert>
ffffffffc02036cc:	65a2                	ld	a1,8(sp)
ffffffffc02036ce:	e515                	bnez	a0,ffffffffc02036fa <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc02036d0:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc02036d2:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc02036d4:	4785                	li	a5,1
ffffffffc02036d6:	02f70c63          	beq	a4,a5,ffffffffc020370e <pgdir_alloc_page+0x7c>
ffffffffc02036da:	00003697          	auipc	a3,0x3
ffffffffc02036de:	73e68693          	addi	a3,a3,1854 # ffffffffc0206e18 <etext+0x1568>
ffffffffc02036e2:	00003617          	auipc	a2,0x3
ffffffffc02036e6:	c4e60613          	addi	a2,a2,-946 # ffffffffc0206330 <etext+0xa80>
ffffffffc02036ea:	1f700593          	li	a1,503
ffffffffc02036ee:	00003517          	auipc	a0,0x3
ffffffffc02036f2:	0e250513          	addi	a0,a0,226 # ffffffffc02067d0 <etext+0xf20>
ffffffffc02036f6:	d51fc0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc02036fa:	100027f3          	csrr	a5,sstatus
ffffffffc02036fe:	8b89                	andi	a5,a5,2
ffffffffc0203700:	ef95                	bnez	a5,ffffffffc020373c <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc0203702:	601c                	ld	a5,0(s0)
ffffffffc0203704:	852e                	mv	a0,a1
ffffffffc0203706:	4585                	li	a1,1
ffffffffc0203708:	739c                	ld	a5,32(a5)
ffffffffc020370a:	9782                	jalr	a5
            return NULL;
ffffffffc020370c:	4581                	li	a1,0
}
ffffffffc020370e:	70e2                	ld	ra,56(sp)
ffffffffc0203710:	7442                	ld	s0,48(sp)
ffffffffc0203712:	74a2                	ld	s1,40(sp)
ffffffffc0203714:	7902                	ld	s2,32(sp)
ffffffffc0203716:	69e2                	ld	s3,24(sp)
ffffffffc0203718:	852e                	mv	a0,a1
ffffffffc020371a:	6121                	addi	sp,sp,64
ffffffffc020371c:	8082                	ret
        intr_disable();
ffffffffc020371e:	9e6fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203722:	00098417          	auipc	s0,0x98
ffffffffc0203726:	f2640413          	addi	s0,s0,-218 # ffffffffc029b648 <pmm_manager>
ffffffffc020372a:	601c                	ld	a5,0(s0)
ffffffffc020372c:	4505                	li	a0,1
ffffffffc020372e:	6f9c                	ld	a5,24(a5)
ffffffffc0203730:	9782                	jalr	a5
ffffffffc0203732:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0203734:	9cafd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0203738:	65a2                	ld	a1,8(sp)
ffffffffc020373a:	b751                	j	ffffffffc02036be <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc020373c:	9c8fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203740:	601c                	ld	a5,0(s0)
ffffffffc0203742:	6522                	ld	a0,8(sp)
ffffffffc0203744:	4585                	li	a1,1
ffffffffc0203746:	739c                	ld	a5,32(a5)
ffffffffc0203748:	9782                	jalr	a5
        intr_enable();
ffffffffc020374a:	9b4fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020374e:	bf7d                	j	ffffffffc020370c <pgdir_alloc_page+0x7a>

ffffffffc0203750 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203750:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203752:	00003697          	auipc	a3,0x3
ffffffffc0203756:	6de68693          	addi	a3,a3,1758 # ffffffffc0206e30 <etext+0x1580>
ffffffffc020375a:	00003617          	auipc	a2,0x3
ffffffffc020375e:	bd660613          	addi	a2,a2,-1066 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203762:	07400593          	li	a1,116
ffffffffc0203766:	00003517          	auipc	a0,0x3
ffffffffc020376a:	6ea50513          	addi	a0,a0,1770 # ffffffffc0206e50 <etext+0x15a0>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc020376e:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203770:	cd7fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203774 <mm_create>:
{
ffffffffc0203774:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203776:	04000513          	li	a0,64
{
ffffffffc020377a:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020377c:	dd4fe0ef          	jal	ffffffffc0201d50 <kmalloc>
    if (mm != NULL)
ffffffffc0203780:	cd19                	beqz	a0,ffffffffc020379e <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203782:	e508                	sd	a0,8(a0)
ffffffffc0203784:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203786:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020378a:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc020378e:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203792:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0203796:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc020379a:	02053c23          	sd	zero,56(a0)
}
ffffffffc020379e:	60a2                	ld	ra,8(sp)
ffffffffc02037a0:	0141                	addi	sp,sp,16
ffffffffc02037a2:	8082                	ret

ffffffffc02037a4 <find_vma>:
    if (mm != NULL)
ffffffffc02037a4:	c505                	beqz	a0,ffffffffc02037cc <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc02037a6:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037a8:	c781                	beqz	a5,ffffffffc02037b0 <find_vma+0xc>
ffffffffc02037aa:	6798                	ld	a4,8(a5)
ffffffffc02037ac:	02e5f363          	bgeu	a1,a4,ffffffffc02037d2 <find_vma+0x2e>
    return listelm->next;
ffffffffc02037b0:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc02037b2:	00f50d63          	beq	a0,a5,ffffffffc02037cc <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc02037b6:	fe87b703          	ld	a4,-24(a5)
ffffffffc02037ba:	00e5e663          	bltu	a1,a4,ffffffffc02037c6 <find_vma+0x22>
ffffffffc02037be:	ff07b703          	ld	a4,-16(a5)
ffffffffc02037c2:	00e5ee63          	bltu	a1,a4,ffffffffc02037de <find_vma+0x3a>
ffffffffc02037c6:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc02037c8:	fef517e3          	bne	a0,a5,ffffffffc02037b6 <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc02037cc:	4781                	li	a5,0
}
ffffffffc02037ce:	853e                	mv	a0,a5
ffffffffc02037d0:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037d2:	6b98                	ld	a4,16(a5)
ffffffffc02037d4:	fce5fee3          	bgeu	a1,a4,ffffffffc02037b0 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc02037d8:	e91c                	sd	a5,16(a0)
}
ffffffffc02037da:	853e                	mv	a0,a5
ffffffffc02037dc:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02037de:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc02037e0:	e91c                	sd	a5,16(a0)
ffffffffc02037e2:	bfe5                	j	ffffffffc02037da <find_vma+0x36>

ffffffffc02037e4 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037e4:	6590                	ld	a2,8(a1)
ffffffffc02037e6:	0105b803          	ld	a6,16(a1)
{
ffffffffc02037ea:	1141                	addi	sp,sp,-16
ffffffffc02037ec:	e406                	sd	ra,8(sp)
ffffffffc02037ee:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037f0:	01066763          	bltu	a2,a6,ffffffffc02037fe <insert_vma_struct+0x1a>
ffffffffc02037f4:	a8b9                	j	ffffffffc0203852 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02037f6:	fe87b703          	ld	a4,-24(a5)
ffffffffc02037fa:	04e66763          	bltu	a2,a4,ffffffffc0203848 <insert_vma_struct+0x64>
ffffffffc02037fe:	86be                	mv	a3,a5
ffffffffc0203800:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0203802:	fef51ae3          	bne	a0,a5,ffffffffc02037f6 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0203806:	02a68463          	beq	a3,a0,ffffffffc020382e <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020380a:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020380e:	fe86b883          	ld	a7,-24(a3)
ffffffffc0203812:	08e8f063          	bgeu	a7,a4,ffffffffc0203892 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203816:	04e66e63          	bltu	a2,a4,ffffffffc0203872 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc020381a:	00f50a63          	beq	a0,a5,ffffffffc020382e <insert_vma_struct+0x4a>
ffffffffc020381e:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203822:	05076863          	bltu	a4,a6,ffffffffc0203872 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0203826:	ff07b603          	ld	a2,-16(a5)
ffffffffc020382a:	02c77263          	bgeu	a4,a2,ffffffffc020384e <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc020382e:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203830:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203832:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203836:	e390                	sd	a2,0(a5)
ffffffffc0203838:	e690                	sd	a2,8(a3)
}
ffffffffc020383a:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020383c:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020383e:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203840:	2705                	addiw	a4,a4,1
ffffffffc0203842:	d118                	sw	a4,32(a0)
}
ffffffffc0203844:	0141                	addi	sp,sp,16
ffffffffc0203846:	8082                	ret
    if (le_prev != list)
ffffffffc0203848:	fca691e3          	bne	a3,a0,ffffffffc020380a <insert_vma_struct+0x26>
ffffffffc020384c:	bfd9                	j	ffffffffc0203822 <insert_vma_struct+0x3e>
ffffffffc020384e:	f03ff0ef          	jal	ffffffffc0203750 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203852:	00003697          	auipc	a3,0x3
ffffffffc0203856:	60e68693          	addi	a3,a3,1550 # ffffffffc0206e60 <etext+0x15b0>
ffffffffc020385a:	00003617          	auipc	a2,0x3
ffffffffc020385e:	ad660613          	addi	a2,a2,-1322 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203862:	07a00593          	li	a1,122
ffffffffc0203866:	00003517          	auipc	a0,0x3
ffffffffc020386a:	5ea50513          	addi	a0,a0,1514 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc020386e:	bd9fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203872:	00003697          	auipc	a3,0x3
ffffffffc0203876:	62e68693          	addi	a3,a3,1582 # ffffffffc0206ea0 <etext+0x15f0>
ffffffffc020387a:	00003617          	auipc	a2,0x3
ffffffffc020387e:	ab660613          	addi	a2,a2,-1354 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203882:	07300593          	li	a1,115
ffffffffc0203886:	00003517          	auipc	a0,0x3
ffffffffc020388a:	5ca50513          	addi	a0,a0,1482 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc020388e:	bb9fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203892:	00003697          	auipc	a3,0x3
ffffffffc0203896:	5ee68693          	addi	a3,a3,1518 # ffffffffc0206e80 <etext+0x15d0>
ffffffffc020389a:	00003617          	auipc	a2,0x3
ffffffffc020389e:	a9660613          	addi	a2,a2,-1386 # ffffffffc0206330 <etext+0xa80>
ffffffffc02038a2:	07200593          	li	a1,114
ffffffffc02038a6:	00003517          	auipc	a0,0x3
ffffffffc02038aa:	5aa50513          	addi	a0,a0,1450 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc02038ae:	b99fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02038b2 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc02038b2:	591c                	lw	a5,48(a0)
{
ffffffffc02038b4:	1141                	addi	sp,sp,-16
ffffffffc02038b6:	e406                	sd	ra,8(sp)
ffffffffc02038b8:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02038ba:	e78d                	bnez	a5,ffffffffc02038e4 <mm_destroy+0x32>
ffffffffc02038bc:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02038be:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc02038c0:	00a40c63          	beq	s0,a0,ffffffffc02038d8 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02038c4:	6118                	ld	a4,0(a0)
ffffffffc02038c6:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc02038c8:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02038ca:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02038cc:	e398                	sd	a4,0(a5)
ffffffffc02038ce:	d28fe0ef          	jal	ffffffffc0201df6 <kfree>
    return listelm->next;
ffffffffc02038d2:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02038d4:	fea418e3          	bne	s0,a0,ffffffffc02038c4 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02038d8:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02038da:	6402                	ld	s0,0(sp)
ffffffffc02038dc:	60a2                	ld	ra,8(sp)
ffffffffc02038de:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02038e0:	d16fe06f          	j	ffffffffc0201df6 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02038e4:	00003697          	auipc	a3,0x3
ffffffffc02038e8:	5dc68693          	addi	a3,a3,1500 # ffffffffc0206ec0 <etext+0x1610>
ffffffffc02038ec:	00003617          	auipc	a2,0x3
ffffffffc02038f0:	a4460613          	addi	a2,a2,-1468 # ffffffffc0206330 <etext+0xa80>
ffffffffc02038f4:	09e00593          	li	a1,158
ffffffffc02038f8:	00003517          	auipc	a0,0x3
ffffffffc02038fc:	55850513          	addi	a0,a0,1368 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203900:	b47fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203904 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203904:	6785                	lui	a5,0x1
ffffffffc0203906:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7bb1>
ffffffffc0203908:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc020390a:	4785                	li	a5,1
{
ffffffffc020390c:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020390e:	962e                	add	a2,a2,a1
ffffffffc0203910:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc0203912:	07fe                	slli	a5,a5,0x1f
{
ffffffffc0203914:	f822                	sd	s0,48(sp)
ffffffffc0203916:	f426                	sd	s1,40(sp)
ffffffffc0203918:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020391c:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc0203920:	0785                	addi	a5,a5,1
ffffffffc0203922:	0084b633          	sltu	a2,s1,s0
ffffffffc0203926:	00f437b3          	sltu	a5,s0,a5
ffffffffc020392a:	00163613          	seqz	a2,a2
ffffffffc020392e:	0017b793          	seqz	a5,a5
{
ffffffffc0203932:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203934:	8fd1                	or	a5,a5,a2
ffffffffc0203936:	ebbd                	bnez	a5,ffffffffc02039ac <mm_map+0xa8>
ffffffffc0203938:	002007b7          	lui	a5,0x200
ffffffffc020393c:	06f4e863          	bltu	s1,a5,ffffffffc02039ac <mm_map+0xa8>
ffffffffc0203940:	f04a                	sd	s2,32(sp)
ffffffffc0203942:	ec4e                	sd	s3,24(sp)
ffffffffc0203944:	e852                	sd	s4,16(sp)
ffffffffc0203946:	892a                	mv	s2,a0
ffffffffc0203948:	89ba                	mv	s3,a4
ffffffffc020394a:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc020394c:	c135                	beqz	a0,ffffffffc02039b0 <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc020394e:	85a6                	mv	a1,s1
ffffffffc0203950:	e55ff0ef          	jal	ffffffffc02037a4 <find_vma>
ffffffffc0203954:	c501                	beqz	a0,ffffffffc020395c <mm_map+0x58>
ffffffffc0203956:	651c                	ld	a5,8(a0)
ffffffffc0203958:	0487e763          	bltu	a5,s0,ffffffffc02039a6 <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020395c:	03000513          	li	a0,48
ffffffffc0203960:	bf0fe0ef          	jal	ffffffffc0201d50 <kmalloc>
ffffffffc0203964:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203966:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc0203968:	c59d                	beqz	a1,ffffffffc0203996 <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc020396a:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc020396c:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc020396e:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203972:	854a                	mv	a0,s2
ffffffffc0203974:	e42e                	sd	a1,8(sp)
ffffffffc0203976:	e6fff0ef          	jal	ffffffffc02037e4 <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc020397a:	65a2                	ld	a1,8(sp)
ffffffffc020397c:	00098463          	beqz	s3,ffffffffc0203984 <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc0203980:	00b9b023          	sd	a1,0(s3)
ffffffffc0203984:	7902                	ld	s2,32(sp)
ffffffffc0203986:	69e2                	ld	s3,24(sp)
ffffffffc0203988:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc020398a:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc020398c:	70e2                	ld	ra,56(sp)
ffffffffc020398e:	7442                	ld	s0,48(sp)
ffffffffc0203990:	74a2                	ld	s1,40(sp)
ffffffffc0203992:	6121                	addi	sp,sp,64
ffffffffc0203994:	8082                	ret
ffffffffc0203996:	70e2                	ld	ra,56(sp)
ffffffffc0203998:	7442                	ld	s0,48(sp)
ffffffffc020399a:	7902                	ld	s2,32(sp)
ffffffffc020399c:	69e2                	ld	s3,24(sp)
ffffffffc020399e:	6a42                	ld	s4,16(sp)
ffffffffc02039a0:	74a2                	ld	s1,40(sp)
ffffffffc02039a2:	6121                	addi	sp,sp,64
ffffffffc02039a4:	8082                	ret
ffffffffc02039a6:	7902                	ld	s2,32(sp)
ffffffffc02039a8:	69e2                	ld	s3,24(sp)
ffffffffc02039aa:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc02039ac:	5575                	li	a0,-3
ffffffffc02039ae:	bff9                	j	ffffffffc020398c <mm_map+0x88>
    assert(mm != NULL);
ffffffffc02039b0:	00003697          	auipc	a3,0x3
ffffffffc02039b4:	52868693          	addi	a3,a3,1320 # ffffffffc0206ed8 <etext+0x1628>
ffffffffc02039b8:	00003617          	auipc	a2,0x3
ffffffffc02039bc:	97860613          	addi	a2,a2,-1672 # ffffffffc0206330 <etext+0xa80>
ffffffffc02039c0:	0b300593          	li	a1,179
ffffffffc02039c4:	00003517          	auipc	a0,0x3
ffffffffc02039c8:	48c50513          	addi	a0,a0,1164 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc02039cc:	a7bfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02039d0 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02039d0:	7139                	addi	sp,sp,-64
ffffffffc02039d2:	fc06                	sd	ra,56(sp)
ffffffffc02039d4:	f822                	sd	s0,48(sp)
ffffffffc02039d6:	f426                	sd	s1,40(sp)
ffffffffc02039d8:	f04a                	sd	s2,32(sp)
ffffffffc02039da:	ec4e                	sd	s3,24(sp)
ffffffffc02039dc:	e852                	sd	s4,16(sp)
ffffffffc02039de:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02039e0:	c525                	beqz	a0,ffffffffc0203a48 <dup_mmap+0x78>
ffffffffc02039e2:	892a                	mv	s2,a0
ffffffffc02039e4:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02039e6:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02039e8:	c1a5                	beqz	a1,ffffffffc0203a48 <dup_mmap+0x78>
    return listelm->prev;
ffffffffc02039ea:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc02039ec:	04848c63          	beq	s1,s0,ffffffffc0203a44 <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039f0:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc02039f4:	fe843a83          	ld	s5,-24(s0)
ffffffffc02039f8:	ff043a03          	ld	s4,-16(s0)
ffffffffc02039fc:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a00:	b50fe0ef          	jal	ffffffffc0201d50 <kmalloc>
    if (vma != NULL)
ffffffffc0203a04:	c515                	beqz	a0,ffffffffc0203a30 <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0203a06:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203a08:	01553423          	sd	s5,8(a0)
ffffffffc0203a0c:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a10:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc0203a14:	854a                	mv	a0,s2
ffffffffc0203a16:	dcfff0ef          	jal	ffffffffc02037e4 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203a1a:	ff043683          	ld	a3,-16(s0)
ffffffffc0203a1e:	fe843603          	ld	a2,-24(s0)
ffffffffc0203a22:	6c8c                	ld	a1,24(s1)
ffffffffc0203a24:	01893503          	ld	a0,24(s2)
ffffffffc0203a28:	4701                	li	a4,0
ffffffffc0203a2a:	a07ff0ef          	jal	ffffffffc0203430 <copy_range>
ffffffffc0203a2e:	dd55                	beqz	a0,ffffffffc02039ea <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc0203a30:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203a32:	70e2                	ld	ra,56(sp)
ffffffffc0203a34:	7442                	ld	s0,48(sp)
ffffffffc0203a36:	74a2                	ld	s1,40(sp)
ffffffffc0203a38:	7902                	ld	s2,32(sp)
ffffffffc0203a3a:	69e2                	ld	s3,24(sp)
ffffffffc0203a3c:	6a42                	ld	s4,16(sp)
ffffffffc0203a3e:	6aa2                	ld	s5,8(sp)
ffffffffc0203a40:	6121                	addi	sp,sp,64
ffffffffc0203a42:	8082                	ret
    return 0;
ffffffffc0203a44:	4501                	li	a0,0
ffffffffc0203a46:	b7f5                	j	ffffffffc0203a32 <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc0203a48:	00003697          	auipc	a3,0x3
ffffffffc0203a4c:	4a068693          	addi	a3,a3,1184 # ffffffffc0206ee8 <etext+0x1638>
ffffffffc0203a50:	00003617          	auipc	a2,0x3
ffffffffc0203a54:	8e060613          	addi	a2,a2,-1824 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203a58:	0cf00593          	li	a1,207
ffffffffc0203a5c:	00003517          	auipc	a0,0x3
ffffffffc0203a60:	3f450513          	addi	a0,a0,1012 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203a64:	9e3fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203a68 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203a68:	1101                	addi	sp,sp,-32
ffffffffc0203a6a:	ec06                	sd	ra,24(sp)
ffffffffc0203a6c:	e822                	sd	s0,16(sp)
ffffffffc0203a6e:	e426                	sd	s1,8(sp)
ffffffffc0203a70:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a72:	c531                	beqz	a0,ffffffffc0203abe <exit_mmap+0x56>
ffffffffc0203a74:	591c                	lw	a5,48(a0)
ffffffffc0203a76:	84aa                	mv	s1,a0
ffffffffc0203a78:	e3b9                	bnez	a5,ffffffffc0203abe <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203a7a:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203a7c:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203a80:	02850663          	beq	a0,s0,ffffffffc0203aac <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a84:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a88:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a8c:	854a                	mv	a0,s2
ffffffffc0203a8e:	fdefe0ef          	jal	ffffffffc020226c <unmap_range>
ffffffffc0203a92:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a94:	fe8498e3          	bne	s1,s0,ffffffffc0203a84 <exit_mmap+0x1c>
ffffffffc0203a98:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a9a:	00848c63          	beq	s1,s0,ffffffffc0203ab2 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a9e:	ff043603          	ld	a2,-16(s0)
ffffffffc0203aa2:	fe843583          	ld	a1,-24(s0)
ffffffffc0203aa6:	854a                	mv	a0,s2
ffffffffc0203aa8:	8f9fe0ef          	jal	ffffffffc02023a0 <exit_range>
ffffffffc0203aac:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203aae:	fe8498e3          	bne	s1,s0,ffffffffc0203a9e <exit_mmap+0x36>
    }
}
ffffffffc0203ab2:	60e2                	ld	ra,24(sp)
ffffffffc0203ab4:	6442                	ld	s0,16(sp)
ffffffffc0203ab6:	64a2                	ld	s1,8(sp)
ffffffffc0203ab8:	6902                	ld	s2,0(sp)
ffffffffc0203aba:	6105                	addi	sp,sp,32
ffffffffc0203abc:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203abe:	00003697          	auipc	a3,0x3
ffffffffc0203ac2:	44a68693          	addi	a3,a3,1098 # ffffffffc0206f08 <etext+0x1658>
ffffffffc0203ac6:	00003617          	auipc	a2,0x3
ffffffffc0203aca:	86a60613          	addi	a2,a2,-1942 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203ace:	0e800593          	li	a1,232
ffffffffc0203ad2:	00003517          	auipc	a0,0x3
ffffffffc0203ad6:	37e50513          	addi	a0,a0,894 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203ada:	96dfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203ade <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203ade:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ae0:	04000513          	li	a0,64
{
ffffffffc0203ae4:	f406                	sd	ra,40(sp)
ffffffffc0203ae6:	f022                	sd	s0,32(sp)
ffffffffc0203ae8:	ec26                	sd	s1,24(sp)
ffffffffc0203aea:	e84a                	sd	s2,16(sp)
ffffffffc0203aec:	e44e                	sd	s3,8(sp)
ffffffffc0203aee:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203af0:	a60fe0ef          	jal	ffffffffc0201d50 <kmalloc>
    if (mm != NULL)
ffffffffc0203af4:	16050c63          	beqz	a0,ffffffffc0203c6c <vmm_init+0x18e>
ffffffffc0203af8:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0203afa:	e508                	sd	a0,8(a0)
ffffffffc0203afc:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203afe:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203b02:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203b06:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203b0a:	02053423          	sd	zero,40(a0)
ffffffffc0203b0e:	02052823          	sw	zero,48(a0)
ffffffffc0203b12:	02053c23          	sd	zero,56(a0)
ffffffffc0203b16:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b1a:	03000513          	li	a0,48
ffffffffc0203b1e:	a32fe0ef          	jal	ffffffffc0201d50 <kmalloc>
    if (vma != NULL)
ffffffffc0203b22:	12050563          	beqz	a0,ffffffffc0203c4c <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc0203b26:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203b2a:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b2c:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203b30:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b32:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0203b34:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0203b36:	8522                	mv	a0,s0
ffffffffc0203b38:	cadff0ef          	jal	ffffffffc02037e4 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203b3c:	fcf9                	bnez	s1,ffffffffc0203b1a <vmm_init+0x3c>
ffffffffc0203b3e:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b42:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b46:	03000513          	li	a0,48
ffffffffc0203b4a:	a06fe0ef          	jal	ffffffffc0201d50 <kmalloc>
    if (vma != NULL)
ffffffffc0203b4e:	12050f63          	beqz	a0,ffffffffc0203c8c <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc0203b52:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203b56:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b58:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203b5c:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b5e:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b60:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203b62:	8522                	mv	a0,s0
ffffffffc0203b64:	c81ff0ef          	jal	ffffffffc02037e4 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b68:	fd249fe3          	bne	s1,s2,ffffffffc0203b46 <vmm_init+0x68>
    return listelm->next;
ffffffffc0203b6c:	641c                	ld	a5,8(s0)
ffffffffc0203b6e:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203b70:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203b74:	1ef40c63          	beq	s0,a5,ffffffffc0203d6c <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b78:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f5e30>
ffffffffc0203b7c:	ffe70693          	addi	a3,a4,-2
ffffffffc0203b80:	12d61663          	bne	a2,a3,ffffffffc0203cac <vmm_init+0x1ce>
ffffffffc0203b84:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203b88:	12e69263          	bne	a3,a4,ffffffffc0203cac <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203b8c:	0715                	addi	a4,a4,5
ffffffffc0203b8e:	679c                	ld	a5,8(a5)
ffffffffc0203b90:	feb712e3          	bne	a4,a1,ffffffffc0203b74 <vmm_init+0x96>
ffffffffc0203b94:	491d                	li	s2,7
ffffffffc0203b96:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b98:	85a6                	mv	a1,s1
ffffffffc0203b9a:	8522                	mv	a0,s0
ffffffffc0203b9c:	c09ff0ef          	jal	ffffffffc02037a4 <find_vma>
ffffffffc0203ba0:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203ba2:	20050563          	beqz	a0,ffffffffc0203dac <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203ba6:	00148593          	addi	a1,s1,1
ffffffffc0203baa:	8522                	mv	a0,s0
ffffffffc0203bac:	bf9ff0ef          	jal	ffffffffc02037a4 <find_vma>
ffffffffc0203bb0:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203bb2:	1c050d63          	beqz	a0,ffffffffc0203d8c <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203bb6:	85ca                	mv	a1,s2
ffffffffc0203bb8:	8522                	mv	a0,s0
ffffffffc0203bba:	bebff0ef          	jal	ffffffffc02037a4 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203bbe:	18051763          	bnez	a0,ffffffffc0203d4c <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203bc2:	00348593          	addi	a1,s1,3
ffffffffc0203bc6:	8522                	mv	a0,s0
ffffffffc0203bc8:	bddff0ef          	jal	ffffffffc02037a4 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203bcc:	16051063          	bnez	a0,ffffffffc0203d2c <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203bd0:	00448593          	addi	a1,s1,4
ffffffffc0203bd4:	8522                	mv	a0,s0
ffffffffc0203bd6:	bcfff0ef          	jal	ffffffffc02037a4 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203bda:	12051963          	bnez	a0,ffffffffc0203d0c <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203bde:	008a3783          	ld	a5,8(s4)
ffffffffc0203be2:	10979563          	bne	a5,s1,ffffffffc0203cec <vmm_init+0x20e>
ffffffffc0203be6:	010a3783          	ld	a5,16(s4)
ffffffffc0203bea:	11279163          	bne	a5,s2,ffffffffc0203cec <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203bee:	0089b783          	ld	a5,8(s3)
ffffffffc0203bf2:	0c979d63          	bne	a5,s1,ffffffffc0203ccc <vmm_init+0x1ee>
ffffffffc0203bf6:	0109b783          	ld	a5,16(s3)
ffffffffc0203bfa:	0d279963          	bne	a5,s2,ffffffffc0203ccc <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203bfe:	0495                	addi	s1,s1,5
ffffffffc0203c00:	1f900793          	li	a5,505
ffffffffc0203c04:	0915                	addi	s2,s2,5
ffffffffc0203c06:	f8f499e3          	bne	s1,a5,ffffffffc0203b98 <vmm_init+0xba>
ffffffffc0203c0a:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203c0c:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203c0e:	85a6                	mv	a1,s1
ffffffffc0203c10:	8522                	mv	a0,s0
ffffffffc0203c12:	b93ff0ef          	jal	ffffffffc02037a4 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203c16:	1a051b63          	bnez	a0,ffffffffc0203dcc <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203c1a:	14fd                	addi	s1,s1,-1
ffffffffc0203c1c:	ff2499e3          	bne	s1,s2,ffffffffc0203c0e <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203c20:	8522                	mv	a0,s0
ffffffffc0203c22:	c91ff0ef          	jal	ffffffffc02038b2 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203c26:	00003517          	auipc	a0,0x3
ffffffffc0203c2a:	45250513          	addi	a0,a0,1106 # ffffffffc0207078 <etext+0x17c8>
ffffffffc0203c2e:	d66fc0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0203c32:	7402                	ld	s0,32(sp)
ffffffffc0203c34:	70a2                	ld	ra,40(sp)
ffffffffc0203c36:	64e2                	ld	s1,24(sp)
ffffffffc0203c38:	6942                	ld	s2,16(sp)
ffffffffc0203c3a:	69a2                	ld	s3,8(sp)
ffffffffc0203c3c:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203c3e:	00003517          	auipc	a0,0x3
ffffffffc0203c42:	45a50513          	addi	a0,a0,1114 # ffffffffc0207098 <etext+0x17e8>
}
ffffffffc0203c46:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203c48:	d4cfc06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0203c4c:	00003697          	auipc	a3,0x3
ffffffffc0203c50:	2dc68693          	addi	a3,a3,732 # ffffffffc0206f28 <etext+0x1678>
ffffffffc0203c54:	00002617          	auipc	a2,0x2
ffffffffc0203c58:	6dc60613          	addi	a2,a2,1756 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203c5c:	12c00593          	li	a1,300
ffffffffc0203c60:	00003517          	auipc	a0,0x3
ffffffffc0203c64:	1f050513          	addi	a0,a0,496 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203c68:	fdefc0ef          	jal	ffffffffc0200446 <__panic>
    assert(mm != NULL);
ffffffffc0203c6c:	00003697          	auipc	a3,0x3
ffffffffc0203c70:	26c68693          	addi	a3,a3,620 # ffffffffc0206ed8 <etext+0x1628>
ffffffffc0203c74:	00002617          	auipc	a2,0x2
ffffffffc0203c78:	6bc60613          	addi	a2,a2,1724 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203c7c:	12400593          	li	a1,292
ffffffffc0203c80:	00003517          	auipc	a0,0x3
ffffffffc0203c84:	1d050513          	addi	a0,a0,464 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203c88:	fbefc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma != NULL);
ffffffffc0203c8c:	00003697          	auipc	a3,0x3
ffffffffc0203c90:	29c68693          	addi	a3,a3,668 # ffffffffc0206f28 <etext+0x1678>
ffffffffc0203c94:	00002617          	auipc	a2,0x2
ffffffffc0203c98:	69c60613          	addi	a2,a2,1692 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203c9c:	13300593          	li	a1,307
ffffffffc0203ca0:	00003517          	auipc	a0,0x3
ffffffffc0203ca4:	1b050513          	addi	a0,a0,432 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203ca8:	f9efc0ef          	jal	ffffffffc0200446 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203cac:	00003697          	auipc	a3,0x3
ffffffffc0203cb0:	2a468693          	addi	a3,a3,676 # ffffffffc0206f50 <etext+0x16a0>
ffffffffc0203cb4:	00002617          	auipc	a2,0x2
ffffffffc0203cb8:	67c60613          	addi	a2,a2,1660 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203cbc:	13d00593          	li	a1,317
ffffffffc0203cc0:	00003517          	auipc	a0,0x3
ffffffffc0203cc4:	19050513          	addi	a0,a0,400 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203cc8:	f7efc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203ccc:	00003697          	auipc	a3,0x3
ffffffffc0203cd0:	33c68693          	addi	a3,a3,828 # ffffffffc0207008 <etext+0x1758>
ffffffffc0203cd4:	00002617          	auipc	a2,0x2
ffffffffc0203cd8:	65c60613          	addi	a2,a2,1628 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203cdc:	14f00593          	li	a1,335
ffffffffc0203ce0:	00003517          	auipc	a0,0x3
ffffffffc0203ce4:	17050513          	addi	a0,a0,368 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203ce8:	f5efc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203cec:	00003697          	auipc	a3,0x3
ffffffffc0203cf0:	2ec68693          	addi	a3,a3,748 # ffffffffc0206fd8 <etext+0x1728>
ffffffffc0203cf4:	00002617          	auipc	a2,0x2
ffffffffc0203cf8:	63c60613          	addi	a2,a2,1596 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203cfc:	14e00593          	li	a1,334
ffffffffc0203d00:	00003517          	auipc	a0,0x3
ffffffffc0203d04:	15050513          	addi	a0,a0,336 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203d08:	f3efc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma5 == NULL);
ffffffffc0203d0c:	00003697          	auipc	a3,0x3
ffffffffc0203d10:	2bc68693          	addi	a3,a3,700 # ffffffffc0206fc8 <etext+0x1718>
ffffffffc0203d14:	00002617          	auipc	a2,0x2
ffffffffc0203d18:	61c60613          	addi	a2,a2,1564 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203d1c:	14c00593          	li	a1,332
ffffffffc0203d20:	00003517          	auipc	a0,0x3
ffffffffc0203d24:	13050513          	addi	a0,a0,304 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203d28:	f1efc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma4 == NULL);
ffffffffc0203d2c:	00003697          	auipc	a3,0x3
ffffffffc0203d30:	28c68693          	addi	a3,a3,652 # ffffffffc0206fb8 <etext+0x1708>
ffffffffc0203d34:	00002617          	auipc	a2,0x2
ffffffffc0203d38:	5fc60613          	addi	a2,a2,1532 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203d3c:	14a00593          	li	a1,330
ffffffffc0203d40:	00003517          	auipc	a0,0x3
ffffffffc0203d44:	11050513          	addi	a0,a0,272 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203d48:	efefc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma3 == NULL);
ffffffffc0203d4c:	00003697          	auipc	a3,0x3
ffffffffc0203d50:	25c68693          	addi	a3,a3,604 # ffffffffc0206fa8 <etext+0x16f8>
ffffffffc0203d54:	00002617          	auipc	a2,0x2
ffffffffc0203d58:	5dc60613          	addi	a2,a2,1500 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203d5c:	14800593          	li	a1,328
ffffffffc0203d60:	00003517          	auipc	a0,0x3
ffffffffc0203d64:	0f050513          	addi	a0,a0,240 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203d68:	edefc0ef          	jal	ffffffffc0200446 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203d6c:	00003697          	auipc	a3,0x3
ffffffffc0203d70:	1cc68693          	addi	a3,a3,460 # ffffffffc0206f38 <etext+0x1688>
ffffffffc0203d74:	00002617          	auipc	a2,0x2
ffffffffc0203d78:	5bc60613          	addi	a2,a2,1468 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203d7c:	13b00593          	li	a1,315
ffffffffc0203d80:	00003517          	auipc	a0,0x3
ffffffffc0203d84:	0d050513          	addi	a0,a0,208 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203d88:	ebefc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2 != NULL);
ffffffffc0203d8c:	00003697          	auipc	a3,0x3
ffffffffc0203d90:	20c68693          	addi	a3,a3,524 # ffffffffc0206f98 <etext+0x16e8>
ffffffffc0203d94:	00002617          	auipc	a2,0x2
ffffffffc0203d98:	59c60613          	addi	a2,a2,1436 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203d9c:	14600593          	li	a1,326
ffffffffc0203da0:	00003517          	auipc	a0,0x3
ffffffffc0203da4:	0b050513          	addi	a0,a0,176 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203da8:	e9efc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1 != NULL);
ffffffffc0203dac:	00003697          	auipc	a3,0x3
ffffffffc0203db0:	1dc68693          	addi	a3,a3,476 # ffffffffc0206f88 <etext+0x16d8>
ffffffffc0203db4:	00002617          	auipc	a2,0x2
ffffffffc0203db8:	57c60613          	addi	a2,a2,1404 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203dbc:	14400593          	li	a1,324
ffffffffc0203dc0:	00003517          	auipc	a0,0x3
ffffffffc0203dc4:	09050513          	addi	a0,a0,144 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203dc8:	e7efc0ef          	jal	ffffffffc0200446 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203dcc:	6914                	ld	a3,16(a0)
ffffffffc0203dce:	6510                	ld	a2,8(a0)
ffffffffc0203dd0:	0004859b          	sext.w	a1,s1
ffffffffc0203dd4:	00003517          	auipc	a0,0x3
ffffffffc0203dd8:	26450513          	addi	a0,a0,612 # ffffffffc0207038 <etext+0x1788>
ffffffffc0203ddc:	bb8fc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203de0:	00003697          	auipc	a3,0x3
ffffffffc0203de4:	28068693          	addi	a3,a3,640 # ffffffffc0207060 <etext+0x17b0>
ffffffffc0203de8:	00002617          	auipc	a2,0x2
ffffffffc0203dec:	54860613          	addi	a2,a2,1352 # ffffffffc0206330 <etext+0xa80>
ffffffffc0203df0:	15900593          	li	a1,345
ffffffffc0203df4:	00003517          	auipc	a0,0x3
ffffffffc0203df8:	05c50513          	addi	a0,a0,92 # ffffffffc0206e50 <etext+0x15a0>
ffffffffc0203dfc:	e4afc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203e00 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203e00:	7179                	addi	sp,sp,-48
ffffffffc0203e02:	f022                	sd	s0,32(sp)
ffffffffc0203e04:	f406                	sd	ra,40(sp)
ffffffffc0203e06:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203e08:	c52d                	beqz	a0,ffffffffc0203e72 <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203e0a:	002007b7          	lui	a5,0x200
ffffffffc0203e0e:	04f5ed63          	bltu	a1,a5,ffffffffc0203e68 <user_mem_check+0x68>
ffffffffc0203e12:	ec26                	sd	s1,24(sp)
ffffffffc0203e14:	00c584b3          	add	s1,a1,a2
ffffffffc0203e18:	0695ff63          	bgeu	a1,s1,ffffffffc0203e96 <user_mem_check+0x96>
ffffffffc0203e1c:	4785                	li	a5,1
ffffffffc0203e1e:	07fe                	slli	a5,a5,0x1f
ffffffffc0203e20:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e49>
ffffffffc0203e22:	06f4fa63          	bgeu	s1,a5,ffffffffc0203e96 <user_mem_check+0x96>
ffffffffc0203e26:	e84a                	sd	s2,16(sp)
ffffffffc0203e28:	e44e                	sd	s3,8(sp)
ffffffffc0203e2a:	8936                	mv	s2,a3
ffffffffc0203e2c:	89aa                	mv	s3,a0
ffffffffc0203e2e:	a829                	j	ffffffffc0203e48 <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e30:	6685                	lui	a3,0x1
ffffffffc0203e32:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e34:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e38:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e3a:	c685                	beqz	a3,ffffffffc0203e62 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e3c:	c399                	beqz	a5,ffffffffc0203e42 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e3e:	02e46263          	bltu	s0,a4,ffffffffc0203e62 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203e42:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203e44:	04947b63          	bgeu	s0,s1,ffffffffc0203e9a <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203e48:	85a2                	mv	a1,s0
ffffffffc0203e4a:	854e                	mv	a0,s3
ffffffffc0203e4c:	959ff0ef          	jal	ffffffffc02037a4 <find_vma>
ffffffffc0203e50:	c909                	beqz	a0,ffffffffc0203e62 <user_mem_check+0x62>
ffffffffc0203e52:	6518                	ld	a4,8(a0)
ffffffffc0203e54:	00e46763          	bltu	s0,a4,ffffffffc0203e62 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e58:	4d1c                	lw	a5,24(a0)
ffffffffc0203e5a:	fc091be3          	bnez	s2,ffffffffc0203e30 <user_mem_check+0x30>
ffffffffc0203e5e:	8b85                	andi	a5,a5,1
ffffffffc0203e60:	f3ed                	bnez	a5,ffffffffc0203e42 <user_mem_check+0x42>
ffffffffc0203e62:	64e2                	ld	s1,24(sp)
ffffffffc0203e64:	6942                	ld	s2,16(sp)
ffffffffc0203e66:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203e68:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e6a:	70a2                	ld	ra,40(sp)
ffffffffc0203e6c:	7402                	ld	s0,32(sp)
ffffffffc0203e6e:	6145                	addi	sp,sp,48
ffffffffc0203e70:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e72:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e76:	fef5eae3          	bltu	a1,a5,ffffffffc0203e6a <user_mem_check+0x6a>
ffffffffc0203e7a:	c80007b7          	lui	a5,0xc8000
ffffffffc0203e7e:	962e                	add	a2,a2,a1
ffffffffc0203e80:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d64969>
ffffffffc0203e82:	00c5b433          	sltu	s0,a1,a2
ffffffffc0203e86:	00f63633          	sltu	a2,a2,a5
ffffffffc0203e8a:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e8c:	00867533          	and	a0,a2,s0
ffffffffc0203e90:	7402                	ld	s0,32(sp)
ffffffffc0203e92:	6145                	addi	sp,sp,48
ffffffffc0203e94:	8082                	ret
ffffffffc0203e96:	64e2                	ld	s1,24(sp)
ffffffffc0203e98:	bfc1                	j	ffffffffc0203e68 <user_mem_check+0x68>
ffffffffc0203e9a:	64e2                	ld	s1,24(sp)
ffffffffc0203e9c:	6942                	ld	s2,16(sp)
ffffffffc0203e9e:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203ea0:	4505                	li	a0,1
ffffffffc0203ea2:	b7e1                	j	ffffffffc0203e6a <user_mem_check+0x6a>

ffffffffc0203ea4 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203ea4:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203ea6:	9402                	jalr	s0

	jal do_exit
ffffffffc0203ea8:	676000ef          	jal	ffffffffc020451e <do_exit>

ffffffffc0203eac <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203eac:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203eae:	10800513          	li	a0,264
{
ffffffffc0203eb2:	e022                	sd	s0,0(sp)
ffffffffc0203eb4:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203eb6:	e9bfd0ef          	jal	ffffffffc0201d50 <kmalloc>
ffffffffc0203eba:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203ebc:	c929                	beqz	a0,ffffffffc0203f0e <alloc_proc+0x62>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->state = PROC_UNINIT;
ffffffffc0203ebe:	57fd                	li	a5,-1
ffffffffc0203ec0:	1782                	slli	a5,a5,0x20
ffffffffc0203ec2:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc0203ec4:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0203ec8:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0203ecc:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203ed0:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203ed4:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203ed8:	07000613          	li	a2,112
ffffffffc0203edc:	4581                	li	a1,0
ffffffffc0203ede:	03050513          	addi	a0,a0,48
ffffffffc0203ee2:	1a5010ef          	jal	ffffffffc0205886 <memset>
        proc->tf = NULL;
        proc->pgdir = 0;
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203ee6:	0b440513          	addi	a0,s0,180
        proc->tf = NULL;
ffffffffc0203eea:	0a043023          	sd	zero,160(s0)
        proc->pgdir = 0;
ffffffffc0203eee:	0a043423          	sd	zero,168(s0)
        proc->flags = 0;
ffffffffc0203ef2:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203ef6:	4641                	li	a2,16
ffffffffc0203ef8:	4581                	li	a1,0
ffffffffc0203efa:	18d010ef          	jal	ffffffffc0205886 <memset>
        proc->wait_state = 0;
ffffffffc0203efe:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc0203f02:	10043023          	sd	zero,256(s0)
ffffffffc0203f06:	0e043c23          	sd	zero,248(s0)
ffffffffc0203f0a:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc0203f0e:	60a2                	ld	ra,8(sp)
ffffffffc0203f10:	8522                	mv	a0,s0
ffffffffc0203f12:	6402                	ld	s0,0(sp)
ffffffffc0203f14:	0141                	addi	sp,sp,16
ffffffffc0203f16:	8082                	ret

ffffffffc0203f18 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203f18:	00097797          	auipc	a5,0x97
ffffffffc0203f1c:	7687b783          	ld	a5,1896(a5) # ffffffffc029b680 <current>
ffffffffc0203f20:	73c8                	ld	a0,160(a5)
ffffffffc0203f22:	814fd06f          	j	ffffffffc0200f36 <forkrets>

ffffffffc0203f26 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203f26:	00097797          	auipc	a5,0x97
ffffffffc0203f2a:	75a7b783          	ld	a5,1882(a5) # ffffffffc029b680 <current>
{
ffffffffc0203f2e:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203f30:	00003617          	auipc	a2,0x3
ffffffffc0203f34:	18060613          	addi	a2,a2,384 # ffffffffc02070b0 <etext+0x1800>
ffffffffc0203f38:	43cc                	lw	a1,4(a5)
ffffffffc0203f3a:	00003517          	auipc	a0,0x3
ffffffffc0203f3e:	18650513          	addi	a0,a0,390 # ffffffffc02070c0 <etext+0x1810>
{
ffffffffc0203f42:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203f44:	a50fc0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0203f48:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0203f4c:	98878793          	addi	a5,a5,-1656 # 98d0 <_binary_obj___user_forktest_out_size>
ffffffffc0203f50:	e43e                	sd	a5,8(sp)
kernel_execve(const char *name, unsigned char *binary, size_t size)
ffffffffc0203f52:	00003517          	auipc	a0,0x3
ffffffffc0203f56:	15e50513          	addi	a0,a0,350 # ffffffffc02070b0 <etext+0x1800>
ffffffffc0203f5a:	0003f797          	auipc	a5,0x3f
ffffffffc0203f5e:	73678793          	addi	a5,a5,1846 # ffffffffc0243690 <_binary_obj___user_forktest_out_start>
ffffffffc0203f62:	f03e                	sd	a5,32(sp)
ffffffffc0203f64:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203f66:	e802                	sd	zero,16(sp)
ffffffffc0203f68:	06b010ef          	jal	ffffffffc02057d2 <strlen>
ffffffffc0203f6c:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203f6e:	4511                	li	a0,4
ffffffffc0203f70:	55a2                	lw	a1,40(sp)
ffffffffc0203f72:	4662                	lw	a2,24(sp)
ffffffffc0203f74:	5682                	lw	a3,32(sp)
ffffffffc0203f76:	4722                	lw	a4,8(sp)
ffffffffc0203f78:	48a9                	li	a7,10
ffffffffc0203f7a:	9002                	ebreak
ffffffffc0203f7c:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203f7e:	65c2                	ld	a1,16(sp)
ffffffffc0203f80:	00003517          	auipc	a0,0x3
ffffffffc0203f84:	16850513          	addi	a0,a0,360 # ffffffffc02070e8 <etext+0x1838>
ffffffffc0203f88:	a0cfc0ef          	jal	ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0203f8c:	00003617          	auipc	a2,0x3
ffffffffc0203f90:	16c60613          	addi	a2,a2,364 # ffffffffc02070f8 <etext+0x1848>
ffffffffc0203f94:	3ba00593          	li	a1,954
ffffffffc0203f98:	00003517          	auipc	a0,0x3
ffffffffc0203f9c:	18050513          	addi	a0,a0,384 # ffffffffc0207118 <etext+0x1868>
ffffffffc0203fa0:	ca6fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203fa4 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203fa4:	6d14                	ld	a3,24(a0)
{
ffffffffc0203fa6:	1141                	addi	sp,sp,-16
ffffffffc0203fa8:	e406                	sd	ra,8(sp)
ffffffffc0203faa:	c02007b7          	lui	a5,0xc0200
ffffffffc0203fae:	02f6ee63          	bltu	a3,a5,ffffffffc0203fea <put_pgdir+0x46>
ffffffffc0203fb2:	00097717          	auipc	a4,0x97
ffffffffc0203fb6:	6ae73703          	ld	a4,1710(a4) # ffffffffc029b660 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203fba:	00097797          	auipc	a5,0x97
ffffffffc0203fbe:	6ae7b783          	ld	a5,1710(a5) # ffffffffc029b668 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203fc2:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203fc4:	82b1                	srli	a3,a3,0xc
ffffffffc0203fc6:	02f6fe63          	bgeu	a3,a5,ffffffffc0204002 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203fca:	00004797          	auipc	a5,0x4
ffffffffc0203fce:	af67b783          	ld	a5,-1290(a5) # ffffffffc0207ac0 <nbase>
ffffffffc0203fd2:	00097517          	auipc	a0,0x97
ffffffffc0203fd6:	69e53503          	ld	a0,1694(a0) # ffffffffc029b670 <pages>
}
ffffffffc0203fda:	60a2                	ld	ra,8(sp)
ffffffffc0203fdc:	8e9d                	sub	a3,a3,a5
ffffffffc0203fde:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203fe0:	4585                	li	a1,1
ffffffffc0203fe2:	9536                	add	a0,a0,a3
}
ffffffffc0203fe4:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203fe6:	f67fd06f          	j	ffffffffc0201f4c <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203fea:	00002617          	auipc	a2,0x2
ffffffffc0203fee:	79e60613          	addi	a2,a2,1950 # ffffffffc0206788 <etext+0xed8>
ffffffffc0203ff2:	07700593          	li	a1,119
ffffffffc0203ff6:	00002517          	auipc	a0,0x2
ffffffffc0203ffa:	71250513          	addi	a0,a0,1810 # ffffffffc0206708 <etext+0xe58>
ffffffffc0203ffe:	c48fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204002:	00002617          	auipc	a2,0x2
ffffffffc0204006:	7ae60613          	addi	a2,a2,1966 # ffffffffc02067b0 <etext+0xf00>
ffffffffc020400a:	06900593          	li	a1,105
ffffffffc020400e:	00002517          	auipc	a0,0x2
ffffffffc0204012:	6fa50513          	addi	a0,a0,1786 # ffffffffc0206708 <etext+0xe58>
ffffffffc0204016:	c30fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020401a <proc_run>:
    if (proc != current)
ffffffffc020401a:	00097697          	auipc	a3,0x97
ffffffffc020401e:	6666b683          	ld	a3,1638(a3) # ffffffffc029b680 <current>
ffffffffc0204022:	04a68463          	beq	a3,a0,ffffffffc020406a <proc_run+0x50>
{
ffffffffc0204026:	1101                	addi	sp,sp,-32
ffffffffc0204028:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020402a:	100027f3          	csrr	a5,sstatus
ffffffffc020402e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204030:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204032:	ef8d                	bnez	a5,ffffffffc020406c <proc_run+0x52>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0204034:	755c                	ld	a5,168(a0)
ffffffffc0204036:	577d                	li	a4,-1
ffffffffc0204038:	177e                	slli	a4,a4,0x3f
ffffffffc020403a:	83b1                	srli	a5,a5,0xc
ffffffffc020403c:	e032                	sd	a2,0(sp)
            current = proc;
ffffffffc020403e:	00097597          	auipc	a1,0x97
ffffffffc0204042:	64a5b123          	sd	a0,1602(a1) # ffffffffc029b680 <current>
ffffffffc0204046:	8fd9                	or	a5,a5,a4
ffffffffc0204048:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc020404c:	03050593          	addi	a1,a0,48
ffffffffc0204050:	03068513          	addi	a0,a3,48
ffffffffc0204054:	136010ef          	jal	ffffffffc020518a <switch_to>
    if (flag)
ffffffffc0204058:	6602                	ld	a2,0(sp)
ffffffffc020405a:	e601                	bnez	a2,ffffffffc0204062 <proc_run+0x48>
}
ffffffffc020405c:	60e2                	ld	ra,24(sp)
ffffffffc020405e:	6105                	addi	sp,sp,32
ffffffffc0204060:	8082                	ret
ffffffffc0204062:	60e2                	ld	ra,24(sp)
ffffffffc0204064:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204066:	899fc06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc020406a:	8082                	ret
ffffffffc020406c:	e42a                	sd	a0,8(sp)
ffffffffc020406e:	e036                	sd	a3,0(sp)
        intr_disable();
ffffffffc0204070:	895fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0204074:	6522                	ld	a0,8(sp)
ffffffffc0204076:	6682                	ld	a3,0(sp)
ffffffffc0204078:	4605                	li	a2,1
ffffffffc020407a:	bf6d                	j	ffffffffc0204034 <proc_run+0x1a>

ffffffffc020407c <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc020407c:	00097717          	auipc	a4,0x97
ffffffffc0204080:	5fc72703          	lw	a4,1532(a4) # ffffffffc029b678 <nr_process>
ffffffffc0204084:	6785                	lui	a5,0x1
ffffffffc0204086:	38f75363          	bge	a4,a5,ffffffffc020440c <do_fork+0x390>
{
ffffffffc020408a:	711d                	addi	sp,sp,-96
ffffffffc020408c:	e8a2                	sd	s0,80(sp)
ffffffffc020408e:	e4a6                	sd	s1,72(sp)
ffffffffc0204090:	e0ca                	sd	s2,64(sp)
ffffffffc0204092:	e06a                	sd	s10,0(sp)
ffffffffc0204094:	ec86                	sd	ra,88(sp)
ffffffffc0204096:	892e                	mv	s2,a1
ffffffffc0204098:	84b2                	mv	s1,a2
ffffffffc020409a:	8d2a                	mv	s10,a0
    if ((proc = alloc_proc()) == NULL) {
ffffffffc020409c:	e11ff0ef          	jal	ffffffffc0203eac <alloc_proc>
ffffffffc02040a0:	842a                	mv	s0,a0
ffffffffc02040a2:	30050063          	beqz	a0,ffffffffc02043a2 <do_fork+0x326>
    proc->parent = current;
ffffffffc02040a6:	f05a                	sd	s6,32(sp)
ffffffffc02040a8:	00097b17          	auipc	s6,0x97
ffffffffc02040ac:	5d8b0b13          	addi	s6,s6,1496 # ffffffffc029b680 <current>
ffffffffc02040b0:	000b3783          	ld	a5,0(s6)
    assert(current->wait_state == 0);
ffffffffc02040b4:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_softint_out_size-0x7ac4>
    proc->parent = current;
ffffffffc02040b8:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc02040ba:	36071763          	bnez	a4,ffffffffc0204428 <do_fork+0x3ac>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02040be:	4509                	li	a0,2
ffffffffc02040c0:	e53fd0ef          	jal	ffffffffc0201f12 <alloc_pages>
    if (page != NULL)
ffffffffc02040c4:	2c050b63          	beqz	a0,ffffffffc020439a <do_fork+0x31e>
ffffffffc02040c8:	fc4e                	sd	s3,56(sp)
    return page - pages + nbase;
ffffffffc02040ca:	00097997          	auipc	s3,0x97
ffffffffc02040ce:	5a698993          	addi	s3,s3,1446 # ffffffffc029b670 <pages>
ffffffffc02040d2:	0009b783          	ld	a5,0(s3)
ffffffffc02040d6:	f852                	sd	s4,48(sp)
ffffffffc02040d8:	00004a17          	auipc	s4,0x4
ffffffffc02040dc:	9e8a0a13          	addi	s4,s4,-1560 # ffffffffc0207ac0 <nbase>
ffffffffc02040e0:	e466                	sd	s9,8(sp)
ffffffffc02040e2:	000a3c83          	ld	s9,0(s4)
ffffffffc02040e6:	40f506b3          	sub	a3,a0,a5
ffffffffc02040ea:	f456                	sd	s5,40(sp)
    return KADDR(page2pa(page));
ffffffffc02040ec:	00097a97          	auipc	s5,0x97
ffffffffc02040f0:	57ca8a93          	addi	s5,s5,1404 # ffffffffc029b668 <npage>
ffffffffc02040f4:	e862                	sd	s8,16(sp)
    return page - pages + nbase;
ffffffffc02040f6:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02040f8:	5c7d                	li	s8,-1
ffffffffc02040fa:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc02040fe:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc0204100:	00cc5c13          	srli	s8,s8,0xc
ffffffffc0204104:	0186f733          	and	a4,a3,s8
ffffffffc0204108:	ec5e                	sd	s7,24(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc020410a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020410c:	36f77163          	bgeu	a4,a5,ffffffffc020446e <do_fork+0x3f2>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204110:	000b3703          	ld	a4,0(s6)
ffffffffc0204114:	00097b17          	auipc	s6,0x97
ffffffffc0204118:	54cb0b13          	addi	s6,s6,1356 # ffffffffc029b660 <va_pa_offset>
ffffffffc020411c:	000b3783          	ld	a5,0(s6)
ffffffffc0204120:	02873b83          	ld	s7,40(a4)
ffffffffc0204124:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204126:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0204128:	2c0b8c63          	beqz	s7,ffffffffc0204400 <do_fork+0x384>
    if (clone_flags & CLONE_VM)
ffffffffc020412c:	100d7793          	andi	a5,s10,256
ffffffffc0204130:	18078b63          	beqz	a5,ffffffffc02042c6 <do_fork+0x24a>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc0204134:	030ba703          	lw	a4,48(s7)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204138:	018bb783          	ld	a5,24(s7)
ffffffffc020413c:	c02006b7          	lui	a3,0xc0200
ffffffffc0204140:	2705                	addiw	a4,a4,1
ffffffffc0204142:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc0204146:	03743423          	sd	s7,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc020414a:	30d7e563          	bltu	a5,a3,ffffffffc0204454 <do_fork+0x3d8>
ffffffffc020414e:	000b3703          	ld	a4,0(s6)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204152:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204154:	8f99                	sub	a5,a5,a4
ffffffffc0204156:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204158:	6789                	lui	a5,0x2
ffffffffc020415a:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x6cd0>
ffffffffc020415e:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204160:	8626                	mv	a2,s1
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204162:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0204164:	87b6                	mv	a5,a3
ffffffffc0204166:	12048713          	addi	a4,s1,288
ffffffffc020416a:	6a0c                	ld	a1,16(a2)
ffffffffc020416c:	00063803          	ld	a6,0(a2)
ffffffffc0204170:	6608                	ld	a0,8(a2)
ffffffffc0204172:	eb8c                	sd	a1,16(a5)
ffffffffc0204174:	0107b023          	sd	a6,0(a5)
ffffffffc0204178:	e788                	sd	a0,8(a5)
ffffffffc020417a:	6e0c                	ld	a1,24(a2)
ffffffffc020417c:	02060613          	addi	a2,a2,32
ffffffffc0204180:	02078793          	addi	a5,a5,32
ffffffffc0204184:	feb7bc23          	sd	a1,-8(a5)
ffffffffc0204188:	fee611e3          	bne	a2,a4,ffffffffc020416a <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc020418c:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204190:	20090b63          	beqz	s2,ffffffffc02043a6 <do_fork+0x32a>
ffffffffc0204194:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204198:	00000797          	auipc	a5,0x0
ffffffffc020419c:	d8078793          	addi	a5,a5,-640 # ffffffffc0203f18 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02041a0:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02041a2:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02041a4:	100027f3          	csrr	a5,sstatus
ffffffffc02041a8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02041aa:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02041ac:	20079c63          	bnez	a5,ffffffffc02043c4 <do_fork+0x348>
    if (++last_pid >= MAX_PID)
ffffffffc02041b0:	00093517          	auipc	a0,0x93
ffffffffc02041b4:	03c52503          	lw	a0,60(a0) # ffffffffc02971ec <last_pid.1>
ffffffffc02041b8:	6789                	lui	a5,0x2
ffffffffc02041ba:	2505                	addiw	a0,a0,1
ffffffffc02041bc:	00093717          	auipc	a4,0x93
ffffffffc02041c0:	02a72823          	sw	a0,48(a4) # ffffffffc02971ec <last_pid.1>
ffffffffc02041c4:	20f55f63          	bge	a0,a5,ffffffffc02043e2 <do_fork+0x366>
    if (last_pid >= next_safe)
ffffffffc02041c8:	00093797          	auipc	a5,0x93
ffffffffc02041cc:	0207a783          	lw	a5,32(a5) # ffffffffc02971e8 <next_safe.0>
ffffffffc02041d0:	00097497          	auipc	s1,0x97
ffffffffc02041d4:	43848493          	addi	s1,s1,1080 # ffffffffc029b608 <proc_list>
ffffffffc02041d8:	06f54563          	blt	a0,a5,ffffffffc0204242 <do_fork+0x1c6>
ffffffffc02041dc:	00097497          	auipc	s1,0x97
ffffffffc02041e0:	42c48493          	addi	s1,s1,1068 # ffffffffc029b608 <proc_list>
ffffffffc02041e4:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc02041e8:	6789                	lui	a5,0x2
ffffffffc02041ea:	00093717          	auipc	a4,0x93
ffffffffc02041ee:	fef72f23          	sw	a5,-2(a4) # ffffffffc02971e8 <next_safe.0>
ffffffffc02041f2:	86aa                	mv	a3,a0
ffffffffc02041f4:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc02041f6:	04988063          	beq	a7,s1,ffffffffc0204236 <do_fork+0x1ba>
ffffffffc02041fa:	882e                	mv	a6,a1
ffffffffc02041fc:	87c6                	mv	a5,a7
ffffffffc02041fe:	6609                	lui	a2,0x2
ffffffffc0204200:	a811                	j	ffffffffc0204214 <do_fork+0x198>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204202:	00e6d663          	bge	a3,a4,ffffffffc020420e <do_fork+0x192>
ffffffffc0204206:	00c75463          	bge	a4,a2,ffffffffc020420e <do_fork+0x192>
                next_safe = proc->pid;
ffffffffc020420a:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020420c:	4805                	li	a6,1
ffffffffc020420e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204210:	00978d63          	beq	a5,s1,ffffffffc020422a <do_fork+0x1ae>
            if (proc->pid == last_pid)
ffffffffc0204214:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x6c74>
ffffffffc0204218:	fed715e3          	bne	a4,a3,ffffffffc0204202 <do_fork+0x186>
                if (++last_pid >= next_safe)
ffffffffc020421c:	2685                	addiw	a3,a3,1
ffffffffc020421e:	1cc6db63          	bge	a3,a2,ffffffffc02043f4 <do_fork+0x378>
ffffffffc0204222:	679c                	ld	a5,8(a5)
ffffffffc0204224:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204226:	fe9797e3          	bne	a5,s1,ffffffffc0204214 <do_fork+0x198>
ffffffffc020422a:	00080663          	beqz	a6,ffffffffc0204236 <do_fork+0x1ba>
ffffffffc020422e:	00093797          	auipc	a5,0x93
ffffffffc0204232:	fac7ad23          	sw	a2,-70(a5) # ffffffffc02971e8 <next_safe.0>
ffffffffc0204236:	c591                	beqz	a1,ffffffffc0204242 <do_fork+0x1c6>
ffffffffc0204238:	00093797          	auipc	a5,0x93
ffffffffc020423c:	fad7aa23          	sw	a3,-76(a5) # ffffffffc02971ec <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204240:	8536                	mv	a0,a3
        proc->pid = get_pid();
ffffffffc0204242:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0204244:	45a9                	li	a1,10
ffffffffc0204246:	1aa010ef          	jal	ffffffffc02053f0 <hash32>
ffffffffc020424a:	02051793          	slli	a5,a0,0x20
ffffffffc020424e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204252:	00093797          	auipc	a5,0x93
ffffffffc0204256:	3b678793          	addi	a5,a5,950 # ffffffffc0297608 <hash_list>
ffffffffc020425a:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc020425c:	6518                	ld	a4,8(a0)
ffffffffc020425e:	0d840793          	addi	a5,s0,216
ffffffffc0204262:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc0204264:	e31c                	sd	a5,0(a4)
ffffffffc0204266:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc0204268:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020426a:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020426e:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc0204270:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc0204272:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc0204274:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204278:	7b74                	ld	a3,240(a4)
ffffffffc020427a:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc020427c:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc020427e:	e464                	sd	s1,200(s0)
ffffffffc0204280:	10d43023          	sd	a3,256(s0)
ffffffffc0204284:	c299                	beqz	a3,ffffffffc020428a <do_fork+0x20e>
        proc->optr->yptr = proc;
ffffffffc0204286:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc0204288:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc020428a:	00097797          	auipc	a5,0x97
ffffffffc020428e:	3ee7a783          	lw	a5,1006(a5) # ffffffffc029b678 <nr_process>
    proc->parent->cptr = proc;
ffffffffc0204292:	fb60                	sd	s0,240(a4)
    nr_process++;
ffffffffc0204294:	2785                	addiw	a5,a5,1
ffffffffc0204296:	00097717          	auipc	a4,0x97
ffffffffc020429a:	3ef72123          	sw	a5,994(a4) # ffffffffc029b678 <nr_process>
    if (flag)
ffffffffc020429e:	14091863          	bnez	s2,ffffffffc02043ee <do_fork+0x372>
    wakeup_proc(proc);
ffffffffc02042a2:	8522                	mv	a0,s0
ffffffffc02042a4:	751000ef          	jal	ffffffffc02051f4 <wakeup_proc>
    ret = proc->pid;
ffffffffc02042a8:	4048                	lw	a0,4(s0)
ffffffffc02042aa:	79e2                	ld	s3,56(sp)
ffffffffc02042ac:	7a42                	ld	s4,48(sp)
ffffffffc02042ae:	7aa2                	ld	s5,40(sp)
ffffffffc02042b0:	7b02                	ld	s6,32(sp)
ffffffffc02042b2:	6be2                	ld	s7,24(sp)
ffffffffc02042b4:	6c42                	ld	s8,16(sp)
ffffffffc02042b6:	6ca2                	ld	s9,8(sp)
}
ffffffffc02042b8:	60e6                	ld	ra,88(sp)
ffffffffc02042ba:	6446                	ld	s0,80(sp)
ffffffffc02042bc:	64a6                	ld	s1,72(sp)
ffffffffc02042be:	6906                	ld	s2,64(sp)
ffffffffc02042c0:	6d02                	ld	s10,0(sp)
ffffffffc02042c2:	6125                	addi	sp,sp,96
ffffffffc02042c4:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc02042c6:	caeff0ef          	jal	ffffffffc0203774 <mm_create>
ffffffffc02042ca:	8d2a                	mv	s10,a0
ffffffffc02042cc:	c949                	beqz	a0,ffffffffc020435e <do_fork+0x2e2>
    if ((page = alloc_page()) == NULL)
ffffffffc02042ce:	4505                	li	a0,1
ffffffffc02042d0:	c43fd0ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc02042d4:	c151                	beqz	a0,ffffffffc0204358 <do_fork+0x2dc>
    return page - pages + nbase;
ffffffffc02042d6:	0009b703          	ld	a4,0(s3)
    return KADDR(page2pa(page));
ffffffffc02042da:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc02042de:	40e506b3          	sub	a3,a0,a4
ffffffffc02042e2:	8699                	srai	a3,a3,0x6
ffffffffc02042e4:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc02042e6:	0186fc33          	and	s8,a3,s8
    return page2ppn(page) << PGSHIFT;
ffffffffc02042ea:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02042ec:	1afc7963          	bgeu	s8,a5,ffffffffc020449e <do_fork+0x422>
ffffffffc02042f0:	000b3783          	ld	a5,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02042f4:	00097597          	auipc	a1,0x97
ffffffffc02042f8:	3645b583          	ld	a1,868(a1) # ffffffffc029b658 <boot_pgdir_va>
ffffffffc02042fc:	6605                	lui	a2,0x1
ffffffffc02042fe:	00f68c33          	add	s8,a3,a5
ffffffffc0204302:	8562                	mv	a0,s8
ffffffffc0204304:	594010ef          	jal	ffffffffc0205898 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204308:	038b8c93          	addi	s9,s7,56
    mm->pgdir = pgdir;
ffffffffc020430c:	018d3c23          	sd	s8,24(s10) # fffffffffff80018 <end+0x3fce4980>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204310:	4c05                	li	s8,1
ffffffffc0204312:	418cb7af          	amoor.d	a5,s8,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204316:	03f79713          	slli	a4,a5,0x3f
ffffffffc020431a:	03f75793          	srli	a5,a4,0x3f
ffffffffc020431e:	cb91                	beqz	a5,ffffffffc0204332 <do_fork+0x2b6>
    {
        schedule();
ffffffffc0204320:	769000ef          	jal	ffffffffc0205288 <schedule>
ffffffffc0204324:	418cb7af          	amoor.d	a5,s8,(s9)
    while (!try_lock(lock))
ffffffffc0204328:	03f79713          	slli	a4,a5,0x3f
ffffffffc020432c:	03f75793          	srli	a5,a4,0x3f
ffffffffc0204330:	fbe5                	bnez	a5,ffffffffc0204320 <do_fork+0x2a4>
        ret = dup_mmap(mm, oldmm);
ffffffffc0204332:	85de                	mv	a1,s7
ffffffffc0204334:	856a                	mv	a0,s10
ffffffffc0204336:	e9aff0ef          	jal	ffffffffc02039d0 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020433a:	57f9                	li	a5,-2
ffffffffc020433c:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc0204340:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc0204342:	16078a63          	beqz	a5,ffffffffc02044b6 <do_fork+0x43a>
    if ((mm = mm_create()) == NULL)
ffffffffc0204346:	8bea                	mv	s7,s10
    if (ret != 0)
ffffffffc0204348:	de0506e3          	beqz	a0,ffffffffc0204134 <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc020434c:	856a                	mv	a0,s10
ffffffffc020434e:	f1aff0ef          	jal	ffffffffc0203a68 <exit_mmap>
    put_pgdir(mm);
ffffffffc0204352:	856a                	mv	a0,s10
ffffffffc0204354:	c51ff0ef          	jal	ffffffffc0203fa4 <put_pgdir>
    mm_destroy(mm);
ffffffffc0204358:	856a                	mv	a0,s10
ffffffffc020435a:	d58ff0ef          	jal	ffffffffc02038b2 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020435e:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204360:	c02007b7          	lui	a5,0xc0200
ffffffffc0204364:	12f6e163          	bltu	a3,a5,ffffffffc0204486 <do_fork+0x40a>
ffffffffc0204368:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage)
ffffffffc020436c:	000ab703          	ld	a4,0(s5)
    return pa2page(PADDR(kva));
ffffffffc0204370:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204374:	83b1                	srli	a5,a5,0xc
ffffffffc0204376:	08e7fd63          	bgeu	a5,a4,ffffffffc0204410 <do_fork+0x394>
    return &pages[PPN(pa) - nbase];
ffffffffc020437a:	000a3703          	ld	a4,0(s4)
ffffffffc020437e:	0009b503          	ld	a0,0(s3)
ffffffffc0204382:	4589                	li	a1,2
ffffffffc0204384:	8f99                	sub	a5,a5,a4
ffffffffc0204386:	079a                	slli	a5,a5,0x6
ffffffffc0204388:	953e                	add	a0,a0,a5
ffffffffc020438a:	bc3fd0ef          	jal	ffffffffc0201f4c <free_pages>
}
ffffffffc020438e:	79e2                	ld	s3,56(sp)
ffffffffc0204390:	7a42                	ld	s4,48(sp)
ffffffffc0204392:	7aa2                	ld	s5,40(sp)
ffffffffc0204394:	6be2                	ld	s7,24(sp)
ffffffffc0204396:	6c42                	ld	s8,16(sp)
ffffffffc0204398:	6ca2                	ld	s9,8(sp)
    kfree(proc);
ffffffffc020439a:	8522                	mv	a0,s0
ffffffffc020439c:	a5bfd0ef          	jal	ffffffffc0201df6 <kfree>
ffffffffc02043a0:	7b02                	ld	s6,32(sp)
    ret = -E_NO_MEM;
ffffffffc02043a2:	5571                	li	a0,-4
    return ret;
ffffffffc02043a4:	bf11                	j	ffffffffc02042b8 <do_fork+0x23c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02043a6:	8936                	mv	s2,a3
ffffffffc02043a8:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02043ac:	00000797          	auipc	a5,0x0
ffffffffc02043b0:	b6c78793          	addi	a5,a5,-1172 # ffffffffc0203f18 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02043b4:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02043b6:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043b8:	100027f3          	csrr	a5,sstatus
ffffffffc02043bc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02043be:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02043c0:	de0788e3          	beqz	a5,ffffffffc02041b0 <do_fork+0x134>
        intr_disable();
ffffffffc02043c4:	d40fc0ef          	jal	ffffffffc0200904 <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc02043c8:	00093517          	auipc	a0,0x93
ffffffffc02043cc:	e2452503          	lw	a0,-476(a0) # ffffffffc02971ec <last_pid.1>
ffffffffc02043d0:	6789                	lui	a5,0x2
        return 1;
ffffffffc02043d2:	4905                	li	s2,1
ffffffffc02043d4:	2505                	addiw	a0,a0,1
ffffffffc02043d6:	00093717          	auipc	a4,0x93
ffffffffc02043da:	e0a72b23          	sw	a0,-490(a4) # ffffffffc02971ec <last_pid.1>
ffffffffc02043de:	def545e3          	blt	a0,a5,ffffffffc02041c8 <do_fork+0x14c>
        last_pid = 1;
ffffffffc02043e2:	4505                	li	a0,1
ffffffffc02043e4:	00093797          	auipc	a5,0x93
ffffffffc02043e8:	e0a7a423          	sw	a0,-504(a5) # ffffffffc02971ec <last_pid.1>
        goto inside;
ffffffffc02043ec:	bbc5                	j	ffffffffc02041dc <do_fork+0x160>
        intr_enable();
ffffffffc02043ee:	d10fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02043f2:	bd45                	j	ffffffffc02042a2 <do_fork+0x226>
                    if (last_pid >= MAX_PID)
ffffffffc02043f4:	6789                	lui	a5,0x2
ffffffffc02043f6:	00f6c363          	blt	a3,a5,ffffffffc02043fc <do_fork+0x380>
                        last_pid = 1;
ffffffffc02043fa:	4685                	li	a3,1
                    goto repeat;
ffffffffc02043fc:	4585                	li	a1,1
ffffffffc02043fe:	bbe5                	j	ffffffffc02041f6 <do_fork+0x17a>
        proc->pgdir = boot_pgdir_pa;
ffffffffc0204400:	00097797          	auipc	a5,0x97
ffffffffc0204404:	2507b783          	ld	a5,592(a5) # ffffffffc029b650 <boot_pgdir_pa>
ffffffffc0204408:	f45c                	sd	a5,168(s0)
        return 0;
ffffffffc020440a:	b3b9                	j	ffffffffc0204158 <do_fork+0xdc>
    int ret = -E_NO_FREE_PROC;
ffffffffc020440c:	556d                	li	a0,-5
}
ffffffffc020440e:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0204410:	00002617          	auipc	a2,0x2
ffffffffc0204414:	3a060613          	addi	a2,a2,928 # ffffffffc02067b0 <etext+0xf00>
ffffffffc0204418:	06900593          	li	a1,105
ffffffffc020441c:	00002517          	auipc	a0,0x2
ffffffffc0204420:	2ec50513          	addi	a0,a0,748 # ffffffffc0206708 <etext+0xe58>
ffffffffc0204424:	822fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(current->wait_state == 0);
ffffffffc0204428:	00003697          	auipc	a3,0x3
ffffffffc020442c:	d0868693          	addi	a3,a3,-760 # ffffffffc0207130 <etext+0x1880>
ffffffffc0204430:	00002617          	auipc	a2,0x2
ffffffffc0204434:	f0060613          	addi	a2,a2,-256 # ffffffffc0206330 <etext+0xa80>
ffffffffc0204438:	1dc00593          	li	a1,476
ffffffffc020443c:	00003517          	auipc	a0,0x3
ffffffffc0204440:	cdc50513          	addi	a0,a0,-804 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204444:	fc4e                	sd	s3,56(sp)
ffffffffc0204446:	f852                	sd	s4,48(sp)
ffffffffc0204448:	f456                	sd	s5,40(sp)
ffffffffc020444a:	ec5e                	sd	s7,24(sp)
ffffffffc020444c:	e862                	sd	s8,16(sp)
ffffffffc020444e:	e466                	sd	s9,8(sp)
ffffffffc0204450:	ff7fb0ef          	jal	ffffffffc0200446 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc0204454:	86be                	mv	a3,a5
ffffffffc0204456:	00002617          	auipc	a2,0x2
ffffffffc020445a:	33260613          	addi	a2,a2,818 # ffffffffc0206788 <etext+0xed8>
ffffffffc020445e:	18a00593          	li	a1,394
ffffffffc0204462:	00003517          	auipc	a0,0x3
ffffffffc0204466:	cb650513          	addi	a0,a0,-842 # ffffffffc0207118 <etext+0x1868>
ffffffffc020446a:	fddfb0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc020446e:	00002617          	auipc	a2,0x2
ffffffffc0204472:	27260613          	addi	a2,a2,626 # ffffffffc02066e0 <etext+0xe30>
ffffffffc0204476:	07100593          	li	a1,113
ffffffffc020447a:	00002517          	auipc	a0,0x2
ffffffffc020447e:	28e50513          	addi	a0,a0,654 # ffffffffc0206708 <etext+0xe58>
ffffffffc0204482:	fc5fb0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0204486:	00002617          	auipc	a2,0x2
ffffffffc020448a:	30260613          	addi	a2,a2,770 # ffffffffc0206788 <etext+0xed8>
ffffffffc020448e:	07700593          	li	a1,119
ffffffffc0204492:	00002517          	auipc	a0,0x2
ffffffffc0204496:	27650513          	addi	a0,a0,630 # ffffffffc0206708 <etext+0xe58>
ffffffffc020449a:	fadfb0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc020449e:	00002617          	auipc	a2,0x2
ffffffffc02044a2:	24260613          	addi	a2,a2,578 # ffffffffc02066e0 <etext+0xe30>
ffffffffc02044a6:	07100593          	li	a1,113
ffffffffc02044aa:	00002517          	auipc	a0,0x2
ffffffffc02044ae:	25e50513          	addi	a0,a0,606 # ffffffffc0206708 <etext+0xe58>
ffffffffc02044b2:	f95fb0ef          	jal	ffffffffc0200446 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc02044b6:	00003617          	auipc	a2,0x3
ffffffffc02044ba:	c9a60613          	addi	a2,a2,-870 # ffffffffc0207150 <etext+0x18a0>
ffffffffc02044be:	03f00593          	li	a1,63
ffffffffc02044c2:	00003517          	auipc	a0,0x3
ffffffffc02044c6:	c9e50513          	addi	a0,a0,-866 # ffffffffc0207160 <etext+0x18b0>
ffffffffc02044ca:	f7dfb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02044ce <kernel_thread>:
{
ffffffffc02044ce:	7129                	addi	sp,sp,-320
ffffffffc02044d0:	fa22                	sd	s0,304(sp)
ffffffffc02044d2:	f626                	sd	s1,296(sp)
ffffffffc02044d4:	f24a                	sd	s2,288(sp)
ffffffffc02044d6:	842a                	mv	s0,a0
ffffffffc02044d8:	84ae                	mv	s1,a1
ffffffffc02044da:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02044dc:	850a                	mv	a0,sp
ffffffffc02044de:	12000613          	li	a2,288
ffffffffc02044e2:	4581                	li	a1,0
{
ffffffffc02044e4:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02044e6:	3a0010ef          	jal	ffffffffc0205886 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02044ea:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02044ec:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02044ee:	100027f3          	csrr	a5,sstatus
ffffffffc02044f2:	edd7f793          	andi	a5,a5,-291
ffffffffc02044f6:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02044fa:	860a                	mv	a2,sp
ffffffffc02044fc:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204500:	00000717          	auipc	a4,0x0
ffffffffc0204504:	9a470713          	addi	a4,a4,-1628 # ffffffffc0203ea4 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204508:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020450a:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020450c:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020450e:	b6fff0ef          	jal	ffffffffc020407c <do_fork>
}
ffffffffc0204512:	70f2                	ld	ra,312(sp)
ffffffffc0204514:	7452                	ld	s0,304(sp)
ffffffffc0204516:	74b2                	ld	s1,296(sp)
ffffffffc0204518:	7912                	ld	s2,288(sp)
ffffffffc020451a:	6131                	addi	sp,sp,320
ffffffffc020451c:	8082                	ret

ffffffffc020451e <do_exit>:
{
ffffffffc020451e:	7179                	addi	sp,sp,-48
ffffffffc0204520:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204522:	00097417          	auipc	s0,0x97
ffffffffc0204526:	15e40413          	addi	s0,s0,350 # ffffffffc029b680 <current>
ffffffffc020452a:	601c                	ld	a5,0(s0)
ffffffffc020452c:	00097717          	auipc	a4,0x97
ffffffffc0204530:	16473703          	ld	a4,356(a4) # ffffffffc029b690 <idleproc>
{
ffffffffc0204534:	f406                	sd	ra,40(sp)
ffffffffc0204536:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc0204538:	0ce78b63          	beq	a5,a4,ffffffffc020460e <do_exit+0xf0>
    if (current == initproc)
ffffffffc020453c:	00097497          	auipc	s1,0x97
ffffffffc0204540:	14c48493          	addi	s1,s1,332 # ffffffffc029b688 <initproc>
ffffffffc0204544:	6098                	ld	a4,0(s1)
ffffffffc0204546:	e84a                	sd	s2,16(sp)
ffffffffc0204548:	0ee78a63          	beq	a5,a4,ffffffffc020463c <do_exit+0x11e>
ffffffffc020454c:	892a                	mv	s2,a0
    struct mm_struct *mm = current->mm;
ffffffffc020454e:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc0204550:	c115                	beqz	a0,ffffffffc0204574 <do_exit+0x56>
ffffffffc0204552:	00097797          	auipc	a5,0x97
ffffffffc0204556:	0fe7b783          	ld	a5,254(a5) # ffffffffc029b650 <boot_pgdir_pa>
ffffffffc020455a:	577d                	li	a4,-1
ffffffffc020455c:	177e                	slli	a4,a4,0x3f
ffffffffc020455e:	83b1                	srli	a5,a5,0xc
ffffffffc0204560:	8fd9                	or	a5,a5,a4
ffffffffc0204562:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0204566:	591c                	lw	a5,48(a0)
ffffffffc0204568:	37fd                	addiw	a5,a5,-1
ffffffffc020456a:	d91c                	sw	a5,48(a0)
        if (mm_count_dec(mm) == 0)
ffffffffc020456c:	cfd5                	beqz	a5,ffffffffc0204628 <do_exit+0x10a>
        current->mm = NULL;
ffffffffc020456e:	601c                	ld	a5,0(s0)
ffffffffc0204570:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204574:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc0204576:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020457a:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020457c:	100027f3          	csrr	a5,sstatus
ffffffffc0204580:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204582:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204584:	ebe1                	bnez	a5,ffffffffc0204654 <do_exit+0x136>
        proc = current->parent;
ffffffffc0204586:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204588:	800007b7          	lui	a5,0x80000
ffffffffc020458c:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
        proc = current->parent;
ffffffffc020458e:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204590:	0ec52703          	lw	a4,236(a0)
ffffffffc0204594:	0cf70463          	beq	a4,a5,ffffffffc020465c <do_exit+0x13e>
        while (current->cptr != NULL)
ffffffffc0204598:	6018                	ld	a4,0(s0)
                if (initproc->wait_state == WT_CHILD)
ffffffffc020459a:	800005b7          	lui	a1,0x80000
ffffffffc020459e:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
        while (current->cptr != NULL)
ffffffffc02045a0:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045a2:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc02045a4:	e789                	bnez	a5,ffffffffc02045ae <do_exit+0x90>
ffffffffc02045a6:	a83d                	j	ffffffffc02045e4 <do_exit+0xc6>
ffffffffc02045a8:	6018                	ld	a4,0(s0)
ffffffffc02045aa:	7b7c                	ld	a5,240(a4)
ffffffffc02045ac:	cf85                	beqz	a5,ffffffffc02045e4 <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc02045ae:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02045b2:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc02045b4:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc02045b6:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc02045ba:	7978                	ld	a4,240(a0)
ffffffffc02045bc:	10e7b023          	sd	a4,256(a5)
ffffffffc02045c0:	c311                	beqz	a4,ffffffffc02045c4 <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc02045c2:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045c4:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02045c6:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02045c8:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc02045ca:	fcc71fe3          	bne	a4,a2,ffffffffc02045a8 <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc02045ce:	0ec52783          	lw	a5,236(a0)
ffffffffc02045d2:	fcb79be3          	bne	a5,a1,ffffffffc02045a8 <do_exit+0x8a>
                    wakeup_proc(initproc);
ffffffffc02045d6:	41f000ef          	jal	ffffffffc02051f4 <wakeup_proc>
ffffffffc02045da:	800005b7          	lui	a1,0x80000
ffffffffc02045de:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
ffffffffc02045e0:	460d                	li	a2,3
ffffffffc02045e2:	b7d9                	j	ffffffffc02045a8 <do_exit+0x8a>
    if (flag)
ffffffffc02045e4:	02091263          	bnez	s2,ffffffffc0204608 <do_exit+0xea>
    schedule();
ffffffffc02045e8:	4a1000ef          	jal	ffffffffc0205288 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02045ec:	601c                	ld	a5,0(s0)
ffffffffc02045ee:	00003617          	auipc	a2,0x3
ffffffffc02045f2:	baa60613          	addi	a2,a2,-1110 # ffffffffc0207198 <etext+0x18e8>
ffffffffc02045f6:	24100593          	li	a1,577
ffffffffc02045fa:	43d4                	lw	a3,4(a5)
ffffffffc02045fc:	00003517          	auipc	a0,0x3
ffffffffc0204600:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204604:	e43fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_enable();
ffffffffc0204608:	af6fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020460c:	bff1                	j	ffffffffc02045e8 <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc020460e:	00003617          	auipc	a2,0x3
ffffffffc0204612:	b6a60613          	addi	a2,a2,-1174 # ffffffffc0207178 <etext+0x18c8>
ffffffffc0204616:	20d00593          	li	a1,525
ffffffffc020461a:	00003517          	auipc	a0,0x3
ffffffffc020461e:	afe50513          	addi	a0,a0,-1282 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204622:	e84a                	sd	s2,16(sp)
ffffffffc0204624:	e23fb0ef          	jal	ffffffffc0200446 <__panic>
            exit_mmap(mm);
ffffffffc0204628:	e42a                	sd	a0,8(sp)
ffffffffc020462a:	c3eff0ef          	jal	ffffffffc0203a68 <exit_mmap>
            put_pgdir(mm);
ffffffffc020462e:	6522                	ld	a0,8(sp)
ffffffffc0204630:	975ff0ef          	jal	ffffffffc0203fa4 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204634:	6522                	ld	a0,8(sp)
ffffffffc0204636:	a7cff0ef          	jal	ffffffffc02038b2 <mm_destroy>
ffffffffc020463a:	bf15                	j	ffffffffc020456e <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc020463c:	00003617          	auipc	a2,0x3
ffffffffc0204640:	b4c60613          	addi	a2,a2,-1204 # ffffffffc0207188 <etext+0x18d8>
ffffffffc0204644:	21100593          	li	a1,529
ffffffffc0204648:	00003517          	auipc	a0,0x3
ffffffffc020464c:	ad050513          	addi	a0,a0,-1328 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204650:	df7fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_disable();
ffffffffc0204654:	ab0fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0204658:	4905                	li	s2,1
ffffffffc020465a:	b735                	j	ffffffffc0204586 <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc020465c:	399000ef          	jal	ffffffffc02051f4 <wakeup_proc>
ffffffffc0204660:	bf25                	j	ffffffffc0204598 <do_exit+0x7a>

ffffffffc0204662 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc0204662:	7179                	addi	sp,sp,-48
ffffffffc0204664:	ec26                	sd	s1,24(sp)
ffffffffc0204666:	e84a                	sd	s2,16(sp)
ffffffffc0204668:	e44e                	sd	s3,8(sp)
ffffffffc020466a:	f406                	sd	ra,40(sp)
ffffffffc020466c:	f022                	sd	s0,32(sp)
ffffffffc020466e:	84aa                	mv	s1,a0
ffffffffc0204670:	892e                	mv	s2,a1
ffffffffc0204672:	00097997          	auipc	s3,0x97
ffffffffc0204676:	00e98993          	addi	s3,s3,14 # ffffffffc029b680 <current>
    if (pid != 0)
ffffffffc020467a:	cd19                	beqz	a0,ffffffffc0204698 <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc020467c:	6789                	lui	a5,0x2
ffffffffc020467e:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bb2>
ffffffffc0204680:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204684:	12e7f563          	bgeu	a5,a4,ffffffffc02047ae <do_wait.part.0+0x14c>
}
ffffffffc0204688:	70a2                	ld	ra,40(sp)
ffffffffc020468a:	7402                	ld	s0,32(sp)
ffffffffc020468c:	64e2                	ld	s1,24(sp)
ffffffffc020468e:	6942                	ld	s2,16(sp)
ffffffffc0204690:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc0204692:	5579                	li	a0,-2
}
ffffffffc0204694:	6145                	addi	sp,sp,48
ffffffffc0204696:	8082                	ret
        proc = current->cptr;
ffffffffc0204698:	0009b703          	ld	a4,0(s3)
ffffffffc020469c:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc020469e:	d46d                	beqz	s0,ffffffffc0204688 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02046a0:	468d                	li	a3,3
ffffffffc02046a2:	a021                	j	ffffffffc02046aa <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc02046a4:	10043403          	ld	s0,256(s0)
ffffffffc02046a8:	c075                	beqz	s0,ffffffffc020478c <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02046aa:	401c                	lw	a5,0(s0)
ffffffffc02046ac:	fed79ce3          	bne	a5,a3,ffffffffc02046a4 <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc02046b0:	00097797          	auipc	a5,0x97
ffffffffc02046b4:	fe07b783          	ld	a5,-32(a5) # ffffffffc029b690 <idleproc>
ffffffffc02046b8:	14878263          	beq	a5,s0,ffffffffc02047fc <do_wait.part.0+0x19a>
ffffffffc02046bc:	00097797          	auipc	a5,0x97
ffffffffc02046c0:	fcc7b783          	ld	a5,-52(a5) # ffffffffc029b688 <initproc>
ffffffffc02046c4:	12f40c63          	beq	s0,a5,ffffffffc02047fc <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc02046c8:	00090663          	beqz	s2,ffffffffc02046d4 <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc02046cc:	0e842783          	lw	a5,232(s0)
ffffffffc02046d0:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02046d4:	100027f3          	csrr	a5,sstatus
ffffffffc02046d8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02046da:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02046dc:	10079963          	bnez	a5,ffffffffc02047ee <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02046e0:	6c74                	ld	a3,216(s0)
ffffffffc02046e2:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc02046e4:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc02046e8:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02046ea:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02046ec:	6474                	ld	a3,200(s0)
ffffffffc02046ee:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc02046f0:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc02046f2:	e314                	sd	a3,0(a4)
ffffffffc02046f4:	c789                	beqz	a5,ffffffffc02046fe <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc02046f6:	7c78                	ld	a4,248(s0)
ffffffffc02046f8:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc02046fa:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc02046fe:	7c78                	ld	a4,248(s0)
ffffffffc0204700:	c36d                	beqz	a4,ffffffffc02047e2 <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc0204702:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc0204706:	00097797          	auipc	a5,0x97
ffffffffc020470a:	f727a783          	lw	a5,-142(a5) # ffffffffc029b678 <nr_process>
ffffffffc020470e:	37fd                	addiw	a5,a5,-1
ffffffffc0204710:	00097717          	auipc	a4,0x97
ffffffffc0204714:	f6f72423          	sw	a5,-152(a4) # ffffffffc029b678 <nr_process>
    if (flag)
ffffffffc0204718:	e271                	bnez	a2,ffffffffc02047dc <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020471a:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020471c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204720:	10f6e663          	bltu	a3,a5,ffffffffc020482c <do_wait.part.0+0x1ca>
ffffffffc0204724:	00097717          	auipc	a4,0x97
ffffffffc0204728:	f3c73703          	ld	a4,-196(a4) # ffffffffc029b660 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc020472c:	00097797          	auipc	a5,0x97
ffffffffc0204730:	f3c7b783          	ld	a5,-196(a5) # ffffffffc029b668 <npage>
    return pa2page(PADDR(kva));
ffffffffc0204734:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0204736:	82b1                	srli	a3,a3,0xc
ffffffffc0204738:	0cf6fe63          	bgeu	a3,a5,ffffffffc0204814 <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc020473c:	00003797          	auipc	a5,0x3
ffffffffc0204740:	3847b783          	ld	a5,900(a5) # ffffffffc0207ac0 <nbase>
ffffffffc0204744:	00097517          	auipc	a0,0x97
ffffffffc0204748:	f2c53503          	ld	a0,-212(a0) # ffffffffc029b670 <pages>
ffffffffc020474c:	4589                	li	a1,2
ffffffffc020474e:	8e9d                	sub	a3,a3,a5
ffffffffc0204750:	069a                	slli	a3,a3,0x6
ffffffffc0204752:	9536                	add	a0,a0,a3
ffffffffc0204754:	ff8fd0ef          	jal	ffffffffc0201f4c <free_pages>
    kfree(proc);
ffffffffc0204758:	8522                	mv	a0,s0
ffffffffc020475a:	e9cfd0ef          	jal	ffffffffc0201df6 <kfree>
}
ffffffffc020475e:	70a2                	ld	ra,40(sp)
ffffffffc0204760:	7402                	ld	s0,32(sp)
ffffffffc0204762:	64e2                	ld	s1,24(sp)
ffffffffc0204764:	6942                	ld	s2,16(sp)
ffffffffc0204766:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc0204768:	4501                	li	a0,0
}
ffffffffc020476a:	6145                	addi	sp,sp,48
ffffffffc020476c:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc020476e:	00097997          	auipc	s3,0x97
ffffffffc0204772:	f1298993          	addi	s3,s3,-238 # ffffffffc029b680 <current>
ffffffffc0204776:	0009b703          	ld	a4,0(s3)
ffffffffc020477a:	f487b683          	ld	a3,-184(a5)
ffffffffc020477e:	f0e695e3          	bne	a3,a4,ffffffffc0204688 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204782:	f287a603          	lw	a2,-216(a5)
ffffffffc0204786:	468d                	li	a3,3
ffffffffc0204788:	06d60063          	beq	a2,a3,ffffffffc02047e8 <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc020478c:	800007b7          	lui	a5,0x80000
ffffffffc0204790:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
        current->state = PROC_SLEEPING;
ffffffffc0204792:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc0204794:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc0204798:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc020479a:	2ef000ef          	jal	ffffffffc0205288 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc020479e:	0009b783          	ld	a5,0(s3)
ffffffffc02047a2:	0b07a783          	lw	a5,176(a5)
ffffffffc02047a6:	8b85                	andi	a5,a5,1
ffffffffc02047a8:	e7b9                	bnez	a5,ffffffffc02047f6 <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc02047aa:	ee0487e3          	beqz	s1,ffffffffc0204698 <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc02047ae:	45a9                	li	a1,10
ffffffffc02047b0:	8526                	mv	a0,s1
ffffffffc02047b2:	43f000ef          	jal	ffffffffc02053f0 <hash32>
ffffffffc02047b6:	02051793          	slli	a5,a0,0x20
ffffffffc02047ba:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02047be:	00093797          	auipc	a5,0x93
ffffffffc02047c2:	e4a78793          	addi	a5,a5,-438 # ffffffffc0297608 <hash_list>
ffffffffc02047c6:	953e                	add	a0,a0,a5
ffffffffc02047c8:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc02047ca:	a029                	j	ffffffffc02047d4 <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc02047cc:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02047d0:	f8970fe3          	beq	a4,s1,ffffffffc020476e <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc02047d4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02047d6:	fef51be3          	bne	a0,a5,ffffffffc02047cc <do_wait.part.0+0x16a>
ffffffffc02047da:	b57d                	j	ffffffffc0204688 <do_wait.part.0+0x26>
        intr_enable();
ffffffffc02047dc:	922fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02047e0:	bf2d                	j	ffffffffc020471a <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc02047e2:	7018                	ld	a4,32(s0)
ffffffffc02047e4:	fb7c                	sd	a5,240(a4)
ffffffffc02047e6:	b705                	j	ffffffffc0204706 <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02047e8:	f2878413          	addi	s0,a5,-216
ffffffffc02047ec:	b5d1                	j	ffffffffc02046b0 <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc02047ee:	916fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02047f2:	4605                	li	a2,1
ffffffffc02047f4:	b5f5                	j	ffffffffc02046e0 <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc02047f6:	555d                	li	a0,-9
ffffffffc02047f8:	d27ff0ef          	jal	ffffffffc020451e <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc02047fc:	00003617          	auipc	a2,0x3
ffffffffc0204800:	9bc60613          	addi	a2,a2,-1604 # ffffffffc02071b8 <etext+0x1908>
ffffffffc0204804:	36200593          	li	a1,866
ffffffffc0204808:	00003517          	auipc	a0,0x3
ffffffffc020480c:	91050513          	addi	a0,a0,-1776 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204810:	c37fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204814:	00002617          	auipc	a2,0x2
ffffffffc0204818:	f9c60613          	addi	a2,a2,-100 # ffffffffc02067b0 <etext+0xf00>
ffffffffc020481c:	06900593          	li	a1,105
ffffffffc0204820:	00002517          	auipc	a0,0x2
ffffffffc0204824:	ee850513          	addi	a0,a0,-280 # ffffffffc0206708 <etext+0xe58>
ffffffffc0204828:	c1ffb0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc020482c:	00002617          	auipc	a2,0x2
ffffffffc0204830:	f5c60613          	addi	a2,a2,-164 # ffffffffc0206788 <etext+0xed8>
ffffffffc0204834:	07700593          	li	a1,119
ffffffffc0204838:	00002517          	auipc	a0,0x2
ffffffffc020483c:	ed050513          	addi	a0,a0,-304 # ffffffffc0206708 <etext+0xe58>
ffffffffc0204840:	c07fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204844 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0204844:	1141                	addi	sp,sp,-16
ffffffffc0204846:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0204848:	f3cfd0ef          	jal	ffffffffc0201f84 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc020484c:	d00fd0ef          	jal	ffffffffc0201d4c <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc0204850:	4601                	li	a2,0
ffffffffc0204852:	4581                	li	a1,0
ffffffffc0204854:	fffff517          	auipc	a0,0xfffff
ffffffffc0204858:	6d250513          	addi	a0,a0,1746 # ffffffffc0203f26 <user_main>
ffffffffc020485c:	c73ff0ef          	jal	ffffffffc02044ce <kernel_thread>
    if (pid <= 0)
ffffffffc0204860:	00a04563          	bgtz	a0,ffffffffc020486a <init_main+0x26>
ffffffffc0204864:	a071                	j	ffffffffc02048f0 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc0204866:	223000ef          	jal	ffffffffc0205288 <schedule>
    if (code_store != NULL)
ffffffffc020486a:	4581                	li	a1,0
ffffffffc020486c:	4501                	li	a0,0
ffffffffc020486e:	df5ff0ef          	jal	ffffffffc0204662 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204872:	d975                	beqz	a0,ffffffffc0204866 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204874:	00003517          	auipc	a0,0x3
ffffffffc0204878:	98450513          	addi	a0,a0,-1660 # ffffffffc02071f8 <etext+0x1948>
ffffffffc020487c:	919fb0ef          	jal	ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204880:	00097797          	auipc	a5,0x97
ffffffffc0204884:	e087b783          	ld	a5,-504(a5) # ffffffffc029b688 <initproc>
ffffffffc0204888:	7bf8                	ld	a4,240(a5)
ffffffffc020488a:	e339                	bnez	a4,ffffffffc02048d0 <init_main+0x8c>
ffffffffc020488c:	7ff8                	ld	a4,248(a5)
ffffffffc020488e:	e329                	bnez	a4,ffffffffc02048d0 <init_main+0x8c>
ffffffffc0204890:	1007b703          	ld	a4,256(a5)
ffffffffc0204894:	ef15                	bnez	a4,ffffffffc02048d0 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc0204896:	00097697          	auipc	a3,0x97
ffffffffc020489a:	de26a683          	lw	a3,-542(a3) # ffffffffc029b678 <nr_process>
ffffffffc020489e:	4709                	li	a4,2
ffffffffc02048a0:	0ae69463          	bne	a3,a4,ffffffffc0204948 <init_main+0x104>
ffffffffc02048a4:	00097697          	auipc	a3,0x97
ffffffffc02048a8:	d6468693          	addi	a3,a3,-668 # ffffffffc029b608 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02048ac:	6698                	ld	a4,8(a3)
ffffffffc02048ae:	0c878793          	addi	a5,a5,200
ffffffffc02048b2:	06f71b63          	bne	a4,a5,ffffffffc0204928 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02048b6:	629c                	ld	a5,0(a3)
ffffffffc02048b8:	04f71863          	bne	a4,a5,ffffffffc0204908 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc02048bc:	00003517          	auipc	a0,0x3
ffffffffc02048c0:	a2450513          	addi	a0,a0,-1500 # ffffffffc02072e0 <etext+0x1a30>
ffffffffc02048c4:	8d1fb0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc02048c8:	60a2                	ld	ra,8(sp)
ffffffffc02048ca:	4501                	li	a0,0
ffffffffc02048cc:	0141                	addi	sp,sp,16
ffffffffc02048ce:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02048d0:	00003697          	auipc	a3,0x3
ffffffffc02048d4:	95068693          	addi	a3,a3,-1712 # ffffffffc0207220 <etext+0x1970>
ffffffffc02048d8:	00002617          	auipc	a2,0x2
ffffffffc02048dc:	a5860613          	addi	a2,a2,-1448 # ffffffffc0206330 <etext+0xa80>
ffffffffc02048e0:	3d000593          	li	a1,976
ffffffffc02048e4:	00003517          	auipc	a0,0x3
ffffffffc02048e8:	83450513          	addi	a0,a0,-1996 # ffffffffc0207118 <etext+0x1868>
ffffffffc02048ec:	b5bfb0ef          	jal	ffffffffc0200446 <__panic>
        panic("create user_main failed.\n");
ffffffffc02048f0:	00003617          	auipc	a2,0x3
ffffffffc02048f4:	8e860613          	addi	a2,a2,-1816 # ffffffffc02071d8 <etext+0x1928>
ffffffffc02048f8:	3c700593          	li	a1,967
ffffffffc02048fc:	00003517          	auipc	a0,0x3
ffffffffc0204900:	81c50513          	addi	a0,a0,-2020 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204904:	b43fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204908:	00003697          	auipc	a3,0x3
ffffffffc020490c:	9a868693          	addi	a3,a3,-1624 # ffffffffc02072b0 <etext+0x1a00>
ffffffffc0204910:	00002617          	auipc	a2,0x2
ffffffffc0204914:	a2060613          	addi	a2,a2,-1504 # ffffffffc0206330 <etext+0xa80>
ffffffffc0204918:	3d300593          	li	a1,979
ffffffffc020491c:	00002517          	auipc	a0,0x2
ffffffffc0204920:	7fc50513          	addi	a0,a0,2044 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204924:	b23fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204928:	00003697          	auipc	a3,0x3
ffffffffc020492c:	95868693          	addi	a3,a3,-1704 # ffffffffc0207280 <etext+0x19d0>
ffffffffc0204930:	00002617          	auipc	a2,0x2
ffffffffc0204934:	a0060613          	addi	a2,a2,-1536 # ffffffffc0206330 <etext+0xa80>
ffffffffc0204938:	3d200593          	li	a1,978
ffffffffc020493c:	00002517          	auipc	a0,0x2
ffffffffc0204940:	7dc50513          	addi	a0,a0,2012 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204944:	b03fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_process == 2);
ffffffffc0204948:	00003697          	auipc	a3,0x3
ffffffffc020494c:	92868693          	addi	a3,a3,-1752 # ffffffffc0207270 <etext+0x19c0>
ffffffffc0204950:	00002617          	auipc	a2,0x2
ffffffffc0204954:	9e060613          	addi	a2,a2,-1568 # ffffffffc0206330 <etext+0xa80>
ffffffffc0204958:	3d100593          	li	a1,977
ffffffffc020495c:	00002517          	auipc	a0,0x2
ffffffffc0204960:	7bc50513          	addi	a0,a0,1980 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204964:	ae3fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204968 <do_execve>:
{
ffffffffc0204968:	7171                	addi	sp,sp,-176
ffffffffc020496a:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020496c:	00097d17          	auipc	s10,0x97
ffffffffc0204970:	d14d0d13          	addi	s10,s10,-748 # ffffffffc029b680 <current>
ffffffffc0204974:	000d3783          	ld	a5,0(s10)
{
ffffffffc0204978:	e94a                	sd	s2,144(sp)
ffffffffc020497a:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020497c:	0287b903          	ld	s2,40(a5)
{
ffffffffc0204980:	84ae                	mv	s1,a1
ffffffffc0204982:	e54e                	sd	s3,136(sp)
ffffffffc0204984:	ec32                	sd	a2,24(sp)
ffffffffc0204986:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204988:	85aa                	mv	a1,a0
ffffffffc020498a:	8626                	mv	a2,s1
ffffffffc020498c:	854a                	mv	a0,s2
ffffffffc020498e:	4681                	li	a3,0
{
ffffffffc0204990:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204992:	c6eff0ef          	jal	ffffffffc0203e00 <user_mem_check>
ffffffffc0204996:	46050f63          	beqz	a0,ffffffffc0204e14 <do_execve+0x4ac>
    memset(local_name, 0, sizeof(local_name));
ffffffffc020499a:	4641                	li	a2,16
ffffffffc020499c:	1808                	addi	a0,sp,48
ffffffffc020499e:	4581                	li	a1,0
ffffffffc02049a0:	6e7000ef          	jal	ffffffffc0205886 <memset>
    if (len > PROC_NAME_LEN)
ffffffffc02049a4:	47bd                	li	a5,15
ffffffffc02049a6:	8626                	mv	a2,s1
ffffffffc02049a8:	0e97ef63          	bltu	a5,s1,ffffffffc0204aa6 <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc02049ac:	85ce                	mv	a1,s3
ffffffffc02049ae:	1808                	addi	a0,sp,48
ffffffffc02049b0:	6e9000ef          	jal	ffffffffc0205898 <memcpy>
    if (mm != NULL)
ffffffffc02049b4:	10090063          	beqz	s2,ffffffffc0204ab4 <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc02049b8:	00002517          	auipc	a0,0x2
ffffffffc02049bc:	52050513          	addi	a0,a0,1312 # ffffffffc0206ed8 <etext+0x1628>
ffffffffc02049c0:	80bfb0ef          	jal	ffffffffc02001ca <cputs>
ffffffffc02049c4:	00097797          	auipc	a5,0x97
ffffffffc02049c8:	c8c7b783          	ld	a5,-884(a5) # ffffffffc029b650 <boot_pgdir_pa>
ffffffffc02049cc:	577d                	li	a4,-1
ffffffffc02049ce:	177e                	slli	a4,a4,0x3f
ffffffffc02049d0:	83b1                	srli	a5,a5,0xc
ffffffffc02049d2:	8fd9                	or	a5,a5,a4
ffffffffc02049d4:	18079073          	csrw	satp,a5
ffffffffc02049d8:	03092783          	lw	a5,48(s2)
ffffffffc02049dc:	37fd                	addiw	a5,a5,-1
ffffffffc02049de:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc02049e2:	30078563          	beqz	a5,ffffffffc0204cec <do_execve+0x384>
        current->mm = NULL;
ffffffffc02049e6:	000d3783          	ld	a5,0(s10)
ffffffffc02049ea:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc02049ee:	d87fe0ef          	jal	ffffffffc0203774 <mm_create>
ffffffffc02049f2:	892a                	mv	s2,a0
ffffffffc02049f4:	22050063          	beqz	a0,ffffffffc0204c14 <do_execve+0x2ac>
    if ((page = alloc_page()) == NULL)
ffffffffc02049f8:	4505                	li	a0,1
ffffffffc02049fa:	d18fd0ef          	jal	ffffffffc0201f12 <alloc_pages>
ffffffffc02049fe:	42050063          	beqz	a0,ffffffffc0204e1e <do_execve+0x4b6>
    return page - pages + nbase;
ffffffffc0204a02:	f0e2                	sd	s8,96(sp)
ffffffffc0204a04:	00097c17          	auipc	s8,0x97
ffffffffc0204a08:	c6cc0c13          	addi	s8,s8,-916 # ffffffffc029b670 <pages>
ffffffffc0204a0c:	000c3783          	ld	a5,0(s8)
ffffffffc0204a10:	f4de                	sd	s7,104(sp)
ffffffffc0204a12:	00003b97          	auipc	s7,0x3
ffffffffc0204a16:	0aebbb83          	ld	s7,174(s7) # ffffffffc0207ac0 <nbase>
ffffffffc0204a1a:	40f506b3          	sub	a3,a0,a5
ffffffffc0204a1e:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc0204a20:	00097c97          	auipc	s9,0x97
ffffffffc0204a24:	c48c8c93          	addi	s9,s9,-952 # ffffffffc029b668 <npage>
ffffffffc0204a28:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc0204a2a:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204a2c:	5b7d                	li	s6,-1
ffffffffc0204a2e:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc0204a32:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204a34:	00cb5713          	srli	a4,s6,0xc
ffffffffc0204a38:	e83a                	sd	a4,16(sp)
ffffffffc0204a3a:	fcd6                	sd	s5,120(sp)
ffffffffc0204a3c:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204a3e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204a40:	40f77263          	bgeu	a4,a5,ffffffffc0204e44 <do_execve+0x4dc>
ffffffffc0204a44:	00097a97          	auipc	s5,0x97
ffffffffc0204a48:	c1ca8a93          	addi	s5,s5,-996 # ffffffffc029b660 <va_pa_offset>
ffffffffc0204a4c:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204a50:	00097597          	auipc	a1,0x97
ffffffffc0204a54:	c085b583          	ld	a1,-1016(a1) # ffffffffc029b658 <boot_pgdir_va>
ffffffffc0204a58:	6605                	lui	a2,0x1
ffffffffc0204a5a:	00f684b3          	add	s1,a3,a5
ffffffffc0204a5e:	8526                	mv	a0,s1
ffffffffc0204a60:	639000ef          	jal	ffffffffc0205898 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204a64:	66e2                	ld	a3,24(sp)
ffffffffc0204a66:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc0204a6a:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204a6e:	4298                	lw	a4,0(a3)
ffffffffc0204a70:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464ba3c7>
ffffffffc0204a74:	06f70863          	beq	a4,a5,ffffffffc0204ae4 <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc0204a78:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc0204a7a:	854a                	mv	a0,s2
ffffffffc0204a7c:	d28ff0ef          	jal	ffffffffc0203fa4 <put_pgdir>
ffffffffc0204a80:	7ae6                	ld	s5,120(sp)
ffffffffc0204a82:	7b46                	ld	s6,112(sp)
ffffffffc0204a84:	7ba6                	ld	s7,104(sp)
ffffffffc0204a86:	7c06                	ld	s8,96(sp)
ffffffffc0204a88:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc0204a8a:	854a                	mv	a0,s2
ffffffffc0204a8c:	e27fe0ef          	jal	ffffffffc02038b2 <mm_destroy>
    do_exit(ret);
ffffffffc0204a90:	8526                	mv	a0,s1
ffffffffc0204a92:	f122                	sd	s0,160(sp)
ffffffffc0204a94:	e152                	sd	s4,128(sp)
ffffffffc0204a96:	fcd6                	sd	s5,120(sp)
ffffffffc0204a98:	f8da                	sd	s6,112(sp)
ffffffffc0204a9a:	f4de                	sd	s7,104(sp)
ffffffffc0204a9c:	f0e2                	sd	s8,96(sp)
ffffffffc0204a9e:	ece6                	sd	s9,88(sp)
ffffffffc0204aa0:	e4ee                	sd	s11,72(sp)
ffffffffc0204aa2:	a7dff0ef          	jal	ffffffffc020451e <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc0204aa6:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc0204aa8:	85ce                	mv	a1,s3
ffffffffc0204aaa:	1808                	addi	a0,sp,48
ffffffffc0204aac:	5ed000ef          	jal	ffffffffc0205898 <memcpy>
    if (mm != NULL)
ffffffffc0204ab0:	f00914e3          	bnez	s2,ffffffffc02049b8 <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc0204ab4:	000d3783          	ld	a5,0(s10)
ffffffffc0204ab8:	779c                	ld	a5,40(a5)
ffffffffc0204aba:	db95                	beqz	a5,ffffffffc02049ee <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204abc:	00003617          	auipc	a2,0x3
ffffffffc0204ac0:	84460613          	addi	a2,a2,-1980 # ffffffffc0207300 <etext+0x1a50>
ffffffffc0204ac4:	24d00593          	li	a1,589
ffffffffc0204ac8:	00002517          	auipc	a0,0x2
ffffffffc0204acc:	65050513          	addi	a0,a0,1616 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204ad0:	f122                	sd	s0,160(sp)
ffffffffc0204ad2:	e152                	sd	s4,128(sp)
ffffffffc0204ad4:	fcd6                	sd	s5,120(sp)
ffffffffc0204ad6:	f8da                	sd	s6,112(sp)
ffffffffc0204ad8:	f4de                	sd	s7,104(sp)
ffffffffc0204ada:	f0e2                	sd	s8,96(sp)
ffffffffc0204adc:	ece6                	sd	s9,88(sp)
ffffffffc0204ade:	e4ee                	sd	s11,72(sp)
ffffffffc0204ae0:	967fb0ef          	jal	ffffffffc0200446 <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204ae4:	0386d703          	lhu	a4,56(a3)
ffffffffc0204ae8:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204aea:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204aee:	00371793          	slli	a5,a4,0x3
ffffffffc0204af2:	8f99                	sub	a5,a5,a4
ffffffffc0204af4:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204af6:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204af8:	97d2                	add	a5,a5,s4
ffffffffc0204afa:	f122                	sd	s0,160(sp)
ffffffffc0204afc:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204afe:	00fa7e63          	bgeu	s4,a5,ffffffffc0204b1a <do_execve+0x1b2>
ffffffffc0204b02:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204b04:	000a2783          	lw	a5,0(s4)
ffffffffc0204b08:	4705                	li	a4,1
ffffffffc0204b0a:	10e78763          	beq	a5,a4,ffffffffc0204c18 <do_execve+0x2b0>
    for (; ph < ph_end; ph++)
ffffffffc0204b0e:	77a2                	ld	a5,40(sp)
ffffffffc0204b10:	038a0a13          	addi	s4,s4,56
ffffffffc0204b14:	fefa68e3          	bltu	s4,a5,ffffffffc0204b04 <do_execve+0x19c>
ffffffffc0204b18:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204b1a:	4701                	li	a4,0
ffffffffc0204b1c:	46ad                	li	a3,11
ffffffffc0204b1e:	00100637          	lui	a2,0x100
ffffffffc0204b22:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204b26:	854a                	mv	a0,s2
ffffffffc0204b28:	dddfe0ef          	jal	ffffffffc0203904 <mm_map>
ffffffffc0204b2c:	84aa                	mv	s1,a0
ffffffffc0204b2e:	1a051963          	bnez	a0,ffffffffc0204ce0 <do_execve+0x378>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204b32:	01893503          	ld	a0,24(s2)
ffffffffc0204b36:	467d                	li	a2,31
ffffffffc0204b38:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204b3c:	b57fe0ef          	jal	ffffffffc0203692 <pgdir_alloc_page>
ffffffffc0204b40:	3a050163          	beqz	a0,ffffffffc0204ee2 <do_execve+0x57a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b44:	01893503          	ld	a0,24(s2)
ffffffffc0204b48:	467d                	li	a2,31
ffffffffc0204b4a:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204b4e:	b45fe0ef          	jal	ffffffffc0203692 <pgdir_alloc_page>
ffffffffc0204b52:	36050763          	beqz	a0,ffffffffc0204ec0 <do_execve+0x558>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b56:	01893503          	ld	a0,24(s2)
ffffffffc0204b5a:	467d                	li	a2,31
ffffffffc0204b5c:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204b60:	b33fe0ef          	jal	ffffffffc0203692 <pgdir_alloc_page>
ffffffffc0204b64:	32050d63          	beqz	a0,ffffffffc0204e9e <do_execve+0x536>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204b68:	01893503          	ld	a0,24(s2)
ffffffffc0204b6c:	467d                	li	a2,31
ffffffffc0204b6e:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204b72:	b21fe0ef          	jal	ffffffffc0203692 <pgdir_alloc_page>
ffffffffc0204b76:	30050363          	beqz	a0,ffffffffc0204e7c <do_execve+0x514>
    mm->mm_count += 1;
ffffffffc0204b7a:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0204b7e:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b82:	01893683          	ld	a3,24(s2)
ffffffffc0204b86:	2785                	addiw	a5,a5,1
ffffffffc0204b88:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0204b8c:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf5e70>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b90:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b94:	2cf6e763          	bltu	a3,a5,ffffffffc0204e62 <do_execve+0x4fa>
ffffffffc0204b98:	000ab783          	ld	a5,0(s5)
ffffffffc0204b9c:	577d                	li	a4,-1
ffffffffc0204b9e:	177e                	slli	a4,a4,0x3f
ffffffffc0204ba0:	8e9d                	sub	a3,a3,a5
ffffffffc0204ba2:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204ba6:	f654                	sd	a3,168(a2)
ffffffffc0204ba8:	8fd9                	or	a5,a5,a4
ffffffffc0204baa:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204bae:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204bb0:	4581                	li	a1,0
ffffffffc0204bb2:	12000613          	li	a2,288
ffffffffc0204bb6:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204bb8:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204bbc:	4cb000ef          	jal	ffffffffc0205886 <memset>
    tf->epc = elf->e_entry;
ffffffffc0204bc0:	67e2                	ld	a5,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bc2:	000d3983          	ld	s3,0(s10)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204bc6:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry;
ffffffffc0204bca:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204bcc:	4785                	li	a5,1
ffffffffc0204bce:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204bd0:	02096913          	ori	s2,s2,32
    tf->epc = elf->e_entry;
ffffffffc0204bd4:	10e43423          	sd	a4,264(s0)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204bd8:	e81c                	sd	a5,16(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204bda:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204bde:	4641                	li	a2,16
ffffffffc0204be0:	4581                	li	a1,0
ffffffffc0204be2:	0b498513          	addi	a0,s3,180
ffffffffc0204be6:	4a1000ef          	jal	ffffffffc0205886 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204bea:	180c                	addi	a1,sp,48
ffffffffc0204bec:	0b498513          	addi	a0,s3,180
ffffffffc0204bf0:	463d                	li	a2,15
ffffffffc0204bf2:	4a7000ef          	jal	ffffffffc0205898 <memcpy>
ffffffffc0204bf6:	740a                	ld	s0,160(sp)
ffffffffc0204bf8:	6a0a                	ld	s4,128(sp)
ffffffffc0204bfa:	7ae6                	ld	s5,120(sp)
ffffffffc0204bfc:	7b46                	ld	s6,112(sp)
ffffffffc0204bfe:	7ba6                	ld	s7,104(sp)
ffffffffc0204c00:	7c06                	ld	s8,96(sp)
ffffffffc0204c02:	6ce6                	ld	s9,88(sp)
}
ffffffffc0204c04:	70aa                	ld	ra,168(sp)
ffffffffc0204c06:	694a                	ld	s2,144(sp)
ffffffffc0204c08:	69aa                	ld	s3,136(sp)
ffffffffc0204c0a:	6d46                	ld	s10,80(sp)
ffffffffc0204c0c:	8526                	mv	a0,s1
ffffffffc0204c0e:	64ea                	ld	s1,152(sp)
ffffffffc0204c10:	614d                	addi	sp,sp,176
ffffffffc0204c12:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204c14:	54f1                	li	s1,-4
ffffffffc0204c16:	bdad                	j	ffffffffc0204a90 <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204c18:	028a3603          	ld	a2,40(s4)
ffffffffc0204c1c:	020a3783          	ld	a5,32(s4)
ffffffffc0204c20:	20f66363          	bltu	a2,a5,ffffffffc0204e26 <do_execve+0x4be>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204c24:	004a2783          	lw	a5,4(s4)
ffffffffc0204c28:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c2c:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204c30:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c32:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204c34:	c6f1                	beqz	a3,ffffffffc0204d00 <do_execve+0x398>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c36:	1c079763          	bnez	a5,ffffffffc0204e04 <do_execve+0x49c>
            perm |= (PTE_W | PTE_R);
ffffffffc0204c3a:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc0204c3c:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc0204c40:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc0204c42:	c709                	beqz	a4,ffffffffc0204c4c <do_execve+0x2e4>
            perm |= PTE_X;
ffffffffc0204c44:	67a2                	ld	a5,8(sp)
ffffffffc0204c46:	0087e793          	ori	a5,a5,8
ffffffffc0204c4a:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204c4c:	010a3583          	ld	a1,16(s4)
ffffffffc0204c50:	4701                	li	a4,0
ffffffffc0204c52:	854a                	mv	a0,s2
ffffffffc0204c54:	cb1fe0ef          	jal	ffffffffc0203904 <mm_map>
ffffffffc0204c58:	84aa                	mv	s1,a0
ffffffffc0204c5a:	1c051463          	bnez	a0,ffffffffc0204e22 <do_execve+0x4ba>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204c5e:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204c62:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204c66:	77fd                	lui	a5,0xfffff
ffffffffc0204c68:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc0204c6c:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc0204c6e:	1a9b7563          	bgeu	s6,s1,ffffffffc0204e18 <do_execve+0x4b0>
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c72:	008a3983          	ld	s3,8(s4)
ffffffffc0204c76:	67e2                	ld	a5,24(sp)
ffffffffc0204c78:	99be                	add	s3,s3,a5
ffffffffc0204c7a:	a881                	j	ffffffffc0204cca <do_execve+0x362>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c7c:	6785                	lui	a5,0x1
ffffffffc0204c7e:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204c82:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204c86:	01b4e463          	bltu	s1,s11,ffffffffc0204c8e <do_execve+0x326>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c8a:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204c8e:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204c92:	67c2                	ld	a5,16(sp)
ffffffffc0204c94:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204c98:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c9c:	8699                	srai	a3,a3,0x6
ffffffffc0204c9e:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204ca0:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ca4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ca6:	18a87363          	bgeu	a6,a0,ffffffffc0204e2c <do_execve+0x4c4>
ffffffffc0204caa:	000ab503          	ld	a0,0(s5)
ffffffffc0204cae:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204cb2:	e032                	sd	a2,0(sp)
ffffffffc0204cb4:	9536                	add	a0,a0,a3
ffffffffc0204cb6:	952e                	add	a0,a0,a1
ffffffffc0204cb8:	85ce                	mv	a1,s3
ffffffffc0204cba:	3df000ef          	jal	ffffffffc0205898 <memcpy>
            start += size, from += size;
ffffffffc0204cbe:	6602                	ld	a2,0(sp)
ffffffffc0204cc0:	9b32                	add	s6,s6,a2
ffffffffc0204cc2:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204cc4:	049b7563          	bgeu	s6,s1,ffffffffc0204d0e <do_execve+0x3a6>
ffffffffc0204cc8:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204cca:	01893503          	ld	a0,24(s2)
ffffffffc0204cce:	6622                	ld	a2,8(sp)
ffffffffc0204cd0:	e02e                	sd	a1,0(sp)
ffffffffc0204cd2:	9c1fe0ef          	jal	ffffffffc0203692 <pgdir_alloc_page>
ffffffffc0204cd6:	6582                	ld	a1,0(sp)
ffffffffc0204cd8:	842a                	mv	s0,a0
ffffffffc0204cda:	f14d                	bnez	a0,ffffffffc0204c7c <do_execve+0x314>
ffffffffc0204cdc:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204cde:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204ce0:	854a                	mv	a0,s2
ffffffffc0204ce2:	d87fe0ef          	jal	ffffffffc0203a68 <exit_mmap>
ffffffffc0204ce6:	740a                	ld	s0,160(sp)
ffffffffc0204ce8:	6a0a                	ld	s4,128(sp)
ffffffffc0204cea:	bb41                	j	ffffffffc0204a7a <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204cec:	854a                	mv	a0,s2
ffffffffc0204cee:	d7bfe0ef          	jal	ffffffffc0203a68 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204cf2:	854a                	mv	a0,s2
ffffffffc0204cf4:	ab0ff0ef          	jal	ffffffffc0203fa4 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204cf8:	854a                	mv	a0,s2
ffffffffc0204cfa:	bb9fe0ef          	jal	ffffffffc02038b2 <mm_destroy>
ffffffffc0204cfe:	b1e5                	j	ffffffffc02049e6 <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d00:	0e078e63          	beqz	a5,ffffffffc0204dfc <do_execve+0x494>
            perm |= PTE_R;
ffffffffc0204d04:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204d06:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204d0a:	e43e                	sd	a5,8(sp)
ffffffffc0204d0c:	bf1d                	j	ffffffffc0204c42 <do_execve+0x2da>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204d0e:	010a3483          	ld	s1,16(s4)
ffffffffc0204d12:	028a3683          	ld	a3,40(s4)
ffffffffc0204d16:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204d18:	07bb7c63          	bgeu	s6,s11,ffffffffc0204d90 <do_execve+0x428>
            if (start == end)
ffffffffc0204d1c:	df6489e3          	beq	s1,s6,ffffffffc0204b0e <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204d20:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204d24:	0fb4f563          	bgeu	s1,s11,ffffffffc0204e0e <do_execve+0x4a6>
    return page - pages + nbase;
ffffffffc0204d28:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204d2c:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204d30:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d34:	8699                	srai	a3,a3,0x6
ffffffffc0204d36:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204d38:	00c69593          	slli	a1,a3,0xc
ffffffffc0204d3c:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d3e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d40:	0ec5f663          	bgeu	a1,a2,ffffffffc0204e2c <do_execve+0x4c4>
ffffffffc0204d44:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d48:	6505                	lui	a0,0x1
ffffffffc0204d4a:	955a                	add	a0,a0,s6
ffffffffc0204d4c:	96b2                	add	a3,a3,a2
ffffffffc0204d4e:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d52:	9536                	add	a0,a0,a3
ffffffffc0204d54:	864e                	mv	a2,s3
ffffffffc0204d56:	4581                	li	a1,0
ffffffffc0204d58:	32f000ef          	jal	ffffffffc0205886 <memset>
            start += size;
ffffffffc0204d5c:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204d5e:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204d62:	01b4f463          	bgeu	s1,s11,ffffffffc0204d6a <do_execve+0x402>
ffffffffc0204d66:	db6484e3          	beq	s1,s6,ffffffffc0204b0e <do_execve+0x1a6>
ffffffffc0204d6a:	e299                	bnez	a3,ffffffffc0204d70 <do_execve+0x408>
ffffffffc0204d6c:	03bb0263          	beq	s6,s11,ffffffffc0204d90 <do_execve+0x428>
ffffffffc0204d70:	00002697          	auipc	a3,0x2
ffffffffc0204d74:	5b868693          	addi	a3,a3,1464 # ffffffffc0207328 <etext+0x1a78>
ffffffffc0204d78:	00001617          	auipc	a2,0x1
ffffffffc0204d7c:	5b860613          	addi	a2,a2,1464 # ffffffffc0206330 <etext+0xa80>
ffffffffc0204d80:	2b600593          	li	a1,694
ffffffffc0204d84:	00002517          	auipc	a0,0x2
ffffffffc0204d88:	39450513          	addi	a0,a0,916 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204d8c:	ebafb0ef          	jal	ffffffffc0200446 <__panic>
        while (start < end)
ffffffffc0204d90:	d69b7fe3          	bgeu	s6,s1,ffffffffc0204b0e <do_execve+0x1a6>
ffffffffc0204d94:	56fd                	li	a3,-1
ffffffffc0204d96:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204d9a:	f03e                	sd	a5,32(sp)
ffffffffc0204d9c:	a0b9                	j	ffffffffc0204dea <do_execve+0x482>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d9e:	6785                	lui	a5,0x1
ffffffffc0204da0:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204da4:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204da8:	0104e463          	bltu	s1,a6,ffffffffc0204db0 <do_execve+0x448>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204dac:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204db0:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204db4:	7782                	ld	a5,32(sp)
ffffffffc0204db6:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204dba:	40d406b3          	sub	a3,s0,a3
ffffffffc0204dbe:	8699                	srai	a3,a3,0x6
ffffffffc0204dc0:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204dc2:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204dc6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204dc8:	06b57263          	bgeu	a0,a1,ffffffffc0204e2c <do_execve+0x4c4>
ffffffffc0204dcc:	000ab583          	ld	a1,0(s5)
ffffffffc0204dd0:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204dd4:	864e                	mv	a2,s3
ffffffffc0204dd6:	96ae                	add	a3,a3,a1
ffffffffc0204dd8:	9536                	add	a0,a0,a3
ffffffffc0204dda:	4581                	li	a1,0
            start += size;
ffffffffc0204ddc:	9b4e                	add	s6,s6,s3
ffffffffc0204dde:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204de0:	2a7000ef          	jal	ffffffffc0205886 <memset>
        while (start < end)
ffffffffc0204de4:	d29b75e3          	bgeu	s6,s1,ffffffffc0204b0e <do_execve+0x1a6>
ffffffffc0204de8:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204dea:	01893503          	ld	a0,24(s2)
ffffffffc0204dee:	6622                	ld	a2,8(sp)
ffffffffc0204df0:	85ee                	mv	a1,s11
ffffffffc0204df2:	8a1fe0ef          	jal	ffffffffc0203692 <pgdir_alloc_page>
ffffffffc0204df6:	842a                	mv	s0,a0
ffffffffc0204df8:	f15d                	bnez	a0,ffffffffc0204d9e <do_execve+0x436>
ffffffffc0204dfa:	b5cd                	j	ffffffffc0204cdc <do_execve+0x374>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204dfc:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204dfe:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204e00:	e43e                	sd	a5,8(sp)
ffffffffc0204e02:	b581                	j	ffffffffc0204c42 <do_execve+0x2da>
            perm |= (PTE_W | PTE_R);
ffffffffc0204e04:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204e06:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204e0a:	e43e                	sd	a5,8(sp)
ffffffffc0204e0c:	bd1d                	j	ffffffffc0204c42 <do_execve+0x2da>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204e0e:	416d89b3          	sub	s3,s11,s6
ffffffffc0204e12:	bf19                	j	ffffffffc0204d28 <do_execve+0x3c0>
        return -E_INVAL;
ffffffffc0204e14:	54f5                	li	s1,-3
ffffffffc0204e16:	b3fd                	j	ffffffffc0204c04 <do_execve+0x29c>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204e18:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204e1a:	84da                	mv	s1,s6
ffffffffc0204e1c:	bddd                	j	ffffffffc0204d12 <do_execve+0x3aa>
    int ret = -E_NO_MEM;
ffffffffc0204e1e:	54f1                	li	s1,-4
ffffffffc0204e20:	b1ad                	j	ffffffffc0204a8a <do_execve+0x122>
ffffffffc0204e22:	6da6                	ld	s11,72(sp)
ffffffffc0204e24:	bd75                	j	ffffffffc0204ce0 <do_execve+0x378>
            ret = -E_INVAL_ELF;
ffffffffc0204e26:	6da6                	ld	s11,72(sp)
ffffffffc0204e28:	54e1                	li	s1,-8
ffffffffc0204e2a:	bd5d                	j	ffffffffc0204ce0 <do_execve+0x378>
ffffffffc0204e2c:	00002617          	auipc	a2,0x2
ffffffffc0204e30:	8b460613          	addi	a2,a2,-1868 # ffffffffc02066e0 <etext+0xe30>
ffffffffc0204e34:	07100593          	li	a1,113
ffffffffc0204e38:	00002517          	auipc	a0,0x2
ffffffffc0204e3c:	8d050513          	addi	a0,a0,-1840 # ffffffffc0206708 <etext+0xe58>
ffffffffc0204e40:	e06fb0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0204e44:	00002617          	auipc	a2,0x2
ffffffffc0204e48:	89c60613          	addi	a2,a2,-1892 # ffffffffc02066e0 <etext+0xe30>
ffffffffc0204e4c:	07100593          	li	a1,113
ffffffffc0204e50:	00002517          	auipc	a0,0x2
ffffffffc0204e54:	8b850513          	addi	a0,a0,-1864 # ffffffffc0206708 <etext+0xe58>
ffffffffc0204e58:	f122                	sd	s0,160(sp)
ffffffffc0204e5a:	e152                	sd	s4,128(sp)
ffffffffc0204e5c:	e4ee                	sd	s11,72(sp)
ffffffffc0204e5e:	de8fb0ef          	jal	ffffffffc0200446 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204e62:	00002617          	auipc	a2,0x2
ffffffffc0204e66:	92660613          	addi	a2,a2,-1754 # ffffffffc0206788 <etext+0xed8>
ffffffffc0204e6a:	2d500593          	li	a1,725
ffffffffc0204e6e:	00002517          	auipc	a0,0x2
ffffffffc0204e72:	2aa50513          	addi	a0,a0,682 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204e76:	e4ee                	sd	s11,72(sp)
ffffffffc0204e78:	dcefb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e7c:	00002697          	auipc	a3,0x2
ffffffffc0204e80:	5c468693          	addi	a3,a3,1476 # ffffffffc0207440 <etext+0x1b90>
ffffffffc0204e84:	00001617          	auipc	a2,0x1
ffffffffc0204e88:	4ac60613          	addi	a2,a2,1196 # ffffffffc0206330 <etext+0xa80>
ffffffffc0204e8c:	2d000593          	li	a1,720
ffffffffc0204e90:	00002517          	auipc	a0,0x2
ffffffffc0204e94:	28850513          	addi	a0,a0,648 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204e98:	e4ee                	sd	s11,72(sp)
ffffffffc0204e9a:	dacfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e9e:	00002697          	auipc	a3,0x2
ffffffffc0204ea2:	55a68693          	addi	a3,a3,1370 # ffffffffc02073f8 <etext+0x1b48>
ffffffffc0204ea6:	00001617          	auipc	a2,0x1
ffffffffc0204eaa:	48a60613          	addi	a2,a2,1162 # ffffffffc0206330 <etext+0xa80>
ffffffffc0204eae:	2cf00593          	li	a1,719
ffffffffc0204eb2:	00002517          	auipc	a0,0x2
ffffffffc0204eb6:	26650513          	addi	a0,a0,614 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204eba:	e4ee                	sd	s11,72(sp)
ffffffffc0204ebc:	d8afb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ec0:	00002697          	auipc	a3,0x2
ffffffffc0204ec4:	4f068693          	addi	a3,a3,1264 # ffffffffc02073b0 <etext+0x1b00>
ffffffffc0204ec8:	00001617          	auipc	a2,0x1
ffffffffc0204ecc:	46860613          	addi	a2,a2,1128 # ffffffffc0206330 <etext+0xa80>
ffffffffc0204ed0:	2ce00593          	li	a1,718
ffffffffc0204ed4:	00002517          	auipc	a0,0x2
ffffffffc0204ed8:	24450513          	addi	a0,a0,580 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204edc:	e4ee                	sd	s11,72(sp)
ffffffffc0204ede:	d68fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204ee2:	00002697          	auipc	a3,0x2
ffffffffc0204ee6:	48668693          	addi	a3,a3,1158 # ffffffffc0207368 <etext+0x1ab8>
ffffffffc0204eea:	00001617          	auipc	a2,0x1
ffffffffc0204eee:	44660613          	addi	a2,a2,1094 # ffffffffc0206330 <etext+0xa80>
ffffffffc0204ef2:	2cd00593          	li	a1,717
ffffffffc0204ef6:	00002517          	auipc	a0,0x2
ffffffffc0204efa:	22250513          	addi	a0,a0,546 # ffffffffc0207118 <etext+0x1868>
ffffffffc0204efe:	e4ee                	sd	s11,72(sp)
ffffffffc0204f00:	d46fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204f04 <do_yield>:
    current->need_resched = 1;
ffffffffc0204f04:	00096797          	auipc	a5,0x96
ffffffffc0204f08:	77c7b783          	ld	a5,1916(a5) # ffffffffc029b680 <current>
ffffffffc0204f0c:	4705                	li	a4,1
}
ffffffffc0204f0e:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204f10:	ef98                	sd	a4,24(a5)
}
ffffffffc0204f12:	8082                	ret

ffffffffc0204f14 <do_wait>:
    if (code_store != NULL)
ffffffffc0204f14:	c59d                	beqz	a1,ffffffffc0204f42 <do_wait+0x2e>
{
ffffffffc0204f16:	1101                	addi	sp,sp,-32
ffffffffc0204f18:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204f1a:	00096517          	auipc	a0,0x96
ffffffffc0204f1e:	76653503          	ld	a0,1894(a0) # ffffffffc029b680 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204f22:	4685                	li	a3,1
ffffffffc0204f24:	4611                	li	a2,4
ffffffffc0204f26:	7508                	ld	a0,40(a0)
{
ffffffffc0204f28:	ec06                	sd	ra,24(sp)
ffffffffc0204f2a:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204f2c:	ed5fe0ef          	jal	ffffffffc0203e00 <user_mem_check>
ffffffffc0204f30:	6702                	ld	a4,0(sp)
ffffffffc0204f32:	67a2                	ld	a5,8(sp)
ffffffffc0204f34:	c909                	beqz	a0,ffffffffc0204f46 <do_wait+0x32>
}
ffffffffc0204f36:	60e2                	ld	ra,24(sp)
ffffffffc0204f38:	85be                	mv	a1,a5
ffffffffc0204f3a:	853a                	mv	a0,a4
ffffffffc0204f3c:	6105                	addi	sp,sp,32
ffffffffc0204f3e:	f24ff06f          	j	ffffffffc0204662 <do_wait.part.0>
ffffffffc0204f42:	f20ff06f          	j	ffffffffc0204662 <do_wait.part.0>
ffffffffc0204f46:	60e2                	ld	ra,24(sp)
ffffffffc0204f48:	5575                	li	a0,-3
ffffffffc0204f4a:	6105                	addi	sp,sp,32
ffffffffc0204f4c:	8082                	ret

ffffffffc0204f4e <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f4e:	6789                	lui	a5,0x2
ffffffffc0204f50:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f54:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bb2>
ffffffffc0204f56:	06e7e463          	bltu	a5,a4,ffffffffc0204fbe <do_kill+0x70>
{
ffffffffc0204f5a:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f5c:	45a9                	li	a1,10
{
ffffffffc0204f5e:	ec06                	sd	ra,24(sp)
ffffffffc0204f60:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f62:	48e000ef          	jal	ffffffffc02053f0 <hash32>
ffffffffc0204f66:	02051793          	slli	a5,a0,0x20
ffffffffc0204f6a:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204f6e:	00092797          	auipc	a5,0x92
ffffffffc0204f72:	69a78793          	addi	a5,a5,1690 # ffffffffc0297608 <hash_list>
ffffffffc0204f76:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204f78:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f7a:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204f7c:	a029                	j	ffffffffc0204f86 <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204f7e:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204f82:	00c70963          	beq	a4,a2,ffffffffc0204f94 <do_kill+0x46>
ffffffffc0204f86:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204f88:	fea69be3          	bne	a3,a0,ffffffffc0204f7e <do_kill+0x30>
}
ffffffffc0204f8c:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204f8e:	5575                	li	a0,-3
}
ffffffffc0204f90:	6105                	addi	sp,sp,32
ffffffffc0204f92:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204f94:	fd852703          	lw	a4,-40(a0)
ffffffffc0204f98:	00177693          	andi	a3,a4,1
ffffffffc0204f9c:	e29d                	bnez	a3,ffffffffc0204fc2 <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f9e:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204fa0:	00176713          	ori	a4,a4,1
ffffffffc0204fa4:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204fa8:	0006c663          	bltz	a3,ffffffffc0204fb4 <do_kill+0x66>
            return 0;
ffffffffc0204fac:	4501                	li	a0,0
}
ffffffffc0204fae:	60e2                	ld	ra,24(sp)
ffffffffc0204fb0:	6105                	addi	sp,sp,32
ffffffffc0204fb2:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204fb4:	f2850513          	addi	a0,a0,-216
ffffffffc0204fb8:	23c000ef          	jal	ffffffffc02051f4 <wakeup_proc>
ffffffffc0204fbc:	bfc5                	j	ffffffffc0204fac <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204fbe:	5575                	li	a0,-3
}
ffffffffc0204fc0:	8082                	ret
        return -E_KILLED;
ffffffffc0204fc2:	555d                	li	a0,-9
ffffffffc0204fc4:	b7ed                	j	ffffffffc0204fae <do_kill+0x60>

ffffffffc0204fc6 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204fc6:	1101                	addi	sp,sp,-32
ffffffffc0204fc8:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204fca:	00096797          	auipc	a5,0x96
ffffffffc0204fce:	63e78793          	addi	a5,a5,1598 # ffffffffc029b608 <proc_list>
ffffffffc0204fd2:	ec06                	sd	ra,24(sp)
ffffffffc0204fd4:	e822                	sd	s0,16(sp)
ffffffffc0204fd6:	e04a                	sd	s2,0(sp)
ffffffffc0204fd8:	00092497          	auipc	s1,0x92
ffffffffc0204fdc:	63048493          	addi	s1,s1,1584 # ffffffffc0297608 <hash_list>
ffffffffc0204fe0:	e79c                	sd	a5,8(a5)
ffffffffc0204fe2:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204fe4:	00096717          	auipc	a4,0x96
ffffffffc0204fe8:	62470713          	addi	a4,a4,1572 # ffffffffc029b608 <proc_list>
ffffffffc0204fec:	87a6                	mv	a5,s1
ffffffffc0204fee:	e79c                	sd	a5,8(a5)
ffffffffc0204ff0:	e39c                	sd	a5,0(a5)
ffffffffc0204ff2:	07c1                	addi	a5,a5,16
ffffffffc0204ff4:	fee79de3          	bne	a5,a4,ffffffffc0204fee <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204ff8:	eb5fe0ef          	jal	ffffffffc0203eac <alloc_proc>
ffffffffc0204ffc:	00096917          	auipc	s2,0x96
ffffffffc0205000:	69490913          	addi	s2,s2,1684 # ffffffffc029b690 <idleproc>
ffffffffc0205004:	00a93023          	sd	a0,0(s2)
ffffffffc0205008:	10050863          	beqz	a0,ffffffffc0205118 <proc_init+0x152>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc020500c:	4789                	li	a5,2
ffffffffc020500e:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
    idleproc->pgdir = boot_pgdir_pa;
ffffffffc0205010:	00096797          	auipc	a5,0x96
ffffffffc0205014:	6407b783          	ld	a5,1600(a5) # ffffffffc029b650 <boot_pgdir_pa>
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205018:	00003717          	auipc	a4,0x3
ffffffffc020501c:	fe870713          	addi	a4,a4,-24 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205020:	0b450413          	addi	s0,a0,180
    idleproc->pgdir = boot_pgdir_pa;
ffffffffc0205024:	f55c                	sd	a5,168(a0)
    idleproc->need_resched = 1;
ffffffffc0205026:	4785                	li	a5,1
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205028:	e918                	sd	a4,16(a0)
    idleproc->need_resched = 1;
ffffffffc020502a:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020502c:	4641                	li	a2,16
ffffffffc020502e:	8522                	mv	a0,s0
ffffffffc0205030:	4581                	li	a1,0
ffffffffc0205032:	055000ef          	jal	ffffffffc0205886 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205036:	8522                	mv	a0,s0
ffffffffc0205038:	463d                	li	a2,15
ffffffffc020503a:	00002597          	auipc	a1,0x2
ffffffffc020503e:	46658593          	addi	a1,a1,1126 # ffffffffc02074a0 <etext+0x1bf0>
ffffffffc0205042:	057000ef          	jal	ffffffffc0205898 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0205046:	00096797          	auipc	a5,0x96
ffffffffc020504a:	6327a783          	lw	a5,1586(a5) # ffffffffc029b678 <nr_process>

    current = idleproc;
ffffffffc020504e:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205052:	4601                	li	a2,0
    nr_process++;
ffffffffc0205054:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205056:	4581                	li	a1,0
ffffffffc0205058:	fffff517          	auipc	a0,0xfffff
ffffffffc020505c:	7ec50513          	addi	a0,a0,2028 # ffffffffc0204844 <init_main>
    current = idleproc;
ffffffffc0205060:	00096697          	auipc	a3,0x96
ffffffffc0205064:	62e6b023          	sd	a4,1568(a3) # ffffffffc029b680 <current>
    nr_process++;
ffffffffc0205068:	00096717          	auipc	a4,0x96
ffffffffc020506c:	60f72823          	sw	a5,1552(a4) # ffffffffc029b678 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205070:	c5eff0ef          	jal	ffffffffc02044ce <kernel_thread>
ffffffffc0205074:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0205076:	08a05563          	blez	a0,ffffffffc0205100 <proc_init+0x13a>
    if (0 < pid && pid < MAX_PID)
ffffffffc020507a:	6789                	lui	a5,0x2
ffffffffc020507c:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bb2>
ffffffffc020507e:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205082:	02e7e463          	bltu	a5,a4,ffffffffc02050aa <proc_init+0xe4>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205086:	45a9                	li	a1,10
ffffffffc0205088:	368000ef          	jal	ffffffffc02053f0 <hash32>
ffffffffc020508c:	02051713          	slli	a4,a0,0x20
ffffffffc0205090:	01c75793          	srli	a5,a4,0x1c
ffffffffc0205094:	00f486b3          	add	a3,s1,a5
ffffffffc0205098:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc020509a:	a029                	j	ffffffffc02050a4 <proc_init+0xde>
            if (proc->pid == pid)
ffffffffc020509c:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02050a0:	04870d63          	beq	a4,s0,ffffffffc02050fa <proc_init+0x134>
    return listelm->next;
ffffffffc02050a4:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02050a6:	fef69be3          	bne	a3,a5,ffffffffc020509c <proc_init+0xd6>
    return NULL;
ffffffffc02050aa:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050ac:	0b478413          	addi	s0,a5,180
ffffffffc02050b0:	4641                	li	a2,16
ffffffffc02050b2:	4581                	li	a1,0
ffffffffc02050b4:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02050b6:	00096717          	auipc	a4,0x96
ffffffffc02050ba:	5cf73923          	sd	a5,1490(a4) # ffffffffc029b688 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050be:	7c8000ef          	jal	ffffffffc0205886 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02050c2:	8522                	mv	a0,s0
ffffffffc02050c4:	463d                	li	a2,15
ffffffffc02050c6:	00002597          	auipc	a1,0x2
ffffffffc02050ca:	40258593          	addi	a1,a1,1026 # ffffffffc02074c8 <etext+0x1c18>
ffffffffc02050ce:	7ca000ef          	jal	ffffffffc0205898 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050d2:	00093783          	ld	a5,0(s2)
ffffffffc02050d6:	cfad                	beqz	a5,ffffffffc0205150 <proc_init+0x18a>
ffffffffc02050d8:	43dc                	lw	a5,4(a5)
ffffffffc02050da:	ebbd                	bnez	a5,ffffffffc0205150 <proc_init+0x18a>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050dc:	00096797          	auipc	a5,0x96
ffffffffc02050e0:	5ac7b783          	ld	a5,1452(a5) # ffffffffc029b688 <initproc>
ffffffffc02050e4:	c7b1                	beqz	a5,ffffffffc0205130 <proc_init+0x16a>
ffffffffc02050e6:	43d8                	lw	a4,4(a5)
ffffffffc02050e8:	4785                	li	a5,1
ffffffffc02050ea:	04f71363          	bne	a4,a5,ffffffffc0205130 <proc_init+0x16a>
}
ffffffffc02050ee:	60e2                	ld	ra,24(sp)
ffffffffc02050f0:	6442                	ld	s0,16(sp)
ffffffffc02050f2:	64a2                	ld	s1,8(sp)
ffffffffc02050f4:	6902                	ld	s2,0(sp)
ffffffffc02050f6:	6105                	addi	sp,sp,32
ffffffffc02050f8:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc02050fa:	f2878793          	addi	a5,a5,-216
ffffffffc02050fe:	b77d                	j	ffffffffc02050ac <proc_init+0xe6>
        panic("create init_main failed.\n");
ffffffffc0205100:	00002617          	auipc	a2,0x2
ffffffffc0205104:	3a860613          	addi	a2,a2,936 # ffffffffc02074a8 <etext+0x1bf8>
ffffffffc0205108:	3f700593          	li	a1,1015
ffffffffc020510c:	00002517          	auipc	a0,0x2
ffffffffc0205110:	00c50513          	addi	a0,a0,12 # ffffffffc0207118 <etext+0x1868>
ffffffffc0205114:	b32fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205118:	00002617          	auipc	a2,0x2
ffffffffc020511c:	37060613          	addi	a2,a2,880 # ffffffffc0207488 <etext+0x1bd8>
ffffffffc0205120:	3e700593          	li	a1,999
ffffffffc0205124:	00002517          	auipc	a0,0x2
ffffffffc0205128:	ff450513          	addi	a0,a0,-12 # ffffffffc0207118 <etext+0x1868>
ffffffffc020512c:	b1afb0ef          	jal	ffffffffc0200446 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205130:	00002697          	auipc	a3,0x2
ffffffffc0205134:	3c868693          	addi	a3,a3,968 # ffffffffc02074f8 <etext+0x1c48>
ffffffffc0205138:	00001617          	auipc	a2,0x1
ffffffffc020513c:	1f860613          	addi	a2,a2,504 # ffffffffc0206330 <etext+0xa80>
ffffffffc0205140:	3fe00593          	li	a1,1022
ffffffffc0205144:	00002517          	auipc	a0,0x2
ffffffffc0205148:	fd450513          	addi	a0,a0,-44 # ffffffffc0207118 <etext+0x1868>
ffffffffc020514c:	afafb0ef          	jal	ffffffffc0200446 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205150:	00002697          	auipc	a3,0x2
ffffffffc0205154:	38068693          	addi	a3,a3,896 # ffffffffc02074d0 <etext+0x1c20>
ffffffffc0205158:	00001617          	auipc	a2,0x1
ffffffffc020515c:	1d860613          	addi	a2,a2,472 # ffffffffc0206330 <etext+0xa80>
ffffffffc0205160:	3fd00593          	li	a1,1021
ffffffffc0205164:	00002517          	auipc	a0,0x2
ffffffffc0205168:	fb450513          	addi	a0,a0,-76 # ffffffffc0207118 <etext+0x1868>
ffffffffc020516c:	adafb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205170 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205170:	1141                	addi	sp,sp,-16
ffffffffc0205172:	e022                	sd	s0,0(sp)
ffffffffc0205174:	e406                	sd	ra,8(sp)
ffffffffc0205176:	00096417          	auipc	s0,0x96
ffffffffc020517a:	50a40413          	addi	s0,s0,1290 # ffffffffc029b680 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc020517e:	6018                	ld	a4,0(s0)
ffffffffc0205180:	6f1c                	ld	a5,24(a4)
ffffffffc0205182:	dffd                	beqz	a5,ffffffffc0205180 <cpu_idle+0x10>
        {
            schedule();
ffffffffc0205184:	104000ef          	jal	ffffffffc0205288 <schedule>
ffffffffc0205188:	bfdd                	j	ffffffffc020517e <cpu_idle+0xe>

ffffffffc020518a <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020518a:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020518e:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205192:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205194:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205196:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020519a:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020519e:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02051a2:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02051a6:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02051aa:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02051ae:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02051b2:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02051b6:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02051ba:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc02051be:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc02051c2:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc02051c6:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc02051c8:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc02051ca:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc02051ce:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc02051d2:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc02051d6:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc02051da:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc02051de:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc02051e2:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc02051e6:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc02051ea:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02051ee:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02051f2:	8082                	ret

ffffffffc02051f4 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051f4:	4118                	lw	a4,0(a0)
{
ffffffffc02051f6:	1101                	addi	sp,sp,-32
ffffffffc02051f8:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051fa:	478d                	li	a5,3
ffffffffc02051fc:	06f70763          	beq	a4,a5,ffffffffc020526a <wakeup_proc+0x76>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205200:	100027f3          	csrr	a5,sstatus
ffffffffc0205204:	8b89                	andi	a5,a5,2
ffffffffc0205206:	eb91                	bnez	a5,ffffffffc020521a <wakeup_proc+0x26>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205208:	4789                	li	a5,2
ffffffffc020520a:	02f70763          	beq	a4,a5,ffffffffc0205238 <wakeup_proc+0x44>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020520e:	60e2                	ld	ra,24(sp)
            proc->state = PROC_RUNNABLE;
ffffffffc0205210:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc0205212:	0e052623          	sw	zero,236(a0)
}
ffffffffc0205216:	6105                	addi	sp,sp,32
ffffffffc0205218:	8082                	ret
        intr_disable();
ffffffffc020521a:	e42a                	sd	a0,8(sp)
ffffffffc020521c:	ee8fb0ef          	jal	ffffffffc0200904 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205220:	6522                	ld	a0,8(sp)
ffffffffc0205222:	4789                	li	a5,2
ffffffffc0205224:	4118                	lw	a4,0(a0)
ffffffffc0205226:	02f70663          	beq	a4,a5,ffffffffc0205252 <wakeup_proc+0x5e>
            proc->state = PROC_RUNNABLE;
ffffffffc020522a:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc020522c:	0e052623          	sw	zero,236(a0)
}
ffffffffc0205230:	60e2                	ld	ra,24(sp)
ffffffffc0205232:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205234:	ecafb06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc0205238:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc020523a:	00002617          	auipc	a2,0x2
ffffffffc020523e:	31e60613          	addi	a2,a2,798 # ffffffffc0207558 <etext+0x1ca8>
ffffffffc0205242:	45d1                	li	a1,20
ffffffffc0205244:	00002517          	auipc	a0,0x2
ffffffffc0205248:	2fc50513          	addi	a0,a0,764 # ffffffffc0207540 <etext+0x1c90>
}
ffffffffc020524c:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc020524e:	a62fb06f          	j	ffffffffc02004b0 <__warn>
ffffffffc0205252:	00002617          	auipc	a2,0x2
ffffffffc0205256:	30660613          	addi	a2,a2,774 # ffffffffc0207558 <etext+0x1ca8>
ffffffffc020525a:	45d1                	li	a1,20
ffffffffc020525c:	00002517          	auipc	a0,0x2
ffffffffc0205260:	2e450513          	addi	a0,a0,740 # ffffffffc0207540 <etext+0x1c90>
ffffffffc0205264:	a4cfb0ef          	jal	ffffffffc02004b0 <__warn>
    if (flag)
ffffffffc0205268:	b7e1                	j	ffffffffc0205230 <wakeup_proc+0x3c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020526a:	00002697          	auipc	a3,0x2
ffffffffc020526e:	2b668693          	addi	a3,a3,694 # ffffffffc0207520 <etext+0x1c70>
ffffffffc0205272:	00001617          	auipc	a2,0x1
ffffffffc0205276:	0be60613          	addi	a2,a2,190 # ffffffffc0206330 <etext+0xa80>
ffffffffc020527a:	45a5                	li	a1,9
ffffffffc020527c:	00002517          	auipc	a0,0x2
ffffffffc0205280:	2c450513          	addi	a0,a0,708 # ffffffffc0207540 <etext+0x1c90>
ffffffffc0205284:	9c2fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205288 <schedule>:

void schedule(void)
{
ffffffffc0205288:	1101                	addi	sp,sp,-32
ffffffffc020528a:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020528c:	100027f3          	csrr	a5,sstatus
ffffffffc0205290:	8b89                	andi	a5,a5,2
ffffffffc0205292:	4301                	li	t1,0
ffffffffc0205294:	e3c1                	bnez	a5,ffffffffc0205314 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205296:	00096897          	auipc	a7,0x96
ffffffffc020529a:	3ea8b883          	ld	a7,1002(a7) # ffffffffc029b680 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020529e:	00096517          	auipc	a0,0x96
ffffffffc02052a2:	3f253503          	ld	a0,1010(a0) # ffffffffc029b690 <idleproc>
        current->need_resched = 0;
ffffffffc02052a6:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02052aa:	04a88f63          	beq	a7,a0,ffffffffc0205308 <schedule+0x80>
ffffffffc02052ae:	0c888693          	addi	a3,a7,200
ffffffffc02052b2:	00096617          	auipc	a2,0x96
ffffffffc02052b6:	35660613          	addi	a2,a2,854 # ffffffffc029b608 <proc_list>
        le = last;
ffffffffc02052ba:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02052bc:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc02052be:	4809                	li	a6,2
ffffffffc02052c0:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc02052c2:	00c78863          	beq	a5,a2,ffffffffc02052d2 <schedule+0x4a>
                if (next->state == PROC_RUNNABLE)
ffffffffc02052c6:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02052ca:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc02052ce:	03070363          	beq	a4,a6,ffffffffc02052f4 <schedule+0x6c>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc02052d2:	fef697e3          	bne	a3,a5,ffffffffc02052c0 <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02052d6:	ed99                	bnez	a1,ffffffffc02052f4 <schedule+0x6c>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02052d8:	451c                	lw	a5,8(a0)
ffffffffc02052da:	2785                	addiw	a5,a5,1
ffffffffc02052dc:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc02052de:	00a88663          	beq	a7,a0,ffffffffc02052ea <schedule+0x62>
ffffffffc02052e2:	e41a                	sd	t1,8(sp)
        {
            proc_run(next);
ffffffffc02052e4:	d37fe0ef          	jal	ffffffffc020401a <proc_run>
ffffffffc02052e8:	6322                	ld	t1,8(sp)
    if (flag)
ffffffffc02052ea:	00031b63          	bnez	t1,ffffffffc0205300 <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02052ee:	60e2                	ld	ra,24(sp)
ffffffffc02052f0:	6105                	addi	sp,sp,32
ffffffffc02052f2:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc02052f4:	4198                	lw	a4,0(a1)
ffffffffc02052f6:	4789                	li	a5,2
ffffffffc02052f8:	fef710e3          	bne	a4,a5,ffffffffc02052d8 <schedule+0x50>
ffffffffc02052fc:	852e                	mv	a0,a1
ffffffffc02052fe:	bfe9                	j	ffffffffc02052d8 <schedule+0x50>
}
ffffffffc0205300:	60e2                	ld	ra,24(sp)
ffffffffc0205302:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205304:	dfafb06f          	j	ffffffffc02008fe <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205308:	00096617          	auipc	a2,0x96
ffffffffc020530c:	30060613          	addi	a2,a2,768 # ffffffffc029b608 <proc_list>
ffffffffc0205310:	86b2                	mv	a3,a2
ffffffffc0205312:	b765                	j	ffffffffc02052ba <schedule+0x32>
        intr_disable();
ffffffffc0205314:	df0fb0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0205318:	4305                	li	t1,1
ffffffffc020531a:	bfb5                	j	ffffffffc0205296 <schedule+0xe>

ffffffffc020531c <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc020531c:	00096797          	auipc	a5,0x96
ffffffffc0205320:	3647b783          	ld	a5,868(a5) # ffffffffc029b680 <current>
}
ffffffffc0205324:	43c8                	lw	a0,4(a5)
ffffffffc0205326:	8082                	ret

ffffffffc0205328 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205328:	4501                	li	a0,0
ffffffffc020532a:	8082                	ret

ffffffffc020532c <sys_putc>:
    cputchar(c);
ffffffffc020532c:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc020532e:	1141                	addi	sp,sp,-16
ffffffffc0205330:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205332:	e97fa0ef          	jal	ffffffffc02001c8 <cputchar>
}
ffffffffc0205336:	60a2                	ld	ra,8(sp)
ffffffffc0205338:	4501                	li	a0,0
ffffffffc020533a:	0141                	addi	sp,sp,16
ffffffffc020533c:	8082                	ret

ffffffffc020533e <sys_kill>:
    return do_kill(pid);
ffffffffc020533e:	4108                	lw	a0,0(a0)
ffffffffc0205340:	c0fff06f          	j	ffffffffc0204f4e <do_kill>

ffffffffc0205344 <sys_yield>:
    return do_yield();
ffffffffc0205344:	bc1ff06f          	j	ffffffffc0204f04 <do_yield>

ffffffffc0205348 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0205348:	6d14                	ld	a3,24(a0)
ffffffffc020534a:	6910                	ld	a2,16(a0)
ffffffffc020534c:	650c                	ld	a1,8(a0)
ffffffffc020534e:	6108                	ld	a0,0(a0)
ffffffffc0205350:	e18ff06f          	j	ffffffffc0204968 <do_execve>

ffffffffc0205354 <sys_wait>:
    return do_wait(pid, store);
ffffffffc0205354:	650c                	ld	a1,8(a0)
ffffffffc0205356:	4108                	lw	a0,0(a0)
ffffffffc0205358:	bbdff06f          	j	ffffffffc0204f14 <do_wait>

ffffffffc020535c <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc020535c:	00096797          	auipc	a5,0x96
ffffffffc0205360:	3247b783          	ld	a5,804(a5) # ffffffffc029b680 <current>
    return do_fork(0, stack, tf);
ffffffffc0205364:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc0205366:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc0205368:	6a0c                	ld	a1,16(a2)
ffffffffc020536a:	d13fe06f          	j	ffffffffc020407c <do_fork>

ffffffffc020536e <sys_exit>:
    return do_exit(error_code);
ffffffffc020536e:	4108                	lw	a0,0(a0)
ffffffffc0205370:	9aeff06f          	j	ffffffffc020451e <do_exit>

ffffffffc0205374 <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc0205374:	00096697          	auipc	a3,0x96
ffffffffc0205378:	30c6b683          	ld	a3,780(a3) # ffffffffc029b680 <current>
syscall(void) {
ffffffffc020537c:	715d                	addi	sp,sp,-80
ffffffffc020537e:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205380:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc0205382:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205384:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc0205386:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205388:	02d7ec63          	bltu	a5,a3,ffffffffc02053c0 <syscall+0x4c>
        if (syscalls[num] != NULL) {
ffffffffc020538c:	00002797          	auipc	a5,0x2
ffffffffc0205390:	41478793          	addi	a5,a5,1044 # ffffffffc02077a0 <syscalls>
ffffffffc0205394:	00369613          	slli	a2,a3,0x3
ffffffffc0205398:	97b2                	add	a5,a5,a2
ffffffffc020539a:	639c                	ld	a5,0(a5)
ffffffffc020539c:	c395                	beqz	a5,ffffffffc02053c0 <syscall+0x4c>
            arg[0] = tf->gpr.a1;
ffffffffc020539e:	7028                	ld	a0,96(s0)
ffffffffc02053a0:	742c                	ld	a1,104(s0)
ffffffffc02053a2:	7830                	ld	a2,112(s0)
ffffffffc02053a4:	7c34                	ld	a3,120(s0)
ffffffffc02053a6:	6c38                	ld	a4,88(s0)
ffffffffc02053a8:	f02a                	sd	a0,32(sp)
ffffffffc02053aa:	f42e                	sd	a1,40(sp)
ffffffffc02053ac:	f832                	sd	a2,48(sp)
ffffffffc02053ae:	fc36                	sd	a3,56(sp)
ffffffffc02053b0:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053b2:	0828                	addi	a0,sp,24
ffffffffc02053b4:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc02053b6:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc02053b8:	e828                	sd	a0,80(s0)
}
ffffffffc02053ba:	6406                	ld	s0,64(sp)
ffffffffc02053bc:	6161                	addi	sp,sp,80
ffffffffc02053be:	8082                	ret
    print_trapframe(tf);
ffffffffc02053c0:	8522                	mv	a0,s0
ffffffffc02053c2:	e436                	sd	a3,8(sp)
ffffffffc02053c4:	f30fb0ef          	jal	ffffffffc0200af4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc02053c8:	00096797          	auipc	a5,0x96
ffffffffc02053cc:	2b87b783          	ld	a5,696(a5) # ffffffffc029b680 <current>
ffffffffc02053d0:	66a2                	ld	a3,8(sp)
ffffffffc02053d2:	00002617          	auipc	a2,0x2
ffffffffc02053d6:	1a660613          	addi	a2,a2,422 # ffffffffc0207578 <etext+0x1cc8>
ffffffffc02053da:	43d8                	lw	a4,4(a5)
ffffffffc02053dc:	06200593          	li	a1,98
ffffffffc02053e0:	0b478793          	addi	a5,a5,180
ffffffffc02053e4:	00002517          	auipc	a0,0x2
ffffffffc02053e8:	1c450513          	addi	a0,a0,452 # ffffffffc02075a8 <etext+0x1cf8>
ffffffffc02053ec:	85afb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02053f0 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02053f0:	9e3707b7          	lui	a5,0x9e370
ffffffffc02053f4:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_exit_out_size+0xffffffff9e365e49>
ffffffffc02053f6:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc02053fa:	02000513          	li	a0,32
ffffffffc02053fe:	9d0d                	subw	a0,a0,a1
}
ffffffffc0205400:	00a7d53b          	srlw	a0,a5,a0
ffffffffc0205404:	8082                	ret

ffffffffc0205406 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205406:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205408:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020540c:	f022                	sd	s0,32(sp)
ffffffffc020540e:	ec26                	sd	s1,24(sp)
ffffffffc0205410:	e84a                	sd	s2,16(sp)
ffffffffc0205412:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205414:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205418:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc020541a:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020541e:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205422:	84aa                	mv	s1,a0
ffffffffc0205424:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0205426:	03067d63          	bgeu	a2,a6,ffffffffc0205460 <printnum+0x5a>
ffffffffc020542a:	e44e                	sd	s3,8(sp)
ffffffffc020542c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020542e:	4785                	li	a5,1
ffffffffc0205430:	00e7d763          	bge	a5,a4,ffffffffc020543e <printnum+0x38>
            putch(padc, putdat);
ffffffffc0205434:	85ca                	mv	a1,s2
ffffffffc0205436:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0205438:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020543a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020543c:	fc65                	bnez	s0,ffffffffc0205434 <printnum+0x2e>
ffffffffc020543e:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205440:	00002797          	auipc	a5,0x2
ffffffffc0205444:	18078793          	addi	a5,a5,384 # ffffffffc02075c0 <etext+0x1d10>
ffffffffc0205448:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020544a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020544c:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0205450:	70a2                	ld	ra,40(sp)
ffffffffc0205452:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205454:	85ca                	mv	a1,s2
ffffffffc0205456:	87a6                	mv	a5,s1
}
ffffffffc0205458:	6942                	ld	s2,16(sp)
ffffffffc020545a:	64e2                	ld	s1,24(sp)
ffffffffc020545c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020545e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0205460:	03065633          	divu	a2,a2,a6
ffffffffc0205464:	8722                	mv	a4,s0
ffffffffc0205466:	fa1ff0ef          	jal	ffffffffc0205406 <printnum>
ffffffffc020546a:	bfd9                	j	ffffffffc0205440 <printnum+0x3a>

ffffffffc020546c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020546c:	7119                	addi	sp,sp,-128
ffffffffc020546e:	f4a6                	sd	s1,104(sp)
ffffffffc0205470:	f0ca                	sd	s2,96(sp)
ffffffffc0205472:	ecce                	sd	s3,88(sp)
ffffffffc0205474:	e8d2                	sd	s4,80(sp)
ffffffffc0205476:	e4d6                	sd	s5,72(sp)
ffffffffc0205478:	e0da                	sd	s6,64(sp)
ffffffffc020547a:	f862                	sd	s8,48(sp)
ffffffffc020547c:	fc86                	sd	ra,120(sp)
ffffffffc020547e:	f8a2                	sd	s0,112(sp)
ffffffffc0205480:	fc5e                	sd	s7,56(sp)
ffffffffc0205482:	f466                	sd	s9,40(sp)
ffffffffc0205484:	f06a                	sd	s10,32(sp)
ffffffffc0205486:	ec6e                	sd	s11,24(sp)
ffffffffc0205488:	84aa                	mv	s1,a0
ffffffffc020548a:	8c32                	mv	s8,a2
ffffffffc020548c:	8a36                	mv	s4,a3
ffffffffc020548e:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205490:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205494:	05500b13          	li	s6,85
ffffffffc0205498:	00002a97          	auipc	s5,0x2
ffffffffc020549c:	408a8a93          	addi	s5,s5,1032 # ffffffffc02078a0 <syscalls+0x100>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054a0:	000c4503          	lbu	a0,0(s8)
ffffffffc02054a4:	001c0413          	addi	s0,s8,1
ffffffffc02054a8:	01350a63          	beq	a0,s3,ffffffffc02054bc <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02054ac:	cd0d                	beqz	a0,ffffffffc02054e6 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02054ae:	85ca                	mv	a1,s2
ffffffffc02054b0:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02054b2:	00044503          	lbu	a0,0(s0)
ffffffffc02054b6:	0405                	addi	s0,s0,1
ffffffffc02054b8:	ff351ae3          	bne	a0,s3,ffffffffc02054ac <vprintfmt+0x40>
        width = precision = -1;
ffffffffc02054bc:	5cfd                	li	s9,-1
ffffffffc02054be:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc02054c0:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02054c4:	4b81                	li	s7,0
ffffffffc02054c6:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054c8:	00044683          	lbu	a3,0(s0)
ffffffffc02054cc:	00140c13          	addi	s8,s0,1
ffffffffc02054d0:	fdd6859b          	addiw	a1,a3,-35
ffffffffc02054d4:	0ff5f593          	zext.b	a1,a1
ffffffffc02054d8:	02bb6663          	bltu	s6,a1,ffffffffc0205504 <vprintfmt+0x98>
ffffffffc02054dc:	058a                	slli	a1,a1,0x2
ffffffffc02054de:	95d6                	add	a1,a1,s5
ffffffffc02054e0:	4198                	lw	a4,0(a1)
ffffffffc02054e2:	9756                	add	a4,a4,s5
ffffffffc02054e4:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02054e6:	70e6                	ld	ra,120(sp)
ffffffffc02054e8:	7446                	ld	s0,112(sp)
ffffffffc02054ea:	74a6                	ld	s1,104(sp)
ffffffffc02054ec:	7906                	ld	s2,96(sp)
ffffffffc02054ee:	69e6                	ld	s3,88(sp)
ffffffffc02054f0:	6a46                	ld	s4,80(sp)
ffffffffc02054f2:	6aa6                	ld	s5,72(sp)
ffffffffc02054f4:	6b06                	ld	s6,64(sp)
ffffffffc02054f6:	7be2                	ld	s7,56(sp)
ffffffffc02054f8:	7c42                	ld	s8,48(sp)
ffffffffc02054fa:	7ca2                	ld	s9,40(sp)
ffffffffc02054fc:	7d02                	ld	s10,32(sp)
ffffffffc02054fe:	6de2                	ld	s11,24(sp)
ffffffffc0205500:	6109                	addi	sp,sp,128
ffffffffc0205502:	8082                	ret
            putch('%', putdat);
ffffffffc0205504:	85ca                	mv	a1,s2
ffffffffc0205506:	02500513          	li	a0,37
ffffffffc020550a:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020550c:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205510:	02500713          	li	a4,37
ffffffffc0205514:	8c22                	mv	s8,s0
ffffffffc0205516:	f8e785e3          	beq	a5,a4,ffffffffc02054a0 <vprintfmt+0x34>
ffffffffc020551a:	ffec4783          	lbu	a5,-2(s8)
ffffffffc020551e:	1c7d                	addi	s8,s8,-1
ffffffffc0205520:	fee79de3          	bne	a5,a4,ffffffffc020551a <vprintfmt+0xae>
ffffffffc0205524:	bfb5                	j	ffffffffc02054a0 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0205526:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc020552a:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc020552c:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0205530:	fd06071b          	addiw	a4,a2,-48
ffffffffc0205534:	24e56a63          	bltu	a0,a4,ffffffffc0205788 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0205538:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020553a:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc020553c:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0205540:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205544:	0197073b          	addw	a4,a4,s9
ffffffffc0205548:	0017171b          	slliw	a4,a4,0x1
ffffffffc020554c:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc020554e:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0205552:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0205554:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0205558:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc020555c:	feb570e3          	bgeu	a0,a1,ffffffffc020553c <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0205560:	f60d54e3          	bgez	s10,ffffffffc02054c8 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0205564:	8d66                	mv	s10,s9
ffffffffc0205566:	5cfd                	li	s9,-1
ffffffffc0205568:	b785                	j	ffffffffc02054c8 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020556a:	8db6                	mv	s11,a3
ffffffffc020556c:	8462                	mv	s0,s8
ffffffffc020556e:	bfa9                	j	ffffffffc02054c8 <vprintfmt+0x5c>
ffffffffc0205570:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0205572:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0205574:	bf91                	j	ffffffffc02054c8 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0205576:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205578:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020557c:	00f74463          	blt	a4,a5,ffffffffc0205584 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0205580:	1a078763          	beqz	a5,ffffffffc020572e <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0205584:	000a3603          	ld	a2,0(s4)
ffffffffc0205588:	46c1                	li	a3,16
ffffffffc020558a:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020558c:	000d879b          	sext.w	a5,s11
ffffffffc0205590:	876a                	mv	a4,s10
ffffffffc0205592:	85ca                	mv	a1,s2
ffffffffc0205594:	8526                	mv	a0,s1
ffffffffc0205596:	e71ff0ef          	jal	ffffffffc0205406 <printnum>
            break;
ffffffffc020559a:	b719                	j	ffffffffc02054a0 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc020559c:	000a2503          	lw	a0,0(s4)
ffffffffc02055a0:	85ca                	mv	a1,s2
ffffffffc02055a2:	0a21                	addi	s4,s4,8
ffffffffc02055a4:	9482                	jalr	s1
            break;
ffffffffc02055a6:	bded                	j	ffffffffc02054a0 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02055a8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055aa:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055ae:	00f74463          	blt	a4,a5,ffffffffc02055b6 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02055b2:	16078963          	beqz	a5,ffffffffc0205724 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc02055b6:	000a3603          	ld	a2,0(s4)
ffffffffc02055ba:	46a9                	li	a3,10
ffffffffc02055bc:	8a2e                	mv	s4,a1
ffffffffc02055be:	b7f9                	j	ffffffffc020558c <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc02055c0:	85ca                	mv	a1,s2
ffffffffc02055c2:	03000513          	li	a0,48
ffffffffc02055c6:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc02055c8:	85ca                	mv	a1,s2
ffffffffc02055ca:	07800513          	li	a0,120
ffffffffc02055ce:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055d0:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02055d4:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02055d6:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02055d8:	bf55                	j	ffffffffc020558c <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc02055da:	85ca                	mv	a1,s2
ffffffffc02055dc:	02500513          	li	a0,37
ffffffffc02055e0:	9482                	jalr	s1
            break;
ffffffffc02055e2:	bd7d                	j	ffffffffc02054a0 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02055e4:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02055e8:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02055ea:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02055ec:	bf95                	j	ffffffffc0205560 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc02055ee:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02055f0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02055f4:	00f74463          	blt	a4,a5,ffffffffc02055fc <vprintfmt+0x190>
    else if (lflag) {
ffffffffc02055f8:	12078163          	beqz	a5,ffffffffc020571a <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc02055fc:	000a3603          	ld	a2,0(s4)
ffffffffc0205600:	46a1                	li	a3,8
ffffffffc0205602:	8a2e                	mv	s4,a1
ffffffffc0205604:	b761                	j	ffffffffc020558c <vprintfmt+0x120>
            if (width < 0)
ffffffffc0205606:	876a                	mv	a4,s10
ffffffffc0205608:	000d5363          	bgez	s10,ffffffffc020560e <vprintfmt+0x1a2>
ffffffffc020560c:	4701                	li	a4,0
ffffffffc020560e:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205612:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0205614:	bd55                	j	ffffffffc02054c8 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0205616:	000d841b          	sext.w	s0,s11
ffffffffc020561a:	fd340793          	addi	a5,s0,-45
ffffffffc020561e:	00f037b3          	snez	a5,a5
ffffffffc0205622:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205626:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc020562a:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020562c:	008a0793          	addi	a5,s4,8
ffffffffc0205630:	e43e                	sd	a5,8(sp)
ffffffffc0205632:	100d8c63          	beqz	s11,ffffffffc020574a <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0205636:	12071363          	bnez	a4,ffffffffc020575c <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020563a:	000dc783          	lbu	a5,0(s11)
ffffffffc020563e:	0007851b          	sext.w	a0,a5
ffffffffc0205642:	c78d                	beqz	a5,ffffffffc020566c <vprintfmt+0x200>
ffffffffc0205644:	0d85                	addi	s11,s11,1
ffffffffc0205646:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205648:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020564c:	000cc563          	bltz	s9,ffffffffc0205656 <vprintfmt+0x1ea>
ffffffffc0205650:	3cfd                	addiw	s9,s9,-1
ffffffffc0205652:	008c8d63          	beq	s9,s0,ffffffffc020566c <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205656:	020b9663          	bnez	s7,ffffffffc0205682 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc020565a:	85ca                	mv	a1,s2
ffffffffc020565c:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020565e:	000dc783          	lbu	a5,0(s11)
ffffffffc0205662:	0d85                	addi	s11,s11,1
ffffffffc0205664:	3d7d                	addiw	s10,s10,-1
ffffffffc0205666:	0007851b          	sext.w	a0,a5
ffffffffc020566a:	f3ed                	bnez	a5,ffffffffc020564c <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc020566c:	01a05963          	blez	s10,ffffffffc020567e <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0205670:	85ca                	mv	a1,s2
ffffffffc0205672:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0205676:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0205678:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc020567a:	fe0d1be3          	bnez	s10,ffffffffc0205670 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020567e:	6a22                	ld	s4,8(sp)
ffffffffc0205680:	b505                	j	ffffffffc02054a0 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0205682:	3781                	addiw	a5,a5,-32
ffffffffc0205684:	fcfa7be3          	bgeu	s4,a5,ffffffffc020565a <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0205688:	03f00513          	li	a0,63
ffffffffc020568c:	85ca                	mv	a1,s2
ffffffffc020568e:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205690:	000dc783          	lbu	a5,0(s11)
ffffffffc0205694:	0d85                	addi	s11,s11,1
ffffffffc0205696:	3d7d                	addiw	s10,s10,-1
ffffffffc0205698:	0007851b          	sext.w	a0,a5
ffffffffc020569c:	dbe1                	beqz	a5,ffffffffc020566c <vprintfmt+0x200>
ffffffffc020569e:	fa0cd9e3          	bgez	s9,ffffffffc0205650 <vprintfmt+0x1e4>
ffffffffc02056a2:	b7c5                	j	ffffffffc0205682 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc02056a4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056a8:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc02056aa:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02056ac:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02056b0:	8fb9                	xor	a5,a5,a4
ffffffffc02056b2:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02056b6:	02d64563          	blt	a2,a3,ffffffffc02056e0 <vprintfmt+0x274>
ffffffffc02056ba:	00002797          	auipc	a5,0x2
ffffffffc02056be:	33e78793          	addi	a5,a5,830 # ffffffffc02079f8 <error_string>
ffffffffc02056c2:	00369713          	slli	a4,a3,0x3
ffffffffc02056c6:	97ba                	add	a5,a5,a4
ffffffffc02056c8:	639c                	ld	a5,0(a5)
ffffffffc02056ca:	cb99                	beqz	a5,ffffffffc02056e0 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc02056cc:	86be                	mv	a3,a5
ffffffffc02056ce:	00000617          	auipc	a2,0x0
ffffffffc02056d2:	20a60613          	addi	a2,a2,522 # ffffffffc02058d8 <etext+0x28>
ffffffffc02056d6:	85ca                	mv	a1,s2
ffffffffc02056d8:	8526                	mv	a0,s1
ffffffffc02056da:	0d8000ef          	jal	ffffffffc02057b2 <printfmt>
ffffffffc02056de:	b3c9                	j	ffffffffc02054a0 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02056e0:	00002617          	auipc	a2,0x2
ffffffffc02056e4:	f0060613          	addi	a2,a2,-256 # ffffffffc02075e0 <etext+0x1d30>
ffffffffc02056e8:	85ca                	mv	a1,s2
ffffffffc02056ea:	8526                	mv	a0,s1
ffffffffc02056ec:	0c6000ef          	jal	ffffffffc02057b2 <printfmt>
ffffffffc02056f0:	bb45                	j	ffffffffc02054a0 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02056f2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02056f4:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc02056f8:	00f74363          	blt	a4,a5,ffffffffc02056fe <vprintfmt+0x292>
    else if (lflag) {
ffffffffc02056fc:	cf81                	beqz	a5,ffffffffc0205714 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc02056fe:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205702:	02044b63          	bltz	s0,ffffffffc0205738 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0205706:	8622                	mv	a2,s0
ffffffffc0205708:	8a5e                	mv	s4,s7
ffffffffc020570a:	46a9                	li	a3,10
ffffffffc020570c:	b541                	j	ffffffffc020558c <vprintfmt+0x120>
            lflag ++;
ffffffffc020570e:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205710:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0205712:	bb5d                	j	ffffffffc02054c8 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0205714:	000a2403          	lw	s0,0(s4)
ffffffffc0205718:	b7ed                	j	ffffffffc0205702 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc020571a:	000a6603          	lwu	a2,0(s4)
ffffffffc020571e:	46a1                	li	a3,8
ffffffffc0205720:	8a2e                	mv	s4,a1
ffffffffc0205722:	b5ad                	j	ffffffffc020558c <vprintfmt+0x120>
ffffffffc0205724:	000a6603          	lwu	a2,0(s4)
ffffffffc0205728:	46a9                	li	a3,10
ffffffffc020572a:	8a2e                	mv	s4,a1
ffffffffc020572c:	b585                	j	ffffffffc020558c <vprintfmt+0x120>
ffffffffc020572e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205732:	46c1                	li	a3,16
ffffffffc0205734:	8a2e                	mv	s4,a1
ffffffffc0205736:	bd99                	j	ffffffffc020558c <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0205738:	85ca                	mv	a1,s2
ffffffffc020573a:	02d00513          	li	a0,45
ffffffffc020573e:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0205740:	40800633          	neg	a2,s0
ffffffffc0205744:	8a5e                	mv	s4,s7
ffffffffc0205746:	46a9                	li	a3,10
ffffffffc0205748:	b591                	j	ffffffffc020558c <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc020574a:	e329                	bnez	a4,ffffffffc020578c <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020574c:	02800793          	li	a5,40
ffffffffc0205750:	853e                	mv	a0,a5
ffffffffc0205752:	00002d97          	auipc	s11,0x2
ffffffffc0205756:	e87d8d93          	addi	s11,s11,-377 # ffffffffc02075d9 <etext+0x1d29>
ffffffffc020575a:	b5f5                	j	ffffffffc0205646 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020575c:	85e6                	mv	a1,s9
ffffffffc020575e:	856e                	mv	a0,s11
ffffffffc0205760:	08a000ef          	jal	ffffffffc02057ea <strnlen>
ffffffffc0205764:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0205768:	01a05863          	blez	s10,ffffffffc0205778 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc020576c:	85ca                	mv	a1,s2
ffffffffc020576e:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205770:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0205772:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205774:	fe0d1ce3          	bnez	s10,ffffffffc020576c <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205778:	000dc783          	lbu	a5,0(s11)
ffffffffc020577c:	0007851b          	sext.w	a0,a5
ffffffffc0205780:	ec0792e3          	bnez	a5,ffffffffc0205644 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205784:	6a22                	ld	s4,8(sp)
ffffffffc0205786:	bb29                	j	ffffffffc02054a0 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205788:	8462                	mv	s0,s8
ffffffffc020578a:	bbd9                	j	ffffffffc0205560 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020578c:	85e6                	mv	a1,s9
ffffffffc020578e:	00002517          	auipc	a0,0x2
ffffffffc0205792:	e4a50513          	addi	a0,a0,-438 # ffffffffc02075d8 <etext+0x1d28>
ffffffffc0205796:	054000ef          	jal	ffffffffc02057ea <strnlen>
ffffffffc020579a:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020579e:	02800793          	li	a5,40
                p = "(null)";
ffffffffc02057a2:	00002d97          	auipc	s11,0x2
ffffffffc02057a6:	e36d8d93          	addi	s11,s11,-458 # ffffffffc02075d8 <etext+0x1d28>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02057aa:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02057ac:	fda040e3          	bgtz	s10,ffffffffc020576c <vprintfmt+0x300>
ffffffffc02057b0:	bd51                	j	ffffffffc0205644 <vprintfmt+0x1d8>

ffffffffc02057b2 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057b2:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02057b4:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057b8:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057ba:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02057bc:	ec06                	sd	ra,24(sp)
ffffffffc02057be:	f83a                	sd	a4,48(sp)
ffffffffc02057c0:	fc3e                	sd	a5,56(sp)
ffffffffc02057c2:	e0c2                	sd	a6,64(sp)
ffffffffc02057c4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02057c6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02057c8:	ca5ff0ef          	jal	ffffffffc020546c <vprintfmt>
}
ffffffffc02057cc:	60e2                	ld	ra,24(sp)
ffffffffc02057ce:	6161                	addi	sp,sp,80
ffffffffc02057d0:	8082                	ret

ffffffffc02057d2 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02057d2:	00054783          	lbu	a5,0(a0)
ffffffffc02057d6:	cb81                	beqz	a5,ffffffffc02057e6 <strlen+0x14>
    size_t cnt = 0;
ffffffffc02057d8:	4781                	li	a5,0
        cnt ++;
ffffffffc02057da:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02057dc:	00f50733          	add	a4,a0,a5
ffffffffc02057e0:	00074703          	lbu	a4,0(a4)
ffffffffc02057e4:	fb7d                	bnez	a4,ffffffffc02057da <strlen+0x8>
    }
    return cnt;
}
ffffffffc02057e6:	853e                	mv	a0,a5
ffffffffc02057e8:	8082                	ret

ffffffffc02057ea <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02057ea:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057ec:	e589                	bnez	a1,ffffffffc02057f6 <strnlen+0xc>
ffffffffc02057ee:	a811                	j	ffffffffc0205802 <strnlen+0x18>
        cnt ++;
ffffffffc02057f0:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02057f2:	00f58863          	beq	a1,a5,ffffffffc0205802 <strnlen+0x18>
ffffffffc02057f6:	00f50733          	add	a4,a0,a5
ffffffffc02057fa:	00074703          	lbu	a4,0(a4)
ffffffffc02057fe:	fb6d                	bnez	a4,ffffffffc02057f0 <strnlen+0x6>
ffffffffc0205800:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205802:	852e                	mv	a0,a1
ffffffffc0205804:	8082                	ret

ffffffffc0205806 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205806:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205808:	0005c703          	lbu	a4,0(a1)
ffffffffc020580c:	0585                	addi	a1,a1,1
ffffffffc020580e:	0785                	addi	a5,a5,1
ffffffffc0205810:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205814:	fb75                	bnez	a4,ffffffffc0205808 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205816:	8082                	ret

ffffffffc0205818 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205818:	00054783          	lbu	a5,0(a0)
ffffffffc020581c:	e791                	bnez	a5,ffffffffc0205828 <strcmp+0x10>
ffffffffc020581e:	a01d                	j	ffffffffc0205844 <strcmp+0x2c>
ffffffffc0205820:	00054783          	lbu	a5,0(a0)
ffffffffc0205824:	cb99                	beqz	a5,ffffffffc020583a <strcmp+0x22>
ffffffffc0205826:	0585                	addi	a1,a1,1
ffffffffc0205828:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc020582c:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020582e:	fef709e3          	beq	a4,a5,ffffffffc0205820 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205832:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205836:	9d19                	subw	a0,a0,a4
ffffffffc0205838:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020583a:	0015c703          	lbu	a4,1(a1)
ffffffffc020583e:	4501                	li	a0,0
}
ffffffffc0205840:	9d19                	subw	a0,a0,a4
ffffffffc0205842:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205844:	0005c703          	lbu	a4,0(a1)
ffffffffc0205848:	4501                	li	a0,0
ffffffffc020584a:	b7f5                	j	ffffffffc0205836 <strcmp+0x1e>

ffffffffc020584c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020584c:	ce01                	beqz	a2,ffffffffc0205864 <strncmp+0x18>
ffffffffc020584e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205852:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205854:	cb91                	beqz	a5,ffffffffc0205868 <strncmp+0x1c>
ffffffffc0205856:	0005c703          	lbu	a4,0(a1)
ffffffffc020585a:	00f71763          	bne	a4,a5,ffffffffc0205868 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc020585e:	0505                	addi	a0,a0,1
ffffffffc0205860:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205862:	f675                	bnez	a2,ffffffffc020584e <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205864:	4501                	li	a0,0
ffffffffc0205866:	8082                	ret
ffffffffc0205868:	00054503          	lbu	a0,0(a0)
ffffffffc020586c:	0005c783          	lbu	a5,0(a1)
ffffffffc0205870:	9d1d                	subw	a0,a0,a5
}
ffffffffc0205872:	8082                	ret

ffffffffc0205874 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205874:	a021                	j	ffffffffc020587c <strchr+0x8>
        if (*s == c) {
ffffffffc0205876:	00f58763          	beq	a1,a5,ffffffffc0205884 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc020587a:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc020587c:	00054783          	lbu	a5,0(a0)
ffffffffc0205880:	fbfd                	bnez	a5,ffffffffc0205876 <strchr+0x2>
    }
    return NULL;
ffffffffc0205882:	4501                	li	a0,0
}
ffffffffc0205884:	8082                	ret

ffffffffc0205886 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205886:	ca01                	beqz	a2,ffffffffc0205896 <memset+0x10>
ffffffffc0205888:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020588a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020588c:	0785                	addi	a5,a5,1
ffffffffc020588e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205892:	fef61de3          	bne	a2,a5,ffffffffc020588c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205896:	8082                	ret

ffffffffc0205898 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205898:	ca19                	beqz	a2,ffffffffc02058ae <memcpy+0x16>
ffffffffc020589a:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020589c:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020589e:	0005c703          	lbu	a4,0(a1)
ffffffffc02058a2:	0585                	addi	a1,a1,1
ffffffffc02058a4:	0785                	addi	a5,a5,1
ffffffffc02058a6:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02058aa:	feb61ae3          	bne	a2,a1,ffffffffc020589e <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02058ae:	8082                	ret
