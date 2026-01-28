#!/usr/bin/env zsh

# Fail on errors
set -e

echo "🔄 Fetching latest changes from upstream..."
git fetch upstream

echo "🔍 Checking out master/main branch..."
git checkout master 2>/dev/null || git checkout main

echo "📥 Merging upstream changes..."
git merge upstream/master -m "Merge changes from upstream"

echo "✅ Merge completed. Push to your private origin repo? (y/n)"
read confirm
if [[ $confirm == "y" ]]; then
    git push origin HEAD
    echo "🚀 Changes pushed to origin."
else
    echo "🛑 Push skipped. You can manually push with: git push origin HEAD"
fi
