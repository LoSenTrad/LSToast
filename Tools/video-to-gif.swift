import Foundation
import AVFoundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Convert an actual simulator recording into the README animation.
// Usage: swift Tools/video-to-gif.swift input.mp4 output.gif [width] [fps] [start] [duration]
let arguments = CommandLine.arguments
guard arguments.count >= 3 else { fatalError("Usage: video-to-gif.swift input.mp4 output.gif [width] [fps] [start] [duration]") }
let input = URL(fileURLWithPath: arguments[1])
let output = URL(fileURLWithPath: arguments[2])
let width = arguments.count > 3 ? Int(arguments[3])! : 360
let fps = arguments.count > 4 ? Double(arguments[4])! : 5
let asset = AVURLAsset(url: input)
let assetDuration = try await asset.load(.duration).seconds
let start = arguments.count > 5 ? Double(arguments[5])! : 0
let requestedDuration = arguments.count > 6 ? Double(arguments[6])! : assetDuration - start
let duration = min(requestedDuration, assetDuration - start)
precondition(start >= 0 && duration > 0 && fps > 0 && width > 0)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
let count = max(1, Int(duration * fps))
try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
guard let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.gif.identifier as CFString, count, nil) else { fatalError("Cannot create GIF") }
CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
let properties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / fps,
                                                  kCGImagePropertyGIFUnclampedDelayTime: 1 / fps]] as CFDictionary
func resized(_ original: CGImage) -> CGImage {
    let height = max(1, Int(Double(original.height) * Double(width) / Double(original.width)))
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.interpolationQuality = .high
    context.draw(original, in: CGRect(x: 0, y: 0, width: width, height: height))
    return context.makeImage()!
}
for index in 0..<count {
    try autoreleasepool {
        let frame = try generator.copyCGImage(at: CMTime(seconds: start + Double(index) / fps, preferredTimescale: 600), actualTime: nil)
        CGImageDestinationAddImage(destination, resized(frame), properties)
    }
}
guard CGImageDestinationFinalize(destination) else { fatalError("Could not finalize GIF") }
print("GIF: \(count) frames, \(duration) seconds, \(width) px wide")
// A real video frame is also useful as a static fallback for reduced-motion readers.
let frame = try generator.copyCGImage(at: CMTime(seconds: start + min(10, max(0, duration - 1)), preferredTimescale: 600), actualTime: nil)
let poster = output.deletingLastPathComponent().appendingPathComponent("demo-poster.png")
let png = CGImageDestinationCreateWithURL(poster as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(png, resized(frame), nil)
_ = CGImageDestinationFinalize(png)
