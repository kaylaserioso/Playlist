import Foundation

public protocol SongServiceProtocol {
    func getSongList(completion: @escaping ([Song]?, Error?) -> Void)
}
