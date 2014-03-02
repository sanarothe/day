#!/usr/bin/ruby

# Script File: day.rb
# Author: Cameron Carroll; Created July 2013
# Purpose: Main file for day.rb to-do & time tracking app.

require 'yaml'
require 'fileutils'

require_relative 'lib/baseconfig'
require_relative 'lib/config'
require_relative 'lib/history'
require_relative 'lib/list'
require_relative 'lib/task'
require_relative 'lib/parser'

VERSION = '1.9.1'



#-------------- User Configuration:
#-------------- Please DO edit the following to your liking:

# Configuration File: Stores tasks and their data
CONFIG_FILE = ENV['HOME'] + '/.config/dayrb/daytodo'
# History File: Technically unused, not sure if it's still in-scope for the project, pending possible removal.
#               But is supposed to keep track of task completion in the long-term.
HISTORY_FILE = ENV['HOME'] + '/.config/dayrb/daytodo_history'
# Colorization: 
# Use ANSI color codes...
# (See http://bluesock.org/~willg/dev/ansi.html for codes.)
# (Change values back to 0 for no colorization.)
COMPLETION_COLOR = 0 # -- Used for completion printouts
CONTEXT_SWITCH_COLOR = 0 # -- Used to declare `Enter/Exit Context'
STAR_COLOR = 0 # -- Used for the description indicator star
TITLE_COLOR = 0 # -- Used for any titles
TEXT_COLOR = 0 # -- Used for basically everything that doesn't fit under the others.
INDEX_COLOR = 0 # -- Used for the index key which refers to tasks.
TASK_COLOR = 0 # -- Used for task name in printouts.

# Flag used to configure main printout. Default is no description and an asterisk indicator instead.
#   :no_description  -- Shows asterisk in main printout when a task has a description.
#   :description     -- Actually prints out the whole description every time.
DESCRIPTION_FLAG = :no_description

# Flag to either print out new task list after a deletion or not.
PRINT_LIST_ON_DELETE = true

# Editor constant. Change to your preferred editor for adding descriptions.
EDITOR = 'vim'

#--------------

#[CUT HERE] -------------------------------------------------------------------

#-------------- Monkey-Patch Definitions:

class String
  def nan?
    self !~ /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/
  end

  def number?
    !self.nan?
  end

  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def color_completion
    colorize(COMPLETION_COLOR)
  end

  def color_context_switch
    colorize(CONTEXT_SWITCH_COLOR)
  end

  def color_star
    colorize(STAR_COLOR)
  end

  def color_title
    colorize(TITLE_COLOR)
  end

  def color_text
    colorize(TEXT_COLOR)
  end

  def color_index
    colorize(INDEX_COLOR)
  end

  def color_task
    colorize(TASK_COLOR)
  end
end

#-------------- Main control method:

def main

  opts = Parser.parse_options

  if opts[:chosen_context] && !opts[:delete]
    histclass = History.new(HISTORY_FILE)
    history_data = histclass.load
  end 

  config = Configuration.new(CONFIG_FILE)
  config_data = config.data

  # Generate list from configuration data:
  list = List.new(config_data[:tasks], config_data[:current_context], config_data[:context_entrance_time]);

  # Handle behaviors:
  if opts[:print]
    list.printout

  elsif opts[:chosen_context] && !opts[:delete]
    list.switch(config, histclass, opts[:chosen_context])

  elsif opts[:new_task]
    raise ArgumentError, "Duplicate task." if config_data[:tasks].keys.include? opts[:new_task]
    if opts[:valid_days]
      valid_days = Parser.parse_day_keys(opts)
    else
      valid_days = nil
    end
    config.save_task(opts[:new_task], valid_days, opts[:description], opts[:time], nil, [])

  elsif opts[:clear]
    if opts[:clear_context]
      task = list.find_task_by_number(opts[:clear_context])
      raise ArgumentError, "Invalid numerical index. (Didn't find a task there.)" unless task
      puts "Clearing fulfillment data for #{task.name}.".color_text
      list.clear_fulfillment(config, task.name)
    else
      puts 'Clearing all fulfillment data.'.color_text
      list.clear_fulfillment(config)
    end
    
  elsif opts[:delete]
    task = list.find_task_by_number(opts[:chosen_context])
    if task
      if list.current_context == opts[:chosen_context]
        raise ArgumentError, "Selected task is the one being timed! Are you sure you want to delete it? If so, check out and try again."
      else
        puts "Deleting task: ".color_title + "`#{task.name}'".color_text
        puts "Description was: ".color_title + "`#{task.description}'".color_text if task.description
        config.delete_task(task.name)
        list.load_tasks config.reload_tasks
        list.printout if PRINT_LIST_ON_DELETE
      end
    else
      raise ArgumentError, "There was no task at that index. (Selection was out of bounds.)"
    end

  elsif opts[:info]
    if opts[:info_context]
      task = list.find_task_by_number(opts[:info_context])
      if task.description
        list.print_description(task.name, task.description)
      else
        puts "(No description for #{task.name})".color_text
      end
    else
      list.print_descriptions
    end

  elsif opts[:help]
    list.print_help

  elsif opts[:version]
    list.print_version
  else
    raise ArgumentError, "There isn't a response to that command.  "
  end
end

main()
