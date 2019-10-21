
import Foundation
import Combine
import UIKit

public protocol Network: AnyObject {

	var baseURL: URL { get }

	var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { get }
	var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { get }

	var persistentParameters: PersistentParameters { get }
	associatedtype PersistentParameters: Encodable = EmptyEncodable

	var persistentHeaders: PersistentHeaders { get }
	associatedtype PersistentHeaders: Encodable = EmptyEncodable
}

public extension Network {

	var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { .deferredToDate }
	var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { .deferredToDate  }

	var persistentParameters: EmptyEncodable { EmptyEncodable() }
	var persistentHeaders: EmptyEncodable { EmptyEncodable() }

	var previewMode: NetworkPreviewMode { return NetworkPreviewMode[for: self] }

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

    func request<R: NetworkRequest>(_ request: R) -> AnyPublisher<R.Response, NetworkError> where R.Response: Decodable {
        do {
            return NetworkKit.request(try request.asURLRequest(on: self), previewMode: previewMode)
                .decode(
                    type: R.Response.self,
                    decoder: decoder)
                .mapError(NetworkError.init)
                .eraseToAnyPublisher()

        } catch {
            return Result.failure(NetworkError.init(error: error))
                .publisher.eraseToAnyPublisher()
        }

	}

    func request<R: NetworkRequest>(_ request: R) -> AnyPublisher<Data, NetworkError> where R.Response == Data {
		do {
            return NetworkKit.request(try request.asURLRequest(on: self), previewMode: previewMode)
		} catch {
			return Result.failure(NetworkError.init(error: error))
				.publisher.eraseToAnyPublisher()
		}
	}
}
