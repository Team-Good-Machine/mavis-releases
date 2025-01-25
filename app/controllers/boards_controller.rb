class BoardsController < ApplicationController
  def show
    @board = Trello::Board.find(params[:id])

    if params[:since].present?
      @cards = Card
        .from_board(@board, since: Date.parse(params[:since]))
        .reject { |card| card.tagged_as_bug? }
        .sort_by(&:created_at)

      @since = Date.parse(params[:since])
    end
  rescue Trello::Error => e
    render plain: "Error: #{e.message}", status: :not_found
  rescue Date::Error => e
    render plain: "Invalid date format. Please use YYYY-MM-DD", status: :bad_request
  end
end
