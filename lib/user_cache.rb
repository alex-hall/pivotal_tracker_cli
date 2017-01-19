module PivotalTrackerCli
  class UserCache

    def self.build_or_assign_user_cache(config, project_id, api_token)
      config['username_to_user_id_map'] || rebuild_user_cache(config, project_id, api_token)
    end

    def self.rebuild_user_cache(config, project_id, api_token)
      username_to_user_id_map = PivotalTrackerCli::Api.get_all_users_for_project(project_id, api_token)

      config['username_to_user_id_map'] = username_to_user_id_map

      File.open(ENV['HOME'] + '/.pt', 'w') do |f|
        f.write config.to_yaml
      end

      username_to_user_id_map
    end
  end
end