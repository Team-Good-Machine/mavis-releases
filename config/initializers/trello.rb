require 'trello'

# require 'logger'
# Enable Faraday debug logging
# module Trello
#   module TFaraday
#     class TInternet
#       class << self
#         private

#         def execute_core(request)
#           conn = Faraday.new(
#             request.uri.to_s,
#             headers: request.headers,
#             proxy: ENV['HTTP_PROXY'],
#             request: { timeout: 10 }
#           ) do |faraday|
#             # Add logger middleware
#             faraday.response :logger, Logger.new($stdout), { bodies: true, headers: false }

#             faraday.response :raise_error
#             faraday.request :multipart
#             faraday.request :json
#           end

#           conn.send(request.verb) do |req|
#             req.body = request.body
#           end
#         end
#       end
#     end
#   end
# end

module Trello
  class Card
    def initialize_fields(fields)
      super

      # If customFields were included in the response, parse them into custom_field_items
      if fields['customFieldItems'].is_a?(Array)
        @custom_field_items = fields['customFieldItems'].map { CustomFieldItem.new(it) }
      end
    end

    # Override custom_fields to return the parsed custom field items when they're included in the response
    def custom_field_items
      @custom_field_items || super
    end
  end
end

# Then configure Trello
Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
  config.member_token = ENV['TRELLO_MEMBER_TOKEN']
end
