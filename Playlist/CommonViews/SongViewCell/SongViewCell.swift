import UIKit

protocol SongViewCellDelegate: AnyObject {
    func didTapDownload(song: Song)
    func didTapPause(song: Song)
    func didTapPlay(song: Song)
}

class SongViewCell: UITableViewCell {
    static let reuseIdentifier: String = "SongViewCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var progressView: ProgressView!
    
    weak var delegate: SongViewCellDelegate?
    
    private var viewModel: SongCellViewModelProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func updateViewModel(_ viewModel: SongCellViewModelProtocol?) {
        self.viewModel = viewModel
        
        updateUI()
    }
    
    @IBAction func didTapActionButton(_ sender: Any) {
        guard let song = viewModel?.song,
              let songState = viewModel?.state
        else { return }
        
        switch songState {
        case .toDownload:
            delegate?.didTapDownload(song: song)
        case .downloading:
            print("")
        case .paused:
            delegate?.didTapPlay(song: song)
        case .playing:
            delegate?.didTapPause(song: song)
        }
    }
}

private extension SongViewCell {
    func updateUI() {
        nameLabel.text = viewModel?.name
        
        updateStateUI()
    }
    
    func updateStateUI() {
        guard let songState = viewModel?.state else { return }

        switch songState {
        case .toDownload:
            actionButton.setImage(UIImage(named: "DownloadIcon"), for: .normal)
            stopLoadingView()
        case .downloading(let progress):
            updateLoadingView(progress: progress)
        case .paused:
            actionButton.setImage(UIImage(named: "PlayIcon"), for: .normal)
            stopLoadingView()
        case .playing:
            actionButton.setImage(UIImage(named: "PauseIcon"), for: .normal)
            stopLoadingView()
        }
    }
    
    func updateLoadingView(progress: CGFloat) {
        actionButton.isHidden = true
        progressView.isHidden = false
        progressView.progressAnimation(progress: progress)
    }
    
    func stopLoadingView() {
        progressView.isHidden = true
        actionButton.isHidden = false
    }
}
