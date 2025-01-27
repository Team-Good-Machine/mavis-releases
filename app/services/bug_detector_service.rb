class BugDetectorService
  def self.analyze_cards(cards)
    new.analyze_cards(cards)
  end

  def analyze_cards(cards)
    return [] if cards.empty?

    # Prepare card data for Claude
    card_data = cards.map do |card|
      {
        id: card.id,
        title: card.name,
        description: card.desc.presence || "No description provided"
      }
    end

    # Ask Claude to analyze and return suspected bug IDs
    suspected_bug_ids = ask_claude(card_data)
    Rails.logger.info "Suspected bug IDs: #{suspected_bug_ids.inspect}"

    # Return only the cards that Claude flagged as potential bugs
    cards.select { |card| suspected_bug_ids.include?(card.id) }
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

  private

  def ask_claude(card_data)
    client = Anthropic::Client.new

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

    response_from_claude = response.dig("content", 0, "text")
    JSON.parse(response_from_claude[/\[(.*?)\]/m, 0])
  end
end
