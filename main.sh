#!/bin/bash

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

## Connecting to a database
connect_database() {
    read -p "Enter the name of the database you want to connect to: " database_name
    if [ -d "./db/$database_name" ]; then
        cd "./db/$database_name"
        echo "You are now connected to '$database_name' database."
        table_menu
    else
        echo "Database '$database_name' does not exist."
    fi
    return_to_menu
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