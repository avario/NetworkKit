import Foundation
import Combine
import UIKit

protocol NetworkPreviewable {
    static func networkPreview() throws -> Self
}

public class PreviewNetworkRequester: NetworkRequester {

    public func perform<R: NetworkRequest, N: Network>(request: R, network: N) -> AnyPublisher<R.Response, NetworkError<N.RemoteError>> {
        do {
            guard let previewable = R.Response.self as? NetworkPreviewable else {
                throw NetworkPreviewError.previewAssetNotFound(assetName: request.path)
            }

            return Result.success(try type(of: previewable).networkPreview() as! R.Response)
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

extension Decodable: NetworkPreviewable {
    
}

extension Data: NetworkPreviewable {

}

//public extension NetworkRequest: PreviewableNetworkRequest where Response: Decodable {
//
//	func preview() throws -> Response {
//		guard let data = NSDataAsset(name: path)?.data else {
//			print("⚠️ Data preview asset not found with name: \(path)")
//			throw NetworkPreviewError.previewAssetNotFound(assetName: path)
//		}
//
//		return try Network.decoder.decode(Response.self, from: data)
//	}
//}
//
//public extension NetworkRequest: PreviewableNetworkRequest where Response == Data {
//
//	func preview() throws -> Response {
//		guard let data = NSDataAsset(name: path)?.data else {
//			print("⚠️ Data preview asset not found with name: \(path)")
//			throw NetworkPreviewError.previewAssetNotFound(assetName: path)
//		}
//
//		return data
//	}
//}
//
//public extension NetworkRequest: PreviewableNetworkRequest where Response == UIImage {
//
//	func preview() throws -> Response {
//		guard let image = UIImage(named: path) else {
//			print("⚠️ Image preview asset not found with name: \(path)")
//			throw NetworkPreviewError.previewAssetNotFound(assetName: path)
//		}
//
//		return image
//	}
//}
