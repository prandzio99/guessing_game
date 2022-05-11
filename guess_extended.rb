#!/usr/bin/env ruby

# lvl 1 - simple guessing game ... DONE
# lvl 2 - play again ... DONE
# lvl 3 - temporary scoreboard ... PASSED
# lvl 4 - scoreboard in file "Hall of Fame" ... DONE
# lvl 5 - config files ... DONE
# lvl 6 - in-game menu and accessible options (config) ... WIP
# lvl 7 - colors ... DONE
# lvl 8 - clean code
# lvl 9 - statistics
# lvl 10 - ghost player program ... 
# lvl 11 - GUI ... 

# gem includes
require 'rubygems'
require 'parseconfig'
require 'colorize'
require 'io/console'


# log constants
ERROR   = "[ERROR]".white.on_red + " "
WARNING = "[WARN]".black.on_yellow + "  "
SUCCESS = "[OK]".white.on_green + "    "
LOG     = "[LOG]" + "   "


# date formatters
DATE_FORMAT     = "%Y/%m/%d %H:%M:%S"
LOG_DATE_FORMAT = "%Y%m%d_%H%M%S"


# error module
module ERR
    module BASE
        module GENERAL
            INTERRUPT   = 0x000101
        end
    end
    module LOAD
        module CONFIG
            NO_FILE     = 0x010101
        end
        module SCOREBOARD
            NO_FILE     = 0x010201
        end
    end
    module MAIN
        module MENU
            CASE_SLIP   = 0x020101
        end
        module GAME
        end
    end
    TBD = 0xFFFFFF
end


# globals
$config = nil
$scoreboard = nil
$session_start = Time.now.strftime LOG_DATE_FORMAT
$debug = false
$hidden_range_start = 0
$hidden_range_end = 1000


#-------------------------------------------------
# Name:     log
# Input:    String, String, String
# Output:   none
# Description:
#   Logging function, works if $debug is true
#-------------------------------------------------
def log type, called_from, message
    time_logged = Time.now.strftime DATE_FORMAT
    logged_msg = "#{type}#{time_logged} in function \"#{called_from}\": #{message}"

    File.open("game_#{$session_start}.log", mode: "a") {
        |log_file| log_file.write("#{logged_msg}\n")
    }
    
    if $debug
        puts logged_msg
    end
        
    nil
end


#-------------------------------------------------
# Name:     clear_screen
# Input:    none
# Output:   none
# Description:
#   Clears terminal if not debugging
#-------------------------------------------------
def clear_screen
    if not $debug
        system("clear")
        log LOG, __method__, "terminal cleared"
    end
    nil
end


#-------------------------------------------------
# Name:     parse_exit_code
# Input:    Integer
# Output:   String
# Description:
#   Takes hexadecimal exit (error) code and parses
#   it into human-readable string
#-------------------------------------------------
def parse_exit_code exit_code
    err_class = exit_code / 0x10000
    err_major = exit_code % 0x10000 / 0x100
    err_minor = exit_code % 0x10
    
    return "class = 0x%02X, major = 0x%02X, minor = 0x%02X" \
    % [err_class, err_major, err_minor]
end


#-------------------------------------------------
# Name:     safe_exit
# Input:    none
# Output:   none
# Description:
#   Performs clean exit, returns exit code.
#-------------------------------------------------
def safe_exit exit_code=0
    clear_screen
    case exit_code
    when 0
        log SUCCESS, __method__, "clean exit"
    when ERR::BASE::GENERAL::INTERRUPT
        log WARNING, __method__, "#{parse_exit_code exit_code}"
    else
        log ERROR, __method__,  "#{parse_exit_code exit_code}"
    end
    exit exit_code
end


#-------------------------------------------------
# Name:     load_config
# Input:    none
# Output:   none
# Description:
#   Utility function loading config into global
#   variable for later access
#-------------------------------------------------
def load_config
    log LOG, __method__, "initialized"
    
    begin
        $config = ParseConfig.new 'game.cfg'
    rescue
        log ERROR, __method__, "config file unreadable or not found"
        safe_exit ERR::LOAD::CONFIG::NO_FILE
    end
    log SUCCESS, __method__, "succesfully parsed"
    
    if $config['debug'] == 'yes'
        log LOG, __method__, "debug traces on"
        $debug = true
    end

    if $config['hidden_range_start'].to_i != 0
        $hidden_range_start = $config['hidden_range_start'].to_i
    end

    if $config['hidden_range_end'].to_i != 1000
        $hidden_range_end = $config['hidden_range_end'].to_i
    end
    
    log SUCCESS, __method__, "loaded successfully"
    nil
end


#-------------------------------------------------
# Name:     load_scoreboard
# Input:    none
# Output:   Integer
# Description: 
#   Utility function reading scoreboard from
#   scoreboard.dat file and returning it
#   in form of a dictionary
#-------------------------------------------------
def load_scoreboard
    log LOG, __method__, "initialized"
    
    $scoreboard = Hash.new 0
    log SUCCESS, __method__, "scoreboard clear"

    if File.exists? "scoreboard.db"
        log LOG, __method__, "found scoreboard file"

        begin
            file = File.open "scoreboard.db", "r"
        rescue
            log ERROR, __method__, "failed to read-open file"
            safe_exit ERR::LOAD::SCOREBOARD::NO_FILE
        end
        log SUCCESS, __method__, "scoreboard file opened"
        
        file.readlines.map(&:chomp).each do |line|
            player, score = line.split
            $scoreboard[player] = score.to_i
        end
        log SUCCESS, __method__, "scoreboard file loaded into memory"

        file.close
        log SUCCESS, __method__, "file closed"
    else
        log LOG, __method__, "no scoreboard file to load"
    end

    log LOG, __method__, "scoreboard size : #{$scoreboard.size}"
    return $scoreboard.size
end


#-------------------------------------------------
# Name:     save_scoreboard
# Input:    Hash
# Output:   none
# Description:
#   Utility function saving ascendingly sorted
#   scoreboard Hash into scoreboard.dat file
#   line by line, returns file size on success,
#   -1 on failure
#-------------------------------------------------
def save_scoreboard
    $scoreboard = $scoreboard.sort_by {|k, v| v}.to_h
    log LOG, __method__, "scoreboard sorted"

    begin
        File.open("scoreboard.db", mode: "w") {
            |log_file| 
            $scoreboard.each do |k, v|
                log_file.write "#{k} #{v}\n"
            end
        }
        log SUCCESS, __method__, "scoreboard saved successfully"
    rescue
        log WARNING, __method__, "failed to save scoreboard"
    end
    nil
end


#-------------------------------------------------
# Name:     save_record
# Input:    Hash, String, Integer
# Ouput:    none
# Description:
#   Utility function saving player's number of
#   tries into the scoreboard; also checks whether
#   the player has already played and if they beat
#   their current record
#
#   DISCLAIMER: if the player has already played,
#   then their move will only be saved if they
#   beat their record
#-------------------------------------------------
def save_record player_name, tries
    if $scoreboard.key? player_name
        if $scoreboard[player_name] > tries
            log LOG, __method__, "player \"#{player_name}\" beat their record, saving"
            puts "You beat your previous record by " + ($scoreboard[player_name] - tries).to_s + " tries!"
            $scoreboard[player_name] = tries
        end
    else
        log LOG, __method__, "player \"#{player_name}\" not yet on the scoreboard, saving"
        $scoreboard[player_name] = tries
    end
    nil
end


#-------------------------------------------------
# Name:     validate_guess
# Input:    Integer, Integer
# Output:   Boolean
# Description:
#   Check if player guessed the hidden number or
#   notify whether it was close
#-------------------------------------------------
def validate_guess guess, hidden
    fraction = ($hidden_range_end - $hidden_range_start) / 5
    log LOG, __method__, "fractions set as #{fraction}"

    difference = hidden - guess

    case
    when difference == 0
        log LOG, __method__, "player guessed the hidden number"
        puts "You guessed it!".green
        return true
    when difference < fraction
        if difference > 0
            log LOG, __method__, "player chose too low, close"
            puts "You're close! Too low!".yellow
        else
            log LOG, __method__, "player chose too high, close"
            puts "You're close! Too high!".yellow
        end
    when difference > fraction
        if difference > 0
            log LOG, __method__, "player chose too low"
            puts "Too low!".red
        else
            log LOG, __method__, "player chose too high, close"
            puts "Too high!".red
        end
    else
        # we shouldn't reach here, wtf?
        log ERROR, __method__, "guess validation fail"
        safe_exit ERR::TBD
    end

    return false
end


#-------------------------------------------------
# Name:     play_game
# Input:    none
# Output:   none
# Description:
#   Game logical flow
#-------------------------------------------------
def play_game
    log LOG, __method__, "starting the game"
    loop do
        clear_screen
        print "Your name: "
        player_name = gets.chomp
        log LOG, __method__, "player name registered : #{player_name}"
        tries = 0

        hidden = rand($hidden_range_start..$hidden_range_end)
        log LOG, __method__, \
        "hidden number generated within range #{$hidden_range_start}-#{$hidden_range_end}"

        loop do
            tries += 1
            log LOG, __method__, "trial nr #{tries}"
            print "Your guess: "
            guess = gets.to_i
            log LOG, __method__, "player guessed : #{guess}"

            if validate_guess guess, hidden
                break
            end
        end

        puts "You did it in #{tries} tries!"
        log LOG, __method__, "player succeeded in #{tries} tries"

        save_record player_name, tries
        save_scoreboard

        print "Do you want to play again? [Y/n] "
        if not ['Y', 'y'].include? gets.chomp
            log LOG, __method__, "player chose to stop playing"
            break
        end
        log LOG, __method__, "restarting the game"
    end

    print "Do you want to exit the game? [Y/n] "
    if ['Y', 'y'].include? gets.chomp
        log LOG, __method__, "player chose to quit the game"
        safe_exit
    else
        log LOG, __method__, "returning to the main menu"
        menu
    end
    nil
end


#-------------------------------------------------
# Name:     show_scoreboard
# Input:    none
# Output:   none
# Description:
#   Display X top scorers
#   X set in config
#-------------------------------------------------
def show_scoreboard
    clear_screen

    nr_pos = $config['sb_rec_nr'].to_i > $scoreboard.size \
            ? $scoreboard.size \
            : $config['sb_rec_nr'].to_i
    
    $scoreboard = $scoreboard.sort_by {|k, v| v}.to_h
    
    puts "pos |#{" player".ljust 32}| tries".yellow
    
    for i in 1..nr_pos do
        puts "#{i.to_s.ljust(4).cyan}| #{$scoreboard.keys[i-1].ljust 31}| #{$scoreboard.values[i-1].to_s.green}"
    end
    
    print "=> press any key to return to main menu"
    
    STDIN.getch
    
    clear_screen
    
    menu
    nil
end


#-------------------------------------------------
# Name:     show_statistics_menu
# Input:    none
# Output:   none
# Description:
#   Display game statistics menu
#-------------------------------------------------
def show_statistics_menu
    menu
end


#-------------------------------------------------
# Name:     show_options_menu
# Input:    none
# Output:   none
# Description:
#   Display game options menu
#-------------------------------------------------
def show_options_menu
    menu
end


#-------------------------------------------------
# Name:     menu
# Input:    none
# Output:   none
# Description:
#   Displays game's menu and lets user choose the
#   desired option
#-------------------------------------------------
def menu
    log LOG, __method__, "game menu open"
    choice = 0
    error = ""
    loop do
        clear_screen
        print error
        puts "==================================".blue
        puts "Guessing Game!".yellow
        puts "==================================".blue
        puts "1) Play".green
        puts "2) Scoreboard"
        puts "3) Statistics"
        puts "4) Options"
        puts "5) Exit".red
        print "=> ".yellow
        log LOG, __method__, "menu in display"
        choice = gets.chomp.to_i
        log LOG, __method__, "received user input : #{choice}"
        if [1, 2, 5].include? choice
            break
        end
        error = "!!! This menu option is not supported !!!\n\n".red
        log WARNING, __method__, "bad input -- menu option not supported"
    end

    case choice
    when 1
        # play the game
        log LOG, __method__, "user chose option \"Play\""
        play_game
    when 2
        # show the top X lowest scores
        log LOG, __method__, "user chose option \"Scoreboard\""
        show_scoreboard
    when 3
        # show game statistics
        log LOG, __method__, "user chose option \"Statistics\""
        show_statistics_menu
    when 4
        # display and change options
        log LOG, __method__, "user chose option \"Options\""
        show_options_menu
    when 5
        # exit the game
        log LOG, __method__, "user chose option \"Exit\""
        safe_exit
    else
        # we shouldn't reach here, wtf?
        log ERROR, __method__, "somehow choice broke the loop?"
        safe_exit ERR::MAIN::MENU::CASE_SLIP
    end
    nil
end


#-------------------------------------------------
# Name:     main
# Input:    none
# Output:   none
# Description:
#   Main process
#-------------------------------------------------
def main
    load_config
    load_scoreboard
    menu
    nil
end


# entry point
begin
    main
rescue Interrupt
    safe_exit ERR::BASE::GENERAL::INTERRUPT
end
