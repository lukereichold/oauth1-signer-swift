import Foundation
import CryptoKit

extension String: Error {}

extension String {
    subscript (i: Int) -> Character {
        self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        String(self[i] as Character)
    }
    
    func base64Hash() -> String? {
        guard let data = data(using: .utf8) else { return nil }
        return Data(SHA256.hash(data: data)).base64EncodedString()
    }
}
