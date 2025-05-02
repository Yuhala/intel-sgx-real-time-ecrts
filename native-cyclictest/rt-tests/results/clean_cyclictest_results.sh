#!/bin/bash

# Find all *.ct files and process them
for file in *.ct; do
  if [[ -f "$file" ]]; then
    # Use a temporary file to store the modified content
    temp_file=$(mktemp)

    # Flag to indicate when to start writing lines
    write=0

    # Read the file line by line
    while IFS= read -r line; do
      # If the line contains "# Histogram", set the flag to start writing
      if [[ "$line" == *"# Histogram"* ]]; then
        write=1
      fi

      # Write the line to the temporary file if the flag is set
      if [[ $write -eq 1 ]]; then
        echo "$line" >> "$temp_file"
      fi
    done < "$file"

    # Overwrite the original file with the contents of the temporary file
    mv "$temp_file" "$file"
  fi
done

echo "Processing complete."