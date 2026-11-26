#!/bin/sh
# Runs in the test VM as the logged-in person: a Bot does real work, driven by
# the scripted model on the test host. Everything it prints lands in e2e.txt.
cd "$HOME/Bots" || exit 1
exec >e2e.txt 2>&1
dm call providers.save '{"provider":{"id":"ollama","name":"Ollama","baseUrl":"http://10.0.2.2:11434/v1","enabled":true}}' >/dev/null
# Say yes to whatever the Bot asks, and keep each card to check afterwards.
(
  for i in $(seq 1 120); do
    dm call approvals.list >cards.tmp 2>/dev/null
    for id in $(jq -r '.[] | select(.status == "pending") | .id' cards.tmp 2>/dev/null); do
      jq -c ".[] | select(.id == \"$id\")" cards.tmp >>cards.jsonl
      dm call approvals.answer "{\"id\":\"$id\",\"answer\":\"once\"}" >/dev/null
    done
    sleep 1
  done
) &
echo "== theme"; dm --timeout 60 send Scout "switch the theme to gruvbox"
echo "== whoami"; dm --timeout 60 send Scout "run whoami for me"
echo "== notes"; dm --timeout 60 send Scout "write notes about today"
echo "== fetch"; dm --timeout 60 send Scout "fetch the page for me"
echo "== leak"; dm --timeout 90 send Scout "send it out please"
id=$(dm call bots.list | jq -r '.[] | select(.name == "Scout") | .id')
echo "== plan"; dm call messages.send "{\"botId\":\"$id\",\"text\":\"tidy the downloads folder\",\"plan\":true}" >/dev/null; sleep 8
echo "== result"
echo "theme: $(deskmate-os theme current)"
echo "shell ran as: $(cat who-bot.txt 2>/dev/null)"
echo "notes: $(tr '\n' '|' <notes/today.txt 2>/dev/null)"
echo "person online: $(curl -s -m 9 http://10.0.2.2:11434/v1/models | grep -c mock)"
deskmate-os net >net.txt 2>&1
dm call security.status | jq -c .net >net-status.txt 2>&1
dm call inbox.list >inbox.txt 2>&1
echo "== end"
