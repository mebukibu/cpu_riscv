#include "defs.h"

void
main()
{
  char s[] = "Number";
  int i;
  for (i = 0; i < 5; i++)
    printf("%s : %x\n", s, i);
  
  printf("%%, %h", 1);

  while (1)
    asm volatile("unimp");
}