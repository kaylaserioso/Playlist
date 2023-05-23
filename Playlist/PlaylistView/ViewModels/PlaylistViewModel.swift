import Foundation

protocol PlaylistViewModelProtocol {
    var songList: [Song] { get }
    func getSongList(completion: @escaping ([Song], Error?) -> Void)
}

class PlaylistViewModel: PlaylistViewModelProtocol {
    
    var songService: SongServiceProtocol
    var songList = [Song]()
    
    init(songService: SongServiceProtocol) {
        self.songService = songService
    }
    
    func getSongList(completion: @escaping ([Song], Error?) -> Void) {
        songService.getSongList { [weak self] songs, error in
            let list = songs ?? [Song]()
            self?.songList = list
            completion(list, error)
        }
    }
    
}
