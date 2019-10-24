import Foundation

public enum NetworkError<T>: Error {

	case local(LocalError)
	case remote(T)

	public enum LocalError {
		case invalidURLResponse(URLResponse)
		case invalidImageData(Data)

		case decodingError(DecodingError)
		case encodingError(EncodingError)
		
		case unknown(Error)
	}

	public init(_ error: Error) {
		if let error = error as? Self {
			self = error
			return
		}

		switch error {
		case let decodingError as DecodingError:
			self = .local(.decodingError(decodingError))

		case let encodingError as EncodingError:
			self = .local(.encodingError(encodingError))

		default:
			self = .local(.unknown(error))
		}
	}
}
