//
//  OAuth1SignerTests.swift
//  OAuth1SignerTests
//
//  Created by Luke Reichold on 12/1/18.
//  Copyright © 2018 Reikam Labs. All rights reserved.
//

import XCTest
@testable import OAuth1Signer

class OAuth1SignerTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testExample() {
//        OAuth.getAuthorizationHeader(forUri: "a", method: "a", payload: "A", consumerKey: "a", signingKey: "a")
        let url = URL(string: "http://example.com?query1=foo1&query1=bar&query3=baz")
        let params = url?.queryParams()
        debugPrint(params)
    }

    func testPerformanceExample() {
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

extension URL {
    func queryParams() -> [URLQueryItem]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return nil
        }
        return components.queryItems?.sorted()
        // TODO: components.percentEncodedQueryItems instead ??
    }
}
