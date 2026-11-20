# frozen_string_literal: true

require "rails_helper"

RSpec.describe NautasTier do
  fab!(:member, :user)
  fab!(:viewer, :user)
  fab!(:low) { Fabricate(:group, name: "nautas") }
  fab!(:high) { Fabricate(:group, name: "traders", full_name: "Traders") }

  before do
    SiteSetting.jtech_enabled = true
    SiteSetting.nautas_tier_groups = "#{low.id}|#{high.id}"
    low.add(member)
    high.add(member)
    sign_in(viewer)
  end

  def card_tier(user)
    get "/u/#{user.username}/card.json"
    response.parsed_body["user"]["nautas_tier"]
  end

  it "names the highest tier group, preferring its full name" do
    expect(card_tier(member)).to eq("Traders")

    get "/u/#{member.username}.json"
    expect(response.parsed_body["user"]["nautas_tier"]).to eq("Traders")
  end

  it "is nil for a member in no tier group" do
    expect(card_tier(viewer)).to be_nil
  end

  it "hides a tier group the viewer can't see" do
    high.update!(visibility_level: Group.visibility_levels[:owners])
    expect(card_tier(member)).to be_nil
  end

  it "is left out when no tier groups are set" do
    SiteSetting.nautas_tier_groups = ""
    get "/u/#{member.username}/card.json"
    expect(response.parsed_body["user"]).not_to have_key("nautas_tier")
  end
end
