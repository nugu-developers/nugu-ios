//
//  ImageList2View.swift
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

final class ImageList2View: DisplayView {
    
    @IBOutlet private weak var imageList2TableView: UITableView!
    
    private var imageList2Items: [ImageList2Template.Item]?
    private var badgeNumber: Bool?
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(ImageList2Template.self, from: payloadData) else { return }
            
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
            
            imageList2TableView.tableHeaderView = (displayItem.title.subtext == nil) ? nil : subTitleContainerView
            
            imageList2Items = displayItem.listItems
            imageList2TableView.reloadData()
            
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
            imageList2TableView.tableFooterView = (displayItem.title.button == nil) ? nil : contentButtonContainerView
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
            
            badgeNumber = displayItem.badgeNumber
            
            imageList2TableView.contentInset.bottom = 60
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("ImageList2View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        imageList2TableView.register(UINib(nibName: "ImageList2ViewCell", bundle: nil), forCellReuseIdentifier: "ImageList2ViewCell")
    }
}

extension ImageList2View: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageList2Items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let imageList2TableViewCell = tableView.dequeueReusableCell(withIdentifier: "ImageList2ViewCell") as! ImageList2ViewCell
        // swiftlint:enable force_cast
        if let badgeNumber = badgeNumber,
            badgeNumber == true {
            imageList2TableViewCell.configure(badgeNumber: String(indexPath.row + 1), item: imageList2Items?[indexPath.row])
        } else {
            imageList2TableViewCell.configure(badgeNumber: nil, item: imageList2Items?[indexPath.row])
        }
        return imageList2TableViewCell
    }
}

extension ImageList2View: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch imageList2Items?[indexPath.row].eventType {
        case .elementSelected:
            onItemSelect?(DisplayItemEventType.elementSelected(token: imageList2Items?[indexPath.row].token, postback: nil))
        case .textInput:
            onItemSelect?(DisplayItemEventType.textInput(textInput: imageList2Items?[indexPath.row].textInput))
        default:
            break
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        idleBar.lineViewIsHidden(hidden: Int(scrollView.contentOffset.y + scrollView.frame.size.height) >= Int(scrollView.contentSize.height))
    }
}

extension ImageList2View: DisplayControllable {
    func visibleTokenList() -> [String]? {
        return imageList2TableView.visibleCells.map { [weak self] (cell) -> String? in
            guard let indexPath = self?.imageList2TableView.indexPath(for: cell),
                let item = self?.imageList2Items?[indexPath.row] else {
                    return nil
            }
            return item.token
        }.compactMap { $0 }
    }
    
    func scroll(direction: DisplayControlPayload.Direction) -> Bool {
        guard let imageList2Items = imageList2Items else {
            return false
        }
        
        let visibleCellsCount = imageList2TableView.visibleCells.count
        switch direction {
        case .previous:
            guard let topCell = imageList2TableView.visibleCells.first,
                let topCellRowIndex = imageList2TableView.indexPath(for: topCell)?.row else {
                    return false
            }
            let previousAnchorIndex = max(topCellRowIndex - visibleCellsCount, 0)
            imageList2TableView.scrollToRow(at: IndexPath(row: previousAnchorIndex, section: 0), at: .top, animated: true)
            return true
        case .next:
            let lastCellRowIndex = imageList2Items.count - 1
            guard let lastCell = imageList2TableView.visibleCells.last,
                let lastVisibleCellRowIndex = imageList2TableView.indexPath(for: lastCell)?.row,
                lastCellRowIndex > lastVisibleCellRowIndex else {
                    return false
            }
            let nextAnchorIndex = min(lastVisibleCellRowIndex + visibleCellsCount, lastCellRowIndex)
            imageList2TableView.scrollToRow(at: IndexPath(row: nextAnchorIndex, section: 0), at: .bottom, animated: true)
            return true
        }
    }
}
