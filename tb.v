`timescale 1ps/1ps

module cache_tb;
    reg clk, rst, read, write;
    reg [7:0] addr, wdata;
    wire [7:0] rdata;
    wire hit, stall;

//Instantiating the cache controller
    cache_controller uut (
        .clk(clk),
        .rst(rst), 
        .read(read), 
        .write(write),
        .addr(addr), 
        .wdata(wdata), 
        .rdata(rdata), 
        .hit(hit), 
        .stall(stall)
    );

//Generating the clock
    always #5000 clk = ~clk;

//Instantiating the VCD file to study the waveform
    initial begin
        $dumpfile("cache_waveform.vcd");
        $dumpvars(0, cache_tb);
        $display("VCD waveform dump enabled");
    end

//This task handles the memory access
    task access(input r, input w, input [7:0] a, input [7:0] d);
        begin
            read = r; write = w; addr = a; wdata = d;
            #10000;
            read = 0; write = 0;
            $display("Time: %0t | Read: %b | Write: %b | Addr: %h | WData: %h | RData: %h | Hit: %b | Stall: %b",
                    $time, r, w, a, d, rdata, hit, stall);
        end
    endtask

    initial begin
        $display("Starting Direct-Mapped Cache Controller Testbench");
        clk = 0; rst = 1;
        read = 0; write = 0; addr = 0; wdata = 0;
        #10000 rst = 0;

        // Test Cases
        $display("\n=== Test Case 1: Cold Misses ===");
        access(0, 1, 8'h10, 8'hA5);
        access(1, 0, 8'h10, 8'h00);

        $display("\n=== Test Case 2: Conflict Misses ===");
        access(0, 1, 8'h24, 8'hB6);
        access(0, 1, 8'h30, 8'hC7);
        access(1, 0, 8'h10, 8'h00);

        $display("\n=== Test Case 3: Reset During Operation ===");
        access(0, 1, 8'h48, 8'hE9);
        #5000 rst = 1;
        #10000 rst = 0;
        access(1, 0, 8'h48, 8'h00);

        $display("\n=== Test Case 4: Same Index, Different Tags ===");
        access(0, 1, 8'h90, 8'hF0);
        access(0, 1, 8'h10, 8'h01);
        access(1, 0, 8'h90, 8'h00);

        $display("\n=== Test Case 5: Back-to-Back Accesses ===");
        access(0, 1, 8'hA0, 8'h12);
        access(0, 1, 8'hA0, 8'h23);
        access(1, 0, 8'hA0, 8'h00);

        //Edge case tests
        $display("\n=== Test Case 6: All-Bits-Set Address (8'hFF) ===");
        access(0, 1, 8'hFF, 8'hAA); // Write to max address
        access(1, 0, 8'hFF, 8'h00); // Read from max address
        access(0, 1, 8'h00, 8'hBB); // Write to min address
        access(1, 0, 8'h00, 8'h00); // Read from min address

        $display("\n=== Test Case 7: Concurrent Read/Write ===");
        // First setup a known value
        access(0, 1, 8'h55, 8'hCC);
        // Then attempt concurrent operation
        read = 1; write = 1; addr = 8'h55; wdata = 8'hDD;
        #10000;
        $display("Time: %0t | Concurrent R/W | Addr: 55 | WData: DD | RData: %h | Hit: %b | Stall: %b",
                $time, rdata, hit, stall);
        read = 0; write = 0;

        #50000;
        $display("\nAll tests completed.");
        $finish;
    end
endmodule