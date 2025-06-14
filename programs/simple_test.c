// Simple test program for Vigna RISC-V processor - bare metal version

#define TEST_OUTPUT_BASE 0x1000

void _start() {
    volatile int* test_output = (volatile int*)TEST_OUTPUT_BASE;
    
    // Simple arithmetic test
    int a = 10;
    int b = 20;
    int result = a + b;
    
    // Store result at memory location for verification
    test_output[0] = result;  // Should be 30
    
    // Simple loop test
    int sum = 0;
    for (int i = 1; i <= 5; i++) {
        sum += i;
    }
    test_output[1] = sum;  // Should be 15 (1+2+3+4+5)
    
    // Simple conditional test
    int max_val = (a > b) ? a : b;
    test_output[2] = max_val;  // Should be 20
    
    // Halt indication
    test_output[3] = 0xDEADBEEF;  // Test completion marker
    
    // Infinite loop to halt processor
    while(1) {};
}