
#!/bin/bash

database_name=""

return_to_menu() {
    read -p "Do you want to return to the home page? (yes/no): " choose
    if [[ $choose == "yes" ]]; then
        first_menu
    else
        echo "thank you for using our system byeee .."
        exit
    fi
}

## Creating the database
create_database() {
    read -p "Enter database name: " database_name

    if [[ $database_name =~ ^[a-zA-Z0-9_]+$ ]]; then
        if [ -d "./db/$database_name" ]; then
            echo "Database already exists."
        else
            mkdir -p "./db/$database_name"
            echo "Database '$database_name' created."
        fi
    else
        echo "Invalid name! Use only letters, numbers, and underscores."
    fi
    return_to_menu
}


## Listing databases
list_databases() {
    if [ ! -d "./db/" ]; then
        echo "no databases for you"
    else
        echo "we found databases and its names are :"
        ls -F ./db/ | grep '/$'
    fi
    return_to_menu
}

##Connecting database
connect_database() {
    read -p "Enter the name of the database you want to connect to: " database_name
    if [ -d "./db/$database_name" ]; then
        # Store the full path of the connected database
        current_database_path="./db/$database_name"
        echo "You are now connected to '$database_name' database."
        table_menu
    else
        echo "Database '$database_name' does not exist."
    fi
    return_to_menu
}

##Create table
create_table() {
    read -p "Enter table name: " table_name
    if [[ $table_name =~ ^[a-zA-Z0-9_]+$ ]]; then
        if [[ ${#table_name} -gt 50 ]]; then
            echo "Table name is too long. Maximum length is 50 characters."
            return
        fi

        if [ -f "$current_database_path/$table_name.csv" ]; then
            echo "Table '$table_name' already exists."
        else
            while true; do
                read -p "Enter number of fields: " num_fields
                if [[ $num_fields =~ ^[0-9]+$ && $num_fields -ge 1 && $num_fields -le 20 ]]; then
                    break
                else
                    echo "Invalid input. Please enter a positive integer between 1 and 20."
                fi
            done

            read -p "Are you sure you want to create the table '$table_name'? (y/n): " confirm
            if [[ $confirm != "y" && $confirm != "Y" ]]; then
                echo "Table creation canceled."
                return
            fi

            metadata=""
            for ((i=1; i<=num_fields; i++)); do
                while true; do
                    read -p "Enter field $i name: " field_name
                    if [[ $i -eq 1 && $field_name != "id" ]]; then
                        echo "The first field must be 'id' (primary key)."
                    elif [[ ! $field_name =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
                        echo "Invalid field name. Field names must start with a letter and contain only letters, numbers, and underscores."
                    elif [[ $metadata == *"$field_name:"* ]]; then
                        echo "Field name '$field_name' already exists. Please choose a unique name."
                    else
                        break
                    fi
                done

                while true; do
                    read -p "Enter field $i type (string/int): " field_type
                    field_type=$(echo "$field_type" | tr '[:upper:]' '[:lower:]')
                    if [[ $field_type != "string" && $field_type != "int" ]]; then
                        echo "Invalid field type. Field type must be 'string' or 'int'."
                    else
                        break
                    fi
                done

                metadata+="$field_name:$field_type,"
            done

            # Save metadata in a separate file
            metadata=${metadata%,}
            echo "$metadata" > "$current_database_path/$table_name.metadata"
            touch "$current_database_path/$table_name.csv"
            echo "Table '$table_name' created with metadata."
        fi
    else
        echo "Invalid table name. Use only letters, numbers, and underscores."
    fi
}

## List table
list_tables() {
    if [ -z "$current_database_path" ]; then
        echo "You are not connected to a database."
        return
    fi

    echo "Listing tables in the '$current_database_path' database..."
    tables=$(ls "$current_database_path" | grep -v '.metadata' 2>/dev/null)

    if [ -z "$tables" ]; then
        echo "No tables found in this database."
    else
        echo "Tables in the '$current_database_path' database:"
        echo "$tables"
    fi
    return_to_menu
}

## Drop Table
drop_table() {
    if [ -z "$current_database_path" ]; then
        echo "You are not connected to a database."
        return
    fi

    tables=$(ls "$current_database_path" | sed 's/.csv$//')
    echo "Tables in the '$current_database_path' database:"
    echo "$tables"

    read -p "Enter the name of the table you want to drop: " table_name

    table_file="$current_database_path/$table_name.csv"
    metadata_file="$current_database_path/$table_name.metadata"

    echo "Checking table file: $table_file"
    echo "Checking metadata file: $metadata_file"

    if [ ! -f "$table_file" ]; then
        echo "Table '$table_name' does not exist in this database."
        return
    fi

    if [ ! -f "$metadata_file" ]; then
        echo "Metadata file for '$table_name' does not exist."
        return
    fi

    read -p "Are you sure you want to drop the table '$table_name'? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo "Table deletion canceled."
        return
    fi

    rm "$table_file"
    rm "$metadata_file"
    echo "Table '$table_name' and its metadata have been dropped successfully."
}

# Delete from table 
delete_from_table() {
    echo "Enter your table name:"
    read -r tname

    if [[ ! -f "$current_database_path/$tname.csv" ]]; then
        echo "Table does not exist."
        return
    fi

    echo "Select an option:"
    echo "1) Delete a specific column"
    echo "2) Delete from line to line"
    echo "3) Delete specific row by primary key"
    echo "4) Delete specific cell"
    echo "5) Delete entire table"
    echo "0) Exit"
    read -r option

    case $option in
        1) delete_column ;;
        2) delete_line_range ;;
        3) delete_row_by_primary_key ;;
        4) delete_specific_cell ;;
        5) delete_entire_table ;;
        0) return ;;  # Exit function or return to main menu
        *) echo "Invalid option. Please try again." ;;
    esac
}

# Delete a specific column by column number
delete_column() {
    local column_number
    echo "Enter the column number to delete:"
    read -r column_number

    if [[ ! $column_number =~ ^[0-9]+$ ]]; then
        echo "Invalid column number."
        return
    fi

    new_content=$(awk -F, -v col="$column_number" '{
        for (i = 1; i <= NF; i++) {
            if (i != col) {
                printf "%s", $i
                if (i != NF && i != col) {
                    printf ","
                }
            }
        }
        print ""  
    }' "$current_database_path/$tname.csv")

    echo "$new_content" > "$current_database_path/$tname.csv"

    echo "Column $column_number deleted."
}

# Delete a range of lines (rows)
delete_line_range() {
    local num_start num_end
    echo "Enter the start and end row numbers to delete:"
    read -r num_start num_end

    if [[ ! $num_start =~ ^[0-9]+$ || ! $num_end =~ ^[0-9]+$ || $num_start -gt $num_end ]]; then
        echo "Invalid row numbers."
        return
    fi

    sed -i "${num_start},${num_end}d" "$current_database_path/$tname.csv"
    echo "Rows $num_start to $num_end deleted."
}

# Delete a specific row by primary key
delete_row_by_primary_key() {
    local primary_key
    echo "Enter the primary key value of the row to delete:"
    read -r primary_key

    if [[ -z $primary_key ]]; then
        echo "Primary key cannot be empty."
        return
    fi

    sed -i "/^$primary_key,/d" "$current_database_path/$tname.csv"
    echo "Row with primary key '$primary_key' deleted."
}

# Delete a specific cell
delete_specific_cell() {
    local row_number column_number
    echo "Enter the row and column numbers of the cell to delete:"
    read -r row_number column_number

    if [[ ! $row_number =~ ^[0-9]+$ || ! $column_number =~ ^[0-9]+$ ]]; then
        echo "Invalid row or column number."
        return
    fi

    new_content=$(awk -F, -v row="$row_number" -v col="$column_number" 'NR == row { $col = ""; } { print }' OFS=, "$current_database_path/$tname.csv")

    echo "$new_content" > "$current_database_path/$tname.csv"

    echo "Cell in row $row_number, column $column_number deleted."
}

# Delete the entire table
delete_entire_table() {
    local confirm
    echo "Are you sure you want to delete the entire table '$tname'? (y/n)"
    read -r confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        rm -f "$current_database_path/$tname.csv" "$current_database_path/$tname.metadata"
        echo "Table '$tname' and its metadata deleted."
    else
        echo "Deletion canceled."
    fi
}

# Update Row
update_row() {
    if [ -z "$current_database_path" ]; then
        echo "You are not connected to a database."
        return
    fi

    read -p "Enter the table name to update a row: " table_name
    table_file="$current_database_path/$table_name.csv"
    metadata_file="$current_database_path/$table_name.metadata"

    if [ ! -f "$table_file" ]; then
        echo "Table '$table_name' does not exist."
        return
    fi

    if [ ! -f "$metadata_file" ]; then
        echo "Metadata file for '$table_name' does not exist."
        return
    fi

  
    read -p "Enter the primary key value of the row to update: " primary_key

    row=$(grep "^$primary_key," "$table_file")
    if [ -z "$row" ]; then
        echo "Row with primary key '$primary_key' not found."
        return
    fi

    echo "Found the row: $row"

    read -p "Enter the new data for the row (comma-separated): " new_row

    sed -i "/^$primary_key,/c\\$new_row" "$table_file"
    echo "Row with primary key '$primary_key' has been updated."
}

## insert_into tables
insert_into_table() {
    if [ -z "$current_database_path" ]; then
        echo "You are not connected to a database."
        return
    fi

    read -p "Enter the name of the table: " table_name
    table_file="$current_database_path/$table_name.csv"
    metadata_file="$current_database_path/$table_name.metadata"

    if [ ! -f "$table_file" ]; then
        echo "Table '$table_name' does not exist."
        return
    fi

    if [ ! -f "$metadata_file" ]; then
        echo "Metadata file for '$table_name' does not exist."
        return
    fi

    # Read metadata into an array
    IFS=',' read -r -a fields < "$metadata_file"

    while true; do
        echo "Enter values for each field:"
        row=""  # Reset row for new insert
        for field in "${fields[@]}"; do
            field_name=$(echo "$field" | cut -d':' -f1)
            field_type=$(echo "$field" | cut -d':' -f2)

            while true; do
                read -p "Enter value for $field_name ($field_type): " value

                # Validate value based on type
                case "$field_type" in
                    "int")
                        if [[ ! $value =~ ^[0-9]+$ ]]; then
                            echo "Invalid value for $field_name. Expected an integer."
                            continue
                        fi
                        ;;
                    "string")
                        # No specific validation for strings
                        if [[ -z "$value" ]]; then
                            echo "Invalid value for $field_name. Cannot be empty."
                            continue
                        fi
                        ;;
                    *)
                        echo "Unknown field type '$field_type' in metadata."
                        return
                        ;;
                esac
                # Append validated value to row
                row+="$value,"
                break
            done
        done

        # Remove trailing comma from the row
        row=${row%,}

        # Append the row to the CSV file
        echo "$row" >> "$table_file"

        echo "Row inserted successfully!"
        break
    done
}

## select from table
select_from_table() {
    if [ -z "$current_database_path" ]; then
        echo "You are not connected to a database."
        return
    fi

    read -p "Enter the name of the table: " table_name
    table_file="$current_database_path/$table_name.csv"
    metadata_file="$current_database_path/$table_name.metadata"

    if [ ! -f "$table_file" ]; then
        echo "Table '$table_name' does not exist."
        return
    fi

    if [ ! -f "$metadata_file" ]; then
        echo "Metadata file for '$table_name' does not exist."
        return
    fi

    echo "Select Options:"
    echo "1. Select all rows from the table"
    echo "2. Select specific columns from the table"
    read -p "Choose an option: " option

    case $option in
        1)
            echo "Displaying all rows from the table '$table_name':"
            if [ ! -s "$table_file" ]; then
                echo "The table is empty."
            else
                cat "$table_file"
            fi
            ;;
        2)
            echo "Fetching metadata..."
            # Parse metadata to get column names
            IFS=',' read -r -a fields < "$metadata_file"
            column_names=()
            for field in "${fields[@]}"; do
                column_names+=("$(echo "$field" | cut -d':' -f1)")
            done
            echo "Available columns: ${column_names[*]}"

            read -p "Enter the column names to select (comma-separated): " selected_columns_input
            IFS=',' read -r -a selected_columns <<< "$selected_columns_input"

            # Validate user input
            valid_selection=true
            for column in "${selected_columns[@]}"; do
                if [[ ! " ${column_names[@]} " =~ " $column " ]]; then
                    echo "Column '$column' does not exist in the table."
                    valid_selection=false
                fi
            done

            if ! $valid_selection; then
                echo "Invalid column selection. Please try again."
                return
            fi

            echo "Selected columns: ${selected_columns[*]}"

            # Get column indices
            indices=()
            for column in "${selected_columns[@]}"; do
                for i in "${!column_names[@]}"; do
                    if [[ "${column_names[$i]}" == "$column" ]]; then
                        indices+=("$i")
                    fi
                done
            done

            echo "Displaying selected columns from the table '$table_name':"
            {
                # Display selected column headers
                echo "${selected_columns[*]}"

                # Read table data row by row
                while IFS=',' read -r -a row; do
                    selected_data=()
                    for index in "${indices[@]}"; do
                        selected_data+=("${row[$index]}")
                    done
                    echo "${selected_data[*]}" | sed 's/ /,/g' # Output as comma-separated values
                done
            } < "$table_file"
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
}

## Table operations menu
table_menu() {
	count=0
    while ((count<5)); do
        echo "Table Menu:"
        echo "1. Create Table"
        echo "2. List Tables"
        echo "3. Drop Table"
        echo "4. Insert into Table"
        echo "5. Select from Table"
        echo "6. Delete from Table"
        echo "7. Update Row"
        echo "8. Back to Main Menu"
        read -p "Select an option: " choice

        case $choice in
            1) create_table ;;
            2) list_tables ;;
            3) drop_table ;;
            4) insert_into_table ;;
            5) select_from_table ;;
            6) delete_from_table ;;
            7) update_row ;;
            8) cd ../..; return_to_menu ;;
            *) echo "Invalid option" ;;
        esac
    done
}

## Dropping a database
drop_database() {
    read -p "Enter the name of the database to drop: " database_name
    if [ -d "./db/$database_name" ]; then
        rm -r "./db/$database_name"
        echo "Database '$database_name' dropped don't worry "
    else
        echo "Database '$database_name' does not exist"
    fi
    return_to_menu
}

## Main menu
first_menu() {
    count=0
    while (( count < 5 )); do
        echo "
        ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
        ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⠀⠀⠀⢠⣾⣧⣤⡖⠀⠀⠀⠀⠀⠀⠀
        ⠀⠀⠀⠀⠀⠀⠀⠀⢀⣼⠋⠀⠉⠀⢄⣸⣿⣿⣿⣿⣿⣥⡤⢶⣿⣦⣀⡀
        ⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡆⠀⠀⠀⣙⣛⣿⣿⣿⣿⡏⠀⠀⣀⣿⣿⣿⡟
        ⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⠷⣦⣤⣤⣬⣽⣿⣿⣿⣿⣿⣿⣿⣟⠛⠿⠋⠀
        ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⠋⣿⣿⣿⣿⣿⣿⣿⣿⢿⣿⣿⡆⠀⠀
        ⠀⠀⠀⠀⣠⣶⣶⣶⣶⣦⡀⠘⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠈⢹⣿⡇⠀⠀
        ⠀⠀⠀⢀⣿⡏⠉⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡆⠀⢀⣿⣿⠀⠀⠀
        ⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣟⡘⣿⣿⣃⠀⠀⠀
        ⣴⣷⣀⣸⣿⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⠹⣿⣯⣤⣾⠏⠉⠉⠉⠙⠢⠀
        ⠈⠙⢿⣿⡟⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣄⠛⠉⢩⣷⣴⡆⠀⠀⠀⠀⠀
        ⠀⠀⠀⠋⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⣿⣿⣀⡠⠋⠈⢿⣇⠀⠀⠀⠀⠀
        ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠿⠿⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
        ⠀⠀⠀⠀⠀
        ⠀⠀⠀"
        echo "=== EMA Management System ==="
        echo "1. Create Database"
        echo "2. List Databases"
        echo "3. Connect to Database"
        echo "4. Drop Database"
        echo "5. Exit"
        echo "==============================="

        read -p "Choose one from the options " choose

        case $choose in
            1) create_database ;;
            2) list_databases ;;
            3) connect_database ;;
            4) drop_database ;;
            5) echo "Bye ....."; exit ;;
            *) echo "Invalid choice" ;;
        esac
    done
}

first_menu
