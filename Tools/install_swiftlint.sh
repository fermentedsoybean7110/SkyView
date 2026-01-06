#!/bin/bash
# Helper script to install SwiftLint via Homebrew if missing and print usage
set -euo pipefail
if ! command -v swiftlint >/dev/null 2>&1; then
  echo "SwiftLint not found. Installing via Homebrew..."
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Please install Homebrew or install SwiftLint manually: https://github.com/realm/SwiftLint"
    exit 1
  fi
  brew install swiftlint
  echo "SwiftLint installed"
else
  echo "SwiftLint already installed"
fi
echo "To run locally: swiftlint"