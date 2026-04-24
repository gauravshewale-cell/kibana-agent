#!/bin/bash

set -e

echo "🚀 Kibana Agent Setup"
echo "===================="
echo ""

# Get absolute path of script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 18+ first."
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js 18+ required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js $(node -v) detected"
echo ""

# Install MCP server dependencies
echo "📦 Installing MCP server dependencies..."
cd "$SCRIPT_DIR/.kiro/mcp-servers"
npm install
cd "$SCRIPT_DIR"
echo "✅ Dependencies installed"
echo ""

# Configure environment variables
echo "⚙️  Environment Configuration"
echo "----------------------------"

read -p "Elasticsearch URL [http://localhost:9200]: " ES_URL
ES_URL=${ES_URL:-http://localhost:9200}

read -p "Kibana URL [http://localhost:5601]: " KIBANA_URL
KIBANA_URL=${KIBANA_URL:-http://localhost:5601}

read -p "Elasticsearch username (optional, press Enter to skip): " ES_USER
if [ -n "$ES_USER" ]; then
    read -sp "Elasticsearch password: " ES_PASSWORD
    echo ""
fi

read -p "Kibana username (optional, press Enter to skip): " KIBANA_USER
if [ -n "$KIBANA_USER" ]; then
    read -sp "Kibana password: " KIBANA_PASSWORD
    echo ""
fi

read -p "Slack webhook URL (optional, press Enter to skip): " SLACK_URL

# Create .env file
cat > "$SCRIPT_DIR/.env" << EOF
ES_URL="$ES_URL"
KIBANA_URL="$KIBANA_URL"
EOF

if [ -n "$ES_USER" ]; then
    echo "ES_USER=\"$ES_USER\"" >> "$SCRIPT_DIR/.env"
    echo "ES_PASSWORD=\"$ES_PASSWORD\"" >> "$SCRIPT_DIR/.env"
fi

if [ -n "$KIBANA_USER" ]; then
    echo "KIBANA_USER=\"$KIBANA_USER\"" >> "$SCRIPT_DIR/.env"
    echo "KIBANA_PASSWORD=\"$KIBANA_PASSWORD\"" >> "$SCRIPT_DIR/.env"
fi

if [ -n "$SLACK_URL" ]; then
    echo "SLACK_INCOMING_WEBHOOK_URL=\"$SLACK_URL\"" >> "$SCRIPT_DIR/.env"
fi

echo "✅ .env file created"
echo ""

# Configure MCP server in Kiro CLI
echo "🔧 Configuring MCP server..."

KIRO_MCP_FILE="$HOME/.kiro/settings/mcp.json"
mkdir -p "$(dirname "$KIRO_MCP_FILE")"

if [ ! -f "$KIRO_MCP_FILE" ]; then
    echo '{"mcpServers":{}}' > "$KIRO_MCP_FILE"
fi

# Create temporary Python script to update JSON
python3 - <<PYTHON_SCRIPT
import json
import sys

mcp_file = "$KIRO_MCP_FILE"
script_dir = "$SCRIPT_DIR"

with open(mcp_file, 'r') as f:
    config = json.load(f)

if 'mcpServers' not in config:
    config['mcpServers'] = {}

config['mcpServers']['kibana-server'] = {
    "command": "node",
    "args": [f"{script_dir}/.kiro/mcp-servers/kibana-server.js"],
    "env": {
        "ES_URL": "$ES_URL",
        "KIBANA_URL": "$KIBANA_URL",
        "ROOT_DIR": script_dir
    },
    "disabled": False,
    "autoApprove": []
}

with open(mcp_file, 'w') as f:
    json.dump(config, f, indent=2)

print("✅ MCP server registered")
PYTHON_SCRIPT

echo ""
echo "✨ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Restart Kiro CLI if it's running"
echo "2. Start the agent: kiro chat --agent kibana-agent"
echo ""
echo "📍 Project location: $SCRIPT_DIR"
