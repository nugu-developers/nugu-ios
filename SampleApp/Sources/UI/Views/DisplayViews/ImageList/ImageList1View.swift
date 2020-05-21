//
//  ImageList1View.swift
//  SampleApp
//
//  Created by jin kim on 2019/12/06.
//  Copyright © 1019 SK Telecom Co., Ltd. All rights reserved.
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

final class ImageList1View: DisplayView {
    
    @IBOutlet private weak var imageList1TableView: UITableView!
    
    private var imageList1Items: [ImageList1Template.Item]?
    private var badgeNumber: Bool?
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(ImageList1Template.self, from: payloadData) else { return }
            
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
            
            imageList1TableView.tableHeaderView = (displayItem.title.subtext == nil) ? nil : subTitleContainerView
            
            imageList1Items = displayItem.listItems
            imageList1TableView.reloadData()
            
            // Set content button
            contentButton.setTitle(displayItem.title.button?.text, for: .normal)
            contentButtonToken = displayItem.title.button?.token
            imageList1TableView.tableFooterView = (displayItem.title.button == nil) ? nil : contentButtonContainerView
            
            // Set chips data (grammarGuide)
            idleBar.chipsData = displayItem.grammarGuide?.compactMap({ (grammarGuide) -> NuguChipsButton.NuguChipsButtonType in
                return .normal(text: grammarGuide)
            }) ?? []
            
            badgeNumber = displayItem.badgeNumber
        }
    }
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("ImageList1View", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        
        imageList1TableView.register(UINib(nibName: "ImageList1ViewCell", bundle: nil), forCellReuseIdentifier: "ImageList1ViewCell")
    }
}

extension ImageList1View: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let imageList1Items = imageList1Items else { return 0 }
        let isOdd = imageList1Items.count % 2 == 1 ? 1 : 0
        return imageList1Items.count / 2 + isOdd
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let imageList1TableViewCell = tableView.dequeueReusableCell(withIdentifier: "ImageList1ViewCell") as! ImageList1ViewCell
        // swiftlint:enable force_cast
        guard let imageList1Items = imageList1Items else {
            return UITableViewCell()
        }
        let badgeNumberString = badgeNumber == true ? String(indexPath.row*2+1) : nil
        let rightItem = indexPath.row*2+1 >= imageList1Items.count ? nil : imageList1Items[indexPath.row*2+1]
        imageList1TableViewCell.configure(badgeNumber: badgeNumberString, leftItem: imageList1Items[indexPath.row*2], rightItem: rightItem)
        imageList1TableViewCell.onItemSelect = { [weak self] selectedItemToken in
            self?.onItemSelect?(selectedItemToken)
        }
        return imageList1TableViewCell
    }
}

extension ImageList1View: DisplayControllable {
    func visibleTokenList() -> [String]? {
        return imageList1TableView.visibleCells.map { [weak self] (cell) -> String? in
            guard let indexPath = self?.imageList1TableView.indexPath(for: cell),
                let item = self?.imageList1Items?[indexPath.row] else {
                    return nil
            }
            return item.token
        }.compactMap { $0 }
    }
    
    func scroll(direction: DisplayControlPayload.Direction) -> Bool {
        guard let imageList1Items = imageList1Items else {
            return false
        }
        
        let visibleCellsCount = imageList1TableView.visibleCells.count
        switch direction {
        case .previous:
            guard let topCell = imageList1TableView.visibleCells.first,
                let topCellRowIndex = imageList1TableView.indexPath(for: topCell)?.row else {
                    return false
            }
            let previousAnchorIndex = max(topCellRowIndex - visibleCellsCount, 0)
            imageList1TableView.scrollToRow(at: IndexPath(row: previousAnchorIndex, section: 0), at: .top, animated: true)
            return true
        case .next:
            let lastCellRowIndex = imageList1Items.count - 1
            guard let lastCell = imageList1TableView.visibleCells.last,
                let lastVisibleCellRowIndex = imageList1TableView.indexPath(for: lastCell)?.row,
                lastCellRowIndex > lastVisibleCellRowIndex else {
                    return false
            }
            let nextAnchorIndex = min(lastVisibleCellRowIndex + visibleCellsCount, lastCellRowIndex)
            imageList1TableView.scrollToRow(at: IndexPath(row: nextAnchorIndex, section: 0), at: .bottom, animated: true)
            return true
        }
    }
}
