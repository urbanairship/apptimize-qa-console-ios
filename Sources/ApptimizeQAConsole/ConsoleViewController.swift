//
//  ConsoleViewController.swift
//  ApptimizeQAConsole
//
//  Copyright © 2021 Urban Airship Inc., d/b/a Airship.
//

import UIKit
import Apptimize

class ConsoleViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var noDataLbl: UILabel!
    @IBOutlet private weak var loadingActivityIndicator: UIActivityIndicatorView!
    
    private var experiments: [ExperimentInfo] = []
    private var filteredData: [ExperimentInfo] = []
    private var nameFilter: String?
    private var enrolledVariantIds: [Int] = []
    var onClosed: (() -> Void)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = closeButton()
        self.navigationItem.rightBarButtonItem = resetAllButton()
        
        let filterBar = UISearchBar()
        filterBar.delegate = self
        self.navigationItem.titleView = filterBar
        
        ConsoleTableViewCell.registerClass(in: self.tableView)
        self.tableView.tableFooterView = UIView()
        refreshList()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(onMetadataStatusChanged(notification:)), name: NSNotification.Name.ApptimizeMetadataStateChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTestProcessedNotification(notification:)), name: NSNotification.Name.ApptimizeTestsProcessed, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let dismissed = navigationController?.isBeingDismissed, dismissed {
            onClosed?()
        }
    }
    
    private func closeButton() -> UIBarButtonItem {
        return UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(onClose))
    }
    
    private func resetAllButton() -> UIBarButtonItem {
        return UIBarButtonItem(title: "Reset All", style: .plain, target: self, action: #selector(onResetAll))
    }
    
    @objc
    private func onClose() {
        self.navigationController?.dismiss(animated: true, completion: onClosed)
    }
    
    @objc
    private func onResetAll() {
        Apptimize.clearAllForcedVariants()
        refreshList()
    }
    
    @objc
    private func onMetadataStatusChanged(notification: Notification) {
        guard let metadataState = notification.userInfo?[ApptimizeMetadataStateFlagsKey] as? NSNumber else {
            return
        }
        
        let state = ApptimizeMetadataStateFlags(rawValue: metadataState.intValue)
        if state.contains(.refreshing) {
            self.loadingActivityIndicator.startAnimating()
        } else {
            refreshList()
        }
    }
    
    @objc
    private func onTestProcessedNotification(notification: Notification) {
        self.loadingActivityIndicator.startAnimating()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(refreshList), object: nil)
        self.perform(#selector(refreshList), with: nil, afterDelay: 0.3)
    }
    
    @objc
    private func refreshList() {
        self.experiments = processExperiments(source: Apptimize.getVariants() ?? [:])
        applyFilter()
        self.enrolledVariantIds = Apptimize.testInfo()?.values.map({ $0.enrolledVariantID().intValue }) ?? []
        self.noDataLbl.isHidden = !self.filteredData.isEmpty
        self.loadingActivityIndicator.stopAnimating()
        self.tableView.reloadData()
    }
    
    private func applyFilter() {
        guard let filter = nameFilter else {
            filteredData = experiments
            return
        }
        if (filter.isEmpty) {
            filteredData = experiments
        } else {
            filteredData = experiments.filter( { $0.name.lowercased().contains(filter.lowercased()) } )
        }
    }
    
    private func processExperiments(source: [String: [String: Any]]) -> [ExperimentInfo] {
        var experimentIdToNames = [Int: String]()
        
        return source.values
            .reduce(into: [Int: [VariantInfo]]()) { partialResult, item in
                if
                    let experimentName = item["experimentName"] as? String,
                    let experimentId = item["experimentID"] as? Int,
                    let variant = VariantInfo(source: item) {
                    experimentIdToNames[experimentId] = experimentName
                    if !partialResult.keys.contains(experimentId) {
                        partialResult[experimentId] = []
                    }
                    partialResult[experimentId]?.append(variant)
                }
            }
            .sorted(by: { $0.key > $1.key }) // sort by creation order
            .compactMap { experimentId, variants in
                guard let name = experimentIdToNames[experimentId] else { return nil }
                return ExperimentInfo(id: experimentId, name: name, variants: variants.sorted(by: { $0.id < $1.id }))
            }
    }
}

// MARK: - Table View Datasource
extension ConsoleViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.filteredData.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredData[section].variants.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ConsoleTableViewCell.dequeue(from: tableView, for: indexPath)
        let variant = filteredData[indexPath.section].variants[indexPath.row]
        cell.setVariant(variant: variant, isSelected: self.enrolledVariantIds.contains(variant.id))
        return cell
    }
}

// MARK: - Table View Delegate
extension ConsoleViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel(frame: CGRect(x: 20, y: 0, width: 0, height: 40))
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.textColor = tableView.tintColor
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.text = filteredData[section].name

        let holder = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        holder.backgroundColor = .white
        holder.addSubview(label)

        return holder
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        toggleSelection(for: indexPath)
    }
    
    private func toggleSelection(for indexPath: IndexPath) {
        let variants = self.filteredData[indexPath.section].variants
        let selectedVarintId = variants[indexPath.row].id
        
        if (enrolledVariantIds.contains(where: { $0 == selectedVarintId })) {
            return
        }
        
        enrolledVariantIds.removeAll { enrolledId in
            variants.contains(where: { $0.id == enrolledId })
        }
        
        enrolledVariantIds.append(selectedVarintId)
        
        Apptimize.clearAllForcedVariants()
        enrolledVariantIds.forEach(Apptimize.forceVariant)
    }
}

// MARK: - Filtering
extension ConsoleViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        nameFilter = searchText
        applyFilter()
        tableView.reloadData()
    }
}

internal struct VariantInfo {
    let id : Int
    let name : String
    
    init?(source: [String: Any]) {
        if
            let variantName = source["variantName"] as? String,
            let variantId = source["variantID"] as? Int {
            self.id = variantId
            self.name = variantName
        } else {
            return nil
        }
    }
}

private struct ExperimentInfo {
    let id : Int
    let name : String
    let variants: [VariantInfo]
}
