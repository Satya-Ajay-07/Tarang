from fastapi import HTTPException, status

class TarangException(HTTPException):
    def __init__(self, status_code: int, detail: str, code: str = "ERROR", extra: dict = None):
        super().__init__(status_code=status_code, detail=detail)
        self.code = code
        self.extra = extra or {}

class NotFoundException(TarangException):
    def __init__(self, detail: str = "Resource not found", code: str = "NOT_FOUND"):
        super().__init__(status_code=status.HTTP_404_NOT_FOUND, detail=detail, code=code)

class UnauthorizedException(TarangException):
    def __init__(self, detail: str = "Could not authenticate user", code: str = "UNAUTHORIZED", extra: dict = None):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            code=code,
            extra=extra
        )

class ForbiddenException(TarangException):
    def __init__(self, detail: str = "Not enough permissions", code: str = "FORBIDDEN"):
        super().__init__(status_code=status.HTTP_403_FORBIDDEN, detail=detail, code=code)

class BadRequestException(TarangException):
    def __init__(self, detail: str = "Bad request parameters", code: str = "BAD_REQUEST"):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, detail=detail, code=code)

class EmailDeliveryException(BadRequestException):
    def __init__(self, detail: str = "Failed to send email. Please try again later.", code: str = "EMAIL_DELIVERY_FAILED"):
        super().__init__(detail=detail, code=code)
