#include "kernel.h"
#include "common.h"

extern char __bss[], __bss_end[], __stack_top[];

void *memset(void *buf, char c, size_t n) {
  uint8_t *p = (uint8_t *) buf;
  while (n--)
    *p++ = c;
  return buf;
}

void kernel_main(void) {
  memset(__bss, 0, (size_t) __bss_end - (size_t) __bss);

  printf("\n\nHello %s\n", "World!");
  printf("1 - 5 - 6 = %x\n", 1 - 5 - 6);

  for (;;){
    __asm__ __volatile__("wfi");
  };
}

__attribute__((section(".text.boot")))
__attribute__((naked))
void boot(void) {
  __asm__ __volatile__(
    "mv sp, %[stack_top]\n"
    "j kernel_main\n"
    :
    : [stack_top] "r" (__stack_top)
  );
}