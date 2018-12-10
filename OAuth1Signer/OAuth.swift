//
//  OAuth.swift
//  OAuth1Signer
//
//  Created by Luke Reichold on 12/2/18.
//  Copyright © 2018 Reikam Labs. All rights reserved.
//

import Foundation
import Security
import CommonCrypto

public struct OAuth {
    
    public typealias AuthorizationHeader = String
    
    public static func authorizationHeader(forUri uri: URL,
                                           method: String,
                                           payload: String?,
                                           consumerKey: String,
                                           signingPrivateKey: SecKey) throws -> AuthorizationHeader {
        
        let queryParams = uri.queryParameters()
        var oauthParams = oauthParameters(withKey: consumerKey, payload: payload)
        let paramString = oauthParamString(forQueryParameters: queryParams, oauthParameters: oauthParams)
        
        let sbs = signatureBaseString(httpMethod: method, baseUri: uri.lowercasedBaseUrl(), paramString: paramString)
        
        do {
            let signature = try signSignatureBaseString(sbs: sbs, signingKey: signingPrivateKey)
            print("signedSignature")
            debugPrint(signature)
            
            let encodedSignature = signature //.addingPercentEncoding(withAllowedCharacters: .)
            oauthParams["oauth_signature"] = encodedSignature
            return authorizationString(oauthParams: oauthParams)
            
        } catch {
            throw error.localizedDescription
        }
    }
}

extension OAuth {
    
    static func signSignatureBaseString(sbs: String, signingKey: SecKey) throws -> String {
        
        guard SecKeyIsAlgorithmSupported(signingKey, .sign, .rsaSignatureMessagePKCS1v15SHA256) else {
            throw "Provided private key is invalid."
        }
        
        let sbsData = sbs.data(using: .utf8)!
        var error: Unmanaged<CFError>?
        guard let signedData = SecKeyCreateSignature(signingKey, .rsaSignatureMessagePKCS1v15SHA256, sbsData as CFData, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
        let signature = (signedData as Data).base64EncodedString() // TODO: Can I cast to Data like this?
        return signature
    }
    
    static func authorizationString(oauthParams: [String: String]) -> String {
        var header = "OAuth "
        for (key, value) in oauthParams {
            header.append("\(key)=\"\(value)\",")
        }
        return String(header.dropLast())
    }
    
    static func signatureBaseString(httpMethod: String, baseUri: String, paramString: String) -> String {
        let escapedBaseUri = baseUri.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        
        return httpMethod.uppercased()
        + "&"
        + escapedBaseUri
        + "&"
        + paramString
    }
    
    static func currentUnixTimestamp() -> String {
        return String(Int(Date().timeIntervalSince1970))
    }
    
    static func nonce() -> String {
        let bytesCount = 8
        var randomBytes = [UInt8](repeating: 0, count: bytesCount)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytesCount, &randomBytes)

        let validChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return randomBytes.map { randomByte in
            return validChars[Int(randomByte % UInt8(validChars.count))]
        }.joined()
    }
    
    static func oauthParameters(withKey consumerKey: String, payload: String?) -> [String: String] {
        var oauthParams = [String: String]()
        if payload != nil {
            oauthParams["oauth_body_hash"] = payload?.sha256() ?? ""
        }
        oauthParams["oauth_consumer_key"] = consumerKey
        oauthParams["oauth_nonce"] = nonce()
        oauthParams["oauth_signature_method"] = "RSA-SHA256"
        oauthParams["oauth_timestamp"] = currentUnixTimestamp()
        oauthParams["oauth_version"] = "1.0"
        return oauthParams
    }
    
    static func oauthParamString(forQueryParameters queryParameters: UniqueParametersMap?,
                                 oauthParameters: [String: String]) -> String {
        
        var allParameters = [(key: String, values: [String])]()
        if let queryParams = queryParameters {
            allParameters += queryParams.sorted { $0.0 < $1.0 }.map {(key: $0.0, values: Array($0.value)) }
        }

        let sortedOauthParams = oauthParameters.sorted { $0.0 < $1.0 }.map { (key: $0.key, values: [$0.value])}
        allParameters += sortedOauthParams
        
        var paramString = allParameters.reduce(into: "") { combined, keyPair in
            keyPair.values.sorted().forEach { value in
                combined.append("\(keyPair.key)=\(value)&")
            }
        }
        
        if paramString.last! == "&" {
            paramString = String(paramString.dropLast())
        }
        
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~") // as per RFC 3986
        return paramString.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }
}

extension String {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    func sha256() -> String? {
        guard
            let data = data(using: String.Encoding.utf8),
            let shaData = data.sha256()
            else { return nil }
        let rc = shaData.base64EncodedString(options: [])
        return rc
    }
    
}

extension String: Error {}

extension Data {
    func sha256() -> Data? {
        guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else { return nil }
        CC_SHA256((self as NSData).bytes, CC_LONG(self.count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return res as Data
    }
}

typealias UniqueParametersMap = [String: Set<String>]

extension URL {
    func queryParameters() -> UniqueParametersMap? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        let uniqueQueryItems = components.queryItems?.reduce(into: UniqueParametersMap()) { uniqueMap, queryItem in
            uniqueMap[queryItem.name, default: []].insert(queryItem.value ?? "")
        }
        
        return uniqueQueryItems
        // TODO: components.percentEncodedQueryItems instead ?
    }
    
    func lowercasedBaseUrl() -> String {
        guard let scheme = scheme?.lowercased(), let host = host?.lowercased() else { return "" }
        return "\(scheme)://\(host)\(path)"
    }
}
