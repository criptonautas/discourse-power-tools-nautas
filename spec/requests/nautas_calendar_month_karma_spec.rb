# frozen_string_literal: true

require "rails_helper"

RSpec.describe NautasCalendarMonthKarma do
  fab!(:member, :user)
  fab!(:viewer, :user)
  fab!(:leaderboard, :gamification_leaderboard)

  before do
    freeze_time Time.utc(2026, 11, 20, 12)
    SiteSetting.jtech_enabled = true
    SiteSetting.discourse_gamification_enabled = true
    SiteSetting.nautas_calendar_month_leaderboard_id = leaderboard.id

    # Inside the rolling month but before the 1st: must not count.
    Fabricate(
      :gamification_leaderboard_score,
      leaderboard_id: leaderboard.id,
      user_id: member.id,
      date: Date.new(2026, 10, 25),
      score: 40,
    )
    Fabricate(
      :gamification_leaderboard_score,
      leaderboard_id: leaderboard.id,
      user_id: member.id,
      date: Date.new(2026, 11, 3),
      score: 7,
    )
    DiscourseGamification::LeaderboardCachedView.new(leaderboard).create
  end

  def card_karma(user)
    get "/u/#{user.username}/card.json"
    expect(response.status).to eq(200)
    response.parsed_body["user"]["nautas_monthly_karma"]
  end

  it "counts the calendar month once the job has rolled the leaderboard" do
    Jobs::NautasRollCalendarMonthKarma.new.execute({})

    expect(leaderboard.reload.from_date).to eq(Date.new(2026, 11, 1))
    sign_in(viewer)
    expect(card_karma(member)).to eq(7)
    expect(card_karma(viewer)).to eq(0)
  end

  it "shows the same karma on the profile" do
    Jobs::NautasRollCalendarMonthKarma.new.execute({})
    sign_in(viewer)

    get "/u/#{member.username}.json"
    expect(response.parsed_body["user"]["nautas_monthly_karma"]).to eq(7)
  end

  it "hides the karma from viewers who can't see the leaderboard" do
    leaderboard.update!(visible_to_groups_ids: [Fabricate(:group).id])
    Jobs::NautasRollCalendarMonthKarma.new.execute({})
    sign_in(viewer)

    expect(card_karma(member)).to be_nil
  end

  it "leaves leaderboards and cards alone when the setting is 0" do
    SiteSetting.nautas_calendar_month_leaderboard_id = 0
    Jobs::NautasRollCalendarMonthKarma.new.execute({})
    sign_in(viewer)

    expect(leaderboard.reload.from_date).to be_nil
    get "/u/#{member.username}/card.json"
    expect(response.parsed_body["user"]).not_to have_key("nautas_monthly_karma")
  end
end
