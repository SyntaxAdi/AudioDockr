from __future__ import annotations

from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from yt_dlp import YoutubeDL
from yt_dlp.utils import DownloadError, ExtractorError


app = FastAPI(title="AudioDockr yt-dlp backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class SearchRequest(BaseModel):
    query: str


class ExtractRequest(BaseModel):
    video_id: str | None = None
    video_url: str | None = None


class ApiError(HTTPException):
    def __init__(self, status_code: int, code: str, message: str) -> None:
        super().__init__(status_code=status_code, detail={"code": code, "message": message})


def classify_error(error: Exception, fallback_code: str) -> tuple[str, str]:
    message = str(error).lower()

    if "429" in message or "too many requests" in message:
        return "rate_limited", "The backend is being rate limited by YouTube right now."
    if "sign in to confirm" in message or "captcha" in message or "bot" in message:
        return "integrity_check_required", "The backend needs extra YouTube verification right now."
    if isinstance(error, DownloadError):
        return "temporary_unavailable", "The backend could not reach YouTube right now."
    if isinstance(error, ExtractorError):
        return "unsupported_response", "yt-dlp could not parse YouTube's latest response format."
    return fallback_code, "YouTube request failed."


def search_result_from_entry(entry: dict[str, Any]) -> dict[str, Any] | None:
    video_id = str(entry.get("id") or "").strip()
    url = str(entry.get("webpage_url") or entry.get("url") or "").strip()
    if not video_id or not url:
        return None

    uploader = str(entry.get("uploader") or entry.get("channel") or "Unknown uploader")
    thumbnails = entry.get("thumbnails") or []

    return {
        "id": video_id,
        "url": url,
        "title": str(entry.get("title") or "Unknown title"),
        "uploader": uploader,
        "duration": int(entry.get("duration") or 0),
        "thumbnails": [
            {"url": str(item.get("url"))}
            for item in thumbnails
            if isinstance(item, dict) and item.get("url")
        ],
    }


def choose_audio_url(info: dict[str, Any]) -> str:
    formats = info.get("formats") or []
    audio_candidates: list[tuple[int, str]] = []

    for fmt in formats:
        if not isinstance(fmt, dict):
            continue
        vcodec = fmt.get("vcodec")
        acodec = fmt.get("acodec")
        url = str(fmt.get("url") or "").strip()
        abr = int(fmt.get("abr") or 0)
        if not url:
            continue
        if acodec and acodec != "none" and (vcodec in (None, "none")):
            audio_candidates.append((abr, url))

    if audio_candidates:
        audio_candidates.sort(key=lambda item: item[0], reverse=True)
        return audio_candidates[0][1]

    direct_url = str(info.get("url") or "").strip()
    if direct_url:
        return direct_url

    raise ApiError(502, "extract_failed", "Unable to prepare audio playback for this track.")


@app.exception_handler(ApiError)
async def api_error_handler(_, exc: ApiError) -> Any:
    return fastapi_error_payload(exc)


def fastapi_error_payload(exc: ApiError):
    return JSONResponse(
        status_code=exc.status_code,
        content=exc.detail,
    )


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/search")
def search(request: SearchRequest) -> dict[str, Any]:
    query = request.query.strip()
    if not query:
        return {"items": []}

    options = {
        "quiet": True,
        "skip_download": True,
        "extract_flat": True,
        "playlistend": 15,
    }

    try:
        with YoutubeDL(options) as ydl:
            info = ydl.extract_info(f"ytsearch15:{query}", download=False)
    except Exception as error:
        code, message = classify_error(error, "temporary_unavailable")
        raise ApiError(502, code, message) from error

    entries = info.get("entries") or []
    items = [item for entry in entries if (item := search_result_from_entry(entry))]
    return {"items": items}


@app.post("/extract")
def extract(request: ExtractRequest) -> dict[str, str]:
    target = (request.video_url or request.video_id or "").strip()
    if not target:
        raise ApiError(400, "invalid_argument", "Video URL is required.")

    if not target.startswith("http://") and not target.startswith("https://"):
        target = f"https://www.youtube.com/watch?v={target}"

    options = {
        "quiet": True,
        "skip_download": True,
        "noplaylist": True,
        "extract_flat": False,
        "format": "bestaudio/best",
    }

    try:
        with YoutubeDL(options) as ydl:
            info = ydl.extract_info(target, download=False)
        return {"audio_url": choose_audio_url(info)}
    except ApiError:
        raise
    except Exception as error:
        code, message = classify_error(error, "extract_failed")
        raise ApiError(502, code, message) from error
