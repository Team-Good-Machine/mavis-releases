class BoardsController < ApplicationController
  def show
    @board = Trello::Board.find(params[:id])

    if params[:since].present?
      since_date = Date.parse(params[:since]).beginning_of_day
      @cards = @board
        .cards(filter: "open", since: since_date.iso8601)
        .sort_by(&:created_at)
    end
  rescue Trello::Error => e
    render plain: "Error: #{e.message}", status: :not_found
  rescue Date::Error => e
    render plain: "Invalid date format. Please use YYYY-MM-DD", status: :bad_request
  end
end
