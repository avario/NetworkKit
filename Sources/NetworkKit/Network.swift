import Foundation

public protocol Network {

	var baseURL: URL { get }

	var parameters: Parameters { get }
	associatedtype Parameters: Encodable = EmptyEncodable

	var headers: Headers { get }
	associatedtype Headers: Encodable = EmptyEncodable

	static var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { get }
	static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { get }

	associatedtype RemoteError = Void
    func remoteError(for response: HTTPURLResponse, data: Data) throws -> RemoteError

    var requester: NetworkRequester { get }
}

public extension Network {

	var parameters: EmptyEncodable { EmptyEncodable() }
	var headers: EmptyEncodable { EmptyEncodable() }

	static var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { .deferredToDate }
	static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { .deferredToDate  }

	static var decoder: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = dateDecodingStrategy
		return decoder
	}

	static var encoder: JSONEncoder {
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
        return try Self.decoder.decode(RemoteError.self, from: data)
	}
}

public struct EmptyEncodable: Encodable { }
