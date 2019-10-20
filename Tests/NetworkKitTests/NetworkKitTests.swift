import XCTest
@testable import NetworkKit

final class NetworkKitTests: XCTestCase {
	
	class MoviesNetwork: Network {		

		let baseURL: URL = URL(string: "https://api.themoviedb.org/3/")!
		let persistentParameters: APICredentials = .init(apiKey: "7141478ba63e445f5cc58583ed4bbb45")

		let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy =
			.formatted({
				let formatter = DateFormatter()
				formatter.dateFormat = "yyyy-MM-dd"
				return formatter
			}())
		
		struct APICredentials: Encodable {
			let apiKey: String
			
			enum CodingKeys: String, CodingKey {
				case apiKey = "api_key"
			}
		}
	}
	
	struct FetchPopularMovies: DecodableNetworkRequest {

		let method: HTTPMethod = .get
		let path: String = "discover/movie"
		let parameters: Parameters

		init(sortBy: String =  "popularity.desc") {
			parameters = Parameters(sortBy: sortBy)
		}

		struct Parameters: Encodable {
			let sortBy: String

			enum CodingKeys: String, CodingKey {
				case sortBy = "sort_by"
			}
		}

		struct Response: Decodable {
			let page: Int
			let results: [MovieSummary]
			
			struct MovieSummary: Decodable {

				let id: Int
				let title: String
				private let rating: Double
				private let backdropPath: String?

				enum CodingKeys: String, CodingKey {
					case id
					case title
					case backdropPath = "backdrop_path"
					case rating = "vote_average"
				}

			}
		}
	}

    struct FetchMovieDetails: DecodableNetworkRequest {
		
		let method: HTTPMethod = .get
		let path: String

		init(movieID: Int) {
			path = "movie/" + String(movieID)
		}

		struct Response: Decodable {
			
			let id: Int
			let title: String
			let releaseDate: Date
			let genres: [Genre]
			let overview: String
			let rating: Double

			enum CodingKeys: String, CodingKey {
				case id
				case title
				case releaseDate = "release_date"
				case genres
				case overview
				case rating = "vote_average"
			}

			struct Genre: Codable {
				let id: Int
				let name: String
			}
		}
	}
	
	var moviesNetwork: MoviesNetwork!
	
	override func setUp() {
		moviesNetwork = .init()
	}
	
	func testFetchMovieDetails() {
		
		let expection = expectation(description: "Fetch Movie Details")
		
		var response: FetchMovieDetails.Response?
		
		_ = moviesNetwork
			.decodableRequest(FetchMovieDetails(movieID: 301528))
			.sink(receiveCompletion: { (completion) in
				
			}) { (value) in
				response = value
				expection.fulfill()
		}
		
		wait(for: [expection], timeout: 10.0)
		
		XCTAssertNotNil(response)
		XCTAssertEqual(response!.title, "Toy Story 4")
	}
	
	func testFetchPopularMovies() {
		
		let expection = expectation(description: "Fetch Movie Details")
		
		var response: FetchPopularMovies.Response?
		
		_ = moviesNetwork
			.decodableRequest(FetchPopularMovies())
			.sink(receiveCompletion: { (completion) in
				
			}) { (value) in
				response = value
				expection.fulfill()
		}
		
		wait(for: [expection], timeout: 10.0)
		
		XCTAssertNotNil(response)
		XCTAssertFalse(response!.results.isEmpty)
	}
	
}
