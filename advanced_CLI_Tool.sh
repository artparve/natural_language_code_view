#!/bin/bash

# Create a function to add parameters to json
function add_parametrs() {
    output_buffer=$output_buffer"\"parameters\": [ { "
    for (( k = 3; k < $#; k += 2)); do
      output_buffer=$output_buffer"\"name\": \"${!k}\", "
      next_index=$((k + 1))
      output_buffer=$output_buffer"\"type\": \"${!next_index}\""
      if [ $(( k + 2)) -lt $# ]; then
        output_buffer=$output_buffer", "
      else
        output_buffer=$output_buffer" "
      fi
    done
    output_buffer=$output_buffer"} ], "
}

# Check if the file is given an argument for the script
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename>.kt"
    exit 1
fi

# Get the file extension
filename="$1"
extension="${filename##*.}"

# Check if the extension is "kt"
if [ "$extension" != "kt" ]; then
    echo "$filename does not have .kt extension."
fi

# Create an output file in json format
output_filename="output_${filename%.*}.json"
output_buffer=""


output_buffer=$output_buffer"{"
mapfile -t file_contents < "$filename"
end_of_file=""


for (( i = 0; i < ${#file_contents[@]}; i++ )); do
  if [[ ${file_contents[i]} =~ "fun" ]]; then
    IFS=$'\n'
    parts=($(echo "${file_contents[i]}" | awk -F '[ (): {]' '{for(i=1; i<=NF; i++) print $i}'))
    number_of_parts="${#parts[@]}"
    count_of_brackets=0
    nested_flag=0


    output_buffer=$output_buffer" \"declarations\": [ { "
    output_buffer=$output_buffer"\"type\": \"function\", "
    output_buffer=$output_buffer"\"name\": \"${parts[1]}\", "

    add_parametrs "${parts[@]}"

    if [ $(( $number_of_parts % 2 )) -eq 0 ]; then
      output_buffer=$output_buffer"\"returnType\": \"Unit\","
    else
      output_buffer=$output_buffer"\"returnType\": \"${parts[-1]}\","
    fi

    output_buffer=$output_buffer" \"body\": \""

    for (( j = i; j < ${#file_contents[@]}; j++ )); do
      if [[ ${file_contents[j]} =~ "fun" ]]; then
        nested_flag=$((nested_flag + 1))
      fi
      output_buffer=$output_buffer"$(echo "${file_contents[j]}" | sed -e 's/^[ \t]*//' | sed 's/"/\\"/g')"

      if [[ ${file_contents[j]} =~ "{" ]]; then
        count_of_brackets=$((count_of_brackets + 1))
      fi

      if [[ ${file_contents[j]} =~ "}" ]]; then
        count_of_brackets=$((count_of_brackets - 1))
      fi
      if [ $count_of_brackets -eq 0 ]; then
        if [ $nested_flag -eq 1 ]; then
          output_buffer=$output_buffer"\""
          end_of_file=" } ],"$end_of_file
          output_buffer=$output_buffer"$end_of_file"
          end_of_file=""
        else
          output_buffer=$output_buffer"\","
          end_of_file="} ] "$end_of_file
        fi
        break
      fi

    done

  fi
done

output_buffer=$output_buffer"}"

echo "$output_buffer" | sed 's/\(.*\),/\1 /' > "$output_filename"


echo -e "Done\nSee file $output_filename"
