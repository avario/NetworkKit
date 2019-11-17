import Foundation
import Combine
import UIKit

public class PreviewAssetDataProvider: NetworkDataProvider {
    public init() { }

    public func dataPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        guard let url = request.url else {
            fatalError()
        }

        guard let data = Self.previewData(at: url) else {
            print("⚠️ Preview asset not found for: \(url.absoluteString)")
            return Result.failure(URLError(.cannotLoadFromNetwork)).publisher.eraseToAnyPublisher()
        }

        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        return Result.success((data, response)).publisher.eraseToAnyPublisher()
    }

    static func previewData(at url: URL) -> Data? {
        var assetName = url.absoluteString
        if let scheme = url.scheme {
            assetName = assetName.replacingOccurrences(of: "\(scheme)://", with: "")
        }

        guard assetName.isEmpty == false else {
            return nil
        }

        if let data = NSDataAsset(name: assetName)?.data {
            return data
        }

        if let image = UIImage(named: assetName),
            let data = image.pngData() {
            return data
        }

        let nextURL: URL

        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        if var queryItems = urlComponents.queryItems,
            queryItems.isEmpty == false {
            queryItems.removeLast()

            if queryItems.isEmpty {
                urlComponents.queryItems = nil
            } else {
                urlComponents.queryItems = queryItems
            }

            guard let componentsURL = urlComponents.url else {
                return nil
            }

            nextURL = componentsURL

        } else {
            nextURL = url.deletingLastPathComponent()
        }

        return previewData(at: nextURL)
    }
}

public extension NetworkRequest where Response: Decodable {

    func preview<N: Network>(on network: N.Type) -> Response {
        var url = N.baseURL.appendingPathComponent(path)

        switch encoding {
        case .url:
            let requestParameters = try! JSONSerialization.jsonObject(
            with: try! N.encoder.encode(parameters)) as! [String: Any]

            guard requestParameters.isEmpty == false else {
                break
            }

            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = requestParameters.map { parameter in
                URLQueryItem(name: parameter.key, value: "\(parameter.value)")
            }

            url = urlComponents.url!

        case .json:
            break
        }

        guard let data = PreviewAssetDataProvider.previewData(at: url) else {
            fatalError("⚠️ Preview asset not found for: \(url.absoluteString)")
        }

        return try! N.decoder.decode(Response.self, from: data)
    }
}
