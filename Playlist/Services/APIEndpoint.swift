import Foundation

public enum APIEndpoint {
    case songList
    
    var path: String {
        switch self {
        case .songList: return "/Lenhador/a0cf9ef19cd816332435316a2369bc00/raw/a1338834fc60f7513402a569af09ffa302a26b63/Songs.json"
        }
    }
    
    var url: URL? {
        return URL(string: "\(Config.baseUrlString)\(path)")
    }
}
