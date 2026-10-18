import QtQuick
import Quickshell

Item {
    id: root

    property string fileName: ""
    property bool isDir: false
    property string iconName: ""
    property int size: 20

    width: size
    height: size

    function resolveIcon(): string {
        if (iconName !== "") {
            return iconName;
        }

        if (isDir) {
            const lower = fileName.toLowerCase();
            if (lower === "downloads" || lower === "téléchargements") return "folder-download";
            if (lower === "documents") return "folder-documents";
            if (lower === "pictures" || lower === "images") return "folder-pictures";
            if (lower === "music" || lower === "musique") return "folder-music";
            if (lower === "videos" || lower === "vidéos") return "folder-videos";
            if (lower === "desktop" || lower === "bureau") return "user-desktop";
            return "folder";
        }

        const dotIdx = fileName.lastIndexOf(".");
        if (dotIdx === -1) {
            return "text-x-generic";
        }

        const ext = fileName.substring(dotIdx + 1).toLowerCase();
        switch (ext) {
            case "png":
            case "jpg":
            case "jpeg":
            case "gif":
            case "svg":
            case "webp":
            case "bmp":
            case "ico":
                return "image-x-generic";

            case "mp4":
            case "mkv":
            case "avi":
            case "mov":
            case "webm":
            case "flv":
                return "video-x-generic";

            case "mp3":
            case "wav":
            case "ogg":
            case "flac":
            case "aac":
            case "opus":
                return "audio-x-generic";

            case "zip":
            case "tar":
            case "gz":
            case "xz":
            case "bz2":
            case "zst":
            case "7z":
            case "rar":
            case "iso":
                return "package-x-generic";

            case "pdf":
                return "application-pdf";

            case "c":
            case "cpp":
            case "cc":
            case "h":
            case "hpp":
                return "text-x-c++src";

            case "py":
                return "text-x-python";

            case "js":
            case "mjs":
            case "cjs":
                return "text-x-javascript";

            case "ts":
                return "text-x-typescript";

            case "qml":
                return "text-x-qml";

            case "html":
            case "htm":
                return "text-html";

            case "css":
                return "text-css";

            case "json":
                return "application-json";

            case "xml":
                return "application-xml";

            case "sh":
            case "bash":
                return "application-x-shellscript";

            case "txt":
            case "log":
            case "ini":
            case "conf":
                return "text-x-generic";

            case "md":
                return "text-markdown";

            case "desktop":
                return "application-x-desktop";

            default:
                return "text-x-generic";
        }
    }

    Image {
        id: img
        anchors.fill: parent
        sourceSize: Qt.size(root.size, root.size)
        source: Quickshell.iconPath(root.resolveIcon(), root.isDir ? "folder" : "text-x-generic")
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }
}
