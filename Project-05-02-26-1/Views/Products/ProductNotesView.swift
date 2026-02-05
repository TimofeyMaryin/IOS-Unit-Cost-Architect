import SwiftUI
import SwiftData

/// Product notes management view
struct ProductNotesView: View {
    @Environment(\.modelContext) private var modelContext
    
    let product: Product
    
    @State private var showingAddNote = false
    
    private var sortedNotes: [ProductNote] {
        let notes = product.notes ?? []
        return notes.sorted { note1, note2 in
            if note1.isPinned != note2.isPinned {
                return note1.isPinned
            }
            return note1.updatedAt > note2.updatedAt
        }
    }
    
    var body: some View {
        List {
            // Stats section
            Section {
                HStack {
                    Label("Total Notes", systemImage: "note.text")
                    Spacer()
                    Text("\(sortedNotes.count)")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("Pinned", systemImage: "pin.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    Text("\(sortedNotes.filter { $0.isPinned }.count)")
                        .fontWeight(.semibold)
                }
            }
            
            // Notes list
            if sortedNotes.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        
                        Text("No notes yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            showingAddNote = true
                        } label: {
                            Label("Add Note", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            } else {
                // Pinned notes
                let pinnedNotes = sortedNotes.filter { $0.isPinned }
                if !pinnedNotes.isEmpty {
                    Section("Pinned") {
                        ForEach(pinnedNotes) { note in
                            NoteRowView(note: note, modelContext: modelContext)
                        }
                        .onDelete { indexSet in
                            deleteNotes(pinnedNotes, at: indexSet)
                        }
                    }
                }
                
                // Other notes
                let otherNotes = sortedNotes.filter { !$0.isPinned }
                if !otherNotes.isEmpty {
                    Section("Notes") {
                        ForEach(otherNotes) { note in
                            NoteRowView(note: note, modelContext: modelContext)
                        }
                        .onDelete { indexSet in
                            deleteNotes(otherNotes, at: indexSet)
                        }
                    }
                }
            }
        }
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddNote = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddNote) {
            NoteEditView(product: product, note: nil)
        }
    }
    
    private func deleteNotes(_ notes: [ProductNote], at offsets: IndexSet) {
        for index in offsets {
            let note = notes[index]
            modelContext.delete(note)
        }
        try? modelContext.save()
    }
}

// MARK: - Note Row View
struct NoteRowView: View {
    @Bindable var note: ProductNote
    let modelContext: ModelContext
    
    @State private var showingEditSheet = false
    
    private var categoryColor: Color {
        switch note.category {
        case .general: return .gray
        case .production: return .blue
        case .quality: return .green
        case .improvement: return .yellow
        case .warning: return .orange
        case .reminder: return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: note.category.icon)
                    .foregroundStyle(categoryColor)
                
                Text(note.category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(categoryColor)
                
                Spacer()
                
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                Text(note.updatedAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(note.content)
                .font(.subheadline)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .swipeActions(edge: .leading) {
            Button {
                note.isPinned.toggle()
                try? modelContext.save()
            } label: {
                Label(note.isPinned ? "Unpin" : "Pin", systemImage: note.isPinned ? "pin.slash" : "pin")
            }
            .tint(.orange)
        }
        .sheet(isPresented: $showingEditSheet) {
            NoteEditView(product: note.product, note: note)
        }
    }
}

// MARK: - Note Edit View
struct NoteEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let product: Product?
    let note: ProductNote?
    
    @State private var content = ""
    @State private var category: NoteCategory = .general
    @State private var isPinned = false
    
    private var isEditing: Bool { note != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
                
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(NoteCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }
                
                Section {
                    Toggle(isOn: $isPinned) {
                        Label("Pin Note", systemImage: "pin.fill")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Note" : "New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(content.isEmpty)
                }
            }
            .onAppear {
                if let note = note {
                    content = note.content
                    category = note.category
                    isPinned = note.isPinned
                }
            }
        }
    }
    
    private func saveNote() {
        if let note = note {
            note.content = content
            note.category = category
            note.isPinned = isPinned
            note.updatedAt = Date()
        } else if let product = product {
            let newNote = ProductNote(
                content: content,
                category: category,
                isPinned: isPinned,
                product: product
            )
            modelContext.insert(newNote)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ProductNotesView(product: Product(name: "Test Product"))
    }
    .modelContainer(for: [Product.self, ProductNote.self], inMemory: true)
}
