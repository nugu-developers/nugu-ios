//
//  DisplayListView.swift
//  SampleApp
//
//  Created by jin kim on 14/08/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit

import NuguAgents

final class DisplayListView: DisplayView {

    @IBOutlet private weak var tableView: UITableView!
    
    override var displayPayload: String? {
        didSet {
            guard let payloadData = displayPayload?.data(using: .utf8),
                let displayItem = try? JSONDecoder().decode(DisplayListTemplate.self, from: payloadData) else { return }
            
            titleLabel.text = displayItem.title.text.text
            titleLabel.textColor = UIColor.textColor(rgbHexString: displayItem.title.text.color)
            backgroundColor = UIColor.backgroundColor(rgbHexString: displayItem.background?.color)
            if let logoUrl = displayItem.title.logo.sources.first?.url {
                logoImageView.loadImage(from: logoUrl)
                logoImageView.isHidden = false
            } else {
                logoImageView.isHidden = true
            }
            
            templateListItems = displayItem.listItems
            tableView.reloadData()
        }
    }
    
    private var templateListItems: [DisplayListTemplate.Item]?

    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("DisplayListView", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        addBorderToTitleContainerView()
        tableView.backgroundColor = UIColor(named: "BackgroundColor")
        tableView.register(UINib(nibName: "DisplayListViewCell", bundle: nil), forCellReuseIdentifier: "DisplayListViewCell")
    }
}

extension DisplayListView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return templateListItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let displayListViewCell = tableView.dequeueReusableCell(withIdentifier: "DisplayListViewCell") as! DisplayListViewCell
        // swiftlint:enable force_cast
        displayListViewCell.configure(index: String(indexPath.row + 1), item: templateListItems?[indexPath.row])
        return displayListViewCell
    }
}

extension DisplayListView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onItemSelect?(templateListItems?[indexPath.row].token)
    }
}

extension DisplayListView: DisplayControllable {
    func visibleTokenList() -> [String]? {
        var visibleTokenList: [String]?
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.main.async { [weak self] in
            visibleTokenList = self?.tableView.visibleCells.map { (cell) -> String? in
                guard let indexPath = self?.tableView.indexPath(for: cell),
                    let item = self?.templateListItems?[indexPath.row] else {
                        return nil
                }
                return item.token
            }.compactMap { $0 }
            semaphore.signal()
        }
        semaphore.wait()
        return visibleTokenList
    }
    
    func scroll(direction: DisplayControlPayload.Direction) -> Bool {
        var scrollResult = false
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let templateListItems = templateListItems else {
            return scrollResult
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let visibleCellsCount = self.tableView.visibleCells.count
            switch direction {
            case .previous:
                guard let topCell = self.tableView.visibleCells.first,
                    let topCellRowIndex = self.tableView.indexPath(for: topCell)?.row else {
                        scrollResult = false
                        semaphore.signal()
                        return
                }
                let previousAnchorIndex = max(topCellRowIndex - visibleCellsCount, 0)
                self.tableView.scrollToRow(at: IndexPath(row: previousAnchorIndex, section: 0), at: .top, animated: true)
                scrollResult = true
                semaphore.signal()
            case .next:
                let lastCellRowIndex = templateListItems.count - 1
                guard let lastCell = self.tableView.visibleCells.last,
                    let lastVisibleCellRowIndex = self.tableView.indexPath(for: lastCell)?.row,
                    lastCellRowIndex > lastVisibleCellRowIndex else {
                        scrollResult = false
                        semaphore.signal()
                        return
                }
                let nextAnchorIndex = min(lastVisibleCellRowIndex + visibleCellsCount, lastCellRowIndex)
                self.tableView.scrollToRow(at: IndexPath(row: nextAnchorIndex, section: 0), at: .bottom, animated: true)
                scrollResult = true
                semaphore.signal()
            }
        }
        semaphore.wait()
        return scrollResult
    }
}
