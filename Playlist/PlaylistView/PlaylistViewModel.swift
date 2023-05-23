import Foundation

protocol PlaylistViewModelProtocol {
    func getSongList()
}

class PlaylistViewModel: PlaylistViewModelProtocol {
    
    var songService: SongServiceProtocol
    
    init(songService: SongServiceProtocol) {
        self.songService = songService
    }
    
    func getSongList() {
        songService.getSongList { songs, error in
            
        }
    }
    
}
