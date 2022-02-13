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

require_relative 'command'
require_relative 'configuration'
require_relative '../util/git'
require_relative '../util/person'
require_relative '../util/story'
require 'tracker_api'

# An abstract base class for all commands
# @abstract Subclass and override {#run} to implement command functionality
class PivotalIntegration::Command::Base
  # Common initialization functionality for all command classes.  This
  # enforces that:
  # * the command is being run within a valid Git repository
  # * the user has specified their Pivotal Tracker API token
  # * all communication with Pivotal Tracker will be protected with SSL
  # * the user has configured the project id for this repository
  def initialize(options = {})
    @options = options
    @repository_root = PivotalIntegration::Util::Git.repository_root
    @configuration = PivotalIntegration::Command::Configuration.new

    # @project = PivotalTracker::Project.find(@configuration.project_id)
    client = PivotalIntegration::Command::Configuration.api_client
    @project = client.project(@configuration.project_id)

    # set pivotal tracker user name if not already set
    PivotalIntegration::Util::Person.my_pivotal_tracker_user_name
  end

  # The main entry point to the command's execution
  # @abstract Override this method to implement command functionality
  def run(*arguments)
    raise NotImplementedError
  end

  def story
    if @options[:story_id]
      @configuration.project.stories.find(@options[:story_id])
    else
      @configuration.story
    end
  end

  class << self
    attr_reader :description

    def desc(text)
      @description = text
    end
  end
end
