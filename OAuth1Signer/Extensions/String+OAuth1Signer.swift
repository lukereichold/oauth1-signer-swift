import Foundation

extension String: Error {}

extension String {
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    func sha256() -> Data? {
        guard let data = data(using: String.Encoding.utf8) else { return nil }
        return data.sha256()
    }
}
