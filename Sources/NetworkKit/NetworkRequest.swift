import Combine
import Foundation

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
	func response(on network: Network, for data: Data) throws -> Response

	associatedtype Requester = NetworkRequester<Self>
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

	func request(on network: Network) -> AnyPublisher<Response, NetworkError<Network.RemoteError>> {
		do {
			let url = network.baseURL.appendingPathComponent(path)

			let requestParameters = try JSONSerialization.jsonObject(
				with: try Network.encoder.encode(parameters)) as! [String: Any]
			let networkParameters = try JSONSerialization.jsonObject(
				with: try Network.encoder.encode(network.parameters)) as! [String: Any]
			let allParameters = requestParameters.merging(networkParameters) { requestParameter, _ in requestParameter }

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
				with: try Network.encoder.encode(headers)) as! [String: Any]
			let networkHeaders = try JSONSerialization.jsonObject(
				with: try Network.encoder.encode(network.headers)) as! [String: Any]
			let allHeaders = requestHeaders.merging(networkHeaders) { requestHeader, _ in requestHeader }

			for header in allHeaders {
				urlRequest.setValue("\(header.value)", forHTTPHeaderField: header.key)
			}

			return URLSession.shared.dataTaskPublisher(for: urlRequest)
				.tryMap { (data: Data, response: URLResponse) -> Response in
					guard let httpResponse = response as? HTTPURLResponse else {
						throw NetworkError<Network.RemoteError>.local(.invalidURLResponse(response))
					}

					guard 200..<300 ~= httpResponse.statusCode else {
						throw NetworkError.remote(try network.remoteError(for: httpResponse, data: data))
					}

					return try self.response(on: network, for: data)
				}
				.mapError(NetworkError<Network.RemoteError>.init)
				.eraseToAnyPublisher()

		} catch {
			return Result.failure(NetworkError<Network.RemoteError>(error))
				.publisher.eraseToAnyPublisher()
		}
	}
}

public extension NetworkRequest where Response: Decodable {
	func response(on network: Network, for data: Data) throws -> Response {
		return try Network.decoder.decode(Response.self, from: data)
	}
}

public extension NetworkRequest where Response == Data {
	func response(on network: Network, for data: Data) throws -> Response {
		return data
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
