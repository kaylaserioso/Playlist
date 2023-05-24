import Foundation

public enum SongState {
    case toDownload
    case downloading(progress: CGFloat)
    case paused
    case playing
}
