import Foundation

class SongCellViewModel: SongCellViewModelProtocol {
    let song: Song
    
    var name: String {
        song.name
    }
    
    private(set) var state: SongState = .toDownload
    
    init(song: Song, state: SongState) {
        self.song = song
        self.state = state
    }
}
