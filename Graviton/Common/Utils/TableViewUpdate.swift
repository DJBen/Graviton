//
//  TableViewUpdate.swift
//  Graviton
//
//  Created by Sihao Lu on 7/14/17.
//  Copyright © 2017 Ben Lu. All rights reserved.
//

import UIKit

struct TableViewUpdate {
    let section: Int
    let initialRows: IndexSet
    let updatedRows: IndexSet
    let finalRows: IndexSet

    init(section: Int, initialRows: IndexSet, updatedRows: IndexSet, finalRows: IndexSet) {
        self.section = section
        self.initialRows = initialRows
        self.updatedRows = updatedRows
        self.finalRows = finalRows
    }
}

extension UITableView {
    func commitUpdate(_ update: TableViewUpdate, with animation: UITableViewRowAnimation) {
        let added = update.finalRows.subtracting(update.initialRows)
        let removed = update.initialRows.subtracting(update.finalRows)
        let realUpdated = update.updatedRows.subtracting(added).subtracting(removed)
        if added.isEmpty == false {
            insertRows(at: added.map { IndexPath(row: $0, section: update.section) }, with: animation)
        }
        if removed.isEmpty == false {
            deleteRows(at: removed.map { IndexPath(row: $0, section: update.section) }, with: animation)
        }
        if realUpdated.isEmpty == false {
            reloadRows(at: realUpdated.map { IndexPath(row: $0, section: update.section) }, with: animation)
        }
    }
}
