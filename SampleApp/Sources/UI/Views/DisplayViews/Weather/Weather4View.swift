//
//  Weather4View.swift
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

final class Weather4View: DisplayView {
    
    @IBOutlet private weak var weather4TableView: UITableView!
    
    private var weather4items: [Weather4Template.Content.Item]?
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(Weather4Template.self, from: payloadData) else { return }
            
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
            
            weather4TableView.tableHeaderView = (displayItem.title.subtext == nil) ? nil : subTitleContainerView
            
            weather4items = displayItem.content.listItems
            weather4TableView.reloadData()
            
            // Set content button
            contentButton.setTitle(displayItem.title.button?.text, for: .normal)
                        
            switch displayItem.title.button?.eventType {
            case .elementSelected:
                contentButtonEventType = .elementSelected(token: displayItem.title.button?.token, postback: displayItem.title.button?.postback)
            case .textInput:
                contentButtonEventType = .textInput(textInput: displayItem.title.button?.textInput)
            default:
                break
            }
            weather4TableView.tableFooterView = (displayItem.title.button == nil) ? nil : contentButtonContainerView
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
            
            weather4TableView.contentInset.bottom = 60
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("Weather4View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        weather4TableView.register(UINib(nibName: "Weather4ViewCell", bundle: nil), forCellReuseIdentifier: "Weather4ViewCell")
    }
}

extension Weather4View: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weather4items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let weather4TableViewCell = tableView.dequeueReusableCell(withIdentifier: "Weather4ViewCell") as! Weather4ViewCell
        // swiftlint:enable force_cast
        weather4TableViewCell.configure(item: weather4items?[indexPath.row])
        return weather4TableViewCell
    }
}

extension Weather4View: UITableViewDelegate {    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        idleBar.lineViewIsHidden(hidden: Int(scrollView.contentOffset.y + scrollView.frame.size.height) >= Int(scrollView.contentSize.height))
    }
}

extension Weather4View: DisplayControllable {
    func visibleTokenList() -> [String]? {
        return nil
    }
    
    func scroll(direction: DisplayControlPayload.Direction) -> Bool {
        guard let weather4items = weather4items else {
            return false
        }
        
        let visibleCellsCount = weather4TableView.visibleCells.count
        switch direction {
        case .previous:
            guard let topCell = weather4TableView.visibleCells.first,
                let topCellRowIndex = weather4TableView.indexPath(for: topCell)?.row else {
                    return false
            }
            let previousAnchorIndex = max(topCellRowIndex - visibleCellsCount, 0)
            weather4TableView.scrollToRow(at: IndexPath(row: previousAnchorIndex, section: 0), at: .top, animated: true)
            return true
        case .next:
            let lastCellRowIndex = weather4items.count - 1
            guard let lastCell = weather4TableView.visibleCells.last,
                let lastVisibleCellRowIndex = weather4TableView.indexPath(for: lastCell)?.row,
                lastCellRowIndex > lastVisibleCellRowIndex else {
                    return false
            }
            let nextAnchorIndex = min(lastVisibleCellRowIndex + visibleCellsCount, lastCellRowIndex)
            weather4TableView.scrollToRow(at: IndexPath(row: nextAnchorIndex, section: 0), at: .bottom, animated: true)
            return true
        }
    }
}
