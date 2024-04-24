class CreateTeamUserNodes < ActiveRecord::Migration[4.2]
  def self.up
    begin
      remove_column :teams_participants, :assignment_id
    rescue StandardError
    end

    teamsusers = TeamsParticipant.all
    teamsusers.each  do |user|
      parent = TeamNode.find_by_node_object_id(user.team_id)
      if parent
        TeamUserNode.create(node_object_id: user.id, parent_id: parent.id)
      end
    end
  end

  def self.down
    teamsusers = TeamsParticipant.all
    teamsusers.each(&:destroy)

    add_column :teams_participants, :assignment_id, :integer
  end
end
