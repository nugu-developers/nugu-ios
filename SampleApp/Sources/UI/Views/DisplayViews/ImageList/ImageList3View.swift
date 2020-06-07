//
//  ImageList3View.swift
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

final class ImageList3View: DisplayView {
    
    @IBOutlet private weak var imageList3TableView: UITableView!
    
    private var imageList3Items: [ImageList3Template.Item]?
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(ImageList3Template.self, from: payloadData) else { return }
            
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
            
            imageList3TableView.tableHeaderView = (displayItem.title.subtext == nil) ? nil : subTitleContainerView
            
            imageList3Items = displayItem.listItems
            imageList3TableView.reloadData()
            
            // Set content button
            contentButton.setTitle(displayItem.title.button?.text, for: .normal)
            contentButtonTokenAndPostback = (displayItem.title.button?.token, displayItem.title.button?.postback)
            imageList3TableView.tableFooterView = (displayItem.title.button == nil) ? nil : contentButtonContainerView
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
            
            imageList3TableView.contentInset.bottom = 60
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("ImageList3View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        imageList3TableView.register(UINib(nibName: "ImageList3ViewCell", bundle: nil), forCellReuseIdentifier: "ImageList3ViewCell")
    }
}

extension ImageList3View: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageList3Items?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let imageList3TableViewCell = tableView.dequeueReusableCell(withIdentifier: "ImageList3ViewCell") as! ImageList3ViewCell
        // swiftlint:enable force_cast
        imageList3TableViewCell.configure(item: imageList3Items?[indexPath.row])
        return imageList3TableViewCell
    }
}

extension ImageList3View: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onItemSelect?(imageList3Items?[indexPath.row].token, nil)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        idleBar.lineViewIsHidden(hidden: Int(scrollView.contentOffset.y + scrollView.frame.size.height) >= Int(scrollView.contentSize.height))
    }
}

extension ImageList3View: DisplayControllable {
    func visibleTokenList() -> [String]? {
        return imageList3TableView.visibleCells.map { [weak self] (cell) -> String? in
            guard let indexPath = self?.imageList3TableView.indexPath(for: cell),
                let item = self?.imageList3Items?[indexPath.row] else {
                    return nil
            }
            return item.token
        }.compactMap { $0 }
    }
    
    func scroll(direction: DisplayControlPayload.Direction) -> Bool {
        guard let imageList3Items = imageList3Items else {
            return false
        }
        
        let visibleCellsCount = imageList3TableView.visibleCells.count
        switch direction {
        case .previous:
            guard let topCell = imageList3TableView.visibleCells.first,
                let topCellRowIndex = imageList3TableView.indexPath(for: topCell)?.row else {
                    return false
            }
            let previousAnchorIndex = max(topCellRowIndex - visibleCellsCount, 0)
            imageList3TableView.scrollToRow(at: IndexPath(row: previousAnchorIndex, section: 0), at: .top, animated: true)
            return true
        case .next:
            let lastCellRowIndex = imageList3Items.count - 1
            guard let lastCell = imageList3TableView.visibleCells.last,
                let lastVisibleCellRowIndex = imageList3TableView.indexPath(for: lastCell)?.row,
                lastCellRowIndex > lastVisibleCellRowIndex else {
                    return false
            }
            let nextAnchorIndex = min(lastVisibleCellRowIndex + visibleCellsCount, lastCellRowIndex)
            imageList3TableView.scrollToRow(at: IndexPath(row: nextAnchorIndex, section: 0), at: .bottom, animated: true)
            return true
        }
    }
}
