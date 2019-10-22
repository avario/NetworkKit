
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

    associatedtype ErrorContent = Void

    func errorContent(for data: Data) throws -> ErrorContent
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

    func request<R: NetworkRequest>(_ request: R) -> AnyPublisher<R.Response, NetworkError<ErrorContent>> {
        do {
            switch previewMode {
            case .automatic:
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil {
                    fallthrough
                }
            case .success:
                return Result.success(try request.preview(on: self))
                    .publisher.eraseToAnyPublisher()
            case .loading:
                return PassthroughSubject<R.Response, NetworkError>()
                    .eraseToAnyPublisher()

            case .failure(let error):
                return Result.failure(NetworkError<ErrorContent>(error ?? NetworkError<ErrorContent>.local(.preview)))
                    .publisher.eraseToAnyPublisher()

            case .noPreview:
                break
            }

            return URLSession.shared.dataTaskPublisher(for: try request.asURLRequest(on: self))
                .tryMap { (data: Data, response: URLResponse) -> R.Response in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NetworkError<ErrorContent>.local(.invalidURLResponse(response))
                    }

                    guard 200..<300 ~= httpResponse.statusCode else {
                        throw NetworkError.remote(
                            statusCode: httpResponse.statusCode,
                            content: try self.errorContent(for: data))
                    }

                    return try request.response(on: self, for: data)
                }
                .mapError(NetworkError<ErrorContent>.init)
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } catch {
            return Result.failure(NetworkError<ErrorContent>(error))
                .publisher.eraseToAnyPublisher()
        }
    }
}

public extension Network where ErrorContent == Void {

    func errorContent(for data: Data) throws {
        return
    }
}

public extension Network where ErrorContent: Decodable {

    func errorContent(for data: Data) throws -> ErrorContent {
        return try decoder.decode(ErrorContent.self, from: data)
    }
}

public struct EmptyEncodable: Encodable { }

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
