
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

public extension Network {

    func preview(mode: NetworkPreviewMode) -> Self {
        NetworkPreviewMode[for: self] = mode
        return self
    }
}

public extension NetworkRequest where Response: Decodable {

    func preview<N: Network>(from network: N) throws -> Response {
        let previewData = try NetworkKit.preview(for: self.asURLRequest(on: network))
        return try network.decoder.decode(Response.self, from: previewData)
    }
}

public extension NetworkRequest where Response == Data {

    func preview<N: Network>(from network: N) throws -> Data {
        return try NetworkKit.preview(for: self.asURLRequest(on: network))
    }
}
