import sys
import os
import slack

email=sys.argv[1]
client = slack.WebClient(token=os.environ["SLACK_TOKEN"])

try:
  user_id = client.users_lookupByEmail(email=email)['user']['id']
  print(f"<@{user_id}> is responsible")
except:
  print(f"<!here> {email} is responsible, but I couldn't find them on Slack")
