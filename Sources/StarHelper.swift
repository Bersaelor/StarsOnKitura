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
        return String.getAbsolutePath(for: "./Resources/hygdata_v3.csv")
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
        if sqrt(nearestDistanceSqd) > abs(Double(searchStar.right_ascension - 24)) { // point close to or below ascension = 0
            let searchStarModulo = searchStar.starMoved(ascension: 24.0, declination: 0.0)
            if let leftSideNearest = stars.nearest(toElement: searchStarModulo),
                leftSideNearest.squaredDistance(to: searchStarModulo) < nearestDistanceSqd {
                nearestStar = leftSideNearest.starMoved(ascension: -24.0, declination: 0.0)
            }
        }
        
        Log.verbose("Found nearest star \(String(describing: nearestStar?.dbID)) in \(Date().timeIntervalSince(startNN))s")
        return nearestStar
    }
    
    static func nearest(number: Int, to ascension: Float, declination: Float, from stars: KDTree<Star>) -> [Star] {
        let searchStar = Star(ascension: ascension, declination: declination)
        
        let startNN = Date()
        var nearest = stars.nearestK(number, toElement: searchStar)
        let nearestDistanceSqd = nearest.last?.squaredDistance(to: searchStar) ?? 10.0
        if sqrt(nearestDistanceSqd) > Double(searchStar.right_ascension) { // point close to or below ascension = 0
            let searchStarModulo = searchStar.starMoved(ascension: 24.0, declination: 0.0)
            let leftSideNearest = stars.nearestK(number, toElement: searchStarModulo)
            if leftSideNearest.last?.squaredDistance(to: searchStarModulo) ?? Double.infinity < nearestDistanceSqd {
                let nearestLeft = leftSideNearest.map { $0.starMoved(ascension: -24.0, declination: 0.0) }
                nearest.append(contentsOf: nearestLeft)
                nearest.sort { (starA, starB) -> Bool in
                    starA.squaredDistance(to: searchStar) < starB.squaredDistance(to: searchStar)
                }
                if nearest.count > number { nearest.removeLast(nearest.count - number) }
            }
        }
        
        Log.verbose("Found nearest stars \(nearest.count) in \(Date().timeIntervalSince(startNN))s")
        return nearest
    }
    
    
    static func stars(from stars: KDTree<Star>, around ascension: Float,
                      declination: Float, radiusAs: Float, radiusDec: Float, maxMag: Double?) -> [Star]
    {
        let startRangeSearch = Date()
        
        var starsVisible = stars.elementsIn([
            (Double(ascension - radiusAs), Double(ascension + radiusAs)),
            (Double(declination - radiusDec), Double(declination + radiusDec))])
        
        //add the points on the other side of the y-axis in case part of the screen is below
        if ascension < radiusAs {
            let leftIntervals: [(Double, Double)] = [
                (Double( 24.0 + ascension - radiusAs), Double(24.0 + ascension + radiusAs)),
                (Double(declination - radiusDec), Double(declination + radiusDec))]
            starsVisible += stars.elementsIn(leftIntervals).map({ (star: Star) -> Star in
                return star.starMoved(ascension: -24.0, declination: 0.0)
            })
        }
        if let maxMag = maxMag {
            starsVisible = starsVisible.filter { (star) -> Bool in
                return star.starData?.value.mag ?? Double.infinity < maxMag
            }
        }
        Log.verbose("Finished RangeSearch with \(starsVisible.count) stars, after \(Date().timeIntervalSince(startRangeSearch))s")
        return starsVisible
    }
}
