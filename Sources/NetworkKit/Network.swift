import Foundation

public protocol Network {
    var baseURL: URL { get }

	var headers: Headers { get }
	associatedtype Headers: Encodable = EmptyEncodable

    static var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { get }
    static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { get }

	associatedtype RemoteError = Void
	func remoteError(for response: HTTPURLResponse, data: Data) throws -> RemoteError
}

public extension Network {
	var headers: EmptyEncodable { EmptyEncodable() }

    static var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { .iso8601 }
    static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { .iso8601 }

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

public struct EmptyEncodable: Encodable {}
