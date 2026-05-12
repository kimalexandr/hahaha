#!/usr/bin/env python3
"""Загрузка собранных APK/AAB в папку Google Drive через сервисный аккаунт.

Ожидаемые переменные окружения:
  GOOGLE_DRIVE_SERVICE_ACCOUNT — JSON ключ (целиком). Допустимо через base64:
  GOOGLE_DRIVE_SERVICE_ACCOUNT_B64 — base64(JSON), если обычный секрет ломает переносы строк.
  GOOGLE_DRIVE_FOLDER_ID — ID папки из URL (.../folders/THIS_ID).

Опционально:
  GITHUB_RUN_NUMBER, GITHUB_SHA — суффикс имён файлов.

Папку в Drive расшарьте на client_email из JSON с правом «Редактор».
В GCP для проекта ключа включите «Google Drive API».
"""

from __future__ import annotations

import base64
import binascii
import glob
import json
import os
import sys
from pathlib import Path

# drive.file иногда даёт 403 при записи в расшаренную папку; drive — типичный выбор для SA + одна папка.
SCOPES = ["https://www.googleapis.com/auth/drive"]


def _load_service_account_dict() -> dict:
    raw = os.environ.get("GOOGLE_DRIVE_SERVICE_ACCOUNT", "").strip()
    b64 = os.environ.get("GOOGLE_DRIVE_SERVICE_ACCOUNT_B64", "").strip()
    if b64 and not raw:
        try:
            raw = base64.standard_b64decode(b64).decode("utf-8")
        except (binascii.Error, UnicodeDecodeError) as e:
            raise ValueError(f"GOOGLE_DRIVE_SERVICE_ACCOUNT_B64: неверный base64/utf-8: {e}") from e
    raw = raw.lstrip("\ufeff")
    if not raw:
        raise ValueError("пустой GOOGLE_DRIVE_SERVICE_ACCOUNT (и не задан B64)")
    return json.loads(raw)


def main() -> int:
    has_sa = bool(os.environ.get("GOOGLE_DRIVE_SERVICE_ACCOUNT", "").strip()) or bool(
        os.environ.get("GOOGLE_DRIVE_SERVICE_ACCOUNT_B64", "").strip()
    )
    folder_id = os.environ.get("GOOGLE_DRIVE_FOLDER_ID", "").strip()

    print("--- Google Drive upload ---")
    print(f"Секрет ключа (SA): {'задан' if has_sa else 'НЕ задан'}")
    print(f"Секрет папки (GOOGLE_DRIVE_FOLDER_ID): {'задан' if folder_id else 'НЕ задан'}")

    if not has_sa and not folder_id:
        print(
            "Пропуск: не настроены секреты GitHub "
            "(GOOGLE_DRIVE_SERVICE_ACCOUNT и GOOGLE_DRIVE_FOLDER_ID)."
        )
        return 0

    if has_sa ^ bool(folder_id):
        print(
            "ОШИБКА: задан только один из секретов. Нужны ОБА: "
            "GOOGLE_DRIVE_SERVICE_ACCOUNT (или …_B64) и GOOGLE_DRIVE_FOLDER_ID.",
            file=sys.stderr,
        )
        return 1

    try:
        info = _load_service_account_dict()
    except (json.JSONDecodeError, ValueError) as e:
        print(f"ОШИБКА: не удалось разобрать JSON ключа: {e}", file=sys.stderr)
        return 1

    client_email = info.get("client_email", "(нет client_email в JSON)")
    print(f"client_email в ключе: {client_email}")

    apks = sorted(glob.glob("build/app/outputs/flutter-apk/*.apk"))
    aabs = sorted(glob.glob("build/app/outputs/bundle/release/*.aab"))
    files = [p for p in apks + aabs if os.path.isfile(p)]
    print(f"Найдено файлов для загрузки: {len(files)}")
    for p in files:
        print(f"  - {p} ({os.path.getsize(p)} bytes)")
    if not files:
        print("ОШИБКА: нет APK/AAB в build/app/outputs/...", file=sys.stderr)
        return 1

    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
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
        try:
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
        except HttpError as e:
            print(f"ОШИБКА Drive API: {e}", file=sys.stderr)
            print(
                "Проверь: 1) папка расшарена на client_email выше с правом «Редактор»; "
                "2) GOOGLE_DRIVE_FOLDER_ID — именно ID из URL; "
                "3) в GCP включён Google Drive API.",
                file=sys.stderr,
            )
            return 1
        print(f"Загружено: {path} -> {created.get('name')} (id={created.get('id')})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
