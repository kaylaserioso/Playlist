import Foundation

public protocol SongServiceProtocol {
    func getSongList(completion: @escaping ([SongItemResponse]?, Error?) -> Void)
}
