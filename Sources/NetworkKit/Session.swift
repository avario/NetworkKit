//
//  Created by Avario Babushka on 21/10/19.
//

import Foundation
import Combine

public class Session {

    static public let shared = Session()
    private init() { }

    public struct DataRequest {
        let url: URL
        let method: HTTPMethod
        let parameters: [String: Any]
        let encoding: ParameterEncoding
        let headers: [String: Any]
    }

    public func request(_ request: DataRequest) -> AnyPublisher<Data, NetworkError> {
        do {
            var urlRequest: URLRequest

            switch request.encoding {
            case .url:
                var urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false)!
                urlComponents.queryItems = request.parameters.map { parameter in
                    URLQueryItem(name: parameter.key, value: "\(parameter.value)")
                }

                urlRequest = URLRequest(url: urlComponents.url!)

            case .json:
                urlRequest = URLRequest(url: request.url)
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request.parameters)
            }

            urlRequest.httpMethod = request.method.rawValue

            for header in request.headers {
                urlRequest.setValue("\(header.value)", forHTTPHeaderField: header.key)
            }

            return URLSession.shared.dataTaskPublisher(for: urlRequest)
                .map { $0.data }
                .mapError(NetworkError.init)
                .eraseToAnyPublisher()

        } catch {
            return Result.failure(NetworkError.init(error: error))
                .publisher.eraseToAnyPublisher()
        }
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
