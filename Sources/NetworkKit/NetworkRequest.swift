import Foundation
import UIKit
import Combine

public protocol NetworkRequest {

    associatedtype Network: NetworkKit.Network

	var method: HTTPMethod { get }
	var path: String { get }
	var encoding: ParameterEncoding { get }
	var parameters: Parameters { get }
	var headers: Headers { get }

	associatedtype Parameters: Encodable = EmptyEncodable
	associatedtype Headers: Encodable = EmptyEncodable

	associatedtype Response = Data
	func response(for data: Data) throws -> Response

    func preview() throws -> Response
}

public extension NetworkRequest {

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

public extension NetworkRequest where Response: Decodable {

	func response(for data: Data) throws -> Response {
		return try Network.decoder.decode(Response.self, from: data)
	}
}

public extension NetworkRequest where Response == Data {

	func response(for data: Data) throws -> Response {
		return data
	}
}

public extension NetworkRequest where Response == UIImage {

	func response(for data: Data) throws -> Response {
		guard let image = UIImage(data: data) else {
			throw NetworkError<Network.RemoteError>.local(.invalidImageData(data))
		}

		return image
	}
}

public enum ParameterEncoding {
	case url
	case json
}

public enum HTTPMethod: String {
	case delete
	case get
	case head
	case post
	case put
}
