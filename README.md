# Mavis Releases

A simple Rails application to help coordinate releases.

## Setup

1. Get your Trello API credentials:
   - Visit https://trello.com/app-key/
   - Copy your API Key (this will be your Developer Public Key)
   - Click on "Generate a Token" to get your Member Token

2. Get your Anthropic API key:
   - Visit https://console.anthropic.com/account/keys
   - Generate and copy your API key

2. Run the application:

```
TRELLO_DEVELOPER_PUBLIC_KEY=your_api_key_here \
TRELLO_MEMBER_TOKEN=your_member_token_here \
ANTHROPIC_API_KEY=your_anthropic_key_here \
bin/dev
```

## Usage

### Backlog health

Visit `/boards/<board_id>` to see a board's title. The board ID can be found in any Trello board URL:
`https://trello.com/b/[BOARD_ID]/[board-name]`
