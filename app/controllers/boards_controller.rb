class BoardsController < ApplicationController
  def show
    @board = Trello::Board.find(params[:id])
  rescue Trello::Error => e
    render plain: "Error: #{e.message}", status: :not_found
  end
end
