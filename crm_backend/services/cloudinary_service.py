"""Cloudinary upload service for company logos and other images."""
import uuid
import cloudinary
import cloudinary.uploader
from config.settings import settings

cloudinary.config(
    cloud_name=settings.cloudinary_cloud_name,
    api_key=settings.cloudinary_api_key,
    api_secret=settings.cloudinary_api_secret,
    secure=True,
)


def upload_image(file_data: bytes, folder: str = "bizzpass", public_id_prefix: str = "company") -> str | None:
    """Upload image bytes to Cloudinary. Returns URL or None on failure."""
    try:
        unique_id = uuid.uuid4().hex[:12]
        result = cloudinary.uploader.upload(
            file_data,
            folder=folder,
            public_id=f"{public_id_prefix}_{unique_id}",
        )
        return result.get("secure_url")
    except Exception:
        return None


def delete_image(url: str) -> bool:
    """Delete image from Cloudinary by URL. Returns True if deleted."""
    try:
        public_id = _url_to_public_id(url)
        if public_id:
            cloudinary.uploader.destroy(public_id)
            return True
    except Exception:
        pass
    return False


def _url_to_public_id(url: str) -> str | None:
    """Extract public_id from Cloudinary URL."""
    if "cloudinary.com" not in url or "/image/upload/" not in url:
        return None
    try:
        parts = url.split("/image/upload/")
        if len(parts) < 2:
            return None
        path = parts[1]
        if "." in path:
            path = path.rsplit(".", 1)[0]
        return path
    except Exception:
        return None
