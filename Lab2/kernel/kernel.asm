
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9e013103          	ld	sp,-1568(sp) # 800089e0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000060:	ba478793          	addi	a5,a5,-1116 # 80005c00 <timervec>
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
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
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
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	384080e7          	jalr	900(ra) # 800024aa <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
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
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	810080e7          	jalr	-2032(ra) # 800019de <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	014080e7          	jalr	20(ra) # 800021f2 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	23a080e7          	jalr	570(ra) # 80002454 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	204080e7          	jalr	516(ra) # 80002500 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	f28080e7          	jalr	-216(ra) # 80002378 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	72e78793          	addi	a5,a5,1838 # 80021bb0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	ac2080e7          	jalr	-1342(ra) # 80002378 <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	8a2080e7          	jalr	-1886(ra) # 800021f2 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	e18080e7          	jalr	-488(ra) # 800019c2 <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	de6080e7          	jalr	-538(ra) # 800019c2 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	dda080e7          	jalr	-550(ra) # 800019c2 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	dc2080e7          	jalr	-574(ra) # 800019c2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d82080e7          	jalr	-638(ra) # 800019c2 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	d56080e7          	jalr	-682(ra) # 800019c2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	aec080e7          	jalr	-1300(ra) # 800019b2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	ad0080e7          	jalr	-1328(ra) # 800019b2 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0d8080e7          	jalr	216(ra) # 80000fd4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00001097          	auipc	ra,0x1
    80000f08:	73c080e7          	jalr	1852(ra) # 80002640 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	d34080e7          	jalr	-716(ra) # 80005c40 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	002080e7          	jalr	2(ra) # 80001f16 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    printfinit();
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	854080e7          	jalr	-1964(ra) # 80000778 <printfinit>
    printf("\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	19c50513          	addi	a0,a0,412 # 800080c8 <digits+0x88>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	65e080e7          	jalr	1630(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	16450513          	addi	a0,a0,356 # 800080a0 <digits+0x60>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	64e080e7          	jalr	1614(ra) # 80000592 <printf>
    printf("\n");
    80000f4c:	00007517          	auipc	a0,0x7
    80000f50:	17c50513          	addi	a0,a0,380 # 800080c8 <digits+0x88>
    80000f54:	fffff097          	auipc	ra,0xfffff
    80000f58:	63e080e7          	jalr	1598(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	b88080e7          	jalr	-1144(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	2a0080e7          	jalr	672(ra) # 80001204 <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	068080e7          	jalr	104(ra) # 80000fd4 <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	96e080e7          	jalr	-1682(ra) # 800018e2 <procinit>
    trapinit();      // trap vectors
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	69c080e7          	jalr	1692(ra) # 80002618 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	6bc080e7          	jalr	1724(ra) # 80002640 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	c9e080e7          	jalr	-866(ra) # 80005c2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	cac080e7          	jalr	-852(ra) # 80005c40 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	e46080e7          	jalr	-442(ra) # 80002de2 <binit>
    iinit();         // inode cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	4d6080e7          	jalr	1238(ra) # 8000347a <iinit>
    fileinit();      // file table
    80000fac:	00003097          	auipc	ra,0x3
    80000fb0:	470080e7          	jalr	1136(ra) # 8000441c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	d94080e7          	jalr	-620(ra) # 80005d48 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	cec080e7          	jalr	-788(ra) # 80001ca8 <userinit>
    __sync_synchronize();
    80000fc4:	0ff0000f          	fence
    started = 1;
    80000fc8:	4785                	li	a5,1
    80000fca:	00008717          	auipc	a4,0x8
    80000fce:	04f72123          	sw	a5,66(a4) # 8000900c <started>
    80000fd2:	b789                	j	80000f14 <main+0x56>

0000000080000fd4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd4:	1141                	addi	sp,sp,-16
    80000fd6:	e422                	sd	s0,8(sp)
    80000fd8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fda:	00008797          	auipc	a5,0x8
    80000fde:	0367b783          	ld	a5,54(a5) # 80009010 <kernel_pagetable>
    80000fe2:	83b1                	srli	a5,a5,0xc
    80000fe4:	577d                	li	a4,-1
    80000fe6:	177e                	slli	a4,a4,0x3f
    80000fe8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fea:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff2:	6422                	ld	s0,8(sp)
    80000ff4:	0141                	addi	sp,sp,16
    80000ff6:	8082                	ret

0000000080000ff8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ff8:	7139                	addi	sp,sp,-64
    80000ffa:	fc06                	sd	ra,56(sp)
    80000ffc:	f822                	sd	s0,48(sp)
    80000ffe:	f426                	sd	s1,40(sp)
    80001000:	f04a                	sd	s2,32(sp)
    80001002:	ec4e                	sd	s3,24(sp)
    80001004:	e852                	sd	s4,16(sp)
    80001006:	e456                	sd	s5,8(sp)
    80001008:	e05a                	sd	s6,0(sp)
    8000100a:	0080                	addi	s0,sp,64
    8000100c:	84aa                	mv	s1,a0
    8000100e:	89ae                	mv	s3,a1
    80001010:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001012:	57fd                	li	a5,-1
    80001014:	83e9                	srli	a5,a5,0x1a
    80001016:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001018:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000101a:	04b7f263          	bgeu	a5,a1,8000105e <walk+0x66>
    panic("walk");
    8000101e:	00007517          	auipc	a0,0x7
    80001022:	0b250513          	addi	a0,a0,178 # 800080d0 <digits+0x90>
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	522080e7          	jalr	1314(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000102e:	060a8663          	beqz	s5,8000109a <walk+0xa2>
    80001032:	00000097          	auipc	ra,0x0
    80001036:	aee080e7          	jalr	-1298(ra) # 80000b20 <kalloc>
    8000103a:	84aa                	mv	s1,a0
    8000103c:	c529                	beqz	a0,80001086 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000103e:	6605                	lui	a2,0x1
    80001040:	4581                	li	a1,0
    80001042:	00000097          	auipc	ra,0x0
    80001046:	cca080e7          	jalr	-822(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000104a:	00c4d793          	srli	a5,s1,0xc
    8000104e:	07aa                	slli	a5,a5,0xa
    80001050:	0017e793          	ori	a5,a5,1
    80001054:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001058:	3a5d                	addiw	s4,s4,-9
    8000105a:	036a0063          	beq	s4,s6,8000107a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000105e:	0149d933          	srl	s2,s3,s4
    80001062:	1ff97913          	andi	s2,s2,511
    80001066:	090e                	slli	s2,s2,0x3
    80001068:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000106a:	00093483          	ld	s1,0(s2)
    8000106e:	0014f793          	andi	a5,s1,1
    80001072:	dfd5                	beqz	a5,8000102e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001074:	80a9                	srli	s1,s1,0xa
    80001076:	04b2                	slli	s1,s1,0xc
    80001078:	b7c5                	j	80001058 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000107a:	00c9d513          	srli	a0,s3,0xc
    8000107e:	1ff57513          	andi	a0,a0,511
    80001082:	050e                	slli	a0,a0,0x3
    80001084:	9526                	add	a0,a0,s1
}
    80001086:	70e2                	ld	ra,56(sp)
    80001088:	7442                	ld	s0,48(sp)
    8000108a:	74a2                	ld	s1,40(sp)
    8000108c:	7902                	ld	s2,32(sp)
    8000108e:	69e2                	ld	s3,24(sp)
    80001090:	6a42                	ld	s4,16(sp)
    80001092:	6aa2                	ld	s5,8(sp)
    80001094:	6b02                	ld	s6,0(sp)
    80001096:	6121                	addi	sp,sp,64
    80001098:	8082                	ret
        return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7ed                	j	80001086 <walk+0x8e>

000000008000109e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000109e:	57fd                	li	a5,-1
    800010a0:	83e9                	srli	a5,a5,0x1a
    800010a2:	00b7f463          	bgeu	a5,a1,800010aa <walkaddr+0xc>
    return 0;
    800010a6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010a8:	8082                	ret
{
    800010aa:	1141                	addi	sp,sp,-16
    800010ac:	e406                	sd	ra,8(sp)
    800010ae:	e022                	sd	s0,0(sp)
    800010b0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010b2:	4601                	li	a2,0
    800010b4:	00000097          	auipc	ra,0x0
    800010b8:	f44080e7          	jalr	-188(ra) # 80000ff8 <walk>
  if(pte == 0)
    800010bc:	c105                	beqz	a0,800010dc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010be:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c0:	0117f693          	andi	a3,a5,17
    800010c4:	4745                	li	a4,17
    return 0;
    800010c6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010c8:	00e68663          	beq	a3,a4,800010d4 <walkaddr+0x36>
}
    800010cc:	60a2                	ld	ra,8(sp)
    800010ce:	6402                	ld	s0,0(sp)
    800010d0:	0141                	addi	sp,sp,16
    800010d2:	8082                	ret
  pa = PTE2PA(*pte);
    800010d4:	00a7d513          	srli	a0,a5,0xa
    800010d8:	0532                	slli	a0,a0,0xc
  return pa;
    800010da:	bfcd                	j	800010cc <walkaddr+0x2e>
    return 0;
    800010dc:	4501                	li	a0,0
    800010de:	b7fd                	j	800010cc <walkaddr+0x2e>

00000000800010e0 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e0:	1101                	addi	sp,sp,-32
    800010e2:	ec06                	sd	ra,24(sp)
    800010e4:	e822                	sd	s0,16(sp)
    800010e6:	e426                	sd	s1,8(sp)
    800010e8:	1000                	addi	s0,sp,32
    800010ea:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010ec:	1552                	slli	a0,a0,0x34
    800010ee:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010f2:	4601                	li	a2,0
    800010f4:	00008517          	auipc	a0,0x8
    800010f8:	f1c53503          	ld	a0,-228(a0) # 80009010 <kernel_pagetable>
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	efc080e7          	jalr	-260(ra) # 80000ff8 <walk>
  if(pte == 0)
    80001104:	cd09                	beqz	a0,8000111e <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001106:	6108                	ld	a0,0(a0)
    80001108:	00157793          	andi	a5,a0,1
    8000110c:	c38d                	beqz	a5,8000112e <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000110e:	8129                	srli	a0,a0,0xa
    80001110:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001112:	9526                	add	a0,a0,s1
    80001114:	60e2                	ld	ra,24(sp)
    80001116:	6442                	ld	s0,16(sp)
    80001118:	64a2                	ld	s1,8(sp)
    8000111a:	6105                	addi	sp,sp,32
    8000111c:	8082                	ret
    panic("kvmpa");
    8000111e:	00007517          	auipc	a0,0x7
    80001122:	fba50513          	addi	a0,a0,-70 # 800080d8 <digits+0x98>
    80001126:	fffff097          	auipc	ra,0xfffff
    8000112a:	422080e7          	jalr	1058(ra) # 80000548 <panic>
    panic("kvmpa");
    8000112e:	00007517          	auipc	a0,0x7
    80001132:	faa50513          	addi	a0,a0,-86 # 800080d8 <digits+0x98>
    80001136:	fffff097          	auipc	ra,0xfffff
    8000113a:	412080e7          	jalr	1042(ra) # 80000548 <panic>

000000008000113e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000113e:	715d                	addi	sp,sp,-80
    80001140:	e486                	sd	ra,72(sp)
    80001142:	e0a2                	sd	s0,64(sp)
    80001144:	fc26                	sd	s1,56(sp)
    80001146:	f84a                	sd	s2,48(sp)
    80001148:	f44e                	sd	s3,40(sp)
    8000114a:	f052                	sd	s4,32(sp)
    8000114c:	ec56                	sd	s5,24(sp)
    8000114e:	e85a                	sd	s6,16(sp)
    80001150:	e45e                	sd	s7,8(sp)
    80001152:	0880                	addi	s0,sp,80
    80001154:	8aaa                	mv	s5,a0
    80001156:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001158:	777d                	lui	a4,0xfffff
    8000115a:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000115e:	167d                	addi	a2,a2,-1
    80001160:	00b609b3          	add	s3,a2,a1
    80001164:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001168:	893e                	mv	s2,a5
    8000116a:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000116e:	6b85                	lui	s7,0x1
    80001170:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001174:	4605                	li	a2,1
    80001176:	85ca                	mv	a1,s2
    80001178:	8556                	mv	a0,s5
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	e7e080e7          	jalr	-386(ra) # 80000ff8 <walk>
    80001182:	c51d                	beqz	a0,800011b0 <mappages+0x72>
    if(*pte & PTE_V)
    80001184:	611c                	ld	a5,0(a0)
    80001186:	8b85                	andi	a5,a5,1
    80001188:	ef81                	bnez	a5,800011a0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000118a:	80b1                	srli	s1,s1,0xc
    8000118c:	04aa                	slli	s1,s1,0xa
    8000118e:	0164e4b3          	or	s1,s1,s6
    80001192:	0014e493          	ori	s1,s1,1
    80001196:	e104                	sd	s1,0(a0)
    if(a == last)
    80001198:	03390863          	beq	s2,s3,800011c8 <mappages+0x8a>
    a += PGSIZE;
    8000119c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000119e:	bfc9                	j	80001170 <mappages+0x32>
      panic("remap");
    800011a0:	00007517          	auipc	a0,0x7
    800011a4:	f4050513          	addi	a0,a0,-192 # 800080e0 <digits+0xa0>
    800011a8:	fffff097          	auipc	ra,0xfffff
    800011ac:	3a0080e7          	jalr	928(ra) # 80000548 <panic>
      return -1;
    800011b0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011b2:	60a6                	ld	ra,72(sp)
    800011b4:	6406                	ld	s0,64(sp)
    800011b6:	74e2                	ld	s1,56(sp)
    800011b8:	7942                	ld	s2,48(sp)
    800011ba:	79a2                	ld	s3,40(sp)
    800011bc:	7a02                	ld	s4,32(sp)
    800011be:	6ae2                	ld	s5,24(sp)
    800011c0:	6b42                	ld	s6,16(sp)
    800011c2:	6ba2                	ld	s7,8(sp)
    800011c4:	6161                	addi	sp,sp,80
    800011c6:	8082                	ret
  return 0;
    800011c8:	4501                	li	a0,0
    800011ca:	b7e5                	j	800011b2 <mappages+0x74>

00000000800011cc <kvmmap>:
{
    800011cc:	1141                	addi	sp,sp,-16
    800011ce:	e406                	sd	ra,8(sp)
    800011d0:	e022                	sd	s0,0(sp)
    800011d2:	0800                	addi	s0,sp,16
    800011d4:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011d6:	86ae                	mv	a3,a1
    800011d8:	85aa                	mv	a1,a0
    800011da:	00008517          	auipc	a0,0x8
    800011de:	e3653503          	ld	a0,-458(a0) # 80009010 <kernel_pagetable>
    800011e2:	00000097          	auipc	ra,0x0
    800011e6:	f5c080e7          	jalr	-164(ra) # 8000113e <mappages>
    800011ea:	e509                	bnez	a0,800011f4 <kvmmap+0x28>
}
    800011ec:	60a2                	ld	ra,8(sp)
    800011ee:	6402                	ld	s0,0(sp)
    800011f0:	0141                	addi	sp,sp,16
    800011f2:	8082                	ret
    panic("kvmmap");
    800011f4:	00007517          	auipc	a0,0x7
    800011f8:	ef450513          	addi	a0,a0,-268 # 800080e8 <digits+0xa8>
    800011fc:	fffff097          	auipc	ra,0xfffff
    80001200:	34c080e7          	jalr	844(ra) # 80000548 <panic>

0000000080001204 <kvminit>:
{
    80001204:	1101                	addi	sp,sp,-32
    80001206:	ec06                	sd	ra,24(sp)
    80001208:	e822                	sd	s0,16(sp)
    8000120a:	e426                	sd	s1,8(sp)
    8000120c:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	912080e7          	jalr	-1774(ra) # 80000b20 <kalloc>
    80001216:	00008797          	auipc	a5,0x8
    8000121a:	dea7bd23          	sd	a0,-518(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000121e:	6605                	lui	a2,0x1
    80001220:	4581                	li	a1,0
    80001222:	00000097          	auipc	ra,0x0
    80001226:	aea080e7          	jalr	-1302(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000122a:	4699                	li	a3,6
    8000122c:	6605                	lui	a2,0x1
    8000122e:	100005b7          	lui	a1,0x10000
    80001232:	10000537          	lui	a0,0x10000
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f96080e7          	jalr	-106(ra) # 800011cc <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000123e:	4699                	li	a3,6
    80001240:	6605                	lui	a2,0x1
    80001242:	100015b7          	lui	a1,0x10001
    80001246:	10001537          	lui	a0,0x10001
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	f82080e7          	jalr	-126(ra) # 800011cc <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001252:	4699                	li	a3,6
    80001254:	6641                	lui	a2,0x10
    80001256:	020005b7          	lui	a1,0x2000
    8000125a:	02000537          	lui	a0,0x2000
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f6e080e7          	jalr	-146(ra) # 800011cc <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001266:	4699                	li	a3,6
    80001268:	00400637          	lui	a2,0x400
    8000126c:	0c0005b7          	lui	a1,0xc000
    80001270:	0c000537          	lui	a0,0xc000
    80001274:	00000097          	auipc	ra,0x0
    80001278:	f58080e7          	jalr	-168(ra) # 800011cc <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000127c:	00007497          	auipc	s1,0x7
    80001280:	d8448493          	addi	s1,s1,-636 # 80008000 <etext>
    80001284:	46a9                	li	a3,10
    80001286:	80007617          	auipc	a2,0x80007
    8000128a:	d7a60613          	addi	a2,a2,-646 # 8000 <_entry-0x7fff8000>
    8000128e:	4585                	li	a1,1
    80001290:	05fe                	slli	a1,a1,0x1f
    80001292:	852e                	mv	a0,a1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f38080e7          	jalr	-200(ra) # 800011cc <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	4645                	li	a2,17
    800012a0:	066e                	slli	a2,a2,0x1b
    800012a2:	8e05                	sub	a2,a2,s1
    800012a4:	85a6                	mv	a1,s1
    800012a6:	8526                	mv	a0,s1
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f24080e7          	jalr	-220(ra) # 800011cc <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012b0:	46a9                	li	a3,10
    800012b2:	6605                	lui	a2,0x1
    800012b4:	00006597          	auipc	a1,0x6
    800012b8:	d4c58593          	addi	a1,a1,-692 # 80007000 <_trampoline>
    800012bc:	04000537          	lui	a0,0x4000
    800012c0:	157d                	addi	a0,a0,-1
    800012c2:	0532                	slli	a0,a0,0xc
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f08080e7          	jalr	-248(ra) # 800011cc <kvmmap>
}
    800012cc:	60e2                	ld	ra,24(sp)
    800012ce:	6442                	ld	s0,16(sp)
    800012d0:	64a2                	ld	s1,8(sp)
    800012d2:	6105                	addi	sp,sp,32
    800012d4:	8082                	ret

00000000800012d6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012d6:	715d                	addi	sp,sp,-80
    800012d8:	e486                	sd	ra,72(sp)
    800012da:	e0a2                	sd	s0,64(sp)
    800012dc:	fc26                	sd	s1,56(sp)
    800012de:	f84a                	sd	s2,48(sp)
    800012e0:	f44e                	sd	s3,40(sp)
    800012e2:	f052                	sd	s4,32(sp)
    800012e4:	ec56                	sd	s5,24(sp)
    800012e6:	e85a                	sd	s6,16(sp)
    800012e8:	e45e                	sd	s7,8(sp)
    800012ea:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012ec:	03459793          	slli	a5,a1,0x34
    800012f0:	e795                	bnez	a5,8000131c <uvmunmap+0x46>
    800012f2:	8a2a                	mv	s4,a0
    800012f4:	892e                	mv	s2,a1
    800012f6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f8:	0632                	slli	a2,a2,0xc
    800012fa:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012fe:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001300:	6b05                	lui	s6,0x1
    80001302:	0735e863          	bltu	a1,s3,80001372 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001306:	60a6                	ld	ra,72(sp)
    80001308:	6406                	ld	s0,64(sp)
    8000130a:	74e2                	ld	s1,56(sp)
    8000130c:	7942                	ld	s2,48(sp)
    8000130e:	79a2                	ld	s3,40(sp)
    80001310:	7a02                	ld	s4,32(sp)
    80001312:	6ae2                	ld	s5,24(sp)
    80001314:	6b42                	ld	s6,16(sp)
    80001316:	6ba2                	ld	s7,8(sp)
    80001318:	6161                	addi	sp,sp,80
    8000131a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000131c:	00007517          	auipc	a0,0x7
    80001320:	dd450513          	addi	a0,a0,-556 # 800080f0 <digits+0xb0>
    80001324:	fffff097          	auipc	ra,0xfffff
    80001328:	224080e7          	jalr	548(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000132c:	00007517          	auipc	a0,0x7
    80001330:	ddc50513          	addi	a0,a0,-548 # 80008108 <digits+0xc8>
    80001334:	fffff097          	auipc	ra,0xfffff
    80001338:	214080e7          	jalr	532(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000133c:	00007517          	auipc	a0,0x7
    80001340:	ddc50513          	addi	a0,a0,-548 # 80008118 <digits+0xd8>
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	204080e7          	jalr	516(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000134c:	00007517          	auipc	a0,0x7
    80001350:	de450513          	addi	a0,a0,-540 # 80008130 <digits+0xf0>
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	1f4080e7          	jalr	500(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    8000135c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000135e:	0532                	slli	a0,a0,0xc
    80001360:	fffff097          	auipc	ra,0xfffff
    80001364:	6c4080e7          	jalr	1732(ra) # 80000a24 <kfree>
    *pte = 0;
    80001368:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000136c:	995a                	add	s2,s2,s6
    8000136e:	f9397ce3          	bgeu	s2,s3,80001306 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001372:	4601                	li	a2,0
    80001374:	85ca                	mv	a1,s2
    80001376:	8552                	mv	a0,s4
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	c80080e7          	jalr	-896(ra) # 80000ff8 <walk>
    80001380:	84aa                	mv	s1,a0
    80001382:	d54d                	beqz	a0,8000132c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001384:	6108                	ld	a0,0(a0)
    80001386:	00157793          	andi	a5,a0,1
    8000138a:	dbcd                	beqz	a5,8000133c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000138c:	3ff57793          	andi	a5,a0,1023
    80001390:	fb778ee3          	beq	a5,s7,8000134c <uvmunmap+0x76>
    if(do_free){
    80001394:	fc0a8ae3          	beqz	s5,80001368 <uvmunmap+0x92>
    80001398:	b7d1                	j	8000135c <uvmunmap+0x86>

000000008000139a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000139a:	1101                	addi	sp,sp,-32
    8000139c:	ec06                	sd	ra,24(sp)
    8000139e:	e822                	sd	s0,16(sp)
    800013a0:	e426                	sd	s1,8(sp)
    800013a2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	77c080e7          	jalr	1916(ra) # 80000b20 <kalloc>
    800013ac:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013ae:	c519                	beqz	a0,800013bc <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b0:	6605                	lui	a2,0x1
    800013b2:	4581                	li	a1,0
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	958080e7          	jalr	-1704(ra) # 80000d0c <memset>
  return pagetable;
}
    800013bc:	8526                	mv	a0,s1
    800013be:	60e2                	ld	ra,24(sp)
    800013c0:	6442                	ld	s0,16(sp)
    800013c2:	64a2                	ld	s1,8(sp)
    800013c4:	6105                	addi	sp,sp,32
    800013c6:	8082                	ret

00000000800013c8 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013c8:	7179                	addi	sp,sp,-48
    800013ca:	f406                	sd	ra,40(sp)
    800013cc:	f022                	sd	s0,32(sp)
    800013ce:	ec26                	sd	s1,24(sp)
    800013d0:	e84a                	sd	s2,16(sp)
    800013d2:	e44e                	sd	s3,8(sp)
    800013d4:	e052                	sd	s4,0(sp)
    800013d6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013d8:	6785                	lui	a5,0x1
    800013da:	04f67863          	bgeu	a2,a5,8000142a <uvminit+0x62>
    800013de:	8a2a                	mv	s4,a0
    800013e0:	89ae                	mv	s3,a1
    800013e2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	73c080e7          	jalr	1852(ra) # 80000b20 <kalloc>
    800013ec:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013ee:	6605                	lui	a2,0x1
    800013f0:	4581                	li	a1,0
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	91a080e7          	jalr	-1766(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013fa:	4779                	li	a4,30
    800013fc:	86ca                	mv	a3,s2
    800013fe:	6605                	lui	a2,0x1
    80001400:	4581                	li	a1,0
    80001402:	8552                	mv	a0,s4
    80001404:	00000097          	auipc	ra,0x0
    80001408:	d3a080e7          	jalr	-710(ra) # 8000113e <mappages>
  memmove(mem, src, sz);
    8000140c:	8626                	mv	a2,s1
    8000140e:	85ce                	mv	a1,s3
    80001410:	854a                	mv	a0,s2
    80001412:	00000097          	auipc	ra,0x0
    80001416:	95a080e7          	jalr	-1702(ra) # 80000d6c <memmove>
}
    8000141a:	70a2                	ld	ra,40(sp)
    8000141c:	7402                	ld	s0,32(sp)
    8000141e:	64e2                	ld	s1,24(sp)
    80001420:	6942                	ld	s2,16(sp)
    80001422:	69a2                	ld	s3,8(sp)
    80001424:	6a02                	ld	s4,0(sp)
    80001426:	6145                	addi	sp,sp,48
    80001428:	8082                	ret
    panic("inituvm: more than a page");
    8000142a:	00007517          	auipc	a0,0x7
    8000142e:	d1e50513          	addi	a0,a0,-738 # 80008148 <digits+0x108>
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	116080e7          	jalr	278(ra) # 80000548 <panic>

000000008000143a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000143a:	1101                	addi	sp,sp,-32
    8000143c:	ec06                	sd	ra,24(sp)
    8000143e:	e822                	sd	s0,16(sp)
    80001440:	e426                	sd	s1,8(sp)
    80001442:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001444:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001446:	00b67d63          	bgeu	a2,a1,80001460 <uvmdealloc+0x26>
    8000144a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000144c:	6785                	lui	a5,0x1
    8000144e:	17fd                	addi	a5,a5,-1
    80001450:	00f60733          	add	a4,a2,a5
    80001454:	767d                	lui	a2,0xfffff
    80001456:	8f71                	and	a4,a4,a2
    80001458:	97ae                	add	a5,a5,a1
    8000145a:	8ff1                	and	a5,a5,a2
    8000145c:	00f76863          	bltu	a4,a5,8000146c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001460:	8526                	mv	a0,s1
    80001462:	60e2                	ld	ra,24(sp)
    80001464:	6442                	ld	s0,16(sp)
    80001466:	64a2                	ld	s1,8(sp)
    80001468:	6105                	addi	sp,sp,32
    8000146a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000146c:	8f99                	sub	a5,a5,a4
    8000146e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001470:	4685                	li	a3,1
    80001472:	0007861b          	sext.w	a2,a5
    80001476:	85ba                	mv	a1,a4
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	e5e080e7          	jalr	-418(ra) # 800012d6 <uvmunmap>
    80001480:	b7c5                	j	80001460 <uvmdealloc+0x26>

0000000080001482 <uvmalloc>:
  if(newsz < oldsz)
    80001482:	0ab66163          	bltu	a2,a1,80001524 <uvmalloc+0xa2>
{
    80001486:	7139                	addi	sp,sp,-64
    80001488:	fc06                	sd	ra,56(sp)
    8000148a:	f822                	sd	s0,48(sp)
    8000148c:	f426                	sd	s1,40(sp)
    8000148e:	f04a                	sd	s2,32(sp)
    80001490:	ec4e                	sd	s3,24(sp)
    80001492:	e852                	sd	s4,16(sp)
    80001494:	e456                	sd	s5,8(sp)
    80001496:	0080                	addi	s0,sp,64
    80001498:	8aaa                	mv	s5,a0
    8000149a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000149c:	6985                	lui	s3,0x1
    8000149e:	19fd                	addi	s3,s3,-1
    800014a0:	95ce                	add	a1,a1,s3
    800014a2:	79fd                	lui	s3,0xfffff
    800014a4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a8:	08c9f063          	bgeu	s3,a2,80001528 <uvmalloc+0xa6>
    800014ac:	894e                	mv	s2,s3
    mem = kalloc();
    800014ae:	fffff097          	auipc	ra,0xfffff
    800014b2:	672080e7          	jalr	1650(ra) # 80000b20 <kalloc>
    800014b6:	84aa                	mv	s1,a0
    if(mem == 0){
    800014b8:	c51d                	beqz	a0,800014e6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014ba:	6605                	lui	a2,0x1
    800014bc:	4581                	li	a1,0
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	84e080e7          	jalr	-1970(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014c6:	4779                	li	a4,30
    800014c8:	86a6                	mv	a3,s1
    800014ca:	6605                	lui	a2,0x1
    800014cc:	85ca                	mv	a1,s2
    800014ce:	8556                	mv	a0,s5
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	c6e080e7          	jalr	-914(ra) # 8000113e <mappages>
    800014d8:	e905                	bnez	a0,80001508 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014da:	6785                	lui	a5,0x1
    800014dc:	993e                	add	s2,s2,a5
    800014de:	fd4968e3          	bltu	s2,s4,800014ae <uvmalloc+0x2c>
  return newsz;
    800014e2:	8552                	mv	a0,s4
    800014e4:	a809                	j	800014f6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014e6:	864e                	mv	a2,s3
    800014e8:	85ca                	mv	a1,s2
    800014ea:	8556                	mv	a0,s5
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	f4e080e7          	jalr	-178(ra) # 8000143a <uvmdealloc>
      return 0;
    800014f4:	4501                	li	a0,0
}
    800014f6:	70e2                	ld	ra,56(sp)
    800014f8:	7442                	ld	s0,48(sp)
    800014fa:	74a2                	ld	s1,40(sp)
    800014fc:	7902                	ld	s2,32(sp)
    800014fe:	69e2                	ld	s3,24(sp)
    80001500:	6a42                	ld	s4,16(sp)
    80001502:	6aa2                	ld	s5,8(sp)
    80001504:	6121                	addi	sp,sp,64
    80001506:	8082                	ret
      kfree(mem);
    80001508:	8526                	mv	a0,s1
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	51a080e7          	jalr	1306(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001512:	864e                	mv	a2,s3
    80001514:	85ca                	mv	a1,s2
    80001516:	8556                	mv	a0,s5
    80001518:	00000097          	auipc	ra,0x0
    8000151c:	f22080e7          	jalr	-222(ra) # 8000143a <uvmdealloc>
      return 0;
    80001520:	4501                	li	a0,0
    80001522:	bfd1                	j	800014f6 <uvmalloc+0x74>
    return oldsz;
    80001524:	852e                	mv	a0,a1
}
    80001526:	8082                	ret
  return newsz;
    80001528:	8532                	mv	a0,a2
    8000152a:	b7f1                	j	800014f6 <uvmalloc+0x74>

000000008000152c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000152c:	7179                	addi	sp,sp,-48
    8000152e:	f406                	sd	ra,40(sp)
    80001530:	f022                	sd	s0,32(sp)
    80001532:	ec26                	sd	s1,24(sp)
    80001534:	e84a                	sd	s2,16(sp)
    80001536:	e44e                	sd	s3,8(sp)
    80001538:	e052                	sd	s4,0(sp)
    8000153a:	1800                	addi	s0,sp,48
    8000153c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000153e:	84aa                	mv	s1,a0
    80001540:	6905                	lui	s2,0x1
    80001542:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001544:	4985                	li	s3,1
    80001546:	a821                	j	8000155e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001548:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000154a:	0532                	slli	a0,a0,0xc
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	fe0080e7          	jalr	-32(ra) # 8000152c <freewalk>
      pagetable[i] = 0;
    80001554:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001558:	04a1                	addi	s1,s1,8
    8000155a:	03248163          	beq	s1,s2,8000157c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000155e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001560:	00f57793          	andi	a5,a0,15
    80001564:	ff3782e3          	beq	a5,s3,80001548 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001568:	8905                	andi	a0,a0,1
    8000156a:	d57d                	beqz	a0,80001558 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000156c:	00007517          	auipc	a0,0x7
    80001570:	bfc50513          	addi	a0,a0,-1028 # 80008168 <digits+0x128>
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	fd4080e7          	jalr	-44(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000157c:	8552                	mv	a0,s4
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	4a6080e7          	jalr	1190(ra) # 80000a24 <kfree>
}
    80001586:	70a2                	ld	ra,40(sp)
    80001588:	7402                	ld	s0,32(sp)
    8000158a:	64e2                	ld	s1,24(sp)
    8000158c:	6942                	ld	s2,16(sp)
    8000158e:	69a2                	ld	s3,8(sp)
    80001590:	6a02                	ld	s4,0(sp)
    80001592:	6145                	addi	sp,sp,48
    80001594:	8082                	ret

0000000080001596 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001596:	1101                	addi	sp,sp,-32
    80001598:	ec06                	sd	ra,24(sp)
    8000159a:	e822                	sd	s0,16(sp)
    8000159c:	e426                	sd	s1,8(sp)
    8000159e:	1000                	addi	s0,sp,32
    800015a0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015a2:	e999                	bnez	a1,800015b8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015a4:	8526                	mv	a0,s1
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	f86080e7          	jalr	-122(ra) # 8000152c <freewalk>
}
    800015ae:	60e2                	ld	ra,24(sp)
    800015b0:	6442                	ld	s0,16(sp)
    800015b2:	64a2                	ld	s1,8(sp)
    800015b4:	6105                	addi	sp,sp,32
    800015b6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	167d                	addi	a2,a2,-1
    800015bc:	962e                	add	a2,a2,a1
    800015be:	4685                	li	a3,1
    800015c0:	8231                	srli	a2,a2,0xc
    800015c2:	4581                	li	a1,0
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	d12080e7          	jalr	-750(ra) # 800012d6 <uvmunmap>
    800015cc:	bfe1                	j	800015a4 <uvmfree+0xe>

00000000800015ce <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015ce:	c679                	beqz	a2,8000169c <uvmcopy+0xce>
{
    800015d0:	715d                	addi	sp,sp,-80
    800015d2:	e486                	sd	ra,72(sp)
    800015d4:	e0a2                	sd	s0,64(sp)
    800015d6:	fc26                	sd	s1,56(sp)
    800015d8:	f84a                	sd	s2,48(sp)
    800015da:	f44e                	sd	s3,40(sp)
    800015dc:	f052                	sd	s4,32(sp)
    800015de:	ec56                	sd	s5,24(sp)
    800015e0:	e85a                	sd	s6,16(sp)
    800015e2:	e45e                	sd	s7,8(sp)
    800015e4:	0880                	addi	s0,sp,80
    800015e6:	8b2a                	mv	s6,a0
    800015e8:	8aae                	mv	s5,a1
    800015ea:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015ec:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015ee:	4601                	li	a2,0
    800015f0:	85ce                	mv	a1,s3
    800015f2:	855a                	mv	a0,s6
    800015f4:	00000097          	auipc	ra,0x0
    800015f8:	a04080e7          	jalr	-1532(ra) # 80000ff8 <walk>
    800015fc:	c531                	beqz	a0,80001648 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015fe:	6118                	ld	a4,0(a0)
    80001600:	00177793          	andi	a5,a4,1
    80001604:	cbb1                	beqz	a5,80001658 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001606:	00a75593          	srli	a1,a4,0xa
    8000160a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000160e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	50e080e7          	jalr	1294(ra) # 80000b20 <kalloc>
    8000161a:	892a                	mv	s2,a0
    8000161c:	c939                	beqz	a0,80001672 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000161e:	6605                	lui	a2,0x1
    80001620:	85de                	mv	a1,s7
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	74a080e7          	jalr	1866(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000162a:	8726                	mv	a4,s1
    8000162c:	86ca                	mv	a3,s2
    8000162e:	6605                	lui	a2,0x1
    80001630:	85ce                	mv	a1,s3
    80001632:	8556                	mv	a0,s5
    80001634:	00000097          	auipc	ra,0x0
    80001638:	b0a080e7          	jalr	-1270(ra) # 8000113e <mappages>
    8000163c:	e515                	bnez	a0,80001668 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000163e:	6785                	lui	a5,0x1
    80001640:	99be                	add	s3,s3,a5
    80001642:	fb49e6e3          	bltu	s3,s4,800015ee <uvmcopy+0x20>
    80001646:	a081                	j	80001686 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001648:	00007517          	auipc	a0,0x7
    8000164c:	b3050513          	addi	a0,a0,-1232 # 80008178 <digits+0x138>
    80001650:	fffff097          	auipc	ra,0xfffff
    80001654:	ef8080e7          	jalr	-264(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b4050513          	addi	a0,a0,-1216 # 80008198 <digits+0x158>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ee8080e7          	jalr	-280(ra) # 80000548 <panic>
      kfree(mem);
    80001668:	854a                	mv	a0,s2
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	3ba080e7          	jalr	954(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001672:	4685                	li	a3,1
    80001674:	00c9d613          	srli	a2,s3,0xc
    80001678:	4581                	li	a1,0
    8000167a:	8556                	mv	a0,s5
    8000167c:	00000097          	auipc	ra,0x0
    80001680:	c5a080e7          	jalr	-934(ra) # 800012d6 <uvmunmap>
  return -1;
    80001684:	557d                	li	a0,-1
}
    80001686:	60a6                	ld	ra,72(sp)
    80001688:	6406                	ld	s0,64(sp)
    8000168a:	74e2                	ld	s1,56(sp)
    8000168c:	7942                	ld	s2,48(sp)
    8000168e:	79a2                	ld	s3,40(sp)
    80001690:	7a02                	ld	s4,32(sp)
    80001692:	6ae2                	ld	s5,24(sp)
    80001694:	6b42                	ld	s6,16(sp)
    80001696:	6ba2                	ld	s7,8(sp)
    80001698:	6161                	addi	sp,sp,80
    8000169a:	8082                	ret
  return 0;
    8000169c:	4501                	li	a0,0
}
    8000169e:	8082                	ret

00000000800016a0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016a0:	1141                	addi	sp,sp,-16
    800016a2:	e406                	sd	ra,8(sp)
    800016a4:	e022                	sd	s0,0(sp)
    800016a6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016a8:	4601                	li	a2,0
    800016aa:	00000097          	auipc	ra,0x0
    800016ae:	94e080e7          	jalr	-1714(ra) # 80000ff8 <walk>
  if(pte == 0)
    800016b2:	c901                	beqz	a0,800016c2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016b4:	611c                	ld	a5,0(a0)
    800016b6:	9bbd                	andi	a5,a5,-17
    800016b8:	e11c                	sd	a5,0(a0)
}
    800016ba:	60a2                	ld	ra,8(sp)
    800016bc:	6402                	ld	s0,0(sp)
    800016be:	0141                	addi	sp,sp,16
    800016c0:	8082                	ret
    panic("uvmclear");
    800016c2:	00007517          	auipc	a0,0x7
    800016c6:	af650513          	addi	a0,a0,-1290 # 800081b8 <digits+0x178>
    800016ca:	fffff097          	auipc	ra,0xfffff
    800016ce:	e7e080e7          	jalr	-386(ra) # 80000548 <panic>

00000000800016d2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016d2:	c6bd                	beqz	a3,80001740 <copyout+0x6e>
{
    800016d4:	715d                	addi	sp,sp,-80
    800016d6:	e486                	sd	ra,72(sp)
    800016d8:	e0a2                	sd	s0,64(sp)
    800016da:	fc26                	sd	s1,56(sp)
    800016dc:	f84a                	sd	s2,48(sp)
    800016de:	f44e                	sd	s3,40(sp)
    800016e0:	f052                	sd	s4,32(sp)
    800016e2:	ec56                	sd	s5,24(sp)
    800016e4:	e85a                	sd	s6,16(sp)
    800016e6:	e45e                	sd	s7,8(sp)
    800016e8:	e062                	sd	s8,0(sp)
    800016ea:	0880                	addi	s0,sp,80
    800016ec:	8b2a                	mv	s6,a0
    800016ee:	8c2e                	mv	s8,a1
    800016f0:	8a32                	mv	s4,a2
    800016f2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016f4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016f6:	6a85                	lui	s5,0x1
    800016f8:	a015                	j	8000171c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016fa:	9562                	add	a0,a0,s8
    800016fc:	0004861b          	sext.w	a2,s1
    80001700:	85d2                	mv	a1,s4
    80001702:	41250533          	sub	a0,a0,s2
    80001706:	fffff097          	auipc	ra,0xfffff
    8000170a:	666080e7          	jalr	1638(ra) # 80000d6c <memmove>

    len -= n;
    8000170e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001712:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001714:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001718:	02098263          	beqz	s3,8000173c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000171c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001720:	85ca                	mv	a1,s2
    80001722:	855a                	mv	a0,s6
    80001724:	00000097          	auipc	ra,0x0
    80001728:	97a080e7          	jalr	-1670(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    8000172c:	cd01                	beqz	a0,80001744 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000172e:	418904b3          	sub	s1,s2,s8
    80001732:	94d6                	add	s1,s1,s5
    if(n > len)
    80001734:	fc99f3e3          	bgeu	s3,s1,800016fa <copyout+0x28>
    80001738:	84ce                	mv	s1,s3
    8000173a:	b7c1                	j	800016fa <copyout+0x28>
  }
  return 0;
    8000173c:	4501                	li	a0,0
    8000173e:	a021                	j	80001746 <copyout+0x74>
    80001740:	4501                	li	a0,0
}
    80001742:	8082                	ret
      return -1;
    80001744:	557d                	li	a0,-1
}
    80001746:	60a6                	ld	ra,72(sp)
    80001748:	6406                	ld	s0,64(sp)
    8000174a:	74e2                	ld	s1,56(sp)
    8000174c:	7942                	ld	s2,48(sp)
    8000174e:	79a2                	ld	s3,40(sp)
    80001750:	7a02                	ld	s4,32(sp)
    80001752:	6ae2                	ld	s5,24(sp)
    80001754:	6b42                	ld	s6,16(sp)
    80001756:	6ba2                	ld	s7,8(sp)
    80001758:	6c02                	ld	s8,0(sp)
    8000175a:	6161                	addi	sp,sp,80
    8000175c:	8082                	ret

000000008000175e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000175e:	c6bd                	beqz	a3,800017cc <copyin+0x6e>
{
    80001760:	715d                	addi	sp,sp,-80
    80001762:	e486                	sd	ra,72(sp)
    80001764:	e0a2                	sd	s0,64(sp)
    80001766:	fc26                	sd	s1,56(sp)
    80001768:	f84a                	sd	s2,48(sp)
    8000176a:	f44e                	sd	s3,40(sp)
    8000176c:	f052                	sd	s4,32(sp)
    8000176e:	ec56                	sd	s5,24(sp)
    80001770:	e85a                	sd	s6,16(sp)
    80001772:	e45e                	sd	s7,8(sp)
    80001774:	e062                	sd	s8,0(sp)
    80001776:	0880                	addi	s0,sp,80
    80001778:	8b2a                	mv	s6,a0
    8000177a:	8a2e                	mv	s4,a1
    8000177c:	8c32                	mv	s8,a2
    8000177e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001780:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001782:	6a85                	lui	s5,0x1
    80001784:	a015                	j	800017a8 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001786:	9562                	add	a0,a0,s8
    80001788:	0004861b          	sext.w	a2,s1
    8000178c:	412505b3          	sub	a1,a0,s2
    80001790:	8552                	mv	a0,s4
    80001792:	fffff097          	auipc	ra,0xfffff
    80001796:	5da080e7          	jalr	1498(ra) # 80000d6c <memmove>

    len -= n;
    8000179a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000179e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017a0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017a4:	02098263          	beqz	s3,800017c8 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017a8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017ac:	85ca                	mv	a1,s2
    800017ae:	855a                	mv	a0,s6
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	8ee080e7          	jalr	-1810(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    800017b8:	cd01                	beqz	a0,800017d0 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800017ba:	418904b3          	sub	s1,s2,s8
    800017be:	94d6                	add	s1,s1,s5
    if(n > len)
    800017c0:	fc99f3e3          	bgeu	s3,s1,80001786 <copyin+0x28>
    800017c4:	84ce                	mv	s1,s3
    800017c6:	b7c1                	j	80001786 <copyin+0x28>
  }
  return 0;
    800017c8:	4501                	li	a0,0
    800017ca:	a021                	j	800017d2 <copyin+0x74>
    800017cc:	4501                	li	a0,0
}
    800017ce:	8082                	ret
      return -1;
    800017d0:	557d                	li	a0,-1
}
    800017d2:	60a6                	ld	ra,72(sp)
    800017d4:	6406                	ld	s0,64(sp)
    800017d6:	74e2                	ld	s1,56(sp)
    800017d8:	7942                	ld	s2,48(sp)
    800017da:	79a2                	ld	s3,40(sp)
    800017dc:	7a02                	ld	s4,32(sp)
    800017de:	6ae2                	ld	s5,24(sp)
    800017e0:	6b42                	ld	s6,16(sp)
    800017e2:	6ba2                	ld	s7,8(sp)
    800017e4:	6c02                	ld	s8,0(sp)
    800017e6:	6161                	addi	sp,sp,80
    800017e8:	8082                	ret

00000000800017ea <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017ea:	c6c5                	beqz	a3,80001892 <copyinstr+0xa8>
{
    800017ec:	715d                	addi	sp,sp,-80
    800017ee:	e486                	sd	ra,72(sp)
    800017f0:	e0a2                	sd	s0,64(sp)
    800017f2:	fc26                	sd	s1,56(sp)
    800017f4:	f84a                	sd	s2,48(sp)
    800017f6:	f44e                	sd	s3,40(sp)
    800017f8:	f052                	sd	s4,32(sp)
    800017fa:	ec56                	sd	s5,24(sp)
    800017fc:	e85a                	sd	s6,16(sp)
    800017fe:	e45e                	sd	s7,8(sp)
    80001800:	0880                	addi	s0,sp,80
    80001802:	8a2a                	mv	s4,a0
    80001804:	8b2e                	mv	s6,a1
    80001806:	8bb2                	mv	s7,a2
    80001808:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000180a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000180c:	6985                	lui	s3,0x1
    8000180e:	a035                	j	8000183a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001810:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001814:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001816:	0017b793          	seqz	a5,a5
    8000181a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000181e:	60a6                	ld	ra,72(sp)
    80001820:	6406                	ld	s0,64(sp)
    80001822:	74e2                	ld	s1,56(sp)
    80001824:	7942                	ld	s2,48(sp)
    80001826:	79a2                	ld	s3,40(sp)
    80001828:	7a02                	ld	s4,32(sp)
    8000182a:	6ae2                	ld	s5,24(sp)
    8000182c:	6b42                	ld	s6,16(sp)
    8000182e:	6ba2                	ld	s7,8(sp)
    80001830:	6161                	addi	sp,sp,80
    80001832:	8082                	ret
    srcva = va0 + PGSIZE;
    80001834:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001838:	c8a9                	beqz	s1,8000188a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000183a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000183e:	85ca                	mv	a1,s2
    80001840:	8552                	mv	a0,s4
    80001842:	00000097          	auipc	ra,0x0
    80001846:	85c080e7          	jalr	-1956(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    8000184a:	c131                	beqz	a0,8000188e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000184c:	41790833          	sub	a6,s2,s7
    80001850:	984e                	add	a6,a6,s3
    if(n > max)
    80001852:	0104f363          	bgeu	s1,a6,80001858 <copyinstr+0x6e>
    80001856:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001858:	955e                	add	a0,a0,s7
    8000185a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000185e:	fc080be3          	beqz	a6,80001834 <copyinstr+0x4a>
    80001862:	985a                	add	a6,a6,s6
    80001864:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001866:	41650633          	sub	a2,a0,s6
    8000186a:	14fd                	addi	s1,s1,-1
    8000186c:	9b26                	add	s6,s6,s1
    8000186e:	00f60733          	add	a4,a2,a5
    80001872:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001876:	df49                	beqz	a4,80001810 <copyinstr+0x26>
        *dst = *p;
    80001878:	00e78023          	sb	a4,0(a5)
      --max;
    8000187c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001880:	0785                	addi	a5,a5,1
    while(n > 0){
    80001882:	ff0796e3          	bne	a5,a6,8000186e <copyinstr+0x84>
      dst++;
    80001886:	8b42                	mv	s6,a6
    80001888:	b775                	j	80001834 <copyinstr+0x4a>
    8000188a:	4781                	li	a5,0
    8000188c:	b769                	j	80001816 <copyinstr+0x2c>
      return -1;
    8000188e:	557d                	li	a0,-1
    80001890:	b779                	j	8000181e <copyinstr+0x34>
  int got_null = 0;
    80001892:	4781                	li	a5,0
  if(got_null){
    80001894:	0017b793          	seqz	a5,a5
    80001898:	40f00533          	neg	a0,a5
}
    8000189c:	8082                	ret

000000008000189e <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000189e:	1101                	addi	sp,sp,-32
    800018a0:	ec06                	sd	ra,24(sp)
    800018a2:	e822                	sd	s0,16(sp)
    800018a4:	e426                	sd	s1,8(sp)
    800018a6:	1000                	addi	s0,sp,32
    800018a8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018aa:	fffff097          	auipc	ra,0xfffff
    800018ae:	2ec080e7          	jalr	748(ra) # 80000b96 <holding>
    800018b2:	c909                	beqz	a0,800018c4 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018b4:	749c                	ld	a5,40(s1)
    800018b6:	00978f63          	beq	a5,s1,800018d4 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018ba:	60e2                	ld	ra,24(sp)
    800018bc:	6442                	ld	s0,16(sp)
    800018be:	64a2                	ld	s1,8(sp)
    800018c0:	6105                	addi	sp,sp,32
    800018c2:	8082                	ret
    panic("wakeup1");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	90450513          	addi	a0,a0,-1788 # 800081c8 <digits+0x188>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c7c080e7          	jalr	-900(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018d4:	4c98                	lw	a4,24(s1)
    800018d6:	4785                	li	a5,1
    800018d8:	fef711e3          	bne	a4,a5,800018ba <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018dc:	4789                	li	a5,2
    800018de:	cc9c                	sw	a5,24(s1)
}
    800018e0:	bfe9                	j	800018ba <wakeup1+0x1c>

00000000800018e2 <procinit>:
{
    800018e2:	715d                	addi	sp,sp,-80
    800018e4:	e486                	sd	ra,72(sp)
    800018e6:	e0a2                	sd	s0,64(sp)
    800018e8:	fc26                	sd	s1,56(sp)
    800018ea:	f84a                	sd	s2,48(sp)
    800018ec:	f44e                	sd	s3,40(sp)
    800018ee:	f052                	sd	s4,32(sp)
    800018f0:	ec56                	sd	s5,24(sp)
    800018f2:	e85a                	sd	s6,16(sp)
    800018f4:	e45e                	sd	s7,8(sp)
    800018f6:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8d858593          	addi	a1,a1,-1832 # 800081d0 <digits+0x190>
    80001900:	00010517          	auipc	a0,0x10
    80001904:	05050513          	addi	a0,a0,80 # 80011950 <pid_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	278080e7          	jalr	632(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	00010917          	auipc	s2,0x10
    80001914:	45890913          	addi	s2,s2,1112 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b97          	auipc	s7,0x7
    8000191c:	8c0b8b93          	addi	s7,s7,-1856 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001920:	8b4a                	mv	s6,s2
    80001922:	00006a97          	auipc	s5,0x6
    80001926:	6dea8a93          	addi	s5,s5,1758 # 80008000 <etext>
    8000192a:	040009b7          	lui	s3,0x4000
    8000192e:	19fd                	addi	s3,s3,-1
    80001930:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00016a17          	auipc	s4,0x16
    80001936:	036a0a13          	addi	s4,s4,54 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85de                	mv	a1,s7
    8000193c:	854a                	mv	a0,s2
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	242080e7          	jalr	578(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	1da080e7          	jalr	474(ra) # 80000b20 <kalloc>
    8000194e:	85aa                	mv	a1,a0
      if(pa == 0)
    80001950:	c929                	beqz	a0,800019a2 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001952:	416904b3          	sub	s1,s2,s6
    80001956:	8491                	srai	s1,s1,0x4
    80001958:	000ab783          	ld	a5,0(s5)
    8000195c:	02f484b3          	mul	s1,s1,a5
    80001960:	2485                	addiw	s1,s1,1
    80001962:	00d4949b          	slliw	s1,s1,0xd
    80001966:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000196a:	4699                	li	a3,6
    8000196c:	6605                	lui	a2,0x1
    8000196e:	8526                	mv	a0,s1
    80001970:	00000097          	auipc	ra,0x0
    80001974:	85c080e7          	jalr	-1956(ra) # 800011cc <kvmmap>
      p->kstack = va;
    80001978:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	17090913          	addi	s2,s2,368
    80001980:	fb491de3          	bne	s2,s4,8000193a <procinit+0x58>
  kvminithart();
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	650080e7          	jalr	1616(ra) # 80000fd4 <kvminithart>
}
    8000198c:	60a6                	ld	ra,72(sp)
    8000198e:	6406                	ld	s0,64(sp)
    80001990:	74e2                	ld	s1,56(sp)
    80001992:	7942                	ld	s2,48(sp)
    80001994:	79a2                	ld	s3,40(sp)
    80001996:	7a02                	ld	s4,32(sp)
    80001998:	6ae2                	ld	s5,24(sp)
    8000199a:	6b42                	ld	s6,16(sp)
    8000199c:	6ba2                	ld	s7,8(sp)
    8000199e:	6161                	addi	sp,sp,80
    800019a0:	8082                	ret
        panic("kalloc");
    800019a2:	00007517          	auipc	a0,0x7
    800019a6:	83e50513          	addi	a0,a0,-1986 # 800081e0 <digits+0x1a0>
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	b9e080e7          	jalr	-1122(ra) # 80000548 <panic>

00000000800019b2 <cpuid>:
{
    800019b2:	1141                	addi	sp,sp,-16
    800019b4:	e422                	sd	s0,8(sp)
    800019b6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019b8:	8512                	mv	a0,tp
}
    800019ba:	2501                	sext.w	a0,a0
    800019bc:	6422                	ld	s0,8(sp)
    800019be:	0141                	addi	sp,sp,16
    800019c0:	8082                	ret

00000000800019c2 <mycpu>:
mycpu(void) {
    800019c2:	1141                	addi	sp,sp,-16
    800019c4:	e422                	sd	s0,8(sp)
    800019c6:	0800                	addi	s0,sp,16
    800019c8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019ca:	2781                	sext.w	a5,a5
    800019cc:	079e                	slli	a5,a5,0x7
}
    800019ce:	00010517          	auipc	a0,0x10
    800019d2:	f9a50513          	addi	a0,a0,-102 # 80011968 <cpus>
    800019d6:	953e                	add	a0,a0,a5
    800019d8:	6422                	ld	s0,8(sp)
    800019da:	0141                	addi	sp,sp,16
    800019dc:	8082                	ret

00000000800019de <myproc>:
myproc(void) {
    800019de:	1101                	addi	sp,sp,-32
    800019e0:	ec06                	sd	ra,24(sp)
    800019e2:	e822                	sd	s0,16(sp)
    800019e4:	e426                	sd	s1,8(sp)
    800019e6:	1000                	addi	s0,sp,32
  push_off();
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	1dc080e7          	jalr	476(ra) # 80000bc4 <push_off>
    800019f0:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019f2:	2781                	sext.w	a5,a5
    800019f4:	079e                	slli	a5,a5,0x7
    800019f6:	00010717          	auipc	a4,0x10
    800019fa:	f5a70713          	addi	a4,a4,-166 # 80011950 <pid_lock>
    800019fe:	97ba                	add	a5,a5,a4
    80001a00:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a02:	fffff097          	auipc	ra,0xfffff
    80001a06:	262080e7          	jalr	610(ra) # 80000c64 <pop_off>
}
    80001a0a:	8526                	mv	a0,s1
    80001a0c:	60e2                	ld	ra,24(sp)
    80001a0e:	6442                	ld	s0,16(sp)
    80001a10:	64a2                	ld	s1,8(sp)
    80001a12:	6105                	addi	sp,sp,32
    80001a14:	8082                	ret

0000000080001a16 <forkret>:
{
    80001a16:	1141                	addi	sp,sp,-16
    80001a18:	e406                	sd	ra,8(sp)
    80001a1a:	e022                	sd	s0,0(sp)
    80001a1c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a1e:	00000097          	auipc	ra,0x0
    80001a22:	fc0080e7          	jalr	-64(ra) # 800019de <myproc>
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	29e080e7          	jalr	670(ra) # 80000cc4 <release>
  if (first) {
    80001a2e:	00007797          	auipc	a5,0x7
    80001a32:	f627a783          	lw	a5,-158(a5) # 80008990 <first.1663>
    80001a36:	eb89                	bnez	a5,80001a48 <forkret+0x32>
  usertrapret();
    80001a38:	00001097          	auipc	ra,0x1
    80001a3c:	c20080e7          	jalr	-992(ra) # 80002658 <usertrapret>
}
    80001a40:	60a2                	ld	ra,8(sp)
    80001a42:	6402                	ld	s0,0(sp)
    80001a44:	0141                	addi	sp,sp,16
    80001a46:	8082                	ret
    first = 0;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	f407a423          	sw	zero,-184(a5) # 80008990 <first.1663>
    fsinit(ROOTDEV);
    80001a50:	4505                	li	a0,1
    80001a52:	00002097          	auipc	ra,0x2
    80001a56:	9a8080e7          	jalr	-1624(ra) # 800033fa <fsinit>
    80001a5a:	bff9                	j	80001a38 <forkret+0x22>

0000000080001a5c <allocpid>:
allocpid() {
    80001a5c:	1101                	addi	sp,sp,-32
    80001a5e:	ec06                	sd	ra,24(sp)
    80001a60:	e822                	sd	s0,16(sp)
    80001a62:	e426                	sd	s1,8(sp)
    80001a64:	e04a                	sd	s2,0(sp)
    80001a66:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a68:	00010917          	auipc	s2,0x10
    80001a6c:	ee890913          	addi	s2,s2,-280 # 80011950 <pid_lock>
    80001a70:	854a                	mv	a0,s2
    80001a72:	fffff097          	auipc	ra,0xfffff
    80001a76:	19e080e7          	jalr	414(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001a7a:	00007797          	auipc	a5,0x7
    80001a7e:	f1a78793          	addi	a5,a5,-230 # 80008994 <nextpid>
    80001a82:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a84:	0014871b          	addiw	a4,s1,1
    80001a88:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a8a:	854a                	mv	a0,s2
    80001a8c:	fffff097          	auipc	ra,0xfffff
    80001a90:	238080e7          	jalr	568(ra) # 80000cc4 <release>
}
    80001a94:	8526                	mv	a0,s1
    80001a96:	60e2                	ld	ra,24(sp)
    80001a98:	6442                	ld	s0,16(sp)
    80001a9a:	64a2                	ld	s1,8(sp)
    80001a9c:	6902                	ld	s2,0(sp)
    80001a9e:	6105                	addi	sp,sp,32
    80001aa0:	8082                	ret

0000000080001aa2 <proc_pagetable>:
{
    80001aa2:	1101                	addi	sp,sp,-32
    80001aa4:	ec06                	sd	ra,24(sp)
    80001aa6:	e822                	sd	s0,16(sp)
    80001aa8:	e426                	sd	s1,8(sp)
    80001aaa:	e04a                	sd	s2,0(sp)
    80001aac:	1000                	addi	s0,sp,32
    80001aae:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ab0:	00000097          	auipc	ra,0x0
    80001ab4:	8ea080e7          	jalr	-1814(ra) # 8000139a <uvmcreate>
    80001ab8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aba:	c121                	beqz	a0,80001afa <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001abc:	4729                	li	a4,10
    80001abe:	00005697          	auipc	a3,0x5
    80001ac2:	54268693          	addi	a3,a3,1346 # 80007000 <_trampoline>
    80001ac6:	6605                	lui	a2,0x1
    80001ac8:	040005b7          	lui	a1,0x4000
    80001acc:	15fd                	addi	a1,a1,-1
    80001ace:	05b2                	slli	a1,a1,0xc
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	66e080e7          	jalr	1646(ra) # 8000113e <mappages>
    80001ad8:	02054863          	bltz	a0,80001b08 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001adc:	4719                	li	a4,6
    80001ade:	05893683          	ld	a3,88(s2)
    80001ae2:	6605                	lui	a2,0x1
    80001ae4:	020005b7          	lui	a1,0x2000
    80001ae8:	15fd                	addi	a1,a1,-1
    80001aea:	05b6                	slli	a1,a1,0xd
    80001aec:	8526                	mv	a0,s1
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	650080e7          	jalr	1616(ra) # 8000113e <mappages>
    80001af6:	02054163          	bltz	a0,80001b18 <proc_pagetable+0x76>
}
    80001afa:	8526                	mv	a0,s1
    80001afc:	60e2                	ld	ra,24(sp)
    80001afe:	6442                	ld	s0,16(sp)
    80001b00:	64a2                	ld	s1,8(sp)
    80001b02:	6902                	ld	s2,0(sp)
    80001b04:	6105                	addi	sp,sp,32
    80001b06:	8082                	ret
    uvmfree(pagetable, 0);
    80001b08:	4581                	li	a1,0
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	00000097          	auipc	ra,0x0
    80001b10:	a8a080e7          	jalr	-1398(ra) # 80001596 <uvmfree>
    return 0;
    80001b14:	4481                	li	s1,0
    80001b16:	b7d5                	j	80001afa <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b18:	4681                	li	a3,0
    80001b1a:	4605                	li	a2,1
    80001b1c:	040005b7          	lui	a1,0x4000
    80001b20:	15fd                	addi	a1,a1,-1
    80001b22:	05b2                	slli	a1,a1,0xc
    80001b24:	8526                	mv	a0,s1
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	7b0080e7          	jalr	1968(ra) # 800012d6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b2e:	4581                	li	a1,0
    80001b30:	8526                	mv	a0,s1
    80001b32:	00000097          	auipc	ra,0x0
    80001b36:	a64080e7          	jalr	-1436(ra) # 80001596 <uvmfree>
    return 0;
    80001b3a:	4481                	li	s1,0
    80001b3c:	bf7d                	j	80001afa <proc_pagetable+0x58>

0000000080001b3e <proc_freepagetable>:
{
    80001b3e:	1101                	addi	sp,sp,-32
    80001b40:	ec06                	sd	ra,24(sp)
    80001b42:	e822                	sd	s0,16(sp)
    80001b44:	e426                	sd	s1,8(sp)
    80001b46:	e04a                	sd	s2,0(sp)
    80001b48:	1000                	addi	s0,sp,32
    80001b4a:	84aa                	mv	s1,a0
    80001b4c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b4e:	4681                	li	a3,0
    80001b50:	4605                	li	a2,1
    80001b52:	040005b7          	lui	a1,0x4000
    80001b56:	15fd                	addi	a1,a1,-1
    80001b58:	05b2                	slli	a1,a1,0xc
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	77c080e7          	jalr	1916(ra) # 800012d6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b62:	4681                	li	a3,0
    80001b64:	4605                	li	a2,1
    80001b66:	020005b7          	lui	a1,0x2000
    80001b6a:	15fd                	addi	a1,a1,-1
    80001b6c:	05b6                	slli	a1,a1,0xd
    80001b6e:	8526                	mv	a0,s1
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	766080e7          	jalr	1894(ra) # 800012d6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b78:	85ca                	mv	a1,s2
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	00000097          	auipc	ra,0x0
    80001b80:	a1a080e7          	jalr	-1510(ra) # 80001596 <uvmfree>
}
    80001b84:	60e2                	ld	ra,24(sp)
    80001b86:	6442                	ld	s0,16(sp)
    80001b88:	64a2                	ld	s1,8(sp)
    80001b8a:	6902                	ld	s2,0(sp)
    80001b8c:	6105                	addi	sp,sp,32
    80001b8e:	8082                	ret

0000000080001b90 <freeproc>:
{
    80001b90:	1101                	addi	sp,sp,-32
    80001b92:	ec06                	sd	ra,24(sp)
    80001b94:	e822                	sd	s0,16(sp)
    80001b96:	e426                	sd	s1,8(sp)
    80001b98:	1000                	addi	s0,sp,32
    80001b9a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b9c:	6d28                	ld	a0,88(a0)
    80001b9e:	c509                	beqz	a0,80001ba8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	e84080e7          	jalr	-380(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001ba8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bac:	68a8                	ld	a0,80(s1)
    80001bae:	c511                	beqz	a0,80001bba <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bb0:	64ac                	ld	a1,72(s1)
    80001bb2:	00000097          	auipc	ra,0x0
    80001bb6:	f8c080e7          	jalr	-116(ra) # 80001b3e <proc_freepagetable>
  p->pagetable = 0;
    80001bba:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bbe:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bc2:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bc6:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bca:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bce:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bd2:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bd6:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bda:	0004ac23          	sw	zero,24(s1)
}
    80001bde:	60e2                	ld	ra,24(sp)
    80001be0:	6442                	ld	s0,16(sp)
    80001be2:	64a2                	ld	s1,8(sp)
    80001be4:	6105                	addi	sp,sp,32
    80001be6:	8082                	ret

0000000080001be8 <allocproc>:
{
    80001be8:	1101                	addi	sp,sp,-32
    80001bea:	ec06                	sd	ra,24(sp)
    80001bec:	e822                	sd	s0,16(sp)
    80001bee:	e426                	sd	s1,8(sp)
    80001bf0:	e04a                	sd	s2,0(sp)
    80001bf2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf4:	00010497          	auipc	s1,0x10
    80001bf8:	17448493          	addi	s1,s1,372 # 80011d68 <proc>
    80001bfc:	00016917          	auipc	s2,0x16
    80001c00:	d6c90913          	addi	s2,s2,-660 # 80017968 <tickslock>
    acquire(&p->lock);
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	00a080e7          	jalr	10(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001c0e:	4c9c                	lw	a5,24(s1)
    80001c10:	cf81                	beqz	a5,80001c28 <allocproc+0x40>
      release(&p->lock);
    80001c12:	8526                	mv	a0,s1
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	0b0080e7          	jalr	176(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c1c:	17048493          	addi	s1,s1,368
    80001c20:	ff2492e3          	bne	s1,s2,80001c04 <allocproc+0x1c>
  return 0;
    80001c24:	4481                	li	s1,0
    80001c26:	a0b9                	j	80001c74 <allocproc+0x8c>
  p->pid = allocpid();
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	e34080e7          	jalr	-460(ra) # 80001a5c <allocpid>
    80001c30:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	eee080e7          	jalr	-274(ra) # 80000b20 <kalloc>
    80001c3a:	892a                	mv	s2,a0
    80001c3c:	eca8                	sd	a0,88(s1)
    80001c3e:	c131                	beqz	a0,80001c82 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c40:	8526                	mv	a0,s1
    80001c42:	00000097          	auipc	ra,0x0
    80001c46:	e60080e7          	jalr	-416(ra) # 80001aa2 <proc_pagetable>
    80001c4a:	892a                	mv	s2,a0
    80001c4c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c4e:	c129                	beqz	a0,80001c90 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c50:	07000613          	li	a2,112
    80001c54:	4581                	li	a1,0
    80001c56:	06048513          	addi	a0,s1,96
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	0b2080e7          	jalr	178(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001c62:	00000797          	auipc	a5,0x0
    80001c66:	db478793          	addi	a5,a5,-588 # 80001a16 <forkret>
    80001c6a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c6c:	60bc                	ld	a5,64(s1)
    80001c6e:	6705                	lui	a4,0x1
    80001c70:	97ba                	add	a5,a5,a4
    80001c72:	f4bc                	sd	a5,104(s1)
}
    80001c74:	8526                	mv	a0,s1
    80001c76:	60e2                	ld	ra,24(sp)
    80001c78:	6442                	ld	s0,16(sp)
    80001c7a:	64a2                	ld	s1,8(sp)
    80001c7c:	6902                	ld	s2,0(sp)
    80001c7e:	6105                	addi	sp,sp,32
    80001c80:	8082                	ret
    release(&p->lock);
    80001c82:	8526                	mv	a0,s1
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	040080e7          	jalr	64(ra) # 80000cc4 <release>
    return 0;
    80001c8c:	84ca                	mv	s1,s2
    80001c8e:	b7dd                	j	80001c74 <allocproc+0x8c>
    freeproc(p);
    80001c90:	8526                	mv	a0,s1
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	efe080e7          	jalr	-258(ra) # 80001b90 <freeproc>
    release(&p->lock);
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	028080e7          	jalr	40(ra) # 80000cc4 <release>
    return 0;
    80001ca4:	84ca                	mv	s1,s2
    80001ca6:	b7f9                	j	80001c74 <allocproc+0x8c>

0000000080001ca8 <userinit>:
{
    80001ca8:	1101                	addi	sp,sp,-32
    80001caa:	ec06                	sd	ra,24(sp)
    80001cac:	e822                	sd	s0,16(sp)
    80001cae:	e426                	sd	s1,8(sp)
    80001cb0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	f36080e7          	jalr	-202(ra) # 80001be8 <allocproc>
    80001cba:	84aa                	mv	s1,a0
  initproc = p;
    80001cbc:	00007797          	auipc	a5,0x7
    80001cc0:	34a7be23          	sd	a0,860(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc4:	03400613          	li	a2,52
    80001cc8:	00007597          	auipc	a1,0x7
    80001ccc:	cd858593          	addi	a1,a1,-808 # 800089a0 <initcode>
    80001cd0:	6928                	ld	a0,80(a0)
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	6f6080e7          	jalr	1782(ra) # 800013c8 <uvminit>
  p->sz = PGSIZE;
    80001cda:	6785                	lui	a5,0x1
    80001cdc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cde:	6cb8                	ld	a4,88(s1)
    80001ce0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ce4:	6cb8                	ld	a4,88(s1)
    80001ce6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ce8:	4641                	li	a2,16
    80001cea:	00006597          	auipc	a1,0x6
    80001cee:	4fe58593          	addi	a1,a1,1278 # 800081e8 <digits+0x1a8>
    80001cf2:	15848513          	addi	a0,s1,344
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	16c080e7          	jalr	364(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001cfe:	00006517          	auipc	a0,0x6
    80001d02:	4fa50513          	addi	a0,a0,1274 # 800081f8 <digits+0x1b8>
    80001d06:	00002097          	auipc	ra,0x2
    80001d0a:	11c080e7          	jalr	284(ra) # 80003e22 <namei>
    80001d0e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d12:	4789                	li	a5,2
    80001d14:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d16:	8526                	mv	a0,s1
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	fac080e7          	jalr	-84(ra) # 80000cc4 <release>
}
    80001d20:	60e2                	ld	ra,24(sp)
    80001d22:	6442                	ld	s0,16(sp)
    80001d24:	64a2                	ld	s1,8(sp)
    80001d26:	6105                	addi	sp,sp,32
    80001d28:	8082                	ret

0000000080001d2a <growproc>:
{
    80001d2a:	1101                	addi	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	e04a                	sd	s2,0(sp)
    80001d34:	1000                	addi	s0,sp,32
    80001d36:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d38:	00000097          	auipc	ra,0x0
    80001d3c:	ca6080e7          	jalr	-858(ra) # 800019de <myproc>
    80001d40:	892a                	mv	s2,a0
  sz = p->sz;
    80001d42:	652c                	ld	a1,72(a0)
    80001d44:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d48:	00904f63          	bgtz	s1,80001d66 <growproc+0x3c>
  } else if(n < 0){
    80001d4c:	0204cc63          	bltz	s1,80001d84 <growproc+0x5a>
  p->sz = sz;
    80001d50:	1602                	slli	a2,a2,0x20
    80001d52:	9201                	srli	a2,a2,0x20
    80001d54:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d58:	4501                	li	a0,0
}
    80001d5a:	60e2                	ld	ra,24(sp)
    80001d5c:	6442                	ld	s0,16(sp)
    80001d5e:	64a2                	ld	s1,8(sp)
    80001d60:	6902                	ld	s2,0(sp)
    80001d62:	6105                	addi	sp,sp,32
    80001d64:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d66:	9e25                	addw	a2,a2,s1
    80001d68:	1602                	slli	a2,a2,0x20
    80001d6a:	9201                	srli	a2,a2,0x20
    80001d6c:	1582                	slli	a1,a1,0x20
    80001d6e:	9181                	srli	a1,a1,0x20
    80001d70:	6928                	ld	a0,80(a0)
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	710080e7          	jalr	1808(ra) # 80001482 <uvmalloc>
    80001d7a:	0005061b          	sext.w	a2,a0
    80001d7e:	fa69                	bnez	a2,80001d50 <growproc+0x26>
      return -1;
    80001d80:	557d                	li	a0,-1
    80001d82:	bfe1                	j	80001d5a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d84:	9e25                	addw	a2,a2,s1
    80001d86:	1602                	slli	a2,a2,0x20
    80001d88:	9201                	srli	a2,a2,0x20
    80001d8a:	1582                	slli	a1,a1,0x20
    80001d8c:	9181                	srli	a1,a1,0x20
    80001d8e:	6928                	ld	a0,80(a0)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	6aa080e7          	jalr	1706(ra) # 8000143a <uvmdealloc>
    80001d98:	0005061b          	sext.w	a2,a0
    80001d9c:	bf55                	j	80001d50 <growproc+0x26>

0000000080001d9e <fork>:
{
    80001d9e:	7179                	addi	sp,sp,-48
    80001da0:	f406                	sd	ra,40(sp)
    80001da2:	f022                	sd	s0,32(sp)
    80001da4:	ec26                	sd	s1,24(sp)
    80001da6:	e84a                	sd	s2,16(sp)
    80001da8:	e44e                	sd	s3,8(sp)
    80001daa:	e052                	sd	s4,0(sp)
    80001dac:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	c30080e7          	jalr	-976(ra) # 800019de <myproc>
    80001db6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	e30080e7          	jalr	-464(ra) # 80001be8 <allocproc>
    80001dc0:	c575                	beqz	a0,80001eac <fork+0x10e>
    80001dc2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dc4:	04893603          	ld	a2,72(s2)
    80001dc8:	692c                	ld	a1,80(a0)
    80001dca:	05093503          	ld	a0,80(s2)
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	800080e7          	jalr	-2048(ra) # 800015ce <uvmcopy>
    80001dd6:	04054863          	bltz	a0,80001e26 <fork+0x88>
  np->sz = p->sz;
    80001dda:	04893783          	ld	a5,72(s2)
    80001dde:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001de2:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001de6:	05893683          	ld	a3,88(s2)
    80001dea:	87b6                	mv	a5,a3
    80001dec:	0589b703          	ld	a4,88(s3)
    80001df0:	12068693          	addi	a3,a3,288
    80001df4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df8:	6788                	ld	a0,8(a5)
    80001dfa:	6b8c                	ld	a1,16(a5)
    80001dfc:	6f90                	ld	a2,24(a5)
    80001dfe:	01073023          	sd	a6,0(a4)
    80001e02:	e708                	sd	a0,8(a4)
    80001e04:	eb0c                	sd	a1,16(a4)
    80001e06:	ef10                	sd	a2,24(a4)
    80001e08:	02078793          	addi	a5,a5,32
    80001e0c:	02070713          	addi	a4,a4,32
    80001e10:	fed792e3          	bne	a5,a3,80001df4 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e14:	0589b783          	ld	a5,88(s3)
    80001e18:	0607b823          	sd	zero,112(a5)
    80001e1c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e20:	15000a13          	li	s4,336
    80001e24:	a03d                	j	80001e52 <fork+0xb4>
    freeproc(np);
    80001e26:	854e                	mv	a0,s3
    80001e28:	00000097          	auipc	ra,0x0
    80001e2c:	d68080e7          	jalr	-664(ra) # 80001b90 <freeproc>
    release(&np->lock);
    80001e30:	854e                	mv	a0,s3
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e92080e7          	jalr	-366(ra) # 80000cc4 <release>
    return -1;
    80001e3a:	54fd                	li	s1,-1
    80001e3c:	a8b9                	j	80001e9a <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e3e:	00002097          	auipc	ra,0x2
    80001e42:	670080e7          	jalr	1648(ra) # 800044ae <filedup>
    80001e46:	009987b3          	add	a5,s3,s1
    80001e4a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e4c:	04a1                	addi	s1,s1,8
    80001e4e:	01448763          	beq	s1,s4,80001e5c <fork+0xbe>
    if(p->ofile[i])
    80001e52:	009907b3          	add	a5,s2,s1
    80001e56:	6388                	ld	a0,0(a5)
    80001e58:	f17d                	bnez	a0,80001e3e <fork+0xa0>
    80001e5a:	bfcd                	j	80001e4c <fork+0xae>
  np->cwd = idup(p->cwd);
    80001e5c:	15093503          	ld	a0,336(s2)
    80001e60:	00001097          	auipc	ra,0x1
    80001e64:	7d4080e7          	jalr	2004(ra) # 80003634 <idup>
    80001e68:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e6c:	4641                	li	a2,16
    80001e6e:	15890593          	addi	a1,s2,344
    80001e72:	15898513          	addi	a0,s3,344
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	fec080e7          	jalr	-20(ra) # 80000e62 <safestrcpy>
  np->trace_mask = p->trace_mask;
    80001e7e:	16892783          	lw	a5,360(s2)
    80001e82:	16f9a423          	sw	a5,360(s3)
  pid = np->pid;
    80001e86:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001e8a:	4789                	li	a5,2
    80001e8c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e90:	854e                	mv	a0,s3
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	e32080e7          	jalr	-462(ra) # 80000cc4 <release>
}
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	70a2                	ld	ra,40(sp)
    80001e9e:	7402                	ld	s0,32(sp)
    80001ea0:	64e2                	ld	s1,24(sp)
    80001ea2:	6942                	ld	s2,16(sp)
    80001ea4:	69a2                	ld	s3,8(sp)
    80001ea6:	6a02                	ld	s4,0(sp)
    80001ea8:	6145                	addi	sp,sp,48
    80001eaa:	8082                	ret
    return -1;
    80001eac:	54fd                	li	s1,-1
    80001eae:	b7f5                	j	80001e9a <fork+0xfc>

0000000080001eb0 <reparent>:
{
    80001eb0:	7179                	addi	sp,sp,-48
    80001eb2:	f406                	sd	ra,40(sp)
    80001eb4:	f022                	sd	s0,32(sp)
    80001eb6:	ec26                	sd	s1,24(sp)
    80001eb8:	e84a                	sd	s2,16(sp)
    80001eba:	e44e                	sd	s3,8(sp)
    80001ebc:	e052                	sd	s4,0(sp)
    80001ebe:	1800                	addi	s0,sp,48
    80001ec0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ec2:	00010497          	auipc	s1,0x10
    80001ec6:	ea648493          	addi	s1,s1,-346 # 80011d68 <proc>
      pp->parent = initproc;
    80001eca:	00007a17          	auipc	s4,0x7
    80001ece:	14ea0a13          	addi	s4,s4,334 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ed2:	00016997          	auipc	s3,0x16
    80001ed6:	a9698993          	addi	s3,s3,-1386 # 80017968 <tickslock>
    80001eda:	a029                	j	80001ee4 <reparent+0x34>
    80001edc:	17048493          	addi	s1,s1,368
    80001ee0:	03348363          	beq	s1,s3,80001f06 <reparent+0x56>
    if(pp->parent == p){
    80001ee4:	709c                	ld	a5,32(s1)
    80001ee6:	ff279be3          	bne	a5,s2,80001edc <reparent+0x2c>
      acquire(&pp->lock);
    80001eea:	8526                	mv	a0,s1
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	d24080e7          	jalr	-732(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80001ef4:	000a3783          	ld	a5,0(s4)
    80001ef8:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001efa:	8526                	mv	a0,s1
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	dc8080e7          	jalr	-568(ra) # 80000cc4 <release>
    80001f04:	bfe1                	j	80001edc <reparent+0x2c>
}
    80001f06:	70a2                	ld	ra,40(sp)
    80001f08:	7402                	ld	s0,32(sp)
    80001f0a:	64e2                	ld	s1,24(sp)
    80001f0c:	6942                	ld	s2,16(sp)
    80001f0e:	69a2                	ld	s3,8(sp)
    80001f10:	6a02                	ld	s4,0(sp)
    80001f12:	6145                	addi	sp,sp,48
    80001f14:	8082                	ret

0000000080001f16 <scheduler>:
{
    80001f16:	715d                	addi	sp,sp,-80
    80001f18:	e486                	sd	ra,72(sp)
    80001f1a:	e0a2                	sd	s0,64(sp)
    80001f1c:	fc26                	sd	s1,56(sp)
    80001f1e:	f84a                	sd	s2,48(sp)
    80001f20:	f44e                	sd	s3,40(sp)
    80001f22:	f052                	sd	s4,32(sp)
    80001f24:	ec56                	sd	s5,24(sp)
    80001f26:	e85a                	sd	s6,16(sp)
    80001f28:	e45e                	sd	s7,8(sp)
    80001f2a:	e062                	sd	s8,0(sp)
    80001f2c:	0880                	addi	s0,sp,80
    80001f2e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f30:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f32:	00779b13          	slli	s6,a5,0x7
    80001f36:	00010717          	auipc	a4,0x10
    80001f3a:	a1a70713          	addi	a4,a4,-1510 # 80011950 <pid_lock>
    80001f3e:	975a                	add	a4,a4,s6
    80001f40:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f44:	00010717          	auipc	a4,0x10
    80001f48:	a2c70713          	addi	a4,a4,-1492 # 80011970 <cpus+0x8>
    80001f4c:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f4e:	4c0d                	li	s8,3
        c->proc = p;
    80001f50:	079e                	slli	a5,a5,0x7
    80001f52:	00010a17          	auipc	s4,0x10
    80001f56:	9fea0a13          	addi	s4,s4,-1538 # 80011950 <pid_lock>
    80001f5a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f5c:	00016997          	auipc	s3,0x16
    80001f60:	a0c98993          	addi	s3,s3,-1524 # 80017968 <tickslock>
        found = 1;
    80001f64:	4b85                	li	s7,1
    80001f66:	a899                	j	80001fbc <scheduler+0xa6>
        p->state = RUNNING;
    80001f68:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001f6c:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001f70:	06048593          	addi	a1,s1,96
    80001f74:	855a                	mv	a0,s6
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	638080e7          	jalr	1592(ra) # 800025ae <swtch>
        c->proc = 0;
    80001f7e:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001f82:	8ade                	mv	s5,s7
      release(&p->lock);
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d3e080e7          	jalr	-706(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8e:	17048493          	addi	s1,s1,368
    80001f92:	01348b63          	beq	s1,s3,80001fa8 <scheduler+0x92>
      acquire(&p->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	c78080e7          	jalr	-904(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    80001fa0:	4c9c                	lw	a5,24(s1)
    80001fa2:	ff2791e3          	bne	a5,s2,80001f84 <scheduler+0x6e>
    80001fa6:	b7c9                	j	80001f68 <scheduler+0x52>
    if(found == 0) {
    80001fa8:	000a9a63          	bnez	s5,80001fbc <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fb0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fb4:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fb8:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc4:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001fc8:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fca:	00010497          	auipc	s1,0x10
    80001fce:	d9e48493          	addi	s1,s1,-610 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80001fd2:	4909                	li	s2,2
    80001fd4:	b7c9                	j	80001f96 <scheduler+0x80>

0000000080001fd6 <sched>:
{
    80001fd6:	7179                	addi	sp,sp,-48
    80001fd8:	f406                	sd	ra,40(sp)
    80001fda:	f022                	sd	s0,32(sp)
    80001fdc:	ec26                	sd	s1,24(sp)
    80001fde:	e84a                	sd	s2,16(sp)
    80001fe0:	e44e                	sd	s3,8(sp)
    80001fe2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	9fa080e7          	jalr	-1542(ra) # 800019de <myproc>
    80001fec:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	ba8080e7          	jalr	-1112(ra) # 80000b96 <holding>
    80001ff6:	c93d                	beqz	a0,8000206c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ffa:	2781                	sext.w	a5,a5
    80001ffc:	079e                	slli	a5,a5,0x7
    80001ffe:	00010717          	auipc	a4,0x10
    80002002:	95270713          	addi	a4,a4,-1710 # 80011950 <pid_lock>
    80002006:	97ba                	add	a5,a5,a4
    80002008:	0907a703          	lw	a4,144(a5)
    8000200c:	4785                	li	a5,1
    8000200e:	06f71763          	bne	a4,a5,8000207c <sched+0xa6>
  if(p->state == RUNNING)
    80002012:	4c98                	lw	a4,24(s1)
    80002014:	478d                	li	a5,3
    80002016:	06f70b63          	beq	a4,a5,8000208c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000201e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002020:	efb5                	bnez	a5,8000209c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002022:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002024:	00010917          	auipc	s2,0x10
    80002028:	92c90913          	addi	s2,s2,-1748 # 80011950 <pid_lock>
    8000202c:	2781                	sext.w	a5,a5
    8000202e:	079e                	slli	a5,a5,0x7
    80002030:	97ca                	add	a5,a5,s2
    80002032:	0947a983          	lw	s3,148(a5)
    80002036:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002038:	2781                	sext.w	a5,a5
    8000203a:	079e                	slli	a5,a5,0x7
    8000203c:	00010597          	auipc	a1,0x10
    80002040:	93458593          	addi	a1,a1,-1740 # 80011970 <cpus+0x8>
    80002044:	95be                	add	a1,a1,a5
    80002046:	06048513          	addi	a0,s1,96
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	564080e7          	jalr	1380(ra) # 800025ae <swtch>
    80002052:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002054:	2781                	sext.w	a5,a5
    80002056:	079e                	slli	a5,a5,0x7
    80002058:	97ca                	add	a5,a5,s2
    8000205a:	0937aa23          	sw	s3,148(a5)
}
    8000205e:	70a2                	ld	ra,40(sp)
    80002060:	7402                	ld	s0,32(sp)
    80002062:	64e2                	ld	s1,24(sp)
    80002064:	6942                	ld	s2,16(sp)
    80002066:	69a2                	ld	s3,8(sp)
    80002068:	6145                	addi	sp,sp,48
    8000206a:	8082                	ret
    panic("sched p->lock");
    8000206c:	00006517          	auipc	a0,0x6
    80002070:	19450513          	addi	a0,a0,404 # 80008200 <digits+0x1c0>
    80002074:	ffffe097          	auipc	ra,0xffffe
    80002078:	4d4080e7          	jalr	1236(ra) # 80000548 <panic>
    panic("sched locks");
    8000207c:	00006517          	auipc	a0,0x6
    80002080:	19450513          	addi	a0,a0,404 # 80008210 <digits+0x1d0>
    80002084:	ffffe097          	auipc	ra,0xffffe
    80002088:	4c4080e7          	jalr	1220(ra) # 80000548 <panic>
    panic("sched running");
    8000208c:	00006517          	auipc	a0,0x6
    80002090:	19450513          	addi	a0,a0,404 # 80008220 <digits+0x1e0>
    80002094:	ffffe097          	auipc	ra,0xffffe
    80002098:	4b4080e7          	jalr	1204(ra) # 80000548 <panic>
    panic("sched interruptible");
    8000209c:	00006517          	auipc	a0,0x6
    800020a0:	19450513          	addi	a0,a0,404 # 80008230 <digits+0x1f0>
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	4a4080e7          	jalr	1188(ra) # 80000548 <panic>

00000000800020ac <exit>:
{
    800020ac:	7179                	addi	sp,sp,-48
    800020ae:	f406                	sd	ra,40(sp)
    800020b0:	f022                	sd	s0,32(sp)
    800020b2:	ec26                	sd	s1,24(sp)
    800020b4:	e84a                	sd	s2,16(sp)
    800020b6:	e44e                	sd	s3,8(sp)
    800020b8:	e052                	sd	s4,0(sp)
    800020ba:	1800                	addi	s0,sp,48
    800020bc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020be:	00000097          	auipc	ra,0x0
    800020c2:	920080e7          	jalr	-1760(ra) # 800019de <myproc>
    800020c6:	89aa                	mv	s3,a0
  if(p == initproc)
    800020c8:	00007797          	auipc	a5,0x7
    800020cc:	f507b783          	ld	a5,-176(a5) # 80009018 <initproc>
    800020d0:	0d050493          	addi	s1,a0,208
    800020d4:	15050913          	addi	s2,a0,336
    800020d8:	02a79363          	bne	a5,a0,800020fe <exit+0x52>
    panic("init exiting");
    800020dc:	00006517          	auipc	a0,0x6
    800020e0:	16c50513          	addi	a0,a0,364 # 80008248 <digits+0x208>
    800020e4:	ffffe097          	auipc	ra,0xffffe
    800020e8:	464080e7          	jalr	1124(ra) # 80000548 <panic>
      fileclose(f);
    800020ec:	00002097          	auipc	ra,0x2
    800020f0:	414080e7          	jalr	1044(ra) # 80004500 <fileclose>
      p->ofile[fd] = 0;
    800020f4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020f8:	04a1                	addi	s1,s1,8
    800020fa:	01248563          	beq	s1,s2,80002104 <exit+0x58>
    if(p->ofile[fd]){
    800020fe:	6088                	ld	a0,0(s1)
    80002100:	f575                	bnez	a0,800020ec <exit+0x40>
    80002102:	bfdd                	j	800020f8 <exit+0x4c>
  begin_op();
    80002104:	00002097          	auipc	ra,0x2
    80002108:	f2a080e7          	jalr	-214(ra) # 8000402e <begin_op>
  iput(p->cwd);
    8000210c:	1509b503          	ld	a0,336(s3)
    80002110:	00001097          	auipc	ra,0x1
    80002114:	71c080e7          	jalr	1820(ra) # 8000382c <iput>
  end_op();
    80002118:	00002097          	auipc	ra,0x2
    8000211c:	f96080e7          	jalr	-106(ra) # 800040ae <end_op>
  p->cwd = 0;
    80002120:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002124:	00007497          	auipc	s1,0x7
    80002128:	ef448493          	addi	s1,s1,-268 # 80009018 <initproc>
    8000212c:	6088                	ld	a0,0(s1)
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	ae2080e7          	jalr	-1310(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    80002136:	6088                	ld	a0,0(s1)
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	766080e7          	jalr	1894(ra) # 8000189e <wakeup1>
  release(&initproc->lock);
    80002140:	6088                	ld	a0,0(s1)
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	b82080e7          	jalr	-1150(ra) # 80000cc4 <release>
  acquire(&p->lock);
    8000214a:	854e                	mv	a0,s3
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	ac4080e7          	jalr	-1340(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    80002154:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002158:	854e                	mv	a0,s3
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	b6a080e7          	jalr	-1174(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    80002162:	8526                	mv	a0,s1
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	aac080e7          	jalr	-1364(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    8000216c:	854e                	mv	a0,s3
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	aa2080e7          	jalr	-1374(ra) # 80000c10 <acquire>
  reparent(p);
    80002176:	854e                	mv	a0,s3
    80002178:	00000097          	auipc	ra,0x0
    8000217c:	d38080e7          	jalr	-712(ra) # 80001eb0 <reparent>
  wakeup1(original_parent);
    80002180:	8526                	mv	a0,s1
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	71c080e7          	jalr	1820(ra) # 8000189e <wakeup1>
  p->xstate = status;
    8000218a:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000218e:	4791                	li	a5,4
    80002190:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	b2e080e7          	jalr	-1234(ra) # 80000cc4 <release>
  sched();
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	e38080e7          	jalr	-456(ra) # 80001fd6 <sched>
  panic("zombie exit");
    800021a6:	00006517          	auipc	a0,0x6
    800021aa:	0b250513          	addi	a0,a0,178 # 80008258 <digits+0x218>
    800021ae:	ffffe097          	auipc	ra,0xffffe
    800021b2:	39a080e7          	jalr	922(ra) # 80000548 <panic>

00000000800021b6 <yield>:
{
    800021b6:	1101                	addi	sp,sp,-32
    800021b8:	ec06                	sd	ra,24(sp)
    800021ba:	e822                	sd	s0,16(sp)
    800021bc:	e426                	sd	s1,8(sp)
    800021be:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	81e080e7          	jalr	-2018(ra) # 800019de <myproc>
    800021c8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	a46080e7          	jalr	-1466(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800021d2:	4789                	li	a5,2
    800021d4:	cc9c                	sw	a5,24(s1)
  sched();
    800021d6:	00000097          	auipc	ra,0x0
    800021da:	e00080e7          	jalr	-512(ra) # 80001fd6 <sched>
  release(&p->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	ae4080e7          	jalr	-1308(ra) # 80000cc4 <release>
}
    800021e8:	60e2                	ld	ra,24(sp)
    800021ea:	6442                	ld	s0,16(sp)
    800021ec:	64a2                	ld	s1,8(sp)
    800021ee:	6105                	addi	sp,sp,32
    800021f0:	8082                	ret

00000000800021f2 <sleep>:
{
    800021f2:	7179                	addi	sp,sp,-48
    800021f4:	f406                	sd	ra,40(sp)
    800021f6:	f022                	sd	s0,32(sp)
    800021f8:	ec26                	sd	s1,24(sp)
    800021fa:	e84a                	sd	s2,16(sp)
    800021fc:	e44e                	sd	s3,8(sp)
    800021fe:	1800                	addi	s0,sp,48
    80002200:	89aa                	mv	s3,a0
    80002202:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	7da080e7          	jalr	2010(ra) # 800019de <myproc>
    8000220c:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000220e:	05250663          	beq	a0,s2,8000225a <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	9fe080e7          	jalr	-1538(ra) # 80000c10 <acquire>
    release(lk);
    8000221a:	854a                	mv	a0,s2
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	aa8080e7          	jalr	-1368(ra) # 80000cc4 <release>
  p->chan = chan;
    80002224:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002228:	4785                	li	a5,1
    8000222a:	cc9c                	sw	a5,24(s1)
  sched();
    8000222c:	00000097          	auipc	ra,0x0
    80002230:	daa080e7          	jalr	-598(ra) # 80001fd6 <sched>
  p->chan = 0;
    80002234:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002238:	8526                	mv	a0,s1
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	a8a080e7          	jalr	-1398(ra) # 80000cc4 <release>
    acquire(lk);
    80002242:	854a                	mv	a0,s2
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	9cc080e7          	jalr	-1588(ra) # 80000c10 <acquire>
}
    8000224c:	70a2                	ld	ra,40(sp)
    8000224e:	7402                	ld	s0,32(sp)
    80002250:	64e2                	ld	s1,24(sp)
    80002252:	6942                	ld	s2,16(sp)
    80002254:	69a2                	ld	s3,8(sp)
    80002256:	6145                	addi	sp,sp,48
    80002258:	8082                	ret
  p->chan = chan;
    8000225a:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000225e:	4785                	li	a5,1
    80002260:	cd1c                	sw	a5,24(a0)
  sched();
    80002262:	00000097          	auipc	ra,0x0
    80002266:	d74080e7          	jalr	-652(ra) # 80001fd6 <sched>
  p->chan = 0;
    8000226a:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000226e:	bff9                	j	8000224c <sleep+0x5a>

0000000080002270 <wait>:
{
    80002270:	715d                	addi	sp,sp,-80
    80002272:	e486                	sd	ra,72(sp)
    80002274:	e0a2                	sd	s0,64(sp)
    80002276:	fc26                	sd	s1,56(sp)
    80002278:	f84a                	sd	s2,48(sp)
    8000227a:	f44e                	sd	s3,40(sp)
    8000227c:	f052                	sd	s4,32(sp)
    8000227e:	ec56                	sd	s5,24(sp)
    80002280:	e85a                	sd	s6,16(sp)
    80002282:	e45e                	sd	s7,8(sp)
    80002284:	e062                	sd	s8,0(sp)
    80002286:	0880                	addi	s0,sp,80
    80002288:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	754080e7          	jalr	1876(ra) # 800019de <myproc>
    80002292:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002294:	8c2a                	mv	s8,a0
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	97a080e7          	jalr	-1670(ra) # 80000c10 <acquire>
    havekids = 0;
    8000229e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022a0:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022a2:	00015997          	auipc	s3,0x15
    800022a6:	6c698993          	addi	s3,s3,1734 # 80017968 <tickslock>
        havekids = 1;
    800022aa:	4a85                	li	s5,1
    havekids = 0;
    800022ac:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022ae:	00010497          	auipc	s1,0x10
    800022b2:	aba48493          	addi	s1,s1,-1350 # 80011d68 <proc>
    800022b6:	a08d                	j	80002318 <wait+0xa8>
          pid = np->pid;
    800022b8:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022bc:	000b0e63          	beqz	s6,800022d8 <wait+0x68>
    800022c0:	4691                	li	a3,4
    800022c2:	03448613          	addi	a2,s1,52
    800022c6:	85da                	mv	a1,s6
    800022c8:	05093503          	ld	a0,80(s2)
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	406080e7          	jalr	1030(ra) # 800016d2 <copyout>
    800022d4:	02054263          	bltz	a0,800022f8 <wait+0x88>
          freeproc(np);
    800022d8:	8526                	mv	a0,s1
    800022da:	00000097          	auipc	ra,0x0
    800022de:	8b6080e7          	jalr	-1866(ra) # 80001b90 <freeproc>
          release(&np->lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	9e0080e7          	jalr	-1568(ra) # 80000cc4 <release>
          release(&p->lock);
    800022ec:	854a                	mv	a0,s2
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	9d6080e7          	jalr	-1578(ra) # 80000cc4 <release>
          return pid;
    800022f6:	a8a9                	j	80002350 <wait+0xe0>
            release(&np->lock);
    800022f8:	8526                	mv	a0,s1
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	9ca080e7          	jalr	-1590(ra) # 80000cc4 <release>
            release(&p->lock);
    80002302:	854a                	mv	a0,s2
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	9c0080e7          	jalr	-1600(ra) # 80000cc4 <release>
            return -1;
    8000230c:	59fd                	li	s3,-1
    8000230e:	a089                	j	80002350 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002310:	17048493          	addi	s1,s1,368
    80002314:	03348463          	beq	s1,s3,8000233c <wait+0xcc>
      if(np->parent == p){
    80002318:	709c                	ld	a5,32(s1)
    8000231a:	ff279be3          	bne	a5,s2,80002310 <wait+0xa0>
        acquire(&np->lock);
    8000231e:	8526                	mv	a0,s1
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	8f0080e7          	jalr	-1808(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    80002328:	4c9c                	lw	a5,24(s1)
    8000232a:	f94787e3          	beq	a5,s4,800022b8 <wait+0x48>
        release(&np->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	994080e7          	jalr	-1644(ra) # 80000cc4 <release>
        havekids = 1;
    80002338:	8756                	mv	a4,s5
    8000233a:	bfd9                	j	80002310 <wait+0xa0>
    if(!havekids || p->killed){
    8000233c:	c701                	beqz	a4,80002344 <wait+0xd4>
    8000233e:	03092783          	lw	a5,48(s2)
    80002342:	c785                	beqz	a5,8000236a <wait+0xfa>
      release(&p->lock);
    80002344:	854a                	mv	a0,s2
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	97e080e7          	jalr	-1666(ra) # 80000cc4 <release>
      return -1;
    8000234e:	59fd                	li	s3,-1
}
    80002350:	854e                	mv	a0,s3
    80002352:	60a6                	ld	ra,72(sp)
    80002354:	6406                	ld	s0,64(sp)
    80002356:	74e2                	ld	s1,56(sp)
    80002358:	7942                	ld	s2,48(sp)
    8000235a:	79a2                	ld	s3,40(sp)
    8000235c:	7a02                	ld	s4,32(sp)
    8000235e:	6ae2                	ld	s5,24(sp)
    80002360:	6b42                	ld	s6,16(sp)
    80002362:	6ba2                	ld	s7,8(sp)
    80002364:	6c02                	ld	s8,0(sp)
    80002366:	6161                	addi	sp,sp,80
    80002368:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000236a:	85e2                	mv	a1,s8
    8000236c:	854a                	mv	a0,s2
    8000236e:	00000097          	auipc	ra,0x0
    80002372:	e84080e7          	jalr	-380(ra) # 800021f2 <sleep>
    havekids = 0;
    80002376:	bf1d                	j	800022ac <wait+0x3c>

0000000080002378 <wakeup>:
{
    80002378:	7139                	addi	sp,sp,-64
    8000237a:	fc06                	sd	ra,56(sp)
    8000237c:	f822                	sd	s0,48(sp)
    8000237e:	f426                	sd	s1,40(sp)
    80002380:	f04a                	sd	s2,32(sp)
    80002382:	ec4e                	sd	s3,24(sp)
    80002384:	e852                	sd	s4,16(sp)
    80002386:	e456                	sd	s5,8(sp)
    80002388:	0080                	addi	s0,sp,64
    8000238a:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000238c:	00010497          	auipc	s1,0x10
    80002390:	9dc48493          	addi	s1,s1,-1572 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002394:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002396:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002398:	00015917          	auipc	s2,0x15
    8000239c:	5d090913          	addi	s2,s2,1488 # 80017968 <tickslock>
    800023a0:	a821                	j	800023b8 <wakeup+0x40>
      p->state = RUNNABLE;
    800023a2:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023a6:	8526                	mv	a0,s1
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	91c080e7          	jalr	-1764(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023b0:	17048493          	addi	s1,s1,368
    800023b4:	01248e63          	beq	s1,s2,800023d0 <wakeup+0x58>
    acquire(&p->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	856080e7          	jalr	-1962(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023c2:	4c9c                	lw	a5,24(s1)
    800023c4:	ff3791e3          	bne	a5,s3,800023a6 <wakeup+0x2e>
    800023c8:	749c                	ld	a5,40(s1)
    800023ca:	fd479ee3          	bne	a5,s4,800023a6 <wakeup+0x2e>
    800023ce:	bfd1                	j	800023a2 <wakeup+0x2a>
}
    800023d0:	70e2                	ld	ra,56(sp)
    800023d2:	7442                	ld	s0,48(sp)
    800023d4:	74a2                	ld	s1,40(sp)
    800023d6:	7902                	ld	s2,32(sp)
    800023d8:	69e2                	ld	s3,24(sp)
    800023da:	6a42                	ld	s4,16(sp)
    800023dc:	6aa2                	ld	s5,8(sp)
    800023de:	6121                	addi	sp,sp,64
    800023e0:	8082                	ret

00000000800023e2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023e2:	7179                	addi	sp,sp,-48
    800023e4:	f406                	sd	ra,40(sp)
    800023e6:	f022                	sd	s0,32(sp)
    800023e8:	ec26                	sd	s1,24(sp)
    800023ea:	e84a                	sd	s2,16(sp)
    800023ec:	e44e                	sd	s3,8(sp)
    800023ee:	1800                	addi	s0,sp,48
    800023f0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023f2:	00010497          	auipc	s1,0x10
    800023f6:	97648493          	addi	s1,s1,-1674 # 80011d68 <proc>
    800023fa:	00015997          	auipc	s3,0x15
    800023fe:	56e98993          	addi	s3,s3,1390 # 80017968 <tickslock>
    acquire(&p->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	80c080e7          	jalr	-2036(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    8000240c:	5c9c                	lw	a5,56(s1)
    8000240e:	01278d63          	beq	a5,s2,80002428 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	8b0080e7          	jalr	-1872(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000241c:	17048493          	addi	s1,s1,368
    80002420:	ff3491e3          	bne	s1,s3,80002402 <kill+0x20>
  }
  return -1;
    80002424:	557d                	li	a0,-1
    80002426:	a829                	j	80002440 <kill+0x5e>
      p->killed = 1;
    80002428:	4785                	li	a5,1
    8000242a:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000242c:	4c98                	lw	a4,24(s1)
    8000242e:	4785                	li	a5,1
    80002430:	00f70f63          	beq	a4,a5,8000244e <kill+0x6c>
      release(&p->lock);
    80002434:	8526                	mv	a0,s1
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	88e080e7          	jalr	-1906(ra) # 80000cc4 <release>
      return 0;
    8000243e:	4501                	li	a0,0
}
    80002440:	70a2                	ld	ra,40(sp)
    80002442:	7402                	ld	s0,32(sp)
    80002444:	64e2                	ld	s1,24(sp)
    80002446:	6942                	ld	s2,16(sp)
    80002448:	69a2                	ld	s3,8(sp)
    8000244a:	6145                	addi	sp,sp,48
    8000244c:	8082                	ret
        p->state = RUNNABLE;
    8000244e:	4789                	li	a5,2
    80002450:	cc9c                	sw	a5,24(s1)
    80002452:	b7cd                	j	80002434 <kill+0x52>

0000000080002454 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002454:	7179                	addi	sp,sp,-48
    80002456:	f406                	sd	ra,40(sp)
    80002458:	f022                	sd	s0,32(sp)
    8000245a:	ec26                	sd	s1,24(sp)
    8000245c:	e84a                	sd	s2,16(sp)
    8000245e:	e44e                	sd	s3,8(sp)
    80002460:	e052                	sd	s4,0(sp)
    80002462:	1800                	addi	s0,sp,48
    80002464:	84aa                	mv	s1,a0
    80002466:	892e                	mv	s2,a1
    80002468:	89b2                	mv	s3,a2
    8000246a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	572080e7          	jalr	1394(ra) # 800019de <myproc>
  if(user_dst){
    80002474:	c08d                	beqz	s1,80002496 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002476:	86d2                	mv	a3,s4
    80002478:	864e                	mv	a2,s3
    8000247a:	85ca                	mv	a1,s2
    8000247c:	6928                	ld	a0,80(a0)
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	254080e7          	jalr	596(ra) # 800016d2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002486:	70a2                	ld	ra,40(sp)
    80002488:	7402                	ld	s0,32(sp)
    8000248a:	64e2                	ld	s1,24(sp)
    8000248c:	6942                	ld	s2,16(sp)
    8000248e:	69a2                	ld	s3,8(sp)
    80002490:	6a02                	ld	s4,0(sp)
    80002492:	6145                	addi	sp,sp,48
    80002494:	8082                	ret
    memmove((char *)dst, src, len);
    80002496:	000a061b          	sext.w	a2,s4
    8000249a:	85ce                	mv	a1,s3
    8000249c:	854a                	mv	a0,s2
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	8ce080e7          	jalr	-1842(ra) # 80000d6c <memmove>
    return 0;
    800024a6:	8526                	mv	a0,s1
    800024a8:	bff9                	j	80002486 <either_copyout+0x32>

00000000800024aa <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024aa:	7179                	addi	sp,sp,-48
    800024ac:	f406                	sd	ra,40(sp)
    800024ae:	f022                	sd	s0,32(sp)
    800024b0:	ec26                	sd	s1,24(sp)
    800024b2:	e84a                	sd	s2,16(sp)
    800024b4:	e44e                	sd	s3,8(sp)
    800024b6:	e052                	sd	s4,0(sp)
    800024b8:	1800                	addi	s0,sp,48
    800024ba:	892a                	mv	s2,a0
    800024bc:	84ae                	mv	s1,a1
    800024be:	89b2                	mv	s3,a2
    800024c0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	51c080e7          	jalr	1308(ra) # 800019de <myproc>
  if(user_src){
    800024ca:	c08d                	beqz	s1,800024ec <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024cc:	86d2                	mv	a3,s4
    800024ce:	864e                	mv	a2,s3
    800024d0:	85ca                	mv	a1,s2
    800024d2:	6928                	ld	a0,80(a0)
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	28a080e7          	jalr	650(ra) # 8000175e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024dc:	70a2                	ld	ra,40(sp)
    800024de:	7402                	ld	s0,32(sp)
    800024e0:	64e2                	ld	s1,24(sp)
    800024e2:	6942                	ld	s2,16(sp)
    800024e4:	69a2                	ld	s3,8(sp)
    800024e6:	6a02                	ld	s4,0(sp)
    800024e8:	6145                	addi	sp,sp,48
    800024ea:	8082                	ret
    memmove(dst, (char*)src, len);
    800024ec:	000a061b          	sext.w	a2,s4
    800024f0:	85ce                	mv	a1,s3
    800024f2:	854a                	mv	a0,s2
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	878080e7          	jalr	-1928(ra) # 80000d6c <memmove>
    return 0;
    800024fc:	8526                	mv	a0,s1
    800024fe:	bff9                	j	800024dc <either_copyin+0x32>

0000000080002500 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002500:	715d                	addi	sp,sp,-80
    80002502:	e486                	sd	ra,72(sp)
    80002504:	e0a2                	sd	s0,64(sp)
    80002506:	fc26                	sd	s1,56(sp)
    80002508:	f84a                	sd	s2,48(sp)
    8000250a:	f44e                	sd	s3,40(sp)
    8000250c:	f052                	sd	s4,32(sp)
    8000250e:	ec56                	sd	s5,24(sp)
    80002510:	e85a                	sd	s6,16(sp)
    80002512:	e45e                	sd	s7,8(sp)
    80002514:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002516:	00006517          	auipc	a0,0x6
    8000251a:	bb250513          	addi	a0,a0,-1102 # 800080c8 <digits+0x88>
    8000251e:	ffffe097          	auipc	ra,0xffffe
    80002522:	074080e7          	jalr	116(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002526:	00010497          	auipc	s1,0x10
    8000252a:	99a48493          	addi	s1,s1,-1638 # 80011ec0 <proc+0x158>
    8000252e:	00015917          	auipc	s2,0x15
    80002532:	59290913          	addi	s2,s2,1426 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002536:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002538:	00006997          	auipc	s3,0x6
    8000253c:	d3098993          	addi	s3,s3,-720 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002540:	00006a97          	auipc	s5,0x6
    80002544:	d30a8a93          	addi	s5,s5,-720 # 80008270 <digits+0x230>
    printf("\n");
    80002548:	00006a17          	auipc	s4,0x6
    8000254c:	b80a0a13          	addi	s4,s4,-1152 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002550:	00006b97          	auipc	s7,0x6
    80002554:	d58b8b93          	addi	s7,s7,-680 # 800082a8 <states.1703>
    80002558:	a00d                	j	8000257a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000255a:	ee06a583          	lw	a1,-288(a3)
    8000255e:	8556                	mv	a0,s5
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	032080e7          	jalr	50(ra) # 80000592 <printf>
    printf("\n");
    80002568:	8552                	mv	a0,s4
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	028080e7          	jalr	40(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002572:	17048493          	addi	s1,s1,368
    80002576:	03248163          	beq	s1,s2,80002598 <procdump+0x98>
    if(p->state == UNUSED)
    8000257a:	86a6                	mv	a3,s1
    8000257c:	ec04a783          	lw	a5,-320(s1)
    80002580:	dbed                	beqz	a5,80002572 <procdump+0x72>
      state = "???";
    80002582:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002584:	fcfb6be3          	bltu	s6,a5,8000255a <procdump+0x5a>
    80002588:	1782                	slli	a5,a5,0x20
    8000258a:	9381                	srli	a5,a5,0x20
    8000258c:	078e                	slli	a5,a5,0x3
    8000258e:	97de                	add	a5,a5,s7
    80002590:	6390                	ld	a2,0(a5)
    80002592:	f661                	bnez	a2,8000255a <procdump+0x5a>
      state = "???";
    80002594:	864e                	mv	a2,s3
    80002596:	b7d1                	j	8000255a <procdump+0x5a>
  }
}
    80002598:	60a6                	ld	ra,72(sp)
    8000259a:	6406                	ld	s0,64(sp)
    8000259c:	74e2                	ld	s1,56(sp)
    8000259e:	7942                	ld	s2,48(sp)
    800025a0:	79a2                	ld	s3,40(sp)
    800025a2:	7a02                	ld	s4,32(sp)
    800025a4:	6ae2                	ld	s5,24(sp)
    800025a6:	6b42                	ld	s6,16(sp)
    800025a8:	6ba2                	ld	s7,8(sp)
    800025aa:	6161                	addi	sp,sp,80
    800025ac:	8082                	ret

00000000800025ae <swtch>:
    800025ae:	00153023          	sd	ra,0(a0)
    800025b2:	00253423          	sd	sp,8(a0)
    800025b6:	e900                	sd	s0,16(a0)
    800025b8:	ed04                	sd	s1,24(a0)
    800025ba:	03253023          	sd	s2,32(a0)
    800025be:	03353423          	sd	s3,40(a0)
    800025c2:	03453823          	sd	s4,48(a0)
    800025c6:	03553c23          	sd	s5,56(a0)
    800025ca:	05653023          	sd	s6,64(a0)
    800025ce:	05753423          	sd	s7,72(a0)
    800025d2:	05853823          	sd	s8,80(a0)
    800025d6:	05953c23          	sd	s9,88(a0)
    800025da:	07a53023          	sd	s10,96(a0)
    800025de:	07b53423          	sd	s11,104(a0)
    800025e2:	0005b083          	ld	ra,0(a1)
    800025e6:	0085b103          	ld	sp,8(a1)
    800025ea:	6980                	ld	s0,16(a1)
    800025ec:	6d84                	ld	s1,24(a1)
    800025ee:	0205b903          	ld	s2,32(a1)
    800025f2:	0285b983          	ld	s3,40(a1)
    800025f6:	0305ba03          	ld	s4,48(a1)
    800025fa:	0385ba83          	ld	s5,56(a1)
    800025fe:	0405bb03          	ld	s6,64(a1)
    80002602:	0485bb83          	ld	s7,72(a1)
    80002606:	0505bc03          	ld	s8,80(a1)
    8000260a:	0585bc83          	ld	s9,88(a1)
    8000260e:	0605bd03          	ld	s10,96(a1)
    80002612:	0685bd83          	ld	s11,104(a1)
    80002616:	8082                	ret

0000000080002618 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002618:	1141                	addi	sp,sp,-16
    8000261a:	e406                	sd	ra,8(sp)
    8000261c:	e022                	sd	s0,0(sp)
    8000261e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002620:	00006597          	auipc	a1,0x6
    80002624:	cb058593          	addi	a1,a1,-848 # 800082d0 <states.1703+0x28>
    80002628:	00015517          	auipc	a0,0x15
    8000262c:	34050513          	addi	a0,a0,832 # 80017968 <tickslock>
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	550080e7          	jalr	1360(ra) # 80000b80 <initlock>
}
    80002638:	60a2                	ld	ra,8(sp)
    8000263a:	6402                	ld	s0,0(sp)
    8000263c:	0141                	addi	sp,sp,16
    8000263e:	8082                	ret

0000000080002640 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002640:	1141                	addi	sp,sp,-16
    80002642:	e422                	sd	s0,8(sp)
    80002644:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002646:	00003797          	auipc	a5,0x3
    8000264a:	52a78793          	addi	a5,a5,1322 # 80005b70 <kernelvec>
    8000264e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002652:	6422                	ld	s0,8(sp)
    80002654:	0141                	addi	sp,sp,16
    80002656:	8082                	ret

0000000080002658 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002658:	1141                	addi	sp,sp,-16
    8000265a:	e406                	sd	ra,8(sp)
    8000265c:	e022                	sd	s0,0(sp)
    8000265e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002660:	fffff097          	auipc	ra,0xfffff
    80002664:	37e080e7          	jalr	894(ra) # 800019de <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002668:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000266c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000266e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002672:	00005617          	auipc	a2,0x5
    80002676:	98e60613          	addi	a2,a2,-1650 # 80007000 <_trampoline>
    8000267a:	00005697          	auipc	a3,0x5
    8000267e:	98668693          	addi	a3,a3,-1658 # 80007000 <_trampoline>
    80002682:	8e91                	sub	a3,a3,a2
    80002684:	040007b7          	lui	a5,0x4000
    80002688:	17fd                	addi	a5,a5,-1
    8000268a:	07b2                	slli	a5,a5,0xc
    8000268c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000268e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002692:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002694:	180026f3          	csrr	a3,satp
    80002698:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000269a:	6d38                	ld	a4,88(a0)
    8000269c:	6134                	ld	a3,64(a0)
    8000269e:	6585                	lui	a1,0x1
    800026a0:	96ae                	add	a3,a3,a1
    800026a2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026a4:	6d38                	ld	a4,88(a0)
    800026a6:	00000697          	auipc	a3,0x0
    800026aa:	13868693          	addi	a3,a3,312 # 800027de <usertrap>
    800026ae:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026b0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026b2:	8692                	mv	a3,tp
    800026b4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026ba:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026be:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026c6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026c8:	6f18                	ld	a4,24(a4)
    800026ca:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026ce:	692c                	ld	a1,80(a0)
    800026d0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026d2:	00005717          	auipc	a4,0x5
    800026d6:	9be70713          	addi	a4,a4,-1602 # 80007090 <userret>
    800026da:	8f11                	sub	a4,a4,a2
    800026dc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026de:	577d                	li	a4,-1
    800026e0:	177e                	slli	a4,a4,0x3f
    800026e2:	8dd9                	or	a1,a1,a4
    800026e4:	02000537          	lui	a0,0x2000
    800026e8:	157d                	addi	a0,a0,-1
    800026ea:	0536                	slli	a0,a0,0xd
    800026ec:	9782                	jalr	a5
}
    800026ee:	60a2                	ld	ra,8(sp)
    800026f0:	6402                	ld	s0,0(sp)
    800026f2:	0141                	addi	sp,sp,16
    800026f4:	8082                	ret

00000000800026f6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026f6:	1101                	addi	sp,sp,-32
    800026f8:	ec06                	sd	ra,24(sp)
    800026fa:	e822                	sd	s0,16(sp)
    800026fc:	e426                	sd	s1,8(sp)
    800026fe:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002700:	00015497          	auipc	s1,0x15
    80002704:	26848493          	addi	s1,s1,616 # 80017968 <tickslock>
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	506080e7          	jalr	1286(ra) # 80000c10 <acquire>
  ticks++;
    80002712:	00007517          	auipc	a0,0x7
    80002716:	90e50513          	addi	a0,a0,-1778 # 80009020 <ticks>
    8000271a:	411c                	lw	a5,0(a0)
    8000271c:	2785                	addiw	a5,a5,1
    8000271e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002720:	00000097          	auipc	ra,0x0
    80002724:	c58080e7          	jalr	-936(ra) # 80002378 <wakeup>
  release(&tickslock);
    80002728:	8526                	mv	a0,s1
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	59a080e7          	jalr	1434(ra) # 80000cc4 <release>
}
    80002732:	60e2                	ld	ra,24(sp)
    80002734:	6442                	ld	s0,16(sp)
    80002736:	64a2                	ld	s1,8(sp)
    80002738:	6105                	addi	sp,sp,32
    8000273a:	8082                	ret

000000008000273c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000273c:	1101                	addi	sp,sp,-32
    8000273e:	ec06                	sd	ra,24(sp)
    80002740:	e822                	sd	s0,16(sp)
    80002742:	e426                	sd	s1,8(sp)
    80002744:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002746:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000274a:	00074d63          	bltz	a4,80002764 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000274e:	57fd                	li	a5,-1
    80002750:	17fe                	slli	a5,a5,0x3f
    80002752:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002754:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002756:	06f70363          	beq	a4,a5,800027bc <devintr+0x80>
  }
}
    8000275a:	60e2                	ld	ra,24(sp)
    8000275c:	6442                	ld	s0,16(sp)
    8000275e:	64a2                	ld	s1,8(sp)
    80002760:	6105                	addi	sp,sp,32
    80002762:	8082                	ret
     (scause & 0xff) == 9){
    80002764:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002768:	46a5                	li	a3,9
    8000276a:	fed792e3          	bne	a5,a3,8000274e <devintr+0x12>
    int irq = plic_claim();
    8000276e:	00003097          	auipc	ra,0x3
    80002772:	50a080e7          	jalr	1290(ra) # 80005c78 <plic_claim>
    80002776:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002778:	47a9                	li	a5,10
    8000277a:	02f50763          	beq	a0,a5,800027a8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000277e:	4785                	li	a5,1
    80002780:	02f50963          	beq	a0,a5,800027b2 <devintr+0x76>
    return 1;
    80002784:	4505                	li	a0,1
    } else if(irq){
    80002786:	d8f1                	beqz	s1,8000275a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002788:	85a6                	mv	a1,s1
    8000278a:	00006517          	auipc	a0,0x6
    8000278e:	b4e50513          	addi	a0,a0,-1202 # 800082d8 <states.1703+0x30>
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	e00080e7          	jalr	-512(ra) # 80000592 <printf>
      plic_complete(irq);
    8000279a:	8526                	mv	a0,s1
    8000279c:	00003097          	auipc	ra,0x3
    800027a0:	500080e7          	jalr	1280(ra) # 80005c9c <plic_complete>
    return 1;
    800027a4:	4505                	li	a0,1
    800027a6:	bf55                	j	8000275a <devintr+0x1e>
      uartintr();
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	22c080e7          	jalr	556(ra) # 800009d4 <uartintr>
    800027b0:	b7ed                	j	8000279a <devintr+0x5e>
      virtio_disk_intr();
    800027b2:	00004097          	auipc	ra,0x4
    800027b6:	984080e7          	jalr	-1660(ra) # 80006136 <virtio_disk_intr>
    800027ba:	b7c5                	j	8000279a <devintr+0x5e>
    if(cpuid() == 0){
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	1f6080e7          	jalr	502(ra) # 800019b2 <cpuid>
    800027c4:	c901                	beqz	a0,800027d4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027c6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027ca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027cc:	14479073          	csrw	sip,a5
    return 2;
    800027d0:	4509                	li	a0,2
    800027d2:	b761                	j	8000275a <devintr+0x1e>
      clockintr();
    800027d4:	00000097          	auipc	ra,0x0
    800027d8:	f22080e7          	jalr	-222(ra) # 800026f6 <clockintr>
    800027dc:	b7ed                	j	800027c6 <devintr+0x8a>

00000000800027de <usertrap>:
{
    800027de:	1101                	addi	sp,sp,-32
    800027e0:	ec06                	sd	ra,24(sp)
    800027e2:	e822                	sd	s0,16(sp)
    800027e4:	e426                	sd	s1,8(sp)
    800027e6:	e04a                	sd	s2,0(sp)
    800027e8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ea:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027ee:	1007f793          	andi	a5,a5,256
    800027f2:	e3ad                	bnez	a5,80002854 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f4:	00003797          	auipc	a5,0x3
    800027f8:	37c78793          	addi	a5,a5,892 # 80005b70 <kernelvec>
    800027fc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002800:	fffff097          	auipc	ra,0xfffff
    80002804:	1de080e7          	jalr	478(ra) # 800019de <myproc>
    80002808:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000280a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000280c:	14102773          	csrr	a4,sepc
    80002810:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002812:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002816:	47a1                	li	a5,8
    80002818:	04f71c63          	bne	a4,a5,80002870 <usertrap+0x92>
    if(p->killed)
    8000281c:	591c                	lw	a5,48(a0)
    8000281e:	e3b9                	bnez	a5,80002864 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002820:	6cb8                	ld	a4,88(s1)
    80002822:	6f1c                	ld	a5,24(a4)
    80002824:	0791                	addi	a5,a5,4
    80002826:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002828:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000282c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002830:	10079073          	csrw	sstatus,a5
    syscall();
    80002834:	00000097          	auipc	ra,0x0
    80002838:	2e0080e7          	jalr	736(ra) # 80002b14 <syscall>
  if(p->killed)
    8000283c:	589c                	lw	a5,48(s1)
    8000283e:	ebc1                	bnez	a5,800028ce <usertrap+0xf0>
  usertrapret();
    80002840:	00000097          	auipc	ra,0x0
    80002844:	e18080e7          	jalr	-488(ra) # 80002658 <usertrapret>
}
    80002848:	60e2                	ld	ra,24(sp)
    8000284a:	6442                	ld	s0,16(sp)
    8000284c:	64a2                	ld	s1,8(sp)
    8000284e:	6902                	ld	s2,0(sp)
    80002850:	6105                	addi	sp,sp,32
    80002852:	8082                	ret
    panic("usertrap: not from user mode");
    80002854:	00006517          	auipc	a0,0x6
    80002858:	aa450513          	addi	a0,a0,-1372 # 800082f8 <states.1703+0x50>
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	cec080e7          	jalr	-788(ra) # 80000548 <panic>
      exit(-1);
    80002864:	557d                	li	a0,-1
    80002866:	00000097          	auipc	ra,0x0
    8000286a:	846080e7          	jalr	-1978(ra) # 800020ac <exit>
    8000286e:	bf4d                	j	80002820 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002870:	00000097          	auipc	ra,0x0
    80002874:	ecc080e7          	jalr	-308(ra) # 8000273c <devintr>
    80002878:	892a                	mv	s2,a0
    8000287a:	c501                	beqz	a0,80002882 <usertrap+0xa4>
  if(p->killed)
    8000287c:	589c                	lw	a5,48(s1)
    8000287e:	c3a1                	beqz	a5,800028be <usertrap+0xe0>
    80002880:	a815                	j	800028b4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002882:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002886:	5c90                	lw	a2,56(s1)
    80002888:	00006517          	auipc	a0,0x6
    8000288c:	a9050513          	addi	a0,a0,-1392 # 80008318 <states.1703+0x70>
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	d02080e7          	jalr	-766(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002898:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000289c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028a0:	00006517          	auipc	a0,0x6
    800028a4:	aa850513          	addi	a0,a0,-1368 # 80008348 <states.1703+0xa0>
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	cea080e7          	jalr	-790(ra) # 80000592 <printf>
    p->killed = 1;
    800028b0:	4785                	li	a5,1
    800028b2:	d89c                	sw	a5,48(s1)
    exit(-1);
    800028b4:	557d                	li	a0,-1
    800028b6:	fffff097          	auipc	ra,0xfffff
    800028ba:	7f6080e7          	jalr	2038(ra) # 800020ac <exit>
  if(which_dev == 2)
    800028be:	4789                	li	a5,2
    800028c0:	f8f910e3          	bne	s2,a5,80002840 <usertrap+0x62>
    yield();
    800028c4:	00000097          	auipc	ra,0x0
    800028c8:	8f2080e7          	jalr	-1806(ra) # 800021b6 <yield>
    800028cc:	bf95                	j	80002840 <usertrap+0x62>
  int which_dev = 0;
    800028ce:	4901                	li	s2,0
    800028d0:	b7d5                	j	800028b4 <usertrap+0xd6>

00000000800028d2 <kerneltrap>:
{
    800028d2:	7179                	addi	sp,sp,-48
    800028d4:	f406                	sd	ra,40(sp)
    800028d6:	f022                	sd	s0,32(sp)
    800028d8:	ec26                	sd	s1,24(sp)
    800028da:	e84a                	sd	s2,16(sp)
    800028dc:	e44e                	sd	s3,8(sp)
    800028de:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028e0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028ec:	1004f793          	andi	a5,s1,256
    800028f0:	cb85                	beqz	a5,80002920 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028f6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028f8:	ef85                	bnez	a5,80002930 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028fa:	00000097          	auipc	ra,0x0
    800028fe:	e42080e7          	jalr	-446(ra) # 8000273c <devintr>
    80002902:	cd1d                	beqz	a0,80002940 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002904:	4789                	li	a5,2
    80002906:	06f50a63          	beq	a0,a5,8000297a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000290a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290e:	10049073          	csrw	sstatus,s1
}
    80002912:	70a2                	ld	ra,40(sp)
    80002914:	7402                	ld	s0,32(sp)
    80002916:	64e2                	ld	s1,24(sp)
    80002918:	6942                	ld	s2,16(sp)
    8000291a:	69a2                	ld	s3,8(sp)
    8000291c:	6145                	addi	sp,sp,48
    8000291e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002920:	00006517          	auipc	a0,0x6
    80002924:	a4850513          	addi	a0,a0,-1464 # 80008368 <states.1703+0xc0>
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	c20080e7          	jalr	-992(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002930:	00006517          	auipc	a0,0x6
    80002934:	a6050513          	addi	a0,a0,-1440 # 80008390 <states.1703+0xe8>
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	c10080e7          	jalr	-1008(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002940:	85ce                	mv	a1,s3
    80002942:	00006517          	auipc	a0,0x6
    80002946:	a6e50513          	addi	a0,a0,-1426 # 800083b0 <states.1703+0x108>
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	c48080e7          	jalr	-952(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002952:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002956:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000295a:	00006517          	auipc	a0,0x6
    8000295e:	a6650513          	addi	a0,a0,-1434 # 800083c0 <states.1703+0x118>
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	c30080e7          	jalr	-976(ra) # 80000592 <printf>
    panic("kerneltrap");
    8000296a:	00006517          	auipc	a0,0x6
    8000296e:	a6e50513          	addi	a0,a0,-1426 # 800083d8 <states.1703+0x130>
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	bd6080e7          	jalr	-1066(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	064080e7          	jalr	100(ra) # 800019de <myproc>
    80002982:	d541                	beqz	a0,8000290a <kerneltrap+0x38>
    80002984:	fffff097          	auipc	ra,0xfffff
    80002988:	05a080e7          	jalr	90(ra) # 800019de <myproc>
    8000298c:	4d18                	lw	a4,24(a0)
    8000298e:	478d                	li	a5,3
    80002990:	f6f71de3          	bne	a4,a5,8000290a <kerneltrap+0x38>
    yield();
    80002994:	00000097          	auipc	ra,0x0
    80002998:	822080e7          	jalr	-2014(ra) # 800021b6 <yield>
    8000299c:	b7bd                	j	8000290a <kerneltrap+0x38>

000000008000299e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000299e:	1101                	addi	sp,sp,-32
    800029a0:	ec06                	sd	ra,24(sp)
    800029a2:	e822                	sd	s0,16(sp)
    800029a4:	e426                	sd	s1,8(sp)
    800029a6:	1000                	addi	s0,sp,32
    800029a8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029aa:	fffff097          	auipc	ra,0xfffff
    800029ae:	034080e7          	jalr	52(ra) # 800019de <myproc>
  switch (n) {
    800029b2:	4795                	li	a5,5
    800029b4:	0497e163          	bltu	a5,s1,800029f6 <argraw+0x58>
    800029b8:	048a                	slli	s1,s1,0x2
    800029ba:	00006717          	auipc	a4,0x6
    800029be:	b1670713          	addi	a4,a4,-1258 # 800084d0 <states.1703+0x228>
    800029c2:	94ba                	add	s1,s1,a4
    800029c4:	409c                	lw	a5,0(s1)
    800029c6:	97ba                	add	a5,a5,a4
    800029c8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029ca:	6d3c                	ld	a5,88(a0)
    800029cc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029ce:	60e2                	ld	ra,24(sp)
    800029d0:	6442                	ld	s0,16(sp)
    800029d2:	64a2                	ld	s1,8(sp)
    800029d4:	6105                	addi	sp,sp,32
    800029d6:	8082                	ret
    return p->trapframe->a1;
    800029d8:	6d3c                	ld	a5,88(a0)
    800029da:	7fa8                	ld	a0,120(a5)
    800029dc:	bfcd                	j	800029ce <argraw+0x30>
    return p->trapframe->a2;
    800029de:	6d3c                	ld	a5,88(a0)
    800029e0:	63c8                	ld	a0,128(a5)
    800029e2:	b7f5                	j	800029ce <argraw+0x30>
    return p->trapframe->a3;
    800029e4:	6d3c                	ld	a5,88(a0)
    800029e6:	67c8                	ld	a0,136(a5)
    800029e8:	b7dd                	j	800029ce <argraw+0x30>
    return p->trapframe->a4;
    800029ea:	6d3c                	ld	a5,88(a0)
    800029ec:	6bc8                	ld	a0,144(a5)
    800029ee:	b7c5                	j	800029ce <argraw+0x30>
    return p->trapframe->a5;
    800029f0:	6d3c                	ld	a5,88(a0)
    800029f2:	6fc8                	ld	a0,152(a5)
    800029f4:	bfe9                	j	800029ce <argraw+0x30>
  panic("argraw");
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	9f250513          	addi	a0,a0,-1550 # 800083e8 <states.1703+0x140>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b4a080e7          	jalr	-1206(ra) # 80000548 <panic>

0000000080002a06 <fetchaddr>:
{
    80002a06:	1101                	addi	sp,sp,-32
    80002a08:	ec06                	sd	ra,24(sp)
    80002a0a:	e822                	sd	s0,16(sp)
    80002a0c:	e426                	sd	s1,8(sp)
    80002a0e:	e04a                	sd	s2,0(sp)
    80002a10:	1000                	addi	s0,sp,32
    80002a12:	84aa                	mv	s1,a0
    80002a14:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a16:	fffff097          	auipc	ra,0xfffff
    80002a1a:	fc8080e7          	jalr	-56(ra) # 800019de <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a1e:	653c                	ld	a5,72(a0)
    80002a20:	02f4f863          	bgeu	s1,a5,80002a50 <fetchaddr+0x4a>
    80002a24:	00848713          	addi	a4,s1,8
    80002a28:	02e7e663          	bltu	a5,a4,80002a54 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a2c:	46a1                	li	a3,8
    80002a2e:	8626                	mv	a2,s1
    80002a30:	85ca                	mv	a1,s2
    80002a32:	6928                	ld	a0,80(a0)
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	d2a080e7          	jalr	-726(ra) # 8000175e <copyin>
    80002a3c:	00a03533          	snez	a0,a0
    80002a40:	40a00533          	neg	a0,a0
}
    80002a44:	60e2                	ld	ra,24(sp)
    80002a46:	6442                	ld	s0,16(sp)
    80002a48:	64a2                	ld	s1,8(sp)
    80002a4a:	6902                	ld	s2,0(sp)
    80002a4c:	6105                	addi	sp,sp,32
    80002a4e:	8082                	ret
    return -1;
    80002a50:	557d                	li	a0,-1
    80002a52:	bfcd                	j	80002a44 <fetchaddr+0x3e>
    80002a54:	557d                	li	a0,-1
    80002a56:	b7fd                	j	80002a44 <fetchaddr+0x3e>

0000000080002a58 <fetchstr>:
{
    80002a58:	7179                	addi	sp,sp,-48
    80002a5a:	f406                	sd	ra,40(sp)
    80002a5c:	f022                	sd	s0,32(sp)
    80002a5e:	ec26                	sd	s1,24(sp)
    80002a60:	e84a                	sd	s2,16(sp)
    80002a62:	e44e                	sd	s3,8(sp)
    80002a64:	1800                	addi	s0,sp,48
    80002a66:	892a                	mv	s2,a0
    80002a68:	84ae                	mv	s1,a1
    80002a6a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a6c:	fffff097          	auipc	ra,0xfffff
    80002a70:	f72080e7          	jalr	-142(ra) # 800019de <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a74:	86ce                	mv	a3,s3
    80002a76:	864a                	mv	a2,s2
    80002a78:	85a6                	mv	a1,s1
    80002a7a:	6928                	ld	a0,80(a0)
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	d6e080e7          	jalr	-658(ra) # 800017ea <copyinstr>
  if(err < 0)
    80002a84:	00054763          	bltz	a0,80002a92 <fetchstr+0x3a>
  return strlen(buf);
    80002a88:	8526                	mv	a0,s1
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	40a080e7          	jalr	1034(ra) # 80000e94 <strlen>
}
    80002a92:	70a2                	ld	ra,40(sp)
    80002a94:	7402                	ld	s0,32(sp)
    80002a96:	64e2                	ld	s1,24(sp)
    80002a98:	6942                	ld	s2,16(sp)
    80002a9a:	69a2                	ld	s3,8(sp)
    80002a9c:	6145                	addi	sp,sp,48
    80002a9e:	8082                	ret

0000000080002aa0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002aa0:	1101                	addi	sp,sp,-32
    80002aa2:	ec06                	sd	ra,24(sp)
    80002aa4:	e822                	sd	s0,16(sp)
    80002aa6:	e426                	sd	s1,8(sp)
    80002aa8:	1000                	addi	s0,sp,32
    80002aaa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	ef2080e7          	jalr	-270(ra) # 8000299e <argraw>
    80002ab4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002ab6:	4501                	li	a0,0
    80002ab8:	60e2                	ld	ra,24(sp)
    80002aba:	6442                	ld	s0,16(sp)
    80002abc:	64a2                	ld	s1,8(sp)
    80002abe:	6105                	addi	sp,sp,32
    80002ac0:	8082                	ret

0000000080002ac2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ac2:	1101                	addi	sp,sp,-32
    80002ac4:	ec06                	sd	ra,24(sp)
    80002ac6:	e822                	sd	s0,16(sp)
    80002ac8:	e426                	sd	s1,8(sp)
    80002aca:	1000                	addi	s0,sp,32
    80002acc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ace:	00000097          	auipc	ra,0x0
    80002ad2:	ed0080e7          	jalr	-304(ra) # 8000299e <argraw>
    80002ad6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ad8:	4501                	li	a0,0
    80002ada:	60e2                	ld	ra,24(sp)
    80002adc:	6442                	ld	s0,16(sp)
    80002ade:	64a2                	ld	s1,8(sp)
    80002ae0:	6105                	addi	sp,sp,32
    80002ae2:	8082                	ret

0000000080002ae4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ae4:	1101                	addi	sp,sp,-32
    80002ae6:	ec06                	sd	ra,24(sp)
    80002ae8:	e822                	sd	s0,16(sp)
    80002aea:	e426                	sd	s1,8(sp)
    80002aec:	e04a                	sd	s2,0(sp)
    80002aee:	1000                	addi	s0,sp,32
    80002af0:	84ae                	mv	s1,a1
    80002af2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002af4:	00000097          	auipc	ra,0x0
    80002af8:	eaa080e7          	jalr	-342(ra) # 8000299e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002afc:	864a                	mv	a2,s2
    80002afe:	85a6                	mv	a1,s1
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	f58080e7          	jalr	-168(ra) # 80002a58 <fetchstr>
}
    80002b08:	60e2                	ld	ra,24(sp)
    80002b0a:	6442                	ld	s0,16(sp)
    80002b0c:	64a2                	ld	s1,8(sp)
    80002b0e:	6902                	ld	s2,0(sp)
    80002b10:	6105                	addi	sp,sp,32
    80002b12:	8082                	ret

0000000080002b14 <syscall>:
[SYS_trace]   "trace",
};

void
syscall(void)
{
    80002b14:	7179                	addi	sp,sp,-48
    80002b16:	f406                	sd	ra,40(sp)
    80002b18:	f022                	sd	s0,32(sp)
    80002b1a:	ec26                	sd	s1,24(sp)
    80002b1c:	e84a                	sd	s2,16(sp)
    80002b1e:	e44e                	sd	s3,8(sp)
    80002b20:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002b22:	fffff097          	auipc	ra,0xfffff
    80002b26:	ebc080e7          	jalr	-324(ra) # 800019de <myproc>
    80002b2a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b2c:	05853903          	ld	s2,88(a0)
    80002b30:	0a893783          	ld	a5,168(s2)
    80002b34:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b38:	37fd                	addiw	a5,a5,-1
    80002b3a:	4755                	li	a4,21
    80002b3c:	04f76863          	bltu	a4,a5,80002b8c <syscall+0x78>
    80002b40:	00399713          	slli	a4,s3,0x3
    80002b44:	00006797          	auipc	a5,0x6
    80002b48:	9a478793          	addi	a5,a5,-1628 # 800084e8 <syscalls>
    80002b4c:	97ba                	add	a5,a5,a4
    80002b4e:	639c                	ld	a5,0(a5)
    80002b50:	cf95                	beqz	a5,80002b8c <syscall+0x78>
    p->trapframe->a0 = syscalls[num]();
    80002b52:	9782                	jalr	a5
    80002b54:	06a93823          	sd	a0,112(s2)
    if(1 << num & p->trace_mask) printf("%d: syscall %s -> %d\n", p->pid, syscalls_name[num], p->trapframe->a0);
    80002b58:	1684a783          	lw	a5,360(s1)
    80002b5c:	4137d7bb          	sraw	a5,a5,s3
    80002b60:	8b85                	andi	a5,a5,1
    80002b62:	c7a1                	beqz	a5,80002baa <syscall+0x96>
    80002b64:	6cb8                	ld	a4,88(s1)
    80002b66:	098e                	slli	s3,s3,0x3
    80002b68:	00006797          	auipc	a5,0x6
    80002b6c:	98078793          	addi	a5,a5,-1664 # 800084e8 <syscalls>
    80002b70:	99be                	add	s3,s3,a5
    80002b72:	7b34                	ld	a3,112(a4)
    80002b74:	0b89b603          	ld	a2,184(s3)
    80002b78:	5c8c                	lw	a1,56(s1)
    80002b7a:	00006517          	auipc	a0,0x6
    80002b7e:	87650513          	addi	a0,a0,-1930 # 800083f0 <states.1703+0x148>
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	a10080e7          	jalr	-1520(ra) # 80000592 <printf>
    80002b8a:	a005                	j	80002baa <syscall+0x96>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b8c:	86ce                	mv	a3,s3
    80002b8e:	15848613          	addi	a2,s1,344
    80002b92:	5c8c                	lw	a1,56(s1)
    80002b94:	00006517          	auipc	a0,0x6
    80002b98:	87450513          	addi	a0,a0,-1932 # 80008408 <states.1703+0x160>
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	9f6080e7          	jalr	-1546(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ba4:	6cbc                	ld	a5,88(s1)
    80002ba6:	577d                	li	a4,-1
    80002ba8:	fbb8                	sd	a4,112(a5)
  }
}
    80002baa:	70a2                	ld	ra,40(sp)
    80002bac:	7402                	ld	s0,32(sp)
    80002bae:	64e2                	ld	s1,24(sp)
    80002bb0:	6942                	ld	s2,16(sp)
    80002bb2:	69a2                	ld	s3,8(sp)
    80002bb4:	6145                	addi	sp,sp,48
    80002bb6:	8082                	ret

0000000080002bb8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002bb8:	1101                	addi	sp,sp,-32
    80002bba:	ec06                	sd	ra,24(sp)
    80002bbc:	e822                	sd	s0,16(sp)
    80002bbe:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002bc0:	fec40593          	addi	a1,s0,-20
    80002bc4:	4501                	li	a0,0
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	eda080e7          	jalr	-294(ra) # 80002aa0 <argint>
    return -1;
    80002bce:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002bd0:	00054963          	bltz	a0,80002be2 <sys_exit+0x2a>
  exit(n);
    80002bd4:	fec42503          	lw	a0,-20(s0)
    80002bd8:	fffff097          	auipc	ra,0xfffff
    80002bdc:	4d4080e7          	jalr	1236(ra) # 800020ac <exit>
  return 0;  // not reached
    80002be0:	4781                	li	a5,0
}
    80002be2:	853e                	mv	a0,a5
    80002be4:	60e2                	ld	ra,24(sp)
    80002be6:	6442                	ld	s0,16(sp)
    80002be8:	6105                	addi	sp,sp,32
    80002bea:	8082                	ret

0000000080002bec <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bec:	1141                	addi	sp,sp,-16
    80002bee:	e406                	sd	ra,8(sp)
    80002bf0:	e022                	sd	s0,0(sp)
    80002bf2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	dea080e7          	jalr	-534(ra) # 800019de <myproc>
}
    80002bfc:	5d08                	lw	a0,56(a0)
    80002bfe:	60a2                	ld	ra,8(sp)
    80002c00:	6402                	ld	s0,0(sp)
    80002c02:	0141                	addi	sp,sp,16
    80002c04:	8082                	ret

0000000080002c06 <sys_fork>:

uint64
sys_fork(void)
{
    80002c06:	1141                	addi	sp,sp,-16
    80002c08:	e406                	sd	ra,8(sp)
    80002c0a:	e022                	sd	s0,0(sp)
    80002c0c:	0800                	addi	s0,sp,16
  return fork();
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	190080e7          	jalr	400(ra) # 80001d9e <fork>
}
    80002c16:	60a2                	ld	ra,8(sp)
    80002c18:	6402                	ld	s0,0(sp)
    80002c1a:	0141                	addi	sp,sp,16
    80002c1c:	8082                	ret

0000000080002c1e <sys_wait>:

uint64
sys_wait(void)
{
    80002c1e:	1101                	addi	sp,sp,-32
    80002c20:	ec06                	sd	ra,24(sp)
    80002c22:	e822                	sd	s0,16(sp)
    80002c24:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c26:	fe840593          	addi	a1,s0,-24
    80002c2a:	4501                	li	a0,0
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	e96080e7          	jalr	-362(ra) # 80002ac2 <argaddr>
    80002c34:	87aa                	mv	a5,a0
    return -1;
    80002c36:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c38:	0007c863          	bltz	a5,80002c48 <sys_wait+0x2a>
  return wait(p);
    80002c3c:	fe843503          	ld	a0,-24(s0)
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	630080e7          	jalr	1584(ra) # 80002270 <wait>
}
    80002c48:	60e2                	ld	ra,24(sp)
    80002c4a:	6442                	ld	s0,16(sp)
    80002c4c:	6105                	addi	sp,sp,32
    80002c4e:	8082                	ret

0000000080002c50 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c50:	7179                	addi	sp,sp,-48
    80002c52:	f406                	sd	ra,40(sp)
    80002c54:	f022                	sd	s0,32(sp)
    80002c56:	ec26                	sd	s1,24(sp)
    80002c58:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c5a:	fdc40593          	addi	a1,s0,-36
    80002c5e:	4501                	li	a0,0
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	e40080e7          	jalr	-448(ra) # 80002aa0 <argint>
    80002c68:	87aa                	mv	a5,a0
    return -1;
    80002c6a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c6c:	0207c063          	bltz	a5,80002c8c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	d6e080e7          	jalr	-658(ra) # 800019de <myproc>
    80002c78:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c7a:	fdc42503          	lw	a0,-36(s0)
    80002c7e:	fffff097          	auipc	ra,0xfffff
    80002c82:	0ac080e7          	jalr	172(ra) # 80001d2a <growproc>
    80002c86:	00054863          	bltz	a0,80002c96 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c8a:	8526                	mv	a0,s1
}
    80002c8c:	70a2                	ld	ra,40(sp)
    80002c8e:	7402                	ld	s0,32(sp)
    80002c90:	64e2                	ld	s1,24(sp)
    80002c92:	6145                	addi	sp,sp,48
    80002c94:	8082                	ret
    return -1;
    80002c96:	557d                	li	a0,-1
    80002c98:	bfd5                	j	80002c8c <sys_sbrk+0x3c>

0000000080002c9a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c9a:	7139                	addi	sp,sp,-64
    80002c9c:	fc06                	sd	ra,56(sp)
    80002c9e:	f822                	sd	s0,48(sp)
    80002ca0:	f426                	sd	s1,40(sp)
    80002ca2:	f04a                	sd	s2,32(sp)
    80002ca4:	ec4e                	sd	s3,24(sp)
    80002ca6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ca8:	fcc40593          	addi	a1,s0,-52
    80002cac:	4501                	li	a0,0
    80002cae:	00000097          	auipc	ra,0x0
    80002cb2:	df2080e7          	jalr	-526(ra) # 80002aa0 <argint>
    return -1;
    80002cb6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cb8:	06054563          	bltz	a0,80002d22 <sys_sleep+0x88>
  acquire(&tickslock);
    80002cbc:	00015517          	auipc	a0,0x15
    80002cc0:	cac50513          	addi	a0,a0,-852 # 80017968 <tickslock>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	f4c080e7          	jalr	-180(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002ccc:	00006917          	auipc	s2,0x6
    80002cd0:	35492903          	lw	s2,852(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002cd4:	fcc42783          	lw	a5,-52(s0)
    80002cd8:	cf85                	beqz	a5,80002d10 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002cda:	00015997          	auipc	s3,0x15
    80002cde:	c8e98993          	addi	s3,s3,-882 # 80017968 <tickslock>
    80002ce2:	00006497          	auipc	s1,0x6
    80002ce6:	33e48493          	addi	s1,s1,830 # 80009020 <ticks>
    if(myproc()->killed){
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	cf4080e7          	jalr	-780(ra) # 800019de <myproc>
    80002cf2:	591c                	lw	a5,48(a0)
    80002cf4:	ef9d                	bnez	a5,80002d32 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cf6:	85ce                	mv	a1,s3
    80002cf8:	8526                	mv	a0,s1
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	4f8080e7          	jalr	1272(ra) # 800021f2 <sleep>
  while(ticks - ticks0 < n){
    80002d02:	409c                	lw	a5,0(s1)
    80002d04:	412787bb          	subw	a5,a5,s2
    80002d08:	fcc42703          	lw	a4,-52(s0)
    80002d0c:	fce7efe3          	bltu	a5,a4,80002cea <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d10:	00015517          	auipc	a0,0x15
    80002d14:	c5850513          	addi	a0,a0,-936 # 80017968 <tickslock>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	fac080e7          	jalr	-84(ra) # 80000cc4 <release>
  return 0;
    80002d20:	4781                	li	a5,0
}
    80002d22:	853e                	mv	a0,a5
    80002d24:	70e2                	ld	ra,56(sp)
    80002d26:	7442                	ld	s0,48(sp)
    80002d28:	74a2                	ld	s1,40(sp)
    80002d2a:	7902                	ld	s2,32(sp)
    80002d2c:	69e2                	ld	s3,24(sp)
    80002d2e:	6121                	addi	sp,sp,64
    80002d30:	8082                	ret
      release(&tickslock);
    80002d32:	00015517          	auipc	a0,0x15
    80002d36:	c3650513          	addi	a0,a0,-970 # 80017968 <tickslock>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	f8a080e7          	jalr	-118(ra) # 80000cc4 <release>
      return -1;
    80002d42:	57fd                	li	a5,-1
    80002d44:	bff9                	j	80002d22 <sys_sleep+0x88>

0000000080002d46 <sys_kill>:

uint64
sys_kill(void)
{
    80002d46:	1101                	addi	sp,sp,-32
    80002d48:	ec06                	sd	ra,24(sp)
    80002d4a:	e822                	sd	s0,16(sp)
    80002d4c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d4e:	fec40593          	addi	a1,s0,-20
    80002d52:	4501                	li	a0,0
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	d4c080e7          	jalr	-692(ra) # 80002aa0 <argint>
    80002d5c:	87aa                	mv	a5,a0
    return -1;
    80002d5e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d60:	0007c863          	bltz	a5,80002d70 <sys_kill+0x2a>
  return kill(pid);
    80002d64:	fec42503          	lw	a0,-20(s0)
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	67a080e7          	jalr	1658(ra) # 800023e2 <kill>
}
    80002d70:	60e2                	ld	ra,24(sp)
    80002d72:	6442                	ld	s0,16(sp)
    80002d74:	6105                	addi	sp,sp,32
    80002d76:	8082                	ret

0000000080002d78 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d78:	1101                	addi	sp,sp,-32
    80002d7a:	ec06                	sd	ra,24(sp)
    80002d7c:	e822                	sd	s0,16(sp)
    80002d7e:	e426                	sd	s1,8(sp)
    80002d80:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d82:	00015517          	auipc	a0,0x15
    80002d86:	be650513          	addi	a0,a0,-1050 # 80017968 <tickslock>
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	e86080e7          	jalr	-378(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002d92:	00006497          	auipc	s1,0x6
    80002d96:	28e4a483          	lw	s1,654(s1) # 80009020 <ticks>
  release(&tickslock);
    80002d9a:	00015517          	auipc	a0,0x15
    80002d9e:	bce50513          	addi	a0,a0,-1074 # 80017968 <tickslock>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	f22080e7          	jalr	-222(ra) # 80000cc4 <release>
  return xticks;
}
    80002daa:	02049513          	slli	a0,s1,0x20
    80002dae:	9101                	srli	a0,a0,0x20
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	64a2                	ld	s1,8(sp)
    80002db6:	6105                	addi	sp,sp,32
    80002db8:	8082                	ret

0000000080002dba <sys_trace>:

uint64
sys_trace(void)
{
    80002dba:	1141                	addi	sp,sp,-16
    80002dbc:	e406                	sd	ra,8(sp)
    80002dbe:	e022                	sd	s0,0(sp)
    80002dc0:	0800                	addi	s0,sp,16
  // printf("(XIII)exec kernel trace\n");
  argint(0, &(myproc()->trace_mask));
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	c1c080e7          	jalr	-996(ra) # 800019de <myproc>
    80002dca:	16850593          	addi	a1,a0,360
    80002dce:	4501                	li	a0,0
    80002dd0:	00000097          	auipc	ra,0x0
    80002dd4:	cd0080e7          	jalr	-816(ra) # 80002aa0 <argint>
  return 0;
}
    80002dd8:	4501                	li	a0,0
    80002dda:	60a2                	ld	ra,8(sp)
    80002ddc:	6402                	ld	s0,0(sp)
    80002dde:	0141                	addi	sp,sp,16
    80002de0:	8082                	ret

0000000080002de2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002de2:	7179                	addi	sp,sp,-48
    80002de4:	f406                	sd	ra,40(sp)
    80002de6:	f022                	sd	s0,32(sp)
    80002de8:	ec26                	sd	s1,24(sp)
    80002dea:	e84a                	sd	s2,16(sp)
    80002dec:	e44e                	sd	s3,8(sp)
    80002dee:	e052                	sd	s4,0(sp)
    80002df0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002df2:	00006597          	auipc	a1,0x6
    80002df6:	86658593          	addi	a1,a1,-1946 # 80008658 <syscalls_name+0xb8>
    80002dfa:	00015517          	auipc	a0,0x15
    80002dfe:	b8650513          	addi	a0,a0,-1146 # 80017980 <bcache>
    80002e02:	ffffe097          	auipc	ra,0xffffe
    80002e06:	d7e080e7          	jalr	-642(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e0a:	0001d797          	auipc	a5,0x1d
    80002e0e:	b7678793          	addi	a5,a5,-1162 # 8001f980 <bcache+0x8000>
    80002e12:	0001d717          	auipc	a4,0x1d
    80002e16:	dd670713          	addi	a4,a4,-554 # 8001fbe8 <bcache+0x8268>
    80002e1a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e1e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e22:	00015497          	auipc	s1,0x15
    80002e26:	b7648493          	addi	s1,s1,-1162 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002e2a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e2c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e2e:	00006a17          	auipc	s4,0x6
    80002e32:	832a0a13          	addi	s4,s4,-1998 # 80008660 <syscalls_name+0xc0>
    b->next = bcache.head.next;
    80002e36:	2b893783          	ld	a5,696(s2)
    80002e3a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e3c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e40:	85d2                	mv	a1,s4
    80002e42:	01048513          	addi	a0,s1,16
    80002e46:	00001097          	auipc	ra,0x1
    80002e4a:	4ac080e7          	jalr	1196(ra) # 800042f2 <initsleeplock>
    bcache.head.next->prev = b;
    80002e4e:	2b893783          	ld	a5,696(s2)
    80002e52:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e54:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e58:	45848493          	addi	s1,s1,1112
    80002e5c:	fd349de3          	bne	s1,s3,80002e36 <binit+0x54>
  }
}
    80002e60:	70a2                	ld	ra,40(sp)
    80002e62:	7402                	ld	s0,32(sp)
    80002e64:	64e2                	ld	s1,24(sp)
    80002e66:	6942                	ld	s2,16(sp)
    80002e68:	69a2                	ld	s3,8(sp)
    80002e6a:	6a02                	ld	s4,0(sp)
    80002e6c:	6145                	addi	sp,sp,48
    80002e6e:	8082                	ret

0000000080002e70 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e70:	7179                	addi	sp,sp,-48
    80002e72:	f406                	sd	ra,40(sp)
    80002e74:	f022                	sd	s0,32(sp)
    80002e76:	ec26                	sd	s1,24(sp)
    80002e78:	e84a                	sd	s2,16(sp)
    80002e7a:	e44e                	sd	s3,8(sp)
    80002e7c:	1800                	addi	s0,sp,48
    80002e7e:	89aa                	mv	s3,a0
    80002e80:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e82:	00015517          	auipc	a0,0x15
    80002e86:	afe50513          	addi	a0,a0,-1282 # 80017980 <bcache>
    80002e8a:	ffffe097          	auipc	ra,0xffffe
    80002e8e:	d86080e7          	jalr	-634(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e92:	0001d497          	auipc	s1,0x1d
    80002e96:	da64b483          	ld	s1,-602(s1) # 8001fc38 <bcache+0x82b8>
    80002e9a:	0001d797          	auipc	a5,0x1d
    80002e9e:	d4e78793          	addi	a5,a5,-690 # 8001fbe8 <bcache+0x8268>
    80002ea2:	02f48f63          	beq	s1,a5,80002ee0 <bread+0x70>
    80002ea6:	873e                	mv	a4,a5
    80002ea8:	a021                	j	80002eb0 <bread+0x40>
    80002eaa:	68a4                	ld	s1,80(s1)
    80002eac:	02e48a63          	beq	s1,a4,80002ee0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002eb0:	449c                	lw	a5,8(s1)
    80002eb2:	ff379ce3          	bne	a5,s3,80002eaa <bread+0x3a>
    80002eb6:	44dc                	lw	a5,12(s1)
    80002eb8:	ff2799e3          	bne	a5,s2,80002eaa <bread+0x3a>
      b->refcnt++;
    80002ebc:	40bc                	lw	a5,64(s1)
    80002ebe:	2785                	addiw	a5,a5,1
    80002ec0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ec2:	00015517          	auipc	a0,0x15
    80002ec6:	abe50513          	addi	a0,a0,-1346 # 80017980 <bcache>
    80002eca:	ffffe097          	auipc	ra,0xffffe
    80002ece:	dfa080e7          	jalr	-518(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002ed2:	01048513          	addi	a0,s1,16
    80002ed6:	00001097          	auipc	ra,0x1
    80002eda:	456080e7          	jalr	1110(ra) # 8000432c <acquiresleep>
      return b;
    80002ede:	a8b9                	j	80002f3c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ee0:	0001d497          	auipc	s1,0x1d
    80002ee4:	d504b483          	ld	s1,-688(s1) # 8001fc30 <bcache+0x82b0>
    80002ee8:	0001d797          	auipc	a5,0x1d
    80002eec:	d0078793          	addi	a5,a5,-768 # 8001fbe8 <bcache+0x8268>
    80002ef0:	00f48863          	beq	s1,a5,80002f00 <bread+0x90>
    80002ef4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ef6:	40bc                	lw	a5,64(s1)
    80002ef8:	cf81                	beqz	a5,80002f10 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002efa:	64a4                	ld	s1,72(s1)
    80002efc:	fee49de3          	bne	s1,a4,80002ef6 <bread+0x86>
  panic("bget: no buffers");
    80002f00:	00005517          	auipc	a0,0x5
    80002f04:	76850513          	addi	a0,a0,1896 # 80008668 <syscalls_name+0xc8>
    80002f08:	ffffd097          	auipc	ra,0xffffd
    80002f0c:	640080e7          	jalr	1600(ra) # 80000548 <panic>
      b->dev = dev;
    80002f10:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002f14:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002f18:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f1c:	4785                	li	a5,1
    80002f1e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f20:	00015517          	auipc	a0,0x15
    80002f24:	a6050513          	addi	a0,a0,-1440 # 80017980 <bcache>
    80002f28:	ffffe097          	auipc	ra,0xffffe
    80002f2c:	d9c080e7          	jalr	-612(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002f30:	01048513          	addi	a0,s1,16
    80002f34:	00001097          	auipc	ra,0x1
    80002f38:	3f8080e7          	jalr	1016(ra) # 8000432c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f3c:	409c                	lw	a5,0(s1)
    80002f3e:	cb89                	beqz	a5,80002f50 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f40:	8526                	mv	a0,s1
    80002f42:	70a2                	ld	ra,40(sp)
    80002f44:	7402                	ld	s0,32(sp)
    80002f46:	64e2                	ld	s1,24(sp)
    80002f48:	6942                	ld	s2,16(sp)
    80002f4a:	69a2                	ld	s3,8(sp)
    80002f4c:	6145                	addi	sp,sp,48
    80002f4e:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f50:	4581                	li	a1,0
    80002f52:	8526                	mv	a0,s1
    80002f54:	00003097          	auipc	ra,0x3
    80002f58:	f38080e7          	jalr	-200(ra) # 80005e8c <virtio_disk_rw>
    b->valid = 1;
    80002f5c:	4785                	li	a5,1
    80002f5e:	c09c                	sw	a5,0(s1)
  return b;
    80002f60:	b7c5                	j	80002f40 <bread+0xd0>

0000000080002f62 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f62:	1101                	addi	sp,sp,-32
    80002f64:	ec06                	sd	ra,24(sp)
    80002f66:	e822                	sd	s0,16(sp)
    80002f68:	e426                	sd	s1,8(sp)
    80002f6a:	1000                	addi	s0,sp,32
    80002f6c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f6e:	0541                	addi	a0,a0,16
    80002f70:	00001097          	auipc	ra,0x1
    80002f74:	456080e7          	jalr	1110(ra) # 800043c6 <holdingsleep>
    80002f78:	cd01                	beqz	a0,80002f90 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f7a:	4585                	li	a1,1
    80002f7c:	8526                	mv	a0,s1
    80002f7e:	00003097          	auipc	ra,0x3
    80002f82:	f0e080e7          	jalr	-242(ra) # 80005e8c <virtio_disk_rw>
}
    80002f86:	60e2                	ld	ra,24(sp)
    80002f88:	6442                	ld	s0,16(sp)
    80002f8a:	64a2                	ld	s1,8(sp)
    80002f8c:	6105                	addi	sp,sp,32
    80002f8e:	8082                	ret
    panic("bwrite");
    80002f90:	00005517          	auipc	a0,0x5
    80002f94:	6f050513          	addi	a0,a0,1776 # 80008680 <syscalls_name+0xe0>
    80002f98:	ffffd097          	auipc	ra,0xffffd
    80002f9c:	5b0080e7          	jalr	1456(ra) # 80000548 <panic>

0000000080002fa0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fa0:	1101                	addi	sp,sp,-32
    80002fa2:	ec06                	sd	ra,24(sp)
    80002fa4:	e822                	sd	s0,16(sp)
    80002fa6:	e426                	sd	s1,8(sp)
    80002fa8:	e04a                	sd	s2,0(sp)
    80002faa:	1000                	addi	s0,sp,32
    80002fac:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fae:	01050913          	addi	s2,a0,16
    80002fb2:	854a                	mv	a0,s2
    80002fb4:	00001097          	auipc	ra,0x1
    80002fb8:	412080e7          	jalr	1042(ra) # 800043c6 <holdingsleep>
    80002fbc:	c92d                	beqz	a0,8000302e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fbe:	854a                	mv	a0,s2
    80002fc0:	00001097          	auipc	ra,0x1
    80002fc4:	3c2080e7          	jalr	962(ra) # 80004382 <releasesleep>

  acquire(&bcache.lock);
    80002fc8:	00015517          	auipc	a0,0x15
    80002fcc:	9b850513          	addi	a0,a0,-1608 # 80017980 <bcache>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	c40080e7          	jalr	-960(ra) # 80000c10 <acquire>
  b->refcnt--;
    80002fd8:	40bc                	lw	a5,64(s1)
    80002fda:	37fd                	addiw	a5,a5,-1
    80002fdc:	0007871b          	sext.w	a4,a5
    80002fe0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fe2:	eb05                	bnez	a4,80003012 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fe4:	68bc                	ld	a5,80(s1)
    80002fe6:	64b8                	ld	a4,72(s1)
    80002fe8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fea:	64bc                	ld	a5,72(s1)
    80002fec:	68b8                	ld	a4,80(s1)
    80002fee:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002ff0:	0001d797          	auipc	a5,0x1d
    80002ff4:	99078793          	addi	a5,a5,-1648 # 8001f980 <bcache+0x8000>
    80002ff8:	2b87b703          	ld	a4,696(a5)
    80002ffc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002ffe:	0001d717          	auipc	a4,0x1d
    80003002:	bea70713          	addi	a4,a4,-1046 # 8001fbe8 <bcache+0x8268>
    80003006:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003008:	2b87b703          	ld	a4,696(a5)
    8000300c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000300e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003012:	00015517          	auipc	a0,0x15
    80003016:	96e50513          	addi	a0,a0,-1682 # 80017980 <bcache>
    8000301a:	ffffe097          	auipc	ra,0xffffe
    8000301e:	caa080e7          	jalr	-854(ra) # 80000cc4 <release>
}
    80003022:	60e2                	ld	ra,24(sp)
    80003024:	6442                	ld	s0,16(sp)
    80003026:	64a2                	ld	s1,8(sp)
    80003028:	6902                	ld	s2,0(sp)
    8000302a:	6105                	addi	sp,sp,32
    8000302c:	8082                	ret
    panic("brelse");
    8000302e:	00005517          	auipc	a0,0x5
    80003032:	65a50513          	addi	a0,a0,1626 # 80008688 <syscalls_name+0xe8>
    80003036:	ffffd097          	auipc	ra,0xffffd
    8000303a:	512080e7          	jalr	1298(ra) # 80000548 <panic>

000000008000303e <bpin>:

void
bpin(struct buf *b) {
    8000303e:	1101                	addi	sp,sp,-32
    80003040:	ec06                	sd	ra,24(sp)
    80003042:	e822                	sd	s0,16(sp)
    80003044:	e426                	sd	s1,8(sp)
    80003046:	1000                	addi	s0,sp,32
    80003048:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000304a:	00015517          	auipc	a0,0x15
    8000304e:	93650513          	addi	a0,a0,-1738 # 80017980 <bcache>
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	bbe080e7          	jalr	-1090(ra) # 80000c10 <acquire>
  b->refcnt++;
    8000305a:	40bc                	lw	a5,64(s1)
    8000305c:	2785                	addiw	a5,a5,1
    8000305e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003060:	00015517          	auipc	a0,0x15
    80003064:	92050513          	addi	a0,a0,-1760 # 80017980 <bcache>
    80003068:	ffffe097          	auipc	ra,0xffffe
    8000306c:	c5c080e7          	jalr	-932(ra) # 80000cc4 <release>
}
    80003070:	60e2                	ld	ra,24(sp)
    80003072:	6442                	ld	s0,16(sp)
    80003074:	64a2                	ld	s1,8(sp)
    80003076:	6105                	addi	sp,sp,32
    80003078:	8082                	ret

000000008000307a <bunpin>:

void
bunpin(struct buf *b) {
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	e426                	sd	s1,8(sp)
    80003082:	1000                	addi	s0,sp,32
    80003084:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003086:	00015517          	auipc	a0,0x15
    8000308a:	8fa50513          	addi	a0,a0,-1798 # 80017980 <bcache>
    8000308e:	ffffe097          	auipc	ra,0xffffe
    80003092:	b82080e7          	jalr	-1150(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003096:	40bc                	lw	a5,64(s1)
    80003098:	37fd                	addiw	a5,a5,-1
    8000309a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000309c:	00015517          	auipc	a0,0x15
    800030a0:	8e450513          	addi	a0,a0,-1820 # 80017980 <bcache>
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	c20080e7          	jalr	-992(ra) # 80000cc4 <release>
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	64a2                	ld	s1,8(sp)
    800030b2:	6105                	addi	sp,sp,32
    800030b4:	8082                	ret

00000000800030b6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030b6:	1101                	addi	sp,sp,-32
    800030b8:	ec06                	sd	ra,24(sp)
    800030ba:	e822                	sd	s0,16(sp)
    800030bc:	e426                	sd	s1,8(sp)
    800030be:	e04a                	sd	s2,0(sp)
    800030c0:	1000                	addi	s0,sp,32
    800030c2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030c4:	00d5d59b          	srliw	a1,a1,0xd
    800030c8:	0001d797          	auipc	a5,0x1d
    800030cc:	f947a783          	lw	a5,-108(a5) # 8002005c <sb+0x1c>
    800030d0:	9dbd                	addw	a1,a1,a5
    800030d2:	00000097          	auipc	ra,0x0
    800030d6:	d9e080e7          	jalr	-610(ra) # 80002e70 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030da:	0074f713          	andi	a4,s1,7
    800030de:	4785                	li	a5,1
    800030e0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030e4:	14ce                	slli	s1,s1,0x33
    800030e6:	90d9                	srli	s1,s1,0x36
    800030e8:	00950733          	add	a4,a0,s1
    800030ec:	05874703          	lbu	a4,88(a4)
    800030f0:	00e7f6b3          	and	a3,a5,a4
    800030f4:	c69d                	beqz	a3,80003122 <bfree+0x6c>
    800030f6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030f8:	94aa                	add	s1,s1,a0
    800030fa:	fff7c793          	not	a5,a5
    800030fe:	8ff9                	and	a5,a5,a4
    80003100:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003104:	00001097          	auipc	ra,0x1
    80003108:	100080e7          	jalr	256(ra) # 80004204 <log_write>
  brelse(bp);
    8000310c:	854a                	mv	a0,s2
    8000310e:	00000097          	auipc	ra,0x0
    80003112:	e92080e7          	jalr	-366(ra) # 80002fa0 <brelse>
}
    80003116:	60e2                	ld	ra,24(sp)
    80003118:	6442                	ld	s0,16(sp)
    8000311a:	64a2                	ld	s1,8(sp)
    8000311c:	6902                	ld	s2,0(sp)
    8000311e:	6105                	addi	sp,sp,32
    80003120:	8082                	ret
    panic("freeing free block");
    80003122:	00005517          	auipc	a0,0x5
    80003126:	56e50513          	addi	a0,a0,1390 # 80008690 <syscalls_name+0xf0>
    8000312a:	ffffd097          	auipc	ra,0xffffd
    8000312e:	41e080e7          	jalr	1054(ra) # 80000548 <panic>

0000000080003132 <balloc>:
{
    80003132:	711d                	addi	sp,sp,-96
    80003134:	ec86                	sd	ra,88(sp)
    80003136:	e8a2                	sd	s0,80(sp)
    80003138:	e4a6                	sd	s1,72(sp)
    8000313a:	e0ca                	sd	s2,64(sp)
    8000313c:	fc4e                	sd	s3,56(sp)
    8000313e:	f852                	sd	s4,48(sp)
    80003140:	f456                	sd	s5,40(sp)
    80003142:	f05a                	sd	s6,32(sp)
    80003144:	ec5e                	sd	s7,24(sp)
    80003146:	e862                	sd	s8,16(sp)
    80003148:	e466                	sd	s9,8(sp)
    8000314a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000314c:	0001d797          	auipc	a5,0x1d
    80003150:	ef87a783          	lw	a5,-264(a5) # 80020044 <sb+0x4>
    80003154:	cbd1                	beqz	a5,800031e8 <balloc+0xb6>
    80003156:	8baa                	mv	s7,a0
    80003158:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000315a:	0001db17          	auipc	s6,0x1d
    8000315e:	ee6b0b13          	addi	s6,s6,-282 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003162:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003164:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003166:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003168:	6c89                	lui	s9,0x2
    8000316a:	a831                	j	80003186 <balloc+0x54>
    brelse(bp);
    8000316c:	854a                	mv	a0,s2
    8000316e:	00000097          	auipc	ra,0x0
    80003172:	e32080e7          	jalr	-462(ra) # 80002fa0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003176:	015c87bb          	addw	a5,s9,s5
    8000317a:	00078a9b          	sext.w	s5,a5
    8000317e:	004b2703          	lw	a4,4(s6)
    80003182:	06eaf363          	bgeu	s5,a4,800031e8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003186:	41fad79b          	sraiw	a5,s5,0x1f
    8000318a:	0137d79b          	srliw	a5,a5,0x13
    8000318e:	015787bb          	addw	a5,a5,s5
    80003192:	40d7d79b          	sraiw	a5,a5,0xd
    80003196:	01cb2583          	lw	a1,28(s6)
    8000319a:	9dbd                	addw	a1,a1,a5
    8000319c:	855e                	mv	a0,s7
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	cd2080e7          	jalr	-814(ra) # 80002e70 <bread>
    800031a6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031a8:	004b2503          	lw	a0,4(s6)
    800031ac:	000a849b          	sext.w	s1,s5
    800031b0:	8662                	mv	a2,s8
    800031b2:	faa4fde3          	bgeu	s1,a0,8000316c <balloc+0x3a>
      m = 1 << (bi % 8);
    800031b6:	41f6579b          	sraiw	a5,a2,0x1f
    800031ba:	01d7d69b          	srliw	a3,a5,0x1d
    800031be:	00c6873b          	addw	a4,a3,a2
    800031c2:	00777793          	andi	a5,a4,7
    800031c6:	9f95                	subw	a5,a5,a3
    800031c8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031cc:	4037571b          	sraiw	a4,a4,0x3
    800031d0:	00e906b3          	add	a3,s2,a4
    800031d4:	0586c683          	lbu	a3,88(a3)
    800031d8:	00d7f5b3          	and	a1,a5,a3
    800031dc:	cd91                	beqz	a1,800031f8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031de:	2605                	addiw	a2,a2,1
    800031e0:	2485                	addiw	s1,s1,1
    800031e2:	fd4618e3          	bne	a2,s4,800031b2 <balloc+0x80>
    800031e6:	b759                	j	8000316c <balloc+0x3a>
  panic("balloc: out of blocks");
    800031e8:	00005517          	auipc	a0,0x5
    800031ec:	4c050513          	addi	a0,a0,1216 # 800086a8 <syscalls_name+0x108>
    800031f0:	ffffd097          	auipc	ra,0xffffd
    800031f4:	358080e7          	jalr	856(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031f8:	974a                	add	a4,a4,s2
    800031fa:	8fd5                	or	a5,a5,a3
    800031fc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003200:	854a                	mv	a0,s2
    80003202:	00001097          	auipc	ra,0x1
    80003206:	002080e7          	jalr	2(ra) # 80004204 <log_write>
        brelse(bp);
    8000320a:	854a                	mv	a0,s2
    8000320c:	00000097          	auipc	ra,0x0
    80003210:	d94080e7          	jalr	-620(ra) # 80002fa0 <brelse>
  bp = bread(dev, bno);
    80003214:	85a6                	mv	a1,s1
    80003216:	855e                	mv	a0,s7
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	c58080e7          	jalr	-936(ra) # 80002e70 <bread>
    80003220:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003222:	40000613          	li	a2,1024
    80003226:	4581                	li	a1,0
    80003228:	05850513          	addi	a0,a0,88
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	ae0080e7          	jalr	-1312(ra) # 80000d0c <memset>
  log_write(bp);
    80003234:	854a                	mv	a0,s2
    80003236:	00001097          	auipc	ra,0x1
    8000323a:	fce080e7          	jalr	-50(ra) # 80004204 <log_write>
  brelse(bp);
    8000323e:	854a                	mv	a0,s2
    80003240:	00000097          	auipc	ra,0x0
    80003244:	d60080e7          	jalr	-672(ra) # 80002fa0 <brelse>
}
    80003248:	8526                	mv	a0,s1
    8000324a:	60e6                	ld	ra,88(sp)
    8000324c:	6446                	ld	s0,80(sp)
    8000324e:	64a6                	ld	s1,72(sp)
    80003250:	6906                	ld	s2,64(sp)
    80003252:	79e2                	ld	s3,56(sp)
    80003254:	7a42                	ld	s4,48(sp)
    80003256:	7aa2                	ld	s5,40(sp)
    80003258:	7b02                	ld	s6,32(sp)
    8000325a:	6be2                	ld	s7,24(sp)
    8000325c:	6c42                	ld	s8,16(sp)
    8000325e:	6ca2                	ld	s9,8(sp)
    80003260:	6125                	addi	sp,sp,96
    80003262:	8082                	ret

0000000080003264 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003264:	7179                	addi	sp,sp,-48
    80003266:	f406                	sd	ra,40(sp)
    80003268:	f022                	sd	s0,32(sp)
    8000326a:	ec26                	sd	s1,24(sp)
    8000326c:	e84a                	sd	s2,16(sp)
    8000326e:	e44e                	sd	s3,8(sp)
    80003270:	e052                	sd	s4,0(sp)
    80003272:	1800                	addi	s0,sp,48
    80003274:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003276:	47ad                	li	a5,11
    80003278:	04b7fe63          	bgeu	a5,a1,800032d4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000327c:	ff45849b          	addiw	s1,a1,-12
    80003280:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003284:	0ff00793          	li	a5,255
    80003288:	0ae7e363          	bltu	a5,a4,8000332e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000328c:	08052583          	lw	a1,128(a0)
    80003290:	c5ad                	beqz	a1,800032fa <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003292:	00092503          	lw	a0,0(s2)
    80003296:	00000097          	auipc	ra,0x0
    8000329a:	bda080e7          	jalr	-1062(ra) # 80002e70 <bread>
    8000329e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032a0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032a4:	02049593          	slli	a1,s1,0x20
    800032a8:	9181                	srli	a1,a1,0x20
    800032aa:	058a                	slli	a1,a1,0x2
    800032ac:	00b784b3          	add	s1,a5,a1
    800032b0:	0004a983          	lw	s3,0(s1)
    800032b4:	04098d63          	beqz	s3,8000330e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800032b8:	8552                	mv	a0,s4
    800032ba:	00000097          	auipc	ra,0x0
    800032be:	ce6080e7          	jalr	-794(ra) # 80002fa0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032c2:	854e                	mv	a0,s3
    800032c4:	70a2                	ld	ra,40(sp)
    800032c6:	7402                	ld	s0,32(sp)
    800032c8:	64e2                	ld	s1,24(sp)
    800032ca:	6942                	ld	s2,16(sp)
    800032cc:	69a2                	ld	s3,8(sp)
    800032ce:	6a02                	ld	s4,0(sp)
    800032d0:	6145                	addi	sp,sp,48
    800032d2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800032d4:	02059493          	slli	s1,a1,0x20
    800032d8:	9081                	srli	s1,s1,0x20
    800032da:	048a                	slli	s1,s1,0x2
    800032dc:	94aa                	add	s1,s1,a0
    800032de:	0504a983          	lw	s3,80(s1)
    800032e2:	fe0990e3          	bnez	s3,800032c2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032e6:	4108                	lw	a0,0(a0)
    800032e8:	00000097          	auipc	ra,0x0
    800032ec:	e4a080e7          	jalr	-438(ra) # 80003132 <balloc>
    800032f0:	0005099b          	sext.w	s3,a0
    800032f4:	0534a823          	sw	s3,80(s1)
    800032f8:	b7e9                	j	800032c2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032fa:	4108                	lw	a0,0(a0)
    800032fc:	00000097          	auipc	ra,0x0
    80003300:	e36080e7          	jalr	-458(ra) # 80003132 <balloc>
    80003304:	0005059b          	sext.w	a1,a0
    80003308:	08b92023          	sw	a1,128(s2)
    8000330c:	b759                	j	80003292 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000330e:	00092503          	lw	a0,0(s2)
    80003312:	00000097          	auipc	ra,0x0
    80003316:	e20080e7          	jalr	-480(ra) # 80003132 <balloc>
    8000331a:	0005099b          	sext.w	s3,a0
    8000331e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003322:	8552                	mv	a0,s4
    80003324:	00001097          	auipc	ra,0x1
    80003328:	ee0080e7          	jalr	-288(ra) # 80004204 <log_write>
    8000332c:	b771                	j	800032b8 <bmap+0x54>
  panic("bmap: out of range");
    8000332e:	00005517          	auipc	a0,0x5
    80003332:	39250513          	addi	a0,a0,914 # 800086c0 <syscalls_name+0x120>
    80003336:	ffffd097          	auipc	ra,0xffffd
    8000333a:	212080e7          	jalr	530(ra) # 80000548 <panic>

000000008000333e <iget>:
{
    8000333e:	7179                	addi	sp,sp,-48
    80003340:	f406                	sd	ra,40(sp)
    80003342:	f022                	sd	s0,32(sp)
    80003344:	ec26                	sd	s1,24(sp)
    80003346:	e84a                	sd	s2,16(sp)
    80003348:	e44e                	sd	s3,8(sp)
    8000334a:	e052                	sd	s4,0(sp)
    8000334c:	1800                	addi	s0,sp,48
    8000334e:	89aa                	mv	s3,a0
    80003350:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003352:	0001d517          	auipc	a0,0x1d
    80003356:	d0e50513          	addi	a0,a0,-754 # 80020060 <icache>
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	8b6080e7          	jalr	-1866(ra) # 80000c10 <acquire>
  empty = 0;
    80003362:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003364:	0001d497          	auipc	s1,0x1d
    80003368:	d1448493          	addi	s1,s1,-748 # 80020078 <icache+0x18>
    8000336c:	0001e697          	auipc	a3,0x1e
    80003370:	79c68693          	addi	a3,a3,1948 # 80021b08 <log>
    80003374:	a039                	j	80003382 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003376:	02090b63          	beqz	s2,800033ac <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000337a:	08848493          	addi	s1,s1,136
    8000337e:	02d48a63          	beq	s1,a3,800033b2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003382:	449c                	lw	a5,8(s1)
    80003384:	fef059e3          	blez	a5,80003376 <iget+0x38>
    80003388:	4098                	lw	a4,0(s1)
    8000338a:	ff3716e3          	bne	a4,s3,80003376 <iget+0x38>
    8000338e:	40d8                	lw	a4,4(s1)
    80003390:	ff4713e3          	bne	a4,s4,80003376 <iget+0x38>
      ip->ref++;
    80003394:	2785                	addiw	a5,a5,1
    80003396:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003398:	0001d517          	auipc	a0,0x1d
    8000339c:	cc850513          	addi	a0,a0,-824 # 80020060 <icache>
    800033a0:	ffffe097          	auipc	ra,0xffffe
    800033a4:	924080e7          	jalr	-1756(ra) # 80000cc4 <release>
      return ip;
    800033a8:	8926                	mv	s2,s1
    800033aa:	a03d                	j	800033d8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ac:	f7f9                	bnez	a5,8000337a <iget+0x3c>
    800033ae:	8926                	mv	s2,s1
    800033b0:	b7e9                	j	8000337a <iget+0x3c>
  if(empty == 0)
    800033b2:	02090c63          	beqz	s2,800033ea <iget+0xac>
  ip->dev = dev;
    800033b6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033ba:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033be:	4785                	li	a5,1
    800033c0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033c4:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800033c8:	0001d517          	auipc	a0,0x1d
    800033cc:	c9850513          	addi	a0,a0,-872 # 80020060 <icache>
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	8f4080e7          	jalr	-1804(ra) # 80000cc4 <release>
}
    800033d8:	854a                	mv	a0,s2
    800033da:	70a2                	ld	ra,40(sp)
    800033dc:	7402                	ld	s0,32(sp)
    800033de:	64e2                	ld	s1,24(sp)
    800033e0:	6942                	ld	s2,16(sp)
    800033e2:	69a2                	ld	s3,8(sp)
    800033e4:	6a02                	ld	s4,0(sp)
    800033e6:	6145                	addi	sp,sp,48
    800033e8:	8082                	ret
    panic("iget: no inodes");
    800033ea:	00005517          	auipc	a0,0x5
    800033ee:	2ee50513          	addi	a0,a0,750 # 800086d8 <syscalls_name+0x138>
    800033f2:	ffffd097          	auipc	ra,0xffffd
    800033f6:	156080e7          	jalr	342(ra) # 80000548 <panic>

00000000800033fa <fsinit>:
fsinit(int dev) {
    800033fa:	7179                	addi	sp,sp,-48
    800033fc:	f406                	sd	ra,40(sp)
    800033fe:	f022                	sd	s0,32(sp)
    80003400:	ec26                	sd	s1,24(sp)
    80003402:	e84a                	sd	s2,16(sp)
    80003404:	e44e                	sd	s3,8(sp)
    80003406:	1800                	addi	s0,sp,48
    80003408:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000340a:	4585                	li	a1,1
    8000340c:	00000097          	auipc	ra,0x0
    80003410:	a64080e7          	jalr	-1436(ra) # 80002e70 <bread>
    80003414:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003416:	0001d997          	auipc	s3,0x1d
    8000341a:	c2a98993          	addi	s3,s3,-982 # 80020040 <sb>
    8000341e:	02000613          	li	a2,32
    80003422:	05850593          	addi	a1,a0,88
    80003426:	854e                	mv	a0,s3
    80003428:	ffffe097          	auipc	ra,0xffffe
    8000342c:	944080e7          	jalr	-1724(ra) # 80000d6c <memmove>
  brelse(bp);
    80003430:	8526                	mv	a0,s1
    80003432:	00000097          	auipc	ra,0x0
    80003436:	b6e080e7          	jalr	-1170(ra) # 80002fa0 <brelse>
  if(sb.magic != FSMAGIC)
    8000343a:	0009a703          	lw	a4,0(s3)
    8000343e:	102037b7          	lui	a5,0x10203
    80003442:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003446:	02f71263          	bne	a4,a5,8000346a <fsinit+0x70>
  initlog(dev, &sb);
    8000344a:	0001d597          	auipc	a1,0x1d
    8000344e:	bf658593          	addi	a1,a1,-1034 # 80020040 <sb>
    80003452:	854a                	mv	a0,s2
    80003454:	00001097          	auipc	ra,0x1
    80003458:	b38080e7          	jalr	-1224(ra) # 80003f8c <initlog>
}
    8000345c:	70a2                	ld	ra,40(sp)
    8000345e:	7402                	ld	s0,32(sp)
    80003460:	64e2                	ld	s1,24(sp)
    80003462:	6942                	ld	s2,16(sp)
    80003464:	69a2                	ld	s3,8(sp)
    80003466:	6145                	addi	sp,sp,48
    80003468:	8082                	ret
    panic("invalid file system");
    8000346a:	00005517          	auipc	a0,0x5
    8000346e:	27e50513          	addi	a0,a0,638 # 800086e8 <syscalls_name+0x148>
    80003472:	ffffd097          	auipc	ra,0xffffd
    80003476:	0d6080e7          	jalr	214(ra) # 80000548 <panic>

000000008000347a <iinit>:
{
    8000347a:	7179                	addi	sp,sp,-48
    8000347c:	f406                	sd	ra,40(sp)
    8000347e:	f022                	sd	s0,32(sp)
    80003480:	ec26                	sd	s1,24(sp)
    80003482:	e84a                	sd	s2,16(sp)
    80003484:	e44e                	sd	s3,8(sp)
    80003486:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003488:	00005597          	auipc	a1,0x5
    8000348c:	27858593          	addi	a1,a1,632 # 80008700 <syscalls_name+0x160>
    80003490:	0001d517          	auipc	a0,0x1d
    80003494:	bd050513          	addi	a0,a0,-1072 # 80020060 <icache>
    80003498:	ffffd097          	auipc	ra,0xffffd
    8000349c:	6e8080e7          	jalr	1768(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034a0:	0001d497          	auipc	s1,0x1d
    800034a4:	be848493          	addi	s1,s1,-1048 # 80020088 <icache+0x28>
    800034a8:	0001e997          	auipc	s3,0x1e
    800034ac:	67098993          	addi	s3,s3,1648 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800034b0:	00005917          	auipc	s2,0x5
    800034b4:	25890913          	addi	s2,s2,600 # 80008708 <syscalls_name+0x168>
    800034b8:	85ca                	mv	a1,s2
    800034ba:	8526                	mv	a0,s1
    800034bc:	00001097          	auipc	ra,0x1
    800034c0:	e36080e7          	jalr	-458(ra) # 800042f2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034c4:	08848493          	addi	s1,s1,136
    800034c8:	ff3498e3          	bne	s1,s3,800034b8 <iinit+0x3e>
}
    800034cc:	70a2                	ld	ra,40(sp)
    800034ce:	7402                	ld	s0,32(sp)
    800034d0:	64e2                	ld	s1,24(sp)
    800034d2:	6942                	ld	s2,16(sp)
    800034d4:	69a2                	ld	s3,8(sp)
    800034d6:	6145                	addi	sp,sp,48
    800034d8:	8082                	ret

00000000800034da <ialloc>:
{
    800034da:	715d                	addi	sp,sp,-80
    800034dc:	e486                	sd	ra,72(sp)
    800034de:	e0a2                	sd	s0,64(sp)
    800034e0:	fc26                	sd	s1,56(sp)
    800034e2:	f84a                	sd	s2,48(sp)
    800034e4:	f44e                	sd	s3,40(sp)
    800034e6:	f052                	sd	s4,32(sp)
    800034e8:	ec56                	sd	s5,24(sp)
    800034ea:	e85a                	sd	s6,16(sp)
    800034ec:	e45e                	sd	s7,8(sp)
    800034ee:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034f0:	0001d717          	auipc	a4,0x1d
    800034f4:	b5c72703          	lw	a4,-1188(a4) # 8002004c <sb+0xc>
    800034f8:	4785                	li	a5,1
    800034fa:	04e7fa63          	bgeu	a5,a4,8000354e <ialloc+0x74>
    800034fe:	8aaa                	mv	s5,a0
    80003500:	8bae                	mv	s7,a1
    80003502:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003504:	0001da17          	auipc	s4,0x1d
    80003508:	b3ca0a13          	addi	s4,s4,-1220 # 80020040 <sb>
    8000350c:	00048b1b          	sext.w	s6,s1
    80003510:	0044d593          	srli	a1,s1,0x4
    80003514:	018a2783          	lw	a5,24(s4)
    80003518:	9dbd                	addw	a1,a1,a5
    8000351a:	8556                	mv	a0,s5
    8000351c:	00000097          	auipc	ra,0x0
    80003520:	954080e7          	jalr	-1708(ra) # 80002e70 <bread>
    80003524:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003526:	05850993          	addi	s3,a0,88
    8000352a:	00f4f793          	andi	a5,s1,15
    8000352e:	079a                	slli	a5,a5,0x6
    80003530:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003532:	00099783          	lh	a5,0(s3)
    80003536:	c785                	beqz	a5,8000355e <ialloc+0x84>
    brelse(bp);
    80003538:	00000097          	auipc	ra,0x0
    8000353c:	a68080e7          	jalr	-1432(ra) # 80002fa0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003540:	0485                	addi	s1,s1,1
    80003542:	00ca2703          	lw	a4,12(s4)
    80003546:	0004879b          	sext.w	a5,s1
    8000354a:	fce7e1e3          	bltu	a5,a4,8000350c <ialloc+0x32>
  panic("ialloc: no inodes");
    8000354e:	00005517          	auipc	a0,0x5
    80003552:	1c250513          	addi	a0,a0,450 # 80008710 <syscalls_name+0x170>
    80003556:	ffffd097          	auipc	ra,0xffffd
    8000355a:	ff2080e7          	jalr	-14(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    8000355e:	04000613          	li	a2,64
    80003562:	4581                	li	a1,0
    80003564:	854e                	mv	a0,s3
    80003566:	ffffd097          	auipc	ra,0xffffd
    8000356a:	7a6080e7          	jalr	1958(ra) # 80000d0c <memset>
      dip->type = type;
    8000356e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003572:	854a                	mv	a0,s2
    80003574:	00001097          	auipc	ra,0x1
    80003578:	c90080e7          	jalr	-880(ra) # 80004204 <log_write>
      brelse(bp);
    8000357c:	854a                	mv	a0,s2
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	a22080e7          	jalr	-1502(ra) # 80002fa0 <brelse>
      return iget(dev, inum);
    80003586:	85da                	mv	a1,s6
    80003588:	8556                	mv	a0,s5
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	db4080e7          	jalr	-588(ra) # 8000333e <iget>
}
    80003592:	60a6                	ld	ra,72(sp)
    80003594:	6406                	ld	s0,64(sp)
    80003596:	74e2                	ld	s1,56(sp)
    80003598:	7942                	ld	s2,48(sp)
    8000359a:	79a2                	ld	s3,40(sp)
    8000359c:	7a02                	ld	s4,32(sp)
    8000359e:	6ae2                	ld	s5,24(sp)
    800035a0:	6b42                	ld	s6,16(sp)
    800035a2:	6ba2                	ld	s7,8(sp)
    800035a4:	6161                	addi	sp,sp,80
    800035a6:	8082                	ret

00000000800035a8 <iupdate>:
{
    800035a8:	1101                	addi	sp,sp,-32
    800035aa:	ec06                	sd	ra,24(sp)
    800035ac:	e822                	sd	s0,16(sp)
    800035ae:	e426                	sd	s1,8(sp)
    800035b0:	e04a                	sd	s2,0(sp)
    800035b2:	1000                	addi	s0,sp,32
    800035b4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035b6:	415c                	lw	a5,4(a0)
    800035b8:	0047d79b          	srliw	a5,a5,0x4
    800035bc:	0001d597          	auipc	a1,0x1d
    800035c0:	a9c5a583          	lw	a1,-1380(a1) # 80020058 <sb+0x18>
    800035c4:	9dbd                	addw	a1,a1,a5
    800035c6:	4108                	lw	a0,0(a0)
    800035c8:	00000097          	auipc	ra,0x0
    800035cc:	8a8080e7          	jalr	-1880(ra) # 80002e70 <bread>
    800035d0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035d2:	05850793          	addi	a5,a0,88
    800035d6:	40c8                	lw	a0,4(s1)
    800035d8:	893d                	andi	a0,a0,15
    800035da:	051a                	slli	a0,a0,0x6
    800035dc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800035de:	04449703          	lh	a4,68(s1)
    800035e2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800035e6:	04649703          	lh	a4,70(s1)
    800035ea:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800035ee:	04849703          	lh	a4,72(s1)
    800035f2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800035f6:	04a49703          	lh	a4,74(s1)
    800035fa:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800035fe:	44f8                	lw	a4,76(s1)
    80003600:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003602:	03400613          	li	a2,52
    80003606:	05048593          	addi	a1,s1,80
    8000360a:	0531                	addi	a0,a0,12
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	760080e7          	jalr	1888(ra) # 80000d6c <memmove>
  log_write(bp);
    80003614:	854a                	mv	a0,s2
    80003616:	00001097          	auipc	ra,0x1
    8000361a:	bee080e7          	jalr	-1042(ra) # 80004204 <log_write>
  brelse(bp);
    8000361e:	854a                	mv	a0,s2
    80003620:	00000097          	auipc	ra,0x0
    80003624:	980080e7          	jalr	-1664(ra) # 80002fa0 <brelse>
}
    80003628:	60e2                	ld	ra,24(sp)
    8000362a:	6442                	ld	s0,16(sp)
    8000362c:	64a2                	ld	s1,8(sp)
    8000362e:	6902                	ld	s2,0(sp)
    80003630:	6105                	addi	sp,sp,32
    80003632:	8082                	ret

0000000080003634 <idup>:
{
    80003634:	1101                	addi	sp,sp,-32
    80003636:	ec06                	sd	ra,24(sp)
    80003638:	e822                	sd	s0,16(sp)
    8000363a:	e426                	sd	s1,8(sp)
    8000363c:	1000                	addi	s0,sp,32
    8000363e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003640:	0001d517          	auipc	a0,0x1d
    80003644:	a2050513          	addi	a0,a0,-1504 # 80020060 <icache>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	5c8080e7          	jalr	1480(ra) # 80000c10 <acquire>
  ip->ref++;
    80003650:	449c                	lw	a5,8(s1)
    80003652:	2785                	addiw	a5,a5,1
    80003654:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003656:	0001d517          	auipc	a0,0x1d
    8000365a:	a0a50513          	addi	a0,a0,-1526 # 80020060 <icache>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	666080e7          	jalr	1638(ra) # 80000cc4 <release>
}
    80003666:	8526                	mv	a0,s1
    80003668:	60e2                	ld	ra,24(sp)
    8000366a:	6442                	ld	s0,16(sp)
    8000366c:	64a2                	ld	s1,8(sp)
    8000366e:	6105                	addi	sp,sp,32
    80003670:	8082                	ret

0000000080003672 <ilock>:
{
    80003672:	1101                	addi	sp,sp,-32
    80003674:	ec06                	sd	ra,24(sp)
    80003676:	e822                	sd	s0,16(sp)
    80003678:	e426                	sd	s1,8(sp)
    8000367a:	e04a                	sd	s2,0(sp)
    8000367c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000367e:	c115                	beqz	a0,800036a2 <ilock+0x30>
    80003680:	84aa                	mv	s1,a0
    80003682:	451c                	lw	a5,8(a0)
    80003684:	00f05f63          	blez	a5,800036a2 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003688:	0541                	addi	a0,a0,16
    8000368a:	00001097          	auipc	ra,0x1
    8000368e:	ca2080e7          	jalr	-862(ra) # 8000432c <acquiresleep>
  if(ip->valid == 0){
    80003692:	40bc                	lw	a5,64(s1)
    80003694:	cf99                	beqz	a5,800036b2 <ilock+0x40>
}
    80003696:	60e2                	ld	ra,24(sp)
    80003698:	6442                	ld	s0,16(sp)
    8000369a:	64a2                	ld	s1,8(sp)
    8000369c:	6902                	ld	s2,0(sp)
    8000369e:	6105                	addi	sp,sp,32
    800036a0:	8082                	ret
    panic("ilock");
    800036a2:	00005517          	auipc	a0,0x5
    800036a6:	08650513          	addi	a0,a0,134 # 80008728 <syscalls_name+0x188>
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	e9e080e7          	jalr	-354(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036b2:	40dc                	lw	a5,4(s1)
    800036b4:	0047d79b          	srliw	a5,a5,0x4
    800036b8:	0001d597          	auipc	a1,0x1d
    800036bc:	9a05a583          	lw	a1,-1632(a1) # 80020058 <sb+0x18>
    800036c0:	9dbd                	addw	a1,a1,a5
    800036c2:	4088                	lw	a0,0(s1)
    800036c4:	fffff097          	auipc	ra,0xfffff
    800036c8:	7ac080e7          	jalr	1964(ra) # 80002e70 <bread>
    800036cc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036ce:	05850593          	addi	a1,a0,88
    800036d2:	40dc                	lw	a5,4(s1)
    800036d4:	8bbd                	andi	a5,a5,15
    800036d6:	079a                	slli	a5,a5,0x6
    800036d8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036da:	00059783          	lh	a5,0(a1)
    800036de:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036e2:	00259783          	lh	a5,2(a1)
    800036e6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036ea:	00459783          	lh	a5,4(a1)
    800036ee:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036f2:	00659783          	lh	a5,6(a1)
    800036f6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036fa:	459c                	lw	a5,8(a1)
    800036fc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036fe:	03400613          	li	a2,52
    80003702:	05b1                	addi	a1,a1,12
    80003704:	05048513          	addi	a0,s1,80
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	664080e7          	jalr	1636(ra) # 80000d6c <memmove>
    brelse(bp);
    80003710:	854a                	mv	a0,s2
    80003712:	00000097          	auipc	ra,0x0
    80003716:	88e080e7          	jalr	-1906(ra) # 80002fa0 <brelse>
    ip->valid = 1;
    8000371a:	4785                	li	a5,1
    8000371c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000371e:	04449783          	lh	a5,68(s1)
    80003722:	fbb5                	bnez	a5,80003696 <ilock+0x24>
      panic("ilock: no type");
    80003724:	00005517          	auipc	a0,0x5
    80003728:	00c50513          	addi	a0,a0,12 # 80008730 <syscalls_name+0x190>
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	e1c080e7          	jalr	-484(ra) # 80000548 <panic>

0000000080003734 <iunlock>:
{
    80003734:	1101                	addi	sp,sp,-32
    80003736:	ec06                	sd	ra,24(sp)
    80003738:	e822                	sd	s0,16(sp)
    8000373a:	e426                	sd	s1,8(sp)
    8000373c:	e04a                	sd	s2,0(sp)
    8000373e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003740:	c905                	beqz	a0,80003770 <iunlock+0x3c>
    80003742:	84aa                	mv	s1,a0
    80003744:	01050913          	addi	s2,a0,16
    80003748:	854a                	mv	a0,s2
    8000374a:	00001097          	auipc	ra,0x1
    8000374e:	c7c080e7          	jalr	-900(ra) # 800043c6 <holdingsleep>
    80003752:	cd19                	beqz	a0,80003770 <iunlock+0x3c>
    80003754:	449c                	lw	a5,8(s1)
    80003756:	00f05d63          	blez	a5,80003770 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000375a:	854a                	mv	a0,s2
    8000375c:	00001097          	auipc	ra,0x1
    80003760:	c26080e7          	jalr	-986(ra) # 80004382 <releasesleep>
}
    80003764:	60e2                	ld	ra,24(sp)
    80003766:	6442                	ld	s0,16(sp)
    80003768:	64a2                	ld	s1,8(sp)
    8000376a:	6902                	ld	s2,0(sp)
    8000376c:	6105                	addi	sp,sp,32
    8000376e:	8082                	ret
    panic("iunlock");
    80003770:	00005517          	auipc	a0,0x5
    80003774:	fd050513          	addi	a0,a0,-48 # 80008740 <syscalls_name+0x1a0>
    80003778:	ffffd097          	auipc	ra,0xffffd
    8000377c:	dd0080e7          	jalr	-560(ra) # 80000548 <panic>

0000000080003780 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003780:	7179                	addi	sp,sp,-48
    80003782:	f406                	sd	ra,40(sp)
    80003784:	f022                	sd	s0,32(sp)
    80003786:	ec26                	sd	s1,24(sp)
    80003788:	e84a                	sd	s2,16(sp)
    8000378a:	e44e                	sd	s3,8(sp)
    8000378c:	e052                	sd	s4,0(sp)
    8000378e:	1800                	addi	s0,sp,48
    80003790:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003792:	05050493          	addi	s1,a0,80
    80003796:	08050913          	addi	s2,a0,128
    8000379a:	a021                	j	800037a2 <itrunc+0x22>
    8000379c:	0491                	addi	s1,s1,4
    8000379e:	01248d63          	beq	s1,s2,800037b8 <itrunc+0x38>
    if(ip->addrs[i]){
    800037a2:	408c                	lw	a1,0(s1)
    800037a4:	dde5                	beqz	a1,8000379c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037a6:	0009a503          	lw	a0,0(s3)
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	90c080e7          	jalr	-1780(ra) # 800030b6 <bfree>
      ip->addrs[i] = 0;
    800037b2:	0004a023          	sw	zero,0(s1)
    800037b6:	b7dd                	j	8000379c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037b8:	0809a583          	lw	a1,128(s3)
    800037bc:	e185                	bnez	a1,800037dc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037be:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037c2:	854e                	mv	a0,s3
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	de4080e7          	jalr	-540(ra) # 800035a8 <iupdate>
}
    800037cc:	70a2                	ld	ra,40(sp)
    800037ce:	7402                	ld	s0,32(sp)
    800037d0:	64e2                	ld	s1,24(sp)
    800037d2:	6942                	ld	s2,16(sp)
    800037d4:	69a2                	ld	s3,8(sp)
    800037d6:	6a02                	ld	s4,0(sp)
    800037d8:	6145                	addi	sp,sp,48
    800037da:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037dc:	0009a503          	lw	a0,0(s3)
    800037e0:	fffff097          	auipc	ra,0xfffff
    800037e4:	690080e7          	jalr	1680(ra) # 80002e70 <bread>
    800037e8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037ea:	05850493          	addi	s1,a0,88
    800037ee:	45850913          	addi	s2,a0,1112
    800037f2:	a811                	j	80003806 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800037f4:	0009a503          	lw	a0,0(s3)
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	8be080e7          	jalr	-1858(ra) # 800030b6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003800:	0491                	addi	s1,s1,4
    80003802:	01248563          	beq	s1,s2,8000380c <itrunc+0x8c>
      if(a[j])
    80003806:	408c                	lw	a1,0(s1)
    80003808:	dde5                	beqz	a1,80003800 <itrunc+0x80>
    8000380a:	b7ed                	j	800037f4 <itrunc+0x74>
    brelse(bp);
    8000380c:	8552                	mv	a0,s4
    8000380e:	fffff097          	auipc	ra,0xfffff
    80003812:	792080e7          	jalr	1938(ra) # 80002fa0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003816:	0809a583          	lw	a1,128(s3)
    8000381a:	0009a503          	lw	a0,0(s3)
    8000381e:	00000097          	auipc	ra,0x0
    80003822:	898080e7          	jalr	-1896(ra) # 800030b6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003826:	0809a023          	sw	zero,128(s3)
    8000382a:	bf51                	j	800037be <itrunc+0x3e>

000000008000382c <iput>:
{
    8000382c:	1101                	addi	sp,sp,-32
    8000382e:	ec06                	sd	ra,24(sp)
    80003830:	e822                	sd	s0,16(sp)
    80003832:	e426                	sd	s1,8(sp)
    80003834:	e04a                	sd	s2,0(sp)
    80003836:	1000                	addi	s0,sp,32
    80003838:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000383a:	0001d517          	auipc	a0,0x1d
    8000383e:	82650513          	addi	a0,a0,-2010 # 80020060 <icache>
    80003842:	ffffd097          	auipc	ra,0xffffd
    80003846:	3ce080e7          	jalr	974(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000384a:	4498                	lw	a4,8(s1)
    8000384c:	4785                	li	a5,1
    8000384e:	02f70363          	beq	a4,a5,80003874 <iput+0x48>
  ip->ref--;
    80003852:	449c                	lw	a5,8(s1)
    80003854:	37fd                	addiw	a5,a5,-1
    80003856:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003858:	0001d517          	auipc	a0,0x1d
    8000385c:	80850513          	addi	a0,a0,-2040 # 80020060 <icache>
    80003860:	ffffd097          	auipc	ra,0xffffd
    80003864:	464080e7          	jalr	1124(ra) # 80000cc4 <release>
}
    80003868:	60e2                	ld	ra,24(sp)
    8000386a:	6442                	ld	s0,16(sp)
    8000386c:	64a2                	ld	s1,8(sp)
    8000386e:	6902                	ld	s2,0(sp)
    80003870:	6105                	addi	sp,sp,32
    80003872:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003874:	40bc                	lw	a5,64(s1)
    80003876:	dff1                	beqz	a5,80003852 <iput+0x26>
    80003878:	04a49783          	lh	a5,74(s1)
    8000387c:	fbf9                	bnez	a5,80003852 <iput+0x26>
    acquiresleep(&ip->lock);
    8000387e:	01048913          	addi	s2,s1,16
    80003882:	854a                	mv	a0,s2
    80003884:	00001097          	auipc	ra,0x1
    80003888:	aa8080e7          	jalr	-1368(ra) # 8000432c <acquiresleep>
    release(&icache.lock);
    8000388c:	0001c517          	auipc	a0,0x1c
    80003890:	7d450513          	addi	a0,a0,2004 # 80020060 <icache>
    80003894:	ffffd097          	auipc	ra,0xffffd
    80003898:	430080e7          	jalr	1072(ra) # 80000cc4 <release>
    itrunc(ip);
    8000389c:	8526                	mv	a0,s1
    8000389e:	00000097          	auipc	ra,0x0
    800038a2:	ee2080e7          	jalr	-286(ra) # 80003780 <itrunc>
    ip->type = 0;
    800038a6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038aa:	8526                	mv	a0,s1
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	cfc080e7          	jalr	-772(ra) # 800035a8 <iupdate>
    ip->valid = 0;
    800038b4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038b8:	854a                	mv	a0,s2
    800038ba:	00001097          	auipc	ra,0x1
    800038be:	ac8080e7          	jalr	-1336(ra) # 80004382 <releasesleep>
    acquire(&icache.lock);
    800038c2:	0001c517          	auipc	a0,0x1c
    800038c6:	79e50513          	addi	a0,a0,1950 # 80020060 <icache>
    800038ca:	ffffd097          	auipc	ra,0xffffd
    800038ce:	346080e7          	jalr	838(ra) # 80000c10 <acquire>
    800038d2:	b741                	j	80003852 <iput+0x26>

00000000800038d4 <iunlockput>:
{
    800038d4:	1101                	addi	sp,sp,-32
    800038d6:	ec06                	sd	ra,24(sp)
    800038d8:	e822                	sd	s0,16(sp)
    800038da:	e426                	sd	s1,8(sp)
    800038dc:	1000                	addi	s0,sp,32
    800038de:	84aa                	mv	s1,a0
  iunlock(ip);
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	e54080e7          	jalr	-428(ra) # 80003734 <iunlock>
  iput(ip);
    800038e8:	8526                	mv	a0,s1
    800038ea:	00000097          	auipc	ra,0x0
    800038ee:	f42080e7          	jalr	-190(ra) # 8000382c <iput>
}
    800038f2:	60e2                	ld	ra,24(sp)
    800038f4:	6442                	ld	s0,16(sp)
    800038f6:	64a2                	ld	s1,8(sp)
    800038f8:	6105                	addi	sp,sp,32
    800038fa:	8082                	ret

00000000800038fc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038fc:	1141                	addi	sp,sp,-16
    800038fe:	e422                	sd	s0,8(sp)
    80003900:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003902:	411c                	lw	a5,0(a0)
    80003904:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003906:	415c                	lw	a5,4(a0)
    80003908:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000390a:	04451783          	lh	a5,68(a0)
    8000390e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003912:	04a51783          	lh	a5,74(a0)
    80003916:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000391a:	04c56783          	lwu	a5,76(a0)
    8000391e:	e99c                	sd	a5,16(a1)
}
    80003920:	6422                	ld	s0,8(sp)
    80003922:	0141                	addi	sp,sp,16
    80003924:	8082                	ret

0000000080003926 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003926:	457c                	lw	a5,76(a0)
    80003928:	0ed7e863          	bltu	a5,a3,80003a18 <readi+0xf2>
{
    8000392c:	7159                	addi	sp,sp,-112
    8000392e:	f486                	sd	ra,104(sp)
    80003930:	f0a2                	sd	s0,96(sp)
    80003932:	eca6                	sd	s1,88(sp)
    80003934:	e8ca                	sd	s2,80(sp)
    80003936:	e4ce                	sd	s3,72(sp)
    80003938:	e0d2                	sd	s4,64(sp)
    8000393a:	fc56                	sd	s5,56(sp)
    8000393c:	f85a                	sd	s6,48(sp)
    8000393e:	f45e                	sd	s7,40(sp)
    80003940:	f062                	sd	s8,32(sp)
    80003942:	ec66                	sd	s9,24(sp)
    80003944:	e86a                	sd	s10,16(sp)
    80003946:	e46e                	sd	s11,8(sp)
    80003948:	1880                	addi	s0,sp,112
    8000394a:	8baa                	mv	s7,a0
    8000394c:	8c2e                	mv	s8,a1
    8000394e:	8ab2                	mv	s5,a2
    80003950:	84b6                	mv	s1,a3
    80003952:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003954:	9f35                	addw	a4,a4,a3
    return 0;
    80003956:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003958:	08d76f63          	bltu	a4,a3,800039f6 <readi+0xd0>
  if(off + n > ip->size)
    8000395c:	00e7f463          	bgeu	a5,a4,80003964 <readi+0x3e>
    n = ip->size - off;
    80003960:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003964:	0a0b0863          	beqz	s6,80003a14 <readi+0xee>
    80003968:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000396a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000396e:	5cfd                	li	s9,-1
    80003970:	a82d                	j	800039aa <readi+0x84>
    80003972:	020a1d93          	slli	s11,s4,0x20
    80003976:	020ddd93          	srli	s11,s11,0x20
    8000397a:	05890613          	addi	a2,s2,88
    8000397e:	86ee                	mv	a3,s11
    80003980:	963a                	add	a2,a2,a4
    80003982:	85d6                	mv	a1,s5
    80003984:	8562                	mv	a0,s8
    80003986:	fffff097          	auipc	ra,0xfffff
    8000398a:	ace080e7          	jalr	-1330(ra) # 80002454 <either_copyout>
    8000398e:	05950d63          	beq	a0,s9,800039e8 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003992:	854a                	mv	a0,s2
    80003994:	fffff097          	auipc	ra,0xfffff
    80003998:	60c080e7          	jalr	1548(ra) # 80002fa0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000399c:	013a09bb          	addw	s3,s4,s3
    800039a0:	009a04bb          	addw	s1,s4,s1
    800039a4:	9aee                	add	s5,s5,s11
    800039a6:	0569f663          	bgeu	s3,s6,800039f2 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039aa:	000ba903          	lw	s2,0(s7)
    800039ae:	00a4d59b          	srliw	a1,s1,0xa
    800039b2:	855e                	mv	a0,s7
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	8b0080e7          	jalr	-1872(ra) # 80003264 <bmap>
    800039bc:	0005059b          	sext.w	a1,a0
    800039c0:	854a                	mv	a0,s2
    800039c2:	fffff097          	auipc	ra,0xfffff
    800039c6:	4ae080e7          	jalr	1198(ra) # 80002e70 <bread>
    800039ca:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800039cc:	3ff4f713          	andi	a4,s1,1023
    800039d0:	40ed07bb          	subw	a5,s10,a4
    800039d4:	413b06bb          	subw	a3,s6,s3
    800039d8:	8a3e                	mv	s4,a5
    800039da:	2781                	sext.w	a5,a5
    800039dc:	0006861b          	sext.w	a2,a3
    800039e0:	f8f679e3          	bgeu	a2,a5,80003972 <readi+0x4c>
    800039e4:	8a36                	mv	s4,a3
    800039e6:	b771                	j	80003972 <readi+0x4c>
      brelse(bp);
    800039e8:	854a                	mv	a0,s2
    800039ea:	fffff097          	auipc	ra,0xfffff
    800039ee:	5b6080e7          	jalr	1462(ra) # 80002fa0 <brelse>
  }
  return tot;
    800039f2:	0009851b          	sext.w	a0,s3
}
    800039f6:	70a6                	ld	ra,104(sp)
    800039f8:	7406                	ld	s0,96(sp)
    800039fa:	64e6                	ld	s1,88(sp)
    800039fc:	6946                	ld	s2,80(sp)
    800039fe:	69a6                	ld	s3,72(sp)
    80003a00:	6a06                	ld	s4,64(sp)
    80003a02:	7ae2                	ld	s5,56(sp)
    80003a04:	7b42                	ld	s6,48(sp)
    80003a06:	7ba2                	ld	s7,40(sp)
    80003a08:	7c02                	ld	s8,32(sp)
    80003a0a:	6ce2                	ld	s9,24(sp)
    80003a0c:	6d42                	ld	s10,16(sp)
    80003a0e:	6da2                	ld	s11,8(sp)
    80003a10:	6165                	addi	sp,sp,112
    80003a12:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a14:	89da                	mv	s3,s6
    80003a16:	bff1                	j	800039f2 <readi+0xcc>
    return 0;
    80003a18:	4501                	li	a0,0
}
    80003a1a:	8082                	ret

0000000080003a1c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a1c:	457c                	lw	a5,76(a0)
    80003a1e:	10d7e663          	bltu	a5,a3,80003b2a <writei+0x10e>
{
    80003a22:	7159                	addi	sp,sp,-112
    80003a24:	f486                	sd	ra,104(sp)
    80003a26:	f0a2                	sd	s0,96(sp)
    80003a28:	eca6                	sd	s1,88(sp)
    80003a2a:	e8ca                	sd	s2,80(sp)
    80003a2c:	e4ce                	sd	s3,72(sp)
    80003a2e:	e0d2                	sd	s4,64(sp)
    80003a30:	fc56                	sd	s5,56(sp)
    80003a32:	f85a                	sd	s6,48(sp)
    80003a34:	f45e                	sd	s7,40(sp)
    80003a36:	f062                	sd	s8,32(sp)
    80003a38:	ec66                	sd	s9,24(sp)
    80003a3a:	e86a                	sd	s10,16(sp)
    80003a3c:	e46e                	sd	s11,8(sp)
    80003a3e:	1880                	addi	s0,sp,112
    80003a40:	8baa                	mv	s7,a0
    80003a42:	8c2e                	mv	s8,a1
    80003a44:	8ab2                	mv	s5,a2
    80003a46:	8936                	mv	s2,a3
    80003a48:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a4a:	00e687bb          	addw	a5,a3,a4
    80003a4e:	0ed7e063          	bltu	a5,a3,80003b2e <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a52:	00043737          	lui	a4,0x43
    80003a56:	0cf76e63          	bltu	a4,a5,80003b32 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a5a:	0a0b0763          	beqz	s6,80003b08 <writei+0xec>
    80003a5e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a60:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a64:	5cfd                	li	s9,-1
    80003a66:	a091                	j	80003aaa <writei+0x8e>
    80003a68:	02099d93          	slli	s11,s3,0x20
    80003a6c:	020ddd93          	srli	s11,s11,0x20
    80003a70:	05848513          	addi	a0,s1,88
    80003a74:	86ee                	mv	a3,s11
    80003a76:	8656                	mv	a2,s5
    80003a78:	85e2                	mv	a1,s8
    80003a7a:	953a                	add	a0,a0,a4
    80003a7c:	fffff097          	auipc	ra,0xfffff
    80003a80:	a2e080e7          	jalr	-1490(ra) # 800024aa <either_copyin>
    80003a84:	07950263          	beq	a0,s9,80003ae8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a88:	8526                	mv	a0,s1
    80003a8a:	00000097          	auipc	ra,0x0
    80003a8e:	77a080e7          	jalr	1914(ra) # 80004204 <log_write>
    brelse(bp);
    80003a92:	8526                	mv	a0,s1
    80003a94:	fffff097          	auipc	ra,0xfffff
    80003a98:	50c080e7          	jalr	1292(ra) # 80002fa0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a9c:	01498a3b          	addw	s4,s3,s4
    80003aa0:	0129893b          	addw	s2,s3,s2
    80003aa4:	9aee                	add	s5,s5,s11
    80003aa6:	056a7663          	bgeu	s4,s6,80003af2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aaa:	000ba483          	lw	s1,0(s7)
    80003aae:	00a9559b          	srliw	a1,s2,0xa
    80003ab2:	855e                	mv	a0,s7
    80003ab4:	fffff097          	auipc	ra,0xfffff
    80003ab8:	7b0080e7          	jalr	1968(ra) # 80003264 <bmap>
    80003abc:	0005059b          	sext.w	a1,a0
    80003ac0:	8526                	mv	a0,s1
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	3ae080e7          	jalr	942(ra) # 80002e70 <bread>
    80003aca:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003acc:	3ff97713          	andi	a4,s2,1023
    80003ad0:	40ed07bb          	subw	a5,s10,a4
    80003ad4:	414b06bb          	subw	a3,s6,s4
    80003ad8:	89be                	mv	s3,a5
    80003ada:	2781                	sext.w	a5,a5
    80003adc:	0006861b          	sext.w	a2,a3
    80003ae0:	f8f674e3          	bgeu	a2,a5,80003a68 <writei+0x4c>
    80003ae4:	89b6                	mv	s3,a3
    80003ae6:	b749                	j	80003a68 <writei+0x4c>
      brelse(bp);
    80003ae8:	8526                	mv	a0,s1
    80003aea:	fffff097          	auipc	ra,0xfffff
    80003aee:	4b6080e7          	jalr	1206(ra) # 80002fa0 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003af2:	04cba783          	lw	a5,76(s7)
    80003af6:	0127f463          	bgeu	a5,s2,80003afe <writei+0xe2>
      ip->size = off;
    80003afa:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003afe:	855e                	mv	a0,s7
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	aa8080e7          	jalr	-1368(ra) # 800035a8 <iupdate>
  }

  return n;
    80003b08:	000b051b          	sext.w	a0,s6
}
    80003b0c:	70a6                	ld	ra,104(sp)
    80003b0e:	7406                	ld	s0,96(sp)
    80003b10:	64e6                	ld	s1,88(sp)
    80003b12:	6946                	ld	s2,80(sp)
    80003b14:	69a6                	ld	s3,72(sp)
    80003b16:	6a06                	ld	s4,64(sp)
    80003b18:	7ae2                	ld	s5,56(sp)
    80003b1a:	7b42                	ld	s6,48(sp)
    80003b1c:	7ba2                	ld	s7,40(sp)
    80003b1e:	7c02                	ld	s8,32(sp)
    80003b20:	6ce2                	ld	s9,24(sp)
    80003b22:	6d42                	ld	s10,16(sp)
    80003b24:	6da2                	ld	s11,8(sp)
    80003b26:	6165                	addi	sp,sp,112
    80003b28:	8082                	ret
    return -1;
    80003b2a:	557d                	li	a0,-1
}
    80003b2c:	8082                	ret
    return -1;
    80003b2e:	557d                	li	a0,-1
    80003b30:	bff1                	j	80003b0c <writei+0xf0>
    return -1;
    80003b32:	557d                	li	a0,-1
    80003b34:	bfe1                	j	80003b0c <writei+0xf0>

0000000080003b36 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b36:	1141                	addi	sp,sp,-16
    80003b38:	e406                	sd	ra,8(sp)
    80003b3a:	e022                	sd	s0,0(sp)
    80003b3c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b3e:	4639                	li	a2,14
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	2a8080e7          	jalr	680(ra) # 80000de8 <strncmp>
}
    80003b48:	60a2                	ld	ra,8(sp)
    80003b4a:	6402                	ld	s0,0(sp)
    80003b4c:	0141                	addi	sp,sp,16
    80003b4e:	8082                	ret

0000000080003b50 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b50:	7139                	addi	sp,sp,-64
    80003b52:	fc06                	sd	ra,56(sp)
    80003b54:	f822                	sd	s0,48(sp)
    80003b56:	f426                	sd	s1,40(sp)
    80003b58:	f04a                	sd	s2,32(sp)
    80003b5a:	ec4e                	sd	s3,24(sp)
    80003b5c:	e852                	sd	s4,16(sp)
    80003b5e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b60:	04451703          	lh	a4,68(a0)
    80003b64:	4785                	li	a5,1
    80003b66:	00f71a63          	bne	a4,a5,80003b7a <dirlookup+0x2a>
    80003b6a:	892a                	mv	s2,a0
    80003b6c:	89ae                	mv	s3,a1
    80003b6e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b70:	457c                	lw	a5,76(a0)
    80003b72:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b74:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b76:	e79d                	bnez	a5,80003ba4 <dirlookup+0x54>
    80003b78:	a8a5                	j	80003bf0 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b7a:	00005517          	auipc	a0,0x5
    80003b7e:	bce50513          	addi	a0,a0,-1074 # 80008748 <syscalls_name+0x1a8>
    80003b82:	ffffd097          	auipc	ra,0xffffd
    80003b86:	9c6080e7          	jalr	-1594(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003b8a:	00005517          	auipc	a0,0x5
    80003b8e:	bd650513          	addi	a0,a0,-1066 # 80008760 <syscalls_name+0x1c0>
    80003b92:	ffffd097          	auipc	ra,0xffffd
    80003b96:	9b6080e7          	jalr	-1610(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b9a:	24c1                	addiw	s1,s1,16
    80003b9c:	04c92783          	lw	a5,76(s2)
    80003ba0:	04f4f763          	bgeu	s1,a5,80003bee <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ba4:	4741                	li	a4,16
    80003ba6:	86a6                	mv	a3,s1
    80003ba8:	fc040613          	addi	a2,s0,-64
    80003bac:	4581                	li	a1,0
    80003bae:	854a                	mv	a0,s2
    80003bb0:	00000097          	auipc	ra,0x0
    80003bb4:	d76080e7          	jalr	-650(ra) # 80003926 <readi>
    80003bb8:	47c1                	li	a5,16
    80003bba:	fcf518e3          	bne	a0,a5,80003b8a <dirlookup+0x3a>
    if(de.inum == 0)
    80003bbe:	fc045783          	lhu	a5,-64(s0)
    80003bc2:	dfe1                	beqz	a5,80003b9a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bc4:	fc240593          	addi	a1,s0,-62
    80003bc8:	854e                	mv	a0,s3
    80003bca:	00000097          	auipc	ra,0x0
    80003bce:	f6c080e7          	jalr	-148(ra) # 80003b36 <namecmp>
    80003bd2:	f561                	bnez	a0,80003b9a <dirlookup+0x4a>
      if(poff)
    80003bd4:	000a0463          	beqz	s4,80003bdc <dirlookup+0x8c>
        *poff = off;
    80003bd8:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003bdc:	fc045583          	lhu	a1,-64(s0)
    80003be0:	00092503          	lw	a0,0(s2)
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	75a080e7          	jalr	1882(ra) # 8000333e <iget>
    80003bec:	a011                	j	80003bf0 <dirlookup+0xa0>
  return 0;
    80003bee:	4501                	li	a0,0
}
    80003bf0:	70e2                	ld	ra,56(sp)
    80003bf2:	7442                	ld	s0,48(sp)
    80003bf4:	74a2                	ld	s1,40(sp)
    80003bf6:	7902                	ld	s2,32(sp)
    80003bf8:	69e2                	ld	s3,24(sp)
    80003bfa:	6a42                	ld	s4,16(sp)
    80003bfc:	6121                	addi	sp,sp,64
    80003bfe:	8082                	ret

0000000080003c00 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c00:	711d                	addi	sp,sp,-96
    80003c02:	ec86                	sd	ra,88(sp)
    80003c04:	e8a2                	sd	s0,80(sp)
    80003c06:	e4a6                	sd	s1,72(sp)
    80003c08:	e0ca                	sd	s2,64(sp)
    80003c0a:	fc4e                	sd	s3,56(sp)
    80003c0c:	f852                	sd	s4,48(sp)
    80003c0e:	f456                	sd	s5,40(sp)
    80003c10:	f05a                	sd	s6,32(sp)
    80003c12:	ec5e                	sd	s7,24(sp)
    80003c14:	e862                	sd	s8,16(sp)
    80003c16:	e466                	sd	s9,8(sp)
    80003c18:	1080                	addi	s0,sp,96
    80003c1a:	84aa                	mv	s1,a0
    80003c1c:	8b2e                	mv	s6,a1
    80003c1e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c20:	00054703          	lbu	a4,0(a0)
    80003c24:	02f00793          	li	a5,47
    80003c28:	02f70363          	beq	a4,a5,80003c4e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c2c:	ffffe097          	auipc	ra,0xffffe
    80003c30:	db2080e7          	jalr	-590(ra) # 800019de <myproc>
    80003c34:	15053503          	ld	a0,336(a0)
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	9fc080e7          	jalr	-1540(ra) # 80003634 <idup>
    80003c40:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c42:	02f00913          	li	s2,47
  len = path - s;
    80003c46:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003c48:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c4a:	4c05                	li	s8,1
    80003c4c:	a865                	j	80003d04 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003c4e:	4585                	li	a1,1
    80003c50:	4505                	li	a0,1
    80003c52:	fffff097          	auipc	ra,0xfffff
    80003c56:	6ec080e7          	jalr	1772(ra) # 8000333e <iget>
    80003c5a:	89aa                	mv	s3,a0
    80003c5c:	b7dd                	j	80003c42 <namex+0x42>
      iunlockput(ip);
    80003c5e:	854e                	mv	a0,s3
    80003c60:	00000097          	auipc	ra,0x0
    80003c64:	c74080e7          	jalr	-908(ra) # 800038d4 <iunlockput>
      return 0;
    80003c68:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c6a:	854e                	mv	a0,s3
    80003c6c:	60e6                	ld	ra,88(sp)
    80003c6e:	6446                	ld	s0,80(sp)
    80003c70:	64a6                	ld	s1,72(sp)
    80003c72:	6906                	ld	s2,64(sp)
    80003c74:	79e2                	ld	s3,56(sp)
    80003c76:	7a42                	ld	s4,48(sp)
    80003c78:	7aa2                	ld	s5,40(sp)
    80003c7a:	7b02                	ld	s6,32(sp)
    80003c7c:	6be2                	ld	s7,24(sp)
    80003c7e:	6c42                	ld	s8,16(sp)
    80003c80:	6ca2                	ld	s9,8(sp)
    80003c82:	6125                	addi	sp,sp,96
    80003c84:	8082                	ret
      iunlock(ip);
    80003c86:	854e                	mv	a0,s3
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	aac080e7          	jalr	-1364(ra) # 80003734 <iunlock>
      return ip;
    80003c90:	bfe9                	j	80003c6a <namex+0x6a>
      iunlockput(ip);
    80003c92:	854e                	mv	a0,s3
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	c40080e7          	jalr	-960(ra) # 800038d4 <iunlockput>
      return 0;
    80003c9c:	89d2                	mv	s3,s4
    80003c9e:	b7f1                	j	80003c6a <namex+0x6a>
  len = path - s;
    80003ca0:	40b48633          	sub	a2,s1,a1
    80003ca4:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ca8:	094cd463          	bge	s9,s4,80003d30 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cac:	4639                	li	a2,14
    80003cae:	8556                	mv	a0,s5
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	0bc080e7          	jalr	188(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003cb8:	0004c783          	lbu	a5,0(s1)
    80003cbc:	01279763          	bne	a5,s2,80003cca <namex+0xca>
    path++;
    80003cc0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003cc2:	0004c783          	lbu	a5,0(s1)
    80003cc6:	ff278de3          	beq	a5,s2,80003cc0 <namex+0xc0>
    ilock(ip);
    80003cca:	854e                	mv	a0,s3
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	9a6080e7          	jalr	-1626(ra) # 80003672 <ilock>
    if(ip->type != T_DIR){
    80003cd4:	04499783          	lh	a5,68(s3)
    80003cd8:	f98793e3          	bne	a5,s8,80003c5e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003cdc:	000b0563          	beqz	s6,80003ce6 <namex+0xe6>
    80003ce0:	0004c783          	lbu	a5,0(s1)
    80003ce4:	d3cd                	beqz	a5,80003c86 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ce6:	865e                	mv	a2,s7
    80003ce8:	85d6                	mv	a1,s5
    80003cea:	854e                	mv	a0,s3
    80003cec:	00000097          	auipc	ra,0x0
    80003cf0:	e64080e7          	jalr	-412(ra) # 80003b50 <dirlookup>
    80003cf4:	8a2a                	mv	s4,a0
    80003cf6:	dd51                	beqz	a0,80003c92 <namex+0x92>
    iunlockput(ip);
    80003cf8:	854e                	mv	a0,s3
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	bda080e7          	jalr	-1062(ra) # 800038d4 <iunlockput>
    ip = next;
    80003d02:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d04:	0004c783          	lbu	a5,0(s1)
    80003d08:	05279763          	bne	a5,s2,80003d56 <namex+0x156>
    path++;
    80003d0c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d0e:	0004c783          	lbu	a5,0(s1)
    80003d12:	ff278de3          	beq	a5,s2,80003d0c <namex+0x10c>
  if(*path == 0)
    80003d16:	c79d                	beqz	a5,80003d44 <namex+0x144>
    path++;
    80003d18:	85a6                	mv	a1,s1
  len = path - s;
    80003d1a:	8a5e                	mv	s4,s7
    80003d1c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d1e:	01278963          	beq	a5,s2,80003d30 <namex+0x130>
    80003d22:	dfbd                	beqz	a5,80003ca0 <namex+0xa0>
    path++;
    80003d24:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d26:	0004c783          	lbu	a5,0(s1)
    80003d2a:	ff279ce3          	bne	a5,s2,80003d22 <namex+0x122>
    80003d2e:	bf8d                	j	80003ca0 <namex+0xa0>
    memmove(name, s, len);
    80003d30:	2601                	sext.w	a2,a2
    80003d32:	8556                	mv	a0,s5
    80003d34:	ffffd097          	auipc	ra,0xffffd
    80003d38:	038080e7          	jalr	56(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003d3c:	9a56                	add	s4,s4,s5
    80003d3e:	000a0023          	sb	zero,0(s4)
    80003d42:	bf9d                	j	80003cb8 <namex+0xb8>
  if(nameiparent){
    80003d44:	f20b03e3          	beqz	s6,80003c6a <namex+0x6a>
    iput(ip);
    80003d48:	854e                	mv	a0,s3
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	ae2080e7          	jalr	-1310(ra) # 8000382c <iput>
    return 0;
    80003d52:	4981                	li	s3,0
    80003d54:	bf19                	j	80003c6a <namex+0x6a>
  if(*path == 0)
    80003d56:	d7fd                	beqz	a5,80003d44 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003d58:	0004c783          	lbu	a5,0(s1)
    80003d5c:	85a6                	mv	a1,s1
    80003d5e:	b7d1                	j	80003d22 <namex+0x122>

0000000080003d60 <dirlink>:
{
    80003d60:	7139                	addi	sp,sp,-64
    80003d62:	fc06                	sd	ra,56(sp)
    80003d64:	f822                	sd	s0,48(sp)
    80003d66:	f426                	sd	s1,40(sp)
    80003d68:	f04a                	sd	s2,32(sp)
    80003d6a:	ec4e                	sd	s3,24(sp)
    80003d6c:	e852                	sd	s4,16(sp)
    80003d6e:	0080                	addi	s0,sp,64
    80003d70:	892a                	mv	s2,a0
    80003d72:	8a2e                	mv	s4,a1
    80003d74:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d76:	4601                	li	a2,0
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	dd8080e7          	jalr	-552(ra) # 80003b50 <dirlookup>
    80003d80:	e93d                	bnez	a0,80003df6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d82:	04c92483          	lw	s1,76(s2)
    80003d86:	c49d                	beqz	s1,80003db4 <dirlink+0x54>
    80003d88:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d8a:	4741                	li	a4,16
    80003d8c:	86a6                	mv	a3,s1
    80003d8e:	fc040613          	addi	a2,s0,-64
    80003d92:	4581                	li	a1,0
    80003d94:	854a                	mv	a0,s2
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	b90080e7          	jalr	-1136(ra) # 80003926 <readi>
    80003d9e:	47c1                	li	a5,16
    80003da0:	06f51163          	bne	a0,a5,80003e02 <dirlink+0xa2>
    if(de.inum == 0)
    80003da4:	fc045783          	lhu	a5,-64(s0)
    80003da8:	c791                	beqz	a5,80003db4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003daa:	24c1                	addiw	s1,s1,16
    80003dac:	04c92783          	lw	a5,76(s2)
    80003db0:	fcf4ede3          	bltu	s1,a5,80003d8a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003db4:	4639                	li	a2,14
    80003db6:	85d2                	mv	a1,s4
    80003db8:	fc240513          	addi	a0,s0,-62
    80003dbc:	ffffd097          	auipc	ra,0xffffd
    80003dc0:	068080e7          	jalr	104(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80003dc4:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dc8:	4741                	li	a4,16
    80003dca:	86a6                	mv	a3,s1
    80003dcc:	fc040613          	addi	a2,s0,-64
    80003dd0:	4581                	li	a1,0
    80003dd2:	854a                	mv	a0,s2
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	c48080e7          	jalr	-952(ra) # 80003a1c <writei>
    80003ddc:	872a                	mv	a4,a0
    80003dde:	47c1                	li	a5,16
  return 0;
    80003de0:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003de2:	02f71863          	bne	a4,a5,80003e12 <dirlink+0xb2>
}
    80003de6:	70e2                	ld	ra,56(sp)
    80003de8:	7442                	ld	s0,48(sp)
    80003dea:	74a2                	ld	s1,40(sp)
    80003dec:	7902                	ld	s2,32(sp)
    80003dee:	69e2                	ld	s3,24(sp)
    80003df0:	6a42                	ld	s4,16(sp)
    80003df2:	6121                	addi	sp,sp,64
    80003df4:	8082                	ret
    iput(ip);
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	a36080e7          	jalr	-1482(ra) # 8000382c <iput>
    return -1;
    80003dfe:	557d                	li	a0,-1
    80003e00:	b7dd                	j	80003de6 <dirlink+0x86>
      panic("dirlink read");
    80003e02:	00005517          	auipc	a0,0x5
    80003e06:	96e50513          	addi	a0,a0,-1682 # 80008770 <syscalls_name+0x1d0>
    80003e0a:	ffffc097          	auipc	ra,0xffffc
    80003e0e:	73e080e7          	jalr	1854(ra) # 80000548 <panic>
    panic("dirlink");
    80003e12:	00005517          	auipc	a0,0x5
    80003e16:	a7650513          	addi	a0,a0,-1418 # 80008888 <syscalls_name+0x2e8>
    80003e1a:	ffffc097          	auipc	ra,0xffffc
    80003e1e:	72e080e7          	jalr	1838(ra) # 80000548 <panic>

0000000080003e22 <namei>:

struct inode*
namei(char *path)
{
    80003e22:	1101                	addi	sp,sp,-32
    80003e24:	ec06                	sd	ra,24(sp)
    80003e26:	e822                	sd	s0,16(sp)
    80003e28:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e2a:	fe040613          	addi	a2,s0,-32
    80003e2e:	4581                	li	a1,0
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	dd0080e7          	jalr	-560(ra) # 80003c00 <namex>
}
    80003e38:	60e2                	ld	ra,24(sp)
    80003e3a:	6442                	ld	s0,16(sp)
    80003e3c:	6105                	addi	sp,sp,32
    80003e3e:	8082                	ret

0000000080003e40 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e40:	1141                	addi	sp,sp,-16
    80003e42:	e406                	sd	ra,8(sp)
    80003e44:	e022                	sd	s0,0(sp)
    80003e46:	0800                	addi	s0,sp,16
    80003e48:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e4a:	4585                	li	a1,1
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	db4080e7          	jalr	-588(ra) # 80003c00 <namex>
}
    80003e54:	60a2                	ld	ra,8(sp)
    80003e56:	6402                	ld	s0,0(sp)
    80003e58:	0141                	addi	sp,sp,16
    80003e5a:	8082                	ret

0000000080003e5c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e5c:	1101                	addi	sp,sp,-32
    80003e5e:	ec06                	sd	ra,24(sp)
    80003e60:	e822                	sd	s0,16(sp)
    80003e62:	e426                	sd	s1,8(sp)
    80003e64:	e04a                	sd	s2,0(sp)
    80003e66:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e68:	0001e917          	auipc	s2,0x1e
    80003e6c:	ca090913          	addi	s2,s2,-864 # 80021b08 <log>
    80003e70:	01892583          	lw	a1,24(s2)
    80003e74:	02892503          	lw	a0,40(s2)
    80003e78:	fffff097          	auipc	ra,0xfffff
    80003e7c:	ff8080e7          	jalr	-8(ra) # 80002e70 <bread>
    80003e80:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e82:	02c92683          	lw	a3,44(s2)
    80003e86:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e88:	02d05763          	blez	a3,80003eb6 <write_head+0x5a>
    80003e8c:	0001e797          	auipc	a5,0x1e
    80003e90:	cac78793          	addi	a5,a5,-852 # 80021b38 <log+0x30>
    80003e94:	05c50713          	addi	a4,a0,92
    80003e98:	36fd                	addiw	a3,a3,-1
    80003e9a:	1682                	slli	a3,a3,0x20
    80003e9c:	9281                	srli	a3,a3,0x20
    80003e9e:	068a                	slli	a3,a3,0x2
    80003ea0:	0001e617          	auipc	a2,0x1e
    80003ea4:	c9c60613          	addi	a2,a2,-868 # 80021b3c <log+0x34>
    80003ea8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003eaa:	4390                	lw	a2,0(a5)
    80003eac:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003eae:	0791                	addi	a5,a5,4
    80003eb0:	0711                	addi	a4,a4,4
    80003eb2:	fed79ce3          	bne	a5,a3,80003eaa <write_head+0x4e>
  }
  bwrite(buf);
    80003eb6:	8526                	mv	a0,s1
    80003eb8:	fffff097          	auipc	ra,0xfffff
    80003ebc:	0aa080e7          	jalr	170(ra) # 80002f62 <bwrite>
  brelse(buf);
    80003ec0:	8526                	mv	a0,s1
    80003ec2:	fffff097          	auipc	ra,0xfffff
    80003ec6:	0de080e7          	jalr	222(ra) # 80002fa0 <brelse>
}
    80003eca:	60e2                	ld	ra,24(sp)
    80003ecc:	6442                	ld	s0,16(sp)
    80003ece:	64a2                	ld	s1,8(sp)
    80003ed0:	6902                	ld	s2,0(sp)
    80003ed2:	6105                	addi	sp,sp,32
    80003ed4:	8082                	ret

0000000080003ed6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ed6:	0001e797          	auipc	a5,0x1e
    80003eda:	c5e7a783          	lw	a5,-930(a5) # 80021b34 <log+0x2c>
    80003ede:	0af05663          	blez	a5,80003f8a <install_trans+0xb4>
{
    80003ee2:	7139                	addi	sp,sp,-64
    80003ee4:	fc06                	sd	ra,56(sp)
    80003ee6:	f822                	sd	s0,48(sp)
    80003ee8:	f426                	sd	s1,40(sp)
    80003eea:	f04a                	sd	s2,32(sp)
    80003eec:	ec4e                	sd	s3,24(sp)
    80003eee:	e852                	sd	s4,16(sp)
    80003ef0:	e456                	sd	s5,8(sp)
    80003ef2:	0080                	addi	s0,sp,64
    80003ef4:	0001ea97          	auipc	s5,0x1e
    80003ef8:	c44a8a93          	addi	s5,s5,-956 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003efc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003efe:	0001e997          	auipc	s3,0x1e
    80003f02:	c0a98993          	addi	s3,s3,-1014 # 80021b08 <log>
    80003f06:	0189a583          	lw	a1,24(s3)
    80003f0a:	014585bb          	addw	a1,a1,s4
    80003f0e:	2585                	addiw	a1,a1,1
    80003f10:	0289a503          	lw	a0,40(s3)
    80003f14:	fffff097          	auipc	ra,0xfffff
    80003f18:	f5c080e7          	jalr	-164(ra) # 80002e70 <bread>
    80003f1c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f1e:	000aa583          	lw	a1,0(s5)
    80003f22:	0289a503          	lw	a0,40(s3)
    80003f26:	fffff097          	auipc	ra,0xfffff
    80003f2a:	f4a080e7          	jalr	-182(ra) # 80002e70 <bread>
    80003f2e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f30:	40000613          	li	a2,1024
    80003f34:	05890593          	addi	a1,s2,88
    80003f38:	05850513          	addi	a0,a0,88
    80003f3c:	ffffd097          	auipc	ra,0xffffd
    80003f40:	e30080e7          	jalr	-464(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f44:	8526                	mv	a0,s1
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	01c080e7          	jalr	28(ra) # 80002f62 <bwrite>
    bunpin(dbuf);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	12a080e7          	jalr	298(ra) # 8000307a <bunpin>
    brelse(lbuf);
    80003f58:	854a                	mv	a0,s2
    80003f5a:	fffff097          	auipc	ra,0xfffff
    80003f5e:	046080e7          	jalr	70(ra) # 80002fa0 <brelse>
    brelse(dbuf);
    80003f62:	8526                	mv	a0,s1
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	03c080e7          	jalr	60(ra) # 80002fa0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f6c:	2a05                	addiw	s4,s4,1
    80003f6e:	0a91                	addi	s5,s5,4
    80003f70:	02c9a783          	lw	a5,44(s3)
    80003f74:	f8fa49e3          	blt	s4,a5,80003f06 <install_trans+0x30>
}
    80003f78:	70e2                	ld	ra,56(sp)
    80003f7a:	7442                	ld	s0,48(sp)
    80003f7c:	74a2                	ld	s1,40(sp)
    80003f7e:	7902                	ld	s2,32(sp)
    80003f80:	69e2                	ld	s3,24(sp)
    80003f82:	6a42                	ld	s4,16(sp)
    80003f84:	6aa2                	ld	s5,8(sp)
    80003f86:	6121                	addi	sp,sp,64
    80003f88:	8082                	ret
    80003f8a:	8082                	ret

0000000080003f8c <initlog>:
{
    80003f8c:	7179                	addi	sp,sp,-48
    80003f8e:	f406                	sd	ra,40(sp)
    80003f90:	f022                	sd	s0,32(sp)
    80003f92:	ec26                	sd	s1,24(sp)
    80003f94:	e84a                	sd	s2,16(sp)
    80003f96:	e44e                	sd	s3,8(sp)
    80003f98:	1800                	addi	s0,sp,48
    80003f9a:	892a                	mv	s2,a0
    80003f9c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f9e:	0001e497          	auipc	s1,0x1e
    80003fa2:	b6a48493          	addi	s1,s1,-1174 # 80021b08 <log>
    80003fa6:	00004597          	auipc	a1,0x4
    80003faa:	7da58593          	addi	a1,a1,2010 # 80008780 <syscalls_name+0x1e0>
    80003fae:	8526                	mv	a0,s1
    80003fb0:	ffffd097          	auipc	ra,0xffffd
    80003fb4:	bd0080e7          	jalr	-1072(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80003fb8:	0149a583          	lw	a1,20(s3)
    80003fbc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003fbe:	0109a783          	lw	a5,16(s3)
    80003fc2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003fc4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003fc8:	854a                	mv	a0,s2
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	ea6080e7          	jalr	-346(ra) # 80002e70 <bread>
  log.lh.n = lh->n;
    80003fd2:	4d3c                	lw	a5,88(a0)
    80003fd4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fd6:	02f05563          	blez	a5,80004000 <initlog+0x74>
    80003fda:	05c50713          	addi	a4,a0,92
    80003fde:	0001e697          	auipc	a3,0x1e
    80003fe2:	b5a68693          	addi	a3,a3,-1190 # 80021b38 <log+0x30>
    80003fe6:	37fd                	addiw	a5,a5,-1
    80003fe8:	1782                	slli	a5,a5,0x20
    80003fea:	9381                	srli	a5,a5,0x20
    80003fec:	078a                	slli	a5,a5,0x2
    80003fee:	06050613          	addi	a2,a0,96
    80003ff2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003ff4:	4310                	lw	a2,0(a4)
    80003ff6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003ff8:	0711                	addi	a4,a4,4
    80003ffa:	0691                	addi	a3,a3,4
    80003ffc:	fef71ce3          	bne	a4,a5,80003ff4 <initlog+0x68>
  brelse(buf);
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	fa0080e7          	jalr	-96(ra) # 80002fa0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	ece080e7          	jalr	-306(ra) # 80003ed6 <install_trans>
  log.lh.n = 0;
    80004010:	0001e797          	auipc	a5,0x1e
    80004014:	b207a223          	sw	zero,-1244(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	e44080e7          	jalr	-444(ra) # 80003e5c <write_head>
}
    80004020:	70a2                	ld	ra,40(sp)
    80004022:	7402                	ld	s0,32(sp)
    80004024:	64e2                	ld	s1,24(sp)
    80004026:	6942                	ld	s2,16(sp)
    80004028:	69a2                	ld	s3,8(sp)
    8000402a:	6145                	addi	sp,sp,48
    8000402c:	8082                	ret

000000008000402e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000402e:	1101                	addi	sp,sp,-32
    80004030:	ec06                	sd	ra,24(sp)
    80004032:	e822                	sd	s0,16(sp)
    80004034:	e426                	sd	s1,8(sp)
    80004036:	e04a                	sd	s2,0(sp)
    80004038:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000403a:	0001e517          	auipc	a0,0x1e
    8000403e:	ace50513          	addi	a0,a0,-1330 # 80021b08 <log>
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	bce080e7          	jalr	-1074(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    8000404a:	0001e497          	auipc	s1,0x1e
    8000404e:	abe48493          	addi	s1,s1,-1346 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004052:	4979                	li	s2,30
    80004054:	a039                	j	80004062 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004056:	85a6                	mv	a1,s1
    80004058:	8526                	mv	a0,s1
    8000405a:	ffffe097          	auipc	ra,0xffffe
    8000405e:	198080e7          	jalr	408(ra) # 800021f2 <sleep>
    if(log.committing){
    80004062:	50dc                	lw	a5,36(s1)
    80004064:	fbed                	bnez	a5,80004056 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004066:	509c                	lw	a5,32(s1)
    80004068:	0017871b          	addiw	a4,a5,1
    8000406c:	0007069b          	sext.w	a3,a4
    80004070:	0027179b          	slliw	a5,a4,0x2
    80004074:	9fb9                	addw	a5,a5,a4
    80004076:	0017979b          	slliw	a5,a5,0x1
    8000407a:	54d8                	lw	a4,44(s1)
    8000407c:	9fb9                	addw	a5,a5,a4
    8000407e:	00f95963          	bge	s2,a5,80004090 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004082:	85a6                	mv	a1,s1
    80004084:	8526                	mv	a0,s1
    80004086:	ffffe097          	auipc	ra,0xffffe
    8000408a:	16c080e7          	jalr	364(ra) # 800021f2 <sleep>
    8000408e:	bfd1                	j	80004062 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004090:	0001e517          	auipc	a0,0x1e
    80004094:	a7850513          	addi	a0,a0,-1416 # 80021b08 <log>
    80004098:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000409a:	ffffd097          	auipc	ra,0xffffd
    8000409e:	c2a080e7          	jalr	-982(ra) # 80000cc4 <release>
      break;
    }
  }
}
    800040a2:	60e2                	ld	ra,24(sp)
    800040a4:	6442                	ld	s0,16(sp)
    800040a6:	64a2                	ld	s1,8(sp)
    800040a8:	6902                	ld	s2,0(sp)
    800040aa:	6105                	addi	sp,sp,32
    800040ac:	8082                	ret

00000000800040ae <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040ae:	7139                	addi	sp,sp,-64
    800040b0:	fc06                	sd	ra,56(sp)
    800040b2:	f822                	sd	s0,48(sp)
    800040b4:	f426                	sd	s1,40(sp)
    800040b6:	f04a                	sd	s2,32(sp)
    800040b8:	ec4e                	sd	s3,24(sp)
    800040ba:	e852                	sd	s4,16(sp)
    800040bc:	e456                	sd	s5,8(sp)
    800040be:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800040c0:	0001e497          	auipc	s1,0x1e
    800040c4:	a4848493          	addi	s1,s1,-1464 # 80021b08 <log>
    800040c8:	8526                	mv	a0,s1
    800040ca:	ffffd097          	auipc	ra,0xffffd
    800040ce:	b46080e7          	jalr	-1210(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    800040d2:	509c                	lw	a5,32(s1)
    800040d4:	37fd                	addiw	a5,a5,-1
    800040d6:	0007891b          	sext.w	s2,a5
    800040da:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040dc:	50dc                	lw	a5,36(s1)
    800040de:	efb9                	bnez	a5,8000413c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040e0:	06091663          	bnez	s2,8000414c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800040e4:	0001e497          	auipc	s1,0x1e
    800040e8:	a2448493          	addi	s1,s1,-1500 # 80021b08 <log>
    800040ec:	4785                	li	a5,1
    800040ee:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040f0:	8526                	mv	a0,s1
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	bd2080e7          	jalr	-1070(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040fa:	54dc                	lw	a5,44(s1)
    800040fc:	06f04763          	bgtz	a5,8000416a <end_op+0xbc>
    acquire(&log.lock);
    80004100:	0001e497          	auipc	s1,0x1e
    80004104:	a0848493          	addi	s1,s1,-1528 # 80021b08 <log>
    80004108:	8526                	mv	a0,s1
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	b06080e7          	jalr	-1274(ra) # 80000c10 <acquire>
    log.committing = 0;
    80004112:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004116:	8526                	mv	a0,s1
    80004118:	ffffe097          	auipc	ra,0xffffe
    8000411c:	260080e7          	jalr	608(ra) # 80002378 <wakeup>
    release(&log.lock);
    80004120:	8526                	mv	a0,s1
    80004122:	ffffd097          	auipc	ra,0xffffd
    80004126:	ba2080e7          	jalr	-1118(ra) # 80000cc4 <release>
}
    8000412a:	70e2                	ld	ra,56(sp)
    8000412c:	7442                	ld	s0,48(sp)
    8000412e:	74a2                	ld	s1,40(sp)
    80004130:	7902                	ld	s2,32(sp)
    80004132:	69e2                	ld	s3,24(sp)
    80004134:	6a42                	ld	s4,16(sp)
    80004136:	6aa2                	ld	s5,8(sp)
    80004138:	6121                	addi	sp,sp,64
    8000413a:	8082                	ret
    panic("log.committing");
    8000413c:	00004517          	auipc	a0,0x4
    80004140:	64c50513          	addi	a0,a0,1612 # 80008788 <syscalls_name+0x1e8>
    80004144:	ffffc097          	auipc	ra,0xffffc
    80004148:	404080e7          	jalr	1028(ra) # 80000548 <panic>
    wakeup(&log);
    8000414c:	0001e497          	auipc	s1,0x1e
    80004150:	9bc48493          	addi	s1,s1,-1604 # 80021b08 <log>
    80004154:	8526                	mv	a0,s1
    80004156:	ffffe097          	auipc	ra,0xffffe
    8000415a:	222080e7          	jalr	546(ra) # 80002378 <wakeup>
  release(&log.lock);
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	b64080e7          	jalr	-1180(ra) # 80000cc4 <release>
  if(do_commit){
    80004168:	b7c9                	j	8000412a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416a:	0001ea97          	auipc	s5,0x1e
    8000416e:	9cea8a93          	addi	s5,s5,-1586 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004172:	0001ea17          	auipc	s4,0x1e
    80004176:	996a0a13          	addi	s4,s4,-1642 # 80021b08 <log>
    8000417a:	018a2583          	lw	a1,24(s4)
    8000417e:	012585bb          	addw	a1,a1,s2
    80004182:	2585                	addiw	a1,a1,1
    80004184:	028a2503          	lw	a0,40(s4)
    80004188:	fffff097          	auipc	ra,0xfffff
    8000418c:	ce8080e7          	jalr	-792(ra) # 80002e70 <bread>
    80004190:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004192:	000aa583          	lw	a1,0(s5)
    80004196:	028a2503          	lw	a0,40(s4)
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	cd6080e7          	jalr	-810(ra) # 80002e70 <bread>
    800041a2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041a4:	40000613          	li	a2,1024
    800041a8:	05850593          	addi	a1,a0,88
    800041ac:	05848513          	addi	a0,s1,88
    800041b0:	ffffd097          	auipc	ra,0xffffd
    800041b4:	bbc080e7          	jalr	-1092(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    800041b8:	8526                	mv	a0,s1
    800041ba:	fffff097          	auipc	ra,0xfffff
    800041be:	da8080e7          	jalr	-600(ra) # 80002f62 <bwrite>
    brelse(from);
    800041c2:	854e                	mv	a0,s3
    800041c4:	fffff097          	auipc	ra,0xfffff
    800041c8:	ddc080e7          	jalr	-548(ra) # 80002fa0 <brelse>
    brelse(to);
    800041cc:	8526                	mv	a0,s1
    800041ce:	fffff097          	auipc	ra,0xfffff
    800041d2:	dd2080e7          	jalr	-558(ra) # 80002fa0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d6:	2905                	addiw	s2,s2,1
    800041d8:	0a91                	addi	s5,s5,4
    800041da:	02ca2783          	lw	a5,44(s4)
    800041de:	f8f94ee3          	blt	s2,a5,8000417a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	c7a080e7          	jalr	-902(ra) # 80003e5c <write_head>
    install_trans(); // Now install writes to home locations
    800041ea:	00000097          	auipc	ra,0x0
    800041ee:	cec080e7          	jalr	-788(ra) # 80003ed6 <install_trans>
    log.lh.n = 0;
    800041f2:	0001e797          	auipc	a5,0x1e
    800041f6:	9407a123          	sw	zero,-1726(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041fa:	00000097          	auipc	ra,0x0
    800041fe:	c62080e7          	jalr	-926(ra) # 80003e5c <write_head>
    80004202:	bdfd                	j	80004100 <end_op+0x52>

0000000080004204 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004204:	1101                	addi	sp,sp,-32
    80004206:	ec06                	sd	ra,24(sp)
    80004208:	e822                	sd	s0,16(sp)
    8000420a:	e426                	sd	s1,8(sp)
    8000420c:	e04a                	sd	s2,0(sp)
    8000420e:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004210:	0001e717          	auipc	a4,0x1e
    80004214:	92472703          	lw	a4,-1756(a4) # 80021b34 <log+0x2c>
    80004218:	47f5                	li	a5,29
    8000421a:	08e7c063          	blt	a5,a4,8000429a <log_write+0x96>
    8000421e:	84aa                	mv	s1,a0
    80004220:	0001e797          	auipc	a5,0x1e
    80004224:	9047a783          	lw	a5,-1788(a5) # 80021b24 <log+0x1c>
    80004228:	37fd                	addiw	a5,a5,-1
    8000422a:	06f75863          	bge	a4,a5,8000429a <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000422e:	0001e797          	auipc	a5,0x1e
    80004232:	8fa7a783          	lw	a5,-1798(a5) # 80021b28 <log+0x20>
    80004236:	06f05a63          	blez	a5,800042aa <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000423a:	0001e917          	auipc	s2,0x1e
    8000423e:	8ce90913          	addi	s2,s2,-1842 # 80021b08 <log>
    80004242:	854a                	mv	a0,s2
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	9cc080e7          	jalr	-1588(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000424c:	02c92603          	lw	a2,44(s2)
    80004250:	06c05563          	blez	a2,800042ba <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004254:	44cc                	lw	a1,12(s1)
    80004256:	0001e717          	auipc	a4,0x1e
    8000425a:	8e270713          	addi	a4,a4,-1822 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000425e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004260:	4314                	lw	a3,0(a4)
    80004262:	04b68d63          	beq	a3,a1,800042bc <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004266:	2785                	addiw	a5,a5,1
    80004268:	0711                	addi	a4,a4,4
    8000426a:	fec79be3          	bne	a5,a2,80004260 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000426e:	0621                	addi	a2,a2,8
    80004270:	060a                	slli	a2,a2,0x2
    80004272:	0001e797          	auipc	a5,0x1e
    80004276:	89678793          	addi	a5,a5,-1898 # 80021b08 <log>
    8000427a:	963e                	add	a2,a2,a5
    8000427c:	44dc                	lw	a5,12(s1)
    8000427e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004280:	8526                	mv	a0,s1
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	dbc080e7          	jalr	-580(ra) # 8000303e <bpin>
    log.lh.n++;
    8000428a:	0001e717          	auipc	a4,0x1e
    8000428e:	87e70713          	addi	a4,a4,-1922 # 80021b08 <log>
    80004292:	575c                	lw	a5,44(a4)
    80004294:	2785                	addiw	a5,a5,1
    80004296:	d75c                	sw	a5,44(a4)
    80004298:	a83d                	j	800042d6 <log_write+0xd2>
    panic("too big a transaction");
    8000429a:	00004517          	auipc	a0,0x4
    8000429e:	4fe50513          	addi	a0,a0,1278 # 80008798 <syscalls_name+0x1f8>
    800042a2:	ffffc097          	auipc	ra,0xffffc
    800042a6:	2a6080e7          	jalr	678(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800042aa:	00004517          	auipc	a0,0x4
    800042ae:	50650513          	addi	a0,a0,1286 # 800087b0 <syscalls_name+0x210>
    800042b2:	ffffc097          	auipc	ra,0xffffc
    800042b6:	296080e7          	jalr	662(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800042ba:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800042bc:	00878713          	addi	a4,a5,8
    800042c0:	00271693          	slli	a3,a4,0x2
    800042c4:	0001e717          	auipc	a4,0x1e
    800042c8:	84470713          	addi	a4,a4,-1980 # 80021b08 <log>
    800042cc:	9736                	add	a4,a4,a3
    800042ce:	44d4                	lw	a3,12(s1)
    800042d0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042d2:	faf607e3          	beq	a2,a5,80004280 <log_write+0x7c>
  }
  release(&log.lock);
    800042d6:	0001e517          	auipc	a0,0x1e
    800042da:	83250513          	addi	a0,a0,-1998 # 80021b08 <log>
    800042de:	ffffd097          	auipc	ra,0xffffd
    800042e2:	9e6080e7          	jalr	-1562(ra) # 80000cc4 <release>
}
    800042e6:	60e2                	ld	ra,24(sp)
    800042e8:	6442                	ld	s0,16(sp)
    800042ea:	64a2                	ld	s1,8(sp)
    800042ec:	6902                	ld	s2,0(sp)
    800042ee:	6105                	addi	sp,sp,32
    800042f0:	8082                	ret

00000000800042f2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042f2:	1101                	addi	sp,sp,-32
    800042f4:	ec06                	sd	ra,24(sp)
    800042f6:	e822                	sd	s0,16(sp)
    800042f8:	e426                	sd	s1,8(sp)
    800042fa:	e04a                	sd	s2,0(sp)
    800042fc:	1000                	addi	s0,sp,32
    800042fe:	84aa                	mv	s1,a0
    80004300:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004302:	00004597          	auipc	a1,0x4
    80004306:	4ce58593          	addi	a1,a1,1230 # 800087d0 <syscalls_name+0x230>
    8000430a:	0521                	addi	a0,a0,8
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	874080e7          	jalr	-1932(ra) # 80000b80 <initlock>
  lk->name = name;
    80004314:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004318:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000431c:	0204a423          	sw	zero,40(s1)
}
    80004320:	60e2                	ld	ra,24(sp)
    80004322:	6442                	ld	s0,16(sp)
    80004324:	64a2                	ld	s1,8(sp)
    80004326:	6902                	ld	s2,0(sp)
    80004328:	6105                	addi	sp,sp,32
    8000432a:	8082                	ret

000000008000432c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000432c:	1101                	addi	sp,sp,-32
    8000432e:	ec06                	sd	ra,24(sp)
    80004330:	e822                	sd	s0,16(sp)
    80004332:	e426                	sd	s1,8(sp)
    80004334:	e04a                	sd	s2,0(sp)
    80004336:	1000                	addi	s0,sp,32
    80004338:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000433a:	00850913          	addi	s2,a0,8
    8000433e:	854a                	mv	a0,s2
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	8d0080e7          	jalr	-1840(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004348:	409c                	lw	a5,0(s1)
    8000434a:	cb89                	beqz	a5,8000435c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000434c:	85ca                	mv	a1,s2
    8000434e:	8526                	mv	a0,s1
    80004350:	ffffe097          	auipc	ra,0xffffe
    80004354:	ea2080e7          	jalr	-350(ra) # 800021f2 <sleep>
  while (lk->locked) {
    80004358:	409c                	lw	a5,0(s1)
    8000435a:	fbed                	bnez	a5,8000434c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000435c:	4785                	li	a5,1
    8000435e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	67e080e7          	jalr	1662(ra) # 800019de <myproc>
    80004368:	5d1c                	lw	a5,56(a0)
    8000436a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000436c:	854a                	mv	a0,s2
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	956080e7          	jalr	-1706(ra) # 80000cc4 <release>
}
    80004376:	60e2                	ld	ra,24(sp)
    80004378:	6442                	ld	s0,16(sp)
    8000437a:	64a2                	ld	s1,8(sp)
    8000437c:	6902                	ld	s2,0(sp)
    8000437e:	6105                	addi	sp,sp,32
    80004380:	8082                	ret

0000000080004382 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004382:	1101                	addi	sp,sp,-32
    80004384:	ec06                	sd	ra,24(sp)
    80004386:	e822                	sd	s0,16(sp)
    80004388:	e426                	sd	s1,8(sp)
    8000438a:	e04a                	sd	s2,0(sp)
    8000438c:	1000                	addi	s0,sp,32
    8000438e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004390:	00850913          	addi	s2,a0,8
    80004394:	854a                	mv	a0,s2
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	87a080e7          	jalr	-1926(ra) # 80000c10 <acquire>
  lk->locked = 0;
    8000439e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043a2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043a6:	8526                	mv	a0,s1
    800043a8:	ffffe097          	auipc	ra,0xffffe
    800043ac:	fd0080e7          	jalr	-48(ra) # 80002378 <wakeup>
  release(&lk->lk);
    800043b0:	854a                	mv	a0,s2
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	912080e7          	jalr	-1774(ra) # 80000cc4 <release>
}
    800043ba:	60e2                	ld	ra,24(sp)
    800043bc:	6442                	ld	s0,16(sp)
    800043be:	64a2                	ld	s1,8(sp)
    800043c0:	6902                	ld	s2,0(sp)
    800043c2:	6105                	addi	sp,sp,32
    800043c4:	8082                	ret

00000000800043c6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800043c6:	7179                	addi	sp,sp,-48
    800043c8:	f406                	sd	ra,40(sp)
    800043ca:	f022                	sd	s0,32(sp)
    800043cc:	ec26                	sd	s1,24(sp)
    800043ce:	e84a                	sd	s2,16(sp)
    800043d0:	e44e                	sd	s3,8(sp)
    800043d2:	1800                	addi	s0,sp,48
    800043d4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043d6:	00850913          	addi	s2,a0,8
    800043da:	854a                	mv	a0,s2
    800043dc:	ffffd097          	auipc	ra,0xffffd
    800043e0:	834080e7          	jalr	-1996(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043e4:	409c                	lw	a5,0(s1)
    800043e6:	ef99                	bnez	a5,80004404 <holdingsleep+0x3e>
    800043e8:	4481                	li	s1,0
  release(&lk->lk);
    800043ea:	854a                	mv	a0,s2
    800043ec:	ffffd097          	auipc	ra,0xffffd
    800043f0:	8d8080e7          	jalr	-1832(ra) # 80000cc4 <release>
  return r;
}
    800043f4:	8526                	mv	a0,s1
    800043f6:	70a2                	ld	ra,40(sp)
    800043f8:	7402                	ld	s0,32(sp)
    800043fa:	64e2                	ld	s1,24(sp)
    800043fc:	6942                	ld	s2,16(sp)
    800043fe:	69a2                	ld	s3,8(sp)
    80004400:	6145                	addi	sp,sp,48
    80004402:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004404:	0284a983          	lw	s3,40(s1)
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	5d6080e7          	jalr	1494(ra) # 800019de <myproc>
    80004410:	5d04                	lw	s1,56(a0)
    80004412:	413484b3          	sub	s1,s1,s3
    80004416:	0014b493          	seqz	s1,s1
    8000441a:	bfc1                	j	800043ea <holdingsleep+0x24>

000000008000441c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000441c:	1141                	addi	sp,sp,-16
    8000441e:	e406                	sd	ra,8(sp)
    80004420:	e022                	sd	s0,0(sp)
    80004422:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004424:	00004597          	auipc	a1,0x4
    80004428:	3bc58593          	addi	a1,a1,956 # 800087e0 <syscalls_name+0x240>
    8000442c:	0001e517          	auipc	a0,0x1e
    80004430:	82450513          	addi	a0,a0,-2012 # 80021c50 <ftable>
    80004434:	ffffc097          	auipc	ra,0xffffc
    80004438:	74c080e7          	jalr	1868(ra) # 80000b80 <initlock>
}
    8000443c:	60a2                	ld	ra,8(sp)
    8000443e:	6402                	ld	s0,0(sp)
    80004440:	0141                	addi	sp,sp,16
    80004442:	8082                	ret

0000000080004444 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004444:	1101                	addi	sp,sp,-32
    80004446:	ec06                	sd	ra,24(sp)
    80004448:	e822                	sd	s0,16(sp)
    8000444a:	e426                	sd	s1,8(sp)
    8000444c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000444e:	0001e517          	auipc	a0,0x1e
    80004452:	80250513          	addi	a0,a0,-2046 # 80021c50 <ftable>
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	7ba080e7          	jalr	1978(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000445e:	0001e497          	auipc	s1,0x1e
    80004462:	80a48493          	addi	s1,s1,-2038 # 80021c68 <ftable+0x18>
    80004466:	0001e717          	auipc	a4,0x1e
    8000446a:	7a270713          	addi	a4,a4,1954 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    8000446e:	40dc                	lw	a5,4(s1)
    80004470:	cf99                	beqz	a5,8000448e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004472:	02848493          	addi	s1,s1,40
    80004476:	fee49ce3          	bne	s1,a4,8000446e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000447a:	0001d517          	auipc	a0,0x1d
    8000447e:	7d650513          	addi	a0,a0,2006 # 80021c50 <ftable>
    80004482:	ffffd097          	auipc	ra,0xffffd
    80004486:	842080e7          	jalr	-1982(ra) # 80000cc4 <release>
  return 0;
    8000448a:	4481                	li	s1,0
    8000448c:	a819                	j	800044a2 <filealloc+0x5e>
      f->ref = 1;
    8000448e:	4785                	li	a5,1
    80004490:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004492:	0001d517          	auipc	a0,0x1d
    80004496:	7be50513          	addi	a0,a0,1982 # 80021c50 <ftable>
    8000449a:	ffffd097          	auipc	ra,0xffffd
    8000449e:	82a080e7          	jalr	-2006(ra) # 80000cc4 <release>
}
    800044a2:	8526                	mv	a0,s1
    800044a4:	60e2                	ld	ra,24(sp)
    800044a6:	6442                	ld	s0,16(sp)
    800044a8:	64a2                	ld	s1,8(sp)
    800044aa:	6105                	addi	sp,sp,32
    800044ac:	8082                	ret

00000000800044ae <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044ae:	1101                	addi	sp,sp,-32
    800044b0:	ec06                	sd	ra,24(sp)
    800044b2:	e822                	sd	s0,16(sp)
    800044b4:	e426                	sd	s1,8(sp)
    800044b6:	1000                	addi	s0,sp,32
    800044b8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044ba:	0001d517          	auipc	a0,0x1d
    800044be:	79650513          	addi	a0,a0,1942 # 80021c50 <ftable>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	74e080e7          	jalr	1870(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800044ca:	40dc                	lw	a5,4(s1)
    800044cc:	02f05263          	blez	a5,800044f0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044d0:	2785                	addiw	a5,a5,1
    800044d2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044d4:	0001d517          	auipc	a0,0x1d
    800044d8:	77c50513          	addi	a0,a0,1916 # 80021c50 <ftable>
    800044dc:	ffffc097          	auipc	ra,0xffffc
    800044e0:	7e8080e7          	jalr	2024(ra) # 80000cc4 <release>
  return f;
}
    800044e4:	8526                	mv	a0,s1
    800044e6:	60e2                	ld	ra,24(sp)
    800044e8:	6442                	ld	s0,16(sp)
    800044ea:	64a2                	ld	s1,8(sp)
    800044ec:	6105                	addi	sp,sp,32
    800044ee:	8082                	ret
    panic("filedup");
    800044f0:	00004517          	auipc	a0,0x4
    800044f4:	2f850513          	addi	a0,a0,760 # 800087e8 <syscalls_name+0x248>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	050080e7          	jalr	80(ra) # 80000548 <panic>

0000000080004500 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004500:	7139                	addi	sp,sp,-64
    80004502:	fc06                	sd	ra,56(sp)
    80004504:	f822                	sd	s0,48(sp)
    80004506:	f426                	sd	s1,40(sp)
    80004508:	f04a                	sd	s2,32(sp)
    8000450a:	ec4e                	sd	s3,24(sp)
    8000450c:	e852                	sd	s4,16(sp)
    8000450e:	e456                	sd	s5,8(sp)
    80004510:	0080                	addi	s0,sp,64
    80004512:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004514:	0001d517          	auipc	a0,0x1d
    80004518:	73c50513          	addi	a0,a0,1852 # 80021c50 <ftable>
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	6f4080e7          	jalr	1780(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004524:	40dc                	lw	a5,4(s1)
    80004526:	06f05163          	blez	a5,80004588 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000452a:	37fd                	addiw	a5,a5,-1
    8000452c:	0007871b          	sext.w	a4,a5
    80004530:	c0dc                	sw	a5,4(s1)
    80004532:	06e04363          	bgtz	a4,80004598 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004536:	0004a903          	lw	s2,0(s1)
    8000453a:	0094ca83          	lbu	s5,9(s1)
    8000453e:	0104ba03          	ld	s4,16(s1)
    80004542:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004546:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000454a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000454e:	0001d517          	auipc	a0,0x1d
    80004552:	70250513          	addi	a0,a0,1794 # 80021c50 <ftable>
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	76e080e7          	jalr	1902(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    8000455e:	4785                	li	a5,1
    80004560:	04f90d63          	beq	s2,a5,800045ba <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004564:	3979                	addiw	s2,s2,-2
    80004566:	4785                	li	a5,1
    80004568:	0527e063          	bltu	a5,s2,800045a8 <fileclose+0xa8>
    begin_op();
    8000456c:	00000097          	auipc	ra,0x0
    80004570:	ac2080e7          	jalr	-1342(ra) # 8000402e <begin_op>
    iput(ff.ip);
    80004574:	854e                	mv	a0,s3
    80004576:	fffff097          	auipc	ra,0xfffff
    8000457a:	2b6080e7          	jalr	694(ra) # 8000382c <iput>
    end_op();
    8000457e:	00000097          	auipc	ra,0x0
    80004582:	b30080e7          	jalr	-1232(ra) # 800040ae <end_op>
    80004586:	a00d                	j	800045a8 <fileclose+0xa8>
    panic("fileclose");
    80004588:	00004517          	auipc	a0,0x4
    8000458c:	26850513          	addi	a0,a0,616 # 800087f0 <syscalls_name+0x250>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	fb8080e7          	jalr	-72(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004598:	0001d517          	auipc	a0,0x1d
    8000459c:	6b850513          	addi	a0,a0,1720 # 80021c50 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	724080e7          	jalr	1828(ra) # 80000cc4 <release>
  }
}
    800045a8:	70e2                	ld	ra,56(sp)
    800045aa:	7442                	ld	s0,48(sp)
    800045ac:	74a2                	ld	s1,40(sp)
    800045ae:	7902                	ld	s2,32(sp)
    800045b0:	69e2                	ld	s3,24(sp)
    800045b2:	6a42                	ld	s4,16(sp)
    800045b4:	6aa2                	ld	s5,8(sp)
    800045b6:	6121                	addi	sp,sp,64
    800045b8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045ba:	85d6                	mv	a1,s5
    800045bc:	8552                	mv	a0,s4
    800045be:	00000097          	auipc	ra,0x0
    800045c2:	372080e7          	jalr	882(ra) # 80004930 <pipeclose>
    800045c6:	b7cd                	j	800045a8 <fileclose+0xa8>

00000000800045c8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800045c8:	715d                	addi	sp,sp,-80
    800045ca:	e486                	sd	ra,72(sp)
    800045cc:	e0a2                	sd	s0,64(sp)
    800045ce:	fc26                	sd	s1,56(sp)
    800045d0:	f84a                	sd	s2,48(sp)
    800045d2:	f44e                	sd	s3,40(sp)
    800045d4:	0880                	addi	s0,sp,80
    800045d6:	84aa                	mv	s1,a0
    800045d8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045da:	ffffd097          	auipc	ra,0xffffd
    800045de:	404080e7          	jalr	1028(ra) # 800019de <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045e2:	409c                	lw	a5,0(s1)
    800045e4:	37f9                	addiw	a5,a5,-2
    800045e6:	4705                	li	a4,1
    800045e8:	04f76763          	bltu	a4,a5,80004636 <filestat+0x6e>
    800045ec:	892a                	mv	s2,a0
    ilock(f->ip);
    800045ee:	6c88                	ld	a0,24(s1)
    800045f0:	fffff097          	auipc	ra,0xfffff
    800045f4:	082080e7          	jalr	130(ra) # 80003672 <ilock>
    stati(f->ip, &st);
    800045f8:	fb840593          	addi	a1,s0,-72
    800045fc:	6c88                	ld	a0,24(s1)
    800045fe:	fffff097          	auipc	ra,0xfffff
    80004602:	2fe080e7          	jalr	766(ra) # 800038fc <stati>
    iunlock(f->ip);
    80004606:	6c88                	ld	a0,24(s1)
    80004608:	fffff097          	auipc	ra,0xfffff
    8000460c:	12c080e7          	jalr	300(ra) # 80003734 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004610:	46e1                	li	a3,24
    80004612:	fb840613          	addi	a2,s0,-72
    80004616:	85ce                	mv	a1,s3
    80004618:	05093503          	ld	a0,80(s2)
    8000461c:	ffffd097          	auipc	ra,0xffffd
    80004620:	0b6080e7          	jalr	182(ra) # 800016d2 <copyout>
    80004624:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004628:	60a6                	ld	ra,72(sp)
    8000462a:	6406                	ld	s0,64(sp)
    8000462c:	74e2                	ld	s1,56(sp)
    8000462e:	7942                	ld	s2,48(sp)
    80004630:	79a2                	ld	s3,40(sp)
    80004632:	6161                	addi	sp,sp,80
    80004634:	8082                	ret
  return -1;
    80004636:	557d                	li	a0,-1
    80004638:	bfc5                	j	80004628 <filestat+0x60>

000000008000463a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000463a:	7179                	addi	sp,sp,-48
    8000463c:	f406                	sd	ra,40(sp)
    8000463e:	f022                	sd	s0,32(sp)
    80004640:	ec26                	sd	s1,24(sp)
    80004642:	e84a                	sd	s2,16(sp)
    80004644:	e44e                	sd	s3,8(sp)
    80004646:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004648:	00854783          	lbu	a5,8(a0)
    8000464c:	c3d5                	beqz	a5,800046f0 <fileread+0xb6>
    8000464e:	84aa                	mv	s1,a0
    80004650:	89ae                	mv	s3,a1
    80004652:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004654:	411c                	lw	a5,0(a0)
    80004656:	4705                	li	a4,1
    80004658:	04e78963          	beq	a5,a4,800046aa <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000465c:	470d                	li	a4,3
    8000465e:	04e78d63          	beq	a5,a4,800046b8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004662:	4709                	li	a4,2
    80004664:	06e79e63          	bne	a5,a4,800046e0 <fileread+0xa6>
    ilock(f->ip);
    80004668:	6d08                	ld	a0,24(a0)
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	008080e7          	jalr	8(ra) # 80003672 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004672:	874a                	mv	a4,s2
    80004674:	5094                	lw	a3,32(s1)
    80004676:	864e                	mv	a2,s3
    80004678:	4585                	li	a1,1
    8000467a:	6c88                	ld	a0,24(s1)
    8000467c:	fffff097          	auipc	ra,0xfffff
    80004680:	2aa080e7          	jalr	682(ra) # 80003926 <readi>
    80004684:	892a                	mv	s2,a0
    80004686:	00a05563          	blez	a0,80004690 <fileread+0x56>
      f->off += r;
    8000468a:	509c                	lw	a5,32(s1)
    8000468c:	9fa9                	addw	a5,a5,a0
    8000468e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004690:	6c88                	ld	a0,24(s1)
    80004692:	fffff097          	auipc	ra,0xfffff
    80004696:	0a2080e7          	jalr	162(ra) # 80003734 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000469a:	854a                	mv	a0,s2
    8000469c:	70a2                	ld	ra,40(sp)
    8000469e:	7402                	ld	s0,32(sp)
    800046a0:	64e2                	ld	s1,24(sp)
    800046a2:	6942                	ld	s2,16(sp)
    800046a4:	69a2                	ld	s3,8(sp)
    800046a6:	6145                	addi	sp,sp,48
    800046a8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046aa:	6908                	ld	a0,16(a0)
    800046ac:	00000097          	auipc	ra,0x0
    800046b0:	418080e7          	jalr	1048(ra) # 80004ac4 <piperead>
    800046b4:	892a                	mv	s2,a0
    800046b6:	b7d5                	j	8000469a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046b8:	02451783          	lh	a5,36(a0)
    800046bc:	03079693          	slli	a3,a5,0x30
    800046c0:	92c1                	srli	a3,a3,0x30
    800046c2:	4725                	li	a4,9
    800046c4:	02d76863          	bltu	a4,a3,800046f4 <fileread+0xba>
    800046c8:	0792                	slli	a5,a5,0x4
    800046ca:	0001d717          	auipc	a4,0x1d
    800046ce:	4e670713          	addi	a4,a4,1254 # 80021bb0 <devsw>
    800046d2:	97ba                	add	a5,a5,a4
    800046d4:	639c                	ld	a5,0(a5)
    800046d6:	c38d                	beqz	a5,800046f8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046d8:	4505                	li	a0,1
    800046da:	9782                	jalr	a5
    800046dc:	892a                	mv	s2,a0
    800046de:	bf75                	j	8000469a <fileread+0x60>
    panic("fileread");
    800046e0:	00004517          	auipc	a0,0x4
    800046e4:	12050513          	addi	a0,a0,288 # 80008800 <syscalls_name+0x260>
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	e60080e7          	jalr	-416(ra) # 80000548 <panic>
    return -1;
    800046f0:	597d                	li	s2,-1
    800046f2:	b765                	j	8000469a <fileread+0x60>
      return -1;
    800046f4:	597d                	li	s2,-1
    800046f6:	b755                	j	8000469a <fileread+0x60>
    800046f8:	597d                	li	s2,-1
    800046fa:	b745                	j	8000469a <fileread+0x60>

00000000800046fc <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800046fc:	00954783          	lbu	a5,9(a0)
    80004700:	14078563          	beqz	a5,8000484a <filewrite+0x14e>
{
    80004704:	715d                	addi	sp,sp,-80
    80004706:	e486                	sd	ra,72(sp)
    80004708:	e0a2                	sd	s0,64(sp)
    8000470a:	fc26                	sd	s1,56(sp)
    8000470c:	f84a                	sd	s2,48(sp)
    8000470e:	f44e                	sd	s3,40(sp)
    80004710:	f052                	sd	s4,32(sp)
    80004712:	ec56                	sd	s5,24(sp)
    80004714:	e85a                	sd	s6,16(sp)
    80004716:	e45e                	sd	s7,8(sp)
    80004718:	e062                	sd	s8,0(sp)
    8000471a:	0880                	addi	s0,sp,80
    8000471c:	892a                	mv	s2,a0
    8000471e:	8aae                	mv	s5,a1
    80004720:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004722:	411c                	lw	a5,0(a0)
    80004724:	4705                	li	a4,1
    80004726:	02e78263          	beq	a5,a4,8000474a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000472a:	470d                	li	a4,3
    8000472c:	02e78563          	beq	a5,a4,80004756 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004730:	4709                	li	a4,2
    80004732:	10e79463          	bne	a5,a4,8000483a <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004736:	0ec05e63          	blez	a2,80004832 <filewrite+0x136>
    int i = 0;
    8000473a:	4981                	li	s3,0
    8000473c:	6b05                	lui	s6,0x1
    8000473e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004742:	6b85                	lui	s7,0x1
    80004744:	c00b8b9b          	addiw	s7,s7,-1024
    80004748:	a851                	j	800047dc <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000474a:	6908                	ld	a0,16(a0)
    8000474c:	00000097          	auipc	ra,0x0
    80004750:	254080e7          	jalr	596(ra) # 800049a0 <pipewrite>
    80004754:	a85d                	j	8000480a <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004756:	02451783          	lh	a5,36(a0)
    8000475a:	03079693          	slli	a3,a5,0x30
    8000475e:	92c1                	srli	a3,a3,0x30
    80004760:	4725                	li	a4,9
    80004762:	0ed76663          	bltu	a4,a3,8000484e <filewrite+0x152>
    80004766:	0792                	slli	a5,a5,0x4
    80004768:	0001d717          	auipc	a4,0x1d
    8000476c:	44870713          	addi	a4,a4,1096 # 80021bb0 <devsw>
    80004770:	97ba                	add	a5,a5,a4
    80004772:	679c                	ld	a5,8(a5)
    80004774:	cff9                	beqz	a5,80004852 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004776:	4505                	li	a0,1
    80004778:	9782                	jalr	a5
    8000477a:	a841                	j	8000480a <filewrite+0x10e>
    8000477c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004780:	00000097          	auipc	ra,0x0
    80004784:	8ae080e7          	jalr	-1874(ra) # 8000402e <begin_op>
      ilock(f->ip);
    80004788:	01893503          	ld	a0,24(s2)
    8000478c:	fffff097          	auipc	ra,0xfffff
    80004790:	ee6080e7          	jalr	-282(ra) # 80003672 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004794:	8762                	mv	a4,s8
    80004796:	02092683          	lw	a3,32(s2)
    8000479a:	01598633          	add	a2,s3,s5
    8000479e:	4585                	li	a1,1
    800047a0:	01893503          	ld	a0,24(s2)
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	278080e7          	jalr	632(ra) # 80003a1c <writei>
    800047ac:	84aa                	mv	s1,a0
    800047ae:	02a05f63          	blez	a0,800047ec <filewrite+0xf0>
        f->off += r;
    800047b2:	02092783          	lw	a5,32(s2)
    800047b6:	9fa9                	addw	a5,a5,a0
    800047b8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047bc:	01893503          	ld	a0,24(s2)
    800047c0:	fffff097          	auipc	ra,0xfffff
    800047c4:	f74080e7          	jalr	-140(ra) # 80003734 <iunlock>
      end_op();
    800047c8:	00000097          	auipc	ra,0x0
    800047cc:	8e6080e7          	jalr	-1818(ra) # 800040ae <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800047d0:	049c1963          	bne	s8,s1,80004822 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800047d4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047d8:	0349d663          	bge	s3,s4,80004804 <filewrite+0x108>
      int n1 = n - i;
    800047dc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800047e0:	84be                	mv	s1,a5
    800047e2:	2781                	sext.w	a5,a5
    800047e4:	f8fb5ce3          	bge	s6,a5,8000477c <filewrite+0x80>
    800047e8:	84de                	mv	s1,s7
    800047ea:	bf49                	j	8000477c <filewrite+0x80>
      iunlock(f->ip);
    800047ec:	01893503          	ld	a0,24(s2)
    800047f0:	fffff097          	auipc	ra,0xfffff
    800047f4:	f44080e7          	jalr	-188(ra) # 80003734 <iunlock>
      end_op();
    800047f8:	00000097          	auipc	ra,0x0
    800047fc:	8b6080e7          	jalr	-1866(ra) # 800040ae <end_op>
      if(r < 0)
    80004800:	fc04d8e3          	bgez	s1,800047d0 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004804:	8552                	mv	a0,s4
    80004806:	033a1863          	bne	s4,s3,80004836 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000480a:	60a6                	ld	ra,72(sp)
    8000480c:	6406                	ld	s0,64(sp)
    8000480e:	74e2                	ld	s1,56(sp)
    80004810:	7942                	ld	s2,48(sp)
    80004812:	79a2                	ld	s3,40(sp)
    80004814:	7a02                	ld	s4,32(sp)
    80004816:	6ae2                	ld	s5,24(sp)
    80004818:	6b42                	ld	s6,16(sp)
    8000481a:	6ba2                	ld	s7,8(sp)
    8000481c:	6c02                	ld	s8,0(sp)
    8000481e:	6161                	addi	sp,sp,80
    80004820:	8082                	ret
        panic("short filewrite");
    80004822:	00004517          	auipc	a0,0x4
    80004826:	fee50513          	addi	a0,a0,-18 # 80008810 <syscalls_name+0x270>
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	d1e080e7          	jalr	-738(ra) # 80000548 <panic>
    int i = 0;
    80004832:	4981                	li	s3,0
    80004834:	bfc1                	j	80004804 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004836:	557d                	li	a0,-1
    80004838:	bfc9                	j	8000480a <filewrite+0x10e>
    panic("filewrite");
    8000483a:	00004517          	auipc	a0,0x4
    8000483e:	fe650513          	addi	a0,a0,-26 # 80008820 <syscalls_name+0x280>
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	d06080e7          	jalr	-762(ra) # 80000548 <panic>
    return -1;
    8000484a:	557d                	li	a0,-1
}
    8000484c:	8082                	ret
      return -1;
    8000484e:	557d                	li	a0,-1
    80004850:	bf6d                	j	8000480a <filewrite+0x10e>
    80004852:	557d                	li	a0,-1
    80004854:	bf5d                	j	8000480a <filewrite+0x10e>

0000000080004856 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004856:	7179                	addi	sp,sp,-48
    80004858:	f406                	sd	ra,40(sp)
    8000485a:	f022                	sd	s0,32(sp)
    8000485c:	ec26                	sd	s1,24(sp)
    8000485e:	e84a                	sd	s2,16(sp)
    80004860:	e44e                	sd	s3,8(sp)
    80004862:	e052                	sd	s4,0(sp)
    80004864:	1800                	addi	s0,sp,48
    80004866:	84aa                	mv	s1,a0
    80004868:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000486a:	0005b023          	sd	zero,0(a1)
    8000486e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004872:	00000097          	auipc	ra,0x0
    80004876:	bd2080e7          	jalr	-1070(ra) # 80004444 <filealloc>
    8000487a:	e088                	sd	a0,0(s1)
    8000487c:	c551                	beqz	a0,80004908 <pipealloc+0xb2>
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	bc6080e7          	jalr	-1082(ra) # 80004444 <filealloc>
    80004886:	00aa3023          	sd	a0,0(s4)
    8000488a:	c92d                	beqz	a0,800048fc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000488c:	ffffc097          	auipc	ra,0xffffc
    80004890:	294080e7          	jalr	660(ra) # 80000b20 <kalloc>
    80004894:	892a                	mv	s2,a0
    80004896:	c125                	beqz	a0,800048f6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004898:	4985                	li	s3,1
    8000489a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000489e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048a2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048a6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048aa:	00004597          	auipc	a1,0x4
    800048ae:	b9658593          	addi	a1,a1,-1130 # 80008440 <states.1703+0x198>
    800048b2:	ffffc097          	auipc	ra,0xffffc
    800048b6:	2ce080e7          	jalr	718(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    800048ba:	609c                	ld	a5,0(s1)
    800048bc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048c0:	609c                	ld	a5,0(s1)
    800048c2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048c6:	609c                	ld	a5,0(s1)
    800048c8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048cc:	609c                	ld	a5,0(s1)
    800048ce:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048d2:	000a3783          	ld	a5,0(s4)
    800048d6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048da:	000a3783          	ld	a5,0(s4)
    800048de:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048e2:	000a3783          	ld	a5,0(s4)
    800048e6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048ea:	000a3783          	ld	a5,0(s4)
    800048ee:	0127b823          	sd	s2,16(a5)
  return 0;
    800048f2:	4501                	li	a0,0
    800048f4:	a025                	j	8000491c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048f6:	6088                	ld	a0,0(s1)
    800048f8:	e501                	bnez	a0,80004900 <pipealloc+0xaa>
    800048fa:	a039                	j	80004908 <pipealloc+0xb2>
    800048fc:	6088                	ld	a0,0(s1)
    800048fe:	c51d                	beqz	a0,8000492c <pipealloc+0xd6>
    fileclose(*f0);
    80004900:	00000097          	auipc	ra,0x0
    80004904:	c00080e7          	jalr	-1024(ra) # 80004500 <fileclose>
  if(*f1)
    80004908:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000490c:	557d                	li	a0,-1
  if(*f1)
    8000490e:	c799                	beqz	a5,8000491c <pipealloc+0xc6>
    fileclose(*f1);
    80004910:	853e                	mv	a0,a5
    80004912:	00000097          	auipc	ra,0x0
    80004916:	bee080e7          	jalr	-1042(ra) # 80004500 <fileclose>
  return -1;
    8000491a:	557d                	li	a0,-1
}
    8000491c:	70a2                	ld	ra,40(sp)
    8000491e:	7402                	ld	s0,32(sp)
    80004920:	64e2                	ld	s1,24(sp)
    80004922:	6942                	ld	s2,16(sp)
    80004924:	69a2                	ld	s3,8(sp)
    80004926:	6a02                	ld	s4,0(sp)
    80004928:	6145                	addi	sp,sp,48
    8000492a:	8082                	ret
  return -1;
    8000492c:	557d                	li	a0,-1
    8000492e:	b7fd                	j	8000491c <pipealloc+0xc6>

0000000080004930 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004930:	1101                	addi	sp,sp,-32
    80004932:	ec06                	sd	ra,24(sp)
    80004934:	e822                	sd	s0,16(sp)
    80004936:	e426                	sd	s1,8(sp)
    80004938:	e04a                	sd	s2,0(sp)
    8000493a:	1000                	addi	s0,sp,32
    8000493c:	84aa                	mv	s1,a0
    8000493e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004940:	ffffc097          	auipc	ra,0xffffc
    80004944:	2d0080e7          	jalr	720(ra) # 80000c10 <acquire>
  if(writable){
    80004948:	02090d63          	beqz	s2,80004982 <pipeclose+0x52>
    pi->writeopen = 0;
    8000494c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004950:	21848513          	addi	a0,s1,536
    80004954:	ffffe097          	auipc	ra,0xffffe
    80004958:	a24080e7          	jalr	-1500(ra) # 80002378 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000495c:	2204b783          	ld	a5,544(s1)
    80004960:	eb95                	bnez	a5,80004994 <pipeclose+0x64>
    release(&pi->lock);
    80004962:	8526                	mv	a0,s1
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	360080e7          	jalr	864(ra) # 80000cc4 <release>
    kfree((char*)pi);
    8000496c:	8526                	mv	a0,s1
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	0b6080e7          	jalr	182(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004976:	60e2                	ld	ra,24(sp)
    80004978:	6442                	ld	s0,16(sp)
    8000497a:	64a2                	ld	s1,8(sp)
    8000497c:	6902                	ld	s2,0(sp)
    8000497e:	6105                	addi	sp,sp,32
    80004980:	8082                	ret
    pi->readopen = 0;
    80004982:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004986:	21c48513          	addi	a0,s1,540
    8000498a:	ffffe097          	auipc	ra,0xffffe
    8000498e:	9ee080e7          	jalr	-1554(ra) # 80002378 <wakeup>
    80004992:	b7e9                	j	8000495c <pipeclose+0x2c>
    release(&pi->lock);
    80004994:	8526                	mv	a0,s1
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	32e080e7          	jalr	814(ra) # 80000cc4 <release>
}
    8000499e:	bfe1                	j	80004976 <pipeclose+0x46>

00000000800049a0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049a0:	7119                	addi	sp,sp,-128
    800049a2:	fc86                	sd	ra,120(sp)
    800049a4:	f8a2                	sd	s0,112(sp)
    800049a6:	f4a6                	sd	s1,104(sp)
    800049a8:	f0ca                	sd	s2,96(sp)
    800049aa:	ecce                	sd	s3,88(sp)
    800049ac:	e8d2                	sd	s4,80(sp)
    800049ae:	e4d6                	sd	s5,72(sp)
    800049b0:	e0da                	sd	s6,64(sp)
    800049b2:	fc5e                	sd	s7,56(sp)
    800049b4:	f862                	sd	s8,48(sp)
    800049b6:	f466                	sd	s9,40(sp)
    800049b8:	f06a                	sd	s10,32(sp)
    800049ba:	ec6e                	sd	s11,24(sp)
    800049bc:	0100                	addi	s0,sp,128
    800049be:	84aa                	mv	s1,a0
    800049c0:	8cae                	mv	s9,a1
    800049c2:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    800049c4:	ffffd097          	auipc	ra,0xffffd
    800049c8:	01a080e7          	jalr	26(ra) # 800019de <myproc>
    800049cc:	892a                	mv	s2,a0

  acquire(&pi->lock);
    800049ce:	8526                	mv	a0,s1
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	240080e7          	jalr	576(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    800049d8:	0d605963          	blez	s6,80004aaa <pipewrite+0x10a>
    800049dc:	89a6                	mv	s3,s1
    800049de:	3b7d                	addiw	s6,s6,-1
    800049e0:	1b02                	slli	s6,s6,0x20
    800049e2:	020b5b13          	srli	s6,s6,0x20
    800049e6:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    800049e8:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049ec:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049f0:	5dfd                	li	s11,-1
    800049f2:	000b8d1b          	sext.w	s10,s7
    800049f6:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    800049f8:	2184a783          	lw	a5,536(s1)
    800049fc:	21c4a703          	lw	a4,540(s1)
    80004a00:	2007879b          	addiw	a5,a5,512
    80004a04:	02f71b63          	bne	a4,a5,80004a3a <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004a08:	2204a783          	lw	a5,544(s1)
    80004a0c:	cbad                	beqz	a5,80004a7e <pipewrite+0xde>
    80004a0e:	03092783          	lw	a5,48(s2)
    80004a12:	e7b5                	bnez	a5,80004a7e <pipewrite+0xde>
      wakeup(&pi->nread);
    80004a14:	8556                	mv	a0,s5
    80004a16:	ffffe097          	auipc	ra,0xffffe
    80004a1a:	962080e7          	jalr	-1694(ra) # 80002378 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a1e:	85ce                	mv	a1,s3
    80004a20:	8552                	mv	a0,s4
    80004a22:	ffffd097          	auipc	ra,0xffffd
    80004a26:	7d0080e7          	jalr	2000(ra) # 800021f2 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a2a:	2184a783          	lw	a5,536(s1)
    80004a2e:	21c4a703          	lw	a4,540(s1)
    80004a32:	2007879b          	addiw	a5,a5,512
    80004a36:	fcf709e3          	beq	a4,a5,80004a08 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a3a:	4685                	li	a3,1
    80004a3c:	019b8633          	add	a2,s7,s9
    80004a40:	f8f40593          	addi	a1,s0,-113
    80004a44:	05093503          	ld	a0,80(s2)
    80004a48:	ffffd097          	auipc	ra,0xffffd
    80004a4c:	d16080e7          	jalr	-746(ra) # 8000175e <copyin>
    80004a50:	05b50e63          	beq	a0,s11,80004aac <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a54:	21c4a783          	lw	a5,540(s1)
    80004a58:	0017871b          	addiw	a4,a5,1
    80004a5c:	20e4ae23          	sw	a4,540(s1)
    80004a60:	1ff7f793          	andi	a5,a5,511
    80004a64:	97a6                	add	a5,a5,s1
    80004a66:	f8f44703          	lbu	a4,-113(s0)
    80004a6a:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004a6e:	001d0c1b          	addiw	s8,s10,1
    80004a72:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004a76:	036b8b63          	beq	s7,s6,80004aac <pipewrite+0x10c>
    80004a7a:	8bbe                	mv	s7,a5
    80004a7c:	bf9d                	j	800049f2 <pipewrite+0x52>
        release(&pi->lock);
    80004a7e:	8526                	mv	a0,s1
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	244080e7          	jalr	580(ra) # 80000cc4 <release>
        return -1;
    80004a88:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004a8a:	8562                	mv	a0,s8
    80004a8c:	70e6                	ld	ra,120(sp)
    80004a8e:	7446                	ld	s0,112(sp)
    80004a90:	74a6                	ld	s1,104(sp)
    80004a92:	7906                	ld	s2,96(sp)
    80004a94:	69e6                	ld	s3,88(sp)
    80004a96:	6a46                	ld	s4,80(sp)
    80004a98:	6aa6                	ld	s5,72(sp)
    80004a9a:	6b06                	ld	s6,64(sp)
    80004a9c:	7be2                	ld	s7,56(sp)
    80004a9e:	7c42                	ld	s8,48(sp)
    80004aa0:	7ca2                	ld	s9,40(sp)
    80004aa2:	7d02                	ld	s10,32(sp)
    80004aa4:	6de2                	ld	s11,24(sp)
    80004aa6:	6109                	addi	sp,sp,128
    80004aa8:	8082                	ret
  for(i = 0; i < n; i++){
    80004aaa:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004aac:	21848513          	addi	a0,s1,536
    80004ab0:	ffffe097          	auipc	ra,0xffffe
    80004ab4:	8c8080e7          	jalr	-1848(ra) # 80002378 <wakeup>
  release(&pi->lock);
    80004ab8:	8526                	mv	a0,s1
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	20a080e7          	jalr	522(ra) # 80000cc4 <release>
  return i;
    80004ac2:	b7e1                	j	80004a8a <pipewrite+0xea>

0000000080004ac4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ac4:	715d                	addi	sp,sp,-80
    80004ac6:	e486                	sd	ra,72(sp)
    80004ac8:	e0a2                	sd	s0,64(sp)
    80004aca:	fc26                	sd	s1,56(sp)
    80004acc:	f84a                	sd	s2,48(sp)
    80004ace:	f44e                	sd	s3,40(sp)
    80004ad0:	f052                	sd	s4,32(sp)
    80004ad2:	ec56                	sd	s5,24(sp)
    80004ad4:	e85a                	sd	s6,16(sp)
    80004ad6:	0880                	addi	s0,sp,80
    80004ad8:	84aa                	mv	s1,a0
    80004ada:	892e                	mv	s2,a1
    80004adc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ade:	ffffd097          	auipc	ra,0xffffd
    80004ae2:	f00080e7          	jalr	-256(ra) # 800019de <myproc>
    80004ae6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ae8:	8b26                	mv	s6,s1
    80004aea:	8526                	mv	a0,s1
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	124080e7          	jalr	292(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004af4:	2184a703          	lw	a4,536(s1)
    80004af8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004afc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b00:	02f71463          	bne	a4,a5,80004b28 <piperead+0x64>
    80004b04:	2244a783          	lw	a5,548(s1)
    80004b08:	c385                	beqz	a5,80004b28 <piperead+0x64>
    if(pr->killed){
    80004b0a:	030a2783          	lw	a5,48(s4)
    80004b0e:	ebc1                	bnez	a5,80004b9e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b10:	85da                	mv	a1,s6
    80004b12:	854e                	mv	a0,s3
    80004b14:	ffffd097          	auipc	ra,0xffffd
    80004b18:	6de080e7          	jalr	1758(ra) # 800021f2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b1c:	2184a703          	lw	a4,536(s1)
    80004b20:	21c4a783          	lw	a5,540(s1)
    80004b24:	fef700e3          	beq	a4,a5,80004b04 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b28:	09505263          	blez	s5,80004bac <piperead+0xe8>
    80004b2c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b2e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004b30:	2184a783          	lw	a5,536(s1)
    80004b34:	21c4a703          	lw	a4,540(s1)
    80004b38:	02f70d63          	beq	a4,a5,80004b72 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b3c:	0017871b          	addiw	a4,a5,1
    80004b40:	20e4ac23          	sw	a4,536(s1)
    80004b44:	1ff7f793          	andi	a5,a5,511
    80004b48:	97a6                	add	a5,a5,s1
    80004b4a:	0187c783          	lbu	a5,24(a5)
    80004b4e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b52:	4685                	li	a3,1
    80004b54:	fbf40613          	addi	a2,s0,-65
    80004b58:	85ca                	mv	a1,s2
    80004b5a:	050a3503          	ld	a0,80(s4)
    80004b5e:	ffffd097          	auipc	ra,0xffffd
    80004b62:	b74080e7          	jalr	-1164(ra) # 800016d2 <copyout>
    80004b66:	01650663          	beq	a0,s6,80004b72 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b6a:	2985                	addiw	s3,s3,1
    80004b6c:	0905                	addi	s2,s2,1
    80004b6e:	fd3a91e3          	bne	s5,s3,80004b30 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b72:	21c48513          	addi	a0,s1,540
    80004b76:	ffffe097          	auipc	ra,0xffffe
    80004b7a:	802080e7          	jalr	-2046(ra) # 80002378 <wakeup>
  release(&pi->lock);
    80004b7e:	8526                	mv	a0,s1
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	144080e7          	jalr	324(ra) # 80000cc4 <release>
  return i;
}
    80004b88:	854e                	mv	a0,s3
    80004b8a:	60a6                	ld	ra,72(sp)
    80004b8c:	6406                	ld	s0,64(sp)
    80004b8e:	74e2                	ld	s1,56(sp)
    80004b90:	7942                	ld	s2,48(sp)
    80004b92:	79a2                	ld	s3,40(sp)
    80004b94:	7a02                	ld	s4,32(sp)
    80004b96:	6ae2                	ld	s5,24(sp)
    80004b98:	6b42                	ld	s6,16(sp)
    80004b9a:	6161                	addi	sp,sp,80
    80004b9c:	8082                	ret
      release(&pi->lock);
    80004b9e:	8526                	mv	a0,s1
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	124080e7          	jalr	292(ra) # 80000cc4 <release>
      return -1;
    80004ba8:	59fd                	li	s3,-1
    80004baa:	bff9                	j	80004b88 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bac:	4981                	li	s3,0
    80004bae:	b7d1                	j	80004b72 <piperead+0xae>

0000000080004bb0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bb0:	df010113          	addi	sp,sp,-528
    80004bb4:	20113423          	sd	ra,520(sp)
    80004bb8:	20813023          	sd	s0,512(sp)
    80004bbc:	ffa6                	sd	s1,504(sp)
    80004bbe:	fbca                	sd	s2,496(sp)
    80004bc0:	f7ce                	sd	s3,488(sp)
    80004bc2:	f3d2                	sd	s4,480(sp)
    80004bc4:	efd6                	sd	s5,472(sp)
    80004bc6:	ebda                	sd	s6,464(sp)
    80004bc8:	e7de                	sd	s7,456(sp)
    80004bca:	e3e2                	sd	s8,448(sp)
    80004bcc:	ff66                	sd	s9,440(sp)
    80004bce:	fb6a                	sd	s10,432(sp)
    80004bd0:	f76e                	sd	s11,424(sp)
    80004bd2:	0c00                	addi	s0,sp,528
    80004bd4:	84aa                	mv	s1,a0
    80004bd6:	dea43c23          	sd	a0,-520(s0)
    80004bda:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	e00080e7          	jalr	-512(ra) # 800019de <myproc>
    80004be6:	892a                	mv	s2,a0

  begin_op();
    80004be8:	fffff097          	auipc	ra,0xfffff
    80004bec:	446080e7          	jalr	1094(ra) # 8000402e <begin_op>

  if((ip = namei(path)) == 0){
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	230080e7          	jalr	560(ra) # 80003e22 <namei>
    80004bfa:	c92d                	beqz	a0,80004c6c <exec+0xbc>
    80004bfc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004bfe:	fffff097          	auipc	ra,0xfffff
    80004c02:	a74080e7          	jalr	-1420(ra) # 80003672 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c06:	04000713          	li	a4,64
    80004c0a:	4681                	li	a3,0
    80004c0c:	e4840613          	addi	a2,s0,-440
    80004c10:	4581                	li	a1,0
    80004c12:	8526                	mv	a0,s1
    80004c14:	fffff097          	auipc	ra,0xfffff
    80004c18:	d12080e7          	jalr	-750(ra) # 80003926 <readi>
    80004c1c:	04000793          	li	a5,64
    80004c20:	00f51a63          	bne	a0,a5,80004c34 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c24:	e4842703          	lw	a4,-440(s0)
    80004c28:	464c47b7          	lui	a5,0x464c4
    80004c2c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c30:	04f70463          	beq	a4,a5,80004c78 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c34:	8526                	mv	a0,s1
    80004c36:	fffff097          	auipc	ra,0xfffff
    80004c3a:	c9e080e7          	jalr	-866(ra) # 800038d4 <iunlockput>
    end_op();
    80004c3e:	fffff097          	auipc	ra,0xfffff
    80004c42:	470080e7          	jalr	1136(ra) # 800040ae <end_op>
  }
  return -1;
    80004c46:	557d                	li	a0,-1
}
    80004c48:	20813083          	ld	ra,520(sp)
    80004c4c:	20013403          	ld	s0,512(sp)
    80004c50:	74fe                	ld	s1,504(sp)
    80004c52:	795e                	ld	s2,496(sp)
    80004c54:	79be                	ld	s3,488(sp)
    80004c56:	7a1e                	ld	s4,480(sp)
    80004c58:	6afe                	ld	s5,472(sp)
    80004c5a:	6b5e                	ld	s6,464(sp)
    80004c5c:	6bbe                	ld	s7,456(sp)
    80004c5e:	6c1e                	ld	s8,448(sp)
    80004c60:	7cfa                	ld	s9,440(sp)
    80004c62:	7d5a                	ld	s10,432(sp)
    80004c64:	7dba                	ld	s11,424(sp)
    80004c66:	21010113          	addi	sp,sp,528
    80004c6a:	8082                	ret
    end_op();
    80004c6c:	fffff097          	auipc	ra,0xfffff
    80004c70:	442080e7          	jalr	1090(ra) # 800040ae <end_op>
    return -1;
    80004c74:	557d                	li	a0,-1
    80004c76:	bfc9                	j	80004c48 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c78:	854a                	mv	a0,s2
    80004c7a:	ffffd097          	auipc	ra,0xffffd
    80004c7e:	e28080e7          	jalr	-472(ra) # 80001aa2 <proc_pagetable>
    80004c82:	8baa                	mv	s7,a0
    80004c84:	d945                	beqz	a0,80004c34 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c86:	e6842983          	lw	s3,-408(s0)
    80004c8a:	e8045783          	lhu	a5,-384(s0)
    80004c8e:	c7ad                	beqz	a5,80004cf8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c90:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004c92:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004c94:	6c85                	lui	s9,0x1
    80004c96:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004c9a:	def43823          	sd	a5,-528(s0)
    80004c9e:	a42d                	j	80004ec8 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ca0:	00004517          	auipc	a0,0x4
    80004ca4:	b9050513          	addi	a0,a0,-1136 # 80008830 <syscalls_name+0x290>
    80004ca8:	ffffc097          	auipc	ra,0xffffc
    80004cac:	8a0080e7          	jalr	-1888(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cb0:	8756                	mv	a4,s5
    80004cb2:	012d86bb          	addw	a3,s11,s2
    80004cb6:	4581                	li	a1,0
    80004cb8:	8526                	mv	a0,s1
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	c6c080e7          	jalr	-916(ra) # 80003926 <readi>
    80004cc2:	2501                	sext.w	a0,a0
    80004cc4:	1aaa9963          	bne	s5,a0,80004e76 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004cc8:	6785                	lui	a5,0x1
    80004cca:	0127893b          	addw	s2,a5,s2
    80004cce:	77fd                	lui	a5,0xfffff
    80004cd0:	01478a3b          	addw	s4,a5,s4
    80004cd4:	1f897163          	bgeu	s2,s8,80004eb6 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004cd8:	02091593          	slli	a1,s2,0x20
    80004cdc:	9181                	srli	a1,a1,0x20
    80004cde:	95ea                	add	a1,a1,s10
    80004ce0:	855e                	mv	a0,s7
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	3bc080e7          	jalr	956(ra) # 8000109e <walkaddr>
    80004cea:	862a                	mv	a2,a0
    if(pa == 0)
    80004cec:	d955                	beqz	a0,80004ca0 <exec+0xf0>
      n = PGSIZE;
    80004cee:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004cf0:	fd9a70e3          	bgeu	s4,s9,80004cb0 <exec+0x100>
      n = sz - i;
    80004cf4:	8ad2                	mv	s5,s4
    80004cf6:	bf6d                	j	80004cb0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cf8:	4901                	li	s2,0
  iunlockput(ip);
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	fffff097          	auipc	ra,0xfffff
    80004d00:	bd8080e7          	jalr	-1064(ra) # 800038d4 <iunlockput>
  end_op();
    80004d04:	fffff097          	auipc	ra,0xfffff
    80004d08:	3aa080e7          	jalr	938(ra) # 800040ae <end_op>
  p = myproc();
    80004d0c:	ffffd097          	auipc	ra,0xffffd
    80004d10:	cd2080e7          	jalr	-814(ra) # 800019de <myproc>
    80004d14:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004d16:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d1a:	6785                	lui	a5,0x1
    80004d1c:	17fd                	addi	a5,a5,-1
    80004d1e:	993e                	add	s2,s2,a5
    80004d20:	757d                	lui	a0,0xfffff
    80004d22:	00a977b3          	and	a5,s2,a0
    80004d26:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d2a:	6609                	lui	a2,0x2
    80004d2c:	963e                	add	a2,a2,a5
    80004d2e:	85be                	mv	a1,a5
    80004d30:	855e                	mv	a0,s7
    80004d32:	ffffc097          	auipc	ra,0xffffc
    80004d36:	750080e7          	jalr	1872(ra) # 80001482 <uvmalloc>
    80004d3a:	8b2a                	mv	s6,a0
  ip = 0;
    80004d3c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d3e:	12050c63          	beqz	a0,80004e76 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d42:	75f9                	lui	a1,0xffffe
    80004d44:	95aa                	add	a1,a1,a0
    80004d46:	855e                	mv	a0,s7
    80004d48:	ffffd097          	auipc	ra,0xffffd
    80004d4c:	958080e7          	jalr	-1704(ra) # 800016a0 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d50:	7c7d                	lui	s8,0xfffff
    80004d52:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d54:	e0043783          	ld	a5,-512(s0)
    80004d58:	6388                	ld	a0,0(a5)
    80004d5a:	c535                	beqz	a0,80004dc6 <exec+0x216>
    80004d5c:	e8840993          	addi	s3,s0,-376
    80004d60:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004d64:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	12e080e7          	jalr	302(ra) # 80000e94 <strlen>
    80004d6e:	2505                	addiw	a0,a0,1
    80004d70:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d74:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004d78:	13896363          	bltu	s2,s8,80004e9e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d7c:	e0043d83          	ld	s11,-512(s0)
    80004d80:	000dba03          	ld	s4,0(s11)
    80004d84:	8552                	mv	a0,s4
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	10e080e7          	jalr	270(ra) # 80000e94 <strlen>
    80004d8e:	0015069b          	addiw	a3,a0,1
    80004d92:	8652                	mv	a2,s4
    80004d94:	85ca                	mv	a1,s2
    80004d96:	855e                	mv	a0,s7
    80004d98:	ffffd097          	auipc	ra,0xffffd
    80004d9c:	93a080e7          	jalr	-1734(ra) # 800016d2 <copyout>
    80004da0:	10054363          	bltz	a0,80004ea6 <exec+0x2f6>
    ustack[argc] = sp;
    80004da4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004da8:	0485                	addi	s1,s1,1
    80004daa:	008d8793          	addi	a5,s11,8
    80004dae:	e0f43023          	sd	a5,-512(s0)
    80004db2:	008db503          	ld	a0,8(s11)
    80004db6:	c911                	beqz	a0,80004dca <exec+0x21a>
    if(argc >= MAXARG)
    80004db8:	09a1                	addi	s3,s3,8
    80004dba:	fb3c96e3          	bne	s9,s3,80004d66 <exec+0x1b6>
  sz = sz1;
    80004dbe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004dc2:	4481                	li	s1,0
    80004dc4:	a84d                	j	80004e76 <exec+0x2c6>
  sp = sz;
    80004dc6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dc8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004dca:	00349793          	slli	a5,s1,0x3
    80004dce:	f9040713          	addi	a4,s0,-112
    80004dd2:	97ba                	add	a5,a5,a4
    80004dd4:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004dd8:	00148693          	addi	a3,s1,1
    80004ddc:	068e                	slli	a3,a3,0x3
    80004dde:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004de2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004de6:	01897663          	bgeu	s2,s8,80004df2 <exec+0x242>
  sz = sz1;
    80004dea:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004dee:	4481                	li	s1,0
    80004df0:	a059                	j	80004e76 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004df2:	e8840613          	addi	a2,s0,-376
    80004df6:	85ca                	mv	a1,s2
    80004df8:	855e                	mv	a0,s7
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	8d8080e7          	jalr	-1832(ra) # 800016d2 <copyout>
    80004e02:	0a054663          	bltz	a0,80004eae <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004e06:	058ab783          	ld	a5,88(s5)
    80004e0a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e0e:	df843783          	ld	a5,-520(s0)
    80004e12:	0007c703          	lbu	a4,0(a5)
    80004e16:	cf11                	beqz	a4,80004e32 <exec+0x282>
    80004e18:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e1a:	02f00693          	li	a3,47
    80004e1e:	a029                	j	80004e28 <exec+0x278>
  for(last=s=path; *s; s++)
    80004e20:	0785                	addi	a5,a5,1
    80004e22:	fff7c703          	lbu	a4,-1(a5)
    80004e26:	c711                	beqz	a4,80004e32 <exec+0x282>
    if(*s == '/')
    80004e28:	fed71ce3          	bne	a4,a3,80004e20 <exec+0x270>
      last = s+1;
    80004e2c:	def43c23          	sd	a5,-520(s0)
    80004e30:	bfc5                	j	80004e20 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e32:	4641                	li	a2,16
    80004e34:	df843583          	ld	a1,-520(s0)
    80004e38:	158a8513          	addi	a0,s5,344
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	026080e7          	jalr	38(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80004e44:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004e48:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004e4c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e50:	058ab783          	ld	a5,88(s5)
    80004e54:	e6043703          	ld	a4,-416(s0)
    80004e58:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e5a:	058ab783          	ld	a5,88(s5)
    80004e5e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e62:	85ea                	mv	a1,s10
    80004e64:	ffffd097          	auipc	ra,0xffffd
    80004e68:	cda080e7          	jalr	-806(ra) # 80001b3e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e6c:	0004851b          	sext.w	a0,s1
    80004e70:	bbe1                	j	80004c48 <exec+0x98>
    80004e72:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004e76:	e0843583          	ld	a1,-504(s0)
    80004e7a:	855e                	mv	a0,s7
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	cc2080e7          	jalr	-830(ra) # 80001b3e <proc_freepagetable>
  if(ip){
    80004e84:	da0498e3          	bnez	s1,80004c34 <exec+0x84>
  return -1;
    80004e88:	557d                	li	a0,-1
    80004e8a:	bb7d                	j	80004c48 <exec+0x98>
    80004e8c:	e1243423          	sd	s2,-504(s0)
    80004e90:	b7dd                	j	80004e76 <exec+0x2c6>
    80004e92:	e1243423          	sd	s2,-504(s0)
    80004e96:	b7c5                	j	80004e76 <exec+0x2c6>
    80004e98:	e1243423          	sd	s2,-504(s0)
    80004e9c:	bfe9                	j	80004e76 <exec+0x2c6>
  sz = sz1;
    80004e9e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ea2:	4481                	li	s1,0
    80004ea4:	bfc9                	j	80004e76 <exec+0x2c6>
  sz = sz1;
    80004ea6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eaa:	4481                	li	s1,0
    80004eac:	b7e9                	j	80004e76 <exec+0x2c6>
  sz = sz1;
    80004eae:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eb2:	4481                	li	s1,0
    80004eb4:	b7c9                	j	80004e76 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004eb6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eba:	2b05                	addiw	s6,s6,1
    80004ebc:	0389899b          	addiw	s3,s3,56
    80004ec0:	e8045783          	lhu	a5,-384(s0)
    80004ec4:	e2fb5be3          	bge	s6,a5,80004cfa <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ec8:	2981                	sext.w	s3,s3
    80004eca:	03800713          	li	a4,56
    80004ece:	86ce                	mv	a3,s3
    80004ed0:	e1040613          	addi	a2,s0,-496
    80004ed4:	4581                	li	a1,0
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	a4e080e7          	jalr	-1458(ra) # 80003926 <readi>
    80004ee0:	03800793          	li	a5,56
    80004ee4:	f8f517e3          	bne	a0,a5,80004e72 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004ee8:	e1042783          	lw	a5,-496(s0)
    80004eec:	4705                	li	a4,1
    80004eee:	fce796e3          	bne	a5,a4,80004eba <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004ef2:	e3843603          	ld	a2,-456(s0)
    80004ef6:	e3043783          	ld	a5,-464(s0)
    80004efa:	f8f669e3          	bltu	a2,a5,80004e8c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004efe:	e2043783          	ld	a5,-480(s0)
    80004f02:	963e                	add	a2,a2,a5
    80004f04:	f8f667e3          	bltu	a2,a5,80004e92 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f08:	85ca                	mv	a1,s2
    80004f0a:	855e                	mv	a0,s7
    80004f0c:	ffffc097          	auipc	ra,0xffffc
    80004f10:	576080e7          	jalr	1398(ra) # 80001482 <uvmalloc>
    80004f14:	e0a43423          	sd	a0,-504(s0)
    80004f18:	d141                	beqz	a0,80004e98 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004f1a:	e2043d03          	ld	s10,-480(s0)
    80004f1e:	df043783          	ld	a5,-528(s0)
    80004f22:	00fd77b3          	and	a5,s10,a5
    80004f26:	fba1                	bnez	a5,80004e76 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f28:	e1842d83          	lw	s11,-488(s0)
    80004f2c:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f30:	f80c03e3          	beqz	s8,80004eb6 <exec+0x306>
    80004f34:	8a62                	mv	s4,s8
    80004f36:	4901                	li	s2,0
    80004f38:	b345                	j	80004cd8 <exec+0x128>

0000000080004f3a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f3a:	7179                	addi	sp,sp,-48
    80004f3c:	f406                	sd	ra,40(sp)
    80004f3e:	f022                	sd	s0,32(sp)
    80004f40:	ec26                	sd	s1,24(sp)
    80004f42:	e84a                	sd	s2,16(sp)
    80004f44:	1800                	addi	s0,sp,48
    80004f46:	892e                	mv	s2,a1
    80004f48:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f4a:	fdc40593          	addi	a1,s0,-36
    80004f4e:	ffffe097          	auipc	ra,0xffffe
    80004f52:	b52080e7          	jalr	-1198(ra) # 80002aa0 <argint>
    80004f56:	04054063          	bltz	a0,80004f96 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f5a:	fdc42703          	lw	a4,-36(s0)
    80004f5e:	47bd                	li	a5,15
    80004f60:	02e7ed63          	bltu	a5,a4,80004f9a <argfd+0x60>
    80004f64:	ffffd097          	auipc	ra,0xffffd
    80004f68:	a7a080e7          	jalr	-1414(ra) # 800019de <myproc>
    80004f6c:	fdc42703          	lw	a4,-36(s0)
    80004f70:	01a70793          	addi	a5,a4,26
    80004f74:	078e                	slli	a5,a5,0x3
    80004f76:	953e                	add	a0,a0,a5
    80004f78:	611c                	ld	a5,0(a0)
    80004f7a:	c395                	beqz	a5,80004f9e <argfd+0x64>
    return -1;
  if(pfd)
    80004f7c:	00090463          	beqz	s2,80004f84 <argfd+0x4a>
    *pfd = fd;
    80004f80:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004f84:	4501                	li	a0,0
  if(pf)
    80004f86:	c091                	beqz	s1,80004f8a <argfd+0x50>
    *pf = f;
    80004f88:	e09c                	sd	a5,0(s1)
}
    80004f8a:	70a2                	ld	ra,40(sp)
    80004f8c:	7402                	ld	s0,32(sp)
    80004f8e:	64e2                	ld	s1,24(sp)
    80004f90:	6942                	ld	s2,16(sp)
    80004f92:	6145                	addi	sp,sp,48
    80004f94:	8082                	ret
    return -1;
    80004f96:	557d                	li	a0,-1
    80004f98:	bfcd                	j	80004f8a <argfd+0x50>
    return -1;
    80004f9a:	557d                	li	a0,-1
    80004f9c:	b7fd                	j	80004f8a <argfd+0x50>
    80004f9e:	557d                	li	a0,-1
    80004fa0:	b7ed                	j	80004f8a <argfd+0x50>

0000000080004fa2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fa2:	1101                	addi	sp,sp,-32
    80004fa4:	ec06                	sd	ra,24(sp)
    80004fa6:	e822                	sd	s0,16(sp)
    80004fa8:	e426                	sd	s1,8(sp)
    80004faa:	1000                	addi	s0,sp,32
    80004fac:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fae:	ffffd097          	auipc	ra,0xffffd
    80004fb2:	a30080e7          	jalr	-1488(ra) # 800019de <myproc>
    80004fb6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004fb8:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004fbc:	4501                	li	a0,0
    80004fbe:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004fc0:	6398                	ld	a4,0(a5)
    80004fc2:	cb19                	beqz	a4,80004fd8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004fc4:	2505                	addiw	a0,a0,1
    80004fc6:	07a1                	addi	a5,a5,8
    80004fc8:	fed51ce3          	bne	a0,a3,80004fc0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004fcc:	557d                	li	a0,-1
}
    80004fce:	60e2                	ld	ra,24(sp)
    80004fd0:	6442                	ld	s0,16(sp)
    80004fd2:	64a2                	ld	s1,8(sp)
    80004fd4:	6105                	addi	sp,sp,32
    80004fd6:	8082                	ret
      p->ofile[fd] = f;
    80004fd8:	01a50793          	addi	a5,a0,26
    80004fdc:	078e                	slli	a5,a5,0x3
    80004fde:	963e                	add	a2,a2,a5
    80004fe0:	e204                	sd	s1,0(a2)
      return fd;
    80004fe2:	b7f5                	j	80004fce <fdalloc+0x2c>

0000000080004fe4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004fe4:	715d                	addi	sp,sp,-80
    80004fe6:	e486                	sd	ra,72(sp)
    80004fe8:	e0a2                	sd	s0,64(sp)
    80004fea:	fc26                	sd	s1,56(sp)
    80004fec:	f84a                	sd	s2,48(sp)
    80004fee:	f44e                	sd	s3,40(sp)
    80004ff0:	f052                	sd	s4,32(sp)
    80004ff2:	ec56                	sd	s5,24(sp)
    80004ff4:	0880                	addi	s0,sp,80
    80004ff6:	89ae                	mv	s3,a1
    80004ff8:	8ab2                	mv	s5,a2
    80004ffa:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004ffc:	fb040593          	addi	a1,s0,-80
    80005000:	fffff097          	auipc	ra,0xfffff
    80005004:	e40080e7          	jalr	-448(ra) # 80003e40 <nameiparent>
    80005008:	892a                	mv	s2,a0
    8000500a:	12050f63          	beqz	a0,80005148 <create+0x164>
    return 0;

  ilock(dp);
    8000500e:	ffffe097          	auipc	ra,0xffffe
    80005012:	664080e7          	jalr	1636(ra) # 80003672 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005016:	4601                	li	a2,0
    80005018:	fb040593          	addi	a1,s0,-80
    8000501c:	854a                	mv	a0,s2
    8000501e:	fffff097          	auipc	ra,0xfffff
    80005022:	b32080e7          	jalr	-1230(ra) # 80003b50 <dirlookup>
    80005026:	84aa                	mv	s1,a0
    80005028:	c921                	beqz	a0,80005078 <create+0x94>
    iunlockput(dp);
    8000502a:	854a                	mv	a0,s2
    8000502c:	fffff097          	auipc	ra,0xfffff
    80005030:	8a8080e7          	jalr	-1880(ra) # 800038d4 <iunlockput>
    ilock(ip);
    80005034:	8526                	mv	a0,s1
    80005036:	ffffe097          	auipc	ra,0xffffe
    8000503a:	63c080e7          	jalr	1596(ra) # 80003672 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000503e:	2981                	sext.w	s3,s3
    80005040:	4789                	li	a5,2
    80005042:	02f99463          	bne	s3,a5,8000506a <create+0x86>
    80005046:	0444d783          	lhu	a5,68(s1)
    8000504a:	37f9                	addiw	a5,a5,-2
    8000504c:	17c2                	slli	a5,a5,0x30
    8000504e:	93c1                	srli	a5,a5,0x30
    80005050:	4705                	li	a4,1
    80005052:	00f76c63          	bltu	a4,a5,8000506a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005056:	8526                	mv	a0,s1
    80005058:	60a6                	ld	ra,72(sp)
    8000505a:	6406                	ld	s0,64(sp)
    8000505c:	74e2                	ld	s1,56(sp)
    8000505e:	7942                	ld	s2,48(sp)
    80005060:	79a2                	ld	s3,40(sp)
    80005062:	7a02                	ld	s4,32(sp)
    80005064:	6ae2                	ld	s5,24(sp)
    80005066:	6161                	addi	sp,sp,80
    80005068:	8082                	ret
    iunlockput(ip);
    8000506a:	8526                	mv	a0,s1
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	868080e7          	jalr	-1944(ra) # 800038d4 <iunlockput>
    return 0;
    80005074:	4481                	li	s1,0
    80005076:	b7c5                	j	80005056 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005078:	85ce                	mv	a1,s3
    8000507a:	00092503          	lw	a0,0(s2)
    8000507e:	ffffe097          	auipc	ra,0xffffe
    80005082:	45c080e7          	jalr	1116(ra) # 800034da <ialloc>
    80005086:	84aa                	mv	s1,a0
    80005088:	c529                	beqz	a0,800050d2 <create+0xee>
  ilock(ip);
    8000508a:	ffffe097          	auipc	ra,0xffffe
    8000508e:	5e8080e7          	jalr	1512(ra) # 80003672 <ilock>
  ip->major = major;
    80005092:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005096:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000509a:	4785                	li	a5,1
    8000509c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800050a0:	8526                	mv	a0,s1
    800050a2:	ffffe097          	auipc	ra,0xffffe
    800050a6:	506080e7          	jalr	1286(ra) # 800035a8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050aa:	2981                	sext.w	s3,s3
    800050ac:	4785                	li	a5,1
    800050ae:	02f98a63          	beq	s3,a5,800050e2 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800050b2:	40d0                	lw	a2,4(s1)
    800050b4:	fb040593          	addi	a1,s0,-80
    800050b8:	854a                	mv	a0,s2
    800050ba:	fffff097          	auipc	ra,0xfffff
    800050be:	ca6080e7          	jalr	-858(ra) # 80003d60 <dirlink>
    800050c2:	06054b63          	bltz	a0,80005138 <create+0x154>
  iunlockput(dp);
    800050c6:	854a                	mv	a0,s2
    800050c8:	fffff097          	auipc	ra,0xfffff
    800050cc:	80c080e7          	jalr	-2036(ra) # 800038d4 <iunlockput>
  return ip;
    800050d0:	b759                	j	80005056 <create+0x72>
    panic("create: ialloc");
    800050d2:	00003517          	auipc	a0,0x3
    800050d6:	77e50513          	addi	a0,a0,1918 # 80008850 <syscalls_name+0x2b0>
    800050da:	ffffb097          	auipc	ra,0xffffb
    800050de:	46e080e7          	jalr	1134(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800050e2:	04a95783          	lhu	a5,74(s2)
    800050e6:	2785                	addiw	a5,a5,1
    800050e8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800050ec:	854a                	mv	a0,s2
    800050ee:	ffffe097          	auipc	ra,0xffffe
    800050f2:	4ba080e7          	jalr	1210(ra) # 800035a8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800050f6:	40d0                	lw	a2,4(s1)
    800050f8:	00003597          	auipc	a1,0x3
    800050fc:	76858593          	addi	a1,a1,1896 # 80008860 <syscalls_name+0x2c0>
    80005100:	8526                	mv	a0,s1
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	c5e080e7          	jalr	-930(ra) # 80003d60 <dirlink>
    8000510a:	00054f63          	bltz	a0,80005128 <create+0x144>
    8000510e:	00492603          	lw	a2,4(s2)
    80005112:	00003597          	auipc	a1,0x3
    80005116:	75658593          	addi	a1,a1,1878 # 80008868 <syscalls_name+0x2c8>
    8000511a:	8526                	mv	a0,s1
    8000511c:	fffff097          	auipc	ra,0xfffff
    80005120:	c44080e7          	jalr	-956(ra) # 80003d60 <dirlink>
    80005124:	f80557e3          	bgez	a0,800050b2 <create+0xce>
      panic("create dots");
    80005128:	00003517          	auipc	a0,0x3
    8000512c:	74850513          	addi	a0,a0,1864 # 80008870 <syscalls_name+0x2d0>
    80005130:	ffffb097          	auipc	ra,0xffffb
    80005134:	418080e7          	jalr	1048(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005138:	00003517          	auipc	a0,0x3
    8000513c:	74850513          	addi	a0,a0,1864 # 80008880 <syscalls_name+0x2e0>
    80005140:	ffffb097          	auipc	ra,0xffffb
    80005144:	408080e7          	jalr	1032(ra) # 80000548 <panic>
    return 0;
    80005148:	84aa                	mv	s1,a0
    8000514a:	b731                	j	80005056 <create+0x72>

000000008000514c <sys_dup>:
{
    8000514c:	7179                	addi	sp,sp,-48
    8000514e:	f406                	sd	ra,40(sp)
    80005150:	f022                	sd	s0,32(sp)
    80005152:	ec26                	sd	s1,24(sp)
    80005154:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005156:	fd840613          	addi	a2,s0,-40
    8000515a:	4581                	li	a1,0
    8000515c:	4501                	li	a0,0
    8000515e:	00000097          	auipc	ra,0x0
    80005162:	ddc080e7          	jalr	-548(ra) # 80004f3a <argfd>
    return -1;
    80005166:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005168:	02054363          	bltz	a0,8000518e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000516c:	fd843503          	ld	a0,-40(s0)
    80005170:	00000097          	auipc	ra,0x0
    80005174:	e32080e7          	jalr	-462(ra) # 80004fa2 <fdalloc>
    80005178:	84aa                	mv	s1,a0
    return -1;
    8000517a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000517c:	00054963          	bltz	a0,8000518e <sys_dup+0x42>
  filedup(f);
    80005180:	fd843503          	ld	a0,-40(s0)
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	32a080e7          	jalr	810(ra) # 800044ae <filedup>
  return fd;
    8000518c:	87a6                	mv	a5,s1
}
    8000518e:	853e                	mv	a0,a5
    80005190:	70a2                	ld	ra,40(sp)
    80005192:	7402                	ld	s0,32(sp)
    80005194:	64e2                	ld	s1,24(sp)
    80005196:	6145                	addi	sp,sp,48
    80005198:	8082                	ret

000000008000519a <sys_read>:
{
    8000519a:	7179                	addi	sp,sp,-48
    8000519c:	f406                	sd	ra,40(sp)
    8000519e:	f022                	sd	s0,32(sp)
    800051a0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051a2:	fe840613          	addi	a2,s0,-24
    800051a6:	4581                	li	a1,0
    800051a8:	4501                	li	a0,0
    800051aa:	00000097          	auipc	ra,0x0
    800051ae:	d90080e7          	jalr	-624(ra) # 80004f3a <argfd>
    return -1;
    800051b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051b4:	04054163          	bltz	a0,800051f6 <sys_read+0x5c>
    800051b8:	fe440593          	addi	a1,s0,-28
    800051bc:	4509                	li	a0,2
    800051be:	ffffe097          	auipc	ra,0xffffe
    800051c2:	8e2080e7          	jalr	-1822(ra) # 80002aa0 <argint>
    return -1;
    800051c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051c8:	02054763          	bltz	a0,800051f6 <sys_read+0x5c>
    800051cc:	fd840593          	addi	a1,s0,-40
    800051d0:	4505                	li	a0,1
    800051d2:	ffffe097          	auipc	ra,0xffffe
    800051d6:	8f0080e7          	jalr	-1808(ra) # 80002ac2 <argaddr>
    return -1;
    800051da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051dc:	00054d63          	bltz	a0,800051f6 <sys_read+0x5c>
  return fileread(f, p, n);
    800051e0:	fe442603          	lw	a2,-28(s0)
    800051e4:	fd843583          	ld	a1,-40(s0)
    800051e8:	fe843503          	ld	a0,-24(s0)
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	44e080e7          	jalr	1102(ra) # 8000463a <fileread>
    800051f4:	87aa                	mv	a5,a0
}
    800051f6:	853e                	mv	a0,a5
    800051f8:	70a2                	ld	ra,40(sp)
    800051fa:	7402                	ld	s0,32(sp)
    800051fc:	6145                	addi	sp,sp,48
    800051fe:	8082                	ret

0000000080005200 <sys_write>:
{
    80005200:	7179                	addi	sp,sp,-48
    80005202:	f406                	sd	ra,40(sp)
    80005204:	f022                	sd	s0,32(sp)
    80005206:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005208:	fe840613          	addi	a2,s0,-24
    8000520c:	4581                	li	a1,0
    8000520e:	4501                	li	a0,0
    80005210:	00000097          	auipc	ra,0x0
    80005214:	d2a080e7          	jalr	-726(ra) # 80004f3a <argfd>
    return -1;
    80005218:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000521a:	04054163          	bltz	a0,8000525c <sys_write+0x5c>
    8000521e:	fe440593          	addi	a1,s0,-28
    80005222:	4509                	li	a0,2
    80005224:	ffffe097          	auipc	ra,0xffffe
    80005228:	87c080e7          	jalr	-1924(ra) # 80002aa0 <argint>
    return -1;
    8000522c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000522e:	02054763          	bltz	a0,8000525c <sys_write+0x5c>
    80005232:	fd840593          	addi	a1,s0,-40
    80005236:	4505                	li	a0,1
    80005238:	ffffe097          	auipc	ra,0xffffe
    8000523c:	88a080e7          	jalr	-1910(ra) # 80002ac2 <argaddr>
    return -1;
    80005240:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005242:	00054d63          	bltz	a0,8000525c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005246:	fe442603          	lw	a2,-28(s0)
    8000524a:	fd843583          	ld	a1,-40(s0)
    8000524e:	fe843503          	ld	a0,-24(s0)
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	4aa080e7          	jalr	1194(ra) # 800046fc <filewrite>
    8000525a:	87aa                	mv	a5,a0
}
    8000525c:	853e                	mv	a0,a5
    8000525e:	70a2                	ld	ra,40(sp)
    80005260:	7402                	ld	s0,32(sp)
    80005262:	6145                	addi	sp,sp,48
    80005264:	8082                	ret

0000000080005266 <sys_close>:
{
    80005266:	1101                	addi	sp,sp,-32
    80005268:	ec06                	sd	ra,24(sp)
    8000526a:	e822                	sd	s0,16(sp)
    8000526c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000526e:	fe040613          	addi	a2,s0,-32
    80005272:	fec40593          	addi	a1,s0,-20
    80005276:	4501                	li	a0,0
    80005278:	00000097          	auipc	ra,0x0
    8000527c:	cc2080e7          	jalr	-830(ra) # 80004f3a <argfd>
    return -1;
    80005280:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005282:	02054463          	bltz	a0,800052aa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005286:	ffffc097          	auipc	ra,0xffffc
    8000528a:	758080e7          	jalr	1880(ra) # 800019de <myproc>
    8000528e:	fec42783          	lw	a5,-20(s0)
    80005292:	07e9                	addi	a5,a5,26
    80005294:	078e                	slli	a5,a5,0x3
    80005296:	97aa                	add	a5,a5,a0
    80005298:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000529c:	fe043503          	ld	a0,-32(s0)
    800052a0:	fffff097          	auipc	ra,0xfffff
    800052a4:	260080e7          	jalr	608(ra) # 80004500 <fileclose>
  return 0;
    800052a8:	4781                	li	a5,0
}
    800052aa:	853e                	mv	a0,a5
    800052ac:	60e2                	ld	ra,24(sp)
    800052ae:	6442                	ld	s0,16(sp)
    800052b0:	6105                	addi	sp,sp,32
    800052b2:	8082                	ret

00000000800052b4 <sys_fstat>:
{
    800052b4:	1101                	addi	sp,sp,-32
    800052b6:	ec06                	sd	ra,24(sp)
    800052b8:	e822                	sd	s0,16(sp)
    800052ba:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052bc:	fe840613          	addi	a2,s0,-24
    800052c0:	4581                	li	a1,0
    800052c2:	4501                	li	a0,0
    800052c4:	00000097          	auipc	ra,0x0
    800052c8:	c76080e7          	jalr	-906(ra) # 80004f3a <argfd>
    return -1;
    800052cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052ce:	02054563          	bltz	a0,800052f8 <sys_fstat+0x44>
    800052d2:	fe040593          	addi	a1,s0,-32
    800052d6:	4505                	li	a0,1
    800052d8:	ffffd097          	auipc	ra,0xffffd
    800052dc:	7ea080e7          	jalr	2026(ra) # 80002ac2 <argaddr>
    return -1;
    800052e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052e2:	00054b63          	bltz	a0,800052f8 <sys_fstat+0x44>
  return filestat(f, st);
    800052e6:	fe043583          	ld	a1,-32(s0)
    800052ea:	fe843503          	ld	a0,-24(s0)
    800052ee:	fffff097          	auipc	ra,0xfffff
    800052f2:	2da080e7          	jalr	730(ra) # 800045c8 <filestat>
    800052f6:	87aa                	mv	a5,a0
}
    800052f8:	853e                	mv	a0,a5
    800052fa:	60e2                	ld	ra,24(sp)
    800052fc:	6442                	ld	s0,16(sp)
    800052fe:	6105                	addi	sp,sp,32
    80005300:	8082                	ret

0000000080005302 <sys_link>:
{
    80005302:	7169                	addi	sp,sp,-304
    80005304:	f606                	sd	ra,296(sp)
    80005306:	f222                	sd	s0,288(sp)
    80005308:	ee26                	sd	s1,280(sp)
    8000530a:	ea4a                	sd	s2,272(sp)
    8000530c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000530e:	08000613          	li	a2,128
    80005312:	ed040593          	addi	a1,s0,-304
    80005316:	4501                	li	a0,0
    80005318:	ffffd097          	auipc	ra,0xffffd
    8000531c:	7cc080e7          	jalr	1996(ra) # 80002ae4 <argstr>
    return -1;
    80005320:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005322:	10054e63          	bltz	a0,8000543e <sys_link+0x13c>
    80005326:	08000613          	li	a2,128
    8000532a:	f5040593          	addi	a1,s0,-176
    8000532e:	4505                	li	a0,1
    80005330:	ffffd097          	auipc	ra,0xffffd
    80005334:	7b4080e7          	jalr	1972(ra) # 80002ae4 <argstr>
    return -1;
    80005338:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000533a:	10054263          	bltz	a0,8000543e <sys_link+0x13c>
  begin_op();
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	cf0080e7          	jalr	-784(ra) # 8000402e <begin_op>
  if((ip = namei(old)) == 0){
    80005346:	ed040513          	addi	a0,s0,-304
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	ad8080e7          	jalr	-1320(ra) # 80003e22 <namei>
    80005352:	84aa                	mv	s1,a0
    80005354:	c551                	beqz	a0,800053e0 <sys_link+0xde>
  ilock(ip);
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	31c080e7          	jalr	796(ra) # 80003672 <ilock>
  if(ip->type == T_DIR){
    8000535e:	04449703          	lh	a4,68(s1)
    80005362:	4785                	li	a5,1
    80005364:	08f70463          	beq	a4,a5,800053ec <sys_link+0xea>
  ip->nlink++;
    80005368:	04a4d783          	lhu	a5,74(s1)
    8000536c:	2785                	addiw	a5,a5,1
    8000536e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005372:	8526                	mv	a0,s1
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	234080e7          	jalr	564(ra) # 800035a8 <iupdate>
  iunlock(ip);
    8000537c:	8526                	mv	a0,s1
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	3b6080e7          	jalr	950(ra) # 80003734 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005386:	fd040593          	addi	a1,s0,-48
    8000538a:	f5040513          	addi	a0,s0,-176
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	ab2080e7          	jalr	-1358(ra) # 80003e40 <nameiparent>
    80005396:	892a                	mv	s2,a0
    80005398:	c935                	beqz	a0,8000540c <sys_link+0x10a>
  ilock(dp);
    8000539a:	ffffe097          	auipc	ra,0xffffe
    8000539e:	2d8080e7          	jalr	728(ra) # 80003672 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053a2:	00092703          	lw	a4,0(s2)
    800053a6:	409c                	lw	a5,0(s1)
    800053a8:	04f71d63          	bne	a4,a5,80005402 <sys_link+0x100>
    800053ac:	40d0                	lw	a2,4(s1)
    800053ae:	fd040593          	addi	a1,s0,-48
    800053b2:	854a                	mv	a0,s2
    800053b4:	fffff097          	auipc	ra,0xfffff
    800053b8:	9ac080e7          	jalr	-1620(ra) # 80003d60 <dirlink>
    800053bc:	04054363          	bltz	a0,80005402 <sys_link+0x100>
  iunlockput(dp);
    800053c0:	854a                	mv	a0,s2
    800053c2:	ffffe097          	auipc	ra,0xffffe
    800053c6:	512080e7          	jalr	1298(ra) # 800038d4 <iunlockput>
  iput(ip);
    800053ca:	8526                	mv	a0,s1
    800053cc:	ffffe097          	auipc	ra,0xffffe
    800053d0:	460080e7          	jalr	1120(ra) # 8000382c <iput>
  end_op();
    800053d4:	fffff097          	auipc	ra,0xfffff
    800053d8:	cda080e7          	jalr	-806(ra) # 800040ae <end_op>
  return 0;
    800053dc:	4781                	li	a5,0
    800053de:	a085                	j	8000543e <sys_link+0x13c>
    end_op();
    800053e0:	fffff097          	auipc	ra,0xfffff
    800053e4:	cce080e7          	jalr	-818(ra) # 800040ae <end_op>
    return -1;
    800053e8:	57fd                	li	a5,-1
    800053ea:	a891                	j	8000543e <sys_link+0x13c>
    iunlockput(ip);
    800053ec:	8526                	mv	a0,s1
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	4e6080e7          	jalr	1254(ra) # 800038d4 <iunlockput>
    end_op();
    800053f6:	fffff097          	auipc	ra,0xfffff
    800053fa:	cb8080e7          	jalr	-840(ra) # 800040ae <end_op>
    return -1;
    800053fe:	57fd                	li	a5,-1
    80005400:	a83d                	j	8000543e <sys_link+0x13c>
    iunlockput(dp);
    80005402:	854a                	mv	a0,s2
    80005404:	ffffe097          	auipc	ra,0xffffe
    80005408:	4d0080e7          	jalr	1232(ra) # 800038d4 <iunlockput>
  ilock(ip);
    8000540c:	8526                	mv	a0,s1
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	264080e7          	jalr	612(ra) # 80003672 <ilock>
  ip->nlink--;
    80005416:	04a4d783          	lhu	a5,74(s1)
    8000541a:	37fd                	addiw	a5,a5,-1
    8000541c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005420:	8526                	mv	a0,s1
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	186080e7          	jalr	390(ra) # 800035a8 <iupdate>
  iunlockput(ip);
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	4a8080e7          	jalr	1192(ra) # 800038d4 <iunlockput>
  end_op();
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	c7a080e7          	jalr	-902(ra) # 800040ae <end_op>
  return -1;
    8000543c:	57fd                	li	a5,-1
}
    8000543e:	853e                	mv	a0,a5
    80005440:	70b2                	ld	ra,296(sp)
    80005442:	7412                	ld	s0,288(sp)
    80005444:	64f2                	ld	s1,280(sp)
    80005446:	6952                	ld	s2,272(sp)
    80005448:	6155                	addi	sp,sp,304
    8000544a:	8082                	ret

000000008000544c <sys_unlink>:
{
    8000544c:	7151                	addi	sp,sp,-240
    8000544e:	f586                	sd	ra,232(sp)
    80005450:	f1a2                	sd	s0,224(sp)
    80005452:	eda6                	sd	s1,216(sp)
    80005454:	e9ca                	sd	s2,208(sp)
    80005456:	e5ce                	sd	s3,200(sp)
    80005458:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000545a:	08000613          	li	a2,128
    8000545e:	f3040593          	addi	a1,s0,-208
    80005462:	4501                	li	a0,0
    80005464:	ffffd097          	auipc	ra,0xffffd
    80005468:	680080e7          	jalr	1664(ra) # 80002ae4 <argstr>
    8000546c:	18054163          	bltz	a0,800055ee <sys_unlink+0x1a2>
  begin_op();
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	bbe080e7          	jalr	-1090(ra) # 8000402e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005478:	fb040593          	addi	a1,s0,-80
    8000547c:	f3040513          	addi	a0,s0,-208
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	9c0080e7          	jalr	-1600(ra) # 80003e40 <nameiparent>
    80005488:	84aa                	mv	s1,a0
    8000548a:	c979                	beqz	a0,80005560 <sys_unlink+0x114>
  ilock(dp);
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	1e6080e7          	jalr	486(ra) # 80003672 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005494:	00003597          	auipc	a1,0x3
    80005498:	3cc58593          	addi	a1,a1,972 # 80008860 <syscalls_name+0x2c0>
    8000549c:	fb040513          	addi	a0,s0,-80
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	696080e7          	jalr	1686(ra) # 80003b36 <namecmp>
    800054a8:	14050a63          	beqz	a0,800055fc <sys_unlink+0x1b0>
    800054ac:	00003597          	auipc	a1,0x3
    800054b0:	3bc58593          	addi	a1,a1,956 # 80008868 <syscalls_name+0x2c8>
    800054b4:	fb040513          	addi	a0,s0,-80
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	67e080e7          	jalr	1662(ra) # 80003b36 <namecmp>
    800054c0:	12050e63          	beqz	a0,800055fc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054c4:	f2c40613          	addi	a2,s0,-212
    800054c8:	fb040593          	addi	a1,s0,-80
    800054cc:	8526                	mv	a0,s1
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	682080e7          	jalr	1666(ra) # 80003b50 <dirlookup>
    800054d6:	892a                	mv	s2,a0
    800054d8:	12050263          	beqz	a0,800055fc <sys_unlink+0x1b0>
  ilock(ip);
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	196080e7          	jalr	406(ra) # 80003672 <ilock>
  if(ip->nlink < 1)
    800054e4:	04a91783          	lh	a5,74(s2)
    800054e8:	08f05263          	blez	a5,8000556c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800054ec:	04491703          	lh	a4,68(s2)
    800054f0:	4785                	li	a5,1
    800054f2:	08f70563          	beq	a4,a5,8000557c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800054f6:	4641                	li	a2,16
    800054f8:	4581                	li	a1,0
    800054fa:	fc040513          	addi	a0,s0,-64
    800054fe:	ffffc097          	auipc	ra,0xffffc
    80005502:	80e080e7          	jalr	-2034(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005506:	4741                	li	a4,16
    80005508:	f2c42683          	lw	a3,-212(s0)
    8000550c:	fc040613          	addi	a2,s0,-64
    80005510:	4581                	li	a1,0
    80005512:	8526                	mv	a0,s1
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	508080e7          	jalr	1288(ra) # 80003a1c <writei>
    8000551c:	47c1                	li	a5,16
    8000551e:	0af51563          	bne	a0,a5,800055c8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005522:	04491703          	lh	a4,68(s2)
    80005526:	4785                	li	a5,1
    80005528:	0af70863          	beq	a4,a5,800055d8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000552c:	8526                	mv	a0,s1
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	3a6080e7          	jalr	934(ra) # 800038d4 <iunlockput>
  ip->nlink--;
    80005536:	04a95783          	lhu	a5,74(s2)
    8000553a:	37fd                	addiw	a5,a5,-1
    8000553c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005540:	854a                	mv	a0,s2
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	066080e7          	jalr	102(ra) # 800035a8 <iupdate>
  iunlockput(ip);
    8000554a:	854a                	mv	a0,s2
    8000554c:	ffffe097          	auipc	ra,0xffffe
    80005550:	388080e7          	jalr	904(ra) # 800038d4 <iunlockput>
  end_op();
    80005554:	fffff097          	auipc	ra,0xfffff
    80005558:	b5a080e7          	jalr	-1190(ra) # 800040ae <end_op>
  return 0;
    8000555c:	4501                	li	a0,0
    8000555e:	a84d                	j	80005610 <sys_unlink+0x1c4>
    end_op();
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	b4e080e7          	jalr	-1202(ra) # 800040ae <end_op>
    return -1;
    80005568:	557d                	li	a0,-1
    8000556a:	a05d                	j	80005610 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000556c:	00003517          	auipc	a0,0x3
    80005570:	32450513          	addi	a0,a0,804 # 80008890 <syscalls_name+0x2f0>
    80005574:	ffffb097          	auipc	ra,0xffffb
    80005578:	fd4080e7          	jalr	-44(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000557c:	04c92703          	lw	a4,76(s2)
    80005580:	02000793          	li	a5,32
    80005584:	f6e7f9e3          	bgeu	a5,a4,800054f6 <sys_unlink+0xaa>
    80005588:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000558c:	4741                	li	a4,16
    8000558e:	86ce                	mv	a3,s3
    80005590:	f1840613          	addi	a2,s0,-232
    80005594:	4581                	li	a1,0
    80005596:	854a                	mv	a0,s2
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	38e080e7          	jalr	910(ra) # 80003926 <readi>
    800055a0:	47c1                	li	a5,16
    800055a2:	00f51b63          	bne	a0,a5,800055b8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055a6:	f1845783          	lhu	a5,-232(s0)
    800055aa:	e7a1                	bnez	a5,800055f2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055ac:	29c1                	addiw	s3,s3,16
    800055ae:	04c92783          	lw	a5,76(s2)
    800055b2:	fcf9ede3          	bltu	s3,a5,8000558c <sys_unlink+0x140>
    800055b6:	b781                	j	800054f6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055b8:	00003517          	auipc	a0,0x3
    800055bc:	2f050513          	addi	a0,a0,752 # 800088a8 <syscalls_name+0x308>
    800055c0:	ffffb097          	auipc	ra,0xffffb
    800055c4:	f88080e7          	jalr	-120(ra) # 80000548 <panic>
    panic("unlink: writei");
    800055c8:	00003517          	auipc	a0,0x3
    800055cc:	2f850513          	addi	a0,a0,760 # 800088c0 <syscalls_name+0x320>
    800055d0:	ffffb097          	auipc	ra,0xffffb
    800055d4:	f78080e7          	jalr	-136(ra) # 80000548 <panic>
    dp->nlink--;
    800055d8:	04a4d783          	lhu	a5,74(s1)
    800055dc:	37fd                	addiw	a5,a5,-1
    800055de:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055e2:	8526                	mv	a0,s1
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	fc4080e7          	jalr	-60(ra) # 800035a8 <iupdate>
    800055ec:	b781                	j	8000552c <sys_unlink+0xe0>
    return -1;
    800055ee:	557d                	li	a0,-1
    800055f0:	a005                	j	80005610 <sys_unlink+0x1c4>
    iunlockput(ip);
    800055f2:	854a                	mv	a0,s2
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	2e0080e7          	jalr	736(ra) # 800038d4 <iunlockput>
  iunlockput(dp);
    800055fc:	8526                	mv	a0,s1
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	2d6080e7          	jalr	726(ra) # 800038d4 <iunlockput>
  end_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	aa8080e7          	jalr	-1368(ra) # 800040ae <end_op>
  return -1;
    8000560e:	557d                	li	a0,-1
}
    80005610:	70ae                	ld	ra,232(sp)
    80005612:	740e                	ld	s0,224(sp)
    80005614:	64ee                	ld	s1,216(sp)
    80005616:	694e                	ld	s2,208(sp)
    80005618:	69ae                	ld	s3,200(sp)
    8000561a:	616d                	addi	sp,sp,240
    8000561c:	8082                	ret

000000008000561e <sys_open>:

uint64
sys_open(void)
{
    8000561e:	7131                	addi	sp,sp,-192
    80005620:	fd06                	sd	ra,184(sp)
    80005622:	f922                	sd	s0,176(sp)
    80005624:	f526                	sd	s1,168(sp)
    80005626:	f14a                	sd	s2,160(sp)
    80005628:	ed4e                	sd	s3,152(sp)
    8000562a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000562c:	08000613          	li	a2,128
    80005630:	f5040593          	addi	a1,s0,-176
    80005634:	4501                	li	a0,0
    80005636:	ffffd097          	auipc	ra,0xffffd
    8000563a:	4ae080e7          	jalr	1198(ra) # 80002ae4 <argstr>
    return -1;
    8000563e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005640:	0c054163          	bltz	a0,80005702 <sys_open+0xe4>
    80005644:	f4c40593          	addi	a1,s0,-180
    80005648:	4505                	li	a0,1
    8000564a:	ffffd097          	auipc	ra,0xffffd
    8000564e:	456080e7          	jalr	1110(ra) # 80002aa0 <argint>
    80005652:	0a054863          	bltz	a0,80005702 <sys_open+0xe4>

  begin_op();
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	9d8080e7          	jalr	-1576(ra) # 8000402e <begin_op>

  if(omode & O_CREATE){
    8000565e:	f4c42783          	lw	a5,-180(s0)
    80005662:	2007f793          	andi	a5,a5,512
    80005666:	cbdd                	beqz	a5,8000571c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005668:	4681                	li	a3,0
    8000566a:	4601                	li	a2,0
    8000566c:	4589                	li	a1,2
    8000566e:	f5040513          	addi	a0,s0,-176
    80005672:	00000097          	auipc	ra,0x0
    80005676:	972080e7          	jalr	-1678(ra) # 80004fe4 <create>
    8000567a:	892a                	mv	s2,a0
    if(ip == 0){
    8000567c:	c959                	beqz	a0,80005712 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000567e:	04491703          	lh	a4,68(s2)
    80005682:	478d                	li	a5,3
    80005684:	00f71763          	bne	a4,a5,80005692 <sys_open+0x74>
    80005688:	04695703          	lhu	a4,70(s2)
    8000568c:	47a5                	li	a5,9
    8000568e:	0ce7ec63          	bltu	a5,a4,80005766 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	db2080e7          	jalr	-590(ra) # 80004444 <filealloc>
    8000569a:	89aa                	mv	s3,a0
    8000569c:	10050263          	beqz	a0,800057a0 <sys_open+0x182>
    800056a0:	00000097          	auipc	ra,0x0
    800056a4:	902080e7          	jalr	-1790(ra) # 80004fa2 <fdalloc>
    800056a8:	84aa                	mv	s1,a0
    800056aa:	0e054663          	bltz	a0,80005796 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056ae:	04491703          	lh	a4,68(s2)
    800056b2:	478d                	li	a5,3
    800056b4:	0cf70463          	beq	a4,a5,8000577c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056b8:	4789                	li	a5,2
    800056ba:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056be:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056c2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800056c6:	f4c42783          	lw	a5,-180(s0)
    800056ca:	0017c713          	xori	a4,a5,1
    800056ce:	8b05                	andi	a4,a4,1
    800056d0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800056d4:	0037f713          	andi	a4,a5,3
    800056d8:	00e03733          	snez	a4,a4
    800056dc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800056e0:	4007f793          	andi	a5,a5,1024
    800056e4:	c791                	beqz	a5,800056f0 <sys_open+0xd2>
    800056e6:	04491703          	lh	a4,68(s2)
    800056ea:	4789                	li	a5,2
    800056ec:	08f70f63          	beq	a4,a5,8000578a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800056f0:	854a                	mv	a0,s2
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	042080e7          	jalr	66(ra) # 80003734 <iunlock>
  end_op();
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	9b4080e7          	jalr	-1612(ra) # 800040ae <end_op>

  return fd;
}
    80005702:	8526                	mv	a0,s1
    80005704:	70ea                	ld	ra,184(sp)
    80005706:	744a                	ld	s0,176(sp)
    80005708:	74aa                	ld	s1,168(sp)
    8000570a:	790a                	ld	s2,160(sp)
    8000570c:	69ea                	ld	s3,152(sp)
    8000570e:	6129                	addi	sp,sp,192
    80005710:	8082                	ret
      end_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	99c080e7          	jalr	-1636(ra) # 800040ae <end_op>
      return -1;
    8000571a:	b7e5                	j	80005702 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000571c:	f5040513          	addi	a0,s0,-176
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	702080e7          	jalr	1794(ra) # 80003e22 <namei>
    80005728:	892a                	mv	s2,a0
    8000572a:	c905                	beqz	a0,8000575a <sys_open+0x13c>
    ilock(ip);
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	f46080e7          	jalr	-186(ra) # 80003672 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005734:	04491703          	lh	a4,68(s2)
    80005738:	4785                	li	a5,1
    8000573a:	f4f712e3          	bne	a4,a5,8000567e <sys_open+0x60>
    8000573e:	f4c42783          	lw	a5,-180(s0)
    80005742:	dba1                	beqz	a5,80005692 <sys_open+0x74>
      iunlockput(ip);
    80005744:	854a                	mv	a0,s2
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	18e080e7          	jalr	398(ra) # 800038d4 <iunlockput>
      end_op();
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	960080e7          	jalr	-1696(ra) # 800040ae <end_op>
      return -1;
    80005756:	54fd                	li	s1,-1
    80005758:	b76d                	j	80005702 <sys_open+0xe4>
      end_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	954080e7          	jalr	-1708(ra) # 800040ae <end_op>
      return -1;
    80005762:	54fd                	li	s1,-1
    80005764:	bf79                	j	80005702 <sys_open+0xe4>
    iunlockput(ip);
    80005766:	854a                	mv	a0,s2
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	16c080e7          	jalr	364(ra) # 800038d4 <iunlockput>
    end_op();
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	93e080e7          	jalr	-1730(ra) # 800040ae <end_op>
    return -1;
    80005778:	54fd                	li	s1,-1
    8000577a:	b761                	j	80005702 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000577c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005780:	04691783          	lh	a5,70(s2)
    80005784:	02f99223          	sh	a5,36(s3)
    80005788:	bf2d                	j	800056c2 <sys_open+0xa4>
    itrunc(ip);
    8000578a:	854a                	mv	a0,s2
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	ff4080e7          	jalr	-12(ra) # 80003780 <itrunc>
    80005794:	bfb1                	j	800056f0 <sys_open+0xd2>
      fileclose(f);
    80005796:	854e                	mv	a0,s3
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	d68080e7          	jalr	-664(ra) # 80004500 <fileclose>
    iunlockput(ip);
    800057a0:	854a                	mv	a0,s2
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	132080e7          	jalr	306(ra) # 800038d4 <iunlockput>
    end_op();
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	904080e7          	jalr	-1788(ra) # 800040ae <end_op>
    return -1;
    800057b2:	54fd                	li	s1,-1
    800057b4:	b7b9                	j	80005702 <sys_open+0xe4>

00000000800057b6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057b6:	7175                	addi	sp,sp,-144
    800057b8:	e506                	sd	ra,136(sp)
    800057ba:	e122                	sd	s0,128(sp)
    800057bc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	870080e7          	jalr	-1936(ra) # 8000402e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800057c6:	08000613          	li	a2,128
    800057ca:	f7040593          	addi	a1,s0,-144
    800057ce:	4501                	li	a0,0
    800057d0:	ffffd097          	auipc	ra,0xffffd
    800057d4:	314080e7          	jalr	788(ra) # 80002ae4 <argstr>
    800057d8:	02054963          	bltz	a0,8000580a <sys_mkdir+0x54>
    800057dc:	4681                	li	a3,0
    800057de:	4601                	li	a2,0
    800057e0:	4585                	li	a1,1
    800057e2:	f7040513          	addi	a0,s0,-144
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	7fe080e7          	jalr	2046(ra) # 80004fe4 <create>
    800057ee:	cd11                	beqz	a0,8000580a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	0e4080e7          	jalr	228(ra) # 800038d4 <iunlockput>
  end_op();
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	8b6080e7          	jalr	-1866(ra) # 800040ae <end_op>
  return 0;
    80005800:	4501                	li	a0,0
}
    80005802:	60aa                	ld	ra,136(sp)
    80005804:	640a                	ld	s0,128(sp)
    80005806:	6149                	addi	sp,sp,144
    80005808:	8082                	ret
    end_op();
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	8a4080e7          	jalr	-1884(ra) # 800040ae <end_op>
    return -1;
    80005812:	557d                	li	a0,-1
    80005814:	b7fd                	j	80005802 <sys_mkdir+0x4c>

0000000080005816 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005816:	7135                	addi	sp,sp,-160
    80005818:	ed06                	sd	ra,152(sp)
    8000581a:	e922                	sd	s0,144(sp)
    8000581c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	810080e7          	jalr	-2032(ra) # 8000402e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005826:	08000613          	li	a2,128
    8000582a:	f7040593          	addi	a1,s0,-144
    8000582e:	4501                	li	a0,0
    80005830:	ffffd097          	auipc	ra,0xffffd
    80005834:	2b4080e7          	jalr	692(ra) # 80002ae4 <argstr>
    80005838:	04054a63          	bltz	a0,8000588c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000583c:	f6c40593          	addi	a1,s0,-148
    80005840:	4505                	li	a0,1
    80005842:	ffffd097          	auipc	ra,0xffffd
    80005846:	25e080e7          	jalr	606(ra) # 80002aa0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000584a:	04054163          	bltz	a0,8000588c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000584e:	f6840593          	addi	a1,s0,-152
    80005852:	4509                	li	a0,2
    80005854:	ffffd097          	auipc	ra,0xffffd
    80005858:	24c080e7          	jalr	588(ra) # 80002aa0 <argint>
     argint(1, &major) < 0 ||
    8000585c:	02054863          	bltz	a0,8000588c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005860:	f6841683          	lh	a3,-152(s0)
    80005864:	f6c41603          	lh	a2,-148(s0)
    80005868:	458d                	li	a1,3
    8000586a:	f7040513          	addi	a0,s0,-144
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	776080e7          	jalr	1910(ra) # 80004fe4 <create>
     argint(2, &minor) < 0 ||
    80005876:	c919                	beqz	a0,8000588c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	05c080e7          	jalr	92(ra) # 800038d4 <iunlockput>
  end_op();
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	82e080e7          	jalr	-2002(ra) # 800040ae <end_op>
  return 0;
    80005888:	4501                	li	a0,0
    8000588a:	a031                	j	80005896 <sys_mknod+0x80>
    end_op();
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	822080e7          	jalr	-2014(ra) # 800040ae <end_op>
    return -1;
    80005894:	557d                	li	a0,-1
}
    80005896:	60ea                	ld	ra,152(sp)
    80005898:	644a                	ld	s0,144(sp)
    8000589a:	610d                	addi	sp,sp,160
    8000589c:	8082                	ret

000000008000589e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000589e:	7135                	addi	sp,sp,-160
    800058a0:	ed06                	sd	ra,152(sp)
    800058a2:	e922                	sd	s0,144(sp)
    800058a4:	e526                	sd	s1,136(sp)
    800058a6:	e14a                	sd	s2,128(sp)
    800058a8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058aa:	ffffc097          	auipc	ra,0xffffc
    800058ae:	134080e7          	jalr	308(ra) # 800019de <myproc>
    800058b2:	892a                	mv	s2,a0
  
  begin_op();
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	77a080e7          	jalr	1914(ra) # 8000402e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058bc:	08000613          	li	a2,128
    800058c0:	f6040593          	addi	a1,s0,-160
    800058c4:	4501                	li	a0,0
    800058c6:	ffffd097          	auipc	ra,0xffffd
    800058ca:	21e080e7          	jalr	542(ra) # 80002ae4 <argstr>
    800058ce:	04054b63          	bltz	a0,80005924 <sys_chdir+0x86>
    800058d2:	f6040513          	addi	a0,s0,-160
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	54c080e7          	jalr	1356(ra) # 80003e22 <namei>
    800058de:	84aa                	mv	s1,a0
    800058e0:	c131                	beqz	a0,80005924 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	d90080e7          	jalr	-624(ra) # 80003672 <ilock>
  if(ip->type != T_DIR){
    800058ea:	04449703          	lh	a4,68(s1)
    800058ee:	4785                	li	a5,1
    800058f0:	04f71063          	bne	a4,a5,80005930 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800058f4:	8526                	mv	a0,s1
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	e3e080e7          	jalr	-450(ra) # 80003734 <iunlock>
  iput(p->cwd);
    800058fe:	15093503          	ld	a0,336(s2)
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	f2a080e7          	jalr	-214(ra) # 8000382c <iput>
  end_op();
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	7a4080e7          	jalr	1956(ra) # 800040ae <end_op>
  p->cwd = ip;
    80005912:	14993823          	sd	s1,336(s2)
  return 0;
    80005916:	4501                	li	a0,0
}
    80005918:	60ea                	ld	ra,152(sp)
    8000591a:	644a                	ld	s0,144(sp)
    8000591c:	64aa                	ld	s1,136(sp)
    8000591e:	690a                	ld	s2,128(sp)
    80005920:	610d                	addi	sp,sp,160
    80005922:	8082                	ret
    end_op();
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	78a080e7          	jalr	1930(ra) # 800040ae <end_op>
    return -1;
    8000592c:	557d                	li	a0,-1
    8000592e:	b7ed                	j	80005918 <sys_chdir+0x7a>
    iunlockput(ip);
    80005930:	8526                	mv	a0,s1
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	fa2080e7          	jalr	-94(ra) # 800038d4 <iunlockput>
    end_op();
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	774080e7          	jalr	1908(ra) # 800040ae <end_op>
    return -1;
    80005942:	557d                	li	a0,-1
    80005944:	bfd1                	j	80005918 <sys_chdir+0x7a>

0000000080005946 <sys_exec>:

uint64
sys_exec(void)
{
    80005946:	7145                	addi	sp,sp,-464
    80005948:	e786                	sd	ra,456(sp)
    8000594a:	e3a2                	sd	s0,448(sp)
    8000594c:	ff26                	sd	s1,440(sp)
    8000594e:	fb4a                	sd	s2,432(sp)
    80005950:	f74e                	sd	s3,424(sp)
    80005952:	f352                	sd	s4,416(sp)
    80005954:	ef56                	sd	s5,408(sp)
    80005956:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005958:	08000613          	li	a2,128
    8000595c:	f4040593          	addi	a1,s0,-192
    80005960:	4501                	li	a0,0
    80005962:	ffffd097          	auipc	ra,0xffffd
    80005966:	182080e7          	jalr	386(ra) # 80002ae4 <argstr>
    return -1;
    8000596a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000596c:	0c054a63          	bltz	a0,80005a40 <sys_exec+0xfa>
    80005970:	e3840593          	addi	a1,s0,-456
    80005974:	4505                	li	a0,1
    80005976:	ffffd097          	auipc	ra,0xffffd
    8000597a:	14c080e7          	jalr	332(ra) # 80002ac2 <argaddr>
    8000597e:	0c054163          	bltz	a0,80005a40 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005982:	10000613          	li	a2,256
    80005986:	4581                	li	a1,0
    80005988:	e4040513          	addi	a0,s0,-448
    8000598c:	ffffb097          	auipc	ra,0xffffb
    80005990:	380080e7          	jalr	896(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005994:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005998:	89a6                	mv	s3,s1
    8000599a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000599c:	02000a13          	li	s4,32
    800059a0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059a4:	00391513          	slli	a0,s2,0x3
    800059a8:	e3040593          	addi	a1,s0,-464
    800059ac:	e3843783          	ld	a5,-456(s0)
    800059b0:	953e                	add	a0,a0,a5
    800059b2:	ffffd097          	auipc	ra,0xffffd
    800059b6:	054080e7          	jalr	84(ra) # 80002a06 <fetchaddr>
    800059ba:	02054a63          	bltz	a0,800059ee <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059be:	e3043783          	ld	a5,-464(s0)
    800059c2:	c3b9                	beqz	a5,80005a08 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059c4:	ffffb097          	auipc	ra,0xffffb
    800059c8:	15c080e7          	jalr	348(ra) # 80000b20 <kalloc>
    800059cc:	85aa                	mv	a1,a0
    800059ce:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800059d2:	cd11                	beqz	a0,800059ee <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800059d4:	6605                	lui	a2,0x1
    800059d6:	e3043503          	ld	a0,-464(s0)
    800059da:	ffffd097          	auipc	ra,0xffffd
    800059de:	07e080e7          	jalr	126(ra) # 80002a58 <fetchstr>
    800059e2:	00054663          	bltz	a0,800059ee <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800059e6:	0905                	addi	s2,s2,1
    800059e8:	09a1                	addi	s3,s3,8
    800059ea:	fb491be3          	bne	s2,s4,800059a0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059ee:	10048913          	addi	s2,s1,256
    800059f2:	6088                	ld	a0,0(s1)
    800059f4:	c529                	beqz	a0,80005a3e <sys_exec+0xf8>
    kfree(argv[i]);
    800059f6:	ffffb097          	auipc	ra,0xffffb
    800059fa:	02e080e7          	jalr	46(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800059fe:	04a1                	addi	s1,s1,8
    80005a00:	ff2499e3          	bne	s1,s2,800059f2 <sys_exec+0xac>
  return -1;
    80005a04:	597d                	li	s2,-1
    80005a06:	a82d                	j	80005a40 <sys_exec+0xfa>
      argv[i] = 0;
    80005a08:	0a8e                	slli	s5,s5,0x3
    80005a0a:	fc040793          	addi	a5,s0,-64
    80005a0e:	9abe                	add	s5,s5,a5
    80005a10:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a14:	e4040593          	addi	a1,s0,-448
    80005a18:	f4040513          	addi	a0,s0,-192
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	194080e7          	jalr	404(ra) # 80004bb0 <exec>
    80005a24:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a26:	10048993          	addi	s3,s1,256
    80005a2a:	6088                	ld	a0,0(s1)
    80005a2c:	c911                	beqz	a0,80005a40 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a2e:	ffffb097          	auipc	ra,0xffffb
    80005a32:	ff6080e7          	jalr	-10(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a36:	04a1                	addi	s1,s1,8
    80005a38:	ff3499e3          	bne	s1,s3,80005a2a <sys_exec+0xe4>
    80005a3c:	a011                	j	80005a40 <sys_exec+0xfa>
  return -1;
    80005a3e:	597d                	li	s2,-1
}
    80005a40:	854a                	mv	a0,s2
    80005a42:	60be                	ld	ra,456(sp)
    80005a44:	641e                	ld	s0,448(sp)
    80005a46:	74fa                	ld	s1,440(sp)
    80005a48:	795a                	ld	s2,432(sp)
    80005a4a:	79ba                	ld	s3,424(sp)
    80005a4c:	7a1a                	ld	s4,416(sp)
    80005a4e:	6afa                	ld	s5,408(sp)
    80005a50:	6179                	addi	sp,sp,464
    80005a52:	8082                	ret

0000000080005a54 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a54:	7139                	addi	sp,sp,-64
    80005a56:	fc06                	sd	ra,56(sp)
    80005a58:	f822                	sd	s0,48(sp)
    80005a5a:	f426                	sd	s1,40(sp)
    80005a5c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a5e:	ffffc097          	auipc	ra,0xffffc
    80005a62:	f80080e7          	jalr	-128(ra) # 800019de <myproc>
    80005a66:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005a68:	fd840593          	addi	a1,s0,-40
    80005a6c:	4501                	li	a0,0
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	054080e7          	jalr	84(ra) # 80002ac2 <argaddr>
    return -1;
    80005a76:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005a78:	0e054063          	bltz	a0,80005b58 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005a7c:	fc840593          	addi	a1,s0,-56
    80005a80:	fd040513          	addi	a0,s0,-48
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	dd2080e7          	jalr	-558(ra) # 80004856 <pipealloc>
    return -1;
    80005a8c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005a8e:	0c054563          	bltz	a0,80005b58 <sys_pipe+0x104>
  fd0 = -1;
    80005a92:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005a96:	fd043503          	ld	a0,-48(s0)
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	508080e7          	jalr	1288(ra) # 80004fa2 <fdalloc>
    80005aa2:	fca42223          	sw	a0,-60(s0)
    80005aa6:	08054c63          	bltz	a0,80005b3e <sys_pipe+0xea>
    80005aaa:	fc843503          	ld	a0,-56(s0)
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	4f4080e7          	jalr	1268(ra) # 80004fa2 <fdalloc>
    80005ab6:	fca42023          	sw	a0,-64(s0)
    80005aba:	06054863          	bltz	a0,80005b2a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005abe:	4691                	li	a3,4
    80005ac0:	fc440613          	addi	a2,s0,-60
    80005ac4:	fd843583          	ld	a1,-40(s0)
    80005ac8:	68a8                	ld	a0,80(s1)
    80005aca:	ffffc097          	auipc	ra,0xffffc
    80005ace:	c08080e7          	jalr	-1016(ra) # 800016d2 <copyout>
    80005ad2:	02054063          	bltz	a0,80005af2 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ad6:	4691                	li	a3,4
    80005ad8:	fc040613          	addi	a2,s0,-64
    80005adc:	fd843583          	ld	a1,-40(s0)
    80005ae0:	0591                	addi	a1,a1,4
    80005ae2:	68a8                	ld	a0,80(s1)
    80005ae4:	ffffc097          	auipc	ra,0xffffc
    80005ae8:	bee080e7          	jalr	-1042(ra) # 800016d2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005aec:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005aee:	06055563          	bgez	a0,80005b58 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005af2:	fc442783          	lw	a5,-60(s0)
    80005af6:	07e9                	addi	a5,a5,26
    80005af8:	078e                	slli	a5,a5,0x3
    80005afa:	97a6                	add	a5,a5,s1
    80005afc:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b00:	fc042503          	lw	a0,-64(s0)
    80005b04:	0569                	addi	a0,a0,26
    80005b06:	050e                	slli	a0,a0,0x3
    80005b08:	9526                	add	a0,a0,s1
    80005b0a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b0e:	fd043503          	ld	a0,-48(s0)
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	9ee080e7          	jalr	-1554(ra) # 80004500 <fileclose>
    fileclose(wf);
    80005b1a:	fc843503          	ld	a0,-56(s0)
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	9e2080e7          	jalr	-1566(ra) # 80004500 <fileclose>
    return -1;
    80005b26:	57fd                	li	a5,-1
    80005b28:	a805                	j	80005b58 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b2a:	fc442783          	lw	a5,-60(s0)
    80005b2e:	0007c863          	bltz	a5,80005b3e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b32:	01a78513          	addi	a0,a5,26
    80005b36:	050e                	slli	a0,a0,0x3
    80005b38:	9526                	add	a0,a0,s1
    80005b3a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b3e:	fd043503          	ld	a0,-48(s0)
    80005b42:	fffff097          	auipc	ra,0xfffff
    80005b46:	9be080e7          	jalr	-1602(ra) # 80004500 <fileclose>
    fileclose(wf);
    80005b4a:	fc843503          	ld	a0,-56(s0)
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	9b2080e7          	jalr	-1614(ra) # 80004500 <fileclose>
    return -1;
    80005b56:	57fd                	li	a5,-1
}
    80005b58:	853e                	mv	a0,a5
    80005b5a:	70e2                	ld	ra,56(sp)
    80005b5c:	7442                	ld	s0,48(sp)
    80005b5e:	74a2                	ld	s1,40(sp)
    80005b60:	6121                	addi	sp,sp,64
    80005b62:	8082                	ret
	...

0000000080005b70 <kernelvec>:
    80005b70:	7111                	addi	sp,sp,-256
    80005b72:	e006                	sd	ra,0(sp)
    80005b74:	e40a                	sd	sp,8(sp)
    80005b76:	e80e                	sd	gp,16(sp)
    80005b78:	ec12                	sd	tp,24(sp)
    80005b7a:	f016                	sd	t0,32(sp)
    80005b7c:	f41a                	sd	t1,40(sp)
    80005b7e:	f81e                	sd	t2,48(sp)
    80005b80:	fc22                	sd	s0,56(sp)
    80005b82:	e0a6                	sd	s1,64(sp)
    80005b84:	e4aa                	sd	a0,72(sp)
    80005b86:	e8ae                	sd	a1,80(sp)
    80005b88:	ecb2                	sd	a2,88(sp)
    80005b8a:	f0b6                	sd	a3,96(sp)
    80005b8c:	f4ba                	sd	a4,104(sp)
    80005b8e:	f8be                	sd	a5,112(sp)
    80005b90:	fcc2                	sd	a6,120(sp)
    80005b92:	e146                	sd	a7,128(sp)
    80005b94:	e54a                	sd	s2,136(sp)
    80005b96:	e94e                	sd	s3,144(sp)
    80005b98:	ed52                	sd	s4,152(sp)
    80005b9a:	f156                	sd	s5,160(sp)
    80005b9c:	f55a                	sd	s6,168(sp)
    80005b9e:	f95e                	sd	s7,176(sp)
    80005ba0:	fd62                	sd	s8,184(sp)
    80005ba2:	e1e6                	sd	s9,192(sp)
    80005ba4:	e5ea                	sd	s10,200(sp)
    80005ba6:	e9ee                	sd	s11,208(sp)
    80005ba8:	edf2                	sd	t3,216(sp)
    80005baa:	f1f6                	sd	t4,224(sp)
    80005bac:	f5fa                	sd	t5,232(sp)
    80005bae:	f9fe                	sd	t6,240(sp)
    80005bb0:	d23fc0ef          	jal	ra,800028d2 <kerneltrap>
    80005bb4:	6082                	ld	ra,0(sp)
    80005bb6:	6122                	ld	sp,8(sp)
    80005bb8:	61c2                	ld	gp,16(sp)
    80005bba:	7282                	ld	t0,32(sp)
    80005bbc:	7322                	ld	t1,40(sp)
    80005bbe:	73c2                	ld	t2,48(sp)
    80005bc0:	7462                	ld	s0,56(sp)
    80005bc2:	6486                	ld	s1,64(sp)
    80005bc4:	6526                	ld	a0,72(sp)
    80005bc6:	65c6                	ld	a1,80(sp)
    80005bc8:	6666                	ld	a2,88(sp)
    80005bca:	7686                	ld	a3,96(sp)
    80005bcc:	7726                	ld	a4,104(sp)
    80005bce:	77c6                	ld	a5,112(sp)
    80005bd0:	7866                	ld	a6,120(sp)
    80005bd2:	688a                	ld	a7,128(sp)
    80005bd4:	692a                	ld	s2,136(sp)
    80005bd6:	69ca                	ld	s3,144(sp)
    80005bd8:	6a6a                	ld	s4,152(sp)
    80005bda:	7a8a                	ld	s5,160(sp)
    80005bdc:	7b2a                	ld	s6,168(sp)
    80005bde:	7bca                	ld	s7,176(sp)
    80005be0:	7c6a                	ld	s8,184(sp)
    80005be2:	6c8e                	ld	s9,192(sp)
    80005be4:	6d2e                	ld	s10,200(sp)
    80005be6:	6dce                	ld	s11,208(sp)
    80005be8:	6e6e                	ld	t3,216(sp)
    80005bea:	7e8e                	ld	t4,224(sp)
    80005bec:	7f2e                	ld	t5,232(sp)
    80005bee:	7fce                	ld	t6,240(sp)
    80005bf0:	6111                	addi	sp,sp,256
    80005bf2:	10200073          	sret
    80005bf6:	00000013          	nop
    80005bfa:	00000013          	nop
    80005bfe:	0001                	nop

0000000080005c00 <timervec>:
    80005c00:	34051573          	csrrw	a0,mscratch,a0
    80005c04:	e10c                	sd	a1,0(a0)
    80005c06:	e510                	sd	a2,8(a0)
    80005c08:	e914                	sd	a3,16(a0)
    80005c0a:	710c                	ld	a1,32(a0)
    80005c0c:	7510                	ld	a2,40(a0)
    80005c0e:	6194                	ld	a3,0(a1)
    80005c10:	96b2                	add	a3,a3,a2
    80005c12:	e194                	sd	a3,0(a1)
    80005c14:	4589                	li	a1,2
    80005c16:	14459073          	csrw	sip,a1
    80005c1a:	6914                	ld	a3,16(a0)
    80005c1c:	6510                	ld	a2,8(a0)
    80005c1e:	610c                	ld	a1,0(a0)
    80005c20:	34051573          	csrrw	a0,mscratch,a0
    80005c24:	30200073          	mret
	...

0000000080005c2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c2a:	1141                	addi	sp,sp,-16
    80005c2c:	e422                	sd	s0,8(sp)
    80005c2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c30:	0c0007b7          	lui	a5,0xc000
    80005c34:	4705                	li	a4,1
    80005c36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c38:	c3d8                	sw	a4,4(a5)
}
    80005c3a:	6422                	ld	s0,8(sp)
    80005c3c:	0141                	addi	sp,sp,16
    80005c3e:	8082                	ret

0000000080005c40 <plicinithart>:

void
plicinithart(void)
{
    80005c40:	1141                	addi	sp,sp,-16
    80005c42:	e406                	sd	ra,8(sp)
    80005c44:	e022                	sd	s0,0(sp)
    80005c46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c48:	ffffc097          	auipc	ra,0xffffc
    80005c4c:	d6a080e7          	jalr	-662(ra) # 800019b2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c50:	0085171b          	slliw	a4,a0,0x8
    80005c54:	0c0027b7          	lui	a5,0xc002
    80005c58:	97ba                	add	a5,a5,a4
    80005c5a:	40200713          	li	a4,1026
    80005c5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c62:	00d5151b          	slliw	a0,a0,0xd
    80005c66:	0c2017b7          	lui	a5,0xc201
    80005c6a:	953e                	add	a0,a0,a5
    80005c6c:	00052023          	sw	zero,0(a0)
}
    80005c70:	60a2                	ld	ra,8(sp)
    80005c72:	6402                	ld	s0,0(sp)
    80005c74:	0141                	addi	sp,sp,16
    80005c76:	8082                	ret

0000000080005c78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005c78:	1141                	addi	sp,sp,-16
    80005c7a:	e406                	sd	ra,8(sp)
    80005c7c:	e022                	sd	s0,0(sp)
    80005c7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c80:	ffffc097          	auipc	ra,0xffffc
    80005c84:	d32080e7          	jalr	-718(ra) # 800019b2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005c88:	00d5179b          	slliw	a5,a0,0xd
    80005c8c:	0c201537          	lui	a0,0xc201
    80005c90:	953e                	add	a0,a0,a5
  return irq;
}
    80005c92:	4148                	lw	a0,4(a0)
    80005c94:	60a2                	ld	ra,8(sp)
    80005c96:	6402                	ld	s0,0(sp)
    80005c98:	0141                	addi	sp,sp,16
    80005c9a:	8082                	ret

0000000080005c9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005c9c:	1101                	addi	sp,sp,-32
    80005c9e:	ec06                	sd	ra,24(sp)
    80005ca0:	e822                	sd	s0,16(sp)
    80005ca2:	e426                	sd	s1,8(sp)
    80005ca4:	1000                	addi	s0,sp,32
    80005ca6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ca8:	ffffc097          	auipc	ra,0xffffc
    80005cac:	d0a080e7          	jalr	-758(ra) # 800019b2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cb0:	00d5151b          	slliw	a0,a0,0xd
    80005cb4:	0c2017b7          	lui	a5,0xc201
    80005cb8:	97aa                	add	a5,a5,a0
    80005cba:	c3c4                	sw	s1,4(a5)
}
    80005cbc:	60e2                	ld	ra,24(sp)
    80005cbe:	6442                	ld	s0,16(sp)
    80005cc0:	64a2                	ld	s1,8(sp)
    80005cc2:	6105                	addi	sp,sp,32
    80005cc4:	8082                	ret

0000000080005cc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cc6:	1141                	addi	sp,sp,-16
    80005cc8:	e406                	sd	ra,8(sp)
    80005cca:	e022                	sd	s0,0(sp)
    80005ccc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cce:	479d                	li	a5,7
    80005cd0:	04a7cc63          	blt	a5,a0,80005d28 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005cd4:	0001d797          	auipc	a5,0x1d
    80005cd8:	32c78793          	addi	a5,a5,812 # 80023000 <disk>
    80005cdc:	00a78733          	add	a4,a5,a0
    80005ce0:	6789                	lui	a5,0x2
    80005ce2:	97ba                	add	a5,a5,a4
    80005ce4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ce8:	eba1                	bnez	a5,80005d38 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005cea:	00451713          	slli	a4,a0,0x4
    80005cee:	0001f797          	auipc	a5,0x1f
    80005cf2:	3127b783          	ld	a5,786(a5) # 80025000 <disk+0x2000>
    80005cf6:	97ba                	add	a5,a5,a4
    80005cf8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005cfc:	0001d797          	auipc	a5,0x1d
    80005d00:	30478793          	addi	a5,a5,772 # 80023000 <disk>
    80005d04:	97aa                	add	a5,a5,a0
    80005d06:	6509                	lui	a0,0x2
    80005d08:	953e                	add	a0,a0,a5
    80005d0a:	4785                	li	a5,1
    80005d0c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d10:	0001f517          	auipc	a0,0x1f
    80005d14:	30850513          	addi	a0,a0,776 # 80025018 <disk+0x2018>
    80005d18:	ffffc097          	auipc	ra,0xffffc
    80005d1c:	660080e7          	jalr	1632(ra) # 80002378 <wakeup>
}
    80005d20:	60a2                	ld	ra,8(sp)
    80005d22:	6402                	ld	s0,0(sp)
    80005d24:	0141                	addi	sp,sp,16
    80005d26:	8082                	ret
    panic("virtio_disk_intr 1");
    80005d28:	00003517          	auipc	a0,0x3
    80005d2c:	ba850513          	addi	a0,a0,-1112 # 800088d0 <syscalls_name+0x330>
    80005d30:	ffffb097          	auipc	ra,0xffffb
    80005d34:	818080e7          	jalr	-2024(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005d38:	00003517          	auipc	a0,0x3
    80005d3c:	bb050513          	addi	a0,a0,-1104 # 800088e8 <syscalls_name+0x348>
    80005d40:	ffffb097          	auipc	ra,0xffffb
    80005d44:	808080e7          	jalr	-2040(ra) # 80000548 <panic>

0000000080005d48 <virtio_disk_init>:
{
    80005d48:	1101                	addi	sp,sp,-32
    80005d4a:	ec06                	sd	ra,24(sp)
    80005d4c:	e822                	sd	s0,16(sp)
    80005d4e:	e426                	sd	s1,8(sp)
    80005d50:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d52:	00003597          	auipc	a1,0x3
    80005d56:	bae58593          	addi	a1,a1,-1106 # 80008900 <syscalls_name+0x360>
    80005d5a:	0001f517          	auipc	a0,0x1f
    80005d5e:	34e50513          	addi	a0,a0,846 # 800250a8 <disk+0x20a8>
    80005d62:	ffffb097          	auipc	ra,0xffffb
    80005d66:	e1e080e7          	jalr	-482(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d6a:	100017b7          	lui	a5,0x10001
    80005d6e:	4398                	lw	a4,0(a5)
    80005d70:	2701                	sext.w	a4,a4
    80005d72:	747277b7          	lui	a5,0x74727
    80005d76:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005d7a:	0ef71163          	bne	a4,a5,80005e5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d7e:	100017b7          	lui	a5,0x10001
    80005d82:	43dc                	lw	a5,4(a5)
    80005d84:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d86:	4705                	li	a4,1
    80005d88:	0ce79a63          	bne	a5,a4,80005e5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005d8c:	100017b7          	lui	a5,0x10001
    80005d90:	479c                	lw	a5,8(a5)
    80005d92:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005d94:	4709                	li	a4,2
    80005d96:	0ce79363          	bne	a5,a4,80005e5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005d9a:	100017b7          	lui	a5,0x10001
    80005d9e:	47d8                	lw	a4,12(a5)
    80005da0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005da2:	554d47b7          	lui	a5,0x554d4
    80005da6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005daa:	0af71963          	bne	a4,a5,80005e5c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dae:	100017b7          	lui	a5,0x10001
    80005db2:	4705                	li	a4,1
    80005db4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005db6:	470d                	li	a4,3
    80005db8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dba:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005dbc:	c7ffe737          	lui	a4,0xc7ffe
    80005dc0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005dc4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dc6:	2701                	sext.w	a4,a4
    80005dc8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dca:	472d                	li	a4,11
    80005dcc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dce:	473d                	li	a4,15
    80005dd0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005dd2:	6705                	lui	a4,0x1
    80005dd4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005dd6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005dda:	5bdc                	lw	a5,52(a5)
    80005ddc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005dde:	c7d9                	beqz	a5,80005e6c <virtio_disk_init+0x124>
  if(max < NUM)
    80005de0:	471d                	li	a4,7
    80005de2:	08f77d63          	bgeu	a4,a5,80005e7c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005de6:	100014b7          	lui	s1,0x10001
    80005dea:	47a1                	li	a5,8
    80005dec:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005dee:	6609                	lui	a2,0x2
    80005df0:	4581                	li	a1,0
    80005df2:	0001d517          	auipc	a0,0x1d
    80005df6:	20e50513          	addi	a0,a0,526 # 80023000 <disk>
    80005dfa:	ffffb097          	auipc	ra,0xffffb
    80005dfe:	f12080e7          	jalr	-238(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e02:	0001d717          	auipc	a4,0x1d
    80005e06:	1fe70713          	addi	a4,a4,510 # 80023000 <disk>
    80005e0a:	00c75793          	srli	a5,a4,0xc
    80005e0e:	2781                	sext.w	a5,a5
    80005e10:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005e12:	0001f797          	auipc	a5,0x1f
    80005e16:	1ee78793          	addi	a5,a5,494 # 80025000 <disk+0x2000>
    80005e1a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005e1c:	0001d717          	auipc	a4,0x1d
    80005e20:	26470713          	addi	a4,a4,612 # 80023080 <disk+0x80>
    80005e24:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005e26:	0001e717          	auipc	a4,0x1e
    80005e2a:	1da70713          	addi	a4,a4,474 # 80024000 <disk+0x1000>
    80005e2e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e30:	4705                	li	a4,1
    80005e32:	00e78c23          	sb	a4,24(a5)
    80005e36:	00e78ca3          	sb	a4,25(a5)
    80005e3a:	00e78d23          	sb	a4,26(a5)
    80005e3e:	00e78da3          	sb	a4,27(a5)
    80005e42:	00e78e23          	sb	a4,28(a5)
    80005e46:	00e78ea3          	sb	a4,29(a5)
    80005e4a:	00e78f23          	sb	a4,30(a5)
    80005e4e:	00e78fa3          	sb	a4,31(a5)
}
    80005e52:	60e2                	ld	ra,24(sp)
    80005e54:	6442                	ld	s0,16(sp)
    80005e56:	64a2                	ld	s1,8(sp)
    80005e58:	6105                	addi	sp,sp,32
    80005e5a:	8082                	ret
    panic("could not find virtio disk");
    80005e5c:	00003517          	auipc	a0,0x3
    80005e60:	ab450513          	addi	a0,a0,-1356 # 80008910 <syscalls_name+0x370>
    80005e64:	ffffa097          	auipc	ra,0xffffa
    80005e68:	6e4080e7          	jalr	1764(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005e6c:	00003517          	auipc	a0,0x3
    80005e70:	ac450513          	addi	a0,a0,-1340 # 80008930 <syscalls_name+0x390>
    80005e74:	ffffa097          	auipc	ra,0xffffa
    80005e78:	6d4080e7          	jalr	1748(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005e7c:	00003517          	auipc	a0,0x3
    80005e80:	ad450513          	addi	a0,a0,-1324 # 80008950 <syscalls_name+0x3b0>
    80005e84:	ffffa097          	auipc	ra,0xffffa
    80005e88:	6c4080e7          	jalr	1732(ra) # 80000548 <panic>

0000000080005e8c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005e8c:	7119                	addi	sp,sp,-128
    80005e8e:	fc86                	sd	ra,120(sp)
    80005e90:	f8a2                	sd	s0,112(sp)
    80005e92:	f4a6                	sd	s1,104(sp)
    80005e94:	f0ca                	sd	s2,96(sp)
    80005e96:	ecce                	sd	s3,88(sp)
    80005e98:	e8d2                	sd	s4,80(sp)
    80005e9a:	e4d6                	sd	s5,72(sp)
    80005e9c:	e0da                	sd	s6,64(sp)
    80005e9e:	fc5e                	sd	s7,56(sp)
    80005ea0:	f862                	sd	s8,48(sp)
    80005ea2:	f466                	sd	s9,40(sp)
    80005ea4:	f06a                	sd	s10,32(sp)
    80005ea6:	0100                	addi	s0,sp,128
    80005ea8:	892a                	mv	s2,a0
    80005eaa:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005eac:	00c52c83          	lw	s9,12(a0)
    80005eb0:	001c9c9b          	slliw	s9,s9,0x1
    80005eb4:	1c82                	slli	s9,s9,0x20
    80005eb6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005eba:	0001f517          	auipc	a0,0x1f
    80005ebe:	1ee50513          	addi	a0,a0,494 # 800250a8 <disk+0x20a8>
    80005ec2:	ffffb097          	auipc	ra,0xffffb
    80005ec6:	d4e080e7          	jalr	-690(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    80005eca:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005ecc:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005ece:	0001db97          	auipc	s7,0x1d
    80005ed2:	132b8b93          	addi	s7,s7,306 # 80023000 <disk>
    80005ed6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005ed8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005eda:	8a4e                	mv	s4,s3
    80005edc:	a051                	j	80005f60 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005ede:	00fb86b3          	add	a3,s7,a5
    80005ee2:	96da                	add	a3,a3,s6
    80005ee4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005ee8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005eea:	0207c563          	bltz	a5,80005f14 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005eee:	2485                	addiw	s1,s1,1
    80005ef0:	0711                	addi	a4,a4,4
    80005ef2:	23548d63          	beq	s1,s5,8000612c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005ef6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ef8:	0001f697          	auipc	a3,0x1f
    80005efc:	12068693          	addi	a3,a3,288 # 80025018 <disk+0x2018>
    80005f00:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005f02:	0006c583          	lbu	a1,0(a3)
    80005f06:	fde1                	bnez	a1,80005ede <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f08:	2785                	addiw	a5,a5,1
    80005f0a:	0685                	addi	a3,a3,1
    80005f0c:	ff879be3          	bne	a5,s8,80005f02 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f10:	57fd                	li	a5,-1
    80005f12:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005f14:	02905a63          	blez	s1,80005f48 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f18:	f9042503          	lw	a0,-112(s0)
    80005f1c:	00000097          	auipc	ra,0x0
    80005f20:	daa080e7          	jalr	-598(ra) # 80005cc6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f24:	4785                	li	a5,1
    80005f26:	0297d163          	bge	a5,s1,80005f48 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f2a:	f9442503          	lw	a0,-108(s0)
    80005f2e:	00000097          	auipc	ra,0x0
    80005f32:	d98080e7          	jalr	-616(ra) # 80005cc6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f36:	4789                	li	a5,2
    80005f38:	0097d863          	bge	a5,s1,80005f48 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005f3c:	f9842503          	lw	a0,-104(s0)
    80005f40:	00000097          	auipc	ra,0x0
    80005f44:	d86080e7          	jalr	-634(ra) # 80005cc6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f48:	0001f597          	auipc	a1,0x1f
    80005f4c:	16058593          	addi	a1,a1,352 # 800250a8 <disk+0x20a8>
    80005f50:	0001f517          	auipc	a0,0x1f
    80005f54:	0c850513          	addi	a0,a0,200 # 80025018 <disk+0x2018>
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	29a080e7          	jalr	666(ra) # 800021f2 <sleep>
  for(int i = 0; i < 3; i++){
    80005f60:	f9040713          	addi	a4,s0,-112
    80005f64:	84ce                	mv	s1,s3
    80005f66:	bf41                	j	80005ef6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80005f68:	4785                	li	a5,1
    80005f6a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    80005f6e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80005f72:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80005f76:	f9042983          	lw	s3,-112(s0)
    80005f7a:	00499493          	slli	s1,s3,0x4
    80005f7e:	0001fa17          	auipc	s4,0x1f
    80005f82:	082a0a13          	addi	s4,s4,130 # 80025000 <disk+0x2000>
    80005f86:	000a3a83          	ld	s5,0(s4)
    80005f8a:	9aa6                	add	s5,s5,s1
    80005f8c:	f8040513          	addi	a0,s0,-128
    80005f90:	ffffb097          	auipc	ra,0xffffb
    80005f94:	150080e7          	jalr	336(ra) # 800010e0 <kvmpa>
    80005f98:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    80005f9c:	000a3783          	ld	a5,0(s4)
    80005fa0:	97a6                	add	a5,a5,s1
    80005fa2:	4741                	li	a4,16
    80005fa4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005fa6:	000a3783          	ld	a5,0(s4)
    80005faa:	97a6                	add	a5,a5,s1
    80005fac:	4705                	li	a4,1
    80005fae:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80005fb2:	f9442703          	lw	a4,-108(s0)
    80005fb6:	000a3783          	ld	a5,0(s4)
    80005fba:	97a6                	add	a5,a5,s1
    80005fbc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005fc0:	0712                	slli	a4,a4,0x4
    80005fc2:	000a3783          	ld	a5,0(s4)
    80005fc6:	97ba                	add	a5,a5,a4
    80005fc8:	05890693          	addi	a3,s2,88
    80005fcc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    80005fce:	000a3783          	ld	a5,0(s4)
    80005fd2:	97ba                	add	a5,a5,a4
    80005fd4:	40000693          	li	a3,1024
    80005fd8:	c794                	sw	a3,8(a5)
  if(write)
    80005fda:	100d0a63          	beqz	s10,800060ee <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005fde:	0001f797          	auipc	a5,0x1f
    80005fe2:	0227b783          	ld	a5,34(a5) # 80025000 <disk+0x2000>
    80005fe6:	97ba                	add	a5,a5,a4
    80005fe8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005fec:	0001d517          	auipc	a0,0x1d
    80005ff0:	01450513          	addi	a0,a0,20 # 80023000 <disk>
    80005ff4:	0001f797          	auipc	a5,0x1f
    80005ff8:	00c78793          	addi	a5,a5,12 # 80025000 <disk+0x2000>
    80005ffc:	6394                	ld	a3,0(a5)
    80005ffe:	96ba                	add	a3,a3,a4
    80006000:	00c6d603          	lhu	a2,12(a3)
    80006004:	00166613          	ori	a2,a2,1
    80006008:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000600c:	f9842683          	lw	a3,-104(s0)
    80006010:	6390                	ld	a2,0(a5)
    80006012:	9732                	add	a4,a4,a2
    80006014:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006018:	20098613          	addi	a2,s3,512
    8000601c:	0612                	slli	a2,a2,0x4
    8000601e:	962a                	add	a2,a2,a0
    80006020:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006024:	00469713          	slli	a4,a3,0x4
    80006028:	6394                	ld	a3,0(a5)
    8000602a:	96ba                	add	a3,a3,a4
    8000602c:	6589                	lui	a1,0x2
    8000602e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006032:	94ae                	add	s1,s1,a1
    80006034:	94aa                	add	s1,s1,a0
    80006036:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006038:	6394                	ld	a3,0(a5)
    8000603a:	96ba                	add	a3,a3,a4
    8000603c:	4585                	li	a1,1
    8000603e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006040:	6394                	ld	a3,0(a5)
    80006042:	96ba                	add	a3,a3,a4
    80006044:	4509                	li	a0,2
    80006046:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000604a:	6394                	ld	a3,0(a5)
    8000604c:	9736                	add	a4,a4,a3
    8000604e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006052:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006056:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000605a:	6794                	ld	a3,8(a5)
    8000605c:	0026d703          	lhu	a4,2(a3)
    80006060:	8b1d                	andi	a4,a4,7
    80006062:	2709                	addiw	a4,a4,2
    80006064:	0706                	slli	a4,a4,0x1
    80006066:	9736                	add	a4,a4,a3
    80006068:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000606c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006070:	6798                	ld	a4,8(a5)
    80006072:	00275783          	lhu	a5,2(a4)
    80006076:	2785                	addiw	a5,a5,1
    80006078:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000607c:	100017b7          	lui	a5,0x10001
    80006080:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006084:	00492703          	lw	a4,4(s2)
    80006088:	4785                	li	a5,1
    8000608a:	02f71163          	bne	a4,a5,800060ac <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000608e:	0001f997          	auipc	s3,0x1f
    80006092:	01a98993          	addi	s3,s3,26 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006096:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006098:	85ce                	mv	a1,s3
    8000609a:	854a                	mv	a0,s2
    8000609c:	ffffc097          	auipc	ra,0xffffc
    800060a0:	156080e7          	jalr	342(ra) # 800021f2 <sleep>
  while(b->disk == 1) {
    800060a4:	00492783          	lw	a5,4(s2)
    800060a8:	fe9788e3          	beq	a5,s1,80006098 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800060ac:	f9042483          	lw	s1,-112(s0)
    800060b0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800060b4:	00479713          	slli	a4,a5,0x4
    800060b8:	0001d797          	auipc	a5,0x1d
    800060bc:	f4878793          	addi	a5,a5,-184 # 80023000 <disk>
    800060c0:	97ba                	add	a5,a5,a4
    800060c2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060c6:	0001f917          	auipc	s2,0x1f
    800060ca:	f3a90913          	addi	s2,s2,-198 # 80025000 <disk+0x2000>
    free_desc(i);
    800060ce:	8526                	mv	a0,s1
    800060d0:	00000097          	auipc	ra,0x0
    800060d4:	bf6080e7          	jalr	-1034(ra) # 80005cc6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800060d8:	0492                	slli	s1,s1,0x4
    800060da:	00093783          	ld	a5,0(s2)
    800060de:	94be                	add	s1,s1,a5
    800060e0:	00c4d783          	lhu	a5,12(s1)
    800060e4:	8b85                	andi	a5,a5,1
    800060e6:	cf89                	beqz	a5,80006100 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800060e8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800060ec:	b7cd                	j	800060ce <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800060ee:	0001f797          	auipc	a5,0x1f
    800060f2:	f127b783          	ld	a5,-238(a5) # 80025000 <disk+0x2000>
    800060f6:	97ba                	add	a5,a5,a4
    800060f8:	4689                	li	a3,2
    800060fa:	00d79623          	sh	a3,12(a5)
    800060fe:	b5fd                	j	80005fec <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006100:	0001f517          	auipc	a0,0x1f
    80006104:	fa850513          	addi	a0,a0,-88 # 800250a8 <disk+0x20a8>
    80006108:	ffffb097          	auipc	ra,0xffffb
    8000610c:	bbc080e7          	jalr	-1092(ra) # 80000cc4 <release>
}
    80006110:	70e6                	ld	ra,120(sp)
    80006112:	7446                	ld	s0,112(sp)
    80006114:	74a6                	ld	s1,104(sp)
    80006116:	7906                	ld	s2,96(sp)
    80006118:	69e6                	ld	s3,88(sp)
    8000611a:	6a46                	ld	s4,80(sp)
    8000611c:	6aa6                	ld	s5,72(sp)
    8000611e:	6b06                	ld	s6,64(sp)
    80006120:	7be2                	ld	s7,56(sp)
    80006122:	7c42                	ld	s8,48(sp)
    80006124:	7ca2                	ld	s9,40(sp)
    80006126:	7d02                	ld	s10,32(sp)
    80006128:	6109                	addi	sp,sp,128
    8000612a:	8082                	ret
  if(write)
    8000612c:	e20d1ee3          	bnez	s10,80005f68 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006130:	f8042023          	sw	zero,-128(s0)
    80006134:	bd2d                	j	80005f6e <virtio_disk_rw+0xe2>

0000000080006136 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006136:	1101                	addi	sp,sp,-32
    80006138:	ec06                	sd	ra,24(sp)
    8000613a:	e822                	sd	s0,16(sp)
    8000613c:	e426                	sd	s1,8(sp)
    8000613e:	e04a                	sd	s2,0(sp)
    80006140:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006142:	0001f517          	auipc	a0,0x1f
    80006146:	f6650513          	addi	a0,a0,-154 # 800250a8 <disk+0x20a8>
    8000614a:	ffffb097          	auipc	ra,0xffffb
    8000614e:	ac6080e7          	jalr	-1338(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006152:	0001f717          	auipc	a4,0x1f
    80006156:	eae70713          	addi	a4,a4,-338 # 80025000 <disk+0x2000>
    8000615a:	02075783          	lhu	a5,32(a4)
    8000615e:	6b18                	ld	a4,16(a4)
    80006160:	00275683          	lhu	a3,2(a4)
    80006164:	8ebd                	xor	a3,a3,a5
    80006166:	8a9d                	andi	a3,a3,7
    80006168:	cab9                	beqz	a3,800061be <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000616a:	0001d917          	auipc	s2,0x1d
    8000616e:	e9690913          	addi	s2,s2,-362 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006172:	0001f497          	auipc	s1,0x1f
    80006176:	e8e48493          	addi	s1,s1,-370 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000617a:	078e                	slli	a5,a5,0x3
    8000617c:	97ba                	add	a5,a5,a4
    8000617e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006180:	20078713          	addi	a4,a5,512
    80006184:	0712                	slli	a4,a4,0x4
    80006186:	974a                	add	a4,a4,s2
    80006188:	03074703          	lbu	a4,48(a4)
    8000618c:	ef21                	bnez	a4,800061e4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000618e:	20078793          	addi	a5,a5,512
    80006192:	0792                	slli	a5,a5,0x4
    80006194:	97ca                	add	a5,a5,s2
    80006196:	7798                	ld	a4,40(a5)
    80006198:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000619c:	7788                	ld	a0,40(a5)
    8000619e:	ffffc097          	auipc	ra,0xffffc
    800061a2:	1da080e7          	jalr	474(ra) # 80002378 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061a6:	0204d783          	lhu	a5,32(s1)
    800061aa:	2785                	addiw	a5,a5,1
    800061ac:	8b9d                	andi	a5,a5,7
    800061ae:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061b2:	6898                	ld	a4,16(s1)
    800061b4:	00275683          	lhu	a3,2(a4)
    800061b8:	8a9d                	andi	a3,a3,7
    800061ba:	fcf690e3          	bne	a3,a5,8000617a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061be:	10001737          	lui	a4,0x10001
    800061c2:	533c                	lw	a5,96(a4)
    800061c4:	8b8d                	andi	a5,a5,3
    800061c6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800061c8:	0001f517          	auipc	a0,0x1f
    800061cc:	ee050513          	addi	a0,a0,-288 # 800250a8 <disk+0x20a8>
    800061d0:	ffffb097          	auipc	ra,0xffffb
    800061d4:	af4080e7          	jalr	-1292(ra) # 80000cc4 <release>
}
    800061d8:	60e2                	ld	ra,24(sp)
    800061da:	6442                	ld	s0,16(sp)
    800061dc:	64a2                	ld	s1,8(sp)
    800061de:	6902                	ld	s2,0(sp)
    800061e0:	6105                	addi	sp,sp,32
    800061e2:	8082                	ret
      panic("virtio_disk_intr status");
    800061e4:	00002517          	auipc	a0,0x2
    800061e8:	78c50513          	addi	a0,a0,1932 # 80008970 <syscalls_name+0x3d0>
    800061ec:	ffffa097          	auipc	ra,0xffffa
    800061f0:	35c080e7          	jalr	860(ra) # 80000548 <panic>
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
