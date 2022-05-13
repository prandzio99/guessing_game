# Guessing Game

This a simple number guessing game that we all know and love. The only difference is that this one has an extended/advanced user interface and some other additional features.

## Installation
All you have to do to setup the game is:
```
git clone git@github.com:prandzio99/guessing_game.git
cd guessing_game
./setup.sh
```
Then to play just type in:
```
./guess_extended.rb
```

### <span style="color:red; font-weight: bold">!!! In some cases setup.sh might not work !!!</span>
You can simply install ruby and required gems with these commands
```
sudo apt-get install ruby-full
sudo gem install colorize parseconfig
```

## Features
The game is a simple number guessing fun, by default in the range of 0 - 1000

As of now, the game has some modifiable settings through `game.cfg`.

There's also a scoreboard updated locally, that is - every time you input a different name in the game, a new record will appear.

### Planned features
- game statistics e.g. average number of attempts needed to guess
- multi-player gameplay (host player and additional player(s))
- scoreboards for different game settings
- GUI? maybe?

## Known bugs
1. Hints might not be accurate when it comes to how close you are to the solution.
2. After viewing scoreboard, first chosen option will always cause error that it's not supported, but the next choice will work as it should. Unless you press 'Enter', then it works as should.
