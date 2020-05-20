//
//  TextList4View.swift
//  SampleApp
//
//  Created by jin kim on 2019/11/06.
//  Copyright © 2019 SK Telecom Co., Ltd. All rights reserved.
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
import NuguUIKit

final class TextList4View: DisplayView {
    
    @IBOutlet private weak var textList4TableView: UITableView!
    
    private var textList4Items: [TextList4Template.Item]?
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(TextList4Template.self, from: payloadData) else { return }
            
            // Set backgroundColor
            backgroundColor = UIColor.backgroundColor(rgbHexString: displayItem.background?.color)
                        
            // Set title
            titleView.setData(titleData: displayItem.title)
            
            // Set sub title
            if let subIconUrl = displayItem.title.subicon?.sources.first?.url {
                subIconImageView.loadImage(from: subIconUrl)
                subIconImageView.isHidden = false
            } else {
                subIconImageView.isHidden = true
            }
            subTitleLabel.setDisplayText(displayText: displayItem.title.subtext)
            subTitleContainerView.isHidden = (displayItem.title.subtext == nil)
            
            textList4TableView.tableHeaderView = (displayItem.title.subtext == nil) ? nil : subTitleContainerView
            
            textList4Items = displayItem.listItems
            textList4TableView.reloadData()
            
            // Set content button
            contentButton.setTitle(displayItem.title.button?.text, for: .normal)
            contentButtonToken = displayItem.title.button?.token
            textList4TableView.tableFooterView = (displayItem.title.button == nil) ? nil : contentButtonContainerView
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("TextList4View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        textList4TableView.register(UINib(nibName: "TextList4ViewCell", bundle: nil), forCellReuseIdentifier: "TextList4ViewCell")
    }
}

extension TextList4View: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textList4Items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let textList4ViewCell = tableView.dequeueReusableCell(withIdentifier: "TextList4ViewCell") as! TextList4ViewCell
        // swiftlint:enable force_cast
        textList4ViewCell.configure(item: textList4Items?[indexPath.row])
        textList4ViewCell.onButtonSelect = { [weak self] token in
            self?.onItemSelect?(token)
        }
        return textList4ViewCell
    }
}

extension TextList4View: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onItemSelect?(textList4Items?[indexPath.row].token)
    }
}

extension TextList4View: DisplayControllable {
    func visibleTokenList() -> [String]? {
        return textList4TableView.visibleCells.map { [weak self] (cell) -> String? in
            guard let indexPath = self?.textList4TableView.indexPath(for: cell),
                let item = self?.textList4Items?[indexPath.row] else {
                    return nil
            }
            return item.token
        }.compactMap { $0 }
    }
    
    func scroll(direction: DisplayControlPayload.Direction) -> Bool {
        guard let textList4Items = textList4Items else {
            return false
        }
        
        let visibleCellsCount = textList4TableView.visibleCells.count
        switch direction {
        case .previous:
            guard let topCell = textList4TableView.visibleCells.first,
                let topCellRowIndex = textList4TableView.indexPath(for: topCell)?.row else {
                    return false
            }
            let previousAnchorIndex = max(topCellRowIndex - visibleCellsCount, 0)
            textList4TableView.scrollToRow(at: IndexPath(row: previousAnchorIndex, section: 0), at: .top, animated: true)
            return true
        case .next:
            let lastCellRowIndex = textList4Items.count - 1
            guard let lastCell = textList4TableView.visibleCells.last,
                let lastVisibleCellRowIndex = textList4TableView.indexPath(for: lastCell)?.row,
                lastCellRowIndex > lastVisibleCellRowIndex else {
                    return false
            }
            let nextAnchorIndex = min(lastVisibleCellRowIndex + visibleCellsCount, lastCellRowIndex)
            textList4TableView.scrollToRow(at: IndexPath(row: nextAnchorIndex, section: 0), at: .bottom, animated: true)
            return true
        }
    }
}
