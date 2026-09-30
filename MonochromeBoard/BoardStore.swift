import Foundation
import Combine

struct BoardTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var details: String = ""
    var color: ProjectColor? = nil
    var opportunityID: UUID? = nil
    var columnID: UUID
    var createdAt: Date = Date()

    private enum CodingKeys: String, CodingKey { case id, title, details, color, opportunityID, columnID, createdAt }

    init(id: UUID = UUID(), title: String, details: String = "", color: ProjectColor? = nil,
         opportunityID: UUID? = nil,
         columnID: UUID, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.details = details
        self.color = color
        self.opportunityID = opportunityID
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
        columnID = try values.decode(UUID.self, forKey: .columnID)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
    }
}

struct BoardColumn: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
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
        BoardColumn(name: "Done")
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
        if columns.first?.name == "To Do" { columns[0].name = "Opportunity Leads" }
        tasks = try values.decode([BoardTask].self, forKey: .tasks)
    }
}

@MainActor
final class BoardStore: ObservableObject {
    @Published private(set) var projects: [BoardProject] = []

    private let fileURL: URL

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("boards.json")
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([BoardProject].self, from: data) {
            projects = saved
        }
    }

    func project(_ id: UUID) -> BoardProject? { projects.first { $0.id == id } }

    @discardableResult
    func addProject(_ name: String, color: ProjectColor) -> UUID {
        let project = BoardProject(name: name.trimmingCharacters(in: .whitespacesAndNewlines), color: color)
        projects.append(project)
        save()
        return project.id
    }

    func deleteProject(_ id: UUID) {
        projects.removeAll { $0.id == id }
        save()
    }

    func updateProject(_ id: UUID, name: String, color: ProjectColor) {
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[index].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        projects[index].color = color
        save()
    }

    func addColumn(to projectID: UUID, name: String) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[index].columns.append(BoardColumn(name: name.trimmingCharacters(in: .whitespacesAndNewlines)))
        save()
    }

    func renameColumn(_ columnID: UUID, in projectID: UUID, to name: String) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
              projects[projectIndex].columns.first?.id != columnID,
              let columnIndex = projects[projectIndex].columns.firstIndex(where: { $0.id == columnID }) else { return }
        projects[projectIndex].columns[columnIndex].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func deleteColumn(_ columnID: UUID, in projectID: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }),
              projects[index].columns.count > 1,
              projects[index].columns.first?.id != columnID else { return }
        let destination = projects[index].columns.first { $0.id != columnID }!.id
        for taskIndex in projects[index].tasks.indices where projects[index].tasks[taskIndex].columnID == columnID {
            projects[index].tasks[taskIndex].columnID = destination
        }
        projects[index].columns.removeAll { $0.id == columnID }
        save()
    }

    func moveColumn(_ columnID: UUID, in projectID: UUID, to targetID: UUID) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
              let sourceIndex = projects[projectIndex].columns.firstIndex(where: { $0.id == columnID }),
              let targetIndex = projects[projectIndex].columns.firstIndex(where: { $0.id == targetID }),
              sourceIndex > 0 else { return }
        let column = projects[projectIndex].columns.remove(at: sourceIndex)
        projects[projectIndex].columns.insert(column, at: max(1, targetIndex))
        save()
    }

    func addTask(to projectID: UUID, columnID: UUID, title: String, details: String,
                 color: ProjectColor?, opportunityID: UUID?) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }),
              projects[index].columns.contains(where: { $0.id == columnID }) else { return }
        projects[index].tasks.append(BoardTask(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                               details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                                               color: color,
                                               opportunityID: opportunityID,
                                               columnID: columnID))
        save()
    }

    func updateTask(_ taskID: UUID, in projectID: UUID, title: String, details: String,
                    columnID: UUID, color: ProjectColor?, opportunityID: UUID?) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
              let taskIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == taskID }),
              projects[projectIndex].columns.contains(where: { $0.id == columnID }) else { return }
        projects[projectIndex].tasks[taskIndex].title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        projects[projectIndex].tasks[taskIndex].details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        projects[projectIndex].tasks[taskIndex].columnID = columnID
        projects[projectIndex].tasks[taskIndex].color = color
        projects[projectIndex].tasks[taskIndex].opportunityID = opportunityID
        save()
    }

    func moveTask(_ taskID: UUID, in projectID: UUID, to columnID: UUID) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
              let taskIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == taskID }),
              projects[projectIndex].columns.contains(where: { $0.id == columnID }) else { return }
        projects[projectIndex].tasks[taskIndex].columnID = columnID
        save()
    }

    func deleteTask(_ taskID: UUID, in projectID: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[index].tasks.removeAll { $0.id == taskID }
        for taskIndex in projects[index].tasks.indices where projects[index].tasks[taskIndex].opportunityID == taskID {
            projects[index].tasks[taskIndex].opportunityID = nil
        }
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
