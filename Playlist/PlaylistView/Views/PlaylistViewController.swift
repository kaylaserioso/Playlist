import UIKit

class PlaylistViewController: UIViewController {
    
    var viewModel: PlaylistViewModelProtocol?
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "SongViewCell", bundle: nil), forCellReuseIdentifier: SongViewCell.reuseIdentifier)
        
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
        return viewModel?.getAllSongs().count ?? 0
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
            guard let indexPaths = self.tableView.indexPathsForVisibleRows,
                  indexPaths.contains(where: { $0.row == index }),
                  let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SongViewCell,
                  let songViewModel = self.viewModel?.getSongCellViewModel(forIndex: index)
            else { return }
            
            cell.updateViewModel(songViewModel)
        }
    }
}

extension PlaylistViewController: SongViewCellDelegate {
    func didTapDownload(song: Song) {
        viewModel?.downloadSong(song)
    }
    
    func didTapPause(song: Song) {
        viewModel?.pauseSong(song)
    }
    
    func didTapPlay(song: Song) {
        viewModel?.playSong(song)
    }
}
