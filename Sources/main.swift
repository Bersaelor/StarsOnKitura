import Foundation
import Kitura
import KDTree
import Dispatch
import HeliumLogger
import LoggerAPI

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

    guard let stars = starTree else {
        response.send("Haven't finished parsing csv data yet, try again later")
        return
    }
    
    if let ascensionString = request.queryParameters["ascension"], let ascension = Float(ascensionString),
        let declinationString = request.queryParameters["declination"], let declination = Float(declinationString),
        let star = StarHelper.nearestStar(to: ascension, declination: declination, stars: stars) {
        Log.info(star.debugDescription)
        response.send("Found Star: \n".appending(star.debugDescription))
    } else {
        response.send("Wrongly formatted ascension or declination query parameters")
    }
}

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
