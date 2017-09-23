//
//  String+ProjectFilePath.swift
//  borace
//
//  Created by Konrad Feiler on 30.05.17.
//
//

import Foundation
import LoggerAPI

extension String {
    static private let separatorCharacter: Character = "/"
    static private let separator = String(separatorCharacter)
    
    static func getAbsolutePath(for path: String) -> String {
        var path = path
        if path.hasSuffix(separator) && path != separator {
            path = String(path.characters.dropLast())
        }
        
        // If we received a path with a tilde (~) in the front, expand it.
        path = NSString(string: path).expandingTildeInPath
        
        if isAbsolute(path: path) {
            return path
        }
        
        let fileManager = FileManager()
        
        let absolutePath = fileManager.currentDirectoryPath + separator + path
        Log.info("currentDirectoryPath \( fileManager.currentDirectoryPath )")
        if fileManager.fileExists(atPath: absolutePath) {
            return absolutePath
        }
        
        // the file does not exist on a path relative to the current working directory
        // return the path relative to the original repository directory
        guard let originalRepositoryPath = getOriginalRepositoryPath() else {
            return absolutePath
        }
        
        Log.info("originalRepositoryPath \( originalRepositoryPath )")

        return originalRepositoryPath + separator + path
    }
    
    static private func isAbsolute(path: String) -> Bool {
        return path.hasPrefix(separator)
    }
    
    static private func getOriginalRepositoryPath() -> String? {
        // this file is at
        // <original repository directory>/Sources/Kitura/staticFileServer/ResourcePathHandler.swift
        // the original repository directory is four path components up
        let currentFilePath = #file
        
        var pathComponents =
            currentFilePath.characters.split(separator: separatorCharacter).map(String.init)
        let numberOfComponentsFromKituraRepositoryDirectoryToThisFile = 2
        
        guard pathComponents.count >= numberOfComponentsFromKituraRepositoryDirectoryToThisFile else {
            Log.error("unable to get original repository path for \(currentFilePath)")
            return nil
        }
        
        pathComponents.removeLast(numberOfComponentsFromKituraRepositoryDirectoryToThisFile)
        pathComponents = removePackagesDirectory(pathComponents: pathComponents)
        
        return separator + pathComponents.joined(separator: separator)
    }
    
    static private func removePackagesDirectory(pathComponents: [String]) -> [String] {
        var pathComponents = pathComponents
        let numberOfComponentsFromKituraPackageToDependentRepository = 3
        let packagesComponentIndex = pathComponents.endIndex - numberOfComponentsFromKituraPackageToDependentRepository
        if pathComponents.count > numberOfComponentsFromKituraPackageToDependentRepository &&
            pathComponents[packagesComponentIndex] == ".build"  &&
            pathComponents[packagesComponentIndex+1] == "checkouts" {
            pathComponents.removeLast(numberOfComponentsFromKituraPackageToDependentRepository)
        }
        else {
            let numberOfComponentsFromEditableKituraPackageToDependentRepository = 2
            let editablePackagesComponentIndex = pathComponents.endIndex - numberOfComponentsFromEditableKituraPackageToDependentRepository
            if pathComponents.count > numberOfComponentsFromEditableKituraPackageToDependentRepository &&
                pathComponents[editablePackagesComponentIndex] == "Packages" {
                pathComponents.removeLast(numberOfComponentsFromEditableKituraPackageToDependentRepository)
            }
        }
        return pathComponents
    }
}
