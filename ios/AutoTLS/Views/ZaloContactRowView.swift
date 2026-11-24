import SwiftUI

struct ZaloContactRowView: View {
    let contact: Contact
    let isLookedUp: Bool
    let onZaloTap: () -> Void
    let onNoteTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Index badge
            Text("\(contact.id)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(isLookedUp ? .green : .secondary)
                .frame(width: 32, height: 32)
                .background(isLookedUp ? Color.green.opacity(0.15) : Color(.systemGray6))
                .clipShape(Circle())
            
            // Middle Content: Phone number, Notes, Status
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(contact.phoneNumber)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    if isLookedUp {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Đã tra")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                
                // Note preview if present
                if !contact.note.isEmpty {
                    HStack(alignment: .center, spacing: 6) {
                        Circle()
                            .fill(contact.color)
                            .frame(width: 7, height: 7)
                        
                        Text(contact.note)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Quick Note Edit Button (Tách riêng để không kích hoạt mở Zalo khi chỉ muốn ghi chú)
            Button(action: onNoteTap) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // Nút Tra Zalo nổi bật (Chạm vào nút hoặc chạm vào thẻ đều mở ngay Zalo)
            Button(action: onZaloTap) {
                HStack(spacing: 5) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Zalo")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.blue.opacity(0.25), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isLookedUp ? Color.green.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isLookedUp ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .contentShape(Rectangle())
        // THAO TÁC 1 CHẠM: Chạm vào bất kỳ vị trí nào trên thẻ/dòng đều mở ngay Zalo!
        .onTapGesture {
            onZaloTap()
        }
    }
}
