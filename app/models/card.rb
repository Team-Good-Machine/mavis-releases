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

    # Prepare card data for Claude
    card_data = candidates.map do |card|
      {
        id: card.id,
        title: card.name,
        description: card.desc.presence || "No description provided"
      }
    end

    # Create Claude client
    client = Anthropic::Client.new

    # Ask Claude to analyze the cards
    response = client.messages(
      parameters: {
        model: "claude-3-5-sonnet-latest",
        max_tokens: 4096,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: <<~PROMPT
                  Analyze these Trello cards and identify which ones might be bug reports that weren't tagged as bugs.
                  Look for indicators like error descriptions, unexpected behavior, or technical issues.

                  Return a JSON array containing only the IDs of cards that are likely bugs.
                  Format: ["card_id1", "card_id2"]

                  Cards to analyze:
                  #{JSON.pretty_generate(card_data)}
                PROMPT
              }
            ]
          }
        ]
      }
    )

    # Parse the response and get the suspected bug IDs
    response_from_claude = response.dig('content', 0, 'text')
    suspected_bug_ids = JSON.parse(response_from_claude[/\[(.*?)\]/m, 0])

    Rails.logger.info "Suspected bug IDs: #{suspected_bug_ids.inspect}"
    # Return only the cards that Claude flagged as potential bugs
    candidates.select { |card| suspected_bug_ids.include?(card.id) }
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse Claude's response: #{e.message}"
    []
  rescue Anthropic::Error => e
    Rails.logger.error "Claude API error: #{e.inspect}"
    []
  rescue Faraday::Error => e
    Rails.logger.error "Faraday error: #{e.inspect}"
    Rails.logger.error "Request failed with: #{e.response[:status]} - #{e.response[:body]}"
    []
  end
end
