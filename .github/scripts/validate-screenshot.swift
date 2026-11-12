import CoreGraphics
import Darwin
import Foundation
import ImageIO

@main
enum ScreenshotValidator {
    static func main() {
        guard CommandLine.arguments.count == 2 else {
            fputs("Usage: validate-screenshot <image.png>\n", stderr)
            exit(2)
        }

        let screenshotURL = URL(fileURLWithPath: CommandLine.arguments[1])

        guard let source = CGImageSourceCreateWithURL(
            screenshotURL as CFURL,
            nil
        ), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            fputs("Unable to decode screenshot.\n", stderr)
            exit(2)
        }

        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](
            repeating: 0,
            count: height * bytesPerRow
        )

        let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let baseAddress = buffer.baseAddress,
                  let context = CGContext(
                      data: baseAddress,
                      width: width,
                      height: height,
                      bitsPerComponent: 8,
                      bytesPerRow: bytesPerRow,
                      space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else {
                return false
            }

            context.draw(
                image,
                in: CGRect(
                    x: 0,
                    y: 0,
                    width: CGFloat(width),
                    height: CGFloat(height)
                )
            )
            return true
        }

        guard rendered else {
            fputs("Unable to inspect screenshot pixels.\n", stderr)
            exit(2)
        }

        func isMostlyBlack(row: Int) -> Bool {
            var blackPixelCount = 0
            let rowOffset = row * bytesPerRow

            for column in 0..<width {
                let pixelOffset = rowOffset + column * bytesPerPixel
                let red = pixels[pixelOffset]
                let green = pixels[pixelOffset + 1]
                let blue = pixels[pixelOffset + 2]
                let alpha = pixels[pixelOffset + 3]

                if red <= 16, green <= 16, blue <= 16, alpha >= 240 {
                    blackPixelCount += 1
                }
            }

            return Double(blackPixelCount) / Double(width) >= 0.80
        }

        var firstEdgeBandHeight = 0
        for row in 0..<height {
            guard isMostlyBlack(row: row) else { break }
            firstEdgeBandHeight += 1
        }

        var secondEdgeBandHeight = 0
        for row in stride(from: height - 1, through: 0, by: -1) {
            guard isMostlyBlack(row: row) else { break }
            secondEdgeBandHeight += 1
        }

        let maximumAllowedBandHeight = max(
            8,
            Int(Double(height) * 0.08)
        )

        print(
            "Screenshot \(width)x\(height): edge black bands "
                + "\(firstEdgeBandHeight)px and \(secondEdgeBandHeight)px; "
                + "maximum allowed \(maximumAllowedBandHeight)px."
        )

        guard firstEdgeBandHeight <= maximumAllowedBandHeight,
              secondEdgeBandHeight <= maximumAllowedBandHeight else {
            fputs(
                "Screenshot rejected because an abnormal black edge band was detected.\n",
                stderr
            )
            exit(1)
        }
    }
}
