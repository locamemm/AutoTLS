import SwiftUI

struct ContactActionMenuSheet: View {
    let contact: Contact
    @ObservedObject var viewModel: TelesaleViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Capsule()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                
                Text(contact.phoneNumber)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .padding(.top, 8)
                
                Text("STT #\(contact.id) • \(contact.status)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 16)
            
            Divider()
            
            // Menu Items
            VStack(spacing: 2) {
                menuButton(
                    icon: "phone.circle.fill",
                    color: .green,
                    title: "Gọi lại số này",
                    subtitle: "Thực hiện cuộc gọi trực tiếp đến số này"
                ) {
                    dismiss()
                    viewModel.dial(phoneNumber: contact.phoneNumber)
                }
                
                menuButton(
                    icon: "play.circle.fill",
                    color: .blue,
                    title: "Gọi từ số này",
                    subtitle: "Bắt đầu chạy chiến dịch tính từ số này"
                ) {
                    dismiss()
                    viewModel.startCampaignFrom(contact)
                }
                
                menuButton(
                    icon: "arrow.triangle.2.circlepath.circle.fill",
                    color: .orange,
                    title: "Đổi trạng thái",
                    subtitle: "Chờ gọi, Đang gọi..., Đã gọi"
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel.editingStatusContact = contact
                    }
                }
                
                menuButton(
                    icon: "highlighter",
                    color: .purple,
                    title: "Mark / Ghi chú",
                    subtitle: "Thêm ghi chú, tô màu, chọn mẫu nhanh"
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        viewModel.editingNoteContact = contact
                    }
                }
                
                menuButton(
                    icon: "message.circle.fill",
                    color: .cyan,
                    title: "Tra số trong Zalo",
                    subtitle: "Mở trực tiếp ứng dụng Zalo"
                ) {
                    dismiss()
                    viewModel.openZalo(phoneNumber: contact.phoneNumber)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    private func menuButton(
        icon: String,
        color: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(color)
                    .frame(width: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
