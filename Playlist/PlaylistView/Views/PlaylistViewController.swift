import UIKit

class PlaylistViewController: UIViewController {
    
    var viewModel: PlaylistViewModelProtocol?
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel?.delegate = self
        viewModel?.getSongList(completion: { [weak self] _, error in
            if let error {
                //show error
                return
            }
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        })
    }
}

extension PlaylistViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.songList.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SongViewCell.reuseIdentifier) as? SongViewCell ?? SongViewCell()
        
        let cellViewModel = self.viewModel?.getSongCellViewModel(forIndex: indexPath.row)
        cell.delegate = self
        cell.updateViewModel(cellViewModel)
        
        return cell
    }
}

extension PlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}

extension PlaylistViewController: PlaylistViewModelDelegate {
    func songDidUpdate(index: Int) {
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }
}

extension PlaylistViewController: SongViewCellDelegate {
    func didTapDownload(song: Song) {
        viewModel?.downloadSong(song)
    }
    
    func didTapPause(song: Song) {
        
    }
    
    func didTapPlay(song: Song) {
        
    }
}
