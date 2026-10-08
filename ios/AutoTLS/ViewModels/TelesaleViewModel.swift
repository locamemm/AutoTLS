import Foundation
import SwiftUI
import Combine

class TelesaleViewModel: ObservableObject {
    static let defaultNoteColor = "#6B7280"
    static let marksFileName = "saved_contacts_marks.txt"
    private let templatesKey = "mark_templates_json"
    
    // State
    @Published var contacts: [Contact] = []
    @Published var currentIndex: Int = -1
    @Published var isCampaignRunning: Bool = false
    @Published var statusMessage: String = "Sẵn sàng. Vui lòng tải file danh bạ."
    @Published var templates: [TemplateMark] = []
    
    // Filter & Search
    @Published var searchText: String = ""
    @Published var selectedStatusFilter: String = "Tất cả"
    
    // UI Dialog Triggers
    @Published var selectedContactForMenu: Contact? = nil
    @Published var editingNoteContact: Contact? = nil
    @Published var editingStatusContact: Contact? = nil
    @Published var shareExportURL: URL? = nil
    @Published var isShowingShareSheet: Bool = false
    @Published var alertMessage: String? = nil
    @Published var showAlert: Bool = false
    
    let callMonitor = CallMonitor()
    
    var filteredContacts: [Contact] {
        contacts.filter { contact in
            let matchesSearch = searchText.isEmpty ||
                contact.phoneNumber.contains(searchText) ||
                contact.note.localizedCaseInsensitiveContains(searchText)
            
            let matchesFilter: Bool
            if selectedStatusFilter == "Tất cả" {
                matchesFilter = true
            } else {
                matchesFilter = contact.status == selectedStatusFilter
            }
            
            return matchesSearch && matchesFilter
        }
    }
    
    var totalCount: Int { contacts.count }
    var calledCount: Int { contacts.filter { $0.status == "Đã gọi" }.count }
    var waitingCount: Int { contacts.filter { $0.status == "Chờ gọi" }.count }
    
    init() {
        loadTemplates()
        loadSavedContacts()
        setupCallObserver()
    }
    
    private func setupCallObserver() {
        callMonitor.onCallEnded = { [weak self] in
            guard let self = self else { return }
            self.handleCallEnded()
        }
    }
    
    // MARK: - Template Management
    func loadTemplates() {
        guard let data = UserDefaults.standard.data(forKey: templatesKey),
              let decoded = try? JSONDecoder().decode([TemplateMark].self, from: data) else {
            // Default starter templates
            self.templates = [
                TemplateMark(note: "Khách hẹn gọi lại", color: "#2563EB"),
                TemplateMark(note: "Không nghe máy", color: "#D97706"),
                TemplateMark(note: "Khách chốt đơn", color: "#10B981"),
                TemplateMark(note: "Sai số / Thuê bao", color: "#DC2626")
            ]
            saveTemplates()
            return
        }
        self.templates = decoded
    }
    
    func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: templatesKey)
        }
    }
    
    func addTemplate(note: String, color: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        templates.append(TemplateMark(note: trimmed, color: color))
        saveTemplates()
    }
    
    func deleteTemplate(_ template: TemplateMark) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    // MARK: - File Parsing & Persistence
    func loadContactsFromURL(_ url: URL) {
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            parseContent(content)
            saveContactsLocally()
            showToast("Đã tải \(contacts.count) số điện thoại.")
        } catch {
            showToast("Lỗi khi đọc file: \(error.localizedDescription)")
        }
    }
    
    func parseContent(_ content: String) {
        var newContacts: [Contact] = []
        var idCounter = 1
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            if let contact = parseContactLine(line, id: idCounter) {
                newContacts.append(contact)
                idCounter += 1
            }
        }
        
        DispatchQueue.main.async {
            self.contacts = newContacts
            self.currentIndex = -1
            self.isCampaignRunning = false
            self.statusMessage = "Đã tải \(newContacts.count) số. Sẵn sàng bắt đầu."
        }
    }
    
    private func parseContactLine(_ line: String, id: Int) -> Contact? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        
        if trimmed.contains("|") {
            let parts = trimmed.components(separatedBy: "|")
            guard let firstPart = parts.first else { return nil }
            let phoneDigits = firstPart.filter { $0.isNumber }
            if phoneDigits.count < 9 { return nil }
            
            let note = parts.count > 1 ? parts[1].replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\|", with: "|") : ""
            let color = (parts.count > 2 && !parts[2].trimmingCharacters(in: .whitespaces).isEmpty) ? parts[2] : Self.defaultNoteColor
            let status = (parts.count > 3 && !parts[3].trimmingCharacters(in: .whitespaces).isEmpty) ? parts[3] : "Chờ gọi"
            
            return Contact(id: id, phoneNumber: phoneDigits, status: status, note: note, noteColor: color, isCurrent: false)
        } else {
            let phoneDigits = trimmed.filter { $0.isNumber }
            if phoneDigits.count >= 9 {
                return Contact(id: id, phoneNumber: phoneDigits, status: "Chờ gọi", note: "", noteColor: Self.defaultNoteColor, isCurrent: false)
            }
            return nil
        }
    }
    
    func serializeContacts() -> String {
        var result = ""
        for contact in contacts {
            let noteEscaped = contact.note.replacingOccurrences(of: "\n", with: "\\n").replacingOccurrences(of: "|", with: "\\|")
            result += "\(contact.phoneNumber)|\(noteEscaped)|\(contact.noteColor)|\(contact.status)\n"
        }
        return result
    }
    
    private var localDocumentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.marksFileName)
    }
    
    func saveContactsLocally() {
        let content = serializeContacts()
        do {
            try content.write(to: localDocumentsURL, atomically: true, encoding: .utf8)
        } catch {
            print("Lỗi lưu file local: \(error)")
        }
    }
    
    func loadSavedContacts() {
        let fileURL = localDocumentsURL
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                parseContent(content)
            }
        }
    }
    
    func exportContactsFile() {
        guard !contacts.isEmpty else {
            showToast("Danh sách trống, không có gì để xuất.")
            return
        }
        
        let content = serializeContacts()
        let timestamp = Int(Date().timeIntervalSince1970)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("AutoTLS_Contacts_\(timestamp).txt")
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            self.shareExportURL = tempURL
            self.isShowingShareSheet = true
        } catch {
            showToast("Không tạo được file xuất: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Campaign Logic
    func startCampaign() {
        guard !contacts.isEmpty else {
            showToast("Vui lòng tải danh sách số điện thoại trước.")
            return
        }
        
        let targetIndex = contacts.firstIndex { $0.status == "Chờ gọi" } ?? 0
        isCampaignRunning = true
        currentIndex = targetIndex
        statusMessage = "Chiến dịch đang chạy..."
        makeCallForCurrentIndex()
    }
    
    func startCampaignFrom(_ contact: Contact) {
        guard let index = contacts.firstIndex(where: { $0.id == contact.id }) else { return }
        isCampaignRunning = true
        currentIndex = index
        statusMessage = "Đang gọi từ số \(contact.phoneNumber)..."
        makeCallForCurrentIndex()
    }
    
    func nextCall() {
        guard isCampaignRunning, currentIndex >= 0 else { return }
        
        currentIndex += 1
        if currentIndex < contacts.count {
            makeCallForCurrentIndex()
        } else {
            showToast("Đã hoàn thành chiến dịch!")
            stopCampaign()
        }
    }
    
    func stopCampaign() {
        isCampaignRunning = false
        if currentIndex >= 0 && currentIndex < contacts.count {
            contacts[currentIndex].isCurrent = false
        }
        currentIndex = -1
        statusMessage = "Chiến dịch đã dừng. Sẵn sàng."
        saveContactsLocally()
    }
    
    private func makeCallForCurrentIndex() {
        guard currentIndex >= 0 && currentIndex < contacts.count else { return }
        
        for i in 0..<contacts.count {
            contacts[i].isCurrent = (i == currentIndex)
        }
        
        contacts[currentIndex].status = "Đang gọi..."
        saveContactsLocally()
        
        let phoneNumber = contacts[currentIndex].phoneNumber
        statusMessage = "Đang quay số: \(phoneNumber)"
        dial(phoneNumber: phoneNumber)
    }
    
    func dial(phoneNumber: String) {
        let cleaned = phoneNumber.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(cleaned)") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    print("Không thể mở ứng dụng điện thoại")
                }
            }
        } else {
            showToast("Thiết bị không hỗ trợ tính năng gọi điện trực tiếp.")
        }
    }
    
    private func handleCallEnded() {
        if currentIndex >= 0 && currentIndex < contacts.count {
            contacts[currentIndex].status = "Đã gọi"
            saveContactsLocally()
            statusMessage = "Cuộc gọi kết thúc. Nhấn 'Số tiếp theo' để gọi tiếp."
            showToast("Cuộc gọi kết thúc. Nhấn 'Số tiếp theo'.")
        }
    }
    
    // MARK: - Contact Operations
    func updateStatus(for contact: Contact, newStatus: String) {
        guard let idx = contacts.firstIndex(where: { $0.id == contact.id }) else { return }
        contacts[idx].status = newStatus
        saveContactsLocally()
        showToast("Đã cập nhật trạng thái: \(newStatus)")
    }
    
    func updateNote(for contact: Contact, newNote: String, newColor: String) {
        guard let idx = contacts.firstIndex(where: { $0.id == contact.id }) else { return }
        contacts[idx].note = newNote
        contacts[idx].noteColor = newColor
        saveContactsLocally()
        showToast("Đã lưu ghi chú cho \(contact.phoneNumber)")
    }
    
    func openZalo(phoneNumber: String) {
        let cleaned = phoneNumber.filter { $0.isNumber }
        if let url = URL(string: "https://zalo.me/\(cleaned)") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func showToast(_ message: String) {
        DispatchQueue.main.async {
            self.alertMessage = message
            self.showAlert = true
        }
    }
}
