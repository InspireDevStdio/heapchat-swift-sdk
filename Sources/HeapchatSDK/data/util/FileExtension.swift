//
//  FileExtension.swift
//  HeapchatSDK
//
//  Created by Aman Kumar on 20/08/25.
//

/// Determines MIME type based on file extension
/// - Parameter fileExtension: The file extension (lowercase)
/// - Returns: The appropriate MIME type
func getMimeType(for fileExtension: String) -> String {
    switch fileExtension {
    // Images
    case "jpg", "jpeg":
        return "image/jpeg"
    case "png":
        return "image/png"
    case "gif":
        return "image/gif"
    case "webp":
        return "image/webp"
    case "heic", "heif":
        return "image/heic"
    case "bmp":
        return "image/bmp"
    case "tiff", "tif":
        return "image/tiff"
    case "svg":
        return "image/svg+xml"

    // Videos
    case "mp4":
        return "video/mp4"
    case "mov":
        return "video/quicktime"
    case "avi":
        return "video/x-msvideo"
    case "wmv":
        return "video/x-ms-wmv"
    case "flv":
        return "video/x-flv"
    case "webm":
        return "video/webm"
    case "m4v":
        return "video/x-m4v"
    case "3gp":
        return "video/3gpp"

    // Audio
    case "mp3":
        return "audio/mpeg"
    case "wav":
        return "audio/wav"
    case "aac":
        return "audio/aac"
    case "m4a":
        return "audio/mp4"
    case "ogg":
        return "audio/ogg"
    case "flac":
        return "audio/flac"

    // Documents
    case "pdf":
        return "application/pdf"
    case "doc":
        return "application/msword"
    case "docx":
        return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    case "xls":
        return "application/vnd.ms-excel"
    case "xlsx":
        return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    case "ppt":
        return "application/vnd.ms-powerpoint"
    case "pptx":
        return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    case "txt":
        return "text/plain"
    case "rtf":
        return "application/rtf"

    // Archives
    case "zip":
        return "application/zip"
    case "rar":
        return "application/vnd.rar"
    case "7z":
        return "application/x-7z-compressed"
    case "tar":
        return "application/x-tar"
    case "gz":
        return "application/gzip"

    default:
        return "application/octet-stream"
    }
}
