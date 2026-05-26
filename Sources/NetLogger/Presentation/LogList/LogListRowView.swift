import SwiftUI

struct LogListRowView: View {
    let log: NetworkLog
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: log.timestamp)
    }
    
    private var durationText: String {
        guard let duration = log.duration else { return "" }
        if duration < 1.0 {
            return String(format: "%.0fms", duration * 1000)
        }
        return String(format: "%.2fs", duration)
    }
    
    private var methodColor: Color {
        switch log.method.uppercased() {
        case "GET": return .green
        case "POST": return .blue
        case "PUT": return .orange
        case "DELETE": return .red
        case "DEBUG": return .teal
        case "INFO": return .cyan
        case "ERROR": return .red
        default: return .gray
        }
    }
    
    private var extractedTag: String? {
        let pattern = "^\\[(.*?)\\]"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: log.url, range: NSRange(log.url.startIndex..., in: log.url)) {
            if let range = Range(match.range(at: 1), in: log.url) {
                return String(log.url[range])
            }
        }
        return nil
    }
    
    private var displayUrl: String {
        if let tag = extractedTag {
            let prefix = "[\(tag)] "
            if log.url.hasPrefix(prefix) {
                return String(log.url.dropFirst(prefix.count))
            }
        }
        return log.url
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                // Method Badge
                Text(log.method.uppercased())
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(methodColor)
                    .cornerRadius(4)
                
                // Status Badge
                StatusBadge(statusCode: log.statusCode)
                
                Spacer()
                
                // Time
                Text(formattedTime)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            // URL Path or Tagged Message
            HStack(alignment: .top, spacing: 6) {
                if let tag = extractedTag {
                    Text("[\(tag)]")
                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                        .foregroundColor(.purple)
                }
                Text(displayUrl)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            // Duration & Error description
            HStack {
                if !durationText.isEmpty {
                    Label(durationText, systemImage: "clock")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                if let error = log.errorDescription {
                    Spacer()
                    Text(error)
                        .font(.system(.caption2))
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
