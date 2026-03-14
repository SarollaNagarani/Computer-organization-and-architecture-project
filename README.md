# Cache Controller Design in Verilog

## Overview

This project implements a simple **direct-mapped cache controller** using Verilog.
The cache controller manages communication between the CPU and main memory to improve memory access speed.

## Features

* Direct-mapped cache architecture
* Write-back policy
* Write-allocate strategy
* Cache hit/miss detection
* Dirty and valid bit handling
* Simulated main memory

## Technologies Used

* Verilog HDL
* Digital Logic Design
* Computer Architecture concepts

## How It Works

1. The CPU sends a read or write request with an address.
2. The cache controller checks if the data exists in the cache (cache hit).
3. If the data is present, it is returned immediately.
4. If the data is not present (cache miss), the block is fetched from main memory.
5. If the replaced block is dirty, it is written back to memory.

## Files

* `cache_controller.v` – main cache controller implementation
* `testbench.v` – simulation testbench (if available)

## Author

Your Name
