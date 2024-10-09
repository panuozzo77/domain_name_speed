#!/bin/bash

# Source the utility script
source ./dns_utils.sh

# Handle SIGINT (CTRL+C) signal
trap 'trap_exit' SIGINT

# Prepare DNS servers
prepare_dns_servers

# Clear previous results
echo "" > "$RESULTS_FILE"

# Get the total DNS servers and prompt user for input
total_servers=$(count_dns_servers)

# Use the get_user_input function to prompt for number of servers to test
user_input=$(get_user_input "$total_servers")

# Create an array of DNS servers
mapfile -t dns_servers < "$COMBINED_DNS_SERVERS_FILE"

# Determine the number of parallel jobs
nproc_val=$(nproc)
if [[ "$user_input" -lt "$nproc_val" ]]; then
    num_jobs="$user_input"
else
    num_jobs="$nproc_val"
fi

# Function to run dnsperf and save results
run_dnsperf() {
    local dns_server=$1
    local queries_file=$2
    local results_file=$3
    local counter=$4
    local user_input=$5

    # Print the current server being tested with its number
    echo "Testing DNS server: $dns_server ($counter of $user_input)"

    # Run dnsperf and capture output
    output=$(dnsperf -s "$dns_server" -d "$queries_file" -l 5 -c 10)

    # Extract relevant metrics from output
    queries_sent=$(echo "$output" | grep "Queries sent:" | awk '{print $3}')
    queries_completed=$(echo "$output" | grep "Queries completed:" | awk '{print $3}')
    qps=$(echo "$output" | grep "Queries per second:" | awk '{print $4}')
    avg_latency=$(echo "$output" | grep "Average Latency (s):" | awk '{print $4}')

    # Write results to file (thread-safe)
    echo "$dns_server, Queries Sent: $queries_sent, Queries Completed: $queries_completed, QPS: $qps, Avg Latency: $avg_latency" >> "$results_file"
}

# Check if GNU Parallel is installed
if ! command -v parallel &> /dev/null; then
    echo "GNU Parallel is not installed. Please install it to continue."
    exit 1
fi

# Export function and variables for parallel
export -f run_dnsperf
export QUERIES_FILE
export RESULTS_FILE
export counter
export user_input

# Prepare a file for Parallel processing
dns_test_list="dns_test_list.txt"
head -n "$user_input" "$COMBINED_DNS_SERVERS_FILE" > "$dns_test_list"

# Run dnsperf in parallel
echo "Running dnsperf with $num_jobs parallel jobs..."
counter=1
parallel -j "$num_jobs" run_dnsperf ::: $(<"$dns_test_list") ::: "$QUERIES_FILE" ::: "$RESULTS_FILE" ::: "$counter" ::: "$user_input"

# Wait for all parallel jobs to complete
wait

# Sort and save the results at the end of the script
save_and_sort_results
