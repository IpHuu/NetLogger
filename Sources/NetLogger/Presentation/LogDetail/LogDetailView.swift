import SwiftUI

struct LogDetailView: View {
    let log: NetworkLog
    
    @State private var activeTab = 0
    @State private var isCopied = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Premium custom tab bar
            Picker("", selection: $activeTab) {
                Text("Tổng quan").tag(0)
                Text("Request").tag(1)
                Text("Response").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(red: 0.08, green: 0.08, blue: 0.09))
            
            Divider()
            
            TabView(selection: $activeTab) {
                overviewTab
                    .tag(0)
                
                requestTab
                    .tag(1)
                
                responseTab
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("Chi tiết API")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: copyCurl) {
                    Label(isCopied ? "Đã copy" : "Copy cURL", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .foregroundColor(isCopied ? .green : .accentColor)
                }
            }
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                detailCard(title: "THÔNG TIN CHUNG") {
                    infoRow(label: "URL", value: log.url, isMonospaced: true)
                    infoRow(label: "Method", value: log.method)
                    infoRow(label: "Status Code", value: log.statusCode.flatMap { "\($0)" } ?? "PENDING")
                    infoRow(label: "Thời gian", value: formattedDate(log.timestamp))
                    if let duration = log.duration {
                        infoRow(label: "Thời gian phản hồi", value: String(format: "%.0f ms (%.3f s)", duration * 1000, duration))
                    }
                }
                
                if let error = log.errorDescription {
                    detailCard(title: "LỖI") {
                        Text(error)
                             .font(.system(.body, design: .monospaced))
                            .foregroundColor(.red)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Request Tab
    private var requestTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                detailCard(title: "REQUEST HEADERS") {
                    if log.requestHeaders.isEmpty {
                        Text("Không có Request Headers")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(log.requestHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { header in
                            infoRow(label: header.key, value: header.value, isMonospaced: true)
                        }
                    }
                }
                
                detailCard(title: "REQUEST BODY") {
                    if let body = log.requestBody, !body.isEmpty {
                        JSONTreeViewer(jsonString: body)
                    } else {
                        Text("Không có Request Body")
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Response Tab
    private var responseTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                detailCard(title: "RESPONSE HEADERS") {
                    if let headers = log.responseHeaders, !headers.isEmpty {
                        ForEach(headers.sorted(by: { $0.key < $1.key }), id: \.key) { header in
                            infoRow(label: header.key, value: header.value, isMonospaced: true)
                        }
                    } else {
                        Text("Không có Response Headers")
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
                
                detailCard(title: "RESPONSE BODY") {
                    if let body = log.responseBody, !body.isEmpty {
                        JSONTreeViewer(jsonString: body)
                    } else {
                        Text("Không có Response Body")
                            .foregroundColor(.gray)
                            .italic()
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Component Helpers
    private func detailCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.caption, weight: .bold))
                .foregroundColor(.gray)
                .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding()
            .background(Color(red: 0.12, green: 0.12, blue: 0.14))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 0.1), lineWidth: 1)
            )
        }
    }
    
    private func infoRow(label: String, value: String, isMonospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(.body, design: isMonospaced ? .monospaced : .default))
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            Divider()
                .background(Color(white: 0.15))
        }
        .padding(.vertical, 2)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    private func copyCurl() {
        let curl = CurlGenerator.generate(from: log)
        UIPasteboard.general.string = curl
        isCopied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCopied = false
        }
    }
}
