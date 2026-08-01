using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using LedgerLens.Models;

namespace LedgerLens.Core;

/// <summary>
/// Builds CSV and XLSX exports. Columns, ordering, header casing, and CSV quoting match the
/// web app (<c>components/conversion-result-view.js</c>) and the macOS app, so exports are
/// interchangeable. XLSX is written with .NET's built-in <see cref="ZipArchive"/> — no
/// third-party spreadsheet dependency.
/// </summary>
public static class SpreadsheetExporter
{
    private sealed class Column
    {
        public string Key = "";
        public string Header = "";
        public double Width;
        public Func<TransactionRow, string> Value = _ => "";
    }

    private static List<Column> Columns(bool includeSourceFile)
    {
        var cols = new List<Column>();
        if (includeSourceFile)
        {
            cols.Add(new Column { Key = "sourceFile", Header = "SourceFile", Width = 18, Value = r => r.SourceFile ?? "" });
        }
        cols.Add(new Column { Key = "date", Header = "Date", Width = 18, Value = r => r.Date });
        cols.Add(new Column { Key = "description", Header = "Description", Width = 48, Value = r => r.Description });
        cols.Add(new Column { Key = "debit", Header = "Debit", Width = 18, Value = r => r.Debit });
        cols.Add(new Column { Key = "credit", Header = "Credit", Width = 18, Value = r => r.Credit });
        cols.Add(new Column { Key = "balance", Header = "Balance", Width = 18, Value = r => r.Balance });
        return cols;
    }

    // MARK: CSV

    public static byte[] BuildCsv(IReadOnlyList<TransactionRow> rows, bool includeSourceFile)
    {
        var cols = Columns(includeSourceFile);
        var lines = new List<string> { string.Join(",", cols.Select(c => c.Key)) };

        foreach (var row in rows)
        {
            var cells = cols.Select(c =>
            {
                var raw = c.Value(row) ?? "";
                return "\"" + raw.Replace("\"", "\"\"") + "\"";
            });
            lines.Add(string.Join(",", cells));
        }

        return new UTF8Encoding(false).GetBytes(string.Join("\n", lines));
    }

    // MARK: XLSX

    public static byte[] BuildXlsx(IReadOnlyList<TransactionRow> rows, bool includeSourceFile)
    {
        var cols = Columns(includeSourceFile);

        using var memory = new MemoryStream();
        using (var archive = new ZipArchive(memory, ZipArchiveMode.Create, leaveOpen: true))
        {
            WriteEntry(archive, "[Content_Types].xml", ContentTypesXml);
            WriteEntry(archive, "_rels/.rels", RootRelsXml);
            WriteEntry(archive, "xl/workbook.xml", WorkbookXml);
            WriteEntry(archive, "xl/_rels/workbook.xml.rels", WorkbookRelsXml);
            WriteEntry(archive, "xl/styles.xml", StylesXml);
            WriteEntry(archive, "xl/worksheets/sheet1.xml", SheetXml(rows, cols));
        }

        return memory.ToArray();
    }

    private static void WriteEntry(ZipArchive archive, string name, string content)
    {
        var entry = archive.CreateEntry(name, CompressionLevel.Optimal);
        using var stream = entry.Open();
        var bytes = new UTF8Encoding(false).GetBytes(content);
        stream.Write(bytes, 0, bytes.Length);
    }

    private const string ContentTypesXml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
        "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">" +
        "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>" +
        "<Default Extension=\"xml\" ContentType=\"application/xml\"/>" +
        "<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>" +
        "<Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>" +
        "<Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>" +
        "</Types>";

    private const string RootRelsXml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
        "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">" +
        "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>" +
        "</Relationships>";

    private const string WorkbookXml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
        "<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">" +
        "<sheets><sheet name=\"Transactions\" sheetId=\"1\" r:id=\"rId1\"/></sheets>" +
        "</workbook>";

    private const string WorkbookRelsXml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
        "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">" +
        "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/>" +
        "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>" +
        "</Relationships>";

    private const string StylesXml =
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>" +
        "<styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">" +
        "<fonts count=\"2\"><font><sz val=\"11\"/><name val=\"Calibri\"/></font><font><b/><sz val=\"11\"/><name val=\"Calibri\"/></font></fonts>" +
        "<fills count=\"1\"><fill><patternFill patternType=\"none\"/></fill></fills>" +
        "<borders count=\"1\"><border><left/><right/><top/><bottom/><diagonal/></border></borders>" +
        "<cellStyleXfs count=\"1\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\"/></cellStyleXfs>" +
        "<cellXfs count=\"2\"><xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/><xf numFmtId=\"0\" fontId=\"1\" fillId=\"0\" borderId=\"0\" xfId=\"0\" applyFont=\"1\"/></cellXfs>" +
        "<cellStyles count=\"1\"><cellStyle name=\"Normal\" xfId=\"0\" builtinId=\"0\"/></cellStyles>" +
        "</styleSheet>";

    private static string SheetXml(IReadOnlyList<TransactionRow> rows, List<Column> cols)
    {
        var sb = new StringBuilder();
        sb.Append("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>");
        sb.Append("<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">");

        sb.Append("<cols>");
        for (var i = 0; i < cols.Count; i++)
        {
            var col = i + 1;
            sb.Append($"<col min=\"{col}\" max=\"{col}\" width=\"{cols[i].Width}\" customWidth=\"1\"/>");
        }
        sb.Append("</cols>");

        sb.Append("<sheetData>");

        sb.Append("<row r=\"1\">");
        for (var i = 0; i < cols.Count; i++)
        {
            sb.Append(Cell(CellRef(i + 1, 1), cols[i].Header, 1));
        }
        sb.Append("</row>");

        for (var r = 0; r < rows.Count; r++)
        {
            var rowNumber = r + 2;
            sb.Append($"<row r=\"{rowNumber}\">");
            for (var i = 0; i < cols.Count; i++)
            {
                sb.Append(Cell(CellRef(i + 1, rowNumber), cols[i].Value(rows[r]) ?? "", 0));
            }
            sb.Append("</row>");
        }

        sb.Append("</sheetData></worksheet>");
        return sb.ToString();
    }

    private static string Cell(string reference, string text, int styleIndex)
    {
        var styleAttr = styleIndex == 0 ? "" : $" s=\"{styleIndex}\"";
        return $"<c r=\"{reference}\"{styleAttr} t=\"inlineStr\"><is><t xml:space=\"preserve\">{EscapeXml(text)}</t></is></c>";
    }

    private static string CellRef(int column, int row)
    {
        var dividend = column;
        var name = "";
        while (dividend > 0)
        {
            var modulo = (dividend - 1) % 26;
            name = (char)('A' + modulo) + name;
            dividend = (dividend - modulo) / 26;
        }
        return name + row;
    }

    private static string EscapeXml(string value) => value
        .Replace("&", "&amp;")
        .Replace("<", "&lt;")
        .Replace(">", "&gt;")
        .Replace("\"", "&quot;")
        .Replace("'", "&apos;");
}
