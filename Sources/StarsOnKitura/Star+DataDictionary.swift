//
//  Star+DataDictionary.swift
//  StarsOnKitura
//
//  Created by Konrad Feiler on 23.09.17.
//

import Foundation
import KDTree
import SwiftyHYGDB
import LoggerAPI

extension RadialStar {
    public var dataDictionary: [String: Any] {
        guard let data = self.starData?.value else {
            Log.error("Should have starData for \(self.dbID)")
            return ["dbID": dbID]
        }
        // so long as Kitura uses SwiftyJson's LclJSONSerialization,
        // JSON data should not contain Int, or Optionals
        return [
            "dbID": Int(dbID),
            "right_ascension": data.right_ascension,
            "declination": data.declination,
            "hip_id": data.hip_id.flatMap({ Int($0) }) ?? NSNull(),
            "hd_id": data.hd_id.flatMap({ Int($0) }) ?? NSNull(),
            "hr_id": data.hr_id.flatMap({ Int($0) }) ?? NSNull(),
            "gl_id": data.gl_id.flatMap({ Int($0) }) ?? NSNull(),
            "bayer_flamstedt": data.bayer_flamstedt ?? NSNull(),
            "properName": data.properName ?? NSNull(),
            "rv": data.rv ?? NSNull(),
            "mag": data.mag,
            "absmag": data.absmag,
            "spectralType": data.spectralType ?? NSNull(),
            "colorIndex": data.colorIndex ?? NSNull()
        ]
    }
}
