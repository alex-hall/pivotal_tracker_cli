#!/usr/bin/env ruby
require 'httparty'
require 'awesome_print'
require 'thor'
require 'byebug'
require 'colorize'
require 'colorized_string'
require_relative 'api'
require_relative 'string_utilities'
require_relative 'user_cache'
require_relative 'hash_manager'

module PivotalTrackerCli
  class Client < Thor

    attr_reader :username_to_user_id_map

    def initialize(args, local_options, config)
      @config = YAML.load_file(ENV['HOME'] + '/.pt')

      @api_token = @config['api_token']
      @project_id = @config['project_id']
      @usernames = @config['usernames']

      @story_statuses = {
          'unstart' => 'unstarted',
          'start' => 'started',
          'deliver' => 'delivered',
          'finish' => %w(finished accepted)
      }

      @username_to_user_id_map = build_or_assign_user_cache(@config)
      super
    end

    desc 'list', 'Lists all current stories for current user'

    def list
      get_current_stories_for_user.map do |story|
        output.puts('*' * 40)
        format_story(story)
      end
      output.puts('*' * 40)
    end

    desc 'show [STORY_ID]', 'Shows a specific story'

    def show(id)
      format_story(get_story(id))
    end

    desc 'update [STORY_ID] [STATUS]', 'Updates the status of a story, available statuses are: unstart, start, deliver, finish'

    def update(id, status)
      validate_and_update_story(id, status)
    end

    desc 'backlog', 'Displays all stores for the 3 most recent iterations in the backlog'

    def backlog
      get_backlog(3).map do |story|
        output.puts("* #{story.id.to_s.red} - #{colorize_status(story.current_state)} - #{embiggen_string(story.name)} <#{get_owner_name_from_ids(story.owner_ids)}>")
      end
    end

    desc 'refresh', 'Refreshes the user cache for tracker'

    def refresh
      rebuild_user_cache(@config)
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


    def format_story(story)
      output.puts("#{'Story ID'.bold}          : #{story.id}")
      output.puts("#{'Status'.bold}            : #{colorize_status(story.current_state)}")
      output.puts("#{'Story Type'.bold}        : #{story.story_type}")
      output.puts("#{'Story Name'.bold}        : #{embiggen_string(story.name)}")
      output.puts("#{'Owners'.bold}            : #{get_owner_name_from_ids(story.owner_ids).yellow}")
      output.puts("#{'Story Description'.bold} :")
      output.puts("                    #{wrap(embiggen_string(story.description), 150, 10)}")
    end
    def wrap(s, width=150, offset=0)
      s.gsub(/(.{1,#{width}})(\s+|\Z)/, "#{' '* offset}\\1\n")
    end

    def get_owner_name_from_ids(owners)
      PivotalTrackerCli::HashManager.get_owner_name_from_ids(owners, @username_to_user_id_map)
    end

    def find_name_given_id(owners)
      PivotalTrackerCli::HashManager.find_name_given_id(owners, @username_to_user_id_map)
    end

    def build_or_assign_user_cache(config)
      PivotalTrackerCli::UserCache.build_or_assign_user_cache(config, @project_id, @api_token)
    end

    def rebuild_user_cache(config)
      PivotalTrackerCli::UserCache.rebuild_user_cache(config, @project_id, @api_token)
    end

    def embiggen_string(string)
      PivotalTrackerCli::StringUtilities.embiggen_string(string)
    end

    def colorize_status(status)
      PivotalTrackerCli::StringUtilities.colorize_status(status)
    end

    def get_backlog(iterations)
      PivotalTrackerCli::Api.get_backlog_for_project(@project_id, @api_token, iterations)
    end

    def get_current_stories_for_user
      PivotalTrackerCli::Api.get_current_stories_for_user(@project_id, @api_token, @usernames)
    end

    def get_story(id)
      PivotalTrackerCli::Api.get_story_by_id(@project_id, @api_token, id)
    end

    def update_story(id, status)
      PivotalTrackerCli::Api.update_story_state(@project_id, @api_token, id, status, get_user_ids_from_usernames(@username_to_user_id_map, @usernames))
    end

    def output
      @output ||= $stdout
    end

    def get_user_ids_from_usernames(user_map, username)
      PivotalTrackerCli::UserCache.get_user_ids_from_usernames(user_map, username)
    end
  end
end