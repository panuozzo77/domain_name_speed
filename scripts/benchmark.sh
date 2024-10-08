#!/bin/bash

# Define input files and URLs
DNS_SERVERS_FILE="dns_servers.txt"
QUERIES_FILE="queries.txt"
RESULTS_FILE="results.txt"
DNS_SERVERS_URL="https://public-dns.info/nameserver/it.txt"
TEMP_DNS_FILE="dns_servers_temp.txt"
DEFAULT_DNS_SERVERS_FILE="default_dns_servers.txt"  # File containing default DNS servers
COMBINED_DNS_SERVERS_FILE="combined_dns_servers.txt"  # Temporary file for combined DNS servers

# Function to sort and save results
save_and_sort_results() {
    if [[ -s "$RESULTS_FILE" ]]; then
        echo "Saving and sorting the results..."
        # Use awk to sort by QPS without including it at the start of the line
	awk -F', ' '{print $0}' "$RESULTS_FILE" | sort -k4 -nr > "sorted_$RESULTS_FILE"
        echo "Benchmarking complete. Results saved to $RESULTS_FILE and sorted results saved to sorted_$RESULTS_FILE."
    else
        echo "No results to save."
    fi
}

# Handle SIGINT (CTRL+C) signal
trap 'echo "CTRL+C detected!"; save_and_sort_results; exit 1' SIGINT

# Download the latest DNS server list to a temporary file
curl -s -o "$TEMP_DNS_FILE" "$DNS_SERVERS_URL"

# Check if the downloaded file is different from the existing dns_server.txt
if cmp -s "$TEMP_DNS_FILE" "$DNS_SERVERS_FILE"; then
    echo "DNS server list is up to date, no changes made."
    rm "$TEMP_DNS_FILE"  # Remove the temporary file if there are no changes
else
    echo "DNS server list has changed. Updating dns_server.txt."
    mv "$TEMP_DNS_FILE" "$DNS_SERVERS_FILE"  # Replace the old file with the new one
fi

# Prepare combined DNS servers for testing
if [[ -f "$DEFAULT_DNS_SERVERS_FILE" ]]; then
    echo "Combining default DNS servers from $DEFAULT_DNS_SERVERS_FILE with the downloaded servers."
    cat "$DEFAULT_DNS_SERVERS_FILE" "$DNS_SERVERS_FILE" > "$COMBINED_DNS_SERVERS_FILE"
else
    echo "Warning: Default DNS servers file ($DEFAULT_DNS_SERVERS_FILE) not found."
    cp "$DNS_SERVERS_FILE" "$COMBINED_DNS_SERVERS_FILE"  # Just copy the existing DNS servers
fi

# Clear previous results
echo "" > "$RESULTS_FILE"

# Count total DNS servers
total_servers=$(wc -l < "$COMBINED_DNS_SERVERS_FILE")
echo "Found $total_servers DNS servers in the combined file."

# Prompt user for number of servers to test
read -p "Enter the number of DNS servers to test (press Enter to test all): " user_input

# If user_input is empty, set to total_servers
if [[ -z "$user_input" ]]; then
    user_input=$total_servers
fi

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

    # Print the current server being tested with its number
    echo "Testing DNS server: $dns_server ($counter of $user_input)"

    # Run dnsperf and capture output
    output=$(dnsperf -s "$dns_server" -d "$QUERIES_FILE" -l 5 -c 10)

    # Extract relevant metrics from output
    queries_sent=$(echo "$output" | grep "Queries sent:" | awk '{print $3}')
    queries_completed=$(echo "$output" | grep "Queries completed:" | awk '{print $3}')
    qps=$(echo "$output" | grep "Queries per second:" | awk '{print $4}')
    avg_latency=$(echo "$output" | grep "Average Latency (s):" | awk '{print $4}')

    # Write results to file
    echo "$dns_server, Queries Sent: $queries_sent, Queries Completed: $queries_completed, QPS: $qps, Avg Latency: $avg_latency" >> "$RESULTS_FILE"

done < "$COMBINED_DNS_SERVERS_FILE"

# Sort and save the results at the end of the script
save_and_sort_results
