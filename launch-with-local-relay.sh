#!/bin/bash

# Launch Geogram Desktop with Local Relay for testing
# This script starts both the relay server and desktop app

set -e

# Try to add Flutter to PATH if not already available
if ! command -v flutter &> /dev/null; then
    # Check common Flutter installation locations
    if [ -d "$HOME/flutter/bin" ]; then
        export PATH="$PATH:$HOME/flutter/bin"
    elif [ -d "/opt/flutter/bin" ]; then
        export PATH="$PATH:/opt/flutter/bin"
    elif [ -d "/usr/local/flutter/bin" ]; then
        export PATH="$PATH:/usr/local/flutter/bin"
    fi
fi

echo "=================================================="
echo "  Geogram Desktop + Local Relay Development"
echo "=================================================="
echo ""

# Determine script directory and derive paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_DIR="$SCRIPT_DIR"
RELAY_DIR="$(dirname "$SCRIPT_DIR")/geogram-relay"

# Check if relay exists
if [ ! -d "$RELAY_DIR" ]; then
    echo "Error: Relay directory not found at $RELAY_DIR"
    exit 1
fi

# Build relay if needed
echo "[1/3] Checking relay build..."
if [ ! -f "$RELAY_DIR/target/geogram-relay-1.0.0.jar" ]; then
    echo "Building relay..."
    cd "$RELAY_DIR"
    mvn clean package -q
    if [ $? -ne 0 ]; then
        echo "Relay build failed!"
        exit 1
    fi
    echo "✓ Relay built successfully"
else
    echo "✓ Relay already built"
fi

# Check if relay is already running on port 8080
echo ""
echo "[2/3] Starting local relay..."
echo "URL: ws://localhost:8080"

# Check for existing process on port 8080
EXISTING_PID=$(lsof -ti:8080 2>/dev/null || true)
if [ ! -z "$EXISTING_PID" ]; then
    echo "  Found existing process on port 8080 (PID: $EXISTING_PID)"
    echo "  Stopping existing relay..."
    kill $EXISTING_PID 2>/dev/null || true
    sleep 1
    # Force kill if still running
    if kill -0 $EXISTING_PID 2>/dev/null; then
        kill -9 $EXISTING_PID 2>/dev/null || true
    fi
    echo "  ✓ Stopped"
fi

cd "$RELAY_DIR"
java -jar target/geogram-relay-1.0.0.jar > /tmp/geogram-relay.log 2>&1 &
RELAY_PID=$!
echo "✓ Relay started (PID: $RELAY_PID)"
echo "  Log: tail -f /tmp/geogram-relay.log"

# Wait for relay to start
echo "  Waiting for relay to initialize..."
sleep 3

# Check if relay is still running
if ! kill -0 $RELAY_PID 2>/dev/null; then
    echo "✗ Relay failed to start. Check log:"
    tail -20 /tmp/geogram-relay.log
    exit 1
fi

echo "✓ Relay is running"

# Build desktop if needed
echo ""
echo "[3/3] Starting desktop app..."
cd "$DESKTOP_DIR"

# Get Flutter packages if needed
if [ ! -d ".dart_tool" ]; then
    echo "Getting Flutter packages..."
    flutter pub get
fi

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter not found in PATH"
    echo ""
    echo "Please ensure Flutter is installed and in your PATH."
    echo "You can add it to your PATH by adding this to ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\"\$PATH:\$HOME/flutter/bin\""
    echo ""
    echo "Or run Flutter manually:"
    echo "  cd $DESKTOP_DIR"
    echo "  /path/to/flutter/bin/flutter run -d linux"
    echo ""
    echo "The relay is still running at ws://localhost:8080 (PID: $RELAY_PID)"
    echo "To stop it: kill $RELAY_PID"
    exit 1
fi

# Launch desktop app
echo "✓ Launching Geogram Desktop"
echo ""
echo "=================================================="
echo "  Setup Instructions"
echo "=================================================="
echo ""
echo "1. Desktop app will open shortly"
echo "2. Go to 'Internet Relays' page"
echo "3. Click '+ Add Relay' button"
echo "4. Enter:"
echo "   - Name: Local Dev Relay"
echo "   - URL: ws://localhost:8080"
echo "5. Click 'Add'"
echo "6. Click 'Set Preferred'"
echo "7. Click 'Test' to connect"
echo ""
echo "Watch the log window for hello messages!"
echo ""
echo "=================================================="
echo "  Running Services"
echo "=================================================="
echo ""
echo "Relay:   ws://localhost:8080 (PID: $RELAY_PID)"
echo "Logs:    tail -f /tmp/geogram-relay.log"
echo ""
echo "Press Ctrl+C to stop both services"
echo "=================================================="
echo ""

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Stopping services..."
    if kill -0 $RELAY_PID 2>/dev/null; then
        kill $RELAY_PID
        echo "✓ Relay stopped"
    fi
    exit 0
}

trap cleanup EXIT INT TERM

# Launch desktop app (this will block until app exits)
flutter run -d linux

# Cleanup will happen automatically via trap
