# Lab8 笔记
**xv6实现了自旋锁和睡眠锁两种锁机制**
## 自旋锁
没有获取到锁的时候会进行while循环等待，不会阻塞归还CPU
### 代码实现
    struct spinlock {
        uint locked;       // Is the lock held?
        char *name;        // Name of lock.
        struct cpu *cpu;   // The cpu holding the lock.
    #ifdef LAB_LOCK
        int nts;
        int n;
    #endif
    };
spinlock是互斥锁，没有信号量，P操作的代码实现为acquire

    void acquire(struct spinlock *lk)
    {
        push_off(); // disable interrupts to avoid deadlock.
        if(holding(lk))
            panic("acquire");

    #ifdef LAB_LOCK // 没定义
        __sync_fetch_and_add(&(lk->n), 1);
    #endif      


        while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    #ifdef LAB_LOCK
            __sync_fetch_and_add(&(lk->nts), 1);
    #else
        ;
    #endif
        }

        __sync_synchronize(); // 让编译器不要乱序执行指令

        // Record info about lock acquisition for holding() and debugging.
        lk->cpu = mycpu();
    }
V操作的代码实现是release，具体代码如下：
    
    void release(struct spinlock *lk)
    {
        if(!holding(lk))
            panic("release");

        lk->cpu = 0;

        __sync_synchronize(); // 让编译器不要乱序执行指令

        __sync_lock_release(&lk->locked);

        pop_off();
    }
`__sync_synchronize()`是GCC提供的内置函数，用于设置一个完整的内存屏障，确保编译器不会将函数之前的代码放在函数之后执行，也不会将之后的代码放在函数之前执行。
## 睡眠锁
睡眠锁是基于自旋锁实现的，睡眠锁的特点是当锁不可用的时候会让出CPU
### 代码实现
    struct sleeplock {
        uint locked;       // Is the lock held?
        struct spinlock lk; // spinlock protecting this sleep lock
        char *name;        // Name of lock.
        int pid;           // Process holding lock
    };
睡眠锁的P操作是acquiresleep，具体代码如下：

    void acquiresleep(struct sleeplock *lk)
    {
        acquire(&lk->lk);
        while (lk->locked) {
            sleep(lk, &lk->lk);
        }
        lk->locked = 1;
        lk->pid = myproc()->pid;
        release(&lk->lk);
    }
sleeplock内部有一个互斥锁lk，为了保护锁内部保存的值不被多个进程篡改，当检测到睡眠锁上锁的时候，触发sleep进行阻塞

睡眠锁的V操作是releasesleep，具体代码如下：

    void releasesleep(struct sleeplock *lk)
    {
        acquire(&lk->lk);
        lk->locked = 0;
        lk->pid = 0;
        wakeup(lk);
        release(&lk->lk);
    }

