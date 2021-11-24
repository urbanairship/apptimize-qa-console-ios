//
//  ConsoleTableViewCell.swift
//  ApptimizeQAConsole
//
//  Copyright © 2021 Urban Airship Inc., d/b/a Airship.
//

import UIKit

class ConsoleTableViewCell: UITableViewCell {
    
    private (set) var item: VariantInfo?
    
    func setVariant(variant: VariantInfo, isSelected: Bool) {
        self.item = variant
        self.reloadUi()
        self.accessoryType = isSelected ? .checkmark : .none
        self.selectionStyle = .none
    }
    
    private func reloadUi() {
        self.textLabel?.text = self.item?.name
    }
    
}
