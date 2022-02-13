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

require_relative 'util'

# Utilities for dealing with +PivotalTracker::Label+s
class PivotalIntegration::Util::Label

  # Add labels to story if they are not already appended to story.
  #
  # @param [PivotalTracker::Story, String] labels as Strings, one label per parameter.
  # @return [boolean] Boolean defining whether story was updated or not.
  def self.add(story, *labels)
    orig_labels = story.labels.map{|l| l.name}

    labels.each do |label_name|
      label = TrackerApi::Resources::Label.new(name: label_name)
      story.labels = story.labels.dup.push(label)
    end

    if story.save
      puts "Updated labels on #{story.name}:"
      puts "#{orig_labels} => #{orig_labels | labels}"
    else
      abort("Failed to update labels on Pivotal Tracker")
    end
  end

  # Add labels from story and remove those labels from every other story in a project.
  #
  # @param [PivotalTracker::Story, String] labels as Strings, one label per parameter.
  # @return [boolean] Boolean defining whether story was updated or not.
  def self.once(story, *labels)
    PivotalTracker::Project.find(story.project_id).stories.all.each do |other_story|
      self.remove(other_story, *labels) if story.name != other_story.name and
                                           other_story.labels and
                                           (other_story.labels.split(',') & labels).any?
    end
    self.add(story, *labels)
  end

  # Remove labels from story.
  #
  # @param [PivotalTracker::Story, String] labels as Strings, one label per parameter.
  # @return [boolean] Boolean defining whether story was updated or not.
  def self.remove(story, *labels)
    original_label_names = story.labels.map{|l| l.name}
    original_labels_for_delete = story.labels

    labels.each do |label_name|
      story.labels = story.labels.reject{|l| l.name == label_name }
    end

    if story.save
      current_labels = story.labels.map{|l| l.name}
      puts "Updated labels on #{story.name}:"
      puts "#{original_label_names} => #{current_labels}"
    else
      abort("Failed to update labels on Pivotal Tracker")
    end
  end

  def self.remove_orig(story, *labels)
    original_labels = story.labels.map{|l| l.name}
    original_labels_for_delete = story.labels

    labels.each do |label_name|
      label = TrackerApi::Resources::Label.new(name: label_name)
      found = original_labels_for_delete.detect{|orig_label| orig_label.name == label_name}
      if (found) then
        found.delete
      end
    end

    if story.save
      current_labels = story.labels.map{|l| l.name}
      puts "Updated labels on #{story.name}:"
      puts "#{original_labels} => #{current_labels}"
    else
      abort("Failed to update labels on Pivotal Tracker")
    end
  end

  # Print labels from story.
  #
  # @param [PivotalTracker::Story, String] labels as Strings, one label per parameter.
  # @return [boolean] Boolean defining whether story was updated or not.
  def self.list(story)
    puts "Story labels:"
    puts story.labels.map{|l| l.name}
  end
end
