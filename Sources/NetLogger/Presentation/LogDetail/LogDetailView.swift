import SwiftUI

struct LogDetailView: View {
    let log: NetworkLog
    
    @State private var activeTab = 0
    @State private var isCopied = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Premium custom tab bar
            Picker("", selection: $activeTab) {
                Text("Overview").tag(0)
                Text("Request").tag(1)
                Text("Response").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            
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
        .navigationTitle("Log Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: copyCurl) {
                        Label("Copy cURL", systemImage: "terminal")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .preferredColorScheme(.light)
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STATUS CODE").font(.caption2).foregroundColor(.gray)
                        StatusBadge(statusCode: log.statusCode)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("METHOD").font(.caption2).foregroundColor(.gray)
                        Text(log.method.uppercased())
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(methodColor(log.method))
                            .cornerRadius(4)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DURATION").font(.caption2).foregroundColor(.gray)
                        if let duration = log.duration {
                            Text(String(format: "%.0fms", duration * 1000))
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundColor(.primary)
                        } else {
                            Text("Pending").font(.subheadline).foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PROTOCOL").font(.caption2).foregroundColor(.gray)
                        Text(log.httpVersion ?? "HTTP/1.1")
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                detailCard(title: "REQUEST URL") {
                    HStack(alignment: .top) {
                        Text(log.url)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                        
                        Spacer()
                        
                        Button(action: { copyToClipboard(log.url) }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                
                if let duration = log.duration {
                    detailCard(title: "PERFORMANCE TIMELINE") {
                        performanceTimeline(total: duration)
                    }
                    .padding(.horizontal)
                }
                
                if let error = log.errorDescription {
                    detailCard(title: "ERROR") {
                        Text(error)
                             .font(.system(.body, design: .monospaced))
                            .foregroundColor(.red)
                            .padding(.vertical, 4)
                    }.padding(.horizontal)
                }
                
                Button(action: copyCurl) {
                    HStack {
                        Spacer()
                        Image(systemName: "terminal")
                        Text(isCopied ? "Copied" : "Copy cURL")
                            .bold()
                        Spacer()
                    }
                    .padding()
                    .background(Color.systemGreen)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    private func performanceTimeline(total: TimeInterval) -> some View {
        let reqMs = (log.requestDuration ?? (total * 0.1)) * 1000
        let resMs = (log.responseDuration ?? (total * 0.9)) * 1000
        let totalMs = total * 1000
        
        let reqRatio = max(0.05, min(0.95, reqMs / totalMs))
        let resRatio = max(0.05, min(0.95, resMs / totalMs))
        
        return VStack(spacing: 12) {
            timelineRow(label: "Request", ratio: reqRatio, color: .blue, ms: reqMs)
            timelineRow(label: "Response", ratio: resRatio, color: .systemGreen, ms: resMs)
            
            Divider().background(Color(white: 0.2))
            
            HStack {
                Text("Total Latency").font(.caption).foregroundColor(.gray)
                Spacer()
                Text(String(format: "%.0fms", totalMs)).font(.caption.bold()).foregroundColor(.primary)
            }
        }
    }
    
    private func timelineRow(label: String, ratio: Double, color: Color, ms: Double) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 70, alignment: .trailing)
            
            GeometryReader { geo in
                let width = geo.size.width * CGFloat(ratio)
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: width, height: 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .frame(height: 8)
            
            Text(String(format: "%.0fms", ms))
                .font(.caption.monospacedDigit())
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .trailing)
        }
    }
    
    private func methodColor(_ method: String) -> Color {
        switch method.uppercased() {
        case "GET": return .green
        case "POST": return .blue
        case "PUT": return .orange
        case "DELETE": return .red
        default: return .gray
        }
    }
    
    // MARK: - Request Tab
    private var requestTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                detailCardWithAction(title: "REQUEST HEADERS", action: { copyHeaders(log.requestHeaders) }) {
                    if log.requestHeaders.isEmpty {
                        Text("No Request Headers")
                            .foregroundColor(.gray)
                            .italic()
                    } else {
                        ForEach(log.requestHeaders.sorted(by: { $0.key < $1.key }), id: \.key) { header in
                            infoRow(label: header.key, value: header.value, isMonospaced: true)
                        }
                    }
                }
                
                detailCardWithAction(title: "REQUEST BODY (JSON)", action: { copyToClipboard(log.requestBody ?? "", formatAsJSON: true) }) {
                    if let body = log.requestBody, !body.isEmpty {
                        JSONTreeViewer(jsonString: body)
                    } else {
                        Text("No Request Body")
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
                detailCardWithAction(title: "RESPONSE HEADERS", action: { copyHeaders(log.responseHeaders ?? [:]) }) {
                    if let headers = log.responseHeaders, !headers.isEmpty {
                        ForEach(headers.sorted(by: { $0.key < $1.key }), id: \.key) { header in
                            infoRow(label: header.key, value: header.value, isMonospaced: true)
                        }
                    } else {
                        Text("No Response Headers")
                            .foregroundColor(.gray)
                            .italic()
                    }
                }
                
                detailCardWithAction(title: "RESPONSE BODY", action: { copyToClipboard(log.responseBody ?? "", formatAsJSON: true) }) {
                    if let body = log.responseBody, !body.isEmpty {
                        JSONTreeViewer(jsonString: body)
                    } else {
                        Text("No Response Body")
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
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
        }
    }
    
    private func detailCardWithAction<Content: View>(title: String, action: @escaping () -> Void, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(.caption, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                Spacer()
                Button(action: action) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(6)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
        }
    }
    
    private func infoRow(label: String, value: String, isMonospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.system(.footnote, design: isMonospaced ? .monospaced : .default))
                .foregroundColor(.primary)
                .textSelection(.enabled)
            
            Divider()
                .background(Color(UIColor.separator))
        }
        .padding(.vertical, 2)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    private func copyToClipboard(_ text: String, formatAsJSON: Bool = false) {
        var copyText = text
        if formatAsJSON, let data = text.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            copyText = prettyString
        }
        UIPasteboard.general.string = copyText
    }
    
    private func copyHeaders(_ headers: [String: String]) {
        let text = headers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        copyToClipboard(text)
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
