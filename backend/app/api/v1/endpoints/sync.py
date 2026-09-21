from datetime import datetime
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models import core, transactions
from app.schemas.sync import PushRequest

router = APIRouter(prefix="/sync", tags=["sync"])

# table name -> ORM model. Add new syncable tables here only (DRY).
_TABLE_MODELS = {
    "companies": core.Company,
    "account_groups": core.AccountGroup,
    "accounts": core.Account,
    "items": core.Item,
    "godowns": core.Godown,
    "voucher_types": core.VoucherType,
    "vouchers": transactions.Voucher,
    "voucher_entries": transactions.VoucherEntry,
    "gst_tax_lines": transactions.GstTaxLine,
    "stock_ledger_entries": transactions.StockLedgerEntry,
}

# FK column -> model it points to. Internal `*_id` values are per-database
# (autoincrement) and meaningless across devices, so pull/push translate
# them to/from the stable `uuid` instead.
_FK_MAP = {
    "company_id": core.Company,
    "group_id": core.AccountGroup,
    "parent_id": core.AccountGroup,
    "party_id": core.Account,
    "account_id": core.Account,
    "voucher_type_id": core.VoucherType,
    "voucher_id": transactions.Voucher,
    "voucher_entry_id": transactions.VoucherEntry,
    "item_id": core.Item,
    "godown_id": core.Godown,
}


def _uuid_of(db: Session, model, pk: int | None) -> str | None:
    if pk is None:
        return None
    row = db.query(model.uuid).filter(model.id == pk).first()
    return row[0] if row else None


def _id_of(db: Session, model, uuid_val: str | None) -> int | None:
    if uuid_val is None:
        return None
    row = db.query(model.id).filter(model.uuid == uuid_val).first()
    if not row:
        raise ValueError(f"Sync order error: {model.__tablename__} {uuid_val} not found on server")
    return row[0]


@router.post("/push")
def push(req: PushRequest, db: Session = Depends(get_db)):
    """Apply client changes. Conflict rule: last-write-wins on updated_at —
    a client change only overwrites the server row if it's newer. FK values
    arrive as `*_uuid` (client-local ids are meaningless here) and are
    resolved to this server's own `*_id` before writing."""
    applied, skipped = 0, 0
    for change in req.changes:
        model = _TABLE_MODELS.get(change.table)
        if not model:
            skipped += 1
            continue
        existing = db.query(model).filter(model.uuid == change.uuid).first()
        payload = dict(change.payload)

        # resolve *_uuid -> local *_id for every known FK
        for fk_col, fk_model in _FK_MAP.items():
            uuid_key = fk_col.replace("_id", "_uuid")
            if uuid_key in payload:
                payload[fk_col] = _id_of(db, fk_model, payload.pop(uuid_key))

        payload = {k: v for k, v in payload.items() if hasattr(model, k) and k != "id"}

        if change.op == "delete":
            if existing:
                existing.deleted_at = datetime.utcnow()
            applied += 1
            continue

        if existing:
            incoming_updated = payload.get("updated_at")
            if incoming_updated and existing.updated_at and str(existing.updated_at) >= str(incoming_updated):
                skipped += 1
                continue
            for k, v in payload.items():
                setattr(existing, k, v)
        else:
            db.add(model(**payload))
        applied += 1
    db.commit()
    return {"applied": applied, "skipped": skipped}


@router.get("/pull")
def pull(table: str = Query(...), since: str = Query(...), db: Session = Depends(get_db)):
    """Returns rows changed since [since], with every `*_id` FK replaced by
    the matching `*_uuid` so the client can resolve it to its own local id."""
    model = _TABLE_MODELS.get(table)
    if not model:
        return {"rows": []}
    since_dt = datetime.fromisoformat(since)
    rows = db.query(model).filter(model.updated_at > since_dt).all()

    out = []
    for r in rows:
        row = {c.name: getattr(r, c.name) for c in model.__table__.columns}
        for fk_col, fk_model in _FK_MAP.items():
            if fk_col in row:
                uuid_key = fk_col.replace("_id", "_uuid")
                row[uuid_key] = _uuid_of(db, fk_model, row.pop(fk_col))
        row.pop("id", None)  # server-internal id is never meaningful to a client
        out.append(row)
    return {"rows": out, "server_time": datetime.utcnow().isoformat()}
