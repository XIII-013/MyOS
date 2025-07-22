struct buf {
  int valid;   // has data been read from disk?
  int disk;    // does disk "own" buf?
  uint dev;    // 设备号
  uint blockno; // 磁盘块号
  struct sleeplock lock;
  // 引用计数，如果为0代表该缓冲区是空闲状态
  // 跟踪当前有多少进程正在使用缓冲区
  uint refcnt;    
  // struct buf *prev; // LRU cache list
  struct buf *next;
  uchar data[BSIZE]; // 实际数据

  uint lastuse; // 使用时间戳来表示最近使用时间
};

