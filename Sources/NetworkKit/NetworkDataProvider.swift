import Foundation
import Combine

public protocol NetworkDataProvider {
	func dataPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError>
}

extension URLSession: NetworkDataProvider {
    public func dataPublisher(for request: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), URLError> {
        return dataTaskPublisher(for: request).eraseToAnyPublisher()
    }
}
