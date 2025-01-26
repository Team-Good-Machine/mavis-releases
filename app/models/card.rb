class Card
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_reader :trello_card, :board_custom_fields

  delegate :name, :url, :created_at, :id, :desc, to: :trello_card

  # @param trello_card [Trello::Card] The Trello card object
  # @param board_custom_fields [Array<Trello::CustomField>] All custom fields from the board,
  #   fetched once to avoid multiple API calls
  def initialize(trello_card, board_custom_fields: [])
    @trello_card = trello_card
    @board_custom_fields = board_custom_fields
  end

  def tagged_as_bug?
    trello_card.labels.any? { it.name == "bug" }
  end

  def self.find_suspected_bugs(cards)
    # Filter out cards already tagged as bugs
    candidates = cards.reject(&:tagged_as_bug?)
    return [] if candidates.empty?

    # Use the service to analyze cards
    BugDetectorService.analyze_cards(candidates)
  end

  def severity_set?
    severity_field_item.present? && severity_field_item.option_id.present?
  end

  def severity
    return nil unless severity_field_item&.option_id

    severity_field
      .checkbox_options
      .find { |opt| opt["id"] == severity_field_item.option_id }
      &.dig("value", "text")
  end

  def high_severity?
    %w[highest high medium].include?(severity&.downcase)
  end

  private

  # Uses @board_custom_fields to find the severity field definition
  # without making an API call
  def severity_field
    @severity_field ||= board_custom_fields.find { |field| field.name.downcase == "severity" }
  end

  # Uses the severity field definition to find the corresponding value
  # for this card in its custom_field_items
  def severity_field_item
    @severity_field_item ||= trello_card.custom_field_items.find { |item| item.custom_field_id == severity_field&.id }
  end
end
