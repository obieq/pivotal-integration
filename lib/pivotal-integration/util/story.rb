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
require_relative 'git'
require_relative 'person'
require 'highline/import'
require 'pivotal-tracker'
require 'active_support/core_ext/string'
require 'tracker_api'

# Utilities for dealing with +PivotalTracker::Story+s
class PivotalIntegration::Util::Story

  def self.new(project, name, type, estimate, person)
    # collect story estimate
    # PivotalIntegration::Util::Story.estimate(story, PivotalIntegration::Command::Estimate.collect_estimation(@project))

    # create story
    owner_ids = person ? [person.id] : []
    project.create_story(name: name, story_type: type, estimate: estimate, owner_ids: owner_ids)
  end

  # Print a human readable version of a story.  This pretty prints the title,
  # description, and notes for the story.
  #
  # @param [PivotalTracker::Story] story the story to pretty print
  # @return [void]
  def self.pretty_print(story)
    client = PivotalIntegration::Command::Configuration.api_client

    print_label 'ID'
    print_value story.id

    print_label 'Project'
    project = client.project(story.project_id)
    print_value project.name

    print_label LABEL_TITLE
    print_value story.name

    description = story.description
    if !description.nil? && !description.empty?
      print_label 'Description'
      print_value description
    end

    print_label 'Type'
    print_value story.story_type.titlecase

    print_label 'State'
    print_value story.current_state.titlecase

    print_label 'Estimate'
    print_value story.estimate == -1 ? 'Unestimated' : story.estimate

    memberships = project.memberships
    requestor = memberships.detect{|m| m.person.id == story.requested_by_id}

    print_label 'Requestor'
    print_value requestor.person.name

    owner_names = []
    print_label 'Owners'
    story.owner_ids.each do |owner_id|
      owner = memberships.detect{|m| m.person.id == owner_id}
      owner_names << owner.person.name
    end

    print_value owner_names.join(', ')

    comment_api = TrackerApi::Endpoints::Comments.new(client)
    comments = comment_api.get(project.id, story_id: story.id)

    comments.sort_by { |comment| comment.created_at }.each_with_index do |comment, index|
      print_label "Comment #{index + 1}"
      print_value comment.text
    end

    puts
  end

  # Assign story to pivotal tracker member.
  #
  # @param [PivotalTracker::Story] story to be assigned
  # @param [PivotalTracker::Member] assigned user
  # @return [void]
  def self.assign(story, person)
    story.add_owner(person.id)
    puts "Story assigned to #{person.name}" if story.save
  end

  # Marks Pivotal Tracker story with given state
  #
  # @param [PivotalTracker::Story] story to be assigned
  # @param [PivotalTracker::Member] assigned user
  # @return [void]
  def self.mark(story, state)
    puts "Changed state to #{state}" if story.update(current_state: state)
  end

  def self.estimate(story, points)
    story.estimate = points
    story.save
  end

  def self.add_comment(story, comment)
    story.notes.create(text: comment)
  end

  # Selects a Pivotal Tracker story by doing the following steps:
  #
  # @param [PivotalTracker::Project] project the project to select stories from
  # @param [String, nil] filter a filter for selecting the story to start.  This
  #   filter can be either:
  #   * a story id: selects the story represented by the id
  #   * a story type (feature, bug, chore): offers the user a selection of stories of the given type
  #   * +nil+: offers the user a selection of stories of all types
  # @param [Fixnum] limit The number maximum number of stories the user can choose from
  # @return [PivotalTracker::Story] The Pivotal Tracker story selected by the user
  def self.select_story(project, filter = nil, limit = 15)
    if filter =~ /[[:digit:]]/
      story = project.story(filter.to_i)
    else
      story = find_story project, filter, limit
    end

    story
  end

  private

  KEY_USER = 'pivotal.user'.freeze

  CANDIDATE_STATES = %w(rejected unstarted unscheduled).freeze

  LABEL_DESCRIPTION = 'Description'.freeze

  LABEL_TITLE = 'Title'.freeze

  LABEL_WIDTH = (LABEL_DESCRIPTION.length + 2).freeze

  CONTENT_WIDTH = (HighLine.new.output_cols - LABEL_WIDTH).freeze

  def self.print_label(label)
    print "%#{LABEL_WIDTH}s" % ["#{label}: "]
  end

  def self.print_value(value)
    value = value.to_s

    if value.blank?
      puts ''
    else
      value.scan(/\S.{0,#{CONTENT_WIDTH - 2}}\S(?=\s|$)|\S+/).each_with_index do |line, index|
        if index == 0
          puts line
        else
          puts "%#{LABEL_WIDTH}s%s" % ['', line]
        end
      end
    end
  end

  def self.find_story(project, type, limit)
    criteria = {
      :current_state => CANDIDATE_STATES
    }
    if type
      criteria[:story_type] = type
    end

    # candidates = project.stories.all(criteria).sort_by{ |s| s.owned_by == @user ? 1 : 0 }.slice(0..limit)
    configuration = PivotalIntegration::Command::Configuration.new

    search_result_container = project.search("-state:accepted")
    stories_search_result = search_result_container.stories
    # NOTE: search_result_container also has an `epics` property

    user_name = PivotalIntegration::Util::Git.get_config KEY_USER, :inherited
    person = PivotalIntegration::Util::Person.get_person_by_name(project, user_name)

    candidates = stories_search_result.stories.sort_by{ |s| (s.owner_ids || []).include?(person.id) ? 0 : 1 }.slice(0..limit)
    if candidates.length == 1
      story = candidates[0]
    else
      story = choose do |menu|
        menu.prompt = 'Choose story to start: '

        candidates.each do |s|
          name = s.owned_by ? '[%s] ' % s.owned_by : ''
          name += type ? s.name : '%-7s %s' % [s.story_type.upcase, s.name]
          menu.choice(name) { s }
        end
      end

      puts
    end

    # story return in stories search result does not support save
    # so, need to query for story via API so it can be saved downstream
    project.story(story.id)
  end
end
