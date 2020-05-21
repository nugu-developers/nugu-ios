//
//  TextList2View.swift
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

final class TextList2View: DisplayView {
    
    @IBOutlet private weak var textList2TableView: UITableView!
    
    private var textList2Items: [TextList2Template.Item]?
    private var badgeNumber: Bool?
    private var toggleStyle: DisplayCommonTemplate.Common.ToggleStyle?
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(TextList2Template.self, from: payloadData) else { return }
            
            // Set backgroundColor
            backgroundColor = UIColor.backgroundColor(rgbHexString: displayItem.background?.color)
                        
            // Set title
            titleView.setData(titleData: displayItem.title)
            titleView.onCloseButtonClick = { [weak self] in
                self?.onCloseButtonClick?()
            }
            
            // Set sub title
            if let subIconUrl = displayItem.title.subicon?.sources.first?.url {
                subIconImageView.loadImage(from: subIconUrl)
                subIconImageView.isHidden = false
            } else {
                subIconImageView.isHidden = true
            }
            subTitleLabel.setDisplayText(displayText: displayItem.title.subtext)
            subTitleContainerView.isHidden = (displayItem.title.subtext == nil)
            
            textList2TableView.tableHeaderView = (displayItem.title.subtext == nil) ? nil : subTitleContainerView
            
            textList2Items = displayItem.listItems
            textList2TableView.reloadData()
            
            // Set content button
            contentButton.setTitle(displayItem.title.button?.text, for: .normal)
            contentButtonToken = displayItem.title.button?.token
            textList2TableView.tableFooterView = (displayItem.title.button == nil) ? nil : contentButtonContainerView
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
            
            badgeNumber = displayItem.badgeNumber
            toggleStyle = displayItem.toggleStyle
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("TextList2View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        textList2TableView.register(UINib(nibName: "TextList2ViewCell", bundle: nil), forCellReuseIdentifier: "TextList2ViewCell")
    }
}

extension TextList2View: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textList2Items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let textList2ViewCell = tableView.dequeueReusableCell(withIdentifier: "TextList2ViewCell") as! TextList2ViewCell
        // swiftlint:enable force_cast
        if let badgeNumber = badgeNumber,
            badgeNumber == true {
            textList2ViewCell.configure(badgeNumber: String(indexPath.row + 1), item: textList2Items?[indexPath.row], toggleStyle: toggleStyle)
        } else {
            textList2ViewCell.configure(badgeNumber: nil, item: textList2Items?[indexPath.row], toggleStyle: toggleStyle)
        }
        textList2ViewCell.onToggleSelect = { [weak self] token in
            self?.onItemSelect?(token)
        }
        return textList2ViewCell
    }
}

extension TextList2View: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onItemSelect?(textList2Items?[indexPath.row].token)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        idleBar.lineViewIsHidden(hidden: Int(scrollView.contentOffset.y + scrollView.frame.size.height) >= Int(scrollView.contentSize.height))
    }
}

extension TextList2View: DisplayControllable {
    func visibleTokenList() -> [String]? {
        return textList2TableView.visibleCells.map { [weak self] (cell) -> String? in
            guard let indexPath = self?.textList2TableView.indexPath(for: cell),
                let item = self?.textList2Items?[indexPath.row] else {
                    return nil
            }
            return item.token
        }.compactMap { $0 }
    }
    
    func scroll(direction: DisplayControlPayload.Direction) -> Bool {
        guard let textList2Items = textList2Items else {
            return false
        }
        
        let visibleCellsCount = textList2TableView.visibleCells.count
        switch direction {
        case .previous:
            guard let topCell = textList2TableView.visibleCells.first,
                let topCellRowIndex = textList2TableView.indexPath(for: topCell)?.row else {
                    return false
            }
            let previousAnchorIndex = max(topCellRowIndex - visibleCellsCount, 0)
            textList2TableView.scrollToRow(at: IndexPath(row: previousAnchorIndex, section: 0), at: .top, animated: true)
            return true
        case .next:
            let lastCellRowIndex = textList2Items.count - 1
            guard let lastCell = textList2TableView.visibleCells.last,
                let lastVisibleCellRowIndex = textList2TableView.indexPath(for: lastCell)?.row,
                lastCellRowIndex > lastVisibleCellRowIndex else {
                    return false
            }
            let nextAnchorIndex = min(lastVisibleCellRowIndex + visibleCellsCount, lastCellRowIndex)
            textList2TableView.scrollToRow(at: IndexPath(row: nextAnchorIndex, section: 0), at: .bottom, animated: true)
            return true
        }
    }
}
