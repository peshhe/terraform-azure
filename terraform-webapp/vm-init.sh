#!/bin/bash
# Variables passed from Terraform's 'custom_data' - exported as environment variables
export ENVIRONMENT="${environment}"
export INDEX="${index}"
export LOCATION="${location}"
export SLACK_URL="${slack_url}"
export COSMOSDB_ENDPOINT="${cosmosdb_endpoint}"
export COSMOSDB_PRIMARY_KEY="${cosmosdb_primary_key}"
export DATABASE_NAME="${database_name}"
export CONTAINER_NAME="${container_name}"
export TIMESTAMP="$(date -u)"

# Install basic web server (nginx), 'curl' and 'jq' commands and Python
apt-get update
apt-get install -y nginx curl python3-pip jq

pip3 install azure-cosmos # Install the Cosmos DB Python SDK

systemctl enable nginx # Enable nginx to start on boot

# Create a Python script to perform the read/write operation
cat > /tmp/cosmos-write-read.py << 'EOF'
import os
import json
import uuid
from azure.cosmos import CosmosClient

# Set credentials from environment variables passed by the shell script
vm_index = os.environ['INDEX']
cosmosdb_endpoint = os.environ['COSMOSDB_ENDPOINT']
cosmosdb_primary_key = os.environ['COSMOSDB_PRIMARY_KEY']
database_name = os.environ['DATABASE_NAME']
container_name = os.environ['CONTAINER_NAME']

client = CosmosClient(cosmosdb_endpoint, cosmosdb_primary_key)
database = client.get_database_client(database_name)
container = database.get_container_client(container_name)

# Create a unique item ID using a combination of index and UUID
item_id = f"vm_{vm_index}_record_{uuid.uuid4()}"

# The item to be written to the database
new_item = {
    "id": item_id,
    "vm_index": vm_index,
    "timestamp": os.environ['TIMESTAMP'],
    "message": f"This is a message from VM number {vm_index}."
}

# Write the item to the container
container.upsert_item(body=new_item)

# Read the item back from the database
read_item = container.read_item(item=item_id, partition_key=item_id)

# Outputs the result in JSON format
print(json.dumps(read_item))

EOF

# Run the Python script and capture its output (in JSON format)
cosmos_json_result=$(python3 /tmp/cosmos-write-read.py)
# Strip the JSON and convert it to a readable message (string)
cosmos_result=$(echo $cosmos_json_result | jq -r '"The VM numbered *" + ."vm_index" + "* with ID *" + ."id" + "* wrote (and read) a message: *" + ."message" + "* ."')

# Compose Slack message
vm_message=":rocket: Virtual Machine *$(hostname)* just got created in *$LOCATION*\n:clock3: Time of creation: $(TZ='Europe/Sofia' date '+%d %B %Y at %H:%M:%S %Z')\n"
db_message="\nThe VM has written to database *$DATABASE_NAME* and has read the following entry from it:\n:tada: $cosmos_result :tada:\n"
payload=$(cat << EOF
{
	"blocks": [
		{
			"type": "section",
			"text": {
				"type": "mrkdwn",
				"text": "$vm_message $db_message"
			}
		},
		{
			"type": "section",
			"text": {
				"type": "plain_text",
				"text": " "
			}
		}
	]
}
EOF
)

# Send Slack notification
result=$(curl -s -X POST -H 'Content-type: application/json' --data "$payload" "$SLACK_URL")
if [[ $result == "ok" ]]; then
	slack="A notification has been sent to Slack"
else
	slack="The VM failed to send a Slack notification. Check VM logs for more info."
	export CURL_SLACK_RESULT=$result
fi

# Create simple HTML page showing server ID
cat > /var/www/html/index.html << HTML
<!DOCTYPE html>
<html>
<head><title>Load Balancer Test</title></head>
<body style="font-family: Arial; text-align: center; padding: 50px;">
  <h1 style="color: #333;">WEB SERVER $INDEX</h1>
  <h2>Environment: $ENVIRONMENT</h2>
  <p>VM is deployed in <b>$LOCATION</b> location</p>
  <h4>$slack</h4>
  <p>Result from DB write/read operation:<br>$cosmos_result</p>
  <p>Current time: <span id="time"></span></p>
  <div style="background: ${index % 2 == 1 ? "#ab7be3" : "#b4e0b7"}; padding: 20px; margin: 20px; border-radius: 10px;">
    <h3>Server Details</h3>
    <p>This response came from VM Instance Number: $INDEX</p>
    <p>Refresh to see load balancing in action!</p>
  </div>
  <script>
    document.getElementById('time').textContent = new Date().toLocaleString();
  </script>
</body>
</html>
HTML

systemctl restart nginx # Restart nginx service to apply changes
