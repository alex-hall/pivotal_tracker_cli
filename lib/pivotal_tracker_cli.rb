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

      if config['username_to_user_id_map']
        @username_to_user_id_map = config['username_to_user_id_map']
      else
        @username_to_user_id_map = PivotalTrackerCli::Api.get_all_users_for_project(@project_id, @api_token)

        config['username_to_user_id_map'] = @username_to_user_id_map

        File.open(ENV['HOME'] + '/.pt', 'w') do |f|
          f.write config.to_yaml
        end
      end

      super
    end

    desc 'find_current_stories', 'This finds all current stories for a given user'

    def find_current_stories
      PivotalTrackerCli::Api.get_current_stories_for_user(@project_id, @api_token, @username).map do |story|
        output.puts('*' * 40)

        if story[:error]
          output.puts("Error: #{story[:error]}")
        else
          output.puts("Story ID: #{story[:story_id]}")
          output.puts("Story Name: #{story[:story_name]}")
          output.puts("Status: #{story[:status]}")
        end

      end
      output.puts('*' * 40)
    end

    desc 'get_story_by_id', 'This finds a specific story'

    def get_story_by_id(id)
      output.puts(get_story(id))
    end

    desc 'start', 'Starts a specific story'

    def start(id)
      output.puts(update_story(id, 'started'))
    end


    desc 'unstart', 'Unstarts a specific story'

    def unstart(id)
      output.puts(update_story(id, 'unstarted'))
    end

    desc 'deliver', 'Delivers a specific story'

    def deliver(id)
      output.puts(update_story(id, 'delivered'))
    end

    desc 'finish', 'Finishes a specific story'

    def finish(id)
      story_type = get_story(id)[:type]

      if story_type == 'chore'
        output.puts(update_story(id, 'accepted'))
      else
        output.puts(update_story(id, 'finished'))
      end
    end

    private

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