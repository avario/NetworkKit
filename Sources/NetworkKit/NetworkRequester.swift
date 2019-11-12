import Foundation
import Combine

public protocol NetworkRequester {
	func perform<R: NetworkRequest, N: Network>(request: R, network: N) -> AnyPublisher<R.Response, NetworkError<N.RemoteError>>
}

extension URLSession: NetworkRequester {

	public func perform<R: NetworkRequest, N: Network>(request: R, network: N) -> AnyPublisher<R.Response, NetworkError<N.RemoteError>> {
		do {
			let url = network.baseURL.appendingPathComponent(request.path)

			let requestParameters = try JSONSerialization.jsonObject(
				with: try N.encoder.encode(request.parameters)) as! [String: Any]
			let networkParameters = try JSONSerialization.jsonObject(
				with: try N.encoder.encode(network.parameters)) as! [String: Any]
			let allParameters = requestParameters.merging(networkParameters) { (requestParameter, _) in requestParameter }

			var urlRequest: URLRequest

			switch request.encoding {
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

			urlRequest.httpMethod = request.method.rawValue

			let requestHeaders = try JSONSerialization.jsonObject(
				with: try N.encoder.encode(request.headers)) as! [String: Any]
			let networkHeaders = try JSONSerialization.jsonObject(
				with: try N.encoder.encode(network.headers)) as! [String: Any]
			let allHeaders = requestHeaders.merging(networkHeaders) { (requestHeader, _) in requestHeader }

			for header in allHeaders {
				urlRequest.setValue("\(header.value)", forHTTPHeaderField: header.key)
			}

			return self.dataTaskPublisher(for: urlRequest)
				.tryMap { (data: Data, response: URLResponse) -> R.Response in
					guard let httpResponse = response as? HTTPURLResponse else {
						throw NetworkError<N.RemoteError>.local(.invalidURLResponse(response))
					}

					guard 200..<300 ~= httpResponse.statusCode else {
						throw NetworkError.remote(try network.remoteError(for: httpResponse, data: data))
					}

					return try request.response(for: data)
			}
			.mapError(NetworkError<N.RemoteError>.init)
			.eraseToAnyPublisher()

		} catch {
			return Result.failure(NetworkError<N.RemoteError>(error))
				.publisher.eraseToAnyPublisher()
		}
	}
}
