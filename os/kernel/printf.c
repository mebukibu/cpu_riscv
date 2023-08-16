#include <stdarg.h>

#include "defs.h"

// Print to the console. only understands %d, %x, %p, %s.
void
printf(char *fmt, ...)
{
  va_list ap;
  int i, c;
  // int locking;
  // char *s;

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
    // c = fmt[++i] & 0xff;
    // if(c == 0)
    //   break;
    // switch(c){
    // case 'd':
    //   printint(va_arg(ap, int), 10, 1);
    //   break;
    // case 'x':
    //   printint(va_arg(ap, int), 16, 1);
    //   break;
    // case 'p':
    //   printptr(va_arg(ap, uint64));
    //   break;
    // case 's':
    //   if((s = va_arg(ap, char*)) == 0)
    //     s = "(null)";
    //   for(; *s; s++)
    //     consputc(*s);
    //   break;
    // case '%':
    //   consputc('%');
    //   break;
    // default:
    //   // Print unknown % sequence to draw attention.
    //   consputc('%');
    //   consputc(c);
    //   break;
    // }
  }
  va_end(ap);

  // if(locking)
  //   release(&pr.lock);
}