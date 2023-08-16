// Physical memory layout

//
// 1000 -- uart0 
// 8000 -- kernel here
//

// qemu puts UART registers here in physical memory.
#define UART0 0x1000