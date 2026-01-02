#!/bin/bash
set -e

echo "Pranjal OM1 Node setup starting..."
sleep 1

# Homebrew
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "Installing dependencies..."
brew install python uv portaudio ffmpeg git -q

cd ~

# Clone OM1
if [ ! -d "pranjal-om1" ]; then
  git clone https://github.com/openmind/OM1.git pranjal-om1
fi

cd pranjal-om1
git submodule update --init

echo "Setting up virtual environment..."
if [ ! -d ".venv" ]; then
  uv venv
fi
source .venv/bin/activate

# -------- API KEY (force real terminal input + never allow empty) --------
API_KEY=""

# Ensure we have a real terminal to ask for input
if [ ! -r /dev/tty ]; then
  echo "Error: No terminal available for API key input."
  echo "Run the script directly in a normal Terminal window."
  exit 1
fi

while [ -z "$API_KEY" ]; do
  echo "" > /dev/tty
  echo "Enter your OpenMind API key (input hidden, paste and press Enter):" > /dev/tty

  # hide input while typing/pasting
  stty -echo < /dev/tty
  IFS= read -r API_KEY < /dev/tty
  stty echo < /dev/tty

  echo "" > /dev/tty

  if [ -z "$API_KEY" ]; then
    echo "API key cannot be empty. Try again." > /dev/tty
  fi
done
# ------------------------------------------------------------------------

# Ensure .env exists
if [ ! -f ".env" ]; then
  cp env.example .env
fi

# Escape key for safe insertion
SAFE_KEY=$(printf '%s\n' "$API_KEY" | sed 's/[\/&]/\\&/g')

# Write OM_API_KEY reliably (replace if exists, append if missing)
if grep -q '^OM_API_KEY=' .env; then
  sed -i '' "s|^OM_API_KEY=.*|OM_API_KEY=$SAFE_KEY|" .env
else
  echo "" >> .env
  echo "OM_API_KEY=$SAFE_KEY" >> .env
fi

echo ""
echo "API key added successfully ✅"
echo "--------------------------------"
grep '^OM_API_KEY=' .env
echo "--------------------------------"

echo ""
echo "Starting OM1 node..."
sleep 1
uv run src/run.py conversation
