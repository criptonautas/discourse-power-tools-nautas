# frozen_string_literal: true

# A member's tier is the highest of the tier groups (lowest first in
# nautas_tier_groups) they belong to. Every member has one, so cards and
# profiles can name it without loading badges.
module ::NautasTier
  def self.group_ids
    SiteSetting.nautas_tier_groups.to_s.split("|").map(&:to_i).select(&:positive?)
  end

  def self.enabled?
    SiteSetting.jtech_enabled && group_ids.any?
  end

  # The tier group's display name, or nil when the member holds none or the
  # viewer may not see that group.
  def self.name_for(user, guardian)
    ids = group_ids
    held = GroupUser.where(user_id: user.id, group_id: ids).pluck(:group_id)
    group = Group.find_by(id: ids.reverse.find { |id| held.include?(id) })
    return nil if group.nil? || !guardian.can_see_group?(group)

    group.full_name.presence || group.name
  end
end
