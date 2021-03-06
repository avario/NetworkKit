import Foundation

public enum NetworkError<T>: Error {
	case local(LocalError)
	case remote(T)

	public enum LocalError {
		case invalidURLResponse(URLResponse)
		case invalidImageData(Data)

		case decodingError(DecodingError)
		case encodingError(EncodingError)

		case timeout

		case unknown(Error)
	}

	public init(_ error: Error) {
		if let error = error as? Self {
			self = error
			return
		}

		switch error {
		case let remoteError as T:
			self = .remote(remoteError)

		case let decodingError as DecodingError:
			self = .local(.decodingError(decodingError))

		case let encodingError as EncodingError:
			self = .local(.encodingError(encodingError))

		default:
			self = .local(.unknown(error))
		}
	}
}
