import SwiftUI
import UniformTypeIdentifiers

private struct KanbanettiProjectDocument: FileDocument {
  static let readableContentTypes: [UTType] = [.json]

  let project: BoardProject

  init(project: BoardProject) {
    self.project = project
  }

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }
    project = try JSONDecoder().decode(BoardProject.self, from: data)
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return FileWrapper(regularFileWithContents: try encoder.encode(project))
  }
}

private enum Palette {
  static let ink = Color(red: 0.94, green: 0.94, blue: 0.94)
  static let muted = Color(red: 0.66, green: 0.66, blue: 0.68)
  static let paper = Color(red: 0.055, green: 0.055, blue: 0.065)
  static let surface = Color(red: 0.105, green: 0.105, blue: 0.12)
  static let raised = Color(red: 0.15, green: 0.15, blue: 0.17)
  static let line = Color(red: 0.25, green: 0.25, blue: 0.28)
  static let onPastel = Color(red: 0.10, green: 0.10, blue: 0.11)
}

extension ProjectColor {
  fileprivate var tint: Color {
    switch self {
    case .blush: Color(red: 1.00, green: 0.57, blue: 0.70)
    case .coral: Color(red: 1.00, green: 0.48, blue: 0.42)
    case .peach: Color(red: 1.00, green: 0.67, blue: 0.39)
    case .tangerine: Color(red: 1.00, green: 0.53, blue: 0.18)
    case .butter: Color(red: 1.00, green: 0.86, blue: 0.35)
    case .lemon: Color(red: 0.95, green: 0.96, blue: 0.31)
    case .lime: Color(red: 0.65, green: 0.94, blue: 0.30)
    case .mint: Color(red: 0.37, green: 0.92, blue: 0.58)
    case .teal: Color(red: 0.25, green: 0.88, blue: 0.76)
    case .aqua: Color(red: 0.26, green: 0.88, blue: 0.94)
    case .sky: Color(red: 0.39, green: 0.73, blue: 1.00)
    case .cobalt: Color(red: 0.43, green: 0.55, blue: 1.00)
    case .lilac: Color(red: 0.67, green: 0.52, blue: 1.00)
    case .violet: Color(red: 0.79, green: 0.45, blue: 1.00)
    case .magenta: Color(red: 0.98, green: 0.42, blue: 0.88)
    }
  }
}

private struct TaskEditorPresentation: Identifiable {
  let id = UUID()
  let task: BoardTask?
  let columnID: UUID
}

private struct CardDragState: Equatable {
  let taskID: UUID
  var translation: CGSize
}

private func edgeStackOffset(
  for cardFrame: CGRect,
  cardIndex: Int,
  cardCount: Int,
  scrollportFrame: CGRect?
) -> CGFloat {
  guard let scrollportFrame else { return 0 }

  let stackStep: CGFloat = 12
  let maximumVisibleLayers = 5
  let topLayer = min(cardIndex, maximumVisibleLayers)
  let bottomLayer = min(cardCount - cardIndex - 1, maximumVisibleLayers)
  let topLimit = scrollportFrame.minY + CGFloat(topLayer) * stackStep
  let bottomLimit = scrollportFrame.maxY - cardFrame.height - CGFloat(bottomLayer) * stackStep

  guard topLimit <= bottomLimit else { return 0 }
  let displayedMinY = min(max(cardFrame.minY, topLimit), bottomLimit)
  return displayedMinY - cardFrame.minY
}

struct ContentView: View {
  @EnvironmentObject private var store: BoardStore
  @State private var showingNewProject = false
  @State private var showingProjectImporter = false
  @State private var importErrorMessage: String?

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
            ContentUnavailableView(
              "No projects yet", systemImage: "rectangle.split.3x1",
              description: Text("Create a project to start organizing your tasks.")
            )
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
                      .foregroundStyle(Palette.onPastel)
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
                  .background(
                    project.color.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 20)
                  )
                  .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                      .fill(project.color.tint)
                      .frame(width: 4)
                      .padding(.vertical, 15)
                  }
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
        ToolbarItemGroup(placement: .topBarTrailing) {
          Button {
            showingProjectImporter = true
          } label: {
            Image(systemName: "square.and.arrow.down")
          }
          .accessibilityLabel("Import project")

          Button {
            showingNewProject = true
          } label: {
            Image(systemName: "plus")
              .fontWeight(.bold)
              .foregroundStyle(Palette.ink)
          }
          .accessibilityLabel("New project")
        }
      }
      .navigationDestination(for: UUID.self) { BoardView(projectID: $0) }
      .sheet(isPresented: $showingNewProject) { ProjectEditor(project: nil) }
      .fileImporter(
        isPresented: $showingProjectImporter,
        allowedContentTypes: [.json]
      ) { result in
        importProject(from: result)
      }
      .alert(
        "Unable to import project",
        isPresented: Binding(
          get: { importErrorMessage != nil },
          set: { if !$0 { importErrorMessage = nil } })
      ) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(importErrorMessage ?? "The selected file could not be imported.")
      }
    }
    .tint(Palette.ink)
  }

  private func importProject(from result: Result<URL, Error>) {
    do {
      let url = try result.get()
      let hasAccess = url.startAccessingSecurityScopedResource()
      defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
      let data = try Data(contentsOf: url)
      let project = try JSONDecoder().decode(BoardProject.self, from: data)
      store.importProject(project)
    } catch {
      importErrorMessage = error.localizedDescription
    }
  }
}

private struct BoardView: View {
  @EnvironmentObject private var store: BoardStore
  let projectID: UUID
  @State private var showingNewColumn = false
  @State private var taskEditorPresentation: TaskEditorPresentation?
  @State private var editingColumn: BoardColumn?
  @State private var editingProject = false
  @State private var selectedOpportunityID: UUID?
  @State private var cardFrames: [UUID: CGRect] = [:]
  @State private var columnScrollportFrames: [UUID: CGRect] = [:]
  @State private var cardDragState: CardDragState?
  @State private var suppressedCardTapID: UUID?
  @State private var exportDocument: KanbanettiProjectDocument?
  @State private var showingProjectExporter = false
  @State private var exportErrorMessage: String?

  private var project: BoardProject? { store.project(projectID) }

  private var isTaskEditorPresented: Binding<Bool> {
    Binding(
      get: { taskEditorPresentation != nil },
      set: { isPresented in
        if !isPresented { taskEditorPresentation = nil }
      })
  }

  var body: some View {
    Group {
      if let project {
        GeometryReader { geometry in
          ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 14) {
              ForEach(project.columns) { column in
                columnView(column, project: project, viewportHeight: geometry.size.height)
              }
              Button {
                showingNewColumn = true
              } label: {
                Label("Add column", systemImage: "plus")
                  .font(.subheadline.weight(.semibold))
                  .frame(width: 230, height: 56)
                  .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16))
                  .overlay(
                    RoundedRectangle(cornerRadius: 16).stroke(
                      Palette.line, style: StrokeStyle(dash: [6])))
              }
              .foregroundStyle(Palette.ink)
            }
            .padding(18)
            .coordinateSpace(name: "board")
            .overlay {
              ZStack {
                Canvas { context, _ in
                  context.drawLayer { connectorLayer in
                    drawConnectors(for: project, context: &connectorLayer)
                    maskCardInteriors(for: project, context: &connectorLayer)
                  }
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                draggedCardOverlay(in: project)
              }
              .zIndex(100)
            }
          }
          .scrollClipDisabled()
          .background(Palette.paper)
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Menu {
              Button("Edit project", systemImage: "pencil") { editingProject = true }
              Button("Add column", systemImage: "plus") { showingNewColumn = true }
              Button("Export project", systemImage: "square.and.arrow.up") {
                exportDocument = KanbanettiProjectDocument(project: project)
                showingProjectExporter = true
              }
            } label: {
              Image(systemName: "ellipsis.circle")
            }
          }
        }
      }
    }
    .sheet(isPresented: $showingNewColumn) {
      ColumnEditor(projectID: projectID, column: nil, isLeadColumn: false)
    }
    .sheet(isPresented: $editingProject) {
      if let project { ProjectEditor(project: project) }
    }
    .sheet(item: $editingColumn) { column in
      ColumnEditor(
        projectID: projectID, column: column,
        isLeadColumn: project?.columns.first?.id == column.id)
    }
    .sheet(isPresented: isTaskEditorPresented) {
      if let presentation = taskEditorPresentation {
        TaskEditor(
          projectID: projectID, task: presentation.task, initialColumnID: presentation.columnID,
          isPresented: isTaskEditorPresented)
      }
    }
    .fileExporter(
      isPresented: $showingProjectExporter,
      document: exportDocument,
      contentType: .json,
      defaultFilename: exportFilename
    ) { result in
      if case .failure(let error) = result {
        exportErrorMessage = error.localizedDescription
      }
    }
    .alert(
      "Unable to export project",
      isPresented: Binding(
        get: { exportErrorMessage != nil },
        set: { if !$0 { exportErrorMessage = nil } })
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(exportErrorMessage ?? "The project could not be exported.")
    }
  }

  private var exportFilename: String {
    let name = project?.name ?? "Kanbanetti Project"
    return name.replacingOccurrences(of: "/", with: "-") + ".kanbanetti.json"
  }

  private func columnView(_ column: BoardColumn, project: BoardProject, viewportHeight: CGFloat)
    -> some View
  {
    let tasks = project.tasks.filter { $0.columnID == column.id }
    let isLeadColumn = project.columns.first?.id == column.id
    let scrollportFrame = columnScrollportFrames[column.id]
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
          Button(isLeadColumn ? "Change background" : "Edit column", systemImage: "paintpalette") {
            editingColumn = column
          }
          Button(
            column.isStacked ? "Unstack tasks" : "Stack tasks",
            systemImage: column.isStacked ? "rectangle.3.group" : "square.stack.3d.up"
          ) {
            withAnimation(.snappy) {
              store.toggleTaskStacking(in: column.id, projectID: projectID)
            }
          }
          if let index = project.columns.firstIndex(where: { $0.id == column.id }), !isLeadColumn {
            if index > 1 {
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
          if project.columns.count > 1, !isLeadColumn {
            Button("Delete column", systemImage: "trash", role: .destructive) {
              store.deleteColumn(column.id, in: projectID)
            }
          }
        } label: {
          Image(systemName: "ellipsis").foregroundStyle(Palette.muted)
        }
      }
      .padding(.horizontal, 3)
      .draggable(isLeadColumn ? "" : column.id.uuidString)
      .accessibilityHint("Drag to reorder columns")

      ScrollView(.vertical) {
        VStack(spacing: column.isStacked ? -44 : 15) {
          ForEach(Array(tasks.enumerated()), id: \.element.id) { cardIndex, task in
            let dragTranslation: CGSize =
              cardDragState?.taskID == task.id ? cardDragState?.translation ?? .zero : .zero
            ZStack(alignment: .bottomTrailing) {
              cardContent(task, isLeadColumn: isLeadColumn, project: project)

              Button {
                taskEditorPresentation = TaskEditorPresentation(
                  task: task, columnID: task.columnID)
              } label: {
                Image(systemName: "arrow.left.arrow.right")
                  .font(.system(size: 11, weight: .semibold))
                  .foregroundStyle(Palette.onPastel.opacity(0.7))
                  .frame(width: 44, height: 44)
                  .contentShape(Rectangle())
              }
              .buttonStyle(.plain)
              .accessibilityLabel(isLeadColumn ? "Edit opportunity" : "Edit task")
            }
            .contentShape(RoundedRectangle(cornerRadius: 15))
            .onTapGesture {
              guard suppressedCardTapID != task.id else { return }
              let opportunityID =
                isLeadColumn ? task.id : project.opportunity(for: task)?.id
              if let opportunityID {
                withAnimation(.easeInOut(duration: 0.2)) {
                  selectedOpportunityID =
                    selectedOpportunityID == opportunityID ? nil : opportunityID
                }
              }
            }
            .zIndex(cardDragState?.taskID == task.id ? 10_000 : Double(cardIndex))
            .opacity(
              cardDragState?.taskID == task.id
                ? 0 : cardOpacity(for: task, isLeadColumn: isLeadColumn)
            )
            .visualEffect { content, geometry in
              content.offset(
                x: dragTranslation.width,
                y: edgeStackOffset(
                  for: geometry.frame(in: .named("board")),
                  cardIndex: cardIndex,
                  cardCount: tasks.count,
                  scrollportFrame: scrollportFrame) + dragTranslation.height)
            }
            .onGeometryChange(for: CGRect.self) { geometry in
              geometry.frame(in: .named("board"))
            } action: { frame in
              cardFrames[task.id] = frame
            }
            .simultaneousGesture(
              DragGesture(minimumDistance: 8, coordinateSpace: .named("board"))
                .onChanged { value in
                  suppressedCardTapID = task.id
                  cardDragState = CardDragState(
                    taskID: task.id,
                    translation: value.translation)
                }
                .onEnded { value in
                  cardDragState = CardDragState(
                    taskID: task.id,
                    translation: value.translation)
                  completeCardDrag(task, in: project)
                  cardDragState = nil
                  Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(250))
                    if suppressedCardTapID == task.id {
                      suppressedCardTapID = nil
                    }
                  }
                }
            )
            .contextMenu {
              if isLeadColumn {
                Button("Edit opportunity", systemImage: "pencil") {
                  taskEditorPresentation = TaskEditorPresentation(
                    task: task, columnID: task.columnID)
                }
              }
              if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                if index > 0 {
                  Button("Move up", systemImage: "arrow.up") {
                    store.moveTaskWithinColumn(task.id, in: projectID, offset: -1)
                  }
                }
                if index < tasks.count - 1 {
                  Button("Move down", systemImage: "arrow.down") {
                    store.moveTaskWithinColumn(task.id, in: projectID, offset: 1)
                  }
                }
              }
              if !isLeadColumn {
                ForEach(
                  project.columns.filter {
                    $0.id != column.id && $0.id != project.columns.first?.id
                  }
                ) { destination in
                  Button("Move to \(destination.name)") {
                    store.moveTask(task.id, in: projectID, to: destination.id)
                  }
                }
              }
              Button("Delete task", role: .destructive) {
                store.deleteTask(task.id, in: projectID)
              }
            }
          }
        }
        .animation(.snappy, value: column.isStacked)
        .animation(.easeInOut(duration: 0.2), value: selectedOpportunityID)
        .padding(.vertical, 2)
      }
      .scrollIndicators(.visible)
      .scrollClipDisabled()
      .frame(height: max(190, viewportHeight - 185))
      .onGeometryChange(for: CGRect.self) { geometry in
        geometry.frame(in: .named("board"))
      } action: { frame in
        columnScrollportFrames[column.id] = frame
      }

      Button {
        taskEditorPresentation = TaskEditorPresentation(task: nil, columnID: column.id)
      } label: {
        Label(isLeadColumn ? "Add opportunity" : "Add task", systemImage: "plus")
          .font(.subheadline.weight(.semibold))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(14)
          .background(Palette.raised, in: RoundedRectangle(cornerRadius: 13))
      }
      .foregroundStyle(Palette.muted)
      Spacer(minLength: 0)
    }
    .padding(15)
    .frame(width: 292, alignment: .topLeading)
    .frame(minHeight: 300, alignment: .top)
    .background(columnBackground(column), in: RoundedRectangle(cornerRadius: 21))
    .overlay {
      RoundedRectangle(cornerRadius: 21)
        .stroke(Color.white.opacity(0.72), lineWidth: 1)
    }
    .zIndex(tasks.contains(where: { $0.id == cardDragState?.taskID }) ? 1_000 : 0)
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

  private func cardContent(_ task: BoardTask, isLeadColumn: Bool, project: BoardProject)
    -> some View
  {
    VStack(alignment: .leading, spacing: 12) {
      Text(task.title)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Palette.onPastel)
        .multilineTextAlignment(.leading)
      if !task.details.isEmpty {
        Text(task.details)
          .font(.subheadline)
          .foregroundStyle(Palette.onPastel.opacity(0.65))
          .lineLimit(3)
          .multilineTextAlignment(.leading)
      }
      HStack {
        Image(systemName: "circle.dotted")
        Text(isLeadColumn ? task.leadKind.name.uppercased() : "TASK")
          .tracking(1)
        if !isLeadColumn, let opportunity = project.opportunity(for: task) {
          Text("·  \(opportunity.title.uppercased())")
            .lineLimit(1)
        }
        Spacer()
      }
      .font(.system(size: 10, weight: .semibold, design: .monospaced))
      .foregroundStyle(Palette.onPastel.opacity(0.65))
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(taskColor(task, in: project).tint, in: RoundedRectangle(cornerRadius: 15))
    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Palette.line))
  }

  @ViewBuilder
  private func draggedCardOverlay(in project: BoardProject) -> some View {
    if let draggedTaskID = cardDragState?.taskID,
      let task = project.tasks.first(where: { $0.id == draggedTaskID }),
      let rawFrame = cardFrames[draggedTaskID]
    {
      let frame = displayedCardFrame(for: task, in: project, rawFrame: rawFrame)
      cardContent(task, isLeadColumn: task.columnID == project.leadColumnID, project: project)
        .overlay(alignment: .bottomTrailing) {
          Image(systemName: "arrow.left.arrow.right")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Palette.onPastel.opacity(0.7))
            .frame(width: 44, height: 44)
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .zIndex(1_000)
    }
  }

  private func cardOpacity(for task: BoardTask, isLeadColumn: Bool) -> Double {
    guard let selectedOpportunityID else { return 1 }
    if isLeadColumn { return task.id == selectedOpportunityID ? 1 : 0.25 }
    guard let project else { return 1 }
    return project.opportunity(for: task)?.id == selectedOpportunityID ? 1 : 0.25
  }

  private func completeCardDrag(_ task: BoardTask, in project: BoardProject) {
    guard let rawFrame = cardFrames[task.id] else { return }
    let finalFrame = displayedCardFrame(for: task, in: project, rawFrame: rawFrame)
    let isOpportunity = task.columnID == project.leadColumnID
    let eligibleColumns = project.columns.filter { column in
      isOpportunity ? column.id == project.leadColumnID : column.id != project.leadColumnID
    }
    guard
      let destination = eligibleColumns.min(by: { lhs, rhs in
        horizontalDistance(from: finalFrame.midX, to: lhs.id)
          < horizontalDistance(from: finalFrame.midX, to: rhs.id)
      })
    else { return }

    let destinationTasks = project.tasks.filter {
      $0.columnID == destination.id && $0.id != task.id
    }
    let insertionTarget = destinationTasks.first { candidate in
      guard let candidateRawFrame = cardFrames[candidate.id] else { return false }
      let candidateFrame = displayedCardFrame(
        for: candidate, in: project, rawFrame: candidateRawFrame)
      return finalFrame.midY < candidateFrame.midY
    }

    if let insertionTarget {
      store.moveTask(task.id, in: projectID, before: insertionTarget.id)
    } else {
      store.moveTaskToEnd(task.id, in: projectID, of: destination.id)
    }
  }

  private func horizontalDistance(from x: CGFloat, to columnID: UUID) -> CGFloat {
    guard let frame = columnScrollportFrames[columnID] else { return .greatestFiniteMagnitude }
    return abs(x - frame.midX)
  }

  private func taskColor(_ task: BoardTask, in project: BoardProject) -> ProjectColor {
    guard project.columns.first?.id != task.columnID,
      let opportunity = project.opportunity(for: task)
    else {
      return task.color ?? project.color
    }
    return opportunity.color ?? project.color
  }

  private func columnBackground(_ column: BoardColumn) -> Color {
    column.color?.tint.opacity(0.16) ?? Palette.surface
  }

  private func drawConnectors(for project: BoardProject, context: inout GraphicsContext) {
    for task in project.tasks {
      guard let opportunity = project.opportunity(for: task) else { continue }
      let opportunityID = opportunity.id
      guard let opportunityRawFrame = cardFrames[opportunityID],
        let taskRawFrame = cardFrames[task.id]
      else { continue }

      let opportunityFrame = displayedCardFrame(
        for: opportunity, in: project,
        rawFrame: opportunityRawFrame)
      let taskFrame = displayedCardFrame(
        for: task, in: project,
        rawFrame: taskRawFrame)
      let travelsRight = taskFrame.midX >= opportunityFrame.midX
      let start = cardEdgePoint(for: opportunityFrame, facingRight: travelsRight)
      let end = cardEdgePoint(for: taskFrame, facingRight: !travelsRight)
      let bend = max(42, abs(end.x - start.x) * 0.42)

      var path = Path()
      path.move(to: start)
      path.addCurve(
        to: end,
        control1: CGPoint(x: start.x + (travelsRight ? bend : -bend), y: start.y),
        control2: CGPoint(x: end.x - (travelsRight ? bend : -bend), y: end.y))

      context.stroke(
        path, with: .color(Palette.paper.opacity(0.92)),
        style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
      let connectorOpacity =
        selectedOpportunityID == nil || selectedOpportunityID == opportunityID ? 1.0 : 0.25
      context.stroke(
        path, with: .color((opportunity.color ?? project.color).tint.opacity(connectorOpacity)),
        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))

      let endpointSize: CGFloat = 8
      for point in [start, end] {
        let dot = CGRect(
          x: point.x - endpointSize / 2, y: point.y - endpointSize / 2,
          width: endpointSize, height: endpointSize)
        context.fill(
          Path(ellipseIn: dot.insetBy(dx: -2, dy: -2)),
          with: .color(Palette.paper.opacity(0.95)))
        context.fill(
          Path(ellipseIn: dot),
          with: .color((opportunity.color ?? project.color).tint.opacity(connectorOpacity)))
      }

    }
  }

  private func maskCardInteriors(for project: BoardProject, context: inout GraphicsContext) {
    context.blendMode = .destinationOut

    for task in project.tasks {
      guard let rawFrame = cardFrames[task.id] else { continue }
      let frame = displayedCardFrame(for: task, in: project, rawFrame: rawFrame)
      let interior = frame.insetBy(dx: 3, dy: 3)
      let borderPath = RoundedRectangle(cornerRadius: 15).path(in: frame.insetBy(dx: 0.5, dy: 0.5))
      let maskOpacity = connectorMaskOpacity(for: task, in: project)
      context.fill(
        RoundedRectangle(cornerRadius: 12).path(in: interior),
        with: .color(.black.opacity(maskOpacity)))
      context.stroke(
        borderPath,
        with: .color(.black),
        style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
    }
  }

  private func connectorMaskOpacity(for task: BoardTask, in project: BoardProject) -> Double {
    if let draggedTaskID = cardDragState?.taskID {
      return task.id == draggedTaskID ? 1 : 0
    }
    guard let selectedOpportunityID else { return 1 }
    let isOpportunity = task.columnID == project.leadColumnID
    let relatedOpportunityID = isOpportunity ? task.id : project.opportunity(for: task)?.id
    return relatedOpportunityID == selectedOpportunityID ? 1 : 0.25
  }

  private func displayedCardFrame(
    for task: BoardTask, in project: BoardProject,
    rawFrame: CGRect
  ) -> CGRect {
    let columnTasks = project.tasks.filter { $0.columnID == task.columnID }
    guard let index = columnTasks.firstIndex(where: { $0.id == task.id }) else { return rawFrame }
    var displayedFrame = rawFrame.offsetBy(
      dx: 0,
      dy: edgeStackOffset(
        for: rawFrame,
        cardIndex: index,
        cardCount: columnTasks.count,
        scrollportFrame: columnScrollportFrames[task.columnID]))
    if let cardDragState, cardDragState.taskID == task.id {
      displayedFrame = displayedFrame.offsetBy(
        dx: cardDragState.translation.width,
        dy: cardDragState.translation.height)
    }
    return displayedFrame
  }

  private func cardEdgePoint(for frame: CGRect, facingRight: Bool) -> CGPoint {
    // The connector has an 8-point terminal with a 2-point outline. Keeping its
    // centre six points outside the card makes the terminal touch the edge without
    // drawing over the card's border.
    let terminalRadius: CGFloat = 6
    return CGPoint(
      x: facingRight ? frame.maxX + terminalRadius : frame.minX - terminalRadius,
      y: frame.midY)
  }
}

private struct ColumnEditor: View {
  @EnvironmentObject private var store: BoardStore
  @Environment(\.dismiss) private var dismiss
  let projectID: UUID
  let column: BoardColumn?
  let isLeadColumn: Bool
  @State private var name: String
  @State private var colorChoice: String

  init(projectID: UUID, column: BoardColumn?, isLeadColumn: Bool) {
    self.projectID = projectID
    self.column = column
    self.isLeadColumn = isLeadColumn
    _name = State(initialValue: column?.name ?? "")
    _colorChoice = State(initialValue: column?.color?.rawValue ?? "none")
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Column") {
          if isLeadColumn {
            LabeledContent("Name", value: name)
          } else {
            TextField("Column name", text: $name)
          }
        }
        Section("Soft background") {
          Picker("Color", selection: $colorChoice) {
            HStack {
              Circle().fill(Palette.surface).frame(width: 18, height: 18)
              Text("Charcoal")
            }
            .tag("none")
            ForEach(ProjectColor.allCases) { option in
              HStack {
                Circle().fill(option.tint.opacity(0.55)).frame(width: 18, height: 18)
                Text(option.name)
              }
              .tag(option.rawValue)
            }
          }
          Text(
            "The selected color is softened against the dark board so cards and connectors stay clear."
          )
          .font(.footnote)
          .foregroundStyle(Palette.muted)
        }
      }
      .navigationTitle(column == nil ? "New column" : "Edit column")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button(column == nil ? "Add" : "Save") {
            let color = ProjectColor(rawValue: colorChoice)
            if let column {
              store.updateColumn(column.id, in: projectID, name: name, color: color)
            } else {
              store.addColumn(to: projectID, name: name, color: color)
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
        Section("Board color") {
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
                          .foregroundStyle(Palette.onPastel)
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
          Text(
            "New opportunities start with this color, and you can give each opportunity its own bright color."
          )
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
  @Binding var isPresented: Bool
  @State private var title = ""
  @State private var details = ""
  @State private var colorChoice: String
  @State private var columnID: UUID
  @State private var opportunityID: UUID?
  @State private var leadKind: LeadKind

  init(
    projectID: UUID, task: BoardTask?, initialColumnID: UUID,
    isPresented: Binding<Bool>
  ) {
    self.projectID = projectID
    self.task = task
    self.initialColumnID = initialColumnID
    _isPresented = isPresented
    _columnID = State(initialValue: initialColumnID)
    _colorChoice = State(initialValue: task?.color?.rawValue ?? "board")
    _opportunityID = State(initialValue: task?.opportunityID)
    _leadKind = State(initialValue: task?.leadKind ?? .opportunity)
  }

  private var project: BoardProject? { store.project(projectID) }
  private var isOpportunity: Bool { project?.columns.first?.id == columnID }
  private var opportunities: [BoardTask] {
    guard let leadColumnID = project?.columns.first?.id else { return [] }
    return project?.tasks.filter { $0.columnID == leadColumnID && $0.id != task?.id } ?? []
  }

  private func closeEditor() {
    isPresented = false
    dismiss()
  }

  private var saveDisabled: Bool {
    title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      || (!isOpportunity && opportunityID == nil)
  }

  private func saveEditor() {
    if let task {
      store.updateTask(
        task.id, in: projectID, title: title, details: details,
        columnID: columnID,
        color: isOpportunity ? ProjectColor(rawValue: colorChoice) : nil,
        opportunityID: isOpportunity ? nil : opportunityID,
        leadKind: isOpportunity ? leadKind : task.leadKind)
    } else {
      store.addTask(
        to: projectID, columnID: columnID, title: title,
        details: details,
        color: isOpportunity ? ProjectColor(rawValue: colorChoice) : nil,
        opportunityID: isOpportunity ? nil : opportunityID,
        leadKind: isOpportunity ? leadKind : .opportunity)
    }
    closeEditor()
  }

  private var editorActions: some View {
    HStack {
      Text("Cancel")
        .foregroundStyle(Palette.ink)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { closeEditor() }
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { closeEditor() }
      Spacer()
      Button("Save") { saveEditor() }
        .fontWeight(.semibold)
        .disabled(saveDisabled)
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 10)
    .background(Palette.paper)
  }

  var body: some View {
    NavigationStack {
      Form {
        Section(isOpportunity ? "Opportunity lead" : "Task") {
          TextField(isOpportunity ? "Opportunity name" : "What needs doing?", text: $title)
          TextField("Details (optional)", text: $details, axis: .vertical)
            .lineLimit(3...6)
        }
        Section("Column") {
          if task != nil, project?.columns.first?.id == task?.columnID {
            LabeledContent("Stage", value: project?.columns.first?.name ?? "Opportunity Leads")
          } else {
            Picker("Move to", selection: $columnID) {
              ForEach(project?.columns ?? []) { column in
                Text(column.name).tag(column.id)
              }
            }
          }
        }
        if isOpportunity {
          Section("Lead type") {
            Picker("Show on card", selection: $leadKind) {
              ForEach(LeadKind.allCases) { kind in
                Text(kind.name).tag(kind)
              }
            }
            .pickerStyle(.segmented)
          }
          Section("Opportunity color") {
            Picker("Color", selection: $colorChoice) {
              HStack {
                Circle()
                  .fill(project?.color.tint ?? Palette.paper)
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
            Text("All tasks linked to this opportunity will use this color.")
              .font(.footnote)
              .foregroundStyle(Palette.muted)
          }
        } else {
          Section("Opportunity") {
            if opportunities.isEmpty {
              Label(
                "Create an opportunity lead in the first column before adding tasks.",
                systemImage: "exclamationmark.circle"
              )
              .font(.footnote)
              .foregroundStyle(Palette.muted)
            } else {
              Picker("Related opportunity", selection: $opportunityID) {
                Text("Select opportunity").tag(nil as UUID?)
                ForEach(opportunities) { opportunity in
                  Text(opportunity.title).tag(opportunity.id as UUID?)
                }
              }
            }
          }
        }
        if let task {
          Section {
            Button("Delete task", role: .destructive) {
              store.deleteTask(task.id, in: projectID)
              closeEditor()
            }
          }
        }
      }
      .navigationTitle(task == nil ? "New task" : "Edit task")
      .navigationBarTitleDisplayMode(.inline)
#if targetEnvironment(macCatalyst)
      .safeAreaInset(edge: .top, spacing: 0) {
        editorActions
      }
#else
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) { closeEditor() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { saveEditor() }
          .fontWeight(.semibold)
          .disabled(saveDisabled)
        }
      }
#endif
      .onAppear {
        title = task?.title ?? ""
        details = task?.details ?? ""
        if task == nil, isOpportunity, let project {
          colorChoice = project.nextLeadColor().rawValue
        }
        if !isOpportunity, opportunityID == nil { opportunityID = opportunities.first?.id }
      }
    }
    .tint(Palette.ink)
  }
}
