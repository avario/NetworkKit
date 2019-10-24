import Foundation

public protocol Network: AnyObject {

	var baseURL: URL { get }

	var parameters: Parameters { get }
	associatedtype Parameters: Encodable = EmptyEncodable

	var headers: Headers { get }
	associatedtype Headers: Encodable = EmptyEncodable

	var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { get }
	var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { get }

	associatedtype RemoteError = Void
    func remoteError(for response: HTTPURLResponse, data: Data) throws -> RemoteError
}

public extension Network {

	var parameters: EmptyEncodable { EmptyEncodable() }
	var headers: EmptyEncodable { EmptyEncodable() }

	var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { .deferredToDate }
	var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { .deferredToDate  }

	var decoder: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = dateDecodingStrategy
		return decoder
	}

	var encoder: JSONEncoder {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = dateEncodingStrategy
		return encoder
	}
}

public extension Network where RemoteError == Void {

	func remoteError(for response: HTTPURLResponse, data: Data) throws {
		return
	}
}

public extension Network where RemoteError: Decodable {

	func remoteError(for response: HTTPURLResponse, data: Data) throws -> RemoteError {
		return try decoder.decode(RemoteError.self, from: data)
	}
}

public struct EmptyEncodable: Encodable { }
