
import Foundation
import Combine
import UIKit

public protocol Network: AnyObject {

	var baseURL: URL { get }

	var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { get }
	var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { get }

	var persistentParameters: PersistentParameters { get }
	associatedtype PersistentParameters: Encodable = EmptyEncodable

	var persistentHeaders: PersistentHeaders { get }
	associatedtype PersistentHeaders: Encodable = EmptyEncodable
}

public struct EmptyEncodable: Encodable { }

public extension Network {

	var dateEncodingStrategy: JSONEncoder.DateEncodingStrategy { .deferredToDate }
	var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy { .deferredToDate  }

	var persistentParameters: EmptyEncodable { EmptyEncodable() }
	var persistentHeaders: EmptyEncodable { EmptyEncodable() }

	var previewMode: NetworkPreviewMode { return NetworkPreviewMode[for: self] }
}

public extension Network {

	internal var decoder: JSONDecoder {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = dateDecodingStrategy
		return decoder
	}

	internal var encoder: JSONEncoder {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = dateEncodingStrategy
		return encoder
	}

	func decodableRequest<R: DecodableNetworkRequest>(_ request: R, previewMode: NetworkPreviewMode? = nil) -> AnyPublisher<R.Response, NetworkError> {

		return dataRequest(request, previewMode: previewMode)
			.decode(
				type: R.Response.self,
				decoder: decoder)
			.mapError(NetworkError.init)
			.eraseToAnyPublisher()
	}

	func dataRequest<R: DataNetworkRequest>(_ request: R) -> AnyPublisher<Data, NetworkError> {
		do {
			let parametersData = try encoder.encode(request.parameters)
			let parametersDictionary = try JSONSerialization.jsonObject(with: parametersData) as! [String: Any]
			
			let persistentParametersData = try encoder.encode(persistentParameters)
			let persistentParametersDictionary = try JSONSerialization.jsonObject(with: persistentParametersData) as! [String: Any]
			
			let allParameters = parametersDictionary.merging(persistentParametersDictionary) { (_, persistent) in persistent }

			let headersData = try encoder.encode(request.headers)
			let headersDictionary = try JSONSerialization.jsonObject(with: headersData) as! [String: Any]

			let persistentHeadersData = try encoder.encode(persistentHeaders)
			let persistentHeadersDictionary = try JSONSerialization.jsonObject(with: persistentHeadersData) as! [String: Any]

			let allHeaders = headersDictionary.merging(persistentHeadersDictionary) { (_, persistent) in persistent }

			let dataRequest = Session.DataRequest(
				url: baseURL.appendingPathComponent(request.path),
				method: request.method,
				parameters: allParameters,
				encoding: request.encoding,
				headers: allHeaders)

            return Session.shared.request(dataRequest, previewMode: previewMode)
			
		} catch {
			return Result.failure(NetworkError.init(error: error))
				.publisher.eraseToAnyPublisher()
		}
	}
}
