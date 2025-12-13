
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
ffffffffc0200062:	7ac050ef          	jal	ffffffffc020580e <memset>
    dtb_init();
ffffffffc0200066:	552000ef          	jal	ffffffffc02005b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	4dc000ef          	jal	ffffffffc0200546 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	7ca58593          	addi	a1,a1,1994 # ffffffffc0205838 <etext>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	7e250513          	addi	a0,a0,2018 # ffffffffc0205858 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1a4000ef          	jal	ffffffffc0200226 <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	6e8020ef          	jal	ffffffffc020276e <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	081000ef          	jal	ffffffffc020090a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	07f000ef          	jal	ffffffffc020090c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	1d5030ef          	jal	ffffffffc0203a66 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	6b9040ef          	jal	ffffffffc0204f4e <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	45a000ef          	jal	ffffffffc02004f4 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	061000ef          	jal	ffffffffc02008fe <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	056050ef          	jal	ffffffffc02050f8 <cpu_idle>

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
ffffffffc02000b6:	00005517          	auipc	a0,0x5
ffffffffc02000ba:	7aa50513          	addi	a0,a0,1962 # ffffffffc0205860 <etext+0x28>
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
ffffffffc0200188:	26c050ef          	jal	ffffffffc02053f4 <vprintfmt>
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
ffffffffc02001bc:	238050ef          	jal	ffffffffc02053f4 <vprintfmt>
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
ffffffffc020022c:	64050513          	addi	a0,a0,1600 # ffffffffc0205868 <etext+0x30>
{
ffffffffc0200230:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200232:	f63ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200236:	00000597          	auipc	a1,0x0
ffffffffc020023a:	e1458593          	addi	a1,a1,-492 # ffffffffc020004a <kern_init>
ffffffffc020023e:	00005517          	auipc	a0,0x5
ffffffffc0200242:	64a50513          	addi	a0,a0,1610 # ffffffffc0205888 <etext+0x50>
ffffffffc0200246:	f4fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024a:	00005597          	auipc	a1,0x5
ffffffffc020024e:	5ee58593          	addi	a1,a1,1518 # ffffffffc0205838 <etext>
ffffffffc0200252:	00005517          	auipc	a0,0x5
ffffffffc0200256:	65650513          	addi	a0,a0,1622 # ffffffffc02058a8 <etext+0x70>
ffffffffc020025a:	f3bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020025e:	00097597          	auipc	a1,0x97
ffffffffc0200262:	f9258593          	addi	a1,a1,-110 # ffffffffc02971f0 <buf>
ffffffffc0200266:	00005517          	auipc	a0,0x5
ffffffffc020026a:	66250513          	addi	a0,a0,1634 # ffffffffc02058c8 <etext+0x90>
ffffffffc020026e:	f27ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200272:	0009b597          	auipc	a1,0x9b
ffffffffc0200276:	42658593          	addi	a1,a1,1062 # ffffffffc029b698 <end>
ffffffffc020027a:	00005517          	auipc	a0,0x5
ffffffffc020027e:	66e50513          	addi	a0,a0,1646 # ffffffffc02058e8 <etext+0xb0>
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
ffffffffc02002aa:	66250513          	addi	a0,a0,1634 # ffffffffc0205908 <etext+0xd0>
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
ffffffffc02002b8:	68460613          	addi	a2,a2,1668 # ffffffffc0205938 <etext+0x100>
ffffffffc02002bc:	04f00593          	li	a1,79
ffffffffc02002c0:	00005517          	auipc	a0,0x5
ffffffffc02002c4:	69050513          	addi	a0,a0,1680 # ffffffffc0205950 <etext+0x118>
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
ffffffffc02002da:	2c240413          	addi	s0,s0,706 # ffffffffc0207598 <commands>
ffffffffc02002de:	00007497          	auipc	s1,0x7
ffffffffc02002e2:	30248493          	addi	s1,s1,770 # ffffffffc02075e0 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	6410                	ld	a2,8(s0)
ffffffffc02002e8:	600c                	ld	a1,0(s0)
ffffffffc02002ea:	00005517          	auipc	a0,0x5
ffffffffc02002ee:	67e50513          	addi	a0,a0,1662 # ffffffffc0205968 <etext+0x130>
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
ffffffffc0200332:	64a50513          	addi	a0,a0,1610 # ffffffffc0205978 <etext+0x140>
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
ffffffffc020034a:	65a50513          	addi	a0,a0,1626 # ffffffffc02059a0 <etext+0x168>
ffffffffc020034e:	e47ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc0200352:	000a0563          	beqz	s4,ffffffffc020035c <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc0200356:	8552                	mv	a0,s4
ffffffffc0200358:	79c000ef          	jal	ffffffffc0200af4 <print_trapframe>
ffffffffc020035c:	00007a97          	auipc	s5,0x7
ffffffffc0200360:	23ca8a93          	addi	s5,s5,572 # ffffffffc0207598 <commands>
        if (argc == MAXARGS - 1)
ffffffffc0200364:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL)
ffffffffc0200366:	00005517          	auipc	a0,0x5
ffffffffc020036a:	66250513          	addi	a0,a0,1634 # ffffffffc02059c8 <etext+0x190>
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
ffffffffc0200388:	21448493          	addi	s1,s1,532 # ffffffffc0207598 <commands>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020038c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc020038e:	6582                	ld	a1,0(sp)
ffffffffc0200390:	6088                	ld	a0,0(s1)
ffffffffc0200392:	40e050ef          	jal	ffffffffc02057a0 <strcmp>
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
ffffffffc02003a8:	65450513          	addi	a0,a0,1620 # ffffffffc02059f8 <etext+0x1c0>
ffffffffc02003ac:	de9ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc02003b0:	bf5d                	j	ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003b2:	00005517          	auipc	a0,0x5
ffffffffc02003b6:	61e50513          	addi	a0,a0,1566 # ffffffffc02059d0 <etext+0x198>
ffffffffc02003ba:	442050ef          	jal	ffffffffc02057fc <strchr>
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
ffffffffc02003f8:	5dc50513          	addi	a0,a0,1500 # ffffffffc02059d0 <etext+0x198>
ffffffffc02003fc:	400050ef          	jal	ffffffffc02057fc <strchr>
ffffffffc0200400:	d575                	beqz	a0,ffffffffc02003ec <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200402:	00044583          	lbu	a1,0(s0)
ffffffffc0200406:	dda5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc0200408:	b76d                	j	ffffffffc02003b2 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040a:	45c1                	li	a1,16
ffffffffc020040c:	00005517          	auipc	a0,0x5
ffffffffc0200410:	5cc50513          	addi	a0,a0,1484 # ffffffffc02059d8 <etext+0x1a0>
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
ffffffffc0200470:	63450513          	addi	a0,a0,1588 # ffffffffc0205aa0 <etext+0x268>
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
ffffffffc020048e:	63650513          	addi	a0,a0,1590 # ffffffffc0205ac0 <etext+0x288>
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
ffffffffc02004c2:	60a50513          	addi	a0,a0,1546 # ffffffffc0205ac8 <etext+0x290>
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
ffffffffc02004e4:	5e050513          	addi	a0,a0,1504 # ffffffffc0205ac0 <etext+0x288>
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
ffffffffc020051e:	5ce50513          	addi	a0,a0,1486 # ffffffffc0205ae8 <etext+0x2b0>
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
ffffffffc02005be:	54e50513          	addi	a0,a0,1358 # ffffffffc0205b08 <etext+0x2d0>
void dtb_init(void) {
ffffffffc02005c2:	f406                	sd	ra,40(sp)
ffffffffc02005c4:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c6:	bcfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005ca:	0000b597          	auipc	a1,0xb
ffffffffc02005ce:	a365b583          	ld	a1,-1482(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc02005d2:	00005517          	auipc	a0,0x5
ffffffffc02005d6:	54650513          	addi	a0,a0,1350 # ffffffffc0205b18 <etext+0x2e0>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005da:	0000b417          	auipc	s0,0xb
ffffffffc02005de:	a2e40413          	addi	s0,s0,-1490 # ffffffffc020b008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005e2:	bb3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e6:	600c                	ld	a1,0(s0)
ffffffffc02005e8:	00005517          	auipc	a0,0x5
ffffffffc02005ec:	54050513          	addi	a0,a0,1344 # ffffffffc0205b28 <etext+0x2f0>
ffffffffc02005f0:	ba5ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005f4:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f6:	00005517          	auipc	a0,0x5
ffffffffc02005fa:	54a50513          	addi	a0,a0,1354 # ffffffffc0205b40 <etext+0x308>
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
ffffffffc02006ec:	52050513          	addi	a0,a0,1312 # ffffffffc0205c08 <etext+0x3d0>
ffffffffc02006f0:	aa5ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f4:	64e2                	ld	s1,24(sp)
ffffffffc02006f6:	6942                	ld	s2,16(sp)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	54850513          	addi	a0,a0,1352 # ffffffffc0205c40 <etext+0x408>
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
ffffffffc0200710:	45450513          	addi	a0,a0,1108 # ffffffffc0205b60 <etext+0x328>
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
ffffffffc0200752:	008050ef          	jal	ffffffffc020575a <strlen>
ffffffffc0200756:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200758:	4619                	li	a2,6
ffffffffc020075a:	8522                	mv	a0,s0
ffffffffc020075c:	00005597          	auipc	a1,0x5
ffffffffc0200760:	42c58593          	addi	a1,a1,1068 # ffffffffc0205b88 <etext+0x350>
ffffffffc0200764:	070050ef          	jal	ffffffffc02057d4 <strncmp>
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
ffffffffc020078c:	40858593          	addi	a1,a1,1032 # ffffffffc0205b90 <etext+0x358>
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
ffffffffc02007be:	7e3040ef          	jal	ffffffffc02057a0 <strcmp>
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
ffffffffc02007e2:	3ba50513          	addi	a0,a0,954 # ffffffffc0205b98 <etext+0x360>
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
ffffffffc02008ac:	31050513          	addi	a0,a0,784 # ffffffffc0205bb8 <etext+0x380>
ffffffffc02008b0:	8e5ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008b4:	01445613          	srli	a2,s0,0x14
ffffffffc02008b8:	85a2                	mv	a1,s0
ffffffffc02008ba:	00005517          	auipc	a0,0x5
ffffffffc02008be:	31650513          	addi	a0,a0,790 # ffffffffc0205bd0 <etext+0x398>
ffffffffc02008c2:	8d3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c6:	009405b3          	add	a1,s0,s1
ffffffffc02008ca:	15fd                	addi	a1,a1,-1
ffffffffc02008cc:	00005517          	auipc	a0,0x5
ffffffffc02008d0:	32450513          	addi	a0,a0,804 # ffffffffc0205bf0 <etext+0x3b8>
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
ffffffffc0200914:	4e478793          	addi	a5,a5,1252 # ffffffffc0200df4 <__alltraps>
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
ffffffffc0200932:	32a50513          	addi	a0,a0,810 # ffffffffc0205c58 <etext+0x420>
{
ffffffffc0200936:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200938:	85dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020093c:	640c                	ld	a1,8(s0)
ffffffffc020093e:	00005517          	auipc	a0,0x5
ffffffffc0200942:	33250513          	addi	a0,a0,818 # ffffffffc0205c70 <etext+0x438>
ffffffffc0200946:	84fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020094a:	680c                	ld	a1,16(s0)
ffffffffc020094c:	00005517          	auipc	a0,0x5
ffffffffc0200950:	33c50513          	addi	a0,a0,828 # ffffffffc0205c88 <etext+0x450>
ffffffffc0200954:	841ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200958:	6c0c                	ld	a1,24(s0)
ffffffffc020095a:	00005517          	auipc	a0,0x5
ffffffffc020095e:	34650513          	addi	a0,a0,838 # ffffffffc0205ca0 <etext+0x468>
ffffffffc0200962:	833ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200966:	700c                	ld	a1,32(s0)
ffffffffc0200968:	00005517          	auipc	a0,0x5
ffffffffc020096c:	35050513          	addi	a0,a0,848 # ffffffffc0205cb8 <etext+0x480>
ffffffffc0200970:	825ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200974:	740c                	ld	a1,40(s0)
ffffffffc0200976:	00005517          	auipc	a0,0x5
ffffffffc020097a:	35a50513          	addi	a0,a0,858 # ffffffffc0205cd0 <etext+0x498>
ffffffffc020097e:	817ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200982:	780c                	ld	a1,48(s0)
ffffffffc0200984:	00005517          	auipc	a0,0x5
ffffffffc0200988:	36450513          	addi	a0,a0,868 # ffffffffc0205ce8 <etext+0x4b0>
ffffffffc020098c:	809ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200990:	7c0c                	ld	a1,56(s0)
ffffffffc0200992:	00005517          	auipc	a0,0x5
ffffffffc0200996:	36e50513          	addi	a0,a0,878 # ffffffffc0205d00 <etext+0x4c8>
ffffffffc020099a:	ffaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020099e:	602c                	ld	a1,64(s0)
ffffffffc02009a0:	00005517          	auipc	a0,0x5
ffffffffc02009a4:	37850513          	addi	a0,a0,888 # ffffffffc0205d18 <etext+0x4e0>
ffffffffc02009a8:	fecff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009ac:	642c                	ld	a1,72(s0)
ffffffffc02009ae:	00005517          	auipc	a0,0x5
ffffffffc02009b2:	38250513          	addi	a0,a0,898 # ffffffffc0205d30 <etext+0x4f8>
ffffffffc02009b6:	fdeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009ba:	682c                	ld	a1,80(s0)
ffffffffc02009bc:	00005517          	auipc	a0,0x5
ffffffffc02009c0:	38c50513          	addi	a0,a0,908 # ffffffffc0205d48 <etext+0x510>
ffffffffc02009c4:	fd0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c8:	6c2c                	ld	a1,88(s0)
ffffffffc02009ca:	00005517          	auipc	a0,0x5
ffffffffc02009ce:	39650513          	addi	a0,a0,918 # ffffffffc0205d60 <etext+0x528>
ffffffffc02009d2:	fc2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d6:	702c                	ld	a1,96(s0)
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	3a050513          	addi	a0,a0,928 # ffffffffc0205d78 <etext+0x540>
ffffffffc02009e0:	fb4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009e4:	742c                	ld	a1,104(s0)
ffffffffc02009e6:	00005517          	auipc	a0,0x5
ffffffffc02009ea:	3aa50513          	addi	a0,a0,938 # ffffffffc0205d90 <etext+0x558>
ffffffffc02009ee:	fa6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009f2:	782c                	ld	a1,112(s0)
ffffffffc02009f4:	00005517          	auipc	a0,0x5
ffffffffc02009f8:	3b450513          	addi	a0,a0,948 # ffffffffc0205da8 <etext+0x570>
ffffffffc02009fc:	f98ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a00:	7c2c                	ld	a1,120(s0)
ffffffffc0200a02:	00005517          	auipc	a0,0x5
ffffffffc0200a06:	3be50513          	addi	a0,a0,958 # ffffffffc0205dc0 <etext+0x588>
ffffffffc0200a0a:	f8aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a0e:	604c                	ld	a1,128(s0)
ffffffffc0200a10:	00005517          	auipc	a0,0x5
ffffffffc0200a14:	3c850513          	addi	a0,a0,968 # ffffffffc0205dd8 <etext+0x5a0>
ffffffffc0200a18:	f7cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a1c:	644c                	ld	a1,136(s0)
ffffffffc0200a1e:	00005517          	auipc	a0,0x5
ffffffffc0200a22:	3d250513          	addi	a0,a0,978 # ffffffffc0205df0 <etext+0x5b8>
ffffffffc0200a26:	f6eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a2a:	684c                	ld	a1,144(s0)
ffffffffc0200a2c:	00005517          	auipc	a0,0x5
ffffffffc0200a30:	3dc50513          	addi	a0,a0,988 # ffffffffc0205e08 <etext+0x5d0>
ffffffffc0200a34:	f60ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a38:	6c4c                	ld	a1,152(s0)
ffffffffc0200a3a:	00005517          	auipc	a0,0x5
ffffffffc0200a3e:	3e650513          	addi	a0,a0,998 # ffffffffc0205e20 <etext+0x5e8>
ffffffffc0200a42:	f52ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a46:	704c                	ld	a1,160(s0)
ffffffffc0200a48:	00005517          	auipc	a0,0x5
ffffffffc0200a4c:	3f050513          	addi	a0,a0,1008 # ffffffffc0205e38 <etext+0x600>
ffffffffc0200a50:	f44ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a54:	744c                	ld	a1,168(s0)
ffffffffc0200a56:	00005517          	auipc	a0,0x5
ffffffffc0200a5a:	3fa50513          	addi	a0,a0,1018 # ffffffffc0205e50 <etext+0x618>
ffffffffc0200a5e:	f36ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a62:	784c                	ld	a1,176(s0)
ffffffffc0200a64:	00005517          	auipc	a0,0x5
ffffffffc0200a68:	40450513          	addi	a0,a0,1028 # ffffffffc0205e68 <etext+0x630>
ffffffffc0200a6c:	f28ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a70:	7c4c                	ld	a1,184(s0)
ffffffffc0200a72:	00005517          	auipc	a0,0x5
ffffffffc0200a76:	40e50513          	addi	a0,a0,1038 # ffffffffc0205e80 <etext+0x648>
ffffffffc0200a7a:	f1aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a7e:	606c                	ld	a1,192(s0)
ffffffffc0200a80:	00005517          	auipc	a0,0x5
ffffffffc0200a84:	41850513          	addi	a0,a0,1048 # ffffffffc0205e98 <etext+0x660>
ffffffffc0200a88:	f0cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a8c:	646c                	ld	a1,200(s0)
ffffffffc0200a8e:	00005517          	auipc	a0,0x5
ffffffffc0200a92:	42250513          	addi	a0,a0,1058 # ffffffffc0205eb0 <etext+0x678>
ffffffffc0200a96:	efeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a9a:	686c                	ld	a1,208(s0)
ffffffffc0200a9c:	00005517          	auipc	a0,0x5
ffffffffc0200aa0:	42c50513          	addi	a0,a0,1068 # ffffffffc0205ec8 <etext+0x690>
ffffffffc0200aa4:	ef0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa8:	6c6c                	ld	a1,216(s0)
ffffffffc0200aaa:	00005517          	auipc	a0,0x5
ffffffffc0200aae:	43650513          	addi	a0,a0,1078 # ffffffffc0205ee0 <etext+0x6a8>
ffffffffc0200ab2:	ee2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab6:	706c                	ld	a1,224(s0)
ffffffffc0200ab8:	00005517          	auipc	a0,0x5
ffffffffc0200abc:	44050513          	addi	a0,a0,1088 # ffffffffc0205ef8 <etext+0x6c0>
ffffffffc0200ac0:	ed4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200ac4:	746c                	ld	a1,232(s0)
ffffffffc0200ac6:	00005517          	auipc	a0,0x5
ffffffffc0200aca:	44a50513          	addi	a0,a0,1098 # ffffffffc0205f10 <etext+0x6d8>
ffffffffc0200ace:	ec6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200ad2:	786c                	ld	a1,240(s0)
ffffffffc0200ad4:	00005517          	auipc	a0,0x5
ffffffffc0200ad8:	45450513          	addi	a0,a0,1108 # ffffffffc0205f28 <etext+0x6f0>
ffffffffc0200adc:	eb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200ae2:	6402                	ld	s0,0(sp)
ffffffffc0200ae4:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae6:	00005517          	auipc	a0,0x5
ffffffffc0200aea:	45a50513          	addi	a0,a0,1114 # ffffffffc0205f40 <etext+0x708>
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
ffffffffc0200b00:	45c50513          	addi	a0,a0,1116 # ffffffffc0205f58 <etext+0x720>
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
ffffffffc0200b18:	45c50513          	addi	a0,a0,1116 # ffffffffc0205f70 <etext+0x738>
ffffffffc0200b1c:	e78ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b20:	10843583          	ld	a1,264(s0)
ffffffffc0200b24:	00005517          	auipc	a0,0x5
ffffffffc0200b28:	46450513          	addi	a0,a0,1124 # ffffffffc0205f88 <etext+0x750>
ffffffffc0200b2c:	e68ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b30:	11043583          	ld	a1,272(s0)
ffffffffc0200b34:	00005517          	auipc	a0,0x5
ffffffffc0200b38:	46c50513          	addi	a0,a0,1132 # ffffffffc0205fa0 <etext+0x768>
ffffffffc0200b3c:	e58ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b40:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b44:	6402                	ld	s0,0(sp)
ffffffffc0200b46:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b48:	00005517          	auipc	a0,0x5
ffffffffc0200b4c:	46850513          	addi	a0,a0,1128 # ffffffffc0205fb0 <etext+0x778>
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
ffffffffc0200b68:	a7c70713          	addi	a4,a4,-1412 # ffffffffc02075e0 <commands+0x48>
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
ffffffffc0200b7a:	4b250513          	addi	a0,a0,1202 # ffffffffc0206028 <etext+0x7f0>
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b82:	00005517          	auipc	a0,0x5
ffffffffc0200b86:	48650513          	addi	a0,a0,1158 # ffffffffc0206008 <etext+0x7d0>
ffffffffc0200b8a:	e0aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b8e:	00005517          	auipc	a0,0x5
ffffffffc0200b92:	43a50513          	addi	a0,a0,1082 # ffffffffc0205fc8 <etext+0x790>
ffffffffc0200b96:	dfeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b9a:	00005517          	auipc	a0,0x5
ffffffffc0200b9e:	44e50513          	addi	a0,a0,1102 # ffffffffc0205fe8 <etext+0x7b0>
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
ffffffffc0200bf4:	46850513          	addi	a0,a0,1128 # ffffffffc0206058 <etext+0x820>
ffffffffc0200bf8:	d9cff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200bfc:	bde5                	j	ffffffffc0200af4 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200bfe:	00005517          	auipc	a0,0x5
ffffffffc0200c02:	44a50513          	addi	a0,a0,1098 # ffffffffc0206048 <etext+0x810>
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
ffffffffc0200c20:	14f76763          	bltu	a4,a5,ffffffffc0200d6e <exception_handler+0x154>
ffffffffc0200c24:	00007717          	auipc	a4,0x7
ffffffffc0200c28:	9ec70713          	addi	a4,a4,-1556 # ffffffffc0207610 <commands+0x78>
ffffffffc0200c2c:	078a                	slli	a5,a5,0x2
ffffffffc0200c2e:	97ba                	add	a5,a5,a4
ffffffffc0200c30:	439c                	lw	a5,0(a5)
{
ffffffffc0200c32:	1101                	addi	sp,sp,-32
ffffffffc0200c34:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200c36:	97ba                	add	a5,a5,a4
ffffffffc0200c38:	86aa                	mv	a3,a0
ffffffffc0200c3a:	8782                	jr	a5
ffffffffc0200c3c:	e42a                	sd	a0,8(sp)
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	52250513          	addi	a0,a0,1314 # ffffffffc0206160 <etext+0x928>
ffffffffc0200c46:	d4eff0ef          	jal	ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200c4a:	66a2                	ld	a3,8(sp)
ffffffffc0200c4c:	1086b783          	ld	a5,264(a3)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c50:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200c52:	0791                	addi	a5,a5,4
ffffffffc0200c54:	10f6b423          	sd	a5,264(a3)
}
ffffffffc0200c58:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200c5a:	6a20406f          	j	ffffffffc02052fc <syscall>
}
ffffffffc0200c5e:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200c60:	00005517          	auipc	a0,0x5
ffffffffc0200c64:	52050513          	addi	a0,a0,1312 # ffffffffc0206180 <etext+0x948>
}
ffffffffc0200c68:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200c6a:	d2aff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c6e:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200c70:	00005517          	auipc	a0,0x5
ffffffffc0200c74:	53050513          	addi	a0,a0,1328 # ffffffffc02061a0 <etext+0x968>
}
ffffffffc0200c78:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200c7a:	d1aff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c7e:	60e2                	ld	ra,24(sp)
        cprintf("Instruction page fault\n");
ffffffffc0200c80:	00005517          	auipc	a0,0x5
ffffffffc0200c84:	54050513          	addi	a0,a0,1344 # ffffffffc02061c0 <etext+0x988>
}
ffffffffc0200c88:	6105                	addi	sp,sp,32
        cprintf("Instruction page fault\n");
ffffffffc0200c8a:	d0aff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c8e:	60e2                	ld	ra,24(sp)
        cprintf("Load page fault\n");
ffffffffc0200c90:	00005517          	auipc	a0,0x5
ffffffffc0200c94:	54850513          	addi	a0,a0,1352 # ffffffffc02061d8 <etext+0x9a0>
}
ffffffffc0200c98:	6105                	addi	sp,sp,32
        cprintf("Load page fault\n");
ffffffffc0200c9a:	cfaff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c9e:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO page fault\n");
ffffffffc0200ca0:	00005517          	auipc	a0,0x5
ffffffffc0200ca4:	55050513          	addi	a0,a0,1360 # ffffffffc02061f0 <etext+0x9b8>
}
ffffffffc0200ca8:	6105                	addi	sp,sp,32
        cprintf("Store/AMO page fault\n");
ffffffffc0200caa:	ceaff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cae:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200cb0:	00005517          	auipc	a0,0x5
ffffffffc0200cb4:	3c850513          	addi	a0,a0,968 # ffffffffc0206078 <etext+0x840>
}
ffffffffc0200cb8:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200cba:	cdaff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cbe:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200cc0:	00005517          	auipc	a0,0x5
ffffffffc0200cc4:	3d850513          	addi	a0,a0,984 # ffffffffc0206098 <etext+0x860>
}
ffffffffc0200cc8:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200cca:	ccaff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cce:	60e2                	ld	ra,24(sp)
        cprintf("Illegal instruction\n");
ffffffffc0200cd0:	00005517          	auipc	a0,0x5
ffffffffc0200cd4:	3e850513          	addi	a0,a0,1000 # ffffffffc02060b8 <etext+0x880>
}
ffffffffc0200cd8:	6105                	addi	sp,sp,32
        cprintf("Illegal instruction\n");
ffffffffc0200cda:	cbaff06f          	j	ffffffffc0200194 <cprintf>
ffffffffc0200cde:	e42a                	sd	a0,8(sp)
        cprintf("Breakpoint\n");
ffffffffc0200ce0:	00005517          	auipc	a0,0x5
ffffffffc0200ce4:	3f050513          	addi	a0,a0,1008 # ffffffffc02060d0 <etext+0x898>
ffffffffc0200ce8:	cacff0ef          	jal	ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200cec:	66a2                	ld	a3,8(sp)
ffffffffc0200cee:	47a9                	li	a5,10
ffffffffc0200cf0:	66d8                	ld	a4,136(a3)
ffffffffc0200cf2:	04f70c63          	beq	a4,a5,ffffffffc0200d4a <exception_handler+0x130>
}
ffffffffc0200cf6:	60e2                	ld	ra,24(sp)
ffffffffc0200cf8:	6105                	addi	sp,sp,32
ffffffffc0200cfa:	8082                	ret
ffffffffc0200cfc:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200cfe:	00005517          	auipc	a0,0x5
ffffffffc0200d02:	3e250513          	addi	a0,a0,994 # ffffffffc02060e0 <etext+0x8a8>
}
ffffffffc0200d06:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200d08:	c8cff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d0c:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200d0e:	00005517          	auipc	a0,0x5
ffffffffc0200d12:	3f250513          	addi	a0,a0,1010 # ffffffffc0206100 <etext+0x8c8>
}
ffffffffc0200d16:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200d18:	c7cff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d1c:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200d1e:	00005517          	auipc	a0,0x5
ffffffffc0200d22:	42a50513          	addi	a0,a0,1066 # ffffffffc0206148 <etext+0x910>
}
ffffffffc0200d26:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200d28:	c6cff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d2c:	60e2                	ld	ra,24(sp)
ffffffffc0200d2e:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200d30:	b3d1                	j	ffffffffc0200af4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d32:	00005617          	auipc	a2,0x5
ffffffffc0200d36:	3e660613          	addi	a2,a2,998 # ffffffffc0206118 <etext+0x8e0>
ffffffffc0200d3a:	0bb00593          	li	a1,187
ffffffffc0200d3e:	00005517          	auipc	a0,0x5
ffffffffc0200d42:	3f250513          	addi	a0,a0,1010 # ffffffffc0206130 <etext+0x8f8>
ffffffffc0200d46:	f00ff0ef          	jal	ffffffffc0200446 <__panic>
            tf->epc += 4;
ffffffffc0200d4a:	1086b783          	ld	a5,264(a3)
ffffffffc0200d4e:	0791                	addi	a5,a5,4
ffffffffc0200d50:	10f6b423          	sd	a5,264(a3)
            syscall();
ffffffffc0200d54:	5a8040ef          	jal	ffffffffc02052fc <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d58:	0009b717          	auipc	a4,0x9b
ffffffffc0200d5c:	92873703          	ld	a4,-1752(a4) # ffffffffc029b680 <current>
ffffffffc0200d60:	6522                	ld	a0,8(sp)
}
ffffffffc0200d62:	60e2                	ld	ra,24(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d64:	6b0c                	ld	a1,16(a4)
ffffffffc0200d66:	6789                	lui	a5,0x2
ffffffffc0200d68:	95be                	add	a1,a1,a5
}
ffffffffc0200d6a:	6105                	addi	sp,sp,32
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d6c:	aa99                	j	ffffffffc0200ec2 <kernel_execve_ret>
        print_trapframe(tf);
ffffffffc0200d6e:	b359                	j	ffffffffc0200af4 <print_trapframe>

ffffffffc0200d70 <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d70:	0009b717          	auipc	a4,0x9b
ffffffffc0200d74:	91073703          	ld	a4,-1776(a4) # ffffffffc029b680 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d78:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200d7c:	cf21                	beqz	a4,ffffffffc0200dd4 <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d7e:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d82:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200d86:	1101                	addi	sp,sp,-32
ffffffffc0200d88:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d8a:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200d8e:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d90:	e432                	sd	a2,8(sp)
ffffffffc0200d92:	e042                	sd	a6,0(sp)
ffffffffc0200d94:	0205c763          	bltz	a1,ffffffffc0200dc2 <trap+0x52>
        exception_handler(tf);
ffffffffc0200d98:	e83ff0ef          	jal	ffffffffc0200c1a <exception_handler>
ffffffffc0200d9c:	6622                	ld	a2,8(sp)
ffffffffc0200d9e:	6802                	ld	a6,0(sp)
ffffffffc0200da0:	0009b697          	auipc	a3,0x9b
ffffffffc0200da4:	8e068693          	addi	a3,a3,-1824 # ffffffffc029b680 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200da8:	6298                	ld	a4,0(a3)
ffffffffc0200daa:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200dae:	e619                	bnez	a2,ffffffffc0200dbc <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200db0:	0b072783          	lw	a5,176(a4)
ffffffffc0200db4:	8b85                	andi	a5,a5,1
ffffffffc0200db6:	e79d                	bnez	a5,ffffffffc0200de4 <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200db8:	6f1c                	ld	a5,24(a4)
ffffffffc0200dba:	e38d                	bnez	a5,ffffffffc0200ddc <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200dbc:	60e2                	ld	ra,24(sp)
ffffffffc0200dbe:	6105                	addi	sp,sp,32
ffffffffc0200dc0:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200dc2:	d95ff0ef          	jal	ffffffffc0200b56 <interrupt_handler>
ffffffffc0200dc6:	6802                	ld	a6,0(sp)
ffffffffc0200dc8:	6622                	ld	a2,8(sp)
ffffffffc0200dca:	0009b697          	auipc	a3,0x9b
ffffffffc0200dce:	8b668693          	addi	a3,a3,-1866 # ffffffffc029b680 <current>
ffffffffc0200dd2:	bfd9                	j	ffffffffc0200da8 <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200dd4:	0005c363          	bltz	a1,ffffffffc0200dda <trap+0x6a>
        exception_handler(tf);
ffffffffc0200dd8:	b589                	j	ffffffffc0200c1a <exception_handler>
        interrupt_handler(tf);
ffffffffc0200dda:	bbb5                	j	ffffffffc0200b56 <interrupt_handler>
}
ffffffffc0200ddc:	60e2                	ld	ra,24(sp)
ffffffffc0200dde:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200de0:	4300406f          	j	ffffffffc0205210 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200de4:	555d                	li	a0,-9
ffffffffc0200de6:	6c0030ef          	jal	ffffffffc02044a6 <do_exit>
            if (current->need_resched)
ffffffffc0200dea:	0009b717          	auipc	a4,0x9b
ffffffffc0200dee:	89673703          	ld	a4,-1898(a4) # ffffffffc029b680 <current>
ffffffffc0200df2:	b7d9                	j	ffffffffc0200db8 <trap+0x48>

ffffffffc0200df4 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200df4:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200df8:	00011463          	bnez	sp,ffffffffc0200e00 <__alltraps+0xc>
ffffffffc0200dfc:	14002173          	csrr	sp,sscratch
ffffffffc0200e00:	712d                	addi	sp,sp,-288
ffffffffc0200e02:	e002                	sd	zero,0(sp)
ffffffffc0200e04:	e406                	sd	ra,8(sp)
ffffffffc0200e06:	ec0e                	sd	gp,24(sp)
ffffffffc0200e08:	f012                	sd	tp,32(sp)
ffffffffc0200e0a:	f416                	sd	t0,40(sp)
ffffffffc0200e0c:	f81a                	sd	t1,48(sp)
ffffffffc0200e0e:	fc1e                	sd	t2,56(sp)
ffffffffc0200e10:	e0a2                	sd	s0,64(sp)
ffffffffc0200e12:	e4a6                	sd	s1,72(sp)
ffffffffc0200e14:	e8aa                	sd	a0,80(sp)
ffffffffc0200e16:	ecae                	sd	a1,88(sp)
ffffffffc0200e18:	f0b2                	sd	a2,96(sp)
ffffffffc0200e1a:	f4b6                	sd	a3,104(sp)
ffffffffc0200e1c:	f8ba                	sd	a4,112(sp)
ffffffffc0200e1e:	fcbe                	sd	a5,120(sp)
ffffffffc0200e20:	e142                	sd	a6,128(sp)
ffffffffc0200e22:	e546                	sd	a7,136(sp)
ffffffffc0200e24:	e94a                	sd	s2,144(sp)
ffffffffc0200e26:	ed4e                	sd	s3,152(sp)
ffffffffc0200e28:	f152                	sd	s4,160(sp)
ffffffffc0200e2a:	f556                	sd	s5,168(sp)
ffffffffc0200e2c:	f95a                	sd	s6,176(sp)
ffffffffc0200e2e:	fd5e                	sd	s7,184(sp)
ffffffffc0200e30:	e1e2                	sd	s8,192(sp)
ffffffffc0200e32:	e5e6                	sd	s9,200(sp)
ffffffffc0200e34:	e9ea                	sd	s10,208(sp)
ffffffffc0200e36:	edee                	sd	s11,216(sp)
ffffffffc0200e38:	f1f2                	sd	t3,224(sp)
ffffffffc0200e3a:	f5f6                	sd	t4,232(sp)
ffffffffc0200e3c:	f9fa                	sd	t5,240(sp)
ffffffffc0200e3e:	fdfe                	sd	t6,248(sp)
ffffffffc0200e40:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e44:	100024f3          	csrr	s1,sstatus
ffffffffc0200e48:	14102973          	csrr	s2,sepc
ffffffffc0200e4c:	143029f3          	csrr	s3,stval
ffffffffc0200e50:	14202a73          	csrr	s4,scause
ffffffffc0200e54:	e822                	sd	s0,16(sp)
ffffffffc0200e56:	e226                	sd	s1,256(sp)
ffffffffc0200e58:	e64a                	sd	s2,264(sp)
ffffffffc0200e5a:	ea4e                	sd	s3,272(sp)
ffffffffc0200e5c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e5e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e60:	f11ff0ef          	jal	ffffffffc0200d70 <trap>

ffffffffc0200e64 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e64:	6492                	ld	s1,256(sp)
ffffffffc0200e66:	6932                	ld	s2,264(sp)
ffffffffc0200e68:	1004f413          	andi	s0,s1,256
ffffffffc0200e6c:	e401                	bnez	s0,ffffffffc0200e74 <__trapret+0x10>
ffffffffc0200e6e:	1200                	addi	s0,sp,288
ffffffffc0200e70:	14041073          	csrw	sscratch,s0
ffffffffc0200e74:	10049073          	csrw	sstatus,s1
ffffffffc0200e78:	14191073          	csrw	sepc,s2
ffffffffc0200e7c:	60a2                	ld	ra,8(sp)
ffffffffc0200e7e:	61e2                	ld	gp,24(sp)
ffffffffc0200e80:	7202                	ld	tp,32(sp)
ffffffffc0200e82:	72a2                	ld	t0,40(sp)
ffffffffc0200e84:	7342                	ld	t1,48(sp)
ffffffffc0200e86:	73e2                	ld	t2,56(sp)
ffffffffc0200e88:	6406                	ld	s0,64(sp)
ffffffffc0200e8a:	64a6                	ld	s1,72(sp)
ffffffffc0200e8c:	6546                	ld	a0,80(sp)
ffffffffc0200e8e:	65e6                	ld	a1,88(sp)
ffffffffc0200e90:	7606                	ld	a2,96(sp)
ffffffffc0200e92:	76a6                	ld	a3,104(sp)
ffffffffc0200e94:	7746                	ld	a4,112(sp)
ffffffffc0200e96:	77e6                	ld	a5,120(sp)
ffffffffc0200e98:	680a                	ld	a6,128(sp)
ffffffffc0200e9a:	68aa                	ld	a7,136(sp)
ffffffffc0200e9c:	694a                	ld	s2,144(sp)
ffffffffc0200e9e:	69ea                	ld	s3,152(sp)
ffffffffc0200ea0:	7a0a                	ld	s4,160(sp)
ffffffffc0200ea2:	7aaa                	ld	s5,168(sp)
ffffffffc0200ea4:	7b4a                	ld	s6,176(sp)
ffffffffc0200ea6:	7bea                	ld	s7,184(sp)
ffffffffc0200ea8:	6c0e                	ld	s8,192(sp)
ffffffffc0200eaa:	6cae                	ld	s9,200(sp)
ffffffffc0200eac:	6d4e                	ld	s10,208(sp)
ffffffffc0200eae:	6dee                	ld	s11,216(sp)
ffffffffc0200eb0:	7e0e                	ld	t3,224(sp)
ffffffffc0200eb2:	7eae                	ld	t4,232(sp)
ffffffffc0200eb4:	7f4e                	ld	t5,240(sp)
ffffffffc0200eb6:	7fee                	ld	t6,248(sp)
ffffffffc0200eb8:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200eba:	10200073          	sret

ffffffffc0200ebe <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200ebe:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200ec0:	b755                	j	ffffffffc0200e64 <__trapret>

ffffffffc0200ec2 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200ec2:	ee058593          	addi	a1,a1,-288

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200ec6:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200eca:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200ece:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200ed2:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200ed6:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200eda:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200ede:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200ee2:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200ee6:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200ee8:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200eea:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200eec:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200eee:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200ef0:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200ef2:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200ef4:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200ef6:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200ef8:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200efa:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200efc:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200efe:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200f00:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200f02:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200f04:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200f06:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200f08:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200f0a:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200f0c:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200f0e:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200f10:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200f12:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200f14:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200f16:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200f18:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200f1a:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200f1c:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200f1e:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f20:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f22:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f24:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f26:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f28:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f2a:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f2c:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f2e:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200f30:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200f32:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200f34:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200f36:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200f38:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200f3a:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200f3c:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200f3e:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200f40:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200f42:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200f44:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200f46:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200f48:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200f4a:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200f4c:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200f4e:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200f50:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200f52:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200f54:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200f56:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200f58:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200f5a:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200f5c:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200f5e:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200f60:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200f62:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200f64:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200f66:	812e                	mv	sp,a1
ffffffffc0200f68:	bdf5                	j	ffffffffc0200e64 <__trapret>

ffffffffc0200f6a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f6a:	00096797          	auipc	a5,0x96
ffffffffc0200f6e:	68678793          	addi	a5,a5,1670 # ffffffffc02975f0 <free_area>
ffffffffc0200f72:	e79c                	sd	a5,8(a5)
ffffffffc0200f74:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f76:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200f7a:	8082                	ret

ffffffffc0200f7c <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200f7c:	00096517          	auipc	a0,0x96
ffffffffc0200f80:	68456503          	lwu	a0,1668(a0) # ffffffffc0297600 <free_area+0x10>
ffffffffc0200f84:	8082                	ret

ffffffffc0200f86 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200f86:	711d                	addi	sp,sp,-96
ffffffffc0200f88:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f8a:	00096917          	auipc	s2,0x96
ffffffffc0200f8e:	66690913          	addi	s2,s2,1638 # ffffffffc02975f0 <free_area>
ffffffffc0200f92:	00893783          	ld	a5,8(s2)
ffffffffc0200f96:	ec86                	sd	ra,88(sp)
ffffffffc0200f98:	e8a2                	sd	s0,80(sp)
ffffffffc0200f9a:	e4a6                	sd	s1,72(sp)
ffffffffc0200f9c:	fc4e                	sd	s3,56(sp)
ffffffffc0200f9e:	f852                	sd	s4,48(sp)
ffffffffc0200fa0:	f456                	sd	s5,40(sp)
ffffffffc0200fa2:	f05a                	sd	s6,32(sp)
ffffffffc0200fa4:	ec5e                	sd	s7,24(sp)
ffffffffc0200fa6:	e862                	sd	s8,16(sp)
ffffffffc0200fa8:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200faa:	2f278363          	beq	a5,s2,ffffffffc0201290 <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0200fae:	4401                	li	s0,0
ffffffffc0200fb0:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200fb2:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200fb6:	8b09                	andi	a4,a4,2
ffffffffc0200fb8:	2e070063          	beqz	a4,ffffffffc0201298 <default_check+0x312>
        count++, total += p->property;
ffffffffc0200fbc:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fc0:	679c                	ld	a5,8(a5)
ffffffffc0200fc2:	2485                	addiw	s1,s1,1
ffffffffc0200fc4:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fc6:	ff2796e3          	bne	a5,s2,ffffffffc0200fb2 <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200fca:	89a2                	mv	s3,s0
ffffffffc0200fcc:	741000ef          	jal	ffffffffc0201f0c <nr_free_pages>
ffffffffc0200fd0:	73351463          	bne	a0,s3,ffffffffc02016f8 <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fd4:	4505                	li	a0,1
ffffffffc0200fd6:	6c5000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc0200fda:	8a2a                	mv	s4,a0
ffffffffc0200fdc:	44050e63          	beqz	a0,ffffffffc0201438 <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fe0:	4505                	li	a0,1
ffffffffc0200fe2:	6b9000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc0200fe6:	89aa                	mv	s3,a0
ffffffffc0200fe8:	72050863          	beqz	a0,ffffffffc0201718 <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fec:	4505                	li	a0,1
ffffffffc0200fee:	6ad000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc0200ff2:	8aaa                	mv	s5,a0
ffffffffc0200ff4:	4c050263          	beqz	a0,ffffffffc02014b8 <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ff8:	40a987b3          	sub	a5,s3,a0
ffffffffc0200ffc:	40aa0733          	sub	a4,s4,a0
ffffffffc0201000:	0017b793          	seqz	a5,a5
ffffffffc0201004:	00173713          	seqz	a4,a4
ffffffffc0201008:	8fd9                	or	a5,a5,a4
ffffffffc020100a:	30079763          	bnez	a5,ffffffffc0201318 <default_check+0x392>
ffffffffc020100e:	313a0563          	beq	s4,s3,ffffffffc0201318 <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201012:	000a2783          	lw	a5,0(s4)
ffffffffc0201016:	2a079163          	bnez	a5,ffffffffc02012b8 <default_check+0x332>
ffffffffc020101a:	0009a783          	lw	a5,0(s3)
ffffffffc020101e:	28079d63          	bnez	a5,ffffffffc02012b8 <default_check+0x332>
ffffffffc0201022:	411c                	lw	a5,0(a0)
ffffffffc0201024:	28079a63          	bnez	a5,ffffffffc02012b8 <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0201028:	0009a797          	auipc	a5,0x9a
ffffffffc020102c:	6487b783          	ld	a5,1608(a5) # ffffffffc029b670 <pages>
ffffffffc0201030:	00007617          	auipc	a2,0x7
ffffffffc0201034:	97863603          	ld	a2,-1672(a2) # ffffffffc02079a8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201038:	0009a697          	auipc	a3,0x9a
ffffffffc020103c:	6306b683          	ld	a3,1584(a3) # ffffffffc029b668 <npage>
ffffffffc0201040:	40fa0733          	sub	a4,s4,a5
ffffffffc0201044:	8719                	srai	a4,a4,0x6
ffffffffc0201046:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0201048:	0732                	slli	a4,a4,0xc
ffffffffc020104a:	06b2                	slli	a3,a3,0xc
ffffffffc020104c:	2ad77663          	bgeu	a4,a3,ffffffffc02012f8 <default_check+0x372>
    return page - pages + nbase;
ffffffffc0201050:	40f98733          	sub	a4,s3,a5
ffffffffc0201054:	8719                	srai	a4,a4,0x6
ffffffffc0201056:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201058:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020105a:	4cd77f63          	bgeu	a4,a3,ffffffffc0201538 <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc020105e:	40f507b3          	sub	a5,a0,a5
ffffffffc0201062:	8799                	srai	a5,a5,0x6
ffffffffc0201064:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201066:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201068:	32d7f863          	bgeu	a5,a3,ffffffffc0201398 <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc020106c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020106e:	00093c03          	ld	s8,0(s2)
ffffffffc0201072:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0201076:	00096b17          	auipc	s6,0x96
ffffffffc020107a:	58ab2b03          	lw	s6,1418(s6) # ffffffffc0297600 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc020107e:	01293023          	sd	s2,0(s2)
ffffffffc0201082:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0201086:	00096797          	auipc	a5,0x96
ffffffffc020108a:	5607ad23          	sw	zero,1402(a5) # ffffffffc0297600 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc020108e:	60d000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc0201092:	2e051363          	bnez	a0,ffffffffc0201378 <default_check+0x3f2>
    free_page(p0);
ffffffffc0201096:	8552                	mv	a0,s4
ffffffffc0201098:	4585                	li	a1,1
ffffffffc020109a:	63b000ef          	jal	ffffffffc0201ed4 <free_pages>
    free_page(p1);
ffffffffc020109e:	854e                	mv	a0,s3
ffffffffc02010a0:	4585                	li	a1,1
ffffffffc02010a2:	633000ef          	jal	ffffffffc0201ed4 <free_pages>
    free_page(p2);
ffffffffc02010a6:	8556                	mv	a0,s5
ffffffffc02010a8:	4585                	li	a1,1
ffffffffc02010aa:	62b000ef          	jal	ffffffffc0201ed4 <free_pages>
    assert(nr_free == 3);
ffffffffc02010ae:	00096717          	auipc	a4,0x96
ffffffffc02010b2:	55272703          	lw	a4,1362(a4) # ffffffffc0297600 <free_area+0x10>
ffffffffc02010b6:	478d                	li	a5,3
ffffffffc02010b8:	2af71063          	bne	a4,a5,ffffffffc0201358 <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010bc:	4505                	li	a0,1
ffffffffc02010be:	5dd000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc02010c2:	89aa                	mv	s3,a0
ffffffffc02010c4:	26050a63          	beqz	a0,ffffffffc0201338 <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010c8:	4505                	li	a0,1
ffffffffc02010ca:	5d1000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc02010ce:	8aaa                	mv	s5,a0
ffffffffc02010d0:	3c050463          	beqz	a0,ffffffffc0201498 <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010d4:	4505                	li	a0,1
ffffffffc02010d6:	5c5000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc02010da:	8a2a                	mv	s4,a0
ffffffffc02010dc:	38050e63          	beqz	a0,ffffffffc0201478 <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc02010e0:	4505                	li	a0,1
ffffffffc02010e2:	5b9000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc02010e6:	36051963          	bnez	a0,ffffffffc0201458 <default_check+0x4d2>
    free_page(p0);
ffffffffc02010ea:	4585                	li	a1,1
ffffffffc02010ec:	854e                	mv	a0,s3
ffffffffc02010ee:	5e7000ef          	jal	ffffffffc0201ed4 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02010f2:	00893783          	ld	a5,8(s2)
ffffffffc02010f6:	1f278163          	beq	a5,s2,ffffffffc02012d8 <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc02010fa:	4505                	li	a0,1
ffffffffc02010fc:	59f000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc0201100:	8caa                	mv	s9,a0
ffffffffc0201102:	30a99b63          	bne	s3,a0,ffffffffc0201418 <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc0201106:	4505                	li	a0,1
ffffffffc0201108:	593000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc020110c:	2e051663          	bnez	a0,ffffffffc02013f8 <default_check+0x472>
    assert(nr_free == 0);
ffffffffc0201110:	00096797          	auipc	a5,0x96
ffffffffc0201114:	4f07a783          	lw	a5,1264(a5) # ffffffffc0297600 <free_area+0x10>
ffffffffc0201118:	2c079063          	bnez	a5,ffffffffc02013d8 <default_check+0x452>
    free_page(p);
ffffffffc020111c:	8566                	mv	a0,s9
ffffffffc020111e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201120:	01893023          	sd	s8,0(s2)
ffffffffc0201124:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0201128:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc020112c:	5a9000ef          	jal	ffffffffc0201ed4 <free_pages>
    free_page(p1);
ffffffffc0201130:	8556                	mv	a0,s5
ffffffffc0201132:	4585                	li	a1,1
ffffffffc0201134:	5a1000ef          	jal	ffffffffc0201ed4 <free_pages>
    free_page(p2);
ffffffffc0201138:	8552                	mv	a0,s4
ffffffffc020113a:	4585                	li	a1,1
ffffffffc020113c:	599000ef          	jal	ffffffffc0201ed4 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201140:	4515                	li	a0,5
ffffffffc0201142:	559000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc0201146:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201148:	26050863          	beqz	a0,ffffffffc02013b8 <default_check+0x432>
ffffffffc020114c:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc020114e:	8b89                	andi	a5,a5,2
ffffffffc0201150:	54079463          	bnez	a5,ffffffffc0201698 <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201154:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201156:	00093b83          	ld	s7,0(s2)
ffffffffc020115a:	00893b03          	ld	s6,8(s2)
ffffffffc020115e:	01293023          	sd	s2,0(s2)
ffffffffc0201162:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0201166:	535000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc020116a:	50051763          	bnez	a0,ffffffffc0201678 <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020116e:	08098a13          	addi	s4,s3,128
ffffffffc0201172:	8552                	mv	a0,s4
ffffffffc0201174:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201176:	00096c17          	auipc	s8,0x96
ffffffffc020117a:	48ac2c03          	lw	s8,1162(s8) # ffffffffc0297600 <free_area+0x10>
    nr_free = 0;
ffffffffc020117e:	00096797          	auipc	a5,0x96
ffffffffc0201182:	4807a123          	sw	zero,1154(a5) # ffffffffc0297600 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201186:	54f000ef          	jal	ffffffffc0201ed4 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020118a:	4511                	li	a0,4
ffffffffc020118c:	50f000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc0201190:	4c051463          	bnez	a0,ffffffffc0201658 <default_check+0x6d2>
ffffffffc0201194:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201198:	8b89                	andi	a5,a5,2
ffffffffc020119a:	48078f63          	beqz	a5,ffffffffc0201638 <default_check+0x6b2>
ffffffffc020119e:	0909a503          	lw	a0,144(s3)
ffffffffc02011a2:	478d                	li	a5,3
ffffffffc02011a4:	48f51a63          	bne	a0,a5,ffffffffc0201638 <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011a8:	4f3000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc02011ac:	8aaa                	mv	s5,a0
ffffffffc02011ae:	46050563          	beqz	a0,ffffffffc0201618 <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc02011b2:	4505                	li	a0,1
ffffffffc02011b4:	4e7000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc02011b8:	44051063          	bnez	a0,ffffffffc02015f8 <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc02011bc:	415a1e63          	bne	s4,s5,ffffffffc02015d8 <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02011c0:	4585                	li	a1,1
ffffffffc02011c2:	854e                	mv	a0,s3
ffffffffc02011c4:	511000ef          	jal	ffffffffc0201ed4 <free_pages>
    free_pages(p1, 3);
ffffffffc02011c8:	8552                	mv	a0,s4
ffffffffc02011ca:	458d                	li	a1,3
ffffffffc02011cc:	509000ef          	jal	ffffffffc0201ed4 <free_pages>
ffffffffc02011d0:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02011d4:	8b89                	andi	a5,a5,2
ffffffffc02011d6:	3e078163          	beqz	a5,ffffffffc02015b8 <default_check+0x632>
ffffffffc02011da:	0109aa83          	lw	s5,16(s3)
ffffffffc02011de:	4785                	li	a5,1
ffffffffc02011e0:	3cfa9c63          	bne	s5,a5,ffffffffc02015b8 <default_check+0x632>
ffffffffc02011e4:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011e8:	8b89                	andi	a5,a5,2
ffffffffc02011ea:	3a078763          	beqz	a5,ffffffffc0201598 <default_check+0x612>
ffffffffc02011ee:	010a2703          	lw	a4,16(s4)
ffffffffc02011f2:	478d                	li	a5,3
ffffffffc02011f4:	3af71263          	bne	a4,a5,ffffffffc0201598 <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02011f8:	8556                	mv	a0,s5
ffffffffc02011fa:	4a1000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc02011fe:	36a99d63          	bne	s3,a0,ffffffffc0201578 <default_check+0x5f2>
    free_page(p0);
ffffffffc0201202:	85d6                	mv	a1,s5
ffffffffc0201204:	4d1000ef          	jal	ffffffffc0201ed4 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201208:	4509                	li	a0,2
ffffffffc020120a:	491000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc020120e:	34aa1563          	bne	s4,a0,ffffffffc0201558 <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc0201212:	4589                	li	a1,2
ffffffffc0201214:	4c1000ef          	jal	ffffffffc0201ed4 <free_pages>
    free_page(p2);
ffffffffc0201218:	04098513          	addi	a0,s3,64
ffffffffc020121c:	85d6                	mv	a1,s5
ffffffffc020121e:	4b7000ef          	jal	ffffffffc0201ed4 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201222:	4515                	li	a0,5
ffffffffc0201224:	477000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc0201228:	89aa                	mv	s3,a0
ffffffffc020122a:	48050763          	beqz	a0,ffffffffc02016b8 <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc020122e:	8556                	mv	a0,s5
ffffffffc0201230:	46b000ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc0201234:	2e051263          	bnez	a0,ffffffffc0201518 <default_check+0x592>

    assert(nr_free == 0);
ffffffffc0201238:	00096797          	auipc	a5,0x96
ffffffffc020123c:	3c87a783          	lw	a5,968(a5) # ffffffffc0297600 <free_area+0x10>
ffffffffc0201240:	2a079c63          	bnez	a5,ffffffffc02014f8 <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201244:	854e                	mv	a0,s3
ffffffffc0201246:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0201248:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc020124c:	01793023          	sd	s7,0(s2)
ffffffffc0201250:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0201254:	481000ef          	jal	ffffffffc0201ed4 <free_pages>
    return listelm->next;
ffffffffc0201258:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020125c:	01278963          	beq	a5,s2,ffffffffc020126e <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201260:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201264:	679c                	ld	a5,8(a5)
ffffffffc0201266:	34fd                	addiw	s1,s1,-1
ffffffffc0201268:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020126a:	ff279be3          	bne	a5,s2,ffffffffc0201260 <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc020126e:	26049563          	bnez	s1,ffffffffc02014d8 <default_check+0x552>
    assert(total == 0);
ffffffffc0201272:	46041363          	bnez	s0,ffffffffc02016d8 <default_check+0x752>
}
ffffffffc0201276:	60e6                	ld	ra,88(sp)
ffffffffc0201278:	6446                	ld	s0,80(sp)
ffffffffc020127a:	64a6                	ld	s1,72(sp)
ffffffffc020127c:	6906                	ld	s2,64(sp)
ffffffffc020127e:	79e2                	ld	s3,56(sp)
ffffffffc0201280:	7a42                	ld	s4,48(sp)
ffffffffc0201282:	7aa2                	ld	s5,40(sp)
ffffffffc0201284:	7b02                	ld	s6,32(sp)
ffffffffc0201286:	6be2                	ld	s7,24(sp)
ffffffffc0201288:	6c42                	ld	s8,16(sp)
ffffffffc020128a:	6ca2                	ld	s9,8(sp)
ffffffffc020128c:	6125                	addi	sp,sp,96
ffffffffc020128e:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201290:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201292:	4401                	li	s0,0
ffffffffc0201294:	4481                	li	s1,0
ffffffffc0201296:	bb1d                	j	ffffffffc0200fcc <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0201298:	00005697          	auipc	a3,0x5
ffffffffc020129c:	f7068693          	addi	a3,a3,-144 # ffffffffc0206208 <etext+0x9d0>
ffffffffc02012a0:	00005617          	auipc	a2,0x5
ffffffffc02012a4:	f7860613          	addi	a2,a2,-136 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02012a8:	11000593          	li	a1,272
ffffffffc02012ac:	00005517          	auipc	a0,0x5
ffffffffc02012b0:	f8450513          	addi	a0,a0,-124 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02012b4:	992ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02012b8:	00005697          	auipc	a3,0x5
ffffffffc02012bc:	03868693          	addi	a3,a3,56 # ffffffffc02062f0 <etext+0xab8>
ffffffffc02012c0:	00005617          	auipc	a2,0x5
ffffffffc02012c4:	f5860613          	addi	a2,a2,-168 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02012c8:	0dc00593          	li	a1,220
ffffffffc02012cc:	00005517          	auipc	a0,0x5
ffffffffc02012d0:	f6450513          	addi	a0,a0,-156 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02012d4:	972ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02012d8:	00005697          	auipc	a3,0x5
ffffffffc02012dc:	0e068693          	addi	a3,a3,224 # ffffffffc02063b8 <etext+0xb80>
ffffffffc02012e0:	00005617          	auipc	a2,0x5
ffffffffc02012e4:	f3860613          	addi	a2,a2,-200 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02012e8:	0f700593          	li	a1,247
ffffffffc02012ec:	00005517          	auipc	a0,0x5
ffffffffc02012f0:	f4450513          	addi	a0,a0,-188 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02012f4:	952ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02012f8:	00005697          	auipc	a3,0x5
ffffffffc02012fc:	03868693          	addi	a3,a3,56 # ffffffffc0206330 <etext+0xaf8>
ffffffffc0201300:	00005617          	auipc	a2,0x5
ffffffffc0201304:	f1860613          	addi	a2,a2,-232 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201308:	0de00593          	li	a1,222
ffffffffc020130c:	00005517          	auipc	a0,0x5
ffffffffc0201310:	f2450513          	addi	a0,a0,-220 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201314:	932ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201318:	00005697          	auipc	a3,0x5
ffffffffc020131c:	fb068693          	addi	a3,a3,-80 # ffffffffc02062c8 <etext+0xa90>
ffffffffc0201320:	00005617          	auipc	a2,0x5
ffffffffc0201324:	ef860613          	addi	a2,a2,-264 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201328:	0db00593          	li	a1,219
ffffffffc020132c:	00005517          	auipc	a0,0x5
ffffffffc0201330:	f0450513          	addi	a0,a0,-252 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201334:	912ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201338:	00005697          	auipc	a3,0x5
ffffffffc020133c:	f3068693          	addi	a3,a3,-208 # ffffffffc0206268 <etext+0xa30>
ffffffffc0201340:	00005617          	auipc	a2,0x5
ffffffffc0201344:	ed860613          	addi	a2,a2,-296 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201348:	0f000593          	li	a1,240
ffffffffc020134c:	00005517          	auipc	a0,0x5
ffffffffc0201350:	ee450513          	addi	a0,a0,-284 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201354:	8f2ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 3);
ffffffffc0201358:	00005697          	auipc	a3,0x5
ffffffffc020135c:	05068693          	addi	a3,a3,80 # ffffffffc02063a8 <etext+0xb70>
ffffffffc0201360:	00005617          	auipc	a2,0x5
ffffffffc0201364:	eb860613          	addi	a2,a2,-328 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201368:	0ee00593          	li	a1,238
ffffffffc020136c:	00005517          	auipc	a0,0x5
ffffffffc0201370:	ec450513          	addi	a0,a0,-316 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201374:	8d2ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201378:	00005697          	auipc	a3,0x5
ffffffffc020137c:	01868693          	addi	a3,a3,24 # ffffffffc0206390 <etext+0xb58>
ffffffffc0201380:	00005617          	auipc	a2,0x5
ffffffffc0201384:	e9860613          	addi	a2,a2,-360 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201388:	0e900593          	li	a1,233
ffffffffc020138c:	00005517          	auipc	a0,0x5
ffffffffc0201390:	ea450513          	addi	a0,a0,-348 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201394:	8b2ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201398:	00005697          	auipc	a3,0x5
ffffffffc020139c:	fd868693          	addi	a3,a3,-40 # ffffffffc0206370 <etext+0xb38>
ffffffffc02013a0:	00005617          	auipc	a2,0x5
ffffffffc02013a4:	e7860613          	addi	a2,a2,-392 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02013a8:	0e000593          	li	a1,224
ffffffffc02013ac:	00005517          	auipc	a0,0x5
ffffffffc02013b0:	e8450513          	addi	a0,a0,-380 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02013b4:	892ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != NULL);
ffffffffc02013b8:	00005697          	auipc	a3,0x5
ffffffffc02013bc:	04868693          	addi	a3,a3,72 # ffffffffc0206400 <etext+0xbc8>
ffffffffc02013c0:	00005617          	auipc	a2,0x5
ffffffffc02013c4:	e5860613          	addi	a2,a2,-424 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02013c8:	11800593          	li	a1,280
ffffffffc02013cc:	00005517          	auipc	a0,0x5
ffffffffc02013d0:	e6450513          	addi	a0,a0,-412 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02013d4:	872ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02013d8:	00005697          	auipc	a3,0x5
ffffffffc02013dc:	01868693          	addi	a3,a3,24 # ffffffffc02063f0 <etext+0xbb8>
ffffffffc02013e0:	00005617          	auipc	a2,0x5
ffffffffc02013e4:	e3860613          	addi	a2,a2,-456 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02013e8:	0fd00593          	li	a1,253
ffffffffc02013ec:	00005517          	auipc	a0,0x5
ffffffffc02013f0:	e4450513          	addi	a0,a0,-444 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02013f4:	852ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013f8:	00005697          	auipc	a3,0x5
ffffffffc02013fc:	f9868693          	addi	a3,a3,-104 # ffffffffc0206390 <etext+0xb58>
ffffffffc0201400:	00005617          	auipc	a2,0x5
ffffffffc0201404:	e1860613          	addi	a2,a2,-488 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201408:	0fb00593          	li	a1,251
ffffffffc020140c:	00005517          	auipc	a0,0x5
ffffffffc0201410:	e2450513          	addi	a0,a0,-476 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201414:	832ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201418:	00005697          	auipc	a3,0x5
ffffffffc020141c:	fb868693          	addi	a3,a3,-72 # ffffffffc02063d0 <etext+0xb98>
ffffffffc0201420:	00005617          	auipc	a2,0x5
ffffffffc0201424:	df860613          	addi	a2,a2,-520 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201428:	0fa00593          	li	a1,250
ffffffffc020142c:	00005517          	auipc	a0,0x5
ffffffffc0201430:	e0450513          	addi	a0,a0,-508 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201434:	812ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201438:	00005697          	auipc	a3,0x5
ffffffffc020143c:	e3068693          	addi	a3,a3,-464 # ffffffffc0206268 <etext+0xa30>
ffffffffc0201440:	00005617          	auipc	a2,0x5
ffffffffc0201444:	dd860613          	addi	a2,a2,-552 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201448:	0d700593          	li	a1,215
ffffffffc020144c:	00005517          	auipc	a0,0x5
ffffffffc0201450:	de450513          	addi	a0,a0,-540 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201454:	ff3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201458:	00005697          	auipc	a3,0x5
ffffffffc020145c:	f3868693          	addi	a3,a3,-200 # ffffffffc0206390 <etext+0xb58>
ffffffffc0201460:	00005617          	auipc	a2,0x5
ffffffffc0201464:	db860613          	addi	a2,a2,-584 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201468:	0f400593          	li	a1,244
ffffffffc020146c:	00005517          	auipc	a0,0x5
ffffffffc0201470:	dc450513          	addi	a0,a0,-572 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201474:	fd3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201478:	00005697          	auipc	a3,0x5
ffffffffc020147c:	e3068693          	addi	a3,a3,-464 # ffffffffc02062a8 <etext+0xa70>
ffffffffc0201480:	00005617          	auipc	a2,0x5
ffffffffc0201484:	d9860613          	addi	a2,a2,-616 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201488:	0f200593          	li	a1,242
ffffffffc020148c:	00005517          	auipc	a0,0x5
ffffffffc0201490:	da450513          	addi	a0,a0,-604 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201494:	fb3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201498:	00005697          	auipc	a3,0x5
ffffffffc020149c:	df068693          	addi	a3,a3,-528 # ffffffffc0206288 <etext+0xa50>
ffffffffc02014a0:	00005617          	auipc	a2,0x5
ffffffffc02014a4:	d7860613          	addi	a2,a2,-648 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02014a8:	0f100593          	li	a1,241
ffffffffc02014ac:	00005517          	auipc	a0,0x5
ffffffffc02014b0:	d8450513          	addi	a0,a0,-636 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02014b4:	f93fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014b8:	00005697          	auipc	a3,0x5
ffffffffc02014bc:	df068693          	addi	a3,a3,-528 # ffffffffc02062a8 <etext+0xa70>
ffffffffc02014c0:	00005617          	auipc	a2,0x5
ffffffffc02014c4:	d5860613          	addi	a2,a2,-680 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02014c8:	0d900593          	li	a1,217
ffffffffc02014cc:	00005517          	auipc	a0,0x5
ffffffffc02014d0:	d6450513          	addi	a0,a0,-668 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02014d4:	f73fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(count == 0);
ffffffffc02014d8:	00005697          	auipc	a3,0x5
ffffffffc02014dc:	07868693          	addi	a3,a3,120 # ffffffffc0206550 <etext+0xd18>
ffffffffc02014e0:	00005617          	auipc	a2,0x5
ffffffffc02014e4:	d3860613          	addi	a2,a2,-712 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02014e8:	14600593          	li	a1,326
ffffffffc02014ec:	00005517          	auipc	a0,0x5
ffffffffc02014f0:	d4450513          	addi	a0,a0,-700 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02014f4:	f53fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02014f8:	00005697          	auipc	a3,0x5
ffffffffc02014fc:	ef868693          	addi	a3,a3,-264 # ffffffffc02063f0 <etext+0xbb8>
ffffffffc0201500:	00005617          	auipc	a2,0x5
ffffffffc0201504:	d1860613          	addi	a2,a2,-744 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201508:	13a00593          	li	a1,314
ffffffffc020150c:	00005517          	auipc	a0,0x5
ffffffffc0201510:	d2450513          	addi	a0,a0,-732 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201514:	f33fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201518:	00005697          	auipc	a3,0x5
ffffffffc020151c:	e7868693          	addi	a3,a3,-392 # ffffffffc0206390 <etext+0xb58>
ffffffffc0201520:	00005617          	auipc	a2,0x5
ffffffffc0201524:	cf860613          	addi	a2,a2,-776 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201528:	13800593          	li	a1,312
ffffffffc020152c:	00005517          	auipc	a0,0x5
ffffffffc0201530:	d0450513          	addi	a0,a0,-764 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201534:	f13fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201538:	00005697          	auipc	a3,0x5
ffffffffc020153c:	e1868693          	addi	a3,a3,-488 # ffffffffc0206350 <etext+0xb18>
ffffffffc0201540:	00005617          	auipc	a2,0x5
ffffffffc0201544:	cd860613          	addi	a2,a2,-808 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201548:	0df00593          	li	a1,223
ffffffffc020154c:	00005517          	auipc	a0,0x5
ffffffffc0201550:	ce450513          	addi	a0,a0,-796 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201554:	ef3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201558:	00005697          	auipc	a3,0x5
ffffffffc020155c:	fb868693          	addi	a3,a3,-72 # ffffffffc0206510 <etext+0xcd8>
ffffffffc0201560:	00005617          	auipc	a2,0x5
ffffffffc0201564:	cb860613          	addi	a2,a2,-840 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201568:	13200593          	li	a1,306
ffffffffc020156c:	00005517          	auipc	a0,0x5
ffffffffc0201570:	cc450513          	addi	a0,a0,-828 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201574:	ed3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201578:	00005697          	auipc	a3,0x5
ffffffffc020157c:	f7868693          	addi	a3,a3,-136 # ffffffffc02064f0 <etext+0xcb8>
ffffffffc0201580:	00005617          	auipc	a2,0x5
ffffffffc0201584:	c9860613          	addi	a2,a2,-872 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201588:	13000593          	li	a1,304
ffffffffc020158c:	00005517          	auipc	a0,0x5
ffffffffc0201590:	ca450513          	addi	a0,a0,-860 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201594:	eb3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201598:	00005697          	auipc	a3,0x5
ffffffffc020159c:	f3068693          	addi	a3,a3,-208 # ffffffffc02064c8 <etext+0xc90>
ffffffffc02015a0:	00005617          	auipc	a2,0x5
ffffffffc02015a4:	c7860613          	addi	a2,a2,-904 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02015a8:	12e00593          	li	a1,302
ffffffffc02015ac:	00005517          	auipc	a0,0x5
ffffffffc02015b0:	c8450513          	addi	a0,a0,-892 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02015b4:	e93fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02015b8:	00005697          	auipc	a3,0x5
ffffffffc02015bc:	ee868693          	addi	a3,a3,-280 # ffffffffc02064a0 <etext+0xc68>
ffffffffc02015c0:	00005617          	auipc	a2,0x5
ffffffffc02015c4:	c5860613          	addi	a2,a2,-936 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02015c8:	12d00593          	li	a1,301
ffffffffc02015cc:	00005517          	auipc	a0,0x5
ffffffffc02015d0:	c6450513          	addi	a0,a0,-924 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02015d4:	e73fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02015d8:	00005697          	auipc	a3,0x5
ffffffffc02015dc:	eb868693          	addi	a3,a3,-328 # ffffffffc0206490 <etext+0xc58>
ffffffffc02015e0:	00005617          	auipc	a2,0x5
ffffffffc02015e4:	c3860613          	addi	a2,a2,-968 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02015e8:	12800593          	li	a1,296
ffffffffc02015ec:	00005517          	auipc	a0,0x5
ffffffffc02015f0:	c4450513          	addi	a0,a0,-956 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02015f4:	e53fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015f8:	00005697          	auipc	a3,0x5
ffffffffc02015fc:	d9868693          	addi	a3,a3,-616 # ffffffffc0206390 <etext+0xb58>
ffffffffc0201600:	00005617          	auipc	a2,0x5
ffffffffc0201604:	c1860613          	addi	a2,a2,-1000 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201608:	12700593          	li	a1,295
ffffffffc020160c:	00005517          	auipc	a0,0x5
ffffffffc0201610:	c2450513          	addi	a0,a0,-988 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201614:	e33fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201618:	00005697          	auipc	a3,0x5
ffffffffc020161c:	e5868693          	addi	a3,a3,-424 # ffffffffc0206470 <etext+0xc38>
ffffffffc0201620:	00005617          	auipc	a2,0x5
ffffffffc0201624:	bf860613          	addi	a2,a2,-1032 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201628:	12600593          	li	a1,294
ffffffffc020162c:	00005517          	auipc	a0,0x5
ffffffffc0201630:	c0450513          	addi	a0,a0,-1020 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201634:	e13fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201638:	00005697          	auipc	a3,0x5
ffffffffc020163c:	e0868693          	addi	a3,a3,-504 # ffffffffc0206440 <etext+0xc08>
ffffffffc0201640:	00005617          	auipc	a2,0x5
ffffffffc0201644:	bd860613          	addi	a2,a2,-1064 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201648:	12500593          	li	a1,293
ffffffffc020164c:	00005517          	auipc	a0,0x5
ffffffffc0201650:	be450513          	addi	a0,a0,-1052 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201654:	df3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201658:	00005697          	auipc	a3,0x5
ffffffffc020165c:	dd068693          	addi	a3,a3,-560 # ffffffffc0206428 <etext+0xbf0>
ffffffffc0201660:	00005617          	auipc	a2,0x5
ffffffffc0201664:	bb860613          	addi	a2,a2,-1096 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201668:	12400593          	li	a1,292
ffffffffc020166c:	00005517          	auipc	a0,0x5
ffffffffc0201670:	bc450513          	addi	a0,a0,-1084 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201674:	dd3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201678:	00005697          	auipc	a3,0x5
ffffffffc020167c:	d1868693          	addi	a3,a3,-744 # ffffffffc0206390 <etext+0xb58>
ffffffffc0201680:	00005617          	auipc	a2,0x5
ffffffffc0201684:	b9860613          	addi	a2,a2,-1128 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201688:	11e00593          	li	a1,286
ffffffffc020168c:	00005517          	auipc	a0,0x5
ffffffffc0201690:	ba450513          	addi	a0,a0,-1116 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201694:	db3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201698:	00005697          	auipc	a3,0x5
ffffffffc020169c:	d7868693          	addi	a3,a3,-648 # ffffffffc0206410 <etext+0xbd8>
ffffffffc02016a0:	00005617          	auipc	a2,0x5
ffffffffc02016a4:	b7860613          	addi	a2,a2,-1160 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02016a8:	11900593          	li	a1,281
ffffffffc02016ac:	00005517          	auipc	a0,0x5
ffffffffc02016b0:	b8450513          	addi	a0,a0,-1148 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02016b4:	d93fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02016b8:	00005697          	auipc	a3,0x5
ffffffffc02016bc:	e7868693          	addi	a3,a3,-392 # ffffffffc0206530 <etext+0xcf8>
ffffffffc02016c0:	00005617          	auipc	a2,0x5
ffffffffc02016c4:	b5860613          	addi	a2,a2,-1192 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02016c8:	13700593          	li	a1,311
ffffffffc02016cc:	00005517          	auipc	a0,0x5
ffffffffc02016d0:	b6450513          	addi	a0,a0,-1180 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02016d4:	d73fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == 0);
ffffffffc02016d8:	00005697          	auipc	a3,0x5
ffffffffc02016dc:	e8868693          	addi	a3,a3,-376 # ffffffffc0206560 <etext+0xd28>
ffffffffc02016e0:	00005617          	auipc	a2,0x5
ffffffffc02016e4:	b3860613          	addi	a2,a2,-1224 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02016e8:	14700593          	li	a1,327
ffffffffc02016ec:	00005517          	auipc	a0,0x5
ffffffffc02016f0:	b4450513          	addi	a0,a0,-1212 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02016f4:	d53fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == nr_free_pages());
ffffffffc02016f8:	00005697          	auipc	a3,0x5
ffffffffc02016fc:	b5068693          	addi	a3,a3,-1200 # ffffffffc0206248 <etext+0xa10>
ffffffffc0201700:	00005617          	auipc	a2,0x5
ffffffffc0201704:	b1860613          	addi	a2,a2,-1256 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201708:	11300593          	li	a1,275
ffffffffc020170c:	00005517          	auipc	a0,0x5
ffffffffc0201710:	b2450513          	addi	a0,a0,-1244 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201714:	d33fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201718:	00005697          	auipc	a3,0x5
ffffffffc020171c:	b7068693          	addi	a3,a3,-1168 # ffffffffc0206288 <etext+0xa50>
ffffffffc0201720:	00005617          	auipc	a2,0x5
ffffffffc0201724:	af860613          	addi	a2,a2,-1288 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201728:	0d800593          	li	a1,216
ffffffffc020172c:	00005517          	auipc	a0,0x5
ffffffffc0201730:	b0450513          	addi	a0,a0,-1276 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201734:	d13fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201738 <default_free_pages>:
{
ffffffffc0201738:	1141                	addi	sp,sp,-16
ffffffffc020173a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020173c:	14058663          	beqz	a1,ffffffffc0201888 <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc0201740:	00659713          	slli	a4,a1,0x6
ffffffffc0201744:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201748:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc020174a:	c30d                	beqz	a4,ffffffffc020176c <default_free_pages+0x34>
ffffffffc020174c:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020174e:	8b05                	andi	a4,a4,1
ffffffffc0201750:	10071c63          	bnez	a4,ffffffffc0201868 <default_free_pages+0x130>
ffffffffc0201754:	6798                	ld	a4,8(a5)
ffffffffc0201756:	8b09                	andi	a4,a4,2
ffffffffc0201758:	10071863          	bnez	a4,ffffffffc0201868 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc020175c:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201760:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201764:	04078793          	addi	a5,a5,64
ffffffffc0201768:	fed792e3          	bne	a5,a3,ffffffffc020174c <default_free_pages+0x14>
    base->property = n;
ffffffffc020176c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020176e:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201772:	4789                	li	a5,2
ffffffffc0201774:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201778:	00096717          	auipc	a4,0x96
ffffffffc020177c:	e8872703          	lw	a4,-376(a4) # ffffffffc0297600 <free_area+0x10>
ffffffffc0201780:	00096697          	auipc	a3,0x96
ffffffffc0201784:	e7068693          	addi	a3,a3,-400 # ffffffffc02975f0 <free_area>
    return list->next == list;
ffffffffc0201788:	669c                	ld	a5,8(a3)
ffffffffc020178a:	9f2d                	addw	a4,a4,a1
ffffffffc020178c:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc020178e:	0ad78163          	beq	a5,a3,ffffffffc0201830 <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc0201792:	fe878713          	addi	a4,a5,-24
ffffffffc0201796:	4581                	li	a1,0
ffffffffc0201798:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc020179c:	00e56a63          	bltu	a0,a4,ffffffffc02017b0 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02017a0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02017a2:	04d70c63          	beq	a4,a3,ffffffffc02017fa <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc02017a6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017a8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02017ac:	fee57ae3          	bgeu	a0,a4,ffffffffc02017a0 <default_free_pages+0x68>
ffffffffc02017b0:	c199                	beqz	a1,ffffffffc02017b6 <default_free_pages+0x7e>
ffffffffc02017b2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017b6:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02017b8:	e390                	sd	a2,0(a5)
ffffffffc02017ba:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc02017bc:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02017be:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc02017c0:	00d70d63          	beq	a4,a3,ffffffffc02017da <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02017c4:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02017c8:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02017cc:	02059813          	slli	a6,a1,0x20
ffffffffc02017d0:	01a85793          	srli	a5,a6,0x1a
ffffffffc02017d4:	97b2                	add	a5,a5,a2
ffffffffc02017d6:	02f50c63          	beq	a0,a5,ffffffffc020180e <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02017da:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02017dc:	00d78c63          	beq	a5,a3,ffffffffc02017f4 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02017e0:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02017e2:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02017e6:	02061593          	slli	a1,a2,0x20
ffffffffc02017ea:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02017ee:	972a                	add	a4,a4,a0
ffffffffc02017f0:	04e68c63          	beq	a3,a4,ffffffffc0201848 <default_free_pages+0x110>
}
ffffffffc02017f4:	60a2                	ld	ra,8(sp)
ffffffffc02017f6:	0141                	addi	sp,sp,16
ffffffffc02017f8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017fa:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017fc:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017fe:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201800:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201802:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201804:	02d70f63          	beq	a4,a3,ffffffffc0201842 <default_free_pages+0x10a>
ffffffffc0201808:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020180a:	87ba                	mv	a5,a4
ffffffffc020180c:	bf71                	j	ffffffffc02017a8 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020180e:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201810:	5875                	li	a6,-3
ffffffffc0201812:	9fad                	addw	a5,a5,a1
ffffffffc0201814:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201818:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020181c:	01853803          	ld	a6,24(a0)
ffffffffc0201820:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201822:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201824:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_exit_out_size+0xfe5e50>
    return listelm->next;
ffffffffc0201828:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020182a:	0105b023          	sd	a6,0(a1)
ffffffffc020182e:	b77d                	j	ffffffffc02017dc <default_free_pages+0xa4>
}
ffffffffc0201830:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201832:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201836:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201838:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020183a:	e398                	sd	a4,0(a5)
ffffffffc020183c:	e798                	sd	a4,8(a5)
}
ffffffffc020183e:	0141                	addi	sp,sp,16
ffffffffc0201840:	8082                	ret
ffffffffc0201842:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201844:	873e                	mv	a4,a5
ffffffffc0201846:	bfad                	j	ffffffffc02017c0 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc0201848:	ff87a703          	lw	a4,-8(a5)
ffffffffc020184c:	56f5                	li	a3,-3
ffffffffc020184e:	9f31                	addw	a4,a4,a2
ffffffffc0201850:	c918                	sw	a4,16(a0)
ffffffffc0201852:	ff078713          	addi	a4,a5,-16
ffffffffc0201856:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc020185a:	6398                	ld	a4,0(a5)
ffffffffc020185c:	679c                	ld	a5,8(a5)
}
ffffffffc020185e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201860:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201862:	e398                	sd	a4,0(a5)
ffffffffc0201864:	0141                	addi	sp,sp,16
ffffffffc0201866:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201868:	00005697          	auipc	a3,0x5
ffffffffc020186c:	d1068693          	addi	a3,a3,-752 # ffffffffc0206578 <etext+0xd40>
ffffffffc0201870:	00005617          	auipc	a2,0x5
ffffffffc0201874:	9a860613          	addi	a2,a2,-1624 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201878:	09400593          	li	a1,148
ffffffffc020187c:	00005517          	auipc	a0,0x5
ffffffffc0201880:	9b450513          	addi	a0,a0,-1612 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201884:	bc3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201888:	00005697          	auipc	a3,0x5
ffffffffc020188c:	ce868693          	addi	a3,a3,-792 # ffffffffc0206570 <etext+0xd38>
ffffffffc0201890:	00005617          	auipc	a2,0x5
ffffffffc0201894:	98860613          	addi	a2,a2,-1656 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201898:	09000593          	li	a1,144
ffffffffc020189c:	00005517          	auipc	a0,0x5
ffffffffc02018a0:	99450513          	addi	a0,a0,-1644 # ffffffffc0206230 <etext+0x9f8>
ffffffffc02018a4:	ba3fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02018a8 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018a8:	c951                	beqz	a0,ffffffffc020193c <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc02018aa:	00096597          	auipc	a1,0x96
ffffffffc02018ae:	d565a583          	lw	a1,-682(a1) # ffffffffc0297600 <free_area+0x10>
ffffffffc02018b2:	86aa                	mv	a3,a0
ffffffffc02018b4:	02059793          	slli	a5,a1,0x20
ffffffffc02018b8:	9381                	srli	a5,a5,0x20
ffffffffc02018ba:	00a7ef63          	bltu	a5,a0,ffffffffc02018d8 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc02018be:	00096617          	auipc	a2,0x96
ffffffffc02018c2:	d3260613          	addi	a2,a2,-718 # ffffffffc02975f0 <free_area>
ffffffffc02018c6:	87b2                	mv	a5,a2
ffffffffc02018c8:	a029                	j	ffffffffc02018d2 <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc02018ca:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02018ce:	00d77763          	bgeu	a4,a3,ffffffffc02018dc <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02018d2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02018d4:	fec79be3          	bne	a5,a2,ffffffffc02018ca <default_alloc_pages+0x22>
        return NULL;
ffffffffc02018d8:	4501                	li	a0,0
}
ffffffffc02018da:	8082                	ret
        if (page->property > n)
ffffffffc02018dc:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02018e0:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018e4:	6798                	ld	a4,8(a5)
ffffffffc02018e6:	02089313          	slli	t1,a7,0x20
ffffffffc02018ea:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc02018ee:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02018f2:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc02018f6:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc02018fa:	0266fa63          	bgeu	a3,t1,ffffffffc020192e <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02018fe:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc0201902:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc0201906:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201908:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020190c:	00870313          	addi	t1,a4,8
ffffffffc0201910:	4889                	li	a7,2
ffffffffc0201912:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201916:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc020191a:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc020191e:	0068b023          	sd	t1,0(a7)
ffffffffc0201922:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc0201926:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc020192a:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc020192e:	9d95                	subw	a1,a1,a3
ffffffffc0201930:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201932:	5775                	li	a4,-3
ffffffffc0201934:	17c1                	addi	a5,a5,-16
ffffffffc0201936:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020193a:	8082                	ret
{
ffffffffc020193c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020193e:	00005697          	auipc	a3,0x5
ffffffffc0201942:	c3268693          	addi	a3,a3,-974 # ffffffffc0206570 <etext+0xd38>
ffffffffc0201946:	00005617          	auipc	a2,0x5
ffffffffc020194a:	8d260613          	addi	a2,a2,-1838 # ffffffffc0206218 <etext+0x9e0>
ffffffffc020194e:	06c00593          	li	a1,108
ffffffffc0201952:	00005517          	auipc	a0,0x5
ffffffffc0201956:	8de50513          	addi	a0,a0,-1826 # ffffffffc0206230 <etext+0x9f8>
{
ffffffffc020195a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020195c:	aebfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201960 <default_init_memmap>:
{
ffffffffc0201960:	1141                	addi	sp,sp,-16
ffffffffc0201962:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201964:	c9e1                	beqz	a1,ffffffffc0201a34 <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc0201966:	00659713          	slli	a4,a1,0x6
ffffffffc020196a:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020196e:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc0201970:	cf11                	beqz	a4,ffffffffc020198c <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201972:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201974:	8b05                	andi	a4,a4,1
ffffffffc0201976:	cf59                	beqz	a4,ffffffffc0201a14 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201978:	0007a823          	sw	zero,16(a5)
ffffffffc020197c:	0007b423          	sd	zero,8(a5)
ffffffffc0201980:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201984:	04078793          	addi	a5,a5,64
ffffffffc0201988:	fed795e3          	bne	a5,a3,ffffffffc0201972 <default_init_memmap+0x12>
    base->property = n;
ffffffffc020198c:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020198e:	4789                	li	a5,2
ffffffffc0201990:	00850713          	addi	a4,a0,8
ffffffffc0201994:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201998:	00096717          	auipc	a4,0x96
ffffffffc020199c:	c6872703          	lw	a4,-920(a4) # ffffffffc0297600 <free_area+0x10>
ffffffffc02019a0:	00096697          	auipc	a3,0x96
ffffffffc02019a4:	c5068693          	addi	a3,a3,-944 # ffffffffc02975f0 <free_area>
    return list->next == list;
ffffffffc02019a8:	669c                	ld	a5,8(a3)
ffffffffc02019aa:	9f2d                	addw	a4,a4,a1
ffffffffc02019ac:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02019ae:	04d78663          	beq	a5,a3,ffffffffc02019fa <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc02019b2:	fe878713          	addi	a4,a5,-24
ffffffffc02019b6:	4581                	li	a1,0
ffffffffc02019b8:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02019bc:	00e56a63          	bltu	a0,a4,ffffffffc02019d0 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019c0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019c2:	02d70263          	beq	a4,a3,ffffffffc02019e6 <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02019c6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019c8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019cc:	fee57ae3          	bgeu	a0,a4,ffffffffc02019c0 <default_init_memmap+0x60>
ffffffffc02019d0:	c199                	beqz	a1,ffffffffc02019d6 <default_init_memmap+0x76>
ffffffffc02019d2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019d6:	6398                	ld	a4,0(a5)
}
ffffffffc02019d8:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019da:	e390                	sd	a2,0(a5)
ffffffffc02019dc:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02019de:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02019e0:	f11c                	sd	a5,32(a0)
ffffffffc02019e2:	0141                	addi	sp,sp,16
ffffffffc02019e4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02019e6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019e8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02019ea:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02019ec:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02019ee:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc02019f0:	00d70e63          	beq	a4,a3,ffffffffc0201a0c <default_init_memmap+0xac>
ffffffffc02019f4:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02019f6:	87ba                	mv	a5,a4
ffffffffc02019f8:	bfc1                	j	ffffffffc02019c8 <default_init_memmap+0x68>
}
ffffffffc02019fa:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02019fc:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201a00:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a02:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201a04:	e398                	sd	a4,0(a5)
ffffffffc0201a06:	e798                	sd	a4,8(a5)
}
ffffffffc0201a08:	0141                	addi	sp,sp,16
ffffffffc0201a0a:	8082                	ret
ffffffffc0201a0c:	60a2                	ld	ra,8(sp)
ffffffffc0201a0e:	e290                	sd	a2,0(a3)
ffffffffc0201a10:	0141                	addi	sp,sp,16
ffffffffc0201a12:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a14:	00005697          	auipc	a3,0x5
ffffffffc0201a18:	b8c68693          	addi	a3,a3,-1140 # ffffffffc02065a0 <etext+0xd68>
ffffffffc0201a1c:	00004617          	auipc	a2,0x4
ffffffffc0201a20:	7fc60613          	addi	a2,a2,2044 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201a24:	04b00593          	li	a1,75
ffffffffc0201a28:	00005517          	auipc	a0,0x5
ffffffffc0201a2c:	80850513          	addi	a0,a0,-2040 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201a30:	a17fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201a34:	00005697          	auipc	a3,0x5
ffffffffc0201a38:	b3c68693          	addi	a3,a3,-1220 # ffffffffc0206570 <etext+0xd38>
ffffffffc0201a3c:	00004617          	auipc	a2,0x4
ffffffffc0201a40:	7dc60613          	addi	a2,a2,2012 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201a44:	04700593          	li	a1,71
ffffffffc0201a48:	00004517          	auipc	a0,0x4
ffffffffc0201a4c:	7e850513          	addi	a0,a0,2024 # ffffffffc0206230 <etext+0x9f8>
ffffffffc0201a50:	9f7fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201a54 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a54:	c531                	beqz	a0,ffffffffc0201aa0 <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201a56:	e9b9                	bnez	a1,ffffffffc0201aac <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a58:	100027f3          	csrr	a5,sstatus
ffffffffc0201a5c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a5e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a60:	efb1                	bnez	a5,ffffffffc0201abc <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a62:	00095797          	auipc	a5,0x95
ffffffffc0201a66:	77e7b783          	ld	a5,1918(a5) # ffffffffc02971e0 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a6a:	873e                	mv	a4,a5
ffffffffc0201a6c:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a6e:	02a77a63          	bgeu	a4,a0,ffffffffc0201aa2 <slob_free+0x4e>
ffffffffc0201a72:	00f56463          	bltu	a0,a5,ffffffffc0201a7a <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a76:	fef76ae3          	bltu	a4,a5,ffffffffc0201a6a <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201a7a:	4110                	lw	a2,0(a0)
ffffffffc0201a7c:	00461693          	slli	a3,a2,0x4
ffffffffc0201a80:	96aa                	add	a3,a3,a0
ffffffffc0201a82:	0ad78463          	beq	a5,a3,ffffffffc0201b2a <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201a86:	4310                	lw	a2,0(a4)
ffffffffc0201a88:	e51c                	sd	a5,8(a0)
ffffffffc0201a8a:	00461693          	slli	a3,a2,0x4
ffffffffc0201a8e:	96ba                	add	a3,a3,a4
ffffffffc0201a90:	08d50163          	beq	a0,a3,ffffffffc0201b12 <slob_free+0xbe>
ffffffffc0201a94:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201a96:	00095797          	auipc	a5,0x95
ffffffffc0201a9a:	74e7b523          	sd	a4,1866(a5) # ffffffffc02971e0 <slobfree>
    if (flag)
ffffffffc0201a9e:	e9a5                	bnez	a1,ffffffffc0201b0e <slob_free+0xba>
ffffffffc0201aa0:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aa2:	fcf574e3          	bgeu	a0,a5,ffffffffc0201a6a <slob_free+0x16>
ffffffffc0201aa6:	fcf762e3          	bltu	a4,a5,ffffffffc0201a6a <slob_free+0x16>
ffffffffc0201aaa:	bfc1                	j	ffffffffc0201a7a <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201aac:	25bd                	addiw	a1,a1,15
ffffffffc0201aae:	8191                	srli	a1,a1,0x4
ffffffffc0201ab0:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ab2:	100027f3          	csrr	a5,sstatus
ffffffffc0201ab6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ab8:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aba:	d7c5                	beqz	a5,ffffffffc0201a62 <slob_free+0xe>
{
ffffffffc0201abc:	1101                	addi	sp,sp,-32
ffffffffc0201abe:	e42a                	sd	a0,8(sp)
ffffffffc0201ac0:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201ac2:	e43fe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201ac6:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ac8:	00095797          	auipc	a5,0x95
ffffffffc0201acc:	7187b783          	ld	a5,1816(a5) # ffffffffc02971e0 <slobfree>
ffffffffc0201ad0:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ad2:	873e                	mv	a4,a5
ffffffffc0201ad4:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ad6:	06a77663          	bgeu	a4,a0,ffffffffc0201b42 <slob_free+0xee>
ffffffffc0201ada:	00f56463          	bltu	a0,a5,ffffffffc0201ae2 <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ade:	fef76ae3          	bltu	a4,a5,ffffffffc0201ad2 <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201ae2:	4110                	lw	a2,0(a0)
ffffffffc0201ae4:	00461693          	slli	a3,a2,0x4
ffffffffc0201ae8:	96aa                	add	a3,a3,a0
ffffffffc0201aea:	06d78363          	beq	a5,a3,ffffffffc0201b50 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201aee:	4310                	lw	a2,0(a4)
ffffffffc0201af0:	e51c                	sd	a5,8(a0)
ffffffffc0201af2:	00461693          	slli	a3,a2,0x4
ffffffffc0201af6:	96ba                	add	a3,a3,a4
ffffffffc0201af8:	06d50163          	beq	a0,a3,ffffffffc0201b5a <slob_free+0x106>
ffffffffc0201afc:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201afe:	00095797          	auipc	a5,0x95
ffffffffc0201b02:	6ee7b123          	sd	a4,1762(a5) # ffffffffc02971e0 <slobfree>
    if (flag)
ffffffffc0201b06:	e1a9                	bnez	a1,ffffffffc0201b48 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b08:	60e2                	ld	ra,24(sp)
ffffffffc0201b0a:	6105                	addi	sp,sp,32
ffffffffc0201b0c:	8082                	ret
        intr_enable();
ffffffffc0201b0e:	df1fe06f          	j	ffffffffc02008fe <intr_enable>
		cur->units += b->units;
ffffffffc0201b12:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b14:	853e                	mv	a0,a5
ffffffffc0201b16:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201b18:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b1c:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201b1e:	00095797          	auipc	a5,0x95
ffffffffc0201b22:	6ce7b123          	sd	a4,1730(a5) # ffffffffc02971e0 <slobfree>
    if (flag)
ffffffffc0201b26:	ddad                	beqz	a1,ffffffffc0201aa0 <slob_free+0x4c>
ffffffffc0201b28:	b7dd                	j	ffffffffc0201b0e <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201b2a:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b2c:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b2e:	9eb1                	addw	a3,a3,a2
ffffffffc0201b30:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201b32:	4310                	lw	a2,0(a4)
ffffffffc0201b34:	e51c                	sd	a5,8(a0)
ffffffffc0201b36:	00461693          	slli	a3,a2,0x4
ffffffffc0201b3a:	96ba                	add	a3,a3,a4
ffffffffc0201b3c:	f4d51ce3          	bne	a0,a3,ffffffffc0201a94 <slob_free+0x40>
ffffffffc0201b40:	bfc9                	j	ffffffffc0201b12 <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b42:	f8f56ee3          	bltu	a0,a5,ffffffffc0201ade <slob_free+0x8a>
ffffffffc0201b46:	b771                	j	ffffffffc0201ad2 <slob_free+0x7e>
}
ffffffffc0201b48:	60e2                	ld	ra,24(sp)
ffffffffc0201b4a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201b4c:	db3fe06f          	j	ffffffffc02008fe <intr_enable>
		b->units += cur->next->units;
ffffffffc0201b50:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b52:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b54:	9eb1                	addw	a3,a3,a2
ffffffffc0201b56:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201b58:	bf59                	j	ffffffffc0201aee <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201b5a:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b5c:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201b5e:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b62:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201b64:	bf61                	j	ffffffffc0201afc <slob_free+0xa8>

ffffffffc0201b66 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b66:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b68:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b6a:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b6e:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b70:	32a000ef          	jal	ffffffffc0201e9a <alloc_pages>
	if (!page)
ffffffffc0201b74:	c91d                	beqz	a0,ffffffffc0201baa <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b76:	0009a697          	auipc	a3,0x9a
ffffffffc0201b7a:	afa6b683          	ld	a3,-1286(a3) # ffffffffc029b670 <pages>
ffffffffc0201b7e:	00006797          	auipc	a5,0x6
ffffffffc0201b82:	e2a7b783          	ld	a5,-470(a5) # ffffffffc02079a8 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201b86:	0009a717          	auipc	a4,0x9a
ffffffffc0201b8a:	ae273703          	ld	a4,-1310(a4) # ffffffffc029b668 <npage>
    return page - pages + nbase;
ffffffffc0201b8e:	8d15                	sub	a0,a0,a3
ffffffffc0201b90:	8519                	srai	a0,a0,0x6
ffffffffc0201b92:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201b94:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b98:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b9a:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b9c:	00e7fa63          	bgeu	a5,a4,ffffffffc0201bb0 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201ba0:	0009a797          	auipc	a5,0x9a
ffffffffc0201ba4:	ac07b783          	ld	a5,-1344(a5) # ffffffffc029b660 <va_pa_offset>
ffffffffc0201ba8:	953e                	add	a0,a0,a5
}
ffffffffc0201baa:	60a2                	ld	ra,8(sp)
ffffffffc0201bac:	0141                	addi	sp,sp,16
ffffffffc0201bae:	8082                	ret
ffffffffc0201bb0:	86aa                	mv	a3,a0
ffffffffc0201bb2:	00005617          	auipc	a2,0x5
ffffffffc0201bb6:	a1660613          	addi	a2,a2,-1514 # ffffffffc02065c8 <etext+0xd90>
ffffffffc0201bba:	07100593          	li	a1,113
ffffffffc0201bbe:	00005517          	auipc	a0,0x5
ffffffffc0201bc2:	a3250513          	addi	a0,a0,-1486 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc0201bc6:	881fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201bca <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201bca:	7179                	addi	sp,sp,-48
ffffffffc0201bcc:	f406                	sd	ra,40(sp)
ffffffffc0201bce:	f022                	sd	s0,32(sp)
ffffffffc0201bd0:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bd2:	01050713          	addi	a4,a0,16
ffffffffc0201bd6:	6785                	lui	a5,0x1
ffffffffc0201bd8:	0af77e63          	bgeu	a4,a5,ffffffffc0201c94 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201bdc:	00f50413          	addi	s0,a0,15
ffffffffc0201be0:	8011                	srli	s0,s0,0x4
ffffffffc0201be2:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201be4:	100025f3          	csrr	a1,sstatus
ffffffffc0201be8:	8989                	andi	a1,a1,2
ffffffffc0201bea:	edd1                	bnez	a1,ffffffffc0201c86 <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201bec:	00095497          	auipc	s1,0x95
ffffffffc0201bf0:	5f448493          	addi	s1,s1,1524 # ffffffffc02971e0 <slobfree>
ffffffffc0201bf4:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bf6:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201bf8:	4314                	lw	a3,0(a4)
ffffffffc0201bfa:	0886da63          	bge	a3,s0,ffffffffc0201c8e <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201bfe:	00e60a63          	beq	a2,a4,ffffffffc0201c12 <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c02:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c04:	4394                	lw	a3,0(a5)
ffffffffc0201c06:	0286d863          	bge	a3,s0,ffffffffc0201c36 <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201c0a:	6090                	ld	a2,0(s1)
ffffffffc0201c0c:	873e                	mv	a4,a5
ffffffffc0201c0e:	fee61ae3          	bne	a2,a4,ffffffffc0201c02 <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201c12:	e9b1                	bnez	a1,ffffffffc0201c66 <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c14:	4501                	li	a0,0
ffffffffc0201c16:	f51ff0ef          	jal	ffffffffc0201b66 <__slob_get_free_pages.constprop.0>
ffffffffc0201c1a:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201c1c:	c915                	beqz	a0,ffffffffc0201c50 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c1e:	6585                	lui	a1,0x1
ffffffffc0201c20:	e35ff0ef          	jal	ffffffffc0201a54 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c24:	100025f3          	csrr	a1,sstatus
ffffffffc0201c28:	8989                	andi	a1,a1,2
ffffffffc0201c2a:	e98d                	bnez	a1,ffffffffc0201c5c <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201c2c:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c2e:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c30:	4394                	lw	a3,0(a5)
ffffffffc0201c32:	fc86cce3          	blt	a3,s0,ffffffffc0201c0a <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c36:	04d40563          	beq	s0,a3,ffffffffc0201c80 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201c3a:	00441613          	slli	a2,s0,0x4
ffffffffc0201c3e:	963e                	add	a2,a2,a5
ffffffffc0201c40:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201c42:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201c44:	9e81                	subw	a3,a3,s0
ffffffffc0201c46:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201c48:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201c4a:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201c4c:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201c4e:	ed99                	bnez	a1,ffffffffc0201c6c <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201c50:	70a2                	ld	ra,40(sp)
ffffffffc0201c52:	7402                	ld	s0,32(sp)
ffffffffc0201c54:	64e2                	ld	s1,24(sp)
ffffffffc0201c56:	853e                	mv	a0,a5
ffffffffc0201c58:	6145                	addi	sp,sp,48
ffffffffc0201c5a:	8082                	ret
        intr_disable();
ffffffffc0201c5c:	ca9fe0ef          	jal	ffffffffc0200904 <intr_disable>
			cur = slobfree;
ffffffffc0201c60:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201c62:	4585                	li	a1,1
ffffffffc0201c64:	b7e9                	j	ffffffffc0201c2e <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201c66:	c99fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c6a:	b76d                	j	ffffffffc0201c14 <slob_alloc.constprop.0+0x4a>
ffffffffc0201c6c:	e43e                	sd	a5,8(sp)
ffffffffc0201c6e:	c91fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c72:	67a2                	ld	a5,8(sp)
}
ffffffffc0201c74:	70a2                	ld	ra,40(sp)
ffffffffc0201c76:	7402                	ld	s0,32(sp)
ffffffffc0201c78:	64e2                	ld	s1,24(sp)
ffffffffc0201c7a:	853e                	mv	a0,a5
ffffffffc0201c7c:	6145                	addi	sp,sp,48
ffffffffc0201c7e:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c80:	6794                	ld	a3,8(a5)
ffffffffc0201c82:	e714                	sd	a3,8(a4)
ffffffffc0201c84:	b7e1                	j	ffffffffc0201c4c <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201c86:	c7ffe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201c8a:	4585                	li	a1,1
ffffffffc0201c8c:	b785                	j	ffffffffc0201bec <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c8e:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201c90:	8732                	mv	a4,a2
ffffffffc0201c92:	b755                	j	ffffffffc0201c36 <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c94:	00005697          	auipc	a3,0x5
ffffffffc0201c98:	96c68693          	addi	a3,a3,-1684 # ffffffffc0206600 <etext+0xdc8>
ffffffffc0201c9c:	00004617          	auipc	a2,0x4
ffffffffc0201ca0:	57c60613          	addi	a2,a2,1404 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0201ca4:	06300593          	li	a1,99
ffffffffc0201ca8:	00005517          	auipc	a0,0x5
ffffffffc0201cac:	97850513          	addi	a0,a0,-1672 # ffffffffc0206620 <etext+0xde8>
ffffffffc0201cb0:	f96fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201cb4 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201cb4:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201cb6:	00005517          	auipc	a0,0x5
ffffffffc0201cba:	98250513          	addi	a0,a0,-1662 # ffffffffc0206638 <etext+0xe00>
{
ffffffffc0201cbe:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201cc0:	cd4fe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201cc4:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cc6:	00005517          	auipc	a0,0x5
ffffffffc0201cca:	98a50513          	addi	a0,a0,-1654 # ffffffffc0206650 <etext+0xe18>
}
ffffffffc0201cce:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cd0:	cc4fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201cd4 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201cd4:	4501                	li	a0,0
ffffffffc0201cd6:	8082                	ret

ffffffffc0201cd8 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201cd8:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cda:	6685                	lui	a3,0x1
{
ffffffffc0201cdc:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cde:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7bc1>
ffffffffc0201ce0:	04a6f963          	bgeu	a3,a0,ffffffffc0201d32 <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ce4:	e42a                	sd	a0,8(sp)
ffffffffc0201ce6:	4561                	li	a0,24
ffffffffc0201ce8:	e822                	sd	s0,16(sp)
ffffffffc0201cea:	ee1ff0ef          	jal	ffffffffc0201bca <slob_alloc.constprop.0>
ffffffffc0201cee:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201cf0:	c541                	beqz	a0,ffffffffc0201d78 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201cf2:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201cf4:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201cf6:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201cf8:	00f75763          	bge	a4,a5,ffffffffc0201d06 <kmalloc+0x2e>
ffffffffc0201cfc:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201d00:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d02:	fef74de3          	blt	a4,a5,ffffffffc0201cfc <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201d06:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d08:	e5fff0ef          	jal	ffffffffc0201b66 <__slob_get_free_pages.constprop.0>
ffffffffc0201d0c:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201d0e:	cd31                	beqz	a0,ffffffffc0201d6a <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d10:	100027f3          	csrr	a5,sstatus
ffffffffc0201d14:	8b89                	andi	a5,a5,2
ffffffffc0201d16:	eb85                	bnez	a5,ffffffffc0201d46 <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201d18:	0009a797          	auipc	a5,0x9a
ffffffffc0201d1c:	9287b783          	ld	a5,-1752(a5) # ffffffffc029b640 <bigblocks>
		bigblocks = bb;
ffffffffc0201d20:	0009a717          	auipc	a4,0x9a
ffffffffc0201d24:	92873023          	sd	s0,-1760(a4) # ffffffffc029b640 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d28:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201d2a:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201d2c:	60e2                	ld	ra,24(sp)
ffffffffc0201d2e:	6105                	addi	sp,sp,32
ffffffffc0201d30:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d32:	0541                	addi	a0,a0,16
ffffffffc0201d34:	e97ff0ef          	jal	ffffffffc0201bca <slob_alloc.constprop.0>
ffffffffc0201d38:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d3a:	0541                	addi	a0,a0,16
ffffffffc0201d3c:	fbe5                	bnez	a5,ffffffffc0201d2c <kmalloc+0x54>
		return 0;
ffffffffc0201d3e:	4501                	li	a0,0
}
ffffffffc0201d40:	60e2                	ld	ra,24(sp)
ffffffffc0201d42:	6105                	addi	sp,sp,32
ffffffffc0201d44:	8082                	ret
        intr_disable();
ffffffffc0201d46:	bbffe0ef          	jal	ffffffffc0200904 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d4a:	0009a797          	auipc	a5,0x9a
ffffffffc0201d4e:	8f67b783          	ld	a5,-1802(a5) # ffffffffc029b640 <bigblocks>
		bigblocks = bb;
ffffffffc0201d52:	0009a717          	auipc	a4,0x9a
ffffffffc0201d56:	8e873723          	sd	s0,-1810(a4) # ffffffffc029b640 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d5a:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201d5c:	ba3fe0ef          	jal	ffffffffc02008fe <intr_enable>
		return bb->pages;
ffffffffc0201d60:	6408                	ld	a0,8(s0)
}
ffffffffc0201d62:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201d64:	6442                	ld	s0,16(sp)
}
ffffffffc0201d66:	6105                	addi	sp,sp,32
ffffffffc0201d68:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d6a:	8522                	mv	a0,s0
ffffffffc0201d6c:	45e1                	li	a1,24
ffffffffc0201d6e:	ce7ff0ef          	jal	ffffffffc0201a54 <slob_free>
		return 0;
ffffffffc0201d72:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d74:	6442                	ld	s0,16(sp)
ffffffffc0201d76:	b7e9                	j	ffffffffc0201d40 <kmalloc+0x68>
ffffffffc0201d78:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201d7a:	4501                	li	a0,0
ffffffffc0201d7c:	b7d1                	j	ffffffffc0201d40 <kmalloc+0x68>

ffffffffc0201d7e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d7e:	c571                	beqz	a0,ffffffffc0201e4a <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d80:	03451793          	slli	a5,a0,0x34
ffffffffc0201d84:	e3e1                	bnez	a5,ffffffffc0201e44 <kfree+0xc6>
{
ffffffffc0201d86:	1101                	addi	sp,sp,-32
ffffffffc0201d88:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d8a:	100027f3          	csrr	a5,sstatus
ffffffffc0201d8e:	8b89                	andi	a5,a5,2
ffffffffc0201d90:	e7c1                	bnez	a5,ffffffffc0201e18 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d92:	0009a797          	auipc	a5,0x9a
ffffffffc0201d96:	8ae7b783          	ld	a5,-1874(a5) # ffffffffc029b640 <bigblocks>
    return 0;
ffffffffc0201d9a:	4581                	li	a1,0
ffffffffc0201d9c:	cbad                	beqz	a5,ffffffffc0201e0e <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d9e:	0009a617          	auipc	a2,0x9a
ffffffffc0201da2:	8a260613          	addi	a2,a2,-1886 # ffffffffc029b640 <bigblocks>
ffffffffc0201da6:	a021                	j	ffffffffc0201dae <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201da8:	01070613          	addi	a2,a4,16
ffffffffc0201dac:	c3a5                	beqz	a5,ffffffffc0201e0c <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201dae:	6794                	ld	a3,8(a5)
ffffffffc0201db0:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201db2:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201db4:	fea69ae3          	bne	a3,a0,ffffffffc0201da8 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201db8:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201dba:	edb5                	bnez	a1,ffffffffc0201e36 <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201dbc:	c02007b7          	lui	a5,0xc0200
ffffffffc0201dc0:	0af56263          	bltu	a0,a5,ffffffffc0201e64 <kfree+0xe6>
ffffffffc0201dc4:	0009a797          	auipc	a5,0x9a
ffffffffc0201dc8:	89c7b783          	ld	a5,-1892(a5) # ffffffffc029b660 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201dcc:	0009a697          	auipc	a3,0x9a
ffffffffc0201dd0:	89c6b683          	ld	a3,-1892(a3) # ffffffffc029b668 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201dd4:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201dd6:	00c55793          	srli	a5,a0,0xc
ffffffffc0201dda:	06d7f963          	bgeu	a5,a3,ffffffffc0201e4c <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dde:	00006617          	auipc	a2,0x6
ffffffffc0201de2:	bca63603          	ld	a2,-1078(a2) # ffffffffc02079a8 <nbase>
ffffffffc0201de6:	0009a517          	auipc	a0,0x9a
ffffffffc0201dea:	88a53503          	ld	a0,-1910(a0) # ffffffffc029b670 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201dee:	4314                	lw	a3,0(a4)
ffffffffc0201df0:	8f91                	sub	a5,a5,a2
ffffffffc0201df2:	079a                	slli	a5,a5,0x6
ffffffffc0201df4:	4585                	li	a1,1
ffffffffc0201df6:	953e                	add	a0,a0,a5
ffffffffc0201df8:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201dfc:	e03a                	sd	a4,0(sp)
ffffffffc0201dfe:	0d6000ef          	jal	ffffffffc0201ed4 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e02:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e04:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e06:	45e1                	li	a1,24
}
ffffffffc0201e08:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e0a:	b1a9                	j	ffffffffc0201a54 <slob_free>
ffffffffc0201e0c:	e185                	bnez	a1,ffffffffc0201e2c <kfree+0xae>
}
ffffffffc0201e0e:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e10:	1541                	addi	a0,a0,-16
ffffffffc0201e12:	4581                	li	a1,0
}
ffffffffc0201e14:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e16:	b93d                	j	ffffffffc0201a54 <slob_free>
        intr_disable();
ffffffffc0201e18:	e02a                	sd	a0,0(sp)
ffffffffc0201e1a:	aebfe0ef          	jal	ffffffffc0200904 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e1e:	0009a797          	auipc	a5,0x9a
ffffffffc0201e22:	8227b783          	ld	a5,-2014(a5) # ffffffffc029b640 <bigblocks>
ffffffffc0201e26:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201e28:	4585                	li	a1,1
ffffffffc0201e2a:	fbb5                	bnez	a5,ffffffffc0201d9e <kfree+0x20>
ffffffffc0201e2c:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201e2e:	ad1fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e32:	6502                	ld	a0,0(sp)
ffffffffc0201e34:	bfe9                	j	ffffffffc0201e0e <kfree+0x90>
ffffffffc0201e36:	e42a                	sd	a0,8(sp)
ffffffffc0201e38:	e03a                	sd	a4,0(sp)
ffffffffc0201e3a:	ac5fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e3e:	6522                	ld	a0,8(sp)
ffffffffc0201e40:	6702                	ld	a4,0(sp)
ffffffffc0201e42:	bfad                	j	ffffffffc0201dbc <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e44:	1541                	addi	a0,a0,-16
ffffffffc0201e46:	4581                	li	a1,0
ffffffffc0201e48:	b131                	j	ffffffffc0201a54 <slob_free>
ffffffffc0201e4a:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e4c:	00005617          	auipc	a2,0x5
ffffffffc0201e50:	84c60613          	addi	a2,a2,-1972 # ffffffffc0206698 <etext+0xe60>
ffffffffc0201e54:	06900593          	li	a1,105
ffffffffc0201e58:	00004517          	auipc	a0,0x4
ffffffffc0201e5c:	79850513          	addi	a0,a0,1944 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc0201e60:	de6fe0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e64:	86aa                	mv	a3,a0
ffffffffc0201e66:	00005617          	auipc	a2,0x5
ffffffffc0201e6a:	80a60613          	addi	a2,a2,-2038 # ffffffffc0206670 <etext+0xe38>
ffffffffc0201e6e:	07700593          	li	a1,119
ffffffffc0201e72:	00004517          	auipc	a0,0x4
ffffffffc0201e76:	77e50513          	addi	a0,a0,1918 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc0201e7a:	dccfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201e7e <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e7e:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e80:	00005617          	auipc	a2,0x5
ffffffffc0201e84:	81860613          	addi	a2,a2,-2024 # ffffffffc0206698 <etext+0xe60>
ffffffffc0201e88:	06900593          	li	a1,105
ffffffffc0201e8c:	00004517          	auipc	a0,0x4
ffffffffc0201e90:	76450513          	addi	a0,a0,1892 # ffffffffc02065f0 <etext+0xdb8>
pa2page(uintptr_t pa)
ffffffffc0201e94:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e96:	db0fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201e9a <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e9a:	100027f3          	csrr	a5,sstatus
ffffffffc0201e9e:	8b89                	andi	a5,a5,2
ffffffffc0201ea0:	e799                	bnez	a5,ffffffffc0201eae <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ea2:	00099797          	auipc	a5,0x99
ffffffffc0201ea6:	7a67b783          	ld	a5,1958(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201eaa:	6f9c                	ld	a5,24(a5)
ffffffffc0201eac:	8782                	jr	a5
{
ffffffffc0201eae:	1101                	addi	sp,sp,-32
ffffffffc0201eb0:	ec06                	sd	ra,24(sp)
ffffffffc0201eb2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201eb4:	a51fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201eb8:	00099797          	auipc	a5,0x99
ffffffffc0201ebc:	7907b783          	ld	a5,1936(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201ec0:	6522                	ld	a0,8(sp)
ffffffffc0201ec2:	6f9c                	ld	a5,24(a5)
ffffffffc0201ec4:	9782                	jalr	a5
ffffffffc0201ec6:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201ec8:	a37fe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201ecc:	60e2                	ld	ra,24(sp)
ffffffffc0201ece:	6522                	ld	a0,8(sp)
ffffffffc0201ed0:	6105                	addi	sp,sp,32
ffffffffc0201ed2:	8082                	ret

ffffffffc0201ed4 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ed4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ed8:	8b89                	andi	a5,a5,2
ffffffffc0201eda:	e799                	bnez	a5,ffffffffc0201ee8 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201edc:	00099797          	auipc	a5,0x99
ffffffffc0201ee0:	76c7b783          	ld	a5,1900(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201ee4:	739c                	ld	a5,32(a5)
ffffffffc0201ee6:	8782                	jr	a5
{
ffffffffc0201ee8:	1101                	addi	sp,sp,-32
ffffffffc0201eea:	ec06                	sd	ra,24(sp)
ffffffffc0201eec:	e42e                	sd	a1,8(sp)
ffffffffc0201eee:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201ef0:	a15fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ef4:	00099797          	auipc	a5,0x99
ffffffffc0201ef8:	7547b783          	ld	a5,1876(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201efc:	65a2                	ld	a1,8(sp)
ffffffffc0201efe:	6502                	ld	a0,0(sp)
ffffffffc0201f00:	739c                	ld	a5,32(a5)
ffffffffc0201f02:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f04:	60e2                	ld	ra,24(sp)
ffffffffc0201f06:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f08:	9f7fe06f          	j	ffffffffc02008fe <intr_enable>

ffffffffc0201f0c <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f0c:	100027f3          	csrr	a5,sstatus
ffffffffc0201f10:	8b89                	andi	a5,a5,2
ffffffffc0201f12:	e799                	bnez	a5,ffffffffc0201f20 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f14:	00099797          	auipc	a5,0x99
ffffffffc0201f18:	7347b783          	ld	a5,1844(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201f1c:	779c                	ld	a5,40(a5)
ffffffffc0201f1e:	8782                	jr	a5
{
ffffffffc0201f20:	1101                	addi	sp,sp,-32
ffffffffc0201f22:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201f24:	9e1fe0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f28:	00099797          	auipc	a5,0x99
ffffffffc0201f2c:	7207b783          	ld	a5,1824(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201f30:	779c                	ld	a5,40(a5)
ffffffffc0201f32:	9782                	jalr	a5
ffffffffc0201f34:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f36:	9c9fe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f3a:	60e2                	ld	ra,24(sp)
ffffffffc0201f3c:	6522                	ld	a0,8(sp)
ffffffffc0201f3e:	6105                	addi	sp,sp,32
ffffffffc0201f40:	8082                	ret

ffffffffc0201f42 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f42:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f46:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f4a:	078e                	slli	a5,a5,0x3
ffffffffc0201f4c:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f50:	6314                	ld	a3,0(a4)
{
ffffffffc0201f52:	7139                	addi	sp,sp,-64
ffffffffc0201f54:	f822                	sd	s0,48(sp)
ffffffffc0201f56:	f426                	sd	s1,40(sp)
ffffffffc0201f58:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f5a:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f5e:	842e                	mv	s0,a1
ffffffffc0201f60:	8832                	mv	a6,a2
ffffffffc0201f62:	00099497          	auipc	s1,0x99
ffffffffc0201f66:	70648493          	addi	s1,s1,1798 # ffffffffc029b668 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f6a:	ebd1                	bnez	a5,ffffffffc0201ffe <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f6c:	16060d63          	beqz	a2,ffffffffc02020e6 <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f70:	100027f3          	csrr	a5,sstatus
ffffffffc0201f74:	8b89                	andi	a5,a5,2
ffffffffc0201f76:	16079e63          	bnez	a5,ffffffffc02020f2 <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f7a:	00099797          	auipc	a5,0x99
ffffffffc0201f7e:	6ce7b783          	ld	a5,1742(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0201f82:	4505                	li	a0,1
ffffffffc0201f84:	e43a                	sd	a4,8(sp)
ffffffffc0201f86:	6f9c                	ld	a5,24(a5)
ffffffffc0201f88:	e832                	sd	a2,16(sp)
ffffffffc0201f8a:	9782                	jalr	a5
ffffffffc0201f8c:	6722                	ld	a4,8(sp)
ffffffffc0201f8e:	6842                	ld	a6,16(sp)
ffffffffc0201f90:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f92:	14078a63          	beqz	a5,ffffffffc02020e6 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201f96:	00099517          	auipc	a0,0x99
ffffffffc0201f9a:	6da53503          	ld	a0,1754(a0) # ffffffffc029b670 <pages>
ffffffffc0201f9e:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fa2:	00099497          	auipc	s1,0x99
ffffffffc0201fa6:	6c648493          	addi	s1,s1,1734 # ffffffffc029b668 <npage>
ffffffffc0201faa:	40a78533          	sub	a0,a5,a0
ffffffffc0201fae:	8519                	srai	a0,a0,0x6
ffffffffc0201fb0:	9546                	add	a0,a0,a7
ffffffffc0201fb2:	6090                	ld	a2,0(s1)
ffffffffc0201fb4:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201fb8:	4585                	li	a1,1
ffffffffc0201fba:	82b1                	srli	a3,a3,0xc
ffffffffc0201fbc:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fbe:	0532                	slli	a0,a0,0xc
ffffffffc0201fc0:	1ac6f763          	bgeu	a3,a2,ffffffffc020216e <get_pte+0x22c>
ffffffffc0201fc4:	00099697          	auipc	a3,0x99
ffffffffc0201fc8:	69c6b683          	ld	a3,1692(a3) # ffffffffc029b660 <va_pa_offset>
ffffffffc0201fcc:	6605                	lui	a2,0x1
ffffffffc0201fce:	4581                	li	a1,0
ffffffffc0201fd0:	9536                	add	a0,a0,a3
ffffffffc0201fd2:	ec42                	sd	a6,24(sp)
ffffffffc0201fd4:	e83e                	sd	a5,16(sp)
ffffffffc0201fd6:	e43a                	sd	a4,8(sp)
ffffffffc0201fd8:	037030ef          	jal	ffffffffc020580e <memset>
    return page - pages + nbase;
ffffffffc0201fdc:	00099697          	auipc	a3,0x99
ffffffffc0201fe0:	6946b683          	ld	a3,1684(a3) # ffffffffc029b670 <pages>
ffffffffc0201fe4:	67c2                	ld	a5,16(sp)
ffffffffc0201fe6:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fea:	6722                	ld	a4,8(sp)
ffffffffc0201fec:	40d786b3          	sub	a3,a5,a3
ffffffffc0201ff0:	8699                	srai	a3,a3,0x6
ffffffffc0201ff2:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ff4:	06aa                	slli	a3,a3,0xa
ffffffffc0201ff6:	6862                	ld	a6,24(sp)
ffffffffc0201ff8:	0116e693          	ori	a3,a3,17
ffffffffc0201ffc:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ffe:	c006f693          	andi	a3,a3,-1024
ffffffffc0202002:	6098                	ld	a4,0(s1)
ffffffffc0202004:	068a                	slli	a3,a3,0x2
ffffffffc0202006:	00c6d793          	srli	a5,a3,0xc
ffffffffc020200a:	14e7f663          	bgeu	a5,a4,ffffffffc0202156 <get_pte+0x214>
ffffffffc020200e:	00099897          	auipc	a7,0x99
ffffffffc0202012:	65288893          	addi	a7,a7,1618 # ffffffffc029b660 <va_pa_offset>
ffffffffc0202016:	0008b603          	ld	a2,0(a7)
ffffffffc020201a:	01545793          	srli	a5,s0,0x15
ffffffffc020201e:	1ff7f793          	andi	a5,a5,511
ffffffffc0202022:	96b2                	add	a3,a3,a2
ffffffffc0202024:	078e                	slli	a5,a5,0x3
ffffffffc0202026:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202028:	6394                	ld	a3,0(a5)
ffffffffc020202a:	0016f613          	andi	a2,a3,1
ffffffffc020202e:	e659                	bnez	a2,ffffffffc02020bc <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202030:	0a080b63          	beqz	a6,ffffffffc02020e6 <get_pte+0x1a4>
ffffffffc0202034:	10002773          	csrr	a4,sstatus
ffffffffc0202038:	8b09                	andi	a4,a4,2
ffffffffc020203a:	ef71                	bnez	a4,ffffffffc0202116 <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020203c:	00099717          	auipc	a4,0x99
ffffffffc0202040:	60c73703          	ld	a4,1548(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc0202044:	4505                	li	a0,1
ffffffffc0202046:	e43e                	sd	a5,8(sp)
ffffffffc0202048:	6f18                	ld	a4,24(a4)
ffffffffc020204a:	9702                	jalr	a4
ffffffffc020204c:	67a2                	ld	a5,8(sp)
ffffffffc020204e:	872a                	mv	a4,a0
ffffffffc0202050:	00099897          	auipc	a7,0x99
ffffffffc0202054:	61088893          	addi	a7,a7,1552 # ffffffffc029b660 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202058:	c759                	beqz	a4,ffffffffc02020e6 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc020205a:	00099697          	auipc	a3,0x99
ffffffffc020205e:	6166b683          	ld	a3,1558(a3) # ffffffffc029b670 <pages>
ffffffffc0202062:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202066:	608c                	ld	a1,0(s1)
ffffffffc0202068:	40d706b3          	sub	a3,a4,a3
ffffffffc020206c:	8699                	srai	a3,a3,0x6
ffffffffc020206e:	96c2                	add	a3,a3,a6
ffffffffc0202070:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0202074:	4505                	li	a0,1
ffffffffc0202076:	8231                	srli	a2,a2,0xc
ffffffffc0202078:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc020207a:	06b2                	slli	a3,a3,0xc
ffffffffc020207c:	10b67663          	bgeu	a2,a1,ffffffffc0202188 <get_pte+0x246>
ffffffffc0202080:	0008b503          	ld	a0,0(a7)
ffffffffc0202084:	6605                	lui	a2,0x1
ffffffffc0202086:	4581                	li	a1,0
ffffffffc0202088:	9536                	add	a0,a0,a3
ffffffffc020208a:	e83a                	sd	a4,16(sp)
ffffffffc020208c:	e43e                	sd	a5,8(sp)
ffffffffc020208e:	780030ef          	jal	ffffffffc020580e <memset>
    return page - pages + nbase;
ffffffffc0202092:	00099697          	auipc	a3,0x99
ffffffffc0202096:	5de6b683          	ld	a3,1502(a3) # ffffffffc029b670 <pages>
ffffffffc020209a:	6742                	ld	a4,16(sp)
ffffffffc020209c:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020a0:	67a2                	ld	a5,8(sp)
ffffffffc02020a2:	40d706b3          	sub	a3,a4,a3
ffffffffc02020a6:	8699                	srai	a3,a3,0x6
ffffffffc02020a8:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020aa:	06aa                	slli	a3,a3,0xa
ffffffffc02020ac:	0116e693          	ori	a3,a3,17
ffffffffc02020b0:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020b2:	6098                	ld	a4,0(s1)
ffffffffc02020b4:	00099897          	auipc	a7,0x99
ffffffffc02020b8:	5ac88893          	addi	a7,a7,1452 # ffffffffc029b660 <va_pa_offset>
ffffffffc02020bc:	c006f693          	andi	a3,a3,-1024
ffffffffc02020c0:	068a                	slli	a3,a3,0x2
ffffffffc02020c2:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020c6:	06e7fc63          	bgeu	a5,a4,ffffffffc020213e <get_pte+0x1fc>
ffffffffc02020ca:	0008b783          	ld	a5,0(a7)
ffffffffc02020ce:	8031                	srli	s0,s0,0xc
ffffffffc02020d0:	1ff47413          	andi	s0,s0,511
ffffffffc02020d4:	040e                	slli	s0,s0,0x3
ffffffffc02020d6:	96be                	add	a3,a3,a5
}
ffffffffc02020d8:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020da:	00868533          	add	a0,a3,s0
}
ffffffffc02020de:	7442                	ld	s0,48(sp)
ffffffffc02020e0:	74a2                	ld	s1,40(sp)
ffffffffc02020e2:	6121                	addi	sp,sp,64
ffffffffc02020e4:	8082                	ret
ffffffffc02020e6:	70e2                	ld	ra,56(sp)
ffffffffc02020e8:	7442                	ld	s0,48(sp)
ffffffffc02020ea:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc02020ec:	4501                	li	a0,0
}
ffffffffc02020ee:	6121                	addi	sp,sp,64
ffffffffc02020f0:	8082                	ret
        intr_disable();
ffffffffc02020f2:	e83a                	sd	a4,16(sp)
ffffffffc02020f4:	ec32                	sd	a2,24(sp)
ffffffffc02020f6:	80ffe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020fa:	00099797          	auipc	a5,0x99
ffffffffc02020fe:	54e7b783          	ld	a5,1358(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0202102:	4505                	li	a0,1
ffffffffc0202104:	6f9c                	ld	a5,24(a5)
ffffffffc0202106:	9782                	jalr	a5
ffffffffc0202108:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020210a:	ff4fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020210e:	6862                	ld	a6,24(sp)
ffffffffc0202110:	6742                	ld	a4,16(sp)
ffffffffc0202112:	67a2                	ld	a5,8(sp)
ffffffffc0202114:	bdbd                	j	ffffffffc0201f92 <get_pte+0x50>
        intr_disable();
ffffffffc0202116:	e83e                	sd	a5,16(sp)
ffffffffc0202118:	fecfe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020211c:	00099717          	auipc	a4,0x99
ffffffffc0202120:	52c73703          	ld	a4,1324(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc0202124:	4505                	li	a0,1
ffffffffc0202126:	6f18                	ld	a4,24(a4)
ffffffffc0202128:	9702                	jalr	a4
ffffffffc020212a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020212c:	fd2fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202130:	6722                	ld	a4,8(sp)
ffffffffc0202132:	67c2                	ld	a5,16(sp)
ffffffffc0202134:	00099897          	auipc	a7,0x99
ffffffffc0202138:	52c88893          	addi	a7,a7,1324 # ffffffffc029b660 <va_pa_offset>
ffffffffc020213c:	bf31                	j	ffffffffc0202058 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020213e:	00004617          	auipc	a2,0x4
ffffffffc0202142:	48a60613          	addi	a2,a2,1162 # ffffffffc02065c8 <etext+0xd90>
ffffffffc0202146:	0fa00593          	li	a1,250
ffffffffc020214a:	00004517          	auipc	a0,0x4
ffffffffc020214e:	56e50513          	addi	a0,a0,1390 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202152:	af4fe0ef          	jal	ffffffffc0200446 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202156:	00004617          	auipc	a2,0x4
ffffffffc020215a:	47260613          	addi	a2,a2,1138 # ffffffffc02065c8 <etext+0xd90>
ffffffffc020215e:	0ed00593          	li	a1,237
ffffffffc0202162:	00004517          	auipc	a0,0x4
ffffffffc0202166:	55650513          	addi	a0,a0,1366 # ffffffffc02066b8 <etext+0xe80>
ffffffffc020216a:	adcfe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020216e:	86aa                	mv	a3,a0
ffffffffc0202170:	00004617          	auipc	a2,0x4
ffffffffc0202174:	45860613          	addi	a2,a2,1112 # ffffffffc02065c8 <etext+0xd90>
ffffffffc0202178:	0e900593          	li	a1,233
ffffffffc020217c:	00004517          	auipc	a0,0x4
ffffffffc0202180:	53c50513          	addi	a0,a0,1340 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202184:	ac2fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202188:	00004617          	auipc	a2,0x4
ffffffffc020218c:	44060613          	addi	a2,a2,1088 # ffffffffc02065c8 <etext+0xd90>
ffffffffc0202190:	0f700593          	li	a1,247
ffffffffc0202194:	00004517          	auipc	a0,0x4
ffffffffc0202198:	52450513          	addi	a0,a0,1316 # ffffffffc02066b8 <etext+0xe80>
ffffffffc020219c:	aaafe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02021a0 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02021a0:	1141                	addi	sp,sp,-16
ffffffffc02021a2:	e022                	sd	s0,0(sp)
ffffffffc02021a4:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021a6:	4601                	li	a2,0
{
ffffffffc02021a8:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021aa:	d99ff0ef          	jal	ffffffffc0201f42 <get_pte>
    if (ptep_store != NULL)
ffffffffc02021ae:	c011                	beqz	s0,ffffffffc02021b2 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc02021b0:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021b2:	c511                	beqz	a0,ffffffffc02021be <get_page+0x1e>
ffffffffc02021b4:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02021b6:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc02021b8:	0017f713          	andi	a4,a5,1
ffffffffc02021bc:	e709                	bnez	a4,ffffffffc02021c6 <get_page+0x26>
}
ffffffffc02021be:	60a2                	ld	ra,8(sp)
ffffffffc02021c0:	6402                	ld	s0,0(sp)
ffffffffc02021c2:	0141                	addi	sp,sp,16
ffffffffc02021c4:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02021c6:	00099717          	auipc	a4,0x99
ffffffffc02021ca:	4a273703          	ld	a4,1186(a4) # ffffffffc029b668 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02021ce:	078a                	slli	a5,a5,0x2
ffffffffc02021d0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021d2:	00e7ff63          	bgeu	a5,a4,ffffffffc02021f0 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc02021d6:	00099517          	auipc	a0,0x99
ffffffffc02021da:	49a53503          	ld	a0,1178(a0) # ffffffffc029b670 <pages>
ffffffffc02021de:	60a2                	ld	ra,8(sp)
ffffffffc02021e0:	6402                	ld	s0,0(sp)
ffffffffc02021e2:	079a                	slli	a5,a5,0x6
ffffffffc02021e4:	fe000737          	lui	a4,0xfe000
ffffffffc02021e8:	97ba                	add	a5,a5,a4
ffffffffc02021ea:	953e                	add	a0,a0,a5
ffffffffc02021ec:	0141                	addi	sp,sp,16
ffffffffc02021ee:	8082                	ret
ffffffffc02021f0:	c8fff0ef          	jal	ffffffffc0201e7e <pa2page.part.0>

ffffffffc02021f4 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02021f4:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021f6:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02021fa:	e486                	sd	ra,72(sp)
ffffffffc02021fc:	e0a2                	sd	s0,64(sp)
ffffffffc02021fe:	fc26                	sd	s1,56(sp)
ffffffffc0202200:	f84a                	sd	s2,48(sp)
ffffffffc0202202:	f44e                	sd	s3,40(sp)
ffffffffc0202204:	f052                	sd	s4,32(sp)
ffffffffc0202206:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202208:	03479713          	slli	a4,a5,0x34
ffffffffc020220c:	ef61                	bnez	a4,ffffffffc02022e4 <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc020220e:	00200a37          	lui	s4,0x200
ffffffffc0202212:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc0202216:	0145b733          	sltu	a4,a1,s4
ffffffffc020221a:	0017b793          	seqz	a5,a5
ffffffffc020221e:	8fd9                	or	a5,a5,a4
ffffffffc0202220:	842e                	mv	s0,a1
ffffffffc0202222:	84b2                	mv	s1,a2
ffffffffc0202224:	e3e5                	bnez	a5,ffffffffc0202304 <unmap_range+0x110>
ffffffffc0202226:	4785                	li	a5,1
ffffffffc0202228:	07fe                	slli	a5,a5,0x1f
ffffffffc020222a:	0785                	addi	a5,a5,1
ffffffffc020222c:	892a                	mv	s2,a0
ffffffffc020222e:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202230:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc0202234:	0cf67863          	bgeu	a2,a5,ffffffffc0202304 <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202238:	4601                	li	a2,0
ffffffffc020223a:	85a2                	mv	a1,s0
ffffffffc020223c:	854a                	mv	a0,s2
ffffffffc020223e:	d05ff0ef          	jal	ffffffffc0201f42 <get_pte>
ffffffffc0202242:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc0202244:	cd31                	beqz	a0,ffffffffc02022a0 <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc0202246:	6118                	ld	a4,0(a0)
ffffffffc0202248:	ef11                	bnez	a4,ffffffffc0202264 <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020224a:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc020224c:	c019                	beqz	s0,ffffffffc0202252 <unmap_range+0x5e>
ffffffffc020224e:	fe9465e3          	bltu	s0,s1,ffffffffc0202238 <unmap_range+0x44>
}
ffffffffc0202252:	60a6                	ld	ra,72(sp)
ffffffffc0202254:	6406                	ld	s0,64(sp)
ffffffffc0202256:	74e2                	ld	s1,56(sp)
ffffffffc0202258:	7942                	ld	s2,48(sp)
ffffffffc020225a:	79a2                	ld	s3,40(sp)
ffffffffc020225c:	7a02                	ld	s4,32(sp)
ffffffffc020225e:	6ae2                	ld	s5,24(sp)
ffffffffc0202260:	6161                	addi	sp,sp,80
ffffffffc0202262:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202264:	00177693          	andi	a3,a4,1
ffffffffc0202268:	d2ed                	beqz	a3,ffffffffc020224a <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc020226a:	00099697          	auipc	a3,0x99
ffffffffc020226e:	3fe6b683          	ld	a3,1022(a3) # ffffffffc029b668 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202272:	070a                	slli	a4,a4,0x2
ffffffffc0202274:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202276:	0ad77763          	bgeu	a4,a3,ffffffffc0202324 <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc020227a:	00099517          	auipc	a0,0x99
ffffffffc020227e:	3f653503          	ld	a0,1014(a0) # ffffffffc029b670 <pages>
ffffffffc0202282:	071a                	slli	a4,a4,0x6
ffffffffc0202284:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202288:	9736                	add	a4,a4,a3
ffffffffc020228a:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc020228c:	4118                	lw	a4,0(a0)
ffffffffc020228e:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd64967>
ffffffffc0202290:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202292:	cb19                	beqz	a4,ffffffffc02022a8 <unmap_range+0xb4>
        *ptep = 0;
ffffffffc0202294:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202298:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020229c:	944e                	add	s0,s0,s3
ffffffffc020229e:	b77d                	j	ffffffffc020224c <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022a0:	9452                	add	s0,s0,s4
ffffffffc02022a2:	01547433          	and	s0,s0,s5
            continue;
ffffffffc02022a6:	b75d                	j	ffffffffc020224c <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02022a8:	10002773          	csrr	a4,sstatus
ffffffffc02022ac:	8b09                	andi	a4,a4,2
ffffffffc02022ae:	eb19                	bnez	a4,ffffffffc02022c4 <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc02022b0:	00099717          	auipc	a4,0x99
ffffffffc02022b4:	39873703          	ld	a4,920(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc02022b8:	4585                	li	a1,1
ffffffffc02022ba:	e03e                	sd	a5,0(sp)
ffffffffc02022bc:	7318                	ld	a4,32(a4)
ffffffffc02022be:	9702                	jalr	a4
    if (flag)
ffffffffc02022c0:	6782                	ld	a5,0(sp)
ffffffffc02022c2:	bfc9                	j	ffffffffc0202294 <unmap_range+0xa0>
        intr_disable();
ffffffffc02022c4:	e43e                	sd	a5,8(sp)
ffffffffc02022c6:	e02a                	sd	a0,0(sp)
ffffffffc02022c8:	e3cfe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc02022cc:	00099717          	auipc	a4,0x99
ffffffffc02022d0:	37c73703          	ld	a4,892(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc02022d4:	6502                	ld	a0,0(sp)
ffffffffc02022d6:	4585                	li	a1,1
ffffffffc02022d8:	7318                	ld	a4,32(a4)
ffffffffc02022da:	9702                	jalr	a4
        intr_enable();
ffffffffc02022dc:	e22fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02022e0:	67a2                	ld	a5,8(sp)
ffffffffc02022e2:	bf4d                	j	ffffffffc0202294 <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022e4:	00004697          	auipc	a3,0x4
ffffffffc02022e8:	3e468693          	addi	a3,a3,996 # ffffffffc02066c8 <etext+0xe90>
ffffffffc02022ec:	00004617          	auipc	a2,0x4
ffffffffc02022f0:	f2c60613          	addi	a2,a2,-212 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02022f4:	12000593          	li	a1,288
ffffffffc02022f8:	00004517          	auipc	a0,0x4
ffffffffc02022fc:	3c050513          	addi	a0,a0,960 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202300:	946fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202304:	00004697          	auipc	a3,0x4
ffffffffc0202308:	3f468693          	addi	a3,a3,1012 # ffffffffc02066f8 <etext+0xec0>
ffffffffc020230c:	00004617          	auipc	a2,0x4
ffffffffc0202310:	f0c60613          	addi	a2,a2,-244 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0202314:	12100593          	li	a1,289
ffffffffc0202318:	00004517          	auipc	a0,0x4
ffffffffc020231c:	3a050513          	addi	a0,a0,928 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202320:	926fe0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202324:	b5bff0ef          	jal	ffffffffc0201e7e <pa2page.part.0>

ffffffffc0202328 <exit_range>:
{
ffffffffc0202328:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020232a:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020232e:	ed06                	sd	ra,152(sp)
ffffffffc0202330:	e922                	sd	s0,144(sp)
ffffffffc0202332:	e526                	sd	s1,136(sp)
ffffffffc0202334:	e14a                	sd	s2,128(sp)
ffffffffc0202336:	fcce                	sd	s3,120(sp)
ffffffffc0202338:	f8d2                	sd	s4,112(sp)
ffffffffc020233a:	f4d6                	sd	s5,104(sp)
ffffffffc020233c:	f0da                	sd	s6,96(sp)
ffffffffc020233e:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202340:	17d2                	slli	a5,a5,0x34
ffffffffc0202342:	22079263          	bnez	a5,ffffffffc0202566 <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc0202346:	00200937          	lui	s2,0x200
ffffffffc020234a:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020234e:	0125b733          	sltu	a4,a1,s2
ffffffffc0202352:	0017b793          	seqz	a5,a5
ffffffffc0202356:	8fd9                	or	a5,a5,a4
ffffffffc0202358:	26079263          	bnez	a5,ffffffffc02025bc <exit_range+0x294>
ffffffffc020235c:	4785                	li	a5,1
ffffffffc020235e:	07fe                	slli	a5,a5,0x1f
ffffffffc0202360:	0785                	addi	a5,a5,1
ffffffffc0202362:	24f67d63          	bgeu	a2,a5,ffffffffc02025bc <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202366:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020236a:	ffe007b7          	lui	a5,0xffe00
ffffffffc020236e:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202370:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202372:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc0202376:	00099a97          	auipc	s5,0x99
ffffffffc020237a:	2f2a8a93          	addi	s5,s5,754 # ffffffffc029b668 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020237e:	400009b7          	lui	s3,0x40000
ffffffffc0202382:	a809                	j	ffffffffc0202394 <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc0202384:	013487b3          	add	a5,s1,s3
ffffffffc0202388:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc020238c:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc020238e:	c3f1                	beqz	a5,ffffffffc0202452 <exit_range+0x12a>
ffffffffc0202390:	0cc7f163          	bgeu	a5,a2,ffffffffc0202452 <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202394:	01e4d413          	srli	s0,s1,0x1e
ffffffffc0202398:	1ff47413          	andi	s0,s0,511
ffffffffc020239c:	040e                	slli	s0,s0,0x3
ffffffffc020239e:	9452                	add	s0,s0,s4
ffffffffc02023a0:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc02023a4:	0018f793          	andi	a5,a7,1
ffffffffc02023a8:	dff1                	beqz	a5,ffffffffc0202384 <exit_range+0x5c>
ffffffffc02023aa:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023ae:	088a                	slli	a7,a7,0x2
ffffffffc02023b0:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc02023b4:	20f8f263          	bgeu	a7,a5,ffffffffc02025b8 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02023b8:	fff802b7          	lui	t0,0xfff80
ffffffffc02023bc:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc02023c0:	000803b7          	lui	t2,0x80
ffffffffc02023c4:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc02023c8:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023cc:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc02023ce:	1cf77863          	bgeu	a4,a5,ffffffffc020259e <exit_range+0x276>
ffffffffc02023d2:	00099f97          	auipc	t6,0x99
ffffffffc02023d6:	28ef8f93          	addi	t6,t6,654 # ffffffffc029b660 <va_pa_offset>
ffffffffc02023da:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc02023de:	4e85                	li	t4,1
ffffffffc02023e0:	6b05                	lui	s6,0x1
ffffffffc02023e2:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023e4:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023e8:	01585713          	srli	a4,a6,0x15
ffffffffc02023ec:	1ff77713          	andi	a4,a4,511
ffffffffc02023f0:	070e                	slli	a4,a4,0x3
ffffffffc02023f2:	9772                	add	a4,a4,t3
ffffffffc02023f4:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc02023f6:	0017f693          	andi	a3,a5,1
ffffffffc02023fa:	e6bd                	bnez	a3,ffffffffc0202468 <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc02023fc:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc02023fe:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202400:	00080863          	beqz	a6,ffffffffc0202410 <exit_range+0xe8>
ffffffffc0202404:	879a                	mv	a5,t1
ffffffffc0202406:	00667363          	bgeu	a2,t1,ffffffffc020240c <exit_range+0xe4>
ffffffffc020240a:	87b2                	mv	a5,a2
ffffffffc020240c:	fcf86ee3          	bltu	a6,a5,ffffffffc02023e8 <exit_range+0xc0>
            if (free_pd0)
ffffffffc0202410:	f60e8ae3          	beqz	t4,ffffffffc0202384 <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc0202414:	000ab783          	ld	a5,0(s5)
ffffffffc0202418:	1af8f063          	bgeu	a7,a5,ffffffffc02025b8 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc020241c:	00099517          	auipc	a0,0x99
ffffffffc0202420:	25453503          	ld	a0,596(a0) # ffffffffc029b670 <pages>
ffffffffc0202424:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202426:	100027f3          	csrr	a5,sstatus
ffffffffc020242a:	8b89                	andi	a5,a5,2
ffffffffc020242c:	10079b63          	bnez	a5,ffffffffc0202542 <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc0202430:	00099797          	auipc	a5,0x99
ffffffffc0202434:	2187b783          	ld	a5,536(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0202438:	4585                	li	a1,1
ffffffffc020243a:	e432                	sd	a2,8(sp)
ffffffffc020243c:	739c                	ld	a5,32(a5)
ffffffffc020243e:	9782                	jalr	a5
ffffffffc0202440:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202442:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc0202446:	013487b3          	add	a5,s1,s3
ffffffffc020244a:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc020244e:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc0202450:	f3a1                	bnez	a5,ffffffffc0202390 <exit_range+0x68>
}
ffffffffc0202452:	60ea                	ld	ra,152(sp)
ffffffffc0202454:	644a                	ld	s0,144(sp)
ffffffffc0202456:	64aa                	ld	s1,136(sp)
ffffffffc0202458:	690a                	ld	s2,128(sp)
ffffffffc020245a:	79e6                	ld	s3,120(sp)
ffffffffc020245c:	7a46                	ld	s4,112(sp)
ffffffffc020245e:	7aa6                	ld	s5,104(sp)
ffffffffc0202460:	7b06                	ld	s6,96(sp)
ffffffffc0202462:	6be6                	ld	s7,88(sp)
ffffffffc0202464:	610d                	addi	sp,sp,160
ffffffffc0202466:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202468:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020246c:	078a                	slli	a5,a5,0x2
ffffffffc020246e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202470:	14a7f463          	bgeu	a5,a0,ffffffffc02025b8 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202474:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc0202476:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc020247a:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020247e:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc0202482:	10abf263          	bgeu	s7,a0,ffffffffc0202586 <exit_range+0x25e>
ffffffffc0202486:	000fb783          	ld	a5,0(t6)
ffffffffc020248a:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020248c:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc0202490:	629c                	ld	a5,0(a3)
ffffffffc0202492:	8b85                	andi	a5,a5,1
ffffffffc0202494:	f7ad                	bnez	a5,ffffffffc02023fe <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202496:	06a1                	addi	a3,a3,8
ffffffffc0202498:	fea69ce3          	bne	a3,a0,ffffffffc0202490 <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc020249c:	00099517          	auipc	a0,0x99
ffffffffc02024a0:	1d453503          	ld	a0,468(a0) # ffffffffc029b670 <pages>
ffffffffc02024a4:	952e                	add	a0,a0,a1
ffffffffc02024a6:	100027f3          	csrr	a5,sstatus
ffffffffc02024aa:	8b89                	andi	a5,a5,2
ffffffffc02024ac:	e3b9                	bnez	a5,ffffffffc02024f2 <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc02024ae:	00099797          	auipc	a5,0x99
ffffffffc02024b2:	19a7b783          	ld	a5,410(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc02024b6:	4585                	li	a1,1
ffffffffc02024b8:	e0b2                	sd	a2,64(sp)
ffffffffc02024ba:	739c                	ld	a5,32(a5)
ffffffffc02024bc:	fc1a                	sd	t1,56(sp)
ffffffffc02024be:	f846                	sd	a7,48(sp)
ffffffffc02024c0:	f47a                	sd	t5,40(sp)
ffffffffc02024c2:	f072                	sd	t3,32(sp)
ffffffffc02024c4:	ec76                	sd	t4,24(sp)
ffffffffc02024c6:	e842                	sd	a6,16(sp)
ffffffffc02024c8:	e43a                	sd	a4,8(sp)
ffffffffc02024ca:	9782                	jalr	a5
    if (flag)
ffffffffc02024cc:	6722                	ld	a4,8(sp)
ffffffffc02024ce:	6842                	ld	a6,16(sp)
ffffffffc02024d0:	6ee2                	ld	t4,24(sp)
ffffffffc02024d2:	7e02                	ld	t3,32(sp)
ffffffffc02024d4:	7f22                	ld	t5,40(sp)
ffffffffc02024d6:	78c2                	ld	a7,48(sp)
ffffffffc02024d8:	7362                	ld	t1,56(sp)
ffffffffc02024da:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024dc:	fff802b7          	lui	t0,0xfff80
ffffffffc02024e0:	000803b7          	lui	t2,0x80
ffffffffc02024e4:	00099f97          	auipc	t6,0x99
ffffffffc02024e8:	17cf8f93          	addi	t6,t6,380 # ffffffffc029b660 <va_pa_offset>
ffffffffc02024ec:	00073023          	sd	zero,0(a4)
ffffffffc02024f0:	b739                	j	ffffffffc02023fe <exit_range+0xd6>
        intr_disable();
ffffffffc02024f2:	e4b2                	sd	a2,72(sp)
ffffffffc02024f4:	e09a                	sd	t1,64(sp)
ffffffffc02024f6:	fc46                	sd	a7,56(sp)
ffffffffc02024f8:	f47a                	sd	t5,40(sp)
ffffffffc02024fa:	f072                	sd	t3,32(sp)
ffffffffc02024fc:	ec76                	sd	t4,24(sp)
ffffffffc02024fe:	e842                	sd	a6,16(sp)
ffffffffc0202500:	e43a                	sd	a4,8(sp)
ffffffffc0202502:	f82a                	sd	a0,48(sp)
ffffffffc0202504:	c00fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202508:	00099797          	auipc	a5,0x99
ffffffffc020250c:	1407b783          	ld	a5,320(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0202510:	7542                	ld	a0,48(sp)
ffffffffc0202512:	4585                	li	a1,1
ffffffffc0202514:	739c                	ld	a5,32(a5)
ffffffffc0202516:	9782                	jalr	a5
        intr_enable();
ffffffffc0202518:	be6fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020251c:	6722                	ld	a4,8(sp)
ffffffffc020251e:	6626                	ld	a2,72(sp)
ffffffffc0202520:	6306                	ld	t1,64(sp)
ffffffffc0202522:	78e2                	ld	a7,56(sp)
ffffffffc0202524:	7f22                	ld	t5,40(sp)
ffffffffc0202526:	7e02                	ld	t3,32(sp)
ffffffffc0202528:	6ee2                	ld	t4,24(sp)
ffffffffc020252a:	6842                	ld	a6,16(sp)
ffffffffc020252c:	00099f97          	auipc	t6,0x99
ffffffffc0202530:	134f8f93          	addi	t6,t6,308 # ffffffffc029b660 <va_pa_offset>
ffffffffc0202534:	000803b7          	lui	t2,0x80
ffffffffc0202538:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc020253c:	00073023          	sd	zero,0(a4)
ffffffffc0202540:	bd7d                	j	ffffffffc02023fe <exit_range+0xd6>
        intr_disable();
ffffffffc0202542:	e832                	sd	a2,16(sp)
ffffffffc0202544:	e42a                	sd	a0,8(sp)
ffffffffc0202546:	bbefe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020254a:	00099797          	auipc	a5,0x99
ffffffffc020254e:	0fe7b783          	ld	a5,254(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0202552:	6522                	ld	a0,8(sp)
ffffffffc0202554:	4585                	li	a1,1
ffffffffc0202556:	739c                	ld	a5,32(a5)
ffffffffc0202558:	9782                	jalr	a5
        intr_enable();
ffffffffc020255a:	ba4fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020255e:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202560:	00043023          	sd	zero,0(s0)
ffffffffc0202564:	b5cd                	j	ffffffffc0202446 <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202566:	00004697          	auipc	a3,0x4
ffffffffc020256a:	16268693          	addi	a3,a3,354 # ffffffffc02066c8 <etext+0xe90>
ffffffffc020256e:	00004617          	auipc	a2,0x4
ffffffffc0202572:	caa60613          	addi	a2,a2,-854 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0202576:	13500593          	li	a1,309
ffffffffc020257a:	00004517          	auipc	a0,0x4
ffffffffc020257e:	13e50513          	addi	a0,a0,318 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202582:	ec5fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202586:	00004617          	auipc	a2,0x4
ffffffffc020258a:	04260613          	addi	a2,a2,66 # ffffffffc02065c8 <etext+0xd90>
ffffffffc020258e:	07100593          	li	a1,113
ffffffffc0202592:	00004517          	auipc	a0,0x4
ffffffffc0202596:	05e50513          	addi	a0,a0,94 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc020259a:	eadfd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc020259e:	86f2                	mv	a3,t3
ffffffffc02025a0:	00004617          	auipc	a2,0x4
ffffffffc02025a4:	02860613          	addi	a2,a2,40 # ffffffffc02065c8 <etext+0xd90>
ffffffffc02025a8:	07100593          	li	a1,113
ffffffffc02025ac:	00004517          	auipc	a0,0x4
ffffffffc02025b0:	04450513          	addi	a0,a0,68 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc02025b4:	e93fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc02025b8:	8c7ff0ef          	jal	ffffffffc0201e7e <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc02025bc:	00004697          	auipc	a3,0x4
ffffffffc02025c0:	13c68693          	addi	a3,a3,316 # ffffffffc02066f8 <etext+0xec0>
ffffffffc02025c4:	00004617          	auipc	a2,0x4
ffffffffc02025c8:	c5460613          	addi	a2,a2,-940 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02025cc:	13600593          	li	a1,310
ffffffffc02025d0:	00004517          	auipc	a0,0x4
ffffffffc02025d4:	0e850513          	addi	a0,a0,232 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02025d8:	e6ffd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02025dc <page_remove>:
{
ffffffffc02025dc:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025de:	4601                	li	a2,0
{
ffffffffc02025e0:	e822                	sd	s0,16(sp)
ffffffffc02025e2:	ec06                	sd	ra,24(sp)
ffffffffc02025e4:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025e6:	95dff0ef          	jal	ffffffffc0201f42 <get_pte>
    if (ptep != NULL)
ffffffffc02025ea:	c511                	beqz	a0,ffffffffc02025f6 <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc02025ec:	6118                	ld	a4,0(a0)
ffffffffc02025ee:	87aa                	mv	a5,a0
ffffffffc02025f0:	00177693          	andi	a3,a4,1
ffffffffc02025f4:	e689                	bnez	a3,ffffffffc02025fe <page_remove+0x22>
}
ffffffffc02025f6:	60e2                	ld	ra,24(sp)
ffffffffc02025f8:	6442                	ld	s0,16(sp)
ffffffffc02025fa:	6105                	addi	sp,sp,32
ffffffffc02025fc:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02025fe:	00099697          	auipc	a3,0x99
ffffffffc0202602:	06a6b683          	ld	a3,106(a3) # ffffffffc029b668 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202606:	070a                	slli	a4,a4,0x2
ffffffffc0202608:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc020260a:	06d77563          	bgeu	a4,a3,ffffffffc0202674 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020260e:	00099517          	auipc	a0,0x99
ffffffffc0202612:	06253503          	ld	a0,98(a0) # ffffffffc029b670 <pages>
ffffffffc0202616:	071a                	slli	a4,a4,0x6
ffffffffc0202618:	fe0006b7          	lui	a3,0xfe000
ffffffffc020261c:	9736                	add	a4,a4,a3
ffffffffc020261e:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202620:	4118                	lw	a4,0(a0)
ffffffffc0202622:	377d                	addiw	a4,a4,-1
ffffffffc0202624:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202626:	cb09                	beqz	a4,ffffffffc0202638 <page_remove+0x5c>
        *ptep = 0;
ffffffffc0202628:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020262c:	12040073          	sfence.vma	s0
}
ffffffffc0202630:	60e2                	ld	ra,24(sp)
ffffffffc0202632:	6442                	ld	s0,16(sp)
ffffffffc0202634:	6105                	addi	sp,sp,32
ffffffffc0202636:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202638:	10002773          	csrr	a4,sstatus
ffffffffc020263c:	8b09                	andi	a4,a4,2
ffffffffc020263e:	eb19                	bnez	a4,ffffffffc0202654 <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc0202640:	00099717          	auipc	a4,0x99
ffffffffc0202644:	00873703          	ld	a4,8(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc0202648:	4585                	li	a1,1
ffffffffc020264a:	e03e                	sd	a5,0(sp)
ffffffffc020264c:	7318                	ld	a4,32(a4)
ffffffffc020264e:	9702                	jalr	a4
    if (flag)
ffffffffc0202650:	6782                	ld	a5,0(sp)
ffffffffc0202652:	bfd9                	j	ffffffffc0202628 <page_remove+0x4c>
        intr_disable();
ffffffffc0202654:	e43e                	sd	a5,8(sp)
ffffffffc0202656:	e02a                	sd	a0,0(sp)
ffffffffc0202658:	aacfe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020265c:	00099717          	auipc	a4,0x99
ffffffffc0202660:	fec73703          	ld	a4,-20(a4) # ffffffffc029b648 <pmm_manager>
ffffffffc0202664:	6502                	ld	a0,0(sp)
ffffffffc0202666:	4585                	li	a1,1
ffffffffc0202668:	7318                	ld	a4,32(a4)
ffffffffc020266a:	9702                	jalr	a4
        intr_enable();
ffffffffc020266c:	a92fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202670:	67a2                	ld	a5,8(sp)
ffffffffc0202672:	bf5d                	j	ffffffffc0202628 <page_remove+0x4c>
ffffffffc0202674:	80bff0ef          	jal	ffffffffc0201e7e <pa2page.part.0>

ffffffffc0202678 <page_insert>:
{
ffffffffc0202678:	7139                	addi	sp,sp,-64
ffffffffc020267a:	f426                	sd	s1,40(sp)
ffffffffc020267c:	84b2                	mv	s1,a2
ffffffffc020267e:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202680:	4605                	li	a2,1
{
ffffffffc0202682:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202684:	85a6                	mv	a1,s1
{
ffffffffc0202686:	fc06                	sd	ra,56(sp)
ffffffffc0202688:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020268a:	8b9ff0ef          	jal	ffffffffc0201f42 <get_pte>
    if (ptep == NULL)
ffffffffc020268e:	cd61                	beqz	a0,ffffffffc0202766 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202690:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202692:	611c                	ld	a5,0(a0)
ffffffffc0202694:	66a2                	ld	a3,8(sp)
ffffffffc0202696:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7baf>
ffffffffc020269a:	c010                	sw	a2,0(s0)
ffffffffc020269c:	0017f613          	andi	a2,a5,1
ffffffffc02026a0:	872a                	mv	a4,a0
ffffffffc02026a2:	e61d                	bnez	a2,ffffffffc02026d0 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc02026a4:	00099617          	auipc	a2,0x99
ffffffffc02026a8:	fcc63603          	ld	a2,-52(a2) # ffffffffc029b670 <pages>
    return page - pages + nbase;
ffffffffc02026ac:	8c11                	sub	s0,s0,a2
ffffffffc02026ae:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02026b0:	200007b7          	lui	a5,0x20000
ffffffffc02026b4:	042a                	slli	s0,s0,0xa
ffffffffc02026b6:	943e                	add	s0,s0,a5
ffffffffc02026b8:	8ec1                	or	a3,a3,s0
ffffffffc02026ba:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02026be:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026c0:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02026c4:	4501                	li	a0,0
}
ffffffffc02026c6:	70e2                	ld	ra,56(sp)
ffffffffc02026c8:	7442                	ld	s0,48(sp)
ffffffffc02026ca:	74a2                	ld	s1,40(sp)
ffffffffc02026cc:	6121                	addi	sp,sp,64
ffffffffc02026ce:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02026d0:	00099617          	auipc	a2,0x99
ffffffffc02026d4:	f9863603          	ld	a2,-104(a2) # ffffffffc029b668 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02026d8:	078a                	slli	a5,a5,0x2
ffffffffc02026da:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026dc:	08c7f763          	bgeu	a5,a2,ffffffffc020276a <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02026e0:	00099617          	auipc	a2,0x99
ffffffffc02026e4:	f9063603          	ld	a2,-112(a2) # ffffffffc029b670 <pages>
ffffffffc02026e8:	fe000537          	lui	a0,0xfe000
ffffffffc02026ec:	079a                	slli	a5,a5,0x6
ffffffffc02026ee:	97aa                	add	a5,a5,a0
ffffffffc02026f0:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc02026f4:	00a40963          	beq	s0,a0,ffffffffc0202706 <page_insert+0x8e>
    page->ref -= 1;
ffffffffc02026f8:	411c                	lw	a5,0(a0)
ffffffffc02026fa:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_exit_out_size+0x1fff5e47>
ffffffffc02026fc:	c11c                	sw	a5,0(a0)
        if (page_ref(page) == 0)
ffffffffc02026fe:	c791                	beqz	a5,ffffffffc020270a <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202700:	12048073          	sfence.vma	s1
}
ffffffffc0202704:	b765                	j	ffffffffc02026ac <page_insert+0x34>
ffffffffc0202706:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc0202708:	b755                	j	ffffffffc02026ac <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020270a:	100027f3          	csrr	a5,sstatus
ffffffffc020270e:	8b89                	andi	a5,a5,2
ffffffffc0202710:	e39d                	bnez	a5,ffffffffc0202736 <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc0202712:	00099797          	auipc	a5,0x99
ffffffffc0202716:	f367b783          	ld	a5,-202(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc020271a:	4585                	li	a1,1
ffffffffc020271c:	e83a                	sd	a4,16(sp)
ffffffffc020271e:	739c                	ld	a5,32(a5)
ffffffffc0202720:	e436                	sd	a3,8(sp)
ffffffffc0202722:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202724:	00099617          	auipc	a2,0x99
ffffffffc0202728:	f4c63603          	ld	a2,-180(a2) # ffffffffc029b670 <pages>
ffffffffc020272c:	66a2                	ld	a3,8(sp)
ffffffffc020272e:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202730:	12048073          	sfence.vma	s1
ffffffffc0202734:	bfa5                	j	ffffffffc02026ac <page_insert+0x34>
        intr_disable();
ffffffffc0202736:	ec3a                	sd	a4,24(sp)
ffffffffc0202738:	e836                	sd	a3,16(sp)
ffffffffc020273a:	e42a                	sd	a0,8(sp)
ffffffffc020273c:	9c8fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202740:	00099797          	auipc	a5,0x99
ffffffffc0202744:	f087b783          	ld	a5,-248(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc0202748:	6522                	ld	a0,8(sp)
ffffffffc020274a:	4585                	li	a1,1
ffffffffc020274c:	739c                	ld	a5,32(a5)
ffffffffc020274e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202750:	9aefe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202754:	00099617          	auipc	a2,0x99
ffffffffc0202758:	f1c63603          	ld	a2,-228(a2) # ffffffffc029b670 <pages>
ffffffffc020275c:	6762                	ld	a4,24(sp)
ffffffffc020275e:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202760:	12048073          	sfence.vma	s1
ffffffffc0202764:	b7a1                	j	ffffffffc02026ac <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc0202766:	5571                	li	a0,-4
ffffffffc0202768:	bfb9                	j	ffffffffc02026c6 <page_insert+0x4e>
ffffffffc020276a:	f14ff0ef          	jal	ffffffffc0201e7e <pa2page.part.0>

ffffffffc020276e <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020276e:	00005797          	auipc	a5,0x5
ffffffffc0202772:	ee278793          	addi	a5,a5,-286 # ffffffffc0207650 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202776:	638c                	ld	a1,0(a5)
{
ffffffffc0202778:	7159                	addi	sp,sp,-112
ffffffffc020277a:	f486                	sd	ra,104(sp)
ffffffffc020277c:	e8ca                	sd	s2,80(sp)
ffffffffc020277e:	e4ce                	sd	s3,72(sp)
ffffffffc0202780:	f85a                	sd	s6,48(sp)
ffffffffc0202782:	f0a2                	sd	s0,96(sp)
ffffffffc0202784:	eca6                	sd	s1,88(sp)
ffffffffc0202786:	e0d2                	sd	s4,64(sp)
ffffffffc0202788:	fc56                	sd	s5,56(sp)
ffffffffc020278a:	f45e                	sd	s7,40(sp)
ffffffffc020278c:	f062                	sd	s8,32(sp)
ffffffffc020278e:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202790:	00099b17          	auipc	s6,0x99
ffffffffc0202794:	eb8b0b13          	addi	s6,s6,-328 # ffffffffc029b648 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202798:	00004517          	auipc	a0,0x4
ffffffffc020279c:	f7850513          	addi	a0,a0,-136 # ffffffffc0206710 <etext+0xed8>
    pmm_manager = &default_pmm_manager;
ffffffffc02027a0:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027a4:	9f1fd0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc02027a8:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027ac:	00099997          	auipc	s3,0x99
ffffffffc02027b0:	eb498993          	addi	s3,s3,-332 # ffffffffc029b660 <va_pa_offset>
    pmm_manager->init();
ffffffffc02027b4:	679c                	ld	a5,8(a5)
ffffffffc02027b6:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02027b8:	57f5                	li	a5,-3
ffffffffc02027ba:	07fa                	slli	a5,a5,0x1e
ffffffffc02027bc:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02027c0:	92afe0ef          	jal	ffffffffc02008ea <get_memory_base>
ffffffffc02027c4:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02027c6:	92efe0ef          	jal	ffffffffc02008f4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02027ca:	70050e63          	beqz	a0,ffffffffc0202ee6 <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027ce:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02027d0:	00004517          	auipc	a0,0x4
ffffffffc02027d4:	f7850513          	addi	a0,a0,-136 # ffffffffc0206748 <etext+0xf10>
ffffffffc02027d8:	9bdfd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027dc:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02027e0:	864a                	mv	a2,s2
ffffffffc02027e2:	85a6                	mv	a1,s1
ffffffffc02027e4:	fff40693          	addi	a3,s0,-1
ffffffffc02027e8:	00004517          	auipc	a0,0x4
ffffffffc02027ec:	f7850513          	addi	a0,a0,-136 # ffffffffc0206760 <etext+0xf28>
ffffffffc02027f0:	9a5fd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc02027f4:	c80007b7          	lui	a5,0xc8000
ffffffffc02027f8:	8522                	mv	a0,s0
ffffffffc02027fa:	5287ed63          	bltu	a5,s0,ffffffffc0202d34 <pmm_init+0x5c6>
ffffffffc02027fe:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202800:	0009a617          	auipc	a2,0x9a
ffffffffc0202804:	e9760613          	addi	a2,a2,-361 # ffffffffc029c697 <end+0xfff>
ffffffffc0202808:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc020280a:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020280c:	00099b97          	auipc	s7,0x99
ffffffffc0202810:	e64b8b93          	addi	s7,s7,-412 # ffffffffc029b670 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202814:	00099497          	auipc	s1,0x99
ffffffffc0202818:	e5448493          	addi	s1,s1,-428 # ffffffffc029b668 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020281c:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202820:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202822:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202826:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202828:	02f50763          	beq	a0,a5,ffffffffc0202856 <pmm_init+0xe8>
ffffffffc020282c:	4701                	li	a4,0
ffffffffc020282e:	4585                	li	a1,1
ffffffffc0202830:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202834:	00671793          	slli	a5,a4,0x6
ffffffffc0202838:	97b2                	add	a5,a5,a2
ffffffffc020283a:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_exit_out_size+0x75e50>
ffffffffc020283c:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202840:	6088                	ld	a0,0(s1)
ffffffffc0202842:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202844:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202848:	00d507b3          	add	a5,a0,a3
ffffffffc020284c:	fef764e3          	bltu	a4,a5,ffffffffc0202834 <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202850:	079a                	slli	a5,a5,0x6
ffffffffc0202852:	00f606b3          	add	a3,a2,a5
ffffffffc0202856:	c02007b7          	lui	a5,0xc0200
ffffffffc020285a:	16f6eee3          	bltu	a3,a5,ffffffffc02031d6 <pmm_init+0xa68>
ffffffffc020285e:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202862:	77fd                	lui	a5,0xfffff
ffffffffc0202864:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202866:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202868:	4e86ed63          	bltu	a3,s0,ffffffffc0202d62 <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020286c:	00004517          	auipc	a0,0x4
ffffffffc0202870:	f1c50513          	addi	a0,a0,-228 # ffffffffc0206788 <etext+0xf50>
ffffffffc0202874:	921fd0ef          	jal	ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202878:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020287c:	00099917          	auipc	s2,0x99
ffffffffc0202880:	ddc90913          	addi	s2,s2,-548 # ffffffffc029b658 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202884:	7b9c                	ld	a5,48(a5)
ffffffffc0202886:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202888:	00004517          	auipc	a0,0x4
ffffffffc020288c:	f1850513          	addi	a0,a0,-232 # ffffffffc02067a0 <etext+0xf68>
ffffffffc0202890:	905fd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202894:	00007697          	auipc	a3,0x7
ffffffffc0202898:	76c68693          	addi	a3,a3,1900 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc020289c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc02028a0:	c02007b7          	lui	a5,0xc0200
ffffffffc02028a4:	2af6eee3          	bltu	a3,a5,ffffffffc0203360 <pmm_init+0xbf2>
ffffffffc02028a8:	0009b783          	ld	a5,0(s3)
ffffffffc02028ac:	8e9d                	sub	a3,a3,a5
ffffffffc02028ae:	00099797          	auipc	a5,0x99
ffffffffc02028b2:	dad7b123          	sd	a3,-606(a5) # ffffffffc029b650 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02028b6:	100027f3          	csrr	a5,sstatus
ffffffffc02028ba:	8b89                	andi	a5,a5,2
ffffffffc02028bc:	48079963          	bnez	a5,ffffffffc0202d4e <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028c0:	000b3783          	ld	a5,0(s6)
ffffffffc02028c4:	779c                	ld	a5,40(a5)
ffffffffc02028c6:	9782                	jalr	a5
ffffffffc02028c8:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028ca:	6098                	ld	a4,0(s1)
ffffffffc02028cc:	c80007b7          	lui	a5,0xc8000
ffffffffc02028d0:	83b1                	srli	a5,a5,0xc
ffffffffc02028d2:	66e7e663          	bltu	a5,a4,ffffffffc0202f3e <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028d6:	00093503          	ld	a0,0(s2)
ffffffffc02028da:	64050263          	beqz	a0,ffffffffc0202f1e <pmm_init+0x7b0>
ffffffffc02028de:	03451793          	slli	a5,a0,0x34
ffffffffc02028e2:	62079e63          	bnez	a5,ffffffffc0202f1e <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028e6:	4601                	li	a2,0
ffffffffc02028e8:	4581                	li	a1,0
ffffffffc02028ea:	8b7ff0ef          	jal	ffffffffc02021a0 <get_page>
ffffffffc02028ee:	240519e3          	bnez	a0,ffffffffc0203340 <pmm_init+0xbd2>
ffffffffc02028f2:	100027f3          	csrr	a5,sstatus
ffffffffc02028f6:	8b89                	andi	a5,a5,2
ffffffffc02028f8:	44079063          	bnez	a5,ffffffffc0202d38 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028fc:	000b3783          	ld	a5,0(s6)
ffffffffc0202900:	4505                	li	a0,1
ffffffffc0202902:	6f9c                	ld	a5,24(a5)
ffffffffc0202904:	9782                	jalr	a5
ffffffffc0202906:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202908:	00093503          	ld	a0,0(s2)
ffffffffc020290c:	4681                	li	a3,0
ffffffffc020290e:	4601                	li	a2,0
ffffffffc0202910:	85d2                	mv	a1,s4
ffffffffc0202912:	d67ff0ef          	jal	ffffffffc0202678 <page_insert>
ffffffffc0202916:	280511e3          	bnez	a0,ffffffffc0203398 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020291a:	00093503          	ld	a0,0(s2)
ffffffffc020291e:	4601                	li	a2,0
ffffffffc0202920:	4581                	li	a1,0
ffffffffc0202922:	e20ff0ef          	jal	ffffffffc0201f42 <get_pte>
ffffffffc0202926:	240509e3          	beqz	a0,ffffffffc0203378 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc020292a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc020292c:	0017f713          	andi	a4,a5,1
ffffffffc0202930:	58070f63          	beqz	a4,ffffffffc0202ece <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202934:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202936:	078a                	slli	a5,a5,0x2
ffffffffc0202938:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020293a:	58e7f863          	bgeu	a5,a4,ffffffffc0202eca <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020293e:	000bb683          	ld	a3,0(s7)
ffffffffc0202942:	079a                	slli	a5,a5,0x6
ffffffffc0202944:	fe000637          	lui	a2,0xfe000
ffffffffc0202948:	97b2                	add	a5,a5,a2
ffffffffc020294a:	97b6                	add	a5,a5,a3
ffffffffc020294c:	14fa1ae3          	bne	s4,a5,ffffffffc02032a0 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc0202950:	000a2683          	lw	a3,0(s4) # 200000 <_binary_obj___user_exit_out_size+0x1f5e48>
ffffffffc0202954:	4785                	li	a5,1
ffffffffc0202956:	12f695e3          	bne	a3,a5,ffffffffc0203280 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020295a:	00093503          	ld	a0,0(s2)
ffffffffc020295e:	77fd                	lui	a5,0xfffff
ffffffffc0202960:	6114                	ld	a3,0(a0)
ffffffffc0202962:	068a                	slli	a3,a3,0x2
ffffffffc0202964:	8efd                	and	a3,a3,a5
ffffffffc0202966:	00c6d613          	srli	a2,a3,0xc
ffffffffc020296a:	0ee67fe3          	bgeu	a2,a4,ffffffffc0203268 <pmm_init+0xafa>
ffffffffc020296e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202972:	96e2                	add	a3,a3,s8
ffffffffc0202974:	0006ba83          	ld	s5,0(a3)
ffffffffc0202978:	0a8a                	slli	s5,s5,0x2
ffffffffc020297a:	00fafab3          	and	s5,s5,a5
ffffffffc020297e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202982:	0ce7f6e3          	bgeu	a5,a4,ffffffffc020324e <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202986:	4601                	li	a2,0
ffffffffc0202988:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020298a:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020298c:	db6ff0ef          	jal	ffffffffc0201f42 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202990:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202992:	05851ee3          	bne	a0,s8,ffffffffc02031ee <pmm_init+0xa80>
ffffffffc0202996:	100027f3          	csrr	a5,sstatus
ffffffffc020299a:	8b89                	andi	a5,a5,2
ffffffffc020299c:	3e079b63          	bnez	a5,ffffffffc0202d92 <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029a0:	000b3783          	ld	a5,0(s6)
ffffffffc02029a4:	4505                	li	a0,1
ffffffffc02029a6:	6f9c                	ld	a5,24(a5)
ffffffffc02029a8:	9782                	jalr	a5
ffffffffc02029aa:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02029ac:	00093503          	ld	a0,0(s2)
ffffffffc02029b0:	46d1                	li	a3,20
ffffffffc02029b2:	6605                	lui	a2,0x1
ffffffffc02029b4:	85e2                	mv	a1,s8
ffffffffc02029b6:	cc3ff0ef          	jal	ffffffffc0202678 <page_insert>
ffffffffc02029ba:	06051ae3          	bnez	a0,ffffffffc020322e <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029be:	00093503          	ld	a0,0(s2)
ffffffffc02029c2:	4601                	li	a2,0
ffffffffc02029c4:	6585                	lui	a1,0x1
ffffffffc02029c6:	d7cff0ef          	jal	ffffffffc0201f42 <get_pte>
ffffffffc02029ca:	040502e3          	beqz	a0,ffffffffc020320e <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc02029ce:	611c                	ld	a5,0(a0)
ffffffffc02029d0:	0107f713          	andi	a4,a5,16
ffffffffc02029d4:	7e070163          	beqz	a4,ffffffffc02031b6 <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc02029d8:	8b91                	andi	a5,a5,4
ffffffffc02029da:	7a078e63          	beqz	a5,ffffffffc0203196 <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02029de:	00093503          	ld	a0,0(s2)
ffffffffc02029e2:	611c                	ld	a5,0(a0)
ffffffffc02029e4:	8bc1                	andi	a5,a5,16
ffffffffc02029e6:	78078863          	beqz	a5,ffffffffc0203176 <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc02029ea:	000c2703          	lw	a4,0(s8)
ffffffffc02029ee:	4785                	li	a5,1
ffffffffc02029f0:	76f71363          	bne	a4,a5,ffffffffc0203156 <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02029f4:	4681                	li	a3,0
ffffffffc02029f6:	6605                	lui	a2,0x1
ffffffffc02029f8:	85d2                	mv	a1,s4
ffffffffc02029fa:	c7fff0ef          	jal	ffffffffc0202678 <page_insert>
ffffffffc02029fe:	72051c63          	bnez	a0,ffffffffc0203136 <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc0202a02:	000a2703          	lw	a4,0(s4)
ffffffffc0202a06:	4789                	li	a5,2
ffffffffc0202a08:	70f71763          	bne	a4,a5,ffffffffc0203116 <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202a0c:	000c2783          	lw	a5,0(s8)
ffffffffc0202a10:	6e079363          	bnez	a5,ffffffffc02030f6 <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a14:	00093503          	ld	a0,0(s2)
ffffffffc0202a18:	4601                	li	a2,0
ffffffffc0202a1a:	6585                	lui	a1,0x1
ffffffffc0202a1c:	d26ff0ef          	jal	ffffffffc0201f42 <get_pte>
ffffffffc0202a20:	6a050b63          	beqz	a0,ffffffffc02030d6 <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a24:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a26:	00177793          	andi	a5,a4,1
ffffffffc0202a2a:	4a078263          	beqz	a5,ffffffffc0202ece <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202a2e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a30:	00271793          	slli	a5,a4,0x2
ffffffffc0202a34:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a36:	48d7fa63          	bgeu	a5,a3,ffffffffc0202eca <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a3a:	000bb683          	ld	a3,0(s7)
ffffffffc0202a3e:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a42:	97d6                	add	a5,a5,s5
ffffffffc0202a44:	079a                	slli	a5,a5,0x6
ffffffffc0202a46:	97b6                	add	a5,a5,a3
ffffffffc0202a48:	66fa1763          	bne	s4,a5,ffffffffc02030b6 <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a4c:	8b41                	andi	a4,a4,16
ffffffffc0202a4e:	64071463          	bnez	a4,ffffffffc0203096 <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a52:	00093503          	ld	a0,0(s2)
ffffffffc0202a56:	4581                	li	a1,0
ffffffffc0202a58:	b85ff0ef          	jal	ffffffffc02025dc <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a5c:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a60:	4785                	li	a5,1
ffffffffc0202a62:	60fc9a63          	bne	s9,a5,ffffffffc0203076 <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202a66:	000c2783          	lw	a5,0(s8)
ffffffffc0202a6a:	5e079663          	bnez	a5,ffffffffc0203056 <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a6e:	00093503          	ld	a0,0(s2)
ffffffffc0202a72:	6585                	lui	a1,0x1
ffffffffc0202a74:	b69ff0ef          	jal	ffffffffc02025dc <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a78:	000a2783          	lw	a5,0(s4)
ffffffffc0202a7c:	52079d63          	bnez	a5,ffffffffc0202fb6 <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202a80:	000c2783          	lw	a5,0(s8)
ffffffffc0202a84:	50079963          	bnez	a5,ffffffffc0202f96 <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a88:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a8c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a8e:	000a3783          	ld	a5,0(s4)
ffffffffc0202a92:	078a                	slli	a5,a5,0x2
ffffffffc0202a94:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a96:	42e7fa63          	bgeu	a5,a4,ffffffffc0202eca <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a9a:	000bb503          	ld	a0,0(s7)
ffffffffc0202a9e:	97d6                	add	a5,a5,s5
ffffffffc0202aa0:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202aa2:	00f506b3          	add	a3,a0,a5
ffffffffc0202aa6:	4294                	lw	a3,0(a3)
ffffffffc0202aa8:	4d969763          	bne	a3,s9,ffffffffc0202f76 <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202aac:	8799                	srai	a5,a5,0x6
ffffffffc0202aae:	00080637          	lui	a2,0x80
ffffffffc0202ab2:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ab4:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202ab8:	4ae7f363          	bgeu	a5,a4,ffffffffc0202f5e <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202abc:	0009b783          	ld	a5,0(s3)
ffffffffc0202ac0:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ac2:	639c                	ld	a5,0(a5)
ffffffffc0202ac4:	078a                	slli	a5,a5,0x2
ffffffffc0202ac6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ac8:	40e7f163          	bgeu	a5,a4,ffffffffc0202eca <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202acc:	8f91                	sub	a5,a5,a2
ffffffffc0202ace:	079a                	slli	a5,a5,0x6
ffffffffc0202ad0:	953e                	add	a0,a0,a5
ffffffffc0202ad2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ad6:	8b89                	andi	a5,a5,2
ffffffffc0202ad8:	30079863          	bnez	a5,ffffffffc0202de8 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202adc:	000b3783          	ld	a5,0(s6)
ffffffffc0202ae0:	4585                	li	a1,1
ffffffffc0202ae2:	739c                	ld	a5,32(a5)
ffffffffc0202ae4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ae6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202aea:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aec:	078a                	slli	a5,a5,0x2
ffffffffc0202aee:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202af0:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202eca <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202af4:	000bb503          	ld	a0,0(s7)
ffffffffc0202af8:	fe000737          	lui	a4,0xfe000
ffffffffc0202afc:	079a                	slli	a5,a5,0x6
ffffffffc0202afe:	97ba                	add	a5,a5,a4
ffffffffc0202b00:	953e                	add	a0,a0,a5
ffffffffc0202b02:	100027f3          	csrr	a5,sstatus
ffffffffc0202b06:	8b89                	andi	a5,a5,2
ffffffffc0202b08:	2c079463          	bnez	a5,ffffffffc0202dd0 <pmm_init+0x662>
ffffffffc0202b0c:	000b3783          	ld	a5,0(s6)
ffffffffc0202b10:	4585                	li	a1,1
ffffffffc0202b12:	739c                	ld	a5,32(a5)
ffffffffc0202b14:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b16:	00093783          	ld	a5,0(s2)
ffffffffc0202b1a:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd63968>
    asm volatile("sfence.vma");
ffffffffc0202b1e:	12000073          	sfence.vma
ffffffffc0202b22:	100027f3          	csrr	a5,sstatus
ffffffffc0202b26:	8b89                	andi	a5,a5,2
ffffffffc0202b28:	28079a63          	bnez	a5,ffffffffc0202dbc <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b2c:	000b3783          	ld	a5,0(s6)
ffffffffc0202b30:	779c                	ld	a5,40(a5)
ffffffffc0202b32:	9782                	jalr	a5
ffffffffc0202b34:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b36:	4d441063          	bne	s0,s4,ffffffffc0202ff6 <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b3a:	00004517          	auipc	a0,0x4
ffffffffc0202b3e:	fb650513          	addi	a0,a0,-74 # ffffffffc0206af0 <etext+0x12b8>
ffffffffc0202b42:	e52fd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0202b46:	100027f3          	csrr	a5,sstatus
ffffffffc0202b4a:	8b89                	andi	a5,a5,2
ffffffffc0202b4c:	24079e63          	bnez	a5,ffffffffc0202da8 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b50:	000b3783          	ld	a5,0(s6)
ffffffffc0202b54:	779c                	ld	a5,40(a5)
ffffffffc0202b56:	9782                	jalr	a5
ffffffffc0202b58:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b5a:	609c                	ld	a5,0(s1)
ffffffffc0202b5c:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b60:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b62:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b66:	6a85                	lui	s5,0x1
ffffffffc0202b68:	02e47c63          	bgeu	s0,a4,ffffffffc0202ba0 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b6c:	00c45713          	srli	a4,s0,0xc
ffffffffc0202b70:	30f77063          	bgeu	a4,a5,ffffffffc0202e70 <pmm_init+0x702>
ffffffffc0202b74:	0009b583          	ld	a1,0(s3)
ffffffffc0202b78:	00093503          	ld	a0,0(s2)
ffffffffc0202b7c:	4601                	li	a2,0
ffffffffc0202b7e:	95a2                	add	a1,a1,s0
ffffffffc0202b80:	bc2ff0ef          	jal	ffffffffc0201f42 <get_pte>
ffffffffc0202b84:	32050363          	beqz	a0,ffffffffc0202eaa <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b88:	611c                	ld	a5,0(a0)
ffffffffc0202b8a:	078a                	slli	a5,a5,0x2
ffffffffc0202b8c:	0147f7b3          	and	a5,a5,s4
ffffffffc0202b90:	2e879d63          	bne	a5,s0,ffffffffc0202e8a <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b94:	609c                	ld	a5,0(s1)
ffffffffc0202b96:	9456                	add	s0,s0,s5
ffffffffc0202b98:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b9c:	fce468e3          	bltu	s0,a4,ffffffffc0202b6c <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202ba0:	00093783          	ld	a5,0(s2)
ffffffffc0202ba4:	639c                	ld	a5,0(a5)
ffffffffc0202ba6:	42079863          	bnez	a5,ffffffffc0202fd6 <pmm_init+0x868>
ffffffffc0202baa:	100027f3          	csrr	a5,sstatus
ffffffffc0202bae:	8b89                	andi	a5,a5,2
ffffffffc0202bb0:	24079863          	bnez	a5,ffffffffc0202e00 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202bb4:	000b3783          	ld	a5,0(s6)
ffffffffc0202bb8:	4505                	li	a0,1
ffffffffc0202bba:	6f9c                	ld	a5,24(a5)
ffffffffc0202bbc:	9782                	jalr	a5
ffffffffc0202bbe:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202bc0:	00093503          	ld	a0,0(s2)
ffffffffc0202bc4:	4699                	li	a3,6
ffffffffc0202bc6:	10000613          	li	a2,256
ffffffffc0202bca:	85a2                	mv	a1,s0
ffffffffc0202bcc:	aadff0ef          	jal	ffffffffc0202678 <page_insert>
ffffffffc0202bd0:	46051363          	bnez	a0,ffffffffc0203036 <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202bd4:	4018                	lw	a4,0(s0)
ffffffffc0202bd6:	4785                	li	a5,1
ffffffffc0202bd8:	42f71f63          	bne	a4,a5,ffffffffc0203016 <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202bdc:	00093503          	ld	a0,0(s2)
ffffffffc0202be0:	6605                	lui	a2,0x1
ffffffffc0202be2:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7ab0>
ffffffffc0202be6:	4699                	li	a3,6
ffffffffc0202be8:	85a2                	mv	a1,s0
ffffffffc0202bea:	a8fff0ef          	jal	ffffffffc0202678 <page_insert>
ffffffffc0202bee:	72051963          	bnez	a0,ffffffffc0203320 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202bf2:	4018                	lw	a4,0(s0)
ffffffffc0202bf4:	4789                	li	a5,2
ffffffffc0202bf6:	70f71563          	bne	a4,a5,ffffffffc0203300 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202bfa:	00004597          	auipc	a1,0x4
ffffffffc0202bfe:	03e58593          	addi	a1,a1,62 # ffffffffc0206c38 <etext+0x1400>
ffffffffc0202c02:	10000513          	li	a0,256
ffffffffc0202c06:	389020ef          	jal	ffffffffc020578e <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c0a:	6585                	lui	a1,0x1
ffffffffc0202c0c:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7ab0>
ffffffffc0202c10:	10000513          	li	a0,256
ffffffffc0202c14:	38d020ef          	jal	ffffffffc02057a0 <strcmp>
ffffffffc0202c18:	6c051463          	bnez	a0,ffffffffc02032e0 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202c1c:	000bb683          	ld	a3,0(s7)
ffffffffc0202c20:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202c24:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202c26:	40d406b3          	sub	a3,s0,a3
ffffffffc0202c2a:	8699                	srai	a3,a3,0x6
ffffffffc0202c2c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202c2e:	00c69793          	slli	a5,a3,0xc
ffffffffc0202c32:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c34:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c36:	32e7f463          	bgeu	a5,a4,ffffffffc0202f5e <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c3a:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c3e:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c42:	97b6                	add	a5,a5,a3
ffffffffc0202c44:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_exit_out_size+0x75f48>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c48:	313020ef          	jal	ffffffffc020575a <strlen>
ffffffffc0202c4c:	66051a63          	bnez	a0,ffffffffc02032c0 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c50:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c54:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c56:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd63968>
ffffffffc0202c5a:	078a                	slli	a5,a5,0x2
ffffffffc0202c5c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c5e:	26e7f663          	bgeu	a5,a4,ffffffffc0202eca <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c62:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202c66:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202f5e <pmm_init+0x7f0>
ffffffffc0202c6a:	0009b783          	ld	a5,0(s3)
ffffffffc0202c6e:	00f689b3          	add	s3,a3,a5
ffffffffc0202c72:	100027f3          	csrr	a5,sstatus
ffffffffc0202c76:	8b89                	andi	a5,a5,2
ffffffffc0202c78:	1e079163          	bnez	a5,ffffffffc0202e5a <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202c7c:	000b3783          	ld	a5,0(s6)
ffffffffc0202c80:	8522                	mv	a0,s0
ffffffffc0202c82:	4585                	li	a1,1
ffffffffc0202c84:	739c                	ld	a5,32(a5)
ffffffffc0202c86:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c88:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202c8c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c8e:	078a                	slli	a5,a5,0x2
ffffffffc0202c90:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c92:	22e7fc63          	bgeu	a5,a4,ffffffffc0202eca <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c96:	000bb503          	ld	a0,0(s7)
ffffffffc0202c9a:	fe000737          	lui	a4,0xfe000
ffffffffc0202c9e:	079a                	slli	a5,a5,0x6
ffffffffc0202ca0:	97ba                	add	a5,a5,a4
ffffffffc0202ca2:	953e                	add	a0,a0,a5
ffffffffc0202ca4:	100027f3          	csrr	a5,sstatus
ffffffffc0202ca8:	8b89                	andi	a5,a5,2
ffffffffc0202caa:	18079c63          	bnez	a5,ffffffffc0202e42 <pmm_init+0x6d4>
ffffffffc0202cae:	000b3783          	ld	a5,0(s6)
ffffffffc0202cb2:	4585                	li	a1,1
ffffffffc0202cb4:	739c                	ld	a5,32(a5)
ffffffffc0202cb6:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cb8:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202cbc:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cbe:	078a                	slli	a5,a5,0x2
ffffffffc0202cc0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cc2:	20e7f463          	bgeu	a5,a4,ffffffffc0202eca <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cc6:	000bb503          	ld	a0,0(s7)
ffffffffc0202cca:	fe000737          	lui	a4,0xfe000
ffffffffc0202cce:	079a                	slli	a5,a5,0x6
ffffffffc0202cd0:	97ba                	add	a5,a5,a4
ffffffffc0202cd2:	953e                	add	a0,a0,a5
ffffffffc0202cd4:	100027f3          	csrr	a5,sstatus
ffffffffc0202cd8:	8b89                	andi	a5,a5,2
ffffffffc0202cda:	14079863          	bnez	a5,ffffffffc0202e2a <pmm_init+0x6bc>
ffffffffc0202cde:	000b3783          	ld	a5,0(s6)
ffffffffc0202ce2:	4585                	li	a1,1
ffffffffc0202ce4:	739c                	ld	a5,32(a5)
ffffffffc0202ce6:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202ce8:	00093783          	ld	a5,0(s2)
ffffffffc0202cec:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202cf0:	12000073          	sfence.vma
ffffffffc0202cf4:	100027f3          	csrr	a5,sstatus
ffffffffc0202cf8:	8b89                	andi	a5,a5,2
ffffffffc0202cfa:	10079e63          	bnez	a5,ffffffffc0202e16 <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cfe:	000b3783          	ld	a5,0(s6)
ffffffffc0202d02:	779c                	ld	a5,40(a5)
ffffffffc0202d04:	9782                	jalr	a5
ffffffffc0202d06:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d08:	1e8c1b63          	bne	s8,s0,ffffffffc0202efe <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d0c:	00004517          	auipc	a0,0x4
ffffffffc0202d10:	fa450513          	addi	a0,a0,-92 # ffffffffc0206cb0 <etext+0x1478>
ffffffffc0202d14:	c80fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202d18:	7406                	ld	s0,96(sp)
ffffffffc0202d1a:	70a6                	ld	ra,104(sp)
ffffffffc0202d1c:	64e6                	ld	s1,88(sp)
ffffffffc0202d1e:	6946                	ld	s2,80(sp)
ffffffffc0202d20:	69a6                	ld	s3,72(sp)
ffffffffc0202d22:	6a06                	ld	s4,64(sp)
ffffffffc0202d24:	7ae2                	ld	s5,56(sp)
ffffffffc0202d26:	7b42                	ld	s6,48(sp)
ffffffffc0202d28:	7ba2                	ld	s7,40(sp)
ffffffffc0202d2a:	7c02                	ld	s8,32(sp)
ffffffffc0202d2c:	6ce2                	ld	s9,24(sp)
ffffffffc0202d2e:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d30:	f85fe06f          	j	ffffffffc0201cb4 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202d34:	853e                	mv	a0,a5
ffffffffc0202d36:	b4e1                	j	ffffffffc02027fe <pmm_init+0x90>
        intr_disable();
ffffffffc0202d38:	bcdfd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d3c:	000b3783          	ld	a5,0(s6)
ffffffffc0202d40:	4505                	li	a0,1
ffffffffc0202d42:	6f9c                	ld	a5,24(a5)
ffffffffc0202d44:	9782                	jalr	a5
ffffffffc0202d46:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d48:	bb7fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d4c:	be75                	j	ffffffffc0202908 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202d4e:	bb7fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d52:	000b3783          	ld	a5,0(s6)
ffffffffc0202d56:	779c                	ld	a5,40(a5)
ffffffffc0202d58:	9782                	jalr	a5
ffffffffc0202d5a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d5c:	ba3fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d60:	b6ad                	j	ffffffffc02028ca <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d62:	6705                	lui	a4,0x1
ffffffffc0202d64:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7bb1>
ffffffffc0202d66:	96ba                	add	a3,a3,a4
ffffffffc0202d68:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d6a:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d6e:	14a77e63          	bgeu	a4,a0,ffffffffc0202eca <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d72:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d76:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202d78:	071a                	slli	a4,a4,0x6
ffffffffc0202d7a:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202d7e:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202d80:	6a9c                	ld	a5,16(a3)
ffffffffc0202d82:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d86:	00e60533          	add	a0,a2,a4
ffffffffc0202d8a:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d8c:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d90:	bcf1                	j	ffffffffc020286c <pmm_init+0xfe>
        intr_disable();
ffffffffc0202d92:	b73fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d96:	000b3783          	ld	a5,0(s6)
ffffffffc0202d9a:	4505                	li	a0,1
ffffffffc0202d9c:	6f9c                	ld	a5,24(a5)
ffffffffc0202d9e:	9782                	jalr	a5
ffffffffc0202da0:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202da2:	b5dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202da6:	b119                	j	ffffffffc02029ac <pmm_init+0x23e>
        intr_disable();
ffffffffc0202da8:	b5dfd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dac:	000b3783          	ld	a5,0(s6)
ffffffffc0202db0:	779c                	ld	a5,40(a5)
ffffffffc0202db2:	9782                	jalr	a5
ffffffffc0202db4:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202db6:	b49fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dba:	b345                	j	ffffffffc0202b5a <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202dbc:	b49fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202dc0:	000b3783          	ld	a5,0(s6)
ffffffffc0202dc4:	779c                	ld	a5,40(a5)
ffffffffc0202dc6:	9782                	jalr	a5
ffffffffc0202dc8:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dca:	b35fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dce:	b3a5                	j	ffffffffc0202b36 <pmm_init+0x3c8>
ffffffffc0202dd0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dd2:	b33fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202dd6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dda:	6522                	ld	a0,8(sp)
ffffffffc0202ddc:	4585                	li	a1,1
ffffffffc0202dde:	739c                	ld	a5,32(a5)
ffffffffc0202de0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202de2:	b1dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202de6:	bb05                	j	ffffffffc0202b16 <pmm_init+0x3a8>
ffffffffc0202de8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dea:	b1bfd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202dee:	000b3783          	ld	a5,0(s6)
ffffffffc0202df2:	6522                	ld	a0,8(sp)
ffffffffc0202df4:	4585                	li	a1,1
ffffffffc0202df6:	739c                	ld	a5,32(a5)
ffffffffc0202df8:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dfa:	b05fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dfe:	b1e5                	j	ffffffffc0202ae6 <pmm_init+0x378>
        intr_disable();
ffffffffc0202e00:	b05fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e04:	000b3783          	ld	a5,0(s6)
ffffffffc0202e08:	4505                	li	a0,1
ffffffffc0202e0a:	6f9c                	ld	a5,24(a5)
ffffffffc0202e0c:	9782                	jalr	a5
ffffffffc0202e0e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e10:	aeffd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e14:	b375                	j	ffffffffc0202bc0 <pmm_init+0x452>
        intr_disable();
ffffffffc0202e16:	aeffd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e1a:	000b3783          	ld	a5,0(s6)
ffffffffc0202e1e:	779c                	ld	a5,40(a5)
ffffffffc0202e20:	9782                	jalr	a5
ffffffffc0202e22:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e24:	adbfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e28:	b5c5                	j	ffffffffc0202d08 <pmm_init+0x59a>
ffffffffc0202e2a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e2c:	ad9fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e30:	000b3783          	ld	a5,0(s6)
ffffffffc0202e34:	6522                	ld	a0,8(sp)
ffffffffc0202e36:	4585                	li	a1,1
ffffffffc0202e38:	739c                	ld	a5,32(a5)
ffffffffc0202e3a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e3c:	ac3fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e40:	b565                	j	ffffffffc0202ce8 <pmm_init+0x57a>
ffffffffc0202e42:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e44:	ac1fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e48:	000b3783          	ld	a5,0(s6)
ffffffffc0202e4c:	6522                	ld	a0,8(sp)
ffffffffc0202e4e:	4585                	li	a1,1
ffffffffc0202e50:	739c                	ld	a5,32(a5)
ffffffffc0202e52:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e54:	aabfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e58:	b585                	j	ffffffffc0202cb8 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202e5a:	aabfd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e5e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e62:	8522                	mv	a0,s0
ffffffffc0202e64:	4585                	li	a1,1
ffffffffc0202e66:	739c                	ld	a5,32(a5)
ffffffffc0202e68:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e6a:	a95fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e6e:	bd29                	j	ffffffffc0202c88 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e70:	86a2                	mv	a3,s0
ffffffffc0202e72:	00003617          	auipc	a2,0x3
ffffffffc0202e76:	75660613          	addi	a2,a2,1878 # ffffffffc02065c8 <etext+0xd90>
ffffffffc0202e7a:	24f00593          	li	a1,591
ffffffffc0202e7e:	00004517          	auipc	a0,0x4
ffffffffc0202e82:	83a50513          	addi	a0,a0,-1990 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202e86:	dc0fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e8a:	00004697          	auipc	a3,0x4
ffffffffc0202e8e:	cc668693          	addi	a3,a3,-826 # ffffffffc0206b50 <etext+0x1318>
ffffffffc0202e92:	00003617          	auipc	a2,0x3
ffffffffc0202e96:	38660613          	addi	a2,a2,902 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0202e9a:	25000593          	li	a1,592
ffffffffc0202e9e:	00004517          	auipc	a0,0x4
ffffffffc0202ea2:	81a50513          	addi	a0,a0,-2022 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202ea6:	da0fd0ef          	jal	ffffffffc0200446 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202eaa:	00004697          	auipc	a3,0x4
ffffffffc0202eae:	c6668693          	addi	a3,a3,-922 # ffffffffc0206b10 <etext+0x12d8>
ffffffffc0202eb2:	00003617          	auipc	a2,0x3
ffffffffc0202eb6:	36660613          	addi	a2,a2,870 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0202eba:	24f00593          	li	a1,591
ffffffffc0202ebe:	00003517          	auipc	a0,0x3
ffffffffc0202ec2:	7fa50513          	addi	a0,a0,2042 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202ec6:	d80fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202eca:	fb5fe0ef          	jal	ffffffffc0201e7e <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202ece:	00004617          	auipc	a2,0x4
ffffffffc0202ed2:	9e260613          	addi	a2,a2,-1566 # ffffffffc02068b0 <etext+0x1078>
ffffffffc0202ed6:	07f00593          	li	a1,127
ffffffffc0202eda:	00003517          	auipc	a0,0x3
ffffffffc0202ede:	71650513          	addi	a0,a0,1814 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc0202ee2:	d64fd0ef          	jal	ffffffffc0200446 <__panic>
        panic("DTB memory info not available");
ffffffffc0202ee6:	00004617          	auipc	a2,0x4
ffffffffc0202eea:	84260613          	addi	a2,a2,-1982 # ffffffffc0206728 <etext+0xef0>
ffffffffc0202eee:	06500593          	li	a1,101
ffffffffc0202ef2:	00003517          	auipc	a0,0x3
ffffffffc0202ef6:	7c650513          	addi	a0,a0,1990 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202efa:	d4cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202efe:	00004697          	auipc	a3,0x4
ffffffffc0202f02:	bca68693          	addi	a3,a3,-1078 # ffffffffc0206ac8 <etext+0x1290>
ffffffffc0202f06:	00003617          	auipc	a2,0x3
ffffffffc0202f0a:	31260613          	addi	a2,a2,786 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0202f0e:	26a00593          	li	a1,618
ffffffffc0202f12:	00003517          	auipc	a0,0x3
ffffffffc0202f16:	7a650513          	addi	a0,a0,1958 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202f1a:	d2cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202f1e:	00004697          	auipc	a3,0x4
ffffffffc0202f22:	8c268693          	addi	a3,a3,-1854 # ffffffffc02067e0 <etext+0xfa8>
ffffffffc0202f26:	00003617          	auipc	a2,0x3
ffffffffc0202f2a:	2f260613          	addi	a2,a2,754 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0202f2e:	21100593          	li	a1,529
ffffffffc0202f32:	00003517          	auipc	a0,0x3
ffffffffc0202f36:	78650513          	addi	a0,a0,1926 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202f3a:	d0cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f3e:	00004697          	auipc	a3,0x4
ffffffffc0202f42:	88268693          	addi	a3,a3,-1918 # ffffffffc02067c0 <etext+0xf88>
ffffffffc0202f46:	00003617          	auipc	a2,0x3
ffffffffc0202f4a:	2d260613          	addi	a2,a2,722 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0202f4e:	21000593          	li	a1,528
ffffffffc0202f52:	00003517          	auipc	a0,0x3
ffffffffc0202f56:	76650513          	addi	a0,a0,1894 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202f5a:	cecfd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f5e:	00003617          	auipc	a2,0x3
ffffffffc0202f62:	66a60613          	addi	a2,a2,1642 # ffffffffc02065c8 <etext+0xd90>
ffffffffc0202f66:	07100593          	li	a1,113
ffffffffc0202f6a:	00003517          	auipc	a0,0x3
ffffffffc0202f6e:	68650513          	addi	a0,a0,1670 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc0202f72:	cd4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f76:	00004697          	auipc	a3,0x4
ffffffffc0202f7a:	b2268693          	addi	a3,a3,-1246 # ffffffffc0206a98 <etext+0x1260>
ffffffffc0202f7e:	00003617          	auipc	a2,0x3
ffffffffc0202f82:	29a60613          	addi	a2,a2,666 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0202f86:	23800593          	li	a1,568
ffffffffc0202f8a:	00003517          	auipc	a0,0x3
ffffffffc0202f8e:	72e50513          	addi	a0,a0,1838 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202f92:	cb4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f96:	00004697          	auipc	a3,0x4
ffffffffc0202f9a:	aba68693          	addi	a3,a3,-1350 # ffffffffc0206a50 <etext+0x1218>
ffffffffc0202f9e:	00003617          	auipc	a2,0x3
ffffffffc0202fa2:	27a60613          	addi	a2,a2,634 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0202fa6:	23600593          	li	a1,566
ffffffffc0202faa:	00003517          	auipc	a0,0x3
ffffffffc0202fae:	70e50513          	addi	a0,a0,1806 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202fb2:	c94fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202fb6:	00004697          	auipc	a3,0x4
ffffffffc0202fba:	aca68693          	addi	a3,a3,-1334 # ffffffffc0206a80 <etext+0x1248>
ffffffffc0202fbe:	00003617          	auipc	a2,0x3
ffffffffc0202fc2:	25a60613          	addi	a2,a2,602 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0202fc6:	23500593          	li	a1,565
ffffffffc0202fca:	00003517          	auipc	a0,0x3
ffffffffc0202fce:	6ee50513          	addi	a0,a0,1774 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202fd2:	c74fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202fd6:	00004697          	auipc	a3,0x4
ffffffffc0202fda:	b9268693          	addi	a3,a3,-1134 # ffffffffc0206b68 <etext+0x1330>
ffffffffc0202fde:	00003617          	auipc	a2,0x3
ffffffffc0202fe2:	23a60613          	addi	a2,a2,570 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0202fe6:	25300593          	li	a1,595
ffffffffc0202fea:	00003517          	auipc	a0,0x3
ffffffffc0202fee:	6ce50513          	addi	a0,a0,1742 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0202ff2:	c54fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202ff6:	00004697          	auipc	a3,0x4
ffffffffc0202ffa:	ad268693          	addi	a3,a3,-1326 # ffffffffc0206ac8 <etext+0x1290>
ffffffffc0202ffe:	00003617          	auipc	a2,0x3
ffffffffc0203002:	21a60613          	addi	a2,a2,538 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203006:	24000593          	li	a1,576
ffffffffc020300a:	00003517          	auipc	a0,0x3
ffffffffc020300e:	6ae50513          	addi	a0,a0,1710 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203012:	c34fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203016:	00004697          	auipc	a3,0x4
ffffffffc020301a:	baa68693          	addi	a3,a3,-1110 # ffffffffc0206bc0 <etext+0x1388>
ffffffffc020301e:	00003617          	auipc	a2,0x3
ffffffffc0203022:	1fa60613          	addi	a2,a2,506 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203026:	25800593          	li	a1,600
ffffffffc020302a:	00003517          	auipc	a0,0x3
ffffffffc020302e:	68e50513          	addi	a0,a0,1678 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203032:	c14fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203036:	00004697          	auipc	a3,0x4
ffffffffc020303a:	b4a68693          	addi	a3,a3,-1206 # ffffffffc0206b80 <etext+0x1348>
ffffffffc020303e:	00003617          	auipc	a2,0x3
ffffffffc0203042:	1da60613          	addi	a2,a2,474 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203046:	25700593          	li	a1,599
ffffffffc020304a:	00003517          	auipc	a0,0x3
ffffffffc020304e:	66e50513          	addi	a0,a0,1646 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203052:	bf4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203056:	00004697          	auipc	a3,0x4
ffffffffc020305a:	9fa68693          	addi	a3,a3,-1542 # ffffffffc0206a50 <etext+0x1218>
ffffffffc020305e:	00003617          	auipc	a2,0x3
ffffffffc0203062:	1ba60613          	addi	a2,a2,442 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203066:	23200593          	li	a1,562
ffffffffc020306a:	00003517          	auipc	a0,0x3
ffffffffc020306e:	64e50513          	addi	a0,a0,1614 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203072:	bd4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203076:	00004697          	auipc	a3,0x4
ffffffffc020307a:	87a68693          	addi	a3,a3,-1926 # ffffffffc02068f0 <etext+0x10b8>
ffffffffc020307e:	00003617          	auipc	a2,0x3
ffffffffc0203082:	19a60613          	addi	a2,a2,410 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203086:	23100593          	li	a1,561
ffffffffc020308a:	00003517          	auipc	a0,0x3
ffffffffc020308e:	62e50513          	addi	a0,a0,1582 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203092:	bb4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203096:	00004697          	auipc	a3,0x4
ffffffffc020309a:	9d268693          	addi	a3,a3,-1582 # ffffffffc0206a68 <etext+0x1230>
ffffffffc020309e:	00003617          	auipc	a2,0x3
ffffffffc02030a2:	17a60613          	addi	a2,a2,378 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02030a6:	22e00593          	li	a1,558
ffffffffc02030aa:	00003517          	auipc	a0,0x3
ffffffffc02030ae:	60e50513          	addi	a0,a0,1550 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02030b2:	b94fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02030b6:	00004697          	auipc	a3,0x4
ffffffffc02030ba:	82268693          	addi	a3,a3,-2014 # ffffffffc02068d8 <etext+0x10a0>
ffffffffc02030be:	00003617          	auipc	a2,0x3
ffffffffc02030c2:	15a60613          	addi	a2,a2,346 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02030c6:	22d00593          	li	a1,557
ffffffffc02030ca:	00003517          	auipc	a0,0x3
ffffffffc02030ce:	5ee50513          	addi	a0,a0,1518 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02030d2:	b74fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030d6:	00004697          	auipc	a3,0x4
ffffffffc02030da:	8a268693          	addi	a3,a3,-1886 # ffffffffc0206978 <etext+0x1140>
ffffffffc02030de:	00003617          	auipc	a2,0x3
ffffffffc02030e2:	13a60613          	addi	a2,a2,314 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02030e6:	22c00593          	li	a1,556
ffffffffc02030ea:	00003517          	auipc	a0,0x3
ffffffffc02030ee:	5ce50513          	addi	a0,a0,1486 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02030f2:	b54fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030f6:	00004697          	auipc	a3,0x4
ffffffffc02030fa:	95a68693          	addi	a3,a3,-1702 # ffffffffc0206a50 <etext+0x1218>
ffffffffc02030fe:	00003617          	auipc	a2,0x3
ffffffffc0203102:	11a60613          	addi	a2,a2,282 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203106:	22b00593          	li	a1,555
ffffffffc020310a:	00003517          	auipc	a0,0x3
ffffffffc020310e:	5ae50513          	addi	a0,a0,1454 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203112:	b34fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203116:	00004697          	auipc	a3,0x4
ffffffffc020311a:	92268693          	addi	a3,a3,-1758 # ffffffffc0206a38 <etext+0x1200>
ffffffffc020311e:	00003617          	auipc	a2,0x3
ffffffffc0203122:	0fa60613          	addi	a2,a2,250 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203126:	22a00593          	li	a1,554
ffffffffc020312a:	00003517          	auipc	a0,0x3
ffffffffc020312e:	58e50513          	addi	a0,a0,1422 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203132:	b14fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203136:	00004697          	auipc	a3,0x4
ffffffffc020313a:	8d268693          	addi	a3,a3,-1838 # ffffffffc0206a08 <etext+0x11d0>
ffffffffc020313e:	00003617          	auipc	a2,0x3
ffffffffc0203142:	0da60613          	addi	a2,a2,218 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203146:	22900593          	li	a1,553
ffffffffc020314a:	00003517          	auipc	a0,0x3
ffffffffc020314e:	56e50513          	addi	a0,a0,1390 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203152:	af4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203156:	00004697          	auipc	a3,0x4
ffffffffc020315a:	89a68693          	addi	a3,a3,-1894 # ffffffffc02069f0 <etext+0x11b8>
ffffffffc020315e:	00003617          	auipc	a2,0x3
ffffffffc0203162:	0ba60613          	addi	a2,a2,186 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203166:	22700593          	li	a1,551
ffffffffc020316a:	00003517          	auipc	a0,0x3
ffffffffc020316e:	54e50513          	addi	a0,a0,1358 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203172:	ad4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203176:	00004697          	auipc	a3,0x4
ffffffffc020317a:	85a68693          	addi	a3,a3,-1958 # ffffffffc02069d0 <etext+0x1198>
ffffffffc020317e:	00003617          	auipc	a2,0x3
ffffffffc0203182:	09a60613          	addi	a2,a2,154 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203186:	22600593          	li	a1,550
ffffffffc020318a:	00003517          	auipc	a0,0x3
ffffffffc020318e:	52e50513          	addi	a0,a0,1326 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203192:	ab4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203196:	00004697          	auipc	a3,0x4
ffffffffc020319a:	82a68693          	addi	a3,a3,-2006 # ffffffffc02069c0 <etext+0x1188>
ffffffffc020319e:	00003617          	auipc	a2,0x3
ffffffffc02031a2:	07a60613          	addi	a2,a2,122 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02031a6:	22500593          	li	a1,549
ffffffffc02031aa:	00003517          	auipc	a0,0x3
ffffffffc02031ae:	50e50513          	addi	a0,a0,1294 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02031b2:	a94fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_U);
ffffffffc02031b6:	00003697          	auipc	a3,0x3
ffffffffc02031ba:	7fa68693          	addi	a3,a3,2042 # ffffffffc02069b0 <etext+0x1178>
ffffffffc02031be:	00003617          	auipc	a2,0x3
ffffffffc02031c2:	05a60613          	addi	a2,a2,90 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02031c6:	22400593          	li	a1,548
ffffffffc02031ca:	00003517          	auipc	a0,0x3
ffffffffc02031ce:	4ee50513          	addi	a0,a0,1262 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02031d2:	a74fd0ef          	jal	ffffffffc0200446 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02031d6:	00003617          	auipc	a2,0x3
ffffffffc02031da:	49a60613          	addi	a2,a2,1178 # ffffffffc0206670 <etext+0xe38>
ffffffffc02031de:	08100593          	li	a1,129
ffffffffc02031e2:	00003517          	auipc	a0,0x3
ffffffffc02031e6:	4d650513          	addi	a0,a0,1238 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02031ea:	a5cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02031ee:	00003697          	auipc	a3,0x3
ffffffffc02031f2:	71a68693          	addi	a3,a3,1818 # ffffffffc0206908 <etext+0x10d0>
ffffffffc02031f6:	00003617          	auipc	a2,0x3
ffffffffc02031fa:	02260613          	addi	a2,a2,34 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02031fe:	21f00593          	li	a1,543
ffffffffc0203202:	00003517          	auipc	a0,0x3
ffffffffc0203206:	4b650513          	addi	a0,a0,1206 # ffffffffc02066b8 <etext+0xe80>
ffffffffc020320a:	a3cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020320e:	00003697          	auipc	a3,0x3
ffffffffc0203212:	76a68693          	addi	a3,a3,1898 # ffffffffc0206978 <etext+0x1140>
ffffffffc0203216:	00003617          	auipc	a2,0x3
ffffffffc020321a:	00260613          	addi	a2,a2,2 # ffffffffc0206218 <etext+0x9e0>
ffffffffc020321e:	22300593          	li	a1,547
ffffffffc0203222:	00003517          	auipc	a0,0x3
ffffffffc0203226:	49650513          	addi	a0,a0,1174 # ffffffffc02066b8 <etext+0xe80>
ffffffffc020322a:	a1cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020322e:	00003697          	auipc	a3,0x3
ffffffffc0203232:	70a68693          	addi	a3,a3,1802 # ffffffffc0206938 <etext+0x1100>
ffffffffc0203236:	00003617          	auipc	a2,0x3
ffffffffc020323a:	fe260613          	addi	a2,a2,-30 # ffffffffc0206218 <etext+0x9e0>
ffffffffc020323e:	22200593          	li	a1,546
ffffffffc0203242:	00003517          	auipc	a0,0x3
ffffffffc0203246:	47650513          	addi	a0,a0,1142 # ffffffffc02066b8 <etext+0xe80>
ffffffffc020324a:	9fcfd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020324e:	86d6                	mv	a3,s5
ffffffffc0203250:	00003617          	auipc	a2,0x3
ffffffffc0203254:	37860613          	addi	a2,a2,888 # ffffffffc02065c8 <etext+0xd90>
ffffffffc0203258:	21e00593          	li	a1,542
ffffffffc020325c:	00003517          	auipc	a0,0x3
ffffffffc0203260:	45c50513          	addi	a0,a0,1116 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203264:	9e2fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203268:	00003617          	auipc	a2,0x3
ffffffffc020326c:	36060613          	addi	a2,a2,864 # ffffffffc02065c8 <etext+0xd90>
ffffffffc0203270:	21d00593          	li	a1,541
ffffffffc0203274:	00003517          	auipc	a0,0x3
ffffffffc0203278:	44450513          	addi	a0,a0,1092 # ffffffffc02066b8 <etext+0xe80>
ffffffffc020327c:	9cafd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203280:	00003697          	auipc	a3,0x3
ffffffffc0203284:	67068693          	addi	a3,a3,1648 # ffffffffc02068f0 <etext+0x10b8>
ffffffffc0203288:	00003617          	auipc	a2,0x3
ffffffffc020328c:	f9060613          	addi	a2,a2,-112 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203290:	21b00593          	li	a1,539
ffffffffc0203294:	00003517          	auipc	a0,0x3
ffffffffc0203298:	42450513          	addi	a0,a0,1060 # ffffffffc02066b8 <etext+0xe80>
ffffffffc020329c:	9aafd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02032a0:	00003697          	auipc	a3,0x3
ffffffffc02032a4:	63868693          	addi	a3,a3,1592 # ffffffffc02068d8 <etext+0x10a0>
ffffffffc02032a8:	00003617          	auipc	a2,0x3
ffffffffc02032ac:	f7060613          	addi	a2,a2,-144 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02032b0:	21a00593          	li	a1,538
ffffffffc02032b4:	00003517          	auipc	a0,0x3
ffffffffc02032b8:	40450513          	addi	a0,a0,1028 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02032bc:	98afd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02032c0:	00004697          	auipc	a3,0x4
ffffffffc02032c4:	9c868693          	addi	a3,a3,-1592 # ffffffffc0206c88 <etext+0x1450>
ffffffffc02032c8:	00003617          	auipc	a2,0x3
ffffffffc02032cc:	f5060613          	addi	a2,a2,-176 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02032d0:	26100593          	li	a1,609
ffffffffc02032d4:	00003517          	auipc	a0,0x3
ffffffffc02032d8:	3e450513          	addi	a0,a0,996 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02032dc:	96afd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02032e0:	00004697          	auipc	a3,0x4
ffffffffc02032e4:	97068693          	addi	a3,a3,-1680 # ffffffffc0206c50 <etext+0x1418>
ffffffffc02032e8:	00003617          	auipc	a2,0x3
ffffffffc02032ec:	f3060613          	addi	a2,a2,-208 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02032f0:	25e00593          	li	a1,606
ffffffffc02032f4:	00003517          	auipc	a0,0x3
ffffffffc02032f8:	3c450513          	addi	a0,a0,964 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02032fc:	94afd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0203300:	00004697          	auipc	a3,0x4
ffffffffc0203304:	92068693          	addi	a3,a3,-1760 # ffffffffc0206c20 <etext+0x13e8>
ffffffffc0203308:	00003617          	auipc	a2,0x3
ffffffffc020330c:	f1060613          	addi	a2,a2,-240 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203310:	25a00593          	li	a1,602
ffffffffc0203314:	00003517          	auipc	a0,0x3
ffffffffc0203318:	3a450513          	addi	a0,a0,932 # ffffffffc02066b8 <etext+0xe80>
ffffffffc020331c:	92afd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203320:	00004697          	auipc	a3,0x4
ffffffffc0203324:	8b868693          	addi	a3,a3,-1864 # ffffffffc0206bd8 <etext+0x13a0>
ffffffffc0203328:	00003617          	auipc	a2,0x3
ffffffffc020332c:	ef060613          	addi	a2,a2,-272 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203330:	25900593          	li	a1,601
ffffffffc0203334:	00003517          	auipc	a0,0x3
ffffffffc0203338:	38450513          	addi	a0,a0,900 # ffffffffc02066b8 <etext+0xe80>
ffffffffc020333c:	90afd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0203340:	00003697          	auipc	a3,0x3
ffffffffc0203344:	4e068693          	addi	a3,a3,1248 # ffffffffc0206820 <etext+0xfe8>
ffffffffc0203348:	00003617          	auipc	a2,0x3
ffffffffc020334c:	ed060613          	addi	a2,a2,-304 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203350:	21200593          	li	a1,530
ffffffffc0203354:	00003517          	auipc	a0,0x3
ffffffffc0203358:	36450513          	addi	a0,a0,868 # ffffffffc02066b8 <etext+0xe80>
ffffffffc020335c:	8eafd0ef          	jal	ffffffffc0200446 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203360:	00003617          	auipc	a2,0x3
ffffffffc0203364:	31060613          	addi	a2,a2,784 # ffffffffc0206670 <etext+0xe38>
ffffffffc0203368:	0c900593          	li	a1,201
ffffffffc020336c:	00003517          	auipc	a0,0x3
ffffffffc0203370:	34c50513          	addi	a0,a0,844 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203374:	8d2fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203378:	00003697          	auipc	a3,0x3
ffffffffc020337c:	50868693          	addi	a3,a3,1288 # ffffffffc0206880 <etext+0x1048>
ffffffffc0203380:	00003617          	auipc	a2,0x3
ffffffffc0203384:	e9860613          	addi	a2,a2,-360 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203388:	21900593          	li	a1,537
ffffffffc020338c:	00003517          	auipc	a0,0x3
ffffffffc0203390:	32c50513          	addi	a0,a0,812 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203394:	8b2fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203398:	00003697          	auipc	a3,0x3
ffffffffc020339c:	4b868693          	addi	a3,a3,1208 # ffffffffc0206850 <etext+0x1018>
ffffffffc02033a0:	00003617          	auipc	a2,0x3
ffffffffc02033a4:	e7860613          	addi	a2,a2,-392 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02033a8:	21600593          	li	a1,534
ffffffffc02033ac:	00003517          	auipc	a0,0x3
ffffffffc02033b0:	30c50513          	addi	a0,a0,780 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02033b4:	892fd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02033b8 <copy_range>:
{
ffffffffc02033b8:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033ba:	00d667b3          	or	a5,a2,a3
{
ffffffffc02033be:	f486                	sd	ra,104(sp)
ffffffffc02033c0:	f0a2                	sd	s0,96(sp)
ffffffffc02033c2:	eca6                	sd	s1,88(sp)
ffffffffc02033c4:	e8ca                	sd	s2,80(sp)
ffffffffc02033c6:	e4ce                	sd	s3,72(sp)
ffffffffc02033c8:	e0d2                	sd	s4,64(sp)
ffffffffc02033ca:	fc56                	sd	s5,56(sp)
ffffffffc02033cc:	f85a                	sd	s6,48(sp)
ffffffffc02033ce:	f45e                	sd	s7,40(sp)
ffffffffc02033d0:	f062                	sd	s8,32(sp)
ffffffffc02033d2:	ec66                	sd	s9,24(sp)
ffffffffc02033d4:	e86a                	sd	s10,16(sp)
ffffffffc02033d6:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033d8:	03479713          	slli	a4,a5,0x34
ffffffffc02033dc:	20071f63          	bnez	a4,ffffffffc02035fa <copy_range+0x242>
    assert(USER_ACCESS(start, end));
ffffffffc02033e0:	002007b7          	lui	a5,0x200
ffffffffc02033e4:	00d63733          	sltu	a4,a2,a3
ffffffffc02033e8:	00f637b3          	sltu	a5,a2,a5
ffffffffc02033ec:	00173713          	seqz	a4,a4
ffffffffc02033f0:	8fd9                	or	a5,a5,a4
ffffffffc02033f2:	8432                	mv	s0,a2
ffffffffc02033f4:	8936                	mv	s2,a3
ffffffffc02033f6:	1e079263          	bnez	a5,ffffffffc02035da <copy_range+0x222>
ffffffffc02033fa:	4785                	li	a5,1
ffffffffc02033fc:	07fe                	slli	a5,a5,0x1f
ffffffffc02033fe:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e49>
ffffffffc0203400:	1cf6fd63          	bgeu	a3,a5,ffffffffc02035da <copy_range+0x222>
ffffffffc0203404:	5b7d                	li	s6,-1
ffffffffc0203406:	8baa                	mv	s7,a0
ffffffffc0203408:	8a2e                	mv	s4,a1
ffffffffc020340a:	6a85                	lui	s5,0x1
ffffffffc020340c:	00cb5b13          	srli	s6,s6,0xc
    if (PPN(pa) >= npage)
ffffffffc0203410:	00098c97          	auipc	s9,0x98
ffffffffc0203414:	258c8c93          	addi	s9,s9,600 # ffffffffc029b668 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203418:	00098c17          	auipc	s8,0x98
ffffffffc020341c:	258c0c13          	addi	s8,s8,600 # ffffffffc029b670 <pages>
ffffffffc0203420:	fff80d37          	lui	s10,0xfff80
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203424:	4601                	li	a2,0
ffffffffc0203426:	85a2                	mv	a1,s0
ffffffffc0203428:	8552                	mv	a0,s4
ffffffffc020342a:	b19fe0ef          	jal	ffffffffc0201f42 <get_pte>
ffffffffc020342e:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0203430:	0e050a63          	beqz	a0,ffffffffc0203524 <copy_range+0x16c>
        if (*ptep & PTE_V)
ffffffffc0203434:	611c                	ld	a5,0(a0)
ffffffffc0203436:	8b85                	andi	a5,a5,1
ffffffffc0203438:	e78d                	bnez	a5,ffffffffc0203462 <copy_range+0xaa>
        start += PGSIZE;
ffffffffc020343a:	9456                	add	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020343c:	c019                	beqz	s0,ffffffffc0203442 <copy_range+0x8a>
ffffffffc020343e:	ff2463e3          	bltu	s0,s2,ffffffffc0203424 <copy_range+0x6c>
    return 0;
ffffffffc0203442:	4501                	li	a0,0
}
ffffffffc0203444:	70a6                	ld	ra,104(sp)
ffffffffc0203446:	7406                	ld	s0,96(sp)
ffffffffc0203448:	64e6                	ld	s1,88(sp)
ffffffffc020344a:	6946                	ld	s2,80(sp)
ffffffffc020344c:	69a6                	ld	s3,72(sp)
ffffffffc020344e:	6a06                	ld	s4,64(sp)
ffffffffc0203450:	7ae2                	ld	s5,56(sp)
ffffffffc0203452:	7b42                	ld	s6,48(sp)
ffffffffc0203454:	7ba2                	ld	s7,40(sp)
ffffffffc0203456:	7c02                	ld	s8,32(sp)
ffffffffc0203458:	6ce2                	ld	s9,24(sp)
ffffffffc020345a:	6d42                	ld	s10,16(sp)
ffffffffc020345c:	6da2                	ld	s11,8(sp)
ffffffffc020345e:	6165                	addi	sp,sp,112
ffffffffc0203460:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203462:	4605                	li	a2,1
ffffffffc0203464:	85a2                	mv	a1,s0
ffffffffc0203466:	855e                	mv	a0,s7
ffffffffc0203468:	adbfe0ef          	jal	ffffffffc0201f42 <get_pte>
ffffffffc020346c:	c165                	beqz	a0,ffffffffc020354c <copy_range+0x194>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc020346e:	0004b983          	ld	s3,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203472:	0019f793          	andi	a5,s3,1
ffffffffc0203476:	14078663          	beqz	a5,ffffffffc02035c2 <copy_range+0x20a>
    if (PPN(pa) >= npage)
ffffffffc020347a:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020347e:	00299793          	slli	a5,s3,0x2
ffffffffc0203482:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203484:	12e7f363          	bgeu	a5,a4,ffffffffc02035aa <copy_range+0x1f2>
    return &pages[PPN(pa) - nbase];
ffffffffc0203488:	000c3483          	ld	s1,0(s8)
ffffffffc020348c:	97ea                	add	a5,a5,s10
ffffffffc020348e:	079a                	slli	a5,a5,0x6
ffffffffc0203490:	94be                	add	s1,s1,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203492:	100027f3          	csrr	a5,sstatus
ffffffffc0203496:	8b89                	andi	a5,a5,2
ffffffffc0203498:	efc9                	bnez	a5,ffffffffc0203532 <copy_range+0x17a>
        page = pmm_manager->alloc_pages(n);
ffffffffc020349a:	00098797          	auipc	a5,0x98
ffffffffc020349e:	1ae7b783          	ld	a5,430(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc02034a2:	4505                	li	a0,1
ffffffffc02034a4:	6f9c                	ld	a5,24(a5)
ffffffffc02034a6:	9782                	jalr	a5
ffffffffc02034a8:	8daa                	mv	s11,a0
            assert(page != NULL);
ffffffffc02034aa:	c0e5                	beqz	s1,ffffffffc020358a <copy_range+0x1d2>
            assert(npage != NULL);
ffffffffc02034ac:	0a0d8f63          	beqz	s11,ffffffffc020356a <copy_range+0x1b2>
    return page - pages + nbase;
ffffffffc02034b0:	000c3783          	ld	a5,0(s8)
ffffffffc02034b4:	00080637          	lui	a2,0x80
    return KADDR(page2pa(page));
ffffffffc02034b8:	000cb703          	ld	a4,0(s9)
    return page - pages + nbase;
ffffffffc02034bc:	40f486b3          	sub	a3,s1,a5
ffffffffc02034c0:	8699                	srai	a3,a3,0x6
ffffffffc02034c2:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02034c4:	0166f5b3          	and	a1,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034c8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02034ca:	08e5f463          	bgeu	a1,a4,ffffffffc0203552 <copy_range+0x19a>
    return page - pages + nbase;
ffffffffc02034ce:	40fd87b3          	sub	a5,s11,a5
ffffffffc02034d2:	8799                	srai	a5,a5,0x6
ffffffffc02034d4:	97b2                	add	a5,a5,a2
    return KADDR(page2pa(page));
ffffffffc02034d6:	0167f633          	and	a2,a5,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034da:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02034dc:	06e67a63          	bgeu	a2,a4,ffffffffc0203550 <copy_range+0x198>
ffffffffc02034e0:	00098517          	auipc	a0,0x98
ffffffffc02034e4:	18053503          	ld	a0,384(a0) # ffffffffc029b660 <va_pa_offset>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc02034e8:	6605                	lui	a2,0x1
ffffffffc02034ea:	00a685b3          	add	a1,a3,a0
ffffffffc02034ee:	953e                	add	a0,a0,a5
ffffffffc02034f0:	330020ef          	jal	ffffffffc0205820 <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02034f4:	01f9f693          	andi	a3,s3,31
ffffffffc02034f8:	85ee                	mv	a1,s11
ffffffffc02034fa:	8622                	mv	a2,s0
ffffffffc02034fc:	855e                	mv	a0,s7
ffffffffc02034fe:	97aff0ef          	jal	ffffffffc0202678 <page_insert>
            assert(ret == 0);
ffffffffc0203502:	dd05                	beqz	a0,ffffffffc020343a <copy_range+0x82>
ffffffffc0203504:	00003697          	auipc	a3,0x3
ffffffffc0203508:	7ec68693          	addi	a3,a3,2028 # ffffffffc0206cf0 <etext+0x14b8>
ffffffffc020350c:	00003617          	auipc	a2,0x3
ffffffffc0203510:	d0c60613          	addi	a2,a2,-756 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203514:	1ae00593          	li	a1,430
ffffffffc0203518:	00003517          	auipc	a0,0x3
ffffffffc020351c:	1a050513          	addi	a0,a0,416 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203520:	f27fc0ef          	jal	ffffffffc0200446 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203524:	002007b7          	lui	a5,0x200
ffffffffc0203528:	97a2                	add	a5,a5,s0
ffffffffc020352a:	ffe00437          	lui	s0,0xffe00
ffffffffc020352e:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc0203530:	b731                	j	ffffffffc020343c <copy_range+0x84>
        intr_disable();
ffffffffc0203532:	bd2fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203536:	00098797          	auipc	a5,0x98
ffffffffc020353a:	1127b783          	ld	a5,274(a5) # ffffffffc029b648 <pmm_manager>
ffffffffc020353e:	4505                	li	a0,1
ffffffffc0203540:	6f9c                	ld	a5,24(a5)
ffffffffc0203542:	9782                	jalr	a5
ffffffffc0203544:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc0203546:	bb8fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020354a:	b785                	j	ffffffffc02034aa <copy_range+0xf2>
                return -E_NO_MEM;
ffffffffc020354c:	5571                	li	a0,-4
ffffffffc020354e:	bddd                	j	ffffffffc0203444 <copy_range+0x8c>
ffffffffc0203550:	86be                	mv	a3,a5
ffffffffc0203552:	00003617          	auipc	a2,0x3
ffffffffc0203556:	07660613          	addi	a2,a2,118 # ffffffffc02065c8 <etext+0xd90>
ffffffffc020355a:	07100593          	li	a1,113
ffffffffc020355e:	00003517          	auipc	a0,0x3
ffffffffc0203562:	09250513          	addi	a0,a0,146 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc0203566:	ee1fc0ef          	jal	ffffffffc0200446 <__panic>
            assert(npage != NULL);
ffffffffc020356a:	00003697          	auipc	a3,0x3
ffffffffc020356e:	77668693          	addi	a3,a3,1910 # ffffffffc0206ce0 <etext+0x14a8>
ffffffffc0203572:	00003617          	auipc	a2,0x3
ffffffffc0203576:	ca660613          	addi	a2,a2,-858 # ffffffffc0206218 <etext+0x9e0>
ffffffffc020357a:	19500593          	li	a1,405
ffffffffc020357e:	00003517          	auipc	a0,0x3
ffffffffc0203582:	13a50513          	addi	a0,a0,314 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203586:	ec1fc0ef          	jal	ffffffffc0200446 <__panic>
            assert(page != NULL);
ffffffffc020358a:	00003697          	auipc	a3,0x3
ffffffffc020358e:	74668693          	addi	a3,a3,1862 # ffffffffc0206cd0 <etext+0x1498>
ffffffffc0203592:	00003617          	auipc	a2,0x3
ffffffffc0203596:	c8660613          	addi	a2,a2,-890 # ffffffffc0206218 <etext+0x9e0>
ffffffffc020359a:	19400593          	li	a1,404
ffffffffc020359e:	00003517          	auipc	a0,0x3
ffffffffc02035a2:	11a50513          	addi	a0,a0,282 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02035a6:	ea1fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02035aa:	00003617          	auipc	a2,0x3
ffffffffc02035ae:	0ee60613          	addi	a2,a2,238 # ffffffffc0206698 <etext+0xe60>
ffffffffc02035b2:	06900593          	li	a1,105
ffffffffc02035b6:	00003517          	auipc	a0,0x3
ffffffffc02035ba:	03a50513          	addi	a0,a0,58 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc02035be:	e89fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02035c2:	00003617          	auipc	a2,0x3
ffffffffc02035c6:	2ee60613          	addi	a2,a2,750 # ffffffffc02068b0 <etext+0x1078>
ffffffffc02035ca:	07f00593          	li	a1,127
ffffffffc02035ce:	00003517          	auipc	a0,0x3
ffffffffc02035d2:	02250513          	addi	a0,a0,34 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc02035d6:	e71fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02035da:	00003697          	auipc	a3,0x3
ffffffffc02035de:	11e68693          	addi	a3,a3,286 # ffffffffc02066f8 <etext+0xec0>
ffffffffc02035e2:	00003617          	auipc	a2,0x3
ffffffffc02035e6:	c3660613          	addi	a2,a2,-970 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02035ea:	17c00593          	li	a1,380
ffffffffc02035ee:	00003517          	auipc	a0,0x3
ffffffffc02035f2:	0ca50513          	addi	a0,a0,202 # ffffffffc02066b8 <etext+0xe80>
ffffffffc02035f6:	e51fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02035fa:	00003697          	auipc	a3,0x3
ffffffffc02035fe:	0ce68693          	addi	a3,a3,206 # ffffffffc02066c8 <etext+0xe90>
ffffffffc0203602:	00003617          	auipc	a2,0x3
ffffffffc0203606:	c1660613          	addi	a2,a2,-1002 # ffffffffc0206218 <etext+0x9e0>
ffffffffc020360a:	17b00593          	li	a1,379
ffffffffc020360e:	00003517          	auipc	a0,0x3
ffffffffc0203612:	0aa50513          	addi	a0,a0,170 # ffffffffc02066b8 <etext+0xe80>
ffffffffc0203616:	e31fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020361a <pgdir_alloc_page>:
{
ffffffffc020361a:	7139                	addi	sp,sp,-64
ffffffffc020361c:	f426                	sd	s1,40(sp)
ffffffffc020361e:	f04a                	sd	s2,32(sp)
ffffffffc0203620:	ec4e                	sd	s3,24(sp)
ffffffffc0203622:	fc06                	sd	ra,56(sp)
ffffffffc0203624:	f822                	sd	s0,48(sp)
ffffffffc0203626:	892a                	mv	s2,a0
ffffffffc0203628:	84ae                	mv	s1,a1
ffffffffc020362a:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020362c:	100027f3          	csrr	a5,sstatus
ffffffffc0203630:	8b89                	andi	a5,a5,2
ffffffffc0203632:	ebb5                	bnez	a5,ffffffffc02036a6 <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203634:	00098417          	auipc	s0,0x98
ffffffffc0203638:	01440413          	addi	s0,s0,20 # ffffffffc029b648 <pmm_manager>
ffffffffc020363c:	601c                	ld	a5,0(s0)
ffffffffc020363e:	4505                	li	a0,1
ffffffffc0203640:	6f9c                	ld	a5,24(a5)
ffffffffc0203642:	9782                	jalr	a5
ffffffffc0203644:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc0203646:	c5b9                	beqz	a1,ffffffffc0203694 <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203648:	86ce                	mv	a3,s3
ffffffffc020364a:	854a                	mv	a0,s2
ffffffffc020364c:	8626                	mv	a2,s1
ffffffffc020364e:	e42e                	sd	a1,8(sp)
ffffffffc0203650:	828ff0ef          	jal	ffffffffc0202678 <page_insert>
ffffffffc0203654:	65a2                	ld	a1,8(sp)
ffffffffc0203656:	e515                	bnez	a0,ffffffffc0203682 <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc0203658:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc020365a:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc020365c:	4785                	li	a5,1
ffffffffc020365e:	02f70c63          	beq	a4,a5,ffffffffc0203696 <pgdir_alloc_page+0x7c>
ffffffffc0203662:	00003697          	auipc	a3,0x3
ffffffffc0203666:	69e68693          	addi	a3,a3,1694 # ffffffffc0206d00 <etext+0x14c8>
ffffffffc020366a:	00003617          	auipc	a2,0x3
ffffffffc020366e:	bae60613          	addi	a2,a2,-1106 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203672:	1f700593          	li	a1,503
ffffffffc0203676:	00003517          	auipc	a0,0x3
ffffffffc020367a:	04250513          	addi	a0,a0,66 # ffffffffc02066b8 <etext+0xe80>
ffffffffc020367e:	dc9fc0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0203682:	100027f3          	csrr	a5,sstatus
ffffffffc0203686:	8b89                	andi	a5,a5,2
ffffffffc0203688:	ef95                	bnez	a5,ffffffffc02036c4 <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc020368a:	601c                	ld	a5,0(s0)
ffffffffc020368c:	852e                	mv	a0,a1
ffffffffc020368e:	4585                	li	a1,1
ffffffffc0203690:	739c                	ld	a5,32(a5)
ffffffffc0203692:	9782                	jalr	a5
            return NULL;
ffffffffc0203694:	4581                	li	a1,0
}
ffffffffc0203696:	70e2                	ld	ra,56(sp)
ffffffffc0203698:	7442                	ld	s0,48(sp)
ffffffffc020369a:	74a2                	ld	s1,40(sp)
ffffffffc020369c:	7902                	ld	s2,32(sp)
ffffffffc020369e:	69e2                	ld	s3,24(sp)
ffffffffc02036a0:	852e                	mv	a0,a1
ffffffffc02036a2:	6121                	addi	sp,sp,64
ffffffffc02036a4:	8082                	ret
        intr_disable();
ffffffffc02036a6:	a5efd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02036aa:	00098417          	auipc	s0,0x98
ffffffffc02036ae:	f9e40413          	addi	s0,s0,-98 # ffffffffc029b648 <pmm_manager>
ffffffffc02036b2:	601c                	ld	a5,0(s0)
ffffffffc02036b4:	4505                	li	a0,1
ffffffffc02036b6:	6f9c                	ld	a5,24(a5)
ffffffffc02036b8:	9782                	jalr	a5
ffffffffc02036ba:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02036bc:	a42fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02036c0:	65a2                	ld	a1,8(sp)
ffffffffc02036c2:	b751                	j	ffffffffc0203646 <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc02036c4:	a40fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02036c8:	601c                	ld	a5,0(s0)
ffffffffc02036ca:	6522                	ld	a0,8(sp)
ffffffffc02036cc:	4585                	li	a1,1
ffffffffc02036ce:	739c                	ld	a5,32(a5)
ffffffffc02036d0:	9782                	jalr	a5
        intr_enable();
ffffffffc02036d2:	a2cfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02036d6:	bf7d                	j	ffffffffc0203694 <pgdir_alloc_page+0x7a>

ffffffffc02036d8 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036d8:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02036da:	00003697          	auipc	a3,0x3
ffffffffc02036de:	63e68693          	addi	a3,a3,1598 # ffffffffc0206d18 <etext+0x14e0>
ffffffffc02036e2:	00003617          	auipc	a2,0x3
ffffffffc02036e6:	b3660613          	addi	a2,a2,-1226 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02036ea:	07400593          	li	a1,116
ffffffffc02036ee:	00003517          	auipc	a0,0x3
ffffffffc02036f2:	64a50513          	addi	a0,a0,1610 # ffffffffc0206d38 <etext+0x1500>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036f6:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02036f8:	d4ffc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02036fc <mm_create>:
{
ffffffffc02036fc:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036fe:	04000513          	li	a0,64
{
ffffffffc0203702:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203704:	dd4fe0ef          	jal	ffffffffc0201cd8 <kmalloc>
    if (mm != NULL)
ffffffffc0203708:	cd19                	beqz	a0,ffffffffc0203726 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc020370a:	e508                	sd	a0,8(a0)
ffffffffc020370c:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc020370e:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203712:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203716:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc020371a:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc020371e:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203722:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203726:	60a2                	ld	ra,8(sp)
ffffffffc0203728:	0141                	addi	sp,sp,16
ffffffffc020372a:	8082                	ret

ffffffffc020372c <find_vma>:
    if (mm != NULL)
ffffffffc020372c:	c505                	beqz	a0,ffffffffc0203754 <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc020372e:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203730:	c781                	beqz	a5,ffffffffc0203738 <find_vma+0xc>
ffffffffc0203732:	6798                	ld	a4,8(a5)
ffffffffc0203734:	02e5f363          	bgeu	a1,a4,ffffffffc020375a <find_vma+0x2e>
    return listelm->next;
ffffffffc0203738:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc020373a:	00f50d63          	beq	a0,a5,ffffffffc0203754 <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020373e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203742:	00e5e663          	bltu	a1,a4,ffffffffc020374e <find_vma+0x22>
ffffffffc0203746:	ff07b703          	ld	a4,-16(a5)
ffffffffc020374a:	00e5ee63          	bltu	a1,a4,ffffffffc0203766 <find_vma+0x3a>
ffffffffc020374e:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203750:	fef517e3          	bne	a0,a5,ffffffffc020373e <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc0203754:	4781                	li	a5,0
}
ffffffffc0203756:	853e                	mv	a0,a5
ffffffffc0203758:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020375a:	6b98                	ld	a4,16(a5)
ffffffffc020375c:	fce5fee3          	bgeu	a1,a4,ffffffffc0203738 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0203760:	e91c                	sd	a5,16(a0)
}
ffffffffc0203762:	853e                	mv	a0,a5
ffffffffc0203764:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203766:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203768:	e91c                	sd	a5,16(a0)
ffffffffc020376a:	bfe5                	j	ffffffffc0203762 <find_vma+0x36>

ffffffffc020376c <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020376c:	6590                	ld	a2,8(a1)
ffffffffc020376e:	0105b803          	ld	a6,16(a1)
{
ffffffffc0203772:	1141                	addi	sp,sp,-16
ffffffffc0203774:	e406                	sd	ra,8(sp)
ffffffffc0203776:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203778:	01066763          	bltu	a2,a6,ffffffffc0203786 <insert_vma_struct+0x1a>
ffffffffc020377c:	a8b9                	j	ffffffffc02037da <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020377e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203782:	04e66763          	bltu	a2,a4,ffffffffc02037d0 <insert_vma_struct+0x64>
ffffffffc0203786:	86be                	mv	a3,a5
ffffffffc0203788:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020378a:	fef51ae3          	bne	a0,a5,ffffffffc020377e <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020378e:	02a68463          	beq	a3,a0,ffffffffc02037b6 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203792:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203796:	fe86b883          	ld	a7,-24(a3)
ffffffffc020379a:	08e8f063          	bgeu	a7,a4,ffffffffc020381a <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020379e:	04e66e63          	bltu	a2,a4,ffffffffc02037fa <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc02037a2:	00f50a63          	beq	a0,a5,ffffffffc02037b6 <insert_vma_struct+0x4a>
ffffffffc02037a6:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037aa:	05076863          	bltu	a4,a6,ffffffffc02037fa <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02037ae:	ff07b603          	ld	a2,-16(a5)
ffffffffc02037b2:	02c77263          	bgeu	a4,a2,ffffffffc02037d6 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc02037b6:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc02037b8:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02037ba:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02037be:	e390                	sd	a2,0(a5)
ffffffffc02037c0:	e690                	sd	a2,8(a3)
}
ffffffffc02037c2:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02037c4:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02037c6:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc02037c8:	2705                	addiw	a4,a4,1
ffffffffc02037ca:	d118                	sw	a4,32(a0)
}
ffffffffc02037cc:	0141                	addi	sp,sp,16
ffffffffc02037ce:	8082                	ret
    if (le_prev != list)
ffffffffc02037d0:	fca691e3          	bne	a3,a0,ffffffffc0203792 <insert_vma_struct+0x26>
ffffffffc02037d4:	bfd9                	j	ffffffffc02037aa <insert_vma_struct+0x3e>
ffffffffc02037d6:	f03ff0ef          	jal	ffffffffc02036d8 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037da:	00003697          	auipc	a3,0x3
ffffffffc02037de:	56e68693          	addi	a3,a3,1390 # ffffffffc0206d48 <etext+0x1510>
ffffffffc02037e2:	00003617          	auipc	a2,0x3
ffffffffc02037e6:	a3660613          	addi	a2,a2,-1482 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02037ea:	07a00593          	li	a1,122
ffffffffc02037ee:	00003517          	auipc	a0,0x3
ffffffffc02037f2:	54a50513          	addi	a0,a0,1354 # ffffffffc0206d38 <etext+0x1500>
ffffffffc02037f6:	c51fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037fa:	00003697          	auipc	a3,0x3
ffffffffc02037fe:	58e68693          	addi	a3,a3,1422 # ffffffffc0206d88 <etext+0x1550>
ffffffffc0203802:	00003617          	auipc	a2,0x3
ffffffffc0203806:	a1660613          	addi	a2,a2,-1514 # ffffffffc0206218 <etext+0x9e0>
ffffffffc020380a:	07300593          	li	a1,115
ffffffffc020380e:	00003517          	auipc	a0,0x3
ffffffffc0203812:	52a50513          	addi	a0,a0,1322 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203816:	c31fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020381a:	00003697          	auipc	a3,0x3
ffffffffc020381e:	54e68693          	addi	a3,a3,1358 # ffffffffc0206d68 <etext+0x1530>
ffffffffc0203822:	00003617          	auipc	a2,0x3
ffffffffc0203826:	9f660613          	addi	a2,a2,-1546 # ffffffffc0206218 <etext+0x9e0>
ffffffffc020382a:	07200593          	li	a1,114
ffffffffc020382e:	00003517          	auipc	a0,0x3
ffffffffc0203832:	50a50513          	addi	a0,a0,1290 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203836:	c11fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020383a <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc020383a:	591c                	lw	a5,48(a0)
{
ffffffffc020383c:	1141                	addi	sp,sp,-16
ffffffffc020383e:	e406                	sd	ra,8(sp)
ffffffffc0203840:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203842:	e78d                	bnez	a5,ffffffffc020386c <mm_destroy+0x32>
ffffffffc0203844:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203846:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203848:	00a40c63          	beq	s0,a0,ffffffffc0203860 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020384c:	6118                	ld	a4,0(a0)
ffffffffc020384e:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203850:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203852:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203854:	e398                	sd	a4,0(a5)
ffffffffc0203856:	d28fe0ef          	jal	ffffffffc0201d7e <kfree>
    return listelm->next;
ffffffffc020385a:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc020385c:	fea418e3          	bne	s0,a0,ffffffffc020384c <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203860:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203862:	6402                	ld	s0,0(sp)
ffffffffc0203864:	60a2                	ld	ra,8(sp)
ffffffffc0203866:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203868:	d16fe06f          	j	ffffffffc0201d7e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc020386c:	00003697          	auipc	a3,0x3
ffffffffc0203870:	53c68693          	addi	a3,a3,1340 # ffffffffc0206da8 <etext+0x1570>
ffffffffc0203874:	00003617          	auipc	a2,0x3
ffffffffc0203878:	9a460613          	addi	a2,a2,-1628 # ffffffffc0206218 <etext+0x9e0>
ffffffffc020387c:	09e00593          	li	a1,158
ffffffffc0203880:	00003517          	auipc	a0,0x3
ffffffffc0203884:	4b850513          	addi	a0,a0,1208 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203888:	bbffc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020388c <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020388c:	6785                	lui	a5,0x1
ffffffffc020388e:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7bb1>
ffffffffc0203890:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc0203892:	4785                	li	a5,1
{
ffffffffc0203894:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203896:	962e                	add	a2,a2,a1
ffffffffc0203898:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc020389a:	07fe                	slli	a5,a5,0x1f
{
ffffffffc020389c:	f822                	sd	s0,48(sp)
ffffffffc020389e:	f426                	sd	s1,40(sp)
ffffffffc02038a0:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02038a4:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc02038a8:	0785                	addi	a5,a5,1
ffffffffc02038aa:	0084b633          	sltu	a2,s1,s0
ffffffffc02038ae:	00f437b3          	sltu	a5,s0,a5
ffffffffc02038b2:	00163613          	seqz	a2,a2
ffffffffc02038b6:	0017b793          	seqz	a5,a5
{
ffffffffc02038ba:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc02038bc:	8fd1                	or	a5,a5,a2
ffffffffc02038be:	ebbd                	bnez	a5,ffffffffc0203934 <mm_map+0xa8>
ffffffffc02038c0:	002007b7          	lui	a5,0x200
ffffffffc02038c4:	06f4e863          	bltu	s1,a5,ffffffffc0203934 <mm_map+0xa8>
ffffffffc02038c8:	f04a                	sd	s2,32(sp)
ffffffffc02038ca:	ec4e                	sd	s3,24(sp)
ffffffffc02038cc:	e852                	sd	s4,16(sp)
ffffffffc02038ce:	892a                	mv	s2,a0
ffffffffc02038d0:	89ba                	mv	s3,a4
ffffffffc02038d2:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02038d4:	c135                	beqz	a0,ffffffffc0203938 <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc02038d6:	85a6                	mv	a1,s1
ffffffffc02038d8:	e55ff0ef          	jal	ffffffffc020372c <find_vma>
ffffffffc02038dc:	c501                	beqz	a0,ffffffffc02038e4 <mm_map+0x58>
ffffffffc02038de:	651c                	ld	a5,8(a0)
ffffffffc02038e0:	0487e763          	bltu	a5,s0,ffffffffc020392e <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038e4:	03000513          	li	a0,48
ffffffffc02038e8:	bf0fe0ef          	jal	ffffffffc0201cd8 <kmalloc>
ffffffffc02038ec:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02038ee:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02038f0:	c59d                	beqz	a1,ffffffffc020391e <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc02038f2:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc02038f4:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02038f6:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02038fa:	854a                	mv	a0,s2
ffffffffc02038fc:	e42e                	sd	a1,8(sp)
ffffffffc02038fe:	e6fff0ef          	jal	ffffffffc020376c <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc0203902:	65a2                	ld	a1,8(sp)
ffffffffc0203904:	00098463          	beqz	s3,ffffffffc020390c <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc0203908:	00b9b023          	sd	a1,0(s3)
ffffffffc020390c:	7902                	ld	s2,32(sp)
ffffffffc020390e:	69e2                	ld	s3,24(sp)
ffffffffc0203910:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc0203912:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc0203914:	70e2                	ld	ra,56(sp)
ffffffffc0203916:	7442                	ld	s0,48(sp)
ffffffffc0203918:	74a2                	ld	s1,40(sp)
ffffffffc020391a:	6121                	addi	sp,sp,64
ffffffffc020391c:	8082                	ret
ffffffffc020391e:	70e2                	ld	ra,56(sp)
ffffffffc0203920:	7442                	ld	s0,48(sp)
ffffffffc0203922:	7902                	ld	s2,32(sp)
ffffffffc0203924:	69e2                	ld	s3,24(sp)
ffffffffc0203926:	6a42                	ld	s4,16(sp)
ffffffffc0203928:	74a2                	ld	s1,40(sp)
ffffffffc020392a:	6121                	addi	sp,sp,64
ffffffffc020392c:	8082                	ret
ffffffffc020392e:	7902                	ld	s2,32(sp)
ffffffffc0203930:	69e2                	ld	s3,24(sp)
ffffffffc0203932:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc0203934:	5575                	li	a0,-3
ffffffffc0203936:	bff9                	j	ffffffffc0203914 <mm_map+0x88>
    assert(mm != NULL);
ffffffffc0203938:	00003697          	auipc	a3,0x3
ffffffffc020393c:	48868693          	addi	a3,a3,1160 # ffffffffc0206dc0 <etext+0x1588>
ffffffffc0203940:	00003617          	auipc	a2,0x3
ffffffffc0203944:	8d860613          	addi	a2,a2,-1832 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203948:	0b300593          	li	a1,179
ffffffffc020394c:	00003517          	auipc	a0,0x3
ffffffffc0203950:	3ec50513          	addi	a0,a0,1004 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203954:	af3fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203958 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203958:	7139                	addi	sp,sp,-64
ffffffffc020395a:	fc06                	sd	ra,56(sp)
ffffffffc020395c:	f822                	sd	s0,48(sp)
ffffffffc020395e:	f426                	sd	s1,40(sp)
ffffffffc0203960:	f04a                	sd	s2,32(sp)
ffffffffc0203962:	ec4e                	sd	s3,24(sp)
ffffffffc0203964:	e852                	sd	s4,16(sp)
ffffffffc0203966:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203968:	c525                	beqz	a0,ffffffffc02039d0 <dup_mmap+0x78>
ffffffffc020396a:	892a                	mv	s2,a0
ffffffffc020396c:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc020396e:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203970:	c1a5                	beqz	a1,ffffffffc02039d0 <dup_mmap+0x78>
    return listelm->prev;
ffffffffc0203972:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203974:	04848c63          	beq	s1,s0,ffffffffc02039cc <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203978:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc020397c:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203980:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203984:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203988:	b50fe0ef          	jal	ffffffffc0201cd8 <kmalloc>
    if (vma != NULL)
ffffffffc020398c:	c515                	beqz	a0,ffffffffc02039b8 <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc020398e:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203990:	01553423          	sd	s5,8(a0)
ffffffffc0203994:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203998:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc020399c:	854a                	mv	a0,s2
ffffffffc020399e:	dcfff0ef          	jal	ffffffffc020376c <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02039a2:	ff043683          	ld	a3,-16(s0)
ffffffffc02039a6:	fe843603          	ld	a2,-24(s0)
ffffffffc02039aa:	6c8c                	ld	a1,24(s1)
ffffffffc02039ac:	01893503          	ld	a0,24(s2)
ffffffffc02039b0:	4701                	li	a4,0
ffffffffc02039b2:	a07ff0ef          	jal	ffffffffc02033b8 <copy_range>
ffffffffc02039b6:	dd55                	beqz	a0,ffffffffc0203972 <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc02039b8:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02039ba:	70e2                	ld	ra,56(sp)
ffffffffc02039bc:	7442                	ld	s0,48(sp)
ffffffffc02039be:	74a2                	ld	s1,40(sp)
ffffffffc02039c0:	7902                	ld	s2,32(sp)
ffffffffc02039c2:	69e2                	ld	s3,24(sp)
ffffffffc02039c4:	6a42                	ld	s4,16(sp)
ffffffffc02039c6:	6aa2                	ld	s5,8(sp)
ffffffffc02039c8:	6121                	addi	sp,sp,64
ffffffffc02039ca:	8082                	ret
    return 0;
ffffffffc02039cc:	4501                	li	a0,0
ffffffffc02039ce:	b7f5                	j	ffffffffc02039ba <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc02039d0:	00003697          	auipc	a3,0x3
ffffffffc02039d4:	40068693          	addi	a3,a3,1024 # ffffffffc0206dd0 <etext+0x1598>
ffffffffc02039d8:	00003617          	auipc	a2,0x3
ffffffffc02039dc:	84060613          	addi	a2,a2,-1984 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02039e0:	0cf00593          	li	a1,207
ffffffffc02039e4:	00003517          	auipc	a0,0x3
ffffffffc02039e8:	35450513          	addi	a0,a0,852 # ffffffffc0206d38 <etext+0x1500>
ffffffffc02039ec:	a5bfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02039f0 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc02039f0:	1101                	addi	sp,sp,-32
ffffffffc02039f2:	ec06                	sd	ra,24(sp)
ffffffffc02039f4:	e822                	sd	s0,16(sp)
ffffffffc02039f6:	e426                	sd	s1,8(sp)
ffffffffc02039f8:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039fa:	c531                	beqz	a0,ffffffffc0203a46 <exit_mmap+0x56>
ffffffffc02039fc:	591c                	lw	a5,48(a0)
ffffffffc02039fe:	84aa                	mv	s1,a0
ffffffffc0203a00:	e3b9                	bnez	a5,ffffffffc0203a46 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203a02:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203a04:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203a08:	02850663          	beq	a0,s0,ffffffffc0203a34 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a0c:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a10:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a14:	854a                	mv	a0,s2
ffffffffc0203a16:	fdefe0ef          	jal	ffffffffc02021f4 <unmap_range>
ffffffffc0203a1a:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a1c:	fe8498e3          	bne	s1,s0,ffffffffc0203a0c <exit_mmap+0x1c>
ffffffffc0203a20:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a22:	00848c63          	beq	s1,s0,ffffffffc0203a3a <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a26:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a2a:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a2e:	854a                	mv	a0,s2
ffffffffc0203a30:	8f9fe0ef          	jal	ffffffffc0202328 <exit_range>
ffffffffc0203a34:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a36:	fe8498e3          	bne	s1,s0,ffffffffc0203a26 <exit_mmap+0x36>
    }
}
ffffffffc0203a3a:	60e2                	ld	ra,24(sp)
ffffffffc0203a3c:	6442                	ld	s0,16(sp)
ffffffffc0203a3e:	64a2                	ld	s1,8(sp)
ffffffffc0203a40:	6902                	ld	s2,0(sp)
ffffffffc0203a42:	6105                	addi	sp,sp,32
ffffffffc0203a44:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a46:	00003697          	auipc	a3,0x3
ffffffffc0203a4a:	3aa68693          	addi	a3,a3,938 # ffffffffc0206df0 <etext+0x15b8>
ffffffffc0203a4e:	00002617          	auipc	a2,0x2
ffffffffc0203a52:	7ca60613          	addi	a2,a2,1994 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203a56:	0e800593          	li	a1,232
ffffffffc0203a5a:	00003517          	auipc	a0,0x3
ffffffffc0203a5e:	2de50513          	addi	a0,a0,734 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203a62:	9e5fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203a66 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203a66:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a68:	04000513          	li	a0,64
{
ffffffffc0203a6c:	f406                	sd	ra,40(sp)
ffffffffc0203a6e:	f022                	sd	s0,32(sp)
ffffffffc0203a70:	ec26                	sd	s1,24(sp)
ffffffffc0203a72:	e84a                	sd	s2,16(sp)
ffffffffc0203a74:	e44e                	sd	s3,8(sp)
ffffffffc0203a76:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a78:	a60fe0ef          	jal	ffffffffc0201cd8 <kmalloc>
    if (mm != NULL)
ffffffffc0203a7c:	16050c63          	beqz	a0,ffffffffc0203bf4 <vmm_init+0x18e>
ffffffffc0203a80:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0203a82:	e508                	sd	a0,8(a0)
ffffffffc0203a84:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a86:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a8a:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a8e:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203a92:	02053423          	sd	zero,40(a0)
ffffffffc0203a96:	02052823          	sw	zero,48(a0)
ffffffffc0203a9a:	02053c23          	sd	zero,56(a0)
ffffffffc0203a9e:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203aa2:	03000513          	li	a0,48
ffffffffc0203aa6:	a32fe0ef          	jal	ffffffffc0201cd8 <kmalloc>
    if (vma != NULL)
ffffffffc0203aaa:	12050563          	beqz	a0,ffffffffc0203bd4 <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc0203aae:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203ab2:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203ab4:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203ab8:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203aba:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0203abc:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0203abe:	8522                	mv	a0,s0
ffffffffc0203ac0:	cadff0ef          	jal	ffffffffc020376c <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203ac4:	fcf9                	bnez	s1,ffffffffc0203aa2 <vmm_init+0x3c>
ffffffffc0203ac6:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203aca:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203ace:	03000513          	li	a0,48
ffffffffc0203ad2:	a06fe0ef          	jal	ffffffffc0201cd8 <kmalloc>
    if (vma != NULL)
ffffffffc0203ad6:	12050f63          	beqz	a0,ffffffffc0203c14 <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc0203ada:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203ade:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203ae0:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203ae4:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203ae6:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ae8:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203aea:	8522                	mv	a0,s0
ffffffffc0203aec:	c81ff0ef          	jal	ffffffffc020376c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203af0:	fd249fe3          	bne	s1,s2,ffffffffc0203ace <vmm_init+0x68>
    return listelm->next;
ffffffffc0203af4:	641c                	ld	a5,8(s0)
ffffffffc0203af6:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203af8:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203afc:	1ef40c63          	beq	s0,a5,ffffffffc0203cf4 <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b00:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f5e30>
ffffffffc0203b04:	ffe70693          	addi	a3,a4,-2
ffffffffc0203b08:	12d61663          	bne	a2,a3,ffffffffc0203c34 <vmm_init+0x1ce>
ffffffffc0203b0c:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203b10:	12e69263          	bne	a3,a4,ffffffffc0203c34 <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203b14:	0715                	addi	a4,a4,5
ffffffffc0203b16:	679c                	ld	a5,8(a5)
ffffffffc0203b18:	feb712e3          	bne	a4,a1,ffffffffc0203afc <vmm_init+0x96>
ffffffffc0203b1c:	491d                	li	s2,7
ffffffffc0203b1e:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b20:	85a6                	mv	a1,s1
ffffffffc0203b22:	8522                	mv	a0,s0
ffffffffc0203b24:	c09ff0ef          	jal	ffffffffc020372c <find_vma>
ffffffffc0203b28:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203b2a:	20050563          	beqz	a0,ffffffffc0203d34 <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b2e:	00148593          	addi	a1,s1,1
ffffffffc0203b32:	8522                	mv	a0,s0
ffffffffc0203b34:	bf9ff0ef          	jal	ffffffffc020372c <find_vma>
ffffffffc0203b38:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b3a:	1c050d63          	beqz	a0,ffffffffc0203d14 <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b3e:	85ca                	mv	a1,s2
ffffffffc0203b40:	8522                	mv	a0,s0
ffffffffc0203b42:	bebff0ef          	jal	ffffffffc020372c <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b46:	18051763          	bnez	a0,ffffffffc0203cd4 <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b4a:	00348593          	addi	a1,s1,3
ffffffffc0203b4e:	8522                	mv	a0,s0
ffffffffc0203b50:	bddff0ef          	jal	ffffffffc020372c <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b54:	16051063          	bnez	a0,ffffffffc0203cb4 <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b58:	00448593          	addi	a1,s1,4
ffffffffc0203b5c:	8522                	mv	a0,s0
ffffffffc0203b5e:	bcfff0ef          	jal	ffffffffc020372c <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b62:	12051963          	bnez	a0,ffffffffc0203c94 <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b66:	008a3783          	ld	a5,8(s4)
ffffffffc0203b6a:	10979563          	bne	a5,s1,ffffffffc0203c74 <vmm_init+0x20e>
ffffffffc0203b6e:	010a3783          	ld	a5,16(s4)
ffffffffc0203b72:	11279163          	bne	a5,s2,ffffffffc0203c74 <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b76:	0089b783          	ld	a5,8(s3)
ffffffffc0203b7a:	0c979d63          	bne	a5,s1,ffffffffc0203c54 <vmm_init+0x1ee>
ffffffffc0203b7e:	0109b783          	ld	a5,16(s3)
ffffffffc0203b82:	0d279963          	bne	a5,s2,ffffffffc0203c54 <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b86:	0495                	addi	s1,s1,5
ffffffffc0203b88:	1f900793          	li	a5,505
ffffffffc0203b8c:	0915                	addi	s2,s2,5
ffffffffc0203b8e:	f8f499e3          	bne	s1,a5,ffffffffc0203b20 <vmm_init+0xba>
ffffffffc0203b92:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b94:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b96:	85a6                	mv	a1,s1
ffffffffc0203b98:	8522                	mv	a0,s0
ffffffffc0203b9a:	b93ff0ef          	jal	ffffffffc020372c <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203b9e:	1a051b63          	bnez	a0,ffffffffc0203d54 <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203ba2:	14fd                	addi	s1,s1,-1
ffffffffc0203ba4:	ff2499e3          	bne	s1,s2,ffffffffc0203b96 <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203ba8:	8522                	mv	a0,s0
ffffffffc0203baa:	c91ff0ef          	jal	ffffffffc020383a <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203bae:	00003517          	auipc	a0,0x3
ffffffffc0203bb2:	3b250513          	addi	a0,a0,946 # ffffffffc0206f60 <etext+0x1728>
ffffffffc0203bb6:	ddefc0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0203bba:	7402                	ld	s0,32(sp)
ffffffffc0203bbc:	70a2                	ld	ra,40(sp)
ffffffffc0203bbe:	64e2                	ld	s1,24(sp)
ffffffffc0203bc0:	6942                	ld	s2,16(sp)
ffffffffc0203bc2:	69a2                	ld	s3,8(sp)
ffffffffc0203bc4:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bc6:	00003517          	auipc	a0,0x3
ffffffffc0203bca:	3ba50513          	addi	a0,a0,954 # ffffffffc0206f80 <etext+0x1748>
}
ffffffffc0203bce:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bd0:	dc4fc06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0203bd4:	00003697          	auipc	a3,0x3
ffffffffc0203bd8:	23c68693          	addi	a3,a3,572 # ffffffffc0206e10 <etext+0x15d8>
ffffffffc0203bdc:	00002617          	auipc	a2,0x2
ffffffffc0203be0:	63c60613          	addi	a2,a2,1596 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203be4:	12c00593          	li	a1,300
ffffffffc0203be8:	00003517          	auipc	a0,0x3
ffffffffc0203bec:	15050513          	addi	a0,a0,336 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203bf0:	857fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(mm != NULL);
ffffffffc0203bf4:	00003697          	auipc	a3,0x3
ffffffffc0203bf8:	1cc68693          	addi	a3,a3,460 # ffffffffc0206dc0 <etext+0x1588>
ffffffffc0203bfc:	00002617          	auipc	a2,0x2
ffffffffc0203c00:	61c60613          	addi	a2,a2,1564 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203c04:	12400593          	li	a1,292
ffffffffc0203c08:	00003517          	auipc	a0,0x3
ffffffffc0203c0c:	13050513          	addi	a0,a0,304 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203c10:	837fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma != NULL);
ffffffffc0203c14:	00003697          	auipc	a3,0x3
ffffffffc0203c18:	1fc68693          	addi	a3,a3,508 # ffffffffc0206e10 <etext+0x15d8>
ffffffffc0203c1c:	00002617          	auipc	a2,0x2
ffffffffc0203c20:	5fc60613          	addi	a2,a2,1532 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203c24:	13300593          	li	a1,307
ffffffffc0203c28:	00003517          	auipc	a0,0x3
ffffffffc0203c2c:	11050513          	addi	a0,a0,272 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203c30:	817fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203c34:	00003697          	auipc	a3,0x3
ffffffffc0203c38:	20468693          	addi	a3,a3,516 # ffffffffc0206e38 <etext+0x1600>
ffffffffc0203c3c:	00002617          	auipc	a2,0x2
ffffffffc0203c40:	5dc60613          	addi	a2,a2,1500 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203c44:	13d00593          	li	a1,317
ffffffffc0203c48:	00003517          	auipc	a0,0x3
ffffffffc0203c4c:	0f050513          	addi	a0,a0,240 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203c50:	ff6fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c54:	00003697          	auipc	a3,0x3
ffffffffc0203c58:	29c68693          	addi	a3,a3,668 # ffffffffc0206ef0 <etext+0x16b8>
ffffffffc0203c5c:	00002617          	auipc	a2,0x2
ffffffffc0203c60:	5bc60613          	addi	a2,a2,1468 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203c64:	14f00593          	li	a1,335
ffffffffc0203c68:	00003517          	auipc	a0,0x3
ffffffffc0203c6c:	0d050513          	addi	a0,a0,208 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203c70:	fd6fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c74:	00003697          	auipc	a3,0x3
ffffffffc0203c78:	24c68693          	addi	a3,a3,588 # ffffffffc0206ec0 <etext+0x1688>
ffffffffc0203c7c:	00002617          	auipc	a2,0x2
ffffffffc0203c80:	59c60613          	addi	a2,a2,1436 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203c84:	14e00593          	li	a1,334
ffffffffc0203c88:	00003517          	auipc	a0,0x3
ffffffffc0203c8c:	0b050513          	addi	a0,a0,176 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203c90:	fb6fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma5 == NULL);
ffffffffc0203c94:	00003697          	auipc	a3,0x3
ffffffffc0203c98:	21c68693          	addi	a3,a3,540 # ffffffffc0206eb0 <etext+0x1678>
ffffffffc0203c9c:	00002617          	auipc	a2,0x2
ffffffffc0203ca0:	57c60613          	addi	a2,a2,1404 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203ca4:	14c00593          	li	a1,332
ffffffffc0203ca8:	00003517          	auipc	a0,0x3
ffffffffc0203cac:	09050513          	addi	a0,a0,144 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203cb0:	f96fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma4 == NULL);
ffffffffc0203cb4:	00003697          	auipc	a3,0x3
ffffffffc0203cb8:	1ec68693          	addi	a3,a3,492 # ffffffffc0206ea0 <etext+0x1668>
ffffffffc0203cbc:	00002617          	auipc	a2,0x2
ffffffffc0203cc0:	55c60613          	addi	a2,a2,1372 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203cc4:	14a00593          	li	a1,330
ffffffffc0203cc8:	00003517          	auipc	a0,0x3
ffffffffc0203ccc:	07050513          	addi	a0,a0,112 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203cd0:	f76fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma3 == NULL);
ffffffffc0203cd4:	00003697          	auipc	a3,0x3
ffffffffc0203cd8:	1bc68693          	addi	a3,a3,444 # ffffffffc0206e90 <etext+0x1658>
ffffffffc0203cdc:	00002617          	auipc	a2,0x2
ffffffffc0203ce0:	53c60613          	addi	a2,a2,1340 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203ce4:	14800593          	li	a1,328
ffffffffc0203ce8:	00003517          	auipc	a0,0x3
ffffffffc0203cec:	05050513          	addi	a0,a0,80 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203cf0:	f56fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203cf4:	00003697          	auipc	a3,0x3
ffffffffc0203cf8:	12c68693          	addi	a3,a3,300 # ffffffffc0206e20 <etext+0x15e8>
ffffffffc0203cfc:	00002617          	auipc	a2,0x2
ffffffffc0203d00:	51c60613          	addi	a2,a2,1308 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203d04:	13b00593          	li	a1,315
ffffffffc0203d08:	00003517          	auipc	a0,0x3
ffffffffc0203d0c:	03050513          	addi	a0,a0,48 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203d10:	f36fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2 != NULL);
ffffffffc0203d14:	00003697          	auipc	a3,0x3
ffffffffc0203d18:	16c68693          	addi	a3,a3,364 # ffffffffc0206e80 <etext+0x1648>
ffffffffc0203d1c:	00002617          	auipc	a2,0x2
ffffffffc0203d20:	4fc60613          	addi	a2,a2,1276 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203d24:	14600593          	li	a1,326
ffffffffc0203d28:	00003517          	auipc	a0,0x3
ffffffffc0203d2c:	01050513          	addi	a0,a0,16 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203d30:	f16fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1 != NULL);
ffffffffc0203d34:	00003697          	auipc	a3,0x3
ffffffffc0203d38:	13c68693          	addi	a3,a3,316 # ffffffffc0206e70 <etext+0x1638>
ffffffffc0203d3c:	00002617          	auipc	a2,0x2
ffffffffc0203d40:	4dc60613          	addi	a2,a2,1244 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203d44:	14400593          	li	a1,324
ffffffffc0203d48:	00003517          	auipc	a0,0x3
ffffffffc0203d4c:	ff050513          	addi	a0,a0,-16 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203d50:	ef6fc0ef          	jal	ffffffffc0200446 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d54:	6914                	ld	a3,16(a0)
ffffffffc0203d56:	6510                	ld	a2,8(a0)
ffffffffc0203d58:	0004859b          	sext.w	a1,s1
ffffffffc0203d5c:	00003517          	auipc	a0,0x3
ffffffffc0203d60:	1c450513          	addi	a0,a0,452 # ffffffffc0206f20 <etext+0x16e8>
ffffffffc0203d64:	c30fc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203d68:	00003697          	auipc	a3,0x3
ffffffffc0203d6c:	1e068693          	addi	a3,a3,480 # ffffffffc0206f48 <etext+0x1710>
ffffffffc0203d70:	00002617          	auipc	a2,0x2
ffffffffc0203d74:	4a860613          	addi	a2,a2,1192 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0203d78:	15900593          	li	a1,345
ffffffffc0203d7c:	00003517          	auipc	a0,0x3
ffffffffc0203d80:	fbc50513          	addi	a0,a0,-68 # ffffffffc0206d38 <etext+0x1500>
ffffffffc0203d84:	ec2fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203d88 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203d88:	7179                	addi	sp,sp,-48
ffffffffc0203d8a:	f022                	sd	s0,32(sp)
ffffffffc0203d8c:	f406                	sd	ra,40(sp)
ffffffffc0203d8e:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203d90:	c52d                	beqz	a0,ffffffffc0203dfa <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203d92:	002007b7          	lui	a5,0x200
ffffffffc0203d96:	04f5ed63          	bltu	a1,a5,ffffffffc0203df0 <user_mem_check+0x68>
ffffffffc0203d9a:	ec26                	sd	s1,24(sp)
ffffffffc0203d9c:	00c584b3          	add	s1,a1,a2
ffffffffc0203da0:	0695ff63          	bgeu	a1,s1,ffffffffc0203e1e <user_mem_check+0x96>
ffffffffc0203da4:	4785                	li	a5,1
ffffffffc0203da6:	07fe                	slli	a5,a5,0x1f
ffffffffc0203da8:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e49>
ffffffffc0203daa:	06f4fa63          	bgeu	s1,a5,ffffffffc0203e1e <user_mem_check+0x96>
ffffffffc0203dae:	e84a                	sd	s2,16(sp)
ffffffffc0203db0:	e44e                	sd	s3,8(sp)
ffffffffc0203db2:	8936                	mv	s2,a3
ffffffffc0203db4:	89aa                	mv	s3,a0
ffffffffc0203db6:	a829                	j	ffffffffc0203dd0 <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203db8:	6685                	lui	a3,0x1
ffffffffc0203dba:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203dbc:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203dc0:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203dc2:	c685                	beqz	a3,ffffffffc0203dea <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203dc4:	c399                	beqz	a5,ffffffffc0203dca <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203dc6:	02e46263          	bltu	s0,a4,ffffffffc0203dea <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203dca:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203dcc:	04947b63          	bgeu	s0,s1,ffffffffc0203e22 <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203dd0:	85a2                	mv	a1,s0
ffffffffc0203dd2:	854e                	mv	a0,s3
ffffffffc0203dd4:	959ff0ef          	jal	ffffffffc020372c <find_vma>
ffffffffc0203dd8:	c909                	beqz	a0,ffffffffc0203dea <user_mem_check+0x62>
ffffffffc0203dda:	6518                	ld	a4,8(a0)
ffffffffc0203ddc:	00e46763          	bltu	s0,a4,ffffffffc0203dea <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203de0:	4d1c                	lw	a5,24(a0)
ffffffffc0203de2:	fc091be3          	bnez	s2,ffffffffc0203db8 <user_mem_check+0x30>
ffffffffc0203de6:	8b85                	andi	a5,a5,1
ffffffffc0203de8:	f3ed                	bnez	a5,ffffffffc0203dca <user_mem_check+0x42>
ffffffffc0203dea:	64e2                	ld	s1,24(sp)
ffffffffc0203dec:	6942                	ld	s2,16(sp)
ffffffffc0203dee:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203df0:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203df2:	70a2                	ld	ra,40(sp)
ffffffffc0203df4:	7402                	ld	s0,32(sp)
ffffffffc0203df6:	6145                	addi	sp,sp,48
ffffffffc0203df8:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203dfa:	c02007b7          	lui	a5,0xc0200
ffffffffc0203dfe:	fef5eae3          	bltu	a1,a5,ffffffffc0203df2 <user_mem_check+0x6a>
ffffffffc0203e02:	c80007b7          	lui	a5,0xc8000
ffffffffc0203e06:	962e                	add	a2,a2,a1
ffffffffc0203e08:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d64969>
ffffffffc0203e0a:	00c5b433          	sltu	s0,a1,a2
ffffffffc0203e0e:	00f63633          	sltu	a2,a2,a5
ffffffffc0203e12:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e14:	00867533          	and	a0,a2,s0
ffffffffc0203e18:	7402                	ld	s0,32(sp)
ffffffffc0203e1a:	6145                	addi	sp,sp,48
ffffffffc0203e1c:	8082                	ret
ffffffffc0203e1e:	64e2                	ld	s1,24(sp)
ffffffffc0203e20:	bfc1                	j	ffffffffc0203df0 <user_mem_check+0x68>
ffffffffc0203e22:	64e2                	ld	s1,24(sp)
ffffffffc0203e24:	6942                	ld	s2,16(sp)
ffffffffc0203e26:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203e28:	4505                	li	a0,1
ffffffffc0203e2a:	b7e1                	j	ffffffffc0203df2 <user_mem_check+0x6a>

ffffffffc0203e2c <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203e2c:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203e2e:	9402                	jalr	s0

	jal do_exit
ffffffffc0203e30:	676000ef          	jal	ffffffffc02044a6 <do_exit>

ffffffffc0203e34 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203e34:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e36:	10800513          	li	a0,264
{
ffffffffc0203e3a:	e022                	sd	s0,0(sp)
ffffffffc0203e3c:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e3e:	e9bfd0ef          	jal	ffffffffc0201cd8 <kmalloc>
ffffffffc0203e42:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203e44:	c929                	beqz	a0,ffffffffc0203e96 <alloc_proc+0x62>
        /*
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */
        proc->state = PROC_UNINIT;
ffffffffc0203e46:	57fd                	li	a5,-1
ffffffffc0203e48:	1782                	slli	a5,a5,0x20
ffffffffc0203e4a:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc0203e4c:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0203e50:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0203e54:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203e58:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203e5c:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203e60:	07000613          	li	a2,112
ffffffffc0203e64:	4581                	li	a1,0
ffffffffc0203e66:	03050513          	addi	a0,a0,48
ffffffffc0203e6a:	1a5010ef          	jal	ffffffffc020580e <memset>
        proc->tf = NULL;
        proc->pgdir = 0;
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203e6e:	0b440513          	addi	a0,s0,180
        proc->tf = NULL;
ffffffffc0203e72:	0a043023          	sd	zero,160(s0)
        proc->pgdir = 0;
ffffffffc0203e76:	0a043423          	sd	zero,168(s0)
        proc->flags = 0;
ffffffffc0203e7a:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203e7e:	4641                	li	a2,16
ffffffffc0203e80:	4581                	li	a1,0
ffffffffc0203e82:	18d010ef          	jal	ffffffffc020580e <memset>
        proc->wait_state = 0;
ffffffffc0203e86:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc0203e8a:	10043023          	sd	zero,256(s0)
ffffffffc0203e8e:	0e043c23          	sd	zero,248(s0)
ffffffffc0203e92:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc0203e96:	60a2                	ld	ra,8(sp)
ffffffffc0203e98:	8522                	mv	a0,s0
ffffffffc0203e9a:	6402                	ld	s0,0(sp)
ffffffffc0203e9c:	0141                	addi	sp,sp,16
ffffffffc0203e9e:	8082                	ret

ffffffffc0203ea0 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203ea0:	00097797          	auipc	a5,0x97
ffffffffc0203ea4:	7e07b783          	ld	a5,2016(a5) # ffffffffc029b680 <current>
ffffffffc0203ea8:	73c8                	ld	a0,160(a5)
ffffffffc0203eaa:	814fd06f          	j	ffffffffc0200ebe <forkrets>

ffffffffc0203eae <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203eae:	00097797          	auipc	a5,0x97
ffffffffc0203eb2:	7d27b783          	ld	a5,2002(a5) # ffffffffc029b680 <current>
{
ffffffffc0203eb6:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203eb8:	00003617          	auipc	a2,0x3
ffffffffc0203ebc:	0e060613          	addi	a2,a2,224 # ffffffffc0206f98 <etext+0x1760>
ffffffffc0203ec0:	43cc                	lw	a1,4(a5)
ffffffffc0203ec2:	00003517          	auipc	a0,0x3
ffffffffc0203ec6:	0e650513          	addi	a0,a0,230 # ffffffffc0206fa8 <etext+0x1770>
{
ffffffffc0203eca:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203ecc:	ac8fc0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0203ed0:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0203ed4:	a0078793          	addi	a5,a5,-1536 # 98d0 <_binary_obj___user_forktest_out_size>
ffffffffc0203ed8:	e43e                	sd	a5,8(sp)
kernel_execve(const char *name, unsigned char *binary, size_t size)
ffffffffc0203eda:	00003517          	auipc	a0,0x3
ffffffffc0203ede:	0be50513          	addi	a0,a0,190 # ffffffffc0206f98 <etext+0x1760>
ffffffffc0203ee2:	0003f797          	auipc	a5,0x3f
ffffffffc0203ee6:	7ae78793          	addi	a5,a5,1966 # ffffffffc0243690 <_binary_obj___user_forktest_out_start>
ffffffffc0203eea:	f03e                	sd	a5,32(sp)
ffffffffc0203eec:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203eee:	e802                	sd	zero,16(sp)
ffffffffc0203ef0:	06b010ef          	jal	ffffffffc020575a <strlen>
ffffffffc0203ef4:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203ef6:	4511                	li	a0,4
ffffffffc0203ef8:	55a2                	lw	a1,40(sp)
ffffffffc0203efa:	4662                	lw	a2,24(sp)
ffffffffc0203efc:	5682                	lw	a3,32(sp)
ffffffffc0203efe:	4722                	lw	a4,8(sp)
ffffffffc0203f00:	48a9                	li	a7,10
ffffffffc0203f02:	9002                	ebreak
ffffffffc0203f04:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203f06:	65c2                	ld	a1,16(sp)
ffffffffc0203f08:	00003517          	auipc	a0,0x3
ffffffffc0203f0c:	0c850513          	addi	a0,a0,200 # ffffffffc0206fd0 <etext+0x1798>
ffffffffc0203f10:	a84fc0ef          	jal	ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0203f14:	00003617          	auipc	a2,0x3
ffffffffc0203f18:	0cc60613          	addi	a2,a2,204 # ffffffffc0206fe0 <etext+0x17a8>
ffffffffc0203f1c:	3ba00593          	li	a1,954
ffffffffc0203f20:	00003517          	auipc	a0,0x3
ffffffffc0203f24:	0e050513          	addi	a0,a0,224 # ffffffffc0207000 <etext+0x17c8>
ffffffffc0203f28:	d1efc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203f2c <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203f2c:	6d14                	ld	a3,24(a0)
{
ffffffffc0203f2e:	1141                	addi	sp,sp,-16
ffffffffc0203f30:	e406                	sd	ra,8(sp)
ffffffffc0203f32:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f36:	02f6ee63          	bltu	a3,a5,ffffffffc0203f72 <put_pgdir+0x46>
ffffffffc0203f3a:	00097717          	auipc	a4,0x97
ffffffffc0203f3e:	72673703          	ld	a4,1830(a4) # ffffffffc029b660 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203f42:	00097797          	auipc	a5,0x97
ffffffffc0203f46:	7267b783          	ld	a5,1830(a5) # ffffffffc029b668 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203f4a:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203f4c:	82b1                	srli	a3,a3,0xc
ffffffffc0203f4e:	02f6fe63          	bgeu	a3,a5,ffffffffc0203f8a <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f52:	00004797          	auipc	a5,0x4
ffffffffc0203f56:	a567b783          	ld	a5,-1450(a5) # ffffffffc02079a8 <nbase>
ffffffffc0203f5a:	00097517          	auipc	a0,0x97
ffffffffc0203f5e:	71653503          	ld	a0,1814(a0) # ffffffffc029b670 <pages>
}
ffffffffc0203f62:	60a2                	ld	ra,8(sp)
ffffffffc0203f64:	8e9d                	sub	a3,a3,a5
ffffffffc0203f66:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203f68:	4585                	li	a1,1
ffffffffc0203f6a:	9536                	add	a0,a0,a3
}
ffffffffc0203f6c:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203f6e:	f67fd06f          	j	ffffffffc0201ed4 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203f72:	00002617          	auipc	a2,0x2
ffffffffc0203f76:	6fe60613          	addi	a2,a2,1790 # ffffffffc0206670 <etext+0xe38>
ffffffffc0203f7a:	07700593          	li	a1,119
ffffffffc0203f7e:	00002517          	auipc	a0,0x2
ffffffffc0203f82:	67250513          	addi	a0,a0,1650 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc0203f86:	cc0fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f8a:	00002617          	auipc	a2,0x2
ffffffffc0203f8e:	70e60613          	addi	a2,a2,1806 # ffffffffc0206698 <etext+0xe60>
ffffffffc0203f92:	06900593          	li	a1,105
ffffffffc0203f96:	00002517          	auipc	a0,0x2
ffffffffc0203f9a:	65a50513          	addi	a0,a0,1626 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc0203f9e:	ca8fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203fa2 <proc_run>:
    if (proc != current)
ffffffffc0203fa2:	00097697          	auipc	a3,0x97
ffffffffc0203fa6:	6de6b683          	ld	a3,1758(a3) # ffffffffc029b680 <current>
ffffffffc0203faa:	04a68463          	beq	a3,a0,ffffffffc0203ff2 <proc_run+0x50>
{
ffffffffc0203fae:	1101                	addi	sp,sp,-32
ffffffffc0203fb0:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fb2:	100027f3          	csrr	a5,sstatus
ffffffffc0203fb6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203fb8:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fba:	ef8d                	bnez	a5,ffffffffc0203ff4 <proc_run+0x52>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203fbc:	755c                	ld	a5,168(a0)
ffffffffc0203fbe:	577d                	li	a4,-1
ffffffffc0203fc0:	177e                	slli	a4,a4,0x3f
ffffffffc0203fc2:	83b1                	srli	a5,a5,0xc
ffffffffc0203fc4:	e032                	sd	a2,0(sp)
            current = proc;
ffffffffc0203fc6:	00097597          	auipc	a1,0x97
ffffffffc0203fca:	6aa5bd23          	sd	a0,1722(a1) # ffffffffc029b680 <current>
ffffffffc0203fce:	8fd9                	or	a5,a5,a4
ffffffffc0203fd0:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0203fd4:	03050593          	addi	a1,a0,48
ffffffffc0203fd8:	03068513          	addi	a0,a3,48
ffffffffc0203fdc:	136010ef          	jal	ffffffffc0205112 <switch_to>
    if (flag)
ffffffffc0203fe0:	6602                	ld	a2,0(sp)
ffffffffc0203fe2:	e601                	bnez	a2,ffffffffc0203fea <proc_run+0x48>
}
ffffffffc0203fe4:	60e2                	ld	ra,24(sp)
ffffffffc0203fe6:	6105                	addi	sp,sp,32
ffffffffc0203fe8:	8082                	ret
ffffffffc0203fea:	60e2                	ld	ra,24(sp)
ffffffffc0203fec:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203fee:	911fc06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc0203ff2:	8082                	ret
ffffffffc0203ff4:	e42a                	sd	a0,8(sp)
ffffffffc0203ff6:	e036                	sd	a3,0(sp)
        intr_disable();
ffffffffc0203ff8:	90dfc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0203ffc:	6522                	ld	a0,8(sp)
ffffffffc0203ffe:	6682                	ld	a3,0(sp)
ffffffffc0204000:	4605                	li	a2,1
ffffffffc0204002:	bf6d                	j	ffffffffc0203fbc <proc_run+0x1a>

ffffffffc0204004 <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc0204004:	00097717          	auipc	a4,0x97
ffffffffc0204008:	67472703          	lw	a4,1652(a4) # ffffffffc029b678 <nr_process>
ffffffffc020400c:	6785                	lui	a5,0x1
ffffffffc020400e:	38f75363          	bge	a4,a5,ffffffffc0204394 <do_fork+0x390>
{
ffffffffc0204012:	711d                	addi	sp,sp,-96
ffffffffc0204014:	e8a2                	sd	s0,80(sp)
ffffffffc0204016:	e4a6                	sd	s1,72(sp)
ffffffffc0204018:	e0ca                	sd	s2,64(sp)
ffffffffc020401a:	e06a                	sd	s10,0(sp)
ffffffffc020401c:	ec86                	sd	ra,88(sp)
ffffffffc020401e:	892e                	mv	s2,a1
ffffffffc0204020:	84b2                	mv	s1,a2
ffffffffc0204022:	8d2a                	mv	s10,a0
    if ((proc = alloc_proc()) == NULL) {
ffffffffc0204024:	e11ff0ef          	jal	ffffffffc0203e34 <alloc_proc>
ffffffffc0204028:	842a                	mv	s0,a0
ffffffffc020402a:	30050063          	beqz	a0,ffffffffc020432a <do_fork+0x326>
    proc->parent = current;
ffffffffc020402e:	f05a                	sd	s6,32(sp)
ffffffffc0204030:	00097b17          	auipc	s6,0x97
ffffffffc0204034:	650b0b13          	addi	s6,s6,1616 # ffffffffc029b680 <current>
ffffffffc0204038:	000b3783          	ld	a5,0(s6)
    assert(current->wait_state == 0);
ffffffffc020403c:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_softint_out_size-0x7ac4>
    proc->parent = current;
ffffffffc0204040:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc0204042:	36071763          	bnez	a4,ffffffffc02043b0 <do_fork+0x3ac>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204046:	4509                	li	a0,2
ffffffffc0204048:	e53fd0ef          	jal	ffffffffc0201e9a <alloc_pages>
    if (page != NULL)
ffffffffc020404c:	2c050b63          	beqz	a0,ffffffffc0204322 <do_fork+0x31e>
ffffffffc0204050:	fc4e                	sd	s3,56(sp)
    return page - pages + nbase;
ffffffffc0204052:	00097997          	auipc	s3,0x97
ffffffffc0204056:	61e98993          	addi	s3,s3,1566 # ffffffffc029b670 <pages>
ffffffffc020405a:	0009b783          	ld	a5,0(s3)
ffffffffc020405e:	f852                	sd	s4,48(sp)
ffffffffc0204060:	00004a17          	auipc	s4,0x4
ffffffffc0204064:	948a0a13          	addi	s4,s4,-1720 # ffffffffc02079a8 <nbase>
ffffffffc0204068:	e466                	sd	s9,8(sp)
ffffffffc020406a:	000a3c83          	ld	s9,0(s4)
ffffffffc020406e:	40f506b3          	sub	a3,a0,a5
ffffffffc0204072:	f456                	sd	s5,40(sp)
    return KADDR(page2pa(page));
ffffffffc0204074:	00097a97          	auipc	s5,0x97
ffffffffc0204078:	5f4a8a93          	addi	s5,s5,1524 # ffffffffc029b668 <npage>
ffffffffc020407c:	e862                	sd	s8,16(sp)
    return page - pages + nbase;
ffffffffc020407e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204080:	5c7d                	li	s8,-1
ffffffffc0204082:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc0204086:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc0204088:	00cc5c13          	srli	s8,s8,0xc
ffffffffc020408c:	0186f733          	and	a4,a3,s8
ffffffffc0204090:	ec5e                	sd	s7,24(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc0204092:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204094:	36f77163          	bgeu	a4,a5,ffffffffc02043f6 <do_fork+0x3f2>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc0204098:	000b3703          	ld	a4,0(s6)
ffffffffc020409c:	00097b17          	auipc	s6,0x97
ffffffffc02040a0:	5c4b0b13          	addi	s6,s6,1476 # ffffffffc029b660 <va_pa_offset>
ffffffffc02040a4:	000b3783          	ld	a5,0(s6)
ffffffffc02040a8:	02873b83          	ld	s7,40(a4)
ffffffffc02040ac:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02040ae:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc02040b0:	2c0b8c63          	beqz	s7,ffffffffc0204388 <do_fork+0x384>
    if (clone_flags & CLONE_VM)
ffffffffc02040b4:	100d7793          	andi	a5,s10,256
ffffffffc02040b8:	18078b63          	beqz	a5,ffffffffc020424e <do_fork+0x24a>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02040bc:	030ba703          	lw	a4,48(s7)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040c0:	018bb783          	ld	a5,24(s7)
ffffffffc02040c4:	c02006b7          	lui	a3,0xc0200
ffffffffc02040c8:	2705                	addiw	a4,a4,1
ffffffffc02040ca:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc02040ce:	03743423          	sd	s7,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040d2:	30d7e563          	bltu	a5,a3,ffffffffc02043dc <do_fork+0x3d8>
ffffffffc02040d6:	000b3703          	ld	a4,0(s6)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040da:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040dc:	8f99                	sub	a5,a5,a4
ffffffffc02040de:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040e0:	6789                	lui	a5,0x2
ffffffffc02040e2:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x6cd0>
ffffffffc02040e6:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02040e8:	8626                	mv	a2,s1
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040ea:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc02040ec:	87b6                	mv	a5,a3
ffffffffc02040ee:	12048713          	addi	a4,s1,288
ffffffffc02040f2:	6a0c                	ld	a1,16(a2)
ffffffffc02040f4:	00063803          	ld	a6,0(a2)
ffffffffc02040f8:	6608                	ld	a0,8(a2)
ffffffffc02040fa:	eb8c                	sd	a1,16(a5)
ffffffffc02040fc:	0107b023          	sd	a6,0(a5)
ffffffffc0204100:	e788                	sd	a0,8(a5)
ffffffffc0204102:	6e0c                	ld	a1,24(a2)
ffffffffc0204104:	02060613          	addi	a2,a2,32
ffffffffc0204108:	02078793          	addi	a5,a5,32
ffffffffc020410c:	feb7bc23          	sd	a1,-8(a5)
ffffffffc0204110:	fee611e3          	bne	a2,a4,ffffffffc02040f2 <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc0204114:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204118:	20090b63          	beqz	s2,ffffffffc020432e <do_fork+0x32a>
ffffffffc020411c:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204120:	00000797          	auipc	a5,0x0
ffffffffc0204124:	d8078793          	addi	a5,a5,-640 # ffffffffc0203ea0 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204128:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020412a:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020412c:	100027f3          	csrr	a5,sstatus
ffffffffc0204130:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204132:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204134:	20079c63          	bnez	a5,ffffffffc020434c <do_fork+0x348>
    if (++last_pid >= MAX_PID)
ffffffffc0204138:	00093517          	auipc	a0,0x93
ffffffffc020413c:	0b452503          	lw	a0,180(a0) # ffffffffc02971ec <last_pid.1>
ffffffffc0204140:	6789                	lui	a5,0x2
ffffffffc0204142:	2505                	addiw	a0,a0,1
ffffffffc0204144:	00093717          	auipc	a4,0x93
ffffffffc0204148:	0aa72423          	sw	a0,168(a4) # ffffffffc02971ec <last_pid.1>
ffffffffc020414c:	20f55f63          	bge	a0,a5,ffffffffc020436a <do_fork+0x366>
    if (last_pid >= next_safe)
ffffffffc0204150:	00093797          	auipc	a5,0x93
ffffffffc0204154:	0987a783          	lw	a5,152(a5) # ffffffffc02971e8 <next_safe.0>
ffffffffc0204158:	00097497          	auipc	s1,0x97
ffffffffc020415c:	4b048493          	addi	s1,s1,1200 # ffffffffc029b608 <proc_list>
ffffffffc0204160:	06f54563          	blt	a0,a5,ffffffffc02041ca <do_fork+0x1c6>
ffffffffc0204164:	00097497          	auipc	s1,0x97
ffffffffc0204168:	4a448493          	addi	s1,s1,1188 # ffffffffc029b608 <proc_list>
ffffffffc020416c:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc0204170:	6789                	lui	a5,0x2
ffffffffc0204172:	00093717          	auipc	a4,0x93
ffffffffc0204176:	06f72b23          	sw	a5,118(a4) # ffffffffc02971e8 <next_safe.0>
ffffffffc020417a:	86aa                	mv	a3,a0
ffffffffc020417c:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc020417e:	04988063          	beq	a7,s1,ffffffffc02041be <do_fork+0x1ba>
ffffffffc0204182:	882e                	mv	a6,a1
ffffffffc0204184:	87c6                	mv	a5,a7
ffffffffc0204186:	6609                	lui	a2,0x2
ffffffffc0204188:	a811                	j	ffffffffc020419c <do_fork+0x198>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020418a:	00e6d663          	bge	a3,a4,ffffffffc0204196 <do_fork+0x192>
ffffffffc020418e:	00c75463          	bge	a4,a2,ffffffffc0204196 <do_fork+0x192>
                next_safe = proc->pid;
ffffffffc0204192:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204194:	4805                	li	a6,1
ffffffffc0204196:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204198:	00978d63          	beq	a5,s1,ffffffffc02041b2 <do_fork+0x1ae>
            if (proc->pid == last_pid)
ffffffffc020419c:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x6c74>
ffffffffc02041a0:	fed715e3          	bne	a4,a3,ffffffffc020418a <do_fork+0x186>
                if (++last_pid >= next_safe)
ffffffffc02041a4:	2685                	addiw	a3,a3,1
ffffffffc02041a6:	1cc6db63          	bge	a3,a2,ffffffffc020437c <do_fork+0x378>
ffffffffc02041aa:	679c                	ld	a5,8(a5)
ffffffffc02041ac:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02041ae:	fe9797e3          	bne	a5,s1,ffffffffc020419c <do_fork+0x198>
ffffffffc02041b2:	00080663          	beqz	a6,ffffffffc02041be <do_fork+0x1ba>
ffffffffc02041b6:	00093797          	auipc	a5,0x93
ffffffffc02041ba:	02c7a923          	sw	a2,50(a5) # ffffffffc02971e8 <next_safe.0>
ffffffffc02041be:	c591                	beqz	a1,ffffffffc02041ca <do_fork+0x1c6>
ffffffffc02041c0:	00093797          	auipc	a5,0x93
ffffffffc02041c4:	02d7a623          	sw	a3,44(a5) # ffffffffc02971ec <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041c8:	8536                	mv	a0,a3
        proc->pid = get_pid();
ffffffffc02041ca:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02041cc:	45a9                	li	a1,10
ffffffffc02041ce:	1aa010ef          	jal	ffffffffc0205378 <hash32>
ffffffffc02041d2:	02051793          	slli	a5,a0,0x20
ffffffffc02041d6:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02041da:	00093797          	auipc	a5,0x93
ffffffffc02041de:	42e78793          	addi	a5,a5,1070 # ffffffffc0297608 <hash_list>
ffffffffc02041e2:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02041e4:	6518                	ld	a4,8(a0)
ffffffffc02041e6:	0d840793          	addi	a5,s0,216
ffffffffc02041ea:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc02041ec:	e31c                	sd	a5,0(a4)
ffffffffc02041ee:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc02041f0:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02041f2:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02041f6:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc02041f8:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc02041fa:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc02041fc:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204200:	7b74                	ld	a3,240(a4)
ffffffffc0204202:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc0204204:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc0204206:	e464                	sd	s1,200(s0)
ffffffffc0204208:	10d43023          	sd	a3,256(s0)
ffffffffc020420c:	c299                	beqz	a3,ffffffffc0204212 <do_fork+0x20e>
        proc->optr->yptr = proc;
ffffffffc020420e:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc0204210:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc0204212:	00097797          	auipc	a5,0x97
ffffffffc0204216:	4667a783          	lw	a5,1126(a5) # ffffffffc029b678 <nr_process>
    proc->parent->cptr = proc;
ffffffffc020421a:	fb60                	sd	s0,240(a4)
    nr_process++;
ffffffffc020421c:	2785                	addiw	a5,a5,1
ffffffffc020421e:	00097717          	auipc	a4,0x97
ffffffffc0204222:	44f72d23          	sw	a5,1114(a4) # ffffffffc029b678 <nr_process>
    if (flag)
ffffffffc0204226:	14091863          	bnez	s2,ffffffffc0204376 <do_fork+0x372>
    wakeup_proc(proc);
ffffffffc020422a:	8522                	mv	a0,s0
ffffffffc020422c:	751000ef          	jal	ffffffffc020517c <wakeup_proc>
    ret = proc->pid;
ffffffffc0204230:	4048                	lw	a0,4(s0)
ffffffffc0204232:	79e2                	ld	s3,56(sp)
ffffffffc0204234:	7a42                	ld	s4,48(sp)
ffffffffc0204236:	7aa2                	ld	s5,40(sp)
ffffffffc0204238:	7b02                	ld	s6,32(sp)
ffffffffc020423a:	6be2                	ld	s7,24(sp)
ffffffffc020423c:	6c42                	ld	s8,16(sp)
ffffffffc020423e:	6ca2                	ld	s9,8(sp)
}
ffffffffc0204240:	60e6                	ld	ra,88(sp)
ffffffffc0204242:	6446                	ld	s0,80(sp)
ffffffffc0204244:	64a6                	ld	s1,72(sp)
ffffffffc0204246:	6906                	ld	s2,64(sp)
ffffffffc0204248:	6d02                	ld	s10,0(sp)
ffffffffc020424a:	6125                	addi	sp,sp,96
ffffffffc020424c:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc020424e:	caeff0ef          	jal	ffffffffc02036fc <mm_create>
ffffffffc0204252:	8d2a                	mv	s10,a0
ffffffffc0204254:	c949                	beqz	a0,ffffffffc02042e6 <do_fork+0x2e2>
    if ((page = alloc_page()) == NULL)
ffffffffc0204256:	4505                	li	a0,1
ffffffffc0204258:	c43fd0ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc020425c:	c151                	beqz	a0,ffffffffc02042e0 <do_fork+0x2dc>
    return page - pages + nbase;
ffffffffc020425e:	0009b703          	ld	a4,0(s3)
    return KADDR(page2pa(page));
ffffffffc0204262:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc0204266:	40e506b3          	sub	a3,a0,a4
ffffffffc020426a:	8699                	srai	a3,a3,0x6
ffffffffc020426c:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc020426e:	0186fc33          	and	s8,a3,s8
    return page2ppn(page) << PGSHIFT;
ffffffffc0204272:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204274:	1afc7963          	bgeu	s8,a5,ffffffffc0204426 <do_fork+0x422>
ffffffffc0204278:	000b3783          	ld	a5,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc020427c:	00097597          	auipc	a1,0x97
ffffffffc0204280:	3dc5b583          	ld	a1,988(a1) # ffffffffc029b658 <boot_pgdir_va>
ffffffffc0204284:	6605                	lui	a2,0x1
ffffffffc0204286:	00f68c33          	add	s8,a3,a5
ffffffffc020428a:	8562                	mv	a0,s8
ffffffffc020428c:	594010ef          	jal	ffffffffc0205820 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204290:	038b8c93          	addi	s9,s7,56
    mm->pgdir = pgdir;
ffffffffc0204294:	018d3c23          	sd	s8,24(s10) # fffffffffff80018 <end+0x3fce4980>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0204298:	4c05                	li	s8,1
ffffffffc020429a:	418cb7af          	amoor.d	a5,s8,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc020429e:	03f79713          	slli	a4,a5,0x3f
ffffffffc02042a2:	03f75793          	srli	a5,a4,0x3f
ffffffffc02042a6:	cb91                	beqz	a5,ffffffffc02042ba <do_fork+0x2b6>
    {
        schedule();
ffffffffc02042a8:	769000ef          	jal	ffffffffc0205210 <schedule>
ffffffffc02042ac:	418cb7af          	amoor.d	a5,s8,(s9)
    while (!try_lock(lock))
ffffffffc02042b0:	03f79713          	slli	a4,a5,0x3f
ffffffffc02042b4:	03f75793          	srli	a5,a4,0x3f
ffffffffc02042b8:	fbe5                	bnez	a5,ffffffffc02042a8 <do_fork+0x2a4>
        ret = dup_mmap(mm, oldmm);
ffffffffc02042ba:	85de                	mv	a1,s7
ffffffffc02042bc:	856a                	mv	a0,s10
ffffffffc02042be:	e9aff0ef          	jal	ffffffffc0203958 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02042c2:	57f9                	li	a5,-2
ffffffffc02042c4:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc02042c8:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc02042ca:	16078a63          	beqz	a5,ffffffffc020443e <do_fork+0x43a>
    if ((mm = mm_create()) == NULL)
ffffffffc02042ce:	8bea                	mv	s7,s10
    if (ret != 0)
ffffffffc02042d0:	de0506e3          	beqz	a0,ffffffffc02040bc <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc02042d4:	856a                	mv	a0,s10
ffffffffc02042d6:	f1aff0ef          	jal	ffffffffc02039f0 <exit_mmap>
    put_pgdir(mm);
ffffffffc02042da:	856a                	mv	a0,s10
ffffffffc02042dc:	c51ff0ef          	jal	ffffffffc0203f2c <put_pgdir>
    mm_destroy(mm);
ffffffffc02042e0:	856a                	mv	a0,s10
ffffffffc02042e2:	d58ff0ef          	jal	ffffffffc020383a <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02042e6:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02042e8:	c02007b7          	lui	a5,0xc0200
ffffffffc02042ec:	12f6e163          	bltu	a3,a5,ffffffffc020440e <do_fork+0x40a>
ffffffffc02042f0:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage)
ffffffffc02042f4:	000ab703          	ld	a4,0(s5)
    return pa2page(PADDR(kva));
ffffffffc02042f8:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02042fc:	83b1                	srli	a5,a5,0xc
ffffffffc02042fe:	08e7fd63          	bgeu	a5,a4,ffffffffc0204398 <do_fork+0x394>
    return &pages[PPN(pa) - nbase];
ffffffffc0204302:	000a3703          	ld	a4,0(s4)
ffffffffc0204306:	0009b503          	ld	a0,0(s3)
ffffffffc020430a:	4589                	li	a1,2
ffffffffc020430c:	8f99                	sub	a5,a5,a4
ffffffffc020430e:	079a                	slli	a5,a5,0x6
ffffffffc0204310:	953e                	add	a0,a0,a5
ffffffffc0204312:	bc3fd0ef          	jal	ffffffffc0201ed4 <free_pages>
}
ffffffffc0204316:	79e2                	ld	s3,56(sp)
ffffffffc0204318:	7a42                	ld	s4,48(sp)
ffffffffc020431a:	7aa2                	ld	s5,40(sp)
ffffffffc020431c:	6be2                	ld	s7,24(sp)
ffffffffc020431e:	6c42                	ld	s8,16(sp)
ffffffffc0204320:	6ca2                	ld	s9,8(sp)
    kfree(proc);
ffffffffc0204322:	8522                	mv	a0,s0
ffffffffc0204324:	a5bfd0ef          	jal	ffffffffc0201d7e <kfree>
ffffffffc0204328:	7b02                	ld	s6,32(sp)
    ret = -E_NO_MEM;
ffffffffc020432a:	5571                	li	a0,-4
    return ret;
ffffffffc020432c:	bf11                	j	ffffffffc0204240 <do_fork+0x23c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020432e:	8936                	mv	s2,a3
ffffffffc0204330:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204334:	00000797          	auipc	a5,0x0
ffffffffc0204338:	b6c78793          	addi	a5,a5,-1172 # ffffffffc0203ea0 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020433c:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020433e:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204340:	100027f3          	csrr	a5,sstatus
ffffffffc0204344:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204346:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204348:	de0788e3          	beqz	a5,ffffffffc0204138 <do_fork+0x134>
        intr_disable();
ffffffffc020434c:	db8fc0ef          	jal	ffffffffc0200904 <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc0204350:	00093517          	auipc	a0,0x93
ffffffffc0204354:	e9c52503          	lw	a0,-356(a0) # ffffffffc02971ec <last_pid.1>
ffffffffc0204358:	6789                	lui	a5,0x2
        return 1;
ffffffffc020435a:	4905                	li	s2,1
ffffffffc020435c:	2505                	addiw	a0,a0,1
ffffffffc020435e:	00093717          	auipc	a4,0x93
ffffffffc0204362:	e8a72723          	sw	a0,-370(a4) # ffffffffc02971ec <last_pid.1>
ffffffffc0204366:	def545e3          	blt	a0,a5,ffffffffc0204150 <do_fork+0x14c>
        last_pid = 1;
ffffffffc020436a:	4505                	li	a0,1
ffffffffc020436c:	00093797          	auipc	a5,0x93
ffffffffc0204370:	e8a7a023          	sw	a0,-384(a5) # ffffffffc02971ec <last_pid.1>
        goto inside;
ffffffffc0204374:	bbc5                	j	ffffffffc0204164 <do_fork+0x160>
        intr_enable();
ffffffffc0204376:	d88fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020437a:	bd45                	j	ffffffffc020422a <do_fork+0x226>
                    if (last_pid >= MAX_PID)
ffffffffc020437c:	6789                	lui	a5,0x2
ffffffffc020437e:	00f6c363          	blt	a3,a5,ffffffffc0204384 <do_fork+0x380>
                        last_pid = 1;
ffffffffc0204382:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204384:	4585                	li	a1,1
ffffffffc0204386:	bbe5                	j	ffffffffc020417e <do_fork+0x17a>
        proc->pgdir = boot_pgdir_pa;
ffffffffc0204388:	00097797          	auipc	a5,0x97
ffffffffc020438c:	2c87b783          	ld	a5,712(a5) # ffffffffc029b650 <boot_pgdir_pa>
ffffffffc0204390:	f45c                	sd	a5,168(s0)
        return 0;
ffffffffc0204392:	b3b9                	j	ffffffffc02040e0 <do_fork+0xdc>
    int ret = -E_NO_FREE_PROC;
ffffffffc0204394:	556d                	li	a0,-5
}
ffffffffc0204396:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0204398:	00002617          	auipc	a2,0x2
ffffffffc020439c:	30060613          	addi	a2,a2,768 # ffffffffc0206698 <etext+0xe60>
ffffffffc02043a0:	06900593          	li	a1,105
ffffffffc02043a4:	00002517          	auipc	a0,0x2
ffffffffc02043a8:	24c50513          	addi	a0,a0,588 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc02043ac:	89afc0ef          	jal	ffffffffc0200446 <__panic>
    assert(current->wait_state == 0);
ffffffffc02043b0:	00003697          	auipc	a3,0x3
ffffffffc02043b4:	c6868693          	addi	a3,a3,-920 # ffffffffc0207018 <etext+0x17e0>
ffffffffc02043b8:	00002617          	auipc	a2,0x2
ffffffffc02043bc:	e6060613          	addi	a2,a2,-416 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02043c0:	1dc00593          	li	a1,476
ffffffffc02043c4:	00003517          	auipc	a0,0x3
ffffffffc02043c8:	c3c50513          	addi	a0,a0,-964 # ffffffffc0207000 <etext+0x17c8>
ffffffffc02043cc:	fc4e                	sd	s3,56(sp)
ffffffffc02043ce:	f852                	sd	s4,48(sp)
ffffffffc02043d0:	f456                	sd	s5,40(sp)
ffffffffc02043d2:	ec5e                	sd	s7,24(sp)
ffffffffc02043d4:	e862                	sd	s8,16(sp)
ffffffffc02043d6:	e466                	sd	s9,8(sp)
ffffffffc02043d8:	86efc0ef          	jal	ffffffffc0200446 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02043dc:	86be                	mv	a3,a5
ffffffffc02043de:	00002617          	auipc	a2,0x2
ffffffffc02043e2:	29260613          	addi	a2,a2,658 # ffffffffc0206670 <etext+0xe38>
ffffffffc02043e6:	18a00593          	li	a1,394
ffffffffc02043ea:	00003517          	auipc	a0,0x3
ffffffffc02043ee:	c1650513          	addi	a0,a0,-1002 # ffffffffc0207000 <etext+0x17c8>
ffffffffc02043f2:	854fc0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc02043f6:	00002617          	auipc	a2,0x2
ffffffffc02043fa:	1d260613          	addi	a2,a2,466 # ffffffffc02065c8 <etext+0xd90>
ffffffffc02043fe:	07100593          	li	a1,113
ffffffffc0204402:	00002517          	auipc	a0,0x2
ffffffffc0204406:	1ee50513          	addi	a0,a0,494 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc020440a:	83cfc0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc020440e:	00002617          	auipc	a2,0x2
ffffffffc0204412:	26260613          	addi	a2,a2,610 # ffffffffc0206670 <etext+0xe38>
ffffffffc0204416:	07700593          	li	a1,119
ffffffffc020441a:	00002517          	auipc	a0,0x2
ffffffffc020441e:	1d650513          	addi	a0,a0,470 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc0204422:	824fc0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204426:	00002617          	auipc	a2,0x2
ffffffffc020442a:	1a260613          	addi	a2,a2,418 # ffffffffc02065c8 <etext+0xd90>
ffffffffc020442e:	07100593          	li	a1,113
ffffffffc0204432:	00002517          	auipc	a0,0x2
ffffffffc0204436:	1be50513          	addi	a0,a0,446 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc020443a:	80cfc0ef          	jal	ffffffffc0200446 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc020443e:	00003617          	auipc	a2,0x3
ffffffffc0204442:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0207038 <etext+0x1800>
ffffffffc0204446:	03f00593          	li	a1,63
ffffffffc020444a:	00003517          	auipc	a0,0x3
ffffffffc020444e:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0207048 <etext+0x1810>
ffffffffc0204452:	ff5fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204456 <kernel_thread>:
{
ffffffffc0204456:	7129                	addi	sp,sp,-320
ffffffffc0204458:	fa22                	sd	s0,304(sp)
ffffffffc020445a:	f626                	sd	s1,296(sp)
ffffffffc020445c:	f24a                	sd	s2,288(sp)
ffffffffc020445e:	842a                	mv	s0,a0
ffffffffc0204460:	84ae                	mv	s1,a1
ffffffffc0204462:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204464:	850a                	mv	a0,sp
ffffffffc0204466:	12000613          	li	a2,288
ffffffffc020446a:	4581                	li	a1,0
{
ffffffffc020446c:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020446e:	3a0010ef          	jal	ffffffffc020580e <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0204472:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204474:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204476:	100027f3          	csrr	a5,sstatus
ffffffffc020447a:	edd7f793          	andi	a5,a5,-291
ffffffffc020447e:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204482:	860a                	mv	a2,sp
ffffffffc0204484:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204488:	00000717          	auipc	a4,0x0
ffffffffc020448c:	9a470713          	addi	a4,a4,-1628 # ffffffffc0203e2c <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204490:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204492:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204494:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204496:	b6fff0ef          	jal	ffffffffc0204004 <do_fork>
}
ffffffffc020449a:	70f2                	ld	ra,312(sp)
ffffffffc020449c:	7452                	ld	s0,304(sp)
ffffffffc020449e:	74b2                	ld	s1,296(sp)
ffffffffc02044a0:	7912                	ld	s2,288(sp)
ffffffffc02044a2:	6131                	addi	sp,sp,320
ffffffffc02044a4:	8082                	ret

ffffffffc02044a6 <do_exit>:
{
ffffffffc02044a6:	7179                	addi	sp,sp,-48
ffffffffc02044a8:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02044aa:	00097417          	auipc	s0,0x97
ffffffffc02044ae:	1d640413          	addi	s0,s0,470 # ffffffffc029b680 <current>
ffffffffc02044b2:	601c                	ld	a5,0(s0)
ffffffffc02044b4:	00097717          	auipc	a4,0x97
ffffffffc02044b8:	1dc73703          	ld	a4,476(a4) # ffffffffc029b690 <idleproc>
{
ffffffffc02044bc:	f406                	sd	ra,40(sp)
ffffffffc02044be:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc02044c0:	0ce78b63          	beq	a5,a4,ffffffffc0204596 <do_exit+0xf0>
    if (current == initproc)
ffffffffc02044c4:	00097497          	auipc	s1,0x97
ffffffffc02044c8:	1c448493          	addi	s1,s1,452 # ffffffffc029b688 <initproc>
ffffffffc02044cc:	6098                	ld	a4,0(s1)
ffffffffc02044ce:	e84a                	sd	s2,16(sp)
ffffffffc02044d0:	0ee78a63          	beq	a5,a4,ffffffffc02045c4 <do_exit+0x11e>
ffffffffc02044d4:	892a                	mv	s2,a0
    struct mm_struct *mm = current->mm;
ffffffffc02044d6:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc02044d8:	c115                	beqz	a0,ffffffffc02044fc <do_exit+0x56>
ffffffffc02044da:	00097797          	auipc	a5,0x97
ffffffffc02044de:	1767b783          	ld	a5,374(a5) # ffffffffc029b650 <boot_pgdir_pa>
ffffffffc02044e2:	577d                	li	a4,-1
ffffffffc02044e4:	177e                	slli	a4,a4,0x3f
ffffffffc02044e6:	83b1                	srli	a5,a5,0xc
ffffffffc02044e8:	8fd9                	or	a5,a5,a4
ffffffffc02044ea:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02044ee:	591c                	lw	a5,48(a0)
ffffffffc02044f0:	37fd                	addiw	a5,a5,-1
ffffffffc02044f2:	d91c                	sw	a5,48(a0)
        if (mm_count_dec(mm) == 0)
ffffffffc02044f4:	cfd5                	beqz	a5,ffffffffc02045b0 <do_exit+0x10a>
        current->mm = NULL;
ffffffffc02044f6:	601c                	ld	a5,0(s0)
ffffffffc02044f8:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02044fc:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc02044fe:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0204502:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204504:	100027f3          	csrr	a5,sstatus
ffffffffc0204508:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020450a:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020450c:	ebe1                	bnez	a5,ffffffffc02045dc <do_exit+0x136>
        proc = current->parent;
ffffffffc020450e:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204510:	800007b7          	lui	a5,0x80000
ffffffffc0204514:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
        proc = current->parent;
ffffffffc0204516:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204518:	0ec52703          	lw	a4,236(a0)
ffffffffc020451c:	0cf70463          	beq	a4,a5,ffffffffc02045e4 <do_exit+0x13e>
        while (current->cptr != NULL)
ffffffffc0204520:	6018                	ld	a4,0(s0)
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204522:	800005b7          	lui	a1,0x80000
ffffffffc0204526:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
        while (current->cptr != NULL)
ffffffffc0204528:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020452a:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc020452c:	e789                	bnez	a5,ffffffffc0204536 <do_exit+0x90>
ffffffffc020452e:	a83d                	j	ffffffffc020456c <do_exit+0xc6>
ffffffffc0204530:	6018                	ld	a4,0(s0)
ffffffffc0204532:	7b7c                	ld	a5,240(a4)
ffffffffc0204534:	cf85                	beqz	a5,ffffffffc020456c <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc0204536:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020453a:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc020453c:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc020453e:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204542:	7978                	ld	a4,240(a0)
ffffffffc0204544:	10e7b023          	sd	a4,256(a5)
ffffffffc0204548:	c311                	beqz	a4,ffffffffc020454c <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc020454a:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020454c:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020454e:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc0204550:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204552:	fcc71fe3          	bne	a4,a2,ffffffffc0204530 <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204556:	0ec52783          	lw	a5,236(a0)
ffffffffc020455a:	fcb79be3          	bne	a5,a1,ffffffffc0204530 <do_exit+0x8a>
                    wakeup_proc(initproc);
ffffffffc020455e:	41f000ef          	jal	ffffffffc020517c <wakeup_proc>
ffffffffc0204562:	800005b7          	lui	a1,0x80000
ffffffffc0204566:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
ffffffffc0204568:	460d                	li	a2,3
ffffffffc020456a:	b7d9                	j	ffffffffc0204530 <do_exit+0x8a>
    if (flag)
ffffffffc020456c:	02091263          	bnez	s2,ffffffffc0204590 <do_exit+0xea>
    schedule();
ffffffffc0204570:	4a1000ef          	jal	ffffffffc0205210 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204574:	601c                	ld	a5,0(s0)
ffffffffc0204576:	00003617          	auipc	a2,0x3
ffffffffc020457a:	b0a60613          	addi	a2,a2,-1270 # ffffffffc0207080 <etext+0x1848>
ffffffffc020457e:	24100593          	li	a1,577
ffffffffc0204582:	43d4                	lw	a3,4(a5)
ffffffffc0204584:	00003517          	auipc	a0,0x3
ffffffffc0204588:	a7c50513          	addi	a0,a0,-1412 # ffffffffc0207000 <etext+0x17c8>
ffffffffc020458c:	ebbfb0ef          	jal	ffffffffc0200446 <__panic>
        intr_enable();
ffffffffc0204590:	b6efc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0204594:	bff1                	j	ffffffffc0204570 <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc0204596:	00003617          	auipc	a2,0x3
ffffffffc020459a:	aca60613          	addi	a2,a2,-1334 # ffffffffc0207060 <etext+0x1828>
ffffffffc020459e:	20d00593          	li	a1,525
ffffffffc02045a2:	00003517          	auipc	a0,0x3
ffffffffc02045a6:	a5e50513          	addi	a0,a0,-1442 # ffffffffc0207000 <etext+0x17c8>
ffffffffc02045aa:	e84a                	sd	s2,16(sp)
ffffffffc02045ac:	e9bfb0ef          	jal	ffffffffc0200446 <__panic>
            exit_mmap(mm);
ffffffffc02045b0:	e42a                	sd	a0,8(sp)
ffffffffc02045b2:	c3eff0ef          	jal	ffffffffc02039f0 <exit_mmap>
            put_pgdir(mm);
ffffffffc02045b6:	6522                	ld	a0,8(sp)
ffffffffc02045b8:	975ff0ef          	jal	ffffffffc0203f2c <put_pgdir>
            mm_destroy(mm);
ffffffffc02045bc:	6522                	ld	a0,8(sp)
ffffffffc02045be:	a7cff0ef          	jal	ffffffffc020383a <mm_destroy>
ffffffffc02045c2:	bf15                	j	ffffffffc02044f6 <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc02045c4:	00003617          	auipc	a2,0x3
ffffffffc02045c8:	aac60613          	addi	a2,a2,-1364 # ffffffffc0207070 <etext+0x1838>
ffffffffc02045cc:	21100593          	li	a1,529
ffffffffc02045d0:	00003517          	auipc	a0,0x3
ffffffffc02045d4:	a3050513          	addi	a0,a0,-1488 # ffffffffc0207000 <etext+0x17c8>
ffffffffc02045d8:	e6ffb0ef          	jal	ffffffffc0200446 <__panic>
        intr_disable();
ffffffffc02045dc:	b28fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02045e0:	4905                	li	s2,1
ffffffffc02045e2:	b735                	j	ffffffffc020450e <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc02045e4:	399000ef          	jal	ffffffffc020517c <wakeup_proc>
ffffffffc02045e8:	bf25                	j	ffffffffc0204520 <do_exit+0x7a>

ffffffffc02045ea <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02045ea:	7179                	addi	sp,sp,-48
ffffffffc02045ec:	ec26                	sd	s1,24(sp)
ffffffffc02045ee:	e84a                	sd	s2,16(sp)
ffffffffc02045f0:	e44e                	sd	s3,8(sp)
ffffffffc02045f2:	f406                	sd	ra,40(sp)
ffffffffc02045f4:	f022                	sd	s0,32(sp)
ffffffffc02045f6:	84aa                	mv	s1,a0
ffffffffc02045f8:	892e                	mv	s2,a1
ffffffffc02045fa:	00097997          	auipc	s3,0x97
ffffffffc02045fe:	08698993          	addi	s3,s3,134 # ffffffffc029b680 <current>
    if (pid != 0)
ffffffffc0204602:	cd19                	beqz	a0,ffffffffc0204620 <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204604:	6789                	lui	a5,0x2
ffffffffc0204606:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bb2>
ffffffffc0204608:	fff5071b          	addiw	a4,a0,-1
ffffffffc020460c:	12e7f563          	bgeu	a5,a4,ffffffffc0204736 <do_wait.part.0+0x14c>
}
ffffffffc0204610:	70a2                	ld	ra,40(sp)
ffffffffc0204612:	7402                	ld	s0,32(sp)
ffffffffc0204614:	64e2                	ld	s1,24(sp)
ffffffffc0204616:	6942                	ld	s2,16(sp)
ffffffffc0204618:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc020461a:	5579                	li	a0,-2
}
ffffffffc020461c:	6145                	addi	sp,sp,48
ffffffffc020461e:	8082                	ret
        proc = current->cptr;
ffffffffc0204620:	0009b703          	ld	a4,0(s3)
ffffffffc0204624:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204626:	d46d                	beqz	s0,ffffffffc0204610 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204628:	468d                	li	a3,3
ffffffffc020462a:	a021                	j	ffffffffc0204632 <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc020462c:	10043403          	ld	s0,256(s0)
ffffffffc0204630:	c075                	beqz	s0,ffffffffc0204714 <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204632:	401c                	lw	a5,0(s0)
ffffffffc0204634:	fed79ce3          	bne	a5,a3,ffffffffc020462c <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc0204638:	00097797          	auipc	a5,0x97
ffffffffc020463c:	0587b783          	ld	a5,88(a5) # ffffffffc029b690 <idleproc>
ffffffffc0204640:	14878263          	beq	a5,s0,ffffffffc0204784 <do_wait.part.0+0x19a>
ffffffffc0204644:	00097797          	auipc	a5,0x97
ffffffffc0204648:	0447b783          	ld	a5,68(a5) # ffffffffc029b688 <initproc>
ffffffffc020464c:	12f40c63          	beq	s0,a5,ffffffffc0204784 <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc0204650:	00090663          	beqz	s2,ffffffffc020465c <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc0204654:	0e842783          	lw	a5,232(s0)
ffffffffc0204658:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020465c:	100027f3          	csrr	a5,sstatus
ffffffffc0204660:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204662:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204664:	10079963          	bnez	a5,ffffffffc0204776 <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204668:	6c74                	ld	a3,216(s0)
ffffffffc020466a:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc020466c:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc0204670:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204672:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204674:	6474                	ld	a3,200(s0)
ffffffffc0204676:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc0204678:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020467a:	e314                	sd	a3,0(a4)
ffffffffc020467c:	c789                	beqz	a5,ffffffffc0204686 <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc020467e:	7c78                	ld	a4,248(s0)
ffffffffc0204680:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc0204682:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc0204686:	7c78                	ld	a4,248(s0)
ffffffffc0204688:	c36d                	beqz	a4,ffffffffc020476a <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc020468a:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc020468e:	00097797          	auipc	a5,0x97
ffffffffc0204692:	fea7a783          	lw	a5,-22(a5) # ffffffffc029b678 <nr_process>
ffffffffc0204696:	37fd                	addiw	a5,a5,-1
ffffffffc0204698:	00097717          	auipc	a4,0x97
ffffffffc020469c:	fef72023          	sw	a5,-32(a4) # ffffffffc029b678 <nr_process>
    if (flag)
ffffffffc02046a0:	e271                	bnez	a2,ffffffffc0204764 <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02046a2:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02046a4:	c02007b7          	lui	a5,0xc0200
ffffffffc02046a8:	10f6e663          	bltu	a3,a5,ffffffffc02047b4 <do_wait.part.0+0x1ca>
ffffffffc02046ac:	00097717          	auipc	a4,0x97
ffffffffc02046b0:	fb473703          	ld	a4,-76(a4) # ffffffffc029b660 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc02046b4:	00097797          	auipc	a5,0x97
ffffffffc02046b8:	fb47b783          	ld	a5,-76(a5) # ffffffffc029b668 <npage>
    return pa2page(PADDR(kva));
ffffffffc02046bc:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc02046be:	82b1                	srli	a3,a3,0xc
ffffffffc02046c0:	0cf6fe63          	bgeu	a3,a5,ffffffffc020479c <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc02046c4:	00003797          	auipc	a5,0x3
ffffffffc02046c8:	2e47b783          	ld	a5,740(a5) # ffffffffc02079a8 <nbase>
ffffffffc02046cc:	00097517          	auipc	a0,0x97
ffffffffc02046d0:	fa453503          	ld	a0,-92(a0) # ffffffffc029b670 <pages>
ffffffffc02046d4:	4589                	li	a1,2
ffffffffc02046d6:	8e9d                	sub	a3,a3,a5
ffffffffc02046d8:	069a                	slli	a3,a3,0x6
ffffffffc02046da:	9536                	add	a0,a0,a3
ffffffffc02046dc:	ff8fd0ef          	jal	ffffffffc0201ed4 <free_pages>
    kfree(proc);
ffffffffc02046e0:	8522                	mv	a0,s0
ffffffffc02046e2:	e9cfd0ef          	jal	ffffffffc0201d7e <kfree>
}
ffffffffc02046e6:	70a2                	ld	ra,40(sp)
ffffffffc02046e8:	7402                	ld	s0,32(sp)
ffffffffc02046ea:	64e2                	ld	s1,24(sp)
ffffffffc02046ec:	6942                	ld	s2,16(sp)
ffffffffc02046ee:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc02046f0:	4501                	li	a0,0
}
ffffffffc02046f2:	6145                	addi	sp,sp,48
ffffffffc02046f4:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02046f6:	00097997          	auipc	s3,0x97
ffffffffc02046fa:	f8a98993          	addi	s3,s3,-118 # ffffffffc029b680 <current>
ffffffffc02046fe:	0009b703          	ld	a4,0(s3)
ffffffffc0204702:	f487b683          	ld	a3,-184(a5)
ffffffffc0204706:	f0e695e3          	bne	a3,a4,ffffffffc0204610 <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020470a:	f287a603          	lw	a2,-216(a5)
ffffffffc020470e:	468d                	li	a3,3
ffffffffc0204710:	06d60063          	beq	a2,a3,ffffffffc0204770 <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc0204714:	800007b7          	lui	a5,0x80000
ffffffffc0204718:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e49>
        current->state = PROC_SLEEPING;
ffffffffc020471a:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc020471c:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc0204720:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc0204722:	2ef000ef          	jal	ffffffffc0205210 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204726:	0009b783          	ld	a5,0(s3)
ffffffffc020472a:	0b07a783          	lw	a5,176(a5)
ffffffffc020472e:	8b85                	andi	a5,a5,1
ffffffffc0204730:	e7b9                	bnez	a5,ffffffffc020477e <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc0204732:	ee0487e3          	beqz	s1,ffffffffc0204620 <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204736:	45a9                	li	a1,10
ffffffffc0204738:	8526                	mv	a0,s1
ffffffffc020473a:	43f000ef          	jal	ffffffffc0205378 <hash32>
ffffffffc020473e:	02051793          	slli	a5,a0,0x20
ffffffffc0204742:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204746:	00093797          	auipc	a5,0x93
ffffffffc020474a:	ec278793          	addi	a5,a5,-318 # ffffffffc0297608 <hash_list>
ffffffffc020474e:	953e                	add	a0,a0,a5
ffffffffc0204750:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc0204752:	a029                	j	ffffffffc020475c <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc0204754:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204758:	f8970fe3          	beq	a4,s1,ffffffffc02046f6 <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc020475c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020475e:	fef51be3          	bne	a0,a5,ffffffffc0204754 <do_wait.part.0+0x16a>
ffffffffc0204762:	b57d                	j	ffffffffc0204610 <do_wait.part.0+0x26>
        intr_enable();
ffffffffc0204764:	99afc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0204768:	bf2d                	j	ffffffffc02046a2 <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc020476a:	7018                	ld	a4,32(s0)
ffffffffc020476c:	fb7c                	sd	a5,240(a4)
ffffffffc020476e:	b705                	j	ffffffffc020468e <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204770:	f2878413          	addi	s0,a5,-216
ffffffffc0204774:	b5d1                	j	ffffffffc0204638 <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc0204776:	98efc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc020477a:	4605                	li	a2,1
ffffffffc020477c:	b5f5                	j	ffffffffc0204668 <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc020477e:	555d                	li	a0,-9
ffffffffc0204780:	d27ff0ef          	jal	ffffffffc02044a6 <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc0204784:	00003617          	auipc	a2,0x3
ffffffffc0204788:	91c60613          	addi	a2,a2,-1764 # ffffffffc02070a0 <etext+0x1868>
ffffffffc020478c:	36200593          	li	a1,866
ffffffffc0204790:	00003517          	auipc	a0,0x3
ffffffffc0204794:	87050513          	addi	a0,a0,-1936 # ffffffffc0207000 <etext+0x17c8>
ffffffffc0204798:	caffb0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020479c:	00002617          	auipc	a2,0x2
ffffffffc02047a0:	efc60613          	addi	a2,a2,-260 # ffffffffc0206698 <etext+0xe60>
ffffffffc02047a4:	06900593          	li	a1,105
ffffffffc02047a8:	00002517          	auipc	a0,0x2
ffffffffc02047ac:	e4850513          	addi	a0,a0,-440 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc02047b0:	c97fb0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02047b4:	00002617          	auipc	a2,0x2
ffffffffc02047b8:	ebc60613          	addi	a2,a2,-324 # ffffffffc0206670 <etext+0xe38>
ffffffffc02047bc:	07700593          	li	a1,119
ffffffffc02047c0:	00002517          	auipc	a0,0x2
ffffffffc02047c4:	e3050513          	addi	a0,a0,-464 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc02047c8:	c7ffb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02047cc <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02047cc:	1141                	addi	sp,sp,-16
ffffffffc02047ce:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02047d0:	f3cfd0ef          	jal	ffffffffc0201f0c <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02047d4:	d00fd0ef          	jal	ffffffffc0201cd4 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02047d8:	4601                	li	a2,0
ffffffffc02047da:	4581                	li	a1,0
ffffffffc02047dc:	fffff517          	auipc	a0,0xfffff
ffffffffc02047e0:	6d250513          	addi	a0,a0,1746 # ffffffffc0203eae <user_main>
ffffffffc02047e4:	c73ff0ef          	jal	ffffffffc0204456 <kernel_thread>
    if (pid <= 0)
ffffffffc02047e8:	00a04563          	bgtz	a0,ffffffffc02047f2 <init_main+0x26>
ffffffffc02047ec:	a071                	j	ffffffffc0204878 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02047ee:	223000ef          	jal	ffffffffc0205210 <schedule>
    if (code_store != NULL)
ffffffffc02047f2:	4581                	li	a1,0
ffffffffc02047f4:	4501                	li	a0,0
ffffffffc02047f6:	df5ff0ef          	jal	ffffffffc02045ea <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02047fa:	d975                	beqz	a0,ffffffffc02047ee <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02047fc:	00003517          	auipc	a0,0x3
ffffffffc0204800:	8e450513          	addi	a0,a0,-1820 # ffffffffc02070e0 <etext+0x18a8>
ffffffffc0204804:	991fb0ef          	jal	ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204808:	00097797          	auipc	a5,0x97
ffffffffc020480c:	e807b783          	ld	a5,-384(a5) # ffffffffc029b688 <initproc>
ffffffffc0204810:	7bf8                	ld	a4,240(a5)
ffffffffc0204812:	e339                	bnez	a4,ffffffffc0204858 <init_main+0x8c>
ffffffffc0204814:	7ff8                	ld	a4,248(a5)
ffffffffc0204816:	e329                	bnez	a4,ffffffffc0204858 <init_main+0x8c>
ffffffffc0204818:	1007b703          	ld	a4,256(a5)
ffffffffc020481c:	ef15                	bnez	a4,ffffffffc0204858 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020481e:	00097697          	auipc	a3,0x97
ffffffffc0204822:	e5a6a683          	lw	a3,-422(a3) # ffffffffc029b678 <nr_process>
ffffffffc0204826:	4709                	li	a4,2
ffffffffc0204828:	0ae69463          	bne	a3,a4,ffffffffc02048d0 <init_main+0x104>
ffffffffc020482c:	00097697          	auipc	a3,0x97
ffffffffc0204830:	ddc68693          	addi	a3,a3,-548 # ffffffffc029b608 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204834:	6698                	ld	a4,8(a3)
ffffffffc0204836:	0c878793          	addi	a5,a5,200
ffffffffc020483a:	06f71b63          	bne	a4,a5,ffffffffc02048b0 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020483e:	629c                	ld	a5,0(a3)
ffffffffc0204840:	04f71863          	bne	a4,a5,ffffffffc0204890 <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204844:	00003517          	auipc	a0,0x3
ffffffffc0204848:	98450513          	addi	a0,a0,-1660 # ffffffffc02071c8 <etext+0x1990>
ffffffffc020484c:	949fb0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0204850:	60a2                	ld	ra,8(sp)
ffffffffc0204852:	4501                	li	a0,0
ffffffffc0204854:	0141                	addi	sp,sp,16
ffffffffc0204856:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204858:	00003697          	auipc	a3,0x3
ffffffffc020485c:	8b068693          	addi	a3,a3,-1872 # ffffffffc0207108 <etext+0x18d0>
ffffffffc0204860:	00002617          	auipc	a2,0x2
ffffffffc0204864:	9b860613          	addi	a2,a2,-1608 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0204868:	3d000593          	li	a1,976
ffffffffc020486c:	00002517          	auipc	a0,0x2
ffffffffc0204870:	79450513          	addi	a0,a0,1940 # ffffffffc0207000 <etext+0x17c8>
ffffffffc0204874:	bd3fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("create user_main failed.\n");
ffffffffc0204878:	00003617          	auipc	a2,0x3
ffffffffc020487c:	84860613          	addi	a2,a2,-1976 # ffffffffc02070c0 <etext+0x1888>
ffffffffc0204880:	3c700593          	li	a1,967
ffffffffc0204884:	00002517          	auipc	a0,0x2
ffffffffc0204888:	77c50513          	addi	a0,a0,1916 # ffffffffc0207000 <etext+0x17c8>
ffffffffc020488c:	bbbfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204890:	00003697          	auipc	a3,0x3
ffffffffc0204894:	90868693          	addi	a3,a3,-1784 # ffffffffc0207198 <etext+0x1960>
ffffffffc0204898:	00002617          	auipc	a2,0x2
ffffffffc020489c:	98060613          	addi	a2,a2,-1664 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02048a0:	3d300593          	li	a1,979
ffffffffc02048a4:	00002517          	auipc	a0,0x2
ffffffffc02048a8:	75c50513          	addi	a0,a0,1884 # ffffffffc0207000 <etext+0x17c8>
ffffffffc02048ac:	b9bfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02048b0:	00003697          	auipc	a3,0x3
ffffffffc02048b4:	8b868693          	addi	a3,a3,-1864 # ffffffffc0207168 <etext+0x1930>
ffffffffc02048b8:	00002617          	auipc	a2,0x2
ffffffffc02048bc:	96060613          	addi	a2,a2,-1696 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02048c0:	3d200593          	li	a1,978
ffffffffc02048c4:	00002517          	auipc	a0,0x2
ffffffffc02048c8:	73c50513          	addi	a0,a0,1852 # ffffffffc0207000 <etext+0x17c8>
ffffffffc02048cc:	b7bfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_process == 2);
ffffffffc02048d0:	00003697          	auipc	a3,0x3
ffffffffc02048d4:	88868693          	addi	a3,a3,-1912 # ffffffffc0207158 <etext+0x1920>
ffffffffc02048d8:	00002617          	auipc	a2,0x2
ffffffffc02048dc:	94060613          	addi	a2,a2,-1728 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02048e0:	3d100593          	li	a1,977
ffffffffc02048e4:	00002517          	auipc	a0,0x2
ffffffffc02048e8:	71c50513          	addi	a0,a0,1820 # ffffffffc0207000 <etext+0x17c8>
ffffffffc02048ec:	b5bfb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02048f0 <do_execve>:
{
ffffffffc02048f0:	7171                	addi	sp,sp,-176
ffffffffc02048f2:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02048f4:	00097d17          	auipc	s10,0x97
ffffffffc02048f8:	d8cd0d13          	addi	s10,s10,-628 # ffffffffc029b680 <current>
ffffffffc02048fc:	000d3783          	ld	a5,0(s10)
{
ffffffffc0204900:	e94a                	sd	s2,144(sp)
ffffffffc0204902:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204904:	0287b903          	ld	s2,40(a5)
{
ffffffffc0204908:	84ae                	mv	s1,a1
ffffffffc020490a:	e54e                	sd	s3,136(sp)
ffffffffc020490c:	ec32                	sd	a2,24(sp)
ffffffffc020490e:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204910:	85aa                	mv	a1,a0
ffffffffc0204912:	8626                	mv	a2,s1
ffffffffc0204914:	854a                	mv	a0,s2
ffffffffc0204916:	4681                	li	a3,0
{
ffffffffc0204918:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020491a:	c6eff0ef          	jal	ffffffffc0203d88 <user_mem_check>
ffffffffc020491e:	46050f63          	beqz	a0,ffffffffc0204d9c <do_execve+0x4ac>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0204922:	4641                	li	a2,16
ffffffffc0204924:	1808                	addi	a0,sp,48
ffffffffc0204926:	4581                	li	a1,0
ffffffffc0204928:	6e7000ef          	jal	ffffffffc020580e <memset>
    if (len > PROC_NAME_LEN)
ffffffffc020492c:	47bd                	li	a5,15
ffffffffc020492e:	8626                	mv	a2,s1
ffffffffc0204930:	0e97ef63          	bltu	a5,s1,ffffffffc0204a2e <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc0204934:	85ce                	mv	a1,s3
ffffffffc0204936:	1808                	addi	a0,sp,48
ffffffffc0204938:	6e9000ef          	jal	ffffffffc0205820 <memcpy>
    if (mm != NULL)
ffffffffc020493c:	10090063          	beqz	s2,ffffffffc0204a3c <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc0204940:	00002517          	auipc	a0,0x2
ffffffffc0204944:	48050513          	addi	a0,a0,1152 # ffffffffc0206dc0 <etext+0x1588>
ffffffffc0204948:	883fb0ef          	jal	ffffffffc02001ca <cputs>
ffffffffc020494c:	00097797          	auipc	a5,0x97
ffffffffc0204950:	d047b783          	ld	a5,-764(a5) # ffffffffc029b650 <boot_pgdir_pa>
ffffffffc0204954:	577d                	li	a4,-1
ffffffffc0204956:	177e                	slli	a4,a4,0x3f
ffffffffc0204958:	83b1                	srli	a5,a5,0xc
ffffffffc020495a:	8fd9                	or	a5,a5,a4
ffffffffc020495c:	18079073          	csrw	satp,a5
ffffffffc0204960:	03092783          	lw	a5,48(s2)
ffffffffc0204964:	37fd                	addiw	a5,a5,-1
ffffffffc0204966:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc020496a:	30078563          	beqz	a5,ffffffffc0204c74 <do_execve+0x384>
        current->mm = NULL;
ffffffffc020496e:	000d3783          	ld	a5,0(s10)
ffffffffc0204972:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204976:	d87fe0ef          	jal	ffffffffc02036fc <mm_create>
ffffffffc020497a:	892a                	mv	s2,a0
ffffffffc020497c:	22050063          	beqz	a0,ffffffffc0204b9c <do_execve+0x2ac>
    if ((page = alloc_page()) == NULL)
ffffffffc0204980:	4505                	li	a0,1
ffffffffc0204982:	d18fd0ef          	jal	ffffffffc0201e9a <alloc_pages>
ffffffffc0204986:	42050063          	beqz	a0,ffffffffc0204da6 <do_execve+0x4b6>
    return page - pages + nbase;
ffffffffc020498a:	f0e2                	sd	s8,96(sp)
ffffffffc020498c:	00097c17          	auipc	s8,0x97
ffffffffc0204990:	ce4c0c13          	addi	s8,s8,-796 # ffffffffc029b670 <pages>
ffffffffc0204994:	000c3783          	ld	a5,0(s8)
ffffffffc0204998:	f4de                	sd	s7,104(sp)
ffffffffc020499a:	00003b97          	auipc	s7,0x3
ffffffffc020499e:	00ebbb83          	ld	s7,14(s7) # ffffffffc02079a8 <nbase>
ffffffffc02049a2:	40f506b3          	sub	a3,a0,a5
ffffffffc02049a6:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc02049a8:	00097c97          	auipc	s9,0x97
ffffffffc02049ac:	cc0c8c93          	addi	s9,s9,-832 # ffffffffc029b668 <npage>
ffffffffc02049b0:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc02049b2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02049b4:	5b7d                	li	s6,-1
ffffffffc02049b6:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc02049ba:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc02049bc:	00cb5713          	srli	a4,s6,0xc
ffffffffc02049c0:	e83a                	sd	a4,16(sp)
ffffffffc02049c2:	fcd6                	sd	s5,120(sp)
ffffffffc02049c4:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02049c6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02049c8:	40f77263          	bgeu	a4,a5,ffffffffc0204dcc <do_execve+0x4dc>
ffffffffc02049cc:	00097a97          	auipc	s5,0x97
ffffffffc02049d0:	c94a8a93          	addi	s5,s5,-876 # ffffffffc029b660 <va_pa_offset>
ffffffffc02049d4:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02049d8:	00097597          	auipc	a1,0x97
ffffffffc02049dc:	c805b583          	ld	a1,-896(a1) # ffffffffc029b658 <boot_pgdir_va>
ffffffffc02049e0:	6605                	lui	a2,0x1
ffffffffc02049e2:	00f684b3          	add	s1,a3,a5
ffffffffc02049e6:	8526                	mv	a0,s1
ffffffffc02049e8:	639000ef          	jal	ffffffffc0205820 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02049ec:	66e2                	ld	a3,24(sp)
ffffffffc02049ee:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02049f2:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02049f6:	4298                	lw	a4,0(a3)
ffffffffc02049f8:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464ba3c7>
ffffffffc02049fc:	06f70863          	beq	a4,a5,ffffffffc0204a6c <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc0204a00:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc0204a02:	854a                	mv	a0,s2
ffffffffc0204a04:	d28ff0ef          	jal	ffffffffc0203f2c <put_pgdir>
ffffffffc0204a08:	7ae6                	ld	s5,120(sp)
ffffffffc0204a0a:	7b46                	ld	s6,112(sp)
ffffffffc0204a0c:	7ba6                	ld	s7,104(sp)
ffffffffc0204a0e:	7c06                	ld	s8,96(sp)
ffffffffc0204a10:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc0204a12:	854a                	mv	a0,s2
ffffffffc0204a14:	e27fe0ef          	jal	ffffffffc020383a <mm_destroy>
    do_exit(ret);
ffffffffc0204a18:	8526                	mv	a0,s1
ffffffffc0204a1a:	f122                	sd	s0,160(sp)
ffffffffc0204a1c:	e152                	sd	s4,128(sp)
ffffffffc0204a1e:	fcd6                	sd	s5,120(sp)
ffffffffc0204a20:	f8da                	sd	s6,112(sp)
ffffffffc0204a22:	f4de                	sd	s7,104(sp)
ffffffffc0204a24:	f0e2                	sd	s8,96(sp)
ffffffffc0204a26:	ece6                	sd	s9,88(sp)
ffffffffc0204a28:	e4ee                	sd	s11,72(sp)
ffffffffc0204a2a:	a7dff0ef          	jal	ffffffffc02044a6 <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc0204a2e:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc0204a30:	85ce                	mv	a1,s3
ffffffffc0204a32:	1808                	addi	a0,sp,48
ffffffffc0204a34:	5ed000ef          	jal	ffffffffc0205820 <memcpy>
    if (mm != NULL)
ffffffffc0204a38:	f00914e3          	bnez	s2,ffffffffc0204940 <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc0204a3c:	000d3783          	ld	a5,0(s10)
ffffffffc0204a40:	779c                	ld	a5,40(a5)
ffffffffc0204a42:	db95                	beqz	a5,ffffffffc0204976 <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204a44:	00002617          	auipc	a2,0x2
ffffffffc0204a48:	7a460613          	addi	a2,a2,1956 # ffffffffc02071e8 <etext+0x19b0>
ffffffffc0204a4c:	24d00593          	li	a1,589
ffffffffc0204a50:	00002517          	auipc	a0,0x2
ffffffffc0204a54:	5b050513          	addi	a0,a0,1456 # ffffffffc0207000 <etext+0x17c8>
ffffffffc0204a58:	f122                	sd	s0,160(sp)
ffffffffc0204a5a:	e152                	sd	s4,128(sp)
ffffffffc0204a5c:	fcd6                	sd	s5,120(sp)
ffffffffc0204a5e:	f8da                	sd	s6,112(sp)
ffffffffc0204a60:	f4de                	sd	s7,104(sp)
ffffffffc0204a62:	f0e2                	sd	s8,96(sp)
ffffffffc0204a64:	ece6                	sd	s9,88(sp)
ffffffffc0204a66:	e4ee                	sd	s11,72(sp)
ffffffffc0204a68:	9dffb0ef          	jal	ffffffffc0200446 <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a6c:	0386d703          	lhu	a4,56(a3)
ffffffffc0204a70:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a72:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a76:	00371793          	slli	a5,a4,0x3
ffffffffc0204a7a:	8f99                	sub	a5,a5,a4
ffffffffc0204a7c:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a7e:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a80:	97d2                	add	a5,a5,s4
ffffffffc0204a82:	f122                	sd	s0,160(sp)
ffffffffc0204a84:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204a86:	00fa7e63          	bgeu	s4,a5,ffffffffc0204aa2 <do_execve+0x1b2>
ffffffffc0204a8a:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204a8c:	000a2783          	lw	a5,0(s4)
ffffffffc0204a90:	4705                	li	a4,1
ffffffffc0204a92:	10e78763          	beq	a5,a4,ffffffffc0204ba0 <do_execve+0x2b0>
    for (; ph < ph_end; ph++)
ffffffffc0204a96:	77a2                	ld	a5,40(sp)
ffffffffc0204a98:	038a0a13          	addi	s4,s4,56
ffffffffc0204a9c:	fefa68e3          	bltu	s4,a5,ffffffffc0204a8c <do_execve+0x19c>
ffffffffc0204aa0:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204aa2:	4701                	li	a4,0
ffffffffc0204aa4:	46ad                	li	a3,11
ffffffffc0204aa6:	00100637          	lui	a2,0x100
ffffffffc0204aaa:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204aae:	854a                	mv	a0,s2
ffffffffc0204ab0:	dddfe0ef          	jal	ffffffffc020388c <mm_map>
ffffffffc0204ab4:	84aa                	mv	s1,a0
ffffffffc0204ab6:	1a051963          	bnez	a0,ffffffffc0204c68 <do_execve+0x378>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204aba:	01893503          	ld	a0,24(s2)
ffffffffc0204abe:	467d                	li	a2,31
ffffffffc0204ac0:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204ac4:	b57fe0ef          	jal	ffffffffc020361a <pgdir_alloc_page>
ffffffffc0204ac8:	3a050163          	beqz	a0,ffffffffc0204e6a <do_execve+0x57a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204acc:	01893503          	ld	a0,24(s2)
ffffffffc0204ad0:	467d                	li	a2,31
ffffffffc0204ad2:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204ad6:	b45fe0ef          	jal	ffffffffc020361a <pgdir_alloc_page>
ffffffffc0204ada:	36050763          	beqz	a0,ffffffffc0204e48 <do_execve+0x558>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ade:	01893503          	ld	a0,24(s2)
ffffffffc0204ae2:	467d                	li	a2,31
ffffffffc0204ae4:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204ae8:	b33fe0ef          	jal	ffffffffc020361a <pgdir_alloc_page>
ffffffffc0204aec:	32050d63          	beqz	a0,ffffffffc0204e26 <do_execve+0x536>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204af0:	01893503          	ld	a0,24(s2)
ffffffffc0204af4:	467d                	li	a2,31
ffffffffc0204af6:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204afa:	b21fe0ef          	jal	ffffffffc020361a <pgdir_alloc_page>
ffffffffc0204afe:	30050363          	beqz	a0,ffffffffc0204e04 <do_execve+0x514>
    mm->mm_count += 1;
ffffffffc0204b02:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0204b06:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b0a:	01893683          	ld	a3,24(s2)
ffffffffc0204b0e:	2785                	addiw	a5,a5,1
ffffffffc0204b10:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0204b14:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf5e70>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b18:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b1c:	2cf6e763          	bltu	a3,a5,ffffffffc0204dea <do_execve+0x4fa>
ffffffffc0204b20:	000ab783          	ld	a5,0(s5)
ffffffffc0204b24:	577d                	li	a4,-1
ffffffffc0204b26:	177e                	slli	a4,a4,0x3f
ffffffffc0204b28:	8e9d                	sub	a3,a3,a5
ffffffffc0204b2a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b2e:	f654                	sd	a3,168(a2)
ffffffffc0204b30:	8fd9                	or	a5,a5,a4
ffffffffc0204b32:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204b36:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b38:	4581                	li	a1,0
ffffffffc0204b3a:	12000613          	li	a2,288
ffffffffc0204b3e:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204b40:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b44:	4cb000ef          	jal	ffffffffc020580e <memset>
    tf->epc = elf->e_entry;
ffffffffc0204b48:	67e2                	ld	a5,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b4a:	000d3983          	ld	s3,0(s10)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b4e:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry;
ffffffffc0204b52:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b54:	4785                	li	a5,1
ffffffffc0204b56:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b58:	02096913          	ori	s2,s2,32
    tf->epc = elf->e_entry;
ffffffffc0204b5c:	10e43423          	sd	a4,264(s0)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b60:	e81c                	sd	a5,16(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0204b62:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b66:	4641                	li	a2,16
ffffffffc0204b68:	4581                	li	a1,0
ffffffffc0204b6a:	0b498513          	addi	a0,s3,180
ffffffffc0204b6e:	4a1000ef          	jal	ffffffffc020580e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204b72:	180c                	addi	a1,sp,48
ffffffffc0204b74:	0b498513          	addi	a0,s3,180
ffffffffc0204b78:	463d                	li	a2,15
ffffffffc0204b7a:	4a7000ef          	jal	ffffffffc0205820 <memcpy>
ffffffffc0204b7e:	740a                	ld	s0,160(sp)
ffffffffc0204b80:	6a0a                	ld	s4,128(sp)
ffffffffc0204b82:	7ae6                	ld	s5,120(sp)
ffffffffc0204b84:	7b46                	ld	s6,112(sp)
ffffffffc0204b86:	7ba6                	ld	s7,104(sp)
ffffffffc0204b88:	7c06                	ld	s8,96(sp)
ffffffffc0204b8a:	6ce6                	ld	s9,88(sp)
}
ffffffffc0204b8c:	70aa                	ld	ra,168(sp)
ffffffffc0204b8e:	694a                	ld	s2,144(sp)
ffffffffc0204b90:	69aa                	ld	s3,136(sp)
ffffffffc0204b92:	6d46                	ld	s10,80(sp)
ffffffffc0204b94:	8526                	mv	a0,s1
ffffffffc0204b96:	64ea                	ld	s1,152(sp)
ffffffffc0204b98:	614d                	addi	sp,sp,176
ffffffffc0204b9a:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204b9c:	54f1                	li	s1,-4
ffffffffc0204b9e:	bdad                	j	ffffffffc0204a18 <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204ba0:	028a3603          	ld	a2,40(s4)
ffffffffc0204ba4:	020a3783          	ld	a5,32(s4)
ffffffffc0204ba8:	20f66363          	bltu	a2,a5,ffffffffc0204dae <do_execve+0x4be>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204bac:	004a2783          	lw	a5,4(s4)
ffffffffc0204bb0:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204bb4:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204bb8:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bba:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204bbc:	c6f1                	beqz	a3,ffffffffc0204c88 <do_execve+0x398>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bbe:	1c079763          	bnez	a5,ffffffffc0204d8c <do_execve+0x49c>
            perm |= (PTE_W | PTE_R);
ffffffffc0204bc2:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc0204bc4:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc0204bc8:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc0204bca:	c709                	beqz	a4,ffffffffc0204bd4 <do_execve+0x2e4>
            perm |= PTE_X;
ffffffffc0204bcc:	67a2                	ld	a5,8(sp)
ffffffffc0204bce:	0087e793          	ori	a5,a5,8
ffffffffc0204bd2:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204bd4:	010a3583          	ld	a1,16(s4)
ffffffffc0204bd8:	4701                	li	a4,0
ffffffffc0204bda:	854a                	mv	a0,s2
ffffffffc0204bdc:	cb1fe0ef          	jal	ffffffffc020388c <mm_map>
ffffffffc0204be0:	84aa                	mv	s1,a0
ffffffffc0204be2:	1c051463          	bnez	a0,ffffffffc0204daa <do_execve+0x4ba>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204be6:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bea:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bee:	77fd                	lui	a5,0xfffff
ffffffffc0204bf0:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bf4:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc0204bf6:	1a9b7563          	bgeu	s6,s1,ffffffffc0204da0 <do_execve+0x4b0>
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204bfa:	008a3983          	ld	s3,8(s4)
ffffffffc0204bfe:	67e2                	ld	a5,24(sp)
ffffffffc0204c00:	99be                	add	s3,s3,a5
ffffffffc0204c02:	a881                	j	ffffffffc0204c52 <do_execve+0x362>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c04:	6785                	lui	a5,0x1
ffffffffc0204c06:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204c0a:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204c0e:	01b4e463          	bltu	s1,s11,ffffffffc0204c16 <do_execve+0x326>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c12:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204c16:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204c1a:	67c2                	ld	a5,16(sp)
ffffffffc0204c1c:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204c20:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c24:	8699                	srai	a3,a3,0x6
ffffffffc0204c26:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204c28:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c2c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c2e:	18a87363          	bgeu	a6,a0,ffffffffc0204db4 <do_execve+0x4c4>
ffffffffc0204c32:	000ab503          	ld	a0,0(s5)
ffffffffc0204c36:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c3a:	e032                	sd	a2,0(sp)
ffffffffc0204c3c:	9536                	add	a0,a0,a3
ffffffffc0204c3e:	952e                	add	a0,a0,a1
ffffffffc0204c40:	85ce                	mv	a1,s3
ffffffffc0204c42:	3df000ef          	jal	ffffffffc0205820 <memcpy>
            start += size, from += size;
ffffffffc0204c46:	6602                	ld	a2,0(sp)
ffffffffc0204c48:	9b32                	add	s6,s6,a2
ffffffffc0204c4a:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204c4c:	049b7563          	bgeu	s6,s1,ffffffffc0204c96 <do_execve+0x3a6>
ffffffffc0204c50:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c52:	01893503          	ld	a0,24(s2)
ffffffffc0204c56:	6622                	ld	a2,8(sp)
ffffffffc0204c58:	e02e                	sd	a1,0(sp)
ffffffffc0204c5a:	9c1fe0ef          	jal	ffffffffc020361a <pgdir_alloc_page>
ffffffffc0204c5e:	6582                	ld	a1,0(sp)
ffffffffc0204c60:	842a                	mv	s0,a0
ffffffffc0204c62:	f14d                	bnez	a0,ffffffffc0204c04 <do_execve+0x314>
ffffffffc0204c64:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204c66:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204c68:	854a                	mv	a0,s2
ffffffffc0204c6a:	d87fe0ef          	jal	ffffffffc02039f0 <exit_mmap>
ffffffffc0204c6e:	740a                	ld	s0,160(sp)
ffffffffc0204c70:	6a0a                	ld	s4,128(sp)
ffffffffc0204c72:	bb41                	j	ffffffffc0204a02 <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204c74:	854a                	mv	a0,s2
ffffffffc0204c76:	d7bfe0ef          	jal	ffffffffc02039f0 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204c7a:	854a                	mv	a0,s2
ffffffffc0204c7c:	ab0ff0ef          	jal	ffffffffc0203f2c <put_pgdir>
            mm_destroy(mm);
ffffffffc0204c80:	854a                	mv	a0,s2
ffffffffc0204c82:	bb9fe0ef          	jal	ffffffffc020383a <mm_destroy>
ffffffffc0204c86:	b1e5                	j	ffffffffc020496e <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c88:	0e078e63          	beqz	a5,ffffffffc0204d84 <do_execve+0x494>
            perm |= PTE_R;
ffffffffc0204c8c:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204c8e:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204c92:	e43e                	sd	a5,8(sp)
ffffffffc0204c94:	bf1d                	j	ffffffffc0204bca <do_execve+0x2da>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204c96:	010a3483          	ld	s1,16(s4)
ffffffffc0204c9a:	028a3683          	ld	a3,40(s4)
ffffffffc0204c9e:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204ca0:	07bb7c63          	bgeu	s6,s11,ffffffffc0204d18 <do_execve+0x428>
            if (start == end)
ffffffffc0204ca4:	df6489e3          	beq	s1,s6,ffffffffc0204a96 <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204ca8:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204cac:	0fb4f563          	bgeu	s1,s11,ffffffffc0204d96 <do_execve+0x4a6>
    return page - pages + nbase;
ffffffffc0204cb0:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204cb4:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204cb8:	40d406b3          	sub	a3,s0,a3
ffffffffc0204cbc:	8699                	srai	a3,a3,0x6
ffffffffc0204cbe:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204cc0:	00c69593          	slli	a1,a3,0xc
ffffffffc0204cc4:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204cc6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204cc8:	0ec5f663          	bgeu	a1,a2,ffffffffc0204db4 <do_execve+0x4c4>
ffffffffc0204ccc:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204cd0:	6505                	lui	a0,0x1
ffffffffc0204cd2:	955a                	add	a0,a0,s6
ffffffffc0204cd4:	96b2                	add	a3,a3,a2
ffffffffc0204cd6:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204cda:	9536                	add	a0,a0,a3
ffffffffc0204cdc:	864e                	mv	a2,s3
ffffffffc0204cde:	4581                	li	a1,0
ffffffffc0204ce0:	32f000ef          	jal	ffffffffc020580e <memset>
            start += size;
ffffffffc0204ce4:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204ce6:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204cea:	01b4f463          	bgeu	s1,s11,ffffffffc0204cf2 <do_execve+0x402>
ffffffffc0204cee:	db6484e3          	beq	s1,s6,ffffffffc0204a96 <do_execve+0x1a6>
ffffffffc0204cf2:	e299                	bnez	a3,ffffffffc0204cf8 <do_execve+0x408>
ffffffffc0204cf4:	03bb0263          	beq	s6,s11,ffffffffc0204d18 <do_execve+0x428>
ffffffffc0204cf8:	00002697          	auipc	a3,0x2
ffffffffc0204cfc:	51868693          	addi	a3,a3,1304 # ffffffffc0207210 <etext+0x19d8>
ffffffffc0204d00:	00001617          	auipc	a2,0x1
ffffffffc0204d04:	51860613          	addi	a2,a2,1304 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0204d08:	2b600593          	li	a1,694
ffffffffc0204d0c:	00002517          	auipc	a0,0x2
ffffffffc0204d10:	2f450513          	addi	a0,a0,756 # ffffffffc0207000 <etext+0x17c8>
ffffffffc0204d14:	f32fb0ef          	jal	ffffffffc0200446 <__panic>
        while (start < end)
ffffffffc0204d18:	d69b7fe3          	bgeu	s6,s1,ffffffffc0204a96 <do_execve+0x1a6>
ffffffffc0204d1c:	56fd                	li	a3,-1
ffffffffc0204d1e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204d22:	f03e                	sd	a5,32(sp)
ffffffffc0204d24:	a0b9                	j	ffffffffc0204d72 <do_execve+0x482>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d26:	6785                	lui	a5,0x1
ffffffffc0204d28:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204d2c:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204d30:	0104e463          	bltu	s1,a6,ffffffffc0204d38 <do_execve+0x448>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d34:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204d38:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204d3c:	7782                	ld	a5,32(sp)
ffffffffc0204d3e:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204d42:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d46:	8699                	srai	a3,a3,0x6
ffffffffc0204d48:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204d4a:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d4e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d50:	06b57263          	bgeu	a0,a1,ffffffffc0204db4 <do_execve+0x4c4>
ffffffffc0204d54:	000ab583          	ld	a1,0(s5)
ffffffffc0204d58:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d5c:	864e                	mv	a2,s3
ffffffffc0204d5e:	96ae                	add	a3,a3,a1
ffffffffc0204d60:	9536                	add	a0,a0,a3
ffffffffc0204d62:	4581                	li	a1,0
            start += size;
ffffffffc0204d64:	9b4e                	add	s6,s6,s3
ffffffffc0204d66:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d68:	2a7000ef          	jal	ffffffffc020580e <memset>
        while (start < end)
ffffffffc0204d6c:	d29b75e3          	bgeu	s6,s1,ffffffffc0204a96 <do_execve+0x1a6>
ffffffffc0204d70:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d72:	01893503          	ld	a0,24(s2)
ffffffffc0204d76:	6622                	ld	a2,8(sp)
ffffffffc0204d78:	85ee                	mv	a1,s11
ffffffffc0204d7a:	8a1fe0ef          	jal	ffffffffc020361a <pgdir_alloc_page>
ffffffffc0204d7e:	842a                	mv	s0,a0
ffffffffc0204d80:	f15d                	bnez	a0,ffffffffc0204d26 <do_execve+0x436>
ffffffffc0204d82:	b5cd                	j	ffffffffc0204c64 <do_execve+0x374>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204d84:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d86:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204d88:	e43e                	sd	a5,8(sp)
ffffffffc0204d8a:	b581                	j	ffffffffc0204bca <do_execve+0x2da>
            perm |= (PTE_W | PTE_R);
ffffffffc0204d8c:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204d8e:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204d92:	e43e                	sd	a5,8(sp)
ffffffffc0204d94:	bd1d                	j	ffffffffc0204bca <do_execve+0x2da>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d96:	416d89b3          	sub	s3,s11,s6
ffffffffc0204d9a:	bf19                	j	ffffffffc0204cb0 <do_execve+0x3c0>
        return -E_INVAL;
ffffffffc0204d9c:	54f5                	li	s1,-3
ffffffffc0204d9e:	b3fd                	j	ffffffffc0204b8c <do_execve+0x29c>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204da0:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204da2:	84da                	mv	s1,s6
ffffffffc0204da4:	bddd                	j	ffffffffc0204c9a <do_execve+0x3aa>
    int ret = -E_NO_MEM;
ffffffffc0204da6:	54f1                	li	s1,-4
ffffffffc0204da8:	b1ad                	j	ffffffffc0204a12 <do_execve+0x122>
ffffffffc0204daa:	6da6                	ld	s11,72(sp)
ffffffffc0204dac:	bd75                	j	ffffffffc0204c68 <do_execve+0x378>
            ret = -E_INVAL_ELF;
ffffffffc0204dae:	6da6                	ld	s11,72(sp)
ffffffffc0204db0:	54e1                	li	s1,-8
ffffffffc0204db2:	bd5d                	j	ffffffffc0204c68 <do_execve+0x378>
ffffffffc0204db4:	00002617          	auipc	a2,0x2
ffffffffc0204db8:	81460613          	addi	a2,a2,-2028 # ffffffffc02065c8 <etext+0xd90>
ffffffffc0204dbc:	07100593          	li	a1,113
ffffffffc0204dc0:	00002517          	auipc	a0,0x2
ffffffffc0204dc4:	83050513          	addi	a0,a0,-2000 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc0204dc8:	e7efb0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0204dcc:	00001617          	auipc	a2,0x1
ffffffffc0204dd0:	7fc60613          	addi	a2,a2,2044 # ffffffffc02065c8 <etext+0xd90>
ffffffffc0204dd4:	07100593          	li	a1,113
ffffffffc0204dd8:	00002517          	auipc	a0,0x2
ffffffffc0204ddc:	81850513          	addi	a0,a0,-2024 # ffffffffc02065f0 <etext+0xdb8>
ffffffffc0204de0:	f122                	sd	s0,160(sp)
ffffffffc0204de2:	e152                	sd	s4,128(sp)
ffffffffc0204de4:	e4ee                	sd	s11,72(sp)
ffffffffc0204de6:	e60fb0ef          	jal	ffffffffc0200446 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204dea:	00002617          	auipc	a2,0x2
ffffffffc0204dee:	88660613          	addi	a2,a2,-1914 # ffffffffc0206670 <etext+0xe38>
ffffffffc0204df2:	2d500593          	li	a1,725
ffffffffc0204df6:	00002517          	auipc	a0,0x2
ffffffffc0204dfa:	20a50513          	addi	a0,a0,522 # ffffffffc0207000 <etext+0x17c8>
ffffffffc0204dfe:	e4ee                	sd	s11,72(sp)
ffffffffc0204e00:	e46fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e04:	00002697          	auipc	a3,0x2
ffffffffc0204e08:	52468693          	addi	a3,a3,1316 # ffffffffc0207328 <etext+0x1af0>
ffffffffc0204e0c:	00001617          	auipc	a2,0x1
ffffffffc0204e10:	40c60613          	addi	a2,a2,1036 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0204e14:	2d000593          	li	a1,720
ffffffffc0204e18:	00002517          	auipc	a0,0x2
ffffffffc0204e1c:	1e850513          	addi	a0,a0,488 # ffffffffc0207000 <etext+0x17c8>
ffffffffc0204e20:	e4ee                	sd	s11,72(sp)
ffffffffc0204e22:	e24fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e26:	00002697          	auipc	a3,0x2
ffffffffc0204e2a:	4ba68693          	addi	a3,a3,1210 # ffffffffc02072e0 <etext+0x1aa8>
ffffffffc0204e2e:	00001617          	auipc	a2,0x1
ffffffffc0204e32:	3ea60613          	addi	a2,a2,1002 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0204e36:	2cf00593          	li	a1,719
ffffffffc0204e3a:	00002517          	auipc	a0,0x2
ffffffffc0204e3e:	1c650513          	addi	a0,a0,454 # ffffffffc0207000 <etext+0x17c8>
ffffffffc0204e42:	e4ee                	sd	s11,72(sp)
ffffffffc0204e44:	e02fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e48:	00002697          	auipc	a3,0x2
ffffffffc0204e4c:	45068693          	addi	a3,a3,1104 # ffffffffc0207298 <etext+0x1a60>
ffffffffc0204e50:	00001617          	auipc	a2,0x1
ffffffffc0204e54:	3c860613          	addi	a2,a2,968 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0204e58:	2ce00593          	li	a1,718
ffffffffc0204e5c:	00002517          	auipc	a0,0x2
ffffffffc0204e60:	1a450513          	addi	a0,a0,420 # ffffffffc0207000 <etext+0x17c8>
ffffffffc0204e64:	e4ee                	sd	s11,72(sp)
ffffffffc0204e66:	de0fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204e6a:	00002697          	auipc	a3,0x2
ffffffffc0204e6e:	3e668693          	addi	a3,a3,998 # ffffffffc0207250 <etext+0x1a18>
ffffffffc0204e72:	00001617          	auipc	a2,0x1
ffffffffc0204e76:	3a660613          	addi	a2,a2,934 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0204e7a:	2cd00593          	li	a1,717
ffffffffc0204e7e:	00002517          	auipc	a0,0x2
ffffffffc0204e82:	18250513          	addi	a0,a0,386 # ffffffffc0207000 <etext+0x17c8>
ffffffffc0204e86:	e4ee                	sd	s11,72(sp)
ffffffffc0204e88:	dbefb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204e8c <do_yield>:
    current->need_resched = 1;
ffffffffc0204e8c:	00096797          	auipc	a5,0x96
ffffffffc0204e90:	7f47b783          	ld	a5,2036(a5) # ffffffffc029b680 <current>
ffffffffc0204e94:	4705                	li	a4,1
}
ffffffffc0204e96:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204e98:	ef98                	sd	a4,24(a5)
}
ffffffffc0204e9a:	8082                	ret

ffffffffc0204e9c <do_wait>:
    if (code_store != NULL)
ffffffffc0204e9c:	c59d                	beqz	a1,ffffffffc0204eca <do_wait+0x2e>
{
ffffffffc0204e9e:	1101                	addi	sp,sp,-32
ffffffffc0204ea0:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204ea2:	00096517          	auipc	a0,0x96
ffffffffc0204ea6:	7de53503          	ld	a0,2014(a0) # ffffffffc029b680 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204eaa:	4685                	li	a3,1
ffffffffc0204eac:	4611                	li	a2,4
ffffffffc0204eae:	7508                	ld	a0,40(a0)
{
ffffffffc0204eb0:	ec06                	sd	ra,24(sp)
ffffffffc0204eb2:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204eb4:	ed5fe0ef          	jal	ffffffffc0203d88 <user_mem_check>
ffffffffc0204eb8:	6702                	ld	a4,0(sp)
ffffffffc0204eba:	67a2                	ld	a5,8(sp)
ffffffffc0204ebc:	c909                	beqz	a0,ffffffffc0204ece <do_wait+0x32>
}
ffffffffc0204ebe:	60e2                	ld	ra,24(sp)
ffffffffc0204ec0:	85be                	mv	a1,a5
ffffffffc0204ec2:	853a                	mv	a0,a4
ffffffffc0204ec4:	6105                	addi	sp,sp,32
ffffffffc0204ec6:	f24ff06f          	j	ffffffffc02045ea <do_wait.part.0>
ffffffffc0204eca:	f20ff06f          	j	ffffffffc02045ea <do_wait.part.0>
ffffffffc0204ece:	60e2                	ld	ra,24(sp)
ffffffffc0204ed0:	5575                	li	a0,-3
ffffffffc0204ed2:	6105                	addi	sp,sp,32
ffffffffc0204ed4:	8082                	ret

ffffffffc0204ed6 <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204ed6:	6789                	lui	a5,0x2
ffffffffc0204ed8:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204edc:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bb2>
ffffffffc0204ede:	06e7e463          	bltu	a5,a4,ffffffffc0204f46 <do_kill+0x70>
{
ffffffffc0204ee2:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ee4:	45a9                	li	a1,10
{
ffffffffc0204ee6:	ec06                	sd	ra,24(sp)
ffffffffc0204ee8:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204eea:	48e000ef          	jal	ffffffffc0205378 <hash32>
ffffffffc0204eee:	02051793          	slli	a5,a0,0x20
ffffffffc0204ef2:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204ef6:	00092797          	auipc	a5,0x92
ffffffffc0204efa:	71278793          	addi	a5,a5,1810 # ffffffffc0297608 <hash_list>
ffffffffc0204efe:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204f00:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f02:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204f04:	a029                	j	ffffffffc0204f0e <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204f06:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204f0a:	00c70963          	beq	a4,a2,ffffffffc0204f1c <do_kill+0x46>
ffffffffc0204f0e:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204f10:	fea69be3          	bne	a3,a0,ffffffffc0204f06 <do_kill+0x30>
}
ffffffffc0204f14:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204f16:	5575                	li	a0,-3
}
ffffffffc0204f18:	6105                	addi	sp,sp,32
ffffffffc0204f1a:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204f1c:	fd852703          	lw	a4,-40(a0)
ffffffffc0204f20:	00177693          	andi	a3,a4,1
ffffffffc0204f24:	e29d                	bnez	a3,ffffffffc0204f4a <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f26:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204f28:	00176713          	ori	a4,a4,1
ffffffffc0204f2c:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f30:	0006c663          	bltz	a3,ffffffffc0204f3c <do_kill+0x66>
            return 0;
ffffffffc0204f34:	4501                	li	a0,0
}
ffffffffc0204f36:	60e2                	ld	ra,24(sp)
ffffffffc0204f38:	6105                	addi	sp,sp,32
ffffffffc0204f3a:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204f3c:	f2850513          	addi	a0,a0,-216
ffffffffc0204f40:	23c000ef          	jal	ffffffffc020517c <wakeup_proc>
ffffffffc0204f44:	bfc5                	j	ffffffffc0204f34 <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204f46:	5575                	li	a0,-3
}
ffffffffc0204f48:	8082                	ret
        return -E_KILLED;
ffffffffc0204f4a:	555d                	li	a0,-9
ffffffffc0204f4c:	b7ed                	j	ffffffffc0204f36 <do_kill+0x60>

ffffffffc0204f4e <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204f4e:	1101                	addi	sp,sp,-32
ffffffffc0204f50:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204f52:	00096797          	auipc	a5,0x96
ffffffffc0204f56:	6b678793          	addi	a5,a5,1718 # ffffffffc029b608 <proc_list>
ffffffffc0204f5a:	ec06                	sd	ra,24(sp)
ffffffffc0204f5c:	e822                	sd	s0,16(sp)
ffffffffc0204f5e:	e04a                	sd	s2,0(sp)
ffffffffc0204f60:	00092497          	auipc	s1,0x92
ffffffffc0204f64:	6a848493          	addi	s1,s1,1704 # ffffffffc0297608 <hash_list>
ffffffffc0204f68:	e79c                	sd	a5,8(a5)
ffffffffc0204f6a:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204f6c:	00096717          	auipc	a4,0x96
ffffffffc0204f70:	69c70713          	addi	a4,a4,1692 # ffffffffc029b608 <proc_list>
ffffffffc0204f74:	87a6                	mv	a5,s1
ffffffffc0204f76:	e79c                	sd	a5,8(a5)
ffffffffc0204f78:	e39c                	sd	a5,0(a5)
ffffffffc0204f7a:	07c1                	addi	a5,a5,16
ffffffffc0204f7c:	fee79de3          	bne	a5,a4,ffffffffc0204f76 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204f80:	eb5fe0ef          	jal	ffffffffc0203e34 <alloc_proc>
ffffffffc0204f84:	00096917          	auipc	s2,0x96
ffffffffc0204f88:	70c90913          	addi	s2,s2,1804 # ffffffffc029b690 <idleproc>
ffffffffc0204f8c:	00a93023          	sd	a0,0(s2)
ffffffffc0204f90:	10050863          	beqz	a0,ffffffffc02050a0 <proc_init+0x152>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204f94:	4789                	li	a5,2
ffffffffc0204f96:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
    idleproc->pgdir = boot_pgdir_pa;
ffffffffc0204f98:	00096797          	auipc	a5,0x96
ffffffffc0204f9c:	6b87b783          	ld	a5,1720(a5) # ffffffffc029b650 <boot_pgdir_pa>
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204fa0:	00003717          	auipc	a4,0x3
ffffffffc0204fa4:	06070713          	addi	a4,a4,96 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fa8:	0b450413          	addi	s0,a0,180
    idleproc->pgdir = boot_pgdir_pa;
ffffffffc0204fac:	f55c                	sd	a5,168(a0)
    idleproc->need_resched = 1;
ffffffffc0204fae:	4785                	li	a5,1
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204fb0:	e918                	sd	a4,16(a0)
    idleproc->need_resched = 1;
ffffffffc0204fb2:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204fb4:	4641                	li	a2,16
ffffffffc0204fb6:	8522                	mv	a0,s0
ffffffffc0204fb8:	4581                	li	a1,0
ffffffffc0204fba:	055000ef          	jal	ffffffffc020580e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204fbe:	8522                	mv	a0,s0
ffffffffc0204fc0:	463d                	li	a2,15
ffffffffc0204fc2:	00002597          	auipc	a1,0x2
ffffffffc0204fc6:	3c658593          	addi	a1,a1,966 # ffffffffc0207388 <etext+0x1b50>
ffffffffc0204fca:	057000ef          	jal	ffffffffc0205820 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204fce:	00096797          	auipc	a5,0x96
ffffffffc0204fd2:	6aa7a783          	lw	a5,1706(a5) # ffffffffc029b678 <nr_process>

    current = idleproc;
ffffffffc0204fd6:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204fda:	4601                	li	a2,0
    nr_process++;
ffffffffc0204fdc:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204fde:	4581                	li	a1,0
ffffffffc0204fe0:	fffff517          	auipc	a0,0xfffff
ffffffffc0204fe4:	7ec50513          	addi	a0,a0,2028 # ffffffffc02047cc <init_main>
    current = idleproc;
ffffffffc0204fe8:	00096697          	auipc	a3,0x96
ffffffffc0204fec:	68e6bc23          	sd	a4,1688(a3) # ffffffffc029b680 <current>
    nr_process++;
ffffffffc0204ff0:	00096717          	auipc	a4,0x96
ffffffffc0204ff4:	68f72423          	sw	a5,1672(a4) # ffffffffc029b678 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204ff8:	c5eff0ef          	jal	ffffffffc0204456 <kernel_thread>
ffffffffc0204ffc:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204ffe:	08a05563          	blez	a0,ffffffffc0205088 <proc_init+0x13a>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205002:	6789                	lui	a5,0x2
ffffffffc0205004:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6bb2>
ffffffffc0205006:	fff5071b          	addiw	a4,a0,-1
ffffffffc020500a:	02e7e463          	bltu	a5,a4,ffffffffc0205032 <proc_init+0xe4>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020500e:	45a9                	li	a1,10
ffffffffc0205010:	368000ef          	jal	ffffffffc0205378 <hash32>
ffffffffc0205014:	02051713          	slli	a4,a0,0x20
ffffffffc0205018:	01c75793          	srli	a5,a4,0x1c
ffffffffc020501c:	00f486b3          	add	a3,s1,a5
ffffffffc0205020:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0205022:	a029                	j	ffffffffc020502c <proc_init+0xde>
            if (proc->pid == pid)
ffffffffc0205024:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205028:	04870d63          	beq	a4,s0,ffffffffc0205082 <proc_init+0x134>
    return listelm->next;
ffffffffc020502c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020502e:	fef69be3          	bne	a3,a5,ffffffffc0205024 <proc_init+0xd6>
    return NULL;
ffffffffc0205032:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205034:	0b478413          	addi	s0,a5,180
ffffffffc0205038:	4641                	li	a2,16
ffffffffc020503a:	4581                	li	a1,0
ffffffffc020503c:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc020503e:	00096717          	auipc	a4,0x96
ffffffffc0205042:	64f73523          	sd	a5,1610(a4) # ffffffffc029b688 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205046:	7c8000ef          	jal	ffffffffc020580e <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020504a:	8522                	mv	a0,s0
ffffffffc020504c:	463d                	li	a2,15
ffffffffc020504e:	00002597          	auipc	a1,0x2
ffffffffc0205052:	36258593          	addi	a1,a1,866 # ffffffffc02073b0 <etext+0x1b78>
ffffffffc0205056:	7ca000ef          	jal	ffffffffc0205820 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020505a:	00093783          	ld	a5,0(s2)
ffffffffc020505e:	cfad                	beqz	a5,ffffffffc02050d8 <proc_init+0x18a>
ffffffffc0205060:	43dc                	lw	a5,4(a5)
ffffffffc0205062:	ebbd                	bnez	a5,ffffffffc02050d8 <proc_init+0x18a>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205064:	00096797          	auipc	a5,0x96
ffffffffc0205068:	6247b783          	ld	a5,1572(a5) # ffffffffc029b688 <initproc>
ffffffffc020506c:	c7b1                	beqz	a5,ffffffffc02050b8 <proc_init+0x16a>
ffffffffc020506e:	43d8                	lw	a4,4(a5)
ffffffffc0205070:	4785                	li	a5,1
ffffffffc0205072:	04f71363          	bne	a4,a5,ffffffffc02050b8 <proc_init+0x16a>
}
ffffffffc0205076:	60e2                	ld	ra,24(sp)
ffffffffc0205078:	6442                	ld	s0,16(sp)
ffffffffc020507a:	64a2                	ld	s1,8(sp)
ffffffffc020507c:	6902                	ld	s2,0(sp)
ffffffffc020507e:	6105                	addi	sp,sp,32
ffffffffc0205080:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205082:	f2878793          	addi	a5,a5,-216
ffffffffc0205086:	b77d                	j	ffffffffc0205034 <proc_init+0xe6>
        panic("create init_main failed.\n");
ffffffffc0205088:	00002617          	auipc	a2,0x2
ffffffffc020508c:	30860613          	addi	a2,a2,776 # ffffffffc0207390 <etext+0x1b58>
ffffffffc0205090:	3f700593          	li	a1,1015
ffffffffc0205094:	00002517          	auipc	a0,0x2
ffffffffc0205098:	f6c50513          	addi	a0,a0,-148 # ffffffffc0207000 <etext+0x17c8>
ffffffffc020509c:	baafb0ef          	jal	ffffffffc0200446 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc02050a0:	00002617          	auipc	a2,0x2
ffffffffc02050a4:	2d060613          	addi	a2,a2,720 # ffffffffc0207370 <etext+0x1b38>
ffffffffc02050a8:	3e700593          	li	a1,999
ffffffffc02050ac:	00002517          	auipc	a0,0x2
ffffffffc02050b0:	f5450513          	addi	a0,a0,-172 # ffffffffc0207000 <etext+0x17c8>
ffffffffc02050b4:	b92fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050b8:	00002697          	auipc	a3,0x2
ffffffffc02050bc:	32868693          	addi	a3,a3,808 # ffffffffc02073e0 <etext+0x1ba8>
ffffffffc02050c0:	00001617          	auipc	a2,0x1
ffffffffc02050c4:	15860613          	addi	a2,a2,344 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02050c8:	3fe00593          	li	a1,1022
ffffffffc02050cc:	00002517          	auipc	a0,0x2
ffffffffc02050d0:	f3450513          	addi	a0,a0,-204 # ffffffffc0207000 <etext+0x17c8>
ffffffffc02050d4:	b72fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050d8:	00002697          	auipc	a3,0x2
ffffffffc02050dc:	2e068693          	addi	a3,a3,736 # ffffffffc02073b8 <etext+0x1b80>
ffffffffc02050e0:	00001617          	auipc	a2,0x1
ffffffffc02050e4:	13860613          	addi	a2,a2,312 # ffffffffc0206218 <etext+0x9e0>
ffffffffc02050e8:	3fd00593          	li	a1,1021
ffffffffc02050ec:	00002517          	auipc	a0,0x2
ffffffffc02050f0:	f1450513          	addi	a0,a0,-236 # ffffffffc0207000 <etext+0x17c8>
ffffffffc02050f4:	b52fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02050f8 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02050f8:	1141                	addi	sp,sp,-16
ffffffffc02050fa:	e022                	sd	s0,0(sp)
ffffffffc02050fc:	e406                	sd	ra,8(sp)
ffffffffc02050fe:	00096417          	auipc	s0,0x96
ffffffffc0205102:	58240413          	addi	s0,s0,1410 # ffffffffc029b680 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205106:	6018                	ld	a4,0(s0)
ffffffffc0205108:	6f1c                	ld	a5,24(a4)
ffffffffc020510a:	dffd                	beqz	a5,ffffffffc0205108 <cpu_idle+0x10>
        {
            schedule();
ffffffffc020510c:	104000ef          	jal	ffffffffc0205210 <schedule>
ffffffffc0205110:	bfdd                	j	ffffffffc0205106 <cpu_idle+0xe>

ffffffffc0205112 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205112:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205116:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc020511a:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc020511c:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc020511e:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205122:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205126:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc020512a:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020512e:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205132:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205136:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020513a:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020513e:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205142:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205146:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020514a:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020514e:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205150:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205152:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205156:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020515a:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020515e:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205162:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205166:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020516a:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020516e:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205172:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205176:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020517a:	8082                	ret

ffffffffc020517c <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020517c:	4118                	lw	a4,0(a0)
{
ffffffffc020517e:	1101                	addi	sp,sp,-32
ffffffffc0205180:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205182:	478d                	li	a5,3
ffffffffc0205184:	06f70763          	beq	a4,a5,ffffffffc02051f2 <wakeup_proc+0x76>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205188:	100027f3          	csrr	a5,sstatus
ffffffffc020518c:	8b89                	andi	a5,a5,2
ffffffffc020518e:	eb91                	bnez	a5,ffffffffc02051a2 <wakeup_proc+0x26>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205190:	4789                	li	a5,2
ffffffffc0205192:	02f70763          	beq	a4,a5,ffffffffc02051c0 <wakeup_proc+0x44>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205196:	60e2                	ld	ra,24(sp)
            proc->state = PROC_RUNNABLE;
ffffffffc0205198:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc020519a:	0e052623          	sw	zero,236(a0)
}
ffffffffc020519e:	6105                	addi	sp,sp,32
ffffffffc02051a0:	8082                	ret
        intr_disable();
ffffffffc02051a2:	e42a                	sd	a0,8(sp)
ffffffffc02051a4:	f60fb0ef          	jal	ffffffffc0200904 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc02051a8:	6522                	ld	a0,8(sp)
ffffffffc02051aa:	4789                	li	a5,2
ffffffffc02051ac:	4118                	lw	a4,0(a0)
ffffffffc02051ae:	02f70663          	beq	a4,a5,ffffffffc02051da <wakeup_proc+0x5e>
            proc->state = PROC_RUNNABLE;
ffffffffc02051b2:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc02051b4:	0e052623          	sw	zero,236(a0)
}
ffffffffc02051b8:	60e2                	ld	ra,24(sp)
ffffffffc02051ba:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02051bc:	f42fb06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc02051c0:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc02051c2:	00002617          	auipc	a2,0x2
ffffffffc02051c6:	27e60613          	addi	a2,a2,638 # ffffffffc0207440 <etext+0x1c08>
ffffffffc02051ca:	45d1                	li	a1,20
ffffffffc02051cc:	00002517          	auipc	a0,0x2
ffffffffc02051d0:	25c50513          	addi	a0,a0,604 # ffffffffc0207428 <etext+0x1bf0>
}
ffffffffc02051d4:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc02051d6:	adafb06f          	j	ffffffffc02004b0 <__warn>
ffffffffc02051da:	00002617          	auipc	a2,0x2
ffffffffc02051de:	26660613          	addi	a2,a2,614 # ffffffffc0207440 <etext+0x1c08>
ffffffffc02051e2:	45d1                	li	a1,20
ffffffffc02051e4:	00002517          	auipc	a0,0x2
ffffffffc02051e8:	24450513          	addi	a0,a0,580 # ffffffffc0207428 <etext+0x1bf0>
ffffffffc02051ec:	ac4fb0ef          	jal	ffffffffc02004b0 <__warn>
    if (flag)
ffffffffc02051f0:	b7e1                	j	ffffffffc02051b8 <wakeup_proc+0x3c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051f2:	00002697          	auipc	a3,0x2
ffffffffc02051f6:	21668693          	addi	a3,a3,534 # ffffffffc0207408 <etext+0x1bd0>
ffffffffc02051fa:	00001617          	auipc	a2,0x1
ffffffffc02051fe:	01e60613          	addi	a2,a2,30 # ffffffffc0206218 <etext+0x9e0>
ffffffffc0205202:	45a5                	li	a1,9
ffffffffc0205204:	00002517          	auipc	a0,0x2
ffffffffc0205208:	22450513          	addi	a0,a0,548 # ffffffffc0207428 <etext+0x1bf0>
ffffffffc020520c:	a3afb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205210 <schedule>:

void schedule(void)
{
ffffffffc0205210:	1101                	addi	sp,sp,-32
ffffffffc0205212:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205214:	100027f3          	csrr	a5,sstatus
ffffffffc0205218:	8b89                	andi	a5,a5,2
ffffffffc020521a:	4301                	li	t1,0
ffffffffc020521c:	e3c1                	bnez	a5,ffffffffc020529c <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc020521e:	00096897          	auipc	a7,0x96
ffffffffc0205222:	4628b883          	ld	a7,1122(a7) # ffffffffc029b680 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205226:	00096517          	auipc	a0,0x96
ffffffffc020522a:	46a53503          	ld	a0,1130(a0) # ffffffffc029b690 <idleproc>
        current->need_resched = 0;
ffffffffc020522e:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205232:	04a88f63          	beq	a7,a0,ffffffffc0205290 <schedule+0x80>
ffffffffc0205236:	0c888693          	addi	a3,a7,200
ffffffffc020523a:	00096617          	auipc	a2,0x96
ffffffffc020523e:	3ce60613          	addi	a2,a2,974 # ffffffffc029b608 <proc_list>
        le = last;
ffffffffc0205242:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205244:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205246:	4809                	li	a6,2
ffffffffc0205248:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc020524a:	00c78863          	beq	a5,a2,ffffffffc020525a <schedule+0x4a>
                if (next->state == PROC_RUNNABLE)
ffffffffc020524e:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205252:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205256:	03070363          	beq	a4,a6,ffffffffc020527c <schedule+0x6c>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc020525a:	fef697e3          	bne	a3,a5,ffffffffc0205248 <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020525e:	ed99                	bnez	a1,ffffffffc020527c <schedule+0x6c>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc0205260:	451c                	lw	a5,8(a0)
ffffffffc0205262:	2785                	addiw	a5,a5,1
ffffffffc0205264:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205266:	00a88663          	beq	a7,a0,ffffffffc0205272 <schedule+0x62>
ffffffffc020526a:	e41a                	sd	t1,8(sp)
        {
            proc_run(next);
ffffffffc020526c:	d37fe0ef          	jal	ffffffffc0203fa2 <proc_run>
ffffffffc0205270:	6322                	ld	t1,8(sp)
    if (flag)
ffffffffc0205272:	00031b63          	bnez	t1,ffffffffc0205288 <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205276:	60e2                	ld	ra,24(sp)
ffffffffc0205278:	6105                	addi	sp,sp,32
ffffffffc020527a:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020527c:	4198                	lw	a4,0(a1)
ffffffffc020527e:	4789                	li	a5,2
ffffffffc0205280:	fef710e3          	bne	a4,a5,ffffffffc0205260 <schedule+0x50>
ffffffffc0205284:	852e                	mv	a0,a1
ffffffffc0205286:	bfe9                	j	ffffffffc0205260 <schedule+0x50>
}
ffffffffc0205288:	60e2                	ld	ra,24(sp)
ffffffffc020528a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020528c:	e72fb06f          	j	ffffffffc02008fe <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205290:	00096617          	auipc	a2,0x96
ffffffffc0205294:	37860613          	addi	a2,a2,888 # ffffffffc029b608 <proc_list>
ffffffffc0205298:	86b2                	mv	a3,a2
ffffffffc020529a:	b765                	j	ffffffffc0205242 <schedule+0x32>
        intr_disable();
ffffffffc020529c:	e68fb0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02052a0:	4305                	li	t1,1
ffffffffc02052a2:	bfb5                	j	ffffffffc020521e <schedule+0xe>

ffffffffc02052a4 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02052a4:	00096797          	auipc	a5,0x96
ffffffffc02052a8:	3dc7b783          	ld	a5,988(a5) # ffffffffc029b680 <current>
}
ffffffffc02052ac:	43c8                	lw	a0,4(a5)
ffffffffc02052ae:	8082                	ret

ffffffffc02052b0 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02052b0:	4501                	li	a0,0
ffffffffc02052b2:	8082                	ret

ffffffffc02052b4 <sys_putc>:
    cputchar(c);
ffffffffc02052b4:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02052b6:	1141                	addi	sp,sp,-16
ffffffffc02052b8:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02052ba:	f0ffa0ef          	jal	ffffffffc02001c8 <cputchar>
}
ffffffffc02052be:	60a2                	ld	ra,8(sp)
ffffffffc02052c0:	4501                	li	a0,0
ffffffffc02052c2:	0141                	addi	sp,sp,16
ffffffffc02052c4:	8082                	ret

ffffffffc02052c6 <sys_kill>:
    return do_kill(pid);
ffffffffc02052c6:	4108                	lw	a0,0(a0)
ffffffffc02052c8:	c0fff06f          	j	ffffffffc0204ed6 <do_kill>

ffffffffc02052cc <sys_yield>:
    return do_yield();
ffffffffc02052cc:	bc1ff06f          	j	ffffffffc0204e8c <do_yield>

ffffffffc02052d0 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02052d0:	6d14                	ld	a3,24(a0)
ffffffffc02052d2:	6910                	ld	a2,16(a0)
ffffffffc02052d4:	650c                	ld	a1,8(a0)
ffffffffc02052d6:	6108                	ld	a0,0(a0)
ffffffffc02052d8:	e18ff06f          	j	ffffffffc02048f0 <do_execve>

ffffffffc02052dc <sys_wait>:
    return do_wait(pid, store);
ffffffffc02052dc:	650c                	ld	a1,8(a0)
ffffffffc02052de:	4108                	lw	a0,0(a0)
ffffffffc02052e0:	bbdff06f          	j	ffffffffc0204e9c <do_wait>

ffffffffc02052e4 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02052e4:	00096797          	auipc	a5,0x96
ffffffffc02052e8:	39c7b783          	ld	a5,924(a5) # ffffffffc029b680 <current>
    return do_fork(0, stack, tf);
ffffffffc02052ec:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc02052ee:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02052f0:	6a0c                	ld	a1,16(a2)
ffffffffc02052f2:	d13fe06f          	j	ffffffffc0204004 <do_fork>

ffffffffc02052f6 <sys_exit>:
    return do_exit(error_code);
ffffffffc02052f6:	4108                	lw	a0,0(a0)
ffffffffc02052f8:	9aeff06f          	j	ffffffffc02044a6 <do_exit>

ffffffffc02052fc <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc02052fc:	00096697          	auipc	a3,0x96
ffffffffc0205300:	3846b683          	ld	a3,900(a3) # ffffffffc029b680 <current>
syscall(void) {
ffffffffc0205304:	715d                	addi	sp,sp,-80
ffffffffc0205306:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc0205308:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc020530a:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020530c:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc020530e:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0205310:	02d7ec63          	bltu	a5,a3,ffffffffc0205348 <syscall+0x4c>
        if (syscalls[num] != NULL) {
ffffffffc0205314:	00002797          	auipc	a5,0x2
ffffffffc0205318:	37478793          	addi	a5,a5,884 # ffffffffc0207688 <syscalls>
ffffffffc020531c:	00369613          	slli	a2,a3,0x3
ffffffffc0205320:	97b2                	add	a5,a5,a2
ffffffffc0205322:	639c                	ld	a5,0(a5)
ffffffffc0205324:	c395                	beqz	a5,ffffffffc0205348 <syscall+0x4c>
            arg[0] = tf->gpr.a1;
ffffffffc0205326:	7028                	ld	a0,96(s0)
ffffffffc0205328:	742c                	ld	a1,104(s0)
ffffffffc020532a:	7830                	ld	a2,112(s0)
ffffffffc020532c:	7c34                	ld	a3,120(s0)
ffffffffc020532e:	6c38                	ld	a4,88(s0)
ffffffffc0205330:	f02a                	sd	a0,32(sp)
ffffffffc0205332:	f42e                	sd	a1,40(sp)
ffffffffc0205334:	f832                	sd	a2,48(sp)
ffffffffc0205336:	fc36                	sd	a3,56(sp)
ffffffffc0205338:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020533a:	0828                	addi	a0,sp,24
ffffffffc020533c:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020533e:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205340:	e828                	sd	a0,80(s0)
}
ffffffffc0205342:	6406                	ld	s0,64(sp)
ffffffffc0205344:	6161                	addi	sp,sp,80
ffffffffc0205346:	8082                	ret
    print_trapframe(tf);
ffffffffc0205348:	8522                	mv	a0,s0
ffffffffc020534a:	e436                	sd	a3,8(sp)
ffffffffc020534c:	fa8fb0ef          	jal	ffffffffc0200af4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205350:	00096797          	auipc	a5,0x96
ffffffffc0205354:	3307b783          	ld	a5,816(a5) # ffffffffc029b680 <current>
ffffffffc0205358:	66a2                	ld	a3,8(sp)
ffffffffc020535a:	00002617          	auipc	a2,0x2
ffffffffc020535e:	10660613          	addi	a2,a2,262 # ffffffffc0207460 <etext+0x1c28>
ffffffffc0205362:	43d8                	lw	a4,4(a5)
ffffffffc0205364:	06200593          	li	a1,98
ffffffffc0205368:	0b478793          	addi	a5,a5,180
ffffffffc020536c:	00002517          	auipc	a0,0x2
ffffffffc0205370:	12450513          	addi	a0,a0,292 # ffffffffc0207490 <etext+0x1c58>
ffffffffc0205374:	8d2fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205378 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205378:	9e3707b7          	lui	a5,0x9e370
ffffffffc020537c:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_exit_out_size+0xffffffff9e365e49>
ffffffffc020537e:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205382:	02000513          	li	a0,32
ffffffffc0205386:	9d0d                	subw	a0,a0,a1
}
ffffffffc0205388:	00a7d53b          	srlw	a0,a5,a0
ffffffffc020538c:	8082                	ret

ffffffffc020538e <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020538e:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205390:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205394:	f022                	sd	s0,32(sp)
ffffffffc0205396:	ec26                	sd	s1,24(sp)
ffffffffc0205398:	e84a                	sd	s2,16(sp)
ffffffffc020539a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020539c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053a0:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc02053a2:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02053a6:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02053aa:	84aa                	mv	s1,a0
ffffffffc02053ac:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc02053ae:	03067d63          	bgeu	a2,a6,ffffffffc02053e8 <printnum+0x5a>
ffffffffc02053b2:	e44e                	sd	s3,8(sp)
ffffffffc02053b4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02053b6:	4785                	li	a5,1
ffffffffc02053b8:	00e7d763          	bge	a5,a4,ffffffffc02053c6 <printnum+0x38>
            putch(padc, putdat);
ffffffffc02053bc:	85ca                	mv	a1,s2
ffffffffc02053be:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02053c0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02053c2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02053c4:	fc65                	bnez	s0,ffffffffc02053bc <printnum+0x2e>
ffffffffc02053c6:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053c8:	00002797          	auipc	a5,0x2
ffffffffc02053cc:	0e078793          	addi	a5,a5,224 # ffffffffc02074a8 <etext+0x1c70>
ffffffffc02053d0:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02053d2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053d4:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02053d8:	70a2                	ld	ra,40(sp)
ffffffffc02053da:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053dc:	85ca                	mv	a1,s2
ffffffffc02053de:	87a6                	mv	a5,s1
}
ffffffffc02053e0:	6942                	ld	s2,16(sp)
ffffffffc02053e2:	64e2                	ld	s1,24(sp)
ffffffffc02053e4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053e6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02053e8:	03065633          	divu	a2,a2,a6
ffffffffc02053ec:	8722                	mv	a4,s0
ffffffffc02053ee:	fa1ff0ef          	jal	ffffffffc020538e <printnum>
ffffffffc02053f2:	bfd9                	j	ffffffffc02053c8 <printnum+0x3a>

ffffffffc02053f4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02053f4:	7119                	addi	sp,sp,-128
ffffffffc02053f6:	f4a6                	sd	s1,104(sp)
ffffffffc02053f8:	f0ca                	sd	s2,96(sp)
ffffffffc02053fa:	ecce                	sd	s3,88(sp)
ffffffffc02053fc:	e8d2                	sd	s4,80(sp)
ffffffffc02053fe:	e4d6                	sd	s5,72(sp)
ffffffffc0205400:	e0da                	sd	s6,64(sp)
ffffffffc0205402:	f862                	sd	s8,48(sp)
ffffffffc0205404:	fc86                	sd	ra,120(sp)
ffffffffc0205406:	f8a2                	sd	s0,112(sp)
ffffffffc0205408:	fc5e                	sd	s7,56(sp)
ffffffffc020540a:	f466                	sd	s9,40(sp)
ffffffffc020540c:	f06a                	sd	s10,32(sp)
ffffffffc020540e:	ec6e                	sd	s11,24(sp)
ffffffffc0205410:	84aa                	mv	s1,a0
ffffffffc0205412:	8c32                	mv	s8,a2
ffffffffc0205414:	8a36                	mv	s4,a3
ffffffffc0205416:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205418:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020541c:	05500b13          	li	s6,85
ffffffffc0205420:	00002a97          	auipc	s5,0x2
ffffffffc0205424:	368a8a93          	addi	s5,s5,872 # ffffffffc0207788 <syscalls+0x100>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205428:	000c4503          	lbu	a0,0(s8)
ffffffffc020542c:	001c0413          	addi	s0,s8,1
ffffffffc0205430:	01350a63          	beq	a0,s3,ffffffffc0205444 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0205434:	cd0d                	beqz	a0,ffffffffc020546e <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0205436:	85ca                	mv	a1,s2
ffffffffc0205438:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020543a:	00044503          	lbu	a0,0(s0)
ffffffffc020543e:	0405                	addi	s0,s0,1
ffffffffc0205440:	ff351ae3          	bne	a0,s3,ffffffffc0205434 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0205444:	5cfd                	li	s9,-1
ffffffffc0205446:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0205448:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc020544c:	4b81                	li	s7,0
ffffffffc020544e:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205450:	00044683          	lbu	a3,0(s0)
ffffffffc0205454:	00140c13          	addi	s8,s0,1
ffffffffc0205458:	fdd6859b          	addiw	a1,a3,-35
ffffffffc020545c:	0ff5f593          	zext.b	a1,a1
ffffffffc0205460:	02bb6663          	bltu	s6,a1,ffffffffc020548c <vprintfmt+0x98>
ffffffffc0205464:	058a                	slli	a1,a1,0x2
ffffffffc0205466:	95d6                	add	a1,a1,s5
ffffffffc0205468:	4198                	lw	a4,0(a1)
ffffffffc020546a:	9756                	add	a4,a4,s5
ffffffffc020546c:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020546e:	70e6                	ld	ra,120(sp)
ffffffffc0205470:	7446                	ld	s0,112(sp)
ffffffffc0205472:	74a6                	ld	s1,104(sp)
ffffffffc0205474:	7906                	ld	s2,96(sp)
ffffffffc0205476:	69e6                	ld	s3,88(sp)
ffffffffc0205478:	6a46                	ld	s4,80(sp)
ffffffffc020547a:	6aa6                	ld	s5,72(sp)
ffffffffc020547c:	6b06                	ld	s6,64(sp)
ffffffffc020547e:	7be2                	ld	s7,56(sp)
ffffffffc0205480:	7c42                	ld	s8,48(sp)
ffffffffc0205482:	7ca2                	ld	s9,40(sp)
ffffffffc0205484:	7d02                	ld	s10,32(sp)
ffffffffc0205486:	6de2                	ld	s11,24(sp)
ffffffffc0205488:	6109                	addi	sp,sp,128
ffffffffc020548a:	8082                	ret
            putch('%', putdat);
ffffffffc020548c:	85ca                	mv	a1,s2
ffffffffc020548e:	02500513          	li	a0,37
ffffffffc0205492:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205494:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205498:	02500713          	li	a4,37
ffffffffc020549c:	8c22                	mv	s8,s0
ffffffffc020549e:	f8e785e3          	beq	a5,a4,ffffffffc0205428 <vprintfmt+0x34>
ffffffffc02054a2:	ffec4783          	lbu	a5,-2(s8)
ffffffffc02054a6:	1c7d                	addi	s8,s8,-1
ffffffffc02054a8:	fee79de3          	bne	a5,a4,ffffffffc02054a2 <vprintfmt+0xae>
ffffffffc02054ac:	bfb5                	j	ffffffffc0205428 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc02054ae:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc02054b2:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc02054b4:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc02054b8:	fd06071b          	addiw	a4,a2,-48
ffffffffc02054bc:	24e56a63          	bltu	a0,a4,ffffffffc0205710 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc02054c0:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054c2:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc02054c4:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc02054c8:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02054cc:	0197073b          	addw	a4,a4,s9
ffffffffc02054d0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02054d4:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc02054d6:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02054da:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02054dc:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02054e0:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc02054e4:	feb570e3          	bgeu	a0,a1,ffffffffc02054c4 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc02054e8:	f60d54e3          	bgez	s10,ffffffffc0205450 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02054ec:	8d66                	mv	s10,s9
ffffffffc02054ee:	5cfd                	li	s9,-1
ffffffffc02054f0:	b785                	j	ffffffffc0205450 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054f2:	8db6                	mv	s11,a3
ffffffffc02054f4:	8462                	mv	s0,s8
ffffffffc02054f6:	bfa9                	j	ffffffffc0205450 <vprintfmt+0x5c>
ffffffffc02054f8:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc02054fa:	4b85                	li	s7,1
            goto reswitch;
ffffffffc02054fc:	bf91                	j	ffffffffc0205450 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02054fe:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205500:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205504:	00f74463          	blt	a4,a5,ffffffffc020550c <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0205508:	1a078763          	beqz	a5,ffffffffc02056b6 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc020550c:	000a3603          	ld	a2,0(s4)
ffffffffc0205510:	46c1                	li	a3,16
ffffffffc0205512:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0205514:	000d879b          	sext.w	a5,s11
ffffffffc0205518:	876a                	mv	a4,s10
ffffffffc020551a:	85ca                	mv	a1,s2
ffffffffc020551c:	8526                	mv	a0,s1
ffffffffc020551e:	e71ff0ef          	jal	ffffffffc020538e <printnum>
            break;
ffffffffc0205522:	b719                	j	ffffffffc0205428 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0205524:	000a2503          	lw	a0,0(s4)
ffffffffc0205528:	85ca                	mv	a1,s2
ffffffffc020552a:	0a21                	addi	s4,s4,8
ffffffffc020552c:	9482                	jalr	s1
            break;
ffffffffc020552e:	bded                	j	ffffffffc0205428 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0205530:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205532:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205536:	00f74463          	blt	a4,a5,ffffffffc020553e <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc020553a:	16078963          	beqz	a5,ffffffffc02056ac <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc020553e:	000a3603          	ld	a2,0(s4)
ffffffffc0205542:	46a9                	li	a3,10
ffffffffc0205544:	8a2e                	mv	s4,a1
ffffffffc0205546:	b7f9                	j	ffffffffc0205514 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0205548:	85ca                	mv	a1,s2
ffffffffc020554a:	03000513          	li	a0,48
ffffffffc020554e:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0205550:	85ca                	mv	a1,s2
ffffffffc0205552:	07800513          	li	a0,120
ffffffffc0205556:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205558:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020555c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020555e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205560:	bf55                	j	ffffffffc0205514 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0205562:	85ca                	mv	a1,s2
ffffffffc0205564:	02500513          	li	a0,37
ffffffffc0205568:	9482                	jalr	s1
            break;
ffffffffc020556a:	bd7d                	j	ffffffffc0205428 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc020556c:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205570:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0205572:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0205574:	bf95                	j	ffffffffc02054e8 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0205576:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205578:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020557c:	00f74463          	blt	a4,a5,ffffffffc0205584 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0205580:	12078163          	beqz	a5,ffffffffc02056a2 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0205584:	000a3603          	ld	a2,0(s4)
ffffffffc0205588:	46a1                	li	a3,8
ffffffffc020558a:	8a2e                	mv	s4,a1
ffffffffc020558c:	b761                	j	ffffffffc0205514 <vprintfmt+0x120>
            if (width < 0)
ffffffffc020558e:	876a                	mv	a4,s10
ffffffffc0205590:	000d5363          	bgez	s10,ffffffffc0205596 <vprintfmt+0x1a2>
ffffffffc0205594:	4701                	li	a4,0
ffffffffc0205596:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020559a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020559c:	bd55                	j	ffffffffc0205450 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc020559e:	000d841b          	sext.w	s0,s11
ffffffffc02055a2:	fd340793          	addi	a5,s0,-45
ffffffffc02055a6:	00f037b3          	snez	a5,a5
ffffffffc02055aa:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055ae:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc02055b2:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055b4:	008a0793          	addi	a5,s4,8
ffffffffc02055b8:	e43e                	sd	a5,8(sp)
ffffffffc02055ba:	100d8c63          	beqz	s11,ffffffffc02056d2 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc02055be:	12071363          	bnez	a4,ffffffffc02056e4 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055c2:	000dc783          	lbu	a5,0(s11)
ffffffffc02055c6:	0007851b          	sext.w	a0,a5
ffffffffc02055ca:	c78d                	beqz	a5,ffffffffc02055f4 <vprintfmt+0x200>
ffffffffc02055cc:	0d85                	addi	s11,s11,1
ffffffffc02055ce:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055d0:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055d4:	000cc563          	bltz	s9,ffffffffc02055de <vprintfmt+0x1ea>
ffffffffc02055d8:	3cfd                	addiw	s9,s9,-1
ffffffffc02055da:	008c8d63          	beq	s9,s0,ffffffffc02055f4 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055de:	020b9663          	bnez	s7,ffffffffc020560a <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc02055e2:	85ca                	mv	a1,s2
ffffffffc02055e4:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055e6:	000dc783          	lbu	a5,0(s11)
ffffffffc02055ea:	0d85                	addi	s11,s11,1
ffffffffc02055ec:	3d7d                	addiw	s10,s10,-1
ffffffffc02055ee:	0007851b          	sext.w	a0,a5
ffffffffc02055f2:	f3ed                	bnez	a5,ffffffffc02055d4 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc02055f4:	01a05963          	blez	s10,ffffffffc0205606 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc02055f8:	85ca                	mv	a1,s2
ffffffffc02055fa:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02055fe:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0205600:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0205602:	fe0d1be3          	bnez	s10,ffffffffc02055f8 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205606:	6a22                	ld	s4,8(sp)
ffffffffc0205608:	b505                	j	ffffffffc0205428 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020560a:	3781                	addiw	a5,a5,-32
ffffffffc020560c:	fcfa7be3          	bgeu	s4,a5,ffffffffc02055e2 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0205610:	03f00513          	li	a0,63
ffffffffc0205614:	85ca                	mv	a1,s2
ffffffffc0205616:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205618:	000dc783          	lbu	a5,0(s11)
ffffffffc020561c:	0d85                	addi	s11,s11,1
ffffffffc020561e:	3d7d                	addiw	s10,s10,-1
ffffffffc0205620:	0007851b          	sext.w	a0,a5
ffffffffc0205624:	dbe1                	beqz	a5,ffffffffc02055f4 <vprintfmt+0x200>
ffffffffc0205626:	fa0cd9e3          	bgez	s9,ffffffffc02055d8 <vprintfmt+0x1e4>
ffffffffc020562a:	b7c5                	j	ffffffffc020560a <vprintfmt+0x216>
            if (err < 0) {
ffffffffc020562c:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205630:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc0205632:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205634:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0205638:	8fb9                	xor	a5,a5,a4
ffffffffc020563a:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020563e:	02d64563          	blt	a2,a3,ffffffffc0205668 <vprintfmt+0x274>
ffffffffc0205642:	00002797          	auipc	a5,0x2
ffffffffc0205646:	29e78793          	addi	a5,a5,670 # ffffffffc02078e0 <error_string>
ffffffffc020564a:	00369713          	slli	a4,a3,0x3
ffffffffc020564e:	97ba                	add	a5,a5,a4
ffffffffc0205650:	639c                	ld	a5,0(a5)
ffffffffc0205652:	cb99                	beqz	a5,ffffffffc0205668 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205654:	86be                	mv	a3,a5
ffffffffc0205656:	00000617          	auipc	a2,0x0
ffffffffc020565a:	20a60613          	addi	a2,a2,522 # ffffffffc0205860 <etext+0x28>
ffffffffc020565e:	85ca                	mv	a1,s2
ffffffffc0205660:	8526                	mv	a0,s1
ffffffffc0205662:	0d8000ef          	jal	ffffffffc020573a <printfmt>
ffffffffc0205666:	b3c9                	j	ffffffffc0205428 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205668:	00002617          	auipc	a2,0x2
ffffffffc020566c:	e6060613          	addi	a2,a2,-416 # ffffffffc02074c8 <etext+0x1c90>
ffffffffc0205670:	85ca                	mv	a1,s2
ffffffffc0205672:	8526                	mv	a0,s1
ffffffffc0205674:	0c6000ef          	jal	ffffffffc020573a <printfmt>
ffffffffc0205678:	bb45                	j	ffffffffc0205428 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020567a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020567c:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0205680:	00f74363          	blt	a4,a5,ffffffffc0205686 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0205684:	cf81                	beqz	a5,ffffffffc020569c <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0205686:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020568a:	02044b63          	bltz	s0,ffffffffc02056c0 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc020568e:	8622                	mv	a2,s0
ffffffffc0205690:	8a5e                	mv	s4,s7
ffffffffc0205692:	46a9                	li	a3,10
ffffffffc0205694:	b541                	j	ffffffffc0205514 <vprintfmt+0x120>
            lflag ++;
ffffffffc0205696:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205698:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020569a:	bb5d                	j	ffffffffc0205450 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc020569c:	000a2403          	lw	s0,0(s4)
ffffffffc02056a0:	b7ed                	j	ffffffffc020568a <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc02056a2:	000a6603          	lwu	a2,0(s4)
ffffffffc02056a6:	46a1                	li	a3,8
ffffffffc02056a8:	8a2e                	mv	s4,a1
ffffffffc02056aa:	b5ad                	j	ffffffffc0205514 <vprintfmt+0x120>
ffffffffc02056ac:	000a6603          	lwu	a2,0(s4)
ffffffffc02056b0:	46a9                	li	a3,10
ffffffffc02056b2:	8a2e                	mv	s4,a1
ffffffffc02056b4:	b585                	j	ffffffffc0205514 <vprintfmt+0x120>
ffffffffc02056b6:	000a6603          	lwu	a2,0(s4)
ffffffffc02056ba:	46c1                	li	a3,16
ffffffffc02056bc:	8a2e                	mv	s4,a1
ffffffffc02056be:	bd99                	j	ffffffffc0205514 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc02056c0:	85ca                	mv	a1,s2
ffffffffc02056c2:	02d00513          	li	a0,45
ffffffffc02056c6:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc02056c8:	40800633          	neg	a2,s0
ffffffffc02056cc:	8a5e                	mv	s4,s7
ffffffffc02056ce:	46a9                	li	a3,10
ffffffffc02056d0:	b591                	j	ffffffffc0205514 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc02056d2:	e329                	bnez	a4,ffffffffc0205714 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056d4:	02800793          	li	a5,40
ffffffffc02056d8:	853e                	mv	a0,a5
ffffffffc02056da:	00002d97          	auipc	s11,0x2
ffffffffc02056de:	de7d8d93          	addi	s11,s11,-537 # ffffffffc02074c1 <etext+0x1c89>
ffffffffc02056e2:	b5f5                	j	ffffffffc02055ce <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056e4:	85e6                	mv	a1,s9
ffffffffc02056e6:	856e                	mv	a0,s11
ffffffffc02056e8:	08a000ef          	jal	ffffffffc0205772 <strnlen>
ffffffffc02056ec:	40ad0d3b          	subw	s10,s10,a0
ffffffffc02056f0:	01a05863          	blez	s10,ffffffffc0205700 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc02056f4:	85ca                	mv	a1,s2
ffffffffc02056f6:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056f8:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc02056fa:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056fc:	fe0d1ce3          	bnez	s10,ffffffffc02056f4 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205700:	000dc783          	lbu	a5,0(s11)
ffffffffc0205704:	0007851b          	sext.w	a0,a5
ffffffffc0205708:	ec0792e3          	bnez	a5,ffffffffc02055cc <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020570c:	6a22                	ld	s4,8(sp)
ffffffffc020570e:	bb29                	j	ffffffffc0205428 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205710:	8462                	mv	s0,s8
ffffffffc0205712:	bbd9                	j	ffffffffc02054e8 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205714:	85e6                	mv	a1,s9
ffffffffc0205716:	00002517          	auipc	a0,0x2
ffffffffc020571a:	daa50513          	addi	a0,a0,-598 # ffffffffc02074c0 <etext+0x1c88>
ffffffffc020571e:	054000ef          	jal	ffffffffc0205772 <strnlen>
ffffffffc0205722:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205726:	02800793          	li	a5,40
                p = "(null)";
ffffffffc020572a:	00002d97          	auipc	s11,0x2
ffffffffc020572e:	d96d8d93          	addi	s11,s11,-618 # ffffffffc02074c0 <etext+0x1c88>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205732:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205734:	fda040e3          	bgtz	s10,ffffffffc02056f4 <vprintfmt+0x300>
ffffffffc0205738:	bd51                	j	ffffffffc02055cc <vprintfmt+0x1d8>

ffffffffc020573a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020573a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020573c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205740:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205742:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205744:	ec06                	sd	ra,24(sp)
ffffffffc0205746:	f83a                	sd	a4,48(sp)
ffffffffc0205748:	fc3e                	sd	a5,56(sp)
ffffffffc020574a:	e0c2                	sd	a6,64(sp)
ffffffffc020574c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020574e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205750:	ca5ff0ef          	jal	ffffffffc02053f4 <vprintfmt>
}
ffffffffc0205754:	60e2                	ld	ra,24(sp)
ffffffffc0205756:	6161                	addi	sp,sp,80
ffffffffc0205758:	8082                	ret

ffffffffc020575a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020575a:	00054783          	lbu	a5,0(a0)
ffffffffc020575e:	cb81                	beqz	a5,ffffffffc020576e <strlen+0x14>
    size_t cnt = 0;
ffffffffc0205760:	4781                	li	a5,0
        cnt ++;
ffffffffc0205762:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0205764:	00f50733          	add	a4,a0,a5
ffffffffc0205768:	00074703          	lbu	a4,0(a4)
ffffffffc020576c:	fb7d                	bnez	a4,ffffffffc0205762 <strlen+0x8>
    }
    return cnt;
}
ffffffffc020576e:	853e                	mv	a0,a5
ffffffffc0205770:	8082                	ret

ffffffffc0205772 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205772:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205774:	e589                	bnez	a1,ffffffffc020577e <strnlen+0xc>
ffffffffc0205776:	a811                	j	ffffffffc020578a <strnlen+0x18>
        cnt ++;
ffffffffc0205778:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020577a:	00f58863          	beq	a1,a5,ffffffffc020578a <strnlen+0x18>
ffffffffc020577e:	00f50733          	add	a4,a0,a5
ffffffffc0205782:	00074703          	lbu	a4,0(a4)
ffffffffc0205786:	fb6d                	bnez	a4,ffffffffc0205778 <strnlen+0x6>
ffffffffc0205788:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020578a:	852e                	mv	a0,a1
ffffffffc020578c:	8082                	ret

ffffffffc020578e <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc020578e:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205790:	0005c703          	lbu	a4,0(a1)
ffffffffc0205794:	0585                	addi	a1,a1,1
ffffffffc0205796:	0785                	addi	a5,a5,1
ffffffffc0205798:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020579c:	fb75                	bnez	a4,ffffffffc0205790 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020579e:	8082                	ret

ffffffffc02057a0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057a0:	00054783          	lbu	a5,0(a0)
ffffffffc02057a4:	e791                	bnez	a5,ffffffffc02057b0 <strcmp+0x10>
ffffffffc02057a6:	a01d                	j	ffffffffc02057cc <strcmp+0x2c>
ffffffffc02057a8:	00054783          	lbu	a5,0(a0)
ffffffffc02057ac:	cb99                	beqz	a5,ffffffffc02057c2 <strcmp+0x22>
ffffffffc02057ae:	0585                	addi	a1,a1,1
ffffffffc02057b0:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc02057b4:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02057b6:	fef709e3          	beq	a4,a5,ffffffffc02057a8 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057ba:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02057be:	9d19                	subw	a0,a0,a4
ffffffffc02057c0:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057c2:	0015c703          	lbu	a4,1(a1)
ffffffffc02057c6:	4501                	li	a0,0
}
ffffffffc02057c8:	9d19                	subw	a0,a0,a4
ffffffffc02057ca:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057cc:	0005c703          	lbu	a4,0(a1)
ffffffffc02057d0:	4501                	li	a0,0
ffffffffc02057d2:	b7f5                	j	ffffffffc02057be <strcmp+0x1e>

ffffffffc02057d4 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057d4:	ce01                	beqz	a2,ffffffffc02057ec <strncmp+0x18>
ffffffffc02057d6:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02057da:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057dc:	cb91                	beqz	a5,ffffffffc02057f0 <strncmp+0x1c>
ffffffffc02057de:	0005c703          	lbu	a4,0(a1)
ffffffffc02057e2:	00f71763          	bne	a4,a5,ffffffffc02057f0 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc02057e6:	0505                	addi	a0,a0,1
ffffffffc02057e8:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057ea:	f675                	bnez	a2,ffffffffc02057d6 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057ec:	4501                	li	a0,0
ffffffffc02057ee:	8082                	ret
ffffffffc02057f0:	00054503          	lbu	a0,0(a0)
ffffffffc02057f4:	0005c783          	lbu	a5,0(a1)
ffffffffc02057f8:	9d1d                	subw	a0,a0,a5
}
ffffffffc02057fa:	8082                	ret

ffffffffc02057fc <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02057fc:	a021                	j	ffffffffc0205804 <strchr+0x8>
        if (*s == c) {
ffffffffc02057fe:	00f58763          	beq	a1,a5,ffffffffc020580c <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0205802:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205804:	00054783          	lbu	a5,0(a0)
ffffffffc0205808:	fbfd                	bnez	a5,ffffffffc02057fe <strchr+0x2>
    }
    return NULL;
ffffffffc020580a:	4501                	li	a0,0
}
ffffffffc020580c:	8082                	ret

ffffffffc020580e <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020580e:	ca01                	beqz	a2,ffffffffc020581e <memset+0x10>
ffffffffc0205810:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205812:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205814:	0785                	addi	a5,a5,1
ffffffffc0205816:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc020581a:	fef61de3          	bne	a2,a5,ffffffffc0205814 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020581e:	8082                	ret

ffffffffc0205820 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205820:	ca19                	beqz	a2,ffffffffc0205836 <memcpy+0x16>
ffffffffc0205822:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205824:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205826:	0005c703          	lbu	a4,0(a1)
ffffffffc020582a:	0585                	addi	a1,a1,1
ffffffffc020582c:	0785                	addi	a5,a5,1
ffffffffc020582e:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205832:	feb61ae3          	bne	a2,a1,ffffffffc0205826 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205836:	8082                	ret
