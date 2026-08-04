import Foundation

/// Builds CSV and XLSX exports from parsed rows. Columns, ordering, header casing, and CSV
/// quoting all match `components/conversion-result-view.js` so desktop exports are
/// interchangeable with the web product's.
enum SpreadsheetExporter {

    /// One exportable column: `key` matches the `TransactionRow` field and the CSV header;
    /// `header` is the title-cased XLSX header the web app uses.
    struct Column {
        let key: String
        let header: String
        let width: Double
        let value: (TransactionRow) -> String
    }

    static func columns(includeSourceFile: Bool, includeFlag: Bool = false) -> [Column] {
        var cols: [Column] = []
        if includeSourceFile {
            cols.append(Column(key: "sourceFile", header: "SourceFile", width: 18) { $0.sourceFile ?? "" })
        }
        cols.append(Column(key: "date", header: "Date", width: 18) { $0.date })
        cols.append(Column(key: "description", header: "Description", width: 48) { $0.description })
        cols.append(Column(key: "debit", header: "Debit", width: 18) { $0.debit })
        cols.append(Column(key: "credit", header: "Credit", width: 18) { $0.credit })
        cols.append(Column(key: "balance", header: "Balance", width: 18) { $0.balance })
        if includeFlag {
            // Marks rows whose balance didn't reconcile so they're filterable in Excel.
            cols.append(Column(key: "flag", header: "Flag", width: 12) { $0.reconciled ? "" : "check" })
        }
        return cols
    }

    // MARK: - CSV

    static func csv(rows: [TransactionRow], includeSourceFile: Bool, includeFlag: Bool = false) -> Data {
        let cols = columns(includeSourceFile: includeSourceFile, includeFlag: includeFlag)
        var lines: [String] = []
        lines.append(cols.map { $0.key }.joined(separator: ","))

        for row in rows {
            let cells = cols.map { column -> String in
                let raw = column.value(row)
                let escaped = raw.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escaped)\""
            }
            lines.append(cells.joined(separator: ","))
        }

        return Data(lines.joined(separator: "\n").utf8)
    }

    // MARK: - XLSX

    static func xlsx(rows: [TransactionRow], includeSourceFile: Bool, includeFlag: Bool = false) -> Data {
        let cols = columns(includeSourceFile: includeSourceFile, includeFlag: includeFlag)
        var archive = ZipArchive()

        archive.addFile(name: "[Content_Types].xml", contents: Data(contentTypesXML.utf8))
        archive.addFile(name: "_rels/.rels", contents: Data(rootRelsXML.utf8))
        archive.addFile(name: "xl/workbook.xml", contents: Data(workbookXML.utf8))
        archive.addFile(name: "xl/_rels/workbook.xml.rels", contents: Data(workbookRelsXML.utf8))
        archive.addFile(name: "xl/styles.xml", contents: Data(stylesXML.utf8))
        archive.addFile(name: "xl/worksheets/sheet1.xml", contents: Data(sheetXML(rows: rows, columns: cols).utf8))

        return archive.finalize()
    }

    // MARK: - XLSX parts

    private static let contentTypesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
    <Default Extension="xml" ContentType="application/xml"/>
    <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
    <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
    <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
    </Types>
    """

    private static let rootRelsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
    </Relationships>
    """

    private static let workbookXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
    <sheets><sheet name="Transactions" sheetId="1" r:id="rId1"/></sheets>
    </workbook>
    """

    private static let workbookRelsXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
    <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
    </Relationships>
    """

    // Two cell formats: index 0 = normal, index 1 = bold (used for the header row).
    private static let stylesXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
    <fonts count="2"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts>
    <fills count="1"><fill><patternFill patternType="none"/></fill></fills>
    <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
    <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
    <cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>
    <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
    </styleSheet>
    """

    private static func sheetXML(rows: [TransactionRow], columns cols: [Column]) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"
        xml += "<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">"

        // Column widths (mirrors the web: 48 for description, 18 otherwise).
        xml += "<cols>"
        for (index, column) in cols.enumerated() {
            let col = index + 1
            xml += "<col min=\"\(col)\" max=\"\(col)\" width=\"\(column.width)\" customWidth=\"1\"/>"
        }
        xml += "</cols>"

        xml += "<sheetData>"

        // Header row (bold, style index 1).
        xml += "<row r=\"1\">"
        for (index, column) in cols.enumerated() {
            xml += cell(reference: cellRef(column: index + 1, row: 1), text: column.header, styleIndex: 1)
        }
        xml += "</row>"

        // Data rows.
        for (rowIndex, row) in rows.enumerated() {
            let rowNumber = rowIndex + 2
            xml += "<row r=\"\(rowNumber)\">"
            for (index, column) in cols.enumerated() {
                xml += cell(reference: cellRef(column: index + 1, row: rowNumber), text: column.value(row), styleIndex: 0)
            }
            xml += "</row>"
        }

        xml += "</sheetData></worksheet>"
        return xml
    }

    private static func cell(reference: String, text: String, styleIndex: Int) -> String {
        let styleAttr = styleIndex == 0 ? "" : " s=\"\(styleIndex)\""
        return "<c r=\"\(reference)\"\(styleAttr) t=\"inlineStr\"><is><t xml:space=\"preserve\">\(escapeXML(text))</t></is></c>"
    }

    private static func cellRef(column: Int, row: Int) -> String {
        var dividend = column
        var name = ""
        while dividend > 0 {
            let modulo = (dividend - 1) % 26
            name = String(UnicodeScalar(65 + modulo)!) + name
            dividend = (dividend - modulo) / 26
        }
        return "\(name)\(row)"
    }

    private static func escapeXML(_ value: String) -> String {
        var result = value.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }
}
