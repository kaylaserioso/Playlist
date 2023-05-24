import Foundation

enum Dependency {
    static var downloadFileManager: DownloadFileManagerProtocol = DownloadFileManager()
    static var audioPlayerManager: AudioPlayerManagerProtocol = AudioPlayerManager()
}
