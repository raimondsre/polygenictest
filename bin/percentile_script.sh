#!/bin/bash

# Check if two filenames were provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 file1.txt file2.txt"
    exit 1
fi

# Assign filenames to variables
file1="$1"
file2="$2"

# Extract the number from the second file
number=$(cat $file2)

# Combine, sort the numbers, and calculate the rank of the number in file2
combined_sorted=$(cat $file1 $file2 | sort -n)
rank=$(echo "$combined_sorted" | awk -v num="$20" '{if ($1 <= num) rank++} END {print rank}')

# Count total numbers
total=$(echo "$combined_sorted" | wc -l)

# Calculate percentile
percentile=$(echo "scale=2; 100 * ($rank / $total)" | bc)

echo $percentile
