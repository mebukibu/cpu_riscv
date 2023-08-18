#include <stdarg.h>

#include "types.h"
#include "defs.h"

static char digits[] = "0123456789abcdef";

static void
printhex(int xx, int sign)
{
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    x = -xx;
  else
    x = xx;

  i = 0;
  do {
    buf[i++] = digits[x & 0xf];
  } while((x >>= 4) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
    consputc(buf[i]);
}

// Print to the console. only understands %d, %x, %p, %s.
void
printf(char *fmt, ...)
{
  va_list ap;
  int i, c;
  // int locking;
  char *s;

  // locking = pr.locking;
  // if(locking)
  //   acquire(&pr.lock);

  // if (fmt == 0)
  //   panic("null fmt");

  va_start(ap, fmt);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    if(c != '%'){
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    // case 'd':
    //   printint(va_arg(ap, int), 10, 1);
    //   break;
    case 'x':
      printhex(va_arg(ap, int), 1);
      break;
    // case 'p':
    //   printptr(va_arg(ap, uint64));
    //   break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
      break;
    case '%':
      consputc('%');
      break;
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
      consputc(c);
      break;
    }
  }
  va_end(ap);

  // if(locking)
  //   release(&pr.lock);
}