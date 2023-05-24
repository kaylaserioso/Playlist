import Foundation

protocol PlaylistViewModelDelegate: AnyObject {
    func songDidUpdate(index: Int)
}

class PlaylistViewModel: PlaylistViewModelProtocol {
    
    private var songService: SongServiceProtocol
    private var downloadFileManager: DownloadFileManagerProtocol
    private var audioManager: AudioPlayerManagerProtocol
    
    weak var delegate: PlaylistViewModelDelegate?
    
    private var songList = [Song]()
    private var songState = [String: SongState]()
    private var songReadWriteThread = DispatchQueue(label: "playlist.song.state.queue")
    private var lastSongPlayed: Song?
    
    init(songService: SongServiceProtocol,
         downloadFileManager: DownloadFileManagerProtocol = Dependency.downloadFileManager,
         audioPlayerManager: AudioPlayerManagerProtocol = Dependency.audioPlayerManager) {
        self.songService = songService
        self.downloadFileManager = downloadFileManager
        self.audioManager = audioPlayerManager
        
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
    
    func playSong(_ song: Song) {
        guard let fileName = song.localFileName else { return }
        
        if let lastSongPlayed, lastSongPlayed.id != song.id {
            pauseSong(lastSongPlayed)
        }
        
        let isSuccess = audioManager.playAudio(withFileName: fileName)
        if isSuccess {
            lastSongPlayed = song
        }
        
        setSongState(.playing, forSong: song)
        if let index = getIndexForSong(withUrlString: song.audioUrl) {
            updateSong(song, at: index)
        }
    }
    
    func pauseSong(_ song: Song) {
        audioManager.pauseCurrentAudio()
        
        setSongState(.paused, forSong: song)
        if let index = getIndexForSong(withUrlString: song.audioUrl) {
            updateSong(song, at: index)
        }
    }
    
    func getSongCellViewModel(forIndex index: Int) -> SongCellViewModelProtocol? {
        let song = getSong(at: index)
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
    
    func getAllSongs() -> [Song] {
        songReadWriteThread.sync {
            return songList
        }
    }
    
    
    func getSong(at index: Int) -> Song {
        songReadWriteThread.sync {
            return songList[index]
        }
    }
    
    func getSongState(_ song: Song) -> SongState? {
        songReadWriteThread.sync {
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
    
    func didFinishDownload(forUrl url: URL, localFileName: String) {
        if let index = getIndexForSong(withUrlString: url.absoluteString) {
            var song = getSong(at: index)
            song.localFileName = localFileName
            
            updateSong(song, at: index)
        }
        
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
        songReadWriteThread.sync {
            self.songState = [:]
            self.songList.forEach({ song in
                self.songState[song.id] = .toDownload
            })
        }
    }
    
    func setSongState(_ state: SongState, forDownloadUrlString urlString: String) {
        guard let index = getIndexForSong(withUrlString: urlString) else { return }
        
        let song = getSong(at: index)
        setSongState(state, forSong: song)
    }
    
    func setSongState(_ state: SongState, forSong song: Song) {
        songReadWriteThread.sync {
            songState[song.id] = state
        }
    }
    
    func updateSongUI(withUrlString urlString: String) {
        if let songIndex = getIndexForSong(withUrlString: urlString) {
            updateSongUI(at: songIndex)
        }
    }
    
    func updateSongUI(at index: Int) {
        delegate?.songDidUpdate(index: index)
    }
    
    func updateSong(_ song: Song, at index: Int) {
        songReadWriteThread.sync {
            songList.remove(at: index)
            songList.insert(song, at: index)
        }
        
        updateSongUI(at: index)
    }
}
