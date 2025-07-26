# fs.c相关函数功能及细节
    static uint balloc(uint dev)
在指定设备dev上找到一个空闲的磁盘块，将其标记为已用

---
    static void bfree(int dev, uint b)
释放磁盘块号为b设备号的dev的磁盘块

---
    struct inode* ialloc(uint dev, short type)
指定要在设备号为dev的存储设备上进行分配inode，inode的类型为type(文件or目录)

---
    void iupdate(struct inode *ip)
将指定inode的元数据信息写回磁盘

---
    static struct inode* iget(uint dev, uint inum)
从icache中获取指定inode（设备号为dev， inode编号为inum），如果不存在则分配一个空间缓存

---
    void iput(struct inode *ip)
减少inode的引用计数，并在引用归零且无文件链接时，释放该inode及其磁盘资源

---
    static uint bmap(struct inode *ip, uint bn)
将inode的指向的数据块建立映射，bn是inode中的指向数据块数组的索引（0-268），如果还没建立映射的时候需要给inode分配数据磁盘块，返回对应物理磁盘块号

---
    void itrunc(struct inode *ip)
释放inode指向的所有数据磁盘块，将指向数据块数组的内容清空，文件大小设为0

---
    int readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
通过inode从磁盘上找到对应的数据块，然后将数据块的内容（从off开始[字节位置]，读取n个字节）读到内存空间dst，其中user_dst用于标识内存空间是否是用户空间

---
    int writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
将内存src的内容写入inode指向的磁盘块位置（通过ip和off定位）写入n个字节，user_src判断数据源是否存在在用户空间

---
    struct inode* dirlookup(struct inode *dp, char *name, uint *poff)
在目标目录inode查找指定名称name的文件，并返回对应inode，poff用于保存目录项在目录文件中的位置。

---
    int dirlink(struct inode *dp, char *name, uint inum)
在目录（dp）中创建新的目录项，将文件名name与目标inode（inode号为inum）关联

---
    static struct inode* namex(char *path, int nameiparent, char *name)
解析路径，返回目标inode（nameiparent = 0）或者父目录inode（nameiparent = 0）

---
    struct inode* namei(char *path)
namex(path, 0, name);

---
    struct inode* nameiparent(char *path, char *name)
namex(path, 1, name);

---