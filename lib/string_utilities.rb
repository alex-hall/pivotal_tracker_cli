module PivotalTrackerCli
  class StringUtilities

    def self.embiggen_string(string)
      return string if ENV['DISABLE_MARKDOWN'] == 'true'

      string
          .gsub(/(\*\*)(.*?)(\*\*)/, "\033[1m" + '\2' "\033[0m")
          .gsub(/(_)(.*?)(_)/, "\033[4m" + '\2' "\033[0m")
    end

    def self.colorize_status(story_state)
      case story_state
        when 'rejected'
          return story_state.red
        when 'accepted'
          return story_state.green
        when 'delivered'
          return story_state.cyan
        when 'finished'
          return story_state.yellow
        when 'started'
          return story_state.magenta
        when 'unstarted'
          return story_state
      end

      story_state
    end

  end
end