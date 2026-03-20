import UIKit

class MainTableViewController: UITableViewController {
    let items = ["标签演示", "AMPopupView 演示"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "AMFlamingo Demo"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            let vc = TagsController()
            self.navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = AMPopupDemoController()
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
} 
