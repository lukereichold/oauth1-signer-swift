import XCTest
import Alamofire
@testable import OAuth1Signer

class OAuth1SignerTests: XCTestCase {
    
    func testExample() {
        let urlString = "https://sandbox.api.mastercard.com/priceless/partner/product/allProductIds"
        let method = "POST";
        let uri = URL(string: urlString)!
        
        let consumerKey = "iRs6nIIfPGEYJsZH-OBvXKBC2xXA464BNDscijDX6764fad4!7599e036db964177a3b470857c7e56b80000000000000000"
        let partnerId = 403 // Priceless Cities
        let apiSecretKey = "mbhhBngBJrEjEJijKUvM5Tti4jwsgpIz" // Priceless Cities
        
        let timestamp = OAuth.currentUnixTimestamp()
        let rawSignature = timestamp + "_" + String(partnerId) + "_" + apiSecretKey
        let signatureString = rawSignature.sha256() ?? ""
        
        let payload: Parameters = ["partnerId": partnerId,
                       "time": Int(timestamp)!,
                       "signature": signatureString,
                       "languageId": 1,
                       "geographicId": 0]
        
        let payloadJSON = (try? JSONSerialization.data(withJSONObject: payload, options: [])) ?? Data()
        let payloadString = String(data: payloadJSON, encoding: .utf8)

        let header = try? OAuth.authorizationHeader(forUri: uri, method: method, payload: payloadString, consumerKey: consumerKey, signingPrivateKey: getPrivateKey())
        

        let headers: HTTPHeaders = [
            "Authorization": header!,
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
        let certificatePath = Bundle(for: OAuth1SignerTests.self).path(forResource: "Imagine_Bank-sandbox", ofType: "p12")
        
        let signingKey = OAuth.loadPrivateKey(fromPath: certificatePath, keyPassword: "keystorepassword")!
        return signingKey
    }

}
