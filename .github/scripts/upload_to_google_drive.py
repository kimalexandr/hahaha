#!/usr/bin/env python3
"""Загрузка собранных APK/AAB в папку Google Drive через сервисный аккаунт.

Ожидаемые переменные окружения:
  GOOGLE_DRIVE_SERVICE_ACCOUNT — JSON ключ сервисного аккаунта (весь файл одной строкой/секретом).
  GOOGLE_DRIVE_FOLDER_ID — ID папки из URL (.../folders/THIS_ID).

Опционально:
  GITHUB_RUN_NUMBER, GITHUB_SHA — для уникальных имён файлов в Drive.

Папку в Drive нужно расшарить на e-mail сервисного аккаунта с правом «Редактор».
"""

from __future__ import annotations

import json
import os
import sys
import glob
from pathlib import Path

SCOPES = ["https://www.googleapis.com/auth/drive.file"]


def main() -> int:
    raw_json = os.environ.get("GOOGLE_DRIVE_SERVICE_ACCOUNT", "").strip()
    folder_id = os.environ.get("GOOGLE_DRIVE_FOLDER_ID", "").strip()
    if not raw_json or not folder_id:
        print(
            "Google Drive: пропуск — не заданы GOOGLE_DRIVE_SERVICE_ACCOUNT "
            "или GOOGLE_DRIVE_FOLDER_ID (секреты GitHub)."
        )
        return 0

    try:
        info = json.loads(raw_json)
    except json.JSONDecodeError as e:
        print(f"Google Drive: неверный JSON сервисного аккаунта: {e}", file=sys.stderr)
        return 1

    apks = sorted(glob.glob("build/app/outputs/flutter-apk/*.apk"))
    aabs = sorted(glob.glob("build/app/outputs/bundle/release/*.aab"))
    files = [p for p in apks + aabs if os.path.isfile(p)]
    if not files:
        print("Google Drive: не найдены APK/AAB под build/app/outputs/...", file=sys.stderr)
        return 1

    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload

    creds = service_account.Credentials.from_service_account_info(info, scopes=SCOPES)
    service = build("drive", "v3", credentials=creds, cache_discovery=False)

    run = os.environ.get("GITHUB_RUN_NUMBER", "")
    short_sha = (os.environ.get("GITHUB_SHA", "") or "")[:7]
    suffix = f"-run{run}-{short_sha}" if run or short_sha else ""

    for path in files:
        base = Path(path).stem
        ext = Path(path).suffix
        name = f"{base}{suffix}{ext}"
        body = {"name": name, "parents": [folder_id]}
        media = MediaFileUpload(path, resumable=True)
        created = (
            service.files()
            .create(
                body=body,
                media_body=media,
                supportsAllDrives=True,
                fields="id,name",
            )
            .execute()
        )
        print(f"Google Drive: загружено {path} -> {created.get('name')} (id={created.get('id')})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
