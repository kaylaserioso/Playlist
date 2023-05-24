import Foundation

protocol PlaylistViewModelDelegate: AnyObject {
    func songDidUpdate(index: Int)
}

class PlaylistViewModel: PlaylistViewModelProtocol {
    
    private var songService: SongServiceProtocol
    private var downloadFileManager: DownloadFileManagerProtocol
    
    weak var delegate: PlaylistViewModelDelegate?
    var songList = [Song]()
    
    private var songState = [String: SongState]()
    private var stateReadWriteThread = DispatchQueue(label: "playlist.song.state.queue")
    
    init(songService: SongServiceProtocol, downloadFileManager: DownloadFileManagerProtocol) {
        self.songService = songService
        
        self.downloadFileManager = downloadFileManager
        self.downloadFileManager.delegate = self
    }
    
    func getSongList(completion: @escaping ([Song], Error?) -> Void) {
        songService.getSongList { [weak self] songs, error in
            let list = songs ?? [Song]()
            self?.songList = list
            
            self?.resetSongState()
            
            completion(list, error)
        }
    }
    
    func downloadSong(_ song: Song) {
        let urlString = song.audioUrl
        
        guard let url = URL(string: urlString)
        else { return }
        
        downloadFileManager.downloadFile(fromUrl: url)
    }
    
    func getSongCellViewModel(forIndex index: Int) -> SongCellViewModelProtocol? {
        let song = songList[index]
        guard let state = getSongState(song) else {
            return nil
        }
        
        return SongCellViewModel(song: song, state: state)
    }
    
    func getIndexForSong(withUrlString url: String) -> Int? {
        return songList.firstIndex { song in
            song.audioUrl == url
        }
    }
    
    func getSongState(_ song: Song) -> SongState? {
        stateReadWriteThread.sync {
            return songState[song.id]
        }
    }
}

extension PlaylistViewModel: DownloadFileManagerDelegate {
    func didReceiveProgress(_ progress: CGFloat, forUrl url: URL) {
        let urlString = url.absoluteString
        setSongState(.downloading(progress: progress), forDownloadUrlString: urlString)
        
        updateSongUI(withUrlString: urlString)
    }
    
    func didFinishDownload(forUrl url: URL, localUrl: URL) {
        let urlString = url.absoluteString
        setSongState(.paused, forDownloadUrlString: urlString)
        
        updateSongUI(withUrlString: urlString)
    }
    
    func didReceiveError(_ error: Error, forUrl url: URL) {
        let urlString = url.absoluteString
        setSongState(.toDownload, forDownloadUrlString: urlString)
        
        updateSongUI(withUrlString: urlString)
    }
}

private extension PlaylistViewModel {
    func resetSongState() {
        stateReadWriteThread.sync {
            self.songState = [:]
            self.songList.forEach({ song in
                self.songState[song.id] = .toDownload
            })
        }
    }
    
    func setSongState(_ state: SongState, forDownloadUrlString urlString: String) {
        guard let index = getIndexForSong(withUrlString: urlString) else { return }
        
        let song = songList[index]
        setSongState(state, forSong: song)
    }
    
    func setSongState(_ state: SongState, forSong song: Song) {
        stateReadWriteThread.sync {
            songState[song.id] = state
        }
    }
    
    func updateSongUI(withUrlString urlString: String) {
        if let songIndex = getIndexForSong(withUrlString: urlString) {
            delegate?.songDidUpdate(index: songIndex)
        }
    }
}
