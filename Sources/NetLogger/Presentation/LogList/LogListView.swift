import SwiftUI

struct LogListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LogListViewModel
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Inline premium filters row
                filtersHeader
                
                if viewModel.filteredLogs.isEmpty {
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
                        ForEach(viewModel.filteredLogs) { log in
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
            .searchable(text: $viewModel.searchText, prompt: "Tìm kiếm theo URL...")
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
                LogSettingsView(viewModel: NetLoggerDI.shared.makeLogSettingsViewModel())
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
                        ForEach(viewModel.methods, id: \.self) { method in
                            Button(method) { viewModel.selectedMethod = method }
                        }
                    } label: {
                        HStack {
                            Text("Method: \(viewModel.selectedMethod)")
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
                        ForEach(viewModel.statuses, id: \.self) { status in
                            Button(status) { viewModel.selectedStatus = status }
                        }
                    } label: {
                        HStack {
                            Text("Status: \(viewModel.selectedStatus)")
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
