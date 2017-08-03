//
//  StarHelper.swift
//  KDTree
//
//  Created by Konrad Feiler on 28.03.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import KDTree
import LoggerAPI

class StarHelper: NSObject {
    
    fileprivate static let csvFilePath: String = {
        return String.rootProjectPath + "/Resources/hygdata_v3.csv"
    }()

    static func loadCSVData(completion: (KDTree<Star>?) -> Void) {
        var startLoading = Date()
        
        guard let fileHandle = fopen(StarHelper.csvFilePath, "r") else {
            Log.error("Couldn't find hygdata_v3 in bundle for file \(StarHelper.csvFilePath)")
            completion(nil)
            return }
        defer { fclose(fileHandle) }
        
        let lines = lineIteratorC(file: fileHandle)
        let stars = lines.dropFirst().flatMap { linePtr -> Star? in
            defer { free(linePtr) }
            return Star(rowPtr :linePtr)
        }
        Log.verbose("Time to load stars: \(Date().timeIntervalSince(startLoading))s")
        startLoading = Date()
        let starTree = KDTree(values: stars)
        Log.verbose("Time to create Tree: \(Date().timeIntervalSince(startLoading))s")
        completion(starTree)
    }
    
    static func nearestStar(to ascension: Float, declination: Float, stars: KDTree<Star>) -> Star? {
        let searchStar = Star(ascension: ascension, declination: declination)
        
        let startNN = Date()
        var nearestStar = stars.nearest(toElement: searchStar)
        let nearestDistanceSqd = nearestStar?.squaredDistance(to: searchStar) ?? 10.0
        if sqrt(nearestDistanceSqd) > Double(searchStar.right_ascension) { // tap close to or below ascension = 0
            let searchStarModulo = searchStar.starMoved(ascension: 24.0, declination: 0.0)
            if let leftSideNearest = stars.nearest(toElement: searchStarModulo),
                leftSideNearest.squaredDistance(to: searchStarModulo) < nearestDistanceSqd {
                nearestStar = leftSideNearest.starMoved(ascension: -24.0, declination: 0.0)
            }
        }
        
        Log.verbose("Found nearest star \(String(describing: nearestStar?.dbID)) in \(Date().timeIntervalSince(startNN))s")
        return nearestStar
    }
}
