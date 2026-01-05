
obj/__user_hello.out:     file format elf64-littleriscv


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
  800034:	68050513          	addi	a0,a0,1664 # 8006b0 <main+0x5c>
  800038:	ec06                	sd	ra,24(sp)
  80003a:	f436                	sd	a3,40(sp)
  80003c:	f83a                	sd	a4,48(sp)
  80003e:	e0c2                	sd	a6,64(sp)
  800040:	e4c6                	sd	a7,72(sp)
  800042:	e43e                	sd	a5,8(sp)
  800044:	0d4000ef          	jal	ra,800118 <cprintf>
  800048:	65a2                	ld	a1,8(sp)
  80004a:	8522                	mv	a0,s0
  80004c:	0a6000ef          	jal	ra,8000f2 <vcprintf>
  800050:	00001517          	auipc	a0,0x1
  800054:	b5050513          	addi	a0,a0,-1200 # 800ba0 <error_string+0xe8>
  800058:	0c0000ef          	jal	ra,800118 <cprintf>
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

00000000008000a2 <sys_getpid>:
  8000a2:	4549                	li	a0,18
  8000a4:	b7c1                	j	800064 <syscall>

00000000008000a6 <sys_putc>:
  8000a6:	85aa                	mv	a1,a0
  8000a8:	4579                	li	a0,30
  8000aa:	bf6d                	j	800064 <syscall>

00000000008000ac <sys_open>:
  8000ac:	862e                	mv	a2,a1
  8000ae:	85aa                	mv	a1,a0
  8000b0:	06400513          	li	a0,100
  8000b4:	bf45                	j	800064 <syscall>

00000000008000b6 <sys_close>:
  8000b6:	85aa                	mv	a1,a0
  8000b8:	06500513          	li	a0,101
  8000bc:	b765                	j	800064 <syscall>

00000000008000be <sys_dup>:
  8000be:	862e                	mv	a2,a1
  8000c0:	85aa                	mv	a1,a0
  8000c2:	08200513          	li	a0,130
  8000c6:	bf79                	j	800064 <syscall>

00000000008000c8 <_start>:
  8000c8:	0d0000ef          	jal	ra,800198 <umain>
  8000cc:	a001                	j	8000cc <_start+0x4>

00000000008000ce <open>:
  8000ce:	1582                	slli	a1,a1,0x20
  8000d0:	9181                	srli	a1,a1,0x20
  8000d2:	bfe9                	j	8000ac <sys_open>

00000000008000d4 <close>:
  8000d4:	b7cd                	j	8000b6 <sys_close>

00000000008000d6 <dup2>:
  8000d6:	b7e5                	j	8000be <sys_dup>

00000000008000d8 <cputch>:
  8000d8:	1141                	addi	sp,sp,-16
  8000da:	e022                	sd	s0,0(sp)
  8000dc:	e406                	sd	ra,8(sp)
  8000de:	842e                	mv	s0,a1
  8000e0:	fc7ff0ef          	jal	ra,8000a6 <sys_putc>
  8000e4:	401c                	lw	a5,0(s0)
  8000e6:	60a2                	ld	ra,8(sp)
  8000e8:	2785                	addiw	a5,a5,1
  8000ea:	c01c                	sw	a5,0(s0)
  8000ec:	6402                	ld	s0,0(sp)
  8000ee:	0141                	addi	sp,sp,16
  8000f0:	8082                	ret

00000000008000f2 <vcprintf>:
  8000f2:	1101                	addi	sp,sp,-32
  8000f4:	872e                	mv	a4,a1
  8000f6:	75dd                	lui	a1,0xffff7
  8000f8:	86aa                	mv	a3,a0
  8000fa:	0070                	addi	a2,sp,12
  8000fc:	00000517          	auipc	a0,0x0
  800100:	fdc50513          	addi	a0,a0,-36 # 8000d8 <cputch>
  800104:	ad958593          	addi	a1,a1,-1319 # ffffffffffff6ad9 <error_string+0xffffffffff7f6021>
  800108:	ec06                	sd	ra,24(sp)
  80010a:	c602                	sw	zero,12(sp)
  80010c:	1aa000ef          	jal	ra,8002b6 <vprintfmt>
  800110:	60e2                	ld	ra,24(sp)
  800112:	4532                	lw	a0,12(sp)
  800114:	6105                	addi	sp,sp,32
  800116:	8082                	ret

0000000000800118 <cprintf>:
  800118:	711d                	addi	sp,sp,-96
  80011a:	02810313          	addi	t1,sp,40
  80011e:	8e2a                	mv	t3,a0
  800120:	f42e                	sd	a1,40(sp)
  800122:	75dd                	lui	a1,0xffff7
  800124:	f832                	sd	a2,48(sp)
  800126:	fc36                	sd	a3,56(sp)
  800128:	e0ba                	sd	a4,64(sp)
  80012a:	00000517          	auipc	a0,0x0
  80012e:	fae50513          	addi	a0,a0,-82 # 8000d8 <cputch>
  800132:	0050                	addi	a2,sp,4
  800134:	871a                	mv	a4,t1
  800136:	86f2                	mv	a3,t3
  800138:	ad958593          	addi	a1,a1,-1319 # ffffffffffff6ad9 <error_string+0xffffffffff7f6021>
  80013c:	ec06                	sd	ra,24(sp)
  80013e:	e4be                	sd	a5,72(sp)
  800140:	e8c2                	sd	a6,80(sp)
  800142:	ecc6                	sd	a7,88(sp)
  800144:	e41a                	sd	t1,8(sp)
  800146:	c202                	sw	zero,4(sp)
  800148:	16e000ef          	jal	ra,8002b6 <vprintfmt>
  80014c:	60e2                	ld	ra,24(sp)
  80014e:	4512                	lw	a0,4(sp)
  800150:	6125                	addi	sp,sp,96
  800152:	8082                	ret

0000000000800154 <initfd>:
  800154:	1101                	addi	sp,sp,-32
  800156:	87ae                	mv	a5,a1
  800158:	e426                	sd	s1,8(sp)
  80015a:	85b2                	mv	a1,a2
  80015c:	84aa                	mv	s1,a0
  80015e:	853e                	mv	a0,a5
  800160:	e822                	sd	s0,16(sp)
  800162:	ec06                	sd	ra,24(sp)
  800164:	f6bff0ef          	jal	ra,8000ce <open>
  800168:	842a                	mv	s0,a0
  80016a:	00054463          	bltz	a0,800172 <initfd+0x1e>
  80016e:	00951863          	bne	a0,s1,80017e <initfd+0x2a>
  800172:	60e2                	ld	ra,24(sp)
  800174:	8522                	mv	a0,s0
  800176:	6442                	ld	s0,16(sp)
  800178:	64a2                	ld	s1,8(sp)
  80017a:	6105                	addi	sp,sp,32
  80017c:	8082                	ret
  80017e:	8526                	mv	a0,s1
  800180:	f55ff0ef          	jal	ra,8000d4 <close>
  800184:	85a6                	mv	a1,s1
  800186:	8522                	mv	a0,s0
  800188:	f4fff0ef          	jal	ra,8000d6 <dup2>
  80018c:	84aa                	mv	s1,a0
  80018e:	8522                	mv	a0,s0
  800190:	f45ff0ef          	jal	ra,8000d4 <close>
  800194:	8426                	mv	s0,s1
  800196:	bff1                	j	800172 <initfd+0x1e>

0000000000800198 <umain>:
  800198:	1101                	addi	sp,sp,-32
  80019a:	e822                	sd	s0,16(sp)
  80019c:	e426                	sd	s1,8(sp)
  80019e:	842a                	mv	s0,a0
  8001a0:	84ae                	mv	s1,a1
  8001a2:	4601                	li	a2,0
  8001a4:	00000597          	auipc	a1,0x0
  8001a8:	52c58593          	addi	a1,a1,1324 # 8006d0 <main+0x7c>
  8001ac:	4501                	li	a0,0
  8001ae:	ec06                	sd	ra,24(sp)
  8001b0:	fa5ff0ef          	jal	ra,800154 <initfd>
  8001b4:	02054263          	bltz	a0,8001d8 <umain+0x40>
  8001b8:	4605                	li	a2,1
  8001ba:	00000597          	auipc	a1,0x0
  8001be:	55658593          	addi	a1,a1,1366 # 800710 <main+0xbc>
  8001c2:	4505                	li	a0,1
  8001c4:	f91ff0ef          	jal	ra,800154 <initfd>
  8001c8:	02054563          	bltz	a0,8001f2 <umain+0x5a>
  8001cc:	85a6                	mv	a1,s1
  8001ce:	8522                	mv	a0,s0
  8001d0:	484000ef          	jal	ra,800654 <main>
  8001d4:	038000ef          	jal	ra,80020c <exit>
  8001d8:	86aa                	mv	a3,a0
  8001da:	00000617          	auipc	a2,0x0
  8001de:	4fe60613          	addi	a2,a2,1278 # 8006d8 <main+0x84>
  8001e2:	45e9                	li	a1,26
  8001e4:	00000517          	auipc	a0,0x0
  8001e8:	51450513          	addi	a0,a0,1300 # 8006f8 <main+0xa4>
  8001ec:	e35ff0ef          	jal	ra,800020 <__warn>
  8001f0:	b7e1                	j	8001b8 <umain+0x20>
  8001f2:	86aa                	mv	a3,a0
  8001f4:	00000617          	auipc	a2,0x0
  8001f8:	52460613          	addi	a2,a2,1316 # 800718 <main+0xc4>
  8001fc:	45f5                	li	a1,29
  8001fe:	00000517          	auipc	a0,0x0
  800202:	4fa50513          	addi	a0,a0,1274 # 8006f8 <main+0xa4>
  800206:	e1bff0ef          	jal	ra,800020 <__warn>
  80020a:	b7c9                	j	8001cc <umain+0x34>

000000000080020c <exit>:
  80020c:	1141                	addi	sp,sp,-16
  80020e:	e406                	sd	ra,8(sp)
  800210:	e8dff0ef          	jal	ra,80009c <sys_exit>
  800214:	00000517          	auipc	a0,0x0
  800218:	52450513          	addi	a0,a0,1316 # 800738 <main+0xe4>
  80021c:	efdff0ef          	jal	ra,800118 <cprintf>
  800220:	a001                	j	800220 <exit+0x14>

0000000000800222 <getpid>:
  800222:	b541                	j	8000a2 <sys_getpid>

0000000000800224 <strnlen>:
  800224:	872a                	mv	a4,a0
  800226:	4501                	li	a0,0
  800228:	e589                	bnez	a1,800232 <strnlen+0xe>
  80022a:	a811                	j	80023e <strnlen+0x1a>
  80022c:	0505                	addi	a0,a0,1
  80022e:	00a58763          	beq	a1,a0,80023c <strnlen+0x18>
  800232:	00a707b3          	add	a5,a4,a0
  800236:	0007c783          	lbu	a5,0(a5)
  80023a:	fbed                	bnez	a5,80022c <strnlen+0x8>
  80023c:	8082                	ret
  80023e:	8082                	ret

0000000000800240 <printnum>:
  800240:	02071893          	slli	a7,a4,0x20
  800244:	7139                	addi	sp,sp,-64
  800246:	0208d893          	srli	a7,a7,0x20
  80024a:	e456                	sd	s5,8(sp)
  80024c:	0316fab3          	remu	s5,a3,a7
  800250:	f822                	sd	s0,48(sp)
  800252:	f426                	sd	s1,40(sp)
  800254:	f04a                	sd	s2,32(sp)
  800256:	ec4e                	sd	s3,24(sp)
  800258:	fc06                	sd	ra,56(sp)
  80025a:	e852                	sd	s4,16(sp)
  80025c:	84aa                	mv	s1,a0
  80025e:	89ae                	mv	s3,a1
  800260:	8932                	mv	s2,a2
  800262:	fff7841b          	addiw	s0,a5,-1
  800266:	2a81                	sext.w	s5,s5
  800268:	0516f163          	bgeu	a3,a7,8002aa <printnum+0x6a>
  80026c:	8a42                	mv	s4,a6
  80026e:	00805863          	blez	s0,80027e <printnum+0x3e>
  800272:	347d                	addiw	s0,s0,-1
  800274:	864e                	mv	a2,s3
  800276:	85ca                	mv	a1,s2
  800278:	8552                	mv	a0,s4
  80027a:	9482                	jalr	s1
  80027c:	f87d                	bnez	s0,800272 <printnum+0x32>
  80027e:	1a82                	slli	s5,s5,0x20
  800280:	020ada93          	srli	s5,s5,0x20
  800284:	00000797          	auipc	a5,0x0
  800288:	4cc78793          	addi	a5,a5,1228 # 800750 <main+0xfc>
  80028c:	7442                	ld	s0,48(sp)
  80028e:	9abe                	add	s5,s5,a5
  800290:	000ac503          	lbu	a0,0(s5)
  800294:	70e2                	ld	ra,56(sp)
  800296:	6a42                	ld	s4,16(sp)
  800298:	6aa2                	ld	s5,8(sp)
  80029a:	864e                	mv	a2,s3
  80029c:	85ca                	mv	a1,s2
  80029e:	69e2                	ld	s3,24(sp)
  8002a0:	7902                	ld	s2,32(sp)
  8002a2:	8326                	mv	t1,s1
  8002a4:	74a2                	ld	s1,40(sp)
  8002a6:	6121                	addi	sp,sp,64
  8002a8:	8302                	jr	t1
  8002aa:	0316d6b3          	divu	a3,a3,a7
  8002ae:	87a2                	mv	a5,s0
  8002b0:	f91ff0ef          	jal	ra,800240 <printnum>
  8002b4:	b7e9                	j	80027e <printnum+0x3e>

00000000008002b6 <vprintfmt>:
  8002b6:	7119                	addi	sp,sp,-128
  8002b8:	f4a6                	sd	s1,104(sp)
  8002ba:	f0ca                	sd	s2,96(sp)
  8002bc:	ecce                	sd	s3,88(sp)
  8002be:	e8d2                	sd	s4,80(sp)
  8002c0:	e4d6                	sd	s5,72(sp)
  8002c2:	e0da                	sd	s6,64(sp)
  8002c4:	fc5e                	sd	s7,56(sp)
  8002c6:	ec6e                	sd	s11,24(sp)
  8002c8:	fc86                	sd	ra,120(sp)
  8002ca:	f8a2                	sd	s0,112(sp)
  8002cc:	f862                	sd	s8,48(sp)
  8002ce:	f466                	sd	s9,40(sp)
  8002d0:	f06a                	sd	s10,32(sp)
  8002d2:	89aa                	mv	s3,a0
  8002d4:	892e                	mv	s2,a1
  8002d6:	84b2                	mv	s1,a2
  8002d8:	8db6                	mv	s11,a3
  8002da:	8aba                	mv	s5,a4
  8002dc:	02500a13          	li	s4,37
  8002e0:	5bfd                	li	s7,-1
  8002e2:	00000b17          	auipc	s6,0x0
  8002e6:	4a2b0b13          	addi	s6,s6,1186 # 800784 <main+0x130>
  8002ea:	000dc503          	lbu	a0,0(s11)
  8002ee:	001d8413          	addi	s0,s11,1
  8002f2:	01450b63          	beq	a0,s4,800308 <vprintfmt+0x52>
  8002f6:	c129                	beqz	a0,800338 <vprintfmt+0x82>
  8002f8:	864a                	mv	a2,s2
  8002fa:	85a6                	mv	a1,s1
  8002fc:	0405                	addi	s0,s0,1
  8002fe:	9982                	jalr	s3
  800300:	fff44503          	lbu	a0,-1(s0)
  800304:	ff4519e3          	bne	a0,s4,8002f6 <vprintfmt+0x40>
  800308:	00044583          	lbu	a1,0(s0)
  80030c:	02000813          	li	a6,32
  800310:	4d01                	li	s10,0
  800312:	4301                	li	t1,0
  800314:	5cfd                	li	s9,-1
  800316:	5c7d                	li	s8,-1
  800318:	05500513          	li	a0,85
  80031c:	48a5                	li	a7,9
  80031e:	fdd5861b          	addiw	a2,a1,-35
  800322:	0ff67613          	andi	a2,a2,255
  800326:	00140d93          	addi	s11,s0,1
  80032a:	04c56263          	bltu	a0,a2,80036e <vprintfmt+0xb8>
  80032e:	060a                	slli	a2,a2,0x2
  800330:	965a                	add	a2,a2,s6
  800332:	4214                	lw	a3,0(a2)
  800334:	96da                	add	a3,a3,s6
  800336:	8682                	jr	a3
  800338:	70e6                	ld	ra,120(sp)
  80033a:	7446                	ld	s0,112(sp)
  80033c:	74a6                	ld	s1,104(sp)
  80033e:	7906                	ld	s2,96(sp)
  800340:	69e6                	ld	s3,88(sp)
  800342:	6a46                	ld	s4,80(sp)
  800344:	6aa6                	ld	s5,72(sp)
  800346:	6b06                	ld	s6,64(sp)
  800348:	7be2                	ld	s7,56(sp)
  80034a:	7c42                	ld	s8,48(sp)
  80034c:	7ca2                	ld	s9,40(sp)
  80034e:	7d02                	ld	s10,32(sp)
  800350:	6de2                	ld	s11,24(sp)
  800352:	6109                	addi	sp,sp,128
  800354:	8082                	ret
  800356:	882e                	mv	a6,a1
  800358:	00144583          	lbu	a1,1(s0)
  80035c:	846e                	mv	s0,s11
  80035e:	00140d93          	addi	s11,s0,1
  800362:	fdd5861b          	addiw	a2,a1,-35
  800366:	0ff67613          	andi	a2,a2,255
  80036a:	fcc572e3          	bgeu	a0,a2,80032e <vprintfmt+0x78>
  80036e:	864a                	mv	a2,s2
  800370:	85a6                	mv	a1,s1
  800372:	02500513          	li	a0,37
  800376:	9982                	jalr	s3
  800378:	fff44783          	lbu	a5,-1(s0)
  80037c:	8da2                	mv	s11,s0
  80037e:	f74786e3          	beq	a5,s4,8002ea <vprintfmt+0x34>
  800382:	ffedc783          	lbu	a5,-2(s11)
  800386:	1dfd                	addi	s11,s11,-1
  800388:	ff479de3          	bne	a5,s4,800382 <vprintfmt+0xcc>
  80038c:	bfb9                	j	8002ea <vprintfmt+0x34>
  80038e:	fd058c9b          	addiw	s9,a1,-48
  800392:	00144583          	lbu	a1,1(s0)
  800396:	846e                	mv	s0,s11
  800398:	fd05869b          	addiw	a3,a1,-48
  80039c:	0005861b          	sext.w	a2,a1
  8003a0:	02d8e463          	bltu	a7,a3,8003c8 <vprintfmt+0x112>
  8003a4:	00144583          	lbu	a1,1(s0)
  8003a8:	002c969b          	slliw	a3,s9,0x2
  8003ac:	0196873b          	addw	a4,a3,s9
  8003b0:	0017171b          	slliw	a4,a4,0x1
  8003b4:	9f31                	addw	a4,a4,a2
  8003b6:	fd05869b          	addiw	a3,a1,-48
  8003ba:	0405                	addi	s0,s0,1
  8003bc:	fd070c9b          	addiw	s9,a4,-48
  8003c0:	0005861b          	sext.w	a2,a1
  8003c4:	fed8f0e3          	bgeu	a7,a3,8003a4 <vprintfmt+0xee>
  8003c8:	f40c5be3          	bgez	s8,80031e <vprintfmt+0x68>
  8003cc:	8c66                	mv	s8,s9
  8003ce:	5cfd                	li	s9,-1
  8003d0:	b7b9                	j	80031e <vprintfmt+0x68>
  8003d2:	fffc4693          	not	a3,s8
  8003d6:	96fd                	srai	a3,a3,0x3f
  8003d8:	00dc77b3          	and	a5,s8,a3
  8003dc:	00144583          	lbu	a1,1(s0)
  8003e0:	00078c1b          	sext.w	s8,a5
  8003e4:	846e                	mv	s0,s11
  8003e6:	bf25                	j	80031e <vprintfmt+0x68>
  8003e8:	000aac83          	lw	s9,0(s5)
  8003ec:	00144583          	lbu	a1,1(s0)
  8003f0:	0aa1                	addi	s5,s5,8
  8003f2:	846e                	mv	s0,s11
  8003f4:	bfd1                	j	8003c8 <vprintfmt+0x112>
  8003f6:	4705                	li	a4,1
  8003f8:	008a8613          	addi	a2,s5,8
  8003fc:	00674463          	blt	a4,t1,800404 <vprintfmt+0x14e>
  800400:	1c030c63          	beqz	t1,8005d8 <vprintfmt+0x322>
  800404:	000ab683          	ld	a3,0(s5)
  800408:	4741                	li	a4,16
  80040a:	8ab2                	mv	s5,a2
  80040c:	2801                	sext.w	a6,a6
  80040e:	87e2                	mv	a5,s8
  800410:	8626                	mv	a2,s1
  800412:	85ca                	mv	a1,s2
  800414:	854e                	mv	a0,s3
  800416:	e2bff0ef          	jal	ra,800240 <printnum>
  80041a:	bdc1                	j	8002ea <vprintfmt+0x34>
  80041c:	000aa503          	lw	a0,0(s5)
  800420:	864a                	mv	a2,s2
  800422:	85a6                	mv	a1,s1
  800424:	0aa1                	addi	s5,s5,8
  800426:	9982                	jalr	s3
  800428:	b5c9                	j	8002ea <vprintfmt+0x34>
  80042a:	4705                	li	a4,1
  80042c:	008a8613          	addi	a2,s5,8
  800430:	00674463          	blt	a4,t1,800438 <vprintfmt+0x182>
  800434:	18030d63          	beqz	t1,8005ce <vprintfmt+0x318>
  800438:	000ab683          	ld	a3,0(s5)
  80043c:	4729                	li	a4,10
  80043e:	8ab2                	mv	s5,a2
  800440:	b7f1                	j	80040c <vprintfmt+0x156>
  800442:	00144583          	lbu	a1,1(s0)
  800446:	4d05                	li	s10,1
  800448:	846e                	mv	s0,s11
  80044a:	bdd1                	j	80031e <vprintfmt+0x68>
  80044c:	864a                	mv	a2,s2
  80044e:	85a6                	mv	a1,s1
  800450:	02500513          	li	a0,37
  800454:	9982                	jalr	s3
  800456:	bd51                	j	8002ea <vprintfmt+0x34>
  800458:	00144583          	lbu	a1,1(s0)
  80045c:	2305                	addiw	t1,t1,1
  80045e:	846e                	mv	s0,s11
  800460:	bd7d                	j	80031e <vprintfmt+0x68>
  800462:	4705                	li	a4,1
  800464:	008a8613          	addi	a2,s5,8
  800468:	00674463          	blt	a4,t1,800470 <vprintfmt+0x1ba>
  80046c:	14030c63          	beqz	t1,8005c4 <vprintfmt+0x30e>
  800470:	000ab683          	ld	a3,0(s5)
  800474:	4721                	li	a4,8
  800476:	8ab2                	mv	s5,a2
  800478:	bf51                	j	80040c <vprintfmt+0x156>
  80047a:	03000513          	li	a0,48
  80047e:	864a                	mv	a2,s2
  800480:	85a6                	mv	a1,s1
  800482:	e042                	sd	a6,0(sp)
  800484:	9982                	jalr	s3
  800486:	864a                	mv	a2,s2
  800488:	85a6                	mv	a1,s1
  80048a:	07800513          	li	a0,120
  80048e:	9982                	jalr	s3
  800490:	0aa1                	addi	s5,s5,8
  800492:	6802                	ld	a6,0(sp)
  800494:	4741                	li	a4,16
  800496:	ff8ab683          	ld	a3,-8(s5)
  80049a:	bf8d                	j	80040c <vprintfmt+0x156>
  80049c:	000ab403          	ld	s0,0(s5)
  8004a0:	008a8793          	addi	a5,s5,8
  8004a4:	e03e                	sd	a5,0(sp)
  8004a6:	14040c63          	beqz	s0,8005fe <vprintfmt+0x348>
  8004aa:	11805063          	blez	s8,8005aa <vprintfmt+0x2f4>
  8004ae:	02d00693          	li	a3,45
  8004b2:	0cd81963          	bne	a6,a3,800584 <vprintfmt+0x2ce>
  8004b6:	00044683          	lbu	a3,0(s0)
  8004ba:	0006851b          	sext.w	a0,a3
  8004be:	ce8d                	beqz	a3,8004f8 <vprintfmt+0x242>
  8004c0:	00140a93          	addi	s5,s0,1
  8004c4:	05e00413          	li	s0,94
  8004c8:	000cc563          	bltz	s9,8004d2 <vprintfmt+0x21c>
  8004cc:	3cfd                	addiw	s9,s9,-1
  8004ce:	037c8363          	beq	s9,s7,8004f4 <vprintfmt+0x23e>
  8004d2:	864a                	mv	a2,s2
  8004d4:	85a6                	mv	a1,s1
  8004d6:	100d0663          	beqz	s10,8005e2 <vprintfmt+0x32c>
  8004da:	3681                	addiw	a3,a3,-32
  8004dc:	10d47363          	bgeu	s0,a3,8005e2 <vprintfmt+0x32c>
  8004e0:	03f00513          	li	a0,63
  8004e4:	9982                	jalr	s3
  8004e6:	000ac683          	lbu	a3,0(s5)
  8004ea:	3c7d                	addiw	s8,s8,-1
  8004ec:	0a85                	addi	s5,s5,1
  8004ee:	0006851b          	sext.w	a0,a3
  8004f2:	faf9                	bnez	a3,8004c8 <vprintfmt+0x212>
  8004f4:	01805a63          	blez	s8,800508 <vprintfmt+0x252>
  8004f8:	3c7d                	addiw	s8,s8,-1
  8004fa:	864a                	mv	a2,s2
  8004fc:	85a6                	mv	a1,s1
  8004fe:	02000513          	li	a0,32
  800502:	9982                	jalr	s3
  800504:	fe0c1ae3          	bnez	s8,8004f8 <vprintfmt+0x242>
  800508:	6a82                	ld	s5,0(sp)
  80050a:	b3c5                	j	8002ea <vprintfmt+0x34>
  80050c:	4705                	li	a4,1
  80050e:	008a8d13          	addi	s10,s5,8
  800512:	00674463          	blt	a4,t1,80051a <vprintfmt+0x264>
  800516:	0a030463          	beqz	t1,8005be <vprintfmt+0x308>
  80051a:	000ab403          	ld	s0,0(s5)
  80051e:	0c044463          	bltz	s0,8005e6 <vprintfmt+0x330>
  800522:	86a2                	mv	a3,s0
  800524:	8aea                	mv	s5,s10
  800526:	4729                	li	a4,10
  800528:	b5d5                	j	80040c <vprintfmt+0x156>
  80052a:	000aa783          	lw	a5,0(s5)
  80052e:	46e1                	li	a3,24
  800530:	0aa1                	addi	s5,s5,8
  800532:	41f7d71b          	sraiw	a4,a5,0x1f
  800536:	8fb9                	xor	a5,a5,a4
  800538:	40e7873b          	subw	a4,a5,a4
  80053c:	02e6c663          	blt	a3,a4,800568 <vprintfmt+0x2b2>
  800540:	00371793          	slli	a5,a4,0x3
  800544:	00000697          	auipc	a3,0x0
  800548:	57468693          	addi	a3,a3,1396 # 800ab8 <error_string>
  80054c:	97b6                	add	a5,a5,a3
  80054e:	639c                	ld	a5,0(a5)
  800550:	cf81                	beqz	a5,800568 <vprintfmt+0x2b2>
  800552:	873e                	mv	a4,a5
  800554:	00000697          	auipc	a3,0x0
  800558:	22c68693          	addi	a3,a3,556 # 800780 <main+0x12c>
  80055c:	8626                	mv	a2,s1
  80055e:	85ca                	mv	a1,s2
  800560:	854e                	mv	a0,s3
  800562:	0d4000ef          	jal	ra,800636 <printfmt>
  800566:	b351                	j	8002ea <vprintfmt+0x34>
  800568:	00000697          	auipc	a3,0x0
  80056c:	20868693          	addi	a3,a3,520 # 800770 <main+0x11c>
  800570:	8626                	mv	a2,s1
  800572:	85ca                	mv	a1,s2
  800574:	854e                	mv	a0,s3
  800576:	0c0000ef          	jal	ra,800636 <printfmt>
  80057a:	bb85                	j	8002ea <vprintfmt+0x34>
  80057c:	00000417          	auipc	s0,0x0
  800580:	1ec40413          	addi	s0,s0,492 # 800768 <main+0x114>
  800584:	85e6                	mv	a1,s9
  800586:	8522                	mv	a0,s0
  800588:	e442                	sd	a6,8(sp)
  80058a:	c9bff0ef          	jal	ra,800224 <strnlen>
  80058e:	40ac0c3b          	subw	s8,s8,a0
  800592:	01805c63          	blez	s8,8005aa <vprintfmt+0x2f4>
  800596:	6822                	ld	a6,8(sp)
  800598:	00080a9b          	sext.w	s5,a6
  80059c:	3c7d                	addiw	s8,s8,-1
  80059e:	864a                	mv	a2,s2
  8005a0:	85a6                	mv	a1,s1
  8005a2:	8556                	mv	a0,s5
  8005a4:	9982                	jalr	s3
  8005a6:	fe0c1be3          	bnez	s8,80059c <vprintfmt+0x2e6>
  8005aa:	00044683          	lbu	a3,0(s0)
  8005ae:	00140a93          	addi	s5,s0,1
  8005b2:	0006851b          	sext.w	a0,a3
  8005b6:	daa9                	beqz	a3,800508 <vprintfmt+0x252>
  8005b8:	05e00413          	li	s0,94
  8005bc:	b731                	j	8004c8 <vprintfmt+0x212>
  8005be:	000aa403          	lw	s0,0(s5)
  8005c2:	bfb1                	j	80051e <vprintfmt+0x268>
  8005c4:	000ae683          	lwu	a3,0(s5)
  8005c8:	4721                	li	a4,8
  8005ca:	8ab2                	mv	s5,a2
  8005cc:	b581                	j	80040c <vprintfmt+0x156>
  8005ce:	000ae683          	lwu	a3,0(s5)
  8005d2:	4729                	li	a4,10
  8005d4:	8ab2                	mv	s5,a2
  8005d6:	bd1d                	j	80040c <vprintfmt+0x156>
  8005d8:	000ae683          	lwu	a3,0(s5)
  8005dc:	4741                	li	a4,16
  8005de:	8ab2                	mv	s5,a2
  8005e0:	b535                	j	80040c <vprintfmt+0x156>
  8005e2:	9982                	jalr	s3
  8005e4:	b709                	j	8004e6 <vprintfmt+0x230>
  8005e6:	864a                	mv	a2,s2
  8005e8:	85a6                	mv	a1,s1
  8005ea:	02d00513          	li	a0,45
  8005ee:	e042                	sd	a6,0(sp)
  8005f0:	9982                	jalr	s3
  8005f2:	6802                	ld	a6,0(sp)
  8005f4:	8aea                	mv	s5,s10
  8005f6:	408006b3          	neg	a3,s0
  8005fa:	4729                	li	a4,10
  8005fc:	bd01                	j	80040c <vprintfmt+0x156>
  8005fe:	03805163          	blez	s8,800620 <vprintfmt+0x36a>
  800602:	02d00693          	li	a3,45
  800606:	f6d81be3          	bne	a6,a3,80057c <vprintfmt+0x2c6>
  80060a:	00000417          	auipc	s0,0x0
  80060e:	15e40413          	addi	s0,s0,350 # 800768 <main+0x114>
  800612:	02800693          	li	a3,40
  800616:	02800513          	li	a0,40
  80061a:	00140a93          	addi	s5,s0,1
  80061e:	b55d                	j	8004c4 <vprintfmt+0x20e>
  800620:	00000a97          	auipc	s5,0x0
  800624:	149a8a93          	addi	s5,s5,329 # 800769 <main+0x115>
  800628:	02800513          	li	a0,40
  80062c:	02800693          	li	a3,40
  800630:	05e00413          	li	s0,94
  800634:	bd51                	j	8004c8 <vprintfmt+0x212>

0000000000800636 <printfmt>:
  800636:	7139                	addi	sp,sp,-64
  800638:	02010313          	addi	t1,sp,32
  80063c:	f03a                	sd	a4,32(sp)
  80063e:	871a                	mv	a4,t1
  800640:	ec06                	sd	ra,24(sp)
  800642:	f43e                	sd	a5,40(sp)
  800644:	f842                	sd	a6,48(sp)
  800646:	fc46                	sd	a7,56(sp)
  800648:	e41a                	sd	t1,8(sp)
  80064a:	c6dff0ef          	jal	ra,8002b6 <vprintfmt>
  80064e:	60e2                	ld	ra,24(sp)
  800650:	6121                	addi	sp,sp,64
  800652:	8082                	ret

0000000000800654 <main>:
  800654:	1141                	addi	sp,sp,-16
  800656:	00000517          	auipc	a0,0x0
  80065a:	52a50513          	addi	a0,a0,1322 # 800b80 <error_string+0xc8>
  80065e:	e406                	sd	ra,8(sp)
  800660:	ab9ff0ef          	jal	ra,800118 <cprintf>
  800664:	bbfff0ef          	jal	ra,800222 <getpid>
  800668:	85aa                	mv	a1,a0
  80066a:	00000517          	auipc	a0,0x0
  80066e:	52650513          	addi	a0,a0,1318 # 800b90 <error_string+0xd8>
  800672:	aa7ff0ef          	jal	ra,800118 <cprintf>
  800676:	00000517          	auipc	a0,0x0
  80067a:	53250513          	addi	a0,a0,1330 # 800ba8 <error_string+0xf0>
  80067e:	a9bff0ef          	jal	ra,800118 <cprintf>
  800682:	60a2                	ld	ra,8(sp)
  800684:	4501                	li	a0,0
  800686:	0141                	addi	sp,sp,16
  800688:	8082                	ret
