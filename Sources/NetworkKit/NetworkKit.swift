//
//  Created by Avario Babushka on 21/10/19.
//

import Foundation
import Combine
import UIKit

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

public struct EmptyEncodable: Encodable { }

public func request(_ request: URLRequest, previewMode: NetworkPreviewMode = .automatic) -> AnyPublisher<Data, NetworkError> {

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

    return URLSession.shared.dataTaskPublisher(for: request)
        .map { $0.data }
        .mapError(NetworkError.init)
        .eraseToAnyPublisher()
}

public func preview(for request: URLRequest) throws -> Data {

    guard let url = request.url else {
        throw NetworkError.unknown
    }

    var previewAssetName = url.absoluteString
    if let scheme = url.scheme {
        previewAssetName = previewAssetName.replacingOccurrences(of: scheme, with: "").replacingOccurrences(of: "://", with: "")
    }

    if let asset = NSDataAsset(name: previewAssetName) {
        return asset.data

    } else if let image = UIImage(named: previewAssetName),
        let imageData = image.pngData() {
        return imageData

    } else {
        print("⚠️ No preview asset found with name: \(previewAssetName)")
        throw NetworkError.unknown
    }
}
