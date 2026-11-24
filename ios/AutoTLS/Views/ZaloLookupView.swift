import SwiftUI

struct ZaloLookupView: View {
    @ObservedObject var viewModel: TelesaleViewModel
    @Binding var isImportingFile: Bool
    @State private var directPhoneInput: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Stats & Status
                zaloHeaderView
                
                // Direct phone input / clipboard lookup (Tra nhanh số bất kỳ)
                directLookupBar
                
                // Search in contacts & Filter pills
                searchAndFilterBar
                
                // Contact list for 1-tap Zalo lookup
                contactListView
            }
            .navigationTitle("Tra cứu Zalo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { isImportingFile = true }) {
                            Label("Tải file danh bạ", systemImage: "doc.badge.plus")
                        }
                        if !viewModel.lookedUpPhoneNumbers.isEmpty {
                            Button(action: { viewModel.clearZaloLookedUp() }) {
                                Label("Làm mới lịch sử tra cứu", systemImage: "arrow.counterclockwise")
                            }
                        }
                        Button(action: { viewModel.exportContactsFile() }) {
                            Label("Xuất file hiện tại", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Subviews
    
    private var zaloHeaderView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                statCard(title: "Tổng số", value: "\(viewModel.totalCount)", color: .blue)
                statCard(title: "Đã tra", value: "\(viewModel.zaloLookedUpCount)", color: .green)
                statCard(title: "Chưa tra", value: "\(viewModel.zaloUnlookedCount)", color: .orange)
            }
            
            Text(viewModel.statusMessage)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var directLookupBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "phone.badge.plus")
                        .foregroundColor(.cyan)
                    TextField("Nhập SĐT để tra cứu nhanh...", text: $directPhoneInput)
                        .keyboardType(.phonePad)
                        .font(.system(size: 15, weight: .medium))
                    
                    if !directPhoneInput.isEmpty {
                        Button(action: { directPhoneInput = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
                
                // Nút Dán nhanh từ clipboard và mở ngay Zalo
                Button(action: {
                    #if canImport(UIKit)
                    if let clip = UIPasteboard.general.string {
                        let digits = clip.filter { $0.isNumber }
                        if !digits.isEmpty {
                            directPhoneInput = digits
                            viewModel.openZalo(phoneNumber: digits)
                        } else {
                            viewModel.statusMessage = "Clipboard không có SĐT hợp lệ."
                        }
                    }
                    #endif
                }) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 42, height: 42)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
                
                // Nút Tra Ngay
                Button(action: {
                    let cleaned = directPhoneInput.filter { $0.isNumber }
                    guard !cleaned.isEmpty else { return }
                    viewModel.openZalo(phoneNumber: cleaned)
                }) {
                    Text("Tra")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 42)
                        .background(directPhoneInput.isEmpty ? Color.gray.opacity(0.4) : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(directPhoneInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(Color(.systemGroupedBackground))
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 6) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Tìm kiếm trong danh bạ...", text: $viewModel.zaloSearchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !viewModel.zaloSearchText.isEmpty {
                    Button(action: { viewModel.zaloSearchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(["Tất cả", "Chưa tra", "Đã tra"], id: \.self) { filter in
                        Text(filter)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(
                                viewModel.zaloFilter == filter ? Color.cyan : Color(.secondarySystemGroupedBackground)
                            )
                            .foregroundColor(
                                viewModel.zaloFilter == filter ? .black : .secondary
                            )
                            .clipShape(Capsule())
                            .onTapGesture {
                                viewModel.zaloFilter = filter
                            }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(.systemGroupedBackground))
    }
    
    private var contactListView: some View {
        Group {
            if viewModel.contacts.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 54))
                        .foregroundColor(.cyan.opacity(0.6))
                    Text("Chưa có danh bạ để tra cứu")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Tải file danh bạ hoặc nhập SĐT trực tiếp ở trên để tra cứu Zalo 1 chạm.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button(action: { isImportingFile = true }) {
                        Label("Tải File Danh Bạ", systemImage: "doc.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.filteredZaloContacts) { contact in
                            ZaloContactRowView(
                                contact: contact,
                                isLookedUp: viewModel.isZaloLookedUp(contact.phoneNumber),
                                onZaloTap: {
                                    // 1 CHẠM DUY NHẤT: Mở ngay Zalo profile
                                    viewModel.openZalo(phoneNumber: contact.phoneNumber)
                                },
                                onNoteTap: {
                                    viewModel.editingNoteContact = contact
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}
