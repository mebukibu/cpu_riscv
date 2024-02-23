#include "common.h"

void putchar(char ch);

void printf(const char *fmt, ...) {
  va_list vargs;
  va_start(vargs, fmt);

  while (*fmt) {
    if (*fmt == '%') {
      fmt++;
      switch (*fmt) {
        case '\0':
          putchar('%');
          goto end;
        case '%':
          putchar('%');
          break;
        case 's': {
          const char *s = va_arg(vargs, const char *);
          while (*s) {
            putchar(*s);
            s++;
          }
          break;
        }
        case 'x': {
          char buf[8];
          uint32_t x;
          int i = 0;
          int xx = va_arg(vargs, int);

          if (xx < 0)
            x = -xx;
          else
            x = xx;
          
          do {
            buf[i++] = "0123456789abcdef"[x & 0xf];
          } while((x >>= 4) != 0);

          if (xx < 0)
            buf[i++] = '-';
          
          while(--i >= 0)
            putchar(buf[i]);
        }
      }
    } else {
      putchar(*fmt);
    }

    fmt++;
  }

end:
  va_end(vargs);
};