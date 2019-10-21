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

        public init(
            url: URL,
            method: HTTPMethod,
            parameters: [String : Any] = [:],
            encoding: ParameterEncoding = .url,
            headers: [String : Any] = [:]) {

            self.url = url
            self.method = method
            self.parameters = parameters
            self.encoding = encoding
            self.headers = headers
        }
    }

    public func request(_ request: DataRequest, previewMode: NetworkPreviewMode = .automatic) -> AnyPublisher<Data, NetworkError> {

        switch previewMode {
        case .automatic:
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != nil {
                fallthrough
            }
        case .success:
            do {
                return Result.success(try preview(for: request))
                    .publisher.eraseToAnyPublisher()
            } catch {
                return Result.failure(NetworkError(error: error))
                    .publisher.eraseToAnyPublisher()
            }
        case .loading:
            return PassthroughSubject<Data, NetworkError>()
                .eraseToAnyPublisher()

        case .failure(let error):
            return Result.failure(error)
                .publisher.eraseToAnyPublisher()

        case .noPreview:
            break
        }

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

    public func preview(for request: DataRequest) throws -> Data {

        var previewAssetName = request.url.absoluteString
        if let scheme = request.url.scheme {
            previewAssetName = previewAssetName.replacingOccurrences(of: scheme, with: "").replacingOccurrences(of: "://", with: "")
        }

        if let asset = NSDataAsset(name: previewAssetName) {
            return asset.data

        } else if let image = UIImage(named: previewAssetName) {
            return image.pngData()!

        } else {
            print("⚠️ No preview asset found with name: \(previewAssetName)")
            throw NetworkError.unknown
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
