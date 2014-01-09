# Check for non-interactive shell.
# =============================================================================
[ -z "$PS1" ] && return


# Start / restore a screen session at login.
# =============================================================================
# only if via ssh, not already a screen session and not root.
if [ -z "$STY" ] && [ -n "$SSH_TTY" ] && [ "${UID}" != 0 ]; then
	screen -dR
fi

# Terminal colours.
# =============================================================================
clrRed="$(tput setf 4)"		# Red
clrWhite="$(tput setf 7)"	# White
clrGreen="$(tput setf 2)"	# Green
clrPurple="$(tput setf 5)"	# Purple
clrReset="$(tput sgr 0)"	# Reset all colour.
clrGrey="$(tput setf 7)"	# Grey

# =============================================================================
# INTERNAL FUNCTIONS
# =============================================================================

# osPlatform - Get the platform (Linux, Darwin, etc)
# Usage: osPlatform
# =============================================================================
osPlatform()
{
	OS_PLATFORM=$(uname)	
	echo $OS_PLATFORM
}

# osProcessor - Get the processor type (x86, x86_64, sparc)
# Usage: osProcessor
# =============================================================================
osProcessor()
{
	OS_PROCESSOR=$(uname -p)	
	echo $OS_PROCESSOR
}

# osVersion - Get the name of the OS (Mac OSX, Ubuntu, Debian etc)
# Usage: osVersion
# =============================================================================
osVersion()
{
	OS_PLATFORM=$(osPlatform);
	
	if [ $OS_PLATFORM = 'Linux' ]; then
	        OS_NAME=$(lsb_release -i | cut -f 2)
	elif [ $OS_PLATFORM = 'Darwin' ]; then
	        OS_NAME=$(sw_vers -productName)
	else
	        OS_NAME='Unknown'
	fi
	echo $OS_NAME	
}

# exists - Is file in path?
# Usage: exists <binary>
# =============================================================================
exists()
{
        if type -P $1 > /dev/null 2>&1 ; then
                return 0;
        else
                return 1;
        fi
}

# Pretty status message.
# Usage: statusMessage <Message> <optional: completion status>
# =============================================================================
statusMessage()
{
	# User configurable options.
	messageDecoration="${clrGreen} [${clrRed}+${clrGreen}]${clrReset} " # Decoration to add before printed message.

	message=$messageDecoration$1
	status=$2

	messageClean=$(echo $message | sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g")
	messageLen=$(( ${#messageClean} -3 ))

	# If we've not been given a status, just print message.
	if [[ -z "$status" ]] ; then 
		echo ${message}
	# We've got a status to print.
	else
 
		# Are we printing success, or failure?
		if $status ; then
			statusMessage="${clrGreen}Done ${clrReset}"
		else
			statusMessage="${clrRed}Failed ${clrReset} "
		fi
		statusMessageClean=$( echo $statusMessage | sed -r "s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" )
		statusMessageLen=$(( ${#statusMessageClean} -3 ))

		termWidth=$(tput cols) # Terminal width
		
		# Get the ammount of padding to add in.
		fillsize=$(($termWidth - $messageLen - $statusMessageLen))

		tput cuu1 # Move the cursor up one line.

		printf "%s%${fillsize}s%s\n" "$message" ' ' "$statusMessage"
	fi
}

# =============================================================================
# SETUP SHELL
# =============================================================================

# Global Aliases
# =============================================================================
alias wtf="watch -n 1 w -hs"
alias cls="clear"
alias starwars="telnet towel.blinkenlights.nl"
alias grep="grep --color=always -i"

# History settings.
# =============================================================================
shopt -s histappend
# Clear console on logout.
trap clear 0

# If local path is available, use it.
# =============================================================================
if [ -d ~/bin ]; then
	OS_PROCESSOR=$(osProcessor);
	OS_PLATFORM=$(osPlatform);
	export PATH=$PATH:~/bin/$OS_PLATFORM/$OS_PROCESSOR
	export LD_LIBRARY_PATH=~/bin/$OS_PLATFORM/$OS_PROCESSOR
fi

# Test if some useful packages are available to us.
# =============================================================================
exists wget
EXISTS_WGET=$?
exists curl
EXISTS_CURL=$?

# Welcome screen - Show me a nice friendly screen when I login (except for when root).
# =============================================================================
#if [ ${UID} != 0 ]; then
	# Display some info.
#	echo -ne "${clrGreen}System:     ${clrRed}"
#	uname -smr
#	echo -e "${clrGreen}Hostname:   ${clrRed}${HOSTNAME}${clrReset}"
#fi

# Platform specific setup. 
# =============================================================================
OS_PLATFORM=$(osPlatform)
if [ $OS_PLATFORM == 'Darwin' ]; then
	# Enable full path in Finder title bar.
	defaults write com.apple.finder _FXShowPosixPathInTitle -bool YES
	
	# Enable Web Inspector in Safari.
	defaults write com.apple.Safari WebKitDeveloperExtras -bool true

	# Enable nice colours for Darwin ls
	# Darwin doesn't have nice ls colours like GNU ls =(
	export CLICOLOR=1
	export LSCOLORS=ExFxCxDxBxegedabagacad
	
	# Path for GNU binaries on macbook.
	export PATH=$PATH:/opt/local/bin
elif [ $OS_PLATFORM == 'Linux' ]; then
	# Enable nice colours for ls.
	eval "`dircolors -b`"
	alias ls='ls -lah --color=auto'
elif [ $OS_PLATFORM == 'SunOS' ]; then
	alias ls='ls -lah'
	
	# No colorized grep by default on Solaris :(
	unalias grep

	# Solaris cheat sheet.
	echo -e "${clrRed}To restart inetd:${clrReset}"
	echo -e "${clrGrey}	# pkill -HUP inetd${clrReset}"
	echo -e "${clrRed}Solaris Update Info:${clrReset}"
	echo -e "${clrGrey}	# smpatch analyze	Check for updates.${clrReset}"
	echo -e "${clrGrey}	# smpatch update	Install pending updates.${clrReset}"
	echo -e "${clrRed}To register a system for updates:${clrReset}"
	echo -e "${clrGrey}	# cacaoadm stop		Stops update service.${clrReset}"
	echo -e "${clrGrey}	# cacaoadm status	Checks service status.${clrReset}"
	echo -e "${clrRed}Erase update repo:${clrReset}"
	echo -e "${clrGrey}	# /usr/lib/cc-ccr/bin/eraseCCRRepository${clrReset}"
	echo -e "${clrGrey}	# rm /var/scn/persistence/SCN*${clrReset}"
	echo -e "${clrGrey}	# cacaoadm start	Starts service.${clrReset}"
fi

# Custom Prompt - Green for user, red for root.
# =============================================================================
if [ ${UID} -eq 0 ]; then
	export PS1="\[$clrPurple\][ \[$clrReset\]\u@\h \[$clrGreen\]\w\[$clrPurple\] ]\[$clrRed\]#\[$clrReset\] "
else
	# Here we need to add \[ before the colours and \] after so that bash
	# doesn't treat the escape sequences as part of its column counting.
	export PS1="\[$clrPurple\][ \[$clrReset\]\u@\h \[$clrGreen\]\w\[$clrPurple\] ]\$\[$clrReset\] "
fi


# =============================================================================
# PUBLIC FUNCTIONS
# =============================================================================

# PublicIP - Display public IP address.
# Usage: PublicIP
# =============================================================================
PublicIP()
{
	# Use wget if available, otherwise fall back to curl.
	if [ $EXISTS_WGET ]; then
		wget -q -O - "http://whatismyip.com/automation/n09230945.asp" | egrep -o '[0-9.]+'
	elif [ $EXISTS_CURL ]; then
		curl -s "http://whatismyip.com/automation/n09230945.asp" | egrep -o '[0-9.]+'
	else
		echo 'Fatal Error: Both curl and wget are unavailable'
	fi
}


# configGet - Download latest shell configuration files.
# =============================================================================
configGet()
{
	cfgDotRoot="$HOME/.dotfiles"
	cfgGitRepo="https://github.com/davehope/dotfiles.git"

	statusMessage "Cloning configuration from Git"
	if [ ! -d "$cfgDotRoot" ]; then
		# No local repo, create one.
		git clone $cfgGitRepo $cfgDotRoot > /dev/null 2>&1
	else
		# Update existing repo.
		cd $cfgDotRoot && git pull > /dev/null 2>&1 && cd 
	fi
	if [ $? == 0 ]; then
		statusMessage "Cloning configuration from Git" true
	else
		statusMessage "Cloning configuration from Git" false
		statusMessage "Downloading files using wget"
		if [ $EXISTS_WGET ]; then
			wget -q https://raw2.github.com/davehope/dotfiles/master/.bashrc -O $cfgDotRoot/.bashrc
			wget -q https://raw2.github.com/davehope/dotfiles/master/.screenrc -O $cfgDotRoot/.screenrc
			wget -q https://raw2.github.com/davehope/dotfiles/master/.vimrc -O $cfgDotRoot/.vimrc
			mkdir -p $cfgDotRoot/vim/colors
			wget -q https://raw2.github.com/davehope/dotfiles/master/.vim/colors/vim-colors.vim -O $cfgDotRoot/.vim/colors/vim-colors.vim
			statusMessage "Downloading files using wget" true
		else
			curl -s https://raw2.github.com/davehope/dotfiles/master/.bashrc -o $cfgDotRoot/.bashrc
			curl -s https://raw2.github.com/davehope/dotfiles/master/.screenrc -o $cfgDotRoot/.screenrc
			curl -s https://raw2.github.com/davehope/dotfiles/master/.vimrc -o $cfgDotRoot/.vimrc
			mkdir -p $cfgDotRoot/vim/colors
			curl -s https://raw2.github.com/davehope/dotfiles/master/.vim/colors/vim-colors.vim -o $cfgDotRoot/.vim/colors/vim-colors.vim
			statusMessage "Downloading files using wget" true
		fi
	fi

	statusMessage "Creating symlinks"
	# Iterate over config files downloaded and create links
	for f in `find $cfgDotRoot -maxdepth 3 -not -path "$cfgDotRoot/.git*"`
	do
		dest=$HOME/${f##*${cfgDotRoot}/}

		# Skip the $cfgDotRoot directory and any readme file.
		if [ $f == $cfgDotRoot ] || [ $f == "$cfgDotRoot/README.md" ] ; then
			continue
		fi

		# If this a directory, create it rather than create a link.
		if [ -d $f ]; then
			mkdir -p $dest
		else
			# If the destination file already exists, remove it.
			if [ -f $dest ] && [ ! -h $dest ]; then
				mv $dest $dest.old
			fi
			# If the symlink exists, unlink it.
			if [ -h $dest ]; then
				unlink $dest
			fi
			# Link the config file to our git repo
			ln -s $f $dest
		fi
	done
	statusMessage "Creating symlinks" true

	# Download local bin directory?
	read -p "Download local bin directory (y/n) ? "
	if [ "$REPLY"  = 'y' ]; then
		if [ $EXISTS_WGET ]; then
			wget -q "${CONFURL}bin.tar" -O ~/bin.tar
		elif [ $EXISTS_CURL ]; then
			curl -s "${CONFURL}bin.tar" -o ~/bin.tar
		else
			echo 'Fatal Error: Both curl and wget are unavailable'
		fi

		# Extract bin and remove download.
		cd ~
		tar xf ~/bin.tar
		rm -f ~/bin.tar
		cd - > /dev/null
	fi

	# Reset terminal.
	read -p "Reset terminal and use new .bashrc (y/n) ? "
	if [ "$REPLY"  = 'y' ]; then
		source ~/.bashrc
	fi
}


# downloads the latest backup of my website using the cpanel backup stuff.
# =============================================================================
cpanelBackup()
{
	# URL to backup.
	read -p "Domain "
	websiteURL=$REPLY;
	
	# Get username
	read -p "Username "
	confUser=$REPLY;

	# Get password.
	stty -echo
	read -p "Password "
	stty echo
	confPass=$REPLY;
	
	wget --http-user=$confUser --http-password=$confPass http://$websiteURL:2082/getbackup/$websiteURL-`date +"%Y.%m.%d"`.tar.gz
}

setupSSH()
{
	read -p "System to copy keys to (user@host): "
	ssh $REPLY 'cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_dsa.pub
}

flac2alac()
{
	for i in *.flac; do
		ffmpeg -i "$i" -acodec alac "`basename "$i" .flac`.m4a";
	done;
}

wav2alac()
{
	for i in *.wav; do
		ffmpeg -i "$i" -acodec alac "`basename "$i" .wav`.m4a";
	done;
}


# Allow local overrides to this file in bashrc.locl 
# =============================================================================
if [ -f "$HOME/.bashrc.local" ]; then
	. $HOME/.bashrc.local
fi

