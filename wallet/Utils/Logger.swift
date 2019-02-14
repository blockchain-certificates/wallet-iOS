//
//  Logger.swift
//  certificates
//
//  Created by Chris Downie on 10/25/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import Foundation
import Blockcerts

private enum LogLevel : String, Codable {
    case debug, info, warning, error, fatal
}

private struct LogEntry : Codable, CustomStringConvertible {
    var description: String {
        return "\(date)[\(level)]" + (tag.isEmpty ? "" : "/\(tag)") + ": \(message)"
    }

    let date : Date
    let level : LogLevel
    let message : String
    let tag : String

    init(level: LogLevel, message: String, tag: String = "") {
        self.level = level
        self.message = message
        self.tag = tag
        date = Date()
    }
}

class Logger {
    static public let main = Logger()

    // Config
    private let printEverything = true

    // Actual useful properties
    private let logFile : URL
    private var recentLogs : [LogEntry]
    private var workItem : DispatchWorkItem? = nil
    private var currentTang: String = ""

    // Dependencies injected
    private let manager : FileManager
    private let encoder : JSONEncoder
    private let decoder : JSONDecoder



    private init(manager: FileManager = FileManager.default,
                 logFile: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("debug_log"),
                 encoder: JSONEncoder? = nil, decoder: JSONDecoder? = nil) {
        self.manager = manager
        self.logFile = logFile
        recentLogs = []

        if let encoder = encoder {
            self.encoder = encoder
        } else {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .iso8601

            self.encoder = jsonEncoder
        }

        if let decoder = decoder {
            self.decoder = decoder
        } else {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .iso8601

            self.decoder = jsonDecoder
        }
    }

    deinit {
        flushLogs()
    }

    public func tag(_ tag: String?) -> Logger {
        self.currentTang = tag ?? ""
        return self
    }

    // Log methods that correspond to the log levels
    public func debug(_ string: String)   { log(level: .debug, message: string)   }
    public func info(_ string: String)    { log(level: .info, message: string)    }
    public func warning(_ string: String) { log(level: .warning, message: string) }
    public func error(_ string: String)   { log(level: .error, message: string)   }
    public func fatal(_ string: String)   { log(level: .fatal, message: string)   }

    public func flushLogs() {
        var logs = loadLogs()
        logs.append(contentsOf: recentLogs)
        recentLogs.removeAll()

        save(logs: logs)
    }

    public func shareLogs() throws -> URL {
        flushLogs()

        let tempFile = manager.temporaryDirectory.appendingPathComponent("logs.json")

        if manager.fileExists(atPath: tempFile.path) {
            try manager.removeItem(at: tempFile)
        }
        try manager.copyItem(at: logFile, to: tempFile)

        return tempFile
    }

    public func clearLogs() {
        save(logs: [])
    }

    // Mark - private helper functions
    private func log(level: LogLevel, message: String) {
        let entry = LogEntry(level: level, message: message, tag: currentTang)
        if printEverything {
            print(entry)
        }
        recentLogs.append(entry)

        // Every 10s or so, flush recent logs out to file.
        if workItem == nil {
            let work = DispatchWorkItem(qos: .background, flags: [], block: { [weak self] in
                self?.flushLogs()
                self?.workItem = nil
            })

            workItem = work
            let dispatchTime = DispatchTime.now() + .seconds(10)
            DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: work)
        }

        currentTang = ""
    }

    private func prune(logs: [LogEntry]) -> [LogEntry] {
        let twentyFourHoursAgo = Date().addingTimeInterval(-1 * 60 * 60 * 24)
        let prunedLogs = logs.filter { (entry) -> Bool in
            entry.date > twentyFourHoursAgo
        }
        return prunedLogs
    }

    private func loadLogs() -> [LogEntry] {
        guard let logData = manager.contents(atPath: logFile.path) else {
            return []
        }

        var logs : [LogEntry] = []
        do {
            logs = try decoder.decode(Array.self, from: logData)
        } catch {
            print("Something went wrong, couldn't decode logs: \(error)")
        }

        return prune(logs: logs)
    }

    private func save(logs: [LogEntry]) {
        do {
            let data = try encoder.encode(logs)
            try data.write(to: logFile)
        } catch {
            print("Failed to encode logs: \(error)")
        }
    }

    public func toLoggerProtocol() -> LoggerProtocol {

        class LoggerWrapper : LoggerProtocol {
            var logger: Logger

            init(wraps logger: Logger) {
                self.logger = logger
            }

            func tag(_ tag: String?) -> LoggerProtocol {
                logger.tag(tag)
                return self
            }

            func info(_ message: String) {
                logger.info(message)
            }

            func debug(_ message: String) {
                logger.debug(message)
            }

            func warning(_ message: String) {
                logger.warning(message)
            }

            func error(_ message: String) {
                logger.error(message)
            }
        }

        return LoggerWrapper(wraps: self)
    }
}

