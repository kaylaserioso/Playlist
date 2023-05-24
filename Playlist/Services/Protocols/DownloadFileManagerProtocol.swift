import Foundation

protocol DownloadFileManagerProtocol {
    var delegate: DownloadFileManagerDelegate? { get set }
    
    func downloadFile(fromUrl url: URL)
    func getDownloadState(forUrlString url: String) -> DownloadState?
}
