
import Foundation

public protocol DataNetworkRequest {

    var method: HTTPMethod { get }
    var path: String { get }
    var encoding: ParameterEncoding { get }
	var parameters: Parameters { get }
    var headers: Headers { get }

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
}
