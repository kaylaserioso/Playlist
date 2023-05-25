import Foundation

protocol AudioPlayerManagerProtocol {
    var delegate: AudioPlayerManagerDelegate? { get set }
    var currentlyPlayingAudioFileName: String? { get }
    
    func playAudio(withFileName fileName: String) -> Bool
    func pauseCurrentAudio()
}
