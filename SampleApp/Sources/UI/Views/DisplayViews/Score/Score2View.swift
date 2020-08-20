//
//  Score2View.swift
//  SampleApp
//
//  Created by 김진님/AI Assistant개발 Cell on 2020/05/17.
//  Copyright © 2020 SK Telecom Co., Ltd. All rights reserved.
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

final class Score2View: DisplayView {
    
    @IBOutlet private weak var score2TableView: UITableView!
    
    private var scoreItems: [Score2Template.Item]?
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(Score2Template.self, from: payloadData) else { return }
            
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
            
            score2TableView.tableHeaderView = (displayItem.title.subtext == nil) ? nil : subTitleContainerView
            
            scoreItems = displayItem.listItems
            score2TableView.reloadData()
            
            contentButton.setTitle(displayItem.title.button?.text, for: .normal)
            
            switch displayItem.title.button?.eventType {
            case .elementSelected:
                contentButtonEventType = .elementSelected(token: displayItem.title.button?.token, postback: displayItem.title.button?.postback)
            case .textInput:
                contentButtonEventType = .textInput(textInput: displayItem.title.button?.textInput)
            default:
                break
            }

            score2TableView.tableFooterView = (displayItem.title.button == nil) ? nil : contentButtonContainerView
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
            
            score2TableView.contentInset.bottom = 60
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("Score2View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        score2TableView.register(UINib(nibName: "Score2ViewCell", bundle: nil), forCellReuseIdentifier: "Score2ViewCell")
    }
}

extension Score2View: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scoreItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let score2ViewCell = tableView.dequeueReusableCell(withIdentifier: "Score2ViewCell") as! Score2ViewCell
        // swiftlint:enable force_cast
        score2ViewCell.configure(item: scoreItems?[indexPath.row])
        return score2ViewCell
    }
}

extension Score2View: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch scoreItems?[indexPath.row].eventType {
        case .elementSelected:
            onItemSelect?(DisplayItemEventType.elementSelected(token: scoreItems?[indexPath.row].token, postback: nil))
        case .textInput:
            onItemSelect?(DisplayItemEventType.textInput(textInput: scoreItems?[indexPath.row].textInput))
        default:
            break
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        idleBar.lineViewIsHidden(hidden: Int(scrollView.contentOffset.y + scrollView.frame.size.height) >= Int(scrollView.contentSize.height))
    }
}

extension Score2View: DisplayControllable {
    func visibleTokenList() -> [String]? {
        return score2TableView.visibleCells.map { [weak self] (cell) -> String? in
            guard let indexPath = self?.score2TableView.indexPath(for: cell),
                let item = self?.scoreItems?[indexPath.row] else {
                    return nil
            }
            return item.token
        }.compactMap { $0 }
    }
    
    func scroll(direction: DisplayControlPayload.Direction) -> Bool {
        guard let templateListItems = scoreItems else {
            return false
        }
        
        let visibleCellsCount = score2TableView.visibleCells.count
        switch direction {
        case .previous:
            guard let topCell = score2TableView.visibleCells.first,
                let topCellRowIndex = score2TableView.indexPath(for: topCell)?.row else {
                    return false
            }
            let previousAnchorIndex = max(topCellRowIndex - visibleCellsCount, 0)
            score2TableView.scrollToRow(at: IndexPath(row: previousAnchorIndex, section: 0), at: .top, animated: true)
            return true
        case .next:
            let lastCellRowIndex = templateListItems.count - 1
            guard let lastCell = score2TableView.visibleCells.last,
                let lastVisibleCellRowIndex = score2TableView.indexPath(for: lastCell)?.row,
                lastCellRowIndex > lastVisibleCellRowIndex else {
                    return false
            }
            let nextAnchorIndex = min(lastVisibleCellRowIndex + visibleCellsCount, lastCellRowIndex)
            score2TableView.scrollToRow(at: IndexPath(row: nextAnchorIndex, section: 0), at: .bottom, animated: true)
            return true
        }
    }
}
