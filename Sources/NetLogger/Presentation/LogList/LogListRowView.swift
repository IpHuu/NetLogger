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
        default: return .gray
        }
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
            
            // URL Path
            Text(log.url)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.primary)
                .lineLimit(2)
            
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
