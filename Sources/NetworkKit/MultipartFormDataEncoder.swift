import Foundation

final public class MultipartFormDataEncoder {

    let boundary = UUID().uuidString

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoding = MultipartFormDataEncoding()
        try value.encode(to: encoding)

        var data = Data()

        for part in encoding.parts.parts {
            var partString = "\r\n--\(boundary)\r\n"

            for property in part.properties {
                switch property {
                case .disposition(let dispositions):

                    partString.append("Content-Disposition: form-data;")

                    for disposition in dispositions {
                        switch disposition {
                        case .name(let name):
                            partString.append(" name=\"\(name)\"")
                        case .fileName(let fileName):
                            partString.append(" filename=\"\(fileName)\"")
                        }
                    }

                    partString.append("\r\n")

                case .type(let type):
                    partString.append("Content-Type: \(type)\r\n")
                }
            }

            partString.append("\r\n")
            data.append(partString.data(using: .utf8)!)
            data.append(part.data)
        }

        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        return data
    }
}

fileprivate struct MultipartFormDataEncoding: Encoder {

    struct MultipartFormDataPart {
        let properties: [Property]
        let data: Data

        enum Property {
            case disposition([ContentDisposition])
            case type(String)

            enum ContentDisposition {
                case name(String)
                case fileName(String)
            }
        }
    }

    fileprivate final class PartsContainer {
        var parts: [MultipartFormDataPart] = []

        func encode(key codingKey: [CodingKey], string: String) {
            encode(key: codingKey, value: string.data(using: .utf8)!)
        }

        func encode(key codingKey: [CodingKey], value: Data) {
            let key = codingKey.map { $0.stringValue }.joined(separator: ".")

            let part = MultipartFormDataPart(
                properties: [.disposition([.name(key)])],
                data: value)

            parts.append(part)
        }
    }

    let parts: PartsContainer

    init(to parts: PartsContainer = PartsContainer()) {
        self.parts = parts
    }

    var codingPath: [CodingKey] = []

    let userInfo: [CodingUserInfoKey: Any] = [:]

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        var container = MultipartFormDataKeyedEncoding<Key>(to: parts)
        container.codingPath = codingPath
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        var container = MultipartFormDataUnkeyedEncoding(to: parts)
        container.codingPath = codingPath
        return container
   }

    func singleValueContainer() -> SingleValueEncodingContainer {
        var container = MultipartFormDataSingleValueEncoding(to: parts)
        container.codingPath = codingPath
        return container
    }
}

fileprivate struct MultipartFormDataKeyedEncoding<Key: CodingKey>: KeyedEncodingContainerProtocol {

    private let parts: MultipartFormDataEncoding.PartsContainer

    init(to parts: MultipartFormDataEncoding.PartsContainer) {
        self.parts = parts
    }

    var codingPath: [CodingKey] = []

    mutating func encodeNil(forKey key: Key) throws {
        parts.encode(key: codingPath + [key], value: Data())
    }

    mutating func encode(_ value: Bool, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: String, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value)
    }

    mutating func encode(_ value: Double, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: Float, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: Int, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: Int8, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: Int16, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: Int32, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: Int64, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: UInt, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: UInt8, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: UInt16, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: UInt32, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode(_ value: UInt64, forKey key: Key) throws {
        parts.encode(key: codingPath + [key], string: value.description)
    }

    mutating func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        if let data = value as? Data {
            parts.encode(key: codingPath + [key], value: data)
            return
        }

        var encoding = MultipartFormDataEncoding(to: parts)
        encoding.codingPath.append(key)
        try value.encode(to: encoding)
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type,
        forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        var container = MultipartFormDataKeyedEncoding<NestedKey>(to: parts)
        container.codingPath = codingPath + [key]
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        var container = MultipartFormDataUnkeyedEncoding(to: parts)
        container.codingPath = codingPath + [key]
        return container
    }

    mutating func superEncoder() -> Encoder {
        let superKey = Key(stringValue: "super")!
        return superEncoder(forKey: superKey)
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        var encoding = MultipartFormDataEncoding(to: parts)
        encoding.codingPath = codingPath + [key]
        return encoding
    }
}

fileprivate struct MultipartFormDataUnkeyedEncoding: UnkeyedEncodingContainer {

    private let parts: MultipartFormDataEncoding.PartsContainer

    init(to parts: MultipartFormDataEncoding.PartsContainer) {
        self.parts = parts
    }

    var codingPath: [CodingKey] = []

    private(set) var count: Int = 0

    private mutating func nextIndexedKey() -> CodingKey {
        let nextCodingKey = IndexedCodingKey(intValue: count)!
        count += 1
        return nextCodingKey
    }

    private struct IndexedCodingKey: CodingKey {
        let intValue: Int?
        let stringValue: String

        init?(intValue: Int) {
            self.intValue = intValue
            self.stringValue = intValue.description
        }

        init?(stringValue: String) {
            return nil
        }
    }

    mutating func encodeNil() throws {
        parts.encode(key: codingPath + [nextIndexedKey()], value: Data())
    }

    mutating func encode(_ value: Bool) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: String) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value)
    }

    mutating func encode(_ value: Double) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: Float) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: Int) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: Int8) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: Int16) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: Int32) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: Int64) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: UInt) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: UInt8) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: UInt16) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: UInt32) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode(_ value: UInt64) throws {
        parts.encode(key: codingPath + [nextIndexedKey()], string: value.description)
    }

    mutating func encode<T: Encodable>(_ value: T) throws {
        if let data = value as? Data {
            parts.encode(key: codingPath + [nextIndexedKey()], value: data)
            return
        }

        var encoding = MultipartFormDataEncoding(to: parts)
        encoding.codingPath = codingPath + [nextIndexedKey()]
        try value.encode(to: encoding)
    }

    mutating func nestedContainer<NestedKey: CodingKey>(
        keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        var container = MultipartFormDataKeyedEncoding<NestedKey>(to: parts)
        container.codingPath = codingPath + [nextIndexedKey()]
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        var container = MultipartFormDataUnkeyedEncoding(to: parts)
        container.codingPath = codingPath + [nextIndexedKey()]
        return container
    }

    mutating func superEncoder() -> Encoder {
        var stringsEncoding = MultipartFormDataEncoding(to: parts)
        stringsEncoding.codingPath.append(nextIndexedKey())
        return stringsEncoding
    }
}

fileprivate struct MultipartFormDataSingleValueEncoding: SingleValueEncodingContainer {

    private let parts: MultipartFormDataEncoding.PartsContainer

    init(to parts: MultipartFormDataEncoding.PartsContainer) {
        self.parts = parts
    }

    var codingPath: [CodingKey] = []

    mutating func encodeNil() throws {
        parts.encode(key: codingPath, value: Data())
    }

    mutating func encode(_ value: Bool) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: String) throws {
        parts.encode(key: codingPath, string: value)
    }

    mutating func encode(_ value: Double) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: Float) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: Int) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: Int8) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: Int16) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: Int32) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: Int64) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: UInt) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: UInt8) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: UInt16) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: UInt32) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode(_ value: UInt64) throws {
        parts.encode(key: codingPath, string: value.description)
    }

    mutating func encode<T: Encodable>(_ value: T) throws {
        if let data = value as? Data {
            parts.encode(key: codingPath, value: data)
            return
        }

        var encoding = MultipartFormDataEncoding(to: parts)
        encoding.codingPath = codingPath
        try value.encode(to: encoding)
    }
}
