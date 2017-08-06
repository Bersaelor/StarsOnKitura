//
//  Star.swift
//  KDTree
//
//  Created by Konrad Feiler on 21/03/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import KDTree
import LoggerAPI

// swiftlint:disable variable_name

struct StarData {
    let hip_id: Int32?
    let hd_id: Int32?
    let hr_id: Int32?
    let gl_id: String?
    let bayer_flamstedt: String?
    let properName: String?
    let distance: Double
    let pmra: Double
    let pmdec: Double
    let rv: Double?
    let mag: Double
    let absmag: Double
    let spectralType: String?
    let colorIndex: Float?
}

extension Star {
    public var dataDictionary: [String: Any] {
        guard let data = self.starData?.value else {
            Log.error("Should have starData for \(self.dbID)")
            return ["dbID": dbID]
        }
        // so long as Kitura uses SwiftyJson's LclJSONSerialization,
        // JSON data should not contain Int, or Optionals
        return [
            "dbID": Int(dbID),
            "right_ascension": right_ascension,
            "declination": declination,
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

struct Star {
    let dbID: Int32
    let right_ascension: Float
    let declination: Float
    let starData: Box<StarData>?
    
    var starPoint: CGPoint {
        return CGPoint(x: CGFloat(self.right_ascension), y: CGFloat(self.declination))
    }
    
    init? (row: String) {
        let fields = row.components(separatedBy: ",")
        
        guard fields.count > 13 else {
            Log.warning("Not enough rows in \(fields)")
            return nil
        }
        
        guard let dbID = Int32(fields[0]),
            let right_ascension = Float(fields[7]),
            let declination = Float(fields[8]),
            let dist = Double(fields[9]),
            let pmra = Double(fields[10]),
            let pmdec = Double(fields[11]),
            let mag = Double(fields[13]),
            let absmag = Double(fields[14])
            else {
                Log.warning("Invalid Row: \(row), \n fields: \(fields)")
                return nil
        }

        self.dbID = dbID
        self.right_ascension = right_ascension
        self.declination = declination
        let starData = StarData(hip_id: Int32(fields[1]),
                                hd_id: Int32(fields[2]),
                                hr_id: Int32(fields[3]),
                                gl_id: fields[4],
                                bayer_flamstedt: fields[5],
                                properName: fields[6],
                                distance: dist, pmra: pmra, pmdec: pmdec, rv: Double(fields[12]),
                                mag: mag, absmag: absmag, spectralType: fields[14], colorIndex: Float(fields[15]))
        self.starData = Box(starData)
    }
    
    init (ascension: Float, declination: Float, dbID: Int32 = -1, starData: Box<StarData>? = nil) {
        self.dbID = dbID
        self.right_ascension = Float(ascension)
        self.declination = Float(declination)
        self.starData = starData
    }
    
    /// High performance initializer
    init? (rowPtr: UnsafeMutablePointer<CChar>) {
        var index = 0

        guard let dbID: Int32 = readNumber(at: &index, stringPtr: rowPtr) else { return nil }
        
        let hip_id: Int32? = readNumber(at: &index, stringPtr: rowPtr)
        let hd_id: Int32? = readNumber(at: &index, stringPtr: rowPtr)
        let hr_id: Int32? = readNumber(at: &index, stringPtr: rowPtr)
        let gl_id = readString(at: &index, stringPtr: rowPtr)
        let bayerFlamstedt = readString(at: &index, stringPtr: rowPtr)
        let properName = readString(at: &index, stringPtr: rowPtr)
        guard let right_ascension: Float = readNumber(at: &index, stringPtr: rowPtr),
            let declination: Float = readNumber(at: &index, stringPtr: rowPtr),
            let dist: Double = readNumber(at: &index, stringPtr: rowPtr),
            let pmra: Double = readNumber(at: &index, stringPtr: rowPtr),
            let pmdec: Double = readNumber(at: &index, stringPtr: rowPtr) else { return nil }
        let rv: Double? = readNumber(at: &index, stringPtr: rowPtr)
        guard let mag: Double = readNumber(at: &index, stringPtr: rowPtr),
            let absmag: Double = readNumber(at: &index, stringPtr: rowPtr) else { return nil }
        let spectralType = readString(at: &index, stringPtr: rowPtr)
        let colorIndex: Float? = readNumber(at: &index, stringPtr: rowPtr)

        self.dbID = dbID
        self.right_ascension = right_ascension
        self.declination = declination
        let starData = StarData(hip_id: hip_id,
                                hd_id: hd_id,
                                hr_id: hr_id,
                                gl_id: gl_id,
                                bayer_flamstedt: bayerFlamstedt,
                                properName: properName,
                                distance: dist, pmra: pmra, pmdec: pmdec, rv: rv,
                                mag: mag, absmag: absmag, spectralType: spectralType, colorIndex: colorIndex)
        self.starData = Box(starData)
    }
    
    func starMoved(ascension: Float, declination: Float) -> Star {
        return Star(ascension: self.right_ascension + ascension,
                    declination: self.declination + declination,
                    dbID: self.dbID, starData: self.starData)
    }
}

// swiftlint:enable variable_name

func == (lhs: Star, rhs: Star) -> Bool {
    return lhs.dbID == rhs.dbID
}

extension Star: Equatable {}

extension Star: KDTreePoint {
    public static var dimensions = 2
    
    public func kdDimension(_ dimension: Int) -> Double {
        return dimension == 0 ? Double(self.right_ascension) : Double(self.declination)
    }
    
    public func squaredDistance(to otherPoint: Star) -> Double {
        let x = self.right_ascension - otherPoint.right_ascension
        let y = self.declination - otherPoint.declination
        return Double(x*x + y*y)
    }
}

extension Star: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        let distanceString = String(describing: starData?.value.distance)
        let magString = String(describing: starData?.value.mag)
        return "🌠: ".appending(starData?.value.properName ?? "N.A.")
            .appending(", Hd(\(starData?.value.hd_id ?? -1)) + HR(\(starData?.value.hr_id ?? -1))")
            .appending("Gliese(\(starData?.value.gl_id ?? "")), BF(\(starData?.value.bayer_flamstedt ?? "")):")
            .appending("\(right_ascension), \(declination), \( distanceString ) mag: \(magString)")
    }
}

// MARK: CSV Helper Methods

fileprivate func indexOfCommaOrEnd(at index: Int, stringPtr: UnsafeMutablePointer<Int8>) -> Int {
    var newIndex = index
    while stringPtr[newIndex] != 0 && stringPtr[newIndex] != 44 { newIndex += 1 }
    if stringPtr[newIndex] != 0 { //if not at end of file, jump over comma
        newIndex += 1
    }
    return newIndex
}

fileprivate func readString(at index: inout Int, stringPtr: UnsafeMutablePointer<Int8>) -> String? {
    let startIndex = index
    index = indexOfCommaOrEnd(at: index, stringPtr: stringPtr)
    
    if index - startIndex > 1 {
        let mutableStringPtr = UnsafeMutablePointer<Int8>(mutating: stringPtr)
        stringPtr[index-1] = 0
        defer { stringPtr[index-1] = 44 }
        let newCPtr = mutableStringPtr.advanced(by: startIndex)
        return String(utf8String: newCPtr)
    }
    return nil
}

fileprivate protocol HasCFormatterString {
    static var cFormatString: [Int8] { get }
    static var initialValue: Self { get }
}

extension Int32: HasCFormatterString {
    static let cFormatString: [Int8] = [37, 100] // %d
    static let initialValue: Int32 = -1
}

extension Float: HasCFormatterString {
    static let cFormatString: [Int8] = [37, 102] // %f
    static let initialValue: Float = 0.0
}

extension Double: HasCFormatterString {
    static let cFormatString: [Int8] = [37, 108, 102] // %lf
    static let initialValue: Double = 0.0
}

fileprivate func readNumber<T: HasCFormatterString>(at index: inout Int, stringPtr: UnsafeMutablePointer<Int8> ) -> T? {
    let startIndex = index
    index = indexOfCommaOrEnd(at: index, stringPtr: stringPtr)
    
    if index - startIndex > 1 {
        var value: T = T.initialValue
        let newCPtr = stringPtr.advanced(by: startIndex)
        var scanned: Int32 = -1
        withUnsafeMutablePointer(to: &value, { valuePtr in
            let args: [CVarArg] = [valuePtr]
            scanned = withVaList(args, { (vaListPtr) -> Int32 in
                return vsscanf(newCPtr, T.cFormatString, vaListPtr)
            })
        })
        return scanned > 0 ? value : nil
    }
    return nil
}
