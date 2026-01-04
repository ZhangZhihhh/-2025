
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    # a0 = hartid, a1 = dtb (from OpenSBI)
    # We need to save these before enabling paging
    # Compute physical address of boot_hartid
    # Method: get link VA, subtract 0xFFFFFFFF40000000
    
    lui t0, %hi(boot_hartid)
ffffffffc0200000:	c02b52b7          	lui	t0,0xc02b5
    addi t0, t0, %lo(boot_hartid)
ffffffffc0200004:	58028293          	addi	t0,t0,1408 # ffffffffc02b5580 <boot_hartid>
    li t1, 0x40000000
ffffffffc0200008:	40000337          	lui	t1,0x40000
    li t2, -1
ffffffffc020000c:	53fd                	li	t2,-1
    slli t2, t2, 32
ffffffffc020000e:	1382                	slli	t2,t2,0x20
    add t1, t1, t2          # t1 = 0xFFFFFFFF40000000
ffffffffc0200010:	931e                	add	t1,t1,t2
    sub t0, t0, t1          # t0 = PA of boot_hartid
ffffffffc0200012:	406282b3          	sub	t0,t0,t1
    sd a0, 0(t0)            # Save hartid
ffffffffc0200016:	00a2b023          	sd	a0,0(t0)
    
    # Save dtb - also use physical address
    lui t0, %hi(boot_dtb)
ffffffffc020001a:	c02b52b7          	lui	t0,0xc02b5
    addi t0, t0, %lo(boot_dtb)
ffffffffc020001e:	58828293          	addi	t0,t0,1416 # ffffffffc02b5588 <boot_dtb>
    li t1, 0x40000000
ffffffffc0200022:	40000337          	lui	t1,0x40000
    li t2, -1
ffffffffc0200026:	53fd                	li	t2,-1
    slli t2, t2, 32
ffffffffc0200028:	1382                	slli	t2,t2,0x20
    add t1, t1, t2          # t1 = 0xFFFFFFFF40000000
ffffffffc020002a:	931e                	add	t1,t1,t2
    sub t0, t0, t1          # t0 = PA of boot_dtb
ffffffffc020002c:	406282b3          	sub	t0,t0,t1
    sd a1, 0(t0)            # Save dtb
ffffffffc0200030:	00b2b023          	sd	a1,0(t0)
    
    # Now set up paging
    # Compute PA of boot_page_table_sv39
    lui t0, %hi(boot_page_table_sv39)
ffffffffc0200034:	c020b2b7          	lui	t0,0xc020b
    addi t0, t0, %lo(boot_page_table_sv39)
ffffffffc0200038:	00028293          	mv	t0,t0
    sub t0, t0, t1          # t0 = PA of page table
ffffffffc020003c:	406282b3          	sub	t0,t0,t1
    
    # Set up satp
    srli t0, t0, 12         # PPN  
ffffffffc0200040:	00c2d293          	srli	t0,t0,0xc
    li t1, 8
ffffffffc0200044:	4321                	li	t1,8
    slli t1, t1, 60         # Sv39 mode
ffffffffc0200046:	1372                	slli	t1,t1,0x3c
    or t0, t0, t1
ffffffffc0200048:	0062e2b3          	or	t0,t0,t1
    csrw satp, t0
ffffffffc020004c:	18029073          	csrw	satp,t0
    sfence.vma
ffffffffc0200050:	12000073          	sfence.vma
    # After enabling paging, PC is still at physical ~0x80200xxx
    # This is OK because VPN[2]=2 provides identity mapping
    
    # Now jump to virtual address
    # Use absolute load to ensure correct address
    la t0, va_start
ffffffffc0200054:	00000297          	auipc	t0,0x0
ffffffffc0200058:	00c28293          	addi	t0,t0,12 # ffffffffc0200060 <va_start>
    jr t0
ffffffffc020005c:	8282                	jr	t0
ffffffffc020005e:	0001                	nop

ffffffffc0200060 <va_start>:

.align 2
va_start:
    # Now at virtual address space
    la sp, bootstacktop
ffffffffc0200060:	0000b117          	auipc	sp,0xb
ffffffffc0200064:	fa010113          	addi	sp,sp,-96 # ffffffffc020b000 <boot_page_table_sv39>
    tail kern_init
ffffffffc0200068:	a009                	j	ffffffffc020006a <kern_init>

ffffffffc020006a <kern_init>:

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);

int kern_init(void)
{
ffffffffc020006a:	1101                	addi	sp,sp,-32
ffffffffc020006c:	e822                	sd	s0,16(sp)
ffffffffc020006e:	e426                	sd	s1,8(sp)
    extern uint64_t boot_hartid, boot_dtb;
    // Save boot parameters before memset clears BSS
    uint64_t saved_hartid = boot_hartid;
    uint64_t saved_dtb = boot_dtb;
ffffffffc0200070:	000b5417          	auipc	s0,0xb5
ffffffffc0200074:	51843403          	ld	s0,1304(s0) # ffffffffc02b5588 <boot_dtb>
    uint64_t saved_hartid = boot_hartid;
ffffffffc0200078:	000b5497          	auipc	s1,0xb5
ffffffffc020007c:	5084b483          	ld	s1,1288(s1) # ffffffffc02b5580 <boot_hartid>
    
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200080:	000b1517          	auipc	a0,0xb1
ffffffffc0200084:	01850513          	addi	a0,a0,24 # ffffffffc02b1098 <buf>
ffffffffc0200088:	000b5617          	auipc	a2,0xb5
ffffffffc020008c:	4f860613          	addi	a2,a2,1272 # ffffffffc02b5580 <boot_hartid>
ffffffffc0200090:	8e09                	sub	a2,a2,a0
ffffffffc0200092:	4581                	li	a1,0
{
ffffffffc0200094:	ec06                	sd	ra,24(sp)
    memset(edata, 0, end - edata);
ffffffffc0200096:	245050ef          	jal	ffffffffc0205ada <memset>
    
    // Restore boot parameters
    boot_hartid = saved_hartid;
ffffffffc020009a:	000b5797          	auipc	a5,0xb5
ffffffffc020009e:	4e97b323          	sd	s1,1254(a5) # ffffffffc02b5580 <boot_hartid>
    boot_dtb = saved_dtb;
ffffffffc02000a2:	000b5797          	auipc	a5,0xb5
ffffffffc02000a6:	4e87b323          	sd	s0,1254(a5) # ffffffffc02b5588 <boot_dtb>
    
    cons_init(); // init the console
ffffffffc02000aa:	4da000ef          	jal	ffffffffc0200584 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc02000ae:	00006597          	auipc	a1,0x6
ffffffffc02000b2:	a5a58593          	addi	a1,a1,-1446 # ffffffffc0205b08 <etext+0x4>
ffffffffc02000b6:	00006517          	auipc	a0,0x6
ffffffffc02000ba:	a7250513          	addi	a0,a0,-1422 # ffffffffc0205b28 <etext+0x24>
ffffffffc02000be:	11e000ef          	jal	ffffffffc02001dc <cprintf>

    print_kerninfo();
ffffffffc02000c2:	1ac000ef          	jal	ffffffffc020026e <print_kerninfo>

    // grade_backtrace();

    dtb_init(); // init dtb
ffffffffc02000c6:	530000ef          	jal	ffffffffc02005f6 <dtb_init>

    pmm_init(); // init physical memory management
ffffffffc02000ca:	6f8020ef          	jal	ffffffffc02027c2 <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc02000ce:	135000ef          	jal	ffffffffc0200a02 <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc02000d2:	133000ef          	jal	ffffffffc0200a04 <idt_init>

    vmm_init(); // init virtual memory management
ffffffffc02000d6:	1db030ef          	jal	ffffffffc0203ab0 <vmm_init>
    sched_init();
ffffffffc02000da:	26c050ef          	jal	ffffffffc0205346 <sched_init>
    proc_init(); // init process table
ffffffffc02000de:	709040ef          	jal	ffffffffc0204fe6 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc02000e2:	45a000ef          	jal	ffffffffc020053c <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc02000e6:	111000ef          	jal	ffffffffc02009f6 <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000ea:	09c050ef          	jal	ffffffffc0205186 <cpu_idle>

ffffffffc02000ee <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000ee:	7179                	addi	sp,sp,-48
ffffffffc02000f0:	f406                	sd	ra,40(sp)
ffffffffc02000f2:	f022                	sd	s0,32(sp)
ffffffffc02000f4:	ec26                	sd	s1,24(sp)
ffffffffc02000f6:	e84a                	sd	s2,16(sp)
ffffffffc02000f8:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000fa:	c901                	beqz	a0,ffffffffc020010a <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000fc:	85aa                	mv	a1,a0
ffffffffc02000fe:	00006517          	auipc	a0,0x6
ffffffffc0200102:	a3250513          	addi	a0,a0,-1486 # ffffffffc0205b30 <etext+0x2c>
ffffffffc0200106:	0d6000ef          	jal	ffffffffc02001dc <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc020010a:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020010c:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc020010e:	000b1997          	auipc	s3,0xb1
ffffffffc0200112:	f8a98993          	addi	s3,s3,-118 # ffffffffc02b1098 <buf>
        c = getchar();
ffffffffc0200116:	148000ef          	jal	ffffffffc020025e <getchar>
ffffffffc020011a:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc020011c:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200120:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0200124:	ff650693          	addi	a3,a0,-10
ffffffffc0200128:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc020012c:	02054963          	bltz	a0,ffffffffc020015e <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200130:	02a95f63          	bge	s2,a0,ffffffffc020016e <readline+0x80>
ffffffffc0200134:	cf0d                	beqz	a4,ffffffffc020016e <readline+0x80>
            cputchar(c);
ffffffffc0200136:	0da000ef          	jal	ffffffffc0200210 <cputchar>
            buf[i ++] = c;
ffffffffc020013a:	009987b3          	add	a5,s3,s1
ffffffffc020013e:	00878023          	sb	s0,0(a5)
ffffffffc0200142:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc0200144:	11a000ef          	jal	ffffffffc020025e <getchar>
ffffffffc0200148:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc020014a:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020014e:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc0200152:	ff650693          	addi	a3,a0,-10
ffffffffc0200156:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc020015a:	fc055be3          	bgez	a0,ffffffffc0200130 <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc020015e:	70a2                	ld	ra,40(sp)
ffffffffc0200160:	7402                	ld	s0,32(sp)
ffffffffc0200162:	64e2                	ld	s1,24(sp)
ffffffffc0200164:	6942                	ld	s2,16(sp)
ffffffffc0200166:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200168:	4501                	li	a0,0
}
ffffffffc020016a:	6145                	addi	sp,sp,48
ffffffffc020016c:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc020016e:	eb81                	bnez	a5,ffffffffc020017e <readline+0x90>
            cputchar(c);
ffffffffc0200170:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc0200172:	00905663          	blez	s1,ffffffffc020017e <readline+0x90>
            cputchar(c);
ffffffffc0200176:	09a000ef          	jal	ffffffffc0200210 <cputchar>
            i --;
ffffffffc020017a:	34fd                	addiw	s1,s1,-1
ffffffffc020017c:	bf69                	j	ffffffffc0200116 <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc020017e:	c291                	beqz	a3,ffffffffc0200182 <readline+0x94>
ffffffffc0200180:	fa59                	bnez	a2,ffffffffc0200116 <readline+0x28>
            cputchar(c);
ffffffffc0200182:	8522                	mv	a0,s0
ffffffffc0200184:	08c000ef          	jal	ffffffffc0200210 <cputchar>
            buf[i] = '\0';
ffffffffc0200188:	000b1517          	auipc	a0,0xb1
ffffffffc020018c:	f1050513          	addi	a0,a0,-240 # ffffffffc02b1098 <buf>
ffffffffc0200190:	94aa                	add	s1,s1,a0
ffffffffc0200192:	00048023          	sb	zero,0(s1)
}
ffffffffc0200196:	70a2                	ld	ra,40(sp)
ffffffffc0200198:	7402                	ld	s0,32(sp)
ffffffffc020019a:	64e2                	ld	s1,24(sp)
ffffffffc020019c:	6942                	ld	s2,16(sp)
ffffffffc020019e:	69a2                	ld	s3,8(sp)
ffffffffc02001a0:	6145                	addi	sp,sp,48
ffffffffc02001a2:	8082                	ret

ffffffffc02001a4 <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc02001a4:	1101                	addi	sp,sp,-32
ffffffffc02001a6:	ec06                	sd	ra,24(sp)
ffffffffc02001a8:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc02001aa:	3dc000ef          	jal	ffffffffc0200586 <cons_putc>
    (*cnt)++;
ffffffffc02001ae:	65a2                	ld	a1,8(sp)
}
ffffffffc02001b0:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc02001b2:	419c                	lw	a5,0(a1)
ffffffffc02001b4:	2785                	addiw	a5,a5,1
ffffffffc02001b6:	c19c                	sw	a5,0(a1)
}
ffffffffc02001b8:	6105                	addi	sp,sp,32
ffffffffc02001ba:	8082                	ret

ffffffffc02001bc <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc02001bc:	1101                	addi	sp,sp,-32
ffffffffc02001be:	862a                	mv	a2,a0
ffffffffc02001c0:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001c2:	00000517          	auipc	a0,0x0
ffffffffc02001c6:	fe250513          	addi	a0,a0,-30 # ffffffffc02001a4 <cputch>
ffffffffc02001ca:	006c                	addi	a1,sp,12
{
ffffffffc02001cc:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02001ce:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001d0:	4f0050ef          	jal	ffffffffc02056c0 <vprintfmt>
    return cnt;
}
ffffffffc02001d4:	60e2                	ld	ra,24(sp)
ffffffffc02001d6:	4532                	lw	a0,12(sp)
ffffffffc02001d8:	6105                	addi	sp,sp,32
ffffffffc02001da:	8082                	ret

ffffffffc02001dc <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc02001dc:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02001de:	02810313          	addi	t1,sp,40
{
ffffffffc02001e2:	f42e                	sd	a1,40(sp)
ffffffffc02001e4:	f832                	sd	a2,48(sp)
ffffffffc02001e6:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001e8:	862a                	mv	a2,a0
ffffffffc02001ea:	004c                	addi	a1,sp,4
ffffffffc02001ec:	00000517          	auipc	a0,0x0
ffffffffc02001f0:	fb850513          	addi	a0,a0,-72 # ffffffffc02001a4 <cputch>
ffffffffc02001f4:	869a                	mv	a3,t1
{
ffffffffc02001f6:	ec06                	sd	ra,24(sp)
ffffffffc02001f8:	e0ba                	sd	a4,64(sp)
ffffffffc02001fa:	e4be                	sd	a5,72(sp)
ffffffffc02001fc:	e8c2                	sd	a6,80(sp)
ffffffffc02001fe:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc0200200:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc0200202:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200204:	4bc050ef          	jal	ffffffffc02056c0 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200208:	60e2                	ld	ra,24(sp)
ffffffffc020020a:	4512                	lw	a0,4(sp)
ffffffffc020020c:	6125                	addi	sp,sp,96
ffffffffc020020e:	8082                	ret

ffffffffc0200210 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc0200210:	ae9d                	j	ffffffffc0200586 <cons_putc>

ffffffffc0200212 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc0200212:	1101                	addi	sp,sp,-32
ffffffffc0200214:	e822                	sd	s0,16(sp)
ffffffffc0200216:	ec06                	sd	ra,24(sp)
ffffffffc0200218:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc020021a:	00054503          	lbu	a0,0(a0)
ffffffffc020021e:	c51d                	beqz	a0,ffffffffc020024c <cputs+0x3a>
ffffffffc0200220:	e426                	sd	s1,8(sp)
ffffffffc0200222:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc0200224:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200226:	360000ef          	jal	ffffffffc0200586 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc020022a:	00044503          	lbu	a0,0(s0)
ffffffffc020022e:	0405                	addi	s0,s0,1
ffffffffc0200230:	87a6                	mv	a5,s1
    (*cnt)++;
ffffffffc0200232:	2485                	addiw	s1,s1,1
    while ((c = *str++) != '\0')
ffffffffc0200234:	f96d                	bnez	a0,ffffffffc0200226 <cputs+0x14>
    cons_putc(c);
ffffffffc0200236:	4529                	li	a0,10
    (*cnt)++;
ffffffffc0200238:	0027841b          	addiw	s0,a5,2
ffffffffc020023c:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc020023e:	348000ef          	jal	ffffffffc0200586 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200242:	60e2                	ld	ra,24(sp)
ffffffffc0200244:	8522                	mv	a0,s0
ffffffffc0200246:	6442                	ld	s0,16(sp)
ffffffffc0200248:	6105                	addi	sp,sp,32
ffffffffc020024a:	8082                	ret
    cons_putc(c);
ffffffffc020024c:	4529                	li	a0,10
ffffffffc020024e:	338000ef          	jal	ffffffffc0200586 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc0200252:	4405                	li	s0,1
}
ffffffffc0200254:	60e2                	ld	ra,24(sp)
ffffffffc0200256:	8522                	mv	a0,s0
ffffffffc0200258:	6442                	ld	s0,16(sp)
ffffffffc020025a:	6105                	addi	sp,sp,32
ffffffffc020025c:	8082                	ret

ffffffffc020025e <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc020025e:	1141                	addi	sp,sp,-16
ffffffffc0200260:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200262:	358000ef          	jal	ffffffffc02005ba <cons_getc>
ffffffffc0200266:	dd75                	beqz	a0,ffffffffc0200262 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200268:	60a2                	ld	ra,8(sp)
ffffffffc020026a:	0141                	addi	sp,sp,16
ffffffffc020026c:	8082                	ret

ffffffffc020026e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020026e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200270:	00006517          	auipc	a0,0x6
ffffffffc0200274:	8c850513          	addi	a0,a0,-1848 # ffffffffc0205b38 <etext+0x34>
void print_kerninfo(void) {
ffffffffc0200278:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020027a:	f63ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020027e:	00000597          	auipc	a1,0x0
ffffffffc0200282:	dec58593          	addi	a1,a1,-532 # ffffffffc020006a <kern_init>
ffffffffc0200286:	00006517          	auipc	a0,0x6
ffffffffc020028a:	8d250513          	addi	a0,a0,-1838 # ffffffffc0205b58 <etext+0x54>
ffffffffc020028e:	f4fff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200292:	00006597          	auipc	a1,0x6
ffffffffc0200296:	87258593          	addi	a1,a1,-1934 # ffffffffc0205b04 <etext>
ffffffffc020029a:	00006517          	auipc	a0,0x6
ffffffffc020029e:	8de50513          	addi	a0,a0,-1826 # ffffffffc0205b78 <etext+0x74>
ffffffffc02002a2:	f3bff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc02002a6:	000b1597          	auipc	a1,0xb1
ffffffffc02002aa:	df258593          	addi	a1,a1,-526 # ffffffffc02b1098 <buf>
ffffffffc02002ae:	00006517          	auipc	a0,0x6
ffffffffc02002b2:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0205b98 <etext+0x94>
ffffffffc02002b6:	f27ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc02002ba:	000b5597          	auipc	a1,0xb5
ffffffffc02002be:	2c658593          	addi	a1,a1,710 # ffffffffc02b5580 <boot_hartid>
ffffffffc02002c2:	00006517          	auipc	a0,0x6
ffffffffc02002c6:	8f650513          	addi	a0,a0,-1802 # ffffffffc0205bb8 <etext+0xb4>
ffffffffc02002ca:	f13ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02002ce:	00000717          	auipc	a4,0x0
ffffffffc02002d2:	d9c70713          	addi	a4,a4,-612 # ffffffffc020006a <kern_init>
ffffffffc02002d6:	000b5797          	auipc	a5,0xb5
ffffffffc02002da:	6a978793          	addi	a5,a5,1705 # ffffffffc02b597f <boot_dtb+0x3f7>
ffffffffc02002de:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002e0:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02002e4:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002e6:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002ea:	95be                	add	a1,a1,a5
ffffffffc02002ec:	85a9                	srai	a1,a1,0xa
ffffffffc02002ee:	00006517          	auipc	a0,0x6
ffffffffc02002f2:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0205bd8 <etext+0xd4>
}
ffffffffc02002f6:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002f8:	b5d5                	j	ffffffffc02001dc <cprintf>

ffffffffc02002fa <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002fa:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002fc:	00006617          	auipc	a2,0x6
ffffffffc0200300:	90c60613          	addi	a2,a2,-1780 # ffffffffc0205c08 <etext+0x104>
ffffffffc0200304:	04d00593          	li	a1,77
ffffffffc0200308:	00006517          	auipc	a0,0x6
ffffffffc020030c:	91850513          	addi	a0,a0,-1768 # ffffffffc0205c20 <etext+0x11c>
void print_stackframe(void) {
ffffffffc0200310:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200312:	17c000ef          	jal	ffffffffc020048e <__panic>

ffffffffc0200316 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200316:	1101                	addi	sp,sp,-32
ffffffffc0200318:	e822                	sd	s0,16(sp)
ffffffffc020031a:	e426                	sd	s1,8(sp)
ffffffffc020031c:	ec06                	sd	ra,24(sp)
ffffffffc020031e:	00007417          	auipc	s0,0x7
ffffffffc0200322:	6b240413          	addi	s0,s0,1714 # ffffffffc02079d0 <commands>
ffffffffc0200326:	00007497          	auipc	s1,0x7
ffffffffc020032a:	6f248493          	addi	s1,s1,1778 # ffffffffc0207a18 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020032e:	6410                	ld	a2,8(s0)
ffffffffc0200330:	600c                	ld	a1,0(s0)
ffffffffc0200332:	00006517          	auipc	a0,0x6
ffffffffc0200336:	90650513          	addi	a0,a0,-1786 # ffffffffc0205c38 <etext+0x134>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020033a:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020033c:	ea1ff0ef          	jal	ffffffffc02001dc <cprintf>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200340:	fe9417e3          	bne	s0,s1,ffffffffc020032e <mon_help+0x18>
    }
    return 0;
}
ffffffffc0200344:	60e2                	ld	ra,24(sp)
ffffffffc0200346:	6442                	ld	s0,16(sp)
ffffffffc0200348:	64a2                	ld	s1,8(sp)
ffffffffc020034a:	4501                	li	a0,0
ffffffffc020034c:	6105                	addi	sp,sp,32
ffffffffc020034e:	8082                	ret

ffffffffc0200350 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200350:	1141                	addi	sp,sp,-16
ffffffffc0200352:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200354:	f1bff0ef          	jal	ffffffffc020026e <print_kerninfo>
    return 0;
}
ffffffffc0200358:	60a2                	ld	ra,8(sp)
ffffffffc020035a:	4501                	li	a0,0
ffffffffc020035c:	0141                	addi	sp,sp,16
ffffffffc020035e:	8082                	ret

ffffffffc0200360 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200360:	1141                	addi	sp,sp,-16
ffffffffc0200362:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200364:	f97ff0ef          	jal	ffffffffc02002fa <print_stackframe>
    return 0;
}
ffffffffc0200368:	60a2                	ld	ra,8(sp)
ffffffffc020036a:	4501                	li	a0,0
ffffffffc020036c:	0141                	addi	sp,sp,16
ffffffffc020036e:	8082                	ret

ffffffffc0200370 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200370:	7131                	addi	sp,sp,-192
ffffffffc0200372:	e952                	sd	s4,144(sp)
ffffffffc0200374:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200376:	00006517          	auipc	a0,0x6
ffffffffc020037a:	8d250513          	addi	a0,a0,-1838 # ffffffffc0205c48 <etext+0x144>
kmonitor(struct trapframe *tf) {
ffffffffc020037e:	fd06                	sd	ra,184(sp)
ffffffffc0200380:	f922                	sd	s0,176(sp)
ffffffffc0200382:	f526                	sd	s1,168(sp)
ffffffffc0200384:	ed4e                	sd	s3,152(sp)
ffffffffc0200386:	e556                	sd	s5,136(sp)
ffffffffc0200388:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020038a:	e53ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020038e:	00006517          	auipc	a0,0x6
ffffffffc0200392:	8e250513          	addi	a0,a0,-1822 # ffffffffc0205c70 <etext+0x16c>
ffffffffc0200396:	e47ff0ef          	jal	ffffffffc02001dc <cprintf>
    if (tf != NULL) {
ffffffffc020039a:	000a0563          	beqz	s4,ffffffffc02003a4 <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc020039e:	8552                	mv	a0,s4
ffffffffc02003a0:	04d000ef          	jal	ffffffffc0200bec <print_trapframe>
ffffffffc02003a4:	00007a97          	auipc	s5,0x7
ffffffffc02003a8:	62ca8a93          	addi	s5,s5,1580 # ffffffffc02079d0 <commands>
        if (argc == MAXARGS - 1) {
ffffffffc02003ac:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003ae:	00006517          	auipc	a0,0x6
ffffffffc02003b2:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0205c98 <etext+0x194>
ffffffffc02003b6:	d39ff0ef          	jal	ffffffffc02000ee <readline>
ffffffffc02003ba:	842a                	mv	s0,a0
ffffffffc02003bc:	d96d                	beqz	a0,ffffffffc02003ae <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003be:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003c2:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003c4:	e99d                	bnez	a1,ffffffffc02003fa <kmonitor+0x8a>
    int argc = 0;
ffffffffc02003c6:	8b26                	mv	s6,s1
    if (argc == 0) {
ffffffffc02003c8:	fe0b03e3          	beqz	s6,ffffffffc02003ae <kmonitor+0x3e>
ffffffffc02003cc:	00007497          	auipc	s1,0x7
ffffffffc02003d0:	60448493          	addi	s1,s1,1540 # ffffffffc02079d0 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003d4:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003d6:	6582                	ld	a1,0(sp)
ffffffffc02003d8:	6088                	ld	a0,0(s1)
ffffffffc02003da:	692050ef          	jal	ffffffffc0205a6c <strcmp>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003de:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003e0:	c149                	beqz	a0,ffffffffc0200462 <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e2:	2405                	addiw	s0,s0,1
ffffffffc02003e4:	04e1                	addi	s1,s1,24
ffffffffc02003e6:	fef418e3          	bne	s0,a5,ffffffffc02003d6 <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003ea:	6582                	ld	a1,0(sp)
ffffffffc02003ec:	00006517          	auipc	a0,0x6
ffffffffc02003f0:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0205cc8 <etext+0x1c4>
ffffffffc02003f4:	de9ff0ef          	jal	ffffffffc02001dc <cprintf>
    return 0;
ffffffffc02003f8:	bf5d                	j	ffffffffc02003ae <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003fa:	00006517          	auipc	a0,0x6
ffffffffc02003fe:	8a650513          	addi	a0,a0,-1882 # ffffffffc0205ca0 <etext+0x19c>
ffffffffc0200402:	6c6050ef          	jal	ffffffffc0205ac8 <strchr>
ffffffffc0200406:	c901                	beqz	a0,ffffffffc0200416 <kmonitor+0xa6>
ffffffffc0200408:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc020040c:	00040023          	sb	zero,0(s0)
ffffffffc0200410:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200412:	d9d5                	beqz	a1,ffffffffc02003c6 <kmonitor+0x56>
ffffffffc0200414:	b7dd                	j	ffffffffc02003fa <kmonitor+0x8a>
        if (*buf == '\0') {
ffffffffc0200416:	00044783          	lbu	a5,0(s0)
ffffffffc020041a:	d7d5                	beqz	a5,ffffffffc02003c6 <kmonitor+0x56>
        if (argc == MAXARGS - 1) {
ffffffffc020041c:	03348b63          	beq	s1,s3,ffffffffc0200452 <kmonitor+0xe2>
        argv[argc ++] = buf;
ffffffffc0200420:	00349793          	slli	a5,s1,0x3
ffffffffc0200424:	978a                	add	a5,a5,sp
ffffffffc0200426:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200428:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020042c:	2485                	addiw	s1,s1,1
ffffffffc020042e:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200430:	e591                	bnez	a1,ffffffffc020043c <kmonitor+0xcc>
ffffffffc0200432:	bf59                	j	ffffffffc02003c8 <kmonitor+0x58>
ffffffffc0200434:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200438:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020043a:	d5d1                	beqz	a1,ffffffffc02003c6 <kmonitor+0x56>
ffffffffc020043c:	00006517          	auipc	a0,0x6
ffffffffc0200440:	86450513          	addi	a0,a0,-1948 # ffffffffc0205ca0 <etext+0x19c>
ffffffffc0200444:	684050ef          	jal	ffffffffc0205ac8 <strchr>
ffffffffc0200448:	d575                	beqz	a0,ffffffffc0200434 <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020044a:	00044583          	lbu	a1,0(s0)
ffffffffc020044e:	dda5                	beqz	a1,ffffffffc02003c6 <kmonitor+0x56>
ffffffffc0200450:	b76d                	j	ffffffffc02003fa <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200452:	45c1                	li	a1,16
ffffffffc0200454:	00006517          	auipc	a0,0x6
ffffffffc0200458:	85450513          	addi	a0,a0,-1964 # ffffffffc0205ca8 <etext+0x1a4>
ffffffffc020045c:	d81ff0ef          	jal	ffffffffc02001dc <cprintf>
ffffffffc0200460:	b7c1                	j	ffffffffc0200420 <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200462:	00141793          	slli	a5,s0,0x1
ffffffffc0200466:	97a2                	add	a5,a5,s0
ffffffffc0200468:	078e                	slli	a5,a5,0x3
ffffffffc020046a:	97d6                	add	a5,a5,s5
ffffffffc020046c:	6b9c                	ld	a5,16(a5)
ffffffffc020046e:	fffb051b          	addiw	a0,s6,-1
ffffffffc0200472:	8652                	mv	a2,s4
ffffffffc0200474:	002c                	addi	a1,sp,8
ffffffffc0200476:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200478:	f2055be3          	bgez	a0,ffffffffc02003ae <kmonitor+0x3e>
}
ffffffffc020047c:	70ea                	ld	ra,184(sp)
ffffffffc020047e:	744a                	ld	s0,176(sp)
ffffffffc0200480:	74aa                	ld	s1,168(sp)
ffffffffc0200482:	69ea                	ld	s3,152(sp)
ffffffffc0200484:	6a4a                	ld	s4,144(sp)
ffffffffc0200486:	6aaa                	ld	s5,136(sp)
ffffffffc0200488:	6b0a                	ld	s6,128(sp)
ffffffffc020048a:	6129                	addi	sp,sp,192
ffffffffc020048c:	8082                	ret

ffffffffc020048e <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020048e:	000b1317          	auipc	t1,0xb1
ffffffffc0200492:	00a33303          	ld	t1,10(t1) # ffffffffc02b1498 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200496:	715d                	addi	sp,sp,-80
ffffffffc0200498:	ec06                	sd	ra,24(sp)
ffffffffc020049a:	f436                	sd	a3,40(sp)
ffffffffc020049c:	f83a                	sd	a4,48(sp)
ffffffffc020049e:	fc3e                	sd	a5,56(sp)
ffffffffc02004a0:	e0c2                	sd	a6,64(sp)
ffffffffc02004a2:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02004a4:	02031e63          	bnez	t1,ffffffffc02004e0 <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004a8:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004aa:	103c                	addi	a5,sp,40
ffffffffc02004ac:	e822                	sd	s0,16(sp)
ffffffffc02004ae:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b0:	862e                	mv	a2,a1
ffffffffc02004b2:	85aa                	mv	a1,a0
ffffffffc02004b4:	00006517          	auipc	a0,0x6
ffffffffc02004b8:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0205d70 <etext+0x26c>
    is_panic = 1;
ffffffffc02004bc:	000b1697          	auipc	a3,0xb1
ffffffffc02004c0:	fce6be23          	sd	a4,-36(a3) # ffffffffc02b1498 <is_panic>
    va_start(ap, fmt);
ffffffffc02004c4:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c6:	d17ff0ef          	jal	ffffffffc02001dc <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004ca:	65a2                	ld	a1,8(sp)
ffffffffc02004cc:	8522                	mv	a0,s0
ffffffffc02004ce:	cefff0ef          	jal	ffffffffc02001bc <vcprintf>
    cprintf("\n");
ffffffffc02004d2:	00006517          	auipc	a0,0x6
ffffffffc02004d6:	8be50513          	addi	a0,a0,-1858 # ffffffffc0205d90 <etext+0x28c>
ffffffffc02004da:	d03ff0ef          	jal	ffffffffc02001dc <cprintf>
ffffffffc02004de:	6442                	ld	s0,16(sp)
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004e0:	4501                	li	a0,0
ffffffffc02004e2:	4581                	li	a1,0
ffffffffc02004e4:	4601                	li	a2,0
ffffffffc02004e6:	48a1                	li	a7,8
ffffffffc02004e8:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004ec:	510000ef          	jal	ffffffffc02009fc <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004f0:	4501                	li	a0,0
ffffffffc02004f2:	e7fff0ef          	jal	ffffffffc0200370 <kmonitor>
    while (1) {
ffffffffc02004f6:	bfed                	j	ffffffffc02004f0 <__panic+0x62>

ffffffffc02004f8 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004f8:	715d                	addi	sp,sp,-80
ffffffffc02004fa:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004fc:	02810313          	addi	t1,sp,40
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200500:	8432                	mv	s0,a2
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200502:	862e                	mv	a2,a1
ffffffffc0200504:	85aa                	mv	a1,a0
ffffffffc0200506:	00006517          	auipc	a0,0x6
ffffffffc020050a:	89250513          	addi	a0,a0,-1902 # ffffffffc0205d98 <etext+0x294>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc020050e:	ec06                	sd	ra,24(sp)
ffffffffc0200510:	f436                	sd	a3,40(sp)
ffffffffc0200512:	f83a                	sd	a4,48(sp)
ffffffffc0200514:	fc3e                	sd	a5,56(sp)
ffffffffc0200516:	e0c2                	sd	a6,64(sp)
ffffffffc0200518:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020051a:	e41a                	sd	t1,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020051c:	cc1ff0ef          	jal	ffffffffc02001dc <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200520:	65a2                	ld	a1,8(sp)
ffffffffc0200522:	8522                	mv	a0,s0
ffffffffc0200524:	c99ff0ef          	jal	ffffffffc02001bc <vcprintf>
    cprintf("\n");
ffffffffc0200528:	00006517          	auipc	a0,0x6
ffffffffc020052c:	86850513          	addi	a0,a0,-1944 # ffffffffc0205d90 <etext+0x28c>
ffffffffc0200530:	cadff0ef          	jal	ffffffffc02001dc <cprintf>
    va_end(ap);
}
ffffffffc0200534:	60e2                	ld	ra,24(sp)
ffffffffc0200536:	6442                	ld	s0,16(sp)
ffffffffc0200538:	6161                	addi	sp,sp,80
ffffffffc020053a:	8082                	ret

ffffffffc020053c <clock_init>:
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void)
{
    set_csr(sie, MIP_STIP);
ffffffffc020053c:	02000793          	li	a5,32
ffffffffc0200540:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200544:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200548:	67e1                	lui	a5,0x18
ffffffffc020054a:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xd178>
ffffffffc020054e:	953e                	add	a0,a0,a5
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200550:	4581                	li	a1,0
ffffffffc0200552:	4601                	li	a2,0
ffffffffc0200554:	4881                	li	a7,0
ffffffffc0200556:	00000073          	ecall
    cprintf("++ setup timer interrupts\n");
ffffffffc020055a:	00006517          	auipc	a0,0x6
ffffffffc020055e:	85e50513          	addi	a0,a0,-1954 # ffffffffc0205db8 <etext+0x2b4>
    ticks = 0;
ffffffffc0200562:	000b1797          	auipc	a5,0xb1
ffffffffc0200566:	f207bf23          	sd	zero,-194(a5) # ffffffffc02b14a0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020056a:	b98d                	j	ffffffffc02001dc <cprintf>

ffffffffc020056c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020056c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200570:	67e1                	lui	a5,0x18
ffffffffc0200572:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_matrix_out_size+0xd178>
ffffffffc0200576:	953e                	add	a0,a0,a5
ffffffffc0200578:	4581                	li	a1,0
ffffffffc020057a:	4601                	li	a2,0
ffffffffc020057c:	4881                	li	a7,0
ffffffffc020057e:	00000073          	ecall
ffffffffc0200582:	8082                	ret

ffffffffc0200584 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200584:	8082                	ret

ffffffffc0200586 <cons_putc>:
#include <assert.h>
#include <atomic.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200586:	100027f3          	csrr	a5,sstatus
ffffffffc020058a:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020058c:	0ff57513          	zext.b	a0,a0
ffffffffc0200590:	e799                	bnez	a5,ffffffffc020059e <cons_putc+0x18>
ffffffffc0200592:	4581                	li	a1,0
ffffffffc0200594:	4601                	li	a2,0
ffffffffc0200596:	4885                	li	a7,1
ffffffffc0200598:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc020059c:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc020059e:	1101                	addi	sp,sp,-32
ffffffffc02005a0:	ec06                	sd	ra,24(sp)
ffffffffc02005a2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005a4:	458000ef          	jal	ffffffffc02009fc <intr_disable>
ffffffffc02005a8:	6522                	ld	a0,8(sp)
ffffffffc02005aa:	4581                	li	a1,0
ffffffffc02005ac:	4601                	li	a2,0
ffffffffc02005ae:	4885                	li	a7,1
ffffffffc02005b0:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005b4:	60e2                	ld	ra,24(sp)
ffffffffc02005b6:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc02005b8:	a93d                	j	ffffffffc02009f6 <intr_enable>

ffffffffc02005ba <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02005ba:	100027f3          	csrr	a5,sstatus
ffffffffc02005be:	8b89                	andi	a5,a5,2
ffffffffc02005c0:	eb89                	bnez	a5,ffffffffc02005d2 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005c2:	4501                	li	a0,0
ffffffffc02005c4:	4581                	li	a1,0
ffffffffc02005c6:	4601                	li	a2,0
ffffffffc02005c8:	4889                	li	a7,2
ffffffffc02005ca:	00000073          	ecall
ffffffffc02005ce:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d0:	8082                	ret
int cons_getc(void) {
ffffffffc02005d2:	1101                	addi	sp,sp,-32
ffffffffc02005d4:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005d6:	426000ef          	jal	ffffffffc02009fc <intr_disable>
ffffffffc02005da:	4501                	li	a0,0
ffffffffc02005dc:	4581                	li	a1,0
ffffffffc02005de:	4601                	li	a2,0
ffffffffc02005e0:	4889                	li	a7,2
ffffffffc02005e2:	00000073          	ecall
ffffffffc02005e6:	2501                	sext.w	a0,a0
ffffffffc02005e8:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ea:	40c000ef          	jal	ffffffffc02009f6 <intr_enable>
}
ffffffffc02005ee:	60e2                	ld	ra,24(sp)
ffffffffc02005f0:	6522                	ld	a0,8(sp)
ffffffffc02005f2:	6105                	addi	sp,sp,32
ffffffffc02005f4:	8082                	ret

ffffffffc02005f6 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005f6:	715d                	addi	sp,sp,-80
    cprintf("DTB Init\n");
ffffffffc02005f8:	00005517          	auipc	a0,0x5
ffffffffc02005fc:	7e050513          	addi	a0,a0,2016 # ffffffffc0205dd8 <etext+0x2d4>
void dtb_init(void) {
ffffffffc0200600:	e486                	sd	ra,72(sp)
ffffffffc0200602:	e0a2                	sd	s0,64(sp)
    cprintf("DTB Init\n");
ffffffffc0200604:	bd9ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200608:	000b5597          	auipc	a1,0xb5
ffffffffc020060c:	f785b583          	ld	a1,-136(a1) # ffffffffc02b5580 <boot_hartid>
ffffffffc0200610:	00005517          	auipc	a0,0x5
ffffffffc0200614:	7d850513          	addi	a0,a0,2008 # ffffffffc0205de8 <etext+0x2e4>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200618:	000b5417          	auipc	s0,0xb5
ffffffffc020061c:	f7040413          	addi	s0,s0,-144 # ffffffffc02b5588 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200620:	bbdff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200624:	600c                	ld	a1,0(s0)
ffffffffc0200626:	00005517          	auipc	a0,0x5
ffffffffc020062a:	7d250513          	addi	a0,a0,2002 # ffffffffc0205df8 <etext+0x2f4>
ffffffffc020062e:	bafff0ef          	jal	ffffffffc02001dc <cprintf>
    
    // If boot_dtb is 0, try common DTB locations for QEMU
    if (boot_dtb == 0) {
ffffffffc0200632:	6018                	ld	a4,0(s0)
ffffffffc0200634:	e345                	bnez	a4,ffffffffc02006d4 <dtb_init+0xde>
        // QEMU virt machine typically puts DTB at 0x82200000 or 0x87e00000
        uintptr_t dtb_candidates[] = {0x82200000, 0x87e00000, 0x80000000 + 128*1024*1024 - 0x200000};
ffffffffc0200636:	41100713          	li	a4,1041
ffffffffc020063a:	43f00793          	li	a5,1087
ffffffffc020063e:	07d6                	slli	a5,a5,0x15
ffffffffc0200640:	0756                	slli	a4,a4,0x15
        for (int i = 0; i < 3; i++) {
            const struct fdt_header *test_header = (const struct fdt_header *)dtb_candidates[i];
            if (fdt32_to_cpu(test_header->magic) == 0xd00dfeed) {
ffffffffc0200642:	d00e0537          	lui	a0,0xd00e0
        uintptr_t dtb_candidates[] = {0x82200000, 0x87e00000, 0x80000000 + 128*1024*1024 - 0x200000};
ffffffffc0200646:	e83a                	sd	a4,16(sp)
ffffffffc0200648:	ec3e                	sd	a5,24(sp)
ffffffffc020064a:	f03e                	sd	a5,32(sp)
            if (fdt32_to_cpu(test_header->magic) == 0xd00dfeed) {
ffffffffc020064c:	eed50513          	addi	a0,a0,-275 # ffffffffd00dfeed <boot_dtb+0xfe2a965>
ffffffffc0200650:	0810                	addi	a2,sp,16
ffffffffc0200652:	02810313          	addi	t1,sp,40
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200656:	00ff08b7          	lui	a7,0xff0
            const struct fdt_header *test_header = (const struct fdt_header *)dtb_candidates[i];
ffffffffc020065a:	620c                	ld	a1,0(a2)
        for (int i = 0; i < 3; i++) {
ffffffffc020065c:	0621                	addi	a2,a2,8
            if (fdt32_to_cpu(test_header->magic) == 0xd00dfeed) {
ffffffffc020065e:	419c                	lw	a5,0(a1)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200660:	0087d69b          	srliw	a3,a5,0x8
ffffffffc0200664:	0187971b          	slliw	a4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200668:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020066c:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200670:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200674:	0116f6b3          	and	a3,a3,a7
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	01076733          	or	a4,a4,a6
ffffffffc020067c:	0ff7f793          	zext.b	a5,a5
ffffffffc0200680:	8f55                	or	a4,a4,a3
ffffffffc0200682:	07a2                	slli	a5,a5,0x8
            if (fdt32_to_cpu(test_header->magic) == 0xd00dfeed) {
ffffffffc0200684:	8fd9                	or	a5,a5,a4
ffffffffc0200686:	02a78e63          	beq	a5,a0,ffffffffc02006c2 <dtb_init+0xcc>
        for (int i = 0; i < 3; i++) {
ffffffffc020068a:	fcc318e3          	bne	t1,a2,ffffffffc020065a <dtb_init+0x64>
            }
        }
    }
    
    if (boot_dtb == 0) {
        cprintf("Warning: DTB not found, using default memory configuration\n");
ffffffffc020068e:	00005517          	auipc	a0,0x5
ffffffffc0200692:	7aa50513          	addi	a0,a0,1962 # ffffffffc0205e38 <etext+0x334>
ffffffffc0200696:	b47ff0ef          	jal	ffffffffc02001dc <cprintf>
        // Default for QEMU virt machine: 128MB at 0x80000000
        memory_base = 0x80000000;
ffffffffc020069a:	4785                	li	a5,1
        cprintf("Warning: Could not extract memory info from DTB, using default\n");
        memory_base = 0x80000000;
        memory_size = 0x8000000;  // 128MB
    }
    cprintf("DTB init completed\n");
}
ffffffffc020069c:	6406                	ld	s0,64(sp)
ffffffffc020069e:	60a6                	ld	ra,72(sp)
        memory_base = 0x80000000;
ffffffffc02006a0:	07fe                	slli	a5,a5,0x1f
        memory_size = 0x8000000;  // 128MB
ffffffffc02006a2:	08000737          	lui	a4,0x8000
        memory_base = 0x80000000;
ffffffffc02006a6:	000b1697          	auipc	a3,0xb1
ffffffffc02006aa:	e0f6b523          	sd	a5,-502(a3) # ffffffffc02b14b0 <memory_base>
        memory_size = 0x8000000;  // 128MB
ffffffffc02006ae:	000b1797          	auipc	a5,0xb1
ffffffffc02006b2:	dee7bd23          	sd	a4,-518(a5) # ffffffffc02b14a8 <memory_size>
        cprintf("Using default memory: base=0x80000000, size=128MB\n");
ffffffffc02006b6:	00005517          	auipc	a0,0x5
ffffffffc02006ba:	7c250513          	addi	a0,a0,1986 # ffffffffc0205e78 <etext+0x374>
}
ffffffffc02006be:	6161                	addi	sp,sp,80
    cprintf("DTB init completed\n");
ffffffffc02006c0:	be31                	j	ffffffffc02001dc <cprintf>
                cprintf("Found DTB at fallback location: 0x%lx\n", boot_dtb);
ffffffffc02006c2:	00005517          	auipc	a0,0x5
ffffffffc02006c6:	74e50513          	addi	a0,a0,1870 # ffffffffc0205e10 <etext+0x30c>
                boot_dtb = dtb_candidates[i];
ffffffffc02006ca:	e00c                	sd	a1,0(s0)
                cprintf("Found DTB at fallback location: 0x%lx\n", boot_dtb);
ffffffffc02006cc:	b11ff0ef          	jal	ffffffffc02001dc <cprintf>
    if (boot_dtb == 0) {
ffffffffc02006d0:	6018                	ld	a4,0(s0)
ffffffffc02006d2:	df55                	beqz	a4,ffffffffc020068e <dtb_init+0x98>
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02006d4:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc02006d6:	d00e06b7          	lui	a3,0xd00e0
ffffffffc02006da:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <boot_dtb+0xfe2a965>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006de:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02006e2:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e6:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ea:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ee:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006f2:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006f4:	8e49                	or	a2,a2,a0
ffffffffc02006f6:	0ff7f793          	zext.b	a5,a5
ffffffffc02006fa:	8dd1                	or	a1,a1,a2
ffffffffc02006fc:	07a2                	slli	a5,a5,0x8
ffffffffc02006fe:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200700:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc0200704:	0ad59463          	bne	a1,a3,ffffffffc02007ac <dtb_init+0x1b6>
    if (extract_memory_info((uintptr_t)boot_dtb, header, &mem_base, &mem_size) == 0) {
ffffffffc0200708:	4710                	lw	a2,8(a4)
ffffffffc020070a:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020070c:	f84a                	sd	s2,48(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070e:	0086541b          	srliw	s0,a2,0x8
ffffffffc0200712:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200716:	01865e1b          	srliw	t3,a2,0x18
ffffffffc020071a:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071e:	0186151b          	slliw	a0,a2,0x18
ffffffffc0200722:	0186959b          	slliw	a1,a3,0x18
ffffffffc0200726:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072a:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200732:	0106d69b          	srliw	a3,a3,0x10
ffffffffc0200736:	01c56533          	or	a0,a0,t3
ffffffffc020073a:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073e:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200742:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200746:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074a:	0ff6f693          	zext.b	a3,a3
ffffffffc020074e:	8c49                	or	s0,s0,a0
ffffffffc0200750:	0622                	slli	a2,a2,0x8
ffffffffc0200752:	8fcd                	or	a5,a5,a1
ffffffffc0200754:	06a2                	slli	a3,a3,0x8
ffffffffc0200756:	8c51                	or	s0,s0,a2
ffffffffc0200758:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020075a:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020075c:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020075e:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200760:	9381                	srli	a5,a5,0x20
    int in_memory_node = 0;
ffffffffc0200762:	4301                	li	t1,0
        switch (token) {
ffffffffc0200764:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200766:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200768:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc020076c:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020076e:	401c                	lw	a5,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200770:	0087d69b          	srliw	a3,a5,0x8
ffffffffc0200774:	0187971b          	slliw	a4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200778:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020077c:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200780:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200784:	0106f6b3          	and	a3,a3,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200788:	8f51                	or	a4,a4,a2
ffffffffc020078a:	0ff7f793          	zext.b	a5,a5
ffffffffc020078e:	8f55                	or	a4,a4,a3
ffffffffc0200790:	07a2                	slli	a5,a5,0x8
ffffffffc0200792:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc0200794:	0b178e63          	beq	a5,a7,ffffffffc0200850 <dtb_init+0x25a>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200798:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc020079a:	02f8ef63          	bltu	a7,a5,ffffffffc02007d8 <dtb_init+0x1e2>
ffffffffc020079e:	07c78b63          	beq	a5,t3,ffffffffc0200814 <dtb_init+0x21e>
ffffffffc02007a2:	4709                	li	a4,2
ffffffffc02007a4:	02e79d63          	bne	a5,a4,ffffffffc02007de <dtb_init+0x1e8>
ffffffffc02007a8:	4301                	li	t1,0
ffffffffc02007aa:	b7d1                	j	ffffffffc020076e <dtb_init+0x178>
        cprintf("Error: Invalid DTB magic number: 0x%x, using default\n", magic);
ffffffffc02007ac:	00005517          	auipc	a0,0x5
ffffffffc02007b0:	70450513          	addi	a0,a0,1796 # ffffffffc0205eb0 <etext+0x3ac>
ffffffffc02007b4:	a29ff0ef          	jal	ffffffffc02001dc <cprintf>
}
ffffffffc02007b8:	60a6                	ld	ra,72(sp)
ffffffffc02007ba:	6406                	ld	s0,64(sp)
        memory_base = 0x80000000;
ffffffffc02007bc:	4785                	li	a5,1
ffffffffc02007be:	07fe                	slli	a5,a5,0x1f
        memory_size = 0x8000000;  // 128MB
ffffffffc02007c0:	08000737          	lui	a4,0x8000
        memory_base = 0x80000000;
ffffffffc02007c4:	000b1697          	auipc	a3,0xb1
ffffffffc02007c8:	cef6b623          	sd	a5,-788(a3) # ffffffffc02b14b0 <memory_base>
        memory_size = 0x8000000;  // 128MB
ffffffffc02007cc:	000b1797          	auipc	a5,0xb1
ffffffffc02007d0:	cce7be23          	sd	a4,-804(a5) # ffffffffc02b14a8 <memory_size>
}
ffffffffc02007d4:	6161                	addi	sp,sp,80
ffffffffc02007d6:	8082                	ret
        switch (token) {
ffffffffc02007d8:	4711                	li	a4,4
ffffffffc02007da:	f8e78ae3          	beq	a5,a4,ffffffffc020076e <dtb_init+0x178>
        cprintf("Warning: Could not extract memory info from DTB, using default\n");
ffffffffc02007de:	00005517          	auipc	a0,0x5
ffffffffc02007e2:	78a50513          	addi	a0,a0,1930 # ffffffffc0205f68 <etext+0x464>
ffffffffc02007e6:	9f7ff0ef          	jal	ffffffffc02001dc <cprintf>
ffffffffc02007ea:	4405                	li	s0,1
ffffffffc02007ec:	047e                	slli	s0,s0,0x1f
ffffffffc02007ee:	080007b7          	lui	a5,0x8000
        memory_base = mem_base;
ffffffffc02007f2:	000b1717          	auipc	a4,0xb1
ffffffffc02007f6:	ca873f23          	sd	s0,-834(a4) # ffffffffc02b14b0 <memory_base>
}
ffffffffc02007fa:	6406                	ld	s0,64(sp)
    cprintf("DTB init completed\n");
ffffffffc02007fc:	7942                	ld	s2,48(sp)
}
ffffffffc02007fe:	60a6                	ld	ra,72(sp)
        memory_size = mem_size;
ffffffffc0200800:	000b1717          	auipc	a4,0xb1
ffffffffc0200804:	caf73423          	sd	a5,-856(a4) # ffffffffc02b14a8 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200808:	00005517          	auipc	a0,0x5
ffffffffc020080c:	7a050513          	addi	a0,a0,1952 # ffffffffc0205fa8 <etext+0x4a4>
}
ffffffffc0200810:	6161                	addi	sp,sp,80
    cprintf("DTB init completed\n");
ffffffffc0200812:	b2e9                	j	ffffffffc02001dc <cprintf>
                int name_len = strlen(name);
ffffffffc0200814:	8522                	mv	a0,s0
ffffffffc0200816:	fc26                	sd	s1,56(sp)
ffffffffc0200818:	e01a                	sd	t1,0(sp)
ffffffffc020081a:	20c050ef          	jal	ffffffffc0205a26 <strlen>
ffffffffc020081e:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200820:	4619                	li	a2,6
ffffffffc0200822:	8522                	mv	a0,s0
ffffffffc0200824:	00005597          	auipc	a1,0x5
ffffffffc0200828:	6c458593          	addi	a1,a1,1732 # ffffffffc0205ee8 <etext+0x3e4>
ffffffffc020082c:	274050ef          	jal	ffffffffc0205aa0 <strncmp>
ffffffffc0200830:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200832:	0004879b          	sext.w	a5,s1
ffffffffc0200836:	0411                	addi	s0,s0,4
ffffffffc0200838:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020083a:	00153513          	seqz	a0,a0
                break;
ffffffffc020083e:	74e2                	ld	s1,56(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200840:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200842:	00a36333          	or	t1,t1,a0
                break;
ffffffffc0200846:	00ff0837          	lui	a6,0xff0
ffffffffc020084a:	488d                	li	a7,3
ffffffffc020084c:	4e05                	li	t3,1
ffffffffc020084e:	b705                	j	ffffffffc020076e <dtb_init+0x178>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200850:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200856:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085e:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200862:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200866:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020086a:	8ed1                	or	a3,a3,a2
ffffffffc020086c:	0ff77713          	zext.b	a4,a4
ffffffffc0200870:	8fd5                	or	a5,a5,a3
ffffffffc0200872:	0722                	slli	a4,a4,0x8
ffffffffc0200874:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200876:	00031863          	bnez	t1,ffffffffc0200886 <dtb_init+0x290>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020087a:	1782                	slli	a5,a5,0x20
ffffffffc020087c:	9381                	srli	a5,a5,0x20
ffffffffc020087e:	043d                	addi	s0,s0,15
ffffffffc0200880:	943e                	add	s0,s0,a5
ffffffffc0200882:	9871                	andi	s0,s0,-4
                break;
ffffffffc0200884:	b5ed                	j	ffffffffc020076e <dtb_init+0x178>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200886:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200888:	00005597          	auipc	a1,0x5
ffffffffc020088c:	66858593          	addi	a1,a1,1640 # ffffffffc0205ef0 <etext+0x3ec>
ffffffffc0200890:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200892:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200896:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020089a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020089e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008a2:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008a6:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008aa:	8ed1                	or	a3,a3,a2
ffffffffc02008ac:	0ff77713          	zext.b	a4,a4
ffffffffc02008b0:	8d55                	or	a0,a0,a3
ffffffffc02008b2:	0722                	slli	a4,a4,0x8
ffffffffc02008b4:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02008b6:	1502                	slli	a0,a0,0x20
ffffffffc02008b8:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02008ba:	954a                	add	a0,a0,s2
ffffffffc02008bc:	e01a                	sd	t1,0(sp)
ffffffffc02008be:	1ae050ef          	jal	ffffffffc0205a6c <strcmp>
ffffffffc02008c2:	6302                	ld	t1,0(sp)
ffffffffc02008c4:	67a2                	ld	a5,8(sp)
ffffffffc02008c6:	00ff0837          	lui	a6,0xff0
ffffffffc02008ca:	488d                	li	a7,3
ffffffffc02008cc:	4e05                	li	t3,1
ffffffffc02008ce:	f555                	bnez	a0,ffffffffc020087a <dtb_init+0x284>
ffffffffc02008d0:	473d                	li	a4,15
ffffffffc02008d2:	faf774e3          	bgeu	a4,a5,ffffffffc020087a <dtb_init+0x284>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02008d6:	00c43783          	ld	a5,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02008da:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008de:	00005517          	auipc	a0,0x5
ffffffffc02008e2:	61a50513          	addi	a0,a0,1562 # ffffffffc0205ef8 <etext+0x3f4>
           fdt32_to_cpu(x >> 32);
ffffffffc02008e6:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008ea:	0086559b          	srliw	a1,a2,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02008ee:	42075693          	srai	a3,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02008f2:	01865e9b          	srliw	t4,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02008f6:	0186131b          	slliw	t1,a2,0x18
ffffffffc02008fa:	0105959b          	slliw	a1,a1,0x10
ffffffffc02008fe:	0105f5b3          	and	a1,a1,a6
ffffffffc0200902:	0086df1b          	srliw	t5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200906:	0106561b          	srliw	a2,a2,0x10
ffffffffc020090a:	01d36333          	or	t1,t1,t4
ffffffffc020090e:	0186de1b          	srliw	t3,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200912:	0186989b          	slliw	a7,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200916:	00b36333          	or	t1,t1,a1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020091a:	010f1f1b          	slliw	t5,t5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020091e:	0ff67593          	zext.b	a1,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200922:	010f7f33          	and	t5,t5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200926:	01c8e8b3          	or	a7,a7,t3
ffffffffc020092a:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020092e:	00875e1b          	srliw	t3,a4,0x8
ffffffffc0200932:	0087de9b          	srliw	t4,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200936:	05a2                	slli	a1,a1,0x8
ffffffffc0200938:	00b36333          	or	t1,t1,a1
ffffffffc020093c:	0187df9b          	srliw	t6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200940:	010e9e9b          	slliw	t4,t4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200944:	01e8e5b3          	or	a1,a7,t5
ffffffffc0200948:	0ff6f613          	zext.b	a2,a3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020094c:	010e189b          	slliw	a7,t3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200950:	01875f1b          	srliw	t5,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200954:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200958:	0107d69b          	srliw	a3,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020095c:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200960:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200964:	010efe33          	and	t3,t4,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200968:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020096c:	0108f833          	and	a6,a7,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200970:	0622                	slli	a2,a2,0x8
ffffffffc0200972:	0ff77713          	zext.b	a4,a4
ffffffffc0200976:	01f46433          	or	s0,s0,t6
ffffffffc020097a:	0107e7b3          	or	a5,a5,a6
ffffffffc020097e:	0722                	slli	a4,a4,0x8
ffffffffc0200980:	8e4d                	or	a2,a2,a1
ffffffffc0200982:	0ff6f693          	zext.b	a3,a3
ffffffffc0200986:	01c46433          	or	s0,s0,t3
ffffffffc020098a:	06a2                	slli	a3,a3,0x8
ffffffffc020098c:	8fd9                	or	a5,a5,a4
           fdt32_to_cpu(x >> 32);
ffffffffc020098e:	1602                	slli	a2,a2,0x20
ffffffffc0200990:	02031593          	slli	a1,t1,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200994:	8c55                	or	s0,s0,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200996:	9201                	srli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200998:	1782                	slli	a5,a5,0x20
ffffffffc020099a:	8fd1                	or	a5,a5,a2
           fdt32_to_cpu(x >> 32);
ffffffffc020099c:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020099e:	1402                	slli	s0,s0,0x20
ffffffffc02009a0:	8c4d                	or	s0,s0,a1
ffffffffc02009a2:	e03e                	sd	a5,0(sp)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02009a4:	839ff0ef          	jal	ffffffffc02001dc <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02009a8:	85a2                	mv	a1,s0
ffffffffc02009aa:	00005517          	auipc	a0,0x5
ffffffffc02009ae:	56e50513          	addi	a0,a0,1390 # ffffffffc0205f18 <etext+0x414>
ffffffffc02009b2:	82bff0ef          	jal	ffffffffc02001dc <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02009b6:	6782                	ld	a5,0(sp)
ffffffffc02009b8:	00005517          	auipc	a0,0x5
ffffffffc02009bc:	57850513          	addi	a0,a0,1400 # ffffffffc0205f30 <etext+0x42c>
ffffffffc02009c0:	0147d613          	srli	a2,a5,0x14
ffffffffc02009c4:	85be                	mv	a1,a5
ffffffffc02009c6:	817ff0ef          	jal	ffffffffc02001dc <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02009ca:	6782                	ld	a5,0(sp)
ffffffffc02009cc:	00005517          	auipc	a0,0x5
ffffffffc02009d0:	58450513          	addi	a0,a0,1412 # ffffffffc0205f50 <etext+0x44c>
ffffffffc02009d4:	008785b3          	add	a1,a5,s0
ffffffffc02009d8:	15fd                	addi	a1,a1,-1
ffffffffc02009da:	803ff0ef          	jal	ffffffffc02001dc <cprintf>
        memory_size = mem_size;
ffffffffc02009de:	6782                	ld	a5,0(sp)
ffffffffc02009e0:	bd09                	j	ffffffffc02007f2 <dtb_init+0x1fc>

ffffffffc02009e2 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02009e2:	000b1517          	auipc	a0,0xb1
ffffffffc02009e6:	ace53503          	ld	a0,-1330(a0) # ffffffffc02b14b0 <memory_base>
ffffffffc02009ea:	8082                	ret

ffffffffc02009ec <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02009ec:	000b1517          	auipc	a0,0xb1
ffffffffc02009f0:	abc53503          	ld	a0,-1348(a0) # ffffffffc02b14a8 <memory_size>
ffffffffc02009f4:	8082                	ret

ffffffffc02009f6 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009f6:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02009fa:	8082                	ret

ffffffffc02009fc <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02009fc:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200a00:	8082                	ret

ffffffffc0200a02 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200a02:	8082                	ret

ffffffffc0200a04 <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200a04:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200a08:	00000797          	auipc	a5,0x0
ffffffffc0200a0c:	4e878793          	addi	a5,a5,1256 # ffffffffc0200ef0 <__alltraps>
ffffffffc0200a10:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200a14:	000407b7          	lui	a5,0x40
ffffffffc0200a18:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200a1c:	8082                	ret

ffffffffc0200a1e <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200a1e:	610c                	ld	a1,0(a0)
{
ffffffffc0200a20:	1141                	addi	sp,sp,-16
ffffffffc0200a22:	e022                	sd	s0,0(sp)
ffffffffc0200a24:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200a26:	00005517          	auipc	a0,0x5
ffffffffc0200a2a:	59a50513          	addi	a0,a0,1434 # ffffffffc0205fc0 <etext+0x4bc>
{
ffffffffc0200a2e:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200a30:	facff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200a34:	640c                	ld	a1,8(s0)
ffffffffc0200a36:	00005517          	auipc	a0,0x5
ffffffffc0200a3a:	5a250513          	addi	a0,a0,1442 # ffffffffc0205fd8 <etext+0x4d4>
ffffffffc0200a3e:	f9eff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200a42:	680c                	ld	a1,16(s0)
ffffffffc0200a44:	00005517          	auipc	a0,0x5
ffffffffc0200a48:	5ac50513          	addi	a0,a0,1452 # ffffffffc0205ff0 <etext+0x4ec>
ffffffffc0200a4c:	f90ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200a50:	6c0c                	ld	a1,24(s0)
ffffffffc0200a52:	00005517          	auipc	a0,0x5
ffffffffc0200a56:	5b650513          	addi	a0,a0,1462 # ffffffffc0206008 <etext+0x504>
ffffffffc0200a5a:	f82ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200a5e:	700c                	ld	a1,32(s0)
ffffffffc0200a60:	00005517          	auipc	a0,0x5
ffffffffc0200a64:	5c050513          	addi	a0,a0,1472 # ffffffffc0206020 <etext+0x51c>
ffffffffc0200a68:	f74ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200a6c:	740c                	ld	a1,40(s0)
ffffffffc0200a6e:	00005517          	auipc	a0,0x5
ffffffffc0200a72:	5ca50513          	addi	a0,a0,1482 # ffffffffc0206038 <etext+0x534>
ffffffffc0200a76:	f66ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200a7a:	780c                	ld	a1,48(s0)
ffffffffc0200a7c:	00005517          	auipc	a0,0x5
ffffffffc0200a80:	5d450513          	addi	a0,a0,1492 # ffffffffc0206050 <etext+0x54c>
ffffffffc0200a84:	f58ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200a88:	7c0c                	ld	a1,56(s0)
ffffffffc0200a8a:	00005517          	auipc	a0,0x5
ffffffffc0200a8e:	5de50513          	addi	a0,a0,1502 # ffffffffc0206068 <etext+0x564>
ffffffffc0200a92:	f4aff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a96:	602c                	ld	a1,64(s0)
ffffffffc0200a98:	00005517          	auipc	a0,0x5
ffffffffc0200a9c:	5e850513          	addi	a0,a0,1512 # ffffffffc0206080 <etext+0x57c>
ffffffffc0200aa0:	f3cff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200aa4:	642c                	ld	a1,72(s0)
ffffffffc0200aa6:	00005517          	auipc	a0,0x5
ffffffffc0200aaa:	5f250513          	addi	a0,a0,1522 # ffffffffc0206098 <etext+0x594>
ffffffffc0200aae:	f2eff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200ab2:	682c                	ld	a1,80(s0)
ffffffffc0200ab4:	00005517          	auipc	a0,0x5
ffffffffc0200ab8:	5fc50513          	addi	a0,a0,1532 # ffffffffc02060b0 <etext+0x5ac>
ffffffffc0200abc:	f20ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200ac0:	6c2c                	ld	a1,88(s0)
ffffffffc0200ac2:	00005517          	auipc	a0,0x5
ffffffffc0200ac6:	60650513          	addi	a0,a0,1542 # ffffffffc02060c8 <etext+0x5c4>
ffffffffc0200aca:	f12ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200ace:	702c                	ld	a1,96(s0)
ffffffffc0200ad0:	00005517          	auipc	a0,0x5
ffffffffc0200ad4:	61050513          	addi	a0,a0,1552 # ffffffffc02060e0 <etext+0x5dc>
ffffffffc0200ad8:	f04ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200adc:	742c                	ld	a1,104(s0)
ffffffffc0200ade:	00005517          	auipc	a0,0x5
ffffffffc0200ae2:	61a50513          	addi	a0,a0,1562 # ffffffffc02060f8 <etext+0x5f4>
ffffffffc0200ae6:	ef6ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200aea:	782c                	ld	a1,112(s0)
ffffffffc0200aec:	00005517          	auipc	a0,0x5
ffffffffc0200af0:	62450513          	addi	a0,a0,1572 # ffffffffc0206110 <etext+0x60c>
ffffffffc0200af4:	ee8ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200af8:	7c2c                	ld	a1,120(s0)
ffffffffc0200afa:	00005517          	auipc	a0,0x5
ffffffffc0200afe:	62e50513          	addi	a0,a0,1582 # ffffffffc0206128 <etext+0x624>
ffffffffc0200b02:	edaff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200b06:	604c                	ld	a1,128(s0)
ffffffffc0200b08:	00005517          	auipc	a0,0x5
ffffffffc0200b0c:	63850513          	addi	a0,a0,1592 # ffffffffc0206140 <etext+0x63c>
ffffffffc0200b10:	eccff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200b14:	644c                	ld	a1,136(s0)
ffffffffc0200b16:	00005517          	auipc	a0,0x5
ffffffffc0200b1a:	64250513          	addi	a0,a0,1602 # ffffffffc0206158 <etext+0x654>
ffffffffc0200b1e:	ebeff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200b22:	684c                	ld	a1,144(s0)
ffffffffc0200b24:	00005517          	auipc	a0,0x5
ffffffffc0200b28:	64c50513          	addi	a0,a0,1612 # ffffffffc0206170 <etext+0x66c>
ffffffffc0200b2c:	eb0ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200b30:	6c4c                	ld	a1,152(s0)
ffffffffc0200b32:	00005517          	auipc	a0,0x5
ffffffffc0200b36:	65650513          	addi	a0,a0,1622 # ffffffffc0206188 <etext+0x684>
ffffffffc0200b3a:	ea2ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200b3e:	704c                	ld	a1,160(s0)
ffffffffc0200b40:	00005517          	auipc	a0,0x5
ffffffffc0200b44:	66050513          	addi	a0,a0,1632 # ffffffffc02061a0 <etext+0x69c>
ffffffffc0200b48:	e94ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200b4c:	744c                	ld	a1,168(s0)
ffffffffc0200b4e:	00005517          	auipc	a0,0x5
ffffffffc0200b52:	66a50513          	addi	a0,a0,1642 # ffffffffc02061b8 <etext+0x6b4>
ffffffffc0200b56:	e86ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200b5a:	784c                	ld	a1,176(s0)
ffffffffc0200b5c:	00005517          	auipc	a0,0x5
ffffffffc0200b60:	67450513          	addi	a0,a0,1652 # ffffffffc02061d0 <etext+0x6cc>
ffffffffc0200b64:	e78ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200b68:	7c4c                	ld	a1,184(s0)
ffffffffc0200b6a:	00005517          	auipc	a0,0x5
ffffffffc0200b6e:	67e50513          	addi	a0,a0,1662 # ffffffffc02061e8 <etext+0x6e4>
ffffffffc0200b72:	e6aff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200b76:	606c                	ld	a1,192(s0)
ffffffffc0200b78:	00005517          	auipc	a0,0x5
ffffffffc0200b7c:	68850513          	addi	a0,a0,1672 # ffffffffc0206200 <etext+0x6fc>
ffffffffc0200b80:	e5cff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200b84:	646c                	ld	a1,200(s0)
ffffffffc0200b86:	00005517          	auipc	a0,0x5
ffffffffc0200b8a:	69250513          	addi	a0,a0,1682 # ffffffffc0206218 <etext+0x714>
ffffffffc0200b8e:	e4eff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b92:	686c                	ld	a1,208(s0)
ffffffffc0200b94:	00005517          	auipc	a0,0x5
ffffffffc0200b98:	69c50513          	addi	a0,a0,1692 # ffffffffc0206230 <etext+0x72c>
ffffffffc0200b9c:	e40ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200ba0:	6c6c                	ld	a1,216(s0)
ffffffffc0200ba2:	00005517          	auipc	a0,0x5
ffffffffc0200ba6:	6a650513          	addi	a0,a0,1702 # ffffffffc0206248 <etext+0x744>
ffffffffc0200baa:	e32ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200bae:	706c                	ld	a1,224(s0)
ffffffffc0200bb0:	00005517          	auipc	a0,0x5
ffffffffc0200bb4:	6b050513          	addi	a0,a0,1712 # ffffffffc0206260 <etext+0x75c>
ffffffffc0200bb8:	e24ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200bbc:	746c                	ld	a1,232(s0)
ffffffffc0200bbe:	00005517          	auipc	a0,0x5
ffffffffc0200bc2:	6ba50513          	addi	a0,a0,1722 # ffffffffc0206278 <etext+0x774>
ffffffffc0200bc6:	e16ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200bca:	786c                	ld	a1,240(s0)
ffffffffc0200bcc:	00005517          	auipc	a0,0x5
ffffffffc0200bd0:	6c450513          	addi	a0,a0,1732 # ffffffffc0206290 <etext+0x78c>
ffffffffc0200bd4:	e08ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200bd8:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200bda:	6402                	ld	s0,0(sp)
ffffffffc0200bdc:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200bde:	00005517          	auipc	a0,0x5
ffffffffc0200be2:	6ca50513          	addi	a0,a0,1738 # ffffffffc02062a8 <etext+0x7a4>
}
ffffffffc0200be6:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200be8:	df4ff06f          	j	ffffffffc02001dc <cprintf>

ffffffffc0200bec <print_trapframe>:
{
ffffffffc0200bec:	1141                	addi	sp,sp,-16
ffffffffc0200bee:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bf0:	85aa                	mv	a1,a0
{
ffffffffc0200bf2:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bf4:	00005517          	auipc	a0,0x5
ffffffffc0200bf8:	6cc50513          	addi	a0,a0,1740 # ffffffffc02062c0 <etext+0x7bc>
{
ffffffffc0200bfc:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200bfe:	ddeff0ef          	jal	ffffffffc02001dc <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200c02:	8522                	mv	a0,s0
ffffffffc0200c04:	e1bff0ef          	jal	ffffffffc0200a1e <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200c08:	10043583          	ld	a1,256(s0)
ffffffffc0200c0c:	00005517          	auipc	a0,0x5
ffffffffc0200c10:	6cc50513          	addi	a0,a0,1740 # ffffffffc02062d8 <etext+0x7d4>
ffffffffc0200c14:	dc8ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200c18:	10843583          	ld	a1,264(s0)
ffffffffc0200c1c:	00005517          	auipc	a0,0x5
ffffffffc0200c20:	6d450513          	addi	a0,a0,1748 # ffffffffc02062f0 <etext+0x7ec>
ffffffffc0200c24:	db8ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200c28:	11043583          	ld	a1,272(s0)
ffffffffc0200c2c:	00005517          	auipc	a0,0x5
ffffffffc0200c30:	6dc50513          	addi	a0,a0,1756 # ffffffffc0206308 <etext+0x804>
ffffffffc0200c34:	da8ff0ef          	jal	ffffffffc02001dc <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c38:	11843583          	ld	a1,280(s0)
}
ffffffffc0200c3c:	6402                	ld	s0,0(sp)
ffffffffc0200c3e:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c40:	00005517          	auipc	a0,0x5
ffffffffc0200c44:	6d850513          	addi	a0,a0,1752 # ffffffffc0206318 <etext+0x814>
}
ffffffffc0200c48:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200c4a:	d92ff06f          	j	ffffffffc02001dc <cprintf>

ffffffffc0200c4e <interrupt_handler>:
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause)
ffffffffc0200c4e:	11853783          	ld	a5,280(a0)
ffffffffc0200c52:	472d                	li	a4,11
ffffffffc0200c54:	0786                	slli	a5,a5,0x1
ffffffffc0200c56:	8385                	srli	a5,a5,0x1
ffffffffc0200c58:	0af76363          	bltu	a4,a5,ffffffffc0200cfe <interrupt_handler+0xb0>
ffffffffc0200c5c:	00007717          	auipc	a4,0x7
ffffffffc0200c60:	dbc70713          	addi	a4,a4,-580 # ffffffffc0207a18 <commands+0x48>
ffffffffc0200c64:	078a                	slli	a5,a5,0x2
ffffffffc0200c66:	97ba                	add	a5,a5,a4
ffffffffc0200c68:	439c                	lw	a5,0(a5)
ffffffffc0200c6a:	97ba                	add	a5,a5,a4
ffffffffc0200c6c:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200c6e:	00005517          	auipc	a0,0x5
ffffffffc0200c72:	72250513          	addi	a0,a0,1826 # ffffffffc0206390 <etext+0x88c>
ffffffffc0200c76:	d66ff06f          	j	ffffffffc02001dc <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200c7a:	00005517          	auipc	a0,0x5
ffffffffc0200c7e:	6f650513          	addi	a0,a0,1782 # ffffffffc0206370 <etext+0x86c>
ffffffffc0200c82:	d5aff06f          	j	ffffffffc02001dc <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200c86:	00005517          	auipc	a0,0x5
ffffffffc0200c8a:	6aa50513          	addi	a0,a0,1706 # ffffffffc0206330 <etext+0x82c>
ffffffffc0200c8e:	d4eff06f          	j	ffffffffc02001dc <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200c92:	00005517          	auipc	a0,0x5
ffffffffc0200c96:	6be50513          	addi	a0,a0,1726 # ffffffffc0206350 <etext+0x84c>
ffffffffc0200c9a:	d42ff06f          	j	ffffffffc02001dc <cprintf>
{
ffffffffc0200c9e:	1141                	addi	sp,sp,-16
ffffffffc0200ca0:	e406                	sd	ra,8(sp)
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */

        // lab6: 2313411  (update LAB3 steps)
        //  在时钟中断时调用调度器的 sched_class_proc_tick 函数
        clock_set_next_event();
ffffffffc0200ca2:	8cbff0ef          	jal	ffffffffc020056c <clock_set_next_event>
        if (++ticks % TICK_NUM == 0) {
ffffffffc0200ca6:	000b0697          	auipc	a3,0xb0
ffffffffc0200caa:	7fa6b683          	ld	a3,2042(a3) # ffffffffc02b14a0 <ticks>
ffffffffc0200cae:	28f5c737          	lui	a4,0x28f5c
ffffffffc0200cb2:	28f70713          	addi	a4,a4,655 # 28f5c28f <_binary_obj___user_matrix_out_size+0x28f50d67>
ffffffffc0200cb6:	5c28f7b7          	lui	a5,0x5c28f
ffffffffc0200cba:	5c378793          	addi	a5,a5,1475 # 5c28f5c3 <_binary_obj___user_matrix_out_size+0x5c28409b>
ffffffffc0200cbe:	0685                	addi	a3,a3,1
ffffffffc0200cc0:	1702                	slli	a4,a4,0x20
ffffffffc0200cc2:	973e                	add	a4,a4,a5
ffffffffc0200cc4:	0026d793          	srli	a5,a3,0x2
ffffffffc0200cc8:	02e7b7b3          	mulhu	a5,a5,a4
ffffffffc0200ccc:	06400593          	li	a1,100
ffffffffc0200cd0:	000b0717          	auipc	a4,0xb0
ffffffffc0200cd4:	7cd73823          	sd	a3,2000(a4) # ffffffffc02b14a0 <ticks>
ffffffffc0200cd8:	8389                	srli	a5,a5,0x2
ffffffffc0200cda:	02b787b3          	mul	a5,a5,a1
ffffffffc0200cde:	02f68163          	beq	a3,a5,ffffffffc0200d00 <interrupt_handler+0xb2>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200ce2:	60a2                	ld	ra,8(sp)
        sched_class_proc_tick(current);
ffffffffc0200ce4:	000b1517          	auipc	a0,0xb1
ffffffffc0200ce8:	83453503          	ld	a0,-1996(a0) # ffffffffc02b1518 <current>
}
ffffffffc0200cec:	0141                	addi	sp,sp,16
        sched_class_proc_tick(current);
ffffffffc0200cee:	6300406f          	j	ffffffffc020531e <sched_class_proc_tick>
        cprintf("Supervisor external interrupt\n");
ffffffffc0200cf2:	00005517          	auipc	a0,0x5
ffffffffc0200cf6:	70e50513          	addi	a0,a0,1806 # ffffffffc0206400 <etext+0x8fc>
ffffffffc0200cfa:	ce2ff06f          	j	ffffffffc02001dc <cprintf>
        print_trapframe(tf);
ffffffffc0200cfe:	b5fd                	j	ffffffffc0200bec <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200d00:	00005517          	auipc	a0,0x5
ffffffffc0200d04:	6b050513          	addi	a0,a0,1712 # ffffffffc02063b0 <etext+0x8ac>
ffffffffc0200d08:	cd4ff0ef          	jal	ffffffffc02001dc <cprintf>
    print_count++;
ffffffffc0200d0c:	000b0797          	auipc	a5,0xb0
ffffffffc0200d10:	7ac7a783          	lw	a5,1964(a5) # ffffffffc02b14b8 <print_count.0>
    if (print_count == 10) {
ffffffffc0200d14:	4729                	li	a4,10
    print_count++;
ffffffffc0200d16:	2785                	addiw	a5,a5,1
ffffffffc0200d18:	000b0697          	auipc	a3,0xb0
ffffffffc0200d1c:	7af6a023          	sw	a5,1952(a3) # ffffffffc02b14b8 <print_count.0>
    if (print_count == 10) {
ffffffffc0200d20:	fce791e3          	bne	a5,a4,ffffffffc0200ce2 <interrupt_handler+0x94>
        cprintf("End of Test.\n");
ffffffffc0200d24:	00005517          	auipc	a0,0x5
ffffffffc0200d28:	69c50513          	addi	a0,a0,1692 # ffffffffc02063c0 <etext+0x8bc>
ffffffffc0200d2c:	cb0ff0ef          	jal	ffffffffc02001dc <cprintf>
        panic("EOT: kernel seems ok.");
ffffffffc0200d30:	00005617          	auipc	a2,0x5
ffffffffc0200d34:	6a060613          	addi	a2,a2,1696 # ffffffffc02063d0 <etext+0x8cc>
ffffffffc0200d38:	45f9                	li	a1,30
ffffffffc0200d3a:	00005517          	auipc	a0,0x5
ffffffffc0200d3e:	6ae50513          	addi	a0,a0,1710 # ffffffffc02063e8 <etext+0x8e4>
ffffffffc0200d42:	f4cff0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0200d46 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200d46:	11853783          	ld	a5,280(a0)
ffffffffc0200d4a:	473d                	li	a4,15
ffffffffc0200d4c:	10f76e63          	bltu	a4,a5,ffffffffc0200e68 <exception_handler+0x122>
ffffffffc0200d50:	00007717          	auipc	a4,0x7
ffffffffc0200d54:	cf870713          	addi	a4,a4,-776 # ffffffffc0207a48 <commands+0x78>
ffffffffc0200d58:	078a                	slli	a5,a5,0x2
ffffffffc0200d5a:	97ba                	add	a5,a5,a4
ffffffffc0200d5c:	439c                	lw	a5,0(a5)
{
ffffffffc0200d5e:	1101                	addi	sp,sp,-32
ffffffffc0200d60:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200d62:	97ba                	add	a5,a5,a4
ffffffffc0200d64:	86aa                	mv	a3,a0
ffffffffc0200d66:	8782                	jr	a5
ffffffffc0200d68:	e42a                	sd	a0,8(sp)
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200d6a:	00005517          	auipc	a0,0x5
ffffffffc0200d6e:	78650513          	addi	a0,a0,1926 # ffffffffc02064f0 <etext+0x9ec>
ffffffffc0200d72:	c6aff0ef          	jal	ffffffffc02001dc <cprintf>
        tf->epc += 4;
ffffffffc0200d76:	66a2                	ld	a3,8(sp)
ffffffffc0200d78:	1086b783          	ld	a5,264(a3)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200d7c:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200d7e:	0791                	addi	a5,a5,4
ffffffffc0200d80:	10f6b423          	sd	a5,264(a3)
}
ffffffffc0200d84:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200d86:	0410406f          	j	ffffffffc02055c6 <syscall>
}
ffffffffc0200d8a:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200d8c:	00005517          	auipc	a0,0x5
ffffffffc0200d90:	78450513          	addi	a0,a0,1924 # ffffffffc0206510 <etext+0xa0c>
}
ffffffffc0200d94:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200d96:	c46ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200d9a:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200d9c:	00005517          	auipc	a0,0x5
ffffffffc0200da0:	79450513          	addi	a0,a0,1940 # ffffffffc0206530 <etext+0xa2c>
}
ffffffffc0200da4:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200da6:	c36ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200daa:	60e2                	ld	ra,24(sp)
        cprintf("Instruction page fault\n");
ffffffffc0200dac:	00005517          	auipc	a0,0x5
ffffffffc0200db0:	7a450513          	addi	a0,a0,1956 # ffffffffc0206550 <etext+0xa4c>
}
ffffffffc0200db4:	6105                	addi	sp,sp,32
        cprintf("Instruction page fault\n");
ffffffffc0200db6:	c26ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200dba:	60e2                	ld	ra,24(sp)
        cprintf("Load page fault\n");
ffffffffc0200dbc:	00005517          	auipc	a0,0x5
ffffffffc0200dc0:	7ac50513          	addi	a0,a0,1964 # ffffffffc0206568 <etext+0xa64>
}
ffffffffc0200dc4:	6105                	addi	sp,sp,32
        cprintf("Load page fault\n");
ffffffffc0200dc6:	c16ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200dca:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO page fault\n");
ffffffffc0200dcc:	00005517          	auipc	a0,0x5
ffffffffc0200dd0:	7b450513          	addi	a0,a0,1972 # ffffffffc0206580 <etext+0xa7c>
}
ffffffffc0200dd4:	6105                	addi	sp,sp,32
        cprintf("Store/AMO page fault\n");
ffffffffc0200dd6:	c06ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200dda:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200ddc:	00005517          	auipc	a0,0x5
ffffffffc0200de0:	64450513          	addi	a0,a0,1604 # ffffffffc0206420 <etext+0x91c>
}
ffffffffc0200de4:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200de6:	bf6ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200dea:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200dec:	00005517          	auipc	a0,0x5
ffffffffc0200df0:	65450513          	addi	a0,a0,1620 # ffffffffc0206440 <etext+0x93c>
}
ffffffffc0200df4:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200df6:	be6ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200dfa:	60e2                	ld	ra,24(sp)
        cprintf("Illegal instruction\n");
ffffffffc0200dfc:	00005517          	auipc	a0,0x5
ffffffffc0200e00:	66450513          	addi	a0,a0,1636 # ffffffffc0206460 <etext+0x95c>
}
ffffffffc0200e04:	6105                	addi	sp,sp,32
        cprintf("Illegal instruction\n");
ffffffffc0200e06:	bd6ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200e0a:	60e2                	ld	ra,24(sp)
        cprintf("Breakpoint\n");
ffffffffc0200e0c:	00005517          	auipc	a0,0x5
ffffffffc0200e10:	66c50513          	addi	a0,a0,1644 # ffffffffc0206478 <etext+0x974>
}
ffffffffc0200e14:	6105                	addi	sp,sp,32
        cprintf("Breakpoint\n");
ffffffffc0200e16:	bc6ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200e1a:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200e1c:	00005517          	auipc	a0,0x5
ffffffffc0200e20:	66c50513          	addi	a0,a0,1644 # ffffffffc0206488 <etext+0x984>
}
ffffffffc0200e24:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200e26:	bb6ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200e2a:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200e2c:	00005517          	auipc	a0,0x5
ffffffffc0200e30:	67c50513          	addi	a0,a0,1660 # ffffffffc02064a8 <etext+0x9a4>
}
ffffffffc0200e34:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200e36:	ba6ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200e3a:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200e3c:	00005517          	auipc	a0,0x5
ffffffffc0200e40:	69c50513          	addi	a0,a0,1692 # ffffffffc02064d8 <etext+0x9d4>
}
ffffffffc0200e44:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200e46:	b96ff06f          	j	ffffffffc02001dc <cprintf>
}
ffffffffc0200e4a:	60e2                	ld	ra,24(sp)
ffffffffc0200e4c:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200e4e:	bb79                	j	ffffffffc0200bec <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200e50:	00005617          	auipc	a2,0x5
ffffffffc0200e54:	67060613          	addi	a2,a2,1648 # ffffffffc02064c0 <etext+0x9bc>
ffffffffc0200e58:	0c100593          	li	a1,193
ffffffffc0200e5c:	00005517          	auipc	a0,0x5
ffffffffc0200e60:	58c50513          	addi	a0,a0,1420 # ffffffffc02063e8 <etext+0x8e4>
ffffffffc0200e64:	e2aff0ef          	jal	ffffffffc020048e <__panic>
        print_trapframe(tf);
ffffffffc0200e68:	b351                	j	ffffffffc0200bec <print_trapframe>

ffffffffc0200e6a <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200e6a:	000b0717          	auipc	a4,0xb0
ffffffffc0200e6e:	6ae73703          	ld	a4,1710(a4) # ffffffffc02b1518 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e72:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200e76:	cf21                	beqz	a4,ffffffffc0200ece <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e78:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200e7c:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200e80:	1101                	addi	sp,sp,-32
ffffffffc0200e82:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200e84:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200e88:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200e8a:	e432                	sd	a2,8(sp)
ffffffffc0200e8c:	e042                	sd	a6,0(sp)
ffffffffc0200e8e:	0205c763          	bltz	a1,ffffffffc0200ebc <trap+0x52>
        exception_handler(tf);
ffffffffc0200e92:	eb5ff0ef          	jal	ffffffffc0200d46 <exception_handler>
ffffffffc0200e96:	6622                	ld	a2,8(sp)
ffffffffc0200e98:	6802                	ld	a6,0(sp)
ffffffffc0200e9a:	000b0697          	auipc	a3,0xb0
ffffffffc0200e9e:	67e68693          	addi	a3,a3,1662 # ffffffffc02b1518 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200ea2:	6298                	ld	a4,0(a3)
ffffffffc0200ea4:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200ea8:	e619                	bnez	a2,ffffffffc0200eb6 <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200eaa:	0b072783          	lw	a5,176(a4)
ffffffffc0200eae:	8b85                	andi	a5,a5,1
ffffffffc0200eb0:	e79d                	bnez	a5,ffffffffc0200ede <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200eb2:	6f1c                	ld	a5,24(a4)
ffffffffc0200eb4:	e38d                	bnez	a5,ffffffffc0200ed6 <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200eb6:	60e2                	ld	ra,24(sp)
ffffffffc0200eb8:	6105                	addi	sp,sp,32
ffffffffc0200eba:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200ebc:	d93ff0ef          	jal	ffffffffc0200c4e <interrupt_handler>
ffffffffc0200ec0:	6802                	ld	a6,0(sp)
ffffffffc0200ec2:	6622                	ld	a2,8(sp)
ffffffffc0200ec4:	000b0697          	auipc	a3,0xb0
ffffffffc0200ec8:	65468693          	addi	a3,a3,1620 # ffffffffc02b1518 <current>
ffffffffc0200ecc:	bfd9                	j	ffffffffc0200ea2 <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200ece:	0005c363          	bltz	a1,ffffffffc0200ed4 <trap+0x6a>
        exception_handler(tf);
ffffffffc0200ed2:	bd95                	j	ffffffffc0200d46 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200ed4:	bbad                	j	ffffffffc0200c4e <interrupt_handler>
}
ffffffffc0200ed6:	60e2                	ld	ra,24(sp)
ffffffffc0200ed8:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200eda:	5b80406f          	j	ffffffffc0205492 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200ede:	555d                	li	a0,-9
ffffffffc0200ee0:	5d2030ef          	jal	ffffffffc02044b2 <do_exit>
            if (current->need_resched)
ffffffffc0200ee4:	000b0717          	auipc	a4,0xb0
ffffffffc0200ee8:	63473703          	ld	a4,1588(a4) # ffffffffc02b1518 <current>
ffffffffc0200eec:	b7d9                	j	ffffffffc0200eb2 <trap+0x48>
	...

ffffffffc0200ef0 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ef0:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200ef4:	00011463          	bnez	sp,ffffffffc0200efc <__alltraps+0xc>
ffffffffc0200ef8:	14002173          	csrr	sp,sscratch
ffffffffc0200efc:	712d                	addi	sp,sp,-288
ffffffffc0200efe:	e002                	sd	zero,0(sp)
ffffffffc0200f00:	e406                	sd	ra,8(sp)
ffffffffc0200f02:	ec0e                	sd	gp,24(sp)
ffffffffc0200f04:	f012                	sd	tp,32(sp)
ffffffffc0200f06:	f416                	sd	t0,40(sp)
ffffffffc0200f08:	f81a                	sd	t1,48(sp)
ffffffffc0200f0a:	fc1e                	sd	t2,56(sp)
ffffffffc0200f0c:	e0a2                	sd	s0,64(sp)
ffffffffc0200f0e:	e4a6                	sd	s1,72(sp)
ffffffffc0200f10:	e8aa                	sd	a0,80(sp)
ffffffffc0200f12:	ecae                	sd	a1,88(sp)
ffffffffc0200f14:	f0b2                	sd	a2,96(sp)
ffffffffc0200f16:	f4b6                	sd	a3,104(sp)
ffffffffc0200f18:	f8ba                	sd	a4,112(sp)
ffffffffc0200f1a:	fcbe                	sd	a5,120(sp)
ffffffffc0200f1c:	e142                	sd	a6,128(sp)
ffffffffc0200f1e:	e546                	sd	a7,136(sp)
ffffffffc0200f20:	e94a                	sd	s2,144(sp)
ffffffffc0200f22:	ed4e                	sd	s3,152(sp)
ffffffffc0200f24:	f152                	sd	s4,160(sp)
ffffffffc0200f26:	f556                	sd	s5,168(sp)
ffffffffc0200f28:	f95a                	sd	s6,176(sp)
ffffffffc0200f2a:	fd5e                	sd	s7,184(sp)
ffffffffc0200f2c:	e1e2                	sd	s8,192(sp)
ffffffffc0200f2e:	e5e6                	sd	s9,200(sp)
ffffffffc0200f30:	e9ea                	sd	s10,208(sp)
ffffffffc0200f32:	edee                	sd	s11,216(sp)
ffffffffc0200f34:	f1f2                	sd	t3,224(sp)
ffffffffc0200f36:	f5f6                	sd	t4,232(sp)
ffffffffc0200f38:	f9fa                	sd	t5,240(sp)
ffffffffc0200f3a:	fdfe                	sd	t6,248(sp)
ffffffffc0200f3c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200f40:	100024f3          	csrr	s1,sstatus
ffffffffc0200f44:	14102973          	csrr	s2,sepc
ffffffffc0200f48:	143029f3          	csrr	s3,stval
ffffffffc0200f4c:	14202a73          	csrr	s4,scause
ffffffffc0200f50:	e822                	sd	s0,16(sp)
ffffffffc0200f52:	e226                	sd	s1,256(sp)
ffffffffc0200f54:	e64a                	sd	s2,264(sp)
ffffffffc0200f56:	ea4e                	sd	s3,272(sp)
ffffffffc0200f58:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200f5a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200f5c:	f0fff0ef          	jal	ffffffffc0200e6a <trap>

ffffffffc0200f60 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200f60:	6492                	ld	s1,256(sp)
ffffffffc0200f62:	6932                	ld	s2,264(sp)
ffffffffc0200f64:	1004f413          	andi	s0,s1,256
ffffffffc0200f68:	e401                	bnez	s0,ffffffffc0200f70 <__trapret+0x10>
ffffffffc0200f6a:	1200                	addi	s0,sp,288
ffffffffc0200f6c:	14041073          	csrw	sscratch,s0
ffffffffc0200f70:	10049073          	csrw	sstatus,s1
ffffffffc0200f74:	14191073          	csrw	sepc,s2
ffffffffc0200f78:	60a2                	ld	ra,8(sp)
ffffffffc0200f7a:	61e2                	ld	gp,24(sp)
ffffffffc0200f7c:	7202                	ld	tp,32(sp)
ffffffffc0200f7e:	72a2                	ld	t0,40(sp)
ffffffffc0200f80:	7342                	ld	t1,48(sp)
ffffffffc0200f82:	73e2                	ld	t2,56(sp)
ffffffffc0200f84:	6406                	ld	s0,64(sp)
ffffffffc0200f86:	64a6                	ld	s1,72(sp)
ffffffffc0200f88:	6546                	ld	a0,80(sp)
ffffffffc0200f8a:	65e6                	ld	a1,88(sp)
ffffffffc0200f8c:	7606                	ld	a2,96(sp)
ffffffffc0200f8e:	76a6                	ld	a3,104(sp)
ffffffffc0200f90:	7746                	ld	a4,112(sp)
ffffffffc0200f92:	77e6                	ld	a5,120(sp)
ffffffffc0200f94:	680a                	ld	a6,128(sp)
ffffffffc0200f96:	68aa                	ld	a7,136(sp)
ffffffffc0200f98:	694a                	ld	s2,144(sp)
ffffffffc0200f9a:	69ea                	ld	s3,152(sp)
ffffffffc0200f9c:	7a0a                	ld	s4,160(sp)
ffffffffc0200f9e:	7aaa                	ld	s5,168(sp)
ffffffffc0200fa0:	7b4a                	ld	s6,176(sp)
ffffffffc0200fa2:	7bea                	ld	s7,184(sp)
ffffffffc0200fa4:	6c0e                	ld	s8,192(sp)
ffffffffc0200fa6:	6cae                	ld	s9,200(sp)
ffffffffc0200fa8:	6d4e                	ld	s10,208(sp)
ffffffffc0200faa:	6dee                	ld	s11,216(sp)
ffffffffc0200fac:	7e0e                	ld	t3,224(sp)
ffffffffc0200fae:	7eae                	ld	t4,232(sp)
ffffffffc0200fb0:	7f4e                	ld	t5,240(sp)
ffffffffc0200fb2:	7fee                	ld	t6,248(sp)
ffffffffc0200fb4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200fb6:	10200073          	sret

ffffffffc0200fba <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200fba:	812a                	mv	sp,a0
ffffffffc0200fbc:	b755                	j	ffffffffc0200f60 <__trapret>

ffffffffc0200fbe <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200fbe:	000b0797          	auipc	a5,0xb0
ffffffffc0200fc2:	50278793          	addi	a5,a5,1282 # ffffffffc02b14c0 <free_area>
ffffffffc0200fc6:	e79c                	sd	a5,8(a5)
ffffffffc0200fc8:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200fca:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200fce:	8082                	ret

ffffffffc0200fd0 <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200fd0:	000b0517          	auipc	a0,0xb0
ffffffffc0200fd4:	50056503          	lwu	a0,1280(a0) # ffffffffc02b14d0 <free_area+0x10>
ffffffffc0200fd8:	8082                	ret

ffffffffc0200fda <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200fda:	711d                	addi	sp,sp,-96
ffffffffc0200fdc:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200fde:	000b0917          	auipc	s2,0xb0
ffffffffc0200fe2:	4e290913          	addi	s2,s2,1250 # ffffffffc02b14c0 <free_area>
ffffffffc0200fe6:	00893783          	ld	a5,8(s2)
ffffffffc0200fea:	ec86                	sd	ra,88(sp)
ffffffffc0200fec:	e8a2                	sd	s0,80(sp)
ffffffffc0200fee:	e4a6                	sd	s1,72(sp)
ffffffffc0200ff0:	fc4e                	sd	s3,56(sp)
ffffffffc0200ff2:	f852                	sd	s4,48(sp)
ffffffffc0200ff4:	f456                	sd	s5,40(sp)
ffffffffc0200ff6:	f05a                	sd	s6,32(sp)
ffffffffc0200ff8:	ec5e                	sd	s7,24(sp)
ffffffffc0200ffa:	e862                	sd	s8,16(sp)
ffffffffc0200ffc:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200ffe:	2f278363          	beq	a5,s2,ffffffffc02012e4 <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0201002:	4401                	li	s0,0
ffffffffc0201004:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201006:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020100a:	8b09                	andi	a4,a4,2
ffffffffc020100c:	2e070063          	beqz	a4,ffffffffc02012ec <default_check+0x312>
        count++, total += p->property;
ffffffffc0201010:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201014:	679c                	ld	a5,8(a5)
ffffffffc0201016:	2485                	addiw	s1,s1,1
ffffffffc0201018:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020101a:	ff2796e3          	bne	a5,s2,ffffffffc0201006 <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc020101e:	89a2                	mv	s3,s0
ffffffffc0201020:	741000ef          	jal	ffffffffc0201f60 <nr_free_pages>
ffffffffc0201024:	73351463          	bne	a0,s3,ffffffffc020174c <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201028:	4505                	li	a0,1
ffffffffc020102a:	6c5000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc020102e:	8a2a                	mv	s4,a0
ffffffffc0201030:	44050e63          	beqz	a0,ffffffffc020148c <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201034:	4505                	li	a0,1
ffffffffc0201036:	6b9000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc020103a:	89aa                	mv	s3,a0
ffffffffc020103c:	72050863          	beqz	a0,ffffffffc020176c <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201040:	4505                	li	a0,1
ffffffffc0201042:	6ad000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc0201046:	8aaa                	mv	s5,a0
ffffffffc0201048:	4c050263          	beqz	a0,ffffffffc020150c <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020104c:	40a987b3          	sub	a5,s3,a0
ffffffffc0201050:	40aa0733          	sub	a4,s4,a0
ffffffffc0201054:	0017b793          	seqz	a5,a5
ffffffffc0201058:	00173713          	seqz	a4,a4
ffffffffc020105c:	8fd9                	or	a5,a5,a4
ffffffffc020105e:	30079763          	bnez	a5,ffffffffc020136c <default_check+0x392>
ffffffffc0201062:	313a0563          	beq	s4,s3,ffffffffc020136c <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201066:	000a2783          	lw	a5,0(s4)
ffffffffc020106a:	2a079163          	bnez	a5,ffffffffc020130c <default_check+0x332>
ffffffffc020106e:	0009a783          	lw	a5,0(s3)
ffffffffc0201072:	28079d63          	bnez	a5,ffffffffc020130c <default_check+0x332>
ffffffffc0201076:	411c                	lw	a5,0(a0)
ffffffffc0201078:	28079a63          	bnez	a5,ffffffffc020130c <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc020107c:	000b0797          	auipc	a5,0xb0
ffffffffc0201080:	48c7b783          	ld	a5,1164(a5) # ffffffffc02b1508 <pages>
ffffffffc0201084:	00007617          	auipc	a2,0x7
ffffffffc0201088:	45c63603          	ld	a2,1116(a2) # ffffffffc02084e0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020108c:	000b0697          	auipc	a3,0xb0
ffffffffc0201090:	4746b683          	ld	a3,1140(a3) # ffffffffc02b1500 <npage>
ffffffffc0201094:	40fa0733          	sub	a4,s4,a5
ffffffffc0201098:	8719                	srai	a4,a4,0x6
ffffffffc020109a:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc020109c:	0732                	slli	a4,a4,0xc
ffffffffc020109e:	06b2                	slli	a3,a3,0xc
ffffffffc02010a0:	2ad77663          	bgeu	a4,a3,ffffffffc020134c <default_check+0x372>
    return page - pages + nbase;
ffffffffc02010a4:	40f98733          	sub	a4,s3,a5
ffffffffc02010a8:	8719                	srai	a4,a4,0x6
ffffffffc02010aa:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010ac:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02010ae:	4cd77f63          	bgeu	a4,a3,ffffffffc020158c <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc02010b2:	40f507b3          	sub	a5,a0,a5
ffffffffc02010b6:	8799                	srai	a5,a5,0x6
ffffffffc02010b8:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02010ba:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010bc:	32d7f863          	bgeu	a5,a3,ffffffffc02013ec <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc02010c0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02010c2:	00093c03          	ld	s8,0(s2)
ffffffffc02010c6:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc02010ca:	000b0b17          	auipc	s6,0xb0
ffffffffc02010ce:	406b2b03          	lw	s6,1030(s6) # ffffffffc02b14d0 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc02010d2:	01293023          	sd	s2,0(s2)
ffffffffc02010d6:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc02010da:	000b0797          	auipc	a5,0xb0
ffffffffc02010de:	3e07ab23          	sw	zero,1014(a5) # ffffffffc02b14d0 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02010e2:	60d000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc02010e6:	2e051363          	bnez	a0,ffffffffc02013cc <default_check+0x3f2>
    free_page(p0);
ffffffffc02010ea:	8552                	mv	a0,s4
ffffffffc02010ec:	4585                	li	a1,1
ffffffffc02010ee:	63b000ef          	jal	ffffffffc0201f28 <free_pages>
    free_page(p1);
ffffffffc02010f2:	854e                	mv	a0,s3
ffffffffc02010f4:	4585                	li	a1,1
ffffffffc02010f6:	633000ef          	jal	ffffffffc0201f28 <free_pages>
    free_page(p2);
ffffffffc02010fa:	8556                	mv	a0,s5
ffffffffc02010fc:	4585                	li	a1,1
ffffffffc02010fe:	62b000ef          	jal	ffffffffc0201f28 <free_pages>
    assert(nr_free == 3);
ffffffffc0201102:	000b0717          	auipc	a4,0xb0
ffffffffc0201106:	3ce72703          	lw	a4,974(a4) # ffffffffc02b14d0 <free_area+0x10>
ffffffffc020110a:	478d                	li	a5,3
ffffffffc020110c:	2af71063          	bne	a4,a5,ffffffffc02013ac <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201110:	4505                	li	a0,1
ffffffffc0201112:	5dd000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc0201116:	89aa                	mv	s3,a0
ffffffffc0201118:	26050a63          	beqz	a0,ffffffffc020138c <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020111c:	4505                	li	a0,1
ffffffffc020111e:	5d1000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc0201122:	8aaa                	mv	s5,a0
ffffffffc0201124:	3c050463          	beqz	a0,ffffffffc02014ec <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201128:	4505                	li	a0,1
ffffffffc020112a:	5c5000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc020112e:	8a2a                	mv	s4,a0
ffffffffc0201130:	38050e63          	beqz	a0,ffffffffc02014cc <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc0201134:	4505                	li	a0,1
ffffffffc0201136:	5b9000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc020113a:	36051963          	bnez	a0,ffffffffc02014ac <default_check+0x4d2>
    free_page(p0);
ffffffffc020113e:	4585                	li	a1,1
ffffffffc0201140:	854e                	mv	a0,s3
ffffffffc0201142:	5e7000ef          	jal	ffffffffc0201f28 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201146:	00893783          	ld	a5,8(s2)
ffffffffc020114a:	1f278163          	beq	a5,s2,ffffffffc020132c <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc020114e:	4505                	li	a0,1
ffffffffc0201150:	59f000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc0201154:	8caa                	mv	s9,a0
ffffffffc0201156:	30a99b63          	bne	s3,a0,ffffffffc020146c <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc020115a:	4505                	li	a0,1
ffffffffc020115c:	593000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc0201160:	2e051663          	bnez	a0,ffffffffc020144c <default_check+0x472>
    assert(nr_free == 0);
ffffffffc0201164:	000b0797          	auipc	a5,0xb0
ffffffffc0201168:	36c7a783          	lw	a5,876(a5) # ffffffffc02b14d0 <free_area+0x10>
ffffffffc020116c:	2c079063          	bnez	a5,ffffffffc020142c <default_check+0x452>
    free_page(p);
ffffffffc0201170:	8566                	mv	a0,s9
ffffffffc0201172:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201174:	01893023          	sd	s8,0(s2)
ffffffffc0201178:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc020117c:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0201180:	5a9000ef          	jal	ffffffffc0201f28 <free_pages>
    free_page(p1);
ffffffffc0201184:	8556                	mv	a0,s5
ffffffffc0201186:	4585                	li	a1,1
ffffffffc0201188:	5a1000ef          	jal	ffffffffc0201f28 <free_pages>
    free_page(p2);
ffffffffc020118c:	8552                	mv	a0,s4
ffffffffc020118e:	4585                	li	a1,1
ffffffffc0201190:	599000ef          	jal	ffffffffc0201f28 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201194:	4515                	li	a0,5
ffffffffc0201196:	559000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc020119a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020119c:	26050863          	beqz	a0,ffffffffc020140c <default_check+0x432>
ffffffffc02011a0:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc02011a2:	8b89                	andi	a5,a5,2
ffffffffc02011a4:	54079463          	bnez	a5,ffffffffc02016ec <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02011a8:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02011aa:	00093b83          	ld	s7,0(s2)
ffffffffc02011ae:	00893b03          	ld	s6,8(s2)
ffffffffc02011b2:	01293023          	sd	s2,0(s2)
ffffffffc02011b6:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc02011ba:	535000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc02011be:	50051763          	bnez	a0,ffffffffc02016cc <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02011c2:	08098a13          	addi	s4,s3,128
ffffffffc02011c6:	8552                	mv	a0,s4
ffffffffc02011c8:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02011ca:	000b0c17          	auipc	s8,0xb0
ffffffffc02011ce:	306c2c03          	lw	s8,774(s8) # ffffffffc02b14d0 <free_area+0x10>
    nr_free = 0;
ffffffffc02011d2:	000b0797          	auipc	a5,0xb0
ffffffffc02011d6:	2e07af23          	sw	zero,766(a5) # ffffffffc02b14d0 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02011da:	54f000ef          	jal	ffffffffc0201f28 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02011de:	4511                	li	a0,4
ffffffffc02011e0:	50f000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc02011e4:	4c051463          	bnez	a0,ffffffffc02016ac <default_check+0x6d2>
ffffffffc02011e8:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02011ec:	8b89                	andi	a5,a5,2
ffffffffc02011ee:	48078f63          	beqz	a5,ffffffffc020168c <default_check+0x6b2>
ffffffffc02011f2:	0909a503          	lw	a0,144(s3)
ffffffffc02011f6:	478d                	li	a5,3
ffffffffc02011f8:	48f51a63          	bne	a0,a5,ffffffffc020168c <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02011fc:	4f3000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc0201200:	8aaa                	mv	s5,a0
ffffffffc0201202:	46050563          	beqz	a0,ffffffffc020166c <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc0201206:	4505                	li	a0,1
ffffffffc0201208:	4e7000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc020120c:	44051063          	bnez	a0,ffffffffc020164c <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc0201210:	415a1e63          	bne	s4,s5,ffffffffc020162c <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201214:	4585                	li	a1,1
ffffffffc0201216:	854e                	mv	a0,s3
ffffffffc0201218:	511000ef          	jal	ffffffffc0201f28 <free_pages>
    free_pages(p1, 3);
ffffffffc020121c:	8552                	mv	a0,s4
ffffffffc020121e:	458d                	li	a1,3
ffffffffc0201220:	509000ef          	jal	ffffffffc0201f28 <free_pages>
ffffffffc0201224:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201228:	8b89                	andi	a5,a5,2
ffffffffc020122a:	3e078163          	beqz	a5,ffffffffc020160c <default_check+0x632>
ffffffffc020122e:	0109aa83          	lw	s5,16(s3)
ffffffffc0201232:	4785                	li	a5,1
ffffffffc0201234:	3cfa9c63          	bne	s5,a5,ffffffffc020160c <default_check+0x632>
ffffffffc0201238:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020123c:	8b89                	andi	a5,a5,2
ffffffffc020123e:	3a078763          	beqz	a5,ffffffffc02015ec <default_check+0x612>
ffffffffc0201242:	010a2703          	lw	a4,16(s4)
ffffffffc0201246:	478d                	li	a5,3
ffffffffc0201248:	3af71263          	bne	a4,a5,ffffffffc02015ec <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020124c:	8556                	mv	a0,s5
ffffffffc020124e:	4a1000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc0201252:	36a99d63          	bne	s3,a0,ffffffffc02015cc <default_check+0x5f2>
    free_page(p0);
ffffffffc0201256:	85d6                	mv	a1,s5
ffffffffc0201258:	4d1000ef          	jal	ffffffffc0201f28 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020125c:	4509                	li	a0,2
ffffffffc020125e:	491000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc0201262:	34aa1563          	bne	s4,a0,ffffffffc02015ac <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc0201266:	4589                	li	a1,2
ffffffffc0201268:	4c1000ef          	jal	ffffffffc0201f28 <free_pages>
    free_page(p2);
ffffffffc020126c:	04098513          	addi	a0,s3,64
ffffffffc0201270:	85d6                	mv	a1,s5
ffffffffc0201272:	4b7000ef          	jal	ffffffffc0201f28 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201276:	4515                	li	a0,5
ffffffffc0201278:	477000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc020127c:	89aa                	mv	s3,a0
ffffffffc020127e:	48050763          	beqz	a0,ffffffffc020170c <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc0201282:	8556                	mv	a0,s5
ffffffffc0201284:	46b000ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc0201288:	2e051263          	bnez	a0,ffffffffc020156c <default_check+0x592>

    assert(nr_free == 0);
ffffffffc020128c:	000b0797          	auipc	a5,0xb0
ffffffffc0201290:	2447a783          	lw	a5,580(a5) # ffffffffc02b14d0 <free_area+0x10>
ffffffffc0201294:	2a079c63          	bnez	a5,ffffffffc020154c <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201298:	854e                	mv	a0,s3
ffffffffc020129a:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc020129c:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc02012a0:	01793023          	sd	s7,0(s2)
ffffffffc02012a4:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc02012a8:	481000ef          	jal	ffffffffc0201f28 <free_pages>
    return listelm->next;
ffffffffc02012ac:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc02012b0:	01278963          	beq	a5,s2,ffffffffc02012c2 <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc02012b4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02012b8:	679c                	ld	a5,8(a5)
ffffffffc02012ba:	34fd                	addiw	s1,s1,-1
ffffffffc02012bc:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc02012be:	ff279be3          	bne	a5,s2,ffffffffc02012b4 <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc02012c2:	26049563          	bnez	s1,ffffffffc020152c <default_check+0x552>
    assert(total == 0);
ffffffffc02012c6:	46041363          	bnez	s0,ffffffffc020172c <default_check+0x752>
}
ffffffffc02012ca:	60e6                	ld	ra,88(sp)
ffffffffc02012cc:	6446                	ld	s0,80(sp)
ffffffffc02012ce:	64a6                	ld	s1,72(sp)
ffffffffc02012d0:	6906                	ld	s2,64(sp)
ffffffffc02012d2:	79e2                	ld	s3,56(sp)
ffffffffc02012d4:	7a42                	ld	s4,48(sp)
ffffffffc02012d6:	7aa2                	ld	s5,40(sp)
ffffffffc02012d8:	7b02                	ld	s6,32(sp)
ffffffffc02012da:	6be2                	ld	s7,24(sp)
ffffffffc02012dc:	6c42                	ld	s8,16(sp)
ffffffffc02012de:	6ca2                	ld	s9,8(sp)
ffffffffc02012e0:	6125                	addi	sp,sp,96
ffffffffc02012e2:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc02012e4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02012e6:	4401                	li	s0,0
ffffffffc02012e8:	4481                	li	s1,0
ffffffffc02012ea:	bb1d                	j	ffffffffc0201020 <default_check+0x46>
        assert(PageProperty(p));
ffffffffc02012ec:	00005697          	auipc	a3,0x5
ffffffffc02012f0:	2ac68693          	addi	a3,a3,684 # ffffffffc0206598 <etext+0xa94>
ffffffffc02012f4:	00005617          	auipc	a2,0x5
ffffffffc02012f8:	2b460613          	addi	a2,a2,692 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02012fc:	11000593          	li	a1,272
ffffffffc0201300:	00005517          	auipc	a0,0x5
ffffffffc0201304:	2c050513          	addi	a0,a0,704 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201308:	986ff0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020130c:	00005697          	auipc	a3,0x5
ffffffffc0201310:	37468693          	addi	a3,a3,884 # ffffffffc0206680 <etext+0xb7c>
ffffffffc0201314:	00005617          	auipc	a2,0x5
ffffffffc0201318:	29460613          	addi	a2,a2,660 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020131c:	0dc00593          	li	a1,220
ffffffffc0201320:	00005517          	auipc	a0,0x5
ffffffffc0201324:	2a050513          	addi	a0,a0,672 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201328:	966ff0ef          	jal	ffffffffc020048e <__panic>
    assert(!list_empty(&free_list));
ffffffffc020132c:	00005697          	auipc	a3,0x5
ffffffffc0201330:	41c68693          	addi	a3,a3,1052 # ffffffffc0206748 <etext+0xc44>
ffffffffc0201334:	00005617          	auipc	a2,0x5
ffffffffc0201338:	27460613          	addi	a2,a2,628 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020133c:	0f700593          	li	a1,247
ffffffffc0201340:	00005517          	auipc	a0,0x5
ffffffffc0201344:	28050513          	addi	a0,a0,640 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201348:	946ff0ef          	jal	ffffffffc020048e <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020134c:	00005697          	auipc	a3,0x5
ffffffffc0201350:	37468693          	addi	a3,a3,884 # ffffffffc02066c0 <etext+0xbbc>
ffffffffc0201354:	00005617          	auipc	a2,0x5
ffffffffc0201358:	25460613          	addi	a2,a2,596 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020135c:	0de00593          	li	a1,222
ffffffffc0201360:	00005517          	auipc	a0,0x5
ffffffffc0201364:	26050513          	addi	a0,a0,608 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201368:	926ff0ef          	jal	ffffffffc020048e <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020136c:	00005697          	auipc	a3,0x5
ffffffffc0201370:	2ec68693          	addi	a3,a3,748 # ffffffffc0206658 <etext+0xb54>
ffffffffc0201374:	00005617          	auipc	a2,0x5
ffffffffc0201378:	23460613          	addi	a2,a2,564 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020137c:	0db00593          	li	a1,219
ffffffffc0201380:	00005517          	auipc	a0,0x5
ffffffffc0201384:	24050513          	addi	a0,a0,576 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201388:	906ff0ef          	jal	ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020138c:	00005697          	auipc	a3,0x5
ffffffffc0201390:	26c68693          	addi	a3,a3,620 # ffffffffc02065f8 <etext+0xaf4>
ffffffffc0201394:	00005617          	auipc	a2,0x5
ffffffffc0201398:	21460613          	addi	a2,a2,532 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020139c:	0f000593          	li	a1,240
ffffffffc02013a0:	00005517          	auipc	a0,0x5
ffffffffc02013a4:	22050513          	addi	a0,a0,544 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02013a8:	8e6ff0ef          	jal	ffffffffc020048e <__panic>
    assert(nr_free == 3);
ffffffffc02013ac:	00005697          	auipc	a3,0x5
ffffffffc02013b0:	38c68693          	addi	a3,a3,908 # ffffffffc0206738 <etext+0xc34>
ffffffffc02013b4:	00005617          	auipc	a2,0x5
ffffffffc02013b8:	1f460613          	addi	a2,a2,500 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02013bc:	0ee00593          	li	a1,238
ffffffffc02013c0:	00005517          	auipc	a0,0x5
ffffffffc02013c4:	20050513          	addi	a0,a0,512 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02013c8:	8c6ff0ef          	jal	ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013cc:	00005697          	auipc	a3,0x5
ffffffffc02013d0:	35468693          	addi	a3,a3,852 # ffffffffc0206720 <etext+0xc1c>
ffffffffc02013d4:	00005617          	auipc	a2,0x5
ffffffffc02013d8:	1d460613          	addi	a2,a2,468 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02013dc:	0e900593          	li	a1,233
ffffffffc02013e0:	00005517          	auipc	a0,0x5
ffffffffc02013e4:	1e050513          	addi	a0,a0,480 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02013e8:	8a6ff0ef          	jal	ffffffffc020048e <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02013ec:	00005697          	auipc	a3,0x5
ffffffffc02013f0:	31468693          	addi	a3,a3,788 # ffffffffc0206700 <etext+0xbfc>
ffffffffc02013f4:	00005617          	auipc	a2,0x5
ffffffffc02013f8:	1b460613          	addi	a2,a2,436 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02013fc:	0e000593          	li	a1,224
ffffffffc0201400:	00005517          	auipc	a0,0x5
ffffffffc0201404:	1c050513          	addi	a0,a0,448 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201408:	886ff0ef          	jal	ffffffffc020048e <__panic>
    assert(p0 != NULL);
ffffffffc020140c:	00005697          	auipc	a3,0x5
ffffffffc0201410:	38468693          	addi	a3,a3,900 # ffffffffc0206790 <etext+0xc8c>
ffffffffc0201414:	00005617          	auipc	a2,0x5
ffffffffc0201418:	19460613          	addi	a2,a2,404 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020141c:	11800593          	li	a1,280
ffffffffc0201420:	00005517          	auipc	a0,0x5
ffffffffc0201424:	1a050513          	addi	a0,a0,416 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201428:	866ff0ef          	jal	ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020142c:	00005697          	auipc	a3,0x5
ffffffffc0201430:	35468693          	addi	a3,a3,852 # ffffffffc0206780 <etext+0xc7c>
ffffffffc0201434:	00005617          	auipc	a2,0x5
ffffffffc0201438:	17460613          	addi	a2,a2,372 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020143c:	0fd00593          	li	a1,253
ffffffffc0201440:	00005517          	auipc	a0,0x5
ffffffffc0201444:	18050513          	addi	a0,a0,384 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201448:	846ff0ef          	jal	ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020144c:	00005697          	auipc	a3,0x5
ffffffffc0201450:	2d468693          	addi	a3,a3,724 # ffffffffc0206720 <etext+0xc1c>
ffffffffc0201454:	00005617          	auipc	a2,0x5
ffffffffc0201458:	15460613          	addi	a2,a2,340 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020145c:	0fb00593          	li	a1,251
ffffffffc0201460:	00005517          	auipc	a0,0x5
ffffffffc0201464:	16050513          	addi	a0,a0,352 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201468:	826ff0ef          	jal	ffffffffc020048e <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020146c:	00005697          	auipc	a3,0x5
ffffffffc0201470:	2f468693          	addi	a3,a3,756 # ffffffffc0206760 <etext+0xc5c>
ffffffffc0201474:	00005617          	auipc	a2,0x5
ffffffffc0201478:	13460613          	addi	a2,a2,308 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020147c:	0fa00593          	li	a1,250
ffffffffc0201480:	00005517          	auipc	a0,0x5
ffffffffc0201484:	14050513          	addi	a0,a0,320 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201488:	806ff0ef          	jal	ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020148c:	00005697          	auipc	a3,0x5
ffffffffc0201490:	16c68693          	addi	a3,a3,364 # ffffffffc02065f8 <etext+0xaf4>
ffffffffc0201494:	00005617          	auipc	a2,0x5
ffffffffc0201498:	11460613          	addi	a2,a2,276 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020149c:	0d700593          	li	a1,215
ffffffffc02014a0:	00005517          	auipc	a0,0x5
ffffffffc02014a4:	12050513          	addi	a0,a0,288 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02014a8:	fe7fe0ef          	jal	ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014ac:	00005697          	auipc	a3,0x5
ffffffffc02014b0:	27468693          	addi	a3,a3,628 # ffffffffc0206720 <etext+0xc1c>
ffffffffc02014b4:	00005617          	auipc	a2,0x5
ffffffffc02014b8:	0f460613          	addi	a2,a2,244 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02014bc:	0f400593          	li	a1,244
ffffffffc02014c0:	00005517          	auipc	a0,0x5
ffffffffc02014c4:	10050513          	addi	a0,a0,256 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02014c8:	fc7fe0ef          	jal	ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02014cc:	00005697          	auipc	a3,0x5
ffffffffc02014d0:	16c68693          	addi	a3,a3,364 # ffffffffc0206638 <etext+0xb34>
ffffffffc02014d4:	00005617          	auipc	a2,0x5
ffffffffc02014d8:	0d460613          	addi	a2,a2,212 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02014dc:	0f200593          	li	a1,242
ffffffffc02014e0:	00005517          	auipc	a0,0x5
ffffffffc02014e4:	0e050513          	addi	a0,a0,224 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02014e8:	fa7fe0ef          	jal	ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02014ec:	00005697          	auipc	a3,0x5
ffffffffc02014f0:	12c68693          	addi	a3,a3,300 # ffffffffc0206618 <etext+0xb14>
ffffffffc02014f4:	00005617          	auipc	a2,0x5
ffffffffc02014f8:	0b460613          	addi	a2,a2,180 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02014fc:	0f100593          	li	a1,241
ffffffffc0201500:	00005517          	auipc	a0,0x5
ffffffffc0201504:	0c050513          	addi	a0,a0,192 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201508:	f87fe0ef          	jal	ffffffffc020048e <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020150c:	00005697          	auipc	a3,0x5
ffffffffc0201510:	12c68693          	addi	a3,a3,300 # ffffffffc0206638 <etext+0xb34>
ffffffffc0201514:	00005617          	auipc	a2,0x5
ffffffffc0201518:	09460613          	addi	a2,a2,148 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020151c:	0d900593          	li	a1,217
ffffffffc0201520:	00005517          	auipc	a0,0x5
ffffffffc0201524:	0a050513          	addi	a0,a0,160 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201528:	f67fe0ef          	jal	ffffffffc020048e <__panic>
    assert(count == 0);
ffffffffc020152c:	00005697          	auipc	a3,0x5
ffffffffc0201530:	3b468693          	addi	a3,a3,948 # ffffffffc02068e0 <etext+0xddc>
ffffffffc0201534:	00005617          	auipc	a2,0x5
ffffffffc0201538:	07460613          	addi	a2,a2,116 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020153c:	14600593          	li	a1,326
ffffffffc0201540:	00005517          	auipc	a0,0x5
ffffffffc0201544:	08050513          	addi	a0,a0,128 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201548:	f47fe0ef          	jal	ffffffffc020048e <__panic>
    assert(nr_free == 0);
ffffffffc020154c:	00005697          	auipc	a3,0x5
ffffffffc0201550:	23468693          	addi	a3,a3,564 # ffffffffc0206780 <etext+0xc7c>
ffffffffc0201554:	00005617          	auipc	a2,0x5
ffffffffc0201558:	05460613          	addi	a2,a2,84 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020155c:	13a00593          	li	a1,314
ffffffffc0201560:	00005517          	auipc	a0,0x5
ffffffffc0201564:	06050513          	addi	a0,a0,96 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201568:	f27fe0ef          	jal	ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020156c:	00005697          	auipc	a3,0x5
ffffffffc0201570:	1b468693          	addi	a3,a3,436 # ffffffffc0206720 <etext+0xc1c>
ffffffffc0201574:	00005617          	auipc	a2,0x5
ffffffffc0201578:	03460613          	addi	a2,a2,52 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020157c:	13800593          	li	a1,312
ffffffffc0201580:	00005517          	auipc	a0,0x5
ffffffffc0201584:	04050513          	addi	a0,a0,64 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201588:	f07fe0ef          	jal	ffffffffc020048e <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020158c:	00005697          	auipc	a3,0x5
ffffffffc0201590:	15468693          	addi	a3,a3,340 # ffffffffc02066e0 <etext+0xbdc>
ffffffffc0201594:	00005617          	auipc	a2,0x5
ffffffffc0201598:	01460613          	addi	a2,a2,20 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020159c:	0df00593          	li	a1,223
ffffffffc02015a0:	00005517          	auipc	a0,0x5
ffffffffc02015a4:	02050513          	addi	a0,a0,32 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02015a8:	ee7fe0ef          	jal	ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02015ac:	00005697          	auipc	a3,0x5
ffffffffc02015b0:	2f468693          	addi	a3,a3,756 # ffffffffc02068a0 <etext+0xd9c>
ffffffffc02015b4:	00005617          	auipc	a2,0x5
ffffffffc02015b8:	ff460613          	addi	a2,a2,-12 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02015bc:	13200593          	li	a1,306
ffffffffc02015c0:	00005517          	auipc	a0,0x5
ffffffffc02015c4:	00050513          	mv	a0,a0
ffffffffc02015c8:	ec7fe0ef          	jal	ffffffffc020048e <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02015cc:	00005697          	auipc	a3,0x5
ffffffffc02015d0:	2b468693          	addi	a3,a3,692 # ffffffffc0206880 <etext+0xd7c>
ffffffffc02015d4:	00005617          	auipc	a2,0x5
ffffffffc02015d8:	fd460613          	addi	a2,a2,-44 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02015dc:	13000593          	li	a1,304
ffffffffc02015e0:	00005517          	auipc	a0,0x5
ffffffffc02015e4:	fe050513          	addi	a0,a0,-32 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02015e8:	ea7fe0ef          	jal	ffffffffc020048e <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02015ec:	00005697          	auipc	a3,0x5
ffffffffc02015f0:	26c68693          	addi	a3,a3,620 # ffffffffc0206858 <etext+0xd54>
ffffffffc02015f4:	00005617          	auipc	a2,0x5
ffffffffc02015f8:	fb460613          	addi	a2,a2,-76 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02015fc:	12e00593          	li	a1,302
ffffffffc0201600:	00005517          	auipc	a0,0x5
ffffffffc0201604:	fc050513          	addi	a0,a0,-64 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201608:	e87fe0ef          	jal	ffffffffc020048e <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc020160c:	00005697          	auipc	a3,0x5
ffffffffc0201610:	22468693          	addi	a3,a3,548 # ffffffffc0206830 <etext+0xd2c>
ffffffffc0201614:	00005617          	auipc	a2,0x5
ffffffffc0201618:	f9460613          	addi	a2,a2,-108 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020161c:	12d00593          	li	a1,301
ffffffffc0201620:	00005517          	auipc	a0,0x5
ffffffffc0201624:	fa050513          	addi	a0,a0,-96 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201628:	e67fe0ef          	jal	ffffffffc020048e <__panic>
    assert(p0 + 2 == p1);
ffffffffc020162c:	00005697          	auipc	a3,0x5
ffffffffc0201630:	1f468693          	addi	a3,a3,500 # ffffffffc0206820 <etext+0xd1c>
ffffffffc0201634:	00005617          	auipc	a2,0x5
ffffffffc0201638:	f7460613          	addi	a2,a2,-140 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020163c:	12800593          	li	a1,296
ffffffffc0201640:	00005517          	auipc	a0,0x5
ffffffffc0201644:	f8050513          	addi	a0,a0,-128 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201648:	e47fe0ef          	jal	ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc020164c:	00005697          	auipc	a3,0x5
ffffffffc0201650:	0d468693          	addi	a3,a3,212 # ffffffffc0206720 <etext+0xc1c>
ffffffffc0201654:	00005617          	auipc	a2,0x5
ffffffffc0201658:	f5460613          	addi	a2,a2,-172 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020165c:	12700593          	li	a1,295
ffffffffc0201660:	00005517          	auipc	a0,0x5
ffffffffc0201664:	f6050513          	addi	a0,a0,-160 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201668:	e27fe0ef          	jal	ffffffffc020048e <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc020166c:	00005697          	auipc	a3,0x5
ffffffffc0201670:	19468693          	addi	a3,a3,404 # ffffffffc0206800 <etext+0xcfc>
ffffffffc0201674:	00005617          	auipc	a2,0x5
ffffffffc0201678:	f3460613          	addi	a2,a2,-204 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020167c:	12600593          	li	a1,294
ffffffffc0201680:	00005517          	auipc	a0,0x5
ffffffffc0201684:	f4050513          	addi	a0,a0,-192 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201688:	e07fe0ef          	jal	ffffffffc020048e <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc020168c:	00005697          	auipc	a3,0x5
ffffffffc0201690:	14468693          	addi	a3,a3,324 # ffffffffc02067d0 <etext+0xccc>
ffffffffc0201694:	00005617          	auipc	a2,0x5
ffffffffc0201698:	f1460613          	addi	a2,a2,-236 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020169c:	12500593          	li	a1,293
ffffffffc02016a0:	00005517          	auipc	a0,0x5
ffffffffc02016a4:	f2050513          	addi	a0,a0,-224 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02016a8:	de7fe0ef          	jal	ffffffffc020048e <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02016ac:	00005697          	auipc	a3,0x5
ffffffffc02016b0:	10c68693          	addi	a3,a3,268 # ffffffffc02067b8 <etext+0xcb4>
ffffffffc02016b4:	00005617          	auipc	a2,0x5
ffffffffc02016b8:	ef460613          	addi	a2,a2,-268 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02016bc:	12400593          	li	a1,292
ffffffffc02016c0:	00005517          	auipc	a0,0x5
ffffffffc02016c4:	f0050513          	addi	a0,a0,-256 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02016c8:	dc7fe0ef          	jal	ffffffffc020048e <__panic>
    assert(alloc_page() == NULL);
ffffffffc02016cc:	00005697          	auipc	a3,0x5
ffffffffc02016d0:	05468693          	addi	a3,a3,84 # ffffffffc0206720 <etext+0xc1c>
ffffffffc02016d4:	00005617          	auipc	a2,0x5
ffffffffc02016d8:	ed460613          	addi	a2,a2,-300 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02016dc:	11e00593          	li	a1,286
ffffffffc02016e0:	00005517          	auipc	a0,0x5
ffffffffc02016e4:	ee050513          	addi	a0,a0,-288 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02016e8:	da7fe0ef          	jal	ffffffffc020048e <__panic>
    assert(!PageProperty(p0));
ffffffffc02016ec:	00005697          	auipc	a3,0x5
ffffffffc02016f0:	0b468693          	addi	a3,a3,180 # ffffffffc02067a0 <etext+0xc9c>
ffffffffc02016f4:	00005617          	auipc	a2,0x5
ffffffffc02016f8:	eb460613          	addi	a2,a2,-332 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02016fc:	11900593          	li	a1,281
ffffffffc0201700:	00005517          	auipc	a0,0x5
ffffffffc0201704:	ec050513          	addi	a0,a0,-320 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201708:	d87fe0ef          	jal	ffffffffc020048e <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020170c:	00005697          	auipc	a3,0x5
ffffffffc0201710:	1b468693          	addi	a3,a3,436 # ffffffffc02068c0 <etext+0xdbc>
ffffffffc0201714:	00005617          	auipc	a2,0x5
ffffffffc0201718:	e9460613          	addi	a2,a2,-364 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020171c:	13700593          	li	a1,311
ffffffffc0201720:	00005517          	auipc	a0,0x5
ffffffffc0201724:	ea050513          	addi	a0,a0,-352 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201728:	d67fe0ef          	jal	ffffffffc020048e <__panic>
    assert(total == 0);
ffffffffc020172c:	00005697          	auipc	a3,0x5
ffffffffc0201730:	1c468693          	addi	a3,a3,452 # ffffffffc02068f0 <etext+0xdec>
ffffffffc0201734:	00005617          	auipc	a2,0x5
ffffffffc0201738:	e7460613          	addi	a2,a2,-396 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020173c:	14700593          	li	a1,327
ffffffffc0201740:	00005517          	auipc	a0,0x5
ffffffffc0201744:	e8050513          	addi	a0,a0,-384 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201748:	d47fe0ef          	jal	ffffffffc020048e <__panic>
    assert(total == nr_free_pages());
ffffffffc020174c:	00005697          	auipc	a3,0x5
ffffffffc0201750:	e8c68693          	addi	a3,a3,-372 # ffffffffc02065d8 <etext+0xad4>
ffffffffc0201754:	00005617          	auipc	a2,0x5
ffffffffc0201758:	e5460613          	addi	a2,a2,-428 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020175c:	11300593          	li	a1,275
ffffffffc0201760:	00005517          	auipc	a0,0x5
ffffffffc0201764:	e6050513          	addi	a0,a0,-416 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201768:	d27fe0ef          	jal	ffffffffc020048e <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020176c:	00005697          	auipc	a3,0x5
ffffffffc0201770:	eac68693          	addi	a3,a3,-340 # ffffffffc0206618 <etext+0xb14>
ffffffffc0201774:	00005617          	auipc	a2,0x5
ffffffffc0201778:	e3460613          	addi	a2,a2,-460 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020177c:	0d800593          	li	a1,216
ffffffffc0201780:	00005517          	auipc	a0,0x5
ffffffffc0201784:	e4050513          	addi	a0,a0,-448 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201788:	d07fe0ef          	jal	ffffffffc020048e <__panic>

ffffffffc020178c <default_free_pages>:
{
ffffffffc020178c:	1141                	addi	sp,sp,-16
ffffffffc020178e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201790:	14058663          	beqz	a1,ffffffffc02018dc <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc0201794:	00659713          	slli	a4,a1,0x6
ffffffffc0201798:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020179c:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc020179e:	c30d                	beqz	a4,ffffffffc02017c0 <default_free_pages+0x34>
ffffffffc02017a0:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017a2:	8b05                	andi	a4,a4,1
ffffffffc02017a4:	10071c63          	bnez	a4,ffffffffc02018bc <default_free_pages+0x130>
ffffffffc02017a8:	6798                	ld	a4,8(a5)
ffffffffc02017aa:	8b09                	andi	a4,a4,2
ffffffffc02017ac:	10071863          	bnez	a4,ffffffffc02018bc <default_free_pages+0x130>
        p->flags = 0;
ffffffffc02017b0:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc02017b4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02017b8:	04078793          	addi	a5,a5,64
ffffffffc02017bc:	fed792e3          	bne	a5,a3,ffffffffc02017a0 <default_free_pages+0x14>
    base->property = n;
ffffffffc02017c0:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02017c2:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02017c6:	4789                	li	a5,2
ffffffffc02017c8:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02017cc:	000b0717          	auipc	a4,0xb0
ffffffffc02017d0:	d0472703          	lw	a4,-764(a4) # ffffffffc02b14d0 <free_area+0x10>
ffffffffc02017d4:	000b0697          	auipc	a3,0xb0
ffffffffc02017d8:	cec68693          	addi	a3,a3,-788 # ffffffffc02b14c0 <free_area>
    return list->next == list;
ffffffffc02017dc:	669c                	ld	a5,8(a3)
ffffffffc02017de:	9f2d                	addw	a4,a4,a1
ffffffffc02017e0:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc02017e2:	0ad78163          	beq	a5,a3,ffffffffc0201884 <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc02017e6:	fe878713          	addi	a4,a5,-24
ffffffffc02017ea:	4581                	li	a1,0
ffffffffc02017ec:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc02017f0:	00e56a63          	bltu	a0,a4,ffffffffc0201804 <default_free_pages+0x78>
    return listelm->next;
ffffffffc02017f4:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02017f6:	04d70c63          	beq	a4,a3,ffffffffc020184e <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc02017fa:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02017fc:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201800:	fee57ae3          	bgeu	a0,a4,ffffffffc02017f4 <default_free_pages+0x68>
ffffffffc0201804:	c199                	beqz	a1,ffffffffc020180a <default_free_pages+0x7e>
ffffffffc0201806:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020180a:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020180c:	e390                	sd	a2,0(a5)
ffffffffc020180e:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc0201810:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201812:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc0201814:	00d70d63          	beq	a4,a3,ffffffffc020182e <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc0201818:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc020181c:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc0201820:	02059813          	slli	a6,a1,0x20
ffffffffc0201824:	01a85793          	srli	a5,a6,0x1a
ffffffffc0201828:	97b2                	add	a5,a5,a2
ffffffffc020182a:	02f50c63          	beq	a0,a5,ffffffffc0201862 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc020182e:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc0201830:	00d78c63          	beq	a5,a3,ffffffffc0201848 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc0201834:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0201836:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc020183a:	02061593          	slli	a1,a2,0x20
ffffffffc020183e:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0201842:	972a                	add	a4,a4,a0
ffffffffc0201844:	04e68c63          	beq	a3,a4,ffffffffc020189c <default_free_pages+0x110>
}
ffffffffc0201848:	60a2                	ld	ra,8(sp)
ffffffffc020184a:	0141                	addi	sp,sp,16
ffffffffc020184c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020184e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201850:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201852:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201854:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201856:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201858:	02d70f63          	beq	a4,a3,ffffffffc0201896 <default_free_pages+0x10a>
ffffffffc020185c:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020185e:	87ba                	mv	a5,a4
ffffffffc0201860:	bf71                	j	ffffffffc02017fc <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201862:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201864:	5875                	li	a6,-3
ffffffffc0201866:	9fad                	addw	a5,a5,a1
ffffffffc0201868:	fef72c23          	sw	a5,-8(a4)
ffffffffc020186c:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201870:	01853803          	ld	a6,24(a0)
ffffffffc0201874:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201876:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201878:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_matrix_out_size+0xfe4ae0>
    return listelm->next;
ffffffffc020187c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020187e:	0105b023          	sd	a6,0(a1)
ffffffffc0201882:	b77d                	j	ffffffffc0201830 <default_free_pages+0xa4>
}
ffffffffc0201884:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201886:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc020188a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020188c:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020188e:	e398                	sd	a4,0(a5)
ffffffffc0201890:	e798                	sd	a4,8(a5)
}
ffffffffc0201892:	0141                	addi	sp,sp,16
ffffffffc0201894:	8082                	ret
ffffffffc0201896:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201898:	873e                	mv	a4,a5
ffffffffc020189a:	bfad                	j	ffffffffc0201814 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc020189c:	ff87a703          	lw	a4,-8(a5)
ffffffffc02018a0:	56f5                	li	a3,-3
ffffffffc02018a2:	9f31                	addw	a4,a4,a2
ffffffffc02018a4:	c918                	sw	a4,16(a0)
ffffffffc02018a6:	ff078713          	addi	a4,a5,-16
ffffffffc02018aa:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018ae:	6398                	ld	a4,0(a5)
ffffffffc02018b0:	679c                	ld	a5,8(a5)
}
ffffffffc02018b2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02018b4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02018b6:	e398                	sd	a4,0(a5)
ffffffffc02018b8:	0141                	addi	sp,sp,16
ffffffffc02018ba:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02018bc:	00005697          	auipc	a3,0x5
ffffffffc02018c0:	04c68693          	addi	a3,a3,76 # ffffffffc0206908 <etext+0xe04>
ffffffffc02018c4:	00005617          	auipc	a2,0x5
ffffffffc02018c8:	ce460613          	addi	a2,a2,-796 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02018cc:	09400593          	li	a1,148
ffffffffc02018d0:	00005517          	auipc	a0,0x5
ffffffffc02018d4:	cf050513          	addi	a0,a0,-784 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02018d8:	bb7fe0ef          	jal	ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc02018dc:	00005697          	auipc	a3,0x5
ffffffffc02018e0:	02468693          	addi	a3,a3,36 # ffffffffc0206900 <etext+0xdfc>
ffffffffc02018e4:	00005617          	auipc	a2,0x5
ffffffffc02018e8:	cc460613          	addi	a2,a2,-828 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02018ec:	09000593          	li	a1,144
ffffffffc02018f0:	00005517          	auipc	a0,0x5
ffffffffc02018f4:	cd050513          	addi	a0,a0,-816 # ffffffffc02065c0 <etext+0xabc>
ffffffffc02018f8:	b97fe0ef          	jal	ffffffffc020048e <__panic>

ffffffffc02018fc <default_alloc_pages>:
    assert(n > 0);
ffffffffc02018fc:	c951                	beqz	a0,ffffffffc0201990 <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc02018fe:	000b0597          	auipc	a1,0xb0
ffffffffc0201902:	bd25a583          	lw	a1,-1070(a1) # ffffffffc02b14d0 <free_area+0x10>
ffffffffc0201906:	86aa                	mv	a3,a0
ffffffffc0201908:	02059793          	slli	a5,a1,0x20
ffffffffc020190c:	9381                	srli	a5,a5,0x20
ffffffffc020190e:	00a7ef63          	bltu	a5,a0,ffffffffc020192c <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc0201912:	000b0617          	auipc	a2,0xb0
ffffffffc0201916:	bae60613          	addi	a2,a2,-1106 # ffffffffc02b14c0 <free_area>
ffffffffc020191a:	87b2                	mv	a5,a2
ffffffffc020191c:	a029                	j	ffffffffc0201926 <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc020191e:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0201922:	00d77763          	bgeu	a4,a3,ffffffffc0201930 <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc0201926:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc0201928:	fec79be3          	bne	a5,a2,ffffffffc020191e <default_alloc_pages+0x22>
        return NULL;
ffffffffc020192c:	4501                	li	a0,0
}
ffffffffc020192e:	8082                	ret
        if (page->property > n)
ffffffffc0201930:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc0201934:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201938:	6798                	ld	a4,8(a5)
ffffffffc020193a:	02089313          	slli	t1,a7,0x20
ffffffffc020193e:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc0201942:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc0201946:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc020194a:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc020194e:	0266fa63          	bgeu	a3,t1,ffffffffc0201982 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc0201952:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc0201956:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc020195a:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc020195c:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201960:	00870313          	addi	t1,a4,8
ffffffffc0201964:	4889                	li	a7,2
ffffffffc0201966:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020196a:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc020196e:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc0201972:	0068b023          	sd	t1,0(a7) # ff0000 <_binary_obj___user_matrix_out_size+0xfe4ad8>
ffffffffc0201976:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc020197a:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc020197e:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc0201982:	9d95                	subw	a1,a1,a3
ffffffffc0201984:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201986:	5775                	li	a4,-3
ffffffffc0201988:	17c1                	addi	a5,a5,-16
ffffffffc020198a:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020198e:	8082                	ret
{
ffffffffc0201990:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201992:	00005697          	auipc	a3,0x5
ffffffffc0201996:	f6e68693          	addi	a3,a3,-146 # ffffffffc0206900 <etext+0xdfc>
ffffffffc020199a:	00005617          	auipc	a2,0x5
ffffffffc020199e:	c0e60613          	addi	a2,a2,-1010 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02019a2:	06c00593          	li	a1,108
ffffffffc02019a6:	00005517          	auipc	a0,0x5
ffffffffc02019aa:	c1a50513          	addi	a0,a0,-998 # ffffffffc02065c0 <etext+0xabc>
{
ffffffffc02019ae:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019b0:	adffe0ef          	jal	ffffffffc020048e <__panic>

ffffffffc02019b4 <default_init_memmap>:
{
ffffffffc02019b4:	1141                	addi	sp,sp,-16
ffffffffc02019b6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02019b8:	c9e1                	beqz	a1,ffffffffc0201a88 <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc02019ba:	00659713          	slli	a4,a1,0x6
ffffffffc02019be:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02019c2:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc02019c4:	cf11                	beqz	a4,ffffffffc02019e0 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02019c6:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02019c8:	8b05                	andi	a4,a4,1
ffffffffc02019ca:	cf59                	beqz	a4,ffffffffc0201a68 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02019cc:	0007a823          	sw	zero,16(a5)
ffffffffc02019d0:	0007b423          	sd	zero,8(a5)
ffffffffc02019d4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc02019d8:	04078793          	addi	a5,a5,64
ffffffffc02019dc:	fed795e3          	bne	a5,a3,ffffffffc02019c6 <default_init_memmap+0x12>
    base->property = n;
ffffffffc02019e0:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02019e2:	4789                	li	a5,2
ffffffffc02019e4:	00850713          	addi	a4,a0,8
ffffffffc02019e8:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02019ec:	000b0717          	auipc	a4,0xb0
ffffffffc02019f0:	ae472703          	lw	a4,-1308(a4) # ffffffffc02b14d0 <free_area+0x10>
ffffffffc02019f4:	000b0697          	auipc	a3,0xb0
ffffffffc02019f8:	acc68693          	addi	a3,a3,-1332 # ffffffffc02b14c0 <free_area>
    return list->next == list;
ffffffffc02019fc:	669c                	ld	a5,8(a3)
ffffffffc02019fe:	9f2d                	addw	a4,a4,a1
ffffffffc0201a00:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc0201a02:	04d78663          	beq	a5,a3,ffffffffc0201a4e <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc0201a06:	fe878713          	addi	a4,a5,-24
ffffffffc0201a0a:	4581                	li	a1,0
ffffffffc0201a0c:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc0201a10:	00e56a63          	bltu	a0,a4,ffffffffc0201a24 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201a14:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201a16:	02d70263          	beq	a4,a3,ffffffffc0201a3a <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc0201a1a:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201a1c:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc0201a20:	fee57ae3          	bgeu	a0,a4,ffffffffc0201a14 <default_init_memmap+0x60>
ffffffffc0201a24:	c199                	beqz	a1,ffffffffc0201a2a <default_init_memmap+0x76>
ffffffffc0201a26:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201a2a:	6398                	ld	a4,0(a5)
}
ffffffffc0201a2c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201a2e:	e390                	sd	a2,0(a5)
ffffffffc0201a30:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc0201a32:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0201a34:	f11c                	sd	a5,32(a0)
ffffffffc0201a36:	0141                	addi	sp,sp,16
ffffffffc0201a38:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201a3a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201a3c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201a3e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201a40:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201a42:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc0201a44:	00d70e63          	beq	a4,a3,ffffffffc0201a60 <default_init_memmap+0xac>
ffffffffc0201a48:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201a4a:	87ba                	mv	a5,a4
ffffffffc0201a4c:	bfc1                	j	ffffffffc0201a1c <default_init_memmap+0x68>
}
ffffffffc0201a4e:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201a50:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201a54:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201a56:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0201a58:	e398                	sd	a4,0(a5)
ffffffffc0201a5a:	e798                	sd	a4,8(a5)
}
ffffffffc0201a5c:	0141                	addi	sp,sp,16
ffffffffc0201a5e:	8082                	ret
ffffffffc0201a60:	60a2                	ld	ra,8(sp)
ffffffffc0201a62:	e290                	sd	a2,0(a3)
ffffffffc0201a64:	0141                	addi	sp,sp,16
ffffffffc0201a66:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201a68:	00005697          	auipc	a3,0x5
ffffffffc0201a6c:	ec868693          	addi	a3,a3,-312 # ffffffffc0206930 <etext+0xe2c>
ffffffffc0201a70:	00005617          	auipc	a2,0x5
ffffffffc0201a74:	b3860613          	addi	a2,a2,-1224 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0201a78:	04b00593          	li	a1,75
ffffffffc0201a7c:	00005517          	auipc	a0,0x5
ffffffffc0201a80:	b4450513          	addi	a0,a0,-1212 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201a84:	a0bfe0ef          	jal	ffffffffc020048e <__panic>
    assert(n > 0);
ffffffffc0201a88:	00005697          	auipc	a3,0x5
ffffffffc0201a8c:	e7868693          	addi	a3,a3,-392 # ffffffffc0206900 <etext+0xdfc>
ffffffffc0201a90:	00005617          	auipc	a2,0x5
ffffffffc0201a94:	b1860613          	addi	a2,a2,-1256 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0201a98:	04700593          	li	a1,71
ffffffffc0201a9c:	00005517          	auipc	a0,0x5
ffffffffc0201aa0:	b2450513          	addi	a0,a0,-1244 # ffffffffc02065c0 <etext+0xabc>
ffffffffc0201aa4:	9ebfe0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0201aa8 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201aa8:	c531                	beqz	a0,ffffffffc0201af4 <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201aaa:	e9b9                	bnez	a1,ffffffffc0201b00 <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201aac:	100027f3          	csrr	a5,sstatus
ffffffffc0201ab0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ab2:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201ab4:	efb1                	bnez	a5,ffffffffc0201b10 <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ab6:	000af797          	auipc	a5,0xaf
ffffffffc0201aba:	5d27b783          	ld	a5,1490(a5) # ffffffffc02b1088 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201abe:	873e                	mv	a4,a5
ffffffffc0201ac0:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ac2:	02a77a63          	bgeu	a4,a0,ffffffffc0201af6 <slob_free+0x4e>
ffffffffc0201ac6:	00f56463          	bltu	a0,a5,ffffffffc0201ace <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201aca:	fef76ae3          	bltu	a4,a5,ffffffffc0201abe <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201ace:	4110                	lw	a2,0(a0)
ffffffffc0201ad0:	00461693          	slli	a3,a2,0x4
ffffffffc0201ad4:	96aa                	add	a3,a3,a0
ffffffffc0201ad6:	0ad78463          	beq	a5,a3,ffffffffc0201b7e <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201ada:	4310                	lw	a2,0(a4)
ffffffffc0201adc:	e51c                	sd	a5,8(a0)
ffffffffc0201ade:	00461693          	slli	a3,a2,0x4
ffffffffc0201ae2:	96ba                	add	a3,a3,a4
ffffffffc0201ae4:	08d50163          	beq	a0,a3,ffffffffc0201b66 <slob_free+0xbe>
ffffffffc0201ae8:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201aea:	000af797          	auipc	a5,0xaf
ffffffffc0201aee:	58e7bf23          	sd	a4,1438(a5) # ffffffffc02b1088 <slobfree>
    if (flag)
ffffffffc0201af2:	e9a5                	bnez	a1,ffffffffc0201b62 <slob_free+0xba>
ffffffffc0201af4:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201af6:	fcf574e3          	bgeu	a0,a5,ffffffffc0201abe <slob_free+0x16>
ffffffffc0201afa:	fcf762e3          	bltu	a4,a5,ffffffffc0201abe <slob_free+0x16>
ffffffffc0201afe:	bfc1                	j	ffffffffc0201ace <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201b00:	25bd                	addiw	a1,a1,15
ffffffffc0201b02:	8191                	srli	a1,a1,0x4
ffffffffc0201b04:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b06:	100027f3          	csrr	a5,sstatus
ffffffffc0201b0a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201b0c:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201b0e:	d7c5                	beqz	a5,ffffffffc0201ab6 <slob_free+0xe>
{
ffffffffc0201b10:	1101                	addi	sp,sp,-32
ffffffffc0201b12:	e42a                	sd	a0,8(sp)
ffffffffc0201b14:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201b16:	ee7fe0ef          	jal	ffffffffc02009fc <intr_disable>
        return 1;
ffffffffc0201b1a:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b1c:	000af797          	auipc	a5,0xaf
ffffffffc0201b20:	56c7b783          	ld	a5,1388(a5) # ffffffffc02b1088 <slobfree>
ffffffffc0201b24:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b26:	873e                	mv	a4,a5
ffffffffc0201b28:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201b2a:	06a77663          	bgeu	a4,a0,ffffffffc0201b96 <slob_free+0xee>
ffffffffc0201b2e:	00f56463          	bltu	a0,a5,ffffffffc0201b36 <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b32:	fef76ae3          	bltu	a4,a5,ffffffffc0201b26 <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201b36:	4110                	lw	a2,0(a0)
ffffffffc0201b38:	00461693          	slli	a3,a2,0x4
ffffffffc0201b3c:	96aa                	add	a3,a3,a0
ffffffffc0201b3e:	06d78363          	beq	a5,a3,ffffffffc0201ba4 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201b42:	4310                	lw	a2,0(a4)
ffffffffc0201b44:	e51c                	sd	a5,8(a0)
ffffffffc0201b46:	00461693          	slli	a3,a2,0x4
ffffffffc0201b4a:	96ba                	add	a3,a3,a4
ffffffffc0201b4c:	06d50163          	beq	a0,a3,ffffffffc0201bae <slob_free+0x106>
ffffffffc0201b50:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201b52:	000af797          	auipc	a5,0xaf
ffffffffc0201b56:	52e7bb23          	sd	a4,1334(a5) # ffffffffc02b1088 <slobfree>
    if (flag)
ffffffffc0201b5a:	e1a9                	bnez	a1,ffffffffc0201b9c <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201b5c:	60e2                	ld	ra,24(sp)
ffffffffc0201b5e:	6105                	addi	sp,sp,32
ffffffffc0201b60:	8082                	ret
        intr_enable();
ffffffffc0201b62:	e95fe06f          	j	ffffffffc02009f6 <intr_enable>
		cur->units += b->units;
ffffffffc0201b66:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b68:	853e                	mv	a0,a5
ffffffffc0201b6a:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201b6c:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b70:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201b72:	000af797          	auipc	a5,0xaf
ffffffffc0201b76:	50e7bb23          	sd	a4,1302(a5) # ffffffffc02b1088 <slobfree>
    if (flag)
ffffffffc0201b7a:	ddad                	beqz	a1,ffffffffc0201af4 <slob_free+0x4c>
ffffffffc0201b7c:	b7dd                	j	ffffffffc0201b62 <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201b7e:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b80:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b82:	9eb1                	addw	a3,a3,a2
ffffffffc0201b84:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201b86:	4310                	lw	a2,0(a4)
ffffffffc0201b88:	e51c                	sd	a5,8(a0)
ffffffffc0201b8a:	00461693          	slli	a3,a2,0x4
ffffffffc0201b8e:	96ba                	add	a3,a3,a4
ffffffffc0201b90:	f4d51ce3          	bne	a0,a3,ffffffffc0201ae8 <slob_free+0x40>
ffffffffc0201b94:	bfc9                	j	ffffffffc0201b66 <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b96:	f8f56ee3          	bltu	a0,a5,ffffffffc0201b32 <slob_free+0x8a>
ffffffffc0201b9a:	b771                	j	ffffffffc0201b26 <slob_free+0x7e>
}
ffffffffc0201b9c:	60e2                	ld	ra,24(sp)
ffffffffc0201b9e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201ba0:	e57fe06f          	j	ffffffffc02009f6 <intr_enable>
		b->units += cur->next->units;
ffffffffc0201ba4:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201ba6:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201ba8:	9eb1                	addw	a3,a3,a2
ffffffffc0201baa:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201bac:	bf59                	j	ffffffffc0201b42 <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201bae:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201bb0:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201bb2:	00c687bb          	addw	a5,a3,a2
ffffffffc0201bb6:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201bb8:	bf61                	j	ffffffffc0201b50 <slob_free+0xa8>

ffffffffc0201bba <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bba:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201bbc:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bbe:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201bc2:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201bc4:	32a000ef          	jal	ffffffffc0201eee <alloc_pages>
	if (!page)
ffffffffc0201bc8:	c91d                	beqz	a0,ffffffffc0201bfe <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201bca:	000b0697          	auipc	a3,0xb0
ffffffffc0201bce:	93e6b683          	ld	a3,-1730(a3) # ffffffffc02b1508 <pages>
ffffffffc0201bd2:	00007797          	auipc	a5,0x7
ffffffffc0201bd6:	90e7b783          	ld	a5,-1778(a5) # ffffffffc02084e0 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201bda:	000b0717          	auipc	a4,0xb0
ffffffffc0201bde:	92673703          	ld	a4,-1754(a4) # ffffffffc02b1500 <npage>
    return page - pages + nbase;
ffffffffc0201be2:	8d15                	sub	a0,a0,a3
ffffffffc0201be4:	8519                	srai	a0,a0,0x6
ffffffffc0201be6:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201be8:	00c51793          	slli	a5,a0,0xc
ffffffffc0201bec:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201bee:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201bf0:	00e7fa63          	bgeu	a5,a4,ffffffffc0201c04 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201bf4:	000b0797          	auipc	a5,0xb0
ffffffffc0201bf8:	9047b783          	ld	a5,-1788(a5) # ffffffffc02b14f8 <va_pa_offset>
ffffffffc0201bfc:	953e                	add	a0,a0,a5
}
ffffffffc0201bfe:	60a2                	ld	ra,8(sp)
ffffffffc0201c00:	0141                	addi	sp,sp,16
ffffffffc0201c02:	8082                	ret
ffffffffc0201c04:	86aa                	mv	a3,a0
ffffffffc0201c06:	00005617          	auipc	a2,0x5
ffffffffc0201c0a:	d5260613          	addi	a2,a2,-686 # ffffffffc0206958 <etext+0xe54>
ffffffffc0201c0e:	07100593          	li	a1,113
ffffffffc0201c12:	00005517          	auipc	a0,0x5
ffffffffc0201c16:	d6e50513          	addi	a0,a0,-658 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0201c1a:	875fe0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0201c1e <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201c1e:	7179                	addi	sp,sp,-48
ffffffffc0201c20:	f406                	sd	ra,40(sp)
ffffffffc0201c22:	f022                	sd	s0,32(sp)
ffffffffc0201c24:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c26:	01050713          	addi	a4,a0,16
ffffffffc0201c2a:	6785                	lui	a5,0x1
ffffffffc0201c2c:	0af77e63          	bgeu	a4,a5,ffffffffc0201ce8 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201c30:	00f50413          	addi	s0,a0,15
ffffffffc0201c34:	8011                	srli	s0,s0,0x4
ffffffffc0201c36:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c38:	100025f3          	csrr	a1,sstatus
ffffffffc0201c3c:	8989                	andi	a1,a1,2
ffffffffc0201c3e:	edd1                	bnez	a1,ffffffffc0201cda <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201c40:	000af497          	auipc	s1,0xaf
ffffffffc0201c44:	44848493          	addi	s1,s1,1096 # ffffffffc02b1088 <slobfree>
ffffffffc0201c48:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c4a:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201c4c:	4314                	lw	a3,0(a4)
ffffffffc0201c4e:	0886da63          	bge	a3,s0,ffffffffc0201ce2 <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201c52:	00e60a63          	beq	a2,a4,ffffffffc0201c66 <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c56:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c58:	4394                	lw	a3,0(a5)
ffffffffc0201c5a:	0286d863          	bge	a3,s0,ffffffffc0201c8a <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201c5e:	6090                	ld	a2,0(s1)
ffffffffc0201c60:	873e                	mv	a4,a5
ffffffffc0201c62:	fee61ae3          	bne	a2,a4,ffffffffc0201c56 <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201c66:	e9b1                	bnez	a1,ffffffffc0201cba <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201c68:	4501                	li	a0,0
ffffffffc0201c6a:	f51ff0ef          	jal	ffffffffc0201bba <__slob_get_free_pages.constprop.0>
ffffffffc0201c6e:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201c70:	c915                	beqz	a0,ffffffffc0201ca4 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201c72:	6585                	lui	a1,0x1
ffffffffc0201c74:	e35ff0ef          	jal	ffffffffc0201aa8 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c78:	100025f3          	csrr	a1,sstatus
ffffffffc0201c7c:	8989                	andi	a1,a1,2
ffffffffc0201c7e:	e98d                	bnez	a1,ffffffffc0201cb0 <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201c80:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c82:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c84:	4394                	lw	a3,0(a5)
ffffffffc0201c86:	fc86cce3          	blt	a3,s0,ffffffffc0201c5e <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c8a:	04d40563          	beq	s0,a3,ffffffffc0201cd4 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201c8e:	00441613          	slli	a2,s0,0x4
ffffffffc0201c92:	963e                	add	a2,a2,a5
ffffffffc0201c94:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201c96:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201c98:	9e81                	subw	a3,a3,s0
ffffffffc0201c9a:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201c9c:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201c9e:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201ca0:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201ca2:	ed99                	bnez	a1,ffffffffc0201cc0 <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201ca4:	70a2                	ld	ra,40(sp)
ffffffffc0201ca6:	7402                	ld	s0,32(sp)
ffffffffc0201ca8:	64e2                	ld	s1,24(sp)
ffffffffc0201caa:	853e                	mv	a0,a5
ffffffffc0201cac:	6145                	addi	sp,sp,48
ffffffffc0201cae:	8082                	ret
        intr_disable();
ffffffffc0201cb0:	d4dfe0ef          	jal	ffffffffc02009fc <intr_disable>
			cur = slobfree;
ffffffffc0201cb4:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201cb6:	4585                	li	a1,1
ffffffffc0201cb8:	b7e9                	j	ffffffffc0201c82 <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201cba:	d3dfe0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0201cbe:	b76d                	j	ffffffffc0201c68 <slob_alloc.constprop.0+0x4a>
ffffffffc0201cc0:	e43e                	sd	a5,8(sp)
ffffffffc0201cc2:	d35fe0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0201cc6:	67a2                	ld	a5,8(sp)
}
ffffffffc0201cc8:	70a2                	ld	ra,40(sp)
ffffffffc0201cca:	7402                	ld	s0,32(sp)
ffffffffc0201ccc:	64e2                	ld	s1,24(sp)
ffffffffc0201cce:	853e                	mv	a0,a5
ffffffffc0201cd0:	6145                	addi	sp,sp,48
ffffffffc0201cd2:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201cd4:	6794                	ld	a3,8(a5)
ffffffffc0201cd6:	e714                	sd	a3,8(a4)
ffffffffc0201cd8:	b7e1                	j	ffffffffc0201ca0 <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201cda:	d23fe0ef          	jal	ffffffffc02009fc <intr_disable>
        return 1;
ffffffffc0201cde:	4585                	li	a1,1
ffffffffc0201ce0:	b785                	j	ffffffffc0201c40 <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201ce2:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201ce4:	8732                	mv	a4,a2
ffffffffc0201ce6:	b755                	j	ffffffffc0201c8a <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201ce8:	00005697          	auipc	a3,0x5
ffffffffc0201cec:	ca868693          	addi	a3,a3,-856 # ffffffffc0206990 <etext+0xe8c>
ffffffffc0201cf0:	00005617          	auipc	a2,0x5
ffffffffc0201cf4:	8b860613          	addi	a2,a2,-1864 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0201cf8:	06300593          	li	a1,99
ffffffffc0201cfc:	00005517          	auipc	a0,0x5
ffffffffc0201d00:	cb450513          	addi	a0,a0,-844 # ffffffffc02069b0 <etext+0xeac>
ffffffffc0201d04:	f8afe0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0201d08 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201d08:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201d0a:	00005517          	auipc	a0,0x5
ffffffffc0201d0e:	cbe50513          	addi	a0,a0,-834 # ffffffffc02069c8 <etext+0xec4>
{
ffffffffc0201d12:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201d14:	cc8fe0ef          	jal	ffffffffc02001dc <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201d18:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d1a:	00005517          	auipc	a0,0x5
ffffffffc0201d1e:	cc650513          	addi	a0,a0,-826 # ffffffffc02069e0 <etext+0xedc>
}
ffffffffc0201d22:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201d24:	cb8fe06f          	j	ffffffffc02001dc <cprintf>

ffffffffc0201d28 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201d28:	4501                	li	a0,0
ffffffffc0201d2a:	8082                	ret

ffffffffc0201d2c <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201d2c:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d2e:	6685                	lui	a3,0x1
{
ffffffffc0201d30:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201d32:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7f31>
ffffffffc0201d34:	04a6f963          	bgeu	a3,a0,ffffffffc0201d86 <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201d38:	e42a                	sd	a0,8(sp)
ffffffffc0201d3a:	4561                	li	a0,24
ffffffffc0201d3c:	e822                	sd	s0,16(sp)
ffffffffc0201d3e:	ee1ff0ef          	jal	ffffffffc0201c1e <slob_alloc.constprop.0>
ffffffffc0201d42:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201d44:	c541                	beqz	a0,ffffffffc0201dcc <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201d46:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201d48:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201d4a:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201d4c:	00f75763          	bge	a4,a5,ffffffffc0201d5a <kmalloc+0x2e>
ffffffffc0201d50:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201d54:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201d56:	fef74de3          	blt	a4,a5,ffffffffc0201d50 <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201d5a:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201d5c:	e5fff0ef          	jal	ffffffffc0201bba <__slob_get_free_pages.constprop.0>
ffffffffc0201d60:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201d62:	cd31                	beqz	a0,ffffffffc0201dbe <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d64:	100027f3          	csrr	a5,sstatus
ffffffffc0201d68:	8b89                	andi	a5,a5,2
ffffffffc0201d6a:	eb85                	bnez	a5,ffffffffc0201d9a <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201d6c:	000af797          	auipc	a5,0xaf
ffffffffc0201d70:	76c7b783          	ld	a5,1900(a5) # ffffffffc02b14d8 <bigblocks>
		bigblocks = bb;
ffffffffc0201d74:	000af717          	auipc	a4,0xaf
ffffffffc0201d78:	76873223          	sd	s0,1892(a4) # ffffffffc02b14d8 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d7c:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201d7e:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201d80:	60e2                	ld	ra,24(sp)
ffffffffc0201d82:	6105                	addi	sp,sp,32
ffffffffc0201d84:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d86:	0541                	addi	a0,a0,16
ffffffffc0201d88:	e97ff0ef          	jal	ffffffffc0201c1e <slob_alloc.constprop.0>
ffffffffc0201d8c:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d8e:	0541                	addi	a0,a0,16
ffffffffc0201d90:	fbe5                	bnez	a5,ffffffffc0201d80 <kmalloc+0x54>
		return 0;
ffffffffc0201d92:	4501                	li	a0,0
}
ffffffffc0201d94:	60e2                	ld	ra,24(sp)
ffffffffc0201d96:	6105                	addi	sp,sp,32
ffffffffc0201d98:	8082                	ret
        intr_disable();
ffffffffc0201d9a:	c63fe0ef          	jal	ffffffffc02009fc <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d9e:	000af797          	auipc	a5,0xaf
ffffffffc0201da2:	73a7b783          	ld	a5,1850(a5) # ffffffffc02b14d8 <bigblocks>
		bigblocks = bb;
ffffffffc0201da6:	000af717          	auipc	a4,0xaf
ffffffffc0201daa:	72873923          	sd	s0,1842(a4) # ffffffffc02b14d8 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201dae:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201db0:	c47fe0ef          	jal	ffffffffc02009f6 <intr_enable>
		return bb->pages;
ffffffffc0201db4:	6408                	ld	a0,8(s0)
}
ffffffffc0201db6:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201db8:	6442                	ld	s0,16(sp)
}
ffffffffc0201dba:	6105                	addi	sp,sp,32
ffffffffc0201dbc:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dbe:	8522                	mv	a0,s0
ffffffffc0201dc0:	45e1                	li	a1,24
ffffffffc0201dc2:	ce7ff0ef          	jal	ffffffffc0201aa8 <slob_free>
		return 0;
ffffffffc0201dc6:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dc8:	6442                	ld	s0,16(sp)
ffffffffc0201dca:	b7e9                	j	ffffffffc0201d94 <kmalloc+0x68>
ffffffffc0201dcc:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201dce:	4501                	li	a0,0
ffffffffc0201dd0:	b7d1                	j	ffffffffc0201d94 <kmalloc+0x68>

ffffffffc0201dd2 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201dd2:	c571                	beqz	a0,ffffffffc0201e9e <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201dd4:	03451793          	slli	a5,a0,0x34
ffffffffc0201dd8:	e3e1                	bnez	a5,ffffffffc0201e98 <kfree+0xc6>
{
ffffffffc0201dda:	1101                	addi	sp,sp,-32
ffffffffc0201ddc:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201dde:	100027f3          	csrr	a5,sstatus
ffffffffc0201de2:	8b89                	andi	a5,a5,2
ffffffffc0201de4:	e7c1                	bnez	a5,ffffffffc0201e6c <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201de6:	000af797          	auipc	a5,0xaf
ffffffffc0201dea:	6f27b783          	ld	a5,1778(a5) # ffffffffc02b14d8 <bigblocks>
    return 0;
ffffffffc0201dee:	4581                	li	a1,0
ffffffffc0201df0:	cbad                	beqz	a5,ffffffffc0201e62 <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201df2:	000af617          	auipc	a2,0xaf
ffffffffc0201df6:	6e660613          	addi	a2,a2,1766 # ffffffffc02b14d8 <bigblocks>
ffffffffc0201dfa:	a021                	j	ffffffffc0201e02 <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dfc:	01070613          	addi	a2,a4,16
ffffffffc0201e00:	c3a5                	beqz	a5,ffffffffc0201e60 <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201e02:	6794                	ld	a3,8(a5)
ffffffffc0201e04:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201e06:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201e08:	fea69ae3          	bne	a3,a0,ffffffffc0201dfc <kfree+0x2a>
				*last = bb->next;
ffffffffc0201e0c:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201e0e:	edb5                	bnez	a1,ffffffffc0201e8a <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201e10:	c02007b7          	lui	a5,0xc0200
ffffffffc0201e14:	0af56263          	bltu	a0,a5,ffffffffc0201eb8 <kfree+0xe6>
ffffffffc0201e18:	000af797          	auipc	a5,0xaf
ffffffffc0201e1c:	6e07b783          	ld	a5,1760(a5) # ffffffffc02b14f8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201e20:	000af697          	auipc	a3,0xaf
ffffffffc0201e24:	6e06b683          	ld	a3,1760(a3) # ffffffffc02b1500 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201e28:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201e2a:	00c55793          	srli	a5,a0,0xc
ffffffffc0201e2e:	06d7f963          	bgeu	a5,a3,ffffffffc0201ea0 <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e32:	00006617          	auipc	a2,0x6
ffffffffc0201e36:	6ae63603          	ld	a2,1710(a2) # ffffffffc02084e0 <nbase>
ffffffffc0201e3a:	000af517          	auipc	a0,0xaf
ffffffffc0201e3e:	6ce53503          	ld	a0,1742(a0) # ffffffffc02b1508 <pages>
	free_pages(kva2page((void *)kva), 1 << order);
ffffffffc0201e42:	4314                	lw	a3,0(a4)
ffffffffc0201e44:	8f91                	sub	a5,a5,a2
ffffffffc0201e46:	079a                	slli	a5,a5,0x6
ffffffffc0201e48:	4585                	li	a1,1
ffffffffc0201e4a:	953e                	add	a0,a0,a5
ffffffffc0201e4c:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201e50:	e03a                	sd	a4,0(sp)
ffffffffc0201e52:	0d6000ef          	jal	ffffffffc0201f28 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e56:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201e58:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e5a:	45e1                	li	a1,24
}
ffffffffc0201e5c:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201e5e:	b1a9                	j	ffffffffc0201aa8 <slob_free>
ffffffffc0201e60:	e185                	bnez	a1,ffffffffc0201e80 <kfree+0xae>
}
ffffffffc0201e62:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e64:	1541                	addi	a0,a0,-16
ffffffffc0201e66:	4581                	li	a1,0
}
ffffffffc0201e68:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e6a:	b93d                	j	ffffffffc0201aa8 <slob_free>
        intr_disable();
ffffffffc0201e6c:	e02a                	sd	a0,0(sp)
ffffffffc0201e6e:	b8ffe0ef          	jal	ffffffffc02009fc <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201e72:	000af797          	auipc	a5,0xaf
ffffffffc0201e76:	6667b783          	ld	a5,1638(a5) # ffffffffc02b14d8 <bigblocks>
ffffffffc0201e7a:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201e7c:	4585                	li	a1,1
ffffffffc0201e7e:	fbb5                	bnez	a5,ffffffffc0201df2 <kfree+0x20>
ffffffffc0201e80:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201e82:	b75fe0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0201e86:	6502                	ld	a0,0(sp)
ffffffffc0201e88:	bfe9                	j	ffffffffc0201e62 <kfree+0x90>
ffffffffc0201e8a:	e42a                	sd	a0,8(sp)
ffffffffc0201e8c:	e03a                	sd	a4,0(sp)
ffffffffc0201e8e:	b69fe0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0201e92:	6522                	ld	a0,8(sp)
ffffffffc0201e94:	6702                	ld	a4,0(sp)
ffffffffc0201e96:	bfad                	j	ffffffffc0201e10 <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e98:	1541                	addi	a0,a0,-16
ffffffffc0201e9a:	4581                	li	a1,0
ffffffffc0201e9c:	b131                	j	ffffffffc0201aa8 <slob_free>
ffffffffc0201e9e:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201ea0:	00005617          	auipc	a2,0x5
ffffffffc0201ea4:	b8860613          	addi	a2,a2,-1144 # ffffffffc0206a28 <etext+0xf24>
ffffffffc0201ea8:	06900593          	li	a1,105
ffffffffc0201eac:	00005517          	auipc	a0,0x5
ffffffffc0201eb0:	ad450513          	addi	a0,a0,-1324 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0201eb4:	ddafe0ef          	jal	ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201eb8:	86aa                	mv	a3,a0
ffffffffc0201eba:	00005617          	auipc	a2,0x5
ffffffffc0201ebe:	b4660613          	addi	a2,a2,-1210 # ffffffffc0206a00 <etext+0xefc>
ffffffffc0201ec2:	07700593          	li	a1,119
ffffffffc0201ec6:	00005517          	auipc	a0,0x5
ffffffffc0201eca:	aba50513          	addi	a0,a0,-1350 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0201ece:	dc0fe0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0201ed2 <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201ed2:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201ed4:	00005617          	auipc	a2,0x5
ffffffffc0201ed8:	b5460613          	addi	a2,a2,-1196 # ffffffffc0206a28 <etext+0xf24>
ffffffffc0201edc:	06900593          	li	a1,105
ffffffffc0201ee0:	00005517          	auipc	a0,0x5
ffffffffc0201ee4:	aa050513          	addi	a0,a0,-1376 # ffffffffc0206980 <etext+0xe7c>
pa2page(uintptr_t pa)
ffffffffc0201ee8:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201eea:	da4fe0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0201eee <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201eee:	100027f3          	csrr	a5,sstatus
ffffffffc0201ef2:	8b89                	andi	a5,a5,2
ffffffffc0201ef4:	e799                	bnez	a5,ffffffffc0201f02 <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201ef6:	000af797          	auipc	a5,0xaf
ffffffffc0201efa:	5ea7b783          	ld	a5,1514(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0201efe:	6f9c                	ld	a5,24(a5)
ffffffffc0201f00:	8782                	jr	a5
{
ffffffffc0201f02:	1101                	addi	sp,sp,-32
ffffffffc0201f04:	ec06                	sd	ra,24(sp)
ffffffffc0201f06:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201f08:	af5fe0ef          	jal	ffffffffc02009fc <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f0c:	000af797          	auipc	a5,0xaf
ffffffffc0201f10:	5d47b783          	ld	a5,1492(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0201f14:	6522                	ld	a0,8(sp)
ffffffffc0201f16:	6f9c                	ld	a5,24(a5)
ffffffffc0201f18:	9782                	jalr	a5
ffffffffc0201f1a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f1c:	adbfe0ef          	jal	ffffffffc02009f6 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201f20:	60e2                	ld	ra,24(sp)
ffffffffc0201f22:	6522                	ld	a0,8(sp)
ffffffffc0201f24:	6105                	addi	sp,sp,32
ffffffffc0201f26:	8082                	ret

ffffffffc0201f28 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f28:	100027f3          	csrr	a5,sstatus
ffffffffc0201f2c:	8b89                	andi	a5,a5,2
ffffffffc0201f2e:	e799                	bnez	a5,ffffffffc0201f3c <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201f30:	000af797          	auipc	a5,0xaf
ffffffffc0201f34:	5b07b783          	ld	a5,1456(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0201f38:	739c                	ld	a5,32(a5)
ffffffffc0201f3a:	8782                	jr	a5
{
ffffffffc0201f3c:	1101                	addi	sp,sp,-32
ffffffffc0201f3e:	ec06                	sd	ra,24(sp)
ffffffffc0201f40:	e42e                	sd	a1,8(sp)
ffffffffc0201f42:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201f44:	ab9fe0ef          	jal	ffffffffc02009fc <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f48:	000af797          	auipc	a5,0xaf
ffffffffc0201f4c:	5987b783          	ld	a5,1432(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0201f50:	65a2                	ld	a1,8(sp)
ffffffffc0201f52:	6502                	ld	a0,0(sp)
ffffffffc0201f54:	739c                	ld	a5,32(a5)
ffffffffc0201f56:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f58:	60e2                	ld	ra,24(sp)
ffffffffc0201f5a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f5c:	a9bfe06f          	j	ffffffffc02009f6 <intr_enable>

ffffffffc0201f60 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f60:	100027f3          	csrr	a5,sstatus
ffffffffc0201f64:	8b89                	andi	a5,a5,2
ffffffffc0201f66:	e799                	bnez	a5,ffffffffc0201f74 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f68:	000af797          	auipc	a5,0xaf
ffffffffc0201f6c:	5787b783          	ld	a5,1400(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0201f70:	779c                	ld	a5,40(a5)
ffffffffc0201f72:	8782                	jr	a5
{
ffffffffc0201f74:	1101                	addi	sp,sp,-32
ffffffffc0201f76:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201f78:	a85fe0ef          	jal	ffffffffc02009fc <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f7c:	000af797          	auipc	a5,0xaf
ffffffffc0201f80:	5647b783          	ld	a5,1380(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0201f84:	779c                	ld	a5,40(a5)
ffffffffc0201f86:	9782                	jalr	a5
ffffffffc0201f88:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f8a:	a6dfe0ef          	jal	ffffffffc02009f6 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f8e:	60e2                	ld	ra,24(sp)
ffffffffc0201f90:	6522                	ld	a0,8(sp)
ffffffffc0201f92:	6105                	addi	sp,sp,32
ffffffffc0201f94:	8082                	ret

ffffffffc0201f96 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f96:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f9a:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f9e:	078e                	slli	a5,a5,0x3
ffffffffc0201fa0:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201fa4:	6314                	ld	a3,0(a4)
{
ffffffffc0201fa6:	7139                	addi	sp,sp,-64
ffffffffc0201fa8:	f822                	sd	s0,48(sp)
ffffffffc0201faa:	f426                	sd	s1,40(sp)
ffffffffc0201fac:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201fae:	0016f793          	andi	a5,a3,1
{
ffffffffc0201fb2:	842e                	mv	s0,a1
ffffffffc0201fb4:	8832                	mv	a6,a2
ffffffffc0201fb6:	000af497          	auipc	s1,0xaf
ffffffffc0201fba:	54a48493          	addi	s1,s1,1354 # ffffffffc02b1500 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201fbe:	ebd1                	bnez	a5,ffffffffc0202052 <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fc0:	16060d63          	beqz	a2,ffffffffc020213a <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201fc4:	100027f3          	csrr	a5,sstatus
ffffffffc0201fc8:	8b89                	andi	a5,a5,2
ffffffffc0201fca:	16079e63          	bnez	a5,ffffffffc0202146 <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201fce:	000af797          	auipc	a5,0xaf
ffffffffc0201fd2:	5127b783          	ld	a5,1298(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0201fd6:	4505                	li	a0,1
ffffffffc0201fd8:	e43a                	sd	a4,8(sp)
ffffffffc0201fda:	6f9c                	ld	a5,24(a5)
ffffffffc0201fdc:	e832                	sd	a2,16(sp)
ffffffffc0201fde:	9782                	jalr	a5
ffffffffc0201fe0:	6722                	ld	a4,8(sp)
ffffffffc0201fe2:	6842                	ld	a6,16(sp)
ffffffffc0201fe4:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201fe6:	14078a63          	beqz	a5,ffffffffc020213a <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201fea:	000af517          	auipc	a0,0xaf
ffffffffc0201fee:	51e53503          	ld	a0,1310(a0) # ffffffffc02b1508 <pages>
ffffffffc0201ff2:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201ff6:	000af497          	auipc	s1,0xaf
ffffffffc0201ffa:	50a48493          	addi	s1,s1,1290 # ffffffffc02b1500 <npage>
ffffffffc0201ffe:	40a78533          	sub	a0,a5,a0
ffffffffc0202002:	8519                	srai	a0,a0,0x6
ffffffffc0202004:	9546                	add	a0,a0,a7
ffffffffc0202006:	6090                	ld	a2,0(s1)
ffffffffc0202008:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc020200c:	4585                	li	a1,1
ffffffffc020200e:	82b1                	srli	a3,a3,0xc
ffffffffc0202010:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0202012:	0532                	slli	a0,a0,0xc
ffffffffc0202014:	1ac6f763          	bgeu	a3,a2,ffffffffc02021c2 <get_pte+0x22c>
ffffffffc0202018:	000af697          	auipc	a3,0xaf
ffffffffc020201c:	4e06b683          	ld	a3,1248(a3) # ffffffffc02b14f8 <va_pa_offset>
ffffffffc0202020:	6605                	lui	a2,0x1
ffffffffc0202022:	4581                	li	a1,0
ffffffffc0202024:	9536                	add	a0,a0,a3
ffffffffc0202026:	ec42                	sd	a6,24(sp)
ffffffffc0202028:	e83e                	sd	a5,16(sp)
ffffffffc020202a:	e43a                	sd	a4,8(sp)
ffffffffc020202c:	2af030ef          	jal	ffffffffc0205ada <memset>
    return page - pages + nbase;
ffffffffc0202030:	000af697          	auipc	a3,0xaf
ffffffffc0202034:	4d86b683          	ld	a3,1240(a3) # ffffffffc02b1508 <pages>
ffffffffc0202038:	67c2                	ld	a5,16(sp)
ffffffffc020203a:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020203e:	6722                	ld	a4,8(sp)
ffffffffc0202040:	40d786b3          	sub	a3,a5,a3
ffffffffc0202044:	8699                	srai	a3,a3,0x6
ffffffffc0202046:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202048:	06aa                	slli	a3,a3,0xa
ffffffffc020204a:	6862                	ld	a6,24(sp)
ffffffffc020204c:	0116e693          	ori	a3,a3,17
ffffffffc0202050:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202052:	c006f693          	andi	a3,a3,-1024
ffffffffc0202056:	6098                	ld	a4,0(s1)
ffffffffc0202058:	068a                	slli	a3,a3,0x2
ffffffffc020205a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020205e:	14e7f663          	bgeu	a5,a4,ffffffffc02021aa <get_pte+0x214>
ffffffffc0202062:	000af897          	auipc	a7,0xaf
ffffffffc0202066:	49688893          	addi	a7,a7,1174 # ffffffffc02b14f8 <va_pa_offset>
ffffffffc020206a:	0008b603          	ld	a2,0(a7)
ffffffffc020206e:	01545793          	srli	a5,s0,0x15
ffffffffc0202072:	1ff7f793          	andi	a5,a5,511
ffffffffc0202076:	96b2                	add	a3,a3,a2
ffffffffc0202078:	078e                	slli	a5,a5,0x3
ffffffffc020207a:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc020207c:	6394                	ld	a3,0(a5)
ffffffffc020207e:	0016f613          	andi	a2,a3,1
ffffffffc0202082:	e659                	bnez	a2,ffffffffc0202110 <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202084:	0a080b63          	beqz	a6,ffffffffc020213a <get_pte+0x1a4>
ffffffffc0202088:	10002773          	csrr	a4,sstatus
ffffffffc020208c:	8b09                	andi	a4,a4,2
ffffffffc020208e:	ef71                	bnez	a4,ffffffffc020216a <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202090:	000af717          	auipc	a4,0xaf
ffffffffc0202094:	45073703          	ld	a4,1104(a4) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0202098:	4505                	li	a0,1
ffffffffc020209a:	e43e                	sd	a5,8(sp)
ffffffffc020209c:	6f18                	ld	a4,24(a4)
ffffffffc020209e:	9702                	jalr	a4
ffffffffc02020a0:	67a2                	ld	a5,8(sp)
ffffffffc02020a2:	872a                	mv	a4,a0
ffffffffc02020a4:	000af897          	auipc	a7,0xaf
ffffffffc02020a8:	45488893          	addi	a7,a7,1108 # ffffffffc02b14f8 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc02020ac:	c759                	beqz	a4,ffffffffc020213a <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc02020ae:	000af697          	auipc	a3,0xaf
ffffffffc02020b2:	45a6b683          	ld	a3,1114(a3) # ffffffffc02b1508 <pages>
ffffffffc02020b6:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020ba:	608c                	ld	a1,0(s1)
ffffffffc02020bc:	40d706b3          	sub	a3,a4,a3
ffffffffc02020c0:	8699                	srai	a3,a3,0x6
ffffffffc02020c2:	96c2                	add	a3,a3,a6
ffffffffc02020c4:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc02020c8:	4505                	li	a0,1
ffffffffc02020ca:	8231                	srli	a2,a2,0xc
ffffffffc02020cc:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc02020ce:	06b2                	slli	a3,a3,0xc
ffffffffc02020d0:	10b67663          	bgeu	a2,a1,ffffffffc02021dc <get_pte+0x246>
ffffffffc02020d4:	0008b503          	ld	a0,0(a7)
ffffffffc02020d8:	6605                	lui	a2,0x1
ffffffffc02020da:	4581                	li	a1,0
ffffffffc02020dc:	9536                	add	a0,a0,a3
ffffffffc02020de:	e83a                	sd	a4,16(sp)
ffffffffc02020e0:	e43e                	sd	a5,8(sp)
ffffffffc02020e2:	1f9030ef          	jal	ffffffffc0205ada <memset>
    return page - pages + nbase;
ffffffffc02020e6:	000af697          	auipc	a3,0xaf
ffffffffc02020ea:	4226b683          	ld	a3,1058(a3) # ffffffffc02b1508 <pages>
ffffffffc02020ee:	6742                	ld	a4,16(sp)
ffffffffc02020f0:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02020f4:	67a2                	ld	a5,8(sp)
ffffffffc02020f6:	40d706b3          	sub	a3,a4,a3
ffffffffc02020fa:	8699                	srai	a3,a3,0x6
ffffffffc02020fc:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02020fe:	06aa                	slli	a3,a3,0xa
ffffffffc0202100:	0116e693          	ori	a3,a3,17
ffffffffc0202104:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202106:	6098                	ld	a4,0(s1)
ffffffffc0202108:	000af897          	auipc	a7,0xaf
ffffffffc020210c:	3f088893          	addi	a7,a7,1008 # ffffffffc02b14f8 <va_pa_offset>
ffffffffc0202110:	c006f693          	andi	a3,a3,-1024
ffffffffc0202114:	068a                	slli	a3,a3,0x2
ffffffffc0202116:	00c6d793          	srli	a5,a3,0xc
ffffffffc020211a:	06e7fc63          	bgeu	a5,a4,ffffffffc0202192 <get_pte+0x1fc>
ffffffffc020211e:	0008b783          	ld	a5,0(a7)
ffffffffc0202122:	8031                	srli	s0,s0,0xc
ffffffffc0202124:	1ff47413          	andi	s0,s0,511
ffffffffc0202128:	040e                	slli	s0,s0,0x3
ffffffffc020212a:	96be                	add	a3,a3,a5
}
ffffffffc020212c:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020212e:	00868533          	add	a0,a3,s0
}
ffffffffc0202132:	7442                	ld	s0,48(sp)
ffffffffc0202134:	74a2                	ld	s1,40(sp)
ffffffffc0202136:	6121                	addi	sp,sp,64
ffffffffc0202138:	8082                	ret
ffffffffc020213a:	70e2                	ld	ra,56(sp)
ffffffffc020213c:	7442                	ld	s0,48(sp)
ffffffffc020213e:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc0202140:	4501                	li	a0,0
}
ffffffffc0202142:	6121                	addi	sp,sp,64
ffffffffc0202144:	8082                	ret
        intr_disable();
ffffffffc0202146:	e83a                	sd	a4,16(sp)
ffffffffc0202148:	ec32                	sd	a2,24(sp)
ffffffffc020214a:	8b3fe0ef          	jal	ffffffffc02009fc <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020214e:	000af797          	auipc	a5,0xaf
ffffffffc0202152:	3927b783          	ld	a5,914(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0202156:	4505                	li	a0,1
ffffffffc0202158:	6f9c                	ld	a5,24(a5)
ffffffffc020215a:	9782                	jalr	a5
ffffffffc020215c:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020215e:	899fe0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202162:	6862                	ld	a6,24(sp)
ffffffffc0202164:	6742                	ld	a4,16(sp)
ffffffffc0202166:	67a2                	ld	a5,8(sp)
ffffffffc0202168:	bdbd                	j	ffffffffc0201fe6 <get_pte+0x50>
        intr_disable();
ffffffffc020216a:	e83e                	sd	a5,16(sp)
ffffffffc020216c:	891fe0ef          	jal	ffffffffc02009fc <intr_disable>
ffffffffc0202170:	000af717          	auipc	a4,0xaf
ffffffffc0202174:	37073703          	ld	a4,880(a4) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0202178:	4505                	li	a0,1
ffffffffc020217a:	6f18                	ld	a4,24(a4)
ffffffffc020217c:	9702                	jalr	a4
ffffffffc020217e:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0202180:	877fe0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202184:	6722                	ld	a4,8(sp)
ffffffffc0202186:	67c2                	ld	a5,16(sp)
ffffffffc0202188:	000af897          	auipc	a7,0xaf
ffffffffc020218c:	37088893          	addi	a7,a7,880 # ffffffffc02b14f8 <va_pa_offset>
ffffffffc0202190:	bf31                	j	ffffffffc02020ac <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202192:	00004617          	auipc	a2,0x4
ffffffffc0202196:	7c660613          	addi	a2,a2,1990 # ffffffffc0206958 <etext+0xe54>
ffffffffc020219a:	10000593          	li	a1,256
ffffffffc020219e:	00005517          	auipc	a0,0x5
ffffffffc02021a2:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02021a6:	ae8fe0ef          	jal	ffffffffc020048e <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02021aa:	00004617          	auipc	a2,0x4
ffffffffc02021ae:	7ae60613          	addi	a2,a2,1966 # ffffffffc0206958 <etext+0xe54>
ffffffffc02021b2:	0f300593          	li	a1,243
ffffffffc02021b6:	00005517          	auipc	a0,0x5
ffffffffc02021ba:	89250513          	addi	a0,a0,-1902 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02021be:	ad0fe0ef          	jal	ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021c2:	86aa                	mv	a3,a0
ffffffffc02021c4:	00004617          	auipc	a2,0x4
ffffffffc02021c8:	79460613          	addi	a2,a2,1940 # ffffffffc0206958 <etext+0xe54>
ffffffffc02021cc:	0ef00593          	li	a1,239
ffffffffc02021d0:	00005517          	auipc	a0,0x5
ffffffffc02021d4:	87850513          	addi	a0,a0,-1928 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02021d8:	ab6fe0ef          	jal	ffffffffc020048e <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02021dc:	00004617          	auipc	a2,0x4
ffffffffc02021e0:	77c60613          	addi	a2,a2,1916 # ffffffffc0206958 <etext+0xe54>
ffffffffc02021e4:	0fd00593          	li	a1,253
ffffffffc02021e8:	00005517          	auipc	a0,0x5
ffffffffc02021ec:	86050513          	addi	a0,a0,-1952 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02021f0:	a9efe0ef          	jal	ffffffffc020048e <__panic>

ffffffffc02021f4 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc02021f4:	1141                	addi	sp,sp,-16
ffffffffc02021f6:	e022                	sd	s0,0(sp)
ffffffffc02021f8:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021fa:	4601                	li	a2,0
{
ffffffffc02021fc:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02021fe:	d99ff0ef          	jal	ffffffffc0201f96 <get_pte>
    if (ptep_store != NULL)
ffffffffc0202202:	c011                	beqz	s0,ffffffffc0202206 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202204:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202206:	c511                	beqz	a0,ffffffffc0202212 <get_page+0x1e>
ffffffffc0202208:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc020220a:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc020220c:	0017f713          	andi	a4,a5,1
ffffffffc0202210:	e709                	bnez	a4,ffffffffc020221a <get_page+0x26>
}
ffffffffc0202212:	60a2                	ld	ra,8(sp)
ffffffffc0202214:	6402                	ld	s0,0(sp)
ffffffffc0202216:	0141                	addi	sp,sp,16
ffffffffc0202218:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc020221a:	000af717          	auipc	a4,0xaf
ffffffffc020221e:	2e673703          	ld	a4,742(a4) # ffffffffc02b1500 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202222:	078a                	slli	a5,a5,0x2
ffffffffc0202224:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202226:	00e7ff63          	bgeu	a5,a4,ffffffffc0202244 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc020222a:	000af517          	auipc	a0,0xaf
ffffffffc020222e:	2de53503          	ld	a0,734(a0) # ffffffffc02b1508 <pages>
ffffffffc0202232:	60a2                	ld	ra,8(sp)
ffffffffc0202234:	6402                	ld	s0,0(sp)
ffffffffc0202236:	079a                	slli	a5,a5,0x6
ffffffffc0202238:	fe000737          	lui	a4,0xfe000
ffffffffc020223c:	97ba                	add	a5,a5,a4
ffffffffc020223e:	953e                	add	a0,a0,a5
ffffffffc0202240:	0141                	addi	sp,sp,16
ffffffffc0202242:	8082                	ret
ffffffffc0202244:	c8fff0ef          	jal	ffffffffc0201ed2 <pa2page.part.0>

ffffffffc0202248 <unmap_range>:
        tlb_invalidate(pgdir, la); //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc0202248:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020224a:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020224e:	e486                	sd	ra,72(sp)
ffffffffc0202250:	e0a2                	sd	s0,64(sp)
ffffffffc0202252:	fc26                	sd	s1,56(sp)
ffffffffc0202254:	f84a                	sd	s2,48(sp)
ffffffffc0202256:	f44e                	sd	s3,40(sp)
ffffffffc0202258:	f052                	sd	s4,32(sp)
ffffffffc020225a:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020225c:	03479713          	slli	a4,a5,0x34
ffffffffc0202260:	ef61                	bnez	a4,ffffffffc0202338 <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc0202262:	00200a37          	lui	s4,0x200
ffffffffc0202266:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020226a:	0145b733          	sltu	a4,a1,s4
ffffffffc020226e:	0017b793          	seqz	a5,a5
ffffffffc0202272:	8fd9                	or	a5,a5,a4
ffffffffc0202274:	842e                	mv	s0,a1
ffffffffc0202276:	84b2                	mv	s1,a2
ffffffffc0202278:	e3e5                	bnez	a5,ffffffffc0202358 <unmap_range+0x110>
ffffffffc020227a:	4785                	li	a5,1
ffffffffc020227c:	07fe                	slli	a5,a5,0x1f
ffffffffc020227e:	0785                	addi	a5,a5,1
ffffffffc0202280:	892a                	mv	s2,a0
ffffffffc0202282:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202284:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc0202288:	0cf67863          	bgeu	a2,a5,ffffffffc0202358 <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc020228c:	4601                	li	a2,0
ffffffffc020228e:	85a2                	mv	a1,s0
ffffffffc0202290:	854a                	mv	a0,s2
ffffffffc0202292:	d05ff0ef          	jal	ffffffffc0201f96 <get_pte>
ffffffffc0202296:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc0202298:	cd31                	beqz	a0,ffffffffc02022f4 <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc020229a:	6118                	ld	a4,0(a0)
ffffffffc020229c:	ef11                	bnez	a4,ffffffffc02022b8 <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020229e:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc02022a0:	c019                	beqz	s0,ffffffffc02022a6 <unmap_range+0x5e>
ffffffffc02022a2:	fe9465e3          	bltu	s0,s1,ffffffffc020228c <unmap_range+0x44>
}
ffffffffc02022a6:	60a6                	ld	ra,72(sp)
ffffffffc02022a8:	6406                	ld	s0,64(sp)
ffffffffc02022aa:	74e2                	ld	s1,56(sp)
ffffffffc02022ac:	7942                	ld	s2,48(sp)
ffffffffc02022ae:	79a2                	ld	s3,40(sp)
ffffffffc02022b0:	7a02                	ld	s4,32(sp)
ffffffffc02022b2:	6ae2                	ld	s5,24(sp)
ffffffffc02022b4:	6161                	addi	sp,sp,80
ffffffffc02022b6:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc02022b8:	00177693          	andi	a3,a4,1
ffffffffc02022bc:	d2ed                	beqz	a3,ffffffffc020229e <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc02022be:	000af697          	auipc	a3,0xaf
ffffffffc02022c2:	2426b683          	ld	a3,578(a3) # ffffffffc02b1500 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02022c6:	070a                	slli	a4,a4,0x2
ffffffffc02022c8:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc02022ca:	0ad77763          	bgeu	a4,a3,ffffffffc0202378 <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc02022ce:	000af517          	auipc	a0,0xaf
ffffffffc02022d2:	23a53503          	ld	a0,570(a0) # ffffffffc02b1508 <pages>
ffffffffc02022d6:	071a                	slli	a4,a4,0x6
ffffffffc02022d8:	fe0006b7          	lui	a3,0xfe000
ffffffffc02022dc:	9736                	add	a4,a4,a3
ffffffffc02022de:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc02022e0:	4118                	lw	a4,0(a0)
ffffffffc02022e2:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <boot_dtb+0x3dd4aa77>
ffffffffc02022e4:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc02022e6:	cb19                	beqz	a4,ffffffffc02022fc <unmap_range+0xb4>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc02022e8:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02022ec:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc02022f0:	944e                	add	s0,s0,s3
ffffffffc02022f2:	b77d                	j	ffffffffc02022a0 <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02022f4:	9452                	add	s0,s0,s4
ffffffffc02022f6:	01547433          	and	s0,s0,s5
            continue;
ffffffffc02022fa:	b75d                	j	ffffffffc02022a0 <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02022fc:	10002773          	csrr	a4,sstatus
ffffffffc0202300:	8b09                	andi	a4,a4,2
ffffffffc0202302:	eb19                	bnez	a4,ffffffffc0202318 <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc0202304:	000af717          	auipc	a4,0xaf
ffffffffc0202308:	1dc73703          	ld	a4,476(a4) # ffffffffc02b14e0 <pmm_manager>
ffffffffc020230c:	4585                	li	a1,1
ffffffffc020230e:	e03e                	sd	a5,0(sp)
ffffffffc0202310:	7318                	ld	a4,32(a4)
ffffffffc0202312:	9702                	jalr	a4
    if (flag)
ffffffffc0202314:	6782                	ld	a5,0(sp)
ffffffffc0202316:	bfc9                	j	ffffffffc02022e8 <unmap_range+0xa0>
        intr_disable();
ffffffffc0202318:	e43e                	sd	a5,8(sp)
ffffffffc020231a:	e02a                	sd	a0,0(sp)
ffffffffc020231c:	ee0fe0ef          	jal	ffffffffc02009fc <intr_disable>
ffffffffc0202320:	000af717          	auipc	a4,0xaf
ffffffffc0202324:	1c073703          	ld	a4,448(a4) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0202328:	6502                	ld	a0,0(sp)
ffffffffc020232a:	4585                	li	a1,1
ffffffffc020232c:	7318                	ld	a4,32(a4)
ffffffffc020232e:	9702                	jalr	a4
        intr_enable();
ffffffffc0202330:	ec6fe0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202334:	67a2                	ld	a5,8(sp)
ffffffffc0202336:	bf4d                	j	ffffffffc02022e8 <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202338:	00004697          	auipc	a3,0x4
ffffffffc020233c:	72068693          	addi	a3,a3,1824 # ffffffffc0206a58 <etext+0xf54>
ffffffffc0202340:	00004617          	auipc	a2,0x4
ffffffffc0202344:	26860613          	addi	a2,a2,616 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0202348:	12800593          	li	a1,296
ffffffffc020234c:	00004517          	auipc	a0,0x4
ffffffffc0202350:	6fc50513          	addi	a0,a0,1788 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0202354:	93afe0ef          	jal	ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0202358:	00004697          	auipc	a3,0x4
ffffffffc020235c:	73068693          	addi	a3,a3,1840 # ffffffffc0206a88 <etext+0xf84>
ffffffffc0202360:	00004617          	auipc	a2,0x4
ffffffffc0202364:	24860613          	addi	a2,a2,584 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0202368:	12900593          	li	a1,297
ffffffffc020236c:	00004517          	auipc	a0,0x4
ffffffffc0202370:	6dc50513          	addi	a0,a0,1756 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0202374:	91afe0ef          	jal	ffffffffc020048e <__panic>
ffffffffc0202378:	b5bff0ef          	jal	ffffffffc0201ed2 <pa2page.part.0>

ffffffffc020237c <exit_range>:
{
ffffffffc020237c:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020237e:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc0202382:	ed06                	sd	ra,152(sp)
ffffffffc0202384:	e922                	sd	s0,144(sp)
ffffffffc0202386:	e526                	sd	s1,136(sp)
ffffffffc0202388:	e14a                	sd	s2,128(sp)
ffffffffc020238a:	fcce                	sd	s3,120(sp)
ffffffffc020238c:	f8d2                	sd	s4,112(sp)
ffffffffc020238e:	f4d6                	sd	s5,104(sp)
ffffffffc0202390:	f0da                	sd	s6,96(sp)
ffffffffc0202392:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202394:	17d2                	slli	a5,a5,0x34
ffffffffc0202396:	22079263          	bnez	a5,ffffffffc02025ba <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc020239a:	00200937          	lui	s2,0x200
ffffffffc020239e:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc02023a2:	0125b733          	sltu	a4,a1,s2
ffffffffc02023a6:	0017b793          	seqz	a5,a5
ffffffffc02023aa:	8fd9                	or	a5,a5,a4
ffffffffc02023ac:	26079263          	bnez	a5,ffffffffc0202610 <exit_range+0x294>
ffffffffc02023b0:	4785                	li	a5,1
ffffffffc02023b2:	07fe                	slli	a5,a5,0x1f
ffffffffc02023b4:	0785                	addi	a5,a5,1
ffffffffc02023b6:	24f67d63          	bgeu	a2,a5,ffffffffc0202610 <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02023ba:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02023be:	ffe007b7          	lui	a5,0xffe00
ffffffffc02023c2:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02023c4:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc02023c6:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc02023ca:	000afa97          	auipc	s5,0xaf
ffffffffc02023ce:	136a8a93          	addi	s5,s5,310 # ffffffffc02b1500 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023d2:	400009b7          	lui	s3,0x40000
ffffffffc02023d6:	a809                	j	ffffffffc02023e8 <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc02023d8:	013487b3          	add	a5,s1,s3
ffffffffc02023dc:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc02023e0:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc02023e2:	c3f1                	beqz	a5,ffffffffc02024a6 <exit_range+0x12a>
ffffffffc02023e4:	0cc7f163          	bgeu	a5,a2,ffffffffc02024a6 <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02023e8:	01e4d413          	srli	s0,s1,0x1e
ffffffffc02023ec:	1ff47413          	andi	s0,s0,511
ffffffffc02023f0:	040e                	slli	s0,s0,0x3
ffffffffc02023f2:	9452                	add	s0,s0,s4
ffffffffc02023f4:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc02023f8:	0018f793          	andi	a5,a7,1
ffffffffc02023fc:	dff1                	beqz	a5,ffffffffc02023d8 <exit_range+0x5c>
ffffffffc02023fe:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202402:	088a                	slli	a7,a7,0x2
ffffffffc0202404:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc0202408:	20f8f263          	bgeu	a7,a5,ffffffffc020260c <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc020240c:	fff802b7          	lui	t0,0xfff80
ffffffffc0202410:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc0202414:	000803b7          	lui	t2,0x80
ffffffffc0202418:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc020241c:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0202420:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc0202422:	1cf77863          	bgeu	a4,a5,ffffffffc02025f2 <exit_range+0x276>
ffffffffc0202426:	000aff97          	auipc	t6,0xaf
ffffffffc020242a:	0d2f8f93          	addi	t6,t6,210 # ffffffffc02b14f8 <va_pa_offset>
ffffffffc020242e:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc0202432:	4e85                	li	t4,1
ffffffffc0202434:	6b05                	lui	s6,0x1
ffffffffc0202436:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202438:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc020243c:	01585713          	srli	a4,a6,0x15
ffffffffc0202440:	1ff77713          	andi	a4,a4,511
ffffffffc0202444:	070e                	slli	a4,a4,0x3
ffffffffc0202446:	9772                	add	a4,a4,t3
ffffffffc0202448:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc020244a:	0017f693          	andi	a3,a5,1
ffffffffc020244e:	e6bd                	bnez	a3,ffffffffc02024bc <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc0202450:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc0202452:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0202454:	00080863          	beqz	a6,ffffffffc0202464 <exit_range+0xe8>
ffffffffc0202458:	879a                	mv	a5,t1
ffffffffc020245a:	00667363          	bgeu	a2,t1,ffffffffc0202460 <exit_range+0xe4>
ffffffffc020245e:	87b2                	mv	a5,a2
ffffffffc0202460:	fcf86ee3          	bltu	a6,a5,ffffffffc020243c <exit_range+0xc0>
            if (free_pd0)
ffffffffc0202464:	f60e8ae3          	beqz	t4,ffffffffc02023d8 <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc0202468:	000ab783          	ld	a5,0(s5)
ffffffffc020246c:	1af8f063          	bgeu	a7,a5,ffffffffc020260c <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202470:	000af517          	auipc	a0,0xaf
ffffffffc0202474:	09853503          	ld	a0,152(a0) # ffffffffc02b1508 <pages>
ffffffffc0202478:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020247a:	100027f3          	csrr	a5,sstatus
ffffffffc020247e:	8b89                	andi	a5,a5,2
ffffffffc0202480:	10079b63          	bnez	a5,ffffffffc0202596 <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc0202484:	000af797          	auipc	a5,0xaf
ffffffffc0202488:	05c7b783          	ld	a5,92(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc020248c:	4585                	li	a1,1
ffffffffc020248e:	e432                	sd	a2,8(sp)
ffffffffc0202490:	739c                	ld	a5,32(a5)
ffffffffc0202492:	9782                	jalr	a5
ffffffffc0202494:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202496:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc020249a:	013487b3          	add	a5,s1,s3
ffffffffc020249e:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc02024a2:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc02024a4:	f3a1                	bnez	a5,ffffffffc02023e4 <exit_range+0x68>
}
ffffffffc02024a6:	60ea                	ld	ra,152(sp)
ffffffffc02024a8:	644a                	ld	s0,144(sp)
ffffffffc02024aa:	64aa                	ld	s1,136(sp)
ffffffffc02024ac:	690a                	ld	s2,128(sp)
ffffffffc02024ae:	79e6                	ld	s3,120(sp)
ffffffffc02024b0:	7a46                	ld	s4,112(sp)
ffffffffc02024b2:	7aa6                	ld	s5,104(sp)
ffffffffc02024b4:	7b06                	ld	s6,96(sp)
ffffffffc02024b6:	6be6                	ld	s7,88(sp)
ffffffffc02024b8:	610d                	addi	sp,sp,160
ffffffffc02024ba:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02024bc:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02024c0:	078a                	slli	a5,a5,0x2
ffffffffc02024c2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02024c4:	14a7f463          	bgeu	a5,a0,ffffffffc020260c <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02024c8:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc02024ca:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc02024ce:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02024d2:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc02024d6:	10abf263          	bgeu	s7,a0,ffffffffc02025da <exit_range+0x25e>
ffffffffc02024da:	000fb783          	ld	a5,0(t6)
ffffffffc02024de:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024e0:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc02024e4:	629c                	ld	a5,0(a3)
ffffffffc02024e6:	8b85                	andi	a5,a5,1
ffffffffc02024e8:	f7ad                	bnez	a5,ffffffffc0202452 <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc02024ea:	06a1                	addi	a3,a3,8
ffffffffc02024ec:	fea69ce3          	bne	a3,a0,ffffffffc02024e4 <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc02024f0:	000af517          	auipc	a0,0xaf
ffffffffc02024f4:	01853503          	ld	a0,24(a0) # ffffffffc02b1508 <pages>
ffffffffc02024f8:	952e                	add	a0,a0,a1
ffffffffc02024fa:	100027f3          	csrr	a5,sstatus
ffffffffc02024fe:	8b89                	andi	a5,a5,2
ffffffffc0202500:	e3b9                	bnez	a5,ffffffffc0202546 <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc0202502:	000af797          	auipc	a5,0xaf
ffffffffc0202506:	fde7b783          	ld	a5,-34(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc020250a:	4585                	li	a1,1
ffffffffc020250c:	e0b2                	sd	a2,64(sp)
ffffffffc020250e:	739c                	ld	a5,32(a5)
ffffffffc0202510:	fc1a                	sd	t1,56(sp)
ffffffffc0202512:	f846                	sd	a7,48(sp)
ffffffffc0202514:	f47a                	sd	t5,40(sp)
ffffffffc0202516:	f072                	sd	t3,32(sp)
ffffffffc0202518:	ec76                	sd	t4,24(sp)
ffffffffc020251a:	e842                	sd	a6,16(sp)
ffffffffc020251c:	e43a                	sd	a4,8(sp)
ffffffffc020251e:	9782                	jalr	a5
    if (flag)
ffffffffc0202520:	6722                	ld	a4,8(sp)
ffffffffc0202522:	6842                	ld	a6,16(sp)
ffffffffc0202524:	6ee2                	ld	t4,24(sp)
ffffffffc0202526:	7e02                	ld	t3,32(sp)
ffffffffc0202528:	7f22                	ld	t5,40(sp)
ffffffffc020252a:	78c2                	ld	a7,48(sp)
ffffffffc020252c:	7362                	ld	t1,56(sp)
ffffffffc020252e:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202530:	fff802b7          	lui	t0,0xfff80
ffffffffc0202534:	000803b7          	lui	t2,0x80
ffffffffc0202538:	000aff97          	auipc	t6,0xaf
ffffffffc020253c:	fc0f8f93          	addi	t6,t6,-64 # ffffffffc02b14f8 <va_pa_offset>
ffffffffc0202540:	00073023          	sd	zero,0(a4)
ffffffffc0202544:	b739                	j	ffffffffc0202452 <exit_range+0xd6>
        intr_disable();
ffffffffc0202546:	e4b2                	sd	a2,72(sp)
ffffffffc0202548:	e09a                	sd	t1,64(sp)
ffffffffc020254a:	fc46                	sd	a7,56(sp)
ffffffffc020254c:	f47a                	sd	t5,40(sp)
ffffffffc020254e:	f072                	sd	t3,32(sp)
ffffffffc0202550:	ec76                	sd	t4,24(sp)
ffffffffc0202552:	e842                	sd	a6,16(sp)
ffffffffc0202554:	e43a                	sd	a4,8(sp)
ffffffffc0202556:	f82a                	sd	a0,48(sp)
ffffffffc0202558:	ca4fe0ef          	jal	ffffffffc02009fc <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020255c:	000af797          	auipc	a5,0xaf
ffffffffc0202560:	f847b783          	ld	a5,-124(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0202564:	7542                	ld	a0,48(sp)
ffffffffc0202566:	4585                	li	a1,1
ffffffffc0202568:	739c                	ld	a5,32(a5)
ffffffffc020256a:	9782                	jalr	a5
        intr_enable();
ffffffffc020256c:	c8afe0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202570:	6722                	ld	a4,8(sp)
ffffffffc0202572:	6626                	ld	a2,72(sp)
ffffffffc0202574:	6306                	ld	t1,64(sp)
ffffffffc0202576:	78e2                	ld	a7,56(sp)
ffffffffc0202578:	7f22                	ld	t5,40(sp)
ffffffffc020257a:	7e02                	ld	t3,32(sp)
ffffffffc020257c:	6ee2                	ld	t4,24(sp)
ffffffffc020257e:	6842                	ld	a6,16(sp)
ffffffffc0202580:	000aff97          	auipc	t6,0xaf
ffffffffc0202584:	f78f8f93          	addi	t6,t6,-136 # ffffffffc02b14f8 <va_pa_offset>
ffffffffc0202588:	000803b7          	lui	t2,0x80
ffffffffc020258c:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202590:	00073023          	sd	zero,0(a4)
ffffffffc0202594:	bd7d                	j	ffffffffc0202452 <exit_range+0xd6>
        intr_disable();
ffffffffc0202596:	e832                	sd	a2,16(sp)
ffffffffc0202598:	e42a                	sd	a0,8(sp)
ffffffffc020259a:	c62fe0ef          	jal	ffffffffc02009fc <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020259e:	000af797          	auipc	a5,0xaf
ffffffffc02025a2:	f427b783          	ld	a5,-190(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc02025a6:	6522                	ld	a0,8(sp)
ffffffffc02025a8:	4585                	li	a1,1
ffffffffc02025aa:	739c                	ld	a5,32(a5)
ffffffffc02025ac:	9782                	jalr	a5
        intr_enable();
ffffffffc02025ae:	c48fe0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc02025b2:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc02025b4:	00043023          	sd	zero,0(s0)
ffffffffc02025b8:	b5cd                	j	ffffffffc020249a <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02025ba:	00004697          	auipc	a3,0x4
ffffffffc02025be:	49e68693          	addi	a3,a3,1182 # ffffffffc0206a58 <etext+0xf54>
ffffffffc02025c2:	00004617          	auipc	a2,0x4
ffffffffc02025c6:	fe660613          	addi	a2,a2,-26 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02025ca:	13d00593          	li	a1,317
ffffffffc02025ce:	00004517          	auipc	a0,0x4
ffffffffc02025d2:	47a50513          	addi	a0,a0,1146 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02025d6:	eb9fd0ef          	jal	ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02025da:	00004617          	auipc	a2,0x4
ffffffffc02025de:	37e60613          	addi	a2,a2,894 # ffffffffc0206958 <etext+0xe54>
ffffffffc02025e2:	07100593          	li	a1,113
ffffffffc02025e6:	00004517          	auipc	a0,0x4
ffffffffc02025ea:	39a50513          	addi	a0,a0,922 # ffffffffc0206980 <etext+0xe7c>
ffffffffc02025ee:	ea1fd0ef          	jal	ffffffffc020048e <__panic>
ffffffffc02025f2:	86f2                	mv	a3,t3
ffffffffc02025f4:	00004617          	auipc	a2,0x4
ffffffffc02025f8:	36460613          	addi	a2,a2,868 # ffffffffc0206958 <etext+0xe54>
ffffffffc02025fc:	07100593          	li	a1,113
ffffffffc0202600:	00004517          	auipc	a0,0x4
ffffffffc0202604:	38050513          	addi	a0,a0,896 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0202608:	e87fd0ef          	jal	ffffffffc020048e <__panic>
ffffffffc020260c:	8c7ff0ef          	jal	ffffffffc0201ed2 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0202610:	00004697          	auipc	a3,0x4
ffffffffc0202614:	47868693          	addi	a3,a3,1144 # ffffffffc0206a88 <etext+0xf84>
ffffffffc0202618:	00004617          	auipc	a2,0x4
ffffffffc020261c:	f9060613          	addi	a2,a2,-112 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0202620:	13e00593          	li	a1,318
ffffffffc0202624:	00004517          	auipc	a0,0x4
ffffffffc0202628:	42450513          	addi	a0,a0,1060 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020262c:	e63fd0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0202630 <page_remove>:
{
ffffffffc0202630:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202632:	4601                	li	a2,0
{
ffffffffc0202634:	e822                	sd	s0,16(sp)
ffffffffc0202636:	ec06                	sd	ra,24(sp)
ffffffffc0202638:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020263a:	95dff0ef          	jal	ffffffffc0201f96 <get_pte>
    if (ptep != NULL)
ffffffffc020263e:	c511                	beqz	a0,ffffffffc020264a <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc0202640:	6118                	ld	a4,0(a0)
ffffffffc0202642:	87aa                	mv	a5,a0
ffffffffc0202644:	00177693          	andi	a3,a4,1
ffffffffc0202648:	e689                	bnez	a3,ffffffffc0202652 <page_remove+0x22>
}
ffffffffc020264a:	60e2                	ld	ra,24(sp)
ffffffffc020264c:	6442                	ld	s0,16(sp)
ffffffffc020264e:	6105                	addi	sp,sp,32
ffffffffc0202650:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202652:	000af697          	auipc	a3,0xaf
ffffffffc0202656:	eae6b683          	ld	a3,-338(a3) # ffffffffc02b1500 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc020265a:	070a                	slli	a4,a4,0x2
ffffffffc020265c:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc020265e:	06d77563          	bgeu	a4,a3,ffffffffc02026c8 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0202662:	000af517          	auipc	a0,0xaf
ffffffffc0202666:	ea653503          	ld	a0,-346(a0) # ffffffffc02b1508 <pages>
ffffffffc020266a:	071a                	slli	a4,a4,0x6
ffffffffc020266c:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202670:	9736                	add	a4,a4,a3
ffffffffc0202672:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202674:	4118                	lw	a4,0(a0)
ffffffffc0202676:	377d                	addiw	a4,a4,-1
ffffffffc0202678:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc020267a:	cb09                	beqz	a4,ffffffffc020268c <page_remove+0x5c>
        *ptep = 0;                 //(5) clear second page table entry
ffffffffc020267c:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202680:	12040073          	sfence.vma	s0
}
ffffffffc0202684:	60e2                	ld	ra,24(sp)
ffffffffc0202686:	6442                	ld	s0,16(sp)
ffffffffc0202688:	6105                	addi	sp,sp,32
ffffffffc020268a:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020268c:	10002773          	csrr	a4,sstatus
ffffffffc0202690:	8b09                	andi	a4,a4,2
ffffffffc0202692:	eb19                	bnez	a4,ffffffffc02026a8 <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc0202694:	000af717          	auipc	a4,0xaf
ffffffffc0202698:	e4c73703          	ld	a4,-436(a4) # ffffffffc02b14e0 <pmm_manager>
ffffffffc020269c:	4585                	li	a1,1
ffffffffc020269e:	e03e                	sd	a5,0(sp)
ffffffffc02026a0:	7318                	ld	a4,32(a4)
ffffffffc02026a2:	9702                	jalr	a4
    if (flag)
ffffffffc02026a4:	6782                	ld	a5,0(sp)
ffffffffc02026a6:	bfd9                	j	ffffffffc020267c <page_remove+0x4c>
        intr_disable();
ffffffffc02026a8:	e43e                	sd	a5,8(sp)
ffffffffc02026aa:	e02a                	sd	a0,0(sp)
ffffffffc02026ac:	b50fe0ef          	jal	ffffffffc02009fc <intr_disable>
ffffffffc02026b0:	000af717          	auipc	a4,0xaf
ffffffffc02026b4:	e3073703          	ld	a4,-464(a4) # ffffffffc02b14e0 <pmm_manager>
ffffffffc02026b8:	6502                	ld	a0,0(sp)
ffffffffc02026ba:	4585                	li	a1,1
ffffffffc02026bc:	7318                	ld	a4,32(a4)
ffffffffc02026be:	9702                	jalr	a4
        intr_enable();
ffffffffc02026c0:	b36fe0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc02026c4:	67a2                	ld	a5,8(sp)
ffffffffc02026c6:	bf5d                	j	ffffffffc020267c <page_remove+0x4c>
ffffffffc02026c8:	80bff0ef          	jal	ffffffffc0201ed2 <pa2page.part.0>

ffffffffc02026cc <page_insert>:
{
ffffffffc02026cc:	7139                	addi	sp,sp,-64
ffffffffc02026ce:	f426                	sd	s1,40(sp)
ffffffffc02026d0:	84b2                	mv	s1,a2
ffffffffc02026d2:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026d4:	4605                	li	a2,1
{
ffffffffc02026d6:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026d8:	85a6                	mv	a1,s1
{
ffffffffc02026da:	fc06                	sd	ra,56(sp)
ffffffffc02026dc:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02026de:	8b9ff0ef          	jal	ffffffffc0201f96 <get_pte>
    if (ptep == NULL)
ffffffffc02026e2:	cd61                	beqz	a0,ffffffffc02027ba <page_insert+0xee>
    page->ref += 1;
ffffffffc02026e4:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc02026e6:	611c                	ld	a5,0(a0)
ffffffffc02026e8:	66a2                	ld	a3,8(sp)
ffffffffc02026ea:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7f1f>
ffffffffc02026ee:	c010                	sw	a2,0(s0)
ffffffffc02026f0:	0017f613          	andi	a2,a5,1
ffffffffc02026f4:	872a                	mv	a4,a0
ffffffffc02026f6:	e61d                	bnez	a2,ffffffffc0202724 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc02026f8:	000af617          	auipc	a2,0xaf
ffffffffc02026fc:	e1063603          	ld	a2,-496(a2) # ffffffffc02b1508 <pages>
    return page - pages + nbase;
ffffffffc0202700:	8c11                	sub	s0,s0,a2
ffffffffc0202702:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202704:	200007b7          	lui	a5,0x20000
ffffffffc0202708:	042a                	slli	s0,s0,0xa
ffffffffc020270a:	943e                	add	s0,s0,a5
ffffffffc020270c:	8ec1                	or	a3,a3,s0
ffffffffc020270e:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0202712:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202714:	12048073          	sfence.vma	s1
    return 0;
ffffffffc0202718:	4501                	li	a0,0
}
ffffffffc020271a:	70e2                	ld	ra,56(sp)
ffffffffc020271c:	7442                	ld	s0,48(sp)
ffffffffc020271e:	74a2                	ld	s1,40(sp)
ffffffffc0202720:	6121                	addi	sp,sp,64
ffffffffc0202722:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202724:	000af617          	auipc	a2,0xaf
ffffffffc0202728:	ddc63603          	ld	a2,-548(a2) # ffffffffc02b1500 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc020272c:	078a                	slli	a5,a5,0x2
ffffffffc020272e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202730:	08c7f763          	bgeu	a5,a2,ffffffffc02027be <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0202734:	000af617          	auipc	a2,0xaf
ffffffffc0202738:	dd463603          	ld	a2,-556(a2) # ffffffffc02b1508 <pages>
ffffffffc020273c:	fe000537          	lui	a0,0xfe000
ffffffffc0202740:	079a                	slli	a5,a5,0x6
ffffffffc0202742:	97aa                	add	a5,a5,a0
ffffffffc0202744:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc0202748:	00a40963          	beq	s0,a0,ffffffffc020275a <page_insert+0x8e>
    page->ref -= 1;
ffffffffc020274c:	411c                	lw	a5,0(a0)
ffffffffc020274e:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_matrix_out_size+0x1fff4ad7>
ffffffffc0202750:	c11c                	sw	a5,0(a0)
        if (page_ref(page) ==
ffffffffc0202752:	c791                	beqz	a5,ffffffffc020275e <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202754:	12048073          	sfence.vma	s1
}
ffffffffc0202758:	b765                	j	ffffffffc0202700 <page_insert+0x34>
ffffffffc020275a:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc020275c:	b755                	j	ffffffffc0202700 <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020275e:	100027f3          	csrr	a5,sstatus
ffffffffc0202762:	8b89                	andi	a5,a5,2
ffffffffc0202764:	e39d                	bnez	a5,ffffffffc020278a <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc0202766:	000af797          	auipc	a5,0xaf
ffffffffc020276a:	d7a7b783          	ld	a5,-646(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc020276e:	4585                	li	a1,1
ffffffffc0202770:	e83a                	sd	a4,16(sp)
ffffffffc0202772:	739c                	ld	a5,32(a5)
ffffffffc0202774:	e436                	sd	a3,8(sp)
ffffffffc0202776:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202778:	000af617          	auipc	a2,0xaf
ffffffffc020277c:	d9063603          	ld	a2,-624(a2) # ffffffffc02b1508 <pages>
ffffffffc0202780:	66a2                	ld	a3,8(sp)
ffffffffc0202782:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202784:	12048073          	sfence.vma	s1
ffffffffc0202788:	bfa5                	j	ffffffffc0202700 <page_insert+0x34>
        intr_disable();
ffffffffc020278a:	ec3a                	sd	a4,24(sp)
ffffffffc020278c:	e836                	sd	a3,16(sp)
ffffffffc020278e:	e42a                	sd	a0,8(sp)
ffffffffc0202790:	a6cfe0ef          	jal	ffffffffc02009fc <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202794:	000af797          	auipc	a5,0xaf
ffffffffc0202798:	d4c7b783          	ld	a5,-692(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc020279c:	6522                	ld	a0,8(sp)
ffffffffc020279e:	4585                	li	a1,1
ffffffffc02027a0:	739c                	ld	a5,32(a5)
ffffffffc02027a2:	9782                	jalr	a5
        intr_enable();
ffffffffc02027a4:	a52fe0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc02027a8:	000af617          	auipc	a2,0xaf
ffffffffc02027ac:	d6063603          	ld	a2,-672(a2) # ffffffffc02b1508 <pages>
ffffffffc02027b0:	6762                	ld	a4,24(sp)
ffffffffc02027b2:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02027b4:	12048073          	sfence.vma	s1
ffffffffc02027b8:	b7a1                	j	ffffffffc0202700 <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc02027ba:	5571                	li	a0,-4
ffffffffc02027bc:	bfb9                	j	ffffffffc020271a <page_insert+0x4e>
ffffffffc02027be:	f14ff0ef          	jal	ffffffffc0201ed2 <pa2page.part.0>

ffffffffc02027c2 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc02027c2:	00005797          	auipc	a5,0x5
ffffffffc02027c6:	2c678793          	addi	a5,a5,710 # ffffffffc0207a88 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027ca:	638c                	ld	a1,0(a5)
{
ffffffffc02027cc:	7159                	addi	sp,sp,-112
ffffffffc02027ce:	f486                	sd	ra,104(sp)
ffffffffc02027d0:	e8ca                	sd	s2,80(sp)
ffffffffc02027d2:	e4ce                	sd	s3,72(sp)
ffffffffc02027d4:	f85a                	sd	s6,48(sp)
ffffffffc02027d6:	f0a2                	sd	s0,96(sp)
ffffffffc02027d8:	eca6                	sd	s1,88(sp)
ffffffffc02027da:	e0d2                	sd	s4,64(sp)
ffffffffc02027dc:	fc56                	sd	s5,56(sp)
ffffffffc02027de:	f45e                	sd	s7,40(sp)
ffffffffc02027e0:	f062                	sd	s8,32(sp)
ffffffffc02027e2:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02027e4:	000afb17          	auipc	s6,0xaf
ffffffffc02027e8:	cfcb0b13          	addi	s6,s6,-772 # ffffffffc02b14e0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027ec:	00004517          	auipc	a0,0x4
ffffffffc02027f0:	2b450513          	addi	a0,a0,692 # ffffffffc0206aa0 <etext+0xf9c>
    pmm_manager = &default_pmm_manager;
ffffffffc02027f4:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02027f8:	9e5fd0ef          	jal	ffffffffc02001dc <cprintf>
    pmm_manager->init();
ffffffffc02027fc:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202800:	000af997          	auipc	s3,0xaf
ffffffffc0202804:	cf898993          	addi	s3,s3,-776 # ffffffffc02b14f8 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202808:	679c                	ld	a5,8(a5)
ffffffffc020280a:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020280c:	57f5                	li	a5,-3
ffffffffc020280e:	07fa                	slli	a5,a5,0x1e
ffffffffc0202810:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc0202814:	9cefe0ef          	jal	ffffffffc02009e2 <get_memory_base>
ffffffffc0202818:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc020281a:	9d2fe0ef          	jal	ffffffffc02009ec <get_memory_size>
    if (mem_size == 0)
ffffffffc020281e:	70050963          	beqz	a0,ffffffffc0202f30 <pmm_init+0x76e>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202822:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0202824:	00004517          	auipc	a0,0x4
ffffffffc0202828:	2b450513          	addi	a0,a0,692 # ffffffffc0206ad8 <etext+0xfd4>
ffffffffc020282c:	9b1fd0ef          	jal	ffffffffc02001dc <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc0202830:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0202834:	864a                	mv	a2,s2
ffffffffc0202836:	85a6                	mv	a1,s1
ffffffffc0202838:	fff40693          	addi	a3,s0,-1
ffffffffc020283c:	00004517          	auipc	a0,0x4
ffffffffc0202840:	2b450513          	addi	a0,a0,692 # ffffffffc0206af0 <etext+0xfec>
ffffffffc0202844:	999fd0ef          	jal	ffffffffc02001dc <cprintf>
    if (maxpa > KERNTOP)
ffffffffc0202848:	c80007b7          	lui	a5,0xc8000
ffffffffc020284c:	8622                	mv	a2,s0
ffffffffc020284e:	5487e663          	bltu	a5,s0,ffffffffc0202d9a <pmm_init+0x5d8>
ffffffffc0202852:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202854:	000b4697          	auipc	a3,0xb4
ffffffffc0202858:	d2b68693          	addi	a3,a3,-725 # ffffffffc02b657f <boot_dtb+0xff7>
ffffffffc020285c:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc020285e:	8231                	srli	a2,a2,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202860:	000afb97          	auipc	s7,0xaf
ffffffffc0202864:	ca8b8b93          	addi	s7,s7,-856 # ffffffffc02b1508 <pages>
    npage = maxpa / PGSIZE;
ffffffffc0202868:	000af497          	auipc	s1,0xaf
ffffffffc020286c:	c9848493          	addi	s1,s1,-872 # ffffffffc02b1500 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202870:	00dbb023          	sd	a3,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202874:	e090                	sd	a2,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202876:	00080737          	lui	a4,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc020287a:	87b6                	mv	a5,a3
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020287c:	02e60663          	beq	a2,a4,ffffffffc02028a8 <pmm_init+0xe6>
ffffffffc0202880:	4701                	li	a4,0
ffffffffc0202882:	4505                	li	a0,1
ffffffffc0202884:	fff805b7          	lui	a1,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202888:	00671793          	slli	a5,a4,0x6
ffffffffc020288c:	97b6                	add	a5,a5,a3
ffffffffc020288e:	07a1                	addi	a5,a5,8 # fffffffffffff008 <boot_dtb+0x3fd49a80>
ffffffffc0202890:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202894:	6090                	ld	a2,0(s1)
ffffffffc0202896:	0705                	addi	a4,a4,1 # 80001 <_binary_obj___user_matrix_out_size+0x74ad9>
    uintptr_t freemem = (uintptr_t)pages + sizeof(struct Page) * (npage - nbase);
ffffffffc0202898:	000bb683          	ld	a3,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc020289c:	00b607b3          	add	a5,a2,a1
ffffffffc02028a0:	fef764e3          	bltu	a4,a5,ffffffffc0202888 <pmm_init+0xc6>
    uintptr_t freemem = (uintptr_t)pages + sizeof(struct Page) * (npage - nbase);
ffffffffc02028a4:	079a                	slli	a5,a5,0x6
ffffffffc02028a6:	97b6                	add	a5,a5,a3
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02028a8:	777d                	lui	a4,0xfffff
ffffffffc02028aa:	8c79                	and	s0,s0,a4
    if (freemem < mem_end)
ffffffffc02028ac:	4e87e963          	bltu	a5,s0,ffffffffc0202d9e <pmm_init+0x5dc>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc02028b0:	0009b583          	ld	a1,0(s3)
ffffffffc02028b4:	00004517          	auipc	a0,0x4
ffffffffc02028b8:	26450513          	addi	a0,a0,612 # ffffffffc0206b18 <etext+0x1014>
ffffffffc02028bc:	921fd0ef          	jal	ffffffffc02001dc <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc02028c0:	000b3783          	ld	a5,0(s6)
ffffffffc02028c4:	7b9c                	ld	a5,48(a5)
ffffffffc02028c6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02028c8:	00004517          	auipc	a0,0x4
ffffffffc02028cc:	26850513          	addi	a0,a0,616 # ffffffffc0206b30 <etext+0x102c>
ffffffffc02028d0:	90dfd0ef          	jal	ffffffffc02001dc <cprintf>
    if (boot_pg_addr < KERNBASE && boot_pg_addr >= 0x80000000) {
ffffffffc02028d4:	a0100793          	li	a5,-1535
    uintptr_t boot_pg_addr = (uintptr_t)boot_page_table_sv39;
ffffffffc02028d8:	00008697          	auipc	a3,0x8
ffffffffc02028dc:	72868693          	addi	a3,a3,1832 # ffffffffc020b000 <boot_page_table_sv39>
    if (boot_pg_addr < KERNBASE && boot_pg_addr >= 0x80000000) {
ffffffffc02028e0:	07d6                	slli	a5,a5,0x15
ffffffffc02028e2:	80008617          	auipc	a2,0x80008
ffffffffc02028e6:	71e60613          	addi	a2,a2,1822 # ffffffff4020b000 <_binary_obj___user_matrix_out_size+0xffffffff401ffad8>
ffffffffc02028ea:	8736                	mv	a4,a3
ffffffffc02028ec:	4af66263          	bltu	a2,a5,ffffffffc0202d90 <pmm_init+0x5ce>
    boot_pgdir_va = (pte_t *)boot_pg_addr;
ffffffffc02028f0:	000af917          	auipc	s2,0xaf
ffffffffc02028f4:	c0090913          	addi	s2,s2,-1024 # ffffffffc02b14f0 <boot_pgdir_va>
ffffffffc02028f8:	00e93023          	sd	a4,0(s2)
    boot_pgdir_pa = PADDR((uintptr_t)boot_pgdir_va);
ffffffffc02028fc:	c02007b7          	lui	a5,0xc0200
ffffffffc0202900:	72f6e463          	bltu	a3,a5,ffffffffc0203028 <pmm_init+0x866>
ffffffffc0202904:	0009b783          	ld	a5,0(s3)
ffffffffc0202908:	8e9d                	sub	a3,a3,a5
ffffffffc020290a:	000af797          	auipc	a5,0xaf
ffffffffc020290e:	bcd7bf23          	sd	a3,-1058(a5) # ffffffffc02b14e8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202912:	100027f3          	csrr	a5,sstatus
ffffffffc0202916:	8b89                	andi	a5,a5,2
ffffffffc0202918:	4c079463          	bnez	a5,ffffffffc0202de0 <pmm_init+0x61e>
        ret = pmm_manager->nr_free_pages();
ffffffffc020291c:	000b3783          	ld	a5,0(s6)
ffffffffc0202920:	779c                	ld	a5,40(a5)
ffffffffc0202922:	9782                	jalr	a5
ffffffffc0202924:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202926:	6098                	ld	a4,0(s1)
ffffffffc0202928:	c80007b7          	lui	a5,0xc8000
ffffffffc020292c:	83b1                	srli	a5,a5,0xc
ffffffffc020292e:	74e7e963          	bltu	a5,a4,ffffffffc0203080 <pmm_init+0x8be>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202932:	00093503          	ld	a0,0(s2)
ffffffffc0202936:	72050563          	beqz	a0,ffffffffc0203060 <pmm_init+0x89e>
ffffffffc020293a:	03451793          	slli	a5,a0,0x34
ffffffffc020293e:	72079163          	bnez	a5,ffffffffc0203060 <pmm_init+0x89e>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0202942:	4601                	li	a2,0
ffffffffc0202944:	4581                	li	a1,0
ffffffffc0202946:	8afff0ef          	jal	ffffffffc02021f4 <get_page>
ffffffffc020294a:	240510e3          	bnez	a0,ffffffffc020338a <pmm_init+0xbc8>
ffffffffc020294e:	100027f3          	csrr	a5,sstatus
ffffffffc0202952:	8b89                	andi	a5,a5,2
ffffffffc0202954:	46079b63          	bnez	a5,ffffffffc0202dca <pmm_init+0x608>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202958:	000b3783          	ld	a5,0(s6)
ffffffffc020295c:	4505                	li	a0,1
ffffffffc020295e:	6f9c                	ld	a5,24(a5)
ffffffffc0202960:	9782                	jalr	a5
ffffffffc0202962:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0202964:	00093503          	ld	a0,0(s2)
ffffffffc0202968:	4681                	li	a3,0
ffffffffc020296a:	4601                	li	a2,0
ffffffffc020296c:	85d2                	mv	a1,s4
ffffffffc020296e:	d5fff0ef          	jal	ffffffffc02026cc <page_insert>
ffffffffc0202972:	140517e3          	bnez	a0,ffffffffc02032c0 <pmm_init+0xafe>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0202976:	00093503          	ld	a0,0(s2)
ffffffffc020297a:	4601                	li	a2,0
ffffffffc020297c:	4581                	li	a1,0
ffffffffc020297e:	e18ff0ef          	jal	ffffffffc0201f96 <get_pte>
ffffffffc0202982:	78050f63          	beqz	a0,ffffffffc0203120 <pmm_init+0x95e>
    assert(pte2page(*ptep) == p1);
ffffffffc0202986:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202988:	0017f713          	andi	a4,a5,1
ffffffffc020298c:	20070fe3          	beqz	a4,ffffffffc02033aa <pmm_init+0xbe8>
    if (PPN(pa) >= npage)
ffffffffc0202990:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202992:	078a                	slli	a5,a5,0x2
ffffffffc0202994:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202996:	58e7fb63          	bgeu	a5,a4,ffffffffc0202f2c <pmm_init+0x76a>
    return &pages[PPN(pa) - nbase];
ffffffffc020299a:	000bb683          	ld	a3,0(s7)
ffffffffc020299e:	079a                	slli	a5,a5,0x6
ffffffffc02029a0:	fe000637          	lui	a2,0xfe000
ffffffffc02029a4:	97b2                	add	a5,a5,a2
ffffffffc02029a6:	97b6                	add	a5,a5,a3
ffffffffc02029a8:	22fa1de3          	bne	s4,a5,ffffffffc02033e2 <pmm_init+0xc20>
    assert(page_ref(p1) == 1);
ffffffffc02029ac:	000a2683          	lw	a3,0(s4) # 200000 <_binary_obj___user_matrix_out_size+0x1f4ad8>
ffffffffc02029b0:	4785                	li	a5,1
ffffffffc02029b2:	20f698e3          	bne	a3,a5,ffffffffc02033c2 <pmm_init+0xc00>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02029b6:	00093503          	ld	a0,0(s2)
ffffffffc02029ba:	77fd                	lui	a5,0xfffff
ffffffffc02029bc:	6114                	ld	a3,0(a0)
ffffffffc02029be:	068a                	slli	a3,a3,0x2
ffffffffc02029c0:	8efd                	and	a3,a3,a5
ffffffffc02029c2:	00c6d613          	srli	a2,a3,0xc
ffffffffc02029c6:	12e67ae3          	bgeu	a2,a4,ffffffffc02032fa <pmm_init+0xb38>
ffffffffc02029ca:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029ce:	96e2                	add	a3,a3,s8
ffffffffc02029d0:	0006ba83          	ld	s5,0(a3)
ffffffffc02029d4:	0a8a                	slli	s5,s5,0x2
ffffffffc02029d6:	00fafab3          	and	s5,s5,a5
ffffffffc02029da:	00cad793          	srli	a5,s5,0xc
ffffffffc02029de:	10e7f1e3          	bgeu	a5,a4,ffffffffc02032e0 <pmm_init+0xb1e>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029e2:	4601                	li	a2,0
ffffffffc02029e4:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029e6:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029e8:	daeff0ef          	jal	ffffffffc0201f96 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02029ec:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02029ee:	79851963          	bne	a0,s8,ffffffffc0203180 <pmm_init+0x9be>
ffffffffc02029f2:	100027f3          	csrr	a5,sstatus
ffffffffc02029f6:	8b89                	andi	a5,a5,2
ffffffffc02029f8:	3e079e63          	bnez	a5,ffffffffc0202df4 <pmm_init+0x632>
        page = pmm_manager->alloc_pages(n);
ffffffffc02029fc:	000b3783          	ld	a5,0(s6)
ffffffffc0202a00:	4505                	li	a0,1
ffffffffc0202a02:	6f9c                	ld	a5,24(a5)
ffffffffc0202a04:	9782                	jalr	a5
ffffffffc0202a06:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202a08:	00093503          	ld	a0,0(s2)
ffffffffc0202a0c:	46d1                	li	a3,20
ffffffffc0202a0e:	6605                	lui	a2,0x1
ffffffffc0202a10:	85e2                	mv	a1,s8
ffffffffc0202a12:	cbbff0ef          	jal	ffffffffc02026cc <page_insert>
ffffffffc0202a16:	78051563          	bnez	a0,ffffffffc02031a0 <pmm_init+0x9de>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a1a:	00093503          	ld	a0,0(s2)
ffffffffc0202a1e:	4601                	li	a2,0
ffffffffc0202a20:	6585                	lui	a1,0x1
ffffffffc0202a22:	d74ff0ef          	jal	ffffffffc0201f96 <get_pte>
ffffffffc0202a26:	72050d63          	beqz	a0,ffffffffc0203160 <pmm_init+0x99e>
    assert(*ptep & PTE_U);
ffffffffc0202a2a:	611c                	ld	a5,0(a0)
ffffffffc0202a2c:	0107f713          	andi	a4,a5,16
ffffffffc0202a30:	70070863          	beqz	a4,ffffffffc0203140 <pmm_init+0x97e>
    assert(*ptep & PTE_W);
ffffffffc0202a34:	8b91                	andi	a5,a5,4
ffffffffc0202a36:	60078563          	beqz	a5,ffffffffc0203040 <pmm_init+0x87e>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0202a3a:	00093503          	ld	a0,0(s2)
ffffffffc0202a3e:	611c                	ld	a5,0(a0)
ffffffffc0202a40:	8bc1                	andi	a5,a5,16
ffffffffc0202a42:	6a078f63          	beqz	a5,ffffffffc0203100 <pmm_init+0x93e>
    assert(page_ref(p2) == 1);
ffffffffc0202a46:	000c2703          	lw	a4,0(s8)
ffffffffc0202a4a:	4785                	li	a5,1
ffffffffc0202a4c:	68f71a63          	bne	a4,a5,ffffffffc02030e0 <pmm_init+0x91e>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0202a50:	4681                	li	a3,0
ffffffffc0202a52:	6605                	lui	a2,0x1
ffffffffc0202a54:	85d2                	mv	a1,s4
ffffffffc0202a56:	c77ff0ef          	jal	ffffffffc02026cc <page_insert>
ffffffffc0202a5a:	66051363          	bnez	a0,ffffffffc02030c0 <pmm_init+0x8fe>
    assert(page_ref(p1) == 2);
ffffffffc0202a5e:	000a2703          	lw	a4,0(s4)
ffffffffc0202a62:	4789                	li	a5,2
ffffffffc0202a64:	62f71e63          	bne	a4,a5,ffffffffc02030a0 <pmm_init+0x8de>
    assert(page_ref(p2) == 0);
ffffffffc0202a68:	000c2783          	lw	a5,0(s8)
ffffffffc0202a6c:	78079a63          	bnez	a5,ffffffffc0203200 <pmm_init+0xa3e>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0202a70:	00093503          	ld	a0,0(s2)
ffffffffc0202a74:	4601                	li	a2,0
ffffffffc0202a76:	6585                	lui	a1,0x1
ffffffffc0202a78:	d1eff0ef          	jal	ffffffffc0201f96 <get_pte>
ffffffffc0202a7c:	76050263          	beqz	a0,ffffffffc02031e0 <pmm_init+0xa1e>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a80:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a82:	00177793          	andi	a5,a4,1
ffffffffc0202a86:	120782e3          	beqz	a5,ffffffffc02033aa <pmm_init+0xbe8>
    if (PPN(pa) >= npage)
ffffffffc0202a8a:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a8c:	00271793          	slli	a5,a4,0x2
ffffffffc0202a90:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a92:	48d7fd63          	bgeu	a5,a3,ffffffffc0202f2c <pmm_init+0x76a>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a96:	000bb683          	ld	a3,0(s7)
ffffffffc0202a9a:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a9e:	97d6                	add	a5,a5,s5
ffffffffc0202aa0:	079a                	slli	a5,a5,0x6
ffffffffc0202aa2:	97b6                	add	a5,a5,a3
ffffffffc0202aa4:	70fa1e63          	bne	s4,a5,ffffffffc02031c0 <pmm_init+0x9fe>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202aa8:	8b41                	andi	a4,a4,16
ffffffffc0202aaa:	7e071b63          	bnez	a4,ffffffffc02032a0 <pmm_init+0xade>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202aae:	00093503          	ld	a0,0(s2)
ffffffffc0202ab2:	4581                	li	a1,0
ffffffffc0202ab4:	b7dff0ef          	jal	ffffffffc0202630 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202ab8:	000a2c83          	lw	s9,0(s4)
ffffffffc0202abc:	4785                	li	a5,1
ffffffffc0202abe:	7cfc9163          	bne	s9,a5,ffffffffc0203280 <pmm_init+0xabe>
    assert(page_ref(p2) == 0);
ffffffffc0202ac2:	000c2783          	lw	a5,0(s8)
ffffffffc0202ac6:	78079d63          	bnez	a5,ffffffffc0203260 <pmm_init+0xa9e>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202aca:	00093503          	ld	a0,0(s2)
ffffffffc0202ace:	6585                	lui	a1,0x1
ffffffffc0202ad0:	b61ff0ef          	jal	ffffffffc0202630 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202ad4:	000a2783          	lw	a5,0(s4)
ffffffffc0202ad8:	76079463          	bnez	a5,ffffffffc0203240 <pmm_init+0xa7e>
    assert(page_ref(p2) == 0);
ffffffffc0202adc:	000c2783          	lw	a5,0(s8)
ffffffffc0202ae0:	74079063          	bnez	a5,ffffffffc0203220 <pmm_init+0xa5e>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202ae4:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202ae8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aea:	000a3783          	ld	a5,0(s4)
ffffffffc0202aee:	078a                	slli	a5,a5,0x2
ffffffffc0202af0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202af2:	42e7fd63          	bgeu	a5,a4,ffffffffc0202f2c <pmm_init+0x76a>
    return &pages[PPN(pa) - nbase];
ffffffffc0202af6:	000bb503          	ld	a0,0(s7)
ffffffffc0202afa:	97d6                	add	a5,a5,s5
ffffffffc0202afc:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202afe:	00f506b3          	add	a3,a0,a5
ffffffffc0202b02:	4294                	lw	a3,0(a3)
ffffffffc0202b04:	079693e3          	bne	a3,s9,ffffffffc020336a <pmm_init+0xba8>
    return page - pages + nbase;
ffffffffc0202b08:	8799                	srai	a5,a5,0x6
ffffffffc0202b0a:	00080637          	lui	a2,0x80
ffffffffc0202b0e:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202b10:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202b14:	02e7ffe3          	bgeu	a5,a4,ffffffffc0203352 <pmm_init+0xb90>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202b18:	0009b783          	ld	a5,0(s3)
ffffffffc0202b1c:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b1e:	639c                	ld	a5,0(a5)
ffffffffc0202b20:	078a                	slli	a5,a5,0x2
ffffffffc0202b22:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b24:	40e7f463          	bgeu	a5,a4,ffffffffc0202f2c <pmm_init+0x76a>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b28:	8f91                	sub	a5,a5,a2
ffffffffc0202b2a:	079a                	slli	a5,a5,0x6
ffffffffc0202b2c:	953e                	add	a0,a0,a5
ffffffffc0202b2e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b32:	8b89                	andi	a5,a5,2
ffffffffc0202b34:	30079b63          	bnez	a5,ffffffffc0202e4a <pmm_init+0x688>
        pmm_manager->free_pages(base, n);
ffffffffc0202b38:	000b3783          	ld	a5,0(s6)
ffffffffc0202b3c:	4585                	li	a1,1
ffffffffc0202b3e:	739c                	ld	a5,32(a5)
ffffffffc0202b40:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b42:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202b46:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b48:	078a                	slli	a5,a5,0x2
ffffffffc0202b4a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202b4c:	3ee7f063          	bgeu	a5,a4,ffffffffc0202f2c <pmm_init+0x76a>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b50:	000bb503          	ld	a0,0(s7)
ffffffffc0202b54:	fe000737          	lui	a4,0xfe000
ffffffffc0202b58:	079a                	slli	a5,a5,0x6
ffffffffc0202b5a:	97ba                	add	a5,a5,a4
ffffffffc0202b5c:	953e                	add	a0,a0,a5
ffffffffc0202b5e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b62:	8b89                	andi	a5,a5,2
ffffffffc0202b64:	2c079763          	bnez	a5,ffffffffc0202e32 <pmm_init+0x670>
ffffffffc0202b68:	000b3783          	ld	a5,0(s6)
ffffffffc0202b6c:	4585                	li	a1,1
ffffffffc0202b6e:	739c                	ld	a5,32(a5)
ffffffffc0202b70:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202b72:	00093783          	ld	a5,0(s2)
ffffffffc0202b76:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <boot_dtb+0x3fd49a78>
    asm volatile("sfence.vma");
ffffffffc0202b7a:	12000073          	sfence.vma
ffffffffc0202b7e:	100027f3          	csrr	a5,sstatus
ffffffffc0202b82:	8b89                	andi	a5,a5,2
ffffffffc0202b84:	28079d63          	bnez	a5,ffffffffc0202e1e <pmm_init+0x65c>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b88:	000b3783          	ld	a5,0(s6)
ffffffffc0202b8c:	779c                	ld	a5,40(a5)
ffffffffc0202b8e:	9782                	jalr	a5
ffffffffc0202b90:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b92:	79441063          	bne	s0,s4,ffffffffc0203312 <pmm_init+0xb50>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b96:	00004517          	auipc	a0,0x4
ffffffffc0202b9a:	2ea50513          	addi	a0,a0,746 # ffffffffc0206e80 <etext+0x137c>
ffffffffc0202b9e:	e3efd0ef          	jal	ffffffffc02001dc <cprintf>
ffffffffc0202ba2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ba6:	8b89                	andi	a5,a5,2
ffffffffc0202ba8:	26079163          	bnez	a5,ffffffffc0202e0a <pmm_init+0x648>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202bac:	000b3783          	ld	a5,0(s6)
ffffffffc0202bb0:	779c                	ld	a5,40(a5)
ffffffffc0202bb2:	9782                	jalr	a5
ffffffffc0202bb4:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bb6:	609c                	ld	a5,0(s1)
ffffffffc0202bb8:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bbc:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bbe:	00c79713          	slli	a4,a5,0xc
ffffffffc0202bc2:	6a85                	lui	s5,0x1
ffffffffc0202bc4:	02e47c63          	bgeu	s0,a4,ffffffffc0202bfc <pmm_init+0x43a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202bc8:	00c45713          	srli	a4,s0,0xc
ffffffffc0202bcc:	34f77363          	bgeu	a4,a5,ffffffffc0202f12 <pmm_init+0x750>
ffffffffc0202bd0:	0009b583          	ld	a1,0(s3)
ffffffffc0202bd4:	00093503          	ld	a0,0(s2)
ffffffffc0202bd8:	4601                	li	a2,0
ffffffffc0202bda:	95a2                	add	a1,a1,s0
ffffffffc0202bdc:	bbaff0ef          	jal	ffffffffc0201f96 <get_pte>
ffffffffc0202be0:	30050963          	beqz	a0,ffffffffc0202ef2 <pmm_init+0x730>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202be4:	611c                	ld	a5,0(a0)
ffffffffc0202be6:	078a                	slli	a5,a5,0x2
ffffffffc0202be8:	0147f7b3          	and	a5,a5,s4
ffffffffc0202bec:	2e879363          	bne	a5,s0,ffffffffc0202ed2 <pmm_init+0x710>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202bf0:	609c                	ld	a5,0(s1)
ffffffffc0202bf2:	9456                	add	s0,s0,s5
ffffffffc0202bf4:	00c79713          	slli	a4,a5,0xc
ffffffffc0202bf8:	fce468e3          	bltu	s0,a4,ffffffffc0202bc8 <pmm_init+0x406>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202bfc:	00093783          	ld	a5,0(s2)
ffffffffc0202c00:	639c                	ld	a5,0(a5)
ffffffffc0202c02:	72079863          	bnez	a5,ffffffffc0203332 <pmm_init+0xb70>
ffffffffc0202c06:	100027f3          	csrr	a5,sstatus
ffffffffc0202c0a:	8b89                	andi	a5,a5,2
ffffffffc0202c0c:	24079b63          	bnez	a5,ffffffffc0202e62 <pmm_init+0x6a0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202c10:	000b3783          	ld	a5,0(s6)
ffffffffc0202c14:	4505                	li	a0,1
ffffffffc0202c16:	6f9c                	ld	a5,24(a5)
ffffffffc0202c18:	9782                	jalr	a5
ffffffffc0202c1a:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c1c:	00093503          	ld	a0,0(s2)
ffffffffc0202c20:	4699                	li	a3,6
ffffffffc0202c22:	10000613          	li	a2,256
ffffffffc0202c26:	85a2                	mv	a1,s0
ffffffffc0202c28:	aa5ff0ef          	jal	ffffffffc02026cc <page_insert>
ffffffffc0202c2c:	3c051e63          	bnez	a0,ffffffffc0203008 <pmm_init+0x846>
    
    assert(page_ref(p) == 1);
ffffffffc0202c30:	4018                	lw	a4,0(s0)
ffffffffc0202c32:	4785                	li	a5,1
ffffffffc0202c34:	3af71a63          	bne	a4,a5,ffffffffc0202fe8 <pmm_init+0x826>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202c38:	00093503          	ld	a0,0(s2)
ffffffffc0202c3c:	6605                	lui	a2,0x1
ffffffffc0202c3e:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7e20>
ffffffffc0202c42:	4699                	li	a3,6
ffffffffc0202c44:	85a2                	mv	a1,s0
ffffffffc0202c46:	a87ff0ef          	jal	ffffffffc02026cc <page_insert>
ffffffffc0202c4a:	36051f63          	bnez	a0,ffffffffc0202fc8 <pmm_init+0x806>
    
    assert(page_ref(p) == 2);
ffffffffc0202c4e:	4018                	lw	a4,0(s0)
ffffffffc0202c50:	4789                	li	a5,2
ffffffffc0202c52:	34f71b63          	bne	a4,a5,ffffffffc0202fa8 <pmm_init+0x7e6>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202c56:	00004597          	auipc	a1,0x4
ffffffffc0202c5a:	37258593          	addi	a1,a1,882 # ffffffffc0206fc8 <etext+0x14c4>
ffffffffc0202c5e:	10000513          	li	a0,256
ffffffffc0202c62:	5f9020ef          	jal	ffffffffc0205a5a <strcpy>
    
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202c66:	6585                	lui	a1,0x1
ffffffffc0202c68:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7e20>
ffffffffc0202c6c:	10000513          	li	a0,256
ffffffffc0202c70:	5fd020ef          	jal	ffffffffc0205a6c <strcmp>
ffffffffc0202c74:	30051a63          	bnez	a0,ffffffffc0202f88 <pmm_init+0x7c6>
    return page - pages + nbase;
ffffffffc0202c78:	000bb683          	ld	a3,0(s7)
ffffffffc0202c7c:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202c80:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202c82:	40d406b3          	sub	a3,s0,a3
ffffffffc0202c86:	8699                	srai	a3,a3,0x6
ffffffffc0202c88:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202c8a:	00c69793          	slli	a5,a3,0xc
ffffffffc0202c8e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c90:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c92:	6ce7f063          	bgeu	a5,a4,ffffffffc0203352 <pmm_init+0xb90>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c96:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c9a:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c9e:	97b6                	add	a5,a5,a3
ffffffffc0202ca0:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_matrix_out_size+0x74bd8>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ca4:	583020ef          	jal	ffffffffc0205a26 <strlen>
ffffffffc0202ca8:	2c051063          	bnez	a0,ffffffffc0202f68 <pmm_init+0x7a6>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202cac:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202cb0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cb2:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <boot_dtb+0x3fd49a78>
ffffffffc0202cb6:	078a                	slli	a5,a5,0x2
ffffffffc0202cb8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cba:	26e7f963          	bgeu	a5,a4,ffffffffc0202f2c <pmm_init+0x76a>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202cbe:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202cc2:	68e7f863          	bgeu	a5,a4,ffffffffc0203352 <pmm_init+0xb90>
ffffffffc0202cc6:	0009b783          	ld	a5,0(s3)
ffffffffc0202cca:	00f689b3          	add	s3,a3,a5
ffffffffc0202cce:	100027f3          	csrr	a5,sstatus
ffffffffc0202cd2:	8b89                	andi	a5,a5,2
ffffffffc0202cd4:	1e079463          	bnez	a5,ffffffffc0202ebc <pmm_init+0x6fa>
        pmm_manager->free_pages(base, n);
ffffffffc0202cd8:	000b3783          	ld	a5,0(s6)
ffffffffc0202cdc:	8522                	mv	a0,s0
ffffffffc0202cde:	4585                	li	a1,1
ffffffffc0202ce0:	739c                	ld	a5,32(a5)
ffffffffc0202ce2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ce4:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202ce8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202cea:	078a                	slli	a5,a5,0x2
ffffffffc0202cec:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202cee:	22e7ff63          	bgeu	a5,a4,ffffffffc0202f2c <pmm_init+0x76a>
    return &pages[PPN(pa) - nbase];
ffffffffc0202cf2:	000bb503          	ld	a0,0(s7)
ffffffffc0202cf6:	fe000737          	lui	a4,0xfe000
ffffffffc0202cfa:	079a                	slli	a5,a5,0x6
ffffffffc0202cfc:	97ba                	add	a5,a5,a4
ffffffffc0202cfe:	953e                	add	a0,a0,a5
ffffffffc0202d00:	100027f3          	csrr	a5,sstatus
ffffffffc0202d04:	8b89                	andi	a5,a5,2
ffffffffc0202d06:	18079f63          	bnez	a5,ffffffffc0202ea4 <pmm_init+0x6e2>
ffffffffc0202d0a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d0e:	4585                	li	a1,1
ffffffffc0202d10:	739c                	ld	a5,32(a5)
ffffffffc0202d12:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d14:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202d18:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202d1a:	078a                	slli	a5,a5,0x2
ffffffffc0202d1c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202d1e:	20e7f763          	bgeu	a5,a4,ffffffffc0202f2c <pmm_init+0x76a>
    return &pages[PPN(pa) - nbase];
ffffffffc0202d22:	000bb503          	ld	a0,0(s7)
ffffffffc0202d26:	fe000737          	lui	a4,0xfe000
ffffffffc0202d2a:	079a                	slli	a5,a5,0x6
ffffffffc0202d2c:	97ba                	add	a5,a5,a4
ffffffffc0202d2e:	953e                	add	a0,a0,a5
ffffffffc0202d30:	100027f3          	csrr	a5,sstatus
ffffffffc0202d34:	8b89                	andi	a5,a5,2
ffffffffc0202d36:	14079b63          	bnez	a5,ffffffffc0202e8c <pmm_init+0x6ca>
ffffffffc0202d3a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d3e:	4585                	li	a1,1
ffffffffc0202d40:	739c                	ld	a5,32(a5)
ffffffffc0202d42:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202d44:	00093783          	ld	a5,0(s2)
ffffffffc0202d48:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202d4c:	12000073          	sfence.vma
ffffffffc0202d50:	100027f3          	csrr	a5,sstatus
ffffffffc0202d54:	8b89                	andi	a5,a5,2
ffffffffc0202d56:	12079163          	bnez	a5,ffffffffc0202e78 <pmm_init+0x6b6>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d5a:	000b3783          	ld	a5,0(s6)
ffffffffc0202d5e:	779c                	ld	a5,40(a5)
ffffffffc0202d60:	9782                	jalr	a5
ffffffffc0202d62:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202d64:	1e8c1263          	bne	s8,s0,ffffffffc0202f48 <pmm_init+0x786>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202d68:	00004517          	auipc	a0,0x4
ffffffffc0202d6c:	2d850513          	addi	a0,a0,728 # ffffffffc0207040 <etext+0x153c>
ffffffffc0202d70:	c6cfd0ef          	jal	ffffffffc02001dc <cprintf>
}
ffffffffc0202d74:	7406                	ld	s0,96(sp)
ffffffffc0202d76:	70a6                	ld	ra,104(sp)
ffffffffc0202d78:	64e6                	ld	s1,88(sp)
ffffffffc0202d7a:	6946                	ld	s2,80(sp)
ffffffffc0202d7c:	69a6                	ld	s3,72(sp)
ffffffffc0202d7e:	6a06                	ld	s4,64(sp)
ffffffffc0202d80:	7ae2                	ld	s5,56(sp)
ffffffffc0202d82:	7b42                	ld	s6,48(sp)
ffffffffc0202d84:	7ba2                	ld	s7,40(sp)
ffffffffc0202d86:	7c02                	ld	s8,32(sp)
ffffffffc0202d88:	6ce2                	ld	s9,24(sp)
ffffffffc0202d8a:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d8c:	f7dfe06f          	j	ffffffffc0201d08 <kmalloc_init>
        boot_pg_addr = boot_pg_addr + va_pa_offset;
ffffffffc0202d90:	0009b783          	ld	a5,0(s3)
ffffffffc0202d94:	96be                	add	a3,a3,a5
    boot_pgdir_va = (pte_t *)boot_pg_addr;
ffffffffc0202d96:	8736                	mv	a4,a3
ffffffffc0202d98:	bea1                	j	ffffffffc02028f0 <pmm_init+0x12e>
    if (maxpa > KERNTOP)
ffffffffc0202d9a:	863e                	mv	a2,a5
ffffffffc0202d9c:	bc5d                	j	ffffffffc0202852 <pmm_init+0x90>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d9e:	6585                	lui	a1,0x1
ffffffffc0202da0:	15fd                	addi	a1,a1,-1 # fff <_binary_obj___user_softint_out_size-0x7f21>
ffffffffc0202da2:	97ae                	add	a5,a5,a1
ffffffffc0202da4:	8ff9                	and	a5,a5,a4
    if (PPN(pa) >= npage)
ffffffffc0202da6:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202daa:	18c77163          	bgeu	a4,a2,ffffffffc0202f2c <pmm_init+0x76a>
    pmm_manager->init_memmap(base, n);
ffffffffc0202dae:	000b3603          	ld	a2,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202db2:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202db4:	071a                	slli	a4,a4,0x6
ffffffffc0202db6:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202dba:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202dbc:	6a1c                	ld	a5,16(a2)
ffffffffc0202dbe:	00c45593          	srli	a1,s0,0xc
ffffffffc0202dc2:	00e68533          	add	a0,a3,a4
ffffffffc0202dc6:	9782                	jalr	a5
}
ffffffffc0202dc8:	b4e5                	j	ffffffffc02028b0 <pmm_init+0xee>
        intr_disable();
ffffffffc0202dca:	c33fd0ef          	jal	ffffffffc02009fc <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202dce:	000b3783          	ld	a5,0(s6)
ffffffffc0202dd2:	4505                	li	a0,1
ffffffffc0202dd4:	6f9c                	ld	a5,24(a5)
ffffffffc0202dd6:	9782                	jalr	a5
ffffffffc0202dd8:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202dda:	c1dfd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202dde:	b659                	j	ffffffffc0202964 <pmm_init+0x1a2>
        intr_disable();
ffffffffc0202de0:	c1dfd0ef          	jal	ffffffffc02009fc <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202de4:	000b3783          	ld	a5,0(s6)
ffffffffc0202de8:	779c                	ld	a5,40(a5)
ffffffffc0202dea:	9782                	jalr	a5
ffffffffc0202dec:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202dee:	c09fd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202df2:	be15                	j	ffffffffc0202926 <pmm_init+0x164>
        intr_disable();
ffffffffc0202df4:	c09fd0ef          	jal	ffffffffc02009fc <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202df8:	000b3783          	ld	a5,0(s6)
ffffffffc0202dfc:	4505                	li	a0,1
ffffffffc0202dfe:	6f9c                	ld	a5,24(a5)
ffffffffc0202e00:	9782                	jalr	a5
ffffffffc0202e02:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e04:	bf3fd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202e08:	b101                	j	ffffffffc0202a08 <pmm_init+0x246>
        intr_disable();
ffffffffc0202e0a:	bf3fd0ef          	jal	ffffffffc02009fc <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e0e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e12:	779c                	ld	a5,40(a5)
ffffffffc0202e14:	9782                	jalr	a5
ffffffffc0202e16:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202e18:	bdffd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202e1c:	bb69                	j	ffffffffc0202bb6 <pmm_init+0x3f4>
        intr_disable();
ffffffffc0202e1e:	bdffd0ef          	jal	ffffffffc02009fc <intr_disable>
ffffffffc0202e22:	000b3783          	ld	a5,0(s6)
ffffffffc0202e26:	779c                	ld	a5,40(a5)
ffffffffc0202e28:	9782                	jalr	a5
ffffffffc0202e2a:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202e2c:	bcbfd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202e30:	b38d                	j	ffffffffc0202b92 <pmm_init+0x3d0>
ffffffffc0202e32:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e34:	bc9fd0ef          	jal	ffffffffc02009fc <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e38:	000b3783          	ld	a5,0(s6)
ffffffffc0202e3c:	6522                	ld	a0,8(sp)
ffffffffc0202e3e:	4585                	li	a1,1
ffffffffc0202e40:	739c                	ld	a5,32(a5)
ffffffffc0202e42:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e44:	bb3fd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202e48:	b32d                	j	ffffffffc0202b72 <pmm_init+0x3b0>
ffffffffc0202e4a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e4c:	bb1fd0ef          	jal	ffffffffc02009fc <intr_disable>
ffffffffc0202e50:	000b3783          	ld	a5,0(s6)
ffffffffc0202e54:	6522                	ld	a0,8(sp)
ffffffffc0202e56:	4585                	li	a1,1
ffffffffc0202e58:	739c                	ld	a5,32(a5)
ffffffffc0202e5a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e5c:	b9bfd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202e60:	b1cd                	j	ffffffffc0202b42 <pmm_init+0x380>
        intr_disable();
ffffffffc0202e62:	b9bfd0ef          	jal	ffffffffc02009fc <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202e66:	000b3783          	ld	a5,0(s6)
ffffffffc0202e6a:	4505                	li	a0,1
ffffffffc0202e6c:	6f9c                	ld	a5,24(a5)
ffffffffc0202e6e:	9782                	jalr	a5
ffffffffc0202e70:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e72:	b85fd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202e76:	b35d                	j	ffffffffc0202c1c <pmm_init+0x45a>
        intr_disable();
ffffffffc0202e78:	b85fd0ef          	jal	ffffffffc02009fc <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202e7c:	000b3783          	ld	a5,0(s6)
ffffffffc0202e80:	779c                	ld	a5,40(a5)
ffffffffc0202e82:	9782                	jalr	a5
ffffffffc0202e84:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e86:	b71fd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202e8a:	bde9                	j	ffffffffc0202d64 <pmm_init+0x5a2>
ffffffffc0202e8c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e8e:	b6ffd0ef          	jal	ffffffffc02009fc <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e92:	000b3783          	ld	a5,0(s6)
ffffffffc0202e96:	6522                	ld	a0,8(sp)
ffffffffc0202e98:	4585                	li	a1,1
ffffffffc0202e9a:	739c                	ld	a5,32(a5)
ffffffffc0202e9c:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e9e:	b59fd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202ea2:	b54d                	j	ffffffffc0202d44 <pmm_init+0x582>
ffffffffc0202ea4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202ea6:	b57fd0ef          	jal	ffffffffc02009fc <intr_disable>
ffffffffc0202eaa:	000b3783          	ld	a5,0(s6)
ffffffffc0202eae:	6522                	ld	a0,8(sp)
ffffffffc0202eb0:	4585                	li	a1,1
ffffffffc0202eb2:	739c                	ld	a5,32(a5)
ffffffffc0202eb4:	9782                	jalr	a5
        intr_enable();
ffffffffc0202eb6:	b41fd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202eba:	bda9                	j	ffffffffc0202d14 <pmm_init+0x552>
        intr_disable();
ffffffffc0202ebc:	b41fd0ef          	jal	ffffffffc02009fc <intr_disable>
ffffffffc0202ec0:	000b3783          	ld	a5,0(s6)
ffffffffc0202ec4:	8522                	mv	a0,s0
ffffffffc0202ec6:	4585                	li	a1,1
ffffffffc0202ec8:	739c                	ld	a5,32(a5)
ffffffffc0202eca:	9782                	jalr	a5
        intr_enable();
ffffffffc0202ecc:	b2bfd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0202ed0:	bd11                	j	ffffffffc0202ce4 <pmm_init+0x522>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202ed2:	00004697          	auipc	a3,0x4
ffffffffc0202ed6:	00e68693          	addi	a3,a3,14 # ffffffffc0206ee0 <etext+0x13dc>
ffffffffc0202eda:	00003617          	auipc	a2,0x3
ffffffffc0202ede:	6ce60613          	addi	a2,a2,1742 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0202ee2:	25800593          	li	a1,600
ffffffffc0202ee6:	00004517          	auipc	a0,0x4
ffffffffc0202eea:	b6250513          	addi	a0,a0,-1182 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0202eee:	da0fd0ef          	jal	ffffffffc020048e <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202ef2:	00004697          	auipc	a3,0x4
ffffffffc0202ef6:	fae68693          	addi	a3,a3,-82 # ffffffffc0206ea0 <etext+0x139c>
ffffffffc0202efa:	00003617          	auipc	a2,0x3
ffffffffc0202efe:	6ae60613          	addi	a2,a2,1710 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0202f02:	25700593          	li	a1,599
ffffffffc0202f06:	00004517          	auipc	a0,0x4
ffffffffc0202f0a:	b4250513          	addi	a0,a0,-1214 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0202f0e:	d80fd0ef          	jal	ffffffffc020048e <__panic>
ffffffffc0202f12:	86a2                	mv	a3,s0
ffffffffc0202f14:	00004617          	auipc	a2,0x4
ffffffffc0202f18:	a4460613          	addi	a2,a2,-1468 # ffffffffc0206958 <etext+0xe54>
ffffffffc0202f1c:	25700593          	li	a1,599
ffffffffc0202f20:	00004517          	auipc	a0,0x4
ffffffffc0202f24:	b2850513          	addi	a0,a0,-1240 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0202f28:	d66fd0ef          	jal	ffffffffc020048e <__panic>
ffffffffc0202f2c:	fa7fe0ef          	jal	ffffffffc0201ed2 <pa2page.part.0>
        panic("DTB memory info not available");
ffffffffc0202f30:	00004617          	auipc	a2,0x4
ffffffffc0202f34:	b8860613          	addi	a2,a2,-1144 # ffffffffc0206ab8 <etext+0xfb4>
ffffffffc0202f38:	06500593          	li	a1,101
ffffffffc0202f3c:	00004517          	auipc	a0,0x4
ffffffffc0202f40:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0202f44:	d4afd0ef          	jal	ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202f48:	00004697          	auipc	a3,0x4
ffffffffc0202f4c:	f1068693          	addi	a3,a3,-240 # ffffffffc0206e58 <etext+0x1354>
ffffffffc0202f50:	00003617          	auipc	a2,0x3
ffffffffc0202f54:	65860613          	addi	a2,a2,1624 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0202f58:	27600593          	li	a1,630
ffffffffc0202f5c:	00004517          	auipc	a0,0x4
ffffffffc0202f60:	aec50513          	addi	a0,a0,-1300 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0202f64:	d2afd0ef          	jal	ffffffffc020048e <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202f68:	00004697          	auipc	a3,0x4
ffffffffc0202f6c:	0b068693          	addi	a3,a3,176 # ffffffffc0207018 <etext+0x1514>
ffffffffc0202f70:	00003617          	auipc	a2,0x3
ffffffffc0202f74:	63860613          	addi	a2,a2,1592 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0202f78:	26d00593          	li	a1,621
ffffffffc0202f7c:	00004517          	auipc	a0,0x4
ffffffffc0202f80:	acc50513          	addi	a0,a0,-1332 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0202f84:	d0afd0ef          	jal	ffffffffc020048e <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202f88:	00004697          	auipc	a3,0x4
ffffffffc0202f8c:	05868693          	addi	a3,a3,88 # ffffffffc0206fe0 <etext+0x14dc>
ffffffffc0202f90:	00003617          	auipc	a2,0x3
ffffffffc0202f94:	61860613          	addi	a2,a2,1560 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0202f98:	26a00593          	li	a1,618
ffffffffc0202f9c:	00004517          	auipc	a0,0x4
ffffffffc0202fa0:	aac50513          	addi	a0,a0,-1364 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0202fa4:	ceafd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202fa8:	00004697          	auipc	a3,0x4
ffffffffc0202fac:	00868693          	addi	a3,a3,8 # ffffffffc0206fb0 <etext+0x14ac>
ffffffffc0202fb0:	00003617          	auipc	a2,0x3
ffffffffc0202fb4:	5f860613          	addi	a2,a2,1528 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0202fb8:	26500593          	li	a1,613
ffffffffc0202fbc:	00004517          	auipc	a0,0x4
ffffffffc0202fc0:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0202fc4:	ccafd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202fc8:	00004697          	auipc	a3,0x4
ffffffffc0202fcc:	fa068693          	addi	a3,a3,-96 # ffffffffc0206f68 <etext+0x1464>
ffffffffc0202fd0:	00003617          	auipc	a2,0x3
ffffffffc0202fd4:	5d860613          	addi	a2,a2,1496 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0202fd8:	26300593          	li	a1,611
ffffffffc0202fdc:	00004517          	auipc	a0,0x4
ffffffffc0202fe0:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0202fe4:	caafd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202fe8:	00004697          	auipc	a3,0x4
ffffffffc0202fec:	f6868693          	addi	a3,a3,-152 # ffffffffc0206f50 <etext+0x144c>
ffffffffc0202ff0:	00003617          	auipc	a2,0x3
ffffffffc0202ff4:	5b860613          	addi	a2,a2,1464 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0202ff8:	26200593          	li	a1,610
ffffffffc0202ffc:	00004517          	auipc	a0,0x4
ffffffffc0203000:	a4c50513          	addi	a0,a0,-1460 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0203004:	c8afd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203008:	00004697          	auipc	a3,0x4
ffffffffc020300c:	f0868693          	addi	a3,a3,-248 # ffffffffc0206f10 <etext+0x140c>
ffffffffc0203010:	00003617          	auipc	a2,0x3
ffffffffc0203014:	59860613          	addi	a2,a2,1432 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203018:	26000593          	li	a1,608
ffffffffc020301c:	00004517          	auipc	a0,0x4
ffffffffc0203020:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0203024:	c6afd0ef          	jal	ffffffffc020048e <__panic>
    boot_pgdir_pa = PADDR((uintptr_t)boot_pgdir_va);
ffffffffc0203028:	00004617          	auipc	a2,0x4
ffffffffc020302c:	9d860613          	addi	a2,a2,-1576 # ffffffffc0206a00 <etext+0xefc>
ffffffffc0203030:	0d100593          	li	a1,209
ffffffffc0203034:	00004517          	auipc	a0,0x4
ffffffffc0203038:	a1450513          	addi	a0,a0,-1516 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020303c:	c52fd0ef          	jal	ffffffffc020048e <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203040:	00004697          	auipc	a3,0x4
ffffffffc0203044:	d1068693          	addi	a3,a3,-752 # ffffffffc0206d50 <etext+0x124c>
ffffffffc0203048:	00003617          	auipc	a2,0x3
ffffffffc020304c:	56060613          	addi	a2,a2,1376 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203050:	22d00593          	li	a1,557
ffffffffc0203054:	00004517          	auipc	a0,0x4
ffffffffc0203058:	9f450513          	addi	a0,a0,-1548 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020305c:	c32fd0ef          	jal	ffffffffc020048e <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0203060:	00004697          	auipc	a3,0x4
ffffffffc0203064:	b1068693          	addi	a3,a3,-1264 # ffffffffc0206b70 <etext+0x106c>
ffffffffc0203068:	00003617          	auipc	a2,0x3
ffffffffc020306c:	54060613          	addi	a2,a2,1344 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203070:	21900593          	li	a1,537
ffffffffc0203074:	00004517          	auipc	a0,0x4
ffffffffc0203078:	9d450513          	addi	a0,a0,-1580 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020307c:	c12fd0ef          	jal	ffffffffc020048e <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203080:	00004697          	auipc	a3,0x4
ffffffffc0203084:	ad068693          	addi	a3,a3,-1328 # ffffffffc0206b50 <etext+0x104c>
ffffffffc0203088:	00003617          	auipc	a2,0x3
ffffffffc020308c:	52060613          	addi	a2,a2,1312 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203090:	21800593          	li	a1,536
ffffffffc0203094:	00004517          	auipc	a0,0x4
ffffffffc0203098:	9b450513          	addi	a0,a0,-1612 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020309c:	bf2fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02030a0:	00004697          	auipc	a3,0x4
ffffffffc02030a4:	d2868693          	addi	a3,a3,-728 # ffffffffc0206dc8 <etext+0x12c4>
ffffffffc02030a8:	00003617          	auipc	a2,0x3
ffffffffc02030ac:	50060613          	addi	a2,a2,1280 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02030b0:	23200593          	li	a1,562
ffffffffc02030b4:	00004517          	auipc	a0,0x4
ffffffffc02030b8:	99450513          	addi	a0,a0,-1644 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02030bc:	bd2fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02030c0:	00004697          	auipc	a3,0x4
ffffffffc02030c4:	cd868693          	addi	a3,a3,-808 # ffffffffc0206d98 <etext+0x1294>
ffffffffc02030c8:	00003617          	auipc	a2,0x3
ffffffffc02030cc:	4e060613          	addi	a2,a2,1248 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02030d0:	23100593          	li	a1,561
ffffffffc02030d4:	00004517          	auipc	a0,0x4
ffffffffc02030d8:	97450513          	addi	a0,a0,-1676 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02030dc:	bb2fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02030e0:	00004697          	auipc	a3,0x4
ffffffffc02030e4:	ca068693          	addi	a3,a3,-864 # ffffffffc0206d80 <etext+0x127c>
ffffffffc02030e8:	00003617          	auipc	a2,0x3
ffffffffc02030ec:	4c060613          	addi	a2,a2,1216 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02030f0:	22f00593          	li	a1,559
ffffffffc02030f4:	00004517          	auipc	a0,0x4
ffffffffc02030f8:	95450513          	addi	a0,a0,-1708 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02030fc:	b92fd0ef          	jal	ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203100:	00004697          	auipc	a3,0x4
ffffffffc0203104:	c6068693          	addi	a3,a3,-928 # ffffffffc0206d60 <etext+0x125c>
ffffffffc0203108:	00003617          	auipc	a2,0x3
ffffffffc020310c:	4a060613          	addi	a2,a2,1184 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203110:	22e00593          	li	a1,558
ffffffffc0203114:	00004517          	auipc	a0,0x4
ffffffffc0203118:	93450513          	addi	a0,a0,-1740 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020311c:	b72fd0ef          	jal	ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203120:	00004697          	auipc	a3,0x4
ffffffffc0203124:	af068693          	addi	a3,a3,-1296 # ffffffffc0206c10 <etext+0x110c>
ffffffffc0203128:	00003617          	auipc	a2,0x3
ffffffffc020312c:	48060613          	addi	a2,a2,1152 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203130:	22100593          	li	a1,545
ffffffffc0203134:	00004517          	auipc	a0,0x4
ffffffffc0203138:	91450513          	addi	a0,a0,-1772 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020313c:	b52fd0ef          	jal	ffffffffc020048e <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203140:	00004697          	auipc	a3,0x4
ffffffffc0203144:	c0068693          	addi	a3,a3,-1024 # ffffffffc0206d40 <etext+0x123c>
ffffffffc0203148:	00003617          	auipc	a2,0x3
ffffffffc020314c:	46060613          	addi	a2,a2,1120 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203150:	22c00593          	li	a1,556
ffffffffc0203154:	00004517          	auipc	a0,0x4
ffffffffc0203158:	8f450513          	addi	a0,a0,-1804 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020315c:	b32fd0ef          	jal	ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc0203160:	00004697          	auipc	a3,0x4
ffffffffc0203164:	ba868693          	addi	a3,a3,-1112 # ffffffffc0206d08 <etext+0x1204>
ffffffffc0203168:	00003617          	auipc	a2,0x3
ffffffffc020316c:	44060613          	addi	a2,a2,1088 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203170:	22b00593          	li	a1,555
ffffffffc0203174:	00004517          	auipc	a0,0x4
ffffffffc0203178:	8d450513          	addi	a0,a0,-1836 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020317c:	b12fd0ef          	jal	ffffffffc020048e <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0203180:	00004697          	auipc	a3,0x4
ffffffffc0203184:	b1868693          	addi	a3,a3,-1256 # ffffffffc0206c98 <etext+0x1194>
ffffffffc0203188:	00003617          	auipc	a2,0x3
ffffffffc020318c:	42060613          	addi	a2,a2,1056 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203190:	22700593          	li	a1,551
ffffffffc0203194:	00004517          	auipc	a0,0x4
ffffffffc0203198:	8b450513          	addi	a0,a0,-1868 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020319c:	af2fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02031a0:	00004697          	auipc	a3,0x4
ffffffffc02031a4:	b2868693          	addi	a3,a3,-1240 # ffffffffc0206cc8 <etext+0x11c4>
ffffffffc02031a8:	00003617          	auipc	a2,0x3
ffffffffc02031ac:	40060613          	addi	a2,a2,1024 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02031b0:	22a00593          	li	a1,554
ffffffffc02031b4:	00004517          	auipc	a0,0x4
ffffffffc02031b8:	89450513          	addi	a0,a0,-1900 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02031bc:	ad2fd0ef          	jal	ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02031c0:	00004697          	auipc	a3,0x4
ffffffffc02031c4:	aa868693          	addi	a3,a3,-1368 # ffffffffc0206c68 <etext+0x1164>
ffffffffc02031c8:	00003617          	auipc	a2,0x3
ffffffffc02031cc:	3e060613          	addi	a2,a2,992 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02031d0:	23500593          	li	a1,565
ffffffffc02031d4:	00004517          	auipc	a0,0x4
ffffffffc02031d8:	87450513          	addi	a0,a0,-1932 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02031dc:	ab2fd0ef          	jal	ffffffffc020048e <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02031e0:	00004697          	auipc	a3,0x4
ffffffffc02031e4:	b2868693          	addi	a3,a3,-1240 # ffffffffc0206d08 <etext+0x1204>
ffffffffc02031e8:	00003617          	auipc	a2,0x3
ffffffffc02031ec:	3c060613          	addi	a2,a2,960 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02031f0:	23400593          	li	a1,564
ffffffffc02031f4:	00004517          	auipc	a0,0x4
ffffffffc02031f8:	85450513          	addi	a0,a0,-1964 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02031fc:	a92fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203200:	00004697          	auipc	a3,0x4
ffffffffc0203204:	be068693          	addi	a3,a3,-1056 # ffffffffc0206de0 <etext+0x12dc>
ffffffffc0203208:	00003617          	auipc	a2,0x3
ffffffffc020320c:	3a060613          	addi	a2,a2,928 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203210:	23300593          	li	a1,563
ffffffffc0203214:	00004517          	auipc	a0,0x4
ffffffffc0203218:	83450513          	addi	a0,a0,-1996 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020321c:	a72fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203220:	00004697          	auipc	a3,0x4
ffffffffc0203224:	bc068693          	addi	a3,a3,-1088 # ffffffffc0206de0 <etext+0x12dc>
ffffffffc0203228:	00003617          	auipc	a2,0x3
ffffffffc020322c:	38060613          	addi	a2,a2,896 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203230:	23e00593          	li	a1,574
ffffffffc0203234:	00004517          	auipc	a0,0x4
ffffffffc0203238:	81450513          	addi	a0,a0,-2028 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020323c:	a52fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0203240:	00004697          	auipc	a3,0x4
ffffffffc0203244:	bd068693          	addi	a3,a3,-1072 # ffffffffc0206e10 <etext+0x130c>
ffffffffc0203248:	00003617          	auipc	a2,0x3
ffffffffc020324c:	36060613          	addi	a2,a2,864 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203250:	23d00593          	li	a1,573
ffffffffc0203254:	00003517          	auipc	a0,0x3
ffffffffc0203258:	7f450513          	addi	a0,a0,2036 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020325c:	a32fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203260:	00004697          	auipc	a3,0x4
ffffffffc0203264:	b8068693          	addi	a3,a3,-1152 # ffffffffc0206de0 <etext+0x12dc>
ffffffffc0203268:	00003617          	auipc	a2,0x3
ffffffffc020326c:	34060613          	addi	a2,a2,832 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203270:	23a00593          	li	a1,570
ffffffffc0203274:	00003517          	auipc	a0,0x3
ffffffffc0203278:	7d450513          	addi	a0,a0,2004 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020327c:	a12fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203280:	00004697          	auipc	a3,0x4
ffffffffc0203284:	a0068693          	addi	a3,a3,-1536 # ffffffffc0206c80 <etext+0x117c>
ffffffffc0203288:	00003617          	auipc	a2,0x3
ffffffffc020328c:	32060613          	addi	a2,a2,800 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203290:	23900593          	li	a1,569
ffffffffc0203294:	00003517          	auipc	a0,0x3
ffffffffc0203298:	7b450513          	addi	a0,a0,1972 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020329c:	9f2fd0ef          	jal	ffffffffc020048e <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02032a0:	00004697          	auipc	a3,0x4
ffffffffc02032a4:	b5868693          	addi	a3,a3,-1192 # ffffffffc0206df8 <etext+0x12f4>
ffffffffc02032a8:	00003617          	auipc	a2,0x3
ffffffffc02032ac:	30060613          	addi	a2,a2,768 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02032b0:	23600593          	li	a1,566
ffffffffc02032b4:	00003517          	auipc	a0,0x3
ffffffffc02032b8:	79450513          	addi	a0,a0,1940 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02032bc:	9d2fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02032c0:	00004697          	auipc	a3,0x4
ffffffffc02032c4:	92068693          	addi	a3,a3,-1760 # ffffffffc0206be0 <etext+0x10dc>
ffffffffc02032c8:	00003617          	auipc	a2,0x3
ffffffffc02032cc:	2e060613          	addi	a2,a2,736 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02032d0:	21e00593          	li	a1,542
ffffffffc02032d4:	00003517          	auipc	a0,0x3
ffffffffc02032d8:	77450513          	addi	a0,a0,1908 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02032dc:	9b2fd0ef          	jal	ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02032e0:	86d6                	mv	a3,s5
ffffffffc02032e2:	00003617          	auipc	a2,0x3
ffffffffc02032e6:	67660613          	addi	a2,a2,1654 # ffffffffc0206958 <etext+0xe54>
ffffffffc02032ea:	22600593          	li	a1,550
ffffffffc02032ee:	00003517          	auipc	a0,0x3
ffffffffc02032f2:	75a50513          	addi	a0,a0,1882 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02032f6:	998fd0ef          	jal	ffffffffc020048e <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc02032fa:	00003617          	auipc	a2,0x3
ffffffffc02032fe:	65e60613          	addi	a2,a2,1630 # ffffffffc0206958 <etext+0xe54>
ffffffffc0203302:	22500593          	li	a1,549
ffffffffc0203306:	00003517          	auipc	a0,0x3
ffffffffc020330a:	74250513          	addi	a0,a0,1858 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020330e:	980fd0ef          	jal	ffffffffc020048e <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0203312:	00004697          	auipc	a3,0x4
ffffffffc0203316:	b4668693          	addi	a3,a3,-1210 # ffffffffc0206e58 <etext+0x1354>
ffffffffc020331a:	00003617          	auipc	a2,0x3
ffffffffc020331e:	28e60613          	addi	a2,a2,654 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203322:	24800593          	li	a1,584
ffffffffc0203326:	00003517          	auipc	a0,0x3
ffffffffc020332a:	72250513          	addi	a0,a0,1826 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020332e:	960fd0ef          	jal	ffffffffc020048e <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0203332:	00004697          	auipc	a3,0x4
ffffffffc0203336:	bc668693          	addi	a3,a3,-1082 # ffffffffc0206ef8 <etext+0x13f4>
ffffffffc020333a:	00003617          	auipc	a2,0x3
ffffffffc020333e:	26e60613          	addi	a2,a2,622 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203342:	25b00593          	li	a1,603
ffffffffc0203346:	00003517          	auipc	a0,0x3
ffffffffc020334a:	70250513          	addi	a0,a0,1794 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020334e:	940fd0ef          	jal	ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc0203352:	00003617          	auipc	a2,0x3
ffffffffc0203356:	60660613          	addi	a2,a2,1542 # ffffffffc0206958 <etext+0xe54>
ffffffffc020335a:	07100593          	li	a1,113
ffffffffc020335e:	00003517          	auipc	a0,0x3
ffffffffc0203362:	62250513          	addi	a0,a0,1570 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0203366:	928fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc020336a:	00004697          	auipc	a3,0x4
ffffffffc020336e:	abe68693          	addi	a3,a3,-1346 # ffffffffc0206e28 <etext+0x1324>
ffffffffc0203372:	00003617          	auipc	a2,0x3
ffffffffc0203376:	23660613          	addi	a2,a2,566 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020337a:	24000593          	li	a1,576
ffffffffc020337e:	00003517          	auipc	a0,0x3
ffffffffc0203382:	6ca50513          	addi	a0,a0,1738 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0203386:	908fd0ef          	jal	ffffffffc020048e <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc020338a:	00004697          	auipc	a3,0x4
ffffffffc020338e:	82668693          	addi	a3,a3,-2010 # ffffffffc0206bb0 <etext+0x10ac>
ffffffffc0203392:	00003617          	auipc	a2,0x3
ffffffffc0203396:	21660613          	addi	a2,a2,534 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020339a:	21a00593          	li	a1,538
ffffffffc020339e:	00003517          	auipc	a0,0x3
ffffffffc02033a2:	6aa50513          	addi	a0,a0,1706 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02033a6:	8e8fd0ef          	jal	ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02033aa:	00004617          	auipc	a2,0x4
ffffffffc02033ae:	89660613          	addi	a2,a2,-1898 # ffffffffc0206c40 <etext+0x113c>
ffffffffc02033b2:	07f00593          	li	a1,127
ffffffffc02033b6:	00003517          	auipc	a0,0x3
ffffffffc02033ba:	5ca50513          	addi	a0,a0,1482 # ffffffffc0206980 <etext+0xe7c>
ffffffffc02033be:	8d0fd0ef          	jal	ffffffffc020048e <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02033c2:	00004697          	auipc	a3,0x4
ffffffffc02033c6:	8be68693          	addi	a3,a3,-1858 # ffffffffc0206c80 <etext+0x117c>
ffffffffc02033ca:	00003617          	auipc	a2,0x3
ffffffffc02033ce:	1de60613          	addi	a2,a2,478 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02033d2:	22300593          	li	a1,547
ffffffffc02033d6:	00003517          	auipc	a0,0x3
ffffffffc02033da:	67250513          	addi	a0,a0,1650 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02033de:	8b0fd0ef          	jal	ffffffffc020048e <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02033e2:	00004697          	auipc	a3,0x4
ffffffffc02033e6:	88668693          	addi	a3,a3,-1914 # ffffffffc0206c68 <etext+0x1164>
ffffffffc02033ea:	00003617          	auipc	a2,0x3
ffffffffc02033ee:	1be60613          	addi	a2,a2,446 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02033f2:	22200593          	li	a1,546
ffffffffc02033f6:	00003517          	auipc	a0,0x3
ffffffffc02033fa:	65250513          	addi	a0,a0,1618 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02033fe:	890fd0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0203402 <copy_range>:
{
ffffffffc0203402:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203404:	00d667b3          	or	a5,a2,a3
{
ffffffffc0203408:	f486                	sd	ra,104(sp)
ffffffffc020340a:	f0a2                	sd	s0,96(sp)
ffffffffc020340c:	eca6                	sd	s1,88(sp)
ffffffffc020340e:	e8ca                	sd	s2,80(sp)
ffffffffc0203410:	e4ce                	sd	s3,72(sp)
ffffffffc0203412:	e0d2                	sd	s4,64(sp)
ffffffffc0203414:	fc56                	sd	s5,56(sp)
ffffffffc0203416:	f85a                	sd	s6,48(sp)
ffffffffc0203418:	f45e                	sd	s7,40(sp)
ffffffffc020341a:	f062                	sd	s8,32(sp)
ffffffffc020341c:	ec66                	sd	s9,24(sp)
ffffffffc020341e:	e86a                	sd	s10,16(sp)
ffffffffc0203420:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203422:	03479713          	slli	a4,a5,0x34
ffffffffc0203426:	20071f63          	bnez	a4,ffffffffc0203644 <copy_range+0x242>
    assert(USER_ACCESS(start, end));
ffffffffc020342a:	002007b7          	lui	a5,0x200
ffffffffc020342e:	00d63733          	sltu	a4,a2,a3
ffffffffc0203432:	00f637b3          	sltu	a5,a2,a5
ffffffffc0203436:	00173713          	seqz	a4,a4
ffffffffc020343a:	8fd9                	or	a5,a5,a4
ffffffffc020343c:	8432                	mv	s0,a2
ffffffffc020343e:	8936                	mv	s2,a3
ffffffffc0203440:	1e079263          	bnez	a5,ffffffffc0203624 <copy_range+0x222>
ffffffffc0203444:	4785                	li	a5,1
ffffffffc0203446:	07fe                	slli	a5,a5,0x1f
ffffffffc0203448:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_matrix_out_size+0x1f4ad9>
ffffffffc020344a:	1cf6fd63          	bgeu	a3,a5,ffffffffc0203624 <copy_range+0x222>
    return KADDR(page2pa(page));
ffffffffc020344e:	5b7d                	li	s6,-1
ffffffffc0203450:	8baa                	mv	s7,a0
ffffffffc0203452:	8a2e                	mv	s4,a1
ffffffffc0203454:	6a85                	lui	s5,0x1
ffffffffc0203456:	00cb5b13          	srli	s6,s6,0xc
    if (PPN(pa) >= npage)
ffffffffc020345a:	000aec97          	auipc	s9,0xae
ffffffffc020345e:	0a6c8c93          	addi	s9,s9,166 # ffffffffc02b1500 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203462:	000aec17          	auipc	s8,0xae
ffffffffc0203466:	0a6c0c13          	addi	s8,s8,166 # ffffffffc02b1508 <pages>
ffffffffc020346a:	fff80d37          	lui	s10,0xfff80
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc020346e:	4601                	li	a2,0
ffffffffc0203470:	85a2                	mv	a1,s0
ffffffffc0203472:	8552                	mv	a0,s4
ffffffffc0203474:	b23fe0ef          	jal	ffffffffc0201f96 <get_pte>
ffffffffc0203478:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc020347a:	0e050a63          	beqz	a0,ffffffffc020356e <copy_range+0x16c>
        if (*ptep & PTE_V)
ffffffffc020347e:	611c                	ld	a5,0(a0)
ffffffffc0203480:	8b85                	andi	a5,a5,1
ffffffffc0203482:	e78d                	bnez	a5,ffffffffc02034ac <copy_range+0xaa>
        start += PGSIZE;
ffffffffc0203484:	9456                	add	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0203486:	c019                	beqz	s0,ffffffffc020348c <copy_range+0x8a>
ffffffffc0203488:	ff2463e3          	bltu	s0,s2,ffffffffc020346e <copy_range+0x6c>
    return 0;
ffffffffc020348c:	4501                	li	a0,0
}
ffffffffc020348e:	70a6                	ld	ra,104(sp)
ffffffffc0203490:	7406                	ld	s0,96(sp)
ffffffffc0203492:	64e6                	ld	s1,88(sp)
ffffffffc0203494:	6946                	ld	s2,80(sp)
ffffffffc0203496:	69a6                	ld	s3,72(sp)
ffffffffc0203498:	6a06                	ld	s4,64(sp)
ffffffffc020349a:	7ae2                	ld	s5,56(sp)
ffffffffc020349c:	7b42                	ld	s6,48(sp)
ffffffffc020349e:	7ba2                	ld	s7,40(sp)
ffffffffc02034a0:	7c02                	ld	s8,32(sp)
ffffffffc02034a2:	6ce2                	ld	s9,24(sp)
ffffffffc02034a4:	6d42                	ld	s10,16(sp)
ffffffffc02034a6:	6da2                	ld	s11,8(sp)
ffffffffc02034a8:	6165                	addi	sp,sp,112
ffffffffc02034aa:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc02034ac:	4605                	li	a2,1
ffffffffc02034ae:	85a2                	mv	a1,s0
ffffffffc02034b0:	855e                	mv	a0,s7
ffffffffc02034b2:	ae5fe0ef          	jal	ffffffffc0201f96 <get_pte>
ffffffffc02034b6:	c165                	beqz	a0,ffffffffc0203596 <copy_range+0x194>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc02034b8:	0004b983          	ld	s3,0(s1)
    if (!(pte & PTE_V))
ffffffffc02034bc:	0019f793          	andi	a5,s3,1
ffffffffc02034c0:	14078663          	beqz	a5,ffffffffc020360c <copy_range+0x20a>
    if (PPN(pa) >= npage)
ffffffffc02034c4:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02034c8:	00299793          	slli	a5,s3,0x2
ffffffffc02034cc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02034ce:	12e7f363          	bgeu	a5,a4,ffffffffc02035f4 <copy_range+0x1f2>
    return &pages[PPN(pa) - nbase];
ffffffffc02034d2:	000c3483          	ld	s1,0(s8)
ffffffffc02034d6:	97ea                	add	a5,a5,s10
ffffffffc02034d8:	079a                	slli	a5,a5,0x6
ffffffffc02034da:	94be                	add	s1,s1,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02034dc:	100027f3          	csrr	a5,sstatus
ffffffffc02034e0:	8b89                	andi	a5,a5,2
ffffffffc02034e2:	efc9                	bnez	a5,ffffffffc020357c <copy_range+0x17a>
        page = pmm_manager->alloc_pages(n);
ffffffffc02034e4:	000ae797          	auipc	a5,0xae
ffffffffc02034e8:	ffc7b783          	ld	a5,-4(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc02034ec:	4505                	li	a0,1
ffffffffc02034ee:	6f9c                	ld	a5,24(a5)
ffffffffc02034f0:	9782                	jalr	a5
ffffffffc02034f2:	8daa                	mv	s11,a0
            assert(page != NULL);
ffffffffc02034f4:	c0e5                	beqz	s1,ffffffffc02035d4 <copy_range+0x1d2>
            assert(npage != NULL);
ffffffffc02034f6:	0a0d8f63          	beqz	s11,ffffffffc02035b4 <copy_range+0x1b2>
    return page - pages + nbase;
ffffffffc02034fa:	000c3783          	ld	a5,0(s8)
ffffffffc02034fe:	00080637          	lui	a2,0x80
    return KADDR(page2pa(page));
ffffffffc0203502:	000cb703          	ld	a4,0(s9)
    return page - pages + nbase;
ffffffffc0203506:	40f486b3          	sub	a3,s1,a5
ffffffffc020350a:	8699                	srai	a3,a3,0x6
ffffffffc020350c:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020350e:	0166f5b3          	and	a1,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203512:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203514:	08e5f463          	bgeu	a1,a4,ffffffffc020359c <copy_range+0x19a>
    return page - pages + nbase;
ffffffffc0203518:	40fd87b3          	sub	a5,s11,a5
ffffffffc020351c:	8799                	srai	a5,a5,0x6
ffffffffc020351e:	97b2                	add	a5,a5,a2
    return KADDR(page2pa(page));
ffffffffc0203520:	0167f633          	and	a2,a5,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203524:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0203526:	06e67a63          	bgeu	a2,a4,ffffffffc020359a <copy_range+0x198>
ffffffffc020352a:	000ae517          	auipc	a0,0xae
ffffffffc020352e:	fce53503          	ld	a0,-50(a0) # ffffffffc02b14f8 <va_pa_offset>
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE);
ffffffffc0203532:	6605                	lui	a2,0x1
ffffffffc0203534:	00a685b3          	add	a1,a3,a0
ffffffffc0203538:	953e                	add	a0,a0,a5
ffffffffc020353a:	5b2020ef          	jal	ffffffffc0205aec <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc020353e:	01f9f693          	andi	a3,s3,31
ffffffffc0203542:	85ee                	mv	a1,s11
ffffffffc0203544:	8622                	mv	a2,s0
ffffffffc0203546:	855e                	mv	a0,s7
ffffffffc0203548:	984ff0ef          	jal	ffffffffc02026cc <page_insert>
            assert(ret == 0);
ffffffffc020354c:	dd05                	beqz	a0,ffffffffc0203484 <copy_range+0x82>
ffffffffc020354e:	00004697          	auipc	a3,0x4
ffffffffc0203552:	b3268693          	addi	a3,a3,-1230 # ffffffffc0207080 <etext+0x157c>
ffffffffc0203556:	00003617          	auipc	a2,0x3
ffffffffc020355a:	05260613          	addi	a2,a2,82 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020355e:	1b600593          	li	a1,438
ffffffffc0203562:	00003517          	auipc	a0,0x3
ffffffffc0203566:	4e650513          	addi	a0,a0,1254 # ffffffffc0206a48 <etext+0xf44>
ffffffffc020356a:	f25fc0ef          	jal	ffffffffc020048e <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc020356e:	002007b7          	lui	a5,0x200
ffffffffc0203572:	97a2                	add	a5,a5,s0
ffffffffc0203574:	ffe00437          	lui	s0,0xffe00
ffffffffc0203578:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc020357a:	b731                	j	ffffffffc0203486 <copy_range+0x84>
        intr_disable();
ffffffffc020357c:	c80fd0ef          	jal	ffffffffc02009fc <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203580:	000ae797          	auipc	a5,0xae
ffffffffc0203584:	f607b783          	ld	a5,-160(a5) # ffffffffc02b14e0 <pmm_manager>
ffffffffc0203588:	4505                	li	a0,1
ffffffffc020358a:	6f9c                	ld	a5,24(a5)
ffffffffc020358c:	9782                	jalr	a5
ffffffffc020358e:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc0203590:	c66fd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0203594:	b785                	j	ffffffffc02034f4 <copy_range+0xf2>
                return -E_NO_MEM;
ffffffffc0203596:	5571                	li	a0,-4
ffffffffc0203598:	bddd                	j	ffffffffc020348e <copy_range+0x8c>
ffffffffc020359a:	86be                	mv	a3,a5
ffffffffc020359c:	00003617          	auipc	a2,0x3
ffffffffc02035a0:	3bc60613          	addi	a2,a2,956 # ffffffffc0206958 <etext+0xe54>
ffffffffc02035a4:	07100593          	li	a1,113
ffffffffc02035a8:	00003517          	auipc	a0,0x3
ffffffffc02035ac:	3d850513          	addi	a0,a0,984 # ffffffffc0206980 <etext+0xe7c>
ffffffffc02035b0:	edffc0ef          	jal	ffffffffc020048e <__panic>
            assert(npage != NULL);
ffffffffc02035b4:	00004697          	auipc	a3,0x4
ffffffffc02035b8:	abc68693          	addi	a3,a3,-1348 # ffffffffc0207070 <etext+0x156c>
ffffffffc02035bc:	00003617          	auipc	a2,0x3
ffffffffc02035c0:	fec60613          	addi	a2,a2,-20 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02035c4:	19d00593          	li	a1,413
ffffffffc02035c8:	00003517          	auipc	a0,0x3
ffffffffc02035cc:	48050513          	addi	a0,a0,1152 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02035d0:	ebffc0ef          	jal	ffffffffc020048e <__panic>
            assert(page != NULL);
ffffffffc02035d4:	00004697          	auipc	a3,0x4
ffffffffc02035d8:	a8c68693          	addi	a3,a3,-1396 # ffffffffc0207060 <etext+0x155c>
ffffffffc02035dc:	00003617          	auipc	a2,0x3
ffffffffc02035e0:	fcc60613          	addi	a2,a2,-52 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02035e4:	19c00593          	li	a1,412
ffffffffc02035e8:	00003517          	auipc	a0,0x3
ffffffffc02035ec:	46050513          	addi	a0,a0,1120 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02035f0:	e9ffc0ef          	jal	ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02035f4:	00003617          	auipc	a2,0x3
ffffffffc02035f8:	43460613          	addi	a2,a2,1076 # ffffffffc0206a28 <etext+0xf24>
ffffffffc02035fc:	06900593          	li	a1,105
ffffffffc0203600:	00003517          	auipc	a0,0x3
ffffffffc0203604:	38050513          	addi	a0,a0,896 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0203608:	e87fc0ef          	jal	ffffffffc020048e <__panic>
        panic("pte2page called with invalid pte");
ffffffffc020360c:	00003617          	auipc	a2,0x3
ffffffffc0203610:	63460613          	addi	a2,a2,1588 # ffffffffc0206c40 <etext+0x113c>
ffffffffc0203614:	07f00593          	li	a1,127
ffffffffc0203618:	00003517          	auipc	a0,0x3
ffffffffc020361c:	36850513          	addi	a0,a0,872 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0203620:	e6ffc0ef          	jal	ffffffffc020048e <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0203624:	00003697          	auipc	a3,0x3
ffffffffc0203628:	46468693          	addi	a3,a3,1124 # ffffffffc0206a88 <etext+0xf84>
ffffffffc020362c:	00003617          	auipc	a2,0x3
ffffffffc0203630:	f7c60613          	addi	a2,a2,-132 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203634:	18400593          	li	a1,388
ffffffffc0203638:	00003517          	auipc	a0,0x3
ffffffffc020363c:	41050513          	addi	a0,a0,1040 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0203640:	e4ffc0ef          	jal	ffffffffc020048e <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203644:	00003697          	auipc	a3,0x3
ffffffffc0203648:	41468693          	addi	a3,a3,1044 # ffffffffc0206a58 <etext+0xf54>
ffffffffc020364c:	00003617          	auipc	a2,0x3
ffffffffc0203650:	f5c60613          	addi	a2,a2,-164 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203654:	18300593          	li	a1,387
ffffffffc0203658:	00003517          	auipc	a0,0x3
ffffffffc020365c:	3f050513          	addi	a0,a0,1008 # ffffffffc0206a48 <etext+0xf44>
ffffffffc0203660:	e2ffc0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0203664 <pgdir_alloc_page>:
{
ffffffffc0203664:	7139                	addi	sp,sp,-64
ffffffffc0203666:	f426                	sd	s1,40(sp)
ffffffffc0203668:	f04a                	sd	s2,32(sp)
ffffffffc020366a:	ec4e                	sd	s3,24(sp)
ffffffffc020366c:	fc06                	sd	ra,56(sp)
ffffffffc020366e:	f822                	sd	s0,48(sp)
ffffffffc0203670:	892a                	mv	s2,a0
ffffffffc0203672:	84ae                	mv	s1,a1
ffffffffc0203674:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203676:	100027f3          	csrr	a5,sstatus
ffffffffc020367a:	8b89                	andi	a5,a5,2
ffffffffc020367c:	ebb5                	bnez	a5,ffffffffc02036f0 <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc020367e:	000ae417          	auipc	s0,0xae
ffffffffc0203682:	e6240413          	addi	s0,s0,-414 # ffffffffc02b14e0 <pmm_manager>
ffffffffc0203686:	601c                	ld	a5,0(s0)
ffffffffc0203688:	4505                	li	a0,1
ffffffffc020368a:	6f9c                	ld	a5,24(a5)
ffffffffc020368c:	9782                	jalr	a5
ffffffffc020368e:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc0203690:	c5b9                	beqz	a1,ffffffffc02036de <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203692:	86ce                	mv	a3,s3
ffffffffc0203694:	854a                	mv	a0,s2
ffffffffc0203696:	8626                	mv	a2,s1
ffffffffc0203698:	e42e                	sd	a1,8(sp)
ffffffffc020369a:	832ff0ef          	jal	ffffffffc02026cc <page_insert>
ffffffffc020369e:	65a2                	ld	a1,8(sp)
ffffffffc02036a0:	e515                	bnez	a0,ffffffffc02036cc <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc02036a2:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc02036a4:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc02036a6:	4785                	li	a5,1
ffffffffc02036a8:	02f70c63          	beq	a4,a5,ffffffffc02036e0 <pgdir_alloc_page+0x7c>
ffffffffc02036ac:	00004697          	auipc	a3,0x4
ffffffffc02036b0:	9e468693          	addi	a3,a3,-1564 # ffffffffc0207090 <etext+0x158c>
ffffffffc02036b4:	00003617          	auipc	a2,0x3
ffffffffc02036b8:	ef460613          	addi	a2,a2,-268 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02036bc:	1ff00593          	li	a1,511
ffffffffc02036c0:	00003517          	auipc	a0,0x3
ffffffffc02036c4:	38850513          	addi	a0,a0,904 # ffffffffc0206a48 <etext+0xf44>
ffffffffc02036c8:	dc7fc0ef          	jal	ffffffffc020048e <__panic>
ffffffffc02036cc:	100027f3          	csrr	a5,sstatus
ffffffffc02036d0:	8b89                	andi	a5,a5,2
ffffffffc02036d2:	ef95                	bnez	a5,ffffffffc020370e <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc02036d4:	601c                	ld	a5,0(s0)
ffffffffc02036d6:	852e                	mv	a0,a1
ffffffffc02036d8:	4585                	li	a1,1
ffffffffc02036da:	739c                	ld	a5,32(a5)
ffffffffc02036dc:	9782                	jalr	a5
            return NULL;
ffffffffc02036de:	4581                	li	a1,0
}
ffffffffc02036e0:	70e2                	ld	ra,56(sp)
ffffffffc02036e2:	7442                	ld	s0,48(sp)
ffffffffc02036e4:	74a2                	ld	s1,40(sp)
ffffffffc02036e6:	7902                	ld	s2,32(sp)
ffffffffc02036e8:	69e2                	ld	s3,24(sp)
ffffffffc02036ea:	852e                	mv	a0,a1
ffffffffc02036ec:	6121                	addi	sp,sp,64
ffffffffc02036ee:	8082                	ret
        intr_disable();
ffffffffc02036f0:	b0cfd0ef          	jal	ffffffffc02009fc <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02036f4:	000ae417          	auipc	s0,0xae
ffffffffc02036f8:	dec40413          	addi	s0,s0,-532 # ffffffffc02b14e0 <pmm_manager>
ffffffffc02036fc:	601c                	ld	a5,0(s0)
ffffffffc02036fe:	4505                	li	a0,1
ffffffffc0203700:	6f9c                	ld	a5,24(a5)
ffffffffc0203702:	9782                	jalr	a5
ffffffffc0203704:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0203706:	af0fd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc020370a:	65a2                	ld	a1,8(sp)
ffffffffc020370c:	b751                	j	ffffffffc0203690 <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc020370e:	aeefd0ef          	jal	ffffffffc02009fc <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203712:	601c                	ld	a5,0(s0)
ffffffffc0203714:	6522                	ld	a0,8(sp)
ffffffffc0203716:	4585                	li	a1,1
ffffffffc0203718:	739c                	ld	a5,32(a5)
ffffffffc020371a:	9782                	jalr	a5
        intr_enable();
ffffffffc020371c:	adafd0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0203720:	bf7d                	j	ffffffffc02036de <pgdir_alloc_page+0x7a>

ffffffffc0203722 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203722:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0203724:	00004697          	auipc	a3,0x4
ffffffffc0203728:	98468693          	addi	a3,a3,-1660 # ffffffffc02070a8 <etext+0x15a4>
ffffffffc020372c:	00003617          	auipc	a2,0x3
ffffffffc0203730:	e7c60613          	addi	a2,a2,-388 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203734:	07400593          	li	a1,116
ffffffffc0203738:	00004517          	auipc	a0,0x4
ffffffffc020373c:	99050513          	addi	a0,a0,-1648 # ffffffffc02070c8 <etext+0x15c4>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc0203740:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0203742:	d4dfc0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0203746 <mm_create>:
{
ffffffffc0203746:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203748:	04000513          	li	a0,64
{
ffffffffc020374c:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020374e:	ddefe0ef          	jal	ffffffffc0201d2c <kmalloc>
    if (mm != NULL)
ffffffffc0203752:	cd19                	beqz	a0,ffffffffc0203770 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc0203754:	e508                	sd	a0,8(a0)
ffffffffc0203756:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203758:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020375c:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203760:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203764:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc0203768:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc020376c:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203770:	60a2                	ld	ra,8(sp)
ffffffffc0203772:	0141                	addi	sp,sp,16
ffffffffc0203774:	8082                	ret

ffffffffc0203776 <find_vma>:
    if (mm != NULL)
ffffffffc0203776:	c505                	beqz	a0,ffffffffc020379e <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc0203778:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020377a:	c781                	beqz	a5,ffffffffc0203782 <find_vma+0xc>
ffffffffc020377c:	6798                	ld	a4,8(a5)
ffffffffc020377e:	02e5f363          	bgeu	a1,a4,ffffffffc02037a4 <find_vma+0x2e>
    return listelm->next;
ffffffffc0203782:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc0203784:	00f50d63          	beq	a0,a5,ffffffffc020379e <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc0203788:	fe87b703          	ld	a4,-24(a5)
ffffffffc020378c:	00e5e663          	bltu	a1,a4,ffffffffc0203798 <find_vma+0x22>
ffffffffc0203790:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203794:	00e5ee63          	bltu	a1,a4,ffffffffc02037b0 <find_vma+0x3a>
ffffffffc0203798:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc020379a:	fef517e3          	bne	a0,a5,ffffffffc0203788 <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc020379e:	4781                	li	a5,0
}
ffffffffc02037a0:	853e                	mv	a0,a5
ffffffffc02037a2:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc02037a4:	6b98                	ld	a4,16(a5)
ffffffffc02037a6:	fce5fee3          	bgeu	a1,a4,ffffffffc0203782 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc02037aa:	e91c                	sd	a5,16(a0)
}
ffffffffc02037ac:	853e                	mv	a0,a5
ffffffffc02037ae:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc02037b0:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc02037b2:	e91c                	sd	a5,16(a0)
ffffffffc02037b4:	bfe5                	j	ffffffffc02037ac <find_vma+0x36>

ffffffffc02037b6 <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037b6:	6590                	ld	a2,8(a1)
ffffffffc02037b8:	0105b803          	ld	a6,16(a1)
{
ffffffffc02037bc:	1141                	addi	sp,sp,-16
ffffffffc02037be:	e406                	sd	ra,8(sp)
ffffffffc02037c0:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037c2:	01066763          	bltu	a2,a6,ffffffffc02037d0 <insert_vma_struct+0x1a>
ffffffffc02037c6:	a8b9                	j	ffffffffc0203824 <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc02037c8:	fe87b703          	ld	a4,-24(a5)
ffffffffc02037cc:	04e66763          	bltu	a2,a4,ffffffffc020381a <insert_vma_struct+0x64>
ffffffffc02037d0:	86be                	mv	a3,a5
ffffffffc02037d2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc02037d4:	fef51ae3          	bne	a0,a5,ffffffffc02037c8 <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc02037d8:	02a68463          	beq	a3,a0,ffffffffc0203800 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc02037dc:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037e0:	fe86b883          	ld	a7,-24(a3)
ffffffffc02037e4:	08e8f063          	bgeu	a7,a4,ffffffffc0203864 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037e8:	04e66e63          	bltu	a2,a4,ffffffffc0203844 <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc02037ec:	00f50a63          	beq	a0,a5,ffffffffc0203800 <insert_vma_struct+0x4a>
ffffffffc02037f0:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037f4:	05076863          	bltu	a4,a6,ffffffffc0203844 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02037f8:	ff07b603          	ld	a2,-16(a5)
ffffffffc02037fc:	02c77263          	bgeu	a4,a2,ffffffffc0203820 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203800:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203802:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0203804:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0203808:	e390                	sd	a2,0(a5)
ffffffffc020380a:	e690                	sd	a2,8(a3)
}
ffffffffc020380c:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020380e:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0203810:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc0203812:	2705                	addiw	a4,a4,1 # fffffffffe000001 <boot_dtb+0x3dd4aa79>
ffffffffc0203814:	d118                	sw	a4,32(a0)
}
ffffffffc0203816:	0141                	addi	sp,sp,16
ffffffffc0203818:	8082                	ret
    if (le_prev != list)
ffffffffc020381a:	fca691e3          	bne	a3,a0,ffffffffc02037dc <insert_vma_struct+0x26>
ffffffffc020381e:	bfd9                	j	ffffffffc02037f4 <insert_vma_struct+0x3e>
ffffffffc0203820:	f03ff0ef          	jal	ffffffffc0203722 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203824:	00004697          	auipc	a3,0x4
ffffffffc0203828:	8b468693          	addi	a3,a3,-1868 # ffffffffc02070d8 <etext+0x15d4>
ffffffffc020382c:	00003617          	auipc	a2,0x3
ffffffffc0203830:	d7c60613          	addi	a2,a2,-644 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203834:	07a00593          	li	a1,122
ffffffffc0203838:	00004517          	auipc	a0,0x4
ffffffffc020383c:	89050513          	addi	a0,a0,-1904 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203840:	c4ffc0ef          	jal	ffffffffc020048e <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0203844:	00004697          	auipc	a3,0x4
ffffffffc0203848:	8d468693          	addi	a3,a3,-1836 # ffffffffc0207118 <etext+0x1614>
ffffffffc020384c:	00003617          	auipc	a2,0x3
ffffffffc0203850:	d5c60613          	addi	a2,a2,-676 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203854:	07300593          	li	a1,115
ffffffffc0203858:	00004517          	auipc	a0,0x4
ffffffffc020385c:	87050513          	addi	a0,a0,-1936 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203860:	c2ffc0ef          	jal	ffffffffc020048e <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203864:	00004697          	auipc	a3,0x4
ffffffffc0203868:	89468693          	addi	a3,a3,-1900 # ffffffffc02070f8 <etext+0x15f4>
ffffffffc020386c:	00003617          	auipc	a2,0x3
ffffffffc0203870:	d3c60613          	addi	a2,a2,-708 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203874:	07200593          	li	a1,114
ffffffffc0203878:	00004517          	auipc	a0,0x4
ffffffffc020387c:	85050513          	addi	a0,a0,-1968 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203880:	c0ffc0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0203884 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc0203884:	591c                	lw	a5,48(a0)
{
ffffffffc0203886:	1141                	addi	sp,sp,-16
ffffffffc0203888:	e406                	sd	ra,8(sp)
ffffffffc020388a:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc020388c:	e78d                	bnez	a5,ffffffffc02038b6 <mm_destroy+0x32>
ffffffffc020388e:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203890:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203892:	00a40c63          	beq	s0,a0,ffffffffc02038aa <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0203896:	6118                	ld	a4,0(a0)
ffffffffc0203898:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc020389a:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc020389c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020389e:	e398                	sd	a4,0(a5)
ffffffffc02038a0:	d32fe0ef          	jal	ffffffffc0201dd2 <kfree>
    return listelm->next;
ffffffffc02038a4:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc02038a6:	fea418e3          	bne	s0,a0,ffffffffc0203896 <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc02038aa:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc02038ac:	6402                	ld	s0,0(sp)
ffffffffc02038ae:	60a2                	ld	ra,8(sp)
ffffffffc02038b0:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc02038b2:	d20fe06f          	j	ffffffffc0201dd2 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02038b6:	00004697          	auipc	a3,0x4
ffffffffc02038ba:	88268693          	addi	a3,a3,-1918 # ffffffffc0207138 <etext+0x1634>
ffffffffc02038be:	00003617          	auipc	a2,0x3
ffffffffc02038c2:	cea60613          	addi	a2,a2,-790 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02038c6:	09e00593          	li	a1,158
ffffffffc02038ca:	00003517          	auipc	a0,0x3
ffffffffc02038ce:	7fe50513          	addi	a0,a0,2046 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc02038d2:	bbdfc0ef          	jal	ffffffffc020048e <__panic>

ffffffffc02038d6 <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02038d6:	6785                	lui	a5,0x1
ffffffffc02038d8:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7f21>
ffffffffc02038da:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc02038dc:	4785                	li	a5,1
{
ffffffffc02038de:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02038e0:	962e                	add	a2,a2,a1
ffffffffc02038e2:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc02038e4:	07fe                	slli	a5,a5,0x1f
{
ffffffffc02038e6:	f822                	sd	s0,48(sp)
ffffffffc02038e8:	f426                	sd	s1,40(sp)
ffffffffc02038ea:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02038ee:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc02038f2:	0785                	addi	a5,a5,1
ffffffffc02038f4:	0084b633          	sltu	a2,s1,s0
ffffffffc02038f8:	00f437b3          	sltu	a5,s0,a5
ffffffffc02038fc:	00163613          	seqz	a2,a2
ffffffffc0203900:	0017b793          	seqz	a5,a5
{
ffffffffc0203904:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc0203906:	8fd1                	or	a5,a5,a2
ffffffffc0203908:	ebbd                	bnez	a5,ffffffffc020397e <mm_map+0xa8>
ffffffffc020390a:	002007b7          	lui	a5,0x200
ffffffffc020390e:	06f4e863          	bltu	s1,a5,ffffffffc020397e <mm_map+0xa8>
ffffffffc0203912:	f04a                	sd	s2,32(sp)
ffffffffc0203914:	ec4e                	sd	s3,24(sp)
ffffffffc0203916:	e852                	sd	s4,16(sp)
ffffffffc0203918:	892a                	mv	s2,a0
ffffffffc020391a:	89ba                	mv	s3,a4
ffffffffc020391c:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc020391e:	c135                	beqz	a0,ffffffffc0203982 <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc0203920:	85a6                	mv	a1,s1
ffffffffc0203922:	e55ff0ef          	jal	ffffffffc0203776 <find_vma>
ffffffffc0203926:	c501                	beqz	a0,ffffffffc020392e <mm_map+0x58>
ffffffffc0203928:	651c                	ld	a5,8(a0)
ffffffffc020392a:	0487e763          	bltu	a5,s0,ffffffffc0203978 <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020392e:	03000513          	li	a0,48
ffffffffc0203932:	bfafe0ef          	jal	ffffffffc0201d2c <kmalloc>
ffffffffc0203936:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0203938:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc020393a:	c59d                	beqz	a1,ffffffffc0203968 <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc020393c:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc020393e:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc0203940:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0203944:	854a                	mv	a0,s2
ffffffffc0203946:	e42e                	sd	a1,8(sp)
ffffffffc0203948:	e6fff0ef          	jal	ffffffffc02037b6 <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc020394c:	65a2                	ld	a1,8(sp)
ffffffffc020394e:	00098463          	beqz	s3,ffffffffc0203956 <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc0203952:	00b9b023          	sd	a1,0(s3)
ffffffffc0203956:	7902                	ld	s2,32(sp)
ffffffffc0203958:	69e2                	ld	s3,24(sp)
ffffffffc020395a:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc020395c:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc020395e:	70e2                	ld	ra,56(sp)
ffffffffc0203960:	7442                	ld	s0,48(sp)
ffffffffc0203962:	74a2                	ld	s1,40(sp)
ffffffffc0203964:	6121                	addi	sp,sp,64
ffffffffc0203966:	8082                	ret
ffffffffc0203968:	70e2                	ld	ra,56(sp)
ffffffffc020396a:	7442                	ld	s0,48(sp)
ffffffffc020396c:	7902                	ld	s2,32(sp)
ffffffffc020396e:	69e2                	ld	s3,24(sp)
ffffffffc0203970:	6a42                	ld	s4,16(sp)
ffffffffc0203972:	74a2                	ld	s1,40(sp)
ffffffffc0203974:	6121                	addi	sp,sp,64
ffffffffc0203976:	8082                	ret
ffffffffc0203978:	7902                	ld	s2,32(sp)
ffffffffc020397a:	69e2                	ld	s3,24(sp)
ffffffffc020397c:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc020397e:	5575                	li	a0,-3
ffffffffc0203980:	bff9                	j	ffffffffc020395e <mm_map+0x88>
    assert(mm != NULL);
ffffffffc0203982:	00003697          	auipc	a3,0x3
ffffffffc0203986:	7ce68693          	addi	a3,a3,1998 # ffffffffc0207150 <etext+0x164c>
ffffffffc020398a:	00003617          	auipc	a2,0x3
ffffffffc020398e:	c1e60613          	addi	a2,a2,-994 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203992:	0b300593          	li	a1,179
ffffffffc0203996:	00003517          	auipc	a0,0x3
ffffffffc020399a:	73250513          	addi	a0,a0,1842 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc020399e:	af1fc0ef          	jal	ffffffffc020048e <__panic>

ffffffffc02039a2 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc02039a2:	7139                	addi	sp,sp,-64
ffffffffc02039a4:	fc06                	sd	ra,56(sp)
ffffffffc02039a6:	f822                	sd	s0,48(sp)
ffffffffc02039a8:	f426                	sd	s1,40(sp)
ffffffffc02039aa:	f04a                	sd	s2,32(sp)
ffffffffc02039ac:	ec4e                	sd	s3,24(sp)
ffffffffc02039ae:	e852                	sd	s4,16(sp)
ffffffffc02039b0:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02039b2:	c525                	beqz	a0,ffffffffc0203a1a <dup_mmap+0x78>
ffffffffc02039b4:	892a                	mv	s2,a0
ffffffffc02039b6:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02039b8:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02039ba:	c1a5                	beqz	a1,ffffffffc0203a1a <dup_mmap+0x78>
    return listelm->prev;
ffffffffc02039bc:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc02039be:	04848c63          	beq	s1,s0,ffffffffc0203a16 <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039c2:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc02039c6:	fe843a83          	ld	s5,-24(s0)
ffffffffc02039ca:	ff043a03          	ld	s4,-16(s0)
ffffffffc02039ce:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02039d2:	b5afe0ef          	jal	ffffffffc0201d2c <kmalloc>
    if (vma != NULL)
ffffffffc02039d6:	c515                	beqz	a0,ffffffffc0203a02 <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02039d8:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc02039da:	01553423          	sd	s5,8(a0)
ffffffffc02039de:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02039e2:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc02039e6:	854a                	mv	a0,s2
ffffffffc02039e8:	dcfff0ef          	jal	ffffffffc02037b6 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc02039ec:	ff043683          	ld	a3,-16(s0)
ffffffffc02039f0:	fe843603          	ld	a2,-24(s0)
ffffffffc02039f4:	6c8c                	ld	a1,24(s1)
ffffffffc02039f6:	01893503          	ld	a0,24(s2)
ffffffffc02039fa:	4701                	li	a4,0
ffffffffc02039fc:	a07ff0ef          	jal	ffffffffc0203402 <copy_range>
ffffffffc0203a00:	dd55                	beqz	a0,ffffffffc02039bc <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc0203a02:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc0203a04:	70e2                	ld	ra,56(sp)
ffffffffc0203a06:	7442                	ld	s0,48(sp)
ffffffffc0203a08:	74a2                	ld	s1,40(sp)
ffffffffc0203a0a:	7902                	ld	s2,32(sp)
ffffffffc0203a0c:	69e2                	ld	s3,24(sp)
ffffffffc0203a0e:	6a42                	ld	s4,16(sp)
ffffffffc0203a10:	6aa2                	ld	s5,8(sp)
ffffffffc0203a12:	6121                	addi	sp,sp,64
ffffffffc0203a14:	8082                	ret
    return 0;
ffffffffc0203a16:	4501                	li	a0,0
ffffffffc0203a18:	b7f5                	j	ffffffffc0203a04 <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc0203a1a:	00003697          	auipc	a3,0x3
ffffffffc0203a1e:	74668693          	addi	a3,a3,1862 # ffffffffc0207160 <etext+0x165c>
ffffffffc0203a22:	00003617          	auipc	a2,0x3
ffffffffc0203a26:	b8660613          	addi	a2,a2,-1146 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203a2a:	0cf00593          	li	a1,207
ffffffffc0203a2e:	00003517          	auipc	a0,0x3
ffffffffc0203a32:	69a50513          	addi	a0,a0,1690 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203a36:	a59fc0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0203a3a <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc0203a3a:	1101                	addi	sp,sp,-32
ffffffffc0203a3c:	ec06                	sd	ra,24(sp)
ffffffffc0203a3e:	e822                	sd	s0,16(sp)
ffffffffc0203a40:	e426                	sd	s1,8(sp)
ffffffffc0203a42:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a44:	c531                	beqz	a0,ffffffffc0203a90 <exit_mmap+0x56>
ffffffffc0203a46:	591c                	lw	a5,48(a0)
ffffffffc0203a48:	84aa                	mv	s1,a0
ffffffffc0203a4a:	e3b9                	bnez	a5,ffffffffc0203a90 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0203a4c:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0203a4e:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc0203a52:	02850663          	beq	a0,s0,ffffffffc0203a7e <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a56:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a5a:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a5e:	854a                	mv	a0,s2
ffffffffc0203a60:	fe8fe0ef          	jal	ffffffffc0202248 <unmap_range>
ffffffffc0203a64:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a66:	fe8498e3          	bne	s1,s0,ffffffffc0203a56 <exit_mmap+0x1c>
ffffffffc0203a6a:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a6c:	00848c63          	beq	s1,s0,ffffffffc0203a84 <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a70:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a74:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a78:	854a                	mv	a0,s2
ffffffffc0203a7a:	903fe0ef          	jal	ffffffffc020237c <exit_range>
ffffffffc0203a7e:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a80:	fe8498e3          	bne	s1,s0,ffffffffc0203a70 <exit_mmap+0x36>
    }
}
ffffffffc0203a84:	60e2                	ld	ra,24(sp)
ffffffffc0203a86:	6442                	ld	s0,16(sp)
ffffffffc0203a88:	64a2                	ld	s1,8(sp)
ffffffffc0203a8a:	6902                	ld	s2,0(sp)
ffffffffc0203a8c:	6105                	addi	sp,sp,32
ffffffffc0203a8e:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a90:	00003697          	auipc	a3,0x3
ffffffffc0203a94:	6f068693          	addi	a3,a3,1776 # ffffffffc0207180 <etext+0x167c>
ffffffffc0203a98:	00003617          	auipc	a2,0x3
ffffffffc0203a9c:	b1060613          	addi	a2,a2,-1264 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203aa0:	0e800593          	li	a1,232
ffffffffc0203aa4:	00003517          	auipc	a0,0x3
ffffffffc0203aa8:	62450513          	addi	a0,a0,1572 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203aac:	9e3fc0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0203ab0 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203ab0:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ab2:	04000513          	li	a0,64
{
ffffffffc0203ab6:	f406                	sd	ra,40(sp)
ffffffffc0203ab8:	f022                	sd	s0,32(sp)
ffffffffc0203aba:	ec26                	sd	s1,24(sp)
ffffffffc0203abc:	e84a                	sd	s2,16(sp)
ffffffffc0203abe:	e44e                	sd	s3,8(sp)
ffffffffc0203ac0:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203ac2:	a6afe0ef          	jal	ffffffffc0201d2c <kmalloc>
    if (mm != NULL)
ffffffffc0203ac6:	16050c63          	beqz	a0,ffffffffc0203c3e <vmm_init+0x18e>
ffffffffc0203aca:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0203acc:	e508                	sd	a0,8(a0)
ffffffffc0203ace:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203ad0:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203ad4:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203ad8:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203adc:	02053423          	sd	zero,40(a0)
ffffffffc0203ae0:	02052823          	sw	zero,48(a0)
ffffffffc0203ae4:	02053c23          	sd	zero,56(a0)
ffffffffc0203ae8:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203aec:	03000513          	li	a0,48
ffffffffc0203af0:	a3cfe0ef          	jal	ffffffffc0201d2c <kmalloc>
    if (vma != NULL)
ffffffffc0203af4:	12050563          	beqz	a0,ffffffffc0203c1e <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc0203af8:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203afc:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203afe:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203b02:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b04:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0203b06:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0203b08:	8522                	mv	a0,s0
ffffffffc0203b0a:	cadff0ef          	jal	ffffffffc02037b6 <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203b0e:	fcf9                	bnez	s1,ffffffffc0203aec <vmm_init+0x3c>
ffffffffc0203b10:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b14:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203b18:	03000513          	li	a0,48
ffffffffc0203b1c:	a10fe0ef          	jal	ffffffffc0201d2c <kmalloc>
    if (vma != NULL)
ffffffffc0203b20:	12050f63          	beqz	a0,ffffffffc0203c5e <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc0203b24:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203b28:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203b2a:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203b2e:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203b30:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b32:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203b34:	8522                	mv	a0,s0
ffffffffc0203b36:	c81ff0ef          	jal	ffffffffc02037b6 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203b3a:	fd249fe3          	bne	s1,s2,ffffffffc0203b18 <vmm_init+0x68>
    return listelm->next;
ffffffffc0203b3e:	641c                	ld	a5,8(s0)
ffffffffc0203b40:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203b42:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203b46:	1ef40c63          	beq	s0,a5,ffffffffc0203d3e <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203b4a:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_matrix_out_size+0x1f4ac0>
ffffffffc0203b4e:	ffe70693          	addi	a3,a4,-2
ffffffffc0203b52:	12d61663          	bne	a2,a3,ffffffffc0203c7e <vmm_init+0x1ce>
ffffffffc0203b56:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203b5a:	12e69263          	bne	a3,a4,ffffffffc0203c7e <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203b5e:	0715                	addi	a4,a4,5
ffffffffc0203b60:	679c                	ld	a5,8(a5)
ffffffffc0203b62:	feb712e3          	bne	a4,a1,ffffffffc0203b46 <vmm_init+0x96>
ffffffffc0203b66:	491d                	li	s2,7
ffffffffc0203b68:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b6a:	85a6                	mv	a1,s1
ffffffffc0203b6c:	8522                	mv	a0,s0
ffffffffc0203b6e:	c09ff0ef          	jal	ffffffffc0203776 <find_vma>
ffffffffc0203b72:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203b74:	20050563          	beqz	a0,ffffffffc0203d7e <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b78:	00148593          	addi	a1,s1,1
ffffffffc0203b7c:	8522                	mv	a0,s0
ffffffffc0203b7e:	bf9ff0ef          	jal	ffffffffc0203776 <find_vma>
ffffffffc0203b82:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b84:	1c050d63          	beqz	a0,ffffffffc0203d5e <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b88:	85ca                	mv	a1,s2
ffffffffc0203b8a:	8522                	mv	a0,s0
ffffffffc0203b8c:	bebff0ef          	jal	ffffffffc0203776 <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b90:	18051763          	bnez	a0,ffffffffc0203d1e <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b94:	00348593          	addi	a1,s1,3
ffffffffc0203b98:	8522                	mv	a0,s0
ffffffffc0203b9a:	bddff0ef          	jal	ffffffffc0203776 <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b9e:	16051063          	bnez	a0,ffffffffc0203cfe <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203ba2:	00448593          	addi	a1,s1,4
ffffffffc0203ba6:	8522                	mv	a0,s0
ffffffffc0203ba8:	bcfff0ef          	jal	ffffffffc0203776 <find_vma>
        assert(vma5 == NULL);
ffffffffc0203bac:	12051963          	bnez	a0,ffffffffc0203cde <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203bb0:	008a3783          	ld	a5,8(s4)
ffffffffc0203bb4:	10979563          	bne	a5,s1,ffffffffc0203cbe <vmm_init+0x20e>
ffffffffc0203bb8:	010a3783          	ld	a5,16(s4)
ffffffffc0203bbc:	11279163          	bne	a5,s2,ffffffffc0203cbe <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203bc0:	0089b783          	ld	a5,8(s3)
ffffffffc0203bc4:	0c979d63          	bne	a5,s1,ffffffffc0203c9e <vmm_init+0x1ee>
ffffffffc0203bc8:	0109b783          	ld	a5,16(s3)
ffffffffc0203bcc:	0d279963          	bne	a5,s2,ffffffffc0203c9e <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203bd0:	0495                	addi	s1,s1,5
ffffffffc0203bd2:	1f900793          	li	a5,505
ffffffffc0203bd6:	0915                	addi	s2,s2,5
ffffffffc0203bd8:	f8f499e3          	bne	s1,a5,ffffffffc0203b6a <vmm_init+0xba>
ffffffffc0203bdc:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203bde:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203be0:	85a6                	mv	a1,s1
ffffffffc0203be2:	8522                	mv	a0,s0
ffffffffc0203be4:	b93ff0ef          	jal	ffffffffc0203776 <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203be8:	1a051b63          	bnez	a0,ffffffffc0203d9e <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203bec:	14fd                	addi	s1,s1,-1
ffffffffc0203bee:	ff2499e3          	bne	s1,s2,ffffffffc0203be0 <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203bf2:	8522                	mv	a0,s0
ffffffffc0203bf4:	c91ff0ef          	jal	ffffffffc0203884 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203bf8:	00003517          	auipc	a0,0x3
ffffffffc0203bfc:	6f850513          	addi	a0,a0,1784 # ffffffffc02072f0 <etext+0x17ec>
ffffffffc0203c00:	ddcfc0ef          	jal	ffffffffc02001dc <cprintf>
}
ffffffffc0203c04:	7402                	ld	s0,32(sp)
ffffffffc0203c06:	70a2                	ld	ra,40(sp)
ffffffffc0203c08:	64e2                	ld	s1,24(sp)
ffffffffc0203c0a:	6942                	ld	s2,16(sp)
ffffffffc0203c0c:	69a2                	ld	s3,8(sp)
ffffffffc0203c0e:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203c10:	00003517          	auipc	a0,0x3
ffffffffc0203c14:	70050513          	addi	a0,a0,1792 # ffffffffc0207310 <etext+0x180c>
}
ffffffffc0203c18:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203c1a:	dc2fc06f          	j	ffffffffc02001dc <cprintf>
        assert(vma != NULL);
ffffffffc0203c1e:	00003697          	auipc	a3,0x3
ffffffffc0203c22:	58268693          	addi	a3,a3,1410 # ffffffffc02071a0 <etext+0x169c>
ffffffffc0203c26:	00003617          	auipc	a2,0x3
ffffffffc0203c2a:	98260613          	addi	a2,a2,-1662 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203c2e:	12c00593          	li	a1,300
ffffffffc0203c32:	00003517          	auipc	a0,0x3
ffffffffc0203c36:	49650513          	addi	a0,a0,1174 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203c3a:	855fc0ef          	jal	ffffffffc020048e <__panic>
    assert(mm != NULL);
ffffffffc0203c3e:	00003697          	auipc	a3,0x3
ffffffffc0203c42:	51268693          	addi	a3,a3,1298 # ffffffffc0207150 <etext+0x164c>
ffffffffc0203c46:	00003617          	auipc	a2,0x3
ffffffffc0203c4a:	96260613          	addi	a2,a2,-1694 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203c4e:	12400593          	li	a1,292
ffffffffc0203c52:	00003517          	auipc	a0,0x3
ffffffffc0203c56:	47650513          	addi	a0,a0,1142 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203c5a:	835fc0ef          	jal	ffffffffc020048e <__panic>
        assert(vma != NULL);
ffffffffc0203c5e:	00003697          	auipc	a3,0x3
ffffffffc0203c62:	54268693          	addi	a3,a3,1346 # ffffffffc02071a0 <etext+0x169c>
ffffffffc0203c66:	00003617          	auipc	a2,0x3
ffffffffc0203c6a:	94260613          	addi	a2,a2,-1726 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203c6e:	13300593          	li	a1,307
ffffffffc0203c72:	00003517          	auipc	a0,0x3
ffffffffc0203c76:	45650513          	addi	a0,a0,1110 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203c7a:	815fc0ef          	jal	ffffffffc020048e <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203c7e:	00003697          	auipc	a3,0x3
ffffffffc0203c82:	54a68693          	addi	a3,a3,1354 # ffffffffc02071c8 <etext+0x16c4>
ffffffffc0203c86:	00003617          	auipc	a2,0x3
ffffffffc0203c8a:	92260613          	addi	a2,a2,-1758 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203c8e:	13d00593          	li	a1,317
ffffffffc0203c92:	00003517          	auipc	a0,0x3
ffffffffc0203c96:	43650513          	addi	a0,a0,1078 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203c9a:	ff4fc0ef          	jal	ffffffffc020048e <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c9e:	00003697          	auipc	a3,0x3
ffffffffc0203ca2:	5e268693          	addi	a3,a3,1506 # ffffffffc0207280 <etext+0x177c>
ffffffffc0203ca6:	00003617          	auipc	a2,0x3
ffffffffc0203caa:	90260613          	addi	a2,a2,-1790 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203cae:	14f00593          	li	a1,335
ffffffffc0203cb2:	00003517          	auipc	a0,0x3
ffffffffc0203cb6:	41650513          	addi	a0,a0,1046 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203cba:	fd4fc0ef          	jal	ffffffffc020048e <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203cbe:	00003697          	auipc	a3,0x3
ffffffffc0203cc2:	59268693          	addi	a3,a3,1426 # ffffffffc0207250 <etext+0x174c>
ffffffffc0203cc6:	00003617          	auipc	a2,0x3
ffffffffc0203cca:	8e260613          	addi	a2,a2,-1822 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203cce:	14e00593          	li	a1,334
ffffffffc0203cd2:	00003517          	auipc	a0,0x3
ffffffffc0203cd6:	3f650513          	addi	a0,a0,1014 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203cda:	fb4fc0ef          	jal	ffffffffc020048e <__panic>
        assert(vma5 == NULL);
ffffffffc0203cde:	00003697          	auipc	a3,0x3
ffffffffc0203ce2:	56268693          	addi	a3,a3,1378 # ffffffffc0207240 <etext+0x173c>
ffffffffc0203ce6:	00003617          	auipc	a2,0x3
ffffffffc0203cea:	8c260613          	addi	a2,a2,-1854 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203cee:	14c00593          	li	a1,332
ffffffffc0203cf2:	00003517          	auipc	a0,0x3
ffffffffc0203cf6:	3d650513          	addi	a0,a0,982 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203cfa:	f94fc0ef          	jal	ffffffffc020048e <__panic>
        assert(vma4 == NULL);
ffffffffc0203cfe:	00003697          	auipc	a3,0x3
ffffffffc0203d02:	53268693          	addi	a3,a3,1330 # ffffffffc0207230 <etext+0x172c>
ffffffffc0203d06:	00003617          	auipc	a2,0x3
ffffffffc0203d0a:	8a260613          	addi	a2,a2,-1886 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203d0e:	14a00593          	li	a1,330
ffffffffc0203d12:	00003517          	auipc	a0,0x3
ffffffffc0203d16:	3b650513          	addi	a0,a0,950 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203d1a:	f74fc0ef          	jal	ffffffffc020048e <__panic>
        assert(vma3 == NULL);
ffffffffc0203d1e:	00003697          	auipc	a3,0x3
ffffffffc0203d22:	50268693          	addi	a3,a3,1282 # ffffffffc0207220 <etext+0x171c>
ffffffffc0203d26:	00003617          	auipc	a2,0x3
ffffffffc0203d2a:	88260613          	addi	a2,a2,-1918 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203d2e:	14800593          	li	a1,328
ffffffffc0203d32:	00003517          	auipc	a0,0x3
ffffffffc0203d36:	39650513          	addi	a0,a0,918 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203d3a:	f54fc0ef          	jal	ffffffffc020048e <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203d3e:	00003697          	auipc	a3,0x3
ffffffffc0203d42:	47268693          	addi	a3,a3,1138 # ffffffffc02071b0 <etext+0x16ac>
ffffffffc0203d46:	00003617          	auipc	a2,0x3
ffffffffc0203d4a:	86260613          	addi	a2,a2,-1950 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203d4e:	13b00593          	li	a1,315
ffffffffc0203d52:	00003517          	auipc	a0,0x3
ffffffffc0203d56:	37650513          	addi	a0,a0,886 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203d5a:	f34fc0ef          	jal	ffffffffc020048e <__panic>
        assert(vma2 != NULL);
ffffffffc0203d5e:	00003697          	auipc	a3,0x3
ffffffffc0203d62:	4b268693          	addi	a3,a3,1202 # ffffffffc0207210 <etext+0x170c>
ffffffffc0203d66:	00003617          	auipc	a2,0x3
ffffffffc0203d6a:	84260613          	addi	a2,a2,-1982 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203d6e:	14600593          	li	a1,326
ffffffffc0203d72:	00003517          	auipc	a0,0x3
ffffffffc0203d76:	35650513          	addi	a0,a0,854 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203d7a:	f14fc0ef          	jal	ffffffffc020048e <__panic>
        assert(vma1 != NULL);
ffffffffc0203d7e:	00003697          	auipc	a3,0x3
ffffffffc0203d82:	48268693          	addi	a3,a3,1154 # ffffffffc0207200 <etext+0x16fc>
ffffffffc0203d86:	00003617          	auipc	a2,0x3
ffffffffc0203d8a:	82260613          	addi	a2,a2,-2014 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203d8e:	14400593          	li	a1,324
ffffffffc0203d92:	00003517          	auipc	a0,0x3
ffffffffc0203d96:	33650513          	addi	a0,a0,822 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203d9a:	ef4fc0ef          	jal	ffffffffc020048e <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d9e:	6914                	ld	a3,16(a0)
ffffffffc0203da0:	6510                	ld	a2,8(a0)
ffffffffc0203da2:	0004859b          	sext.w	a1,s1
ffffffffc0203da6:	00003517          	auipc	a0,0x3
ffffffffc0203daa:	50a50513          	addi	a0,a0,1290 # ffffffffc02072b0 <etext+0x17ac>
ffffffffc0203dae:	c2efc0ef          	jal	ffffffffc02001dc <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203db2:	00003697          	auipc	a3,0x3
ffffffffc0203db6:	52668693          	addi	a3,a3,1318 # ffffffffc02072d8 <etext+0x17d4>
ffffffffc0203dba:	00002617          	auipc	a2,0x2
ffffffffc0203dbe:	7ee60613          	addi	a2,a2,2030 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0203dc2:	15900593          	li	a1,345
ffffffffc0203dc6:	00003517          	auipc	a0,0x3
ffffffffc0203dca:	30250513          	addi	a0,a0,770 # ffffffffc02070c8 <etext+0x15c4>
ffffffffc0203dce:	ec0fc0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0203dd2 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203dd2:	7179                	addi	sp,sp,-48
ffffffffc0203dd4:	f022                	sd	s0,32(sp)
ffffffffc0203dd6:	f406                	sd	ra,40(sp)
ffffffffc0203dd8:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203dda:	c52d                	beqz	a0,ffffffffc0203e44 <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203ddc:	002007b7          	lui	a5,0x200
ffffffffc0203de0:	04f5ed63          	bltu	a1,a5,ffffffffc0203e3a <user_mem_check+0x68>
ffffffffc0203de4:	ec26                	sd	s1,24(sp)
ffffffffc0203de6:	00c584b3          	add	s1,a1,a2
ffffffffc0203dea:	0695fa63          	bgeu	a1,s1,ffffffffc0203e5e <user_mem_check+0x8c>
ffffffffc0203dee:	4785                	li	a5,1
ffffffffc0203df0:	07fe                	slli	a5,a5,0x1f
ffffffffc0203df2:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_matrix_out_size+0x1f4ad9>
ffffffffc0203df4:	06f4f563          	bgeu	s1,a5,ffffffffc0203e5e <user_mem_check+0x8c>
ffffffffc0203df8:	e84a                	sd	s2,16(sp)
ffffffffc0203dfa:	e44e                	sd	s3,8(sp)
ffffffffc0203dfc:	8936                	mv	s2,a3
ffffffffc0203dfe:	89aa                	mv	s3,a0
ffffffffc0203e00:	a829                	j	ffffffffc0203e1a <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e02:	6685                	lui	a3,0x1
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e04:	0027f613          	andi	a2,a5,2
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e08:	9736                	add	a4,a4,a3
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e0a:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e0c:	c605                	beqz	a2,ffffffffc0203e34 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203e0e:	c399                	beqz	a5,ffffffffc0203e14 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203e10:	02e46263          	bltu	s0,a4,ffffffffc0203e34 <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203e14:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203e16:	06947563          	bgeu	s0,s1,ffffffffc0203e80 <user_mem_check+0xae>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203e1a:	85a2                	mv	a1,s0
ffffffffc0203e1c:	854e                	mv	a0,s3
ffffffffc0203e1e:	959ff0ef          	jal	ffffffffc0203776 <find_vma>
ffffffffc0203e22:	c909                	beqz	a0,ffffffffc0203e34 <user_mem_check+0x62>
ffffffffc0203e24:	6518                	ld	a4,8(a0)
ffffffffc0203e26:	00e46763          	bltu	s0,a4,ffffffffc0203e34 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203e2a:	4d1c                	lw	a5,24(a0)
ffffffffc0203e2c:	fc091be3          	bnez	s2,ffffffffc0203e02 <user_mem_check+0x30>
ffffffffc0203e30:	8b85                	andi	a5,a5,1
ffffffffc0203e32:	f3ed                	bnez	a5,ffffffffc0203e14 <user_mem_check+0x42>
ffffffffc0203e34:	64e2                	ld	s1,24(sp)
ffffffffc0203e36:	6942                	ld	s2,16(sp)
ffffffffc0203e38:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203e3a:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0203e3c:	70a2                	ld	ra,40(sp)
ffffffffc0203e3e:	7402                	ld	s0,32(sp)
ffffffffc0203e40:	6145                	addi	sp,sp,48
ffffffffc0203e42:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203e44:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e48:	00f5ed63          	bltu	a1,a5,ffffffffc0203e62 <user_mem_check+0x90>
ffffffffc0203e4c:	962e                	add	a2,a2,a1
ffffffffc0203e4e:	fec5f7e3          	bgeu	a1,a2,ffffffffc0203e3c <user_mem_check+0x6a>
ffffffffc0203e52:	c8000537          	lui	a0,0xc8000
ffffffffc0203e56:	0505                	addi	a0,a0,1 # ffffffffc8000001 <boot_dtb+0x7d4aa79>
ffffffffc0203e58:	00a63533          	sltu	a0,a2,a0
ffffffffc0203e5c:	b7c5                	j	ffffffffc0203e3c <user_mem_check+0x6a>
ffffffffc0203e5e:	64e2                	ld	s1,24(sp)
ffffffffc0203e60:	bfe9                	j	ffffffffc0203e3a <user_mem_check+0x68>
ffffffffc0203e62:	80000737          	lui	a4,0x80000
ffffffffc0203e66:	fff74713          	not	a4,a4
ffffffffc0203e6a:	4501                	li	a0,0
ffffffffc0203e6c:	fcb778e3          	bgeu	a4,a1,ffffffffc0203e3c <user_mem_check+0x6a>
ffffffffc0203e70:	962e                	add	a2,a2,a1
ffffffffc0203e72:	00f637b3          	sltu	a5,a2,a5
ffffffffc0203e76:	00c5b633          	sltu	a2,a1,a2
ffffffffc0203e7a:	00c7f533          	and	a0,a5,a2
ffffffffc0203e7e:	bf7d                	j	ffffffffc0203e3c <user_mem_check+0x6a>
ffffffffc0203e80:	64e2                	ld	s1,24(sp)
ffffffffc0203e82:	6942                	ld	s2,16(sp)
ffffffffc0203e84:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203e86:	4505                	li	a0,1
ffffffffc0203e88:	bf55                	j	ffffffffc0203e3c <user_mem_check+0x6a>

ffffffffc0203e8a <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203e8a:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203e8c:	9402                	jalr	s0

	jal do_exit
ffffffffc0203e8e:	624000ef          	jal	ffffffffc02044b2 <do_exit>

ffffffffc0203e92 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203e92:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e94:	14800513          	li	a0,328
{
ffffffffc0203e98:	e022                	sd	s0,0(sp)
ffffffffc0203e9a:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e9c:	e91fd0ef          	jal	ffffffffc0201d2c <kmalloc>
ffffffffc0203ea0:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203ea2:	c93d                	beqz	a0,ffffffffc0203f18 <alloc_proc+0x86>
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;
ffffffffc0203ea4:	57fd                	li	a5,-1
ffffffffc0203ea6:	1782                	slli	a5,a5,0x20
ffffffffc0203ea8:	e11c                	sd	a5,0(a0)
        proc->pid = -1;
        proc->runs = 0;
ffffffffc0203eaa:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0203eae:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0203eb2:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203eb6:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203eba:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0203ebe:	07000613          	li	a2,112
ffffffffc0203ec2:	4581                	li	a1,0
ffffffffc0203ec4:	03050513          	addi	a0,a0,48
ffffffffc0203ec8:	413010ef          	jal	ffffffffc0205ada <memset>
        proc->tf = NULL;
        proc->pgdir = 0;
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203ecc:	0b440513          	addi	a0,s0,180
        proc->tf = NULL;
ffffffffc0203ed0:	0a043023          	sd	zero,160(s0)
        proc->pgdir = 0;
ffffffffc0203ed4:	0a043423          	sd	zero,168(s0)
        proc->flags = 0;
ffffffffc0203ed8:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN + 1);
ffffffffc0203edc:	4641                	li	a2,16
ffffffffc0203ede:	4581                	li	a1,0
ffffffffc0203ee0:	3fb010ef          	jal	ffffffffc0205ada <memset>
         *       skew_heap_entry_t lab6_run_pool;            // entry in the run pool (lab6 stride)
         *       uint32_t lab6_stride;                       // stride value (lab6 stride)
         *       uint32_t lab6_priority;                     // priority value (lab6 stride)
         */
        proc->rq = NULL;
        list_init(&(proc->run_link));
ffffffffc0203ee4:	11040793          	addi	a5,s0,272
        proc->wait_state = 0;
ffffffffc0203ee8:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->yptr = proc->optr = NULL;
ffffffffc0203eec:	10043023          	sd	zero,256(s0)
ffffffffc0203ef0:	0e043c23          	sd	zero,248(s0)
ffffffffc0203ef4:	0e043823          	sd	zero,240(s0)
        proc->rq = NULL;
ffffffffc0203ef8:	10043423          	sd	zero,264(s0)
        proc->time_slice = 0;
ffffffffc0203efc:	12042023          	sw	zero,288(s0)
        proc->lab6_run_pool.left = proc->lab6_run_pool.right = proc->lab6_run_pool.parent = NULL;
ffffffffc0203f00:	12043423          	sd	zero,296(s0)
ffffffffc0203f04:	12043c23          	sd	zero,312(s0)
ffffffffc0203f08:	12043823          	sd	zero,304(s0)
        proc->lab6_stride = 0;
ffffffffc0203f0c:	14043023          	sd	zero,320(s0)
    elm->prev = elm->next = elm;
ffffffffc0203f10:	10f43c23          	sd	a5,280(s0)
ffffffffc0203f14:	10f43823          	sd	a5,272(s0)
        proc->lab6_priority = 0;
    }
    return proc;
}
ffffffffc0203f18:	60a2                	ld	ra,8(sp)
ffffffffc0203f1a:	8522                	mv	a0,s0
ffffffffc0203f1c:	6402                	ld	s0,0(sp)
ffffffffc0203f1e:	0141                	addi	sp,sp,16
ffffffffc0203f20:	8082                	ret

ffffffffc0203f22 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203f22:	000ad797          	auipc	a5,0xad
ffffffffc0203f26:	5f67b783          	ld	a5,1526(a5) # ffffffffc02b1518 <current>
ffffffffc0203f2a:	73c8                	ld	a0,160(a5)
ffffffffc0203f2c:	88efd06f          	j	ffffffffc0200fba <forkrets>

ffffffffc0203f30 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203f30:	6d14                	ld	a3,24(a0)
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm)
{
ffffffffc0203f32:	1141                	addi	sp,sp,-16
ffffffffc0203f34:	e406                	sd	ra,8(sp)
ffffffffc0203f36:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f3a:	02f6ee63          	bltu	a3,a5,ffffffffc0203f76 <put_pgdir+0x46>
ffffffffc0203f3e:	000ad717          	auipc	a4,0xad
ffffffffc0203f42:	5ba73703          	ld	a4,1466(a4) # ffffffffc02b14f8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203f46:	000ad797          	auipc	a5,0xad
ffffffffc0203f4a:	5ba7b783          	ld	a5,1466(a5) # ffffffffc02b1500 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203f4e:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203f50:	82b1                	srli	a3,a3,0xc
ffffffffc0203f52:	02f6fe63          	bgeu	a3,a5,ffffffffc0203f8e <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f56:	00004797          	auipc	a5,0x4
ffffffffc0203f5a:	58a7b783          	ld	a5,1418(a5) # ffffffffc02084e0 <nbase>
ffffffffc0203f5e:	000ad517          	auipc	a0,0xad
ffffffffc0203f62:	5aa53503          	ld	a0,1450(a0) # ffffffffc02b1508 <pages>
    free_page(kva2page(mm->pgdir));
}
ffffffffc0203f66:	60a2                	ld	ra,8(sp)
ffffffffc0203f68:	8e9d                	sub	a3,a3,a5
ffffffffc0203f6a:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203f6c:	4585                	li	a1,1
ffffffffc0203f6e:	9536                	add	a0,a0,a3
}
ffffffffc0203f70:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203f72:	fb7fd06f          	j	ffffffffc0201f28 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203f76:	00003617          	auipc	a2,0x3
ffffffffc0203f7a:	a8a60613          	addi	a2,a2,-1398 # ffffffffc0206a00 <etext+0xefc>
ffffffffc0203f7e:	07700593          	li	a1,119
ffffffffc0203f82:	00003517          	auipc	a0,0x3
ffffffffc0203f86:	9fe50513          	addi	a0,a0,-1538 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0203f8a:	d04fc0ef          	jal	ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f8e:	00003617          	auipc	a2,0x3
ffffffffc0203f92:	a9a60613          	addi	a2,a2,-1382 # ffffffffc0206a28 <etext+0xf24>
ffffffffc0203f96:	06900593          	li	a1,105
ffffffffc0203f9a:	00003517          	auipc	a0,0x3
ffffffffc0203f9e:	9e650513          	addi	a0,a0,-1562 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0203fa2:	cecfc0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0203fa6 <proc_run>:
    if (proc != current)
ffffffffc0203fa6:	000ad717          	auipc	a4,0xad
ffffffffc0203faa:	57273703          	ld	a4,1394(a4) # ffffffffc02b1518 <current>
ffffffffc0203fae:	02a70863          	beq	a4,a0,ffffffffc0203fde <proc_run+0x38>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fb2:	100027f3          	csrr	a5,sstatus
ffffffffc0203fb6:	8b89                	andi	a5,a5,2
ffffffffc0203fb8:	e785                	bnez	a5,ffffffffc0203fe0 <proc_run+0x3a>
            if (next->pgdir != 0) {
ffffffffc0203fba:	755c                	ld	a5,168(a0)
            current = proc;
ffffffffc0203fbc:	000ad697          	auipc	a3,0xad
ffffffffc0203fc0:	54a6be23          	sd	a0,1372(a3) # ffffffffc02b1518 <current>
            if (next->pgdir != 0) {
ffffffffc0203fc4:	c799                	beqz	a5,ffffffffc0203fd2 <proc_run+0x2c>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203fc6:	56fd                	li	a3,-1
ffffffffc0203fc8:	16fe                	slli	a3,a3,0x3f
ffffffffc0203fca:	83b1                	srli	a5,a5,0xc
ffffffffc0203fcc:	8fd5                	or	a5,a5,a3
ffffffffc0203fce:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0203fd2:	03050593          	addi	a1,a0,48
ffffffffc0203fd6:	03070513          	addi	a0,a4,48
ffffffffc0203fda:	1f40106f          	j	ffffffffc02051ce <switch_to>
ffffffffc0203fde:	8082                	ret
{
ffffffffc0203fe0:	1101                	addi	sp,sp,-32
ffffffffc0203fe2:	e43a                	sd	a4,8(sp)
ffffffffc0203fe4:	e02a                	sd	a0,0(sp)
ffffffffc0203fe6:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0203fe8:	a15fc0ef          	jal	ffffffffc02009fc <intr_disable>
            if (next->pgdir != 0) {
ffffffffc0203fec:	6502                	ld	a0,0(sp)
ffffffffc0203fee:	6722                	ld	a4,8(sp)
ffffffffc0203ff0:	755c                	ld	a5,168(a0)
            current = proc;
ffffffffc0203ff2:	000ad697          	auipc	a3,0xad
ffffffffc0203ff6:	52a6b323          	sd	a0,1318(a3) # ffffffffc02b1518 <current>
            if (next->pgdir != 0) {
ffffffffc0203ffa:	c799                	beqz	a5,ffffffffc0204008 <proc_run+0x62>
ffffffffc0203ffc:	56fd                	li	a3,-1
ffffffffc0203ffe:	16fe                	slli	a3,a3,0x3f
ffffffffc0204000:	83b1                	srli	a5,a5,0xc
ffffffffc0204002:	8fd5                	or	a5,a5,a3
ffffffffc0204004:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0204008:	03050593          	addi	a1,a0,48
ffffffffc020400c:	03070513          	addi	a0,a4,48
ffffffffc0204010:	1be010ef          	jal	ffffffffc02051ce <switch_to>
}
ffffffffc0204014:	60e2                	ld	ra,24(sp)
ffffffffc0204016:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204018:	9dffc06f          	j	ffffffffc02009f6 <intr_enable>

ffffffffc020401c <do_fork>:
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
ffffffffc020401c:	000ad717          	auipc	a4,0xad
ffffffffc0204020:	4f472703          	lw	a4,1268(a4) # ffffffffc02b1510 <nr_process>
ffffffffc0204024:	6785                	lui	a5,0x1
ffffffffc0204026:	36f75d63          	bge	a4,a5,ffffffffc02043a0 <do_fork+0x384>
{
ffffffffc020402a:	711d                	addi	sp,sp,-96
ffffffffc020402c:	e8a2                	sd	s0,80(sp)
ffffffffc020402e:	e4a6                	sd	s1,72(sp)
ffffffffc0204030:	e0ca                	sd	s2,64(sp)
ffffffffc0204032:	e06a                	sd	s10,0(sp)
ffffffffc0204034:	ec86                	sd	ra,88(sp)
ffffffffc0204036:	892e                	mv	s2,a1
ffffffffc0204038:	84b2                	mv	s1,a2
ffffffffc020403a:	8d2a                	mv	s10,a0
     *    update step 1: set child proc's parent to current process, make sure current process's wait_state is 0
     *    update step 5: insert proc_struct into hash_list && proc_list, set the relation links of process
     */

    // 1. alloc_proc
    if ((proc = alloc_proc()) == NULL) {
ffffffffc020403c:	e57ff0ef          	jal	ffffffffc0203e92 <alloc_proc>
ffffffffc0204040:	842a                	mv	s0,a0
ffffffffc0204042:	30050063          	beqz	a0,ffffffffc0204342 <do_fork+0x326>
        goto fork_out;
    }
    // 2. set parent and check wait_state
    proc->parent = current;
ffffffffc0204046:	f05a                	sd	s6,32(sp)
ffffffffc0204048:	000adb17          	auipc	s6,0xad
ffffffffc020404c:	4d0b0b13          	addi	s6,s6,1232 # ffffffffc02b1518 <current>
ffffffffc0204050:	000b3783          	ld	a5,0(s6)
    assert(current->wait_state == 0);
ffffffffc0204054:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_softint_out_size-0x7e34>
    proc->parent = current;
ffffffffc0204058:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);
ffffffffc020405a:	3c071263          	bnez	a4,ffffffffc020441e <do_fork+0x402>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020405e:	4509                	li	a0,2
ffffffffc0204060:	e8ffd0ef          	jal	ffffffffc0201eee <alloc_pages>
    if (page != NULL)
ffffffffc0204064:	2c050b63          	beqz	a0,ffffffffc020433a <do_fork+0x31e>
ffffffffc0204068:	fc4e                	sd	s3,56(sp)
    return page - pages + nbase;
ffffffffc020406a:	000ad997          	auipc	s3,0xad
ffffffffc020406e:	49e98993          	addi	s3,s3,1182 # ffffffffc02b1508 <pages>
ffffffffc0204072:	0009b783          	ld	a5,0(s3)
ffffffffc0204076:	f852                	sd	s4,48(sp)
ffffffffc0204078:	00004a17          	auipc	s4,0x4
ffffffffc020407c:	468a0a13          	addi	s4,s4,1128 # ffffffffc02084e0 <nbase>
ffffffffc0204080:	e466                	sd	s9,8(sp)
ffffffffc0204082:	000a3c83          	ld	s9,0(s4)
ffffffffc0204086:	40f506b3          	sub	a3,a0,a5
ffffffffc020408a:	f456                	sd	s5,40(sp)
    return KADDR(page2pa(page));
ffffffffc020408c:	000ada97          	auipc	s5,0xad
ffffffffc0204090:	474a8a93          	addi	s5,s5,1140 # ffffffffc02b1500 <npage>
ffffffffc0204094:	e862                	sd	s8,16(sp)
    return page - pages + nbase;
ffffffffc0204096:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204098:	5c7d                	li	s8,-1
ffffffffc020409a:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc020409e:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc02040a0:	00cc5c13          	srli	s8,s8,0xc
ffffffffc02040a4:	0186f733          	and	a4,a3,s8
ffffffffc02040a8:	ec5e                	sd	s7,24(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc02040aa:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02040ac:	30f77863          	bgeu	a4,a5,ffffffffc02043bc <do_fork+0x3a0>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02040b0:	000b3703          	ld	a4,0(s6)
ffffffffc02040b4:	000adb17          	auipc	s6,0xad
ffffffffc02040b8:	444b0b13          	addi	s6,s6,1092 # ffffffffc02b14f8 <va_pa_offset>
ffffffffc02040bc:	000b3783          	ld	a5,0(s6)
ffffffffc02040c0:	02873b83          	ld	s7,40(a4)
ffffffffc02040c4:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02040c6:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc02040c8:	020b8863          	beqz	s7,ffffffffc02040f8 <do_fork+0xdc>
    if (clone_flags & CLONE_VM)
ffffffffc02040cc:	100d7793          	andi	a5,s10,256
ffffffffc02040d0:	18078b63          	beqz	a5,ffffffffc0204266 <do_fork+0x24a>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02040d4:	030ba703          	lw	a4,48(s7)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040d8:	018bb783          	ld	a5,24(s7)
ffffffffc02040dc:	c02006b7          	lui	a3,0xc0200
ffffffffc02040e0:	2705                	addiw	a4,a4,1
ffffffffc02040e2:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc02040e6:	03743423          	sd	s7,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040ea:	2ed7e563          	bltu	a5,a3,ffffffffc02043d4 <do_fork+0x3b8>
ffffffffc02040ee:	000b3703          	ld	a4,0(s6)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040f2:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040f4:	8f99                	sub	a5,a5,a4
ffffffffc02040f6:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040f8:	6789                	lui	a5,0x2
ffffffffc02040fa:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x7040>
ffffffffc02040fe:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0204100:	8626                	mv	a2,s1
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0204102:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0204104:	87b6                	mv	a5,a3
ffffffffc0204106:	12048713          	addi	a4,s1,288
ffffffffc020410a:	6a0c                	ld	a1,16(a2)
ffffffffc020410c:	00063803          	ld	a6,0(a2)
ffffffffc0204110:	6608                	ld	a0,8(a2)
ffffffffc0204112:	eb8c                	sd	a1,16(a5)
ffffffffc0204114:	0107b023          	sd	a6,0(a5)
ffffffffc0204118:	e788                	sd	a0,8(a5)
ffffffffc020411a:	6e0c                	ld	a1,24(a2)
ffffffffc020411c:	02060613          	addi	a2,a2,32
ffffffffc0204120:	02078793          	addi	a5,a5,32
ffffffffc0204124:	feb7bc23          	sd	a1,-8(a5)
ffffffffc0204128:	fee611e3          	bne	a2,a4,ffffffffc020410a <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc020412c:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_entry+0x50>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204130:	20090b63          	beqz	s2,ffffffffc0204346 <do_fork+0x32a>
ffffffffc0204134:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204138:	00000797          	auipc	a5,0x0
ffffffffc020413c:	dea78793          	addi	a5,a5,-534 # ffffffffc0203f22 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204140:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204142:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204144:	100027f3          	csrr	a5,sstatus
ffffffffc0204148:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020414a:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020414c:	20079c63          	bnez	a5,ffffffffc0204364 <do_fork+0x348>
    if (++last_pid >= MAX_PID)
ffffffffc0204150:	000ad517          	auipc	a0,0xad
ffffffffc0204154:	f4452503          	lw	a0,-188(a0) # ffffffffc02b1094 <last_pid.1>
ffffffffc0204158:	6789                	lui	a5,0x2
ffffffffc020415a:	2505                	addiw	a0,a0,1
ffffffffc020415c:	000ad717          	auipc	a4,0xad
ffffffffc0204160:	f2a72c23          	sw	a0,-200(a4) # ffffffffc02b1094 <last_pid.1>
ffffffffc0204164:	20f55f63          	bge	a0,a5,ffffffffc0204382 <do_fork+0x366>
    if (last_pid >= next_safe)
ffffffffc0204168:	000ad797          	auipc	a5,0xad
ffffffffc020416c:	f287a783          	lw	a5,-216(a5) # ffffffffc02b1090 <next_safe.0>
ffffffffc0204170:	000b1497          	auipc	s1,0xb1
ffffffffc0204174:	3c048493          	addi	s1,s1,960 # ffffffffc02b5530 <proc_list>
ffffffffc0204178:	06f54563          	blt	a0,a5,ffffffffc02041e2 <do_fork+0x1c6>
    return listelm->next;
ffffffffc020417c:	000b1497          	auipc	s1,0xb1
ffffffffc0204180:	3b448493          	addi	s1,s1,948 # ffffffffc02b5530 <proc_list>
ffffffffc0204184:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc0204188:	6789                	lui	a5,0x2
ffffffffc020418a:	000ad717          	auipc	a4,0xad
ffffffffc020418e:	f0f72323          	sw	a5,-250(a4) # ffffffffc02b1090 <next_safe.0>
ffffffffc0204192:	86aa                	mv	a3,a0
ffffffffc0204194:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204196:	04988063          	beq	a7,s1,ffffffffc02041d6 <do_fork+0x1ba>
ffffffffc020419a:	882e                	mv	a6,a1
ffffffffc020419c:	87c6                	mv	a5,a7
ffffffffc020419e:	6609                	lui	a2,0x2
ffffffffc02041a0:	a811                	j	ffffffffc02041b4 <do_fork+0x198>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041a2:	00e6d663          	bge	a3,a4,ffffffffc02041ae <do_fork+0x192>
ffffffffc02041a6:	00c75463          	bge	a4,a2,ffffffffc02041ae <do_fork+0x192>
                next_safe = proc->pid;
ffffffffc02041aa:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041ac:	4805                	li	a6,1
ffffffffc02041ae:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02041b0:	00978d63          	beq	a5,s1,ffffffffc02041ca <do_fork+0x1ae>
            if (proc->pid == last_pid)
ffffffffc02041b4:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x6fe4>
ffffffffc02041b8:	fed715e3          	bne	a4,a3,ffffffffc02041a2 <do_fork+0x186>
                if (++last_pid >= next_safe)
ffffffffc02041bc:	2685                	addiw	a3,a3,1
ffffffffc02041be:	1cc6db63          	bge	a3,a2,ffffffffc0204394 <do_fork+0x378>
ffffffffc02041c2:	679c                	ld	a5,8(a5)
ffffffffc02041c4:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc02041c6:	fe9797e3          	bne	a5,s1,ffffffffc02041b4 <do_fork+0x198>
ffffffffc02041ca:	00080663          	beqz	a6,ffffffffc02041d6 <do_fork+0x1ba>
ffffffffc02041ce:	000ad797          	auipc	a5,0xad
ffffffffc02041d2:	ecc7a123          	sw	a2,-318(a5) # ffffffffc02b1090 <next_safe.0>
ffffffffc02041d6:	c591                	beqz	a1,ffffffffc02041e2 <do_fork+0x1c6>
ffffffffc02041d8:	000ad797          	auipc	a5,0xad
ffffffffc02041dc:	ead7ae23          	sw	a3,-324(a5) # ffffffffc02b1094 <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041e0:	8536                	mv	a0,a3

    // 6. insert into hash_list and proc_list, set links
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        proc->pid = get_pid();
ffffffffc02041e2:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02041e4:	45a9                	li	a1,10
ffffffffc02041e6:	45e010ef          	jal	ffffffffc0205644 <hash32>
ffffffffc02041ea:	02051793          	slli	a5,a0,0x20
ffffffffc02041ee:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02041f2:	000ad797          	auipc	a5,0xad
ffffffffc02041f6:	33e78793          	addi	a5,a5,830 # ffffffffc02b1530 <hash_list>
ffffffffc02041fa:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02041fc:	6518                	ld	a4,8(a0)
ffffffffc02041fe:	0d840793          	addi	a5,s0,216
ffffffffc0204202:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc0204204:	e31c                	sd	a5,0(a4)
ffffffffc0204206:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc0204208:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc020420a:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc020420e:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc0204210:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc0204212:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc0204214:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc0204218:	7b74                	ld	a3,240(a4)
ffffffffc020421a:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc020421c:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc020421e:	e464                	sd	s1,200(s0)
ffffffffc0204220:	10d43023          	sd	a3,256(s0)
ffffffffc0204224:	c299                	beqz	a3,ffffffffc020422a <do_fork+0x20e>
        proc->optr->yptr = proc;
ffffffffc0204226:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc0204228:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc020422a:	000ad797          	auipc	a5,0xad
ffffffffc020422e:	2e67a783          	lw	a5,742(a5) # ffffffffc02b1510 <nr_process>
    proc->parent->cptr = proc;
ffffffffc0204232:	fb60                	sd	s0,240(a4)
    nr_process++;
ffffffffc0204234:	2785                	addiw	a5,a5,1
ffffffffc0204236:	000ad717          	auipc	a4,0xad
ffffffffc020423a:	2cf72d23          	sw	a5,730(a4) # ffffffffc02b1510 <nr_process>
    if (flag)
ffffffffc020423e:	14091863          	bnez	s2,ffffffffc020438e <do_fork+0x372>
        set_links(proc);
    }
    local_intr_restore(intr_flag);

    // 7. wakeup_proc
    wakeup_proc(proc);
ffffffffc0204242:	8522                	mv	a0,s0
ffffffffc0204244:	156010ef          	jal	ffffffffc020539a <wakeup_proc>

    // 8. set return value
    ret = proc->pid;
ffffffffc0204248:	4048                	lw	a0,4(s0)
ffffffffc020424a:	79e2                	ld	s3,56(sp)
ffffffffc020424c:	7a42                	ld	s4,48(sp)
ffffffffc020424e:	7aa2                	ld	s5,40(sp)
ffffffffc0204250:	7b02                	ld	s6,32(sp)
ffffffffc0204252:	6be2                	ld	s7,24(sp)
ffffffffc0204254:	6c42                	ld	s8,16(sp)
ffffffffc0204256:	6ca2                	ld	s9,8(sp)
bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}
ffffffffc0204258:	60e6                	ld	ra,88(sp)
ffffffffc020425a:	6446                	ld	s0,80(sp)
ffffffffc020425c:	64a6                	ld	s1,72(sp)
ffffffffc020425e:	6906                	ld	s2,64(sp)
ffffffffc0204260:	6d02                	ld	s10,0(sp)
ffffffffc0204262:	6125                	addi	sp,sp,96
ffffffffc0204264:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc0204266:	ce0ff0ef          	jal	ffffffffc0203746 <mm_create>
ffffffffc020426a:	8d2a                	mv	s10,a0
ffffffffc020426c:	c949                	beqz	a0,ffffffffc02042fe <do_fork+0x2e2>
    if ((page = alloc_page()) == NULL)
ffffffffc020426e:	4505                	li	a0,1
ffffffffc0204270:	c7ffd0ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc0204274:	c151                	beqz	a0,ffffffffc02042f8 <do_fork+0x2dc>
    return page - pages + nbase;
ffffffffc0204276:	0009b703          	ld	a4,0(s3)
    return KADDR(page2pa(page));
ffffffffc020427a:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc020427e:	40e506b3          	sub	a3,a0,a4
ffffffffc0204282:	8699                	srai	a3,a3,0x6
ffffffffc0204284:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc0204286:	0186fc33          	and	s8,a3,s8
    return page2ppn(page) << PGSHIFT;
ffffffffc020428a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020428c:	1afc7f63          	bgeu	s8,a5,ffffffffc020444a <do_fork+0x42e>
ffffffffc0204290:	000b3783          	ld	a5,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204294:	000ad597          	auipc	a1,0xad
ffffffffc0204298:	25c5b583          	ld	a1,604(a1) # ffffffffc02b14f0 <boot_pgdir_va>
ffffffffc020429c:	6605                	lui	a2,0x1
ffffffffc020429e:	00f68c33          	add	s8,a3,a5
ffffffffc02042a2:	8562                	mv	a0,s8
ffffffffc02042a4:	049010ef          	jal	ffffffffc0205aec <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc02042a8:	038b8c93          	addi	s9,s7,56
    mm->pgdir = pgdir;
ffffffffc02042ac:	018d3c23          	sd	s8,24(s10) # fffffffffff80018 <boot_dtb+0x3fccaa90>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02042b0:	4c05                	li	s8,1
ffffffffc02042b2:	418cb7af          	amoor.d	a5,s8,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc02042b6:	03f79713          	slli	a4,a5,0x3f
ffffffffc02042ba:	03f75793          	srli	a5,a4,0x3f
ffffffffc02042be:	cb91                	beqz	a5,ffffffffc02042d2 <do_fork+0x2b6>
    {
        schedule();
ffffffffc02042c0:	1d2010ef          	jal	ffffffffc0205492 <schedule>
ffffffffc02042c4:	418cb7af          	amoor.d	a5,s8,(s9)
    while (!try_lock(lock))
ffffffffc02042c8:	03f79713          	slli	a4,a5,0x3f
ffffffffc02042cc:	03f75793          	srli	a5,a4,0x3f
ffffffffc02042d0:	fbe5                	bnez	a5,ffffffffc02042c0 <do_fork+0x2a4>
        ret = dup_mmap(mm, oldmm);
ffffffffc02042d2:	85de                	mv	a1,s7
ffffffffc02042d4:	856a                	mv	a0,s10
ffffffffc02042d6:	eccff0ef          	jal	ffffffffc02039a2 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02042da:	57f9                	li	a5,-2
ffffffffc02042dc:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc02042e0:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc02042e2:	12078263          	beqz	a5,ffffffffc0204406 <do_fork+0x3ea>
    if ((mm = mm_create()) == NULL)
ffffffffc02042e6:	8bea                	mv	s7,s10
    if (ret != 0)
ffffffffc02042e8:	de0506e3          	beqz	a0,ffffffffc02040d4 <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc02042ec:	856a                	mv	a0,s10
ffffffffc02042ee:	f4cff0ef          	jal	ffffffffc0203a3a <exit_mmap>
    put_pgdir(mm);
ffffffffc02042f2:	856a                	mv	a0,s10
ffffffffc02042f4:	c3dff0ef          	jal	ffffffffc0203f30 <put_pgdir>
    mm_destroy(mm);
ffffffffc02042f8:	856a                	mv	a0,s10
ffffffffc02042fa:	d8aff0ef          	jal	ffffffffc0203884 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02042fe:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc0204300:	c02007b7          	lui	a5,0xc0200
ffffffffc0204304:	0ef6e563          	bltu	a3,a5,ffffffffc02043ee <do_fork+0x3d2>
ffffffffc0204308:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage)
ffffffffc020430c:	000ab703          	ld	a4,0(s5)
    return pa2page(PADDR(kva));
ffffffffc0204310:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc0204314:	83b1                	srli	a5,a5,0xc
ffffffffc0204316:	08e7f763          	bgeu	a5,a4,ffffffffc02043a4 <do_fork+0x388>
    return &pages[PPN(pa) - nbase];
ffffffffc020431a:	000a3703          	ld	a4,0(s4)
ffffffffc020431e:	0009b503          	ld	a0,0(s3)
ffffffffc0204322:	4589                	li	a1,2
ffffffffc0204324:	8f99                	sub	a5,a5,a4
ffffffffc0204326:	079a                	slli	a5,a5,0x6
ffffffffc0204328:	953e                	add	a0,a0,a5
ffffffffc020432a:	bfffd0ef          	jal	ffffffffc0201f28 <free_pages>
}
ffffffffc020432e:	79e2                	ld	s3,56(sp)
ffffffffc0204330:	7a42                	ld	s4,48(sp)
ffffffffc0204332:	7aa2                	ld	s5,40(sp)
ffffffffc0204334:	6be2                	ld	s7,24(sp)
ffffffffc0204336:	6c42                	ld	s8,16(sp)
ffffffffc0204338:	6ca2                	ld	s9,8(sp)
    kfree(proc);
ffffffffc020433a:	8522                	mv	a0,s0
ffffffffc020433c:	a97fd0ef          	jal	ffffffffc0201dd2 <kfree>
ffffffffc0204340:	7b02                	ld	s6,32(sp)
    ret = -E_NO_MEM;
ffffffffc0204342:	5571                	li	a0,-4
    return ret;
ffffffffc0204344:	bf11                	j	ffffffffc0204258 <do_fork+0x23c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204346:	8936                	mv	s2,a3
ffffffffc0204348:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020434c:	00000797          	auipc	a5,0x0
ffffffffc0204350:	bd678793          	addi	a5,a5,-1066 # ffffffffc0203f22 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204354:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204356:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204358:	100027f3          	csrr	a5,sstatus
ffffffffc020435c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020435e:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204360:	de0788e3          	beqz	a5,ffffffffc0204150 <do_fork+0x134>
        intr_disable();
ffffffffc0204364:	e98fc0ef          	jal	ffffffffc02009fc <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc0204368:	000ad517          	auipc	a0,0xad
ffffffffc020436c:	d2c52503          	lw	a0,-724(a0) # ffffffffc02b1094 <last_pid.1>
ffffffffc0204370:	6789                	lui	a5,0x2
        return 1;
ffffffffc0204372:	4905                	li	s2,1
ffffffffc0204374:	2505                	addiw	a0,a0,1
ffffffffc0204376:	000ad717          	auipc	a4,0xad
ffffffffc020437a:	d0a72f23          	sw	a0,-738(a4) # ffffffffc02b1094 <last_pid.1>
ffffffffc020437e:	def545e3          	blt	a0,a5,ffffffffc0204168 <do_fork+0x14c>
        last_pid = 1;
ffffffffc0204382:	4505                	li	a0,1
ffffffffc0204384:	000ad797          	auipc	a5,0xad
ffffffffc0204388:	d0a7a823          	sw	a0,-752(a5) # ffffffffc02b1094 <last_pid.1>
        goto inside;
ffffffffc020438c:	bbc5                	j	ffffffffc020417c <do_fork+0x160>
        intr_enable();
ffffffffc020438e:	e68fc0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0204392:	bd45                	j	ffffffffc0204242 <do_fork+0x226>
                    if (last_pid >= MAX_PID)
ffffffffc0204394:	6789                	lui	a5,0x2
ffffffffc0204396:	00f6c363          	blt	a3,a5,ffffffffc020439c <do_fork+0x380>
                        last_pid = 1;
ffffffffc020439a:	4685                	li	a3,1
                    goto repeat;
ffffffffc020439c:	4585                	li	a1,1
ffffffffc020439e:	bbe5                	j	ffffffffc0204196 <do_fork+0x17a>
    int ret = -E_NO_FREE_PROC;
ffffffffc02043a0:	556d                	li	a0,-5
}
ffffffffc02043a2:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc02043a4:	00002617          	auipc	a2,0x2
ffffffffc02043a8:	68460613          	addi	a2,a2,1668 # ffffffffc0206a28 <etext+0xf24>
ffffffffc02043ac:	06900593          	li	a1,105
ffffffffc02043b0:	00002517          	auipc	a0,0x2
ffffffffc02043b4:	5d050513          	addi	a0,a0,1488 # ffffffffc0206980 <etext+0xe7c>
ffffffffc02043b8:	8d6fc0ef          	jal	ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc02043bc:	00002617          	auipc	a2,0x2
ffffffffc02043c0:	59c60613          	addi	a2,a2,1436 # ffffffffc0206958 <etext+0xe54>
ffffffffc02043c4:	07100593          	li	a1,113
ffffffffc02043c8:	00002517          	auipc	a0,0x2
ffffffffc02043cc:	5b850513          	addi	a0,a0,1464 # ffffffffc0206980 <etext+0xe7c>
ffffffffc02043d0:	8befc0ef          	jal	ffffffffc020048e <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02043d4:	86be                	mv	a3,a5
ffffffffc02043d6:	00002617          	auipc	a2,0x2
ffffffffc02043da:	62a60613          	addi	a2,a2,1578 # ffffffffc0206a00 <etext+0xefc>
ffffffffc02043de:	19c00593          	li	a1,412
ffffffffc02043e2:	00003517          	auipc	a0,0x3
ffffffffc02043e6:	f6650513          	addi	a0,a0,-154 # ffffffffc0207348 <etext+0x1844>
ffffffffc02043ea:	8a4fc0ef          	jal	ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02043ee:	00002617          	auipc	a2,0x2
ffffffffc02043f2:	61260613          	addi	a2,a2,1554 # ffffffffc0206a00 <etext+0xefc>
ffffffffc02043f6:	07700593          	li	a1,119
ffffffffc02043fa:	00002517          	auipc	a0,0x2
ffffffffc02043fe:	58650513          	addi	a0,a0,1414 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0204402:	88cfc0ef          	jal	ffffffffc020048e <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc0204406:	00003617          	auipc	a2,0x3
ffffffffc020440a:	f5a60613          	addi	a2,a2,-166 # ffffffffc0207360 <etext+0x185c>
ffffffffc020440e:	04000593          	li	a1,64
ffffffffc0204412:	00003517          	auipc	a0,0x3
ffffffffc0204416:	f5e50513          	addi	a0,a0,-162 # ffffffffc0207370 <etext+0x186c>
ffffffffc020441a:	874fc0ef          	jal	ffffffffc020048e <__panic>
    assert(current->wait_state == 0);
ffffffffc020441e:	00003697          	auipc	a3,0x3
ffffffffc0204422:	f0a68693          	addi	a3,a3,-246 # ffffffffc0207328 <etext+0x1824>
ffffffffc0204426:	00002617          	auipc	a2,0x2
ffffffffc020442a:	18260613          	addi	a2,a2,386 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020442e:	1ed00593          	li	a1,493
ffffffffc0204432:	00003517          	auipc	a0,0x3
ffffffffc0204436:	f1650513          	addi	a0,a0,-234 # ffffffffc0207348 <etext+0x1844>
ffffffffc020443a:	fc4e                	sd	s3,56(sp)
ffffffffc020443c:	f852                	sd	s4,48(sp)
ffffffffc020443e:	f456                	sd	s5,40(sp)
ffffffffc0204440:	ec5e                	sd	s7,24(sp)
ffffffffc0204442:	e862                	sd	s8,16(sp)
ffffffffc0204444:	e466                	sd	s9,8(sp)
ffffffffc0204446:	848fc0ef          	jal	ffffffffc020048e <__panic>
    return KADDR(page2pa(page));
ffffffffc020444a:	00002617          	auipc	a2,0x2
ffffffffc020444e:	50e60613          	addi	a2,a2,1294 # ffffffffc0206958 <etext+0xe54>
ffffffffc0204452:	07100593          	li	a1,113
ffffffffc0204456:	00002517          	auipc	a0,0x2
ffffffffc020445a:	52a50513          	addi	a0,a0,1322 # ffffffffc0206980 <etext+0xe7c>
ffffffffc020445e:	830fc0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0204462 <kernel_thread>:
{
ffffffffc0204462:	7129                	addi	sp,sp,-320
ffffffffc0204464:	fa22                	sd	s0,304(sp)
ffffffffc0204466:	f626                	sd	s1,296(sp)
ffffffffc0204468:	f24a                	sd	s2,288(sp)
ffffffffc020446a:	842a                	mv	s0,a0
ffffffffc020446c:	84ae                	mv	s1,a1
ffffffffc020446e:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204470:	850a                	mv	a0,sp
ffffffffc0204472:	12000613          	li	a2,288
ffffffffc0204476:	4581                	li	a1,0
{
ffffffffc0204478:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020447a:	660010ef          	jal	ffffffffc0205ada <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020447e:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0204480:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204482:	100027f3          	csrr	a5,sstatus
ffffffffc0204486:	edd7f793          	andi	a5,a5,-291
ffffffffc020448a:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020448e:	860a                	mv	a2,sp
ffffffffc0204490:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204494:	00000717          	auipc	a4,0x0
ffffffffc0204498:	9f670713          	addi	a4,a4,-1546 # ffffffffc0203e8a <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020449c:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020449e:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02044a0:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02044a2:	b7bff0ef          	jal	ffffffffc020401c <do_fork>
}
ffffffffc02044a6:	70f2                	ld	ra,312(sp)
ffffffffc02044a8:	7452                	ld	s0,304(sp)
ffffffffc02044aa:	74b2                	ld	s1,296(sp)
ffffffffc02044ac:	7912                	ld	s2,288(sp)
ffffffffc02044ae:	6131                	addi	sp,sp,320
ffffffffc02044b0:	8082                	ret

ffffffffc02044b2 <do_exit>:
// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
ffffffffc02044b2:	7179                	addi	sp,sp,-48
ffffffffc02044b4:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc02044b6:	000ad417          	auipc	s0,0xad
ffffffffc02044ba:	06240413          	addi	s0,s0,98 # ffffffffc02b1518 <current>
ffffffffc02044be:	601c                	ld	a5,0(s0)
ffffffffc02044c0:	000ad717          	auipc	a4,0xad
ffffffffc02044c4:	06873703          	ld	a4,104(a4) # ffffffffc02b1528 <idleproc>
{
ffffffffc02044c8:	f406                	sd	ra,40(sp)
ffffffffc02044ca:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc02044cc:	0ce78b63          	beq	a5,a4,ffffffffc02045a2 <do_exit+0xf0>
    {
        panic("idleproc exit.\n");
    }
    if (current == initproc)
ffffffffc02044d0:	000ad497          	auipc	s1,0xad
ffffffffc02044d4:	05048493          	addi	s1,s1,80 # ffffffffc02b1520 <initproc>
ffffffffc02044d8:	6098                	ld	a4,0(s1)
ffffffffc02044da:	e84a                	sd	s2,16(sp)
ffffffffc02044dc:	0ee78a63          	beq	a5,a4,ffffffffc02045d0 <do_exit+0x11e>
ffffffffc02044e0:	892a                	mv	s2,a0
    {
        panic("initproc exit.\n");
    }
    struct mm_struct *mm = current->mm;
ffffffffc02044e2:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc02044e4:	c115                	beqz	a0,ffffffffc0204508 <do_exit+0x56>
ffffffffc02044e6:	000ad797          	auipc	a5,0xad
ffffffffc02044ea:	0027b783          	ld	a5,2(a5) # ffffffffc02b14e8 <boot_pgdir_pa>
ffffffffc02044ee:	577d                	li	a4,-1
ffffffffc02044f0:	177e                	slli	a4,a4,0x3f
ffffffffc02044f2:	83b1                	srli	a5,a5,0xc
ffffffffc02044f4:	8fd9                	or	a5,a5,a4
ffffffffc02044f6:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02044fa:	591c                	lw	a5,48(a0)
ffffffffc02044fc:	37fd                	addiw	a5,a5,-1
ffffffffc02044fe:	d91c                	sw	a5,48(a0)
    {
        lsatp(boot_pgdir_pa);
        if (mm_count_dec(mm) == 0)
ffffffffc0204500:	cfd5                	beqz	a5,ffffffffc02045bc <do_exit+0x10a>
        {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);
        }
        current->mm = NULL;
ffffffffc0204502:	601c                	ld	a5,0(s0)
ffffffffc0204504:	0207b423          	sd	zero,40(a5)
    }
    current->state = PROC_ZOMBIE;
ffffffffc0204508:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc020450a:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020450e:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204510:	100027f3          	csrr	a5,sstatus
ffffffffc0204514:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204516:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204518:	ebe1                	bnez	a5,ffffffffc02045e8 <do_exit+0x136>
    bool intr_flag;
    struct proc_struct *proc;
    local_intr_save(intr_flag);
    {
        proc = current->parent;
ffffffffc020451a:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc020451c:	800007b7          	lui	a5,0x80000
ffffffffc0204520:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ad9>
        proc = current->parent;
ffffffffc0204522:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc0204524:	0ec52703          	lw	a4,236(a0)
ffffffffc0204528:	0cf70463          	beq	a4,a5,ffffffffc02045f0 <do_exit+0x13e>
        {
            wakeup_proc(proc);
        }
        while (current->cptr != NULL)
ffffffffc020452c:	6018                	ld	a4,0(s0)
            }
            proc->parent = initproc;
            initproc->cptr = proc;
            if (proc->state == PROC_ZOMBIE)
            {
                if (initproc->wait_state == WT_CHILD)
ffffffffc020452e:	800005b7          	lui	a1,0x80000
ffffffffc0204532:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ad9>
        while (current->cptr != NULL)
ffffffffc0204534:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204536:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc0204538:	e789                	bnez	a5,ffffffffc0204542 <do_exit+0x90>
ffffffffc020453a:	a83d                	j	ffffffffc0204578 <do_exit+0xc6>
ffffffffc020453c:	6018                	ld	a4,0(s0)
ffffffffc020453e:	7b7c                	ld	a5,240(a4)
ffffffffc0204540:	cf85                	beqz	a5,ffffffffc0204578 <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc0204542:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204546:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204548:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc020454a:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020454e:	7978                	ld	a4,240(a0)
ffffffffc0204550:	10e7b023          	sd	a4,256(a5)
ffffffffc0204554:	c311                	beqz	a4,ffffffffc0204558 <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc0204556:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204558:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020455a:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020455c:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020455e:	fcc71fe3          	bne	a4,a2,ffffffffc020453c <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204562:	0ec52783          	lw	a5,236(a0)
ffffffffc0204566:	fcb79be3          	bne	a5,a1,ffffffffc020453c <do_exit+0x8a>
                {
                    wakeup_proc(initproc);
ffffffffc020456a:	631000ef          	jal	ffffffffc020539a <wakeup_proc>
ffffffffc020456e:	800005b7          	lui	a1,0x80000
ffffffffc0204572:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ad9>
ffffffffc0204574:	460d                	li	a2,3
ffffffffc0204576:	b7d9                	j	ffffffffc020453c <do_exit+0x8a>
    if (flag)
ffffffffc0204578:	02091263          	bnez	s2,ffffffffc020459c <do_exit+0xea>
                }
            }
        }
    }
    local_intr_restore(intr_flag);
    schedule();
ffffffffc020457c:	717000ef          	jal	ffffffffc0205492 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc0204580:	601c                	ld	a5,0(s0)
ffffffffc0204582:	00003617          	auipc	a2,0x3
ffffffffc0204586:	e2660613          	addi	a2,a2,-474 # ffffffffc02073a8 <etext+0x18a4>
ffffffffc020458a:	25200593          	li	a1,594
ffffffffc020458e:	43d4                	lw	a3,4(a5)
ffffffffc0204590:	00003517          	auipc	a0,0x3
ffffffffc0204594:	db850513          	addi	a0,a0,-584 # ffffffffc0207348 <etext+0x1844>
ffffffffc0204598:	ef7fb0ef          	jal	ffffffffc020048e <__panic>
        intr_enable();
ffffffffc020459c:	c5afc0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc02045a0:	bff1                	j	ffffffffc020457c <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc02045a2:	00003617          	auipc	a2,0x3
ffffffffc02045a6:	de660613          	addi	a2,a2,-538 # ffffffffc0207388 <etext+0x1884>
ffffffffc02045aa:	21e00593          	li	a1,542
ffffffffc02045ae:	00003517          	auipc	a0,0x3
ffffffffc02045b2:	d9a50513          	addi	a0,a0,-614 # ffffffffc0207348 <etext+0x1844>
ffffffffc02045b6:	e84a                	sd	s2,16(sp)
ffffffffc02045b8:	ed7fb0ef          	jal	ffffffffc020048e <__panic>
            exit_mmap(mm);
ffffffffc02045bc:	e42a                	sd	a0,8(sp)
ffffffffc02045be:	c7cff0ef          	jal	ffffffffc0203a3a <exit_mmap>
            put_pgdir(mm);
ffffffffc02045c2:	6522                	ld	a0,8(sp)
ffffffffc02045c4:	96dff0ef          	jal	ffffffffc0203f30 <put_pgdir>
            mm_destroy(mm);
ffffffffc02045c8:	6522                	ld	a0,8(sp)
ffffffffc02045ca:	abaff0ef          	jal	ffffffffc0203884 <mm_destroy>
ffffffffc02045ce:	bf15                	j	ffffffffc0204502 <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc02045d0:	00003617          	auipc	a2,0x3
ffffffffc02045d4:	dc860613          	addi	a2,a2,-568 # ffffffffc0207398 <etext+0x1894>
ffffffffc02045d8:	22200593          	li	a1,546
ffffffffc02045dc:	00003517          	auipc	a0,0x3
ffffffffc02045e0:	d6c50513          	addi	a0,a0,-660 # ffffffffc0207348 <etext+0x1844>
ffffffffc02045e4:	eabfb0ef          	jal	ffffffffc020048e <__panic>
        intr_disable();
ffffffffc02045e8:	c14fc0ef          	jal	ffffffffc02009fc <intr_disable>
        return 1;
ffffffffc02045ec:	4905                	li	s2,1
ffffffffc02045ee:	b735                	j	ffffffffc020451a <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc02045f0:	5ab000ef          	jal	ffffffffc020539a <wakeup_proc>
ffffffffc02045f4:	bf25                	j	ffffffffc020452c <do_exit+0x7a>

ffffffffc02045f6 <do_wait.part.0>:
}

// do_wait - wait one OR any children with PROC_ZOMBIE state, and free memory space of kernel stack
//         - proc struct of this child.
// NOTE: only after do_wait function, all resources of the child proces are free.
int do_wait(int pid, int *code_store)
ffffffffc02045f6:	7179                	addi	sp,sp,-48
ffffffffc02045f8:	ec26                	sd	s1,24(sp)
ffffffffc02045fa:	e84a                	sd	s2,16(sp)
ffffffffc02045fc:	e44e                	sd	s3,8(sp)
ffffffffc02045fe:	f406                	sd	ra,40(sp)
ffffffffc0204600:	f022                	sd	s0,32(sp)
ffffffffc0204602:	84aa                	mv	s1,a0
ffffffffc0204604:	892e                	mv	s2,a1
ffffffffc0204606:	000ad997          	auipc	s3,0xad
ffffffffc020460a:	f1298993          	addi	s3,s3,-238 # ffffffffc02b1518 <current>

    struct proc_struct *proc;
    bool intr_flag, haskid;
repeat:
    haskid = 0;
    if (pid != 0)
ffffffffc020460e:	cd19                	beqz	a0,ffffffffc020462c <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204610:	6789                	lui	a5,0x2
ffffffffc0204612:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f22>
ffffffffc0204614:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204618:	12e7f563          	bgeu	a5,a4,ffffffffc0204742 <do_wait.part.0+0x14c>
    }
    local_intr_restore(intr_flag);
    put_kstack(proc);
    kfree(proc);
    return 0;
}
ffffffffc020461c:	70a2                	ld	ra,40(sp)
ffffffffc020461e:	7402                	ld	s0,32(sp)
ffffffffc0204620:	64e2                	ld	s1,24(sp)
ffffffffc0204622:	6942                	ld	s2,16(sp)
ffffffffc0204624:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc0204626:	5579                	li	a0,-2
}
ffffffffc0204628:	6145                	addi	sp,sp,48
ffffffffc020462a:	8082                	ret
        proc = current->cptr;
ffffffffc020462c:	0009b703          	ld	a4,0(s3)
ffffffffc0204630:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204632:	d46d                	beqz	s0,ffffffffc020461c <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204634:	468d                	li	a3,3
ffffffffc0204636:	a021                	j	ffffffffc020463e <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204638:	10043403          	ld	s0,256(s0)
ffffffffc020463c:	c075                	beqz	s0,ffffffffc0204720 <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020463e:	401c                	lw	a5,0(s0)
ffffffffc0204640:	fed79ce3          	bne	a5,a3,ffffffffc0204638 <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc0204644:	000ad797          	auipc	a5,0xad
ffffffffc0204648:	ee47b783          	ld	a5,-284(a5) # ffffffffc02b1528 <idleproc>
ffffffffc020464c:	14878263          	beq	a5,s0,ffffffffc0204790 <do_wait.part.0+0x19a>
ffffffffc0204650:	000ad797          	auipc	a5,0xad
ffffffffc0204654:	ed07b783          	ld	a5,-304(a5) # ffffffffc02b1520 <initproc>
ffffffffc0204658:	12f40c63          	beq	s0,a5,ffffffffc0204790 <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc020465c:	00090663          	beqz	s2,ffffffffc0204668 <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc0204660:	0e842783          	lw	a5,232(s0)
ffffffffc0204664:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204668:	100027f3          	csrr	a5,sstatus
ffffffffc020466c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020466e:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204670:	10079963          	bnez	a5,ffffffffc0204782 <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204674:	6c74                	ld	a3,216(s0)
ffffffffc0204676:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc0204678:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc020467c:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020467e:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0204680:	6474                	ld	a3,200(s0)
ffffffffc0204682:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc0204684:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204686:	e314                	sd	a3,0(a4)
ffffffffc0204688:	c789                	beqz	a5,ffffffffc0204692 <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc020468a:	7c78                	ld	a4,248(s0)
ffffffffc020468c:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc020468e:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc0204692:	7c78                	ld	a4,248(s0)
ffffffffc0204694:	c36d                	beqz	a4,ffffffffc0204776 <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc0204696:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc020469a:	000ad797          	auipc	a5,0xad
ffffffffc020469e:	e767a783          	lw	a5,-394(a5) # ffffffffc02b1510 <nr_process>
ffffffffc02046a2:	37fd                	addiw	a5,a5,-1
ffffffffc02046a4:	000ad717          	auipc	a4,0xad
ffffffffc02046a8:	e6f72623          	sw	a5,-404(a4) # ffffffffc02b1510 <nr_process>
    if (flag)
ffffffffc02046ac:	e271                	bnez	a2,ffffffffc0204770 <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02046ae:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02046b0:	c02007b7          	lui	a5,0xc0200
ffffffffc02046b4:	10f6e663          	bltu	a3,a5,ffffffffc02047c0 <do_wait.part.0+0x1ca>
ffffffffc02046b8:	000ad717          	auipc	a4,0xad
ffffffffc02046bc:	e4073703          	ld	a4,-448(a4) # ffffffffc02b14f8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc02046c0:	000ad797          	auipc	a5,0xad
ffffffffc02046c4:	e407b783          	ld	a5,-448(a5) # ffffffffc02b1500 <npage>
    return pa2page(PADDR(kva));
ffffffffc02046c8:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc02046ca:	82b1                	srli	a3,a3,0xc
ffffffffc02046cc:	0cf6fe63          	bgeu	a3,a5,ffffffffc02047a8 <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc02046d0:	00004797          	auipc	a5,0x4
ffffffffc02046d4:	e107b783          	ld	a5,-496(a5) # ffffffffc02084e0 <nbase>
ffffffffc02046d8:	000ad517          	auipc	a0,0xad
ffffffffc02046dc:	e3053503          	ld	a0,-464(a0) # ffffffffc02b1508 <pages>
ffffffffc02046e0:	4589                	li	a1,2
ffffffffc02046e2:	8e9d                	sub	a3,a3,a5
ffffffffc02046e4:	069a                	slli	a3,a3,0x6
ffffffffc02046e6:	9536                	add	a0,a0,a3
ffffffffc02046e8:	841fd0ef          	jal	ffffffffc0201f28 <free_pages>
    kfree(proc);
ffffffffc02046ec:	8522                	mv	a0,s0
ffffffffc02046ee:	ee4fd0ef          	jal	ffffffffc0201dd2 <kfree>
}
ffffffffc02046f2:	70a2                	ld	ra,40(sp)
ffffffffc02046f4:	7402                	ld	s0,32(sp)
ffffffffc02046f6:	64e2                	ld	s1,24(sp)
ffffffffc02046f8:	6942                	ld	s2,16(sp)
ffffffffc02046fa:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc02046fc:	4501                	li	a0,0
}
ffffffffc02046fe:	6145                	addi	sp,sp,48
ffffffffc0204700:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc0204702:	000ad997          	auipc	s3,0xad
ffffffffc0204706:	e1698993          	addi	s3,s3,-490 # ffffffffc02b1518 <current>
ffffffffc020470a:	0009b703          	ld	a4,0(s3)
ffffffffc020470e:	f487b683          	ld	a3,-184(a5)
ffffffffc0204712:	f0e695e3          	bne	a3,a4,ffffffffc020461c <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204716:	f287a603          	lw	a2,-216(a5)
ffffffffc020471a:	468d                	li	a3,3
ffffffffc020471c:	06d60063          	beq	a2,a3,ffffffffc020477c <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc0204720:	800007b7          	lui	a5,0x80000
ffffffffc0204724:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_matrix_out_size+0xffffffff7fff4ad9>
        current->state = PROC_SLEEPING;
ffffffffc0204726:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc0204728:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc020472c:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc020472e:	565000ef          	jal	ffffffffc0205492 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204732:	0009b783          	ld	a5,0(s3)
ffffffffc0204736:	0b07a783          	lw	a5,176(a5)
ffffffffc020473a:	8b85                	andi	a5,a5,1
ffffffffc020473c:	e7b9                	bnez	a5,ffffffffc020478a <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc020473e:	ee0487e3          	beqz	s1,ffffffffc020462c <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204742:	45a9                	li	a1,10
ffffffffc0204744:	8526                	mv	a0,s1
ffffffffc0204746:	6ff000ef          	jal	ffffffffc0205644 <hash32>
ffffffffc020474a:	02051793          	slli	a5,a0,0x20
ffffffffc020474e:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204752:	000ad797          	auipc	a5,0xad
ffffffffc0204756:	dde78793          	addi	a5,a5,-546 # ffffffffc02b1530 <hash_list>
ffffffffc020475a:	953e                	add	a0,a0,a5
ffffffffc020475c:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc020475e:	a029                	j	ffffffffc0204768 <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc0204760:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204764:	f8970fe3          	beq	a4,s1,ffffffffc0204702 <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc0204768:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020476a:	fef51be3          	bne	a0,a5,ffffffffc0204760 <do_wait.part.0+0x16a>
ffffffffc020476e:	b57d                	j	ffffffffc020461c <do_wait.part.0+0x26>
        intr_enable();
ffffffffc0204770:	a86fc0ef          	jal	ffffffffc02009f6 <intr_enable>
ffffffffc0204774:	bf2d                	j	ffffffffc02046ae <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc0204776:	7018                	ld	a4,32(s0)
ffffffffc0204778:	fb7c                	sd	a5,240(a4)
ffffffffc020477a:	b705                	j	ffffffffc020469a <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020477c:	f2878413          	addi	s0,a5,-216
ffffffffc0204780:	b5d1                	j	ffffffffc0204644 <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc0204782:	a7afc0ef          	jal	ffffffffc02009fc <intr_disable>
        return 1;
ffffffffc0204786:	4605                	li	a2,1
ffffffffc0204788:	b5f5                	j	ffffffffc0204674 <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc020478a:	555d                	li	a0,-9
ffffffffc020478c:	d27ff0ef          	jal	ffffffffc02044b2 <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc0204790:	00003617          	auipc	a2,0x3
ffffffffc0204794:	c3860613          	addi	a2,a2,-968 # ffffffffc02073c8 <etext+0x18c4>
ffffffffc0204798:	37400593          	li	a1,884
ffffffffc020479c:	00003517          	auipc	a0,0x3
ffffffffc02047a0:	bac50513          	addi	a0,a0,-1108 # ffffffffc0207348 <etext+0x1844>
ffffffffc02047a4:	cebfb0ef          	jal	ffffffffc020048e <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02047a8:	00002617          	auipc	a2,0x2
ffffffffc02047ac:	28060613          	addi	a2,a2,640 # ffffffffc0206a28 <etext+0xf24>
ffffffffc02047b0:	06900593          	li	a1,105
ffffffffc02047b4:	00002517          	auipc	a0,0x2
ffffffffc02047b8:	1cc50513          	addi	a0,a0,460 # ffffffffc0206980 <etext+0xe7c>
ffffffffc02047bc:	cd3fb0ef          	jal	ffffffffc020048e <__panic>
    return pa2page(PADDR(kva));
ffffffffc02047c0:	00002617          	auipc	a2,0x2
ffffffffc02047c4:	24060613          	addi	a2,a2,576 # ffffffffc0206a00 <etext+0xefc>
ffffffffc02047c8:	07700593          	li	a1,119
ffffffffc02047cc:	00002517          	auipc	a0,0x2
ffffffffc02047d0:	1b450513          	addi	a0,a0,436 # ffffffffc0206980 <etext+0xe7c>
ffffffffc02047d4:	cbbfb0ef          	jal	ffffffffc020048e <__panic>

ffffffffc02047d8 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02047d8:	1141                	addi	sp,sp,-16
ffffffffc02047da:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02047dc:	f84fd0ef          	jal	ffffffffc0201f60 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02047e0:	d48fd0ef          	jal	ffffffffc0201d28 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02047e4:	4601                	li	a2,0
ffffffffc02047e6:	4581                	li	a1,0
ffffffffc02047e8:	00000517          	auipc	a0,0x0
ffffffffc02047ec:	6ac50513          	addi	a0,a0,1708 # ffffffffc0204e94 <user_main>
ffffffffc02047f0:	c73ff0ef          	jal	ffffffffc0204462 <kernel_thread>
    if (pid <= 0)
ffffffffc02047f4:	00a04563          	bgtz	a0,ffffffffc02047fe <init_main+0x26>
ffffffffc02047f8:	a071                	j	ffffffffc0204884 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02047fa:	499000ef          	jal	ffffffffc0205492 <schedule>
    if (code_store != NULL)
ffffffffc02047fe:	4581                	li	a1,0
ffffffffc0204800:	4501                	li	a0,0
ffffffffc0204802:	df5ff0ef          	jal	ffffffffc02045f6 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc0204806:	d975                	beqz	a0,ffffffffc02047fa <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc0204808:	00003517          	auipc	a0,0x3
ffffffffc020480c:	c0050513          	addi	a0,a0,-1024 # ffffffffc0207408 <etext+0x1904>
ffffffffc0204810:	9cdfb0ef          	jal	ffffffffc02001dc <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204814:	000ad797          	auipc	a5,0xad
ffffffffc0204818:	d0c7b783          	ld	a5,-756(a5) # ffffffffc02b1520 <initproc>
ffffffffc020481c:	7bf8                	ld	a4,240(a5)
ffffffffc020481e:	e339                	bnez	a4,ffffffffc0204864 <init_main+0x8c>
ffffffffc0204820:	7ff8                	ld	a4,248(a5)
ffffffffc0204822:	e329                	bnez	a4,ffffffffc0204864 <init_main+0x8c>
ffffffffc0204824:	1007b703          	ld	a4,256(a5)
ffffffffc0204828:	ef15                	bnez	a4,ffffffffc0204864 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc020482a:	000ad697          	auipc	a3,0xad
ffffffffc020482e:	ce66a683          	lw	a3,-794(a3) # ffffffffc02b1510 <nr_process>
ffffffffc0204832:	4709                	li	a4,2
ffffffffc0204834:	0ae69463          	bne	a3,a4,ffffffffc02048dc <init_main+0x104>
ffffffffc0204838:	000b1697          	auipc	a3,0xb1
ffffffffc020483c:	cf868693          	addi	a3,a3,-776 # ffffffffc02b5530 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0204840:	6698                	ld	a4,8(a3)
ffffffffc0204842:	0c878793          	addi	a5,a5,200
ffffffffc0204846:	06f71b63          	bne	a4,a5,ffffffffc02048bc <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020484a:	629c                	ld	a5,0(a3)
ffffffffc020484c:	04f71863          	bne	a4,a5,ffffffffc020489c <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc0204850:	00003517          	auipc	a0,0x3
ffffffffc0204854:	ca050513          	addi	a0,a0,-864 # ffffffffc02074f0 <etext+0x19ec>
ffffffffc0204858:	985fb0ef          	jal	ffffffffc02001dc <cprintf>
    return 0;
}
ffffffffc020485c:	60a2                	ld	ra,8(sp)
ffffffffc020485e:	4501                	li	a0,0
ffffffffc0204860:	0141                	addi	sp,sp,16
ffffffffc0204862:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204864:	00003697          	auipc	a3,0x3
ffffffffc0204868:	bcc68693          	addi	a3,a3,-1076 # ffffffffc0207430 <etext+0x192c>
ffffffffc020486c:	00002617          	auipc	a2,0x2
ffffffffc0204870:	d3c60613          	addi	a2,a2,-708 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0204874:	3e000593          	li	a1,992
ffffffffc0204878:	00003517          	auipc	a0,0x3
ffffffffc020487c:	ad050513          	addi	a0,a0,-1328 # ffffffffc0207348 <etext+0x1844>
ffffffffc0204880:	c0ffb0ef          	jal	ffffffffc020048e <__panic>
        panic("create user_main failed.\n");
ffffffffc0204884:	00003617          	auipc	a2,0x3
ffffffffc0204888:	b6460613          	addi	a2,a2,-1180 # ffffffffc02073e8 <etext+0x18e4>
ffffffffc020488c:	3d700593          	li	a1,983
ffffffffc0204890:	00003517          	auipc	a0,0x3
ffffffffc0204894:	ab850513          	addi	a0,a0,-1352 # ffffffffc0207348 <etext+0x1844>
ffffffffc0204898:	bf7fb0ef          	jal	ffffffffc020048e <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020489c:	00003697          	auipc	a3,0x3
ffffffffc02048a0:	c2468693          	addi	a3,a3,-988 # ffffffffc02074c0 <etext+0x19bc>
ffffffffc02048a4:	00002617          	auipc	a2,0x2
ffffffffc02048a8:	d0460613          	addi	a2,a2,-764 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02048ac:	3e300593          	li	a1,995
ffffffffc02048b0:	00003517          	auipc	a0,0x3
ffffffffc02048b4:	a9850513          	addi	a0,a0,-1384 # ffffffffc0207348 <etext+0x1844>
ffffffffc02048b8:	bd7fb0ef          	jal	ffffffffc020048e <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02048bc:	00003697          	auipc	a3,0x3
ffffffffc02048c0:	bd468693          	addi	a3,a3,-1068 # ffffffffc0207490 <etext+0x198c>
ffffffffc02048c4:	00002617          	auipc	a2,0x2
ffffffffc02048c8:	ce460613          	addi	a2,a2,-796 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02048cc:	3e200593          	li	a1,994
ffffffffc02048d0:	00003517          	auipc	a0,0x3
ffffffffc02048d4:	a7850513          	addi	a0,a0,-1416 # ffffffffc0207348 <etext+0x1844>
ffffffffc02048d8:	bb7fb0ef          	jal	ffffffffc020048e <__panic>
    assert(nr_process == 2);
ffffffffc02048dc:	00003697          	auipc	a3,0x3
ffffffffc02048e0:	ba468693          	addi	a3,a3,-1116 # ffffffffc0207480 <etext+0x197c>
ffffffffc02048e4:	00002617          	auipc	a2,0x2
ffffffffc02048e8:	cc460613          	addi	a2,a2,-828 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02048ec:	3e100593          	li	a1,993
ffffffffc02048f0:	00003517          	auipc	a0,0x3
ffffffffc02048f4:	a5850513          	addi	a0,a0,-1448 # ffffffffc0207348 <etext+0x1844>
ffffffffc02048f8:	b97fb0ef          	jal	ffffffffc020048e <__panic>

ffffffffc02048fc <do_execve>:
{
ffffffffc02048fc:	7171                	addi	sp,sp,-176
ffffffffc02048fe:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204900:	000add17          	auipc	s10,0xad
ffffffffc0204904:	c18d0d13          	addi	s10,s10,-1000 # ffffffffc02b1518 <current>
ffffffffc0204908:	000d3783          	ld	a5,0(s10)
{
ffffffffc020490c:	e94a                	sd	s2,144(sp)
ffffffffc020490e:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204910:	0287b903          	ld	s2,40(a5)
{
ffffffffc0204914:	84ae                	mv	s1,a1
ffffffffc0204916:	e54e                	sd	s3,136(sp)
ffffffffc0204918:	ec32                	sd	a2,24(sp)
ffffffffc020491a:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc020491c:	85aa                	mv	a1,a0
ffffffffc020491e:	8626                	mv	a2,s1
ffffffffc0204920:	854a                	mv	a0,s2
ffffffffc0204922:	4681                	li	a3,0
{
ffffffffc0204924:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc0204926:	cacff0ef          	jal	ffffffffc0203dd2 <user_mem_check>
ffffffffc020492a:	46050d63          	beqz	a0,ffffffffc0204da4 <do_execve+0x4a8>
    memset(local_name, 0, sizeof(local_name));
ffffffffc020492e:	4641                	li	a2,16
ffffffffc0204930:	1808                	addi	a0,sp,48
ffffffffc0204932:	4581                	li	a1,0
ffffffffc0204934:	1a6010ef          	jal	ffffffffc0205ada <memset>
    if (len > PROC_NAME_LEN)
ffffffffc0204938:	47bd                	li	a5,15
ffffffffc020493a:	8626                	mv	a2,s1
ffffffffc020493c:	0e97ef63          	bltu	a5,s1,ffffffffc0204a3a <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc0204940:	85ce                	mv	a1,s3
ffffffffc0204942:	1808                	addi	a0,sp,48
ffffffffc0204944:	1a8010ef          	jal	ffffffffc0205aec <memcpy>
    if (mm != NULL)
ffffffffc0204948:	10090063          	beqz	s2,ffffffffc0204a48 <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc020494c:	00003517          	auipc	a0,0x3
ffffffffc0204950:	80450513          	addi	a0,a0,-2044 # ffffffffc0207150 <etext+0x164c>
ffffffffc0204954:	8bffb0ef          	jal	ffffffffc0200212 <cputs>
ffffffffc0204958:	000ad797          	auipc	a5,0xad
ffffffffc020495c:	b907b783          	ld	a5,-1136(a5) # ffffffffc02b14e8 <boot_pgdir_pa>
ffffffffc0204960:	577d                	li	a4,-1
ffffffffc0204962:	177e                	slli	a4,a4,0x3f
ffffffffc0204964:	83b1                	srli	a5,a5,0xc
ffffffffc0204966:	8fd9                	or	a5,a5,a4
ffffffffc0204968:	18079073          	csrw	satp,a5
ffffffffc020496c:	03092783          	lw	a5,48(s2)
ffffffffc0204970:	37fd                	addiw	a5,a5,-1
ffffffffc0204972:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204976:	30078363          	beqz	a5,ffffffffc0204c7c <do_execve+0x380>
        current->mm = NULL;
ffffffffc020497a:	000d3783          	ld	a5,0(s10)
ffffffffc020497e:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204982:	dc5fe0ef          	jal	ffffffffc0203746 <mm_create>
ffffffffc0204986:	892a                	mv	s2,a0
ffffffffc0204988:	20050e63          	beqz	a0,ffffffffc0204ba4 <do_execve+0x2a8>
    if ((page = alloc_page()) == NULL)
ffffffffc020498c:	4505                	li	a0,1
ffffffffc020498e:	d60fd0ef          	jal	ffffffffc0201eee <alloc_pages>
ffffffffc0204992:	40050e63          	beqz	a0,ffffffffc0204dae <do_execve+0x4b2>
    return page - pages + nbase;
ffffffffc0204996:	f0e2                	sd	s8,96(sp)
ffffffffc0204998:	000adc17          	auipc	s8,0xad
ffffffffc020499c:	b70c0c13          	addi	s8,s8,-1168 # ffffffffc02b1508 <pages>
ffffffffc02049a0:	000c3783          	ld	a5,0(s8)
ffffffffc02049a4:	f4de                	sd	s7,104(sp)
ffffffffc02049a6:	00004b97          	auipc	s7,0x4
ffffffffc02049aa:	b3abbb83          	ld	s7,-1222(s7) # ffffffffc02084e0 <nbase>
ffffffffc02049ae:	40f506b3          	sub	a3,a0,a5
ffffffffc02049b2:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc02049b4:	000adc97          	auipc	s9,0xad
ffffffffc02049b8:	b4cc8c93          	addi	s9,s9,-1204 # ffffffffc02b1500 <npage>
ffffffffc02049bc:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc02049be:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02049c0:	5b7d                	li	s6,-1
ffffffffc02049c2:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc02049c6:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc02049c8:	00cb5713          	srli	a4,s6,0xc
ffffffffc02049cc:	e83a                	sd	a4,16(sp)
ffffffffc02049ce:	fcd6                	sd	s5,120(sp)
ffffffffc02049d0:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02049d2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02049d4:	40f77063          	bgeu	a4,a5,ffffffffc0204dd4 <do_execve+0x4d8>
ffffffffc02049d8:	000ada97          	auipc	s5,0xad
ffffffffc02049dc:	b20a8a93          	addi	s5,s5,-1248 # ffffffffc02b14f8 <va_pa_offset>
ffffffffc02049e0:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02049e4:	000ad597          	auipc	a1,0xad
ffffffffc02049e8:	b0c5b583          	ld	a1,-1268(a1) # ffffffffc02b14f0 <boot_pgdir_va>
ffffffffc02049ec:	6605                	lui	a2,0x1
ffffffffc02049ee:	00f684b3          	add	s1,a3,a5
ffffffffc02049f2:	8526                	mv	a0,s1
ffffffffc02049f4:	0f8010ef          	jal	ffffffffc0205aec <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02049f8:	66e2                	ld	a3,24(sp)
ffffffffc02049fa:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02049fe:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc0204a02:	4298                	lw	a4,0(a3)
ffffffffc0204a04:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_matrix_out_size+0x464b9057>
ffffffffc0204a08:	06f70863          	beq	a4,a5,ffffffffc0204a78 <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc0204a0c:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc0204a0e:	854a                	mv	a0,s2
ffffffffc0204a10:	d20ff0ef          	jal	ffffffffc0203f30 <put_pgdir>
ffffffffc0204a14:	7ae6                	ld	s5,120(sp)
ffffffffc0204a16:	7b46                	ld	s6,112(sp)
ffffffffc0204a18:	7ba6                	ld	s7,104(sp)
ffffffffc0204a1a:	7c06                	ld	s8,96(sp)
ffffffffc0204a1c:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc0204a1e:	854a                	mv	a0,s2
ffffffffc0204a20:	e65fe0ef          	jal	ffffffffc0203884 <mm_destroy>
    do_exit(ret);
ffffffffc0204a24:	8526                	mv	a0,s1
ffffffffc0204a26:	f122                	sd	s0,160(sp)
ffffffffc0204a28:	e152                	sd	s4,128(sp)
ffffffffc0204a2a:	fcd6                	sd	s5,120(sp)
ffffffffc0204a2c:	f8da                	sd	s6,112(sp)
ffffffffc0204a2e:	f4de                	sd	s7,104(sp)
ffffffffc0204a30:	f0e2                	sd	s8,96(sp)
ffffffffc0204a32:	ece6                	sd	s9,88(sp)
ffffffffc0204a34:	e4ee                	sd	s11,72(sp)
ffffffffc0204a36:	a7dff0ef          	jal	ffffffffc02044b2 <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc0204a3a:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc0204a3c:	85ce                	mv	a1,s3
ffffffffc0204a3e:	1808                	addi	a0,sp,48
ffffffffc0204a40:	0ac010ef          	jal	ffffffffc0205aec <memcpy>
    if (mm != NULL)
ffffffffc0204a44:	f00914e3          	bnez	s2,ffffffffc020494c <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc0204a48:	000d3783          	ld	a5,0(s10)
ffffffffc0204a4c:	779c                	ld	a5,40(a5)
ffffffffc0204a4e:	db95                	beqz	a5,ffffffffc0204982 <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204a50:	00003617          	auipc	a2,0x3
ffffffffc0204a54:	ac060613          	addi	a2,a2,-1344 # ffffffffc0207510 <etext+0x1a0c>
ffffffffc0204a58:	25e00593          	li	a1,606
ffffffffc0204a5c:	00003517          	auipc	a0,0x3
ffffffffc0204a60:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0207348 <etext+0x1844>
ffffffffc0204a64:	f122                	sd	s0,160(sp)
ffffffffc0204a66:	e152                	sd	s4,128(sp)
ffffffffc0204a68:	fcd6                	sd	s5,120(sp)
ffffffffc0204a6a:	f8da                	sd	s6,112(sp)
ffffffffc0204a6c:	f4de                	sd	s7,104(sp)
ffffffffc0204a6e:	f0e2                	sd	s8,96(sp)
ffffffffc0204a70:	ece6                	sd	s9,88(sp)
ffffffffc0204a72:	e4ee                	sd	s11,72(sp)
ffffffffc0204a74:	a1bfb0ef          	jal	ffffffffc020048e <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a78:	0386d703          	lhu	a4,56(a3)
ffffffffc0204a7c:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a7e:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a82:	00371793          	slli	a5,a4,0x3
ffffffffc0204a86:	8f99                	sub	a5,a5,a4
ffffffffc0204a88:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a8a:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a8c:	97d2                	add	a5,a5,s4
ffffffffc0204a8e:	f122                	sd	s0,160(sp)
ffffffffc0204a90:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204a92:	00fa7e63          	bgeu	s4,a5,ffffffffc0204aae <do_execve+0x1b2>
ffffffffc0204a96:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204a98:	000a2783          	lw	a5,0(s4)
ffffffffc0204a9c:	4705                	li	a4,1
ffffffffc0204a9e:	10e78563          	beq	a5,a4,ffffffffc0204ba8 <do_execve+0x2ac>
    for (; ph < ph_end; ph++)
ffffffffc0204aa2:	77a2                	ld	a5,40(sp)
ffffffffc0204aa4:	038a0a13          	addi	s4,s4,56
ffffffffc0204aa8:	fefa68e3          	bltu	s4,a5,ffffffffc0204a98 <do_execve+0x19c>
ffffffffc0204aac:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204aae:	4701                	li	a4,0
ffffffffc0204ab0:	46ad                	li	a3,11
ffffffffc0204ab2:	00100637          	lui	a2,0x100
ffffffffc0204ab6:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204aba:	854a                	mv	a0,s2
ffffffffc0204abc:	e1bfe0ef          	jal	ffffffffc02038d6 <mm_map>
ffffffffc0204ac0:	84aa                	mv	s1,a0
ffffffffc0204ac2:	1a051763          	bnez	a0,ffffffffc0204c70 <do_execve+0x374>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204ac6:	01893503          	ld	a0,24(s2)
ffffffffc0204aca:	467d                	li	a2,31
ffffffffc0204acc:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204ad0:	b95fe0ef          	jal	ffffffffc0203664 <pgdir_alloc_page>
ffffffffc0204ad4:	38050f63          	beqz	a0,ffffffffc0204e72 <do_execve+0x576>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ad8:	01893503          	ld	a0,24(s2)
ffffffffc0204adc:	467d                	li	a2,31
ffffffffc0204ade:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204ae2:	b83fe0ef          	jal	ffffffffc0203664 <pgdir_alloc_page>
ffffffffc0204ae6:	36050563          	beqz	a0,ffffffffc0204e50 <do_execve+0x554>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204aea:	01893503          	ld	a0,24(s2)
ffffffffc0204aee:	467d                	li	a2,31
ffffffffc0204af0:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204af4:	b71fe0ef          	jal	ffffffffc0203664 <pgdir_alloc_page>
ffffffffc0204af8:	32050b63          	beqz	a0,ffffffffc0204e2e <do_execve+0x532>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204afc:	01893503          	ld	a0,24(s2)
ffffffffc0204b00:	467d                	li	a2,31
ffffffffc0204b02:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204b06:	b5ffe0ef          	jal	ffffffffc0203664 <pgdir_alloc_page>
ffffffffc0204b0a:	30050163          	beqz	a0,ffffffffc0204e0c <do_execve+0x510>
    mm->mm_count += 1;
ffffffffc0204b0e:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0204b12:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b16:	01893683          	ld	a3,24(s2)
ffffffffc0204b1a:	2785                	addiw	a5,a5,1
ffffffffc0204b1c:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0204b20:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_matrix_out_size+0xf4b00>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204b24:	c02007b7          	lui	a5,0xc0200
ffffffffc0204b28:	2cf6e563          	bltu	a3,a5,ffffffffc0204df2 <do_execve+0x4f6>
ffffffffc0204b2c:	000ab783          	ld	a5,0(s5)
ffffffffc0204b30:	577d                	li	a4,-1
ffffffffc0204b32:	177e                	slli	a4,a4,0x3f
ffffffffc0204b34:	8e9d                	sub	a3,a3,a5
ffffffffc0204b36:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b3a:	f654                	sd	a3,168(a2)
ffffffffc0204b3c:	8fd9                	or	a5,a5,a4
ffffffffc0204b3e:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204b42:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b44:	4581                	li	a1,0
ffffffffc0204b46:	12000613          	li	a2,288
ffffffffc0204b4a:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204b4c:	10043983          	ld	s3,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b50:	78b000ef          	jal	ffffffffc0205ada <memset>
    tf->epc = elf->e_entry;
ffffffffc0204b54:	67e2                	ld	a5,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b56:	000d3903          	ld	s2,0(s10)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc0204b5a:	edf9f993          	andi	s3,s3,-289
    tf->epc = elf->e_entry;
ffffffffc0204b5e:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b60:	4785                	li	a5,1
ffffffffc0204b62:	07fe                	slli	a5,a5,0x1f
    tf->epc = elf->e_entry;
ffffffffc0204b64:	10e43423          	sd	a4,264(s0)
    tf->gpr.sp = USTACKTOP;
ffffffffc0204b68:	e81c                	sd	a5,16(s0)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc0204b6a:	11343023          	sd	s3,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b6e:	4641                	li	a2,16
ffffffffc0204b70:	4581                	li	a1,0
ffffffffc0204b72:	0b490513          	addi	a0,s2,180
ffffffffc0204b76:	765000ef          	jal	ffffffffc0205ada <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204b7a:	180c                	addi	a1,sp,48
ffffffffc0204b7c:	0b490513          	addi	a0,s2,180
ffffffffc0204b80:	463d                	li	a2,15
ffffffffc0204b82:	76b000ef          	jal	ffffffffc0205aec <memcpy>
ffffffffc0204b86:	740a                	ld	s0,160(sp)
ffffffffc0204b88:	6a0a                	ld	s4,128(sp)
ffffffffc0204b8a:	7ae6                	ld	s5,120(sp)
ffffffffc0204b8c:	7b46                	ld	s6,112(sp)
ffffffffc0204b8e:	7ba6                	ld	s7,104(sp)
ffffffffc0204b90:	7c06                	ld	s8,96(sp)
ffffffffc0204b92:	6ce6                	ld	s9,88(sp)
}
ffffffffc0204b94:	70aa                	ld	ra,168(sp)
ffffffffc0204b96:	694a                	ld	s2,144(sp)
ffffffffc0204b98:	69aa                	ld	s3,136(sp)
ffffffffc0204b9a:	6d46                	ld	s10,80(sp)
ffffffffc0204b9c:	8526                	mv	a0,s1
ffffffffc0204b9e:	64ea                	ld	s1,152(sp)
ffffffffc0204ba0:	614d                	addi	sp,sp,176
ffffffffc0204ba2:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204ba4:	54f1                	li	s1,-4
ffffffffc0204ba6:	bdbd                	j	ffffffffc0204a24 <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204ba8:	028a3603          	ld	a2,40(s4)
ffffffffc0204bac:	020a3783          	ld	a5,32(s4)
ffffffffc0204bb0:	20f66363          	bltu	a2,a5,ffffffffc0204db6 <do_execve+0x4ba>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204bb4:	004a2783          	lw	a5,4(s4)
ffffffffc0204bb8:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204bbc:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204bc0:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bc2:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204bc4:	c6f1                	beqz	a3,ffffffffc0204c90 <do_execve+0x394>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204bc6:	1c079763          	bnez	a5,ffffffffc0204d94 <do_execve+0x498>
            perm |= (PTE_W | PTE_R);
ffffffffc0204bca:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc0204bcc:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc0204bd0:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc0204bd2:	c709                	beqz	a4,ffffffffc0204bdc <do_execve+0x2e0>
            perm |= PTE_X;
ffffffffc0204bd4:	67a2                	ld	a5,8(sp)
ffffffffc0204bd6:	0087e793          	ori	a5,a5,8
ffffffffc0204bda:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204bdc:	010a3583          	ld	a1,16(s4)
ffffffffc0204be0:	4701                	li	a4,0
ffffffffc0204be2:	854a                	mv	a0,s2
ffffffffc0204be4:	cf3fe0ef          	jal	ffffffffc02038d6 <mm_map>
ffffffffc0204be8:	84aa                	mv	s1,a0
ffffffffc0204bea:	1c051463          	bnez	a0,ffffffffc0204db2 <do_execve+0x4b6>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bee:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bf2:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bf6:	77fd                	lui	a5,0xfffff
ffffffffc0204bf8:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bfc:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc0204bfe:	1a9b7563          	bgeu	s6,s1,ffffffffc0204da8 <do_execve+0x4ac>
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204c02:	008a3983          	ld	s3,8(s4)
ffffffffc0204c06:	67e2                	ld	a5,24(sp)
ffffffffc0204c08:	99be                	add	s3,s3,a5
ffffffffc0204c0a:	a881                	j	ffffffffc0204c5a <do_execve+0x35e>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c0c:	6785                	lui	a5,0x1
ffffffffc0204c0e:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204c12:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204c16:	01b4e463          	bltu	s1,s11,ffffffffc0204c1e <do_execve+0x322>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204c1a:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204c1e:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204c22:	67c2                	ld	a5,16(sp)
ffffffffc0204c24:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204c28:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c2c:	8699                	srai	a3,a3,0x6
ffffffffc0204c2e:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204c30:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c34:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c36:	18a87363          	bgeu	a6,a0,ffffffffc0204dbc <do_execve+0x4c0>
ffffffffc0204c3a:	000ab503          	ld	a0,0(s5)
ffffffffc0204c3e:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c42:	e032                	sd	a2,0(sp)
ffffffffc0204c44:	9536                	add	a0,a0,a3
ffffffffc0204c46:	952e                	add	a0,a0,a1
ffffffffc0204c48:	85ce                	mv	a1,s3
ffffffffc0204c4a:	6a3000ef          	jal	ffffffffc0205aec <memcpy>
            start += size, from += size;
ffffffffc0204c4e:	6602                	ld	a2,0(sp)
ffffffffc0204c50:	9b32                	add	s6,s6,a2
ffffffffc0204c52:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204c54:	049b7563          	bgeu	s6,s1,ffffffffc0204c9e <do_execve+0x3a2>
ffffffffc0204c58:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c5a:	01893503          	ld	a0,24(s2)
ffffffffc0204c5e:	6622                	ld	a2,8(sp)
ffffffffc0204c60:	e02e                	sd	a1,0(sp)
ffffffffc0204c62:	a03fe0ef          	jal	ffffffffc0203664 <pgdir_alloc_page>
ffffffffc0204c66:	6582                	ld	a1,0(sp)
ffffffffc0204c68:	842a                	mv	s0,a0
ffffffffc0204c6a:	f14d                	bnez	a0,ffffffffc0204c0c <do_execve+0x310>
ffffffffc0204c6c:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204c6e:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204c70:	854a                	mv	a0,s2
ffffffffc0204c72:	dc9fe0ef          	jal	ffffffffc0203a3a <exit_mmap>
ffffffffc0204c76:	740a                	ld	s0,160(sp)
ffffffffc0204c78:	6a0a                	ld	s4,128(sp)
ffffffffc0204c7a:	bb51                	j	ffffffffc0204a0e <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204c7c:	854a                	mv	a0,s2
ffffffffc0204c7e:	dbdfe0ef          	jal	ffffffffc0203a3a <exit_mmap>
            put_pgdir(mm);
ffffffffc0204c82:	854a                	mv	a0,s2
ffffffffc0204c84:	aacff0ef          	jal	ffffffffc0203f30 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204c88:	854a                	mv	a0,s2
ffffffffc0204c8a:	bfbfe0ef          	jal	ffffffffc0203884 <mm_destroy>
ffffffffc0204c8e:	b1f5                	j	ffffffffc020497a <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c90:	0e078e63          	beqz	a5,ffffffffc0204d8c <do_execve+0x490>
            perm |= PTE_R;
ffffffffc0204c94:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204c96:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204c9a:	e43e                	sd	a5,8(sp)
ffffffffc0204c9c:	bf1d                	j	ffffffffc0204bd2 <do_execve+0x2d6>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204c9e:	010a3483          	ld	s1,16(s4)
ffffffffc0204ca2:	028a3683          	ld	a3,40(s4)
ffffffffc0204ca6:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204ca8:	07bb7c63          	bgeu	s6,s11,ffffffffc0204d20 <do_execve+0x424>
            if (start == end)
ffffffffc0204cac:	df648be3          	beq	s1,s6,ffffffffc0204aa2 <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204cb0:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204cb4:	0fb4f563          	bgeu	s1,s11,ffffffffc0204d9e <do_execve+0x4a2>
    return page - pages + nbase;
ffffffffc0204cb8:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204cbc:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204cc0:	40d406b3          	sub	a3,s0,a3
ffffffffc0204cc4:	8699                	srai	a3,a3,0x6
ffffffffc0204cc6:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204cc8:	00c69593          	slli	a1,a3,0xc
ffffffffc0204ccc:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204cce:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204cd0:	0ec5f663          	bgeu	a1,a2,ffffffffc0204dbc <do_execve+0x4c0>
ffffffffc0204cd4:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204cd8:	6505                	lui	a0,0x1
ffffffffc0204cda:	955a                	add	a0,a0,s6
ffffffffc0204cdc:	96b2                	add	a3,a3,a2
ffffffffc0204cde:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204ce2:	9536                	add	a0,a0,a3
ffffffffc0204ce4:	864e                	mv	a2,s3
ffffffffc0204ce6:	4581                	li	a1,0
ffffffffc0204ce8:	5f3000ef          	jal	ffffffffc0205ada <memset>
            start += size;
ffffffffc0204cec:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204cee:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204cf2:	01b4f463          	bgeu	s1,s11,ffffffffc0204cfa <do_execve+0x3fe>
ffffffffc0204cf6:	db6486e3          	beq	s1,s6,ffffffffc0204aa2 <do_execve+0x1a6>
ffffffffc0204cfa:	e299                	bnez	a3,ffffffffc0204d00 <do_execve+0x404>
ffffffffc0204cfc:	03bb0263          	beq	s6,s11,ffffffffc0204d20 <do_execve+0x424>
ffffffffc0204d00:	00003697          	auipc	a3,0x3
ffffffffc0204d04:	83868693          	addi	a3,a3,-1992 # ffffffffc0207538 <etext+0x1a34>
ffffffffc0204d08:	00002617          	auipc	a2,0x2
ffffffffc0204d0c:	8a060613          	addi	a2,a2,-1888 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0204d10:	2c700593          	li	a1,711
ffffffffc0204d14:	00002517          	auipc	a0,0x2
ffffffffc0204d18:	63450513          	addi	a0,a0,1588 # ffffffffc0207348 <etext+0x1844>
ffffffffc0204d1c:	f72fb0ef          	jal	ffffffffc020048e <__panic>
        while (start < end)
ffffffffc0204d20:	d89b71e3          	bgeu	s6,s1,ffffffffc0204aa2 <do_execve+0x1a6>
ffffffffc0204d24:	56fd                	li	a3,-1
ffffffffc0204d26:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204d2a:	f03e                	sd	a5,32(sp)
ffffffffc0204d2c:	a0b9                	j	ffffffffc0204d7a <do_execve+0x47e>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d2e:	6785                	lui	a5,0x1
ffffffffc0204d30:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204d34:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204d38:	0104e463          	bltu	s1,a6,ffffffffc0204d40 <do_execve+0x444>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d3c:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204d40:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204d44:	7782                	ld	a5,32(sp)
ffffffffc0204d46:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204d4a:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d4e:	8699                	srai	a3,a3,0x6
ffffffffc0204d50:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204d52:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d56:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d58:	06b57263          	bgeu	a0,a1,ffffffffc0204dbc <do_execve+0x4c0>
ffffffffc0204d5c:	000ab583          	ld	a1,0(s5)
ffffffffc0204d60:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d64:	864e                	mv	a2,s3
ffffffffc0204d66:	96ae                	add	a3,a3,a1
ffffffffc0204d68:	9536                	add	a0,a0,a3
ffffffffc0204d6a:	4581                	li	a1,0
            start += size;
ffffffffc0204d6c:	9b4e                	add	s6,s6,s3
ffffffffc0204d6e:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d70:	56b000ef          	jal	ffffffffc0205ada <memset>
        while (start < end)
ffffffffc0204d74:	d29b77e3          	bgeu	s6,s1,ffffffffc0204aa2 <do_execve+0x1a6>
ffffffffc0204d78:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d7a:	01893503          	ld	a0,24(s2)
ffffffffc0204d7e:	6622                	ld	a2,8(sp)
ffffffffc0204d80:	85ee                	mv	a1,s11
ffffffffc0204d82:	8e3fe0ef          	jal	ffffffffc0203664 <pgdir_alloc_page>
ffffffffc0204d86:	842a                	mv	s0,a0
ffffffffc0204d88:	f15d                	bnez	a0,ffffffffc0204d2e <do_execve+0x432>
ffffffffc0204d8a:	b5cd                	j	ffffffffc0204c6c <do_execve+0x370>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204d8c:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d8e:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204d90:	e43e                	sd	a5,8(sp)
ffffffffc0204d92:	b581                	j	ffffffffc0204bd2 <do_execve+0x2d6>
            perm |= (PTE_W | PTE_R);
ffffffffc0204d94:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204d96:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204d9a:	e43e                	sd	a5,8(sp)
ffffffffc0204d9c:	bd1d                	j	ffffffffc0204bd2 <do_execve+0x2d6>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d9e:	416d89b3          	sub	s3,s11,s6
ffffffffc0204da2:	bf19                	j	ffffffffc0204cb8 <do_execve+0x3bc>
        return -E_INVAL;
ffffffffc0204da4:	54f5                	li	s1,-3
ffffffffc0204da6:	b3fd                	j	ffffffffc0204b94 <do_execve+0x298>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204da8:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204daa:	84da                	mv	s1,s6
ffffffffc0204dac:	bddd                	j	ffffffffc0204ca2 <do_execve+0x3a6>
    int ret = -E_NO_MEM;
ffffffffc0204dae:	54f1                	li	s1,-4
ffffffffc0204db0:	b1bd                	j	ffffffffc0204a1e <do_execve+0x122>
ffffffffc0204db2:	6da6                	ld	s11,72(sp)
ffffffffc0204db4:	bd75                	j	ffffffffc0204c70 <do_execve+0x374>
            ret = -E_INVAL_ELF;
ffffffffc0204db6:	6da6                	ld	s11,72(sp)
ffffffffc0204db8:	54e1                	li	s1,-8
ffffffffc0204dba:	bd5d                	j	ffffffffc0204c70 <do_execve+0x374>
ffffffffc0204dbc:	00002617          	auipc	a2,0x2
ffffffffc0204dc0:	b9c60613          	addi	a2,a2,-1124 # ffffffffc0206958 <etext+0xe54>
ffffffffc0204dc4:	07100593          	li	a1,113
ffffffffc0204dc8:	00002517          	auipc	a0,0x2
ffffffffc0204dcc:	bb850513          	addi	a0,a0,-1096 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0204dd0:	ebefb0ef          	jal	ffffffffc020048e <__panic>
ffffffffc0204dd4:	00002617          	auipc	a2,0x2
ffffffffc0204dd8:	b8460613          	addi	a2,a2,-1148 # ffffffffc0206958 <etext+0xe54>
ffffffffc0204ddc:	07100593          	li	a1,113
ffffffffc0204de0:	00002517          	auipc	a0,0x2
ffffffffc0204de4:	ba050513          	addi	a0,a0,-1120 # ffffffffc0206980 <etext+0xe7c>
ffffffffc0204de8:	f122                	sd	s0,160(sp)
ffffffffc0204dea:	e152                	sd	s4,128(sp)
ffffffffc0204dec:	e4ee                	sd	s11,72(sp)
ffffffffc0204dee:	ea0fb0ef          	jal	ffffffffc020048e <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204df2:	00002617          	auipc	a2,0x2
ffffffffc0204df6:	c0e60613          	addi	a2,a2,-1010 # ffffffffc0206a00 <etext+0xefc>
ffffffffc0204dfa:	2e600593          	li	a1,742
ffffffffc0204dfe:	00002517          	auipc	a0,0x2
ffffffffc0204e02:	54a50513          	addi	a0,a0,1354 # ffffffffc0207348 <etext+0x1844>
ffffffffc0204e06:	e4ee                	sd	s11,72(sp)
ffffffffc0204e08:	e86fb0ef          	jal	ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e0c:	00003697          	auipc	a3,0x3
ffffffffc0204e10:	84468693          	addi	a3,a3,-1980 # ffffffffc0207650 <etext+0x1b4c>
ffffffffc0204e14:	00001617          	auipc	a2,0x1
ffffffffc0204e18:	79460613          	addi	a2,a2,1940 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0204e1c:	2e100593          	li	a1,737
ffffffffc0204e20:	00002517          	auipc	a0,0x2
ffffffffc0204e24:	52850513          	addi	a0,a0,1320 # ffffffffc0207348 <etext+0x1844>
ffffffffc0204e28:	e4ee                	sd	s11,72(sp)
ffffffffc0204e2a:	e64fb0ef          	jal	ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e2e:	00002697          	auipc	a3,0x2
ffffffffc0204e32:	7da68693          	addi	a3,a3,2010 # ffffffffc0207608 <etext+0x1b04>
ffffffffc0204e36:	00001617          	auipc	a2,0x1
ffffffffc0204e3a:	77260613          	addi	a2,a2,1906 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0204e3e:	2e000593          	li	a1,736
ffffffffc0204e42:	00002517          	auipc	a0,0x2
ffffffffc0204e46:	50650513          	addi	a0,a0,1286 # ffffffffc0207348 <etext+0x1844>
ffffffffc0204e4a:	e4ee                	sd	s11,72(sp)
ffffffffc0204e4c:	e42fb0ef          	jal	ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e50:	00002697          	auipc	a3,0x2
ffffffffc0204e54:	77068693          	addi	a3,a3,1904 # ffffffffc02075c0 <etext+0x1abc>
ffffffffc0204e58:	00001617          	auipc	a2,0x1
ffffffffc0204e5c:	75060613          	addi	a2,a2,1872 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0204e60:	2df00593          	li	a1,735
ffffffffc0204e64:	00002517          	auipc	a0,0x2
ffffffffc0204e68:	4e450513          	addi	a0,a0,1252 # ffffffffc0207348 <etext+0x1844>
ffffffffc0204e6c:	e4ee                	sd	s11,72(sp)
ffffffffc0204e6e:	e20fb0ef          	jal	ffffffffc020048e <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204e72:	00002697          	auipc	a3,0x2
ffffffffc0204e76:	70668693          	addi	a3,a3,1798 # ffffffffc0207578 <etext+0x1a74>
ffffffffc0204e7a:	00001617          	auipc	a2,0x1
ffffffffc0204e7e:	72e60613          	addi	a2,a2,1838 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0204e82:	2de00593          	li	a1,734
ffffffffc0204e86:	00002517          	auipc	a0,0x2
ffffffffc0204e8a:	4c250513          	addi	a0,a0,1218 # ffffffffc0207348 <etext+0x1844>
ffffffffc0204e8e:	e4ee                	sd	s11,72(sp)
ffffffffc0204e90:	dfefb0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0204e94 <user_main>:
{
ffffffffc0204e94:	1101                	addi	sp,sp,-32
ffffffffc0204e96:	e426                	sd	s1,8(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204e98:	000ac497          	auipc	s1,0xac
ffffffffc0204e9c:	68048493          	addi	s1,s1,1664 # ffffffffc02b1518 <current>
ffffffffc0204ea0:	609c                	ld	a5,0(s1)
ffffffffc0204ea2:	00002617          	auipc	a2,0x2
ffffffffc0204ea6:	7f660613          	addi	a2,a2,2038 # ffffffffc0207698 <etext+0x1b94>
ffffffffc0204eaa:	00002517          	auipc	a0,0x2
ffffffffc0204eae:	7fe50513          	addi	a0,a0,2046 # ffffffffc02076a8 <etext+0x1ba4>
ffffffffc0204eb2:	43cc                	lw	a1,4(a5)
{
ffffffffc0204eb4:	ec06                	sd	ra,24(sp)
ffffffffc0204eb6:	e822                	sd	s0,16(sp)
ffffffffc0204eb8:	e04a                	sd	s2,0(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204eba:	b22fb0ef          	jal	ffffffffc02001dc <cprintf>
    size_t len = strlen(name);
ffffffffc0204ebe:	00002517          	auipc	a0,0x2
ffffffffc0204ec2:	7da50513          	addi	a0,a0,2010 # ffffffffc0207698 <etext+0x1b94>
ffffffffc0204ec6:	361000ef          	jal	ffffffffc0205a26 <strlen>
    struct trapframe *old_tf = current->tf;
ffffffffc0204eca:	6098                	ld	a4,0(s1)
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204ecc:	6789                	lui	a5,0x2
ffffffffc0204ece:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x7040>
ffffffffc0204ed2:	6b00                	ld	s0,16(a4)
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204ed4:	734c                	ld	a1,160(a4)
    size_t len = strlen(name);
ffffffffc0204ed6:	892a                	mv	s2,a0
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
ffffffffc0204ed8:	943e                	add	s0,s0,a5
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
ffffffffc0204eda:	12000613          	li	a2,288
ffffffffc0204ede:	8522                	mv	a0,s0
ffffffffc0204ee0:	40d000ef          	jal	ffffffffc0205aec <memcpy>
    current->tf = new_tf;
ffffffffc0204ee4:	609c                	ld	a5,0(s1)
    ret = do_execve(name, len, binary, size);
ffffffffc0204ee6:	85ca                	mv	a1,s2
ffffffffc0204ee8:	3fe06697          	auipc	a3,0x3fe06
ffffffffc0204eec:	81868693          	addi	a3,a3,-2024 # a700 <_binary_obj___user_priority_out_size>
    current->tf = new_tf;
ffffffffc0204ef0:	f3c0                	sd	s0,160(a5)
    ret = do_execve(name, len, binary, size);
ffffffffc0204ef2:	00072617          	auipc	a2,0x72
ffffffffc0204ef6:	9be60613          	addi	a2,a2,-1602 # ffffffffc02768b0 <_binary_obj___user_priority_out_start>
ffffffffc0204efa:	00002517          	auipc	a0,0x2
ffffffffc0204efe:	79e50513          	addi	a0,a0,1950 # ffffffffc0207698 <etext+0x1b94>
ffffffffc0204f02:	9fbff0ef          	jal	ffffffffc02048fc <do_execve>
    asm volatile(
ffffffffc0204f06:	8122                	mv	sp,s0
ffffffffc0204f08:	858fc06f          	j	ffffffffc0200f60 <__trapret>
    panic("user_main execve failed.\n");
ffffffffc0204f0c:	00002617          	auipc	a2,0x2
ffffffffc0204f10:	7c460613          	addi	a2,a2,1988 # ffffffffc02076d0 <etext+0x1bcc>
ffffffffc0204f14:	3ca00593          	li	a1,970
ffffffffc0204f18:	00002517          	auipc	a0,0x2
ffffffffc0204f1c:	43050513          	addi	a0,a0,1072 # ffffffffc0207348 <etext+0x1844>
ffffffffc0204f20:	d6efb0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0204f24 <do_yield>:
    current->need_resched = 1;
ffffffffc0204f24:	000ac797          	auipc	a5,0xac
ffffffffc0204f28:	5f47b783          	ld	a5,1524(a5) # ffffffffc02b1518 <current>
ffffffffc0204f2c:	4705                	li	a4,1
}
ffffffffc0204f2e:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204f30:	ef98                	sd	a4,24(a5)
}
ffffffffc0204f32:	8082                	ret

ffffffffc0204f34 <do_wait>:
    if (code_store != NULL)
ffffffffc0204f34:	c59d                	beqz	a1,ffffffffc0204f62 <do_wait+0x2e>
{
ffffffffc0204f36:	1101                	addi	sp,sp,-32
ffffffffc0204f38:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204f3a:	000ac517          	auipc	a0,0xac
ffffffffc0204f3e:	5de53503          	ld	a0,1502(a0) # ffffffffc02b1518 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204f42:	4685                	li	a3,1
ffffffffc0204f44:	4611                	li	a2,4
ffffffffc0204f46:	7508                	ld	a0,40(a0)
{
ffffffffc0204f48:	ec06                	sd	ra,24(sp)
ffffffffc0204f4a:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204f4c:	e87fe0ef          	jal	ffffffffc0203dd2 <user_mem_check>
ffffffffc0204f50:	6702                	ld	a4,0(sp)
ffffffffc0204f52:	67a2                	ld	a5,8(sp)
ffffffffc0204f54:	c909                	beqz	a0,ffffffffc0204f66 <do_wait+0x32>
}
ffffffffc0204f56:	60e2                	ld	ra,24(sp)
ffffffffc0204f58:	85be                	mv	a1,a5
ffffffffc0204f5a:	853a                	mv	a0,a4
ffffffffc0204f5c:	6105                	addi	sp,sp,32
ffffffffc0204f5e:	e98ff06f          	j	ffffffffc02045f6 <do_wait.part.0>
ffffffffc0204f62:	e94ff06f          	j	ffffffffc02045f6 <do_wait.part.0>
ffffffffc0204f66:	60e2                	ld	ra,24(sp)
ffffffffc0204f68:	5575                	li	a0,-3
ffffffffc0204f6a:	6105                	addi	sp,sp,32
ffffffffc0204f6c:	8082                	ret

ffffffffc0204f6e <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204f6e:	6789                	lui	a5,0x2
ffffffffc0204f70:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204f74:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f22>
ffffffffc0204f76:	06e7e463          	bltu	a5,a4,ffffffffc0204fde <do_kill+0x70>
{
ffffffffc0204f7a:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f7c:	45a9                	li	a1,10
{
ffffffffc0204f7e:	ec06                	sd	ra,24(sp)
ffffffffc0204f80:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f82:	6c2000ef          	jal	ffffffffc0205644 <hash32>
ffffffffc0204f86:	02051793          	slli	a5,a0,0x20
ffffffffc0204f8a:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204f8e:	000ac797          	auipc	a5,0xac
ffffffffc0204f92:	5a278793          	addi	a5,a5,1442 # ffffffffc02b1530 <hash_list>
ffffffffc0204f96:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204f98:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f9a:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204f9c:	a029                	j	ffffffffc0204fa6 <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204f9e:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204fa2:	00c70963          	beq	a4,a2,ffffffffc0204fb4 <do_kill+0x46>
ffffffffc0204fa6:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204fa8:	fea69be3          	bne	a3,a0,ffffffffc0204f9e <do_kill+0x30>
}
ffffffffc0204fac:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204fae:	5575                	li	a0,-3
}
ffffffffc0204fb0:	6105                	addi	sp,sp,32
ffffffffc0204fb2:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204fb4:	fd852703          	lw	a4,-40(a0)
ffffffffc0204fb8:	00177693          	andi	a3,a4,1
ffffffffc0204fbc:	e29d                	bnez	a3,ffffffffc0204fe2 <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204fbe:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204fc0:	00176713          	ori	a4,a4,1
ffffffffc0204fc4:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204fc8:	0006c663          	bltz	a3,ffffffffc0204fd4 <do_kill+0x66>
            return 0;
ffffffffc0204fcc:	4501                	li	a0,0
}
ffffffffc0204fce:	60e2                	ld	ra,24(sp)
ffffffffc0204fd0:	6105                	addi	sp,sp,32
ffffffffc0204fd2:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204fd4:	f2850513          	addi	a0,a0,-216
ffffffffc0204fd8:	3c2000ef          	jal	ffffffffc020539a <wakeup_proc>
ffffffffc0204fdc:	bfc5                	j	ffffffffc0204fcc <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204fde:	5575                	li	a0,-3
}
ffffffffc0204fe0:	8082                	ret
        return -E_KILLED;
ffffffffc0204fe2:	555d                	li	a0,-9
ffffffffc0204fe4:	b7ed                	j	ffffffffc0204fce <do_kill+0x60>

ffffffffc0204fe6 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204fe6:	1101                	addi	sp,sp,-32
ffffffffc0204fe8:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204fea:	000b0797          	auipc	a5,0xb0
ffffffffc0204fee:	54678793          	addi	a5,a5,1350 # ffffffffc02b5530 <proc_list>
ffffffffc0204ff2:	ec06                	sd	ra,24(sp)
ffffffffc0204ff4:	e822                	sd	s0,16(sp)
ffffffffc0204ff6:	e04a                	sd	s2,0(sp)
ffffffffc0204ff8:	000ac497          	auipc	s1,0xac
ffffffffc0204ffc:	53848493          	addi	s1,s1,1336 # ffffffffc02b1530 <hash_list>
ffffffffc0205000:	e79c                	sd	a5,8(a5)
ffffffffc0205002:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0205004:	000b0717          	auipc	a4,0xb0
ffffffffc0205008:	52c70713          	addi	a4,a4,1324 # ffffffffc02b5530 <proc_list>
ffffffffc020500c:	87a6                	mv	a5,s1
ffffffffc020500e:	e79c                	sd	a5,8(a5)
ffffffffc0205010:	e39c                	sd	a5,0(a5)
ffffffffc0205012:	07c1                	addi	a5,a5,16
ffffffffc0205014:	fee79de3          	bne	a5,a4,ffffffffc020500e <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0205018:	e7bfe0ef          	jal	ffffffffc0203e92 <alloc_proc>
ffffffffc020501c:	000ac917          	auipc	s2,0xac
ffffffffc0205020:	50c90913          	addi	s2,s2,1292 # ffffffffc02b1528 <idleproc>
ffffffffc0205024:	00a93023          	sd	a0,0(s2)
ffffffffc0205028:	10050363          	beqz	a0,ffffffffc020512e <proc_init+0x148>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc020502c:	4789                	li	a5,2
ffffffffc020502e:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205030:	00004797          	auipc	a5,0x4
ffffffffc0205034:	fd078793          	addi	a5,a5,-48 # ffffffffc0209000 <bootstack>
ffffffffc0205038:	e91c                	sd	a5,16(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020503a:	0b450413          	addi	s0,a0,180
    idleproc->need_resched = 1;
ffffffffc020503e:	4785                	li	a5,1
ffffffffc0205040:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205042:	4641                	li	a2,16
ffffffffc0205044:	8522                	mv	a0,s0
ffffffffc0205046:	4581                	li	a1,0
ffffffffc0205048:	293000ef          	jal	ffffffffc0205ada <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020504c:	8522                	mv	a0,s0
ffffffffc020504e:	463d                	li	a2,15
ffffffffc0205050:	00002597          	auipc	a1,0x2
ffffffffc0205054:	6b858593          	addi	a1,a1,1720 # ffffffffc0207708 <etext+0x1c04>
ffffffffc0205058:	295000ef          	jal	ffffffffc0205aec <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc020505c:	000ac797          	auipc	a5,0xac
ffffffffc0205060:	4b47a783          	lw	a5,1204(a5) # ffffffffc02b1510 <nr_process>

    current = idleproc;
ffffffffc0205064:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205068:	4601                	li	a2,0
    nr_process++;
ffffffffc020506a:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc020506c:	4581                	li	a1,0
ffffffffc020506e:	fffff517          	auipc	a0,0xfffff
ffffffffc0205072:	76a50513          	addi	a0,a0,1898 # ffffffffc02047d8 <init_main>
    current = idleproc;
ffffffffc0205076:	000ac697          	auipc	a3,0xac
ffffffffc020507a:	4ae6b123          	sd	a4,1186(a3) # ffffffffc02b1518 <current>
    nr_process++;
ffffffffc020507e:	000ac717          	auipc	a4,0xac
ffffffffc0205082:	48f72923          	sw	a5,1170(a4) # ffffffffc02b1510 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205086:	bdcff0ef          	jal	ffffffffc0204462 <kernel_thread>
ffffffffc020508a:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc020508c:	08a05563          	blez	a0,ffffffffc0205116 <proc_init+0x130>
    if (0 < pid && pid < MAX_PID)
ffffffffc0205090:	6789                	lui	a5,0x2
ffffffffc0205092:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6f22>
ffffffffc0205094:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205098:	02e7e463          	bltu	a5,a4,ffffffffc02050c0 <proc_init+0xda>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc020509c:	45a9                	li	a1,10
ffffffffc020509e:	5a6000ef          	jal	ffffffffc0205644 <hash32>
ffffffffc02050a2:	02051713          	slli	a4,a0,0x20
ffffffffc02050a6:	01c75793          	srli	a5,a4,0x1c
ffffffffc02050aa:	00f486b3          	add	a3,s1,a5
ffffffffc02050ae:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc02050b0:	a029                	j	ffffffffc02050ba <proc_init+0xd4>
            if (proc->pid == pid)
ffffffffc02050b2:	f2c7a703          	lw	a4,-212(a5)
ffffffffc02050b6:	04870d63          	beq	a4,s0,ffffffffc0205110 <proc_init+0x12a>
    return listelm->next;
ffffffffc02050ba:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc02050bc:	fef69be3          	bne	a3,a5,ffffffffc02050b2 <proc_init+0xcc>
    return NULL;
ffffffffc02050c0:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050c2:	0b478413          	addi	s0,a5,180
ffffffffc02050c6:	4641                	li	a2,16
ffffffffc02050c8:	4581                	li	a1,0
ffffffffc02050ca:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc02050cc:	000ac717          	auipc	a4,0xac
ffffffffc02050d0:	44f73a23          	sd	a5,1108(a4) # ffffffffc02b1520 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02050d4:	207000ef          	jal	ffffffffc0205ada <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02050d8:	8522                	mv	a0,s0
ffffffffc02050da:	463d                	li	a2,15
ffffffffc02050dc:	00002597          	auipc	a1,0x2
ffffffffc02050e0:	65458593          	addi	a1,a1,1620 # ffffffffc0207730 <etext+0x1c2c>
ffffffffc02050e4:	209000ef          	jal	ffffffffc0205aec <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050e8:	00093783          	ld	a5,0(s2)
ffffffffc02050ec:	cfad                	beqz	a5,ffffffffc0205166 <proc_init+0x180>
ffffffffc02050ee:	43dc                	lw	a5,4(a5)
ffffffffc02050f0:	ebbd                	bnez	a5,ffffffffc0205166 <proc_init+0x180>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02050f2:	000ac797          	auipc	a5,0xac
ffffffffc02050f6:	42e7b783          	ld	a5,1070(a5) # ffffffffc02b1520 <initproc>
ffffffffc02050fa:	c7b1                	beqz	a5,ffffffffc0205146 <proc_init+0x160>
ffffffffc02050fc:	43d8                	lw	a4,4(a5)
ffffffffc02050fe:	4785                	li	a5,1
ffffffffc0205100:	04f71363          	bne	a4,a5,ffffffffc0205146 <proc_init+0x160>
}
ffffffffc0205104:	60e2                	ld	ra,24(sp)
ffffffffc0205106:	6442                	ld	s0,16(sp)
ffffffffc0205108:	64a2                	ld	s1,8(sp)
ffffffffc020510a:	6902                	ld	s2,0(sp)
ffffffffc020510c:	6105                	addi	sp,sp,32
ffffffffc020510e:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205110:	f2878793          	addi	a5,a5,-216
ffffffffc0205114:	b77d                	j	ffffffffc02050c2 <proc_init+0xdc>
        panic("create init_main failed.\n");
ffffffffc0205116:	00002617          	auipc	a2,0x2
ffffffffc020511a:	5fa60613          	addi	a2,a2,1530 # ffffffffc0207710 <etext+0x1c0c>
ffffffffc020511e:	40600593          	li	a1,1030
ffffffffc0205122:	00002517          	auipc	a0,0x2
ffffffffc0205126:	22650513          	addi	a0,a0,550 # ffffffffc0207348 <etext+0x1844>
ffffffffc020512a:	b64fb0ef          	jal	ffffffffc020048e <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc020512e:	00002617          	auipc	a2,0x2
ffffffffc0205132:	5c260613          	addi	a2,a2,1474 # ffffffffc02076f0 <etext+0x1bec>
ffffffffc0205136:	3f700593          	li	a1,1015
ffffffffc020513a:	00002517          	auipc	a0,0x2
ffffffffc020513e:	20e50513          	addi	a0,a0,526 # ffffffffc0207348 <etext+0x1844>
ffffffffc0205142:	b4cfb0ef          	jal	ffffffffc020048e <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205146:	00002697          	auipc	a3,0x2
ffffffffc020514a:	61a68693          	addi	a3,a3,1562 # ffffffffc0207760 <etext+0x1c5c>
ffffffffc020514e:	00001617          	auipc	a2,0x1
ffffffffc0205152:	45a60613          	addi	a2,a2,1114 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0205156:	40d00593          	li	a1,1037
ffffffffc020515a:	00002517          	auipc	a0,0x2
ffffffffc020515e:	1ee50513          	addi	a0,a0,494 # ffffffffc0207348 <etext+0x1844>
ffffffffc0205162:	b2cfb0ef          	jal	ffffffffc020048e <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205166:	00002697          	auipc	a3,0x2
ffffffffc020516a:	5d268693          	addi	a3,a3,1490 # ffffffffc0207738 <etext+0x1c34>
ffffffffc020516e:	00001617          	auipc	a2,0x1
ffffffffc0205172:	43a60613          	addi	a2,a2,1082 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0205176:	40c00593          	li	a1,1036
ffffffffc020517a:	00002517          	auipc	a0,0x2
ffffffffc020517e:	1ce50513          	addi	a0,a0,462 # ffffffffc0207348 <etext+0x1844>
ffffffffc0205182:	b0cfb0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0205186 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc0205186:	1141                	addi	sp,sp,-16
ffffffffc0205188:	e022                	sd	s0,0(sp)
ffffffffc020518a:	e406                	sd	ra,8(sp)
ffffffffc020518c:	000ac417          	auipc	s0,0xac
ffffffffc0205190:	38c40413          	addi	s0,s0,908 # ffffffffc02b1518 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc0205194:	6018                	ld	a4,0(s0)
ffffffffc0205196:	6f1c                	ld	a5,24(a4)
ffffffffc0205198:	dffd                	beqz	a5,ffffffffc0205196 <cpu_idle+0x10>
        {
            schedule();
ffffffffc020519a:	2f8000ef          	jal	ffffffffc0205492 <schedule>
ffffffffc020519e:	bfdd                	j	ffffffffc0205194 <cpu_idle+0xe>

ffffffffc02051a0 <lab6_set_priority>:
        }
    }
}
// FOR LAB6, set the process's priority (bigger value will get more CPU time)
void lab6_set_priority(uint32_t priority)
{
ffffffffc02051a0:	1101                	addi	sp,sp,-32
ffffffffc02051a2:	85aa                	mv	a1,a0
    cprintf("set priority to %d\n", priority);
ffffffffc02051a4:	e42a                	sd	a0,8(sp)
ffffffffc02051a6:	00002517          	auipc	a0,0x2
ffffffffc02051aa:	5e250513          	addi	a0,a0,1506 # ffffffffc0207788 <etext+0x1c84>
{
ffffffffc02051ae:	ec06                	sd	ra,24(sp)
    cprintf("set priority to %d\n", priority);
ffffffffc02051b0:	82cfb0ef          	jal	ffffffffc02001dc <cprintf>
    if (priority == 0)
ffffffffc02051b4:	65a2                	ld	a1,8(sp)
        current->lab6_priority = 1;
ffffffffc02051b6:	000ac717          	auipc	a4,0xac
ffffffffc02051ba:	36273703          	ld	a4,866(a4) # ffffffffc02b1518 <current>
    if (priority == 0)
ffffffffc02051be:	4785                	li	a5,1
ffffffffc02051c0:	c191                	beqz	a1,ffffffffc02051c4 <lab6_set_priority+0x24>
ffffffffc02051c2:	87ae                	mv	a5,a1
    else
        current->lab6_priority = priority;
}
ffffffffc02051c4:	60e2                	ld	ra,24(sp)
        current->lab6_priority = 1;
ffffffffc02051c6:	14f72223          	sw	a5,324(a4)
}
ffffffffc02051ca:	6105                	addi	sp,sp,32
ffffffffc02051cc:	8082                	ret

ffffffffc02051ce <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02051ce:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02051d2:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02051d6:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02051d8:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02051da:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02051de:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02051e2:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02051e6:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02051ea:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc02051ee:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc02051f2:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc02051f6:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc02051fa:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc02051fe:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205202:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205206:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020520a:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020520c:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc020520e:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205212:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205216:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020521a:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020521e:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205222:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205226:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020522a:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020522e:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205232:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205236:	8082                	ret

ffffffffc0205238 <RR_init>:
    elm->prev = elm->next = elm;
ffffffffc0205238:	e508                	sd	a0,8(a0)
ffffffffc020523a:	e108                	sd	a0,0(a0)
static void
RR_init(struct run_queue *rq)
{
    // LAB6: 2313411
    list_init(&(rq->run_list));
    rq->proc_num = 0;
ffffffffc020523c:	00052823          	sw	zero,16(a0)
}
ffffffffc0205240:	8082                	ret

ffffffffc0205242 <RR_pick_next>:
    return listelm->next;
ffffffffc0205242:	651c                	ld	a5,8(a0)
static struct proc_struct *
RR_pick_next(struct run_queue *rq)
{
    // LAB6: 2313411
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
ffffffffc0205244:	00f50563          	beq	a0,a5,ffffffffc020524e <RR_pick_next+0xc>
        return le2proc(le, run_link);
ffffffffc0205248:	ef078513          	addi	a0,a5,-272
ffffffffc020524c:	8082                	ret
    }
    return NULL;
ffffffffc020524e:	4501                	li	a0,0
}
ffffffffc0205250:	8082                	ret

ffffffffc0205252 <RR_proc_tick>:
 */
static void
RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    // LAB6: 2313411
    if (proc->time_slice > 0) {
ffffffffc0205252:	1205a783          	lw	a5,288(a1)
ffffffffc0205256:	00f05563          	blez	a5,ffffffffc0205260 <RR_proc_tick+0xe>
        proc->time_slice--;
ffffffffc020525a:	37fd                	addiw	a5,a5,-1
ffffffffc020525c:	12f5a023          	sw	a5,288(a1)
    }
    if (proc->time_slice == 0) {
ffffffffc0205260:	e399                	bnez	a5,ffffffffc0205266 <RR_proc_tick+0x14>
        proc->need_resched = 1;
ffffffffc0205262:	4785                	li	a5,1
ffffffffc0205264:	ed9c                	sd	a5,24(a1)
    }
}
ffffffffc0205266:	8082                	ret

ffffffffc0205268 <RR_dequeue>:
    return list->next == list;
ffffffffc0205268:	1185b703          	ld	a4,280(a1)
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
ffffffffc020526c:	11058793          	addi	a5,a1,272
ffffffffc0205270:	02e78263          	beq	a5,a4,ffffffffc0205294 <RR_dequeue+0x2c>
ffffffffc0205274:	1085b683          	ld	a3,264(a1)
ffffffffc0205278:	00a69e63          	bne	a3,a0,ffffffffc0205294 <RR_dequeue+0x2c>
    __list_del(listelm->prev, listelm->next);
ffffffffc020527c:	1105b503          	ld	a0,272(a1)
    rq->proc_num--;
ffffffffc0205280:	4a90                	lw	a2,16(a3)
    prev->next = next;
ffffffffc0205282:	e518                	sd	a4,8(a0)
    next->prev = prev;
ffffffffc0205284:	e308                	sd	a0,0(a4)
    elm->prev = elm->next = elm;
ffffffffc0205286:	10f5bc23          	sd	a5,280(a1)
ffffffffc020528a:	10f5b823          	sd	a5,272(a1)
ffffffffc020528e:	367d                	addiw	a2,a2,-1
ffffffffc0205290:	ca90                	sw	a2,16(a3)
ffffffffc0205292:	8082                	ret
{
ffffffffc0205294:	1141                	addi	sp,sp,-16
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
ffffffffc0205296:	00002697          	auipc	a3,0x2
ffffffffc020529a:	50a68693          	addi	a3,a3,1290 # ffffffffc02077a0 <etext+0x1c9c>
ffffffffc020529e:	00001617          	auipc	a2,0x1
ffffffffc02052a2:	30a60613          	addi	a2,a2,778 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc02052a6:	03d00593          	li	a1,61
ffffffffc02052aa:	00002517          	auipc	a0,0x2
ffffffffc02052ae:	52e50513          	addi	a0,a0,1326 # ffffffffc02077d8 <etext+0x1cd4>
{
ffffffffc02052b2:	e406                	sd	ra,8(sp)
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
ffffffffc02052b4:	9dafb0ef          	jal	ffffffffc020048e <__panic>

ffffffffc02052b8 <RR_enqueue>:
    assert(list_empty(&(proc->run_link)));
ffffffffc02052b8:	1185b703          	ld	a4,280(a1)
ffffffffc02052bc:	11058793          	addi	a5,a1,272
ffffffffc02052c0:	02e79d63          	bne	a5,a4,ffffffffc02052fa <RR_enqueue+0x42>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02052c4:	6118                	ld	a4,0(a0)
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
ffffffffc02052c6:	1205a683          	lw	a3,288(a1)
    prev->next = next->prev = elm;
ffffffffc02052ca:	e11c                	sd	a5,0(a0)
ffffffffc02052cc:	e71c                	sd	a5,8(a4)
    elm->prev = prev;
ffffffffc02052ce:	10e5b823          	sd	a4,272(a1)
    elm->next = next;
ffffffffc02052d2:	10a5bc23          	sd	a0,280(a1)
ffffffffc02052d6:	495c                	lw	a5,20(a0)
ffffffffc02052d8:	ea89                	bnez	a3,ffffffffc02052ea <RR_enqueue+0x32>
        proc->time_slice = rq->max_time_slice;
ffffffffc02052da:	12f5a023          	sw	a5,288(a1)
    rq->proc_num++;
ffffffffc02052de:	491c                	lw	a5,16(a0)
    proc->rq = rq;
ffffffffc02052e0:	10a5b423          	sd	a0,264(a1)
    rq->proc_num++;
ffffffffc02052e4:	2785                	addiw	a5,a5,1
ffffffffc02052e6:	c91c                	sw	a5,16(a0)
ffffffffc02052e8:	8082                	ret
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
ffffffffc02052ea:	fed7c8e3          	blt	a5,a3,ffffffffc02052da <RR_enqueue+0x22>
    rq->proc_num++;
ffffffffc02052ee:	491c                	lw	a5,16(a0)
    proc->rq = rq;
ffffffffc02052f0:	10a5b423          	sd	a0,264(a1)
    rq->proc_num++;
ffffffffc02052f4:	2785                	addiw	a5,a5,1
ffffffffc02052f6:	c91c                	sw	a5,16(a0)
ffffffffc02052f8:	8082                	ret
{
ffffffffc02052fa:	1141                	addi	sp,sp,-16
    assert(list_empty(&(proc->run_link)));
ffffffffc02052fc:	00002697          	auipc	a3,0x2
ffffffffc0205300:	4fc68693          	addi	a3,a3,1276 # ffffffffc02077f8 <etext+0x1cf4>
ffffffffc0205304:	00001617          	auipc	a2,0x1
ffffffffc0205308:	2a460613          	addi	a2,a2,676 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc020530c:	02900593          	li	a1,41
ffffffffc0205310:	00002517          	auipc	a0,0x2
ffffffffc0205314:	4c850513          	addi	a0,a0,1224 # ffffffffc02077d8 <etext+0x1cd4>
{
ffffffffc0205318:	e406                	sd	ra,8(sp)
    assert(list_empty(&(proc->run_link)));
ffffffffc020531a:	974fb0ef          	jal	ffffffffc020048e <__panic>

ffffffffc020531e <sched_class_proc_tick>:
    return sched_class->pick_next(rq);
}

void sched_class_proc_tick(struct proc_struct *proc)
{
    if (proc != idleproc)
ffffffffc020531e:	000ac797          	auipc	a5,0xac
ffffffffc0205322:	20a7b783          	ld	a5,522(a5) # ffffffffc02b1528 <idleproc>
{
ffffffffc0205326:	85aa                	mv	a1,a0
    if (proc != idleproc)
ffffffffc0205328:	00a78c63          	beq	a5,a0,ffffffffc0205340 <sched_class_proc_tick+0x22>
    {
        sched_class->proc_tick(rq, proc);
ffffffffc020532c:	000b0797          	auipc	a5,0xb0
ffffffffc0205330:	23c7b783          	ld	a5,572(a5) # ffffffffc02b5568 <sched_class>
ffffffffc0205334:	000b0517          	auipc	a0,0xb0
ffffffffc0205338:	22c53503          	ld	a0,556(a0) # ffffffffc02b5560 <rq>
ffffffffc020533c:	779c                	ld	a5,40(a5)
ffffffffc020533e:	8782                	jr	a5
    }
    else
    {
        proc->need_resched = 1;
ffffffffc0205340:	4705                	li	a4,1
ffffffffc0205342:	ef98                	sd	a4,24(a5)
    }
}
ffffffffc0205344:	8082                	ret

ffffffffc0205346 <sched_init>:

void sched_init(void)
{
    list_init(&timer_list);

    sched_class = &default_sched_class;  // RR 调度器
ffffffffc0205346:	000ac797          	auipc	a5,0xac
ffffffffc020534a:	d1278793          	addi	a5,a5,-750 # ffffffffc02b1058 <default_sched_class>
{
ffffffffc020534e:	1141                	addi	sp,sp,-16
    // sched_class = &stride_sched_class;  // Stride 调度器

    rq = &__rq;
    rq->max_time_slice = MAX_TIME_SLICE;
    sched_class->init(rq);
ffffffffc0205350:	6794                	ld	a3,8(a5)
    sched_class = &default_sched_class;  // RR 调度器
ffffffffc0205352:	000b0717          	auipc	a4,0xb0
ffffffffc0205356:	20f73b23          	sd	a5,534(a4) # ffffffffc02b5568 <sched_class>
{
ffffffffc020535a:	e406                	sd	ra,8(sp)
    elm->prev = elm->next = elm;
ffffffffc020535c:	000b0797          	auipc	a5,0xb0
ffffffffc0205360:	21478793          	addi	a5,a5,532 # ffffffffc02b5570 <timer_list>
    rq = &__rq;
ffffffffc0205364:	000b0717          	auipc	a4,0xb0
ffffffffc0205368:	1dc70713          	addi	a4,a4,476 # ffffffffc02b5540 <__rq>
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc020536c:	4615                	li	a2,5
ffffffffc020536e:	e79c                	sd	a5,8(a5)
ffffffffc0205370:	e39c                	sd	a5,0(a5)
    sched_class->init(rq);
ffffffffc0205372:	853a                	mv	a0,a4
    rq->max_time_slice = MAX_TIME_SLICE;
ffffffffc0205374:	cb50                	sw	a2,20(a4)
    rq = &__rq;
ffffffffc0205376:	000b0797          	auipc	a5,0xb0
ffffffffc020537a:	1ee7b523          	sd	a4,490(a5) # ffffffffc02b5560 <rq>
    sched_class->init(rq);
ffffffffc020537e:	9682                	jalr	a3

    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205380:	000b0797          	auipc	a5,0xb0
ffffffffc0205384:	1e87b783          	ld	a5,488(a5) # ffffffffc02b5568 <sched_class>
}
ffffffffc0205388:	60a2                	ld	ra,8(sp)
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc020538a:	00002517          	auipc	a0,0x2
ffffffffc020538e:	49e50513          	addi	a0,a0,1182 # ffffffffc0207828 <etext+0x1d24>
ffffffffc0205392:	638c                	ld	a1,0(a5)
}
ffffffffc0205394:	0141                	addi	sp,sp,16
    cprintf("sched class: %s\n", sched_class->name);
ffffffffc0205396:	e47fa06f          	j	ffffffffc02001dc <cprintf>

ffffffffc020539a <wakeup_proc>:

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020539a:	4118                	lw	a4,0(a0)
{
ffffffffc020539c:	1101                	addi	sp,sp,-32
ffffffffc020539e:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02053a0:	478d                	li	a5,3
ffffffffc02053a2:	0cf70863          	beq	a4,a5,ffffffffc0205472 <wakeup_proc+0xd8>
ffffffffc02053a6:	85aa                	mv	a1,a0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02053a8:	100027f3          	csrr	a5,sstatus
ffffffffc02053ac:	8b89                	andi	a5,a5,2
ffffffffc02053ae:	e3b1                	bnez	a5,ffffffffc02053f2 <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc02053b0:	4789                	li	a5,2
ffffffffc02053b2:	08f70563          	beq	a4,a5,ffffffffc020543c <wakeup_proc+0xa2>
        {
            proc->state = PROC_RUNNABLE;
            proc->wait_state = 0;
            if (proc != current)
ffffffffc02053b6:	000ac717          	auipc	a4,0xac
ffffffffc02053ba:	16273703          	ld	a4,354(a4) # ffffffffc02b1518 <current>
            proc->wait_state = 0;
ffffffffc02053be:	0e052623          	sw	zero,236(a0)
            proc->state = PROC_RUNNABLE;
ffffffffc02053c2:	c11c                	sw	a5,0(a0)
            if (proc != current)
ffffffffc02053c4:	02e50463          	beq	a0,a4,ffffffffc02053ec <wakeup_proc+0x52>
    if (proc != idleproc)
ffffffffc02053c8:	000ac797          	auipc	a5,0xac
ffffffffc02053cc:	1607b783          	ld	a5,352(a5) # ffffffffc02b1528 <idleproc>
ffffffffc02053d0:	00f50e63          	beq	a0,a5,ffffffffc02053ec <wakeup_proc+0x52>
        sched_class->enqueue(rq, proc);
ffffffffc02053d4:	000b0797          	auipc	a5,0xb0
ffffffffc02053d8:	1947b783          	ld	a5,404(a5) # ffffffffc02b5568 <sched_class>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02053dc:	60e2                	ld	ra,24(sp)
        sched_class->enqueue(rq, proc);
ffffffffc02053de:	000b0517          	auipc	a0,0xb0
ffffffffc02053e2:	18253503          	ld	a0,386(a0) # ffffffffc02b5560 <rq>
ffffffffc02053e6:	6b9c                	ld	a5,16(a5)
}
ffffffffc02053e8:	6105                	addi	sp,sp,32
        sched_class->enqueue(rq, proc);
ffffffffc02053ea:	8782                	jr	a5
}
ffffffffc02053ec:	60e2                	ld	ra,24(sp)
ffffffffc02053ee:	6105                	addi	sp,sp,32
ffffffffc02053f0:	8082                	ret
        intr_disable();
ffffffffc02053f2:	e42a                	sd	a0,8(sp)
ffffffffc02053f4:	e08fb0ef          	jal	ffffffffc02009fc <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc02053f8:	65a2                	ld	a1,8(sp)
ffffffffc02053fa:	4789                	li	a5,2
ffffffffc02053fc:	4198                	lw	a4,0(a1)
ffffffffc02053fe:	04f70d63          	beq	a4,a5,ffffffffc0205458 <wakeup_proc+0xbe>
            if (proc != current)
ffffffffc0205402:	000ac717          	auipc	a4,0xac
ffffffffc0205406:	11673703          	ld	a4,278(a4) # ffffffffc02b1518 <current>
            proc->wait_state = 0;
ffffffffc020540a:	0e05a623          	sw	zero,236(a1)
            proc->state = PROC_RUNNABLE;
ffffffffc020540e:	c19c                	sw	a5,0(a1)
            if (proc != current)
ffffffffc0205410:	02e58263          	beq	a1,a4,ffffffffc0205434 <wakeup_proc+0x9a>
    if (proc != idleproc)
ffffffffc0205414:	000ac797          	auipc	a5,0xac
ffffffffc0205418:	1147b783          	ld	a5,276(a5) # ffffffffc02b1528 <idleproc>
ffffffffc020541c:	00f58c63          	beq	a1,a5,ffffffffc0205434 <wakeup_proc+0x9a>
        sched_class->enqueue(rq, proc);
ffffffffc0205420:	000b0797          	auipc	a5,0xb0
ffffffffc0205424:	1487b783          	ld	a5,328(a5) # ffffffffc02b5568 <sched_class>
ffffffffc0205428:	000b0517          	auipc	a0,0xb0
ffffffffc020542c:	13853503          	ld	a0,312(a0) # ffffffffc02b5560 <rq>
ffffffffc0205430:	6b9c                	ld	a5,16(a5)
ffffffffc0205432:	9782                	jalr	a5
}
ffffffffc0205434:	60e2                	ld	ra,24(sp)
ffffffffc0205436:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205438:	dbefb06f          	j	ffffffffc02009f6 <intr_enable>
ffffffffc020543c:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc020543e:	00002617          	auipc	a2,0x2
ffffffffc0205442:	43a60613          	addi	a2,a2,1082 # ffffffffc0207878 <etext+0x1d74>
ffffffffc0205446:	05200593          	li	a1,82
ffffffffc020544a:	00002517          	auipc	a0,0x2
ffffffffc020544e:	41650513          	addi	a0,a0,1046 # ffffffffc0207860 <etext+0x1d5c>
}
ffffffffc0205452:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc0205454:	8a4fb06f          	j	ffffffffc02004f8 <__warn>
ffffffffc0205458:	00002617          	auipc	a2,0x2
ffffffffc020545c:	42060613          	addi	a2,a2,1056 # ffffffffc0207878 <etext+0x1d74>
ffffffffc0205460:	05200593          	li	a1,82
ffffffffc0205464:	00002517          	auipc	a0,0x2
ffffffffc0205468:	3fc50513          	addi	a0,a0,1020 # ffffffffc0207860 <etext+0x1d5c>
ffffffffc020546c:	88cfb0ef          	jal	ffffffffc02004f8 <__warn>
    if (flag)
ffffffffc0205470:	b7d1                	j	ffffffffc0205434 <wakeup_proc+0x9a>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205472:	00002697          	auipc	a3,0x2
ffffffffc0205476:	3ce68693          	addi	a3,a3,974 # ffffffffc0207840 <etext+0x1d3c>
ffffffffc020547a:	00001617          	auipc	a2,0x1
ffffffffc020547e:	12e60613          	addi	a2,a2,302 # ffffffffc02065a8 <etext+0xaa4>
ffffffffc0205482:	04300593          	li	a1,67
ffffffffc0205486:	00002517          	auipc	a0,0x2
ffffffffc020548a:	3da50513          	addi	a0,a0,986 # ffffffffc0207860 <etext+0x1d5c>
ffffffffc020548e:	800fb0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0205492 <schedule>:

void schedule(void)
{
ffffffffc0205492:	7139                	addi	sp,sp,-64
ffffffffc0205494:	fc06                	sd	ra,56(sp)
ffffffffc0205496:	f822                	sd	s0,48(sp)
ffffffffc0205498:	f426                	sd	s1,40(sp)
ffffffffc020549a:	f04a                	sd	s2,32(sp)
ffffffffc020549c:	ec4e                	sd	s3,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020549e:	100027f3          	csrr	a5,sstatus
ffffffffc02054a2:	8b89                	andi	a5,a5,2
ffffffffc02054a4:	4981                	li	s3,0
ffffffffc02054a6:	efc9                	bnez	a5,ffffffffc0205540 <schedule+0xae>
    bool intr_flag;
    struct proc_struct *next;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02054a8:	000ac417          	auipc	s0,0xac
ffffffffc02054ac:	07040413          	addi	s0,s0,112 # ffffffffc02b1518 <current>
ffffffffc02054b0:	600c                	ld	a1,0(s0)
        if (current->state == PROC_RUNNABLE)
ffffffffc02054b2:	4789                	li	a5,2
ffffffffc02054b4:	000b0497          	auipc	s1,0xb0
ffffffffc02054b8:	0ac48493          	addi	s1,s1,172 # ffffffffc02b5560 <rq>
ffffffffc02054bc:	4198                	lw	a4,0(a1)
        current->need_resched = 0;
ffffffffc02054be:	0005bc23          	sd	zero,24(a1)
        if (current->state == PROC_RUNNABLE)
ffffffffc02054c2:	000b0917          	auipc	s2,0xb0
ffffffffc02054c6:	0a690913          	addi	s2,s2,166 # ffffffffc02b5568 <sched_class>
ffffffffc02054ca:	04f70f63          	beq	a4,a5,ffffffffc0205528 <schedule+0x96>
    return sched_class->pick_next(rq);
ffffffffc02054ce:	00093783          	ld	a5,0(s2)
ffffffffc02054d2:	6088                	ld	a0,0(s1)
ffffffffc02054d4:	739c                	ld	a5,32(a5)
ffffffffc02054d6:	9782                	jalr	a5
ffffffffc02054d8:	85aa                	mv	a1,a0
        {
            sched_class_enqueue(current);
        }
        if ((next = sched_class_pick_next()) != NULL)
ffffffffc02054da:	c131                	beqz	a0,ffffffffc020551e <schedule+0x8c>
    sched_class->dequeue(rq, proc);
ffffffffc02054dc:	00093783          	ld	a5,0(s2)
ffffffffc02054e0:	6088                	ld	a0,0(s1)
ffffffffc02054e2:	e42e                	sd	a1,8(sp)
ffffffffc02054e4:	6f9c                	ld	a5,24(a5)
ffffffffc02054e6:	9782                	jalr	a5
ffffffffc02054e8:	65a2                	ld	a1,8(sp)
        }
        if (next == NULL)
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc02054ea:	459c                	lw	a5,8(a1)
        if (next != current)
ffffffffc02054ec:	6018                	ld	a4,0(s0)
        next->runs++;
ffffffffc02054ee:	2785                	addiw	a5,a5,1
ffffffffc02054f0:	c59c                	sw	a5,8(a1)
        if (next != current)
ffffffffc02054f2:	00b70563          	beq	a4,a1,ffffffffc02054fc <schedule+0x6a>
        {
            proc_run(next);
ffffffffc02054f6:	852e                	mv	a0,a1
ffffffffc02054f8:	aaffe0ef          	jal	ffffffffc0203fa6 <proc_run>
    if (flag)
ffffffffc02054fc:	00099963          	bnez	s3,ffffffffc020550e <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205500:	70e2                	ld	ra,56(sp)
ffffffffc0205502:	7442                	ld	s0,48(sp)
ffffffffc0205504:	74a2                	ld	s1,40(sp)
ffffffffc0205506:	7902                	ld	s2,32(sp)
ffffffffc0205508:	69e2                	ld	s3,24(sp)
ffffffffc020550a:	6121                	addi	sp,sp,64
ffffffffc020550c:	8082                	ret
ffffffffc020550e:	7442                	ld	s0,48(sp)
ffffffffc0205510:	70e2                	ld	ra,56(sp)
ffffffffc0205512:	74a2                	ld	s1,40(sp)
ffffffffc0205514:	7902                	ld	s2,32(sp)
ffffffffc0205516:	69e2                	ld	s3,24(sp)
ffffffffc0205518:	6121                	addi	sp,sp,64
        intr_enable();
ffffffffc020551a:	cdcfb06f          	j	ffffffffc02009f6 <intr_enable>
            next = idleproc;
ffffffffc020551e:	000ac597          	auipc	a1,0xac
ffffffffc0205522:	00a5b583          	ld	a1,10(a1) # ffffffffc02b1528 <idleproc>
ffffffffc0205526:	b7d1                	j	ffffffffc02054ea <schedule+0x58>
    if (proc != idleproc)
ffffffffc0205528:	000ac797          	auipc	a5,0xac
ffffffffc020552c:	0007b783          	ld	a5,0(a5) # ffffffffc02b1528 <idleproc>
ffffffffc0205530:	f8f58fe3          	beq	a1,a5,ffffffffc02054ce <schedule+0x3c>
        sched_class->enqueue(rq, proc);
ffffffffc0205534:	00093783          	ld	a5,0(s2)
ffffffffc0205538:	6088                	ld	a0,0(s1)
ffffffffc020553a:	6b9c                	ld	a5,16(a5)
ffffffffc020553c:	9782                	jalr	a5
ffffffffc020553e:	bf41                	j	ffffffffc02054ce <schedule+0x3c>
        intr_disable();
ffffffffc0205540:	cbcfb0ef          	jal	ffffffffc02009fc <intr_disable>
        return 1;
ffffffffc0205544:	4985                	li	s3,1
ffffffffc0205546:	b78d                	j	ffffffffc02054a8 <schedule+0x16>

ffffffffc0205548 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205548:	000ac797          	auipc	a5,0xac
ffffffffc020554c:	fd07b783          	ld	a5,-48(a5) # ffffffffc02b1518 <current>
}
ffffffffc0205550:	43c8                	lw	a0,4(a5)
ffffffffc0205552:	8082                	ret

ffffffffc0205554 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205554:	4501                	li	a0,0
ffffffffc0205556:	8082                	ret

ffffffffc0205558 <sys_gettime>:
static int sys_gettime(uint64_t arg[]){
    return (int)ticks*10;
ffffffffc0205558:	000ac797          	auipc	a5,0xac
ffffffffc020555c:	f487b783          	ld	a5,-184(a5) # ffffffffc02b14a0 <ticks>
ffffffffc0205560:	0027951b          	slliw	a0,a5,0x2
ffffffffc0205564:	9d3d                	addw	a0,a0,a5
ffffffffc0205566:	0015151b          	slliw	a0,a0,0x1
}
ffffffffc020556a:	8082                	ret

ffffffffc020556c <sys_lab6_set_priority>:
static int sys_lab6_set_priority(uint64_t arg[]){
    uint64_t priority = (uint64_t)arg[0];
    lab6_set_priority(priority);
ffffffffc020556c:	4108                	lw	a0,0(a0)
static int sys_lab6_set_priority(uint64_t arg[]){
ffffffffc020556e:	1141                	addi	sp,sp,-16
ffffffffc0205570:	e406                	sd	ra,8(sp)
    lab6_set_priority(priority);
ffffffffc0205572:	c2fff0ef          	jal	ffffffffc02051a0 <lab6_set_priority>
    return 0;
}
ffffffffc0205576:	60a2                	ld	ra,8(sp)
ffffffffc0205578:	4501                	li	a0,0
ffffffffc020557a:	0141                	addi	sp,sp,16
ffffffffc020557c:	8082                	ret

ffffffffc020557e <sys_putc>:
    cputchar(c);
ffffffffc020557e:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205580:	1141                	addi	sp,sp,-16
ffffffffc0205582:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc0205584:	c8dfa0ef          	jal	ffffffffc0200210 <cputchar>
}
ffffffffc0205588:	60a2                	ld	ra,8(sp)
ffffffffc020558a:	4501                	li	a0,0
ffffffffc020558c:	0141                	addi	sp,sp,16
ffffffffc020558e:	8082                	ret

ffffffffc0205590 <sys_kill>:
    return do_kill(pid);
ffffffffc0205590:	4108                	lw	a0,0(a0)
ffffffffc0205592:	9ddff06f          	j	ffffffffc0204f6e <do_kill>

ffffffffc0205596 <sys_yield>:
    return do_yield();
ffffffffc0205596:	98fff06f          	j	ffffffffc0204f24 <do_yield>

ffffffffc020559a <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc020559a:	6d14                	ld	a3,24(a0)
ffffffffc020559c:	6910                	ld	a2,16(a0)
ffffffffc020559e:	650c                	ld	a1,8(a0)
ffffffffc02055a0:	6108                	ld	a0,0(a0)
ffffffffc02055a2:	b5aff06f          	j	ffffffffc02048fc <do_execve>

ffffffffc02055a6 <sys_wait>:
    return do_wait(pid, store);
ffffffffc02055a6:	650c                	ld	a1,8(a0)
ffffffffc02055a8:	4108                	lw	a0,0(a0)
ffffffffc02055aa:	98bff06f          	j	ffffffffc0204f34 <do_wait>

ffffffffc02055ae <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02055ae:	000ac797          	auipc	a5,0xac
ffffffffc02055b2:	f6a7b783          	ld	a5,-150(a5) # ffffffffc02b1518 <current>
    return do_fork(0, stack, tf);
ffffffffc02055b6:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc02055b8:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02055ba:	6a0c                	ld	a1,16(a2)
ffffffffc02055bc:	a61fe06f          	j	ffffffffc020401c <do_fork>

ffffffffc02055c0 <sys_exit>:
    return do_exit(error_code);
ffffffffc02055c0:	4108                	lw	a0,0(a0)
ffffffffc02055c2:	ef1fe06f          	j	ffffffffc02044b2 <do_exit>

ffffffffc02055c6 <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc02055c6:	000ac697          	auipc	a3,0xac
ffffffffc02055ca:	f526b683          	ld	a3,-174(a3) # ffffffffc02b1518 <current>
syscall(void) {
ffffffffc02055ce:	715d                	addi	sp,sp,-80
ffffffffc02055d0:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc02055d2:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc02055d4:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02055d6:	0ff00793          	li	a5,255
    int num = tf->gpr.a0;
ffffffffc02055da:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02055dc:	02d7ec63          	bltu	a5,a3,ffffffffc0205614 <syscall+0x4e>
        if (syscalls[num] != NULL) {
ffffffffc02055e0:	00002797          	auipc	a5,0x2
ffffffffc02055e4:	4e078793          	addi	a5,a5,1248 # ffffffffc0207ac0 <syscalls>
ffffffffc02055e8:	00369613          	slli	a2,a3,0x3
ffffffffc02055ec:	97b2                	add	a5,a5,a2
ffffffffc02055ee:	639c                	ld	a5,0(a5)
ffffffffc02055f0:	c395                	beqz	a5,ffffffffc0205614 <syscall+0x4e>
            arg[0] = tf->gpr.a1;
ffffffffc02055f2:	7028                	ld	a0,96(s0)
ffffffffc02055f4:	742c                	ld	a1,104(s0)
ffffffffc02055f6:	7830                	ld	a2,112(s0)
ffffffffc02055f8:	7c34                	ld	a3,120(s0)
ffffffffc02055fa:	6c38                	ld	a4,88(s0)
ffffffffc02055fc:	f02a                	sd	a0,32(sp)
ffffffffc02055fe:	f42e                	sd	a1,40(sp)
ffffffffc0205600:	f832                	sd	a2,48(sp)
ffffffffc0205602:	fc36                	sd	a3,56(sp)
ffffffffc0205604:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205606:	0828                	addi	a0,sp,24
ffffffffc0205608:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020560a:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020560c:	e828                	sd	a0,80(s0)
}
ffffffffc020560e:	6406                	ld	s0,64(sp)
ffffffffc0205610:	6161                	addi	sp,sp,80
ffffffffc0205612:	8082                	ret
    print_trapframe(tf);
ffffffffc0205614:	8522                	mv	a0,s0
ffffffffc0205616:	e436                	sd	a3,8(sp)
ffffffffc0205618:	dd4fb0ef          	jal	ffffffffc0200bec <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc020561c:	000ac797          	auipc	a5,0xac
ffffffffc0205620:	efc7b783          	ld	a5,-260(a5) # ffffffffc02b1518 <current>
ffffffffc0205624:	66a2                	ld	a3,8(sp)
ffffffffc0205626:	00002617          	auipc	a2,0x2
ffffffffc020562a:	27260613          	addi	a2,a2,626 # ffffffffc0207898 <etext+0x1d94>
ffffffffc020562e:	43d8                	lw	a4,4(a5)
ffffffffc0205630:	06c00593          	li	a1,108
ffffffffc0205634:	0b478793          	addi	a5,a5,180
ffffffffc0205638:	00002517          	auipc	a0,0x2
ffffffffc020563c:	29050513          	addi	a0,a0,656 # ffffffffc02078c8 <etext+0x1dc4>
ffffffffc0205640:	e4ffa0ef          	jal	ffffffffc020048e <__panic>

ffffffffc0205644 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205644:	9e3707b7          	lui	a5,0x9e370
ffffffffc0205648:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_matrix_out_size+0xffffffff9e364ad9>
ffffffffc020564a:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc020564e:	02000513          	li	a0,32
ffffffffc0205652:	9d0d                	subw	a0,a0,a1
}
ffffffffc0205654:	00a7d53b          	srlw	a0,a5,a0
ffffffffc0205658:	8082                	ret

ffffffffc020565a <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020565a:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020565c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205660:	f022                	sd	s0,32(sp)
ffffffffc0205662:	ec26                	sd	s1,24(sp)
ffffffffc0205664:	e84a                	sd	s2,16(sp)
ffffffffc0205666:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205668:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020566c:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc020566e:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205672:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205676:	84aa                	mv	s1,a0
ffffffffc0205678:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc020567a:	03067d63          	bgeu	a2,a6,ffffffffc02056b4 <printnum+0x5a>
ffffffffc020567e:	e44e                	sd	s3,8(sp)
ffffffffc0205680:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205682:	4785                	li	a5,1
ffffffffc0205684:	00e7d763          	bge	a5,a4,ffffffffc0205692 <printnum+0x38>
            putch(padc, putdat);
ffffffffc0205688:	85ca                	mv	a1,s2
ffffffffc020568a:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc020568c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020568e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205690:	fc65                	bnez	s0,ffffffffc0205688 <printnum+0x2e>
ffffffffc0205692:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205694:	00002797          	auipc	a5,0x2
ffffffffc0205698:	24c78793          	addi	a5,a5,588 # ffffffffc02078e0 <etext+0x1ddc>
ffffffffc020569c:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020569e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02056a0:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02056a4:	70a2                	ld	ra,40(sp)
ffffffffc02056a6:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02056a8:	85ca                	mv	a1,s2
ffffffffc02056aa:	87a6                	mv	a5,s1
}
ffffffffc02056ac:	6942                	ld	s2,16(sp)
ffffffffc02056ae:	64e2                	ld	s1,24(sp)
ffffffffc02056b0:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02056b2:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02056b4:	03065633          	divu	a2,a2,a6
ffffffffc02056b8:	8722                	mv	a4,s0
ffffffffc02056ba:	fa1ff0ef          	jal	ffffffffc020565a <printnum>
ffffffffc02056be:	bfd9                	j	ffffffffc0205694 <printnum+0x3a>

ffffffffc02056c0 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02056c0:	7119                	addi	sp,sp,-128
ffffffffc02056c2:	f4a6                	sd	s1,104(sp)
ffffffffc02056c4:	f0ca                	sd	s2,96(sp)
ffffffffc02056c6:	ecce                	sd	s3,88(sp)
ffffffffc02056c8:	e8d2                	sd	s4,80(sp)
ffffffffc02056ca:	e4d6                	sd	s5,72(sp)
ffffffffc02056cc:	e0da                	sd	s6,64(sp)
ffffffffc02056ce:	f862                	sd	s8,48(sp)
ffffffffc02056d0:	fc86                	sd	ra,120(sp)
ffffffffc02056d2:	f8a2                	sd	s0,112(sp)
ffffffffc02056d4:	fc5e                	sd	s7,56(sp)
ffffffffc02056d6:	f466                	sd	s9,40(sp)
ffffffffc02056d8:	f06a                	sd	s10,32(sp)
ffffffffc02056da:	ec6e                	sd	s11,24(sp)
ffffffffc02056dc:	84aa                	mv	s1,a0
ffffffffc02056de:	8c32                	mv	s8,a2
ffffffffc02056e0:	8a36                	mv	s4,a3
ffffffffc02056e2:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02056e4:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056e8:	05500b13          	li	s6,85
ffffffffc02056ec:	00003a97          	auipc	s5,0x3
ffffffffc02056f0:	bd4a8a93          	addi	s5,s5,-1068 # ffffffffc02082c0 <syscalls+0x800>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02056f4:	000c4503          	lbu	a0,0(s8)
ffffffffc02056f8:	001c0413          	addi	s0,s8,1
ffffffffc02056fc:	01350a63          	beq	a0,s3,ffffffffc0205710 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0205700:	cd0d                	beqz	a0,ffffffffc020573a <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0205702:	85ca                	mv	a1,s2
ffffffffc0205704:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0205706:	00044503          	lbu	a0,0(s0)
ffffffffc020570a:	0405                	addi	s0,s0,1
ffffffffc020570c:	ff351ae3          	bne	a0,s3,ffffffffc0205700 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0205710:	5cfd                	li	s9,-1
ffffffffc0205712:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0205714:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0205718:	4b81                	li	s7,0
ffffffffc020571a:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020571c:	00044683          	lbu	a3,0(s0)
ffffffffc0205720:	00140c13          	addi	s8,s0,1
ffffffffc0205724:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0205728:	0ff5f593          	zext.b	a1,a1
ffffffffc020572c:	02bb6663          	bltu	s6,a1,ffffffffc0205758 <vprintfmt+0x98>
ffffffffc0205730:	058a                	slli	a1,a1,0x2
ffffffffc0205732:	95d6                	add	a1,a1,s5
ffffffffc0205734:	4198                	lw	a4,0(a1)
ffffffffc0205736:	9756                	add	a4,a4,s5
ffffffffc0205738:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020573a:	70e6                	ld	ra,120(sp)
ffffffffc020573c:	7446                	ld	s0,112(sp)
ffffffffc020573e:	74a6                	ld	s1,104(sp)
ffffffffc0205740:	7906                	ld	s2,96(sp)
ffffffffc0205742:	69e6                	ld	s3,88(sp)
ffffffffc0205744:	6a46                	ld	s4,80(sp)
ffffffffc0205746:	6aa6                	ld	s5,72(sp)
ffffffffc0205748:	6b06                	ld	s6,64(sp)
ffffffffc020574a:	7be2                	ld	s7,56(sp)
ffffffffc020574c:	7c42                	ld	s8,48(sp)
ffffffffc020574e:	7ca2                	ld	s9,40(sp)
ffffffffc0205750:	7d02                	ld	s10,32(sp)
ffffffffc0205752:	6de2                	ld	s11,24(sp)
ffffffffc0205754:	6109                	addi	sp,sp,128
ffffffffc0205756:	8082                	ret
            putch('%', putdat);
ffffffffc0205758:	85ca                	mv	a1,s2
ffffffffc020575a:	02500513          	li	a0,37
ffffffffc020575e:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205760:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205764:	02500713          	li	a4,37
ffffffffc0205768:	8c22                	mv	s8,s0
ffffffffc020576a:	f8e785e3          	beq	a5,a4,ffffffffc02056f4 <vprintfmt+0x34>
ffffffffc020576e:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0205772:	1c7d                	addi	s8,s8,-1
ffffffffc0205774:	fee79de3          	bne	a5,a4,ffffffffc020576e <vprintfmt+0xae>
ffffffffc0205778:	bfb5                	j	ffffffffc02056f4 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc020577a:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc020577e:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0205780:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0205784:	fd06071b          	addiw	a4,a2,-48
ffffffffc0205788:	24e56a63          	bltu	a0,a4,ffffffffc02059dc <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc020578c:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020578e:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0205790:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0205794:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0205798:	0197073b          	addw	a4,a4,s9
ffffffffc020579c:	0017171b          	slliw	a4,a4,0x1
ffffffffc02057a0:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc02057a2:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02057a6:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02057a8:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02057ac:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc02057b0:	feb570e3          	bgeu	a0,a1,ffffffffc0205790 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc02057b4:	f60d54e3          	bgez	s10,ffffffffc020571c <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02057b8:	8d66                	mv	s10,s9
ffffffffc02057ba:	5cfd                	li	s9,-1
ffffffffc02057bc:	b785                	j	ffffffffc020571c <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02057be:	8db6                	mv	s11,a3
ffffffffc02057c0:	8462                	mv	s0,s8
ffffffffc02057c2:	bfa9                	j	ffffffffc020571c <vprintfmt+0x5c>
ffffffffc02057c4:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc02057c6:	4b85                	li	s7,1
            goto reswitch;
ffffffffc02057c8:	bf91                	j	ffffffffc020571c <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02057ca:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02057cc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02057d0:	00f74463          	blt	a4,a5,ffffffffc02057d8 <vprintfmt+0x118>
    else if (lflag) {
ffffffffc02057d4:	1a078763          	beqz	a5,ffffffffc0205982 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc02057d8:	000a3603          	ld	a2,0(s4)
ffffffffc02057dc:	46c1                	li	a3,16
ffffffffc02057de:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02057e0:	000d879b          	sext.w	a5,s11
ffffffffc02057e4:	876a                	mv	a4,s10
ffffffffc02057e6:	85ca                	mv	a1,s2
ffffffffc02057e8:	8526                	mv	a0,s1
ffffffffc02057ea:	e71ff0ef          	jal	ffffffffc020565a <printnum>
            break;
ffffffffc02057ee:	b719                	j	ffffffffc02056f4 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc02057f0:	000a2503          	lw	a0,0(s4)
ffffffffc02057f4:	85ca                	mv	a1,s2
ffffffffc02057f6:	0a21                	addi	s4,s4,8
ffffffffc02057f8:	9482                	jalr	s1
            break;
ffffffffc02057fa:	bded                	j	ffffffffc02056f4 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02057fc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02057fe:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205802:	00f74463          	blt	a4,a5,ffffffffc020580a <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0205806:	16078963          	beqz	a5,ffffffffc0205978 <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc020580a:	000a3603          	ld	a2,0(s4)
ffffffffc020580e:	46a9                	li	a3,10
ffffffffc0205810:	8a2e                	mv	s4,a1
ffffffffc0205812:	b7f9                	j	ffffffffc02057e0 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0205814:	85ca                	mv	a1,s2
ffffffffc0205816:	03000513          	li	a0,48
ffffffffc020581a:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc020581c:	85ca                	mv	a1,s2
ffffffffc020581e:	07800513          	li	a0,120
ffffffffc0205822:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205824:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0205828:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020582a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020582c:	bf55                	j	ffffffffc02057e0 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc020582e:	85ca                	mv	a1,s2
ffffffffc0205830:	02500513          	li	a0,37
ffffffffc0205834:	9482                	jalr	s1
            break;
ffffffffc0205836:	bd7d                	j	ffffffffc02056f4 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0205838:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020583c:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc020583e:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0205840:	bf95                	j	ffffffffc02057b4 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0205842:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205844:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205848:	00f74463          	blt	a4,a5,ffffffffc0205850 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc020584c:	12078163          	beqz	a5,ffffffffc020596e <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0205850:	000a3603          	ld	a2,0(s4)
ffffffffc0205854:	46a1                	li	a3,8
ffffffffc0205856:	8a2e                	mv	s4,a1
ffffffffc0205858:	b761                	j	ffffffffc02057e0 <vprintfmt+0x120>
            if (width < 0)
ffffffffc020585a:	876a                	mv	a4,s10
ffffffffc020585c:	000d5363          	bgez	s10,ffffffffc0205862 <vprintfmt+0x1a2>
ffffffffc0205860:	4701                	li	a4,0
ffffffffc0205862:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205866:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0205868:	bd55                	j	ffffffffc020571c <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc020586a:	000d841b          	sext.w	s0,s11
ffffffffc020586e:	fd340793          	addi	a5,s0,-45
ffffffffc0205872:	00f037b3          	snez	a5,a5
ffffffffc0205876:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020587a:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc020587e:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205880:	008a0793          	addi	a5,s4,8
ffffffffc0205884:	e43e                	sd	a5,8(sp)
ffffffffc0205886:	100d8c63          	beqz	s11,ffffffffc020599e <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc020588a:	12071363          	bnez	a4,ffffffffc02059b0 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020588e:	000dc783          	lbu	a5,0(s11)
ffffffffc0205892:	0007851b          	sext.w	a0,a5
ffffffffc0205896:	c78d                	beqz	a5,ffffffffc02058c0 <vprintfmt+0x200>
ffffffffc0205898:	0d85                	addi	s11,s11,1
ffffffffc020589a:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020589c:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02058a0:	000cc563          	bltz	s9,ffffffffc02058aa <vprintfmt+0x1ea>
ffffffffc02058a4:	3cfd                	addiw	s9,s9,-1
ffffffffc02058a6:	008c8d63          	beq	s9,s0,ffffffffc02058c0 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02058aa:	020b9663          	bnez	s7,ffffffffc02058d6 <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc02058ae:	85ca                	mv	a1,s2
ffffffffc02058b0:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02058b2:	000dc783          	lbu	a5,0(s11)
ffffffffc02058b6:	0d85                	addi	s11,s11,1
ffffffffc02058b8:	3d7d                	addiw	s10,s10,-1
ffffffffc02058ba:	0007851b          	sext.w	a0,a5
ffffffffc02058be:	f3ed                	bnez	a5,ffffffffc02058a0 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc02058c0:	01a05963          	blez	s10,ffffffffc02058d2 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc02058c4:	85ca                	mv	a1,s2
ffffffffc02058c6:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02058ca:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc02058cc:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc02058ce:	fe0d1be3          	bnez	s10,ffffffffc02058c4 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02058d2:	6a22                	ld	s4,8(sp)
ffffffffc02058d4:	b505                	j	ffffffffc02056f4 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02058d6:	3781                	addiw	a5,a5,-32
ffffffffc02058d8:	fcfa7be3          	bgeu	s4,a5,ffffffffc02058ae <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc02058dc:	03f00513          	li	a0,63
ffffffffc02058e0:	85ca                	mv	a1,s2
ffffffffc02058e2:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02058e4:	000dc783          	lbu	a5,0(s11)
ffffffffc02058e8:	0d85                	addi	s11,s11,1
ffffffffc02058ea:	3d7d                	addiw	s10,s10,-1
ffffffffc02058ec:	0007851b          	sext.w	a0,a5
ffffffffc02058f0:	dbe1                	beqz	a5,ffffffffc02058c0 <vprintfmt+0x200>
ffffffffc02058f2:	fa0cd9e3          	bgez	s9,ffffffffc02058a4 <vprintfmt+0x1e4>
ffffffffc02058f6:	b7c5                	j	ffffffffc02058d6 <vprintfmt+0x216>
            if (err < 0) {
ffffffffc02058f8:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02058fc:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc02058fe:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205900:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0205904:	8fb9                	xor	a5,a5,a4
ffffffffc0205906:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020590a:	02d64563          	blt	a2,a3,ffffffffc0205934 <vprintfmt+0x274>
ffffffffc020590e:	00003797          	auipc	a5,0x3
ffffffffc0205912:	b0a78793          	addi	a5,a5,-1270 # ffffffffc0208418 <error_string>
ffffffffc0205916:	00369713          	slli	a4,a3,0x3
ffffffffc020591a:	97ba                	add	a5,a5,a4
ffffffffc020591c:	639c                	ld	a5,0(a5)
ffffffffc020591e:	cb99                	beqz	a5,ffffffffc0205934 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205920:	86be                	mv	a3,a5
ffffffffc0205922:	00000617          	auipc	a2,0x0
ffffffffc0205926:	20e60613          	addi	a2,a2,526 # ffffffffc0205b30 <etext+0x2c>
ffffffffc020592a:	85ca                	mv	a1,s2
ffffffffc020592c:	8526                	mv	a0,s1
ffffffffc020592e:	0d8000ef          	jal	ffffffffc0205a06 <printfmt>
ffffffffc0205932:	b3c9                	j	ffffffffc02056f4 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205934:	00002617          	auipc	a2,0x2
ffffffffc0205938:	fcc60613          	addi	a2,a2,-52 # ffffffffc0207900 <etext+0x1dfc>
ffffffffc020593c:	85ca                	mv	a1,s2
ffffffffc020593e:	8526                	mv	a0,s1
ffffffffc0205940:	0c6000ef          	jal	ffffffffc0205a06 <printfmt>
ffffffffc0205944:	bb45                	j	ffffffffc02056f4 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0205946:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205948:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc020594c:	00f74363          	blt	a4,a5,ffffffffc0205952 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0205950:	cf81                	beqz	a5,ffffffffc0205968 <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0205952:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0205956:	02044b63          	bltz	s0,ffffffffc020598c <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc020595a:	8622                	mv	a2,s0
ffffffffc020595c:	8a5e                	mv	s4,s7
ffffffffc020595e:	46a9                	li	a3,10
ffffffffc0205960:	b541                	j	ffffffffc02057e0 <vprintfmt+0x120>
            lflag ++;
ffffffffc0205962:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205964:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0205966:	bb5d                	j	ffffffffc020571c <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc0205968:	000a2403          	lw	s0,0(s4)
ffffffffc020596c:	b7ed                	j	ffffffffc0205956 <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc020596e:	000a6603          	lwu	a2,0(s4)
ffffffffc0205972:	46a1                	li	a3,8
ffffffffc0205974:	8a2e                	mv	s4,a1
ffffffffc0205976:	b5ad                	j	ffffffffc02057e0 <vprintfmt+0x120>
ffffffffc0205978:	000a6603          	lwu	a2,0(s4)
ffffffffc020597c:	46a9                	li	a3,10
ffffffffc020597e:	8a2e                	mv	s4,a1
ffffffffc0205980:	b585                	j	ffffffffc02057e0 <vprintfmt+0x120>
ffffffffc0205982:	000a6603          	lwu	a2,0(s4)
ffffffffc0205986:	46c1                	li	a3,16
ffffffffc0205988:	8a2e                	mv	s4,a1
ffffffffc020598a:	bd99                	j	ffffffffc02057e0 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc020598c:	85ca                	mv	a1,s2
ffffffffc020598e:	02d00513          	li	a0,45
ffffffffc0205992:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0205994:	40800633          	neg	a2,s0
ffffffffc0205998:	8a5e                	mv	s4,s7
ffffffffc020599a:	46a9                	li	a3,10
ffffffffc020599c:	b591                	j	ffffffffc02057e0 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc020599e:	e329                	bnez	a4,ffffffffc02059e0 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02059a0:	02800793          	li	a5,40
ffffffffc02059a4:	853e                	mv	a0,a5
ffffffffc02059a6:	00002d97          	auipc	s11,0x2
ffffffffc02059aa:	f53d8d93          	addi	s11,s11,-173 # ffffffffc02078f9 <etext+0x1df5>
ffffffffc02059ae:	b5f5                	j	ffffffffc020589a <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02059b0:	85e6                	mv	a1,s9
ffffffffc02059b2:	856e                	mv	a0,s11
ffffffffc02059b4:	08a000ef          	jal	ffffffffc0205a3e <strnlen>
ffffffffc02059b8:	40ad0d3b          	subw	s10,s10,a0
ffffffffc02059bc:	01a05863          	blez	s10,ffffffffc02059cc <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc02059c0:	85ca                	mv	a1,s2
ffffffffc02059c2:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02059c4:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc02059c6:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02059c8:	fe0d1ce3          	bnez	s10,ffffffffc02059c0 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02059cc:	000dc783          	lbu	a5,0(s11)
ffffffffc02059d0:	0007851b          	sext.w	a0,a5
ffffffffc02059d4:	ec0792e3          	bnez	a5,ffffffffc0205898 <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02059d8:	6a22                	ld	s4,8(sp)
ffffffffc02059da:	bb29                	j	ffffffffc02056f4 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02059dc:	8462                	mv	s0,s8
ffffffffc02059de:	bbd9                	j	ffffffffc02057b4 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02059e0:	85e6                	mv	a1,s9
ffffffffc02059e2:	00002517          	auipc	a0,0x2
ffffffffc02059e6:	f1650513          	addi	a0,a0,-234 # ffffffffc02078f8 <etext+0x1df4>
ffffffffc02059ea:	054000ef          	jal	ffffffffc0205a3e <strnlen>
ffffffffc02059ee:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02059f2:	02800793          	li	a5,40
                p = "(null)";
ffffffffc02059f6:	00002d97          	auipc	s11,0x2
ffffffffc02059fa:	f02d8d93          	addi	s11,s11,-254 # ffffffffc02078f8 <etext+0x1df4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02059fe:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205a00:	fda040e3          	bgtz	s10,ffffffffc02059c0 <vprintfmt+0x300>
ffffffffc0205a04:	bd51                	j	ffffffffc0205898 <vprintfmt+0x1d8>

ffffffffc0205a06 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205a06:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0205a08:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205a0c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205a0e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205a10:	ec06                	sd	ra,24(sp)
ffffffffc0205a12:	f83a                	sd	a4,48(sp)
ffffffffc0205a14:	fc3e                	sd	a5,56(sp)
ffffffffc0205a16:	e0c2                	sd	a6,64(sp)
ffffffffc0205a18:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0205a1a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205a1c:	ca5ff0ef          	jal	ffffffffc02056c0 <vprintfmt>
}
ffffffffc0205a20:	60e2                	ld	ra,24(sp)
ffffffffc0205a22:	6161                	addi	sp,sp,80
ffffffffc0205a24:	8082                	ret

ffffffffc0205a26 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0205a26:	00054783          	lbu	a5,0(a0)
ffffffffc0205a2a:	cb81                	beqz	a5,ffffffffc0205a3a <strlen+0x14>
    size_t cnt = 0;
ffffffffc0205a2c:	4781                	li	a5,0
        cnt ++;
ffffffffc0205a2e:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0205a30:	00f50733          	add	a4,a0,a5
ffffffffc0205a34:	00074703          	lbu	a4,0(a4)
ffffffffc0205a38:	fb7d                	bnez	a4,ffffffffc0205a2e <strlen+0x8>
    }
    return cnt;
}
ffffffffc0205a3a:	853e                	mv	a0,a5
ffffffffc0205a3c:	8082                	ret

ffffffffc0205a3e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205a3e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205a40:	e589                	bnez	a1,ffffffffc0205a4a <strnlen+0xc>
ffffffffc0205a42:	a811                	j	ffffffffc0205a56 <strnlen+0x18>
        cnt ++;
ffffffffc0205a44:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205a46:	00f58863          	beq	a1,a5,ffffffffc0205a56 <strnlen+0x18>
ffffffffc0205a4a:	00f50733          	add	a4,a0,a5
ffffffffc0205a4e:	00074703          	lbu	a4,0(a4)
ffffffffc0205a52:	fb6d                	bnez	a4,ffffffffc0205a44 <strnlen+0x6>
ffffffffc0205a54:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0205a56:	852e                	mv	a0,a1
ffffffffc0205a58:	8082                	ret

ffffffffc0205a5a <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0205a5a:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205a5c:	0005c703          	lbu	a4,0(a1)
ffffffffc0205a60:	0585                	addi	a1,a1,1
ffffffffc0205a62:	0785                	addi	a5,a5,1
ffffffffc0205a64:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0205a68:	fb75                	bnez	a4,ffffffffc0205a5c <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0205a6a:	8082                	ret

ffffffffc0205a6c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205a6c:	00054783          	lbu	a5,0(a0)
ffffffffc0205a70:	e791                	bnez	a5,ffffffffc0205a7c <strcmp+0x10>
ffffffffc0205a72:	a01d                	j	ffffffffc0205a98 <strcmp+0x2c>
ffffffffc0205a74:	00054783          	lbu	a5,0(a0)
ffffffffc0205a78:	cb99                	beqz	a5,ffffffffc0205a8e <strcmp+0x22>
ffffffffc0205a7a:	0585                	addi	a1,a1,1
ffffffffc0205a7c:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0205a80:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205a82:	fef709e3          	beq	a4,a5,ffffffffc0205a74 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205a86:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0205a8a:	9d19                	subw	a0,a0,a4
ffffffffc0205a8c:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205a8e:	0015c703          	lbu	a4,1(a1)
ffffffffc0205a92:	4501                	li	a0,0
}
ffffffffc0205a94:	9d19                	subw	a0,a0,a4
ffffffffc0205a96:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205a98:	0005c703          	lbu	a4,0(a1)
ffffffffc0205a9c:	4501                	li	a0,0
ffffffffc0205a9e:	b7f5                	j	ffffffffc0205a8a <strcmp+0x1e>

ffffffffc0205aa0 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205aa0:	ce01                	beqz	a2,ffffffffc0205ab8 <strncmp+0x18>
ffffffffc0205aa2:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0205aa6:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205aa8:	cb91                	beqz	a5,ffffffffc0205abc <strncmp+0x1c>
ffffffffc0205aaa:	0005c703          	lbu	a4,0(a1)
ffffffffc0205aae:	00f71763          	bne	a4,a5,ffffffffc0205abc <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0205ab2:	0505                	addi	a0,a0,1
ffffffffc0205ab4:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0205ab6:	f675                	bnez	a2,ffffffffc0205aa2 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205ab8:	4501                	li	a0,0
ffffffffc0205aba:	8082                	ret
ffffffffc0205abc:	00054503          	lbu	a0,0(a0)
ffffffffc0205ac0:	0005c783          	lbu	a5,0(a1)
ffffffffc0205ac4:	9d1d                	subw	a0,a0,a5
}
ffffffffc0205ac6:	8082                	ret

ffffffffc0205ac8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0205ac8:	a021                	j	ffffffffc0205ad0 <strchr+0x8>
        if (*s == c) {
ffffffffc0205aca:	00f58763          	beq	a1,a5,ffffffffc0205ad8 <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc0205ace:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0205ad0:	00054783          	lbu	a5,0(a0)
ffffffffc0205ad4:	fbfd                	bnez	a5,ffffffffc0205aca <strchr+0x2>
    }
    return NULL;
ffffffffc0205ad6:	4501                	li	a0,0
}
ffffffffc0205ad8:	8082                	ret

ffffffffc0205ada <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0205ada:	ca01                	beqz	a2,ffffffffc0205aea <memset+0x10>
ffffffffc0205adc:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0205ade:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0205ae0:	0785                	addi	a5,a5,1
ffffffffc0205ae2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0205ae6:	fef61de3          	bne	a2,a5,ffffffffc0205ae0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0205aea:	8082                	ret

ffffffffc0205aec <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0205aec:	ca19                	beqz	a2,ffffffffc0205b02 <memcpy+0x16>
ffffffffc0205aee:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0205af0:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0205af2:	0005c703          	lbu	a4,0(a1)
ffffffffc0205af6:	0585                	addi	a1,a1,1
ffffffffc0205af8:	0785                	addi	a5,a5,1
ffffffffc0205afa:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205afe:	feb61ae3          	bne	a2,a1,ffffffffc0205af2 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205b02:	8082                	ret
