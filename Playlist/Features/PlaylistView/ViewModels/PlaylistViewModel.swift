import Foundation

protocol PlaylistViewModelDelegate: AnyObject {
    func listDidUpdate()
    func songDidUpdate(index: Int)
}

class PlaylistViewModel: PlaylistViewModelProtocol {
    
    private var songService: SongServiceProtocol
    private var downloadFileManager: DownloadFileManagerProtocol
    private var audioManager: AudioPlayerManagerProtocol
    private var persistenceManager: PersistenceManagerProtocol
    
    weak var delegate: PlaylistViewModelDelegate?
    
    private var songList = [Song]()
    private var songState = [String: SongState]()
    private var songReadWriteThread = DispatchQueue(label: "playlist.song.state.queue")
    private var lastSongPlayed: Song?
    
    init(songService: SongServiceProtocol,
         downloadFileManager: DownloadFileManagerProtocol = Dependency.downloadFileManager,
         audioPlayerManager: AudioPlayerManagerProtocol = Dependency.audioPlayerManager,
         persistenceManager: PersistenceManagerProtocol = Dependency.persistenceManager) {
        self.songService = songService
        self.downloadFileManager = downloadFileManager
        self.audioManager = audioPlayerManager
        self.persistenceManager = persistenceManager
        
        self.downloadFileManager.delegate = self
        self.audioManager.delegate = self
    }
    
    /**
     Loads all songs from the database then will fetch and update from server. Should be called from the main thread.
     */
    func refreshSongList() {
        getAllLocalSongList()
        delegate?.listDidUpdate()
        
        getRemoteSongList { [weak self] items, error in
            self?.updateLocallySavedSongs(from: items)
            DispatchQueue.main.async {
                self?.getAllLocalSongList()
                self?.delegate?.listDidUpdate()
            }
        }
    }
    
    /**
     Will download song file from server and update database. Expected to be called from main thread.
     */
    func downloadSong(_ song: Song) {
        guard let urlString = song.audioUrlString,
              let url = URL(string: urlString)
        else { return }
        
        downloadFileManager.downloadFile(fromUrl: url)
    }
    
    /**
     Plays song saved from disk. Also, pausing any currently playing song, if any. Expected to be called from main thread.
     */
    func playSong(_ song: Song) {
        guard let fileName = song.localFileName else { return }
        
        if let lastSongPlayed, lastSongPlayed.id != song.id {
            pauseSong(lastSongPlayed)
        }
        
        let isSuccess = audioManager.playAudio(withFileName: fileName)
        if isSuccess {
            lastSongPlayed = song
        }
        
        setSongStateFromMainQueue(.playing, forSong: song)
        if let index = songList.firstIndex(of: song) {
            delegate?.songDidUpdate(index: index)
        }
    }
    
    /**
     Pauses song. Expected to be called from main thread.
     */
    func pauseSong(_ song: Song) {
        audioManager.pauseCurrentAudio()
        
        setSongStateFromMainQueue(.paused, forSong: song)
        if let index = songList.firstIndex(of: song) {
            delegate?.songDidUpdate(index: index)
        }
    }
    
    /**
     Returns instance of SongCellViewModelProtocol. Expected to be called from main thread.
     */
    func getSongCellViewModel(forIndex index: Int) -> SongCellViewModelProtocol? {
        let song = getSong(at: index)
        guard let state = getSongStateFromMainQueue(song) else {
            return nil
        }
        
        return SongCellViewModel(song: song, state: state)
    }
    
    func getIndexForSong(withUrlString url: String) -> Int? {
        DispatchQueue.main.sync {
            return self.songList.firstIndex { song in
                song.audioUrlString == url
            }
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
}

extension PlaylistViewModel: DownloadFileManagerDelegate {
    func didReceiveProgress(_ progress: CGFloat, forUrl url: URL) {
        let urlString = url.absoluteString
        setSongState(.downloading(progress: progress), forDownloadUrlString: urlString)
        
        updateSongUI(withUrlString: urlString)
    }
    
    func didFinishDownload(forUrl url: URL, localFileName: String) {
        if let index = getIndexForSong(withUrlString: url.absoluteString) {
            let song = getSong(at: index)
            updateDatabaseSong(song, withLocalFileName: localFileName)
            
            DispatchQueue.main.async { [weak self] in
                if let songId = song.id, let updatedSong = self?.getDatabaseSong(withId: songId) {
                    self?.setSongStateFromBackgroundQueue(.paused, forSong: updatedSong)
                    self?.updateSongList(updatedSong, at: index)
                }
            }
        }
    }
    
    func didReceiveError(_ error: Error, forUrl url: URL) {
        let urlString = url.absoluteString
        setSongState(.toDownload, forDownloadUrlString: urlString)
        
        updateSongUI(withUrlString: urlString)
    }
}

extension PlaylistViewModel: AudioPlayerManagerDelegate {
    func didFinishPlaying(audioWithFileName fileName: String?) {
        if let currentSong = lastSongPlayed {
            pauseSong(currentSong)
        }
    }
}

private extension PlaylistViewModel {
    /**
     Will fetch all songs saved in the database. Should be called from the main thread.
     */
    func getAllLocalSongList () {
        let sortyById = NSSortDescriptor(key: "id", ascending: true)
        let localSongs = persistenceManager.getAll(context: persistenceManager.managedObjectContext,
                                                   type: Song.self,
                                                   sortDescriptors: [sortyById])
        songList = localSongs ?? []
        resetSongState()
    }
    
    /**
     Will fetch song from database to be used in main thread.
     */
    func getDatabaseSong(withId id: String) -> Song? {
        let managedObjectContext = persistenceManager.managedObjectContext
        let song = persistenceManager.getModel(context: managedObjectContext,
                                               id: id,
                                               type: Song.self)
        return song
    }
    
    /**
     Will fetch all songs from the server and will update the database and `songList`.
     */
    func getRemoteSongList(completion: @escaping ([SongItemResponse], Error?) -> Void) {
        songService.getSongList { songs, error in
            let list = songs ?? [SongItemResponse]()
            
            completion(list, error)
        }
    }
    
    /**
     Will update songs in the database based from the response from the server.
     */
    func updateLocallySavedSongs(from list: [SongItemResponse]) {
        guard list.count > 0 else { return }
        
        let backgroundContext = persistenceManager.backgroundTaskManagedContext
        
        backgroundContext.performAndWait {
            let allSongs = persistenceManager.getAll(context: backgroundContext,
                                                     type: Song.self,
                                                     sortDescriptors: nil)
            
            // get songs to be deleted from the database
            let serverSongIdList = list.map({ $0.id })
            let toDeleteList = allSongs?.filter({ localSong in
                !serverSongIdList.contains(localSong.id ?? "")
            }) ?? []
            for item in toDeleteList {
                backgroundContext.delete(item)
            }
            
            // get songs to be added in the database
            let localSongIdList = allSongs?.compactMap({ $0.id }) ?? []
            let toAddList = list.filter { serverSong in
                !localSongIdList.contains(serverSong.id)
            }
            for item in toAddList {
                let newSong = Song(context: backgroundContext)
                newSong.id = item.id
                newSong.name = item.name
                newSong.audioUrlString = item.audioUrl
            }
            
            try? backgroundContext.save()
        }
        
        DispatchQueue.main.async {
            self.persistenceManager.saveMainContext()
        }
    }
    
    /**
     Will update file name of song object from the database.
     */
    func updateDatabaseSong(_ song: Song, withLocalFileName fileName: String) {
        let songObjectId = song.objectID
        let backgroundContext = persistenceManager.backgroundTaskManagedContext
        
        backgroundContext.performAndWait {
            let contextSong = backgroundContext.object(with: songObjectId) as? Song
            contextSong?.localFileName = fileName
            
            try? backgroundContext.save()
        }
        
        DispatchQueue.main.async {
            self.persistenceManager.saveMainContext()
        }
    }
    
    func resetSongState() {
        songReadWriteThread.sync {
            self.songState = [:]
            self.songList.forEach({ song in
                guard let songId = song.id else { return }
                self.songState[songId] = song.localFileName == nil ? .toDownload : .paused
            })
        }
    }
    
    func getSongStateFromMainQueue(_ song: Song) -> SongState? {
        var state: SongState?
        songReadWriteThread.sync {
            guard let songId = song.id else {
                return
            }
            state = songState[songId]
        }
        
        return state
    }
    
    func getSongStateFromBackgroundQueue(_ song: Song) -> SongState? {
        let songObjectId = song.objectID
        var state: SongState?
        songReadWriteThread.sync {
            let backgroundContext = self.persistenceManager.backgroundTaskManagedContext
            var backgroundContextSong: Song?
            
            backgroundContext.performAndWait {
                backgroundContextSong = self.persistenceManager.backgroundTaskManagedContext.object(with: songObjectId) as? Song
            }
            
            guard let songId = backgroundContextSong?.id else {
                return
            }
            state = songState[songId]
        }
        
        return state
    }
    
    /**
     Returns song state based on download URL. Expected to be called from background queue
     */
    func setSongState(_ state: SongState, forDownloadUrlString urlString: String) {
        guard let index = getIndexForSong(withUrlString: urlString) else { return }
        
        let song = getSong(at: index)
        setSongStateFromBackgroundQueue(state, forSong: song)
    }
    
    func setSongStateFromMainQueue(_ state: SongState, forSong song: Song) {
        songReadWriteThread.sync {
            guard let songId = song.id else { return }
            songState[songId] = state
        }
    }
    
    func setSongStateFromBackgroundQueue(_ state: SongState, forSong song: Song) {
        let songObjectId = song.objectID
        songReadWriteThread.sync {
            let backgroundContext = self.persistenceManager.backgroundTaskManagedContext
            var backgroundContextSong: Song?
            
            backgroundContext.performAndWait {
                backgroundContextSong = self.persistenceManager.backgroundTaskManagedContext.object(with: songObjectId) as? Song
                guard let songId = backgroundContextSong?.id else { return }
                songState[songId] = state
            }
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
    
    func updateSongList(_ song: Song, at index: Int) {
        songReadWriteThread.sync {
            songList.remove(at: index)
            songList.insert(song, at: index)
        }
        
        updateSongUI(at: index)
    }
}
