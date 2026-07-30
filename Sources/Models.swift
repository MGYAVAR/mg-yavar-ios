import Foundation

struct PortfolioResponse: Codable {
    let balances: Balances?
    let positions: Positions?
}
struct Balances: Codable {
    let data: [BalanceItem]?
    enum CodingKeys: String, CodingKey { case data = "Data" }
}
struct BalanceItem: Codable {
    let totalValue: Double?
    enum CodingKeys: String, CodingKey { case totalValue = "TotalValue" }
}
struct Positions: Codable {
    let data: [Position]?
    enum CodingKeys: String, CodingKey { case data = "Data" }
}
struct Position: Codable, Identifiable {
    var id: String = UUID().uuidString
    let display: Display?
    let view: View?
    enum CodingKeys: String, CodingKey {
        case display = "DisplayAndFormat"
        case view = "NetPositionView"
    }
    struct Display: Codable { let symbol: String }
    struct View: Codable {
        let pnl: Double?
        enum CodingKeys: String, CodingKey { case pnl = "UnrealizedMarketValueInBaseCurrency" }
    }
}
struct SignalsResponse: Codable {
    let topRadar: [RadarItem]?
    enum CodingKeys: String, CodingKey { case topRadar = "top_radar" }
}
struct RadarItem: Codable, Identifiable {
    var id: String = UUID().uuidString
    let ticker: String
    let recClass: String?
    let score: Int?
    enum CodingKeys: String, CodingKey {
        case ticker
        case recClass = "recommendation_class"
        case score = "opportunity_score"
    }
}
struct OrdersResponse: Codable {
    let data: [Order]?
    enum CodingKeys: String, CodingKey { case data = "Data" }
}
struct Order: Codable, Identifiable {
    var id: String = UUID().uuidString
    let type: String?
    let price: Double?
    let qty: Double?
    enum CodingKeys: String, CodingKey {
        case type = "OpenOrderType"
        case price = "Price"
        case qty = "Amount"
    }
}
struct HealthResponse: Codable { let status: String }
