import UIKit
import Alamofire
import CommonCrypto
import mc_oauth1_signer

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchAllProductIds()
    }

    func fetchAllProductIds() {
        let urlString = "https://sandbox.api.mastercard.com/priceless/partner/product/allProductIds"
        let method = "POST";
        let uri = URL(string: urlString)!
        
        let consumerKey = "iRs6nIIfPGEYJsZH-OBvXKBC2xXA464BNDscijDX6764fad4!7599e036db964177a3b470857c7e56b80000000000000000"
        let partnerId = 403 // Priceless Cities
        let apiSecretKey = "mbhhBngBJrEjEJijKUvM5Tti4jwsgpIz" // Priceless Cities
        
        let timestamp = currentUnixTimestamp()
        let rawSignature = timestamp + "_" + String(partnerId) + "_" + apiSecretKey
        let signatureString = rawSignature.sha256()?.hexString() ?? ""
        
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
        
        Alamofire.request(urlString, method: .post, parameters: payload, encoding: JSONEncoding.default, headers: headers).responseJSON {
            response in
            
            // DEBUGGING
            
            print("Raw signature:")
            debugPrint(rawSignature)
            
            print("\nSHA256 hashed signature (URL encoded):")
            debugPrint(signatureString)
            
            print("\nPrinting raw UrlRequest in cURL format...")
            debugPrint(NSString(string: response.request!.cURL))
            
            // -- END DEBUGGING
            
            switch response.result {
            case .success:
                print(response)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func getPrivateKey() -> SecKey {
        let certificatePath = Bundle(for: ViewController.self).path(forResource: "Imagine_Bank-sandbox", ofType: "p12")
        
        let signingKey = KeyProvider.loadPrivateKey(fromPath: certificatePath!, keyPassword: "keystorepassword")!
        return signingKey
    }
    
    func currentUnixTimestamp() -> String {
        return String(Int(Date().timeIntervalSince1970))
    }
    
}

public extension URLRequest {
    
    /// Returns a cURL command for a request
    /// - return A String object that contains cURL command or "" if an URL is not properly initalized.
    public var cURL: String {
        
        guard
            let url = url,
            let httpMethod = httpMethod,
            url.absoluteString.utf8.count > 0
            else {
                return ""
        }
        
        var curlCommand = "curl --verbose \\\n"
        
        // URL
        curlCommand = curlCommand.appendingFormat(" '%@' \\\n", url.absoluteString)
        
        // Method if different from GET
        if "GET" != httpMethod {
            curlCommand = curlCommand.appendingFormat(" -X %@ \\\n", httpMethod)
        }
        
        // Headers
        let allHeadersFields = allHTTPHeaderFields!
        let allHeadersKeys = Array(allHeadersFields.keys)
        let sortedHeadersKeys  = allHeadersKeys.sorted(by: <)
        for key in sortedHeadersKeys {
            curlCommand = curlCommand.appendingFormat(" -H '%@: %@' \\\n", key, self.value(forHTTPHeaderField: key)!)
        }
        
        // HTTP body
        if let httpBody = httpBody, httpBody.count > 0 {
            let httpBodyString = String(data: httpBody, encoding: String.Encoding.utf8)!
            let escapedHttpBody = URLRequest.escapeAllSingleQuotes(httpBodyString)
            curlCommand = curlCommand.appendingFormat(" --data '%@' \\\n", escapedHttpBody)
        }
        
        return curlCommand
    }
    
    /// Escapes all single quotes for shell from a given string.
    static func escapeAllSingleQuotes(_ value: String) -> String {
        return value.replacingOccurrences(of: "'", with: "'\\''")
    }
}

extension String {
    func sha256() -> Data? {
        guard let data = data(using: String.Encoding.utf8) else { return nil }
        return data.sha256()
    }
}

extension Data {
    func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    func sha256() -> Data? {
        guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else { return nil }
        CC_SHA256((self as NSData).bytes, CC_LONG(self.count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return res as Data
    }
}
