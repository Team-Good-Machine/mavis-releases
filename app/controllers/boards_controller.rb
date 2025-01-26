class BoardsController < ApplicationController
  def show
    @board = Trello::Board.find(params[:id])
    @since = Date.parse(params[:since]) if params[:since].present?

    # Only load data for Turbo Frame requests
    if turbo_frame_request?
      all_cards = Card
        .from_board(@board, since: @since)
        .sort_by(&:created_at)

      case params[:frame]
      when "potential_bugs"
        @cards = Card.find_suspected_bugs(all_cards)
        render :potential_bugs
      when "high_severity_bugs"
        @high_severity_bugs = all_cards.select { it.tagged_as_bug? && it.high_severity? }
        render :high_severity_bugs
      when "bugs_without_severity"
        @bugs_without_severity = all_cards.select { it.tagged_as_bug? && !it.severity_set? }
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
