import Cocoa
import CoreGraphics
import ImageIO

func createIconBitmap(pixelSize: Int) -> CGImage? {
    let width = pixelSize
    let height = pixelSize
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        return nil
    }
    
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    
    let size = CGFloat(pixelSize)
    let scale = size / 1024.0
    
    // Background: Cheerful, vibrant fresh green (#16A34A / #22C55E blend, ~#1BA84E)
    let bgGreen = CGColor(red: 25/255.0, green: 165/255.0, blue: 75/255.0, alpha: 1.0)
    context.setFillColor(bgGreen)
    context.fill(CGRect(x: 0, y: 0, width: size, height: size))
    
    // Line style: Pure white, round caps & round joins for friendly cartoon feel
    let white = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    context.setStrokeColor(white)
    context.setFillColor(white)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    
    let mainStrokeW = 34.0 * scale
    let detailStrokeW = 24.0 * scale
    context.setLineWidth(mainStrokeW)
    
    // Scaling helper
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        return CGPoint(x: x * scale, y: y * scale)
    }
    
    let ox: CGFloat = 20
    let oy: CGFloat = 10
    
    // 1. WHEELS
    let rearWheel = pt(380 + ox, 335 + oy)
    let frontWheel = pt(690 + ox, 335 + oy)
    let wheelOuterR = 66.0 * scale
    let wheelInnerR = 24.0 * scale
    let wheelArchR = 96.0 * scale
    
    context.strokeEllipse(in: CGRect(x: frontWheel.x - wheelOuterR, y: frontWheel.y - wheelOuterR, width: wheelOuterR * 2, height: wheelOuterR * 2))
    context.fillEllipse(in: CGRect(x: frontWheel.x - wheelInnerR, y: frontWheel.y - wheelInnerR, width: wheelInnerR * 2, height: wheelInnerR * 2))
    
    context.strokeEllipse(in: CGRect(x: rearWheel.x - wheelOuterR, y: rearWheel.y - wheelOuterR, width: wheelOuterR * 2, height: wheelOuterR * 2))
    context.fillEllipse(in: CGRect(x: rearWheel.x - wheelInnerR, y: rearWheel.y - wheelInnerR, width: wheelInnerR * 2, height: wheelInnerR * 2))
    
    // 2. STUBBY BUBBLY CAR BODY
    let carPath = CGMutablePath()
    
    carPath.move(to: pt(240 + ox, 335 + oy))
    carPath.addCurve(to: pt(245 + ox, 445 + oy), control1: pt(235 + ox, 365 + oy), control2: pt(238 + ox, 410 + oy))
    carPath.addCurve(to: pt(310 + ox, 500 + oy), control1: pt(255 + ox, 475 + oy), control2: pt(280 + ox, 495 + oy))
    
    carPath.addCurve(to: pt(460 + ox, 660 + oy), control1: pt(345 + ox, 565 + oy), control2: pt(395 + ox, 645 + oy))
    carPath.addCurve(to: pt(610 + ox, 660 + oy), control1: pt(510 + ox, 672 + oy), control2: pt(560 + ox, 672 + oy))
    
    carPath.addCurve(to: pt(735 + ox, 500 + oy), control1: pt(665 + ox, 645 + oy), control2: pt(710 + ox, 565 + oy))
    carPath.addCurve(to: pt(820 + ox, 455 + oy), control1: pt(765 + ox, 480 + oy), control2: pt(795 + ox, 470 + oy))
    carPath.addCurve(to: pt(830 + ox, 395 + oy), control1: pt(840 + ox, 440 + oy), control2: pt(845 + ox, 415 + oy))
    carPath.addCurve(to: pt(790 + ox, 335 + oy), control1: pt(825 + ox, 355 + oy), control2: pt(810 + ox, 335 + oy))
    
    carPath.addLine(to: pt(690 + 96 + ox, 335 + oy))
    carPath.addArc(center: frontWheel, radius: wheelArchR, startAngle: 0, endAngle: CGFloat.pi, clockwise: false)
    
    carPath.addLine(to: pt(380 + 96 + ox, 335 + oy))
    carPath.addArc(center: rearWheel, radius: wheelArchR, startAngle: 0, endAngle: CGFloat.pi, clockwise: false)
    carPath.addLine(to: pt(240 + ox, 335 + oy))
    
    context.addPath(carPath)
    context.strokePath()
    
    // 3. PARALLEL BUBBLE WINDOWS
    let windowPath = CGMutablePath()
    
    // Rear window
    windowPath.move(to: pt(460 + ox, 605 + oy))
    windowPath.addLine(to: pt(520 + ox, 608 + oy))
    windowPath.addLine(to: pt(520 + ox, 505 + oy))
    windowPath.addLine(to: pt(345 + ox, 505 + oy))
    windowPath.addCurve(to: pt(460 + ox, 605 + oy), control1: pt(375 + ox, 550 + oy), control2: pt(415 + ox, 595 + oy))
    
    // Front window
    windowPath.move(to: pt(550 + ox, 608 + oy))
    windowPath.addCurve(to: pt(600 + ox, 605 + oy), control1: pt(565 + ox, 608 + oy), control2: pt(585 + ox, 607 + oy))
    windowPath.addCurve(to: pt(680 + ox, 505 + oy), control1: pt(635 + ox, 595 + oy), control2: pt(665 + ox, 550 + oy))
    windowPath.addLine(to: pt(550 + ox, 505 + oy))
    windowPath.closeSubpath()
    
    context.saveGState()
    context.setLineWidth(detailStrokeW)
    context.addPath(windowPath)
    context.strokePath()
    context.restoreGState()
    
    // 4. CUTE DETAILS: Round Headlight & Taillight & Door Handle
    let headlightCenter = pt(800 + ox, 435 + oy)
    let headlightR = 20.0 * scale
    context.strokeEllipse(in: CGRect(x: headlightCenter.x - headlightR, y: headlightCenter.y - headlightR, width: headlightR * 2, height: headlightR * 2))
    let headlightInnerR = 8.0 * scale
    context.fillEllipse(in: CGRect(x: headlightCenter.x - headlightInnerR, y: headlightCenter.y - headlightInnerR, width: headlightInnerR * 2, height: headlightInnerR * 2))
    
    let taillightCenter = pt(265 + ox, 455 + oy)
    let taillightR = 14.0 * scale
    context.strokeEllipse(in: CGRect(x: taillightCenter.x - taillightR, y: taillightCenter.y - taillightR, width: taillightR * 2, height: taillightR * 2))
    
    let handlePath = CGMutablePath()
    handlePath.move(to: pt(480 + ox, 480 + oy))
    handlePath.addLine(to: pt(515 + ox, 480 + oy))
    context.saveGState()
    context.setLineWidth(detailStrokeW)
    context.addPath(handlePath)
    context.strokePath()
    context.restoreGState()
    
    // 5. CHARGING STATION & PLAYFUL LOOPING CABLE
    let boxW: CGFloat = 84 * scale
    let boxH: CGFloat = 120 * scale
    let boxRect = CGRect(x: (85 + ox) * scale, y: (610 + oy) * scale, width: boxW, height: boxH)
    let boxPath = CGPath(roundedRect: boxRect, cornerWidth: 22 * scale, cornerHeight: 22 * scale, transform: nil)
    
    context.saveGState()
    context.setLineWidth(mainStrokeW)
    context.addPath(boxPath)
    context.strokePath()
    
    let boltPath = CGMutablePath()
    boltPath.move(to: pt(132 + ox, 705 + oy))
    boltPath.addLine(to: pt(115 + ox, 665 + oy))
    boltPath.addLine(to: pt(129 + ox, 665 + oy))
    boltPath.addLine(to: pt(122 + ox, 628 + oy))
    boltPath.addLine(to: pt(141 + ox, 672 + oy))
    boltPath.addLine(to: pt(127 + ox, 672 + oy))
    boltPath.closeSubpath()
    
    context.setFillColor(white)
    context.addPath(boltPath)
    context.fillPath()
    context.restoreGState()
    
    let cablePath = CGMutablePath()
    cablePath.move(to: pt(285 + ox, 490 + oy))
    cablePath.addCurve(to: pt(150 + ox, 430 + oy), control1: pt(225 + ox, 485 + oy), control2: pt(180 + ox, 380 + oy))
    cablePath.addCurve(to: pt(127 + ox, 610 + oy), control1: pt(125 + ox, 475 + oy), control2: pt(127 + ox, 550 + oy))
    
    context.saveGState()
    context.setLineWidth(detailStrokeW)
    context.addPath(cablePath)
    context.strokePath()
    
    let plugRect = CGRect(x: (280 + ox) * scale, y: (480 + oy) * scale, width: 22 * scale, height: 20 * scale)
    let plugPath = CGPath(roundedRect: plugRect, cornerWidth: 6 * scale, cornerHeight: 6 * scale, transform: nil)
    context.setFillColor(white)
    context.addPath(plugPath)
    context.fillPath()
    context.restoreGState()
    
    return context.makeImage()
}

func saveCGImageAsPNG(cgImage: CGImage, path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let destination = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil) else {
        print("Failed to create destination for \(path)")
        return
    }
    CGImageDestinationAddImage(destination, cgImage, nil)
    if CGImageDestinationFinalize(destination) {
        print("Saved: \(path)")
    } else {
        print("Failed to write \(path)")
    }
}

// 1. Save iOS AppIcon (1024x1024)
let iosBaseDir = "/Volumes/Thunderbolt/Users/pkormann/evcharge-calc-ios/EVChargeCalculator/Assets.xcassets/AppIcon.appiconset"

if let img1024 = createIconBitmap(pixelSize: 1024) {
    saveCGImageAsPNG(cgImage: img1024, path: "\(iosBaseDir)/AppIcon-1024.png")
}

// Clean up any extra icon files in AppIcon.appiconset
let fileManager = FileManager.default
if let enumerator = fileManager.enumerator(atPath: iosBaseDir) {
    for case let file as String in enumerator {
        if file.hasSuffix(".png") && file != "AppIcon-1024.png" {
            try? fileManager.removeItem(atPath: "\(iosBaseDir)/\(file)")
        }
    }
}

// 2. Save Android mipmap icons
let androidResDir = "/Volumes/Thunderbolt/Users/pkormann/evcharge-calc-android/app/src/main/res"
let androidSizes: [(String, Int)] = [
    ("mipmap-mdpi/ic_launcher.png", 48),
    ("mipmap-hdpi/ic_launcher.png", 72),
    ("mipmap-xhdpi/ic_launcher.png", 96),
    ("mipmap-xxhdpi/ic_launcher.png", 144),
    ("mipmap-xxxhdpi/ic_launcher.png", 192),
    ("mipmap-mdpi/ic_launcher_round.png", 48),
    ("mipmap-hdpi/ic_launcher_round.png", 72),
    ("mipmap-xhdpi/ic_launcher_round.png", 96),
    ("mipmap-xxhdpi/ic_launcher_round.png", 144),
    ("mipmap-xxxhdpi/ic_launcher_round.png", 192)
]

for (relPath, px) in androidSizes {
    if let img = createIconBitmap(pixelSize: px) {
        saveCGImageAsPNG(cgImage: img, path: "\(androidResDir)/\(relPath)")
    }
}
