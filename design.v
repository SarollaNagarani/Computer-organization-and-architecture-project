// L1 Cache Controller implemented using Direct Cache Mapping Technique with Write-Back and Write-Allocate

module cache_controller (
    input clk,
    input rst,
    input read,
    input write,
    input [7:0] addr,
    input [7:0] wdata,
    output reg [7:0] rdata,
    output reg hit,
    output reg stall
);

// Parameters for configuration
parameter BLOCK_SIZE = 4;
parameter NUM_SETS = 4;
parameter WRITE_BACK = 1;
parameter WRITE_ALLOCATE = 1;

// Derived constants
localparam OFFSET_BITS = 2;
localparam INDEX_BITS = 2;
localparam TAG_BITS = 8 - INDEX_BITS - OFFSET_BITS;

// Cache arrays (for direct-mapped)
reg valid [0:NUM_SETS-1];       // valid bits
reg dirty [0:NUM_SETS-1];       // dirty bits
reg [TAG_BITS-1:0] tag_array [0:NUM_SETS-1];   // tag storage
reg [7:0] block [0:NUM_SETS*BLOCK_SIZE-1];     // data storage

// Simulated main memory (for write-back)
reg [7:0] main_memory [0:255];  // 256-byte memory

// Address decomposition
wire [TAG_BITS-1:0] addr_tag = addr[7:4];
wire [INDEX_BITS-1:0] addr_index = addr[3:2];
wire [OFFSET_BITS-1:0] addr_offset = addr[1:0];

// Block base address calculation
wire [3:0] block_base = addr_index * BLOCK_SIZE;

// Hit detection (combinatorial)
wire cache_hit = valid[addr_index] && (tag_array[addr_index] == addr_tag);

integer i;

// Task to write back a block to main memory
task write_back;
    input [INDEX_BITS-1:0] index;
    reg [7:0] original_addr;
    integer i;
    begin
        if (dirty[index]) begin
            // Concatenation syntax
            original_addr = {tag_array[index], index, 2'b00};
            
            // Memory write operation
            for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
                main_memory[original_addr + i] = block[(index * BLOCK_SIZE) + i];
            end
            
            dirty[index] = 0;
            $display("Time: %0t | Write-Back: Index %d to Addr %h", 
                    $time, index, original_addr);
        end
    end
endtask

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset all cache entries
        for (i = 0; i < NUM_SETS; i = i + 1) begin
            valid[i] <= 0;
            dirty[i] <= 0;
            tag_array[i] <= 0;
        end
        // Initialize memory with default values
        for (i = 0; i < 256; i = i + 1) begin
            main_memory[i] <= 8'h00;
        end
        hit <= 0;
        stall <= 0;
        rdata <= 0;
    end
    else begin
        hit <= 0;
        stall <= 0;

        if (read || write) begin
            if (cache_hit) begin
                hit <= 1;
                stall <= 0;
                
                if (read) begin
                    rdata <= block[block_base + addr_offset];
                end
                if (write) begin
                    block[block_base + addr_offset] <= wdata;
                    if (WRITE_BACK) dirty[addr_index] <= 1;
                end
            end
            else begin // Cache miss
                stall <= 1;
                
                // Handle write-back if needed
                if (valid[addr_index] && dirty[addr_index] && WRITE_BACK) begin
                    write_back(addr_index); // Write back the evicted block
                end
                
                // Allocate new block (read from memory or initialize)
                tag_array[addr_index] <= addr_tag;
                valid[addr_index] <= 1;
                dirty[addr_index] <= 0;
                
                // Simulate memory read (write-allocate)
                for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
                    block[block_base + i] <= main_memory[{addr_tag, addr_index, 2'b00} + i];
                end
                
                if (write && WRITE_ALLOCATE) begin
                    block[block_base + addr_offset] <= wdata;
                    if (WRITE_BACK) dirty[addr_index] <= 1;
                end
                else if (read) begin
                    rdata <= main_memory[addr]; // Forward read data
                end
            end
            
            $display("Time: %0t | %s | Addr: %h | Index: %d | Offset: %d | Tag: %b | Hit: %b",
                     $time, read ? "READ" : "WRITE", addr, addr_index, addr_offset, addr_tag, cache_hit);
        end
    end
end
endmodule