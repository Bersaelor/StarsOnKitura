import Foundation
import Kitura
import KituraStencil
import KDTree
import Dispatch
import HeliumLogger
import LoggerAPI

// Initialize HeliumLogger
HeliumLogger.use()

// Mark: Load the Stars!
// --------------

var starTree: KDTree<Star>?
let startLoading = Date()
DispatchQueue.global(qos: .background).async { _ in
    Log.info("Loading CSV")
    StarHelper.loadCSVData { stars in
        starTree = stars
        
        Log.info("Finished loading \(stars?.count ?? -1) stars, after \(Date().timeIntervalSince(startLoading))s")
    }
}

// MARK: routing
// --------------
let router = Router()

router.add(templateEngine: StencilTemplateEngine())

router.all("/", middleware: StaticFileServer(path: "./static"))

// Handle HTTP GET requests to /

// main page with sample links
router.get("/") { request, response, next in
    defer { next() }
    
    response.headers["Content-Type"] = "text/html; charset=utf-8"

    let context = [
        "links": [
            ["desc": "Nearest Star", "url": "./star?ascension=14.2&declination=19.2"],
            ["desc": "Nearest Stars", "url": "./nearestStars?number=6&ascension=20.5&declination=45.3"],
            ["desc": "Stars in Area", "url": "./starsAround?ascension=15.2&declination=3.0&radiusX=1.4&radiusY=2&maxMag=4"]
        ]
    ]
    try response.render("main.stencil", context: context).end()
}

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
        Log.info("Json: \(star.dataDictionary)")
        response.send(json: star.dataDictionary)
//        response.send(json: ["JSONKEY": "RESPONSE"])
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
    
    if let ascension = request.queryParameters["ascension"].flatMap({ Float($0) }),
        let declination = request.queryParameters["declination"].flatMap({ Float($0) }),
        let radiusX = request.queryParameters["radiusX"].flatMap({ Float($0) }),
        let radiusY = request.queryParameters["radiusY"].flatMap({ Float($0) })
    {
        let maxMag = request.queryParameters["maxMag"].flatMap( { Double($0) })
        let stars = StarHelper.stars(from: starTree, around: ascension, declination: declination,
                                     radiusAs: radiusX, radiusDec: radiusY, maxMag: maxMag)

        response.send(json: stars.map { $0.dataDictionary } )
    } else {
        response.send("Wrongly formatted ascension, declination, radiusX or radiusY query parameters")
    }
}

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
