module PivotalTrackerCli
  class HashManager
    def self.get_owner_name_from_ids(owners, username_to_user_id_map)
      return 'unassigned' if owners.empty?

      owners.map do |owner|
        find_name_given_id(owner, username_to_user_id_map)
      end.join(', ')
    end

    def self.find_name_given_id(owner_id, username_to_user_id_map)
      name = ''

      username_to_user_id_map.each_value do |value|
        if value[:id] == owner_id
          name = value[:name]
          break
        end
      end

      name
    end
  end
end