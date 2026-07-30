import SwiftUI

@main
struct MGYavarApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            PortfolioView().tabItem { Label("Portfolio", systemImage: "chart.pie.fill") }
            SignalsView().tabItem { Label("Signals", systemImage: "waveform.path.ecg") }
            BracketsView().tabItem { Label("Brackets", systemImage: "shield.fill") }
            SettingsView().tabItem { Label("Settings", systemImage: "gear") }
        }.tint(.green)
    }
}

// MARK: - Models

struct PortfolioResponse: Decodable {
    let balances: Balances?
    let positionsList: [Position]
    
    enum CodingKeys: String, CodingKey {
        case balances
        case positions
    }
    
    enum PositionsCodingKeys: String, CodingKey {
        case data = "Data"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        balances = try container.decodeIfPresent(Balances.self, forKey: .balances)
        // Custom decode for positions with __count + Data structure
        if let positionsContainer = try? container.nestedContainer(keyedBy: PositionsCodingKeys.self, forKey: .positions) {
            positionsList = try positionsContainer.decodeIfPresent([Position].self, forKey: .data) ?? []
        } else {
            positionsList = []
        }
    }
}

struct Balances: Decodable {
    let totalValue: Double?
    let cashAvailable: Double?
    enum CodingKeys: String, CodingKey {
        case totalValue = "TotalValue"
        case cashAvailable = "CollateralAvailable"
    }
}

struct Position: Decodable, Identifiable {
    var id: String = UUID().uuidString
    let symbol: String
    let amount: Double
    let pnl: Double
    
    enum CodingKeys: String, CodingKey {
        case display = "DisplayAndFormat"
        case base = "NetPositionBase"
        case view = "NetPositionView"
    }
    
    enum DisplayKeys: String, CodingKey { case symbol = "Symbol" }
    enum BaseKeys: String, CodingKey { case amount = "Amount" }
    enum ViewKeys: String, CodingKey { case pnl = "ProfitLossOnTradeInBaseCurrency" }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let displayContainer = try container.nestedContainer(keyedBy: DisplayKeys.self, forKey: .display)
        symbol = try displayContainer.decode(String.self, forKey: .symbol)
        
        let baseContainer = try container.nestedContainer(keyedBy: BaseKeys.self, forKey: .base)
        amount = try baseContainer.decode(Double.self, forKey: .amount)
        
        let viewContainer = try container.nestedContainer(keyedBy: ViewKeys.self, forKey: .view)
        pnl = try viewContainer.decodeIfPresent(Double.self, forKey: .pnl) ?? 0
    }
}

struct SignalsResponse: Decodable {
    let topRadar: [RadarItem]?
    enum CodingKeys: String, CodingKey { case topRadar = "top_radar" }
}

struct RadarItem: Decodable, Identifiable {
    var id: String = UUID().uuidString
    let ticker: String
    let recClass: String?
    let score: Int?
    enum CodingKeys: String, CodingKey {
        case ticker
        case recClass = "rec_class"
        case score
    }
}

struct OrdersResponse: Decodable {
    let data: [Order]?
    enum CodingKeys: String, CodingKey { case data = "Data" }
}

struct Order: Decodable, Identifiable {
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

struct HealthResponse: Decodable { let status: String }

// MARK: - Portfolio
struct PortfolioView: View {
    @State private var items: [Position] = []
    @State private var totalValue: Double = 0
    @State private var loading = true
    @State private var err = ""
    
    var body: some View {
        NavigationStack {
            List {
                if loading { ProgressView() }
                if !err.isEmpty { Text(err).foregroundColor(.red).font(.caption) }
                Section("Account") { Text("€\(totalValue, specifier: "%.0f")").bold() }
                Section("Positions (\(items.count))") {
                    ForEach(items) { p in
                        HStack {
                            Text(p.symbol).bold()
                            Spacer()
                            Text("€\(p.pnl, specifier: "%.0f")").foregroundColor(p.pnl >= 0 ? .green : .red)
                        }
                    }
                }
            }.navigationTitle("Portfolio")
        }.task { await load() }
    }
    
    func load() async {
        loading = true; err = ""
        do {
            let r: PortfolioResponse = try await APIClient.shared.fetch("/portfolio")
            totalValue = r.balances?.totalValue ?? 0
            items = r.positionsList
        } catch {
            err = "\(error)"
            print("PORTFOLIO: \(error)")
        }
        loading = false
    }
}

// MARK: - Signals
struct SignalsView: View {
    @State private var items: [RadarItem] = []
    @State private var loading = true
    @State private var err = ""
    
    var body: some View {
        NavigationStack {
            List {
                if loading { ProgressView() }
                if !err.isEmpty { Text(err).foregroundColor(.red).font(.caption) }
                ForEach(items) { r in
                    HStack {
                        Text(r.ticker).bold()
                        Text(r.recClass ?? "").font(.caption).foregroundColor(.orange)
                        Spacer()
                        if let s = r.score { Text("\(s)").bold().foregroundColor(.blue) }
                    }
                }
            }.navigationTitle("Signals")
        }.task { await load() }
    }
    
    func load() async {
        loading = true; err = ""
        do {
            items = (try await APIClient.shared.fetch("/signals") as SignalsResponse).topRadar ?? []
        } catch {
            err = "\(error)"
            print("SIGNALS: \(error)")
        }
        loading = false
    }
}

// MARK: - Brackets
struct BracketsView: View {
    @State private var items: [Order] = []
    @State private var loading = true
    @State private var err = ""
    
    var body: some View {
        NavigationStack {
            List {
                if loading { ProgressView() }
                if !err.isEmpty { Text(err).foregroundColor(.red).font(.caption) }
                if items.isEmpty && !loading { Text("No open orders") }
                ForEach(items) { o in
                    HStack {
                        Text(o.type ?? "?").bold()
                        Spacer()
                        Text("x\(o.qty ?? 0, specifier: "%.0f") @ \(o.price ?? 0, specifier: "%.2f")")
                    }
                }
            }.navigationTitle("Brackets")
        }.task { await load() }
    }
    
    func load() async {
        loading = true; err = ""
        do {
            items = (try await APIClient.shared.fetch("/orders") as OrdersResponse).data ?? []
        } catch {
            err = "\(error)"
            print("ORDERS: \(error)")
        }
        loading = false
    }
}

// MARK: - Settings
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("API") { Text("http://100.71.88.40:8788").font(.caption).foregroundColor(.secondary) }
                Section("Connection") { Text("Backend ✓").foregroundColor(.green) }
            }.navigationTitle("Settings")
        }
    }
}
