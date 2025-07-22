// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem[NCPU];

char* kmem_lock_name[] = {
  "kmem0",
  "kmem1",
  "kmem2",
  "kmem3",
  "kmem4",
  "kmem5",
  "kmem6",
  "kmem7",
};

void
kinit()
{
  // initlock(&kmem.lock, "kmem");
  for(int i = 0;i < NCPU;i++) 
    initlock(&kmem[i].lock, kmem_lock_name[i]);
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  push_off();

  int cpuID = cpuid();

  acquire(&kmem[cpuID].lock);
  r->next = kmem[cpuID].freelist;
  kmem[cpuID].freelist = r;
  release(&kmem[cpuID].lock);

  pop_off();
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  push_off();

  int cpuID = cpuid();

  acquire(&kmem[cpuID].lock);
  if(!kmem[cpuID].freelist) { // 当前CPU没有空闲页表
    int steal_page_num = 64; // 从其他CPU偷页表
    for(int i = 0;i < NCPU;i++) {
      if(i == cpuID) continue;

      acquire(&kmem[i].lock);

      if(!kmem[i].freelist) { // 该CPU没有空余页
        release(&kmem[i].lock);
        continue;
      }

      struct run* rr = kmem[i].freelist;
      while(rr && steal_page_num) {
        steal_page_num--;
        kmem[i].freelist = rr->next;
        rr->next = kmem[cpuID].freelist;
        kmem[cpuID].freelist = rr;
        rr = kmem[i].freelist;
      }
      
      release(&kmem[i].lock);

      if(!steal_page_num) break;
    }
  }

  r = kmem[cpuID].freelist;
  if(r)
    kmem[cpuID].freelist = r->next;
  release(&kmem[cpuID].lock);

  pop_off();

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
