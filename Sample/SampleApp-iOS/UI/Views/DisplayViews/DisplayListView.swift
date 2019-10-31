//
//  DisplayListView.swift
//  SampleApp-iOS
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

import NuguInterface

final class DisplayListView: UIView {
    
    @IBOutlet private weak var titleContainerView: UIView!
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    
    var onCloseButtonClick: (() -> Void)?
    var onItemSelect: (((templateId: String?, token: String?)) -> Void)?
    
    var displayTemplate: DisplayTemplate.ListTemplate? {
        didSet {
            guard let displayTemplate = displayTemplate else { return }

            titleLabel.text = displayTemplate.title.text.text
            titleLabel.textColor = UIColor(rgbHexString: displayTemplate.title.text.color)
            
            if let logoUrl = displayTemplate.title.logo.sources.first?.url {
                logoImageView.loadImage(from: logoUrl)
                logoImageView.isHidden = false
            } else {
                logoImageView.isHidden = true
            }
            
            backgroundColor = UIColor(rgbHexString: displayTemplate.background?.color)
            
            tableView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadFromXib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadFromXib()
    }
    
    private func loadFromXib() {
        let view = Bundle.main.loadNibNamed("DisplayListView", owner: self)?.first as! UIView
        view.frame = bounds
        addSubview(view)
        tableView.register(UINib(nibName: "DisplayListViewCell", bundle: nil), forCellReuseIdentifier: "DisplayListViewCell")
        addBorderToTitleContainerView()
    }
    
    private func addBorderToTitleContainerView() {
        titleContainerView.layer.cornerRadius = titleContainerView.bounds.size.height / 2.0
        titleContainerView.layer.borderColor = UIColor(rgbHexValue: 0xc9cacc).cgColor
        titleContainerView.layer.borderWidth = 1.0
    }
    
    @IBAction private func closeButtonDidClick(_ button: UIButton) {
        onCloseButtonClick?()
    }
}

extension DisplayListView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayTemplate?.listItems.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let displayImageList1Cell = tableView.dequeueReusableCell(withIdentifier: "DisplayListViewCell") as! DisplayListViewCell
        displayImageList1Cell.configure(index: String(indexPath.row + 1), item: displayTemplate?.listItems[indexPath.row])
        return displayImageList1Cell
    }
}

extension DisplayListView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onItemSelect?((templateId: displayTemplate?.playServiceId, token: displayTemplate?.listItems[indexPath.row].token))
    }
}

