#pragma once
#include "common.h"

#define PROCS_MAX 4
#define PROC_UNUSED   0
#define PROC_RUNNABLE 1
#define PROC_EXITED   2
#define MSTATUS_MPP_MASK (3u << 11)
#define MSTATUS_MPP_S    (1u << 11)
#define SIE_SEIE         (1L << 9) // external
#define SIE_STIE         (1L << 5) // timer
#define SIE_SSIE         (1L << 1) // software
#define SATP_SV32        (1u << 31)
#define SSTATUS_SPIE     (1u << 5)
#define SCAUSE_ECALL 8
#define PAGE_V (1 << 0)
#define PAGE_R (1 << 1)
#define PAGE_W (1 << 2)
#define PAGE_X (1 << 3)
#define PAGE_U (1 << 4)

#ifdef QEMU
#define USER_BASE 0x80000928
#define UART_BASE 0x10000000
#else
#define USER_BASE 0x8928
#define UART_BASE 0x1000
#endif

struct process {
  int pid;
  int state;
  vaddr_t sp;
  // uint32_t *page_table;
  uint8_t stack[1024];
};

struct trap_frame {
  uint32_t ra;
  uint32_t gp;
  uint32_t tp;
  uint32_t t0;
  uint32_t t1;
  uint32_t t2;
  uint32_t t3;
  uint32_t t4;
  uint32_t t5;
  uint32_t t6;
  uint32_t a0;
  uint32_t a1;
  uint32_t a2;
  uint32_t a3;
  uint32_t a4;
  uint32_t a5;
  uint32_t a6;
  uint32_t a7;
  uint32_t s0;
  uint32_t s1;
  uint32_t s2;
  uint32_t s3;
  uint32_t s4;
  uint32_t s5;
  uint32_t s6;
  uint32_t s7;
  uint32_t s8;
  uint32_t s9;
  uint32_t s10;
  uint32_t s11;
  uint32_t sp;
} __attribute__((packed));

#define READ_CSR(reg)                                                      \
  ({                                                                       \
    unsigned long __tmp;                                                   \
    __asm__ __volatile__("csrr %0, " #reg : "=r"(__tmp));                  \
    __tmp;                                                                 \
  })

#define WRITE_CSR(reg, value)                                              \
  do {                                                                     \
    uint32_t __tmp = (value);                                              \
    __asm__ __volatile__("csrw " #reg ", %0" ::"r"(__tmp));                \
  } while (0)

#define PANIC(fmt, ...)                                                    \
  do {                                                                     \
    printf("PANIC: %s:%i: " fmt "\n", __FILE__, __LINE__, ##__VA_ARGS__);  \
    while (1) {}                                                           \
  } while (0)

void putchar(char ch);
char getchar(void);