//
//  WebViewController.swift
//  SampleApp
//
//  Created by jin kim on 20/06/2019.
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

final class WebViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet private weak var webView: NuguWebView!
    
    var initialURL: URL?
    
    // MARK: Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let initialURL = initialURL else { return }
        webView.load(URLRequest(url: initialURL))
    }
}

// MARK: - Private (IBAction)

private extension WebViewController {
    @IBAction func closeButtonDidClick(_ button: UIButton) {
        dismiss(animated: true)
    }
}
