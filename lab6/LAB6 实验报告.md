# LAB6 调度器实验报告



---

## 练习 1：理解调度器框架的实现

### 1. `sched_class` 结构体分析

本次实验中`sched_class` 是调度类，每种调度算法都会提供一个 `struct sched_class` 实例。定义如下：

```c
struct sched_class {
    const char *name;                             // 调度算法名称
    void (*init)(struct run_queue *rq);           // 运行队列初始化
    void (*enqueue)(struct run_queue *rq,
                    struct proc_struct *proc);    // 进程入队
    void (*dequeue)(struct run_queue *rq,
                    struct proc_struct *proc);    // 进程出队
    struct proc_struct *(*pick_next)(
        struct run_queue *rq);                    // 选择下一个运行进程
    void (*proc_tick)(struct run_queue *rq,
                      struct proc_struct *proc);  // 每个时钟 tick 时对当前进程的处理
};
```

#### 每个函数指针的作用与调用时机

- `name`函数
  - 用于标识调度算法类型，初始化时调用，用于打印日志，方便调试和在 `grade.sh` 中检查
- `init(rq)`函数
  - 调用时机：调度器初始化时，由 `sched_init` 调用。
  - 作用：负责初始化运行队列 `run_queue` 的内部数据结构。对于 RR 调度器：将 run_list 初始化为空链表，proc_num 置为 0
- `enqueue(rq, proc)`函数
  - 调用时机：当进程变为PROC_RUNNABLE状态且需要加入就绪队列时，由框架层调用（在 `wakeup_proc`、`schedule` 中）。
  - 作用：负责将进程插入到相应的数据结构中（RR 使用链表尾插，Stride 使用斜堆等）并维护队列元数据（如 proc_num++）。
- `dequeue(rq, proc)`函数
  - 调用时机：当一个进程被选中即将运行（`schedule` 中）、或从就绪队列移除（如退出）时调用。
  - 作用：用于从运行队列中删除该进程节点，并更新队列元数据。对于 RR通过链表删除操作完成。该函数仅在进程已被选中但尚未真正运行前调用，确保队列状态一致。
- `pick_next(rq)`函数
  - 调用时机：每次需要选择下一个将要运行的进程时调用，由 `schedule()` 调用。
  - 作用：根据具体调度算法，从就绪队列中选择“下一个要运行的进程”：
    - RR：选队头
    - Stride：选 stride 最小的那个
- `proc_tick(rq, proc)`函数
  - 调用时机：每次时钟中断（timer interrupt）时，由 `sched_class_proc_tick` 调用。
  - 作用：负责更新当前进程的时间片 `time_slice`（RR）或其他算法状态，并在需要换出 CPU 时设置 `proc->need_resched = 1`。

#### 为什么用函数指针而不是直接调用固定函数？

1. 框架代码（`sched_init` / `schedule` / `wakeup_proc`）只依赖 `sched_class` 接口，不关心具体调度算法的实现细节。新增或切换调度算法，只需提供新的 `sched_class` 实例，并在初始化时切换指针，无需修改框架逻辑。
2. 可以方便地添加多种调度类（RR、Stride、将来的 MLFQ 等），测试或比较不同策略只需切换指针。
3. 实验中可快速切换不同调度算法，对比行为差异，不需要改动大量框架代码。

------

### 2. `run_queue` 结构体分析：为什么lab6的 run_queue 需要支持两种数据结构（链表和斜堆）

lab5 引入调度框架并实现默认的 **Round-Robin (RR) 调度算法**，而 lab6 在此基础上要求实现 **Stride Scheduling** 算法

#### 为什么需要同时支持链表和斜堆？

- **兼容性**：RR 已经使用链表实现，保留 `run_list` 可以让 RR 代码非常简单。

- 性能与复杂度平衡

  - Stride 调度要频繁选择 stride 最小的进程，如果使用链表，每次 `pick_next` 需要 O(n) 扫描，低效。
  - 斜堆（skew heap）是一种自调整堆，能够在 O(log n) 时间内插入和删除最小元素，非常适合实现最小堆。
  
- 灵活性

  - 不同算法可以选择不同的底层结构：
    - RR 只关心 FIFO 顺序：用链表即可。
    - Stride 关心“最小 stride”：用斜堆更自然。
  - `run_queue` 提前预留出通用字段，使得调度算法可以复用框架，而不需要改动核心结构。
  - 链表在 RR 中高效且简单；斜堆在 Stride 中提供必要的高效优先级管理。

------

### 3. 调度器框架函数分析

关键框架函数包括：`sched_init()`、`wakeup_proc()`、`schedule()`。

#### 3.1 `sched_init()`

- 该函数用于初始化计时器链表 `timer_list`，能够选择当前使用的调度类（实验基础部分为 `default_sched_class`，Challenge 中改为 `stride_sched_class`）。
- 能够初始化全局运行队列 `rq`（设置 `max_time_slice`，调用调度类的 `init` 函数）。

- `sched_init` 不直接操作链表或斜堆，而是通过 `sched_class->init(rq)` 委托给具体算法实现。

#### 3.2 `wakeup_proc()`

**lab5 中的实现**：

```c++
void wakeup_proc(struct proc_struct *proc)
{
    // 仅修改进程状态为 RUNNABLE
    // 不进行任何入队操作（因为没有独立的就绪队列）
    if (proc->state != PROC_RUNNABLE)
    {
        proc->state = PROC_RUNNABLE;
        proc->wait_state = 0;
    }
}
```

**lab6 中的实现**：

```c++
void wakeup_proc(struct proc_struct *proc)
{
    // ...
    if (proc->state != PROC_RUNNABLE)
    {
        proc->state = PROC_RUNNABLE;
        proc->wait_state = 0;
        if (proc != current)
        {
            sched_class_enqueue(proc);   // 通过调度类入队
        }
    }
    // ...
}
```

lab6 在唤醒进程时，若进程变为就绪态且不是当前进程，则主动将其加入就绪队列。入队操作不再直接操作链表，而是通过 sched_class_enqueue()（内部调用 sched_class->enqueue(rq, proc)）委托给具体调度类完成。

- 主要职责：
  - 将睡眠或阻塞的进程设置为可运行状态 `PROC_RUNNABLE`。
  - 如果不是当前进程，则通过 `sched_class_enqueue` 把它加入运行队列。
- 与算法解耦：
  - 不关心如何插入队列（FIFO？按优先级？按 stride？），全部交给 `enqueue` 实现。

#### 3.3 `schedule()`

**lab5 中的实现**：

```c++
void schedule(void)
{
    // 直接遍历全局 proc_list 链表
    // 从当前进程位置开始，向后查找第一个 PROC_RUNNABLE 进程
    // 若找不到，则运行 idleproc
    // 无入队、出队概念，直接在 proc_list 上操作
}
```

**lab6 中的实现**：



```c++
void schedule(void)
{
    // ...
    if (current->state == PROC_RUNNABLE)
    {
        sched_class_enqueue(current);            // 当前进程仍可运行时重新入队
    }
    if ((next = sched_class_pick_next()) != NULL) // 选择下一个进程
    {
        sched_class_dequeue(next);               // 出队
    }
    if (next == NULL)
    {
        next = idleproc;
    }
    // ...
    proc_run(next);
}
```

**变化**：lab6 完全放弃了对全局 proc_list 的遍历。引入独立的就绪队列管理：当前进程若仍可运行需重新入队；选择下一个进程通过 pick_next；选中后需显式出队。所有队列操作均通过调度类函数指针完成。

- 流程说明：
  1. 清除当前进程的 `need_resched` 标志。
  2. 若当前进程仍然是 `PROC_RUNNABLE`，则重新入队。
  3. 从队列中选择下一个要运行的进程：`pick_next`。
  4. 将选中的进程从队列中删除：`dequeue`。
  5. 如果没有找到，则运行 `idleproc`。
  6. 切换进程：调用 `proc_run(next)`。
- 与算法解耦：
  - `schedule` 只调用 `sched_class_pick_next` 和 `sched_class_dequeue`，不关心具体算法如何做决策。

------

### 4. 调度器框架的使用流程

#### 4.1 调度类初始化流程

从内核启动到调度器初始化的一个典型流程：

1. **入口代码执行**：初始化内核基本环境（内存、页表、中断等）。

2. **进程子系统初始化**：`proc_init()` 创建 `idleproc` 和 `initproc`。

3. **调度器初始化**

   ：调用`sched_init()`

   - 初始化 `timer_list`。
   - 选择调度类：基础实验中为 `default_sched_class`（RR）；Challenge 中为 `stride_sched_class`。
   - 设置 `rq`，并调用 `sched_class->init(rq)`，完成运行队列的初始化。
   - 打印当前调度类名称，用于测试脚本检查。
   
4. **时钟中断初始化**：设置时钟中断，在每个 tick 时驱动调度器。

通过 `sched_class` 指针，`default_sched_class` 被绑定到整个调度框架中。

#### 4.2 完整进程调度流程

可以将调度过程概括为下列步骤：

1. **时钟中断到来**
   - 硬件触发时钟中断 → 进入 trap 处理函数 → 识别为时钟中断（`IRQ_S_TIMER`）。
   
2. **调用 `sched_class_proc_tick(current)`**
   
   - 框架层函数：
   
     ```
     void sched_class_proc_tick(struct proc_struct *proc) {
         if (proc != idleproc) {
             sched_class->proc_tick(rq, proc);
         } else {
             proc->need_resched = 1;
         }
     }
     ```
   
     
   
   - 对非 idle 进程，将具体的 tick 处理委托给当前调度类的 `proc_tick`。
   
   - 对 idle 进程，直接设置 `need_resched = 1`，迫使后续调度出 idle。
   
3. **在 `proc_tick` 中更新当前进程状态**
   - RR 中典型实现：
   
     ```
     if (proc->time_slice > 0) proc->time_slice--;
     if (proc->time_slice == 0) proc->need_resched = 1;
     ```
   
   - Stride 中同样会维护时间片，并通过 `need_resched` 通知调度器在下一次安全点触发调度。
   
4. **中断返回前的调度检查**
   - 在合适的切换点（如陷入内核或系统调用返回处），如果 `current->need_resched == 1`，调用 `schedule()`。
   
5. **`schedule()`调度流程**
   
   - 如前所述：
     - 若当前进程仍然可运行，则重新入队。
     - 通过 `pick_next` 选择下一个进程。
     - 若队列空，则运行 `idleproc`。
     - 调用 `proc_run(next) `进行上下文切换。
   
6. **`need_resched` 标志位的作用**
   - 它是“延后调度”的软中断标志，用于：
     - 在中断 / 系统调用等不可立即切换环境下，先做必要工作，再安全地调用 `schedule`。
     - 避免在任意位置随意切换，破坏内核关键路径的原子性。
   - `proc_tick` 中只是标记 `need_resched`，真正的切换由 `schedule` 在安全点触发。

#### 4.3 调度算法的切换机制

要添加一个新的调度算法（如 Stride），需要做的工作：

1. **实现一个新的 `sched_class` 实例**

   - 定义一个结构体，如：

     ```
     struct sched_class stride_sched_class = {
         .name      = "stride_scheduler",
         .init      = stride_init,
         .enqueue   = stride_enqueue,
         .dequeue   = stride_dequeue,
         .pick_next = stride_pick_next,
         .proc_tick = stride_proc_tick,
     };
     ```

   - 同时实现上述 5 个函数。

2. **在头文件中声明**

   - 在调度头文件中声明：`extern struct sched_class stride_sched_class;`

3. **在 `sched_init() `中切换调度类**

   - 将：`sched_class = &default_sched_class;`

     换成：`sched_class = &stride_sched_class;`

   - 或增加一个编译 / 运行时配置来选择不同 `sched_class`。

4. **其他框架代码无需修改**

   - `wakeup_proc`、`schedule`、`sched_class_proc_tick`等逻辑完全不需要改动。
   - 这正是这种设计易于切换调度算法的原因：算法差异通过 `sched_class`封装，对框架透明。

------

## 练习 2：Round Robin 调度算法实现

### 1. Lab5 vs Lab6 中一个函数的差异分析：`schedule()`

以 `schedule()`为例，Lab5 与 Lab6 的实现有代表性的差异：

- **Lab5 **：

  - 直接操作运行队列：
    - 当前进程如果还能运行，则直接 `list_add_tail` 回队列。
    - 从队头 `list_pop_front` 选择下一个进程。
  - 调度逻辑与队列操作紧耦合，只适用于 RR 这种队头轮转。

- **Lab6 实现特点**：

  - 完全通过`sched_class`接口调用：

    ```
    if (current->state == PROC_RUNNABLE) {
        sched_class_enqueue(current);      // 间接调用 RR_enqueue / stride_enqueue
    }
    if ((next = sched_class_pick_next()) != NULL) {
        sched_class_dequeue(next);
    }
    ```
  
  - `schedule` 不关心底层是链表还是斜堆，也不关心是 RR 还是 Stride。
  
  - 这样设计的好处是：当引入 Stride 或其他算法时，不需要修改 `schedule`，只要更换 `sched_class` 即可。

**如果不做这个改动会有什么问题？**

- 若`schedule` 仍然直接使用链表操作：

  - 就无法支持需要优先队列、堆等复杂结构的算法。
  - 每次增加新算法，都要修改 `schedule`，框架与策略强耦合，可维护性极差。
  
- 当前改动使 `schedule`成为一个与算法无关的“统一调度入口”，提高了扩展性和可维护性。

------

### 2. RR 各函数的实现思路

RR 调度类 `default_sched_class`的关键函数实现如下。

#### 2.1 `RR_init`

```
static void RR_init(struct run_queue *rq) {
    list_init(&(rq->run_list));
    rq->proc_num = 0;
}
```

- 使用空链表初始化运行队列。
- `proc_num` 清零。
- `max_time_slice` 在 `sched_init()` 中设置，这里不处理。
- 原因：
  - RR 只需要一个 FIFO 队列，双向循环链表足够。

#### 2.2 `RR_enqueue`

```
static void RR_enqueue(struct run_queue *rq, struct proc_struct *proc) {
    assert(list_empty(&(proc->run_link)));
    list_add_before(&(rq->run_list), &(proc->run_link)); // 队尾插入
    if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice) {
        proc->time_slice = rq->max_time_slice;
    }
    proc->rq = rq;
    rq->proc_num++;
}
```

- 关键点：
  - 通过 `assert(list_empty(...))` 保证进程不会重复在队列中。
  - 使用 `list_add_before(&rq->run_list, &proc->run_link)` 将新进程插入到表头前，即逻辑上的队尾，实现 FIFO。
  - 重新分配时间片：如果 `time_slice` 为空或过大，设置为 `rq->max_time_slice`。
  - 更新 `proc->rq`指针和队列进程数。
- 边界情况：
  - 空队列插入：`run_list` 本身是哨兵节点，`list_add_before` 对空队列也适用。
  - 进程已在队列中：通过 `assert` 捕获逻辑错误。

#### 2.3 `RR_dequeue`

```
static void RR_dequeue(struct run_queue *rq, struct proc_struct *proc) {
    assert(!list_empty(&(proc->run_link)) && proc->rq == rq);
    list_del_init(&(proc->run_link));
    rq->proc_num--;
}
```

- 保证该进程确实在本队列中，且 `run_link` 非空。
- 使用 `list_del_init` 删除节点并重置其指针，防止悬挂指针。
- 更新 `proc_num`。

#### 2.4 `RR_pick_next`

```
static struct proc_struct *RR_pick_next(struct run_queue *rq) {
    list_entry_t *le = list_next(&(rq->run_list));
    if (le != &(rq->run_list)) {
        return le2proc(le, run_link);
    }
    return NULL;
}
```

- 取`run_list`的下一个节点作为队头：若等于哨兵节点，说明队列为空，返回 `NULL`。

- `schedule()` 在得到 `next` 后会调用 `sched_class_dequeue(next)` 将其出队。

#### 2.5 `RR_proc_tick`

```
static void RR_proc_tick(struct run_queue *rq, struct proc_struct *proc) {
    if (proc->time_slice > 0) {
        proc->time_slice--;
    }
    if (proc->time_slice == 0) {
        proc->need_resched = 1;
    }
}
```

- 每个时钟 tick将当前进程 `time_slice` 减一;若时间片用完，则设置 `need_resched = 1`，在安全点触发调度。
- 理由：RR 的核心即“时间片轮转”，通过时间片用尽后设置 `need_resched` 实现公平轮转。

------

### 3. `make grade` 与 QEMU 调度现象

`make grade`的结果是：

```
priority:                (3.2s)
  -check result:                             OK
  -check output:                             OK
Total Score: 50/50
```

在使用 RR 调度器（`sched_class = &default_sched_class`）时：

- `make grade` 输出中关键部分：

  - 出现 `"sched class: RR_scheduler"`。

  - priority测试项中会出现：`check result` 与 `check output` 均为 `OK`且最终 `Total Score: 50/50`。

- 在 QEMU 中观察到的调度现象（RR）：

  - 每个子进程打印的 `acc` 值接近，`sched result: 1 1 1 1 1`。
  - 说明所有进程获得的 CPU 时间大致相同，符合 RR 的“时间平均公平性”。

在启用 Stride 调度器时：

- `sched class: stride_scheduler`。

- priority程序输出：

  - `sched result: 1 1 2 2 3`（或相近比例）。
- 高优先级进程获得明显更多的 CPU 时间。

------

### 4. Round Robin 调度算法分析与拓展

#### 4.1 RR 的优缺点

- 优点：
  - 实现简单，易于理解与验证。
  - 对所有就绪进程公平：每个进程按轮次获得时间片，不会长期饥饿。
  - 响应时间较好，适合交互式系统。
- 缺点：
  - 不考虑进程优先级，无法区分重要/不重要任务。
  - 对 I/O 密集型和 CPU 密集型进程一视同仁，整体吞吐不一定最优。
  - 时间片设置不当可能导致：
    - 过大 → 接近 FIFO，响应变差。
    - 过小 → 上下文切换过于频繁，系统开销变大。

#### 4.2 时间片大小的调优

- 设计目标：
  - 时间片应大于一次典型上下文切换开销，避免大量时间浪费在切换上。
  - 时间片应足够小，使交互式任务的响应时间在可接受范围内。
- 在本实验中，`MAX_TIME_SLICE`设为 5，是权衡可见性与简洁性的选择。

#### 4.3 为什么 `RR_proc_tick` 中要设置 `need_resched`

- `need_resched`是“软中断”式标志：通过 `RR_proc_tick` 中的时间片逻辑，将“应该调度”的信息记录下来。而具体的调度发生在 `schedule()`，由内核在安全点（如中断返回、系统调用返回）调用。
  
- 如果不设置`need_resched`,即使时间片用尽，进程仍会继续执行，不会轮转到其他进程。这样RR 的公平性与响应性都会被破坏。


#### 4.4 拓展思考：优先级 RR 调度与多核支持

1. **如何实现优先级 RR 调度？**

   可以在现有 RR 基础上扩展：

   单队列 + 按优先级插入
   - 将高优先级进程插入队头或靠前位置，低优先级进程插入队尾或靠后位置。
   
   - 可以结合现有的 `lab6_priority` 字段，将调度决策与优先级挂钩。
   
2. **当前实现是否支持多核调度？**

   - 当前实现实际上是单核模型：
     - 全局只有一个 `run_queue`和一个 `sched_class`。
     - `current`、`idleproc`等都是单 CPU 语义。
   - 如果要支持多核（SMP），需要：
     - 为每个 CPU 维护一个 `run_queue`和一个 `current`。
     - 需要加锁保护运行队列（如自旋锁）。
     - 增加负载均衡接口（`load_balance`、`get_proc` 等），在空闲 CPU 上“偷”任务。
   - `sched_class` 结构中已经为多核预留了一些接口注释，从设计上是可扩展的。

------

## Challenge： Stride 调度与多级反馈队列设计

### 1. 多级反馈队列（MLFQ）调度算法概要设计

多级反馈队列（Multi-Level Feedback Queue, MLFQ）的核心思想：

- 维护多级就绪队列，每一层代表一个不同的优先级和时间片长度。
  - 高优先级队列：时间片短、响应快。
  - 低优先级队列：时间片长、适合长期 CPU 密集型任务。
- 新进程从最高优先级队列开始；
- 如果在当前队列用完时间片仍未完成，则“降级”到下一层队列；
- 若进程长时间未获得 CPU，可提升到更高优先级队列，避免饥饿。

#### 概要设计

- `run_queue`结构扩展：

  - 增加一个数组或链表数组，用于表示多个优先级队列：

    ```
    #define MLFQ_LEVELS 3
    struct run_queue {
        list_entry_t run_list[MLFQ_LEVELS];  // 每级一个 RR 队列
        unsigned int proc_num;
        int max_time_slice[MLFQ_LEVELS];     // 每级不同时间片
        // 其他字段...
    };
    ```

- `enqueue`
  
  - 根据进程当前所在优先级（ `proc->mlfq_level`），插入对应级别的 `run_list` 队尾。

- `pick_next`
  
  - 从最高优先级队列开始，找到第一个非空队列，选择队头进程。

- `proc_tick`
  
  - 每个 tick 递减 `time_slice`。
  - 时间片用完：
    - 若未完成，降低优先级（`level++`，但不超过最低级），设置新的时间片。
    - 若较低优先级进程长期得不到运行，可通过全局“老化”机制提升其优先级。
  
- 优点：

  - 兼顾高优先级短时间片和吞吐（低优先级长时间片）。
  - 自动根据进程行为（I/O 密集 / CPU 密集）调整优先级。

### 2. Stride 算法的“时间片与优先级成正比”说明

Stride 调度算法中，每个进程 `i` 有：

- 优先级（权重）：`priority_i`（越大表示越重要）
- 当前 stride 值：`stride_i`，初始为 0
- 每次被调度运行一个时间片后：
  - `stride_i += BIG_STRIDE / priority_i`

调度器总是选择当前 `stride` 最小的进程运行。

实验中 `priority` 程序的输出也验证了这一点：
`sched result: 1 1 2 2 3`，高优先级进程明显获得更多时间片。

### 3. Stride 实现过程简述

Challenge 中实现的 Stride 调度器主要步骤：

1. **定义 BIG_STRIDE**

   `#define BIG_STRIDE 0x7FFFFFFF`取一个足够大的正数，避免溢出。

2. **在进程结构中使用实验提供的字段**

   - `proc_struct`中已有：
   - `uint32_t lab6_stride;`
     - `uint32_t lab6_priority;`
   - `skew_heap_entry_t lab6_run_pool;`

3. **使用斜堆作为运行队列的优先队列**

   - `run_queue.lab6_run_pool` 为斜堆根。
   - 利用 `skew_heap_insert` / `skew_heap_remove`操作完成 O(log n) 的插入和删除。

4. **核心函数**

   - `stride_init`：初始化 `run_list`、`lab6_run_pool` 和 `proc_num`。

   - `stride_enqueue`
     - 将进程插入 `lab6_run_pool` 斜堆。
     - 设置时间片与 `rq`指针，增加 `proc_num`。

   - `stride_dequeue`
     - 用 `skew_heap_remove` 从斜堆移除该进程。
     
   - `stride_pick_next`
     - 从 `lab6_run_pool` 根节点获取 stride 最小的进程。
     - 更新其 `lab6_stride += BIG_STRIDE / lab6_priority`。

   - `stride_proc_tick`
     - 与 RR 类似，递减 `time_slice`，用尽后设置 `need_resched = 1`。

5. **切换调度器**

   - 在 `sched_init()`中将 `sched_class` 改为 `&stride_sched_class` 即可生效。

------

## 总结

- 通过本次实验，我深入理解了 uCore 调度器框架的设计思想：
  - 使用 `sched_class`进行策略抽象，将框架与算法解耦。
  - `run_queue`同时支持链表与斜堆，为不同复杂度的调度算法提供基础结构。
- 在此次实验的框架下，我不仅实现了基础的 Round Robin 调度算法，理解了时间片轮转、公平性和 `need_resched` 机制，还实现了 Stride 调度算法，并通过实验验证了“时间片分配与优先级成正比”的性质。