#!/bin/bash
set -e

echo "========================================"
echo "   Pranjal OM1 Node Setup (macOS)        "
echo "========================================"
sleep 1

# Check Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing now..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo ""
echo "Installing required packages..."
brew install python uv git ffmpeg portaudio -q

BASE_DIR="$HOME/pranjal-om1"

if [ ! -d "$BASE_DIR" ]; then
  echo "Downloading OM1 source code..."
  git clone https://github.com/openmind/OM1.git "$BASE_DIR"
fi

cd "$BASE_DIR"
git submodule update --init

echo ""
echo "Setting up Python environment..."
uv venv
source .venv/bin/activate

echo ""
read -p "Enter your OpenMind API key: " OM_KEY

if [ ! -f ".env" ]; then
  cp env.example .env
fi

ESCAPED_KEY=$(printf '%s\n' "$OM_KEY" | sed 's/[\/&]/\\&/g')
sed -i '' "s|^OM_API_KEY=.*|OM_API_KEY=$ESCAPED_KEY|" .env

echo ""
echo "API key saved ✅"
echo ""
echo "Setup complete."
echo ""
echo "To start the OM1 node, run:"
echo ""
echo "  cd $BASE_DIR"
echo "  source .venv/bin/activate"
echo "  uv run src/run.py conversation"
echo ""
