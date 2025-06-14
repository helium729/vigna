// Simple Fibonacci test program for Vigna RISC-V processor (stack-free)

#define TEST_OUTPUT_BASE 0x1000

void _start() {
    volatile int* test_output = (volatile int*)TEST_OUTPUT_BASE;
    
    // Calculate first 8 Fibonacci numbers without using arrays
    int a = 0, b = 1;
    
    // Store first two numbers
    test_output[0] = a;
    test_output[1] = b;
    
    // Calculate and store the rest
    for (int i = 2; i < 8; i++) {
        int next = a + b;
        test_output[i] = next;
        a = b;
        b = next;
    }
    
    // Store completion marker
    test_output[8] = 0x12345678;
    
    // Infinite loop to halt processor
    while(1) {};
}