
import Foundation

public protocol DecodableNetworkRequest: DataNetworkRequest {

	associatedtype Response: Decodable = EmptyResponse
}

public struct EmptyResponse: Encodable { }
