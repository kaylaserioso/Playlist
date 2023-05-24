import Foundation

protocol PlaylistViewModelProtocol {
    var delegate: PlaylistViewModelDelegate? { get set }
    var songList: [Song] { get }
    func getSongList(completion: @escaping ([Song], Error?) -> Void)
    func getSongCellViewModel(forIndex index: Int) -> SongCellViewModelProtocol?
    func downloadSong(_ song: Song)
}
