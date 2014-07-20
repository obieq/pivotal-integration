#!/usr/bin/env ruby -U
# Git Pivotal Tracker Integration
# Copyright (c) 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'active_support'
require 'active_support/core_ext/string'

class PivotalIntegration::CommandRunner
  COMMANDS = ObjectSpace.each_object(Class).select { |klass| klass < PivotalIntegration::Command::Base }
  COMMAND_NAMES = COMMANDS.map{|c|c.name.demodulize.downcase}
  MAX_COMMAND_LEN = COMMAND_NAMES.map(&:length).max

  class << self
    def print_command_help(commands)
      commands.each do |command|
        puts "  %-#{MAX_COMMAND_LEN}s   %s" % [command.name.demodulize.downcase, command.description]
      end
    end

    def show_help
      puts "Usage: pivotal [--help] <command> [<args>]"
      puts

      main_commands = COMMANDS.select{ |c| %w(start finish new).include? c.name.demodulize.downcase }
      secondary_commands = COMMANDS - main_commands

      puts "Main Commands"
      print_command_help(main_commands.sort_by{ |c| %w(new start finish).index(c.name.demodulize.downcase) })

      puts
      puts "Secondary Commands:"
      print_command_help(secondary_commands.sort_by(&:name))
    end

    def run
      begin
        if COMMAND_NAMES.include?(ARGV.first.try(:downcase))
          command = ARGV.shift.downcase

          options = {}
          optparse = OptionParser.new do |opts|
            opts.on('-h', '--help') do
              show_help
              exit
            end

            opts.on('-S', '--story ID') do |id|
              options[:story_id] = id
            end

            if command == 'start'
              opts.on('--use-current') do
                options[:use_current] = true
              end
            end

            if command == 'finish'
              opts.on('--pull-request') do
                options[:pull_request] = true
              end

              opts.on('--no-complete') do
                options[:no_complete] = true
              end

              opts.on('--no-delete') do
                options[:no_delete] = true
              end

              opts.on('--no-merge') do
                options[:no_merge] = true
              end
            end
          end
          optparse.parse!

          command_class = PivotalIntegration::Command.const_get(command.classify)
          command_class.new(options).run(*ARGV)

        elsif ARGV.empty?
          show_help

        else
          abort "Invalid command #{ARGV.first}."
        end

      rescue Interrupt
        puts
        puts "Operation cancelled."
        exit
      end
    end
  end
end
