import Foundation

protocol AudioPlayerManagerProtocol {
    var currentlyPlayingAudioFileName: String? { get }
    
    func playAudio(withFileName fileName: String) -> Bool
    func pauseCurrentAudio()
}
