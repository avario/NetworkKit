
import Foundation

public protocol DataNetworkRequest {

    var method: HTTPMethod { get }
    var path: String { get }
    var encoding: ParameterEncoding { get }
	var parameters: Parameters { get }
    var headers: Headers { get }

    func previewAssetName<N: Network>(for network: N) -> String

    associatedtype Parameters: Encodable = EmptyEncodable
    associatedtype Headers: Encodable = EmptyEncodable
}

public extension DataNetworkRequest {

    var encoding: ParameterEncoding {
        switch method {
        case .get, .delete, .head:
            return .url
        case .put, .post:
            return .json
        }
    }

	var parameters: EmptyEncodable { EmptyEncodable() }
    var headers: EmptyEncodable { EmptyEncodable() }

    func previewAssetName<N: Network>(for network: N) -> String {
        let localURL = network.baseURL.appendingPathComponent(path)
        var localName = localURL.absoluteString
        if let scheme = localURL.scheme {
            localName = localName.replacingOccurrences(of: scheme, with: "").replacingOccurrences(of: "://", with: "")
        }

        return localName
    }
}
