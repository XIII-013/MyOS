# 实验3细节梳理
## main函数流程
    // 内存管理子系统初始化
    kinit();         // physical page allocator
    kvminit();       // create kernel page table
    kvminithart();   // turn on paging

    // 进程管理基础初始化
    procinit();      // process table

    // 中断和异常处理初始化
    trapinit();      // trap vectors
    trapinithart();  // install kernel trap vector
    plicinit();      // set up interrupt controller
    plicinithart();  // ask PLIC for device interrupts

    // 文件系统基础初始化
    binit();         // buffer cache
    iinit();         // inode cache
    fileinit();      // file table
    virtio_disk_init(); // emulated hard disk
kinit(): 初始化锁(`initlock`)和空闲页链表(`freerange`)
### **内核空间初始化**
### kvminit 逻辑
创建并初始化一个只映射内核空间”的页表，用于内核在启用分页机制（satp）后能继续正常运行

    void kvminit()
    {
        kernel_pagetable = (pagetable_t) kalloc();
        memset(kernel_pagetable, 0, PGSIZE);

        // uart registers
        kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);

        // virtio mmio disk interface
        kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

        // CLINT
        kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);

        // PLIC
        kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);

        // map kernel text executable and read-only.
        kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

        // map kernel data and the physical RAM we'll make use of.
        kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

        // map the trampoline for trap entry/exit to
        // the highest virtual address in the kernel.
        kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    }
其中里面涉及一个函数`kvmmap`，这个函数的作用是将一段物理内存映射到内核页表中，接收四个参数（映射的虚拟地址，映射的物理地址，要映射的大小，权限）。内核的页表是恒等映射，va==pa。

kvminit建立了初始内核页表，映射了uart0(串口设备地址)，VIRTIO0(虚拟磁盘设备地址)，KERNBASE(内核所有代码与数据)，TRAMPOLINE(蹦床页)等

### kvminithart
    void kvminithart()
    {
        w_satp(MAKE_SATP(kernel_pagetable));
        sfence_vma();
    }
    static inline void w_satp(uint64 x)
    {
        asm volatile("csrw satp, %0" : : "r" (x));
        // %0指的是占位符
    }
这部分代码涉及内联汇编，首先内联汇编格式如下：

    asm [volatile] ( 
        "汇编指令" 
        : 输出操作数 
        : 输入操作数 
        : 破坏列表
    );
kvminithart()函数的作用就是启动分页机制，而前面的内核的恒等映射并不会使之冲突，好处是在启用分页机制前后，内核代码可以继续执行而无需任何地址转换的调整

    // flush the TLB.
    static inline void
    sfence_vma()
    {
        // the zero, zero means flush all TLB entries.
        asm volatile("sfence.vma zero, zero");
    }
kvminithart执行sfence指令刷新TLB，确保新建立的页表映射对所有CPU核心立即可见
### procinit
操作系统内核初始化过程中用于初始化进程管理数据结构，主要做了：为每个进程初始化锁、预先分配一个内核栈。操作完毕之后再使用kvminithart刷新TLB

    // initialize the proc table at boot time.
    void
    procinit(void)
    {
        struct proc *p;
        
        initlock(&pid_lock, "nextpid");
        for(p = proc; p < &proc[NPROC]; p++) {
            initlock(&p->lock, "proc");

            // Allocate a page for the process's kernel stack.
            // Map it high in memory, followed by an invalid
            // guard page.
            char *pa = kalloc();
            if(pa == 0)
                panic("kalloc");
            uint64 va = KSTACK((int) (p - proc));
            kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
            p->kstack = va;
        }
        kvminithart();
    }
### trapinit & trapinithart
    void
    trapinit(void)
    {
        initlock(&tickslock, "time");
    }
只初始化保护时钟计数器 (ticks) 的自旋锁

    void
    trapinithart(void)
    {
        w_stvec((uint64)kernelvec);
    }
设置 stvec 寄存器（Supervisor Trap Vector），指定所有陷阱（包括时钟中断）的处理入口为 kernelvec（在 kernel/kernelvec.S 中）
### plicinit & plicinithart
    void
    plicinit(void)
    {
        // set desired IRQ priorities non-zero (otherwise disabled).
        *(uint32*)(PLIC + UART0_IRQ*4) = 1;
        *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    }
xv6中对RISC-V平台级别中断控制器（platform-level interrupt controller）进行初始化，启用了串口中断和虚拟磁盘中断

    void
    plicinithart(void)
    {
        int hart = cpuid();
        
        // set uart's enable bit for this hart's S-mode. 
        *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);

        // set this hart's S-mode priority threshold to 0.
        *(uint32*)PLIC_SPRIORITY(hart) = 0;
    }
总的来说，plicinithart用于针对每个CPU核心单独配置PLIC的函数，首先plicinithart获取当前执行CPU的核心，PLIC_SENABLE代表当前核心的PLIC中断使能寄存器地址。PLIC_SPRIORITY代表当前核心的优先级阈值寄存器地址，将该寄存器设置为0代表接受优先级>0的中断

**plicinit告诉中断控制器，串口和虚拟磁盘这两个设备可以产生中断；plicinithart将CPU设置为只接受串口和磁盘的中断信号**
### 文件系统
    void
    binit(void)
    {
        struct buf *b;

        initlock(&bcache.lock, "bcache");

        // Create linked list of buffers
        bcache.head.prev = &bcache.head;
        bcache.head.next = &bcache.head;
        for(b = bcache.buf; b < bcache.buf+NBUF; b++){
            b->next = bcache.head.next;
            b->prev = &bcache.head;
            initsleeplock(&b->lock, "buffer");
            bcache.head.next->prev = b;
            bcache.head.next = b;
        }
    }
初始化磁盘缓冲区的函数，准备了一个全局磁盘块缓存机制buf[NBUF]，构建了LRU链表（双向链表），为全局缓存和每个缓冲区初始化锁

    struct {
        struct spinlock lock;
        struct inode inode[NINODE];
    } icache;
    void
    iinit()
    {
        int i = 0;
        initlock(&icache.lock, "icache");
        for(i = 0; i < NINODE; i++) {
            initsleeplock(&icache.inode[i].lock, "inode");
        }
    }
为整个inode缓存系统初始化一个全局自旋锁，以保护对inode缓存结构的并发访问。其次初始化每个inode的睡眠锁

    struct {
        struct spinlock lock;
        struct file file[NFILE];
    } ftable;

    void
    fileinit(void)
    {
        initlock(&ftable.lock, "ftable");
    }
ftable是xv6中全局文件表的数据结构，里面包含一个固定大小的文件结构体数组，作为系统中所有打开文件的中央存储池，通过索引管理所有进程打开的文件实例。

fileinit函数逻辑只是初始化ftable的自旋锁
### **设置第一个用户进程**
    // Set up first user process.
    void
    userinit(void)
    {
        struct proc *p;

        // 分配进程结构体
        p = allocproc();
        initproc = p;
        
        // allocate one user page and copy init's instructions
        // and data into it.
        // 初始化用户地址空间
        // uvminit将i你听从的拷贝到用户内存的第一页，init是编译时嵌入的汇编程序
        uvminit(p->pagetable, initcode, sizeof(initcode));
        p->sz = PGSIZE;

        // prepare for the very first "return" from kernel to user.
        p->trapframe->epc = 0;      // user program counter
        p->trapframe->sp = PGSIZE;  // user stack pointer

        safestrcpy(p->name, "initcode", sizeof(p->name));
        p->cwd = namei("/");

        p->state = RUNNABLE;

        release(&p->lock);
    }
xv6创建第一个用户进程，是内核态过渡到用户态的关键步骤，后续执行流程是当调度器首次选择该进程运行时：
1. 通过`usertrapret`切换到用户态
2. 从`epc=0`开始执行initcode中的指令
3. `initcode`调用`exec("/init")`加载真正的用户程序
4. 系统进入正常的用户态运行环境
**`init`是用户态的第一个程序**
之所以创建这个进程是为了要启动用户环境，内核自身无法直接运行用户程序，因此**需要一个种子进程作为所有用户进程的祖先**，后续所有进程都通过`fork()`从这个进程进行派生。创建的这个进程就是**1号进程**
### 调度器逻辑
    void scheduler(void)
    {
        struct proc *p;
        struct cpu *c = mycpu();
        
        c->proc = 0;
        for(;;){
            // Avoid deadlock by ensuring that devices can interrupt.
            intr_on();
            
            int found = 0;
            for(p = proc; p < &proc[NPROC]; p++) {
                acquire(&p->lock);
                if(p->state == RUNNABLE) {
                    // Switch to chosen process.  It is the process's job
                    // to release its lock and then reacquire it
                    // before jumping back to us.
                    p->state = RUNNING;
                    c->proc = p;
                    swtch(&c->context, &p->context);

                    // Process is done running for now.
                    // It should have changed its p->state before coming back.
                    c->proc = 0;

                    found = 1;
                }
                release(&p->lock);
            }
    #if !defined (LAB_FS)
            if(found == 0) {
            intr_on();
            asm volatile("wfi");
            }
    #else
            ;
    #endif
        }
    }
这个是xv6的核心调度函数，运行在每个CPU核心上，负责选择并切换运行用户进程。调度器的内部是一个**无限循环**。
1. 调度器扫描进程寻找RUNNABLE的进程，通过swtch进行上下文切换
2. c->proc记录当前CPU运行的进程，切换回来后清零表示返回到调度器
3. 如果`found == 0`表示无进程可以运行，那么开启中断(`intr_on()`)，执行wfi
