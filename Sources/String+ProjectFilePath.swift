//
//  String+ProjectFilePath.swift
//  borace
//
//  Created by Konrad Feiler on 30.05.17.
//
//

import Foundation

extension String {
    private static let separator = "/"
    
    static var rootProjectPath: String {
        let currentFilePath = #file
        
        var pathComponents = currentFilePath.components(separatedBy: separator)
        let numberOfComponentsFromProjectRepositoryDirectoryToThisFile = 2

        pathComponents.removeLast(numberOfComponentsFromProjectRepositoryDirectoryToThisFile)
        
        guard pathComponents.count >= numberOfComponentsFromProjectRepositoryDirectoryToThisFile else {
            fatalError("ERROR: unable to get original repository path for \(currentFilePath)")
        }

        return separator + pathComponents.joined(separator: separator)
    }
}
