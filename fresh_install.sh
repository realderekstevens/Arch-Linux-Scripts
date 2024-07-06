#!/bin/bash

gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Hello, there! Welcome to $(gum style --foreground 212 'Gum')."
NAME=$(gum input --placeholder "What is your name?")

echo -e "Well, it is nice to meet you, $(gum style --foreground 212 "$NAME")."

sleep 1; clear

echo -e "Can you tell me a $(gum style --italic --foreground 99 'secret')?\n"

gum write --placeholder "I'll keep it to myself, I promise!" > /dev/null # we keep the secret to ourselves

clear; echo "What should I do with this information?"; sleep 1

READ="Read"; THINK="Think"; DISCARD="Discard"
ACTIONS=$(gum choose --no-limit "$READ" "$THINK" "$DISCARD")

clear; echo "One moment, please."