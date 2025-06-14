// Fibonacci test program for Vigna RISC-V processor

#define TEST_OUTPUT_BASE 0x1000

void _start() {
    volatile int* test_output = (volatile int*)TEST_OUTPUT_BASE;
    
    // Calculate first 8 Fibonacci numbers
    int fib[8];
    fib[0] = 0;
    fib[1] = 1;
    
    for (int i = 2; i < 8; i++) {
        fib[i] = fib[i-1] + fib[i-2];
    }
    
    // Store results to memory
    for (int i = 0; i < 8; i++) {
        test_output[i] = fib[i];
    }
    
    // Store completion marker
    test_output[8] = 0x12345678;
    
    // Infinite loop to halt processor
    while(1) {};
}