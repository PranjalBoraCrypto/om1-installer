#!/bin/bash

set -e

echo "Pranjal OM1 Node setup starting..."
sleep 1

if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "Installing required dependencies..."
brew install python uv portaudio ffmpeg git -q

cd ~
if [ ! -d "pranjal-om1" ]; then
    git clone https://github.com/openmind/OM1.git pranjal-om1
fi

cd pranjal-om1
git submodule update --init

echo "Creating virtual environment..."
uv venv
source .venv/bin/activate

echo ""
echo "Enter your OpenMind API key:"
read -r API_KEY < /dev/tty

if [ ! -f ".env" ]; then
    cp env.example .env
fi

sed -i '' "s|^OM_API_KEY=.*|OM_API_KEY=$API_KEY|" .env

echo ""
echo "API key added successfully!"
echo "--------------------------------"
grep OM_API_KEY .env
echo "--------------------------------"

echo ""
echo "Starting OM1 node..."
sleep 2
uv run src/run.py conversation
