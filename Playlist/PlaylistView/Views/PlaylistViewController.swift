import UIKit

class PlaylistViewController: UIViewController {
    
    var viewModel: PlaylistViewModelProtocol?
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        if let song = self.viewModel?.songList[indexPath.row] {
            cell.nameLabel.text = song.name
        }
        
        return cell
    }
}

extension PlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
