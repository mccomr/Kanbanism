import Foundation
import Combine

struct BoardTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var details: String = ""
    var columnID: UUID
    var createdAt: Date = Date()
}

struct BoardColumn: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
}

enum ProjectColor: String, CaseIterable, Codable, Identifiable {
    case blush, peach, butter, mint, sky, lilac

    var id: String { rawValue }
    var name: String { rawValue.capitalized }
}

struct BoardProject: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var color: ProjectColor = .lilac
    var columns: [BoardColumn] = [
        BoardColumn(name: "To Do"),
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
              let columnIndex = projects[projectIndex].columns.firstIndex(where: { $0.id == columnID }) else { return }
        projects[projectIndex].columns[columnIndex].name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func deleteColumn(_ columnID: UUID, in projectID: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }),
              projects[index].columns.count > 1 else { return }
        let destination = projects[index].columns.first { $0.id != columnID }!.id
        for taskIndex in projects[index].tasks.indices where projects[index].tasks[taskIndex].columnID == columnID {
            projects[index].tasks[taskIndex].columnID = destination
        }
        projects[index].columns.removeAll { $0.id == columnID }
        save()
    }

    func addTask(to projectID: UUID, columnID: UUID, title: String, details: String) {
        guard let index = projects.firstIndex(where: { $0.id == projectID }),
              projects[index].columns.contains(where: { $0.id == columnID }) else { return }
        projects[index].tasks.append(BoardTask(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                               details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                                               columnID: columnID))
        save()
    }

    func updateTask(_ taskID: UUID, in projectID: UUID, title: String, details: String, columnID: UUID) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectID }),
              let taskIndex = projects[projectIndex].tasks.firstIndex(where: { $0.id == taskID }),
              projects[projectIndex].columns.contains(where: { $0.id == columnID }) else { return }
        projects[projectIndex].tasks[taskIndex].title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        projects[projectIndex].tasks[taskIndex].details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        projects[projectIndex].tasks[taskIndex].columnID = columnID
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
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
