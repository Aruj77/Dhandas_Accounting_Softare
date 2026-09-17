from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.api.v1.endpoints import gstin
from app.core.exceptions import GSTINNotFoundError, GSTProviderError, InvalidGSTINError

app = FastAPI(title="Dhandha GST Service", version="1.0.0")

app.include_router(gstin.router, prefix="/api/v1")


@app.exception_handler(InvalidGSTINError)
async def invalid_gstin_handler(request: Request, exc: InvalidGSTINError) -> JSONResponse:
    return JSONResponse(status_code=400, content={"valid": False, "message": str(exc)})


@app.exception_handler(GSTINNotFoundError)
async def not_found_handler(request: Request, exc: GSTINNotFoundError) -> JSONResponse:
    return JSONResponse(status_code=404, content={"valid": False, "message": str(exc)})


@app.exception_handler(GSTProviderError)
async def provider_error_handler(request: Request, exc: GSTProviderError) -> JSONResponse:
    return JSONResponse(status_code=502, content={"valid": False, "message": str(exc)})


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}
