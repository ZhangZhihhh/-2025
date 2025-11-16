
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00009297          	auipc	t0,0x9
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0209000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00009297          	auipc	t0,0x9
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0209008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02082b7          	lui	t0,0xc0208
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
ffffffffc020003c:	c0208137          	lui	sp,0xc0208

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
ffffffffc020004a:	00009517          	auipc	a0,0x9
ffffffffc020004e:	fe650513          	addi	a0,a0,-26 # ffffffffc0209030 <buf>
ffffffffc0200052:	0000d617          	auipc	a2,0xd
ffffffffc0200056:	49660613          	addi	a2,a2,1174 # ffffffffc020d4e8 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0207ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	553030ef          	jal	ffffffffc0203db4 <memset>
    dtb_init();
ffffffffc0200066:	4c2000ef          	jal	ffffffffc0200528 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	44c000ef          	jal	ffffffffc02004b6 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00004597          	auipc	a1,0x4
ffffffffc0200072:	d9a58593          	addi	a1,a1,-614 # ffffffffc0203e08 <etext+0x6>
ffffffffc0200076:	00004517          	auipc	a0,0x4
ffffffffc020007a:	db250513          	addi	a0,a0,-590 # ffffffffc0203e28 <etext+0x26>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	158000ef          	jal	ffffffffc02001da <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	05c020ef          	jal	ffffffffc02020e2 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	7f0000ef          	jal	ffffffffc020087a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	7ee000ef          	jal	ffffffffc020087c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	5cd020ef          	jal	ffffffffc0202e5e <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	4e6030ef          	jal	ffffffffc020357c <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	3ca000ef          	jal	ffffffffc0200464 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	7d0000ef          	jal	ffffffffc020086e <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	732030ef          	jal	ffffffffc02037d4 <cpu_idle>

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
ffffffffc02000b6:	00004517          	auipc	a0,0x4
ffffffffc02000ba:	d7a50513          	addi	a0,a0,-646 # ffffffffc0203e30 <etext+0x2e>
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
ffffffffc02000c6:	00009997          	auipc	s3,0x9
ffffffffc02000ca:	f6a98993          	addi	s3,s3,-150 # ffffffffc0209030 <buf>
        c = getchar();
ffffffffc02000ce:	0fc000ef          	jal	ffffffffc02001ca <getchar>
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
ffffffffc02000fc:	0ce000ef          	jal	ffffffffc02001ca <getchar>
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
ffffffffc0200140:	00009517          	auipc	a0,0x9
ffffffffc0200144:	ef050513          	addi	a0,a0,-272 # ffffffffc0209030 <buf>
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
ffffffffc0200162:	356000ef          	jal	ffffffffc02004b8 <cons_putc>
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
ffffffffc0200188:	013030ef          	jal	ffffffffc020399a <vprintfmt>
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
ffffffffc02001bc:	7de030ef          	jal	ffffffffc020399a <vprintfmt>
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
ffffffffc02001c8:	acc5                	j	ffffffffc02004b8 <cons_putc>

ffffffffc02001ca <getchar>:
}

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc02001ca:	1141                	addi	sp,sp,-16
ffffffffc02001cc:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02001ce:	31e000ef          	jal	ffffffffc02004ec <cons_getc>
ffffffffc02001d2:	dd75                	beqz	a0,ffffffffc02001ce <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02001d4:	60a2                	ld	ra,8(sp)
ffffffffc02001d6:	0141                	addi	sp,sp,16
ffffffffc02001d8:	8082                	ret

ffffffffc02001da <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc02001da:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02001dc:	00004517          	auipc	a0,0x4
ffffffffc02001e0:	c5c50513          	addi	a0,a0,-932 # ffffffffc0203e38 <etext+0x36>
{
ffffffffc02001e4:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001e6:	fafff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02001ea:	00000597          	auipc	a1,0x0
ffffffffc02001ee:	e6058593          	addi	a1,a1,-416 # ffffffffc020004a <kern_init>
ffffffffc02001f2:	00004517          	auipc	a0,0x4
ffffffffc02001f6:	c6650513          	addi	a0,a0,-922 # ffffffffc0203e58 <etext+0x56>
ffffffffc02001fa:	f9bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02001fe:	00004597          	auipc	a1,0x4
ffffffffc0200202:	c0458593          	addi	a1,a1,-1020 # ffffffffc0203e02 <etext>
ffffffffc0200206:	00004517          	auipc	a0,0x4
ffffffffc020020a:	c7250513          	addi	a0,a0,-910 # ffffffffc0203e78 <etext+0x76>
ffffffffc020020e:	f87ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200212:	00009597          	auipc	a1,0x9
ffffffffc0200216:	e1e58593          	addi	a1,a1,-482 # ffffffffc0209030 <buf>
ffffffffc020021a:	00004517          	auipc	a0,0x4
ffffffffc020021e:	c7e50513          	addi	a0,a0,-898 # ffffffffc0203e98 <etext+0x96>
ffffffffc0200222:	f73ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200226:	0000d597          	auipc	a1,0xd
ffffffffc020022a:	2c258593          	addi	a1,a1,706 # ffffffffc020d4e8 <end>
ffffffffc020022e:	00004517          	auipc	a0,0x4
ffffffffc0200232:	c8a50513          	addi	a0,a0,-886 # ffffffffc0203eb8 <etext+0xb6>
ffffffffc0200236:	f5fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020023a:	00000717          	auipc	a4,0x0
ffffffffc020023e:	e1070713          	addi	a4,a4,-496 # ffffffffc020004a <kern_init>
ffffffffc0200242:	0000d797          	auipc	a5,0xd
ffffffffc0200246:	6a578793          	addi	a5,a5,1701 # ffffffffc020d8e7 <end+0x3ff>
ffffffffc020024a:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020024c:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200250:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200252:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200256:	95be                	add	a1,a1,a5
ffffffffc0200258:	85a9                	srai	a1,a1,0xa
ffffffffc020025a:	00004517          	auipc	a0,0x4
ffffffffc020025e:	c7e50513          	addi	a0,a0,-898 # ffffffffc0203ed8 <etext+0xd6>
}
ffffffffc0200262:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200264:	bf05                	j	ffffffffc0200194 <cprintf>

ffffffffc0200266 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc0200266:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200268:	00004617          	auipc	a2,0x4
ffffffffc020026c:	ca060613          	addi	a2,a2,-864 # ffffffffc0203f08 <etext+0x106>
ffffffffc0200270:	04900593          	li	a1,73
ffffffffc0200274:	00004517          	auipc	a0,0x4
ffffffffc0200278:	cac50513          	addi	a0,a0,-852 # ffffffffc0203f20 <etext+0x11e>
{
ffffffffc020027c:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020027e:	188000ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0200282 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200282:	1101                	addi	sp,sp,-32
ffffffffc0200284:	e822                	sd	s0,16(sp)
ffffffffc0200286:	e426                	sd	s1,8(sp)
ffffffffc0200288:	ec06                	sd	ra,24(sp)
ffffffffc020028a:	00005417          	auipc	s0,0x5
ffffffffc020028e:	43e40413          	addi	s0,s0,1086 # ffffffffc02056c8 <commands>
ffffffffc0200292:	00005497          	auipc	s1,0x5
ffffffffc0200296:	47e48493          	addi	s1,s1,1150 # ffffffffc0205710 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020029a:	6410                	ld	a2,8(s0)
ffffffffc020029c:	600c                	ld	a1,0(s0)
ffffffffc020029e:	00004517          	auipc	a0,0x4
ffffffffc02002a2:	c9a50513          	addi	a0,a0,-870 # ffffffffc0203f38 <etext+0x136>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002a6:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002a8:	eedff0ef          	jal	ffffffffc0200194 <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002ac:	fe9417e3          	bne	s0,s1,ffffffffc020029a <mon_help+0x18>
    }
    return 0;
}
ffffffffc02002b0:	60e2                	ld	ra,24(sp)
ffffffffc02002b2:	6442                	ld	s0,16(sp)
ffffffffc02002b4:	64a2                	ld	s1,8(sp)
ffffffffc02002b6:	4501                	li	a0,0
ffffffffc02002b8:	6105                	addi	sp,sp,32
ffffffffc02002ba:	8082                	ret

ffffffffc02002bc <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002bc:	1141                	addi	sp,sp,-16
ffffffffc02002be:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002c0:	f1bff0ef          	jal	ffffffffc02001da <print_kerninfo>
    return 0;
}
ffffffffc02002c4:	60a2                	ld	ra,8(sp)
ffffffffc02002c6:	4501                	li	a0,0
ffffffffc02002c8:	0141                	addi	sp,sp,16
ffffffffc02002ca:	8082                	ret

ffffffffc02002cc <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002cc:	1141                	addi	sp,sp,-16
ffffffffc02002ce:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002d0:	f97ff0ef          	jal	ffffffffc0200266 <print_stackframe>
    return 0;
}
ffffffffc02002d4:	60a2                	ld	ra,8(sp)
ffffffffc02002d6:	4501                	li	a0,0
ffffffffc02002d8:	0141                	addi	sp,sp,16
ffffffffc02002da:	8082                	ret

ffffffffc02002dc <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002dc:	7131                	addi	sp,sp,-192
ffffffffc02002de:	e952                	sd	s4,144(sp)
ffffffffc02002e0:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002e2:	00004517          	auipc	a0,0x4
ffffffffc02002e6:	c6650513          	addi	a0,a0,-922 # ffffffffc0203f48 <etext+0x146>
kmonitor(struct trapframe *tf) {
ffffffffc02002ea:	fd06                	sd	ra,184(sp)
ffffffffc02002ec:	f922                	sd	s0,176(sp)
ffffffffc02002ee:	f526                	sd	s1,168(sp)
ffffffffc02002f0:	f14a                	sd	s2,160(sp)
ffffffffc02002f2:	e556                	sd	s5,136(sp)
ffffffffc02002f4:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002f6:	e9fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002fa:	00004517          	auipc	a0,0x4
ffffffffc02002fe:	c7650513          	addi	a0,a0,-906 # ffffffffc0203f70 <etext+0x16e>
ffffffffc0200302:	e93ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL) {
ffffffffc0200306:	000a0563          	beqz	s4,ffffffffc0200310 <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc020030a:	8552                	mv	a0,s4
ffffffffc020030c:	758000ef          	jal	ffffffffc0200a64 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200310:	4501                	li	a0,0
ffffffffc0200312:	4581                	li	a1,0
ffffffffc0200314:	4601                	li	a2,0
ffffffffc0200316:	48a1                	li	a7,8
ffffffffc0200318:	00000073          	ecall
ffffffffc020031c:	00005a97          	auipc	s5,0x5
ffffffffc0200320:	3aca8a93          	addi	s5,s5,940 # ffffffffc02056c8 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc0200324:	493d                	li	s2,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200326:	00004517          	auipc	a0,0x4
ffffffffc020032a:	c7250513          	addi	a0,a0,-910 # ffffffffc0203f98 <etext+0x196>
ffffffffc020032e:	d79ff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc0200332:	842a                	mv	s0,a0
ffffffffc0200334:	d96d                	beqz	a0,ffffffffc0200326 <kmonitor+0x4a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200336:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020033a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033c:	e99d                	bnez	a1,ffffffffc0200372 <kmonitor+0x96>
    int argc = 0;
ffffffffc020033e:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc0200340:	fe0b03e3          	beqz	s6,ffffffffc0200326 <kmonitor+0x4a>
ffffffffc0200344:	00005497          	auipc	s1,0x5
ffffffffc0200348:	38448493          	addi	s1,s1,900 # ffffffffc02056c8 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020034e:	6582                	ld	a1,0(sp)
ffffffffc0200350:	6088                	ld	a0,0(s1)
ffffffffc0200352:	1f5030ef          	jal	ffffffffc0203d46 <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200356:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200358:	c149                	beqz	a0,ffffffffc02003da <kmonitor+0xfe>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020035a:	2405                	addiw	s0,s0,1
ffffffffc020035c:	04e1                	addi	s1,s1,24
ffffffffc020035e:	fef418e3          	bne	s0,a5,ffffffffc020034e <kmonitor+0x72>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200362:	6582                	ld	a1,0(sp)
ffffffffc0200364:	00004517          	auipc	a0,0x4
ffffffffc0200368:	c6450513          	addi	a0,a0,-924 # ffffffffc0203fc8 <etext+0x1c6>
ffffffffc020036c:	e29ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc0200370:	bf5d                	j	ffffffffc0200326 <kmonitor+0x4a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200372:	00004517          	auipc	a0,0x4
ffffffffc0200376:	c2e50513          	addi	a0,a0,-978 # ffffffffc0203fa0 <etext+0x19e>
ffffffffc020037a:	229030ef          	jal	ffffffffc0203da2 <strchr>
ffffffffc020037e:	c901                	beqz	a0,ffffffffc020038e <kmonitor+0xb2>
ffffffffc0200380:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200384:	00040023          	sb	zero,0(s0)
ffffffffc0200388:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020038a:	d9d5                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc020038c:	b7dd                	j	ffffffffc0200372 <kmonitor+0x96>
        if (*buf == '\0') {
ffffffffc020038e:	00044783          	lbu	a5,0(s0)
ffffffffc0200392:	d7d5                	beqz	a5,ffffffffc020033e <kmonitor+0x62>
        if (argc == MAXARGS - 1) {
ffffffffc0200394:	03248b63          	beq	s1,s2,ffffffffc02003ca <kmonitor+0xee>
        argv[argc ++] = buf;
ffffffffc0200398:	00349793          	slli	a5,s1,0x3
ffffffffc020039c:	978a                	add	a5,a5,sp
ffffffffc020039e:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a0:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003a4:	2485                	addiw	s1,s1,1
ffffffffc02003a6:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a8:	e591                	bnez	a1,ffffffffc02003b4 <kmonitor+0xd8>
ffffffffc02003aa:	bf59                	j	ffffffffc0200340 <kmonitor+0x64>
ffffffffc02003ac:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003b0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003b2:	d5d1                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc02003b4:	00004517          	auipc	a0,0x4
ffffffffc02003b8:	bec50513          	addi	a0,a0,-1044 # ffffffffc0203fa0 <etext+0x19e>
ffffffffc02003bc:	1e7030ef          	jal	ffffffffc0203da2 <strchr>
ffffffffc02003c0:	d575                	beqz	a0,ffffffffc02003ac <kmonitor+0xd0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c2:	00044583          	lbu	a1,0(s0)
ffffffffc02003c6:	dda5                	beqz	a1,ffffffffc020033e <kmonitor+0x62>
ffffffffc02003c8:	b76d                	j	ffffffffc0200372 <kmonitor+0x96>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003ca:	45c1                	li	a1,16
ffffffffc02003cc:	00004517          	auipc	a0,0x4
ffffffffc02003d0:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0203fa8 <etext+0x1a6>
ffffffffc02003d4:	dc1ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc02003d8:	b7c1                	j	ffffffffc0200398 <kmonitor+0xbc>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003da:	00141793          	slli	a5,s0,0x1
ffffffffc02003de:	97a2                	add	a5,a5,s0
ffffffffc02003e0:	078e                	slli	a5,a5,0x3
ffffffffc02003e2:	97d6                	add	a5,a5,s5
ffffffffc02003e4:	6b9c                	ld	a5,16(a5)
ffffffffc02003e6:	fffb051b          	addiw	a0,s6,-1
ffffffffc02003ea:	8652                	mv	a2,s4
ffffffffc02003ec:	002c                	addi	a1,sp,8
ffffffffc02003ee:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003f0:	f2055be3          	bgez	a0,ffffffffc0200326 <kmonitor+0x4a>
}
ffffffffc02003f4:	70ea                	ld	ra,184(sp)
ffffffffc02003f6:	744a                	ld	s0,176(sp)
ffffffffc02003f8:	74aa                	ld	s1,168(sp)
ffffffffc02003fa:	790a                	ld	s2,160(sp)
ffffffffc02003fc:	6a4a                	ld	s4,144(sp)
ffffffffc02003fe:	6aaa                	ld	s5,136(sp)
ffffffffc0200400:	6b0a                	ld	s6,128(sp)
ffffffffc0200402:	6129                	addi	sp,sp,192
ffffffffc0200404:	8082                	ret

ffffffffc0200406 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200406:	0000d317          	auipc	t1,0xd
ffffffffc020040a:	06232303          	lw	t1,98(t1) # ffffffffc020d468 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020040e:	715d                	addi	sp,sp,-80
ffffffffc0200410:	ec06                	sd	ra,24(sp)
ffffffffc0200412:	f436                	sd	a3,40(sp)
ffffffffc0200414:	f83a                	sd	a4,48(sp)
ffffffffc0200416:	fc3e                	sd	a5,56(sp)
ffffffffc0200418:	e0c2                	sd	a6,64(sp)
ffffffffc020041a:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020041c:	02031e63          	bnez	t1,ffffffffc0200458 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200420:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200422:	103c                	addi	a5,sp,40
ffffffffc0200424:	e822                	sd	s0,16(sp)
ffffffffc0200426:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200428:	862e                	mv	a2,a1
ffffffffc020042a:	85aa                	mv	a1,a0
ffffffffc020042c:	00004517          	auipc	a0,0x4
ffffffffc0200430:	c4450513          	addi	a0,a0,-956 # ffffffffc0204070 <etext+0x26e>
    is_panic = 1;
ffffffffc0200434:	0000d697          	auipc	a3,0xd
ffffffffc0200438:	02e6aa23          	sw	a4,52(a3) # ffffffffc020d468 <is_panic>
    va_start(ap, fmt);
ffffffffc020043c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020043e:	d57ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200442:	65a2                	ld	a1,8(sp)
ffffffffc0200444:	8522                	mv	a0,s0
ffffffffc0200446:	d2fff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020044a:	00004517          	auipc	a0,0x4
ffffffffc020044e:	c4650513          	addi	a0,a0,-954 # ffffffffc0204090 <etext+0x28e>
ffffffffc0200452:	d43ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200456:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200458:	41c000ef          	jal	ffffffffc0200874 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020045c:	4501                	li	a0,0
ffffffffc020045e:	e7fff0ef          	jal	ffffffffc02002dc <kmonitor>
    while (1) {
ffffffffc0200462:	bfed                	j	ffffffffc020045c <__panic+0x56>

ffffffffc0200464 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	0000d717          	auipc	a4,0xd
ffffffffc020046e:	00f73323          	sd	a5,6(a4) # ffffffffc020d470 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200472:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200476:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200478:	953e                	add	a0,a0,a5
ffffffffc020047a:	4601                	li	a2,0
ffffffffc020047c:	4881                	li	a7,0
ffffffffc020047e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200482:	02000793          	li	a5,32
ffffffffc0200486:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020048a:	00004517          	auipc	a0,0x4
ffffffffc020048e:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0204098 <etext+0x296>
    ticks = 0;
ffffffffc0200492:	0000d797          	auipc	a5,0xd
ffffffffc0200496:	fe07b323          	sd	zero,-26(a5) # ffffffffc020d478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020049a:	b9ed                	j	ffffffffc0200194 <cprintf>

ffffffffc020049c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020049c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02004a0:	0000d797          	auipc	a5,0xd
ffffffffc02004a4:	fd07b783          	ld	a5,-48(a5) # ffffffffc020d470 <timebase>
ffffffffc02004a8:	4581                	li	a1,0
ffffffffc02004aa:	4601                	li	a2,0
ffffffffc02004ac:	953e                	add	a0,a0,a5
ffffffffc02004ae:	4881                	li	a7,0
ffffffffc02004b0:	00000073          	ecall
ffffffffc02004b4:	8082                	ret

ffffffffc02004b6 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02004b6:	8082                	ret

ffffffffc02004b8 <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004b8:	100027f3          	csrr	a5,sstatus
ffffffffc02004bc:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02004be:	0ff57513          	zext.b	a0,a0
ffffffffc02004c2:	e799                	bnez	a5,ffffffffc02004d0 <cons_putc+0x18>
ffffffffc02004c4:	4581                	li	a1,0
ffffffffc02004c6:	4601                	li	a2,0
ffffffffc02004c8:	4885                	li	a7,1
ffffffffc02004ca:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02004ce:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02004d0:	1101                	addi	sp,sp,-32
ffffffffc02004d2:	ec06                	sd	ra,24(sp)
ffffffffc02004d4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02004d6:	39e000ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02004da:	6522                	ld	a0,8(sp)
ffffffffc02004dc:	4581                	li	a1,0
ffffffffc02004de:	4601                	li	a2,0
ffffffffc02004e0:	4885                	li	a7,1
ffffffffc02004e2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02004e6:	60e2                	ld	ra,24(sp)
ffffffffc02004e8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02004ea:	a651                	j	ffffffffc020086e <intr_enable>

ffffffffc02004ec <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004ec:	100027f3          	csrr	a5,sstatus
ffffffffc02004f0:	8b89                	andi	a5,a5,2
ffffffffc02004f2:	eb89                	bnez	a5,ffffffffc0200504 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02004f4:	4501                	li	a0,0
ffffffffc02004f6:	4581                	li	a1,0
ffffffffc02004f8:	4601                	li	a2,0
ffffffffc02004fa:	4889                	li	a7,2
ffffffffc02004fc:	00000073          	ecall
ffffffffc0200500:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200502:	8082                	ret
int cons_getc(void) {
ffffffffc0200504:	1101                	addi	sp,sp,-32
ffffffffc0200506:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200508:	36c000ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc020050c:	4501                	li	a0,0
ffffffffc020050e:	4581                	li	a1,0
ffffffffc0200510:	4601                	li	a2,0
ffffffffc0200512:	4889                	li	a7,2
ffffffffc0200514:	00000073          	ecall
ffffffffc0200518:	2501                	sext.w	a0,a0
ffffffffc020051a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020051c:	352000ef          	jal	ffffffffc020086e <intr_enable>
}
ffffffffc0200520:	60e2                	ld	ra,24(sp)
ffffffffc0200522:	6522                	ld	a0,8(sp)
ffffffffc0200524:	6105                	addi	sp,sp,32
ffffffffc0200526:	8082                	ret

ffffffffc0200528 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200528:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020052a:	00004517          	auipc	a0,0x4
ffffffffc020052e:	b8e50513          	addi	a0,a0,-1138 # ffffffffc02040b8 <etext+0x2b6>
void dtb_init(void) {
ffffffffc0200532:	f406                	sd	ra,40(sp)
ffffffffc0200534:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200536:	c5fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020053a:	00009597          	auipc	a1,0x9
ffffffffc020053e:	ac65b583          	ld	a1,-1338(a1) # ffffffffc0209000 <boot_hartid>
ffffffffc0200542:	00004517          	auipc	a0,0x4
ffffffffc0200546:	b8650513          	addi	a0,a0,-1146 # ffffffffc02040c8 <etext+0x2c6>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020054a:	00009417          	auipc	s0,0x9
ffffffffc020054e:	abe40413          	addi	s0,s0,-1346 # ffffffffc0209008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200552:	c43ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200556:	600c                	ld	a1,0(s0)
ffffffffc0200558:	00004517          	auipc	a0,0x4
ffffffffc020055c:	b8050513          	addi	a0,a0,-1152 # ffffffffc02040d8 <etext+0x2d6>
ffffffffc0200560:	c35ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200564:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200566:	00004517          	auipc	a0,0x4
ffffffffc020056a:	b8a50513          	addi	a0,a0,-1142 # ffffffffc02040f0 <etext+0x2ee>
    if (boot_dtb == 0) {
ffffffffc020056e:	10070163          	beqz	a4,ffffffffc0200670 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200572:	57f5                	li	a5,-3
ffffffffc0200574:	07fa                	slli	a5,a5,0x1e
ffffffffc0200576:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200578:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020057a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020057e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed2a05>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200582:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200586:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020058a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020058e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200592:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200596:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200598:	8e49                	or	a2,a2,a0
ffffffffc020059a:	0ff7f793          	zext.b	a5,a5
ffffffffc020059e:	8dd1                	or	a1,a1,a2
ffffffffc02005a0:	07a2                	slli	a5,a5,0x8
ffffffffc02005a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02005a8:	0cd59863          	bne	a1,a3,ffffffffc0200678 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02005ac:	4710                	lw	a2,8(a4)
ffffffffc02005ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02005b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02005be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02005c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02005ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02005da:	01c56533          	or	a0,a0,t3
ffffffffc02005de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02005f2:	8c49                	or	s0,s0,a0
ffffffffc02005f4:	0622                	slli	a2,a2,0x8
ffffffffc02005f6:	8fcd                	or	a5,a5,a1
ffffffffc02005f8:	06a2                	slli	a3,a3,0x8
ffffffffc02005fa:	8c51                	or	s0,s0,a2
ffffffffc02005fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200600:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200602:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200604:	9381                	srli	a5,a5,0x20
ffffffffc0200606:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200608:	4301                	li	t1,0
        switch (token) {
ffffffffc020060a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020060c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020060e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200612:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200614:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200616:	0087579b          	srliw	a5,a4,0x8
ffffffffc020061a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200622:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200626:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020062a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020062e:	8ed1                	or	a3,a3,a2
ffffffffc0200630:	0ff77713          	zext.b	a4,a4
ffffffffc0200634:	8fd5                	or	a5,a5,a3
ffffffffc0200636:	0722                	slli	a4,a4,0x8
ffffffffc0200638:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020063a:	05178763          	beq	a5,a7,ffffffffc0200688 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020063e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200640:	00f8e963          	bltu	a7,a5,ffffffffc0200652 <dtb_init+0x12a>
ffffffffc0200644:	07c78d63          	beq	a5,t3,ffffffffc02006be <dtb_init+0x196>
ffffffffc0200648:	4709                	li	a4,2
ffffffffc020064a:	00e79763          	bne	a5,a4,ffffffffc0200658 <dtb_init+0x130>
ffffffffc020064e:	4301                	li	t1,0
ffffffffc0200650:	b7d1                	j	ffffffffc0200614 <dtb_init+0xec>
ffffffffc0200652:	4711                	li	a4,4
ffffffffc0200654:	fce780e3          	beq	a5,a4,ffffffffc0200614 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200658:	00004517          	auipc	a0,0x4
ffffffffc020065c:	b6050513          	addi	a0,a0,-1184 # ffffffffc02041b8 <etext+0x3b6>
ffffffffc0200660:	b35ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200664:	64e2                	ld	s1,24(sp)
ffffffffc0200666:	6942                	ld	s2,16(sp)
ffffffffc0200668:	00004517          	auipc	a0,0x4
ffffffffc020066c:	b8850513          	addi	a0,a0,-1144 # ffffffffc02041f0 <etext+0x3ee>
}
ffffffffc0200670:	7402                	ld	s0,32(sp)
ffffffffc0200672:	70a2                	ld	ra,40(sp)
ffffffffc0200674:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200676:	be39                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200678:	7402                	ld	s0,32(sp)
ffffffffc020067a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020067c:	00004517          	auipc	a0,0x4
ffffffffc0200680:	a9450513          	addi	a0,a0,-1388 # ffffffffc0204110 <etext+0x30e>
}
ffffffffc0200684:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200686:	b639                	j	ffffffffc0200194 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200688:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020068e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200692:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200696:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a2:	8ed1                	or	a3,a3,a2
ffffffffc02006a4:	0ff77713          	zext.b	a4,a4
ffffffffc02006a8:	8fd5                	or	a5,a5,a3
ffffffffc02006aa:	0722                	slli	a4,a4,0x8
ffffffffc02006ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ae:	04031463          	bnez	t1,ffffffffc02006f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006b2:	1782                	slli	a5,a5,0x20
ffffffffc02006b4:	9381                	srli	a5,a5,0x20
ffffffffc02006b6:	043d                	addi	s0,s0,15
ffffffffc02006b8:	943e                	add	s0,s0,a5
ffffffffc02006ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02006bc:	bfa1                	j	ffffffffc0200614 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02006be:	8522                	mv	a0,s0
ffffffffc02006c0:	e01a                	sd	t1,0(sp)
ffffffffc02006c2:	63e030ef          	jal	ffffffffc0203d00 <strlen>
ffffffffc02006c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006c8:	4619                	li	a2,6
ffffffffc02006ca:	8522                	mv	a0,s0
ffffffffc02006cc:	00004597          	auipc	a1,0x4
ffffffffc02006d0:	a6c58593          	addi	a1,a1,-1428 # ffffffffc0204138 <etext+0x336>
ffffffffc02006d4:	6a6030ef          	jal	ffffffffc0203d7a <strncmp>
ffffffffc02006d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006da:	0411                	addi	s0,s0,4
ffffffffc02006dc:	0004879b          	sext.w	a5,s1
ffffffffc02006e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02006ec:	00ff0837          	lui	a6,0xff0
ffffffffc02006f0:	488d                	li	a7,3
ffffffffc02006f2:	4e05                	li	t3,1
ffffffffc02006f4:	b705                	j	ffffffffc0200614 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006f8:	00004597          	auipc	a1,0x4
ffffffffc02006fc:	a4858593          	addi	a1,a1,-1464 # ffffffffc0204140 <etext+0x33e>
ffffffffc0200700:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200702:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200706:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020070e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071a:	8ed1                	or	a3,a3,a2
ffffffffc020071c:	0ff77713          	zext.b	a4,a4
ffffffffc0200720:	0722                	slli	a4,a4,0x8
ffffffffc0200722:	8d55                	or	a0,a0,a3
ffffffffc0200724:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200726:	1502                	slli	a0,a0,0x20
ffffffffc0200728:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020072a:	954a                	add	a0,a0,s2
ffffffffc020072c:	e01a                	sd	t1,0(sp)
ffffffffc020072e:	618030ef          	jal	ffffffffc0203d46 <strcmp>
ffffffffc0200732:	67a2                	ld	a5,8(sp)
ffffffffc0200734:	473d                	li	a4,15
ffffffffc0200736:	6302                	ld	t1,0(sp)
ffffffffc0200738:	00ff0837          	lui	a6,0xff0
ffffffffc020073c:	488d                	li	a7,3
ffffffffc020073e:	4e05                	li	t3,1
ffffffffc0200740:	f6f779e3          	bgeu	a4,a5,ffffffffc02006b2 <dtb_init+0x18a>
ffffffffc0200744:	f53d                	bnez	a0,ffffffffc02006b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200746:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020074a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020074e:	00004517          	auipc	a0,0x4
ffffffffc0200752:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0204148 <etext+0x346>
           fdt32_to_cpu(x >> 32);
ffffffffc0200756:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020075a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020075e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200762:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200766:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020076e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200772:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200776:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020077a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077e:	01037333          	and	t1,t1,a6
ffffffffc0200782:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200786:	01e5e5b3          	or	a1,a1,t5
ffffffffc020078a:	0ff7f793          	zext.b	a5,a5
ffffffffc020078e:	01de6e33          	or	t3,t3,t4
ffffffffc0200792:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200796:	01067633          	and	a2,a2,a6
ffffffffc020079a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020079e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	07a2                	slli	a5,a5,0x8
ffffffffc02007a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02007a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02007ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02007b0:	8ddd                	or	a1,a1,a5
ffffffffc02007b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02007ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007d6:	08a2                	slli	a7,a7,0x8
ffffffffc02007d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02007e4:	01de6833          	or	a6,t3,t4
ffffffffc02007e8:	0ff77713          	zext.b	a4,a4
ffffffffc02007ec:	01166633          	or	a2,a2,a7
ffffffffc02007f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02007f4:	06a2                	slli	a3,a3,0x8
ffffffffc02007f6:	01046433          	or	s0,s0,a6
ffffffffc02007fa:	0722                	slli	a4,a4,0x8
ffffffffc02007fc:	8fd5                	or	a5,a5,a3
ffffffffc02007fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200800:	1582                	slli	a1,a1,0x20
ffffffffc0200802:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200804:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200806:	9201                	srli	a2,a2,0x20
ffffffffc0200808:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020080a:	1402                	slli	s0,s0,0x20
ffffffffc020080c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200810:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200812:	983ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200816:	85a6                	mv	a1,s1
ffffffffc0200818:	00004517          	auipc	a0,0x4
ffffffffc020081c:	95050513          	addi	a0,a0,-1712 # ffffffffc0204168 <etext+0x366>
ffffffffc0200820:	975ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200824:	01445613          	srli	a2,s0,0x14
ffffffffc0200828:	85a2                	mv	a1,s0
ffffffffc020082a:	00004517          	auipc	a0,0x4
ffffffffc020082e:	95650513          	addi	a0,a0,-1706 # ffffffffc0204180 <etext+0x37e>
ffffffffc0200832:	963ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200836:	009405b3          	add	a1,s0,s1
ffffffffc020083a:	15fd                	addi	a1,a1,-1
ffffffffc020083c:	00004517          	auipc	a0,0x4
ffffffffc0200840:	96450513          	addi	a0,a0,-1692 # ffffffffc02041a0 <etext+0x39e>
ffffffffc0200844:	951ff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc0200848:	0000d797          	auipc	a5,0xd
ffffffffc020084c:	c497b023          	sd	s1,-960(a5) # ffffffffc020d488 <memory_base>
        memory_size = mem_size;
ffffffffc0200850:	0000d797          	auipc	a5,0xd
ffffffffc0200854:	c287b823          	sd	s0,-976(a5) # ffffffffc020d480 <memory_size>
ffffffffc0200858:	b531                	j	ffffffffc0200664 <dtb_init+0x13c>

ffffffffc020085a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020085a:	0000d517          	auipc	a0,0xd
ffffffffc020085e:	c2e53503          	ld	a0,-978(a0) # ffffffffc020d488 <memory_base>
ffffffffc0200862:	8082                	ret

ffffffffc0200864 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200864:	0000d517          	auipc	a0,0xd
ffffffffc0200868:	c1c53503          	ld	a0,-996(a0) # ffffffffc020d480 <memory_size>
ffffffffc020086c:	8082                	ret

ffffffffc020086e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020086e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200872:	8082                	ret

ffffffffc0200874 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200874:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200878:	8082                	ret

ffffffffc020087a <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020087a:	8082                	ret

ffffffffc020087c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020087c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200880:	00000797          	auipc	a5,0x0
ffffffffc0200884:	38878793          	addi	a5,a5,904 # ffffffffc0200c08 <__alltraps>
ffffffffc0200888:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020088c:	000407b7          	lui	a5,0x40
ffffffffc0200890:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200894:	8082                	ret

ffffffffc0200896 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200896:	610c                	ld	a1,0(a0)
{
ffffffffc0200898:	1141                	addi	sp,sp,-16
ffffffffc020089a:	e022                	sd	s0,0(sp)
ffffffffc020089c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020089e:	00004517          	auipc	a0,0x4
ffffffffc02008a2:	96a50513          	addi	a0,a0,-1686 # ffffffffc0204208 <etext+0x406>
{
ffffffffc02008a6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02008a8:	8edff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02008ac:	640c                	ld	a1,8(s0)
ffffffffc02008ae:	00004517          	auipc	a0,0x4
ffffffffc02008b2:	97250513          	addi	a0,a0,-1678 # ffffffffc0204220 <etext+0x41e>
ffffffffc02008b6:	8dfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02008ba:	680c                	ld	a1,16(s0)
ffffffffc02008bc:	00004517          	auipc	a0,0x4
ffffffffc02008c0:	97c50513          	addi	a0,a0,-1668 # ffffffffc0204238 <etext+0x436>
ffffffffc02008c4:	8d1ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02008c8:	6c0c                	ld	a1,24(s0)
ffffffffc02008ca:	00004517          	auipc	a0,0x4
ffffffffc02008ce:	98650513          	addi	a0,a0,-1658 # ffffffffc0204250 <etext+0x44e>
ffffffffc02008d2:	8c3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02008d6:	700c                	ld	a1,32(s0)
ffffffffc02008d8:	00004517          	auipc	a0,0x4
ffffffffc02008dc:	99050513          	addi	a0,a0,-1648 # ffffffffc0204268 <etext+0x466>
ffffffffc02008e0:	8b5ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02008e4:	740c                	ld	a1,40(s0)
ffffffffc02008e6:	00004517          	auipc	a0,0x4
ffffffffc02008ea:	99a50513          	addi	a0,a0,-1638 # ffffffffc0204280 <etext+0x47e>
ffffffffc02008ee:	8a7ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008f2:	780c                	ld	a1,48(s0)
ffffffffc02008f4:	00004517          	auipc	a0,0x4
ffffffffc02008f8:	9a450513          	addi	a0,a0,-1628 # ffffffffc0204298 <etext+0x496>
ffffffffc02008fc:	899ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200900:	7c0c                	ld	a1,56(s0)
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	9ae50513          	addi	a0,a0,-1618 # ffffffffc02042b0 <etext+0x4ae>
ffffffffc020090a:	88bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020090e:	602c                	ld	a1,64(s0)
ffffffffc0200910:	00004517          	auipc	a0,0x4
ffffffffc0200914:	9b850513          	addi	a0,a0,-1608 # ffffffffc02042c8 <etext+0x4c6>
ffffffffc0200918:	87dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020091c:	642c                	ld	a1,72(s0)
ffffffffc020091e:	00004517          	auipc	a0,0x4
ffffffffc0200922:	9c250513          	addi	a0,a0,-1598 # ffffffffc02042e0 <etext+0x4de>
ffffffffc0200926:	86fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020092a:	682c                	ld	a1,80(s0)
ffffffffc020092c:	00004517          	auipc	a0,0x4
ffffffffc0200930:	9cc50513          	addi	a0,a0,-1588 # ffffffffc02042f8 <etext+0x4f6>
ffffffffc0200934:	861ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200938:	6c2c                	ld	a1,88(s0)
ffffffffc020093a:	00004517          	auipc	a0,0x4
ffffffffc020093e:	9d650513          	addi	a0,a0,-1578 # ffffffffc0204310 <etext+0x50e>
ffffffffc0200942:	853ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200946:	702c                	ld	a1,96(s0)
ffffffffc0200948:	00004517          	auipc	a0,0x4
ffffffffc020094c:	9e050513          	addi	a0,a0,-1568 # ffffffffc0204328 <etext+0x526>
ffffffffc0200950:	845ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200954:	742c                	ld	a1,104(s0)
ffffffffc0200956:	00004517          	auipc	a0,0x4
ffffffffc020095a:	9ea50513          	addi	a0,a0,-1558 # ffffffffc0204340 <etext+0x53e>
ffffffffc020095e:	837ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200962:	782c                	ld	a1,112(s0)
ffffffffc0200964:	00004517          	auipc	a0,0x4
ffffffffc0200968:	9f450513          	addi	a0,a0,-1548 # ffffffffc0204358 <etext+0x556>
ffffffffc020096c:	829ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200970:	7c2c                	ld	a1,120(s0)
ffffffffc0200972:	00004517          	auipc	a0,0x4
ffffffffc0200976:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0204370 <etext+0x56e>
ffffffffc020097a:	81bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020097e:	604c                	ld	a1,128(s0)
ffffffffc0200980:	00004517          	auipc	a0,0x4
ffffffffc0200984:	a0850513          	addi	a0,a0,-1528 # ffffffffc0204388 <etext+0x586>
ffffffffc0200988:	80dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020098c:	644c                	ld	a1,136(s0)
ffffffffc020098e:	00004517          	auipc	a0,0x4
ffffffffc0200992:	a1250513          	addi	a0,a0,-1518 # ffffffffc02043a0 <etext+0x59e>
ffffffffc0200996:	ffeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020099a:	684c                	ld	a1,144(s0)
ffffffffc020099c:	00004517          	auipc	a0,0x4
ffffffffc02009a0:	a1c50513          	addi	a0,a0,-1508 # ffffffffc02043b8 <etext+0x5b6>
ffffffffc02009a4:	ff0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02009a8:	6c4c                	ld	a1,152(s0)
ffffffffc02009aa:	00004517          	auipc	a0,0x4
ffffffffc02009ae:	a2650513          	addi	a0,a0,-1498 # ffffffffc02043d0 <etext+0x5ce>
ffffffffc02009b2:	fe2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02009b6:	704c                	ld	a1,160(s0)
ffffffffc02009b8:	00004517          	auipc	a0,0x4
ffffffffc02009bc:	a3050513          	addi	a0,a0,-1488 # ffffffffc02043e8 <etext+0x5e6>
ffffffffc02009c0:	fd4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02009c4:	744c                	ld	a1,168(s0)
ffffffffc02009c6:	00004517          	auipc	a0,0x4
ffffffffc02009ca:	a3a50513          	addi	a0,a0,-1478 # ffffffffc0204400 <etext+0x5fe>
ffffffffc02009ce:	fc6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02009d2:	784c                	ld	a1,176(s0)
ffffffffc02009d4:	00004517          	auipc	a0,0x4
ffffffffc02009d8:	a4450513          	addi	a0,a0,-1468 # ffffffffc0204418 <etext+0x616>
ffffffffc02009dc:	fb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02009e0:	7c4c                	ld	a1,184(s0)
ffffffffc02009e2:	00004517          	auipc	a0,0x4
ffffffffc02009e6:	a4e50513          	addi	a0,a0,-1458 # ffffffffc0204430 <etext+0x62e>
ffffffffc02009ea:	faaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009ee:	606c                	ld	a1,192(s0)
ffffffffc02009f0:	00004517          	auipc	a0,0x4
ffffffffc02009f4:	a5850513          	addi	a0,a0,-1448 # ffffffffc0204448 <etext+0x646>
ffffffffc02009f8:	f9cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009fc:	646c                	ld	a1,200(s0)
ffffffffc02009fe:	00004517          	auipc	a0,0x4
ffffffffc0200a02:	a6250513          	addi	a0,a0,-1438 # ffffffffc0204460 <etext+0x65e>
ffffffffc0200a06:	f8eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a0a:	686c                	ld	a1,208(s0)
ffffffffc0200a0c:	00004517          	auipc	a0,0x4
ffffffffc0200a10:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0204478 <etext+0x676>
ffffffffc0200a14:	f80ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200a18:	6c6c                	ld	a1,216(s0)
ffffffffc0200a1a:	00004517          	auipc	a0,0x4
ffffffffc0200a1e:	a7650513          	addi	a0,a0,-1418 # ffffffffc0204490 <etext+0x68e>
ffffffffc0200a22:	f72ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200a26:	706c                	ld	a1,224(s0)
ffffffffc0200a28:	00004517          	auipc	a0,0x4
ffffffffc0200a2c:	a8050513          	addi	a0,a0,-1408 # ffffffffc02044a8 <etext+0x6a6>
ffffffffc0200a30:	f64ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200a34:	746c                	ld	a1,232(s0)
ffffffffc0200a36:	00004517          	auipc	a0,0x4
ffffffffc0200a3a:	a8a50513          	addi	a0,a0,-1398 # ffffffffc02044c0 <etext+0x6be>
ffffffffc0200a3e:	f56ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200a42:	786c                	ld	a1,240(s0)
ffffffffc0200a44:	00004517          	auipc	a0,0x4
ffffffffc0200a48:	a9450513          	addi	a0,a0,-1388 # ffffffffc02044d8 <etext+0x6d6>
ffffffffc0200a4c:	f48ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a50:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a52:	6402                	ld	s0,0(sp)
ffffffffc0200a54:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a56:	00004517          	auipc	a0,0x4
ffffffffc0200a5a:	a9a50513          	addi	a0,a0,-1382 # ffffffffc02044f0 <etext+0x6ee>
}
ffffffffc0200a5e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a60:	f34ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200a64 <print_trapframe>:
{
ffffffffc0200a64:	1141                	addi	sp,sp,-16
ffffffffc0200a66:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a68:	85aa                	mv	a1,a0
{
ffffffffc0200a6a:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a6c:	00004517          	auipc	a0,0x4
ffffffffc0200a70:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0204508 <etext+0x706>
{
ffffffffc0200a74:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a76:	f1eff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a7a:	8522                	mv	a0,s0
ffffffffc0200a7c:	e1bff0ef          	jal	ffffffffc0200896 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a80:	10043583          	ld	a1,256(s0)
ffffffffc0200a84:	00004517          	auipc	a0,0x4
ffffffffc0200a88:	a9c50513          	addi	a0,a0,-1380 # ffffffffc0204520 <etext+0x71e>
ffffffffc0200a8c:	f08ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a90:	10843583          	ld	a1,264(s0)
ffffffffc0200a94:	00004517          	auipc	a0,0x4
ffffffffc0200a98:	aa450513          	addi	a0,a0,-1372 # ffffffffc0204538 <etext+0x736>
ffffffffc0200a9c:	ef8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200aa0:	11043583          	ld	a1,272(s0)
ffffffffc0200aa4:	00004517          	auipc	a0,0x4
ffffffffc0200aa8:	aac50513          	addi	a0,a0,-1364 # ffffffffc0204550 <etext+0x74e>
ffffffffc0200aac:	ee8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab0:	11843583          	ld	a1,280(s0)
}
ffffffffc0200ab4:	6402                	ld	s0,0(sp)
ffffffffc0200ab6:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ab8:	00004517          	auipc	a0,0x4
ffffffffc0200abc:	ab050513          	addi	a0,a0,-1360 # ffffffffc0204568 <etext+0x766>
}
ffffffffc0200ac0:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ac2:	ed2ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200ac6 <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200ac6:	11853783          	ld	a5,280(a0)
ffffffffc0200aca:	472d                	li	a4,11
ffffffffc0200acc:	0786                	slli	a5,a5,0x1
ffffffffc0200ace:	8385                	srli	a5,a5,0x1
ffffffffc0200ad0:	04f76b63          	bltu	a4,a5,ffffffffc0200b26 <interrupt_handler+0x60>
ffffffffc0200ad4:	00005717          	auipc	a4,0x5
ffffffffc0200ad8:	c3c70713          	addi	a4,a4,-964 # ffffffffc0205710 <commands+0x48>
ffffffffc0200adc:	078a                	slli	a5,a5,0x2
ffffffffc0200ade:	97ba                	add	a5,a5,a4
ffffffffc0200ae0:	439c                	lw	a5,0(a5)
ffffffffc0200ae2:	97ba                	add	a5,a5,a4
ffffffffc0200ae4:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200ae6:	00004517          	auipc	a0,0x4
ffffffffc0200aea:	afa50513          	addi	a0,a0,-1286 # ffffffffc02045e0 <etext+0x7de>
ffffffffc0200aee:	ea6ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200af2:	00004517          	auipc	a0,0x4
ffffffffc0200af6:	ace50513          	addi	a0,a0,-1330 # ffffffffc02045c0 <etext+0x7be>
ffffffffc0200afa:	e9aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200afe:	00004517          	auipc	a0,0x4
ffffffffc0200b02:	a8250513          	addi	a0,a0,-1406 # ffffffffc0204580 <etext+0x77e>
ffffffffc0200b06:	e8eff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b0a:	00004517          	auipc	a0,0x4
ffffffffc0200b0e:	a9650513          	addi	a0,a0,-1386 # ffffffffc02045a0 <etext+0x79e>
ffffffffc0200b12:	e82ff06f          	j	ffffffffc0200194 <cprintf>
        // In fact, Call sbi_set_timer will clear STIP, or you can clear it
        // directly.
        // clear_csr(sip, SIP_STIP);

        /*LAB3 请补充你在lab3中的代码 */ 
        clock_set_next_event();
ffffffffc0200b16:	987ff06f          	j	ffffffffc020049c <clock_set_next_event>
        break;
    case IRQ_U_EXT:
        cprintf("User software interrupt\n");
        break;
    case IRQ_S_EXT:
        cprintf("Supervisor external interrupt\n");
ffffffffc0200b1a:	00004517          	auipc	a0,0x4
ffffffffc0200b1e:	ae650513          	addi	a0,a0,-1306 # ffffffffc0204600 <etext+0x7fe>
ffffffffc0200b22:	e72ff06f          	j	ffffffffc0200194 <cprintf>
        break;
    case IRQ_M_EXT:
        cprintf("Machine software interrupt\n");
        break;
    default:
        print_trapframe(tf);
ffffffffc0200b26:	bf3d                	j	ffffffffc0200a64 <print_trapframe>

ffffffffc0200b28 <exception_handler>:
}

void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200b28:	11853783          	ld	a5,280(a0)
ffffffffc0200b2c:	473d                	li	a4,15
ffffffffc0200b2e:	0cf76563          	bltu	a4,a5,ffffffffc0200bf8 <exception_handler+0xd0>
ffffffffc0200b32:	00005717          	auipc	a4,0x5
ffffffffc0200b36:	c0e70713          	addi	a4,a4,-1010 # ffffffffc0205740 <commands+0x78>
ffffffffc0200b3a:	078a                	slli	a5,a5,0x2
ffffffffc0200b3c:	97ba                	add	a5,a5,a4
ffffffffc0200b3e:	439c                	lw	a5,0(a5)
ffffffffc0200b40:	97ba                	add	a5,a5,a4
ffffffffc0200b42:	8782                	jr	a5
        break;
    case CAUSE_LOAD_PAGE_FAULT:
        cprintf("Load page fault\n");
        break;
    case CAUSE_STORE_PAGE_FAULT:
        cprintf("Store/AMO page fault\n");
ffffffffc0200b44:	00004517          	auipc	a0,0x4
ffffffffc0200b48:	c5c50513          	addi	a0,a0,-932 # ffffffffc02047a0 <etext+0x99e>
ffffffffc0200b4c:	e48ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction address misaligned\n");
ffffffffc0200b50:	00004517          	auipc	a0,0x4
ffffffffc0200b54:	ad050513          	addi	a0,a0,-1328 # ffffffffc0204620 <etext+0x81e>
ffffffffc0200b58:	e3cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction access fault\n");
ffffffffc0200b5c:	00004517          	auipc	a0,0x4
ffffffffc0200b60:	ae450513          	addi	a0,a0,-1308 # ffffffffc0204640 <etext+0x83e>
ffffffffc0200b64:	e30ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Illegal instruction\n");
ffffffffc0200b68:	00004517          	auipc	a0,0x4
ffffffffc0200b6c:	af850513          	addi	a0,a0,-1288 # ffffffffc0204660 <etext+0x85e>
ffffffffc0200b70:	e24ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Breakpoint\n");
ffffffffc0200b74:	00004517          	auipc	a0,0x4
ffffffffc0200b78:	b0450513          	addi	a0,a0,-1276 # ffffffffc0204678 <etext+0x876>
ffffffffc0200b7c:	e18ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load address misaligned\n");
ffffffffc0200b80:	00004517          	auipc	a0,0x4
ffffffffc0200b84:	b0850513          	addi	a0,a0,-1272 # ffffffffc0204688 <etext+0x886>
ffffffffc0200b88:	e0cff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load access fault\n");
ffffffffc0200b8c:	00004517          	auipc	a0,0x4
ffffffffc0200b90:	b1c50513          	addi	a0,a0,-1252 # ffffffffc02046a8 <etext+0x8a6>
ffffffffc0200b94:	e00ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("AMO address misaligned\n");
ffffffffc0200b98:	00004517          	auipc	a0,0x4
ffffffffc0200b9c:	b2850513          	addi	a0,a0,-1240 # ffffffffc02046c0 <etext+0x8be>
ffffffffc0200ba0:	df4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Store/AMO access fault\n");
ffffffffc0200ba4:	00004517          	auipc	a0,0x4
ffffffffc0200ba8:	b3450513          	addi	a0,a0,-1228 # ffffffffc02046d8 <etext+0x8d6>
ffffffffc0200bac:	de8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from U-mode\n");
ffffffffc0200bb0:	00004517          	auipc	a0,0x4
ffffffffc0200bb4:	b4050513          	addi	a0,a0,-1216 # ffffffffc02046f0 <etext+0x8ee>
ffffffffc0200bb8:	ddcff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from S-mode\n");
ffffffffc0200bbc:	00004517          	auipc	a0,0x4
ffffffffc0200bc0:	b5450513          	addi	a0,a0,-1196 # ffffffffc0204710 <etext+0x90e>
ffffffffc0200bc4:	dd0ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from H-mode\n");
ffffffffc0200bc8:	00004517          	auipc	a0,0x4
ffffffffc0200bcc:	b6850513          	addi	a0,a0,-1176 # ffffffffc0204730 <etext+0x92e>
ffffffffc0200bd0:	dc4ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Environment call from M-mode\n");
ffffffffc0200bd4:	00004517          	auipc	a0,0x4
ffffffffc0200bd8:	b7c50513          	addi	a0,a0,-1156 # ffffffffc0204750 <etext+0x94e>
ffffffffc0200bdc:	db8ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Instruction page fault\n");
ffffffffc0200be0:	00004517          	auipc	a0,0x4
ffffffffc0200be4:	b9050513          	addi	a0,a0,-1136 # ffffffffc0204770 <etext+0x96e>
ffffffffc0200be8:	dacff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Load page fault\n");
ffffffffc0200bec:	00004517          	auipc	a0,0x4
ffffffffc0200bf0:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0204788 <etext+0x986>
ffffffffc0200bf4:	da0ff06f          	j	ffffffffc0200194 <cprintf>
        break;
    default:
        print_trapframe(tf);
ffffffffc0200bf8:	b5b5                	j	ffffffffc0200a64 <print_trapframe>

ffffffffc0200bfa <trap>:
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0)
ffffffffc0200bfa:	11853783          	ld	a5,280(a0)
ffffffffc0200bfe:	0007c363          	bltz	a5,ffffffffc0200c04 <trap+0xa>
        interrupt_handler(tf);
    }
    else
    {
        // exceptions
        exception_handler(tf);
ffffffffc0200c02:	b71d                	j	ffffffffc0200b28 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200c04:	b5c9                	j	ffffffffc0200ac6 <interrupt_handler>
	...

ffffffffc0200c08 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200c08:	14011073          	csrw	sscratch,sp
ffffffffc0200c0c:	712d                	addi	sp,sp,-288
ffffffffc0200c0e:	e406                	sd	ra,8(sp)
ffffffffc0200c10:	ec0e                	sd	gp,24(sp)
ffffffffc0200c12:	f012                	sd	tp,32(sp)
ffffffffc0200c14:	f416                	sd	t0,40(sp)
ffffffffc0200c16:	f81a                	sd	t1,48(sp)
ffffffffc0200c18:	fc1e                	sd	t2,56(sp)
ffffffffc0200c1a:	e0a2                	sd	s0,64(sp)
ffffffffc0200c1c:	e4a6                	sd	s1,72(sp)
ffffffffc0200c1e:	e8aa                	sd	a0,80(sp)
ffffffffc0200c20:	ecae                	sd	a1,88(sp)
ffffffffc0200c22:	f0b2                	sd	a2,96(sp)
ffffffffc0200c24:	f4b6                	sd	a3,104(sp)
ffffffffc0200c26:	f8ba                	sd	a4,112(sp)
ffffffffc0200c28:	fcbe                	sd	a5,120(sp)
ffffffffc0200c2a:	e142                	sd	a6,128(sp)
ffffffffc0200c2c:	e546                	sd	a7,136(sp)
ffffffffc0200c2e:	e94a                	sd	s2,144(sp)
ffffffffc0200c30:	ed4e                	sd	s3,152(sp)
ffffffffc0200c32:	f152                	sd	s4,160(sp)
ffffffffc0200c34:	f556                	sd	s5,168(sp)
ffffffffc0200c36:	f95a                	sd	s6,176(sp)
ffffffffc0200c38:	fd5e                	sd	s7,184(sp)
ffffffffc0200c3a:	e1e2                	sd	s8,192(sp)
ffffffffc0200c3c:	e5e6                	sd	s9,200(sp)
ffffffffc0200c3e:	e9ea                	sd	s10,208(sp)
ffffffffc0200c40:	edee                	sd	s11,216(sp)
ffffffffc0200c42:	f1f2                	sd	t3,224(sp)
ffffffffc0200c44:	f5f6                	sd	t4,232(sp)
ffffffffc0200c46:	f9fa                	sd	t5,240(sp)
ffffffffc0200c48:	fdfe                	sd	t6,248(sp)
ffffffffc0200c4a:	14002473          	csrr	s0,sscratch
ffffffffc0200c4e:	100024f3          	csrr	s1,sstatus
ffffffffc0200c52:	14102973          	csrr	s2,sepc
ffffffffc0200c56:	143029f3          	csrr	s3,stval
ffffffffc0200c5a:	14202a73          	csrr	s4,scause
ffffffffc0200c5e:	e822                	sd	s0,16(sp)
ffffffffc0200c60:	e226                	sd	s1,256(sp)
ffffffffc0200c62:	e64a                	sd	s2,264(sp)
ffffffffc0200c64:	ea4e                	sd	s3,272(sp)
ffffffffc0200c66:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200c68:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c6a:	f91ff0ef          	jal	ffffffffc0200bfa <trap>

ffffffffc0200c6e <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c6e:	6492                	ld	s1,256(sp)
ffffffffc0200c70:	6932                	ld	s2,264(sp)
ffffffffc0200c72:	10049073          	csrw	sstatus,s1
ffffffffc0200c76:	14191073          	csrw	sepc,s2
ffffffffc0200c7a:	60a2                	ld	ra,8(sp)
ffffffffc0200c7c:	61e2                	ld	gp,24(sp)
ffffffffc0200c7e:	7202                	ld	tp,32(sp)
ffffffffc0200c80:	72a2                	ld	t0,40(sp)
ffffffffc0200c82:	7342                	ld	t1,48(sp)
ffffffffc0200c84:	73e2                	ld	t2,56(sp)
ffffffffc0200c86:	6406                	ld	s0,64(sp)
ffffffffc0200c88:	64a6                	ld	s1,72(sp)
ffffffffc0200c8a:	6546                	ld	a0,80(sp)
ffffffffc0200c8c:	65e6                	ld	a1,88(sp)
ffffffffc0200c8e:	7606                	ld	a2,96(sp)
ffffffffc0200c90:	76a6                	ld	a3,104(sp)
ffffffffc0200c92:	7746                	ld	a4,112(sp)
ffffffffc0200c94:	77e6                	ld	a5,120(sp)
ffffffffc0200c96:	680a                	ld	a6,128(sp)
ffffffffc0200c98:	68aa                	ld	a7,136(sp)
ffffffffc0200c9a:	694a                	ld	s2,144(sp)
ffffffffc0200c9c:	69ea                	ld	s3,152(sp)
ffffffffc0200c9e:	7a0a                	ld	s4,160(sp)
ffffffffc0200ca0:	7aaa                	ld	s5,168(sp)
ffffffffc0200ca2:	7b4a                	ld	s6,176(sp)
ffffffffc0200ca4:	7bea                	ld	s7,184(sp)
ffffffffc0200ca6:	6c0e                	ld	s8,192(sp)
ffffffffc0200ca8:	6cae                	ld	s9,200(sp)
ffffffffc0200caa:	6d4e                	ld	s10,208(sp)
ffffffffc0200cac:	6dee                	ld	s11,216(sp)
ffffffffc0200cae:	7e0e                	ld	t3,224(sp)
ffffffffc0200cb0:	7eae                	ld	t4,232(sp)
ffffffffc0200cb2:	7f4e                	ld	t5,240(sp)
ffffffffc0200cb4:	7fee                	ld	t6,248(sp)
ffffffffc0200cb6:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200cb8:	10200073          	sret

ffffffffc0200cbc <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200cbc:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200cbe:	bf45                	j	ffffffffc0200c6e <__trapret>
ffffffffc0200cc0:	0001                	nop

ffffffffc0200cc2 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200cc2:	00008797          	auipc	a5,0x8
ffffffffc0200cc6:	76e78793          	addi	a5,a5,1902 # ffffffffc0209430 <free_area>
ffffffffc0200cca:	e79c                	sd	a5,8(a5)
ffffffffc0200ccc:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200cce:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200cd2:	8082                	ret

ffffffffc0200cd4 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200cd4:	00008517          	auipc	a0,0x8
ffffffffc0200cd8:	76c56503          	lwu	a0,1900(a0) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200cdc:	8082                	ret

ffffffffc0200cde <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200cde:	711d                	addi	sp,sp,-96
ffffffffc0200ce0:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200ce2:	00008917          	auipc	s2,0x8
ffffffffc0200ce6:	74e90913          	addi	s2,s2,1870 # ffffffffc0209430 <free_area>
ffffffffc0200cea:	00893783          	ld	a5,8(s2)
ffffffffc0200cee:	ec86                	sd	ra,88(sp)
ffffffffc0200cf0:	e8a2                	sd	s0,80(sp)
ffffffffc0200cf2:	e4a6                	sd	s1,72(sp)
ffffffffc0200cf4:	fc4e                	sd	s3,56(sp)
ffffffffc0200cf6:	f852                	sd	s4,48(sp)
ffffffffc0200cf8:	f456                	sd	s5,40(sp)
ffffffffc0200cfa:	f05a                	sd	s6,32(sp)
ffffffffc0200cfc:	ec5e                	sd	s7,24(sp)
ffffffffc0200cfe:	e862                	sd	s8,16(sp)
ffffffffc0200d00:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d02:	2f278763          	beq	a5,s2,ffffffffc0200ff0 <default_check+0x312>
    int count = 0, total = 0;
ffffffffc0200d06:	4401                	li	s0,0
ffffffffc0200d08:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d0a:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d0e:	8b09                	andi	a4,a4,2
ffffffffc0200d10:	2e070463          	beqz	a4,ffffffffc0200ff8 <default_check+0x31a>
        count ++, total += p->property;
ffffffffc0200d14:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d18:	679c                	ld	a5,8(a5)
ffffffffc0200d1a:	2485                	addiw	s1,s1,1
ffffffffc0200d1c:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d1e:	ff2796e3          	bne	a5,s2,ffffffffc0200d0a <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200d22:	89a2                	mv	s3,s0
ffffffffc0200d24:	745000ef          	jal	ffffffffc0201c68 <nr_free_pages>
ffffffffc0200d28:	73351863          	bne	a0,s3,ffffffffc0201458 <default_check+0x77a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d2c:	4505                	li	a0,1
ffffffffc0200d2e:	6c9000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200d32:	8a2a                	mv	s4,a0
ffffffffc0200d34:	46050263          	beqz	a0,ffffffffc0201198 <default_check+0x4ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d38:	4505                	li	a0,1
ffffffffc0200d3a:	6bd000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200d3e:	89aa                	mv	s3,a0
ffffffffc0200d40:	72050c63          	beqz	a0,ffffffffc0201478 <default_check+0x79a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d44:	4505                	li	a0,1
ffffffffc0200d46:	6b1000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200d4a:	8aaa                	mv	s5,a0
ffffffffc0200d4c:	4c050663          	beqz	a0,ffffffffc0201218 <default_check+0x53a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d50:	40aa07b3          	sub	a5,s4,a0
ffffffffc0200d54:	40a98733          	sub	a4,s3,a0
ffffffffc0200d58:	0017b793          	seqz	a5,a5
ffffffffc0200d5c:	00173713          	seqz	a4,a4
ffffffffc0200d60:	8fd9                	or	a5,a5,a4
ffffffffc0200d62:	30079b63          	bnez	a5,ffffffffc0201078 <default_check+0x39a>
ffffffffc0200d66:	313a0963          	beq	s4,s3,ffffffffc0201078 <default_check+0x39a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d6a:	000a2783          	lw	a5,0(s4)
ffffffffc0200d6e:	2a079563          	bnez	a5,ffffffffc0201018 <default_check+0x33a>
ffffffffc0200d72:	0009a783          	lw	a5,0(s3)
ffffffffc0200d76:	2a079163          	bnez	a5,ffffffffc0201018 <default_check+0x33a>
ffffffffc0200d7a:	411c                	lw	a5,0(a0)
ffffffffc0200d7c:	28079e63          	bnez	a5,ffffffffc0201018 <default_check+0x33a>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0200d80:	0000c797          	auipc	a5,0xc
ffffffffc0200d84:	7407b783          	ld	a5,1856(a5) # ffffffffc020d4c0 <pages>
ffffffffc0200d88:	00005617          	auipc	a2,0x5
ffffffffc0200d8c:	bc063603          	ld	a2,-1088(a2) # ffffffffc0205948 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200d90:	0000c697          	auipc	a3,0xc
ffffffffc0200d94:	7286b683          	ld	a3,1832(a3) # ffffffffc020d4b8 <npage>
ffffffffc0200d98:	40fa0733          	sub	a4,s4,a5
ffffffffc0200d9c:	8719                	srai	a4,a4,0x6
ffffffffc0200d9e:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0200da0:	0732                	slli	a4,a4,0xc
ffffffffc0200da2:	06b2                	slli	a3,a3,0xc
ffffffffc0200da4:	2ad77a63          	bgeu	a4,a3,ffffffffc0201058 <default_check+0x37a>
    return page - pages + nbase;
ffffffffc0200da8:	40f98733          	sub	a4,s3,a5
ffffffffc0200dac:	8719                	srai	a4,a4,0x6
ffffffffc0200dae:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200db0:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200db2:	4ed77363          	bgeu	a4,a3,ffffffffc0201298 <default_check+0x5ba>
    return page - pages + nbase;
ffffffffc0200db6:	40f507b3          	sub	a5,a0,a5
ffffffffc0200dba:	8799                	srai	a5,a5,0x6
ffffffffc0200dbc:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200dbe:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200dc0:	32d7fc63          	bgeu	a5,a3,ffffffffc02010f8 <default_check+0x41a>
    assert(alloc_page() == NULL);
ffffffffc0200dc4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200dc6:	00093c03          	ld	s8,0(s2)
ffffffffc0200dca:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200dce:	00008b17          	auipc	s6,0x8
ffffffffc0200dd2:	672b2b03          	lw	s6,1650(s6) # ffffffffc0209440 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc0200dd6:	01293023          	sd	s2,0(s2)
ffffffffc0200dda:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0200dde:	00008797          	auipc	a5,0x8
ffffffffc0200de2:	6607a123          	sw	zero,1634(a5) # ffffffffc0209440 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200de6:	611000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200dea:	2e051763          	bnez	a0,ffffffffc02010d8 <default_check+0x3fa>
    free_page(p0);
ffffffffc0200dee:	8552                	mv	a0,s4
ffffffffc0200df0:	4585                	li	a1,1
ffffffffc0200df2:	63f000ef          	jal	ffffffffc0201c30 <free_pages>
    free_page(p1);
ffffffffc0200df6:	854e                	mv	a0,s3
ffffffffc0200df8:	4585                	li	a1,1
ffffffffc0200dfa:	637000ef          	jal	ffffffffc0201c30 <free_pages>
    free_page(p2);
ffffffffc0200dfe:	8556                	mv	a0,s5
ffffffffc0200e00:	4585                	li	a1,1
ffffffffc0200e02:	62f000ef          	jal	ffffffffc0201c30 <free_pages>
    assert(nr_free == 3);
ffffffffc0200e06:	00008717          	auipc	a4,0x8
ffffffffc0200e0a:	63a72703          	lw	a4,1594(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200e0e:	478d                	li	a5,3
ffffffffc0200e10:	2af71463          	bne	a4,a5,ffffffffc02010b8 <default_check+0x3da>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e14:	4505                	li	a0,1
ffffffffc0200e16:	5e1000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200e1a:	89aa                	mv	s3,a0
ffffffffc0200e1c:	26050e63          	beqz	a0,ffffffffc0201098 <default_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e20:	4505                	li	a0,1
ffffffffc0200e22:	5d5000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200e26:	8aaa                	mv	s5,a0
ffffffffc0200e28:	3c050863          	beqz	a0,ffffffffc02011f8 <default_check+0x51a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e2c:	4505                	li	a0,1
ffffffffc0200e2e:	5c9000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200e32:	8a2a                	mv	s4,a0
ffffffffc0200e34:	3a050263          	beqz	a0,ffffffffc02011d8 <default_check+0x4fa>
    assert(alloc_page() == NULL);
ffffffffc0200e38:	4505                	li	a0,1
ffffffffc0200e3a:	5bd000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200e3e:	36051d63          	bnez	a0,ffffffffc02011b8 <default_check+0x4da>
    free_page(p0);
ffffffffc0200e42:	4585                	li	a1,1
ffffffffc0200e44:	854e                	mv	a0,s3
ffffffffc0200e46:	5eb000ef          	jal	ffffffffc0201c30 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200e4a:	00893783          	ld	a5,8(s2)
ffffffffc0200e4e:	1f278563          	beq	a5,s2,ffffffffc0201038 <default_check+0x35a>
    assert((p = alloc_page()) == p0);
ffffffffc0200e52:	4505                	li	a0,1
ffffffffc0200e54:	5a3000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200e58:	8caa                	mv	s9,a0
ffffffffc0200e5a:	30a99f63          	bne	s3,a0,ffffffffc0201178 <default_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc0200e5e:	4505                	li	a0,1
ffffffffc0200e60:	597000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200e64:	2e051a63          	bnez	a0,ffffffffc0201158 <default_check+0x47a>
    assert(nr_free == 0);
ffffffffc0200e68:	00008797          	auipc	a5,0x8
ffffffffc0200e6c:	5d87a783          	lw	a5,1496(a5) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200e70:	2c079463          	bnez	a5,ffffffffc0201138 <default_check+0x45a>
    free_page(p);
ffffffffc0200e74:	8566                	mv	a0,s9
ffffffffc0200e76:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200e78:	01893023          	sd	s8,0(s2)
ffffffffc0200e7c:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200e80:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200e84:	5ad000ef          	jal	ffffffffc0201c30 <free_pages>
    free_page(p1);
ffffffffc0200e88:	8556                	mv	a0,s5
ffffffffc0200e8a:	4585                	li	a1,1
ffffffffc0200e8c:	5a5000ef          	jal	ffffffffc0201c30 <free_pages>
    free_page(p2);
ffffffffc0200e90:	8552                	mv	a0,s4
ffffffffc0200e92:	4585                	li	a1,1
ffffffffc0200e94:	59d000ef          	jal	ffffffffc0201c30 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200e98:	4515                	li	a0,5
ffffffffc0200e9a:	55d000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200e9e:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200ea0:	26050c63          	beqz	a0,ffffffffc0201118 <default_check+0x43a>
ffffffffc0200ea4:	651c                	ld	a5,8(a0)
ffffffffc0200ea6:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200ea8:	8b85                	andi	a5,a5,1
ffffffffc0200eaa:	54079763          	bnez	a5,ffffffffc02013f8 <default_check+0x71a>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200eae:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200eb0:	00093b83          	ld	s7,0(s2)
ffffffffc0200eb4:	00893b03          	ld	s6,8(s2)
ffffffffc0200eb8:	01293023          	sd	s2,0(s2)
ffffffffc0200ebc:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200ec0:	537000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200ec4:	50051a63          	bnez	a0,ffffffffc02013d8 <default_check+0x6fa>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200ec8:	08098a13          	addi	s4,s3,128
ffffffffc0200ecc:	8552                	mv	a0,s4
ffffffffc0200ece:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200ed0:	00008c17          	auipc	s8,0x8
ffffffffc0200ed4:	570c2c03          	lw	s8,1392(s8) # ffffffffc0209440 <free_area+0x10>
    nr_free = 0;
ffffffffc0200ed8:	00008797          	auipc	a5,0x8
ffffffffc0200edc:	5607a423          	sw	zero,1384(a5) # ffffffffc0209440 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200ee0:	551000ef          	jal	ffffffffc0201c30 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200ee4:	4511                	li	a0,4
ffffffffc0200ee6:	511000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200eea:	4c051763          	bnez	a0,ffffffffc02013b8 <default_check+0x6da>
ffffffffc0200eee:	0889b783          	ld	a5,136(s3)
ffffffffc0200ef2:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200ef4:	8b85                	andi	a5,a5,1
ffffffffc0200ef6:	4a078163          	beqz	a5,ffffffffc0201398 <default_check+0x6ba>
ffffffffc0200efa:	0909a503          	lw	a0,144(s3)
ffffffffc0200efe:	478d                	li	a5,3
ffffffffc0200f00:	48f51c63          	bne	a0,a5,ffffffffc0201398 <default_check+0x6ba>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200f04:	4f3000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200f08:	8aaa                	mv	s5,a0
ffffffffc0200f0a:	46050763          	beqz	a0,ffffffffc0201378 <default_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc0200f0e:	4505                	li	a0,1
ffffffffc0200f10:	4e7000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200f14:	44051263          	bnez	a0,ffffffffc0201358 <default_check+0x67a>
    assert(p0 + 2 == p1);
ffffffffc0200f18:	435a1063          	bne	s4,s5,ffffffffc0201338 <default_check+0x65a>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200f1c:	4585                	li	a1,1
ffffffffc0200f1e:	854e                	mv	a0,s3
ffffffffc0200f20:	511000ef          	jal	ffffffffc0201c30 <free_pages>
    free_pages(p1, 3);
ffffffffc0200f24:	8552                	mv	a0,s4
ffffffffc0200f26:	458d                	li	a1,3
ffffffffc0200f28:	509000ef          	jal	ffffffffc0201c30 <free_pages>
ffffffffc0200f2c:	0089b783          	ld	a5,8(s3)
ffffffffc0200f30:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200f32:	8b85                	andi	a5,a5,1
ffffffffc0200f34:	3e078263          	beqz	a5,ffffffffc0201318 <default_check+0x63a>
ffffffffc0200f38:	0109aa83          	lw	s5,16(s3)
ffffffffc0200f3c:	4785                	li	a5,1
ffffffffc0200f3e:	3cfa9d63          	bne	s5,a5,ffffffffc0201318 <default_check+0x63a>
ffffffffc0200f42:	008a3783          	ld	a5,8(s4)
ffffffffc0200f46:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200f48:	8b85                	andi	a5,a5,1
ffffffffc0200f4a:	3a078763          	beqz	a5,ffffffffc02012f8 <default_check+0x61a>
ffffffffc0200f4e:	010a2703          	lw	a4,16(s4)
ffffffffc0200f52:	478d                	li	a5,3
ffffffffc0200f54:	3af71263          	bne	a4,a5,ffffffffc02012f8 <default_check+0x61a>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200f58:	8556                	mv	a0,s5
ffffffffc0200f5a:	49d000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200f5e:	36a99d63          	bne	s3,a0,ffffffffc02012d8 <default_check+0x5fa>
    free_page(p0);
ffffffffc0200f62:	85d6                	mv	a1,s5
ffffffffc0200f64:	4cd000ef          	jal	ffffffffc0201c30 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200f68:	4509                	li	a0,2
ffffffffc0200f6a:	48d000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200f6e:	34aa1563          	bne	s4,a0,ffffffffc02012b8 <default_check+0x5da>

    free_pages(p0, 2);
ffffffffc0200f72:	4589                	li	a1,2
ffffffffc0200f74:	4bd000ef          	jal	ffffffffc0201c30 <free_pages>
    free_page(p2);
ffffffffc0200f78:	04098513          	addi	a0,s3,64
ffffffffc0200f7c:	85d6                	mv	a1,s5
ffffffffc0200f7e:	4b3000ef          	jal	ffffffffc0201c30 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f82:	4515                	li	a0,5
ffffffffc0200f84:	473000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200f88:	89aa                	mv	s3,a0
ffffffffc0200f8a:	48050763          	beqz	a0,ffffffffc0201418 <default_check+0x73a>
    assert(alloc_page() == NULL);
ffffffffc0200f8e:	8556                	mv	a0,s5
ffffffffc0200f90:	467000ef          	jal	ffffffffc0201bf6 <alloc_pages>
ffffffffc0200f94:	2e051263          	bnez	a0,ffffffffc0201278 <default_check+0x59a>

    assert(nr_free == 0);
ffffffffc0200f98:	00008797          	auipc	a5,0x8
ffffffffc0200f9c:	4a87a783          	lw	a5,1192(a5) # ffffffffc0209440 <free_area+0x10>
ffffffffc0200fa0:	2a079c63          	bnez	a5,ffffffffc0201258 <default_check+0x57a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200fa4:	854e                	mv	a0,s3
ffffffffc0200fa6:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0200fa8:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc0200fac:	01793023          	sd	s7,0(s2)
ffffffffc0200fb0:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0200fb4:	47d000ef          	jal	ffffffffc0201c30 <free_pages>
    return listelm->next;
ffffffffc0200fb8:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fbc:	01278963          	beq	a5,s2,ffffffffc0200fce <default_check+0x2f0>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200fc0:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fc4:	679c                	ld	a5,8(a5)
ffffffffc0200fc6:	34fd                	addiw	s1,s1,-1
ffffffffc0200fc8:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fca:	ff279be3          	bne	a5,s2,ffffffffc0200fc0 <default_check+0x2e2>
    }
    assert(count == 0);
ffffffffc0200fce:	26049563          	bnez	s1,ffffffffc0201238 <default_check+0x55a>
    assert(total == 0);
ffffffffc0200fd2:	46041363          	bnez	s0,ffffffffc0201438 <default_check+0x75a>
}
ffffffffc0200fd6:	60e6                	ld	ra,88(sp)
ffffffffc0200fd8:	6446                	ld	s0,80(sp)
ffffffffc0200fda:	64a6                	ld	s1,72(sp)
ffffffffc0200fdc:	6906                	ld	s2,64(sp)
ffffffffc0200fde:	79e2                	ld	s3,56(sp)
ffffffffc0200fe0:	7a42                	ld	s4,48(sp)
ffffffffc0200fe2:	7aa2                	ld	s5,40(sp)
ffffffffc0200fe4:	7b02                	ld	s6,32(sp)
ffffffffc0200fe6:	6be2                	ld	s7,24(sp)
ffffffffc0200fe8:	6c42                	ld	s8,16(sp)
ffffffffc0200fea:	6ca2                	ld	s9,8(sp)
ffffffffc0200fec:	6125                	addi	sp,sp,96
ffffffffc0200fee:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ff0:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200ff2:	4401                	li	s0,0
ffffffffc0200ff4:	4481                	li	s1,0
ffffffffc0200ff6:	b33d                	j	ffffffffc0200d24 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0200ff8:	00003697          	auipc	a3,0x3
ffffffffc0200ffc:	7c068693          	addi	a3,a3,1984 # ffffffffc02047b8 <etext+0x9b6>
ffffffffc0201000:	00003617          	auipc	a2,0x3
ffffffffc0201004:	7c860613          	addi	a2,a2,1992 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201008:	0f000593          	li	a1,240
ffffffffc020100c:	00003517          	auipc	a0,0x3
ffffffffc0201010:	7d450513          	addi	a0,a0,2004 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201014:	bf2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201018:	00004697          	auipc	a3,0x4
ffffffffc020101c:	88868693          	addi	a3,a3,-1912 # ffffffffc02048a0 <etext+0xa9e>
ffffffffc0201020:	00003617          	auipc	a2,0x3
ffffffffc0201024:	7a860613          	addi	a2,a2,1960 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201028:	0be00593          	li	a1,190
ffffffffc020102c:	00003517          	auipc	a0,0x3
ffffffffc0201030:	7b450513          	addi	a0,a0,1972 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201034:	bd2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201038:	00004697          	auipc	a3,0x4
ffffffffc020103c:	93068693          	addi	a3,a3,-1744 # ffffffffc0204968 <etext+0xb66>
ffffffffc0201040:	00003617          	auipc	a2,0x3
ffffffffc0201044:	78860613          	addi	a2,a2,1928 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201048:	0d900593          	li	a1,217
ffffffffc020104c:	00003517          	auipc	a0,0x3
ffffffffc0201050:	79450513          	addi	a0,a0,1940 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201054:	bb2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201058:	00004697          	auipc	a3,0x4
ffffffffc020105c:	88868693          	addi	a3,a3,-1912 # ffffffffc02048e0 <etext+0xade>
ffffffffc0201060:	00003617          	auipc	a2,0x3
ffffffffc0201064:	76860613          	addi	a2,a2,1896 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201068:	0c000593          	li	a1,192
ffffffffc020106c:	00003517          	auipc	a0,0x3
ffffffffc0201070:	77450513          	addi	a0,a0,1908 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201074:	b92ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201078:	00004697          	auipc	a3,0x4
ffffffffc020107c:	80068693          	addi	a3,a3,-2048 # ffffffffc0204878 <etext+0xa76>
ffffffffc0201080:	00003617          	auipc	a2,0x3
ffffffffc0201084:	74860613          	addi	a2,a2,1864 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201088:	0bd00593          	li	a1,189
ffffffffc020108c:	00003517          	auipc	a0,0x3
ffffffffc0201090:	75450513          	addi	a0,a0,1876 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201094:	b72ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201098:	00003697          	auipc	a3,0x3
ffffffffc020109c:	78068693          	addi	a3,a3,1920 # ffffffffc0204818 <etext+0xa16>
ffffffffc02010a0:	00003617          	auipc	a2,0x3
ffffffffc02010a4:	72860613          	addi	a2,a2,1832 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02010a8:	0d200593          	li	a1,210
ffffffffc02010ac:	00003517          	auipc	a0,0x3
ffffffffc02010b0:	73450513          	addi	a0,a0,1844 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02010b4:	b52ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 3);
ffffffffc02010b8:	00004697          	auipc	a3,0x4
ffffffffc02010bc:	8a068693          	addi	a3,a3,-1888 # ffffffffc0204958 <etext+0xb56>
ffffffffc02010c0:	00003617          	auipc	a2,0x3
ffffffffc02010c4:	70860613          	addi	a2,a2,1800 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02010c8:	0d000593          	li	a1,208
ffffffffc02010cc:	00003517          	auipc	a0,0x3
ffffffffc02010d0:	71450513          	addi	a0,a0,1812 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02010d4:	b32ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010d8:	00004697          	auipc	a3,0x4
ffffffffc02010dc:	86868693          	addi	a3,a3,-1944 # ffffffffc0204940 <etext+0xb3e>
ffffffffc02010e0:	00003617          	auipc	a2,0x3
ffffffffc02010e4:	6e860613          	addi	a2,a2,1768 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02010e8:	0cb00593          	li	a1,203
ffffffffc02010ec:	00003517          	auipc	a0,0x3
ffffffffc02010f0:	6f450513          	addi	a0,a0,1780 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02010f4:	b12ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010f8:	00004697          	auipc	a3,0x4
ffffffffc02010fc:	82868693          	addi	a3,a3,-2008 # ffffffffc0204920 <etext+0xb1e>
ffffffffc0201100:	00003617          	auipc	a2,0x3
ffffffffc0201104:	6c860613          	addi	a2,a2,1736 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201108:	0c200593          	li	a1,194
ffffffffc020110c:	00003517          	auipc	a0,0x3
ffffffffc0201110:	6d450513          	addi	a0,a0,1748 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201114:	af2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 != NULL);
ffffffffc0201118:	00004697          	auipc	a3,0x4
ffffffffc020111c:	89868693          	addi	a3,a3,-1896 # ffffffffc02049b0 <etext+0xbae>
ffffffffc0201120:	00003617          	auipc	a2,0x3
ffffffffc0201124:	6a860613          	addi	a2,a2,1704 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201128:	0f800593          	li	a1,248
ffffffffc020112c:	00003517          	auipc	a0,0x3
ffffffffc0201130:	6b450513          	addi	a0,a0,1716 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201134:	ad2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 0);
ffffffffc0201138:	00004697          	auipc	a3,0x4
ffffffffc020113c:	86868693          	addi	a3,a3,-1944 # ffffffffc02049a0 <etext+0xb9e>
ffffffffc0201140:	00003617          	auipc	a2,0x3
ffffffffc0201144:	68860613          	addi	a2,a2,1672 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201148:	0df00593          	li	a1,223
ffffffffc020114c:	00003517          	auipc	a0,0x3
ffffffffc0201150:	69450513          	addi	a0,a0,1684 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201154:	ab2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201158:	00003697          	auipc	a3,0x3
ffffffffc020115c:	7e868693          	addi	a3,a3,2024 # ffffffffc0204940 <etext+0xb3e>
ffffffffc0201160:	00003617          	auipc	a2,0x3
ffffffffc0201164:	66860613          	addi	a2,a2,1640 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201168:	0dd00593          	li	a1,221
ffffffffc020116c:	00003517          	auipc	a0,0x3
ffffffffc0201170:	67450513          	addi	a0,a0,1652 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201174:	a92ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201178:	00004697          	auipc	a3,0x4
ffffffffc020117c:	80868693          	addi	a3,a3,-2040 # ffffffffc0204980 <etext+0xb7e>
ffffffffc0201180:	00003617          	auipc	a2,0x3
ffffffffc0201184:	64860613          	addi	a2,a2,1608 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201188:	0dc00593          	li	a1,220
ffffffffc020118c:	00003517          	auipc	a0,0x3
ffffffffc0201190:	65450513          	addi	a0,a0,1620 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201194:	a72ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201198:	00003697          	auipc	a3,0x3
ffffffffc020119c:	68068693          	addi	a3,a3,1664 # ffffffffc0204818 <etext+0xa16>
ffffffffc02011a0:	00003617          	auipc	a2,0x3
ffffffffc02011a4:	62860613          	addi	a2,a2,1576 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02011a8:	0b900593          	li	a1,185
ffffffffc02011ac:	00003517          	auipc	a0,0x3
ffffffffc02011b0:	63450513          	addi	a0,a0,1588 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02011b4:	a52ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011b8:	00003697          	auipc	a3,0x3
ffffffffc02011bc:	78868693          	addi	a3,a3,1928 # ffffffffc0204940 <etext+0xb3e>
ffffffffc02011c0:	00003617          	auipc	a2,0x3
ffffffffc02011c4:	60860613          	addi	a2,a2,1544 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02011c8:	0d600593          	li	a1,214
ffffffffc02011cc:	00003517          	auipc	a0,0x3
ffffffffc02011d0:	61450513          	addi	a0,a0,1556 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02011d4:	a32ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02011d8:	00003697          	auipc	a3,0x3
ffffffffc02011dc:	68068693          	addi	a3,a3,1664 # ffffffffc0204858 <etext+0xa56>
ffffffffc02011e0:	00003617          	auipc	a2,0x3
ffffffffc02011e4:	5e860613          	addi	a2,a2,1512 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02011e8:	0d400593          	li	a1,212
ffffffffc02011ec:	00003517          	auipc	a0,0x3
ffffffffc02011f0:	5f450513          	addi	a0,a0,1524 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02011f4:	a12ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02011f8:	00003697          	auipc	a3,0x3
ffffffffc02011fc:	64068693          	addi	a3,a3,1600 # ffffffffc0204838 <etext+0xa36>
ffffffffc0201200:	00003617          	auipc	a2,0x3
ffffffffc0201204:	5c860613          	addi	a2,a2,1480 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201208:	0d300593          	li	a1,211
ffffffffc020120c:	00003517          	auipc	a0,0x3
ffffffffc0201210:	5d450513          	addi	a0,a0,1492 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201214:	9f2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201218:	00003697          	auipc	a3,0x3
ffffffffc020121c:	64068693          	addi	a3,a3,1600 # ffffffffc0204858 <etext+0xa56>
ffffffffc0201220:	00003617          	auipc	a2,0x3
ffffffffc0201224:	5a860613          	addi	a2,a2,1448 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201228:	0bb00593          	li	a1,187
ffffffffc020122c:	00003517          	auipc	a0,0x3
ffffffffc0201230:	5b450513          	addi	a0,a0,1460 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201234:	9d2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(count == 0);
ffffffffc0201238:	00004697          	auipc	a3,0x4
ffffffffc020123c:	8c868693          	addi	a3,a3,-1848 # ffffffffc0204b00 <etext+0xcfe>
ffffffffc0201240:	00003617          	auipc	a2,0x3
ffffffffc0201244:	58860613          	addi	a2,a2,1416 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201248:	12500593          	li	a1,293
ffffffffc020124c:	00003517          	auipc	a0,0x3
ffffffffc0201250:	59450513          	addi	a0,a0,1428 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201254:	9b2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free == 0);
ffffffffc0201258:	00003697          	auipc	a3,0x3
ffffffffc020125c:	74868693          	addi	a3,a3,1864 # ffffffffc02049a0 <etext+0xb9e>
ffffffffc0201260:	00003617          	auipc	a2,0x3
ffffffffc0201264:	56860613          	addi	a2,a2,1384 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201268:	11a00593          	li	a1,282
ffffffffc020126c:	00003517          	auipc	a0,0x3
ffffffffc0201270:	57450513          	addi	a0,a0,1396 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201274:	992ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201278:	00003697          	auipc	a3,0x3
ffffffffc020127c:	6c868693          	addi	a3,a3,1736 # ffffffffc0204940 <etext+0xb3e>
ffffffffc0201280:	00003617          	auipc	a2,0x3
ffffffffc0201284:	54860613          	addi	a2,a2,1352 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201288:	11800593          	li	a1,280
ffffffffc020128c:	00003517          	auipc	a0,0x3
ffffffffc0201290:	55450513          	addi	a0,a0,1364 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201294:	972ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201298:	00003697          	auipc	a3,0x3
ffffffffc020129c:	66868693          	addi	a3,a3,1640 # ffffffffc0204900 <etext+0xafe>
ffffffffc02012a0:	00003617          	auipc	a2,0x3
ffffffffc02012a4:	52860613          	addi	a2,a2,1320 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02012a8:	0c100593          	li	a1,193
ffffffffc02012ac:	00003517          	auipc	a0,0x3
ffffffffc02012b0:	53450513          	addi	a0,a0,1332 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02012b4:	952ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02012b8:	00004697          	auipc	a3,0x4
ffffffffc02012bc:	80868693          	addi	a3,a3,-2040 # ffffffffc0204ac0 <etext+0xcbe>
ffffffffc02012c0:	00003617          	auipc	a2,0x3
ffffffffc02012c4:	50860613          	addi	a2,a2,1288 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02012c8:	11200593          	li	a1,274
ffffffffc02012cc:	00003517          	auipc	a0,0x3
ffffffffc02012d0:	51450513          	addi	a0,a0,1300 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02012d4:	932ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02012d8:	00003697          	auipc	a3,0x3
ffffffffc02012dc:	7c868693          	addi	a3,a3,1992 # ffffffffc0204aa0 <etext+0xc9e>
ffffffffc02012e0:	00003617          	auipc	a2,0x3
ffffffffc02012e4:	4e860613          	addi	a2,a2,1256 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02012e8:	11000593          	li	a1,272
ffffffffc02012ec:	00003517          	auipc	a0,0x3
ffffffffc02012f0:	4f450513          	addi	a0,a0,1268 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02012f4:	912ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02012f8:	00003697          	auipc	a3,0x3
ffffffffc02012fc:	78068693          	addi	a3,a3,1920 # ffffffffc0204a78 <etext+0xc76>
ffffffffc0201300:	00003617          	auipc	a2,0x3
ffffffffc0201304:	4c860613          	addi	a2,a2,1224 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201308:	10e00593          	li	a1,270
ffffffffc020130c:	00003517          	auipc	a0,0x3
ffffffffc0201310:	4d450513          	addi	a0,a0,1236 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201314:	8f2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201318:	00003697          	auipc	a3,0x3
ffffffffc020131c:	73868693          	addi	a3,a3,1848 # ffffffffc0204a50 <etext+0xc4e>
ffffffffc0201320:	00003617          	auipc	a2,0x3
ffffffffc0201324:	4a860613          	addi	a2,a2,1192 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201328:	10d00593          	li	a1,269
ffffffffc020132c:	00003517          	auipc	a0,0x3
ffffffffc0201330:	4b450513          	addi	a0,a0,1204 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201334:	8d2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201338:	00003697          	auipc	a3,0x3
ffffffffc020133c:	70868693          	addi	a3,a3,1800 # ffffffffc0204a40 <etext+0xc3e>
ffffffffc0201340:	00003617          	auipc	a2,0x3
ffffffffc0201344:	48860613          	addi	a2,a2,1160 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201348:	10800593          	li	a1,264
ffffffffc020134c:	00003517          	auipc	a0,0x3
ffffffffc0201350:	49450513          	addi	a0,a0,1172 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201354:	8b2ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201358:	00003697          	auipc	a3,0x3
ffffffffc020135c:	5e868693          	addi	a3,a3,1512 # ffffffffc0204940 <etext+0xb3e>
ffffffffc0201360:	00003617          	auipc	a2,0x3
ffffffffc0201364:	46860613          	addi	a2,a2,1128 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201368:	10700593          	li	a1,263
ffffffffc020136c:	00003517          	auipc	a0,0x3
ffffffffc0201370:	47450513          	addi	a0,a0,1140 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201374:	892ff0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201378:	00003697          	auipc	a3,0x3
ffffffffc020137c:	6a868693          	addi	a3,a3,1704 # ffffffffc0204a20 <etext+0xc1e>
ffffffffc0201380:	00003617          	auipc	a2,0x3
ffffffffc0201384:	44860613          	addi	a2,a2,1096 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201388:	10600593          	li	a1,262
ffffffffc020138c:	00003517          	auipc	a0,0x3
ffffffffc0201390:	45450513          	addi	a0,a0,1108 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201394:	872ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201398:	00003697          	auipc	a3,0x3
ffffffffc020139c:	65868693          	addi	a3,a3,1624 # ffffffffc02049f0 <etext+0xbee>
ffffffffc02013a0:	00003617          	auipc	a2,0x3
ffffffffc02013a4:	42860613          	addi	a2,a2,1064 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02013a8:	10500593          	li	a1,261
ffffffffc02013ac:	00003517          	auipc	a0,0x3
ffffffffc02013b0:	43450513          	addi	a0,a0,1076 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02013b4:	852ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02013b8:	00003697          	auipc	a3,0x3
ffffffffc02013bc:	62068693          	addi	a3,a3,1568 # ffffffffc02049d8 <etext+0xbd6>
ffffffffc02013c0:	00003617          	auipc	a2,0x3
ffffffffc02013c4:	40860613          	addi	a2,a2,1032 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02013c8:	10400593          	li	a1,260
ffffffffc02013cc:	00003517          	auipc	a0,0x3
ffffffffc02013d0:	41450513          	addi	a0,a0,1044 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02013d4:	832ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013d8:	00003697          	auipc	a3,0x3
ffffffffc02013dc:	56868693          	addi	a3,a3,1384 # ffffffffc0204940 <etext+0xb3e>
ffffffffc02013e0:	00003617          	auipc	a2,0x3
ffffffffc02013e4:	3e860613          	addi	a2,a2,1000 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02013e8:	0fe00593          	li	a1,254
ffffffffc02013ec:	00003517          	auipc	a0,0x3
ffffffffc02013f0:	3f450513          	addi	a0,a0,1012 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02013f4:	812ff0ef          	jal	ffffffffc0200406 <__panic>
    assert(!PageProperty(p0));
ffffffffc02013f8:	00003697          	auipc	a3,0x3
ffffffffc02013fc:	5c868693          	addi	a3,a3,1480 # ffffffffc02049c0 <etext+0xbbe>
ffffffffc0201400:	00003617          	auipc	a2,0x3
ffffffffc0201404:	3c860613          	addi	a2,a2,968 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201408:	0f900593          	li	a1,249
ffffffffc020140c:	00003517          	auipc	a0,0x3
ffffffffc0201410:	3d450513          	addi	a0,a0,980 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201414:	ff3fe0ef          	jal	ffffffffc0200406 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201418:	00003697          	auipc	a3,0x3
ffffffffc020141c:	6c868693          	addi	a3,a3,1736 # ffffffffc0204ae0 <etext+0xcde>
ffffffffc0201420:	00003617          	auipc	a2,0x3
ffffffffc0201424:	3a860613          	addi	a2,a2,936 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201428:	11700593          	li	a1,279
ffffffffc020142c:	00003517          	auipc	a0,0x3
ffffffffc0201430:	3b450513          	addi	a0,a0,948 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201434:	fd3fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(total == 0);
ffffffffc0201438:	00003697          	auipc	a3,0x3
ffffffffc020143c:	6d868693          	addi	a3,a3,1752 # ffffffffc0204b10 <etext+0xd0e>
ffffffffc0201440:	00003617          	auipc	a2,0x3
ffffffffc0201444:	38860613          	addi	a2,a2,904 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201448:	12600593          	li	a1,294
ffffffffc020144c:	00003517          	auipc	a0,0x3
ffffffffc0201450:	39450513          	addi	a0,a0,916 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201454:	fb3fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201458:	00003697          	auipc	a3,0x3
ffffffffc020145c:	3a068693          	addi	a3,a3,928 # ffffffffc02047f8 <etext+0x9f6>
ffffffffc0201460:	00003617          	auipc	a2,0x3
ffffffffc0201464:	36860613          	addi	a2,a2,872 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201468:	0f300593          	li	a1,243
ffffffffc020146c:	00003517          	auipc	a0,0x3
ffffffffc0201470:	37450513          	addi	a0,a0,884 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201474:	f93fe0ef          	jal	ffffffffc0200406 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201478:	00003697          	auipc	a3,0x3
ffffffffc020147c:	3c068693          	addi	a3,a3,960 # ffffffffc0204838 <etext+0xa36>
ffffffffc0201480:	00003617          	auipc	a2,0x3
ffffffffc0201484:	34860613          	addi	a2,a2,840 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201488:	0ba00593          	li	a1,186
ffffffffc020148c:	00003517          	auipc	a0,0x3
ffffffffc0201490:	35450513          	addi	a0,a0,852 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201494:	f73fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201498 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201498:	1141                	addi	sp,sp,-16
ffffffffc020149a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020149c:	14058663          	beqz	a1,ffffffffc02015e8 <default_free_pages+0x150>
    for (; p != base + n; p ++) {
ffffffffc02014a0:	00659713          	slli	a4,a1,0x6
ffffffffc02014a4:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02014a8:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02014aa:	c30d                	beqz	a4,ffffffffc02014cc <default_free_pages+0x34>
ffffffffc02014ac:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02014ae:	8b05                	andi	a4,a4,1
ffffffffc02014b0:	10071c63          	bnez	a4,ffffffffc02015c8 <default_free_pages+0x130>
ffffffffc02014b4:	6798                	ld	a4,8(a5)
ffffffffc02014b6:	8b09                	andi	a4,a4,2
ffffffffc02014b8:	10071863          	bnez	a4,ffffffffc02015c8 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc02014bc:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02014c0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02014c4:	04078793          	addi	a5,a5,64
ffffffffc02014c8:	fed792e3          	bne	a5,a3,ffffffffc02014ac <default_free_pages+0x14>
    base->property = n;
ffffffffc02014cc:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02014ce:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014d2:	4789                	li	a5,2
ffffffffc02014d4:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02014d8:	00008717          	auipc	a4,0x8
ffffffffc02014dc:	f6872703          	lw	a4,-152(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc02014e0:	00008697          	auipc	a3,0x8
ffffffffc02014e4:	f5068693          	addi	a3,a3,-176 # ffffffffc0209430 <free_area>
    return list->next == list;
ffffffffc02014e8:	669c                	ld	a5,8(a3)
ffffffffc02014ea:	9f2d                	addw	a4,a4,a1
ffffffffc02014ec:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014ee:	0ad78163          	beq	a5,a3,ffffffffc0201590 <default_free_pages+0xf8>
            struct Page* page = le2page(le, page_link);
ffffffffc02014f2:	fe878713          	addi	a4,a5,-24
ffffffffc02014f6:	4581                	li	a1,0
ffffffffc02014f8:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02014fc:	00e56a63          	bltu	a0,a4,ffffffffc0201510 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201500:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201502:	04d70c63          	beq	a4,a3,ffffffffc020155a <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc0201506:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201508:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020150c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201500 <default_free_pages+0x68>
ffffffffc0201510:	c199                	beqz	a1,ffffffffc0201516 <default_free_pages+0x7e>
ffffffffc0201512:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201516:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201518:	e390                	sd	a2,0(a5)
ffffffffc020151a:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc020151c:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc020151e:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201520:	00d70d63          	beq	a4,a3,ffffffffc020153a <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0201524:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201528:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc020152c:	02059813          	slli	a6,a1,0x20
ffffffffc0201530:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201534:	97b2                	add	a5,a5,a2
ffffffffc0201536:	02f50c63          	beq	a0,a5,ffffffffc020156e <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020153a:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc020153c:	00d78c63          	beq	a5,a3,ffffffffc0201554 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0201540:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201542:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0201546:	02061593          	slli	a1,a2,0x20
ffffffffc020154a:	01a5d713          	srli	a4,a1,0x1a
ffffffffc020154e:	972a                	add	a4,a4,a0
ffffffffc0201550:	04e68c63          	beq	a3,a4,ffffffffc02015a8 <default_free_pages+0x110>
}
ffffffffc0201554:	60a2                	ld	ra,8(sp)
ffffffffc0201556:	0141                	addi	sp,sp,16
ffffffffc0201558:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020155a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020155c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020155e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201560:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201562:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201564:	02d70f63          	beq	a4,a3,ffffffffc02015a2 <default_free_pages+0x10a>
ffffffffc0201568:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020156a:	87ba                	mv	a5,a4
ffffffffc020156c:	bf71                	j	ffffffffc0201508 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc020156e:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201570:	5875                	li	a6,-3
ffffffffc0201572:	9fad                	addw	a5,a5,a1
ffffffffc0201574:	fef72c23          	sw	a5,-8(a4)
ffffffffc0201578:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc020157c:	01853803          	ld	a6,24(a0)
ffffffffc0201580:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201582:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201584:	00b83423          	sd	a1,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    return listelm->next;
ffffffffc0201588:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020158a:	0105b023          	sd	a6,0(a1)
ffffffffc020158e:	b77d                	j	ffffffffc020153c <default_free_pages+0xa4>
}
ffffffffc0201590:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201592:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201596:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201598:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020159a:	e398                	sd	a4,0(a5)
ffffffffc020159c:	e798                	sd	a4,8(a5)
}
ffffffffc020159e:	0141                	addi	sp,sp,16
ffffffffc02015a0:	8082                	ret
ffffffffc02015a2:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02015a4:	873e                	mv	a4,a5
ffffffffc02015a6:	bfad                	j	ffffffffc0201520 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc02015a8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02015ac:	56f5                	li	a3,-3
ffffffffc02015ae:	9f31                	addw	a4,a4,a2
ffffffffc02015b0:	c918                	sw	a4,16(a0)
ffffffffc02015b2:	ff078713          	addi	a4,a5,-16
ffffffffc02015b6:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02015ba:	6398                	ld	a4,0(a5)
ffffffffc02015bc:	679c                	ld	a5,8(a5)
}
ffffffffc02015be:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02015c0:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02015c2:	e398                	sd	a4,0(a5)
ffffffffc02015c4:	0141                	addi	sp,sp,16
ffffffffc02015c6:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02015c8:	00003697          	auipc	a3,0x3
ffffffffc02015cc:	56068693          	addi	a3,a3,1376 # ffffffffc0204b28 <etext+0xd26>
ffffffffc02015d0:	00003617          	auipc	a2,0x3
ffffffffc02015d4:	1f860613          	addi	a2,a2,504 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02015d8:	08300593          	li	a1,131
ffffffffc02015dc:	00003517          	auipc	a0,0x3
ffffffffc02015e0:	20450513          	addi	a0,a0,516 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02015e4:	e23fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(n > 0);
ffffffffc02015e8:	00003697          	auipc	a3,0x3
ffffffffc02015ec:	53868693          	addi	a3,a3,1336 # ffffffffc0204b20 <etext+0xd1e>
ffffffffc02015f0:	00003617          	auipc	a2,0x3
ffffffffc02015f4:	1d860613          	addi	a2,a2,472 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02015f8:	08000593          	li	a1,128
ffffffffc02015fc:	00003517          	auipc	a0,0x3
ffffffffc0201600:	1e450513          	addi	a0,a0,484 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201604:	e03fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201608 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201608:	c951                	beqz	a0,ffffffffc020169c <default_alloc_pages+0x94>
    if (n > nr_free) {
ffffffffc020160a:	00008597          	auipc	a1,0x8
ffffffffc020160e:	e365a583          	lw	a1,-458(a1) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201612:	86aa                	mv	a3,a0
ffffffffc0201614:	02059793          	slli	a5,a1,0x20
ffffffffc0201618:	9381                	srli	a5,a5,0x20
ffffffffc020161a:	00a7ef63          	bltu	a5,a0,ffffffffc0201638 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc020161e:	00008617          	auipc	a2,0x8
ffffffffc0201622:	e1260613          	addi	a2,a2,-494 # ffffffffc0209430 <free_area>
ffffffffc0201626:	87b2                	mv	a5,a2
ffffffffc0201628:	a029                	j	ffffffffc0201632 <default_alloc_pages+0x2a>
        if (p->property >= n) {
ffffffffc020162a:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020162e:	00d77763          	bgeu	a4,a3,ffffffffc020163c <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc0201632:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201634:	fec79be3          	bne	a5,a2,ffffffffc020162a <default_alloc_pages+0x22>
        return NULL;
ffffffffc0201638:	4501                	li	a0,0
}
ffffffffc020163a:	8082                	ret
        if (page->property > n) {
ffffffffc020163c:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc0201640:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201644:	6798                	ld	a4,8(a5)
ffffffffc0201646:	02089313          	slli	t1,a7,0x20
ffffffffc020164a:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc020164e:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0201652:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc0201656:	fe878513          	addi	a0,a5,-24
        if (page->property > n) {
ffffffffc020165a:	0266fa63          	bgeu	a3,t1,ffffffffc020168e <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc020165e:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc0201662:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc0201666:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201668:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020166c:	00870313          	addi	t1,a4,8
ffffffffc0201670:	4889                	li	a7,2
ffffffffc0201672:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201676:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc020167a:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc020167e:	0068b023          	sd	t1,0(a7)
ffffffffc0201682:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc0201686:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc020168a:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc020168e:	9d95                	subw	a1,a1,a3
ffffffffc0201690:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201692:	5775                	li	a4,-3
ffffffffc0201694:	17c1                	addi	a5,a5,-16
ffffffffc0201696:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020169a:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020169c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020169e:	00003697          	auipc	a3,0x3
ffffffffc02016a2:	48268693          	addi	a3,a3,1154 # ffffffffc0204b20 <etext+0xd1e>
ffffffffc02016a6:	00003617          	auipc	a2,0x3
ffffffffc02016aa:	12260613          	addi	a2,a2,290 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02016ae:	06200593          	li	a1,98
ffffffffc02016b2:	00003517          	auipc	a0,0x3
ffffffffc02016b6:	12e50513          	addi	a0,a0,302 # ffffffffc02047e0 <etext+0x9de>
default_alloc_pages(size_t n) {
ffffffffc02016ba:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016bc:	d4bfe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02016c0 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02016c0:	1141                	addi	sp,sp,-16
ffffffffc02016c2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02016c4:	c9e1                	beqz	a1,ffffffffc0201794 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02016c6:	00659713          	slli	a4,a1,0x6
ffffffffc02016ca:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02016ce:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02016d0:	cf11                	beqz	a4,ffffffffc02016ec <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02016d2:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02016d4:	8b05                	andi	a4,a4,1
ffffffffc02016d6:	cf59                	beqz	a4,ffffffffc0201774 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02016d8:	0007a823          	sw	zero,16(a5)
ffffffffc02016dc:	0007b423          	sd	zero,8(a5)
ffffffffc02016e0:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02016e4:	04078793          	addi	a5,a5,64
ffffffffc02016e8:	fed795e3          	bne	a5,a3,ffffffffc02016d2 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02016ec:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02016ee:	4789                	li	a5,2
ffffffffc02016f0:	00850713          	addi	a4,a0,8
ffffffffc02016f4:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02016f8:	00008717          	auipc	a4,0x8
ffffffffc02016fc:	d4872703          	lw	a4,-696(a4) # ffffffffc0209440 <free_area+0x10>
ffffffffc0201700:	00008697          	auipc	a3,0x8
ffffffffc0201704:	d3068693          	addi	a3,a3,-720 # ffffffffc0209430 <free_area>
    return list->next == list;
ffffffffc0201708:	669c                	ld	a5,8(a3)
ffffffffc020170a:	9f2d                	addw	a4,a4,a1
ffffffffc020170c:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020170e:	04d78663          	beq	a5,a3,ffffffffc020175a <default_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201712:	fe878713          	addi	a4,a5,-24
ffffffffc0201716:	4581                	li	a1,0
ffffffffc0201718:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc020171c:	00e56a63          	bltu	a0,a4,ffffffffc0201730 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201720:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201722:	02d70263          	beq	a4,a3,ffffffffc0201746 <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc0201726:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201728:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020172c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201720 <default_init_memmap+0x60>
ffffffffc0201730:	c199                	beqz	a1,ffffffffc0201736 <default_init_memmap+0x76>
ffffffffc0201732:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201736:	6398                	ld	a4,0(a5)
}
ffffffffc0201738:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020173a:	e390                	sd	a2,0(a5)
ffffffffc020173c:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc020173e:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201740:	f11c                	sd	a5,32(a0)
ffffffffc0201742:	0141                	addi	sp,sp,16
ffffffffc0201744:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201746:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201748:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020174a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020174c:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020174e:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201750:	00d70e63          	beq	a4,a3,ffffffffc020176c <default_init_memmap+0xac>
ffffffffc0201754:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201756:	87ba                	mv	a5,a4
ffffffffc0201758:	bfc1                	j	ffffffffc0201728 <default_init_memmap+0x68>
}
ffffffffc020175a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020175c:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201760:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201762:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201764:	e398                	sd	a4,0(a5)
ffffffffc0201766:	e798                	sd	a4,8(a5)
}
ffffffffc0201768:	0141                	addi	sp,sp,16
ffffffffc020176a:	8082                	ret
ffffffffc020176c:	60a2                	ld	ra,8(sp)
ffffffffc020176e:	e290                	sd	a2,0(a3)
ffffffffc0201770:	0141                	addi	sp,sp,16
ffffffffc0201772:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201774:	00003697          	auipc	a3,0x3
ffffffffc0201778:	3dc68693          	addi	a3,a3,988 # ffffffffc0204b50 <etext+0xd4e>
ffffffffc020177c:	00003617          	auipc	a2,0x3
ffffffffc0201780:	04c60613          	addi	a2,a2,76 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201784:	04900593          	li	a1,73
ffffffffc0201788:	00003517          	auipc	a0,0x3
ffffffffc020178c:	05850513          	addi	a0,a0,88 # ffffffffc02047e0 <etext+0x9de>
ffffffffc0201790:	c77fe0ef          	jal	ffffffffc0200406 <__panic>
    assert(n > 0);
ffffffffc0201794:	00003697          	auipc	a3,0x3
ffffffffc0201798:	38c68693          	addi	a3,a3,908 # ffffffffc0204b20 <etext+0xd1e>
ffffffffc020179c:	00003617          	auipc	a2,0x3
ffffffffc02017a0:	02c60613          	addi	a2,a2,44 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02017a4:	04600593          	li	a1,70
ffffffffc02017a8:	00003517          	auipc	a0,0x3
ffffffffc02017ac:	03850513          	addi	a0,a0,56 # ffffffffc02047e0 <etext+0x9de>
ffffffffc02017b0:	c57fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02017b4 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02017b4:	c531                	beqz	a0,ffffffffc0201800 <slob_free+0x4c>
		return;

	if (size)
ffffffffc02017b6:	e9b9                	bnez	a1,ffffffffc020180c <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017b8:	100027f3          	csrr	a5,sstatus
ffffffffc02017bc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02017be:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02017c0:	efb1                	bnez	a5,ffffffffc020181c <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02017c2:	00008797          	auipc	a5,0x8
ffffffffc02017c6:	85e7b783          	ld	a5,-1954(a5) # ffffffffc0209020 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02017ca:	873e                	mv	a4,a5
ffffffffc02017cc:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02017ce:	02a77a63          	bgeu	a4,a0,ffffffffc0201802 <slob_free+0x4e>
ffffffffc02017d2:	00f56463          	bltu	a0,a5,ffffffffc02017da <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02017d6:	fef76ae3          	bltu	a4,a5,ffffffffc02017ca <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc02017da:	4110                	lw	a2,0(a0)
ffffffffc02017dc:	00461693          	slli	a3,a2,0x4
ffffffffc02017e0:	96aa                	add	a3,a3,a0
ffffffffc02017e2:	0ad78463          	beq	a5,a3,ffffffffc020188a <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc02017e6:	4310                	lw	a2,0(a4)
ffffffffc02017e8:	e51c                	sd	a5,8(a0)
ffffffffc02017ea:	00461693          	slli	a3,a2,0x4
ffffffffc02017ee:	96ba                	add	a3,a3,a4
ffffffffc02017f0:	08d50163          	beq	a0,a3,ffffffffc0201872 <slob_free+0xbe>
ffffffffc02017f4:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc02017f6:	00008797          	auipc	a5,0x8
ffffffffc02017fa:	82e7b523          	sd	a4,-2006(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc02017fe:	e9a5                	bnez	a1,ffffffffc020186e <slob_free+0xba>
ffffffffc0201800:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201802:	fcf574e3          	bgeu	a0,a5,ffffffffc02017ca <slob_free+0x16>
ffffffffc0201806:	fcf762e3          	bltu	a4,a5,ffffffffc02017ca <slob_free+0x16>
ffffffffc020180a:	bfc1                	j	ffffffffc02017da <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc020180c:	25bd                	addiw	a1,a1,15
ffffffffc020180e:	8191                	srli	a1,a1,0x4
ffffffffc0201810:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201812:	100027f3          	csrr	a5,sstatus
ffffffffc0201816:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201818:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020181a:	d7c5                	beqz	a5,ffffffffc02017c2 <slob_free+0xe>
{
ffffffffc020181c:	1101                	addi	sp,sp,-32
ffffffffc020181e:	e42a                	sd	a0,8(sp)
ffffffffc0201820:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201822:	852ff0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc0201826:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201828:	00007797          	auipc	a5,0x7
ffffffffc020182c:	7f87b783          	ld	a5,2040(a5) # ffffffffc0209020 <slobfree>
ffffffffc0201830:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201832:	873e                	mv	a4,a5
ffffffffc0201834:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201836:	06a77663          	bgeu	a4,a0,ffffffffc02018a2 <slob_free+0xee>
ffffffffc020183a:	00f56463          	bltu	a0,a5,ffffffffc0201842 <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020183e:	fef76ae3          	bltu	a4,a5,ffffffffc0201832 <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201842:	4110                	lw	a2,0(a0)
ffffffffc0201844:	00461693          	slli	a3,a2,0x4
ffffffffc0201848:	96aa                	add	a3,a3,a0
ffffffffc020184a:	06d78363          	beq	a5,a3,ffffffffc02018b0 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc020184e:	4310                	lw	a2,0(a4)
ffffffffc0201850:	e51c                	sd	a5,8(a0)
ffffffffc0201852:	00461693          	slli	a3,a2,0x4
ffffffffc0201856:	96ba                	add	a3,a3,a4
ffffffffc0201858:	06d50163          	beq	a0,a3,ffffffffc02018ba <slob_free+0x106>
ffffffffc020185c:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc020185e:	00007797          	auipc	a5,0x7
ffffffffc0201862:	7ce7b123          	sd	a4,1986(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc0201866:	e1a9                	bnez	a1,ffffffffc02018a8 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201868:	60e2                	ld	ra,24(sp)
ffffffffc020186a:	6105                	addi	sp,sp,32
ffffffffc020186c:	8082                	ret
        intr_enable();
ffffffffc020186e:	800ff06f          	j	ffffffffc020086e <intr_enable>
		cur->units += b->units;
ffffffffc0201872:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201874:	853e                	mv	a0,a5
ffffffffc0201876:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201878:	00c687bb          	addw	a5,a3,a2
ffffffffc020187c:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc020187e:	00007797          	auipc	a5,0x7
ffffffffc0201882:	7ae7b123          	sd	a4,1954(a5) # ffffffffc0209020 <slobfree>
    if (flag) {
ffffffffc0201886:	ddad                	beqz	a1,ffffffffc0201800 <slob_free+0x4c>
ffffffffc0201888:	b7dd                	j	ffffffffc020186e <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc020188a:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc020188c:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc020188e:	9eb1                	addw	a3,a3,a2
ffffffffc0201890:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201892:	4310                	lw	a2,0(a4)
ffffffffc0201894:	e51c                	sd	a5,8(a0)
ffffffffc0201896:	00461693          	slli	a3,a2,0x4
ffffffffc020189a:	96ba                	add	a3,a3,a4
ffffffffc020189c:	f4d51ce3          	bne	a0,a3,ffffffffc02017f4 <slob_free+0x40>
ffffffffc02018a0:	bfc9                	j	ffffffffc0201872 <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02018a2:	f8f56ee3          	bltu	a0,a5,ffffffffc020183e <slob_free+0x8a>
ffffffffc02018a6:	b771                	j	ffffffffc0201832 <slob_free+0x7e>
}
ffffffffc02018a8:	60e2                	ld	ra,24(sp)
ffffffffc02018aa:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02018ac:	fc3fe06f          	j	ffffffffc020086e <intr_enable>
		b->units += cur->next->units;
ffffffffc02018b0:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc02018b2:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc02018b4:	9eb1                	addw	a3,a3,a2
ffffffffc02018b6:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc02018b8:	bf59                	j	ffffffffc020184e <slob_free+0x9a>
		cur->units += b->units;
ffffffffc02018ba:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc02018bc:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc02018be:	00c687bb          	addw	a5,a3,a2
ffffffffc02018c2:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc02018c4:	bf61                	j	ffffffffc020185c <slob_free+0xa8>

ffffffffc02018c6 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018c6:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018c8:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018ca:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018ce:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc02018d0:	326000ef          	jal	ffffffffc0201bf6 <alloc_pages>
	if (!page)
ffffffffc02018d4:	c91d                	beqz	a0,ffffffffc020190a <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02018d6:	0000c697          	auipc	a3,0xc
ffffffffc02018da:	bea6b683          	ld	a3,-1046(a3) # ffffffffc020d4c0 <pages>
ffffffffc02018de:	00004797          	auipc	a5,0x4
ffffffffc02018e2:	06a7b783          	ld	a5,106(a5) # ffffffffc0205948 <nbase>
    return KADDR(page2pa(page));
ffffffffc02018e6:	0000c717          	auipc	a4,0xc
ffffffffc02018ea:	bd273703          	ld	a4,-1070(a4) # ffffffffc020d4b8 <npage>
    return page - pages + nbase;
ffffffffc02018ee:	8d15                	sub	a0,a0,a3
ffffffffc02018f0:	8519                	srai	a0,a0,0x6
ffffffffc02018f2:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc02018f4:	00c51793          	slli	a5,a0,0xc
ffffffffc02018f8:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02018fa:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc02018fc:	00e7fa63          	bgeu	a5,a4,ffffffffc0201910 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201900:	0000c797          	auipc	a5,0xc
ffffffffc0201904:	bb07b783          	ld	a5,-1104(a5) # ffffffffc020d4b0 <va_pa_offset>
ffffffffc0201908:	953e                	add	a0,a0,a5
}
ffffffffc020190a:	60a2                	ld	ra,8(sp)
ffffffffc020190c:	0141                	addi	sp,sp,16
ffffffffc020190e:	8082                	ret
ffffffffc0201910:	86aa                	mv	a3,a0
ffffffffc0201912:	00003617          	auipc	a2,0x3
ffffffffc0201916:	26660613          	addi	a2,a2,614 # ffffffffc0204b78 <etext+0xd76>
ffffffffc020191a:	07100593          	li	a1,113
ffffffffc020191e:	00003517          	auipc	a0,0x3
ffffffffc0201922:	28250513          	addi	a0,a0,642 # ffffffffc0204ba0 <etext+0xd9e>
ffffffffc0201926:	ae1fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020192a <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc020192a:	7179                	addi	sp,sp,-48
ffffffffc020192c:	f406                	sd	ra,40(sp)
ffffffffc020192e:	f022                	sd	s0,32(sp)
ffffffffc0201930:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201932:	01050713          	addi	a4,a0,16
ffffffffc0201936:	6785                	lui	a5,0x1
ffffffffc0201938:	0af77e63          	bgeu	a4,a5,ffffffffc02019f4 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc020193c:	00f50413          	addi	s0,a0,15
ffffffffc0201940:	8011                	srli	s0,s0,0x4
ffffffffc0201942:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201944:	100025f3          	csrr	a1,sstatus
ffffffffc0201948:	8989                	andi	a1,a1,2
ffffffffc020194a:	edd1                	bnez	a1,ffffffffc02019e6 <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc020194c:	00007497          	auipc	s1,0x7
ffffffffc0201950:	6d448493          	addi	s1,s1,1748 # ffffffffc0209020 <slobfree>
ffffffffc0201954:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201956:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201958:	4314                	lw	a3,0(a4)
ffffffffc020195a:	0886da63          	bge	a3,s0,ffffffffc02019ee <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc020195e:	00e60a63          	beq	a2,a4,ffffffffc0201972 <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201962:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201964:	4394                	lw	a3,0(a5)
ffffffffc0201966:	0286d863          	bge	a3,s0,ffffffffc0201996 <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc020196a:	6090                	ld	a2,0(s1)
ffffffffc020196c:	873e                	mv	a4,a5
ffffffffc020196e:	fee61ae3          	bne	a2,a4,ffffffffc0201962 <slob_alloc.constprop.0+0x38>
    if (flag) {
ffffffffc0201972:	e9b1                	bnez	a1,ffffffffc02019c6 <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201974:	4501                	li	a0,0
ffffffffc0201976:	f51ff0ef          	jal	ffffffffc02018c6 <__slob_get_free_pages.constprop.0>
ffffffffc020197a:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc020197c:	c915                	beqz	a0,ffffffffc02019b0 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc020197e:	6585                	lui	a1,0x1
ffffffffc0201980:	e35ff0ef          	jal	ffffffffc02017b4 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201984:	100025f3          	csrr	a1,sstatus
ffffffffc0201988:	8989                	andi	a1,a1,2
ffffffffc020198a:	e98d                	bnez	a1,ffffffffc02019bc <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc020198c:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc020198e:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201990:	4394                	lw	a3,0(a5)
ffffffffc0201992:	fc86cce3          	blt	a3,s0,ffffffffc020196a <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201996:	04d40563          	beq	s0,a3,ffffffffc02019e0 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc020199a:	00441613          	slli	a2,s0,0x4
ffffffffc020199e:	963e                	add	a2,a2,a5
ffffffffc02019a0:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc02019a2:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc02019a4:	9e81                	subw	a3,a3,s0
ffffffffc02019a6:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc02019a8:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc02019aa:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc02019ac:	e098                	sd	a4,0(s1)
    if (flag) {
ffffffffc02019ae:	ed99                	bnez	a1,ffffffffc02019cc <slob_alloc.constprop.0+0xa2>
}
ffffffffc02019b0:	70a2                	ld	ra,40(sp)
ffffffffc02019b2:	7402                	ld	s0,32(sp)
ffffffffc02019b4:	64e2                	ld	s1,24(sp)
ffffffffc02019b6:	853e                	mv	a0,a5
ffffffffc02019b8:	6145                	addi	sp,sp,48
ffffffffc02019ba:	8082                	ret
        intr_disable();
ffffffffc02019bc:	eb9fe0ef          	jal	ffffffffc0200874 <intr_disable>
			cur = slobfree;
ffffffffc02019c0:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc02019c2:	4585                	li	a1,1
ffffffffc02019c4:	b7e9                	j	ffffffffc020198e <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc02019c6:	ea9fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02019ca:	b76d                	j	ffffffffc0201974 <slob_alloc.constprop.0+0x4a>
ffffffffc02019cc:	e43e                	sd	a5,8(sp)
ffffffffc02019ce:	ea1fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02019d2:	67a2                	ld	a5,8(sp)
}
ffffffffc02019d4:	70a2                	ld	ra,40(sp)
ffffffffc02019d6:	7402                	ld	s0,32(sp)
ffffffffc02019d8:	64e2                	ld	s1,24(sp)
ffffffffc02019da:	853e                	mv	a0,a5
ffffffffc02019dc:	6145                	addi	sp,sp,48
ffffffffc02019de:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc02019e0:	6794                	ld	a3,8(a5)
ffffffffc02019e2:	e714                	sd	a3,8(a4)
ffffffffc02019e4:	b7e1                	j	ffffffffc02019ac <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc02019e6:	e8ffe0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc02019ea:	4585                	li	a1,1
ffffffffc02019ec:	b785                	j	ffffffffc020194c <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc02019ee:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc02019f0:	8732                	mv	a4,a2
ffffffffc02019f2:	b755                	j	ffffffffc0201996 <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc02019f4:	00003697          	auipc	a3,0x3
ffffffffc02019f8:	1bc68693          	addi	a3,a3,444 # ffffffffc0204bb0 <etext+0xdae>
ffffffffc02019fc:	00003617          	auipc	a2,0x3
ffffffffc0201a00:	dcc60613          	addi	a2,a2,-564 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0201a04:	06300593          	li	a1,99
ffffffffc0201a08:	00003517          	auipc	a0,0x3
ffffffffc0201a0c:	1c850513          	addi	a0,a0,456 # ffffffffc0204bd0 <etext+0xdce>
ffffffffc0201a10:	9f7fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201a14 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201a14:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201a16:	00003517          	auipc	a0,0x3
ffffffffc0201a1a:	1d250513          	addi	a0,a0,466 # ffffffffc0204be8 <etext+0xde6>
{
ffffffffc0201a1e:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201a20:	f74fe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a24:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a26:	00003517          	auipc	a0,0x3
ffffffffc0201a2a:	1da50513          	addi	a0,a0,474 # ffffffffc0204c00 <etext+0xdfe>
}
ffffffffc0201a2e:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a30:	f64fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201a34 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201a34:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a36:	6685                	lui	a3,0x1
{
ffffffffc0201a38:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201a3a:	16bd                	addi	a3,a3,-17 # fef <kern_entry-0xffffffffc01ff011>
ffffffffc0201a3c:	04a6f963          	bgeu	a3,a0,ffffffffc0201a8e <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201a40:	e42a                	sd	a0,8(sp)
ffffffffc0201a42:	4561                	li	a0,24
ffffffffc0201a44:	e822                	sd	s0,16(sp)
ffffffffc0201a46:	ee5ff0ef          	jal	ffffffffc020192a <slob_alloc.constprop.0>
ffffffffc0201a4a:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201a4c:	c541                	beqz	a0,ffffffffc0201ad4 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201a4e:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201a50:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201a52:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201a54:	00f75763          	bge	a4,a5,ffffffffc0201a62 <kmalloc+0x2e>
ffffffffc0201a58:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201a5c:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201a5e:	fef74de3          	blt	a4,a5,ffffffffc0201a58 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201a62:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201a64:	e63ff0ef          	jal	ffffffffc02018c6 <__slob_get_free_pages.constprop.0>
ffffffffc0201a68:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201a6a:	cd31                	beqz	a0,ffffffffc0201ac6 <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a6c:	100027f3          	csrr	a5,sstatus
ffffffffc0201a70:	8b89                	andi	a5,a5,2
ffffffffc0201a72:	eb85                	bnez	a5,ffffffffc0201aa2 <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201a74:	0000c797          	auipc	a5,0xc
ffffffffc0201a78:	a1c7b783          	ld	a5,-1508(a5) # ffffffffc020d490 <bigblocks>
		bigblocks = bb;
ffffffffc0201a7c:	0000c717          	auipc	a4,0xc
ffffffffc0201a80:	a0873a23          	sd	s0,-1516(a4) # ffffffffc020d490 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201a84:	e81c                	sd	a5,16(s0)
    if (flag) {
ffffffffc0201a86:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201a88:	60e2                	ld	ra,24(sp)
ffffffffc0201a8a:	6105                	addi	sp,sp,32
ffffffffc0201a8c:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201a8e:	0541                	addi	a0,a0,16
ffffffffc0201a90:	e9bff0ef          	jal	ffffffffc020192a <slob_alloc.constprop.0>
ffffffffc0201a94:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201a96:	0541                	addi	a0,a0,16
ffffffffc0201a98:	fbe5                	bnez	a5,ffffffffc0201a88 <kmalloc+0x54>
		return 0;
ffffffffc0201a9a:	4501                	li	a0,0
}
ffffffffc0201a9c:	60e2                	ld	ra,24(sp)
ffffffffc0201a9e:	6105                	addi	sp,sp,32
ffffffffc0201aa0:	8082                	ret
        intr_disable();
ffffffffc0201aa2:	dd3fe0ef          	jal	ffffffffc0200874 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201aa6:	0000c797          	auipc	a5,0xc
ffffffffc0201aaa:	9ea7b783          	ld	a5,-1558(a5) # ffffffffc020d490 <bigblocks>
		bigblocks = bb;
ffffffffc0201aae:	0000c717          	auipc	a4,0xc
ffffffffc0201ab2:	9e873123          	sd	s0,-1566(a4) # ffffffffc020d490 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201ab6:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201ab8:	db7fe0ef          	jal	ffffffffc020086e <intr_enable>
		return bb->pages;
ffffffffc0201abc:	6408                	ld	a0,8(s0)
}
ffffffffc0201abe:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201ac0:	6442                	ld	s0,16(sp)
}
ffffffffc0201ac2:	6105                	addi	sp,sp,32
ffffffffc0201ac4:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ac6:	8522                	mv	a0,s0
ffffffffc0201ac8:	45e1                	li	a1,24
ffffffffc0201aca:	cebff0ef          	jal	ffffffffc02017b4 <slob_free>
		return 0;
ffffffffc0201ace:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ad0:	6442                	ld	s0,16(sp)
ffffffffc0201ad2:	b7e9                	j	ffffffffc0201a9c <kmalloc+0x68>
ffffffffc0201ad4:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201ad6:	4501                	li	a0,0
ffffffffc0201ad8:	b7d1                	j	ffffffffc0201a9c <kmalloc+0x68>

ffffffffc0201ada <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201ada:	c571                	beqz	a0,ffffffffc0201ba6 <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201adc:	03451793          	slli	a5,a0,0x34
ffffffffc0201ae0:	e3e1                	bnez	a5,ffffffffc0201ba0 <kfree+0xc6>
{
ffffffffc0201ae2:	1101                	addi	sp,sp,-32
ffffffffc0201ae4:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ae6:	100027f3          	csrr	a5,sstatus
ffffffffc0201aea:	8b89                	andi	a5,a5,2
ffffffffc0201aec:	e7c1                	bnez	a5,ffffffffc0201b74 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201aee:	0000c797          	auipc	a5,0xc
ffffffffc0201af2:	9a27b783          	ld	a5,-1630(a5) # ffffffffc020d490 <bigblocks>
    return 0;
ffffffffc0201af6:	4581                	li	a1,0
ffffffffc0201af8:	cbad                	beqz	a5,ffffffffc0201b6a <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201afa:	0000c617          	auipc	a2,0xc
ffffffffc0201afe:	99660613          	addi	a2,a2,-1642 # ffffffffc020d490 <bigblocks>
ffffffffc0201b02:	a021                	j	ffffffffc0201b0a <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b04:	01070613          	addi	a2,a4,16
ffffffffc0201b08:	c3a5                	beqz	a5,ffffffffc0201b68 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201b0a:	6794                	ld	a3,8(a5)
ffffffffc0201b0c:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201b0e:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201b10:	fea69ae3          	bne	a3,a0,ffffffffc0201b04 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201b14:	e21c                	sd	a5,0(a2)
    if (flag) {
ffffffffc0201b16:	edb5                	bnez	a1,ffffffffc0201b92 <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201b18:	c02007b7          	lui	a5,0xc0200
ffffffffc0201b1c:	0af56263          	bltu	a0,a5,ffffffffc0201bc0 <kfree+0xe6>
ffffffffc0201b20:	0000c797          	auipc	a5,0xc
ffffffffc0201b24:	9907b783          	ld	a5,-1648(a5) # ffffffffc020d4b0 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201b28:	0000c697          	auipc	a3,0xc
ffffffffc0201b2c:	9906b683          	ld	a3,-1648(a3) # ffffffffc020d4b8 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201b30:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201b32:	00c55793          	srli	a5,a0,0xc
ffffffffc0201b36:	06d7f963          	bgeu	a5,a3,ffffffffc0201ba8 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b3a:	00004617          	auipc	a2,0x4
ffffffffc0201b3e:	e0e63603          	ld	a2,-498(a2) # ffffffffc0205948 <nbase>
ffffffffc0201b42:	0000c517          	auipc	a0,0xc
ffffffffc0201b46:	97e53503          	ld	a0,-1666(a0) # ffffffffc020d4c0 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201b4a:	4314                	lw	a3,0(a4)
ffffffffc0201b4c:	8f91                	sub	a5,a5,a2
ffffffffc0201b4e:	079a                	slli	a5,a5,0x6
ffffffffc0201b50:	4585                	li	a1,1
ffffffffc0201b52:	953e                	add	a0,a0,a5
ffffffffc0201b54:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201b58:	e03a                	sd	a4,0(sp)
ffffffffc0201b5a:	0d6000ef          	jal	ffffffffc0201c30 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b5e:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201b60:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b62:	45e1                	li	a1,24
}
ffffffffc0201b64:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201b66:	b1b9                	j	ffffffffc02017b4 <slob_free>
ffffffffc0201b68:	e185                	bnez	a1,ffffffffc0201b88 <kfree+0xae>
}
ffffffffc0201b6a:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201b6c:	1541                	addi	a0,a0,-16
ffffffffc0201b6e:	4581                	li	a1,0
}
ffffffffc0201b70:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201b72:	b189                	j	ffffffffc02017b4 <slob_free>
        intr_disable();
ffffffffc0201b74:	e02a                	sd	a0,0(sp)
ffffffffc0201b76:	cfffe0ef          	jal	ffffffffc0200874 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201b7a:	0000c797          	auipc	a5,0xc
ffffffffc0201b7e:	9167b783          	ld	a5,-1770(a5) # ffffffffc020d490 <bigblocks>
ffffffffc0201b82:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201b84:	4585                	li	a1,1
ffffffffc0201b86:	fbb5                	bnez	a5,ffffffffc0201afa <kfree+0x20>
ffffffffc0201b88:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201b8a:	ce5fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201b8e:	6502                	ld	a0,0(sp)
ffffffffc0201b90:	bfe9                	j	ffffffffc0201b6a <kfree+0x90>
ffffffffc0201b92:	e42a                	sd	a0,8(sp)
ffffffffc0201b94:	e03a                	sd	a4,0(sp)
ffffffffc0201b96:	cd9fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201b9a:	6522                	ld	a0,8(sp)
ffffffffc0201b9c:	6702                	ld	a4,0(sp)
ffffffffc0201b9e:	bfad                	j	ffffffffc0201b18 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201ba0:	1541                	addi	a0,a0,-16
ffffffffc0201ba2:	4581                	li	a1,0
ffffffffc0201ba4:	b901                	j	ffffffffc02017b4 <slob_free>
ffffffffc0201ba6:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201ba8:	00003617          	auipc	a2,0x3
ffffffffc0201bac:	0a060613          	addi	a2,a2,160 # ffffffffc0204c48 <etext+0xe46>
ffffffffc0201bb0:	06900593          	li	a1,105
ffffffffc0201bb4:	00003517          	auipc	a0,0x3
ffffffffc0201bb8:	fec50513          	addi	a0,a0,-20 # ffffffffc0204ba0 <etext+0xd9e>
ffffffffc0201bbc:	84bfe0ef          	jal	ffffffffc0200406 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201bc0:	86aa                	mv	a3,a0
ffffffffc0201bc2:	00003617          	auipc	a2,0x3
ffffffffc0201bc6:	05e60613          	addi	a2,a2,94 # ffffffffc0204c20 <etext+0xe1e>
ffffffffc0201bca:	07700593          	li	a1,119
ffffffffc0201bce:	00003517          	auipc	a0,0x3
ffffffffc0201bd2:	fd250513          	addi	a0,a0,-46 # ffffffffc0204ba0 <etext+0xd9e>
ffffffffc0201bd6:	831fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201bda <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201bda:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201bdc:	00003617          	auipc	a2,0x3
ffffffffc0201be0:	06c60613          	addi	a2,a2,108 # ffffffffc0204c48 <etext+0xe46>
ffffffffc0201be4:	06900593          	li	a1,105
ffffffffc0201be8:	00003517          	auipc	a0,0x3
ffffffffc0201bec:	fb850513          	addi	a0,a0,-72 # ffffffffc0204ba0 <etext+0xd9e>
pa2page(uintptr_t pa)
ffffffffc0201bf0:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201bf2:	815fe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201bf6 <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201bf6:	100027f3          	csrr	a5,sstatus
ffffffffc0201bfa:	8b89                	andi	a5,a5,2
ffffffffc0201bfc:	e799                	bnez	a5,ffffffffc0201c0a <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201bfe:	0000c797          	auipc	a5,0xc
ffffffffc0201c02:	89a7b783          	ld	a5,-1894(a5) # ffffffffc020d498 <pmm_manager>
ffffffffc0201c06:	6f9c                	ld	a5,24(a5)
ffffffffc0201c08:	8782                	jr	a5
{
ffffffffc0201c0a:	1101                	addi	sp,sp,-32
ffffffffc0201c0c:	ec06                	sd	ra,24(sp)
ffffffffc0201c0e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201c10:	c65fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201c14:	0000c797          	auipc	a5,0xc
ffffffffc0201c18:	8847b783          	ld	a5,-1916(a5) # ffffffffc020d498 <pmm_manager>
ffffffffc0201c1c:	6522                	ld	a0,8(sp)
ffffffffc0201c1e:	6f9c                	ld	a5,24(a5)
ffffffffc0201c20:	9782                	jalr	a5
ffffffffc0201c22:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201c24:	c4bfe0ef          	jal	ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201c28:	60e2                	ld	ra,24(sp)
ffffffffc0201c2a:	6522                	ld	a0,8(sp)
ffffffffc0201c2c:	6105                	addi	sp,sp,32
ffffffffc0201c2e:	8082                	ret

ffffffffc0201c30 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c30:	100027f3          	csrr	a5,sstatus
ffffffffc0201c34:	8b89                	andi	a5,a5,2
ffffffffc0201c36:	e799                	bnez	a5,ffffffffc0201c44 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201c38:	0000c797          	auipc	a5,0xc
ffffffffc0201c3c:	8607b783          	ld	a5,-1952(a5) # ffffffffc020d498 <pmm_manager>
ffffffffc0201c40:	739c                	ld	a5,32(a5)
ffffffffc0201c42:	8782                	jr	a5
{
ffffffffc0201c44:	1101                	addi	sp,sp,-32
ffffffffc0201c46:	ec06                	sd	ra,24(sp)
ffffffffc0201c48:	e42e                	sd	a1,8(sp)
ffffffffc0201c4a:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201c4c:	c29fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201c50:	0000c797          	auipc	a5,0xc
ffffffffc0201c54:	8487b783          	ld	a5,-1976(a5) # ffffffffc020d498 <pmm_manager>
ffffffffc0201c58:	65a2                	ld	a1,8(sp)
ffffffffc0201c5a:	6502                	ld	a0,0(sp)
ffffffffc0201c5c:	739c                	ld	a5,32(a5)
ffffffffc0201c5e:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201c60:	60e2                	ld	ra,24(sp)
ffffffffc0201c62:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201c64:	c0bfe06f          	j	ffffffffc020086e <intr_enable>

ffffffffc0201c68 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c68:	100027f3          	csrr	a5,sstatus
ffffffffc0201c6c:	8b89                	andi	a5,a5,2
ffffffffc0201c6e:	e799                	bnez	a5,ffffffffc0201c7c <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201c70:	0000c797          	auipc	a5,0xc
ffffffffc0201c74:	8287b783          	ld	a5,-2008(a5) # ffffffffc020d498 <pmm_manager>
ffffffffc0201c78:	779c                	ld	a5,40(a5)
ffffffffc0201c7a:	8782                	jr	a5
{
ffffffffc0201c7c:	1101                	addi	sp,sp,-32
ffffffffc0201c7e:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201c80:	bf5fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201c84:	0000c797          	auipc	a5,0xc
ffffffffc0201c88:	8147b783          	ld	a5,-2028(a5) # ffffffffc020d498 <pmm_manager>
ffffffffc0201c8c:	779c                	ld	a5,40(a5)
ffffffffc0201c8e:	9782                	jalr	a5
ffffffffc0201c90:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201c92:	bddfe0ef          	jal	ffffffffc020086e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201c96:	60e2                	ld	ra,24(sp)
ffffffffc0201c98:	6522                	ld	a0,8(sp)
ffffffffc0201c9a:	6105                	addi	sp,sp,32
ffffffffc0201c9c:	8082                	ret

ffffffffc0201c9e <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201c9e:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201ca2:	1ff7f793          	andi	a5,a5,511
ffffffffc0201ca6:	078e                	slli	a5,a5,0x3
ffffffffc0201ca8:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201cac:	6314                	ld	a3,0(a4)
{
ffffffffc0201cae:	7139                	addi	sp,sp,-64
ffffffffc0201cb0:	f822                	sd	s0,48(sp)
ffffffffc0201cb2:	f426                	sd	s1,40(sp)
ffffffffc0201cb4:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201cb6:	0016f793          	andi	a5,a3,1
{
ffffffffc0201cba:	842e                	mv	s0,a1
ffffffffc0201cbc:	8832                	mv	a6,a2
ffffffffc0201cbe:	0000b497          	auipc	s1,0xb
ffffffffc0201cc2:	7fa48493          	addi	s1,s1,2042 # ffffffffc020d4b8 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201cc6:	ebd1                	bnez	a5,ffffffffc0201d5a <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201cc8:	16060d63          	beqz	a2,ffffffffc0201e42 <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ccc:	100027f3          	csrr	a5,sstatus
ffffffffc0201cd0:	8b89                	andi	a5,a5,2
ffffffffc0201cd2:	16079e63          	bnez	a5,ffffffffc0201e4e <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201cd6:	0000b797          	auipc	a5,0xb
ffffffffc0201cda:	7c27b783          	ld	a5,1986(a5) # ffffffffc020d498 <pmm_manager>
ffffffffc0201cde:	4505                	li	a0,1
ffffffffc0201ce0:	e43a                	sd	a4,8(sp)
ffffffffc0201ce2:	6f9c                	ld	a5,24(a5)
ffffffffc0201ce4:	e832                	sd	a2,16(sp)
ffffffffc0201ce6:	9782                	jalr	a5
ffffffffc0201ce8:	6722                	ld	a4,8(sp)
ffffffffc0201cea:	6842                	ld	a6,16(sp)
ffffffffc0201cec:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201cee:	14078a63          	beqz	a5,ffffffffc0201e42 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201cf2:	0000b517          	auipc	a0,0xb
ffffffffc0201cf6:	7ce53503          	ld	a0,1998(a0) # ffffffffc020d4c0 <pages>
ffffffffc0201cfa:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201cfe:	0000b497          	auipc	s1,0xb
ffffffffc0201d02:	7ba48493          	addi	s1,s1,1978 # ffffffffc020d4b8 <npage>
ffffffffc0201d06:	40a78533          	sub	a0,a5,a0
ffffffffc0201d0a:	8519                	srai	a0,a0,0x6
ffffffffc0201d0c:	9546                	add	a0,a0,a7
ffffffffc0201d0e:	6090                	ld	a2,0(s1)
ffffffffc0201d10:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201d14:	4585                	li	a1,1
ffffffffc0201d16:	82b1                	srli	a3,a3,0xc
ffffffffc0201d18:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d1a:	0532                	slli	a0,a0,0xc
ffffffffc0201d1c:	1ac6f763          	bgeu	a3,a2,ffffffffc0201eca <get_pte+0x22c>
ffffffffc0201d20:	0000b697          	auipc	a3,0xb
ffffffffc0201d24:	7906b683          	ld	a3,1936(a3) # ffffffffc020d4b0 <va_pa_offset>
ffffffffc0201d28:	6605                	lui	a2,0x1
ffffffffc0201d2a:	4581                	li	a1,0
ffffffffc0201d2c:	9536                	add	a0,a0,a3
ffffffffc0201d2e:	ec42                	sd	a6,24(sp)
ffffffffc0201d30:	e83e                	sd	a5,16(sp)
ffffffffc0201d32:	e43a                	sd	a4,8(sp)
ffffffffc0201d34:	080020ef          	jal	ffffffffc0203db4 <memset>
    return page - pages + nbase;
ffffffffc0201d38:	0000b697          	auipc	a3,0xb
ffffffffc0201d3c:	7886b683          	ld	a3,1928(a3) # ffffffffc020d4c0 <pages>
ffffffffc0201d40:	67c2                	ld	a5,16(sp)
ffffffffc0201d42:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201d46:	6722                	ld	a4,8(sp)
ffffffffc0201d48:	40d786b3          	sub	a3,a5,a3
ffffffffc0201d4c:	8699                	srai	a3,a3,0x6
ffffffffc0201d4e:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201d50:	06aa                	slli	a3,a3,0xa
ffffffffc0201d52:	6862                	ld	a6,24(sp)
ffffffffc0201d54:	0116e693          	ori	a3,a3,17
ffffffffc0201d58:	e314                	sd	a3,0(a4)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201d5a:	c006f693          	andi	a3,a3,-1024
ffffffffc0201d5e:	6098                	ld	a4,0(s1)
ffffffffc0201d60:	068a                	slli	a3,a3,0x2
ffffffffc0201d62:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201d66:	14e7f663          	bgeu	a5,a4,ffffffffc0201eb2 <get_pte+0x214>
ffffffffc0201d6a:	0000b897          	auipc	a7,0xb
ffffffffc0201d6e:	74688893          	addi	a7,a7,1862 # ffffffffc020d4b0 <va_pa_offset>
ffffffffc0201d72:	0008b603          	ld	a2,0(a7)
ffffffffc0201d76:	01545793          	srli	a5,s0,0x15
ffffffffc0201d7a:	1ff7f793          	andi	a5,a5,511
ffffffffc0201d7e:	96b2                	add	a3,a3,a2
ffffffffc0201d80:	078e                	slli	a5,a5,0x3
ffffffffc0201d82:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0201d84:	6394                	ld	a3,0(a5)
ffffffffc0201d86:	0016f613          	andi	a2,a3,1
ffffffffc0201d8a:	e659                	bnez	a2,ffffffffc0201e18 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201d8c:	0a080b63          	beqz	a6,ffffffffc0201e42 <get_pte+0x1a4>
ffffffffc0201d90:	10002773          	csrr	a4,sstatus
ffffffffc0201d94:	8b09                	andi	a4,a4,2
ffffffffc0201d96:	ef71                	bnez	a4,ffffffffc0201e72 <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201d98:	0000b717          	auipc	a4,0xb
ffffffffc0201d9c:	70073703          	ld	a4,1792(a4) # ffffffffc020d498 <pmm_manager>
ffffffffc0201da0:	4505                	li	a0,1
ffffffffc0201da2:	e43e                	sd	a5,8(sp)
ffffffffc0201da4:	6f18                	ld	a4,24(a4)
ffffffffc0201da6:	9702                	jalr	a4
ffffffffc0201da8:	67a2                	ld	a5,8(sp)
ffffffffc0201daa:	872a                	mv	a4,a0
ffffffffc0201dac:	0000b897          	auipc	a7,0xb
ffffffffc0201db0:	70488893          	addi	a7,a7,1796 # ffffffffc020d4b0 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201db4:	c759                	beqz	a4,ffffffffc0201e42 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201db6:	0000b697          	auipc	a3,0xb
ffffffffc0201dba:	70a6b683          	ld	a3,1802(a3) # ffffffffc020d4c0 <pages>
ffffffffc0201dbe:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201dc2:	608c                	ld	a1,0(s1)
ffffffffc0201dc4:	40d706b3          	sub	a3,a4,a3
ffffffffc0201dc8:	8699                	srai	a3,a3,0x6
ffffffffc0201dca:	96c2                	add	a3,a3,a6
ffffffffc0201dcc:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0201dd0:	4505                	li	a0,1
ffffffffc0201dd2:	8231                	srli	a2,a2,0xc
ffffffffc0201dd4:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201dd6:	06b2                	slli	a3,a3,0xc
ffffffffc0201dd8:	10b67663          	bgeu	a2,a1,ffffffffc0201ee4 <get_pte+0x246>
ffffffffc0201ddc:	0008b503          	ld	a0,0(a7)
ffffffffc0201de0:	6605                	lui	a2,0x1
ffffffffc0201de2:	4581                	li	a1,0
ffffffffc0201de4:	9536                	add	a0,a0,a3
ffffffffc0201de6:	e83a                	sd	a4,16(sp)
ffffffffc0201de8:	e43e                	sd	a5,8(sp)
ffffffffc0201dea:	7cb010ef          	jal	ffffffffc0203db4 <memset>
    return page - pages + nbase;
ffffffffc0201dee:	0000b697          	auipc	a3,0xb
ffffffffc0201df2:	6d26b683          	ld	a3,1746(a3) # ffffffffc020d4c0 <pages>
ffffffffc0201df6:	6742                	ld	a4,16(sp)
ffffffffc0201df8:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201dfc:	67a2                	ld	a5,8(sp)
ffffffffc0201dfe:	40d706b3          	sub	a3,a4,a3
ffffffffc0201e02:	8699                	srai	a3,a3,0x6
ffffffffc0201e04:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201e06:	06aa                	slli	a3,a3,0xa
ffffffffc0201e08:	0116e693          	ori	a3,a3,17
ffffffffc0201e0c:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e0e:	6098                	ld	a4,0(s1)
ffffffffc0201e10:	0000b897          	auipc	a7,0xb
ffffffffc0201e14:	6a088893          	addi	a7,a7,1696 # ffffffffc020d4b0 <va_pa_offset>
ffffffffc0201e18:	c006f693          	andi	a3,a3,-1024
ffffffffc0201e1c:	068a                	slli	a3,a3,0x2
ffffffffc0201e1e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201e22:	06e7fc63          	bgeu	a5,a4,ffffffffc0201e9a <get_pte+0x1fc>
ffffffffc0201e26:	0008b783          	ld	a5,0(a7)
ffffffffc0201e2a:	8031                	srli	s0,s0,0xc
ffffffffc0201e2c:	1ff47413          	andi	s0,s0,511
ffffffffc0201e30:	040e                	slli	s0,s0,0x3
ffffffffc0201e32:	96be                	add	a3,a3,a5
}
ffffffffc0201e34:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e36:	00868533          	add	a0,a3,s0
}
ffffffffc0201e3a:	7442                	ld	s0,48(sp)
ffffffffc0201e3c:	74a2                	ld	s1,40(sp)
ffffffffc0201e3e:	6121                	addi	sp,sp,64
ffffffffc0201e40:	8082                	ret
ffffffffc0201e42:	70e2                	ld	ra,56(sp)
ffffffffc0201e44:	7442                	ld	s0,48(sp)
ffffffffc0201e46:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0201e48:	4501                	li	a0,0
}
ffffffffc0201e4a:	6121                	addi	sp,sp,64
ffffffffc0201e4c:	8082                	ret
        intr_disable();
ffffffffc0201e4e:	e83a                	sd	a4,16(sp)
ffffffffc0201e50:	ec32                	sd	a2,24(sp)
ffffffffc0201e52:	a23fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e56:	0000b797          	auipc	a5,0xb
ffffffffc0201e5a:	6427b783          	ld	a5,1602(a5) # ffffffffc020d498 <pmm_manager>
ffffffffc0201e5e:	4505                	li	a0,1
ffffffffc0201e60:	6f9c                	ld	a5,24(a5)
ffffffffc0201e62:	9782                	jalr	a5
ffffffffc0201e64:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201e66:	a09fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201e6a:	6862                	ld	a6,24(sp)
ffffffffc0201e6c:	6742                	ld	a4,16(sp)
ffffffffc0201e6e:	67a2                	ld	a5,8(sp)
ffffffffc0201e70:	bdbd                	j	ffffffffc0201cee <get_pte+0x50>
        intr_disable();
ffffffffc0201e72:	e83e                	sd	a5,16(sp)
ffffffffc0201e74:	a01fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0201e78:	0000b717          	auipc	a4,0xb
ffffffffc0201e7c:	62073703          	ld	a4,1568(a4) # ffffffffc020d498 <pmm_manager>
ffffffffc0201e80:	4505                	li	a0,1
ffffffffc0201e82:	6f18                	ld	a4,24(a4)
ffffffffc0201e84:	9702                	jalr	a4
ffffffffc0201e86:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201e88:	9e7fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201e8c:	6722                	ld	a4,8(sp)
ffffffffc0201e8e:	67c2                	ld	a5,16(sp)
ffffffffc0201e90:	0000b897          	auipc	a7,0xb
ffffffffc0201e94:	62088893          	addi	a7,a7,1568 # ffffffffc020d4b0 <va_pa_offset>
ffffffffc0201e98:	bf31                	j	ffffffffc0201db4 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0201e9a:	00003617          	auipc	a2,0x3
ffffffffc0201e9e:	cde60613          	addi	a2,a2,-802 # ffffffffc0204b78 <etext+0xd76>
ffffffffc0201ea2:	0fb00593          	li	a1,251
ffffffffc0201ea6:	00003517          	auipc	a0,0x3
ffffffffc0201eaa:	dc250513          	addi	a0,a0,-574 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0201eae:	d58fe0ef          	jal	ffffffffc0200406 <__panic>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201eb2:	00003617          	auipc	a2,0x3
ffffffffc0201eb6:	cc660613          	addi	a2,a2,-826 # ffffffffc0204b78 <etext+0xd76>
ffffffffc0201eba:	0ee00593          	li	a1,238
ffffffffc0201ebe:	00003517          	auipc	a0,0x3
ffffffffc0201ec2:	daa50513          	addi	a0,a0,-598 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0201ec6:	d40fe0ef          	jal	ffffffffc0200406 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201eca:	86aa                	mv	a3,a0
ffffffffc0201ecc:	00003617          	auipc	a2,0x3
ffffffffc0201ed0:	cac60613          	addi	a2,a2,-852 # ffffffffc0204b78 <etext+0xd76>
ffffffffc0201ed4:	0eb00593          	li	a1,235
ffffffffc0201ed8:	00003517          	auipc	a0,0x3
ffffffffc0201edc:	d9050513          	addi	a0,a0,-624 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0201ee0:	d26fe0ef          	jal	ffffffffc0200406 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ee4:	00003617          	auipc	a2,0x3
ffffffffc0201ee8:	c9460613          	addi	a2,a2,-876 # ffffffffc0204b78 <etext+0xd76>
ffffffffc0201eec:	0f800593          	li	a1,248
ffffffffc0201ef0:	00003517          	auipc	a0,0x3
ffffffffc0201ef4:	d7850513          	addi	a0,a0,-648 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0201ef8:	d0efe0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0201efc <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0201efc:	1141                	addi	sp,sp,-16
ffffffffc0201efe:	e022                	sd	s0,0(sp)
ffffffffc0201f00:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f02:	4601                	li	a2,0
{
ffffffffc0201f04:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f06:	d99ff0ef          	jal	ffffffffc0201c9e <get_pte>
    if (ptep_store != NULL)
ffffffffc0201f0a:	c011                	beqz	s0,ffffffffc0201f0e <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0201f0c:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f0e:	c511                	beqz	a0,ffffffffc0201f1a <get_page+0x1e>
ffffffffc0201f10:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0201f12:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0201f14:	0017f713          	andi	a4,a5,1
ffffffffc0201f18:	e709                	bnez	a4,ffffffffc0201f22 <get_page+0x26>
}
ffffffffc0201f1a:	60a2                	ld	ra,8(sp)
ffffffffc0201f1c:	6402                	ld	s0,0(sp)
ffffffffc0201f1e:	0141                	addi	sp,sp,16
ffffffffc0201f20:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201f22:	0000b717          	auipc	a4,0xb
ffffffffc0201f26:	59673703          	ld	a4,1430(a4) # ffffffffc020d4b8 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f2a:	078a                	slli	a5,a5,0x2
ffffffffc0201f2c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f2e:	00e7ff63          	bgeu	a5,a4,ffffffffc0201f4c <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f32:	0000b517          	auipc	a0,0xb
ffffffffc0201f36:	58e53503          	ld	a0,1422(a0) # ffffffffc020d4c0 <pages>
ffffffffc0201f3a:	60a2                	ld	ra,8(sp)
ffffffffc0201f3c:	6402                	ld	s0,0(sp)
ffffffffc0201f3e:	079a                	slli	a5,a5,0x6
ffffffffc0201f40:	fe000737          	lui	a4,0xfe000
ffffffffc0201f44:	97ba                	add	a5,a5,a4
ffffffffc0201f46:	953e                	add	a0,a0,a5
ffffffffc0201f48:	0141                	addi	sp,sp,16
ffffffffc0201f4a:	8082                	ret
ffffffffc0201f4c:	c8fff0ef          	jal	ffffffffc0201bda <pa2page.part.0>

ffffffffc0201f50 <page_remove>:
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la)
{
ffffffffc0201f50:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f52:	4601                	li	a2,0
{
ffffffffc0201f54:	e822                	sd	s0,16(sp)
ffffffffc0201f56:	ec06                	sd	ra,24(sp)
ffffffffc0201f58:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0201f5a:	d45ff0ef          	jal	ffffffffc0201c9e <get_pte>
    if (ptep != NULL)
ffffffffc0201f5e:	c511                	beqz	a0,ffffffffc0201f6a <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc0201f60:	6118                	ld	a4,0(a0)
ffffffffc0201f62:	87aa                	mv	a5,a0
ffffffffc0201f64:	00177693          	andi	a3,a4,1
ffffffffc0201f68:	e689                	bnez	a3,ffffffffc0201f72 <page_remove+0x22>
    {
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0201f6a:	60e2                	ld	ra,24(sp)
ffffffffc0201f6c:	6442                	ld	s0,16(sp)
ffffffffc0201f6e:	6105                	addi	sp,sp,32
ffffffffc0201f70:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0201f72:	0000b697          	auipc	a3,0xb
ffffffffc0201f76:	5466b683          	ld	a3,1350(a3) # ffffffffc020d4b8 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0201f7a:	070a                	slli	a4,a4,0x2
ffffffffc0201f7c:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0201f7e:	06d77563          	bgeu	a4,a3,ffffffffc0201fe8 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f82:	0000b517          	auipc	a0,0xb
ffffffffc0201f86:	53e53503          	ld	a0,1342(a0) # ffffffffc020d4c0 <pages>
ffffffffc0201f8a:	071a                	slli	a4,a4,0x6
ffffffffc0201f8c:	fe0006b7          	lui	a3,0xfe000
ffffffffc0201f90:	9736                	add	a4,a4,a3
ffffffffc0201f92:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0201f94:	4118                	lw	a4,0(a0)
ffffffffc0201f96:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3ddf2b17>
ffffffffc0201f98:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0201f9a:	cb09                	beqz	a4,ffffffffc0201fac <page_remove+0x5c>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc0201f9c:	0007b023          	sd	zero,0(a5)
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0201fa0:	12040073          	sfence.vma	s0
}
ffffffffc0201fa4:	60e2                	ld	ra,24(sp)
ffffffffc0201fa6:	6442                	ld	s0,16(sp)
ffffffffc0201fa8:	6105                	addi	sp,sp,32
ffffffffc0201faa:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201fac:	10002773          	csrr	a4,sstatus
ffffffffc0201fb0:	8b09                	andi	a4,a4,2
ffffffffc0201fb2:	eb19                	bnez	a4,ffffffffc0201fc8 <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc0201fb4:	0000b717          	auipc	a4,0xb
ffffffffc0201fb8:	4e473703          	ld	a4,1252(a4) # ffffffffc020d498 <pmm_manager>
ffffffffc0201fbc:	4585                	li	a1,1
ffffffffc0201fbe:	e03e                	sd	a5,0(sp)
ffffffffc0201fc0:	7318                	ld	a4,32(a4)
ffffffffc0201fc2:	9702                	jalr	a4
    if (flag) {
ffffffffc0201fc4:	6782                	ld	a5,0(sp)
ffffffffc0201fc6:	bfd9                	j	ffffffffc0201f9c <page_remove+0x4c>
        intr_disable();
ffffffffc0201fc8:	e43e                	sd	a5,8(sp)
ffffffffc0201fca:	e02a                	sd	a0,0(sp)
ffffffffc0201fcc:	8a9fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0201fd0:	0000b717          	auipc	a4,0xb
ffffffffc0201fd4:	4c873703          	ld	a4,1224(a4) # ffffffffc020d498 <pmm_manager>
ffffffffc0201fd8:	6502                	ld	a0,0(sp)
ffffffffc0201fda:	4585                	li	a1,1
ffffffffc0201fdc:	7318                	ld	a4,32(a4)
ffffffffc0201fde:	9702                	jalr	a4
        intr_enable();
ffffffffc0201fe0:	88ffe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0201fe4:	67a2                	ld	a5,8(sp)
ffffffffc0201fe6:	bf5d                	j	ffffffffc0201f9c <page_remove+0x4c>
ffffffffc0201fe8:	bf3ff0ef          	jal	ffffffffc0201bda <pa2page.part.0>

ffffffffc0201fec <page_insert>:
{
ffffffffc0201fec:	7139                	addi	sp,sp,-64
ffffffffc0201fee:	f426                	sd	s1,40(sp)
ffffffffc0201ff0:	84b2                	mv	s1,a2
ffffffffc0201ff2:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201ff4:	4605                	li	a2,1
{
ffffffffc0201ff6:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201ff8:	85a6                	mv	a1,s1
{
ffffffffc0201ffa:	fc06                	sd	ra,56(sp)
ffffffffc0201ffc:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0201ffe:	ca1ff0ef          	jal	ffffffffc0201c9e <get_pte>
    if (ptep == NULL)
ffffffffc0202002:	cd61                	beqz	a0,ffffffffc02020da <page_insert+0xee>
    page->ref += 1;
ffffffffc0202004:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202006:	611c                	ld	a5,0(a0)
ffffffffc0202008:	66a2                	ld	a3,8(sp)
ffffffffc020200a:	0015861b          	addiw	a2,a1,1 # 1001 <kern_entry-0xffffffffc01fefff>
ffffffffc020200e:	c010                	sw	a2,0(s0)
ffffffffc0202010:	0017f613          	andi	a2,a5,1
ffffffffc0202014:	872a                	mv	a4,a0
ffffffffc0202016:	e61d                	bnez	a2,ffffffffc0202044 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc0202018:	0000b617          	auipc	a2,0xb
ffffffffc020201c:	4a863603          	ld	a2,1192(a2) # ffffffffc020d4c0 <pages>
    return page - pages + nbase;
ffffffffc0202020:	8c11                	sub	s0,s0,a2
ffffffffc0202022:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202024:	200007b7          	lui	a5,0x20000
ffffffffc0202028:	042a                	slli	s0,s0,0xa
ffffffffc020202a:	943e                	add	s0,s0,a5
ffffffffc020202c:	8ec1                	or	a3,a3,s0
ffffffffc020202e:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202032:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202034:	12048073          	sfence.vma	s1
    return 0;
ffffffffc0202038:	4501                	li	a0,0
}
ffffffffc020203a:	70e2                	ld	ra,56(sp)
ffffffffc020203c:	7442                	ld	s0,48(sp)
ffffffffc020203e:	74a2                	ld	s1,40(sp)
ffffffffc0202040:	6121                	addi	sp,sp,64
ffffffffc0202042:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202044:	0000b617          	auipc	a2,0xb
ffffffffc0202048:	47463603          	ld	a2,1140(a2) # ffffffffc020d4b8 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc020204c:	078a                	slli	a5,a5,0x2
ffffffffc020204e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202050:	08c7f763          	bgeu	a5,a2,ffffffffc02020de <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202054:	0000b617          	auipc	a2,0xb
ffffffffc0202058:	46c63603          	ld	a2,1132(a2) # ffffffffc020d4c0 <pages>
ffffffffc020205c:	fe000537          	lui	a0,0xfe000
ffffffffc0202060:	079a                	slli	a5,a5,0x6
ffffffffc0202062:	97aa                	add	a5,a5,a0
ffffffffc0202064:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc0202068:	00a40963          	beq	s0,a0,ffffffffc020207a <page_insert+0x8e>
    page->ref -= 1;
ffffffffc020206c:	411c                	lw	a5,0(a0)
ffffffffc020206e:	37fd                	addiw	a5,a5,-1 # 1fffffff <kern_entry-0xffffffffa0200001>
ffffffffc0202070:	c11c                	sw	a5,0(a0)
        if (page_ref(page) ==
ffffffffc0202072:	c791                	beqz	a5,ffffffffc020207e <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202074:	12048073          	sfence.vma	s1
}
ffffffffc0202078:	b765                	j	ffffffffc0202020 <page_insert+0x34>
ffffffffc020207a:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc020207c:	b755                	j	ffffffffc0202020 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020207e:	100027f3          	csrr	a5,sstatus
ffffffffc0202082:	8b89                	andi	a5,a5,2
ffffffffc0202084:	e39d                	bnez	a5,ffffffffc02020aa <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc0202086:	0000b797          	auipc	a5,0xb
ffffffffc020208a:	4127b783          	ld	a5,1042(a5) # ffffffffc020d498 <pmm_manager>
ffffffffc020208e:	4585                	li	a1,1
ffffffffc0202090:	e83a                	sd	a4,16(sp)
ffffffffc0202092:	739c                	ld	a5,32(a5)
ffffffffc0202094:	e436                	sd	a3,8(sp)
ffffffffc0202096:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202098:	0000b617          	auipc	a2,0xb
ffffffffc020209c:	42863603          	ld	a2,1064(a2) # ffffffffc020d4c0 <pages>
ffffffffc02020a0:	66a2                	ld	a3,8(sp)
ffffffffc02020a2:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020a4:	12048073          	sfence.vma	s1
ffffffffc02020a8:	bfa5                	j	ffffffffc0202020 <page_insert+0x34>
        intr_disable();
ffffffffc02020aa:	ec3a                	sd	a4,24(sp)
ffffffffc02020ac:	e836                	sd	a3,16(sp)
ffffffffc02020ae:	e42a                	sd	a0,8(sp)
ffffffffc02020b0:	fc4fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02020b4:	0000b797          	auipc	a5,0xb
ffffffffc02020b8:	3e47b783          	ld	a5,996(a5) # ffffffffc020d498 <pmm_manager>
ffffffffc02020bc:	6522                	ld	a0,8(sp)
ffffffffc02020be:	4585                	li	a1,1
ffffffffc02020c0:	739c                	ld	a5,32(a5)
ffffffffc02020c2:	9782                	jalr	a5
        intr_enable();
ffffffffc02020c4:	faafe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02020c8:	0000b617          	auipc	a2,0xb
ffffffffc02020cc:	3f863603          	ld	a2,1016(a2) # ffffffffc020d4c0 <pages>
ffffffffc02020d0:	6762                	ld	a4,24(sp)
ffffffffc02020d2:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02020d4:	12048073          	sfence.vma	s1
ffffffffc02020d8:	b7a1                	j	ffffffffc0202020 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc02020da:	5571                	li	a0,-4
ffffffffc02020dc:	bfb9                	j	ffffffffc020203a <page_insert+0x4e>
ffffffffc02020de:	afdff0ef          	jal	ffffffffc0201bda <pa2page.part.0>

ffffffffc02020e2 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02020e2:	00003797          	auipc	a5,0x3
ffffffffc02020e6:	69e78793          	addi	a5,a5,1694 # ffffffffc0205780 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02020ea:	638c                	ld	a1,0(a5)
{
ffffffffc02020ec:	7159                	addi	sp,sp,-112
ffffffffc02020ee:	f486                	sd	ra,104(sp)
ffffffffc02020f0:	e8ca                	sd	s2,80(sp)
ffffffffc02020f2:	e4ce                	sd	s3,72(sp)
ffffffffc02020f4:	f85a                	sd	s6,48(sp)
ffffffffc02020f6:	f0a2                	sd	s0,96(sp)
ffffffffc02020f8:	eca6                	sd	s1,88(sp)
ffffffffc02020fa:	e0d2                	sd	s4,64(sp)
ffffffffc02020fc:	fc56                	sd	s5,56(sp)
ffffffffc02020fe:	f45e                	sd	s7,40(sp)
ffffffffc0202100:	f062                	sd	s8,32(sp)
ffffffffc0202102:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202104:	0000bb17          	auipc	s6,0xb
ffffffffc0202108:	394b0b13          	addi	s6,s6,916 # ffffffffc020d498 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020210c:	00003517          	auipc	a0,0x3
ffffffffc0202110:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0204c78 <etext+0xe76>
    pmm_manager = &default_pmm_manager;
ffffffffc0202114:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202118:	87cfe0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc020211c:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202120:	0000b997          	auipc	s3,0xb
ffffffffc0202124:	39098993          	addi	s3,s3,912 # ffffffffc020d4b0 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202128:	679c                	ld	a5,8(a5)
ffffffffc020212a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020212c:	57f5                	li	a5,-3
ffffffffc020212e:	07fa                	slli	a5,a5,0x1e
ffffffffc0202130:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202134:	f26fe0ef          	jal	ffffffffc020085a <get_memory_base>
ffffffffc0202138:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020213a:	f2afe0ef          	jal	ffffffffc0200864 <get_memory_size>
    if (mem_size == 0) {
ffffffffc020213e:	70050e63          	beqz	a0,ffffffffc020285a <pmm_init+0x778>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0202142:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202144:	00003517          	auipc	a0,0x3
ffffffffc0202148:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0204cb0 <etext+0xeae>
ffffffffc020214c:	848fe0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0202150:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202154:	864a                	mv	a2,s2
ffffffffc0202156:	85a6                	mv	a1,s1
ffffffffc0202158:	fff40693          	addi	a3,s0,-1
ffffffffc020215c:	00003517          	auipc	a0,0x3
ffffffffc0202160:	b6c50513          	addi	a0,a0,-1172 # ffffffffc0204cc8 <etext+0xec6>
ffffffffc0202164:	830fe0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc0202168:	c80007b7          	lui	a5,0xc8000
ffffffffc020216c:	8522                	mv	a0,s0
ffffffffc020216e:	5287ed63          	bltu	a5,s0,ffffffffc02026a8 <pmm_init+0x5c6>
ffffffffc0202172:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202174:	0000c617          	auipc	a2,0xc
ffffffffc0202178:	37360613          	addi	a2,a2,883 # ffffffffc020e4e7 <end+0xfff>
ffffffffc020217c:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc020217e:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202180:	0000bb97          	auipc	s7,0xb
ffffffffc0202184:	340b8b93          	addi	s7,s7,832 # ffffffffc020d4c0 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202188:	0000b497          	auipc	s1,0xb
ffffffffc020218c:	33048493          	addi	s1,s1,816 # ffffffffc020d4b8 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202190:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202194:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202196:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020219a:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020219c:	02f50763          	beq	a0,a5,ffffffffc02021ca <pmm_init+0xe8>
ffffffffc02021a0:	4701                	li	a4,0
ffffffffc02021a2:	4585                	li	a1,1
ffffffffc02021a4:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc02021a8:	00671793          	slli	a5,a4,0x6
ffffffffc02021ac:	97b2                	add	a5,a5,a2
ffffffffc02021ae:	07a1                	addi	a5,a5,8 # 80008 <kern_entry-0xffffffffc017fff8>
ffffffffc02021b0:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021b4:	6088                	ld	a0,0(s1)
ffffffffc02021b6:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02021b8:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc02021bc:	00d507b3          	add	a5,a0,a3
ffffffffc02021c0:	fef764e3          	bltu	a4,a5,ffffffffc02021a8 <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02021c4:	079a                	slli	a5,a5,0x6
ffffffffc02021c6:	00f606b3          	add	a3,a2,a5
ffffffffc02021ca:	c02007b7          	lui	a5,0xc0200
ffffffffc02021ce:	16f6eee3          	bltu	a3,a5,ffffffffc0202b4a <pmm_init+0xa68>
ffffffffc02021d2:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02021d6:	77fd                	lui	a5,0xfffff
ffffffffc02021d8:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02021da:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc02021dc:	4e86ed63          	bltu	a3,s0,ffffffffc02026d6 <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02021e0:	00003517          	auipc	a0,0x3
ffffffffc02021e4:	b1050513          	addi	a0,a0,-1264 # ffffffffc0204cf0 <etext+0xeee>
ffffffffc02021e8:	fadfd0ef          	jal	ffffffffc0200194 <cprintf>
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02021ec:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc02021f0:	0000b917          	auipc	s2,0xb
ffffffffc02021f4:	2b890913          	addi	s2,s2,696 # ffffffffc020d4a8 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc02021f8:	7b9c                	ld	a5,48(a5)
ffffffffc02021fa:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02021fc:	00003517          	auipc	a0,0x3
ffffffffc0202200:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0204d08 <etext+0xf06>
ffffffffc0202204:	f91fd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202208:	00006697          	auipc	a3,0x6
ffffffffc020220c:	df868693          	addi	a3,a3,-520 # ffffffffc0208000 <boot_page_table_sv39>
ffffffffc0202210:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202214:	c02007b7          	lui	a5,0xc0200
ffffffffc0202218:	2af6eee3          	bltu	a3,a5,ffffffffc0202cd4 <pmm_init+0xbf2>
ffffffffc020221c:	0009b783          	ld	a5,0(s3)
ffffffffc0202220:	8e9d                	sub	a3,a3,a5
ffffffffc0202222:	0000b797          	auipc	a5,0xb
ffffffffc0202226:	26d7bf23          	sd	a3,638(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020222a:	100027f3          	csrr	a5,sstatus
ffffffffc020222e:	8b89                	andi	a5,a5,2
ffffffffc0202230:	48079963          	bnez	a5,ffffffffc02026c2 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202234:	000b3783          	ld	a5,0(s6)
ffffffffc0202238:	779c                	ld	a5,40(a5)
ffffffffc020223a:	9782                	jalr	a5
ffffffffc020223c:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020223e:	6098                	ld	a4,0(s1)
ffffffffc0202240:	c80007b7          	lui	a5,0xc8000
ffffffffc0202244:	83b1                	srli	a5,a5,0xc
ffffffffc0202246:	66e7e663          	bltu	a5,a4,ffffffffc02028b2 <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc020224a:	00093503          	ld	a0,0(s2)
ffffffffc020224e:	64050263          	beqz	a0,ffffffffc0202892 <pmm_init+0x7b0>
ffffffffc0202252:	03451793          	slli	a5,a0,0x34
ffffffffc0202256:	62079e63          	bnez	a5,ffffffffc0202892 <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020225a:	4601                	li	a2,0
ffffffffc020225c:	4581                	li	a1,0
ffffffffc020225e:	c9fff0ef          	jal	ffffffffc0201efc <get_page>
ffffffffc0202262:	240519e3          	bnez	a0,ffffffffc0202cb4 <pmm_init+0xbd2>
ffffffffc0202266:	100027f3          	csrr	a5,sstatus
ffffffffc020226a:	8b89                	andi	a5,a5,2
ffffffffc020226c:	44079063          	bnez	a5,ffffffffc02026ac <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202270:	000b3783          	ld	a5,0(s6)
ffffffffc0202274:	4505                	li	a0,1
ffffffffc0202276:	6f9c                	ld	a5,24(a5)
ffffffffc0202278:	9782                	jalr	a5
ffffffffc020227a:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc020227c:	00093503          	ld	a0,0(s2)
ffffffffc0202280:	4681                	li	a3,0
ffffffffc0202282:	4601                	li	a2,0
ffffffffc0202284:	85d2                	mv	a1,s4
ffffffffc0202286:	d67ff0ef          	jal	ffffffffc0201fec <page_insert>
ffffffffc020228a:	280511e3          	bnez	a0,ffffffffc0202d0c <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc020228e:	00093503          	ld	a0,0(s2)
ffffffffc0202292:	4601                	li	a2,0
ffffffffc0202294:	4581                	li	a1,0
ffffffffc0202296:	a09ff0ef          	jal	ffffffffc0201c9e <get_pte>
ffffffffc020229a:	240509e3          	beqz	a0,ffffffffc0202cec <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc020229e:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc02022a0:	0017f713          	andi	a4,a5,1
ffffffffc02022a4:	58070f63          	beqz	a4,ffffffffc0202842 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc02022a8:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02022aa:	078a                	slli	a5,a5,0x2
ffffffffc02022ac:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02022ae:	58e7f863          	bgeu	a5,a4,ffffffffc020283e <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02022b2:	000bb683          	ld	a3,0(s7)
ffffffffc02022b6:	079a                	slli	a5,a5,0x6
ffffffffc02022b8:	fe000637          	lui	a2,0xfe000
ffffffffc02022bc:	97b2                	add	a5,a5,a2
ffffffffc02022be:	97b6                	add	a5,a5,a3
ffffffffc02022c0:	14fa1ae3          	bne	s4,a5,ffffffffc0202c14 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc02022c4:	000a2683          	lw	a3,0(s4)
ffffffffc02022c8:	4785                	li	a5,1
ffffffffc02022ca:	12f695e3          	bne	a3,a5,ffffffffc0202bf4 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02022ce:	00093503          	ld	a0,0(s2)
ffffffffc02022d2:	77fd                	lui	a5,0xfffff
ffffffffc02022d4:	6114                	ld	a3,0(a0)
ffffffffc02022d6:	068a                	slli	a3,a3,0x2
ffffffffc02022d8:	8efd                	and	a3,a3,a5
ffffffffc02022da:	00c6d613          	srli	a2,a3,0xc
ffffffffc02022de:	0ee67fe3          	bgeu	a2,a4,ffffffffc0202bdc <pmm_init+0xafa>
ffffffffc02022e2:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02022e6:	96e2                	add	a3,a3,s8
ffffffffc02022e8:	0006ba83          	ld	s5,0(a3)
ffffffffc02022ec:	0a8a                	slli	s5,s5,0x2
ffffffffc02022ee:	00fafab3          	and	s5,s5,a5
ffffffffc02022f2:	00cad793          	srli	a5,s5,0xc
ffffffffc02022f6:	0ce7f6e3          	bgeu	a5,a4,ffffffffc0202bc2 <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02022fa:	4601                	li	a2,0
ffffffffc02022fc:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02022fe:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202300:	99fff0ef          	jal	ffffffffc0201c9e <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202304:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202306:	05851ee3          	bne	a0,s8,ffffffffc0202b62 <pmm_init+0xa80>
ffffffffc020230a:	100027f3          	csrr	a5,sstatus
ffffffffc020230e:	8b89                	andi	a5,a5,2
ffffffffc0202310:	3e079b63          	bnez	a5,ffffffffc0202706 <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202314:	000b3783          	ld	a5,0(s6)
ffffffffc0202318:	4505                	li	a0,1
ffffffffc020231a:	6f9c                	ld	a5,24(a5)
ffffffffc020231c:	9782                	jalr	a5
ffffffffc020231e:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202320:	00093503          	ld	a0,0(s2)
ffffffffc0202324:	46d1                	li	a3,20
ffffffffc0202326:	6605                	lui	a2,0x1
ffffffffc0202328:	85e2                	mv	a1,s8
ffffffffc020232a:	cc3ff0ef          	jal	ffffffffc0201fec <page_insert>
ffffffffc020232e:	06051ae3          	bnez	a0,ffffffffc0202ba2 <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202332:	00093503          	ld	a0,0(s2)
ffffffffc0202336:	4601                	li	a2,0
ffffffffc0202338:	6585                	lui	a1,0x1
ffffffffc020233a:	965ff0ef          	jal	ffffffffc0201c9e <get_pte>
ffffffffc020233e:	040502e3          	beqz	a0,ffffffffc0202b82 <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc0202342:	611c                	ld	a5,0(a0)
ffffffffc0202344:	0107f713          	andi	a4,a5,16
ffffffffc0202348:	7e070163          	beqz	a4,ffffffffc0202b2a <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc020234c:	8b91                	andi	a5,a5,4
ffffffffc020234e:	7a078e63          	beqz	a5,ffffffffc0202b0a <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202352:	00093503          	ld	a0,0(s2)
ffffffffc0202356:	611c                	ld	a5,0(a0)
ffffffffc0202358:	8bc1                	andi	a5,a5,16
ffffffffc020235a:	78078863          	beqz	a5,ffffffffc0202aea <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc020235e:	000c2703          	lw	a4,0(s8)
ffffffffc0202362:	4785                	li	a5,1
ffffffffc0202364:	76f71363          	bne	a4,a5,ffffffffc0202aca <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202368:	4681                	li	a3,0
ffffffffc020236a:	6605                	lui	a2,0x1
ffffffffc020236c:	85d2                	mv	a1,s4
ffffffffc020236e:	c7fff0ef          	jal	ffffffffc0201fec <page_insert>
ffffffffc0202372:	72051c63          	bnez	a0,ffffffffc0202aaa <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc0202376:	000a2703          	lw	a4,0(s4)
ffffffffc020237a:	4789                	li	a5,2
ffffffffc020237c:	70f71763          	bne	a4,a5,ffffffffc0202a8a <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc0202380:	000c2783          	lw	a5,0(s8)
ffffffffc0202384:	6e079363          	bnez	a5,ffffffffc0202a6a <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202388:	00093503          	ld	a0,0(s2)
ffffffffc020238c:	4601                	li	a2,0
ffffffffc020238e:	6585                	lui	a1,0x1
ffffffffc0202390:	90fff0ef          	jal	ffffffffc0201c9e <get_pte>
ffffffffc0202394:	6a050b63          	beqz	a0,ffffffffc0202a4a <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202398:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc020239a:	00177793          	andi	a5,a4,1
ffffffffc020239e:	4a078263          	beqz	a5,ffffffffc0202842 <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc02023a2:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02023a4:	00271793          	slli	a5,a4,0x2
ffffffffc02023a8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02023aa:	48d7fa63          	bgeu	a5,a3,ffffffffc020283e <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc02023ae:	000bb683          	ld	a3,0(s7)
ffffffffc02023b2:	fff80ab7          	lui	s5,0xfff80
ffffffffc02023b6:	97d6                	add	a5,a5,s5
ffffffffc02023b8:	079a                	slli	a5,a5,0x6
ffffffffc02023ba:	97b6                	add	a5,a5,a3
ffffffffc02023bc:	66fa1763          	bne	s4,a5,ffffffffc0202a2a <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc02023c0:	8b41                	andi	a4,a4,16
ffffffffc02023c2:	64071463          	bnez	a4,ffffffffc0202a0a <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc02023c6:	00093503          	ld	a0,0(s2)
ffffffffc02023ca:	4581                	li	a1,0
ffffffffc02023cc:	b85ff0ef          	jal	ffffffffc0201f50 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02023d0:	000a2c83          	lw	s9,0(s4)
ffffffffc02023d4:	4785                	li	a5,1
ffffffffc02023d6:	60fc9a63          	bne	s9,a5,ffffffffc02029ea <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc02023da:	000c2783          	lw	a5,0(s8)
ffffffffc02023de:	5e079663          	bnez	a5,ffffffffc02029ca <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc02023e2:	00093503          	ld	a0,0(s2)
ffffffffc02023e6:	6585                	lui	a1,0x1
ffffffffc02023e8:	b69ff0ef          	jal	ffffffffc0201f50 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02023ec:	000a2783          	lw	a5,0(s4)
ffffffffc02023f0:	52079d63          	bnez	a5,ffffffffc020292a <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc02023f4:	000c2783          	lw	a5,0(s8)
ffffffffc02023f8:	50079963          	bnez	a5,ffffffffc020290a <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc02023fc:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202400:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202402:	000a3783          	ld	a5,0(s4)
ffffffffc0202406:	078a                	slli	a5,a5,0x2
ffffffffc0202408:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020240a:	42e7fa63          	bgeu	a5,a4,ffffffffc020283e <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020240e:	000bb503          	ld	a0,0(s7)
ffffffffc0202412:	97d6                	add	a5,a5,s5
ffffffffc0202414:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202416:	00f506b3          	add	a3,a0,a5
ffffffffc020241a:	4294                	lw	a3,0(a3)
ffffffffc020241c:	4d969763          	bne	a3,s9,ffffffffc02028ea <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202420:	8799                	srai	a5,a5,0x6
ffffffffc0202422:	00080637          	lui	a2,0x80
ffffffffc0202426:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202428:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020242c:	4ae7f363          	bgeu	a5,a4,ffffffffc02028d2 <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202430:	0009b783          	ld	a5,0(s3)
ffffffffc0202434:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202436:	639c                	ld	a5,0(a5)
ffffffffc0202438:	078a                	slli	a5,a5,0x2
ffffffffc020243a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020243c:	40e7f163          	bgeu	a5,a4,ffffffffc020283e <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202440:	8f91                	sub	a5,a5,a2
ffffffffc0202442:	079a                	slli	a5,a5,0x6
ffffffffc0202444:	953e                	add	a0,a0,a5
ffffffffc0202446:	100027f3          	csrr	a5,sstatus
ffffffffc020244a:	8b89                	andi	a5,a5,2
ffffffffc020244c:	30079863          	bnez	a5,ffffffffc020275c <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202450:	000b3783          	ld	a5,0(s6)
ffffffffc0202454:	4585                	li	a1,1
ffffffffc0202456:	739c                	ld	a5,32(a5)
ffffffffc0202458:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020245a:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc020245e:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202460:	078a                	slli	a5,a5,0x2
ffffffffc0202462:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202464:	3ce7fd63          	bgeu	a5,a4,ffffffffc020283e <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202468:	000bb503          	ld	a0,0(s7)
ffffffffc020246c:	fe000737          	lui	a4,0xfe000
ffffffffc0202470:	079a                	slli	a5,a5,0x6
ffffffffc0202472:	97ba                	add	a5,a5,a4
ffffffffc0202474:	953e                	add	a0,a0,a5
ffffffffc0202476:	100027f3          	csrr	a5,sstatus
ffffffffc020247a:	8b89                	andi	a5,a5,2
ffffffffc020247c:	2c079463          	bnez	a5,ffffffffc0202744 <pmm_init+0x662>
ffffffffc0202480:	000b3783          	ld	a5,0(s6)
ffffffffc0202484:	4585                	li	a1,1
ffffffffc0202486:	739c                	ld	a5,32(a5)
ffffffffc0202488:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc020248a:	00093783          	ld	a5,0(s2)
ffffffffc020248e:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fdf1b18>
    asm volatile("sfence.vma");
ffffffffc0202492:	12000073          	sfence.vma
ffffffffc0202496:	100027f3          	csrr	a5,sstatus
ffffffffc020249a:	8b89                	andi	a5,a5,2
ffffffffc020249c:	28079a63          	bnez	a5,ffffffffc0202730 <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc02024a0:	000b3783          	ld	a5,0(s6)
ffffffffc02024a4:	779c                	ld	a5,40(a5)
ffffffffc02024a6:	9782                	jalr	a5
ffffffffc02024a8:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc02024aa:	4d441063          	bne	s0,s4,ffffffffc020296a <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02024ae:	00003517          	auipc	a0,0x3
ffffffffc02024b2:	baa50513          	addi	a0,a0,-1110 # ffffffffc0205058 <etext+0x1256>
ffffffffc02024b6:	cdffd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc02024ba:	100027f3          	csrr	a5,sstatus
ffffffffc02024be:	8b89                	andi	a5,a5,2
ffffffffc02024c0:	24079e63          	bnez	a5,ffffffffc020271c <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc02024c4:	000b3783          	ld	a5,0(s6)
ffffffffc02024c8:	779c                	ld	a5,40(a5)
ffffffffc02024ca:	9782                	jalr	a5
ffffffffc02024cc:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02024ce:	609c                	ld	a5,0(s1)
ffffffffc02024d0:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02024d4:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc02024d6:	00c79713          	slli	a4,a5,0xc
ffffffffc02024da:	6a85                	lui	s5,0x1
ffffffffc02024dc:	02e47c63          	bgeu	s0,a4,ffffffffc0202514 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02024e0:	00c45713          	srli	a4,s0,0xc
ffffffffc02024e4:	30f77063          	bgeu	a4,a5,ffffffffc02027e4 <pmm_init+0x702>
ffffffffc02024e8:	0009b583          	ld	a1,0(s3)
ffffffffc02024ec:	00093503          	ld	a0,0(s2)
ffffffffc02024f0:	4601                	li	a2,0
ffffffffc02024f2:	95a2                	add	a1,a1,s0
ffffffffc02024f4:	faaff0ef          	jal	ffffffffc0201c9e <get_pte>
ffffffffc02024f8:	32050363          	beqz	a0,ffffffffc020281e <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02024fc:	611c                	ld	a5,0(a0)
ffffffffc02024fe:	078a                	slli	a5,a5,0x2
ffffffffc0202500:	0147f7b3          	and	a5,a5,s4
ffffffffc0202504:	2e879d63          	bne	a5,s0,ffffffffc02027fe <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202508:	609c                	ld	a5,0(s1)
ffffffffc020250a:	9456                	add	s0,s0,s5
ffffffffc020250c:	00c79713          	slli	a4,a5,0xc
ffffffffc0202510:	fce468e3          	bltu	s0,a4,ffffffffc02024e0 <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202514:	00093783          	ld	a5,0(s2)
ffffffffc0202518:	639c                	ld	a5,0(a5)
ffffffffc020251a:	42079863          	bnez	a5,ffffffffc020294a <pmm_init+0x868>
ffffffffc020251e:	100027f3          	csrr	a5,sstatus
ffffffffc0202522:	8b89                	andi	a5,a5,2
ffffffffc0202524:	24079863          	bnez	a5,ffffffffc0202774 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202528:	000b3783          	ld	a5,0(s6)
ffffffffc020252c:	4505                	li	a0,1
ffffffffc020252e:	6f9c                	ld	a5,24(a5)
ffffffffc0202530:	9782                	jalr	a5
ffffffffc0202532:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202534:	00093503          	ld	a0,0(s2)
ffffffffc0202538:	4699                	li	a3,6
ffffffffc020253a:	10000613          	li	a2,256
ffffffffc020253e:	85a2                	mv	a1,s0
ffffffffc0202540:	aadff0ef          	jal	ffffffffc0201fec <page_insert>
ffffffffc0202544:	46051363          	bnez	a0,ffffffffc02029aa <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202548:	4018                	lw	a4,0(s0)
ffffffffc020254a:	4785                	li	a5,1
ffffffffc020254c:	42f71f63          	bne	a4,a5,ffffffffc020298a <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202550:	00093503          	ld	a0,0(s2)
ffffffffc0202554:	6605                	lui	a2,0x1
ffffffffc0202556:	10060613          	addi	a2,a2,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc020255a:	4699                	li	a3,6
ffffffffc020255c:	85a2                	mv	a1,s0
ffffffffc020255e:	a8fff0ef          	jal	ffffffffc0201fec <page_insert>
ffffffffc0202562:	72051963          	bnez	a0,ffffffffc0202c94 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202566:	4018                	lw	a4,0(s0)
ffffffffc0202568:	4789                	li	a5,2
ffffffffc020256a:	70f71563          	bne	a4,a5,ffffffffc0202c74 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020256e:	00003597          	auipc	a1,0x3
ffffffffc0202572:	c3258593          	addi	a1,a1,-974 # ffffffffc02051a0 <etext+0x139e>
ffffffffc0202576:	10000513          	li	a0,256
ffffffffc020257a:	7ba010ef          	jal	ffffffffc0203d34 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020257e:	6585                	lui	a1,0x1
ffffffffc0202580:	10058593          	addi	a1,a1,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0202584:	10000513          	li	a0,256
ffffffffc0202588:	7be010ef          	jal	ffffffffc0203d46 <strcmp>
ffffffffc020258c:	6c051463          	bnez	a0,ffffffffc0202c54 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202590:	000bb683          	ld	a3,0(s7)
ffffffffc0202594:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202598:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc020259a:	40d406b3          	sub	a3,s0,a3
ffffffffc020259e:	8699                	srai	a3,a3,0x6
ffffffffc02025a0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02025a2:	00c69793          	slli	a5,a3,0xc
ffffffffc02025a6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02025a8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02025aa:	32e7f463          	bgeu	a5,a4,ffffffffc02028d2 <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02025ae:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc02025b2:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc02025b6:	97b6                	add	a5,a5,a3
ffffffffc02025b8:	10078023          	sb	zero,256(a5) # 80100 <kern_entry-0xffffffffc017ff00>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02025bc:	744010ef          	jal	ffffffffc0203d00 <strlen>
ffffffffc02025c0:	66051a63          	bnez	a0,ffffffffc0202c34 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc02025c4:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc02025c8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02025ca:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fdf1b18>
ffffffffc02025ce:	078a                	slli	a5,a5,0x2
ffffffffc02025d0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02025d2:	26e7f663          	bgeu	a5,a4,ffffffffc020283e <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc02025d6:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02025da:	2ee7fc63          	bgeu	a5,a4,ffffffffc02028d2 <pmm_init+0x7f0>
ffffffffc02025de:	0009b783          	ld	a5,0(s3)
ffffffffc02025e2:	00f689b3          	add	s3,a3,a5
ffffffffc02025e6:	100027f3          	csrr	a5,sstatus
ffffffffc02025ea:	8b89                	andi	a5,a5,2
ffffffffc02025ec:	1e079163          	bnez	a5,ffffffffc02027ce <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc02025f0:	000b3783          	ld	a5,0(s6)
ffffffffc02025f4:	8522                	mv	a0,s0
ffffffffc02025f6:	4585                	li	a1,1
ffffffffc02025f8:	739c                	ld	a5,32(a5)
ffffffffc02025fa:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02025fc:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202600:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202602:	078a                	slli	a5,a5,0x2
ffffffffc0202604:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202606:	22e7fc63          	bgeu	a5,a4,ffffffffc020283e <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020260a:	000bb503          	ld	a0,0(s7)
ffffffffc020260e:	fe000737          	lui	a4,0xfe000
ffffffffc0202612:	079a                	slli	a5,a5,0x6
ffffffffc0202614:	97ba                	add	a5,a5,a4
ffffffffc0202616:	953e                	add	a0,a0,a5
ffffffffc0202618:	100027f3          	csrr	a5,sstatus
ffffffffc020261c:	8b89                	andi	a5,a5,2
ffffffffc020261e:	18079c63          	bnez	a5,ffffffffc02027b6 <pmm_init+0x6d4>
ffffffffc0202622:	000b3783          	ld	a5,0(s6)
ffffffffc0202626:	4585                	li	a1,1
ffffffffc0202628:	739c                	ld	a5,32(a5)
ffffffffc020262a:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020262c:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202630:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202632:	078a                	slli	a5,a5,0x2
ffffffffc0202634:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202636:	20e7f463          	bgeu	a5,a4,ffffffffc020283e <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020263a:	000bb503          	ld	a0,0(s7)
ffffffffc020263e:	fe000737          	lui	a4,0xfe000
ffffffffc0202642:	079a                	slli	a5,a5,0x6
ffffffffc0202644:	97ba                	add	a5,a5,a4
ffffffffc0202646:	953e                	add	a0,a0,a5
ffffffffc0202648:	100027f3          	csrr	a5,sstatus
ffffffffc020264c:	8b89                	andi	a5,a5,2
ffffffffc020264e:	14079863          	bnez	a5,ffffffffc020279e <pmm_init+0x6bc>
ffffffffc0202652:	000b3783          	ld	a5,0(s6)
ffffffffc0202656:	4585                	li	a1,1
ffffffffc0202658:	739c                	ld	a5,32(a5)
ffffffffc020265a:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc020265c:	00093783          	ld	a5,0(s2)
ffffffffc0202660:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202664:	12000073          	sfence.vma
ffffffffc0202668:	100027f3          	csrr	a5,sstatus
ffffffffc020266c:	8b89                	andi	a5,a5,2
ffffffffc020266e:	10079e63          	bnez	a5,ffffffffc020278a <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202672:	000b3783          	ld	a5,0(s6)
ffffffffc0202676:	779c                	ld	a5,40(a5)
ffffffffc0202678:	9782                	jalr	a5
ffffffffc020267a:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc020267c:	1e8c1b63          	bne	s8,s0,ffffffffc0202872 <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202680:	00003517          	auipc	a0,0x3
ffffffffc0202684:	b9850513          	addi	a0,a0,-1128 # ffffffffc0205218 <etext+0x1416>
ffffffffc0202688:	b0dfd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc020268c:	7406                	ld	s0,96(sp)
ffffffffc020268e:	70a6                	ld	ra,104(sp)
ffffffffc0202690:	64e6                	ld	s1,88(sp)
ffffffffc0202692:	6946                	ld	s2,80(sp)
ffffffffc0202694:	69a6                	ld	s3,72(sp)
ffffffffc0202696:	6a06                	ld	s4,64(sp)
ffffffffc0202698:	7ae2                	ld	s5,56(sp)
ffffffffc020269a:	7b42                	ld	s6,48(sp)
ffffffffc020269c:	7ba2                	ld	s7,40(sp)
ffffffffc020269e:	7c02                	ld	s8,32(sp)
ffffffffc02026a0:	6ce2                	ld	s9,24(sp)
ffffffffc02026a2:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc02026a4:	b70ff06f          	j	ffffffffc0201a14 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc02026a8:	853e                	mv	a0,a5
ffffffffc02026aa:	b4e1                	j	ffffffffc0202172 <pmm_init+0x90>
        intr_disable();
ffffffffc02026ac:	9c8fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02026b0:	000b3783          	ld	a5,0(s6)
ffffffffc02026b4:	4505                	li	a0,1
ffffffffc02026b6:	6f9c                	ld	a5,24(a5)
ffffffffc02026b8:	9782                	jalr	a5
ffffffffc02026ba:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02026bc:	9b2fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02026c0:	be75                	j	ffffffffc020227c <pmm_init+0x19a>
        intr_disable();
ffffffffc02026c2:	9b2fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02026c6:	000b3783          	ld	a5,0(s6)
ffffffffc02026ca:	779c                	ld	a5,40(a5)
ffffffffc02026cc:	9782                	jalr	a5
ffffffffc02026ce:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02026d0:	99efe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02026d4:	b6ad                	j	ffffffffc020223e <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02026d6:	6705                	lui	a4,0x1
ffffffffc02026d8:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02026da:	96ba                	add	a3,a3,a4
ffffffffc02026dc:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc02026de:	00c7d713          	srli	a4,a5,0xc
ffffffffc02026e2:	14a77e63          	bgeu	a4,a0,ffffffffc020283e <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc02026e6:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02026ea:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc02026ec:	071a                	slli	a4,a4,0x6
ffffffffc02026ee:	fe0007b7          	lui	a5,0xfe000
ffffffffc02026f2:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc02026f4:	6a9c                	ld	a5,16(a3)
ffffffffc02026f6:	00c45593          	srli	a1,s0,0xc
ffffffffc02026fa:	00e60533          	add	a0,a2,a4
ffffffffc02026fe:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202700:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202704:	bcf1                	j	ffffffffc02021e0 <pmm_init+0xfe>
        intr_disable();
ffffffffc0202706:	96efe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020270a:	000b3783          	ld	a5,0(s6)
ffffffffc020270e:	4505                	li	a0,1
ffffffffc0202710:	6f9c                	ld	a5,24(a5)
ffffffffc0202712:	9782                	jalr	a5
ffffffffc0202714:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202716:	958fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020271a:	b119                	j	ffffffffc0202320 <pmm_init+0x23e>
        intr_disable();
ffffffffc020271c:	958fe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202720:	000b3783          	ld	a5,0(s6)
ffffffffc0202724:	779c                	ld	a5,40(a5)
ffffffffc0202726:	9782                	jalr	a5
ffffffffc0202728:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc020272a:	944fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020272e:	b345                	j	ffffffffc02024ce <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202730:	944fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202734:	000b3783          	ld	a5,0(s6)
ffffffffc0202738:	779c                	ld	a5,40(a5)
ffffffffc020273a:	9782                	jalr	a5
ffffffffc020273c:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc020273e:	930fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202742:	b3a5                	j	ffffffffc02024aa <pmm_init+0x3c8>
ffffffffc0202744:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202746:	92efe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020274a:	000b3783          	ld	a5,0(s6)
ffffffffc020274e:	6522                	ld	a0,8(sp)
ffffffffc0202750:	4585                	li	a1,1
ffffffffc0202752:	739c                	ld	a5,32(a5)
ffffffffc0202754:	9782                	jalr	a5
        intr_enable();
ffffffffc0202756:	918fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020275a:	bb05                	j	ffffffffc020248a <pmm_init+0x3a8>
ffffffffc020275c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020275e:	916fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc0202762:	000b3783          	ld	a5,0(s6)
ffffffffc0202766:	6522                	ld	a0,8(sp)
ffffffffc0202768:	4585                	li	a1,1
ffffffffc020276a:	739c                	ld	a5,32(a5)
ffffffffc020276c:	9782                	jalr	a5
        intr_enable();
ffffffffc020276e:	900fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202772:	b1e5                	j	ffffffffc020245a <pmm_init+0x378>
        intr_disable();
ffffffffc0202774:	900fe0ef          	jal	ffffffffc0200874 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202778:	000b3783          	ld	a5,0(s6)
ffffffffc020277c:	4505                	li	a0,1
ffffffffc020277e:	6f9c                	ld	a5,24(a5)
ffffffffc0202780:	9782                	jalr	a5
ffffffffc0202782:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202784:	8eafe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc0202788:	b375                	j	ffffffffc0202534 <pmm_init+0x452>
        intr_disable();
ffffffffc020278a:	8eafe0ef          	jal	ffffffffc0200874 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020278e:	000b3783          	ld	a5,0(s6)
ffffffffc0202792:	779c                	ld	a5,40(a5)
ffffffffc0202794:	9782                	jalr	a5
ffffffffc0202796:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202798:	8d6fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc020279c:	b5c5                	j	ffffffffc020267c <pmm_init+0x59a>
ffffffffc020279e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027a0:	8d4fe0ef          	jal	ffffffffc0200874 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02027a4:	000b3783          	ld	a5,0(s6)
ffffffffc02027a8:	6522                	ld	a0,8(sp)
ffffffffc02027aa:	4585                	li	a1,1
ffffffffc02027ac:	739c                	ld	a5,32(a5)
ffffffffc02027ae:	9782                	jalr	a5
        intr_enable();
ffffffffc02027b0:	8befe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027b4:	b565                	j	ffffffffc020265c <pmm_init+0x57a>
ffffffffc02027b6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02027b8:	8bcfe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02027bc:	000b3783          	ld	a5,0(s6)
ffffffffc02027c0:	6522                	ld	a0,8(sp)
ffffffffc02027c2:	4585                	li	a1,1
ffffffffc02027c4:	739c                	ld	a5,32(a5)
ffffffffc02027c6:	9782                	jalr	a5
        intr_enable();
ffffffffc02027c8:	8a6fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027cc:	b585                	j	ffffffffc020262c <pmm_init+0x54a>
        intr_disable();
ffffffffc02027ce:	8a6fe0ef          	jal	ffffffffc0200874 <intr_disable>
ffffffffc02027d2:	000b3783          	ld	a5,0(s6)
ffffffffc02027d6:	8522                	mv	a0,s0
ffffffffc02027d8:	4585                	li	a1,1
ffffffffc02027da:	739c                	ld	a5,32(a5)
ffffffffc02027dc:	9782                	jalr	a5
        intr_enable();
ffffffffc02027de:	890fe0ef          	jal	ffffffffc020086e <intr_enable>
ffffffffc02027e2:	bd29                	j	ffffffffc02025fc <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02027e4:	86a2                	mv	a3,s0
ffffffffc02027e6:	00002617          	auipc	a2,0x2
ffffffffc02027ea:	39260613          	addi	a2,a2,914 # ffffffffc0204b78 <etext+0xd76>
ffffffffc02027ee:	1a400593          	li	a1,420
ffffffffc02027f2:	00002517          	auipc	a0,0x2
ffffffffc02027f6:	47650513          	addi	a0,a0,1142 # ffffffffc0204c68 <etext+0xe66>
ffffffffc02027fa:	c0dfd0ef          	jal	ffffffffc0200406 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02027fe:	00003697          	auipc	a3,0x3
ffffffffc0202802:	8ba68693          	addi	a3,a3,-1862 # ffffffffc02050b8 <etext+0x12b6>
ffffffffc0202806:	00002617          	auipc	a2,0x2
ffffffffc020280a:	fc260613          	addi	a2,a2,-62 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020280e:	1a500593          	li	a1,421
ffffffffc0202812:	00002517          	auipc	a0,0x2
ffffffffc0202816:	45650513          	addi	a0,a0,1110 # ffffffffc0204c68 <etext+0xe66>
ffffffffc020281a:	bedfd0ef          	jal	ffffffffc0200406 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020281e:	00003697          	auipc	a3,0x3
ffffffffc0202822:	85a68693          	addi	a3,a3,-1958 # ffffffffc0205078 <etext+0x1276>
ffffffffc0202826:	00002617          	auipc	a2,0x2
ffffffffc020282a:	fa260613          	addi	a2,a2,-94 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020282e:	1a400593          	li	a1,420
ffffffffc0202832:	00002517          	auipc	a0,0x2
ffffffffc0202836:	43650513          	addi	a0,a0,1078 # ffffffffc0204c68 <etext+0xe66>
ffffffffc020283a:	bcdfd0ef          	jal	ffffffffc0200406 <__panic>
ffffffffc020283e:	b9cff0ef          	jal	ffffffffc0201bda <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202842:	00002617          	auipc	a2,0x2
ffffffffc0202846:	5d660613          	addi	a2,a2,1494 # ffffffffc0204e18 <etext+0x1016>
ffffffffc020284a:	07f00593          	li	a1,127
ffffffffc020284e:	00002517          	auipc	a0,0x2
ffffffffc0202852:	35250513          	addi	a0,a0,850 # ffffffffc0204ba0 <etext+0xd9e>
ffffffffc0202856:	bb1fd0ef          	jal	ffffffffc0200406 <__panic>
        panic("DTB memory info not available");
ffffffffc020285a:	00002617          	auipc	a2,0x2
ffffffffc020285e:	43660613          	addi	a2,a2,1078 # ffffffffc0204c90 <etext+0xe8e>
ffffffffc0202862:	06400593          	li	a1,100
ffffffffc0202866:	00002517          	auipc	a0,0x2
ffffffffc020286a:	40250513          	addi	a0,a0,1026 # ffffffffc0204c68 <etext+0xe66>
ffffffffc020286e:	b99fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202872:	00002697          	auipc	a3,0x2
ffffffffc0202876:	7be68693          	addi	a3,a3,1982 # ffffffffc0205030 <etext+0x122e>
ffffffffc020287a:	00002617          	auipc	a2,0x2
ffffffffc020287e:	f4e60613          	addi	a2,a2,-178 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202882:	1bf00593          	li	a1,447
ffffffffc0202886:	00002517          	auipc	a0,0x2
ffffffffc020288a:	3e250513          	addi	a0,a0,994 # ffffffffc0204c68 <etext+0xe66>
ffffffffc020288e:	b79fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202892:	00002697          	auipc	a3,0x2
ffffffffc0202896:	4b668693          	addi	a3,a3,1206 # ffffffffc0204d48 <etext+0xf46>
ffffffffc020289a:	00002617          	auipc	a2,0x2
ffffffffc020289e:	f2e60613          	addi	a2,a2,-210 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02028a2:	16600593          	li	a1,358
ffffffffc02028a6:	00002517          	auipc	a0,0x2
ffffffffc02028aa:	3c250513          	addi	a0,a0,962 # ffffffffc0204c68 <etext+0xe66>
ffffffffc02028ae:	b59fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028b2:	00002697          	auipc	a3,0x2
ffffffffc02028b6:	47668693          	addi	a3,a3,1142 # ffffffffc0204d28 <etext+0xf26>
ffffffffc02028ba:	00002617          	auipc	a2,0x2
ffffffffc02028be:	f0e60613          	addi	a2,a2,-242 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02028c2:	16500593          	li	a1,357
ffffffffc02028c6:	00002517          	auipc	a0,0x2
ffffffffc02028ca:	3a250513          	addi	a0,a0,930 # ffffffffc0204c68 <etext+0xe66>
ffffffffc02028ce:	b39fd0ef          	jal	ffffffffc0200406 <__panic>
    return KADDR(page2pa(page));
ffffffffc02028d2:	00002617          	auipc	a2,0x2
ffffffffc02028d6:	2a660613          	addi	a2,a2,678 # ffffffffc0204b78 <etext+0xd76>
ffffffffc02028da:	07100593          	li	a1,113
ffffffffc02028de:	00002517          	auipc	a0,0x2
ffffffffc02028e2:	2c250513          	addi	a0,a0,706 # ffffffffc0204ba0 <etext+0xd9e>
ffffffffc02028e6:	b21fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc02028ea:	00002697          	auipc	a3,0x2
ffffffffc02028ee:	71668693          	addi	a3,a3,1814 # ffffffffc0205000 <etext+0x11fe>
ffffffffc02028f2:	00002617          	auipc	a2,0x2
ffffffffc02028f6:	ed660613          	addi	a2,a2,-298 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02028fa:	18d00593          	li	a1,397
ffffffffc02028fe:	00002517          	auipc	a0,0x2
ffffffffc0202902:	36a50513          	addi	a0,a0,874 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202906:	b01fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020290a:	00002697          	auipc	a3,0x2
ffffffffc020290e:	6ae68693          	addi	a3,a3,1710 # ffffffffc0204fb8 <etext+0x11b6>
ffffffffc0202912:	00002617          	auipc	a2,0x2
ffffffffc0202916:	eb660613          	addi	a2,a2,-330 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020291a:	18b00593          	li	a1,395
ffffffffc020291e:	00002517          	auipc	a0,0x2
ffffffffc0202922:	34a50513          	addi	a0,a0,842 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202926:	ae1fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc020292a:	00002697          	auipc	a3,0x2
ffffffffc020292e:	6be68693          	addi	a3,a3,1726 # ffffffffc0204fe8 <etext+0x11e6>
ffffffffc0202932:	00002617          	auipc	a2,0x2
ffffffffc0202936:	e9660613          	addi	a2,a2,-362 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020293a:	18a00593          	li	a1,394
ffffffffc020293e:	00002517          	auipc	a0,0x2
ffffffffc0202942:	32a50513          	addi	a0,a0,810 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202946:	ac1fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc020294a:	00002697          	auipc	a3,0x2
ffffffffc020294e:	78668693          	addi	a3,a3,1926 # ffffffffc02050d0 <etext+0x12ce>
ffffffffc0202952:	00002617          	auipc	a2,0x2
ffffffffc0202956:	e7660613          	addi	a2,a2,-394 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020295a:	1a800593          	li	a1,424
ffffffffc020295e:	00002517          	auipc	a0,0x2
ffffffffc0202962:	30a50513          	addi	a0,a0,778 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202966:	aa1fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc020296a:	00002697          	auipc	a3,0x2
ffffffffc020296e:	6c668693          	addi	a3,a3,1734 # ffffffffc0205030 <etext+0x122e>
ffffffffc0202972:	00002617          	auipc	a2,0x2
ffffffffc0202976:	e5660613          	addi	a2,a2,-426 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020297a:	19500593          	li	a1,405
ffffffffc020297e:	00002517          	auipc	a0,0x2
ffffffffc0202982:	2ea50513          	addi	a0,a0,746 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202986:	a81fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p) == 1);
ffffffffc020298a:	00002697          	auipc	a3,0x2
ffffffffc020298e:	79e68693          	addi	a3,a3,1950 # ffffffffc0205128 <etext+0x1326>
ffffffffc0202992:	00002617          	auipc	a2,0x2
ffffffffc0202996:	e3660613          	addi	a2,a2,-458 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020299a:	1ad00593          	li	a1,429
ffffffffc020299e:	00002517          	auipc	a0,0x2
ffffffffc02029a2:	2ca50513          	addi	a0,a0,714 # ffffffffc0204c68 <etext+0xe66>
ffffffffc02029a6:	a61fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02029aa:	00002697          	auipc	a3,0x2
ffffffffc02029ae:	73e68693          	addi	a3,a3,1854 # ffffffffc02050e8 <etext+0x12e6>
ffffffffc02029b2:	00002617          	auipc	a2,0x2
ffffffffc02029b6:	e1660613          	addi	a2,a2,-490 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02029ba:	1ac00593          	li	a1,428
ffffffffc02029be:	00002517          	auipc	a0,0x2
ffffffffc02029c2:	2aa50513          	addi	a0,a0,682 # ffffffffc0204c68 <etext+0xe66>
ffffffffc02029c6:	a41fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02029ca:	00002697          	auipc	a3,0x2
ffffffffc02029ce:	5ee68693          	addi	a3,a3,1518 # ffffffffc0204fb8 <etext+0x11b6>
ffffffffc02029d2:	00002617          	auipc	a2,0x2
ffffffffc02029d6:	df660613          	addi	a2,a2,-522 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02029da:	18700593          	li	a1,391
ffffffffc02029de:	00002517          	auipc	a0,0x2
ffffffffc02029e2:	28a50513          	addi	a0,a0,650 # ffffffffc0204c68 <etext+0xe66>
ffffffffc02029e6:	a21fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02029ea:	00002697          	auipc	a3,0x2
ffffffffc02029ee:	46e68693          	addi	a3,a3,1134 # ffffffffc0204e58 <etext+0x1056>
ffffffffc02029f2:	00002617          	auipc	a2,0x2
ffffffffc02029f6:	dd660613          	addi	a2,a2,-554 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02029fa:	18600593          	li	a1,390
ffffffffc02029fe:	00002517          	auipc	a0,0x2
ffffffffc0202a02:	26a50513          	addi	a0,a0,618 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202a06:	a01fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a0a:	00002697          	auipc	a3,0x2
ffffffffc0202a0e:	5c668693          	addi	a3,a3,1478 # ffffffffc0204fd0 <etext+0x11ce>
ffffffffc0202a12:	00002617          	auipc	a2,0x2
ffffffffc0202a16:	db660613          	addi	a2,a2,-586 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202a1a:	18300593          	li	a1,387
ffffffffc0202a1e:	00002517          	auipc	a0,0x2
ffffffffc0202a22:	24a50513          	addi	a0,a0,586 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202a26:	9e1fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a2a:	00002697          	auipc	a3,0x2
ffffffffc0202a2e:	41668693          	addi	a3,a3,1046 # ffffffffc0204e40 <etext+0x103e>
ffffffffc0202a32:	00002617          	auipc	a2,0x2
ffffffffc0202a36:	d9660613          	addi	a2,a2,-618 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202a3a:	18200593          	li	a1,386
ffffffffc0202a3e:	00002517          	auipc	a0,0x2
ffffffffc0202a42:	22a50513          	addi	a0,a0,554 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202a46:	9c1fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a4a:	00002697          	auipc	a3,0x2
ffffffffc0202a4e:	49668693          	addi	a3,a3,1174 # ffffffffc0204ee0 <etext+0x10de>
ffffffffc0202a52:	00002617          	auipc	a2,0x2
ffffffffc0202a56:	d7660613          	addi	a2,a2,-650 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202a5a:	18100593          	li	a1,385
ffffffffc0202a5e:	00002517          	auipc	a0,0x2
ffffffffc0202a62:	20a50513          	addi	a0,a0,522 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202a66:	9a1fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202a6a:	00002697          	auipc	a3,0x2
ffffffffc0202a6e:	54e68693          	addi	a3,a3,1358 # ffffffffc0204fb8 <etext+0x11b6>
ffffffffc0202a72:	00002617          	auipc	a2,0x2
ffffffffc0202a76:	d5660613          	addi	a2,a2,-682 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202a7a:	18000593          	li	a1,384
ffffffffc0202a7e:	00002517          	auipc	a0,0x2
ffffffffc0202a82:	1ea50513          	addi	a0,a0,490 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202a86:	981fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202a8a:	00002697          	auipc	a3,0x2
ffffffffc0202a8e:	51668693          	addi	a3,a3,1302 # ffffffffc0204fa0 <etext+0x119e>
ffffffffc0202a92:	00002617          	auipc	a2,0x2
ffffffffc0202a96:	d3660613          	addi	a2,a2,-714 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202a9a:	17f00593          	li	a1,383
ffffffffc0202a9e:	00002517          	auipc	a0,0x2
ffffffffc0202aa2:	1ca50513          	addi	a0,a0,458 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202aa6:	961fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202aaa:	00002697          	auipc	a3,0x2
ffffffffc0202aae:	4c668693          	addi	a3,a3,1222 # ffffffffc0204f70 <etext+0x116e>
ffffffffc0202ab2:	00002617          	auipc	a2,0x2
ffffffffc0202ab6:	d1660613          	addi	a2,a2,-746 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202aba:	17e00593          	li	a1,382
ffffffffc0202abe:	00002517          	auipc	a0,0x2
ffffffffc0202ac2:	1aa50513          	addi	a0,a0,426 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202ac6:	941fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202aca:	00002697          	auipc	a3,0x2
ffffffffc0202ace:	48e68693          	addi	a3,a3,1166 # ffffffffc0204f58 <etext+0x1156>
ffffffffc0202ad2:	00002617          	auipc	a2,0x2
ffffffffc0202ad6:	cf660613          	addi	a2,a2,-778 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202ada:	17c00593          	li	a1,380
ffffffffc0202ade:	00002517          	auipc	a0,0x2
ffffffffc0202ae2:	18a50513          	addi	a0,a0,394 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202ae6:	921fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202aea:	00002697          	auipc	a3,0x2
ffffffffc0202aee:	44e68693          	addi	a3,a3,1102 # ffffffffc0204f38 <etext+0x1136>
ffffffffc0202af2:	00002617          	auipc	a2,0x2
ffffffffc0202af6:	cd660613          	addi	a2,a2,-810 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202afa:	17b00593          	li	a1,379
ffffffffc0202afe:	00002517          	auipc	a0,0x2
ffffffffc0202b02:	16a50513          	addi	a0,a0,362 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202b06:	901fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202b0a:	00002697          	auipc	a3,0x2
ffffffffc0202b0e:	41e68693          	addi	a3,a3,1054 # ffffffffc0204f28 <etext+0x1126>
ffffffffc0202b12:	00002617          	auipc	a2,0x2
ffffffffc0202b16:	cb660613          	addi	a2,a2,-842 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202b1a:	17a00593          	li	a1,378
ffffffffc0202b1e:	00002517          	auipc	a0,0x2
ffffffffc0202b22:	14a50513          	addi	a0,a0,330 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202b26:	8e1fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202b2a:	00002697          	auipc	a3,0x2
ffffffffc0202b2e:	3ee68693          	addi	a3,a3,1006 # ffffffffc0204f18 <etext+0x1116>
ffffffffc0202b32:	00002617          	auipc	a2,0x2
ffffffffc0202b36:	c9660613          	addi	a2,a2,-874 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202b3a:	17900593          	li	a1,377
ffffffffc0202b3e:	00002517          	auipc	a0,0x2
ffffffffc0202b42:	12a50513          	addi	a0,a0,298 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202b46:	8c1fd0ef          	jal	ffffffffc0200406 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202b4a:	00002617          	auipc	a2,0x2
ffffffffc0202b4e:	0d660613          	addi	a2,a2,214 # ffffffffc0204c20 <etext+0xe1e>
ffffffffc0202b52:	08000593          	li	a1,128
ffffffffc0202b56:	00002517          	auipc	a0,0x2
ffffffffc0202b5a:	11250513          	addi	a0,a0,274 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202b5e:	8a9fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202b62:	00002697          	auipc	a3,0x2
ffffffffc0202b66:	30e68693          	addi	a3,a3,782 # ffffffffc0204e70 <etext+0x106e>
ffffffffc0202b6a:	00002617          	auipc	a2,0x2
ffffffffc0202b6e:	c5e60613          	addi	a2,a2,-930 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202b72:	17400593          	li	a1,372
ffffffffc0202b76:	00002517          	auipc	a0,0x2
ffffffffc0202b7a:	0f250513          	addi	a0,a0,242 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202b7e:	889fd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202b82:	00002697          	auipc	a3,0x2
ffffffffc0202b86:	35e68693          	addi	a3,a3,862 # ffffffffc0204ee0 <etext+0x10de>
ffffffffc0202b8a:	00002617          	auipc	a2,0x2
ffffffffc0202b8e:	c3e60613          	addi	a2,a2,-962 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202b92:	17800593          	li	a1,376
ffffffffc0202b96:	00002517          	auipc	a0,0x2
ffffffffc0202b9a:	0d250513          	addi	a0,a0,210 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202b9e:	869fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202ba2:	00002697          	auipc	a3,0x2
ffffffffc0202ba6:	2fe68693          	addi	a3,a3,766 # ffffffffc0204ea0 <etext+0x109e>
ffffffffc0202baa:	00002617          	auipc	a2,0x2
ffffffffc0202bae:	c1e60613          	addi	a2,a2,-994 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202bb2:	17700593          	li	a1,375
ffffffffc0202bb6:	00002517          	auipc	a0,0x2
ffffffffc0202bba:	0b250513          	addi	a0,a0,178 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202bbe:	849fd0ef          	jal	ffffffffc0200406 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202bc2:	86d6                	mv	a3,s5
ffffffffc0202bc4:	00002617          	auipc	a2,0x2
ffffffffc0202bc8:	fb460613          	addi	a2,a2,-76 # ffffffffc0204b78 <etext+0xd76>
ffffffffc0202bcc:	17300593          	li	a1,371
ffffffffc0202bd0:	00002517          	auipc	a0,0x2
ffffffffc0202bd4:	09850513          	addi	a0,a0,152 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202bd8:	82ffd0ef          	jal	ffffffffc0200406 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0202bdc:	00002617          	auipc	a2,0x2
ffffffffc0202be0:	f9c60613          	addi	a2,a2,-100 # ffffffffc0204b78 <etext+0xd76>
ffffffffc0202be4:	17200593          	li	a1,370
ffffffffc0202be8:	00002517          	auipc	a0,0x2
ffffffffc0202bec:	08050513          	addi	a0,a0,128 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202bf0:	817fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202bf4:	00002697          	auipc	a3,0x2
ffffffffc0202bf8:	26468693          	addi	a3,a3,612 # ffffffffc0204e58 <etext+0x1056>
ffffffffc0202bfc:	00002617          	auipc	a2,0x2
ffffffffc0202c00:	bcc60613          	addi	a2,a2,-1076 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202c04:	17000593          	li	a1,368
ffffffffc0202c08:	00002517          	auipc	a0,0x2
ffffffffc0202c0c:	06050513          	addi	a0,a0,96 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202c10:	ff6fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c14:	00002697          	auipc	a3,0x2
ffffffffc0202c18:	22c68693          	addi	a3,a3,556 # ffffffffc0204e40 <etext+0x103e>
ffffffffc0202c1c:	00002617          	auipc	a2,0x2
ffffffffc0202c20:	bac60613          	addi	a2,a2,-1108 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202c24:	16f00593          	li	a1,367
ffffffffc0202c28:	00002517          	auipc	a0,0x2
ffffffffc0202c2c:	04050513          	addi	a0,a0,64 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202c30:	fd6fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c34:	00002697          	auipc	a3,0x2
ffffffffc0202c38:	5bc68693          	addi	a3,a3,1468 # ffffffffc02051f0 <etext+0x13ee>
ffffffffc0202c3c:	00002617          	auipc	a2,0x2
ffffffffc0202c40:	b8c60613          	addi	a2,a2,-1140 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202c44:	1b600593          	li	a1,438
ffffffffc0202c48:	00002517          	auipc	a0,0x2
ffffffffc0202c4c:	02050513          	addi	a0,a0,32 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202c50:	fb6fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c54:	00002697          	auipc	a3,0x2
ffffffffc0202c58:	56468693          	addi	a3,a3,1380 # ffffffffc02051b8 <etext+0x13b6>
ffffffffc0202c5c:	00002617          	auipc	a2,0x2
ffffffffc0202c60:	b6c60613          	addi	a2,a2,-1172 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202c64:	1b300593          	li	a1,435
ffffffffc0202c68:	00002517          	auipc	a0,0x2
ffffffffc0202c6c:	00050513          	mv	a0,a0
ffffffffc0202c70:	f96fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202c74:	00002697          	auipc	a3,0x2
ffffffffc0202c78:	51468693          	addi	a3,a3,1300 # ffffffffc0205188 <etext+0x1386>
ffffffffc0202c7c:	00002617          	auipc	a2,0x2
ffffffffc0202c80:	b4c60613          	addi	a2,a2,-1204 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202c84:	1af00593          	li	a1,431
ffffffffc0202c88:	00002517          	auipc	a0,0x2
ffffffffc0202c8c:	fe050513          	addi	a0,a0,-32 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202c90:	f76fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202c94:	00002697          	auipc	a3,0x2
ffffffffc0202c98:	4ac68693          	addi	a3,a3,1196 # ffffffffc0205140 <etext+0x133e>
ffffffffc0202c9c:	00002617          	auipc	a2,0x2
ffffffffc0202ca0:	b2c60613          	addi	a2,a2,-1236 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202ca4:	1ae00593          	li	a1,430
ffffffffc0202ca8:	00002517          	auipc	a0,0x2
ffffffffc0202cac:	fc050513          	addi	a0,a0,-64 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202cb0:	f56fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202cb4:	00002697          	auipc	a3,0x2
ffffffffc0202cb8:	0d468693          	addi	a3,a3,212 # ffffffffc0204d88 <etext+0xf86>
ffffffffc0202cbc:	00002617          	auipc	a2,0x2
ffffffffc0202cc0:	b0c60613          	addi	a2,a2,-1268 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202cc4:	16700593          	li	a1,359
ffffffffc0202cc8:	00002517          	auipc	a0,0x2
ffffffffc0202ccc:	fa050513          	addi	a0,a0,-96 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202cd0:	f36fd0ef          	jal	ffffffffc0200406 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202cd4:	00002617          	auipc	a2,0x2
ffffffffc0202cd8:	f4c60613          	addi	a2,a2,-180 # ffffffffc0204c20 <etext+0xe1e>
ffffffffc0202cdc:	0cb00593          	li	a1,203
ffffffffc0202ce0:	00002517          	auipc	a0,0x2
ffffffffc0202ce4:	f8850513          	addi	a0,a0,-120 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202ce8:	f1efd0ef          	jal	ffffffffc0200406 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202cec:	00002697          	auipc	a3,0x2
ffffffffc0202cf0:	0fc68693          	addi	a3,a3,252 # ffffffffc0204de8 <etext+0xfe6>
ffffffffc0202cf4:	00002617          	auipc	a2,0x2
ffffffffc0202cf8:	ad460613          	addi	a2,a2,-1324 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202cfc:	16e00593          	li	a1,366
ffffffffc0202d00:	00002517          	auipc	a0,0x2
ffffffffc0202d04:	f6850513          	addi	a0,a0,-152 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202d08:	efefd0ef          	jal	ffffffffc0200406 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202d0c:	00002697          	auipc	a3,0x2
ffffffffc0202d10:	0ac68693          	addi	a3,a3,172 # ffffffffc0204db8 <etext+0xfb6>
ffffffffc0202d14:	00002617          	auipc	a2,0x2
ffffffffc0202d18:	ab460613          	addi	a2,a2,-1356 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202d1c:	16b00593          	li	a1,363
ffffffffc0202d20:	00002517          	auipc	a0,0x2
ffffffffc0202d24:	f4850513          	addi	a0,a0,-184 # ffffffffc0204c68 <etext+0xe66>
ffffffffc0202d28:	edefd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202d2c <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d2c:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0202d2e:	00002697          	auipc	a3,0x2
ffffffffc0202d32:	50a68693          	addi	a3,a3,1290 # ffffffffc0205238 <etext+0x1436>
ffffffffc0202d36:	00002617          	auipc	a2,0x2
ffffffffc0202d3a:	a9260613          	addi	a2,a2,-1390 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202d3e:	08800593          	li	a1,136
ffffffffc0202d42:	00002517          	auipc	a0,0x2
ffffffffc0202d46:	51650513          	addi	a0,a0,1302 # ffffffffc0205258 <etext+0x1456>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0202d4a:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0202d4c:	ebafd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202d50 <find_vma>:
    if (mm != NULL)
ffffffffc0202d50:	c505                	beqz	a0,ffffffffc0202d78 <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc0202d52:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202d54:	c781                	beqz	a5,ffffffffc0202d5c <find_vma+0xc>
ffffffffc0202d56:	6798                	ld	a4,8(a5)
ffffffffc0202d58:	02e5f363          	bgeu	a1,a4,ffffffffc0202d7e <find_vma+0x2e>
    return listelm->next;
ffffffffc0202d5c:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc0202d5e:	00f50d63          	beq	a0,a5,ffffffffc0202d78 <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0202d62:	fe87b703          	ld	a4,-24(a5) # fffffffffdffffe8 <end+0x3ddf2b00>
ffffffffc0202d66:	00e5e663          	bltu	a1,a4,ffffffffc0202d72 <find_vma+0x22>
ffffffffc0202d6a:	ff07b703          	ld	a4,-16(a5)
ffffffffc0202d6e:	00e5ee63          	bltu	a1,a4,ffffffffc0202d8a <find_vma+0x3a>
ffffffffc0202d72:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0202d74:	fef517e3          	bne	a0,a5,ffffffffc0202d62 <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc0202d78:	4781                	li	a5,0
}
ffffffffc0202d7a:	853e                	mv	a0,a5
ffffffffc0202d7c:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0202d7e:	6b98                	ld	a4,16(a5)
ffffffffc0202d80:	fce5fee3          	bgeu	a1,a4,ffffffffc0202d5c <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0202d84:	e91c                	sd	a5,16(a0)
}
ffffffffc0202d86:	853e                	mv	a0,a5
ffffffffc0202d88:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0202d8a:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc0202d8c:	e91c                	sd	a5,16(a0)
ffffffffc0202d8e:	bfe5                	j	ffffffffc0202d86 <find_vma+0x36>

ffffffffc0202d90 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202d90:	6590                	ld	a2,8(a1)
ffffffffc0202d92:	0105b803          	ld	a6,16(a1)
{
ffffffffc0202d96:	1141                	addi	sp,sp,-16
ffffffffc0202d98:	e406                	sd	ra,8(sp)
ffffffffc0202d9a:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202d9c:	01066763          	bltu	a2,a6,ffffffffc0202daa <insert_vma_struct+0x1a>
ffffffffc0202da0:	a8b9                	j	ffffffffc0202dfe <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc0202da2:	fe87b703          	ld	a4,-24(a5)
ffffffffc0202da6:	04e66763          	bltu	a2,a4,ffffffffc0202df4 <insert_vma_struct+0x64>
ffffffffc0202daa:	86be                	mv	a3,a5
ffffffffc0202dac:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc0202dae:	fef51ae3          	bne	a0,a5,ffffffffc0202da2 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc0202db2:	02a68463          	beq	a3,a0,ffffffffc0202dda <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0202db6:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202dba:	fe86b883          	ld	a7,-24(a3)
ffffffffc0202dbe:	08e8f063          	bgeu	a7,a4,ffffffffc0202e3e <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202dc2:	04e66e63          	bltu	a2,a4,ffffffffc0202e1e <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0202dc6:	00f50a63          	beq	a0,a5,ffffffffc0202dda <insert_vma_struct+0x4a>
ffffffffc0202dca:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202dce:	05076863          	bltu	a4,a6,ffffffffc0202e1e <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0202dd2:	ff07b603          	ld	a2,-16(a5)
ffffffffc0202dd6:	02c77263          	bgeu	a4,a2,ffffffffc0202dfa <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0202dda:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0202ddc:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0202dde:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0202de2:	e390                	sd	a2,0(a5)
ffffffffc0202de4:	e690                	sd	a2,8(a3)
}
ffffffffc0202de6:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0202de8:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0202dea:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0202dec:	2705                	addiw	a4,a4,1
ffffffffc0202dee:	d118                	sw	a4,32(a0)
}
ffffffffc0202df0:	0141                	addi	sp,sp,16
ffffffffc0202df2:	8082                	ret
    if (le_prev != list)
ffffffffc0202df4:	fca691e3          	bne	a3,a0,ffffffffc0202db6 <insert_vma_struct+0x26>
ffffffffc0202df8:	bfd9                	j	ffffffffc0202dce <insert_vma_struct+0x3e>
ffffffffc0202dfa:	f33ff0ef          	jal	ffffffffc0202d2c <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0202dfe:	00002697          	auipc	a3,0x2
ffffffffc0202e02:	46a68693          	addi	a3,a3,1130 # ffffffffc0205268 <etext+0x1466>
ffffffffc0202e06:	00002617          	auipc	a2,0x2
ffffffffc0202e0a:	9c260613          	addi	a2,a2,-1598 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202e0e:	08e00593          	li	a1,142
ffffffffc0202e12:	00002517          	auipc	a0,0x2
ffffffffc0202e16:	44650513          	addi	a0,a0,1094 # ffffffffc0205258 <etext+0x1456>
ffffffffc0202e1a:	decfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0202e1e:	00002697          	auipc	a3,0x2
ffffffffc0202e22:	48a68693          	addi	a3,a3,1162 # ffffffffc02052a8 <etext+0x14a6>
ffffffffc0202e26:	00002617          	auipc	a2,0x2
ffffffffc0202e2a:	9a260613          	addi	a2,a2,-1630 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202e2e:	08700593          	li	a1,135
ffffffffc0202e32:	00002517          	auipc	a0,0x2
ffffffffc0202e36:	42650513          	addi	a0,a0,1062 # ffffffffc0205258 <etext+0x1456>
ffffffffc0202e3a:	dccfd0ef          	jal	ffffffffc0200406 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0202e3e:	00002697          	auipc	a3,0x2
ffffffffc0202e42:	44a68693          	addi	a3,a3,1098 # ffffffffc0205288 <etext+0x1486>
ffffffffc0202e46:	00002617          	auipc	a2,0x2
ffffffffc0202e4a:	98260613          	addi	a2,a2,-1662 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202e4e:	08600593          	li	a1,134
ffffffffc0202e52:	00002517          	auipc	a0,0x2
ffffffffc0202e56:	40650513          	addi	a0,a0,1030 # ffffffffc0205258 <etext+0x1456>
ffffffffc0202e5a:	dacfd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0202e5e <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0202e5e:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202e60:	03000513          	li	a0,48
{
ffffffffc0202e64:	fc06                	sd	ra,56(sp)
ffffffffc0202e66:	f822                	sd	s0,48(sp)
ffffffffc0202e68:	f426                	sd	s1,40(sp)
ffffffffc0202e6a:	f04a                	sd	s2,32(sp)
ffffffffc0202e6c:	ec4e                	sd	s3,24(sp)
ffffffffc0202e6e:	e852                	sd	s4,16(sp)
ffffffffc0202e70:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0202e72:	bc3fe0ef          	jal	ffffffffc0201a34 <kmalloc>
    if (mm != NULL)
ffffffffc0202e76:	18050a63          	beqz	a0,ffffffffc020300a <vmm_init+0x1ac>
ffffffffc0202e7a:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0202e7c:	e508                	sd	a0,8(a0)
ffffffffc0202e7e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0202e80:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0202e84:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0202e88:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0202e8c:	02053423          	sd	zero,40(a0)
ffffffffc0202e90:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202e94:	03000513          	li	a0,48
ffffffffc0202e98:	b9dfe0ef          	jal	ffffffffc0201a34 <kmalloc>
    if (vma != NULL)
ffffffffc0202e9c:	14050763          	beqz	a0,ffffffffc0202fea <vmm_init+0x18c>
        vma->vm_end = vm_end;
ffffffffc0202ea0:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0202ea4:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202ea6:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0202eaa:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202eac:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0202eae:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0202eb0:	8522                	mv	a0,s0
ffffffffc0202eb2:	edfff0ef          	jal	ffffffffc0202d90 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0202eb6:	fcf9                	bnez	s1,ffffffffc0202e94 <vmm_init+0x36>
ffffffffc0202eb8:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202ebc:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0202ec0:	03000513          	li	a0,48
ffffffffc0202ec4:	b71fe0ef          	jal	ffffffffc0201a34 <kmalloc>
    if (vma != NULL)
ffffffffc0202ec8:	16050163          	beqz	a0,ffffffffc020302a <vmm_init+0x1cc>
        vma->vm_end = vm_end;
ffffffffc0202ecc:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0202ed0:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0202ed2:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0202ed6:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0202ed8:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202eda:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0202edc:	8522                	mv	a0,s0
ffffffffc0202ede:	eb3ff0ef          	jal	ffffffffc0202d90 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0202ee2:	fd249fe3          	bne	s1,s2,ffffffffc0202ec0 <vmm_init+0x62>
    return listelm->next;
ffffffffc0202ee6:	641c                	ld	a5,8(s0)
ffffffffc0202ee8:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0202eea:	1fb00593          	li	a1,507
ffffffffc0202eee:	8abe                	mv	s5,a5
    {
        assert(le != &(mm->mmap_list));
ffffffffc0202ef0:	20f40d63          	beq	s0,a5,ffffffffc020310a <vmm_init+0x2ac>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0202ef4:	fe87b603          	ld	a2,-24(a5)
ffffffffc0202ef8:	ffe70693          	addi	a3,a4,-2
ffffffffc0202efc:	14d61763          	bne	a2,a3,ffffffffc020304a <vmm_init+0x1ec>
ffffffffc0202f00:	ff07b683          	ld	a3,-16(a5)
ffffffffc0202f04:	14e69363          	bne	a3,a4,ffffffffc020304a <vmm_init+0x1ec>
    for (i = 1; i <= step2; i++)
ffffffffc0202f08:	0715                	addi	a4,a4,5
ffffffffc0202f0a:	679c                	ld	a5,8(a5)
ffffffffc0202f0c:	feb712e3          	bne	a4,a1,ffffffffc0202ef0 <vmm_init+0x92>
ffffffffc0202f10:	491d                	li	s2,7
ffffffffc0202f12:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0202f14:	85a6                	mv	a1,s1
ffffffffc0202f16:	8522                	mv	a0,s0
ffffffffc0202f18:	e39ff0ef          	jal	ffffffffc0202d50 <find_vma>
ffffffffc0202f1c:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0202f1e:	22050663          	beqz	a0,ffffffffc020314a <vmm_init+0x2ec>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0202f22:	00148593          	addi	a1,s1,1
ffffffffc0202f26:	8522                	mv	a0,s0
ffffffffc0202f28:	e29ff0ef          	jal	ffffffffc0202d50 <find_vma>
ffffffffc0202f2c:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0202f2e:	1e050e63          	beqz	a0,ffffffffc020312a <vmm_init+0x2cc>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0202f32:	85ca                	mv	a1,s2
ffffffffc0202f34:	8522                	mv	a0,s0
ffffffffc0202f36:	e1bff0ef          	jal	ffffffffc0202d50 <find_vma>
        assert(vma3 == NULL);
ffffffffc0202f3a:	1a051863          	bnez	a0,ffffffffc02030ea <vmm_init+0x28c>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0202f3e:	00348593          	addi	a1,s1,3
ffffffffc0202f42:	8522                	mv	a0,s0
ffffffffc0202f44:	e0dff0ef          	jal	ffffffffc0202d50 <find_vma>
        assert(vma4 == NULL);
ffffffffc0202f48:	18051163          	bnez	a0,ffffffffc02030ca <vmm_init+0x26c>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0202f4c:	00448593          	addi	a1,s1,4
ffffffffc0202f50:	8522                	mv	a0,s0
ffffffffc0202f52:	dffff0ef          	jal	ffffffffc0202d50 <find_vma>
        assert(vma5 == NULL);
ffffffffc0202f56:	14051a63          	bnez	a0,ffffffffc02030aa <vmm_init+0x24c>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0202f5a:	008a3783          	ld	a5,8(s4)
ffffffffc0202f5e:	12979663          	bne	a5,s1,ffffffffc020308a <vmm_init+0x22c>
ffffffffc0202f62:	010a3783          	ld	a5,16(s4)
ffffffffc0202f66:	13279263          	bne	a5,s2,ffffffffc020308a <vmm_init+0x22c>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0202f6a:	0089b783          	ld	a5,8(s3)
ffffffffc0202f6e:	0e979e63          	bne	a5,s1,ffffffffc020306a <vmm_init+0x20c>
ffffffffc0202f72:	0109b783          	ld	a5,16(s3)
ffffffffc0202f76:	0f279a63          	bne	a5,s2,ffffffffc020306a <vmm_init+0x20c>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0202f7a:	0495                	addi	s1,s1,5
ffffffffc0202f7c:	1f900793          	li	a5,505
ffffffffc0202f80:	0915                	addi	s2,s2,5
ffffffffc0202f82:	f8f499e3          	bne	s1,a5,ffffffffc0202f14 <vmm_init+0xb6>
ffffffffc0202f86:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0202f88:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0202f8a:	85a6                	mv	a1,s1
ffffffffc0202f8c:	8522                	mv	a0,s0
ffffffffc0202f8e:	dc3ff0ef          	jal	ffffffffc0202d50 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0202f92:	1c051c63          	bnez	a0,ffffffffc020316a <vmm_init+0x30c>
    for (i = 4; i >= 0; i--)
ffffffffc0202f96:	14fd                	addi	s1,s1,-1
ffffffffc0202f98:	ff2499e3          	bne	s1,s2,ffffffffc0202f8a <vmm_init+0x12c>
    while ((le = list_next(list)) != list)
ffffffffc0202f9c:	028a8063          	beq	s5,s0,ffffffffc0202fbc <vmm_init+0x15e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0202fa0:	008ab783          	ld	a5,8(s5) # 1008 <kern_entry-0xffffffffc01feff8>
ffffffffc0202fa4:	000ab703          	ld	a4,0(s5)
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0202fa8:	fe0a8513          	addi	a0,s5,-32
    prev->next = next;
ffffffffc0202fac:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202fae:	e398                	sd	a4,0(a5)
ffffffffc0202fb0:	b2bfe0ef          	jal	ffffffffc0201ada <kfree>
    return listelm->next;
ffffffffc0202fb4:	641c                	ld	a5,8(s0)
ffffffffc0202fb6:	8abe                	mv	s5,a5
    while ((le = list_next(list)) != list)
ffffffffc0202fb8:	fef414e3          	bne	s0,a5,ffffffffc0202fa0 <vmm_init+0x142>
    kfree(mm); // kfree mm
ffffffffc0202fbc:	8522                	mv	a0,s0
ffffffffc0202fbe:	b1dfe0ef          	jal	ffffffffc0201ada <kfree>
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0202fc2:	00002517          	auipc	a0,0x2
ffffffffc0202fc6:	46650513          	addi	a0,a0,1126 # ffffffffc0205428 <etext+0x1626>
ffffffffc0202fca:	9cafd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202fce:	7442                	ld	s0,48(sp)
ffffffffc0202fd0:	70e2                	ld	ra,56(sp)
ffffffffc0202fd2:	74a2                	ld	s1,40(sp)
ffffffffc0202fd4:	7902                	ld	s2,32(sp)
ffffffffc0202fd6:	69e2                	ld	s3,24(sp)
ffffffffc0202fd8:	6a42                	ld	s4,16(sp)
ffffffffc0202fda:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202fdc:	00002517          	auipc	a0,0x2
ffffffffc0202fe0:	46c50513          	addi	a0,a0,1132 # ffffffffc0205448 <etext+0x1646>
}
ffffffffc0202fe4:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0202fe6:	9aefd06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0202fea:	00002697          	auipc	a3,0x2
ffffffffc0202fee:	2ee68693          	addi	a3,a3,750 # ffffffffc02052d8 <etext+0x14d6>
ffffffffc0202ff2:	00001617          	auipc	a2,0x1
ffffffffc0202ff6:	7d660613          	addi	a2,a2,2006 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc0202ffa:	0da00593          	li	a1,218
ffffffffc0202ffe:	00002517          	auipc	a0,0x2
ffffffffc0203002:	25a50513          	addi	a0,a0,602 # ffffffffc0205258 <etext+0x1456>
ffffffffc0203006:	c00fd0ef          	jal	ffffffffc0200406 <__panic>
    assert(mm != NULL);
ffffffffc020300a:	00002697          	auipc	a3,0x2
ffffffffc020300e:	2be68693          	addi	a3,a3,702 # ffffffffc02052c8 <etext+0x14c6>
ffffffffc0203012:	00001617          	auipc	a2,0x1
ffffffffc0203016:	7b660613          	addi	a2,a2,1974 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020301a:	0d200593          	li	a1,210
ffffffffc020301e:	00002517          	auipc	a0,0x2
ffffffffc0203022:	23a50513          	addi	a0,a0,570 # ffffffffc0205258 <etext+0x1456>
ffffffffc0203026:	be0fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma != NULL);
ffffffffc020302a:	00002697          	auipc	a3,0x2
ffffffffc020302e:	2ae68693          	addi	a3,a3,686 # ffffffffc02052d8 <etext+0x14d6>
ffffffffc0203032:	00001617          	auipc	a2,0x1
ffffffffc0203036:	79660613          	addi	a2,a2,1942 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020303a:	0e100593          	li	a1,225
ffffffffc020303e:	00002517          	auipc	a0,0x2
ffffffffc0203042:	21a50513          	addi	a0,a0,538 # ffffffffc0205258 <etext+0x1456>
ffffffffc0203046:	bc0fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020304a:	00002697          	auipc	a3,0x2
ffffffffc020304e:	2b668693          	addi	a3,a3,694 # ffffffffc0205300 <etext+0x14fe>
ffffffffc0203052:	00001617          	auipc	a2,0x1
ffffffffc0203056:	77660613          	addi	a2,a2,1910 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020305a:	0eb00593          	li	a1,235
ffffffffc020305e:	00002517          	auipc	a0,0x2
ffffffffc0203062:	1fa50513          	addi	a0,a0,506 # ffffffffc0205258 <etext+0x1456>
ffffffffc0203066:	ba0fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc020306a:	00002697          	auipc	a3,0x2
ffffffffc020306e:	34e68693          	addi	a3,a3,846 # ffffffffc02053b8 <etext+0x15b6>
ffffffffc0203072:	00001617          	auipc	a2,0x1
ffffffffc0203076:	75660613          	addi	a2,a2,1878 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020307a:	0fd00593          	li	a1,253
ffffffffc020307e:	00002517          	auipc	a0,0x2
ffffffffc0203082:	1da50513          	addi	a0,a0,474 # ffffffffc0205258 <etext+0x1456>
ffffffffc0203086:	b80fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc020308a:	00002697          	auipc	a3,0x2
ffffffffc020308e:	2fe68693          	addi	a3,a3,766 # ffffffffc0205388 <etext+0x1586>
ffffffffc0203092:	00001617          	auipc	a2,0x1
ffffffffc0203096:	73660613          	addi	a2,a2,1846 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020309a:	0fc00593          	li	a1,252
ffffffffc020309e:	00002517          	auipc	a0,0x2
ffffffffc02030a2:	1ba50513          	addi	a0,a0,442 # ffffffffc0205258 <etext+0x1456>
ffffffffc02030a6:	b60fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma5 == NULL);
ffffffffc02030aa:	00002697          	auipc	a3,0x2
ffffffffc02030ae:	2ce68693          	addi	a3,a3,718 # ffffffffc0205378 <etext+0x1576>
ffffffffc02030b2:	00001617          	auipc	a2,0x1
ffffffffc02030b6:	71660613          	addi	a2,a2,1814 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02030ba:	0fa00593          	li	a1,250
ffffffffc02030be:	00002517          	auipc	a0,0x2
ffffffffc02030c2:	19a50513          	addi	a0,a0,410 # ffffffffc0205258 <etext+0x1456>
ffffffffc02030c6:	b40fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma4 == NULL);
ffffffffc02030ca:	00002697          	auipc	a3,0x2
ffffffffc02030ce:	29e68693          	addi	a3,a3,670 # ffffffffc0205368 <etext+0x1566>
ffffffffc02030d2:	00001617          	auipc	a2,0x1
ffffffffc02030d6:	6f660613          	addi	a2,a2,1782 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02030da:	0f800593          	li	a1,248
ffffffffc02030de:	00002517          	auipc	a0,0x2
ffffffffc02030e2:	17a50513          	addi	a0,a0,378 # ffffffffc0205258 <etext+0x1456>
ffffffffc02030e6:	b20fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma3 == NULL);
ffffffffc02030ea:	00002697          	auipc	a3,0x2
ffffffffc02030ee:	26e68693          	addi	a3,a3,622 # ffffffffc0205358 <etext+0x1556>
ffffffffc02030f2:	00001617          	auipc	a2,0x1
ffffffffc02030f6:	6d660613          	addi	a2,a2,1750 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02030fa:	0f600593          	li	a1,246
ffffffffc02030fe:	00002517          	auipc	a0,0x2
ffffffffc0203102:	15a50513          	addi	a0,a0,346 # ffffffffc0205258 <etext+0x1456>
ffffffffc0203106:	b00fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020310a:	00002697          	auipc	a3,0x2
ffffffffc020310e:	1de68693          	addi	a3,a3,478 # ffffffffc02052e8 <etext+0x14e6>
ffffffffc0203112:	00001617          	auipc	a2,0x1
ffffffffc0203116:	6b660613          	addi	a2,a2,1718 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020311a:	0e900593          	li	a1,233
ffffffffc020311e:	00002517          	auipc	a0,0x2
ffffffffc0203122:	13a50513          	addi	a0,a0,314 # ffffffffc0205258 <etext+0x1456>
ffffffffc0203126:	ae0fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma2 != NULL);
ffffffffc020312a:	00002697          	auipc	a3,0x2
ffffffffc020312e:	21e68693          	addi	a3,a3,542 # ffffffffc0205348 <etext+0x1546>
ffffffffc0203132:	00001617          	auipc	a2,0x1
ffffffffc0203136:	69660613          	addi	a2,a2,1686 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020313a:	0f400593          	li	a1,244
ffffffffc020313e:	00002517          	auipc	a0,0x2
ffffffffc0203142:	11a50513          	addi	a0,a0,282 # ffffffffc0205258 <etext+0x1456>
ffffffffc0203146:	ac0fd0ef          	jal	ffffffffc0200406 <__panic>
        assert(vma1 != NULL);
ffffffffc020314a:	00002697          	auipc	a3,0x2
ffffffffc020314e:	1ee68693          	addi	a3,a3,494 # ffffffffc0205338 <etext+0x1536>
ffffffffc0203152:	00001617          	auipc	a2,0x1
ffffffffc0203156:	67660613          	addi	a2,a2,1654 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020315a:	0f200593          	li	a1,242
ffffffffc020315e:	00002517          	auipc	a0,0x2
ffffffffc0203162:	0fa50513          	addi	a0,a0,250 # ffffffffc0205258 <etext+0x1456>
ffffffffc0203166:	aa0fd0ef          	jal	ffffffffc0200406 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc020316a:	6914                	ld	a3,16(a0)
ffffffffc020316c:	6510                	ld	a2,8(a0)
ffffffffc020316e:	0004859b          	sext.w	a1,s1
ffffffffc0203172:	00002517          	auipc	a0,0x2
ffffffffc0203176:	27650513          	addi	a0,a0,630 # ffffffffc02053e8 <etext+0x15e6>
ffffffffc020317a:	81afd0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc020317e:	00002697          	auipc	a3,0x2
ffffffffc0203182:	29268693          	addi	a3,a3,658 # ffffffffc0205410 <etext+0x160e>
ffffffffc0203186:	00001617          	auipc	a2,0x1
ffffffffc020318a:	64260613          	addi	a2,a2,1602 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020318e:	10700593          	li	a1,263
ffffffffc0203192:	00002517          	auipc	a0,0x2
ffffffffc0203196:	0c650513          	addi	a0,a0,198 # ffffffffc0205258 <etext+0x1456>
ffffffffc020319a:	a6cfd0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020319e <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc020319e:	8526                	mv	a0,s1
	jalr s0
ffffffffc02031a0:	9402                	jalr	s0

	jal do_exit
ffffffffc02031a2:	3be000ef          	jal	ffffffffc0203560 <do_exit>

ffffffffc02031a6 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc02031a6:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02031a8:	0e800513          	li	a0,232
{
ffffffffc02031ac:	e022                	sd	s0,0(sp)
ffffffffc02031ae:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc02031b0:	885fe0ef          	jal	ffffffffc0201a34 <kmalloc>
ffffffffc02031b4:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc02031b6:	cd21                	beqz	a0,ffffffffc020320e <alloc_proc+0x68>
    {
        // LAB4:EXERCISE1 2313411
        proc->state = PROC_UNINIT;
ffffffffc02031b8:	57fd                	li	a5,-1
ffffffffc02031ba:	1782                	slli	a5,a5,0x20
ffffffffc02031bc:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc02031be:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc02031c2:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc02031c6:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;
ffffffffc02031ca:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc02031ce:	02053423          	sd	zero,40(a0)
        memset(&proc->context, 0, sizeof(struct context));
ffffffffc02031d2:	07000613          	li	a2,112
ffffffffc02031d6:	4581                	li	a1,0
ffffffffc02031d8:	03050513          	addi	a0,a0,48
ffffffffc02031dc:	3d9000ef          	jal	ffffffffc0203db4 <memset>
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
ffffffffc02031e0:	0000a797          	auipc	a5,0xa
ffffffffc02031e4:	2c07b783          	ld	a5,704(a5) # ffffffffc020d4a0 <boot_pgdir_pa>
        proc->tf = NULL;
ffffffffc02031e8:	0a043023          	sd	zero,160(s0) # ffffffffc02000a0 <kern_init+0x56>
        proc->flags = 0;
ffffffffc02031ec:	0a042823          	sw	zero,176(s0)
        proc->pgdir = boot_pgdir_pa;
ffffffffc02031f0:	f45c                	sd	a5,168(s0)
        memset(proc->name, 0, sizeof(proc->name));
ffffffffc02031f2:	0b440513          	addi	a0,s0,180
ffffffffc02031f6:	4641                	li	a2,16
ffffffffc02031f8:	4581                	li	a1,0
ffffffffc02031fa:	3bb000ef          	jal	ffffffffc0203db4 <memset>
        list_init(&proc->list_link);
ffffffffc02031fe:	0c840713          	addi	a4,s0,200
        list_init(&proc->hash_link);
ffffffffc0203202:	0d840793          	addi	a5,s0,216
    elm->prev = elm->next = elm;
ffffffffc0203206:	e878                	sd	a4,208(s0)
ffffffffc0203208:	e478                	sd	a4,200(s0)
ffffffffc020320a:	f07c                	sd	a5,224(s0)
ffffffffc020320c:	ec7c                	sd	a5,216(s0)
        
    }
    return proc;
}
ffffffffc020320e:	60a2                	ld	ra,8(sp)
ffffffffc0203210:	8522                	mv	a0,s0
ffffffffc0203212:	6402                	ld	s0,0(sp)
ffffffffc0203214:	0141                	addi	sp,sp,16
ffffffffc0203216:	8082                	ret

ffffffffc0203218 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203218:	0000a797          	auipc	a5,0xa
ffffffffc020321c:	2b87b783          	ld	a5,696(a5) # ffffffffc020d4d0 <current>
ffffffffc0203220:	73c8                	ld	a0,160(a5)
ffffffffc0203222:	a9bfd06f          	j	ffffffffc0200cbc <forkrets>

ffffffffc0203226 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc0203226:	1101                	addi	sp,sp,-32
ffffffffc0203228:	e822                	sd	s0,16(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc020322a:	0000a417          	auipc	s0,0xa
ffffffffc020322e:	2a643403          	ld	s0,678(s0) # ffffffffc020d4d0 <current>
{
ffffffffc0203232:	e04a                	sd	s2,0(sp)
    memset(name, 0, sizeof(name));
ffffffffc0203234:	4641                	li	a2,16
{
ffffffffc0203236:	892a                	mv	s2,a0
    memset(name, 0, sizeof(name));
ffffffffc0203238:	4581                	li	a1,0
ffffffffc020323a:	00006517          	auipc	a0,0x6
ffffffffc020323e:	20e50513          	addi	a0,a0,526 # ffffffffc0209448 <name.2>
{
ffffffffc0203242:	ec06                	sd	ra,24(sp)
ffffffffc0203244:	e426                	sd	s1,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203246:	4044                	lw	s1,4(s0)
    memset(name, 0, sizeof(name));
ffffffffc0203248:	36d000ef          	jal	ffffffffc0203db4 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);
ffffffffc020324c:	0b440593          	addi	a1,s0,180
ffffffffc0203250:	463d                	li	a2,15
ffffffffc0203252:	00006517          	auipc	a0,0x6
ffffffffc0203256:	1f650513          	addi	a0,a0,502 # ffffffffc0209448 <name.2>
ffffffffc020325a:	36d000ef          	jal	ffffffffc0203dc6 <memcpy>
ffffffffc020325e:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
ffffffffc0203260:	85a6                	mv	a1,s1
ffffffffc0203262:	00002517          	auipc	a0,0x2
ffffffffc0203266:	1fe50513          	addi	a0,a0,510 # ffffffffc0205460 <etext+0x165e>
ffffffffc020326a:	f2bfc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg);
ffffffffc020326e:	85ca                	mv	a1,s2
ffffffffc0203270:	00002517          	auipc	a0,0x2
ffffffffc0203274:	21850513          	addi	a0,a0,536 # ffffffffc0205488 <etext+0x1686>
ffffffffc0203278:	f1dfc0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
ffffffffc020327c:	00002517          	auipc	a0,0x2
ffffffffc0203280:	21c50513          	addi	a0,a0,540 # ffffffffc0205498 <etext+0x1696>
ffffffffc0203284:	f11fc0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc0203288:	60e2                	ld	ra,24(sp)
ffffffffc020328a:	6442                	ld	s0,16(sp)
ffffffffc020328c:	64a2                	ld	s1,8(sp)
ffffffffc020328e:	6902                	ld	s2,0(sp)
ffffffffc0203290:	4501                	li	a0,0
ffffffffc0203292:	6105                	addi	sp,sp,32
ffffffffc0203294:	8082                	ret

ffffffffc0203296 <proc_run>:
    if (proc != current)
ffffffffc0203296:	0000a797          	auipc	a5,0xa
ffffffffc020329a:	23a78793          	addi	a5,a5,570 # ffffffffc020d4d0 <current>
ffffffffc020329e:	6398                	ld	a4,0(a5)
ffffffffc02032a0:	04a70263          	beq	a4,a0,ffffffffc02032e4 <proc_run+0x4e>
{
ffffffffc02032a4:	1101                	addi	sp,sp,-32
ffffffffc02032a6:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02032a8:	100026f3          	csrr	a3,sstatus
ffffffffc02032ac:	8a89                	andi	a3,a3,2
    return 0;
ffffffffc02032ae:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02032b0:	ea9d                	bnez	a3,ffffffffc02032e6 <proc_run+0x50>
        current = proc;
ffffffffc02032b2:	e388                	sd	a0,0(a5)
        lsatp(proc->pgdir);
ffffffffc02032b4:	755c                	ld	a5,168(a0)
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned int pgdir)
{
  write_csr(satp, SATP32_MODE | (pgdir >> RISCV_PGSHIFT));
ffffffffc02032b6:	800006b7          	lui	a3,0x80000
ffffffffc02032ba:	e432                	sd	a2,8(sp)
ffffffffc02032bc:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc02032c0:	8fd5                	or	a5,a5,a3
ffffffffc02032c2:	18079073          	csrw	satp,a5
        switch_to(&prev->context, &proc->context);
ffffffffc02032c6:	03050593          	addi	a1,a0,48
ffffffffc02032ca:	03070513          	addi	a0,a4,48
ffffffffc02032ce:	520000ef          	jal	ffffffffc02037ee <switch_to>
    if (flag) {
ffffffffc02032d2:	6622                	ld	a2,8(sp)
ffffffffc02032d4:	e601                	bnez	a2,ffffffffc02032dc <proc_run+0x46>
}
ffffffffc02032d6:	60e2                	ld	ra,24(sp)
ffffffffc02032d8:	6105                	addi	sp,sp,32
ffffffffc02032da:	8082                	ret
ffffffffc02032dc:	60e2                	ld	ra,24(sp)
ffffffffc02032de:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02032e0:	d8efd06f          	j	ffffffffc020086e <intr_enable>
ffffffffc02032e4:	8082                	ret
        intr_disable();
ffffffffc02032e6:	e42a                	sd	a0,8(sp)
ffffffffc02032e8:	d8cfd0ef          	jal	ffffffffc0200874 <intr_disable>
        struct proc_struct *prev = current;
ffffffffc02032ec:	0000a797          	auipc	a5,0xa
ffffffffc02032f0:	1e478793          	addi	a5,a5,484 # ffffffffc020d4d0 <current>
ffffffffc02032f4:	6398                	ld	a4,0(a5)
        return 1;
ffffffffc02032f6:	6522                	ld	a0,8(sp)
ffffffffc02032f8:	4605                	li	a2,1
ffffffffc02032fa:	bf65                	j	ffffffffc02032b2 <proc_run+0x1c>

ffffffffc02032fc <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc02032fc:	0000a717          	auipc	a4,0xa
ffffffffc0203300:	1cc72703          	lw	a4,460(a4) # ffffffffc020d4c8 <nr_process>
ffffffffc0203304:	6785                	lui	a5,0x1
ffffffffc0203306:	1cf75763          	bge	a4,a5,ffffffffc02034d4 <do_fork+0x1d8>
{
ffffffffc020330a:	1101                	addi	sp,sp,-32
ffffffffc020330c:	e822                	sd	s0,16(sp)
ffffffffc020330e:	e426                	sd	s1,8(sp)
ffffffffc0203310:	e04a                	sd	s2,0(sp)
ffffffffc0203312:	ec06                	sd	ra,24(sp)
ffffffffc0203314:	892e                	mv	s2,a1
ffffffffc0203316:	84b2                	mv	s1,a2
    proc = alloc_proc();
ffffffffc0203318:	e8fff0ef          	jal	ffffffffc02031a6 <alloc_proc>
ffffffffc020331c:	842a                	mv	s0,a0
    if (!proc)
ffffffffc020331e:	1a050963          	beqz	a0,ffffffffc02034d0 <do_fork+0x1d4>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0203322:	4509                	li	a0,2
ffffffffc0203324:	8d3fe0ef          	jal	ffffffffc0201bf6 <alloc_pages>
    if (page != NULL)
ffffffffc0203328:	1a050163          	beqz	a0,ffffffffc02034ca <do_fork+0x1ce>
    return page - pages + nbase;
ffffffffc020332c:	0000a697          	auipc	a3,0xa
ffffffffc0203330:	1946b683          	ld	a3,404(a3) # ffffffffc020d4c0 <pages>
ffffffffc0203334:	00002797          	auipc	a5,0x2
ffffffffc0203338:	6147b783          	ld	a5,1556(a5) # ffffffffc0205948 <nbase>
    return KADDR(page2pa(page));
ffffffffc020333c:	0000a717          	auipc	a4,0xa
ffffffffc0203340:	17c73703          	ld	a4,380(a4) # ffffffffc020d4b8 <npage>
    return page - pages + nbase;
ffffffffc0203344:	40d506b3          	sub	a3,a0,a3
ffffffffc0203348:	8699                	srai	a3,a3,0x6
ffffffffc020334a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc020334c:	00c69793          	slli	a5,a3,0xc
ffffffffc0203350:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203352:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203354:	1ae7f263          	bgeu	a5,a4,ffffffffc02034f8 <do_fork+0x1fc>
    assert(current->mm == NULL);
ffffffffc0203358:	0000ae17          	auipc	t3,0xa
ffffffffc020335c:	178e3e03          	ld	t3,376(t3) # ffffffffc020d4d0 <current>
ffffffffc0203360:	0000a717          	auipc	a4,0xa
ffffffffc0203364:	15073703          	ld	a4,336(a4) # ffffffffc020d4b0 <va_pa_offset>
ffffffffc0203368:	028e3783          	ld	a5,40(t3)
ffffffffc020336c:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc020336e:	e814                	sd	a3,16(s0)
    assert(current->mm == NULL);
ffffffffc0203370:	16079463          	bnez	a5,ffffffffc02034d8 <do_fork+0x1dc>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0203374:	6789                	lui	a5,0x2
ffffffffc0203376:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc020337a:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc020337c:	8626                	mv	a2,s1
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc020337e:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0203380:	87b6                	mv	a5,a3
ffffffffc0203382:	12048713          	addi	a4,s1,288
ffffffffc0203386:	6a0c                	ld	a1,16(a2)
ffffffffc0203388:	00063803          	ld	a6,0(a2)
ffffffffc020338c:	6608                	ld	a0,8(a2)
ffffffffc020338e:	eb8c                	sd	a1,16(a5)
ffffffffc0203390:	0107b023          	sd	a6,0(a5)
ffffffffc0203394:	e788                	sd	a0,8(a5)
ffffffffc0203396:	6e0c                	ld	a1,24(a2)
ffffffffc0203398:	02060613          	addi	a2,a2,32
ffffffffc020339c:	02078793          	addi	a5,a5,32
ffffffffc02033a0:	feb7bc23          	sd	a1,-8(a5)
ffffffffc02033a4:	fee611e3          	bne	a2,a4,ffffffffc0203386 <do_fork+0x8a>
    proc->tf->gpr.a0 = 0;
ffffffffc02033a8:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02033ac:	10090163          	beqz	s2,ffffffffc02034ae <do_fork+0x1b2>
    if (++last_pid >= MAX_PID)
ffffffffc02033b0:	00006517          	auipc	a0,0x6
ffffffffc02033b4:	c7c52503          	lw	a0,-900(a0) # ffffffffc020902c <last_pid.1>
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02033b8:	00000797          	auipc	a5,0x0
ffffffffc02033bc:	e6078793          	addi	a5,a5,-416 # ffffffffc0203218 <forkret>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02033c0:	0126b823          	sd	s2,16(a3)
    if (++last_pid >= MAX_PID)
ffffffffc02033c4:	2505                	addiw	a0,a0,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02033c6:	f81c                	sd	a5,48(s0)
    if (++last_pid >= MAX_PID)
ffffffffc02033c8:	00006797          	auipc	a5,0x6
ffffffffc02033cc:	c6a7a223          	sw	a0,-924(a5) # ffffffffc020902c <last_pid.1>
    __list_add(elm, listelm, listelm->next);
ffffffffc02033d0:	0000a617          	auipc	a2,0xa
ffffffffc02033d4:	08860613          	addi	a2,a2,136 # ffffffffc020d458 <proc_list>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02033d8:	fc14                	sd	a3,56(s0)
    if (++last_pid >= MAX_PID)
ffffffffc02033da:	6789                	lui	a5,0x2
ffffffffc02033dc:	00863883          	ld	a7,8(a2)
ffffffffc02033e0:	0cf55963          	bge	a0,a5,ffffffffc02034b2 <do_fork+0x1b6>
    if (last_pid >= next_safe)
ffffffffc02033e4:	00006797          	auipc	a5,0x6
ffffffffc02033e8:	c447a783          	lw	a5,-956(a5) # ffffffffc0209028 <next_safe.0>
ffffffffc02033ec:	06f54063          	blt	a0,a5,ffffffffc020344c <do_fork+0x150>
        next_safe = MAX_PID;
ffffffffc02033f0:	6789                	lui	a5,0x2
ffffffffc02033f2:	00006717          	auipc	a4,0x6
ffffffffc02033f6:	c2f72b23          	sw	a5,-970(a4) # ffffffffc0209028 <next_safe.0>
ffffffffc02033fa:	86aa                	mv	a3,a0
ffffffffc02033fc:	4801                	li	a6,0
        while ((le = list_next(le)) != list)
ffffffffc02033fe:	04c88063          	beq	a7,a2,ffffffffc020343e <do_fork+0x142>
ffffffffc0203402:	8342                	mv	t1,a6
    return listelm->next;
ffffffffc0203404:	87c6                	mv	a5,a7
ffffffffc0203406:	6589                	lui	a1,0x2
ffffffffc0203408:	a811                	j	ffffffffc020341c <do_fork+0x120>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020340a:	00e6d663          	bge	a3,a4,ffffffffc0203416 <do_fork+0x11a>
ffffffffc020340e:	00b75463          	bge	a4,a1,ffffffffc0203416 <do_fork+0x11a>
                next_safe = proc->pid;
ffffffffc0203412:	85ba                	mv	a1,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0203414:	4305                	li	t1,1
ffffffffc0203416:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0203418:	00c78d63          	beq	a5,a2,ffffffffc0203432 <do_fork+0x136>
            if (proc->pid == last_pid)
ffffffffc020341c:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc0203420:	fed715e3          	bne	a4,a3,ffffffffc020340a <do_fork+0x10e>
                if (++last_pid >= next_safe)
ffffffffc0203424:	2685                	addiw	a3,a3,1
ffffffffc0203426:	08b6dc63          	bge	a3,a1,ffffffffc02034be <do_fork+0x1c2>
ffffffffc020342a:	679c                	ld	a5,8(a5)
ffffffffc020342c:	4805                	li	a6,1
        while ((le = list_next(le)) != list)
ffffffffc020342e:	fec797e3          	bne	a5,a2,ffffffffc020341c <do_fork+0x120>
ffffffffc0203432:	00030663          	beqz	t1,ffffffffc020343e <do_fork+0x142>
ffffffffc0203436:	00006797          	auipc	a5,0x6
ffffffffc020343a:	beb7a923          	sw	a1,-1038(a5) # ffffffffc0209028 <next_safe.0>
ffffffffc020343e:	00080763          	beqz	a6,ffffffffc020344c <do_fork+0x150>
ffffffffc0203442:	00006797          	auipc	a5,0x6
ffffffffc0203446:	bed7a523          	sw	a3,-1046(a5) # ffffffffc020902c <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020344a:	8536                	mv	a0,a3
    list_add(&proc_list, &proc->list_link);
ffffffffc020344c:	0c840793          	addi	a5,s0,200
    proc->pid = get_pid();
ffffffffc0203450:	c048                	sw	a0,4(s0)
    proc->parent = current;
ffffffffc0203452:	03c43023          	sd	t3,32(s0)
    prev->next = next->prev = elm;
ffffffffc0203456:	00f8b023          	sd	a5,0(a7)
    elm->next = next;
ffffffffc020345a:	0d143823          	sd	a7,208(s0)
    elm->prev = prev;
ffffffffc020345e:	e470                	sd	a2,200(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0203460:	45a9                	li	a1,10
    prev->next = next->prev = elm;
ffffffffc0203462:	e61c                	sd	a5,8(a2)
ffffffffc0203464:	4ba000ef          	jal	ffffffffc020391e <hash32>
ffffffffc0203468:	02051713          	slli	a4,a0,0x20
ffffffffc020346c:	01c75793          	srli	a5,a4,0x1c
ffffffffc0203470:	00006717          	auipc	a4,0x6
ffffffffc0203474:	fe870713          	addi	a4,a4,-24 # ffffffffc0209458 <hash_list>
ffffffffc0203478:	97ba                	add	a5,a5,a4
    __list_add(elm, listelm, listelm->next);
ffffffffc020347a:	6798                	ld	a4,8(a5)
ffffffffc020347c:	0d840693          	addi	a3,s0,216
    wakeup_proc(proc);
ffffffffc0203480:	8522                	mv	a0,s0
    prev->next = next->prev = elm;
ffffffffc0203482:	e314                	sd	a3,0(a4)
ffffffffc0203484:	e794                	sd	a3,8(a5)
    elm->next = next;
ffffffffc0203486:	f078                	sd	a4,224(s0)
    elm->prev = prev;
ffffffffc0203488:	ec7c                	sd	a5,216(s0)
ffffffffc020348a:	3ce000ef          	jal	ffffffffc0203858 <wakeup_proc>
    nr_process++;
ffffffffc020348e:	0000a797          	auipc	a5,0xa
ffffffffc0203492:	03a7a783          	lw	a5,58(a5) # ffffffffc020d4c8 <nr_process>
    ret = proc->pid;
ffffffffc0203496:	4048                	lw	a0,4(s0)
    nr_process++;
ffffffffc0203498:	2785                	addiw	a5,a5,1
ffffffffc020349a:	0000a717          	auipc	a4,0xa
ffffffffc020349e:	02f72723          	sw	a5,46(a4) # ffffffffc020d4c8 <nr_process>
}
ffffffffc02034a2:	60e2                	ld	ra,24(sp)
ffffffffc02034a4:	6442                	ld	s0,16(sp)
ffffffffc02034a6:	64a2                	ld	s1,8(sp)
ffffffffc02034a8:	6902                	ld	s2,0(sp)
ffffffffc02034aa:	6105                	addi	sp,sp,32
ffffffffc02034ac:	8082                	ret
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02034ae:	8936                	mv	s2,a3
ffffffffc02034b0:	b701                	j	ffffffffc02033b0 <do_fork+0xb4>
        last_pid = 1;
ffffffffc02034b2:	4505                	li	a0,1
ffffffffc02034b4:	00006797          	auipc	a5,0x6
ffffffffc02034b8:	b6a7ac23          	sw	a0,-1160(a5) # ffffffffc020902c <last_pid.1>
        goto inside;
ffffffffc02034bc:	bf15                	j	ffffffffc02033f0 <do_fork+0xf4>
                    if (last_pid >= MAX_PID)
ffffffffc02034be:	6789                	lui	a5,0x2
ffffffffc02034c0:	00f6c363          	blt	a3,a5,ffffffffc02034c6 <do_fork+0x1ca>
                        last_pid = 1;
ffffffffc02034c4:	4685                	li	a3,1
                    goto repeat;
ffffffffc02034c6:	4805                	li	a6,1
ffffffffc02034c8:	bf1d                	j	ffffffffc02033fe <do_fork+0x102>
    kfree(proc);
ffffffffc02034ca:	8522                	mv	a0,s0
ffffffffc02034cc:	e0efe0ef          	jal	ffffffffc0201ada <kfree>
    ret = -E_NO_MEM;
ffffffffc02034d0:	5571                	li	a0,-4
ffffffffc02034d2:	bfc1                	j	ffffffffc02034a2 <do_fork+0x1a6>
    int ret = -E_NO_FREE_PROC;
ffffffffc02034d4:	556d                	li	a0,-5
}
ffffffffc02034d6:	8082                	ret
    assert(current->mm == NULL);
ffffffffc02034d8:	00002697          	auipc	a3,0x2
ffffffffc02034dc:	fe068693          	addi	a3,a3,-32 # ffffffffc02054b8 <etext+0x16b6>
ffffffffc02034e0:	00001617          	auipc	a2,0x1
ffffffffc02034e4:	2e860613          	addi	a2,a2,744 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02034e8:	10700593          	li	a1,263
ffffffffc02034ec:	00002517          	auipc	a0,0x2
ffffffffc02034f0:	fe450513          	addi	a0,a0,-28 # ffffffffc02054d0 <etext+0x16ce>
ffffffffc02034f4:	f13fc0ef          	jal	ffffffffc0200406 <__panic>
ffffffffc02034f8:	00001617          	auipc	a2,0x1
ffffffffc02034fc:	68060613          	addi	a2,a2,1664 # ffffffffc0204b78 <etext+0xd76>
ffffffffc0203500:	07100593          	li	a1,113
ffffffffc0203504:	00001517          	auipc	a0,0x1
ffffffffc0203508:	69c50513          	addi	a0,a0,1692 # ffffffffc0204ba0 <etext+0xd9e>
ffffffffc020350c:	efbfc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc0203510 <kernel_thread>:
{
ffffffffc0203510:	7129                	addi	sp,sp,-320
ffffffffc0203512:	fa22                	sd	s0,304(sp)
ffffffffc0203514:	f626                	sd	s1,296(sp)
ffffffffc0203516:	f24a                	sd	s2,288(sp)
ffffffffc0203518:	842a                	mv	s0,a0
ffffffffc020351a:	84ae                	mv	s1,a1
ffffffffc020351c:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020351e:	850a                	mv	a0,sp
ffffffffc0203520:	12000613          	li	a2,288
ffffffffc0203524:	4581                	li	a1,0
{
ffffffffc0203526:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0203528:	08d000ef          	jal	ffffffffc0203db4 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020352c:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020352e:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0203530:	100027f3          	csrr	a5,sstatus
ffffffffc0203534:	edd7f793          	andi	a5,a5,-291
ffffffffc0203538:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020353c:	860a                	mv	a2,sp
ffffffffc020353e:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0203542:	00000717          	auipc	a4,0x0
ffffffffc0203546:	c5c70713          	addi	a4,a4,-932 # ffffffffc020319e <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020354a:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020354c:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020354e:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0203550:	dadff0ef          	jal	ffffffffc02032fc <do_fork>
}
ffffffffc0203554:	70f2                	ld	ra,312(sp)
ffffffffc0203556:	7452                	ld	s0,304(sp)
ffffffffc0203558:	74b2                	ld	s1,296(sp)
ffffffffc020355a:	7912                	ld	s2,288(sp)
ffffffffc020355c:	6131                	addi	sp,sp,320
ffffffffc020355e:	8082                	ret

ffffffffc0203560 <do_exit>:
{
ffffffffc0203560:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n");
ffffffffc0203562:	00002617          	auipc	a2,0x2
ffffffffc0203566:	f8660613          	addi	a2,a2,-122 # ffffffffc02054e8 <etext+0x16e6>
ffffffffc020356a:	14a00593          	li	a1,330
ffffffffc020356e:	00002517          	auipc	a0,0x2
ffffffffc0203572:	f6250513          	addi	a0,a0,-158 # ffffffffc02054d0 <etext+0x16ce>
{
ffffffffc0203576:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n");
ffffffffc0203578:	e8ffc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020357c <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc020357c:	7179                	addi	sp,sp,-48
ffffffffc020357e:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc0203580:	0000a797          	auipc	a5,0xa
ffffffffc0203584:	ed878793          	addi	a5,a5,-296 # ffffffffc020d458 <proc_list>
ffffffffc0203588:	f406                	sd	ra,40(sp)
ffffffffc020358a:	f022                	sd	s0,32(sp)
ffffffffc020358c:	e84a                	sd	s2,16(sp)
ffffffffc020358e:	e44e                	sd	s3,8(sp)
ffffffffc0203590:	00006497          	auipc	s1,0x6
ffffffffc0203594:	ec848493          	addi	s1,s1,-312 # ffffffffc0209458 <hash_list>
ffffffffc0203598:	e79c                	sd	a5,8(a5)
ffffffffc020359a:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc020359c:	0000a717          	auipc	a4,0xa
ffffffffc02035a0:	ebc70713          	addi	a4,a4,-324 # ffffffffc020d458 <proc_list>
ffffffffc02035a4:	87a6                	mv	a5,s1
ffffffffc02035a6:	e79c                	sd	a5,8(a5)
ffffffffc02035a8:	e39c                	sd	a5,0(a5)
ffffffffc02035aa:	07c1                	addi	a5,a5,16
ffffffffc02035ac:	fee79de3          	bne	a5,a4,ffffffffc02035a6 <proc_init+0x2a>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc02035b0:	bf7ff0ef          	jal	ffffffffc02031a6 <alloc_proc>
ffffffffc02035b4:	0000a917          	auipc	s2,0xa
ffffffffc02035b8:	f2c90913          	addi	s2,s2,-212 # ffffffffc020d4e0 <idleproc>
ffffffffc02035bc:	00a93023          	sd	a0,0(s2)
ffffffffc02035c0:	1a050263          	beqz	a0,ffffffffc0203764 <proc_init+0x1e8>
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02035c4:	07000513          	li	a0,112
ffffffffc02035c8:	c6cfe0ef          	jal	ffffffffc0201a34 <kmalloc>
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02035cc:	07000613          	li	a2,112
ffffffffc02035d0:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context));
ffffffffc02035d2:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context));
ffffffffc02035d4:	7e0000ef          	jal	ffffffffc0203db4 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));
ffffffffc02035d8:	00093503          	ld	a0,0(s2)
ffffffffc02035dc:	85a2                	mv	a1,s0
ffffffffc02035de:	07000613          	li	a2,112
ffffffffc02035e2:	03050513          	addi	a0,a0,48
ffffffffc02035e6:	7f8000ef          	jal	ffffffffc0203dde <memcmp>
ffffffffc02035ea:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02035ec:	453d                	li	a0,15
ffffffffc02035ee:	c46fe0ef          	jal	ffffffffc0201a34 <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02035f2:	463d                	li	a2,15
ffffffffc02035f4:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
ffffffffc02035f6:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN);
ffffffffc02035f8:	7bc000ef          	jal	ffffffffc0203db4 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);
ffffffffc02035fc:	00093503          	ld	a0,0(s2)
ffffffffc0203600:	85a2                	mv	a1,s0
ffffffffc0203602:	463d                	li	a2,15
ffffffffc0203604:	0b450513          	addi	a0,a0,180
ffffffffc0203608:	7d6000ef          	jal	ffffffffc0203dde <memcmp>

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc020360c:	00093783          	ld	a5,0(s2)
ffffffffc0203610:	0000a717          	auipc	a4,0xa
ffffffffc0203614:	e9073703          	ld	a4,-368(a4) # ffffffffc020d4a0 <boot_pgdir_pa>
ffffffffc0203618:	77d4                	ld	a3,168(a5)
ffffffffc020361a:	0ee68863          	beq	a3,a4,ffffffffc020370a <proc_init+0x18e>
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc020361e:	4709                	li	a4,2
ffffffffc0203620:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0203622:	00003717          	auipc	a4,0x3
ffffffffc0203626:	9de70713          	addi	a4,a4,-1570 # ffffffffc0206000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020362a:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc020362e:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1;
ffffffffc0203630:	4705                	li	a4,1
ffffffffc0203632:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0203634:	8522                	mv	a0,s0
ffffffffc0203636:	4641                	li	a2,16
ffffffffc0203638:	4581                	li	a1,0
ffffffffc020363a:	77a000ef          	jal	ffffffffc0203db4 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020363e:	8522                	mv	a0,s0
ffffffffc0203640:	463d                	li	a2,15
ffffffffc0203642:	00002597          	auipc	a1,0x2
ffffffffc0203646:	eee58593          	addi	a1,a1,-274 # ffffffffc0205530 <etext+0x172e>
ffffffffc020364a:	77c000ef          	jal	ffffffffc0203dc6 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc020364e:	0000a797          	auipc	a5,0xa
ffffffffc0203652:	e7a7a783          	lw	a5,-390(a5) # ffffffffc020d4c8 <nr_process>

    current = idleproc;
ffffffffc0203656:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020365a:	4601                	li	a2,0
    nr_process++;
ffffffffc020365c:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020365e:	00002597          	auipc	a1,0x2
ffffffffc0203662:	eda58593          	addi	a1,a1,-294 # ffffffffc0205538 <etext+0x1736>
ffffffffc0203666:	00000517          	auipc	a0,0x0
ffffffffc020366a:	bc050513          	addi	a0,a0,-1088 # ffffffffc0203226 <init_main>
    current = idleproc;
ffffffffc020366e:	0000a697          	auipc	a3,0xa
ffffffffc0203672:	e6e6b123          	sd	a4,-414(a3) # ffffffffc020d4d0 <current>
    nr_process++;
ffffffffc0203676:	0000a717          	auipc	a4,0xa
ffffffffc020367a:	e4f72923          	sw	a5,-430(a4) # ffffffffc020d4c8 <nr_process>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020367e:	e93ff0ef          	jal	ffffffffc0203510 <kernel_thread>
ffffffffc0203682:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0203684:	0ea05c63          	blez	a0,ffffffffc020377c <proc_init+0x200>
    if (0 < pid && pid < MAX_PID)
ffffffffc0203688:	6789                	lui	a5,0x2
ffffffffc020368a:	17f9                	addi	a5,a5,-2 # 1ffe <kern_entry-0xffffffffc01fe002>
ffffffffc020368c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0203690:	02e7e463          	bltu	a5,a4,ffffffffc02036b8 <proc_init+0x13c>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0203694:	45a9                	li	a1,10
ffffffffc0203696:	288000ef          	jal	ffffffffc020391e <hash32>
ffffffffc020369a:	02051713          	slli	a4,a0,0x20
ffffffffc020369e:	01c75793          	srli	a5,a4,0x1c
ffffffffc02036a2:	00f486b3          	add	a3,s1,a5
ffffffffc02036a6:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02036a8:	a029                	j	ffffffffc02036b2 <proc_init+0x136>
            if (proc->pid == pid)
ffffffffc02036aa:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02036ae:	0a870863          	beq	a4,s0,ffffffffc020375e <proc_init+0x1e2>
    return listelm->next;
ffffffffc02036b2:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02036b4:	fef69be3          	bne	a3,a5,ffffffffc02036aa <proc_init+0x12e>
    return NULL;
ffffffffc02036b8:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036ba:	0b478413          	addi	s0,a5,180
ffffffffc02036be:	4641                	li	a2,16
ffffffffc02036c0:	4581                	li	a1,0
ffffffffc02036c2:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02036c4:	0000a717          	auipc	a4,0xa
ffffffffc02036c8:	e0f73a23          	sd	a5,-492(a4) # ffffffffc020d4d8 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02036cc:	6e8000ef          	jal	ffffffffc0203db4 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02036d0:	8522                	mv	a0,s0
ffffffffc02036d2:	463d                	li	a2,15
ffffffffc02036d4:	00002597          	auipc	a1,0x2
ffffffffc02036d8:	e9458593          	addi	a1,a1,-364 # ffffffffc0205568 <etext+0x1766>
ffffffffc02036dc:	6ea000ef          	jal	ffffffffc0203dc6 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02036e0:	00093783          	ld	a5,0(s2)
ffffffffc02036e4:	cbe1                	beqz	a5,ffffffffc02037b4 <proc_init+0x238>
ffffffffc02036e6:	43dc                	lw	a5,4(a5)
ffffffffc02036e8:	e7f1                	bnez	a5,ffffffffc02037b4 <proc_init+0x238>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02036ea:	0000a797          	auipc	a5,0xa
ffffffffc02036ee:	dee7b783          	ld	a5,-530(a5) # ffffffffc020d4d8 <initproc>
ffffffffc02036f2:	c3cd                	beqz	a5,ffffffffc0203794 <proc_init+0x218>
ffffffffc02036f4:	43d8                	lw	a4,4(a5)
ffffffffc02036f6:	4785                	li	a5,1
ffffffffc02036f8:	08f71e63          	bne	a4,a5,ffffffffc0203794 <proc_init+0x218>
}
ffffffffc02036fc:	70a2                	ld	ra,40(sp)
ffffffffc02036fe:	7402                	ld	s0,32(sp)
ffffffffc0203700:	64e2                	ld	s1,24(sp)
ffffffffc0203702:	6942                	ld	s2,16(sp)
ffffffffc0203704:	69a2                	ld	s3,8(sp)
ffffffffc0203706:	6145                	addi	sp,sp,48
ffffffffc0203708:	8082                	ret
    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
ffffffffc020370a:	73d8                	ld	a4,160(a5)
ffffffffc020370c:	f00719e3          	bnez	a4,ffffffffc020361e <proc_init+0xa2>
ffffffffc0203710:	f00997e3          	bnez	s3,ffffffffc020361e <proc_init+0xa2>
ffffffffc0203714:	4398                	lw	a4,0(a5)
ffffffffc0203716:	f00714e3          	bnez	a4,ffffffffc020361e <proc_init+0xa2>
ffffffffc020371a:	43d4                	lw	a3,4(a5)
ffffffffc020371c:	577d                	li	a4,-1
ffffffffc020371e:	f0e690e3          	bne	a3,a4,ffffffffc020361e <proc_init+0xa2>
ffffffffc0203722:	4798                	lw	a4,8(a5)
ffffffffc0203724:	ee071de3          	bnez	a4,ffffffffc020361e <proc_init+0xa2>
ffffffffc0203728:	6b98                	ld	a4,16(a5)
ffffffffc020372a:	ee071ae3          	bnez	a4,ffffffffc020361e <proc_init+0xa2>
ffffffffc020372e:	4f98                	lw	a4,24(a5)
ffffffffc0203730:	ee0717e3          	bnez	a4,ffffffffc020361e <proc_init+0xa2>
ffffffffc0203734:	7398                	ld	a4,32(a5)
ffffffffc0203736:	ee0714e3          	bnez	a4,ffffffffc020361e <proc_init+0xa2>
ffffffffc020373a:	7798                	ld	a4,40(a5)
ffffffffc020373c:	ee0711e3          	bnez	a4,ffffffffc020361e <proc_init+0xa2>
ffffffffc0203740:	0b07a703          	lw	a4,176(a5)
ffffffffc0203744:	8f49                	or	a4,a4,a0
ffffffffc0203746:	2701                	sext.w	a4,a4
ffffffffc0203748:	ec071be3          	bnez	a4,ffffffffc020361e <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc020374c:	00002517          	auipc	a0,0x2
ffffffffc0203750:	dcc50513          	addi	a0,a0,-564 # ffffffffc0205518 <etext+0x1716>
ffffffffc0203754:	a41fc0ef          	jal	ffffffffc0200194 <cprintf>
    idleproc->pid = 0;
ffffffffc0203758:	00093783          	ld	a5,0(s2)
ffffffffc020375c:	b5c9                	j	ffffffffc020361e <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020375e:	f2878793          	addi	a5,a5,-216
ffffffffc0203762:	bfa1                	j	ffffffffc02036ba <proc_init+0x13e>
        panic("cannot alloc idleproc.\n");
ffffffffc0203764:	00002617          	auipc	a2,0x2
ffffffffc0203768:	d9c60613          	addi	a2,a2,-612 # ffffffffc0205500 <etext+0x16fe>
ffffffffc020376c:	16500593          	li	a1,357
ffffffffc0203770:	00002517          	auipc	a0,0x2
ffffffffc0203774:	d6050513          	addi	a0,a0,-672 # ffffffffc02054d0 <etext+0x16ce>
ffffffffc0203778:	c8ffc0ef          	jal	ffffffffc0200406 <__panic>
        panic("create init_main failed.\n");
ffffffffc020377c:	00002617          	auipc	a2,0x2
ffffffffc0203780:	dcc60613          	addi	a2,a2,-564 # ffffffffc0205548 <etext+0x1746>
ffffffffc0203784:	18200593          	li	a1,386
ffffffffc0203788:	00002517          	auipc	a0,0x2
ffffffffc020378c:	d4850513          	addi	a0,a0,-696 # ffffffffc02054d0 <etext+0x16ce>
ffffffffc0203790:	c77fc0ef          	jal	ffffffffc0200406 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0203794:	00002697          	auipc	a3,0x2
ffffffffc0203798:	e0468693          	addi	a3,a3,-508 # ffffffffc0205598 <etext+0x1796>
ffffffffc020379c:	00001617          	auipc	a2,0x1
ffffffffc02037a0:	02c60613          	addi	a2,a2,44 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02037a4:	18900593          	li	a1,393
ffffffffc02037a8:	00002517          	auipc	a0,0x2
ffffffffc02037ac:	d2850513          	addi	a0,a0,-728 # ffffffffc02054d0 <etext+0x16ce>
ffffffffc02037b0:	c57fc0ef          	jal	ffffffffc0200406 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02037b4:	00002697          	auipc	a3,0x2
ffffffffc02037b8:	dbc68693          	addi	a3,a3,-580 # ffffffffc0205570 <etext+0x176e>
ffffffffc02037bc:	00001617          	auipc	a2,0x1
ffffffffc02037c0:	00c60613          	addi	a2,a2,12 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc02037c4:	18800593          	li	a1,392
ffffffffc02037c8:	00002517          	auipc	a0,0x2
ffffffffc02037cc:	d0850513          	addi	a0,a0,-760 # ffffffffc02054d0 <etext+0x16ce>
ffffffffc02037d0:	c37fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc02037d4 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02037d4:	1141                	addi	sp,sp,-16
ffffffffc02037d6:	e022                	sd	s0,0(sp)
ffffffffc02037d8:	e406                	sd	ra,8(sp)
ffffffffc02037da:	0000a417          	auipc	s0,0xa
ffffffffc02037de:	cf640413          	addi	s0,s0,-778 # ffffffffc020d4d0 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02037e2:	6018                	ld	a4,0(s0)
ffffffffc02037e4:	4f1c                	lw	a5,24(a4)
ffffffffc02037e6:	dffd                	beqz	a5,ffffffffc02037e4 <cpu_idle+0x10>
        {
            schedule();
ffffffffc02037e8:	0a2000ef          	jal	ffffffffc020388a <schedule>
ffffffffc02037ec:	bfdd                	j	ffffffffc02037e2 <cpu_idle+0xe>

ffffffffc02037ee <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02037ee:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02037f2:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02037f6:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02037f8:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02037fa:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02037fe:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0203802:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0203806:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc020380a:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc020380e:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0203812:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0203816:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020381a:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc020381e:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0203822:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0203826:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020382a:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020382c:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc020382e:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0203832:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0203836:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020383a:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020383e:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0203842:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0203846:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020384a:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020384e:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0203852:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0203856:	8082                	ret

ffffffffc0203858 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203858:	411c                	lw	a5,0(a0)
ffffffffc020385a:	4705                	li	a4,1
ffffffffc020385c:	37f9                	addiw	a5,a5,-2
ffffffffc020385e:	00f77563          	bgeu	a4,a5,ffffffffc0203868 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc0203862:	4789                	li	a5,2
ffffffffc0203864:	c11c                	sw	a5,0(a0)
ffffffffc0203866:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203868:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc020386a:	00002697          	auipc	a3,0x2
ffffffffc020386e:	d5668693          	addi	a3,a3,-682 # ffffffffc02055c0 <etext+0x17be>
ffffffffc0203872:	00001617          	auipc	a2,0x1
ffffffffc0203876:	f5660613          	addi	a2,a2,-170 # ffffffffc02047c8 <etext+0x9c6>
ffffffffc020387a:	45a5                	li	a1,9
ffffffffc020387c:	00002517          	auipc	a0,0x2
ffffffffc0203880:	d8450513          	addi	a0,a0,-636 # ffffffffc0205600 <etext+0x17fe>
wakeup_proc(struct proc_struct *proc) {
ffffffffc0203884:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc0203886:	b81fc0ef          	jal	ffffffffc0200406 <__panic>

ffffffffc020388a <schedule>:
}

void
schedule(void) {
ffffffffc020388a:	1101                	addi	sp,sp,-32
ffffffffc020388c:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020388e:	100027f3          	csrr	a5,sstatus
ffffffffc0203892:	8b89                	andi	a5,a5,2
ffffffffc0203894:	4301                	li	t1,0
ffffffffc0203896:	e3c1                	bnez	a5,ffffffffc0203916 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0203898:	0000a897          	auipc	a7,0xa
ffffffffc020389c:	c388b883          	ld	a7,-968(a7) # ffffffffc020d4d0 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02038a0:	0000a517          	auipc	a0,0xa
ffffffffc02038a4:	c4053503          	ld	a0,-960(a0) # ffffffffc020d4e0 <idleproc>
        current->need_resched = 0;
ffffffffc02038a8:	0008ac23          	sw	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02038ac:	04a88f63          	beq	a7,a0,ffffffffc020390a <schedule+0x80>
ffffffffc02038b0:	0c888693          	addi	a3,a7,200
ffffffffc02038b4:	0000a617          	auipc	a2,0xa
ffffffffc02038b8:	ba460613          	addi	a2,a2,-1116 # ffffffffc020d458 <proc_list>
        le = last;
ffffffffc02038bc:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc02038be:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc02038c0:	4809                	li	a6,2
ffffffffc02038c2:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc02038c4:	00c78863          	beq	a5,a2,ffffffffc02038d4 <schedule+0x4a>
                if (next->state == PROC_RUNNABLE) {
ffffffffc02038c8:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc02038cc:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc02038d0:	03070363          	beq	a4,a6,ffffffffc02038f6 <schedule+0x6c>
                    break;
                }
            }
        } while (le != last);
ffffffffc02038d4:	fef697e3          	bne	a3,a5,ffffffffc02038c2 <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02038d8:	ed99                	bnez	a1,ffffffffc02038f6 <schedule+0x6c>
            next = idleproc;
        }
        next->runs ++;
ffffffffc02038da:	451c                	lw	a5,8(a0)
ffffffffc02038dc:	2785                	addiw	a5,a5,1
ffffffffc02038de:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc02038e0:	00a88663          	beq	a7,a0,ffffffffc02038ec <schedule+0x62>
ffffffffc02038e4:	e41a                	sd	t1,8(sp)
            proc_run(next);
ffffffffc02038e6:	9b1ff0ef          	jal	ffffffffc0203296 <proc_run>
ffffffffc02038ea:	6322                	ld	t1,8(sp)
    if (flag) {
ffffffffc02038ec:	00031b63          	bnez	t1,ffffffffc0203902 <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02038f0:	60e2                	ld	ra,24(sp)
ffffffffc02038f2:	6105                	addi	sp,sp,32
ffffffffc02038f4:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc02038f6:	4198                	lw	a4,0(a1)
ffffffffc02038f8:	4789                	li	a5,2
ffffffffc02038fa:	fef710e3          	bne	a4,a5,ffffffffc02038da <schedule+0x50>
ffffffffc02038fe:	852e                	mv	a0,a1
ffffffffc0203900:	bfe9                	j	ffffffffc02038da <schedule+0x50>
}
ffffffffc0203902:	60e2                	ld	ra,24(sp)
ffffffffc0203904:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203906:	f69fc06f          	j	ffffffffc020086e <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020390a:	0000a617          	auipc	a2,0xa
ffffffffc020390e:	b4e60613          	addi	a2,a2,-1202 # ffffffffc020d458 <proc_list>
ffffffffc0203912:	86b2                	mv	a3,a2
ffffffffc0203914:	b765                	j	ffffffffc02038bc <schedule+0x32>
        intr_disable();
ffffffffc0203916:	f5ffc0ef          	jal	ffffffffc0200874 <intr_disable>
        return 1;
ffffffffc020391a:	4305                	li	t1,1
ffffffffc020391c:	bfb5                	j	ffffffffc0203898 <schedule+0xe>

ffffffffc020391e <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc020391e:	9e3707b7          	lui	a5,0x9e370
ffffffffc0203922:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <kern_entry-0x21e8ffff>
ffffffffc0203924:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc0203928:	02000513          	li	a0,32
ffffffffc020392c:	9d0d                	subw	a0,a0,a1
}
ffffffffc020392e:	00a7d53b          	srlw	a0,a5,a0
ffffffffc0203932:	8082                	ret

ffffffffc0203934 <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203934:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203936:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020393a:	f022                	sd	s0,32(sp)
ffffffffc020393c:	ec26                	sd	s1,24(sp)
ffffffffc020393e:	e84a                	sd	s2,16(sp)
ffffffffc0203940:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203942:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203946:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203948:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020394c:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203950:	84aa                	mv	s1,a0
ffffffffc0203952:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc0203954:	03067d63          	bgeu	a2,a6,ffffffffc020398e <printnum+0x5a>
ffffffffc0203958:	e44e                	sd	s3,8(sp)
ffffffffc020395a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020395c:	4785                	li	a5,1
ffffffffc020395e:	00e7d763          	bge	a5,a4,ffffffffc020396c <printnum+0x38>
            putch(padc, putdat);
ffffffffc0203962:	85ca                	mv	a1,s2
ffffffffc0203964:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0203966:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203968:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020396a:	fc65                	bnez	s0,ffffffffc0203962 <printnum+0x2e>
ffffffffc020396c:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020396e:	00002797          	auipc	a5,0x2
ffffffffc0203972:	caa78793          	addi	a5,a5,-854 # ffffffffc0205618 <etext+0x1816>
ffffffffc0203976:	97d2                	add	a5,a5,s4
}
ffffffffc0203978:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020397a:	0007c503          	lbu	a0,0(a5)
}
ffffffffc020397e:	70a2                	ld	ra,40(sp)
ffffffffc0203980:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203982:	85ca                	mv	a1,s2
ffffffffc0203984:	87a6                	mv	a5,s1
}
ffffffffc0203986:	6942                	ld	s2,16(sp)
ffffffffc0203988:	64e2                	ld	s1,24(sp)
ffffffffc020398a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020398c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020398e:	03065633          	divu	a2,a2,a6
ffffffffc0203992:	8722                	mv	a4,s0
ffffffffc0203994:	fa1ff0ef          	jal	ffffffffc0203934 <printnum>
ffffffffc0203998:	bfd9                	j	ffffffffc020396e <printnum+0x3a>

ffffffffc020399a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020399a:	7119                	addi	sp,sp,-128
ffffffffc020399c:	f4a6                	sd	s1,104(sp)
ffffffffc020399e:	f0ca                	sd	s2,96(sp)
ffffffffc02039a0:	ecce                	sd	s3,88(sp)
ffffffffc02039a2:	e8d2                	sd	s4,80(sp)
ffffffffc02039a4:	e4d6                	sd	s5,72(sp)
ffffffffc02039a6:	e0da                	sd	s6,64(sp)
ffffffffc02039a8:	f862                	sd	s8,48(sp)
ffffffffc02039aa:	fc86                	sd	ra,120(sp)
ffffffffc02039ac:	f8a2                	sd	s0,112(sp)
ffffffffc02039ae:	fc5e                	sd	s7,56(sp)
ffffffffc02039b0:	f466                	sd	s9,40(sp)
ffffffffc02039b2:	f06a                	sd	s10,32(sp)
ffffffffc02039b4:	ec6e                	sd	s11,24(sp)
ffffffffc02039b6:	84aa                	mv	s1,a0
ffffffffc02039b8:	8c32                	mv	s8,a2
ffffffffc02039ba:	8a36                	mv	s4,a3
ffffffffc02039bc:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02039be:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02039c2:	05500b13          	li	s6,85
ffffffffc02039c6:	00002a97          	auipc	s5,0x2
ffffffffc02039ca:	df2a8a93          	addi	s5,s5,-526 # ffffffffc02057b8 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02039ce:	000c4503          	lbu	a0,0(s8)
ffffffffc02039d2:	001c0413          	addi	s0,s8,1
ffffffffc02039d6:	01350a63          	beq	a0,s3,ffffffffc02039ea <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02039da:	cd0d                	beqz	a0,ffffffffc0203a14 <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02039dc:	85ca                	mv	a1,s2
ffffffffc02039de:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02039e0:	00044503          	lbu	a0,0(s0)
ffffffffc02039e4:	0405                	addi	s0,s0,1
ffffffffc02039e6:	ff351ae3          	bne	a0,s3,ffffffffc02039da <vprintfmt+0x40>
        width = precision = -1;
ffffffffc02039ea:	5cfd                	li	s9,-1
ffffffffc02039ec:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc02039ee:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02039f2:	4b81                	li	s7,0
ffffffffc02039f4:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02039f6:	00044683          	lbu	a3,0(s0)
ffffffffc02039fa:	00140c13          	addi	s8,s0,1
ffffffffc02039fe:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0203a02:	0ff5f593          	zext.b	a1,a1
ffffffffc0203a06:	02bb6663          	bltu	s6,a1,ffffffffc0203a32 <vprintfmt+0x98>
ffffffffc0203a0a:	058a                	slli	a1,a1,0x2
ffffffffc0203a0c:	95d6                	add	a1,a1,s5
ffffffffc0203a0e:	4198                	lw	a4,0(a1)
ffffffffc0203a10:	9756                	add	a4,a4,s5
ffffffffc0203a12:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203a14:	70e6                	ld	ra,120(sp)
ffffffffc0203a16:	7446                	ld	s0,112(sp)
ffffffffc0203a18:	74a6                	ld	s1,104(sp)
ffffffffc0203a1a:	7906                	ld	s2,96(sp)
ffffffffc0203a1c:	69e6                	ld	s3,88(sp)
ffffffffc0203a1e:	6a46                	ld	s4,80(sp)
ffffffffc0203a20:	6aa6                	ld	s5,72(sp)
ffffffffc0203a22:	6b06                	ld	s6,64(sp)
ffffffffc0203a24:	7be2                	ld	s7,56(sp)
ffffffffc0203a26:	7c42                	ld	s8,48(sp)
ffffffffc0203a28:	7ca2                	ld	s9,40(sp)
ffffffffc0203a2a:	7d02                	ld	s10,32(sp)
ffffffffc0203a2c:	6de2                	ld	s11,24(sp)
ffffffffc0203a2e:	6109                	addi	sp,sp,128
ffffffffc0203a30:	8082                	ret
            putch('%', putdat);
ffffffffc0203a32:	85ca                	mv	a1,s2
ffffffffc0203a34:	02500513          	li	a0,37
ffffffffc0203a38:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0203a3a:	fff44783          	lbu	a5,-1(s0)
ffffffffc0203a3e:	02500713          	li	a4,37
ffffffffc0203a42:	8c22                	mv	s8,s0
ffffffffc0203a44:	f8e785e3          	beq	a5,a4,ffffffffc02039ce <vprintfmt+0x34>
ffffffffc0203a48:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0203a4c:	1c7d                	addi	s8,s8,-1
ffffffffc0203a4e:	fee79de3          	bne	a5,a4,ffffffffc0203a48 <vprintfmt+0xae>
ffffffffc0203a52:	bfb5                	j	ffffffffc02039ce <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0203a54:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0203a58:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0203a5a:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0203a5e:	fd06071b          	addiw	a4,a2,-48
ffffffffc0203a62:	24e56a63          	bltu	a0,a4,ffffffffc0203cb6 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0203a66:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a68:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0203a6a:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0203a6e:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0203a72:	0197073b          	addw	a4,a4,s9
ffffffffc0203a76:	0017171b          	slliw	a4,a4,0x1
ffffffffc0203a7a:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0203a7c:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0203a80:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0203a82:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0203a86:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0203a8a:	feb570e3          	bgeu	a0,a1,ffffffffc0203a6a <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0203a8e:	f60d54e3          	bgez	s10,ffffffffc02039f6 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0203a92:	8d66                	mv	s10,s9
ffffffffc0203a94:	5cfd                	li	s9,-1
ffffffffc0203a96:	b785                	j	ffffffffc02039f6 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203a98:	8db6                	mv	s11,a3
ffffffffc0203a9a:	8462                	mv	s0,s8
ffffffffc0203a9c:	bfa9                	j	ffffffffc02039f6 <vprintfmt+0x5c>
ffffffffc0203a9e:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0203aa0:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0203aa2:	bf91                	j	ffffffffc02039f6 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0203aa4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203aa6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203aaa:	00f74463          	blt	a4,a5,ffffffffc0203ab2 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0203aae:	1a078763          	beqz	a5,ffffffffc0203c5c <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc0203ab2:	000a3603          	ld	a2,0(s4)
ffffffffc0203ab6:	46c1                	li	a3,16
ffffffffc0203ab8:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0203aba:	000d879b          	sext.w	a5,s11
ffffffffc0203abe:	876a                	mv	a4,s10
ffffffffc0203ac0:	85ca                	mv	a1,s2
ffffffffc0203ac2:	8526                	mv	a0,s1
ffffffffc0203ac4:	e71ff0ef          	jal	ffffffffc0203934 <printnum>
            break;
ffffffffc0203ac8:	b719                	j	ffffffffc02039ce <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0203aca:	000a2503          	lw	a0,0(s4)
ffffffffc0203ace:	85ca                	mv	a1,s2
ffffffffc0203ad0:	0a21                	addi	s4,s4,8
ffffffffc0203ad2:	9482                	jalr	s1
            break;
ffffffffc0203ad4:	bded                	j	ffffffffc02039ce <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203ad6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203ad8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203adc:	00f74463          	blt	a4,a5,ffffffffc0203ae4 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0203ae0:	16078963          	beqz	a5,ffffffffc0203c52 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc0203ae4:	000a3603          	ld	a2,0(s4)
ffffffffc0203ae8:	46a9                	li	a3,10
ffffffffc0203aea:	8a2e                	mv	s4,a1
ffffffffc0203aec:	b7f9                	j	ffffffffc0203aba <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0203aee:	85ca                	mv	a1,s2
ffffffffc0203af0:	03000513          	li	a0,48
ffffffffc0203af4:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0203af6:	85ca                	mv	a1,s2
ffffffffc0203af8:	07800513          	li	a0,120
ffffffffc0203afc:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203afe:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0203b02:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0203b04:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0203b06:	bf55                	j	ffffffffc0203aba <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0203b08:	85ca                	mv	a1,s2
ffffffffc0203b0a:	02500513          	li	a0,37
ffffffffc0203b0e:	9482                	jalr	s1
            break;
ffffffffc0203b10:	bd7d                	j	ffffffffc02039ce <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0203b12:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b16:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0203b18:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0203b1a:	bf95                	j	ffffffffc0203a8e <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0203b1c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203b1e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0203b22:	00f74463          	blt	a4,a5,ffffffffc0203b2a <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0203b26:	12078163          	beqz	a5,ffffffffc0203c48 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0203b2a:	000a3603          	ld	a2,0(s4)
ffffffffc0203b2e:	46a1                	li	a3,8
ffffffffc0203b30:	8a2e                	mv	s4,a1
ffffffffc0203b32:	b761                	j	ffffffffc0203aba <vprintfmt+0x120>
            if (width < 0)
ffffffffc0203b34:	876a                	mv	a4,s10
ffffffffc0203b36:	000d5363          	bgez	s10,ffffffffc0203b3c <vprintfmt+0x1a2>
ffffffffc0203b3a:	4701                	li	a4,0
ffffffffc0203b3c:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203b40:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203b42:	bd55                	j	ffffffffc02039f6 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc0203b44:	000d841b          	sext.w	s0,s11
ffffffffc0203b48:	fd340793          	addi	a5,s0,-45
ffffffffc0203b4c:	00f037b3          	snez	a5,a5
ffffffffc0203b50:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203b54:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0203b58:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203b5a:	008a0793          	addi	a5,s4,8
ffffffffc0203b5e:	e43e                	sd	a5,8(sp)
ffffffffc0203b60:	100d8c63          	beqz	s11,ffffffffc0203c78 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0203b64:	12071363          	bnez	a4,ffffffffc0203c8a <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203b68:	000dc783          	lbu	a5,0(s11)
ffffffffc0203b6c:	0007851b          	sext.w	a0,a5
ffffffffc0203b70:	c78d                	beqz	a5,ffffffffc0203b9a <vprintfmt+0x200>
ffffffffc0203b72:	0d85                	addi	s11,s11,1
ffffffffc0203b74:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203b76:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203b7a:	000cc563          	bltz	s9,ffffffffc0203b84 <vprintfmt+0x1ea>
ffffffffc0203b7e:	3cfd                	addiw	s9,s9,-1
ffffffffc0203b80:	008c8d63          	beq	s9,s0,ffffffffc0203b9a <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203b84:	020b9663          	bnez	s7,ffffffffc0203bb0 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0203b88:	85ca                	mv	a1,s2
ffffffffc0203b8a:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203b8c:	000dc783          	lbu	a5,0(s11)
ffffffffc0203b90:	0d85                	addi	s11,s11,1
ffffffffc0203b92:	3d7d                	addiw	s10,s10,-1
ffffffffc0203b94:	0007851b          	sext.w	a0,a5
ffffffffc0203b98:	f3ed                	bnez	a5,ffffffffc0203b7a <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0203b9a:	01a05963          	blez	s10,ffffffffc0203bac <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0203b9e:	85ca                	mv	a1,s2
ffffffffc0203ba0:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0203ba4:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0203ba6:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0203ba8:	fe0d1be3          	bnez	s10,ffffffffc0203b9e <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203bac:	6a22                	ld	s4,8(sp)
ffffffffc0203bae:	b505                	j	ffffffffc02039ce <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0203bb0:	3781                	addiw	a5,a5,-32
ffffffffc0203bb2:	fcfa7be3          	bgeu	s4,a5,ffffffffc0203b88 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0203bb6:	03f00513          	li	a0,63
ffffffffc0203bba:	85ca                	mv	a1,s2
ffffffffc0203bbc:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203bbe:	000dc783          	lbu	a5,0(s11)
ffffffffc0203bc2:	0d85                	addi	s11,s11,1
ffffffffc0203bc4:	3d7d                	addiw	s10,s10,-1
ffffffffc0203bc6:	0007851b          	sext.w	a0,a5
ffffffffc0203bca:	dbe1                	beqz	a5,ffffffffc0203b9a <vprintfmt+0x200>
ffffffffc0203bcc:	fa0cd9e3          	bgez	s9,ffffffffc0203b7e <vprintfmt+0x1e4>
ffffffffc0203bd0:	b7c5                	j	ffffffffc0203bb0 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc0203bd2:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203bd6:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc0203bd8:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0203bda:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0203bde:	8fb9                	xor	a5,a5,a4
ffffffffc0203be0:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203be4:	02d64563          	blt	a2,a3,ffffffffc0203c0e <vprintfmt+0x274>
ffffffffc0203be8:	00002797          	auipc	a5,0x2
ffffffffc0203bec:	d2878793          	addi	a5,a5,-728 # ffffffffc0205910 <error_string>
ffffffffc0203bf0:	00369713          	slli	a4,a3,0x3
ffffffffc0203bf4:	97ba                	add	a5,a5,a4
ffffffffc0203bf6:	639c                	ld	a5,0(a5)
ffffffffc0203bf8:	cb99                	beqz	a5,ffffffffc0203c0e <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0203bfa:	86be                	mv	a3,a5
ffffffffc0203bfc:	00000617          	auipc	a2,0x0
ffffffffc0203c00:	23460613          	addi	a2,a2,564 # ffffffffc0203e30 <etext+0x2e>
ffffffffc0203c04:	85ca                	mv	a1,s2
ffffffffc0203c06:	8526                	mv	a0,s1
ffffffffc0203c08:	0d8000ef          	jal	ffffffffc0203ce0 <printfmt>
ffffffffc0203c0c:	b3c9                	j	ffffffffc02039ce <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0203c0e:	00002617          	auipc	a2,0x2
ffffffffc0203c12:	a2a60613          	addi	a2,a2,-1494 # ffffffffc0205638 <etext+0x1836>
ffffffffc0203c16:	85ca                	mv	a1,s2
ffffffffc0203c18:	8526                	mv	a0,s1
ffffffffc0203c1a:	0c6000ef          	jal	ffffffffc0203ce0 <printfmt>
ffffffffc0203c1e:	bb45                	j	ffffffffc02039ce <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0203c20:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0203c22:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0203c26:	00f74363          	blt	a4,a5,ffffffffc0203c2c <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0203c2a:	cf81                	beqz	a5,ffffffffc0203c42 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0203c2c:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0203c30:	02044b63          	bltz	s0,ffffffffc0203c66 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0203c34:	8622                	mv	a2,s0
ffffffffc0203c36:	8a5e                	mv	s4,s7
ffffffffc0203c38:	46a9                	li	a3,10
ffffffffc0203c3a:	b541                	j	ffffffffc0203aba <vprintfmt+0x120>
            lflag ++;
ffffffffc0203c3c:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203c3e:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0203c40:	bb5d                	j	ffffffffc02039f6 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0203c42:	000a2403          	lw	s0,0(s4)
ffffffffc0203c46:	b7ed                	j	ffffffffc0203c30 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0203c48:	000a6603          	lwu	a2,0(s4)
ffffffffc0203c4c:	46a1                	li	a3,8
ffffffffc0203c4e:	8a2e                	mv	s4,a1
ffffffffc0203c50:	b5ad                	j	ffffffffc0203aba <vprintfmt+0x120>
ffffffffc0203c52:	000a6603          	lwu	a2,0(s4)
ffffffffc0203c56:	46a9                	li	a3,10
ffffffffc0203c58:	8a2e                	mv	s4,a1
ffffffffc0203c5a:	b585                	j	ffffffffc0203aba <vprintfmt+0x120>
ffffffffc0203c5c:	000a6603          	lwu	a2,0(s4)
ffffffffc0203c60:	46c1                	li	a3,16
ffffffffc0203c62:	8a2e                	mv	s4,a1
ffffffffc0203c64:	bd99                	j	ffffffffc0203aba <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0203c66:	85ca                	mv	a1,s2
ffffffffc0203c68:	02d00513          	li	a0,45
ffffffffc0203c6c:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0203c6e:	40800633          	neg	a2,s0
ffffffffc0203c72:	8a5e                	mv	s4,s7
ffffffffc0203c74:	46a9                	li	a3,10
ffffffffc0203c76:	b591                	j	ffffffffc0203aba <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0203c78:	e329                	bnez	a4,ffffffffc0203cba <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203c7a:	02800793          	li	a5,40
ffffffffc0203c7e:	853e                	mv	a0,a5
ffffffffc0203c80:	00002d97          	auipc	s11,0x2
ffffffffc0203c84:	9b1d8d93          	addi	s11,s11,-1615 # ffffffffc0205631 <etext+0x182f>
ffffffffc0203c88:	b5f5                	j	ffffffffc0203b74 <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203c8a:	85e6                	mv	a1,s9
ffffffffc0203c8c:	856e                	mv	a0,s11
ffffffffc0203c8e:	08a000ef          	jal	ffffffffc0203d18 <strnlen>
ffffffffc0203c92:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0203c96:	01a05863          	blez	s10,ffffffffc0203ca6 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0203c9a:	85ca                	mv	a1,s2
ffffffffc0203c9c:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203c9e:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc0203ca0:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203ca2:	fe0d1ce3          	bnez	s10,ffffffffc0203c9a <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203ca6:	000dc783          	lbu	a5,0(s11)
ffffffffc0203caa:	0007851b          	sext.w	a0,a5
ffffffffc0203cae:	ec0792e3          	bnez	a5,ffffffffc0203b72 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0203cb2:	6a22                	ld	s4,8(sp)
ffffffffc0203cb4:	bb29                	j	ffffffffc02039ce <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203cb6:	8462                	mv	s0,s8
ffffffffc0203cb8:	bbd9                	j	ffffffffc0203a8e <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cba:	85e6                	mv	a1,s9
ffffffffc0203cbc:	00002517          	auipc	a0,0x2
ffffffffc0203cc0:	97450513          	addi	a0,a0,-1676 # ffffffffc0205630 <etext+0x182e>
ffffffffc0203cc4:	054000ef          	jal	ffffffffc0203d18 <strnlen>
ffffffffc0203cc8:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203ccc:	02800793          	li	a5,40
                p = "(null)";
ffffffffc0203cd0:	00002d97          	auipc	s11,0x2
ffffffffc0203cd4:	960d8d93          	addi	s11,s11,-1696 # ffffffffc0205630 <etext+0x182e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0203cd8:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0203cda:	fda040e3          	bgtz	s10,ffffffffc0203c9a <vprintfmt+0x300>
ffffffffc0203cde:	bd51                	j	ffffffffc0203b72 <vprintfmt+0x1d8>

ffffffffc0203ce0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203ce0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0203ce2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203ce6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203ce8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0203cea:	ec06                	sd	ra,24(sp)
ffffffffc0203cec:	f83a                	sd	a4,48(sp)
ffffffffc0203cee:	fc3e                	sd	a5,56(sp)
ffffffffc0203cf0:	e0c2                	sd	a6,64(sp)
ffffffffc0203cf2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0203cf4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0203cf6:	ca5ff0ef          	jal	ffffffffc020399a <vprintfmt>
}
ffffffffc0203cfa:	60e2                	ld	ra,24(sp)
ffffffffc0203cfc:	6161                	addi	sp,sp,80
ffffffffc0203cfe:	8082                	ret

ffffffffc0203d00 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203d00:	00054783          	lbu	a5,0(a0)
ffffffffc0203d04:	cb81                	beqz	a5,ffffffffc0203d14 <strlen+0x14>
    size_t cnt = 0;
ffffffffc0203d06:	4781                	li	a5,0
        cnt ++;
ffffffffc0203d08:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0203d0a:	00f50733          	add	a4,a0,a5
ffffffffc0203d0e:	00074703          	lbu	a4,0(a4)
ffffffffc0203d12:	fb7d                	bnez	a4,ffffffffc0203d08 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0203d14:	853e                	mv	a0,a5
ffffffffc0203d16:	8082                	ret

ffffffffc0203d18 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203d18:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203d1a:	e589                	bnez	a1,ffffffffc0203d24 <strnlen+0xc>
ffffffffc0203d1c:	a811                	j	ffffffffc0203d30 <strnlen+0x18>
        cnt ++;
ffffffffc0203d1e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203d20:	00f58863          	beq	a1,a5,ffffffffc0203d30 <strnlen+0x18>
ffffffffc0203d24:	00f50733          	add	a4,a0,a5
ffffffffc0203d28:	00074703          	lbu	a4,0(a4)
ffffffffc0203d2c:	fb6d                	bnez	a4,ffffffffc0203d1e <strnlen+0x6>
ffffffffc0203d2e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203d30:	852e                	mv	a0,a1
ffffffffc0203d32:	8082                	ret

ffffffffc0203d34 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203d34:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203d36:	0005c703          	lbu	a4,0(a1)
ffffffffc0203d3a:	0585                	addi	a1,a1,1
ffffffffc0203d3c:	0785                	addi	a5,a5,1
ffffffffc0203d3e:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203d42:	fb75                	bnez	a4,ffffffffc0203d36 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203d44:	8082                	ret

ffffffffc0203d46 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203d46:	00054783          	lbu	a5,0(a0)
ffffffffc0203d4a:	e791                	bnez	a5,ffffffffc0203d56 <strcmp+0x10>
ffffffffc0203d4c:	a01d                	j	ffffffffc0203d72 <strcmp+0x2c>
ffffffffc0203d4e:	00054783          	lbu	a5,0(a0)
ffffffffc0203d52:	cb99                	beqz	a5,ffffffffc0203d68 <strcmp+0x22>
ffffffffc0203d54:	0585                	addi	a1,a1,1
ffffffffc0203d56:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0203d5a:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203d5c:	fef709e3          	beq	a4,a5,ffffffffc0203d4e <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203d60:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203d64:	9d19                	subw	a0,a0,a4
ffffffffc0203d66:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203d68:	0015c703          	lbu	a4,1(a1)
ffffffffc0203d6c:	4501                	li	a0,0
}
ffffffffc0203d6e:	9d19                	subw	a0,a0,a4
ffffffffc0203d70:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203d72:	0005c703          	lbu	a4,0(a1)
ffffffffc0203d76:	4501                	li	a0,0
ffffffffc0203d78:	b7f5                	j	ffffffffc0203d64 <strcmp+0x1e>

ffffffffc0203d7a <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203d7a:	ce01                	beqz	a2,ffffffffc0203d92 <strncmp+0x18>
ffffffffc0203d7c:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0203d80:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203d82:	cb91                	beqz	a5,ffffffffc0203d96 <strncmp+0x1c>
ffffffffc0203d84:	0005c703          	lbu	a4,0(a1)
ffffffffc0203d88:	00f71763          	bne	a4,a5,ffffffffc0203d96 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0203d8c:	0505                	addi	a0,a0,1
ffffffffc0203d8e:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0203d90:	f675                	bnez	a2,ffffffffc0203d7c <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203d92:	4501                	li	a0,0
ffffffffc0203d94:	8082                	ret
ffffffffc0203d96:	00054503          	lbu	a0,0(a0)
ffffffffc0203d9a:	0005c783          	lbu	a5,0(a1)
ffffffffc0203d9e:	9d1d                	subw	a0,a0,a5
}
ffffffffc0203da0:	8082                	ret

ffffffffc0203da2 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203da2:	a021                	j	ffffffffc0203daa <strchr+0x8>
        if (*s == c) {
ffffffffc0203da4:	00f58763          	beq	a1,a5,ffffffffc0203db2 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0203da8:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203daa:	00054783          	lbu	a5,0(a0)
ffffffffc0203dae:	fbfd                	bnez	a5,ffffffffc0203da4 <strchr+0x2>
    }
    return NULL;
ffffffffc0203db0:	4501                	li	a0,0
}
ffffffffc0203db2:	8082                	ret

ffffffffc0203db4 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203db4:	ca01                	beqz	a2,ffffffffc0203dc4 <memset+0x10>
ffffffffc0203db6:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203db8:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203dba:	0785                	addi	a5,a5,1
ffffffffc0203dbc:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203dc0:	fef61de3          	bne	a2,a5,ffffffffc0203dba <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203dc4:	8082                	ret

ffffffffc0203dc6 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203dc6:	ca19                	beqz	a2,ffffffffc0203ddc <memcpy+0x16>
ffffffffc0203dc8:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203dca:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203dcc:	0005c703          	lbu	a4,0(a1)
ffffffffc0203dd0:	0585                	addi	a1,a1,1
ffffffffc0203dd2:	0785                	addi	a5,a5,1
ffffffffc0203dd4:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203dd8:	feb61ae3          	bne	a2,a1,ffffffffc0203dcc <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203ddc:	8082                	ret

ffffffffc0203dde <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0203dde:	c205                	beqz	a2,ffffffffc0203dfe <memcmp+0x20>
ffffffffc0203de0:	962a                	add	a2,a2,a0
ffffffffc0203de2:	a019                	j	ffffffffc0203de8 <memcmp+0xa>
ffffffffc0203de4:	00c50d63          	beq	a0,a2,ffffffffc0203dfe <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0203de8:	00054783          	lbu	a5,0(a0)
ffffffffc0203dec:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0203df0:	0505                	addi	a0,a0,1
ffffffffc0203df2:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0203df4:	fee788e3          	beq	a5,a4,ffffffffc0203de4 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203df8:	40e7853b          	subw	a0,a5,a4
ffffffffc0203dfc:	8082                	ret
    }
    return 0;
ffffffffc0203dfe:	4501                	li	a0,0
}
ffffffffc0203e00:	8082                	ret
