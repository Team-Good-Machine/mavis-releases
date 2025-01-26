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
      .cards(filter: "visible", since: since_date&.iso8601, customFieldItems: 'true')
      .map { new(it) }
      # .take(1)
  end

  def self.find_suspected_bugs(cards)
    # Filter out cards already tagged as bugs
    candidates = cards.reject(&:tagged_as_bug?)
    return [] if candidates.empty?

    # Use the service to analyze cards
    BugDetectorService.analyze_cards(candidates)
  end

  def severity_set?
    trello_card.custom_field_items.any? { |field| field.custom_field.name.downcase == "severity" && field.option_id.present? }
  end

  def severity
    severity_field = trello_card.custom_field_items.find { |field| field.custom_field.name.downcase == "severity" }
    return nil unless severity_field&.option_id

    # Get the selected option's value from checkbox_options
    severity_field.custom_field.checkbox_options
      .find { |opt| opt["id"] == severity_field.option_id }
      &.dig("value", "text")
  end

  def high_severity?
    %w[highest high medium].include?(severity&.downcase)
  end
end
