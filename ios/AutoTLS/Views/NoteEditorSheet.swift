import SwiftUI

struct NoteEditorSheet: View {
    let contact: Contact
    @ObservedObject var viewModel: TelesaleViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var noteText: String = ""
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
                // Section 1: Note content
                Section(header: Text("Nội dung ghi chú cho \(contact.phoneNumber)")) {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 100)
                        .font(.body)
                }
                
                // Section 2: Color picker
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
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                
                // Section 3: Quick templates
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
                                    noteText = template.note
                                    selectedColorHex = template.color
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
            selectedColorHex = contact.noteColor.isEmpty ? "#6B7280" : contact.noteColor
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
