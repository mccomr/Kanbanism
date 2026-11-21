import Combine
import Foundation

enum LeadKind: String, CaseIterable, Codable, Identifiable {
  case opportunity
  case partner
  case vendor

  var id: String { rawValue }
  var name: String { rawValue.capitalized }
}

struct BoardTask: Identifiable, Codable, Equatable {
  var id: UUID = UUID()
  var title: String
  var details: String = ""
  var color: ProjectColor? = nil
  var opportunityID: UUID? = nil
  var leadKind: LeadKind = .opportunity
  var isUrgent: Bool = false
  var columnID: UUID
  var createdAt: Date = Date()

  private enum CodingKeys: String, CodingKey {
    case id, title, details, color, opportunityID, leadKind, isUrgent, columnID, createdAt
  }

  init(
    id: UUID = UUID(), title: String, details: String = "", color: ProjectColor? = nil,
    opportunityID: UUID? = nil,
    leadKind: LeadKind = .opportunity,
    isUrgent: Bool = false,
    columnID: UUID, createdAt: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.details = details
    self.color = color
    self.opportunityID = opportunityID
    self.leadKind = leadKind
    self.isUrgent = isUrgent
    self.columnID = columnID
    self.createdAt = createdAt
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(UUID.self, forKey: .id)
    title = try values.decode(String.self, forKey: .title)
    details = try values.decode(String.self, forKey: .details)
    color = try values.decodeIfPresent(ProjectColor.self, forKey: .color)
    opportunityID = try values.decodeIfPresent(UUID.self, forKey: .opportunityID)
    leadKind = try values.decodeIfPresent(LeadKind.self, forKey: .leadKind) ?? .opportunity
    isUrgent = try values.decodeIfPresent(Bool.self, forKey: .isUrgent) ?? false
    columnID = try values.decode(UUID.self, forKey: .columnID)
    createdAt = try values.decode(Date.self, forKey: .createdAt)
  }
}

struct BoardColumn: Identifiable, Codable, Equatable {
  var id: UUID = UUID()
  var name: String
  var color: ProjectColor? = nil
  var stacksTasks: Bool? = nil
  var usesCompactWidth: Bool? = nil

  var isStacked: Bool { stacksTasks == true }
  var isCompact: Bool { usesCompactWidth == true }
}

enum ProjectColor: String, CaseIterable, Codable, Identifiable {
  case blush, coral, peach, tangerine, butter, lemon, lime, mint
  case teal, aqua, sky, cobalt, lilac, violet, magenta

  var id: String { rawValue }
  var name: String { rawValue.capitalized }
}

struct BoardProject: Identifiable, Codable, Equatable {
  var id: UUID = UUID()
  var name: String
  var color: ProjectColor = .lilac
  var columns: [BoardColumn] = [
    BoardColumn(name: "Opportunity Leads"),
    BoardColumn(name: "In Progress"),
    BoardColumn(name: "Done"),
  ]
  var tasks: [BoardTask] = []

  private enum CodingKeys: String, CodingKey { case id, name, color, columns, tasks }

  init(id: UUID = UUID(), name: String, color: ProjectColor = .lilac) {
    self.id = id
    self.name = name
    self.color = color
  }

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(UUID.self, forKey: .id)
    name = try values.decode(String.self, forKey: .name)
    color = try values.decodeIfPresent(ProjectColor.self, forKey: .color) ?? .lilac
    columns = try values.decode([BoardColumn].self, forKey: .columns)
    if let firstIndex = columns.indices.first, columns[firstIndex].name == "To Do" {
      columns[firstIndex].name = "Opportunity Leads"
    }
    tasks = try values.decode([BoardTask].self, forKey: .tasks)
  }
}

extension BoardProject {
  static var starterProjects: [BoardProject] {
    [enterpriseSalesPipeline, strategicPartnerships]
  }

  private static var enterpriseSalesPipeline: BoardProject {
    let leads = BoardColumn(name: "Opportunity Leads", color: .sky)
    let qualified = BoardColumn(name: "Qualified", color: .aqua)
    let proposal = BoardColumn(name: "Proposal", color: .butter)
    let negotiation = BoardColumn(name: "Negotiation", color: .peach)
    let won = BoardColumn(name: "Won", color: .mint)

    let northstar = BoardTask(
      title: "Northstar Retail", details: "National inventory visibility platform",
      color: .coral, leadKind: .opportunity, columnID: leads.id)
    let apex = BoardTask(
      title: "Apex Logistics", details: "Fleet operations and analytics rollout",
      color: .cobalt, leadKind: .opportunity, columnID: leads.id)
    let greenline = BoardTask(
      title: "Greenline Health", details: "Patient services workflow modernisation",
      color: .lime, leadKind: .opportunity, columnID: leads.id)

    var project = BoardProject(name: "Enterprise Sales Pipeline", color: .sky)
    project.columns = [leads, qualified, proposal, negotiation, won]
    project.tasks = [
      northstar,
      apex,
      greenline,
      BoardTask(
        title: "Confirm executive sponsor", details: "Book a 30-minute discovery call",
        color: northstar.color, opportunityID: northstar.id, columnID: qualified.id),
      BoardTask(
        title: "Map store integration requirements", details: "Document POS and ERP interfaces",
        color: northstar.color, opportunityID: northstar.id, columnID: proposal.id),
      BoardTask(
        title: "Prepare value assessment", details: "Model savings from reduced stock-outs",
        color: northstar.color, opportunityID: northstar.id, columnID: negotiation.id),
      BoardTask(
        title: "Complete fleet discovery", details: "Review depots, vehicles and reporting needs",
        color: apex.color, opportunityID: apex.id, columnID: qualified.id),
      BoardTask(
        title: "Send solution proposal", details: "Include rollout plan and support options",
        color: apex.color, opportunityID: apex.id, columnID: proposal.id),
      BoardTask(
        title: "Run security workshop", details: "Cover privacy, access and audit requirements",
        color: greenline.color, opportunityID: greenline.id, columnID: qualified.id),
      BoardTask(
        title: "Agree pilot scope", details: "Select the first two clinic locations",
        color: greenline.color, opportunityID: greenline.id, columnID: proposal.id),
    ]
    return project
  }

  private static var strategicPartnerships: BoardProject {
    let leads = BoardColumn(name: "Opportunity Leads", color: .lilac)
    let discovery = BoardColumn(name: "Discovery", color: .sky)
    let diligence = BoardColumn(name: "Due Diligence", color: .butter)
    let agreement = BoardColumn(name: "Agreement", color: .peach)
    let launched = BoardColumn(name: "Launched", color: .mint)

    let brightPath = BoardTask(
      title: "BrightPath Consulting", details: "Regional referral and delivery partnership",
      color: .violet, leadKind: .partner, columnID: leads.id)
    let cloudBridge = BoardTask(
      title: "CloudBridge Systems", details: "Technology integration and co-marketing partner",
      color: .aqua, leadKind: .partner, columnID: leads.id)
    let signalWorks = BoardTask(
      title: "SignalWorks CRM", details: "CRM supplier for lead and customer synchronisation",
      color: .tangerine, leadKind: .vendor, columnID: leads.id)

    var project = BoardProject(name: "Strategic Partnerships", color: .lilac)
    project.columns = [leads, discovery, diligence, agreement, launched]
    project.tasks = [
      brightPath,
      cloudBridge,
      signalWorks,
      BoardTask(
        title: "Define ideal customer profile", details: "Agree target industries and account size",
        color: brightPath.color, opportunityID: brightPath.id, columnID: discovery.id),
      BoardTask(
        title: "Review delivery capability", details: "Validate coverage, skills and references",
        color: brightPath.color, opportunityID: brightPath.id, columnID: diligence.id),
      BoardTask(
        title: "Draft referral terms", details: "Set lead registration and revenue share rules",
        color: brightPath.color, opportunityID: brightPath.id, columnID: agreement.id),
      BoardTask(
        title: "Design integration workshop", details: "Map product and API touchpoints",
        color: cloudBridge.color, opportunityID: cloudBridge.id, columnID: discovery.id),
      BoardTask(
        title: "Build joint launch plan", details: "Coordinate announcement, webinar and case study",
        color: cloudBridge.color, opportunityID: cloudBridge.id, columnID: agreement.id),
      BoardTask(
        title: "Complete security review", details: "Assess data handling and service controls",
        color: signalWorks.color, opportunityID: signalWorks.id, columnID: diligence.id),
      BoardTask(
        title: "Approve supplier agreement", details: "Finalise support levels and renewal terms",
        color: signalWorks.color, opportunityID: signalWorks.id, columnID: launched.id),
    ]
    return project
  }
}

extension BoardProject {
  var leadColumnID: UUID? { columns.first?.id }

  var opportunities: [BoardTask] {
    guard let leadColumnID else { return [] }
    return tasks.filter { $0.columnID == leadColumnID }
  }

  func nextLeadColor(excluding taskID: UUID? = nil) -> ProjectColor {
    let leadColors =
      opportunities
      .filter { $0.id != taskID }
      .map { $0.color ?? color }
    let usedColors = Set(leadColors)

    if let unusedColor = ProjectColor.allCases.first(where: { !usedColors.contains($0) }) {
      return unusedColor
    }

    let colorCounts = Dictionary(grouping: leadColors, by: { $0 }).mapValues(\.count)
    return ProjectColor.allCases.min {
      colorCounts[$0, default: 0] < colorCounts[$1, default: 0]
    } ?? color
  }

  func opportunity(for task: BoardTask) -> BoardTask? {
    guard task.columnID != leadColumnID else { return nil }

    if let opportunityID = task.opportunityID,
      let linkedOpportunity = opportunities.first(where: { $0.id == opportunityID })
    {
      return linkedOpportunity
    }

    if let color = task.color,
      let colorMatch = opportunities.first(where: { $0.color == color })
    {
      return colorMatch
    }

    return opportunities.first
  }
}

@MainActor
final class BoardStore: ObservableObject {
  @Published private(set) var projects: [BoardProject] = []

  private static let starterProjectsInstalledKey = "starterProjectsInstalled.v1"
  private let fileURL: URL

  init() {
    let directory =
      FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    fileURL = directory.appendingPathComponent("boards.json")
    if FileManager.default.fileExists(atPath: fileURL.path) {
      if let data = try? Data(contentsOf: fileURL),
        let saved = try? JSONDecoder().decode([BoardProject].self, from: data)
      {
        projects = saved
        repairOpportunityLinks()
        installStarterProjectsIfNeeded()
      }
    } else {
      projects = BoardProject.starterProjects
      save()
      UserDefaults.standard.set(true, forKey: Self.starterProjectsInstalledKey)
    }
  }

  func project(_ id: UUID) -> BoardProject? { projects.first { $0.id == id } }

  @discardableResult
  func addProject(_ name: String, color: ProjectColor) -> UUID {
    let project = BoardProject(
      name: name.trimmingCharacters(in: .whitespacesAndNewlines), color: color)
    projects.append(project)
    save()
    return project.id
  }

  func deleteProject(_ id: UUID) {
    projects.removeAll { $0.id == id }
    save()
  }

  @discardableResult
  func importProject(_ importedProject: BoardProject) -> UUID {
    var project = importedProject
    project.id = UUID()

    let columnIDMap = Dictionary(
      uniqueKeysWithValues: project.columns.map { ($0.id, UUID()) })
    let taskIDMap = Dictionary(
      uniqueKeysWithValues: project.tasks.map { ($0.id, UUID()) })

    for columnIndex in project.columns.indices {
      project.columns[columnIndex].id = columnIDMap[project.columns[columnIndex].id] ?? UUID()
    }
    for taskIndex in project.tasks.indices {
      let originalTask = project.tasks[taskIndex]
      project.tasks[taskIndex].id = taskIDMap[originalTask.id] ?? UUID()
      project.tasks[taskIndex].columnID =
        columnIDMap[originalTask.columnID] ?? originalTask.columnID
      project.tasks[taskIndex].opportunityID = originalTask.opportunityID.flatMap { taskIDMap[$0] }
    }

    if projects.contains(where: { $0.name == project.name }) {
      project.name += " (Imported)"
    }
    projects.append(project)
    save()
    return project.id
  }

  func updateProject(_ id: UUID, name: String, color: ProjectColor) {
    guard let index = projects.firstIndex(where: { $0.id == id }) else { return }
    projects[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    projects[index].color = color
    save()
  }

  func addColumn(to projectID: UUID, name: String, color: ProjectColor?) {
    guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
    projects[index].columns.append(
      BoardColumn(
        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
        color: color))
    save()
  }

  func updateColumn(_ columnID: UUID, in projectID: UUID, name: String, color: ProjectColor?) {
    guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
      let columnIndex = projects[projectIndex].columns.firstIndex(where: { $0.id == columnID })
    else { return }
    projects[projectIndex].columns[columnIndex].name = name.trimmingCharacters(
      in: .whitespacesAndNewlines)
    projects[projectIndex].columns[columnIndex].color = color
    save()
  }

  func toggleTaskStacking(in columnID: UUID, projectID: UUID) {
    guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
      let columnIndex = projects[projectIndex].columns.firstIndex(where: { $0.id == columnID })
    else { return }
    projects[projectIndex].columns[columnIndex].stacksTasks = !projects[projectIndex].columns[
      columnIndex
    ].isStacked
    save()
  }

  func toggleColumnWidth(_ columnID: UUID, in projectID: UUID) {
    guard
      let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
      let columnIndex = projects[projectIndex].columns.firstIndex(where: { $0.id == columnID })
    else { return }
    projects[projectIndex].columns[columnIndex].usesCompactWidth =
      !projects[projectIndex].columns[columnIndex].isCompact
    save()
  }

  func deleteColumn(_ columnID: UUID, in projectID: UUID) {
    guard let index = projects.firstIndex(where: { $0.id == projectID }),
      projects[index].columns.count > 1,
      projects[index].columns.first?.id != columnID
    else { return }
    guard let destination = projects[index].columns.first(where: { $0.id != columnID })?.id else {
      return
    }
    for taskIndex in projects[index].tasks.indices
    where projects[index].tasks[taskIndex].columnID == columnID {
      projects[index].tasks[taskIndex].columnID = destination
    }
    projects[index].columns.removeAll { $0.id == columnID }
    save()
  }

  func moveColumn(_ columnID: UUID, in projectID: UUID, to targetID: UUID) {
    guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
      let sourceIndex = projects[projectIndex].columns.firstIndex(where: { $0.id == columnID }),
      let targetIndex = projects[projectIndex].columns.firstIndex(where: { $0.id == targetID }),
      sourceIndex > 0
    else { return }
    let column = projects[projectIndex].columns.remove(at: sourceIndex)
    projects[projectIndex].columns.insert(column, at: max(1, targetIndex))
    save()
  }

  func addTask(
    to projectID: UUID, columnID: UUID, title: String, details: String,
    color: ProjectColor?, opportunityID: UUID?, leadKind: LeadKind, isUrgent: Bool
  ) {
    guard let index = projects.firstIndex(where: { $0.id == projectID }),
      projects[index].columns.contains(where: { $0.id == columnID })
    else { return }
    projects[index].tasks.append(
      BoardTask(
        title: title.trimmingCharacters(in: .whitespacesAndNewlines),
        details: details.trimmingCharacters(in: .whitespacesAndNewlines),
        color: color,
        opportunityID: opportunityID,
        leadKind: leadKind,
        isUrgent: isUrgent,
        columnID: columnID))
    save()
  }

  func updateTask(
    _ taskID: UUID, in projectID: UUID, title: String, details: String,
    columnID: UUID, color: ProjectColor?, opportunityID: UUID?, leadKind: LeadKind,
    isUrgent: Bool
  ) {
    guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
      let taskIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == taskID }),
      projects[projectIndex].columns.contains(where: { $0.id == columnID })
    else { return }
    projects[projectIndex].tasks[taskIndex].title = title.trimmingCharacters(
      in: .whitespacesAndNewlines)
    projects[projectIndex].tasks[taskIndex].details = details.trimmingCharacters(
      in: .whitespacesAndNewlines)
    projects[projectIndex].tasks[taskIndex].columnID = columnID
    projects[projectIndex].tasks[taskIndex].color = color
    projects[projectIndex].tasks[taskIndex].opportunityID = opportunityID
    projects[projectIndex].tasks[taskIndex].leadKind = leadKind
    projects[projectIndex].tasks[taskIndex].isUrgent = isUrgent
    save()
  }

  func moveTask(_ taskID: UUID, in projectID: UUID, to columnID: UUID) {
    guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
      let taskIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == taskID }),
      projects[projectIndex].columns.contains(where: { $0.id == columnID })
    else { return }
    projects[projectIndex].tasks[taskIndex].columnID = columnID
    save()
  }

  func moveTaskToEnd(_ taskID: UUID, in projectID: UUID, of columnID: UUID) {
    guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
      let taskIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == taskID }),
      projects[projectIndex].columns.contains(where: { $0.id == columnID })
    else { return }
    var task = projects[projectIndex].tasks.remove(at: taskIndex)
    task.columnID = columnID
    projects[projectIndex].tasks.append(task)
    save()
  }

  func moveTask(_ taskID: UUID, in projectID: UUID, before targetID: UUID) {
    guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
      let sourceIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == taskID }),
      let target = projects[projectIndex].tasks.first(where: { $0.id == targetID }),
      taskID != targetID
    else { return }
    var task = projects[projectIndex].tasks.remove(at: sourceIndex)
    task.columnID = target.columnID
    guard
      let updatedTargetIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == targetID })
    else {
      projects[projectIndex].tasks.append(task)
      save()
      return
    }
    projects[projectIndex].tasks.insert(task, at: updatedTargetIndex)
    save()
  }

  func moveTaskWithinColumn(_ taskID: UUID, in projectID: UUID, offset: Int) {
    guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
      let task = projects[projectIndex].tasks.first(where: { $0.id == taskID })
    else { return }
    let orderedIDs = projects[projectIndex].tasks
      .filter { $0.columnID == task.columnID }
      .map(\.id)
    guard let position = orderedIDs.firstIndex(of: taskID) else { return }
    let destination = position + offset
    guard orderedIDs.indices.contains(destination),
      let sourceIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == taskID }),
      let destinationIndex = projects[projectIndex].tasks.firstIndex(where: {
        $0.id == orderedIDs[destination]
      })
    else { return }
    projects[projectIndex].tasks.swapAt(sourceIndex, destinationIndex)
    save()
  }

  func deleteTask(_ taskID: UUID, in projectID: UUID) {
    guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
    projects[index].tasks.removeAll { $0.id == taskID }
    for taskIndex in projects[index].tasks.indices
    where projects[index].tasks[taskIndex].opportunityID == taskID {
      projects[index].tasks[taskIndex].opportunityID = nil
    }
    save()
  }

  private func save() {
    guard let data = try? JSONEncoder().encode(projects) else { return }
    try? data.write(to: fileURL, options: .atomic)
  }

  private func installStarterProjectsIfNeeded() {
    guard !UserDefaults.standard.bool(forKey: Self.starterProjectsInstalledKey) else { return }

    let existingNames = Set(projects.map { $0.name.localizedLowercase })
    let missingProjects = BoardProject.starterProjects.filter {
      !existingNames.contains($0.name.localizedLowercase)
    }
    if !missingProjects.isEmpty {
      projects.append(contentsOf: missingProjects)
      save()
    }
    UserDefaults.standard.set(true, forKey: Self.starterProjectsInstalledKey)
  }

  private func repairOpportunityLinks() {
    var changed = false
    for projectIndex in projects.indices {
      let project = projects[projectIndex]
      guard let leadColumnID = project.leadColumnID else { continue }
      let opportunities = project.opportunities
      guard !opportunities.isEmpty else { continue }
      let opportunityIDs = Set(opportunities.map(\.id))

      for taskIndex in projects[projectIndex].tasks.indices {
        let task = projects[projectIndex].tasks[taskIndex]
        guard task.columnID != leadColumnID else { continue }
        if let opportunityID = task.opportunityID,
          opportunityIDs.contains(opportunityID)
        {
          continue
        }
        let match =
          task.color.flatMap { color in
            opportunities.first { $0.color == color }
          } ?? opportunities[0]
        projects[projectIndex].tasks[taskIndex].opportunityID = match.id
        projects[projectIndex].tasks[taskIndex].color = match.color
        changed = true
      }
    }
    if changed { save() }
  }
}
