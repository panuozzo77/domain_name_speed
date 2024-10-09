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
user_input=$(get_user_input "$total_servers")

# Initialize a counter
counter=0

# Loop through each DNS server and run dnsperf using the combined list
while read -r dns_server; do
    # Increment the counter
    ((counter++))

    # Stop if we've reached the user-defined limit
    if (( counter > user_input )); then
        break
    fi

    # Run dnsperf and capture output
    echo "Testing DNS server: $dns_server ($counter of $user_input)"
    output=$(dnsperf -s "$dns_server" -d "$QUERIES_FILE" -l 5 -c 10)

    # Extract metrics and write results
    queries_sent=$(echo "$output" | grep "Queries sent:" | awk '{print $3}')
    queries_completed=$(echo "$output" | grep "Queries completed:" | awk '{print $3}')
    qps=$(echo "$output" | grep "Queries per second:" | awk '{print $4}')
    avg_latency=$(echo "$output" | grep "Average Latency (s):" | awk '{print $4}')
    echo "$dns_server, Queries Sent: $queries_sent, Queries Completed: $queries_completed, QPS: $qps, Avg Latency: $avg_latency" >> "$RESULTS_FILE"

done < "$COMBINED_DNS_SERVERS_FILE"

# Sort and save the results at the end of the script
save_and_sort_results
