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

# require_relative 'util'
# require_relative 'story'
require 'highline/import'
require 'pivotal-tracker'
require 'active_support/core_ext/string'
require 'tracker_api'

# Utilities for dealing with +PivotalTracker::Person+s
class PivotalIntegration::Util::Person

#   def self.new(project)
#     # collect story estimate
#     # PivotalIntegration::Util::Story.estimate(story, PivotalIntegration::Command::Estimate.collect_estimation(@project))

#     # create story
#     project.create_story(name: name, story_type: type, estimate: estimate)
#   end

  def self.get_person_by_name(project, name)
    return nil if name.blank? || !(membership = project.memberships.detect{|m| m.person.name == name})
    membership.person
  end

  # Returns the current user's Pivotal Tracker user name for this repository.
  # If not yet configured, then prompts the user for their user name.
  # The value is checked for in the _inherited_ Git configuration, but is stored in the
  # _local_ Git configuration so that it is specific to this repository.
  def self.my_pivotal_tracker_user_name
    client = PivotalIntegration::Command::Configuration.api_client
    user_name = PivotalIntegration::Util::Git.get_config KEY_USER, :inherited

    if user_name.empty?
      projects = client.projects
      user_name = choose do |menu|
        menu.prompt = 'Choose your user name associated with this repository: '

        # TODO: return distinct names => `flatten.uniq.each do |person|`
        projects.map do |p|
          p.memberships.map do |m|
            menu.choice(m.person.name) {m.person.name}
          end
        end
      end

      PivotalIntegration::Util::Git.set_config KEY_USER, user_name.inspect, :global # was orig :local
    end

    user_name
  end

  KEY_USER = 'pivotal.user'.freeze
end
