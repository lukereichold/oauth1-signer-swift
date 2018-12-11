import Foundation

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
    }
    
    func lowercasedBaseUrl() -> String {
        guard let scheme = scheme?.lowercased(), let host = host?.lowercased() else { return "" }
        return "\(scheme)://\(host)\(path)"
    }
}

