//
//  DisplayWeatherListView.swift
//  SampleApp
//
//  Created by jin kim on 2019/12/16.
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

final class DisplayWeatherListView: DisplayView {
    
    @IBOutlet private weak var locationButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    
    override var displayPayload: Data? {
        didSet {
            guard let payloadData = displayPayload,
                let displayItem = try? JSONDecoder().decode(DisplayWeatherListTemplate.self, from: payloadData) else { return }
            
            titleLabel.text = displayItem.title.text.text
            titleLabel.textColor = UIColor.textColor(rgbHexString: displayItem.title.text.color)
            
            backgroundColor = UIColor.backgroundColor(rgbHexString: displayItem.background?.color)
            
            if let logoUrl = displayItem.title.logo?.sources.first?.url {
                logoImageView.loadImage(from: logoUrl)
                logoImageView.isHidden = false
            } else {
                logoImageView.isHidden = true
            }

            // Set location info
            locationButton.setTitle(displayItem.title.subtext?.text, for: .normal)
            locationButton.setTitleColor(UIColor.textColor(rgbHexString: displayItem.title.subtext?.color), for: .normal)

            weatherListItems = displayItem.content.listItems
            tableView.reloadData()            
        }
    }

    private var weatherListItems: [DisplayWeatherListTemplate.Content.Item]?
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("DisplayWeatherListView", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        addBorderToTitleContainerView()
        tableView.backgroundColor = UIColor.white
        tableView.register(UINib(nibName: "DisplayWeatherListViewCell", bundle: nil), forCellReuseIdentifier: "DisplayWeatherListViewCell")
    }
}

extension DisplayWeatherListView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weatherListItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let displayWeatherListViewCell = tableView.dequeueReusableCell(withIdentifier: "DisplayWeatherListViewCell") as! DisplayWeatherListViewCell
        // swiftlint:enable force_cast
        displayWeatherListViewCell.configure(item: weatherListItems?[indexPath.row])
        return displayWeatherListViewCell
    }
}
