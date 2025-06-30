
user/_find：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <fmtname>:

char goal[DIRSIZ+1];

char*
fmtname(char *path)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
   e:	84aa                	mv	s1,a0
  static char buf[DIRSIZ+1];
  char *p;

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
  10:	00000097          	auipc	ra,0x0
  14:	2e4080e7          	jalr	740(ra) # 2f4 <strlen>
  18:	02051793          	slli	a5,a0,0x20
  1c:	9381                	srli	a5,a5,0x20
  1e:	97a6                	add	a5,a5,s1
  20:	02f00693          	li	a3,47
  24:	0097e963          	bltu	a5,s1,36 <fmtname+0x36>
  28:	0007c703          	lbu	a4,0(a5)
  2c:	00d70563          	beq	a4,a3,36 <fmtname+0x36>
  30:	17fd                	addi	a5,a5,-1
  32:	fe97fbe3          	bgeu	a5,s1,28 <fmtname+0x28>
    ;
  p++;
  36:	00178493          	addi	s1,a5,1

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
  3a:	8526                	mv	a0,s1
  3c:	00000097          	auipc	ra,0x0
  40:	2b8080e7          	jalr	696(ra) # 2f4 <strlen>
  44:	2501                	sext.w	a0,a0
  46:	47b5                	li	a5,13
  48:	00a7fa63          	bgeu	a5,a0,5c <fmtname+0x5c>
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  return buf;
}
  4c:	8526                	mv	a0,s1
  4e:	70a2                	ld	ra,40(sp)
  50:	7402                	ld	s0,32(sp)
  52:	64e2                	ld	s1,24(sp)
  54:	6942                	ld	s2,16(sp)
  56:	69a2                	ld	s3,8(sp)
  58:	6145                	addi	sp,sp,48
  5a:	8082                	ret
  memmove(buf, p, strlen(p));
  5c:	8526                	mv	a0,s1
  5e:	00000097          	auipc	ra,0x0
  62:	296080e7          	jalr	662(ra) # 2f4 <strlen>
  66:	00001997          	auipc	s3,0x1
  6a:	a6298993          	addi	s3,s3,-1438 # ac8 <buf.1108>
  6e:	0005061b          	sext.w	a2,a0
  72:	85a6                	mv	a1,s1
  74:	854e                	mv	a0,s3
  76:	00000097          	auipc	ra,0x0
  7a:	3f6080e7          	jalr	1014(ra) # 46c <memmove>
  memset(buf+strlen(p), ' ', DIRSIZ-strlen(p));
  7e:	8526                	mv	a0,s1
  80:	00000097          	auipc	ra,0x0
  84:	274080e7          	jalr	628(ra) # 2f4 <strlen>
  88:	0005091b          	sext.w	s2,a0
  8c:	8526                	mv	a0,s1
  8e:	00000097          	auipc	ra,0x0
  92:	266080e7          	jalr	614(ra) # 2f4 <strlen>
  96:	1902                	slli	s2,s2,0x20
  98:	02095913          	srli	s2,s2,0x20
  9c:	4639                	li	a2,14
  9e:	9e09                	subw	a2,a2,a0
  a0:	02000593          	li	a1,32
  a4:	01298533          	add	a0,s3,s2
  a8:	00000097          	auipc	ra,0x0
  ac:	276080e7          	jalr	630(ra) # 31e <memset>
  return buf;
  b0:	84ce                	mv	s1,s3
  b2:	bf69                	j	4c <fmtname+0x4c>

00000000000000b4 <find>:

void
find(char *path)
{
  b4:	da010113          	addi	sp,sp,-608
  b8:	24113c23          	sd	ra,600(sp)
  bc:	24813823          	sd	s0,592(sp)
  c0:	24913423          	sd	s1,584(sp)
  c4:	25213023          	sd	s2,576(sp)
  c8:	23313c23          	sd	s3,568(sp)
  cc:	23413823          	sd	s4,560(sp)
  d0:	1480                	addi	s0,sp,608
  d2:	892a                	mv	s2,a0
  char buf[512], *p;
  int fd;
  struct dirent de;
  struct stat st;

  if((fd = open(path, 0)) < 0){
  d4:	4581                	li	a1,0
  d6:	00000097          	auipc	ra,0x0
  da:	48c080e7          	jalr	1164(ra) # 562 <open>
  de:	06054763          	bltz	a0,14c <find+0x98>
  e2:	84aa                	mv	s1,a0
    fprintf(2, "find: cannot open %s\n", path);
    return;
  }

  if(fstat(fd, &st) < 0){
  e4:	da840593          	addi	a1,s0,-600
  e8:	00000097          	auipc	ra,0x0
  ec:	492080e7          	jalr	1170(ra) # 57a <fstat>
  f0:	06054963          	bltz	a0,162 <find+0xae>
    fprintf(2, "find: cannot stat %s\n", path);
    close(fd);
    return;
  }

  switch(st.type){
  f4:	db041783          	lh	a5,-592(s0)
  f8:	0007869b          	sext.w	a3,a5
  fc:	4705                	li	a4,1
  fe:	0ae68063          	beq	a3,a4,19e <find+0xea>
 102:	4709                	li	a4,2
 104:	02e69063          	bne	a3,a4,124 <find+0x70>
  case T_FILE:
    // printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
    if(strcmp(fmtname(path), goal) == 0) printf("%s/%s\n", path, goal);
 108:	854a                	mv	a0,s2
 10a:	00000097          	auipc	ra,0x0
 10e:	ef6080e7          	jalr	-266(ra) # 0 <fmtname>
 112:	00001597          	auipc	a1,0x1
 116:	9c658593          	addi	a1,a1,-1594 # ad8 <goal>
 11a:	00000097          	auipc	ra,0x0
 11e:	1ae080e7          	jalr	430(ra) # 2c8 <strcmp>
 122:	c125                	beqz	a0,182 <find+0xce>
      }
    //   printf("%s %d %d %d\n", fmtname(buf), st.type, st.ino, st.size);
    }
    break;
  }
  close(fd);
 124:	8526                	mv	a0,s1
 126:	00000097          	auipc	ra,0x0
 12a:	424080e7          	jalr	1060(ra) # 54a <close>
}
 12e:	25813083          	ld	ra,600(sp)
 132:	25013403          	ld	s0,592(sp)
 136:	24813483          	ld	s1,584(sp)
 13a:	24013903          	ld	s2,576(sp)
 13e:	23813983          	ld	s3,568(sp)
 142:	23013a03          	ld	s4,560(sp)
 146:	26010113          	addi	sp,sp,608
 14a:	8082                	ret
    fprintf(2, "find: cannot open %s\n", path);
 14c:	864a                	mv	a2,s2
 14e:	00001597          	auipc	a1,0x1
 152:	8f258593          	addi	a1,a1,-1806 # a40 <malloc+0xe8>
 156:	4509                	li	a0,2
 158:	00000097          	auipc	ra,0x0
 15c:	714080e7          	jalr	1812(ra) # 86c <fprintf>
    return;
 160:	b7f9                	j	12e <find+0x7a>
    fprintf(2, "find: cannot stat %s\n", path);
 162:	864a                	mv	a2,s2
 164:	00001597          	auipc	a1,0x1
 168:	8f458593          	addi	a1,a1,-1804 # a58 <malloc+0x100>
 16c:	4509                	li	a0,2
 16e:	00000097          	auipc	ra,0x0
 172:	6fe080e7          	jalr	1790(ra) # 86c <fprintf>
    close(fd);
 176:	8526                	mv	a0,s1
 178:	00000097          	auipc	ra,0x0
 17c:	3d2080e7          	jalr	978(ra) # 54a <close>
    return;
 180:	b77d                	j	12e <find+0x7a>
    if(strcmp(fmtname(path), goal) == 0) printf("%s/%s\n", path, goal);
 182:	00001617          	auipc	a2,0x1
 186:	95660613          	addi	a2,a2,-1706 # ad8 <goal>
 18a:	85ca                	mv	a1,s2
 18c:	00001517          	auipc	a0,0x1
 190:	8e450513          	addi	a0,a0,-1820 # a70 <malloc+0x118>
 194:	00000097          	auipc	ra,0x0
 198:	706080e7          	jalr	1798(ra) # 89a <printf>
 19c:	b761                	j	124 <find+0x70>
    if(strlen(path) + 1 + DIRSIZ + 1 > sizeof buf){
 19e:	854a                	mv	a0,s2
 1a0:	00000097          	auipc	ra,0x0
 1a4:	154080e7          	jalr	340(ra) # 2f4 <strlen>
 1a8:	2541                	addiw	a0,a0,16
 1aa:	20000793          	li	a5,512
 1ae:	00a7fb63          	bgeu	a5,a0,1c4 <find+0x110>
      printf("find: path too long\n");
 1b2:	00001517          	auipc	a0,0x1
 1b6:	8c650513          	addi	a0,a0,-1850 # a78 <malloc+0x120>
 1ba:	00000097          	auipc	ra,0x0
 1be:	6e0080e7          	jalr	1760(ra) # 89a <printf>
      break;
 1c2:	b78d                	j	124 <find+0x70>
    strcpy(buf, path);
 1c4:	85ca                	mv	a1,s2
 1c6:	dd040513          	addi	a0,s0,-560
 1ca:	00000097          	auipc	ra,0x0
 1ce:	0e2080e7          	jalr	226(ra) # 2ac <strcpy>
    p = buf+strlen(buf);
 1d2:	dd040513          	addi	a0,s0,-560
 1d6:	00000097          	auipc	ra,0x0
 1da:	11e080e7          	jalr	286(ra) # 2f4 <strlen>
 1de:	02051913          	slli	s2,a0,0x20
 1e2:	02095913          	srli	s2,s2,0x20
 1e6:	dd040793          	addi	a5,s0,-560
 1ea:	993e                	add	s2,s2,a5
    *p++ = '/';
 1ec:	00190993          	addi	s3,s2,1
 1f0:	02f00793          	li	a5,47
 1f4:	00f90023          	sb	a5,0(s2)
        printf("find: cannot stat %s\n", buf);
 1f8:	00001a17          	auipc	s4,0x1
 1fc:	860a0a13          	addi	s4,s4,-1952 # a58 <malloc+0x100>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 200:	4641                	li	a2,16
 202:	dc040593          	addi	a1,s0,-576
 206:	8526                	mv	a0,s1
 208:	00000097          	auipc	ra,0x0
 20c:	332080e7          	jalr	818(ra) # 53a <read>
 210:	47c1                	li	a5,16
 212:	f0f519e3          	bne	a0,a5,124 <find+0x70>
      if(de.inum == 0)
 216:	dc045783          	lhu	a5,-576(s0)
 21a:	d3fd                	beqz	a5,200 <find+0x14c>
      memmove(p, de.name, DIRSIZ);
 21c:	4639                	li	a2,14
 21e:	dc240593          	addi	a1,s0,-574
 222:	854e                	mv	a0,s3
 224:	00000097          	auipc	ra,0x0
 228:	248080e7          	jalr	584(ra) # 46c <memmove>
      p[DIRSIZ] = 0;
 22c:	000907a3          	sb	zero,15(s2)
      if(stat(buf, &st) < 0){
 230:	da840593          	addi	a1,s0,-600
 234:	dd040513          	addi	a0,s0,-560
 238:	00000097          	auipc	ra,0x0
 23c:	1a4080e7          	jalr	420(ra) # 3dc <stat>
 240:	fc0550e3          	bgez	a0,200 <find+0x14c>
        printf("find: cannot stat %s\n", buf);
 244:	dd040593          	addi	a1,s0,-560
 248:	8552                	mv	a0,s4
 24a:	00000097          	auipc	ra,0x0
 24e:	650080e7          	jalr	1616(ra) # 89a <printf>
        continue;
 252:	b77d                	j	200 <find+0x14c>

0000000000000254 <main>:

int
main(int argc, char *argv[])
{
 254:	1101                	addi	sp,sp,-32
 256:	ec06                	sd	ra,24(sp)
 258:	e822                	sd	s0,16(sp)
 25a:	e426                	sd	s1,8(sp)
 25c:	e04a                	sd	s2,0(sp)
 25e:	1000                	addi	s0,sp,32
  if(argc != 3){
 260:	478d                	li	a5,3
 262:	00f50763          	beq	a0,a5,270 <main+0x1c>
    exit(0);
 266:	4501                	li	a0,0
 268:	00000097          	auipc	ra,0x0
 26c:	2ba080e7          	jalr	698(ra) # 522 <exit>
 270:	84ae                	mv	s1,a1
  }
  strcpy(goal, argv[2]);
 272:	00001917          	auipc	s2,0x1
 276:	86690913          	addi	s2,s2,-1946 # ad8 <goal>
 27a:	698c                	ld	a1,16(a1)
 27c:	854a                	mv	a0,s2
 27e:	00000097          	auipc	ra,0x0
 282:	02e080e7          	jalr	46(ra) # 2ac <strcpy>
  printf("\ngoal: %s\n\n",goal);
 286:	85ca                	mv	a1,s2
 288:	00001517          	auipc	a0,0x1
 28c:	80850513          	addi	a0,a0,-2040 # a90 <malloc+0x138>
 290:	00000097          	auipc	ra,0x0
 294:	60a080e7          	jalr	1546(ra) # 89a <printf>
  find(argv[1]);
 298:	6488                	ld	a0,8(s1)
 29a:	00000097          	auipc	ra,0x0
 29e:	e1a080e7          	jalr	-486(ra) # b4 <find>
  exit(0);
 2a2:	4501                	li	a0,0
 2a4:	00000097          	auipc	ra,0x0
 2a8:	27e080e7          	jalr	638(ra) # 522 <exit>

00000000000002ac <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2ac:	1141                	addi	sp,sp,-16
 2ae:	e422                	sd	s0,8(sp)
 2b0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2b2:	87aa                	mv	a5,a0
 2b4:	0585                	addi	a1,a1,1
 2b6:	0785                	addi	a5,a5,1
 2b8:	fff5c703          	lbu	a4,-1(a1)
 2bc:	fee78fa3          	sb	a4,-1(a5)
 2c0:	fb75                	bnez	a4,2b4 <strcpy+0x8>
    ;
  return os;
}
 2c2:	6422                	ld	s0,8(sp)
 2c4:	0141                	addi	sp,sp,16
 2c6:	8082                	ret

00000000000002c8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2c8:	1141                	addi	sp,sp,-16
 2ca:	e422                	sd	s0,8(sp)
 2cc:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2ce:	00054783          	lbu	a5,0(a0)
 2d2:	cb91                	beqz	a5,2e6 <strcmp+0x1e>
 2d4:	0005c703          	lbu	a4,0(a1)
 2d8:	00f71763          	bne	a4,a5,2e6 <strcmp+0x1e>
    p++, q++;
 2dc:	0505                	addi	a0,a0,1
 2de:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2e0:	00054783          	lbu	a5,0(a0)
 2e4:	fbe5                	bnez	a5,2d4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2e6:	0005c503          	lbu	a0,0(a1)
}
 2ea:	40a7853b          	subw	a0,a5,a0
 2ee:	6422                	ld	s0,8(sp)
 2f0:	0141                	addi	sp,sp,16
 2f2:	8082                	ret

00000000000002f4 <strlen>:

uint
strlen(const char *s)
{
 2f4:	1141                	addi	sp,sp,-16
 2f6:	e422                	sd	s0,8(sp)
 2f8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2fa:	00054783          	lbu	a5,0(a0)
 2fe:	cf91                	beqz	a5,31a <strlen+0x26>
 300:	0505                	addi	a0,a0,1
 302:	87aa                	mv	a5,a0
 304:	4685                	li	a3,1
 306:	9e89                	subw	a3,a3,a0
 308:	00f6853b          	addw	a0,a3,a5
 30c:	0785                	addi	a5,a5,1
 30e:	fff7c703          	lbu	a4,-1(a5)
 312:	fb7d                	bnez	a4,308 <strlen+0x14>
    ;
  return n;
}
 314:	6422                	ld	s0,8(sp)
 316:	0141                	addi	sp,sp,16
 318:	8082                	ret
  for(n = 0; s[n]; n++)
 31a:	4501                	li	a0,0
 31c:	bfe5                	j	314 <strlen+0x20>

000000000000031e <memset>:

void*
memset(void *dst, int c, uint n)
{
 31e:	1141                	addi	sp,sp,-16
 320:	e422                	sd	s0,8(sp)
 322:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 324:	ce09                	beqz	a2,33e <memset+0x20>
 326:	87aa                	mv	a5,a0
 328:	fff6071b          	addiw	a4,a2,-1
 32c:	1702                	slli	a4,a4,0x20
 32e:	9301                	srli	a4,a4,0x20
 330:	0705                	addi	a4,a4,1
 332:	972a                	add	a4,a4,a0
    cdst[i] = c;
 334:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 338:	0785                	addi	a5,a5,1
 33a:	fee79de3          	bne	a5,a4,334 <memset+0x16>
  }
  return dst;
}
 33e:	6422                	ld	s0,8(sp)
 340:	0141                	addi	sp,sp,16
 342:	8082                	ret

0000000000000344 <strchr>:

char*
strchr(const char *s, char c)
{
 344:	1141                	addi	sp,sp,-16
 346:	e422                	sd	s0,8(sp)
 348:	0800                	addi	s0,sp,16
  for(; *s; s++)
 34a:	00054783          	lbu	a5,0(a0)
 34e:	cb99                	beqz	a5,364 <strchr+0x20>
    if(*s == c)
 350:	00f58763          	beq	a1,a5,35e <strchr+0x1a>
  for(; *s; s++)
 354:	0505                	addi	a0,a0,1
 356:	00054783          	lbu	a5,0(a0)
 35a:	fbfd                	bnez	a5,350 <strchr+0xc>
      return (char*)s;
  return 0;
 35c:	4501                	li	a0,0
}
 35e:	6422                	ld	s0,8(sp)
 360:	0141                	addi	sp,sp,16
 362:	8082                	ret
  return 0;
 364:	4501                	li	a0,0
 366:	bfe5                	j	35e <strchr+0x1a>

0000000000000368 <gets>:

char*
gets(char *buf, int max)
{
 368:	711d                	addi	sp,sp,-96
 36a:	ec86                	sd	ra,88(sp)
 36c:	e8a2                	sd	s0,80(sp)
 36e:	e4a6                	sd	s1,72(sp)
 370:	e0ca                	sd	s2,64(sp)
 372:	fc4e                	sd	s3,56(sp)
 374:	f852                	sd	s4,48(sp)
 376:	f456                	sd	s5,40(sp)
 378:	f05a                	sd	s6,32(sp)
 37a:	ec5e                	sd	s7,24(sp)
 37c:	1080                	addi	s0,sp,96
 37e:	8baa                	mv	s7,a0
 380:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 382:	892a                	mv	s2,a0
 384:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 386:	4aa9                	li	s5,10
 388:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 38a:	89a6                	mv	s3,s1
 38c:	2485                	addiw	s1,s1,1
 38e:	0344d863          	bge	s1,s4,3be <gets+0x56>
    cc = read(0, &c, 1);
 392:	4605                	li	a2,1
 394:	faf40593          	addi	a1,s0,-81
 398:	4501                	li	a0,0
 39a:	00000097          	auipc	ra,0x0
 39e:	1a0080e7          	jalr	416(ra) # 53a <read>
    if(cc < 1)
 3a2:	00a05e63          	blez	a0,3be <gets+0x56>
    buf[i++] = c;
 3a6:	faf44783          	lbu	a5,-81(s0)
 3aa:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3ae:	01578763          	beq	a5,s5,3bc <gets+0x54>
 3b2:	0905                	addi	s2,s2,1
 3b4:	fd679be3          	bne	a5,s6,38a <gets+0x22>
  for(i=0; i+1 < max; ){
 3b8:	89a6                	mv	s3,s1
 3ba:	a011                	j	3be <gets+0x56>
 3bc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3be:	99de                	add	s3,s3,s7
 3c0:	00098023          	sb	zero,0(s3)
  return buf;
}
 3c4:	855e                	mv	a0,s7
 3c6:	60e6                	ld	ra,88(sp)
 3c8:	6446                	ld	s0,80(sp)
 3ca:	64a6                	ld	s1,72(sp)
 3cc:	6906                	ld	s2,64(sp)
 3ce:	79e2                	ld	s3,56(sp)
 3d0:	7a42                	ld	s4,48(sp)
 3d2:	7aa2                	ld	s5,40(sp)
 3d4:	7b02                	ld	s6,32(sp)
 3d6:	6be2                	ld	s7,24(sp)
 3d8:	6125                	addi	sp,sp,96
 3da:	8082                	ret

00000000000003dc <stat>:

int
stat(const char *n, struct stat *st)
{
 3dc:	1101                	addi	sp,sp,-32
 3de:	ec06                	sd	ra,24(sp)
 3e0:	e822                	sd	s0,16(sp)
 3e2:	e426                	sd	s1,8(sp)
 3e4:	e04a                	sd	s2,0(sp)
 3e6:	1000                	addi	s0,sp,32
 3e8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3ea:	4581                	li	a1,0
 3ec:	00000097          	auipc	ra,0x0
 3f0:	176080e7          	jalr	374(ra) # 562 <open>
  if(fd < 0)
 3f4:	02054563          	bltz	a0,41e <stat+0x42>
 3f8:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3fa:	85ca                	mv	a1,s2
 3fc:	00000097          	auipc	ra,0x0
 400:	17e080e7          	jalr	382(ra) # 57a <fstat>
 404:	892a                	mv	s2,a0
  close(fd);
 406:	8526                	mv	a0,s1
 408:	00000097          	auipc	ra,0x0
 40c:	142080e7          	jalr	322(ra) # 54a <close>
  return r;
}
 410:	854a                	mv	a0,s2
 412:	60e2                	ld	ra,24(sp)
 414:	6442                	ld	s0,16(sp)
 416:	64a2                	ld	s1,8(sp)
 418:	6902                	ld	s2,0(sp)
 41a:	6105                	addi	sp,sp,32
 41c:	8082                	ret
    return -1;
 41e:	597d                	li	s2,-1
 420:	bfc5                	j	410 <stat+0x34>

0000000000000422 <atoi>:

int
atoi(const char *s)
{
 422:	1141                	addi	sp,sp,-16
 424:	e422                	sd	s0,8(sp)
 426:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 428:	00054603          	lbu	a2,0(a0)
 42c:	fd06079b          	addiw	a5,a2,-48
 430:	0ff7f793          	andi	a5,a5,255
 434:	4725                	li	a4,9
 436:	02f76963          	bltu	a4,a5,468 <atoi+0x46>
 43a:	86aa                	mv	a3,a0
  n = 0;
 43c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 43e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 440:	0685                	addi	a3,a3,1
 442:	0025179b          	slliw	a5,a0,0x2
 446:	9fa9                	addw	a5,a5,a0
 448:	0017979b          	slliw	a5,a5,0x1
 44c:	9fb1                	addw	a5,a5,a2
 44e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 452:	0006c603          	lbu	a2,0(a3)
 456:	fd06071b          	addiw	a4,a2,-48
 45a:	0ff77713          	andi	a4,a4,255
 45e:	fee5f1e3          	bgeu	a1,a4,440 <atoi+0x1e>
  return n;
}
 462:	6422                	ld	s0,8(sp)
 464:	0141                	addi	sp,sp,16
 466:	8082                	ret
  n = 0;
 468:	4501                	li	a0,0
 46a:	bfe5                	j	462 <atoi+0x40>

000000000000046c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 46c:	1141                	addi	sp,sp,-16
 46e:	e422                	sd	s0,8(sp)
 470:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 472:	02b57663          	bgeu	a0,a1,49e <memmove+0x32>
    while(n-- > 0)
 476:	02c05163          	blez	a2,498 <memmove+0x2c>
 47a:	fff6079b          	addiw	a5,a2,-1
 47e:	1782                	slli	a5,a5,0x20
 480:	9381                	srli	a5,a5,0x20
 482:	0785                	addi	a5,a5,1
 484:	97aa                	add	a5,a5,a0
  dst = vdst;
 486:	872a                	mv	a4,a0
      *dst++ = *src++;
 488:	0585                	addi	a1,a1,1
 48a:	0705                	addi	a4,a4,1
 48c:	fff5c683          	lbu	a3,-1(a1)
 490:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 494:	fee79ae3          	bne	a5,a4,488 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 498:	6422                	ld	s0,8(sp)
 49a:	0141                	addi	sp,sp,16
 49c:	8082                	ret
    dst += n;
 49e:	00c50733          	add	a4,a0,a2
    src += n;
 4a2:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4a4:	fec05ae3          	blez	a2,498 <memmove+0x2c>
 4a8:	fff6079b          	addiw	a5,a2,-1
 4ac:	1782                	slli	a5,a5,0x20
 4ae:	9381                	srli	a5,a5,0x20
 4b0:	fff7c793          	not	a5,a5
 4b4:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4b6:	15fd                	addi	a1,a1,-1
 4b8:	177d                	addi	a4,a4,-1
 4ba:	0005c683          	lbu	a3,0(a1)
 4be:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4c2:	fee79ae3          	bne	a5,a4,4b6 <memmove+0x4a>
 4c6:	bfc9                	j	498 <memmove+0x2c>

00000000000004c8 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4c8:	1141                	addi	sp,sp,-16
 4ca:	e422                	sd	s0,8(sp)
 4cc:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4ce:	ca05                	beqz	a2,4fe <memcmp+0x36>
 4d0:	fff6069b          	addiw	a3,a2,-1
 4d4:	1682                	slli	a3,a3,0x20
 4d6:	9281                	srli	a3,a3,0x20
 4d8:	0685                	addi	a3,a3,1
 4da:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4dc:	00054783          	lbu	a5,0(a0)
 4e0:	0005c703          	lbu	a4,0(a1)
 4e4:	00e79863          	bne	a5,a4,4f4 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4e8:	0505                	addi	a0,a0,1
    p2++;
 4ea:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4ec:	fed518e3          	bne	a0,a3,4dc <memcmp+0x14>
  }
  return 0;
 4f0:	4501                	li	a0,0
 4f2:	a019                	j	4f8 <memcmp+0x30>
      return *p1 - *p2;
 4f4:	40e7853b          	subw	a0,a5,a4
}
 4f8:	6422                	ld	s0,8(sp)
 4fa:	0141                	addi	sp,sp,16
 4fc:	8082                	ret
  return 0;
 4fe:	4501                	li	a0,0
 500:	bfe5                	j	4f8 <memcmp+0x30>

0000000000000502 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 502:	1141                	addi	sp,sp,-16
 504:	e406                	sd	ra,8(sp)
 506:	e022                	sd	s0,0(sp)
 508:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 50a:	00000097          	auipc	ra,0x0
 50e:	f62080e7          	jalr	-158(ra) # 46c <memmove>
}
 512:	60a2                	ld	ra,8(sp)
 514:	6402                	ld	s0,0(sp)
 516:	0141                	addi	sp,sp,16
 518:	8082                	ret

000000000000051a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 51a:	4885                	li	a7,1
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <exit>:
.global exit
exit:
 li a7, SYS_exit
 522:	4889                	li	a7,2
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <wait>:
.global wait
wait:
 li a7, SYS_wait
 52a:	488d                	li	a7,3
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 532:	4891                	li	a7,4
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <read>:
.global read
read:
 li a7, SYS_read
 53a:	4895                	li	a7,5
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <write>:
.global write
write:
 li a7, SYS_write
 542:	48c1                	li	a7,16
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <close>:
.global close
close:
 li a7, SYS_close
 54a:	48d5                	li	a7,21
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <kill>:
.global kill
kill:
 li a7, SYS_kill
 552:	4899                	li	a7,6
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <exec>:
.global exec
exec:
 li a7, SYS_exec
 55a:	489d                	li	a7,7
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <open>:
.global open
open:
 li a7, SYS_open
 562:	48bd                	li	a7,15
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 56a:	48c5                	li	a7,17
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 572:	48c9                	li	a7,18
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 57a:	48a1                	li	a7,8
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <link>:
.global link
link:
 li a7, SYS_link
 582:	48cd                	li	a7,19
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 58a:	48d1                	li	a7,20
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 592:	48a5                	li	a7,9
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <dup>:
.global dup
dup:
 li a7, SYS_dup
 59a:	48a9                	li	a7,10
 ecall
 59c:	00000073          	ecall
 ret
 5a0:	8082                	ret

00000000000005a2 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5a2:	48ad                	li	a7,11
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5aa:	48b1                	li	a7,12
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5b2:	48b5                	li	a7,13
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5ba:	48b9                	li	a7,14
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5c2:	1101                	addi	sp,sp,-32
 5c4:	ec06                	sd	ra,24(sp)
 5c6:	e822                	sd	s0,16(sp)
 5c8:	1000                	addi	s0,sp,32
 5ca:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5ce:	4605                	li	a2,1
 5d0:	fef40593          	addi	a1,s0,-17
 5d4:	00000097          	auipc	ra,0x0
 5d8:	f6e080e7          	jalr	-146(ra) # 542 <write>
}
 5dc:	60e2                	ld	ra,24(sp)
 5de:	6442                	ld	s0,16(sp)
 5e0:	6105                	addi	sp,sp,32
 5e2:	8082                	ret

00000000000005e4 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5e4:	7139                	addi	sp,sp,-64
 5e6:	fc06                	sd	ra,56(sp)
 5e8:	f822                	sd	s0,48(sp)
 5ea:	f426                	sd	s1,40(sp)
 5ec:	f04a                	sd	s2,32(sp)
 5ee:	ec4e                	sd	s3,24(sp)
 5f0:	0080                	addi	s0,sp,64
 5f2:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5f4:	c299                	beqz	a3,5fa <printint+0x16>
 5f6:	0805c863          	bltz	a1,686 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5fa:	2581                	sext.w	a1,a1
  neg = 0;
 5fc:	4881                	li	a7,0
 5fe:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 602:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 604:	2601                	sext.w	a2,a2
 606:	00000517          	auipc	a0,0x0
 60a:	4a250513          	addi	a0,a0,1186 # aa8 <digits>
 60e:	883a                	mv	a6,a4
 610:	2705                	addiw	a4,a4,1
 612:	02c5f7bb          	remuw	a5,a1,a2
 616:	1782                	slli	a5,a5,0x20
 618:	9381                	srli	a5,a5,0x20
 61a:	97aa                	add	a5,a5,a0
 61c:	0007c783          	lbu	a5,0(a5)
 620:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 624:	0005879b          	sext.w	a5,a1
 628:	02c5d5bb          	divuw	a1,a1,a2
 62c:	0685                	addi	a3,a3,1
 62e:	fec7f0e3          	bgeu	a5,a2,60e <printint+0x2a>
  if(neg)
 632:	00088b63          	beqz	a7,648 <printint+0x64>
    buf[i++] = '-';
 636:	fd040793          	addi	a5,s0,-48
 63a:	973e                	add	a4,a4,a5
 63c:	02d00793          	li	a5,45
 640:	fef70823          	sb	a5,-16(a4)
 644:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 648:	02e05863          	blez	a4,678 <printint+0x94>
 64c:	fc040793          	addi	a5,s0,-64
 650:	00e78933          	add	s2,a5,a4
 654:	fff78993          	addi	s3,a5,-1
 658:	99ba                	add	s3,s3,a4
 65a:	377d                	addiw	a4,a4,-1
 65c:	1702                	slli	a4,a4,0x20
 65e:	9301                	srli	a4,a4,0x20
 660:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 664:	fff94583          	lbu	a1,-1(s2)
 668:	8526                	mv	a0,s1
 66a:	00000097          	auipc	ra,0x0
 66e:	f58080e7          	jalr	-168(ra) # 5c2 <putc>
  while(--i >= 0)
 672:	197d                	addi	s2,s2,-1
 674:	ff3918e3          	bne	s2,s3,664 <printint+0x80>
}
 678:	70e2                	ld	ra,56(sp)
 67a:	7442                	ld	s0,48(sp)
 67c:	74a2                	ld	s1,40(sp)
 67e:	7902                	ld	s2,32(sp)
 680:	69e2                	ld	s3,24(sp)
 682:	6121                	addi	sp,sp,64
 684:	8082                	ret
    x = -xx;
 686:	40b005bb          	negw	a1,a1
    neg = 1;
 68a:	4885                	li	a7,1
    x = -xx;
 68c:	bf8d                	j	5fe <printint+0x1a>

000000000000068e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 68e:	7119                	addi	sp,sp,-128
 690:	fc86                	sd	ra,120(sp)
 692:	f8a2                	sd	s0,112(sp)
 694:	f4a6                	sd	s1,104(sp)
 696:	f0ca                	sd	s2,96(sp)
 698:	ecce                	sd	s3,88(sp)
 69a:	e8d2                	sd	s4,80(sp)
 69c:	e4d6                	sd	s5,72(sp)
 69e:	e0da                	sd	s6,64(sp)
 6a0:	fc5e                	sd	s7,56(sp)
 6a2:	f862                	sd	s8,48(sp)
 6a4:	f466                	sd	s9,40(sp)
 6a6:	f06a                	sd	s10,32(sp)
 6a8:	ec6e                	sd	s11,24(sp)
 6aa:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6ac:	0005c903          	lbu	s2,0(a1)
 6b0:	18090f63          	beqz	s2,84e <vprintf+0x1c0>
 6b4:	8aaa                	mv	s5,a0
 6b6:	8b32                	mv	s6,a2
 6b8:	00158493          	addi	s1,a1,1
  state = 0;
 6bc:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6be:	02500a13          	li	s4,37
      if(c == 'd'){
 6c2:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6c6:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6ca:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6ce:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6d2:	00000b97          	auipc	s7,0x0
 6d6:	3d6b8b93          	addi	s7,s7,982 # aa8 <digits>
 6da:	a839                	j	6f8 <vprintf+0x6a>
        putc(fd, c);
 6dc:	85ca                	mv	a1,s2
 6de:	8556                	mv	a0,s5
 6e0:	00000097          	auipc	ra,0x0
 6e4:	ee2080e7          	jalr	-286(ra) # 5c2 <putc>
 6e8:	a019                	j	6ee <vprintf+0x60>
    } else if(state == '%'){
 6ea:	01498f63          	beq	s3,s4,708 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6ee:	0485                	addi	s1,s1,1
 6f0:	fff4c903          	lbu	s2,-1(s1)
 6f4:	14090d63          	beqz	s2,84e <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6f8:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6fc:	fe0997e3          	bnez	s3,6ea <vprintf+0x5c>
      if(c == '%'){
 700:	fd479ee3          	bne	a5,s4,6dc <vprintf+0x4e>
        state = '%';
 704:	89be                	mv	s3,a5
 706:	b7e5                	j	6ee <vprintf+0x60>
      if(c == 'd'){
 708:	05878063          	beq	a5,s8,748 <vprintf+0xba>
      } else if(c == 'l') {
 70c:	05978c63          	beq	a5,s9,764 <vprintf+0xd6>
      } else if(c == 'x') {
 710:	07a78863          	beq	a5,s10,780 <vprintf+0xf2>
      } else if(c == 'p') {
 714:	09b78463          	beq	a5,s11,79c <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 718:	07300713          	li	a4,115
 71c:	0ce78663          	beq	a5,a4,7e8 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 720:	06300713          	li	a4,99
 724:	0ee78e63          	beq	a5,a4,820 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 728:	11478863          	beq	a5,s4,838 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 72c:	85d2                	mv	a1,s4
 72e:	8556                	mv	a0,s5
 730:	00000097          	auipc	ra,0x0
 734:	e92080e7          	jalr	-366(ra) # 5c2 <putc>
        putc(fd, c);
 738:	85ca                	mv	a1,s2
 73a:	8556                	mv	a0,s5
 73c:	00000097          	auipc	ra,0x0
 740:	e86080e7          	jalr	-378(ra) # 5c2 <putc>
      }
      state = 0;
 744:	4981                	li	s3,0
 746:	b765                	j	6ee <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 748:	008b0913          	addi	s2,s6,8
 74c:	4685                	li	a3,1
 74e:	4629                	li	a2,10
 750:	000b2583          	lw	a1,0(s6)
 754:	8556                	mv	a0,s5
 756:	00000097          	auipc	ra,0x0
 75a:	e8e080e7          	jalr	-370(ra) # 5e4 <printint>
 75e:	8b4a                	mv	s6,s2
      state = 0;
 760:	4981                	li	s3,0
 762:	b771                	j	6ee <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 764:	008b0913          	addi	s2,s6,8
 768:	4681                	li	a3,0
 76a:	4629                	li	a2,10
 76c:	000b2583          	lw	a1,0(s6)
 770:	8556                	mv	a0,s5
 772:	00000097          	auipc	ra,0x0
 776:	e72080e7          	jalr	-398(ra) # 5e4 <printint>
 77a:	8b4a                	mv	s6,s2
      state = 0;
 77c:	4981                	li	s3,0
 77e:	bf85                	j	6ee <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 780:	008b0913          	addi	s2,s6,8
 784:	4681                	li	a3,0
 786:	4641                	li	a2,16
 788:	000b2583          	lw	a1,0(s6)
 78c:	8556                	mv	a0,s5
 78e:	00000097          	auipc	ra,0x0
 792:	e56080e7          	jalr	-426(ra) # 5e4 <printint>
 796:	8b4a                	mv	s6,s2
      state = 0;
 798:	4981                	li	s3,0
 79a:	bf91                	j	6ee <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 79c:	008b0793          	addi	a5,s6,8
 7a0:	f8f43423          	sd	a5,-120(s0)
 7a4:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7a8:	03000593          	li	a1,48
 7ac:	8556                	mv	a0,s5
 7ae:	00000097          	auipc	ra,0x0
 7b2:	e14080e7          	jalr	-492(ra) # 5c2 <putc>
  putc(fd, 'x');
 7b6:	85ea                	mv	a1,s10
 7b8:	8556                	mv	a0,s5
 7ba:	00000097          	auipc	ra,0x0
 7be:	e08080e7          	jalr	-504(ra) # 5c2 <putc>
 7c2:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7c4:	03c9d793          	srli	a5,s3,0x3c
 7c8:	97de                	add	a5,a5,s7
 7ca:	0007c583          	lbu	a1,0(a5)
 7ce:	8556                	mv	a0,s5
 7d0:	00000097          	auipc	ra,0x0
 7d4:	df2080e7          	jalr	-526(ra) # 5c2 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7d8:	0992                	slli	s3,s3,0x4
 7da:	397d                	addiw	s2,s2,-1
 7dc:	fe0914e3          	bnez	s2,7c4 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7e0:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7e4:	4981                	li	s3,0
 7e6:	b721                	j	6ee <vprintf+0x60>
        s = va_arg(ap, char*);
 7e8:	008b0993          	addi	s3,s6,8
 7ec:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7f0:	02090163          	beqz	s2,812 <vprintf+0x184>
        while(*s != 0){
 7f4:	00094583          	lbu	a1,0(s2)
 7f8:	c9a1                	beqz	a1,848 <vprintf+0x1ba>
          putc(fd, *s);
 7fa:	8556                	mv	a0,s5
 7fc:	00000097          	auipc	ra,0x0
 800:	dc6080e7          	jalr	-570(ra) # 5c2 <putc>
          s++;
 804:	0905                	addi	s2,s2,1
        while(*s != 0){
 806:	00094583          	lbu	a1,0(s2)
 80a:	f9e5                	bnez	a1,7fa <vprintf+0x16c>
        s = va_arg(ap, char*);
 80c:	8b4e                	mv	s6,s3
      state = 0;
 80e:	4981                	li	s3,0
 810:	bdf9                	j	6ee <vprintf+0x60>
          s = "(null)";
 812:	00000917          	auipc	s2,0x0
 816:	28e90913          	addi	s2,s2,654 # aa0 <malloc+0x148>
        while(*s != 0){
 81a:	02800593          	li	a1,40
 81e:	bff1                	j	7fa <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 820:	008b0913          	addi	s2,s6,8
 824:	000b4583          	lbu	a1,0(s6)
 828:	8556                	mv	a0,s5
 82a:	00000097          	auipc	ra,0x0
 82e:	d98080e7          	jalr	-616(ra) # 5c2 <putc>
 832:	8b4a                	mv	s6,s2
      state = 0;
 834:	4981                	li	s3,0
 836:	bd65                	j	6ee <vprintf+0x60>
        putc(fd, c);
 838:	85d2                	mv	a1,s4
 83a:	8556                	mv	a0,s5
 83c:	00000097          	auipc	ra,0x0
 840:	d86080e7          	jalr	-634(ra) # 5c2 <putc>
      state = 0;
 844:	4981                	li	s3,0
 846:	b565                	j	6ee <vprintf+0x60>
        s = va_arg(ap, char*);
 848:	8b4e                	mv	s6,s3
      state = 0;
 84a:	4981                	li	s3,0
 84c:	b54d                	j	6ee <vprintf+0x60>
    }
  }
}
 84e:	70e6                	ld	ra,120(sp)
 850:	7446                	ld	s0,112(sp)
 852:	74a6                	ld	s1,104(sp)
 854:	7906                	ld	s2,96(sp)
 856:	69e6                	ld	s3,88(sp)
 858:	6a46                	ld	s4,80(sp)
 85a:	6aa6                	ld	s5,72(sp)
 85c:	6b06                	ld	s6,64(sp)
 85e:	7be2                	ld	s7,56(sp)
 860:	7c42                	ld	s8,48(sp)
 862:	7ca2                	ld	s9,40(sp)
 864:	7d02                	ld	s10,32(sp)
 866:	6de2                	ld	s11,24(sp)
 868:	6109                	addi	sp,sp,128
 86a:	8082                	ret

000000000000086c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 86c:	715d                	addi	sp,sp,-80
 86e:	ec06                	sd	ra,24(sp)
 870:	e822                	sd	s0,16(sp)
 872:	1000                	addi	s0,sp,32
 874:	e010                	sd	a2,0(s0)
 876:	e414                	sd	a3,8(s0)
 878:	e818                	sd	a4,16(s0)
 87a:	ec1c                	sd	a5,24(s0)
 87c:	03043023          	sd	a6,32(s0)
 880:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 884:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 888:	8622                	mv	a2,s0
 88a:	00000097          	auipc	ra,0x0
 88e:	e04080e7          	jalr	-508(ra) # 68e <vprintf>
}
 892:	60e2                	ld	ra,24(sp)
 894:	6442                	ld	s0,16(sp)
 896:	6161                	addi	sp,sp,80
 898:	8082                	ret

000000000000089a <printf>:

void
printf(const char *fmt, ...)
{
 89a:	711d                	addi	sp,sp,-96
 89c:	ec06                	sd	ra,24(sp)
 89e:	e822                	sd	s0,16(sp)
 8a0:	1000                	addi	s0,sp,32
 8a2:	e40c                	sd	a1,8(s0)
 8a4:	e810                	sd	a2,16(s0)
 8a6:	ec14                	sd	a3,24(s0)
 8a8:	f018                	sd	a4,32(s0)
 8aa:	f41c                	sd	a5,40(s0)
 8ac:	03043823          	sd	a6,48(s0)
 8b0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8b4:	00840613          	addi	a2,s0,8
 8b8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8bc:	85aa                	mv	a1,a0
 8be:	4505                	li	a0,1
 8c0:	00000097          	auipc	ra,0x0
 8c4:	dce080e7          	jalr	-562(ra) # 68e <vprintf>
}
 8c8:	60e2                	ld	ra,24(sp)
 8ca:	6442                	ld	s0,16(sp)
 8cc:	6125                	addi	sp,sp,96
 8ce:	8082                	ret

00000000000008d0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8d0:	1141                	addi	sp,sp,-16
 8d2:	e422                	sd	s0,8(sp)
 8d4:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8d6:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8da:	00000797          	auipc	a5,0x0
 8de:	1e67b783          	ld	a5,486(a5) # ac0 <freep>
 8e2:	a805                	j	912 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8e4:	4618                	lw	a4,8(a2)
 8e6:	9db9                	addw	a1,a1,a4
 8e8:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8ec:	6398                	ld	a4,0(a5)
 8ee:	6318                	ld	a4,0(a4)
 8f0:	fee53823          	sd	a4,-16(a0)
 8f4:	a091                	j	938 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8f6:	ff852703          	lw	a4,-8(a0)
 8fa:	9e39                	addw	a2,a2,a4
 8fc:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8fe:	ff053703          	ld	a4,-16(a0)
 902:	e398                	sd	a4,0(a5)
 904:	a099                	j	94a <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 906:	6398                	ld	a4,0(a5)
 908:	00e7e463          	bltu	a5,a4,910 <free+0x40>
 90c:	00e6ea63          	bltu	a3,a4,920 <free+0x50>
{
 910:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 912:	fed7fae3          	bgeu	a5,a3,906 <free+0x36>
 916:	6398                	ld	a4,0(a5)
 918:	00e6e463          	bltu	a3,a4,920 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 91c:	fee7eae3          	bltu	a5,a4,910 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 920:	ff852583          	lw	a1,-8(a0)
 924:	6390                	ld	a2,0(a5)
 926:	02059713          	slli	a4,a1,0x20
 92a:	9301                	srli	a4,a4,0x20
 92c:	0712                	slli	a4,a4,0x4
 92e:	9736                	add	a4,a4,a3
 930:	fae60ae3          	beq	a2,a4,8e4 <free+0x14>
    bp->s.ptr = p->s.ptr;
 934:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 938:	4790                	lw	a2,8(a5)
 93a:	02061713          	slli	a4,a2,0x20
 93e:	9301                	srli	a4,a4,0x20
 940:	0712                	slli	a4,a4,0x4
 942:	973e                	add	a4,a4,a5
 944:	fae689e3          	beq	a3,a4,8f6 <free+0x26>
  } else
    p->s.ptr = bp;
 948:	e394                	sd	a3,0(a5)
  freep = p;
 94a:	00000717          	auipc	a4,0x0
 94e:	16f73b23          	sd	a5,374(a4) # ac0 <freep>
}
 952:	6422                	ld	s0,8(sp)
 954:	0141                	addi	sp,sp,16
 956:	8082                	ret

0000000000000958 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 958:	7139                	addi	sp,sp,-64
 95a:	fc06                	sd	ra,56(sp)
 95c:	f822                	sd	s0,48(sp)
 95e:	f426                	sd	s1,40(sp)
 960:	f04a                	sd	s2,32(sp)
 962:	ec4e                	sd	s3,24(sp)
 964:	e852                	sd	s4,16(sp)
 966:	e456                	sd	s5,8(sp)
 968:	e05a                	sd	s6,0(sp)
 96a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 96c:	02051493          	slli	s1,a0,0x20
 970:	9081                	srli	s1,s1,0x20
 972:	04bd                	addi	s1,s1,15
 974:	8091                	srli	s1,s1,0x4
 976:	0014899b          	addiw	s3,s1,1
 97a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 97c:	00000517          	auipc	a0,0x0
 980:	14453503          	ld	a0,324(a0) # ac0 <freep>
 984:	c515                	beqz	a0,9b0 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 986:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 988:	4798                	lw	a4,8(a5)
 98a:	02977f63          	bgeu	a4,s1,9c8 <malloc+0x70>
 98e:	8a4e                	mv	s4,s3
 990:	0009871b          	sext.w	a4,s3
 994:	6685                	lui	a3,0x1
 996:	00d77363          	bgeu	a4,a3,99c <malloc+0x44>
 99a:	6a05                	lui	s4,0x1
 99c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9a0:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9a4:	00000917          	auipc	s2,0x0
 9a8:	11c90913          	addi	s2,s2,284 # ac0 <freep>
  if(p == (char*)-1)
 9ac:	5afd                	li	s5,-1
 9ae:	a88d                	j	a20 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9b0:	00000797          	auipc	a5,0x0
 9b4:	13878793          	addi	a5,a5,312 # ae8 <base>
 9b8:	00000717          	auipc	a4,0x0
 9bc:	10f73423          	sd	a5,264(a4) # ac0 <freep>
 9c0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9c2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9c6:	b7e1                	j	98e <malloc+0x36>
      if(p->s.size == nunits)
 9c8:	02e48b63          	beq	s1,a4,9fe <malloc+0xa6>
        p->s.size -= nunits;
 9cc:	4137073b          	subw	a4,a4,s3
 9d0:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9d2:	1702                	slli	a4,a4,0x20
 9d4:	9301                	srli	a4,a4,0x20
 9d6:	0712                	slli	a4,a4,0x4
 9d8:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9da:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9de:	00000717          	auipc	a4,0x0
 9e2:	0ea73123          	sd	a0,226(a4) # ac0 <freep>
      return (void*)(p + 1);
 9e6:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9ea:	70e2                	ld	ra,56(sp)
 9ec:	7442                	ld	s0,48(sp)
 9ee:	74a2                	ld	s1,40(sp)
 9f0:	7902                	ld	s2,32(sp)
 9f2:	69e2                	ld	s3,24(sp)
 9f4:	6a42                	ld	s4,16(sp)
 9f6:	6aa2                	ld	s5,8(sp)
 9f8:	6b02                	ld	s6,0(sp)
 9fa:	6121                	addi	sp,sp,64
 9fc:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9fe:	6398                	ld	a4,0(a5)
 a00:	e118                	sd	a4,0(a0)
 a02:	bff1                	j	9de <malloc+0x86>
  hp->s.size = nu;
 a04:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a08:	0541                	addi	a0,a0,16
 a0a:	00000097          	auipc	ra,0x0
 a0e:	ec6080e7          	jalr	-314(ra) # 8d0 <free>
  return freep;
 a12:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a16:	d971                	beqz	a0,9ea <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a18:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a1a:	4798                	lw	a4,8(a5)
 a1c:	fa9776e3          	bgeu	a4,s1,9c8 <malloc+0x70>
    if(p == freep)
 a20:	00093703          	ld	a4,0(s2)
 a24:	853e                	mv	a0,a5
 a26:	fef719e3          	bne	a4,a5,a18 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a2a:	8552                	mv	a0,s4
 a2c:	00000097          	auipc	ra,0x0
 a30:	b7e080e7          	jalr	-1154(ra) # 5aa <sbrk>
  if(p == (char*)-1)
 a34:	fd5518e3          	bne	a0,s5,a04 <malloc+0xac>
        return 0;
 a38:	4501                	li	a0,0
 a3a:	bf45                	j	9ea <malloc+0x92>
