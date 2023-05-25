import Foundation

public struct SongItemResponse: Codable {
    let id: String
    let name: String
    let audioUrl: String
    var localFileName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case audioUrl = "audioURL"
    }
}
