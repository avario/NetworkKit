
import Foundation
import UIKit

public enum NetworkPreviewMode {

    case automatic
    case success
    case loading
    case failure(error: NetworkError)
    case noPreview

    private static var networkPreviewModes: [ObjectIdentifier: NetworkPreviewMode] = .init()

    public static subscript<N: Network>(for network: N) -> NetworkPreviewMode {
        get {
            return networkPreviewModes[ObjectIdentifier(network)] ?? .automatic
        }
        set(newValue) {
            networkPreviewModes[ObjectIdentifier(network)] = newValue
        }
    }
}

extension Network {

    func preview(mode: NetworkPreviewMode) -> Self {
        NetworkPreviewMode[for: self] = mode
        return self
    }
}

public extension DataNetworkRequest {

    func dataPreview<N: Network>(from network: N) throws -> Data {

		let previewAssetName = self.previewAssetName(for: network)

        if let asset = NSDataAsset(name: previewAssetName) {
            return asset.data

        } else if let image = UIImage(named: previewAssetName) {
            return image.pngData()!

        } else {
            print("⚠️ No preview asset with name: \(previewAssetName)")
            throw NetworkError.unknown
        }
    }
}

extension DecodableNetworkRequest {

    func decodedPreview<N: Network>(from network: N) throws -> Response {
		let previewData = try self.dataPreview(from: network)
        return try network.decoder.decode(Response.self, from: previewData)
    }
}
