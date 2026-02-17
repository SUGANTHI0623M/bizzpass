"""Cloudinary upload service – all file uploads (company logos and other files) use Cloudinary.

- Company logos: uploaded as images to folder bizzpass/companies.
- Other files: use upload_file() for raw/documents (PDF, etc.) in folder bizzpass/files.
"""
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
    """Upload image bytes to Cloudinary (company logos, avatars, etc.). Returns secure URL or None on failure."""
    try:
        unique_id = uuid.uuid4().hex[:12]
        result = cloudinary.uploader.upload(
            file_data,
            folder=folder,
            public_id=f"{public_id_prefix}_{unique_id}",
            resource_type="image",
        )
        return result.get("secure_url")
    except Exception:
        return None


def upload_file(
    file_data: bytes,
    folder: str = "bizzpass/files",
    public_id_prefix: str = "file",
    resource_type: str = "raw",
) -> str | None:
    """Upload any file (PDF, document, etc.) to Cloudinary. Returns secure URL or None on failure."""
    try:
        unique_id = uuid.uuid4().hex[:12]
        result = cloudinary.uploader.upload(
            file_data,
            folder=folder,
            public_id=f"{public_id_prefix}_{unique_id}",
            resource_type=resource_type,
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
