# 实验3细节梳理
## main函数流程
    kinit();         // physical page allocator
    kvminit();       // create kernel page table
    kvminithart();   // turn on paging
    procinit();      // process table
    trapinit();      // trap vectors
    trapinithart();  // install kernel trap vector
    plicinit();      // set up interrupt controller
    plicinithart();  // ask PLIC for device interrupts
    binit();         // buffer cache
    iinit();         // inode cache
    fileinit();      // file table
    virtio_disk_init(); // emulated hard disk
kinit(): 初始化锁(`initlock`)和空闲页链表(`freerange`)

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
### procinit

## vm.c
