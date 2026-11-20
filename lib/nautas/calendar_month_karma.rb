# frozen_string_literal: true

# Gamification's "monthly" period is a rolling month (CURRENT_DATE - 1 month)
# and core has no calendar option. A leaderboard's from_date wins over every
# period start (GREATEST), so keeping it on the 1st of the month (UTC) turns
# one leaderboard into a calendar-month one: its page, its home block and the
# score each member sees all agree.
module ::NautasCalendarMonthKarma
  def self.enabled?
    SiteSetting.jtech_enabled && SiteSetting.nautas_calendar_month_leaderboard_id.positive? &&
      defined?(::DiscourseGamification) && SiteSetting.discourse_gamification_enabled
  end

  def self.leaderboard
    ::DiscourseGamification::GamificationLeaderboard.find_by(
      id: SiteSetting.nautas_calendar_month_leaderboard_id,
    )
  end

  # Idempotent, so the job can run often and a late run catches up.
  def self.roll!
    board = leaderboard
    return if board.nil?

    start = Date.current.beginning_of_month
    return if board.from_date == start && board.to_date.nil?

    board.update!(from_date: start, to_date: nil)
    ::DiscourseGamification::LeaderboardCachedView.new(board).refresh
  end

  # The member's score on that leaderboard this month: 0 without points, nil
  # when the viewer may not see the leaderboard or its positions aren't built.
  def self.score_for(user, guardian)
    board = leaderboard
    return nil if board.nil? || !guardian.can_see_leaderboard?(board)

    position =
      ::DiscourseGamification::GamificationLeaderboard.find_position_by(
        leaderboard_id: board.id,
        for_user_id: user.id,
        period: "all_time",
      )
    position&.total_score || 0
  rescue ::DiscourseGamification::LeaderboardCachedView::NotReadyError
    nil
  end
end
