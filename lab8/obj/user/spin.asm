
obj/__user_spin.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <__panic>:
  800020:	715d                	addi	sp,sp,-80
  800022:	8e2e                	mv	t3,a1
  800024:	e822                	sd	s0,16(sp)
  800026:	85aa                	mv	a1,a0
  800028:	8432                	mv	s0,a2
  80002a:	fc3e                	sd	a5,56(sp)
  80002c:	8672                	mv	a2,t3
  80002e:	103c                	addi	a5,sp,40
  800030:	00000517          	auipc	a0,0x0
  800034:	75050513          	addi	a0,a0,1872 # 800780 <main+0xd2>
  800038:	ec06                	sd	ra,24(sp)
  80003a:	f436                	sd	a3,40(sp)
  80003c:	f83a                	sd	a4,48(sp)
  80003e:	e0c2                	sd	a6,64(sp)
  800040:	e4c6                	sd	a7,72(sp)
  800042:	e43e                	sd	a5,8(sp)
  800044:	128000ef          	jal	ra,80016c <cprintf>
  800048:	65a2                	ld	a1,8(sp)
  80004a:	8522                	mv	a0,s0
  80004c:	0fa000ef          	jal	ra,800146 <vcprintf>
  800050:	00000517          	auipc	a0,0x0
  800054:	79050513          	addi	a0,a0,1936 # 8007e0 <main+0x132>
  800058:	114000ef          	jal	ra,80016c <cprintf>
  80005c:	5559                	li	a0,-10
  80005e:	202000ef          	jal	ra,800260 <exit>

0000000000800062 <__warn>:
  800062:	715d                	addi	sp,sp,-80
  800064:	832e                	mv	t1,a1
  800066:	e822                	sd	s0,16(sp)
  800068:	85aa                	mv	a1,a0
  80006a:	8432                	mv	s0,a2
  80006c:	fc3e                	sd	a5,56(sp)
  80006e:	861a                	mv	a2,t1
  800070:	103c                	addi	a5,sp,40
  800072:	00000517          	auipc	a0,0x0
  800076:	72e50513          	addi	a0,a0,1838 # 8007a0 <main+0xf2>
  80007a:	ec06                	sd	ra,24(sp)
  80007c:	f436                	sd	a3,40(sp)
  80007e:	f83a                	sd	a4,48(sp)
  800080:	e0c2                	sd	a6,64(sp)
  800082:	e4c6                	sd	a7,72(sp)
  800084:	e43e                	sd	a5,8(sp)
  800086:	0e6000ef          	jal	ra,80016c <cprintf>
  80008a:	65a2                	ld	a1,8(sp)
  80008c:	8522                	mv	a0,s0
  80008e:	0b8000ef          	jal	ra,800146 <vcprintf>
  800092:	00000517          	auipc	a0,0x0
  800096:	74e50513          	addi	a0,a0,1870 # 8007e0 <main+0x132>
  80009a:	0d2000ef          	jal	ra,80016c <cprintf>
  80009e:	60e2                	ld	ra,24(sp)
  8000a0:	6442                	ld	s0,16(sp)
  8000a2:	6161                	addi	sp,sp,80
  8000a4:	8082                	ret

00000000008000a6 <syscall>:
  8000a6:	7175                	addi	sp,sp,-144
  8000a8:	f8ba                	sd	a4,112(sp)
  8000aa:	e0ba                	sd	a4,64(sp)
  8000ac:	0118                	addi	a4,sp,128
  8000ae:	e42a                	sd	a0,8(sp)
  8000b0:	ecae                	sd	a1,88(sp)
  8000b2:	f0b2                	sd	a2,96(sp)
  8000b4:	f4b6                	sd	a3,104(sp)
  8000b6:	fcbe                	sd	a5,120(sp)
  8000b8:	e142                	sd	a6,128(sp)
  8000ba:	e546                	sd	a7,136(sp)
  8000bc:	f42e                	sd	a1,40(sp)
  8000be:	f832                	sd	a2,48(sp)
  8000c0:	fc36                	sd	a3,56(sp)
  8000c2:	f03a                	sd	a4,32(sp)
  8000c4:	e4be                	sd	a5,72(sp)
  8000c6:	4522                	lw	a0,8(sp)
  8000c8:	55a2                	lw	a1,40(sp)
  8000ca:	5642                	lw	a2,48(sp)
  8000cc:	56e2                	lw	a3,56(sp)
  8000ce:	4706                	lw	a4,64(sp)
  8000d0:	47a6                	lw	a5,72(sp)
  8000d2:	00000073          	ecall
  8000d6:	ce2a                	sw	a0,28(sp)
  8000d8:	4572                	lw	a0,28(sp)
  8000da:	6149                	addi	sp,sp,144
  8000dc:	8082                	ret

00000000008000de <sys_exit>:
  8000de:	85aa                	mv	a1,a0
  8000e0:	4505                	li	a0,1
  8000e2:	b7d1                	j	8000a6 <syscall>

00000000008000e4 <sys_fork>:
  8000e4:	4509                	li	a0,2
  8000e6:	b7c1                	j	8000a6 <syscall>

00000000008000e8 <sys_wait>:
  8000e8:	862e                	mv	a2,a1
  8000ea:	85aa                	mv	a1,a0
  8000ec:	450d                	li	a0,3
  8000ee:	bf65                	j	8000a6 <syscall>

00000000008000f0 <sys_yield>:
  8000f0:	4529                	li	a0,10
  8000f2:	bf55                	j	8000a6 <syscall>

00000000008000f4 <sys_kill>:
  8000f4:	85aa                	mv	a1,a0
  8000f6:	4531                	li	a0,12
  8000f8:	b77d                	j	8000a6 <syscall>

00000000008000fa <sys_putc>:
  8000fa:	85aa                	mv	a1,a0
  8000fc:	4579                	li	a0,30
  8000fe:	b765                	j	8000a6 <syscall>

0000000000800100 <sys_open>:
  800100:	862e                	mv	a2,a1
  800102:	85aa                	mv	a1,a0
  800104:	06400513          	li	a0,100
  800108:	bf79                	j	8000a6 <syscall>

000000000080010a <sys_close>:
  80010a:	85aa                	mv	a1,a0
  80010c:	06500513          	li	a0,101
  800110:	bf59                	j	8000a6 <syscall>

0000000000800112 <sys_dup>:
  800112:	862e                	mv	a2,a1
  800114:	85aa                	mv	a1,a0
  800116:	08200513          	li	a0,130
  80011a:	b771                	j	8000a6 <syscall>

000000000080011c <_start>:
  80011c:	0d0000ef          	jal	ra,8001ec <umain>
  800120:	a001                	j	800120 <_start+0x4>

0000000000800122 <open>:
  800122:	1582                	slli	a1,a1,0x20
  800124:	9181                	srli	a1,a1,0x20
  800126:	bfe9                	j	800100 <sys_open>

0000000000800128 <close>:
  800128:	b7cd                	j	80010a <sys_close>

000000000080012a <dup2>:
  80012a:	b7e5                	j	800112 <sys_dup>

000000000080012c <cputch>:
  80012c:	1141                	addi	sp,sp,-16
  80012e:	e022                	sd	s0,0(sp)
  800130:	e406                	sd	ra,8(sp)
  800132:	842e                	mv	s0,a1
  800134:	fc7ff0ef          	jal	ra,8000fa <sys_putc>
  800138:	401c                	lw	a5,0(s0)
  80013a:	60a2                	ld	ra,8(sp)
  80013c:	2785                	addiw	a5,a5,1
  80013e:	c01c                	sw	a5,0(s0)
  800140:	6402                	ld	s0,0(sp)
  800142:	0141                	addi	sp,sp,16
  800144:	8082                	ret

0000000000800146 <vcprintf>:
  800146:	1101                	addi	sp,sp,-32
  800148:	872e                	mv	a4,a1
  80014a:	75dd                	lui	a1,0xffff7
  80014c:	86aa                	mv	a3,a0
  80014e:	0070                	addi	a2,sp,12
  800150:	00000517          	auipc	a0,0x0
  800154:	fdc50513          	addi	a0,a0,-36 # 80012c <cputch>
  800158:	ad958593          	addi	a1,a1,-1319 # ffffffffffff6ad9 <error_string+0xffffffffff7f5f31>
  80015c:	ec06                	sd	ra,24(sp)
  80015e:	c602                	sw	zero,12(sp)
  800160:	1b0000ef          	jal	ra,800310 <vprintfmt>
  800164:	60e2                	ld	ra,24(sp)
  800166:	4532                	lw	a0,12(sp)
  800168:	6105                	addi	sp,sp,32
  80016a:	8082                	ret

000000000080016c <cprintf>:
  80016c:	711d                	addi	sp,sp,-96
  80016e:	02810313          	addi	t1,sp,40
  800172:	8e2a                	mv	t3,a0
  800174:	f42e                	sd	a1,40(sp)
  800176:	75dd                	lui	a1,0xffff7
  800178:	f832                	sd	a2,48(sp)
  80017a:	fc36                	sd	a3,56(sp)
  80017c:	e0ba                	sd	a4,64(sp)
  80017e:	00000517          	auipc	a0,0x0
  800182:	fae50513          	addi	a0,a0,-82 # 80012c <cputch>
  800186:	0050                	addi	a2,sp,4
  800188:	871a                	mv	a4,t1
  80018a:	86f2                	mv	a3,t3
  80018c:	ad958593          	addi	a1,a1,-1319 # ffffffffffff6ad9 <error_string+0xffffffffff7f5f31>
  800190:	ec06                	sd	ra,24(sp)
  800192:	e4be                	sd	a5,72(sp)
  800194:	e8c2                	sd	a6,80(sp)
  800196:	ecc6                	sd	a7,88(sp)
  800198:	e41a                	sd	t1,8(sp)
  80019a:	c202                	sw	zero,4(sp)
  80019c:	174000ef          	jal	ra,800310 <vprintfmt>
  8001a0:	60e2                	ld	ra,24(sp)
  8001a2:	4512                	lw	a0,4(sp)
  8001a4:	6125                	addi	sp,sp,96
  8001a6:	8082                	ret

00000000008001a8 <initfd>:
  8001a8:	1101                	addi	sp,sp,-32
  8001aa:	87ae                	mv	a5,a1
  8001ac:	e426                	sd	s1,8(sp)
  8001ae:	85b2                	mv	a1,a2
  8001b0:	84aa                	mv	s1,a0
  8001b2:	853e                	mv	a0,a5
  8001b4:	e822                	sd	s0,16(sp)
  8001b6:	ec06                	sd	ra,24(sp)
  8001b8:	f6bff0ef          	jal	ra,800122 <open>
  8001bc:	842a                	mv	s0,a0
  8001be:	00054463          	bltz	a0,8001c6 <initfd+0x1e>
  8001c2:	00951863          	bne	a0,s1,8001d2 <initfd+0x2a>
  8001c6:	60e2                	ld	ra,24(sp)
  8001c8:	8522                	mv	a0,s0
  8001ca:	6442                	ld	s0,16(sp)
  8001cc:	64a2                	ld	s1,8(sp)
  8001ce:	6105                	addi	sp,sp,32
  8001d0:	8082                	ret
  8001d2:	8526                	mv	a0,s1
  8001d4:	f55ff0ef          	jal	ra,800128 <close>
  8001d8:	85a6                	mv	a1,s1
  8001da:	8522                	mv	a0,s0
  8001dc:	f4fff0ef          	jal	ra,80012a <dup2>
  8001e0:	84aa                	mv	s1,a0
  8001e2:	8522                	mv	a0,s0
  8001e4:	f45ff0ef          	jal	ra,800128 <close>
  8001e8:	8426                	mv	s0,s1
  8001ea:	bff1                	j	8001c6 <initfd+0x1e>

00000000008001ec <umain>:
  8001ec:	1101                	addi	sp,sp,-32
  8001ee:	e822                	sd	s0,16(sp)
  8001f0:	e426                	sd	s1,8(sp)
  8001f2:	842a                	mv	s0,a0
  8001f4:	84ae                	mv	s1,a1
  8001f6:	4601                	li	a2,0
  8001f8:	00000597          	auipc	a1,0x0
  8001fc:	5c858593          	addi	a1,a1,1480 # 8007c0 <main+0x112>
  800200:	4501                	li	a0,0
  800202:	ec06                	sd	ra,24(sp)
  800204:	fa5ff0ef          	jal	ra,8001a8 <initfd>
  800208:	02054263          	bltz	a0,80022c <umain+0x40>
  80020c:	4605                	li	a2,1
  80020e:	00000597          	auipc	a1,0x0
  800212:	5f258593          	addi	a1,a1,1522 # 800800 <main+0x152>
  800216:	4505                	li	a0,1
  800218:	f91ff0ef          	jal	ra,8001a8 <initfd>
  80021c:	02054563          	bltz	a0,800246 <umain+0x5a>
  800220:	85a6                	mv	a1,s1
  800222:	8522                	mv	a0,s0
  800224:	48a000ef          	jal	ra,8006ae <main>
  800228:	038000ef          	jal	ra,800260 <exit>
  80022c:	86aa                	mv	a3,a0
  80022e:	00000617          	auipc	a2,0x0
  800232:	59a60613          	addi	a2,a2,1434 # 8007c8 <main+0x11a>
  800236:	45e9                	li	a1,26
  800238:	00000517          	auipc	a0,0x0
  80023c:	5b050513          	addi	a0,a0,1456 # 8007e8 <main+0x13a>
  800240:	e23ff0ef          	jal	ra,800062 <__warn>
  800244:	b7e1                	j	80020c <umain+0x20>
  800246:	86aa                	mv	a3,a0
  800248:	00000617          	auipc	a2,0x0
  80024c:	5c060613          	addi	a2,a2,1472 # 800808 <main+0x15a>
  800250:	45f5                	li	a1,29
  800252:	00000517          	auipc	a0,0x0
  800256:	59650513          	addi	a0,a0,1430 # 8007e8 <main+0x13a>
  80025a:	e09ff0ef          	jal	ra,800062 <__warn>
  80025e:	b7c9                	j	800220 <umain+0x34>

0000000000800260 <exit>:
  800260:	1141                	addi	sp,sp,-16
  800262:	e406                	sd	ra,8(sp)
  800264:	e7bff0ef          	jal	ra,8000de <sys_exit>
  800268:	00000517          	auipc	a0,0x0
  80026c:	5c050513          	addi	a0,a0,1472 # 800828 <main+0x17a>
  800270:	efdff0ef          	jal	ra,80016c <cprintf>
  800274:	a001                	j	800274 <exit+0x14>

0000000000800276 <fork>:
  800276:	b5bd                	j	8000e4 <sys_fork>

0000000000800278 <waitpid>:
  800278:	bd85                	j	8000e8 <sys_wait>

000000000080027a <yield>:
  80027a:	bd9d                	j	8000f0 <sys_yield>

000000000080027c <kill>:
  80027c:	bda5                	j	8000f4 <sys_kill>

000000000080027e <strnlen>:
  80027e:	872a                	mv	a4,a0
  800280:	4501                	li	a0,0
  800282:	e589                	bnez	a1,80028c <strnlen+0xe>
  800284:	a811                	j	800298 <strnlen+0x1a>
  800286:	0505                	addi	a0,a0,1
  800288:	00a58763          	beq	a1,a0,800296 <strnlen+0x18>
  80028c:	00a707b3          	add	a5,a4,a0
  800290:	0007c783          	lbu	a5,0(a5)
  800294:	fbed                	bnez	a5,800286 <strnlen+0x8>
  800296:	8082                	ret
  800298:	8082                	ret

000000000080029a <printnum>:
  80029a:	02071893          	slli	a7,a4,0x20
  80029e:	7139                	addi	sp,sp,-64
  8002a0:	0208d893          	srli	a7,a7,0x20
  8002a4:	e456                	sd	s5,8(sp)
  8002a6:	0316fab3          	remu	s5,a3,a7
  8002aa:	f822                	sd	s0,48(sp)
  8002ac:	f426                	sd	s1,40(sp)
  8002ae:	f04a                	sd	s2,32(sp)
  8002b0:	ec4e                	sd	s3,24(sp)
  8002b2:	fc06                	sd	ra,56(sp)
  8002b4:	e852                	sd	s4,16(sp)
  8002b6:	84aa                	mv	s1,a0
  8002b8:	89ae                	mv	s3,a1
  8002ba:	8932                	mv	s2,a2
  8002bc:	fff7841b          	addiw	s0,a5,-1
  8002c0:	2a81                	sext.w	s5,s5
  8002c2:	0516f163          	bgeu	a3,a7,800304 <printnum+0x6a>
  8002c6:	8a42                	mv	s4,a6
  8002c8:	00805863          	blez	s0,8002d8 <printnum+0x3e>
  8002cc:	347d                	addiw	s0,s0,-1
  8002ce:	864e                	mv	a2,s3
  8002d0:	85ca                	mv	a1,s2
  8002d2:	8552                	mv	a0,s4
  8002d4:	9482                	jalr	s1
  8002d6:	f87d                	bnez	s0,8002cc <printnum+0x32>
  8002d8:	1a82                	slli	s5,s5,0x20
  8002da:	020ada93          	srli	s5,s5,0x20
  8002de:	00000797          	auipc	a5,0x0
  8002e2:	56278793          	addi	a5,a5,1378 # 800840 <main+0x192>
  8002e6:	7442                	ld	s0,48(sp)
  8002e8:	9abe                	add	s5,s5,a5
  8002ea:	000ac503          	lbu	a0,0(s5)
  8002ee:	70e2                	ld	ra,56(sp)
  8002f0:	6a42                	ld	s4,16(sp)
  8002f2:	6aa2                	ld	s5,8(sp)
  8002f4:	864e                	mv	a2,s3
  8002f6:	85ca                	mv	a1,s2
  8002f8:	69e2                	ld	s3,24(sp)
  8002fa:	7902                	ld	s2,32(sp)
  8002fc:	8326                	mv	t1,s1
  8002fe:	74a2                	ld	s1,40(sp)
  800300:	6121                	addi	sp,sp,64
  800302:	8302                	jr	t1
  800304:	0316d6b3          	divu	a3,a3,a7
  800308:	87a2                	mv	a5,s0
  80030a:	f91ff0ef          	jal	ra,80029a <printnum>
  80030e:	b7e9                	j	8002d8 <printnum+0x3e>

0000000000800310 <vprintfmt>:
  800310:	7119                	addi	sp,sp,-128
  800312:	f4a6                	sd	s1,104(sp)
  800314:	f0ca                	sd	s2,96(sp)
  800316:	ecce                	sd	s3,88(sp)
  800318:	e8d2                	sd	s4,80(sp)
  80031a:	e4d6                	sd	s5,72(sp)
  80031c:	e0da                	sd	s6,64(sp)
  80031e:	fc5e                	sd	s7,56(sp)
  800320:	ec6e                	sd	s11,24(sp)
  800322:	fc86                	sd	ra,120(sp)
  800324:	f8a2                	sd	s0,112(sp)
  800326:	f862                	sd	s8,48(sp)
  800328:	f466                	sd	s9,40(sp)
  80032a:	f06a                	sd	s10,32(sp)
  80032c:	89aa                	mv	s3,a0
  80032e:	892e                	mv	s2,a1
  800330:	84b2                	mv	s1,a2
  800332:	8db6                	mv	s11,a3
  800334:	8aba                	mv	s5,a4
  800336:	02500a13          	li	s4,37
  80033a:	5bfd                	li	s7,-1
  80033c:	00000b17          	auipc	s6,0x0
  800340:	538b0b13          	addi	s6,s6,1336 # 800874 <main+0x1c6>
  800344:	000dc503          	lbu	a0,0(s11)
  800348:	001d8413          	addi	s0,s11,1
  80034c:	01450b63          	beq	a0,s4,800362 <vprintfmt+0x52>
  800350:	c129                	beqz	a0,800392 <vprintfmt+0x82>
  800352:	864a                	mv	a2,s2
  800354:	85a6                	mv	a1,s1
  800356:	0405                	addi	s0,s0,1
  800358:	9982                	jalr	s3
  80035a:	fff44503          	lbu	a0,-1(s0)
  80035e:	ff4519e3          	bne	a0,s4,800350 <vprintfmt+0x40>
  800362:	00044583          	lbu	a1,0(s0)
  800366:	02000813          	li	a6,32
  80036a:	4d01                	li	s10,0
  80036c:	4301                	li	t1,0
  80036e:	5cfd                	li	s9,-1
  800370:	5c7d                	li	s8,-1
  800372:	05500513          	li	a0,85
  800376:	48a5                	li	a7,9
  800378:	fdd5861b          	addiw	a2,a1,-35
  80037c:	0ff67613          	andi	a2,a2,255
  800380:	00140d93          	addi	s11,s0,1
  800384:	04c56263          	bltu	a0,a2,8003c8 <vprintfmt+0xb8>
  800388:	060a                	slli	a2,a2,0x2
  80038a:	965a                	add	a2,a2,s6
  80038c:	4214                	lw	a3,0(a2)
  80038e:	96da                	add	a3,a3,s6
  800390:	8682                	jr	a3
  800392:	70e6                	ld	ra,120(sp)
  800394:	7446                	ld	s0,112(sp)
  800396:	74a6                	ld	s1,104(sp)
  800398:	7906                	ld	s2,96(sp)
  80039a:	69e6                	ld	s3,88(sp)
  80039c:	6a46                	ld	s4,80(sp)
  80039e:	6aa6                	ld	s5,72(sp)
  8003a0:	6b06                	ld	s6,64(sp)
  8003a2:	7be2                	ld	s7,56(sp)
  8003a4:	7c42                	ld	s8,48(sp)
  8003a6:	7ca2                	ld	s9,40(sp)
  8003a8:	7d02                	ld	s10,32(sp)
  8003aa:	6de2                	ld	s11,24(sp)
  8003ac:	6109                	addi	sp,sp,128
  8003ae:	8082                	ret
  8003b0:	882e                	mv	a6,a1
  8003b2:	00144583          	lbu	a1,1(s0)
  8003b6:	846e                	mv	s0,s11
  8003b8:	00140d93          	addi	s11,s0,1
  8003bc:	fdd5861b          	addiw	a2,a1,-35
  8003c0:	0ff67613          	andi	a2,a2,255
  8003c4:	fcc572e3          	bgeu	a0,a2,800388 <vprintfmt+0x78>
  8003c8:	864a                	mv	a2,s2
  8003ca:	85a6                	mv	a1,s1
  8003cc:	02500513          	li	a0,37
  8003d0:	9982                	jalr	s3
  8003d2:	fff44783          	lbu	a5,-1(s0)
  8003d6:	8da2                	mv	s11,s0
  8003d8:	f74786e3          	beq	a5,s4,800344 <vprintfmt+0x34>
  8003dc:	ffedc783          	lbu	a5,-2(s11)
  8003e0:	1dfd                	addi	s11,s11,-1
  8003e2:	ff479de3          	bne	a5,s4,8003dc <vprintfmt+0xcc>
  8003e6:	bfb9                	j	800344 <vprintfmt+0x34>
  8003e8:	fd058c9b          	addiw	s9,a1,-48
  8003ec:	00144583          	lbu	a1,1(s0)
  8003f0:	846e                	mv	s0,s11
  8003f2:	fd05869b          	addiw	a3,a1,-48
  8003f6:	0005861b          	sext.w	a2,a1
  8003fa:	02d8e463          	bltu	a7,a3,800422 <vprintfmt+0x112>
  8003fe:	00144583          	lbu	a1,1(s0)
  800402:	002c969b          	slliw	a3,s9,0x2
  800406:	0196873b          	addw	a4,a3,s9
  80040a:	0017171b          	slliw	a4,a4,0x1
  80040e:	9f31                	addw	a4,a4,a2
  800410:	fd05869b          	addiw	a3,a1,-48
  800414:	0405                	addi	s0,s0,1
  800416:	fd070c9b          	addiw	s9,a4,-48
  80041a:	0005861b          	sext.w	a2,a1
  80041e:	fed8f0e3          	bgeu	a7,a3,8003fe <vprintfmt+0xee>
  800422:	f40c5be3          	bgez	s8,800378 <vprintfmt+0x68>
  800426:	8c66                	mv	s8,s9
  800428:	5cfd                	li	s9,-1
  80042a:	b7b9                	j	800378 <vprintfmt+0x68>
  80042c:	fffc4693          	not	a3,s8
  800430:	96fd                	srai	a3,a3,0x3f
  800432:	00dc77b3          	and	a5,s8,a3
  800436:	00144583          	lbu	a1,1(s0)
  80043a:	00078c1b          	sext.w	s8,a5
  80043e:	846e                	mv	s0,s11
  800440:	bf25                	j	800378 <vprintfmt+0x68>
  800442:	000aac83          	lw	s9,0(s5)
  800446:	00144583          	lbu	a1,1(s0)
  80044a:	0aa1                	addi	s5,s5,8
  80044c:	846e                	mv	s0,s11
  80044e:	bfd1                	j	800422 <vprintfmt+0x112>
  800450:	4705                	li	a4,1
  800452:	008a8613          	addi	a2,s5,8
  800456:	00674463          	blt	a4,t1,80045e <vprintfmt+0x14e>
  80045a:	1c030c63          	beqz	t1,800632 <vprintfmt+0x322>
  80045e:	000ab683          	ld	a3,0(s5)
  800462:	4741                	li	a4,16
  800464:	8ab2                	mv	s5,a2
  800466:	2801                	sext.w	a6,a6
  800468:	87e2                	mv	a5,s8
  80046a:	8626                	mv	a2,s1
  80046c:	85ca                	mv	a1,s2
  80046e:	854e                	mv	a0,s3
  800470:	e2bff0ef          	jal	ra,80029a <printnum>
  800474:	bdc1                	j	800344 <vprintfmt+0x34>
  800476:	000aa503          	lw	a0,0(s5)
  80047a:	864a                	mv	a2,s2
  80047c:	85a6                	mv	a1,s1
  80047e:	0aa1                	addi	s5,s5,8
  800480:	9982                	jalr	s3
  800482:	b5c9                	j	800344 <vprintfmt+0x34>
  800484:	4705                	li	a4,1
  800486:	008a8613          	addi	a2,s5,8
  80048a:	00674463          	blt	a4,t1,800492 <vprintfmt+0x182>
  80048e:	18030d63          	beqz	t1,800628 <vprintfmt+0x318>
  800492:	000ab683          	ld	a3,0(s5)
  800496:	4729                	li	a4,10
  800498:	8ab2                	mv	s5,a2
  80049a:	b7f1                	j	800466 <vprintfmt+0x156>
  80049c:	00144583          	lbu	a1,1(s0)
  8004a0:	4d05                	li	s10,1
  8004a2:	846e                	mv	s0,s11
  8004a4:	bdd1                	j	800378 <vprintfmt+0x68>
  8004a6:	864a                	mv	a2,s2
  8004a8:	85a6                	mv	a1,s1
  8004aa:	02500513          	li	a0,37
  8004ae:	9982                	jalr	s3
  8004b0:	bd51                	j	800344 <vprintfmt+0x34>
  8004b2:	00144583          	lbu	a1,1(s0)
  8004b6:	2305                	addiw	t1,t1,1
  8004b8:	846e                	mv	s0,s11
  8004ba:	bd7d                	j	800378 <vprintfmt+0x68>
  8004bc:	4705                	li	a4,1
  8004be:	008a8613          	addi	a2,s5,8
  8004c2:	00674463          	blt	a4,t1,8004ca <vprintfmt+0x1ba>
  8004c6:	14030c63          	beqz	t1,80061e <vprintfmt+0x30e>
  8004ca:	000ab683          	ld	a3,0(s5)
  8004ce:	4721                	li	a4,8
  8004d0:	8ab2                	mv	s5,a2
  8004d2:	bf51                	j	800466 <vprintfmt+0x156>
  8004d4:	03000513          	li	a0,48
  8004d8:	864a                	mv	a2,s2
  8004da:	85a6                	mv	a1,s1
  8004dc:	e042                	sd	a6,0(sp)
  8004de:	9982                	jalr	s3
  8004e0:	864a                	mv	a2,s2
  8004e2:	85a6                	mv	a1,s1
  8004e4:	07800513          	li	a0,120
  8004e8:	9982                	jalr	s3
  8004ea:	0aa1                	addi	s5,s5,8
  8004ec:	6802                	ld	a6,0(sp)
  8004ee:	4741                	li	a4,16
  8004f0:	ff8ab683          	ld	a3,-8(s5)
  8004f4:	bf8d                	j	800466 <vprintfmt+0x156>
  8004f6:	000ab403          	ld	s0,0(s5)
  8004fa:	008a8793          	addi	a5,s5,8
  8004fe:	e03e                	sd	a5,0(sp)
  800500:	14040c63          	beqz	s0,800658 <vprintfmt+0x348>
  800504:	11805063          	blez	s8,800604 <vprintfmt+0x2f4>
  800508:	02d00693          	li	a3,45
  80050c:	0cd81963          	bne	a6,a3,8005de <vprintfmt+0x2ce>
  800510:	00044683          	lbu	a3,0(s0)
  800514:	0006851b          	sext.w	a0,a3
  800518:	ce8d                	beqz	a3,800552 <vprintfmt+0x242>
  80051a:	00140a93          	addi	s5,s0,1
  80051e:	05e00413          	li	s0,94
  800522:	000cc563          	bltz	s9,80052c <vprintfmt+0x21c>
  800526:	3cfd                	addiw	s9,s9,-1
  800528:	037c8363          	beq	s9,s7,80054e <vprintfmt+0x23e>
  80052c:	864a                	mv	a2,s2
  80052e:	85a6                	mv	a1,s1
  800530:	100d0663          	beqz	s10,80063c <vprintfmt+0x32c>
  800534:	3681                	addiw	a3,a3,-32
  800536:	10d47363          	bgeu	s0,a3,80063c <vprintfmt+0x32c>
  80053a:	03f00513          	li	a0,63
  80053e:	9982                	jalr	s3
  800540:	000ac683          	lbu	a3,0(s5)
  800544:	3c7d                	addiw	s8,s8,-1
  800546:	0a85                	addi	s5,s5,1
  800548:	0006851b          	sext.w	a0,a3
  80054c:	faf9                	bnez	a3,800522 <vprintfmt+0x212>
  80054e:	01805a63          	blez	s8,800562 <vprintfmt+0x252>
  800552:	3c7d                	addiw	s8,s8,-1
  800554:	864a                	mv	a2,s2
  800556:	85a6                	mv	a1,s1
  800558:	02000513          	li	a0,32
  80055c:	9982                	jalr	s3
  80055e:	fe0c1ae3          	bnez	s8,800552 <vprintfmt+0x242>
  800562:	6a82                	ld	s5,0(sp)
  800564:	b3c5                	j	800344 <vprintfmt+0x34>
  800566:	4705                	li	a4,1
  800568:	008a8d13          	addi	s10,s5,8
  80056c:	00674463          	blt	a4,t1,800574 <vprintfmt+0x264>
  800570:	0a030463          	beqz	t1,800618 <vprintfmt+0x308>
  800574:	000ab403          	ld	s0,0(s5)
  800578:	0c044463          	bltz	s0,800640 <vprintfmt+0x330>
  80057c:	86a2                	mv	a3,s0
  80057e:	8aea                	mv	s5,s10
  800580:	4729                	li	a4,10
  800582:	b5d5                	j	800466 <vprintfmt+0x156>
  800584:	000aa783          	lw	a5,0(s5)
  800588:	46e1                	li	a3,24
  80058a:	0aa1                	addi	s5,s5,8
  80058c:	41f7d71b          	sraiw	a4,a5,0x1f
  800590:	8fb9                	xor	a5,a5,a4
  800592:	40e7873b          	subw	a4,a5,a4
  800596:	02e6c663          	blt	a3,a4,8005c2 <vprintfmt+0x2b2>
  80059a:	00371793          	slli	a5,a4,0x3
  80059e:	00000697          	auipc	a3,0x0
  8005a2:	60a68693          	addi	a3,a3,1546 # 800ba8 <error_string>
  8005a6:	97b6                	add	a5,a5,a3
  8005a8:	639c                	ld	a5,0(a5)
  8005aa:	cf81                	beqz	a5,8005c2 <vprintfmt+0x2b2>
  8005ac:	873e                	mv	a4,a5
  8005ae:	00000697          	auipc	a3,0x0
  8005b2:	2c268693          	addi	a3,a3,706 # 800870 <main+0x1c2>
  8005b6:	8626                	mv	a2,s1
  8005b8:	85ca                	mv	a1,s2
  8005ba:	854e                	mv	a0,s3
  8005bc:	0d4000ef          	jal	ra,800690 <printfmt>
  8005c0:	b351                	j	800344 <vprintfmt+0x34>
  8005c2:	00000697          	auipc	a3,0x0
  8005c6:	29e68693          	addi	a3,a3,670 # 800860 <main+0x1b2>
  8005ca:	8626                	mv	a2,s1
  8005cc:	85ca                	mv	a1,s2
  8005ce:	854e                	mv	a0,s3
  8005d0:	0c0000ef          	jal	ra,800690 <printfmt>
  8005d4:	bb85                	j	800344 <vprintfmt+0x34>
  8005d6:	00000417          	auipc	s0,0x0
  8005da:	28240413          	addi	s0,s0,642 # 800858 <main+0x1aa>
  8005de:	85e6                	mv	a1,s9
  8005e0:	8522                	mv	a0,s0
  8005e2:	e442                	sd	a6,8(sp)
  8005e4:	c9bff0ef          	jal	ra,80027e <strnlen>
  8005e8:	40ac0c3b          	subw	s8,s8,a0
  8005ec:	01805c63          	blez	s8,800604 <vprintfmt+0x2f4>
  8005f0:	6822                	ld	a6,8(sp)
  8005f2:	00080a9b          	sext.w	s5,a6
  8005f6:	3c7d                	addiw	s8,s8,-1
  8005f8:	864a                	mv	a2,s2
  8005fa:	85a6                	mv	a1,s1
  8005fc:	8556                	mv	a0,s5
  8005fe:	9982                	jalr	s3
  800600:	fe0c1be3          	bnez	s8,8005f6 <vprintfmt+0x2e6>
  800604:	00044683          	lbu	a3,0(s0)
  800608:	00140a93          	addi	s5,s0,1
  80060c:	0006851b          	sext.w	a0,a3
  800610:	daa9                	beqz	a3,800562 <vprintfmt+0x252>
  800612:	05e00413          	li	s0,94
  800616:	b731                	j	800522 <vprintfmt+0x212>
  800618:	000aa403          	lw	s0,0(s5)
  80061c:	bfb1                	j	800578 <vprintfmt+0x268>
  80061e:	000ae683          	lwu	a3,0(s5)
  800622:	4721                	li	a4,8
  800624:	8ab2                	mv	s5,a2
  800626:	b581                	j	800466 <vprintfmt+0x156>
  800628:	000ae683          	lwu	a3,0(s5)
  80062c:	4729                	li	a4,10
  80062e:	8ab2                	mv	s5,a2
  800630:	bd1d                	j	800466 <vprintfmt+0x156>
  800632:	000ae683          	lwu	a3,0(s5)
  800636:	4741                	li	a4,16
  800638:	8ab2                	mv	s5,a2
  80063a:	b535                	j	800466 <vprintfmt+0x156>
  80063c:	9982                	jalr	s3
  80063e:	b709                	j	800540 <vprintfmt+0x230>
  800640:	864a                	mv	a2,s2
  800642:	85a6                	mv	a1,s1
  800644:	02d00513          	li	a0,45
  800648:	e042                	sd	a6,0(sp)
  80064a:	9982                	jalr	s3
  80064c:	6802                	ld	a6,0(sp)
  80064e:	8aea                	mv	s5,s10
  800650:	408006b3          	neg	a3,s0
  800654:	4729                	li	a4,10
  800656:	bd01                	j	800466 <vprintfmt+0x156>
  800658:	03805163          	blez	s8,80067a <vprintfmt+0x36a>
  80065c:	02d00693          	li	a3,45
  800660:	f6d81be3          	bne	a6,a3,8005d6 <vprintfmt+0x2c6>
  800664:	00000417          	auipc	s0,0x0
  800668:	1f440413          	addi	s0,s0,500 # 800858 <main+0x1aa>
  80066c:	02800693          	li	a3,40
  800670:	02800513          	li	a0,40
  800674:	00140a93          	addi	s5,s0,1
  800678:	b55d                	j	80051e <vprintfmt+0x20e>
  80067a:	00000a97          	auipc	s5,0x0
  80067e:	1dfa8a93          	addi	s5,s5,479 # 800859 <main+0x1ab>
  800682:	02800513          	li	a0,40
  800686:	02800693          	li	a3,40
  80068a:	05e00413          	li	s0,94
  80068e:	bd51                	j	800522 <vprintfmt+0x212>

0000000000800690 <printfmt>:
  800690:	7139                	addi	sp,sp,-64
  800692:	02010313          	addi	t1,sp,32
  800696:	f03a                	sd	a4,32(sp)
  800698:	871a                	mv	a4,t1
  80069a:	ec06                	sd	ra,24(sp)
  80069c:	f43e                	sd	a5,40(sp)
  80069e:	f842                	sd	a6,48(sp)
  8006a0:	fc46                	sd	a7,56(sp)
  8006a2:	e41a                	sd	t1,8(sp)
  8006a4:	c6dff0ef          	jal	ra,800310 <vprintfmt>
  8006a8:	60e2                	ld	ra,24(sp)
  8006aa:	6121                	addi	sp,sp,64
  8006ac:	8082                	ret

00000000008006ae <main>:
  8006ae:	1141                	addi	sp,sp,-16
  8006b0:	00000517          	auipc	a0,0x0
  8006b4:	5c050513          	addi	a0,a0,1472 # 800c70 <error_string+0xc8>
  8006b8:	e406                	sd	ra,8(sp)
  8006ba:	e022                	sd	s0,0(sp)
  8006bc:	ab1ff0ef          	jal	ra,80016c <cprintf>
  8006c0:	bb7ff0ef          	jal	ra,800276 <fork>
  8006c4:	e901                	bnez	a0,8006d4 <main+0x26>
  8006c6:	00000517          	auipc	a0,0x0
  8006ca:	5d250513          	addi	a0,a0,1490 # 800c98 <error_string+0xf0>
  8006ce:	a9fff0ef          	jal	ra,80016c <cprintf>
  8006d2:	a001                	j	8006d2 <main+0x24>
  8006d4:	842a                	mv	s0,a0
  8006d6:	00000517          	auipc	a0,0x0
  8006da:	5e250513          	addi	a0,a0,1506 # 800cb8 <error_string+0x110>
  8006de:	a8fff0ef          	jal	ra,80016c <cprintf>
  8006e2:	b99ff0ef          	jal	ra,80027a <yield>
  8006e6:	b95ff0ef          	jal	ra,80027a <yield>
  8006ea:	b91ff0ef          	jal	ra,80027a <yield>
  8006ee:	00000517          	auipc	a0,0x0
  8006f2:	5f250513          	addi	a0,a0,1522 # 800ce0 <error_string+0x138>
  8006f6:	a77ff0ef          	jal	ra,80016c <cprintf>
  8006fa:	8522                	mv	a0,s0
  8006fc:	b81ff0ef          	jal	ra,80027c <kill>
  800700:	ed31                	bnez	a0,80075c <main+0xae>
  800702:	4581                	li	a1,0
  800704:	00000517          	auipc	a0,0x0
  800708:	64450513          	addi	a0,a0,1604 # 800d48 <error_string+0x1a0>
  80070c:	a61ff0ef          	jal	ra,80016c <cprintf>
  800710:	4581                	li	a1,0
  800712:	8522                	mv	a0,s0
  800714:	b65ff0ef          	jal	ra,800278 <waitpid>
  800718:	e11d                	bnez	a0,80073e <main+0x90>
  80071a:	4581                	li	a1,0
  80071c:	00000517          	auipc	a0,0x0
  800720:	66450513          	addi	a0,a0,1636 # 800d80 <error_string+0x1d8>
  800724:	a49ff0ef          	jal	ra,80016c <cprintf>
  800728:	00000517          	auipc	a0,0x0
  80072c:	67050513          	addi	a0,a0,1648 # 800d98 <error_string+0x1f0>
  800730:	a3dff0ef          	jal	ra,80016c <cprintf>
  800734:	60a2                	ld	ra,8(sp)
  800736:	6402                	ld	s0,0(sp)
  800738:	4501                	li	a0,0
  80073a:	0141                	addi	sp,sp,16
  80073c:	8082                	ret
  80073e:	00000697          	auipc	a3,0x0
  800742:	62268693          	addi	a3,a3,1570 # 800d60 <error_string+0x1b8>
  800746:	00000617          	auipc	a2,0x0
  80074a:	5da60613          	addi	a2,a2,1498 # 800d20 <error_string+0x178>
  80074e:	45dd                	li	a1,23
  800750:	00000517          	auipc	a0,0x0
  800754:	5e850513          	addi	a0,a0,1512 # 800d38 <error_string+0x190>
  800758:	8c9ff0ef          	jal	ra,800020 <__panic>
  80075c:	00000697          	auipc	a3,0x0
  800760:	5ac68693          	addi	a3,a3,1452 # 800d08 <error_string+0x160>
  800764:	00000617          	auipc	a2,0x0
  800768:	5bc60613          	addi	a2,a2,1468 # 800d20 <error_string+0x178>
  80076c:	45d1                	li	a1,20
  80076e:	00000517          	auipc	a0,0x0
  800772:	5ca50513          	addi	a0,a0,1482 # 800d38 <error_string+0x190>
  800776:	8abff0ef          	jal	ra,800020 <__panic>
