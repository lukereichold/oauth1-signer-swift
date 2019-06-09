import XCTest
import CryptoKit // TODO: REMOVE ME
@testable import MastercardOAuth1Signer

final class MastercardOAuth1SignerTests: XCTestCase {
    func testExample() {
        XCTAssertEqual(MastercardOAuth1Signer().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]

    func testExtractQueryParams() {
        let encodedString = "https://sandbox.api.mastercard.com?param1=plus+value&param2=colon:value&param3=a space~".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let queryParams = URL(string: encodedString!)?.queryParameters()
        XCTAssertEqual(queryParams?.count, 3, "Number of parameters are incorrect")
        let filterResult =  queryParams?.filter({
            // this is where you determine whether to include the specific element, $0
            $0.value.contains("plus+value") ||
                $0.value.contains("colon:value") ||
                $0.value.contains("a space~")
            // or whatever search method you're using instead
        })
        XCTAssertEqual(filterResult?.count, 3, "Number of parameters are incorrect")
    }
    
    func testLowercasedBaseUrl() {
        let encodedString = "https://sandbox.api.mastercard.com?param1=plus+value&param2=colon:value&param3=a space~".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let baseURL = URL(string: encodedString!)?.lowercasedBaseUrl()
        XCTAssertEqual(baseURL, "https://sandbox.api.mastercard.com", "lowercasedBaseUrl() is incorrect")
    }
    
    func testLowercasedBaseUrl_ShouldRemoveRedundantPorts() {
        var encodedString = "https://api.mastercard.com:443/test?query=param".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        var baseURL = URL(string: encodedString!)?.lowercasedBaseUrl()
        XCTAssertEqual(baseURL, "https://api.mastercard.com/test", "lowercasedBaseUrl() is not removing redundant ports")
        
        encodedString = "http://api.mastercard.com:80/test".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        baseURL = URL(string: encodedString!)?.lowercasedBaseUrl()
        XCTAssertEqual(baseURL, "http://api.mastercard.com/test", "lowercasedBaseUrl() is not removing redundant ports")
        
        encodedString = "https://api.mastercard.com:17443/test?query=param".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        baseURL = URL.init(string: encodedString!)?.lowercasedBaseUrl()
        XCTAssertEqual(baseURL, "https://api.mastercard.com/test", "lowercasedBaseUrl() is removing valid port number")
        
    }
    
    func testLowercasedBaseUrl_ShouldRemoveFragments() {
        let encodedString = "https://api.mastercard.com/test?query=param#fragment".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let baseURL = URL(string: encodedString!)?.lowercasedBaseUrl()
        XCTAssertEqual(baseURL, "https://api.mastercard.com/test", "lowercasedBaseUrl() is removing valid port number")
    }
    
    func testLowercasedBaseUrl_ShouldUseLowercaseSchemesAndHosts() {
        let encodedString = "HTTPS://API.MASTERCARD.COM/TEST".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let baseURL = URL.init(string: encodedString!)?.lowercasedBaseUrl()
        XCTAssertEqual(baseURL, "https://api.mastercard.com/TEST", "lowercasedBaseUrl() is not lower casing schemes and host")
    }
    
    func testLoadPrivateKey_ShouldReturnKey() {
        let certificatePath = Bundle(for: type(of: self)).path(forResource: "test_key_container", ofType: "p12")
        let signingKey = KeyProvider.loadPrivateKey(fromPath: certificatePath!, keyPassword: "Password1")!
        XCTAssertEqual(256, SecKeyGetBlockSize(signingKey), "signingKey size is incorrect")
        //        XCTAssertFalse(SecKeyIsAlgorithmSupported(signingKey, .encrypt, .rsaEncryptionRaw))
        
    }
    
    func testOAuthHeaders() {
        let urlString = "https://sandbox.api.mastercard.com/fraud/merchant/v1/termination-inquiry?Format=XML&PageOffset=0&PageLength=10"
        let method = "POST";
        let uri = URL(string: urlString)!
        let bodyString = "<?xml version=\"1.0\" encoding=\"Windows-1252\"?><ns2:TerminationInquiryRequest xmlns:ns2=\"http://mastercard.com/termination\"><AcquirerId>1996</AcquirerId><TransactionReferenceNumber>1</TransactionReferenceNumber><Merchant><Name>TEST</Name><DoingBusinessAsName>TEST</DoingBusinessAsName><PhoneNumber>5555555555</PhoneNumber><NationalTaxId>1234567890</NationalTaxId><Address><Line1>5555 Test Lane</Line1><City>TEST</City><CountrySubdivision>XX</CountrySubdivision><PostalCode>12345</PostalCode><Country>USA</Country></Address><Principal><FirstName>John</FirstName><LastName>Smith</LastName><NationalId>1234567890</NationalId><PhoneNumber>5555555555</PhoneNumber><Address><Line1>5555 Test Lane</Line1><City>TEST</City><CountrySubdivision>XX</CountrySubdivision><PostalCode>12345</PostalCode><Country>USA</Country></Address><DriversLicense><Number>1234567890</Number><CountrySubdivision>XX</CountrySubdivision></DriversLicense></Principal></Merchant></ns2:TerminationInquiryRequest>"
        let consumerKey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
        let certificatePath = Bundle(for: type(of: self)).path(forResource: "test_key_container", ofType: "p12")
        let signingKey = KeyProvider.loadPrivateKey(fromPath: certificatePath!, keyPassword: "Password1")!
        let payloadData = bodyString.data(using: .utf8)
        let payloadString = String(data: payloadData!, encoding: .utf8)
        
        let header = try? OAuth.authorizationHeader(forUri: uri, method: method, payload: payloadString, consumerKey: consumerKey, signingPrivateKey: signingKey)
        XCTAssertTrue((header?.contains("oauth_body_hash=\"h2Pd7zlzEZjZVIKB4j94UZn/xxoR3RoCjYQ9/JdadGQ=\""))!,"OAuth body hash is incorrect")
        XCTAssertTrue((header?.contains("oauth_consumer_key=\"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\""))!,"OAuth Consumer key is incorrect")
        XCTAssertTrue((header?.contains("oauth_signature_method=\"RSA-SHA256\""))!,"OAuth Signature Method is incorrect")
        XCTAssertTrue((header?.contains("oauth_version=\"1.0\""))!,"OAuth Version is incorrect")
    }
}
