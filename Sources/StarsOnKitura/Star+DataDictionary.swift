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
            Log.error("Should have had starData!)")
            return [:]
        }
        
        // so long as Kitura uses SwiftyJson's LclJSONSerialization,
        // JSON data should not contain Int, or Optionals
        return [
            "dbID": Int(data.db_id),
            "right_ascension": data.right_ascension,
            "declination": data.declination,
            "hip_id": data.hip_id != -1 ? Int(data.hip_id) : NSNull(),
            "hd_id": data.hd_id != -1 ? Int(data.hd_id) : NSNull(),
            "hr_id": data.hr_id != -1 ? Int(data.hr_id) : NSNull(),
            "gl_id": data.getGlId() ?? NSNull(),
            "bayer_flamstedt": data.getBayerFlamstedt() ?? NSNull(),
            "properName": data.getProperName() ?? NSNull(),
            "distance": data.distance,
            "rv": data.rv,
            "mag": data.mag,
            "absmag": data.absmag,
            "spectralType": data.getSpectralType() ?? NSNull(),
            "colorIndex": data.colorIndex
        ]
    }
}
