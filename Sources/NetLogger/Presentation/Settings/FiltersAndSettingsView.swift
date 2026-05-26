import SwiftUI

struct FiltersAndSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LogSettingsViewModel
    @ObservedObject var listViewModel: LogListViewModel
    
    let methods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "HEAD"]
    let statusGroups = ["2xx", "3xx", "4xx", "5xx"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("FILTER BY METHOD")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                        ForEach(methods, id: \.self) { method in
                            Toggle(isOn: Binding(
                                get: { listViewModel.selectedMethods.contains(method) },
                                set: { isOn in
                                    if isOn {
                                        listViewModel.selectedMethods.insert(method)
                                    } else {
                                        listViewModel.selectedMethods.remove(method)
                                    }
                                }
                            )) {
                                Text(method).font(.system(.body, design: .monospaced))
                            }
                            .toggleStyle(CheckboxToggleStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("FILTER BY STATUS")) {
                    HStack(spacing: 8) {
                        ForEach(statusGroups, id: \.self) { group in
                            let isSelected = listViewModel.selectedStatusGroups.contains(group)
                            Button(action: {
                                if isSelected {
                                    listViewModel.selectedStatusGroups.remove(group)
                                } else {
                                    listViewModel.selectedStatusGroups.insert(group)
                                }
                            }) {
                                Text(group)
                                    .font(.caption.bold())
                                    .padding(.vertical, 6)
                                    .frame(maxWidth: .infinity)
                                    .background(isSelected ? Color.systemGreen : Color(white: 0.15))
                                    .foregroundColor(isSelected ? .white : .gray)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("LOG MANAGEMENT")) {
                    Toggle(isOn: Binding(
                        get: { viewModel.autoDeleteDays < 30 }, // Simple logic for toggle
                        set: { isOn in
                            viewModel.autoDeleteDays = isOn ? 7 : 30
                            viewModel.updateConfig()
                        }
                    )) {
                        VStack(alignment: .leading) {
                            Text("Auto-delete logs")
                            Text("Remove logs older than \(Int(viewModel.autoDeleteDays)) days")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Max log entries")
                            Spacer()
                            Text("\(Int(viewModel.maxEntries))")
                                .foregroundColor(.gray)
                        }
                        Slider(value: $viewModel.maxEntries, in: 100...5000, step: 100)
                            .onChange(of: viewModel.maxEntries) { _ in
                                viewModel.updateConfig()
                            }
                    }
                }
                
                Section(header: Text("SHAKE TO REPORT")) {
                    Toggle("Enable Shake Detector", isOn: Binding(
                        get: { viewModel.enableShake },
                        set: { viewModel.toggleShake($0) }
                    ))
                    
                    if viewModel.enableShake {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Sensitivity")
                                Spacer()
                                Text(sensitivityLabel)
                                    .foregroundColor(.gray)
                            }
                            Slider(value: $viewModel.shakeSensitivity, in: 0...2, step: 1)
                                .onChange(of: viewModel.shakeSensitivity) { _ in
                                    viewModel.updateConfig()
                                }
                            HStack {
                                Text("Low").font(.caption2).foregroundColor(.gray)
                                Spacer()
                                Text("High").font(.caption2).foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.systemGreen)
                        Text("NetLogger Pro")
                            .font(.headline)
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Powered by Clean Architecture & DI")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Filters & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(.systemGreen)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        listViewModel.selectedMethods.removeAll()
                        listViewModel.selectedStatusGroups.removeAll()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var sensitivityLabel: String {
        if viewModel.shakeSensitivity < 0.5 { return "LOW" }
        if viewModel.shakeSensitivity < 1.5 { return "MEDIUM" }
        return "HIGH"
    }
}

// Custom Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .systemGreen : .gray)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}
