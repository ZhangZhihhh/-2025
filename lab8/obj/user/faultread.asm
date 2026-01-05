
obj/__user_faultread.out:     file format elf64-littleriscv


Disassembly of section .text:

0000000000800020 <__warn>:
  800020:	715d                	addi	sp,sp,-80
  800022:	832e                	mv	t1,a1
  800024:	e822                	sd	s0,16(sp)
  800026:	85aa                	mv	a1,a0
  800028:	8432                	mv	s0,a2
  80002a:	fc3e                	sd	a5,56(sp)
  80002c:	861a                	mv	a2,t1
  80002e:	103c                	addi	a5,sp,40
  800030:	00000517          	auipc	a0,0x0
  800034:	64850513          	addi	a0,a0,1608 # 800678 <main+0x2a>
  800038:	ec06                	sd	ra,24(sp)
  80003a:	f436                	sd	a3,40(sp)
  80003c:	f83a                	sd	a4,48(sp)
  80003e:	e0c2                	sd	a6,64(sp)
  800040:	e4c6                	sd	a7,72(sp)
  800042:	e43e                	sd	a5,8(sp)
  800044:	0d0000ef          	jal	ra,800114 <cprintf>
  800048:	65a2                	ld	a1,8(sp)
  80004a:	8522                	mv	a0,s0
  80004c:	0a2000ef          	jal	ra,8000ee <vcprintf>
  800050:	00000517          	auipc	a0,0x0
  800054:	66850513          	addi	a0,a0,1640 # 8006b8 <main+0x6a>
  800058:	0bc000ef          	jal	ra,800114 <cprintf>
  80005c:	60e2                	ld	ra,24(sp)
  80005e:	6442                	ld	s0,16(sp)
  800060:	6161                	addi	sp,sp,80
  800062:	8082                	ret

0000000000800064 <syscall>:
  800064:	7175                	addi	sp,sp,-144
  800066:	f8ba                	sd	a4,112(sp)
  800068:	e0ba                	sd	a4,64(sp)
  80006a:	0118                	addi	a4,sp,128
  80006c:	e42a                	sd	a0,8(sp)
  80006e:	ecae                	sd	a1,88(sp)
  800070:	f0b2                	sd	a2,96(sp)
  800072:	f4b6                	sd	a3,104(sp)
  800074:	fcbe                	sd	a5,120(sp)
  800076:	e142                	sd	a6,128(sp)
  800078:	e546                	sd	a7,136(sp)
  80007a:	f42e                	sd	a1,40(sp)
  80007c:	f832                	sd	a2,48(sp)
  80007e:	fc36                	sd	a3,56(sp)
  800080:	f03a                	sd	a4,32(sp)
  800082:	e4be                	sd	a5,72(sp)
  800084:	4522                	lw	a0,8(sp)
  800086:	55a2                	lw	a1,40(sp)
  800088:	5642                	lw	a2,48(sp)
  80008a:	56e2                	lw	a3,56(sp)
  80008c:	4706                	lw	a4,64(sp)
  80008e:	47a6                	lw	a5,72(sp)
  800090:	00000073          	ecall
  800094:	ce2a                	sw	a0,28(sp)
  800096:	4572                	lw	a0,28(sp)
  800098:	6149                	addi	sp,sp,144
  80009a:	8082                	ret

000000000080009c <sys_exit>:
  80009c:	85aa                	mv	a1,a0
  80009e:	4505                	li	a0,1
  8000a0:	b7d1                	j	800064 <syscall>

00000000008000a2 <sys_putc>:
  8000a2:	85aa                	mv	a1,a0
  8000a4:	4579                	li	a0,30
  8000a6:	bf7d                	j	800064 <syscall>

00000000008000a8 <sys_open>:
  8000a8:	862e                	mv	a2,a1
  8000aa:	85aa                	mv	a1,a0
  8000ac:	06400513          	li	a0,100
  8000b0:	bf55                	j	800064 <syscall>

00000000008000b2 <sys_close>:
  8000b2:	85aa                	mv	a1,a0
  8000b4:	06500513          	li	a0,101
  8000b8:	b775                	j	800064 <syscall>

00000000008000ba <sys_dup>:
  8000ba:	862e                	mv	a2,a1
  8000bc:	85aa                	mv	a1,a0
  8000be:	08200513          	li	a0,130
  8000c2:	b74d                	j	800064 <syscall>

00000000008000c4 <_start>:
  8000c4:	0d0000ef          	jal	ra,800194 <umain>
  8000c8:	a001                	j	8000c8 <_start+0x4>

00000000008000ca <open>:
  8000ca:	1582                	slli	a1,a1,0x20
  8000cc:	9181                	srli	a1,a1,0x20
  8000ce:	bfe9                	j	8000a8 <sys_open>

00000000008000d0 <close>:
  8000d0:	b7cd                	j	8000b2 <sys_close>

00000000008000d2 <dup2>:
  8000d2:	b7e5                	j	8000ba <sys_dup>

00000000008000d4 <cputch>:
  8000d4:	1141                	addi	sp,sp,-16
  8000d6:	e022                	sd	s0,0(sp)
  8000d8:	e406                	sd	ra,8(sp)
  8000da:	842e                	mv	s0,a1
  8000dc:	fc7ff0ef          	jal	ra,8000a2 <sys_putc>
  8000e0:	401c                	lw	a5,0(s0)
  8000e2:	60a2                	ld	ra,8(sp)
  8000e4:	2785                	addiw	a5,a5,1
  8000e6:	c01c                	sw	a5,0(s0)
  8000e8:	6402                	ld	s0,0(sp)
  8000ea:	0141                	addi	sp,sp,16
  8000ec:	8082                	ret

00000000008000ee <vcprintf>:
  8000ee:	1101                	addi	sp,sp,-32
  8000f0:	872e                	mv	a4,a1
  8000f2:	75dd                	lui	a1,0xffff7
  8000f4:	86aa                	mv	a3,a0
  8000f6:	0070                	addi	a2,sp,12
  8000f8:	00000517          	auipc	a0,0x0
  8000fc:	fdc50513          	addi	a0,a0,-36 # 8000d4 <cputch>
  800100:	ad958593          	addi	a1,a1,-1319 # ffffffffffff6ad9 <error_string+0xffffffffff7f6059>
  800104:	ec06                	sd	ra,24(sp)
  800106:	c602                	sw	zero,12(sp)
  800108:	1a8000ef          	jal	ra,8002b0 <vprintfmt>
  80010c:	60e2                	ld	ra,24(sp)
  80010e:	4532                	lw	a0,12(sp)
  800110:	6105                	addi	sp,sp,32
  800112:	8082                	ret

0000000000800114 <cprintf>:
  800114:	711d                	addi	sp,sp,-96
  800116:	02810313          	addi	t1,sp,40
  80011a:	8e2a                	mv	t3,a0
  80011c:	f42e                	sd	a1,40(sp)
  80011e:	75dd                	lui	a1,0xffff7
  800120:	f832                	sd	a2,48(sp)
  800122:	fc36                	sd	a3,56(sp)
  800124:	e0ba                	sd	a4,64(sp)
  800126:	00000517          	auipc	a0,0x0
  80012a:	fae50513          	addi	a0,a0,-82 # 8000d4 <cputch>
  80012e:	0050                	addi	a2,sp,4
  800130:	871a                	mv	a4,t1
  800132:	86f2                	mv	a3,t3
  800134:	ad958593          	addi	a1,a1,-1319 # ffffffffffff6ad9 <error_string+0xffffffffff7f6059>
  800138:	ec06                	sd	ra,24(sp)
  80013a:	e4be                	sd	a5,72(sp)
  80013c:	e8c2                	sd	a6,80(sp)
  80013e:	ecc6                	sd	a7,88(sp)
  800140:	e41a                	sd	t1,8(sp)
  800142:	c202                	sw	zero,4(sp)
  800144:	16c000ef          	jal	ra,8002b0 <vprintfmt>
  800148:	60e2                	ld	ra,24(sp)
  80014a:	4512                	lw	a0,4(sp)
  80014c:	6125                	addi	sp,sp,96
  80014e:	8082                	ret

0000000000800150 <initfd>:
  800150:	1101                	addi	sp,sp,-32
  800152:	87ae                	mv	a5,a1
  800154:	e426                	sd	s1,8(sp)
  800156:	85b2                	mv	a1,a2
  800158:	84aa                	mv	s1,a0
  80015a:	853e                	mv	a0,a5
  80015c:	e822                	sd	s0,16(sp)
  80015e:	ec06                	sd	ra,24(sp)
  800160:	f6bff0ef          	jal	ra,8000ca <open>
  800164:	842a                	mv	s0,a0
  800166:	00054463          	bltz	a0,80016e <initfd+0x1e>
  80016a:	00951863          	bne	a0,s1,80017a <initfd+0x2a>
  80016e:	60e2                	ld	ra,24(sp)
  800170:	8522                	mv	a0,s0
  800172:	6442                	ld	s0,16(sp)
  800174:	64a2                	ld	s1,8(sp)
  800176:	6105                	addi	sp,sp,32
  800178:	8082                	ret
  80017a:	8526                	mv	a0,s1
  80017c:	f55ff0ef          	jal	ra,8000d0 <close>
  800180:	85a6                	mv	a1,s1
  800182:	8522                	mv	a0,s0
  800184:	f4fff0ef          	jal	ra,8000d2 <dup2>
  800188:	84aa                	mv	s1,a0
  80018a:	8522                	mv	a0,s0
  80018c:	f45ff0ef          	jal	ra,8000d0 <close>
  800190:	8426                	mv	s0,s1
  800192:	bff1                	j	80016e <initfd+0x1e>

0000000000800194 <umain>:
  800194:	1101                	addi	sp,sp,-32
  800196:	e822                	sd	s0,16(sp)
  800198:	e426                	sd	s1,8(sp)
  80019a:	842a                	mv	s0,a0
  80019c:	84ae                	mv	s1,a1
  80019e:	4601                	li	a2,0
  8001a0:	00000597          	auipc	a1,0x0
  8001a4:	4f858593          	addi	a1,a1,1272 # 800698 <main+0x4a>
  8001a8:	4501                	li	a0,0
  8001aa:	ec06                	sd	ra,24(sp)
  8001ac:	fa5ff0ef          	jal	ra,800150 <initfd>
  8001b0:	02054263          	bltz	a0,8001d4 <umain+0x40>
  8001b4:	4605                	li	a2,1
  8001b6:	00000597          	auipc	a1,0x0
  8001ba:	52258593          	addi	a1,a1,1314 # 8006d8 <main+0x8a>
  8001be:	4505                	li	a0,1
  8001c0:	f91ff0ef          	jal	ra,800150 <initfd>
  8001c4:	02054563          	bltz	a0,8001ee <umain+0x5a>
  8001c8:	85a6                	mv	a1,s1
  8001ca:	8522                	mv	a0,s0
  8001cc:	482000ef          	jal	ra,80064e <main>
  8001d0:	038000ef          	jal	ra,800208 <exit>
  8001d4:	86aa                	mv	a3,a0
  8001d6:	00000617          	auipc	a2,0x0
  8001da:	4ca60613          	addi	a2,a2,1226 # 8006a0 <main+0x52>
  8001de:	45e9                	li	a1,26
  8001e0:	00000517          	auipc	a0,0x0
  8001e4:	4e050513          	addi	a0,a0,1248 # 8006c0 <main+0x72>
  8001e8:	e39ff0ef          	jal	ra,800020 <__warn>
  8001ec:	b7e1                	j	8001b4 <umain+0x20>
  8001ee:	86aa                	mv	a3,a0
  8001f0:	00000617          	auipc	a2,0x0
  8001f4:	4f060613          	addi	a2,a2,1264 # 8006e0 <main+0x92>
  8001f8:	45f5                	li	a1,29
  8001fa:	00000517          	auipc	a0,0x0
  8001fe:	4c650513          	addi	a0,a0,1222 # 8006c0 <main+0x72>
  800202:	e1fff0ef          	jal	ra,800020 <__warn>
  800206:	b7c9                	j	8001c8 <umain+0x34>

0000000000800208 <exit>:
  800208:	1141                	addi	sp,sp,-16
  80020a:	e406                	sd	ra,8(sp)
  80020c:	e91ff0ef          	jal	ra,80009c <sys_exit>
  800210:	00000517          	auipc	a0,0x0
  800214:	4f050513          	addi	a0,a0,1264 # 800700 <main+0xb2>
  800218:	efdff0ef          	jal	ra,800114 <cprintf>
  80021c:	a001                	j	80021c <exit+0x14>

000000000080021e <strnlen>:
  80021e:	872a                	mv	a4,a0
  800220:	4501                	li	a0,0
  800222:	e589                	bnez	a1,80022c <strnlen+0xe>
  800224:	a811                	j	800238 <strnlen+0x1a>
  800226:	0505                	addi	a0,a0,1
  800228:	00a58763          	beq	a1,a0,800236 <strnlen+0x18>
  80022c:	00a707b3          	add	a5,a4,a0
  800230:	0007c783          	lbu	a5,0(a5)
  800234:	fbed                	bnez	a5,800226 <strnlen+0x8>
  800236:	8082                	ret
  800238:	8082                	ret

000000000080023a <printnum>:
  80023a:	02071893          	slli	a7,a4,0x20
  80023e:	7139                	addi	sp,sp,-64
  800240:	0208d893          	srli	a7,a7,0x20
  800244:	e456                	sd	s5,8(sp)
  800246:	0316fab3          	remu	s5,a3,a7
  80024a:	f822                	sd	s0,48(sp)
  80024c:	f426                	sd	s1,40(sp)
  80024e:	f04a                	sd	s2,32(sp)
  800250:	ec4e                	sd	s3,24(sp)
  800252:	fc06                	sd	ra,56(sp)
  800254:	e852                	sd	s4,16(sp)
  800256:	84aa                	mv	s1,a0
  800258:	89ae                	mv	s3,a1
  80025a:	8932                	mv	s2,a2
  80025c:	fff7841b          	addiw	s0,a5,-1
  800260:	2a81                	sext.w	s5,s5
  800262:	0516f163          	bgeu	a3,a7,8002a4 <printnum+0x6a>
  800266:	8a42                	mv	s4,a6
  800268:	00805863          	blez	s0,800278 <printnum+0x3e>
  80026c:	347d                	addiw	s0,s0,-1
  80026e:	864e                	mv	a2,s3
  800270:	85ca                	mv	a1,s2
  800272:	8552                	mv	a0,s4
  800274:	9482                	jalr	s1
  800276:	f87d                	bnez	s0,80026c <printnum+0x32>
  800278:	1a82                	slli	s5,s5,0x20
  80027a:	020ada93          	srli	s5,s5,0x20
  80027e:	00000797          	auipc	a5,0x0
  800282:	49a78793          	addi	a5,a5,1178 # 800718 <main+0xca>
  800286:	7442                	ld	s0,48(sp)
  800288:	9abe                	add	s5,s5,a5
  80028a:	000ac503          	lbu	a0,0(s5)
  80028e:	70e2                	ld	ra,56(sp)
  800290:	6a42                	ld	s4,16(sp)
  800292:	6aa2                	ld	s5,8(sp)
  800294:	864e                	mv	a2,s3
  800296:	85ca                	mv	a1,s2
  800298:	69e2                	ld	s3,24(sp)
  80029a:	7902                	ld	s2,32(sp)
  80029c:	8326                	mv	t1,s1
  80029e:	74a2                	ld	s1,40(sp)
  8002a0:	6121                	addi	sp,sp,64
  8002a2:	8302                	jr	t1
  8002a4:	0316d6b3          	divu	a3,a3,a7
  8002a8:	87a2                	mv	a5,s0
  8002aa:	f91ff0ef          	jal	ra,80023a <printnum>
  8002ae:	b7e9                	j	800278 <printnum+0x3e>

00000000008002b0 <vprintfmt>:
  8002b0:	7119                	addi	sp,sp,-128
  8002b2:	f4a6                	sd	s1,104(sp)
  8002b4:	f0ca                	sd	s2,96(sp)
  8002b6:	ecce                	sd	s3,88(sp)
  8002b8:	e8d2                	sd	s4,80(sp)
  8002ba:	e4d6                	sd	s5,72(sp)
  8002bc:	e0da                	sd	s6,64(sp)
  8002be:	fc5e                	sd	s7,56(sp)
  8002c0:	ec6e                	sd	s11,24(sp)
  8002c2:	fc86                	sd	ra,120(sp)
  8002c4:	f8a2                	sd	s0,112(sp)
  8002c6:	f862                	sd	s8,48(sp)
  8002c8:	f466                	sd	s9,40(sp)
  8002ca:	f06a                	sd	s10,32(sp)
  8002cc:	89aa                	mv	s3,a0
  8002ce:	892e                	mv	s2,a1
  8002d0:	84b2                	mv	s1,a2
  8002d2:	8db6                	mv	s11,a3
  8002d4:	8aba                	mv	s5,a4
  8002d6:	02500a13          	li	s4,37
  8002da:	5bfd                	li	s7,-1
  8002dc:	00000b17          	auipc	s6,0x0
  8002e0:	470b0b13          	addi	s6,s6,1136 # 80074c <main+0xfe>
  8002e4:	000dc503          	lbu	a0,0(s11)
  8002e8:	001d8413          	addi	s0,s11,1
  8002ec:	01450b63          	beq	a0,s4,800302 <vprintfmt+0x52>
  8002f0:	c129                	beqz	a0,800332 <vprintfmt+0x82>
  8002f2:	864a                	mv	a2,s2
  8002f4:	85a6                	mv	a1,s1
  8002f6:	0405                	addi	s0,s0,1
  8002f8:	9982                	jalr	s3
  8002fa:	fff44503          	lbu	a0,-1(s0)
  8002fe:	ff4519e3          	bne	a0,s4,8002f0 <vprintfmt+0x40>
  800302:	00044583          	lbu	a1,0(s0)
  800306:	02000813          	li	a6,32
  80030a:	4d01                	li	s10,0
  80030c:	4301                	li	t1,0
  80030e:	5cfd                	li	s9,-1
  800310:	5c7d                	li	s8,-1
  800312:	05500513          	li	a0,85
  800316:	48a5                	li	a7,9
  800318:	fdd5861b          	addiw	a2,a1,-35
  80031c:	0ff67613          	andi	a2,a2,255
  800320:	00140d93          	addi	s11,s0,1
  800324:	04c56263          	bltu	a0,a2,800368 <vprintfmt+0xb8>
  800328:	060a                	slli	a2,a2,0x2
  80032a:	965a                	add	a2,a2,s6
  80032c:	4214                	lw	a3,0(a2)
  80032e:	96da                	add	a3,a3,s6
  800330:	8682                	jr	a3
  800332:	70e6                	ld	ra,120(sp)
  800334:	7446                	ld	s0,112(sp)
  800336:	74a6                	ld	s1,104(sp)
  800338:	7906                	ld	s2,96(sp)
  80033a:	69e6                	ld	s3,88(sp)
  80033c:	6a46                	ld	s4,80(sp)
  80033e:	6aa6                	ld	s5,72(sp)
  800340:	6b06                	ld	s6,64(sp)
  800342:	7be2                	ld	s7,56(sp)
  800344:	7c42                	ld	s8,48(sp)
  800346:	7ca2                	ld	s9,40(sp)
  800348:	7d02                	ld	s10,32(sp)
  80034a:	6de2                	ld	s11,24(sp)
  80034c:	6109                	addi	sp,sp,128
  80034e:	8082                	ret
  800350:	882e                	mv	a6,a1
  800352:	00144583          	lbu	a1,1(s0)
  800356:	846e                	mv	s0,s11
  800358:	00140d93          	addi	s11,s0,1
  80035c:	fdd5861b          	addiw	a2,a1,-35
  800360:	0ff67613          	andi	a2,a2,255
  800364:	fcc572e3          	bgeu	a0,a2,800328 <vprintfmt+0x78>
  800368:	864a                	mv	a2,s2
  80036a:	85a6                	mv	a1,s1
  80036c:	02500513          	li	a0,37
  800370:	9982                	jalr	s3
  800372:	fff44783          	lbu	a5,-1(s0)
  800376:	8da2                	mv	s11,s0
  800378:	f74786e3          	beq	a5,s4,8002e4 <vprintfmt+0x34>
  80037c:	ffedc783          	lbu	a5,-2(s11)
  800380:	1dfd                	addi	s11,s11,-1
  800382:	ff479de3          	bne	a5,s4,80037c <vprintfmt+0xcc>
  800386:	bfb9                	j	8002e4 <vprintfmt+0x34>
  800388:	fd058c9b          	addiw	s9,a1,-48
  80038c:	00144583          	lbu	a1,1(s0)
  800390:	846e                	mv	s0,s11
  800392:	fd05869b          	addiw	a3,a1,-48
  800396:	0005861b          	sext.w	a2,a1
  80039a:	02d8e463          	bltu	a7,a3,8003c2 <vprintfmt+0x112>
  80039e:	00144583          	lbu	a1,1(s0)
  8003a2:	002c969b          	slliw	a3,s9,0x2
  8003a6:	0196873b          	addw	a4,a3,s9
  8003aa:	0017171b          	slliw	a4,a4,0x1
  8003ae:	9f31                	addw	a4,a4,a2
  8003b0:	fd05869b          	addiw	a3,a1,-48
  8003b4:	0405                	addi	s0,s0,1
  8003b6:	fd070c9b          	addiw	s9,a4,-48
  8003ba:	0005861b          	sext.w	a2,a1
  8003be:	fed8f0e3          	bgeu	a7,a3,80039e <vprintfmt+0xee>
  8003c2:	f40c5be3          	bgez	s8,800318 <vprintfmt+0x68>
  8003c6:	8c66                	mv	s8,s9
  8003c8:	5cfd                	li	s9,-1
  8003ca:	b7b9                	j	800318 <vprintfmt+0x68>
  8003cc:	fffc4693          	not	a3,s8
  8003d0:	96fd                	srai	a3,a3,0x3f
  8003d2:	00dc77b3          	and	a5,s8,a3
  8003d6:	00144583          	lbu	a1,1(s0)
  8003da:	00078c1b          	sext.w	s8,a5
  8003de:	846e                	mv	s0,s11
  8003e0:	bf25                	j	800318 <vprintfmt+0x68>
  8003e2:	000aac83          	lw	s9,0(s5)
  8003e6:	00144583          	lbu	a1,1(s0)
  8003ea:	0aa1                	addi	s5,s5,8
  8003ec:	846e                	mv	s0,s11
  8003ee:	bfd1                	j	8003c2 <vprintfmt+0x112>
  8003f0:	4705                	li	a4,1
  8003f2:	008a8613          	addi	a2,s5,8
  8003f6:	00674463          	blt	a4,t1,8003fe <vprintfmt+0x14e>
  8003fa:	1c030c63          	beqz	t1,8005d2 <vprintfmt+0x322>
  8003fe:	000ab683          	ld	a3,0(s5)
  800402:	4741                	li	a4,16
  800404:	8ab2                	mv	s5,a2
  800406:	2801                	sext.w	a6,a6
  800408:	87e2                	mv	a5,s8
  80040a:	8626                	mv	a2,s1
  80040c:	85ca                	mv	a1,s2
  80040e:	854e                	mv	a0,s3
  800410:	e2bff0ef          	jal	ra,80023a <printnum>
  800414:	bdc1                	j	8002e4 <vprintfmt+0x34>
  800416:	000aa503          	lw	a0,0(s5)
  80041a:	864a                	mv	a2,s2
  80041c:	85a6                	mv	a1,s1
  80041e:	0aa1                	addi	s5,s5,8
  800420:	9982                	jalr	s3
  800422:	b5c9                	j	8002e4 <vprintfmt+0x34>
  800424:	4705                	li	a4,1
  800426:	008a8613          	addi	a2,s5,8
  80042a:	00674463          	blt	a4,t1,800432 <vprintfmt+0x182>
  80042e:	18030d63          	beqz	t1,8005c8 <vprintfmt+0x318>
  800432:	000ab683          	ld	a3,0(s5)
  800436:	4729                	li	a4,10
  800438:	8ab2                	mv	s5,a2
  80043a:	b7f1                	j	800406 <vprintfmt+0x156>
  80043c:	00144583          	lbu	a1,1(s0)
  800440:	4d05                	li	s10,1
  800442:	846e                	mv	s0,s11
  800444:	bdd1                	j	800318 <vprintfmt+0x68>
  800446:	864a                	mv	a2,s2
  800448:	85a6                	mv	a1,s1
  80044a:	02500513          	li	a0,37
  80044e:	9982                	jalr	s3
  800450:	bd51                	j	8002e4 <vprintfmt+0x34>
  800452:	00144583          	lbu	a1,1(s0)
  800456:	2305                	addiw	t1,t1,1
  800458:	846e                	mv	s0,s11
  80045a:	bd7d                	j	800318 <vprintfmt+0x68>
  80045c:	4705                	li	a4,1
  80045e:	008a8613          	addi	a2,s5,8
  800462:	00674463          	blt	a4,t1,80046a <vprintfmt+0x1ba>
  800466:	14030c63          	beqz	t1,8005be <vprintfmt+0x30e>
  80046a:	000ab683          	ld	a3,0(s5)
  80046e:	4721                	li	a4,8
  800470:	8ab2                	mv	s5,a2
  800472:	bf51                	j	800406 <vprintfmt+0x156>
  800474:	03000513          	li	a0,48
  800478:	864a                	mv	a2,s2
  80047a:	85a6                	mv	a1,s1
  80047c:	e042                	sd	a6,0(sp)
  80047e:	9982                	jalr	s3
  800480:	864a                	mv	a2,s2
  800482:	85a6                	mv	a1,s1
  800484:	07800513          	li	a0,120
  800488:	9982                	jalr	s3
  80048a:	0aa1                	addi	s5,s5,8
  80048c:	6802                	ld	a6,0(sp)
  80048e:	4741                	li	a4,16
  800490:	ff8ab683          	ld	a3,-8(s5)
  800494:	bf8d                	j	800406 <vprintfmt+0x156>
  800496:	000ab403          	ld	s0,0(s5)
  80049a:	008a8793          	addi	a5,s5,8
  80049e:	e03e                	sd	a5,0(sp)
  8004a0:	14040c63          	beqz	s0,8005f8 <vprintfmt+0x348>
  8004a4:	11805063          	blez	s8,8005a4 <vprintfmt+0x2f4>
  8004a8:	02d00693          	li	a3,45
  8004ac:	0cd81963          	bne	a6,a3,80057e <vprintfmt+0x2ce>
  8004b0:	00044683          	lbu	a3,0(s0)
  8004b4:	0006851b          	sext.w	a0,a3
  8004b8:	ce8d                	beqz	a3,8004f2 <vprintfmt+0x242>
  8004ba:	00140a93          	addi	s5,s0,1
  8004be:	05e00413          	li	s0,94
  8004c2:	000cc563          	bltz	s9,8004cc <vprintfmt+0x21c>
  8004c6:	3cfd                	addiw	s9,s9,-1
  8004c8:	037c8363          	beq	s9,s7,8004ee <vprintfmt+0x23e>
  8004cc:	864a                	mv	a2,s2
  8004ce:	85a6                	mv	a1,s1
  8004d0:	100d0663          	beqz	s10,8005dc <vprintfmt+0x32c>
  8004d4:	3681                	addiw	a3,a3,-32
  8004d6:	10d47363          	bgeu	s0,a3,8005dc <vprintfmt+0x32c>
  8004da:	03f00513          	li	a0,63
  8004de:	9982                	jalr	s3
  8004e0:	000ac683          	lbu	a3,0(s5)
  8004e4:	3c7d                	addiw	s8,s8,-1
  8004e6:	0a85                	addi	s5,s5,1
  8004e8:	0006851b          	sext.w	a0,a3
  8004ec:	faf9                	bnez	a3,8004c2 <vprintfmt+0x212>
  8004ee:	01805a63          	blez	s8,800502 <vprintfmt+0x252>
  8004f2:	3c7d                	addiw	s8,s8,-1
  8004f4:	864a                	mv	a2,s2
  8004f6:	85a6                	mv	a1,s1
  8004f8:	02000513          	li	a0,32
  8004fc:	9982                	jalr	s3
  8004fe:	fe0c1ae3          	bnez	s8,8004f2 <vprintfmt+0x242>
  800502:	6a82                	ld	s5,0(sp)
  800504:	b3c5                	j	8002e4 <vprintfmt+0x34>
  800506:	4705                	li	a4,1
  800508:	008a8d13          	addi	s10,s5,8
  80050c:	00674463          	blt	a4,t1,800514 <vprintfmt+0x264>
  800510:	0a030463          	beqz	t1,8005b8 <vprintfmt+0x308>
  800514:	000ab403          	ld	s0,0(s5)
  800518:	0c044463          	bltz	s0,8005e0 <vprintfmt+0x330>
  80051c:	86a2                	mv	a3,s0
  80051e:	8aea                	mv	s5,s10
  800520:	4729                	li	a4,10
  800522:	b5d5                	j	800406 <vprintfmt+0x156>
  800524:	000aa783          	lw	a5,0(s5)
  800528:	46e1                	li	a3,24
  80052a:	0aa1                	addi	s5,s5,8
  80052c:	41f7d71b          	sraiw	a4,a5,0x1f
  800530:	8fb9                	xor	a5,a5,a4
  800532:	40e7873b          	subw	a4,a5,a4
  800536:	02e6c663          	blt	a3,a4,800562 <vprintfmt+0x2b2>
  80053a:	00371793          	slli	a5,a4,0x3
  80053e:	00000697          	auipc	a3,0x0
  800542:	54268693          	addi	a3,a3,1346 # 800a80 <error_string>
  800546:	97b6                	add	a5,a5,a3
  800548:	639c                	ld	a5,0(a5)
  80054a:	cf81                	beqz	a5,800562 <vprintfmt+0x2b2>
  80054c:	873e                	mv	a4,a5
  80054e:	00000697          	auipc	a3,0x0
  800552:	1fa68693          	addi	a3,a3,506 # 800748 <main+0xfa>
  800556:	8626                	mv	a2,s1
  800558:	85ca                	mv	a1,s2
  80055a:	854e                	mv	a0,s3
  80055c:	0d4000ef          	jal	ra,800630 <printfmt>
  800560:	b351                	j	8002e4 <vprintfmt+0x34>
  800562:	00000697          	auipc	a3,0x0
  800566:	1d668693          	addi	a3,a3,470 # 800738 <main+0xea>
  80056a:	8626                	mv	a2,s1
  80056c:	85ca                	mv	a1,s2
  80056e:	854e                	mv	a0,s3
  800570:	0c0000ef          	jal	ra,800630 <printfmt>
  800574:	bb85                	j	8002e4 <vprintfmt+0x34>
  800576:	00000417          	auipc	s0,0x0
  80057a:	1ba40413          	addi	s0,s0,442 # 800730 <main+0xe2>
  80057e:	85e6                	mv	a1,s9
  800580:	8522                	mv	a0,s0
  800582:	e442                	sd	a6,8(sp)
  800584:	c9bff0ef          	jal	ra,80021e <strnlen>
  800588:	40ac0c3b          	subw	s8,s8,a0
  80058c:	01805c63          	blez	s8,8005a4 <vprintfmt+0x2f4>
  800590:	6822                	ld	a6,8(sp)
  800592:	00080a9b          	sext.w	s5,a6
  800596:	3c7d                	addiw	s8,s8,-1
  800598:	864a                	mv	a2,s2
  80059a:	85a6                	mv	a1,s1
  80059c:	8556                	mv	a0,s5
  80059e:	9982                	jalr	s3
  8005a0:	fe0c1be3          	bnez	s8,800596 <vprintfmt+0x2e6>
  8005a4:	00044683          	lbu	a3,0(s0)
  8005a8:	00140a93          	addi	s5,s0,1
  8005ac:	0006851b          	sext.w	a0,a3
  8005b0:	daa9                	beqz	a3,800502 <vprintfmt+0x252>
  8005b2:	05e00413          	li	s0,94
  8005b6:	b731                	j	8004c2 <vprintfmt+0x212>
  8005b8:	000aa403          	lw	s0,0(s5)
  8005bc:	bfb1                	j	800518 <vprintfmt+0x268>
  8005be:	000ae683          	lwu	a3,0(s5)
  8005c2:	4721                	li	a4,8
  8005c4:	8ab2                	mv	s5,a2
  8005c6:	b581                	j	800406 <vprintfmt+0x156>
  8005c8:	000ae683          	lwu	a3,0(s5)
  8005cc:	4729                	li	a4,10
  8005ce:	8ab2                	mv	s5,a2
  8005d0:	bd1d                	j	800406 <vprintfmt+0x156>
  8005d2:	000ae683          	lwu	a3,0(s5)
  8005d6:	4741                	li	a4,16
  8005d8:	8ab2                	mv	s5,a2
  8005da:	b535                	j	800406 <vprintfmt+0x156>
  8005dc:	9982                	jalr	s3
  8005de:	b709                	j	8004e0 <vprintfmt+0x230>
  8005e0:	864a                	mv	a2,s2
  8005e2:	85a6                	mv	a1,s1
  8005e4:	02d00513          	li	a0,45
  8005e8:	e042                	sd	a6,0(sp)
  8005ea:	9982                	jalr	s3
  8005ec:	6802                	ld	a6,0(sp)
  8005ee:	8aea                	mv	s5,s10
  8005f0:	408006b3          	neg	a3,s0
  8005f4:	4729                	li	a4,10
  8005f6:	bd01                	j	800406 <vprintfmt+0x156>
  8005f8:	03805163          	blez	s8,80061a <vprintfmt+0x36a>
  8005fc:	02d00693          	li	a3,45
  800600:	f6d81be3          	bne	a6,a3,800576 <vprintfmt+0x2c6>
  800604:	00000417          	auipc	s0,0x0
  800608:	12c40413          	addi	s0,s0,300 # 800730 <main+0xe2>
  80060c:	02800693          	li	a3,40
  800610:	02800513          	li	a0,40
  800614:	00140a93          	addi	s5,s0,1
  800618:	b55d                	j	8004be <vprintfmt+0x20e>
  80061a:	00000a97          	auipc	s5,0x0
  80061e:	117a8a93          	addi	s5,s5,279 # 800731 <main+0xe3>
  800622:	02800513          	li	a0,40
  800626:	02800693          	li	a3,40
  80062a:	05e00413          	li	s0,94
  80062e:	bd51                	j	8004c2 <vprintfmt+0x212>

0000000000800630 <printfmt>:
  800630:	7139                	addi	sp,sp,-64
  800632:	02010313          	addi	t1,sp,32
  800636:	f03a                	sd	a4,32(sp)
  800638:	871a                	mv	a4,t1
  80063a:	ec06                	sd	ra,24(sp)
  80063c:	f43e                	sd	a5,40(sp)
  80063e:	f842                	sd	a6,48(sp)
  800640:	fc46                	sd	a7,56(sp)
  800642:	e41a                	sd	t1,8(sp)
  800644:	c6dff0ef          	jal	ra,8002b0 <vprintfmt>
  800648:	60e2                	ld	ra,24(sp)
  80064a:	6121                	addi	sp,sp,64
  80064c:	8082                	ret

000000000080064e <main>:
  80064e:	00002783          	lw	a5,0(zero) # 0 <__warn-0x800020>
  800652:	9002                	ebreak
