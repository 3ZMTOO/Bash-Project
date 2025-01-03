#!/usr/bin/bash

insert_into_table () {
    table_name=$1 #first argument is the name of table
    values=("${@:2}") #The remaining arguments should be stored as values of table's columns
    DB_DIR=~


# #This should check is the table exists or not
table_file="$DB_DIR/$table_name.csv"

if [[ ! -f "$table_file" ]]; then       
    echo "Error: Table '$table_name' does not exist."
    return 1
fi 

schema=$(head -n 1 "$table_file")
IFS=',' read -r -a columns <<< "$schema"


if [[ ${#values[@]} -ne ${#columns[@]} ]]; then
echo "Error: Number of values (${#values[@]}) does not match the schema (${#columns[@]})."
return 1
fi

new_row=""
  for value in "${values[@]}"; do
    if [[ -n "$new_row" ]]; then
      new_row+=","
    fi
    new_row+="$value"
  done
  echo "$new_row" >> "$table_file"
  echo "Row inserted into '$table_name': $new_row"
}

insert_into_table bla2 name mariam 9 hi alo abdulrahman eskandarany modeer bono h haha 


