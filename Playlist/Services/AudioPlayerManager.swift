import Foundation
import AVFoundation

public class AudioPlayerManager: NSObject, AudioPlayerManagerProtocol {
    private var audioPlayer: AVAudioPlayer?
    private lazy var documentsUrl: URL? = {
        try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    }()
    
    public var currentlyPlayingAudioFileName: String?
    
    override init() {
        super.init()
        
        setup()
    }
    
    public func playAudio(withFileName fileName: String) -> Bool {
        guard let audioURL = documentsUrl?.appendingPathComponent(fileName) else {
            return false
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: audioURL)
            player.delegate = self
            self.audioPlayer = player
            
            player.play()
            self.currentlyPlayingAudioFileName = fileName
            return true
        } catch {
            print("Failed to play audio: \(error.localizedDescription) ")
            return false
        }
    }
    
    public func pauseCurrentAudio() {
        guard let player = audioPlayer, player.isPlaying else {
            return
        }
        
        player.pause()
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    
}

private extension AudioPlayerManager {
    func setup() {
        do {
            try AVAudioSession.sharedInstance().setMode(.default)
        } catch {
            
        }
    }
}
