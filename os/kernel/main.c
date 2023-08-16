#include "defs.h"

void
main()
{
  printf("Hello World!\n");
  while (1)
    asm volatile("unimp");
}