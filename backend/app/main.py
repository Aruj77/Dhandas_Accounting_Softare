from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.api.v1.endpoints import gstin, hsn, sync, reports
from app.core.exceptions import (
    GSTINNotFoundError,
    GSTProviderError,
    HSNNotFoundError,
    InvalidGSTINError,
    InvalidHSNError,
)

app = FastAPI(
    title="Dhandha GST Service",
    version="1.0.0",
)

# Routers
app.include_router(gstin.router, prefix="/api/v1")
app.include_router(hsn.router, prefix="/api/v1")
app.include_router(sync.router, prefix="/api/v1")
app.include_router(reports.router, prefix="/api/v1")


# Exception handlers
@app.exception_handler(InvalidGSTINError)
async def invalid_gstin_handler(
    request: Request,
    exc: InvalidGSTINError,
) -> JSONResponse:
    return JSONResponse(
        status_code=400,
        content={"valid": False, "message": str(exc)},
    )


@app.exception_handler(GSTINNotFoundError)
async def gstin_not_found_handler(
    request: Request,
    exc: GSTINNotFoundError,
) -> JSONResponse:
    return JSONResponse(
        status_code=404,
        content={"valid": False, "message": str(exc)},
    )


@app.exception_handler(GSTProviderError)
async def provider_error_handler(
    request: Request,
    exc: GSTProviderError,
) -> JSONResponse:
    return JSONResponse(
        status_code=502,
        content={"valid": False, "message": str(exc)},
    )


@app.exception_handler(InvalidHSNError)
async def invalid_hsn_handler(
    request: Request,
    exc: InvalidHSNError,
) -> JSONResponse:
    return JSONResponse(
        status_code=400,
        content={"valid": False, "message": str(exc)},
    )


@app.exception_handler(HSNNotFoundError)
async def hsn_not_found_handler(
    request: Request,
    exc: HSNNotFoundError,
) -> JSONResponse:
    return JSONResponse(
        status_code=404,
        content={"valid": False, "message": str(exc)},
    )


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}
