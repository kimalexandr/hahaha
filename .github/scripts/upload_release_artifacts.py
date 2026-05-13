#!/usr/bin/env python3
"""Загрузка release APK/AAB в Google Cloud Storage и/или Google Drive.

Секреты GitHub Actions (имена фиксированы в workflow):
  GOOGLE_DRIVE_SERVICE_ACCOUNT — JSON сервисного аккаунта (тот же ключ, что для Firebase).
  GOOGLE_DRIVE_SERVICE_ACCOUNT_B64 — опционально, base64(JSON).
  GOOGLE_DRIVE_FOLDER_ID — опционально, папка Drive (см. ниже про лимит SA).
  GCS_BUCKET_NAME — опционально, имя bucket GCS без gs:// (рекомендуется для личного Google).

Drive: у сервисного аккаунта нет квоты «Мой диск». Загрузка в обычную папку часто даёт 403
storageQuotaExceeded. Рабочие варианты: (1) папка внутри **Shared drive** (Google Workspace),
  участник SA с правом контент-менеджер; (2) только **GCS** в том же GCP-проекте.

GCS: включи Cloud Storage API, создай bucket, выдай SA роль Storage Object Creator (или Admin)
  на bucket. Секрет GCS_BUCKET_NAME = имя bucket.
"""

from __future__ import annotations

import base64
import binascii
import glob
import json
import os
import sys
from pathlib import Path

DRIVE_SCOPES = ["https://www.googleapis.com/auth/drive"]


def _load_service_account_dict() -> dict:
    raw = os.environ.get("GOOGLE_DRIVE_SERVICE_ACCOUNT", "").strip()
    b64 = os.environ.get("GOOGLE_DRIVE_SERVICE_ACCOUNT_B64", "").strip()
    if b64 and not raw:
        try:
            raw = base64.standard_b64decode(b64).decode("utf-8")
        except (binascii.Error, UnicodeDecodeError) as e:
            raise ValueError(f"GOOGLE_DRIVE_SERVICE_ACCOUNT_B64: {e}") from e
    raw = raw.lstrip("\ufeff")
    if not raw:
        raise ValueError("пустой JSON ключа (GOOGLE_DRIVE_SERVICE_ACCOUNT)")
    return json.loads(raw)


def _collect_files() -> list[str]:
    apks = sorted(glob.glob("build/app/outputs/flutter-apk/*.apk"))
    aabs = sorted(glob.glob("build/app/outputs/bundle/release/*.aab"))
    return [p for p in apks + aabs if os.path.isfile(p)]


def _upload_gcs(paths: list[str], info: dict) -> bool:
    bucket_name = os.environ.get("GCS_BUCKET_NAME", "").strip()
    if not bucket_name:
        return True  # не настроено — не ошибка

    from google.cloud import storage
    from google.oauth2 import service_account

    creds = service_account.Credentials.from_service_account_info(info)
    client = storage.Client(credentials=creds, project=info.get("project_id"))
    bucket = client.bucket(bucket_name)
    run = os.environ.get("GITHUB_RUN_NUMBER", "0")
    short = (os.environ.get("GITHUB_SHA", "") or "")[:7]

    for path in paths:
        dest = f"ci/run-{run}-{short}/{Path(path).name}"
        blob = bucket.blob(dest)
        ctype = (
            "application/vnd.android.package-archive"
            if path.endswith(".apk")
            else "application/octet-stream"
        )
        blob.upload_from_filename(path, content_type=ctype)
        print(f"GCS: gs://{bucket_name}/{dest}")
    return True


def _upload_drive(paths: list[str], info: dict, folder_id: str) -> tuple[bool, bool]:
    from google.oauth2 import service_account
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    from googleapiclient.http import MediaFileUpload

    creds = service_account.Credentials.from_service_account_info(info, scopes=DRIVE_SCOPES)
    service = build("drive", "v3", credentials=creds, cache_discovery=False)
    run = os.environ.get("GITHUB_RUN_NUMBER", "")
    short_sha = (os.environ.get("GITHUB_SHA", "") or "")[:7]
    suffix = f"-run{run}-{short_sha}" if run or short_sha else ""

    for path in paths:
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
            print(f"Drive: {path} -> {created.get('name')} (id={created.get('id')})")
        except HttpError as e:
            print(f"Drive API: {e}", file=sys.stderr)
            body = str(e)
            if "storageQuotaExceeded" in body:
                print(
                    "\nУ сервисного аккаунта нет квоты Google Drive для «Мой диск».\n"
                    "Варианты:\n"
                    "  • Загрузка в **Google Cloud Storage**: задай секрет GCS_BUCKET_NAME "
                    "(bucket в проекте GCP, права SA на запись в bucket).\n"
                    "  • Или папка в **Shared drive** (корпоративный общий диск), SA добавлен "
                    "участником, ID папки из этого диска.\n",
                    file=sys.stderr,
                )
                return False, True
            return False, False
    return True, False


def main() -> int:
    print("--- Загрузка артефактов (GCS и/или Drive) ---")

    gcs_bucket = bool(os.environ.get("GCS_BUCKET_NAME", "").strip())
    folder_id = os.environ.get("GOOGLE_DRIVE_FOLDER_ID", "").strip()
    has_sa = bool(os.environ.get("GOOGLE_DRIVE_SERVICE_ACCOUNT", "").strip()) or bool(
        os.environ.get("GOOGLE_DRIVE_SERVICE_ACCOUNT_B64", "").strip()
    )

    print(f"GCS_BUCKET_NAME: {'задан' if gcs_bucket else 'нет'}")
    print(f"GOOGLE_DRIVE_FOLDER_ID: {'задан' if folder_id else 'нет'}")
    print(f"JSON ключа (SA): {'задан' if has_sa else 'нет'}")

    if not gcs_bucket and not folder_id:
        print("Пропуск: не заданы ни GCS_BUCKET_NAME, ни GOOGLE_DRIVE_FOLDER_ID.")
        return 0

    if not has_sa:
        print("ОШИБКА: нужен GOOGLE_DRIVE_SERVICE_ACCOUNT (JSON того же SA, что в GCP).", file=sys.stderr)
        return 1

    if folder_id and not gcs_bucket:
        pass  # ok
    if gcs_bucket and not folder_id:
        pass  # ok

    try:
        info = _load_service_account_dict()
    except (json.JSONDecodeError, ValueError) as e:
        print(f"ОШИБКА JSON ключа: {e}", file=sys.stderr)
        return 1

    print(f"client_email: {info.get('client_email', '?')}")

    paths = _collect_files()
    print(f"Файлов к загрузке: {len(paths)}")
    for p in paths:
        print(f"  - {p} ({os.path.getsize(p)} bytes)")
    if not paths:
        print("ОШИБКА: нет APK/AAB.", file=sys.stderr)
        return 1

    ok_gcs = True
    ok_drive = True
    drive_quota_exceeded = False
    tried_gcs = gcs_bucket
    tried_drive = bool(folder_id)

    if tried_gcs:
        try:
            ok_gcs = _upload_gcs(paths, info)
        except Exception as e:
            ok_gcs = False
            print(f"GCS ошибка: {e}", file=sys.stderr)

    if tried_drive:
        ok_drive, drive_quota_exceeded = _upload_drive(paths, info, folder_id)

    if tried_gcs and tried_drive:
        if ok_gcs and ok_drive:
            return 0
        if ok_gcs or ok_drive:
            print(
                "Предупреждение: одна из целей не удалась (см. лог выше). "
                "Артефакты всё же доступны там, где успех.",
                file=sys.stderr,
            )
            return 0
        return 1

    if tried_gcs:
        return 0 if ok_gcs else 1
    if ok_drive:
        return 0
    if drive_quota_exceeded:
        print(
            "Предупреждение: пропускаю падение CI, т.к. Drive с service account без Shared drive "
            "не поддерживает квоту. Артефакты доступны в GitHub Artifacts.",
            file=sys.stderr,
        )
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
