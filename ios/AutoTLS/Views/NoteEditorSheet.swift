import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct NoteEditorSheet: View {
    let contact: Contact
    @ObservedObject var viewModel: TelesaleViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var noteText: String = ""
    @State private var cursorPosition: Int = 0
    @State private var selectedColorHex: String = "#6B7280"
    @State private var showingAddTemplateAlert = false
    @State private var newTemplateNote = ""
    @State private var newTemplateColor = "#2563EB"
    
    let palette: [String] = [
        "#6B7280", // Gray
        "#DC2626", // Red
        "#2563EB", // Blue
        "#D97706", // Amber
        "#7C3AED", // Purple
        "#10B981", // Green
        "#EC4899"  // Pink
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Section 1: Note content with quick Clear button and cursor tracking
                Section(header: HStack {
                    Text("Ghi chú cho \(contact.phoneNumber)")
                    Spacer()
                    if !noteText.isEmpty {
                        Button(action: {
                            noteText = ""
                            cursorPosition = 0
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Clear")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(6)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }) {
                    ZStack(alignment: .topLeading) {
                        if noteText.isEmpty {
                            Text("Nhập ghi chú cho khách hàng...")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        NoteTextView(text: $noteText, cursorPosition: $cursorPosition)
                            .frame(minHeight: 110)
                    }
                }
                
                // Section 2: Color picker (chọn màu sẽ ẩn bàn phím ngay lập tức)
                Section(header: Text("Màu sắc đánh dấu")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(palette, id: \.self) { hex in
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: hex) ?? .gray)
                                        .frame(width: 36, height: 36)
                                    
                                    if selectedColorHex.uppercased() == hex.uppercased() {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColorHex.uppercased() == hex.uppercased() ? 2 : 0)
                                )
                                .onTapGesture {
                                    selectedColorHex = hex
                                    dismissKeyboard()
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                
                // Section 3: Quick templates (chèn nội dung vào đúng vị trí con trỏ)
                Section(header: HStack {
                    Text("Mẫu ghi chú nhanh")
                    Spacer()
                    Button(action: {
                        newTemplateNote = ""
                        showingAddTemplateAlert = true
                    }) {
                        Label("Thêm mẫu", systemImage: "plus.circle.fill")
                            .font(.caption)
                    }
                }) {
                    if viewModel.templates.isEmpty {
                        Text("Chưa có mẫu nào. Bấm 'Thêm mẫu' để tạo.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.templates) { template in
                            HStack {
                                Circle()
                                    .fill(Color(hex: template.color) ?? .gray)
                                    .frame(width: 10, height: 10)
                                
                                Text(template.note)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    insertTemplateAtCursor(template)
                                }) {
                                    Text("Dùng")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                viewModel.deleteTemplate(viewModel.templates[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Mark Ghi Chú")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        viewModel.updateNote(for: contact, newNote: noteText, newColor: selectedColorHex)
                        dismiss()
                    }
                    .font(.headline)
                }
            }
            .sheet(isPresented: $showingAddTemplateAlert) {
                AddTemplateView(viewModel: viewModel, isPresented: $showingAddTemplateAlert)
            }
        }
        .onAppear {
            noteText = contact.note
            cursorPosition = contact.note.utf16.count
            selectedColorHex = contact.noteColor.isEmpty ? "#6B7280" : contact.noteColor
        }
    }
    
    // Thêm nội dung mẫu vào vị trí con trỏ chuột
    private func insertTemplateAtCursor(_ template: TemplateMark) {
        let utf16 = noteText.utf16
        let safePos = max(0, min(cursorPosition, utf16.count))
        
        let prefix = String(utf16.prefix(safePos)) ?? ""
        let suffix = String(utf16.suffix(utf16.count - safePos)) ?? ""
        
        noteText = prefix + template.note + suffix
        cursorPosition = safePos + template.note.utf16.count
        selectedColorHex = template.color
    }
    
    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

// Trình soạn thảo văn bản hỗ trợ bám sát vị trí con trỏ (Caret Cursor)
struct NoteTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var cursorPosition: Int
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: NoteTextView
        
        init(_ parent: NoteTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.parent.text = textView.text
            self.parent.cursorPosition = textView.selectedRange.location
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            self.parent.cursorPosition = textView.selectedRange.location
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.textColor = .label
        textView.isScrollEnabled = true
        textView.text = text
        let safePos = min(cursorPosition, text.utf16.count)
        textView.selectedRange = NSRange(location: safePos, length: 0)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
            let safePos = min(cursorPosition, text.utf16.count)
            uiView.selectedRange = NSRange(location: safePos, length: 0)
        }
    }
}

struct AddTemplateView: View {
    @ObservedObject var viewModel: TelesaleViewModel
    @Binding var isPresented: Bool
    
    @State private var templateNote = ""
    @State private var templateColor = "#2563EB"
    
    let palette: [String] = [
        "#6B7280", "#DC2626", "#2563EB", "#D97706", "#7C3AED", "#10B981", "#EC4899"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nội dung mẫu")) {
                    TextField("Ví dụ: Hẹn gọi lại vào ngày mai", text: $templateNote)
                }
                
                Section(header: Text("Chọn màu mẫu")) {
                    HStack(spacing: 12) {
                        ForEach(palette, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex) ?? .gray)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: templateColor == hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    templateColor = hex
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Thêm Mẫu Mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tạo") {
                        viewModel.addTemplate(note: templateNote, color: templateColor)
                        isPresented = false
                    }
                    .disabled(templateNote.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
