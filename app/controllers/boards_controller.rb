class BoardsController < ApplicationController
  def show
    @board = Board.find(params[:id])
    @since = Date.parse(params[:since]) if params[:since].present?

    # Only load data for Turbo Frame requests
    if turbo_frame_request?
      all_cards_since = @board.cards(since: @since)
      all_bugs = @board.bug_cards

      case params[:frame]
      when "potential_bugs"
        @cards = Card.find_suspected_bugs(all_cards_since)
        render :potential_bugs
      when "high_severity_bugs"
        @high_severity_bugs = all_bugs
          .select(&:high_severity?)
          .sort_by { |card| [card.severity_order, card.created_at] }
        render :high_severity_bugs
      when "bugs_without_severity"
        @bugs_without_severity = all_bugs.reject(&:severity_set?)
        render :bugs_without_severity
      end
      return
    end

    # Initial page load has no card data
  rescue Trello::Error => e
    render plain: "Error: #{e.message}", status: :not_found
  rescue Date::Error => e
    render plain: "Invalid date format. Please use YYYY-MM-DD", status: :bad_request
  end
end
