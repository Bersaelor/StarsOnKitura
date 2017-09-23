//
//  App.swift
//  borace
//
//  Created by Konrad Feiler on 08.09.17.
//
//

import Foundation

struct App {
    static let current = App()
    
    fileprivate let startTime = Date()
}

extension App {
    
    func started() { }
    
    private var upTime: String {
        #if os(OSX) || os(iOS) || os(tvOS)
            return DateComponentsFormatter().string(from: Date().timeIntervalSince(startTime))?.appending(" s") ?? "? s"
        #else
            let interval = Int(Date().timeIntervalSince(startTime))
            let seconds = interval % 60
            let minutes = (interval / 60) % 60
            let hours = (interval / 3600)
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        #endif
    }
    
    var stencilContext: [String: String] {
        return [
            "uptime": upTime,
        ]
    }

}
