import resend
from datetime import datetime
from app.core.config import settings

def send_verification_email(email: str, username: str, token: str):
    verification_url = (
    f"{settings.FRONTEND_URL}/verify-email?token={token}"
    )
    
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Verify your Tarang Account</title>
        <style>
            body {{
                font-family: 'Outfit', 'Inter', Helvetica, Arial, sans-serif;
                background-color: #F8FBFD;
                color: #0F4C81;
                margin: 0;
                padding: 0;
            }}
            .container {{
                max-width: 600px;
                margin: 40px auto;
                background-color: #ffffff;
                border-radius: 24px;
                padding: 40px;
                box-shadow: 0 10px 25px rgba(20, 184, 166, 0.1);
                border: 1px solid rgba(226, 232, 240, 0.8);
            }}
            .logo {{
                font-size: 28px;
                font-weight: 800;
                text-align: center;
                margin-bottom: 24px;
                color: #0F4C81;
            }}
            .logo span {{
                color: #14B8A6;
            }}
            h1 {{
                font-size: 22px;
                font-weight: 700;
                text-align: center;
                margin-bottom: 8px;
            }}
            p {{
                font-size: 16px;
                line-height: 1.6;
                color: #4A5568;
                text-align: center;
                margin-bottom: 24px;
            }}
            .btn-container {{
                text-align: center;
                margin: 32px 0;
            }}
            .btn {{
                background-color: #14B8A6;
                color: #ffffff !important;
                padding: 14px 32px;
                font-size: 16px;
                font-weight: 700;
                text-decoration: none;
                border-radius: 16px;
                box-shadow: 0 8px 15px rgba(20, 184, 166, 0.25);
                display: inline-block;
            }}
            .link-container {{
                margin-top: 32px;
                padding-top: 24px;
                border-t: 1px solid #E2E8F0;
                word-break: break-all;
                font-size: 13px;
                color: #A0AEC0;
                text-align: center;
            }}
            .link-container a {{
                color: #14B8A6;
                text-decoration: none;
            }}
            .footer {{
                text-align: center;
                margin-top: 40px;
                font-size: 12px;
                color: #A0AEC0;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="logo">🌊 Tar<span>ang</span></div>
            <h1>Welcome to the Wave Circle, @{username}!</h1>
            <p>Every Voice Creates a Wave. To activate your account and start sharing, please verify your email address by clicking the button below. This link expires in 24 hours.</p>
            <div class="btn-container">
                <a href="{verification_url}" class="btn">Verify Account</a>
            </div>
            <div class="link-container">
                If the button doesn't work, copy and paste this URL into your browser:<br>
                <a href="{verification_url}">{verification_url}</a>
            </div>
            <div class="footer">
                &copy; {datetime.utcnow().year} Tarang. All rights reserved.<br>
                Connecting people through community currents.
            </div>
        </div>
    </body>
    </html>
    """

    # Check if we should use Resend (requires configured key)
    has_valid_key = settings.RESEND_API_KEY and settings.RESEND_API_KEY not in ("re_your_api_key", "", None)
    
    if has_valid_key:
        try:
            resend.api_key = settings.RESEND_API_KEY
            r = resend.Emails.send({
                "from": f"Tarang <{settings.MAIL_FROM}>",
                "to": email,
                "subject": "Verify your Tarang Account 🌊",
                "html": html_content
            })
            print(f"[MAIL PRODUCTION] Verification email sent via Resend for {email}: {r}")
        except Exception as e:
            print(f"[MAIL ERROR] Failed sending via Resend: {str(e)}")
            # Fallback output in logs so it does not block the user entirely if API fails
            print(f"[MAIL MOCK FALLBACK] Verification link for {email}: {verification_url}")
    else:
        # Mock implementation for local/dev
        print(f"[MAIL MOCK] Verification link for {email}: {verification_url}")
