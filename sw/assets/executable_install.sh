#!/bin/bash

function brew_shellenv() {
	if [[ -d "${HOME}/homebrew" ]]; then
		eval "$("${HOME}"/homebrew/bin/brew shellenv)"
	else
		if [[ ${OSTYPE} == "darwin"* ]]; then
			test -d /opt/homebrew && eval "$(/opt/homebrew/bin/brew shellenv)"
			test -f /usr/local/bin/brew && eval "$(/usr/local/bin/brew shellenv)"
		else
			test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		fi
	fi
}

cd "${HOME}" || exit

echo "Do you want to use the system's homebrew? (recommended) [Y/n]"
read -r answer
if [ "$answer" = "n" ]; then
	echo "Installing local homebrew..."
	mkdir homebrew
	curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
else
	rm -rf ~/homebrew
	echo "Installing system homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew_shellenv

brew install gh
brew install chezmoi
brew install zsh
brew install gum

if ! grep -q "$(which zsh)" /etc/shells; then
	echo "Adding $(which zsh) to /etc/shells"
	sudo sh -c "echo $(which zsh) >> /etc/shells"
fi
chsh -s "$(which zsh)"

echo "Authenticating with GitHub. Please make sure to choose ssh option for authentication."

gh auth login -p ssh

if [ -d "$HOME"/.git ]; then
	echo "Backing up $HOME/.git to $HOME/.git.bak"
	mv "$HOME"/.git "$HOME"/.git.bak
fi

echo "Setting up .gitconfig_local"

email=$(gum input --placeholder "Please enter your email address")
name=$(gum input --placeholder "Please enter your name")

echo "[user]" >"$HOME"/.gitconfig_local
echo "  name = $name" >>"$HOME"/.gitconfig_local
echo "  email = $email" >>"$HOME"/.gitconfig_local

chezmoi init git@github.com:moojok/dotfiles.git
chezmoi apply -v

echo "Running autoupdate script..."
~/sw/bin/executable_autoupdate.zsh --force

if [ $? -ne 0 ]; then
	echo "Failed to run autoupdate script"
	exit 1
fi

echo "Restarting computer..."
sudo reboot
