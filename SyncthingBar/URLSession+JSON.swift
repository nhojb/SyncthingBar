//
//  URLSession+JSON.swift
//  SyncthingBar
//
//  Created by John on 18/11/2016.
//  Copyright © 2016 Olive Toast Software Ltd. All rights reserved.
//

import Foundation

extension URLSession {
    func jsonTask(with request: URLRequest, completionHandler: @escaping (Any?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.dataTask(with:request) { (data, response, error) in
            var jsonObject : Any?
            if let data = data {
                jsonObject = try? JSONSerialization.jsonObject(with: data)
            }
            completionHandler(jsonObject, response, error)
        }
    }
}
