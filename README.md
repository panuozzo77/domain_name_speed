
![logo](https://github.com/user-attachments/assets/39da0a32-39f1-4b5e-8650-7306c4cf4fd0)

This project provides a suite of scripts for benchmarking DNS servers. It allows users to test multiple DNS servers for their performance metrics, including Queries Per Second (QPS) and average latency. The results can be sorted and analyzed to enhance decision-making in DNS configurations.

## Overview

The project consists of the following files:

- **benchmark.sh**: The primary script for running DNS benchmarks against a list of DNS servers. This script downloads the latest DNS server list, combines it with default servers, runs benchmarks, and sorts the results.
- **default_dns_servers.txt**: A file containing default DNS server IPs for benchmarking.
- **parallelized.sh**: A version of the benchmark script that executes tests in parallel, improving performance by utilizing multiple threads.
- **results.txt**: The output file where the raw results of the benchmarks are saved.
- **sorted_results.txt**: The output file where the sorted results (by QPS) are stored.
- **combined_dns_servers.txt**: A temporary file that combines the default DNS servers with the latest downloaded servers.
- **dns_servers.txt**: The file that holds the latest DNS servers downloaded from the internet.
- **queries.txt**: The file containing DNS query data used for testing.
- **useful**: A directory or file that contains additional resources or scripts (provide context if it's a directory).

## Features

- **Dynamic DNS Server Updates**: Download and update the list of DNS servers from a reliable source.
- **Default Server Combination**: Combine user-defined default DNS servers with the downloaded list for comparative analysis.
- **Performance Benchmarking**: Benchmark DNS servers using the `dnsperf` tool to measure their performance.
- **Result Management**: Save and sort results based on performance metrics for easy analysis.
- **Parallel Execution**: Option for parallel execution to speed up the testing process and improve efficiency.

## Prerequisites

- Any Linux distribution
- Ensure that the following tools are installed:
  - `dnsperf`: Benchmarking tool for DNS performance
  - `parallel`: Utility to execute tasks in parallel
  - `curl`: For downloading files
  - `awk`: For processing text files

You can typically install these using your package manager or by building them from source.

## Usage

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/dns-benchmark.git
   cd dns-benchmark
   ```
   
2. **Adjust configuration as needed:**

- Review the various variables in the *.sh files to ensure they suit your situation. In particular:
- dns_servers.txt: This file is fetched from a URL; choose one that suits your needs.
- default_dns_servers.txt: Use this file to benchmark well-known DNS servers like Google and Cloudflare against others.
- queries.txt: This file will be used to test the DNS servers with specific queries; you can source it from your Pi-hole or create your own.
3. **Run the benchmarks and enjoy!**

- Execute the benchmarking script with:
   ```bash
   ./benchmark.sh
   ```
 - For parallel execution, use:
    ```bash
   ./parallelized.sh
   ```
