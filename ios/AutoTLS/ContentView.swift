import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = TelesaleViewModel()
    @State private var isImportingFile = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Statistics & Status Header
                statusHeaderView
                
                // Primary Action & Campaign Control Buttons
                controlButtonsView
                
                // Search and Filter Bar
                searchAndFilterBar
                
                // Contact List
                contactListView
            }
            .navigationTitle("Auto Telesale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { isImportingFile = true }) {
                            Label("Tải file danh bạ", systemImage: "doc.badge.plus")
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
            .fileImporter(
                isPresented: $isImportingFile,
                allowedContentTypes: [.plainText, .text],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let selectedURL = urls.first {
                        viewModel.loadContactsFromURL(selectedURL)
                    }
                case .failure(let error):
                    viewModel.showToast("Lỗi chọn file: \(error.localizedDescription)")
                }
            }
            .sheet(item: $viewModel.selectedContactForMenu) { contact in
                ContactActionMenuSheet(contact: contact, viewModel: viewModel)
                    .presentationDetents([.medium])
            }
            .sheet(item: $viewModel.editingNoteContact) { contact in
                NoteEditorSheet(contact: contact, viewModel: viewModel)
            }
            .sheet(item: $viewModel.editingStatusContact) { contact in
                StatusPickerSheet(contact: contact, viewModel: viewModel)
                    .presentationDetents([.fraction(0.35)])
            }
            .sheet(isPresented: $viewModel.isShowingShareSheet) {
                if let url = viewModel.shareExportURL {
                    ShareActivityView(activityItems: [url])
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text("Thông báo"),
                    message: Text(viewModel.alertMessage ?? ""),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    
    private var statusHeaderView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                statCard(title: "Tổng số", value: "\(viewModel.totalCount)", color: .blue)
                statCard(title: "Đã gọi", value: "\(viewModel.calledCount)", color: .green)
                statCard(title: "Chờ gọi", value: "\(viewModel.waitingCount)", color: .orange)
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
    
    private var controlButtonsView: some View {
        VStack(spacing: 8) {
            // Row 1: Load file & Export file
            HStack(spacing: 8) {
                Button(action: { isImportingFile = true }) {
                    Label("Tải File", systemImage: "doc.text.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isCampaignRunning)
                .opacity(viewModel.isCampaignRunning ? 0.5 : 1.0)
                
                Button(action: { viewModel.exportContactsFile() }) {
                    Label("Xuất File", systemImage: "square.and.arrow.up.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
            }
            
            // Row 2: Campaign Actions (Start, Next, Stop)
            HStack(spacing: 8) {
                Button(action: { viewModel.startCampaign() }) {
                    Label("Bắt đầu", systemImage: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(viewModel.isCampaignRunning ? Color.gray.opacity(0.4) : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isCampaignRunning || viewModel.contacts.isEmpty)
                
                Button(action: { viewModel.nextCall() }) {
                    Label("Số tiếp theo", systemImage: "forward.fill")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            !viewModel.isCampaignRunning ? Color.gray.opacity(0.4) : Color.blue
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isCampaignRunning)
                
                Button(action: { viewModel.stopCampaign() }) {
                    Label("Dừng", systemImage: "stop.fill")
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            !viewModel.isCampaignRunning ? Color.gray.opacity(0.4) : Color.red
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!viewModel.isCampaignRunning)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Tìm số hoặc ghi chú...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
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
                    ForEach(["Tất cả", "Chờ gọi", "Đang gọi...", "Đã gọi"], id: \.self) { filter in
                        Text(filter)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                viewModel.selectedStatusFilter == filter ? Color.blue : Color(.secondarySystemGroupedBackground)
                            )
                            .foregroundColor(
                                viewModel.selectedStatusFilter == filter ? .white : .secondary
                            )
                            .clipShape(Capsule())
                            .onTapGesture {
                                viewModel.selectedStatusFilter = filter
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
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 54))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Chưa có danh sách liên hệ")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Nhấn nút 'Tải File' ở trên để chọn file text (.txt) chứa danh sách số điện thoại.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.filteredContacts) { contact in
                                ContactRowView(
                                    contact: contact,
                                    onMenuTap: {
                                        viewModel.selectedContactForMenu = contact
                                    },
                                    onCallTap: {
                                        viewModel.dial(phoneNumber: contact.phoneNumber)
                                    }
                                )
                                .id(contact.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .onChange(of: viewModel.currentIndex) { newIndex in
                        if newIndex >= 0 && newIndex < viewModel.contacts.count {
                            let currentContact = viewModel.contacts[newIndex]
                            withAnimation {
                                proxy.scrollTo(currentContact.id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
