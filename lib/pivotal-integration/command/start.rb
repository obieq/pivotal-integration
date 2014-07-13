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

require_relative 'base'
require 'pivotal-tracker'

# The class that encapsulates starting a Pivotal Tracker Story
class PivotalIntegration::Command::Start < PivotalIntegration::Command::Base
  desc "Start working on a story"

  # Starts a Pivotal Tracker story by doing the following steps:
  # * Create a branch
  # * Add default commit hook
  # * Start the story on Pivotal Tracker
  #
  # @param [String, nil] filter a filter for selecting the story to start.  This
  #   filter can be either:
  #   * a story id
  #   * a story type (feature, bug, chore)
  #   * +nil+
  # @return [void]
  def run(*arguments)
    filter = arguments.first
    use_current_branch = @options.fetch(:use_current, false)

    if filter == 'new'
      arguments.shift
      story = PivotalIntegration::Util::Story.new(@project, *PivotalIntegration::Command::New.collect_type_and_name(arguments))
    else
      story = PivotalIntegration::Util::Story.select_story @project, filter
    end

    if story.estimate.nil? or story.estimate == -1
      PivotalIntegration::Util::Story.estimate(story, PivotalIntegration::Command::Estimate.collect_estimation(@project))
    end

    PivotalIntegration::Util::Story.pretty_print story

    development_branch_name = development_branch_name story
    base_branch = PivotalIntegration::Util::Git.get_config_with_default 'pivotal.develop-branch', 'master'
    PivotalIntegration::Util::Git.switch_branch base_branch unless use_current_branch
    PivotalIntegration::Util::Git.create_branch development_branch_name
    @configuration.story = story

    PivotalIntegration::Util::Git.add_hook 'prepare-commit-msg', File.join(File.dirname(__FILE__), 'prepare-commit-msg.sh')

    start_on_tracker story
  end

  private

  def development_branch_name(story)
    branch_name = branch_prefix(story) + ask("Enter branch name (#{branch_prefix(story)}<branch-name>): ")
    puts
    branch_name
  end

  def branch_prefix(story)
    "#{story.id}-"
  end

  def start_on_tracker(story)
    print 'Starting story on Pivotal Tracker... '
    story.update(
      :current_state => 'started',
      :owned_by => PivotalIntegration::Util::Git.get_config('user.name')
    )
    puts 'OK'
  end

end
