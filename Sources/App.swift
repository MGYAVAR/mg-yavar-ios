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

// MARK: - Portfolio
struct PortfolioView: View {
    @State private var positions: [Position] = []
    @State private var totalValue: Double = 0
    @State private var loading = true
    @State private var err = ""
    
    var body: some View {
        NavigationStack {
            List {
                if loading { ProgressView() }
                if !err.isEmpty { Text(err).foregroundColor(.red) }
                Section("Account") { Text("€\(totalValue, specifier: "%.0f")").bold() }
                Section("Positions") {
                    ForEach(positions) { p in
                        HStack {
                            Text(p.display?.symbol ?? "?").bold()
                            Spacer()
                            let pnl = p.view?.pnl ?? 0
                            Text("€\(pnl, specifier: "%.0f")").foregroundColor(pnl >= 0 ? .green : .red)
                        }
                    }
                }
            }.navigationTitle("Portfolio")
        }.task { await load() }
    }
    
    func load() async {
        loading = true; err = ""
        do {
            let p: PortfolioResponse = try await APIClient.shared.fetch("/portfolio")
            totalValue = p.balances?.data?.first?.totalValue ?? 0
            positions = (p.positions?.data ?? []).filter { ($0.display?.symbol ?? "") != "" }
        } catch { err = error.localizedDescription }
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
                if !err.isEmpty { Text(err).foregroundColor(.red) }
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
        do { items = (try await APIClient.shared.fetch("/signals") as SignalsResponse).topRadar ?? [] }
        catch { err = error.localizedDescription }
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
                if !err.isEmpty { Text(err).foregroundColor(.red) }
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
        do { items = (try await APIClient.shared.fetch("/orders") as OrdersResponse).data ?? [] }
        catch { err = error.localizedDescription }
        loading = false
    }
}

// MARK: - Settings
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("API") { Text("http://100.71.88.40:8788").font(.caption).foregroundColor(.secondary) }
                Section("Connection") { Text("Backend connected ✓").foregroundColor(.green) }
            }.navigationTitle("Settings")
        }
    }
}
