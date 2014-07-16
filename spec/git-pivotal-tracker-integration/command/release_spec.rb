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
require 'pivotal-integration/command/release'
require 'pivotal-integration/util/git'
require 'pivotal-integration/util/story'
require 'pivotal-tracker'

describe PivotalIntegration::Command::Release do

  before do
    $stdout = StringIO.new
    $stderr = StringIO.new

    @project = double('project')
    PivotalIntegration::Util::Git.should_receive(:repository_root)
    PivotalIntegration::Command::Configuration.any_instance.should_receive(:api_token)
    PivotalIntegration::Command::Configuration.any_instance.should_receive(:project_id)
    PivotalTracker::Project.should_receive(:find).and_return(@project)
    @release = PivotalIntegration::Command::Release.new
  end

  it 'should run' do
    story = PivotalTracker::Story.new(:id => 12345678)
    updater = double('updater')
    PivotalIntegration::Util::Story.should_receive(:select_story).and_return(story)
    PivotalIntegration::Util::Story.should_receive(:pretty_print)
    PivotalIntegration::VersionUpdate::Gradle.should_receive(:new).and_return(updater)
    updater.should_receive(:supports?).and_return(true)
    updater.should_receive(:current_version).and_return('test_current_version')
    @release.should_receive(:ask).and_return('test_release_version')
    @release.should_receive(:ask).and_return('test_next_version')
    updater.should_receive(:update_version).with('test_release_version')
    PivotalIntegration::Util::Git.should_receive(:create_release_tag).with('test_release_version', story)
    updater.should_receive(:update_version).with('test_next_version')
    PivotalIntegration::Util::Git.should_receive(:create_commit).with('test_next_version Development', story)
    PivotalIntegration::Util::Git.should_receive(:branch_name).and_return('master')
    PivotalIntegration::Util::Git.should_receive(:push).with('master', 'vtest_release_version')

    @release.run(nil)
  end

end
