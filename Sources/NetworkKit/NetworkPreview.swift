
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

extension DecodableNetworkRequest {

    func preview<N: Network>(from network: N) throws -> Response {
        let url = network.baseURL.appendingPathComponent(path)
        let previewData = try Session.shared.preview(for: url)

        return try network.decoder.decode(Response.self, from: previewData)
    }
}
