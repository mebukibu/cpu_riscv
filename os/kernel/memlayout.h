// Physical memory layout

//
// 1000 -- uart0 
// 8000 -- kernel here
//

// qemu puts UART registers here in physical memory.
#ifdef QEMU
#define UART0 0x10000000L
#else
#define UART0 0x1000
#endif