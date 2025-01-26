class Board
  attr_reader :trello_board

  def initialize(trello_board)
    @trello_board = trello_board
  end

  delegate :id, :name, to: :trello_board

  def self.find(id)
    new(Trello::Board.find(id))
  end

  def cards(since: nil)
    since_date = since&.beginning_of_day

    trello_board
      .cards(filter: "visible", since: since_date&.iso8601, customFieldItems: 'true')
      .map { |card| Card.new(card, board_custom_fields:) }
  end

  def high_severity_bugs
    bug_cards.select(&:high_severity?)
  end

  def bug_cards(since: nil)
    cards(since:).select(&:tagged_as_bug?)
  end

private

  def board_custom_fields
    @board_custom_fields ||= trello_board.custom_fields(filter: "enabled")
  end
end
