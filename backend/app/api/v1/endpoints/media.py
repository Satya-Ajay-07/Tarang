from fastapi import APIRouter, Depends, UploadFile, File
from app.api.deps import get_current_active_user
from app.core.exceptions import BadRequestException
from app.core.storage import get_storage
from app.models.models import User

router = APIRouter()

# Max file size constraints
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10MB
MAX_VIDEO_SIZE = 50 * 1024 * 1024  # 50MB

SUPPORTED_IMAGE_TYPES = {"image/jpeg", "image/png", "image/webp"}
SUPPORTED_VIDEO_TYPES = {"video/mp4", "video/webm"}

@router.post("/upload", response_model=dict)
async def upload_media(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_active_user)
):
    # Validate content type
    content_type = file.content_type
    if content_type in SUPPORTED_IMAGE_TYPES:
        max_size = MAX_IMAGE_SIZE
        folder = "tarang/images"
    elif content_type in SUPPORTED_VIDEO_TYPES:
        max_size = MAX_VIDEO_SIZE
        folder = "tarang/videos"
    else:
        raise BadRequestException(
            detail="Unsupported file format. Please upload JPEG, PNG, WebP, MP4, or WebM.",
            code="UNSUPPORTED_FILE_TYPE"
        )

    # Validate file size (FastAPI does not load entire file to memory unless read is called)
    content = await file.read()
    file_size = len(content)
    if file_size > max_size:
        raise BadRequestException(
            detail=f"File exceeds maximum size limits ({max_size // (1024*1024)}MB)",
            code="FILE_TOO_LARGE"
        )
    
    # Reset read pointer
    await file.seek(0)
    
    try:
        storage = get_storage()
        url = storage.upload_file(file, folder=folder)
        return {"url": url}
    except Exception as e:
        raise BadRequestException(
            detail=f"Failed to upload file to cloud storage: {str(e)}",
            code="UPLOAD_FAILED"
        )
