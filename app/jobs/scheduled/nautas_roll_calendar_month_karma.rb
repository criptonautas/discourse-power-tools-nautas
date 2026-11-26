# frozen_string_literal: true

module Jobs
  # Moves the calendar-month leaderboard to the 1st shortly after the month
  # turns (UTC). Does nothing the rest of the month.
  class NautasRollCalendarMonthKarma < ::Jobs::Scheduled
    every 10.minutes

    def execute(_args)
      return unless ::NautasCalendarMonthKarma.enabled?
      ::NautasCalendarMonthKarma.roll!
    end
  end
end
