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
    private var knownWinnerNames: [Int: String] = [:]
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
        
        
        addFooterView()
        
        refreshList()
    }
    
    fileprivate func addFooterView() {
        let font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)

        let footerView = UITextView()
        footerView.text = "Apptimize Version: \(Apptimize.libraryVersion())\nApptimize QA Console Version: \(ApptimizeQAConsole.version())"
        footerView.font = font
        footerView.textColor = .darkGray
        footerView.backgroundColor = .systemGray6
        footerView.isEditable = false
        footerView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        footerView.isScrollEnabled = false
        
        let width = self.tableView.bounds.size.width
        let size = footerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height))
        
        if footerView.frame.size.height != size.height {
            footerView.frame.size.height = size.height
        }
        
        self.tableView.tableFooterView = footerView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(onMetadataStatusChanged(notification:)), name: NSNotification.Name.ApptimizeMetadataStateChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onTestProcessedNotification(notification:)), name: NSNotification.Name.ApptimizeTestsProcessed, object: nil)
        NotificationCenter.default.post(name: NSNotification.Name.ApptimizeQAConsoleWillAppear, object: ApptimizeQAConsole.shared)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.post(name: NSNotification.Name.ApptimizeQAConsoleWillDisappear, object: ApptimizeQAConsole.shared)
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
        let variants = Apptimize.getVariants() ?? [:]
        let winnerInfo = Array((Apptimize.instantUpdateAndWinnerInfo() ?? [:]).values).filter({ !$0.isInstantUpdate() })
        let testInfo = Apptimize.testInfo() ?? [:]
                
        self.experiments = processExperiments(source: variants, testInfo: Array(testInfo.values), winnerInfo: winnerInfo)
        
        applyFilter()
        
        self.enrolledVariantIds = testInfo.values.map({ $0.enrolledVariantID().intValue })
        self.enrolledVariantIds.append(contentsOf: winnerInfo.map({ $0.winningVariantID().intValue }))
        
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
    
    private func processExperiments(source: [String: [String: Any]], testInfo: [ApptimizeTestInfo], winnerInfo: [ApptimizeInstantUpdateOrWinnerInfo]) -> [ExperimentInfo] {
        var experimentIdToNames = [Int: String]()
        
        return source.values
            .reduce(into: [Int: [VariantInfo]]()) { partialResult, item in
                if
                    let experimentName = item["experimentName"] as? String,
                    let experimentId = item["experimentID"] as? Int,
                    let variant = VariantInfo(source: item) {
                        if experimentName.isEmpty {
                            if let winner = winnerInfo.first(where: { $0.winningExperimentID().intValue == experimentId }) {
                                experimentIdToNames[experimentId] = "Winner for: \(winner.winningExperimentName())"
                                knownWinnerNames[experimentId] = winner.winningExperimentName()
                            } else if let winnerName = knownWinnerNames[experimentId] {
                                experimentIdToNames[experimentId] = "Winner for: \(winnerName)"
                            } else {
                                experimentIdToNames[experimentId] = "Experiment Id: \(experimentId)"
                            }
                        } else {
                            experimentIdToNames[experimentId] = experimentName
                        }
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
        let selectedVariantId = variants[indexPath.row].id
        
        if (enrolledVariantIds.contains(where: { $0 == selectedVariantId })) {
            enrolledVariantIds.removeAll(where: { $0 == selectedVariantId })
        } else {
            enrolledVariantIds.removeAll(where: { variantId in variants.contains(where: { $0.id == variantId }) })
            enrolledVariantIds.append(selectedVariantId)
        }

        Apptimize.clearAllForcedVariants()

        enrolledVariantIds.forEach({ Apptimize.forceVariant($0) })

        self.refreshList()
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

internal struct ExperimentInfo {
    let id : Int
    let name : String
    let variants: [VariantInfo]
}
