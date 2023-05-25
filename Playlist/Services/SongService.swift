import Foundation

public class SongService: SongServiceProtocol {
    let apiClient = APIClient()
    
    public func getSongList(completion: @escaping ([SongItemResponse]?, Error?) -> Void) {
        guard let url = APIEndpoint.songList.url else {
            completion(nil, nil)
            return
        }
        
        let urlRequest = URLRequest(url: url)
        apiClient.request(urlRequest, type: SongListResponse.self) { response, error in
            completion(response?.data, error)
        }
    }
}
