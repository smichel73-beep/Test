"""
Creates top-level OneDrive folders via Microsoft Graph API.

Setup:
  1. Register an app in Azure Portal (https://portal.azure.com)
     -> Azure Active Directory -> App registrations -> New registration
  2. Add API permission: Microsoft Graph -> Delegated -> Files.ReadWrite
  3. Set REDIRECT_URI to http://localhost:8080
  4. Copy Client ID and (optional) Client Secret into the config below
     or export them as environment variables:
       export ONEDRIVE_CLIENT_ID=<your-client-id>
       export ONEDRIVE_CLIENT_SECRET=<your-client-secret>  # leave blank for public client
  5. pip install requests
  6. python create_onedrive_folders.py
"""

import os
import json
import webbrowser
import urllib.parse
import urllib.request
from http.server import HTTPServer, BaseHTTPRequestHandler

CLIENT_ID = os.getenv("ONEDRIVE_CLIENT_ID", "YOUR_CLIENT_ID_HERE")
CLIENT_SECRET = os.getenv("ONEDRIVE_CLIENT_SECRET", "")
REDIRECT_URI = "http://localhost:8080"
SCOPES = "Files.ReadWrite offline_access"
AUTHORITY = "https://login.microsoftonline.com/common"

FOLDERS = [
    "01_Arbeit",
    "02_Organisation",
    "03_Schule & Familie",
    "04_Projekte",
    "05_Technik & Tools",
    "99_Eingang (temporär!)",
]


# ── OAuth2 device-code / auth-code flow ──────────────────────────────────────

_auth_code: str | None = None


class _CallbackHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        global _auth_code
        params = dict(urllib.parse.parse_qsl(urllib.parse.urlparse(self.path).query))
        _auth_code = params.get("code")
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"<h2>Authorisation complete. You can close this tab.</h2>")

    def log_message(self, *_):
        pass


def _get_token() -> str:
    auth_url = (
        f"{AUTHORITY}/oauth2/v2.0/authorize?"
        + urllib.parse.urlencode(
            {
                "client_id": CLIENT_ID,
                "response_type": "code",
                "redirect_uri": REDIRECT_URI,
                "scope": SCOPES,
            }
        )
    )
    print("Opening browser for Microsoft login …")
    webbrowser.open(auth_url)

    server = HTTPServer(("localhost", 8080), _CallbackHandler)
    server.handle_request()

    data = {
        "client_id": CLIENT_ID,
        "grant_type": "authorization_code",
        "code": _auth_code,
        "redirect_uri": REDIRECT_URI,
        "scope": SCOPES,
    }
    if CLIENT_SECRET:
        data["client_secret"] = CLIENT_SECRET

    req = urllib.request.Request(
        f"{AUTHORITY}/oauth2/v2.0/token",
        data=urllib.parse.urlencode(data).encode(),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        token_data = json.loads(resp.read())

    return token_data["access_token"]


# ── Graph API helpers ─────────────────────────────────────────────────────────

def _api(method: str, url: str, token: str, body: dict | None = None):
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode() if body else None,
        headers=headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as exc:
        body_text = exc.read().decode()
        raise RuntimeError(f"HTTP {exc.code}: {body_text}") from exc


def create_folder(name: str, token: str) -> dict:
    url = "https://graph.microsoft.com/v1.0/me/drive/root/children"
    payload = {
        "name": name,
        "folder": {},
        "@microsoft.graph.conflictBehavior": "fail",
    }
    return _api("POST", url, token, payload)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    if CLIENT_ID == "YOUR_CLIENT_ID_HERE":
        raise SystemExit(
            "Please set ONEDRIVE_CLIENT_ID (see instructions at the top of this file)."
        )

    token = _get_token()
    print()
    for folder in FOLDERS:
        try:
            result = create_folder(folder, token)
            print(f"  ✓  {result['name']}")
        except RuntimeError as exc:
            if "nameAlreadyExists" in str(exc):
                print(f"  –  {folder}  (already exists, skipped)")
            else:
                print(f"  ✗  {folder}  →  {exc}")

    print("\nDone.")


if __name__ == "__main__":
    main()
