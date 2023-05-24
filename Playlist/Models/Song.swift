import Foundation

public struct Song: Codable {
    let id: String
    let name: String
    let audioUrl: String
    var localUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case audioUrl = "audioURL"
    }
}
