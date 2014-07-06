//
//  ArtistsViewController.swift
//  SubsonicSwift
//
//  Created by Matt Thomas on 6/20/14.
//  Copyright (c) 2014 Matt Thomas. All rights reserved.
//

import Cocoa

class ArtistsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet var tableView: NSTableView

    var artists: Artist[] = Artist[]() {
    didSet {
        self.tableView.reloadData()
    }
    }

    func numberOfRowsInTableView(aTableView: NSTableView!) -> Int {
        return artists.count
    }

    func tableView(tableView: NSTableView, viewForTableColumn: NSTableColumn, row: Int) -> NSView {

        let artist = artists[row]

        let tableCellView = tableView.makeViewWithIdentifier("ArtistCell", owner: nil) as NSTableCellView
        tableCellView.textField.stringValue = artist.name
        return tableCellView
    }

}
