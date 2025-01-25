class Card
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :trello_card

  delegate :name, :url, :created_at, to: :trello_card

  def initialize(trello_card)
    @trello_card = trello_card
  end

  def tagged_as_bug?
    trello_card.labels.any? { it.name == "bug" }
  end

  def self.from_board(board, since: nil)
    since_date = since&.beginning_of_day

    board
      .cards(filter: "open", since: since_date&.iso8601)
      .map { |trello_card| new(trello_card) }
  end
end
