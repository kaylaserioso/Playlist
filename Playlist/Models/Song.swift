import Foundation

public struct Song: Codable {
    let id: String
    let name: String
    let audioURL: String
    let fileName: String?
}
