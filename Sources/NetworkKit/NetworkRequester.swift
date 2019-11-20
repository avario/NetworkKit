import Combine
import Foundation

public class NetworkRequester<R: NetworkRequest>: ObservableObject {
	public enum State {
		case loading
		case failure(NetworkError<R.Network.RemoteError>)
		case success(R.Response)
	}

	@Published public var state: State = .loading

	public var isLoading: Bool {
		if case .loading = state {
			return true
		} else {
			return false
		}
	}

	public var error: Error? {
		if case let .failure(error) = state {
			return error
		} else {
			return nil
		}
	}

	public var response: R.Response? {
		if case let .success(response) = state {
			return response
		} else {
			return nil
		}
	}

	public init() {}

	public func request(_ request: R, on network: R.Network) {
		cancellable = request
			.request(on: network)
			.map { .success($0) }
			.catch { error -> Just<State> in
				Just(.failure(error))
			}
			.receive(on: DispatchQueue.main)
			.assign(to: \.state, on: self)
	}

	private var cancellable: Cancellable?
}
