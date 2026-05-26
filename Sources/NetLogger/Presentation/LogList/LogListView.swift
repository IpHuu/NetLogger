import SwiftUI

struct LogListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LogListViewModel
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Chips
                filterChips
                
                if viewModel.groupedLogs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No logs found")
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.groupedLogs, id: \.0) { group in
                            Section(header: Text(group.0).foregroundColor(.gray).bold()) {
                                ForEach(group.1) { log in
                                    NavigationLink(destination: LogDetailView(log: log)) {
                                        LogListRowView(log: log)
                                    }
                                    .listRowBackground(Color(red: 0.12, green: 0.12, blue: 0.14))
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("NetScanner Pro")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "Search logs...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { viewModel.clearLogs() }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(.systemGreen)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.09))
            .sheet(isPresented: $showingSettings) {
                FiltersAndSettingsView(
                    viewModel: NetLoggerDI.shared.makeLogSettingsViewModel(),
                    listViewModel: viewModel
                )
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var filterChips: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(LogListViewModel.LogTypeChip.allCases, id: \.self) { chip in
                        let isSelected = viewModel.selectedChip == chip
                        Button(action: {
                            withAnimation {
                                viewModel.selectedChip = chip
                            }
                        }) {
                            Text(chip.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(isSelected ? Color.systemGreen : Color(white: 0.15))
                                .foregroundColor(isSelected ? .white : .gray)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
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
