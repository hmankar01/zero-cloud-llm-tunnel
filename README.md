# Zero-Cloud Mobile LLM Pipeline (macOS + WireGuard + Ollama)

A bare-metal, peer-to-peer inference pipeline for streaming 27B+ parameter local LLMs from an Apple Silicon MacBook to an iOS client over 5G cellular—with **zero cloud relays**, **zero third-party VPN accounts (no Tailscale/Cloudflare)**, and **strict network interface isolation**.

## ⚡ Benchmarks (Apple M5 Pro — 17.8 GiB Unified GPU Memory)
* **Model:** `Qwen3.6-27B` / `Devstral:24B` (100% offloaded to Metal GPU)
* **Prompt Evaluation:** `217.43 tokens/sec`
* **Generation Speed (over 5G UW):** `~15.72 tokens/sec`
* **Third-Party Cloud Relays:** `0`

## 🏗️ Architecture & Security Model
Most local LLM remote setups bind Ollama to `0.0.0.0:11434` (exposing the inference server to the entire local LAN/Wi-Fi subnet) and rely on third-party coordination servers for NAT traversal. 

This setup locks the stack down to the bare metal:
1. **Cryptographic Transport:** Uses a raw `utun` WireGuard interface (`wg0`) on macOS (`10.10.10.1/24`) paired via offline ANSI QR code (`qrencode`) to an iOS peer (`10.10.10.2/32`).
2. **Strict Interface Binding:** The `wg-vibe.sh` daemon kills stray localhost Ollama processes and binds the server exclusively to `10.10.10.1:11434`. Local Wi-Fi devices cannot see or query the port.
3. **Stealth 5G Ingress:** Home gateway routes UDP port `51820` to a static DHCP lease on the MacBook. Any unauthenticated packet hitting port `51820` from the public internet is silently dropped at the WireGuard cryptographic handshake layer before ever reaching the application layer.

---

## 🚀 Quick Start

### 1. Prerequisites (macOS)
```bash
brew install wireguard-tools qrencode ollama
```

### 2. Provision Cryptographic Keys & Tunnel
Generate independent keypairs for the macOS server and iOS client inside `~/.wireguard` (with `umask 077`), configure `/opt/homebrew/etc/wireguard/wg0.conf` on subnet `10.10.10.1/24` listening on UDP `51820`, and generate an offline terminal QR code for the iOS WireGuard app:
```bash
qrencode -t ansiutf8 < ~/.wireguard/iphone.conf
```

### 3. Bring Up the Tunnel & Locked-Down LLM Server
Start the WireGuard interface and launch the daemon wrapper with `caffeinate` so macOS stays awake while serving requests over 5G:
```bash
sudo wg-quick up wg0
chmod +x wg-vibe.sh
caffeinate -dimsu ./wg-vibe.sh
```

### 4. Connect from iOS (Enchanted / Open-WebUI)
* Toggle the WireGuard profile **ON** on your iPhone (over 5G or Wi-Fi).
* Point your iOS client endpoint to `http://10.10.10.1:11434`.
