#!/usr/bin/env bash
FILE_NAME="git-prompt.sh"
SOURCE_FILE_PATH="$(dirname $0)/scripts/$FILE_NAME"
TARGET_PATH="$HOME/.config/git/"
echo $SOURCE_FILE_PATH
echo $TARGET_PATH
cp "$SOURCE_FILE_PATH" "$TARGET_PATH"