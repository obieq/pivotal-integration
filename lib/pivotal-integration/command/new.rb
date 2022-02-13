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
require_relative '../util/person'
require 'highline/import'

# The class that encapsulates starting a Pivotal Tracker Story
class PivotalIntegration::Command::New < PivotalIntegration::Command::Base
  desc "Create a new story"

  STORY_TYPES = %w(feature bug chore release)
  def run(*arguments)
    options = self.class.collect_type_and_name(@configuration.project, arguments)

    puts
    print 'Creating new story on Pivotal Tracker... '
    PivotalIntegration::Util::Story.new(@configuration.project, *options)
    puts 'OK'
  end

  class << self
    def collect_type_and_name(project, arguments)
      type = STORY_TYPES.include?(arguments.first.try(:downcase)) ? arguments.shift : choose_type
      type = type.downcase.to_sym

      name = arguments.shift || ask('Provide a name for the new story: ')
      estimate = arguments.shift || adapt_estimate_for_api_validation_rules(project)
      person = PivotalIntegration::Util::Person.get_person_by_name(project, choose_owner_name(project, arguments.shift))

      [name, type, estimate, person]
    end

  private

    def adapt_estimate_for_api_validation_rules(project)
      estimate = PivotalIntegration::Command::Estimate.collect_estimation(project).to_i
      estimate > -1 ? estimate : nil # api requires null value if no estimate, i.e., user hit `enter` for none
    end

    def choose_type
      choose do |menu|
        menu.prompt = 'What type of story do you want to create: '
        STORY_TYPES.each { |type| menu.choice(type.titleize) }
      end
    end

    def choose_owner_name(project, owner_name)
      if (!owner_name)
        owner_name = choose do |menu|
          menu.prompt = 'Assign Owner'
          menu.prompt = 'Select an owner from above list: '
          menu.choice('None') {'None'}
          project.memberships.map do |member|
              menu.choice(member.person.name) {member.person.name}
          end
        end
      end

      owner_name
    end
  end
end
