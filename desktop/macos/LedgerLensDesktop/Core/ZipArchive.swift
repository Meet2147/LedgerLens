import Foundation

/// A tiny, dependency-free ZIP writer using the STORE method (no compression).
///
/// Bank statements produce small spreadsheets, so skipping compression keeps the code
/// trivial and the output is a fully valid ZIP — which is all an `.xlsx` container needs.
/// This lets the app write real Excel files with no third-party packages.
struct ZipArchive {
    private struct Entry {
        let name: String
        let data: Data
        let crc32: UInt32
        let offset: UInt32
    }

    private var entries: [Entry] = []
    private var buffer = Data()

    mutating func addFile(name: String, contents: Data) {
        let crc = ZipArchive.crc32(of: contents)
        let offset = UInt32(buffer.count)
        let nameBytes = Array(name.utf8)

        // Local file header
        buffer.appendLE(UInt32(0x04034b50))
        buffer.appendLE(UInt16(20))          // version needed
        buffer.appendLE(UInt16(0))           // flags
        buffer.appendLE(UInt16(0))           // method: store
        buffer.appendLE(UInt16(0))           // mod time
        buffer.appendLE(UInt16(0x21))        // mod date (1980-01-01)
        buffer.appendLE(crc)
        buffer.appendLE(UInt32(contents.count)) // compressed size
        buffer.appendLE(UInt32(contents.count)) // uncompressed size
        buffer.appendLE(UInt16(nameBytes.count))
        buffer.appendLE(UInt16(0))           // extra length
        buffer.append(contentsOf: nameBytes)
        buffer.append(contents)

        entries.append(Entry(name: name, data: contents, crc32: crc, offset: offset))
    }

    mutating func finalize() -> Data {
        let centralStart = UInt32(buffer.count)

        for entry in entries {
            let nameBytes = Array(entry.name.utf8)
            buffer.appendLE(UInt32(0x02014b50))
            buffer.appendLE(UInt16(20))      // version made by
            buffer.appendLE(UInt16(20))      // version needed
            buffer.appendLE(UInt16(0))       // flags
            buffer.appendLE(UInt16(0))       // method: store
            buffer.appendLE(UInt16(0))       // mod time
            buffer.appendLE(UInt16(0x21))    // mod date
            buffer.appendLE(entry.crc32)
            buffer.appendLE(UInt32(entry.data.count))
            buffer.appendLE(UInt32(entry.data.count))
            buffer.appendLE(UInt16(nameBytes.count))
            buffer.appendLE(UInt16(0))       // extra length
            buffer.appendLE(UInt16(0))       // comment length
            buffer.appendLE(UInt16(0))       // disk number start
            buffer.appendLE(UInt16(0))       // internal attrs
            buffer.appendLE(UInt32(0))       // external attrs
            buffer.appendLE(entry.offset)
            buffer.append(contentsOf: nameBytes)
        }

        let centralSize = UInt32(buffer.count) - centralStart

        // End of central directory record
        buffer.appendLE(UInt32(0x06054b50))
        buffer.appendLE(UInt16(0))           // disk number
        buffer.appendLE(UInt16(0))           // disk with central dir
        buffer.appendLE(UInt16(entries.count))
        buffer.appendLE(UInt16(entries.count))
        buffer.appendLE(centralSize)
        buffer.appendLE(centralStart)
        buffer.appendLE(UInt16(0))           // comment length

        return buffer
    }

    // MARK: - CRC32

    private static let crcTable: [UInt32] = {
        (0..<256).map { i -> UInt32 in
            var c = UInt32(i)
            for _ in 0..<8 {
                c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1)
            }
            return c
        }
    }()

    static func crc32(of data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = crcTable[index] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }
}

private extension Data {
    mutating func appendLE(_ value: UInt16) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
    }

    mutating func appendLE(_ value: UInt32) {
        append(UInt8(value & 0xFF))
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8((value >> 16) & 0xFF))
        append(UInt8((value >> 24) & 0xFF))
    }
}
