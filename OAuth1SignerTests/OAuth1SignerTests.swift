import XCTest
import Alamofire
@testable import OAuth1Signer

class OAuth1SignerTests: XCTestCase {
    
    func testExample() {
        let urlString = "***REMOVED***"
        let method = "POST";
        let uri = URL(string: urlString)!
        
        let consumerKey = "***REMOVED***"
        let ***REMOVED*** = ***REMOVED*** // ***REMOVED***
        let apiSecretKey = "***REMOVED***" // ***REMOVED***
        
        let timestamp = OAuth.currentUnixTimestamp()
        let rawSignature = timestamp + "_" + String(***REMOVED***) + "_" + apiSecretKey
        let signatureString = rawSignature.sha256() ?? ""
        
        let payload: Parameters = ["***REMOVED***": ***REMOVED***,
                       "time": Int(timestamp)!,
                       "signature": signatureString,
                       "languageId": 1,
                       "geographicId": 0]
        
        let payloadJSON = (try? JSONSerialization.data(withJSONObject: payload, options: [])) ?? Data()
        let payloadString = String(data: payloadJSON, encoding: .utf8)

        
        let header = try? OAuth.authorizationHeader(forUri: uri, method: method, payload: payloadString, consumerKey: consumerKey, signingPrivateKey: getPrivateKey())
        

        let headers: HTTPHeaders = [
            "Authorization": header! as String,
            "Accept": "application/json",
            "Referer": "api.mastercard.com"
        ]

        let expectation = XCTestExpectation(description: "Running web request")
        Alamofire.request(urlString, method: .post, parameters: payload, encoding: JSONEncoding.default, headers: headers).responseJSON {
            response in
            
            print("PRINTING PROVIDED HEADERS...")
            debugPrint(response.request!.allHTTPHeaderFields)

            switch response.result {
            case .success:
                print(response)
            case .failure(let error):
                print(error)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }
    
    // TODO: provide this to consumers in a Utilities class?
    private func getPrivateKey() -> SecKey {
        let certificatePath = Bundle(for: OAuth1SignerTests.self).path(forResource: "***REMOVED***", ofType: "p12")
        
        let signingKey = OAuth.loadPrivateKey(fromPath: certificatePath, keyPassword: "***REMOVED***")!
        return signingKey
    }

}
