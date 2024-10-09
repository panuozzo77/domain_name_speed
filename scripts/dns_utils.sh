#!/bin/bash

# Default file paths (can be overridden if needed)
RESULTS_FILE="${RESULTS_FILE:-../results/results.txt}"
SORTED_RESULTS_FILE="${SORTED_RESULTS_FILE:-../results/sorted.txt}"
DNS_SERVERS_URL="${DNS_SERVERS_URL:-https://public-dns.info/nameserver/it.txt}"
TEMP_DNS_FILE="${TEMP_DNS_FILE:-../config/dns_servers_temp.txt}"
DNS_SERVERS_FILE="${DNS_SERVERS_FILE:-../config/dns_servers.txt}"
QUERIES_FILE="${QUERIES_FILE:-../config/queries.txt}"
DEFAULT_DNS_SERVERS_FILE="${DEFAULT_DNS_SERVERS_FILE:-../config/default_dns_servers.txt}"
COMBINED_DNS_SERVERS_FILE="${COMBINED_DNS_SERVERS_FILE:-../config/combined_dns_servers.txt}"

# Function to download and combine DNS server lists
prepare_dns_servers() {
    # Download the latest DNS server list to a temporary file
    curl -s -o "$TEMP_DNS_FILE" "$DNS_SERVERS_URL"

    # Check if the downloaded file is different from the existing dns_servers.txt
    if cmp -s "$TEMP_DNS_FILE" "$DNS_SERVERS_FILE"; then
        echo "DNS server list is up to date, no changes made."
        rm "$TEMP_DNS_FILE"
    else
        echo "DNS server list has changed. Updating dns_servers.txt."
        mv "$TEMP_DNS_FILE" "$DNS_SERVERS_FILE"
    fi

    # Prepare combined DNS servers for testing
    if [[ -f "$DEFAULT_DNS_SERVERS_FILE" ]]; then
        echo "Combining default DNS servers from $DEFAULT_DNS_SERVERS_FILE with the downloaded servers."
        cat "$DEFAULT_DNS_SERVERS_FILE" "$DNS_SERVERS_FILE" > "$COMBINED_DNS_SERVERS_FILE"
    else
        echo "Warning: Default DNS servers file ($DEFAULT_DNS_SERVERS_FILE) not found."
        cp "$DNS_SERVERS_FILE" "$COMBINED_DNS_SERVERS_FILE"
    fi
}

# Function to sort and save results
save_and_sort_results() {
    if [[ -s "$RESULTS_FILE" ]]; then
        echo "Saving and sorting the results..."
        awk -F', ' '{print $0}' "$RESULTS_FILE" | sort -k4 -nr > "$SORTED_RESULTS_FILE"
        echo "Benchmarking complete. Results saved to $RESULTS_FILE and sorted results saved to $SORTED_RESULTS_FILE."
        
        if [[ -f "$dns_test_list" ]]; then
            rm "$dns_test_list"
        fi
    else
        echo "No results to save."
    fi
}

# Trap handler to save and sort results on exit
trap_exit() {
    echo "CTRL+C detected!"
    save_and_sort_results
    exit 1
}

# Count total DNS servers
count_dns_servers() {
    total_servers=$(wc -l < "$COMBINED_DNS_SERVERS_FILE")
    echo "Found $total_servers DNS servers in the combined file."
    echo "$total_servers"
}

# Function to prompt user for number of servers to test
get_user_input() {
    local total_servers=$1
    read -p "Enter the number of DNS servers to test (press Enter to test all): " user_input
    if [[ -z "$user_input" ]]; then
        user_input=$total_servers
    fi
    echo "$user_input"
}
