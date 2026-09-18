import SwiftUI
import UniformTypeIdentifiers

private enum Palette {
    static let ink = Color(red: 0.09, green: 0.09, blue: 0.09)
    static let muted = Color(red: 0.43, green: 0.43, blue: 0.43)
    static let paper = Color(red: 0.96, green: 0.96, blue: 0.96)
    static let line = Color(red: 0.86, green: 0.86, blue: 0.86)
}

private extension ProjectColor {
    var tint: Color {
        switch self {
        case .blush: Color(red: 0.98, green: 0.84, blue: 0.87)
        case .peach: Color(red: 1.00, green: 0.88, blue: 0.78)
        case .butter: Color(red: 0.98, green: 0.93, blue: 0.72)
        case .mint: Color(red: 0.80, green: 0.93, blue: 0.85)
        case .sky: Color(red: 0.80, green: 0.89, blue: 0.98)
        case .lilac: Color(red: 0.88, green: 0.84, blue: 0.97)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: BoardStore
    @State private var showingNewProject = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("YOUR WORKSPACE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2.5)
                            .foregroundStyle(Palette.muted)
                        Text("Boards")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.ink)
                        Text("Make space for what matters.")
                            .foregroundStyle(Palette.muted)
                    }
                    .padding(.top, 18)

                    if store.projects.isEmpty {
                        ContentUnavailableView("No projects yet", systemImage: "rectangle.split.3x1",
                                               description: Text("Create a project to start organizing your tasks."))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(store.projects) { project in
                                NavigationLink(value: project.id) {
                                    HStack(alignment: .top, spacing: 16) {
                                        Image(systemName: "square.grid.2x2.fill")
                                            .font(.title3)
                                            .frame(width: 48, height: 48)
                                            .background(project.color.tint, in: RoundedRectangle(cornerRadius: 13))
                                            .foregroundStyle(Palette.ink)
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(project.name)
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundStyle(Palette.ink)
                                            Text("\(project.tasks.count) tasks  ·  \(project.columns.count) columns")
                                                .font(.subheadline)
                                                .foregroundStyle(Palette.muted)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.up.right")
                                            .foregroundStyle(Palette.muted)
                                    }
                                    .padding(20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(project.color.tint.opacity(0.42), in: RoundedRectangle(cornerRadius: 20))
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Palette.line))
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Delete project", systemImage: "trash", role: .destructive) {
                                        store.deleteProject(project.id)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(22)
            }
            .background(Palette.paper)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewProject = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                            .foregroundStyle(Palette.ink)
                    }
                    .accessibilityLabel("New project")
                }
            }
            .navigationDestination(for: UUID.self) { BoardView(projectID: $0) }
            .sheet(isPresented: $showingNewProject) { ProjectEditor(project: nil) }
        }
        .tint(Palette.ink)
    }
}

private struct BoardView: View {
    @EnvironmentObject private var store: BoardStore
    let projectID: UUID
    @State private var showingNewColumn = false
    @State private var columnName = ""
    @State private var editingTask: BoardTask?
    @State private var newTaskColumnID: UUID?
    @State private var renameColumn: BoardColumn?
    @State private var editingProject = false

    private var project: BoardProject? { store.project(projectID) }

    var body: some View {
        Group {
            if let project {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(project.columns) { column in
                            columnView(column, project: project)
                        }
                        Button { showingNewColumn = true } label: {
                            Label("Add column", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 230, height: 56)
                                .background(.white, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.line, style: StrokeStyle(dash: [6])))
                        }
                        .foregroundStyle(Palette.ink)
                    }
                    .padding(18)
                }
                .background(Palette.paper)
                .navigationTitle(project.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Edit project", systemImage: "pencil") { editingProject = true }
                            Button("Add column", systemImage: "plus") { showingNewColumn = true }
                        } label: { Image(systemName: "ellipsis.circle") }
                    }
                }
            }
        }
        .alert("New column", isPresented: $showingNewColumn) {
            TextField("Column name", text: $columnName)
            Button("Cancel", role: .cancel) { columnName = "" }
            Button("Add") {
                if !columnName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    store.addColumn(to: projectID, name: columnName)
                }
                columnName = ""
            }
        }
        .sheet(isPresented: $editingProject) {
            if let project { ProjectEditor(project: project) }
        }
        .alert("Rename column", isPresented: Binding(get: { renameColumn != nil }, set: { if !$0 { renameColumn = nil } })) {
            TextField("Column name", text: $columnName)
            Button("Cancel", role: .cancel) { renameColumn = nil }
            Button("Save") {
                if let column = renameColumn, !columnName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    store.renameColumn(column.id, in: projectID, to: columnName)
                }
                renameColumn = nil
                columnName = ""
            }
        }
        .sheet(item: $editingTask) { task in
            TaskEditor(projectID: projectID, task: task, initialColumnID: task.columnID)
        }
        .sheet(item: $newTaskColumnID) { columnID in
            TaskEditor(projectID: projectID, task: nil, initialColumnID: columnID)
        }
    }

    private func columnView(_ column: BoardColumn, project: BoardProject) -> some View {
        let tasks = project.tasks.filter { $0.columnID == column.id }
        return VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
                    .accessibilityHidden(true)
                Text(column.name.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                Text("\(tasks.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Palette.muted)
                Spacer()
                Menu {
                    Button("Rename", systemImage: "pencil") {
                        columnName = column.name
                        renameColumn = column
                    }
                    if let index = project.columns.firstIndex(where: { $0.id == column.id }) {
                        if index > 0 {
                            Button("Move left", systemImage: "arrow.left") {
                                store.moveColumn(column.id, in: projectID, to: project.columns[index - 1].id)
                            }
                        }
                        if index < project.columns.count - 1 {
                            Button("Move right", systemImage: "arrow.right") {
                                store.moveColumn(column.id, in: projectID, to: project.columns[index + 1].id)
                            }
                        }
                    }
                    if project.columns.count > 1 {
                        Button("Delete column", systemImage: "trash", role: .destructive) {
                            store.deleteColumn(column.id, in: projectID)
                        }
                    }
                } label: { Image(systemName: "ellipsis").foregroundStyle(Palette.muted) }
            }
            .padding(.horizontal, 3)
            .draggable(column.id.uuidString)
            .accessibilityHint("Drag to reorder columns")

            ForEach(tasks) { task in
                Button { editingTask = task } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(task.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .multilineTextAlignment(.leading)
                        if !task.details.isEmpty {
                            Text(task.details)
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        HStack {
                            Image(systemName: "circle.dotted")
                            Text("TASK")
                                .tracking(1)
                            Spacer()
                            Image(systemName: "arrow.left.arrow.right")
                        }
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Palette.muted)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background((task.color ?? project.color).tint, in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Palette.line))
                }
                .buttonStyle(.plain)
                .draggable(task.id.uuidString)
                .contextMenu {
                    ForEach(project.columns.filter { $0.id != column.id }) { destination in
                        Button("Move to \(destination.name)") {
                            store.moveTask(task.id, in: projectID, to: destination.id)
                        }
                    }
                    Button("Delete task", role: .destructive) {
                        store.deleteTask(task.id, in: projectID)
                    }
                }
            }

            Button { newTaskColumnID = column.id } label: {
                Label("Add task", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 13))
            }
            .foregroundStyle(Palette.muted)
            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(width: 292, alignment: .topLeading)
        .frame(minHeight: 300, alignment: .top)
        .background(Color(red: 0.92, green: 0.92, blue: 0.92), in: RoundedRectangle(cornerRadius: 21))
        .dropDestination(for: String.self) { items, _ in
            guard let first = items.first, let id = UUID(uuidString: first) else { return false }
            if project.tasks.contains(where: { $0.id == id }) {
                store.moveTask(id, in: projectID, to: column.id)
                return true
            }
            if project.columns.contains(where: { $0.id == id }) {
                store.moveColumn(id, in: projectID, to: column.id)
                return true
            }
            return false
        }
    }
}

private struct ProjectEditor: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    let project: BoardProject?
    @State private var name: String
    @State private var color: ProjectColor

    init(project: BoardProject?) {
        self.project = project
        _name = State(initialValue: project?.name ?? "")
        _color = State(initialValue: project?.color ?? .lilac)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Project name", text: $name)
                }
                Section("Pastel color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 14) {
                        ForEach(ProjectColor.allCases) { option in
                            Button {
                                color = option
                            } label: {
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(option.tint)
                                        .frame(width: 54, height: 54)
                                        .overlay {
                                            if color == option {
                                                Image(systemName: "checkmark")
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(Palette.ink)
                                            }
                                        }
                                    Text(option.name)
                                        .font(.caption)
                                        .foregroundStyle(Palette.ink)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(option.name) project color")
                            .accessibilityAddTraits(color == option ? [.isSelected] : [])
                        }
                    }
                    .padding(.vertical, 8)
                }
                Section {
                    Text("Tasks use this color unless you choose a different color for an individual task.")
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                }
            }
            .navigationTitle(project == nil ? "New project" : "Edit project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(project == nil ? "Create" : "Save") {
                        if let project {
                            store.updateProject(project.id, name: name, color: color)
                        } else {
                            store.addProject(name, color: color)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .tint(Palette.ink)
    }
}

private struct TaskEditor: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    let projectID: UUID
    let task: BoardTask?
    let initialColumnID: UUID
    @State private var title = ""
    @State private var details = ""
    @State private var colorChoice: String
    @State private var columnID: UUID

    init(projectID: UUID, task: BoardTask?, initialColumnID: UUID) {
        self.projectID = projectID
        self.task = task
        self.initialColumnID = initialColumnID
        _columnID = State(initialValue: initialColumnID)
        _colorChoice = State(initialValue: task?.color?.rawValue ?? "board")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("What needs doing?", text: $title)
                    TextField("Details (optional)", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Column") {
                    Picker("Move to", selection: $columnID) {
                        ForEach(store.project(projectID)?.columns ?? []) { column in
                            Text(column.name).tag(column.id)
                        }
                    }
                }
                Section("Task color") {
                    Picker("Color", selection: $colorChoice) {
                        HStack {
                            Circle()
                                .fill(store.project(projectID)?.color.tint ?? Palette.paper)
                                .frame(width: 18, height: 18)
                            Text("Board color")
                        }
                        .tag("board")
                        ForEach(ProjectColor.allCases) { option in
                            HStack {
                                Circle().fill(option.tint).frame(width: 18, height: 18)
                                Text(option.name)
                            }
                            .tag(option.rawValue)
                        }
                    }
                }
                if let task {
                    Section {
                        Button("Delete task", role: .destructive) {
                            store.deleteTask(task.id, in: projectID)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(task == nil ? "New task" : "Edit task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let task {
                            store.updateTask(task.id, in: projectID, title: title, details: details,
                                             columnID: columnID, color: ProjectColor(rawValue: colorChoice))
                        } else {
                            store.addTask(to: projectID, columnID: columnID, title: title,
                                          details: details, color: ProjectColor(rawValue: colorChoice))
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                title = task?.title ?? ""
                details = task?.details ?? ""
            }
        }
        .tint(Palette.ink)
    }
}

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
