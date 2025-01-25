class Card
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :trello_card

  delegate :name, :url, :created_at, :id, :desc, to: :trello_card

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

  def self.find_suspected_bugs(cards)
    # Filter out cards already tagged as bugs
    candidates = cards.reject(&:tagged_as_bug?)
    return [] if candidates.empty?

    # Use the service to analyze cards
    BugDetectorService.analyze_cards(candidates)
  end
end
