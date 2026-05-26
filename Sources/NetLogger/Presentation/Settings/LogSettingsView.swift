import SwiftUI

struct LogSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LogSettingsViewModel
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("TÍNH NĂNG KÍCH HOẠT")) {
                    Toggle("Lắc thiết bị mở Logs", isOn: Binding(
                        get: { viewModel.enableShake },
                        set: { viewModel.toggleShake($0) }
                    ))
                    
                    Toggle("Hiển thị nút nổi (Floating Button)", isOn: Binding(
                        get: { viewModel.enableFloating },
                        set: { viewModel.toggleFloating($0) }
                    ))
                }
                
                Section(header: Text("CẤU HÌNH BỘ NHỚ")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Giới hạn số log lưu trữ")
                            Spacer()
                            Text("\(Int(viewModel.maxEntries)) entries")
                                .bold()
                        }
                        Slider(value: $viewModel.maxEntries, in: 100...2000, step: 50)
                            .onChange(of: viewModel.maxEntries) { _ in
                                viewModel.updateConfig()
                            }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Tự động xoá logs sau")
                            Spacer()
                            Text("\(Int(viewModel.autoDeleteDays)) ngày")
                                .bold()
                        }
                        Slider(value: $viewModel.autoDeleteDays, in: 1...30, step: 1)
                            .onChange(of: viewModel.autoDeleteDays) { _ in
                                viewModel.updateConfig()
                            }
                    }
                }
                
                Section {
                    Button(action: { showingClearAlert = true }) {
                        HStack {
                            Spacer()
                            Text("Xóa Toàn Bộ Logs")
                                .foregroundColor(.red)
                                .bold()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Cài đặt NetLogger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showingClearAlert) {
                Alert(
                    title: Text("Xác nhận xóa"),
                    message: Text("Hành động này sẽ xóa vĩnh viễn toàn bộ lịch sử API log. Bạn có chắc chắn không?"),
                    primaryButton: .destructive(Text("Xóa")) {
                        viewModel.clearAllLogs()
                        dismiss()
                    },
                    secondaryButton: .cancel(Text("Hủy"))
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}
