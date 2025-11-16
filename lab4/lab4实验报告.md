# 第四次实验报告
## 练习0
我们需要在 trap.c 中加入此前lab3时钟中断部分的代码，实际上由于本次不需要每隔一秒打印内容，所以我们在 IRQ_S_TIMER 中添加 ```clock_set_next_event(); ```这一行内容即可
## 练习一：分配并初始化一个进程控制块
我们需要完成对 struct proc_struct 结构体的初始化，具体代码如下：
```
        proc->state = PROC_UNINIT;
        proc->pid = -1;
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&proc->context, 0, sizeof(struct context));
        proc->tf = NULL;
        proc->pgdir = boot_pgdir_pa;
        proc->flags = 0;
        memset(proc->name, 0, sizeof(proc->name));
        list_init(&proc->list_link);
        list_init(&proc->hash_link);
```
将线程状态设置为未初始化状态，线程ID设为-1来表示此线程暂时还没有 pid ，只有经过 get_pid 后才可以获得真正的 id ，接着线程被CPU运行的次数 proc->runs 、内核栈的栈地址 proc->kstack 等内容全都设置为0。这里需要说明的是，对于```proc->pgdir = boot_pgdir_pa;```是将页表指针设为内核的页目录，这是因为对于内核线程，一开始就会使用内核地址空间；而对于用户进程，后面会通过 copy_mm() 替换成用户态页表，这是 uCore 的标准流程。
### 问题：proc_struct中struct context context和struct trapframe *tf成员变量含义和在本实验中的作用是？
context： 是内核态上下文，用于保存一次进程切换过程中 CPU 寄存器的内容。本实验中用于内核栈上的进程切换。
trapframe：是中断帧结构体，里面保存进程的执行状态。本实验中用于用户态陷入内核时保存全部寄存器，退出内核时恢复用户态。
## 练习2：为新创建的内核线程分配资源
我们需要完成 do_fork 函数中的处理过程，代码如下：
```
    proc = alloc_proc();
    if (!proc)
        goto fork_out;
    if (setup_kstack(proc) < 0)
        goto bad_fork_cleanup_proc;
    if (copy_mm(clone_flags, proc) < 0)
        goto bad_fork_cleanup_kstack;
    copy_thread(proc, stack, tf);
    proc->pid = get_pid();
    proc->parent = current;
    list_add(&proc_list, &proc->list_link);
    hash_proc(proc);
    wakeup_proc(proc);
    nr_process++;
    ret = proc->pid;
```
先调用 alloc_proc 为进程分配一个 PCB ，此时只有一个空白的进程框架，没有实际的上下文信息、栈、页表等内容。接着用 setup_kstack 为子进程分配内核栈，用于异常中断、系统调用时保存 trapframe 。接着
用 copy_mm 和 copy_thread 复制内存管理信息并设置执行上下文。copy_thread 的作用有两个，复制 trapframe。然后设置 PID、父进程指针，并将子进程加入链表和哈希表，用 wakeup_proc 唤醒新进程，最终增加总进程数、返回 PID。
### 问题：ucore是否做到给每个新fork的线程一个唯一的id？
在 uCore 的实现中，每个被成功 fork 出来的线程/进程都能获得一个在 当前所有存在的进程中唯一的 ID ，这个 ID 只是在现在所有存在的进程中唯一，而不是历史中所有存在过的进程中唯一。
首先 pid 由 get_pid() 统一管理，并检查是否冲突，该函数会递增 last_pid 并遍历 proc_list 来检查 ID 是否被使用。而且 uCore 的 fork 流程是串行的，不会出现并发竞争 pid，因此不会有两个并发的 do_fork() 同时调用 get_pid()。
## 练习三：编写proc_run 函数
以下是我们的代码：
```
bool intr_flag;
        local_intr_save(intr_flag);
        struct proc_struct *prev = current;
        current = proc;
        lsatp(proc->pgdir);
        switch_to(&prev->context, &proc->context);
        local_intr_restore(intr_flag);
```
在进行进程切换时，首先使用一个局部变量 intr_flag 保存中断状态，并通过 local_intr_save(intr_flag) 关闭中断以保证上下文切换过程的原子性。随后用 prev = current 记录当前正在运行的旧进程，并将 current = proc 设置为即将运行的新进程。接着调用 lsatp(proc->pgdir) 切换页表，从而让 CPU 使用新进程的地址空间布局。然后通过 switch_to(&prev->context, &proc->context) 完成上下文切换：保存旧进程寄存器并加载新进程寄存器，使 CPU 真正“跳转”到新进程的执行现场。最后使用 local_intr_restore(intr_flag) 恢复之前的中断状态，保证系统在进程切换完成后继续正常响应中断。
### 问题：在本实验的执行过程中，创建且运行了几个内核线程？
创建并运行了 2 个内核线程，分别是 idleproc 空闲进程和 initproc 初始进程
