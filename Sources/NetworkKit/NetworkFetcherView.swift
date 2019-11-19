import SwiftUI

public struct NetworkFetcherView<R: NetworkRequest, F: NetworkFetcher<R>, LoadingView: View, ErrorView: View, FetchedView: View>: View {
	public let body: AnyView

	public init(state: F.State, @ViewBuilder loading: () -> LoadingView, @ViewBuilder error: (NetworkError<R.Network.RemoteError>) -> ErrorView, @ViewBuilder fetched: (R.Response) -> FetchedView) {
		switch state {
		case .loading:
			body = AnyView(loading())
		case .error(let requestError):
			body = AnyView(error(requestError))
		case .fetched(let response):
			body = AnyView(fetched(response))
		}
	}
}
