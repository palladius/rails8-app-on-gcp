#!/bin/bash
# Script to test if emails are correctly sent to Mailpit
set -e

echo "✉️ Sending a test email using Rails runner..."
docker compose run --rm -e SMTP_HOST=mail jobs bin/rails runner "user = User.first || User.create!(email_address: 'ricc@example.com', password: 'password'); UserMailer.with(user: user).welcome.deliver_now"

echo "✅ Email sent. Verifying in Mailpit..."
sleep 2

MESSAGES=$(curl -s http://localhost:8025/api/v1/messages)
TOTAL=$(echo "$MESSAGES" | jq '.total')

if [ "$TOTAL" -gt 0 ]; then
  echo "🎉 Success! Found $TOTAL messages in Mailpit."
  echo "Last message subject: $(echo "$MESSAGES" | jq -r '.messages[0].Subject')"
  echo "View them at http://localhost:8025/"
else
  echo "❌ Failed to find messages in Mailpit."
  exit 1
fi
