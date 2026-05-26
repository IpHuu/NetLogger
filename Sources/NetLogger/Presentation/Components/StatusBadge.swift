import SwiftUI

struct StatusBadge: View {
    let statusCode: Int?
    
    var color: Color {
        guard let code = statusCode else {
            return .blue // Pending
        }
        switch code {
        case 200...299:
            return .green
        case 300...399:
            return .orange
        case 400...499:
            return .red
        default:
            return .purple // 5xx or general error
        }
    }
    
    var text: String {
        if let code = statusCode {
            return "\(code)"
        }
        return "PENDING"
    }
    
    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.85))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color, lineWidth: 1)
            )
    }
}
