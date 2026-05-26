import SwiftUI

struct LogSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var maxEntries: Double = Double(NetLogger.shared.config.maxEntries)
    @State private var autoDeleteDays: Double = Double(NetLogger.shared.config.autoDeleteDays)
    @State private var enableShake = NetLogger.shared.config.enableShake
    @State private var enableFloating = NetLogger.shared.config.enableFloatingButton
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("TÍNH NĂNG KÍCH HOẠT")) {
                    Toggle("Lắc thiết bị mở Logs", isOn: $enableShake)
                        .onChange(of: enableShake) { newValue in
                            NetLogger.shared.config.enableShake = newValue
                            if newValue {
                                ShakeDetector.shared.enable()
                            }
                        }
                    
                    Toggle("Hiển thị nút nổi (Floating Button)", isOn: $enableFloating)
                        .onChange(of: enableFloating) { newValue in
                            NetLogger.shared.config.enableFloatingButton = newValue
                            if newValue {
                                FloatingButtonWindow.shared.show()
                            } else {
                                FloatingButtonWindow.shared.hide()
                            }
                        }
                }
                
                Section(header: Text("CẤU HÌNH BỘ NHỚ")) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Giới hạn số log lưu trữ")
                            Spacer()
                            Text("\(Int(maxEntries)) entries")
                                .bold()
                        }
                        Slider(value: $maxEntries, in: 100...2000, step: 50)
                            .onChange(of: maxEntries) { newValue in
                                NetLogger.shared.config.maxEntries = Int(newValue)
                            }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Tự động xoá logs sau")
                            Spacer()
                            Text("\(Int(autoDeleteDays)) ngày")
                                .bold()
                        }
                        Slider(value: $autoDeleteDays, in: 1...30, step: 1)
                            .onChange(of: autoDeleteDays) { newValue in
                                NetLogger.shared.config.autoDeleteDays = Int(newValue)
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
                        LogRealmManager.shared.clearAll()
                        dismiss()
                    },
                    secondaryButton: .cancel(Text("Hủy"))
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}
