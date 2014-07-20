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

directory = File.expand_path("./pivotal-integration/command/*.rb", File.dirname(__FILE__))
Dir.glob(directory).each do |file|
  next if %w(base.rb command.rb configuration.rb runner.rb).include?(File.basename(file))
  require file
end

require_relative './pivotal-integration/command/runner'
