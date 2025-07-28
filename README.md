# MyOS
## Lab1熟悉开发环境
主要工作是利用常见的系统调用编写代码（sleep、pingpong、find、xargs）
### pingpong
通过管道实现父进程和子进程之间的简单通信。父进程发送一个字符给子进程，子进程接收到后再发送回给父进程，父进程接收到子进程的回复后并打印。

## Lab2系统调用
该实验主要用以熟悉系统调用的流程，了解系统调用的步骤，然后为此操作系统新增系统调用函数。

### System Call tracing 
此系统调用用以跟踪用户程序的系统调用，并将调用的相关信息打印出来，具体实现如下：
- 在进程结构体中添加一个变量用以记录需要跟踪的系统调用的编号，每一个系统调用都对应着一个系统调用编号。
- 通过trace系统调用（本实验实现的）传入需要监控的系统调用。
- 在内核函数syscall中加入判断逻辑，如果此时进程的系统调用号是监控调用号，则打印进程号，系统调用函数名，系统调用号

### sysinfo 用来获取空闲的内存、已创建的进程数量
这个系统调用的功能是将当前空闲内存的数量和已创建的进程数量存储至当前进程的某个虚拟地址空间，进程的虚拟空间是用户态，而系统调用属于内核态，因此需要使用xv6实现的函数copyout将内核态数据复制到用户态
- 通过遍历kmem.freelist查看链表的节点数量即可知道当前空闲的内存有哪些。
- 遍历proc[NPROC]数组查看进程状态p->state不为unused的即为已创建的进程，统计数量。
- 将上面两步的计算结果保存在xv6预定义的结构体sysinfo info中
- 使用copyout(myproc()->pagetable, dstaddr, (char*)info, sizeof(info))将内核空间结构体info的内容复制到用户态地址空间dstaddr中。

## Lab3 页表
xv6基于Sv39 RISC-V运行，它只使用64位虚拟地址的低39位，虚拟地址的前27位用于索引页表，xv6是三级页表，寻址过程使用walk函数实现，页表在逻辑上视作由$2^{27}$个页表条目(PTE)组成的数组，数组存着44位的物理页码(PPN)。

地址转换过程为：使用虚拟地址的前27位在页表中查找对应的PTE，然后根据PTE中的PPN的44位物理地址页表与12位的偏移量（1页4KB，长度为$2^{12}$字节）组成一个56位的物理地址。由于一个页表是4KB，一个PTE保存的值是8字节即页表可以看成数组
$$uint64\,pagetable[PTE] = PPN$$
所以一个页表能保存的数组长度为512个（4*1024/8 = 512），因此只能存9位的PTE，因此需要三级页表才能表示27位的索引，前两级页表的PPN是下一级页表的物理地址，最后一级页表的PPN表示的才是最终物理地址页表。walk函数的工作流程如下图所示。

![](./images/walk_logic.png)

### print a page table
需要模拟查询页表的过程，对三级页表进行遍历并打印，模仿下列函数打印即可：

    void freewalk(pagetable_t pagetable)
    {
        // there are 2^9 = 512 PTEs in a page table.
        for(int i = 0; i < 512; i++){
            pte_t pte = pagetable[i];
            if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
                // this PTE points to a lower-level page table.
                uint64 child = PTE2PA(pte);
                freewalk((pagetable_t)child);
                pagetable[i] = 0;
            } else if(pte & PTE_V){
                panic("freewalk: leaf");
            }
        }
        kfree((void*)pagetable);
    }
`(pte & PTE_V)`表示这个页表项被写入数据了，是有效的页表项。而`pte & (PTE_R|PTE_W|PTE_X)`表示这个页表项的内容是虚拟地址对应物理地址还是下一级页表的物理地址（1为前者，0为后者）

### A kernel page table per process
原本的xv6操作系统中每个进程是共用一个内核页表的。如果出现一个恶意进程篡改了内核页表的数据，那么其他进程运行程序的时候都会受影响，如果每个进程进入内核态之后都能有自己独立的内核页表，可以避免上述问题的发生

- 处理这个问题首先得在内核结构体中添加新的成员`kernel_pagetable`用以保存内核态的页表，内核进程需要依赖内核页表的一些固定映射才能正常工作，例如UART控制、硬盘界面、中断控制等等，
