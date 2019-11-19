import Combine
import Foundation

public class NetworkFetcher<R: NetworkRequest>: ObservableObject {
	public enum State {
		case loading
		case error(NetworkError<R.Network.RemoteError>)
		case fetched(R.Response)
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
		if case let .error(error) = state {
			return error
		} else {
			return nil
		}
	}

	public var response: R.Response? {
		if case let .fetched(response) = state {
			return response
		} else {
			return nil
		}
	}

	public init() {}

	public func fetch(_ request: R, on network: R.Network) {
		cancellable = request
			.request(on: network)
			.map { .fetched($0) }
			.catch { error -> Just<State> in
				Just(.error(error))
			}
			.receive(on: DispatchQueue.main)
			.assign(to: \.state, on: self)
	}

	private var cancellable: Cancellable?
}
