// Sorting test program for Vigna RISC-V processor

#define TEST_OUTPUT_BASE 0x1000

void _start() {
    volatile int* test_output = (volatile int*)TEST_OUTPUT_BASE;
    
    // Test array to sort
    int arr[5] = {5, 2, 8, 1, 9};
    
    // Bubble sort implementation
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4 - i; j++) {
            if (arr[j] > arr[j + 1]) {
                // Swap elements
                int temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
    
    // Store sorted array to memory
    for (int i = 0; i < 5; i++) {
        test_output[i] = arr[i];
    }
    
    // Store completion marker
    test_output[5] = 0xABCDEF00;
    
    // Infinite loop to halt processor
    while(1) {};
}