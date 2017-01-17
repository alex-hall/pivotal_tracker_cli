#!/usr/bin/env ruby
require 'httparty'
require 'awesome_print'
require 'thor'
require 'byebug'
require_relative 'api'

module PivotalTrackerCli
  class Client < Thor

    attr_reader :username_to_user_id_map

    def initialize(args, local_options, config)
      config = YAML.load_file(ENV['HOME'] + '/.pt')

      @api_token = config['api_token']
      @project_id = config['project_id']
      @username = config['username']

      @story_statuses = {
          'unstart' => 'unstarted',
          'start' => 'started',
          'deliver' => 'delivered',
          'finish' => %w(finished accepted)
      }

      build_or_assign_user_cache(config)

      super
    end

    desc 'list', 'Lists all current stories for current user'

    def list
      get_current_stories_for_user.map do |story|
        output.puts('*' * 40)
        output.puts("Story ID: #{story.id}")
        output.puts("Story Name: #{story.name}")
        output.puts("Status: #{story.current_state}")
      end
      output.puts('*' * 40)
    end

    desc 'show [STORY_ID]', 'Shows a specific story'

    def show(id)
      output.puts(get_story(id))
    end

    desc 'update [STORY_ID] [STATUS]', 'Updates the status of a story, available statuses are: unstart, start, deliver, finish'

    def update(id, status)
      validate_and_update_story(id, status)
    end

    private

    def validate_and_update_story(id, status)
      return output.puts('Invalid story status. Story statuses are: unstart, start, deliver, finish') unless @story_statuses[status]

      story = get_story(id)

      return output.puts('Story not found, please validate story number.') unless story

      if status != 'finish'
        output.puts(update_story(id, @story_statuses[status]))
      else
        if story.story_type == 'chore'
          output.puts(update_story(id, 'accepted'))
        else
          output.puts(update_story(id, 'finished'))
        end
      end
    end

    def build_or_assign_user_cache(config)
      if config['username_to_user_id_map']
        @username_to_user_id_map = config['username_to_user_id_map']
      else
        @username_to_user_id_map = PivotalTrackerCli::Api.get_all_users_for_project(@project_id, @api_token)

        config['username_to_user_id_map'] = @username_to_user_id_map

        File.open(ENV['HOME'] + '/.pt', 'w') do |f|
          f.write config.to_yaml
        end
      end
    end

    def get_current_stories_for_user
      PivotalTrackerCli::Api.get_current_stories_for_user(@project_id, @api_token, @username)
    end

    def get_story(id)
      PivotalTrackerCli::Api.get_story_by_id(@project_id, @api_token, id)
    end

    def update_story(id, status)
      PivotalTrackerCli::Api.update_story_state(@project_id, @api_token, id, status)
    end

    def output
      @output ||= $stdout
    end
  end
end