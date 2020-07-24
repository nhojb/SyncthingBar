//
//  UserDefaults+URL.swift
//  SyncthingBar
//
//  Created by John on 22/11/2016.
//  Copyright © 2016 Olive Toast Software Ltd. All rights reserved.
//

import Foundation

extension UserDefaults {
    func url(forKey key: String) -> URL? {
        if let urlString = self.object(forKey: key) as? String {
            return URL(string: urlString)
        }
        else {
            return nil
        }
    }
}
