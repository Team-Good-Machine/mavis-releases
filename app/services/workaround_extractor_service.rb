class WorkaroundExtractorService
  BATCH_SIZE = 10

  def self.extract_workarounds(cards)
    new.extract_workarounds(cards)
  end

  def extract_workarounds(cards)
    return cards if cards.empty?

    # Only process cards that mention workarounds
    cards_with_workarounds = cards.select { |card| card.desc.downcase.include?("workaround") }

    # Process filtered cards in batches
    cards_with_workarounds.each_slice(BATCH_SIZE) do |batch|
      process_batch(batch)
    end

    cards
  end

  private

  def process_batch(cards)
    # Prepare card data for Claude
    card_data = cards.map do |card|
      {
        id: card.id,
        description: card.desc
      }
    end
    # Log the card data
    Rails.logger.info "Card data: #{card_data.inspect}"

    client = Anthropic::Client.new

    response = client.messages(
      parameters: {
        model: "claude-3-sonnet-20240229",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: <<~PROMPT
                  For each of these Trello card descriptions, extract the text that follows any Markdown heading containing the word "workaround" (case-insensitive).
                  A Markdown heading can start with one or more '#' symbols followed by the text.

                  Extract all text following the workaround heading until the next heading or the end of the description.
                  If there is no heading containing "workaround", return null.

                  Even if the section states there is "no workaround", still extract and return the full text as it may contain
                  important information about temporary measures or alternative approaches.

                  Return a JSON object mapping card IDs to their documented workaround text if text is present, or null.
                  Format: { "card_id1": "workaround text", "card_id2": null }

                  Card descriptions to analyze:
                  #{JSON.pretty_generate(card_data)}
                PROMPT
              }
            ]
          }
        ]
      }
    )

    # Extract the text content from the response
    response_text = response["content"].first["text"]

    Rails.logger.info "Response text: #{response_text}"

    # Find the JSON object in the response text
    json_match = response_text.match(/\{[^{]*\}/)
    workarounds = JSON.parse(json_match[0]) if json_match

    Rails.logger.info "Workarounds: #{workarounds.inspect}"

    # Set workaround on each card in the batch
    cards.each do |card|
      card.workaround = workarounds[card.id] if workarounds
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse Claude's response: #{e.message}"
  rescue Anthropic::Error => e
    Rails.logger.error "Claude API error: #{e.inspect}"
  end
end
