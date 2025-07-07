
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8d013103          	ld	sp,-1840(sp) # 800088d0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000060:	c5478793          	addi	a5,a5,-940 # 80005cb0 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
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
    8000012a:	47c080e7          	jalr	1148(ra) # 800025a2 <either_copyin>
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
    800001d2:	910080e7          	jalr	-1776(ra) # 80001ade <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	10c080e7          	jalr	268(ra) # 800022ea <sleep>
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
    8000021e:	332080e7          	jalr	818(ra) # 8000254c <either_copyout>
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
    80000300:	2fc080e7          	jalr	764(ra) # 800025f8 <procdump>
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
    80000454:	020080e7          	jalr	32(ra) # 80002470 <wakeup>
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
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
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
    800008ba:	bba080e7          	jalr	-1094(ra) # 80002470 <wakeup>
    
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
    80000954:	99a080e7          	jalr	-1638(ra) # 800022ea <sleep>
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
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
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
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
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
    80000bae:	f18080e7          	jalr	-232(ra) # 80001ac2 <mycpu>
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
    80000be0:	ee6080e7          	jalr	-282(ra) # 80001ac2 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	eda080e7          	jalr	-294(ra) # 80001ac2 <mycpu>
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
    80000c04:	ec2080e7          	jalr	-318(ra) # 80001ac2 <mycpu>
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
    80000c44:	e82080e7          	jalr	-382(ra) # 80001ac2 <mycpu>
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
    80000c70:	e56080e7          	jalr	-426(ra) # 80001ac2 <mycpu>
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
    80000eca:	bec080e7          	jalr	-1044(ra) # 80001ab2 <cpuid>
#endif    
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
    80000ee6:	bd0080e7          	jalr	-1072(ra) # 80001ab2 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0e0080e7          	jalr	224(ra) # 80000fdc <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	834080e7          	jalr	-1996(ra) # 80002738 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	de4080e7          	jalr	-540(ra) # 80005cf0 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	0fa080e7          	jalr	250(ra) # 8000200e <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    statsinit();
    80000f24:	00005097          	auipc	ra,0x5
    80000f28:	58e080e7          	jalr	1422(ra) # 800064b2 <statsinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	84c080e7          	jalr	-1972(ra) # 80000778 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	19450513          	addi	a0,a0,404 # 800080c8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	656080e7          	jalr	1622(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	15c50513          	addi	a0,a0,348 # 800080a0 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	646080e7          	jalr	1606(ra) # 80000592 <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	17450513          	addi	a0,a0,372 # 800080c8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	636080e7          	jalr	1590(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b80080e7          	jalr	-1152(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	2a0080e7          	jalr	672(ra) # 8000120c <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	068080e7          	jalr	104(ra) # 80000fdc <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	a66080e7          	jalr	-1434(ra) # 800019e2 <procinit>
    trapinit();      // trap vectors
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	78c080e7          	jalr	1932(ra) # 80002710 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	7ac080e7          	jalr	1964(ra) # 80002738 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	d46080e7          	jalr	-698(ra) # 80005cda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	d54080e7          	jalr	-684(ra) # 80005cf0 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	ed6080e7          	jalr	-298(ra) # 80002e7a <binit>
    iinit();         // inode cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	566080e7          	jalr	1382(ra) # 80003512 <iinit>
    fileinit();      // file table
    80000fb4:	00003097          	auipc	ra,0x3
    80000fb8:	500080e7          	jalr	1280(ra) # 800044b4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	e3c080e7          	jalr	-452(ra) # 80005df8 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	de4080e7          	jalr	-540(ra) # 80001da8 <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fdc:	1141                	addi	sp,sp,-16
    80000fde:	e422                	sd	s0,8(sp)
    80000fe0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	02e7b783          	ld	a5,46(a5) # 80009010 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0aa50513          	addi	a0,a0,170 # 800080d0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	51a080e7          	jalr	1306(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	ae6080e7          	jalr	-1306(ra) # 80000b20 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cc2080e7          	jalr	-830(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a6:	57fd                	li	a5,-1
    800010a8:	83e9                	srli	a5,a5,0x1a
    800010aa:	00b7f463          	bgeu	a5,a1,800010b2 <walkaddr+0xc>
    return 0;
    800010ae:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b0:	8082                	ret
{
    800010b2:	1141                	addi	sp,sp,-16
    800010b4:	e406                	sd	ra,8(sp)
    800010b6:	e022                	sd	s0,0(sp)
    800010b8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ba:	4601                	li	a2,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	f44080e7          	jalr	-188(ra) # 80001000 <walk>
  if(pte == 0)
    800010c4:	c105                	beqz	a0,800010e4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c8:	0117f693          	andi	a3,a5,17
    800010cc:	4745                	li	a4,17
    return 0;
    800010ce:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d0:	00e68663          	beq	a3,a4,800010dc <walkaddr+0x36>
}
    800010d4:	60a2                	ld	ra,8(sp)
    800010d6:	6402                	ld	s0,0(sp)
    800010d8:	0141                	addi	sp,sp,16
    800010da:	8082                	ret
  pa = PTE2PA(*pte);
    800010dc:	00a7d513          	srli	a0,a5,0xa
    800010e0:	0532                	slli	a0,a0,0xc
  return pa;
    800010e2:	bfcd                	j	800010d4 <walkaddr+0x2e>
    return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7fd                	j	800010d4 <walkaddr+0x2e>

00000000800010e8 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e8:	1101                	addi	sp,sp,-32
    800010ea:	ec06                	sd	ra,24(sp)
    800010ec:	e822                	sd	s0,16(sp)
    800010ee:	e426                	sd	s1,8(sp)
    800010f0:	1000                	addi	s0,sp,32
    800010f2:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010f4:	1552                	slli	a0,a0,0x34
    800010f6:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010fa:	4601                	li	a2,0
    800010fc:	00008517          	auipc	a0,0x8
    80001100:	f1453503          	ld	a0,-236(a0) # 80009010 <kernel_pagetable>
    80001104:	00000097          	auipc	ra,0x0
    80001108:	efc080e7          	jalr	-260(ra) # 80001000 <walk>
  if(pte == 0)
    8000110c:	cd09                	beqz	a0,80001126 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000110e:	6108                	ld	a0,0(a0)
    80001110:	00157793          	andi	a5,a0,1
    80001114:	c38d                	beqz	a5,80001136 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001116:	8129                	srli	a0,a0,0xa
    80001118:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000111a:	9526                	add	a0,a0,s1
    8000111c:	60e2                	ld	ra,24(sp)
    8000111e:	6442                	ld	s0,16(sp)
    80001120:	64a2                	ld	s1,8(sp)
    80001122:	6105                	addi	sp,sp,32
    80001124:	8082                	ret
    panic("kvmpa");
    80001126:	00007517          	auipc	a0,0x7
    8000112a:	fb250513          	addi	a0,a0,-78 # 800080d8 <digits+0x98>
    8000112e:	fffff097          	auipc	ra,0xfffff
    80001132:	41a080e7          	jalr	1050(ra) # 80000548 <panic>
    panic("kvmpa");
    80001136:	00007517          	auipc	a0,0x7
    8000113a:	fa250513          	addi	a0,a0,-94 # 800080d8 <digits+0x98>
    8000113e:	fffff097          	auipc	ra,0xfffff
    80001142:	40a080e7          	jalr	1034(ra) # 80000548 <panic>

0000000080001146 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001146:	715d                	addi	sp,sp,-80
    80001148:	e486                	sd	ra,72(sp)
    8000114a:	e0a2                	sd	s0,64(sp)
    8000114c:	fc26                	sd	s1,56(sp)
    8000114e:	f84a                	sd	s2,48(sp)
    80001150:	f44e                	sd	s3,40(sp)
    80001152:	f052                	sd	s4,32(sp)
    80001154:	ec56                	sd	s5,24(sp)
    80001156:	e85a                	sd	s6,16(sp)
    80001158:	e45e                	sd	s7,8(sp)
    8000115a:	0880                	addi	s0,sp,80
    8000115c:	8aaa                	mv	s5,a0
    8000115e:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001160:	777d                	lui	a4,0xfffff
    80001162:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001166:	167d                	addi	a2,a2,-1
    80001168:	00b609b3          	add	s3,a2,a1
    8000116c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001170:	893e                	mv	s2,a5
    80001172:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001176:	6b85                	lui	s7,0x1
    80001178:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000117c:	4605                	li	a2,1
    8000117e:	85ca                	mv	a1,s2
    80001180:	8556                	mv	a0,s5
    80001182:	00000097          	auipc	ra,0x0
    80001186:	e7e080e7          	jalr	-386(ra) # 80001000 <walk>
    8000118a:	c51d                	beqz	a0,800011b8 <mappages+0x72>
    if(*pte & PTE_V)
    8000118c:	611c                	ld	a5,0(a0)
    8000118e:	8b85                	andi	a5,a5,1
    80001190:	ef81                	bnez	a5,800011a8 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001192:	80b1                	srli	s1,s1,0xc
    80001194:	04aa                	slli	s1,s1,0xa
    80001196:	0164e4b3          	or	s1,s1,s6
    8000119a:	0014e493          	ori	s1,s1,1
    8000119e:	e104                	sd	s1,0(a0)
    if(a == last)
    800011a0:	03390863          	beq	s2,s3,800011d0 <mappages+0x8a>
    a += PGSIZE;
    800011a4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011a6:	bfc9                	j	80001178 <mappages+0x32>
      panic("remap");
    800011a8:	00007517          	auipc	a0,0x7
    800011ac:	f3850513          	addi	a0,a0,-200 # 800080e0 <digits+0xa0>
    800011b0:	fffff097          	auipc	ra,0xfffff
    800011b4:	398080e7          	jalr	920(ra) # 80000548 <panic>
      return -1;
    800011b8:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011ba:	60a6                	ld	ra,72(sp)
    800011bc:	6406                	ld	s0,64(sp)
    800011be:	74e2                	ld	s1,56(sp)
    800011c0:	7942                	ld	s2,48(sp)
    800011c2:	79a2                	ld	s3,40(sp)
    800011c4:	7a02                	ld	s4,32(sp)
    800011c6:	6ae2                	ld	s5,24(sp)
    800011c8:	6b42                	ld	s6,16(sp)
    800011ca:	6ba2                	ld	s7,8(sp)
    800011cc:	6161                	addi	sp,sp,80
    800011ce:	8082                	ret
  return 0;
    800011d0:	4501                	li	a0,0
    800011d2:	b7e5                	j	800011ba <mappages+0x74>

00000000800011d4 <kvmmap>:
{
    800011d4:	1141                	addi	sp,sp,-16
    800011d6:	e406                	sd	ra,8(sp)
    800011d8:	e022                	sd	s0,0(sp)
    800011da:	0800                	addi	s0,sp,16
    800011dc:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011de:	86ae                	mv	a3,a1
    800011e0:	85aa                	mv	a1,a0
    800011e2:	00008517          	auipc	a0,0x8
    800011e6:	e2e53503          	ld	a0,-466(a0) # 80009010 <kernel_pagetable>
    800011ea:	00000097          	auipc	ra,0x0
    800011ee:	f5c080e7          	jalr	-164(ra) # 80001146 <mappages>
    800011f2:	e509                	bnez	a0,800011fc <kvmmap+0x28>
}
    800011f4:	60a2                	ld	ra,8(sp)
    800011f6:	6402                	ld	s0,0(sp)
    800011f8:	0141                	addi	sp,sp,16
    800011fa:	8082                	ret
    panic("kvmmap");
    800011fc:	00007517          	auipc	a0,0x7
    80001200:	eec50513          	addi	a0,a0,-276 # 800080e8 <digits+0xa8>
    80001204:	fffff097          	auipc	ra,0xfffff
    80001208:	344080e7          	jalr	836(ra) # 80000548 <panic>

000000008000120c <kvminit>:
{
    8000120c:	1101                	addi	sp,sp,-32
    8000120e:	ec06                	sd	ra,24(sp)
    80001210:	e822                	sd	s0,16(sp)
    80001212:	e426                	sd	s1,8(sp)
    80001214:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	90a080e7          	jalr	-1782(ra) # 80000b20 <kalloc>
    8000121e:	00008797          	auipc	a5,0x8
    80001222:	dea7b923          	sd	a0,-526(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001226:	6605                	lui	a2,0x1
    80001228:	4581                	li	a1,0
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	ae2080e7          	jalr	-1310(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001232:	4699                	li	a3,6
    80001234:	6605                	lui	a2,0x1
    80001236:	100005b7          	lui	a1,0x10000
    8000123a:	10000537          	lui	a0,0x10000
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f96080e7          	jalr	-106(ra) # 800011d4 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001246:	4699                	li	a3,6
    80001248:	6605                	lui	a2,0x1
    8000124a:	100015b7          	lui	a1,0x10001
    8000124e:	10001537          	lui	a0,0x10001
    80001252:	00000097          	auipc	ra,0x0
    80001256:	f82080e7          	jalr	-126(ra) # 800011d4 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000125a:	4699                	li	a3,6
    8000125c:	6641                	lui	a2,0x10
    8000125e:	020005b7          	lui	a1,0x2000
    80001262:	02000537          	lui	a0,0x2000
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f6e080e7          	jalr	-146(ra) # 800011d4 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000126e:	4699                	li	a3,6
    80001270:	00400637          	lui	a2,0x400
    80001274:	0c0005b7          	lui	a1,0xc000
    80001278:	0c000537          	lui	a0,0xc000
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	f58080e7          	jalr	-168(ra) # 800011d4 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001284:	00007497          	auipc	s1,0x7
    80001288:	d7c48493          	addi	s1,s1,-644 # 80008000 <etext>
    8000128c:	46a9                	li	a3,10
    8000128e:	80007617          	auipc	a2,0x80007
    80001292:	d7260613          	addi	a2,a2,-654 # 8000 <_entry-0x7fff8000>
    80001296:	4585                	li	a1,1
    80001298:	05fe                	slli	a1,a1,0x1f
    8000129a:	852e                	mv	a0,a1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f38080e7          	jalr	-200(ra) # 800011d4 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012a4:	4699                	li	a3,6
    800012a6:	4645                	li	a2,17
    800012a8:	066e                	slli	a2,a2,0x1b
    800012aa:	8e05                	sub	a2,a2,s1
    800012ac:	85a6                	mv	a1,s1
    800012ae:	8526                	mv	a0,s1
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f24080e7          	jalr	-220(ra) # 800011d4 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012b8:	46a9                	li	a3,10
    800012ba:	6605                	lui	a2,0x1
    800012bc:	00006597          	auipc	a1,0x6
    800012c0:	d4458593          	addi	a1,a1,-700 # 80007000 <_trampoline>
    800012c4:	04000537          	lui	a0,0x4000
    800012c8:	157d                	addi	a0,a0,-1
    800012ca:	0532                	slli	a0,a0,0xc
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	f08080e7          	jalr	-248(ra) # 800011d4 <kvmmap>
}
    800012d4:	60e2                	ld	ra,24(sp)
    800012d6:	6442                	ld	s0,16(sp)
    800012d8:	64a2                	ld	s1,8(sp)
    800012da:	6105                	addi	sp,sp,32
    800012dc:	8082                	ret

00000000800012de <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012de:	715d                	addi	sp,sp,-80
    800012e0:	e486                	sd	ra,72(sp)
    800012e2:	e0a2                	sd	s0,64(sp)
    800012e4:	fc26                	sd	s1,56(sp)
    800012e6:	f84a                	sd	s2,48(sp)
    800012e8:	f44e                	sd	s3,40(sp)
    800012ea:	f052                	sd	s4,32(sp)
    800012ec:	ec56                	sd	s5,24(sp)
    800012ee:	e85a                	sd	s6,16(sp)
    800012f0:	e45e                	sd	s7,8(sp)
    800012f2:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f4:	03459793          	slli	a5,a1,0x34
    800012f8:	e795                	bnez	a5,80001324 <uvmunmap+0x46>
    800012fa:	8a2a                	mv	s4,a0
    800012fc:	892e                	mv	s2,a1
    800012fe:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001300:	0632                	slli	a2,a2,0xc
    80001302:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001306:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001308:	6b05                	lui	s6,0x1
    8000130a:	0735e863          	bltu	a1,s3,8000137a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000130e:	60a6                	ld	ra,72(sp)
    80001310:	6406                	ld	s0,64(sp)
    80001312:	74e2                	ld	s1,56(sp)
    80001314:	7942                	ld	s2,48(sp)
    80001316:	79a2                	ld	s3,40(sp)
    80001318:	7a02                	ld	s4,32(sp)
    8000131a:	6ae2                	ld	s5,24(sp)
    8000131c:	6b42                	ld	s6,16(sp)
    8000131e:	6ba2                	ld	s7,8(sp)
    80001320:	6161                	addi	sp,sp,80
    80001322:	8082                	ret
    panic("uvmunmap: not aligned");
    80001324:	00007517          	auipc	a0,0x7
    80001328:	dcc50513          	addi	a0,a0,-564 # 800080f0 <digits+0xb0>
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	21c080e7          	jalr	540(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001334:	00007517          	auipc	a0,0x7
    80001338:	dd450513          	addi	a0,a0,-556 # 80008108 <digits+0xc8>
    8000133c:	fffff097          	auipc	ra,0xfffff
    80001340:	20c080e7          	jalr	524(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001344:	00007517          	auipc	a0,0x7
    80001348:	dd450513          	addi	a0,a0,-556 # 80008118 <digits+0xd8>
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	1fc080e7          	jalr	508(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001354:	00007517          	auipc	a0,0x7
    80001358:	ddc50513          	addi	a0,a0,-548 # 80008130 <digits+0xf0>
    8000135c:	fffff097          	auipc	ra,0xfffff
    80001360:	1ec080e7          	jalr	492(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    80001364:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001366:	0532                	slli	a0,a0,0xc
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	6bc080e7          	jalr	1724(ra) # 80000a24 <kfree>
    *pte = 0;
    80001370:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001374:	995a                	add	s2,s2,s6
    80001376:	f9397ce3          	bgeu	s2,s3,8000130e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000137a:	4601                	li	a2,0
    8000137c:	85ca                	mv	a1,s2
    8000137e:	8552                	mv	a0,s4
    80001380:	00000097          	auipc	ra,0x0
    80001384:	c80080e7          	jalr	-896(ra) # 80001000 <walk>
    80001388:	84aa                	mv	s1,a0
    8000138a:	d54d                	beqz	a0,80001334 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000138c:	6108                	ld	a0,0(a0)
    8000138e:	00157793          	andi	a5,a0,1
    80001392:	dbcd                	beqz	a5,80001344 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001394:	3ff57793          	andi	a5,a0,1023
    80001398:	fb778ee3          	beq	a5,s7,80001354 <uvmunmap+0x76>
    if(do_free){
    8000139c:	fc0a8ae3          	beqz	s5,80001370 <uvmunmap+0x92>
    800013a0:	b7d1                	j	80001364 <uvmunmap+0x86>

00000000800013a2 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a2:	1101                	addi	sp,sp,-32
    800013a4:	ec06                	sd	ra,24(sp)
    800013a6:	e822                	sd	s0,16(sp)
    800013a8:	e426                	sd	s1,8(sp)
    800013aa:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ac:	fffff097          	auipc	ra,0xfffff
    800013b0:	774080e7          	jalr	1908(ra) # 80000b20 <kalloc>
    800013b4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013b6:	c519                	beqz	a0,800013c4 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b8:	6605                	lui	a2,0x1
    800013ba:	4581                	li	a1,0
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	950080e7          	jalr	-1712(ra) # 80000d0c <memset>
  return pagetable;
}
    800013c4:	8526                	mv	a0,s1
    800013c6:	60e2                	ld	ra,24(sp)
    800013c8:	6442                	ld	s0,16(sp)
    800013ca:	64a2                	ld	s1,8(sp)
    800013cc:	6105                	addi	sp,sp,32
    800013ce:	8082                	ret

00000000800013d0 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013d0:	7179                	addi	sp,sp,-48
    800013d2:	f406                	sd	ra,40(sp)
    800013d4:	f022                	sd	s0,32(sp)
    800013d6:	ec26                	sd	s1,24(sp)
    800013d8:	e84a                	sd	s2,16(sp)
    800013da:	e44e                	sd	s3,8(sp)
    800013dc:	e052                	sd	s4,0(sp)
    800013de:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013e0:	6785                	lui	a5,0x1
    800013e2:	04f67863          	bgeu	a2,a5,80001432 <uvminit+0x62>
    800013e6:	8a2a                	mv	s4,a0
    800013e8:	89ae                	mv	s3,a1
    800013ea:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013ec:	fffff097          	auipc	ra,0xfffff
    800013f0:	734080e7          	jalr	1844(ra) # 80000b20 <kalloc>
    800013f4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013f6:	6605                	lui	a2,0x1
    800013f8:	4581                	li	a1,0
    800013fa:	00000097          	auipc	ra,0x0
    800013fe:	912080e7          	jalr	-1774(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001402:	4779                	li	a4,30
    80001404:	86ca                	mv	a3,s2
    80001406:	6605                	lui	a2,0x1
    80001408:	4581                	li	a1,0
    8000140a:	8552                	mv	a0,s4
    8000140c:	00000097          	auipc	ra,0x0
    80001410:	d3a080e7          	jalr	-710(ra) # 80001146 <mappages>
  memmove(mem, src, sz);
    80001414:	8626                	mv	a2,s1
    80001416:	85ce                	mv	a1,s3
    80001418:	854a                	mv	a0,s2
    8000141a:	00000097          	auipc	ra,0x0
    8000141e:	952080e7          	jalr	-1710(ra) # 80000d6c <memmove>
}
    80001422:	70a2                	ld	ra,40(sp)
    80001424:	7402                	ld	s0,32(sp)
    80001426:	64e2                	ld	s1,24(sp)
    80001428:	6942                	ld	s2,16(sp)
    8000142a:	69a2                	ld	s3,8(sp)
    8000142c:	6a02                	ld	s4,0(sp)
    8000142e:	6145                	addi	sp,sp,48
    80001430:	8082                	ret
    panic("inituvm: more than a page");
    80001432:	00007517          	auipc	a0,0x7
    80001436:	d1650513          	addi	a0,a0,-746 # 80008148 <digits+0x108>
    8000143a:	fffff097          	auipc	ra,0xfffff
    8000143e:	10e080e7          	jalr	270(ra) # 80000548 <panic>

0000000080001442 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001442:	1101                	addi	sp,sp,-32
    80001444:	ec06                	sd	ra,24(sp)
    80001446:	e822                	sd	s0,16(sp)
    80001448:	e426                	sd	s1,8(sp)
    8000144a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000144c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000144e:	00b67d63          	bgeu	a2,a1,80001468 <uvmdealloc+0x26>
    80001452:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001454:	6785                	lui	a5,0x1
    80001456:	17fd                	addi	a5,a5,-1
    80001458:	00f60733          	add	a4,a2,a5
    8000145c:	767d                	lui	a2,0xfffff
    8000145e:	8f71                	and	a4,a4,a2
    80001460:	97ae                	add	a5,a5,a1
    80001462:	8ff1                	and	a5,a5,a2
    80001464:	00f76863          	bltu	a4,a5,80001474 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001468:	8526                	mv	a0,s1
    8000146a:	60e2                	ld	ra,24(sp)
    8000146c:	6442                	ld	s0,16(sp)
    8000146e:	64a2                	ld	s1,8(sp)
    80001470:	6105                	addi	sp,sp,32
    80001472:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001474:	8f99                	sub	a5,a5,a4
    80001476:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001478:	4685                	li	a3,1
    8000147a:	0007861b          	sext.w	a2,a5
    8000147e:	85ba                	mv	a1,a4
    80001480:	00000097          	auipc	ra,0x0
    80001484:	e5e080e7          	jalr	-418(ra) # 800012de <uvmunmap>
    80001488:	b7c5                	j	80001468 <uvmdealloc+0x26>

000000008000148a <uvmalloc>:
  if(newsz < oldsz)
    8000148a:	0ab66163          	bltu	a2,a1,8000152c <uvmalloc+0xa2>
{
    8000148e:	7139                	addi	sp,sp,-64
    80001490:	fc06                	sd	ra,56(sp)
    80001492:	f822                	sd	s0,48(sp)
    80001494:	f426                	sd	s1,40(sp)
    80001496:	f04a                	sd	s2,32(sp)
    80001498:	ec4e                	sd	s3,24(sp)
    8000149a:	e852                	sd	s4,16(sp)
    8000149c:	e456                	sd	s5,8(sp)
    8000149e:	0080                	addi	s0,sp,64
    800014a0:	8aaa                	mv	s5,a0
    800014a2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014a4:	6985                	lui	s3,0x1
    800014a6:	19fd                	addi	s3,s3,-1
    800014a8:	95ce                	add	a1,a1,s3
    800014aa:	79fd                	lui	s3,0xfffff
    800014ac:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b0:	08c9f063          	bgeu	s3,a2,80001530 <uvmalloc+0xa6>
    800014b4:	894e                	mv	s2,s3
    mem = kalloc();
    800014b6:	fffff097          	auipc	ra,0xfffff
    800014ba:	66a080e7          	jalr	1642(ra) # 80000b20 <kalloc>
    800014be:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c0:	c51d                	beqz	a0,800014ee <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014c2:	6605                	lui	a2,0x1
    800014c4:	4581                	li	a1,0
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	846080e7          	jalr	-1978(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014ce:	4779                	li	a4,30
    800014d0:	86a6                	mv	a3,s1
    800014d2:	6605                	lui	a2,0x1
    800014d4:	85ca                	mv	a1,s2
    800014d6:	8556                	mv	a0,s5
    800014d8:	00000097          	auipc	ra,0x0
    800014dc:	c6e080e7          	jalr	-914(ra) # 80001146 <mappages>
    800014e0:	e905                	bnez	a0,80001510 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e2:	6785                	lui	a5,0x1
    800014e4:	993e                	add	s2,s2,a5
    800014e6:	fd4968e3          	bltu	s2,s4,800014b6 <uvmalloc+0x2c>
  return newsz;
    800014ea:	8552                	mv	a0,s4
    800014ec:	a809                	j	800014fe <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014ee:	864e                	mv	a2,s3
    800014f0:	85ca                	mv	a1,s2
    800014f2:	8556                	mv	a0,s5
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	f4e080e7          	jalr	-178(ra) # 80001442 <uvmdealloc>
      return 0;
    800014fc:	4501                	li	a0,0
}
    800014fe:	70e2                	ld	ra,56(sp)
    80001500:	7442                	ld	s0,48(sp)
    80001502:	74a2                	ld	s1,40(sp)
    80001504:	7902                	ld	s2,32(sp)
    80001506:	69e2                	ld	s3,24(sp)
    80001508:	6a42                	ld	s4,16(sp)
    8000150a:	6aa2                	ld	s5,8(sp)
    8000150c:	6121                	addi	sp,sp,64
    8000150e:	8082                	ret
      kfree(mem);
    80001510:	8526                	mv	a0,s1
    80001512:	fffff097          	auipc	ra,0xfffff
    80001516:	512080e7          	jalr	1298(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000151a:	864e                	mv	a2,s3
    8000151c:	85ca                	mv	a1,s2
    8000151e:	8556                	mv	a0,s5
    80001520:	00000097          	auipc	ra,0x0
    80001524:	f22080e7          	jalr	-222(ra) # 80001442 <uvmdealloc>
      return 0;
    80001528:	4501                	li	a0,0
    8000152a:	bfd1                	j	800014fe <uvmalloc+0x74>
    return oldsz;
    8000152c:	852e                	mv	a0,a1
}
    8000152e:	8082                	ret
  return newsz;
    80001530:	8532                	mv	a0,a2
    80001532:	b7f1                	j	800014fe <uvmalloc+0x74>

0000000080001534 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001534:	7179                	addi	sp,sp,-48
    80001536:	f406                	sd	ra,40(sp)
    80001538:	f022                	sd	s0,32(sp)
    8000153a:	ec26                	sd	s1,24(sp)
    8000153c:	e84a                	sd	s2,16(sp)
    8000153e:	e44e                	sd	s3,8(sp)
    80001540:	e052                	sd	s4,0(sp)
    80001542:	1800                	addi	s0,sp,48
    80001544:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001546:	84aa                	mv	s1,a0
    80001548:	6905                	lui	s2,0x1
    8000154a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000154c:	4985                	li	s3,1
    8000154e:	a821                	j	80001566 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001550:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001552:	0532                	slli	a0,a0,0xc
    80001554:	00000097          	auipc	ra,0x0
    80001558:	fe0080e7          	jalr	-32(ra) # 80001534 <freewalk>
      pagetable[i] = 0;
    8000155c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001560:	04a1                	addi	s1,s1,8
    80001562:	03248163          	beq	s1,s2,80001584 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001566:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001568:	00f57793          	andi	a5,a0,15
    8000156c:	ff3782e3          	beq	a5,s3,80001550 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001570:	8905                	andi	a0,a0,1
    80001572:	d57d                	beqz	a0,80001560 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001574:	00007517          	auipc	a0,0x7
    80001578:	bf450513          	addi	a0,a0,-1036 # 80008168 <digits+0x128>
    8000157c:	fffff097          	auipc	ra,0xfffff
    80001580:	fcc080e7          	jalr	-52(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    80001584:	8552                	mv	a0,s4
    80001586:	fffff097          	auipc	ra,0xfffff
    8000158a:	49e080e7          	jalr	1182(ra) # 80000a24 <kfree>
}
    8000158e:	70a2                	ld	ra,40(sp)
    80001590:	7402                	ld	s0,32(sp)
    80001592:	64e2                	ld	s1,24(sp)
    80001594:	6942                	ld	s2,16(sp)
    80001596:	69a2                	ld	s3,8(sp)
    80001598:	6a02                	ld	s4,0(sp)
    8000159a:	6145                	addi	sp,sp,48
    8000159c:	8082                	ret

000000008000159e <tableprint>:

void
tableprint(pagetable_t pagetable, int level)
{
    8000159e:	7159                	addi	sp,sp,-112
    800015a0:	f486                	sd	ra,104(sp)
    800015a2:	f0a2                	sd	s0,96(sp)
    800015a4:	eca6                	sd	s1,88(sp)
    800015a6:	e8ca                	sd	s2,80(sp)
    800015a8:	e4ce                	sd	s3,72(sp)
    800015aa:	e0d2                	sd	s4,64(sp)
    800015ac:	fc56                	sd	s5,56(sp)
    800015ae:	f85a                	sd	s6,48(sp)
    800015b0:	f45e                	sd	s7,40(sp)
    800015b2:	f062                	sd	s8,32(sp)
    800015b4:	ec66                	sd	s9,24(sp)
    800015b6:	e86a                	sd	s10,16(sp)
    800015b8:	e46e                	sd	s11,8(sp)
    800015ba:	1880                	addi	s0,sp,112
    800015bc:	8aae                	mv	s5,a1
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015be:	89aa                	mv	s3,a0
    800015c0:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V){ // 表示页表项有效
    // if(pte & PTE_V) {
      // this PTE points to a lower-level page table.
      printf("..");
    800015c2:	00007c97          	auipc	s9,0x7
    800015c6:	bb6c8c93          	addi	s9,s9,-1098 # 80008178 <digits+0x138>
      for(int i = 0;i < level;i++) printf(" ..");
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    800015ca:	00007c17          	auipc	s8,0x7
    800015ce:	bbec0c13          	addi	s8,s8,-1090 # 80008188 <digits+0x148>
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0) { // 表示该节点不是子节点
        uint64 child = PTE2PA(pte);
        tableprint((pagetable_t)child, level + 1);
    800015d2:	00158d9b          	addiw	s11,a1,1
      for(int i = 0;i < level;i++) printf(" ..");
    800015d6:	4d01                	li	s10,0
    800015d8:	00007b17          	auipc	s6,0x7
    800015dc:	ba8b0b13          	addi	s6,s6,-1112 # 80008180 <digits+0x140>
  for(int i = 0; i < 512; i++){
    800015e0:	20000b93          	li	s7,512
    800015e4:	a029                	j	800015ee <tableprint+0x50>
    800015e6:	2905                	addiw	s2,s2,1
    800015e8:	09a1                	addi	s3,s3,8
    800015ea:	05790d63          	beq	s2,s7,80001644 <tableprint+0xa6>
    pte_t pte = pagetable[i];
    800015ee:	0009ba03          	ld	s4,0(s3) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    if(pte & PTE_V){ // 表示页表项有效
    800015f2:	001a7793          	andi	a5,s4,1
    800015f6:	dbe5                	beqz	a5,800015e6 <tableprint+0x48>
      printf("..");
    800015f8:	8566                	mv	a0,s9
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f98080e7          	jalr	-104(ra) # 80000592 <printf>
      for(int i = 0;i < level;i++) printf(" ..");
    80001602:	01505b63          	blez	s5,80001618 <tableprint+0x7a>
    80001606:	84ea                	mv	s1,s10
    80001608:	855a                	mv	a0,s6
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	f88080e7          	jalr	-120(ra) # 80000592 <printf>
    80001612:	2485                	addiw	s1,s1,1
    80001614:	fe9a9ae3          	bne	s5,s1,80001608 <tableprint+0x6a>
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80001618:	00aa5493          	srli	s1,s4,0xa
    8000161c:	04b2                	slli	s1,s1,0xc
    8000161e:	86a6                	mv	a3,s1
    80001620:	8652                	mv	a2,s4
    80001622:	85ca                	mv	a1,s2
    80001624:	8562                	mv	a0,s8
    80001626:	fffff097          	auipc	ra,0xfffff
    8000162a:	f6c080e7          	jalr	-148(ra) # 80000592 <printf>
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0) { // 表示该节点不是子节点
    8000162e:	00ea7a13          	andi	s4,s4,14
    80001632:	fa0a1ae3          	bnez	s4,800015e6 <tableprint+0x48>
        tableprint((pagetable_t)child, level + 1);
    80001636:	85ee                	mv	a1,s11
    80001638:	8526                	mv	a0,s1
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	f64080e7          	jalr	-156(ra) # 8000159e <tableprint>
    80001642:	b755                	j	800015e6 <tableprint+0x48>
      }
      
    } 
  }
}
    80001644:	70a6                	ld	ra,104(sp)
    80001646:	7406                	ld	s0,96(sp)
    80001648:	64e6                	ld	s1,88(sp)
    8000164a:	6946                	ld	s2,80(sp)
    8000164c:	69a6                	ld	s3,72(sp)
    8000164e:	6a06                	ld	s4,64(sp)
    80001650:	7ae2                	ld	s5,56(sp)
    80001652:	7b42                	ld	s6,48(sp)
    80001654:	7ba2                	ld	s7,40(sp)
    80001656:	7c02                	ld	s8,32(sp)
    80001658:	6ce2                	ld	s9,24(sp)
    8000165a:	6d42                	ld	s10,16(sp)
    8000165c:	6da2                	ld	s11,8(sp)
    8000165e:	6165                	addi	sp,sp,112
    80001660:	8082                	ret

0000000080001662 <vmprint>:

void vmprint(pagetable_t pagetable) {
    80001662:	1101                	addi	sp,sp,-32
    80001664:	ec06                	sd	ra,24(sp)
    80001666:	e822                	sd	s0,16(sp)
    80001668:	e426                	sd	s1,8(sp)
    8000166a:	1000                	addi	s0,sp,32
    8000166c:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    8000166e:	85aa                	mv	a1,a0
    80001670:	00007517          	auipc	a0,0x7
    80001674:	b3050513          	addi	a0,a0,-1232 # 800081a0 <digits+0x160>
    80001678:	fffff097          	auipc	ra,0xfffff
    8000167c:	f1a080e7          	jalr	-230(ra) # 80000592 <printf>
  tableprint(pagetable, 0);
    80001680:	4581                	li	a1,0
    80001682:	8526                	mv	a0,s1
    80001684:	00000097          	auipc	ra,0x0
    80001688:	f1a080e7          	jalr	-230(ra) # 8000159e <tableprint>
}
    8000168c:	60e2                	ld	ra,24(sp)
    8000168e:	6442                	ld	s0,16(sp)
    80001690:	64a2                	ld	s1,8(sp)
    80001692:	6105                	addi	sp,sp,32
    80001694:	8082                	ret

0000000080001696 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001696:	1101                	addi	sp,sp,-32
    80001698:	ec06                	sd	ra,24(sp)
    8000169a:	e822                	sd	s0,16(sp)
    8000169c:	e426                	sd	s1,8(sp)
    8000169e:	1000                	addi	s0,sp,32
    800016a0:	84aa                	mv	s1,a0
  if(sz > 0)
    800016a2:	e999                	bnez	a1,800016b8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016a4:	8526                	mv	a0,s1
    800016a6:	00000097          	auipc	ra,0x0
    800016aa:	e8e080e7          	jalr	-370(ra) # 80001534 <freewalk>
}
    800016ae:	60e2                	ld	ra,24(sp)
    800016b0:	6442                	ld	s0,16(sp)
    800016b2:	64a2                	ld	s1,8(sp)
    800016b4:	6105                	addi	sp,sp,32
    800016b6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016b8:	6605                	lui	a2,0x1
    800016ba:	167d                	addi	a2,a2,-1
    800016bc:	962e                	add	a2,a2,a1
    800016be:	4685                	li	a3,1
    800016c0:	8231                	srli	a2,a2,0xc
    800016c2:	4581                	li	a1,0
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	c1a080e7          	jalr	-998(ra) # 800012de <uvmunmap>
    800016cc:	bfe1                	j	800016a4 <uvmfree+0xe>

00000000800016ce <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016ce:	c679                	beqz	a2,8000179c <uvmcopy+0xce>
{
    800016d0:	715d                	addi	sp,sp,-80
    800016d2:	e486                	sd	ra,72(sp)
    800016d4:	e0a2                	sd	s0,64(sp)
    800016d6:	fc26                	sd	s1,56(sp)
    800016d8:	f84a                	sd	s2,48(sp)
    800016da:	f44e                	sd	s3,40(sp)
    800016dc:	f052                	sd	s4,32(sp)
    800016de:	ec56                	sd	s5,24(sp)
    800016e0:	e85a                	sd	s6,16(sp)
    800016e2:	e45e                	sd	s7,8(sp)
    800016e4:	0880                	addi	s0,sp,80
    800016e6:	8b2a                	mv	s6,a0
    800016e8:	8aae                	mv	s5,a1
    800016ea:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016ec:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800016ee:	4601                	li	a2,0
    800016f0:	85ce                	mv	a1,s3
    800016f2:	855a                	mv	a0,s6
    800016f4:	00000097          	auipc	ra,0x0
    800016f8:	90c080e7          	jalr	-1780(ra) # 80001000 <walk>
    800016fc:	c531                	beqz	a0,80001748 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016fe:	6118                	ld	a4,0(a0)
    80001700:	00177793          	andi	a5,a4,1
    80001704:	cbb1                	beqz	a5,80001758 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001706:	00a75593          	srli	a1,a4,0xa
    8000170a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000170e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001712:	fffff097          	auipc	ra,0xfffff
    80001716:	40e080e7          	jalr	1038(ra) # 80000b20 <kalloc>
    8000171a:	892a                	mv	s2,a0
    8000171c:	c939                	beqz	a0,80001772 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000171e:	6605                	lui	a2,0x1
    80001720:	85de                	mv	a1,s7
    80001722:	fffff097          	auipc	ra,0xfffff
    80001726:	64a080e7          	jalr	1610(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000172a:	8726                	mv	a4,s1
    8000172c:	86ca                	mv	a3,s2
    8000172e:	6605                	lui	a2,0x1
    80001730:	85ce                	mv	a1,s3
    80001732:	8556                	mv	a0,s5
    80001734:	00000097          	auipc	ra,0x0
    80001738:	a12080e7          	jalr	-1518(ra) # 80001146 <mappages>
    8000173c:	e515                	bnez	a0,80001768 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000173e:	6785                	lui	a5,0x1
    80001740:	99be                	add	s3,s3,a5
    80001742:	fb49e6e3          	bltu	s3,s4,800016ee <uvmcopy+0x20>
    80001746:	a081                	j	80001786 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001748:	00007517          	auipc	a0,0x7
    8000174c:	a6850513          	addi	a0,a0,-1432 # 800081b0 <digits+0x170>
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	df8080e7          	jalr	-520(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    80001758:	00007517          	auipc	a0,0x7
    8000175c:	a7850513          	addi	a0,a0,-1416 # 800081d0 <digits+0x190>
    80001760:	fffff097          	auipc	ra,0xfffff
    80001764:	de8080e7          	jalr	-536(ra) # 80000548 <panic>
      kfree(mem);
    80001768:	854a                	mv	a0,s2
    8000176a:	fffff097          	auipc	ra,0xfffff
    8000176e:	2ba080e7          	jalr	698(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001772:	4685                	li	a3,1
    80001774:	00c9d613          	srli	a2,s3,0xc
    80001778:	4581                	li	a1,0
    8000177a:	8556                	mv	a0,s5
    8000177c:	00000097          	auipc	ra,0x0
    80001780:	b62080e7          	jalr	-1182(ra) # 800012de <uvmunmap>
  return -1;
    80001784:	557d                	li	a0,-1
}
    80001786:	60a6                	ld	ra,72(sp)
    80001788:	6406                	ld	s0,64(sp)
    8000178a:	74e2                	ld	s1,56(sp)
    8000178c:	7942                	ld	s2,48(sp)
    8000178e:	79a2                	ld	s3,40(sp)
    80001790:	7a02                	ld	s4,32(sp)
    80001792:	6ae2                	ld	s5,24(sp)
    80001794:	6b42                	ld	s6,16(sp)
    80001796:	6ba2                	ld	s7,8(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret
  return 0;
    8000179c:	4501                	li	a0,0
}
    8000179e:	8082                	ret

00000000800017a0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017a0:	1141                	addi	sp,sp,-16
    800017a2:	e406                	sd	ra,8(sp)
    800017a4:	e022                	sd	s0,0(sp)
    800017a6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017a8:	4601                	li	a2,0
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	856080e7          	jalr	-1962(ra) # 80001000 <walk>
  if(pte == 0)
    800017b2:	c901                	beqz	a0,800017c2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017b4:	611c                	ld	a5,0(a0)
    800017b6:	9bbd                	andi	a5,a5,-17
    800017b8:	e11c                	sd	a5,0(a0)
}
    800017ba:	60a2                	ld	ra,8(sp)
    800017bc:	6402                	ld	s0,0(sp)
    800017be:	0141                	addi	sp,sp,16
    800017c0:	8082                	ret
    panic("uvmclear");
    800017c2:	00007517          	auipc	a0,0x7
    800017c6:	a2e50513          	addi	a0,a0,-1490 # 800081f0 <digits+0x1b0>
    800017ca:	fffff097          	auipc	ra,0xfffff
    800017ce:	d7e080e7          	jalr	-642(ra) # 80000548 <panic>

00000000800017d2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017d2:	c6bd                	beqz	a3,80001840 <copyout+0x6e>
{
    800017d4:	715d                	addi	sp,sp,-80
    800017d6:	e486                	sd	ra,72(sp)
    800017d8:	e0a2                	sd	s0,64(sp)
    800017da:	fc26                	sd	s1,56(sp)
    800017dc:	f84a                	sd	s2,48(sp)
    800017de:	f44e                	sd	s3,40(sp)
    800017e0:	f052                	sd	s4,32(sp)
    800017e2:	ec56                	sd	s5,24(sp)
    800017e4:	e85a                	sd	s6,16(sp)
    800017e6:	e45e                	sd	s7,8(sp)
    800017e8:	e062                	sd	s8,0(sp)
    800017ea:	0880                	addi	s0,sp,80
    800017ec:	8b2a                	mv	s6,a0
    800017ee:	8c2e                	mv	s8,a1
    800017f0:	8a32                	mv	s4,a2
    800017f2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017f4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017f6:	6a85                	lui	s5,0x1
    800017f8:	a015                	j	8000181c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017fa:	9562                	add	a0,a0,s8
    800017fc:	0004861b          	sext.w	a2,s1
    80001800:	85d2                	mv	a1,s4
    80001802:	41250533          	sub	a0,a0,s2
    80001806:	fffff097          	auipc	ra,0xfffff
    8000180a:	566080e7          	jalr	1382(ra) # 80000d6c <memmove>

    len -= n;
    8000180e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001812:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001814:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001818:	02098263          	beqz	s3,8000183c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000181c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001820:	85ca                	mv	a1,s2
    80001822:	855a                	mv	a0,s6
    80001824:	00000097          	auipc	ra,0x0
    80001828:	882080e7          	jalr	-1918(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000182c:	cd01                	beqz	a0,80001844 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000182e:	418904b3          	sub	s1,s2,s8
    80001832:	94d6                	add	s1,s1,s5
    if(n > len)
    80001834:	fc99f3e3          	bgeu	s3,s1,800017fa <copyout+0x28>
    80001838:	84ce                	mv	s1,s3
    8000183a:	b7c1                	j	800017fa <copyout+0x28>
  }
  return 0;
    8000183c:	4501                	li	a0,0
    8000183e:	a021                	j	80001846 <copyout+0x74>
    80001840:	4501                	li	a0,0
}
    80001842:	8082                	ret
      return -1;
    80001844:	557d                	li	a0,-1
}
    80001846:	60a6                	ld	ra,72(sp)
    80001848:	6406                	ld	s0,64(sp)
    8000184a:	74e2                	ld	s1,56(sp)
    8000184c:	7942                	ld	s2,48(sp)
    8000184e:	79a2                	ld	s3,40(sp)
    80001850:	7a02                	ld	s4,32(sp)
    80001852:	6ae2                	ld	s5,24(sp)
    80001854:	6b42                	ld	s6,16(sp)
    80001856:	6ba2                	ld	s7,8(sp)
    80001858:	6c02                	ld	s8,0(sp)
    8000185a:	6161                	addi	sp,sp,80
    8000185c:	8082                	ret

000000008000185e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000185e:	c6bd                	beqz	a3,800018cc <copyin+0x6e>
{
    80001860:	715d                	addi	sp,sp,-80
    80001862:	e486                	sd	ra,72(sp)
    80001864:	e0a2                	sd	s0,64(sp)
    80001866:	fc26                	sd	s1,56(sp)
    80001868:	f84a                	sd	s2,48(sp)
    8000186a:	f44e                	sd	s3,40(sp)
    8000186c:	f052                	sd	s4,32(sp)
    8000186e:	ec56                	sd	s5,24(sp)
    80001870:	e85a                	sd	s6,16(sp)
    80001872:	e45e                	sd	s7,8(sp)
    80001874:	e062                	sd	s8,0(sp)
    80001876:	0880                	addi	s0,sp,80
    80001878:	8b2a                	mv	s6,a0
    8000187a:	8a2e                	mv	s4,a1
    8000187c:	8c32                	mv	s8,a2
    8000187e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001880:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001882:	6a85                	lui	s5,0x1
    80001884:	a015                	j	800018a8 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001886:	9562                	add	a0,a0,s8
    80001888:	0004861b          	sext.w	a2,s1
    8000188c:	412505b3          	sub	a1,a0,s2
    80001890:	8552                	mv	a0,s4
    80001892:	fffff097          	auipc	ra,0xfffff
    80001896:	4da080e7          	jalr	1242(ra) # 80000d6c <memmove>

    len -= n;
    8000189a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000189e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800018a0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018a4:	02098263          	beqz	s3,800018c8 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800018a8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018ac:	85ca                	mv	a1,s2
    800018ae:	855a                	mv	a0,s6
    800018b0:	fffff097          	auipc	ra,0xfffff
    800018b4:	7f6080e7          	jalr	2038(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    800018b8:	cd01                	beqz	a0,800018d0 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800018ba:	418904b3          	sub	s1,s2,s8
    800018be:	94d6                	add	s1,s1,s5
    if(n > len)
    800018c0:	fc99f3e3          	bgeu	s3,s1,80001886 <copyin+0x28>
    800018c4:	84ce                	mv	s1,s3
    800018c6:	b7c1                	j	80001886 <copyin+0x28>
  }
  return 0;
    800018c8:	4501                	li	a0,0
    800018ca:	a021                	j	800018d2 <copyin+0x74>
    800018cc:	4501                	li	a0,0
}
    800018ce:	8082                	ret
      return -1;
    800018d0:	557d                	li	a0,-1
}
    800018d2:	60a6                	ld	ra,72(sp)
    800018d4:	6406                	ld	s0,64(sp)
    800018d6:	74e2                	ld	s1,56(sp)
    800018d8:	7942                	ld	s2,48(sp)
    800018da:	79a2                	ld	s3,40(sp)
    800018dc:	7a02                	ld	s4,32(sp)
    800018de:	6ae2                	ld	s5,24(sp)
    800018e0:	6b42                	ld	s6,16(sp)
    800018e2:	6ba2                	ld	s7,8(sp)
    800018e4:	6c02                	ld	s8,0(sp)
    800018e6:	6161                	addi	sp,sp,80
    800018e8:	8082                	ret

00000000800018ea <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018ea:	c6c5                	beqz	a3,80001992 <copyinstr+0xa8>
{
    800018ec:	715d                	addi	sp,sp,-80
    800018ee:	e486                	sd	ra,72(sp)
    800018f0:	e0a2                	sd	s0,64(sp)
    800018f2:	fc26                	sd	s1,56(sp)
    800018f4:	f84a                	sd	s2,48(sp)
    800018f6:	f44e                	sd	s3,40(sp)
    800018f8:	f052                	sd	s4,32(sp)
    800018fa:	ec56                	sd	s5,24(sp)
    800018fc:	e85a                	sd	s6,16(sp)
    800018fe:	e45e                	sd	s7,8(sp)
    80001900:	0880                	addi	s0,sp,80
    80001902:	8a2a                	mv	s4,a0
    80001904:	8b2e                	mv	s6,a1
    80001906:	8bb2                	mv	s7,a2
    80001908:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000190a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000190c:	6985                	lui	s3,0x1
    8000190e:	a035                	j	8000193a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001910:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001914:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001916:	0017b793          	seqz	a5,a5
    8000191a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000191e:	60a6                	ld	ra,72(sp)
    80001920:	6406                	ld	s0,64(sp)
    80001922:	74e2                	ld	s1,56(sp)
    80001924:	7942                	ld	s2,48(sp)
    80001926:	79a2                	ld	s3,40(sp)
    80001928:	7a02                	ld	s4,32(sp)
    8000192a:	6ae2                	ld	s5,24(sp)
    8000192c:	6b42                	ld	s6,16(sp)
    8000192e:	6ba2                	ld	s7,8(sp)
    80001930:	6161                	addi	sp,sp,80
    80001932:	8082                	ret
    srcva = va0 + PGSIZE;
    80001934:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001938:	c8a9                	beqz	s1,8000198a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000193a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000193e:	85ca                	mv	a1,s2
    80001940:	8552                	mv	a0,s4
    80001942:	fffff097          	auipc	ra,0xfffff
    80001946:	764080e7          	jalr	1892(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000194a:	c131                	beqz	a0,8000198e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000194c:	41790833          	sub	a6,s2,s7
    80001950:	984e                	add	a6,a6,s3
    if(n > max)
    80001952:	0104f363          	bgeu	s1,a6,80001958 <copyinstr+0x6e>
    80001956:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001958:	955e                	add	a0,a0,s7
    8000195a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000195e:	fc080be3          	beqz	a6,80001934 <copyinstr+0x4a>
    80001962:	985a                	add	a6,a6,s6
    80001964:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001966:	41650633          	sub	a2,a0,s6
    8000196a:	14fd                	addi	s1,s1,-1
    8000196c:	9b26                	add	s6,s6,s1
    8000196e:	00f60733          	add	a4,a2,a5
    80001972:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    80001976:	df49                	beqz	a4,80001910 <copyinstr+0x26>
        *dst = *p;
    80001978:	00e78023          	sb	a4,0(a5)
      --max;
    8000197c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001980:	0785                	addi	a5,a5,1
    while(n > 0){
    80001982:	ff0796e3          	bne	a5,a6,8000196e <copyinstr+0x84>
      dst++;
    80001986:	8b42                	mv	s6,a6
    80001988:	b775                	j	80001934 <copyinstr+0x4a>
    8000198a:	4781                	li	a5,0
    8000198c:	b769                	j	80001916 <copyinstr+0x2c>
      return -1;
    8000198e:	557d                	li	a0,-1
    80001990:	b779                	j	8000191e <copyinstr+0x34>
  int got_null = 0;
    80001992:	4781                	li	a5,0
  if(got_null){
    80001994:	0017b793          	seqz	a5,a5
    80001998:	40f00533          	neg	a0,a5
}
    8000199c:	8082                	ret

000000008000199e <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000199e:	1101                	addi	sp,sp,-32
    800019a0:	ec06                	sd	ra,24(sp)
    800019a2:	e822                	sd	s0,16(sp)
    800019a4:	e426                	sd	s1,8(sp)
    800019a6:	1000                	addi	s0,sp,32
    800019a8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800019aa:	fffff097          	auipc	ra,0xfffff
    800019ae:	1ec080e7          	jalr	492(ra) # 80000b96 <holding>
    800019b2:	c909                	beqz	a0,800019c4 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800019b4:	749c                	ld	a5,40(s1)
    800019b6:	00978f63          	beq	a5,s1,800019d4 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800019ba:	60e2                	ld	ra,24(sp)
    800019bc:	6442                	ld	s0,16(sp)
    800019be:	64a2                	ld	s1,8(sp)
    800019c0:	6105                	addi	sp,sp,32
    800019c2:	8082                	ret
    panic("wakeup1");
    800019c4:	00007517          	auipc	a0,0x7
    800019c8:	83c50513          	addi	a0,a0,-1988 # 80008200 <digits+0x1c0>
    800019cc:	fffff097          	auipc	ra,0xfffff
    800019d0:	b7c080e7          	jalr	-1156(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800019d4:	4c98                	lw	a4,24(s1)
    800019d6:	4785                	li	a5,1
    800019d8:	fef711e3          	bne	a4,a5,800019ba <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019dc:	4789                	li	a5,2
    800019de:	cc9c                	sw	a5,24(s1)
}
    800019e0:	bfe9                	j	800019ba <wakeup1+0x1c>

00000000800019e2 <procinit>:
{
    800019e2:	715d                	addi	sp,sp,-80
    800019e4:	e486                	sd	ra,72(sp)
    800019e6:	e0a2                	sd	s0,64(sp)
    800019e8:	fc26                	sd	s1,56(sp)
    800019ea:	f84a                	sd	s2,48(sp)
    800019ec:	f44e                	sd	s3,40(sp)
    800019ee:	f052                	sd	s4,32(sp)
    800019f0:	ec56                	sd	s5,24(sp)
    800019f2:	e85a                	sd	s6,16(sp)
    800019f4:	e45e                	sd	s7,8(sp)
    800019f6:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800019f8:	00007597          	auipc	a1,0x7
    800019fc:	81058593          	addi	a1,a1,-2032 # 80008208 <digits+0x1c8>
    80001a00:	00010517          	auipc	a0,0x10
    80001a04:	f5050513          	addi	a0,a0,-176 # 80011950 <pid_lock>
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	178080e7          	jalr	376(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a10:	00010917          	auipc	s2,0x10
    80001a14:	35890913          	addi	s2,s2,856 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001a18:	00006b97          	auipc	s7,0x6
    80001a1c:	7f8b8b93          	addi	s7,s7,2040 # 80008210 <digits+0x1d0>
      uint64 va = KSTACK((int) (p - proc));
    80001a20:	8b4a                	mv	s6,s2
    80001a22:	00006a97          	auipc	s5,0x6
    80001a26:	5dea8a93          	addi	s5,s5,1502 # 80008000 <etext>
    80001a2a:	040009b7          	lui	s3,0x4000
    80001a2e:	19fd                	addi	s3,s3,-1
    80001a30:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a32:	00016a17          	auipc	s4,0x16
    80001a36:	d36a0a13          	addi	s4,s4,-714 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001a3a:	85de                	mv	a1,s7
    80001a3c:	854a                	mv	a0,s2
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	142080e7          	jalr	322(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	0da080e7          	jalr	218(ra) # 80000b20 <kalloc>
    80001a4e:	85aa                	mv	a1,a0
      if(pa == 0)
    80001a50:	c929                	beqz	a0,80001aa2 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001a52:	416904b3          	sub	s1,s2,s6
    80001a56:	848d                	srai	s1,s1,0x3
    80001a58:	000ab783          	ld	a5,0(s5)
    80001a5c:	02f484b3          	mul	s1,s1,a5
    80001a60:	2485                	addiw	s1,s1,1
    80001a62:	00d4949b          	slliw	s1,s1,0xd
    80001a66:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a6a:	4699                	li	a3,6
    80001a6c:	6605                	lui	a2,0x1
    80001a6e:	8526                	mv	a0,s1
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	764080e7          	jalr	1892(ra) # 800011d4 <kvmmap>
      p->kstack = va;
    80001a78:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a7c:	16890913          	addi	s2,s2,360
    80001a80:	fb491de3          	bne	s2,s4,80001a3a <procinit+0x58>
  kvminithart();
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	558080e7          	jalr	1368(ra) # 80000fdc <kvminithart>
}
    80001a8c:	60a6                	ld	ra,72(sp)
    80001a8e:	6406                	ld	s0,64(sp)
    80001a90:	74e2                	ld	s1,56(sp)
    80001a92:	7942                	ld	s2,48(sp)
    80001a94:	79a2                	ld	s3,40(sp)
    80001a96:	7a02                	ld	s4,32(sp)
    80001a98:	6ae2                	ld	s5,24(sp)
    80001a9a:	6b42                	ld	s6,16(sp)
    80001a9c:	6ba2                	ld	s7,8(sp)
    80001a9e:	6161                	addi	sp,sp,80
    80001aa0:	8082                	ret
        panic("kalloc");
    80001aa2:	00006517          	auipc	a0,0x6
    80001aa6:	77650513          	addi	a0,a0,1910 # 80008218 <digits+0x1d8>
    80001aaa:	fffff097          	auipc	ra,0xfffff
    80001aae:	a9e080e7          	jalr	-1378(ra) # 80000548 <panic>

0000000080001ab2 <cpuid>:
{
    80001ab2:	1141                	addi	sp,sp,-16
    80001ab4:	e422                	sd	s0,8(sp)
    80001ab6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ab8:	8512                	mv	a0,tp
}
    80001aba:	2501                	sext.w	a0,a0
    80001abc:	6422                	ld	s0,8(sp)
    80001abe:	0141                	addi	sp,sp,16
    80001ac0:	8082                	ret

0000000080001ac2 <mycpu>:
mycpu(void) {
    80001ac2:	1141                	addi	sp,sp,-16
    80001ac4:	e422                	sd	s0,8(sp)
    80001ac6:	0800                	addi	s0,sp,16
    80001ac8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001aca:	2781                	sext.w	a5,a5
    80001acc:	079e                	slli	a5,a5,0x7
}
    80001ace:	00010517          	auipc	a0,0x10
    80001ad2:	e9a50513          	addi	a0,a0,-358 # 80011968 <cpus>
    80001ad6:	953e                	add	a0,a0,a5
    80001ad8:	6422                	ld	s0,8(sp)
    80001ada:	0141                	addi	sp,sp,16
    80001adc:	8082                	ret

0000000080001ade <myproc>:
myproc(void) {
    80001ade:	1101                	addi	sp,sp,-32
    80001ae0:	ec06                	sd	ra,24(sp)
    80001ae2:	e822                	sd	s0,16(sp)
    80001ae4:	e426                	sd	s1,8(sp)
    80001ae6:	1000                	addi	s0,sp,32
  push_off();
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	0dc080e7          	jalr	220(ra) # 80000bc4 <push_off>
    80001af0:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001af2:	2781                	sext.w	a5,a5
    80001af4:	079e                	slli	a5,a5,0x7
    80001af6:	00010717          	auipc	a4,0x10
    80001afa:	e5a70713          	addi	a4,a4,-422 # 80011950 <pid_lock>
    80001afe:	97ba                	add	a5,a5,a4
    80001b00:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	162080e7          	jalr	354(ra) # 80000c64 <pop_off>
}
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	60e2                	ld	ra,24(sp)
    80001b0e:	6442                	ld	s0,16(sp)
    80001b10:	64a2                	ld	s1,8(sp)
    80001b12:	6105                	addi	sp,sp,32
    80001b14:	8082                	ret

0000000080001b16 <forkret>:
{
    80001b16:	1141                	addi	sp,sp,-16
    80001b18:	e406                	sd	ra,8(sp)
    80001b1a:	e022                	sd	s0,0(sp)
    80001b1c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b1e:	00000097          	auipc	ra,0x0
    80001b22:	fc0080e7          	jalr	-64(ra) # 80001ade <myproc>
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	19e080e7          	jalr	414(ra) # 80000cc4 <release>
  if (first) {
    80001b2e:	00007797          	auipc	a5,0x7
    80001b32:	d527a783          	lw	a5,-686(a5) # 80008880 <first.1672>
    80001b36:	eb89                	bnez	a5,80001b48 <forkret+0x32>
  usertrapret();
    80001b38:	00001097          	auipc	ra,0x1
    80001b3c:	c18080e7          	jalr	-1000(ra) # 80002750 <usertrapret>
}
    80001b40:	60a2                	ld	ra,8(sp)
    80001b42:	6402                	ld	s0,0(sp)
    80001b44:	0141                	addi	sp,sp,16
    80001b46:	8082                	ret
    first = 0;
    80001b48:	00007797          	auipc	a5,0x7
    80001b4c:	d207ac23          	sw	zero,-712(a5) # 80008880 <first.1672>
    fsinit(ROOTDEV);
    80001b50:	4505                	li	a0,1
    80001b52:	00002097          	auipc	ra,0x2
    80001b56:	940080e7          	jalr	-1728(ra) # 80003492 <fsinit>
    80001b5a:	bff9                	j	80001b38 <forkret+0x22>

0000000080001b5c <allocpid>:
allocpid() {
    80001b5c:	1101                	addi	sp,sp,-32
    80001b5e:	ec06                	sd	ra,24(sp)
    80001b60:	e822                	sd	s0,16(sp)
    80001b62:	e426                	sd	s1,8(sp)
    80001b64:	e04a                	sd	s2,0(sp)
    80001b66:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b68:	00010917          	auipc	s2,0x10
    80001b6c:	de890913          	addi	s2,s2,-536 # 80011950 <pid_lock>
    80001b70:	854a                	mv	a0,s2
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	09e080e7          	jalr	158(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001b7a:	00007797          	auipc	a5,0x7
    80001b7e:	d0a78793          	addi	a5,a5,-758 # 80008884 <nextpid>
    80001b82:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b84:	0014871b          	addiw	a4,s1,1
    80001b88:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b8a:	854a                	mv	a0,s2
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	138080e7          	jalr	312(ra) # 80000cc4 <release>
}
    80001b94:	8526                	mv	a0,s1
    80001b96:	60e2                	ld	ra,24(sp)
    80001b98:	6442                	ld	s0,16(sp)
    80001b9a:	64a2                	ld	s1,8(sp)
    80001b9c:	6902                	ld	s2,0(sp)
    80001b9e:	6105                	addi	sp,sp,32
    80001ba0:	8082                	ret

0000000080001ba2 <proc_pagetable>:
{
    80001ba2:	1101                	addi	sp,sp,-32
    80001ba4:	ec06                	sd	ra,24(sp)
    80001ba6:	e822                	sd	s0,16(sp)
    80001ba8:	e426                	sd	s1,8(sp)
    80001baa:	e04a                	sd	s2,0(sp)
    80001bac:	1000                	addi	s0,sp,32
    80001bae:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	7f2080e7          	jalr	2034(ra) # 800013a2 <uvmcreate>
    80001bb8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bba:	c121                	beqz	a0,80001bfa <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bbc:	4729                	li	a4,10
    80001bbe:	00005697          	auipc	a3,0x5
    80001bc2:	44268693          	addi	a3,a3,1090 # 80007000 <_trampoline>
    80001bc6:	6605                	lui	a2,0x1
    80001bc8:	040005b7          	lui	a1,0x4000
    80001bcc:	15fd                	addi	a1,a1,-1
    80001bce:	05b2                	slli	a1,a1,0xc
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	576080e7          	jalr	1398(ra) # 80001146 <mappages>
    80001bd8:	02054863          	bltz	a0,80001c08 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bdc:	4719                	li	a4,6
    80001bde:	05893683          	ld	a3,88(s2)
    80001be2:	6605                	lui	a2,0x1
    80001be4:	020005b7          	lui	a1,0x2000
    80001be8:	15fd                	addi	a1,a1,-1
    80001bea:	05b6                	slli	a1,a1,0xd
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	558080e7          	jalr	1368(ra) # 80001146 <mappages>
    80001bf6:	02054163          	bltz	a0,80001c18 <proc_pagetable+0x76>
}
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	60e2                	ld	ra,24(sp)
    80001bfe:	6442                	ld	s0,16(sp)
    80001c00:	64a2                	ld	s1,8(sp)
    80001c02:	6902                	ld	s2,0(sp)
    80001c04:	6105                	addi	sp,sp,32
    80001c06:	8082                	ret
    uvmfree(pagetable, 0);
    80001c08:	4581                	li	a1,0
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	a8a080e7          	jalr	-1398(ra) # 80001696 <uvmfree>
    return 0;
    80001c14:	4481                	li	s1,0
    80001c16:	b7d5                	j	80001bfa <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c18:	4681                	li	a3,0
    80001c1a:	4605                	li	a2,1
    80001c1c:	040005b7          	lui	a1,0x4000
    80001c20:	15fd                	addi	a1,a1,-1
    80001c22:	05b2                	slli	a1,a1,0xc
    80001c24:	8526                	mv	a0,s1
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	6b8080e7          	jalr	1720(ra) # 800012de <uvmunmap>
    uvmfree(pagetable, 0);
    80001c2e:	4581                	li	a1,0
    80001c30:	8526                	mv	a0,s1
    80001c32:	00000097          	auipc	ra,0x0
    80001c36:	a64080e7          	jalr	-1436(ra) # 80001696 <uvmfree>
    return 0;
    80001c3a:	4481                	li	s1,0
    80001c3c:	bf7d                	j	80001bfa <proc_pagetable+0x58>

0000000080001c3e <proc_freepagetable>:
{
    80001c3e:	1101                	addi	sp,sp,-32
    80001c40:	ec06                	sd	ra,24(sp)
    80001c42:	e822                	sd	s0,16(sp)
    80001c44:	e426                	sd	s1,8(sp)
    80001c46:	e04a                	sd	s2,0(sp)
    80001c48:	1000                	addi	s0,sp,32
    80001c4a:	84aa                	mv	s1,a0
    80001c4c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c4e:	4681                	li	a3,0
    80001c50:	4605                	li	a2,1
    80001c52:	040005b7          	lui	a1,0x4000
    80001c56:	15fd                	addi	a1,a1,-1
    80001c58:	05b2                	slli	a1,a1,0xc
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	684080e7          	jalr	1668(ra) # 800012de <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c62:	4681                	li	a3,0
    80001c64:	4605                	li	a2,1
    80001c66:	020005b7          	lui	a1,0x2000
    80001c6a:	15fd                	addi	a1,a1,-1
    80001c6c:	05b6                	slli	a1,a1,0xd
    80001c6e:	8526                	mv	a0,s1
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	66e080e7          	jalr	1646(ra) # 800012de <uvmunmap>
  uvmfree(pagetable, sz);
    80001c78:	85ca                	mv	a1,s2
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	a1a080e7          	jalr	-1510(ra) # 80001696 <uvmfree>
}
    80001c84:	60e2                	ld	ra,24(sp)
    80001c86:	6442                	ld	s0,16(sp)
    80001c88:	64a2                	ld	s1,8(sp)
    80001c8a:	6902                	ld	s2,0(sp)
    80001c8c:	6105                	addi	sp,sp,32
    80001c8e:	8082                	ret

0000000080001c90 <freeproc>:
{
    80001c90:	1101                	addi	sp,sp,-32
    80001c92:	ec06                	sd	ra,24(sp)
    80001c94:	e822                	sd	s0,16(sp)
    80001c96:	e426                	sd	s1,8(sp)
    80001c98:	1000                	addi	s0,sp,32
    80001c9a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c9c:	6d28                	ld	a0,88(a0)
    80001c9e:	c509                	beqz	a0,80001ca8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	d84080e7          	jalr	-636(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001ca8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cac:	68a8                	ld	a0,80(s1)
    80001cae:	c511                	beqz	a0,80001cba <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cb0:	64ac                	ld	a1,72(s1)
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	f8c080e7          	jalr	-116(ra) # 80001c3e <proc_freepagetable>
  p->pagetable = 0;
    80001cba:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cbe:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cc2:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001cc6:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001cca:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cce:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001cd2:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001cd6:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001cda:	0004ac23          	sw	zero,24(s1)
}
    80001cde:	60e2                	ld	ra,24(sp)
    80001ce0:	6442                	ld	s0,16(sp)
    80001ce2:	64a2                	ld	s1,8(sp)
    80001ce4:	6105                	addi	sp,sp,32
    80001ce6:	8082                	ret

0000000080001ce8 <allocproc>:
{
    80001ce8:	1101                	addi	sp,sp,-32
    80001cea:	ec06                	sd	ra,24(sp)
    80001cec:	e822                	sd	s0,16(sp)
    80001cee:	e426                	sd	s1,8(sp)
    80001cf0:	e04a                	sd	s2,0(sp)
    80001cf2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cf4:	00010497          	auipc	s1,0x10
    80001cf8:	07448493          	addi	s1,s1,116 # 80011d68 <proc>
    80001cfc:	00016917          	auipc	s2,0x16
    80001d00:	a6c90913          	addi	s2,s2,-1428 # 80017768 <tickslock>
    acquire(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	f0a080e7          	jalr	-246(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001d0e:	4c9c                	lw	a5,24(s1)
    80001d10:	cf81                	beqz	a5,80001d28 <allocproc+0x40>
      release(&p->lock);
    80001d12:	8526                	mv	a0,s1
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	fb0080e7          	jalr	-80(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d1c:	16848493          	addi	s1,s1,360
    80001d20:	ff2492e3          	bne	s1,s2,80001d04 <allocproc+0x1c>
  return 0;
    80001d24:	4481                	li	s1,0
    80001d26:	a0b9                	j	80001d74 <allocproc+0x8c>
  p->pid = allocpid();
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	e34080e7          	jalr	-460(ra) # 80001b5c <allocpid>
    80001d30:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	dee080e7          	jalr	-530(ra) # 80000b20 <kalloc>
    80001d3a:	892a                	mv	s2,a0
    80001d3c:	eca8                	sd	a0,88(s1)
    80001d3e:	c131                	beqz	a0,80001d82 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d40:	8526                	mv	a0,s1
    80001d42:	00000097          	auipc	ra,0x0
    80001d46:	e60080e7          	jalr	-416(ra) # 80001ba2 <proc_pagetable>
    80001d4a:	892a                	mv	s2,a0
    80001d4c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d4e:	c129                	beqz	a0,80001d90 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d50:	07000613          	li	a2,112
    80001d54:	4581                	li	a1,0
    80001d56:	06048513          	addi	a0,s1,96
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	fb2080e7          	jalr	-78(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001d62:	00000797          	auipc	a5,0x0
    80001d66:	db478793          	addi	a5,a5,-588 # 80001b16 <forkret>
    80001d6a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d6c:	60bc                	ld	a5,64(s1)
    80001d6e:	6705                	lui	a4,0x1
    80001d70:	97ba                	add	a5,a5,a4
    80001d72:	f4bc                	sd	a5,104(s1)
}
    80001d74:	8526                	mv	a0,s1
    80001d76:	60e2                	ld	ra,24(sp)
    80001d78:	6442                	ld	s0,16(sp)
    80001d7a:	64a2                	ld	s1,8(sp)
    80001d7c:	6902                	ld	s2,0(sp)
    80001d7e:	6105                	addi	sp,sp,32
    80001d80:	8082                	ret
    release(&p->lock);
    80001d82:	8526                	mv	a0,s1
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	f40080e7          	jalr	-192(ra) # 80000cc4 <release>
    return 0;
    80001d8c:	84ca                	mv	s1,s2
    80001d8e:	b7dd                	j	80001d74 <allocproc+0x8c>
    freeproc(p);
    80001d90:	8526                	mv	a0,s1
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	efe080e7          	jalr	-258(ra) # 80001c90 <freeproc>
    release(&p->lock);
    80001d9a:	8526                	mv	a0,s1
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	f28080e7          	jalr	-216(ra) # 80000cc4 <release>
    return 0;
    80001da4:	84ca                	mv	s1,s2
    80001da6:	b7f9                	j	80001d74 <allocproc+0x8c>

0000000080001da8 <userinit>:
{
    80001da8:	1101                	addi	sp,sp,-32
    80001daa:	ec06                	sd	ra,24(sp)
    80001dac:	e822                	sd	s0,16(sp)
    80001dae:	e426                	sd	s1,8(sp)
    80001db0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	f36080e7          	jalr	-202(ra) # 80001ce8 <allocproc>
    80001dba:	84aa                	mv	s1,a0
  initproc = p;
    80001dbc:	00007797          	auipc	a5,0x7
    80001dc0:	24a7be23          	sd	a0,604(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001dc4:	03400613          	li	a2,52
    80001dc8:	00007597          	auipc	a1,0x7
    80001dcc:	ac858593          	addi	a1,a1,-1336 # 80008890 <initcode>
    80001dd0:	6928                	ld	a0,80(a0)
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	5fe080e7          	jalr	1534(ra) # 800013d0 <uvminit>
  p->sz = PGSIZE;
    80001dda:	6785                	lui	a5,0x1
    80001ddc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dde:	6cb8                	ld	a4,88(s1)
    80001de0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001de4:	6cb8                	ld	a4,88(s1)
    80001de6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001de8:	4641                	li	a2,16
    80001dea:	00006597          	auipc	a1,0x6
    80001dee:	43658593          	addi	a1,a1,1078 # 80008220 <digits+0x1e0>
    80001df2:	15848513          	addi	a0,s1,344
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	06c080e7          	jalr	108(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001dfe:	00006517          	auipc	a0,0x6
    80001e02:	43250513          	addi	a0,a0,1074 # 80008230 <digits+0x1f0>
    80001e06:	00002097          	auipc	ra,0x2
    80001e0a:	0b4080e7          	jalr	180(ra) # 80003eba <namei>
    80001e0e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e12:	4789                	li	a5,2
    80001e14:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e16:	8526                	mv	a0,s1
    80001e18:	fffff097          	auipc	ra,0xfffff
    80001e1c:	eac080e7          	jalr	-340(ra) # 80000cc4 <release>
}
    80001e20:	60e2                	ld	ra,24(sp)
    80001e22:	6442                	ld	s0,16(sp)
    80001e24:	64a2                	ld	s1,8(sp)
    80001e26:	6105                	addi	sp,sp,32
    80001e28:	8082                	ret

0000000080001e2a <growproc>:
{
    80001e2a:	1101                	addi	sp,sp,-32
    80001e2c:	ec06                	sd	ra,24(sp)
    80001e2e:	e822                	sd	s0,16(sp)
    80001e30:	e426                	sd	s1,8(sp)
    80001e32:	e04a                	sd	s2,0(sp)
    80001e34:	1000                	addi	s0,sp,32
    80001e36:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e38:	00000097          	auipc	ra,0x0
    80001e3c:	ca6080e7          	jalr	-858(ra) # 80001ade <myproc>
    80001e40:	892a                	mv	s2,a0
  sz = p->sz;
    80001e42:	652c                	ld	a1,72(a0)
    80001e44:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e48:	00904f63          	bgtz	s1,80001e66 <growproc+0x3c>
  } else if(n < 0){
    80001e4c:	0204cc63          	bltz	s1,80001e84 <growproc+0x5a>
  p->sz = sz;
    80001e50:	1602                	slli	a2,a2,0x20
    80001e52:	9201                	srli	a2,a2,0x20
    80001e54:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e58:	4501                	li	a0,0
}
    80001e5a:	60e2                	ld	ra,24(sp)
    80001e5c:	6442                	ld	s0,16(sp)
    80001e5e:	64a2                	ld	s1,8(sp)
    80001e60:	6902                	ld	s2,0(sp)
    80001e62:	6105                	addi	sp,sp,32
    80001e64:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e66:	9e25                	addw	a2,a2,s1
    80001e68:	1602                	slli	a2,a2,0x20
    80001e6a:	9201                	srli	a2,a2,0x20
    80001e6c:	1582                	slli	a1,a1,0x20
    80001e6e:	9181                	srli	a1,a1,0x20
    80001e70:	6928                	ld	a0,80(a0)
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	618080e7          	jalr	1560(ra) # 8000148a <uvmalloc>
    80001e7a:	0005061b          	sext.w	a2,a0
    80001e7e:	fa69                	bnez	a2,80001e50 <growproc+0x26>
      return -1;
    80001e80:	557d                	li	a0,-1
    80001e82:	bfe1                	j	80001e5a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e84:	9e25                	addw	a2,a2,s1
    80001e86:	1602                	slli	a2,a2,0x20
    80001e88:	9201                	srli	a2,a2,0x20
    80001e8a:	1582                	slli	a1,a1,0x20
    80001e8c:	9181                	srli	a1,a1,0x20
    80001e8e:	6928                	ld	a0,80(a0)
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	5b2080e7          	jalr	1458(ra) # 80001442 <uvmdealloc>
    80001e98:	0005061b          	sext.w	a2,a0
    80001e9c:	bf55                	j	80001e50 <growproc+0x26>

0000000080001e9e <fork>:
{
    80001e9e:	7179                	addi	sp,sp,-48
    80001ea0:	f406                	sd	ra,40(sp)
    80001ea2:	f022                	sd	s0,32(sp)
    80001ea4:	ec26                	sd	s1,24(sp)
    80001ea6:	e84a                	sd	s2,16(sp)
    80001ea8:	e44e                	sd	s3,8(sp)
    80001eaa:	e052                	sd	s4,0(sp)
    80001eac:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001eae:	00000097          	auipc	ra,0x0
    80001eb2:	c30080e7          	jalr	-976(ra) # 80001ade <myproc>
    80001eb6:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001eb8:	00000097          	auipc	ra,0x0
    80001ebc:	e30080e7          	jalr	-464(ra) # 80001ce8 <allocproc>
    80001ec0:	c175                	beqz	a0,80001fa4 <fork+0x106>
    80001ec2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ec4:	04893603          	ld	a2,72(s2)
    80001ec8:	692c                	ld	a1,80(a0)
    80001eca:	05093503          	ld	a0,80(s2)
    80001ece:	00000097          	auipc	ra,0x0
    80001ed2:	800080e7          	jalr	-2048(ra) # 800016ce <uvmcopy>
    80001ed6:	04054863          	bltz	a0,80001f26 <fork+0x88>
  np->sz = p->sz;
    80001eda:	04893783          	ld	a5,72(s2)
    80001ede:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001ee2:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ee6:	05893683          	ld	a3,88(s2)
    80001eea:	87b6                	mv	a5,a3
    80001eec:	0589b703          	ld	a4,88(s3)
    80001ef0:	12068693          	addi	a3,a3,288
    80001ef4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ef8:	6788                	ld	a0,8(a5)
    80001efa:	6b8c                	ld	a1,16(a5)
    80001efc:	6f90                	ld	a2,24(a5)
    80001efe:	01073023          	sd	a6,0(a4)
    80001f02:	e708                	sd	a0,8(a4)
    80001f04:	eb0c                	sd	a1,16(a4)
    80001f06:	ef10                	sd	a2,24(a4)
    80001f08:	02078793          	addi	a5,a5,32
    80001f0c:	02070713          	addi	a4,a4,32
    80001f10:	fed792e3          	bne	a5,a3,80001ef4 <fork+0x56>
  np->trapframe->a0 = 0;
    80001f14:	0589b783          	ld	a5,88(s3)
    80001f18:	0607b823          	sd	zero,112(a5)
    80001f1c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f20:	15000a13          	li	s4,336
    80001f24:	a03d                	j	80001f52 <fork+0xb4>
    freeproc(np);
    80001f26:	854e                	mv	a0,s3
    80001f28:	00000097          	auipc	ra,0x0
    80001f2c:	d68080e7          	jalr	-664(ra) # 80001c90 <freeproc>
    release(&np->lock);
    80001f30:	854e                	mv	a0,s3
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	d92080e7          	jalr	-622(ra) # 80000cc4 <release>
    return -1;
    80001f3a:	54fd                	li	s1,-1
    80001f3c:	a899                	j	80001f92 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f3e:	00002097          	auipc	ra,0x2
    80001f42:	608080e7          	jalr	1544(ra) # 80004546 <filedup>
    80001f46:	009987b3          	add	a5,s3,s1
    80001f4a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f4c:	04a1                	addi	s1,s1,8
    80001f4e:	01448763          	beq	s1,s4,80001f5c <fork+0xbe>
    if(p->ofile[i])
    80001f52:	009907b3          	add	a5,s2,s1
    80001f56:	6388                	ld	a0,0(a5)
    80001f58:	f17d                	bnez	a0,80001f3e <fork+0xa0>
    80001f5a:	bfcd                	j	80001f4c <fork+0xae>
  np->cwd = idup(p->cwd);
    80001f5c:	15093503          	ld	a0,336(s2)
    80001f60:	00001097          	auipc	ra,0x1
    80001f64:	76c080e7          	jalr	1900(ra) # 800036cc <idup>
    80001f68:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f6c:	4641                	li	a2,16
    80001f6e:	15890593          	addi	a1,s2,344
    80001f72:	15898513          	addi	a0,s3,344
    80001f76:	fffff097          	auipc	ra,0xfffff
    80001f7a:	eec080e7          	jalr	-276(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80001f7e:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f82:	4789                	li	a5,2
    80001f84:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f88:	854e                	mv	a0,s3
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	d3a080e7          	jalr	-710(ra) # 80000cc4 <release>
}
    80001f92:	8526                	mv	a0,s1
    80001f94:	70a2                	ld	ra,40(sp)
    80001f96:	7402                	ld	s0,32(sp)
    80001f98:	64e2                	ld	s1,24(sp)
    80001f9a:	6942                	ld	s2,16(sp)
    80001f9c:	69a2                	ld	s3,8(sp)
    80001f9e:	6a02                	ld	s4,0(sp)
    80001fa0:	6145                	addi	sp,sp,48
    80001fa2:	8082                	ret
    return -1;
    80001fa4:	54fd                	li	s1,-1
    80001fa6:	b7f5                	j	80001f92 <fork+0xf4>

0000000080001fa8 <reparent>:
{
    80001fa8:	7179                	addi	sp,sp,-48
    80001faa:	f406                	sd	ra,40(sp)
    80001fac:	f022                	sd	s0,32(sp)
    80001fae:	ec26                	sd	s1,24(sp)
    80001fb0:	e84a                	sd	s2,16(sp)
    80001fb2:	e44e                	sd	s3,8(sp)
    80001fb4:	e052                	sd	s4,0(sp)
    80001fb6:	1800                	addi	s0,sp,48
    80001fb8:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fba:	00010497          	auipc	s1,0x10
    80001fbe:	dae48493          	addi	s1,s1,-594 # 80011d68 <proc>
      pp->parent = initproc;
    80001fc2:	00007a17          	auipc	s4,0x7
    80001fc6:	056a0a13          	addi	s4,s4,86 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fca:	00015997          	auipc	s3,0x15
    80001fce:	79e98993          	addi	s3,s3,1950 # 80017768 <tickslock>
    80001fd2:	a029                	j	80001fdc <reparent+0x34>
    80001fd4:	16848493          	addi	s1,s1,360
    80001fd8:	03348363          	beq	s1,s3,80001ffe <reparent+0x56>
    if(pp->parent == p){
    80001fdc:	709c                	ld	a5,32(s1)
    80001fde:	ff279be3          	bne	a5,s2,80001fd4 <reparent+0x2c>
      acquire(&pp->lock);
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	c2c080e7          	jalr	-980(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80001fec:	000a3783          	ld	a5,0(s4)
    80001ff0:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001ff2:	8526                	mv	a0,s1
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	cd0080e7          	jalr	-816(ra) # 80000cc4 <release>
    80001ffc:	bfe1                	j	80001fd4 <reparent+0x2c>
}
    80001ffe:	70a2                	ld	ra,40(sp)
    80002000:	7402                	ld	s0,32(sp)
    80002002:	64e2                	ld	s1,24(sp)
    80002004:	6942                	ld	s2,16(sp)
    80002006:	69a2                	ld	s3,8(sp)
    80002008:	6a02                	ld	s4,0(sp)
    8000200a:	6145                	addi	sp,sp,48
    8000200c:	8082                	ret

000000008000200e <scheduler>:
{
    8000200e:	715d                	addi	sp,sp,-80
    80002010:	e486                	sd	ra,72(sp)
    80002012:	e0a2                	sd	s0,64(sp)
    80002014:	fc26                	sd	s1,56(sp)
    80002016:	f84a                	sd	s2,48(sp)
    80002018:	f44e                	sd	s3,40(sp)
    8000201a:	f052                	sd	s4,32(sp)
    8000201c:	ec56                	sd	s5,24(sp)
    8000201e:	e85a                	sd	s6,16(sp)
    80002020:	e45e                	sd	s7,8(sp)
    80002022:	e062                	sd	s8,0(sp)
    80002024:	0880                	addi	s0,sp,80
    80002026:	8792                	mv	a5,tp
  int id = r_tp();
    80002028:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000202a:	00779b13          	slli	s6,a5,0x7
    8000202e:	00010717          	auipc	a4,0x10
    80002032:	92270713          	addi	a4,a4,-1758 # 80011950 <pid_lock>
    80002036:	975a                	add	a4,a4,s6
    80002038:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    8000203c:	00010717          	auipc	a4,0x10
    80002040:	93470713          	addi	a4,a4,-1740 # 80011970 <cpus+0x8>
    80002044:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80002046:	4c0d                	li	s8,3
        c->proc = p;
    80002048:	079e                	slli	a5,a5,0x7
    8000204a:	00010a17          	auipc	s4,0x10
    8000204e:	906a0a13          	addi	s4,s4,-1786 # 80011950 <pid_lock>
    80002052:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002054:	00015997          	auipc	s3,0x15
    80002058:	71498993          	addi	s3,s3,1812 # 80017768 <tickslock>
        found = 1;
    8000205c:	4b85                	li	s7,1
    8000205e:	a899                	j	800020b4 <scheduler+0xa6>
        p->state = RUNNING;
    80002060:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80002064:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80002068:	06048593          	addi	a1,s1,96
    8000206c:	855a                	mv	a0,s6
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	638080e7          	jalr	1592(ra) # 800026a6 <swtch>
        c->proc = 0;
    80002076:	000a3c23          	sd	zero,24(s4)
        found = 1;
    8000207a:	8ade                	mv	s5,s7
      release(&p->lock);
    8000207c:	8526                	mv	a0,s1
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	c46080e7          	jalr	-954(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002086:	16848493          	addi	s1,s1,360
    8000208a:	01348b63          	beq	s1,s3,800020a0 <scheduler+0x92>
      acquire(&p->lock);
    8000208e:	8526                	mv	a0,s1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	b80080e7          	jalr	-1152(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    80002098:	4c9c                	lw	a5,24(s1)
    8000209a:	ff2791e3          	bne	a5,s2,8000207c <scheduler+0x6e>
    8000209e:	b7c9                	j	80002060 <scheduler+0x52>
    if(found == 0) {
    800020a0:	000a9a63          	bnez	s5,800020b4 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020a4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020a8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020ac:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800020b0:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020b8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020bc:	10079073          	csrw	sstatus,a5
    int found = 0;
    800020c0:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    800020c2:	00010497          	auipc	s1,0x10
    800020c6:	ca648493          	addi	s1,s1,-858 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    800020ca:	4909                	li	s2,2
    800020cc:	b7c9                	j	8000208e <scheduler+0x80>

00000000800020ce <sched>:
{
    800020ce:	7179                	addi	sp,sp,-48
    800020d0:	f406                	sd	ra,40(sp)
    800020d2:	f022                	sd	s0,32(sp)
    800020d4:	ec26                	sd	s1,24(sp)
    800020d6:	e84a                	sd	s2,16(sp)
    800020d8:	e44e                	sd	s3,8(sp)
    800020da:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020dc:	00000097          	auipc	ra,0x0
    800020e0:	a02080e7          	jalr	-1534(ra) # 80001ade <myproc>
    800020e4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	ab0080e7          	jalr	-1360(ra) # 80000b96 <holding>
    800020ee:	c93d                	beqz	a0,80002164 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020f0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020f2:	2781                	sext.w	a5,a5
    800020f4:	079e                	slli	a5,a5,0x7
    800020f6:	00010717          	auipc	a4,0x10
    800020fa:	85a70713          	addi	a4,a4,-1958 # 80011950 <pid_lock>
    800020fe:	97ba                	add	a5,a5,a4
    80002100:	0907a703          	lw	a4,144(a5)
    80002104:	4785                	li	a5,1
    80002106:	06f71763          	bne	a4,a5,80002174 <sched+0xa6>
  if(p->state == RUNNING)
    8000210a:	4c98                	lw	a4,24(s1)
    8000210c:	478d                	li	a5,3
    8000210e:	06f70b63          	beq	a4,a5,80002184 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002112:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002116:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002118:	efb5                	bnez	a5,80002194 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000211a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000211c:	00010917          	auipc	s2,0x10
    80002120:	83490913          	addi	s2,s2,-1996 # 80011950 <pid_lock>
    80002124:	2781                	sext.w	a5,a5
    80002126:	079e                	slli	a5,a5,0x7
    80002128:	97ca                	add	a5,a5,s2
    8000212a:	0947a983          	lw	s3,148(a5)
    8000212e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002130:	2781                	sext.w	a5,a5
    80002132:	079e                	slli	a5,a5,0x7
    80002134:	00010597          	auipc	a1,0x10
    80002138:	83c58593          	addi	a1,a1,-1988 # 80011970 <cpus+0x8>
    8000213c:	95be                	add	a1,a1,a5
    8000213e:	06048513          	addi	a0,s1,96
    80002142:	00000097          	auipc	ra,0x0
    80002146:	564080e7          	jalr	1380(ra) # 800026a6 <swtch>
    8000214a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000214c:	2781                	sext.w	a5,a5
    8000214e:	079e                	slli	a5,a5,0x7
    80002150:	97ca                	add	a5,a5,s2
    80002152:	0937aa23          	sw	s3,148(a5)
}
    80002156:	70a2                	ld	ra,40(sp)
    80002158:	7402                	ld	s0,32(sp)
    8000215a:	64e2                	ld	s1,24(sp)
    8000215c:	6942                	ld	s2,16(sp)
    8000215e:	69a2                	ld	s3,8(sp)
    80002160:	6145                	addi	sp,sp,48
    80002162:	8082                	ret
    panic("sched p->lock");
    80002164:	00006517          	auipc	a0,0x6
    80002168:	0d450513          	addi	a0,a0,212 # 80008238 <digits+0x1f8>
    8000216c:	ffffe097          	auipc	ra,0xffffe
    80002170:	3dc080e7          	jalr	988(ra) # 80000548 <panic>
    panic("sched locks");
    80002174:	00006517          	auipc	a0,0x6
    80002178:	0d450513          	addi	a0,a0,212 # 80008248 <digits+0x208>
    8000217c:	ffffe097          	auipc	ra,0xffffe
    80002180:	3cc080e7          	jalr	972(ra) # 80000548 <panic>
    panic("sched running");
    80002184:	00006517          	auipc	a0,0x6
    80002188:	0d450513          	addi	a0,a0,212 # 80008258 <digits+0x218>
    8000218c:	ffffe097          	auipc	ra,0xffffe
    80002190:	3bc080e7          	jalr	956(ra) # 80000548 <panic>
    panic("sched interruptible");
    80002194:	00006517          	auipc	a0,0x6
    80002198:	0d450513          	addi	a0,a0,212 # 80008268 <digits+0x228>
    8000219c:	ffffe097          	auipc	ra,0xffffe
    800021a0:	3ac080e7          	jalr	940(ra) # 80000548 <panic>

00000000800021a4 <exit>:
{
    800021a4:	7179                	addi	sp,sp,-48
    800021a6:	f406                	sd	ra,40(sp)
    800021a8:	f022                	sd	s0,32(sp)
    800021aa:	ec26                	sd	s1,24(sp)
    800021ac:	e84a                	sd	s2,16(sp)
    800021ae:	e44e                	sd	s3,8(sp)
    800021b0:	e052                	sd	s4,0(sp)
    800021b2:	1800                	addi	s0,sp,48
    800021b4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	928080e7          	jalr	-1752(ra) # 80001ade <myproc>
    800021be:	89aa                	mv	s3,a0
  if(p == initproc)
    800021c0:	00007797          	auipc	a5,0x7
    800021c4:	e587b783          	ld	a5,-424(a5) # 80009018 <initproc>
    800021c8:	0d050493          	addi	s1,a0,208
    800021cc:	15050913          	addi	s2,a0,336
    800021d0:	02a79363          	bne	a5,a0,800021f6 <exit+0x52>
    panic("init exiting");
    800021d4:	00006517          	auipc	a0,0x6
    800021d8:	0ac50513          	addi	a0,a0,172 # 80008280 <digits+0x240>
    800021dc:	ffffe097          	auipc	ra,0xffffe
    800021e0:	36c080e7          	jalr	876(ra) # 80000548 <panic>
      fileclose(f);
    800021e4:	00002097          	auipc	ra,0x2
    800021e8:	3b4080e7          	jalr	948(ra) # 80004598 <fileclose>
      p->ofile[fd] = 0;
    800021ec:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021f0:	04a1                	addi	s1,s1,8
    800021f2:	01248563          	beq	s1,s2,800021fc <exit+0x58>
    if(p->ofile[fd]){
    800021f6:	6088                	ld	a0,0(s1)
    800021f8:	f575                	bnez	a0,800021e4 <exit+0x40>
    800021fa:	bfdd                	j	800021f0 <exit+0x4c>
  begin_op();
    800021fc:	00002097          	auipc	ra,0x2
    80002200:	eca080e7          	jalr	-310(ra) # 800040c6 <begin_op>
  iput(p->cwd);
    80002204:	1509b503          	ld	a0,336(s3)
    80002208:	00001097          	auipc	ra,0x1
    8000220c:	6bc080e7          	jalr	1724(ra) # 800038c4 <iput>
  end_op();
    80002210:	00002097          	auipc	ra,0x2
    80002214:	f36080e7          	jalr	-202(ra) # 80004146 <end_op>
  p->cwd = 0;
    80002218:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000221c:	00007497          	auipc	s1,0x7
    80002220:	dfc48493          	addi	s1,s1,-516 # 80009018 <initproc>
    80002224:	6088                	ld	a0,0(s1)
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	9ea080e7          	jalr	-1558(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    8000222e:	6088                	ld	a0,0(s1)
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	76e080e7          	jalr	1902(ra) # 8000199e <wakeup1>
  release(&initproc->lock);
    80002238:	6088                	ld	a0,0(s1)
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	a8a080e7          	jalr	-1398(ra) # 80000cc4 <release>
  acquire(&p->lock);
    80002242:	854e                	mv	a0,s3
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	9cc080e7          	jalr	-1588(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    8000224c:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002250:	854e                	mv	a0,s3
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	a72080e7          	jalr	-1422(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	9b4080e7          	jalr	-1612(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    80002264:	854e                	mv	a0,s3
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	9aa080e7          	jalr	-1622(ra) # 80000c10 <acquire>
  reparent(p);
    8000226e:	854e                	mv	a0,s3
    80002270:	00000097          	auipc	ra,0x0
    80002274:	d38080e7          	jalr	-712(ra) # 80001fa8 <reparent>
  wakeup1(original_parent);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	724080e7          	jalr	1828(ra) # 8000199e <wakeup1>
  p->xstate = status;
    80002282:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002286:	4791                	li	a5,4
    80002288:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	a36080e7          	jalr	-1482(ra) # 80000cc4 <release>
  sched();
    80002296:	00000097          	auipc	ra,0x0
    8000229a:	e38080e7          	jalr	-456(ra) # 800020ce <sched>
  panic("zombie exit");
    8000229e:	00006517          	auipc	a0,0x6
    800022a2:	ff250513          	addi	a0,a0,-14 # 80008290 <digits+0x250>
    800022a6:	ffffe097          	auipc	ra,0xffffe
    800022aa:	2a2080e7          	jalr	674(ra) # 80000548 <panic>

00000000800022ae <yield>:
{
    800022ae:	1101                	addi	sp,sp,-32
    800022b0:	ec06                	sd	ra,24(sp)
    800022b2:	e822                	sd	s0,16(sp)
    800022b4:	e426                	sd	s1,8(sp)
    800022b6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022b8:	00000097          	auipc	ra,0x0
    800022bc:	826080e7          	jalr	-2010(ra) # 80001ade <myproc>
    800022c0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	94e080e7          	jalr	-1714(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800022ca:	4789                	li	a5,2
    800022cc:	cc9c                	sw	a5,24(s1)
  sched();
    800022ce:	00000097          	auipc	ra,0x0
    800022d2:	e00080e7          	jalr	-512(ra) # 800020ce <sched>
  release(&p->lock);
    800022d6:	8526                	mv	a0,s1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	9ec080e7          	jalr	-1556(ra) # 80000cc4 <release>
}
    800022e0:	60e2                	ld	ra,24(sp)
    800022e2:	6442                	ld	s0,16(sp)
    800022e4:	64a2                	ld	s1,8(sp)
    800022e6:	6105                	addi	sp,sp,32
    800022e8:	8082                	ret

00000000800022ea <sleep>:
{
    800022ea:	7179                	addi	sp,sp,-48
    800022ec:	f406                	sd	ra,40(sp)
    800022ee:	f022                	sd	s0,32(sp)
    800022f0:	ec26                	sd	s1,24(sp)
    800022f2:	e84a                	sd	s2,16(sp)
    800022f4:	e44e                	sd	s3,8(sp)
    800022f6:	1800                	addi	s0,sp,48
    800022f8:	89aa                	mv	s3,a0
    800022fa:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	7e2080e7          	jalr	2018(ra) # 80001ade <myproc>
    80002304:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002306:	05250663          	beq	a0,s2,80002352 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	906080e7          	jalr	-1786(ra) # 80000c10 <acquire>
    release(lk);
    80002312:	854a                	mv	a0,s2
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	9b0080e7          	jalr	-1616(ra) # 80000cc4 <release>
  p->chan = chan;
    8000231c:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002320:	4785                	li	a5,1
    80002322:	cc9c                	sw	a5,24(s1)
  sched();
    80002324:	00000097          	auipc	ra,0x0
    80002328:	daa080e7          	jalr	-598(ra) # 800020ce <sched>
  p->chan = 0;
    8000232c:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002330:	8526                	mv	a0,s1
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	992080e7          	jalr	-1646(ra) # 80000cc4 <release>
    acquire(lk);
    8000233a:	854a                	mv	a0,s2
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	8d4080e7          	jalr	-1836(ra) # 80000c10 <acquire>
}
    80002344:	70a2                	ld	ra,40(sp)
    80002346:	7402                	ld	s0,32(sp)
    80002348:	64e2                	ld	s1,24(sp)
    8000234a:	6942                	ld	s2,16(sp)
    8000234c:	69a2                	ld	s3,8(sp)
    8000234e:	6145                	addi	sp,sp,48
    80002350:	8082                	ret
  p->chan = chan;
    80002352:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002356:	4785                	li	a5,1
    80002358:	cd1c                	sw	a5,24(a0)
  sched();
    8000235a:	00000097          	auipc	ra,0x0
    8000235e:	d74080e7          	jalr	-652(ra) # 800020ce <sched>
  p->chan = 0;
    80002362:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002366:	bff9                	j	80002344 <sleep+0x5a>

0000000080002368 <wait>:
{
    80002368:	715d                	addi	sp,sp,-80
    8000236a:	e486                	sd	ra,72(sp)
    8000236c:	e0a2                	sd	s0,64(sp)
    8000236e:	fc26                	sd	s1,56(sp)
    80002370:	f84a                	sd	s2,48(sp)
    80002372:	f44e                	sd	s3,40(sp)
    80002374:	f052                	sd	s4,32(sp)
    80002376:	ec56                	sd	s5,24(sp)
    80002378:	e85a                	sd	s6,16(sp)
    8000237a:	e45e                	sd	s7,8(sp)
    8000237c:	e062                	sd	s8,0(sp)
    8000237e:	0880                	addi	s0,sp,80
    80002380:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	75c080e7          	jalr	1884(ra) # 80001ade <myproc>
    8000238a:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000238c:	8c2a                	mv	s8,a0
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	882080e7          	jalr	-1918(ra) # 80000c10 <acquire>
    havekids = 0;
    80002396:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002398:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000239a:	00015997          	auipc	s3,0x15
    8000239e:	3ce98993          	addi	s3,s3,974 # 80017768 <tickslock>
        havekids = 1;
    800023a2:	4a85                	li	s5,1
    havekids = 0;
    800023a4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023a6:	00010497          	auipc	s1,0x10
    800023aa:	9c248493          	addi	s1,s1,-1598 # 80011d68 <proc>
    800023ae:	a08d                	j	80002410 <wait+0xa8>
          pid = np->pid;
    800023b0:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023b4:	000b0e63          	beqz	s6,800023d0 <wait+0x68>
    800023b8:	4691                	li	a3,4
    800023ba:	03448613          	addi	a2,s1,52
    800023be:	85da                	mv	a1,s6
    800023c0:	05093503          	ld	a0,80(s2)
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	40e080e7          	jalr	1038(ra) # 800017d2 <copyout>
    800023cc:	02054263          	bltz	a0,800023f0 <wait+0x88>
          freeproc(np);
    800023d0:	8526                	mv	a0,s1
    800023d2:	00000097          	auipc	ra,0x0
    800023d6:	8be080e7          	jalr	-1858(ra) # 80001c90 <freeproc>
          release(&np->lock);
    800023da:	8526                	mv	a0,s1
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8e8080e7          	jalr	-1816(ra) # 80000cc4 <release>
          release(&p->lock);
    800023e4:	854a                	mv	a0,s2
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	8de080e7          	jalr	-1826(ra) # 80000cc4 <release>
          return pid;
    800023ee:	a8a9                	j	80002448 <wait+0xe0>
            release(&np->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8d2080e7          	jalr	-1838(ra) # 80000cc4 <release>
            release(&p->lock);
    800023fa:	854a                	mv	a0,s2
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	8c8080e7          	jalr	-1848(ra) # 80000cc4 <release>
            return -1;
    80002404:	59fd                	li	s3,-1
    80002406:	a089                	j	80002448 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002408:	16848493          	addi	s1,s1,360
    8000240c:	03348463          	beq	s1,s3,80002434 <wait+0xcc>
      if(np->parent == p){
    80002410:	709c                	ld	a5,32(s1)
    80002412:	ff279be3          	bne	a5,s2,80002408 <wait+0xa0>
        acquire(&np->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	7f8080e7          	jalr	2040(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    80002420:	4c9c                	lw	a5,24(s1)
    80002422:	f94787e3          	beq	a5,s4,800023b0 <wait+0x48>
        release(&np->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	89c080e7          	jalr	-1892(ra) # 80000cc4 <release>
        havekids = 1;
    80002430:	8756                	mv	a4,s5
    80002432:	bfd9                	j	80002408 <wait+0xa0>
    if(!havekids || p->killed){
    80002434:	c701                	beqz	a4,8000243c <wait+0xd4>
    80002436:	03092783          	lw	a5,48(s2)
    8000243a:	c785                	beqz	a5,80002462 <wait+0xfa>
      release(&p->lock);
    8000243c:	854a                	mv	a0,s2
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	886080e7          	jalr	-1914(ra) # 80000cc4 <release>
      return -1;
    80002446:	59fd                	li	s3,-1
}
    80002448:	854e                	mv	a0,s3
    8000244a:	60a6                	ld	ra,72(sp)
    8000244c:	6406                	ld	s0,64(sp)
    8000244e:	74e2                	ld	s1,56(sp)
    80002450:	7942                	ld	s2,48(sp)
    80002452:	79a2                	ld	s3,40(sp)
    80002454:	7a02                	ld	s4,32(sp)
    80002456:	6ae2                	ld	s5,24(sp)
    80002458:	6b42                	ld	s6,16(sp)
    8000245a:	6ba2                	ld	s7,8(sp)
    8000245c:	6c02                	ld	s8,0(sp)
    8000245e:	6161                	addi	sp,sp,80
    80002460:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002462:	85e2                	mv	a1,s8
    80002464:	854a                	mv	a0,s2
    80002466:	00000097          	auipc	ra,0x0
    8000246a:	e84080e7          	jalr	-380(ra) # 800022ea <sleep>
    havekids = 0;
    8000246e:	bf1d                	j	800023a4 <wait+0x3c>

0000000080002470 <wakeup>:
{
    80002470:	7139                	addi	sp,sp,-64
    80002472:	fc06                	sd	ra,56(sp)
    80002474:	f822                	sd	s0,48(sp)
    80002476:	f426                	sd	s1,40(sp)
    80002478:	f04a                	sd	s2,32(sp)
    8000247a:	ec4e                	sd	s3,24(sp)
    8000247c:	e852                	sd	s4,16(sp)
    8000247e:	e456                	sd	s5,8(sp)
    80002480:	0080                	addi	s0,sp,64
    80002482:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002484:	00010497          	auipc	s1,0x10
    80002488:	8e448493          	addi	s1,s1,-1820 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000248c:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000248e:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002490:	00015917          	auipc	s2,0x15
    80002494:	2d890913          	addi	s2,s2,728 # 80017768 <tickslock>
    80002498:	a821                	j	800024b0 <wakeup+0x40>
      p->state = RUNNABLE;
    8000249a:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	824080e7          	jalr	-2012(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024a8:	16848493          	addi	s1,s1,360
    800024ac:	01248e63          	beq	s1,s2,800024c8 <wakeup+0x58>
    acquire(&p->lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	75e080e7          	jalr	1886(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800024ba:	4c9c                	lw	a5,24(s1)
    800024bc:	ff3791e3          	bne	a5,s3,8000249e <wakeup+0x2e>
    800024c0:	749c                	ld	a5,40(s1)
    800024c2:	fd479ee3          	bne	a5,s4,8000249e <wakeup+0x2e>
    800024c6:	bfd1                	j	8000249a <wakeup+0x2a>
}
    800024c8:	70e2                	ld	ra,56(sp)
    800024ca:	7442                	ld	s0,48(sp)
    800024cc:	74a2                	ld	s1,40(sp)
    800024ce:	7902                	ld	s2,32(sp)
    800024d0:	69e2                	ld	s3,24(sp)
    800024d2:	6a42                	ld	s4,16(sp)
    800024d4:	6aa2                	ld	s5,8(sp)
    800024d6:	6121                	addi	sp,sp,64
    800024d8:	8082                	ret

00000000800024da <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024da:	7179                	addi	sp,sp,-48
    800024dc:	f406                	sd	ra,40(sp)
    800024de:	f022                	sd	s0,32(sp)
    800024e0:	ec26                	sd	s1,24(sp)
    800024e2:	e84a                	sd	s2,16(sp)
    800024e4:	e44e                	sd	s3,8(sp)
    800024e6:	1800                	addi	s0,sp,48
    800024e8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024ea:	00010497          	auipc	s1,0x10
    800024ee:	87e48493          	addi	s1,s1,-1922 # 80011d68 <proc>
    800024f2:	00015997          	auipc	s3,0x15
    800024f6:	27698993          	addi	s3,s3,630 # 80017768 <tickslock>
    acquire(&p->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	714080e7          	jalr	1812(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    80002504:	5c9c                	lw	a5,56(s1)
    80002506:	01278d63          	beq	a5,s2,80002520 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000250a:	8526                	mv	a0,s1
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	7b8080e7          	jalr	1976(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002514:	16848493          	addi	s1,s1,360
    80002518:	ff3491e3          	bne	s1,s3,800024fa <kill+0x20>
  }
  return -1;
    8000251c:	557d                	li	a0,-1
    8000251e:	a829                	j	80002538 <kill+0x5e>
      p->killed = 1;
    80002520:	4785                	li	a5,1
    80002522:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002524:	4c98                	lw	a4,24(s1)
    80002526:	4785                	li	a5,1
    80002528:	00f70f63          	beq	a4,a5,80002546 <kill+0x6c>
      release(&p->lock);
    8000252c:	8526                	mv	a0,s1
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	796080e7          	jalr	1942(ra) # 80000cc4 <release>
      return 0;
    80002536:	4501                	li	a0,0
}
    80002538:	70a2                	ld	ra,40(sp)
    8000253a:	7402                	ld	s0,32(sp)
    8000253c:	64e2                	ld	s1,24(sp)
    8000253e:	6942                	ld	s2,16(sp)
    80002540:	69a2                	ld	s3,8(sp)
    80002542:	6145                	addi	sp,sp,48
    80002544:	8082                	ret
        p->state = RUNNABLE;
    80002546:	4789                	li	a5,2
    80002548:	cc9c                	sw	a5,24(s1)
    8000254a:	b7cd                	j	8000252c <kill+0x52>

000000008000254c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000254c:	7179                	addi	sp,sp,-48
    8000254e:	f406                	sd	ra,40(sp)
    80002550:	f022                	sd	s0,32(sp)
    80002552:	ec26                	sd	s1,24(sp)
    80002554:	e84a                	sd	s2,16(sp)
    80002556:	e44e                	sd	s3,8(sp)
    80002558:	e052                	sd	s4,0(sp)
    8000255a:	1800                	addi	s0,sp,48
    8000255c:	84aa                	mv	s1,a0
    8000255e:	892e                	mv	s2,a1
    80002560:	89b2                	mv	s3,a2
    80002562:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	57a080e7          	jalr	1402(ra) # 80001ade <myproc>
  if(user_dst){
    8000256c:	c08d                	beqz	s1,8000258e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000256e:	86d2                	mv	a3,s4
    80002570:	864e                	mv	a2,s3
    80002572:	85ca                	mv	a1,s2
    80002574:	6928                	ld	a0,80(a0)
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	25c080e7          	jalr	604(ra) # 800017d2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000257e:	70a2                	ld	ra,40(sp)
    80002580:	7402                	ld	s0,32(sp)
    80002582:	64e2                	ld	s1,24(sp)
    80002584:	6942                	ld	s2,16(sp)
    80002586:	69a2                	ld	s3,8(sp)
    80002588:	6a02                	ld	s4,0(sp)
    8000258a:	6145                	addi	sp,sp,48
    8000258c:	8082                	ret
    memmove((char *)dst, src, len);
    8000258e:	000a061b          	sext.w	a2,s4
    80002592:	85ce                	mv	a1,s3
    80002594:	854a                	mv	a0,s2
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	7d6080e7          	jalr	2006(ra) # 80000d6c <memmove>
    return 0;
    8000259e:	8526                	mv	a0,s1
    800025a0:	bff9                	j	8000257e <either_copyout+0x32>

00000000800025a2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025a2:	7179                	addi	sp,sp,-48
    800025a4:	f406                	sd	ra,40(sp)
    800025a6:	f022                	sd	s0,32(sp)
    800025a8:	ec26                	sd	s1,24(sp)
    800025aa:	e84a                	sd	s2,16(sp)
    800025ac:	e44e                	sd	s3,8(sp)
    800025ae:	e052                	sd	s4,0(sp)
    800025b0:	1800                	addi	s0,sp,48
    800025b2:	892a                	mv	s2,a0
    800025b4:	84ae                	mv	s1,a1
    800025b6:	89b2                	mv	s3,a2
    800025b8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025ba:	fffff097          	auipc	ra,0xfffff
    800025be:	524080e7          	jalr	1316(ra) # 80001ade <myproc>
  if(user_src){
    800025c2:	c08d                	beqz	s1,800025e4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025c4:	86d2                	mv	a3,s4
    800025c6:	864e                	mv	a2,s3
    800025c8:	85ca                	mv	a1,s2
    800025ca:	6928                	ld	a0,80(a0)
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	292080e7          	jalr	658(ra) # 8000185e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025d4:	70a2                	ld	ra,40(sp)
    800025d6:	7402                	ld	s0,32(sp)
    800025d8:	64e2                	ld	s1,24(sp)
    800025da:	6942                	ld	s2,16(sp)
    800025dc:	69a2                	ld	s3,8(sp)
    800025de:	6a02                	ld	s4,0(sp)
    800025e0:	6145                	addi	sp,sp,48
    800025e2:	8082                	ret
    memmove(dst, (char*)src, len);
    800025e4:	000a061b          	sext.w	a2,s4
    800025e8:	85ce                	mv	a1,s3
    800025ea:	854a                	mv	a0,s2
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	780080e7          	jalr	1920(ra) # 80000d6c <memmove>
    return 0;
    800025f4:	8526                	mv	a0,s1
    800025f6:	bff9                	j	800025d4 <either_copyin+0x32>

00000000800025f8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025f8:	715d                	addi	sp,sp,-80
    800025fa:	e486                	sd	ra,72(sp)
    800025fc:	e0a2                	sd	s0,64(sp)
    800025fe:	fc26                	sd	s1,56(sp)
    80002600:	f84a                	sd	s2,48(sp)
    80002602:	f44e                	sd	s3,40(sp)
    80002604:	f052                	sd	s4,32(sp)
    80002606:	ec56                	sd	s5,24(sp)
    80002608:	e85a                	sd	s6,16(sp)
    8000260a:	e45e                	sd	s7,8(sp)
    8000260c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000260e:	00006517          	auipc	a0,0x6
    80002612:	aba50513          	addi	a0,a0,-1350 # 800080c8 <digits+0x88>
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	f7c080e7          	jalr	-132(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000261e:	00010497          	auipc	s1,0x10
    80002622:	8a248493          	addi	s1,s1,-1886 # 80011ec0 <proc+0x158>
    80002626:	00015917          	auipc	s2,0x15
    8000262a:	29a90913          	addi	s2,s2,666 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262e:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002630:	00006997          	auipc	s3,0x6
    80002634:	c7098993          	addi	s3,s3,-912 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    80002638:	00006a97          	auipc	s5,0x6
    8000263c:	c70a8a93          	addi	s5,s5,-912 # 800082a8 <digits+0x268>
    printf("\n");
    80002640:	00006a17          	auipc	s4,0x6
    80002644:	a88a0a13          	addi	s4,s4,-1400 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002648:	00006b97          	auipc	s7,0x6
    8000264c:	c98b8b93          	addi	s7,s7,-872 # 800082e0 <states.1712>
    80002650:	a00d                	j	80002672 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002652:	ee06a583          	lw	a1,-288(a3)
    80002656:	8556                	mv	a0,s5
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	f3a080e7          	jalr	-198(ra) # 80000592 <printf>
    printf("\n");
    80002660:	8552                	mv	a0,s4
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	f30080e7          	jalr	-208(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000266a:	16848493          	addi	s1,s1,360
    8000266e:	03248163          	beq	s1,s2,80002690 <procdump+0x98>
    if(p->state == UNUSED)
    80002672:	86a6                	mv	a3,s1
    80002674:	ec04a783          	lw	a5,-320(s1)
    80002678:	dbed                	beqz	a5,8000266a <procdump+0x72>
      state = "???";
    8000267a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000267c:	fcfb6be3          	bltu	s6,a5,80002652 <procdump+0x5a>
    80002680:	1782                	slli	a5,a5,0x20
    80002682:	9381                	srli	a5,a5,0x20
    80002684:	078e                	slli	a5,a5,0x3
    80002686:	97de                	add	a5,a5,s7
    80002688:	6390                	ld	a2,0(a5)
    8000268a:	f661                	bnez	a2,80002652 <procdump+0x5a>
      state = "???";
    8000268c:	864e                	mv	a2,s3
    8000268e:	b7d1                	j	80002652 <procdump+0x5a>
  }
}
    80002690:	60a6                	ld	ra,72(sp)
    80002692:	6406                	ld	s0,64(sp)
    80002694:	74e2                	ld	s1,56(sp)
    80002696:	7942                	ld	s2,48(sp)
    80002698:	79a2                	ld	s3,40(sp)
    8000269a:	7a02                	ld	s4,32(sp)
    8000269c:	6ae2                	ld	s5,24(sp)
    8000269e:	6b42                	ld	s6,16(sp)
    800026a0:	6ba2                	ld	s7,8(sp)
    800026a2:	6161                	addi	sp,sp,80
    800026a4:	8082                	ret

00000000800026a6 <swtch>:
    800026a6:	00153023          	sd	ra,0(a0)
    800026aa:	00253423          	sd	sp,8(a0)
    800026ae:	e900                	sd	s0,16(a0)
    800026b0:	ed04                	sd	s1,24(a0)
    800026b2:	03253023          	sd	s2,32(a0)
    800026b6:	03353423          	sd	s3,40(a0)
    800026ba:	03453823          	sd	s4,48(a0)
    800026be:	03553c23          	sd	s5,56(a0)
    800026c2:	05653023          	sd	s6,64(a0)
    800026c6:	05753423          	sd	s7,72(a0)
    800026ca:	05853823          	sd	s8,80(a0)
    800026ce:	05953c23          	sd	s9,88(a0)
    800026d2:	07a53023          	sd	s10,96(a0)
    800026d6:	07b53423          	sd	s11,104(a0)
    800026da:	0005b083          	ld	ra,0(a1)
    800026de:	0085b103          	ld	sp,8(a1)
    800026e2:	6980                	ld	s0,16(a1)
    800026e4:	6d84                	ld	s1,24(a1)
    800026e6:	0205b903          	ld	s2,32(a1)
    800026ea:	0285b983          	ld	s3,40(a1)
    800026ee:	0305ba03          	ld	s4,48(a1)
    800026f2:	0385ba83          	ld	s5,56(a1)
    800026f6:	0405bb03          	ld	s6,64(a1)
    800026fa:	0485bb83          	ld	s7,72(a1)
    800026fe:	0505bc03          	ld	s8,80(a1)
    80002702:	0585bc83          	ld	s9,88(a1)
    80002706:	0605bd03          	ld	s10,96(a1)
    8000270a:	0685bd83          	ld	s11,104(a1)
    8000270e:	8082                	ret

0000000080002710 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002710:	1141                	addi	sp,sp,-16
    80002712:	e406                	sd	ra,8(sp)
    80002714:	e022                	sd	s0,0(sp)
    80002716:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002718:	00006597          	auipc	a1,0x6
    8000271c:	bf058593          	addi	a1,a1,-1040 # 80008308 <states.1712+0x28>
    80002720:	00015517          	auipc	a0,0x15
    80002724:	04850513          	addi	a0,a0,72 # 80017768 <tickslock>
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	458080e7          	jalr	1112(ra) # 80000b80 <initlock>
}
    80002730:	60a2                	ld	ra,8(sp)
    80002732:	6402                	ld	s0,0(sp)
    80002734:	0141                	addi	sp,sp,16
    80002736:	8082                	ret

0000000080002738 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002738:	1141                	addi	sp,sp,-16
    8000273a:	e422                	sd	s0,8(sp)
    8000273c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273e:	00003797          	auipc	a5,0x3
    80002742:	4e278793          	addi	a5,a5,1250 # 80005c20 <kernelvec>
    80002746:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000274a:	6422                	ld	s0,8(sp)
    8000274c:	0141                	addi	sp,sp,16
    8000274e:	8082                	ret

0000000080002750 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002750:	1141                	addi	sp,sp,-16
    80002752:	e406                	sd	ra,8(sp)
    80002754:	e022                	sd	s0,0(sp)
    80002756:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002758:	fffff097          	auipc	ra,0xfffff
    8000275c:	386080e7          	jalr	902(ra) # 80001ade <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002760:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002764:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002766:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000276a:	00005617          	auipc	a2,0x5
    8000276e:	89660613          	addi	a2,a2,-1898 # 80007000 <_trampoline>
    80002772:	00005697          	auipc	a3,0x5
    80002776:	88e68693          	addi	a3,a3,-1906 # 80007000 <_trampoline>
    8000277a:	8e91                	sub	a3,a3,a2
    8000277c:	040007b7          	lui	a5,0x4000
    80002780:	17fd                	addi	a5,a5,-1
    80002782:	07b2                	slli	a5,a5,0xc
    80002784:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002786:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000278a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000278c:	180026f3          	csrr	a3,satp
    80002790:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002792:	6d38                	ld	a4,88(a0)
    80002794:	6134                	ld	a3,64(a0)
    80002796:	6585                	lui	a1,0x1
    80002798:	96ae                	add	a3,a3,a1
    8000279a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000279c:	6d38                	ld	a4,88(a0)
    8000279e:	00000697          	auipc	a3,0x0
    800027a2:	13868693          	addi	a3,a3,312 # 800028d6 <usertrap>
    800027a6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027a8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027aa:	8692                	mv	a3,tp
    800027ac:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ae:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027b2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027b6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ba:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027be:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027c0:	6f18                	ld	a4,24(a4)
    800027c2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027c6:	692c                	ld	a1,80(a0)
    800027c8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027ca:	00005717          	auipc	a4,0x5
    800027ce:	8c670713          	addi	a4,a4,-1850 # 80007090 <userret>
    800027d2:	8f11                	sub	a4,a4,a2
    800027d4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027d6:	577d                	li	a4,-1
    800027d8:	177e                	slli	a4,a4,0x3f
    800027da:	8dd9                	or	a1,a1,a4
    800027dc:	02000537          	lui	a0,0x2000
    800027e0:	157d                	addi	a0,a0,-1
    800027e2:	0536                	slli	a0,a0,0xd
    800027e4:	9782                	jalr	a5
}
    800027e6:	60a2                	ld	ra,8(sp)
    800027e8:	6402                	ld	s0,0(sp)
    800027ea:	0141                	addi	sp,sp,16
    800027ec:	8082                	ret

00000000800027ee <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027ee:	1101                	addi	sp,sp,-32
    800027f0:	ec06                	sd	ra,24(sp)
    800027f2:	e822                	sd	s0,16(sp)
    800027f4:	e426                	sd	s1,8(sp)
    800027f6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027f8:	00015497          	auipc	s1,0x15
    800027fc:	f7048493          	addi	s1,s1,-144 # 80017768 <tickslock>
    80002800:	8526                	mv	a0,s1
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	40e080e7          	jalr	1038(ra) # 80000c10 <acquire>
  ticks++;
    8000280a:	00007517          	auipc	a0,0x7
    8000280e:	81650513          	addi	a0,a0,-2026 # 80009020 <ticks>
    80002812:	411c                	lw	a5,0(a0)
    80002814:	2785                	addiw	a5,a5,1
    80002816:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002818:	00000097          	auipc	ra,0x0
    8000281c:	c58080e7          	jalr	-936(ra) # 80002470 <wakeup>
  release(&tickslock);
    80002820:	8526                	mv	a0,s1
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	4a2080e7          	jalr	1186(ra) # 80000cc4 <release>
}
    8000282a:	60e2                	ld	ra,24(sp)
    8000282c:	6442                	ld	s0,16(sp)
    8000282e:	64a2                	ld	s1,8(sp)
    80002830:	6105                	addi	sp,sp,32
    80002832:	8082                	ret

0000000080002834 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002834:	1101                	addi	sp,sp,-32
    80002836:	ec06                	sd	ra,24(sp)
    80002838:	e822                	sd	s0,16(sp)
    8000283a:	e426                	sd	s1,8(sp)
    8000283c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000283e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002842:	00074d63          	bltz	a4,8000285c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002846:	57fd                	li	a5,-1
    80002848:	17fe                	slli	a5,a5,0x3f
    8000284a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000284c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000284e:	06f70363          	beq	a4,a5,800028b4 <devintr+0x80>
  }
}
    80002852:	60e2                	ld	ra,24(sp)
    80002854:	6442                	ld	s0,16(sp)
    80002856:	64a2                	ld	s1,8(sp)
    80002858:	6105                	addi	sp,sp,32
    8000285a:	8082                	ret
     (scause & 0xff) == 9){
    8000285c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002860:	46a5                	li	a3,9
    80002862:	fed792e3          	bne	a5,a3,80002846 <devintr+0x12>
    int irq = plic_claim();
    80002866:	00003097          	auipc	ra,0x3
    8000286a:	4c2080e7          	jalr	1218(ra) # 80005d28 <plic_claim>
    8000286e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002870:	47a9                	li	a5,10
    80002872:	02f50763          	beq	a0,a5,800028a0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002876:	4785                	li	a5,1
    80002878:	02f50963          	beq	a0,a5,800028aa <devintr+0x76>
    return 1;
    8000287c:	4505                	li	a0,1
    } else if(irq){
    8000287e:	d8f1                	beqz	s1,80002852 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002880:	85a6                	mv	a1,s1
    80002882:	00006517          	auipc	a0,0x6
    80002886:	a8e50513          	addi	a0,a0,-1394 # 80008310 <states.1712+0x30>
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	d08080e7          	jalr	-760(ra) # 80000592 <printf>
      plic_complete(irq);
    80002892:	8526                	mv	a0,s1
    80002894:	00003097          	auipc	ra,0x3
    80002898:	4b8080e7          	jalr	1208(ra) # 80005d4c <plic_complete>
    return 1;
    8000289c:	4505                	li	a0,1
    8000289e:	bf55                	j	80002852 <devintr+0x1e>
      uartintr();
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	134080e7          	jalr	308(ra) # 800009d4 <uartintr>
    800028a8:	b7ed                	j	80002892 <devintr+0x5e>
      virtio_disk_intr();
    800028aa:	00004097          	auipc	ra,0x4
    800028ae:	93c080e7          	jalr	-1732(ra) # 800061e6 <virtio_disk_intr>
    800028b2:	b7c5                	j	80002892 <devintr+0x5e>
    if(cpuid() == 0){
    800028b4:	fffff097          	auipc	ra,0xfffff
    800028b8:	1fe080e7          	jalr	510(ra) # 80001ab2 <cpuid>
    800028bc:	c901                	beqz	a0,800028cc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028be:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028c2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028c4:	14479073          	csrw	sip,a5
    return 2;
    800028c8:	4509                	li	a0,2
    800028ca:	b761                	j	80002852 <devintr+0x1e>
      clockintr();
    800028cc:	00000097          	auipc	ra,0x0
    800028d0:	f22080e7          	jalr	-222(ra) # 800027ee <clockintr>
    800028d4:	b7ed                	j	800028be <devintr+0x8a>

00000000800028d6 <usertrap>:
{
    800028d6:	1101                	addi	sp,sp,-32
    800028d8:	ec06                	sd	ra,24(sp)
    800028da:	e822                	sd	s0,16(sp)
    800028dc:	e426                	sd	s1,8(sp)
    800028de:	e04a                	sd	s2,0(sp)
    800028e0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028e6:	1007f793          	andi	a5,a5,256
    800028ea:	e3ad                	bnez	a5,8000294c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ec:	00003797          	auipc	a5,0x3
    800028f0:	33478793          	addi	a5,a5,820 # 80005c20 <kernelvec>
    800028f4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028f8:	fffff097          	auipc	ra,0xfffff
    800028fc:	1e6080e7          	jalr	486(ra) # 80001ade <myproc>
    80002900:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002902:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002904:	14102773          	csrr	a4,sepc
    80002908:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000290a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000290e:	47a1                	li	a5,8
    80002910:	04f71c63          	bne	a4,a5,80002968 <usertrap+0x92>
    if(p->killed)
    80002914:	591c                	lw	a5,48(a0)
    80002916:	e3b9                	bnez	a5,8000295c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002918:	6cb8                	ld	a4,88(s1)
    8000291a:	6f1c                	ld	a5,24(a4)
    8000291c:	0791                	addi	a5,a5,4
    8000291e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002920:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002924:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002928:	10079073          	csrw	sstatus,a5
    syscall();
    8000292c:	00000097          	auipc	ra,0x0
    80002930:	2e0080e7          	jalr	736(ra) # 80002c0c <syscall>
  if(p->killed)
    80002934:	589c                	lw	a5,48(s1)
    80002936:	ebc1                	bnez	a5,800029c6 <usertrap+0xf0>
  usertrapret();
    80002938:	00000097          	auipc	ra,0x0
    8000293c:	e18080e7          	jalr	-488(ra) # 80002750 <usertrapret>
}
    80002940:	60e2                	ld	ra,24(sp)
    80002942:	6442                	ld	s0,16(sp)
    80002944:	64a2                	ld	s1,8(sp)
    80002946:	6902                	ld	s2,0(sp)
    80002948:	6105                	addi	sp,sp,32
    8000294a:	8082                	ret
    panic("usertrap: not from user mode");
    8000294c:	00006517          	auipc	a0,0x6
    80002950:	9e450513          	addi	a0,a0,-1564 # 80008330 <states.1712+0x50>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	bf4080e7          	jalr	-1036(ra) # 80000548 <panic>
      exit(-1);
    8000295c:	557d                	li	a0,-1
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	846080e7          	jalr	-1978(ra) # 800021a4 <exit>
    80002966:	bf4d                	j	80002918 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002968:	00000097          	auipc	ra,0x0
    8000296c:	ecc080e7          	jalr	-308(ra) # 80002834 <devintr>
    80002970:	892a                	mv	s2,a0
    80002972:	c501                	beqz	a0,8000297a <usertrap+0xa4>
  if(p->killed)
    80002974:	589c                	lw	a5,48(s1)
    80002976:	c3a1                	beqz	a5,800029b6 <usertrap+0xe0>
    80002978:	a815                	j	800029ac <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000297a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000297e:	5c90                	lw	a2,56(s1)
    80002980:	00006517          	auipc	a0,0x6
    80002984:	9d050513          	addi	a0,a0,-1584 # 80008350 <states.1712+0x70>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	c0a080e7          	jalr	-1014(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002990:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002994:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	9e850513          	addi	a0,a0,-1560 # 80008380 <states.1712+0xa0>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	bf2080e7          	jalr	-1038(ra) # 80000592 <printf>
    p->killed = 1;
    800029a8:	4785                	li	a5,1
    800029aa:	d89c                	sw	a5,48(s1)
    exit(-1);
    800029ac:	557d                	li	a0,-1
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	7f6080e7          	jalr	2038(ra) # 800021a4 <exit>
  if(which_dev == 2)
    800029b6:	4789                	li	a5,2
    800029b8:	f8f910e3          	bne	s2,a5,80002938 <usertrap+0x62>
    yield();
    800029bc:	00000097          	auipc	ra,0x0
    800029c0:	8f2080e7          	jalr	-1806(ra) # 800022ae <yield>
    800029c4:	bf95                	j	80002938 <usertrap+0x62>
  int which_dev = 0;
    800029c6:	4901                	li	s2,0
    800029c8:	b7d5                	j	800029ac <usertrap+0xd6>

00000000800029ca <kerneltrap>:
{
    800029ca:	7179                	addi	sp,sp,-48
    800029cc:	f406                	sd	ra,40(sp)
    800029ce:	f022                	sd	s0,32(sp)
    800029d0:	ec26                	sd	s1,24(sp)
    800029d2:	e84a                	sd	s2,16(sp)
    800029d4:	e44e                	sd	s3,8(sp)
    800029d6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029d8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029dc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029e4:	1004f793          	andi	a5,s1,256
    800029e8:	cb85                	beqz	a5,80002a18 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029ee:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029f0:	ef85                	bnez	a5,80002a28 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	e42080e7          	jalr	-446(ra) # 80002834 <devintr>
    800029fa:	cd1d                	beqz	a0,80002a38 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029fc:	4789                	li	a5,2
    800029fe:	06f50a63          	beq	a0,a5,80002a72 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a02:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a06:	10049073          	csrw	sstatus,s1
}
    80002a0a:	70a2                	ld	ra,40(sp)
    80002a0c:	7402                	ld	s0,32(sp)
    80002a0e:	64e2                	ld	s1,24(sp)
    80002a10:	6942                	ld	s2,16(sp)
    80002a12:	69a2                	ld	s3,8(sp)
    80002a14:	6145                	addi	sp,sp,48
    80002a16:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a18:	00006517          	auipc	a0,0x6
    80002a1c:	98850513          	addi	a0,a0,-1656 # 800083a0 <states.1712+0xc0>
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	b28080e7          	jalr	-1240(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a28:	00006517          	auipc	a0,0x6
    80002a2c:	9a050513          	addi	a0,a0,-1632 # 800083c8 <states.1712+0xe8>
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	b18080e7          	jalr	-1256(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a38:	85ce                	mv	a1,s3
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	9ae50513          	addi	a0,a0,-1618 # 800083e8 <states.1712+0x108>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b50080e7          	jalr	-1200(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a4a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a4e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	9a650513          	addi	a0,a0,-1626 # 800083f8 <states.1712+0x118>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	b38080e7          	jalr	-1224(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	9ae50513          	addi	a0,a0,-1618 # 80008410 <states.1712+0x130>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	ade080e7          	jalr	-1314(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a72:	fffff097          	auipc	ra,0xfffff
    80002a76:	06c080e7          	jalr	108(ra) # 80001ade <myproc>
    80002a7a:	d541                	beqz	a0,80002a02 <kerneltrap+0x38>
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	062080e7          	jalr	98(ra) # 80001ade <myproc>
    80002a84:	4d18                	lw	a4,24(a0)
    80002a86:	478d                	li	a5,3
    80002a88:	f6f71de3          	bne	a4,a5,80002a02 <kerneltrap+0x38>
    yield();
    80002a8c:	00000097          	auipc	ra,0x0
    80002a90:	822080e7          	jalr	-2014(ra) # 800022ae <yield>
    80002a94:	b7bd                	j	80002a02 <kerneltrap+0x38>

0000000080002a96 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a96:	1101                	addi	sp,sp,-32
    80002a98:	ec06                	sd	ra,24(sp)
    80002a9a:	e822                	sd	s0,16(sp)
    80002a9c:	e426                	sd	s1,8(sp)
    80002a9e:	1000                	addi	s0,sp,32
    80002aa0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	03c080e7          	jalr	60(ra) # 80001ade <myproc>
  switch (n) {
    80002aaa:	4795                	li	a5,5
    80002aac:	0497e163          	bltu	a5,s1,80002aee <argraw+0x58>
    80002ab0:	048a                	slli	s1,s1,0x2
    80002ab2:	00006717          	auipc	a4,0x6
    80002ab6:	99670713          	addi	a4,a4,-1642 # 80008448 <states.1712+0x168>
    80002aba:	94ba                	add	s1,s1,a4
    80002abc:	409c                	lw	a5,0(s1)
    80002abe:	97ba                	add	a5,a5,a4
    80002ac0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ac2:	6d3c                	ld	a5,88(a0)
    80002ac4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ac6:	60e2                	ld	ra,24(sp)
    80002ac8:	6442                	ld	s0,16(sp)
    80002aca:	64a2                	ld	s1,8(sp)
    80002acc:	6105                	addi	sp,sp,32
    80002ace:	8082                	ret
    return p->trapframe->a1;
    80002ad0:	6d3c                	ld	a5,88(a0)
    80002ad2:	7fa8                	ld	a0,120(a5)
    80002ad4:	bfcd                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a2;
    80002ad6:	6d3c                	ld	a5,88(a0)
    80002ad8:	63c8                	ld	a0,128(a5)
    80002ada:	b7f5                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a3;
    80002adc:	6d3c                	ld	a5,88(a0)
    80002ade:	67c8                	ld	a0,136(a5)
    80002ae0:	b7dd                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a4;
    80002ae2:	6d3c                	ld	a5,88(a0)
    80002ae4:	6bc8                	ld	a0,144(a5)
    80002ae6:	b7c5                	j	80002ac6 <argraw+0x30>
    return p->trapframe->a5;
    80002ae8:	6d3c                	ld	a5,88(a0)
    80002aea:	6fc8                	ld	a0,152(a5)
    80002aec:	bfe9                	j	80002ac6 <argraw+0x30>
  panic("argraw");
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	93250513          	addi	a0,a0,-1742 # 80008420 <states.1712+0x140>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a52080e7          	jalr	-1454(ra) # 80000548 <panic>

0000000080002afe <fetchaddr>:
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	e04a                	sd	s2,0(sp)
    80002b08:	1000                	addi	s0,sp,32
    80002b0a:	84aa                	mv	s1,a0
    80002b0c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b0e:	fffff097          	auipc	ra,0xfffff
    80002b12:	fd0080e7          	jalr	-48(ra) # 80001ade <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b16:	653c                	ld	a5,72(a0)
    80002b18:	02f4f863          	bgeu	s1,a5,80002b48 <fetchaddr+0x4a>
    80002b1c:	00848713          	addi	a4,s1,8
    80002b20:	02e7e663          	bltu	a5,a4,80002b4c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b24:	46a1                	li	a3,8
    80002b26:	8626                	mv	a2,s1
    80002b28:	85ca                	mv	a1,s2
    80002b2a:	6928                	ld	a0,80(a0)
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	d32080e7          	jalr	-718(ra) # 8000185e <copyin>
    80002b34:	00a03533          	snez	a0,a0
    80002b38:	40a00533          	neg	a0,a0
}
    80002b3c:	60e2                	ld	ra,24(sp)
    80002b3e:	6442                	ld	s0,16(sp)
    80002b40:	64a2                	ld	s1,8(sp)
    80002b42:	6902                	ld	s2,0(sp)
    80002b44:	6105                	addi	sp,sp,32
    80002b46:	8082                	ret
    return -1;
    80002b48:	557d                	li	a0,-1
    80002b4a:	bfcd                	j	80002b3c <fetchaddr+0x3e>
    80002b4c:	557d                	li	a0,-1
    80002b4e:	b7fd                	j	80002b3c <fetchaddr+0x3e>

0000000080002b50 <fetchstr>:
{
    80002b50:	7179                	addi	sp,sp,-48
    80002b52:	f406                	sd	ra,40(sp)
    80002b54:	f022                	sd	s0,32(sp)
    80002b56:	ec26                	sd	s1,24(sp)
    80002b58:	e84a                	sd	s2,16(sp)
    80002b5a:	e44e                	sd	s3,8(sp)
    80002b5c:	1800                	addi	s0,sp,48
    80002b5e:	892a                	mv	s2,a0
    80002b60:	84ae                	mv	s1,a1
    80002b62:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b64:	fffff097          	auipc	ra,0xfffff
    80002b68:	f7a080e7          	jalr	-134(ra) # 80001ade <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b6c:	86ce                	mv	a3,s3
    80002b6e:	864a                	mv	a2,s2
    80002b70:	85a6                	mv	a1,s1
    80002b72:	6928                	ld	a0,80(a0)
    80002b74:	fffff097          	auipc	ra,0xfffff
    80002b78:	d76080e7          	jalr	-650(ra) # 800018ea <copyinstr>
  if(err < 0)
    80002b7c:	00054763          	bltz	a0,80002b8a <fetchstr+0x3a>
  return strlen(buf);
    80002b80:	8526                	mv	a0,s1
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	312080e7          	jalr	786(ra) # 80000e94 <strlen>
}
    80002b8a:	70a2                	ld	ra,40(sp)
    80002b8c:	7402                	ld	s0,32(sp)
    80002b8e:	64e2                	ld	s1,24(sp)
    80002b90:	6942                	ld	s2,16(sp)
    80002b92:	69a2                	ld	s3,8(sp)
    80002b94:	6145                	addi	sp,sp,48
    80002b96:	8082                	ret

0000000080002b98 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b98:	1101                	addi	sp,sp,-32
    80002b9a:	ec06                	sd	ra,24(sp)
    80002b9c:	e822                	sd	s0,16(sp)
    80002b9e:	e426                	sd	s1,8(sp)
    80002ba0:	1000                	addi	s0,sp,32
    80002ba2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ba4:	00000097          	auipc	ra,0x0
    80002ba8:	ef2080e7          	jalr	-270(ra) # 80002a96 <argraw>
    80002bac:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bae:	4501                	li	a0,0
    80002bb0:	60e2                	ld	ra,24(sp)
    80002bb2:	6442                	ld	s0,16(sp)
    80002bb4:	64a2                	ld	s1,8(sp)
    80002bb6:	6105                	addi	sp,sp,32
    80002bb8:	8082                	ret

0000000080002bba <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bba:	1101                	addi	sp,sp,-32
    80002bbc:	ec06                	sd	ra,24(sp)
    80002bbe:	e822                	sd	s0,16(sp)
    80002bc0:	e426                	sd	s1,8(sp)
    80002bc2:	1000                	addi	s0,sp,32
    80002bc4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	ed0080e7          	jalr	-304(ra) # 80002a96 <argraw>
    80002bce:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bd0:	4501                	li	a0,0
    80002bd2:	60e2                	ld	ra,24(sp)
    80002bd4:	6442                	ld	s0,16(sp)
    80002bd6:	64a2                	ld	s1,8(sp)
    80002bd8:	6105                	addi	sp,sp,32
    80002bda:	8082                	ret

0000000080002bdc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bdc:	1101                	addi	sp,sp,-32
    80002bde:	ec06                	sd	ra,24(sp)
    80002be0:	e822                	sd	s0,16(sp)
    80002be2:	e426                	sd	s1,8(sp)
    80002be4:	e04a                	sd	s2,0(sp)
    80002be6:	1000                	addi	s0,sp,32
    80002be8:	84ae                	mv	s1,a1
    80002bea:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bec:	00000097          	auipc	ra,0x0
    80002bf0:	eaa080e7          	jalr	-342(ra) # 80002a96 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bf4:	864a                	mv	a2,s2
    80002bf6:	85a6                	mv	a1,s1
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	f58080e7          	jalr	-168(ra) # 80002b50 <fetchstr>
}
    80002c00:	60e2                	ld	ra,24(sp)
    80002c02:	6442                	ld	s0,16(sp)
    80002c04:	64a2                	ld	s1,8(sp)
    80002c06:	6902                	ld	s2,0(sp)
    80002c08:	6105                	addi	sp,sp,32
    80002c0a:	8082                	ret

0000000080002c0c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c0c:	1101                	addi	sp,sp,-32
    80002c0e:	ec06                	sd	ra,24(sp)
    80002c10:	e822                	sd	s0,16(sp)
    80002c12:	e426                	sd	s1,8(sp)
    80002c14:	e04a                	sd	s2,0(sp)
    80002c16:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	ec6080e7          	jalr	-314(ra) # 80001ade <myproc>
    80002c20:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c22:	05853903          	ld	s2,88(a0)
    80002c26:	0a893783          	ld	a5,168(s2)
    80002c2a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c2e:	37fd                	addiw	a5,a5,-1
    80002c30:	4751                	li	a4,20
    80002c32:	00f76f63          	bltu	a4,a5,80002c50 <syscall+0x44>
    80002c36:	00369713          	slli	a4,a3,0x3
    80002c3a:	00006797          	auipc	a5,0x6
    80002c3e:	82678793          	addi	a5,a5,-2010 # 80008460 <syscalls>
    80002c42:	97ba                	add	a5,a5,a4
    80002c44:	639c                	ld	a5,0(a5)
    80002c46:	c789                	beqz	a5,80002c50 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c48:	9782                	jalr	a5
    80002c4a:	06a93823          	sd	a0,112(s2)
    80002c4e:	a839                	j	80002c6c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c50:	15848613          	addi	a2,s1,344
    80002c54:	5c8c                	lw	a1,56(s1)
    80002c56:	00005517          	auipc	a0,0x5
    80002c5a:	7d250513          	addi	a0,a0,2002 # 80008428 <states.1712+0x148>
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	934080e7          	jalr	-1740(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c66:	6cbc                	ld	a5,88(s1)
    80002c68:	577d                	li	a4,-1
    80002c6a:	fbb8                	sd	a4,112(a5)
  }
}
    80002c6c:	60e2                	ld	ra,24(sp)
    80002c6e:	6442                	ld	s0,16(sp)
    80002c70:	64a2                	ld	s1,8(sp)
    80002c72:	6902                	ld	s2,0(sp)
    80002c74:	6105                	addi	sp,sp,32
    80002c76:	8082                	ret

0000000080002c78 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c78:	1101                	addi	sp,sp,-32
    80002c7a:	ec06                	sd	ra,24(sp)
    80002c7c:	e822                	sd	s0,16(sp)
    80002c7e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c80:	fec40593          	addi	a1,s0,-20
    80002c84:	4501                	li	a0,0
    80002c86:	00000097          	auipc	ra,0x0
    80002c8a:	f12080e7          	jalr	-238(ra) # 80002b98 <argint>
    return -1;
    80002c8e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c90:	00054963          	bltz	a0,80002ca2 <sys_exit+0x2a>
  exit(n);
    80002c94:	fec42503          	lw	a0,-20(s0)
    80002c98:	fffff097          	auipc	ra,0xfffff
    80002c9c:	50c080e7          	jalr	1292(ra) # 800021a4 <exit>
  return 0;  // not reached
    80002ca0:	4781                	li	a5,0
}
    80002ca2:	853e                	mv	a0,a5
    80002ca4:	60e2                	ld	ra,24(sp)
    80002ca6:	6442                	ld	s0,16(sp)
    80002ca8:	6105                	addi	sp,sp,32
    80002caa:	8082                	ret

0000000080002cac <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cac:	1141                	addi	sp,sp,-16
    80002cae:	e406                	sd	ra,8(sp)
    80002cb0:	e022                	sd	s0,0(sp)
    80002cb2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	e2a080e7          	jalr	-470(ra) # 80001ade <myproc>
}
    80002cbc:	5d08                	lw	a0,56(a0)
    80002cbe:	60a2                	ld	ra,8(sp)
    80002cc0:	6402                	ld	s0,0(sp)
    80002cc2:	0141                	addi	sp,sp,16
    80002cc4:	8082                	ret

0000000080002cc6 <sys_fork>:

uint64
sys_fork(void)
{
    80002cc6:	1141                	addi	sp,sp,-16
    80002cc8:	e406                	sd	ra,8(sp)
    80002cca:	e022                	sd	s0,0(sp)
    80002ccc:	0800                	addi	s0,sp,16
  return fork();
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	1d0080e7          	jalr	464(ra) # 80001e9e <fork>
}
    80002cd6:	60a2                	ld	ra,8(sp)
    80002cd8:	6402                	ld	s0,0(sp)
    80002cda:	0141                	addi	sp,sp,16
    80002cdc:	8082                	ret

0000000080002cde <sys_wait>:

uint64
sys_wait(void)
{
    80002cde:	1101                	addi	sp,sp,-32
    80002ce0:	ec06                	sd	ra,24(sp)
    80002ce2:	e822                	sd	s0,16(sp)
    80002ce4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ce6:	fe840593          	addi	a1,s0,-24
    80002cea:	4501                	li	a0,0
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	ece080e7          	jalr	-306(ra) # 80002bba <argaddr>
    80002cf4:	87aa                	mv	a5,a0
    return -1;
    80002cf6:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cf8:	0007c863          	bltz	a5,80002d08 <sys_wait+0x2a>
  return wait(p);
    80002cfc:	fe843503          	ld	a0,-24(s0)
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	668080e7          	jalr	1640(ra) # 80002368 <wait>
}
    80002d08:	60e2                	ld	ra,24(sp)
    80002d0a:	6442                	ld	s0,16(sp)
    80002d0c:	6105                	addi	sp,sp,32
    80002d0e:	8082                	ret

0000000080002d10 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d10:	7179                	addi	sp,sp,-48
    80002d12:	f406                	sd	ra,40(sp)
    80002d14:	f022                	sd	s0,32(sp)
    80002d16:	ec26                	sd	s1,24(sp)
    80002d18:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d1a:	fdc40593          	addi	a1,s0,-36
    80002d1e:	4501                	li	a0,0
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	e78080e7          	jalr	-392(ra) # 80002b98 <argint>
    80002d28:	87aa                	mv	a5,a0
    return -1;
    80002d2a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d2c:	0207c063          	bltz	a5,80002d4c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	dae080e7          	jalr	-594(ra) # 80001ade <myproc>
    80002d38:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d3a:	fdc42503          	lw	a0,-36(s0)
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	0ec080e7          	jalr	236(ra) # 80001e2a <growproc>
    80002d46:	00054863          	bltz	a0,80002d56 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d4a:	8526                	mv	a0,s1
}
    80002d4c:	70a2                	ld	ra,40(sp)
    80002d4e:	7402                	ld	s0,32(sp)
    80002d50:	64e2                	ld	s1,24(sp)
    80002d52:	6145                	addi	sp,sp,48
    80002d54:	8082                	ret
    return -1;
    80002d56:	557d                	li	a0,-1
    80002d58:	bfd5                	j	80002d4c <sys_sbrk+0x3c>

0000000080002d5a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d5a:	7139                	addi	sp,sp,-64
    80002d5c:	fc06                	sd	ra,56(sp)
    80002d5e:	f822                	sd	s0,48(sp)
    80002d60:	f426                	sd	s1,40(sp)
    80002d62:	f04a                	sd	s2,32(sp)
    80002d64:	ec4e                	sd	s3,24(sp)
    80002d66:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d68:	fcc40593          	addi	a1,s0,-52
    80002d6c:	4501                	li	a0,0
    80002d6e:	00000097          	auipc	ra,0x0
    80002d72:	e2a080e7          	jalr	-470(ra) # 80002b98 <argint>
    return -1;
    80002d76:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d78:	06054563          	bltz	a0,80002de2 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d7c:	00015517          	auipc	a0,0x15
    80002d80:	9ec50513          	addi	a0,a0,-1556 # 80017768 <tickslock>
    80002d84:	ffffe097          	auipc	ra,0xffffe
    80002d88:	e8c080e7          	jalr	-372(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002d8c:	00006917          	auipc	s2,0x6
    80002d90:	29492903          	lw	s2,660(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d94:	fcc42783          	lw	a5,-52(s0)
    80002d98:	cf85                	beqz	a5,80002dd0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d9a:	00015997          	auipc	s3,0x15
    80002d9e:	9ce98993          	addi	s3,s3,-1586 # 80017768 <tickslock>
    80002da2:	00006497          	auipc	s1,0x6
    80002da6:	27e48493          	addi	s1,s1,638 # 80009020 <ticks>
    if(myproc()->killed){
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	d34080e7          	jalr	-716(ra) # 80001ade <myproc>
    80002db2:	591c                	lw	a5,48(a0)
    80002db4:	ef9d                	bnez	a5,80002df2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002db6:	85ce                	mv	a1,s3
    80002db8:	8526                	mv	a0,s1
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	530080e7          	jalr	1328(ra) # 800022ea <sleep>
  while(ticks - ticks0 < n){
    80002dc2:	409c                	lw	a5,0(s1)
    80002dc4:	412787bb          	subw	a5,a5,s2
    80002dc8:	fcc42703          	lw	a4,-52(s0)
    80002dcc:	fce7efe3          	bltu	a5,a4,80002daa <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dd0:	00015517          	auipc	a0,0x15
    80002dd4:	99850513          	addi	a0,a0,-1640 # 80017768 <tickslock>
    80002dd8:	ffffe097          	auipc	ra,0xffffe
    80002ddc:	eec080e7          	jalr	-276(ra) # 80000cc4 <release>
  return 0;
    80002de0:	4781                	li	a5,0
}
    80002de2:	853e                	mv	a0,a5
    80002de4:	70e2                	ld	ra,56(sp)
    80002de6:	7442                	ld	s0,48(sp)
    80002de8:	74a2                	ld	s1,40(sp)
    80002dea:	7902                	ld	s2,32(sp)
    80002dec:	69e2                	ld	s3,24(sp)
    80002dee:	6121                	addi	sp,sp,64
    80002df0:	8082                	ret
      release(&tickslock);
    80002df2:	00015517          	auipc	a0,0x15
    80002df6:	97650513          	addi	a0,a0,-1674 # 80017768 <tickslock>
    80002dfa:	ffffe097          	auipc	ra,0xffffe
    80002dfe:	eca080e7          	jalr	-310(ra) # 80000cc4 <release>
      return -1;
    80002e02:	57fd                	li	a5,-1
    80002e04:	bff9                	j	80002de2 <sys_sleep+0x88>

0000000080002e06 <sys_kill>:

uint64
sys_kill(void)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e0e:	fec40593          	addi	a1,s0,-20
    80002e12:	4501                	li	a0,0
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	d84080e7          	jalr	-636(ra) # 80002b98 <argint>
    80002e1c:	87aa                	mv	a5,a0
    return -1;
    80002e1e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e20:	0007c863          	bltz	a5,80002e30 <sys_kill+0x2a>
  return kill(pid);
    80002e24:	fec42503          	lw	a0,-20(s0)
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	6b2080e7          	jalr	1714(ra) # 800024da <kill>
}
    80002e30:	60e2                	ld	ra,24(sp)
    80002e32:	6442                	ld	s0,16(sp)
    80002e34:	6105                	addi	sp,sp,32
    80002e36:	8082                	ret

0000000080002e38 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e38:	1101                	addi	sp,sp,-32
    80002e3a:	ec06                	sd	ra,24(sp)
    80002e3c:	e822                	sd	s0,16(sp)
    80002e3e:	e426                	sd	s1,8(sp)
    80002e40:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e42:	00015517          	auipc	a0,0x15
    80002e46:	92650513          	addi	a0,a0,-1754 # 80017768 <tickslock>
    80002e4a:	ffffe097          	auipc	ra,0xffffe
    80002e4e:	dc6080e7          	jalr	-570(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002e52:	00006497          	auipc	s1,0x6
    80002e56:	1ce4a483          	lw	s1,462(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e5a:	00015517          	auipc	a0,0x15
    80002e5e:	90e50513          	addi	a0,a0,-1778 # 80017768 <tickslock>
    80002e62:	ffffe097          	auipc	ra,0xffffe
    80002e66:	e62080e7          	jalr	-414(ra) # 80000cc4 <release>
  return xticks;
}
    80002e6a:	02049513          	slli	a0,s1,0x20
    80002e6e:	9101                	srli	a0,a0,0x20
    80002e70:	60e2                	ld	ra,24(sp)
    80002e72:	6442                	ld	s0,16(sp)
    80002e74:	64a2                	ld	s1,8(sp)
    80002e76:	6105                	addi	sp,sp,32
    80002e78:	8082                	ret

0000000080002e7a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e7a:	7179                	addi	sp,sp,-48
    80002e7c:	f406                	sd	ra,40(sp)
    80002e7e:	f022                	sd	s0,32(sp)
    80002e80:	ec26                	sd	s1,24(sp)
    80002e82:	e84a                	sd	s2,16(sp)
    80002e84:	e44e                	sd	s3,8(sp)
    80002e86:	e052                	sd	s4,0(sp)
    80002e88:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e8a:	00005597          	auipc	a1,0x5
    80002e8e:	68658593          	addi	a1,a1,1670 # 80008510 <syscalls+0xb0>
    80002e92:	00015517          	auipc	a0,0x15
    80002e96:	8ee50513          	addi	a0,a0,-1810 # 80017780 <bcache>
    80002e9a:	ffffe097          	auipc	ra,0xffffe
    80002e9e:	ce6080e7          	jalr	-794(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ea2:	0001d797          	auipc	a5,0x1d
    80002ea6:	8de78793          	addi	a5,a5,-1826 # 8001f780 <bcache+0x8000>
    80002eaa:	0001d717          	auipc	a4,0x1d
    80002eae:	b3e70713          	addi	a4,a4,-1218 # 8001f9e8 <bcache+0x8268>
    80002eb2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002eb6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eba:	00015497          	auipc	s1,0x15
    80002ebe:	8de48493          	addi	s1,s1,-1826 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002ec2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ec4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ec6:	00005a17          	auipc	s4,0x5
    80002eca:	652a0a13          	addi	s4,s4,1618 # 80008518 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002ece:	2b893783          	ld	a5,696(s2)
    80002ed2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ed4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ed8:	85d2                	mv	a1,s4
    80002eda:	01048513          	addi	a0,s1,16
    80002ede:	00001097          	auipc	ra,0x1
    80002ee2:	4ac080e7          	jalr	1196(ra) # 8000438a <initsleeplock>
    bcache.head.next->prev = b;
    80002ee6:	2b893783          	ld	a5,696(s2)
    80002eea:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002eec:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ef0:	45848493          	addi	s1,s1,1112
    80002ef4:	fd349de3          	bne	s1,s3,80002ece <binit+0x54>
  }
}
    80002ef8:	70a2                	ld	ra,40(sp)
    80002efa:	7402                	ld	s0,32(sp)
    80002efc:	64e2                	ld	s1,24(sp)
    80002efe:	6942                	ld	s2,16(sp)
    80002f00:	69a2                	ld	s3,8(sp)
    80002f02:	6a02                	ld	s4,0(sp)
    80002f04:	6145                	addi	sp,sp,48
    80002f06:	8082                	ret

0000000080002f08 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f08:	7179                	addi	sp,sp,-48
    80002f0a:	f406                	sd	ra,40(sp)
    80002f0c:	f022                	sd	s0,32(sp)
    80002f0e:	ec26                	sd	s1,24(sp)
    80002f10:	e84a                	sd	s2,16(sp)
    80002f12:	e44e                	sd	s3,8(sp)
    80002f14:	1800                	addi	s0,sp,48
    80002f16:	89aa                	mv	s3,a0
    80002f18:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f1a:	00015517          	auipc	a0,0x15
    80002f1e:	86650513          	addi	a0,a0,-1946 # 80017780 <bcache>
    80002f22:	ffffe097          	auipc	ra,0xffffe
    80002f26:	cee080e7          	jalr	-786(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f2a:	0001d497          	auipc	s1,0x1d
    80002f2e:	b0e4b483          	ld	s1,-1266(s1) # 8001fa38 <bcache+0x82b8>
    80002f32:	0001d797          	auipc	a5,0x1d
    80002f36:	ab678793          	addi	a5,a5,-1354 # 8001f9e8 <bcache+0x8268>
    80002f3a:	02f48f63          	beq	s1,a5,80002f78 <bread+0x70>
    80002f3e:	873e                	mv	a4,a5
    80002f40:	a021                	j	80002f48 <bread+0x40>
    80002f42:	68a4                	ld	s1,80(s1)
    80002f44:	02e48a63          	beq	s1,a4,80002f78 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f48:	449c                	lw	a5,8(s1)
    80002f4a:	ff379ce3          	bne	a5,s3,80002f42 <bread+0x3a>
    80002f4e:	44dc                	lw	a5,12(s1)
    80002f50:	ff2799e3          	bne	a5,s2,80002f42 <bread+0x3a>
      b->refcnt++;
    80002f54:	40bc                	lw	a5,64(s1)
    80002f56:	2785                	addiw	a5,a5,1
    80002f58:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f5a:	00015517          	auipc	a0,0x15
    80002f5e:	82650513          	addi	a0,a0,-2010 # 80017780 <bcache>
    80002f62:	ffffe097          	auipc	ra,0xffffe
    80002f66:	d62080e7          	jalr	-670(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002f6a:	01048513          	addi	a0,s1,16
    80002f6e:	00001097          	auipc	ra,0x1
    80002f72:	456080e7          	jalr	1110(ra) # 800043c4 <acquiresleep>
      return b;
    80002f76:	a8b9                	j	80002fd4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f78:	0001d497          	auipc	s1,0x1d
    80002f7c:	ab84b483          	ld	s1,-1352(s1) # 8001fa30 <bcache+0x82b0>
    80002f80:	0001d797          	auipc	a5,0x1d
    80002f84:	a6878793          	addi	a5,a5,-1432 # 8001f9e8 <bcache+0x8268>
    80002f88:	00f48863          	beq	s1,a5,80002f98 <bread+0x90>
    80002f8c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f8e:	40bc                	lw	a5,64(s1)
    80002f90:	cf81                	beqz	a5,80002fa8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f92:	64a4                	ld	s1,72(s1)
    80002f94:	fee49de3          	bne	s1,a4,80002f8e <bread+0x86>
  panic("bget: no buffers");
    80002f98:	00005517          	auipc	a0,0x5
    80002f9c:	58850513          	addi	a0,a0,1416 # 80008520 <syscalls+0xc0>
    80002fa0:	ffffd097          	auipc	ra,0xffffd
    80002fa4:	5a8080e7          	jalr	1448(ra) # 80000548 <panic>
      b->dev = dev;
    80002fa8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fac:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fb0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fb4:	4785                	li	a5,1
    80002fb6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fb8:	00014517          	auipc	a0,0x14
    80002fbc:	7c850513          	addi	a0,a0,1992 # 80017780 <bcache>
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	d04080e7          	jalr	-764(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002fc8:	01048513          	addi	a0,s1,16
    80002fcc:	00001097          	auipc	ra,0x1
    80002fd0:	3f8080e7          	jalr	1016(ra) # 800043c4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fd4:	409c                	lw	a5,0(s1)
    80002fd6:	cb89                	beqz	a5,80002fe8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fd8:	8526                	mv	a0,s1
    80002fda:	70a2                	ld	ra,40(sp)
    80002fdc:	7402                	ld	s0,32(sp)
    80002fde:	64e2                	ld	s1,24(sp)
    80002fe0:	6942                	ld	s2,16(sp)
    80002fe2:	69a2                	ld	s3,8(sp)
    80002fe4:	6145                	addi	sp,sp,48
    80002fe6:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fe8:	4581                	li	a1,0
    80002fea:	8526                	mv	a0,s1
    80002fec:	00003097          	auipc	ra,0x3
    80002ff0:	f50080e7          	jalr	-176(ra) # 80005f3c <virtio_disk_rw>
    b->valid = 1;
    80002ff4:	4785                	li	a5,1
    80002ff6:	c09c                	sw	a5,0(s1)
  return b;
    80002ff8:	b7c5                	j	80002fd8 <bread+0xd0>

0000000080002ffa <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ffa:	1101                	addi	sp,sp,-32
    80002ffc:	ec06                	sd	ra,24(sp)
    80002ffe:	e822                	sd	s0,16(sp)
    80003000:	e426                	sd	s1,8(sp)
    80003002:	1000                	addi	s0,sp,32
    80003004:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003006:	0541                	addi	a0,a0,16
    80003008:	00001097          	auipc	ra,0x1
    8000300c:	456080e7          	jalr	1110(ra) # 8000445e <holdingsleep>
    80003010:	cd01                	beqz	a0,80003028 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003012:	4585                	li	a1,1
    80003014:	8526                	mv	a0,s1
    80003016:	00003097          	auipc	ra,0x3
    8000301a:	f26080e7          	jalr	-218(ra) # 80005f3c <virtio_disk_rw>
}
    8000301e:	60e2                	ld	ra,24(sp)
    80003020:	6442                	ld	s0,16(sp)
    80003022:	64a2                	ld	s1,8(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret
    panic("bwrite");
    80003028:	00005517          	auipc	a0,0x5
    8000302c:	51050513          	addi	a0,a0,1296 # 80008538 <syscalls+0xd8>
    80003030:	ffffd097          	auipc	ra,0xffffd
    80003034:	518080e7          	jalr	1304(ra) # 80000548 <panic>

0000000080003038 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003038:	1101                	addi	sp,sp,-32
    8000303a:	ec06                	sd	ra,24(sp)
    8000303c:	e822                	sd	s0,16(sp)
    8000303e:	e426                	sd	s1,8(sp)
    80003040:	e04a                	sd	s2,0(sp)
    80003042:	1000                	addi	s0,sp,32
    80003044:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003046:	01050913          	addi	s2,a0,16
    8000304a:	854a                	mv	a0,s2
    8000304c:	00001097          	auipc	ra,0x1
    80003050:	412080e7          	jalr	1042(ra) # 8000445e <holdingsleep>
    80003054:	c92d                	beqz	a0,800030c6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003056:	854a                	mv	a0,s2
    80003058:	00001097          	auipc	ra,0x1
    8000305c:	3c2080e7          	jalr	962(ra) # 8000441a <releasesleep>

  acquire(&bcache.lock);
    80003060:	00014517          	auipc	a0,0x14
    80003064:	72050513          	addi	a0,a0,1824 # 80017780 <bcache>
    80003068:	ffffe097          	auipc	ra,0xffffe
    8000306c:	ba8080e7          	jalr	-1112(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003070:	40bc                	lw	a5,64(s1)
    80003072:	37fd                	addiw	a5,a5,-1
    80003074:	0007871b          	sext.w	a4,a5
    80003078:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000307a:	eb05                	bnez	a4,800030aa <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000307c:	68bc                	ld	a5,80(s1)
    8000307e:	64b8                	ld	a4,72(s1)
    80003080:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003082:	64bc                	ld	a5,72(s1)
    80003084:	68b8                	ld	a4,80(s1)
    80003086:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003088:	0001c797          	auipc	a5,0x1c
    8000308c:	6f878793          	addi	a5,a5,1784 # 8001f780 <bcache+0x8000>
    80003090:	2b87b703          	ld	a4,696(a5)
    80003094:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003096:	0001d717          	auipc	a4,0x1d
    8000309a:	95270713          	addi	a4,a4,-1710 # 8001f9e8 <bcache+0x8268>
    8000309e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030a0:	2b87b703          	ld	a4,696(a5)
    800030a4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030a6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030aa:	00014517          	auipc	a0,0x14
    800030ae:	6d650513          	addi	a0,a0,1750 # 80017780 <bcache>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	c12080e7          	jalr	-1006(ra) # 80000cc4 <release>
}
    800030ba:	60e2                	ld	ra,24(sp)
    800030bc:	6442                	ld	s0,16(sp)
    800030be:	64a2                	ld	s1,8(sp)
    800030c0:	6902                	ld	s2,0(sp)
    800030c2:	6105                	addi	sp,sp,32
    800030c4:	8082                	ret
    panic("brelse");
    800030c6:	00005517          	auipc	a0,0x5
    800030ca:	47a50513          	addi	a0,a0,1146 # 80008540 <syscalls+0xe0>
    800030ce:	ffffd097          	auipc	ra,0xffffd
    800030d2:	47a080e7          	jalr	1146(ra) # 80000548 <panic>

00000000800030d6 <bpin>:

void
bpin(struct buf *b) {
    800030d6:	1101                	addi	sp,sp,-32
    800030d8:	ec06                	sd	ra,24(sp)
    800030da:	e822                	sd	s0,16(sp)
    800030dc:	e426                	sd	s1,8(sp)
    800030de:	1000                	addi	s0,sp,32
    800030e0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030e2:	00014517          	auipc	a0,0x14
    800030e6:	69e50513          	addi	a0,a0,1694 # 80017780 <bcache>
    800030ea:	ffffe097          	auipc	ra,0xffffe
    800030ee:	b26080e7          	jalr	-1242(ra) # 80000c10 <acquire>
  b->refcnt++;
    800030f2:	40bc                	lw	a5,64(s1)
    800030f4:	2785                	addiw	a5,a5,1
    800030f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030f8:	00014517          	auipc	a0,0x14
    800030fc:	68850513          	addi	a0,a0,1672 # 80017780 <bcache>
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	bc4080e7          	jalr	-1084(ra) # 80000cc4 <release>
}
    80003108:	60e2                	ld	ra,24(sp)
    8000310a:	6442                	ld	s0,16(sp)
    8000310c:	64a2                	ld	s1,8(sp)
    8000310e:	6105                	addi	sp,sp,32
    80003110:	8082                	ret

0000000080003112 <bunpin>:

void
bunpin(struct buf *b) {
    80003112:	1101                	addi	sp,sp,-32
    80003114:	ec06                	sd	ra,24(sp)
    80003116:	e822                	sd	s0,16(sp)
    80003118:	e426                	sd	s1,8(sp)
    8000311a:	1000                	addi	s0,sp,32
    8000311c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000311e:	00014517          	auipc	a0,0x14
    80003122:	66250513          	addi	a0,a0,1634 # 80017780 <bcache>
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	aea080e7          	jalr	-1302(ra) # 80000c10 <acquire>
  b->refcnt--;
    8000312e:	40bc                	lw	a5,64(s1)
    80003130:	37fd                	addiw	a5,a5,-1
    80003132:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003134:	00014517          	auipc	a0,0x14
    80003138:	64c50513          	addi	a0,a0,1612 # 80017780 <bcache>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	b88080e7          	jalr	-1144(ra) # 80000cc4 <release>
}
    80003144:	60e2                	ld	ra,24(sp)
    80003146:	6442                	ld	s0,16(sp)
    80003148:	64a2                	ld	s1,8(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret

000000008000314e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000314e:	1101                	addi	sp,sp,-32
    80003150:	ec06                	sd	ra,24(sp)
    80003152:	e822                	sd	s0,16(sp)
    80003154:	e426                	sd	s1,8(sp)
    80003156:	e04a                	sd	s2,0(sp)
    80003158:	1000                	addi	s0,sp,32
    8000315a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000315c:	00d5d59b          	srliw	a1,a1,0xd
    80003160:	0001d797          	auipc	a5,0x1d
    80003164:	cfc7a783          	lw	a5,-772(a5) # 8001fe5c <sb+0x1c>
    80003168:	9dbd                	addw	a1,a1,a5
    8000316a:	00000097          	auipc	ra,0x0
    8000316e:	d9e080e7          	jalr	-610(ra) # 80002f08 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003172:	0074f713          	andi	a4,s1,7
    80003176:	4785                	li	a5,1
    80003178:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000317c:	14ce                	slli	s1,s1,0x33
    8000317e:	90d9                	srli	s1,s1,0x36
    80003180:	00950733          	add	a4,a0,s1
    80003184:	05874703          	lbu	a4,88(a4)
    80003188:	00e7f6b3          	and	a3,a5,a4
    8000318c:	c69d                	beqz	a3,800031ba <bfree+0x6c>
    8000318e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003190:	94aa                	add	s1,s1,a0
    80003192:	fff7c793          	not	a5,a5
    80003196:	8ff9                	and	a5,a5,a4
    80003198:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000319c:	00001097          	auipc	ra,0x1
    800031a0:	100080e7          	jalr	256(ra) # 8000429c <log_write>
  brelse(bp);
    800031a4:	854a                	mv	a0,s2
    800031a6:	00000097          	auipc	ra,0x0
    800031aa:	e92080e7          	jalr	-366(ra) # 80003038 <brelse>
}
    800031ae:	60e2                	ld	ra,24(sp)
    800031b0:	6442                	ld	s0,16(sp)
    800031b2:	64a2                	ld	s1,8(sp)
    800031b4:	6902                	ld	s2,0(sp)
    800031b6:	6105                	addi	sp,sp,32
    800031b8:	8082                	ret
    panic("freeing free block");
    800031ba:	00005517          	auipc	a0,0x5
    800031be:	38e50513          	addi	a0,a0,910 # 80008548 <syscalls+0xe8>
    800031c2:	ffffd097          	auipc	ra,0xffffd
    800031c6:	386080e7          	jalr	902(ra) # 80000548 <panic>

00000000800031ca <balloc>:
{
    800031ca:	711d                	addi	sp,sp,-96
    800031cc:	ec86                	sd	ra,88(sp)
    800031ce:	e8a2                	sd	s0,80(sp)
    800031d0:	e4a6                	sd	s1,72(sp)
    800031d2:	e0ca                	sd	s2,64(sp)
    800031d4:	fc4e                	sd	s3,56(sp)
    800031d6:	f852                	sd	s4,48(sp)
    800031d8:	f456                	sd	s5,40(sp)
    800031da:	f05a                	sd	s6,32(sp)
    800031dc:	ec5e                	sd	s7,24(sp)
    800031de:	e862                	sd	s8,16(sp)
    800031e0:	e466                	sd	s9,8(sp)
    800031e2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031e4:	0001d797          	auipc	a5,0x1d
    800031e8:	c607a783          	lw	a5,-928(a5) # 8001fe44 <sb+0x4>
    800031ec:	cbd1                	beqz	a5,80003280 <balloc+0xb6>
    800031ee:	8baa                	mv	s7,a0
    800031f0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031f2:	0001db17          	auipc	s6,0x1d
    800031f6:	c4eb0b13          	addi	s6,s6,-946 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031fa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031fc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031fe:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003200:	6c89                	lui	s9,0x2
    80003202:	a831                	j	8000321e <balloc+0x54>
    brelse(bp);
    80003204:	854a                	mv	a0,s2
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	e32080e7          	jalr	-462(ra) # 80003038 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000320e:	015c87bb          	addw	a5,s9,s5
    80003212:	00078a9b          	sext.w	s5,a5
    80003216:	004b2703          	lw	a4,4(s6)
    8000321a:	06eaf363          	bgeu	s5,a4,80003280 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000321e:	41fad79b          	sraiw	a5,s5,0x1f
    80003222:	0137d79b          	srliw	a5,a5,0x13
    80003226:	015787bb          	addw	a5,a5,s5
    8000322a:	40d7d79b          	sraiw	a5,a5,0xd
    8000322e:	01cb2583          	lw	a1,28(s6)
    80003232:	9dbd                	addw	a1,a1,a5
    80003234:	855e                	mv	a0,s7
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	cd2080e7          	jalr	-814(ra) # 80002f08 <bread>
    8000323e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003240:	004b2503          	lw	a0,4(s6)
    80003244:	000a849b          	sext.w	s1,s5
    80003248:	8662                	mv	a2,s8
    8000324a:	faa4fde3          	bgeu	s1,a0,80003204 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000324e:	41f6579b          	sraiw	a5,a2,0x1f
    80003252:	01d7d69b          	srliw	a3,a5,0x1d
    80003256:	00c6873b          	addw	a4,a3,a2
    8000325a:	00777793          	andi	a5,a4,7
    8000325e:	9f95                	subw	a5,a5,a3
    80003260:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003264:	4037571b          	sraiw	a4,a4,0x3
    80003268:	00e906b3          	add	a3,s2,a4
    8000326c:	0586c683          	lbu	a3,88(a3)
    80003270:	00d7f5b3          	and	a1,a5,a3
    80003274:	cd91                	beqz	a1,80003290 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003276:	2605                	addiw	a2,a2,1
    80003278:	2485                	addiw	s1,s1,1
    8000327a:	fd4618e3          	bne	a2,s4,8000324a <balloc+0x80>
    8000327e:	b759                	j	80003204 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003280:	00005517          	auipc	a0,0x5
    80003284:	2e050513          	addi	a0,a0,736 # 80008560 <syscalls+0x100>
    80003288:	ffffd097          	auipc	ra,0xffffd
    8000328c:	2c0080e7          	jalr	704(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003290:	974a                	add	a4,a4,s2
    80003292:	8fd5                	or	a5,a5,a3
    80003294:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003298:	854a                	mv	a0,s2
    8000329a:	00001097          	auipc	ra,0x1
    8000329e:	002080e7          	jalr	2(ra) # 8000429c <log_write>
        brelse(bp);
    800032a2:	854a                	mv	a0,s2
    800032a4:	00000097          	auipc	ra,0x0
    800032a8:	d94080e7          	jalr	-620(ra) # 80003038 <brelse>
  bp = bread(dev, bno);
    800032ac:	85a6                	mv	a1,s1
    800032ae:	855e                	mv	a0,s7
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	c58080e7          	jalr	-936(ra) # 80002f08 <bread>
    800032b8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032ba:	40000613          	li	a2,1024
    800032be:	4581                	li	a1,0
    800032c0:	05850513          	addi	a0,a0,88
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	a48080e7          	jalr	-1464(ra) # 80000d0c <memset>
  log_write(bp);
    800032cc:	854a                	mv	a0,s2
    800032ce:	00001097          	auipc	ra,0x1
    800032d2:	fce080e7          	jalr	-50(ra) # 8000429c <log_write>
  brelse(bp);
    800032d6:	854a                	mv	a0,s2
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	d60080e7          	jalr	-672(ra) # 80003038 <brelse>
}
    800032e0:	8526                	mv	a0,s1
    800032e2:	60e6                	ld	ra,88(sp)
    800032e4:	6446                	ld	s0,80(sp)
    800032e6:	64a6                	ld	s1,72(sp)
    800032e8:	6906                	ld	s2,64(sp)
    800032ea:	79e2                	ld	s3,56(sp)
    800032ec:	7a42                	ld	s4,48(sp)
    800032ee:	7aa2                	ld	s5,40(sp)
    800032f0:	7b02                	ld	s6,32(sp)
    800032f2:	6be2                	ld	s7,24(sp)
    800032f4:	6c42                	ld	s8,16(sp)
    800032f6:	6ca2                	ld	s9,8(sp)
    800032f8:	6125                	addi	sp,sp,96
    800032fa:	8082                	ret

00000000800032fc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032fc:	7179                	addi	sp,sp,-48
    800032fe:	f406                	sd	ra,40(sp)
    80003300:	f022                	sd	s0,32(sp)
    80003302:	ec26                	sd	s1,24(sp)
    80003304:	e84a                	sd	s2,16(sp)
    80003306:	e44e                	sd	s3,8(sp)
    80003308:	e052                	sd	s4,0(sp)
    8000330a:	1800                	addi	s0,sp,48
    8000330c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000330e:	47ad                	li	a5,11
    80003310:	04b7fe63          	bgeu	a5,a1,8000336c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003314:	ff45849b          	addiw	s1,a1,-12
    80003318:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000331c:	0ff00793          	li	a5,255
    80003320:	0ae7e363          	bltu	a5,a4,800033c6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003324:	08052583          	lw	a1,128(a0)
    80003328:	c5ad                	beqz	a1,80003392 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000332a:	00092503          	lw	a0,0(s2)
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	bda080e7          	jalr	-1062(ra) # 80002f08 <bread>
    80003336:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003338:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000333c:	02049593          	slli	a1,s1,0x20
    80003340:	9181                	srli	a1,a1,0x20
    80003342:	058a                	slli	a1,a1,0x2
    80003344:	00b784b3          	add	s1,a5,a1
    80003348:	0004a983          	lw	s3,0(s1)
    8000334c:	04098d63          	beqz	s3,800033a6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003350:	8552                	mv	a0,s4
    80003352:	00000097          	auipc	ra,0x0
    80003356:	ce6080e7          	jalr	-794(ra) # 80003038 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000335a:	854e                	mv	a0,s3
    8000335c:	70a2                	ld	ra,40(sp)
    8000335e:	7402                	ld	s0,32(sp)
    80003360:	64e2                	ld	s1,24(sp)
    80003362:	6942                	ld	s2,16(sp)
    80003364:	69a2                	ld	s3,8(sp)
    80003366:	6a02                	ld	s4,0(sp)
    80003368:	6145                	addi	sp,sp,48
    8000336a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000336c:	02059493          	slli	s1,a1,0x20
    80003370:	9081                	srli	s1,s1,0x20
    80003372:	048a                	slli	s1,s1,0x2
    80003374:	94aa                	add	s1,s1,a0
    80003376:	0504a983          	lw	s3,80(s1)
    8000337a:	fe0990e3          	bnez	s3,8000335a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000337e:	4108                	lw	a0,0(a0)
    80003380:	00000097          	auipc	ra,0x0
    80003384:	e4a080e7          	jalr	-438(ra) # 800031ca <balloc>
    80003388:	0005099b          	sext.w	s3,a0
    8000338c:	0534a823          	sw	s3,80(s1)
    80003390:	b7e9                	j	8000335a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003392:	4108                	lw	a0,0(a0)
    80003394:	00000097          	auipc	ra,0x0
    80003398:	e36080e7          	jalr	-458(ra) # 800031ca <balloc>
    8000339c:	0005059b          	sext.w	a1,a0
    800033a0:	08b92023          	sw	a1,128(s2)
    800033a4:	b759                	j	8000332a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033a6:	00092503          	lw	a0,0(s2)
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	e20080e7          	jalr	-480(ra) # 800031ca <balloc>
    800033b2:	0005099b          	sext.w	s3,a0
    800033b6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033ba:	8552                	mv	a0,s4
    800033bc:	00001097          	auipc	ra,0x1
    800033c0:	ee0080e7          	jalr	-288(ra) # 8000429c <log_write>
    800033c4:	b771                	j	80003350 <bmap+0x54>
  panic("bmap: out of range");
    800033c6:	00005517          	auipc	a0,0x5
    800033ca:	1b250513          	addi	a0,a0,434 # 80008578 <syscalls+0x118>
    800033ce:	ffffd097          	auipc	ra,0xffffd
    800033d2:	17a080e7          	jalr	378(ra) # 80000548 <panic>

00000000800033d6 <iget>:
{
    800033d6:	7179                	addi	sp,sp,-48
    800033d8:	f406                	sd	ra,40(sp)
    800033da:	f022                	sd	s0,32(sp)
    800033dc:	ec26                	sd	s1,24(sp)
    800033de:	e84a                	sd	s2,16(sp)
    800033e0:	e44e                	sd	s3,8(sp)
    800033e2:	e052                	sd	s4,0(sp)
    800033e4:	1800                	addi	s0,sp,48
    800033e6:	89aa                	mv	s3,a0
    800033e8:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800033ea:	0001d517          	auipc	a0,0x1d
    800033ee:	a7650513          	addi	a0,a0,-1418 # 8001fe60 <icache>
    800033f2:	ffffe097          	auipc	ra,0xffffe
    800033f6:	81e080e7          	jalr	-2018(ra) # 80000c10 <acquire>
  empty = 0;
    800033fa:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033fc:	0001d497          	auipc	s1,0x1d
    80003400:	a7c48493          	addi	s1,s1,-1412 # 8001fe78 <icache+0x18>
    80003404:	0001e697          	auipc	a3,0x1e
    80003408:	50468693          	addi	a3,a3,1284 # 80021908 <log>
    8000340c:	a039                	j	8000341a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000340e:	02090b63          	beqz	s2,80003444 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003412:	08848493          	addi	s1,s1,136
    80003416:	02d48a63          	beq	s1,a3,8000344a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000341a:	449c                	lw	a5,8(s1)
    8000341c:	fef059e3          	blez	a5,8000340e <iget+0x38>
    80003420:	4098                	lw	a4,0(s1)
    80003422:	ff3716e3          	bne	a4,s3,8000340e <iget+0x38>
    80003426:	40d8                	lw	a4,4(s1)
    80003428:	ff4713e3          	bne	a4,s4,8000340e <iget+0x38>
      ip->ref++;
    8000342c:	2785                	addiw	a5,a5,1
    8000342e:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003430:	0001d517          	auipc	a0,0x1d
    80003434:	a3050513          	addi	a0,a0,-1488 # 8001fe60 <icache>
    80003438:	ffffe097          	auipc	ra,0xffffe
    8000343c:	88c080e7          	jalr	-1908(ra) # 80000cc4 <release>
      return ip;
    80003440:	8926                	mv	s2,s1
    80003442:	a03d                	j	80003470 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003444:	f7f9                	bnez	a5,80003412 <iget+0x3c>
    80003446:	8926                	mv	s2,s1
    80003448:	b7e9                	j	80003412 <iget+0x3c>
  if(empty == 0)
    8000344a:	02090c63          	beqz	s2,80003482 <iget+0xac>
  ip->dev = dev;
    8000344e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003452:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003456:	4785                	li	a5,1
    80003458:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000345c:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003460:	0001d517          	auipc	a0,0x1d
    80003464:	a0050513          	addi	a0,a0,-1536 # 8001fe60 <icache>
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	85c080e7          	jalr	-1956(ra) # 80000cc4 <release>
}
    80003470:	854a                	mv	a0,s2
    80003472:	70a2                	ld	ra,40(sp)
    80003474:	7402                	ld	s0,32(sp)
    80003476:	64e2                	ld	s1,24(sp)
    80003478:	6942                	ld	s2,16(sp)
    8000347a:	69a2                	ld	s3,8(sp)
    8000347c:	6a02                	ld	s4,0(sp)
    8000347e:	6145                	addi	sp,sp,48
    80003480:	8082                	ret
    panic("iget: no inodes");
    80003482:	00005517          	auipc	a0,0x5
    80003486:	10e50513          	addi	a0,a0,270 # 80008590 <syscalls+0x130>
    8000348a:	ffffd097          	auipc	ra,0xffffd
    8000348e:	0be080e7          	jalr	190(ra) # 80000548 <panic>

0000000080003492 <fsinit>:
fsinit(int dev) {
    80003492:	7179                	addi	sp,sp,-48
    80003494:	f406                	sd	ra,40(sp)
    80003496:	f022                	sd	s0,32(sp)
    80003498:	ec26                	sd	s1,24(sp)
    8000349a:	e84a                	sd	s2,16(sp)
    8000349c:	e44e                	sd	s3,8(sp)
    8000349e:	1800                	addi	s0,sp,48
    800034a0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034a2:	4585                	li	a1,1
    800034a4:	00000097          	auipc	ra,0x0
    800034a8:	a64080e7          	jalr	-1436(ra) # 80002f08 <bread>
    800034ac:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034ae:	0001d997          	auipc	s3,0x1d
    800034b2:	99298993          	addi	s3,s3,-1646 # 8001fe40 <sb>
    800034b6:	02000613          	li	a2,32
    800034ba:	05850593          	addi	a1,a0,88
    800034be:	854e                	mv	a0,s3
    800034c0:	ffffe097          	auipc	ra,0xffffe
    800034c4:	8ac080e7          	jalr	-1876(ra) # 80000d6c <memmove>
  brelse(bp);
    800034c8:	8526                	mv	a0,s1
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	b6e080e7          	jalr	-1170(ra) # 80003038 <brelse>
  if(sb.magic != FSMAGIC)
    800034d2:	0009a703          	lw	a4,0(s3)
    800034d6:	102037b7          	lui	a5,0x10203
    800034da:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800034de:	02f71263          	bne	a4,a5,80003502 <fsinit+0x70>
  initlog(dev, &sb);
    800034e2:	0001d597          	auipc	a1,0x1d
    800034e6:	95e58593          	addi	a1,a1,-1698 # 8001fe40 <sb>
    800034ea:	854a                	mv	a0,s2
    800034ec:	00001097          	auipc	ra,0x1
    800034f0:	b38080e7          	jalr	-1224(ra) # 80004024 <initlog>
}
    800034f4:	70a2                	ld	ra,40(sp)
    800034f6:	7402                	ld	s0,32(sp)
    800034f8:	64e2                	ld	s1,24(sp)
    800034fa:	6942                	ld	s2,16(sp)
    800034fc:	69a2                	ld	s3,8(sp)
    800034fe:	6145                	addi	sp,sp,48
    80003500:	8082                	ret
    panic("invalid file system");
    80003502:	00005517          	auipc	a0,0x5
    80003506:	09e50513          	addi	a0,a0,158 # 800085a0 <syscalls+0x140>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	03e080e7          	jalr	62(ra) # 80000548 <panic>

0000000080003512 <iinit>:
{
    80003512:	7179                	addi	sp,sp,-48
    80003514:	f406                	sd	ra,40(sp)
    80003516:	f022                	sd	s0,32(sp)
    80003518:	ec26                	sd	s1,24(sp)
    8000351a:	e84a                	sd	s2,16(sp)
    8000351c:	e44e                	sd	s3,8(sp)
    8000351e:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003520:	00005597          	auipc	a1,0x5
    80003524:	09858593          	addi	a1,a1,152 # 800085b8 <syscalls+0x158>
    80003528:	0001d517          	auipc	a0,0x1d
    8000352c:	93850513          	addi	a0,a0,-1736 # 8001fe60 <icache>
    80003530:	ffffd097          	auipc	ra,0xffffd
    80003534:	650080e7          	jalr	1616(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003538:	0001d497          	auipc	s1,0x1d
    8000353c:	95048493          	addi	s1,s1,-1712 # 8001fe88 <icache+0x28>
    80003540:	0001e997          	auipc	s3,0x1e
    80003544:	3d898993          	addi	s3,s3,984 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003548:	00005917          	auipc	s2,0x5
    8000354c:	07890913          	addi	s2,s2,120 # 800085c0 <syscalls+0x160>
    80003550:	85ca                	mv	a1,s2
    80003552:	8526                	mv	a0,s1
    80003554:	00001097          	auipc	ra,0x1
    80003558:	e36080e7          	jalr	-458(ra) # 8000438a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000355c:	08848493          	addi	s1,s1,136
    80003560:	ff3498e3          	bne	s1,s3,80003550 <iinit+0x3e>
}
    80003564:	70a2                	ld	ra,40(sp)
    80003566:	7402                	ld	s0,32(sp)
    80003568:	64e2                	ld	s1,24(sp)
    8000356a:	6942                	ld	s2,16(sp)
    8000356c:	69a2                	ld	s3,8(sp)
    8000356e:	6145                	addi	sp,sp,48
    80003570:	8082                	ret

0000000080003572 <ialloc>:
{
    80003572:	715d                	addi	sp,sp,-80
    80003574:	e486                	sd	ra,72(sp)
    80003576:	e0a2                	sd	s0,64(sp)
    80003578:	fc26                	sd	s1,56(sp)
    8000357a:	f84a                	sd	s2,48(sp)
    8000357c:	f44e                	sd	s3,40(sp)
    8000357e:	f052                	sd	s4,32(sp)
    80003580:	ec56                	sd	s5,24(sp)
    80003582:	e85a                	sd	s6,16(sp)
    80003584:	e45e                	sd	s7,8(sp)
    80003586:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003588:	0001d717          	auipc	a4,0x1d
    8000358c:	8c472703          	lw	a4,-1852(a4) # 8001fe4c <sb+0xc>
    80003590:	4785                	li	a5,1
    80003592:	04e7fa63          	bgeu	a5,a4,800035e6 <ialloc+0x74>
    80003596:	8aaa                	mv	s5,a0
    80003598:	8bae                	mv	s7,a1
    8000359a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000359c:	0001da17          	auipc	s4,0x1d
    800035a0:	8a4a0a13          	addi	s4,s4,-1884 # 8001fe40 <sb>
    800035a4:	00048b1b          	sext.w	s6,s1
    800035a8:	0044d593          	srli	a1,s1,0x4
    800035ac:	018a2783          	lw	a5,24(s4)
    800035b0:	9dbd                	addw	a1,a1,a5
    800035b2:	8556                	mv	a0,s5
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	954080e7          	jalr	-1708(ra) # 80002f08 <bread>
    800035bc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035be:	05850993          	addi	s3,a0,88
    800035c2:	00f4f793          	andi	a5,s1,15
    800035c6:	079a                	slli	a5,a5,0x6
    800035c8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035ca:	00099783          	lh	a5,0(s3)
    800035ce:	c785                	beqz	a5,800035f6 <ialloc+0x84>
    brelse(bp);
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	a68080e7          	jalr	-1432(ra) # 80003038 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035d8:	0485                	addi	s1,s1,1
    800035da:	00ca2703          	lw	a4,12(s4)
    800035de:	0004879b          	sext.w	a5,s1
    800035e2:	fce7e1e3          	bltu	a5,a4,800035a4 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035e6:	00005517          	auipc	a0,0x5
    800035ea:	fe250513          	addi	a0,a0,-30 # 800085c8 <syscalls+0x168>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	f5a080e7          	jalr	-166(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    800035f6:	04000613          	li	a2,64
    800035fa:	4581                	li	a1,0
    800035fc:	854e                	mv	a0,s3
    800035fe:	ffffd097          	auipc	ra,0xffffd
    80003602:	70e080e7          	jalr	1806(ra) # 80000d0c <memset>
      dip->type = type;
    80003606:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000360a:	854a                	mv	a0,s2
    8000360c:	00001097          	auipc	ra,0x1
    80003610:	c90080e7          	jalr	-880(ra) # 8000429c <log_write>
      brelse(bp);
    80003614:	854a                	mv	a0,s2
    80003616:	00000097          	auipc	ra,0x0
    8000361a:	a22080e7          	jalr	-1502(ra) # 80003038 <brelse>
      return iget(dev, inum);
    8000361e:	85da                	mv	a1,s6
    80003620:	8556                	mv	a0,s5
    80003622:	00000097          	auipc	ra,0x0
    80003626:	db4080e7          	jalr	-588(ra) # 800033d6 <iget>
}
    8000362a:	60a6                	ld	ra,72(sp)
    8000362c:	6406                	ld	s0,64(sp)
    8000362e:	74e2                	ld	s1,56(sp)
    80003630:	7942                	ld	s2,48(sp)
    80003632:	79a2                	ld	s3,40(sp)
    80003634:	7a02                	ld	s4,32(sp)
    80003636:	6ae2                	ld	s5,24(sp)
    80003638:	6b42                	ld	s6,16(sp)
    8000363a:	6ba2                	ld	s7,8(sp)
    8000363c:	6161                	addi	sp,sp,80
    8000363e:	8082                	ret

0000000080003640 <iupdate>:
{
    80003640:	1101                	addi	sp,sp,-32
    80003642:	ec06                	sd	ra,24(sp)
    80003644:	e822                	sd	s0,16(sp)
    80003646:	e426                	sd	s1,8(sp)
    80003648:	e04a                	sd	s2,0(sp)
    8000364a:	1000                	addi	s0,sp,32
    8000364c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000364e:	415c                	lw	a5,4(a0)
    80003650:	0047d79b          	srliw	a5,a5,0x4
    80003654:	0001d597          	auipc	a1,0x1d
    80003658:	8045a583          	lw	a1,-2044(a1) # 8001fe58 <sb+0x18>
    8000365c:	9dbd                	addw	a1,a1,a5
    8000365e:	4108                	lw	a0,0(a0)
    80003660:	00000097          	auipc	ra,0x0
    80003664:	8a8080e7          	jalr	-1880(ra) # 80002f08 <bread>
    80003668:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000366a:	05850793          	addi	a5,a0,88
    8000366e:	40c8                	lw	a0,4(s1)
    80003670:	893d                	andi	a0,a0,15
    80003672:	051a                	slli	a0,a0,0x6
    80003674:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003676:	04449703          	lh	a4,68(s1)
    8000367a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000367e:	04649703          	lh	a4,70(s1)
    80003682:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003686:	04849703          	lh	a4,72(s1)
    8000368a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000368e:	04a49703          	lh	a4,74(s1)
    80003692:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003696:	44f8                	lw	a4,76(s1)
    80003698:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000369a:	03400613          	li	a2,52
    8000369e:	05048593          	addi	a1,s1,80
    800036a2:	0531                	addi	a0,a0,12
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	6c8080e7          	jalr	1736(ra) # 80000d6c <memmove>
  log_write(bp);
    800036ac:	854a                	mv	a0,s2
    800036ae:	00001097          	auipc	ra,0x1
    800036b2:	bee080e7          	jalr	-1042(ra) # 8000429c <log_write>
  brelse(bp);
    800036b6:	854a                	mv	a0,s2
    800036b8:	00000097          	auipc	ra,0x0
    800036bc:	980080e7          	jalr	-1664(ra) # 80003038 <brelse>
}
    800036c0:	60e2                	ld	ra,24(sp)
    800036c2:	6442                	ld	s0,16(sp)
    800036c4:	64a2                	ld	s1,8(sp)
    800036c6:	6902                	ld	s2,0(sp)
    800036c8:	6105                	addi	sp,sp,32
    800036ca:	8082                	ret

00000000800036cc <idup>:
{
    800036cc:	1101                	addi	sp,sp,-32
    800036ce:	ec06                	sd	ra,24(sp)
    800036d0:	e822                	sd	s0,16(sp)
    800036d2:	e426                	sd	s1,8(sp)
    800036d4:	1000                	addi	s0,sp,32
    800036d6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800036d8:	0001c517          	auipc	a0,0x1c
    800036dc:	78850513          	addi	a0,a0,1928 # 8001fe60 <icache>
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	530080e7          	jalr	1328(ra) # 80000c10 <acquire>
  ip->ref++;
    800036e8:	449c                	lw	a5,8(s1)
    800036ea:	2785                	addiw	a5,a5,1
    800036ec:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800036ee:	0001c517          	auipc	a0,0x1c
    800036f2:	77250513          	addi	a0,a0,1906 # 8001fe60 <icache>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	5ce080e7          	jalr	1486(ra) # 80000cc4 <release>
}
    800036fe:	8526                	mv	a0,s1
    80003700:	60e2                	ld	ra,24(sp)
    80003702:	6442                	ld	s0,16(sp)
    80003704:	64a2                	ld	s1,8(sp)
    80003706:	6105                	addi	sp,sp,32
    80003708:	8082                	ret

000000008000370a <ilock>:
{
    8000370a:	1101                	addi	sp,sp,-32
    8000370c:	ec06                	sd	ra,24(sp)
    8000370e:	e822                	sd	s0,16(sp)
    80003710:	e426                	sd	s1,8(sp)
    80003712:	e04a                	sd	s2,0(sp)
    80003714:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003716:	c115                	beqz	a0,8000373a <ilock+0x30>
    80003718:	84aa                	mv	s1,a0
    8000371a:	451c                	lw	a5,8(a0)
    8000371c:	00f05f63          	blez	a5,8000373a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003720:	0541                	addi	a0,a0,16
    80003722:	00001097          	auipc	ra,0x1
    80003726:	ca2080e7          	jalr	-862(ra) # 800043c4 <acquiresleep>
  if(ip->valid == 0){
    8000372a:	40bc                	lw	a5,64(s1)
    8000372c:	cf99                	beqz	a5,8000374a <ilock+0x40>
}
    8000372e:	60e2                	ld	ra,24(sp)
    80003730:	6442                	ld	s0,16(sp)
    80003732:	64a2                	ld	s1,8(sp)
    80003734:	6902                	ld	s2,0(sp)
    80003736:	6105                	addi	sp,sp,32
    80003738:	8082                	ret
    panic("ilock");
    8000373a:	00005517          	auipc	a0,0x5
    8000373e:	ea650513          	addi	a0,a0,-346 # 800085e0 <syscalls+0x180>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	e06080e7          	jalr	-506(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000374a:	40dc                	lw	a5,4(s1)
    8000374c:	0047d79b          	srliw	a5,a5,0x4
    80003750:	0001c597          	auipc	a1,0x1c
    80003754:	7085a583          	lw	a1,1800(a1) # 8001fe58 <sb+0x18>
    80003758:	9dbd                	addw	a1,a1,a5
    8000375a:	4088                	lw	a0,0(s1)
    8000375c:	fffff097          	auipc	ra,0xfffff
    80003760:	7ac080e7          	jalr	1964(ra) # 80002f08 <bread>
    80003764:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003766:	05850593          	addi	a1,a0,88
    8000376a:	40dc                	lw	a5,4(s1)
    8000376c:	8bbd                	andi	a5,a5,15
    8000376e:	079a                	slli	a5,a5,0x6
    80003770:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003772:	00059783          	lh	a5,0(a1)
    80003776:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000377a:	00259783          	lh	a5,2(a1)
    8000377e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003782:	00459783          	lh	a5,4(a1)
    80003786:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000378a:	00659783          	lh	a5,6(a1)
    8000378e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003792:	459c                	lw	a5,8(a1)
    80003794:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003796:	03400613          	li	a2,52
    8000379a:	05b1                	addi	a1,a1,12
    8000379c:	05048513          	addi	a0,s1,80
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	5cc080e7          	jalr	1484(ra) # 80000d6c <memmove>
    brelse(bp);
    800037a8:	854a                	mv	a0,s2
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	88e080e7          	jalr	-1906(ra) # 80003038 <brelse>
    ip->valid = 1;
    800037b2:	4785                	li	a5,1
    800037b4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037b6:	04449783          	lh	a5,68(s1)
    800037ba:	fbb5                	bnez	a5,8000372e <ilock+0x24>
      panic("ilock: no type");
    800037bc:	00005517          	auipc	a0,0x5
    800037c0:	e2c50513          	addi	a0,a0,-468 # 800085e8 <syscalls+0x188>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	d84080e7          	jalr	-636(ra) # 80000548 <panic>

00000000800037cc <iunlock>:
{
    800037cc:	1101                	addi	sp,sp,-32
    800037ce:	ec06                	sd	ra,24(sp)
    800037d0:	e822                	sd	s0,16(sp)
    800037d2:	e426                	sd	s1,8(sp)
    800037d4:	e04a                	sd	s2,0(sp)
    800037d6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037d8:	c905                	beqz	a0,80003808 <iunlock+0x3c>
    800037da:	84aa                	mv	s1,a0
    800037dc:	01050913          	addi	s2,a0,16
    800037e0:	854a                	mv	a0,s2
    800037e2:	00001097          	auipc	ra,0x1
    800037e6:	c7c080e7          	jalr	-900(ra) # 8000445e <holdingsleep>
    800037ea:	cd19                	beqz	a0,80003808 <iunlock+0x3c>
    800037ec:	449c                	lw	a5,8(s1)
    800037ee:	00f05d63          	blez	a5,80003808 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037f2:	854a                	mv	a0,s2
    800037f4:	00001097          	auipc	ra,0x1
    800037f8:	c26080e7          	jalr	-986(ra) # 8000441a <releasesleep>
}
    800037fc:	60e2                	ld	ra,24(sp)
    800037fe:	6442                	ld	s0,16(sp)
    80003800:	64a2                	ld	s1,8(sp)
    80003802:	6902                	ld	s2,0(sp)
    80003804:	6105                	addi	sp,sp,32
    80003806:	8082                	ret
    panic("iunlock");
    80003808:	00005517          	auipc	a0,0x5
    8000380c:	df050513          	addi	a0,a0,-528 # 800085f8 <syscalls+0x198>
    80003810:	ffffd097          	auipc	ra,0xffffd
    80003814:	d38080e7          	jalr	-712(ra) # 80000548 <panic>

0000000080003818 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003818:	7179                	addi	sp,sp,-48
    8000381a:	f406                	sd	ra,40(sp)
    8000381c:	f022                	sd	s0,32(sp)
    8000381e:	ec26                	sd	s1,24(sp)
    80003820:	e84a                	sd	s2,16(sp)
    80003822:	e44e                	sd	s3,8(sp)
    80003824:	e052                	sd	s4,0(sp)
    80003826:	1800                	addi	s0,sp,48
    80003828:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000382a:	05050493          	addi	s1,a0,80
    8000382e:	08050913          	addi	s2,a0,128
    80003832:	a021                	j	8000383a <itrunc+0x22>
    80003834:	0491                	addi	s1,s1,4
    80003836:	01248d63          	beq	s1,s2,80003850 <itrunc+0x38>
    if(ip->addrs[i]){
    8000383a:	408c                	lw	a1,0(s1)
    8000383c:	dde5                	beqz	a1,80003834 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000383e:	0009a503          	lw	a0,0(s3)
    80003842:	00000097          	auipc	ra,0x0
    80003846:	90c080e7          	jalr	-1780(ra) # 8000314e <bfree>
      ip->addrs[i] = 0;
    8000384a:	0004a023          	sw	zero,0(s1)
    8000384e:	b7dd                	j	80003834 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003850:	0809a583          	lw	a1,128(s3)
    80003854:	e185                	bnez	a1,80003874 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003856:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000385a:	854e                	mv	a0,s3
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	de4080e7          	jalr	-540(ra) # 80003640 <iupdate>
}
    80003864:	70a2                	ld	ra,40(sp)
    80003866:	7402                	ld	s0,32(sp)
    80003868:	64e2                	ld	s1,24(sp)
    8000386a:	6942                	ld	s2,16(sp)
    8000386c:	69a2                	ld	s3,8(sp)
    8000386e:	6a02                	ld	s4,0(sp)
    80003870:	6145                	addi	sp,sp,48
    80003872:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003874:	0009a503          	lw	a0,0(s3)
    80003878:	fffff097          	auipc	ra,0xfffff
    8000387c:	690080e7          	jalr	1680(ra) # 80002f08 <bread>
    80003880:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003882:	05850493          	addi	s1,a0,88
    80003886:	45850913          	addi	s2,a0,1112
    8000388a:	a811                	j	8000389e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000388c:	0009a503          	lw	a0,0(s3)
    80003890:	00000097          	auipc	ra,0x0
    80003894:	8be080e7          	jalr	-1858(ra) # 8000314e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003898:	0491                	addi	s1,s1,4
    8000389a:	01248563          	beq	s1,s2,800038a4 <itrunc+0x8c>
      if(a[j])
    8000389e:	408c                	lw	a1,0(s1)
    800038a0:	dde5                	beqz	a1,80003898 <itrunc+0x80>
    800038a2:	b7ed                	j	8000388c <itrunc+0x74>
    brelse(bp);
    800038a4:	8552                	mv	a0,s4
    800038a6:	fffff097          	auipc	ra,0xfffff
    800038aa:	792080e7          	jalr	1938(ra) # 80003038 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038ae:	0809a583          	lw	a1,128(s3)
    800038b2:	0009a503          	lw	a0,0(s3)
    800038b6:	00000097          	auipc	ra,0x0
    800038ba:	898080e7          	jalr	-1896(ra) # 8000314e <bfree>
    ip->addrs[NDIRECT] = 0;
    800038be:	0809a023          	sw	zero,128(s3)
    800038c2:	bf51                	j	80003856 <itrunc+0x3e>

00000000800038c4 <iput>:
{
    800038c4:	1101                	addi	sp,sp,-32
    800038c6:	ec06                	sd	ra,24(sp)
    800038c8:	e822                	sd	s0,16(sp)
    800038ca:	e426                	sd	s1,8(sp)
    800038cc:	e04a                	sd	s2,0(sp)
    800038ce:	1000                	addi	s0,sp,32
    800038d0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038d2:	0001c517          	auipc	a0,0x1c
    800038d6:	58e50513          	addi	a0,a0,1422 # 8001fe60 <icache>
    800038da:	ffffd097          	auipc	ra,0xffffd
    800038de:	336080e7          	jalr	822(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038e2:	4498                	lw	a4,8(s1)
    800038e4:	4785                	li	a5,1
    800038e6:	02f70363          	beq	a4,a5,8000390c <iput+0x48>
  ip->ref--;
    800038ea:	449c                	lw	a5,8(s1)
    800038ec:	37fd                	addiw	a5,a5,-1
    800038ee:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038f0:	0001c517          	auipc	a0,0x1c
    800038f4:	57050513          	addi	a0,a0,1392 # 8001fe60 <icache>
    800038f8:	ffffd097          	auipc	ra,0xffffd
    800038fc:	3cc080e7          	jalr	972(ra) # 80000cc4 <release>
}
    80003900:	60e2                	ld	ra,24(sp)
    80003902:	6442                	ld	s0,16(sp)
    80003904:	64a2                	ld	s1,8(sp)
    80003906:	6902                	ld	s2,0(sp)
    80003908:	6105                	addi	sp,sp,32
    8000390a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000390c:	40bc                	lw	a5,64(s1)
    8000390e:	dff1                	beqz	a5,800038ea <iput+0x26>
    80003910:	04a49783          	lh	a5,74(s1)
    80003914:	fbf9                	bnez	a5,800038ea <iput+0x26>
    acquiresleep(&ip->lock);
    80003916:	01048913          	addi	s2,s1,16
    8000391a:	854a                	mv	a0,s2
    8000391c:	00001097          	auipc	ra,0x1
    80003920:	aa8080e7          	jalr	-1368(ra) # 800043c4 <acquiresleep>
    release(&icache.lock);
    80003924:	0001c517          	auipc	a0,0x1c
    80003928:	53c50513          	addi	a0,a0,1340 # 8001fe60 <icache>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	398080e7          	jalr	920(ra) # 80000cc4 <release>
    itrunc(ip);
    80003934:	8526                	mv	a0,s1
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	ee2080e7          	jalr	-286(ra) # 80003818 <itrunc>
    ip->type = 0;
    8000393e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003942:	8526                	mv	a0,s1
    80003944:	00000097          	auipc	ra,0x0
    80003948:	cfc080e7          	jalr	-772(ra) # 80003640 <iupdate>
    ip->valid = 0;
    8000394c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003950:	854a                	mv	a0,s2
    80003952:	00001097          	auipc	ra,0x1
    80003956:	ac8080e7          	jalr	-1336(ra) # 8000441a <releasesleep>
    acquire(&icache.lock);
    8000395a:	0001c517          	auipc	a0,0x1c
    8000395e:	50650513          	addi	a0,a0,1286 # 8001fe60 <icache>
    80003962:	ffffd097          	auipc	ra,0xffffd
    80003966:	2ae080e7          	jalr	686(ra) # 80000c10 <acquire>
    8000396a:	b741                	j	800038ea <iput+0x26>

000000008000396c <iunlockput>:
{
    8000396c:	1101                	addi	sp,sp,-32
    8000396e:	ec06                	sd	ra,24(sp)
    80003970:	e822                	sd	s0,16(sp)
    80003972:	e426                	sd	s1,8(sp)
    80003974:	1000                	addi	s0,sp,32
    80003976:	84aa                	mv	s1,a0
  iunlock(ip);
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	e54080e7          	jalr	-428(ra) # 800037cc <iunlock>
  iput(ip);
    80003980:	8526                	mv	a0,s1
    80003982:	00000097          	auipc	ra,0x0
    80003986:	f42080e7          	jalr	-190(ra) # 800038c4 <iput>
}
    8000398a:	60e2                	ld	ra,24(sp)
    8000398c:	6442                	ld	s0,16(sp)
    8000398e:	64a2                	ld	s1,8(sp)
    80003990:	6105                	addi	sp,sp,32
    80003992:	8082                	ret

0000000080003994 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003994:	1141                	addi	sp,sp,-16
    80003996:	e422                	sd	s0,8(sp)
    80003998:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000399a:	411c                	lw	a5,0(a0)
    8000399c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000399e:	415c                	lw	a5,4(a0)
    800039a0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039a2:	04451783          	lh	a5,68(a0)
    800039a6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039aa:	04a51783          	lh	a5,74(a0)
    800039ae:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039b2:	04c56783          	lwu	a5,76(a0)
    800039b6:	e99c                	sd	a5,16(a1)
}
    800039b8:	6422                	ld	s0,8(sp)
    800039ba:	0141                	addi	sp,sp,16
    800039bc:	8082                	ret

00000000800039be <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039be:	457c                	lw	a5,76(a0)
    800039c0:	0ed7e863          	bltu	a5,a3,80003ab0 <readi+0xf2>
{
    800039c4:	7159                	addi	sp,sp,-112
    800039c6:	f486                	sd	ra,104(sp)
    800039c8:	f0a2                	sd	s0,96(sp)
    800039ca:	eca6                	sd	s1,88(sp)
    800039cc:	e8ca                	sd	s2,80(sp)
    800039ce:	e4ce                	sd	s3,72(sp)
    800039d0:	e0d2                	sd	s4,64(sp)
    800039d2:	fc56                	sd	s5,56(sp)
    800039d4:	f85a                	sd	s6,48(sp)
    800039d6:	f45e                	sd	s7,40(sp)
    800039d8:	f062                	sd	s8,32(sp)
    800039da:	ec66                	sd	s9,24(sp)
    800039dc:	e86a                	sd	s10,16(sp)
    800039de:	e46e                	sd	s11,8(sp)
    800039e0:	1880                	addi	s0,sp,112
    800039e2:	8baa                	mv	s7,a0
    800039e4:	8c2e                	mv	s8,a1
    800039e6:	8ab2                	mv	s5,a2
    800039e8:	84b6                	mv	s1,a3
    800039ea:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039ec:	9f35                	addw	a4,a4,a3
    return 0;
    800039ee:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039f0:	08d76f63          	bltu	a4,a3,80003a8e <readi+0xd0>
  if(off + n > ip->size)
    800039f4:	00e7f463          	bgeu	a5,a4,800039fc <readi+0x3e>
    n = ip->size - off;
    800039f8:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039fc:	0a0b0863          	beqz	s6,80003aac <readi+0xee>
    80003a00:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a02:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a06:	5cfd                	li	s9,-1
    80003a08:	a82d                	j	80003a42 <readi+0x84>
    80003a0a:	020a1d93          	slli	s11,s4,0x20
    80003a0e:	020ddd93          	srli	s11,s11,0x20
    80003a12:	05890613          	addi	a2,s2,88
    80003a16:	86ee                	mv	a3,s11
    80003a18:	963a                	add	a2,a2,a4
    80003a1a:	85d6                	mv	a1,s5
    80003a1c:	8562                	mv	a0,s8
    80003a1e:	fffff097          	auipc	ra,0xfffff
    80003a22:	b2e080e7          	jalr	-1234(ra) # 8000254c <either_copyout>
    80003a26:	05950d63          	beq	a0,s9,80003a80 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a2a:	854a                	mv	a0,s2
    80003a2c:	fffff097          	auipc	ra,0xfffff
    80003a30:	60c080e7          	jalr	1548(ra) # 80003038 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a34:	013a09bb          	addw	s3,s4,s3
    80003a38:	009a04bb          	addw	s1,s4,s1
    80003a3c:	9aee                	add	s5,s5,s11
    80003a3e:	0569f663          	bgeu	s3,s6,80003a8a <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a42:	000ba903          	lw	s2,0(s7)
    80003a46:	00a4d59b          	srliw	a1,s1,0xa
    80003a4a:	855e                	mv	a0,s7
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	8b0080e7          	jalr	-1872(ra) # 800032fc <bmap>
    80003a54:	0005059b          	sext.w	a1,a0
    80003a58:	854a                	mv	a0,s2
    80003a5a:	fffff097          	auipc	ra,0xfffff
    80003a5e:	4ae080e7          	jalr	1198(ra) # 80002f08 <bread>
    80003a62:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a64:	3ff4f713          	andi	a4,s1,1023
    80003a68:	40ed07bb          	subw	a5,s10,a4
    80003a6c:	413b06bb          	subw	a3,s6,s3
    80003a70:	8a3e                	mv	s4,a5
    80003a72:	2781                	sext.w	a5,a5
    80003a74:	0006861b          	sext.w	a2,a3
    80003a78:	f8f679e3          	bgeu	a2,a5,80003a0a <readi+0x4c>
    80003a7c:	8a36                	mv	s4,a3
    80003a7e:	b771                	j	80003a0a <readi+0x4c>
      brelse(bp);
    80003a80:	854a                	mv	a0,s2
    80003a82:	fffff097          	auipc	ra,0xfffff
    80003a86:	5b6080e7          	jalr	1462(ra) # 80003038 <brelse>
  }
  return tot;
    80003a8a:	0009851b          	sext.w	a0,s3
}
    80003a8e:	70a6                	ld	ra,104(sp)
    80003a90:	7406                	ld	s0,96(sp)
    80003a92:	64e6                	ld	s1,88(sp)
    80003a94:	6946                	ld	s2,80(sp)
    80003a96:	69a6                	ld	s3,72(sp)
    80003a98:	6a06                	ld	s4,64(sp)
    80003a9a:	7ae2                	ld	s5,56(sp)
    80003a9c:	7b42                	ld	s6,48(sp)
    80003a9e:	7ba2                	ld	s7,40(sp)
    80003aa0:	7c02                	ld	s8,32(sp)
    80003aa2:	6ce2                	ld	s9,24(sp)
    80003aa4:	6d42                	ld	s10,16(sp)
    80003aa6:	6da2                	ld	s11,8(sp)
    80003aa8:	6165                	addi	sp,sp,112
    80003aaa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aac:	89da                	mv	s3,s6
    80003aae:	bff1                	j	80003a8a <readi+0xcc>
    return 0;
    80003ab0:	4501                	li	a0,0
}
    80003ab2:	8082                	ret

0000000080003ab4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ab4:	457c                	lw	a5,76(a0)
    80003ab6:	10d7e663          	bltu	a5,a3,80003bc2 <writei+0x10e>
{
    80003aba:	7159                	addi	sp,sp,-112
    80003abc:	f486                	sd	ra,104(sp)
    80003abe:	f0a2                	sd	s0,96(sp)
    80003ac0:	eca6                	sd	s1,88(sp)
    80003ac2:	e8ca                	sd	s2,80(sp)
    80003ac4:	e4ce                	sd	s3,72(sp)
    80003ac6:	e0d2                	sd	s4,64(sp)
    80003ac8:	fc56                	sd	s5,56(sp)
    80003aca:	f85a                	sd	s6,48(sp)
    80003acc:	f45e                	sd	s7,40(sp)
    80003ace:	f062                	sd	s8,32(sp)
    80003ad0:	ec66                	sd	s9,24(sp)
    80003ad2:	e86a                	sd	s10,16(sp)
    80003ad4:	e46e                	sd	s11,8(sp)
    80003ad6:	1880                	addi	s0,sp,112
    80003ad8:	8baa                	mv	s7,a0
    80003ada:	8c2e                	mv	s8,a1
    80003adc:	8ab2                	mv	s5,a2
    80003ade:	8936                	mv	s2,a3
    80003ae0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ae2:	00e687bb          	addw	a5,a3,a4
    80003ae6:	0ed7e063          	bltu	a5,a3,80003bc6 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003aea:	00043737          	lui	a4,0x43
    80003aee:	0cf76e63          	bltu	a4,a5,80003bca <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003af2:	0a0b0763          	beqz	s6,80003ba0 <writei+0xec>
    80003af6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003afc:	5cfd                	li	s9,-1
    80003afe:	a091                	j	80003b42 <writei+0x8e>
    80003b00:	02099d93          	slli	s11,s3,0x20
    80003b04:	020ddd93          	srli	s11,s11,0x20
    80003b08:	05848513          	addi	a0,s1,88
    80003b0c:	86ee                	mv	a3,s11
    80003b0e:	8656                	mv	a2,s5
    80003b10:	85e2                	mv	a1,s8
    80003b12:	953a                	add	a0,a0,a4
    80003b14:	fffff097          	auipc	ra,0xfffff
    80003b18:	a8e080e7          	jalr	-1394(ra) # 800025a2 <either_copyin>
    80003b1c:	07950263          	beq	a0,s9,80003b80 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b20:	8526                	mv	a0,s1
    80003b22:	00000097          	auipc	ra,0x0
    80003b26:	77a080e7          	jalr	1914(ra) # 8000429c <log_write>
    brelse(bp);
    80003b2a:	8526                	mv	a0,s1
    80003b2c:	fffff097          	auipc	ra,0xfffff
    80003b30:	50c080e7          	jalr	1292(ra) # 80003038 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b34:	01498a3b          	addw	s4,s3,s4
    80003b38:	0129893b          	addw	s2,s3,s2
    80003b3c:	9aee                	add	s5,s5,s11
    80003b3e:	056a7663          	bgeu	s4,s6,80003b8a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b42:	000ba483          	lw	s1,0(s7)
    80003b46:	00a9559b          	srliw	a1,s2,0xa
    80003b4a:	855e                	mv	a0,s7
    80003b4c:	fffff097          	auipc	ra,0xfffff
    80003b50:	7b0080e7          	jalr	1968(ra) # 800032fc <bmap>
    80003b54:	0005059b          	sext.w	a1,a0
    80003b58:	8526                	mv	a0,s1
    80003b5a:	fffff097          	auipc	ra,0xfffff
    80003b5e:	3ae080e7          	jalr	942(ra) # 80002f08 <bread>
    80003b62:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b64:	3ff97713          	andi	a4,s2,1023
    80003b68:	40ed07bb          	subw	a5,s10,a4
    80003b6c:	414b06bb          	subw	a3,s6,s4
    80003b70:	89be                	mv	s3,a5
    80003b72:	2781                	sext.w	a5,a5
    80003b74:	0006861b          	sext.w	a2,a3
    80003b78:	f8f674e3          	bgeu	a2,a5,80003b00 <writei+0x4c>
    80003b7c:	89b6                	mv	s3,a3
    80003b7e:	b749                	j	80003b00 <writei+0x4c>
      brelse(bp);
    80003b80:	8526                	mv	a0,s1
    80003b82:	fffff097          	auipc	ra,0xfffff
    80003b86:	4b6080e7          	jalr	1206(ra) # 80003038 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003b8a:	04cba783          	lw	a5,76(s7)
    80003b8e:	0127f463          	bgeu	a5,s2,80003b96 <writei+0xe2>
      ip->size = off;
    80003b92:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b96:	855e                	mv	a0,s7
    80003b98:	00000097          	auipc	ra,0x0
    80003b9c:	aa8080e7          	jalr	-1368(ra) # 80003640 <iupdate>
  }

  return n;
    80003ba0:	000b051b          	sext.w	a0,s6
}
    80003ba4:	70a6                	ld	ra,104(sp)
    80003ba6:	7406                	ld	s0,96(sp)
    80003ba8:	64e6                	ld	s1,88(sp)
    80003baa:	6946                	ld	s2,80(sp)
    80003bac:	69a6                	ld	s3,72(sp)
    80003bae:	6a06                	ld	s4,64(sp)
    80003bb0:	7ae2                	ld	s5,56(sp)
    80003bb2:	7b42                	ld	s6,48(sp)
    80003bb4:	7ba2                	ld	s7,40(sp)
    80003bb6:	7c02                	ld	s8,32(sp)
    80003bb8:	6ce2                	ld	s9,24(sp)
    80003bba:	6d42                	ld	s10,16(sp)
    80003bbc:	6da2                	ld	s11,8(sp)
    80003bbe:	6165                	addi	sp,sp,112
    80003bc0:	8082                	ret
    return -1;
    80003bc2:	557d                	li	a0,-1
}
    80003bc4:	8082                	ret
    return -1;
    80003bc6:	557d                	li	a0,-1
    80003bc8:	bff1                	j	80003ba4 <writei+0xf0>
    return -1;
    80003bca:	557d                	li	a0,-1
    80003bcc:	bfe1                	j	80003ba4 <writei+0xf0>

0000000080003bce <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bce:	1141                	addi	sp,sp,-16
    80003bd0:	e406                	sd	ra,8(sp)
    80003bd2:	e022                	sd	s0,0(sp)
    80003bd4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003bd6:	4639                	li	a2,14
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	210080e7          	jalr	528(ra) # 80000de8 <strncmp>
}
    80003be0:	60a2                	ld	ra,8(sp)
    80003be2:	6402                	ld	s0,0(sp)
    80003be4:	0141                	addi	sp,sp,16
    80003be6:	8082                	ret

0000000080003be8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003be8:	7139                	addi	sp,sp,-64
    80003bea:	fc06                	sd	ra,56(sp)
    80003bec:	f822                	sd	s0,48(sp)
    80003bee:	f426                	sd	s1,40(sp)
    80003bf0:	f04a                	sd	s2,32(sp)
    80003bf2:	ec4e                	sd	s3,24(sp)
    80003bf4:	e852                	sd	s4,16(sp)
    80003bf6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bf8:	04451703          	lh	a4,68(a0)
    80003bfc:	4785                	li	a5,1
    80003bfe:	00f71a63          	bne	a4,a5,80003c12 <dirlookup+0x2a>
    80003c02:	892a                	mv	s2,a0
    80003c04:	89ae                	mv	s3,a1
    80003c06:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c08:	457c                	lw	a5,76(a0)
    80003c0a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c0c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c0e:	e79d                	bnez	a5,80003c3c <dirlookup+0x54>
    80003c10:	a8a5                	j	80003c88 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c12:	00005517          	auipc	a0,0x5
    80003c16:	9ee50513          	addi	a0,a0,-1554 # 80008600 <syscalls+0x1a0>
    80003c1a:	ffffd097          	auipc	ra,0xffffd
    80003c1e:	92e080e7          	jalr	-1746(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c22:	00005517          	auipc	a0,0x5
    80003c26:	9f650513          	addi	a0,a0,-1546 # 80008618 <syscalls+0x1b8>
    80003c2a:	ffffd097          	auipc	ra,0xffffd
    80003c2e:	91e080e7          	jalr	-1762(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c32:	24c1                	addiw	s1,s1,16
    80003c34:	04c92783          	lw	a5,76(s2)
    80003c38:	04f4f763          	bgeu	s1,a5,80003c86 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c3c:	4741                	li	a4,16
    80003c3e:	86a6                	mv	a3,s1
    80003c40:	fc040613          	addi	a2,s0,-64
    80003c44:	4581                	li	a1,0
    80003c46:	854a                	mv	a0,s2
    80003c48:	00000097          	auipc	ra,0x0
    80003c4c:	d76080e7          	jalr	-650(ra) # 800039be <readi>
    80003c50:	47c1                	li	a5,16
    80003c52:	fcf518e3          	bne	a0,a5,80003c22 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c56:	fc045783          	lhu	a5,-64(s0)
    80003c5a:	dfe1                	beqz	a5,80003c32 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c5c:	fc240593          	addi	a1,s0,-62
    80003c60:	854e                	mv	a0,s3
    80003c62:	00000097          	auipc	ra,0x0
    80003c66:	f6c080e7          	jalr	-148(ra) # 80003bce <namecmp>
    80003c6a:	f561                	bnez	a0,80003c32 <dirlookup+0x4a>
      if(poff)
    80003c6c:	000a0463          	beqz	s4,80003c74 <dirlookup+0x8c>
        *poff = off;
    80003c70:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c74:	fc045583          	lhu	a1,-64(s0)
    80003c78:	00092503          	lw	a0,0(s2)
    80003c7c:	fffff097          	auipc	ra,0xfffff
    80003c80:	75a080e7          	jalr	1882(ra) # 800033d6 <iget>
    80003c84:	a011                	j	80003c88 <dirlookup+0xa0>
  return 0;
    80003c86:	4501                	li	a0,0
}
    80003c88:	70e2                	ld	ra,56(sp)
    80003c8a:	7442                	ld	s0,48(sp)
    80003c8c:	74a2                	ld	s1,40(sp)
    80003c8e:	7902                	ld	s2,32(sp)
    80003c90:	69e2                	ld	s3,24(sp)
    80003c92:	6a42                	ld	s4,16(sp)
    80003c94:	6121                	addi	sp,sp,64
    80003c96:	8082                	ret

0000000080003c98 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c98:	711d                	addi	sp,sp,-96
    80003c9a:	ec86                	sd	ra,88(sp)
    80003c9c:	e8a2                	sd	s0,80(sp)
    80003c9e:	e4a6                	sd	s1,72(sp)
    80003ca0:	e0ca                	sd	s2,64(sp)
    80003ca2:	fc4e                	sd	s3,56(sp)
    80003ca4:	f852                	sd	s4,48(sp)
    80003ca6:	f456                	sd	s5,40(sp)
    80003ca8:	f05a                	sd	s6,32(sp)
    80003caa:	ec5e                	sd	s7,24(sp)
    80003cac:	e862                	sd	s8,16(sp)
    80003cae:	e466                	sd	s9,8(sp)
    80003cb0:	1080                	addi	s0,sp,96
    80003cb2:	84aa                	mv	s1,a0
    80003cb4:	8b2e                	mv	s6,a1
    80003cb6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cb8:	00054703          	lbu	a4,0(a0)
    80003cbc:	02f00793          	li	a5,47
    80003cc0:	02f70363          	beq	a4,a5,80003ce6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cc4:	ffffe097          	auipc	ra,0xffffe
    80003cc8:	e1a080e7          	jalr	-486(ra) # 80001ade <myproc>
    80003ccc:	15053503          	ld	a0,336(a0)
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	9fc080e7          	jalr	-1540(ra) # 800036cc <idup>
    80003cd8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003cda:	02f00913          	li	s2,47
  len = path - s;
    80003cde:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003ce0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ce2:	4c05                	li	s8,1
    80003ce4:	a865                	j	80003d9c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ce6:	4585                	li	a1,1
    80003ce8:	4505                	li	a0,1
    80003cea:	fffff097          	auipc	ra,0xfffff
    80003cee:	6ec080e7          	jalr	1772(ra) # 800033d6 <iget>
    80003cf2:	89aa                	mv	s3,a0
    80003cf4:	b7dd                	j	80003cda <namex+0x42>
      iunlockput(ip);
    80003cf6:	854e                	mv	a0,s3
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	c74080e7          	jalr	-908(ra) # 8000396c <iunlockput>
      return 0;
    80003d00:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d02:	854e                	mv	a0,s3
    80003d04:	60e6                	ld	ra,88(sp)
    80003d06:	6446                	ld	s0,80(sp)
    80003d08:	64a6                	ld	s1,72(sp)
    80003d0a:	6906                	ld	s2,64(sp)
    80003d0c:	79e2                	ld	s3,56(sp)
    80003d0e:	7a42                	ld	s4,48(sp)
    80003d10:	7aa2                	ld	s5,40(sp)
    80003d12:	7b02                	ld	s6,32(sp)
    80003d14:	6be2                	ld	s7,24(sp)
    80003d16:	6c42                	ld	s8,16(sp)
    80003d18:	6ca2                	ld	s9,8(sp)
    80003d1a:	6125                	addi	sp,sp,96
    80003d1c:	8082                	ret
      iunlock(ip);
    80003d1e:	854e                	mv	a0,s3
    80003d20:	00000097          	auipc	ra,0x0
    80003d24:	aac080e7          	jalr	-1364(ra) # 800037cc <iunlock>
      return ip;
    80003d28:	bfe9                	j	80003d02 <namex+0x6a>
      iunlockput(ip);
    80003d2a:	854e                	mv	a0,s3
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	c40080e7          	jalr	-960(ra) # 8000396c <iunlockput>
      return 0;
    80003d34:	89d2                	mv	s3,s4
    80003d36:	b7f1                	j	80003d02 <namex+0x6a>
  len = path - s;
    80003d38:	40b48633          	sub	a2,s1,a1
    80003d3c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d40:	094cd463          	bge	s9,s4,80003dc8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d44:	4639                	li	a2,14
    80003d46:	8556                	mv	a0,s5
    80003d48:	ffffd097          	auipc	ra,0xffffd
    80003d4c:	024080e7          	jalr	36(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003d50:	0004c783          	lbu	a5,0(s1)
    80003d54:	01279763          	bne	a5,s2,80003d62 <namex+0xca>
    path++;
    80003d58:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d5a:	0004c783          	lbu	a5,0(s1)
    80003d5e:	ff278de3          	beq	a5,s2,80003d58 <namex+0xc0>
    ilock(ip);
    80003d62:	854e                	mv	a0,s3
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	9a6080e7          	jalr	-1626(ra) # 8000370a <ilock>
    if(ip->type != T_DIR){
    80003d6c:	04499783          	lh	a5,68(s3)
    80003d70:	f98793e3          	bne	a5,s8,80003cf6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d74:	000b0563          	beqz	s6,80003d7e <namex+0xe6>
    80003d78:	0004c783          	lbu	a5,0(s1)
    80003d7c:	d3cd                	beqz	a5,80003d1e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d7e:	865e                	mv	a2,s7
    80003d80:	85d6                	mv	a1,s5
    80003d82:	854e                	mv	a0,s3
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	e64080e7          	jalr	-412(ra) # 80003be8 <dirlookup>
    80003d8c:	8a2a                	mv	s4,a0
    80003d8e:	dd51                	beqz	a0,80003d2a <namex+0x92>
    iunlockput(ip);
    80003d90:	854e                	mv	a0,s3
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	bda080e7          	jalr	-1062(ra) # 8000396c <iunlockput>
    ip = next;
    80003d9a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003d9c:	0004c783          	lbu	a5,0(s1)
    80003da0:	05279763          	bne	a5,s2,80003dee <namex+0x156>
    path++;
    80003da4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003da6:	0004c783          	lbu	a5,0(s1)
    80003daa:	ff278de3          	beq	a5,s2,80003da4 <namex+0x10c>
  if(*path == 0)
    80003dae:	c79d                	beqz	a5,80003ddc <namex+0x144>
    path++;
    80003db0:	85a6                	mv	a1,s1
  len = path - s;
    80003db2:	8a5e                	mv	s4,s7
    80003db4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003db6:	01278963          	beq	a5,s2,80003dc8 <namex+0x130>
    80003dba:	dfbd                	beqz	a5,80003d38 <namex+0xa0>
    path++;
    80003dbc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003dbe:	0004c783          	lbu	a5,0(s1)
    80003dc2:	ff279ce3          	bne	a5,s2,80003dba <namex+0x122>
    80003dc6:	bf8d                	j	80003d38 <namex+0xa0>
    memmove(name, s, len);
    80003dc8:	2601                	sext.w	a2,a2
    80003dca:	8556                	mv	a0,s5
    80003dcc:	ffffd097          	auipc	ra,0xffffd
    80003dd0:	fa0080e7          	jalr	-96(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003dd4:	9a56                	add	s4,s4,s5
    80003dd6:	000a0023          	sb	zero,0(s4)
    80003dda:	bf9d                	j	80003d50 <namex+0xb8>
  if(nameiparent){
    80003ddc:	f20b03e3          	beqz	s6,80003d02 <namex+0x6a>
    iput(ip);
    80003de0:	854e                	mv	a0,s3
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	ae2080e7          	jalr	-1310(ra) # 800038c4 <iput>
    return 0;
    80003dea:	4981                	li	s3,0
    80003dec:	bf19                	j	80003d02 <namex+0x6a>
  if(*path == 0)
    80003dee:	d7fd                	beqz	a5,80003ddc <namex+0x144>
  while(*path != '/' && *path != 0)
    80003df0:	0004c783          	lbu	a5,0(s1)
    80003df4:	85a6                	mv	a1,s1
    80003df6:	b7d1                	j	80003dba <namex+0x122>

0000000080003df8 <dirlink>:
{
    80003df8:	7139                	addi	sp,sp,-64
    80003dfa:	fc06                	sd	ra,56(sp)
    80003dfc:	f822                	sd	s0,48(sp)
    80003dfe:	f426                	sd	s1,40(sp)
    80003e00:	f04a                	sd	s2,32(sp)
    80003e02:	ec4e                	sd	s3,24(sp)
    80003e04:	e852                	sd	s4,16(sp)
    80003e06:	0080                	addi	s0,sp,64
    80003e08:	892a                	mv	s2,a0
    80003e0a:	8a2e                	mv	s4,a1
    80003e0c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e0e:	4601                	li	a2,0
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	dd8080e7          	jalr	-552(ra) # 80003be8 <dirlookup>
    80003e18:	e93d                	bnez	a0,80003e8e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e1a:	04c92483          	lw	s1,76(s2)
    80003e1e:	c49d                	beqz	s1,80003e4c <dirlink+0x54>
    80003e20:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e22:	4741                	li	a4,16
    80003e24:	86a6                	mv	a3,s1
    80003e26:	fc040613          	addi	a2,s0,-64
    80003e2a:	4581                	li	a1,0
    80003e2c:	854a                	mv	a0,s2
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	b90080e7          	jalr	-1136(ra) # 800039be <readi>
    80003e36:	47c1                	li	a5,16
    80003e38:	06f51163          	bne	a0,a5,80003e9a <dirlink+0xa2>
    if(de.inum == 0)
    80003e3c:	fc045783          	lhu	a5,-64(s0)
    80003e40:	c791                	beqz	a5,80003e4c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e42:	24c1                	addiw	s1,s1,16
    80003e44:	04c92783          	lw	a5,76(s2)
    80003e48:	fcf4ede3          	bltu	s1,a5,80003e22 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e4c:	4639                	li	a2,14
    80003e4e:	85d2                	mv	a1,s4
    80003e50:	fc240513          	addi	a0,s0,-62
    80003e54:	ffffd097          	auipc	ra,0xffffd
    80003e58:	fd0080e7          	jalr	-48(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80003e5c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e60:	4741                	li	a4,16
    80003e62:	86a6                	mv	a3,s1
    80003e64:	fc040613          	addi	a2,s0,-64
    80003e68:	4581                	li	a1,0
    80003e6a:	854a                	mv	a0,s2
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	c48080e7          	jalr	-952(ra) # 80003ab4 <writei>
    80003e74:	872a                	mv	a4,a0
    80003e76:	47c1                	li	a5,16
  return 0;
    80003e78:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e7a:	02f71863          	bne	a4,a5,80003eaa <dirlink+0xb2>
}
    80003e7e:	70e2                	ld	ra,56(sp)
    80003e80:	7442                	ld	s0,48(sp)
    80003e82:	74a2                	ld	s1,40(sp)
    80003e84:	7902                	ld	s2,32(sp)
    80003e86:	69e2                	ld	s3,24(sp)
    80003e88:	6a42                	ld	s4,16(sp)
    80003e8a:	6121                	addi	sp,sp,64
    80003e8c:	8082                	ret
    iput(ip);
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	a36080e7          	jalr	-1482(ra) # 800038c4 <iput>
    return -1;
    80003e96:	557d                	li	a0,-1
    80003e98:	b7dd                	j	80003e7e <dirlink+0x86>
      panic("dirlink read");
    80003e9a:	00004517          	auipc	a0,0x4
    80003e9e:	78e50513          	addi	a0,a0,1934 # 80008628 <syscalls+0x1c8>
    80003ea2:	ffffc097          	auipc	ra,0xffffc
    80003ea6:	6a6080e7          	jalr	1702(ra) # 80000548 <panic>
    panic("dirlink");
    80003eaa:	00005517          	auipc	a0,0x5
    80003eae:	89650513          	addi	a0,a0,-1898 # 80008740 <syscalls+0x2e0>
    80003eb2:	ffffc097          	auipc	ra,0xffffc
    80003eb6:	696080e7          	jalr	1686(ra) # 80000548 <panic>

0000000080003eba <namei>:

struct inode*
namei(char *path)
{
    80003eba:	1101                	addi	sp,sp,-32
    80003ebc:	ec06                	sd	ra,24(sp)
    80003ebe:	e822                	sd	s0,16(sp)
    80003ec0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ec2:	fe040613          	addi	a2,s0,-32
    80003ec6:	4581                	li	a1,0
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	dd0080e7          	jalr	-560(ra) # 80003c98 <namex>
}
    80003ed0:	60e2                	ld	ra,24(sp)
    80003ed2:	6442                	ld	s0,16(sp)
    80003ed4:	6105                	addi	sp,sp,32
    80003ed6:	8082                	ret

0000000080003ed8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ed8:	1141                	addi	sp,sp,-16
    80003eda:	e406                	sd	ra,8(sp)
    80003edc:	e022                	sd	s0,0(sp)
    80003ede:	0800                	addi	s0,sp,16
    80003ee0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ee2:	4585                	li	a1,1
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	db4080e7          	jalr	-588(ra) # 80003c98 <namex>
}
    80003eec:	60a2                	ld	ra,8(sp)
    80003eee:	6402                	ld	s0,0(sp)
    80003ef0:	0141                	addi	sp,sp,16
    80003ef2:	8082                	ret

0000000080003ef4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ef4:	1101                	addi	sp,sp,-32
    80003ef6:	ec06                	sd	ra,24(sp)
    80003ef8:	e822                	sd	s0,16(sp)
    80003efa:	e426                	sd	s1,8(sp)
    80003efc:	e04a                	sd	s2,0(sp)
    80003efe:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f00:	0001e917          	auipc	s2,0x1e
    80003f04:	a0890913          	addi	s2,s2,-1528 # 80021908 <log>
    80003f08:	01892583          	lw	a1,24(s2)
    80003f0c:	02892503          	lw	a0,40(s2)
    80003f10:	fffff097          	auipc	ra,0xfffff
    80003f14:	ff8080e7          	jalr	-8(ra) # 80002f08 <bread>
    80003f18:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f1a:	02c92683          	lw	a3,44(s2)
    80003f1e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f20:	02d05763          	blez	a3,80003f4e <write_head+0x5a>
    80003f24:	0001e797          	auipc	a5,0x1e
    80003f28:	a1478793          	addi	a5,a5,-1516 # 80021938 <log+0x30>
    80003f2c:	05c50713          	addi	a4,a0,92
    80003f30:	36fd                	addiw	a3,a3,-1
    80003f32:	1682                	slli	a3,a3,0x20
    80003f34:	9281                	srli	a3,a3,0x20
    80003f36:	068a                	slli	a3,a3,0x2
    80003f38:	0001e617          	auipc	a2,0x1e
    80003f3c:	a0460613          	addi	a2,a2,-1532 # 8002193c <log+0x34>
    80003f40:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f42:	4390                	lw	a2,0(a5)
    80003f44:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f46:	0791                	addi	a5,a5,4
    80003f48:	0711                	addi	a4,a4,4
    80003f4a:	fed79ce3          	bne	a5,a3,80003f42 <write_head+0x4e>
  }
  bwrite(buf);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	0aa080e7          	jalr	170(ra) # 80002ffa <bwrite>
  brelse(buf);
    80003f58:	8526                	mv	a0,s1
    80003f5a:	fffff097          	auipc	ra,0xfffff
    80003f5e:	0de080e7          	jalr	222(ra) # 80003038 <brelse>
}
    80003f62:	60e2                	ld	ra,24(sp)
    80003f64:	6442                	ld	s0,16(sp)
    80003f66:	64a2                	ld	s1,8(sp)
    80003f68:	6902                	ld	s2,0(sp)
    80003f6a:	6105                	addi	sp,sp,32
    80003f6c:	8082                	ret

0000000080003f6e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f6e:	0001e797          	auipc	a5,0x1e
    80003f72:	9c67a783          	lw	a5,-1594(a5) # 80021934 <log+0x2c>
    80003f76:	0af05663          	blez	a5,80004022 <install_trans+0xb4>
{
    80003f7a:	7139                	addi	sp,sp,-64
    80003f7c:	fc06                	sd	ra,56(sp)
    80003f7e:	f822                	sd	s0,48(sp)
    80003f80:	f426                	sd	s1,40(sp)
    80003f82:	f04a                	sd	s2,32(sp)
    80003f84:	ec4e                	sd	s3,24(sp)
    80003f86:	e852                	sd	s4,16(sp)
    80003f88:	e456                	sd	s5,8(sp)
    80003f8a:	0080                	addi	s0,sp,64
    80003f8c:	0001ea97          	auipc	s5,0x1e
    80003f90:	9aca8a93          	addi	s5,s5,-1620 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f94:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f96:	0001e997          	auipc	s3,0x1e
    80003f9a:	97298993          	addi	s3,s3,-1678 # 80021908 <log>
    80003f9e:	0189a583          	lw	a1,24(s3)
    80003fa2:	014585bb          	addw	a1,a1,s4
    80003fa6:	2585                	addiw	a1,a1,1
    80003fa8:	0289a503          	lw	a0,40(s3)
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	f5c080e7          	jalr	-164(ra) # 80002f08 <bread>
    80003fb4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fb6:	000aa583          	lw	a1,0(s5)
    80003fba:	0289a503          	lw	a0,40(s3)
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	f4a080e7          	jalr	-182(ra) # 80002f08 <bread>
    80003fc6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003fc8:	40000613          	li	a2,1024
    80003fcc:	05890593          	addi	a1,s2,88
    80003fd0:	05850513          	addi	a0,a0,88
    80003fd4:	ffffd097          	auipc	ra,0xffffd
    80003fd8:	d98080e7          	jalr	-616(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fdc:	8526                	mv	a0,s1
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	01c080e7          	jalr	28(ra) # 80002ffa <bwrite>
    bunpin(dbuf);
    80003fe6:	8526                	mv	a0,s1
    80003fe8:	fffff097          	auipc	ra,0xfffff
    80003fec:	12a080e7          	jalr	298(ra) # 80003112 <bunpin>
    brelse(lbuf);
    80003ff0:	854a                	mv	a0,s2
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	046080e7          	jalr	70(ra) # 80003038 <brelse>
    brelse(dbuf);
    80003ffa:	8526                	mv	a0,s1
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	03c080e7          	jalr	60(ra) # 80003038 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004004:	2a05                	addiw	s4,s4,1
    80004006:	0a91                	addi	s5,s5,4
    80004008:	02c9a783          	lw	a5,44(s3)
    8000400c:	f8fa49e3          	blt	s4,a5,80003f9e <install_trans+0x30>
}
    80004010:	70e2                	ld	ra,56(sp)
    80004012:	7442                	ld	s0,48(sp)
    80004014:	74a2                	ld	s1,40(sp)
    80004016:	7902                	ld	s2,32(sp)
    80004018:	69e2                	ld	s3,24(sp)
    8000401a:	6a42                	ld	s4,16(sp)
    8000401c:	6aa2                	ld	s5,8(sp)
    8000401e:	6121                	addi	sp,sp,64
    80004020:	8082                	ret
    80004022:	8082                	ret

0000000080004024 <initlog>:
{
    80004024:	7179                	addi	sp,sp,-48
    80004026:	f406                	sd	ra,40(sp)
    80004028:	f022                	sd	s0,32(sp)
    8000402a:	ec26                	sd	s1,24(sp)
    8000402c:	e84a                	sd	s2,16(sp)
    8000402e:	e44e                	sd	s3,8(sp)
    80004030:	1800                	addi	s0,sp,48
    80004032:	892a                	mv	s2,a0
    80004034:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004036:	0001e497          	auipc	s1,0x1e
    8000403a:	8d248493          	addi	s1,s1,-1838 # 80021908 <log>
    8000403e:	00004597          	auipc	a1,0x4
    80004042:	5fa58593          	addi	a1,a1,1530 # 80008638 <syscalls+0x1d8>
    80004046:	8526                	mv	a0,s1
    80004048:	ffffd097          	auipc	ra,0xffffd
    8000404c:	b38080e7          	jalr	-1224(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004050:	0149a583          	lw	a1,20(s3)
    80004054:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004056:	0109a783          	lw	a5,16(s3)
    8000405a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000405c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004060:	854a                	mv	a0,s2
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	ea6080e7          	jalr	-346(ra) # 80002f08 <bread>
  log.lh.n = lh->n;
    8000406a:	4d3c                	lw	a5,88(a0)
    8000406c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000406e:	02f05563          	blez	a5,80004098 <initlog+0x74>
    80004072:	05c50713          	addi	a4,a0,92
    80004076:	0001e697          	auipc	a3,0x1e
    8000407a:	8c268693          	addi	a3,a3,-1854 # 80021938 <log+0x30>
    8000407e:	37fd                	addiw	a5,a5,-1
    80004080:	1782                	slli	a5,a5,0x20
    80004082:	9381                	srli	a5,a5,0x20
    80004084:	078a                	slli	a5,a5,0x2
    80004086:	06050613          	addi	a2,a0,96
    8000408a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000408c:	4310                	lw	a2,0(a4)
    8000408e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004090:	0711                	addi	a4,a4,4
    80004092:	0691                	addi	a3,a3,4
    80004094:	fef71ce3          	bne	a4,a5,8000408c <initlog+0x68>
  brelse(buf);
    80004098:	fffff097          	auipc	ra,0xfffff
    8000409c:	fa0080e7          	jalr	-96(ra) # 80003038 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040a0:	00000097          	auipc	ra,0x0
    800040a4:	ece080e7          	jalr	-306(ra) # 80003f6e <install_trans>
  log.lh.n = 0;
    800040a8:	0001e797          	auipc	a5,0x1e
    800040ac:	8807a623          	sw	zero,-1908(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	e44080e7          	jalr	-444(ra) # 80003ef4 <write_head>
}
    800040b8:	70a2                	ld	ra,40(sp)
    800040ba:	7402                	ld	s0,32(sp)
    800040bc:	64e2                	ld	s1,24(sp)
    800040be:	6942                	ld	s2,16(sp)
    800040c0:	69a2                	ld	s3,8(sp)
    800040c2:	6145                	addi	sp,sp,48
    800040c4:	8082                	ret

00000000800040c6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040c6:	1101                	addi	sp,sp,-32
    800040c8:	ec06                	sd	ra,24(sp)
    800040ca:	e822                	sd	s0,16(sp)
    800040cc:	e426                	sd	s1,8(sp)
    800040ce:	e04a                	sd	s2,0(sp)
    800040d0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040d2:	0001e517          	auipc	a0,0x1e
    800040d6:	83650513          	addi	a0,a0,-1994 # 80021908 <log>
    800040da:	ffffd097          	auipc	ra,0xffffd
    800040de:	b36080e7          	jalr	-1226(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    800040e2:	0001e497          	auipc	s1,0x1e
    800040e6:	82648493          	addi	s1,s1,-2010 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040ea:	4979                	li	s2,30
    800040ec:	a039                	j	800040fa <begin_op+0x34>
      sleep(&log, &log.lock);
    800040ee:	85a6                	mv	a1,s1
    800040f0:	8526                	mv	a0,s1
    800040f2:	ffffe097          	auipc	ra,0xffffe
    800040f6:	1f8080e7          	jalr	504(ra) # 800022ea <sleep>
    if(log.committing){
    800040fa:	50dc                	lw	a5,36(s1)
    800040fc:	fbed                	bnez	a5,800040ee <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040fe:	509c                	lw	a5,32(s1)
    80004100:	0017871b          	addiw	a4,a5,1
    80004104:	0007069b          	sext.w	a3,a4
    80004108:	0027179b          	slliw	a5,a4,0x2
    8000410c:	9fb9                	addw	a5,a5,a4
    8000410e:	0017979b          	slliw	a5,a5,0x1
    80004112:	54d8                	lw	a4,44(s1)
    80004114:	9fb9                	addw	a5,a5,a4
    80004116:	00f95963          	bge	s2,a5,80004128 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000411a:	85a6                	mv	a1,s1
    8000411c:	8526                	mv	a0,s1
    8000411e:	ffffe097          	auipc	ra,0xffffe
    80004122:	1cc080e7          	jalr	460(ra) # 800022ea <sleep>
    80004126:	bfd1                	j	800040fa <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004128:	0001d517          	auipc	a0,0x1d
    8000412c:	7e050513          	addi	a0,a0,2016 # 80021908 <log>
    80004130:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004132:	ffffd097          	auipc	ra,0xffffd
    80004136:	b92080e7          	jalr	-1134(ra) # 80000cc4 <release>
      break;
    }
  }
}
    8000413a:	60e2                	ld	ra,24(sp)
    8000413c:	6442                	ld	s0,16(sp)
    8000413e:	64a2                	ld	s1,8(sp)
    80004140:	6902                	ld	s2,0(sp)
    80004142:	6105                	addi	sp,sp,32
    80004144:	8082                	ret

0000000080004146 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004146:	7139                	addi	sp,sp,-64
    80004148:	fc06                	sd	ra,56(sp)
    8000414a:	f822                	sd	s0,48(sp)
    8000414c:	f426                	sd	s1,40(sp)
    8000414e:	f04a                	sd	s2,32(sp)
    80004150:	ec4e                	sd	s3,24(sp)
    80004152:	e852                	sd	s4,16(sp)
    80004154:	e456                	sd	s5,8(sp)
    80004156:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004158:	0001d497          	auipc	s1,0x1d
    8000415c:	7b048493          	addi	s1,s1,1968 # 80021908 <log>
    80004160:	8526                	mv	a0,s1
    80004162:	ffffd097          	auipc	ra,0xffffd
    80004166:	aae080e7          	jalr	-1362(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    8000416a:	509c                	lw	a5,32(s1)
    8000416c:	37fd                	addiw	a5,a5,-1
    8000416e:	0007891b          	sext.w	s2,a5
    80004172:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004174:	50dc                	lw	a5,36(s1)
    80004176:	efb9                	bnez	a5,800041d4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004178:	06091663          	bnez	s2,800041e4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000417c:	0001d497          	auipc	s1,0x1d
    80004180:	78c48493          	addi	s1,s1,1932 # 80021908 <log>
    80004184:	4785                	li	a5,1
    80004186:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004188:	8526                	mv	a0,s1
    8000418a:	ffffd097          	auipc	ra,0xffffd
    8000418e:	b3a080e7          	jalr	-1222(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004192:	54dc                	lw	a5,44(s1)
    80004194:	06f04763          	bgtz	a5,80004202 <end_op+0xbc>
    acquire(&log.lock);
    80004198:	0001d497          	auipc	s1,0x1d
    8000419c:	77048493          	addi	s1,s1,1904 # 80021908 <log>
    800041a0:	8526                	mv	a0,s1
    800041a2:	ffffd097          	auipc	ra,0xffffd
    800041a6:	a6e080e7          	jalr	-1426(ra) # 80000c10 <acquire>
    log.committing = 0;
    800041aa:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041ae:	8526                	mv	a0,s1
    800041b0:	ffffe097          	auipc	ra,0xffffe
    800041b4:	2c0080e7          	jalr	704(ra) # 80002470 <wakeup>
    release(&log.lock);
    800041b8:	8526                	mv	a0,s1
    800041ba:	ffffd097          	auipc	ra,0xffffd
    800041be:	b0a080e7          	jalr	-1270(ra) # 80000cc4 <release>
}
    800041c2:	70e2                	ld	ra,56(sp)
    800041c4:	7442                	ld	s0,48(sp)
    800041c6:	74a2                	ld	s1,40(sp)
    800041c8:	7902                	ld	s2,32(sp)
    800041ca:	69e2                	ld	s3,24(sp)
    800041cc:	6a42                	ld	s4,16(sp)
    800041ce:	6aa2                	ld	s5,8(sp)
    800041d0:	6121                	addi	sp,sp,64
    800041d2:	8082                	ret
    panic("log.committing");
    800041d4:	00004517          	auipc	a0,0x4
    800041d8:	46c50513          	addi	a0,a0,1132 # 80008640 <syscalls+0x1e0>
    800041dc:	ffffc097          	auipc	ra,0xffffc
    800041e0:	36c080e7          	jalr	876(ra) # 80000548 <panic>
    wakeup(&log);
    800041e4:	0001d497          	auipc	s1,0x1d
    800041e8:	72448493          	addi	s1,s1,1828 # 80021908 <log>
    800041ec:	8526                	mv	a0,s1
    800041ee:	ffffe097          	auipc	ra,0xffffe
    800041f2:	282080e7          	jalr	642(ra) # 80002470 <wakeup>
  release(&log.lock);
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	acc080e7          	jalr	-1332(ra) # 80000cc4 <release>
  if(do_commit){
    80004200:	b7c9                	j	800041c2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004202:	0001da97          	auipc	s5,0x1d
    80004206:	736a8a93          	addi	s5,s5,1846 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000420a:	0001da17          	auipc	s4,0x1d
    8000420e:	6fea0a13          	addi	s4,s4,1790 # 80021908 <log>
    80004212:	018a2583          	lw	a1,24(s4)
    80004216:	012585bb          	addw	a1,a1,s2
    8000421a:	2585                	addiw	a1,a1,1
    8000421c:	028a2503          	lw	a0,40(s4)
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	ce8080e7          	jalr	-792(ra) # 80002f08 <bread>
    80004228:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000422a:	000aa583          	lw	a1,0(s5)
    8000422e:	028a2503          	lw	a0,40(s4)
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	cd6080e7          	jalr	-810(ra) # 80002f08 <bread>
    8000423a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000423c:	40000613          	li	a2,1024
    80004240:	05850593          	addi	a1,a0,88
    80004244:	05848513          	addi	a0,s1,88
    80004248:	ffffd097          	auipc	ra,0xffffd
    8000424c:	b24080e7          	jalr	-1244(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004250:	8526                	mv	a0,s1
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	da8080e7          	jalr	-600(ra) # 80002ffa <bwrite>
    brelse(from);
    8000425a:	854e                	mv	a0,s3
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	ddc080e7          	jalr	-548(ra) # 80003038 <brelse>
    brelse(to);
    80004264:	8526                	mv	a0,s1
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	dd2080e7          	jalr	-558(ra) # 80003038 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000426e:	2905                	addiw	s2,s2,1
    80004270:	0a91                	addi	s5,s5,4
    80004272:	02ca2783          	lw	a5,44(s4)
    80004276:	f8f94ee3          	blt	s2,a5,80004212 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	c7a080e7          	jalr	-902(ra) # 80003ef4 <write_head>
    install_trans(); // Now install writes to home locations
    80004282:	00000097          	auipc	ra,0x0
    80004286:	cec080e7          	jalr	-788(ra) # 80003f6e <install_trans>
    log.lh.n = 0;
    8000428a:	0001d797          	auipc	a5,0x1d
    8000428e:	6a07a523          	sw	zero,1706(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004292:	00000097          	auipc	ra,0x0
    80004296:	c62080e7          	jalr	-926(ra) # 80003ef4 <write_head>
    8000429a:	bdfd                	j	80004198 <end_op+0x52>

000000008000429c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000429c:	1101                	addi	sp,sp,-32
    8000429e:	ec06                	sd	ra,24(sp)
    800042a0:	e822                	sd	s0,16(sp)
    800042a2:	e426                	sd	s1,8(sp)
    800042a4:	e04a                	sd	s2,0(sp)
    800042a6:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042a8:	0001d717          	auipc	a4,0x1d
    800042ac:	68c72703          	lw	a4,1676(a4) # 80021934 <log+0x2c>
    800042b0:	47f5                	li	a5,29
    800042b2:	08e7c063          	blt	a5,a4,80004332 <log_write+0x96>
    800042b6:	84aa                	mv	s1,a0
    800042b8:	0001d797          	auipc	a5,0x1d
    800042bc:	66c7a783          	lw	a5,1644(a5) # 80021924 <log+0x1c>
    800042c0:	37fd                	addiw	a5,a5,-1
    800042c2:	06f75863          	bge	a4,a5,80004332 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042c6:	0001d797          	auipc	a5,0x1d
    800042ca:	6627a783          	lw	a5,1634(a5) # 80021928 <log+0x20>
    800042ce:	06f05a63          	blez	a5,80004342 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800042d2:	0001d917          	auipc	s2,0x1d
    800042d6:	63690913          	addi	s2,s2,1590 # 80021908 <log>
    800042da:	854a                	mv	a0,s2
    800042dc:	ffffd097          	auipc	ra,0xffffd
    800042e0:	934080e7          	jalr	-1740(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800042e4:	02c92603          	lw	a2,44(s2)
    800042e8:	06c05563          	blez	a2,80004352 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042ec:	44cc                	lw	a1,12(s1)
    800042ee:	0001d717          	auipc	a4,0x1d
    800042f2:	64a70713          	addi	a4,a4,1610 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042f6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042f8:	4314                	lw	a3,0(a4)
    800042fa:	04b68d63          	beq	a3,a1,80004354 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800042fe:	2785                	addiw	a5,a5,1
    80004300:	0711                	addi	a4,a4,4
    80004302:	fec79be3          	bne	a5,a2,800042f8 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004306:	0621                	addi	a2,a2,8
    80004308:	060a                	slli	a2,a2,0x2
    8000430a:	0001d797          	auipc	a5,0x1d
    8000430e:	5fe78793          	addi	a5,a5,1534 # 80021908 <log>
    80004312:	963e                	add	a2,a2,a5
    80004314:	44dc                	lw	a5,12(s1)
    80004316:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004318:	8526                	mv	a0,s1
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	dbc080e7          	jalr	-580(ra) # 800030d6 <bpin>
    log.lh.n++;
    80004322:	0001d717          	auipc	a4,0x1d
    80004326:	5e670713          	addi	a4,a4,1510 # 80021908 <log>
    8000432a:	575c                	lw	a5,44(a4)
    8000432c:	2785                	addiw	a5,a5,1
    8000432e:	d75c                	sw	a5,44(a4)
    80004330:	a83d                	j	8000436e <log_write+0xd2>
    panic("too big a transaction");
    80004332:	00004517          	auipc	a0,0x4
    80004336:	31e50513          	addi	a0,a0,798 # 80008650 <syscalls+0x1f0>
    8000433a:	ffffc097          	auipc	ra,0xffffc
    8000433e:	20e080e7          	jalr	526(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004342:	00004517          	auipc	a0,0x4
    80004346:	32650513          	addi	a0,a0,806 # 80008668 <syscalls+0x208>
    8000434a:	ffffc097          	auipc	ra,0xffffc
    8000434e:	1fe080e7          	jalr	510(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004352:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004354:	00878713          	addi	a4,a5,8
    80004358:	00271693          	slli	a3,a4,0x2
    8000435c:	0001d717          	auipc	a4,0x1d
    80004360:	5ac70713          	addi	a4,a4,1452 # 80021908 <log>
    80004364:	9736                	add	a4,a4,a3
    80004366:	44d4                	lw	a3,12(s1)
    80004368:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000436a:	faf607e3          	beq	a2,a5,80004318 <log_write+0x7c>
  }
  release(&log.lock);
    8000436e:	0001d517          	auipc	a0,0x1d
    80004372:	59a50513          	addi	a0,a0,1434 # 80021908 <log>
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	94e080e7          	jalr	-1714(ra) # 80000cc4 <release>
}
    8000437e:	60e2                	ld	ra,24(sp)
    80004380:	6442                	ld	s0,16(sp)
    80004382:	64a2                	ld	s1,8(sp)
    80004384:	6902                	ld	s2,0(sp)
    80004386:	6105                	addi	sp,sp,32
    80004388:	8082                	ret

000000008000438a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000438a:	1101                	addi	sp,sp,-32
    8000438c:	ec06                	sd	ra,24(sp)
    8000438e:	e822                	sd	s0,16(sp)
    80004390:	e426                	sd	s1,8(sp)
    80004392:	e04a                	sd	s2,0(sp)
    80004394:	1000                	addi	s0,sp,32
    80004396:	84aa                	mv	s1,a0
    80004398:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000439a:	00004597          	auipc	a1,0x4
    8000439e:	2ee58593          	addi	a1,a1,750 # 80008688 <syscalls+0x228>
    800043a2:	0521                	addi	a0,a0,8
    800043a4:	ffffc097          	auipc	ra,0xffffc
    800043a8:	7dc080e7          	jalr	2012(ra) # 80000b80 <initlock>
  lk->name = name;
    800043ac:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043b0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043b4:	0204a423          	sw	zero,40(s1)
}
    800043b8:	60e2                	ld	ra,24(sp)
    800043ba:	6442                	ld	s0,16(sp)
    800043bc:	64a2                	ld	s1,8(sp)
    800043be:	6902                	ld	s2,0(sp)
    800043c0:	6105                	addi	sp,sp,32
    800043c2:	8082                	ret

00000000800043c4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043c4:	1101                	addi	sp,sp,-32
    800043c6:	ec06                	sd	ra,24(sp)
    800043c8:	e822                	sd	s0,16(sp)
    800043ca:	e426                	sd	s1,8(sp)
    800043cc:	e04a                	sd	s2,0(sp)
    800043ce:	1000                	addi	s0,sp,32
    800043d0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043d2:	00850913          	addi	s2,a0,8
    800043d6:	854a                	mv	a0,s2
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	838080e7          	jalr	-1992(ra) # 80000c10 <acquire>
  while (lk->locked) {
    800043e0:	409c                	lw	a5,0(s1)
    800043e2:	cb89                	beqz	a5,800043f4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043e4:	85ca                	mv	a1,s2
    800043e6:	8526                	mv	a0,s1
    800043e8:	ffffe097          	auipc	ra,0xffffe
    800043ec:	f02080e7          	jalr	-254(ra) # 800022ea <sleep>
  while (lk->locked) {
    800043f0:	409c                	lw	a5,0(s1)
    800043f2:	fbed                	bnez	a5,800043e4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043f4:	4785                	li	a5,1
    800043f6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	6e6080e7          	jalr	1766(ra) # 80001ade <myproc>
    80004400:	5d1c                	lw	a5,56(a0)
    80004402:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004404:	854a                	mv	a0,s2
    80004406:	ffffd097          	auipc	ra,0xffffd
    8000440a:	8be080e7          	jalr	-1858(ra) # 80000cc4 <release>
}
    8000440e:	60e2                	ld	ra,24(sp)
    80004410:	6442                	ld	s0,16(sp)
    80004412:	64a2                	ld	s1,8(sp)
    80004414:	6902                	ld	s2,0(sp)
    80004416:	6105                	addi	sp,sp,32
    80004418:	8082                	ret

000000008000441a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000441a:	1101                	addi	sp,sp,-32
    8000441c:	ec06                	sd	ra,24(sp)
    8000441e:	e822                	sd	s0,16(sp)
    80004420:	e426                	sd	s1,8(sp)
    80004422:	e04a                	sd	s2,0(sp)
    80004424:	1000                	addi	s0,sp,32
    80004426:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004428:	00850913          	addi	s2,a0,8
    8000442c:	854a                	mv	a0,s2
    8000442e:	ffffc097          	auipc	ra,0xffffc
    80004432:	7e2080e7          	jalr	2018(ra) # 80000c10 <acquire>
  lk->locked = 0;
    80004436:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000443a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000443e:	8526                	mv	a0,s1
    80004440:	ffffe097          	auipc	ra,0xffffe
    80004444:	030080e7          	jalr	48(ra) # 80002470 <wakeup>
  release(&lk->lk);
    80004448:	854a                	mv	a0,s2
    8000444a:	ffffd097          	auipc	ra,0xffffd
    8000444e:	87a080e7          	jalr	-1926(ra) # 80000cc4 <release>
}
    80004452:	60e2                	ld	ra,24(sp)
    80004454:	6442                	ld	s0,16(sp)
    80004456:	64a2                	ld	s1,8(sp)
    80004458:	6902                	ld	s2,0(sp)
    8000445a:	6105                	addi	sp,sp,32
    8000445c:	8082                	ret

000000008000445e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000445e:	7179                	addi	sp,sp,-48
    80004460:	f406                	sd	ra,40(sp)
    80004462:	f022                	sd	s0,32(sp)
    80004464:	ec26                	sd	s1,24(sp)
    80004466:	e84a                	sd	s2,16(sp)
    80004468:	e44e                	sd	s3,8(sp)
    8000446a:	1800                	addi	s0,sp,48
    8000446c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000446e:	00850913          	addi	s2,a0,8
    80004472:	854a                	mv	a0,s2
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	79c080e7          	jalr	1948(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000447c:	409c                	lw	a5,0(s1)
    8000447e:	ef99                	bnez	a5,8000449c <holdingsleep+0x3e>
    80004480:	4481                	li	s1,0
  release(&lk->lk);
    80004482:	854a                	mv	a0,s2
    80004484:	ffffd097          	auipc	ra,0xffffd
    80004488:	840080e7          	jalr	-1984(ra) # 80000cc4 <release>
  return r;
}
    8000448c:	8526                	mv	a0,s1
    8000448e:	70a2                	ld	ra,40(sp)
    80004490:	7402                	ld	s0,32(sp)
    80004492:	64e2                	ld	s1,24(sp)
    80004494:	6942                	ld	s2,16(sp)
    80004496:	69a2                	ld	s3,8(sp)
    80004498:	6145                	addi	sp,sp,48
    8000449a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000449c:	0284a983          	lw	s3,40(s1)
    800044a0:	ffffd097          	auipc	ra,0xffffd
    800044a4:	63e080e7          	jalr	1598(ra) # 80001ade <myproc>
    800044a8:	5d04                	lw	s1,56(a0)
    800044aa:	413484b3          	sub	s1,s1,s3
    800044ae:	0014b493          	seqz	s1,s1
    800044b2:	bfc1                	j	80004482 <holdingsleep+0x24>

00000000800044b4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044b4:	1141                	addi	sp,sp,-16
    800044b6:	e406                	sd	ra,8(sp)
    800044b8:	e022                	sd	s0,0(sp)
    800044ba:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044bc:	00004597          	auipc	a1,0x4
    800044c0:	1dc58593          	addi	a1,a1,476 # 80008698 <syscalls+0x238>
    800044c4:	0001d517          	auipc	a0,0x1d
    800044c8:	58c50513          	addi	a0,a0,1420 # 80021a50 <ftable>
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	6b4080e7          	jalr	1716(ra) # 80000b80 <initlock>
}
    800044d4:	60a2                	ld	ra,8(sp)
    800044d6:	6402                	ld	s0,0(sp)
    800044d8:	0141                	addi	sp,sp,16
    800044da:	8082                	ret

00000000800044dc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044dc:	1101                	addi	sp,sp,-32
    800044de:	ec06                	sd	ra,24(sp)
    800044e0:	e822                	sd	s0,16(sp)
    800044e2:	e426                	sd	s1,8(sp)
    800044e4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044e6:	0001d517          	auipc	a0,0x1d
    800044ea:	56a50513          	addi	a0,a0,1386 # 80021a50 <ftable>
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	722080e7          	jalr	1826(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044f6:	0001d497          	auipc	s1,0x1d
    800044fa:	57248493          	addi	s1,s1,1394 # 80021a68 <ftable+0x18>
    800044fe:	0001e717          	auipc	a4,0x1e
    80004502:	50a70713          	addi	a4,a4,1290 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004506:	40dc                	lw	a5,4(s1)
    80004508:	cf99                	beqz	a5,80004526 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000450a:	02848493          	addi	s1,s1,40
    8000450e:	fee49ce3          	bne	s1,a4,80004506 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004512:	0001d517          	auipc	a0,0x1d
    80004516:	53e50513          	addi	a0,a0,1342 # 80021a50 <ftable>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	7aa080e7          	jalr	1962(ra) # 80000cc4 <release>
  return 0;
    80004522:	4481                	li	s1,0
    80004524:	a819                	j	8000453a <filealloc+0x5e>
      f->ref = 1;
    80004526:	4785                	li	a5,1
    80004528:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000452a:	0001d517          	auipc	a0,0x1d
    8000452e:	52650513          	addi	a0,a0,1318 # 80021a50 <ftable>
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	792080e7          	jalr	1938(ra) # 80000cc4 <release>
}
    8000453a:	8526                	mv	a0,s1
    8000453c:	60e2                	ld	ra,24(sp)
    8000453e:	6442                	ld	s0,16(sp)
    80004540:	64a2                	ld	s1,8(sp)
    80004542:	6105                	addi	sp,sp,32
    80004544:	8082                	ret

0000000080004546 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004546:	1101                	addi	sp,sp,-32
    80004548:	ec06                	sd	ra,24(sp)
    8000454a:	e822                	sd	s0,16(sp)
    8000454c:	e426                	sd	s1,8(sp)
    8000454e:	1000                	addi	s0,sp,32
    80004550:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004552:	0001d517          	auipc	a0,0x1d
    80004556:	4fe50513          	addi	a0,a0,1278 # 80021a50 <ftable>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	6b6080e7          	jalr	1718(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004562:	40dc                	lw	a5,4(s1)
    80004564:	02f05263          	blez	a5,80004588 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004568:	2785                	addiw	a5,a5,1
    8000456a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000456c:	0001d517          	auipc	a0,0x1d
    80004570:	4e450513          	addi	a0,a0,1252 # 80021a50 <ftable>
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	750080e7          	jalr	1872(ra) # 80000cc4 <release>
  return f;
}
    8000457c:	8526                	mv	a0,s1
    8000457e:	60e2                	ld	ra,24(sp)
    80004580:	6442                	ld	s0,16(sp)
    80004582:	64a2                	ld	s1,8(sp)
    80004584:	6105                	addi	sp,sp,32
    80004586:	8082                	ret
    panic("filedup");
    80004588:	00004517          	auipc	a0,0x4
    8000458c:	11850513          	addi	a0,a0,280 # 800086a0 <syscalls+0x240>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	fb8080e7          	jalr	-72(ra) # 80000548 <panic>

0000000080004598 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004598:	7139                	addi	sp,sp,-64
    8000459a:	fc06                	sd	ra,56(sp)
    8000459c:	f822                	sd	s0,48(sp)
    8000459e:	f426                	sd	s1,40(sp)
    800045a0:	f04a                	sd	s2,32(sp)
    800045a2:	ec4e                	sd	s3,24(sp)
    800045a4:	e852                	sd	s4,16(sp)
    800045a6:	e456                	sd	s5,8(sp)
    800045a8:	0080                	addi	s0,sp,64
    800045aa:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045ac:	0001d517          	auipc	a0,0x1d
    800045b0:	4a450513          	addi	a0,a0,1188 # 80021a50 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	65c080e7          	jalr	1628(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800045bc:	40dc                	lw	a5,4(s1)
    800045be:	06f05163          	blez	a5,80004620 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045c2:	37fd                	addiw	a5,a5,-1
    800045c4:	0007871b          	sext.w	a4,a5
    800045c8:	c0dc                	sw	a5,4(s1)
    800045ca:	06e04363          	bgtz	a4,80004630 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045ce:	0004a903          	lw	s2,0(s1)
    800045d2:	0094ca83          	lbu	s5,9(s1)
    800045d6:	0104ba03          	ld	s4,16(s1)
    800045da:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045de:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045e2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045e6:	0001d517          	auipc	a0,0x1d
    800045ea:	46a50513          	addi	a0,a0,1130 # 80021a50 <ftable>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	6d6080e7          	jalr	1750(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    800045f6:	4785                	li	a5,1
    800045f8:	04f90d63          	beq	s2,a5,80004652 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045fc:	3979                	addiw	s2,s2,-2
    800045fe:	4785                	li	a5,1
    80004600:	0527e063          	bltu	a5,s2,80004640 <fileclose+0xa8>
    begin_op();
    80004604:	00000097          	auipc	ra,0x0
    80004608:	ac2080e7          	jalr	-1342(ra) # 800040c6 <begin_op>
    iput(ff.ip);
    8000460c:	854e                	mv	a0,s3
    8000460e:	fffff097          	auipc	ra,0xfffff
    80004612:	2b6080e7          	jalr	694(ra) # 800038c4 <iput>
    end_op();
    80004616:	00000097          	auipc	ra,0x0
    8000461a:	b30080e7          	jalr	-1232(ra) # 80004146 <end_op>
    8000461e:	a00d                	j	80004640 <fileclose+0xa8>
    panic("fileclose");
    80004620:	00004517          	auipc	a0,0x4
    80004624:	08850513          	addi	a0,a0,136 # 800086a8 <syscalls+0x248>
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	f20080e7          	jalr	-224(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004630:	0001d517          	auipc	a0,0x1d
    80004634:	42050513          	addi	a0,a0,1056 # 80021a50 <ftable>
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	68c080e7          	jalr	1676(ra) # 80000cc4 <release>
  }
}
    80004640:	70e2                	ld	ra,56(sp)
    80004642:	7442                	ld	s0,48(sp)
    80004644:	74a2                	ld	s1,40(sp)
    80004646:	7902                	ld	s2,32(sp)
    80004648:	69e2                	ld	s3,24(sp)
    8000464a:	6a42                	ld	s4,16(sp)
    8000464c:	6aa2                	ld	s5,8(sp)
    8000464e:	6121                	addi	sp,sp,64
    80004650:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004652:	85d6                	mv	a1,s5
    80004654:	8552                	mv	a0,s4
    80004656:	00000097          	auipc	ra,0x0
    8000465a:	372080e7          	jalr	882(ra) # 800049c8 <pipeclose>
    8000465e:	b7cd                	j	80004640 <fileclose+0xa8>

0000000080004660 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004660:	715d                	addi	sp,sp,-80
    80004662:	e486                	sd	ra,72(sp)
    80004664:	e0a2                	sd	s0,64(sp)
    80004666:	fc26                	sd	s1,56(sp)
    80004668:	f84a                	sd	s2,48(sp)
    8000466a:	f44e                	sd	s3,40(sp)
    8000466c:	0880                	addi	s0,sp,80
    8000466e:	84aa                	mv	s1,a0
    80004670:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004672:	ffffd097          	auipc	ra,0xffffd
    80004676:	46c080e7          	jalr	1132(ra) # 80001ade <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000467a:	409c                	lw	a5,0(s1)
    8000467c:	37f9                	addiw	a5,a5,-2
    8000467e:	4705                	li	a4,1
    80004680:	04f76763          	bltu	a4,a5,800046ce <filestat+0x6e>
    80004684:	892a                	mv	s2,a0
    ilock(f->ip);
    80004686:	6c88                	ld	a0,24(s1)
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	082080e7          	jalr	130(ra) # 8000370a <ilock>
    stati(f->ip, &st);
    80004690:	fb840593          	addi	a1,s0,-72
    80004694:	6c88                	ld	a0,24(s1)
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	2fe080e7          	jalr	766(ra) # 80003994 <stati>
    iunlock(f->ip);
    8000469e:	6c88                	ld	a0,24(s1)
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	12c080e7          	jalr	300(ra) # 800037cc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046a8:	46e1                	li	a3,24
    800046aa:	fb840613          	addi	a2,s0,-72
    800046ae:	85ce                	mv	a1,s3
    800046b0:	05093503          	ld	a0,80(s2)
    800046b4:	ffffd097          	auipc	ra,0xffffd
    800046b8:	11e080e7          	jalr	286(ra) # 800017d2 <copyout>
    800046bc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046c0:	60a6                	ld	ra,72(sp)
    800046c2:	6406                	ld	s0,64(sp)
    800046c4:	74e2                	ld	s1,56(sp)
    800046c6:	7942                	ld	s2,48(sp)
    800046c8:	79a2                	ld	s3,40(sp)
    800046ca:	6161                	addi	sp,sp,80
    800046cc:	8082                	ret
  return -1;
    800046ce:	557d                	li	a0,-1
    800046d0:	bfc5                	j	800046c0 <filestat+0x60>

00000000800046d2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046d2:	7179                	addi	sp,sp,-48
    800046d4:	f406                	sd	ra,40(sp)
    800046d6:	f022                	sd	s0,32(sp)
    800046d8:	ec26                	sd	s1,24(sp)
    800046da:	e84a                	sd	s2,16(sp)
    800046dc:	e44e                	sd	s3,8(sp)
    800046de:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046e0:	00854783          	lbu	a5,8(a0)
    800046e4:	c3d5                	beqz	a5,80004788 <fileread+0xb6>
    800046e6:	84aa                	mv	s1,a0
    800046e8:	89ae                	mv	s3,a1
    800046ea:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046ec:	411c                	lw	a5,0(a0)
    800046ee:	4705                	li	a4,1
    800046f0:	04e78963          	beq	a5,a4,80004742 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046f4:	470d                	li	a4,3
    800046f6:	04e78d63          	beq	a5,a4,80004750 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046fa:	4709                	li	a4,2
    800046fc:	06e79e63          	bne	a5,a4,80004778 <fileread+0xa6>
    ilock(f->ip);
    80004700:	6d08                	ld	a0,24(a0)
    80004702:	fffff097          	auipc	ra,0xfffff
    80004706:	008080e7          	jalr	8(ra) # 8000370a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000470a:	874a                	mv	a4,s2
    8000470c:	5094                	lw	a3,32(s1)
    8000470e:	864e                	mv	a2,s3
    80004710:	4585                	li	a1,1
    80004712:	6c88                	ld	a0,24(s1)
    80004714:	fffff097          	auipc	ra,0xfffff
    80004718:	2aa080e7          	jalr	682(ra) # 800039be <readi>
    8000471c:	892a                	mv	s2,a0
    8000471e:	00a05563          	blez	a0,80004728 <fileread+0x56>
      f->off += r;
    80004722:	509c                	lw	a5,32(s1)
    80004724:	9fa9                	addw	a5,a5,a0
    80004726:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004728:	6c88                	ld	a0,24(s1)
    8000472a:	fffff097          	auipc	ra,0xfffff
    8000472e:	0a2080e7          	jalr	162(ra) # 800037cc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004732:	854a                	mv	a0,s2
    80004734:	70a2                	ld	ra,40(sp)
    80004736:	7402                	ld	s0,32(sp)
    80004738:	64e2                	ld	s1,24(sp)
    8000473a:	6942                	ld	s2,16(sp)
    8000473c:	69a2                	ld	s3,8(sp)
    8000473e:	6145                	addi	sp,sp,48
    80004740:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004742:	6908                	ld	a0,16(a0)
    80004744:	00000097          	auipc	ra,0x0
    80004748:	418080e7          	jalr	1048(ra) # 80004b5c <piperead>
    8000474c:	892a                	mv	s2,a0
    8000474e:	b7d5                	j	80004732 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004750:	02451783          	lh	a5,36(a0)
    80004754:	03079693          	slli	a3,a5,0x30
    80004758:	92c1                	srli	a3,a3,0x30
    8000475a:	4725                	li	a4,9
    8000475c:	02d76863          	bltu	a4,a3,8000478c <fileread+0xba>
    80004760:	0792                	slli	a5,a5,0x4
    80004762:	0001d717          	auipc	a4,0x1d
    80004766:	24e70713          	addi	a4,a4,590 # 800219b0 <devsw>
    8000476a:	97ba                	add	a5,a5,a4
    8000476c:	639c                	ld	a5,0(a5)
    8000476e:	c38d                	beqz	a5,80004790 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004770:	4505                	li	a0,1
    80004772:	9782                	jalr	a5
    80004774:	892a                	mv	s2,a0
    80004776:	bf75                	j	80004732 <fileread+0x60>
    panic("fileread");
    80004778:	00004517          	auipc	a0,0x4
    8000477c:	f4050513          	addi	a0,a0,-192 # 800086b8 <syscalls+0x258>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	dc8080e7          	jalr	-568(ra) # 80000548 <panic>
    return -1;
    80004788:	597d                	li	s2,-1
    8000478a:	b765                	j	80004732 <fileread+0x60>
      return -1;
    8000478c:	597d                	li	s2,-1
    8000478e:	b755                	j	80004732 <fileread+0x60>
    80004790:	597d                	li	s2,-1
    80004792:	b745                	j	80004732 <fileread+0x60>

0000000080004794 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004794:	00954783          	lbu	a5,9(a0)
    80004798:	14078563          	beqz	a5,800048e2 <filewrite+0x14e>
{
    8000479c:	715d                	addi	sp,sp,-80
    8000479e:	e486                	sd	ra,72(sp)
    800047a0:	e0a2                	sd	s0,64(sp)
    800047a2:	fc26                	sd	s1,56(sp)
    800047a4:	f84a                	sd	s2,48(sp)
    800047a6:	f44e                	sd	s3,40(sp)
    800047a8:	f052                	sd	s4,32(sp)
    800047aa:	ec56                	sd	s5,24(sp)
    800047ac:	e85a                	sd	s6,16(sp)
    800047ae:	e45e                	sd	s7,8(sp)
    800047b0:	e062                	sd	s8,0(sp)
    800047b2:	0880                	addi	s0,sp,80
    800047b4:	892a                	mv	s2,a0
    800047b6:	8aae                	mv	s5,a1
    800047b8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ba:	411c                	lw	a5,0(a0)
    800047bc:	4705                	li	a4,1
    800047be:	02e78263          	beq	a5,a4,800047e2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047c2:	470d                	li	a4,3
    800047c4:	02e78563          	beq	a5,a4,800047ee <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047c8:	4709                	li	a4,2
    800047ca:	10e79463          	bne	a5,a4,800048d2 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047ce:	0ec05e63          	blez	a2,800048ca <filewrite+0x136>
    int i = 0;
    800047d2:	4981                	li	s3,0
    800047d4:	6b05                	lui	s6,0x1
    800047d6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800047da:	6b85                	lui	s7,0x1
    800047dc:	c00b8b9b          	addiw	s7,s7,-1024
    800047e0:	a851                	j	80004874 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047e2:	6908                	ld	a0,16(a0)
    800047e4:	00000097          	auipc	ra,0x0
    800047e8:	254080e7          	jalr	596(ra) # 80004a38 <pipewrite>
    800047ec:	a85d                	j	800048a2 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047ee:	02451783          	lh	a5,36(a0)
    800047f2:	03079693          	slli	a3,a5,0x30
    800047f6:	92c1                	srli	a3,a3,0x30
    800047f8:	4725                	li	a4,9
    800047fa:	0ed76663          	bltu	a4,a3,800048e6 <filewrite+0x152>
    800047fe:	0792                	slli	a5,a5,0x4
    80004800:	0001d717          	auipc	a4,0x1d
    80004804:	1b070713          	addi	a4,a4,432 # 800219b0 <devsw>
    80004808:	97ba                	add	a5,a5,a4
    8000480a:	679c                	ld	a5,8(a5)
    8000480c:	cff9                	beqz	a5,800048ea <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000480e:	4505                	li	a0,1
    80004810:	9782                	jalr	a5
    80004812:	a841                	j	800048a2 <filewrite+0x10e>
    80004814:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004818:	00000097          	auipc	ra,0x0
    8000481c:	8ae080e7          	jalr	-1874(ra) # 800040c6 <begin_op>
      ilock(f->ip);
    80004820:	01893503          	ld	a0,24(s2)
    80004824:	fffff097          	auipc	ra,0xfffff
    80004828:	ee6080e7          	jalr	-282(ra) # 8000370a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000482c:	8762                	mv	a4,s8
    8000482e:	02092683          	lw	a3,32(s2)
    80004832:	01598633          	add	a2,s3,s5
    80004836:	4585                	li	a1,1
    80004838:	01893503          	ld	a0,24(s2)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	278080e7          	jalr	632(ra) # 80003ab4 <writei>
    80004844:	84aa                	mv	s1,a0
    80004846:	02a05f63          	blez	a0,80004884 <filewrite+0xf0>
        f->off += r;
    8000484a:	02092783          	lw	a5,32(s2)
    8000484e:	9fa9                	addw	a5,a5,a0
    80004850:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004854:	01893503          	ld	a0,24(s2)
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	f74080e7          	jalr	-140(ra) # 800037cc <iunlock>
      end_op();
    80004860:	00000097          	auipc	ra,0x0
    80004864:	8e6080e7          	jalr	-1818(ra) # 80004146 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004868:	049c1963          	bne	s8,s1,800048ba <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000486c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004870:	0349d663          	bge	s3,s4,8000489c <filewrite+0x108>
      int n1 = n - i;
    80004874:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004878:	84be                	mv	s1,a5
    8000487a:	2781                	sext.w	a5,a5
    8000487c:	f8fb5ce3          	bge	s6,a5,80004814 <filewrite+0x80>
    80004880:	84de                	mv	s1,s7
    80004882:	bf49                	j	80004814 <filewrite+0x80>
      iunlock(f->ip);
    80004884:	01893503          	ld	a0,24(s2)
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	f44080e7          	jalr	-188(ra) # 800037cc <iunlock>
      end_op();
    80004890:	00000097          	auipc	ra,0x0
    80004894:	8b6080e7          	jalr	-1866(ra) # 80004146 <end_op>
      if(r < 0)
    80004898:	fc04d8e3          	bgez	s1,80004868 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    8000489c:	8552                	mv	a0,s4
    8000489e:	033a1863          	bne	s4,s3,800048ce <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048a2:	60a6                	ld	ra,72(sp)
    800048a4:	6406                	ld	s0,64(sp)
    800048a6:	74e2                	ld	s1,56(sp)
    800048a8:	7942                	ld	s2,48(sp)
    800048aa:	79a2                	ld	s3,40(sp)
    800048ac:	7a02                	ld	s4,32(sp)
    800048ae:	6ae2                	ld	s5,24(sp)
    800048b0:	6b42                	ld	s6,16(sp)
    800048b2:	6ba2                	ld	s7,8(sp)
    800048b4:	6c02                	ld	s8,0(sp)
    800048b6:	6161                	addi	sp,sp,80
    800048b8:	8082                	ret
        panic("short filewrite");
    800048ba:	00004517          	auipc	a0,0x4
    800048be:	e0e50513          	addi	a0,a0,-498 # 800086c8 <syscalls+0x268>
    800048c2:	ffffc097          	auipc	ra,0xffffc
    800048c6:	c86080e7          	jalr	-890(ra) # 80000548 <panic>
    int i = 0;
    800048ca:	4981                	li	s3,0
    800048cc:	bfc1                	j	8000489c <filewrite+0x108>
    ret = (i == n ? n : -1);
    800048ce:	557d                	li	a0,-1
    800048d0:	bfc9                	j	800048a2 <filewrite+0x10e>
    panic("filewrite");
    800048d2:	00004517          	auipc	a0,0x4
    800048d6:	e0650513          	addi	a0,a0,-506 # 800086d8 <syscalls+0x278>
    800048da:	ffffc097          	auipc	ra,0xffffc
    800048de:	c6e080e7          	jalr	-914(ra) # 80000548 <panic>
    return -1;
    800048e2:	557d                	li	a0,-1
}
    800048e4:	8082                	ret
      return -1;
    800048e6:	557d                	li	a0,-1
    800048e8:	bf6d                	j	800048a2 <filewrite+0x10e>
    800048ea:	557d                	li	a0,-1
    800048ec:	bf5d                	j	800048a2 <filewrite+0x10e>

00000000800048ee <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048ee:	7179                	addi	sp,sp,-48
    800048f0:	f406                	sd	ra,40(sp)
    800048f2:	f022                	sd	s0,32(sp)
    800048f4:	ec26                	sd	s1,24(sp)
    800048f6:	e84a                	sd	s2,16(sp)
    800048f8:	e44e                	sd	s3,8(sp)
    800048fa:	e052                	sd	s4,0(sp)
    800048fc:	1800                	addi	s0,sp,48
    800048fe:	84aa                	mv	s1,a0
    80004900:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004902:	0005b023          	sd	zero,0(a1)
    80004906:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	bd2080e7          	jalr	-1070(ra) # 800044dc <filealloc>
    80004912:	e088                	sd	a0,0(s1)
    80004914:	c551                	beqz	a0,800049a0 <pipealloc+0xb2>
    80004916:	00000097          	auipc	ra,0x0
    8000491a:	bc6080e7          	jalr	-1082(ra) # 800044dc <filealloc>
    8000491e:	00aa3023          	sd	a0,0(s4)
    80004922:	c92d                	beqz	a0,80004994 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	1fc080e7          	jalr	508(ra) # 80000b20 <kalloc>
    8000492c:	892a                	mv	s2,a0
    8000492e:	c125                	beqz	a0,8000498e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004930:	4985                	li	s3,1
    80004932:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004936:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000493a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000493e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004942:	00004597          	auipc	a1,0x4
    80004946:	da658593          	addi	a1,a1,-602 # 800086e8 <syscalls+0x288>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	236080e7          	jalr	566(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004952:	609c                	ld	a5,0(s1)
    80004954:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004958:	609c                	ld	a5,0(s1)
    8000495a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000495e:	609c                	ld	a5,0(s1)
    80004960:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004964:	609c                	ld	a5,0(s1)
    80004966:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000496a:	000a3783          	ld	a5,0(s4)
    8000496e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004972:	000a3783          	ld	a5,0(s4)
    80004976:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000497a:	000a3783          	ld	a5,0(s4)
    8000497e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004982:	000a3783          	ld	a5,0(s4)
    80004986:	0127b823          	sd	s2,16(a5)
  return 0;
    8000498a:	4501                	li	a0,0
    8000498c:	a025                	j	800049b4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000498e:	6088                	ld	a0,0(s1)
    80004990:	e501                	bnez	a0,80004998 <pipealloc+0xaa>
    80004992:	a039                	j	800049a0 <pipealloc+0xb2>
    80004994:	6088                	ld	a0,0(s1)
    80004996:	c51d                	beqz	a0,800049c4 <pipealloc+0xd6>
    fileclose(*f0);
    80004998:	00000097          	auipc	ra,0x0
    8000499c:	c00080e7          	jalr	-1024(ra) # 80004598 <fileclose>
  if(*f1)
    800049a0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049a4:	557d                	li	a0,-1
  if(*f1)
    800049a6:	c799                	beqz	a5,800049b4 <pipealloc+0xc6>
    fileclose(*f1);
    800049a8:	853e                	mv	a0,a5
    800049aa:	00000097          	auipc	ra,0x0
    800049ae:	bee080e7          	jalr	-1042(ra) # 80004598 <fileclose>
  return -1;
    800049b2:	557d                	li	a0,-1
}
    800049b4:	70a2                	ld	ra,40(sp)
    800049b6:	7402                	ld	s0,32(sp)
    800049b8:	64e2                	ld	s1,24(sp)
    800049ba:	6942                	ld	s2,16(sp)
    800049bc:	69a2                	ld	s3,8(sp)
    800049be:	6a02                	ld	s4,0(sp)
    800049c0:	6145                	addi	sp,sp,48
    800049c2:	8082                	ret
  return -1;
    800049c4:	557d                	li	a0,-1
    800049c6:	b7fd                	j	800049b4 <pipealloc+0xc6>

00000000800049c8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049c8:	1101                	addi	sp,sp,-32
    800049ca:	ec06                	sd	ra,24(sp)
    800049cc:	e822                	sd	s0,16(sp)
    800049ce:	e426                	sd	s1,8(sp)
    800049d0:	e04a                	sd	s2,0(sp)
    800049d2:	1000                	addi	s0,sp,32
    800049d4:	84aa                	mv	s1,a0
    800049d6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	238080e7          	jalr	568(ra) # 80000c10 <acquire>
  if(writable){
    800049e0:	02090d63          	beqz	s2,80004a1a <pipeclose+0x52>
    pi->writeopen = 0;
    800049e4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049e8:	21848513          	addi	a0,s1,536
    800049ec:	ffffe097          	auipc	ra,0xffffe
    800049f0:	a84080e7          	jalr	-1404(ra) # 80002470 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049f4:	2204b783          	ld	a5,544(s1)
    800049f8:	eb95                	bnez	a5,80004a2c <pipeclose+0x64>
    release(&pi->lock);
    800049fa:	8526                	mv	a0,s1
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	2c8080e7          	jalr	712(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004a04:	8526                	mv	a0,s1
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	01e080e7          	jalr	30(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a0e:	60e2                	ld	ra,24(sp)
    80004a10:	6442                	ld	s0,16(sp)
    80004a12:	64a2                	ld	s1,8(sp)
    80004a14:	6902                	ld	s2,0(sp)
    80004a16:	6105                	addi	sp,sp,32
    80004a18:	8082                	ret
    pi->readopen = 0;
    80004a1a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a1e:	21c48513          	addi	a0,s1,540
    80004a22:	ffffe097          	auipc	ra,0xffffe
    80004a26:	a4e080e7          	jalr	-1458(ra) # 80002470 <wakeup>
    80004a2a:	b7e9                	j	800049f4 <pipeclose+0x2c>
    release(&pi->lock);
    80004a2c:	8526                	mv	a0,s1
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	296080e7          	jalr	662(ra) # 80000cc4 <release>
}
    80004a36:	bfe1                	j	80004a0e <pipeclose+0x46>

0000000080004a38 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a38:	7119                	addi	sp,sp,-128
    80004a3a:	fc86                	sd	ra,120(sp)
    80004a3c:	f8a2                	sd	s0,112(sp)
    80004a3e:	f4a6                	sd	s1,104(sp)
    80004a40:	f0ca                	sd	s2,96(sp)
    80004a42:	ecce                	sd	s3,88(sp)
    80004a44:	e8d2                	sd	s4,80(sp)
    80004a46:	e4d6                	sd	s5,72(sp)
    80004a48:	e0da                	sd	s6,64(sp)
    80004a4a:	fc5e                	sd	s7,56(sp)
    80004a4c:	f862                	sd	s8,48(sp)
    80004a4e:	f466                	sd	s9,40(sp)
    80004a50:	f06a                	sd	s10,32(sp)
    80004a52:	ec6e                	sd	s11,24(sp)
    80004a54:	0100                	addi	s0,sp,128
    80004a56:	84aa                	mv	s1,a0
    80004a58:	8cae                	mv	s9,a1
    80004a5a:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a5c:	ffffd097          	auipc	ra,0xffffd
    80004a60:	082080e7          	jalr	130(ra) # 80001ade <myproc>
    80004a64:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a66:	8526                	mv	a0,s1
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	1a8080e7          	jalr	424(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004a70:	0d605963          	blez	s6,80004b42 <pipewrite+0x10a>
    80004a74:	89a6                	mv	s3,s1
    80004a76:	3b7d                	addiw	s6,s6,-1
    80004a78:	1b02                	slli	s6,s6,0x20
    80004a7a:	020b5b13          	srli	s6,s6,0x20
    80004a7e:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a80:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a84:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a88:	5dfd                	li	s11,-1
    80004a8a:	000b8d1b          	sext.w	s10,s7
    80004a8e:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a90:	2184a783          	lw	a5,536(s1)
    80004a94:	21c4a703          	lw	a4,540(s1)
    80004a98:	2007879b          	addiw	a5,a5,512
    80004a9c:	02f71b63          	bne	a4,a5,80004ad2 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004aa0:	2204a783          	lw	a5,544(s1)
    80004aa4:	cbad                	beqz	a5,80004b16 <pipewrite+0xde>
    80004aa6:	03092783          	lw	a5,48(s2)
    80004aaa:	e7b5                	bnez	a5,80004b16 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004aac:	8556                	mv	a0,s5
    80004aae:	ffffe097          	auipc	ra,0xffffe
    80004ab2:	9c2080e7          	jalr	-1598(ra) # 80002470 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ab6:	85ce                	mv	a1,s3
    80004ab8:	8552                	mv	a0,s4
    80004aba:	ffffe097          	auipc	ra,0xffffe
    80004abe:	830080e7          	jalr	-2000(ra) # 800022ea <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ac2:	2184a783          	lw	a5,536(s1)
    80004ac6:	21c4a703          	lw	a4,540(s1)
    80004aca:	2007879b          	addiw	a5,a5,512
    80004ace:	fcf709e3          	beq	a4,a5,80004aa0 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ad2:	4685                	li	a3,1
    80004ad4:	019b8633          	add	a2,s7,s9
    80004ad8:	f8f40593          	addi	a1,s0,-113
    80004adc:	05093503          	ld	a0,80(s2)
    80004ae0:	ffffd097          	auipc	ra,0xffffd
    80004ae4:	d7e080e7          	jalr	-642(ra) # 8000185e <copyin>
    80004ae8:	05b50e63          	beq	a0,s11,80004b44 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004aec:	21c4a783          	lw	a5,540(s1)
    80004af0:	0017871b          	addiw	a4,a5,1
    80004af4:	20e4ae23          	sw	a4,540(s1)
    80004af8:	1ff7f793          	andi	a5,a5,511
    80004afc:	97a6                	add	a5,a5,s1
    80004afe:	f8f44703          	lbu	a4,-113(s0)
    80004b02:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b06:	001d0c1b          	addiw	s8,s10,1
    80004b0a:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b0e:	036b8b63          	beq	s7,s6,80004b44 <pipewrite+0x10c>
    80004b12:	8bbe                	mv	s7,a5
    80004b14:	bf9d                	j	80004a8a <pipewrite+0x52>
        release(&pi->lock);
    80004b16:	8526                	mv	a0,s1
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	1ac080e7          	jalr	428(ra) # 80000cc4 <release>
        return -1;
    80004b20:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b22:	8562                	mv	a0,s8
    80004b24:	70e6                	ld	ra,120(sp)
    80004b26:	7446                	ld	s0,112(sp)
    80004b28:	74a6                	ld	s1,104(sp)
    80004b2a:	7906                	ld	s2,96(sp)
    80004b2c:	69e6                	ld	s3,88(sp)
    80004b2e:	6a46                	ld	s4,80(sp)
    80004b30:	6aa6                	ld	s5,72(sp)
    80004b32:	6b06                	ld	s6,64(sp)
    80004b34:	7be2                	ld	s7,56(sp)
    80004b36:	7c42                	ld	s8,48(sp)
    80004b38:	7ca2                	ld	s9,40(sp)
    80004b3a:	7d02                	ld	s10,32(sp)
    80004b3c:	6de2                	ld	s11,24(sp)
    80004b3e:	6109                	addi	sp,sp,128
    80004b40:	8082                	ret
  for(i = 0; i < n; i++){
    80004b42:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b44:	21848513          	addi	a0,s1,536
    80004b48:	ffffe097          	auipc	ra,0xffffe
    80004b4c:	928080e7          	jalr	-1752(ra) # 80002470 <wakeup>
  release(&pi->lock);
    80004b50:	8526                	mv	a0,s1
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	172080e7          	jalr	370(ra) # 80000cc4 <release>
  return i;
    80004b5a:	b7e1                	j	80004b22 <pipewrite+0xea>

0000000080004b5c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b5c:	715d                	addi	sp,sp,-80
    80004b5e:	e486                	sd	ra,72(sp)
    80004b60:	e0a2                	sd	s0,64(sp)
    80004b62:	fc26                	sd	s1,56(sp)
    80004b64:	f84a                	sd	s2,48(sp)
    80004b66:	f44e                	sd	s3,40(sp)
    80004b68:	f052                	sd	s4,32(sp)
    80004b6a:	ec56                	sd	s5,24(sp)
    80004b6c:	e85a                	sd	s6,16(sp)
    80004b6e:	0880                	addi	s0,sp,80
    80004b70:	84aa                	mv	s1,a0
    80004b72:	892e                	mv	s2,a1
    80004b74:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	f68080e7          	jalr	-152(ra) # 80001ade <myproc>
    80004b7e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b80:	8b26                	mv	s6,s1
    80004b82:	8526                	mv	a0,s1
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	08c080e7          	jalr	140(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b8c:	2184a703          	lw	a4,536(s1)
    80004b90:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b94:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b98:	02f71463          	bne	a4,a5,80004bc0 <piperead+0x64>
    80004b9c:	2244a783          	lw	a5,548(s1)
    80004ba0:	c385                	beqz	a5,80004bc0 <piperead+0x64>
    if(pr->killed){
    80004ba2:	030a2783          	lw	a5,48(s4)
    80004ba6:	ebc1                	bnez	a5,80004c36 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ba8:	85da                	mv	a1,s6
    80004baa:	854e                	mv	a0,s3
    80004bac:	ffffd097          	auipc	ra,0xffffd
    80004bb0:	73e080e7          	jalr	1854(ra) # 800022ea <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb4:	2184a703          	lw	a4,536(s1)
    80004bb8:	21c4a783          	lw	a5,540(s1)
    80004bbc:	fef700e3          	beq	a4,a5,80004b9c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bc0:	09505263          	blez	s5,80004c44 <piperead+0xe8>
    80004bc4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bc6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bc8:	2184a783          	lw	a5,536(s1)
    80004bcc:	21c4a703          	lw	a4,540(s1)
    80004bd0:	02f70d63          	beq	a4,a5,80004c0a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bd4:	0017871b          	addiw	a4,a5,1
    80004bd8:	20e4ac23          	sw	a4,536(s1)
    80004bdc:	1ff7f793          	andi	a5,a5,511
    80004be0:	97a6                	add	a5,a5,s1
    80004be2:	0187c783          	lbu	a5,24(a5)
    80004be6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bea:	4685                	li	a3,1
    80004bec:	fbf40613          	addi	a2,s0,-65
    80004bf0:	85ca                	mv	a1,s2
    80004bf2:	050a3503          	ld	a0,80(s4)
    80004bf6:	ffffd097          	auipc	ra,0xffffd
    80004bfa:	bdc080e7          	jalr	-1060(ra) # 800017d2 <copyout>
    80004bfe:	01650663          	beq	a0,s6,80004c0a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c02:	2985                	addiw	s3,s3,1
    80004c04:	0905                	addi	s2,s2,1
    80004c06:	fd3a91e3          	bne	s5,s3,80004bc8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c0a:	21c48513          	addi	a0,s1,540
    80004c0e:	ffffe097          	auipc	ra,0xffffe
    80004c12:	862080e7          	jalr	-1950(ra) # 80002470 <wakeup>
  release(&pi->lock);
    80004c16:	8526                	mv	a0,s1
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	0ac080e7          	jalr	172(ra) # 80000cc4 <release>
  return i;
}
    80004c20:	854e                	mv	a0,s3
    80004c22:	60a6                	ld	ra,72(sp)
    80004c24:	6406                	ld	s0,64(sp)
    80004c26:	74e2                	ld	s1,56(sp)
    80004c28:	7942                	ld	s2,48(sp)
    80004c2a:	79a2                	ld	s3,40(sp)
    80004c2c:	7a02                	ld	s4,32(sp)
    80004c2e:	6ae2                	ld	s5,24(sp)
    80004c30:	6b42                	ld	s6,16(sp)
    80004c32:	6161                	addi	sp,sp,80
    80004c34:	8082                	ret
      release(&pi->lock);
    80004c36:	8526                	mv	a0,s1
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	08c080e7          	jalr	140(ra) # 80000cc4 <release>
      return -1;
    80004c40:	59fd                	li	s3,-1
    80004c42:	bff9                	j	80004c20 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c44:	4981                	li	s3,0
    80004c46:	b7d1                	j	80004c0a <piperead+0xae>

0000000080004c48 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c48:	df010113          	addi	sp,sp,-528
    80004c4c:	20113423          	sd	ra,520(sp)
    80004c50:	20813023          	sd	s0,512(sp)
    80004c54:	ffa6                	sd	s1,504(sp)
    80004c56:	fbca                	sd	s2,496(sp)
    80004c58:	f7ce                	sd	s3,488(sp)
    80004c5a:	f3d2                	sd	s4,480(sp)
    80004c5c:	efd6                	sd	s5,472(sp)
    80004c5e:	ebda                	sd	s6,464(sp)
    80004c60:	e7de                	sd	s7,456(sp)
    80004c62:	e3e2                	sd	s8,448(sp)
    80004c64:	ff66                	sd	s9,440(sp)
    80004c66:	fb6a                	sd	s10,432(sp)
    80004c68:	f76e                	sd	s11,424(sp)
    80004c6a:	0c00                	addi	s0,sp,528
    80004c6c:	84aa                	mv	s1,a0
    80004c6e:	dea43c23          	sd	a0,-520(s0)
    80004c72:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	e68080e7          	jalr	-408(ra) # 80001ade <myproc>
    80004c7e:	892a                	mv	s2,a0

  begin_op();
    80004c80:	fffff097          	auipc	ra,0xfffff
    80004c84:	446080e7          	jalr	1094(ra) # 800040c6 <begin_op>

  if((ip = namei(path)) == 0){
    80004c88:	8526                	mv	a0,s1
    80004c8a:	fffff097          	auipc	ra,0xfffff
    80004c8e:	230080e7          	jalr	560(ra) # 80003eba <namei>
    80004c92:	c92d                	beqz	a0,80004d04 <exec+0xbc>
    80004c94:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	a74080e7          	jalr	-1420(ra) # 8000370a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c9e:	04000713          	li	a4,64
    80004ca2:	4681                	li	a3,0
    80004ca4:	e4840613          	addi	a2,s0,-440
    80004ca8:	4581                	li	a1,0
    80004caa:	8526                	mv	a0,s1
    80004cac:	fffff097          	auipc	ra,0xfffff
    80004cb0:	d12080e7          	jalr	-750(ra) # 800039be <readi>
    80004cb4:	04000793          	li	a5,64
    80004cb8:	00f51a63          	bne	a0,a5,80004ccc <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cbc:	e4842703          	lw	a4,-440(s0)
    80004cc0:	464c47b7          	lui	a5,0x464c4
    80004cc4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cc8:	04f70463          	beq	a4,a5,80004d10 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ccc:	8526                	mv	a0,s1
    80004cce:	fffff097          	auipc	ra,0xfffff
    80004cd2:	c9e080e7          	jalr	-866(ra) # 8000396c <iunlockput>
    end_op();
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	470080e7          	jalr	1136(ra) # 80004146 <end_op>
  }
  return -1;
    80004cde:	557d                	li	a0,-1
}
    80004ce0:	20813083          	ld	ra,520(sp)
    80004ce4:	20013403          	ld	s0,512(sp)
    80004ce8:	74fe                	ld	s1,504(sp)
    80004cea:	795e                	ld	s2,496(sp)
    80004cec:	79be                	ld	s3,488(sp)
    80004cee:	7a1e                	ld	s4,480(sp)
    80004cf0:	6afe                	ld	s5,472(sp)
    80004cf2:	6b5e                	ld	s6,464(sp)
    80004cf4:	6bbe                	ld	s7,456(sp)
    80004cf6:	6c1e                	ld	s8,448(sp)
    80004cf8:	7cfa                	ld	s9,440(sp)
    80004cfa:	7d5a                	ld	s10,432(sp)
    80004cfc:	7dba                	ld	s11,424(sp)
    80004cfe:	21010113          	addi	sp,sp,528
    80004d02:	8082                	ret
    end_op();
    80004d04:	fffff097          	auipc	ra,0xfffff
    80004d08:	442080e7          	jalr	1090(ra) # 80004146 <end_op>
    return -1;
    80004d0c:	557d                	li	a0,-1
    80004d0e:	bfc9                	j	80004ce0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d10:	854a                	mv	a0,s2
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	e90080e7          	jalr	-368(ra) # 80001ba2 <proc_pagetable>
    80004d1a:	8baa                	mv	s7,a0
    80004d1c:	d945                	beqz	a0,80004ccc <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d1e:	e6842983          	lw	s3,-408(s0)
    80004d22:	e8045783          	lhu	a5,-384(s0)
    80004d26:	c7ad                	beqz	a5,80004d90 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d28:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d2a:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d2c:	6c85                	lui	s9,0x1
    80004d2e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d32:	def43823          	sd	a5,-528(s0)
    80004d36:	a489                	j	80004f78 <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d38:	00004517          	auipc	a0,0x4
    80004d3c:	9b850513          	addi	a0,a0,-1608 # 800086f0 <syscalls+0x290>
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	808080e7          	jalr	-2040(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d48:	8756                	mv	a4,s5
    80004d4a:	012d86bb          	addw	a3,s11,s2
    80004d4e:	4581                	li	a1,0
    80004d50:	8526                	mv	a0,s1
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	c6c080e7          	jalr	-916(ra) # 800039be <readi>
    80004d5a:	2501                	sext.w	a0,a0
    80004d5c:	1caa9563          	bne	s5,a0,80004f26 <exec+0x2de>
  for(i = 0; i < sz; i += PGSIZE){
    80004d60:	6785                	lui	a5,0x1
    80004d62:	0127893b          	addw	s2,a5,s2
    80004d66:	77fd                	lui	a5,0xfffff
    80004d68:	01478a3b          	addw	s4,a5,s4
    80004d6c:	1f897d63          	bgeu	s2,s8,80004f66 <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    80004d70:	02091593          	slli	a1,s2,0x20
    80004d74:	9181                	srli	a1,a1,0x20
    80004d76:	95ea                	add	a1,a1,s10
    80004d78:	855e                	mv	a0,s7
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	32c080e7          	jalr	812(ra) # 800010a6 <walkaddr>
    80004d82:	862a                	mv	a2,a0
    if(pa == 0)
    80004d84:	d955                	beqz	a0,80004d38 <exec+0xf0>
      n = PGSIZE;
    80004d86:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004d88:	fd9a70e3          	bgeu	s4,s9,80004d48 <exec+0x100>
      n = sz - i;
    80004d8c:	8ad2                	mv	s5,s4
    80004d8e:	bf6d                	j	80004d48 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d90:	4901                	li	s2,0
  iunlockput(ip);
    80004d92:	8526                	mv	a0,s1
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	bd8080e7          	jalr	-1064(ra) # 8000396c <iunlockput>
  end_op();
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	3aa080e7          	jalr	938(ra) # 80004146 <end_op>
  p = myproc();
    80004da4:	ffffd097          	auipc	ra,0xffffd
    80004da8:	d3a080e7          	jalr	-710(ra) # 80001ade <myproc>
    80004dac:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004dae:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004db2:	6785                	lui	a5,0x1
    80004db4:	17fd                	addi	a5,a5,-1
    80004db6:	993e                	add	s2,s2,a5
    80004db8:	757d                	lui	a0,0xfffff
    80004dba:	00a977b3          	and	a5,s2,a0
    80004dbe:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dc2:	6609                	lui	a2,0x2
    80004dc4:	963e                	add	a2,a2,a5
    80004dc6:	85be                	mv	a1,a5
    80004dc8:	855e                	mv	a0,s7
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	6c0080e7          	jalr	1728(ra) # 8000148a <uvmalloc>
    80004dd2:	8b2a                	mv	s6,a0
  ip = 0;
    80004dd4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dd6:	14050863          	beqz	a0,80004f26 <exec+0x2de>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004dda:	75f9                	lui	a1,0xffffe
    80004ddc:	95aa                	add	a1,a1,a0
    80004dde:	855e                	mv	a0,s7
    80004de0:	ffffd097          	auipc	ra,0xffffd
    80004de4:	9c0080e7          	jalr	-1600(ra) # 800017a0 <uvmclear>
  stackbase = sp - PGSIZE;
    80004de8:	7c7d                	lui	s8,0xfffff
    80004dea:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004dec:	e0043783          	ld	a5,-512(s0)
    80004df0:	6388                	ld	a0,0(a5)
    80004df2:	c535                	beqz	a0,80004e5e <exec+0x216>
    80004df4:	e8840993          	addi	s3,s0,-376
    80004df8:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004dfc:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	096080e7          	jalr	150(ra) # 80000e94 <strlen>
    80004e06:	2505                	addiw	a0,a0,1
    80004e08:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e0c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e10:	13896f63          	bltu	s2,s8,80004f4e <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e14:	e0043d83          	ld	s11,-512(s0)
    80004e18:	000dba03          	ld	s4,0(s11)
    80004e1c:	8552                	mv	a0,s4
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	076080e7          	jalr	118(ra) # 80000e94 <strlen>
    80004e26:	0015069b          	addiw	a3,a0,1
    80004e2a:	8652                	mv	a2,s4
    80004e2c:	85ca                	mv	a1,s2
    80004e2e:	855e                	mv	a0,s7
    80004e30:	ffffd097          	auipc	ra,0xffffd
    80004e34:	9a2080e7          	jalr	-1630(ra) # 800017d2 <copyout>
    80004e38:	10054f63          	bltz	a0,80004f56 <exec+0x30e>
    ustack[argc] = sp;
    80004e3c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e40:	0485                	addi	s1,s1,1
    80004e42:	008d8793          	addi	a5,s11,8
    80004e46:	e0f43023          	sd	a5,-512(s0)
    80004e4a:	008db503          	ld	a0,8(s11)
    80004e4e:	c911                	beqz	a0,80004e62 <exec+0x21a>
    if(argc >= MAXARG)
    80004e50:	09a1                	addi	s3,s3,8
    80004e52:	fb3c96e3          	bne	s9,s3,80004dfe <exec+0x1b6>
  sz = sz1;
    80004e56:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e5a:	4481                	li	s1,0
    80004e5c:	a0e9                	j	80004f26 <exec+0x2de>
  sp = sz;
    80004e5e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e60:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e62:	00349793          	slli	a5,s1,0x3
    80004e66:	f9040713          	addi	a4,s0,-112
    80004e6a:	97ba                	add	a5,a5,a4
    80004e6c:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004e70:	00148693          	addi	a3,s1,1
    80004e74:	068e                	slli	a3,a3,0x3
    80004e76:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e7a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e7e:	01897663          	bgeu	s2,s8,80004e8a <exec+0x242>
  sz = sz1;
    80004e82:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e86:	4481                	li	s1,0
    80004e88:	a879                	j	80004f26 <exec+0x2de>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e8a:	e8840613          	addi	a2,s0,-376
    80004e8e:	85ca                	mv	a1,s2
    80004e90:	855e                	mv	a0,s7
    80004e92:	ffffd097          	auipc	ra,0xffffd
    80004e96:	940080e7          	jalr	-1728(ra) # 800017d2 <copyout>
    80004e9a:	0c054263          	bltz	a0,80004f5e <exec+0x316>
  p->trapframe->a1 = sp;
    80004e9e:	058ab783          	ld	a5,88(s5)
    80004ea2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ea6:	df843783          	ld	a5,-520(s0)
    80004eaa:	0007c703          	lbu	a4,0(a5)
    80004eae:	cf11                	beqz	a4,80004eca <exec+0x282>
    80004eb0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004eb2:	02f00693          	li	a3,47
    80004eb6:	a029                	j	80004ec0 <exec+0x278>
  for(last=s=path; *s; s++)
    80004eb8:	0785                	addi	a5,a5,1
    80004eba:	fff7c703          	lbu	a4,-1(a5)
    80004ebe:	c711                	beqz	a4,80004eca <exec+0x282>
    if(*s == '/')
    80004ec0:	fed71ce3          	bne	a4,a3,80004eb8 <exec+0x270>
      last = s+1;
    80004ec4:	def43c23          	sd	a5,-520(s0)
    80004ec8:	bfc5                	j	80004eb8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004eca:	4641                	li	a2,16
    80004ecc:	df843583          	ld	a1,-520(s0)
    80004ed0:	158a8513          	addi	a0,s5,344
    80004ed4:	ffffc097          	auipc	ra,0xffffc
    80004ed8:	f8e080e7          	jalr	-114(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80004edc:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004ee0:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004ee4:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004ee8:	058ab783          	ld	a5,88(s5)
    80004eec:	e6043703          	ld	a4,-416(s0)
    80004ef0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ef2:	058ab783          	ld	a5,88(s5)
    80004ef6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004efa:	85ea                	mv	a1,s10
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	d42080e7          	jalr	-702(ra) # 80001c3e <proc_freepagetable>
  if(p->pid==1) vmprint(p->pagetable);
    80004f04:	038aa703          	lw	a4,56(s5)
    80004f08:	4785                	li	a5,1
    80004f0a:	00f70563          	beq	a4,a5,80004f14 <exec+0x2cc>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f0e:	0004851b          	sext.w	a0,s1
    80004f12:	b3f9                	j	80004ce0 <exec+0x98>
  if(p->pid==1) vmprint(p->pagetable);
    80004f14:	050ab503          	ld	a0,80(s5)
    80004f18:	ffffc097          	auipc	ra,0xffffc
    80004f1c:	74a080e7          	jalr	1866(ra) # 80001662 <vmprint>
    80004f20:	b7fd                	j	80004f0e <exec+0x2c6>
    80004f22:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f26:	e0843583          	ld	a1,-504(s0)
    80004f2a:	855e                	mv	a0,s7
    80004f2c:	ffffd097          	auipc	ra,0xffffd
    80004f30:	d12080e7          	jalr	-750(ra) # 80001c3e <proc_freepagetable>
  if(ip){
    80004f34:	d8049ce3          	bnez	s1,80004ccc <exec+0x84>
  return -1;
    80004f38:	557d                	li	a0,-1
    80004f3a:	b35d                	j	80004ce0 <exec+0x98>
    80004f3c:	e1243423          	sd	s2,-504(s0)
    80004f40:	b7dd                	j	80004f26 <exec+0x2de>
    80004f42:	e1243423          	sd	s2,-504(s0)
    80004f46:	b7c5                	j	80004f26 <exec+0x2de>
    80004f48:	e1243423          	sd	s2,-504(s0)
    80004f4c:	bfe9                	j	80004f26 <exec+0x2de>
  sz = sz1;
    80004f4e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f52:	4481                	li	s1,0
    80004f54:	bfc9                	j	80004f26 <exec+0x2de>
  sz = sz1;
    80004f56:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f5a:	4481                	li	s1,0
    80004f5c:	b7e9                	j	80004f26 <exec+0x2de>
  sz = sz1;
    80004f5e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f62:	4481                	li	s1,0
    80004f64:	b7c9                	j	80004f26 <exec+0x2de>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f66:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f6a:	2b05                	addiw	s6,s6,1
    80004f6c:	0389899b          	addiw	s3,s3,56
    80004f70:	e8045783          	lhu	a5,-384(s0)
    80004f74:	e0fb5fe3          	bge	s6,a5,80004d92 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f78:	2981                	sext.w	s3,s3
    80004f7a:	03800713          	li	a4,56
    80004f7e:	86ce                	mv	a3,s3
    80004f80:	e1040613          	addi	a2,s0,-496
    80004f84:	4581                	li	a1,0
    80004f86:	8526                	mv	a0,s1
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	a36080e7          	jalr	-1482(ra) # 800039be <readi>
    80004f90:	03800793          	li	a5,56
    80004f94:	f8f517e3          	bne	a0,a5,80004f22 <exec+0x2da>
    if(ph.type != ELF_PROG_LOAD)
    80004f98:	e1042783          	lw	a5,-496(s0)
    80004f9c:	4705                	li	a4,1
    80004f9e:	fce796e3          	bne	a5,a4,80004f6a <exec+0x322>
    if(ph.memsz < ph.filesz)
    80004fa2:	e3843603          	ld	a2,-456(s0)
    80004fa6:	e3043783          	ld	a5,-464(s0)
    80004faa:	f8f669e3          	bltu	a2,a5,80004f3c <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fae:	e2043783          	ld	a5,-480(s0)
    80004fb2:	963e                	add	a2,a2,a5
    80004fb4:	f8f667e3          	bltu	a2,a5,80004f42 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fb8:	85ca                	mv	a1,s2
    80004fba:	855e                	mv	a0,s7
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	4ce080e7          	jalr	1230(ra) # 8000148a <uvmalloc>
    80004fc4:	e0a43423          	sd	a0,-504(s0)
    80004fc8:	d141                	beqz	a0,80004f48 <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    80004fca:	e2043d03          	ld	s10,-480(s0)
    80004fce:	df043783          	ld	a5,-528(s0)
    80004fd2:	00fd77b3          	and	a5,s10,a5
    80004fd6:	fba1                	bnez	a5,80004f26 <exec+0x2de>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fd8:	e1842d83          	lw	s11,-488(s0)
    80004fdc:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fe0:	f80c03e3          	beqz	s8,80004f66 <exec+0x31e>
    80004fe4:	8a62                	mv	s4,s8
    80004fe6:	4901                	li	s2,0
    80004fe8:	b361                	j	80004d70 <exec+0x128>

0000000080004fea <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fea:	7179                	addi	sp,sp,-48
    80004fec:	f406                	sd	ra,40(sp)
    80004fee:	f022                	sd	s0,32(sp)
    80004ff0:	ec26                	sd	s1,24(sp)
    80004ff2:	e84a                	sd	s2,16(sp)
    80004ff4:	1800                	addi	s0,sp,48
    80004ff6:	892e                	mv	s2,a1
    80004ff8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004ffa:	fdc40593          	addi	a1,s0,-36
    80004ffe:	ffffe097          	auipc	ra,0xffffe
    80005002:	b9a080e7          	jalr	-1126(ra) # 80002b98 <argint>
    80005006:	04054063          	bltz	a0,80005046 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000500a:	fdc42703          	lw	a4,-36(s0)
    8000500e:	47bd                	li	a5,15
    80005010:	02e7ed63          	bltu	a5,a4,8000504a <argfd+0x60>
    80005014:	ffffd097          	auipc	ra,0xffffd
    80005018:	aca080e7          	jalr	-1334(ra) # 80001ade <myproc>
    8000501c:	fdc42703          	lw	a4,-36(s0)
    80005020:	01a70793          	addi	a5,a4,26
    80005024:	078e                	slli	a5,a5,0x3
    80005026:	953e                	add	a0,a0,a5
    80005028:	611c                	ld	a5,0(a0)
    8000502a:	c395                	beqz	a5,8000504e <argfd+0x64>
    return -1;
  if(pfd)
    8000502c:	00090463          	beqz	s2,80005034 <argfd+0x4a>
    *pfd = fd;
    80005030:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005034:	4501                	li	a0,0
  if(pf)
    80005036:	c091                	beqz	s1,8000503a <argfd+0x50>
    *pf = f;
    80005038:	e09c                	sd	a5,0(s1)
}
    8000503a:	70a2                	ld	ra,40(sp)
    8000503c:	7402                	ld	s0,32(sp)
    8000503e:	64e2                	ld	s1,24(sp)
    80005040:	6942                	ld	s2,16(sp)
    80005042:	6145                	addi	sp,sp,48
    80005044:	8082                	ret
    return -1;
    80005046:	557d                	li	a0,-1
    80005048:	bfcd                	j	8000503a <argfd+0x50>
    return -1;
    8000504a:	557d                	li	a0,-1
    8000504c:	b7fd                	j	8000503a <argfd+0x50>
    8000504e:	557d                	li	a0,-1
    80005050:	b7ed                	j	8000503a <argfd+0x50>

0000000080005052 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005052:	1101                	addi	sp,sp,-32
    80005054:	ec06                	sd	ra,24(sp)
    80005056:	e822                	sd	s0,16(sp)
    80005058:	e426                	sd	s1,8(sp)
    8000505a:	1000                	addi	s0,sp,32
    8000505c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000505e:	ffffd097          	auipc	ra,0xffffd
    80005062:	a80080e7          	jalr	-1408(ra) # 80001ade <myproc>
    80005066:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005068:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80b0>
    8000506c:	4501                	li	a0,0
    8000506e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005070:	6398                	ld	a4,0(a5)
    80005072:	cb19                	beqz	a4,80005088 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005074:	2505                	addiw	a0,a0,1
    80005076:	07a1                	addi	a5,a5,8
    80005078:	fed51ce3          	bne	a0,a3,80005070 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000507c:	557d                	li	a0,-1
}
    8000507e:	60e2                	ld	ra,24(sp)
    80005080:	6442                	ld	s0,16(sp)
    80005082:	64a2                	ld	s1,8(sp)
    80005084:	6105                	addi	sp,sp,32
    80005086:	8082                	ret
      p->ofile[fd] = f;
    80005088:	01a50793          	addi	a5,a0,26
    8000508c:	078e                	slli	a5,a5,0x3
    8000508e:	963e                	add	a2,a2,a5
    80005090:	e204                	sd	s1,0(a2)
      return fd;
    80005092:	b7f5                	j	8000507e <fdalloc+0x2c>

0000000080005094 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005094:	715d                	addi	sp,sp,-80
    80005096:	e486                	sd	ra,72(sp)
    80005098:	e0a2                	sd	s0,64(sp)
    8000509a:	fc26                	sd	s1,56(sp)
    8000509c:	f84a                	sd	s2,48(sp)
    8000509e:	f44e                	sd	s3,40(sp)
    800050a0:	f052                	sd	s4,32(sp)
    800050a2:	ec56                	sd	s5,24(sp)
    800050a4:	0880                	addi	s0,sp,80
    800050a6:	89ae                	mv	s3,a1
    800050a8:	8ab2                	mv	s5,a2
    800050aa:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050ac:	fb040593          	addi	a1,s0,-80
    800050b0:	fffff097          	auipc	ra,0xfffff
    800050b4:	e28080e7          	jalr	-472(ra) # 80003ed8 <nameiparent>
    800050b8:	892a                	mv	s2,a0
    800050ba:	12050f63          	beqz	a0,800051f8 <create+0x164>
    return 0;

  ilock(dp);
    800050be:	ffffe097          	auipc	ra,0xffffe
    800050c2:	64c080e7          	jalr	1612(ra) # 8000370a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050c6:	4601                	li	a2,0
    800050c8:	fb040593          	addi	a1,s0,-80
    800050cc:	854a                	mv	a0,s2
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	b1a080e7          	jalr	-1254(ra) # 80003be8 <dirlookup>
    800050d6:	84aa                	mv	s1,a0
    800050d8:	c921                	beqz	a0,80005128 <create+0x94>
    iunlockput(dp);
    800050da:	854a                	mv	a0,s2
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	890080e7          	jalr	-1904(ra) # 8000396c <iunlockput>
    ilock(ip);
    800050e4:	8526                	mv	a0,s1
    800050e6:	ffffe097          	auipc	ra,0xffffe
    800050ea:	624080e7          	jalr	1572(ra) # 8000370a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050ee:	2981                	sext.w	s3,s3
    800050f0:	4789                	li	a5,2
    800050f2:	02f99463          	bne	s3,a5,8000511a <create+0x86>
    800050f6:	0444d783          	lhu	a5,68(s1)
    800050fa:	37f9                	addiw	a5,a5,-2
    800050fc:	17c2                	slli	a5,a5,0x30
    800050fe:	93c1                	srli	a5,a5,0x30
    80005100:	4705                	li	a4,1
    80005102:	00f76c63          	bltu	a4,a5,8000511a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005106:	8526                	mv	a0,s1
    80005108:	60a6                	ld	ra,72(sp)
    8000510a:	6406                	ld	s0,64(sp)
    8000510c:	74e2                	ld	s1,56(sp)
    8000510e:	7942                	ld	s2,48(sp)
    80005110:	79a2                	ld	s3,40(sp)
    80005112:	7a02                	ld	s4,32(sp)
    80005114:	6ae2                	ld	s5,24(sp)
    80005116:	6161                	addi	sp,sp,80
    80005118:	8082                	ret
    iunlockput(ip);
    8000511a:	8526                	mv	a0,s1
    8000511c:	fffff097          	auipc	ra,0xfffff
    80005120:	850080e7          	jalr	-1968(ra) # 8000396c <iunlockput>
    return 0;
    80005124:	4481                	li	s1,0
    80005126:	b7c5                	j	80005106 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005128:	85ce                	mv	a1,s3
    8000512a:	00092503          	lw	a0,0(s2)
    8000512e:	ffffe097          	auipc	ra,0xffffe
    80005132:	444080e7          	jalr	1092(ra) # 80003572 <ialloc>
    80005136:	84aa                	mv	s1,a0
    80005138:	c529                	beqz	a0,80005182 <create+0xee>
  ilock(ip);
    8000513a:	ffffe097          	auipc	ra,0xffffe
    8000513e:	5d0080e7          	jalr	1488(ra) # 8000370a <ilock>
  ip->major = major;
    80005142:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005146:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000514a:	4785                	li	a5,1
    8000514c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005150:	8526                	mv	a0,s1
    80005152:	ffffe097          	auipc	ra,0xffffe
    80005156:	4ee080e7          	jalr	1262(ra) # 80003640 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000515a:	2981                	sext.w	s3,s3
    8000515c:	4785                	li	a5,1
    8000515e:	02f98a63          	beq	s3,a5,80005192 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005162:	40d0                	lw	a2,4(s1)
    80005164:	fb040593          	addi	a1,s0,-80
    80005168:	854a                	mv	a0,s2
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	c8e080e7          	jalr	-882(ra) # 80003df8 <dirlink>
    80005172:	06054b63          	bltz	a0,800051e8 <create+0x154>
  iunlockput(dp);
    80005176:	854a                	mv	a0,s2
    80005178:	ffffe097          	auipc	ra,0xffffe
    8000517c:	7f4080e7          	jalr	2036(ra) # 8000396c <iunlockput>
  return ip;
    80005180:	b759                	j	80005106 <create+0x72>
    panic("create: ialloc");
    80005182:	00003517          	auipc	a0,0x3
    80005186:	58e50513          	addi	a0,a0,1422 # 80008710 <syscalls+0x2b0>
    8000518a:	ffffb097          	auipc	ra,0xffffb
    8000518e:	3be080e7          	jalr	958(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005192:	04a95783          	lhu	a5,74(s2)
    80005196:	2785                	addiw	a5,a5,1
    80005198:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000519c:	854a                	mv	a0,s2
    8000519e:	ffffe097          	auipc	ra,0xffffe
    800051a2:	4a2080e7          	jalr	1186(ra) # 80003640 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051a6:	40d0                	lw	a2,4(s1)
    800051a8:	00003597          	auipc	a1,0x3
    800051ac:	57858593          	addi	a1,a1,1400 # 80008720 <syscalls+0x2c0>
    800051b0:	8526                	mv	a0,s1
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	c46080e7          	jalr	-954(ra) # 80003df8 <dirlink>
    800051ba:	00054f63          	bltz	a0,800051d8 <create+0x144>
    800051be:	00492603          	lw	a2,4(s2)
    800051c2:	00003597          	auipc	a1,0x3
    800051c6:	fb658593          	addi	a1,a1,-74 # 80008178 <digits+0x138>
    800051ca:	8526                	mv	a0,s1
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	c2c080e7          	jalr	-980(ra) # 80003df8 <dirlink>
    800051d4:	f80557e3          	bgez	a0,80005162 <create+0xce>
      panic("create dots");
    800051d8:	00003517          	auipc	a0,0x3
    800051dc:	55050513          	addi	a0,a0,1360 # 80008728 <syscalls+0x2c8>
    800051e0:	ffffb097          	auipc	ra,0xffffb
    800051e4:	368080e7          	jalr	872(ra) # 80000548 <panic>
    panic("create: dirlink");
    800051e8:	00003517          	auipc	a0,0x3
    800051ec:	55050513          	addi	a0,a0,1360 # 80008738 <syscalls+0x2d8>
    800051f0:	ffffb097          	auipc	ra,0xffffb
    800051f4:	358080e7          	jalr	856(ra) # 80000548 <panic>
    return 0;
    800051f8:	84aa                	mv	s1,a0
    800051fa:	b731                	j	80005106 <create+0x72>

00000000800051fc <sys_dup>:
{
    800051fc:	7179                	addi	sp,sp,-48
    800051fe:	f406                	sd	ra,40(sp)
    80005200:	f022                	sd	s0,32(sp)
    80005202:	ec26                	sd	s1,24(sp)
    80005204:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005206:	fd840613          	addi	a2,s0,-40
    8000520a:	4581                	li	a1,0
    8000520c:	4501                	li	a0,0
    8000520e:	00000097          	auipc	ra,0x0
    80005212:	ddc080e7          	jalr	-548(ra) # 80004fea <argfd>
    return -1;
    80005216:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005218:	02054363          	bltz	a0,8000523e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000521c:	fd843503          	ld	a0,-40(s0)
    80005220:	00000097          	auipc	ra,0x0
    80005224:	e32080e7          	jalr	-462(ra) # 80005052 <fdalloc>
    80005228:	84aa                	mv	s1,a0
    return -1;
    8000522a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000522c:	00054963          	bltz	a0,8000523e <sys_dup+0x42>
  filedup(f);
    80005230:	fd843503          	ld	a0,-40(s0)
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	312080e7          	jalr	786(ra) # 80004546 <filedup>
  return fd;
    8000523c:	87a6                	mv	a5,s1
}
    8000523e:	853e                	mv	a0,a5
    80005240:	70a2                	ld	ra,40(sp)
    80005242:	7402                	ld	s0,32(sp)
    80005244:	64e2                	ld	s1,24(sp)
    80005246:	6145                	addi	sp,sp,48
    80005248:	8082                	ret

000000008000524a <sys_read>:
{
    8000524a:	7179                	addi	sp,sp,-48
    8000524c:	f406                	sd	ra,40(sp)
    8000524e:	f022                	sd	s0,32(sp)
    80005250:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005252:	fe840613          	addi	a2,s0,-24
    80005256:	4581                	li	a1,0
    80005258:	4501                	li	a0,0
    8000525a:	00000097          	auipc	ra,0x0
    8000525e:	d90080e7          	jalr	-624(ra) # 80004fea <argfd>
    return -1;
    80005262:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005264:	04054163          	bltz	a0,800052a6 <sys_read+0x5c>
    80005268:	fe440593          	addi	a1,s0,-28
    8000526c:	4509                	li	a0,2
    8000526e:	ffffe097          	auipc	ra,0xffffe
    80005272:	92a080e7          	jalr	-1750(ra) # 80002b98 <argint>
    return -1;
    80005276:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005278:	02054763          	bltz	a0,800052a6 <sys_read+0x5c>
    8000527c:	fd840593          	addi	a1,s0,-40
    80005280:	4505                	li	a0,1
    80005282:	ffffe097          	auipc	ra,0xffffe
    80005286:	938080e7          	jalr	-1736(ra) # 80002bba <argaddr>
    return -1;
    8000528a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000528c:	00054d63          	bltz	a0,800052a6 <sys_read+0x5c>
  return fileread(f, p, n);
    80005290:	fe442603          	lw	a2,-28(s0)
    80005294:	fd843583          	ld	a1,-40(s0)
    80005298:	fe843503          	ld	a0,-24(s0)
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	436080e7          	jalr	1078(ra) # 800046d2 <fileread>
    800052a4:	87aa                	mv	a5,a0
}
    800052a6:	853e                	mv	a0,a5
    800052a8:	70a2                	ld	ra,40(sp)
    800052aa:	7402                	ld	s0,32(sp)
    800052ac:	6145                	addi	sp,sp,48
    800052ae:	8082                	ret

00000000800052b0 <sys_write>:
{
    800052b0:	7179                	addi	sp,sp,-48
    800052b2:	f406                	sd	ra,40(sp)
    800052b4:	f022                	sd	s0,32(sp)
    800052b6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b8:	fe840613          	addi	a2,s0,-24
    800052bc:	4581                	li	a1,0
    800052be:	4501                	li	a0,0
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	d2a080e7          	jalr	-726(ra) # 80004fea <argfd>
    return -1;
    800052c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ca:	04054163          	bltz	a0,8000530c <sys_write+0x5c>
    800052ce:	fe440593          	addi	a1,s0,-28
    800052d2:	4509                	li	a0,2
    800052d4:	ffffe097          	auipc	ra,0xffffe
    800052d8:	8c4080e7          	jalr	-1852(ra) # 80002b98 <argint>
    return -1;
    800052dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052de:	02054763          	bltz	a0,8000530c <sys_write+0x5c>
    800052e2:	fd840593          	addi	a1,s0,-40
    800052e6:	4505                	li	a0,1
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	8d2080e7          	jalr	-1838(ra) # 80002bba <argaddr>
    return -1;
    800052f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f2:	00054d63          	bltz	a0,8000530c <sys_write+0x5c>
  return filewrite(f, p, n);
    800052f6:	fe442603          	lw	a2,-28(s0)
    800052fa:	fd843583          	ld	a1,-40(s0)
    800052fe:	fe843503          	ld	a0,-24(s0)
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	492080e7          	jalr	1170(ra) # 80004794 <filewrite>
    8000530a:	87aa                	mv	a5,a0
}
    8000530c:	853e                	mv	a0,a5
    8000530e:	70a2                	ld	ra,40(sp)
    80005310:	7402                	ld	s0,32(sp)
    80005312:	6145                	addi	sp,sp,48
    80005314:	8082                	ret

0000000080005316 <sys_close>:
{
    80005316:	1101                	addi	sp,sp,-32
    80005318:	ec06                	sd	ra,24(sp)
    8000531a:	e822                	sd	s0,16(sp)
    8000531c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000531e:	fe040613          	addi	a2,s0,-32
    80005322:	fec40593          	addi	a1,s0,-20
    80005326:	4501                	li	a0,0
    80005328:	00000097          	auipc	ra,0x0
    8000532c:	cc2080e7          	jalr	-830(ra) # 80004fea <argfd>
    return -1;
    80005330:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005332:	02054463          	bltz	a0,8000535a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005336:	ffffc097          	auipc	ra,0xffffc
    8000533a:	7a8080e7          	jalr	1960(ra) # 80001ade <myproc>
    8000533e:	fec42783          	lw	a5,-20(s0)
    80005342:	07e9                	addi	a5,a5,26
    80005344:	078e                	slli	a5,a5,0x3
    80005346:	97aa                	add	a5,a5,a0
    80005348:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000534c:	fe043503          	ld	a0,-32(s0)
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	248080e7          	jalr	584(ra) # 80004598 <fileclose>
  return 0;
    80005358:	4781                	li	a5,0
}
    8000535a:	853e                	mv	a0,a5
    8000535c:	60e2                	ld	ra,24(sp)
    8000535e:	6442                	ld	s0,16(sp)
    80005360:	6105                	addi	sp,sp,32
    80005362:	8082                	ret

0000000080005364 <sys_fstat>:
{
    80005364:	1101                	addi	sp,sp,-32
    80005366:	ec06                	sd	ra,24(sp)
    80005368:	e822                	sd	s0,16(sp)
    8000536a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000536c:	fe840613          	addi	a2,s0,-24
    80005370:	4581                	li	a1,0
    80005372:	4501                	li	a0,0
    80005374:	00000097          	auipc	ra,0x0
    80005378:	c76080e7          	jalr	-906(ra) # 80004fea <argfd>
    return -1;
    8000537c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000537e:	02054563          	bltz	a0,800053a8 <sys_fstat+0x44>
    80005382:	fe040593          	addi	a1,s0,-32
    80005386:	4505                	li	a0,1
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	832080e7          	jalr	-1998(ra) # 80002bba <argaddr>
    return -1;
    80005390:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005392:	00054b63          	bltz	a0,800053a8 <sys_fstat+0x44>
  return filestat(f, st);
    80005396:	fe043583          	ld	a1,-32(s0)
    8000539a:	fe843503          	ld	a0,-24(s0)
    8000539e:	fffff097          	auipc	ra,0xfffff
    800053a2:	2c2080e7          	jalr	706(ra) # 80004660 <filestat>
    800053a6:	87aa                	mv	a5,a0
}
    800053a8:	853e                	mv	a0,a5
    800053aa:	60e2                	ld	ra,24(sp)
    800053ac:	6442                	ld	s0,16(sp)
    800053ae:	6105                	addi	sp,sp,32
    800053b0:	8082                	ret

00000000800053b2 <sys_link>:
{
    800053b2:	7169                	addi	sp,sp,-304
    800053b4:	f606                	sd	ra,296(sp)
    800053b6:	f222                	sd	s0,288(sp)
    800053b8:	ee26                	sd	s1,280(sp)
    800053ba:	ea4a                	sd	s2,272(sp)
    800053bc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053be:	08000613          	li	a2,128
    800053c2:	ed040593          	addi	a1,s0,-304
    800053c6:	4501                	li	a0,0
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	814080e7          	jalr	-2028(ra) # 80002bdc <argstr>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053d2:	10054e63          	bltz	a0,800054ee <sys_link+0x13c>
    800053d6:	08000613          	li	a2,128
    800053da:	f5040593          	addi	a1,s0,-176
    800053de:	4505                	li	a0,1
    800053e0:	ffffd097          	auipc	ra,0xffffd
    800053e4:	7fc080e7          	jalr	2044(ra) # 80002bdc <argstr>
    return -1;
    800053e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ea:	10054263          	bltz	a0,800054ee <sys_link+0x13c>
  begin_op();
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	cd8080e7          	jalr	-808(ra) # 800040c6 <begin_op>
  if((ip = namei(old)) == 0){
    800053f6:	ed040513          	addi	a0,s0,-304
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	ac0080e7          	jalr	-1344(ra) # 80003eba <namei>
    80005402:	84aa                	mv	s1,a0
    80005404:	c551                	beqz	a0,80005490 <sys_link+0xde>
  ilock(ip);
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	304080e7          	jalr	772(ra) # 8000370a <ilock>
  if(ip->type == T_DIR){
    8000540e:	04449703          	lh	a4,68(s1)
    80005412:	4785                	li	a5,1
    80005414:	08f70463          	beq	a4,a5,8000549c <sys_link+0xea>
  ip->nlink++;
    80005418:	04a4d783          	lhu	a5,74(s1)
    8000541c:	2785                	addiw	a5,a5,1
    8000541e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005422:	8526                	mv	a0,s1
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	21c080e7          	jalr	540(ra) # 80003640 <iupdate>
  iunlock(ip);
    8000542c:	8526                	mv	a0,s1
    8000542e:	ffffe097          	auipc	ra,0xffffe
    80005432:	39e080e7          	jalr	926(ra) # 800037cc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005436:	fd040593          	addi	a1,s0,-48
    8000543a:	f5040513          	addi	a0,s0,-176
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	a9a080e7          	jalr	-1382(ra) # 80003ed8 <nameiparent>
    80005446:	892a                	mv	s2,a0
    80005448:	c935                	beqz	a0,800054bc <sys_link+0x10a>
  ilock(dp);
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	2c0080e7          	jalr	704(ra) # 8000370a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005452:	00092703          	lw	a4,0(s2)
    80005456:	409c                	lw	a5,0(s1)
    80005458:	04f71d63          	bne	a4,a5,800054b2 <sys_link+0x100>
    8000545c:	40d0                	lw	a2,4(s1)
    8000545e:	fd040593          	addi	a1,s0,-48
    80005462:	854a                	mv	a0,s2
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	994080e7          	jalr	-1644(ra) # 80003df8 <dirlink>
    8000546c:	04054363          	bltz	a0,800054b2 <sys_link+0x100>
  iunlockput(dp);
    80005470:	854a                	mv	a0,s2
    80005472:	ffffe097          	auipc	ra,0xffffe
    80005476:	4fa080e7          	jalr	1274(ra) # 8000396c <iunlockput>
  iput(ip);
    8000547a:	8526                	mv	a0,s1
    8000547c:	ffffe097          	auipc	ra,0xffffe
    80005480:	448080e7          	jalr	1096(ra) # 800038c4 <iput>
  end_op();
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	cc2080e7          	jalr	-830(ra) # 80004146 <end_op>
  return 0;
    8000548c:	4781                	li	a5,0
    8000548e:	a085                	j	800054ee <sys_link+0x13c>
    end_op();
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	cb6080e7          	jalr	-842(ra) # 80004146 <end_op>
    return -1;
    80005498:	57fd                	li	a5,-1
    8000549a:	a891                	j	800054ee <sys_link+0x13c>
    iunlockput(ip);
    8000549c:	8526                	mv	a0,s1
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	4ce080e7          	jalr	1230(ra) # 8000396c <iunlockput>
    end_op();
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	ca0080e7          	jalr	-864(ra) # 80004146 <end_op>
    return -1;
    800054ae:	57fd                	li	a5,-1
    800054b0:	a83d                	j	800054ee <sys_link+0x13c>
    iunlockput(dp);
    800054b2:	854a                	mv	a0,s2
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	4b8080e7          	jalr	1208(ra) # 8000396c <iunlockput>
  ilock(ip);
    800054bc:	8526                	mv	a0,s1
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	24c080e7          	jalr	588(ra) # 8000370a <ilock>
  ip->nlink--;
    800054c6:	04a4d783          	lhu	a5,74(s1)
    800054ca:	37fd                	addiw	a5,a5,-1
    800054cc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054d0:	8526                	mv	a0,s1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	16e080e7          	jalr	366(ra) # 80003640 <iupdate>
  iunlockput(ip);
    800054da:	8526                	mv	a0,s1
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	490080e7          	jalr	1168(ra) # 8000396c <iunlockput>
  end_op();
    800054e4:	fffff097          	auipc	ra,0xfffff
    800054e8:	c62080e7          	jalr	-926(ra) # 80004146 <end_op>
  return -1;
    800054ec:	57fd                	li	a5,-1
}
    800054ee:	853e                	mv	a0,a5
    800054f0:	70b2                	ld	ra,296(sp)
    800054f2:	7412                	ld	s0,288(sp)
    800054f4:	64f2                	ld	s1,280(sp)
    800054f6:	6952                	ld	s2,272(sp)
    800054f8:	6155                	addi	sp,sp,304
    800054fa:	8082                	ret

00000000800054fc <sys_unlink>:
{
    800054fc:	7151                	addi	sp,sp,-240
    800054fe:	f586                	sd	ra,232(sp)
    80005500:	f1a2                	sd	s0,224(sp)
    80005502:	eda6                	sd	s1,216(sp)
    80005504:	e9ca                	sd	s2,208(sp)
    80005506:	e5ce                	sd	s3,200(sp)
    80005508:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000550a:	08000613          	li	a2,128
    8000550e:	f3040593          	addi	a1,s0,-208
    80005512:	4501                	li	a0,0
    80005514:	ffffd097          	auipc	ra,0xffffd
    80005518:	6c8080e7          	jalr	1736(ra) # 80002bdc <argstr>
    8000551c:	18054163          	bltz	a0,8000569e <sys_unlink+0x1a2>
  begin_op();
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	ba6080e7          	jalr	-1114(ra) # 800040c6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005528:	fb040593          	addi	a1,s0,-80
    8000552c:	f3040513          	addi	a0,s0,-208
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	9a8080e7          	jalr	-1624(ra) # 80003ed8 <nameiparent>
    80005538:	84aa                	mv	s1,a0
    8000553a:	c979                	beqz	a0,80005610 <sys_unlink+0x114>
  ilock(dp);
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	1ce080e7          	jalr	462(ra) # 8000370a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005544:	00003597          	auipc	a1,0x3
    80005548:	1dc58593          	addi	a1,a1,476 # 80008720 <syscalls+0x2c0>
    8000554c:	fb040513          	addi	a0,s0,-80
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	67e080e7          	jalr	1662(ra) # 80003bce <namecmp>
    80005558:	14050a63          	beqz	a0,800056ac <sys_unlink+0x1b0>
    8000555c:	00003597          	auipc	a1,0x3
    80005560:	c1c58593          	addi	a1,a1,-996 # 80008178 <digits+0x138>
    80005564:	fb040513          	addi	a0,s0,-80
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	666080e7          	jalr	1638(ra) # 80003bce <namecmp>
    80005570:	12050e63          	beqz	a0,800056ac <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005574:	f2c40613          	addi	a2,s0,-212
    80005578:	fb040593          	addi	a1,s0,-80
    8000557c:	8526                	mv	a0,s1
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	66a080e7          	jalr	1642(ra) # 80003be8 <dirlookup>
    80005586:	892a                	mv	s2,a0
    80005588:	12050263          	beqz	a0,800056ac <sys_unlink+0x1b0>
  ilock(ip);
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	17e080e7          	jalr	382(ra) # 8000370a <ilock>
  if(ip->nlink < 1)
    80005594:	04a91783          	lh	a5,74(s2)
    80005598:	08f05263          	blez	a5,8000561c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000559c:	04491703          	lh	a4,68(s2)
    800055a0:	4785                	li	a5,1
    800055a2:	08f70563          	beq	a4,a5,8000562c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055a6:	4641                	li	a2,16
    800055a8:	4581                	li	a1,0
    800055aa:	fc040513          	addi	a0,s0,-64
    800055ae:	ffffb097          	auipc	ra,0xffffb
    800055b2:	75e080e7          	jalr	1886(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055b6:	4741                	li	a4,16
    800055b8:	f2c42683          	lw	a3,-212(s0)
    800055bc:	fc040613          	addi	a2,s0,-64
    800055c0:	4581                	li	a1,0
    800055c2:	8526                	mv	a0,s1
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	4f0080e7          	jalr	1264(ra) # 80003ab4 <writei>
    800055cc:	47c1                	li	a5,16
    800055ce:	0af51563          	bne	a0,a5,80005678 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055d2:	04491703          	lh	a4,68(s2)
    800055d6:	4785                	li	a5,1
    800055d8:	0af70863          	beq	a4,a5,80005688 <sys_unlink+0x18c>
  iunlockput(dp);
    800055dc:	8526                	mv	a0,s1
    800055de:	ffffe097          	auipc	ra,0xffffe
    800055e2:	38e080e7          	jalr	910(ra) # 8000396c <iunlockput>
  ip->nlink--;
    800055e6:	04a95783          	lhu	a5,74(s2)
    800055ea:	37fd                	addiw	a5,a5,-1
    800055ec:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055f0:	854a                	mv	a0,s2
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	04e080e7          	jalr	78(ra) # 80003640 <iupdate>
  iunlockput(ip);
    800055fa:	854a                	mv	a0,s2
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	370080e7          	jalr	880(ra) # 8000396c <iunlockput>
  end_op();
    80005604:	fffff097          	auipc	ra,0xfffff
    80005608:	b42080e7          	jalr	-1214(ra) # 80004146 <end_op>
  return 0;
    8000560c:	4501                	li	a0,0
    8000560e:	a84d                	j	800056c0 <sys_unlink+0x1c4>
    end_op();
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	b36080e7          	jalr	-1226(ra) # 80004146 <end_op>
    return -1;
    80005618:	557d                	li	a0,-1
    8000561a:	a05d                	j	800056c0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000561c:	00003517          	auipc	a0,0x3
    80005620:	12c50513          	addi	a0,a0,300 # 80008748 <syscalls+0x2e8>
    80005624:	ffffb097          	auipc	ra,0xffffb
    80005628:	f24080e7          	jalr	-220(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000562c:	04c92703          	lw	a4,76(s2)
    80005630:	02000793          	li	a5,32
    80005634:	f6e7f9e3          	bgeu	a5,a4,800055a6 <sys_unlink+0xaa>
    80005638:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000563c:	4741                	li	a4,16
    8000563e:	86ce                	mv	a3,s3
    80005640:	f1840613          	addi	a2,s0,-232
    80005644:	4581                	li	a1,0
    80005646:	854a                	mv	a0,s2
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	376080e7          	jalr	886(ra) # 800039be <readi>
    80005650:	47c1                	li	a5,16
    80005652:	00f51b63          	bne	a0,a5,80005668 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005656:	f1845783          	lhu	a5,-232(s0)
    8000565a:	e7a1                	bnez	a5,800056a2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000565c:	29c1                	addiw	s3,s3,16
    8000565e:	04c92783          	lw	a5,76(s2)
    80005662:	fcf9ede3          	bltu	s3,a5,8000563c <sys_unlink+0x140>
    80005666:	b781                	j	800055a6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005668:	00003517          	auipc	a0,0x3
    8000566c:	0f850513          	addi	a0,a0,248 # 80008760 <syscalls+0x300>
    80005670:	ffffb097          	auipc	ra,0xffffb
    80005674:	ed8080e7          	jalr	-296(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005678:	00003517          	auipc	a0,0x3
    8000567c:	10050513          	addi	a0,a0,256 # 80008778 <syscalls+0x318>
    80005680:	ffffb097          	auipc	ra,0xffffb
    80005684:	ec8080e7          	jalr	-312(ra) # 80000548 <panic>
    dp->nlink--;
    80005688:	04a4d783          	lhu	a5,74(s1)
    8000568c:	37fd                	addiw	a5,a5,-1
    8000568e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	fac080e7          	jalr	-84(ra) # 80003640 <iupdate>
    8000569c:	b781                	j	800055dc <sys_unlink+0xe0>
    return -1;
    8000569e:	557d                	li	a0,-1
    800056a0:	a005                	j	800056c0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056a2:	854a                	mv	a0,s2
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	2c8080e7          	jalr	712(ra) # 8000396c <iunlockput>
  iunlockput(dp);
    800056ac:	8526                	mv	a0,s1
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	2be080e7          	jalr	702(ra) # 8000396c <iunlockput>
  end_op();
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	a90080e7          	jalr	-1392(ra) # 80004146 <end_op>
  return -1;
    800056be:	557d                	li	a0,-1
}
    800056c0:	70ae                	ld	ra,232(sp)
    800056c2:	740e                	ld	s0,224(sp)
    800056c4:	64ee                	ld	s1,216(sp)
    800056c6:	694e                	ld	s2,208(sp)
    800056c8:	69ae                	ld	s3,200(sp)
    800056ca:	616d                	addi	sp,sp,240
    800056cc:	8082                	ret

00000000800056ce <sys_open>:

uint64
sys_open(void)
{
    800056ce:	7131                	addi	sp,sp,-192
    800056d0:	fd06                	sd	ra,184(sp)
    800056d2:	f922                	sd	s0,176(sp)
    800056d4:	f526                	sd	s1,168(sp)
    800056d6:	f14a                	sd	s2,160(sp)
    800056d8:	ed4e                	sd	s3,152(sp)
    800056da:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056dc:	08000613          	li	a2,128
    800056e0:	f5040593          	addi	a1,s0,-176
    800056e4:	4501                	li	a0,0
    800056e6:	ffffd097          	auipc	ra,0xffffd
    800056ea:	4f6080e7          	jalr	1270(ra) # 80002bdc <argstr>
    return -1;
    800056ee:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056f0:	0c054163          	bltz	a0,800057b2 <sys_open+0xe4>
    800056f4:	f4c40593          	addi	a1,s0,-180
    800056f8:	4505                	li	a0,1
    800056fa:	ffffd097          	auipc	ra,0xffffd
    800056fe:	49e080e7          	jalr	1182(ra) # 80002b98 <argint>
    80005702:	0a054863          	bltz	a0,800057b2 <sys_open+0xe4>

  begin_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	9c0080e7          	jalr	-1600(ra) # 800040c6 <begin_op>

  if(omode & O_CREATE){
    8000570e:	f4c42783          	lw	a5,-180(s0)
    80005712:	2007f793          	andi	a5,a5,512
    80005716:	cbdd                	beqz	a5,800057cc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005718:	4681                	li	a3,0
    8000571a:	4601                	li	a2,0
    8000571c:	4589                	li	a1,2
    8000571e:	f5040513          	addi	a0,s0,-176
    80005722:	00000097          	auipc	ra,0x0
    80005726:	972080e7          	jalr	-1678(ra) # 80005094 <create>
    8000572a:	892a                	mv	s2,a0
    if(ip == 0){
    8000572c:	c959                	beqz	a0,800057c2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000572e:	04491703          	lh	a4,68(s2)
    80005732:	478d                	li	a5,3
    80005734:	00f71763          	bne	a4,a5,80005742 <sys_open+0x74>
    80005738:	04695703          	lhu	a4,70(s2)
    8000573c:	47a5                	li	a5,9
    8000573e:	0ce7ec63          	bltu	a5,a4,80005816 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	d9a080e7          	jalr	-614(ra) # 800044dc <filealloc>
    8000574a:	89aa                	mv	s3,a0
    8000574c:	10050263          	beqz	a0,80005850 <sys_open+0x182>
    80005750:	00000097          	auipc	ra,0x0
    80005754:	902080e7          	jalr	-1790(ra) # 80005052 <fdalloc>
    80005758:	84aa                	mv	s1,a0
    8000575a:	0e054663          	bltz	a0,80005846 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000575e:	04491703          	lh	a4,68(s2)
    80005762:	478d                	li	a5,3
    80005764:	0cf70463          	beq	a4,a5,8000582c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005768:	4789                	li	a5,2
    8000576a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000576e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005772:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005776:	f4c42783          	lw	a5,-180(s0)
    8000577a:	0017c713          	xori	a4,a5,1
    8000577e:	8b05                	andi	a4,a4,1
    80005780:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005784:	0037f713          	andi	a4,a5,3
    80005788:	00e03733          	snez	a4,a4
    8000578c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005790:	4007f793          	andi	a5,a5,1024
    80005794:	c791                	beqz	a5,800057a0 <sys_open+0xd2>
    80005796:	04491703          	lh	a4,68(s2)
    8000579a:	4789                	li	a5,2
    8000579c:	08f70f63          	beq	a4,a5,8000583a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057a0:	854a                	mv	a0,s2
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	02a080e7          	jalr	42(ra) # 800037cc <iunlock>
  end_op();
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	99c080e7          	jalr	-1636(ra) # 80004146 <end_op>

  return fd;
}
    800057b2:	8526                	mv	a0,s1
    800057b4:	70ea                	ld	ra,184(sp)
    800057b6:	744a                	ld	s0,176(sp)
    800057b8:	74aa                	ld	s1,168(sp)
    800057ba:	790a                	ld	s2,160(sp)
    800057bc:	69ea                	ld	s3,152(sp)
    800057be:	6129                	addi	sp,sp,192
    800057c0:	8082                	ret
      end_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	984080e7          	jalr	-1660(ra) # 80004146 <end_op>
      return -1;
    800057ca:	b7e5                	j	800057b2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057cc:	f5040513          	addi	a0,s0,-176
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	6ea080e7          	jalr	1770(ra) # 80003eba <namei>
    800057d8:	892a                	mv	s2,a0
    800057da:	c905                	beqz	a0,8000580a <sys_open+0x13c>
    ilock(ip);
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	f2e080e7          	jalr	-210(ra) # 8000370a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057e4:	04491703          	lh	a4,68(s2)
    800057e8:	4785                	li	a5,1
    800057ea:	f4f712e3          	bne	a4,a5,8000572e <sys_open+0x60>
    800057ee:	f4c42783          	lw	a5,-180(s0)
    800057f2:	dba1                	beqz	a5,80005742 <sys_open+0x74>
      iunlockput(ip);
    800057f4:	854a                	mv	a0,s2
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	176080e7          	jalr	374(ra) # 8000396c <iunlockput>
      end_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	948080e7          	jalr	-1720(ra) # 80004146 <end_op>
      return -1;
    80005806:	54fd                	li	s1,-1
    80005808:	b76d                	j	800057b2 <sys_open+0xe4>
      end_op();
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	93c080e7          	jalr	-1732(ra) # 80004146 <end_op>
      return -1;
    80005812:	54fd                	li	s1,-1
    80005814:	bf79                	j	800057b2 <sys_open+0xe4>
    iunlockput(ip);
    80005816:	854a                	mv	a0,s2
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	154080e7          	jalr	340(ra) # 8000396c <iunlockput>
    end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	926080e7          	jalr	-1754(ra) # 80004146 <end_op>
    return -1;
    80005828:	54fd                	li	s1,-1
    8000582a:	b761                	j	800057b2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000582c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005830:	04691783          	lh	a5,70(s2)
    80005834:	02f99223          	sh	a5,36(s3)
    80005838:	bf2d                	j	80005772 <sys_open+0xa4>
    itrunc(ip);
    8000583a:	854a                	mv	a0,s2
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	fdc080e7          	jalr	-36(ra) # 80003818 <itrunc>
    80005844:	bfb1                	j	800057a0 <sys_open+0xd2>
      fileclose(f);
    80005846:	854e                	mv	a0,s3
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	d50080e7          	jalr	-688(ra) # 80004598 <fileclose>
    iunlockput(ip);
    80005850:	854a                	mv	a0,s2
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	11a080e7          	jalr	282(ra) # 8000396c <iunlockput>
    end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	8ec080e7          	jalr	-1812(ra) # 80004146 <end_op>
    return -1;
    80005862:	54fd                	li	s1,-1
    80005864:	b7b9                	j	800057b2 <sys_open+0xe4>

0000000080005866 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005866:	7175                	addi	sp,sp,-144
    80005868:	e506                	sd	ra,136(sp)
    8000586a:	e122                	sd	s0,128(sp)
    8000586c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	858080e7          	jalr	-1960(ra) # 800040c6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005876:	08000613          	li	a2,128
    8000587a:	f7040593          	addi	a1,s0,-144
    8000587e:	4501                	li	a0,0
    80005880:	ffffd097          	auipc	ra,0xffffd
    80005884:	35c080e7          	jalr	860(ra) # 80002bdc <argstr>
    80005888:	02054963          	bltz	a0,800058ba <sys_mkdir+0x54>
    8000588c:	4681                	li	a3,0
    8000588e:	4601                	li	a2,0
    80005890:	4585                	li	a1,1
    80005892:	f7040513          	addi	a0,s0,-144
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	7fe080e7          	jalr	2046(ra) # 80005094 <create>
    8000589e:	cd11                	beqz	a0,800058ba <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	0cc080e7          	jalr	204(ra) # 8000396c <iunlockput>
  end_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	89e080e7          	jalr	-1890(ra) # 80004146 <end_op>
  return 0;
    800058b0:	4501                	li	a0,0
}
    800058b2:	60aa                	ld	ra,136(sp)
    800058b4:	640a                	ld	s0,128(sp)
    800058b6:	6149                	addi	sp,sp,144
    800058b8:	8082                	ret
    end_op();
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	88c080e7          	jalr	-1908(ra) # 80004146 <end_op>
    return -1;
    800058c2:	557d                	li	a0,-1
    800058c4:	b7fd                	j	800058b2 <sys_mkdir+0x4c>

00000000800058c6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058c6:	7135                	addi	sp,sp,-160
    800058c8:	ed06                	sd	ra,152(sp)
    800058ca:	e922                	sd	s0,144(sp)
    800058cc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	7f8080e7          	jalr	2040(ra) # 800040c6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058d6:	08000613          	li	a2,128
    800058da:	f7040593          	addi	a1,s0,-144
    800058de:	4501                	li	a0,0
    800058e0:	ffffd097          	auipc	ra,0xffffd
    800058e4:	2fc080e7          	jalr	764(ra) # 80002bdc <argstr>
    800058e8:	04054a63          	bltz	a0,8000593c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800058ec:	f6c40593          	addi	a1,s0,-148
    800058f0:	4505                	li	a0,1
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	2a6080e7          	jalr	678(ra) # 80002b98 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058fa:	04054163          	bltz	a0,8000593c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058fe:	f6840593          	addi	a1,s0,-152
    80005902:	4509                	li	a0,2
    80005904:	ffffd097          	auipc	ra,0xffffd
    80005908:	294080e7          	jalr	660(ra) # 80002b98 <argint>
     argint(1, &major) < 0 ||
    8000590c:	02054863          	bltz	a0,8000593c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005910:	f6841683          	lh	a3,-152(s0)
    80005914:	f6c41603          	lh	a2,-148(s0)
    80005918:	458d                	li	a1,3
    8000591a:	f7040513          	addi	a0,s0,-144
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	776080e7          	jalr	1910(ra) # 80005094 <create>
     argint(2, &minor) < 0 ||
    80005926:	c919                	beqz	a0,8000593c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	044080e7          	jalr	68(ra) # 8000396c <iunlockput>
  end_op();
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	816080e7          	jalr	-2026(ra) # 80004146 <end_op>
  return 0;
    80005938:	4501                	li	a0,0
    8000593a:	a031                	j	80005946 <sys_mknod+0x80>
    end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	80a080e7          	jalr	-2038(ra) # 80004146 <end_op>
    return -1;
    80005944:	557d                	li	a0,-1
}
    80005946:	60ea                	ld	ra,152(sp)
    80005948:	644a                	ld	s0,144(sp)
    8000594a:	610d                	addi	sp,sp,160
    8000594c:	8082                	ret

000000008000594e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000594e:	7135                	addi	sp,sp,-160
    80005950:	ed06                	sd	ra,152(sp)
    80005952:	e922                	sd	s0,144(sp)
    80005954:	e526                	sd	s1,136(sp)
    80005956:	e14a                	sd	s2,128(sp)
    80005958:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000595a:	ffffc097          	auipc	ra,0xffffc
    8000595e:	184080e7          	jalr	388(ra) # 80001ade <myproc>
    80005962:	892a                	mv	s2,a0
  
  begin_op();
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	762080e7          	jalr	1890(ra) # 800040c6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000596c:	08000613          	li	a2,128
    80005970:	f6040593          	addi	a1,s0,-160
    80005974:	4501                	li	a0,0
    80005976:	ffffd097          	auipc	ra,0xffffd
    8000597a:	266080e7          	jalr	614(ra) # 80002bdc <argstr>
    8000597e:	04054b63          	bltz	a0,800059d4 <sys_chdir+0x86>
    80005982:	f6040513          	addi	a0,s0,-160
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	534080e7          	jalr	1332(ra) # 80003eba <namei>
    8000598e:	84aa                	mv	s1,a0
    80005990:	c131                	beqz	a0,800059d4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	d78080e7          	jalr	-648(ra) # 8000370a <ilock>
  if(ip->type != T_DIR){
    8000599a:	04449703          	lh	a4,68(s1)
    8000599e:	4785                	li	a5,1
    800059a0:	04f71063          	bne	a4,a5,800059e0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059a4:	8526                	mv	a0,s1
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	e26080e7          	jalr	-474(ra) # 800037cc <iunlock>
  iput(p->cwd);
    800059ae:	15093503          	ld	a0,336(s2)
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	f12080e7          	jalr	-238(ra) # 800038c4 <iput>
  end_op();
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	78c080e7          	jalr	1932(ra) # 80004146 <end_op>
  p->cwd = ip;
    800059c2:	14993823          	sd	s1,336(s2)
  return 0;
    800059c6:	4501                	li	a0,0
}
    800059c8:	60ea                	ld	ra,152(sp)
    800059ca:	644a                	ld	s0,144(sp)
    800059cc:	64aa                	ld	s1,136(sp)
    800059ce:	690a                	ld	s2,128(sp)
    800059d0:	610d                	addi	sp,sp,160
    800059d2:	8082                	ret
    end_op();
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	772080e7          	jalr	1906(ra) # 80004146 <end_op>
    return -1;
    800059dc:	557d                	li	a0,-1
    800059de:	b7ed                	j	800059c8 <sys_chdir+0x7a>
    iunlockput(ip);
    800059e0:	8526                	mv	a0,s1
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	f8a080e7          	jalr	-118(ra) # 8000396c <iunlockput>
    end_op();
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	75c080e7          	jalr	1884(ra) # 80004146 <end_op>
    return -1;
    800059f2:	557d                	li	a0,-1
    800059f4:	bfd1                	j	800059c8 <sys_chdir+0x7a>

00000000800059f6 <sys_exec>:

uint64
sys_exec(void)
{
    800059f6:	7145                	addi	sp,sp,-464
    800059f8:	e786                	sd	ra,456(sp)
    800059fa:	e3a2                	sd	s0,448(sp)
    800059fc:	ff26                	sd	s1,440(sp)
    800059fe:	fb4a                	sd	s2,432(sp)
    80005a00:	f74e                	sd	s3,424(sp)
    80005a02:	f352                	sd	s4,416(sp)
    80005a04:	ef56                	sd	s5,408(sp)
    80005a06:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a08:	08000613          	li	a2,128
    80005a0c:	f4040593          	addi	a1,s0,-192
    80005a10:	4501                	li	a0,0
    80005a12:	ffffd097          	auipc	ra,0xffffd
    80005a16:	1ca080e7          	jalr	458(ra) # 80002bdc <argstr>
    return -1;
    80005a1a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a1c:	0c054a63          	bltz	a0,80005af0 <sys_exec+0xfa>
    80005a20:	e3840593          	addi	a1,s0,-456
    80005a24:	4505                	li	a0,1
    80005a26:	ffffd097          	auipc	ra,0xffffd
    80005a2a:	194080e7          	jalr	404(ra) # 80002bba <argaddr>
    80005a2e:	0c054163          	bltz	a0,80005af0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a32:	10000613          	li	a2,256
    80005a36:	4581                	li	a1,0
    80005a38:	e4040513          	addi	a0,s0,-448
    80005a3c:	ffffb097          	auipc	ra,0xffffb
    80005a40:	2d0080e7          	jalr	720(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a44:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a48:	89a6                	mv	s3,s1
    80005a4a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a4c:	02000a13          	li	s4,32
    80005a50:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a54:	00391513          	slli	a0,s2,0x3
    80005a58:	e3040593          	addi	a1,s0,-464
    80005a5c:	e3843783          	ld	a5,-456(s0)
    80005a60:	953e                	add	a0,a0,a5
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	09c080e7          	jalr	156(ra) # 80002afe <fetchaddr>
    80005a6a:	02054a63          	bltz	a0,80005a9e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a6e:	e3043783          	ld	a5,-464(s0)
    80005a72:	c3b9                	beqz	a5,80005ab8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a74:	ffffb097          	auipc	ra,0xffffb
    80005a78:	0ac080e7          	jalr	172(ra) # 80000b20 <kalloc>
    80005a7c:	85aa                	mv	a1,a0
    80005a7e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a82:	cd11                	beqz	a0,80005a9e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a84:	6605                	lui	a2,0x1
    80005a86:	e3043503          	ld	a0,-464(s0)
    80005a8a:	ffffd097          	auipc	ra,0xffffd
    80005a8e:	0c6080e7          	jalr	198(ra) # 80002b50 <fetchstr>
    80005a92:	00054663          	bltz	a0,80005a9e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a96:	0905                	addi	s2,s2,1
    80005a98:	09a1                	addi	s3,s3,8
    80005a9a:	fb491be3          	bne	s2,s4,80005a50 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a9e:	10048913          	addi	s2,s1,256
    80005aa2:	6088                	ld	a0,0(s1)
    80005aa4:	c529                	beqz	a0,80005aee <sys_exec+0xf8>
    kfree(argv[i]);
    80005aa6:	ffffb097          	auipc	ra,0xffffb
    80005aaa:	f7e080e7          	jalr	-130(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aae:	04a1                	addi	s1,s1,8
    80005ab0:	ff2499e3          	bne	s1,s2,80005aa2 <sys_exec+0xac>
  return -1;
    80005ab4:	597d                	li	s2,-1
    80005ab6:	a82d                	j	80005af0 <sys_exec+0xfa>
      argv[i] = 0;
    80005ab8:	0a8e                	slli	s5,s5,0x3
    80005aba:	fc040793          	addi	a5,s0,-64
    80005abe:	9abe                	add	s5,s5,a5
    80005ac0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ac4:	e4040593          	addi	a1,s0,-448
    80005ac8:	f4040513          	addi	a0,s0,-192
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	17c080e7          	jalr	380(ra) # 80004c48 <exec>
    80005ad4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ad6:	10048993          	addi	s3,s1,256
    80005ada:	6088                	ld	a0,0(s1)
    80005adc:	c911                	beqz	a0,80005af0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ade:	ffffb097          	auipc	ra,0xffffb
    80005ae2:	f46080e7          	jalr	-186(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae6:	04a1                	addi	s1,s1,8
    80005ae8:	ff3499e3          	bne	s1,s3,80005ada <sys_exec+0xe4>
    80005aec:	a011                	j	80005af0 <sys_exec+0xfa>
  return -1;
    80005aee:	597d                	li	s2,-1
}
    80005af0:	854a                	mv	a0,s2
    80005af2:	60be                	ld	ra,456(sp)
    80005af4:	641e                	ld	s0,448(sp)
    80005af6:	74fa                	ld	s1,440(sp)
    80005af8:	795a                	ld	s2,432(sp)
    80005afa:	79ba                	ld	s3,424(sp)
    80005afc:	7a1a                	ld	s4,416(sp)
    80005afe:	6afa                	ld	s5,408(sp)
    80005b00:	6179                	addi	sp,sp,464
    80005b02:	8082                	ret

0000000080005b04 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b04:	7139                	addi	sp,sp,-64
    80005b06:	fc06                	sd	ra,56(sp)
    80005b08:	f822                	sd	s0,48(sp)
    80005b0a:	f426                	sd	s1,40(sp)
    80005b0c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b0e:	ffffc097          	auipc	ra,0xffffc
    80005b12:	fd0080e7          	jalr	-48(ra) # 80001ade <myproc>
    80005b16:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b18:	fd840593          	addi	a1,s0,-40
    80005b1c:	4501                	li	a0,0
    80005b1e:	ffffd097          	auipc	ra,0xffffd
    80005b22:	09c080e7          	jalr	156(ra) # 80002bba <argaddr>
    return -1;
    80005b26:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b28:	0e054063          	bltz	a0,80005c08 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b2c:	fc840593          	addi	a1,s0,-56
    80005b30:	fd040513          	addi	a0,s0,-48
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	dba080e7          	jalr	-582(ra) # 800048ee <pipealloc>
    return -1;
    80005b3c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b3e:	0c054563          	bltz	a0,80005c08 <sys_pipe+0x104>
  fd0 = -1;
    80005b42:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b46:	fd043503          	ld	a0,-48(s0)
    80005b4a:	fffff097          	auipc	ra,0xfffff
    80005b4e:	508080e7          	jalr	1288(ra) # 80005052 <fdalloc>
    80005b52:	fca42223          	sw	a0,-60(s0)
    80005b56:	08054c63          	bltz	a0,80005bee <sys_pipe+0xea>
    80005b5a:	fc843503          	ld	a0,-56(s0)
    80005b5e:	fffff097          	auipc	ra,0xfffff
    80005b62:	4f4080e7          	jalr	1268(ra) # 80005052 <fdalloc>
    80005b66:	fca42023          	sw	a0,-64(s0)
    80005b6a:	06054863          	bltz	a0,80005bda <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b6e:	4691                	li	a3,4
    80005b70:	fc440613          	addi	a2,s0,-60
    80005b74:	fd843583          	ld	a1,-40(s0)
    80005b78:	68a8                	ld	a0,80(s1)
    80005b7a:	ffffc097          	auipc	ra,0xffffc
    80005b7e:	c58080e7          	jalr	-936(ra) # 800017d2 <copyout>
    80005b82:	02054063          	bltz	a0,80005ba2 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b86:	4691                	li	a3,4
    80005b88:	fc040613          	addi	a2,s0,-64
    80005b8c:	fd843583          	ld	a1,-40(s0)
    80005b90:	0591                	addi	a1,a1,4
    80005b92:	68a8                	ld	a0,80(s1)
    80005b94:	ffffc097          	auipc	ra,0xffffc
    80005b98:	c3e080e7          	jalr	-962(ra) # 800017d2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b9c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b9e:	06055563          	bgez	a0,80005c08 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005ba2:	fc442783          	lw	a5,-60(s0)
    80005ba6:	07e9                	addi	a5,a5,26
    80005ba8:	078e                	slli	a5,a5,0x3
    80005baa:	97a6                	add	a5,a5,s1
    80005bac:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bb0:	fc042503          	lw	a0,-64(s0)
    80005bb4:	0569                	addi	a0,a0,26
    80005bb6:	050e                	slli	a0,a0,0x3
    80005bb8:	9526                	add	a0,a0,s1
    80005bba:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bbe:	fd043503          	ld	a0,-48(s0)
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	9d6080e7          	jalr	-1578(ra) # 80004598 <fileclose>
    fileclose(wf);
    80005bca:	fc843503          	ld	a0,-56(s0)
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	9ca080e7          	jalr	-1590(ra) # 80004598 <fileclose>
    return -1;
    80005bd6:	57fd                	li	a5,-1
    80005bd8:	a805                	j	80005c08 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bda:	fc442783          	lw	a5,-60(s0)
    80005bde:	0007c863          	bltz	a5,80005bee <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005be2:	01a78513          	addi	a0,a5,26
    80005be6:	050e                	slli	a0,a0,0x3
    80005be8:	9526                	add	a0,a0,s1
    80005bea:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bee:	fd043503          	ld	a0,-48(s0)
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	9a6080e7          	jalr	-1626(ra) # 80004598 <fileclose>
    fileclose(wf);
    80005bfa:	fc843503          	ld	a0,-56(s0)
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	99a080e7          	jalr	-1638(ra) # 80004598 <fileclose>
    return -1;
    80005c06:	57fd                	li	a5,-1
}
    80005c08:	853e                	mv	a0,a5
    80005c0a:	70e2                	ld	ra,56(sp)
    80005c0c:	7442                	ld	s0,48(sp)
    80005c0e:	74a2                	ld	s1,40(sp)
    80005c10:	6121                	addi	sp,sp,64
    80005c12:	8082                	ret
	...

0000000080005c20 <kernelvec>:
    80005c20:	7111                	addi	sp,sp,-256
    80005c22:	e006                	sd	ra,0(sp)
    80005c24:	e40a                	sd	sp,8(sp)
    80005c26:	e80e                	sd	gp,16(sp)
    80005c28:	ec12                	sd	tp,24(sp)
    80005c2a:	f016                	sd	t0,32(sp)
    80005c2c:	f41a                	sd	t1,40(sp)
    80005c2e:	f81e                	sd	t2,48(sp)
    80005c30:	fc22                	sd	s0,56(sp)
    80005c32:	e0a6                	sd	s1,64(sp)
    80005c34:	e4aa                	sd	a0,72(sp)
    80005c36:	e8ae                	sd	a1,80(sp)
    80005c38:	ecb2                	sd	a2,88(sp)
    80005c3a:	f0b6                	sd	a3,96(sp)
    80005c3c:	f4ba                	sd	a4,104(sp)
    80005c3e:	f8be                	sd	a5,112(sp)
    80005c40:	fcc2                	sd	a6,120(sp)
    80005c42:	e146                	sd	a7,128(sp)
    80005c44:	e54a                	sd	s2,136(sp)
    80005c46:	e94e                	sd	s3,144(sp)
    80005c48:	ed52                	sd	s4,152(sp)
    80005c4a:	f156                	sd	s5,160(sp)
    80005c4c:	f55a                	sd	s6,168(sp)
    80005c4e:	f95e                	sd	s7,176(sp)
    80005c50:	fd62                	sd	s8,184(sp)
    80005c52:	e1e6                	sd	s9,192(sp)
    80005c54:	e5ea                	sd	s10,200(sp)
    80005c56:	e9ee                	sd	s11,208(sp)
    80005c58:	edf2                	sd	t3,216(sp)
    80005c5a:	f1f6                	sd	t4,224(sp)
    80005c5c:	f5fa                	sd	t5,232(sp)
    80005c5e:	f9fe                	sd	t6,240(sp)
    80005c60:	d6bfc0ef          	jal	ra,800029ca <kerneltrap>
    80005c64:	6082                	ld	ra,0(sp)
    80005c66:	6122                	ld	sp,8(sp)
    80005c68:	61c2                	ld	gp,16(sp)
    80005c6a:	7282                	ld	t0,32(sp)
    80005c6c:	7322                	ld	t1,40(sp)
    80005c6e:	73c2                	ld	t2,48(sp)
    80005c70:	7462                	ld	s0,56(sp)
    80005c72:	6486                	ld	s1,64(sp)
    80005c74:	6526                	ld	a0,72(sp)
    80005c76:	65c6                	ld	a1,80(sp)
    80005c78:	6666                	ld	a2,88(sp)
    80005c7a:	7686                	ld	a3,96(sp)
    80005c7c:	7726                	ld	a4,104(sp)
    80005c7e:	77c6                	ld	a5,112(sp)
    80005c80:	7866                	ld	a6,120(sp)
    80005c82:	688a                	ld	a7,128(sp)
    80005c84:	692a                	ld	s2,136(sp)
    80005c86:	69ca                	ld	s3,144(sp)
    80005c88:	6a6a                	ld	s4,152(sp)
    80005c8a:	7a8a                	ld	s5,160(sp)
    80005c8c:	7b2a                	ld	s6,168(sp)
    80005c8e:	7bca                	ld	s7,176(sp)
    80005c90:	7c6a                	ld	s8,184(sp)
    80005c92:	6c8e                	ld	s9,192(sp)
    80005c94:	6d2e                	ld	s10,200(sp)
    80005c96:	6dce                	ld	s11,208(sp)
    80005c98:	6e6e                	ld	t3,216(sp)
    80005c9a:	7e8e                	ld	t4,224(sp)
    80005c9c:	7f2e                	ld	t5,232(sp)
    80005c9e:	7fce                	ld	t6,240(sp)
    80005ca0:	6111                	addi	sp,sp,256
    80005ca2:	10200073          	sret
    80005ca6:	00000013          	nop
    80005caa:	00000013          	nop
    80005cae:	0001                	nop

0000000080005cb0 <timervec>:
    80005cb0:	34051573          	csrrw	a0,mscratch,a0
    80005cb4:	e10c                	sd	a1,0(a0)
    80005cb6:	e510                	sd	a2,8(a0)
    80005cb8:	e914                	sd	a3,16(a0)
    80005cba:	710c                	ld	a1,32(a0)
    80005cbc:	7510                	ld	a2,40(a0)
    80005cbe:	6194                	ld	a3,0(a1)
    80005cc0:	96b2                	add	a3,a3,a2
    80005cc2:	e194                	sd	a3,0(a1)
    80005cc4:	4589                	li	a1,2
    80005cc6:	14459073          	csrw	sip,a1
    80005cca:	6914                	ld	a3,16(a0)
    80005ccc:	6510                	ld	a2,8(a0)
    80005cce:	610c                	ld	a1,0(a0)
    80005cd0:	34051573          	csrrw	a0,mscratch,a0
    80005cd4:	30200073          	mret
	...

0000000080005cda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cda:	1141                	addi	sp,sp,-16
    80005cdc:	e422                	sd	s0,8(sp)
    80005cde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ce0:	0c0007b7          	lui	a5,0xc000
    80005ce4:	4705                	li	a4,1
    80005ce6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ce8:	c3d8                	sw	a4,4(a5)
}
    80005cea:	6422                	ld	s0,8(sp)
    80005cec:	0141                	addi	sp,sp,16
    80005cee:	8082                	ret

0000000080005cf0 <plicinithart>:

void
plicinithart(void)
{
    80005cf0:	1141                	addi	sp,sp,-16
    80005cf2:	e406                	sd	ra,8(sp)
    80005cf4:	e022                	sd	s0,0(sp)
    80005cf6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	dba080e7          	jalr	-582(ra) # 80001ab2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d00:	0085171b          	slliw	a4,a0,0x8
    80005d04:	0c0027b7          	lui	a5,0xc002
    80005d08:	97ba                	add	a5,a5,a4
    80005d0a:	40200713          	li	a4,1026
    80005d0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d12:	00d5151b          	slliw	a0,a0,0xd
    80005d16:	0c2017b7          	lui	a5,0xc201
    80005d1a:	953e                	add	a0,a0,a5
    80005d1c:	00052023          	sw	zero,0(a0)
}
    80005d20:	60a2                	ld	ra,8(sp)
    80005d22:	6402                	ld	s0,0(sp)
    80005d24:	0141                	addi	sp,sp,16
    80005d26:	8082                	ret

0000000080005d28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d28:	1141                	addi	sp,sp,-16
    80005d2a:	e406                	sd	ra,8(sp)
    80005d2c:	e022                	sd	s0,0(sp)
    80005d2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d30:	ffffc097          	auipc	ra,0xffffc
    80005d34:	d82080e7          	jalr	-638(ra) # 80001ab2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d38:	00d5179b          	slliw	a5,a0,0xd
    80005d3c:	0c201537          	lui	a0,0xc201
    80005d40:	953e                	add	a0,a0,a5
  return irq;
}
    80005d42:	4148                	lw	a0,4(a0)
    80005d44:	60a2                	ld	ra,8(sp)
    80005d46:	6402                	ld	s0,0(sp)
    80005d48:	0141                	addi	sp,sp,16
    80005d4a:	8082                	ret

0000000080005d4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d4c:	1101                	addi	sp,sp,-32
    80005d4e:	ec06                	sd	ra,24(sp)
    80005d50:	e822                	sd	s0,16(sp)
    80005d52:	e426                	sd	s1,8(sp)
    80005d54:	1000                	addi	s0,sp,32
    80005d56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	d5a080e7          	jalr	-678(ra) # 80001ab2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d60:	00d5151b          	slliw	a0,a0,0xd
    80005d64:	0c2017b7          	lui	a5,0xc201
    80005d68:	97aa                	add	a5,a5,a0
    80005d6a:	c3c4                	sw	s1,4(a5)
}
    80005d6c:	60e2                	ld	ra,24(sp)
    80005d6e:	6442                	ld	s0,16(sp)
    80005d70:	64a2                	ld	s1,8(sp)
    80005d72:	6105                	addi	sp,sp,32
    80005d74:	8082                	ret

0000000080005d76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d76:	1141                	addi	sp,sp,-16
    80005d78:	e406                	sd	ra,8(sp)
    80005d7a:	e022                	sd	s0,0(sp)
    80005d7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d7e:	479d                	li	a5,7
    80005d80:	04a7cc63          	blt	a5,a0,80005dd8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d84:	0001d797          	auipc	a5,0x1d
    80005d88:	27c78793          	addi	a5,a5,636 # 80023000 <disk>
    80005d8c:	00a78733          	add	a4,a5,a0
    80005d90:	6789                	lui	a5,0x2
    80005d92:	97ba                	add	a5,a5,a4
    80005d94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d98:	eba1                	bnez	a5,80005de8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d9a:	00451713          	slli	a4,a0,0x4
    80005d9e:	0001f797          	auipc	a5,0x1f
    80005da2:	2627b783          	ld	a5,610(a5) # 80025000 <disk+0x2000>
    80005da6:	97ba                	add	a5,a5,a4
    80005da8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dac:	0001d797          	auipc	a5,0x1d
    80005db0:	25478793          	addi	a5,a5,596 # 80023000 <disk>
    80005db4:	97aa                	add	a5,a5,a0
    80005db6:	6509                	lui	a0,0x2
    80005db8:	953e                	add	a0,a0,a5
    80005dba:	4785                	li	a5,1
    80005dbc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005dc0:	0001f517          	auipc	a0,0x1f
    80005dc4:	25850513          	addi	a0,a0,600 # 80025018 <disk+0x2018>
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	6a8080e7          	jalr	1704(ra) # 80002470 <wakeup>
}
    80005dd0:	60a2                	ld	ra,8(sp)
    80005dd2:	6402                	ld	s0,0(sp)
    80005dd4:	0141                	addi	sp,sp,16
    80005dd6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005dd8:	00003517          	auipc	a0,0x3
    80005ddc:	9b050513          	addi	a0,a0,-1616 # 80008788 <syscalls+0x328>
    80005de0:	ffffa097          	auipc	ra,0xffffa
    80005de4:	768080e7          	jalr	1896(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005de8:	00003517          	auipc	a0,0x3
    80005dec:	9b850513          	addi	a0,a0,-1608 # 800087a0 <syscalls+0x340>
    80005df0:	ffffa097          	auipc	ra,0xffffa
    80005df4:	758080e7          	jalr	1880(ra) # 80000548 <panic>

0000000080005df8 <virtio_disk_init>:
{
    80005df8:	1101                	addi	sp,sp,-32
    80005dfa:	ec06                	sd	ra,24(sp)
    80005dfc:	e822                	sd	s0,16(sp)
    80005dfe:	e426                	sd	s1,8(sp)
    80005e00:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e02:	00003597          	auipc	a1,0x3
    80005e06:	9b658593          	addi	a1,a1,-1610 # 800087b8 <syscalls+0x358>
    80005e0a:	0001f517          	auipc	a0,0x1f
    80005e0e:	29e50513          	addi	a0,a0,670 # 800250a8 <disk+0x20a8>
    80005e12:	ffffb097          	auipc	ra,0xffffb
    80005e16:	d6e080e7          	jalr	-658(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e1a:	100017b7          	lui	a5,0x10001
    80005e1e:	4398                	lw	a4,0(a5)
    80005e20:	2701                	sext.w	a4,a4
    80005e22:	747277b7          	lui	a5,0x74727
    80005e26:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e2a:	0ef71163          	bne	a4,a5,80005f0c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e2e:	100017b7          	lui	a5,0x10001
    80005e32:	43dc                	lw	a5,4(a5)
    80005e34:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e36:	4705                	li	a4,1
    80005e38:	0ce79a63          	bne	a5,a4,80005f0c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e3c:	100017b7          	lui	a5,0x10001
    80005e40:	479c                	lw	a5,8(a5)
    80005e42:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e44:	4709                	li	a4,2
    80005e46:	0ce79363          	bne	a5,a4,80005f0c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e4a:	100017b7          	lui	a5,0x10001
    80005e4e:	47d8                	lw	a4,12(a5)
    80005e50:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e52:	554d47b7          	lui	a5,0x554d4
    80005e56:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e5a:	0af71963          	bne	a4,a5,80005f0c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e5e:	100017b7          	lui	a5,0x10001
    80005e62:	4705                	li	a4,1
    80005e64:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e66:	470d                	li	a4,3
    80005e68:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e6a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e6c:	c7ffe737          	lui	a4,0xc7ffe
    80005e70:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80005e74:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e76:	2701                	sext.w	a4,a4
    80005e78:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7a:	472d                	li	a4,11
    80005e7c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7e:	473d                	li	a4,15
    80005e80:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e82:	6705                	lui	a4,0x1
    80005e84:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e86:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e8a:	5bdc                	lw	a5,52(a5)
    80005e8c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e8e:	c7d9                	beqz	a5,80005f1c <virtio_disk_init+0x124>
  if(max < NUM)
    80005e90:	471d                	li	a4,7
    80005e92:	08f77d63          	bgeu	a4,a5,80005f2c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e96:	100014b7          	lui	s1,0x10001
    80005e9a:	47a1                	li	a5,8
    80005e9c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e9e:	6609                	lui	a2,0x2
    80005ea0:	4581                	li	a1,0
    80005ea2:	0001d517          	auipc	a0,0x1d
    80005ea6:	15e50513          	addi	a0,a0,350 # 80023000 <disk>
    80005eaa:	ffffb097          	auipc	ra,0xffffb
    80005eae:	e62080e7          	jalr	-414(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005eb2:	0001d717          	auipc	a4,0x1d
    80005eb6:	14e70713          	addi	a4,a4,334 # 80023000 <disk>
    80005eba:	00c75793          	srli	a5,a4,0xc
    80005ebe:	2781                	sext.w	a5,a5
    80005ec0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ec2:	0001f797          	auipc	a5,0x1f
    80005ec6:	13e78793          	addi	a5,a5,318 # 80025000 <disk+0x2000>
    80005eca:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005ecc:	0001d717          	auipc	a4,0x1d
    80005ed0:	1b470713          	addi	a4,a4,436 # 80023080 <disk+0x80>
    80005ed4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005ed6:	0001e717          	auipc	a4,0x1e
    80005eda:	12a70713          	addi	a4,a4,298 # 80024000 <disk+0x1000>
    80005ede:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ee0:	4705                	li	a4,1
    80005ee2:	00e78c23          	sb	a4,24(a5)
    80005ee6:	00e78ca3          	sb	a4,25(a5)
    80005eea:	00e78d23          	sb	a4,26(a5)
    80005eee:	00e78da3          	sb	a4,27(a5)
    80005ef2:	00e78e23          	sb	a4,28(a5)
    80005ef6:	00e78ea3          	sb	a4,29(a5)
    80005efa:	00e78f23          	sb	a4,30(a5)
    80005efe:	00e78fa3          	sb	a4,31(a5)
}
    80005f02:	60e2                	ld	ra,24(sp)
    80005f04:	6442                	ld	s0,16(sp)
    80005f06:	64a2                	ld	s1,8(sp)
    80005f08:	6105                	addi	sp,sp,32
    80005f0a:	8082                	ret
    panic("could not find virtio disk");
    80005f0c:	00003517          	auipc	a0,0x3
    80005f10:	8bc50513          	addi	a0,a0,-1860 # 800087c8 <syscalls+0x368>
    80005f14:	ffffa097          	auipc	ra,0xffffa
    80005f18:	634080e7          	jalr	1588(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f1c:	00003517          	auipc	a0,0x3
    80005f20:	8cc50513          	addi	a0,a0,-1844 # 800087e8 <syscalls+0x388>
    80005f24:	ffffa097          	auipc	ra,0xffffa
    80005f28:	624080e7          	jalr	1572(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f2c:	00003517          	auipc	a0,0x3
    80005f30:	8dc50513          	addi	a0,a0,-1828 # 80008808 <syscalls+0x3a8>
    80005f34:	ffffa097          	auipc	ra,0xffffa
    80005f38:	614080e7          	jalr	1556(ra) # 80000548 <panic>

0000000080005f3c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f3c:	7119                	addi	sp,sp,-128
    80005f3e:	fc86                	sd	ra,120(sp)
    80005f40:	f8a2                	sd	s0,112(sp)
    80005f42:	f4a6                	sd	s1,104(sp)
    80005f44:	f0ca                	sd	s2,96(sp)
    80005f46:	ecce                	sd	s3,88(sp)
    80005f48:	e8d2                	sd	s4,80(sp)
    80005f4a:	e4d6                	sd	s5,72(sp)
    80005f4c:	e0da                	sd	s6,64(sp)
    80005f4e:	fc5e                	sd	s7,56(sp)
    80005f50:	f862                	sd	s8,48(sp)
    80005f52:	f466                	sd	s9,40(sp)
    80005f54:	f06a                	sd	s10,32(sp)
    80005f56:	0100                	addi	s0,sp,128
    80005f58:	892a                	mv	s2,a0
    80005f5a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f5c:	00c52c83          	lw	s9,12(a0)
    80005f60:	001c9c9b          	slliw	s9,s9,0x1
    80005f64:	1c82                	slli	s9,s9,0x20
    80005f66:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f6a:	0001f517          	auipc	a0,0x1f
    80005f6e:	13e50513          	addi	a0,a0,318 # 800250a8 <disk+0x20a8>
    80005f72:	ffffb097          	auipc	ra,0xffffb
    80005f76:	c9e080e7          	jalr	-866(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    80005f7a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f7c:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f7e:	0001db97          	auipc	s7,0x1d
    80005f82:	082b8b93          	addi	s7,s7,130 # 80023000 <disk>
    80005f86:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f88:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f8a:	8a4e                	mv	s4,s3
    80005f8c:	a051                	j	80006010 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f8e:	00fb86b3          	add	a3,s7,a5
    80005f92:	96da                	add	a3,a3,s6
    80005f94:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005f98:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005f9a:	0207c563          	bltz	a5,80005fc4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f9e:	2485                	addiw	s1,s1,1
    80005fa0:	0711                	addi	a4,a4,4
    80005fa2:	23548d63          	beq	s1,s5,800061dc <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005fa6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fa8:	0001f697          	auipc	a3,0x1f
    80005fac:	07068693          	addi	a3,a3,112 # 80025018 <disk+0x2018>
    80005fb0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fb2:	0006c583          	lbu	a1,0(a3)
    80005fb6:	fde1                	bnez	a1,80005f8e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fb8:	2785                	addiw	a5,a5,1
    80005fba:	0685                	addi	a3,a3,1
    80005fbc:	ff879be3          	bne	a5,s8,80005fb2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fc0:	57fd                	li	a5,-1
    80005fc2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fc4:	02905a63          	blez	s1,80005ff8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fc8:	f9042503          	lw	a0,-112(s0)
    80005fcc:	00000097          	auipc	ra,0x0
    80005fd0:	daa080e7          	jalr	-598(ra) # 80005d76 <free_desc>
      for(int j = 0; j < i; j++)
    80005fd4:	4785                	li	a5,1
    80005fd6:	0297d163          	bge	a5,s1,80005ff8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fda:	f9442503          	lw	a0,-108(s0)
    80005fde:	00000097          	auipc	ra,0x0
    80005fe2:	d98080e7          	jalr	-616(ra) # 80005d76 <free_desc>
      for(int j = 0; j < i; j++)
    80005fe6:	4789                	li	a5,2
    80005fe8:	0097d863          	bge	a5,s1,80005ff8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fec:	f9842503          	lw	a0,-104(s0)
    80005ff0:	00000097          	auipc	ra,0x0
    80005ff4:	d86080e7          	jalr	-634(ra) # 80005d76 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ff8:	0001f597          	auipc	a1,0x1f
    80005ffc:	0b058593          	addi	a1,a1,176 # 800250a8 <disk+0x20a8>
    80006000:	0001f517          	auipc	a0,0x1f
    80006004:	01850513          	addi	a0,a0,24 # 80025018 <disk+0x2018>
    80006008:	ffffc097          	auipc	ra,0xffffc
    8000600c:	2e2080e7          	jalr	738(ra) # 800022ea <sleep>
  for(int i = 0; i < 3; i++){
    80006010:	f9040713          	addi	a4,s0,-112
    80006014:	84ce                	mv	s1,s3
    80006016:	bf41                	j	80005fa6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006018:	4785                	li	a5,1
    8000601a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000601e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006022:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006026:	f9042983          	lw	s3,-112(s0)
    8000602a:	00499493          	slli	s1,s3,0x4
    8000602e:	0001fa17          	auipc	s4,0x1f
    80006032:	fd2a0a13          	addi	s4,s4,-46 # 80025000 <disk+0x2000>
    80006036:	000a3a83          	ld	s5,0(s4)
    8000603a:	9aa6                	add	s5,s5,s1
    8000603c:	f8040513          	addi	a0,s0,-128
    80006040:	ffffb097          	auipc	ra,0xffffb
    80006044:	0a8080e7          	jalr	168(ra) # 800010e8 <kvmpa>
    80006048:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000604c:	000a3783          	ld	a5,0(s4)
    80006050:	97a6                	add	a5,a5,s1
    80006052:	4741                	li	a4,16
    80006054:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006056:	000a3783          	ld	a5,0(s4)
    8000605a:	97a6                	add	a5,a5,s1
    8000605c:	4705                	li	a4,1
    8000605e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006062:	f9442703          	lw	a4,-108(s0)
    80006066:	000a3783          	ld	a5,0(s4)
    8000606a:	97a6                	add	a5,a5,s1
    8000606c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006070:	0712                	slli	a4,a4,0x4
    80006072:	000a3783          	ld	a5,0(s4)
    80006076:	97ba                	add	a5,a5,a4
    80006078:	05890693          	addi	a3,s2,88
    8000607c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000607e:	000a3783          	ld	a5,0(s4)
    80006082:	97ba                	add	a5,a5,a4
    80006084:	40000693          	li	a3,1024
    80006088:	c794                	sw	a3,8(a5)
  if(write)
    8000608a:	100d0a63          	beqz	s10,8000619e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000608e:	0001f797          	auipc	a5,0x1f
    80006092:	f727b783          	ld	a5,-142(a5) # 80025000 <disk+0x2000>
    80006096:	97ba                	add	a5,a5,a4
    80006098:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000609c:	0001d517          	auipc	a0,0x1d
    800060a0:	f6450513          	addi	a0,a0,-156 # 80023000 <disk>
    800060a4:	0001f797          	auipc	a5,0x1f
    800060a8:	f5c78793          	addi	a5,a5,-164 # 80025000 <disk+0x2000>
    800060ac:	6394                	ld	a3,0(a5)
    800060ae:	96ba                	add	a3,a3,a4
    800060b0:	00c6d603          	lhu	a2,12(a3)
    800060b4:	00166613          	ori	a2,a2,1
    800060b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060bc:	f9842683          	lw	a3,-104(s0)
    800060c0:	6390                	ld	a2,0(a5)
    800060c2:	9732                	add	a4,a4,a2
    800060c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800060c8:	20098613          	addi	a2,s3,512
    800060cc:	0612                	slli	a2,a2,0x4
    800060ce:	962a                	add	a2,a2,a0
    800060d0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060d4:	00469713          	slli	a4,a3,0x4
    800060d8:	6394                	ld	a3,0(a5)
    800060da:	96ba                	add	a3,a3,a4
    800060dc:	6589                	lui	a1,0x2
    800060de:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800060e2:	94ae                	add	s1,s1,a1
    800060e4:	94aa                	add	s1,s1,a0
    800060e6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800060e8:	6394                	ld	a3,0(a5)
    800060ea:	96ba                	add	a3,a3,a4
    800060ec:	4585                	li	a1,1
    800060ee:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060f0:	6394                	ld	a3,0(a5)
    800060f2:	96ba                	add	a3,a3,a4
    800060f4:	4509                	li	a0,2
    800060f6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800060fa:	6394                	ld	a3,0(a5)
    800060fc:	9736                	add	a4,a4,a3
    800060fe:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006102:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006106:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000610a:	6794                	ld	a3,8(a5)
    8000610c:	0026d703          	lhu	a4,2(a3)
    80006110:	8b1d                	andi	a4,a4,7
    80006112:	2709                	addiw	a4,a4,2
    80006114:	0706                	slli	a4,a4,0x1
    80006116:	9736                	add	a4,a4,a3
    80006118:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000611c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006120:	6798                	ld	a4,8(a5)
    80006122:	00275783          	lhu	a5,2(a4)
    80006126:	2785                	addiw	a5,a5,1
    80006128:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000612c:	100017b7          	lui	a5,0x10001
    80006130:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006134:	00492703          	lw	a4,4(s2)
    80006138:	4785                	li	a5,1
    8000613a:	02f71163          	bne	a4,a5,8000615c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000613e:	0001f997          	auipc	s3,0x1f
    80006142:	f6a98993          	addi	s3,s3,-150 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006146:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006148:	85ce                	mv	a1,s3
    8000614a:	854a                	mv	a0,s2
    8000614c:	ffffc097          	auipc	ra,0xffffc
    80006150:	19e080e7          	jalr	414(ra) # 800022ea <sleep>
  while(b->disk == 1) {
    80006154:	00492783          	lw	a5,4(s2)
    80006158:	fe9788e3          	beq	a5,s1,80006148 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000615c:	f9042483          	lw	s1,-112(s0)
    80006160:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006164:	00479713          	slli	a4,a5,0x4
    80006168:	0001d797          	auipc	a5,0x1d
    8000616c:	e9878793          	addi	a5,a5,-360 # 80023000 <disk>
    80006170:	97ba                	add	a5,a5,a4
    80006172:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006176:	0001f917          	auipc	s2,0x1f
    8000617a:	e8a90913          	addi	s2,s2,-374 # 80025000 <disk+0x2000>
    free_desc(i);
    8000617e:	8526                	mv	a0,s1
    80006180:	00000097          	auipc	ra,0x0
    80006184:	bf6080e7          	jalr	-1034(ra) # 80005d76 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006188:	0492                	slli	s1,s1,0x4
    8000618a:	00093783          	ld	a5,0(s2)
    8000618e:	94be                	add	s1,s1,a5
    80006190:	00c4d783          	lhu	a5,12(s1)
    80006194:	8b85                	andi	a5,a5,1
    80006196:	cf89                	beqz	a5,800061b0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006198:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000619c:	b7cd                	j	8000617e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000619e:	0001f797          	auipc	a5,0x1f
    800061a2:	e627b783          	ld	a5,-414(a5) # 80025000 <disk+0x2000>
    800061a6:	97ba                	add	a5,a5,a4
    800061a8:	4689                	li	a3,2
    800061aa:	00d79623          	sh	a3,12(a5)
    800061ae:	b5fd                	j	8000609c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061b0:	0001f517          	auipc	a0,0x1f
    800061b4:	ef850513          	addi	a0,a0,-264 # 800250a8 <disk+0x20a8>
    800061b8:	ffffb097          	auipc	ra,0xffffb
    800061bc:	b0c080e7          	jalr	-1268(ra) # 80000cc4 <release>
}
    800061c0:	70e6                	ld	ra,120(sp)
    800061c2:	7446                	ld	s0,112(sp)
    800061c4:	74a6                	ld	s1,104(sp)
    800061c6:	7906                	ld	s2,96(sp)
    800061c8:	69e6                	ld	s3,88(sp)
    800061ca:	6a46                	ld	s4,80(sp)
    800061cc:	6aa6                	ld	s5,72(sp)
    800061ce:	6b06                	ld	s6,64(sp)
    800061d0:	7be2                	ld	s7,56(sp)
    800061d2:	7c42                	ld	s8,48(sp)
    800061d4:	7ca2                	ld	s9,40(sp)
    800061d6:	7d02                	ld	s10,32(sp)
    800061d8:	6109                	addi	sp,sp,128
    800061da:	8082                	ret
  if(write)
    800061dc:	e20d1ee3          	bnez	s10,80006018 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800061e0:	f8042023          	sw	zero,-128(s0)
    800061e4:	bd2d                	j	8000601e <virtio_disk_rw+0xe2>

00000000800061e6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061e6:	1101                	addi	sp,sp,-32
    800061e8:	ec06                	sd	ra,24(sp)
    800061ea:	e822                	sd	s0,16(sp)
    800061ec:	e426                	sd	s1,8(sp)
    800061ee:	e04a                	sd	s2,0(sp)
    800061f0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061f2:	0001f517          	auipc	a0,0x1f
    800061f6:	eb650513          	addi	a0,a0,-330 # 800250a8 <disk+0x20a8>
    800061fa:	ffffb097          	auipc	ra,0xffffb
    800061fe:	a16080e7          	jalr	-1514(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006202:	0001f717          	auipc	a4,0x1f
    80006206:	dfe70713          	addi	a4,a4,-514 # 80025000 <disk+0x2000>
    8000620a:	02075783          	lhu	a5,32(a4)
    8000620e:	6b18                	ld	a4,16(a4)
    80006210:	00275683          	lhu	a3,2(a4)
    80006214:	8ebd                	xor	a3,a3,a5
    80006216:	8a9d                	andi	a3,a3,7
    80006218:	cab9                	beqz	a3,8000626e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000621a:	0001d917          	auipc	s2,0x1d
    8000621e:	de690913          	addi	s2,s2,-538 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006222:	0001f497          	auipc	s1,0x1f
    80006226:	dde48493          	addi	s1,s1,-546 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000622a:	078e                	slli	a5,a5,0x3
    8000622c:	97ba                	add	a5,a5,a4
    8000622e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006230:	20078713          	addi	a4,a5,512
    80006234:	0712                	slli	a4,a4,0x4
    80006236:	974a                	add	a4,a4,s2
    80006238:	03074703          	lbu	a4,48(a4)
    8000623c:	ef21                	bnez	a4,80006294 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000623e:	20078793          	addi	a5,a5,512
    80006242:	0792                	slli	a5,a5,0x4
    80006244:	97ca                	add	a5,a5,s2
    80006246:	7798                	ld	a4,40(a5)
    80006248:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000624c:	7788                	ld	a0,40(a5)
    8000624e:	ffffc097          	auipc	ra,0xffffc
    80006252:	222080e7          	jalr	546(ra) # 80002470 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006256:	0204d783          	lhu	a5,32(s1)
    8000625a:	2785                	addiw	a5,a5,1
    8000625c:	8b9d                	andi	a5,a5,7
    8000625e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006262:	6898                	ld	a4,16(s1)
    80006264:	00275683          	lhu	a3,2(a4)
    80006268:	8a9d                	andi	a3,a3,7
    8000626a:	fcf690e3          	bne	a3,a5,8000622a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000626e:	10001737          	lui	a4,0x10001
    80006272:	533c                	lw	a5,96(a4)
    80006274:	8b8d                	andi	a5,a5,3
    80006276:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006278:	0001f517          	auipc	a0,0x1f
    8000627c:	e3050513          	addi	a0,a0,-464 # 800250a8 <disk+0x20a8>
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	a44080e7          	jalr	-1468(ra) # 80000cc4 <release>
}
    80006288:	60e2                	ld	ra,24(sp)
    8000628a:	6442                	ld	s0,16(sp)
    8000628c:	64a2                	ld	s1,8(sp)
    8000628e:	6902                	ld	s2,0(sp)
    80006290:	6105                	addi	sp,sp,32
    80006292:	8082                	ret
      panic("virtio_disk_intr status");
    80006294:	00002517          	auipc	a0,0x2
    80006298:	59450513          	addi	a0,a0,1428 # 80008828 <syscalls+0x3c8>
    8000629c:	ffffa097          	auipc	ra,0xffffa
    800062a0:	2ac080e7          	jalr	684(ra) # 80000548 <panic>

00000000800062a4 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    800062a4:	7179                	addi	sp,sp,-48
    800062a6:	f406                	sd	ra,40(sp)
    800062a8:	f022                	sd	s0,32(sp)
    800062aa:	ec26                	sd	s1,24(sp)
    800062ac:	e84a                	sd	s2,16(sp)
    800062ae:	e44e                	sd	s3,8(sp)
    800062b0:	e052                	sd	s4,0(sp)
    800062b2:	1800                	addi	s0,sp,48
    800062b4:	892a                	mv	s2,a0
    800062b6:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    800062b8:	00003a17          	auipc	s4,0x3
    800062bc:	d70a0a13          	addi	s4,s4,-656 # 80009028 <stats>
    800062c0:	000a2683          	lw	a3,0(s4)
    800062c4:	00002617          	auipc	a2,0x2
    800062c8:	57c60613          	addi	a2,a2,1404 # 80008840 <syscalls+0x3e0>
    800062cc:	00000097          	auipc	ra,0x0
    800062d0:	2c2080e7          	jalr	706(ra) # 8000658e <snprintf>
    800062d4:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    800062d6:	004a2683          	lw	a3,4(s4)
    800062da:	00002617          	auipc	a2,0x2
    800062de:	57660613          	addi	a2,a2,1398 # 80008850 <syscalls+0x3f0>
    800062e2:	85ce                	mv	a1,s3
    800062e4:	954a                	add	a0,a0,s2
    800062e6:	00000097          	auipc	ra,0x0
    800062ea:	2a8080e7          	jalr	680(ra) # 8000658e <snprintf>
  return n;
}
    800062ee:	9d25                	addw	a0,a0,s1
    800062f0:	70a2                	ld	ra,40(sp)
    800062f2:	7402                	ld	s0,32(sp)
    800062f4:	64e2                	ld	s1,24(sp)
    800062f6:	6942                	ld	s2,16(sp)
    800062f8:	69a2                	ld	s3,8(sp)
    800062fa:	6a02                	ld	s4,0(sp)
    800062fc:	6145                	addi	sp,sp,48
    800062fe:	8082                	ret

0000000080006300 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80006300:	7179                	addi	sp,sp,-48
    80006302:	f406                	sd	ra,40(sp)
    80006304:	f022                	sd	s0,32(sp)
    80006306:	ec26                	sd	s1,24(sp)
    80006308:	e84a                	sd	s2,16(sp)
    8000630a:	e44e                	sd	s3,8(sp)
    8000630c:	1800                	addi	s0,sp,48
    8000630e:	89ae                	mv	s3,a1
    80006310:	84b2                	mv	s1,a2
    80006312:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006314:	ffffb097          	auipc	ra,0xffffb
    80006318:	7ca080e7          	jalr	1994(ra) # 80001ade <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    8000631c:	653c                	ld	a5,72(a0)
    8000631e:	02f4ff63          	bgeu	s1,a5,8000635c <copyin_new+0x5c>
    80006322:	01248733          	add	a4,s1,s2
    80006326:	02f77d63          	bgeu	a4,a5,80006360 <copyin_new+0x60>
    8000632a:	02976d63          	bltu	a4,s1,80006364 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    8000632e:	0009061b          	sext.w	a2,s2
    80006332:	85a6                	mv	a1,s1
    80006334:	854e                	mv	a0,s3
    80006336:	ffffb097          	auipc	ra,0xffffb
    8000633a:	a36080e7          	jalr	-1482(ra) # 80000d6c <memmove>
  stats.ncopyin++;   // XXX lock
    8000633e:	00003717          	auipc	a4,0x3
    80006342:	cea70713          	addi	a4,a4,-790 # 80009028 <stats>
    80006346:	431c                	lw	a5,0(a4)
    80006348:	2785                	addiw	a5,a5,1
    8000634a:	c31c                	sw	a5,0(a4)
  return 0;
    8000634c:	4501                	li	a0,0
}
    8000634e:	70a2                	ld	ra,40(sp)
    80006350:	7402                	ld	s0,32(sp)
    80006352:	64e2                	ld	s1,24(sp)
    80006354:	6942                	ld	s2,16(sp)
    80006356:	69a2                	ld	s3,8(sp)
    80006358:	6145                	addi	sp,sp,48
    8000635a:	8082                	ret
    return -1;
    8000635c:	557d                	li	a0,-1
    8000635e:	bfc5                	j	8000634e <copyin_new+0x4e>
    80006360:	557d                	li	a0,-1
    80006362:	b7f5                	j	8000634e <copyin_new+0x4e>
    80006364:	557d                	li	a0,-1
    80006366:	b7e5                	j	8000634e <copyin_new+0x4e>

0000000080006368 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006368:	7179                	addi	sp,sp,-48
    8000636a:	f406                	sd	ra,40(sp)
    8000636c:	f022                	sd	s0,32(sp)
    8000636e:	ec26                	sd	s1,24(sp)
    80006370:	e84a                	sd	s2,16(sp)
    80006372:	e44e                	sd	s3,8(sp)
    80006374:	1800                	addi	s0,sp,48
    80006376:	89ae                	mv	s3,a1
    80006378:	8932                	mv	s2,a2
    8000637a:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    8000637c:	ffffb097          	auipc	ra,0xffffb
    80006380:	762080e7          	jalr	1890(ra) # 80001ade <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006384:	00003717          	auipc	a4,0x3
    80006388:	ca470713          	addi	a4,a4,-860 # 80009028 <stats>
    8000638c:	435c                	lw	a5,4(a4)
    8000638e:	2785                	addiw	a5,a5,1
    80006390:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006392:	cc85                	beqz	s1,800063ca <copyinstr_new+0x62>
    80006394:	00990833          	add	a6,s2,s1
    80006398:	87ca                	mv	a5,s2
    8000639a:	6538                	ld	a4,72(a0)
    8000639c:	00e7ff63          	bgeu	a5,a4,800063ba <copyinstr_new+0x52>
    dst[i] = s[i];
    800063a0:	0007c683          	lbu	a3,0(a5)
    800063a4:	41278733          	sub	a4,a5,s2
    800063a8:	974e                	add	a4,a4,s3
    800063aa:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    800063ae:	c285                	beqz	a3,800063ce <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    800063b0:	0785                	addi	a5,a5,1
    800063b2:	ff0794e3          	bne	a5,a6,8000639a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    800063b6:	557d                	li	a0,-1
    800063b8:	a011                	j	800063bc <copyinstr_new+0x54>
    800063ba:	557d                	li	a0,-1
}
    800063bc:	70a2                	ld	ra,40(sp)
    800063be:	7402                	ld	s0,32(sp)
    800063c0:	64e2                	ld	s1,24(sp)
    800063c2:	6942                	ld	s2,16(sp)
    800063c4:	69a2                	ld	s3,8(sp)
    800063c6:	6145                	addi	sp,sp,48
    800063c8:	8082                	ret
  return -1;
    800063ca:	557d                	li	a0,-1
    800063cc:	bfc5                	j	800063bc <copyinstr_new+0x54>
      return 0;
    800063ce:	4501                	li	a0,0
    800063d0:	b7f5                	j	800063bc <copyinstr_new+0x54>

00000000800063d2 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800063d2:	1141                	addi	sp,sp,-16
    800063d4:	e422                	sd	s0,8(sp)
    800063d6:	0800                	addi	s0,sp,16
  return -1;
}
    800063d8:	557d                	li	a0,-1
    800063da:	6422                	ld	s0,8(sp)
    800063dc:	0141                	addi	sp,sp,16
    800063de:	8082                	ret

00000000800063e0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800063e0:	7179                	addi	sp,sp,-48
    800063e2:	f406                	sd	ra,40(sp)
    800063e4:	f022                	sd	s0,32(sp)
    800063e6:	ec26                	sd	s1,24(sp)
    800063e8:	e84a                	sd	s2,16(sp)
    800063ea:	e44e                	sd	s3,8(sp)
    800063ec:	e052                	sd	s4,0(sp)
    800063ee:	1800                	addi	s0,sp,48
    800063f0:	892a                	mv	s2,a0
    800063f2:	89ae                	mv	s3,a1
    800063f4:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800063f6:	00020517          	auipc	a0,0x20
    800063fa:	c0a50513          	addi	a0,a0,-1014 # 80026000 <stats>
    800063fe:	ffffb097          	auipc	ra,0xffffb
    80006402:	812080e7          	jalr	-2030(ra) # 80000c10 <acquire>

  if(stats.sz == 0) {
    80006406:	00021797          	auipc	a5,0x21
    8000640a:	c127a783          	lw	a5,-1006(a5) # 80027018 <stats+0x1018>
    8000640e:	cbb5                	beqz	a5,80006482 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006410:	00021797          	auipc	a5,0x21
    80006414:	bf078793          	addi	a5,a5,-1040 # 80027000 <stats+0x1000>
    80006418:	4fd8                	lw	a4,28(a5)
    8000641a:	4f9c                	lw	a5,24(a5)
    8000641c:	9f99                	subw	a5,a5,a4
    8000641e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006422:	06d05e63          	blez	a3,8000649e <statsread+0xbe>
    if(m > n)
    80006426:	8a3e                	mv	s4,a5
    80006428:	00d4d363          	bge	s1,a3,8000642e <statsread+0x4e>
    8000642c:	8a26                	mv	s4,s1
    8000642e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006432:	86a6                	mv	a3,s1
    80006434:	00020617          	auipc	a2,0x20
    80006438:	be460613          	addi	a2,a2,-1052 # 80026018 <stats+0x18>
    8000643c:	963a                	add	a2,a2,a4
    8000643e:	85ce                	mv	a1,s3
    80006440:	854a                	mv	a0,s2
    80006442:	ffffc097          	auipc	ra,0xffffc
    80006446:	10a080e7          	jalr	266(ra) # 8000254c <either_copyout>
    8000644a:	57fd                	li	a5,-1
    8000644c:	00f50a63          	beq	a0,a5,80006460 <statsread+0x80>
      stats.off += m;
    80006450:	00021717          	auipc	a4,0x21
    80006454:	bb070713          	addi	a4,a4,-1104 # 80027000 <stats+0x1000>
    80006458:	4f5c                	lw	a5,28(a4)
    8000645a:	014787bb          	addw	a5,a5,s4
    8000645e:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006460:	00020517          	auipc	a0,0x20
    80006464:	ba050513          	addi	a0,a0,-1120 # 80026000 <stats>
    80006468:	ffffb097          	auipc	ra,0xffffb
    8000646c:	85c080e7          	jalr	-1956(ra) # 80000cc4 <release>
  return m;
}
    80006470:	8526                	mv	a0,s1
    80006472:	70a2                	ld	ra,40(sp)
    80006474:	7402                	ld	s0,32(sp)
    80006476:	64e2                	ld	s1,24(sp)
    80006478:	6942                	ld	s2,16(sp)
    8000647a:	69a2                	ld	s3,8(sp)
    8000647c:	6a02                	ld	s4,0(sp)
    8000647e:	6145                	addi	sp,sp,48
    80006480:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006482:	6585                	lui	a1,0x1
    80006484:	00020517          	auipc	a0,0x20
    80006488:	b9450513          	addi	a0,a0,-1132 # 80026018 <stats+0x18>
    8000648c:	00000097          	auipc	ra,0x0
    80006490:	e18080e7          	jalr	-488(ra) # 800062a4 <statscopyin>
    80006494:	00021797          	auipc	a5,0x21
    80006498:	b8a7a223          	sw	a0,-1148(a5) # 80027018 <stats+0x1018>
    8000649c:	bf95                	j	80006410 <statsread+0x30>
    stats.sz = 0;
    8000649e:	00021797          	auipc	a5,0x21
    800064a2:	b6278793          	addi	a5,a5,-1182 # 80027000 <stats+0x1000>
    800064a6:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    800064aa:	0007ae23          	sw	zero,28(a5)
    m = -1;
    800064ae:	54fd                	li	s1,-1
    800064b0:	bf45                	j	80006460 <statsread+0x80>

00000000800064b2 <statsinit>:

void
statsinit(void)
{
    800064b2:	1141                	addi	sp,sp,-16
    800064b4:	e406                	sd	ra,8(sp)
    800064b6:	e022                	sd	s0,0(sp)
    800064b8:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    800064ba:	00002597          	auipc	a1,0x2
    800064be:	3a658593          	addi	a1,a1,934 # 80008860 <syscalls+0x400>
    800064c2:	00020517          	auipc	a0,0x20
    800064c6:	b3e50513          	addi	a0,a0,-1218 # 80026000 <stats>
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	6b6080e7          	jalr	1718(ra) # 80000b80 <initlock>

  devsw[STATS].read = statsread;
    800064d2:	0001b797          	auipc	a5,0x1b
    800064d6:	4de78793          	addi	a5,a5,1246 # 800219b0 <devsw>
    800064da:	00000717          	auipc	a4,0x0
    800064de:	f0670713          	addi	a4,a4,-250 # 800063e0 <statsread>
    800064e2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800064e4:	00000717          	auipc	a4,0x0
    800064e8:	eee70713          	addi	a4,a4,-274 # 800063d2 <statswrite>
    800064ec:	f798                	sd	a4,40(a5)
}
    800064ee:	60a2                	ld	ra,8(sp)
    800064f0:	6402                	ld	s0,0(sp)
    800064f2:	0141                	addi	sp,sp,16
    800064f4:	8082                	ret

00000000800064f6 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800064f6:	1101                	addi	sp,sp,-32
    800064f8:	ec22                	sd	s0,24(sp)
    800064fa:	1000                	addi	s0,sp,32
    800064fc:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800064fe:	c299                	beqz	a3,80006504 <sprintint+0xe>
    80006500:	0805c163          	bltz	a1,80006582 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006504:	2581                	sext.w	a1,a1
    80006506:	4301                	li	t1,0

  i = 0;
    80006508:	fe040713          	addi	a4,s0,-32
    8000650c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000650e:	2601                	sext.w	a2,a2
    80006510:	00002697          	auipc	a3,0x2
    80006514:	35868693          	addi	a3,a3,856 # 80008868 <digits>
    80006518:	88aa                	mv	a7,a0
    8000651a:	2505                	addiw	a0,a0,1
    8000651c:	02c5f7bb          	remuw	a5,a1,a2
    80006520:	1782                	slli	a5,a5,0x20
    80006522:	9381                	srli	a5,a5,0x20
    80006524:	97b6                	add	a5,a5,a3
    80006526:	0007c783          	lbu	a5,0(a5)
    8000652a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000652e:	0005879b          	sext.w	a5,a1
    80006532:	02c5d5bb          	divuw	a1,a1,a2
    80006536:	0705                	addi	a4,a4,1
    80006538:	fec7f0e3          	bgeu	a5,a2,80006518 <sprintint+0x22>

  if(sign)
    8000653c:	00030b63          	beqz	t1,80006552 <sprintint+0x5c>
    buf[i++] = '-';
    80006540:	ff040793          	addi	a5,s0,-16
    80006544:	97aa                	add	a5,a5,a0
    80006546:	02d00713          	li	a4,45
    8000654a:	fee78823          	sb	a4,-16(a5)
    8000654e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006552:	02a05c63          	blez	a0,8000658a <sprintint+0x94>
    80006556:	fe040793          	addi	a5,s0,-32
    8000655a:	00a78733          	add	a4,a5,a0
    8000655e:	87c2                	mv	a5,a6
    80006560:	0805                	addi	a6,a6,1
    80006562:	fff5061b          	addiw	a2,a0,-1
    80006566:	1602                	slli	a2,a2,0x20
    80006568:	9201                	srli	a2,a2,0x20
    8000656a:	9642                	add	a2,a2,a6
  *s = c;
    8000656c:	fff74683          	lbu	a3,-1(a4)
    80006570:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006574:	177d                	addi	a4,a4,-1
    80006576:	0785                	addi	a5,a5,1
    80006578:	fec79ae3          	bne	a5,a2,8000656c <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000657c:	6462                	ld	s0,24(sp)
    8000657e:	6105                	addi	sp,sp,32
    80006580:	8082                	ret
    x = -xx;
    80006582:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006586:	4305                	li	t1,1
    x = -xx;
    80006588:	b741                	j	80006508 <sprintint+0x12>
  while(--i >= 0)
    8000658a:	4501                	li	a0,0
    8000658c:	bfc5                	j	8000657c <sprintint+0x86>

000000008000658e <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000658e:	7171                	addi	sp,sp,-176
    80006590:	fc86                	sd	ra,120(sp)
    80006592:	f8a2                	sd	s0,112(sp)
    80006594:	f4a6                	sd	s1,104(sp)
    80006596:	f0ca                	sd	s2,96(sp)
    80006598:	ecce                	sd	s3,88(sp)
    8000659a:	e8d2                	sd	s4,80(sp)
    8000659c:	e4d6                	sd	s5,72(sp)
    8000659e:	e0da                	sd	s6,64(sp)
    800065a0:	fc5e                	sd	s7,56(sp)
    800065a2:	f862                	sd	s8,48(sp)
    800065a4:	f466                	sd	s9,40(sp)
    800065a6:	f06a                	sd	s10,32(sp)
    800065a8:	ec6e                	sd	s11,24(sp)
    800065aa:	0100                	addi	s0,sp,128
    800065ac:	e414                	sd	a3,8(s0)
    800065ae:	e818                	sd	a4,16(s0)
    800065b0:	ec1c                	sd	a5,24(s0)
    800065b2:	03043023          	sd	a6,32(s0)
    800065b6:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    800065ba:	ca0d                	beqz	a2,800065ec <snprintf+0x5e>
    800065bc:	8baa                	mv	s7,a0
    800065be:	89ae                	mv	s3,a1
    800065c0:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    800065c2:	00840793          	addi	a5,s0,8
    800065c6:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    800065ca:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800065cc:	4901                	li	s2,0
    800065ce:	02b05763          	blez	a1,800065fc <snprintf+0x6e>
    if(c != '%'){
    800065d2:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800065d6:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800065da:	02800d93          	li	s11,40
  *s = c;
    800065de:	02500d13          	li	s10,37
    switch(c){
    800065e2:	07800c93          	li	s9,120
    800065e6:	06400c13          	li	s8,100
    800065ea:	a01d                	j	80006610 <snprintf+0x82>
    panic("null fmt");
    800065ec:	00002517          	auipc	a0,0x2
    800065f0:	a3c50513          	addi	a0,a0,-1476 # 80008028 <etext+0x28>
    800065f4:	ffffa097          	auipc	ra,0xffffa
    800065f8:	f54080e7          	jalr	-172(ra) # 80000548 <panic>
  int off = 0;
    800065fc:	4481                	li	s1,0
    800065fe:	a86d                	j	800066b8 <snprintf+0x12a>
  *s = c;
    80006600:	009b8733          	add	a4,s7,s1
    80006604:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006608:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000660a:	2905                	addiw	s2,s2,1
    8000660c:	0b34d663          	bge	s1,s3,800066b8 <snprintf+0x12a>
    80006610:	012a07b3          	add	a5,s4,s2
    80006614:	0007c783          	lbu	a5,0(a5)
    80006618:	0007871b          	sext.w	a4,a5
    8000661c:	cfd1                	beqz	a5,800066b8 <snprintf+0x12a>
    if(c != '%'){
    8000661e:	ff5711e3          	bne	a4,s5,80006600 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006622:	2905                	addiw	s2,s2,1
    80006624:	012a07b3          	add	a5,s4,s2
    80006628:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    8000662c:	c7d1                	beqz	a5,800066b8 <snprintf+0x12a>
    switch(c){
    8000662e:	05678c63          	beq	a5,s6,80006686 <snprintf+0xf8>
    80006632:	02fb6763          	bltu	s6,a5,80006660 <snprintf+0xd2>
    80006636:	0b578763          	beq	a5,s5,800066e4 <snprintf+0x156>
    8000663a:	0b879b63          	bne	a5,s8,800066f0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000663e:	f8843783          	ld	a5,-120(s0)
    80006642:	00878713          	addi	a4,a5,8
    80006646:	f8e43423          	sd	a4,-120(s0)
    8000664a:	4685                	li	a3,1
    8000664c:	4629                	li	a2,10
    8000664e:	438c                	lw	a1,0(a5)
    80006650:	009b8533          	add	a0,s7,s1
    80006654:	00000097          	auipc	ra,0x0
    80006658:	ea2080e7          	jalr	-350(ra) # 800064f6 <sprintint>
    8000665c:	9ca9                	addw	s1,s1,a0
      break;
    8000665e:	b775                	j	8000660a <snprintf+0x7c>
    switch(c){
    80006660:	09979863          	bne	a5,s9,800066f0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006664:	f8843783          	ld	a5,-120(s0)
    80006668:	00878713          	addi	a4,a5,8
    8000666c:	f8e43423          	sd	a4,-120(s0)
    80006670:	4685                	li	a3,1
    80006672:	4641                	li	a2,16
    80006674:	438c                	lw	a1,0(a5)
    80006676:	009b8533          	add	a0,s7,s1
    8000667a:	00000097          	auipc	ra,0x0
    8000667e:	e7c080e7          	jalr	-388(ra) # 800064f6 <sprintint>
    80006682:	9ca9                	addw	s1,s1,a0
      break;
    80006684:	b759                	j	8000660a <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006686:	f8843783          	ld	a5,-120(s0)
    8000668a:	00878713          	addi	a4,a5,8
    8000668e:	f8e43423          	sd	a4,-120(s0)
    80006692:	639c                	ld	a5,0(a5)
    80006694:	c3b1                	beqz	a5,800066d8 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006696:	0007c703          	lbu	a4,0(a5)
    8000669a:	db25                	beqz	a4,8000660a <snprintf+0x7c>
    8000669c:	0134de63          	bge	s1,s3,800066b8 <snprintf+0x12a>
    800066a0:	009b86b3          	add	a3,s7,s1
  *s = c;
    800066a4:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    800066a8:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    800066aa:	0785                	addi	a5,a5,1
    800066ac:	0007c703          	lbu	a4,0(a5)
    800066b0:	df29                	beqz	a4,8000660a <snprintf+0x7c>
    800066b2:	0685                	addi	a3,a3,1
    800066b4:	fe9998e3          	bne	s3,s1,800066a4 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    800066b8:	8526                	mv	a0,s1
    800066ba:	70e6                	ld	ra,120(sp)
    800066bc:	7446                	ld	s0,112(sp)
    800066be:	74a6                	ld	s1,104(sp)
    800066c0:	7906                	ld	s2,96(sp)
    800066c2:	69e6                	ld	s3,88(sp)
    800066c4:	6a46                	ld	s4,80(sp)
    800066c6:	6aa6                	ld	s5,72(sp)
    800066c8:	6b06                	ld	s6,64(sp)
    800066ca:	7be2                	ld	s7,56(sp)
    800066cc:	7c42                	ld	s8,48(sp)
    800066ce:	7ca2                	ld	s9,40(sp)
    800066d0:	7d02                	ld	s10,32(sp)
    800066d2:	6de2                	ld	s11,24(sp)
    800066d4:	614d                	addi	sp,sp,176
    800066d6:	8082                	ret
        s = "(null)";
    800066d8:	00002797          	auipc	a5,0x2
    800066dc:	94878793          	addi	a5,a5,-1720 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    800066e0:	876e                	mv	a4,s11
    800066e2:	bf6d                	j	8000669c <snprintf+0x10e>
  *s = c;
    800066e4:	009b87b3          	add	a5,s7,s1
    800066e8:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    800066ec:	2485                	addiw	s1,s1,1
      break;
    800066ee:	bf31                	j	8000660a <snprintf+0x7c>
  *s = c;
    800066f0:	009b8733          	add	a4,s7,s1
    800066f4:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    800066f8:	0014871b          	addiw	a4,s1,1
  *s = c;
    800066fc:	975e                	add	a4,a4,s7
    800066fe:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006702:	2489                	addiw	s1,s1,2
      break;
    80006704:	b719                	j	8000660a <snprintf+0x7c>
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
