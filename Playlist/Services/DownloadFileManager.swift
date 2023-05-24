import Foundation

public protocol DownloadFileManagerDelegate: AnyObject {
    func didReceiveProgress(_ progress: CGFloat, forUrl url: URL)
    func didFinishDownload(forUrl url: URL, localFileName: String)
    func didReceiveError(_ error: Error, forUrl url: URL)
}

public enum DownloadState: Equatable {
    case downloading(progress: CGFloat)
    case success
    case error(error: Error)
    
    public static func == (lhs: DownloadState, rhs: DownloadState) -> Bool {
        switch (lhs, rhs) {
        case (.success, .success): return true
        case (.downloading(_), .downloading(progress: _)): return true
        case (.error(_), .error(_)): return true
        default: return false
        }
    }
}

public class DownloadFileManager: NSObject, DownloadFileManagerProtocol {
    public weak var delegate: DownloadFileManagerDelegate?
    
    lazy var urlSession = URLSession(configuration: .default,
                                     delegate: self,
                                     delegateQueue: nil)
    
    private var downloadQueue = DispatchQueue(label: "playlist.download.queue", attributes: .concurrent)
    private var stateReadWriteQueue = DispatchQueue(label: "playlist.download.state.queue")
    private var downloadState = [String: DownloadState]()
    
    public func downloadFile(fromUrl url: URL) {
        let state = getDownloadState(forUrlString: url.absoluteString)
        guard (state == nil) || (state == DownloadState.error(error: NSError()))
        else { return }
        
        downloadQueue.async { [weak self] in
            let request = URLRequest(url: url)
            self?.setDownloadState(.downloading(progress: 0), forUrlString: url.absoluteString)
            let task = self?.urlSession.downloadTask(with: request)
            task?.resume()
        }
    }
    
    public func getDownloadState(forUrlString url: String) -> DownloadState? {
        stateReadWriteQueue.sync {
            return downloadState[url]
        }
    }
    
    private func setDownloadState(_ state: DownloadState, forUrlString url: String) {
        stateReadWriteQueue.sync {
            downloadState[url] = state
        }
    }
}

extension DownloadFileManager: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        guard let requestUrl = downloadTask.originalRequest?.url else { return }
        
        do {
            let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: false)
            let fileName = location.lastPathComponent
            let savedUrl = documentsURL.appendingPathComponent(fileName)
            try FileManager.default.moveItem(at: location, to: savedUrl)
            
            setDownloadState(.success, forUrlString: requestUrl.absoluteString)
            delegate?.didFinishDownload(forUrl: requestUrl, localFileName: fileName)
        } catch {
            setDownloadState(.error(error: error), forUrlString: requestUrl.absoluteString)
            delegate?.didReceiveError(error, forUrl: requestUrl)
        }
    }
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        guard let requestUrl = downloadTask.originalRequest?.url else { return }
        
        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        setDownloadState(.downloading(progress: progress), forUrlString: requestUrl.absoluteString)
        delegate?.didReceiveProgress(progress, forUrl: requestUrl)
    }
}
