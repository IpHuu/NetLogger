import SwiftUI

public struct JSONTreeViewer: View {
    let jsonString: String
    
    @State private var rootNode: JSONNode?
    @State private var parseError: String?
    
    public init(jsonString: String) {
        self.jsonString = jsonString
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = parseError {
                Text("Invalid JSON:\n\(error)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.red)
                    .padding()
            } else if let root = rootNode {
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    JSONNodeView(node: root, depth: 0)
                        .padding(.horizontal)
                }
            } else {
                Text("Empty Body")
                    .foregroundColor(.gray)
                    .italic()
                    .padding()
            }
        }
        .onAppear {
            parse()
        }
    }
    
    private func parse() {
        guard let data = jsonString.data(using: .utf8), !jsonString.isEmpty else {
            parseError = "No data"
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            self.rootNode = parseJSON(json, key: "{}")
            self.parseError = nil
        } catch {
            self.parseError = error.localizedDescription
        }
    }
    
    private func parseJSON(_ json: Any, key: String) -> JSONNode {
        if let dict = json as? [String: Any] {
            let children = dict.map { parseJSON($0.value, key: $0.key) }.sorted { $0.keyLabel < $1.keyLabel }
            return .object(key: key, value: children)
        } else if let array = json as? [Any] {
            let children = array.enumerated().map { parseJSON($0.element, key: "[\($0.offset)]") }
            return .array(key: key, value: children)
        } else {
            return .leaf(key: key, value: json)
        }
    }
}

// MARK: - Node Type
enum JSONNode: Identifiable {
    case object(key: String, value: [JSONNode])
    case array(key: String, value: [JSONNode])
    case leaf(key: String, value: Any)
    
    var id: String {
        switch self {
        case .object(let key, _): return "obj_\(key)"
        case .array(let key, _): return "arr_\(key)"
        case .leaf(let key, _): return "leaf_\(key)"
        }
    }
    
    var keyLabel: String {
        switch self {
        case .object(let key, _), .array(let key, _), .leaf(let key, _):
            return key
        }
    }
}

// MARK: - Node View
struct JSONNodeView: View {
    let node: JSONNode
    let depth: Int
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch node {
            case .object(let key, let children):
                HStack(spacing: 4) {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    
                    Text(key)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    Text("{\(children.count)}")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(children) { child in
                            JSONNodeView(node: child, depth: depth + 1)
                        }
                    }
                    .padding(.leading, 16)
                }
                
            case .array(let key, let children):
                HStack(spacing: 4) {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    
                    Text(key)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.blue)
                    
                    Text("[\(children.count)]")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(children) { child in
                            JSONNodeView(node: child, depth: depth + 1)
                        }
                    }
                    .padding(.leading, 16)
                }
                
            case .leaf(let key, let value):
                HStack(spacing: 4) {
                    Spacer().frame(width: 16) // Align with chevrons
                    
                    Text(key)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.teal)
                    
                    Text(":")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    LeafValueView(value: value)
                }
            }
        }
    }
}

// MARK: - Leaf Value Rendering
struct LeafValueView: View {
    let value: Any
    
    var body: some View {
        if let str = value as? String {
            Text("\"\(str)\"")
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(.green)
        } else if let num = value as? NSNumber {
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                Text(num.boolValue ? "true" : "false")
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.purple)
            } else {
                Text("\(num)")
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.orange)
            }
        } else if value is NSNull {
            Text("null")
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(.gray)
        } else {
            Text("\(String(describing: value))")
                .font(.system(.footnote, design: .monospaced))
                .foregroundColor(.primary)
        }
    }
}
