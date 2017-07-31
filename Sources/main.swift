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
        DispatchQueue.main.async {
            starTree = stars
            
            Log.info("Finished loading \(stars?.count ?? -1) stars, after \(Date().timeIntervalSince(startLoading))s")
        }
    }
}


// Mark: Respond with the Stars!

// Create a new router
let router = Router()

// Handle HTTP GET requests to /
router.get("/") {
    request, response, next in
    response.send("Hello, World!")
    next()
}

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
