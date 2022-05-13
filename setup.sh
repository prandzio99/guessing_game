echo -en "Checking if ruby is installed... "

GREEN='\033[0;32m'
YELLOW='\033'
END='\033[0m'

if [ -f "/usr/bin/ruby" ]; then
    echo -en "${GREEN}OK.${END}\n"
else
    echo -en "${YELLOW}installing...${END}\n"
    sudo apt-get --assume-yes install ruby-full
fi
echo -en "Installed: "
ruby --version

echo -en "Checking if required gems installed...\n"
echo -en "Colorize... "
if [ $(gem list -i "^colorize$") == "true" ]; then
    echo -en "${GREEN}OK.${END}\n"
else
    echo -en "${YELLOW}installing...${END}\n"
    sudo gem install colorize
fi
echo -en "ParseConfig... "
if [ $(gem list -i "^parseconfig$") == "true" ]; then
    echo -en "${GREEN}OK.${END}\n"
else
    echo -en "${YELLOW}installing...${END}\n"
    sudo gem install parseconfig
fi

echo -en "${GREEN}Setup complete!${END}\n"