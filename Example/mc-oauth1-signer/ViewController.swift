import UIKit
import Alamofire
import CommonCrypto
import MastercardOAuth

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        requestService()
    }

    func requestService() {
        let urlString = "https://sandbox.api.mastercard.com/service"
        let method = "POST";
        let uri = URL(string: urlString)!
        let consumerKey = "<<REPLACE_ME>>"
        
        let payload: Parameters = [
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
            switch response.result {
            case .success:
                print(response)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func getPrivateKey() -> SecKey {
        let certificatePath = Bundle(for: ViewController.self).path(forResource: "<<REPLACE_ME>>", ofType: "p12")
        
        let signingKey = KeyProvider.loadPrivateKey(fromPath: certificatePath!, keyPassword: "<<REPLACE_ME>>")!
        return signingKey
    }
}
