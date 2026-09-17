from app.core.exceptions import InvalidHSNError
from app.providers.hsn_base import HSNProvider
from app.schemas.hsn import HSNDetails
from app.utils.validators import validate_hsn_format


class HSNService:
    """Business rule: validate format, then look up via the bundled offline
    master data (backend/app/data/hsn_codes.json — official CBIC/GST list).
    No network call needed — the JSON is comprehensive and static.
    To add a live-verified provider later, write NewProvider(HSNProvider)
    and pass it in here instead — nothing else changes.
    """

    def __init__(self, provider: HSNProvider):
        self._provider = provider

    async def validate_and_fetch(self, code: str) -> HSNDetails:
        code = code.strip()

        if not validate_hsn_format(code):
            raise InvalidHSNError("HSN/SAC must be numeric, 2/4/6/8 digits")

        return await self._provider.fetch_hsn_details(code)
