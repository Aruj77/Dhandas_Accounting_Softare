class GSTServiceError(Exception):
    """Base exception for all GST service errors."""


class InvalidGSTINError(GSTServiceError):
    """Raised when GSTIN format/checksum is invalid, or GSTIN is inactive."""


class GSTINNotFoundError(GSTServiceError):
    """Raised when the provider has no record for the given GSTIN."""


class GSTProviderError(GSTServiceError):
    """Raised when the upstream provider fails, times out, or is unreachable."""


class InvalidHSNError(GSTServiceError):
    """Raised when HSN/SAC format is invalid (must be 2, 4, 6 or 8 digits)."""


class HSNNotFoundError(GSTServiceError):
    """Raised when no provider (online or offline) recognizes the HSN/SAC code."""
