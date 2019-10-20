
import Foundation

public enum NetworkError: Error {
	case unknown
	
	public init(error: Error) {
        if let error = error as? NetworkError {
            self = error
        }

		self = .unknown
	}
}
