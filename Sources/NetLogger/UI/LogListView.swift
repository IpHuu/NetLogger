import SwiftUI

struct LogListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var realmManager = LogRealmManager.shared
    
    @State private var searchText = ""
    @State private var selectedMethod = "ALL"
    @State private var selectedStatus = "ALL"
    @State private var showingSettings = false
    
    private let methods = ["ALL", "GET", "POST", "PUT", "DELETE"]
    private let statuses = ["ALL", "SUCCESS", "REDIRECT", "CLIENT ERROR", "SERVER ERROR", "PENDING"]
    
    private var filteredLogs: [NetworkLog] {
        realmManager.logs.filter { log in
            // Search text filter
            let matchesSearch = searchText.isEmpty || 
                log.url.localizedCaseInsensitiveContains(searchText) || 
                log.method.localizedCaseInsensitiveContains(searchText)
            
            // Method filter
            let matchesMethod = selectedMethod == "ALL" || log.method.uppercased() == selectedMethod
            
            // Status filter
            let matchesStatus: Bool
            if selectedStatus == "ALL" {
                matchesStatus = true
            } else {
                guard let code = log.statusCode else {
                    matchesStatus = selectedStatus == "PENDING"
                    return matchesSearch && matchesMethod && matchesStatus
                }
                switch selectedStatus {
                case "SUCCESS":
                    matchesStatus = (200...299).contains(code)
                case "REDIRECT":
                    matchesStatus = (300...399).contains(code)
                case "CLIENT ERROR":
                    matchesStatus = (400...499).contains(code)
                case "SERVER ERROR":
                    matchesStatus = (500...599).contains(code)
                default:
                    matchesStatus = false
                }
            }
            
            return matchesSearch && matchesMethod && matchesStatus
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Inline premium filters row
                filtersHeader
                
                if filteredLogs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "icloud.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Không tìm thấy kết quả nào")
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredLogs) { log in
                            NavigationLink(destination: LogDetailView(log: log)) {
                                LogListRowView(log: log)
                            }
                            .listRowBackground(Color(red: 0.12, green: 0.12, blue: 0.14))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("NetLogger API Console")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Tìm kiếm theo URL...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.systemGreen)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                    .foregroundColor(.systemGreen)
                }
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.09))
            .sheet(isPresented: $showingSettings) {
                LogSettingsView()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var filtersHeader: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Method Filter
                    Menu {
                        ForEach(methods, id: \.self) { method in
                            Button(method) { selectedMethod = method }
                        }
                    } label: {
                        HStack {
                            Text("Method: \(selectedMethod)")
                            Image(systemName: "chevron.down")
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.15))
                        .cornerRadius(8)
                        .foregroundColor(.primary)
                    }
                    
                    // Status Filter
                    Menu {
                        ForEach(statuses, id: \.self) { status in
                            Button(status) { selectedStatus = status }
                        }
                    } label: {
                        HStack {
                            Text("Status: \(selectedStatus)")
                            Image(systemName: "chevron.down")
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.15))
                        .cornerRadius(8)
                        .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(red: 0.12, green: 0.12, blue: 0.14))
            
            Divider()
                .background(Color(white: 0.15))
        }
    }
}

// Global Color extension for NetLogger UI styling
extension Color {
    static let systemGreen = Color(red: 0.15, green: 0.70, blue: 0.35)
}
