class BoardsController < ApplicationController
  def show
    @board = Trello::Board.find(params[:id])

    if params[:since].present?
      @since = Date.parse(params[:since])
      all_cards = Card
        .from_board(@board, since: @since)
        .sort_by(&:created_at)

      @cards = Card.find_suspected_bugs(all_cards)
    end

    # Get all bug cards without severity
    @bugs_without_severity = Card
      .from_board(@board, since: @since)
      .select { it.tagged_as_bug? && !it.severity_set? }
      .sort_by(&:created_at)

  rescue Trello::Error => e
    render plain: "Error: #{e.message}", status: :not_found
  rescue Date::Error => e
    render plain: "Invalid date format. Please use YYYY-MM-DD", status: :bad_request
  end
end
