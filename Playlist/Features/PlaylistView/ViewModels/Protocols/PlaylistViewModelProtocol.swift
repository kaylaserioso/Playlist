import Foundation

protocol PlaylistViewModelProtocol {
    var delegate: PlaylistViewModelDelegate? { get set }
    
    func refreshSongList()
    func getSongCellViewModel(forIndex index: Int) -> SongCellViewModelProtocol?
    func downloadSong(_ song: Song)
    func playSong(_ song: Song)
    func pauseSong(_ song: Song)
    func getAllSongs() -> [Song]
    func getSong(at index: Int) -> Song
}
