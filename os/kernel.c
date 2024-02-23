#include "kernel.h"
#include "common.h"

extern char __bss[], __bss_end[], __stack_top[];

void kernel_main(void) {
  memset(__bss, 0, (size_t) __bss_end - (size_t) __bss);

  printf("\n\nHello %s\n", "World!");
  printf("1 - 5 - 6 = %x\n", 1 - 5 - 6);

  char src[10], dst[10];
  memset(src, 'a', 9);
  src[9] = '\0';
  dst[0] = '\0';
  printf("src : %s, dst : %s\n", src, dst);
  memcpy(dst, src, 10);
  printf("src : %s, dst : %s\n", src, dst);
  strcpy(dst, "abcdefg");
  printf("src : %s, dst : %s\n", src, dst);
  printf("src == dst ?: %x\n", strcmp(src, dst));
  strcpy(dst, src);
  printf("src == dst ?: %x\n", strcmp(src, dst));

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