---
name: stolnk-push
description: Send files (especially AI-generated HTML reports, interactive pages, Markdown summaries, images, or build artifacts) directly to the user's iPhone via their Stolnk inbox URL (https://<name>.stolnk.com). Use when the user asks to "send this to my phone", "push to my iPhone", "save to <name>.stolnk.com", or wants to read generated HTML/Markdown output on mobile.
---

# Stolnk Push (`stolnk-push`)

Push any file up to 95 MiB straight to the user's iPhone **Received** folder via their Stolnk address (`https://<name>.stolnk.com`).

HTML files render natively as web pages on iPhone; Markdown files render formatted—no zip, no cable, no messaging app compression, and it delivers even if the iPhone is offline.

## Configuration

Check for the user's Stolnk address in this order:
1. Explicitly mentioned in the user's prompt (e.g. `ryan.stolnk.com` or `https://ryan.stolnk.com`)
2. Environment variable `STOLNK_INBOX` (accepts either `ryan` or `https://ryan.stolnk.com`)
3. Optional password in `STOLNK_PASSWORD` (only if the inbox is password-protected)

If no inbox address is known, ask the user for their Stolnk address (`<name>.stolnk.com`).

## How to Send a File

### Option 1: Direct `curl` (no script needed)

```bash
curl --fail-with-body -F "file=@/path/to/report.html" "https://<name>.stolnk.com"
```

With a password-protected inbox:

```bash
curl --fail-with-body -F "password=$STOLNK_PASSWORD" -F "file=@/path/to/report.html" "https://<name>.stolnk.com"
```

### Option 2: Helper script

Run `scripts/stolnk-push.sh`:

```bash
./scripts/stolnk-push.sh /path/to/report.html [inbox]
```

## Best Practices for AI Agents

- **HTML reports**: Prefer self-contained single-file HTML (inline CSS/JS, responsive mobile viewport `<meta name="viewport" content="width=device-width, initial-scale=1">`) so it renders cleanly on iPhone immediately without broken external relative assets.
- **Markdown**: Standard `.md` files render with formatting directly inside Stolnk.
- **File size limit**: The terminal (`curl`) route accepts **one file per request, up to 95 MiB**. If sending multiple files, send them in separate requests. If a file exceeds 95 MiB, tell the user to drop it via the browser page (`https://<name>.stolnk.com`) instead (which supports up to 2 GB Free / 20 GB Member with browser-side E2E encryption).
- **Security note**: Unlike the browser send page (which encrypts client-side), the `curl` route sends plaintext over TLS to Stolnk's edge worker, which immediately encrypts it with the iPhone's public key before storage. Do not use the `curl` route for secrets or credentials that must never touch a server in plaintext; use the browser send page instead.
- **Capability discovery**: `GET https://<name>.stolnk.com?format=json` returns machine-readable limits and status for any inbox.

## Response Handling

A successful upload returns JSON like:

```json
{
  "accepted": true,
  "inbox": "ryan",
  "file": { "name": "report.html", "size": 12338, "id": "..." },
  "recipientOnline": false,
  "message": "Accepted. It will be delivered when ryan next comes online..."
}
```

Confirm the filename, size, and delivery status (`recipientOnline` or queued for next open) concisely to the user.
