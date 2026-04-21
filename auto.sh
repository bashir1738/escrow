#!/bin/bash

echo "Running daily update..."

git add .

if ! git diff --cached --quiet; then
  git commit -m "daily auto update $(date)"
  git push
else
  echo "No changes to commit"
fi

