#!/usr/bin/env python3
"""Backend for scripts/letterboxd.lua (mpv + uosc).

Only the operations used by the Lua script are supported:

    rate_movie.py --search <query> --json --limit N
    rate_movie.py --log <film-url> --json --dry-run
    rate_movie.py --log <film-url> --json [--rating R]
                  [--rewatch|--no-rewatch] [--like|--no-like]

Cookies are read from ~/.local/share/letterboxd/cookies.txt.
"""

from __future__ import annotations

import argparse
import html
import json
import re
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from urllib.parse import quote, urljoin

import requests

BASE = "https://letterboxd.com"
API_BASE = "https://api.letterboxd.com/api/v0"
DEFAULT_UA = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
)
COOKIE_PATH = Path("~/.local/share/letterboxd/cookies.txt").expanduser()

VIDEO_EXT = re.compile(r"\.(mkv|mp4|avi|mov|m4v|wmv|iso|ts|webm)$", re.IGNORECASE)
YEAR_PAREN_RE = re.compile(r"[\(\[]\s*((?:18|19|20)\d{2})\s*[\)\]]")
YEAR_BOUNDARY_RE = re.compile(r"(?<!\d)((?:18|19|20)\d{2})(?!\d)")
LID_PATTERNS = (
    r"&quot;lid&quot;:&quot;([A-Za-z0-9]+)&quot;",
    r'"lid"\s*:\s*"([A-Za-z0-9]+)"',
    r'data-film-lid=["\']([A-Za-z0-9]+)["\']',
    r"boxd\.it/([A-Za-z0-9]+)",
)

TECHNICAL_TAGS = {
    "1080p",
    "2160p",
    "720p",
    "480p",
    "4k",
    "uhd",
    "hdr",
    "hdr10",
    "dv",
    "bluray",
    "blu-ray",
    "brrip",
    "bdrip",
    "webrip",
    "webdl",
    "web",
    "hdtv",
    "dvdrip",
    "remux",
    "x264",
    "x265",
    "h264",
    "h265",
    "hevc",
    "av1",
    "xvid",
    "ita",
    "eng",
    "chi",
    "jpn",
    "ger",
    "fre",
    "spa",
    "rus",
    "sub",
    "subs",
    "ac3",
    "aac",
    "dts",
    "dtshd",
    "truehd",
    "atmos",
    "multi",
    "dual",
    "5.1",
    "7.1",
    "2.0",
    "proper",
    "repack",
    "extended",
    "directorcut",
    "licensed",
    "licdom",
    "mkv",
    "mp4",
    "avi",
    "mov",
}


class LetterboxdError(RuntimeError):
    pass


@dataclass
class Film:
    lid: str
    name: str
    year: int | None
    slug: str
    url: str
    display_name: str | None = None
    rating: float | None = None


def film_to_dict(film: Film) -> dict:
    display_name = film.display_name
    if not display_name:
        display_name = f"{film.name} ({film.year})" if film.year else film.name
    return {
        "lid": film.lid,
        "title": film.name,
        "year": film.year,
        "display_name": display_name,
        "slug": film.slug,
        "url": film.url,
        "rating": film.rating,
    }


def find_release_year(name: str) -> re.Match | None:
    """Find the release year without mistaking title numbers for a year."""
    parenthesized = list(YEAR_PAREN_RE.finditer(name))
    if parenthesized:
        return parenthesized[-1]

    candidates = []
    for match in YEAR_BOUNDARY_RE.finditer(name):
        rest = name[match.end() :].lstrip(" ._-[]()")
        next_token = re.split(r"[ ._\-\[\]()]", rest, maxsplit=1)[0].lower()
        if not rest or next_token in TECHNICAL_TAGS:
            candidates.append(match)
    return candidates[-1] if candidates else None


def guess_movie_name(filename: str) -> tuple[str, str | None]:
    """Extract a title and year from a release filename or plain title."""
    name = Path(filename).name
    name = VIDEO_EXT.sub("", name)

    match = find_release_year(name)
    year = match.group(1) if match else None
    if match:
        name = name[: match.start()]

    name = name.replace(".", " ").replace("_", " ").replace("-", " ")
    words = [
        word
        for word in re.sub(r"\s+", " ", name).strip().split()
        if word.lower().strip(".,[]()") not in TECHNICAL_TAGS
    ]
    return " ".join(words).strip(" ._-[]()"), year


def load_cookies(path: Path) -> dict[str, str]:
    """Load a browser cookie export in 'name=value' or Netscape format."""
    cookies: dict[str, str] = {}

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or (line.startswith("#") and "\t" not in line):
            continue

        if "\t" in line:
            fields = line.split("\t")
            if len(fields) >= 7:
                cookies[fields[5]] = fields[6]
            continue

        if "=" not in line:
            continue
        name, value = line.split("=", 1)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        cookies[name.strip()] = value

    if not cookies:
        raise LetterboxdError(f"No cookies found in {path}")
    return cookies


def find_csrf_token(cookies: dict[str, str]) -> str:
    token = cookies.get("com.xk72.webparts.csrf")
    if token:
        return token
    for name, value in cookies.items():
        if name.lower().endswith("csrf"):
            return value
    raise LetterboxdError("CSRF cookie not found; export a fresh cookies.txt")


def find_username(cookies: dict[str, str]) -> str | None:
    username = cookies.get("letterboxd.signed.in.as", "").strip().strip('"')
    return username or None


def make_session(cookies: dict[str, str], user_agent: str) -> requests.Session:
    session = requests.Session()
    session.cookies.update(cookies)
    session.headers.update(
        {
            "User-Agent": user_agent,
            "Accept-Language": "en-US,en;q=0.9",
        }
    )
    return session


def slug_from_url(url: str) -> str:
    match = re.search(r"/film/([^/?#]+)", url or "")
    return match.group(1).lower() if match else ""


def fetch_film(session: requests.Session, slug: str) -> tuple[str, str, str | None] | None:
    url = f"{BASE}/film/{quote(slug, safe='-')}/"
    response = session.get(url, timeout=30, allow_redirects=True)

    if response.status_code == 404:
        return None
    if response.status_code == 403 and (
        "just a moment" in response.text.lower() or "cf-mitigated" in response.headers
    ):
        raise LetterboxdError(
            "Letterboxd returned a Cloudflare challenge. Export fresh cookies "
            "from your browser and try again."
        )
    if response.status_code != 200:
        raise LetterboxdError(f"Could not load {url} (HTTP {response.status_code})")

    final = re.search(r"/film/([^/?#]+)", response.url)
    final_slug = final.group(1).lower() if final else slug
    lid = response.headers.get("x-letterboxd-identifier")
    return response.text, final_slug, lid


def extract_lid(page: str) -> str | None:
    for pattern in LID_PATTERNS:
        match = re.search(pattern, page)
        if match:
            return match.group(1)
    return None


def extract_title(page: str, fallback: str) -> str:
    match = re.search(r'<meta\s+property="og:title"\s+content="([^"]+)"', page)
    return html.unescape(match.group(1)) if match else fallback


def title_year(title: str) -> int | None:
    years = YEAR_BOUNDARY_RE.findall(title)
    return int(years[-1]) if years else None


def resolve_film(session: requests.Session, slug: str) -> Film:
    page = fetch_film(session, slug)
    if page is None:
        raise LetterboxdError(f"No film found for {slug}")

    content, final_slug, header_lid = page
    lid = header_lid or extract_lid(content)
    if not lid:
        raise LetterboxdError(f"Could not find the Letterboxd ID for {slug}")

    title = extract_title(content, final_slug)
    return Film(
        lid=lid,
        name=title,
        year=title_year(title),
        slug=final_slug,
        url=f"{BASE}/film/{final_slug}/",
        display_name=title,
    )


def _search_api(query: str, per_page: int) -> list[Film]:
    """GET https://api.letterboxd.com/api/v0/search."""
    response = requests.get(
        f"{API_BASE}/search",
        params={
            "input": query,
            "perPage": per_page,
            "searchMethod": "FullText",
            "include": "FilmSearchItem",
            "adult": "false",
        },
        headers={"Accept": "application/json", "User-Agent": DEFAULT_UA},
        timeout=30,
    )

    if response.status_code != 200:
        raise LetterboxdError(
            f"Search failed (HTTP {response.status_code}): {response.text[:200]}"
        )
    try:
        payload = response.json()
    except ValueError as exc:
        raise LetterboxdError("Search returned invalid JSON") from exc

    films: list[Film] = []
    for item in payload.get("items", []):
        film = item.get("film") or {}
        lid = film.get("id")
        if not lid:
            continue
        link = film.get("link") or ""
        slug = slug_from_url(link)
        films.append(
            Film(
                lid=lid,
                name=film.get("name", ""),
                year=film.get("releaseYear"),
                slug=slug,
                url=link or f"{BASE}/film/{slug}/",
                display_name=film.get("fullDisplayName"),
                rating=film.get("rating"),
            )
        )
    return films


def _search_site(session: requests.Session, query: str, per_page: int) -> list[Film]:
    """Fallback search using the website's cookie-authenticated autocomplete."""
    response = session.get(
        f"{BASE}/s/autocompletefilm",
        params={"q": query},
        headers={
            "Accept": "application/json, text/javascript, */*; q=0.01",
            "X-Requested-With": "XMLHttpRequest",
            "Referer": f"{BASE}/",
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin",
        },
        timeout=30,
    )
    if response.status_code != 200:
        raise LetterboxdError(f"Site search failed (HTTP {response.status_code})")
    try:
        payload = response.json()
    except ValueError as exc:
        raise LetterboxdError("Site search returned invalid JSON") from exc

    films: list[Film] = []
    for item in payload.get("data", [])[:per_page]:
        lid = item.get("lid")
        if not lid:
            continue
        slug = item.get("slug") or slug_from_url(item.get("url", ""))
        year = item.get("releaseYear")
        name = item.get("name", "")
        films.append(
            Film(
                lid=lid,
                name=name,
                year=year,
                slug=slug,
                url=urljoin(BASE, item.get("url") or f"/film/{slug}/"),
                display_name=f"{name} ({year})" if year else name,
            )
        )
    return films


def search_films(
    query: str,
    per_page: int = 10,
    session: requests.Session | None = None,
) -> list[Film]:
    """Search films via the API, falling back to the website autocomplete."""
    query = query.strip()
    if not query:
        raise LetterboxdError("Search query is empty")

    try:
        return _search_api(query, per_page)
    except (LetterboxdError, requests.RequestException) as api_error:
        if session is None:
            raise
        try:
            return _search_site(session, query, per_page)
        except (LetterboxdError, requests.RequestException, ValueError):
            raise api_error


def fetch_viewing(session: requests.Session, username: str | None, slug: str) -> dict:
    """Return the member's existing viewing data for a film, if any."""
    if not username:
        return {}
    url = f"{BASE}/{quote(username, safe='')}/film/{quote(slug, safe='-')}/json/"
    try:
        response = session.get(
            url,
            headers={
                "Accept": "application/json",
                "X-Requested-With": "XMLHttpRequest",
                "Referer": f"{BASE}/film/{slug}/",
                "Sec-Fetch-Dest": "empty",
                "Sec-Fetch-Mode": "cors",
                "Sec-Fetch-Site": "same-origin",
            },
            timeout=30,
        )
    except requests.RequestException:
        return {}
    if response.status_code != 200:
        return {}
    try:
        payload = response.json()
    except ValueError:
        return {}
    return payload if isinstance(payload, dict) else {}


def create_log_entry(
    session: requests.Session,
    csrf: str,
    film: Film,
    *,
    rating: float | None,
    diary_date: str,
    rewatch: bool,
    liked: bool,
) -> dict:
    """Create a diary entry via the website's internal log-entry endpoint."""
    payload: dict = {
        "productionId": film.lid,
        "tags": [],
        "like": liked,
        "diaryDetails": {"diaryDate": diary_date, "rewatch": rewatch},
    }
    if rating is not None:
        payload["rating"] = rating

    response = session.post(
        f"{BASE}/api/v0/production-log-entries",
        json=payload,
        headers={
            "Accept": "application/json",
            "Content-Type": "application/json; charset=UTF-8",
            "Origin": BASE,
            "Referer": film.url,
            "X-CSRF-TOKEN": csrf,
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin",
        },
        timeout=30,
    )

    try:
        data = response.json()
    except ValueError:
        data = {}

    if response.status_code == 200:
        entry = data.get("logEntry")
        if not isinstance(entry, dict):
            raise LetterboxdError("Log entry was saved but the response was unexpected")
        return entry
    if response.status_code in (401, 403):
        message = data.get("message") if isinstance(data, dict) else None
        raise LetterboxdError(
            "Letterboxd rejected the log entry"
            + (f": {message}" if message else "")
            + ". Your cookies or CSRF token are probably stale."
        )
    if response.status_code == 404:
        message = data.get("message") if isinstance(data, dict) else None
        raise LetterboxdError(
            "Film not found for logging" + (f": {message}" if message else "")
        )
    if response.status_code == 400:
        message = data.get("message") if isinstance(data, dict) else None
        raise LetterboxdError(
            "Letterboxd rejected the log entry"
            + (f": {message}" if message else f" (HTTP {response.status_code})")
        )
    raise LetterboxdError(
        f"Log request failed (HTTP {response.status_code}): {data or response.text[:300]}"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Letterboxd search/log backend for the mpv script."
    )
    parser.add_argument(
        "input",
        nargs="?",
        help="Film URL (for --log) or query (for --search)",
    )
    parser.add_argument(
        "--search",
        nargs="?",
        const=True,
        metavar="QUERY",
        help="Search films and print the results",
    )
    parser.add_argument(
        "--log",
        action="store_true",
        help="Log a diary entry for the film",
    )
    parser.add_argument(
        "--rating",
        "-r",
        type=float,
        help="Rating from 0.5 to 5.0 in half-star steps",
    )
    parser.add_argument(
        "--rewatch",
        dest="rewatch",
        action="store_true",
        default=None,
        help="Mark the viewing as a rewatch (default: auto-detect)",
    )
    parser.add_argument(
        "--no-rewatch",
        dest="rewatch",
        action="store_false",
        help="Mark the viewing as a first watch",
    )
    parser.add_argument(
        "--like",
        dest="liked",
        action="store_true",
        default=None,
        help="Like the film (default: keep the current like state)",
    )
    parser.add_argument(
        "--no-like",
        dest="liked",
        action="store_false",
        help="Remove the like",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=10,
        help="Number of search results (default: 10, max: 100)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Accepted for compatibility; output is always JSON",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Resolve the film but do not submit anything",
    )

    args = parser.parse_args()

    if args.search is not None:
        if (
            args.rating is not None
            or args.log
            or args.dry_run
            or args.rewatch is not None
            or args.liked is not None
        ):
            parser.error("--search cannot be combined with log options")
        if not (1 <= args.limit <= 100):
            parser.error("--limit must be between 1 and 100")
        if not isinstance(args.search, str) and not args.input:
            parser.error("--search requires a query")
    else:
        if not args.input:
            parser.error("the following arguments are required: input")
        if not args.log:
            parser.error("--log is required (or use --search)")
        if args.rating is not None and (
            args.rating < 0.5
            or args.rating > 5.0
            or args.rating * 2 != round(args.rating * 2)
        ):
            parser.error("--rating must be between 0.5 and 5.0 in half-star steps")
    return args


def emit_error(message: str) -> int:
    print(json.dumps({"ok": False, "error": message}))
    return 1


def run_search(args: argparse.Namespace) -> int:
    query = args.search if isinstance(args.search, str) else args.input

    session = None
    try:
        session = make_session(load_cookies(COOKIE_PATH), DEFAULT_UA)
    except (LetterboxdError, OSError):
        pass

    try:
        title, year = guess_movie_name(query)
        if year:
            query = f"{title}-{year}"
        films = search_films(query, per_page=args.limit, session=session)
    except (LetterboxdError, requests.RequestException) as exc:
        return emit_error(str(exc))

    print(
        json.dumps(
            {
                "ok": True,
                "query": query or "",
                "results": [film_to_dict(film) for film in films],
            }
        )
    )
    return 0


def run_log(args: argparse.Namespace) -> int:
    try:
        cookies = load_cookies(COOKIE_PATH)
        username = find_username(cookies)
        session = make_session(cookies, DEFAULT_UA)
        slug = slug_from_url(args.input)
        if not slug:
            raise LetterboxdError("Expected a Letterboxd film URL")
        film = resolve_film(session, slug)
    except (LetterboxdError, OSError, requests.RequestException) as exc:
        return emit_error(str(exc))

    previous = fetch_viewing(session, username, film.slug)
    rewatch = (
        args.rewatch if args.rewatch is not None else bool(previous.get("viewingDate"))
    )
    liked = args.liked if args.liked is not None else bool(previous.get("liked"))
    rating = args.rating
    diary_date = date.today().isoformat()

    if args.dry_run:
        print(
            json.dumps(
                {
                    "ok": True,
                    "dry_run": True,
                    "film": film_to_dict(film),
                    "date": diary_date,
                    "rating": rating,
                    "rewatch": rewatch,
                    "liked": liked,
                }
            )
        )
        return 0

    try:
        entry = create_log_entry(
            session,
            find_csrf_token(cookies),
            film,
            rating=rating,
            diary_date=diary_date,
            rewatch=rewatch,
            liked=liked,
        )
    except (LetterboxdError, requests.RequestException) as exc:
        return emit_error(str(exc))

    print(
        json.dumps(
            {
                "ok": True,
                "dry_run": False,
                "film": film_to_dict(film),
                "entry": {
                    "id": entry.get("id"),
                    "name": entry.get("name"),
                },
                "date": diary_date,
                "rating": rating,
                "rewatch": rewatch,
                "liked": liked,
            }
        )
    )
    return 0


def main() -> int:
    args = parse_args()
    if args.search is not None:
        return run_search(args)
    return run_log(args)


if __name__ == "__main__":
    raise SystemExit(main())
