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

require 'spec_helper'
require 'pivotal-integration/command/configuration'
require 'pivotal-integration/command/start'
require 'pivotal-integration/util/git'
require 'pivotal-integration/util/story'
require 'pivotal-tracker'

describe PivotalIntegration::Command::Start do

  before do
    # $stdout = StringIO.new
    # $stderr = StringIO.new

    @project = double('project')
    @story = double('story')
    PivotalIntegration::Util::Git.should_receive(:repository_root)
    PivotalIntegration::Command::Configuration.any_instance.should_receive(:api_token)
    PivotalIntegration::Command::Configuration.any_instance.should_receive(:project_id)
    PivotalTracker::Project.should_receive(:find).and_return(@project)
    @start = PivotalIntegration::Command::Start.new
  end

  it 'should run' do
    PivotalIntegration::Util::Story.should_receive(:select_story).with(@project, 'test_filter').and_return(@story)
    PivotalIntegration::Util::Story.should_receive(:pretty_print)
    @story.should_receive(:id).twice.and_return(12345678)
    @start.should_receive(:ask).and_return('development_branch')
    PivotalIntegration::Util::Git.should_receive(:create_branch).with('12345678-development_branch')
    PivotalIntegration::Command::Configuration.any_instance.should_receive(:story=)
    PivotalIntegration::Util::Git.should_receive(:add_hook)
    PivotalIntegration::Util::Git.should_receive(:get_config).with('pivotal.develop-branch', anything).and_return('master')
    PivotalIntegration::Util::Git.should_receive(:get_config).with('user.name').and_return('test_owner')
    @story.stub(:estimate).and_return 1
    @story.should_receive(:update).with(
      :current_state => 'started',
      :owned_by => 'test_owner'
    )

    @start.run 'test_filter'
  end
end
