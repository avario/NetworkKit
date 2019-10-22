
import Foundation
import UIKit

public enum NetworkPreviewMode {

    case automatic
    case success
    case loading
    case failure(error: Error? = nil)
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

public extension Network {

    func preview(mode: NetworkPreviewMode) -> Self {
        NetworkPreviewMode[for: self] = mode
        return self
    }
}

public extension NetworkRequest {

    func previewAssetName<N: Network>(on network: N) -> String {
        let url = network.baseURL.appendingPathComponent(path)
        var previewAssetName = url.absoluteString
        if let scheme = url.scheme {
            previewAssetName = previewAssetName.replacingOccurrences(of: scheme, with: "").replacingOccurrences(of: "://", with: "")
        }

        return previewAssetName
    }
}

public extension NetworkRequest where Response: Decodable {

    func preview<N: Network>(on network: N) throws -> Response {
        let assetName = previewAssetName(on: network)

        guard let data = NSDataAsset(name: assetName)?.data else {
            print("⚠️ Data preview asset not found with name: \(assetName)")
            throw NetworkError<N.ErrorContent>.local(.previewAssetNotFound(assetName))
        }

        return try network.decoder.decode(Response.self, from: data)
    }
}

public extension NetworkRequest where Response == Data {

    func preview<N: Network>(on network: N) throws -> Response {
        let assetName = previewAssetName(on: network)

        guard let data = NSDataAsset(name: assetName)?.data else {
            print("⚠️ Data preview asset not found with name: \(assetName)")
            throw NetworkError<N.ErrorContent>.local(.previewAssetNotFound(assetName))
        }

        return data
    }
}

public extension NetworkRequest where Response == UIImage {

    func preview<N: Network>(on network: N) throws -> Response {
        let assetName = previewAssetName(on: network)

        guard let image = UIImage(named: assetName) else {
            print("⚠️ Image preview asset not found with name: \(assetName)")
            throw NetworkError<N.ErrorContent>.local(.previewAssetNotFound(assetName))
        }

        return image
    }
}
