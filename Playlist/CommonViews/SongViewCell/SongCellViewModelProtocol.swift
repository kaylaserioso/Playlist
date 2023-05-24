import Foundation

protocol SongCellViewModelProtocol {
    var song: Song { get }
    var name: String { get }
    var state: SongState { get }
}
