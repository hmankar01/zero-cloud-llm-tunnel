#!/usr/bin/env bash
# wg-vibe.sh — Zero-Cloud Ollama Daemon Wrapper for WireGuard
# Binds Ollama strictly to the encrypted WireGuard interface (10.10.10.1)

set -e

WG_IP="10.10.10.1"
PORT="11434"
OLLAMA_PID=""

cleanup() {
    if [[ -n "$OLLAMA_PID" ]]; then
        echo ""
        echo "[INFO] Shutting down Ollama server (PID: $OLLAMA_PID)..."
        kill "$OLLAMA_PID" 2>/dev/null || true
        wait "$OLLAMA_PID" 2>/dev/null || true
        echo "[OK] Closed cleanly."
    fi
    exit 0
}

trap cleanup SIGINT SIGTERM

echo "[INFO] Checking WireGuard tunnel ($WG_IP)..."
if ! ifconfig | grep -q "$WG_IP"; then
    echo "[ERROR] WireGuard interface ($WG_IP) is not active!"
    echo "Run: sudo wg-quick up wg0"
    exit 1
fi

echo "[INFO] Stopping any default background Ollama daemons..."
pkill -f "ollama serve" 2>/dev/null || true
sleep 1

echo "[INFO] Binding Ollama strictly to $WG_IP:$PORT..."
export OLLAMA_HOST="http://${WG_IP}:${PORT}"

ollama serve &
OLLAMA_PID=$!

echo "[OK] Ollama is live on $OLLAMA_HOST! Streaming logs below (Press Ctrl+C to stop):"
echo "----------------------------------------------------------------------"
wait "$OLLAMA_PID"
