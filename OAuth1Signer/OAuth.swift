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

public final class OAuth {
    
    public static func authorizationHeader(forUri uri: URL,
                                           method: String,
                                           payload: String?,
                                           consumerKey: String,
                                           signingPrivateKey: SecKey) throws -> String {
        
        let queryParams = uri.queryParameters()
        var oauthParams = oauthParameters(withKey: consumerKey, payload: payload)
        let paramString = oauthParamString(forQueryParameters: queryParams, oauthParameters: oauthParams)
        
        let sbs = signatureBaseString(httpMethod: method, baseUri: uri.lowercasedBaseUrl(), paramString: paramString)
        
        do {
            let signature = try signSignatureBaseString(sbs: sbs, signingKey: signingPrivateKey)
            let encodedSignature = signature //.addingPercentEncoding(withAllowedCharacters: .)
            oauthParams["oauth_signature"] = encodedSignature
            debugPrint(authorizationString(oauthParams: oauthParams))
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
        allowed.insert(charactersIn: "-._~")
        return paramString.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }
}

extension OAuth {
    public static func loadPrivateKey(fromPath certificatePath: String?, keyPassword: String) -> SecKey? {
        
        guard let certificatePath = certificatePath,
            let certificateData = NSData(contentsOfFile: certificatePath) else {
                return nil
        }
        
        var status: OSStatus
        let options = [kSecImportExportPassphrase as String: keyPassword]
        
        var optItems: CFArray?
        status = SecPKCS12Import(certificateData, options as CFDictionary, &optItems)
        if status != errSecSuccess {
            print("Failed loading private key - unable to import keystore.")
            return nil
        }
        guard let items = optItems else { return nil }
        
        // Cast CFArrayRef to Swift Array
        let itemsArray = items as [AnyObject]
        // Cast CFDictionaryRef as Swift Dictionary
        guard let myIdentityAndTrust = itemsArray.first as? [String : AnyObject] else {
            return nil
        }
        
        // Get our SecIdentityRef from the PKCS #12 blob
        let outIdentity = myIdentityAndTrust[kSecImportItemIdentity as String] as! SecIdentity
        var myReturnedCertificate: SecCertificate?
        status = SecIdentityCopyCertificate(outIdentity, &myReturnedCertificate)
        if status != errSecSuccess {
            print("Failed to retrieve the certificate associated with the requested identity.")
            return nil
        }
        
        // Get the private key associated with our identity
        var privateKey: SecKey?
        status = SecIdentityCopyPrivateKey(outIdentity, &privateKey)
        if status != errSecSuccess {
            print("Failed to extract the private key from the keystore.")
            return nil
        }
        
        return privateKey
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

