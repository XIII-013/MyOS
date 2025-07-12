# Lab4笔记
## RISC-V寄存器概述
1. stvec：内核在这里写入trap处理程序的地址
2. sepc：trap发生时，RISC-V保存程序的pc值
3. scause：RISC-V放置一个描述trap原因的数字
4. sscratch：保存当前用户进程trapframe结构体的用户虚拟地址
5. sstatus：里面有一位SIE用于标识能否接收中断

## trap发生后计算机的工作流程（硬件部分）
1. 清除SIE禁用中断
2. 将pc复制到sepc
3. 将当前模式（用户模式，管理模式）保存在sstatus的SPP位
4. 设置scause记录产生trap的原因
5. 将模式设置为管理模式
6. 将stvec的值复制到pc上
7. 在新的pc上开始执行

**CPU不会切换到内核页表，不会切换到内核栈，也不会保存除pc以外的任何寄存器**

## 软件处理流程
### **trap入口`uservec`（保存在stvec中）**
1. 保存用户寄存器并切换到内核执行环境
2. 保存所有用户寄存器到trapframe，并加载内核环境（**恢复内核栈指针，内核页表**）
3. 跳转至usertrap
### **陷阱分发`usertrap`**
主要作用是根据scause判断陷阱类型，并调用对应的处理函数

1. 保存sepc至trapframe->epc，防止嵌套trap修改返回地址
2. 将stvec寄存器存的函数改为kernelvec(当前在内核态，对应处理trap的函数也不同)
3. 通过scause寄存器的值判断是什么原因触发了trap（系统调用[调用syscall]，设备中断[调用devintr]，异常[kill进程]）
4. 调用usertrapret()返回用户态

### syscall()
根据系统调用号执行对应的内核函数
1. 从trapframe->a7读取系统调用号
2. 通过系统调用表跳转到对应函数
3. 将返回值存入trapframe->a0

### devintr()
处理设备中断，定时器中断
1. 定时器中断：调用yield()函数。**yield函数的作用是让当前进程主动放弃CPU，触发一次进程调度。**
2. 设备中断：代码中暂时没实现

### **usertrapret() & userret()返回用户态**
### usertrapret()
1. 关闭中断，防止竞争
2. 设置stvec重新指向uservec（usertrap函数内部改成kerneltrap，需要切换回来）
3. trapframe->epc存入sepc寄存器中，为后续sret指令将sepc的值赋值给pc恢复到trap发生的指令位置做准备。
4. 设置userret()函数的传参，第一个参数(存放至a0寄存器)是trapframe地址，第二个参数(存放至a1寄存器)是用户页表
5. 调用userret()

### userret()
1. 切换页表为用户页表(csrw satp, a1)
2. 将trapframe事先保存的寄存器值重新写入寄存器
3. 将trapframe的地址从a0写入sscratch寄存器
4. 调用sret指令，返回trap发生时候的pc处