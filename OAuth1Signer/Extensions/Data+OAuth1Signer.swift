import Foundation
import CommonCrypto

extension Data {
    func sha256() -> Data? {
        guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else { return nil }
        CC_SHA256((self as NSData).bytes, CC_LONG(self.count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return res as Data
    }
    
    func base64String() -> String {
        return base64EncodedString(options: [])
    }
    
    func hexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
