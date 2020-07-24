//
//  SyncthingClient.swift
//  SyncthingBar
//
//  Created by John on 12/11/2016.
//  Copyright © 2016 Olive Toast Software Ltd. All rights reserved.
//

import Foundation

enum SyncthingClientError: Error {
    case invalidRequest
    case invalidResponse
    case parseError
}

class SyncthingClient {
    let apiKey: String
    let url: URL

    init(url: URL, apiKey: String) {
        self.url = url
        self.apiKey = apiKey
    }

    func restRequest(forPath path: String, httpMethod: String = "GET") -> URLRequest? {
        if let restUrl = URL(string: path, relativeTo: self.url) {
            var request = URLRequest(url: restUrl)
            request.httpMethod = httpMethod
            request.setValue(self.apiKey, forHTTPHeaderField: "X-API-Key")
            return request
        }
        else {
            return nil
        }
    }

    /// Polls syncthing up to "repeating" times to check the connection.
    func checkConnection(repeating: Int, completionHandler: @escaping (Bool, Error?) -> Void) {
        var count = 0

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            count += 1
            if count >= repeating {
                timer.invalidate()
            }

            self.ping { ok, error in
                // We ignore the error to ensure we keep checking:
                if ok {
                    timer.invalidate()
                    completionHandler(ok, nil)
                }
            }
        }
    }

    func ping(completionHandler: @escaping (Bool, Error?) -> Void) {
        if let request = self.restRequest(forPath: "/rest/system/ping") {
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if error == nil && (response as! HTTPURLResponse).statusCode == 200 {
                        completionHandler(true, nil)
                    }
                    else {
                        completionHandler(false, SyncthingClientError.invalidResponse)
                    }
                }
            }.resume()
        }
        else {
            completionHandler(false, SyncthingClientError.invalidRequest)
        }
    }

    func fetchEvent(lastId: Int, limit: Int, completionHandler: @escaping ([String: Any]?, Error?) -> Void ) {
        var path = "/rest/events?since=\(lastId)"
        if limit > 0 {
            path += "&limit=\(limit)"
        }

        guard let request = self.restRequest(forPath: path) else {
            // TODO: Should this method throw, or return false?
            completionHandler(nil, SyncthingClientError.invalidRequest)
            return
        }

        URLSession.shared.jsonTask(with: request) { json, response, error in
            DispatchQueue.main.async {
                if error != nil {
                    completionHandler(nil, error)
                }
                else if let json = json {
                    guard let root = json as? [Any] else {
                        completionHandler(nil, SyncthingClientError.parseError)
                        return
                    }

                    guard let info = root.first as? [String: Any] else {
                        completionHandler(nil, SyncthingClientError.parseError)
                        return
                    }

                    completionHandler(info, nil)
                }
                else {
                    completionHandler(nil, SyncthingClientError.parseError)
                }
            }
        }.resume()
    }
}
