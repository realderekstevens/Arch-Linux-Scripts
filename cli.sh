#!/bin/bash

PSQL="psql -X --username=postgres --dbname=buckbreaker --tuples-only -c"
PSQL_CreateDatabase="psql -X --username=postgres --dbname=postgres --tuples-only -c"

INTRODUCTION(){
clear;
gum style --border normal --margin "1" --padding "1 2" --border-foreground '#0000FF' "Hello, there! Welcome to $(gum style --foreground '#0000FF' 'Arch Linux PostgREST CLI')."
NAME=$(gum input --placeholder "What is your name?")
echo -e "Well, it is nice to meet you, $(gum style --foreground '#0000FF' "$NAME")."
clear;
MAIN_MENU
}

MAIN_MENU(){
DATABASE_MANAGEMENT="Database Management"; USER_MANAGEMENT="User Management"; DISCARD="Discard"
ACTIONS=$(gum choose --no-limit "$DATABASE_MANAGEMENT" "$USER_MANAGEMENT" "$DISCARD")

grep -q "$DATABASE_MANAGEMENT" <<< "$ACTIONS" && gum spin -s line --title "Reading the secret..." -- sleep 3
grep -q "$USER_MANAGEMENT" <<< "$ACTIONS" && gum spin -s pulse --title "Thinking about your secret..." -- sleep 3
grep -q "$PACKAGE_MANAGEMENT" <<< "$ACTIONS" && gum spin -s monkey --title " Discarding your secret..." -- sleep 3
}

INTRODUCTION
