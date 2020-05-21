//
//  TextList1View.swift
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

final class TextList1View: DisplayView {
    
    @IBOutlet private weak var textList1TableView: UITableView!
    
    private var textList1Items: [TextList1Template.Item]?
    private var badgeNumber: Bool?
    private var toggleStyle: DisplayCommonTemplate.Common.ToggleStyle?
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(TextList1Template.self, from: payloadData) else { return }
            
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
            
            textList1TableView.tableHeaderView = (displayItem.title.subtext == nil) ? nil : subTitleContainerView
            
            textList1Items = displayItem.listItems
            textList1TableView.reloadData()
            
            // Set content button
            contentButton.setTitle(displayItem.title.button?.text, for: .normal)
            contentButtonToken = displayItem.title.button?.token
            textList1TableView.tableFooterView = (displayItem.title.button == nil) ? nil : contentButtonContainerView
            
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
        let view = Bundle.main.loadNibNamed("TextList1View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        textList1TableView.register(UINib(nibName: "TextList1ViewCell", bundle: nil), forCellReuseIdentifier: "TextList1ViewCell")
    }
}

extension TextList1View: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textList1Items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let textList1ViewCell = tableView.dequeueReusableCell(withIdentifier: "TextList1ViewCell") as! TextList1ViewCell
        // swiftlint:enable force_cast
        if let badgeNumber = badgeNumber,
            badgeNumber == true {
            textList1ViewCell.configure(badgeNumber: String(indexPath.row + 1), item: textList1Items?[indexPath.row], toggleStyle: toggleStyle)
        } else {
            textList1ViewCell.configure(badgeNumber: nil, item: textList1Items?[indexPath.row], toggleStyle: toggleStyle)
        }
        textList1ViewCell.onToggleSelect = { [weak self] token in
            self?.onItemSelect?(token)
        }
        return textList1ViewCell
    }
}

extension TextList1View: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onItemSelect?(textList1Items?[indexPath.row].token)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        idleBar.lineViewIsHidden(hidden: Int(scrollView.contentOffset.y + scrollView.frame.size.height) >= Int(scrollView.contentSize.height))
    }
}

extension TextList1View: DisplayControllable {
    func visibleTokenList() -> [String]? {
        return textList1TableView.visibleCells.map { [weak self] (cell) -> String? in
            guard let indexPath = self?.textList1TableView.indexPath(for: cell),
                let item = self?.textList1Items?[indexPath.row] else {
                    return nil
            }
            return item.token
        }.compactMap { $0 }
    }
    
    func scroll(direction: DisplayControlPayload.Direction) -> Bool {
        guard let textList1Items = textList1Items else {
            return false
        }
        
        let visibleCellsCount = textList1TableView.visibleCells.count
        switch direction {
        case .previous:
            guard let topCell = textList1TableView.visibleCells.first,
                let topCellRowIndex = textList1TableView.indexPath(for: topCell)?.row else {
                    return false
            }
            let previousAnchorIndex = max(topCellRowIndex - visibleCellsCount, 0)
            textList1TableView.scrollToRow(at: IndexPath(row: previousAnchorIndex, section: 0), at: .top, animated: true)
            return true
        case .next:
            let lastCellRowIndex = textList1Items.count - 1
            guard let lastCell = textList1TableView.visibleCells.last,
                let lastVisibleCellRowIndex = textList1TableView.indexPath(for: lastCell)?.row,
                lastCellRowIndex > lastVisibleCellRowIndex else {
                    return false
            }
            let nextAnchorIndex = min(lastVisibleCellRowIndex + visibleCellsCount, lastCellRowIndex)
            textList1TableView.scrollToRow(at: IndexPath(row: nextAnchorIndex, section: 0), at: .bottom, animated: true)
            return true
        }
    }
}
