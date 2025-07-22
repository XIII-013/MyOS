// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"

// 定义散列桶
#define NBUFMAP_BUCKET 13
#define BUFMAP_HASH(dev, blockno) ((((dev) << 27) | (blockno)) % NBUFMAP_BUCKET)


struct {
  // struct spinlock lock;
  struct buf buf[NBUF]; // 固定大小的缓冲区数组，用于缓存磁盘块的数据

  // Linked list of all buffers, through prev/next.
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  // struct buf head;

  struct spinlock eviction_lock;    // 驱逐时候使用的全局锁

  // hash table
  struct buf bufmap[NBUFMAP_BUCKET];  // 散列桶
  struct spinlock bufmap_locks[NBUFMAP_BUCKET]; // 散列桶的锁
  
} bcache;

void
binit(void)
{
  // struct buf *b;

  // initlock(&bcache.lock, "bcache");

  // Create linked list of buffers
  // bcache.head.prev = &bcache.head;
  // bcache.head.next = &bcache.head;
  // for(b = bcache.buf; b < bcache.buf+NBUF; b++){
  //   b->next = bcache.head.next;
  //   b->prev = &bcache.head;
  //   initsleeplock(&b->lock, "buffer");
  //   bcache.head.next->prev = b;
  //   bcache.head.next = b;
  // }

  // 初始化桶锁和散列桶
  for(int i = 0;i < NBUFMAP_BUCKET;i++) {
    initlock(&bcache.bufmap_locks[i], "bufmap");
    bcache.bufmap[i].next = 0;
  }

  // 遍历bcache的所有缓冲区块
  for(int i = 0;i < NBUF;i++) {
    // 初始化bcache的缓冲区块
    struct buf *b = &bcache.buf[i];
    initsleeplock(&b->lock, "buf");
    b->lastuse = 0;
    b->refcnt = 0;

    // 将所有缓冲区块放入0号散列桶
    b->next = bcache.bufmap[0].next;
    bcache.bufmap[0].next = b;
  }

  // 初始化驱逐锁
  initlock(&bcache.eviction_lock, "eviction");

}

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;

  // acquire(&bcache.lock);
  uint key = BUFMAP_HASH(dev, blockno);

  // 获取对应散列桶的锁
  acquire(&bcache.bufmap_locks[key]);

  // Is the block already cached?
  for(b = bcache.bufmap[key].next; b != 0; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      b->refcnt++;
      release(&bcache.bufmap_locks[key]);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // Not cached.
  // Recycle the least recently used (LRU) unused buffer.
  // for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
  //   if(b->refcnt == 0) {
  //     b->dev = dev;
  //     b->blockno = blockno;
  //     b->valid = 0;
  //     b->refcnt = 1;
  //     release(&bcache.lock);
  //     acquiresleep(&b->lock);
  //     return b;
  //   }
  // }
  

  // 释放桶锁并加上驱逐锁，准备按照LRU算法获取最近未使用的页
  release(&bcache.bufmap_locks[key]);
  acquire(&bcache.eviction_lock);

  // 再次进行检查key桶内部有无指定磁盘块缓存
  //（释放锁之后获取驱逐锁之间有可能更新）
  for(b = bcache.bufmap[key].next; b != 0; b = b->next){
    if(b->dev == dev && b->blockno == blockno){
      acquire(&bcache.bufmap_locks[key]);
      b->refcnt++;
      release(&bcache.bufmap_locks[key]);
      release(&bcache.eviction_lock);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // 仍然没有找到，只能按照LRU进行驱逐
  uint holding_bucket = -1; // 记录当前持有桶锁号
  struct buf *evict_buf = 0; // 待驱逐的buf

  // 遍历桶
  for(int i = 0;i < NBUFMAP_BUCKET;i++) {
    if(i == key) continue;
    acquire(&bcache.bufmap_locks[i]);

    int found = 0;// 代表在该桶找到最近更久未使用的页
    for(b = &bcache.bufmap[i]; b->next != 0; b = b->next){
      if(b->next->refcnt == 0 && (!evict_buf || b->next->lastuse < evict_buf->next->lastuse)) {
        found = 1;
        evict_buf = b;
      }
    }

    // 如果没找到则释放i号锁
    if(!found) 
      release(&bcache.bufmap_locks[i]);
    else {
      if(holding_bucket != -1) release(&bcache.bufmap_locks[holding_bucket]);
      holding_bucket = i;
    }

  } 

  // 如果没找到可用的缓存区块，则报panic
  if(!evict_buf) panic("bget: no buffers");

  b = evict_buf->next;

  // 完成驱逐操作(从链表上提出该缓冲区块)
  evict_buf->next = b->next;
  release(&bcache.bufmap_locks[holding_bucket]);

  // 将新的缓冲区块添加至key桶
  acquire(&bcache.bufmap_locks[key]);
  b->next = bcache.bufmap[key].next;
  bcache.bufmap[key].next = b;
 

  b->dev = dev;
  b->blockno = blockno;
  b->refcnt = 1;
  b->valid = 0;

  // 释放锁
  release(&bcache.bufmap_locks[key]);
  release(&bcache.eviction_lock);
  acquiresleep(&b->lock);
  return b;

}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0); // 从磁盘读数据，0代表读操作
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1); // 将缓冲区数据写回磁盘，1代表写操作
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);

  uint key = BUFMAP_HASH(b->dev, b->blockno);

  acquire(&bcache.bufmap_locks[key]);
  b->refcnt--;
  if (b->refcnt == 0) {
    b->lastuse = ticks;
  }
  
  release(&bcache.bufmap_locks[key]);
}

void
bpin(struct buf *b) {
  uint key = BUFMAP_HASH(b->dev, b->blockno);
  acquire(&bcache.bufmap_locks[key]);
  b->refcnt++;
  release(&bcache.bufmap_locks[key]);
}

void
bunpin(struct buf *b) {
  uint key = BUFMAP_HASH(b->dev, b->blockno);
  acquire(&bcache.bufmap_locks[key]);
  b->refcnt--;
  release(&bcache.bufmap_locks[key]);
}


