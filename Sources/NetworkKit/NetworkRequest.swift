import Foundation
import UIKit
import Combine

public protocol NetworkRequest {

	var method: HTTPMethod { get }
	var path: String { get }
	var encoding: ParameterEncoding { get }
	var parameters: Parameters { get }
	var headers: Headers { get }

	associatedtype Parameters: Encodable = EmptyEncodable
	associatedtype Headers: Encodable = EmptyEncodable

	associatedtype Response = Data
	func response<N: Network>(on network: N, for data: Data) throws -> Response

    #if DEBUG
    func preview<N: Network>(on network: N) throws -> Response
    #endif
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

	func request<N: Network>(on network: N) -> AnyPublisher<Response, NetworkError<N.RemoteError>>  {
		do {
            #if DEBUG
            switch NetworkPreviewMode.modes[ObjectIdentifier(network)] ?? .automatic {
			case .automatic:
				if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil {
					fallthrough
				}
            case .always:
				return Result.success(try preview(on: network))
					.publisher.eraseToAnyPublisher()

			case .never:
				break
			}
            #endif

			let url = network.baseURL.appendingPathComponent(path)

			let requestParameters = try JSONSerialization.jsonObject(
				with: try network.encoder.encode(parameters)) as! [String: Any]
			let networkParameters = try JSONSerialization.jsonObject(
				with: try network.encoder.encode(network.parameters)) as! [String: Any]
			let allParameters = requestParameters.merging(networkParameters) { (requestParameter, _) in requestParameter }

			var urlRequest: URLRequest

			switch encoding {
			case .url:
				var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
				urlComponents.queryItems = allParameters.map { parameter in
					URLQueryItem(name: parameter.key, value: "\(parameter.value)")
				}

				urlRequest = URLRequest(url: urlComponents.url!)

			case .json:
				urlRequest = URLRequest(url: url)
				urlRequest.httpBody = try JSONSerialization.data(withJSONObject: allParameters)
			}

			urlRequest.httpMethod = method.rawValue

			let requestHeaders = try JSONSerialization.jsonObject(
				with: try network.encoder.encode(headers)) as! [String: Any]
			let networkHeaders = try JSONSerialization.jsonObject(
				with: try network.encoder.encode(network.headers)) as! [String: Any]
			let allHeaders = requestHeaders.merging(networkHeaders) { (requestHeader, _) in requestHeader }

			for header in allHeaders {
				urlRequest.setValue("\(header.value)", forHTTPHeaderField: header.key)
			}

			return URLSession.shared.dataTaskPublisher(for: urlRequest)
				.tryMap { (data: Data, response: URLResponse) -> Response in
					guard let httpResponse = response as? HTTPURLResponse else {
						throw NetworkError<N.RemoteError>.local(.invalidURLResponse(response))
					}

					guard 200..<300 ~= httpResponse.statusCode else {
						throw NetworkError.remote(try network.remoteError(for: httpResponse, data: data))
					}

					return try self.response(on: network, for: data)
			}
			.mapError(NetworkError<N.RemoteError>.init)
			.eraseToAnyPublisher()

		} catch {
			return Result.failure(NetworkError<N.RemoteError>(error))
				.publisher.eraseToAnyPublisher()
		}
	}
}

public extension NetworkRequest where Response: Decodable {

	func response<N: Network>(on network: N, for data: Data) throws -> Response {
		return try network.decoder.decode(Response.self, from: data)
	}
}

public extension NetworkRequest where Response == Data {

	func response<N: Network>(on network: N, for data: Data) throws -> Response {
		return data
	}
}

public extension NetworkRequest where Response == UIImage {

	func response<N: Network>(on network: N, for data: Data) throws -> Response {
		guard let image = UIImage(data: data) else {
			throw NetworkError<N.RemoteError>.local(.invalidImageData(data))
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
