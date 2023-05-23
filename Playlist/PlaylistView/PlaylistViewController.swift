import UIKit

class PlaylistViewController: UIViewController {
    
    var viewModel: PlaylistViewModelProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel?.getSongList()
    }


}

