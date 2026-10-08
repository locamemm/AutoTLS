import Foundation

struct TemplateMark: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var note: String
    var color: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case note
        case color
    }
}
