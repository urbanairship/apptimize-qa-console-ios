//
//  ViewController.swift
//  QAConsoleIntegration
//
//  Copyright © 2021 Urban Airship Inc., d/b/a Airship.
//

import UIKit
import Apptimize

#if DEBUG
import ApptimizeQAConsole
#endif

// MARK: - TableView Data Source Model
fileprivate class TableViewDataModel
{
    public var title: String
    public var detail: String
    
    public init(title: String, detail: String)
    {
        self.title = title
        self.detail = detail
    }
}

// MARK: - TableViewController
class RootViewController: UITableViewController {
    private var enrolledTests: [TableViewDataModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.ApptimizeTestsProcessed, object: self, queue: nil) { _ in
            self.refresh()
        }

        refresh()
    }
    
    @objc func refresh()
    {
        guard let testInfo = Apptimize.testInfo() else {
            self.enrolledTests = []
            return
        }
        
        self.enrolledTests = testInfo.values.map({ test in
            TableViewDataModel(title: test.testName(), detail: "\(test.enrolledVariantName()) (\(test.enrolledVariantID()))")
        }).sorted(by: { l, r in l.title.lowercased() < r.title.lowercased() })
        
        self.tableView.reloadData()
    }
}

// MARK: - Table View Datasource
extension RootViewController
{
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return enrolledTests.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Enrolled Tests"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let data = enrolledTests[indexPath.row]
        
        cell.textLabel?.text = data.title
        cell.detailTextLabel?.text = data.detail

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
