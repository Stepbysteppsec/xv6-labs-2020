
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	80013103          	ld	sp,-2048(sp) # 80008800 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	c1478793          	addi	a5,a5,-1004 # 80005c70 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e0478793          	addi	a5,a5,-508 # 80000eaa <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	af4080e7          	jalr	-1292(ra) # 80000c00 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305c63          	blez	s3,8000016c <consolewrite+0x80>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3b0080e7          	jalr	944(ra) # 800024d6 <either_copyin>
    8000012e:	01550d63          	beq	a0,s5,80000148 <consolewrite+0x5c>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	79a080e7          	jalr	1946(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
    80000146:	894e                	mv	s2,s3
  }
  release(&cons.lock);
    80000148:	00011517          	auipc	a0,0x11
    8000014c:	6e850513          	addi	a0,a0,1768 # 80011830 <cons>
    80000150:	00001097          	auipc	ra,0x1
    80000154:	b64080e7          	jalr	-1180(ra) # 80000cb4 <release>

  return i;
}
    80000158:	854a                	mv	a0,s2
    8000015a:	60a6                	ld	ra,72(sp)
    8000015c:	6406                	ld	s0,64(sp)
    8000015e:	74e2                	ld	s1,56(sp)
    80000160:	7942                	ld	s2,48(sp)
    80000162:	79a2                	ld	s3,40(sp)
    80000164:	7a02                	ld	s4,32(sp)
    80000166:	6ae2                	ld	s5,24(sp)
    80000168:	6161                	addi	sp,sp,80
    8000016a:	8082                	ret
  for(i = 0; i < n; i++){
    8000016c:	4901                	li	s2,0
    8000016e:	bfe9                	j	80000148 <consolewrite+0x5c>

0000000080000170 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000170:	7159                	addi	sp,sp,-112
    80000172:	f486                	sd	ra,104(sp)
    80000174:	f0a2                	sd	s0,96(sp)
    80000176:	eca6                	sd	s1,88(sp)
    80000178:	e8ca                	sd	s2,80(sp)
    8000017a:	e4ce                	sd	s3,72(sp)
    8000017c:	e0d2                	sd	s4,64(sp)
    8000017e:	fc56                	sd	s5,56(sp)
    80000180:	f85a                	sd	s6,48(sp)
    80000182:	f45e                	sd	s7,40(sp)
    80000184:	f062                	sd	s8,32(sp)
    80000186:	ec66                	sd	s9,24(sp)
    80000188:	e86a                	sd	s10,16(sp)
    8000018a:	1880                	addi	s0,sp,112
    8000018c:	8aaa                	mv	s5,a0
    8000018e:	8a2e                	mv	s4,a1
    80000190:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a62080e7          	jalr	-1438(ra) # 80000c00 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	00011917          	auipc	s2,0x11
    800001b2:	71a90913          	addi	s2,s2,1818 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b6:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b8:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ba:	4ca9                	li	s9,10
  while(n > 0){
    800001bc:	07305863          	blez	s3,8000022c <consoleread+0xbc>
    while(cons.r == cons.w){
    800001c0:	0984a783          	lw	a5,152(s1)
    800001c4:	09c4a703          	lw	a4,156(s1)
    800001c8:	02f71463          	bne	a4,a5,800001f0 <consoleread+0x80>
      if(myproc()->killed){
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	842080e7          	jalr	-1982(ra) # 80001a0e <myproc>
    800001d4:	591c                	lw	a5,48(a0)
    800001d6:	e7b5                	bnez	a5,80000242 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d8:	85a6                	mv	a1,s1
    800001da:	854a                	mv	a0,s2
    800001dc:	00002097          	auipc	ra,0x2
    800001e0:	04a080e7          	jalr	74(ra) # 80002226 <sleep>
    while(cons.r == cons.w){
    800001e4:	0984a783          	lw	a5,152(s1)
    800001e8:	09c4a703          	lw	a4,156(s1)
    800001ec:	fef700e3          	beq	a4,a5,800001cc <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f0:	0017871b          	addiw	a4,a5,1
    800001f4:	08e4ac23          	sw	a4,152(s1)
    800001f8:	07f7f713          	andi	a4,a5,127
    800001fc:	9726                	add	a4,a4,s1
    800001fe:	01874703          	lbu	a4,24(a4)
    80000202:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000206:	077d0563          	beq	s10,s7,80000270 <consoleread+0x100>
    cbuf = c;
    8000020a:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020e:	4685                	li	a3,1
    80000210:	f9f40613          	addi	a2,s0,-97
    80000214:	85d2                	mv	a1,s4
    80000216:	8556                	mv	a0,s5
    80000218:	00002097          	auipc	ra,0x2
    8000021c:	268080e7          	jalr	616(ra) # 80002480 <either_copyout>
    80000220:	01850663          	beq	a0,s8,8000022c <consoleread+0xbc>
    dst++;
    80000224:	0a05                	addi	s4,s4,1
    --n;
    80000226:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000228:	f99d1ae3          	bne	s10,s9,800001bc <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	60450513          	addi	a0,a0,1540 # 80011830 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	a80080e7          	jalr	-1408(ra) # 80000cb4 <release>

  return target - n;
    8000023c:	413b053b          	subw	a0,s6,s3
    80000240:	a811                	j	80000254 <consoleread+0xe4>
        release(&cons.lock);
    80000242:	00011517          	auipc	a0,0x11
    80000246:	5ee50513          	addi	a0,a0,1518 # 80011830 <cons>
    8000024a:	00001097          	auipc	ra,0x1
    8000024e:	a6a080e7          	jalr	-1430(ra) # 80000cb4 <release>
        return -1;
    80000252:	557d                	li	a0,-1
}
    80000254:	70a6                	ld	ra,104(sp)
    80000256:	7406                	ld	s0,96(sp)
    80000258:	64e6                	ld	s1,88(sp)
    8000025a:	6946                	ld	s2,80(sp)
    8000025c:	69a6                	ld	s3,72(sp)
    8000025e:	6a06                	ld	s4,64(sp)
    80000260:	7ae2                	ld	s5,56(sp)
    80000262:	7b42                	ld	s6,48(sp)
    80000264:	7ba2                	ld	s7,40(sp)
    80000266:	7c02                	ld	s8,32(sp)
    80000268:	6ce2                	ld	s9,24(sp)
    8000026a:	6d42                	ld	s10,16(sp)
    8000026c:	6165                	addi	sp,sp,112
    8000026e:	8082                	ret
      if(n < target){
    80000270:	0009871b          	sext.w	a4,s3
    80000274:	fb677ce3          	bgeu	a4,s6,8000022c <consoleread+0xbc>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	64f72823          	sw	a5,1616(a4) # 800118c8 <cons+0x98>
    80000280:	b775                	j	8000022c <consoleread+0xbc>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	560080e7          	jalr	1376(ra) # 800007f2 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	54e080e7          	jalr	1358(ra) # 800007f2 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	542080e7          	jalr	1346(ra) # 800007f2 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	538080e7          	jalr	1336(ra) # 800007f2 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	55e50513          	addi	a0,a0,1374 # 80011830 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	926080e7          	jalr	-1754(ra) # 80000c00 <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	234080e7          	jalr	564(ra) # 8000252c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	53050513          	addi	a0,a0,1328 # 80011830 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	9ac080e7          	jalr	-1620(ra) # 80000cb4 <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000324:	00011717          	auipc	a4,0x11
    80000328:	50c70713          	addi	a4,a4,1292 # 80011830 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	4e278793          	addi	a5,a5,1250 # 80011830 <cons>
    80000356:	0a07a703          	lw	a4,160(a5)
    8000035a:	0017069b          	addiw	a3,a4,1
    8000035e:	0006861b          	sext.w	a2,a3
    80000362:	0ad7a023          	sw	a3,160(a5)
    80000366:	07f77713          	andi	a4,a4,127
    8000036a:	97ba                	add	a5,a5,a4
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	54c7a783          	lw	a5,1356(a5) # 800118c8 <cons+0x98>
    80000384:	0807879b          	addiw	a5,a5,128
    80000388:	f6f61ce3          	bne	a2,a5,80000300 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038c:	863e                	mv	a2,a5
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	4a070713          	addi	a4,a4,1184 # 80011830 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	49048493          	addi	s1,s1,1168 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	45470713          	addi	a4,a4,1108 # 80011830 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	4cf72f23          	sw	a5,1246(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000418:	00011797          	auipc	a5,0x11
    8000041c:	41878793          	addi	a5,a5,1048 # 80011830 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	48c7a823          	sw	a2,1168(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	48450513          	addi	a0,a0,1156 # 800118c8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	f5a080e7          	jalr	-166(ra) # 800023a6 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00011517          	auipc	a0,0x11
    8000046a:	3ca50513          	addi	a0,a0,970 # 80011830 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	702080e7          	jalr	1794(ra) # 80000b70 <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	32c080e7          	jalr	812(ra) # 800007a2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	53278793          	addi	a5,a5,1330 # 800219b0 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cea70713          	addi	a4,a4,-790 # 80000170 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c5c70713          	addi	a4,a4,-932 # 800000ec <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054763          	bltz	a0,8000053e <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088c63          	beqz	a7,80000504 <printint+0x62>
    buf[i++] = '-';
    800004f0:	fe070793          	addi	a5,a4,-32
    800004f4:	00878733          	add	a4,a5,s0
    800004f8:	02d00793          	li	a5,45
    800004fc:	fef70823          	sb	a5,-16(a4)
    80000500:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000504:	02e05763          	blez	a4,80000532 <printint+0x90>
    80000508:	fd040793          	addi	a5,s0,-48
    8000050c:	00e784b3          	add	s1,a5,a4
    80000510:	fff78913          	addi	s2,a5,-1
    80000514:	993a                	add	s2,s2,a4
    80000516:	377d                	addiw	a4,a4,-1
    80000518:	1702                	slli	a4,a4,0x20
    8000051a:	9301                	srli	a4,a4,0x20
    8000051c:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000520:	fff4c503          	lbu	a0,-1(s1)
    80000524:	00000097          	auipc	ra,0x0
    80000528:	d5e080e7          	jalr	-674(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052c:	14fd                	addi	s1,s1,-1
    8000052e:	ff2499e3          	bne	s1,s2,80000520 <printint+0x7e>
}
    80000532:	70a2                	ld	ra,40(sp)
    80000534:	7402                	ld	s0,32(sp)
    80000536:	64e2                	ld	s1,24(sp)
    80000538:	6942                	ld	s2,16(sp)
    8000053a:	6145                	addi	sp,sp,48
    8000053c:	8082                	ret
    x = -xx;
    8000053e:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000542:	4885                	li	a7,1
    x = -xx;
    80000544:	bf95                	j	800004b8 <printint+0x16>

0000000080000546 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000546:	1101                	addi	sp,sp,-32
    80000548:	ec06                	sd	ra,24(sp)
    8000054a:	e822                	sd	s0,16(sp)
    8000054c:	e426                	sd	s1,8(sp)
    8000054e:	1000                	addi	s0,sp,32
    80000550:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000552:	00011797          	auipc	a5,0x11
    80000556:	3807af23          	sw	zero,926(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055a:	00008517          	auipc	a0,0x8
    8000055e:	abe50513          	addi	a0,a0,-1346 # 80008018 <etext+0x18>
    80000562:	00000097          	auipc	ra,0x0
    80000566:	02e080e7          	jalr	46(ra) # 80000590 <printf>
  printf(s);
    8000056a:	8526                	mv	a0,s1
    8000056c:	00000097          	auipc	ra,0x0
    80000570:	024080e7          	jalr	36(ra) # 80000590 <printf>
  printf("\n");
    80000574:	00008517          	auipc	a0,0x8
    80000578:	b5450513          	addi	a0,a0,-1196 # 800080c8 <digits+0x88>
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	014080e7          	jalr	20(ra) # 80000590 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000584:	4785                	li	a5,1
    80000586:	00009717          	auipc	a4,0x9
    8000058a:	a6f72d23          	sw	a5,-1414(a4) # 80009000 <panicked>
  for(;;)
    8000058e:	a001                	j	8000058e <panic+0x48>

0000000080000590 <printf>:
{
    80000590:	7131                	addi	sp,sp,-192
    80000592:	fc86                	sd	ra,120(sp)
    80000594:	f8a2                	sd	s0,112(sp)
    80000596:	f4a6                	sd	s1,104(sp)
    80000598:	f0ca                	sd	s2,96(sp)
    8000059a:	ecce                	sd	s3,88(sp)
    8000059c:	e8d2                	sd	s4,80(sp)
    8000059e:	e4d6                	sd	s5,72(sp)
    800005a0:	e0da                	sd	s6,64(sp)
    800005a2:	fc5e                	sd	s7,56(sp)
    800005a4:	f862                	sd	s8,48(sp)
    800005a6:	f466                	sd	s9,40(sp)
    800005a8:	f06a                	sd	s10,32(sp)
    800005aa:	ec6e                	sd	s11,24(sp)
    800005ac:	0100                	addi	s0,sp,128
    800005ae:	8a2a                	mv	s4,a0
    800005b0:	e40c                	sd	a1,8(s0)
    800005b2:	e810                	sd	a2,16(s0)
    800005b4:	ec14                	sd	a3,24(s0)
    800005b6:	f018                	sd	a4,32(s0)
    800005b8:	f41c                	sd	a5,40(s0)
    800005ba:	03043823          	sd	a6,48(s0)
    800005be:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c2:	00011d97          	auipc	s11,0x11
    800005c6:	32edad83          	lw	s11,814(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005ca:	020d9b63          	bnez	s11,80000600 <printf+0x70>
  if (fmt == 0)
    800005ce:	040a0263          	beqz	s4,80000612 <printf+0x82>
  va_start(ap, fmt);
    800005d2:	00840793          	addi	a5,s0,8
    800005d6:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005da:	000a4503          	lbu	a0,0(s4)
    800005de:	14050f63          	beqz	a0,8000073c <printf+0x1ac>
    800005e2:	4981                	li	s3,0
    if(c != '%'){
    800005e4:	02500a93          	li	s5,37
    switch(c){
    800005e8:	07000b93          	li	s7,112
  consputc('x');
    800005ec:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ee:	00008b17          	auipc	s6,0x8
    800005f2:	a52b0b13          	addi	s6,s6,-1454 # 80008040 <digits>
    switch(c){
    800005f6:	07300c93          	li	s9,115
    800005fa:	06400c13          	li	s8,100
    800005fe:	a82d                	j	80000638 <printf+0xa8>
    acquire(&pr.lock);
    80000600:	00011517          	auipc	a0,0x11
    80000604:	2d850513          	addi	a0,a0,728 # 800118d8 <pr>
    80000608:	00000097          	auipc	ra,0x0
    8000060c:	5f8080e7          	jalr	1528(ra) # 80000c00 <acquire>
    80000610:	bf7d                	j	800005ce <printf+0x3e>
    panic("null fmt");
    80000612:	00008517          	auipc	a0,0x8
    80000616:	a1650513          	addi	a0,a0,-1514 # 80008028 <etext+0x28>
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	f2c080e7          	jalr	-212(ra) # 80000546 <panic>
      consputc(c);
    80000622:	00000097          	auipc	ra,0x0
    80000626:	c60080e7          	jalr	-928(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062a:	2985                	addiw	s3,s3,1
    8000062c:	013a07b3          	add	a5,s4,s3
    80000630:	0007c503          	lbu	a0,0(a5)
    80000634:	10050463          	beqz	a0,8000073c <printf+0x1ac>
    if(c != '%'){
    80000638:	ff5515e3          	bne	a0,s5,80000622 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063c:	2985                	addiw	s3,s3,1
    8000063e:	013a07b3          	add	a5,s4,s3
    80000642:	0007c783          	lbu	a5,0(a5)
    80000646:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000064a:	cbed                	beqz	a5,8000073c <printf+0x1ac>
    switch(c){
    8000064c:	05778a63          	beq	a5,s7,800006a0 <printf+0x110>
    80000650:	02fbf663          	bgeu	s7,a5,8000067c <printf+0xec>
    80000654:	09978863          	beq	a5,s9,800006e4 <printf+0x154>
    80000658:	07800713          	li	a4,120
    8000065c:	0ce79563          	bne	a5,a4,80000726 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4605                	li	a2,1
    8000066e:	85ea                	mv	a1,s10
    80000670:	4388                	lw	a0,0(a5)
    80000672:	00000097          	auipc	ra,0x0
    80000676:	e30080e7          	jalr	-464(ra) # 800004a2 <printint>
      break;
    8000067a:	bf45                	j	8000062a <printf+0x9a>
    switch(c){
    8000067c:	09578f63          	beq	a5,s5,8000071a <printf+0x18a>
    80000680:	0b879363          	bne	a5,s8,80000726 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	4605                	li	a2,1
    80000692:	45a9                	li	a1,10
    80000694:	4388                	lw	a0,0(a5)
    80000696:	00000097          	auipc	ra,0x0
    8000069a:	e0c080e7          	jalr	-500(ra) # 800004a2 <printint>
      break;
    8000069e:	b771                	j	8000062a <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a0:	f8843783          	ld	a5,-120(s0)
    800006a4:	00878713          	addi	a4,a5,8
    800006a8:	f8e43423          	sd	a4,-120(s0)
    800006ac:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006b0:	03000513          	li	a0,48
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bce080e7          	jalr	-1074(ra) # 80000282 <consputc>
  consputc('x');
    800006bc:	07800513          	li	a0,120
    800006c0:	00000097          	auipc	ra,0x0
    800006c4:	bc2080e7          	jalr	-1086(ra) # 80000282 <consputc>
    800006c8:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ca:	03c95793          	srli	a5,s2,0x3c
    800006ce:	97da                	add	a5,a5,s6
    800006d0:	0007c503          	lbu	a0,0(a5)
    800006d4:	00000097          	auipc	ra,0x0
    800006d8:	bae080e7          	jalr	-1106(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006dc:	0912                	slli	s2,s2,0x4
    800006de:	34fd                	addiw	s1,s1,-1
    800006e0:	f4ed                	bnez	s1,800006ca <printf+0x13a>
    800006e2:	b7a1                	j	8000062a <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	6384                	ld	s1,0(a5)
    800006f2:	cc89                	beqz	s1,8000070c <printf+0x17c>
      for(; *s; s++)
    800006f4:	0004c503          	lbu	a0,0(s1)
    800006f8:	d90d                	beqz	a0,8000062a <printf+0x9a>
        consputc(*s);
    800006fa:	00000097          	auipc	ra,0x0
    800006fe:	b88080e7          	jalr	-1144(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000702:	0485                	addi	s1,s1,1
    80000704:	0004c503          	lbu	a0,0(s1)
    80000708:	f96d                	bnez	a0,800006fa <printf+0x16a>
    8000070a:	b705                	j	8000062a <printf+0x9a>
        s = "(null)";
    8000070c:	00008497          	auipc	s1,0x8
    80000710:	91448493          	addi	s1,s1,-1772 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000714:	02800513          	li	a0,40
    80000718:	b7cd                	j	800006fa <printf+0x16a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b66080e7          	jalr	-1178(ra) # 80000282 <consputc>
      break;
    80000724:	b719                	j	8000062a <printf+0x9a>
      consputc('%');
    80000726:	8556                	mv	a0,s5
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b5a080e7          	jalr	-1190(ra) # 80000282 <consputc>
      consputc(c);
    80000730:	8526                	mv	a0,s1
    80000732:	00000097          	auipc	ra,0x0
    80000736:	b50080e7          	jalr	-1200(ra) # 80000282 <consputc>
      break;
    8000073a:	bdc5                	j	8000062a <printf+0x9a>
  if(locking)
    8000073c:	020d9163          	bnez	s11,8000075e <printf+0x1ce>
}
    80000740:	70e6                	ld	ra,120(sp)
    80000742:	7446                	ld	s0,112(sp)
    80000744:	74a6                	ld	s1,104(sp)
    80000746:	7906                	ld	s2,96(sp)
    80000748:	69e6                	ld	s3,88(sp)
    8000074a:	6a46                	ld	s4,80(sp)
    8000074c:	6aa6                	ld	s5,72(sp)
    8000074e:	6b06                	ld	s6,64(sp)
    80000750:	7be2                	ld	s7,56(sp)
    80000752:	7c42                	ld	s8,48(sp)
    80000754:	7ca2                	ld	s9,40(sp)
    80000756:	7d02                	ld	s10,32(sp)
    80000758:	6de2                	ld	s11,24(sp)
    8000075a:	6129                	addi	sp,sp,192
    8000075c:	8082                	ret
    release(&pr.lock);
    8000075e:	00011517          	auipc	a0,0x11
    80000762:	17a50513          	addi	a0,a0,378 # 800118d8 <pr>
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	54e080e7          	jalr	1358(ra) # 80000cb4 <release>
}
    8000076e:	bfc9                	j	80000740 <printf+0x1b0>

0000000080000770 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000770:	1101                	addi	sp,sp,-32
    80000772:	ec06                	sd	ra,24(sp)
    80000774:	e822                	sd	s0,16(sp)
    80000776:	e426                	sd	s1,8(sp)
    80000778:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077a:	00011497          	auipc	s1,0x11
    8000077e:	15e48493          	addi	s1,s1,350 # 800118d8 <pr>
    80000782:	00008597          	auipc	a1,0x8
    80000786:	8b658593          	addi	a1,a1,-1866 # 80008038 <etext+0x38>
    8000078a:	8526                	mv	a0,s1
    8000078c:	00000097          	auipc	ra,0x0
    80000790:	3e4080e7          	jalr	996(ra) # 80000b70 <initlock>
  pr.locking = 1;
    80000794:	4785                	li	a5,1
    80000796:	cc9c                	sw	a5,24(s1)
}
    80000798:	60e2                	ld	ra,24(sp)
    8000079a:	6442                	ld	s0,16(sp)
    8000079c:	64a2                	ld	s1,8(sp)
    8000079e:	6105                	addi	sp,sp,32
    800007a0:	8082                	ret

00000000800007a2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a2:	1141                	addi	sp,sp,-16
    800007a4:	e406                	sd	ra,8(sp)
    800007a6:	e022                	sd	s0,0(sp)
    800007a8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007aa:	100007b7          	lui	a5,0x10000
    800007ae:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b2:	f8000713          	li	a4,-128
    800007b6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ba:	470d                	li	a4,3
    800007bc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c8:	469d                	li	a3,7
    800007ca:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ce:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d2:	00008597          	auipc	a1,0x8
    800007d6:	88658593          	addi	a1,a1,-1914 # 80008058 <digits+0x18>
    800007da:	00011517          	auipc	a0,0x11
    800007de:	11e50513          	addi	a0,a0,286 # 800118f8 <uart_tx_lock>
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	38e080e7          	jalr	910(ra) # 80000b70 <initlock>
}
    800007ea:	60a2                	ld	ra,8(sp)
    800007ec:	6402                	ld	s0,0(sp)
    800007ee:	0141                	addi	sp,sp,16
    800007f0:	8082                	ret

00000000800007f2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f2:	1101                	addi	sp,sp,-32
    800007f4:	ec06                	sd	ra,24(sp)
    800007f6:	e822                	sd	s0,16(sp)
    800007f8:	e426                	sd	s1,8(sp)
    800007fa:	1000                	addi	s0,sp,32
    800007fc:	84aa                	mv	s1,a0
  push_off();
    800007fe:	00000097          	auipc	ra,0x0
    80000802:	3b6080e7          	jalr	950(ra) # 80000bb4 <push_off>

  if(panicked){
    80000806:	00008797          	auipc	a5,0x8
    8000080a:	7fa7a783          	lw	a5,2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000812:	c391                	beqz	a5,80000816 <uartputc_sync+0x24>
    for(;;)
    80000814:	a001                	j	80000814 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081a:	0207f793          	andi	a5,a5,32
    8000081e:	dfe5                	beqz	a5,80000816 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000820:	0ff4f513          	zext.b	a0,s1
    80000824:	100007b7          	lui	a5,0x10000
    80000828:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082c:	00000097          	auipc	ra,0x0
    80000830:	428080e7          	jalr	1064(ra) # 80000c54 <pop_off>
}
    80000834:	60e2                	ld	ra,24(sp)
    80000836:	6442                	ld	s0,16(sp)
    80000838:	64a2                	ld	s1,8(sp)
    8000083a:	6105                	addi	sp,sp,32
    8000083c:	8082                	ret

000000008000083e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083e:	00008797          	auipc	a5,0x8
    80000842:	7c67a783          	lw	a5,1990(a5) # 80009004 <uart_tx_r>
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	7c272703          	lw	a4,1986(a4) # 80009008 <uart_tx_w>
    8000084e:	08f70063          	beq	a4,a5,800008ce <uartstart+0x90>
{
    80000852:	7139                	addi	sp,sp,-64
    80000854:	fc06                	sd	ra,56(sp)
    80000856:	f822                	sd	s0,48(sp)
    80000858:	f426                	sd	s1,40(sp)
    8000085a:	f04a                	sd	s2,32(sp)
    8000085c:	ec4e                	sd	s3,24(sp)
    8000085e:	e852                	sd	s4,16(sp)
    80000860:	e456                	sd	s5,8(sp)
    80000862:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000868:	00011a97          	auipc	s5,0x11
    8000086c:	090a8a93          	addi	s5,s5,144 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000870:	00008497          	auipc	s1,0x8
    80000874:	79448493          	addi	s1,s1,1940 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000878:	00008a17          	auipc	s4,0x8
    8000087c:	790a0a13          	addi	s4,s4,1936 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000880:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000884:	02077713          	andi	a4,a4,32
    80000888:	cb15                	beqz	a4,800008bc <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    8000088a:	00fa8733          	add	a4,s5,a5
    8000088e:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000892:	2785                	addiw	a5,a5,1
    80000894:	41f7d71b          	sraiw	a4,a5,0x1f
    80000898:	01b7571b          	srliw	a4,a4,0x1b
    8000089c:	9fb9                	addw	a5,a5,a4
    8000089e:	8bfd                	andi	a5,a5,31
    800008a0:	9f99                	subw	a5,a5,a4
    800008a2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	b00080e7          	jalr	-1280(ra) # 800023a6 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	409c                	lw	a5,0(s1)
    800008b4:	000a2703          	lw	a4,0(s4)
    800008b8:	fcf714e3          	bne	a4,a5,80000880 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008e2:	00011517          	auipc	a0,0x11
    800008e6:	01650513          	addi	a0,a0,22 # 800118f8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	316080e7          	jalr	790(ra) # 80000c00 <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	70e7a783          	lw	a5,1806(a5) # 80009000 <panicked>
    800008fa:	c391                	beqz	a5,800008fe <uartputc+0x2e>
    for(;;)
    800008fc:	a001                	j	800008fc <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fe:	00008697          	auipc	a3,0x8
    80000902:	70a6a683          	lw	a3,1802(a3) # 80009008 <uart_tx_w>
    80000906:	0016879b          	addiw	a5,a3,1
    8000090a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090e:	01b7571b          	srliw	a4,a4,0x1b
    80000912:	9fb9                	addw	a5,a5,a4
    80000914:	8bfd                	andi	a5,a5,31
    80000916:	9f99                	subw	a5,a5,a4
    80000918:	00008717          	auipc	a4,0x8
    8000091c:	6ec72703          	lw	a4,1772(a4) # 80009004 <uart_tx_r>
    80000920:	04f71363          	bne	a4,a5,80000966 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000924:	00011a17          	auipc	s4,0x11
    80000928:	fd4a0a13          	addi	s4,s4,-44 # 800118f8 <uart_tx_lock>
    8000092c:	00008917          	auipc	s2,0x8
    80000930:	6d890913          	addi	s2,s2,1752 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000934:	00008997          	auipc	s3,0x8
    80000938:	6d498993          	addi	s3,s3,1748 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000093c:	85d2                	mv	a1,s4
    8000093e:	854a                	mv	a0,s2
    80000940:	00002097          	auipc	ra,0x2
    80000944:	8e6080e7          	jalr	-1818(ra) # 80002226 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000948:	0009a683          	lw	a3,0(s3)
    8000094c:	0016879b          	addiw	a5,a3,1
    80000950:	41f7d71b          	sraiw	a4,a5,0x1f
    80000954:	01b7571b          	srliw	a4,a4,0x1b
    80000958:	9fb9                	addw	a5,a5,a4
    8000095a:	8bfd                	andi	a5,a5,31
    8000095c:	9f99                	subw	a5,a5,a4
    8000095e:	00092703          	lw	a4,0(s2)
    80000962:	fcf70de3          	beq	a4,a5,8000093c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000966:	00011917          	auipc	s2,0x11
    8000096a:	f9290913          	addi	s2,s2,-110 # 800118f8 <uart_tx_lock>
    8000096e:	96ca                	add	a3,a3,s2
    80000970:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000974:	00008717          	auipc	a4,0x8
    80000978:	68f72a23          	sw	a5,1684(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000097c:	00000097          	auipc	ra,0x0
    80000980:	ec2080e7          	jalr	-318(ra) # 8000083e <uartstart>
      release(&uart_tx_lock);
    80000984:	854a                	mv	a0,s2
    80000986:	00000097          	auipc	ra,0x0
    8000098a:	32e080e7          	jalr	814(ra) # 80000cb4 <release>
}
    8000098e:	70a2                	ld	ra,40(sp)
    80000990:	7402                	ld	s0,32(sp)
    80000992:	64e2                	ld	s1,24(sp)
    80000994:	6942                	ld	s2,16(sp)
    80000996:	69a2                	ld	s3,8(sp)
    80000998:	6a02                	ld	s4,0(sp)
    8000099a:	6145                	addi	sp,sp,48
    8000099c:	8082                	ret

000000008000099e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099e:	1141                	addi	sp,sp,-16
    800009a0:	e422                	sd	s0,8(sp)
    800009a2:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a4:	100007b7          	lui	a5,0x10000
    800009a8:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ac:	8b85                	andi	a5,a5,1
    800009ae:	cb81                	beqz	a5,800009be <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800009b0:	100007b7          	lui	a5,0x10000
    800009b4:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	addi	sp,sp,16
    800009bc:	8082                	ret
    return -1;
    800009be:	557d                	li	a0,-1
    800009c0:	bfe5                	j	800009b8 <uartgetc+0x1a>

00000000800009c2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c2:	1101                	addi	sp,sp,-32
    800009c4:	ec06                	sd	ra,24(sp)
    800009c6:	e822                	sd	s0,16(sp)
    800009c8:	e426                	sd	s1,8(sp)
    800009ca:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009cc:	54fd                	li	s1,-1
    800009ce:	a029                	j	800009d8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	8f4080e7          	jalr	-1804(ra) # 800002c4 <consoleintr>
    int c = uartgetc();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	fc6080e7          	jalr	-58(ra) # 8000099e <uartgetc>
    if(c == -1)
    800009e0:	fe9518e3          	bne	a0,s1,800009d0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e4:	00011497          	auipc	s1,0x11
    800009e8:	f1448493          	addi	s1,s1,-236 # 800118f8 <uart_tx_lock>
    800009ec:	8526                	mv	a0,s1
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	212080e7          	jalr	530(ra) # 80000c00 <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e48080e7          	jalr	-440(ra) # 8000083e <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	2b4080e7          	jalr	692(ra) # 80000cb4 <release>
}
    80000a08:	60e2                	ld	ra,24(sp)
    80000a0a:	6442                	ld	s0,16(sp)
    80000a0c:	64a2                	ld	s1,8(sp)
    80000a0e:	6105                	addi	sp,sp,32
    80000a10:	8082                	ret

0000000080000a12 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a12:	1101                	addi	sp,sp,-32
    80000a14:	ec06                	sd	ra,24(sp)
    80000a16:	e822                	sd	s0,16(sp)
    80000a18:	e426                	sd	s1,8(sp)
    80000a1a:	e04a                	sd	s2,0(sp)
    80000a1c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03451793          	slli	a5,a0,0x34
    80000a22:	ebb9                	bnez	a5,80000a78 <kfree+0x66>
    80000a24:	84aa                	mv	s1,a0
    80000a26:	00025797          	auipc	a5,0x25
    80000a2a:	5da78793          	addi	a5,a5,1498 # 80026000 <end>
    80000a2e:	04f56563          	bltu	a0,a5,80000a78 <kfree+0x66>
    80000a32:	47c5                	li	a5,17
    80000a34:	07ee                	slli	a5,a5,0x1b
    80000a36:	04f57163          	bgeu	a0,a5,80000a78 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a3a:	6605                	lui	a2,0x1
    80000a3c:	4585                	li	a1,1
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	2be080e7          	jalr	702(ra) # 80000cfc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00011917          	auipc	s2,0x11
    80000a4a:	eea90913          	addi	s2,s2,-278 # 80011930 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	1b0080e7          	jalr	432(ra) # 80000c00 <acquire>
  r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	250080e7          	jalr	592(ra) # 80000cb4 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6902                	ld	s2,0(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret
    panic("kfree");
    80000a78:	00007517          	auipc	a0,0x7
    80000a7c:	5e850513          	addi	a0,a0,1512 # 80008060 <digits+0x20>
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	ac6080e7          	jalr	-1338(ra) # 80000546 <panic>

0000000080000a88 <freerange>:
{
    80000a88:	7179                	addi	sp,sp,-48
    80000a8a:	f406                	sd	ra,40(sp)
    80000a8c:	f022                	sd	s0,32(sp)
    80000a8e:	ec26                	sd	s1,24(sp)
    80000a90:	e84a                	sd	s2,16(sp)
    80000a92:	e44e                	sd	s3,8(sp)
    80000a94:	e052                	sd	s4,0(sp)
    80000a96:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a98:	6785                	lui	a5,0x1
    80000a9a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a9e:	00e504b3          	add	s1,a0,a4
    80000aa2:	777d                	lui	a4,0xfffff
    80000aa4:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa6:	94be                	add	s1,s1,a5
    80000aa8:	0095ee63          	bltu	a1,s1,80000ac4 <freerange+0x3c>
    80000aac:	892e                	mv	s2,a1
    kfree(p);
    80000aae:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab0:	6985                	lui	s3,0x1
    kfree(p);
    80000ab2:	01448533          	add	a0,s1,s4
    80000ab6:	00000097          	auipc	ra,0x0
    80000aba:	f5c080e7          	jalr	-164(ra) # 80000a12 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000abe:	94ce                	add	s1,s1,s3
    80000ac0:	fe9979e3          	bgeu	s2,s1,80000ab2 <freerange+0x2a>
}
    80000ac4:	70a2                	ld	ra,40(sp)
    80000ac6:	7402                	ld	s0,32(sp)
    80000ac8:	64e2                	ld	s1,24(sp)
    80000aca:	6942                	ld	s2,16(sp)
    80000acc:	69a2                	ld	s3,8(sp)
    80000ace:	6a02                	ld	s4,0(sp)
    80000ad0:	6145                	addi	sp,sp,48
    80000ad2:	8082                	ret

0000000080000ad4 <kinit>:
{
    80000ad4:	1141                	addi	sp,sp,-16
    80000ad6:	e406                	sd	ra,8(sp)
    80000ad8:	e022                	sd	s0,0(sp)
    80000ada:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000adc:	00007597          	auipc	a1,0x7
    80000ae0:	58c58593          	addi	a1,a1,1420 # 80008068 <digits+0x28>
    80000ae4:	00011517          	auipc	a0,0x11
    80000ae8:	e4c50513          	addi	a0,a0,-436 # 80011930 <kmem>
    80000aec:	00000097          	auipc	ra,0x0
    80000af0:	084080e7          	jalr	132(ra) # 80000b70 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af4:	45c5                	li	a1,17
    80000af6:	05ee                	slli	a1,a1,0x1b
    80000af8:	00025517          	auipc	a0,0x25
    80000afc:	50850513          	addi	a0,a0,1288 # 80026000 <end>
    80000b00:	00000097          	auipc	ra,0x0
    80000b04:	f88080e7          	jalr	-120(ra) # 80000a88 <freerange>
}
    80000b08:	60a2                	ld	ra,8(sp)
    80000b0a:	6402                	ld	s0,0(sp)
    80000b0c:	0141                	addi	sp,sp,16
    80000b0e:	8082                	ret

0000000080000b10 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b10:	1101                	addi	sp,sp,-32
    80000b12:	ec06                	sd	ra,24(sp)
    80000b14:	e822                	sd	s0,16(sp)
    80000b16:	e426                	sd	s1,8(sp)
    80000b18:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b1a:	00011497          	auipc	s1,0x11
    80000b1e:	e1648493          	addi	s1,s1,-490 # 80011930 <kmem>
    80000b22:	8526                	mv	a0,s1
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	0dc080e7          	jalr	220(ra) # 80000c00 <acquire>
  r = kmem.freelist;
    80000b2c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2e:	c885                	beqz	s1,80000b5e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b30:	609c                	ld	a5,0(s1)
    80000b32:	00011517          	auipc	a0,0x11
    80000b36:	dfe50513          	addi	a0,a0,-514 # 80011930 <kmem>
    80000b3a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	178080e7          	jalr	376(ra) # 80000cb4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b44:	6605                	lui	a2,0x1
    80000b46:	4595                	li	a1,5
    80000b48:	8526                	mv	a0,s1
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	1b2080e7          	jalr	434(ra) # 80000cfc <memset>
  return (void*)r;
}
    80000b52:	8526                	mv	a0,s1
    80000b54:	60e2                	ld	ra,24(sp)
    80000b56:	6442                	ld	s0,16(sp)
    80000b58:	64a2                	ld	s1,8(sp)
    80000b5a:	6105                	addi	sp,sp,32
    80000b5c:	8082                	ret
  release(&kmem.lock);
    80000b5e:	00011517          	auipc	a0,0x11
    80000b62:	dd250513          	addi	a0,a0,-558 # 80011930 <kmem>
    80000b66:	00000097          	auipc	ra,0x0
    80000b6a:	14e080e7          	jalr	334(ra) # 80000cb4 <release>
  if(r)
    80000b6e:	b7d5                	j	80000b52 <kalloc+0x42>

0000000080000b70 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b70:	1141                	addi	sp,sp,-16
    80000b72:	e422                	sd	s0,8(sp)
    80000b74:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b76:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b78:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b7c:	00053823          	sd	zero,16(a0)
}
    80000b80:	6422                	ld	s0,8(sp)
    80000b82:	0141                	addi	sp,sp,16
    80000b84:	8082                	ret

0000000080000b86 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b86:	411c                	lw	a5,0(a0)
    80000b88:	e399                	bnez	a5,80000b8e <holding+0x8>
    80000b8a:	4501                	li	a0,0
  return r;
}
    80000b8c:	8082                	ret
{
    80000b8e:	1101                	addi	sp,sp,-32
    80000b90:	ec06                	sd	ra,24(sp)
    80000b92:	e822                	sd	s0,16(sp)
    80000b94:	e426                	sd	s1,8(sp)
    80000b96:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b98:	6904                	ld	s1,16(a0)
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	e58080e7          	jalr	-424(ra) # 800019f2 <mycpu>
    80000ba2:	40a48533          	sub	a0,s1,a0
    80000ba6:	00153513          	seqz	a0,a0
}
    80000baa:	60e2                	ld	ra,24(sp)
    80000bac:	6442                	ld	s0,16(sp)
    80000bae:	64a2                	ld	s1,8(sp)
    80000bb0:	6105                	addi	sp,sp,32
    80000bb2:	8082                	ret

0000000080000bb4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb4:	1101                	addi	sp,sp,-32
    80000bb6:	ec06                	sd	ra,24(sp)
    80000bb8:	e822                	sd	s0,16(sp)
    80000bba:	e426                	sd	s1,8(sp)
    80000bbc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bbe:	100024f3          	csrr	s1,sstatus
    80000bc2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bcc:	00001097          	auipc	ra,0x1
    80000bd0:	e26080e7          	jalr	-474(ra) # 800019f2 <mycpu>
    80000bd4:	5d3c                	lw	a5,120(a0)
    80000bd6:	cf89                	beqz	a5,80000bf0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd8:	00001097          	auipc	ra,0x1
    80000bdc:	e1a080e7          	jalr	-486(ra) # 800019f2 <mycpu>
    80000be0:	5d3c                	lw	a5,120(a0)
    80000be2:	2785                	addiw	a5,a5,1
    80000be4:	dd3c                	sw	a5,120(a0)
}
    80000be6:	60e2                	ld	ra,24(sp)
    80000be8:	6442                	ld	s0,16(sp)
    80000bea:	64a2                	ld	s1,8(sp)
    80000bec:	6105                	addi	sp,sp,32
    80000bee:	8082                	ret
    mycpu()->intena = old;
    80000bf0:	00001097          	auipc	ra,0x1
    80000bf4:	e02080e7          	jalr	-510(ra) # 800019f2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf8:	8085                	srli	s1,s1,0x1
    80000bfa:	8885                	andi	s1,s1,1
    80000bfc:	dd64                	sw	s1,124(a0)
    80000bfe:	bfe9                	j	80000bd8 <push_off+0x24>

0000000080000c00 <acquire>:
{
    80000c00:	1101                	addi	sp,sp,-32
    80000c02:	ec06                	sd	ra,24(sp)
    80000c04:	e822                	sd	s0,16(sp)
    80000c06:	e426                	sd	s1,8(sp)
    80000c08:	1000                	addi	s0,sp,32
    80000c0a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c0c:	00000097          	auipc	ra,0x0
    80000c10:	fa8080e7          	jalr	-88(ra) # 80000bb4 <push_off>
  if(holding(lk))
    80000c14:	8526                	mv	a0,s1
    80000c16:	00000097          	auipc	ra,0x0
    80000c1a:	f70080e7          	jalr	-144(ra) # 80000b86 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1e:	4705                	li	a4,1
  if(holding(lk))
    80000c20:	e115                	bnez	a0,80000c44 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c22:	87ba                	mv	a5,a4
    80000c24:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c28:	2781                	sext.w	a5,a5
    80000c2a:	ffe5                	bnez	a5,80000c22 <acquire+0x22>
  __sync_synchronize();
    80000c2c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c30:	00001097          	auipc	ra,0x1
    80000c34:	dc2080e7          	jalr	-574(ra) # 800019f2 <mycpu>
    80000c38:	e888                	sd	a0,16(s1)
}
    80000c3a:	60e2                	ld	ra,24(sp)
    80000c3c:	6442                	ld	s0,16(sp)
    80000c3e:	64a2                	ld	s1,8(sp)
    80000c40:	6105                	addi	sp,sp,32
    80000c42:	8082                	ret
    panic("acquire");
    80000c44:	00007517          	auipc	a0,0x7
    80000c48:	42c50513          	addi	a0,a0,1068 # 80008070 <digits+0x30>
    80000c4c:	00000097          	auipc	ra,0x0
    80000c50:	8fa080e7          	jalr	-1798(ra) # 80000546 <panic>

0000000080000c54 <pop_off>:

void
pop_off(void)
{
    80000c54:	1141                	addi	sp,sp,-16
    80000c56:	e406                	sd	ra,8(sp)
    80000c58:	e022                	sd	s0,0(sp)
    80000c5a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c5c:	00001097          	auipc	ra,0x1
    80000c60:	d96080e7          	jalr	-618(ra) # 800019f2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c68:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c6a:	e78d                	bnez	a5,80000c94 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c6c:	5d3c                	lw	a5,120(a0)
    80000c6e:	02f05b63          	blez	a5,80000ca4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c72:	37fd                	addiw	a5,a5,-1
    80000c74:	0007871b          	sext.w	a4,a5
    80000c78:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c7a:	eb09                	bnez	a4,80000c8c <pop_off+0x38>
    80000c7c:	5d7c                	lw	a5,124(a0)
    80000c7e:	c799                	beqz	a5,80000c8c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c80:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c84:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c88:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c8c:	60a2                	ld	ra,8(sp)
    80000c8e:	6402                	ld	s0,0(sp)
    80000c90:	0141                	addi	sp,sp,16
    80000c92:	8082                	ret
    panic("pop_off - interruptible");
    80000c94:	00007517          	auipc	a0,0x7
    80000c98:	3e450513          	addi	a0,a0,996 # 80008078 <digits+0x38>
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	8aa080e7          	jalr	-1878(ra) # 80000546 <panic>
    panic("pop_off");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3ec50513          	addi	a0,a0,1004 # 80008090 <digits+0x50>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89a080e7          	jalr	-1894(ra) # 80000546 <panic>

0000000080000cb4 <release>:
{
    80000cb4:	1101                	addi	sp,sp,-32
    80000cb6:	ec06                	sd	ra,24(sp)
    80000cb8:	e822                	sd	s0,16(sp)
    80000cba:	e426                	sd	s1,8(sp)
    80000cbc:	1000                	addi	s0,sp,32
    80000cbe:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cc0:	00000097          	auipc	ra,0x0
    80000cc4:	ec6080e7          	jalr	-314(ra) # 80000b86 <holding>
    80000cc8:	c115                	beqz	a0,80000cec <release+0x38>
  lk->cpu = 0;
    80000cca:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cce:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cd2:	0f50000f          	fence	iorw,ow
    80000cd6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cda:	00000097          	auipc	ra,0x0
    80000cde:	f7a080e7          	jalr	-134(ra) # 80000c54 <pop_off>
}
    80000ce2:	60e2                	ld	ra,24(sp)
    80000ce4:	6442                	ld	s0,16(sp)
    80000ce6:	64a2                	ld	s1,8(sp)
    80000ce8:	6105                	addi	sp,sp,32
    80000cea:	8082                	ret
    panic("release");
    80000cec:	00007517          	auipc	a0,0x7
    80000cf0:	3ac50513          	addi	a0,a0,940 # 80008098 <digits+0x58>
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	852080e7          	jalr	-1966(ra) # 80000546 <panic>

0000000080000cfc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cfc:	1141                	addi	sp,sp,-16
    80000cfe:	e422                	sd	s0,8(sp)
    80000d00:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d02:	ca19                	beqz	a2,80000d18 <memset+0x1c>
    80000d04:	87aa                	mv	a5,a0
    80000d06:	1602                	slli	a2,a2,0x20
    80000d08:	9201                	srli	a2,a2,0x20
    80000d0a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d12:	0785                	addi	a5,a5,1
    80000d14:	fee79de3          	bne	a5,a4,80000d0e <memset+0x12>
  }
  return dst;
}
    80000d18:	6422                	ld	s0,8(sp)
    80000d1a:	0141                	addi	sp,sp,16
    80000d1c:	8082                	ret

0000000080000d1e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1e:	1141                	addi	sp,sp,-16
    80000d20:	e422                	sd	s0,8(sp)
    80000d22:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d24:	ca05                	beqz	a2,80000d54 <memcmp+0x36>
    80000d26:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d32:	00054783          	lbu	a5,0(a0)
    80000d36:	0005c703          	lbu	a4,0(a1)
    80000d3a:	00e79863          	bne	a5,a4,80000d4a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3e:	0505                	addi	a0,a0,1
    80000d40:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d42:	fed518e3          	bne	a0,a3,80000d32 <memcmp+0x14>
  }

  return 0;
    80000d46:	4501                	li	a0,0
    80000d48:	a019                	j	80000d4e <memcmp+0x30>
      return *s1 - *s2;
    80000d4a:	40e7853b          	subw	a0,a5,a4
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  return 0;
    80000d54:	4501                	li	a0,0
    80000d56:	bfe5                	j	80000d4e <memcmp+0x30>

0000000080000d58 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d58:	1141                	addi	sp,sp,-16
    80000d5a:	e422                	sd	s0,8(sp)
    80000d5c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5e:	02a5e563          	bltu	a1,a0,80000d88 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d62:	fff6069b          	addiw	a3,a2,-1
    80000d66:	ce11                	beqz	a2,80000d82 <memmove+0x2a>
    80000d68:	1682                	slli	a3,a3,0x20
    80000d6a:	9281                	srli	a3,a3,0x20
    80000d6c:	0685                	addi	a3,a3,1
    80000d6e:	96ae                	add	a3,a3,a1
    80000d70:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d72:	0585                	addi	a1,a1,1
    80000d74:	0785                	addi	a5,a5,1
    80000d76:	fff5c703          	lbu	a4,-1(a1)
    80000d7a:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7e:	fed59ae3          	bne	a1,a3,80000d72 <memmove+0x1a>

  return dst;
}
    80000d82:	6422                	ld	s0,8(sp)
    80000d84:	0141                	addi	sp,sp,16
    80000d86:	8082                	ret
  if(s < d && s + n > d){
    80000d88:	02061713          	slli	a4,a2,0x20
    80000d8c:	9301                	srli	a4,a4,0x20
    80000d8e:	00e587b3          	add	a5,a1,a4
    80000d92:	fcf578e3          	bgeu	a0,a5,80000d62 <memmove+0xa>
    d += n;
    80000d96:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d98:	fff6069b          	addiw	a3,a2,-1
    80000d9c:	d27d                	beqz	a2,80000d82 <memmove+0x2a>
    80000d9e:	02069613          	slli	a2,a3,0x20
    80000da2:	9201                	srli	a2,a2,0x20
    80000da4:	fff64613          	not	a2,a2
    80000da8:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000daa:	17fd                	addi	a5,a5,-1
    80000dac:	177d                	addi	a4,a4,-1 # ffffffffffffefff <end+0xffffffff7ffd8fff>
    80000dae:	0007c683          	lbu	a3,0(a5)
    80000db2:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db6:	fef61ae3          	bne	a2,a5,80000daa <memmove+0x52>
    80000dba:	b7e1                	j	80000d82 <memmove+0x2a>

0000000080000dbc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dbc:	1141                	addi	sp,sp,-16
    80000dbe:	e406                	sd	ra,8(sp)
    80000dc0:	e022                	sd	s0,0(sp)
    80000dc2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc4:	00000097          	auipc	ra,0x0
    80000dc8:	f94080e7          	jalr	-108(ra) # 80000d58 <memmove>
}
    80000dcc:	60a2                	ld	ra,8(sp)
    80000dce:	6402                	ld	s0,0(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret

0000000080000dd4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd4:	1141                	addi	sp,sp,-16
    80000dd6:	e422                	sd	s0,8(sp)
    80000dd8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dda:	ce11                	beqz	a2,80000df6 <strncmp+0x22>
    80000ddc:	00054783          	lbu	a5,0(a0)
    80000de0:	cf89                	beqz	a5,80000dfa <strncmp+0x26>
    80000de2:	0005c703          	lbu	a4,0(a1)
    80000de6:	00f71a63          	bne	a4,a5,80000dfa <strncmp+0x26>
    n--, p++, q++;
    80000dea:	367d                	addiw	a2,a2,-1
    80000dec:	0505                	addi	a0,a0,1
    80000dee:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000df0:	f675                	bnez	a2,80000ddc <strncmp+0x8>
  if(n == 0)
    return 0;
    80000df2:	4501                	li	a0,0
    80000df4:	a809                	j	80000e06 <strncmp+0x32>
    80000df6:	4501                	li	a0,0
    80000df8:	a039                	j	80000e06 <strncmp+0x32>
  if(n == 0)
    80000dfa:	ca09                	beqz	a2,80000e0c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dfc:	00054503          	lbu	a0,0(a0)
    80000e00:	0005c783          	lbu	a5,0(a1)
    80000e04:	9d1d                	subw	a0,a0,a5
}
    80000e06:	6422                	ld	s0,8(sp)
    80000e08:	0141                	addi	sp,sp,16
    80000e0a:	8082                	ret
    return 0;
    80000e0c:	4501                	li	a0,0
    80000e0e:	bfe5                	j	80000e06 <strncmp+0x32>

0000000080000e10 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e16:	872a                	mv	a4,a0
    80000e18:	8832                	mv	a6,a2
    80000e1a:	367d                	addiw	a2,a2,-1
    80000e1c:	01005963          	blez	a6,80000e2e <strncpy+0x1e>
    80000e20:	0705                	addi	a4,a4,1
    80000e22:	0005c783          	lbu	a5,0(a1)
    80000e26:	fef70fa3          	sb	a5,-1(a4)
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	f7f5                	bnez	a5,80000e18 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2e:	86ba                	mv	a3,a4
    80000e30:	00c05c63          	blez	a2,80000e48 <strncpy+0x38>
    *s++ = 0;
    80000e34:	0685                	addi	a3,a3,1
    80000e36:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e3a:	40d707bb          	subw	a5,a4,a3
    80000e3e:	37fd                	addiw	a5,a5,-1
    80000e40:	010787bb          	addw	a5,a5,a6
    80000e44:	fef048e3          	bgtz	a5,80000e34 <strncpy+0x24>
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e54:	02c05363          	blez	a2,80000e7a <safestrcpy+0x2c>
    80000e58:	fff6069b          	addiw	a3,a2,-1
    80000e5c:	1682                	slli	a3,a3,0x20
    80000e5e:	9281                	srli	a3,a3,0x20
    80000e60:	96ae                	add	a3,a3,a1
    80000e62:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e64:	00d58963          	beq	a1,a3,80000e76 <safestrcpy+0x28>
    80000e68:	0585                	addi	a1,a1,1
    80000e6a:	0785                	addi	a5,a5,1
    80000e6c:	fff5c703          	lbu	a4,-1(a1)
    80000e70:	fee78fa3          	sb	a4,-1(a5)
    80000e74:	fb65                	bnez	a4,80000e64 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e76:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret

0000000080000e80 <strlen>:

int
strlen(const char *s)
{
    80000e80:	1141                	addi	sp,sp,-16
    80000e82:	e422                	sd	s0,8(sp)
    80000e84:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e86:	00054783          	lbu	a5,0(a0)
    80000e8a:	cf91                	beqz	a5,80000ea6 <strlen+0x26>
    80000e8c:	0505                	addi	a0,a0,1
    80000e8e:	87aa                	mv	a5,a0
    80000e90:	4685                	li	a3,1
    80000e92:	9e89                	subw	a3,a3,a0
    80000e94:	00f6853b          	addw	a0,a3,a5
    80000e98:	0785                	addi	a5,a5,1
    80000e9a:	fff7c703          	lbu	a4,-1(a5)
    80000e9e:	fb7d                	bnez	a4,80000e94 <strlen+0x14>
    ;
  return n;
}
    80000ea0:	6422                	ld	s0,8(sp)
    80000ea2:	0141                	addi	sp,sp,16
    80000ea4:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea6:	4501                	li	a0,0
    80000ea8:	bfe5                	j	80000ea0 <strlen+0x20>

0000000080000eaa <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eaa:	1141                	addi	sp,sp,-16
    80000eac:	e406                	sd	ra,8(sp)
    80000eae:	e022                	sd	s0,0(sp)
    80000eb0:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	b30080e7          	jalr	-1232(ra) # 800019e2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eba:	00008717          	auipc	a4,0x8
    80000ebe:	15270713          	addi	a4,a4,338 # 8000900c <started>
  if(cpuid() == 0){
    80000ec2:	c139                	beqz	a0,80000f08 <main+0x5e>
    while(started == 0)
    80000ec4:	431c                	lw	a5,0(a4)
    80000ec6:	2781                	sext.w	a5,a5
    80000ec8:	dff5                	beqz	a5,80000ec4 <main+0x1a>
      ;
    __sync_synchronize();
    80000eca:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	b14080e7          	jalr	-1260(ra) # 800019e2 <cpuid>
    80000ed6:	85aa                	mv	a1,a0
    80000ed8:	00007517          	auipc	a0,0x7
    80000edc:	1e050513          	addi	a0,a0,480 # 800080b8 <digits+0x78>
    80000ee0:	fffff097          	auipc	ra,0xfffff
    80000ee4:	6b0080e7          	jalr	1712(ra) # 80000590 <printf>
    kvminithart();    // turn on paging
    80000ee8:	00000097          	auipc	ra,0x0
    80000eec:	0d8080e7          	jalr	216(ra) # 80000fc0 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	77e080e7          	jalr	1918(ra) # 8000266e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef8:	00005097          	auipc	ra,0x5
    80000efc:	db8080e7          	jalr	-584(ra) # 80005cb0 <plicinithart>
  }

  scheduler();        
    80000f00:	00001097          	auipc	ra,0x1
    80000f04:	046080e7          	jalr	70(ra) # 80001f46 <scheduler>
    consoleinit();
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	54e080e7          	jalr	1358(ra) # 80000456 <consoleinit>
    printfinit();
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	860080e7          	jalr	-1952(ra) # 80000770 <printfinit>
    printf("\n");
    80000f18:	00007517          	auipc	a0,0x7
    80000f1c:	1b050513          	addi	a0,a0,432 # 800080c8 <digits+0x88>
    80000f20:	fffff097          	auipc	ra,0xfffff
    80000f24:	670080e7          	jalr	1648(ra) # 80000590 <printf>
    printf("xv6 kernel is booting\n");
    80000f28:	00007517          	auipc	a0,0x7
    80000f2c:	17850513          	addi	a0,a0,376 # 800080a0 <digits+0x60>
    80000f30:	fffff097          	auipc	ra,0xfffff
    80000f34:	660080e7          	jalr	1632(ra) # 80000590 <printf>
    printf("\n");
    80000f38:	00007517          	auipc	a0,0x7
    80000f3c:	19050513          	addi	a0,a0,400 # 800080c8 <digits+0x88>
    80000f40:	fffff097          	auipc	ra,0xfffff
    80000f44:	650080e7          	jalr	1616(ra) # 80000590 <printf>
    kinit();         // physical page allocator
    80000f48:	00000097          	auipc	ra,0x0
    80000f4c:	b8c080e7          	jalr	-1140(ra) # 80000ad4 <kinit>
    kvminit();       // create kernel page table
    80000f50:	00000097          	auipc	ra,0x0
    80000f54:	31c080e7          	jalr	796(ra) # 8000126c <kvminit>
    kvminithart();   // turn on paging
    80000f58:	00000097          	auipc	ra,0x0
    80000f5c:	068080e7          	jalr	104(ra) # 80000fc0 <kvminithart>
    procinit();      // process table
    80000f60:	00001097          	auipc	ra,0x1
    80000f64:	9b2080e7          	jalr	-1614(ra) # 80001912 <procinit>
    trapinit();      // trap vectors
    80000f68:	00001097          	auipc	ra,0x1
    80000f6c:	6de080e7          	jalr	1758(ra) # 80002646 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	6fe080e7          	jalr	1790(ra) # 8000266e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f78:	00005097          	auipc	ra,0x5
    80000f7c:	d22080e7          	jalr	-734(ra) # 80005c9a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	d30080e7          	jalr	-720(ra) # 80005cb0 <plicinithart>
    binit();         // buffer cache
    80000f88:	00002097          	auipc	ra,0x2
    80000f8c:	ed0080e7          	jalr	-304(ra) # 80002e58 <binit>
    iinit();         // inode cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	55e080e7          	jalr	1374(ra) # 800034ee <iinit>
    fileinit();      // file table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	504080e7          	jalr	1284(ra) # 8000449c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa0:	00005097          	auipc	ra,0x5
    80000fa4:	e16080e7          	jalr	-490(ra) # 80005db6 <virtio_disk_init>
    userinit();      // first user process
    80000fa8:	00001097          	auipc	ra,0x1
    80000fac:	d30080e7          	jalr	-720(ra) # 80001cd8 <userinit>
    __sync_synchronize();
    80000fb0:	0ff0000f          	fence
    started = 1;
    80000fb4:	4785                	li	a5,1
    80000fb6:	00008717          	auipc	a4,0x8
    80000fba:	04f72b23          	sw	a5,86(a4) # 8000900c <started>
    80000fbe:	b789                	j	80000f00 <main+0x56>

0000000080000fc0 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc0:	1141                	addi	sp,sp,-16
    80000fc2:	e422                	sd	s0,8(sp)
    80000fc4:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fc6:	00008797          	auipc	a5,0x8
    80000fca:	04a7b783          	ld	a5,74(a5) # 80009010 <kernel_pagetable>
    80000fce:	83b1                	srli	a5,a5,0xc
    80000fd0:	577d                	li	a4,-1
    80000fd2:	177e                	slli	a4,a4,0x3f
    80000fd4:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fd6:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fda:	12000073          	sfence.vma
  sfence_vma();
}
    80000fde:	6422                	ld	s0,8(sp)
    80000fe0:	0141                	addi	sp,sp,16
    80000fe2:	8082                	ret

0000000080000fe4 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fe4:	7139                	addi	sp,sp,-64
    80000fe6:	fc06                	sd	ra,56(sp)
    80000fe8:	f822                	sd	s0,48(sp)
    80000fea:	f426                	sd	s1,40(sp)
    80000fec:	f04a                	sd	s2,32(sp)
    80000fee:	ec4e                	sd	s3,24(sp)
    80000ff0:	e852                	sd	s4,16(sp)
    80000ff2:	e456                	sd	s5,8(sp)
    80000ff4:	e05a                	sd	s6,0(sp)
    80000ff6:	0080                	addi	s0,sp,64
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	89ae                	mv	s3,a1
    80000ffc:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ffe:	57fd                	li	a5,-1
    80001000:	83e9                	srli	a5,a5,0x1a
    80001002:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001004:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001006:	04b7f263          	bgeu	a5,a1,8000104a <walk+0x66>
    panic("walk");
    8000100a:	00007517          	auipc	a0,0x7
    8000100e:	0c650513          	addi	a0,a0,198 # 800080d0 <digits+0x90>
    80001012:	fffff097          	auipc	ra,0xfffff
    80001016:	534080e7          	jalr	1332(ra) # 80000546 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000101a:	060a8663          	beqz	s5,80001086 <walk+0xa2>
    8000101e:	00000097          	auipc	ra,0x0
    80001022:	af2080e7          	jalr	-1294(ra) # 80000b10 <kalloc>
    80001026:	84aa                	mv	s1,a0
    80001028:	c529                	beqz	a0,80001072 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000102a:	6605                	lui	a2,0x1
    8000102c:	4581                	li	a1,0
    8000102e:	00000097          	auipc	ra,0x0
    80001032:	cce080e7          	jalr	-818(ra) # 80000cfc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001036:	00c4d793          	srli	a5,s1,0xc
    8000103a:	07aa                	slli	a5,a5,0xa
    8000103c:	0017e793          	ori	a5,a5,1
    80001040:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001044:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    80001046:	036a0063          	beq	s4,s6,80001066 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000104a:	0149d933          	srl	s2,s3,s4
    8000104e:	1ff97913          	andi	s2,s2,511
    80001052:	090e                	slli	s2,s2,0x3
    80001054:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001056:	00093483          	ld	s1,0(s2)
    8000105a:	0014f793          	andi	a5,s1,1
    8000105e:	dfd5                	beqz	a5,8000101a <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001060:	80a9                	srli	s1,s1,0xa
    80001062:	04b2                	slli	s1,s1,0xc
    80001064:	b7c5                	j	80001044 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001066:	00c9d513          	srli	a0,s3,0xc
    8000106a:	1ff57513          	andi	a0,a0,511
    8000106e:	050e                	slli	a0,a0,0x3
    80001070:	9526                	add	a0,a0,s1
}
    80001072:	70e2                	ld	ra,56(sp)
    80001074:	7442                	ld	s0,48(sp)
    80001076:	74a2                	ld	s1,40(sp)
    80001078:	7902                	ld	s2,32(sp)
    8000107a:	69e2                	ld	s3,24(sp)
    8000107c:	6a42                	ld	s4,16(sp)
    8000107e:	6aa2                	ld	s5,8(sp)
    80001080:	6b02                	ld	s6,0(sp)
    80001082:	6121                	addi	sp,sp,64
    80001084:	8082                	ret
        return 0;
    80001086:	4501                	li	a0,0
    80001088:	b7ed                	j	80001072 <walk+0x8e>

000000008000108a <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000108a:	1101                	addi	sp,sp,-32
    8000108c:	ec06                	sd	ra,24(sp)
    8000108e:	e822                	sd	s0,16(sp)
    80001090:	e426                	sd	s1,8(sp)
    80001092:	1000                	addi	s0,sp,32
    80001094:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001096:	1552                	slli	a0,a0,0x34
    80001098:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000109c:	4601                	li	a2,0
    8000109e:	00008517          	auipc	a0,0x8
    800010a2:	f7253503          	ld	a0,-142(a0) # 80009010 <kernel_pagetable>
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	f3e080e7          	jalr	-194(ra) # 80000fe4 <walk>
  if(pte == 0)
    800010ae:	cd09                	beqz	a0,800010c8 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010b0:	6108                	ld	a0,0(a0)
    800010b2:	00157793          	andi	a5,a0,1
    800010b6:	c38d                	beqz	a5,800010d8 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010b8:	8129                	srli	a0,a0,0xa
    800010ba:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010bc:	9526                	add	a0,a0,s1
    800010be:	60e2                	ld	ra,24(sp)
    800010c0:	6442                	ld	s0,16(sp)
    800010c2:	64a2                	ld	s1,8(sp)
    800010c4:	6105                	addi	sp,sp,32
    800010c6:	8082                	ret
    panic("kvmpa");
    800010c8:	00007517          	auipc	a0,0x7
    800010cc:	01050513          	addi	a0,a0,16 # 800080d8 <digits+0x98>
    800010d0:	fffff097          	auipc	ra,0xfffff
    800010d4:	476080e7          	jalr	1142(ra) # 80000546 <panic>
    panic("kvmpa");
    800010d8:	00007517          	auipc	a0,0x7
    800010dc:	00050513          	mv	a0,a0
    800010e0:	fffff097          	auipc	ra,0xfffff
    800010e4:	466080e7          	jalr	1126(ra) # 80000546 <panic>

00000000800010e8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010e8:	715d                	addi	sp,sp,-80
    800010ea:	e486                	sd	ra,72(sp)
    800010ec:	e0a2                	sd	s0,64(sp)
    800010ee:	fc26                	sd	s1,56(sp)
    800010f0:	f84a                	sd	s2,48(sp)
    800010f2:	f44e                	sd	s3,40(sp)
    800010f4:	f052                	sd	s4,32(sp)
    800010f6:	ec56                	sd	s5,24(sp)
    800010f8:	e85a                	sd	s6,16(sp)
    800010fa:	e45e                	sd	s7,8(sp)
    800010fc:	0880                	addi	s0,sp,80
    800010fe:	8aaa                	mv	s5,a0
    80001100:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001102:	777d                	lui	a4,0xfffff
    80001104:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001108:	fff60993          	addi	s3,a2,-1 # fff <_entry-0x7ffff001>
    8000110c:	99ae                	add	s3,s3,a1
    8000110e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001112:	893e                	mv	s2,a5
    80001114:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001118:	6b85                	lui	s7,0x1
    8000111a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000111e:	4605                	li	a2,1
    80001120:	85ca                	mv	a1,s2
    80001122:	8556                	mv	a0,s5
    80001124:	00000097          	auipc	ra,0x0
    80001128:	ec0080e7          	jalr	-320(ra) # 80000fe4 <walk>
    8000112c:	c51d                	beqz	a0,8000115a <mappages+0x72>
    if(*pte & PTE_V)
    8000112e:	611c                	ld	a5,0(a0)
    80001130:	8b85                	andi	a5,a5,1
    80001132:	ef81                	bnez	a5,8000114a <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001134:	80b1                	srli	s1,s1,0xc
    80001136:	04aa                	slli	s1,s1,0xa
    80001138:	0164e4b3          	or	s1,s1,s6
    8000113c:	0014e493          	ori	s1,s1,1
    80001140:	e104                	sd	s1,0(a0)
    if(a == last)
    80001142:	03390863          	beq	s2,s3,80001172 <mappages+0x8a>
    a += PGSIZE;
    80001146:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001148:	bfc9                	j	8000111a <mappages+0x32>
      panic("remap");
    8000114a:	00007517          	auipc	a0,0x7
    8000114e:	f9650513          	addi	a0,a0,-106 # 800080e0 <digits+0xa0>
    80001152:	fffff097          	auipc	ra,0xfffff
    80001156:	3f4080e7          	jalr	1012(ra) # 80000546 <panic>
      return -1;
    8000115a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000115c:	60a6                	ld	ra,72(sp)
    8000115e:	6406                	ld	s0,64(sp)
    80001160:	74e2                	ld	s1,56(sp)
    80001162:	7942                	ld	s2,48(sp)
    80001164:	79a2                	ld	s3,40(sp)
    80001166:	7a02                	ld	s4,32(sp)
    80001168:	6ae2                	ld	s5,24(sp)
    8000116a:	6b42                	ld	s6,16(sp)
    8000116c:	6ba2                	ld	s7,8(sp)
    8000116e:	6161                	addi	sp,sp,80
    80001170:	8082                	ret
  return 0;
    80001172:	4501                	li	a0,0
    80001174:	b7e5                	j	8000115c <mappages+0x74>

0000000080001176 <walkaddr>:
{
    80001176:	7179                	addi	sp,sp,-48
    80001178:	f406                	sd	ra,40(sp)
    8000117a:	f022                	sd	s0,32(sp)
    8000117c:	ec26                	sd	s1,24(sp)
    8000117e:	e84a                	sd	s2,16(sp)
    80001180:	e44e                	sd	s3,8(sp)
    80001182:	e052                	sd	s4,0(sp)
    80001184:	1800                	addi	s0,sp,48
    80001186:	892a                	mv	s2,a0
    80001188:	84ae                	mv	s1,a1
  struct proc * p = myproc();
    8000118a:	00001097          	auipc	ra,0x1
    8000118e:	884080e7          	jalr	-1916(ra) # 80001a0e <myproc>
  if(va >= MAXVA)
    80001192:	57fd                	li	a5,-1
    80001194:	83e9                	srli	a5,a5,0x1a
    80001196:	0097fc63          	bgeu	a5,s1,800011ae <walkaddr+0x38>
    return 0;
    8000119a:	4901                	li	s2,0
}
    8000119c:	854a                	mv	a0,s2
    8000119e:	70a2                	ld	ra,40(sp)
    800011a0:	7402                	ld	s0,32(sp)
    800011a2:	64e2                	ld	s1,24(sp)
    800011a4:	6942                	ld	s2,16(sp)
    800011a6:	69a2                	ld	s3,8(sp)
    800011a8:	6a02                	ld	s4,0(sp)
    800011aa:	6145                	addi	sp,sp,48
    800011ac:	8082                	ret
    800011ae:	89aa                	mv	s3,a0
  pte = walk(pagetable, va, 0);
    800011b0:	4601                	li	a2,0
    800011b2:	85a6                	mv	a1,s1
    800011b4:	854a                	mv	a0,s2
    800011b6:	00000097          	auipc	ra,0x0
    800011ba:	e2e080e7          	jalr	-466(ra) # 80000fe4 <walk>
  if(pte == 0||(*pte & PTE_V) == 0)
    800011be:	c509                	beqz	a0,800011c8 <walkaddr+0x52>
    800011c0:	611c                	ld	a5,0(a0)
    800011c2:	0017f713          	andi	a4,a5,1
    800011c6:	ef39                	bnez	a4,80001224 <walkaddr+0xae>
    uint64 ka =(uint64) kalloc();
    800011c8:	00000097          	auipc	ra,0x0
    800011cc:	948080e7          	jalr	-1720(ra) # 80000b10 <kalloc>
    800011d0:	8a2a                	mv	s4,a0
    if(ka == 0)  return 0;
    800011d2:	4901                	li	s2,0
    800011d4:	d561                	beqz	a0,8000119c <walkaddr+0x26>
    else if(isValid(p,va)==0) 
    800011d6:	85a6                	mv	a1,s1
    800011d8:	854e                	mv	a0,s3
    800011da:	00001097          	auipc	ra,0x1
    800011de:	4ac080e7          	jalr	1196(ra) # 80002686 <isValid>
    800011e2:	c91d                	beqz	a0,80001218 <walkaddr+0xa2>
    uint64 ka =(uint64) kalloc();
    800011e4:	8952                	mv	s2,s4
      memset((void*)ka,0,PGSIZE); 
    800011e6:	6605                	lui	a2,0x1
    800011e8:	4581                	li	a1,0
    800011ea:	8552                	mv	a0,s4
    800011ec:	00000097          	auipc	ra,0x0
    800011f0:	b10080e7          	jalr	-1264(ra) # 80000cfc <memset>
      if(mappages(p->pagetable,va,PGSIZE,ka,PTE_R|PTE_W|PTE_U) != 0){
    800011f4:	4759                	li	a4,22
    800011f6:	86d2                	mv	a3,s4
    800011f8:	6605                	lui	a2,0x1
    800011fa:	85a6                	mv	a1,s1
    800011fc:	0509b503          	ld	a0,80(s3) # 1050 <_entry-0x7fffefb0>
    80001200:	00000097          	auipc	ra,0x0
    80001204:	ee8080e7          	jalr	-280(ra) # 800010e8 <mappages>
    80001208:	d951                	beqz	a0,8000119c <walkaddr+0x26>
        kfree((void*)ka);
    8000120a:	8552                	mv	a0,s4
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	806080e7          	jalr	-2042(ra) # 80000a12 <kfree>
        return 0;
    80001214:	4901                	li	s2,0
    80001216:	b759                	j	8000119c <walkaddr+0x26>
      kfree((void*)ka);
    80001218:	8552                	mv	a0,s4
    8000121a:	fffff097          	auipc	ra,0xfffff
    8000121e:	7f8080e7          	jalr	2040(ra) # 80000a12 <kfree>
      return 0;
    80001222:	bfad                	j	8000119c <walkaddr+0x26>
  if((*pte & PTE_U) == 0)
    80001224:	0107f913          	andi	s2,a5,16
    80001228:	f6090ae3          	beqz	s2,8000119c <walkaddr+0x26>
  pa = PTE2PA(*pte);
    8000122c:	83a9                	srli	a5,a5,0xa
    8000122e:	00c79913          	slli	s2,a5,0xc
  return pa;
    80001232:	b7ad                	j	8000119c <walkaddr+0x26>

0000000080001234 <kvmmap>:
{
    80001234:	1141                	addi	sp,sp,-16
    80001236:	e406                	sd	ra,8(sp)
    80001238:	e022                	sd	s0,0(sp)
    8000123a:	0800                	addi	s0,sp,16
    8000123c:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000123e:	86ae                	mv	a3,a1
    80001240:	85aa                	mv	a1,a0
    80001242:	00008517          	auipc	a0,0x8
    80001246:	dce53503          	ld	a0,-562(a0) # 80009010 <kernel_pagetable>
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	e9e080e7          	jalr	-354(ra) # 800010e8 <mappages>
    80001252:	e509                	bnez	a0,8000125c <kvmmap+0x28>
}
    80001254:	60a2                	ld	ra,8(sp)
    80001256:	6402                	ld	s0,0(sp)
    80001258:	0141                	addi	sp,sp,16
    8000125a:	8082                	ret
    panic("kvmmap");
    8000125c:	00007517          	auipc	a0,0x7
    80001260:	e8c50513          	addi	a0,a0,-372 # 800080e8 <digits+0xa8>
    80001264:	fffff097          	auipc	ra,0xfffff
    80001268:	2e2080e7          	jalr	738(ra) # 80000546 <panic>

000000008000126c <kvminit>:
{
    8000126c:	1101                	addi	sp,sp,-32
    8000126e:	ec06                	sd	ra,24(sp)
    80001270:	e822                	sd	s0,16(sp)
    80001272:	e426                	sd	s1,8(sp)
    80001274:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001276:	00000097          	auipc	ra,0x0
    8000127a:	89a080e7          	jalr	-1894(ra) # 80000b10 <kalloc>
    8000127e:	00008717          	auipc	a4,0x8
    80001282:	d8a73923          	sd	a0,-622(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001286:	6605                	lui	a2,0x1
    80001288:	4581                	li	a1,0
    8000128a:	00000097          	auipc	ra,0x0
    8000128e:	a72080e7          	jalr	-1422(ra) # 80000cfc <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001292:	4699                	li	a3,6
    80001294:	6605                	lui	a2,0x1
    80001296:	100005b7          	lui	a1,0x10000
    8000129a:	10000537          	lui	a0,0x10000
    8000129e:	00000097          	auipc	ra,0x0
    800012a2:	f96080e7          	jalr	-106(ra) # 80001234 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012a6:	4699                	li	a3,6
    800012a8:	6605                	lui	a2,0x1
    800012aa:	100015b7          	lui	a1,0x10001
    800012ae:	10001537          	lui	a0,0x10001
    800012b2:	00000097          	auipc	ra,0x0
    800012b6:	f82080e7          	jalr	-126(ra) # 80001234 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012ba:	4699                	li	a3,6
    800012bc:	6641                	lui	a2,0x10
    800012be:	020005b7          	lui	a1,0x2000
    800012c2:	02000537          	lui	a0,0x2000
    800012c6:	00000097          	auipc	ra,0x0
    800012ca:	f6e080e7          	jalr	-146(ra) # 80001234 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ce:	4699                	li	a3,6
    800012d0:	00400637          	lui	a2,0x400
    800012d4:	0c0005b7          	lui	a1,0xc000
    800012d8:	0c000537          	lui	a0,0xc000
    800012dc:	00000097          	auipc	ra,0x0
    800012e0:	f58080e7          	jalr	-168(ra) # 80001234 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012e4:	00007497          	auipc	s1,0x7
    800012e8:	d1c48493          	addi	s1,s1,-740 # 80008000 <etext>
    800012ec:	46a9                	li	a3,10
    800012ee:	80007617          	auipc	a2,0x80007
    800012f2:	d1260613          	addi	a2,a2,-750 # 8000 <_entry-0x7fff8000>
    800012f6:	4585                	li	a1,1
    800012f8:	05fe                	slli	a1,a1,0x1f
    800012fa:	852e                	mv	a0,a1
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	f38080e7          	jalr	-200(ra) # 80001234 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001304:	4699                	li	a3,6
    80001306:	4645                	li	a2,17
    80001308:	066e                	slli	a2,a2,0x1b
    8000130a:	8e05                	sub	a2,a2,s1
    8000130c:	85a6                	mv	a1,s1
    8000130e:	8526                	mv	a0,s1
    80001310:	00000097          	auipc	ra,0x0
    80001314:	f24080e7          	jalr	-220(ra) # 80001234 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001318:	46a9                	li	a3,10
    8000131a:	6605                	lui	a2,0x1
    8000131c:	00006597          	auipc	a1,0x6
    80001320:	ce458593          	addi	a1,a1,-796 # 80007000 <_trampoline>
    80001324:	04000537          	lui	a0,0x4000
    80001328:	157d                	addi	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    8000132a:	0532                	slli	a0,a0,0xc
    8000132c:	00000097          	auipc	ra,0x0
    80001330:	f08080e7          	jalr	-248(ra) # 80001234 <kvmmap>
}
    80001334:	60e2                	ld	ra,24(sp)
    80001336:	6442                	ld	s0,16(sp)
    80001338:	64a2                	ld	s1,8(sp)
    8000133a:	6105                	addi	sp,sp,32
    8000133c:	8082                	ret

000000008000133e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000133e:	715d                	addi	sp,sp,-80
    80001340:	e486                	sd	ra,72(sp)
    80001342:	e0a2                	sd	s0,64(sp)
    80001344:	fc26                	sd	s1,56(sp)
    80001346:	f84a                	sd	s2,48(sp)
    80001348:	f44e                	sd	s3,40(sp)
    8000134a:	f052                	sd	s4,32(sp)
    8000134c:	ec56                	sd	s5,24(sp)
    8000134e:	e85a                	sd	s6,16(sp)
    80001350:	e45e                	sd	s7,8(sp)
    80001352:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001354:	03459793          	slli	a5,a1,0x34
    80001358:	e795                	bnez	a5,80001384 <uvmunmap+0x46>
    8000135a:	8a2a                	mv	s4,a0
    8000135c:	892e                	mv	s2,a1
    8000135e:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001360:	0632                	slli	a2,a2,0xc
    80001362:	00b609b3          	add	s3,a2,a1
      //panic("uvmunmap: walk");
      continue;
    if((*pte & PTE_V) == 0)
      //panic("uvmunmap: not mapped");
      continue;
    if(PTE_FLAGS(*pte) == PTE_V)
    80001366:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001368:	6a85                	lui	s5,0x1
    8000136a:	0535e263          	bltu	a1,s3,800013ae <uvmunmap+0x70>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000136e:	60a6                	ld	ra,72(sp)
    80001370:	6406                	ld	s0,64(sp)
    80001372:	74e2                	ld	s1,56(sp)
    80001374:	7942                	ld	s2,48(sp)
    80001376:	79a2                	ld	s3,40(sp)
    80001378:	7a02                	ld	s4,32(sp)
    8000137a:	6ae2                	ld	s5,24(sp)
    8000137c:	6b42                	ld	s6,16(sp)
    8000137e:	6ba2                	ld	s7,8(sp)
    80001380:	6161                	addi	sp,sp,80
    80001382:	8082                	ret
    panic("uvmunmap: not aligned");
    80001384:	00007517          	auipc	a0,0x7
    80001388:	d6c50513          	addi	a0,a0,-660 # 800080f0 <digits+0xb0>
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	1ba080e7          	jalr	442(ra) # 80000546 <panic>
      panic("uvmunmap: not a leaf");
    80001394:	00007517          	auipc	a0,0x7
    80001398:	d7450513          	addi	a0,a0,-652 # 80008108 <digits+0xc8>
    8000139c:	fffff097          	auipc	ra,0xfffff
    800013a0:	1aa080e7          	jalr	426(ra) # 80000546 <panic>
    *pte = 0;
    800013a4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013a8:	9956                	add	s2,s2,s5
    800013aa:	fd3972e3          	bgeu	s2,s3,8000136e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013ae:	4601                	li	a2,0
    800013b0:	85ca                	mv	a1,s2
    800013b2:	8552                	mv	a0,s4
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	c30080e7          	jalr	-976(ra) # 80000fe4 <walk>
    800013bc:	84aa                	mv	s1,a0
    800013be:	d56d                	beqz	a0,800013a8 <uvmunmap+0x6a>
    if((*pte & PTE_V) == 0)
    800013c0:	611c                	ld	a5,0(a0)
    800013c2:	0017f713          	andi	a4,a5,1
    800013c6:	d36d                	beqz	a4,800013a8 <uvmunmap+0x6a>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013c8:	3ff7f713          	andi	a4,a5,1023
    800013cc:	fd7704e3          	beq	a4,s7,80001394 <uvmunmap+0x56>
    if(do_free){
    800013d0:	fc0b0ae3          	beqz	s6,800013a4 <uvmunmap+0x66>
      uint64 pa = PTE2PA(*pte);
    800013d4:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800013d6:	00c79513          	slli	a0,a5,0xc
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	638080e7          	jalr	1592(ra) # 80000a12 <kfree>
    800013e2:	b7c9                	j	800013a4 <uvmunmap+0x66>

00000000800013e4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ee:	fffff097          	auipc	ra,0xfffff
    800013f2:	722080e7          	jalr	1826(ra) # 80000b10 <kalloc>
    800013f6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013f8:	c519                	beqz	a0,80001406 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013fa:	6605                	lui	a2,0x1
    800013fc:	4581                	li	a1,0
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	8fe080e7          	jalr	-1794(ra) # 80000cfc <memset>
  return pagetable;
}
    80001406:	8526                	mv	a0,s1
    80001408:	60e2                	ld	ra,24(sp)
    8000140a:	6442                	ld	s0,16(sp)
    8000140c:	64a2                	ld	s1,8(sp)
    8000140e:	6105                	addi	sp,sp,32
    80001410:	8082                	ret

0000000080001412 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001412:	7179                	addi	sp,sp,-48
    80001414:	f406                	sd	ra,40(sp)
    80001416:	f022                	sd	s0,32(sp)
    80001418:	ec26                	sd	s1,24(sp)
    8000141a:	e84a                	sd	s2,16(sp)
    8000141c:	e44e                	sd	s3,8(sp)
    8000141e:	e052                	sd	s4,0(sp)
    80001420:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001422:	6785                	lui	a5,0x1
    80001424:	04f67863          	bgeu	a2,a5,80001474 <uvminit+0x62>
    80001428:	8a2a                	mv	s4,a0
    8000142a:	89ae                	mv	s3,a1
    8000142c:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000142e:	fffff097          	auipc	ra,0xfffff
    80001432:	6e2080e7          	jalr	1762(ra) # 80000b10 <kalloc>
    80001436:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001438:	6605                	lui	a2,0x1
    8000143a:	4581                	li	a1,0
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	8c0080e7          	jalr	-1856(ra) # 80000cfc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001444:	4779                	li	a4,30
    80001446:	86ca                	mv	a3,s2
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	8552                	mv	a0,s4
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	c9a080e7          	jalr	-870(ra) # 800010e8 <mappages>
  memmove(mem, src, sz);
    80001456:	8626                	mv	a2,s1
    80001458:	85ce                	mv	a1,s3
    8000145a:	854a                	mv	a0,s2
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	8fc080e7          	jalr	-1796(ra) # 80000d58 <memmove>
}
    80001464:	70a2                	ld	ra,40(sp)
    80001466:	7402                	ld	s0,32(sp)
    80001468:	64e2                	ld	s1,24(sp)
    8000146a:	6942                	ld	s2,16(sp)
    8000146c:	69a2                	ld	s3,8(sp)
    8000146e:	6a02                	ld	s4,0(sp)
    80001470:	6145                	addi	sp,sp,48
    80001472:	8082                	ret
    panic("inituvm: more than a page");
    80001474:	00007517          	auipc	a0,0x7
    80001478:	cac50513          	addi	a0,a0,-852 # 80008120 <digits+0xe0>
    8000147c:	fffff097          	auipc	ra,0xfffff
    80001480:	0ca080e7          	jalr	202(ra) # 80000546 <panic>

0000000080001484 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001484:	1101                	addi	sp,sp,-32
    80001486:	ec06                	sd	ra,24(sp)
    80001488:	e822                	sd	s0,16(sp)
    8000148a:	e426                	sd	s1,8(sp)
    8000148c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000148e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001490:	00b67d63          	bgeu	a2,a1,800014aa <uvmdealloc+0x26>
    80001494:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001496:	6785                	lui	a5,0x1
    80001498:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000149a:	00f60733          	add	a4,a2,a5
    8000149e:	76fd                	lui	a3,0xfffff
    800014a0:	8f75                	and	a4,a4,a3
    800014a2:	97ae                	add	a5,a5,a1
    800014a4:	8ff5                	and	a5,a5,a3
    800014a6:	00f76863          	bltu	a4,a5,800014b6 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014aa:	8526                	mv	a0,s1
    800014ac:	60e2                	ld	ra,24(sp)
    800014ae:	6442                	ld	s0,16(sp)
    800014b0:	64a2                	ld	s1,8(sp)
    800014b2:	6105                	addi	sp,sp,32
    800014b4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014b6:	8f99                	sub	a5,a5,a4
    800014b8:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ba:	4685                	li	a3,1
    800014bc:	0007861b          	sext.w	a2,a5
    800014c0:	85ba                	mv	a1,a4
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	e7c080e7          	jalr	-388(ra) # 8000133e <uvmunmap>
    800014ca:	b7c5                	j	800014aa <uvmdealloc+0x26>

00000000800014cc <uvmalloc>:
  if(newsz < oldsz)
    800014cc:	0ab66163          	bltu	a2,a1,8000156e <uvmalloc+0xa2>
{
    800014d0:	7139                	addi	sp,sp,-64
    800014d2:	fc06                	sd	ra,56(sp)
    800014d4:	f822                	sd	s0,48(sp)
    800014d6:	f426                	sd	s1,40(sp)
    800014d8:	f04a                	sd	s2,32(sp)
    800014da:	ec4e                	sd	s3,24(sp)
    800014dc:	e852                	sd	s4,16(sp)
    800014de:	e456                	sd	s5,8(sp)
    800014e0:	0080                	addi	s0,sp,64
    800014e2:	8aaa                	mv	s5,a0
    800014e4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014e6:	6785                	lui	a5,0x1
    800014e8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014ea:	95be                	add	a1,a1,a5
    800014ec:	77fd                	lui	a5,0xfffff
    800014ee:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014f2:	08c9f063          	bgeu	s3,a2,80001572 <uvmalloc+0xa6>
    800014f6:	894e                	mv	s2,s3
    mem = kalloc();
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	618080e7          	jalr	1560(ra) # 80000b10 <kalloc>
    80001500:	84aa                	mv	s1,a0
    if(mem == 0){
    80001502:	c51d                	beqz	a0,80001530 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001504:	6605                	lui	a2,0x1
    80001506:	4581                	li	a1,0
    80001508:	fffff097          	auipc	ra,0xfffff
    8000150c:	7f4080e7          	jalr	2036(ra) # 80000cfc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001510:	4779                	li	a4,30
    80001512:	86a6                	mv	a3,s1
    80001514:	6605                	lui	a2,0x1
    80001516:	85ca                	mv	a1,s2
    80001518:	8556                	mv	a0,s5
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	bce080e7          	jalr	-1074(ra) # 800010e8 <mappages>
    80001522:	e905                	bnez	a0,80001552 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001524:	6785                	lui	a5,0x1
    80001526:	993e                	add	s2,s2,a5
    80001528:	fd4968e3          	bltu	s2,s4,800014f8 <uvmalloc+0x2c>
  return newsz;
    8000152c:	8552                	mv	a0,s4
    8000152e:	a809                	j	80001540 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001530:	864e                	mv	a2,s3
    80001532:	85ca                	mv	a1,s2
    80001534:	8556                	mv	a0,s5
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	f4e080e7          	jalr	-178(ra) # 80001484 <uvmdealloc>
      return 0;
    8000153e:	4501                	li	a0,0
}
    80001540:	70e2                	ld	ra,56(sp)
    80001542:	7442                	ld	s0,48(sp)
    80001544:	74a2                	ld	s1,40(sp)
    80001546:	7902                	ld	s2,32(sp)
    80001548:	69e2                	ld	s3,24(sp)
    8000154a:	6a42                	ld	s4,16(sp)
    8000154c:	6aa2                	ld	s5,8(sp)
    8000154e:	6121                	addi	sp,sp,64
    80001550:	8082                	ret
      kfree(mem);
    80001552:	8526                	mv	a0,s1
    80001554:	fffff097          	auipc	ra,0xfffff
    80001558:	4be080e7          	jalr	1214(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000155c:	864e                	mv	a2,s3
    8000155e:	85ca                	mv	a1,s2
    80001560:	8556                	mv	a0,s5
    80001562:	00000097          	auipc	ra,0x0
    80001566:	f22080e7          	jalr	-222(ra) # 80001484 <uvmdealloc>
      return 0;
    8000156a:	4501                	li	a0,0
    8000156c:	bfd1                	j	80001540 <uvmalloc+0x74>
    return oldsz;
    8000156e:	852e                	mv	a0,a1
}
    80001570:	8082                	ret
  return newsz;
    80001572:	8532                	mv	a0,a2
    80001574:	b7f1                	j	80001540 <uvmalloc+0x74>

0000000080001576 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001576:	7179                	addi	sp,sp,-48
    80001578:	f406                	sd	ra,40(sp)
    8000157a:	f022                	sd	s0,32(sp)
    8000157c:	ec26                	sd	s1,24(sp)
    8000157e:	e84a                	sd	s2,16(sp)
    80001580:	e44e                	sd	s3,8(sp)
    80001582:	e052                	sd	s4,0(sp)
    80001584:	1800                	addi	s0,sp,48
    80001586:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001588:	84aa                	mv	s1,a0
    8000158a:	6905                	lui	s2,0x1
    8000158c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000158e:	4985                	li	s3,1
    80001590:	a829                	j	800015aa <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001592:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001594:	00c79513          	slli	a0,a5,0xc
    80001598:	00000097          	auipc	ra,0x0
    8000159c:	fde080e7          	jalr	-34(ra) # 80001576 <freewalk>
      pagetable[i] = 0;
    800015a0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015a4:	04a1                	addi	s1,s1,8
    800015a6:	03248163          	beq	s1,s2,800015c8 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015aa:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ac:	00f7f713          	andi	a4,a5,15
    800015b0:	ff3701e3          	beq	a4,s3,80001592 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015b4:	8b85                	andi	a5,a5,1
    800015b6:	d7fd                	beqz	a5,800015a4 <freewalk+0x2e>
      panic("freewalk: leaf");
    800015b8:	00007517          	auipc	a0,0x7
    800015bc:	b8850513          	addi	a0,a0,-1144 # 80008140 <digits+0x100>
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	f86080e7          	jalr	-122(ra) # 80000546 <panic>
    }
  }
  kfree((void*)pagetable);
    800015c8:	8552                	mv	a0,s4
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	448080e7          	jalr	1096(ra) # 80000a12 <kfree>
}
    800015d2:	70a2                	ld	ra,40(sp)
    800015d4:	7402                	ld	s0,32(sp)
    800015d6:	64e2                	ld	s1,24(sp)
    800015d8:	6942                	ld	s2,16(sp)
    800015da:	69a2                	ld	s3,8(sp)
    800015dc:	6a02                	ld	s4,0(sp)
    800015de:	6145                	addi	sp,sp,48
    800015e0:	8082                	ret

00000000800015e2 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015e2:	1101                	addi	sp,sp,-32
    800015e4:	ec06                	sd	ra,24(sp)
    800015e6:	e822                	sd	s0,16(sp)
    800015e8:	e426                	sd	s1,8(sp)
    800015ea:	1000                	addi	s0,sp,32
    800015ec:	84aa                	mv	s1,a0
  if(sz > 0)
    800015ee:	e999                	bnez	a1,80001604 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015f0:	8526                	mv	a0,s1
    800015f2:	00000097          	auipc	ra,0x0
    800015f6:	f84080e7          	jalr	-124(ra) # 80001576 <freewalk>
}
    800015fa:	60e2                	ld	ra,24(sp)
    800015fc:	6442                	ld	s0,16(sp)
    800015fe:	64a2                	ld	s1,8(sp)
    80001600:	6105                	addi	sp,sp,32
    80001602:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001604:	6785                	lui	a5,0x1
    80001606:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001608:	95be                	add	a1,a1,a5
    8000160a:	4685                	li	a3,1
    8000160c:	00c5d613          	srli	a2,a1,0xc
    80001610:	4581                	li	a1,0
    80001612:	00000097          	auipc	ra,0x0
    80001616:	d2c080e7          	jalr	-724(ra) # 8000133e <uvmunmap>
    8000161a:	bfd9                	j	800015f0 <uvmfree+0xe>

000000008000161c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000161c:	ca4d                	beqz	a2,800016ce <uvmcopy+0xb2>
{
    8000161e:	715d                	addi	sp,sp,-80
    80001620:	e486                	sd	ra,72(sp)
    80001622:	e0a2                	sd	s0,64(sp)
    80001624:	fc26                	sd	s1,56(sp)
    80001626:	f84a                	sd	s2,48(sp)
    80001628:	f44e                	sd	s3,40(sp)
    8000162a:	f052                	sd	s4,32(sp)
    8000162c:	ec56                	sd	s5,24(sp)
    8000162e:	e85a                	sd	s6,16(sp)
    80001630:	e45e                	sd	s7,8(sp)
    80001632:	0880                	addi	s0,sp,80
    80001634:	8aaa                	mv	s5,a0
    80001636:	8b2e                	mv	s6,a1
    80001638:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000163a:	4481                	li	s1,0
    8000163c:	a029                	j	80001646 <uvmcopy+0x2a>
    8000163e:	6785                	lui	a5,0x1
    80001640:	94be                	add	s1,s1,a5
    80001642:	0744fa63          	bgeu	s1,s4,800016b6 <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    80001646:	4601                	li	a2,0
    80001648:	85a6                	mv	a1,s1
    8000164a:	8556                	mv	a0,s5
    8000164c:	00000097          	auipc	ra,0x0
    80001650:	998080e7          	jalr	-1640(ra) # 80000fe4 <walk>
    80001654:	d56d                	beqz	a0,8000163e <uvmcopy+0x22>
      //panic("uvmcopy: pte should exist");
      continue;
    if((*pte & PTE_V) == 0)
    80001656:	6118                	ld	a4,0(a0)
    80001658:	00177793          	andi	a5,a4,1
    8000165c:	d3ed                	beqz	a5,8000163e <uvmcopy+0x22>
     // panic("uvmcopy: page not present");
      continue;
    pa = PTE2PA(*pte);
    8000165e:	00a75593          	srli	a1,a4,0xa
    80001662:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001666:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	4a6080e7          	jalr	1190(ra) # 80000b10 <kalloc>
    80001672:	89aa                	mv	s3,a0
    80001674:	c515                	beqz	a0,800016a0 <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001676:	6605                	lui	a2,0x1
    80001678:	85de                	mv	a1,s7
    8000167a:	fffff097          	auipc	ra,0xfffff
    8000167e:	6de080e7          	jalr	1758(ra) # 80000d58 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001682:	874a                	mv	a4,s2
    80001684:	86ce                	mv	a3,s3
    80001686:	6605                	lui	a2,0x1
    80001688:	85a6                	mv	a1,s1
    8000168a:	855a                	mv	a0,s6
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	a5c080e7          	jalr	-1444(ra) # 800010e8 <mappages>
    80001694:	d54d                	beqz	a0,8000163e <uvmcopy+0x22>
      kfree(mem);
    80001696:	854e                	mv	a0,s3
    80001698:	fffff097          	auipc	ra,0xfffff
    8000169c:	37a080e7          	jalr	890(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016a0:	4685                	li	a3,1
    800016a2:	00c4d613          	srli	a2,s1,0xc
    800016a6:	4581                	li	a1,0
    800016a8:	855a                	mv	a0,s6
    800016aa:	00000097          	auipc	ra,0x0
    800016ae:	c94080e7          	jalr	-876(ra) # 8000133e <uvmunmap>
  return -1;
    800016b2:	557d                	li	a0,-1
    800016b4:	a011                	j	800016b8 <uvmcopy+0x9c>
  return 0;
    800016b6:	4501                	li	a0,0
}
    800016b8:	60a6                	ld	ra,72(sp)
    800016ba:	6406                	ld	s0,64(sp)
    800016bc:	74e2                	ld	s1,56(sp)
    800016be:	7942                	ld	s2,48(sp)
    800016c0:	79a2                	ld	s3,40(sp)
    800016c2:	7a02                	ld	s4,32(sp)
    800016c4:	6ae2                	ld	s5,24(sp)
    800016c6:	6b42                	ld	s6,16(sp)
    800016c8:	6ba2                	ld	s7,8(sp)
    800016ca:	6161                	addi	sp,sp,80
    800016cc:	8082                	ret
  return 0;
    800016ce:	4501                	li	a0,0
}
    800016d0:	8082                	ret

00000000800016d2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016d2:	1141                	addi	sp,sp,-16
    800016d4:	e406                	sd	ra,8(sp)
    800016d6:	e022                	sd	s0,0(sp)
    800016d8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016da:	4601                	li	a2,0
    800016dc:	00000097          	auipc	ra,0x0
    800016e0:	908080e7          	jalr	-1784(ra) # 80000fe4 <walk>
  if(pte == 0)
    800016e4:	c901                	beqz	a0,800016f4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016e6:	611c                	ld	a5,0(a0)
    800016e8:	9bbd                	andi	a5,a5,-17
    800016ea:	e11c                	sd	a5,0(a0)
}
    800016ec:	60a2                	ld	ra,8(sp)
    800016ee:	6402                	ld	s0,0(sp)
    800016f0:	0141                	addi	sp,sp,16
    800016f2:	8082                	ret
    panic("uvmclear");
    800016f4:	00007517          	auipc	a0,0x7
    800016f8:	a5c50513          	addi	a0,a0,-1444 # 80008150 <digits+0x110>
    800016fc:	fffff097          	auipc	ra,0xfffff
    80001700:	e4a080e7          	jalr	-438(ra) # 80000546 <panic>

0000000080001704 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001704:	c6bd                	beqz	a3,80001772 <copyout+0x6e>
{
    80001706:	715d                	addi	sp,sp,-80
    80001708:	e486                	sd	ra,72(sp)
    8000170a:	e0a2                	sd	s0,64(sp)
    8000170c:	fc26                	sd	s1,56(sp)
    8000170e:	f84a                	sd	s2,48(sp)
    80001710:	f44e                	sd	s3,40(sp)
    80001712:	f052                	sd	s4,32(sp)
    80001714:	ec56                	sd	s5,24(sp)
    80001716:	e85a                	sd	s6,16(sp)
    80001718:	e45e                	sd	s7,8(sp)
    8000171a:	e062                	sd	s8,0(sp)
    8000171c:	0880                	addi	s0,sp,80
    8000171e:	8b2a                	mv	s6,a0
    80001720:	8c2e                	mv	s8,a1
    80001722:	8a32                	mv	s4,a2
    80001724:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001726:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001728:	6a85                	lui	s5,0x1
    8000172a:	a015                	j	8000174e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000172c:	9562                	add	a0,a0,s8
    8000172e:	0004861b          	sext.w	a2,s1
    80001732:	85d2                	mv	a1,s4
    80001734:	41250533          	sub	a0,a0,s2
    80001738:	fffff097          	auipc	ra,0xfffff
    8000173c:	620080e7          	jalr	1568(ra) # 80000d58 <memmove>

    len -= n;
    80001740:	409989b3          	sub	s3,s3,s1
    src += n;
    80001744:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001746:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174a:	02098263          	beqz	s3,8000176e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000174e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001752:	85ca                	mv	a1,s2
    80001754:	855a                	mv	a0,s6
    80001756:	00000097          	auipc	ra,0x0
    8000175a:	a20080e7          	jalr	-1504(ra) # 80001176 <walkaddr>
    if(pa0 == 0)
    8000175e:	cd01                	beqz	a0,80001776 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001760:	418904b3          	sub	s1,s2,s8
    80001764:	94d6                	add	s1,s1,s5
    80001766:	fc99f3e3          	bgeu	s3,s1,8000172c <copyout+0x28>
    8000176a:	84ce                	mv	s1,s3
    8000176c:	b7c1                	j	8000172c <copyout+0x28>
  }
  return 0;
    8000176e:	4501                	li	a0,0
    80001770:	a021                	j	80001778 <copyout+0x74>
    80001772:	4501                	li	a0,0
}
    80001774:	8082                	ret
      return -1;
    80001776:	557d                	li	a0,-1
}
    80001778:	60a6                	ld	ra,72(sp)
    8000177a:	6406                	ld	s0,64(sp)
    8000177c:	74e2                	ld	s1,56(sp)
    8000177e:	7942                	ld	s2,48(sp)
    80001780:	79a2                	ld	s3,40(sp)
    80001782:	7a02                	ld	s4,32(sp)
    80001784:	6ae2                	ld	s5,24(sp)
    80001786:	6b42                	ld	s6,16(sp)
    80001788:	6ba2                	ld	s7,8(sp)
    8000178a:	6c02                	ld	s8,0(sp)
    8000178c:	6161                	addi	sp,sp,80
    8000178e:	8082                	ret

0000000080001790 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001790:	caa5                	beqz	a3,80001800 <copyin+0x70>
{
    80001792:	715d                	addi	sp,sp,-80
    80001794:	e486                	sd	ra,72(sp)
    80001796:	e0a2                	sd	s0,64(sp)
    80001798:	fc26                	sd	s1,56(sp)
    8000179a:	f84a                	sd	s2,48(sp)
    8000179c:	f44e                	sd	s3,40(sp)
    8000179e:	f052                	sd	s4,32(sp)
    800017a0:	ec56                	sd	s5,24(sp)
    800017a2:	e85a                	sd	s6,16(sp)
    800017a4:	e45e                	sd	s7,8(sp)
    800017a6:	e062                	sd	s8,0(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8b2a                	mv	s6,a0
    800017ac:	8a2e                	mv	s4,a1
    800017ae:	8c32                	mv	s8,a2
    800017b0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6a85                	lui	s5,0x1
    800017b6:	a01d                	j	800017dc <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017b8:	018505b3          	add	a1,a0,s8
    800017bc:	0004861b          	sext.w	a2,s1
    800017c0:	412585b3          	sub	a1,a1,s2
    800017c4:	8552                	mv	a0,s4
    800017c6:	fffff097          	auipc	ra,0xfffff
    800017ca:	592080e7          	jalr	1426(ra) # 80000d58 <memmove>

    len -= n;
    800017ce:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017d2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017d4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017d8:	02098263          	beqz	s3,800017fc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017dc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017e0:	85ca                	mv	a1,s2
    800017e2:	855a                	mv	a0,s6
    800017e4:	00000097          	auipc	ra,0x0
    800017e8:	992080e7          	jalr	-1646(ra) # 80001176 <walkaddr>
    if(pa0 == 0)
    800017ec:	cd01                	beqz	a0,80001804 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ee:	418904b3          	sub	s1,s2,s8
    800017f2:	94d6                	add	s1,s1,s5
    800017f4:	fc99f2e3          	bgeu	s3,s1,800017b8 <copyin+0x28>
    800017f8:	84ce                	mv	s1,s3
    800017fa:	bf7d                	j	800017b8 <copyin+0x28>
  }
  return 0;
    800017fc:	4501                	li	a0,0
    800017fe:	a021                	j	80001806 <copyin+0x76>
    80001800:	4501                	li	a0,0
}
    80001802:	8082                	ret
      return -1;
    80001804:	557d                	li	a0,-1
}
    80001806:	60a6                	ld	ra,72(sp)
    80001808:	6406                	ld	s0,64(sp)
    8000180a:	74e2                	ld	s1,56(sp)
    8000180c:	7942                	ld	s2,48(sp)
    8000180e:	79a2                	ld	s3,40(sp)
    80001810:	7a02                	ld	s4,32(sp)
    80001812:	6ae2                	ld	s5,24(sp)
    80001814:	6b42                	ld	s6,16(sp)
    80001816:	6ba2                	ld	s7,8(sp)
    80001818:	6c02                	ld	s8,0(sp)
    8000181a:	6161                	addi	sp,sp,80
    8000181c:	8082                	ret

000000008000181e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000181e:	c2dd                	beqz	a3,800018c4 <copyinstr+0xa6>
{
    80001820:	715d                	addi	sp,sp,-80
    80001822:	e486                	sd	ra,72(sp)
    80001824:	e0a2                	sd	s0,64(sp)
    80001826:	fc26                	sd	s1,56(sp)
    80001828:	f84a                	sd	s2,48(sp)
    8000182a:	f44e                	sd	s3,40(sp)
    8000182c:	f052                	sd	s4,32(sp)
    8000182e:	ec56                	sd	s5,24(sp)
    80001830:	e85a                	sd	s6,16(sp)
    80001832:	e45e                	sd	s7,8(sp)
    80001834:	0880                	addi	s0,sp,80
    80001836:	8a2a                	mv	s4,a0
    80001838:	8b2e                	mv	s6,a1
    8000183a:	8bb2                	mv	s7,a2
    8000183c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000183e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001840:	6985                	lui	s3,0x1
    80001842:	a02d                	j	8000186c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001844:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001848:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000184a:	37fd                	addiw	a5,a5,-1
    8000184c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001850:	60a6                	ld	ra,72(sp)
    80001852:	6406                	ld	s0,64(sp)
    80001854:	74e2                	ld	s1,56(sp)
    80001856:	7942                	ld	s2,48(sp)
    80001858:	79a2                	ld	s3,40(sp)
    8000185a:	7a02                	ld	s4,32(sp)
    8000185c:	6ae2                	ld	s5,24(sp)
    8000185e:	6b42                	ld	s6,16(sp)
    80001860:	6ba2                	ld	s7,8(sp)
    80001862:	6161                	addi	sp,sp,80
    80001864:	8082                	ret
    srcva = va0 + PGSIZE;
    80001866:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000186a:	c8a9                	beqz	s1,800018bc <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000186c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001870:	85ca                	mv	a1,s2
    80001872:	8552                	mv	a0,s4
    80001874:	00000097          	auipc	ra,0x0
    80001878:	902080e7          	jalr	-1790(ra) # 80001176 <walkaddr>
    if(pa0 == 0)
    8000187c:	c131                	beqz	a0,800018c0 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000187e:	417906b3          	sub	a3,s2,s7
    80001882:	96ce                	add	a3,a3,s3
    80001884:	00d4f363          	bgeu	s1,a3,8000188a <copyinstr+0x6c>
    80001888:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000188a:	955e                	add	a0,a0,s7
    8000188c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001890:	daf9                	beqz	a3,80001866 <copyinstr+0x48>
    80001892:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001894:	41650633          	sub	a2,a0,s6
    80001898:	fff48593          	addi	a1,s1,-1
    8000189c:	95da                	add	a1,a1,s6
    while(n > 0){
    8000189e:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800018a0:	00f60733          	add	a4,a2,a5
    800018a4:	00074703          	lbu	a4,0(a4)
    800018a8:	df51                	beqz	a4,80001844 <copyinstr+0x26>
        *dst = *p;
    800018aa:	00e78023          	sb	a4,0(a5)
      --max;
    800018ae:	40f584b3          	sub	s1,a1,a5
      dst++;
    800018b2:	0785                	addi	a5,a5,1
    while(n > 0){
    800018b4:	fed796e3          	bne	a5,a3,800018a0 <copyinstr+0x82>
      dst++;
    800018b8:	8b3e                	mv	s6,a5
    800018ba:	b775                	j	80001866 <copyinstr+0x48>
    800018bc:	4781                	li	a5,0
    800018be:	b771                	j	8000184a <copyinstr+0x2c>
      return -1;
    800018c0:	557d                	li	a0,-1
    800018c2:	b779                	j	80001850 <copyinstr+0x32>
  int got_null = 0;
    800018c4:	4781                	li	a5,0
  if(got_null){
    800018c6:	37fd                	addiw	a5,a5,-1
    800018c8:	0007851b          	sext.w	a0,a5
}
    800018cc:	8082                	ret

00000000800018ce <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018ce:	1101                	addi	sp,sp,-32
    800018d0:	ec06                	sd	ra,24(sp)
    800018d2:	e822                	sd	s0,16(sp)
    800018d4:	e426                	sd	s1,8(sp)
    800018d6:	1000                	addi	s0,sp,32
    800018d8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018da:	fffff097          	auipc	ra,0xfffff
    800018de:	2ac080e7          	jalr	684(ra) # 80000b86 <holding>
    800018e2:	c909                	beqz	a0,800018f4 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018e4:	749c                	ld	a5,40(s1)
    800018e6:	00978f63          	beq	a5,s1,80001904 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018ea:	60e2                	ld	ra,24(sp)
    800018ec:	6442                	ld	s0,16(sp)
    800018ee:	64a2                	ld	s1,8(sp)
    800018f0:	6105                	addi	sp,sp,32
    800018f2:	8082                	ret
    panic("wakeup1");
    800018f4:	00007517          	auipc	a0,0x7
    800018f8:	86c50513          	addi	a0,a0,-1940 # 80008160 <digits+0x120>
    800018fc:	fffff097          	auipc	ra,0xfffff
    80001900:	c4a080e7          	jalr	-950(ra) # 80000546 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001904:	4c98                	lw	a4,24(s1)
    80001906:	4785                	li	a5,1
    80001908:	fef711e3          	bne	a4,a5,800018ea <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000190c:	4789                	li	a5,2
    8000190e:	cc9c                	sw	a5,24(s1)
}
    80001910:	bfe9                	j	800018ea <wakeup1+0x1c>

0000000080001912 <procinit>:
{
    80001912:	715d                	addi	sp,sp,-80
    80001914:	e486                	sd	ra,72(sp)
    80001916:	e0a2                	sd	s0,64(sp)
    80001918:	fc26                	sd	s1,56(sp)
    8000191a:	f84a                	sd	s2,48(sp)
    8000191c:	f44e                	sd	s3,40(sp)
    8000191e:	f052                	sd	s4,32(sp)
    80001920:	ec56                	sd	s5,24(sp)
    80001922:	e85a                	sd	s6,16(sp)
    80001924:	e45e                	sd	s7,8(sp)
    80001926:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001928:	00007597          	auipc	a1,0x7
    8000192c:	84058593          	addi	a1,a1,-1984 # 80008168 <digits+0x128>
    80001930:	00010517          	auipc	a0,0x10
    80001934:	02050513          	addi	a0,a0,32 # 80011950 <pid_lock>
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	238080e7          	jalr	568(ra) # 80000b70 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001940:	00010917          	auipc	s2,0x10
    80001944:	42890913          	addi	s2,s2,1064 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001948:	00007b97          	auipc	s7,0x7
    8000194c:	828b8b93          	addi	s7,s7,-2008 # 80008170 <digits+0x130>
      uint64 va = KSTACK((int) (p - proc));
    80001950:	8b4a                	mv	s6,s2
    80001952:	00006a97          	auipc	s5,0x6
    80001956:	6aea8a93          	addi	s5,s5,1710 # 80008000 <etext>
    8000195a:	040009b7          	lui	s3,0x4000
    8000195e:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001960:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001962:	00016a17          	auipc	s4,0x16
    80001966:	e06a0a13          	addi	s4,s4,-506 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    8000196a:	85de                	mv	a1,s7
    8000196c:	854a                	mv	a0,s2
    8000196e:	fffff097          	auipc	ra,0xfffff
    80001972:	202080e7          	jalr	514(ra) # 80000b70 <initlock>
      char *pa = kalloc();
    80001976:	fffff097          	auipc	ra,0xfffff
    8000197a:	19a080e7          	jalr	410(ra) # 80000b10 <kalloc>
    8000197e:	85aa                	mv	a1,a0
      if(pa == 0)
    80001980:	c929                	beqz	a0,800019d2 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001982:	416904b3          	sub	s1,s2,s6
    80001986:	848d                	srai	s1,s1,0x3
    80001988:	000ab783          	ld	a5,0(s5)
    8000198c:	02f484b3          	mul	s1,s1,a5
    80001990:	2485                	addiw	s1,s1,1
    80001992:	00d4949b          	slliw	s1,s1,0xd
    80001996:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000199a:	4699                	li	a3,6
    8000199c:	6605                	lui	a2,0x1
    8000199e:	8526                	mv	a0,s1
    800019a0:	00000097          	auipc	ra,0x0
    800019a4:	894080e7          	jalr	-1900(ra) # 80001234 <kvmmap>
      p->kstack = va;
    800019a8:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ac:	16890913          	addi	s2,s2,360
    800019b0:	fb491de3          	bne	s2,s4,8000196a <procinit+0x58>
  kvminithart();
    800019b4:	fffff097          	auipc	ra,0xfffff
    800019b8:	60c080e7          	jalr	1548(ra) # 80000fc0 <kvminithart>
}
    800019bc:	60a6                	ld	ra,72(sp)
    800019be:	6406                	ld	s0,64(sp)
    800019c0:	74e2                	ld	s1,56(sp)
    800019c2:	7942                	ld	s2,48(sp)
    800019c4:	79a2                	ld	s3,40(sp)
    800019c6:	7a02                	ld	s4,32(sp)
    800019c8:	6ae2                	ld	s5,24(sp)
    800019ca:	6b42                	ld	s6,16(sp)
    800019cc:	6ba2                	ld	s7,8(sp)
    800019ce:	6161                	addi	sp,sp,80
    800019d0:	8082                	ret
        panic("kalloc");
    800019d2:	00006517          	auipc	a0,0x6
    800019d6:	7a650513          	addi	a0,a0,1958 # 80008178 <digits+0x138>
    800019da:	fffff097          	auipc	ra,0xfffff
    800019de:	b6c080e7          	jalr	-1172(ra) # 80000546 <panic>

00000000800019e2 <cpuid>:
{
    800019e2:	1141                	addi	sp,sp,-16
    800019e4:	e422                	sd	s0,8(sp)
    800019e6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019e8:	8512                	mv	a0,tp
}
    800019ea:	2501                	sext.w	a0,a0
    800019ec:	6422                	ld	s0,8(sp)
    800019ee:	0141                	addi	sp,sp,16
    800019f0:	8082                	ret

00000000800019f2 <mycpu>:
mycpu(void) {
    800019f2:	1141                	addi	sp,sp,-16
    800019f4:	e422                	sd	s0,8(sp)
    800019f6:	0800                	addi	s0,sp,16
    800019f8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019fa:	2781                	sext.w	a5,a5
    800019fc:	079e                	slli	a5,a5,0x7
}
    800019fe:	00010517          	auipc	a0,0x10
    80001a02:	f6a50513          	addi	a0,a0,-150 # 80011968 <cpus>
    80001a06:	953e                	add	a0,a0,a5
    80001a08:	6422                	ld	s0,8(sp)
    80001a0a:	0141                	addi	sp,sp,16
    80001a0c:	8082                	ret

0000000080001a0e <myproc>:
myproc(void) {
    80001a0e:	1101                	addi	sp,sp,-32
    80001a10:	ec06                	sd	ra,24(sp)
    80001a12:	e822                	sd	s0,16(sp)
    80001a14:	e426                	sd	s1,8(sp)
    80001a16:	1000                	addi	s0,sp,32
  push_off();
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	19c080e7          	jalr	412(ra) # 80000bb4 <push_off>
    80001a20:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a22:	2781                	sext.w	a5,a5
    80001a24:	079e                	slli	a5,a5,0x7
    80001a26:	00010717          	auipc	a4,0x10
    80001a2a:	f2a70713          	addi	a4,a4,-214 # 80011950 <pid_lock>
    80001a2e:	97ba                	add	a5,a5,a4
    80001a30:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a32:	fffff097          	auipc	ra,0xfffff
    80001a36:	222080e7          	jalr	546(ra) # 80000c54 <pop_off>
}
    80001a3a:	8526                	mv	a0,s1
    80001a3c:	60e2                	ld	ra,24(sp)
    80001a3e:	6442                	ld	s0,16(sp)
    80001a40:	64a2                	ld	s1,8(sp)
    80001a42:	6105                	addi	sp,sp,32
    80001a44:	8082                	ret

0000000080001a46 <forkret>:
{
    80001a46:	1141                	addi	sp,sp,-16
    80001a48:	e406                	sd	ra,8(sp)
    80001a4a:	e022                	sd	s0,0(sp)
    80001a4c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a4e:	00000097          	auipc	ra,0x0
    80001a52:	fc0080e7          	jalr	-64(ra) # 80001a0e <myproc>
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	25e080e7          	jalr	606(ra) # 80000cb4 <release>
  if (first) {
    80001a5e:	00007797          	auipc	a5,0x7
    80001a62:	d527a783          	lw	a5,-686(a5) # 800087b0 <first.1>
    80001a66:	eb89                	bnez	a5,80001a78 <forkret+0x32>
  usertrapret();
    80001a68:	00001097          	auipc	ra,0x1
    80001a6c:	c4c080e7          	jalr	-948(ra) # 800026b4 <usertrapret>
}
    80001a70:	60a2                	ld	ra,8(sp)
    80001a72:	6402                	ld	s0,0(sp)
    80001a74:	0141                	addi	sp,sp,16
    80001a76:	8082                	ret
    first = 0;
    80001a78:	00007797          	auipc	a5,0x7
    80001a7c:	d207ac23          	sw	zero,-712(a5) # 800087b0 <first.1>
    fsinit(ROOTDEV);
    80001a80:	4505                	li	a0,1
    80001a82:	00002097          	auipc	ra,0x2
    80001a86:	9ec080e7          	jalr	-1556(ra) # 8000346e <fsinit>
    80001a8a:	bff9                	j	80001a68 <forkret+0x22>

0000000080001a8c <allocpid>:
allocpid() {
    80001a8c:	1101                	addi	sp,sp,-32
    80001a8e:	ec06                	sd	ra,24(sp)
    80001a90:	e822                	sd	s0,16(sp)
    80001a92:	e426                	sd	s1,8(sp)
    80001a94:	e04a                	sd	s2,0(sp)
    80001a96:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a98:	00010917          	auipc	s2,0x10
    80001a9c:	eb890913          	addi	s2,s2,-328 # 80011950 <pid_lock>
    80001aa0:	854a                	mv	a0,s2
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	15e080e7          	jalr	350(ra) # 80000c00 <acquire>
  pid = nextpid;
    80001aaa:	00007797          	auipc	a5,0x7
    80001aae:	d0a78793          	addi	a5,a5,-758 # 800087b4 <nextpid>
    80001ab2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ab4:	0014871b          	addiw	a4,s1,1
    80001ab8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aba:	854a                	mv	a0,s2
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	1f8080e7          	jalr	504(ra) # 80000cb4 <release>
}
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	60e2                	ld	ra,24(sp)
    80001ac8:	6442                	ld	s0,16(sp)
    80001aca:	64a2                	ld	s1,8(sp)
    80001acc:	6902                	ld	s2,0(sp)
    80001ace:	6105                	addi	sp,sp,32
    80001ad0:	8082                	ret

0000000080001ad2 <proc_pagetable>:
{
    80001ad2:	1101                	addi	sp,sp,-32
    80001ad4:	ec06                	sd	ra,24(sp)
    80001ad6:	e822                	sd	s0,16(sp)
    80001ad8:	e426                	sd	s1,8(sp)
    80001ada:	e04a                	sd	s2,0(sp)
    80001adc:	1000                	addi	s0,sp,32
    80001ade:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ae0:	00000097          	auipc	ra,0x0
    80001ae4:	904080e7          	jalr	-1788(ra) # 800013e4 <uvmcreate>
    80001ae8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aea:	c121                	beqz	a0,80001b2a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aec:	4729                	li	a4,10
    80001aee:	00005697          	auipc	a3,0x5
    80001af2:	51268693          	addi	a3,a3,1298 # 80007000 <_trampoline>
    80001af6:	6605                	lui	a2,0x1
    80001af8:	040005b7          	lui	a1,0x4000
    80001afc:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001afe:	05b2                	slli	a1,a1,0xc
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	5e8080e7          	jalr	1512(ra) # 800010e8 <mappages>
    80001b08:	02054863          	bltz	a0,80001b38 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b0c:	4719                	li	a4,6
    80001b0e:	05893683          	ld	a3,88(s2)
    80001b12:	6605                	lui	a2,0x1
    80001b14:	020005b7          	lui	a1,0x2000
    80001b18:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b1a:	05b6                	slli	a1,a1,0xd
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	5ca080e7          	jalr	1482(ra) # 800010e8 <mappages>
    80001b26:	02054163          	bltz	a0,80001b48 <proc_pagetable+0x76>
}
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	60e2                	ld	ra,24(sp)
    80001b2e:	6442                	ld	s0,16(sp)
    80001b30:	64a2                	ld	s1,8(sp)
    80001b32:	6902                	ld	s2,0(sp)
    80001b34:	6105                	addi	sp,sp,32
    80001b36:	8082                	ret
    uvmfree(pagetable, 0);
    80001b38:	4581                	li	a1,0
    80001b3a:	8526                	mv	a0,s1
    80001b3c:	00000097          	auipc	ra,0x0
    80001b40:	aa6080e7          	jalr	-1370(ra) # 800015e2 <uvmfree>
    return 0;
    80001b44:	4481                	li	s1,0
    80001b46:	b7d5                	j	80001b2a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b48:	4681                	li	a3,0
    80001b4a:	4605                	li	a2,1
    80001b4c:	040005b7          	lui	a1,0x4000
    80001b50:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b52:	05b2                	slli	a1,a1,0xc
    80001b54:	8526                	mv	a0,s1
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	7e8080e7          	jalr	2024(ra) # 8000133e <uvmunmap>
    uvmfree(pagetable, 0);
    80001b5e:	4581                	li	a1,0
    80001b60:	8526                	mv	a0,s1
    80001b62:	00000097          	auipc	ra,0x0
    80001b66:	a80080e7          	jalr	-1408(ra) # 800015e2 <uvmfree>
    return 0;
    80001b6a:	4481                	li	s1,0
    80001b6c:	bf7d                	j	80001b2a <proc_pagetable+0x58>

0000000080001b6e <proc_freepagetable>:
{
    80001b6e:	1101                	addi	sp,sp,-32
    80001b70:	ec06                	sd	ra,24(sp)
    80001b72:	e822                	sd	s0,16(sp)
    80001b74:	e426                	sd	s1,8(sp)
    80001b76:	e04a                	sd	s2,0(sp)
    80001b78:	1000                	addi	s0,sp,32
    80001b7a:	84aa                	mv	s1,a0
    80001b7c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b7e:	4681                	li	a3,0
    80001b80:	4605                	li	a2,1
    80001b82:	040005b7          	lui	a1,0x4000
    80001b86:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b88:	05b2                	slli	a1,a1,0xc
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	7b4080e7          	jalr	1972(ra) # 8000133e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b92:	4681                	li	a3,0
    80001b94:	4605                	li	a2,1
    80001b96:	020005b7          	lui	a1,0x2000
    80001b9a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b9c:	05b6                	slli	a1,a1,0xd
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	79e080e7          	jalr	1950(ra) # 8000133e <uvmunmap>
  uvmfree(pagetable, sz);
    80001ba8:	85ca                	mv	a1,s2
    80001baa:	8526                	mv	a0,s1
    80001bac:	00000097          	auipc	ra,0x0
    80001bb0:	a36080e7          	jalr	-1482(ra) # 800015e2 <uvmfree>
}
    80001bb4:	60e2                	ld	ra,24(sp)
    80001bb6:	6442                	ld	s0,16(sp)
    80001bb8:	64a2                	ld	s1,8(sp)
    80001bba:	6902                	ld	s2,0(sp)
    80001bbc:	6105                	addi	sp,sp,32
    80001bbe:	8082                	ret

0000000080001bc0 <freeproc>:
{
    80001bc0:	1101                	addi	sp,sp,-32
    80001bc2:	ec06                	sd	ra,24(sp)
    80001bc4:	e822                	sd	s0,16(sp)
    80001bc6:	e426                	sd	s1,8(sp)
    80001bc8:	1000                	addi	s0,sp,32
    80001bca:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bcc:	6d28                	ld	a0,88(a0)
    80001bce:	c509                	beqz	a0,80001bd8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	e42080e7          	jalr	-446(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001bd8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bdc:	68a8                	ld	a0,80(s1)
    80001bde:	c511                	beqz	a0,80001bea <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001be0:	64ac                	ld	a1,72(s1)
    80001be2:	00000097          	auipc	ra,0x0
    80001be6:	f8c080e7          	jalr	-116(ra) # 80001b6e <proc_freepagetable>
  p->pagetable = 0;
    80001bea:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bee:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bf2:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bf6:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bfa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bfe:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c02:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c06:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c0a:	0004ac23          	sw	zero,24(s1)
}
    80001c0e:	60e2                	ld	ra,24(sp)
    80001c10:	6442                	ld	s0,16(sp)
    80001c12:	64a2                	ld	s1,8(sp)
    80001c14:	6105                	addi	sp,sp,32
    80001c16:	8082                	ret

0000000080001c18 <allocproc>:
{
    80001c18:	1101                	addi	sp,sp,-32
    80001c1a:	ec06                	sd	ra,24(sp)
    80001c1c:	e822                	sd	s0,16(sp)
    80001c1e:	e426                	sd	s1,8(sp)
    80001c20:	e04a                	sd	s2,0(sp)
    80001c22:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c24:	00010497          	auipc	s1,0x10
    80001c28:	14448493          	addi	s1,s1,324 # 80011d68 <proc>
    80001c2c:	00016917          	auipc	s2,0x16
    80001c30:	b3c90913          	addi	s2,s2,-1220 # 80017768 <tickslock>
    acquire(&p->lock);
    80001c34:	8526                	mv	a0,s1
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	fca080e7          	jalr	-54(ra) # 80000c00 <acquire>
    if(p->state == UNUSED) {
    80001c3e:	4c9c                	lw	a5,24(s1)
    80001c40:	cf81                	beqz	a5,80001c58 <allocproc+0x40>
      release(&p->lock);
    80001c42:	8526                	mv	a0,s1
    80001c44:	fffff097          	auipc	ra,0xfffff
    80001c48:	070080e7          	jalr	112(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c4c:	16848493          	addi	s1,s1,360
    80001c50:	ff2492e3          	bne	s1,s2,80001c34 <allocproc+0x1c>
  return 0;
    80001c54:	4481                	li	s1,0
    80001c56:	a0b9                	j	80001ca4 <allocproc+0x8c>
  p->pid = allocpid();
    80001c58:	00000097          	auipc	ra,0x0
    80001c5c:	e34080e7          	jalr	-460(ra) # 80001a8c <allocpid>
    80001c60:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	eae080e7          	jalr	-338(ra) # 80000b10 <kalloc>
    80001c6a:	892a                	mv	s2,a0
    80001c6c:	eca8                	sd	a0,88(s1)
    80001c6e:	c131                	beqz	a0,80001cb2 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	e60080e7          	jalr	-416(ra) # 80001ad2 <proc_pagetable>
    80001c7a:	892a                	mv	s2,a0
    80001c7c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c7e:	c129                	beqz	a0,80001cc0 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c80:	07000613          	li	a2,112
    80001c84:	4581                	li	a1,0
    80001c86:	06048513          	addi	a0,s1,96
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	072080e7          	jalr	114(ra) # 80000cfc <memset>
  p->context.ra = (uint64)forkret;
    80001c92:	00000797          	auipc	a5,0x0
    80001c96:	db478793          	addi	a5,a5,-588 # 80001a46 <forkret>
    80001c9a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c9c:	60bc                	ld	a5,64(s1)
    80001c9e:	6705                	lui	a4,0x1
    80001ca0:	97ba                	add	a5,a5,a4
    80001ca2:	f4bc                	sd	a5,104(s1)
}
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	60e2                	ld	ra,24(sp)
    80001ca8:	6442                	ld	s0,16(sp)
    80001caa:	64a2                	ld	s1,8(sp)
    80001cac:	6902                	ld	s2,0(sp)
    80001cae:	6105                	addi	sp,sp,32
    80001cb0:	8082                	ret
    release(&p->lock);
    80001cb2:	8526                	mv	a0,s1
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	000080e7          	jalr	ra # 80000cb4 <release>
    return 0;
    80001cbc:	84ca                	mv	s1,s2
    80001cbe:	b7dd                	j	80001ca4 <allocproc+0x8c>
    freeproc(p);
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	00000097          	auipc	ra,0x0
    80001cc6:	efe080e7          	jalr	-258(ra) # 80001bc0 <freeproc>
    release(&p->lock);
    80001cca:	8526                	mv	a0,s1
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	fe8080e7          	jalr	-24(ra) # 80000cb4 <release>
    return 0;
    80001cd4:	84ca                	mv	s1,s2
    80001cd6:	b7f9                	j	80001ca4 <allocproc+0x8c>

0000000080001cd8 <userinit>:
{
    80001cd8:	1101                	addi	sp,sp,-32
    80001cda:	ec06                	sd	ra,24(sp)
    80001cdc:	e822                	sd	s0,16(sp)
    80001cde:	e426                	sd	s1,8(sp)
    80001ce0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ce2:	00000097          	auipc	ra,0x0
    80001ce6:	f36080e7          	jalr	-202(ra) # 80001c18 <allocproc>
    80001cea:	84aa                	mv	s1,a0
  initproc = p;
    80001cec:	00007797          	auipc	a5,0x7
    80001cf0:	32a7b623          	sd	a0,812(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cf4:	03400613          	li	a2,52
    80001cf8:	00007597          	auipc	a1,0x7
    80001cfc:	ac858593          	addi	a1,a1,-1336 # 800087c0 <initcode>
    80001d00:	6928                	ld	a0,80(a0)
    80001d02:	fffff097          	auipc	ra,0xfffff
    80001d06:	710080e7          	jalr	1808(ra) # 80001412 <uvminit>
  p->sz = PGSIZE;
    80001d0a:	6785                	lui	a5,0x1
    80001d0c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d0e:	6cb8                	ld	a4,88(s1)
    80001d10:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d14:	6cb8                	ld	a4,88(s1)
    80001d16:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d18:	4641                	li	a2,16
    80001d1a:	00006597          	auipc	a1,0x6
    80001d1e:	46658593          	addi	a1,a1,1126 # 80008180 <digits+0x140>
    80001d22:	15848513          	addi	a0,s1,344
    80001d26:	fffff097          	auipc	ra,0xfffff
    80001d2a:	128080e7          	jalr	296(ra) # 80000e4e <safestrcpy>
  p->cwd = namei("/");
    80001d2e:	00006517          	auipc	a0,0x6
    80001d32:	46250513          	addi	a0,a0,1122 # 80008190 <digits+0x150>
    80001d36:	00002097          	auipc	ra,0x2
    80001d3a:	16c080e7          	jalr	364(ra) # 80003ea2 <namei>
    80001d3e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d42:	4789                	li	a5,2
    80001d44:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d46:	8526                	mv	a0,s1
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	f6c080e7          	jalr	-148(ra) # 80000cb4 <release>
}
    80001d50:	60e2                	ld	ra,24(sp)
    80001d52:	6442                	ld	s0,16(sp)
    80001d54:	64a2                	ld	s1,8(sp)
    80001d56:	6105                	addi	sp,sp,32
    80001d58:	8082                	ret

0000000080001d5a <growproc>:
{
    80001d5a:	1101                	addi	sp,sp,-32
    80001d5c:	ec06                	sd	ra,24(sp)
    80001d5e:	e822                	sd	s0,16(sp)
    80001d60:	e426                	sd	s1,8(sp)
    80001d62:	e04a                	sd	s2,0(sp)
    80001d64:	1000                	addi	s0,sp,32
    80001d66:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	ca6080e7          	jalr	-858(ra) # 80001a0e <myproc>
    80001d70:	892a                	mv	s2,a0
  sz = p->sz;
    80001d72:	652c                	ld	a1,72(a0)
    80001d74:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d78:	00904f63          	bgtz	s1,80001d96 <growproc+0x3c>
  } else if(n < 0){
    80001d7c:	0204cd63          	bltz	s1,80001db6 <growproc+0x5c>
  p->sz = sz;
    80001d80:	1782                	slli	a5,a5,0x20
    80001d82:	9381                	srli	a5,a5,0x20
    80001d84:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d88:	4501                	li	a0,0
}
    80001d8a:	60e2                	ld	ra,24(sp)
    80001d8c:	6442                	ld	s0,16(sp)
    80001d8e:	64a2                	ld	s1,8(sp)
    80001d90:	6902                	ld	s2,0(sp)
    80001d92:	6105                	addi	sp,sp,32
    80001d94:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d96:	00f4863b          	addw	a2,s1,a5
    80001d9a:	1602                	slli	a2,a2,0x20
    80001d9c:	9201                	srli	a2,a2,0x20
    80001d9e:	1582                	slli	a1,a1,0x20
    80001da0:	9181                	srli	a1,a1,0x20
    80001da2:	6928                	ld	a0,80(a0)
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	728080e7          	jalr	1832(ra) # 800014cc <uvmalloc>
    80001dac:	0005079b          	sext.w	a5,a0
    80001db0:	fbe1                	bnez	a5,80001d80 <growproc+0x26>
      return -1;
    80001db2:	557d                	li	a0,-1
    80001db4:	bfd9                	j	80001d8a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001db6:	00f4863b          	addw	a2,s1,a5
    80001dba:	1602                	slli	a2,a2,0x20
    80001dbc:	9201                	srli	a2,a2,0x20
    80001dbe:	1582                	slli	a1,a1,0x20
    80001dc0:	9181                	srli	a1,a1,0x20
    80001dc2:	6928                	ld	a0,80(a0)
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	6c0080e7          	jalr	1728(ra) # 80001484 <uvmdealloc>
    80001dcc:	0005079b          	sext.w	a5,a0
    80001dd0:	bf45                	j	80001d80 <growproc+0x26>

0000000080001dd2 <fork>:
{
    80001dd2:	7139                	addi	sp,sp,-64
    80001dd4:	fc06                	sd	ra,56(sp)
    80001dd6:	f822                	sd	s0,48(sp)
    80001dd8:	f426                	sd	s1,40(sp)
    80001dda:	f04a                	sd	s2,32(sp)
    80001ddc:	ec4e                	sd	s3,24(sp)
    80001dde:	e852                	sd	s4,16(sp)
    80001de0:	e456                	sd	s5,8(sp)
    80001de2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001de4:	00000097          	auipc	ra,0x0
    80001de8:	c2a080e7          	jalr	-982(ra) # 80001a0e <myproc>
    80001dec:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	e2a080e7          	jalr	-470(ra) # 80001c18 <allocproc>
    80001df6:	c17d                	beqz	a0,80001edc <fork+0x10a>
    80001df8:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dfa:	048ab603          	ld	a2,72(s5)
    80001dfe:	692c                	ld	a1,80(a0)
    80001e00:	050ab503          	ld	a0,80(s5)
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	818080e7          	jalr	-2024(ra) # 8000161c <uvmcopy>
    80001e0c:	04054a63          	bltz	a0,80001e60 <fork+0x8e>
  np->sz = p->sz;
    80001e10:	048ab783          	ld	a5,72(s5)
    80001e14:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001e18:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e1c:	058ab683          	ld	a3,88(s5)
    80001e20:	87b6                	mv	a5,a3
    80001e22:	058a3703          	ld	a4,88(s4)
    80001e26:	12068693          	addi	a3,a3,288
    80001e2a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e2e:	6788                	ld	a0,8(a5)
    80001e30:	6b8c                	ld	a1,16(a5)
    80001e32:	6f90                	ld	a2,24(a5)
    80001e34:	01073023          	sd	a6,0(a4)
    80001e38:	e708                	sd	a0,8(a4)
    80001e3a:	eb0c                	sd	a1,16(a4)
    80001e3c:	ef10                	sd	a2,24(a4)
    80001e3e:	02078793          	addi	a5,a5,32
    80001e42:	02070713          	addi	a4,a4,32
    80001e46:	fed792e3          	bne	a5,a3,80001e2a <fork+0x58>
  np->trapframe->a0 = 0;
    80001e4a:	058a3783          	ld	a5,88(s4)
    80001e4e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e52:	0d0a8493          	addi	s1,s5,208
    80001e56:	0d0a0913          	addi	s2,s4,208
    80001e5a:	150a8993          	addi	s3,s5,336
    80001e5e:	a00d                	j	80001e80 <fork+0xae>
    freeproc(np);
    80001e60:	8552                	mv	a0,s4
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	d5e080e7          	jalr	-674(ra) # 80001bc0 <freeproc>
    release(&np->lock);
    80001e6a:	8552                	mv	a0,s4
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e48080e7          	jalr	-440(ra) # 80000cb4 <release>
    return -1;
    80001e74:	54fd                	li	s1,-1
    80001e76:	a889                	j	80001ec8 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001e78:	04a1                	addi	s1,s1,8
    80001e7a:	0921                	addi	s2,s2,8
    80001e7c:	01348b63          	beq	s1,s3,80001e92 <fork+0xc0>
    if(p->ofile[i])
    80001e80:	6088                	ld	a0,0(s1)
    80001e82:	d97d                	beqz	a0,80001e78 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e84:	00002097          	auipc	ra,0x2
    80001e88:	6aa080e7          	jalr	1706(ra) # 8000452e <filedup>
    80001e8c:	00a93023          	sd	a0,0(s2)
    80001e90:	b7e5                	j	80001e78 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001e92:	150ab503          	ld	a0,336(s5)
    80001e96:	00002097          	auipc	ra,0x2
    80001e9a:	814080e7          	jalr	-2028(ra) # 800036aa <idup>
    80001e9e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ea2:	4641                	li	a2,16
    80001ea4:	158a8593          	addi	a1,s5,344
    80001ea8:	158a0513          	addi	a0,s4,344
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	fa2080e7          	jalr	-94(ra) # 80000e4e <safestrcpy>
  pid = np->pid;
    80001eb4:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001eb8:	4789                	li	a5,2
    80001eba:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ebe:	8552                	mv	a0,s4
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	df4080e7          	jalr	-524(ra) # 80000cb4 <release>
}
    80001ec8:	8526                	mv	a0,s1
    80001eca:	70e2                	ld	ra,56(sp)
    80001ecc:	7442                	ld	s0,48(sp)
    80001ece:	74a2                	ld	s1,40(sp)
    80001ed0:	7902                	ld	s2,32(sp)
    80001ed2:	69e2                	ld	s3,24(sp)
    80001ed4:	6a42                	ld	s4,16(sp)
    80001ed6:	6aa2                	ld	s5,8(sp)
    80001ed8:	6121                	addi	sp,sp,64
    80001eda:	8082                	ret
    return -1;
    80001edc:	54fd                	li	s1,-1
    80001ede:	b7ed                	j	80001ec8 <fork+0xf6>

0000000080001ee0 <reparent>:
{
    80001ee0:	7179                	addi	sp,sp,-48
    80001ee2:	f406                	sd	ra,40(sp)
    80001ee4:	f022                	sd	s0,32(sp)
    80001ee6:	ec26                	sd	s1,24(sp)
    80001ee8:	e84a                	sd	s2,16(sp)
    80001eea:	e44e                	sd	s3,8(sp)
    80001eec:	e052                	sd	s4,0(sp)
    80001eee:	1800                	addi	s0,sp,48
    80001ef0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ef2:	00010497          	auipc	s1,0x10
    80001ef6:	e7648493          	addi	s1,s1,-394 # 80011d68 <proc>
      pp->parent = initproc;
    80001efa:	00007a17          	auipc	s4,0x7
    80001efe:	11ea0a13          	addi	s4,s4,286 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f02:	00016997          	auipc	s3,0x16
    80001f06:	86698993          	addi	s3,s3,-1946 # 80017768 <tickslock>
    80001f0a:	a029                	j	80001f14 <reparent+0x34>
    80001f0c:	16848493          	addi	s1,s1,360
    80001f10:	03348363          	beq	s1,s3,80001f36 <reparent+0x56>
    if(pp->parent == p){
    80001f14:	709c                	ld	a5,32(s1)
    80001f16:	ff279be3          	bne	a5,s2,80001f0c <reparent+0x2c>
      acquire(&pp->lock);
    80001f1a:	8526                	mv	a0,s1
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	ce4080e7          	jalr	-796(ra) # 80000c00 <acquire>
      pp->parent = initproc;
    80001f24:	000a3783          	ld	a5,0(s4)
    80001f28:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	fffff097          	auipc	ra,0xfffff
    80001f30:	d88080e7          	jalr	-632(ra) # 80000cb4 <release>
    80001f34:	bfe1                	j	80001f0c <reparent+0x2c>
}
    80001f36:	70a2                	ld	ra,40(sp)
    80001f38:	7402                	ld	s0,32(sp)
    80001f3a:	64e2                	ld	s1,24(sp)
    80001f3c:	6942                	ld	s2,16(sp)
    80001f3e:	69a2                	ld	s3,8(sp)
    80001f40:	6a02                	ld	s4,0(sp)
    80001f42:	6145                	addi	sp,sp,48
    80001f44:	8082                	ret

0000000080001f46 <scheduler>:
{
    80001f46:	711d                	addi	sp,sp,-96
    80001f48:	ec86                	sd	ra,88(sp)
    80001f4a:	e8a2                	sd	s0,80(sp)
    80001f4c:	e4a6                	sd	s1,72(sp)
    80001f4e:	e0ca                	sd	s2,64(sp)
    80001f50:	fc4e                	sd	s3,56(sp)
    80001f52:	f852                	sd	s4,48(sp)
    80001f54:	f456                	sd	s5,40(sp)
    80001f56:	f05a                	sd	s6,32(sp)
    80001f58:	ec5e                	sd	s7,24(sp)
    80001f5a:	e862                	sd	s8,16(sp)
    80001f5c:	e466                	sd	s9,8(sp)
    80001f5e:	1080                	addi	s0,sp,96
    80001f60:	8792                	mv	a5,tp
  int id = r_tp();
    80001f62:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f64:	00779c13          	slli	s8,a5,0x7
    80001f68:	00010717          	auipc	a4,0x10
    80001f6c:	9e870713          	addi	a4,a4,-1560 # 80011950 <pid_lock>
    80001f70:	9762                	add	a4,a4,s8
    80001f72:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f76:	00010717          	auipc	a4,0x10
    80001f7a:	9fa70713          	addi	a4,a4,-1542 # 80011970 <cpus+0x8>
    80001f7e:	9c3a                	add	s8,s8,a4
    int nproc = 0;
    80001f80:	4c81                	li	s9,0
      if(p->state == RUNNABLE) {
    80001f82:	4a89                	li	s5,2
        c->proc = p;
    80001f84:	079e                	slli	a5,a5,0x7
    80001f86:	00010b17          	auipc	s6,0x10
    80001f8a:	9cab0b13          	addi	s6,s6,-1590 # 80011950 <pid_lock>
    80001f8e:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f90:	00015a17          	auipc	s4,0x15
    80001f94:	7d8a0a13          	addi	s4,s4,2008 # 80017768 <tickslock>
    80001f98:	a8a1                	j	80001ff0 <scheduler+0xaa>
      release(&p->lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	d18080e7          	jalr	-744(ra) # 80000cb4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fa4:	16848493          	addi	s1,s1,360
    80001fa8:	03448a63          	beq	s1,s4,80001fdc <scheduler+0x96>
      acquire(&p->lock);
    80001fac:	8526                	mv	a0,s1
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	c52080e7          	jalr	-942(ra) # 80000c00 <acquire>
      if(p->state != UNUSED) {
    80001fb6:	4c9c                	lw	a5,24(s1)
    80001fb8:	d3ed                	beqz	a5,80001f9a <scheduler+0x54>
        nproc++;
    80001fba:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80001fbc:	fd579fe3          	bne	a5,s5,80001f9a <scheduler+0x54>
        p->state = RUNNING;
    80001fc0:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001fc4:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80001fc8:	06048593          	addi	a1,s1,96
    80001fcc:	8562                	mv	a0,s8
    80001fce:	00000097          	auipc	ra,0x0
    80001fd2:	60e080e7          	jalr	1550(ra) # 800025dc <swtch>
        c->proc = 0;
    80001fd6:	000b3c23          	sd	zero,24(s6)
    80001fda:	b7c1                	j	80001f9a <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80001fdc:	013aca63          	blt	s5,s3,80001ff0 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fe4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fe8:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fec:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ff0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ff4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff8:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80001ffc:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ffe:	00010497          	auipc	s1,0x10
    80002002:	d6a48493          	addi	s1,s1,-662 # 80011d68 <proc>
        p->state = RUNNING;
    80002006:	4b8d                	li	s7,3
    80002008:	b755                	j	80001fac <scheduler+0x66>

000000008000200a <sched>:
{
    8000200a:	7179                	addi	sp,sp,-48
    8000200c:	f406                	sd	ra,40(sp)
    8000200e:	f022                	sd	s0,32(sp)
    80002010:	ec26                	sd	s1,24(sp)
    80002012:	e84a                	sd	s2,16(sp)
    80002014:	e44e                	sd	s3,8(sp)
    80002016:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002018:	00000097          	auipc	ra,0x0
    8000201c:	9f6080e7          	jalr	-1546(ra) # 80001a0e <myproc>
    80002020:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	b64080e7          	jalr	-1180(ra) # 80000b86 <holding>
    8000202a:	c93d                	beqz	a0,800020a0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000202c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000202e:	2781                	sext.w	a5,a5
    80002030:	079e                	slli	a5,a5,0x7
    80002032:	00010717          	auipc	a4,0x10
    80002036:	91e70713          	addi	a4,a4,-1762 # 80011950 <pid_lock>
    8000203a:	97ba                	add	a5,a5,a4
    8000203c:	0907a703          	lw	a4,144(a5)
    80002040:	4785                	li	a5,1
    80002042:	06f71763          	bne	a4,a5,800020b0 <sched+0xa6>
  if(p->state == RUNNING)
    80002046:	4c98                	lw	a4,24(s1)
    80002048:	478d                	li	a5,3
    8000204a:	06f70b63          	beq	a4,a5,800020c0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000204e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002052:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002054:	efb5                	bnez	a5,800020d0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002056:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002058:	00010917          	auipc	s2,0x10
    8000205c:	8f890913          	addi	s2,s2,-1800 # 80011950 <pid_lock>
    80002060:	2781                	sext.w	a5,a5
    80002062:	079e                	slli	a5,a5,0x7
    80002064:	97ca                	add	a5,a5,s2
    80002066:	0947a983          	lw	s3,148(a5)
    8000206a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000206c:	2781                	sext.w	a5,a5
    8000206e:	079e                	slli	a5,a5,0x7
    80002070:	00010597          	auipc	a1,0x10
    80002074:	90058593          	addi	a1,a1,-1792 # 80011970 <cpus+0x8>
    80002078:	95be                	add	a1,a1,a5
    8000207a:	06048513          	addi	a0,s1,96
    8000207e:	00000097          	auipc	ra,0x0
    80002082:	55e080e7          	jalr	1374(ra) # 800025dc <swtch>
    80002086:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002088:	2781                	sext.w	a5,a5
    8000208a:	079e                	slli	a5,a5,0x7
    8000208c:	993e                	add	s2,s2,a5
    8000208e:	09392a23          	sw	s3,148(s2)
}
    80002092:	70a2                	ld	ra,40(sp)
    80002094:	7402                	ld	s0,32(sp)
    80002096:	64e2                	ld	s1,24(sp)
    80002098:	6942                	ld	s2,16(sp)
    8000209a:	69a2                	ld	s3,8(sp)
    8000209c:	6145                	addi	sp,sp,48
    8000209e:	8082                	ret
    panic("sched p->lock");
    800020a0:	00006517          	auipc	a0,0x6
    800020a4:	0f850513          	addi	a0,a0,248 # 80008198 <digits+0x158>
    800020a8:	ffffe097          	auipc	ra,0xffffe
    800020ac:	49e080e7          	jalr	1182(ra) # 80000546 <panic>
    panic("sched locks");
    800020b0:	00006517          	auipc	a0,0x6
    800020b4:	0f850513          	addi	a0,a0,248 # 800081a8 <digits+0x168>
    800020b8:	ffffe097          	auipc	ra,0xffffe
    800020bc:	48e080e7          	jalr	1166(ra) # 80000546 <panic>
    panic("sched running");
    800020c0:	00006517          	auipc	a0,0x6
    800020c4:	0f850513          	addi	a0,a0,248 # 800081b8 <digits+0x178>
    800020c8:	ffffe097          	auipc	ra,0xffffe
    800020cc:	47e080e7          	jalr	1150(ra) # 80000546 <panic>
    panic("sched interruptible");
    800020d0:	00006517          	auipc	a0,0x6
    800020d4:	0f850513          	addi	a0,a0,248 # 800081c8 <digits+0x188>
    800020d8:	ffffe097          	auipc	ra,0xffffe
    800020dc:	46e080e7          	jalr	1134(ra) # 80000546 <panic>

00000000800020e0 <exit>:
{
    800020e0:	7179                	addi	sp,sp,-48
    800020e2:	f406                	sd	ra,40(sp)
    800020e4:	f022                	sd	s0,32(sp)
    800020e6:	ec26                	sd	s1,24(sp)
    800020e8:	e84a                	sd	s2,16(sp)
    800020ea:	e44e                	sd	s3,8(sp)
    800020ec:	e052                	sd	s4,0(sp)
    800020ee:	1800                	addi	s0,sp,48
    800020f0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	91c080e7          	jalr	-1764(ra) # 80001a0e <myproc>
    800020fa:	89aa                	mv	s3,a0
  if(p == initproc)
    800020fc:	00007797          	auipc	a5,0x7
    80002100:	f1c7b783          	ld	a5,-228(a5) # 80009018 <initproc>
    80002104:	0d050493          	addi	s1,a0,208
    80002108:	15050913          	addi	s2,a0,336
    8000210c:	02a79363          	bne	a5,a0,80002132 <exit+0x52>
    panic("init exiting");
    80002110:	00006517          	auipc	a0,0x6
    80002114:	0d050513          	addi	a0,a0,208 # 800081e0 <digits+0x1a0>
    80002118:	ffffe097          	auipc	ra,0xffffe
    8000211c:	42e080e7          	jalr	1070(ra) # 80000546 <panic>
      fileclose(f);
    80002120:	00002097          	auipc	ra,0x2
    80002124:	460080e7          	jalr	1120(ra) # 80004580 <fileclose>
      p->ofile[fd] = 0;
    80002128:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000212c:	04a1                	addi	s1,s1,8
    8000212e:	01248563          	beq	s1,s2,80002138 <exit+0x58>
    if(p->ofile[fd]){
    80002132:	6088                	ld	a0,0(s1)
    80002134:	f575                	bnez	a0,80002120 <exit+0x40>
    80002136:	bfdd                	j	8000212c <exit+0x4c>
  begin_op();
    80002138:	00002097          	auipc	ra,0x2
    8000213c:	f7a080e7          	jalr	-134(ra) # 800040b2 <begin_op>
  iput(p->cwd);
    80002140:	1509b503          	ld	a0,336(s3)
    80002144:	00001097          	auipc	ra,0x1
    80002148:	75e080e7          	jalr	1886(ra) # 800038a2 <iput>
  end_op();
    8000214c:	00002097          	auipc	ra,0x2
    80002150:	fe4080e7          	jalr	-28(ra) # 80004130 <end_op>
  p->cwd = 0;
    80002154:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002158:	00007497          	auipc	s1,0x7
    8000215c:	ec048493          	addi	s1,s1,-320 # 80009018 <initproc>
    80002160:	6088                	ld	a0,0(s1)
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	a9e080e7          	jalr	-1378(ra) # 80000c00 <acquire>
  wakeup1(initproc);
    8000216a:	6088                	ld	a0,0(s1)
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	762080e7          	jalr	1890(ra) # 800018ce <wakeup1>
  release(&initproc->lock);
    80002174:	6088                	ld	a0,0(s1)
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b3e080e7          	jalr	-1218(ra) # 80000cb4 <release>
  acquire(&p->lock);
    8000217e:	854e                	mv	a0,s3
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	a80080e7          	jalr	-1408(ra) # 80000c00 <acquire>
  struct proc *original_parent = p->parent;
    80002188:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000218c:	854e                	mv	a0,s3
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	b26080e7          	jalr	-1242(ra) # 80000cb4 <release>
  acquire(&original_parent->lock);
    80002196:	8526                	mv	a0,s1
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	a68080e7          	jalr	-1432(ra) # 80000c00 <acquire>
  acquire(&p->lock);
    800021a0:	854e                	mv	a0,s3
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	a5e080e7          	jalr	-1442(ra) # 80000c00 <acquire>
  reparent(p);
    800021aa:	854e                	mv	a0,s3
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	d34080e7          	jalr	-716(ra) # 80001ee0 <reparent>
  wakeup1(original_parent);
    800021b4:	8526                	mv	a0,s1
    800021b6:	fffff097          	auipc	ra,0xfffff
    800021ba:	718080e7          	jalr	1816(ra) # 800018ce <wakeup1>
  p->xstate = status;
    800021be:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021c2:	4791                	li	a5,4
    800021c4:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021c8:	8526                	mv	a0,s1
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	aea080e7          	jalr	-1302(ra) # 80000cb4 <release>
  sched();
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	e38080e7          	jalr	-456(ra) # 8000200a <sched>
  panic("zombie exit");
    800021da:	00006517          	auipc	a0,0x6
    800021de:	01650513          	addi	a0,a0,22 # 800081f0 <digits+0x1b0>
    800021e2:	ffffe097          	auipc	ra,0xffffe
    800021e6:	364080e7          	jalr	868(ra) # 80000546 <panic>

00000000800021ea <yield>:
{
    800021ea:	1101                	addi	sp,sp,-32
    800021ec:	ec06                	sd	ra,24(sp)
    800021ee:	e822                	sd	s0,16(sp)
    800021f0:	e426                	sd	s1,8(sp)
    800021f2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	81a080e7          	jalr	-2022(ra) # 80001a0e <myproc>
    800021fc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	a02080e7          	jalr	-1534(ra) # 80000c00 <acquire>
  p->state = RUNNABLE;
    80002206:	4789                	li	a5,2
    80002208:	cc9c                	sw	a5,24(s1)
  sched();
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	e00080e7          	jalr	-512(ra) # 8000200a <sched>
  release(&p->lock);
    80002212:	8526                	mv	a0,s1
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	aa0080e7          	jalr	-1376(ra) # 80000cb4 <release>
}
    8000221c:	60e2                	ld	ra,24(sp)
    8000221e:	6442                	ld	s0,16(sp)
    80002220:	64a2                	ld	s1,8(sp)
    80002222:	6105                	addi	sp,sp,32
    80002224:	8082                	ret

0000000080002226 <sleep>:
{
    80002226:	7179                	addi	sp,sp,-48
    80002228:	f406                	sd	ra,40(sp)
    8000222a:	f022                	sd	s0,32(sp)
    8000222c:	ec26                	sd	s1,24(sp)
    8000222e:	e84a                	sd	s2,16(sp)
    80002230:	e44e                	sd	s3,8(sp)
    80002232:	1800                	addi	s0,sp,48
    80002234:	89aa                	mv	s3,a0
    80002236:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	7d6080e7          	jalr	2006(ra) # 80001a0e <myproc>
    80002240:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002242:	05250663          	beq	a0,s2,8000228e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	9ba080e7          	jalr	-1606(ra) # 80000c00 <acquire>
    release(lk);
    8000224e:	854a                	mv	a0,s2
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	a64080e7          	jalr	-1436(ra) # 80000cb4 <release>
  p->chan = chan;
    80002258:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000225c:	4785                	li	a5,1
    8000225e:	cc9c                	sw	a5,24(s1)
  sched();
    80002260:	00000097          	auipc	ra,0x0
    80002264:	daa080e7          	jalr	-598(ra) # 8000200a <sched>
  p->chan = 0;
    80002268:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	a46080e7          	jalr	-1466(ra) # 80000cb4 <release>
    acquire(lk);
    80002276:	854a                	mv	a0,s2
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	988080e7          	jalr	-1656(ra) # 80000c00 <acquire>
}
    80002280:	70a2                	ld	ra,40(sp)
    80002282:	7402                	ld	s0,32(sp)
    80002284:	64e2                	ld	s1,24(sp)
    80002286:	6942                	ld	s2,16(sp)
    80002288:	69a2                	ld	s3,8(sp)
    8000228a:	6145                	addi	sp,sp,48
    8000228c:	8082                	ret
  p->chan = chan;
    8000228e:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002292:	4785                	li	a5,1
    80002294:	cd1c                	sw	a5,24(a0)
  sched();
    80002296:	00000097          	auipc	ra,0x0
    8000229a:	d74080e7          	jalr	-652(ra) # 8000200a <sched>
  p->chan = 0;
    8000229e:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022a2:	bff9                	j	80002280 <sleep+0x5a>

00000000800022a4 <wait>:
{
    800022a4:	715d                	addi	sp,sp,-80
    800022a6:	e486                	sd	ra,72(sp)
    800022a8:	e0a2                	sd	s0,64(sp)
    800022aa:	fc26                	sd	s1,56(sp)
    800022ac:	f84a                	sd	s2,48(sp)
    800022ae:	f44e                	sd	s3,40(sp)
    800022b0:	f052                	sd	s4,32(sp)
    800022b2:	ec56                	sd	s5,24(sp)
    800022b4:	e85a                	sd	s6,16(sp)
    800022b6:	e45e                	sd	s7,8(sp)
    800022b8:	0880                	addi	s0,sp,80
    800022ba:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	752080e7          	jalr	1874(ra) # 80001a0e <myproc>
    800022c4:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	93a080e7          	jalr	-1734(ra) # 80000c00 <acquire>
    havekids = 0;
    800022ce:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022d0:	4a11                	li	s4,4
        havekids = 1;
    800022d2:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800022d4:	00015997          	auipc	s3,0x15
    800022d8:	49498993          	addi	s3,s3,1172 # 80017768 <tickslock>
    havekids = 0;
    800022dc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022de:	00010497          	auipc	s1,0x10
    800022e2:	a8a48493          	addi	s1,s1,-1398 # 80011d68 <proc>
    800022e6:	a08d                	j	80002348 <wait+0xa4>
          pid = np->pid;
    800022e8:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022ec:	000b0e63          	beqz	s6,80002308 <wait+0x64>
    800022f0:	4691                	li	a3,4
    800022f2:	03448613          	addi	a2,s1,52
    800022f6:	85da                	mv	a1,s6
    800022f8:	05093503          	ld	a0,80(s2)
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	408080e7          	jalr	1032(ra) # 80001704 <copyout>
    80002304:	02054263          	bltz	a0,80002328 <wait+0x84>
          freeproc(np);
    80002308:	8526                	mv	a0,s1
    8000230a:	00000097          	auipc	ra,0x0
    8000230e:	8b6080e7          	jalr	-1866(ra) # 80001bc0 <freeproc>
          release(&np->lock);
    80002312:	8526                	mv	a0,s1
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	9a0080e7          	jalr	-1632(ra) # 80000cb4 <release>
          release(&p->lock);
    8000231c:	854a                	mv	a0,s2
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	996080e7          	jalr	-1642(ra) # 80000cb4 <release>
          return pid;
    80002326:	a8a9                	j	80002380 <wait+0xdc>
            release(&np->lock);
    80002328:	8526                	mv	a0,s1
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	98a080e7          	jalr	-1654(ra) # 80000cb4 <release>
            release(&p->lock);
    80002332:	854a                	mv	a0,s2
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	980080e7          	jalr	-1664(ra) # 80000cb4 <release>
            return -1;
    8000233c:	59fd                	li	s3,-1
    8000233e:	a089                	j	80002380 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002340:	16848493          	addi	s1,s1,360
    80002344:	03348463          	beq	s1,s3,8000236c <wait+0xc8>
      if(np->parent == p){
    80002348:	709c                	ld	a5,32(s1)
    8000234a:	ff279be3          	bne	a5,s2,80002340 <wait+0x9c>
        acquire(&np->lock);
    8000234e:	8526                	mv	a0,s1
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	8b0080e7          	jalr	-1872(ra) # 80000c00 <acquire>
        if(np->state == ZOMBIE){
    80002358:	4c9c                	lw	a5,24(s1)
    8000235a:	f94787e3          	beq	a5,s4,800022e8 <wait+0x44>
        release(&np->lock);
    8000235e:	8526                	mv	a0,s1
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	954080e7          	jalr	-1708(ra) # 80000cb4 <release>
        havekids = 1;
    80002368:	8756                	mv	a4,s5
    8000236a:	bfd9                	j	80002340 <wait+0x9c>
    if(!havekids || p->killed){
    8000236c:	c701                	beqz	a4,80002374 <wait+0xd0>
    8000236e:	03092783          	lw	a5,48(s2)
    80002372:	c39d                	beqz	a5,80002398 <wait+0xf4>
      release(&p->lock);
    80002374:	854a                	mv	a0,s2
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	93e080e7          	jalr	-1730(ra) # 80000cb4 <release>
      return -1;
    8000237e:	59fd                	li	s3,-1
}
    80002380:	854e                	mv	a0,s3
    80002382:	60a6                	ld	ra,72(sp)
    80002384:	6406                	ld	s0,64(sp)
    80002386:	74e2                	ld	s1,56(sp)
    80002388:	7942                	ld	s2,48(sp)
    8000238a:	79a2                	ld	s3,40(sp)
    8000238c:	7a02                	ld	s4,32(sp)
    8000238e:	6ae2                	ld	s5,24(sp)
    80002390:	6b42                	ld	s6,16(sp)
    80002392:	6ba2                	ld	s7,8(sp)
    80002394:	6161                	addi	sp,sp,80
    80002396:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002398:	85ca                	mv	a1,s2
    8000239a:	854a                	mv	a0,s2
    8000239c:	00000097          	auipc	ra,0x0
    800023a0:	e8a080e7          	jalr	-374(ra) # 80002226 <sleep>
    havekids = 0;
    800023a4:	bf25                	j	800022dc <wait+0x38>

00000000800023a6 <wakeup>:
{
    800023a6:	7139                	addi	sp,sp,-64
    800023a8:	fc06                	sd	ra,56(sp)
    800023aa:	f822                	sd	s0,48(sp)
    800023ac:	f426                	sd	s1,40(sp)
    800023ae:	f04a                	sd	s2,32(sp)
    800023b0:	ec4e                	sd	s3,24(sp)
    800023b2:	e852                	sd	s4,16(sp)
    800023b4:	e456                	sd	s5,8(sp)
    800023b6:	0080                	addi	s0,sp,64
    800023b8:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ba:	00010497          	auipc	s1,0x10
    800023be:	9ae48493          	addi	s1,s1,-1618 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023c2:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023c4:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023c6:	00015917          	auipc	s2,0x15
    800023ca:	3a290913          	addi	s2,s2,930 # 80017768 <tickslock>
    800023ce:	a811                	j	800023e2 <wakeup+0x3c>
    release(&p->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8e2080e7          	jalr	-1822(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023da:	16848493          	addi	s1,s1,360
    800023de:	03248063          	beq	s1,s2,800023fe <wakeup+0x58>
    acquire(&p->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	81c080e7          	jalr	-2020(ra) # 80000c00 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023ec:	4c9c                	lw	a5,24(s1)
    800023ee:	ff3791e3          	bne	a5,s3,800023d0 <wakeup+0x2a>
    800023f2:	749c                	ld	a5,40(s1)
    800023f4:	fd479ee3          	bne	a5,s4,800023d0 <wakeup+0x2a>
      p->state = RUNNABLE;
    800023f8:	0154ac23          	sw	s5,24(s1)
    800023fc:	bfd1                	j	800023d0 <wakeup+0x2a>
}
    800023fe:	70e2                	ld	ra,56(sp)
    80002400:	7442                	ld	s0,48(sp)
    80002402:	74a2                	ld	s1,40(sp)
    80002404:	7902                	ld	s2,32(sp)
    80002406:	69e2                	ld	s3,24(sp)
    80002408:	6a42                	ld	s4,16(sp)
    8000240a:	6aa2                	ld	s5,8(sp)
    8000240c:	6121                	addi	sp,sp,64
    8000240e:	8082                	ret

0000000080002410 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002410:	7179                	addi	sp,sp,-48
    80002412:	f406                	sd	ra,40(sp)
    80002414:	f022                	sd	s0,32(sp)
    80002416:	ec26                	sd	s1,24(sp)
    80002418:	e84a                	sd	s2,16(sp)
    8000241a:	e44e                	sd	s3,8(sp)
    8000241c:	1800                	addi	s0,sp,48
    8000241e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002420:	00010497          	auipc	s1,0x10
    80002424:	94848493          	addi	s1,s1,-1720 # 80011d68 <proc>
    80002428:	00015997          	auipc	s3,0x15
    8000242c:	34098993          	addi	s3,s3,832 # 80017768 <tickslock>
    acquire(&p->lock);
    80002430:	8526                	mv	a0,s1
    80002432:	ffffe097          	auipc	ra,0xffffe
    80002436:	7ce080e7          	jalr	1998(ra) # 80000c00 <acquire>
    if(p->pid == pid){
    8000243a:	5c9c                	lw	a5,56(s1)
    8000243c:	01278d63          	beq	a5,s2,80002456 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	872080e7          	jalr	-1934(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000244a:	16848493          	addi	s1,s1,360
    8000244e:	ff3491e3          	bne	s1,s3,80002430 <kill+0x20>
  }
  return -1;
    80002452:	557d                	li	a0,-1
    80002454:	a821                	j	8000246c <kill+0x5c>
      p->killed = 1;
    80002456:	4785                	li	a5,1
    80002458:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000245a:	4c98                	lw	a4,24(s1)
    8000245c:	00f70f63          	beq	a4,a5,8000247a <kill+0x6a>
      release(&p->lock);
    80002460:	8526                	mv	a0,s1
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	852080e7          	jalr	-1966(ra) # 80000cb4 <release>
      return 0;
    8000246a:	4501                	li	a0,0
}
    8000246c:	70a2                	ld	ra,40(sp)
    8000246e:	7402                	ld	s0,32(sp)
    80002470:	64e2                	ld	s1,24(sp)
    80002472:	6942                	ld	s2,16(sp)
    80002474:	69a2                	ld	s3,8(sp)
    80002476:	6145                	addi	sp,sp,48
    80002478:	8082                	ret
        p->state = RUNNABLE;
    8000247a:	4789                	li	a5,2
    8000247c:	cc9c                	sw	a5,24(s1)
    8000247e:	b7cd                	j	80002460 <kill+0x50>

0000000080002480 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002480:	7179                	addi	sp,sp,-48
    80002482:	f406                	sd	ra,40(sp)
    80002484:	f022                	sd	s0,32(sp)
    80002486:	ec26                	sd	s1,24(sp)
    80002488:	e84a                	sd	s2,16(sp)
    8000248a:	e44e                	sd	s3,8(sp)
    8000248c:	e052                	sd	s4,0(sp)
    8000248e:	1800                	addi	s0,sp,48
    80002490:	84aa                	mv	s1,a0
    80002492:	892e                	mv	s2,a1
    80002494:	89b2                	mv	s3,a2
    80002496:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	576080e7          	jalr	1398(ra) # 80001a0e <myproc>
  if(user_dst){
    800024a0:	c08d                	beqz	s1,800024c2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024a2:	86d2                	mv	a3,s4
    800024a4:	864e                	mv	a2,s3
    800024a6:	85ca                	mv	a1,s2
    800024a8:	6928                	ld	a0,80(a0)
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	25a080e7          	jalr	602(ra) # 80001704 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024b2:	70a2                	ld	ra,40(sp)
    800024b4:	7402                	ld	s0,32(sp)
    800024b6:	64e2                	ld	s1,24(sp)
    800024b8:	6942                	ld	s2,16(sp)
    800024ba:	69a2                	ld	s3,8(sp)
    800024bc:	6a02                	ld	s4,0(sp)
    800024be:	6145                	addi	sp,sp,48
    800024c0:	8082                	ret
    memmove((char *)dst, src, len);
    800024c2:	000a061b          	sext.w	a2,s4
    800024c6:	85ce                	mv	a1,s3
    800024c8:	854a                	mv	a0,s2
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	88e080e7          	jalr	-1906(ra) # 80000d58 <memmove>
    return 0;
    800024d2:	8526                	mv	a0,s1
    800024d4:	bff9                	j	800024b2 <either_copyout+0x32>

00000000800024d6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d6:	7179                	addi	sp,sp,-48
    800024d8:	f406                	sd	ra,40(sp)
    800024da:	f022                	sd	s0,32(sp)
    800024dc:	ec26                	sd	s1,24(sp)
    800024de:	e84a                	sd	s2,16(sp)
    800024e0:	e44e                	sd	s3,8(sp)
    800024e2:	e052                	sd	s4,0(sp)
    800024e4:	1800                	addi	s0,sp,48
    800024e6:	892a                	mv	s2,a0
    800024e8:	84ae                	mv	s1,a1
    800024ea:	89b2                	mv	s3,a2
    800024ec:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	520080e7          	jalr	1312(ra) # 80001a0e <myproc>
  if(user_src){
    800024f6:	c08d                	beqz	s1,80002518 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024f8:	86d2                	mv	a3,s4
    800024fa:	864e                	mv	a2,s3
    800024fc:	85ca                	mv	a1,s2
    800024fe:	6928                	ld	a0,80(a0)
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	290080e7          	jalr	656(ra) # 80001790 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002508:	70a2                	ld	ra,40(sp)
    8000250a:	7402                	ld	s0,32(sp)
    8000250c:	64e2                	ld	s1,24(sp)
    8000250e:	6942                	ld	s2,16(sp)
    80002510:	69a2                	ld	s3,8(sp)
    80002512:	6a02                	ld	s4,0(sp)
    80002514:	6145                	addi	sp,sp,48
    80002516:	8082                	ret
    memmove(dst, (char*)src, len);
    80002518:	000a061b          	sext.w	a2,s4
    8000251c:	85ce                	mv	a1,s3
    8000251e:	854a                	mv	a0,s2
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	838080e7          	jalr	-1992(ra) # 80000d58 <memmove>
    return 0;
    80002528:	8526                	mv	a0,s1
    8000252a:	bff9                	j	80002508 <either_copyin+0x32>

000000008000252c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000252c:	715d                	addi	sp,sp,-80
    8000252e:	e486                	sd	ra,72(sp)
    80002530:	e0a2                	sd	s0,64(sp)
    80002532:	fc26                	sd	s1,56(sp)
    80002534:	f84a                	sd	s2,48(sp)
    80002536:	f44e                	sd	s3,40(sp)
    80002538:	f052                	sd	s4,32(sp)
    8000253a:	ec56                	sd	s5,24(sp)
    8000253c:	e85a                	sd	s6,16(sp)
    8000253e:	e45e                	sd	s7,8(sp)
    80002540:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002542:	00006517          	auipc	a0,0x6
    80002546:	b8650513          	addi	a0,a0,-1146 # 800080c8 <digits+0x88>
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	046080e7          	jalr	70(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002552:	00010497          	auipc	s1,0x10
    80002556:	96e48493          	addi	s1,s1,-1682 # 80011ec0 <proc+0x158>
    8000255a:	00015917          	auipc	s2,0x15
    8000255e:	36690913          	addi	s2,s2,870 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002562:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002564:	00006997          	auipc	s3,0x6
    80002568:	c9c98993          	addi	s3,s3,-868 # 80008200 <digits+0x1c0>
    printf("%d %s %s", p->pid, state, p->name);
    8000256c:	00006a97          	auipc	s5,0x6
    80002570:	c9ca8a93          	addi	s5,s5,-868 # 80008208 <digits+0x1c8>
    printf("\n");
    80002574:	00006a17          	auipc	s4,0x6
    80002578:	b54a0a13          	addi	s4,s4,-1196 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000257c:	00006b97          	auipc	s7,0x6
    80002580:	cc4b8b93          	addi	s7,s7,-828 # 80008240 <states.0>
    80002584:	a00d                	j	800025a6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002586:	ee06a583          	lw	a1,-288(a3)
    8000258a:	8556                	mv	a0,s5
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	004080e7          	jalr	4(ra) # 80000590 <printf>
    printf("\n");
    80002594:	8552                	mv	a0,s4
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	ffa080e7          	jalr	-6(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000259e:	16848493          	addi	s1,s1,360
    800025a2:	03248263          	beq	s1,s2,800025c6 <procdump+0x9a>
    if(p->state == UNUSED)
    800025a6:	86a6                	mv	a3,s1
    800025a8:	ec04a783          	lw	a5,-320(s1)
    800025ac:	dbed                	beqz	a5,8000259e <procdump+0x72>
      state = "???";
    800025ae:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b0:	fcfb6be3          	bltu	s6,a5,80002586 <procdump+0x5a>
    800025b4:	02079713          	slli	a4,a5,0x20
    800025b8:	01d75793          	srli	a5,a4,0x1d
    800025bc:	97de                	add	a5,a5,s7
    800025be:	6390                	ld	a2,0(a5)
    800025c0:	f279                	bnez	a2,80002586 <procdump+0x5a>
      state = "???";
    800025c2:	864e                	mv	a2,s3
    800025c4:	b7c9                	j	80002586 <procdump+0x5a>
  }
}
    800025c6:	60a6                	ld	ra,72(sp)
    800025c8:	6406                	ld	s0,64(sp)
    800025ca:	74e2                	ld	s1,56(sp)
    800025cc:	7942                	ld	s2,48(sp)
    800025ce:	79a2                	ld	s3,40(sp)
    800025d0:	7a02                	ld	s4,32(sp)
    800025d2:	6ae2                	ld	s5,24(sp)
    800025d4:	6b42                	ld	s6,16(sp)
    800025d6:	6ba2                	ld	s7,8(sp)
    800025d8:	6161                	addi	sp,sp,80
    800025da:	8082                	ret

00000000800025dc <swtch>:
    800025dc:	00153023          	sd	ra,0(a0)
    800025e0:	00253423          	sd	sp,8(a0)
    800025e4:	e900                	sd	s0,16(a0)
    800025e6:	ed04                	sd	s1,24(a0)
    800025e8:	03253023          	sd	s2,32(a0)
    800025ec:	03353423          	sd	s3,40(a0)
    800025f0:	03453823          	sd	s4,48(a0)
    800025f4:	03553c23          	sd	s5,56(a0)
    800025f8:	05653023          	sd	s6,64(a0)
    800025fc:	05753423          	sd	s7,72(a0)
    80002600:	05853823          	sd	s8,80(a0)
    80002604:	05953c23          	sd	s9,88(a0)
    80002608:	07a53023          	sd	s10,96(a0)
    8000260c:	07b53423          	sd	s11,104(a0)
    80002610:	0005b083          	ld	ra,0(a1)
    80002614:	0085b103          	ld	sp,8(a1)
    80002618:	6980                	ld	s0,16(a1)
    8000261a:	6d84                	ld	s1,24(a1)
    8000261c:	0205b903          	ld	s2,32(a1)
    80002620:	0285b983          	ld	s3,40(a1)
    80002624:	0305ba03          	ld	s4,48(a1)
    80002628:	0385ba83          	ld	s5,56(a1)
    8000262c:	0405bb03          	ld	s6,64(a1)
    80002630:	0485bb83          	ld	s7,72(a1)
    80002634:	0505bc03          	ld	s8,80(a1)
    80002638:	0585bc83          	ld	s9,88(a1)
    8000263c:	0605bd03          	ld	s10,96(a1)
    80002640:	0685bd83          	ld	s11,104(a1)
    80002644:	8082                	ret

0000000080002646 <trapinit>:

int isValid(struct proc *p,uint64 va);

void
trapinit(void)
{
    80002646:	1141                	addi	sp,sp,-16
    80002648:	e406                	sd	ra,8(sp)
    8000264a:	e022                	sd	s0,0(sp)
    8000264c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000264e:	00006597          	auipc	a1,0x6
    80002652:	c1a58593          	addi	a1,a1,-998 # 80008268 <states.0+0x28>
    80002656:	00015517          	auipc	a0,0x15
    8000265a:	11250513          	addi	a0,a0,274 # 80017768 <tickslock>
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	512080e7          	jalr	1298(ra) # 80000b70 <initlock>
}
    80002666:	60a2                	ld	ra,8(sp)
    80002668:	6402                	ld	s0,0(sp)
    8000266a:	0141                	addi	sp,sp,16
    8000266c:	8082                	ret

000000008000266e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000266e:	1141                	addi	sp,sp,-16
    80002670:	e422                	sd	s0,8(sp)
    80002672:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002674:	00003797          	auipc	a5,0x3
    80002678:	56c78793          	addi	a5,a5,1388 # 80005be0 <kernelvec>
    8000267c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002680:	6422                	ld	s0,8(sp)
    80002682:	0141                	addi	sp,sp,16
    80002684:	8082                	ret

0000000080002686 <isValid>:
    yield();

  usertrapret();
}
int isValid(struct proc *p,uint64 va)
{
    80002686:	1141                	addi	sp,sp,-16
    80002688:	e422                	sd	s0,8(sp)
    8000268a:	0800                	addi	s0,sp,16
 uint64 stackbase = PGROUNDUP(p->trapframe->sp);
 if(va>p->sz||va<stackbase)
    8000268c:	653c                	ld	a5,72(a0)
    8000268e:	02b7e163          	bltu	a5,a1,800026b0 <isValid+0x2a>
 uint64 stackbase = PGROUNDUP(p->trapframe->sp);
    80002692:	6d3c                	ld	a5,88(a0)
    80002694:	7b88                	ld	a0,48(a5)
    80002696:	6785                	lui	a5,0x1
    80002698:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000269a:	953e                	add	a0,a0,a5
    8000269c:	77fd                	lui	a5,0xfffff
    8000269e:	8d7d                	and	a0,a0,a5
 if(va>p->sz||va<stackbase)
    800026a0:	00a5b533          	sltu	a0,a1,a0
    800026a4:	00154513          	xori	a0,a0,1
   return 0;
    800026a8:	2501                	sext.w	a0,a0
 return 1;
}
    800026aa:	6422                	ld	s0,8(sp)
    800026ac:	0141                	addi	sp,sp,16
    800026ae:	8082                	ret
   return 0;
    800026b0:	4501                	li	a0,0
    800026b2:	bfe5                	j	800026aa <isValid+0x24>

00000000800026b4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026b4:	1141                	addi	sp,sp,-16
    800026b6:	e406                	sd	ra,8(sp)
    800026b8:	e022                	sd	s0,0(sp)
    800026ba:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026bc:	fffff097          	auipc	ra,0xfffff
    800026c0:	352080e7          	jalr	850(ra) # 80001a0e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026c4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026c8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ca:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026ce:	00005697          	auipc	a3,0x5
    800026d2:	93268693          	addi	a3,a3,-1742 # 80007000 <_trampoline>
    800026d6:	00005717          	auipc	a4,0x5
    800026da:	92a70713          	addi	a4,a4,-1750 # 80007000 <_trampoline>
    800026de:	8f15                	sub	a4,a4,a3
    800026e0:	040007b7          	lui	a5,0x4000
    800026e4:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800026e6:	07b2                	slli	a5,a5,0xc
    800026e8:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ea:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026ee:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026f0:	18002673          	csrr	a2,satp
    800026f4:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026f6:	6d30                	ld	a2,88(a0)
    800026f8:	6138                	ld	a4,64(a0)
    800026fa:	6585                	lui	a1,0x1
    800026fc:	972e                	add	a4,a4,a1
    800026fe:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002700:	6d38                	ld	a4,88(a0)
    80002702:	00000617          	auipc	a2,0x0
    80002706:	13860613          	addi	a2,a2,312 # 8000283a <usertrap>
    8000270a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000270c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000270e:	8612                	mv	a2,tp
    80002710:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002712:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002716:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000271a:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002722:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002724:	6f18                	ld	a4,24(a4)
    80002726:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000272a:	692c                	ld	a1,80(a0)
    8000272c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000272e:	00005717          	auipc	a4,0x5
    80002732:	96270713          	addi	a4,a4,-1694 # 80007090 <userret>
    80002736:	8f15                	sub	a4,a4,a3
    80002738:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000273a:	577d                	li	a4,-1
    8000273c:	177e                	slli	a4,a4,0x3f
    8000273e:	8dd9                	or	a1,a1,a4
    80002740:	02000537          	lui	a0,0x2000
    80002744:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002746:	0536                	slli	a0,a0,0xd
    80002748:	9782                	jalr	a5
}
    8000274a:	60a2                	ld	ra,8(sp)
    8000274c:	6402                	ld	s0,0(sp)
    8000274e:	0141                	addi	sp,sp,16
    80002750:	8082                	ret

0000000080002752 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002752:	1101                	addi	sp,sp,-32
    80002754:	ec06                	sd	ra,24(sp)
    80002756:	e822                	sd	s0,16(sp)
    80002758:	e426                	sd	s1,8(sp)
    8000275a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000275c:	00015497          	auipc	s1,0x15
    80002760:	00c48493          	addi	s1,s1,12 # 80017768 <tickslock>
    80002764:	8526                	mv	a0,s1
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	49a080e7          	jalr	1178(ra) # 80000c00 <acquire>
  ticks++;
    8000276e:	00007517          	auipc	a0,0x7
    80002772:	8b250513          	addi	a0,a0,-1870 # 80009020 <ticks>
    80002776:	411c                	lw	a5,0(a0)
    80002778:	2785                	addiw	a5,a5,1
    8000277a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000277c:	00000097          	auipc	ra,0x0
    80002780:	c2a080e7          	jalr	-982(ra) # 800023a6 <wakeup>
  release(&tickslock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	52e080e7          	jalr	1326(ra) # 80000cb4 <release>
}
    8000278e:	60e2                	ld	ra,24(sp)
    80002790:	6442                	ld	s0,16(sp)
    80002792:	64a2                	ld	s1,8(sp)
    80002794:	6105                	addi	sp,sp,32
    80002796:	8082                	ret

0000000080002798 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002798:	1101                	addi	sp,sp,-32
    8000279a:	ec06                	sd	ra,24(sp)
    8000279c:	e822                	sd	s0,16(sp)
    8000279e:	e426                	sd	s1,8(sp)
    800027a0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027a2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027a6:	00074d63          	bltz	a4,800027c0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027aa:	57fd                	li	a5,-1
    800027ac:	17fe                	slli	a5,a5,0x3f
    800027ae:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027b0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027b2:	06f70363          	beq	a4,a5,80002818 <devintr+0x80>
  }
}
    800027b6:	60e2                	ld	ra,24(sp)
    800027b8:	6442                	ld	s0,16(sp)
    800027ba:	64a2                	ld	s1,8(sp)
    800027bc:	6105                	addi	sp,sp,32
    800027be:	8082                	ret
     (scause & 0xff) == 9){
    800027c0:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800027c4:	46a5                	li	a3,9
    800027c6:	fed792e3          	bne	a5,a3,800027aa <devintr+0x12>
    int irq = plic_claim();
    800027ca:	00003097          	auipc	ra,0x3
    800027ce:	51e080e7          	jalr	1310(ra) # 80005ce8 <plic_claim>
    800027d2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027d4:	47a9                	li	a5,10
    800027d6:	02f50763          	beq	a0,a5,80002804 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027da:	4785                	li	a5,1
    800027dc:	02f50963          	beq	a0,a5,8000280e <devintr+0x76>
    return 1;
    800027e0:	4505                	li	a0,1
    } else if(irq){
    800027e2:	d8f1                	beqz	s1,800027b6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027e4:	85a6                	mv	a1,s1
    800027e6:	00006517          	auipc	a0,0x6
    800027ea:	a8a50513          	addi	a0,a0,-1398 # 80008270 <states.0+0x30>
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	da2080e7          	jalr	-606(ra) # 80000590 <printf>
      plic_complete(irq);
    800027f6:	8526                	mv	a0,s1
    800027f8:	00003097          	auipc	ra,0x3
    800027fc:	514080e7          	jalr	1300(ra) # 80005d0c <plic_complete>
    return 1;
    80002800:	4505                	li	a0,1
    80002802:	bf55                	j	800027b6 <devintr+0x1e>
      uartintr();
    80002804:	ffffe097          	auipc	ra,0xffffe
    80002808:	1be080e7          	jalr	446(ra) # 800009c2 <uartintr>
    8000280c:	b7ed                	j	800027f6 <devintr+0x5e>
      virtio_disk_intr();
    8000280e:	00004097          	auipc	ra,0x4
    80002812:	972080e7          	jalr	-1678(ra) # 80006180 <virtio_disk_intr>
    80002816:	b7c5                	j	800027f6 <devintr+0x5e>
    if(cpuid() == 0){
    80002818:	fffff097          	auipc	ra,0xfffff
    8000281c:	1ca080e7          	jalr	458(ra) # 800019e2 <cpuid>
    80002820:	c901                	beqz	a0,80002830 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002822:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002826:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002828:	14479073          	csrw	sip,a5
    return 2;
    8000282c:	4509                	li	a0,2
    8000282e:	b761                	j	800027b6 <devintr+0x1e>
      clockintr();
    80002830:	00000097          	auipc	ra,0x0
    80002834:	f22080e7          	jalr	-222(ra) # 80002752 <clockintr>
    80002838:	b7ed                	j	80002822 <devintr+0x8a>

000000008000283a <usertrap>:
{
    8000283a:	7179                	addi	sp,sp,-48
    8000283c:	f406                	sd	ra,40(sp)
    8000283e:	f022                	sd	s0,32(sp)
    80002840:	ec26                	sd	s1,24(sp)
    80002842:	e84a                	sd	s2,16(sp)
    80002844:	e44e                	sd	s3,8(sp)
    80002846:	e052                	sd	s4,0(sp)
    80002848:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000284a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000284e:	1007f793          	andi	a5,a5,256
    80002852:	e7a5                	bnez	a5,800028ba <usertrap+0x80>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002854:	00003797          	auipc	a5,0x3
    80002858:	38c78793          	addi	a5,a5,908 # 80005be0 <kernelvec>
    8000285c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002860:	fffff097          	auipc	ra,0xfffff
    80002864:	1ae080e7          	jalr	430(ra) # 80001a0e <myproc>
    80002868:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000286a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000286c:	14102773          	csrr	a4,sepc
    80002870:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002872:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002876:	47a1                	li	a5,8
    80002878:	04f71f63          	bne	a4,a5,800028d6 <usertrap+0x9c>
    if(p->killed)
    8000287c:	591c                	lw	a5,48(a0)
    8000287e:	e7b1                	bnez	a5,800028ca <usertrap+0x90>
    p->trapframe->epc += 4;
    80002880:	6cb8                	ld	a4,88(s1)
    80002882:	6f1c                	ld	a5,24(a4)
    80002884:	0791                	addi	a5,a5,4
    80002886:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002888:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000288c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002890:	10079073          	csrw	sstatus,a5
    syscall();
    80002894:	00000097          	auipc	ra,0x0
    80002898:	356080e7          	jalr	854(ra) # 80002bea <syscall>
  if(p->killed)
    8000289c:	589c                	lw	a5,48(s1)
    8000289e:	10079363          	bnez	a5,800029a4 <usertrap+0x16a>
  usertrapret();
    800028a2:	00000097          	auipc	ra,0x0
    800028a6:	e12080e7          	jalr	-494(ra) # 800026b4 <usertrapret>
}
    800028aa:	70a2                	ld	ra,40(sp)
    800028ac:	7402                	ld	s0,32(sp)
    800028ae:	64e2                	ld	s1,24(sp)
    800028b0:	6942                	ld	s2,16(sp)
    800028b2:	69a2                	ld	s3,8(sp)
    800028b4:	6a02                	ld	s4,0(sp)
    800028b6:	6145                	addi	sp,sp,48
    800028b8:	8082                	ret
    panic("usertrap: not from user mode");
    800028ba:	00006517          	auipc	a0,0x6
    800028be:	9d650513          	addi	a0,a0,-1578 # 80008290 <states.0+0x50>
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	c84080e7          	jalr	-892(ra) # 80000546 <panic>
      exit(-1);
    800028ca:	557d                	li	a0,-1
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	814080e7          	jalr	-2028(ra) # 800020e0 <exit>
    800028d4:	b775                	j	80002880 <usertrap+0x46>
  } else if((which_dev = devintr()) != 0){
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	ec2080e7          	jalr	-318(ra) # 80002798 <devintr>
    800028de:	892a                	mv	s2,a0
    800028e0:	ed5d                	bnez	a0,8000299e <usertrap+0x164>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e2:	14202773          	csrr	a4,scause
  } else if(r_scause() == 13 || r_scause() == 15){
    800028e6:	47b5                	li	a5,13
    800028e8:	00f70763          	beq	a4,a5,800028f6 <usertrap+0xbc>
    800028ec:	14202773          	csrr	a4,scause
    800028f0:	47bd                	li	a5,15
    800028f2:	06f71063          	bne	a4,a5,80002952 <usertrap+0x118>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028f6:	14302a73          	csrr	s4,stval
    uint64 ka = (uint64)kalloc();
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	216080e7          	jalr	534(ra) # 80000b10 <kalloc>
    80002902:	89aa                	mv	s3,a0
    if(ka == 0) 
    80002904:	cd35                	beqz	a0,80002980 <usertrap+0x146>
    else if(isValid(p,va) == 0){
    80002906:	85d2                	mv	a1,s4
    80002908:	8526                	mv	a0,s1
    8000290a:	00000097          	auipc	ra,0x0
    8000290e:	d7c080e7          	jalr	-644(ra) # 80002686 <isValid>
    80002912:	e519                	bnez	a0,80002920 <usertrap+0xe6>
      kfree((void*)ka);
    80002914:	854e                	mv	a0,s3
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	0fc080e7          	jalr	252(ra) # 80000a12 <kfree>
      p->killed = 1;
    8000291e:	a08d                	j	80002980 <usertrap+0x146>
    memset((void*)ka,0,PGSIZE);
    80002920:	6605                	lui	a2,0x1
    80002922:	4581                	li	a1,0
    80002924:	854e                	mv	a0,s3
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	3d6080e7          	jalr	982(ra) # 80000cfc <memset>
    if(mappages(p->pagetable,va,PGSIZE,ka,PTE_U|PTE_R|PTE_W) != 0)
    8000292e:	4759                	li	a4,22
    80002930:	86ce                	mv	a3,s3
    80002932:	6605                	lui	a2,0x1
    80002934:	75fd                	lui	a1,0xfffff
    80002936:	00ba75b3          	and	a1,s4,a1
    8000293a:	68a8                	ld	a0,80(s1)
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	7ac080e7          	jalr	1964(ra) # 800010e8 <mappages>
    80002944:	dd21                	beqz	a0,8000289c <usertrap+0x62>
      kfree((void*)ka);
    80002946:	854e                	mv	a0,s3
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	0ca080e7          	jalr	202(ra) # 80000a12 <kfree>
      p->killed = 1;
    80002950:	a805                	j	80002980 <usertrap+0x146>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002952:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002956:	5c90                	lw	a2,56(s1)
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	95850513          	addi	a0,a0,-1704 # 800082b0 <states.0+0x70>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	c30080e7          	jalr	-976(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002968:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000296c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002970:	00006517          	auipc	a0,0x6
    80002974:	97050513          	addi	a0,a0,-1680 # 800082e0 <states.0+0xa0>
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	c18080e7          	jalr	-1000(ra) # 80000590 <printf>
      p->killed = 1;
    80002980:	4785                	li	a5,1
    80002982:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002984:	557d                	li	a0,-1
    80002986:	fffff097          	auipc	ra,0xfffff
    8000298a:	75a080e7          	jalr	1882(ra) # 800020e0 <exit>
  if(which_dev == 2)
    8000298e:	4789                	li	a5,2
    80002990:	f0f919e3          	bne	s2,a5,800028a2 <usertrap+0x68>
    yield();
    80002994:	00000097          	auipc	ra,0x0
    80002998:	856080e7          	jalr	-1962(ra) # 800021ea <yield>
    8000299c:	b719                	j	800028a2 <usertrap+0x68>
  if(p->killed)
    8000299e:	589c                	lw	a5,48(s1)
    800029a0:	d7fd                	beqz	a5,8000298e <usertrap+0x154>
    800029a2:	b7cd                	j	80002984 <usertrap+0x14a>
    800029a4:	4901                	li	s2,0
    800029a6:	bff9                	j	80002984 <usertrap+0x14a>

00000000800029a8 <kerneltrap>:
{
    800029a8:	7179                	addi	sp,sp,-48
    800029aa:	f406                	sd	ra,40(sp)
    800029ac:	f022                	sd	s0,32(sp)
    800029ae:	ec26                	sd	s1,24(sp)
    800029b0:	e84a                	sd	s2,16(sp)
    800029b2:	e44e                	sd	s3,8(sp)
    800029b4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ba:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029be:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029c2:	1004f793          	andi	a5,s1,256
    800029c6:	cb85                	beqz	a5,800029f6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029cc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029ce:	ef85                	bnez	a5,80002a06 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029d0:	00000097          	auipc	ra,0x0
    800029d4:	dc8080e7          	jalr	-568(ra) # 80002798 <devintr>
    800029d8:	cd1d                	beqz	a0,80002a16 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029da:	4789                	li	a5,2
    800029dc:	06f50a63          	beq	a0,a5,80002a50 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029e0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e4:	10049073          	csrw	sstatus,s1
}
    800029e8:	70a2                	ld	ra,40(sp)
    800029ea:	7402                	ld	s0,32(sp)
    800029ec:	64e2                	ld	s1,24(sp)
    800029ee:	6942                	ld	s2,16(sp)
    800029f0:	69a2                	ld	s3,8(sp)
    800029f2:	6145                	addi	sp,sp,48
    800029f4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	90a50513          	addi	a0,a0,-1782 # 80008300 <states.0+0xc0>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b48080e7          	jalr	-1208(ra) # 80000546 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a06:	00006517          	auipc	a0,0x6
    80002a0a:	92250513          	addi	a0,a0,-1758 # 80008328 <states.0+0xe8>
    80002a0e:	ffffe097          	auipc	ra,0xffffe
    80002a12:	b38080e7          	jalr	-1224(ra) # 80000546 <panic>
    printf("scause %p\n", scause);
    80002a16:	85ce                	mv	a1,s3
    80002a18:	00006517          	auipc	a0,0x6
    80002a1c:	93050513          	addi	a0,a0,-1744 # 80008348 <states.0+0x108>
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	b70080e7          	jalr	-1168(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a28:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a2c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	92850513          	addi	a0,a0,-1752 # 80008358 <states.0+0x118>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b58080e7          	jalr	-1192(ra) # 80000590 <printf>
    panic("kerneltrap");
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	93050513          	addi	a0,a0,-1744 # 80008370 <states.0+0x130>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	afe080e7          	jalr	-1282(ra) # 80000546 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a50:	fffff097          	auipc	ra,0xfffff
    80002a54:	fbe080e7          	jalr	-66(ra) # 80001a0e <myproc>
    80002a58:	d541                	beqz	a0,800029e0 <kerneltrap+0x38>
    80002a5a:	fffff097          	auipc	ra,0xfffff
    80002a5e:	fb4080e7          	jalr	-76(ra) # 80001a0e <myproc>
    80002a62:	4d18                	lw	a4,24(a0)
    80002a64:	478d                	li	a5,3
    80002a66:	f6f71de3          	bne	a4,a5,800029e0 <kerneltrap+0x38>
    yield();
    80002a6a:	fffff097          	auipc	ra,0xfffff
    80002a6e:	780080e7          	jalr	1920(ra) # 800021ea <yield>
    80002a72:	b7bd                	j	800029e0 <kerneltrap+0x38>

0000000080002a74 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a74:	1101                	addi	sp,sp,-32
    80002a76:	ec06                	sd	ra,24(sp)
    80002a78:	e822                	sd	s0,16(sp)
    80002a7a:	e426                	sd	s1,8(sp)
    80002a7c:	1000                	addi	s0,sp,32
    80002a7e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	f8e080e7          	jalr	-114(ra) # 80001a0e <myproc>
  switch (n) {
    80002a88:	4795                	li	a5,5
    80002a8a:	0497e163          	bltu	a5,s1,80002acc <argraw+0x58>
    80002a8e:	048a                	slli	s1,s1,0x2
    80002a90:	00006717          	auipc	a4,0x6
    80002a94:	91870713          	addi	a4,a4,-1768 # 800083a8 <states.0+0x168>
    80002a98:	94ba                	add	s1,s1,a4
    80002a9a:	409c                	lw	a5,0(s1)
    80002a9c:	97ba                	add	a5,a5,a4
    80002a9e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002aa0:	6d3c                	ld	a5,88(a0)
    80002aa2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aa4:	60e2                	ld	ra,24(sp)
    80002aa6:	6442                	ld	s0,16(sp)
    80002aa8:	64a2                	ld	s1,8(sp)
    80002aaa:	6105                	addi	sp,sp,32
    80002aac:	8082                	ret
    return p->trapframe->a1;
    80002aae:	6d3c                	ld	a5,88(a0)
    80002ab0:	7fa8                	ld	a0,120(a5)
    80002ab2:	bfcd                	j	80002aa4 <argraw+0x30>
    return p->trapframe->a2;
    80002ab4:	6d3c                	ld	a5,88(a0)
    80002ab6:	63c8                	ld	a0,128(a5)
    80002ab8:	b7f5                	j	80002aa4 <argraw+0x30>
    return p->trapframe->a3;
    80002aba:	6d3c                	ld	a5,88(a0)
    80002abc:	67c8                	ld	a0,136(a5)
    80002abe:	b7dd                	j	80002aa4 <argraw+0x30>
    return p->trapframe->a4;
    80002ac0:	6d3c                	ld	a5,88(a0)
    80002ac2:	6bc8                	ld	a0,144(a5)
    80002ac4:	b7c5                	j	80002aa4 <argraw+0x30>
    return p->trapframe->a5;
    80002ac6:	6d3c                	ld	a5,88(a0)
    80002ac8:	6fc8                	ld	a0,152(a5)
    80002aca:	bfe9                	j	80002aa4 <argraw+0x30>
  panic("argraw");
    80002acc:	00006517          	auipc	a0,0x6
    80002ad0:	8b450513          	addi	a0,a0,-1868 # 80008380 <states.0+0x140>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	a72080e7          	jalr	-1422(ra) # 80000546 <panic>

0000000080002adc <fetchaddr>:
{
    80002adc:	1101                	addi	sp,sp,-32
    80002ade:	ec06                	sd	ra,24(sp)
    80002ae0:	e822                	sd	s0,16(sp)
    80002ae2:	e426                	sd	s1,8(sp)
    80002ae4:	e04a                	sd	s2,0(sp)
    80002ae6:	1000                	addi	s0,sp,32
    80002ae8:	84aa                	mv	s1,a0
    80002aea:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002aec:	fffff097          	auipc	ra,0xfffff
    80002af0:	f22080e7          	jalr	-222(ra) # 80001a0e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002af4:	653c                	ld	a5,72(a0)
    80002af6:	02f4f863          	bgeu	s1,a5,80002b26 <fetchaddr+0x4a>
    80002afa:	00848713          	addi	a4,s1,8
    80002afe:	02e7e663          	bltu	a5,a4,80002b2a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b02:	46a1                	li	a3,8
    80002b04:	8626                	mv	a2,s1
    80002b06:	85ca                	mv	a1,s2
    80002b08:	6928                	ld	a0,80(a0)
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	c86080e7          	jalr	-890(ra) # 80001790 <copyin>
    80002b12:	00a03533          	snez	a0,a0
    80002b16:	40a00533          	neg	a0,a0
}
    80002b1a:	60e2                	ld	ra,24(sp)
    80002b1c:	6442                	ld	s0,16(sp)
    80002b1e:	64a2                	ld	s1,8(sp)
    80002b20:	6902                	ld	s2,0(sp)
    80002b22:	6105                	addi	sp,sp,32
    80002b24:	8082                	ret
    return -1;
    80002b26:	557d                	li	a0,-1
    80002b28:	bfcd                	j	80002b1a <fetchaddr+0x3e>
    80002b2a:	557d                	li	a0,-1
    80002b2c:	b7fd                	j	80002b1a <fetchaddr+0x3e>

0000000080002b2e <fetchstr>:
{
    80002b2e:	7179                	addi	sp,sp,-48
    80002b30:	f406                	sd	ra,40(sp)
    80002b32:	f022                	sd	s0,32(sp)
    80002b34:	ec26                	sd	s1,24(sp)
    80002b36:	e84a                	sd	s2,16(sp)
    80002b38:	e44e                	sd	s3,8(sp)
    80002b3a:	1800                	addi	s0,sp,48
    80002b3c:	892a                	mv	s2,a0
    80002b3e:	84ae                	mv	s1,a1
    80002b40:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b42:	fffff097          	auipc	ra,0xfffff
    80002b46:	ecc080e7          	jalr	-308(ra) # 80001a0e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b4a:	86ce                	mv	a3,s3
    80002b4c:	864a                	mv	a2,s2
    80002b4e:	85a6                	mv	a1,s1
    80002b50:	6928                	ld	a0,80(a0)
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	ccc080e7          	jalr	-820(ra) # 8000181e <copyinstr>
  if(err < 0)
    80002b5a:	00054763          	bltz	a0,80002b68 <fetchstr+0x3a>
  return strlen(buf);
    80002b5e:	8526                	mv	a0,s1
    80002b60:	ffffe097          	auipc	ra,0xffffe
    80002b64:	320080e7          	jalr	800(ra) # 80000e80 <strlen>
}
    80002b68:	70a2                	ld	ra,40(sp)
    80002b6a:	7402                	ld	s0,32(sp)
    80002b6c:	64e2                	ld	s1,24(sp)
    80002b6e:	6942                	ld	s2,16(sp)
    80002b70:	69a2                	ld	s3,8(sp)
    80002b72:	6145                	addi	sp,sp,48
    80002b74:	8082                	ret

0000000080002b76 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b76:	1101                	addi	sp,sp,-32
    80002b78:	ec06                	sd	ra,24(sp)
    80002b7a:	e822                	sd	s0,16(sp)
    80002b7c:	e426                	sd	s1,8(sp)
    80002b7e:	1000                	addi	s0,sp,32
    80002b80:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b82:	00000097          	auipc	ra,0x0
    80002b86:	ef2080e7          	jalr	-270(ra) # 80002a74 <argraw>
    80002b8a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b8c:	4501                	li	a0,0
    80002b8e:	60e2                	ld	ra,24(sp)
    80002b90:	6442                	ld	s0,16(sp)
    80002b92:	64a2                	ld	s1,8(sp)
    80002b94:	6105                	addi	sp,sp,32
    80002b96:	8082                	ret

0000000080002b98 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b98:	1101                	addi	sp,sp,-32
    80002b9a:	ec06                	sd	ra,24(sp)
    80002b9c:	e822                	sd	s0,16(sp)
    80002b9e:	e426                	sd	s1,8(sp)
    80002ba0:	1000                	addi	s0,sp,32
    80002ba2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ba4:	00000097          	auipc	ra,0x0
    80002ba8:	ed0080e7          	jalr	-304(ra) # 80002a74 <argraw>
    80002bac:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bae:	4501                	li	a0,0
    80002bb0:	60e2                	ld	ra,24(sp)
    80002bb2:	6442                	ld	s0,16(sp)
    80002bb4:	64a2                	ld	s1,8(sp)
    80002bb6:	6105                	addi	sp,sp,32
    80002bb8:	8082                	ret

0000000080002bba <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bba:	1101                	addi	sp,sp,-32
    80002bbc:	ec06                	sd	ra,24(sp)
    80002bbe:	e822                	sd	s0,16(sp)
    80002bc0:	e426                	sd	s1,8(sp)
    80002bc2:	e04a                	sd	s2,0(sp)
    80002bc4:	1000                	addi	s0,sp,32
    80002bc6:	84ae                	mv	s1,a1
    80002bc8:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bca:	00000097          	auipc	ra,0x0
    80002bce:	eaa080e7          	jalr	-342(ra) # 80002a74 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bd2:	864a                	mv	a2,s2
    80002bd4:	85a6                	mv	a1,s1
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	f58080e7          	jalr	-168(ra) # 80002b2e <fetchstr>
}
    80002bde:	60e2                	ld	ra,24(sp)
    80002be0:	6442                	ld	s0,16(sp)
    80002be2:	64a2                	ld	s1,8(sp)
    80002be4:	6902                	ld	s2,0(sp)
    80002be6:	6105                	addi	sp,sp,32
    80002be8:	8082                	ret

0000000080002bea <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002bea:	1101                	addi	sp,sp,-32
    80002bec:	ec06                	sd	ra,24(sp)
    80002bee:	e822                	sd	s0,16(sp)
    80002bf0:	e426                	sd	s1,8(sp)
    80002bf2:	e04a                	sd	s2,0(sp)
    80002bf4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	e18080e7          	jalr	-488(ra) # 80001a0e <myproc>
    80002bfe:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c00:	05853903          	ld	s2,88(a0)
    80002c04:	0a893783          	ld	a5,168(s2)
    80002c08:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c0c:	37fd                	addiw	a5,a5,-1
    80002c0e:	4751                	li	a4,20
    80002c10:	00f76f63          	bltu	a4,a5,80002c2e <syscall+0x44>
    80002c14:	00369713          	slli	a4,a3,0x3
    80002c18:	00005797          	auipc	a5,0x5
    80002c1c:	7a878793          	addi	a5,a5,1960 # 800083c0 <syscalls>
    80002c20:	97ba                	add	a5,a5,a4
    80002c22:	639c                	ld	a5,0(a5)
    80002c24:	c789                	beqz	a5,80002c2e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c26:	9782                	jalr	a5
    80002c28:	06a93823          	sd	a0,112(s2)
    80002c2c:	a839                	j	80002c4a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c2e:	15848613          	addi	a2,s1,344
    80002c32:	5c8c                	lw	a1,56(s1)
    80002c34:	00005517          	auipc	a0,0x5
    80002c38:	75450513          	addi	a0,a0,1876 # 80008388 <states.0+0x148>
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	954080e7          	jalr	-1708(ra) # 80000590 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c44:	6cbc                	ld	a5,88(s1)
    80002c46:	577d                	li	a4,-1
    80002c48:	fbb8                	sd	a4,112(a5)
  }
}
    80002c4a:	60e2                	ld	ra,24(sp)
    80002c4c:	6442                	ld	s0,16(sp)
    80002c4e:	64a2                	ld	s1,8(sp)
    80002c50:	6902                	ld	s2,0(sp)
    80002c52:	6105                	addi	sp,sp,32
    80002c54:	8082                	ret

0000000080002c56 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c56:	1101                	addi	sp,sp,-32
    80002c58:	ec06                	sd	ra,24(sp)
    80002c5a:	e822                	sd	s0,16(sp)
    80002c5c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c5e:	fec40593          	addi	a1,s0,-20
    80002c62:	4501                	li	a0,0
    80002c64:	00000097          	auipc	ra,0x0
    80002c68:	f12080e7          	jalr	-238(ra) # 80002b76 <argint>
    return -1;
    80002c6c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c6e:	00054963          	bltz	a0,80002c80 <sys_exit+0x2a>
  exit(n);
    80002c72:	fec42503          	lw	a0,-20(s0)
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	46a080e7          	jalr	1130(ra) # 800020e0 <exit>
  return 0;  // not reached
    80002c7e:	4781                	li	a5,0
}
    80002c80:	853e                	mv	a0,a5
    80002c82:	60e2                	ld	ra,24(sp)
    80002c84:	6442                	ld	s0,16(sp)
    80002c86:	6105                	addi	sp,sp,32
    80002c88:	8082                	ret

0000000080002c8a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c8a:	1141                	addi	sp,sp,-16
    80002c8c:	e406                	sd	ra,8(sp)
    80002c8e:	e022                	sd	s0,0(sp)
    80002c90:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	d7c080e7          	jalr	-644(ra) # 80001a0e <myproc>
}
    80002c9a:	5d08                	lw	a0,56(a0)
    80002c9c:	60a2                	ld	ra,8(sp)
    80002c9e:	6402                	ld	s0,0(sp)
    80002ca0:	0141                	addi	sp,sp,16
    80002ca2:	8082                	ret

0000000080002ca4 <sys_fork>:

uint64
sys_fork(void)
{
    80002ca4:	1141                	addi	sp,sp,-16
    80002ca6:	e406                	sd	ra,8(sp)
    80002ca8:	e022                	sd	s0,0(sp)
    80002caa:	0800                	addi	s0,sp,16
  return fork();
    80002cac:	fffff097          	auipc	ra,0xfffff
    80002cb0:	126080e7          	jalr	294(ra) # 80001dd2 <fork>
}
    80002cb4:	60a2                	ld	ra,8(sp)
    80002cb6:	6402                	ld	s0,0(sp)
    80002cb8:	0141                	addi	sp,sp,16
    80002cba:	8082                	ret

0000000080002cbc <sys_wait>:

uint64
sys_wait(void)
{
    80002cbc:	1101                	addi	sp,sp,-32
    80002cbe:	ec06                	sd	ra,24(sp)
    80002cc0:	e822                	sd	s0,16(sp)
    80002cc2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cc4:	fe840593          	addi	a1,s0,-24
    80002cc8:	4501                	li	a0,0
    80002cca:	00000097          	auipc	ra,0x0
    80002cce:	ece080e7          	jalr	-306(ra) # 80002b98 <argaddr>
    80002cd2:	87aa                	mv	a5,a0
    return -1;
    80002cd4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cd6:	0007c863          	bltz	a5,80002ce6 <sys_wait+0x2a>
  return wait(p);
    80002cda:	fe843503          	ld	a0,-24(s0)
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	5c6080e7          	jalr	1478(ra) # 800022a4 <wait>
}
    80002ce6:	60e2                	ld	ra,24(sp)
    80002ce8:	6442                	ld	s0,16(sp)
    80002cea:	6105                	addi	sp,sp,32
    80002cec:	8082                	ret

0000000080002cee <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cee:	7179                	addi	sp,sp,-48
    80002cf0:	f406                	sd	ra,40(sp)
    80002cf2:	f022                	sd	s0,32(sp)
    80002cf4:	ec26                	sd	s1,24(sp)
    80002cf6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cf8:	fdc40593          	addi	a1,s0,-36
    80002cfc:	4501                	li	a0,0
    80002cfe:	00000097          	auipc	ra,0x0
    80002d02:	e78080e7          	jalr	-392(ra) # 80002b76 <argint>
    80002d06:	87aa                	mv	a5,a0
    return -1;
    80002d08:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d0a:	0207c063          	bltz	a5,80002d2a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	d00080e7          	jalr	-768(ra) # 80001a0e <myproc>
    80002d16:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d18:	fdc42503          	lw	a0,-36(s0)
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	03e080e7          	jalr	62(ra) # 80001d5a <growproc>
    80002d24:	00054863          	bltz	a0,80002d34 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d28:	8526                	mv	a0,s1
}
    80002d2a:	70a2                	ld	ra,40(sp)
    80002d2c:	7402                	ld	s0,32(sp)
    80002d2e:	64e2                	ld	s1,24(sp)
    80002d30:	6145                	addi	sp,sp,48
    80002d32:	8082                	ret
    return -1;
    80002d34:	557d                	li	a0,-1
    80002d36:	bfd5                	j	80002d2a <sys_sbrk+0x3c>

0000000080002d38 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d38:	7139                	addi	sp,sp,-64
    80002d3a:	fc06                	sd	ra,56(sp)
    80002d3c:	f822                	sd	s0,48(sp)
    80002d3e:	f426                	sd	s1,40(sp)
    80002d40:	f04a                	sd	s2,32(sp)
    80002d42:	ec4e                	sd	s3,24(sp)
    80002d44:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d46:	fcc40593          	addi	a1,s0,-52
    80002d4a:	4501                	li	a0,0
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	e2a080e7          	jalr	-470(ra) # 80002b76 <argint>
    return -1;
    80002d54:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d56:	06054563          	bltz	a0,80002dc0 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d5a:	00015517          	auipc	a0,0x15
    80002d5e:	a0e50513          	addi	a0,a0,-1522 # 80017768 <tickslock>
    80002d62:	ffffe097          	auipc	ra,0xffffe
    80002d66:	e9e080e7          	jalr	-354(ra) # 80000c00 <acquire>
  ticks0 = ticks;
    80002d6a:	00006917          	auipc	s2,0x6
    80002d6e:	2b692903          	lw	s2,694(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d72:	fcc42783          	lw	a5,-52(s0)
    80002d76:	cf85                	beqz	a5,80002dae <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d78:	00015997          	auipc	s3,0x15
    80002d7c:	9f098993          	addi	s3,s3,-1552 # 80017768 <tickslock>
    80002d80:	00006497          	auipc	s1,0x6
    80002d84:	2a048493          	addi	s1,s1,672 # 80009020 <ticks>
    if(myproc()->killed){
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	c86080e7          	jalr	-890(ra) # 80001a0e <myproc>
    80002d90:	591c                	lw	a5,48(a0)
    80002d92:	ef9d                	bnez	a5,80002dd0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d94:	85ce                	mv	a1,s3
    80002d96:	8526                	mv	a0,s1
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	48e080e7          	jalr	1166(ra) # 80002226 <sleep>
  while(ticks - ticks0 < n){
    80002da0:	409c                	lw	a5,0(s1)
    80002da2:	412787bb          	subw	a5,a5,s2
    80002da6:	fcc42703          	lw	a4,-52(s0)
    80002daa:	fce7efe3          	bltu	a5,a4,80002d88 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dae:	00015517          	auipc	a0,0x15
    80002db2:	9ba50513          	addi	a0,a0,-1606 # 80017768 <tickslock>
    80002db6:	ffffe097          	auipc	ra,0xffffe
    80002dba:	efe080e7          	jalr	-258(ra) # 80000cb4 <release>
  return 0;
    80002dbe:	4781                	li	a5,0
}
    80002dc0:	853e                	mv	a0,a5
    80002dc2:	70e2                	ld	ra,56(sp)
    80002dc4:	7442                	ld	s0,48(sp)
    80002dc6:	74a2                	ld	s1,40(sp)
    80002dc8:	7902                	ld	s2,32(sp)
    80002dca:	69e2                	ld	s3,24(sp)
    80002dcc:	6121                	addi	sp,sp,64
    80002dce:	8082                	ret
      release(&tickslock);
    80002dd0:	00015517          	auipc	a0,0x15
    80002dd4:	99850513          	addi	a0,a0,-1640 # 80017768 <tickslock>
    80002dd8:	ffffe097          	auipc	ra,0xffffe
    80002ddc:	edc080e7          	jalr	-292(ra) # 80000cb4 <release>
      return -1;
    80002de0:	57fd                	li	a5,-1
    80002de2:	bff9                	j	80002dc0 <sys_sleep+0x88>

0000000080002de4 <sys_kill>:

uint64
sys_kill(void)
{
    80002de4:	1101                	addi	sp,sp,-32
    80002de6:	ec06                	sd	ra,24(sp)
    80002de8:	e822                	sd	s0,16(sp)
    80002dea:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dec:	fec40593          	addi	a1,s0,-20
    80002df0:	4501                	li	a0,0
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	d84080e7          	jalr	-636(ra) # 80002b76 <argint>
    80002dfa:	87aa                	mv	a5,a0
    return -1;
    80002dfc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002dfe:	0007c863          	bltz	a5,80002e0e <sys_kill+0x2a>
  return kill(pid);
    80002e02:	fec42503          	lw	a0,-20(s0)
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	60a080e7          	jalr	1546(ra) # 80002410 <kill>
}
    80002e0e:	60e2                	ld	ra,24(sp)
    80002e10:	6442                	ld	s0,16(sp)
    80002e12:	6105                	addi	sp,sp,32
    80002e14:	8082                	ret

0000000080002e16 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e16:	1101                	addi	sp,sp,-32
    80002e18:	ec06                	sd	ra,24(sp)
    80002e1a:	e822                	sd	s0,16(sp)
    80002e1c:	e426                	sd	s1,8(sp)
    80002e1e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e20:	00015517          	auipc	a0,0x15
    80002e24:	94850513          	addi	a0,a0,-1720 # 80017768 <tickslock>
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	dd8080e7          	jalr	-552(ra) # 80000c00 <acquire>
  xticks = ticks;
    80002e30:	00006497          	auipc	s1,0x6
    80002e34:	1f04a483          	lw	s1,496(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e38:	00015517          	auipc	a0,0x15
    80002e3c:	93050513          	addi	a0,a0,-1744 # 80017768 <tickslock>
    80002e40:	ffffe097          	auipc	ra,0xffffe
    80002e44:	e74080e7          	jalr	-396(ra) # 80000cb4 <release>
  return xticks;
}
    80002e48:	02049513          	slli	a0,s1,0x20
    80002e4c:	9101                	srli	a0,a0,0x20
    80002e4e:	60e2                	ld	ra,24(sp)
    80002e50:	6442                	ld	s0,16(sp)
    80002e52:	64a2                	ld	s1,8(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret

0000000080002e58 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e58:	7179                	addi	sp,sp,-48
    80002e5a:	f406                	sd	ra,40(sp)
    80002e5c:	f022                	sd	s0,32(sp)
    80002e5e:	ec26                	sd	s1,24(sp)
    80002e60:	e84a                	sd	s2,16(sp)
    80002e62:	e44e                	sd	s3,8(sp)
    80002e64:	e052                	sd	s4,0(sp)
    80002e66:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e68:	00005597          	auipc	a1,0x5
    80002e6c:	60858593          	addi	a1,a1,1544 # 80008470 <syscalls+0xb0>
    80002e70:	00015517          	auipc	a0,0x15
    80002e74:	91050513          	addi	a0,a0,-1776 # 80017780 <bcache>
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	cf8080e7          	jalr	-776(ra) # 80000b70 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e80:	0001d797          	auipc	a5,0x1d
    80002e84:	90078793          	addi	a5,a5,-1792 # 8001f780 <bcache+0x8000>
    80002e88:	0001d717          	auipc	a4,0x1d
    80002e8c:	b6070713          	addi	a4,a4,-1184 # 8001f9e8 <bcache+0x8268>
    80002e90:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e94:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e98:	00015497          	auipc	s1,0x15
    80002e9c:	90048493          	addi	s1,s1,-1792 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002ea0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ea2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ea4:	00005a17          	auipc	s4,0x5
    80002ea8:	5d4a0a13          	addi	s4,s4,1492 # 80008478 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002eac:	2b893783          	ld	a5,696(s2)
    80002eb0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eb2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002eb6:	85d2                	mv	a1,s4
    80002eb8:	01048513          	addi	a0,s1,16
    80002ebc:	00001097          	auipc	ra,0x1
    80002ec0:	4b6080e7          	jalr	1206(ra) # 80004372 <initsleeplock>
    bcache.head.next->prev = b;
    80002ec4:	2b893783          	ld	a5,696(s2)
    80002ec8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002eca:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ece:	45848493          	addi	s1,s1,1112
    80002ed2:	fd349de3          	bne	s1,s3,80002eac <binit+0x54>
  }
}
    80002ed6:	70a2                	ld	ra,40(sp)
    80002ed8:	7402                	ld	s0,32(sp)
    80002eda:	64e2                	ld	s1,24(sp)
    80002edc:	6942                	ld	s2,16(sp)
    80002ede:	69a2                	ld	s3,8(sp)
    80002ee0:	6a02                	ld	s4,0(sp)
    80002ee2:	6145                	addi	sp,sp,48
    80002ee4:	8082                	ret

0000000080002ee6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ee6:	7179                	addi	sp,sp,-48
    80002ee8:	f406                	sd	ra,40(sp)
    80002eea:	f022                	sd	s0,32(sp)
    80002eec:	ec26                	sd	s1,24(sp)
    80002eee:	e84a                	sd	s2,16(sp)
    80002ef0:	e44e                	sd	s3,8(sp)
    80002ef2:	1800                	addi	s0,sp,48
    80002ef4:	892a                	mv	s2,a0
    80002ef6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ef8:	00015517          	auipc	a0,0x15
    80002efc:	88850513          	addi	a0,a0,-1912 # 80017780 <bcache>
    80002f00:	ffffe097          	auipc	ra,0xffffe
    80002f04:	d00080e7          	jalr	-768(ra) # 80000c00 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f08:	0001d497          	auipc	s1,0x1d
    80002f0c:	b304b483          	ld	s1,-1232(s1) # 8001fa38 <bcache+0x82b8>
    80002f10:	0001d797          	auipc	a5,0x1d
    80002f14:	ad878793          	addi	a5,a5,-1320 # 8001f9e8 <bcache+0x8268>
    80002f18:	02f48f63          	beq	s1,a5,80002f56 <bread+0x70>
    80002f1c:	873e                	mv	a4,a5
    80002f1e:	a021                	j	80002f26 <bread+0x40>
    80002f20:	68a4                	ld	s1,80(s1)
    80002f22:	02e48a63          	beq	s1,a4,80002f56 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f26:	449c                	lw	a5,8(s1)
    80002f28:	ff279ce3          	bne	a5,s2,80002f20 <bread+0x3a>
    80002f2c:	44dc                	lw	a5,12(s1)
    80002f2e:	ff3799e3          	bne	a5,s3,80002f20 <bread+0x3a>
      b->refcnt++;
    80002f32:	40bc                	lw	a5,64(s1)
    80002f34:	2785                	addiw	a5,a5,1
    80002f36:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f38:	00015517          	auipc	a0,0x15
    80002f3c:	84850513          	addi	a0,a0,-1976 # 80017780 <bcache>
    80002f40:	ffffe097          	auipc	ra,0xffffe
    80002f44:	d74080e7          	jalr	-652(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    80002f48:	01048513          	addi	a0,s1,16
    80002f4c:	00001097          	auipc	ra,0x1
    80002f50:	460080e7          	jalr	1120(ra) # 800043ac <acquiresleep>
      return b;
    80002f54:	a8b9                	j	80002fb2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f56:	0001d497          	auipc	s1,0x1d
    80002f5a:	ada4b483          	ld	s1,-1318(s1) # 8001fa30 <bcache+0x82b0>
    80002f5e:	0001d797          	auipc	a5,0x1d
    80002f62:	a8a78793          	addi	a5,a5,-1398 # 8001f9e8 <bcache+0x8268>
    80002f66:	00f48863          	beq	s1,a5,80002f76 <bread+0x90>
    80002f6a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f6c:	40bc                	lw	a5,64(s1)
    80002f6e:	cf81                	beqz	a5,80002f86 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f70:	64a4                	ld	s1,72(s1)
    80002f72:	fee49de3          	bne	s1,a4,80002f6c <bread+0x86>
  panic("bget: no buffers");
    80002f76:	00005517          	auipc	a0,0x5
    80002f7a:	50a50513          	addi	a0,a0,1290 # 80008480 <syscalls+0xc0>
    80002f7e:	ffffd097          	auipc	ra,0xffffd
    80002f82:	5c8080e7          	jalr	1480(ra) # 80000546 <panic>
      b->dev = dev;
    80002f86:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f8a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f8e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f92:	4785                	li	a5,1
    80002f94:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f96:	00014517          	auipc	a0,0x14
    80002f9a:	7ea50513          	addi	a0,a0,2026 # 80017780 <bcache>
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	d16080e7          	jalr	-746(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    80002fa6:	01048513          	addi	a0,s1,16
    80002faa:	00001097          	auipc	ra,0x1
    80002fae:	402080e7          	jalr	1026(ra) # 800043ac <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fb2:	409c                	lw	a5,0(s1)
    80002fb4:	cb89                	beqz	a5,80002fc6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fb6:	8526                	mv	a0,s1
    80002fb8:	70a2                	ld	ra,40(sp)
    80002fba:	7402                	ld	s0,32(sp)
    80002fbc:	64e2                	ld	s1,24(sp)
    80002fbe:	6942                	ld	s2,16(sp)
    80002fc0:	69a2                	ld	s3,8(sp)
    80002fc2:	6145                	addi	sp,sp,48
    80002fc4:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fc6:	4581                	li	a1,0
    80002fc8:	8526                	mv	a0,s1
    80002fca:	00003097          	auipc	ra,0x3
    80002fce:	f2e080e7          	jalr	-210(ra) # 80005ef8 <virtio_disk_rw>
    b->valid = 1;
    80002fd2:	4785                	li	a5,1
    80002fd4:	c09c                	sw	a5,0(s1)
  return b;
    80002fd6:	b7c5                	j	80002fb6 <bread+0xd0>

0000000080002fd8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fd8:	1101                	addi	sp,sp,-32
    80002fda:	ec06                	sd	ra,24(sp)
    80002fdc:	e822                	sd	s0,16(sp)
    80002fde:	e426                	sd	s1,8(sp)
    80002fe0:	1000                	addi	s0,sp,32
    80002fe2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fe4:	0541                	addi	a0,a0,16
    80002fe6:	00001097          	auipc	ra,0x1
    80002fea:	460080e7          	jalr	1120(ra) # 80004446 <holdingsleep>
    80002fee:	cd01                	beqz	a0,80003006 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ff0:	4585                	li	a1,1
    80002ff2:	8526                	mv	a0,s1
    80002ff4:	00003097          	auipc	ra,0x3
    80002ff8:	f04080e7          	jalr	-252(ra) # 80005ef8 <virtio_disk_rw>
}
    80002ffc:	60e2                	ld	ra,24(sp)
    80002ffe:	6442                	ld	s0,16(sp)
    80003000:	64a2                	ld	s1,8(sp)
    80003002:	6105                	addi	sp,sp,32
    80003004:	8082                	ret
    panic("bwrite");
    80003006:	00005517          	auipc	a0,0x5
    8000300a:	49250513          	addi	a0,a0,1170 # 80008498 <syscalls+0xd8>
    8000300e:	ffffd097          	auipc	ra,0xffffd
    80003012:	538080e7          	jalr	1336(ra) # 80000546 <panic>

0000000080003016 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003016:	1101                	addi	sp,sp,-32
    80003018:	ec06                	sd	ra,24(sp)
    8000301a:	e822                	sd	s0,16(sp)
    8000301c:	e426                	sd	s1,8(sp)
    8000301e:	e04a                	sd	s2,0(sp)
    80003020:	1000                	addi	s0,sp,32
    80003022:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003024:	01050913          	addi	s2,a0,16
    80003028:	854a                	mv	a0,s2
    8000302a:	00001097          	auipc	ra,0x1
    8000302e:	41c080e7          	jalr	1052(ra) # 80004446 <holdingsleep>
    80003032:	c92d                	beqz	a0,800030a4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003034:	854a                	mv	a0,s2
    80003036:	00001097          	auipc	ra,0x1
    8000303a:	3cc080e7          	jalr	972(ra) # 80004402 <releasesleep>

  acquire(&bcache.lock);
    8000303e:	00014517          	auipc	a0,0x14
    80003042:	74250513          	addi	a0,a0,1858 # 80017780 <bcache>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	bba080e7          	jalr	-1094(ra) # 80000c00 <acquire>
  b->refcnt--;
    8000304e:	40bc                	lw	a5,64(s1)
    80003050:	37fd                	addiw	a5,a5,-1
    80003052:	0007871b          	sext.w	a4,a5
    80003056:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003058:	eb05                	bnez	a4,80003088 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000305a:	68bc                	ld	a5,80(s1)
    8000305c:	64b8                	ld	a4,72(s1)
    8000305e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003060:	64bc                	ld	a5,72(s1)
    80003062:	68b8                	ld	a4,80(s1)
    80003064:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003066:	0001c797          	auipc	a5,0x1c
    8000306a:	71a78793          	addi	a5,a5,1818 # 8001f780 <bcache+0x8000>
    8000306e:	2b87b703          	ld	a4,696(a5)
    80003072:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003074:	0001d717          	auipc	a4,0x1d
    80003078:	97470713          	addi	a4,a4,-1676 # 8001f9e8 <bcache+0x8268>
    8000307c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000307e:	2b87b703          	ld	a4,696(a5)
    80003082:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003084:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003088:	00014517          	auipc	a0,0x14
    8000308c:	6f850513          	addi	a0,a0,1784 # 80017780 <bcache>
    80003090:	ffffe097          	auipc	ra,0xffffe
    80003094:	c24080e7          	jalr	-988(ra) # 80000cb4 <release>
}
    80003098:	60e2                	ld	ra,24(sp)
    8000309a:	6442                	ld	s0,16(sp)
    8000309c:	64a2                	ld	s1,8(sp)
    8000309e:	6902                	ld	s2,0(sp)
    800030a0:	6105                	addi	sp,sp,32
    800030a2:	8082                	ret
    panic("brelse");
    800030a4:	00005517          	auipc	a0,0x5
    800030a8:	3fc50513          	addi	a0,a0,1020 # 800084a0 <syscalls+0xe0>
    800030ac:	ffffd097          	auipc	ra,0xffffd
    800030b0:	49a080e7          	jalr	1178(ra) # 80000546 <panic>

00000000800030b4 <bpin>:

void
bpin(struct buf *b) {
    800030b4:	1101                	addi	sp,sp,-32
    800030b6:	ec06                	sd	ra,24(sp)
    800030b8:	e822                	sd	s0,16(sp)
    800030ba:	e426                	sd	s1,8(sp)
    800030bc:	1000                	addi	s0,sp,32
    800030be:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030c0:	00014517          	auipc	a0,0x14
    800030c4:	6c050513          	addi	a0,a0,1728 # 80017780 <bcache>
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	b38080e7          	jalr	-1224(ra) # 80000c00 <acquire>
  b->refcnt++;
    800030d0:	40bc                	lw	a5,64(s1)
    800030d2:	2785                	addiw	a5,a5,1
    800030d4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030d6:	00014517          	auipc	a0,0x14
    800030da:	6aa50513          	addi	a0,a0,1706 # 80017780 <bcache>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	bd6080e7          	jalr	-1066(ra) # 80000cb4 <release>
}
    800030e6:	60e2                	ld	ra,24(sp)
    800030e8:	6442                	ld	s0,16(sp)
    800030ea:	64a2                	ld	s1,8(sp)
    800030ec:	6105                	addi	sp,sp,32
    800030ee:	8082                	ret

00000000800030f0 <bunpin>:

void
bunpin(struct buf *b) {
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	e426                	sd	s1,8(sp)
    800030f8:	1000                	addi	s0,sp,32
    800030fa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030fc:	00014517          	auipc	a0,0x14
    80003100:	68450513          	addi	a0,a0,1668 # 80017780 <bcache>
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	afc080e7          	jalr	-1284(ra) # 80000c00 <acquire>
  b->refcnt--;
    8000310c:	40bc                	lw	a5,64(s1)
    8000310e:	37fd                	addiw	a5,a5,-1
    80003110:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003112:	00014517          	auipc	a0,0x14
    80003116:	66e50513          	addi	a0,a0,1646 # 80017780 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	b9a080e7          	jalr	-1126(ra) # 80000cb4 <release>
}
    80003122:	60e2                	ld	ra,24(sp)
    80003124:	6442                	ld	s0,16(sp)
    80003126:	64a2                	ld	s1,8(sp)
    80003128:	6105                	addi	sp,sp,32
    8000312a:	8082                	ret

000000008000312c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000312c:	1101                	addi	sp,sp,-32
    8000312e:	ec06                	sd	ra,24(sp)
    80003130:	e822                	sd	s0,16(sp)
    80003132:	e426                	sd	s1,8(sp)
    80003134:	e04a                	sd	s2,0(sp)
    80003136:	1000                	addi	s0,sp,32
    80003138:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000313a:	00d5d59b          	srliw	a1,a1,0xd
    8000313e:	0001d797          	auipc	a5,0x1d
    80003142:	d1e7a783          	lw	a5,-738(a5) # 8001fe5c <sb+0x1c>
    80003146:	9dbd                	addw	a1,a1,a5
    80003148:	00000097          	auipc	ra,0x0
    8000314c:	d9e080e7          	jalr	-610(ra) # 80002ee6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003150:	0074f713          	andi	a4,s1,7
    80003154:	4785                	li	a5,1
    80003156:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000315a:	14ce                	slli	s1,s1,0x33
    8000315c:	90d9                	srli	s1,s1,0x36
    8000315e:	00950733          	add	a4,a0,s1
    80003162:	05874703          	lbu	a4,88(a4)
    80003166:	00e7f6b3          	and	a3,a5,a4
    8000316a:	c69d                	beqz	a3,80003198 <bfree+0x6c>
    8000316c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000316e:	94aa                	add	s1,s1,a0
    80003170:	fff7c793          	not	a5,a5
    80003174:	8f7d                	and	a4,a4,a5
    80003176:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000317a:	00001097          	auipc	ra,0x1
    8000317e:	10c080e7          	jalr	268(ra) # 80004286 <log_write>
  brelse(bp);
    80003182:	854a                	mv	a0,s2
    80003184:	00000097          	auipc	ra,0x0
    80003188:	e92080e7          	jalr	-366(ra) # 80003016 <brelse>
}
    8000318c:	60e2                	ld	ra,24(sp)
    8000318e:	6442                	ld	s0,16(sp)
    80003190:	64a2                	ld	s1,8(sp)
    80003192:	6902                	ld	s2,0(sp)
    80003194:	6105                	addi	sp,sp,32
    80003196:	8082                	ret
    panic("freeing free block");
    80003198:	00005517          	auipc	a0,0x5
    8000319c:	31050513          	addi	a0,a0,784 # 800084a8 <syscalls+0xe8>
    800031a0:	ffffd097          	auipc	ra,0xffffd
    800031a4:	3a6080e7          	jalr	934(ra) # 80000546 <panic>

00000000800031a8 <balloc>:
{
    800031a8:	711d                	addi	sp,sp,-96
    800031aa:	ec86                	sd	ra,88(sp)
    800031ac:	e8a2                	sd	s0,80(sp)
    800031ae:	e4a6                	sd	s1,72(sp)
    800031b0:	e0ca                	sd	s2,64(sp)
    800031b2:	fc4e                	sd	s3,56(sp)
    800031b4:	f852                	sd	s4,48(sp)
    800031b6:	f456                	sd	s5,40(sp)
    800031b8:	f05a                	sd	s6,32(sp)
    800031ba:	ec5e                	sd	s7,24(sp)
    800031bc:	e862                	sd	s8,16(sp)
    800031be:	e466                	sd	s9,8(sp)
    800031c0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031c2:	0001d797          	auipc	a5,0x1d
    800031c6:	c827a783          	lw	a5,-894(a5) # 8001fe44 <sb+0x4>
    800031ca:	cbc1                	beqz	a5,8000325a <balloc+0xb2>
    800031cc:	8baa                	mv	s7,a0
    800031ce:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031d0:	0001db17          	auipc	s6,0x1d
    800031d4:	c70b0b13          	addi	s6,s6,-912 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031d8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031da:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031dc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031de:	6c89                	lui	s9,0x2
    800031e0:	a831                	j	800031fc <balloc+0x54>
    brelse(bp);
    800031e2:	854a                	mv	a0,s2
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	e32080e7          	jalr	-462(ra) # 80003016 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031ec:	015c87bb          	addw	a5,s9,s5
    800031f0:	00078a9b          	sext.w	s5,a5
    800031f4:	004b2703          	lw	a4,4(s6)
    800031f8:	06eaf163          	bgeu	s5,a4,8000325a <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800031fc:	41fad79b          	sraiw	a5,s5,0x1f
    80003200:	0137d79b          	srliw	a5,a5,0x13
    80003204:	015787bb          	addw	a5,a5,s5
    80003208:	40d7d79b          	sraiw	a5,a5,0xd
    8000320c:	01cb2583          	lw	a1,28(s6)
    80003210:	9dbd                	addw	a1,a1,a5
    80003212:	855e                	mv	a0,s7
    80003214:	00000097          	auipc	ra,0x0
    80003218:	cd2080e7          	jalr	-814(ra) # 80002ee6 <bread>
    8000321c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000321e:	004b2503          	lw	a0,4(s6)
    80003222:	000a849b          	sext.w	s1,s5
    80003226:	8762                	mv	a4,s8
    80003228:	faa4fde3          	bgeu	s1,a0,800031e2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000322c:	00777693          	andi	a3,a4,7
    80003230:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003234:	41f7579b          	sraiw	a5,a4,0x1f
    80003238:	01d7d79b          	srliw	a5,a5,0x1d
    8000323c:	9fb9                	addw	a5,a5,a4
    8000323e:	4037d79b          	sraiw	a5,a5,0x3
    80003242:	00f90633          	add	a2,s2,a5
    80003246:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000324a:	00c6f5b3          	and	a1,a3,a2
    8000324e:	cd91                	beqz	a1,8000326a <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003250:	2705                	addiw	a4,a4,1
    80003252:	2485                	addiw	s1,s1,1
    80003254:	fd471ae3          	bne	a4,s4,80003228 <balloc+0x80>
    80003258:	b769                	j	800031e2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000325a:	00005517          	auipc	a0,0x5
    8000325e:	26650513          	addi	a0,a0,614 # 800084c0 <syscalls+0x100>
    80003262:	ffffd097          	auipc	ra,0xffffd
    80003266:	2e4080e7          	jalr	740(ra) # 80000546 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000326a:	97ca                	add	a5,a5,s2
    8000326c:	8e55                	or	a2,a2,a3
    8000326e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003272:	854a                	mv	a0,s2
    80003274:	00001097          	auipc	ra,0x1
    80003278:	012080e7          	jalr	18(ra) # 80004286 <log_write>
        brelse(bp);
    8000327c:	854a                	mv	a0,s2
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	d98080e7          	jalr	-616(ra) # 80003016 <brelse>
  bp = bread(dev, bno);
    80003286:	85a6                	mv	a1,s1
    80003288:	855e                	mv	a0,s7
    8000328a:	00000097          	auipc	ra,0x0
    8000328e:	c5c080e7          	jalr	-932(ra) # 80002ee6 <bread>
    80003292:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003294:	40000613          	li	a2,1024
    80003298:	4581                	li	a1,0
    8000329a:	05850513          	addi	a0,a0,88
    8000329e:	ffffe097          	auipc	ra,0xffffe
    800032a2:	a5e080e7          	jalr	-1442(ra) # 80000cfc <memset>
  log_write(bp);
    800032a6:	854a                	mv	a0,s2
    800032a8:	00001097          	auipc	ra,0x1
    800032ac:	fde080e7          	jalr	-34(ra) # 80004286 <log_write>
  brelse(bp);
    800032b0:	854a                	mv	a0,s2
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	d64080e7          	jalr	-668(ra) # 80003016 <brelse>
}
    800032ba:	8526                	mv	a0,s1
    800032bc:	60e6                	ld	ra,88(sp)
    800032be:	6446                	ld	s0,80(sp)
    800032c0:	64a6                	ld	s1,72(sp)
    800032c2:	6906                	ld	s2,64(sp)
    800032c4:	79e2                	ld	s3,56(sp)
    800032c6:	7a42                	ld	s4,48(sp)
    800032c8:	7aa2                	ld	s5,40(sp)
    800032ca:	7b02                	ld	s6,32(sp)
    800032cc:	6be2                	ld	s7,24(sp)
    800032ce:	6c42                	ld	s8,16(sp)
    800032d0:	6ca2                	ld	s9,8(sp)
    800032d2:	6125                	addi	sp,sp,96
    800032d4:	8082                	ret

00000000800032d6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032d6:	7179                	addi	sp,sp,-48
    800032d8:	f406                	sd	ra,40(sp)
    800032da:	f022                	sd	s0,32(sp)
    800032dc:	ec26                	sd	s1,24(sp)
    800032de:	e84a                	sd	s2,16(sp)
    800032e0:	e44e                	sd	s3,8(sp)
    800032e2:	e052                	sd	s4,0(sp)
    800032e4:	1800                	addi	s0,sp,48
    800032e6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032e8:	47ad                	li	a5,11
    800032ea:	04b7fe63          	bgeu	a5,a1,80003346 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032ee:	ff45849b          	addiw	s1,a1,-12
    800032f2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032f6:	0ff00793          	li	a5,255
    800032fa:	0ae7e463          	bltu	a5,a4,800033a2 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032fe:	08052583          	lw	a1,128(a0)
    80003302:	c5b5                	beqz	a1,8000336e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003304:	00092503          	lw	a0,0(s2)
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	bde080e7          	jalr	-1058(ra) # 80002ee6 <bread>
    80003310:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003312:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003316:	02049713          	slli	a4,s1,0x20
    8000331a:	01e75593          	srli	a1,a4,0x1e
    8000331e:	00b784b3          	add	s1,a5,a1
    80003322:	0004a983          	lw	s3,0(s1)
    80003326:	04098e63          	beqz	s3,80003382 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000332a:	8552                	mv	a0,s4
    8000332c:	00000097          	auipc	ra,0x0
    80003330:	cea080e7          	jalr	-790(ra) # 80003016 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003334:	854e                	mv	a0,s3
    80003336:	70a2                	ld	ra,40(sp)
    80003338:	7402                	ld	s0,32(sp)
    8000333a:	64e2                	ld	s1,24(sp)
    8000333c:	6942                	ld	s2,16(sp)
    8000333e:	69a2                	ld	s3,8(sp)
    80003340:	6a02                	ld	s4,0(sp)
    80003342:	6145                	addi	sp,sp,48
    80003344:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003346:	02059793          	slli	a5,a1,0x20
    8000334a:	01e7d593          	srli	a1,a5,0x1e
    8000334e:	00b504b3          	add	s1,a0,a1
    80003352:	0504a983          	lw	s3,80(s1)
    80003356:	fc099fe3          	bnez	s3,80003334 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000335a:	4108                	lw	a0,0(a0)
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	e4c080e7          	jalr	-436(ra) # 800031a8 <balloc>
    80003364:	0005099b          	sext.w	s3,a0
    80003368:	0534a823          	sw	s3,80(s1)
    8000336c:	b7e1                	j	80003334 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000336e:	4108                	lw	a0,0(a0)
    80003370:	00000097          	auipc	ra,0x0
    80003374:	e38080e7          	jalr	-456(ra) # 800031a8 <balloc>
    80003378:	0005059b          	sext.w	a1,a0
    8000337c:	08b92023          	sw	a1,128(s2)
    80003380:	b751                	j	80003304 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003382:	00092503          	lw	a0,0(s2)
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	e22080e7          	jalr	-478(ra) # 800031a8 <balloc>
    8000338e:	0005099b          	sext.w	s3,a0
    80003392:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003396:	8552                	mv	a0,s4
    80003398:	00001097          	auipc	ra,0x1
    8000339c:	eee080e7          	jalr	-274(ra) # 80004286 <log_write>
    800033a0:	b769                	j	8000332a <bmap+0x54>
  panic("bmap: out of range");
    800033a2:	00005517          	auipc	a0,0x5
    800033a6:	13650513          	addi	a0,a0,310 # 800084d8 <syscalls+0x118>
    800033aa:	ffffd097          	auipc	ra,0xffffd
    800033ae:	19c080e7          	jalr	412(ra) # 80000546 <panic>

00000000800033b2 <iget>:
{
    800033b2:	7179                	addi	sp,sp,-48
    800033b4:	f406                	sd	ra,40(sp)
    800033b6:	f022                	sd	s0,32(sp)
    800033b8:	ec26                	sd	s1,24(sp)
    800033ba:	e84a                	sd	s2,16(sp)
    800033bc:	e44e                	sd	s3,8(sp)
    800033be:	e052                	sd	s4,0(sp)
    800033c0:	1800                	addi	s0,sp,48
    800033c2:	89aa                	mv	s3,a0
    800033c4:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800033c6:	0001d517          	auipc	a0,0x1d
    800033ca:	a9a50513          	addi	a0,a0,-1382 # 8001fe60 <icache>
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	832080e7          	jalr	-1998(ra) # 80000c00 <acquire>
  empty = 0;
    800033d6:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033d8:	0001d497          	auipc	s1,0x1d
    800033dc:	aa048493          	addi	s1,s1,-1376 # 8001fe78 <icache+0x18>
    800033e0:	0001e697          	auipc	a3,0x1e
    800033e4:	52868693          	addi	a3,a3,1320 # 80021908 <log>
    800033e8:	a039                	j	800033f6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ea:	02090b63          	beqz	s2,80003420 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033ee:	08848493          	addi	s1,s1,136
    800033f2:	02d48a63          	beq	s1,a3,80003426 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033f6:	449c                	lw	a5,8(s1)
    800033f8:	fef059e3          	blez	a5,800033ea <iget+0x38>
    800033fc:	4098                	lw	a4,0(s1)
    800033fe:	ff3716e3          	bne	a4,s3,800033ea <iget+0x38>
    80003402:	40d8                	lw	a4,4(s1)
    80003404:	ff4713e3          	bne	a4,s4,800033ea <iget+0x38>
      ip->ref++;
    80003408:	2785                	addiw	a5,a5,1
    8000340a:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000340c:	0001d517          	auipc	a0,0x1d
    80003410:	a5450513          	addi	a0,a0,-1452 # 8001fe60 <icache>
    80003414:	ffffe097          	auipc	ra,0xffffe
    80003418:	8a0080e7          	jalr	-1888(ra) # 80000cb4 <release>
      return ip;
    8000341c:	8926                	mv	s2,s1
    8000341e:	a03d                	j	8000344c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003420:	f7f9                	bnez	a5,800033ee <iget+0x3c>
    80003422:	8926                	mv	s2,s1
    80003424:	b7e9                	j	800033ee <iget+0x3c>
  if(empty == 0)
    80003426:	02090c63          	beqz	s2,8000345e <iget+0xac>
  ip->dev = dev;
    8000342a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000342e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003432:	4785                	li	a5,1
    80003434:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003438:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000343c:	0001d517          	auipc	a0,0x1d
    80003440:	a2450513          	addi	a0,a0,-1500 # 8001fe60 <icache>
    80003444:	ffffe097          	auipc	ra,0xffffe
    80003448:	870080e7          	jalr	-1936(ra) # 80000cb4 <release>
}
    8000344c:	854a                	mv	a0,s2
    8000344e:	70a2                	ld	ra,40(sp)
    80003450:	7402                	ld	s0,32(sp)
    80003452:	64e2                	ld	s1,24(sp)
    80003454:	6942                	ld	s2,16(sp)
    80003456:	69a2                	ld	s3,8(sp)
    80003458:	6a02                	ld	s4,0(sp)
    8000345a:	6145                	addi	sp,sp,48
    8000345c:	8082                	ret
    panic("iget: no inodes");
    8000345e:	00005517          	auipc	a0,0x5
    80003462:	09250513          	addi	a0,a0,146 # 800084f0 <syscalls+0x130>
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	0e0080e7          	jalr	224(ra) # 80000546 <panic>

000000008000346e <fsinit>:
fsinit(int dev) {
    8000346e:	7179                	addi	sp,sp,-48
    80003470:	f406                	sd	ra,40(sp)
    80003472:	f022                	sd	s0,32(sp)
    80003474:	ec26                	sd	s1,24(sp)
    80003476:	e84a                	sd	s2,16(sp)
    80003478:	e44e                	sd	s3,8(sp)
    8000347a:	1800                	addi	s0,sp,48
    8000347c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000347e:	4585                	li	a1,1
    80003480:	00000097          	auipc	ra,0x0
    80003484:	a66080e7          	jalr	-1434(ra) # 80002ee6 <bread>
    80003488:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000348a:	0001d997          	auipc	s3,0x1d
    8000348e:	9b698993          	addi	s3,s3,-1610 # 8001fe40 <sb>
    80003492:	02000613          	li	a2,32
    80003496:	05850593          	addi	a1,a0,88
    8000349a:	854e                	mv	a0,s3
    8000349c:	ffffe097          	auipc	ra,0xffffe
    800034a0:	8bc080e7          	jalr	-1860(ra) # 80000d58 <memmove>
  brelse(bp);
    800034a4:	8526                	mv	a0,s1
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	b70080e7          	jalr	-1168(ra) # 80003016 <brelse>
  if(sb.magic != FSMAGIC)
    800034ae:	0009a703          	lw	a4,0(s3)
    800034b2:	102037b7          	lui	a5,0x10203
    800034b6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034ba:	02f71263          	bne	a4,a5,800034de <fsinit+0x70>
  initlog(dev, &sb);
    800034be:	0001d597          	auipc	a1,0x1d
    800034c2:	98258593          	addi	a1,a1,-1662 # 8001fe40 <sb>
    800034c6:	854a                	mv	a0,s2
    800034c8:	00001097          	auipc	ra,0x1
    800034cc:	b46080e7          	jalr	-1210(ra) # 8000400e <initlog>
}
    800034d0:	70a2                	ld	ra,40(sp)
    800034d2:	7402                	ld	s0,32(sp)
    800034d4:	64e2                	ld	s1,24(sp)
    800034d6:	6942                	ld	s2,16(sp)
    800034d8:	69a2                	ld	s3,8(sp)
    800034da:	6145                	addi	sp,sp,48
    800034dc:	8082                	ret
    panic("invalid file system");
    800034de:	00005517          	auipc	a0,0x5
    800034e2:	02250513          	addi	a0,a0,34 # 80008500 <syscalls+0x140>
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	060080e7          	jalr	96(ra) # 80000546 <panic>

00000000800034ee <iinit>:
{
    800034ee:	7179                	addi	sp,sp,-48
    800034f0:	f406                	sd	ra,40(sp)
    800034f2:	f022                	sd	s0,32(sp)
    800034f4:	ec26                	sd	s1,24(sp)
    800034f6:	e84a                	sd	s2,16(sp)
    800034f8:	e44e                	sd	s3,8(sp)
    800034fa:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800034fc:	00005597          	auipc	a1,0x5
    80003500:	01c58593          	addi	a1,a1,28 # 80008518 <syscalls+0x158>
    80003504:	0001d517          	auipc	a0,0x1d
    80003508:	95c50513          	addi	a0,a0,-1700 # 8001fe60 <icache>
    8000350c:	ffffd097          	auipc	ra,0xffffd
    80003510:	664080e7          	jalr	1636(ra) # 80000b70 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003514:	0001d497          	auipc	s1,0x1d
    80003518:	97448493          	addi	s1,s1,-1676 # 8001fe88 <icache+0x28>
    8000351c:	0001e997          	auipc	s3,0x1e
    80003520:	3fc98993          	addi	s3,s3,1020 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003524:	00005917          	auipc	s2,0x5
    80003528:	ffc90913          	addi	s2,s2,-4 # 80008520 <syscalls+0x160>
    8000352c:	85ca                	mv	a1,s2
    8000352e:	8526                	mv	a0,s1
    80003530:	00001097          	auipc	ra,0x1
    80003534:	e42080e7          	jalr	-446(ra) # 80004372 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003538:	08848493          	addi	s1,s1,136
    8000353c:	ff3498e3          	bne	s1,s3,8000352c <iinit+0x3e>
}
    80003540:	70a2                	ld	ra,40(sp)
    80003542:	7402                	ld	s0,32(sp)
    80003544:	64e2                	ld	s1,24(sp)
    80003546:	6942                	ld	s2,16(sp)
    80003548:	69a2                	ld	s3,8(sp)
    8000354a:	6145                	addi	sp,sp,48
    8000354c:	8082                	ret

000000008000354e <ialloc>:
{
    8000354e:	715d                	addi	sp,sp,-80
    80003550:	e486                	sd	ra,72(sp)
    80003552:	e0a2                	sd	s0,64(sp)
    80003554:	fc26                	sd	s1,56(sp)
    80003556:	f84a                	sd	s2,48(sp)
    80003558:	f44e                	sd	s3,40(sp)
    8000355a:	f052                	sd	s4,32(sp)
    8000355c:	ec56                	sd	s5,24(sp)
    8000355e:	e85a                	sd	s6,16(sp)
    80003560:	e45e                	sd	s7,8(sp)
    80003562:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003564:	0001d717          	auipc	a4,0x1d
    80003568:	8e872703          	lw	a4,-1816(a4) # 8001fe4c <sb+0xc>
    8000356c:	4785                	li	a5,1
    8000356e:	04e7fa63          	bgeu	a5,a4,800035c2 <ialloc+0x74>
    80003572:	8aaa                	mv	s5,a0
    80003574:	8bae                	mv	s7,a1
    80003576:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003578:	0001da17          	auipc	s4,0x1d
    8000357c:	8c8a0a13          	addi	s4,s4,-1848 # 8001fe40 <sb>
    80003580:	00048b1b          	sext.w	s6,s1
    80003584:	0044d593          	srli	a1,s1,0x4
    80003588:	018a2783          	lw	a5,24(s4)
    8000358c:	9dbd                	addw	a1,a1,a5
    8000358e:	8556                	mv	a0,s5
    80003590:	00000097          	auipc	ra,0x0
    80003594:	956080e7          	jalr	-1706(ra) # 80002ee6 <bread>
    80003598:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000359a:	05850993          	addi	s3,a0,88
    8000359e:	00f4f793          	andi	a5,s1,15
    800035a2:	079a                	slli	a5,a5,0x6
    800035a4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035a6:	00099783          	lh	a5,0(s3)
    800035aa:	c785                	beqz	a5,800035d2 <ialloc+0x84>
    brelse(bp);
    800035ac:	00000097          	auipc	ra,0x0
    800035b0:	a6a080e7          	jalr	-1430(ra) # 80003016 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035b4:	0485                	addi	s1,s1,1
    800035b6:	00ca2703          	lw	a4,12(s4)
    800035ba:	0004879b          	sext.w	a5,s1
    800035be:	fce7e1e3          	bltu	a5,a4,80003580 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035c2:	00005517          	auipc	a0,0x5
    800035c6:	f6650513          	addi	a0,a0,-154 # 80008528 <syscalls+0x168>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	f7c080e7          	jalr	-132(ra) # 80000546 <panic>
      memset(dip, 0, sizeof(*dip));
    800035d2:	04000613          	li	a2,64
    800035d6:	4581                	li	a1,0
    800035d8:	854e                	mv	a0,s3
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	722080e7          	jalr	1826(ra) # 80000cfc <memset>
      dip->type = type;
    800035e2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035e6:	854a                	mv	a0,s2
    800035e8:	00001097          	auipc	ra,0x1
    800035ec:	c9e080e7          	jalr	-866(ra) # 80004286 <log_write>
      brelse(bp);
    800035f0:	854a                	mv	a0,s2
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	a24080e7          	jalr	-1500(ra) # 80003016 <brelse>
      return iget(dev, inum);
    800035fa:	85da                	mv	a1,s6
    800035fc:	8556                	mv	a0,s5
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	db4080e7          	jalr	-588(ra) # 800033b2 <iget>
}
    80003606:	60a6                	ld	ra,72(sp)
    80003608:	6406                	ld	s0,64(sp)
    8000360a:	74e2                	ld	s1,56(sp)
    8000360c:	7942                	ld	s2,48(sp)
    8000360e:	79a2                	ld	s3,40(sp)
    80003610:	7a02                	ld	s4,32(sp)
    80003612:	6ae2                	ld	s5,24(sp)
    80003614:	6b42                	ld	s6,16(sp)
    80003616:	6ba2                	ld	s7,8(sp)
    80003618:	6161                	addi	sp,sp,80
    8000361a:	8082                	ret

000000008000361c <iupdate>:
{
    8000361c:	1101                	addi	sp,sp,-32
    8000361e:	ec06                	sd	ra,24(sp)
    80003620:	e822                	sd	s0,16(sp)
    80003622:	e426                	sd	s1,8(sp)
    80003624:	e04a                	sd	s2,0(sp)
    80003626:	1000                	addi	s0,sp,32
    80003628:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000362a:	415c                	lw	a5,4(a0)
    8000362c:	0047d79b          	srliw	a5,a5,0x4
    80003630:	0001d597          	auipc	a1,0x1d
    80003634:	8285a583          	lw	a1,-2008(a1) # 8001fe58 <sb+0x18>
    80003638:	9dbd                	addw	a1,a1,a5
    8000363a:	4108                	lw	a0,0(a0)
    8000363c:	00000097          	auipc	ra,0x0
    80003640:	8aa080e7          	jalr	-1878(ra) # 80002ee6 <bread>
    80003644:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003646:	05850793          	addi	a5,a0,88
    8000364a:	40d8                	lw	a4,4(s1)
    8000364c:	8b3d                	andi	a4,a4,15
    8000364e:	071a                	slli	a4,a4,0x6
    80003650:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003652:	04449703          	lh	a4,68(s1)
    80003656:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000365a:	04649703          	lh	a4,70(s1)
    8000365e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003662:	04849703          	lh	a4,72(s1)
    80003666:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000366a:	04a49703          	lh	a4,74(s1)
    8000366e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003672:	44f8                	lw	a4,76(s1)
    80003674:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003676:	03400613          	li	a2,52
    8000367a:	05048593          	addi	a1,s1,80
    8000367e:	00c78513          	addi	a0,a5,12
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	6d6080e7          	jalr	1750(ra) # 80000d58 <memmove>
  log_write(bp);
    8000368a:	854a                	mv	a0,s2
    8000368c:	00001097          	auipc	ra,0x1
    80003690:	bfa080e7          	jalr	-1030(ra) # 80004286 <log_write>
  brelse(bp);
    80003694:	854a                	mv	a0,s2
    80003696:	00000097          	auipc	ra,0x0
    8000369a:	980080e7          	jalr	-1664(ra) # 80003016 <brelse>
}
    8000369e:	60e2                	ld	ra,24(sp)
    800036a0:	6442                	ld	s0,16(sp)
    800036a2:	64a2                	ld	s1,8(sp)
    800036a4:	6902                	ld	s2,0(sp)
    800036a6:	6105                	addi	sp,sp,32
    800036a8:	8082                	ret

00000000800036aa <idup>:
{
    800036aa:	1101                	addi	sp,sp,-32
    800036ac:	ec06                	sd	ra,24(sp)
    800036ae:	e822                	sd	s0,16(sp)
    800036b0:	e426                	sd	s1,8(sp)
    800036b2:	1000                	addi	s0,sp,32
    800036b4:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800036b6:	0001c517          	auipc	a0,0x1c
    800036ba:	7aa50513          	addi	a0,a0,1962 # 8001fe60 <icache>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	542080e7          	jalr	1346(ra) # 80000c00 <acquire>
  ip->ref++;
    800036c6:	449c                	lw	a5,8(s1)
    800036c8:	2785                	addiw	a5,a5,1
    800036ca:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800036cc:	0001c517          	auipc	a0,0x1c
    800036d0:	79450513          	addi	a0,a0,1940 # 8001fe60 <icache>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	5e0080e7          	jalr	1504(ra) # 80000cb4 <release>
}
    800036dc:	8526                	mv	a0,s1
    800036de:	60e2                	ld	ra,24(sp)
    800036e0:	6442                	ld	s0,16(sp)
    800036e2:	64a2                	ld	s1,8(sp)
    800036e4:	6105                	addi	sp,sp,32
    800036e6:	8082                	ret

00000000800036e8 <ilock>:
{
    800036e8:	1101                	addi	sp,sp,-32
    800036ea:	ec06                	sd	ra,24(sp)
    800036ec:	e822                	sd	s0,16(sp)
    800036ee:	e426                	sd	s1,8(sp)
    800036f0:	e04a                	sd	s2,0(sp)
    800036f2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036f4:	c115                	beqz	a0,80003718 <ilock+0x30>
    800036f6:	84aa                	mv	s1,a0
    800036f8:	451c                	lw	a5,8(a0)
    800036fa:	00f05f63          	blez	a5,80003718 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036fe:	0541                	addi	a0,a0,16
    80003700:	00001097          	auipc	ra,0x1
    80003704:	cac080e7          	jalr	-852(ra) # 800043ac <acquiresleep>
  if(ip->valid == 0){
    80003708:	40bc                	lw	a5,64(s1)
    8000370a:	cf99                	beqz	a5,80003728 <ilock+0x40>
}
    8000370c:	60e2                	ld	ra,24(sp)
    8000370e:	6442                	ld	s0,16(sp)
    80003710:	64a2                	ld	s1,8(sp)
    80003712:	6902                	ld	s2,0(sp)
    80003714:	6105                	addi	sp,sp,32
    80003716:	8082                	ret
    panic("ilock");
    80003718:	00005517          	auipc	a0,0x5
    8000371c:	e2850513          	addi	a0,a0,-472 # 80008540 <syscalls+0x180>
    80003720:	ffffd097          	auipc	ra,0xffffd
    80003724:	e26080e7          	jalr	-474(ra) # 80000546 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003728:	40dc                	lw	a5,4(s1)
    8000372a:	0047d79b          	srliw	a5,a5,0x4
    8000372e:	0001c597          	auipc	a1,0x1c
    80003732:	72a5a583          	lw	a1,1834(a1) # 8001fe58 <sb+0x18>
    80003736:	9dbd                	addw	a1,a1,a5
    80003738:	4088                	lw	a0,0(s1)
    8000373a:	fffff097          	auipc	ra,0xfffff
    8000373e:	7ac080e7          	jalr	1964(ra) # 80002ee6 <bread>
    80003742:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003744:	05850593          	addi	a1,a0,88
    80003748:	40dc                	lw	a5,4(s1)
    8000374a:	8bbd                	andi	a5,a5,15
    8000374c:	079a                	slli	a5,a5,0x6
    8000374e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003750:	00059783          	lh	a5,0(a1)
    80003754:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003758:	00259783          	lh	a5,2(a1)
    8000375c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003760:	00459783          	lh	a5,4(a1)
    80003764:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003768:	00659783          	lh	a5,6(a1)
    8000376c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003770:	459c                	lw	a5,8(a1)
    80003772:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003774:	03400613          	li	a2,52
    80003778:	05b1                	addi	a1,a1,12
    8000377a:	05048513          	addi	a0,s1,80
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	5da080e7          	jalr	1498(ra) # 80000d58 <memmove>
    brelse(bp);
    80003786:	854a                	mv	a0,s2
    80003788:	00000097          	auipc	ra,0x0
    8000378c:	88e080e7          	jalr	-1906(ra) # 80003016 <brelse>
    ip->valid = 1;
    80003790:	4785                	li	a5,1
    80003792:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003794:	04449783          	lh	a5,68(s1)
    80003798:	fbb5                	bnez	a5,8000370c <ilock+0x24>
      panic("ilock: no type");
    8000379a:	00005517          	auipc	a0,0x5
    8000379e:	dae50513          	addi	a0,a0,-594 # 80008548 <syscalls+0x188>
    800037a2:	ffffd097          	auipc	ra,0xffffd
    800037a6:	da4080e7          	jalr	-604(ra) # 80000546 <panic>

00000000800037aa <iunlock>:
{
    800037aa:	1101                	addi	sp,sp,-32
    800037ac:	ec06                	sd	ra,24(sp)
    800037ae:	e822                	sd	s0,16(sp)
    800037b0:	e426                	sd	s1,8(sp)
    800037b2:	e04a                	sd	s2,0(sp)
    800037b4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037b6:	c905                	beqz	a0,800037e6 <iunlock+0x3c>
    800037b8:	84aa                	mv	s1,a0
    800037ba:	01050913          	addi	s2,a0,16
    800037be:	854a                	mv	a0,s2
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	c86080e7          	jalr	-890(ra) # 80004446 <holdingsleep>
    800037c8:	cd19                	beqz	a0,800037e6 <iunlock+0x3c>
    800037ca:	449c                	lw	a5,8(s1)
    800037cc:	00f05d63          	blez	a5,800037e6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037d0:	854a                	mv	a0,s2
    800037d2:	00001097          	auipc	ra,0x1
    800037d6:	c30080e7          	jalr	-976(ra) # 80004402 <releasesleep>
}
    800037da:	60e2                	ld	ra,24(sp)
    800037dc:	6442                	ld	s0,16(sp)
    800037de:	64a2                	ld	s1,8(sp)
    800037e0:	6902                	ld	s2,0(sp)
    800037e2:	6105                	addi	sp,sp,32
    800037e4:	8082                	ret
    panic("iunlock");
    800037e6:	00005517          	auipc	a0,0x5
    800037ea:	d7250513          	addi	a0,a0,-654 # 80008558 <syscalls+0x198>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	d58080e7          	jalr	-680(ra) # 80000546 <panic>

00000000800037f6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037f6:	7179                	addi	sp,sp,-48
    800037f8:	f406                	sd	ra,40(sp)
    800037fa:	f022                	sd	s0,32(sp)
    800037fc:	ec26                	sd	s1,24(sp)
    800037fe:	e84a                	sd	s2,16(sp)
    80003800:	e44e                	sd	s3,8(sp)
    80003802:	e052                	sd	s4,0(sp)
    80003804:	1800                	addi	s0,sp,48
    80003806:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003808:	05050493          	addi	s1,a0,80
    8000380c:	08050913          	addi	s2,a0,128
    80003810:	a021                	j	80003818 <itrunc+0x22>
    80003812:	0491                	addi	s1,s1,4
    80003814:	01248d63          	beq	s1,s2,8000382e <itrunc+0x38>
    if(ip->addrs[i]){
    80003818:	408c                	lw	a1,0(s1)
    8000381a:	dde5                	beqz	a1,80003812 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000381c:	0009a503          	lw	a0,0(s3)
    80003820:	00000097          	auipc	ra,0x0
    80003824:	90c080e7          	jalr	-1780(ra) # 8000312c <bfree>
      ip->addrs[i] = 0;
    80003828:	0004a023          	sw	zero,0(s1)
    8000382c:	b7dd                	j	80003812 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000382e:	0809a583          	lw	a1,128(s3)
    80003832:	e185                	bnez	a1,80003852 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003834:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003838:	854e                	mv	a0,s3
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	de2080e7          	jalr	-542(ra) # 8000361c <iupdate>
}
    80003842:	70a2                	ld	ra,40(sp)
    80003844:	7402                	ld	s0,32(sp)
    80003846:	64e2                	ld	s1,24(sp)
    80003848:	6942                	ld	s2,16(sp)
    8000384a:	69a2                	ld	s3,8(sp)
    8000384c:	6a02                	ld	s4,0(sp)
    8000384e:	6145                	addi	sp,sp,48
    80003850:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003852:	0009a503          	lw	a0,0(s3)
    80003856:	fffff097          	auipc	ra,0xfffff
    8000385a:	690080e7          	jalr	1680(ra) # 80002ee6 <bread>
    8000385e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003860:	05850493          	addi	s1,a0,88
    80003864:	45850913          	addi	s2,a0,1112
    80003868:	a021                	j	80003870 <itrunc+0x7a>
    8000386a:	0491                	addi	s1,s1,4
    8000386c:	01248b63          	beq	s1,s2,80003882 <itrunc+0x8c>
      if(a[j])
    80003870:	408c                	lw	a1,0(s1)
    80003872:	dde5                	beqz	a1,8000386a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003874:	0009a503          	lw	a0,0(s3)
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	8b4080e7          	jalr	-1868(ra) # 8000312c <bfree>
    80003880:	b7ed                	j	8000386a <itrunc+0x74>
    brelse(bp);
    80003882:	8552                	mv	a0,s4
    80003884:	fffff097          	auipc	ra,0xfffff
    80003888:	792080e7          	jalr	1938(ra) # 80003016 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000388c:	0809a583          	lw	a1,128(s3)
    80003890:	0009a503          	lw	a0,0(s3)
    80003894:	00000097          	auipc	ra,0x0
    80003898:	898080e7          	jalr	-1896(ra) # 8000312c <bfree>
    ip->addrs[NDIRECT] = 0;
    8000389c:	0809a023          	sw	zero,128(s3)
    800038a0:	bf51                	j	80003834 <itrunc+0x3e>

00000000800038a2 <iput>:
{
    800038a2:	1101                	addi	sp,sp,-32
    800038a4:	ec06                	sd	ra,24(sp)
    800038a6:	e822                	sd	s0,16(sp)
    800038a8:	e426                	sd	s1,8(sp)
    800038aa:	e04a                	sd	s2,0(sp)
    800038ac:	1000                	addi	s0,sp,32
    800038ae:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038b0:	0001c517          	auipc	a0,0x1c
    800038b4:	5b050513          	addi	a0,a0,1456 # 8001fe60 <icache>
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	348080e7          	jalr	840(ra) # 80000c00 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038c0:	4498                	lw	a4,8(s1)
    800038c2:	4785                	li	a5,1
    800038c4:	02f70363          	beq	a4,a5,800038ea <iput+0x48>
  ip->ref--;
    800038c8:	449c                	lw	a5,8(s1)
    800038ca:	37fd                	addiw	a5,a5,-1
    800038cc:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038ce:	0001c517          	auipc	a0,0x1c
    800038d2:	59250513          	addi	a0,a0,1426 # 8001fe60 <icache>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	3de080e7          	jalr	990(ra) # 80000cb4 <release>
}
    800038de:	60e2                	ld	ra,24(sp)
    800038e0:	6442                	ld	s0,16(sp)
    800038e2:	64a2                	ld	s1,8(sp)
    800038e4:	6902                	ld	s2,0(sp)
    800038e6:	6105                	addi	sp,sp,32
    800038e8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038ea:	40bc                	lw	a5,64(s1)
    800038ec:	dff1                	beqz	a5,800038c8 <iput+0x26>
    800038ee:	04a49783          	lh	a5,74(s1)
    800038f2:	fbf9                	bnez	a5,800038c8 <iput+0x26>
    acquiresleep(&ip->lock);
    800038f4:	01048913          	addi	s2,s1,16
    800038f8:	854a                	mv	a0,s2
    800038fa:	00001097          	auipc	ra,0x1
    800038fe:	ab2080e7          	jalr	-1358(ra) # 800043ac <acquiresleep>
    release(&icache.lock);
    80003902:	0001c517          	auipc	a0,0x1c
    80003906:	55e50513          	addi	a0,a0,1374 # 8001fe60 <icache>
    8000390a:	ffffd097          	auipc	ra,0xffffd
    8000390e:	3aa080e7          	jalr	938(ra) # 80000cb4 <release>
    itrunc(ip);
    80003912:	8526                	mv	a0,s1
    80003914:	00000097          	auipc	ra,0x0
    80003918:	ee2080e7          	jalr	-286(ra) # 800037f6 <itrunc>
    ip->type = 0;
    8000391c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003920:	8526                	mv	a0,s1
    80003922:	00000097          	auipc	ra,0x0
    80003926:	cfa080e7          	jalr	-774(ra) # 8000361c <iupdate>
    ip->valid = 0;
    8000392a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000392e:	854a                	mv	a0,s2
    80003930:	00001097          	auipc	ra,0x1
    80003934:	ad2080e7          	jalr	-1326(ra) # 80004402 <releasesleep>
    acquire(&icache.lock);
    80003938:	0001c517          	auipc	a0,0x1c
    8000393c:	52850513          	addi	a0,a0,1320 # 8001fe60 <icache>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	2c0080e7          	jalr	704(ra) # 80000c00 <acquire>
    80003948:	b741                	j	800038c8 <iput+0x26>

000000008000394a <iunlockput>:
{
    8000394a:	1101                	addi	sp,sp,-32
    8000394c:	ec06                	sd	ra,24(sp)
    8000394e:	e822                	sd	s0,16(sp)
    80003950:	e426                	sd	s1,8(sp)
    80003952:	1000                	addi	s0,sp,32
    80003954:	84aa                	mv	s1,a0
  iunlock(ip);
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	e54080e7          	jalr	-428(ra) # 800037aa <iunlock>
  iput(ip);
    8000395e:	8526                	mv	a0,s1
    80003960:	00000097          	auipc	ra,0x0
    80003964:	f42080e7          	jalr	-190(ra) # 800038a2 <iput>
}
    80003968:	60e2                	ld	ra,24(sp)
    8000396a:	6442                	ld	s0,16(sp)
    8000396c:	64a2                	ld	s1,8(sp)
    8000396e:	6105                	addi	sp,sp,32
    80003970:	8082                	ret

0000000080003972 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003972:	1141                	addi	sp,sp,-16
    80003974:	e422                	sd	s0,8(sp)
    80003976:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003978:	411c                	lw	a5,0(a0)
    8000397a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000397c:	415c                	lw	a5,4(a0)
    8000397e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003980:	04451783          	lh	a5,68(a0)
    80003984:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003988:	04a51783          	lh	a5,74(a0)
    8000398c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003990:	04c56783          	lwu	a5,76(a0)
    80003994:	e99c                	sd	a5,16(a1)
}
    80003996:	6422                	ld	s0,8(sp)
    80003998:	0141                	addi	sp,sp,16
    8000399a:	8082                	ret

000000008000399c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000399c:	457c                	lw	a5,76(a0)
    8000399e:	0ed7e963          	bltu	a5,a3,80003a90 <readi+0xf4>
{
    800039a2:	7159                	addi	sp,sp,-112
    800039a4:	f486                	sd	ra,104(sp)
    800039a6:	f0a2                	sd	s0,96(sp)
    800039a8:	eca6                	sd	s1,88(sp)
    800039aa:	e8ca                	sd	s2,80(sp)
    800039ac:	e4ce                	sd	s3,72(sp)
    800039ae:	e0d2                	sd	s4,64(sp)
    800039b0:	fc56                	sd	s5,56(sp)
    800039b2:	f85a                	sd	s6,48(sp)
    800039b4:	f45e                	sd	s7,40(sp)
    800039b6:	f062                	sd	s8,32(sp)
    800039b8:	ec66                	sd	s9,24(sp)
    800039ba:	e86a                	sd	s10,16(sp)
    800039bc:	e46e                	sd	s11,8(sp)
    800039be:	1880                	addi	s0,sp,112
    800039c0:	8baa                	mv	s7,a0
    800039c2:	8c2e                	mv	s8,a1
    800039c4:	8ab2                	mv	s5,a2
    800039c6:	84b6                	mv	s1,a3
    800039c8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039ca:	9f35                	addw	a4,a4,a3
    return 0;
    800039cc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039ce:	0ad76063          	bltu	a4,a3,80003a6e <readi+0xd2>
  if(off + n > ip->size)
    800039d2:	00e7f463          	bgeu	a5,a4,800039da <readi+0x3e>
    n = ip->size - off;
    800039d6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039da:	0a0b0963          	beqz	s6,80003a8c <readi+0xf0>
    800039de:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039e0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039e4:	5cfd                	li	s9,-1
    800039e6:	a82d                	j	80003a20 <readi+0x84>
    800039e8:	020a1d93          	slli	s11,s4,0x20
    800039ec:	020ddd93          	srli	s11,s11,0x20
    800039f0:	05890613          	addi	a2,s2,88
    800039f4:	86ee                	mv	a3,s11
    800039f6:	963a                	add	a2,a2,a4
    800039f8:	85d6                	mv	a1,s5
    800039fa:	8562                	mv	a0,s8
    800039fc:	fffff097          	auipc	ra,0xfffff
    80003a00:	a84080e7          	jalr	-1404(ra) # 80002480 <either_copyout>
    80003a04:	05950d63          	beq	a0,s9,80003a5e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a08:	854a                	mv	a0,s2
    80003a0a:	fffff097          	auipc	ra,0xfffff
    80003a0e:	60c080e7          	jalr	1548(ra) # 80003016 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a12:	013a09bb          	addw	s3,s4,s3
    80003a16:	009a04bb          	addw	s1,s4,s1
    80003a1a:	9aee                	add	s5,s5,s11
    80003a1c:	0569f763          	bgeu	s3,s6,80003a6a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a20:	000ba903          	lw	s2,0(s7)
    80003a24:	00a4d59b          	srliw	a1,s1,0xa
    80003a28:	855e                	mv	a0,s7
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	8ac080e7          	jalr	-1876(ra) # 800032d6 <bmap>
    80003a32:	0005059b          	sext.w	a1,a0
    80003a36:	854a                	mv	a0,s2
    80003a38:	fffff097          	auipc	ra,0xfffff
    80003a3c:	4ae080e7          	jalr	1198(ra) # 80002ee6 <bread>
    80003a40:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a42:	3ff4f713          	andi	a4,s1,1023
    80003a46:	40ed07bb          	subw	a5,s10,a4
    80003a4a:	413b06bb          	subw	a3,s6,s3
    80003a4e:	8a3e                	mv	s4,a5
    80003a50:	2781                	sext.w	a5,a5
    80003a52:	0006861b          	sext.w	a2,a3
    80003a56:	f8f679e3          	bgeu	a2,a5,800039e8 <readi+0x4c>
    80003a5a:	8a36                	mv	s4,a3
    80003a5c:	b771                	j	800039e8 <readi+0x4c>
      brelse(bp);
    80003a5e:	854a                	mv	a0,s2
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	5b6080e7          	jalr	1462(ra) # 80003016 <brelse>
      tot = -1;
    80003a68:	59fd                	li	s3,-1
  }
  return tot;
    80003a6a:	0009851b          	sext.w	a0,s3
}
    80003a6e:	70a6                	ld	ra,104(sp)
    80003a70:	7406                	ld	s0,96(sp)
    80003a72:	64e6                	ld	s1,88(sp)
    80003a74:	6946                	ld	s2,80(sp)
    80003a76:	69a6                	ld	s3,72(sp)
    80003a78:	6a06                	ld	s4,64(sp)
    80003a7a:	7ae2                	ld	s5,56(sp)
    80003a7c:	7b42                	ld	s6,48(sp)
    80003a7e:	7ba2                	ld	s7,40(sp)
    80003a80:	7c02                	ld	s8,32(sp)
    80003a82:	6ce2                	ld	s9,24(sp)
    80003a84:	6d42                	ld	s10,16(sp)
    80003a86:	6da2                	ld	s11,8(sp)
    80003a88:	6165                	addi	sp,sp,112
    80003a8a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a8c:	89da                	mv	s3,s6
    80003a8e:	bff1                	j	80003a6a <readi+0xce>
    return 0;
    80003a90:	4501                	li	a0,0
}
    80003a92:	8082                	ret

0000000080003a94 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a94:	457c                	lw	a5,76(a0)
    80003a96:	10d7e763          	bltu	a5,a3,80003ba4 <writei+0x110>
{
    80003a9a:	7159                	addi	sp,sp,-112
    80003a9c:	f486                	sd	ra,104(sp)
    80003a9e:	f0a2                	sd	s0,96(sp)
    80003aa0:	eca6                	sd	s1,88(sp)
    80003aa2:	e8ca                	sd	s2,80(sp)
    80003aa4:	e4ce                	sd	s3,72(sp)
    80003aa6:	e0d2                	sd	s4,64(sp)
    80003aa8:	fc56                	sd	s5,56(sp)
    80003aaa:	f85a                	sd	s6,48(sp)
    80003aac:	f45e                	sd	s7,40(sp)
    80003aae:	f062                	sd	s8,32(sp)
    80003ab0:	ec66                	sd	s9,24(sp)
    80003ab2:	e86a                	sd	s10,16(sp)
    80003ab4:	e46e                	sd	s11,8(sp)
    80003ab6:	1880                	addi	s0,sp,112
    80003ab8:	8baa                	mv	s7,a0
    80003aba:	8c2e                	mv	s8,a1
    80003abc:	8ab2                	mv	s5,a2
    80003abe:	8936                	mv	s2,a3
    80003ac0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ac2:	00e687bb          	addw	a5,a3,a4
    80003ac6:	0ed7e163          	bltu	a5,a3,80003ba8 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003aca:	00043737          	lui	a4,0x43
    80003ace:	0cf76f63          	bltu	a4,a5,80003bac <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ad2:	0a0b0863          	beqz	s6,80003b82 <writei+0xee>
    80003ad6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003adc:	5cfd                	li	s9,-1
    80003ade:	a091                	j	80003b22 <writei+0x8e>
    80003ae0:	02099d93          	slli	s11,s3,0x20
    80003ae4:	020ddd93          	srli	s11,s11,0x20
    80003ae8:	05848513          	addi	a0,s1,88
    80003aec:	86ee                	mv	a3,s11
    80003aee:	8656                	mv	a2,s5
    80003af0:	85e2                	mv	a1,s8
    80003af2:	953a                	add	a0,a0,a4
    80003af4:	fffff097          	auipc	ra,0xfffff
    80003af8:	9e2080e7          	jalr	-1566(ra) # 800024d6 <either_copyin>
    80003afc:	07950263          	beq	a0,s9,80003b60 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003b00:	8526                	mv	a0,s1
    80003b02:	00000097          	auipc	ra,0x0
    80003b06:	784080e7          	jalr	1924(ra) # 80004286 <log_write>
    brelse(bp);
    80003b0a:	8526                	mv	a0,s1
    80003b0c:	fffff097          	auipc	ra,0xfffff
    80003b10:	50a080e7          	jalr	1290(ra) # 80003016 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b14:	01498a3b          	addw	s4,s3,s4
    80003b18:	0129893b          	addw	s2,s3,s2
    80003b1c:	9aee                	add	s5,s5,s11
    80003b1e:	056a7763          	bgeu	s4,s6,80003b6c <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b22:	000ba483          	lw	s1,0(s7)
    80003b26:	00a9559b          	srliw	a1,s2,0xa
    80003b2a:	855e                	mv	a0,s7
    80003b2c:	fffff097          	auipc	ra,0xfffff
    80003b30:	7aa080e7          	jalr	1962(ra) # 800032d6 <bmap>
    80003b34:	0005059b          	sext.w	a1,a0
    80003b38:	8526                	mv	a0,s1
    80003b3a:	fffff097          	auipc	ra,0xfffff
    80003b3e:	3ac080e7          	jalr	940(ra) # 80002ee6 <bread>
    80003b42:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b44:	3ff97713          	andi	a4,s2,1023
    80003b48:	40ed07bb          	subw	a5,s10,a4
    80003b4c:	414b06bb          	subw	a3,s6,s4
    80003b50:	89be                	mv	s3,a5
    80003b52:	2781                	sext.w	a5,a5
    80003b54:	0006861b          	sext.w	a2,a3
    80003b58:	f8f674e3          	bgeu	a2,a5,80003ae0 <writei+0x4c>
    80003b5c:	89b6                	mv	s3,a3
    80003b5e:	b749                	j	80003ae0 <writei+0x4c>
      brelse(bp);
    80003b60:	8526                	mv	a0,s1
    80003b62:	fffff097          	auipc	ra,0xfffff
    80003b66:	4b4080e7          	jalr	1204(ra) # 80003016 <brelse>
      n = -1;
    80003b6a:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003b6c:	04cba783          	lw	a5,76(s7)
    80003b70:	0127f463          	bgeu	a5,s2,80003b78 <writei+0xe4>
      ip->size = off;
    80003b74:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b78:	855e                	mv	a0,s7
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	aa2080e7          	jalr	-1374(ra) # 8000361c <iupdate>
  }

  return n;
    80003b82:	000b051b          	sext.w	a0,s6
}
    80003b86:	70a6                	ld	ra,104(sp)
    80003b88:	7406                	ld	s0,96(sp)
    80003b8a:	64e6                	ld	s1,88(sp)
    80003b8c:	6946                	ld	s2,80(sp)
    80003b8e:	69a6                	ld	s3,72(sp)
    80003b90:	6a06                	ld	s4,64(sp)
    80003b92:	7ae2                	ld	s5,56(sp)
    80003b94:	7b42                	ld	s6,48(sp)
    80003b96:	7ba2                	ld	s7,40(sp)
    80003b98:	7c02                	ld	s8,32(sp)
    80003b9a:	6ce2                	ld	s9,24(sp)
    80003b9c:	6d42                	ld	s10,16(sp)
    80003b9e:	6da2                	ld	s11,8(sp)
    80003ba0:	6165                	addi	sp,sp,112
    80003ba2:	8082                	ret
    return -1;
    80003ba4:	557d                	li	a0,-1
}
    80003ba6:	8082                	ret
    return -1;
    80003ba8:	557d                	li	a0,-1
    80003baa:	bff1                	j	80003b86 <writei+0xf2>
    return -1;
    80003bac:	557d                	li	a0,-1
    80003bae:	bfe1                	j	80003b86 <writei+0xf2>

0000000080003bb0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bb0:	1141                	addi	sp,sp,-16
    80003bb2:	e406                	sd	ra,8(sp)
    80003bb4:	e022                	sd	s0,0(sp)
    80003bb6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bb8:	4639                	li	a2,14
    80003bba:	ffffd097          	auipc	ra,0xffffd
    80003bbe:	21a080e7          	jalr	538(ra) # 80000dd4 <strncmp>
}
    80003bc2:	60a2                	ld	ra,8(sp)
    80003bc4:	6402                	ld	s0,0(sp)
    80003bc6:	0141                	addi	sp,sp,16
    80003bc8:	8082                	ret

0000000080003bca <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003bca:	7139                	addi	sp,sp,-64
    80003bcc:	fc06                	sd	ra,56(sp)
    80003bce:	f822                	sd	s0,48(sp)
    80003bd0:	f426                	sd	s1,40(sp)
    80003bd2:	f04a                	sd	s2,32(sp)
    80003bd4:	ec4e                	sd	s3,24(sp)
    80003bd6:	e852                	sd	s4,16(sp)
    80003bd8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bda:	04451703          	lh	a4,68(a0)
    80003bde:	4785                	li	a5,1
    80003be0:	00f71a63          	bne	a4,a5,80003bf4 <dirlookup+0x2a>
    80003be4:	892a                	mv	s2,a0
    80003be6:	89ae                	mv	s3,a1
    80003be8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bea:	457c                	lw	a5,76(a0)
    80003bec:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bee:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bf0:	e79d                	bnez	a5,80003c1e <dirlookup+0x54>
    80003bf2:	a8a5                	j	80003c6a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bf4:	00005517          	auipc	a0,0x5
    80003bf8:	96c50513          	addi	a0,a0,-1684 # 80008560 <syscalls+0x1a0>
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	94a080e7          	jalr	-1718(ra) # 80000546 <panic>
      panic("dirlookup read");
    80003c04:	00005517          	auipc	a0,0x5
    80003c08:	97450513          	addi	a0,a0,-1676 # 80008578 <syscalls+0x1b8>
    80003c0c:	ffffd097          	auipc	ra,0xffffd
    80003c10:	93a080e7          	jalr	-1734(ra) # 80000546 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c14:	24c1                	addiw	s1,s1,16
    80003c16:	04c92783          	lw	a5,76(s2)
    80003c1a:	04f4f763          	bgeu	s1,a5,80003c68 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c1e:	4741                	li	a4,16
    80003c20:	86a6                	mv	a3,s1
    80003c22:	fc040613          	addi	a2,s0,-64
    80003c26:	4581                	li	a1,0
    80003c28:	854a                	mv	a0,s2
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	d72080e7          	jalr	-654(ra) # 8000399c <readi>
    80003c32:	47c1                	li	a5,16
    80003c34:	fcf518e3          	bne	a0,a5,80003c04 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c38:	fc045783          	lhu	a5,-64(s0)
    80003c3c:	dfe1                	beqz	a5,80003c14 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c3e:	fc240593          	addi	a1,s0,-62
    80003c42:	854e                	mv	a0,s3
    80003c44:	00000097          	auipc	ra,0x0
    80003c48:	f6c080e7          	jalr	-148(ra) # 80003bb0 <namecmp>
    80003c4c:	f561                	bnez	a0,80003c14 <dirlookup+0x4a>
      if(poff)
    80003c4e:	000a0463          	beqz	s4,80003c56 <dirlookup+0x8c>
        *poff = off;
    80003c52:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c56:	fc045583          	lhu	a1,-64(s0)
    80003c5a:	00092503          	lw	a0,0(s2)
    80003c5e:	fffff097          	auipc	ra,0xfffff
    80003c62:	754080e7          	jalr	1876(ra) # 800033b2 <iget>
    80003c66:	a011                	j	80003c6a <dirlookup+0xa0>
  return 0;
    80003c68:	4501                	li	a0,0
}
    80003c6a:	70e2                	ld	ra,56(sp)
    80003c6c:	7442                	ld	s0,48(sp)
    80003c6e:	74a2                	ld	s1,40(sp)
    80003c70:	7902                	ld	s2,32(sp)
    80003c72:	69e2                	ld	s3,24(sp)
    80003c74:	6a42                	ld	s4,16(sp)
    80003c76:	6121                	addi	sp,sp,64
    80003c78:	8082                	ret

0000000080003c7a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c7a:	711d                	addi	sp,sp,-96
    80003c7c:	ec86                	sd	ra,88(sp)
    80003c7e:	e8a2                	sd	s0,80(sp)
    80003c80:	e4a6                	sd	s1,72(sp)
    80003c82:	e0ca                	sd	s2,64(sp)
    80003c84:	fc4e                	sd	s3,56(sp)
    80003c86:	f852                	sd	s4,48(sp)
    80003c88:	f456                	sd	s5,40(sp)
    80003c8a:	f05a                	sd	s6,32(sp)
    80003c8c:	ec5e                	sd	s7,24(sp)
    80003c8e:	e862                	sd	s8,16(sp)
    80003c90:	e466                	sd	s9,8(sp)
    80003c92:	e06a                	sd	s10,0(sp)
    80003c94:	1080                	addi	s0,sp,96
    80003c96:	84aa                	mv	s1,a0
    80003c98:	8b2e                	mv	s6,a1
    80003c9a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c9c:	00054703          	lbu	a4,0(a0)
    80003ca0:	02f00793          	li	a5,47
    80003ca4:	02f70363          	beq	a4,a5,80003cca <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ca8:	ffffe097          	auipc	ra,0xffffe
    80003cac:	d66080e7          	jalr	-666(ra) # 80001a0e <myproc>
    80003cb0:	15053503          	ld	a0,336(a0)
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	9f6080e7          	jalr	-1546(ra) # 800036aa <idup>
    80003cbc:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003cbe:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003cc2:	4cb5                	li	s9,13
  len = path - s;
    80003cc4:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003cc6:	4c05                	li	s8,1
    80003cc8:	a87d                	j	80003d86 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003cca:	4585                	li	a1,1
    80003ccc:	4505                	li	a0,1
    80003cce:	fffff097          	auipc	ra,0xfffff
    80003cd2:	6e4080e7          	jalr	1764(ra) # 800033b2 <iget>
    80003cd6:	8a2a                	mv	s4,a0
    80003cd8:	b7dd                	j	80003cbe <namex+0x44>
      iunlockput(ip);
    80003cda:	8552                	mv	a0,s4
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	c6e080e7          	jalr	-914(ra) # 8000394a <iunlockput>
      return 0;
    80003ce4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ce6:	8552                	mv	a0,s4
    80003ce8:	60e6                	ld	ra,88(sp)
    80003cea:	6446                	ld	s0,80(sp)
    80003cec:	64a6                	ld	s1,72(sp)
    80003cee:	6906                	ld	s2,64(sp)
    80003cf0:	79e2                	ld	s3,56(sp)
    80003cf2:	7a42                	ld	s4,48(sp)
    80003cf4:	7aa2                	ld	s5,40(sp)
    80003cf6:	7b02                	ld	s6,32(sp)
    80003cf8:	6be2                	ld	s7,24(sp)
    80003cfa:	6c42                	ld	s8,16(sp)
    80003cfc:	6ca2                	ld	s9,8(sp)
    80003cfe:	6d02                	ld	s10,0(sp)
    80003d00:	6125                	addi	sp,sp,96
    80003d02:	8082                	ret
      iunlock(ip);
    80003d04:	8552                	mv	a0,s4
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	aa4080e7          	jalr	-1372(ra) # 800037aa <iunlock>
      return ip;
    80003d0e:	bfe1                	j	80003ce6 <namex+0x6c>
      iunlockput(ip);
    80003d10:	8552                	mv	a0,s4
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	c38080e7          	jalr	-968(ra) # 8000394a <iunlockput>
      return 0;
    80003d1a:	8a4e                	mv	s4,s3
    80003d1c:	b7e9                	j	80003ce6 <namex+0x6c>
  len = path - s;
    80003d1e:	40998633          	sub	a2,s3,s1
    80003d22:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003d26:	09acd863          	bge	s9,s10,80003db6 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003d2a:	4639                	li	a2,14
    80003d2c:	85a6                	mv	a1,s1
    80003d2e:	8556                	mv	a0,s5
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	028080e7          	jalr	40(ra) # 80000d58 <memmove>
    80003d38:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d3a:	0004c783          	lbu	a5,0(s1)
    80003d3e:	01279763          	bne	a5,s2,80003d4c <namex+0xd2>
    path++;
    80003d42:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d44:	0004c783          	lbu	a5,0(s1)
    80003d48:	ff278de3          	beq	a5,s2,80003d42 <namex+0xc8>
    ilock(ip);
    80003d4c:	8552                	mv	a0,s4
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	99a080e7          	jalr	-1638(ra) # 800036e8 <ilock>
    if(ip->type != T_DIR){
    80003d56:	044a1783          	lh	a5,68(s4)
    80003d5a:	f98790e3          	bne	a5,s8,80003cda <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003d5e:	000b0563          	beqz	s6,80003d68 <namex+0xee>
    80003d62:	0004c783          	lbu	a5,0(s1)
    80003d66:	dfd9                	beqz	a5,80003d04 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d68:	865e                	mv	a2,s7
    80003d6a:	85d6                	mv	a1,s5
    80003d6c:	8552                	mv	a0,s4
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	e5c080e7          	jalr	-420(ra) # 80003bca <dirlookup>
    80003d76:	89aa                	mv	s3,a0
    80003d78:	dd41                	beqz	a0,80003d10 <namex+0x96>
    iunlockput(ip);
    80003d7a:	8552                	mv	a0,s4
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	bce080e7          	jalr	-1074(ra) # 8000394a <iunlockput>
    ip = next;
    80003d84:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003d86:	0004c783          	lbu	a5,0(s1)
    80003d8a:	01279763          	bne	a5,s2,80003d98 <namex+0x11e>
    path++;
    80003d8e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d90:	0004c783          	lbu	a5,0(s1)
    80003d94:	ff278de3          	beq	a5,s2,80003d8e <namex+0x114>
  if(*path == 0)
    80003d98:	cb9d                	beqz	a5,80003dce <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d9a:	0004c783          	lbu	a5,0(s1)
    80003d9e:	89a6                	mv	s3,s1
  len = path - s;
    80003da0:	8d5e                	mv	s10,s7
    80003da2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003da4:	01278963          	beq	a5,s2,80003db6 <namex+0x13c>
    80003da8:	dbbd                	beqz	a5,80003d1e <namex+0xa4>
    path++;
    80003daa:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003dac:	0009c783          	lbu	a5,0(s3)
    80003db0:	ff279ce3          	bne	a5,s2,80003da8 <namex+0x12e>
    80003db4:	b7ad                	j	80003d1e <namex+0xa4>
    memmove(name, s, len);
    80003db6:	2601                	sext.w	a2,a2
    80003db8:	85a6                	mv	a1,s1
    80003dba:	8556                	mv	a0,s5
    80003dbc:	ffffd097          	auipc	ra,0xffffd
    80003dc0:	f9c080e7          	jalr	-100(ra) # 80000d58 <memmove>
    name[len] = 0;
    80003dc4:	9d56                	add	s10,s10,s5
    80003dc6:	000d0023          	sb	zero,0(s10)
    80003dca:	84ce                	mv	s1,s3
    80003dcc:	b7bd                	j	80003d3a <namex+0xc0>
  if(nameiparent){
    80003dce:	f00b0ce3          	beqz	s6,80003ce6 <namex+0x6c>
    iput(ip);
    80003dd2:	8552                	mv	a0,s4
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	ace080e7          	jalr	-1330(ra) # 800038a2 <iput>
    return 0;
    80003ddc:	4a01                	li	s4,0
    80003dde:	b721                	j	80003ce6 <namex+0x6c>

0000000080003de0 <dirlink>:
{
    80003de0:	7139                	addi	sp,sp,-64
    80003de2:	fc06                	sd	ra,56(sp)
    80003de4:	f822                	sd	s0,48(sp)
    80003de6:	f426                	sd	s1,40(sp)
    80003de8:	f04a                	sd	s2,32(sp)
    80003dea:	ec4e                	sd	s3,24(sp)
    80003dec:	e852                	sd	s4,16(sp)
    80003dee:	0080                	addi	s0,sp,64
    80003df0:	892a                	mv	s2,a0
    80003df2:	8a2e                	mv	s4,a1
    80003df4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003df6:	4601                	li	a2,0
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	dd2080e7          	jalr	-558(ra) # 80003bca <dirlookup>
    80003e00:	e93d                	bnez	a0,80003e76 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e02:	04c92483          	lw	s1,76(s2)
    80003e06:	c49d                	beqz	s1,80003e34 <dirlink+0x54>
    80003e08:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e0a:	4741                	li	a4,16
    80003e0c:	86a6                	mv	a3,s1
    80003e0e:	fc040613          	addi	a2,s0,-64
    80003e12:	4581                	li	a1,0
    80003e14:	854a                	mv	a0,s2
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	b86080e7          	jalr	-1146(ra) # 8000399c <readi>
    80003e1e:	47c1                	li	a5,16
    80003e20:	06f51163          	bne	a0,a5,80003e82 <dirlink+0xa2>
    if(de.inum == 0)
    80003e24:	fc045783          	lhu	a5,-64(s0)
    80003e28:	c791                	beqz	a5,80003e34 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e2a:	24c1                	addiw	s1,s1,16
    80003e2c:	04c92783          	lw	a5,76(s2)
    80003e30:	fcf4ede3          	bltu	s1,a5,80003e0a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e34:	4639                	li	a2,14
    80003e36:	85d2                	mv	a1,s4
    80003e38:	fc240513          	addi	a0,s0,-62
    80003e3c:	ffffd097          	auipc	ra,0xffffd
    80003e40:	fd4080e7          	jalr	-44(ra) # 80000e10 <strncpy>
  de.inum = inum;
    80003e44:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e48:	4741                	li	a4,16
    80003e4a:	86a6                	mv	a3,s1
    80003e4c:	fc040613          	addi	a2,s0,-64
    80003e50:	4581                	li	a1,0
    80003e52:	854a                	mv	a0,s2
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	c40080e7          	jalr	-960(ra) # 80003a94 <writei>
    80003e5c:	872a                	mv	a4,a0
    80003e5e:	47c1                	li	a5,16
  return 0;
    80003e60:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e62:	02f71863          	bne	a4,a5,80003e92 <dirlink+0xb2>
}
    80003e66:	70e2                	ld	ra,56(sp)
    80003e68:	7442                	ld	s0,48(sp)
    80003e6a:	74a2                	ld	s1,40(sp)
    80003e6c:	7902                	ld	s2,32(sp)
    80003e6e:	69e2                	ld	s3,24(sp)
    80003e70:	6a42                	ld	s4,16(sp)
    80003e72:	6121                	addi	sp,sp,64
    80003e74:	8082                	ret
    iput(ip);
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	a2c080e7          	jalr	-1492(ra) # 800038a2 <iput>
    return -1;
    80003e7e:	557d                	li	a0,-1
    80003e80:	b7dd                	j	80003e66 <dirlink+0x86>
      panic("dirlink read");
    80003e82:	00004517          	auipc	a0,0x4
    80003e86:	70650513          	addi	a0,a0,1798 # 80008588 <syscalls+0x1c8>
    80003e8a:	ffffc097          	auipc	ra,0xffffc
    80003e8e:	6bc080e7          	jalr	1724(ra) # 80000546 <panic>
    panic("dirlink");
    80003e92:	00005517          	auipc	a0,0x5
    80003e96:	81650513          	addi	a0,a0,-2026 # 800086a8 <syscalls+0x2e8>
    80003e9a:	ffffc097          	auipc	ra,0xffffc
    80003e9e:	6ac080e7          	jalr	1708(ra) # 80000546 <panic>

0000000080003ea2 <namei>:

struct inode*
namei(char *path)
{
    80003ea2:	1101                	addi	sp,sp,-32
    80003ea4:	ec06                	sd	ra,24(sp)
    80003ea6:	e822                	sd	s0,16(sp)
    80003ea8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003eaa:	fe040613          	addi	a2,s0,-32
    80003eae:	4581                	li	a1,0
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	dca080e7          	jalr	-566(ra) # 80003c7a <namex>
}
    80003eb8:	60e2                	ld	ra,24(sp)
    80003eba:	6442                	ld	s0,16(sp)
    80003ebc:	6105                	addi	sp,sp,32
    80003ebe:	8082                	ret

0000000080003ec0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ec0:	1141                	addi	sp,sp,-16
    80003ec2:	e406                	sd	ra,8(sp)
    80003ec4:	e022                	sd	s0,0(sp)
    80003ec6:	0800                	addi	s0,sp,16
    80003ec8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003eca:	4585                	li	a1,1
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	dae080e7          	jalr	-594(ra) # 80003c7a <namex>
}
    80003ed4:	60a2                	ld	ra,8(sp)
    80003ed6:	6402                	ld	s0,0(sp)
    80003ed8:	0141                	addi	sp,sp,16
    80003eda:	8082                	ret

0000000080003edc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003edc:	1101                	addi	sp,sp,-32
    80003ede:	ec06                	sd	ra,24(sp)
    80003ee0:	e822                	sd	s0,16(sp)
    80003ee2:	e426                	sd	s1,8(sp)
    80003ee4:	e04a                	sd	s2,0(sp)
    80003ee6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ee8:	0001e917          	auipc	s2,0x1e
    80003eec:	a2090913          	addi	s2,s2,-1504 # 80021908 <log>
    80003ef0:	01892583          	lw	a1,24(s2)
    80003ef4:	02892503          	lw	a0,40(s2)
    80003ef8:	fffff097          	auipc	ra,0xfffff
    80003efc:	fee080e7          	jalr	-18(ra) # 80002ee6 <bread>
    80003f00:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f02:	02c92683          	lw	a3,44(s2)
    80003f06:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f08:	02d05863          	blez	a3,80003f38 <write_head+0x5c>
    80003f0c:	0001e797          	auipc	a5,0x1e
    80003f10:	a2c78793          	addi	a5,a5,-1492 # 80021938 <log+0x30>
    80003f14:	05c50713          	addi	a4,a0,92
    80003f18:	36fd                	addiw	a3,a3,-1
    80003f1a:	02069613          	slli	a2,a3,0x20
    80003f1e:	01e65693          	srli	a3,a2,0x1e
    80003f22:	0001e617          	auipc	a2,0x1e
    80003f26:	a1a60613          	addi	a2,a2,-1510 # 8002193c <log+0x34>
    80003f2a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f2c:	4390                	lw	a2,0(a5)
    80003f2e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f30:	0791                	addi	a5,a5,4
    80003f32:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003f34:	fed79ce3          	bne	a5,a3,80003f2c <write_head+0x50>
  }
  bwrite(buf);
    80003f38:	8526                	mv	a0,s1
    80003f3a:	fffff097          	auipc	ra,0xfffff
    80003f3e:	09e080e7          	jalr	158(ra) # 80002fd8 <bwrite>
  brelse(buf);
    80003f42:	8526                	mv	a0,s1
    80003f44:	fffff097          	auipc	ra,0xfffff
    80003f48:	0d2080e7          	jalr	210(ra) # 80003016 <brelse>
}
    80003f4c:	60e2                	ld	ra,24(sp)
    80003f4e:	6442                	ld	s0,16(sp)
    80003f50:	64a2                	ld	s1,8(sp)
    80003f52:	6902                	ld	s2,0(sp)
    80003f54:	6105                	addi	sp,sp,32
    80003f56:	8082                	ret

0000000080003f58 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f58:	0001e797          	auipc	a5,0x1e
    80003f5c:	9dc7a783          	lw	a5,-1572(a5) # 80021934 <log+0x2c>
    80003f60:	0af05663          	blez	a5,8000400c <install_trans+0xb4>
{
    80003f64:	7139                	addi	sp,sp,-64
    80003f66:	fc06                	sd	ra,56(sp)
    80003f68:	f822                	sd	s0,48(sp)
    80003f6a:	f426                	sd	s1,40(sp)
    80003f6c:	f04a                	sd	s2,32(sp)
    80003f6e:	ec4e                	sd	s3,24(sp)
    80003f70:	e852                	sd	s4,16(sp)
    80003f72:	e456                	sd	s5,8(sp)
    80003f74:	0080                	addi	s0,sp,64
    80003f76:	0001ea97          	auipc	s5,0x1e
    80003f7a:	9c2a8a93          	addi	s5,s5,-1598 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f7e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f80:	0001e997          	auipc	s3,0x1e
    80003f84:	98898993          	addi	s3,s3,-1656 # 80021908 <log>
    80003f88:	0189a583          	lw	a1,24(s3)
    80003f8c:	014585bb          	addw	a1,a1,s4
    80003f90:	2585                	addiw	a1,a1,1
    80003f92:	0289a503          	lw	a0,40(s3)
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	f50080e7          	jalr	-176(ra) # 80002ee6 <bread>
    80003f9e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fa0:	000aa583          	lw	a1,0(s5)
    80003fa4:	0289a503          	lw	a0,40(s3)
    80003fa8:	fffff097          	auipc	ra,0xfffff
    80003fac:	f3e080e7          	jalr	-194(ra) # 80002ee6 <bread>
    80003fb0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fb2:	40000613          	li	a2,1024
    80003fb6:	05890593          	addi	a1,s2,88
    80003fba:	05850513          	addi	a0,a0,88
    80003fbe:	ffffd097          	auipc	ra,0xffffd
    80003fc2:	d9a080e7          	jalr	-614(ra) # 80000d58 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fc6:	8526                	mv	a0,s1
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	010080e7          	jalr	16(ra) # 80002fd8 <bwrite>
    bunpin(dbuf);
    80003fd0:	8526                	mv	a0,s1
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	11e080e7          	jalr	286(ra) # 800030f0 <bunpin>
    brelse(lbuf);
    80003fda:	854a                	mv	a0,s2
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	03a080e7          	jalr	58(ra) # 80003016 <brelse>
    brelse(dbuf);
    80003fe4:	8526                	mv	a0,s1
    80003fe6:	fffff097          	auipc	ra,0xfffff
    80003fea:	030080e7          	jalr	48(ra) # 80003016 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fee:	2a05                	addiw	s4,s4,1
    80003ff0:	0a91                	addi	s5,s5,4
    80003ff2:	02c9a783          	lw	a5,44(s3)
    80003ff6:	f8fa49e3          	blt	s4,a5,80003f88 <install_trans+0x30>
}
    80003ffa:	70e2                	ld	ra,56(sp)
    80003ffc:	7442                	ld	s0,48(sp)
    80003ffe:	74a2                	ld	s1,40(sp)
    80004000:	7902                	ld	s2,32(sp)
    80004002:	69e2                	ld	s3,24(sp)
    80004004:	6a42                	ld	s4,16(sp)
    80004006:	6aa2                	ld	s5,8(sp)
    80004008:	6121                	addi	sp,sp,64
    8000400a:	8082                	ret
    8000400c:	8082                	ret

000000008000400e <initlog>:
{
    8000400e:	7179                	addi	sp,sp,-48
    80004010:	f406                	sd	ra,40(sp)
    80004012:	f022                	sd	s0,32(sp)
    80004014:	ec26                	sd	s1,24(sp)
    80004016:	e84a                	sd	s2,16(sp)
    80004018:	e44e                	sd	s3,8(sp)
    8000401a:	1800                	addi	s0,sp,48
    8000401c:	892a                	mv	s2,a0
    8000401e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004020:	0001e497          	auipc	s1,0x1e
    80004024:	8e848493          	addi	s1,s1,-1816 # 80021908 <log>
    80004028:	00004597          	auipc	a1,0x4
    8000402c:	57058593          	addi	a1,a1,1392 # 80008598 <syscalls+0x1d8>
    80004030:	8526                	mv	a0,s1
    80004032:	ffffd097          	auipc	ra,0xffffd
    80004036:	b3e080e7          	jalr	-1218(ra) # 80000b70 <initlock>
  log.start = sb->logstart;
    8000403a:	0149a583          	lw	a1,20(s3)
    8000403e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004040:	0109a783          	lw	a5,16(s3)
    80004044:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004046:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000404a:	854a                	mv	a0,s2
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	e9a080e7          	jalr	-358(ra) # 80002ee6 <bread>
  log.lh.n = lh->n;
    80004054:	4d34                	lw	a3,88(a0)
    80004056:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004058:	02d05663          	blez	a3,80004084 <initlog+0x76>
    8000405c:	05c50793          	addi	a5,a0,92
    80004060:	0001e717          	auipc	a4,0x1e
    80004064:	8d870713          	addi	a4,a4,-1832 # 80021938 <log+0x30>
    80004068:	36fd                	addiw	a3,a3,-1
    8000406a:	02069613          	slli	a2,a3,0x20
    8000406e:	01e65693          	srli	a3,a2,0x1e
    80004072:	06050613          	addi	a2,a0,96
    80004076:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004078:	4390                	lw	a2,0(a5)
    8000407a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000407c:	0791                	addi	a5,a5,4
    8000407e:	0711                	addi	a4,a4,4
    80004080:	fed79ce3          	bne	a5,a3,80004078 <initlog+0x6a>
  brelse(buf);
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	f92080e7          	jalr	-110(ra) # 80003016 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	ecc080e7          	jalr	-308(ra) # 80003f58 <install_trans>
  log.lh.n = 0;
    80004094:	0001e797          	auipc	a5,0x1e
    80004098:	8a07a023          	sw	zero,-1888(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	e40080e7          	jalr	-448(ra) # 80003edc <write_head>
}
    800040a4:	70a2                	ld	ra,40(sp)
    800040a6:	7402                	ld	s0,32(sp)
    800040a8:	64e2                	ld	s1,24(sp)
    800040aa:	6942                	ld	s2,16(sp)
    800040ac:	69a2                	ld	s3,8(sp)
    800040ae:	6145                	addi	sp,sp,48
    800040b0:	8082                	ret

00000000800040b2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040b2:	1101                	addi	sp,sp,-32
    800040b4:	ec06                	sd	ra,24(sp)
    800040b6:	e822                	sd	s0,16(sp)
    800040b8:	e426                	sd	s1,8(sp)
    800040ba:	e04a                	sd	s2,0(sp)
    800040bc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040be:	0001e517          	auipc	a0,0x1e
    800040c2:	84a50513          	addi	a0,a0,-1974 # 80021908 <log>
    800040c6:	ffffd097          	auipc	ra,0xffffd
    800040ca:	b3a080e7          	jalr	-1222(ra) # 80000c00 <acquire>
  while(1){
    if(log.committing){
    800040ce:	0001e497          	auipc	s1,0x1e
    800040d2:	83a48493          	addi	s1,s1,-1990 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040d6:	4979                	li	s2,30
    800040d8:	a039                	j	800040e6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040da:	85a6                	mv	a1,s1
    800040dc:	8526                	mv	a0,s1
    800040de:	ffffe097          	auipc	ra,0xffffe
    800040e2:	148080e7          	jalr	328(ra) # 80002226 <sleep>
    if(log.committing){
    800040e6:	50dc                	lw	a5,36(s1)
    800040e8:	fbed                	bnez	a5,800040da <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040ea:	5098                	lw	a4,32(s1)
    800040ec:	2705                	addiw	a4,a4,1
    800040ee:	0007069b          	sext.w	a3,a4
    800040f2:	0027179b          	slliw	a5,a4,0x2
    800040f6:	9fb9                	addw	a5,a5,a4
    800040f8:	0017979b          	slliw	a5,a5,0x1
    800040fc:	54d8                	lw	a4,44(s1)
    800040fe:	9fb9                	addw	a5,a5,a4
    80004100:	00f95963          	bge	s2,a5,80004112 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004104:	85a6                	mv	a1,s1
    80004106:	8526                	mv	a0,s1
    80004108:	ffffe097          	auipc	ra,0xffffe
    8000410c:	11e080e7          	jalr	286(ra) # 80002226 <sleep>
    80004110:	bfd9                	j	800040e6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004112:	0001d517          	auipc	a0,0x1d
    80004116:	7f650513          	addi	a0,a0,2038 # 80021908 <log>
    8000411a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000411c:	ffffd097          	auipc	ra,0xffffd
    80004120:	b98080e7          	jalr	-1128(ra) # 80000cb4 <release>
      break;
    }
  }
}
    80004124:	60e2                	ld	ra,24(sp)
    80004126:	6442                	ld	s0,16(sp)
    80004128:	64a2                	ld	s1,8(sp)
    8000412a:	6902                	ld	s2,0(sp)
    8000412c:	6105                	addi	sp,sp,32
    8000412e:	8082                	ret

0000000080004130 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004130:	7139                	addi	sp,sp,-64
    80004132:	fc06                	sd	ra,56(sp)
    80004134:	f822                	sd	s0,48(sp)
    80004136:	f426                	sd	s1,40(sp)
    80004138:	f04a                	sd	s2,32(sp)
    8000413a:	ec4e                	sd	s3,24(sp)
    8000413c:	e852                	sd	s4,16(sp)
    8000413e:	e456                	sd	s5,8(sp)
    80004140:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004142:	0001d497          	auipc	s1,0x1d
    80004146:	7c648493          	addi	s1,s1,1990 # 80021908 <log>
    8000414a:	8526                	mv	a0,s1
    8000414c:	ffffd097          	auipc	ra,0xffffd
    80004150:	ab4080e7          	jalr	-1356(ra) # 80000c00 <acquire>
  log.outstanding -= 1;
    80004154:	509c                	lw	a5,32(s1)
    80004156:	37fd                	addiw	a5,a5,-1
    80004158:	0007891b          	sext.w	s2,a5
    8000415c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000415e:	50dc                	lw	a5,36(s1)
    80004160:	e7b9                	bnez	a5,800041ae <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004162:	04091e63          	bnez	s2,800041be <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004166:	0001d497          	auipc	s1,0x1d
    8000416a:	7a248493          	addi	s1,s1,1954 # 80021908 <log>
    8000416e:	4785                	li	a5,1
    80004170:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004172:	8526                	mv	a0,s1
    80004174:	ffffd097          	auipc	ra,0xffffd
    80004178:	b40080e7          	jalr	-1216(ra) # 80000cb4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000417c:	54dc                	lw	a5,44(s1)
    8000417e:	06f04763          	bgtz	a5,800041ec <end_op+0xbc>
    acquire(&log.lock);
    80004182:	0001d497          	auipc	s1,0x1d
    80004186:	78648493          	addi	s1,s1,1926 # 80021908 <log>
    8000418a:	8526                	mv	a0,s1
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	a74080e7          	jalr	-1420(ra) # 80000c00 <acquire>
    log.committing = 0;
    80004194:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004198:	8526                	mv	a0,s1
    8000419a:	ffffe097          	auipc	ra,0xffffe
    8000419e:	20c080e7          	jalr	524(ra) # 800023a6 <wakeup>
    release(&log.lock);
    800041a2:	8526                	mv	a0,s1
    800041a4:	ffffd097          	auipc	ra,0xffffd
    800041a8:	b10080e7          	jalr	-1264(ra) # 80000cb4 <release>
}
    800041ac:	a03d                	j	800041da <end_op+0xaa>
    panic("log.committing");
    800041ae:	00004517          	auipc	a0,0x4
    800041b2:	3f250513          	addi	a0,a0,1010 # 800085a0 <syscalls+0x1e0>
    800041b6:	ffffc097          	auipc	ra,0xffffc
    800041ba:	390080e7          	jalr	912(ra) # 80000546 <panic>
    wakeup(&log);
    800041be:	0001d497          	auipc	s1,0x1d
    800041c2:	74a48493          	addi	s1,s1,1866 # 80021908 <log>
    800041c6:	8526                	mv	a0,s1
    800041c8:	ffffe097          	auipc	ra,0xffffe
    800041cc:	1de080e7          	jalr	478(ra) # 800023a6 <wakeup>
  release(&log.lock);
    800041d0:	8526                	mv	a0,s1
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	ae2080e7          	jalr	-1310(ra) # 80000cb4 <release>
}
    800041da:	70e2                	ld	ra,56(sp)
    800041dc:	7442                	ld	s0,48(sp)
    800041de:	74a2                	ld	s1,40(sp)
    800041e0:	7902                	ld	s2,32(sp)
    800041e2:	69e2                	ld	s3,24(sp)
    800041e4:	6a42                	ld	s4,16(sp)
    800041e6:	6aa2                	ld	s5,8(sp)
    800041e8:	6121                	addi	sp,sp,64
    800041ea:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ec:	0001da97          	auipc	s5,0x1d
    800041f0:	74ca8a93          	addi	s5,s5,1868 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041f4:	0001da17          	auipc	s4,0x1d
    800041f8:	714a0a13          	addi	s4,s4,1812 # 80021908 <log>
    800041fc:	018a2583          	lw	a1,24(s4)
    80004200:	012585bb          	addw	a1,a1,s2
    80004204:	2585                	addiw	a1,a1,1
    80004206:	028a2503          	lw	a0,40(s4)
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	cdc080e7          	jalr	-804(ra) # 80002ee6 <bread>
    80004212:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004214:	000aa583          	lw	a1,0(s5)
    80004218:	028a2503          	lw	a0,40(s4)
    8000421c:	fffff097          	auipc	ra,0xfffff
    80004220:	cca080e7          	jalr	-822(ra) # 80002ee6 <bread>
    80004224:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004226:	40000613          	li	a2,1024
    8000422a:	05850593          	addi	a1,a0,88
    8000422e:	05848513          	addi	a0,s1,88
    80004232:	ffffd097          	auipc	ra,0xffffd
    80004236:	b26080e7          	jalr	-1242(ra) # 80000d58 <memmove>
    bwrite(to);  // write the log
    8000423a:	8526                	mv	a0,s1
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	d9c080e7          	jalr	-612(ra) # 80002fd8 <bwrite>
    brelse(from);
    80004244:	854e                	mv	a0,s3
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	dd0080e7          	jalr	-560(ra) # 80003016 <brelse>
    brelse(to);
    8000424e:	8526                	mv	a0,s1
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	dc6080e7          	jalr	-570(ra) # 80003016 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004258:	2905                	addiw	s2,s2,1
    8000425a:	0a91                	addi	s5,s5,4
    8000425c:	02ca2783          	lw	a5,44(s4)
    80004260:	f8f94ee3          	blt	s2,a5,800041fc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004264:	00000097          	auipc	ra,0x0
    80004268:	c78080e7          	jalr	-904(ra) # 80003edc <write_head>
    install_trans(); // Now install writes to home locations
    8000426c:	00000097          	auipc	ra,0x0
    80004270:	cec080e7          	jalr	-788(ra) # 80003f58 <install_trans>
    log.lh.n = 0;
    80004274:	0001d797          	auipc	a5,0x1d
    80004278:	6c07a023          	sw	zero,1728(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000427c:	00000097          	auipc	ra,0x0
    80004280:	c60080e7          	jalr	-928(ra) # 80003edc <write_head>
    80004284:	bdfd                	j	80004182 <end_op+0x52>

0000000080004286 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004286:	1101                	addi	sp,sp,-32
    80004288:	ec06                	sd	ra,24(sp)
    8000428a:	e822                	sd	s0,16(sp)
    8000428c:	e426                	sd	s1,8(sp)
    8000428e:	e04a                	sd	s2,0(sp)
    80004290:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004292:	0001d717          	auipc	a4,0x1d
    80004296:	6a272703          	lw	a4,1698(a4) # 80021934 <log+0x2c>
    8000429a:	47f5                	li	a5,29
    8000429c:	08e7c063          	blt	a5,a4,8000431c <log_write+0x96>
    800042a0:	84aa                	mv	s1,a0
    800042a2:	0001d797          	auipc	a5,0x1d
    800042a6:	6827a783          	lw	a5,1666(a5) # 80021924 <log+0x1c>
    800042aa:	37fd                	addiw	a5,a5,-1
    800042ac:	06f75863          	bge	a4,a5,8000431c <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042b0:	0001d797          	auipc	a5,0x1d
    800042b4:	6787a783          	lw	a5,1656(a5) # 80021928 <log+0x20>
    800042b8:	06f05a63          	blez	a5,8000432c <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800042bc:	0001d917          	auipc	s2,0x1d
    800042c0:	64c90913          	addi	s2,s2,1612 # 80021908 <log>
    800042c4:	854a                	mv	a0,s2
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	93a080e7          	jalr	-1734(ra) # 80000c00 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800042ce:	02c92603          	lw	a2,44(s2)
    800042d2:	06c05563          	blez	a2,8000433c <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042d6:	44cc                	lw	a1,12(s1)
    800042d8:	0001d717          	auipc	a4,0x1d
    800042dc:	66070713          	addi	a4,a4,1632 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042e0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042e2:	4314                	lw	a3,0(a4)
    800042e4:	04b68d63          	beq	a3,a1,8000433e <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800042e8:	2785                	addiw	a5,a5,1
    800042ea:	0711                	addi	a4,a4,4
    800042ec:	fec79be3          	bne	a5,a2,800042e2 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042f0:	0621                	addi	a2,a2,8
    800042f2:	060a                	slli	a2,a2,0x2
    800042f4:	0001d797          	auipc	a5,0x1d
    800042f8:	61478793          	addi	a5,a5,1556 # 80021908 <log>
    800042fc:	97b2                	add	a5,a5,a2
    800042fe:	44d8                	lw	a4,12(s1)
    80004300:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004302:	8526                	mv	a0,s1
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	db0080e7          	jalr	-592(ra) # 800030b4 <bpin>
    log.lh.n++;
    8000430c:	0001d717          	auipc	a4,0x1d
    80004310:	5fc70713          	addi	a4,a4,1532 # 80021908 <log>
    80004314:	575c                	lw	a5,44(a4)
    80004316:	2785                	addiw	a5,a5,1
    80004318:	d75c                	sw	a5,44(a4)
    8000431a:	a835                	j	80004356 <log_write+0xd0>
    panic("too big a transaction");
    8000431c:	00004517          	auipc	a0,0x4
    80004320:	29450513          	addi	a0,a0,660 # 800085b0 <syscalls+0x1f0>
    80004324:	ffffc097          	auipc	ra,0xffffc
    80004328:	222080e7          	jalr	546(ra) # 80000546 <panic>
    panic("log_write outside of trans");
    8000432c:	00004517          	auipc	a0,0x4
    80004330:	29c50513          	addi	a0,a0,668 # 800085c8 <syscalls+0x208>
    80004334:	ffffc097          	auipc	ra,0xffffc
    80004338:	212080e7          	jalr	530(ra) # 80000546 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000433c:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000433e:	00878693          	addi	a3,a5,8
    80004342:	068a                	slli	a3,a3,0x2
    80004344:	0001d717          	auipc	a4,0x1d
    80004348:	5c470713          	addi	a4,a4,1476 # 80021908 <log>
    8000434c:	9736                	add	a4,a4,a3
    8000434e:	44d4                	lw	a3,12(s1)
    80004350:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004352:	faf608e3          	beq	a2,a5,80004302 <log_write+0x7c>
  }
  release(&log.lock);
    80004356:	0001d517          	auipc	a0,0x1d
    8000435a:	5b250513          	addi	a0,a0,1458 # 80021908 <log>
    8000435e:	ffffd097          	auipc	ra,0xffffd
    80004362:	956080e7          	jalr	-1706(ra) # 80000cb4 <release>
}
    80004366:	60e2                	ld	ra,24(sp)
    80004368:	6442                	ld	s0,16(sp)
    8000436a:	64a2                	ld	s1,8(sp)
    8000436c:	6902                	ld	s2,0(sp)
    8000436e:	6105                	addi	sp,sp,32
    80004370:	8082                	ret

0000000080004372 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004372:	1101                	addi	sp,sp,-32
    80004374:	ec06                	sd	ra,24(sp)
    80004376:	e822                	sd	s0,16(sp)
    80004378:	e426                	sd	s1,8(sp)
    8000437a:	e04a                	sd	s2,0(sp)
    8000437c:	1000                	addi	s0,sp,32
    8000437e:	84aa                	mv	s1,a0
    80004380:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004382:	00004597          	auipc	a1,0x4
    80004386:	26658593          	addi	a1,a1,614 # 800085e8 <syscalls+0x228>
    8000438a:	0521                	addi	a0,a0,8
    8000438c:	ffffc097          	auipc	ra,0xffffc
    80004390:	7e4080e7          	jalr	2020(ra) # 80000b70 <initlock>
  lk->name = name;
    80004394:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004398:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000439c:	0204a423          	sw	zero,40(s1)
}
    800043a0:	60e2                	ld	ra,24(sp)
    800043a2:	6442                	ld	s0,16(sp)
    800043a4:	64a2                	ld	s1,8(sp)
    800043a6:	6902                	ld	s2,0(sp)
    800043a8:	6105                	addi	sp,sp,32
    800043aa:	8082                	ret

00000000800043ac <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043ac:	1101                	addi	sp,sp,-32
    800043ae:	ec06                	sd	ra,24(sp)
    800043b0:	e822                	sd	s0,16(sp)
    800043b2:	e426                	sd	s1,8(sp)
    800043b4:	e04a                	sd	s2,0(sp)
    800043b6:	1000                	addi	s0,sp,32
    800043b8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043ba:	00850913          	addi	s2,a0,8
    800043be:	854a                	mv	a0,s2
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	840080e7          	jalr	-1984(ra) # 80000c00 <acquire>
  while (lk->locked) {
    800043c8:	409c                	lw	a5,0(s1)
    800043ca:	cb89                	beqz	a5,800043dc <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043cc:	85ca                	mv	a1,s2
    800043ce:	8526                	mv	a0,s1
    800043d0:	ffffe097          	auipc	ra,0xffffe
    800043d4:	e56080e7          	jalr	-426(ra) # 80002226 <sleep>
  while (lk->locked) {
    800043d8:	409c                	lw	a5,0(s1)
    800043da:	fbed                	bnez	a5,800043cc <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043dc:	4785                	li	a5,1
    800043de:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043e0:	ffffd097          	auipc	ra,0xffffd
    800043e4:	62e080e7          	jalr	1582(ra) # 80001a0e <myproc>
    800043e8:	5d1c                	lw	a5,56(a0)
    800043ea:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043ec:	854a                	mv	a0,s2
    800043ee:	ffffd097          	auipc	ra,0xffffd
    800043f2:	8c6080e7          	jalr	-1850(ra) # 80000cb4 <release>
}
    800043f6:	60e2                	ld	ra,24(sp)
    800043f8:	6442                	ld	s0,16(sp)
    800043fa:	64a2                	ld	s1,8(sp)
    800043fc:	6902                	ld	s2,0(sp)
    800043fe:	6105                	addi	sp,sp,32
    80004400:	8082                	ret

0000000080004402 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004402:	1101                	addi	sp,sp,-32
    80004404:	ec06                	sd	ra,24(sp)
    80004406:	e822                	sd	s0,16(sp)
    80004408:	e426                	sd	s1,8(sp)
    8000440a:	e04a                	sd	s2,0(sp)
    8000440c:	1000                	addi	s0,sp,32
    8000440e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004410:	00850913          	addi	s2,a0,8
    80004414:	854a                	mv	a0,s2
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	7ea080e7          	jalr	2026(ra) # 80000c00 <acquire>
  lk->locked = 0;
    8000441e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004422:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004426:	8526                	mv	a0,s1
    80004428:	ffffe097          	auipc	ra,0xffffe
    8000442c:	f7e080e7          	jalr	-130(ra) # 800023a6 <wakeup>
  release(&lk->lk);
    80004430:	854a                	mv	a0,s2
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	882080e7          	jalr	-1918(ra) # 80000cb4 <release>
}
    8000443a:	60e2                	ld	ra,24(sp)
    8000443c:	6442                	ld	s0,16(sp)
    8000443e:	64a2                	ld	s1,8(sp)
    80004440:	6902                	ld	s2,0(sp)
    80004442:	6105                	addi	sp,sp,32
    80004444:	8082                	ret

0000000080004446 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004446:	7179                	addi	sp,sp,-48
    80004448:	f406                	sd	ra,40(sp)
    8000444a:	f022                	sd	s0,32(sp)
    8000444c:	ec26                	sd	s1,24(sp)
    8000444e:	e84a                	sd	s2,16(sp)
    80004450:	e44e                	sd	s3,8(sp)
    80004452:	1800                	addi	s0,sp,48
    80004454:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004456:	00850913          	addi	s2,a0,8
    8000445a:	854a                	mv	a0,s2
    8000445c:	ffffc097          	auipc	ra,0xffffc
    80004460:	7a4080e7          	jalr	1956(ra) # 80000c00 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004464:	409c                	lw	a5,0(s1)
    80004466:	ef99                	bnez	a5,80004484 <holdingsleep+0x3e>
    80004468:	4481                	li	s1,0
  release(&lk->lk);
    8000446a:	854a                	mv	a0,s2
    8000446c:	ffffd097          	auipc	ra,0xffffd
    80004470:	848080e7          	jalr	-1976(ra) # 80000cb4 <release>
  return r;
}
    80004474:	8526                	mv	a0,s1
    80004476:	70a2                	ld	ra,40(sp)
    80004478:	7402                	ld	s0,32(sp)
    8000447a:	64e2                	ld	s1,24(sp)
    8000447c:	6942                	ld	s2,16(sp)
    8000447e:	69a2                	ld	s3,8(sp)
    80004480:	6145                	addi	sp,sp,48
    80004482:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004484:	0284a983          	lw	s3,40(s1)
    80004488:	ffffd097          	auipc	ra,0xffffd
    8000448c:	586080e7          	jalr	1414(ra) # 80001a0e <myproc>
    80004490:	5d04                	lw	s1,56(a0)
    80004492:	413484b3          	sub	s1,s1,s3
    80004496:	0014b493          	seqz	s1,s1
    8000449a:	bfc1                	j	8000446a <holdingsleep+0x24>

000000008000449c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000449c:	1141                	addi	sp,sp,-16
    8000449e:	e406                	sd	ra,8(sp)
    800044a0:	e022                	sd	s0,0(sp)
    800044a2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044a4:	00004597          	auipc	a1,0x4
    800044a8:	15458593          	addi	a1,a1,340 # 800085f8 <syscalls+0x238>
    800044ac:	0001d517          	auipc	a0,0x1d
    800044b0:	5a450513          	addi	a0,a0,1444 # 80021a50 <ftable>
    800044b4:	ffffc097          	auipc	ra,0xffffc
    800044b8:	6bc080e7          	jalr	1724(ra) # 80000b70 <initlock>
}
    800044bc:	60a2                	ld	ra,8(sp)
    800044be:	6402                	ld	s0,0(sp)
    800044c0:	0141                	addi	sp,sp,16
    800044c2:	8082                	ret

00000000800044c4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044c4:	1101                	addi	sp,sp,-32
    800044c6:	ec06                	sd	ra,24(sp)
    800044c8:	e822                	sd	s0,16(sp)
    800044ca:	e426                	sd	s1,8(sp)
    800044cc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044ce:	0001d517          	auipc	a0,0x1d
    800044d2:	58250513          	addi	a0,a0,1410 # 80021a50 <ftable>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	72a080e7          	jalr	1834(ra) # 80000c00 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044de:	0001d497          	auipc	s1,0x1d
    800044e2:	58a48493          	addi	s1,s1,1418 # 80021a68 <ftable+0x18>
    800044e6:	0001e717          	auipc	a4,0x1e
    800044ea:	52270713          	addi	a4,a4,1314 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    800044ee:	40dc                	lw	a5,4(s1)
    800044f0:	cf99                	beqz	a5,8000450e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044f2:	02848493          	addi	s1,s1,40
    800044f6:	fee49ce3          	bne	s1,a4,800044ee <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044fa:	0001d517          	auipc	a0,0x1d
    800044fe:	55650513          	addi	a0,a0,1366 # 80021a50 <ftable>
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	7b2080e7          	jalr	1970(ra) # 80000cb4 <release>
  return 0;
    8000450a:	4481                	li	s1,0
    8000450c:	a819                	j	80004522 <filealloc+0x5e>
      f->ref = 1;
    8000450e:	4785                	li	a5,1
    80004510:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004512:	0001d517          	auipc	a0,0x1d
    80004516:	53e50513          	addi	a0,a0,1342 # 80021a50 <ftable>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	79a080e7          	jalr	1946(ra) # 80000cb4 <release>
}
    80004522:	8526                	mv	a0,s1
    80004524:	60e2                	ld	ra,24(sp)
    80004526:	6442                	ld	s0,16(sp)
    80004528:	64a2                	ld	s1,8(sp)
    8000452a:	6105                	addi	sp,sp,32
    8000452c:	8082                	ret

000000008000452e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000452e:	1101                	addi	sp,sp,-32
    80004530:	ec06                	sd	ra,24(sp)
    80004532:	e822                	sd	s0,16(sp)
    80004534:	e426                	sd	s1,8(sp)
    80004536:	1000                	addi	s0,sp,32
    80004538:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000453a:	0001d517          	auipc	a0,0x1d
    8000453e:	51650513          	addi	a0,a0,1302 # 80021a50 <ftable>
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	6be080e7          	jalr	1726(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    8000454a:	40dc                	lw	a5,4(s1)
    8000454c:	02f05263          	blez	a5,80004570 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004550:	2785                	addiw	a5,a5,1
    80004552:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004554:	0001d517          	auipc	a0,0x1d
    80004558:	4fc50513          	addi	a0,a0,1276 # 80021a50 <ftable>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	758080e7          	jalr	1880(ra) # 80000cb4 <release>
  return f;
}
    80004564:	8526                	mv	a0,s1
    80004566:	60e2                	ld	ra,24(sp)
    80004568:	6442                	ld	s0,16(sp)
    8000456a:	64a2                	ld	s1,8(sp)
    8000456c:	6105                	addi	sp,sp,32
    8000456e:	8082                	ret
    panic("filedup");
    80004570:	00004517          	auipc	a0,0x4
    80004574:	09050513          	addi	a0,a0,144 # 80008600 <syscalls+0x240>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	fce080e7          	jalr	-50(ra) # 80000546 <panic>

0000000080004580 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004580:	7139                	addi	sp,sp,-64
    80004582:	fc06                	sd	ra,56(sp)
    80004584:	f822                	sd	s0,48(sp)
    80004586:	f426                	sd	s1,40(sp)
    80004588:	f04a                	sd	s2,32(sp)
    8000458a:	ec4e                	sd	s3,24(sp)
    8000458c:	e852                	sd	s4,16(sp)
    8000458e:	e456                	sd	s5,8(sp)
    80004590:	0080                	addi	s0,sp,64
    80004592:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004594:	0001d517          	auipc	a0,0x1d
    80004598:	4bc50513          	addi	a0,a0,1212 # 80021a50 <ftable>
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	664080e7          	jalr	1636(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    800045a4:	40dc                	lw	a5,4(s1)
    800045a6:	06f05163          	blez	a5,80004608 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045aa:	37fd                	addiw	a5,a5,-1
    800045ac:	0007871b          	sext.w	a4,a5
    800045b0:	c0dc                	sw	a5,4(s1)
    800045b2:	06e04363          	bgtz	a4,80004618 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045b6:	0004a903          	lw	s2,0(s1)
    800045ba:	0094ca83          	lbu	s5,9(s1)
    800045be:	0104ba03          	ld	s4,16(s1)
    800045c2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045c6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045ca:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045ce:	0001d517          	auipc	a0,0x1d
    800045d2:	48250513          	addi	a0,a0,1154 # 80021a50 <ftable>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	6de080e7          	jalr	1758(ra) # 80000cb4 <release>

  if(ff.type == FD_PIPE){
    800045de:	4785                	li	a5,1
    800045e0:	04f90d63          	beq	s2,a5,8000463a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045e4:	3979                	addiw	s2,s2,-2
    800045e6:	4785                	li	a5,1
    800045e8:	0527e063          	bltu	a5,s2,80004628 <fileclose+0xa8>
    begin_op();
    800045ec:	00000097          	auipc	ra,0x0
    800045f0:	ac6080e7          	jalr	-1338(ra) # 800040b2 <begin_op>
    iput(ff.ip);
    800045f4:	854e                	mv	a0,s3
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	2ac080e7          	jalr	684(ra) # 800038a2 <iput>
    end_op();
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	b32080e7          	jalr	-1230(ra) # 80004130 <end_op>
    80004606:	a00d                	j	80004628 <fileclose+0xa8>
    panic("fileclose");
    80004608:	00004517          	auipc	a0,0x4
    8000460c:	00050513          	mv	a0,a0
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	f36080e7          	jalr	-202(ra) # 80000546 <panic>
    release(&ftable.lock);
    80004618:	0001d517          	auipc	a0,0x1d
    8000461c:	43850513          	addi	a0,a0,1080 # 80021a50 <ftable>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	694080e7          	jalr	1684(ra) # 80000cb4 <release>
  }
}
    80004628:	70e2                	ld	ra,56(sp)
    8000462a:	7442                	ld	s0,48(sp)
    8000462c:	74a2                	ld	s1,40(sp)
    8000462e:	7902                	ld	s2,32(sp)
    80004630:	69e2                	ld	s3,24(sp)
    80004632:	6a42                	ld	s4,16(sp)
    80004634:	6aa2                	ld	s5,8(sp)
    80004636:	6121                	addi	sp,sp,64
    80004638:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000463a:	85d6                	mv	a1,s5
    8000463c:	8552                	mv	a0,s4
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	372080e7          	jalr	882(ra) # 800049b0 <pipeclose>
    80004646:	b7cd                	j	80004628 <fileclose+0xa8>

0000000080004648 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004648:	715d                	addi	sp,sp,-80
    8000464a:	e486                	sd	ra,72(sp)
    8000464c:	e0a2                	sd	s0,64(sp)
    8000464e:	fc26                	sd	s1,56(sp)
    80004650:	f84a                	sd	s2,48(sp)
    80004652:	f44e                	sd	s3,40(sp)
    80004654:	0880                	addi	s0,sp,80
    80004656:	84aa                	mv	s1,a0
    80004658:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000465a:	ffffd097          	auipc	ra,0xffffd
    8000465e:	3b4080e7          	jalr	948(ra) # 80001a0e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004662:	409c                	lw	a5,0(s1)
    80004664:	37f9                	addiw	a5,a5,-2
    80004666:	4705                	li	a4,1
    80004668:	04f76763          	bltu	a4,a5,800046b6 <filestat+0x6e>
    8000466c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000466e:	6c88                	ld	a0,24(s1)
    80004670:	fffff097          	auipc	ra,0xfffff
    80004674:	078080e7          	jalr	120(ra) # 800036e8 <ilock>
    stati(f->ip, &st);
    80004678:	fb840593          	addi	a1,s0,-72
    8000467c:	6c88                	ld	a0,24(s1)
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	2f4080e7          	jalr	756(ra) # 80003972 <stati>
    iunlock(f->ip);
    80004686:	6c88                	ld	a0,24(s1)
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	122080e7          	jalr	290(ra) # 800037aa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004690:	46e1                	li	a3,24
    80004692:	fb840613          	addi	a2,s0,-72
    80004696:	85ce                	mv	a1,s3
    80004698:	05093503          	ld	a0,80(s2)
    8000469c:	ffffd097          	auipc	ra,0xffffd
    800046a0:	068080e7          	jalr	104(ra) # 80001704 <copyout>
    800046a4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046a8:	60a6                	ld	ra,72(sp)
    800046aa:	6406                	ld	s0,64(sp)
    800046ac:	74e2                	ld	s1,56(sp)
    800046ae:	7942                	ld	s2,48(sp)
    800046b0:	79a2                	ld	s3,40(sp)
    800046b2:	6161                	addi	sp,sp,80
    800046b4:	8082                	ret
  return -1;
    800046b6:	557d                	li	a0,-1
    800046b8:	bfc5                	j	800046a8 <filestat+0x60>

00000000800046ba <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046ba:	7179                	addi	sp,sp,-48
    800046bc:	f406                	sd	ra,40(sp)
    800046be:	f022                	sd	s0,32(sp)
    800046c0:	ec26                	sd	s1,24(sp)
    800046c2:	e84a                	sd	s2,16(sp)
    800046c4:	e44e                	sd	s3,8(sp)
    800046c6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046c8:	00854783          	lbu	a5,8(a0)
    800046cc:	c3d5                	beqz	a5,80004770 <fileread+0xb6>
    800046ce:	84aa                	mv	s1,a0
    800046d0:	89ae                	mv	s3,a1
    800046d2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046d4:	411c                	lw	a5,0(a0)
    800046d6:	4705                	li	a4,1
    800046d8:	04e78963          	beq	a5,a4,8000472a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046dc:	470d                	li	a4,3
    800046de:	04e78d63          	beq	a5,a4,80004738 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046e2:	4709                	li	a4,2
    800046e4:	06e79e63          	bne	a5,a4,80004760 <fileread+0xa6>
    ilock(f->ip);
    800046e8:	6d08                	ld	a0,24(a0)
    800046ea:	fffff097          	auipc	ra,0xfffff
    800046ee:	ffe080e7          	jalr	-2(ra) # 800036e8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046f2:	874a                	mv	a4,s2
    800046f4:	5094                	lw	a3,32(s1)
    800046f6:	864e                	mv	a2,s3
    800046f8:	4585                	li	a1,1
    800046fa:	6c88                	ld	a0,24(s1)
    800046fc:	fffff097          	auipc	ra,0xfffff
    80004700:	2a0080e7          	jalr	672(ra) # 8000399c <readi>
    80004704:	892a                	mv	s2,a0
    80004706:	00a05563          	blez	a0,80004710 <fileread+0x56>
      f->off += r;
    8000470a:	509c                	lw	a5,32(s1)
    8000470c:	9fa9                	addw	a5,a5,a0
    8000470e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004710:	6c88                	ld	a0,24(s1)
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	098080e7          	jalr	152(ra) # 800037aa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000471a:	854a                	mv	a0,s2
    8000471c:	70a2                	ld	ra,40(sp)
    8000471e:	7402                	ld	s0,32(sp)
    80004720:	64e2                	ld	s1,24(sp)
    80004722:	6942                	ld	s2,16(sp)
    80004724:	69a2                	ld	s3,8(sp)
    80004726:	6145                	addi	sp,sp,48
    80004728:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000472a:	6908                	ld	a0,16(a0)
    8000472c:	00000097          	auipc	ra,0x0
    80004730:	3f6080e7          	jalr	1014(ra) # 80004b22 <piperead>
    80004734:	892a                	mv	s2,a0
    80004736:	b7d5                	j	8000471a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004738:	02451783          	lh	a5,36(a0)
    8000473c:	03079693          	slli	a3,a5,0x30
    80004740:	92c1                	srli	a3,a3,0x30
    80004742:	4725                	li	a4,9
    80004744:	02d76863          	bltu	a4,a3,80004774 <fileread+0xba>
    80004748:	0792                	slli	a5,a5,0x4
    8000474a:	0001d717          	auipc	a4,0x1d
    8000474e:	26670713          	addi	a4,a4,614 # 800219b0 <devsw>
    80004752:	97ba                	add	a5,a5,a4
    80004754:	639c                	ld	a5,0(a5)
    80004756:	c38d                	beqz	a5,80004778 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004758:	4505                	li	a0,1
    8000475a:	9782                	jalr	a5
    8000475c:	892a                	mv	s2,a0
    8000475e:	bf75                	j	8000471a <fileread+0x60>
    panic("fileread");
    80004760:	00004517          	auipc	a0,0x4
    80004764:	eb850513          	addi	a0,a0,-328 # 80008618 <syscalls+0x258>
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	dde080e7          	jalr	-546(ra) # 80000546 <panic>
    return -1;
    80004770:	597d                	li	s2,-1
    80004772:	b765                	j	8000471a <fileread+0x60>
      return -1;
    80004774:	597d                	li	s2,-1
    80004776:	b755                	j	8000471a <fileread+0x60>
    80004778:	597d                	li	s2,-1
    8000477a:	b745                	j	8000471a <fileread+0x60>

000000008000477c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000477c:	00954783          	lbu	a5,9(a0)
    80004780:	14078563          	beqz	a5,800048ca <filewrite+0x14e>
{
    80004784:	715d                	addi	sp,sp,-80
    80004786:	e486                	sd	ra,72(sp)
    80004788:	e0a2                	sd	s0,64(sp)
    8000478a:	fc26                	sd	s1,56(sp)
    8000478c:	f84a                	sd	s2,48(sp)
    8000478e:	f44e                	sd	s3,40(sp)
    80004790:	f052                	sd	s4,32(sp)
    80004792:	ec56                	sd	s5,24(sp)
    80004794:	e85a                	sd	s6,16(sp)
    80004796:	e45e                	sd	s7,8(sp)
    80004798:	e062                	sd	s8,0(sp)
    8000479a:	0880                	addi	s0,sp,80
    8000479c:	892a                	mv	s2,a0
    8000479e:	8b2e                	mv	s6,a1
    800047a0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047a2:	411c                	lw	a5,0(a0)
    800047a4:	4705                	li	a4,1
    800047a6:	02e78263          	beq	a5,a4,800047ca <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047aa:	470d                	li	a4,3
    800047ac:	02e78563          	beq	a5,a4,800047d6 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047b0:	4709                	li	a4,2
    800047b2:	10e79463          	bne	a5,a4,800048ba <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047b6:	0ec05e63          	blez	a2,800048b2 <filewrite+0x136>
    int i = 0;
    800047ba:	4981                	li	s3,0
    800047bc:	6b85                	lui	s7,0x1
    800047be:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047c2:	6c05                	lui	s8,0x1
    800047c4:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047c8:	a851                	j	8000485c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047ca:	6908                	ld	a0,16(a0)
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	254080e7          	jalr	596(ra) # 80004a20 <pipewrite>
    800047d4:	a85d                	j	8000488a <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047d6:	02451783          	lh	a5,36(a0)
    800047da:	03079693          	slli	a3,a5,0x30
    800047de:	92c1                	srli	a3,a3,0x30
    800047e0:	4725                	li	a4,9
    800047e2:	0ed76663          	bltu	a4,a3,800048ce <filewrite+0x152>
    800047e6:	0792                	slli	a5,a5,0x4
    800047e8:	0001d717          	auipc	a4,0x1d
    800047ec:	1c870713          	addi	a4,a4,456 # 800219b0 <devsw>
    800047f0:	97ba                	add	a5,a5,a4
    800047f2:	679c                	ld	a5,8(a5)
    800047f4:	cff9                	beqz	a5,800048d2 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800047f6:	4505                	li	a0,1
    800047f8:	9782                	jalr	a5
    800047fa:	a841                	j	8000488a <filewrite+0x10e>
    800047fc:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004800:	00000097          	auipc	ra,0x0
    80004804:	8b2080e7          	jalr	-1870(ra) # 800040b2 <begin_op>
      ilock(f->ip);
    80004808:	01893503          	ld	a0,24(s2)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	edc080e7          	jalr	-292(ra) # 800036e8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004814:	8756                	mv	a4,s5
    80004816:	02092683          	lw	a3,32(s2)
    8000481a:	01698633          	add	a2,s3,s6
    8000481e:	4585                	li	a1,1
    80004820:	01893503          	ld	a0,24(s2)
    80004824:	fffff097          	auipc	ra,0xfffff
    80004828:	270080e7          	jalr	624(ra) # 80003a94 <writei>
    8000482c:	84aa                	mv	s1,a0
    8000482e:	02a05f63          	blez	a0,8000486c <filewrite+0xf0>
        f->off += r;
    80004832:	02092783          	lw	a5,32(s2)
    80004836:	9fa9                	addw	a5,a5,a0
    80004838:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000483c:	01893503          	ld	a0,24(s2)
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	f6a080e7          	jalr	-150(ra) # 800037aa <iunlock>
      end_op();
    80004848:	00000097          	auipc	ra,0x0
    8000484c:	8e8080e7          	jalr	-1816(ra) # 80004130 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004850:	049a9963          	bne	s5,s1,800048a2 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004854:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004858:	0349d663          	bge	s3,s4,80004884 <filewrite+0x108>
      int n1 = n - i;
    8000485c:	413a04bb          	subw	s1,s4,s3
    80004860:	0004879b          	sext.w	a5,s1
    80004864:	f8fbdce3          	bge	s7,a5,800047fc <filewrite+0x80>
    80004868:	84e2                	mv	s1,s8
    8000486a:	bf49                	j	800047fc <filewrite+0x80>
      iunlock(f->ip);
    8000486c:	01893503          	ld	a0,24(s2)
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	f3a080e7          	jalr	-198(ra) # 800037aa <iunlock>
      end_op();
    80004878:	00000097          	auipc	ra,0x0
    8000487c:	8b8080e7          	jalr	-1864(ra) # 80004130 <end_op>
      if(r < 0)
    80004880:	fc04d8e3          	bgez	s1,80004850 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004884:	8552                	mv	a0,s4
    80004886:	033a1863          	bne	s4,s3,800048b6 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000488a:	60a6                	ld	ra,72(sp)
    8000488c:	6406                	ld	s0,64(sp)
    8000488e:	74e2                	ld	s1,56(sp)
    80004890:	7942                	ld	s2,48(sp)
    80004892:	79a2                	ld	s3,40(sp)
    80004894:	7a02                	ld	s4,32(sp)
    80004896:	6ae2                	ld	s5,24(sp)
    80004898:	6b42                	ld	s6,16(sp)
    8000489a:	6ba2                	ld	s7,8(sp)
    8000489c:	6c02                	ld	s8,0(sp)
    8000489e:	6161                	addi	sp,sp,80
    800048a0:	8082                	ret
        panic("short filewrite");
    800048a2:	00004517          	auipc	a0,0x4
    800048a6:	d8650513          	addi	a0,a0,-634 # 80008628 <syscalls+0x268>
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	c9c080e7          	jalr	-868(ra) # 80000546 <panic>
    int i = 0;
    800048b2:	4981                	li	s3,0
    800048b4:	bfc1                	j	80004884 <filewrite+0x108>
    ret = (i == n ? n : -1);
    800048b6:	557d                	li	a0,-1
    800048b8:	bfc9                	j	8000488a <filewrite+0x10e>
    panic("filewrite");
    800048ba:	00004517          	auipc	a0,0x4
    800048be:	d7e50513          	addi	a0,a0,-642 # 80008638 <syscalls+0x278>
    800048c2:	ffffc097          	auipc	ra,0xffffc
    800048c6:	c84080e7          	jalr	-892(ra) # 80000546 <panic>
    return -1;
    800048ca:	557d                	li	a0,-1
}
    800048cc:	8082                	ret
      return -1;
    800048ce:	557d                	li	a0,-1
    800048d0:	bf6d                	j	8000488a <filewrite+0x10e>
    800048d2:	557d                	li	a0,-1
    800048d4:	bf5d                	j	8000488a <filewrite+0x10e>

00000000800048d6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048d6:	7179                	addi	sp,sp,-48
    800048d8:	f406                	sd	ra,40(sp)
    800048da:	f022                	sd	s0,32(sp)
    800048dc:	ec26                	sd	s1,24(sp)
    800048de:	e84a                	sd	s2,16(sp)
    800048e0:	e44e                	sd	s3,8(sp)
    800048e2:	e052                	sd	s4,0(sp)
    800048e4:	1800                	addi	s0,sp,48
    800048e6:	84aa                	mv	s1,a0
    800048e8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048ea:	0005b023          	sd	zero,0(a1)
    800048ee:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048f2:	00000097          	auipc	ra,0x0
    800048f6:	bd2080e7          	jalr	-1070(ra) # 800044c4 <filealloc>
    800048fa:	e088                	sd	a0,0(s1)
    800048fc:	c551                	beqz	a0,80004988 <pipealloc+0xb2>
    800048fe:	00000097          	auipc	ra,0x0
    80004902:	bc6080e7          	jalr	-1082(ra) # 800044c4 <filealloc>
    80004906:	00aa3023          	sd	a0,0(s4)
    8000490a:	c92d                	beqz	a0,8000497c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	204080e7          	jalr	516(ra) # 80000b10 <kalloc>
    80004914:	892a                	mv	s2,a0
    80004916:	c125                	beqz	a0,80004976 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004918:	4985                	li	s3,1
    8000491a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000491e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004922:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004926:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000492a:	00004597          	auipc	a1,0x4
    8000492e:	d1e58593          	addi	a1,a1,-738 # 80008648 <syscalls+0x288>
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	23e080e7          	jalr	574(ra) # 80000b70 <initlock>
  (*f0)->type = FD_PIPE;
    8000493a:	609c                	ld	a5,0(s1)
    8000493c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004940:	609c                	ld	a5,0(s1)
    80004942:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004946:	609c                	ld	a5,0(s1)
    80004948:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000494c:	609c                	ld	a5,0(s1)
    8000494e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004952:	000a3783          	ld	a5,0(s4)
    80004956:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000495a:	000a3783          	ld	a5,0(s4)
    8000495e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004962:	000a3783          	ld	a5,0(s4)
    80004966:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000496a:	000a3783          	ld	a5,0(s4)
    8000496e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004972:	4501                	li	a0,0
    80004974:	a025                	j	8000499c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004976:	6088                	ld	a0,0(s1)
    80004978:	e501                	bnez	a0,80004980 <pipealloc+0xaa>
    8000497a:	a039                	j	80004988 <pipealloc+0xb2>
    8000497c:	6088                	ld	a0,0(s1)
    8000497e:	c51d                	beqz	a0,800049ac <pipealloc+0xd6>
    fileclose(*f0);
    80004980:	00000097          	auipc	ra,0x0
    80004984:	c00080e7          	jalr	-1024(ra) # 80004580 <fileclose>
  if(*f1)
    80004988:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000498c:	557d                	li	a0,-1
  if(*f1)
    8000498e:	c799                	beqz	a5,8000499c <pipealloc+0xc6>
    fileclose(*f1);
    80004990:	853e                	mv	a0,a5
    80004992:	00000097          	auipc	ra,0x0
    80004996:	bee080e7          	jalr	-1042(ra) # 80004580 <fileclose>
  return -1;
    8000499a:	557d                	li	a0,-1
}
    8000499c:	70a2                	ld	ra,40(sp)
    8000499e:	7402                	ld	s0,32(sp)
    800049a0:	64e2                	ld	s1,24(sp)
    800049a2:	6942                	ld	s2,16(sp)
    800049a4:	69a2                	ld	s3,8(sp)
    800049a6:	6a02                	ld	s4,0(sp)
    800049a8:	6145                	addi	sp,sp,48
    800049aa:	8082                	ret
  return -1;
    800049ac:	557d                	li	a0,-1
    800049ae:	b7fd                	j	8000499c <pipealloc+0xc6>

00000000800049b0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049b0:	1101                	addi	sp,sp,-32
    800049b2:	ec06                	sd	ra,24(sp)
    800049b4:	e822                	sd	s0,16(sp)
    800049b6:	e426                	sd	s1,8(sp)
    800049b8:	e04a                	sd	s2,0(sp)
    800049ba:	1000                	addi	s0,sp,32
    800049bc:	84aa                	mv	s1,a0
    800049be:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	240080e7          	jalr	576(ra) # 80000c00 <acquire>
  if(writable){
    800049c8:	02090d63          	beqz	s2,80004a02 <pipeclose+0x52>
    pi->writeopen = 0;
    800049cc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049d0:	21848513          	addi	a0,s1,536
    800049d4:	ffffe097          	auipc	ra,0xffffe
    800049d8:	9d2080e7          	jalr	-1582(ra) # 800023a6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049dc:	2204b783          	ld	a5,544(s1)
    800049e0:	eb95                	bnez	a5,80004a14 <pipeclose+0x64>
    release(&pi->lock);
    800049e2:	8526                	mv	a0,s1
    800049e4:	ffffc097          	auipc	ra,0xffffc
    800049e8:	2d0080e7          	jalr	720(ra) # 80000cb4 <release>
    kfree((char*)pi);
    800049ec:	8526                	mv	a0,s1
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	024080e7          	jalr	36(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    800049f6:	60e2                	ld	ra,24(sp)
    800049f8:	6442                	ld	s0,16(sp)
    800049fa:	64a2                	ld	s1,8(sp)
    800049fc:	6902                	ld	s2,0(sp)
    800049fe:	6105                	addi	sp,sp,32
    80004a00:	8082                	ret
    pi->readopen = 0;
    80004a02:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a06:	21c48513          	addi	a0,s1,540
    80004a0a:	ffffe097          	auipc	ra,0xffffe
    80004a0e:	99c080e7          	jalr	-1636(ra) # 800023a6 <wakeup>
    80004a12:	b7e9                	j	800049dc <pipeclose+0x2c>
    release(&pi->lock);
    80004a14:	8526                	mv	a0,s1
    80004a16:	ffffc097          	auipc	ra,0xffffc
    80004a1a:	29e080e7          	jalr	670(ra) # 80000cb4 <release>
}
    80004a1e:	bfe1                	j	800049f6 <pipeclose+0x46>

0000000080004a20 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a20:	711d                	addi	sp,sp,-96
    80004a22:	ec86                	sd	ra,88(sp)
    80004a24:	e8a2                	sd	s0,80(sp)
    80004a26:	e4a6                	sd	s1,72(sp)
    80004a28:	e0ca                	sd	s2,64(sp)
    80004a2a:	fc4e                	sd	s3,56(sp)
    80004a2c:	f852                	sd	s4,48(sp)
    80004a2e:	f456                	sd	s5,40(sp)
    80004a30:	f05a                	sd	s6,32(sp)
    80004a32:	ec5e                	sd	s7,24(sp)
    80004a34:	e862                	sd	s8,16(sp)
    80004a36:	1080                	addi	s0,sp,96
    80004a38:	84aa                	mv	s1,a0
    80004a3a:	8b2e                	mv	s6,a1
    80004a3c:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a3e:	ffffd097          	auipc	ra,0xffffd
    80004a42:	fd0080e7          	jalr	-48(ra) # 80001a0e <myproc>
    80004a46:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a48:	8526                	mv	a0,s1
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	1b6080e7          	jalr	438(ra) # 80000c00 <acquire>
  for(i = 0; i < n; i++){
    80004a52:	09505863          	blez	s5,80004ae2 <pipewrite+0xc2>
    80004a56:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a58:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a5c:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a60:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a62:	2184a783          	lw	a5,536(s1)
    80004a66:	21c4a703          	lw	a4,540(s1)
    80004a6a:	2007879b          	addiw	a5,a5,512
    80004a6e:	02f71b63          	bne	a4,a5,80004aa4 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004a72:	2204a783          	lw	a5,544(s1)
    80004a76:	c3d9                	beqz	a5,80004afc <pipewrite+0xdc>
    80004a78:	03092783          	lw	a5,48(s2)
    80004a7c:	e3c1                	bnez	a5,80004afc <pipewrite+0xdc>
      wakeup(&pi->nread);
    80004a7e:	8552                	mv	a0,s4
    80004a80:	ffffe097          	auipc	ra,0xffffe
    80004a84:	926080e7          	jalr	-1754(ra) # 800023a6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a88:	85a6                	mv	a1,s1
    80004a8a:	854e                	mv	a0,s3
    80004a8c:	ffffd097          	auipc	ra,0xffffd
    80004a90:	79a080e7          	jalr	1946(ra) # 80002226 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a94:	2184a783          	lw	a5,536(s1)
    80004a98:	21c4a703          	lw	a4,540(s1)
    80004a9c:	2007879b          	addiw	a5,a5,512
    80004aa0:	fcf709e3          	beq	a4,a5,80004a72 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aa4:	4685                	li	a3,1
    80004aa6:	865a                	mv	a2,s6
    80004aa8:	faf40593          	addi	a1,s0,-81
    80004aac:	05093503          	ld	a0,80(s2)
    80004ab0:	ffffd097          	auipc	ra,0xffffd
    80004ab4:	ce0080e7          	jalr	-800(ra) # 80001790 <copyin>
    80004ab8:	03850663          	beq	a0,s8,80004ae4 <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004abc:	21c4a783          	lw	a5,540(s1)
    80004ac0:	0017871b          	addiw	a4,a5,1
    80004ac4:	20e4ae23          	sw	a4,540(s1)
    80004ac8:	1ff7f793          	andi	a5,a5,511
    80004acc:	97a6                	add	a5,a5,s1
    80004ace:	faf44703          	lbu	a4,-81(s0)
    80004ad2:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004ad6:	2b85                	addiw	s7,s7,1
    80004ad8:	0b05                	addi	s6,s6,1
    80004ada:	f97a94e3          	bne	s5,s7,80004a62 <pipewrite+0x42>
    80004ade:	8bd6                	mv	s7,s5
    80004ae0:	a011                	j	80004ae4 <pipewrite+0xc4>
    80004ae2:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004ae4:	21848513          	addi	a0,s1,536
    80004ae8:	ffffe097          	auipc	ra,0xffffe
    80004aec:	8be080e7          	jalr	-1858(ra) # 800023a6 <wakeup>
  release(&pi->lock);
    80004af0:	8526                	mv	a0,s1
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	1c2080e7          	jalr	450(ra) # 80000cb4 <release>
  return i;
    80004afa:	a039                	j	80004b08 <pipewrite+0xe8>
        release(&pi->lock);
    80004afc:	8526                	mv	a0,s1
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	1b6080e7          	jalr	438(ra) # 80000cb4 <release>
        return -1;
    80004b06:	5bfd                	li	s7,-1
}
    80004b08:	855e                	mv	a0,s7
    80004b0a:	60e6                	ld	ra,88(sp)
    80004b0c:	6446                	ld	s0,80(sp)
    80004b0e:	64a6                	ld	s1,72(sp)
    80004b10:	6906                	ld	s2,64(sp)
    80004b12:	79e2                	ld	s3,56(sp)
    80004b14:	7a42                	ld	s4,48(sp)
    80004b16:	7aa2                	ld	s5,40(sp)
    80004b18:	7b02                	ld	s6,32(sp)
    80004b1a:	6be2                	ld	s7,24(sp)
    80004b1c:	6c42                	ld	s8,16(sp)
    80004b1e:	6125                	addi	sp,sp,96
    80004b20:	8082                	ret

0000000080004b22 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b22:	715d                	addi	sp,sp,-80
    80004b24:	e486                	sd	ra,72(sp)
    80004b26:	e0a2                	sd	s0,64(sp)
    80004b28:	fc26                	sd	s1,56(sp)
    80004b2a:	f84a                	sd	s2,48(sp)
    80004b2c:	f44e                	sd	s3,40(sp)
    80004b2e:	f052                	sd	s4,32(sp)
    80004b30:	ec56                	sd	s5,24(sp)
    80004b32:	e85a                	sd	s6,16(sp)
    80004b34:	0880                	addi	s0,sp,80
    80004b36:	84aa                	mv	s1,a0
    80004b38:	892e                	mv	s2,a1
    80004b3a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b3c:	ffffd097          	auipc	ra,0xffffd
    80004b40:	ed2080e7          	jalr	-302(ra) # 80001a0e <myproc>
    80004b44:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b46:	8526                	mv	a0,s1
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	0b8080e7          	jalr	184(ra) # 80000c00 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b50:	2184a703          	lw	a4,536(s1)
    80004b54:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b58:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b5c:	02f71463          	bne	a4,a5,80004b84 <piperead+0x62>
    80004b60:	2244a783          	lw	a5,548(s1)
    80004b64:	c385                	beqz	a5,80004b84 <piperead+0x62>
    if(pr->killed){
    80004b66:	030a2783          	lw	a5,48(s4)
    80004b6a:	ebc9                	bnez	a5,80004bfc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b6c:	85a6                	mv	a1,s1
    80004b6e:	854e                	mv	a0,s3
    80004b70:	ffffd097          	auipc	ra,0xffffd
    80004b74:	6b6080e7          	jalr	1718(ra) # 80002226 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b78:	2184a703          	lw	a4,536(s1)
    80004b7c:	21c4a783          	lw	a5,540(s1)
    80004b80:	fef700e3          	beq	a4,a5,80004b60 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b84:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b86:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b88:	05505463          	blez	s5,80004bd0 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004b8c:	2184a783          	lw	a5,536(s1)
    80004b90:	21c4a703          	lw	a4,540(s1)
    80004b94:	02f70e63          	beq	a4,a5,80004bd0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b98:	0017871b          	addiw	a4,a5,1
    80004b9c:	20e4ac23          	sw	a4,536(s1)
    80004ba0:	1ff7f793          	andi	a5,a5,511
    80004ba4:	97a6                	add	a5,a5,s1
    80004ba6:	0187c783          	lbu	a5,24(a5)
    80004baa:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bae:	4685                	li	a3,1
    80004bb0:	fbf40613          	addi	a2,s0,-65
    80004bb4:	85ca                	mv	a1,s2
    80004bb6:	050a3503          	ld	a0,80(s4)
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	b4a080e7          	jalr	-1206(ra) # 80001704 <copyout>
    80004bc2:	01650763          	beq	a0,s6,80004bd0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc6:	2985                	addiw	s3,s3,1
    80004bc8:	0905                	addi	s2,s2,1
    80004bca:	fd3a91e3          	bne	s5,s3,80004b8c <piperead+0x6a>
    80004bce:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bd0:	21c48513          	addi	a0,s1,540
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	7d2080e7          	jalr	2002(ra) # 800023a6 <wakeup>
  release(&pi->lock);
    80004bdc:	8526                	mv	a0,s1
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	0d6080e7          	jalr	214(ra) # 80000cb4 <release>
  return i;
}
    80004be6:	854e                	mv	a0,s3
    80004be8:	60a6                	ld	ra,72(sp)
    80004bea:	6406                	ld	s0,64(sp)
    80004bec:	74e2                	ld	s1,56(sp)
    80004bee:	7942                	ld	s2,48(sp)
    80004bf0:	79a2                	ld	s3,40(sp)
    80004bf2:	7a02                	ld	s4,32(sp)
    80004bf4:	6ae2                	ld	s5,24(sp)
    80004bf6:	6b42                	ld	s6,16(sp)
    80004bf8:	6161                	addi	sp,sp,80
    80004bfa:	8082                	ret
      release(&pi->lock);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	0b6080e7          	jalr	182(ra) # 80000cb4 <release>
      return -1;
    80004c06:	59fd                	li	s3,-1
    80004c08:	bff9                	j	80004be6 <piperead+0xc4>

0000000080004c0a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c0a:	de010113          	addi	sp,sp,-544
    80004c0e:	20113c23          	sd	ra,536(sp)
    80004c12:	20813823          	sd	s0,528(sp)
    80004c16:	20913423          	sd	s1,520(sp)
    80004c1a:	21213023          	sd	s2,512(sp)
    80004c1e:	ffce                	sd	s3,504(sp)
    80004c20:	fbd2                	sd	s4,496(sp)
    80004c22:	f7d6                	sd	s5,488(sp)
    80004c24:	f3da                	sd	s6,480(sp)
    80004c26:	efde                	sd	s7,472(sp)
    80004c28:	ebe2                	sd	s8,464(sp)
    80004c2a:	e7e6                	sd	s9,456(sp)
    80004c2c:	e3ea                	sd	s10,448(sp)
    80004c2e:	ff6e                	sd	s11,440(sp)
    80004c30:	1400                	addi	s0,sp,544
    80004c32:	892a                	mv	s2,a0
    80004c34:	dea43423          	sd	a0,-536(s0)
    80004c38:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	dd2080e7          	jalr	-558(ra) # 80001a0e <myproc>
    80004c44:	84aa                	mv	s1,a0

  begin_op();
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	46c080e7          	jalr	1132(ra) # 800040b2 <begin_op>

  if((ip = namei(path)) == 0){
    80004c4e:	854a                	mv	a0,s2
    80004c50:	fffff097          	auipc	ra,0xfffff
    80004c54:	252080e7          	jalr	594(ra) # 80003ea2 <namei>
    80004c58:	c93d                	beqz	a0,80004cce <exec+0xc4>
    80004c5a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	a8c080e7          	jalr	-1396(ra) # 800036e8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c64:	04000713          	li	a4,64
    80004c68:	4681                	li	a3,0
    80004c6a:	e4840613          	addi	a2,s0,-440
    80004c6e:	4581                	li	a1,0
    80004c70:	8556                	mv	a0,s5
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	d2a080e7          	jalr	-726(ra) # 8000399c <readi>
    80004c7a:	04000793          	li	a5,64
    80004c7e:	00f51a63          	bne	a0,a5,80004c92 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c82:	e4842703          	lw	a4,-440(s0)
    80004c86:	464c47b7          	lui	a5,0x464c4
    80004c8a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c8e:	04f70663          	beq	a4,a5,80004cda <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c92:	8556                	mv	a0,s5
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	cb6080e7          	jalr	-842(ra) # 8000394a <iunlockput>
    end_op();
    80004c9c:	fffff097          	auipc	ra,0xfffff
    80004ca0:	494080e7          	jalr	1172(ra) # 80004130 <end_op>
  }
  return -1;
    80004ca4:	557d                	li	a0,-1
}
    80004ca6:	21813083          	ld	ra,536(sp)
    80004caa:	21013403          	ld	s0,528(sp)
    80004cae:	20813483          	ld	s1,520(sp)
    80004cb2:	20013903          	ld	s2,512(sp)
    80004cb6:	79fe                	ld	s3,504(sp)
    80004cb8:	7a5e                	ld	s4,496(sp)
    80004cba:	7abe                	ld	s5,488(sp)
    80004cbc:	7b1e                	ld	s6,480(sp)
    80004cbe:	6bfe                	ld	s7,472(sp)
    80004cc0:	6c5e                	ld	s8,464(sp)
    80004cc2:	6cbe                	ld	s9,456(sp)
    80004cc4:	6d1e                	ld	s10,448(sp)
    80004cc6:	7dfa                	ld	s11,440(sp)
    80004cc8:	22010113          	addi	sp,sp,544
    80004ccc:	8082                	ret
    end_op();
    80004cce:	fffff097          	auipc	ra,0xfffff
    80004cd2:	462080e7          	jalr	1122(ra) # 80004130 <end_op>
    return -1;
    80004cd6:	557d                	li	a0,-1
    80004cd8:	b7f9                	j	80004ca6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	df6080e7          	jalr	-522(ra) # 80001ad2 <proc_pagetable>
    80004ce4:	8b2a                	mv	s6,a0
    80004ce6:	d555                	beqz	a0,80004c92 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ce8:	e6842783          	lw	a5,-408(s0)
    80004cec:	e8045703          	lhu	a4,-384(s0)
    80004cf0:	c735                	beqz	a4,80004d5c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cf2:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cf4:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004cf8:	6a05                	lui	s4,0x1
    80004cfa:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004cfe:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004d02:	6d85                	lui	s11,0x1
    80004d04:	7d7d                	lui	s10,0xfffff
    80004d06:	ac1d                	j	80004f3c <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d08:	00004517          	auipc	a0,0x4
    80004d0c:	94850513          	addi	a0,a0,-1720 # 80008650 <syscalls+0x290>
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	836080e7          	jalr	-1994(ra) # 80000546 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d18:	874a                	mv	a4,s2
    80004d1a:	009c86bb          	addw	a3,s9,s1
    80004d1e:	4581                	li	a1,0
    80004d20:	8556                	mv	a0,s5
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	c7a080e7          	jalr	-902(ra) # 8000399c <readi>
    80004d2a:	2501                	sext.w	a0,a0
    80004d2c:	1aa91863          	bne	s2,a0,80004edc <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d30:	009d84bb          	addw	s1,s11,s1
    80004d34:	013d09bb          	addw	s3,s10,s3
    80004d38:	1f74f263          	bgeu	s1,s7,80004f1c <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d3c:	02049593          	slli	a1,s1,0x20
    80004d40:	9181                	srli	a1,a1,0x20
    80004d42:	95e2                	add	a1,a1,s8
    80004d44:	855a                	mv	a0,s6
    80004d46:	ffffc097          	auipc	ra,0xffffc
    80004d4a:	430080e7          	jalr	1072(ra) # 80001176 <walkaddr>
    80004d4e:	862a                	mv	a2,a0
    if(pa == 0)
    80004d50:	dd45                	beqz	a0,80004d08 <exec+0xfe>
      n = PGSIZE;
    80004d52:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d54:	fd49f2e3          	bgeu	s3,s4,80004d18 <exec+0x10e>
      n = sz - i;
    80004d58:	894e                	mv	s2,s3
    80004d5a:	bf7d                	j	80004d18 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d5c:	4481                	li	s1,0
  iunlockput(ip);
    80004d5e:	8556                	mv	a0,s5
    80004d60:	fffff097          	auipc	ra,0xfffff
    80004d64:	bea080e7          	jalr	-1046(ra) # 8000394a <iunlockput>
  end_op();
    80004d68:	fffff097          	auipc	ra,0xfffff
    80004d6c:	3c8080e7          	jalr	968(ra) # 80004130 <end_op>
  p = myproc();
    80004d70:	ffffd097          	auipc	ra,0xffffd
    80004d74:	c9e080e7          	jalr	-866(ra) # 80001a0e <myproc>
    80004d78:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d7a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d7e:	6785                	lui	a5,0x1
    80004d80:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004d82:	97a6                	add	a5,a5,s1
    80004d84:	777d                	lui	a4,0xfffff
    80004d86:	8ff9                	and	a5,a5,a4
    80004d88:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d8c:	6609                	lui	a2,0x2
    80004d8e:	963e                	add	a2,a2,a5
    80004d90:	85be                	mv	a1,a5
    80004d92:	855a                	mv	a0,s6
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	738080e7          	jalr	1848(ra) # 800014cc <uvmalloc>
    80004d9c:	8c2a                	mv	s8,a0
  ip = 0;
    80004d9e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004da0:	12050e63          	beqz	a0,80004edc <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004da4:	75f9                	lui	a1,0xffffe
    80004da6:	95aa                	add	a1,a1,a0
    80004da8:	855a                	mv	a0,s6
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	928080e7          	jalr	-1752(ra) # 800016d2 <uvmclear>
  stackbase = sp - PGSIZE;
    80004db2:	7afd                	lui	s5,0xfffff
    80004db4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004db6:	df043783          	ld	a5,-528(s0)
    80004dba:	6388                	ld	a0,0(a5)
    80004dbc:	c925                	beqz	a0,80004e2c <exec+0x222>
    80004dbe:	e8840993          	addi	s3,s0,-376
    80004dc2:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004dc6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dc8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	0b6080e7          	jalr	182(ra) # 80000e80 <strlen>
    80004dd2:	0015079b          	addiw	a5,a0,1
    80004dd6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dda:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004dde:	13596363          	bltu	s2,s5,80004f04 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004de2:	df043d83          	ld	s11,-528(s0)
    80004de6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004dea:	8552                	mv	a0,s4
    80004dec:	ffffc097          	auipc	ra,0xffffc
    80004df0:	094080e7          	jalr	148(ra) # 80000e80 <strlen>
    80004df4:	0015069b          	addiw	a3,a0,1
    80004df8:	8652                	mv	a2,s4
    80004dfa:	85ca                	mv	a1,s2
    80004dfc:	855a                	mv	a0,s6
    80004dfe:	ffffd097          	auipc	ra,0xffffd
    80004e02:	906080e7          	jalr	-1786(ra) # 80001704 <copyout>
    80004e06:	10054363          	bltz	a0,80004f0c <exec+0x302>
    ustack[argc] = sp;
    80004e0a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e0e:	0485                	addi	s1,s1,1
    80004e10:	008d8793          	addi	a5,s11,8
    80004e14:	def43823          	sd	a5,-528(s0)
    80004e18:	008db503          	ld	a0,8(s11)
    80004e1c:	c911                	beqz	a0,80004e30 <exec+0x226>
    if(argc >= MAXARG)
    80004e1e:	09a1                	addi	s3,s3,8
    80004e20:	fb3c95e3          	bne	s9,s3,80004dca <exec+0x1c0>
  sz = sz1;
    80004e24:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e28:	4a81                	li	s5,0
    80004e2a:	a84d                	j	80004edc <exec+0x2d2>
  sp = sz;
    80004e2c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e2e:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e30:	00349793          	slli	a5,s1,0x3
    80004e34:	f9078793          	addi	a5,a5,-112
    80004e38:	97a2                	add	a5,a5,s0
    80004e3a:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e3e:	00148693          	addi	a3,s1,1
    80004e42:	068e                	slli	a3,a3,0x3
    80004e44:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e48:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e4c:	01597663          	bgeu	s2,s5,80004e58 <exec+0x24e>
  sz = sz1;
    80004e50:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e54:	4a81                	li	s5,0
    80004e56:	a059                	j	80004edc <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e58:	e8840613          	addi	a2,s0,-376
    80004e5c:	85ca                	mv	a1,s2
    80004e5e:	855a                	mv	a0,s6
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	8a4080e7          	jalr	-1884(ra) # 80001704 <copyout>
    80004e68:	0a054663          	bltz	a0,80004f14 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e6c:	058bb783          	ld	a5,88(s7)
    80004e70:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e74:	de843783          	ld	a5,-536(s0)
    80004e78:	0007c703          	lbu	a4,0(a5)
    80004e7c:	cf11                	beqz	a4,80004e98 <exec+0x28e>
    80004e7e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e80:	02f00693          	li	a3,47
    80004e84:	a039                	j	80004e92 <exec+0x288>
      last = s+1;
    80004e86:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e8a:	0785                	addi	a5,a5,1
    80004e8c:	fff7c703          	lbu	a4,-1(a5)
    80004e90:	c701                	beqz	a4,80004e98 <exec+0x28e>
    if(*s == '/')
    80004e92:	fed71ce3          	bne	a4,a3,80004e8a <exec+0x280>
    80004e96:	bfc5                	j	80004e86 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e98:	4641                	li	a2,16
    80004e9a:	de843583          	ld	a1,-536(s0)
    80004e9e:	158b8513          	addi	a0,s7,344
    80004ea2:	ffffc097          	auipc	ra,0xffffc
    80004ea6:	fac080e7          	jalr	-84(ra) # 80000e4e <safestrcpy>
  oldpagetable = p->pagetable;
    80004eaa:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004eae:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004eb2:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004eb6:	058bb783          	ld	a5,88(s7)
    80004eba:	e6043703          	ld	a4,-416(s0)
    80004ebe:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ec0:	058bb783          	ld	a5,88(s7)
    80004ec4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ec8:	85ea                	mv	a1,s10
    80004eca:	ffffd097          	auipc	ra,0xffffd
    80004ece:	ca4080e7          	jalr	-860(ra) # 80001b6e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ed2:	0004851b          	sext.w	a0,s1
    80004ed6:	bbc1                	j	80004ca6 <exec+0x9c>
    80004ed8:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004edc:	df843583          	ld	a1,-520(s0)
    80004ee0:	855a                	mv	a0,s6
    80004ee2:	ffffd097          	auipc	ra,0xffffd
    80004ee6:	c8c080e7          	jalr	-884(ra) # 80001b6e <proc_freepagetable>
  if(ip){
    80004eea:	da0a94e3          	bnez	s5,80004c92 <exec+0x88>
  return -1;
    80004eee:	557d                	li	a0,-1
    80004ef0:	bb5d                	j	80004ca6 <exec+0x9c>
    80004ef2:	de943c23          	sd	s1,-520(s0)
    80004ef6:	b7dd                	j	80004edc <exec+0x2d2>
    80004ef8:	de943c23          	sd	s1,-520(s0)
    80004efc:	b7c5                	j	80004edc <exec+0x2d2>
    80004efe:	de943c23          	sd	s1,-520(s0)
    80004f02:	bfe9                	j	80004edc <exec+0x2d2>
  sz = sz1;
    80004f04:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f08:	4a81                	li	s5,0
    80004f0a:	bfc9                	j	80004edc <exec+0x2d2>
  sz = sz1;
    80004f0c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f10:	4a81                	li	s5,0
    80004f12:	b7e9                	j	80004edc <exec+0x2d2>
  sz = sz1;
    80004f14:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f18:	4a81                	li	s5,0
    80004f1a:	b7c9                	j	80004edc <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f1c:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f20:	e0843783          	ld	a5,-504(s0)
    80004f24:	0017869b          	addiw	a3,a5,1
    80004f28:	e0d43423          	sd	a3,-504(s0)
    80004f2c:	e0043783          	ld	a5,-512(s0)
    80004f30:	0387879b          	addiw	a5,a5,56
    80004f34:	e8045703          	lhu	a4,-384(s0)
    80004f38:	e2e6d3e3          	bge	a3,a4,80004d5e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f3c:	2781                	sext.w	a5,a5
    80004f3e:	e0f43023          	sd	a5,-512(s0)
    80004f42:	03800713          	li	a4,56
    80004f46:	86be                	mv	a3,a5
    80004f48:	e1040613          	addi	a2,s0,-496
    80004f4c:	4581                	li	a1,0
    80004f4e:	8556                	mv	a0,s5
    80004f50:	fffff097          	auipc	ra,0xfffff
    80004f54:	a4c080e7          	jalr	-1460(ra) # 8000399c <readi>
    80004f58:	03800793          	li	a5,56
    80004f5c:	f6f51ee3          	bne	a0,a5,80004ed8 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f60:	e1042783          	lw	a5,-496(s0)
    80004f64:	4705                	li	a4,1
    80004f66:	fae79de3          	bne	a5,a4,80004f20 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f6a:	e3843603          	ld	a2,-456(s0)
    80004f6e:	e3043783          	ld	a5,-464(s0)
    80004f72:	f8f660e3          	bltu	a2,a5,80004ef2 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f76:	e2043783          	ld	a5,-480(s0)
    80004f7a:	963e                	add	a2,a2,a5
    80004f7c:	f6f66ee3          	bltu	a2,a5,80004ef8 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f80:	85a6                	mv	a1,s1
    80004f82:	855a                	mv	a0,s6
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	548080e7          	jalr	1352(ra) # 800014cc <uvmalloc>
    80004f8c:	dea43c23          	sd	a0,-520(s0)
    80004f90:	d53d                	beqz	a0,80004efe <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004f92:	e2043c03          	ld	s8,-480(s0)
    80004f96:	de043783          	ld	a5,-544(s0)
    80004f9a:	00fc77b3          	and	a5,s8,a5
    80004f9e:	ff9d                	bnez	a5,80004edc <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fa0:	e1842c83          	lw	s9,-488(s0)
    80004fa4:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fa8:	f60b8ae3          	beqz	s7,80004f1c <exec+0x312>
    80004fac:	89de                	mv	s3,s7
    80004fae:	4481                	li	s1,0
    80004fb0:	b371                	j	80004d3c <exec+0x132>

0000000080004fb2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fb2:	7179                	addi	sp,sp,-48
    80004fb4:	f406                	sd	ra,40(sp)
    80004fb6:	f022                	sd	s0,32(sp)
    80004fb8:	ec26                	sd	s1,24(sp)
    80004fba:	e84a                	sd	s2,16(sp)
    80004fbc:	1800                	addi	s0,sp,48
    80004fbe:	892e                	mv	s2,a1
    80004fc0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004fc2:	fdc40593          	addi	a1,s0,-36
    80004fc6:	ffffe097          	auipc	ra,0xffffe
    80004fca:	bb0080e7          	jalr	-1104(ra) # 80002b76 <argint>
    80004fce:	04054063          	bltz	a0,8000500e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fd2:	fdc42703          	lw	a4,-36(s0)
    80004fd6:	47bd                	li	a5,15
    80004fd8:	02e7ed63          	bltu	a5,a4,80005012 <argfd+0x60>
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	a32080e7          	jalr	-1486(ra) # 80001a0e <myproc>
    80004fe4:	fdc42703          	lw	a4,-36(s0)
    80004fe8:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80004fec:	078e                	slli	a5,a5,0x3
    80004fee:	953e                	add	a0,a0,a5
    80004ff0:	611c                	ld	a5,0(a0)
    80004ff2:	c395                	beqz	a5,80005016 <argfd+0x64>
    return -1;
  if(pfd)
    80004ff4:	00090463          	beqz	s2,80004ffc <argfd+0x4a>
    *pfd = fd;
    80004ff8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ffc:	4501                	li	a0,0
  if(pf)
    80004ffe:	c091                	beqz	s1,80005002 <argfd+0x50>
    *pf = f;
    80005000:	e09c                	sd	a5,0(s1)
}
    80005002:	70a2                	ld	ra,40(sp)
    80005004:	7402                	ld	s0,32(sp)
    80005006:	64e2                	ld	s1,24(sp)
    80005008:	6942                	ld	s2,16(sp)
    8000500a:	6145                	addi	sp,sp,48
    8000500c:	8082                	ret
    return -1;
    8000500e:	557d                	li	a0,-1
    80005010:	bfcd                	j	80005002 <argfd+0x50>
    return -1;
    80005012:	557d                	li	a0,-1
    80005014:	b7fd                	j	80005002 <argfd+0x50>
    80005016:	557d                	li	a0,-1
    80005018:	b7ed                	j	80005002 <argfd+0x50>

000000008000501a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000501a:	1101                	addi	sp,sp,-32
    8000501c:	ec06                	sd	ra,24(sp)
    8000501e:	e822                	sd	s0,16(sp)
    80005020:	e426                	sd	s1,8(sp)
    80005022:	1000                	addi	s0,sp,32
    80005024:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005026:	ffffd097          	auipc	ra,0xffffd
    8000502a:	9e8080e7          	jalr	-1560(ra) # 80001a0e <myproc>
    8000502e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005030:	0d050793          	addi	a5,a0,208
    80005034:	4501                	li	a0,0
    80005036:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005038:	6398                	ld	a4,0(a5)
    8000503a:	cb19                	beqz	a4,80005050 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000503c:	2505                	addiw	a0,a0,1
    8000503e:	07a1                	addi	a5,a5,8
    80005040:	fed51ce3          	bne	a0,a3,80005038 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005044:	557d                	li	a0,-1
}
    80005046:	60e2                	ld	ra,24(sp)
    80005048:	6442                	ld	s0,16(sp)
    8000504a:	64a2                	ld	s1,8(sp)
    8000504c:	6105                	addi	sp,sp,32
    8000504e:	8082                	ret
      p->ofile[fd] = f;
    80005050:	01a50793          	addi	a5,a0,26
    80005054:	078e                	slli	a5,a5,0x3
    80005056:	963e                	add	a2,a2,a5
    80005058:	e204                	sd	s1,0(a2)
      return fd;
    8000505a:	b7f5                	j	80005046 <fdalloc+0x2c>

000000008000505c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000505c:	715d                	addi	sp,sp,-80
    8000505e:	e486                	sd	ra,72(sp)
    80005060:	e0a2                	sd	s0,64(sp)
    80005062:	fc26                	sd	s1,56(sp)
    80005064:	f84a                	sd	s2,48(sp)
    80005066:	f44e                	sd	s3,40(sp)
    80005068:	f052                	sd	s4,32(sp)
    8000506a:	ec56                	sd	s5,24(sp)
    8000506c:	0880                	addi	s0,sp,80
    8000506e:	89ae                	mv	s3,a1
    80005070:	8ab2                	mv	s5,a2
    80005072:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005074:	fb040593          	addi	a1,s0,-80
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	e48080e7          	jalr	-440(ra) # 80003ec0 <nameiparent>
    80005080:	892a                	mv	s2,a0
    80005082:	12050e63          	beqz	a0,800051be <create+0x162>
    return 0;

  ilock(dp);
    80005086:	ffffe097          	auipc	ra,0xffffe
    8000508a:	662080e7          	jalr	1634(ra) # 800036e8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000508e:	4601                	li	a2,0
    80005090:	fb040593          	addi	a1,s0,-80
    80005094:	854a                	mv	a0,s2
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	b34080e7          	jalr	-1228(ra) # 80003bca <dirlookup>
    8000509e:	84aa                	mv	s1,a0
    800050a0:	c921                	beqz	a0,800050f0 <create+0x94>
    iunlockput(dp);
    800050a2:	854a                	mv	a0,s2
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	8a6080e7          	jalr	-1882(ra) # 8000394a <iunlockput>
    ilock(ip);
    800050ac:	8526                	mv	a0,s1
    800050ae:	ffffe097          	auipc	ra,0xffffe
    800050b2:	63a080e7          	jalr	1594(ra) # 800036e8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050b6:	2981                	sext.w	s3,s3
    800050b8:	4789                	li	a5,2
    800050ba:	02f99463          	bne	s3,a5,800050e2 <create+0x86>
    800050be:	0444d783          	lhu	a5,68(s1)
    800050c2:	37f9                	addiw	a5,a5,-2
    800050c4:	17c2                	slli	a5,a5,0x30
    800050c6:	93c1                	srli	a5,a5,0x30
    800050c8:	4705                	li	a4,1
    800050ca:	00f76c63          	bltu	a4,a5,800050e2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050ce:	8526                	mv	a0,s1
    800050d0:	60a6                	ld	ra,72(sp)
    800050d2:	6406                	ld	s0,64(sp)
    800050d4:	74e2                	ld	s1,56(sp)
    800050d6:	7942                	ld	s2,48(sp)
    800050d8:	79a2                	ld	s3,40(sp)
    800050da:	7a02                	ld	s4,32(sp)
    800050dc:	6ae2                	ld	s5,24(sp)
    800050de:	6161                	addi	sp,sp,80
    800050e0:	8082                	ret
    iunlockput(ip);
    800050e2:	8526                	mv	a0,s1
    800050e4:	fffff097          	auipc	ra,0xfffff
    800050e8:	866080e7          	jalr	-1946(ra) # 8000394a <iunlockput>
    return 0;
    800050ec:	4481                	li	s1,0
    800050ee:	b7c5                	j	800050ce <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050f0:	85ce                	mv	a1,s3
    800050f2:	00092503          	lw	a0,0(s2)
    800050f6:	ffffe097          	auipc	ra,0xffffe
    800050fa:	458080e7          	jalr	1112(ra) # 8000354e <ialloc>
    800050fe:	84aa                	mv	s1,a0
    80005100:	c521                	beqz	a0,80005148 <create+0xec>
  ilock(ip);
    80005102:	ffffe097          	auipc	ra,0xffffe
    80005106:	5e6080e7          	jalr	1510(ra) # 800036e8 <ilock>
  ip->major = major;
    8000510a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000510e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005112:	4a05                	li	s4,1
    80005114:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005118:	8526                	mv	a0,s1
    8000511a:	ffffe097          	auipc	ra,0xffffe
    8000511e:	502080e7          	jalr	1282(ra) # 8000361c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005122:	2981                	sext.w	s3,s3
    80005124:	03498a63          	beq	s3,s4,80005158 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005128:	40d0                	lw	a2,4(s1)
    8000512a:	fb040593          	addi	a1,s0,-80
    8000512e:	854a                	mv	a0,s2
    80005130:	fffff097          	auipc	ra,0xfffff
    80005134:	cb0080e7          	jalr	-848(ra) # 80003de0 <dirlink>
    80005138:	06054b63          	bltz	a0,800051ae <create+0x152>
  iunlockput(dp);
    8000513c:	854a                	mv	a0,s2
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	80c080e7          	jalr	-2036(ra) # 8000394a <iunlockput>
  return ip;
    80005146:	b761                	j	800050ce <create+0x72>
    panic("create: ialloc");
    80005148:	00003517          	auipc	a0,0x3
    8000514c:	52850513          	addi	a0,a0,1320 # 80008670 <syscalls+0x2b0>
    80005150:	ffffb097          	auipc	ra,0xffffb
    80005154:	3f6080e7          	jalr	1014(ra) # 80000546 <panic>
    dp->nlink++;  // for ".."
    80005158:	04a95783          	lhu	a5,74(s2)
    8000515c:	2785                	addiw	a5,a5,1
    8000515e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005162:	854a                	mv	a0,s2
    80005164:	ffffe097          	auipc	ra,0xffffe
    80005168:	4b8080e7          	jalr	1208(ra) # 8000361c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000516c:	40d0                	lw	a2,4(s1)
    8000516e:	00003597          	auipc	a1,0x3
    80005172:	51258593          	addi	a1,a1,1298 # 80008680 <syscalls+0x2c0>
    80005176:	8526                	mv	a0,s1
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	c68080e7          	jalr	-920(ra) # 80003de0 <dirlink>
    80005180:	00054f63          	bltz	a0,8000519e <create+0x142>
    80005184:	00492603          	lw	a2,4(s2)
    80005188:	00003597          	auipc	a1,0x3
    8000518c:	50058593          	addi	a1,a1,1280 # 80008688 <syscalls+0x2c8>
    80005190:	8526                	mv	a0,s1
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	c4e080e7          	jalr	-946(ra) # 80003de0 <dirlink>
    8000519a:	f80557e3          	bgez	a0,80005128 <create+0xcc>
      panic("create dots");
    8000519e:	00003517          	auipc	a0,0x3
    800051a2:	4f250513          	addi	a0,a0,1266 # 80008690 <syscalls+0x2d0>
    800051a6:	ffffb097          	auipc	ra,0xffffb
    800051aa:	3a0080e7          	jalr	928(ra) # 80000546 <panic>
    panic("create: dirlink");
    800051ae:	00003517          	auipc	a0,0x3
    800051b2:	4f250513          	addi	a0,a0,1266 # 800086a0 <syscalls+0x2e0>
    800051b6:	ffffb097          	auipc	ra,0xffffb
    800051ba:	390080e7          	jalr	912(ra) # 80000546 <panic>
    return 0;
    800051be:	84aa                	mv	s1,a0
    800051c0:	b739                	j	800050ce <create+0x72>

00000000800051c2 <sys_dup>:
{
    800051c2:	7179                	addi	sp,sp,-48
    800051c4:	f406                	sd	ra,40(sp)
    800051c6:	f022                	sd	s0,32(sp)
    800051c8:	ec26                	sd	s1,24(sp)
    800051ca:	e84a                	sd	s2,16(sp)
    800051cc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051ce:	fd840613          	addi	a2,s0,-40
    800051d2:	4581                	li	a1,0
    800051d4:	4501                	li	a0,0
    800051d6:	00000097          	auipc	ra,0x0
    800051da:	ddc080e7          	jalr	-548(ra) # 80004fb2 <argfd>
    return -1;
    800051de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051e0:	02054363          	bltz	a0,80005206 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800051e4:	fd843903          	ld	s2,-40(s0)
    800051e8:	854a                	mv	a0,s2
    800051ea:	00000097          	auipc	ra,0x0
    800051ee:	e30080e7          	jalr	-464(ra) # 8000501a <fdalloc>
    800051f2:	84aa                	mv	s1,a0
    return -1;
    800051f4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051f6:	00054863          	bltz	a0,80005206 <sys_dup+0x44>
  filedup(f);
    800051fa:	854a                	mv	a0,s2
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	332080e7          	jalr	818(ra) # 8000452e <filedup>
  return fd;
    80005204:	87a6                	mv	a5,s1
}
    80005206:	853e                	mv	a0,a5
    80005208:	70a2                	ld	ra,40(sp)
    8000520a:	7402                	ld	s0,32(sp)
    8000520c:	64e2                	ld	s1,24(sp)
    8000520e:	6942                	ld	s2,16(sp)
    80005210:	6145                	addi	sp,sp,48
    80005212:	8082                	ret

0000000080005214 <sys_read>:
{
    80005214:	7179                	addi	sp,sp,-48
    80005216:	f406                	sd	ra,40(sp)
    80005218:	f022                	sd	s0,32(sp)
    8000521a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000521c:	fe840613          	addi	a2,s0,-24
    80005220:	4581                	li	a1,0
    80005222:	4501                	li	a0,0
    80005224:	00000097          	auipc	ra,0x0
    80005228:	d8e080e7          	jalr	-626(ra) # 80004fb2 <argfd>
    return -1;
    8000522c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000522e:	04054163          	bltz	a0,80005270 <sys_read+0x5c>
    80005232:	fe440593          	addi	a1,s0,-28
    80005236:	4509                	li	a0,2
    80005238:	ffffe097          	auipc	ra,0xffffe
    8000523c:	93e080e7          	jalr	-1730(ra) # 80002b76 <argint>
    return -1;
    80005240:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005242:	02054763          	bltz	a0,80005270 <sys_read+0x5c>
    80005246:	fd840593          	addi	a1,s0,-40
    8000524a:	4505                	li	a0,1
    8000524c:	ffffe097          	auipc	ra,0xffffe
    80005250:	94c080e7          	jalr	-1716(ra) # 80002b98 <argaddr>
    return -1;
    80005254:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005256:	00054d63          	bltz	a0,80005270 <sys_read+0x5c>
  return fileread(f, p, n);
    8000525a:	fe442603          	lw	a2,-28(s0)
    8000525e:	fd843583          	ld	a1,-40(s0)
    80005262:	fe843503          	ld	a0,-24(s0)
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	454080e7          	jalr	1108(ra) # 800046ba <fileread>
    8000526e:	87aa                	mv	a5,a0
}
    80005270:	853e                	mv	a0,a5
    80005272:	70a2                	ld	ra,40(sp)
    80005274:	7402                	ld	s0,32(sp)
    80005276:	6145                	addi	sp,sp,48
    80005278:	8082                	ret

000000008000527a <sys_write>:
{
    8000527a:	7179                	addi	sp,sp,-48
    8000527c:	f406                	sd	ra,40(sp)
    8000527e:	f022                	sd	s0,32(sp)
    80005280:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005282:	fe840613          	addi	a2,s0,-24
    80005286:	4581                	li	a1,0
    80005288:	4501                	li	a0,0
    8000528a:	00000097          	auipc	ra,0x0
    8000528e:	d28080e7          	jalr	-728(ra) # 80004fb2 <argfd>
    return -1;
    80005292:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005294:	04054163          	bltz	a0,800052d6 <sys_write+0x5c>
    80005298:	fe440593          	addi	a1,s0,-28
    8000529c:	4509                	li	a0,2
    8000529e:	ffffe097          	auipc	ra,0xffffe
    800052a2:	8d8080e7          	jalr	-1832(ra) # 80002b76 <argint>
    return -1;
    800052a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a8:	02054763          	bltz	a0,800052d6 <sys_write+0x5c>
    800052ac:	fd840593          	addi	a1,s0,-40
    800052b0:	4505                	li	a0,1
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	8e6080e7          	jalr	-1818(ra) # 80002b98 <argaddr>
    return -1;
    800052ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052bc:	00054d63          	bltz	a0,800052d6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052c0:	fe442603          	lw	a2,-28(s0)
    800052c4:	fd843583          	ld	a1,-40(s0)
    800052c8:	fe843503          	ld	a0,-24(s0)
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	4b0080e7          	jalr	1200(ra) # 8000477c <filewrite>
    800052d4:	87aa                	mv	a5,a0
}
    800052d6:	853e                	mv	a0,a5
    800052d8:	70a2                	ld	ra,40(sp)
    800052da:	7402                	ld	s0,32(sp)
    800052dc:	6145                	addi	sp,sp,48
    800052de:	8082                	ret

00000000800052e0 <sys_close>:
{
    800052e0:	1101                	addi	sp,sp,-32
    800052e2:	ec06                	sd	ra,24(sp)
    800052e4:	e822                	sd	s0,16(sp)
    800052e6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052e8:	fe040613          	addi	a2,s0,-32
    800052ec:	fec40593          	addi	a1,s0,-20
    800052f0:	4501                	li	a0,0
    800052f2:	00000097          	auipc	ra,0x0
    800052f6:	cc0080e7          	jalr	-832(ra) # 80004fb2 <argfd>
    return -1;
    800052fa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052fc:	02054463          	bltz	a0,80005324 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005300:	ffffc097          	auipc	ra,0xffffc
    80005304:	70e080e7          	jalr	1806(ra) # 80001a0e <myproc>
    80005308:	fec42783          	lw	a5,-20(s0)
    8000530c:	07e9                	addi	a5,a5,26
    8000530e:	078e                	slli	a5,a5,0x3
    80005310:	953e                	add	a0,a0,a5
    80005312:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005316:	fe043503          	ld	a0,-32(s0)
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	266080e7          	jalr	614(ra) # 80004580 <fileclose>
  return 0;
    80005322:	4781                	li	a5,0
}
    80005324:	853e                	mv	a0,a5
    80005326:	60e2                	ld	ra,24(sp)
    80005328:	6442                	ld	s0,16(sp)
    8000532a:	6105                	addi	sp,sp,32
    8000532c:	8082                	ret

000000008000532e <sys_fstat>:
{
    8000532e:	1101                	addi	sp,sp,-32
    80005330:	ec06                	sd	ra,24(sp)
    80005332:	e822                	sd	s0,16(sp)
    80005334:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005336:	fe840613          	addi	a2,s0,-24
    8000533a:	4581                	li	a1,0
    8000533c:	4501                	li	a0,0
    8000533e:	00000097          	auipc	ra,0x0
    80005342:	c74080e7          	jalr	-908(ra) # 80004fb2 <argfd>
    return -1;
    80005346:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005348:	02054563          	bltz	a0,80005372 <sys_fstat+0x44>
    8000534c:	fe040593          	addi	a1,s0,-32
    80005350:	4505                	li	a0,1
    80005352:	ffffe097          	auipc	ra,0xffffe
    80005356:	846080e7          	jalr	-1978(ra) # 80002b98 <argaddr>
    return -1;
    8000535a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000535c:	00054b63          	bltz	a0,80005372 <sys_fstat+0x44>
  return filestat(f, st);
    80005360:	fe043583          	ld	a1,-32(s0)
    80005364:	fe843503          	ld	a0,-24(s0)
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	2e0080e7          	jalr	736(ra) # 80004648 <filestat>
    80005370:	87aa                	mv	a5,a0
}
    80005372:	853e                	mv	a0,a5
    80005374:	60e2                	ld	ra,24(sp)
    80005376:	6442                	ld	s0,16(sp)
    80005378:	6105                	addi	sp,sp,32
    8000537a:	8082                	ret

000000008000537c <sys_link>:
{
    8000537c:	7169                	addi	sp,sp,-304
    8000537e:	f606                	sd	ra,296(sp)
    80005380:	f222                	sd	s0,288(sp)
    80005382:	ee26                	sd	s1,280(sp)
    80005384:	ea4a                	sd	s2,272(sp)
    80005386:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005388:	08000613          	li	a2,128
    8000538c:	ed040593          	addi	a1,s0,-304
    80005390:	4501                	li	a0,0
    80005392:	ffffe097          	auipc	ra,0xffffe
    80005396:	828080e7          	jalr	-2008(ra) # 80002bba <argstr>
    return -1;
    8000539a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000539c:	10054e63          	bltz	a0,800054b8 <sys_link+0x13c>
    800053a0:	08000613          	li	a2,128
    800053a4:	f5040593          	addi	a1,s0,-176
    800053a8:	4505                	li	a0,1
    800053aa:	ffffe097          	auipc	ra,0xffffe
    800053ae:	810080e7          	jalr	-2032(ra) # 80002bba <argstr>
    return -1;
    800053b2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053b4:	10054263          	bltz	a0,800054b8 <sys_link+0x13c>
  begin_op();
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	cfa080e7          	jalr	-774(ra) # 800040b2 <begin_op>
  if((ip = namei(old)) == 0){
    800053c0:	ed040513          	addi	a0,s0,-304
    800053c4:	fffff097          	auipc	ra,0xfffff
    800053c8:	ade080e7          	jalr	-1314(ra) # 80003ea2 <namei>
    800053cc:	84aa                	mv	s1,a0
    800053ce:	c551                	beqz	a0,8000545a <sys_link+0xde>
  ilock(ip);
    800053d0:	ffffe097          	auipc	ra,0xffffe
    800053d4:	318080e7          	jalr	792(ra) # 800036e8 <ilock>
  if(ip->type == T_DIR){
    800053d8:	04449703          	lh	a4,68(s1)
    800053dc:	4785                	li	a5,1
    800053de:	08f70463          	beq	a4,a5,80005466 <sys_link+0xea>
  ip->nlink++;
    800053e2:	04a4d783          	lhu	a5,74(s1)
    800053e6:	2785                	addiw	a5,a5,1
    800053e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053ec:	8526                	mv	a0,s1
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	22e080e7          	jalr	558(ra) # 8000361c <iupdate>
  iunlock(ip);
    800053f6:	8526                	mv	a0,s1
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	3b2080e7          	jalr	946(ra) # 800037aa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005400:	fd040593          	addi	a1,s0,-48
    80005404:	f5040513          	addi	a0,s0,-176
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	ab8080e7          	jalr	-1352(ra) # 80003ec0 <nameiparent>
    80005410:	892a                	mv	s2,a0
    80005412:	c935                	beqz	a0,80005486 <sys_link+0x10a>
  ilock(dp);
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	2d4080e7          	jalr	724(ra) # 800036e8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000541c:	00092703          	lw	a4,0(s2)
    80005420:	409c                	lw	a5,0(s1)
    80005422:	04f71d63          	bne	a4,a5,8000547c <sys_link+0x100>
    80005426:	40d0                	lw	a2,4(s1)
    80005428:	fd040593          	addi	a1,s0,-48
    8000542c:	854a                	mv	a0,s2
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	9b2080e7          	jalr	-1614(ra) # 80003de0 <dirlink>
    80005436:	04054363          	bltz	a0,8000547c <sys_link+0x100>
  iunlockput(dp);
    8000543a:	854a                	mv	a0,s2
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	50e080e7          	jalr	1294(ra) # 8000394a <iunlockput>
  iput(ip);
    80005444:	8526                	mv	a0,s1
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	45c080e7          	jalr	1116(ra) # 800038a2 <iput>
  end_op();
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	ce2080e7          	jalr	-798(ra) # 80004130 <end_op>
  return 0;
    80005456:	4781                	li	a5,0
    80005458:	a085                	j	800054b8 <sys_link+0x13c>
    end_op();
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	cd6080e7          	jalr	-810(ra) # 80004130 <end_op>
    return -1;
    80005462:	57fd                	li	a5,-1
    80005464:	a891                	j	800054b8 <sys_link+0x13c>
    iunlockput(ip);
    80005466:	8526                	mv	a0,s1
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	4e2080e7          	jalr	1250(ra) # 8000394a <iunlockput>
    end_op();
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	cc0080e7          	jalr	-832(ra) # 80004130 <end_op>
    return -1;
    80005478:	57fd                	li	a5,-1
    8000547a:	a83d                	j	800054b8 <sys_link+0x13c>
    iunlockput(dp);
    8000547c:	854a                	mv	a0,s2
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	4cc080e7          	jalr	1228(ra) # 8000394a <iunlockput>
  ilock(ip);
    80005486:	8526                	mv	a0,s1
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	260080e7          	jalr	608(ra) # 800036e8 <ilock>
  ip->nlink--;
    80005490:	04a4d783          	lhu	a5,74(s1)
    80005494:	37fd                	addiw	a5,a5,-1
    80005496:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000549a:	8526                	mv	a0,s1
    8000549c:	ffffe097          	auipc	ra,0xffffe
    800054a0:	180080e7          	jalr	384(ra) # 8000361c <iupdate>
  iunlockput(ip);
    800054a4:	8526                	mv	a0,s1
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	4a4080e7          	jalr	1188(ra) # 8000394a <iunlockput>
  end_op();
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	c82080e7          	jalr	-894(ra) # 80004130 <end_op>
  return -1;
    800054b6:	57fd                	li	a5,-1
}
    800054b8:	853e                	mv	a0,a5
    800054ba:	70b2                	ld	ra,296(sp)
    800054bc:	7412                	ld	s0,288(sp)
    800054be:	64f2                	ld	s1,280(sp)
    800054c0:	6952                	ld	s2,272(sp)
    800054c2:	6155                	addi	sp,sp,304
    800054c4:	8082                	ret

00000000800054c6 <sys_unlink>:
{
    800054c6:	7151                	addi	sp,sp,-240
    800054c8:	f586                	sd	ra,232(sp)
    800054ca:	f1a2                	sd	s0,224(sp)
    800054cc:	eda6                	sd	s1,216(sp)
    800054ce:	e9ca                	sd	s2,208(sp)
    800054d0:	e5ce                	sd	s3,200(sp)
    800054d2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054d4:	08000613          	li	a2,128
    800054d8:	f3040593          	addi	a1,s0,-208
    800054dc:	4501                	li	a0,0
    800054de:	ffffd097          	auipc	ra,0xffffd
    800054e2:	6dc080e7          	jalr	1756(ra) # 80002bba <argstr>
    800054e6:	18054163          	bltz	a0,80005668 <sys_unlink+0x1a2>
  begin_op();
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	bc8080e7          	jalr	-1080(ra) # 800040b2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054f2:	fb040593          	addi	a1,s0,-80
    800054f6:	f3040513          	addi	a0,s0,-208
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	9c6080e7          	jalr	-1594(ra) # 80003ec0 <nameiparent>
    80005502:	84aa                	mv	s1,a0
    80005504:	c979                	beqz	a0,800055da <sys_unlink+0x114>
  ilock(dp);
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	1e2080e7          	jalr	482(ra) # 800036e8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000550e:	00003597          	auipc	a1,0x3
    80005512:	17258593          	addi	a1,a1,370 # 80008680 <syscalls+0x2c0>
    80005516:	fb040513          	addi	a0,s0,-80
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	696080e7          	jalr	1686(ra) # 80003bb0 <namecmp>
    80005522:	14050a63          	beqz	a0,80005676 <sys_unlink+0x1b0>
    80005526:	00003597          	auipc	a1,0x3
    8000552a:	16258593          	addi	a1,a1,354 # 80008688 <syscalls+0x2c8>
    8000552e:	fb040513          	addi	a0,s0,-80
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	67e080e7          	jalr	1662(ra) # 80003bb0 <namecmp>
    8000553a:	12050e63          	beqz	a0,80005676 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000553e:	f2c40613          	addi	a2,s0,-212
    80005542:	fb040593          	addi	a1,s0,-80
    80005546:	8526                	mv	a0,s1
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	682080e7          	jalr	1666(ra) # 80003bca <dirlookup>
    80005550:	892a                	mv	s2,a0
    80005552:	12050263          	beqz	a0,80005676 <sys_unlink+0x1b0>
  ilock(ip);
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	192080e7          	jalr	402(ra) # 800036e8 <ilock>
  if(ip->nlink < 1)
    8000555e:	04a91783          	lh	a5,74(s2)
    80005562:	08f05263          	blez	a5,800055e6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005566:	04491703          	lh	a4,68(s2)
    8000556a:	4785                	li	a5,1
    8000556c:	08f70563          	beq	a4,a5,800055f6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005570:	4641                	li	a2,16
    80005572:	4581                	li	a1,0
    80005574:	fc040513          	addi	a0,s0,-64
    80005578:	ffffb097          	auipc	ra,0xffffb
    8000557c:	784080e7          	jalr	1924(ra) # 80000cfc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005580:	4741                	li	a4,16
    80005582:	f2c42683          	lw	a3,-212(s0)
    80005586:	fc040613          	addi	a2,s0,-64
    8000558a:	4581                	li	a1,0
    8000558c:	8526                	mv	a0,s1
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	506080e7          	jalr	1286(ra) # 80003a94 <writei>
    80005596:	47c1                	li	a5,16
    80005598:	0af51563          	bne	a0,a5,80005642 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000559c:	04491703          	lh	a4,68(s2)
    800055a0:	4785                	li	a5,1
    800055a2:	0af70863          	beq	a4,a5,80005652 <sys_unlink+0x18c>
  iunlockput(dp);
    800055a6:	8526                	mv	a0,s1
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	3a2080e7          	jalr	930(ra) # 8000394a <iunlockput>
  ip->nlink--;
    800055b0:	04a95783          	lhu	a5,74(s2)
    800055b4:	37fd                	addiw	a5,a5,-1
    800055b6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055ba:	854a                	mv	a0,s2
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	060080e7          	jalr	96(ra) # 8000361c <iupdate>
  iunlockput(ip);
    800055c4:	854a                	mv	a0,s2
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	384080e7          	jalr	900(ra) # 8000394a <iunlockput>
  end_op();
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	b62080e7          	jalr	-1182(ra) # 80004130 <end_op>
  return 0;
    800055d6:	4501                	li	a0,0
    800055d8:	a84d                	j	8000568a <sys_unlink+0x1c4>
    end_op();
    800055da:	fffff097          	auipc	ra,0xfffff
    800055de:	b56080e7          	jalr	-1194(ra) # 80004130 <end_op>
    return -1;
    800055e2:	557d                	li	a0,-1
    800055e4:	a05d                	j	8000568a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055e6:	00003517          	auipc	a0,0x3
    800055ea:	0ca50513          	addi	a0,a0,202 # 800086b0 <syscalls+0x2f0>
    800055ee:	ffffb097          	auipc	ra,0xffffb
    800055f2:	f58080e7          	jalr	-168(ra) # 80000546 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055f6:	04c92703          	lw	a4,76(s2)
    800055fa:	02000793          	li	a5,32
    800055fe:	f6e7f9e3          	bgeu	a5,a4,80005570 <sys_unlink+0xaa>
    80005602:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005606:	4741                	li	a4,16
    80005608:	86ce                	mv	a3,s3
    8000560a:	f1840613          	addi	a2,s0,-232
    8000560e:	4581                	li	a1,0
    80005610:	854a                	mv	a0,s2
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	38a080e7          	jalr	906(ra) # 8000399c <readi>
    8000561a:	47c1                	li	a5,16
    8000561c:	00f51b63          	bne	a0,a5,80005632 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005620:	f1845783          	lhu	a5,-232(s0)
    80005624:	e7a1                	bnez	a5,8000566c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005626:	29c1                	addiw	s3,s3,16
    80005628:	04c92783          	lw	a5,76(s2)
    8000562c:	fcf9ede3          	bltu	s3,a5,80005606 <sys_unlink+0x140>
    80005630:	b781                	j	80005570 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005632:	00003517          	auipc	a0,0x3
    80005636:	09650513          	addi	a0,a0,150 # 800086c8 <syscalls+0x308>
    8000563a:	ffffb097          	auipc	ra,0xffffb
    8000563e:	f0c080e7          	jalr	-244(ra) # 80000546 <panic>
    panic("unlink: writei");
    80005642:	00003517          	auipc	a0,0x3
    80005646:	09e50513          	addi	a0,a0,158 # 800086e0 <syscalls+0x320>
    8000564a:	ffffb097          	auipc	ra,0xffffb
    8000564e:	efc080e7          	jalr	-260(ra) # 80000546 <panic>
    dp->nlink--;
    80005652:	04a4d783          	lhu	a5,74(s1)
    80005656:	37fd                	addiw	a5,a5,-1
    80005658:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000565c:	8526                	mv	a0,s1
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	fbe080e7          	jalr	-66(ra) # 8000361c <iupdate>
    80005666:	b781                	j	800055a6 <sys_unlink+0xe0>
    return -1;
    80005668:	557d                	li	a0,-1
    8000566a:	a005                	j	8000568a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000566c:	854a                	mv	a0,s2
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	2dc080e7          	jalr	732(ra) # 8000394a <iunlockput>
  iunlockput(dp);
    80005676:	8526                	mv	a0,s1
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	2d2080e7          	jalr	722(ra) # 8000394a <iunlockput>
  end_op();
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	ab0080e7          	jalr	-1360(ra) # 80004130 <end_op>
  return -1;
    80005688:	557d                	li	a0,-1
}
    8000568a:	70ae                	ld	ra,232(sp)
    8000568c:	740e                	ld	s0,224(sp)
    8000568e:	64ee                	ld	s1,216(sp)
    80005690:	694e                	ld	s2,208(sp)
    80005692:	69ae                	ld	s3,200(sp)
    80005694:	616d                	addi	sp,sp,240
    80005696:	8082                	ret

0000000080005698 <sys_open>:

uint64
sys_open(void)
{
    80005698:	7131                	addi	sp,sp,-192
    8000569a:	fd06                	sd	ra,184(sp)
    8000569c:	f922                	sd	s0,176(sp)
    8000569e:	f526                	sd	s1,168(sp)
    800056a0:	f14a                	sd	s2,160(sp)
    800056a2:	ed4e                	sd	s3,152(sp)
    800056a4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056a6:	08000613          	li	a2,128
    800056aa:	f5040593          	addi	a1,s0,-176
    800056ae:	4501                	li	a0,0
    800056b0:	ffffd097          	auipc	ra,0xffffd
    800056b4:	50a080e7          	jalr	1290(ra) # 80002bba <argstr>
    return -1;
    800056b8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056ba:	0c054163          	bltz	a0,8000577c <sys_open+0xe4>
    800056be:	f4c40593          	addi	a1,s0,-180
    800056c2:	4505                	li	a0,1
    800056c4:	ffffd097          	auipc	ra,0xffffd
    800056c8:	4b2080e7          	jalr	1202(ra) # 80002b76 <argint>
    800056cc:	0a054863          	bltz	a0,8000577c <sys_open+0xe4>

  begin_op();
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	9e2080e7          	jalr	-1566(ra) # 800040b2 <begin_op>

  if(omode & O_CREATE){
    800056d8:	f4c42783          	lw	a5,-180(s0)
    800056dc:	2007f793          	andi	a5,a5,512
    800056e0:	cbdd                	beqz	a5,80005796 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056e2:	4681                	li	a3,0
    800056e4:	4601                	li	a2,0
    800056e6:	4589                	li	a1,2
    800056e8:	f5040513          	addi	a0,s0,-176
    800056ec:	00000097          	auipc	ra,0x0
    800056f0:	970080e7          	jalr	-1680(ra) # 8000505c <create>
    800056f4:	892a                	mv	s2,a0
    if(ip == 0){
    800056f6:	c959                	beqz	a0,8000578c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056f8:	04491703          	lh	a4,68(s2)
    800056fc:	478d                	li	a5,3
    800056fe:	00f71763          	bne	a4,a5,8000570c <sys_open+0x74>
    80005702:	04695703          	lhu	a4,70(s2)
    80005706:	47a5                	li	a5,9
    80005708:	0ce7ec63          	bltu	a5,a4,800057e0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	db8080e7          	jalr	-584(ra) # 800044c4 <filealloc>
    80005714:	89aa                	mv	s3,a0
    80005716:	10050263          	beqz	a0,8000581a <sys_open+0x182>
    8000571a:	00000097          	auipc	ra,0x0
    8000571e:	900080e7          	jalr	-1792(ra) # 8000501a <fdalloc>
    80005722:	84aa                	mv	s1,a0
    80005724:	0e054663          	bltz	a0,80005810 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005728:	04491703          	lh	a4,68(s2)
    8000572c:	478d                	li	a5,3
    8000572e:	0cf70463          	beq	a4,a5,800057f6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005732:	4789                	li	a5,2
    80005734:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005738:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000573c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005740:	f4c42783          	lw	a5,-180(s0)
    80005744:	0017c713          	xori	a4,a5,1
    80005748:	8b05                	andi	a4,a4,1
    8000574a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000574e:	0037f713          	andi	a4,a5,3
    80005752:	00e03733          	snez	a4,a4
    80005756:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000575a:	4007f793          	andi	a5,a5,1024
    8000575e:	c791                	beqz	a5,8000576a <sys_open+0xd2>
    80005760:	04491703          	lh	a4,68(s2)
    80005764:	4789                	li	a5,2
    80005766:	08f70f63          	beq	a4,a5,80005804 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000576a:	854a                	mv	a0,s2
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	03e080e7          	jalr	62(ra) # 800037aa <iunlock>
  end_op();
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	9bc080e7          	jalr	-1604(ra) # 80004130 <end_op>

  return fd;
}
    8000577c:	8526                	mv	a0,s1
    8000577e:	70ea                	ld	ra,184(sp)
    80005780:	744a                	ld	s0,176(sp)
    80005782:	74aa                	ld	s1,168(sp)
    80005784:	790a                	ld	s2,160(sp)
    80005786:	69ea                	ld	s3,152(sp)
    80005788:	6129                	addi	sp,sp,192
    8000578a:	8082                	ret
      end_op();
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	9a4080e7          	jalr	-1628(ra) # 80004130 <end_op>
      return -1;
    80005794:	b7e5                	j	8000577c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005796:	f5040513          	addi	a0,s0,-176
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	708080e7          	jalr	1800(ra) # 80003ea2 <namei>
    800057a2:	892a                	mv	s2,a0
    800057a4:	c905                	beqz	a0,800057d4 <sys_open+0x13c>
    ilock(ip);
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	f42080e7          	jalr	-190(ra) # 800036e8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057ae:	04491703          	lh	a4,68(s2)
    800057b2:	4785                	li	a5,1
    800057b4:	f4f712e3          	bne	a4,a5,800056f8 <sys_open+0x60>
    800057b8:	f4c42783          	lw	a5,-180(s0)
    800057bc:	dba1                	beqz	a5,8000570c <sys_open+0x74>
      iunlockput(ip);
    800057be:	854a                	mv	a0,s2
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	18a080e7          	jalr	394(ra) # 8000394a <iunlockput>
      end_op();
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	968080e7          	jalr	-1688(ra) # 80004130 <end_op>
      return -1;
    800057d0:	54fd                	li	s1,-1
    800057d2:	b76d                	j	8000577c <sys_open+0xe4>
      end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	95c080e7          	jalr	-1700(ra) # 80004130 <end_op>
      return -1;
    800057dc:	54fd                	li	s1,-1
    800057de:	bf79                	j	8000577c <sys_open+0xe4>
    iunlockput(ip);
    800057e0:	854a                	mv	a0,s2
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	168080e7          	jalr	360(ra) # 8000394a <iunlockput>
    end_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	946080e7          	jalr	-1722(ra) # 80004130 <end_op>
    return -1;
    800057f2:	54fd                	li	s1,-1
    800057f4:	b761                	j	8000577c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057f6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057fa:	04691783          	lh	a5,70(s2)
    800057fe:	02f99223          	sh	a5,36(s3)
    80005802:	bf2d                	j	8000573c <sys_open+0xa4>
    itrunc(ip);
    80005804:	854a                	mv	a0,s2
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	ff0080e7          	jalr	-16(ra) # 800037f6 <itrunc>
    8000580e:	bfb1                	j	8000576a <sys_open+0xd2>
      fileclose(f);
    80005810:	854e                	mv	a0,s3
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	d6e080e7          	jalr	-658(ra) # 80004580 <fileclose>
    iunlockput(ip);
    8000581a:	854a                	mv	a0,s2
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	12e080e7          	jalr	302(ra) # 8000394a <iunlockput>
    end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	90c080e7          	jalr	-1780(ra) # 80004130 <end_op>
    return -1;
    8000582c:	54fd                	li	s1,-1
    8000582e:	b7b9                	j	8000577c <sys_open+0xe4>

0000000080005830 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005830:	7175                	addi	sp,sp,-144
    80005832:	e506                	sd	ra,136(sp)
    80005834:	e122                	sd	s0,128(sp)
    80005836:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	87a080e7          	jalr	-1926(ra) # 800040b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005840:	08000613          	li	a2,128
    80005844:	f7040593          	addi	a1,s0,-144
    80005848:	4501                	li	a0,0
    8000584a:	ffffd097          	auipc	ra,0xffffd
    8000584e:	370080e7          	jalr	880(ra) # 80002bba <argstr>
    80005852:	02054963          	bltz	a0,80005884 <sys_mkdir+0x54>
    80005856:	4681                	li	a3,0
    80005858:	4601                	li	a2,0
    8000585a:	4585                	li	a1,1
    8000585c:	f7040513          	addi	a0,s0,-144
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	7fc080e7          	jalr	2044(ra) # 8000505c <create>
    80005868:	cd11                	beqz	a0,80005884 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	0e0080e7          	jalr	224(ra) # 8000394a <iunlockput>
  end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	8be080e7          	jalr	-1858(ra) # 80004130 <end_op>
  return 0;
    8000587a:	4501                	li	a0,0
}
    8000587c:	60aa                	ld	ra,136(sp)
    8000587e:	640a                	ld	s0,128(sp)
    80005880:	6149                	addi	sp,sp,144
    80005882:	8082                	ret
    end_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	8ac080e7          	jalr	-1876(ra) # 80004130 <end_op>
    return -1;
    8000588c:	557d                	li	a0,-1
    8000588e:	b7fd                	j	8000587c <sys_mkdir+0x4c>

0000000080005890 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005890:	7135                	addi	sp,sp,-160
    80005892:	ed06                	sd	ra,152(sp)
    80005894:	e922                	sd	s0,144(sp)
    80005896:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	81a080e7          	jalr	-2022(ra) # 800040b2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058a0:	08000613          	li	a2,128
    800058a4:	f7040593          	addi	a1,s0,-144
    800058a8:	4501                	li	a0,0
    800058aa:	ffffd097          	auipc	ra,0xffffd
    800058ae:	310080e7          	jalr	784(ra) # 80002bba <argstr>
    800058b2:	04054a63          	bltz	a0,80005906 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058b6:	f6c40593          	addi	a1,s0,-148
    800058ba:	4505                	li	a0,1
    800058bc:	ffffd097          	auipc	ra,0xffffd
    800058c0:	2ba080e7          	jalr	698(ra) # 80002b76 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058c4:	04054163          	bltz	a0,80005906 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058c8:	f6840593          	addi	a1,s0,-152
    800058cc:	4509                	li	a0,2
    800058ce:	ffffd097          	auipc	ra,0xffffd
    800058d2:	2a8080e7          	jalr	680(ra) # 80002b76 <argint>
     argint(1, &major) < 0 ||
    800058d6:	02054863          	bltz	a0,80005906 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058da:	f6841683          	lh	a3,-152(s0)
    800058de:	f6c41603          	lh	a2,-148(s0)
    800058e2:	458d                	li	a1,3
    800058e4:	f7040513          	addi	a0,s0,-144
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	774080e7          	jalr	1908(ra) # 8000505c <create>
     argint(2, &minor) < 0 ||
    800058f0:	c919                	beqz	a0,80005906 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	058080e7          	jalr	88(ra) # 8000394a <iunlockput>
  end_op();
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	836080e7          	jalr	-1994(ra) # 80004130 <end_op>
  return 0;
    80005902:	4501                	li	a0,0
    80005904:	a031                	j	80005910 <sys_mknod+0x80>
    end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	82a080e7          	jalr	-2006(ra) # 80004130 <end_op>
    return -1;
    8000590e:	557d                	li	a0,-1
}
    80005910:	60ea                	ld	ra,152(sp)
    80005912:	644a                	ld	s0,144(sp)
    80005914:	610d                	addi	sp,sp,160
    80005916:	8082                	ret

0000000080005918 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005918:	7135                	addi	sp,sp,-160
    8000591a:	ed06                	sd	ra,152(sp)
    8000591c:	e922                	sd	s0,144(sp)
    8000591e:	e526                	sd	s1,136(sp)
    80005920:	e14a                	sd	s2,128(sp)
    80005922:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005924:	ffffc097          	auipc	ra,0xffffc
    80005928:	0ea080e7          	jalr	234(ra) # 80001a0e <myproc>
    8000592c:	892a                	mv	s2,a0
  
  begin_op();
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	784080e7          	jalr	1924(ra) # 800040b2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005936:	08000613          	li	a2,128
    8000593a:	f6040593          	addi	a1,s0,-160
    8000593e:	4501                	li	a0,0
    80005940:	ffffd097          	auipc	ra,0xffffd
    80005944:	27a080e7          	jalr	634(ra) # 80002bba <argstr>
    80005948:	04054b63          	bltz	a0,8000599e <sys_chdir+0x86>
    8000594c:	f6040513          	addi	a0,s0,-160
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	552080e7          	jalr	1362(ra) # 80003ea2 <namei>
    80005958:	84aa                	mv	s1,a0
    8000595a:	c131                	beqz	a0,8000599e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	d8c080e7          	jalr	-628(ra) # 800036e8 <ilock>
  if(ip->type != T_DIR){
    80005964:	04449703          	lh	a4,68(s1)
    80005968:	4785                	li	a5,1
    8000596a:	04f71063          	bne	a4,a5,800059aa <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000596e:	8526                	mv	a0,s1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	e3a080e7          	jalr	-454(ra) # 800037aa <iunlock>
  iput(p->cwd);
    80005978:	15093503          	ld	a0,336(s2)
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	f26080e7          	jalr	-218(ra) # 800038a2 <iput>
  end_op();
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	7ac080e7          	jalr	1964(ra) # 80004130 <end_op>
  p->cwd = ip;
    8000598c:	14993823          	sd	s1,336(s2)
  return 0;
    80005990:	4501                	li	a0,0
}
    80005992:	60ea                	ld	ra,152(sp)
    80005994:	644a                	ld	s0,144(sp)
    80005996:	64aa                	ld	s1,136(sp)
    80005998:	690a                	ld	s2,128(sp)
    8000599a:	610d                	addi	sp,sp,160
    8000599c:	8082                	ret
    end_op();
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	792080e7          	jalr	1938(ra) # 80004130 <end_op>
    return -1;
    800059a6:	557d                	li	a0,-1
    800059a8:	b7ed                	j	80005992 <sys_chdir+0x7a>
    iunlockput(ip);
    800059aa:	8526                	mv	a0,s1
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	f9e080e7          	jalr	-98(ra) # 8000394a <iunlockput>
    end_op();
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	77c080e7          	jalr	1916(ra) # 80004130 <end_op>
    return -1;
    800059bc:	557d                	li	a0,-1
    800059be:	bfd1                	j	80005992 <sys_chdir+0x7a>

00000000800059c0 <sys_exec>:

uint64
sys_exec(void)
{
    800059c0:	7145                	addi	sp,sp,-464
    800059c2:	e786                	sd	ra,456(sp)
    800059c4:	e3a2                	sd	s0,448(sp)
    800059c6:	ff26                	sd	s1,440(sp)
    800059c8:	fb4a                	sd	s2,432(sp)
    800059ca:	f74e                	sd	s3,424(sp)
    800059cc:	f352                	sd	s4,416(sp)
    800059ce:	ef56                	sd	s5,408(sp)
    800059d0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059d2:	08000613          	li	a2,128
    800059d6:	f4040593          	addi	a1,s0,-192
    800059da:	4501                	li	a0,0
    800059dc:	ffffd097          	auipc	ra,0xffffd
    800059e0:	1de080e7          	jalr	478(ra) # 80002bba <argstr>
    return -1;
    800059e4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059e6:	0c054b63          	bltz	a0,80005abc <sys_exec+0xfc>
    800059ea:	e3840593          	addi	a1,s0,-456
    800059ee:	4505                	li	a0,1
    800059f0:	ffffd097          	auipc	ra,0xffffd
    800059f4:	1a8080e7          	jalr	424(ra) # 80002b98 <argaddr>
    800059f8:	0c054263          	bltz	a0,80005abc <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800059fc:	10000613          	li	a2,256
    80005a00:	4581                	li	a1,0
    80005a02:	e4040513          	addi	a0,s0,-448
    80005a06:	ffffb097          	auipc	ra,0xffffb
    80005a0a:	2f6080e7          	jalr	758(ra) # 80000cfc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a0e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a12:	89a6                	mv	s3,s1
    80005a14:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a16:	02000a13          	li	s4,32
    80005a1a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a1e:	00391513          	slli	a0,s2,0x3
    80005a22:	e3040593          	addi	a1,s0,-464
    80005a26:	e3843783          	ld	a5,-456(s0)
    80005a2a:	953e                	add	a0,a0,a5
    80005a2c:	ffffd097          	auipc	ra,0xffffd
    80005a30:	0b0080e7          	jalr	176(ra) # 80002adc <fetchaddr>
    80005a34:	02054a63          	bltz	a0,80005a68 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a38:	e3043783          	ld	a5,-464(s0)
    80005a3c:	c3b9                	beqz	a5,80005a82 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	0d2080e7          	jalr	210(ra) # 80000b10 <kalloc>
    80005a46:	85aa                	mv	a1,a0
    80005a48:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a4c:	cd11                	beqz	a0,80005a68 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a4e:	6605                	lui	a2,0x1
    80005a50:	e3043503          	ld	a0,-464(s0)
    80005a54:	ffffd097          	auipc	ra,0xffffd
    80005a58:	0da080e7          	jalr	218(ra) # 80002b2e <fetchstr>
    80005a5c:	00054663          	bltz	a0,80005a68 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a60:	0905                	addi	s2,s2,1
    80005a62:	09a1                	addi	s3,s3,8
    80005a64:	fb491be3          	bne	s2,s4,80005a1a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a68:	f4040913          	addi	s2,s0,-192
    80005a6c:	6088                	ld	a0,0(s1)
    80005a6e:	c531                	beqz	a0,80005aba <sys_exec+0xfa>
    kfree(argv[i]);
    80005a70:	ffffb097          	auipc	ra,0xffffb
    80005a74:	fa2080e7          	jalr	-94(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a78:	04a1                	addi	s1,s1,8
    80005a7a:	ff2499e3          	bne	s1,s2,80005a6c <sys_exec+0xac>
  return -1;
    80005a7e:	597d                	li	s2,-1
    80005a80:	a835                	j	80005abc <sys_exec+0xfc>
      argv[i] = 0;
    80005a82:	0a8e                	slli	s5,s5,0x3
    80005a84:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005a88:	00878ab3          	add	s5,a5,s0
    80005a8c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a90:	e4040593          	addi	a1,s0,-448
    80005a94:	f4040513          	addi	a0,s0,-192
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	172080e7          	jalr	370(ra) # 80004c0a <exec>
    80005aa0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aa2:	f4040993          	addi	s3,s0,-192
    80005aa6:	6088                	ld	a0,0(s1)
    80005aa8:	c911                	beqz	a0,80005abc <sys_exec+0xfc>
    kfree(argv[i]);
    80005aaa:	ffffb097          	auipc	ra,0xffffb
    80005aae:	f68080e7          	jalr	-152(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab2:	04a1                	addi	s1,s1,8
    80005ab4:	ff3499e3          	bne	s1,s3,80005aa6 <sys_exec+0xe6>
    80005ab8:	a011                	j	80005abc <sys_exec+0xfc>
  return -1;
    80005aba:	597d                	li	s2,-1
}
    80005abc:	854a                	mv	a0,s2
    80005abe:	60be                	ld	ra,456(sp)
    80005ac0:	641e                	ld	s0,448(sp)
    80005ac2:	74fa                	ld	s1,440(sp)
    80005ac4:	795a                	ld	s2,432(sp)
    80005ac6:	79ba                	ld	s3,424(sp)
    80005ac8:	7a1a                	ld	s4,416(sp)
    80005aca:	6afa                	ld	s5,408(sp)
    80005acc:	6179                	addi	sp,sp,464
    80005ace:	8082                	ret

0000000080005ad0 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ad0:	7139                	addi	sp,sp,-64
    80005ad2:	fc06                	sd	ra,56(sp)
    80005ad4:	f822                	sd	s0,48(sp)
    80005ad6:	f426                	sd	s1,40(sp)
    80005ad8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ada:	ffffc097          	auipc	ra,0xffffc
    80005ade:	f34080e7          	jalr	-204(ra) # 80001a0e <myproc>
    80005ae2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ae4:	fd840593          	addi	a1,s0,-40
    80005ae8:	4501                	li	a0,0
    80005aea:	ffffd097          	auipc	ra,0xffffd
    80005aee:	0ae080e7          	jalr	174(ra) # 80002b98 <argaddr>
    return -1;
    80005af2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005af4:	0e054063          	bltz	a0,80005bd4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005af8:	fc840593          	addi	a1,s0,-56
    80005afc:	fd040513          	addi	a0,s0,-48
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	dd6080e7          	jalr	-554(ra) # 800048d6 <pipealloc>
    return -1;
    80005b08:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b0a:	0c054563          	bltz	a0,80005bd4 <sys_pipe+0x104>
  fd0 = -1;
    80005b0e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b12:	fd043503          	ld	a0,-48(s0)
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	504080e7          	jalr	1284(ra) # 8000501a <fdalloc>
    80005b1e:	fca42223          	sw	a0,-60(s0)
    80005b22:	08054c63          	bltz	a0,80005bba <sys_pipe+0xea>
    80005b26:	fc843503          	ld	a0,-56(s0)
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	4f0080e7          	jalr	1264(ra) # 8000501a <fdalloc>
    80005b32:	fca42023          	sw	a0,-64(s0)
    80005b36:	06054963          	bltz	a0,80005ba8 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b3a:	4691                	li	a3,4
    80005b3c:	fc440613          	addi	a2,s0,-60
    80005b40:	fd843583          	ld	a1,-40(s0)
    80005b44:	68a8                	ld	a0,80(s1)
    80005b46:	ffffc097          	auipc	ra,0xffffc
    80005b4a:	bbe080e7          	jalr	-1090(ra) # 80001704 <copyout>
    80005b4e:	02054063          	bltz	a0,80005b6e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b52:	4691                	li	a3,4
    80005b54:	fc040613          	addi	a2,s0,-64
    80005b58:	fd843583          	ld	a1,-40(s0)
    80005b5c:	0591                	addi	a1,a1,4
    80005b5e:	68a8                	ld	a0,80(s1)
    80005b60:	ffffc097          	auipc	ra,0xffffc
    80005b64:	ba4080e7          	jalr	-1116(ra) # 80001704 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b68:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b6a:	06055563          	bgez	a0,80005bd4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b6e:	fc442783          	lw	a5,-60(s0)
    80005b72:	07e9                	addi	a5,a5,26
    80005b74:	078e                	slli	a5,a5,0x3
    80005b76:	97a6                	add	a5,a5,s1
    80005b78:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b7c:	fc042783          	lw	a5,-64(s0)
    80005b80:	07e9                	addi	a5,a5,26
    80005b82:	078e                	slli	a5,a5,0x3
    80005b84:	00f48533          	add	a0,s1,a5
    80005b88:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b8c:	fd043503          	ld	a0,-48(s0)
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	9f0080e7          	jalr	-1552(ra) # 80004580 <fileclose>
    fileclose(wf);
    80005b98:	fc843503          	ld	a0,-56(s0)
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	9e4080e7          	jalr	-1564(ra) # 80004580 <fileclose>
    return -1;
    80005ba4:	57fd                	li	a5,-1
    80005ba6:	a03d                	j	80005bd4 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ba8:	fc442783          	lw	a5,-60(s0)
    80005bac:	0007c763          	bltz	a5,80005bba <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bb0:	07e9                	addi	a5,a5,26
    80005bb2:	078e                	slli	a5,a5,0x3
    80005bb4:	97a6                	add	a5,a5,s1
    80005bb6:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005bba:	fd043503          	ld	a0,-48(s0)
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	9c2080e7          	jalr	-1598(ra) # 80004580 <fileclose>
    fileclose(wf);
    80005bc6:	fc843503          	ld	a0,-56(s0)
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	9b6080e7          	jalr	-1610(ra) # 80004580 <fileclose>
    return -1;
    80005bd2:	57fd                	li	a5,-1
}
    80005bd4:	853e                	mv	a0,a5
    80005bd6:	70e2                	ld	ra,56(sp)
    80005bd8:	7442                	ld	s0,48(sp)
    80005bda:	74a2                	ld	s1,40(sp)
    80005bdc:	6121                	addi	sp,sp,64
    80005bde:	8082                	ret

0000000080005be0 <kernelvec>:
    80005be0:	7111                	addi	sp,sp,-256
    80005be2:	e006                	sd	ra,0(sp)
    80005be4:	e40a                	sd	sp,8(sp)
    80005be6:	e80e                	sd	gp,16(sp)
    80005be8:	ec12                	sd	tp,24(sp)
    80005bea:	f016                	sd	t0,32(sp)
    80005bec:	f41a                	sd	t1,40(sp)
    80005bee:	f81e                	sd	t2,48(sp)
    80005bf0:	fc22                	sd	s0,56(sp)
    80005bf2:	e0a6                	sd	s1,64(sp)
    80005bf4:	e4aa                	sd	a0,72(sp)
    80005bf6:	e8ae                	sd	a1,80(sp)
    80005bf8:	ecb2                	sd	a2,88(sp)
    80005bfa:	f0b6                	sd	a3,96(sp)
    80005bfc:	f4ba                	sd	a4,104(sp)
    80005bfe:	f8be                	sd	a5,112(sp)
    80005c00:	fcc2                	sd	a6,120(sp)
    80005c02:	e146                	sd	a7,128(sp)
    80005c04:	e54a                	sd	s2,136(sp)
    80005c06:	e94e                	sd	s3,144(sp)
    80005c08:	ed52                	sd	s4,152(sp)
    80005c0a:	f156                	sd	s5,160(sp)
    80005c0c:	f55a                	sd	s6,168(sp)
    80005c0e:	f95e                	sd	s7,176(sp)
    80005c10:	fd62                	sd	s8,184(sp)
    80005c12:	e1e6                	sd	s9,192(sp)
    80005c14:	e5ea                	sd	s10,200(sp)
    80005c16:	e9ee                	sd	s11,208(sp)
    80005c18:	edf2                	sd	t3,216(sp)
    80005c1a:	f1f6                	sd	t4,224(sp)
    80005c1c:	f5fa                	sd	t5,232(sp)
    80005c1e:	f9fe                	sd	t6,240(sp)
    80005c20:	d89fc0ef          	jal	ra,800029a8 <kerneltrap>
    80005c24:	6082                	ld	ra,0(sp)
    80005c26:	6122                	ld	sp,8(sp)
    80005c28:	61c2                	ld	gp,16(sp)
    80005c2a:	7282                	ld	t0,32(sp)
    80005c2c:	7322                	ld	t1,40(sp)
    80005c2e:	73c2                	ld	t2,48(sp)
    80005c30:	7462                	ld	s0,56(sp)
    80005c32:	6486                	ld	s1,64(sp)
    80005c34:	6526                	ld	a0,72(sp)
    80005c36:	65c6                	ld	a1,80(sp)
    80005c38:	6666                	ld	a2,88(sp)
    80005c3a:	7686                	ld	a3,96(sp)
    80005c3c:	7726                	ld	a4,104(sp)
    80005c3e:	77c6                	ld	a5,112(sp)
    80005c40:	7866                	ld	a6,120(sp)
    80005c42:	688a                	ld	a7,128(sp)
    80005c44:	692a                	ld	s2,136(sp)
    80005c46:	69ca                	ld	s3,144(sp)
    80005c48:	6a6a                	ld	s4,152(sp)
    80005c4a:	7a8a                	ld	s5,160(sp)
    80005c4c:	7b2a                	ld	s6,168(sp)
    80005c4e:	7bca                	ld	s7,176(sp)
    80005c50:	7c6a                	ld	s8,184(sp)
    80005c52:	6c8e                	ld	s9,192(sp)
    80005c54:	6d2e                	ld	s10,200(sp)
    80005c56:	6dce                	ld	s11,208(sp)
    80005c58:	6e6e                	ld	t3,216(sp)
    80005c5a:	7e8e                	ld	t4,224(sp)
    80005c5c:	7f2e                	ld	t5,232(sp)
    80005c5e:	7fce                	ld	t6,240(sp)
    80005c60:	6111                	addi	sp,sp,256
    80005c62:	10200073          	sret
    80005c66:	00000013          	nop
    80005c6a:	00000013          	nop
    80005c6e:	0001                	nop

0000000080005c70 <timervec>:
    80005c70:	34051573          	csrrw	a0,mscratch,a0
    80005c74:	e10c                	sd	a1,0(a0)
    80005c76:	e510                	sd	a2,8(a0)
    80005c78:	e914                	sd	a3,16(a0)
    80005c7a:	710c                	ld	a1,32(a0)
    80005c7c:	7510                	ld	a2,40(a0)
    80005c7e:	6194                	ld	a3,0(a1)
    80005c80:	96b2                	add	a3,a3,a2
    80005c82:	e194                	sd	a3,0(a1)
    80005c84:	4589                	li	a1,2
    80005c86:	14459073          	csrw	sip,a1
    80005c8a:	6914                	ld	a3,16(a0)
    80005c8c:	6510                	ld	a2,8(a0)
    80005c8e:	610c                	ld	a1,0(a0)
    80005c90:	34051573          	csrrw	a0,mscratch,a0
    80005c94:	30200073          	mret
	...

0000000080005c9a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c9a:	1141                	addi	sp,sp,-16
    80005c9c:	e422                	sd	s0,8(sp)
    80005c9e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ca0:	0c0007b7          	lui	a5,0xc000
    80005ca4:	4705                	li	a4,1
    80005ca6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ca8:	c3d8                	sw	a4,4(a5)
}
    80005caa:	6422                	ld	s0,8(sp)
    80005cac:	0141                	addi	sp,sp,16
    80005cae:	8082                	ret

0000000080005cb0 <plicinithart>:

void
plicinithart(void)
{
    80005cb0:	1141                	addi	sp,sp,-16
    80005cb2:	e406                	sd	ra,8(sp)
    80005cb4:	e022                	sd	s0,0(sp)
    80005cb6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cb8:	ffffc097          	auipc	ra,0xffffc
    80005cbc:	d2a080e7          	jalr	-726(ra) # 800019e2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005cc0:	0085171b          	slliw	a4,a0,0x8
    80005cc4:	0c0027b7          	lui	a5,0xc002
    80005cc8:	97ba                	add	a5,a5,a4
    80005cca:	40200713          	li	a4,1026
    80005cce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cd2:	00d5151b          	slliw	a0,a0,0xd
    80005cd6:	0c2017b7          	lui	a5,0xc201
    80005cda:	97aa                	add	a5,a5,a0
    80005cdc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ce0:	60a2                	ld	ra,8(sp)
    80005ce2:	6402                	ld	s0,0(sp)
    80005ce4:	0141                	addi	sp,sp,16
    80005ce6:	8082                	ret

0000000080005ce8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ce8:	1141                	addi	sp,sp,-16
    80005cea:	e406                	sd	ra,8(sp)
    80005cec:	e022                	sd	s0,0(sp)
    80005cee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cf0:	ffffc097          	auipc	ra,0xffffc
    80005cf4:	cf2080e7          	jalr	-782(ra) # 800019e2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cf8:	00d5151b          	slliw	a0,a0,0xd
    80005cfc:	0c2017b7          	lui	a5,0xc201
    80005d00:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d02:	43c8                	lw	a0,4(a5)
    80005d04:	60a2                	ld	ra,8(sp)
    80005d06:	6402                	ld	s0,0(sp)
    80005d08:	0141                	addi	sp,sp,16
    80005d0a:	8082                	ret

0000000080005d0c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d0c:	1101                	addi	sp,sp,-32
    80005d0e:	ec06                	sd	ra,24(sp)
    80005d10:	e822                	sd	s0,16(sp)
    80005d12:	e426                	sd	s1,8(sp)
    80005d14:	1000                	addi	s0,sp,32
    80005d16:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d18:	ffffc097          	auipc	ra,0xffffc
    80005d1c:	cca080e7          	jalr	-822(ra) # 800019e2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d20:	00d5151b          	slliw	a0,a0,0xd
    80005d24:	0c2017b7          	lui	a5,0xc201
    80005d28:	97aa                	add	a5,a5,a0
    80005d2a:	c3c4                	sw	s1,4(a5)
}
    80005d2c:	60e2                	ld	ra,24(sp)
    80005d2e:	6442                	ld	s0,16(sp)
    80005d30:	64a2                	ld	s1,8(sp)
    80005d32:	6105                	addi	sp,sp,32
    80005d34:	8082                	ret

0000000080005d36 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d36:	1141                	addi	sp,sp,-16
    80005d38:	e406                	sd	ra,8(sp)
    80005d3a:	e022                	sd	s0,0(sp)
    80005d3c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d3e:	479d                	li	a5,7
    80005d40:	04a7cb63          	blt	a5,a0,80005d96 <free_desc+0x60>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d44:	0001d717          	auipc	a4,0x1d
    80005d48:	2bc70713          	addi	a4,a4,700 # 80023000 <disk>
    80005d4c:	972a                	add	a4,a4,a0
    80005d4e:	6789                	lui	a5,0x2
    80005d50:	97ba                	add	a5,a5,a4
    80005d52:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d56:	eba1                	bnez	a5,80005da6 <free_desc+0x70>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d58:	00451713          	slli	a4,a0,0x4
    80005d5c:	0001f797          	auipc	a5,0x1f
    80005d60:	2a47b783          	ld	a5,676(a5) # 80025000 <disk+0x2000>
    80005d64:	97ba                	add	a5,a5,a4
    80005d66:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005d6a:	0001d717          	auipc	a4,0x1d
    80005d6e:	29670713          	addi	a4,a4,662 # 80023000 <disk>
    80005d72:	972a                	add	a4,a4,a0
    80005d74:	6789                	lui	a5,0x2
    80005d76:	97ba                	add	a5,a5,a4
    80005d78:	4705                	li	a4,1
    80005d7a:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d7e:	0001f517          	auipc	a0,0x1f
    80005d82:	29a50513          	addi	a0,a0,666 # 80025018 <disk+0x2018>
    80005d86:	ffffc097          	auipc	ra,0xffffc
    80005d8a:	620080e7          	jalr	1568(ra) # 800023a6 <wakeup>
}
    80005d8e:	60a2                	ld	ra,8(sp)
    80005d90:	6402                	ld	s0,0(sp)
    80005d92:	0141                	addi	sp,sp,16
    80005d94:	8082                	ret
    panic("virtio_disk_intr 1");
    80005d96:	00003517          	auipc	a0,0x3
    80005d9a:	95a50513          	addi	a0,a0,-1702 # 800086f0 <syscalls+0x330>
    80005d9e:	ffffa097          	auipc	ra,0xffffa
    80005da2:	7a8080e7          	jalr	1960(ra) # 80000546 <panic>
    panic("virtio_disk_intr 2");
    80005da6:	00003517          	auipc	a0,0x3
    80005daa:	96250513          	addi	a0,a0,-1694 # 80008708 <syscalls+0x348>
    80005dae:	ffffa097          	auipc	ra,0xffffa
    80005db2:	798080e7          	jalr	1944(ra) # 80000546 <panic>

0000000080005db6 <virtio_disk_init>:
{
    80005db6:	1101                	addi	sp,sp,-32
    80005db8:	ec06                	sd	ra,24(sp)
    80005dba:	e822                	sd	s0,16(sp)
    80005dbc:	e426                	sd	s1,8(sp)
    80005dbe:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005dc0:	00003597          	auipc	a1,0x3
    80005dc4:	96058593          	addi	a1,a1,-1696 # 80008720 <syscalls+0x360>
    80005dc8:	0001f517          	auipc	a0,0x1f
    80005dcc:	2e050513          	addi	a0,a0,736 # 800250a8 <disk+0x20a8>
    80005dd0:	ffffb097          	auipc	ra,0xffffb
    80005dd4:	da0080e7          	jalr	-608(ra) # 80000b70 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dd8:	100017b7          	lui	a5,0x10001
    80005ddc:	4398                	lw	a4,0(a5)
    80005dde:	2701                	sext.w	a4,a4
    80005de0:	747277b7          	lui	a5,0x74727
    80005de4:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005de8:	0ef71063          	bne	a4,a5,80005ec8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dec:	100017b7          	lui	a5,0x10001
    80005df0:	43dc                	lw	a5,4(a5)
    80005df2:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005df4:	4705                	li	a4,1
    80005df6:	0ce79963          	bne	a5,a4,80005ec8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dfa:	100017b7          	lui	a5,0x10001
    80005dfe:	479c                	lw	a5,8(a5)
    80005e00:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e02:	4709                	li	a4,2
    80005e04:	0ce79263          	bne	a5,a4,80005ec8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e08:	100017b7          	lui	a5,0x10001
    80005e0c:	47d8                	lw	a4,12(a5)
    80005e0e:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e10:	554d47b7          	lui	a5,0x554d4
    80005e14:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e18:	0af71863          	bne	a4,a5,80005ec8 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e1c:	100017b7          	lui	a5,0x10001
    80005e20:	4705                	li	a4,1
    80005e22:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e24:	470d                	li	a4,3
    80005e26:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e28:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e2a:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e2e:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e32:	8f75                	and	a4,a4,a3
    80005e34:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e36:	472d                	li	a4,11
    80005e38:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e3a:	473d                	li	a4,15
    80005e3c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e3e:	6705                	lui	a4,0x1
    80005e40:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e42:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e46:	5bdc                	lw	a5,52(a5)
    80005e48:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e4a:	c7d9                	beqz	a5,80005ed8 <virtio_disk_init+0x122>
  if(max < NUM)
    80005e4c:	471d                	li	a4,7
    80005e4e:	08f77d63          	bgeu	a4,a5,80005ee8 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e52:	100014b7          	lui	s1,0x10001
    80005e56:	47a1                	li	a5,8
    80005e58:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e5a:	6609                	lui	a2,0x2
    80005e5c:	4581                	li	a1,0
    80005e5e:	0001d517          	auipc	a0,0x1d
    80005e62:	1a250513          	addi	a0,a0,418 # 80023000 <disk>
    80005e66:	ffffb097          	auipc	ra,0xffffb
    80005e6a:	e96080e7          	jalr	-362(ra) # 80000cfc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e6e:	0001d717          	auipc	a4,0x1d
    80005e72:	19270713          	addi	a4,a4,402 # 80023000 <disk>
    80005e76:	00c75793          	srli	a5,a4,0xc
    80005e7a:	2781                	sext.w	a5,a5
    80005e7c:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005e7e:	0001f797          	auipc	a5,0x1f
    80005e82:	18278793          	addi	a5,a5,386 # 80025000 <disk+0x2000>
    80005e86:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005e88:	0001d717          	auipc	a4,0x1d
    80005e8c:	1f870713          	addi	a4,a4,504 # 80023080 <disk+0x80>
    80005e90:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005e92:	0001e717          	auipc	a4,0x1e
    80005e96:	16e70713          	addi	a4,a4,366 # 80024000 <disk+0x1000>
    80005e9a:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e9c:	4705                	li	a4,1
    80005e9e:	00e78c23          	sb	a4,24(a5)
    80005ea2:	00e78ca3          	sb	a4,25(a5)
    80005ea6:	00e78d23          	sb	a4,26(a5)
    80005eaa:	00e78da3          	sb	a4,27(a5)
    80005eae:	00e78e23          	sb	a4,28(a5)
    80005eb2:	00e78ea3          	sb	a4,29(a5)
    80005eb6:	00e78f23          	sb	a4,30(a5)
    80005eba:	00e78fa3          	sb	a4,31(a5)
}
    80005ebe:	60e2                	ld	ra,24(sp)
    80005ec0:	6442                	ld	s0,16(sp)
    80005ec2:	64a2                	ld	s1,8(sp)
    80005ec4:	6105                	addi	sp,sp,32
    80005ec6:	8082                	ret
    panic("could not find virtio disk");
    80005ec8:	00003517          	auipc	a0,0x3
    80005ecc:	86850513          	addi	a0,a0,-1944 # 80008730 <syscalls+0x370>
    80005ed0:	ffffa097          	auipc	ra,0xffffa
    80005ed4:	676080e7          	jalr	1654(ra) # 80000546 <panic>
    panic("virtio disk has no queue 0");
    80005ed8:	00003517          	auipc	a0,0x3
    80005edc:	87850513          	addi	a0,a0,-1928 # 80008750 <syscalls+0x390>
    80005ee0:	ffffa097          	auipc	ra,0xffffa
    80005ee4:	666080e7          	jalr	1638(ra) # 80000546 <panic>
    panic("virtio disk max queue too short");
    80005ee8:	00003517          	auipc	a0,0x3
    80005eec:	88850513          	addi	a0,a0,-1912 # 80008770 <syscalls+0x3b0>
    80005ef0:	ffffa097          	auipc	ra,0xffffa
    80005ef4:	656080e7          	jalr	1622(ra) # 80000546 <panic>

0000000080005ef8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ef8:	7175                	addi	sp,sp,-144
    80005efa:	e506                	sd	ra,136(sp)
    80005efc:	e122                	sd	s0,128(sp)
    80005efe:	fca6                	sd	s1,120(sp)
    80005f00:	f8ca                	sd	s2,112(sp)
    80005f02:	f4ce                	sd	s3,104(sp)
    80005f04:	f0d2                	sd	s4,96(sp)
    80005f06:	ecd6                	sd	s5,88(sp)
    80005f08:	e8da                	sd	s6,80(sp)
    80005f0a:	e4de                	sd	s7,72(sp)
    80005f0c:	e0e2                	sd	s8,64(sp)
    80005f0e:	fc66                	sd	s9,56(sp)
    80005f10:	f86a                	sd	s10,48(sp)
    80005f12:	f46e                	sd	s11,40(sp)
    80005f14:	0900                	addi	s0,sp,144
    80005f16:	8aaa                	mv	s5,a0
    80005f18:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f1a:	00c52c83          	lw	s9,12(a0)
    80005f1e:	001c9c9b          	slliw	s9,s9,0x1
    80005f22:	1c82                	slli	s9,s9,0x20
    80005f24:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f28:	0001f517          	auipc	a0,0x1f
    80005f2c:	18050513          	addi	a0,a0,384 # 800250a8 <disk+0x20a8>
    80005f30:	ffffb097          	auipc	ra,0xffffb
    80005f34:	cd0080e7          	jalr	-816(ra) # 80000c00 <acquire>
  for(int i = 0; i < 3; i++){
    80005f38:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f3a:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f3c:	0001dc17          	auipc	s8,0x1d
    80005f40:	0c4c0c13          	addi	s8,s8,196 # 80023000 <disk>
    80005f44:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f46:	4b0d                	li	s6,3
    80005f48:	a0ad                	j	80005fb2 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f4a:	00fc0733          	add	a4,s8,a5
    80005f4e:	975e                	add	a4,a4,s7
    80005f50:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f54:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f56:	0207c563          	bltz	a5,80005f80 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f5a:	2905                	addiw	s2,s2,1
    80005f5c:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005f5e:	19690c63          	beq	s2,s6,800060f6 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005f62:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f64:	0001f717          	auipc	a4,0x1f
    80005f68:	0b470713          	addi	a4,a4,180 # 80025018 <disk+0x2018>
    80005f6c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f6e:	00074683          	lbu	a3,0(a4)
    80005f72:	fee1                	bnez	a3,80005f4a <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f74:	2785                	addiw	a5,a5,1
    80005f76:	0705                	addi	a4,a4,1
    80005f78:	fe979be3          	bne	a5,s1,80005f6e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f7c:	57fd                	li	a5,-1
    80005f7e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f80:	01205d63          	blez	s2,80005f9a <virtio_disk_rw+0xa2>
    80005f84:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f86:	000a2503          	lw	a0,0(s4)
    80005f8a:	00000097          	auipc	ra,0x0
    80005f8e:	dac080e7          	jalr	-596(ra) # 80005d36 <free_desc>
      for(int j = 0; j < i; j++)
    80005f92:	2d85                	addiw	s11,s11,1
    80005f94:	0a11                	addi	s4,s4,4
    80005f96:	ff2d98e3          	bne	s11,s2,80005f86 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f9a:	0001f597          	auipc	a1,0x1f
    80005f9e:	10e58593          	addi	a1,a1,270 # 800250a8 <disk+0x20a8>
    80005fa2:	0001f517          	auipc	a0,0x1f
    80005fa6:	07650513          	addi	a0,a0,118 # 80025018 <disk+0x2018>
    80005faa:	ffffc097          	auipc	ra,0xffffc
    80005fae:	27c080e7          	jalr	636(ra) # 80002226 <sleep>
  for(int i = 0; i < 3; i++){
    80005fb2:	f8040a13          	addi	s4,s0,-128
{
    80005fb6:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005fb8:	894e                	mv	s2,s3
    80005fba:	b765                	j	80005f62 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fbc:	0001f717          	auipc	a4,0x1f
    80005fc0:	04473703          	ld	a4,68(a4) # 80025000 <disk+0x2000>
    80005fc4:	973e                	add	a4,a4,a5
    80005fc6:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fca:	0001d517          	auipc	a0,0x1d
    80005fce:	03650513          	addi	a0,a0,54 # 80023000 <disk>
    80005fd2:	0001f717          	auipc	a4,0x1f
    80005fd6:	02e70713          	addi	a4,a4,46 # 80025000 <disk+0x2000>
    80005fda:	6314                	ld	a3,0(a4)
    80005fdc:	96be                	add	a3,a3,a5
    80005fde:	00c6d603          	lhu	a2,12(a3)
    80005fe2:	00166613          	ori	a2,a2,1
    80005fe6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005fea:	f8842683          	lw	a3,-120(s0)
    80005fee:	6310                	ld	a2,0(a4)
    80005ff0:	97b2                	add	a5,a5,a2
    80005ff2:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80005ff6:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    80005ffa:	0612                	slli	a2,a2,0x4
    80005ffc:	962a                	add	a2,a2,a0
    80005ffe:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006002:	00469793          	slli	a5,a3,0x4
    80006006:	630c                	ld	a1,0(a4)
    80006008:	95be                	add	a1,a1,a5
    8000600a:	6689                	lui	a3,0x2
    8000600c:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006010:	96ca                	add	a3,a3,s2
    80006012:	96aa                	add	a3,a3,a0
    80006014:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80006016:	6314                	ld	a3,0(a4)
    80006018:	96be                	add	a3,a3,a5
    8000601a:	4585                	li	a1,1
    8000601c:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000601e:	6314                	ld	a3,0(a4)
    80006020:	96be                	add	a3,a3,a5
    80006022:	4509                	li	a0,2
    80006024:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006028:	6314                	ld	a3,0(a4)
    8000602a:	97b6                	add	a5,a5,a3
    8000602c:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006030:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006034:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006038:	6714                	ld	a3,8(a4)
    8000603a:	0026d783          	lhu	a5,2(a3)
    8000603e:	8b9d                	andi	a5,a5,7
    80006040:	0789                	addi	a5,a5,2
    80006042:	0786                	slli	a5,a5,0x1
    80006044:	96be                	add	a3,a3,a5
    80006046:	00969023          	sh	s1,0(a3)
  __sync_synchronize();
    8000604a:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000604e:	6718                	ld	a4,8(a4)
    80006050:	00275783          	lhu	a5,2(a4)
    80006054:	2785                	addiw	a5,a5,1
    80006056:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000605a:	100017b7          	lui	a5,0x10001
    8000605e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006062:	004aa783          	lw	a5,4(s5)
    80006066:	02b79163          	bne	a5,a1,80006088 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000606a:	0001f917          	auipc	s2,0x1f
    8000606e:	03e90913          	addi	s2,s2,62 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006072:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006074:	85ca                	mv	a1,s2
    80006076:	8556                	mv	a0,s5
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	1ae080e7          	jalr	430(ra) # 80002226 <sleep>
  while(b->disk == 1) {
    80006080:	004aa783          	lw	a5,4(s5)
    80006084:	fe9788e3          	beq	a5,s1,80006074 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006088:	f8042483          	lw	s1,-128(s0)
    8000608c:	20048713          	addi	a4,s1,512
    80006090:	0712                	slli	a4,a4,0x4
    80006092:	0001d797          	auipc	a5,0x1d
    80006096:	f6e78793          	addi	a5,a5,-146 # 80023000 <disk>
    8000609a:	97ba                	add	a5,a5,a4
    8000609c:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060a0:	0001f917          	auipc	s2,0x1f
    800060a4:	f6090913          	addi	s2,s2,-160 # 80025000 <disk+0x2000>
    800060a8:	a019                	j	800060ae <virtio_disk_rw+0x1b6>
      i = disk.desc[i].next;
    800060aa:	00e7d483          	lhu	s1,14(a5)
    free_desc(i);
    800060ae:	8526                	mv	a0,s1
    800060b0:	00000097          	auipc	ra,0x0
    800060b4:	c86080e7          	jalr	-890(ra) # 80005d36 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060b8:	0492                	slli	s1,s1,0x4
    800060ba:	00093783          	ld	a5,0(s2)
    800060be:	97a6                	add	a5,a5,s1
    800060c0:	00c7d703          	lhu	a4,12(a5)
    800060c4:	8b05                	andi	a4,a4,1
    800060c6:	f375                	bnez	a4,800060aa <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060c8:	0001f517          	auipc	a0,0x1f
    800060cc:	fe050513          	addi	a0,a0,-32 # 800250a8 <disk+0x20a8>
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	be4080e7          	jalr	-1052(ra) # 80000cb4 <release>
}
    800060d8:	60aa                	ld	ra,136(sp)
    800060da:	640a                	ld	s0,128(sp)
    800060dc:	74e6                	ld	s1,120(sp)
    800060de:	7946                	ld	s2,112(sp)
    800060e0:	79a6                	ld	s3,104(sp)
    800060e2:	7a06                	ld	s4,96(sp)
    800060e4:	6ae6                	ld	s5,88(sp)
    800060e6:	6b46                	ld	s6,80(sp)
    800060e8:	6ba6                	ld	s7,72(sp)
    800060ea:	6c06                	ld	s8,64(sp)
    800060ec:	7ce2                	ld	s9,56(sp)
    800060ee:	7d42                	ld	s10,48(sp)
    800060f0:	7da2                	ld	s11,40(sp)
    800060f2:	6149                	addi	sp,sp,144
    800060f4:	8082                	ret
  if(write)
    800060f6:	01a037b3          	snez	a5,s10
    800060fa:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800060fe:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006102:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006106:	f8042483          	lw	s1,-128(s0)
    8000610a:	00449913          	slli	s2,s1,0x4
    8000610e:	0001f997          	auipc	s3,0x1f
    80006112:	ef298993          	addi	s3,s3,-270 # 80025000 <disk+0x2000>
    80006116:	0009ba03          	ld	s4,0(s3)
    8000611a:	9a4a                	add	s4,s4,s2
    8000611c:	f7040513          	addi	a0,s0,-144
    80006120:	ffffb097          	auipc	ra,0xffffb
    80006124:	f6a080e7          	jalr	-150(ra) # 8000108a <kvmpa>
    80006128:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000612c:	0009b783          	ld	a5,0(s3)
    80006130:	97ca                	add	a5,a5,s2
    80006132:	4741                	li	a4,16
    80006134:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006136:	0009b783          	ld	a5,0(s3)
    8000613a:	97ca                	add	a5,a5,s2
    8000613c:	4705                	li	a4,1
    8000613e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006142:	f8442783          	lw	a5,-124(s0)
    80006146:	0009b703          	ld	a4,0(s3)
    8000614a:	974a                	add	a4,a4,s2
    8000614c:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006150:	0792                	slli	a5,a5,0x4
    80006152:	0009b703          	ld	a4,0(s3)
    80006156:	973e                	add	a4,a4,a5
    80006158:	058a8693          	addi	a3,s5,88
    8000615c:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000615e:	0009b703          	ld	a4,0(s3)
    80006162:	973e                	add	a4,a4,a5
    80006164:	40000693          	li	a3,1024
    80006168:	c714                	sw	a3,8(a4)
  if(write)
    8000616a:	e40d19e3          	bnez	s10,80005fbc <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000616e:	0001f717          	auipc	a4,0x1f
    80006172:	e9273703          	ld	a4,-366(a4) # 80025000 <disk+0x2000>
    80006176:	973e                	add	a4,a4,a5
    80006178:	4689                	li	a3,2
    8000617a:	00d71623          	sh	a3,12(a4)
    8000617e:	b5b1                	j	80005fca <virtio_disk_rw+0xd2>

0000000080006180 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006180:	1101                	addi	sp,sp,-32
    80006182:	ec06                	sd	ra,24(sp)
    80006184:	e822                	sd	s0,16(sp)
    80006186:	e426                	sd	s1,8(sp)
    80006188:	e04a                	sd	s2,0(sp)
    8000618a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000618c:	0001f517          	auipc	a0,0x1f
    80006190:	f1c50513          	addi	a0,a0,-228 # 800250a8 <disk+0x20a8>
    80006194:	ffffb097          	auipc	ra,0xffffb
    80006198:	a6c080e7          	jalr	-1428(ra) # 80000c00 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000619c:	0001f717          	auipc	a4,0x1f
    800061a0:	e6470713          	addi	a4,a4,-412 # 80025000 <disk+0x2000>
    800061a4:	02075783          	lhu	a5,32(a4)
    800061a8:	6b18                	ld	a4,16(a4)
    800061aa:	00275683          	lhu	a3,2(a4)
    800061ae:	8ebd                	xor	a3,a3,a5
    800061b0:	8a9d                	andi	a3,a3,7
    800061b2:	cab9                	beqz	a3,80006208 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800061b4:	0001d917          	auipc	s2,0x1d
    800061b8:	e4c90913          	addi	s2,s2,-436 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061bc:	0001f497          	auipc	s1,0x1f
    800061c0:	e4448493          	addi	s1,s1,-444 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800061c4:	078e                	slli	a5,a5,0x3
    800061c6:	973e                	add	a4,a4,a5
    800061c8:	435c                	lw	a5,4(a4)
    if(disk.info[id].status != 0)
    800061ca:	20078713          	addi	a4,a5,512
    800061ce:	0712                	slli	a4,a4,0x4
    800061d0:	974a                	add	a4,a4,s2
    800061d2:	03074703          	lbu	a4,48(a4)
    800061d6:	ef21                	bnez	a4,8000622e <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800061d8:	20078793          	addi	a5,a5,512
    800061dc:	0792                	slli	a5,a5,0x4
    800061de:	97ca                	add	a5,a5,s2
    800061e0:	7798                	ld	a4,40(a5)
    800061e2:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800061e6:	7788                	ld	a0,40(a5)
    800061e8:	ffffc097          	auipc	ra,0xffffc
    800061ec:	1be080e7          	jalr	446(ra) # 800023a6 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061f0:	0204d783          	lhu	a5,32(s1)
    800061f4:	2785                	addiw	a5,a5,1
    800061f6:	8b9d                	andi	a5,a5,7
    800061f8:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061fc:	6898                	ld	a4,16(s1)
    800061fe:	00275683          	lhu	a3,2(a4)
    80006202:	8a9d                	andi	a3,a3,7
    80006204:	fcf690e3          	bne	a3,a5,800061c4 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006208:	10001737          	lui	a4,0x10001
    8000620c:	533c                	lw	a5,96(a4)
    8000620e:	8b8d                	andi	a5,a5,3
    80006210:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006212:	0001f517          	auipc	a0,0x1f
    80006216:	e9650513          	addi	a0,a0,-362 # 800250a8 <disk+0x20a8>
    8000621a:	ffffb097          	auipc	ra,0xffffb
    8000621e:	a9a080e7          	jalr	-1382(ra) # 80000cb4 <release>
}
    80006222:	60e2                	ld	ra,24(sp)
    80006224:	6442                	ld	s0,16(sp)
    80006226:	64a2                	ld	s1,8(sp)
    80006228:	6902                	ld	s2,0(sp)
    8000622a:	6105                	addi	sp,sp,32
    8000622c:	8082                	ret
      panic("virtio_disk_intr status");
    8000622e:	00002517          	auipc	a0,0x2
    80006232:	56250513          	addi	a0,a0,1378 # 80008790 <syscalls+0x3d0>
    80006236:	ffffa097          	auipc	ra,0xffffa
    8000623a:	310080e7          	jalr	784(ra) # 80000546 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
