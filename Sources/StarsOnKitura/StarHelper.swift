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
import SwiftyHYGDB
import Dispatch

class StarHelper: NSObject {
    
    fileprivate static let csvFilePath: String = {
        return String.getAbsolutePath(for: "./Resources/hygdata_v3.csv")
    }()

    static func loadStarTree(named filePath: String, completion: @escaping (KDTree<RadialStar>?) -> Void) {
        let startLoading = Date()
        
        DispatchQueue.global(qos: .background).async {
            guard let stars: [RadialStar] = SwiftyHYGDB.loadCSVData(from: filePath) else {
                completion(nil)
                return
            }
            Log.debug("Time to load \(stars.count) stars: \(Date().timeIntervalSince(startLoading))s from \(filePath)")
            let startTreeBuilding = Date()
            let tree = KDTree(values: stars)
            Log.debug("Time build tree: \(Date().timeIntervalSince(startTreeBuilding)),"
                .appending(" complete time: \(Date().timeIntervalSince(startLoading))s"))
            completion(tree)
        }
    }
    
    static func nearestStar(to ascension: Float, declination: Float, stars: KDTree<RadialStar>) -> RadialStar? {
        let searchStar = RadialStar(ascension: ascension, declination: declination)
        
        let startNN = Date()
        var nearestStar = stars.nearest(to: searchStar)
        let nearestDistanceSqd = nearestStar?.squaredDistance(to: searchStar) ?? 10.0
        if sqrt(nearestDistanceSqd) > abs(Double(searchStar.normalizedAscension - 1)) { // point close to or below ascension = 0
            let searchStarModulo = searchStar.starMoved(ascension: 24.0, declination: 0.0)
            if let leftSideNearest = stars.nearest(to: searchStarModulo),
                leftSideNearest.squaredDistance(to: searchStarModulo) < nearestDistanceSqd {
                nearestStar = leftSideNearest.starMoved(ascension: -24.0, declination: 0.0)
            }
        }
        
        Log.verbose("Found nearest star \(String(describing: nearestStar?.dbID)) in \(Date().timeIntervalSince(startNN))s")
        return nearestStar
    }
    
    static func nearest(number: Int, to ascension: Float, declination: Float, from stars: KDTree<RadialStar>) -> [RadialStar] {
        let searchStar = RadialStar(ascension: ascension, declination: declination)
        
        let startNN = Date()
        var nearest = stars.nearestK(number, to: searchStar)
        let nearestDistanceSqd = nearest.last?.squaredDistance(to: searchStar) ?? 10.0
        if sqrt(nearestDistanceSqd) > Double(searchStar.normalizedAscension) { // point close to or below ascension = 0
            let searchStarModulo = searchStar.starMoved(ascension: 24.0, declination: 0.0)
            let leftSideNearest = stars.nearestK(number, to: searchStarModulo)
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
    
    
    static func stars(from stars: KDTree<RadialStar>, around ascension: Float,
                      declination: Float, deltaAsc: Float, deltaDec: Float, maxMag: Double?) -> [RadialStar]
    {
        let startRangeSearch = Date()
        
        let verticalRange = (Double(RadialStar.normalize(declination: declination - deltaDec)),
                             Double(RadialStar.normalize(declination: declination + deltaDec)))
        var starsVisible = stars.elementsIn([
            (Double(RadialStar.normalize(rightAscension: ascension - deltaAsc)),
             Double(RadialStar.normalize(rightAscension: ascension + deltaAsc))), verticalRange])
        
        //add the points on the other side of the y-axis in case part of the screen is below
        if ascension < deltaAsc {
            let leftIntervals: [(Double, Double)] = [
                (Double( 24.0 + ascension - deltaAsc), Double(24.0 + ascension + deltaAsc)),
                (Double(declination - deltaDec), Double(declination + deltaDec))]
            starsVisible += stars.elementsIn(leftIntervals).map({ (star: RadialStar) -> RadialStar in
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
