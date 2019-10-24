import Foundation
import UIKit

#if DEBUG

public enum NetworkPreviewMode {
	
	case automatic
	case always
	case never
	
	static var modes: [ObjectIdentifier: NetworkPreviewMode] = .init()
}

public extension Network {

	func preview(_ previewMode: NetworkPreviewMode) -> Self {
		NetworkPreviewMode.modes[ObjectIdentifier(self)] = previewMode
		return self
	}
}

public extension NetworkRequest {
	
	func previewAssetName<N: Network>(on network: N) -> String {
		let url = network.baseURL.appendingPathComponent(path)
		var previewAssetName = url.absoluteString
		if let scheme = url.scheme {
			previewAssetName = previewAssetName.replacingOccurrences(of: "\(scheme)://", with: "")
		}
		
		return previewAssetName
	}
}

enum NetworkPreviewError: Error {
	case previewAssetNotFound(assetName: String)
}

public extension NetworkRequest where Response: Decodable {
	
	func preview<N: Network>(on network: N) throws -> Response {
		let assetName = previewAssetName(on: network)
		
		guard let data = NSDataAsset(name: assetName)?.data else {
			print("⚠️ Data preview asset not found with name: \(assetName)")
			throw NetworkPreviewError.previewAssetNotFound(assetName: assetName)
		}
		
		return try network.decoder.decode(Response.self, from: data)
	}
}

public extension NetworkRequest where Response == Data {
	
	func preview<N: Network>(on network: N) throws -> Response {
		let assetName = previewAssetName(on: network)
		
		guard let data = NSDataAsset(name: assetName)?.data else {
			print("⚠️ Data preview asset not found with name: \(assetName)")
			throw NetworkPreviewError.previewAssetNotFound(assetName: assetName)
		}
		
		return data
	}
}

public extension NetworkRequest where Response == UIImage {
	
	func preview<N: Network>(on network: N) throws -> Response {
		let assetName = previewAssetName(on: network)
		
		guard let image = UIImage(named: assetName) else {
			print("⚠️ Image preview asset not found with name: \(assetName)")
			throw NetworkPreviewError.previewAssetNotFound(assetName: assetName)
		}
		
		return image
	}
}

#endif
