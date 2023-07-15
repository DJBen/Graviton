//
//  File.swift
//  
//
//  Created by Jatin Mathur on 7/11/23.
//

import Foundation
import UIKit

struct StarLocation: Hashable {
    // centroid of the detected star
    let u: Double
    let v: Double
    
    init(u: Double, v: Double) {
        self.u = u
        self.v = v
    }
}

func getStarLocations(img: UIImage) -> [StarLocation] {
    return img.getStarLocations()
}

extension UIImage {
    ///  Calculates the location of stars in an image by:
    ///  1) Convert to grayscale
    ///  2) Searching for stars. Algorithm overview:
    ///     a) In line-scan order, search for pixels with intensity > STAR_PIX_THRESH (on a 0-255 color value range)
    ///     b) If a pixel is found with that intensity, the flood-fill algorithm is run to determine
    ///         all pixels that are connected to the original high-intensity pixel. Assuming the
    ///         size of the shape is reasonable (MIN_PIX_FOR_STAR <= numPixels <= MAX_PIX_FOR_STAR),
    ///         we then calculate the centroid of all the pixels and report that as a single `StarLocation`.
    ///     c) Continue searching for other stars in the image.
    func getStarLocations() -> [StarLocation] {
        let s = Date()
        let image = convertToGrayscale(self)!
        let e = Date()
        let dtGs = e.timeIntervalSince(s)
        print("Time spent converting to grayscale: \(dtGs)")
        let cgImg = image.cgImage!;
        let pixelData = cgImg.dataProvider?.data!
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        // Handle a variety of input images by detecting if Alpha-channel is present and
        // where the value of the grayscale image is. For example, if the Alpha channel
        // is present and is the first value (ARGB), we need grayscale_idx=1 to actually
        // get a meaningful value. We ignore Alpha for reading back the grayscale value
        // and determining star intensity.
        var hasAlpha: Bool = false;
        var grayscale_idx: Int = 0;
        switch cgImg.alphaInfo {
            case .none:
                break
            case .premultipliedLast, .last:
                hasAlpha = true;
            case .premultipliedFirst, .first:
                hasAlpha = true;
                grayscale_idx = 1
            case .noneSkipFirst:
                grayscale_idx = 1;
            case .noneSkipLast:
                break
            default:
                print("Could not determine alpha?")
                return [];
        }
        
        let items = hasAlpha ? 4 : 3
        
        var stars: [StarLocation] = []
        
        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        var visited = Array(repeating: false, count: width * height)
        let STAR_PIX_THRESH = 230
        let MIN_PIX_FOR_STAR = 6
        let MAX_PIX_FOR_STAR = 1000
        // Skips to speed-up star searching
        let SKIP_STEP = 3
        
        let startTime = Date()
        for y in stride(from: 0, to: height, by: SKIP_STEP) {
            for x in stride(from: 0, to: width, by: SKIP_STEP) {
                let posVis = pix2Pos(y: y, x: x, width: width, idx_value: 0, num_channels: 1)
                if visited[posVis] {
                    continue
                }
                visited[posVis] = true
                let posData = pix2Pos(y: y, x: x, width: width, idx_value: grayscale_idx, num_channels: items)
                let dataVal = data[posData]
                if dataVal > STAR_PIX_THRESH {
                    var pixels: [(Int, Int)] = [(x, y)]
                    var stack: [(Int, Int)] = [(x, y)]

                    // Run flood fill
                    while let (x, y) = stack.popLast() {
                        for dx in [-1, 1] {
                            for dy in [-1, 1] {
                                let nx = x + dx
                                let ny = y + dy
                                let nxPosData = pix2Pos(y: ny, x: nx, width: width, idx_value: grayscale_idx, num_channels: items)
                                let nxPosVis = pix2Pos(y: ny, x: nx, width: width, idx_value: 0, num_channels: 1)
                                if nx >= 0 && nx < width && ny >= 0 && ny < height && !visited[nxPosVis] {
                                    visited[nxPosVis] = true
                                    if data[nxPosData] > STAR_PIX_THRESH {
                                        pixels.append((nx, ny))
                                        stack.append((nx, ny))
                                    }
                                }
                            }
                        }
                        // bail early if we have filled too many regions
                        if stack.count > MAX_PIX_FOR_STAR {
                            break
                        }
                    }

                    if pixels.count < MIN_PIX_FOR_STAR || pixels.count > MAX_PIX_FOR_STAR {
                        continue
                    }
                    // Calculate the centroid of the filled area
                    let sum = pixels.reduce((0, 0)) { ($0.0 + $1.0, $0.1 + $1.1) }
                    let centroid = (Double(sum.0) / Double(pixels.count), Double(sum.1) / Double(pixels.count))
                    stars.append(StarLocation(
                        u: centroid.0,
                        v: centroid.1
                    ))
                }
            }
        }
        let endTime = Date()
        let timeInterval: Double = endTime.timeIntervalSince(startTime)
        print("Total time for flood-fill: \(timeInterval) seconds")
        return stars
    }
}

// Goes from a pixel to an index in the flattened array.
func pix2Pos(y: Int, x: Int, width: Int, idx_value: Int, num_channels: Int) -> Int {
    return y * width * num_channels + x * num_channels + idx_value
}

func convertToGrayscale(_ image: UIImage) -> UIImage? {
    let context = CIContext(options: nil)
    if let filter = CIFilter(name: "CIPhotoEffectMono") {
        filter.setValue(CIImage(image: image), forKey: kCIInputImageKey)
        if let output = filter.outputImage,
            let cgImage = context.createCGImage(output, from: output.extent) {
            return UIImage(cgImage: cgImage)
        }
    }
    return nil
}
