import uuid as uuid_lib
from datetime import datetime, timezone

from sqlalchemy import BigInteger, DateTime, Integer, String, Boolean
from sqlalchemy.orm import Mapped, mapped_column


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


class SyncMixin:
    """Mirrors lib/database/tables/core_tables.dart::SyncColumns.

    `id` (internal, autoincrement) is used for every FK -> fast joins.
    `uuid` is the stable identity shared with the SQLite/Drift client and is
    what the sync protocol keys off (never the internal id, which differs
    per device).
    """

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    uuid: Mapped[str] = mapped_column(
        String(36), unique=True, index=True, default=lambda: str(uuid_lib.uuid4())
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, onupdate=utcnow, index=True
    )
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    version: Mapped[int] = mapped_column(Integer, default=1)
    is_dirty: Mapped[bool] = mapped_column(Boolean, default=True)
