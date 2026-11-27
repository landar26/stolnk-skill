---
name: stolnk-push
description: Send files (especially AI-generated HTML reports, interactive pages, Markdown summaries, images, or build artifacts) directly to the user's iPhone via their Stolnk inbox URL (https://<name>.stolnk.com). Use when the user asks to "send this to my phone", "push to my iPhone", "send to <name>.stolnk.com", or wants to read generated HTML/Markdown output on mobile.
---

# Stolnk Push (`stolnk-push`)

Push any file up to 95 MiB straight to the user's iPhone **Received** folder via their Stolnk address (`https://<name>.stolnk.com`).

HTML files render natively as web pages on iPhone; Markdown files render formatted—no zip, no cable, no messaging app compression, and it delivers even if the iPhone is offline.

## Step-by-Step Procedure

### 1. Determine the Stolnk Address

- Check whether the user already provided their Stolnk address in the current prompt, conversation history, or workspace instructions (e.g., `ryan`, `ryan.stolnk.com`, or `https://ryan.stolnk.com`).
- Normalize it to `https://<name>.stolnk.com` (strip any trailing slash).
- If no address is known, **ask the user** for their Stolnk address (`<name>.stolnk.com`) before uploading.

### 2. Prepare the File

- Ensure the content is saved to a **real local file path** on disk. Do **not** pipe from stdin (`file=@-`), because the server requires an exact `Content-Length` header.
- Check that the file size is **≤ 95 MiB** (`99,614,720` bytes). If larger, do not attempt `curl`; instruct the user to drop the file on `https://<name>.stolnk.com` in a browser (supports up to 2 GB Free / 20 GB Member with browser-side E2E encryption).
- For **multiple files**, send them in separate `curl` requests (the endpoint accepts strictly **one file per request**).
- For **HTML output**, generate a self-contained single-file HTML (inline CSS/JS, `<meta name="viewport" content="width=device-width, initial-scale=1">`) so it renders cleanly on iPhone without broken relative assets.
- For **Markdown**, standard `.md` files render formatted natively inside Stolnk.

### 3. (Optional) Check Inbox Capabilities

If you need to verify whether an inbox exists, is accepting files, or requires a password:

```bash
curl -sS "https://<name>.stolnk.com?format=json"
```

The JSON response reports `accepting`, `recipientOnline`, `upload.maxBytesPerRequest`, and `upload.passwordField` (present if password-protected).

### 4. Upload the File with `curl`

Standard inbox:

```bash
curl --fail-with-body -sS -F "file=@/path/to/report.html" "https://<name>.stolnk.com"
```

Password-protected inbox (use the `X-Stolnk-Password` header, or place `-F "password=..."` **before** `-F "file=@..."` — fields after `file` are rejected):

```bash
curl --fail-with-body -sS -H "X-Stolnk-Password: <password>" -F "file=@/path/to/report.html" "https://<name>.stolnk.com"
```

### 5. Handle the Response

A successful upload returns HTTP `202 Accepted` with JSON:

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

#### Common Errors

- **`401 Unauthorized`**: The inbox is password-protected or the password is wrong. Ask the user for the inbox password and retry with `-H "X-Stolnk-Password: <password>"`.
- **`404 Not Found`**: The inbox does not exist. Ask the user to verify the spelling of `<name>.stolnk.com`.
- **`423 Locked`**: The inbox is currently paused and not accepting files. Inform the user.
- **`413` / quota error**: File exceeds 95 MiB or the recipient's monthly relay allowance is full. Tell the user to upload via the browser page (`https://<name>.stolnk.com`).

## Privacy & Security Note

Unlike the browser send page (which encrypts end-to-end on the sender's device), the `curl` route sends plaintext over HTTPS to Stolnk's edge worker, which immediately encrypts it with the recipient's public key before storage. Do not use `curl` for raw secrets or credentials that must never touch a server in plaintext; tell the user to use the browser send page instead.
