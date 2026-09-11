#!/bin/bash
COUNT_FILE="/root/personalization/audit/iar/continuo/context_budget_count.txt"
THRESHOLD=200

if [ ! -f "$COUNT_FILE" ]; then
    echo 0 > "$COUNT_FILE"
fi

COUNT=$(cat "$COUNT_FILE")
COUNT=$((COUNT + 1))

if [ "$COUNT" -ge "$THRESHOLD" ]; then
    echo "Context budget threshold reached: $COUNT tool calls (approx $((COUNT*2)) msgs). Stopping."
    exit 1
fi

echo $COUNT > "$COUNT_FILE"

"$@"
