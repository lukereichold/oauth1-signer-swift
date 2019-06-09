import Foundation
import Security

public struct OAuth {
    
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
            oauthParams["oauth_signature"] = signature
            return authorizationString(oauthParams: oauthParams)
            
        } catch {
            throw error.localizedDescription
        }
    }
}

private extension OAuth {
    
    static func signSignatureBaseString(sbs: String, signingKey: SecKey) throws -> String {
        
        guard SecKeyIsAlgorithmSupported(signingKey, .sign, .rsaSignatureMessagePKCS1v15SHA256) else {
            throw "Provided private key is invalid."
        }
        
        let sbsData = sbs.data(using: .utf8)!
        var error: Unmanaged<CFError>?
        guard let signedData = SecKeyCreateSignature(signingKey, .rsaSignatureMessagePKCS1v15SHA256, sbsData as CFData, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
        let signature = (signedData as Data).base64EncodedString()
        return signature.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    }
    
    static func authorizationString(oauthParams: [String: String]) -> String {
        var header = "OAuth "
        for (key, value) in oauthParams.sorted(by: {$0.0 < $1.0}) {
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
            oauthParams["oauth_body_hash"] = payload?.base64Hash() ?? ""
        }
        oauthParams["oauth_consumer_key"] = consumerKey.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
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
    
    static func currentUnixTimestamp() -> String {
        return String(Int(Date().timeIntervalSince1970))
    }
}
