from app.services.email import email_service

def send_verification_email(email: str, username: str, token: str) -> bool:
    """Wrapper function to route verification email through the reusable EmailService.
    Maintains compatibility with all existing callers and the test suite.
    """
    return email_service.send_verification_email(email, username, token)