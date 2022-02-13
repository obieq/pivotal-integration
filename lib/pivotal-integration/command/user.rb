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

# The class that encapsulates assigning current Pivotal Tracker Story to a user
class PivotalIntegration::Command::User < PivotalIntegration::Command::Base
  desc "Set your pivotal tracker user name in local .gitconfig file"

  def run(*arguments)
    user_name = PivotalIntegration::Util::Person.my_pivotal_tracker_user_name
    puts "\nPivotal Tracker User Name\n  #{user_name}\n\n"
  end



end
