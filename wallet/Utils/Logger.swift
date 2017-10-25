//
//  Logger.swift
//  certificates
//
//  Created by Chris Downie on 10/25/17.
//  Copyright © 2017 Learning Machine, Inc. All rights reserved.
//

import Foundation

private enum LogLevel : String, Codable {
    case debug, info, warning, error, fatal
}

private struct LogEntry : Codable {
    let date : Date
    let level : LogLevel
    let message : String
    
    init(level: LogLevel, message: String) {
        self.level = level
        self.message = message
        date = Date()
    }
}

struct Logger {
    private let logFile : URL
    
    // Dependencies injected
    private let manager : FileManager
    private let encoder : JSONEncoder
    private let decoder : JSONDecoder
    
    private var recentLogs : [LogEntry]
    
    init(manager: FileManager = FileManager.default,
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
    
    // Log methods that correspond to the log levels
    public mutating func debug(_ string: String)   { log(level: .debug, message: string)   }
    public mutating func info(_ string: String)    { log(level: .info, message: string)    }
    public mutating func warning(_ string: String) { log(level: .warning, message: string) }
    public mutating func error(_ string: String)   { log(level: .error, message: string)   }
    public mutating func fatal(_ string: String)   { log(level: .fatal, message: string)   }
    
    private mutating func log(level: LogLevel, message: String) {
        let entry = LogEntry(level: level, message: message)
        recentLogs.append(entry)
    }
    
    public mutating func flushLogs() {
        var logs = loadLogs()
        logs.append(contentsOf: recentLogs)
        recentLogs.removeAll()
        
        save(logs: logs)
    }
    
    public func pruneLogs() {
        let logs = loadLogs()
        
        let twentyFourHoursAgo = Date().addingTimeInterval(-1 * 60 * 60 * 24)
        let prunedLogs = logs.filter { (entry) -> Bool in
            entry.date > twentyFourHoursAgo
        }
        
        // Save the logs back out
        save(logs: prunedLogs)
    }
    
    public mutating func emptyingLogs() {
        recentLogs.removeAll()
        try? FileManager.default.removeItem(at: logFile)
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
        
        return logs
    }
    
    private func save(logs: [LogEntry]) {
        do {
            let data = try encoder.encode(logs)
            try data.write(to: logFile)
        } catch {
            print("Failed to encode logs: \(error)")
        }
    }
}

