import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// 住所→座標のジオコーディング結果を SQLite に永続化する
/// (Android版 GeocodingCacheDatabase 相当)。
/// 「該当なし」も記録し、一定期間は同じ住所を再問い合わせしない。
/// スレッドセーフではないため、単一の actor / MainActor から使うこと。
final class GeocodingCacheStore {

    enum LookupResult: Equatable {
        /// 未キャッシュ。ジオコーディングが必要
        case miss
        /// 座標が見つかっている
        case found(latitude: Double, longitude: Double)
        /// 「該当なし」が記録されており、まだ再試行期間に達していない
        case unresolved
    }

    enum StoreError: Error {
        case openFailed(String)
        case executeFailed(String)
    }

    private var db: OpaquePointer?
    private let failureRetryInterval: TimeInterval

    init(url: URL, failureRetryInterval: TimeInterval = 14 * 24 * 60 * 60) throws {
        self.failureRetryInterval = failureRetryInterval
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        guard sqlite3_open(url.path, &db) == SQLITE_OK else {
            let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            sqlite3_close(db)
            db = nil
            throw StoreError.openFailed(message)
        }
        try execute("""
            CREATE TABLE IF NOT EXISTS geocoding_cache (
                address TEXT PRIMARY KEY,
                latitude REAL,
                longitude REAL,
                updated_at REAL NOT NULL
            )
            """)
    }

    deinit {
        sqlite3_close(db)
    }

    static func defaultURL() -> URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "GeocodingCache.sqlite")
    }

    func lookup(_ address: String) -> LookupResult {
        var statement: OpaquePointer?
        let sql = "SELECT latitude, longitude, updated_at FROM geocoding_cache WHERE address = ?"
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return .miss }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_text(statement, 1, address, -1, SQLITE_TRANSIENT)

        guard sqlite3_step(statement) == SQLITE_ROW else { return .miss }

        if sqlite3_column_type(statement, 0) == SQLITE_NULL
            || sqlite3_column_type(statement, 1) == SQLITE_NULL {
            let updatedAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
            let isFresh = updatedAt.addingTimeInterval(failureRetryInterval) > Date()
            return isFresh ? .unresolved : .miss
        }

        return .found(
            latitude: sqlite3_column_double(statement, 0),
            longitude: sqlite3_column_double(statement, 1)
        )
    }

    /// 変換結果を保存する。`latitude`/`longitude` が nil の場合は「該当なし」を記録する。
    func save(_ address: String, latitude: Double?, longitude: Double?) {
        var statement: OpaquePointer?
        let sql = """
            INSERT OR REPLACE INTO geocoding_cache (address, latitude, longitude, updated_at)
            VALUES (?, ?, ?, ?)
            """
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, address, -1, SQLITE_TRANSIENT)
        if let latitude, let longitude {
            sqlite3_bind_double(statement, 2, latitude)
            sqlite3_bind_double(statement, 3, longitude)
        } else {
            sqlite3_bind_null(statement, 2)
            sqlite3_bind_null(statement, 3)
        }
        sqlite3_bind_double(statement, 4, Date().timeIntervalSince1970)
        sqlite3_step(statement)
    }

    private func execute(_ sql: String) throws {
        var errorMessage: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(errorMessage)
            throw StoreError.executeFailed(message)
        }
    }
}
