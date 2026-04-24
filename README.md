# Kibana Agent for Kiro CLI

A specialized Kiro CLI agent for creating Kibana dashboards and Slack alerts from natural language. Uses Model Context Protocol (MCP) to interact with Elasticsearch and Kibana.

## Features

- Create Kibana dashboards from natural language descriptions
- Configure Slack metric alerts
- Automatic data view resolution
- Query preview before dashboard creation
- Support for multiple visualization types (line, bar, pie, table)

## Prerequisites

- [Kiro CLI](https://github.com/kiro-ai/kiro-cli) installed
- Running Elasticsearch instance (default: http://localhost:9200)
- Running Kibana instance (default: http://localhost:5601)
- Node.js 18+ (for MCP server)

## Installation

### Quick Setup

```bash
git clone <repository-url>
cd kibana-agent
./setup.sh
```

The setup script will:
- Check Node.js version (18+ required)
- Install MCP server dependencies
- Prompt for configuration values
- Create `.env` file
- Register MCP server with Kiro CLI

After setup, restart Kiro CLI if it's running.

### Manual Setup

<details>
<summary>Click to expand manual installation steps</summary>

1. Install MCP server dependencies:
```bash
cd .kiro/mcp-servers
npm install
cd ../..
```

2. Copy `.env.example` to `.env` and configure:
```bash
cp .env.example .env
# Edit .env with your values
```

3. Add to `~/.kiro/settings/mcp.json`:
```json
{
  "mcpServers": {
    "kibana-server": {
      "command": "node",
      "args": ["/absolute/path/to/kibana-agent/.kiro/mcp-servers/kibana-server.js"],
      "env": {
        "ES_URL": "http://localhost:9200",
        "KIBANA_URL": "http://localhost:5601",
        "ROOT_DIR": "/absolute/path/to/kibana-agent"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

4. Restart Kiro CLI

</details>

## Usage

Start the agent:

```bash
kiro chat --agent kibana-agent
```

### Creating Dashboards

```
User: Show error count over time
Agent: What index pattern? (e.g., logs-*)
User: logs-app-*
Agent: [Previews data, creates dashboard, returns Kibana URL]
```

### Creating Alerts

```
User: Alert when CPU > 80%
Agent: What index pattern?
User: metrics-system-*
Agent: [Creates alert with gt operator at 80]
```

## Workflow

### Dashboard Creation

1. User describes visualization needs
2. Agent determines index (or asks if unclear)
3. Agent asks for: field to visualize, viz type, time range
4. Agent previews data and asks for confirmation
5. Agent generates and creates dashboard, returns URL

### Alert Configuration

1. User describes alert condition
2. Agent determines index and metric field
3. Agent asks for threshold and operator
4. Agent creates alert configuration

## MCP Tools

The agent uses these MCP tools provided by the server:

- `list_indices` - List all Elasticsearch indices
- `create_data_view` - Create Kibana data view for an index
- `discover_fields` - List available fields in an index
- `query_preview` - Preview query results with aggregations
- `generate_dashboard` - Generate dashboard configuration
- `create_dashboard` - Create dashboard in Kibana
- `create_alert` - Configure metric alert
- `check_alerts` - Evaluate alerts and send notifications

## Configuration

### Agent Configuration

The agent is configured in `.kiro/agents/kibana-agent.json`. Key settings:

- Allowed tools: MCP tools for Kibana operations
- Workflow prompts for dashboard and alert creation
- Default values (time range: 15m)

### MCP Server

The MCP server (`kibana-server.js`) handles:

- Elasticsearch API calls
- Kibana API calls
- Dashboard generation
- Alert evaluation
- Slack notifications

## Tips

- Use index patterns with wildcards (e.g., `logs-*`, `metrics-*`)
- Default time range is 15 minutes
- Supported operators: `gt` (>), `lt` (<), `gte` (≥), `lte` (≤)
- Agent automatically resolves data view IDs
- Preview data before creating dashboards

## Troubleshooting

### MCP Server Not Loading

1. Check `~/.kiro/settings/mcp.json` has correct absolute paths
2. Verify Node.js is installed: `node --version`
3. Check MCP server dependencies: `cd .kiro/mcp-servers && npm install`
4. Restart Kiro CLI

### Dashboard Creation Fails

1. Verify Elasticsearch is running: `curl http://localhost:9200`
2. Verify Kibana is running: `curl http://localhost:5601`
3. Check index exists: Use `list_indices` tool
4. Verify data view exists or create one with `create_data_view`

### Alerts Not Triggering

1. Check `.env` has `SLACK_INCOMING_WEBHOOK_URL`
2. Verify webhook URL is valid
3. Check alert configuration in `.kiro/data/kibana-agent/alerts.json`

## License

MIT

## Contributing

Contributions welcome! Please open an issue or PR.
