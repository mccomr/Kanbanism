import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct KanbanettiCSVDocument: FileDocument {
  static let readableContentTypes: [UTType] = [.commaSeparatedText]

  private let data: Data

  init(project: BoardProject) {
    data = Data(Self.csv(for: project).utf8)
  }

  init(configuration: ReadConfiguration) throws {
    guard let contents = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }
    data = contents
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }

  private static func csv(for project: BoardProject) -> String {
    let headers = [
      "Project", "Column", "Item Type", "Title", "Details", "Opportunity", "Color",
      "Created At",
    ]
    var rows = [headers]
    let dateFormatter = ISO8601DateFormatter()

    for column in project.columns {
      for task in project.tasks where task.columnID == column.id {
        let isLead = column.id == project.leadColumnID
        let opportunity = isLead ? task : project.opportunity(for: task)
        rows.append([
          project.name,
          column.name,
          isLead ? task.leadKind.name : "Task",
          task.title,
          task.details,
          isLead ? task.title : opportunity?.title ?? "",
          (task.color ?? opportunity?.color ?? project.color).name,
          dateFormatter.string(from: task.createdAt),
        ])
      }
    }

    return rows.map { $0.map(csvField).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
  }

  private static func csvField(_ value: String) -> String {
    var safeValue = value
    if let first = safeValue.first, "=+-@".contains(first) {
      safeValue = "'" + safeValue
    }
    return "\"" + safeValue.replacingOccurrences(of: "\"", with: "\"\"") + "\""
  }
}

struct KanbanettiPDFDocument: FileDocument {
  static let readableContentTypes: [UTType] = [.pdf]

  private let data: Data

  init(project: BoardProject) {
    data = KanbanettiPDFReport.make(for: project)
  }

  init(configuration: ReadConfiguration) throws {
    guard let contents = configuration.file.regularFileContents else {
      throw CocoaError(.fileReadCorruptFile)
    }
    data = contents
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}

private enum KanbanettiPDFReport {
  private static let page = CGRect(x: 0, y: 0, width: 595, height: 842)
  private static let margin: CGFloat = 42
  private static let contentWidth = page.width - margin * 2
  private static let dark = UIColor(red: 0.055, green: 0.055, blue: 0.065, alpha: 1)
  private static let muted = UIColor(red: 0.38, green: 0.39, blue: 0.43, alpha: 1)
  private static let line = UIColor(red: 0.86, green: 0.87, blue: 0.89, alpha: 1)
  private static let card = UIColor(red: 0.965, green: 0.97, blue: 0.98, alpha: 1)

  static func make(for project: BoardProject) -> Data {
    let renderer = UIGraphicsPDFRenderer(bounds: page)
    return renderer.pdfData { rendererContext in
      var y: CGFloat = 0
      var pageNumber = 0

      func startPage() {
        rendererContext.beginPage()
        pageNumber += 1
        UIColor.white.setFill()
        UIRectFill(page)
        y = drawPageHeader(project: project, pageNumber: pageNumber)
      }

      func ensureSpace(_ height: CGFloat) {
        if y + height > page.height - 46 {
          drawPageFooter(pageNumber: pageNumber)
          startPage()
        }
      }

      startPage()
      y = drawSummary(project: project, at: y)

      for column in project.columns {
        let tasks = project.tasks.filter { $0.columnID == column.id }
        ensureSpace(58)
        y = drawColumnHeader(column: column, count: tasks.count, at: y)

        if tasks.isEmpty {
          ensureSpace(42)
          drawText(
            "No items", in: CGRect(x: margin + 14, y: y + 10, width: contentWidth - 28, height: 20),
            font: .italicSystemFont(ofSize: 11), color: muted)
          y += 42
        } else {
          for task in tasks {
            let height = taskHeight(task, project: project, column: column)
            ensureSpace(height + 8)
            drawTask(task, project: project, column: column, at: y, height: height)
            y += height + 8
          }
        }
        y += 14
      }

      drawPageFooter(pageNumber: pageNumber)
    }
  }

  private static func drawPageHeader(project: BoardProject, pageNumber: Int) -> CGFloat {
    let headerHeight: CGFloat = pageNumber == 1 ? 116 : 74
    dark.setFill()
    UIRectFill(CGRect(x: 0, y: 0, width: page.width, height: headerHeight))

    let accent = uiColor(project.color)
    accent.setFill()
    UIBezierPath(
      roundedRect: CGRect(x: margin, y: pageNumber == 1 ? 30 : 22, width: 10, height: 38),
      cornerRadius: 5
    ).fill()

    drawText(
      project.name,
      in: CGRect(x: margin + 24, y: pageNumber == 1 ? 24 : 17, width: contentWidth - 24, height: 34),
      font: .boldSystemFont(ofSize: pageNumber == 1 ? 25 : 19), color: .white)
    drawText(
      pageNumber == 1 ? "KANBANETTI PROJECT REPORT" : "KANBANETTI · CONTINUED",
      in: CGRect(x: margin + 24, y: pageNumber == 1 ? 61 : 43, width: contentWidth - 24, height: 18),
      font: .systemFont(ofSize: 9, weight: .semibold),
      color: UIColor.white.withAlphaComponent(0.62))

    return headerHeight + 24
  }

  private static func drawSummary(project: BoardProject, at y: CGFloat) -> CGFloat {
    let opportunityCount = project.opportunities.count
    let taskCount = max(0, project.tasks.count - opportunityCount)
    let values = [
      ("COLUMNS", "\(project.columns.count)"),
      ("LEADS", "\(opportunityCount)"),
      ("TASKS", "\(taskCount)"),
    ]
    let gap: CGFloat = 10
    let width = (contentWidth - gap * 2) / 3

    for (index, value) in values.enumerated() {
      let rect = CGRect(x: margin + CGFloat(index) * (width + gap), y: y, width: width, height: 58)
      card.setFill()
      UIBezierPath(roundedRect: rect, cornerRadius: 10).fill()
      drawText(
        value.1, in: CGRect(x: rect.minX + 12, y: rect.minY + 9, width: width - 24, height: 25),
        font: .boldSystemFont(ofSize: 20), color: dark)
      drawText(
        value.0, in: CGRect(x: rect.minX + 12, y: rect.minY + 35, width: width - 24, height: 14),
        font: .systemFont(ofSize: 8, weight: .semibold), color: muted)
    }
    return y + 78
  }

  private static func drawColumnHeader(column: BoardColumn, count: Int, at y: CGFloat) -> CGFloat {
    let accent = column.color.map(uiColor) ?? UIColor(red: 0.35, green: 0.36, blue: 0.40, alpha: 1)
    accent.withAlphaComponent(0.16).setFill()
    UIBezierPath(
      roundedRect: CGRect(x: margin, y: y, width: contentWidth, height: 38), cornerRadius: 9
    ).fill()
    accent.setFill()
    UIBezierPath(
      roundedRect: CGRect(x: margin, y: y, width: 6, height: 38), cornerRadius: 3
    ).fill()
    drawText(
      column.name.uppercased(),
      in: CGRect(x: margin + 17, y: y + 11, width: contentWidth - 90, height: 16),
      font: .systemFont(ofSize: 10, weight: .bold), color: dark)
    drawText(
      "\(count)", in: CGRect(x: page.width - margin - 48, y: y + 9, width: 34, height: 18),
      font: .systemFont(ofSize: 11, weight: .bold), color: muted, alignment: .right)
    return y + 48
  }

  private static func taskHeight(_ task: BoardTask, project: BoardProject, column: BoardColumn)
    -> CGFloat
  {
    guard !task.details.isEmpty else { return 62 }
    let detailWidth = contentWidth - 40
    let detailHeight = (task.details as NSString).boundingRect(
      with: CGSize(width: detailWidth, height: 80),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: UIFont.systemFont(ofSize: 10)], context: nil
    ).height
    return min(116, max(78, 67 + ceil(detailHeight)))
  }

  private static func drawTask(
    _ task: BoardTask, project: BoardProject, column: BoardColumn, at y: CGFloat, height: CGFloat
  ) {
    let rect = CGRect(x: margin, y: y, width: contentWidth, height: height)
    card.setFill()
    UIBezierPath(roundedRect: rect, cornerRadius: 10).fill()
    line.setStroke()
    let outline = UIBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 10)
    outline.lineWidth = 1
    outline.stroke()

    let opportunity = project.opportunity(for: task)
    let color = uiColor(task.color ?? opportunity?.color ?? project.color)
    color.setFill()
    UIBezierPath(
      roundedRect: CGRect(x: rect.minX, y: rect.minY, width: 6, height: rect.height),
      cornerRadius: 3
    ).fill()

    drawText(
      task.title, in: CGRect(x: rect.minX + 17, y: rect.minY + 10, width: rect.width - 34, height: 19),
      font: .systemFont(ofSize: 12, weight: .semibold), color: dark)

    let isLead = column.id == project.leadColumnID
    var metadata = isLead ? task.leadKind.name : "Task"
    if !isLead, let opportunity { metadata += "  ·  \(opportunity.title)" }
    metadata += "  ·  \(shortDate(task.createdAt))"
    drawText(
      metadata,
      in: CGRect(x: rect.minX + 17, y: rect.minY + 31, width: rect.width - 34, height: 15),
      font: .systemFont(ofSize: 8.5, weight: .medium), color: muted)

    if !task.details.isEmpty {
      drawText(
        task.details,
        in: CGRect(
          x: rect.minX + 17, y: rect.minY + 49, width: rect.width - 34,
          height: rect.height - 57),
        font: .systemFont(ofSize: 10), color: dark)
    }
  }

  private static func drawPageFooter(pageNumber: Int) {
    line.setFill()
    UIRectFill(CGRect(x: margin, y: page.height - 35, width: contentWidth, height: 0.5))
    drawText(
      "Generated by Kanbanetti",
      in: CGRect(x: margin, y: page.height - 27, width: 220, height: 14),
      font: .systemFont(ofSize: 8), color: muted)
    drawText(
      "Page \(pageNumber)",
      in: CGRect(x: page.width - margin - 80, y: page.height - 27, width: 80, height: 14),
      font: .systemFont(ofSize: 8), color: muted, alignment: .right)
  }

  private static func drawText(
    _ text: String, in rect: CGRect, font: UIFont, color: UIColor,
    alignment: NSTextAlignment = .left
  ) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    paragraph.lineBreakMode = .byTruncatingTail
    (text as NSString).draw(
      with: rect,
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph],
      context: nil)
  }

  private static func shortDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
  }

  private static func uiColor(_ color: ProjectColor) -> UIColor {
    switch color {
    case .blush: UIColor(red: 1.00, green: 0.57, blue: 0.70, alpha: 1)
    case .coral: UIColor(red: 1.00, green: 0.48, blue: 0.42, alpha: 1)
    case .peach: UIColor(red: 1.00, green: 0.67, blue: 0.39, alpha: 1)
    case .tangerine: UIColor(red: 1.00, green: 0.53, blue: 0.18, alpha: 1)
    case .butter: UIColor(red: 1.00, green: 0.86, blue: 0.35, alpha: 1)
    case .lemon: UIColor(red: 0.95, green: 0.96, blue: 0.31, alpha: 1)
    case .lime: UIColor(red: 0.65, green: 0.94, blue: 0.30, alpha: 1)
    case .mint: UIColor(red: 0.37, green: 0.92, blue: 0.58, alpha: 1)
    case .teal: UIColor(red: 0.25, green: 0.88, blue: 0.76, alpha: 1)
    case .aqua: UIColor(red: 0.26, green: 0.88, blue: 0.94, alpha: 1)
    case .sky: UIColor(red: 0.39, green: 0.73, blue: 1.00, alpha: 1)
    case .cobalt: UIColor(red: 0.43, green: 0.55, blue: 1.00, alpha: 1)
    case .lilac: UIColor(red: 0.67, green: 0.52, blue: 1.00, alpha: 1)
    case .violet: UIColor(red: 0.79, green: 0.45, blue: 1.00, alpha: 1)
    case .magenta: UIColor(red: 0.98, green: 0.42, blue: 0.88, alpha: 1)
    }
  }
}
