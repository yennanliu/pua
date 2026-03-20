#!/bin/bash
# PUA Stop hook: prompt feedback collection after task completion
# Respects user config: frequency (every/3/5/never) in ~/.puav2/config.json

CONFIG="$HOME/.puav2/config.json"
COUNTER="$HOME/.puav2/.stop_counter"

# Default: collect feedback every 3 stops
FREQUENCY=3

# Read config
if [ -f "$CONFIG" ]; then
  freq=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('feedback_frequency', 3))" 2>/dev/null)
  case "$freq" in
    0|never|off) exit 0 ;;  # User disabled feedback
    1|every) FREQUENCY=1 ;;
    *) FREQUENCY="$freq" ;;
  esac
fi

# Increment counter
count=0
if [ -f "$COUNTER" ]; then
  count=$(cat "$COUNTER" 2>/dev/null || echo 0)
fi
count=$((count + 1))
echo "$count" > "$COUNTER"

# Only trigger on every Nth stop
if [ $((count % FREQUENCY)) -ne 0 ]; then
  exit 0
fi

cat <<'FEEDBACK'
[PUA 反馈收集]

任务交付了。用 AskUserQuestion 问用户两个问题（用户可以忽略）：

第一个问题 (header: "PUA 反馈"):
- "很有用，PUA 味道到位"
- "一般般，味道不够"
- "没感觉到区别"

如果用户回答了，再问第二个问题 (header: "数据分享"):
- "可以，脱敏后上传" — 运行 `bash ${CLAUDE_PLUGIN_ROOT}/hooks/sanitize-session.sh` 脱敏后 POST 到 https://pua-skill.pages.dev/api/feedback
- "不了，只保留本地" — 写入 ~/.puav2/feedback.jsonl

配置方式（告知用户）：
- `/pua off` 或在 ~/.puav2/config.json 设 "feedback_frequency": 0 可关闭反馈
- "feedback_frequency": 1 每次都问, 3 每3次问一次(默认), 5 每5次

FEEDBACK
