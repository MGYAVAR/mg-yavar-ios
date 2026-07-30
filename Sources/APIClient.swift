import Foundation

actor APIClient {
    static let shared = APIClient()
    private let base = "http://100.71.88.40:8788"
    
    func fetch<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: base + path) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        return try JSONDecoder().decode(T.self, from: data)
    }
}
