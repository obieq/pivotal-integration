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

# The class that encapsulates assigning current Pivotal Tracker Story to a user
class PivotalIntegration::Command::Assign < PivotalIntegration::Command::Base
  desc "Assign the current story to a user"

  # Assigns story to user.
  # @return [void]
  def run(*arguments)
    name = arguments.first
    person = getPersonByName(name) || choose_user

    PivotalIntegration::Util::Story.assign(story, person)
  end

  private

  def choose_user
    selected = choose do |menu|
      menu.prompt = 'Choose an user from above list: '

      project_member_names.each do |membership|
        menu.choice(membership)
      end
    end

    getPersonByName(selected)
  end

  def project_member_names
    @project.memberships.map{|m| m.person.name}
  end

  def getPersonByName(name)
    return nil if name.blank? || !(membership = @project.memberships.detect{|m| m.person.name == name})
    membership.person
  end
end
