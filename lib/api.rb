module PivotalTrackerCli
  class Api
    def self.get_all_users_for_project(project_id, api_token)
      response = HTTParty.get("https://www.pivotaltracker.com/services/v5/projects/#{project_id}/memberships",
                              headers: {
                                  'X-TrackerToken': api_token
                              }
      )

      return unless response.success?

      member_map = {}

      response.parsed_response.map do |member|
        member_map[member['person']['username']] = { id: member['person']['id'], name: member['person']['name'] }
      end

      member_map
    end

    def self.get_story_by_id(project_id, api_token, story_id)
      response = HTTParty
                     .get("https://www.pivotaltracker.com/services/v5/projects/#{project_id}/stories/#{story_id.to_s}",
                          headers: {
                              'X-TrackerToken': api_token
                          })

      OpenStruct.new(response.parsed_response) if response.success?
    end

    def self.update_story_state(project_id, api_token, id, state, owner_ids)
      response = HTTParty.put(
          "https://www.pivotaltracker.com/services/v5/projects/#{project_id}/stories/#{id.to_s}",
          headers: {
              'X-TrackerToken': api_token
          },
          body: {
              'current_state': state,
              'owner_ids': owner_ids
          }
      )

      "Story ##{id} successfully #{state}." if response.success?
    end

    def self.get_current_stories_for_user(project_id, api_token, usernames)
      search_term = usernames.map do |username|
        "owner:\"#{username}\""
      end.join(' OR ')


      response = HTTParty
                     .get("https://www.pivotaltracker.com/services/v5/projects/#{project_id}/search",
                          query: {
                              query: search_term
                          },
                          headers: {
                              'X-TrackerToken': api_token
                          })

      story_list = []

      response.parsed_response['stories']['stories'].map { |story| story_list.push(OpenStruct.new(story)) } if response.success?

      story_list
    end

    def self.get_backlog_for_project(project_id, api_token, limit=3)

      endpoint = "https://www.pivotaltracker.com/services/v5/projects/#{project_id}/iterations?scope=current_backlog&limit=#{limit}"

      response = HTTParty.get(endpoint,
                              headers: {
                                  'X-TrackerToken': api_token
                              })

      stories = []

      response.parsed_response.each do |iteration|
        iteration['stories'].each do |story|
          stories.push(OpenStruct.new(story))
        end
      end
      stories
    end
  end
end
