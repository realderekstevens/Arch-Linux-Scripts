#!/bin/bash

sudo pacman -Syu gum

PSQL="psql -X --username=postgres --dbname=bikes --tuples-only -c"
PSQL_CreateDatabase="psql -X --username=postgres --dbname=postgres --tuples-only -c"

gum style --border normal --margin "1" --padding "1 2 " --border-foreground 212 "Hello, there! Welcome to $(gum style --foreround 212 'Derek's Vultr Arch Linux PostgREST Setup)."

MAIN_MENU(){
	if [[ $1 ]]
	then
		echo -e "\n$1"
	fi
	echo -e "\n~~~~~ Bike Rental Shop ~~~~~"
	echo -e "\n0. Database Management Menu\n1. Rent a Bike\n2. Return a Bike\n3. Exit Program\n"
	echo "Enter Command: "
	read MAIN_MENU_SELECTION
	case $MAIN_MENU_SELECTION in
	0) DATABASE_MANAGEMENT_MENU ;;
	1) RENT_MENU ;;
	2) RETURN_MENU ;;
	3) EXIT ;;
	*) MAIN_MENU "Please enter a valid option." ;;
esac
}

MAIN_MENU()

getuserandpass(){
	NAME=$(gum input --placeholder "First, please enter a name for the user account."
	while ! echo "$name" | grep -q "^[a-z_][a-z0-9_-]*$"; do
		name=$("Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _.")
	echo -e "Well, it is nice to meet you, $(gum style --foreground 212 "$NAME")."
done
esac
}

reinstall_neovim(){
## Uninstall
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
sudo pacman -Syu ttf-terminus-nerd
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim
}

init_database_management(){
sudo pacman -R vim
sudo pacman -Syu postgresql ufw go neovim
}

setup_postgresql(){
sudo pacman -Syu postgresql
su postgres
initdb --locale=C.UTF-8 --encoding=UTF8 -D /var/lib/postgres/data --data-checksums
exit
systemctl start postgresql
vim /var/lib/postgres/.psql_history
:wq
chown postgres /var/lib/postgres/.psql_history
}

set_user_install_yay(){
sudo useradd -m -G wheel $NAME
sudo EDITOR=vim visudo
su - $NAME
sudo pacman -Syu git
cd ~/
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
}

init_database_management()
getuserandpass()
set_user_install_yay(){
setup_postgresql()

sudo useradd -m -G wheel $NAME
sudo EDITOR=vim visudo
su - $NAME
sudo pacman -Syu git
cd ~/
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
}

sleep 1; clear

echo -e "Setting Timezome to: $(gum style --foreground 212 "America/Phoenix")."

timedatectl set-timezone America/Phoenix

echo -e "Successfully set Timezone to: $(gum style --foreground 212 "America/Phoenix")."

sleep 1; clear

sudo pacman -R vim
sudo pacman -Syu postgresql ufw go ttf-jetbrains-mono neovim