import Foundation
import Kitura
import KDTree
import Dispatch
import HeliumLogger
import LoggerAPI
import SwiftyJSON

// Initialize HeliumLogger
HeliumLogger.use()

// Mark: Load the Stars!
var starTree: KDTree<Star>?
let startLoading = Date()
DispatchQueue.global(qos: .background).async { _ in
    Log.info("Loading CSV")
    StarHelper.loadCSVData { stars in
        starTree = stars
        
        Log.info("Finished loading \(stars?.count ?? -1) stars, after \(Date().timeIntervalSince(startLoading))s")
    }
}

// Mark: Respond with the Stars!

// Create a new router
let router = Router()

// Handle HTTP GET requests to /
router.get("/") { request, response, next in
    defer { next() }

    response.send("Hello, World!")
}

// Handle HTTP GET requests to /
router.get("/star") { request, response, next in
    defer { next() }

    response.headers["Content-Type"] = "text/html; charset=utf-8"

    guard let starTree = starTree else {
        response.send("Haven't finished parsing csv data yet, try again later")
        return
    }
    
    if let ascensionString = request.queryParameters["ascension"], let ascension = Float(ascensionString),
        let declinationString = request.queryParameters["declination"], let declination = Float(declinationString),
        let star = StarHelper.nearestStar(to: ascension, declination: declination, stars: starTree) {
        Log.info(star.debugDescription)
        response.send(json: star.dataDictionary)
    } else {
        response.send("Wrongly formatted ascension or declination query parameters")
    }
}

router.get("/nearestStars") { request, response, next in
    defer { next() }
    
    response.headers["Content-Type"] = "text/html; charset=utf-8"
    
    guard let starTree = starTree else {
        response.send("Haven't finished parsing csv data yet, try again later")
        return
    }
    
    if let numberString = request.queryParameters["number"], let number = Int(numberString),
        let ascensionString = request.queryParameters["ascension"], let ascension = Float(ascensionString),
        let declinationString = request.queryParameters["declination"], let declination = Float(declinationString)
    {
        let stars = StarHelper.nearest(number: number, to: ascension, declination: declination, from: starTree)
        response.send(json: stars.map { $0.dataDictionary } )
    } else {
        response.send("Wrongly formatted ascension or declination query parameters")
    }
}

router.get("/starsAround") { request, response, next in
    defer { next() }
    
    response.headers["Content-Type"] = "text/html; charset=utf-8"
    
    guard let starTree = starTree else {
        response.send("Haven't finished parsing csv data yet, try again later")
        return
    }
    
    if let ascensionString = request.queryParameters["ascension"], let ascension = Float(ascensionString),
        let declinationString = request.queryParameters["declination"], let declination = Float(declinationString),
        let radiusXString = request.queryParameters["radiusX"], let radiusX = Float(radiusXString),
        let radiusYString = request.queryParameters["radiusY"], let radiusY = Float(radiusYString)
    {
        let stars = StarHelper.stars(from: starTree, around: ascension, declination: declination,
                                     radiusAs: radiusX, radiusDec: radiusY)
        response.send(json: stars.map { $0.dataDictionary } )
    } else {
        response.send("Wrongly formatted ascension, declination, radiusX or radiusY query parameters")
    }
}

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
