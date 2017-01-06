module PivotalTrackerCli
  class Api
    def self.get_story_by_id(project_id, api_token, story_id)
      response = HTTParty
                     .get("https://www.pivotaltracker.com/services/v5/projects/#{project_id}/stories/#{story_id.to_s}",
                          headers: {
                              'X-TrackerToken': api_token
                          })

      if response.success?
        {type: response.parsed_response['story_type']}
      else
        {error: response.parsed_response.dig('error') || 'Failed to reach API.'}
      end
    end

    def self.update_story_state(project_id, api_token, id, state)
      response = HTTParty.put(
          "https://www.pivotaltracker.com/services/v5/projects/#{project_id}/stories/#{id.to_s}",
          headers: {
              'X-TrackerToken': api_token
          },
          body: {
              'current_state': state
          }
      )

      if response.success?
        "Story ##{id} successfully #{state}."
      else
        response.parsed_response.dig('error') || 'Failed to reach API.'
      end
    end

    def self.get_current_stories_for_user(project_id, api_token, username)
      response = HTTParty
                     .get("https://www.pivotaltracker.com/services/v5/projects/#{project_id}/search",
                          query: {
                              query: "owner:\"#{username}\""
                          },
                          headers: {
                              'X-TrackerToken': api_token
                          })
      if response.success?
        response.parsed_response['stories']['stories'].map do |story|
          {
              story_id: story['id'],
              story_name: story['name'],
              status: story['current_state']
          }
        end
      else
        [{error: response.parsed_response.dig('error') || 'Failed to reach API.'}]
      end
    end
  end
end
