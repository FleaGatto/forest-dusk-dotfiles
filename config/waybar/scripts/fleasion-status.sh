#!/usr/bin/env bash
if pgrep -if 'fleasion.*launcher\.py' >/dev/null 2>&1; then
    echo '{"text": "󰖂 Fleasion", "class": "on", "tooltip": "Fleasion is running"}'
else
    echo '{"text": "󰖂 Fleasion", "class": "off", "tooltip": "Fleasion is not running"}'
fi
