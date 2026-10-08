import SwiftUI

struct ContactRowView: View {
    let contact: Contact
    let onMenuTap: () -> Void
    let onCallTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Index badge
            Text("\(contact.id)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .background(Color(.systemGray6))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(contact.phoneNumber)
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Status Badge
                    statusBadge(for: contact.status)
                }
                
                // Note if present
                if !contact.note.isEmpty {
                    HStack(alignment: .center, spacing: 6) {
                        Circle()
                            .fill(contact.color)
                            .frame(width: 8, height: 8)
                        
                        Text(contact.note)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(contact.color.opacity(0.12))
                    .cornerRadius(6)
                }
            }
            
            // Fast call action button
            Button(action: onCallTap) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.green)
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(contact.isCurrent ? Color.blue.opacity(0.18) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(contact.isCurrent ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onMenuTap()
        }
    }
    
    @ViewBuilder
    private func statusBadge(for status: String) -> some View {
        let (bg, fg): (Color, Color) = {
            switch status {
            case "Đã gọi":
                return (Color.green.opacity(0.2), Color.green)
            case "Đang gọi...":
                return (Color.orange.opacity(0.2), Color.orange)
            default:
                return (Color.gray.opacity(0.2), Color.gray)
            }
        }()
        
        Text(status)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bg)
            .clipShape(Capsule())
    }
}
