class GSTServiceError(Exception):
    """Base exception for all GST service errors."""


class InvalidGSTINError(GSTServiceError):
    """Raised when GSTIN format/checksum is invalid, or GSTIN is inactive."""


class GSTINNotFoundError(GSTServiceError):
    """Raised when the provider has no record for the given GSTIN."""


class GSTProviderError(GSTServiceError):
    """Raised when the upstream provider fails, times out, or is unreachable."""
