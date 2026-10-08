import SwiftUI

struct StatusPickerSheet: View {
    let contact: Contact
    @ObservedObject var viewModel: TelesaleViewModel
    @Environment(\.dismiss) private var dismiss
    
    let statuses = ["Chờ gọi", "Đang gọi...", "Đã gọi"]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Chọn trạng thái cho số \(contact.phoneNumber)")) {
                    ForEach(statuses, id: \.self) { status in
                        HStack {
                            Text(status)
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            if contact.status == status {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.updateStatus(for: contact, newStatus: status)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Trạng Thái Cuộc Gọi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}
