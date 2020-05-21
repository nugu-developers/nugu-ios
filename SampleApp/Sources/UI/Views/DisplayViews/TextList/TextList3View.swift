//
//  TextList3View.swift
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

final class TextList3View: DisplayView {
    
    @IBOutlet private weak var textList3TableView: UITableView!
    
    @IBOutlet private weak var contentFooterView: UIView!
    
    @IBOutlet private weak var captionContainerView: UIView!
    @IBOutlet private weak var captionLabel: UILabel!
    
    private var textList3Items: [TextList3Template.Item]?
    private var badgeNumber: Bool?
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(TextList3Template.self, from: payloadData) else { return }
            
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
            
            textList3TableView.tableHeaderView = (displayItem.title.subtext == nil) ? nil : subTitleContainerView
            
            textList3Items = displayItem.listItems
            textList3TableView.reloadData()
            
            // Set caption
            captionContainerView.isHidden = (displayItem.caption == nil)
            captionLabel.setDisplayText(displayText: displayItem.caption)
            
            // Set content button
            if let buttonItem = displayItem.title.button {
                contentButtonContainerView.isHidden = false
                contentButton.setTitle(buttonItem.text, for: .normal)
                contentButtonToken = buttonItem.token
            } else {
                contentButtonContainerView.isHidden = true
            }
            
            // Set footer view
            let captionContainerViewHeight = captionContainerView.isHidden ? 0 : captionContainerView.frame.height
            let contentButtonContainerViewHeight = contentButtonContainerView.isHidden ? 0 : contentButtonContainerView.frame.height
            contentFooterView.frame = CGRect(origin: .zero, size: CGSize(width: contentFooterView.bounds.width, height: captionContainerViewHeight + contentButtonContainerViewHeight))
            textList3TableView.tableFooterView = contentFooterView
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
            
            badgeNumber = displayItem.badgeNumber
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("TextList3View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        textList3TableView.register(UINib(nibName: "TextList3ViewCell", bundle: nil), forCellReuseIdentifier: "TextList3ViewCell")
    }
}

extension TextList3View: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textList3Items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let textList3ViewCell = tableView.dequeueReusableCell(withIdentifier: "TextList3ViewCell") as! TextList3ViewCell
        // swiftlint:enable force_cast
        if let badgeNumber = badgeNumber,
            badgeNumber == true {
            textList3ViewCell.configure(badgeNumber: String(indexPath.row + 1), item: textList3Items?[indexPath.row])
        } else {
            textList3ViewCell.configure(badgeNumber: nil, item: textList3Items?[indexPath.row])
        }
        return textList3ViewCell
    }
}

extension TextList3View: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onItemSelect?(textList3Items?[indexPath.row].token)
    }
}

extension TextList3View: DisplayControllable {
    func visibleTokenList() -> [String]? {
        return textList3TableView.visibleCells.map { [weak self] (cell) -> String? in
            guard let indexPath = self?.textList3TableView.indexPath(for: cell),
                let item = self?.textList3Items?[indexPath.row] else {
                    return nil
            }
            return item.token
        }.compactMap { $0 }
    }
    
    func scroll(direction: DisplayControlPayload.Direction) -> Bool {
        guard let textList3Items = textList3Items else {
            return false
        }
        
        let visibleCellsCount = textList3TableView.visibleCells.count
        switch direction {
        case .previous:
            guard let topCell = textList3TableView.visibleCells.first,
                let topCellRowIndex = textList3TableView.indexPath(for: topCell)?.row else {
                    return false
            }
            let previousAnchorIndex = max(topCellRowIndex - visibleCellsCount, 0)
            textList3TableView.scrollToRow(at: IndexPath(row: previousAnchorIndex, section: 0), at: .top, animated: true)
            return true
        case .next:
            let lastCellRowIndex = textList3Items.count - 1
            guard let lastCell = textList3TableView.visibleCells.last,
                let lastVisibleCellRowIndex = textList3TableView.indexPath(for: lastCell)?.row,
                lastCellRowIndex > lastVisibleCellRowIndex else {
                    return false
            }
            let nextAnchorIndex = min(lastVisibleCellRowIndex + visibleCellsCount, lastCellRowIndex)
            textList3TableView.scrollToRow(at: IndexPath(row: nextAnchorIndex, section: 0), at: .bottom, animated: true)
            return true
        }
    }
}
