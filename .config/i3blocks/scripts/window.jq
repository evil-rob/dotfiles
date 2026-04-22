#!/usr/bin/env -S jq --unbuffered -cf

if .change == "focus" or .change == "title" then
  ..
  | select(type == "object" and .focused == true)
  | { "label": " ", "full_text": .name }
elif .change == "close" then
  { "label": " ", "full_text": "" }
else
  empty
end
