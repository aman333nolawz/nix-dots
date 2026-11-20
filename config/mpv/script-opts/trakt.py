#!/usr/bin/env python3
"""Trakt backend for scripts/trakt.lua (mpv).

Commands used by the Lua script:

    trakt.py --match <path> [--title <media-title>]
    trakt.py --search <query|path> [--title <media-title>] [--limit N]
    trakt.py --scrobble start|pause|stop --kind movie|episode \
             --trakt-id ID --progress PERCENT

One-time setup (create a Trakt API app at https://app.trakt.tv/settings/apps):

    trakt.py --authorize

Only a Client ID is required. Newer Trakt apps do not have a Client Secret;
if yours has one, it is used when present. Credentials and tokens are stored
under $XDG_DATA_HOME/trakt-mpv (default ~/.local/share/trakt-mpv).
"""

from __future__ import annotations

import argparse
import getpass
import json
import os
import re
import shlex
import sys
import time
import unicodedata
from difflib import SequenceMatcher
from pathlib import Path
from typing import Any

import requests
from guessit import guessit

API_BASE = "https://api.trakt.tv"
OAUTH_DEVICE_CODE = f"{API_BASE}/oauth/device/code"
OAUTH_DEVICE_TOKEN = f"{API_BASE}/oauth/device/token"
OAUTH_TOKEN = f"{API_BASE}/oauth/token"
SITE_BASE = "https://trakt.tv"

_data_home = Path(
    os.environ.get("XDG_DATA_HOME") or (Path.home() / ".local/share")
)
DATA_DIR = _data_home / "trakt-mpv"
CREDENTIALS_PATH = DATA_DIR / "credentials.json"
TOKEN_PATH = DATA_DIR / "token.json"


class TraktError(RuntimeError):
    pass


# ---------------------------------------------------------------------------
# credentials and OAuth


def _save_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        os.chmod(path.parent, 0o700)
    except OSError:
        pass

    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    try:
        os.chmod(tmp, 0o600)
    except OSError:
        pass
    tmp.replace(path)


def _load_json(path: Path) -> dict:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise TraktError(f"Could not read {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise TraktError(f"Unexpected data in {path}")
    return payload


def _authorize_hint() -> str:
    return f"Run: python3 {shlex.quote(sys.argv[0])} --authorize"


def _client_body(client_id: str, client_secret: str | None = None) -> dict:
    """OAuth request body fields. Newer apps have no client secret."""
    body = {"client_id": client_id}
    if client_secret:
        body["client_secret"] = client_secret
    return body


def load_credentials() -> dict:
    if not CREDENTIALS_PATH.exists():
        raise TraktError(
            "Trakt API credentials not found. " + _authorize_hint()
        )
    credentials = _load_json(CREDENTIALS_PATH)
    if not credentials.get("client_id"):
        raise TraktError(
            "Trakt API credentials are incomplete. " + _authorize_hint()
        )
    return credentials


def load_token() -> dict:
    if not TOKEN_PATH.exists():
        raise TraktError("Trakt is not authorized. " + _authorize_hint())
    token = _load_json(TOKEN_PATH)
    if not token.get("access_token") or not token.get("refresh_token"):
        raise TraktError("Stored Trakt token is incomplete. " + _authorize_hint())
    return token


def _token_is_expiring(token: dict, margin: int = 300) -> bool:
    try:
        created_at = float(token.get("created_at") or 0)
        expires_in = float(token.get("expires_in") or 0)
    except (TypeError, ValueError):
        return True
    if not created_at or not expires_in:
        return True
    return time.time() >= created_at + expires_in - margin


def refresh_token(credentials: dict, token: dict) -> dict:
    body = _client_body(
        credentials["client_id"], credentials.get("client_secret")
    )
    body["refresh_token"] = token["refresh_token"]
    body["grant_type"] = "refresh_token"

    response = requests.post(
        OAUTH_TOKEN,
        json=body,
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
            "trakt-api-version": "2",
            "trakt-api-key": credentials["client_id"],
        },
        timeout=20,
    )
    if response.status_code != 200:
        detail = _response_detail(response)
        raise TraktError(
            "Could not refresh the Trakt token"
            + (f" ({detail})" if detail else "")
            + ". "
            + _authorize_hint()
        )

    refreshed = response.json()
    refreshed.setdefault("created_at", int(time.time()))
    _save_json(TOKEN_PATH, refreshed)
    return refreshed


def ensure_token(credentials: dict) -> dict:
    token = load_token()
    if _token_is_expiring(token):
        token = refresh_token(credentials, token)
    return token


def authorize() -> int:
    credentials: dict = {}
    if CREDENTIALS_PATH.exists():
        try:
            credentials = _load_json(CREDENTIALS_PATH)
        except TraktError:
            credentials = {}

    client_id = (
        os.environ.get("TRAKT_CLIENT_ID") or credentials.get("client_id") or ""
    ).strip()
    client_secret = (
        os.environ.get("TRAKT_CLIENT_SECRET")
        or credentials.get("client_secret")
        or ""
    ).strip()

    if not client_id:
        print("Create a Trakt API app at https://app.trakt.tv/settings/apps")
        print("Only the Client ID is required. Newer Trakt apps do not have a")
        print("Client Secret; the redirect URI is not used by device auth.\n")
        client_id = input("Client ID: ").strip()
        if not client_id:
            raise TraktError("A Trakt Client ID is required")

        if not client_secret and sys.stdin.isatty():
            entered = getpass.getpass(
                "Client Secret (optional, press Enter to skip): "
            ).strip()
            if entered:
                client_secret = entered

    stored_credentials = {"client_id": client_id}
    if client_secret:
        stored_credentials["client_secret"] = client_secret
    _save_json(CREDENTIALS_PATH, stored_credentials)

    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "trakt-api-version": "2",
        "trakt-api-key": client_id,
    }
    response = requests.post(
        OAUTH_DEVICE_CODE,
        json={"client_id": client_id},
        headers=headers,
        timeout=20,
    )
    if response.status_code != 200:
        raise TraktError(
            f"Could not start device authorization: {_response_detail(response)}"
        )

    device = response.json()
    verification_url = device.get("verification_url", "https://trakt.tv/activate")
    print(f"\nOpen {verification_url}")
    print(f"Enter code: {device.get('user_code')}\n")

    deadline = time.time() + int(device.get("expires_in") or 600)
    interval = max(1, int(device.get("interval") or 5))

    while time.time() < deadline:
        body = _client_body(client_id, client_secret)
        body["code"] = device["device_code"]
        poll = requests.post(
            OAUTH_DEVICE_TOKEN,
            json=body,
            headers=headers,
            timeout=20,
        )

        if poll.status_code == 200:
            token = poll.json()
            token.setdefault("created_at", int(time.time()))
            _save_json(TOKEN_PATH, token)
            print("Authorized. Trakt tracking is ready.")
            return 0

        if poll.status_code == 400:  # pending
            time.sleep(interval)
            continue
        if poll.status_code == 429:  # polled too quickly
            interval = min(interval * 2, 30)
            time.sleep(interval)
            continue

        raise TraktError(
            f"Authorization failed: {_response_detail(poll)}"
        )

    raise TraktError("Authorization expired. " + _authorize_hint())


# ---------------------------------------------------------------------------
# API client


def _response_detail(response: requests.Response) -> str:
    try:
        payload = response.json()
    except ValueError:
        payload = None

    if isinstance(payload, dict):
        message = payload.get("error_description") or payload.get("message")
        if not message and payload.get("error"):
            message = payload["error"]
        if message:
            return str(message)

    text = response.text.strip()
    return text[:300] if text else f"HTTP {response.status_code}"


class TraktClient:
    def __init__(self) -> None:
        self.credentials = load_credentials()
        self.token = ensure_token(self.credentials)
        self.session = requests.Session()

    def _headers(self, authenticated: bool) -> dict:
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
            "trakt-api-version": "2",
            "trakt-api-key": self.credentials["client_id"],
        }
        if authenticated:
            headers["Authorization"] = f"Bearer {self.token['access_token']}"
        return headers

    def _request(
        self,
        method: str,
        path: str,
        *,
        authenticated: bool = False,
        params: dict | None = None,
        json_body: dict | None = None,
        allow_404: bool = False,
        retry: bool = True,
    ) -> Any:
        response = self.session.request(
            method,
            API_BASE + path,
            headers=self._headers(authenticated),
            params=params,
            json=json_body,
            timeout=20,
        )

        if response.status_code == 401 and authenticated and retry:
            self.token = refresh_token(self.credentials, self.token)
            return self._request(
                method,
                path,
                authenticated=authenticated,
                params=params,
                json_body=json_body,
                allow_404=allow_404,
                retry=False,
            )

        if response.status_code == 404 and allow_404:
            return None

        # A duplicate scrobble is not an error for our purposes.
        if response.status_code == 409 and path.startswith("/scrobble/"):
            try:
                payload = response.json()
            except ValueError:
                payload = {}
            if not isinstance(payload, dict):
                payload = {}
            payload.setdefault(
                "action", "scrobble" if path.endswith("/stop") else path.rsplit("/", 1)[-1]
            )
            return payload

        # Trakt ignores stop scrobbles below 1%.
        if response.status_code == 422 and path.endswith("/scrobble/stop"):
            return {"action": "ignored"}

        if not 200 <= response.status_code < 300:
            raise TraktError(
                f"Trakt API error (HTTP {response.status_code}): "
                f"{_response_detail(response)}"
            )

        if response.status_code == 204 or not response.content:
            return None
        try:
            return response.json()
        except ValueError as exc:
            raise TraktError("Trakt returned invalid JSON") from exc

    def search_movies(
        self, query: str, year: int | None = None, limit: int = 10
    ) -> list[dict]:
        params: dict[str, Any] = {"query": query, "limit": limit, "page": 1}
        if year:
            params["years"] = str(year)
        data = self._request("GET", "/search/movie", params=params)
        return [
            item["movie"]
            for item in data or []
            if item.get("type") == "movie" and isinstance(item.get("movie"), dict)
        ]

    def search_shows(
        self, query: str, year: int | None = None, limit: int = 10
    ) -> list[dict]:
        params: dict[str, Any] = {"query": query, "limit": limit, "page": 1}
        if year:
            params["years"] = str(year)
        data = self._request("GET", "/search/show", params=params)
        return [
            item["show"]
            for item in data or []
            if item.get("type") == "show" and isinstance(item.get("show"), dict)
        ]

    def get_episode(
        self, show_id: int, season: int, number: int
    ) -> dict | None:
        data = self._request(
            "GET",
            f"/shows/{show_id}/seasons/{season}/episodes/{number}",
            allow_404=True,
        )
        return data if isinstance(data, dict) else None

    def scrobble(
        self, action: str, kind: str, trakt_id: int, progress: float
    ) -> dict:
        item = "movie" if kind == "movie" else "episode"
        payload = {
            "progress": round(max(0.0, min(100.0, progress)), 2),
            item: {"ids": {"trakt": int(trakt_id)}},
        }
        data = self._request(
            "POST",
            f"/scrobble/{action}",
            authenticated=True,
            json_body=payload,
        )
        if isinstance(data, dict):
            data.setdefault("action", action)
            return data
        return {"action": action}


# ---------------------------------------------------------------------------
# filename parsing and matching


def _first(value: Any) -> Any:
    if isinstance(value, (list, tuple)):
        return value[0] if value else None
    return value


def _as_int(value: Any) -> int | None:
    value = _first(value)
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _guess(value: str) -> dict:
    try:
        result = guessit(value)
        return dict(result) if result else {}
    except Exception:
        return {}


def parse_media(value: str, title_hint: str | None = None) -> dict:
    guess = _guess(value)

    title = _first(guess.get("title"))
    year = _as_int(guess.get("year"))
    season = _as_int(guess.get("season"))
    episode = _as_int(guess.get("episode"))
    episode_title = _first(guess.get("episode_title"))

    # The path may be a URL or something guessit cannot identify well. Use
    # mpv's media title as a fallback for the title and episode details.
    if title_hint:
        hint = _guess(title_hint)
        if episode is None and _as_int(hint.get("episode")) is not None:
            episode = _as_int(hint.get("episode"))
            season = _as_int(hint.get("season"))
            episode_title = _first(hint.get("episode_title")) or episode_title
            year = year or _as_int(hint.get("year"))
            title = _first(hint.get("title")) or title
        if not title:
            title = _first(hint.get("title"))

    if not title:
        title = Path(value).stem

    if episode is not None and season is None:
        season = 1

    return {
        "kind": "episode" if episode is not None else "movie",
        "title": str(title).strip(),
        "year": year,
        "season": season,
        "episode": episode,
        "episode_title": episode_title,
    }


def normalize_title(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = "".join(char for char in value if not unicodedata.combining(char))
    value = value.lower().replace("&", " and ")
    value = re.sub(r"^(?:the|a|an)\s+", "", value)
    return re.sub(r"[^a-z0-9]+", " ", value).strip()


def title_score(left: str, right: str) -> float:
    left_norm = normalize_title(left)
    right_norm = normalize_title(right)
    if not left_norm or not right_norm:
        return 0.0
    if left_norm == right_norm:
        return 1.0
    return SequenceMatcher(None, left_norm, right_norm).ratio()


def _year_matches(parsed_year: int | None, candidate_year: Any) -> bool:
    if not parsed_year:
        return True
    candidate = _as_int(candidate_year)
    return candidate is None or candidate == parsed_year


def _dedupe(items: list[dict]) -> list[dict]:
    seen: set[int] = set()
    unique: list[dict] = []
    for item in items:
        trakt_id = _as_int((item.get("ids") or {}).get("trakt"))
        if trakt_id is None or trakt_id in seen:
            continue
        seen.add(trakt_id)
        unique.append(item)
    return unique


def _media_from_movie(movie: dict) -> dict | None:
    ids = movie.get("ids") or {}
    trakt_id = _as_int(ids.get("trakt"))
    title = movie.get("title") or ""
    if not trakt_id or not title:
        return None

    year = _as_int(movie.get("year"))
    slug = ids.get("slug") or ""
    return {
        "kind": "movie",
        "trakt_id": trakt_id,
        "title": title,
        "year": year,
        "display_name": f"{title} ({year})" if year else title,
        "url": f"{SITE_BASE}/movies/{slug}" if slug else SITE_BASE,
    }


def _media_from_episode(show: dict, episode: dict) -> dict | None:
    show_ids = show.get("ids") or {}
    episode_ids = episode.get("ids") or {}
    trakt_id = _as_int(episode_ids.get("trakt"))
    show_title = show.get("title") or ""
    if not trakt_id or not show_title:
        return None

    season = _as_int(episode.get("season")) or 0
    number = _as_int(episode.get("number")) or 0
    episode_title = episode.get("title") or ""
    show_slug = show_ids.get("slug") or ""

    display_name = f"{show_title} S{season:02d}E{number:02d}"
    if episode_title:
        display_name += f" · {episode_title}"

    url = SITE_BASE
    if show_slug:
        url = (
            f"{SITE_BASE}/shows/{show_slug}"
            f"/seasons/{season}/episodes/{number}"
        )

    return {
        "kind": "episode",
        "trakt_id": trakt_id,
        "show_id": _as_int(show_ids.get("trakt")),
        "show_title": show_title,
        "season": season,
        "episode": number,
        "episode_title": episode_title,
        "year": _as_int(show.get("year")),
        "display_name": display_name,
        "url": url,
    }


def find_movie(client: TraktClient, parsed: dict) -> dict | None:
    title = parsed["title"]
    year = parsed["year"]

    for search_year in ([year, None] if year else [None]):
        results = _dedupe(client.search_movies(title, search_year))
        matches = [
            movie
            for movie in results
            if title_score(title, movie.get("title", "")) >= 0.92
            and _year_matches(year, movie.get("year"))
        ]
        if len(matches) == 1:
            return _media_from_movie(matches[0])
        if year:
            exact = [
                movie
                for movie in matches
                if _as_int(movie.get("year")) == year
            ]
            if len(exact) == 1:
                return _media_from_movie(exact[0])
        if matches:
            return None

    return None


def find_episode(client: TraktClient, parsed: dict) -> dict | None:
    title = parsed["title"]
    year = parsed["year"]
    season = parsed["season"] or 1
    number = parsed["episode"] or 0

    for search_year in ([year, None] if year else [None]):
        results = _dedupe(client.search_shows(title, search_year))
        matches = [
            show
            for show in results
            if title_score(title, show.get("title", "")) >= 0.92
            and _year_matches(year, show.get("year"))
        ]

        if len(matches) > 1:
            if year:
                exact = [
                    show
                    for show in matches
                    if _as_int(show.get("year")) == year
                ]
                if len(exact) == 1:
                    matches = exact
                else:
                    return None
            else:
                return None

        for show in matches:
            show_id = _as_int((show.get("ids") or {}).get("trakt"))
            if not show_id:
                continue

            episode = client.get_episode(show_id, season, number)
            if episode:
                return _media_from_episode(show, episode)

    return None


def resolve_media(client: TraktClient, parsed: dict) -> dict | None:
    if parsed["kind"] == "episode":
        return find_episode(client, parsed)
    return find_movie(client, parsed)


def search_media(
    client: TraktClient, parsed: dict, limit: int
) -> list[dict]:
    title = parsed["title"]
    year = parsed["year"]

    if parsed["kind"] == "movie":
        movies = _dedupe(client.search_movies(title, year, limit=limit))
        if not movies and year:
            movies = _dedupe(client.search_movies(title, None, limit=limit))
        return [
            media
            for media in (_media_from_movie(movie) for movie in movies)
            if media
        ]

    season = parsed["season"] or 1
    number = parsed["episode"] or 0
    shows = _dedupe(client.search_shows(title, year, limit=min(limit, 10)))
    if not shows and year:
        shows = _dedupe(client.search_shows(title, None, limit=min(limit, 10)))

    results: list[dict] = []
    seen: set[int] = set()
    for show in shows:
        show_id = _as_int((show.get("ids") or {}).get("trakt"))
        if not show_id:
            continue
        episode = client.get_episode(show_id, season, number)
        if not episode:
            continue
        media = _media_from_episode(show, episode)
        if not media or media["trakt_id"] in seen:
            continue
        seen.add(media["trakt_id"])
        results.append(media)
        if len(results) >= limit:
            break

    return results


# ---------------------------------------------------------------------------
# CLI


def emit_error(message: str) -> int:
    print(json.dumps({"ok": False, "error": message}))
    return 1


def emit_json(data: dict) -> int:
    print(json.dumps(data))
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Trakt scrobbling backend for the mpv script."
    )
    parser.add_argument(
        "--authorize",
        action="store_true",
        help="Set up Trakt API credentials and authorize this device",
    )
    parser.add_argument("--match", metavar="PATH", help="Resolve a filename")
    parser.add_argument("--search", metavar="QUERY", help="Search Trakt")
    parser.add_argument(
        "--title",
        default="",
        help="mpv media title, used when the filename is unclear",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=10,
        help="Number of search results (default: 10)",
    )
    parser.add_argument(
        "--scrobble",
        choices=("start", "pause", "stop"),
        help="Scrobble action",
    )
    parser.add_argument("--kind", choices=("movie", "episode"))
    parser.add_argument("--trakt-id", type=int)
    parser.add_argument("--progress", type=float)

    args = parser.parse_args()

    modes = sum(
        bool(value)
        for value in (args.authorize, args.match, args.search, args.scrobble)
    )
    if modes == 0:
        parser.error("one of --authorize, --match, --search or --scrobble is required")
    if modes > 1:
        parser.error("--authorize, --match, --search and --scrobble are mutually exclusive")

    if args.scrobble:
        if not args.kind or args.trakt_id is None or args.progress is None:
            parser.error("--scrobble requires --kind, --trakt-id and --progress")
        if not 0 <= args.progress <= 100:
            parser.error("--progress must be between 0 and 100")

    if args.search is not None and not (1 <= args.limit <= 50):
        parser.error("--limit must be between 1 and 50")

    return args


def main() -> int:
    args = parse_args()

    if args.authorize:
        try:
            return authorize()
        except (TraktError, requests.RequestException) as exc:
            print(f"Error: {exc}", file=sys.stderr)
            return 1

    try:
        if args.scrobble:
            client = TraktClient()
            result = client.scrobble(
                args.scrobble, args.kind, args.trakt_id, args.progress
            )
            return emit_json(
                {
                    "ok": True,
                    "action": result.get("action", args.scrobble),
                    "progress": result.get("progress", args.progress),
                }
            )

        parsed = parse_media(args.match or args.search, args.title or None)
        client = TraktClient()

        if args.match:
            media = resolve_media(client, parsed)
            if media is None:
                label = parsed["title"]
                if parsed["year"]:
                    label += f" ({parsed['year']})"
                if parsed["kind"] == "episode":
                    label += (
                        f" S{parsed['season'] or 1:02d}"
                        f"E{parsed['episode'] or 0:02d}"
                    )
                raise TraktError(f'No confident Trakt match for "{label}"')
            return emit_json({"ok": True, "parsed": parsed, "media": media})

        results = search_media(client, parsed, args.limit)
        return emit_json({"ok": True, "parsed": parsed, "results": results})

    except TraktError as exc:
        return emit_error(str(exc))
    except requests.RequestException as exc:
        return emit_error(f"Could not reach Trakt: {exc}")


if __name__ == "__main__":
    raise SystemExit(main())
