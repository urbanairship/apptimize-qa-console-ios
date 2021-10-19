//
//  Helper.swift
//  ApptimizeQAConsole
//
//  Copyright © 2021 Urban Airship Inc., d/b/a Airship.
//

import Foundation
import UIKit

extension UIViewController {
    internal static func loadFromNib() -> Self {
        let name = String(describing: self)
        #if SWIFT_PACKAGE
        return self.init(nibName: name, bundle: Bundle.module)
        #else
        return self.init(nibName: name, bundle: Bundle(for: Self.self))
        #endif
    }
}

extension UITableViewCell {
    private static func identifier() -> String {
        return String(describing: self)
    }
    
    internal static func dequeue(from table: UITableView, for path: IndexPath) -> Self {
        return table.dequeueReusableCell(withIdentifier: identifier(), for: path) as! Self
    }
    
    internal static func registerNib(in table: UITableView) {
        #if SWIFT_PACKAGE
        table.register(UINib(nibName: String(describing: self), bundle: Bundle.module), forCellReuseIdentifier: identifier())
        #else
        table.register(UINib(nibName: String(describing: self), bundle: Bundle(for: Self.self)), forCellReuseIdentifier: identifier())
        #endif
    }
    
    internal static func registerClass(in table: UITableView) {
        table.register(Self.self, forCellReuseIdentifier: identifier())
    }
}
