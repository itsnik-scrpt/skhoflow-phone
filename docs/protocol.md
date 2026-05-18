# SkhoFlow wire protocol v2

Two transports, three channels. Pairing is HTTP/JSON over TCP; the stream itself is RTP/UDP for video + audio and WebSocket for input.

```
+------------+              +-----------------+              +------------+
|  iPhone    | -- HTTP -->  | Windows host    | <-- HTTP --  | (admin UI) |
|  client    |              | :47990 control  |              +------------+
|            | <- RTP/UDP - | :47989 video    |
|            | <- RTP/UDP - | :47988 audio    |
|            | <-- WS ----> | :47991 input    |
+------------+              +-----------------+
```

## 1. Discovery (UDP)

- Client broadcasts `SKHO?` on UDP **47988**.
- Host replies with JSON `{ "type": "SKHO!", "id": <uuid>, "name": <hostname>, "port": <controlPort>, "version": 2 }`.
- The client uses the source IP of the reply as the host address.

> Until mDNS / Bonjour is wired, this is the discovery mechanism. The iOS app also has a manual "type an IP" fallback.

## 2. Pairing (HTTP/JSON on the control port)

All endpoints accept and return JSON. The host shows a 6-digit PIN in its UI; the client must echo it within 2 minutes.

### `GET /info`

```json
{
  "id": "5e1f...",
  "name": "RYZEN-DESK",
  "version": 2,
  "requirePin": true,
  "protocol": "skhoflow/2.0"
}
```

### `POST /pair`

Request:
```json
{
  "name": "Niko's iPhone",
  "model": "iPhone16,2",
  "publicKey": "<base64 P-256 SPKI>",
  "pin": "841502"
}
```

Response 200:
```json
{ "deviceId": "9f3c..." }
```

Errors: 403 `{ "error": "wrong_pin" | "no_pin_pending" }`.

### `POST /unpair`

```json
{ "deviceId": "9f3c..." }
```

### `POST /session/start`

Request:
```json
{ "deviceId": "9f3c..." }
```

Response:
```json
{
  "videoPort": 47989,
  "controlPort": 47991,
  "stream": {
    "width": 1920, "height": 1080, "fps": 60,
    "bitrateKbps": 20000, "codec": "h264", "audioBitrateKbps": 192
  }
}
```

### `POST /session/stop`

Closes the active session for that device.

## 3. Video (UDP, RTP-like)

- H.264 Annex-B or HEVC NALUs, fragmented per RFC 6184 / 7798.
- Packet header: `seq | timestamp | flags | length`.
- Keyframe request from client → host as a single UDP control packet on the same port.

## 4. Audio (UDP, RTP-like)

- Opus frames at 48 kHz, 2-channel, 10 ms frames.
- Smaller jitter buffer (40 ms target) than video.

## 5. Input (WebSocket, JSON)

```json
{ "t": "touch", "id": 0, "phase": "began", "x": 0.51, "y": 0.42 }
{ "t": "key", "code": 65, "down": true }
{ "t": "gamepad", "buttons": 0x0080, "lx": 0.12, "ly": -0.55 }
```

Coordinates are normalized to `[0, 1]` so they survive any aspect-ratio negotiation.

## 6. Security roadmap (post-scaffold)

| Layer | Plan |
|-------|------|
| Pairing | Replace PIN with PIN + ECDSA P-256 keypair; client sends pubKey on first pair; host signs a cert for that client |
| Transport | Upgrade `/control` to TLS 1.3 (self-signed cert pinned by the iOS keychain) |
| Video/audio | SRTP keyed off the pairing handshake |
| Input | DTLS, same key material as SRTP |
