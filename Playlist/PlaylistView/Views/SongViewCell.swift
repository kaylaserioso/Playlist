import UIKit

class SongViewCell: UITableViewCell {
    static let reuseIdentifier: String = "SongViewCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    @IBAction func didTapActionButton(_ sender: Any) {
        
    }
}
