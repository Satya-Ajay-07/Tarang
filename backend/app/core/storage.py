import abc
from fastapi import UploadFile
from typing import Optional
from app.core.config import settings

class BaseStorage(abc.ABC):
    @abc.abstractmethod
    def upload_file(self, file: UploadFile, folder: str = "tarang") -> str:
        pass

    @abc.abstractmethod
    def delete_file(self, file_url: str) -> bool:
        pass


class CloudinaryStorage(BaseStorage):
    def __init__(self):
        import cloudinary
        import cloudinary.uploader
        
        # Configure cloudinary
        if settings.CLOUDINARY_CLOUD_NAME and settings.CLOUDINARY_API_KEY:
            cloudinary.config(
                cloud_name=settings.CLOUDINARY_CLOUD_NAME,
                api_key=settings.CLOUDINARY_API_KEY,
                api_secret=settings.CLOUDINARY_API_SECRET,
                secure=True
            )
        self.uploader = cloudinary.uploader

    def upload_file(self, file: UploadFile, folder: str = "tarang") -> str:
        # Check if setup correctly
        if not settings.CLOUDINARY_CLOUD_NAME or settings.CLOUDINARY_CLOUD_NAME == "dev_cloudinary":
            # Return placeholder in local dev if not configured
            return f"https://res.cloudinary.com/demo/image/upload/v12345/sample.png"
            
        result = self.uploader.upload(
            file.file,
            folder=folder,
            resource_type="auto"
        )
        return result.get("secure_url")

    def delete_file(self, file_url: str) -> bool:
        import cloudinary.uploader
        try:
            # Extract public ID from URL
            # Example: https://res.cloudinary.com/cloud_name/image/upload/v12345/tarang/public_id.jpg
            if "cloudinary.com" not in file_url:
                return False
            parts = file_url.split("/")
            # public id is tarang/public_id
            public_id = f"{parts[-2]}/{parts[-1].split('.')[0]}"
            cloudinary.uploader.destroy(public_id)
            return True
        except Exception:
            return False

# Export the active storage provider
def get_storage() -> BaseStorage:
    return CloudinaryStorage()
