import Combine
import Foundation

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

	func request<N: Network>(on network: N) -> AnyPublisher<Response, NetworkError<N.RemoteError>> {
		do {
			let url = network.baseURL.appendingPathComponent(path)
			var urlRequest: URLRequest

			switch encoding {
			case .url:
                let serializedParameters = try JSONSerialization.jsonObject(
                    with: try N.encoder.encode(parameters)) as! [String: Any]

				var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
				urlComponents.queryItems = serializedParameters.map { parameter in
					URLQueryItem(name: parameter.key, value: "\(parameter.value)")
				}

				urlRequest = URLRequest(url: urlComponents.url!)

			case .json:
				urlRequest = URLRequest(url: url)
                urlRequest.httpBody = try JSONEncoder().encode(parameters)

            case .multipartFormData:
                let encoder = MultipartFormDataEncoder()
                urlRequest = URLRequest(url: url)
                urlRequest.setValue("multipart/form-data; boundary=\(encoder.boundary)", forHTTPHeaderField: "Content-Type")

                let data = try encoder.encode(parameters)
                urlRequest.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")

                urlRequest.httpBody = data
			}

			urlRequest.httpMethod = method.rawValue

			let requestHeaders = try JSONSerialization.jsonObject(
				with: try N.encoder.encode(headers)) as! [String: Any]
			let networkHeaders = try JSONSerialization.jsonObject(
				with: try N.encoder.encode(network.headers)) as! [String: Any]
			let allHeaders = requestHeaders.merging(networkHeaders) { requestHeader, _ in requestHeader }

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
		return try N.decoder.decode(Response.self, from: data)
	}
}

public extension NetworkRequest where Response == Data {
	func response<N: Network>(on network: N, for data: Data) throws -> Response {
		return data
	}
}

public enum ParameterEncoding {
	case url
	case json
    case multipartFormData
}

public enum HTTPMethod: String {
	case delete
	case get
	case head
	case post
	case put
}
