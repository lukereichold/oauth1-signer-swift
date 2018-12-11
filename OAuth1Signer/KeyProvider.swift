import Foundation

public struct KeyProvider {
    
    public static func loadPrivateKey(fromPath certificatePath: String, keyPassword: String) -> SecKey? {
        
        guard let certificateData = NSData(contentsOfFile: certificatePath) else { return nil }
        
        var status: OSStatus
        let options = [kSecImportExportPassphrase as String: keyPassword]
        
        var optItems: CFArray?
        status = SecPKCS12Import(certificateData, options as CFDictionary, &optItems)
        if status != errSecSuccess {
            print("Failed loading private key - unable to import keystore.")
            return nil
        }
        guard let items = optItems else { return nil }
        
        let itemsArray = items as [AnyObject]
        guard let myIdentityAndTrust = itemsArray.first as? [String : AnyObject] else {
            return nil
        }
        
        let outIdentity = myIdentityAndTrust[kSecImportItemIdentity as String] as! SecIdentity
        var myReturnedCertificate: SecCertificate?
        status = SecIdentityCopyCertificate(outIdentity, &myReturnedCertificate)
        if status != errSecSuccess {
            print("Failed to retrieve the certificate associated with the requested identity.")
            return nil
        }
        
        var privateKey: SecKey?
        status = SecIdentityCopyPrivateKey(outIdentity, &privateKey)
        if status != errSecSuccess {
            print("Failed to extract the private key from the keystore.")
            return nil
        }
        
        return privateKey
    }

}

