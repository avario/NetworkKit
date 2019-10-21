
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
}

public extension NetworkRequest {

    func asURLRequest<N: Network>(on network: N) throws -> URLRequest {

        let url = network.baseURL.appendingPathComponent(path)

        let requestParameters = try JSONSerialization.jsonObject(
            with: try network.encoder.encode(parameters)) as! [String: Any]
        let persistentParameters = try JSONSerialization.jsonObject(
            with: try network.encoder.encode(network.persistentParameters)) as! [String: Any]
        let allParameters = requestParameters.merging(persistentParameters) { (_, persistent) in persistent }

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
        let persistentHeaders = try JSONSerialization.jsonObject(
            with: try network.encoder.encode(network.persistentHeaders)) as! [String: Any]
        let allHeaders = requestHeaders.merging(persistentHeaders) { (_, persistent) in persistent }

        for header in allHeaders {
            urlRequest.setValue("\(header.value)", forHTTPHeaderField: header.key)
        }

        return urlRequest
    }
}
