import Foundation
import Combine
import UIKit

public class PreviewNetworkRequester: NetworkRequester {

    public func perform<R: NetworkRequest, N: Network>(request: R, network: N) -> AnyPublisher<R.Response, NetworkError<N.RemoteError>> {
        do {
            return Result.success(try request.preview())
                .publisher.eraseToAnyPublisher()
        } catch {
            return Result.failure(NetworkError<N.RemoteError>(error))
                .publisher.eraseToAnyPublisher()
        }
    }
}

enum NetworkPreviewError: Error {
	case previewAssetNotFound(assetName: String)
}

public extension NetworkRequest where Response: Decodable {

	func preview() throws -> Response {
		guard let data = NSDataAsset(name: path)?.data else {
			print("⚠️ Data preview asset not found with name: \(path)")
			throw NetworkPreviewError.previewAssetNotFound(assetName: path)
		}

        return try Network.decoder.decode(Response.self, from: data)
	}
}

public extension NetworkRequest where Response == Data {

	func preview() throws -> Response {
		guard let data = NSDataAsset(name: path)?.data else {
			print("⚠️ Data preview asset not found with name: \(path)")
			throw NetworkPreviewError.previewAssetNotFound(assetName: path)
		}

		return data
	}
}

public extension NetworkRequest where Response == UIImage {

	func preview() throws -> Response {
		guard let image = UIImage(named: path) else {
			print("⚠️ Image preview asset not found with name: \(path)")
			throw NetworkPreviewError.previewAssetNotFound(assetName: path)
		}

		return image
	}
}
