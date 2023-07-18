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
    ///  1) In line-scan order, search for pixels with intensity > STAR_PIX_THRESH
    ///  2) If a pixel is found with that intensity, the flood-fill algorithm is run to determine
    ///    all pixels that are connected to the original high-intensity pixel. Then, we check
    ///    a) The size of the shape is reasonable (MIN_PIX_FOR_STAR <= numPixels <= MAX_PIX_FOR_STAR)
    ///    b) It "looks like" a star by seeing if the corners of the rectangular region containing the star are dark near the corners.
    ///    If they are dark, it means the brightness is in the center which is what a star looks like.
    ///  3) We then calculate the centroid of all the pixels and report that as a single `StarLocation`.
    ///  4) Continue searching for other stars in the image.
    func getStarLocations() -> [StarLocation] {
        let cgImg = self.cgImage!;
        let pixelData = cgImg.dataProvider?.data!
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        // data will have a 4th alpha-channel
        var stars: [StarLocation] = []
        
        let width = Int(self.size.width.rounded())
        let height = Int(self.size.height.rounded())
        
        var visited = Array(repeating: false, count: width * height)
        let MIN_PIX_FOR_STAR = 16
        let MAX_PIX_FOR_STAR = 1000
        let STAR_PIX_THRESH = 150
        // Skips to speed-up star searching
        let SKIP_STEP = 1 // 3
        
        let numChannels: Int
        let ignoreChan: Int?
        switch cgImg.alphaInfo {
            case .none:
                numChannels = 3
                ignoreChan = nil
            case .first, .premultipliedFirst, .noneSkipFirst:
                numChannels = 4
                ignoreChan = 0
            case .last, .premultipliedLast, .noneSkipLast:
                numChannels = 4
                ignoreChan = 3
            @unknown default:
                print("Unknown alpha info")
                numChannels = 3
                ignoreChan = nil
        }
        
        // TODO: SWITCH TO WIDHT AND HEIGHT SWITCH
//        for dataIdx in 0..<height*numChannels+12 {
//        for x in 0..<width {
//            let y = x
//            print("y: \(y), x: \(x)")
//            let dataIdx = pix2Pos(y: y, x: x, width: width, numChannels: numChannels)
//            print("idx: \(dataIdx). val: \(data[dataIdx]),")
//        }
        
        let starLock = NSLock()
        let startTime = Date()
    //        DispatchQueue.concurrentPerform(iterations: height/SKIP_STEP) { i in
//            let y = i * SKIP_STEP
        for y in stride(from: 0, to: height, by: SKIP_STEP) {
            for x in stride(from: 0, to: width, by: SKIP_STEP) {
                let visIdx = pix2Pos(y: y, x: x, width: width, numChannels: 1)
                if visited[visIdx] {
                    continue
                }
                let dataIdx = pix2Pos(y: y, x: x, width: width, numChannels:    numChannels)
                let dataVal = getAvgRGB(data: data, pos: dataIdx, numChannels: numChannels, ignoreChan: ignoreChan)
                if dataVal < STAR_PIX_THRESH {
                    visited[visIdx] = true
                    continue
                }
                starLock.lock()
                if visited[visIdx] {
                    // another thread already filled this, so just continue
                    starLock.unlock()
                    continue
                }
                
                visited[visIdx] = true
                var pixels: [(Int, Int)] = [(x, y)]
                var stack: [(Int, Int)] = [(x, y)]
                var sumRGB: UInt32 = 0

                // Run flood fill
                while let (x, y) = stack.popLast() {
                    for dx in -1...1 {
                        for dy in -1...1 {
                            let nx = x + dx
                            let ny = y + dy
                            let nxVisIdx = pix2Pos(y: ny, x: nx, width: width, numChannels: 1)
                            if nx >= 0 && nx < width && ny >= 0 && ny < height && !visited[nxVisIdx] {
                                visited[nxVisIdx] = true
                                let nxDataIdx = pix2Pos(y: ny, x: nx, width: width, numChannels: numChannels)
                                let nxDataVal = getAvgRGB(data: data, pos: nxDataIdx, numChannels: numChannels, ignoreChan: ignoreChan)
                                if nxDataVal > STAR_PIX_THRESH {
                                    pixels.append((nx, ny))
                                    stack.append((nx, ny))
                                    // TODO: handle overflow case better?
                                    sumRGB += UInt32(nxDataVal)
                                }
                            }
                        }
                    }
                }
                
                starLock.unlock()
                if pixels.count < MIN_PIX_FOR_STAR || pixels.count > MAX_PIX_FOR_STAR {
                    continue
                }
                
                // Validate the star looks like what we think a star should look like, then calculate the centroid of the filled area
                var sum = (0, 0)
                var minX = width
                var maxX = 0
                var minY = height
                var maxY = 0
                for ((u, v)) in pixels {
                    sum.0 += u
                    sum.1 += v
                    if u < minX {
                        minX = u
                    }
                    if u > maxX {
                        maxX = u
                    }

                    if v < minY {
                        minY = v
                    }
                    if v > maxY {
                        maxY = v
                    }
                }
                
                let centroid = (Double(sum.0) / Double(pixels.count), Double(sum.1) / Double(pixels.count))
                let avgStarVal = UInt8(sumRGB / UInt32(pixels.count))
                
                // check 4 corners are dark, otherwise this might be a cloud or some other bright object
                // blows out the bounding rectangle of the star by `expandWindow` pixels to give proper space for the image to dark
                let expandWindow = 30
                // The pixel value must drop this much for the image to be considered "dark"
                let darkDelta: UInt8 = 20
                minX = max(0, minX - expandWindow)
                maxX = min(width - 1, maxX + expandWindow)
                minY = max(0, minY - 5)
                maxY = min(height - 1, maxY + 5)
                var passed = true
                for (testU, testV) in [
                    (minX, minY),
                    (minX, maxY - 1),
                    (maxX - 1, minY),
                    (maxX - 1, maxY - 1)
                ] {
                    // avg the 2x2 area
                    let posData0 = getAvgRGB(data: data, pos: pix2Pos(y: testV, x: testU, width: width, numChannels: numChannels), numChannels: numChannels, ignoreChan: ignoreChan)
                    let posData1 = getAvgRGB(data: data, pos: pix2Pos(y: testV, x: testU + 1, width: width, numChannels: numChannels), numChannels: numChannels, ignoreChan: ignoreChan)
                    let posData2 = getAvgRGB(data: data, pos: pix2Pos(y: testV + 1, x: testU, width: width, numChannels: numChannels), numChannels: numChannels, ignoreChan: ignoreChan)
                    let posData3 = getAvgRGB(data: data, pos: pix2Pos(y: testV + 1, x: testU + 1, width: width, numChannels: numChannels), numChannels: numChannels, ignoreChan: ignoreChan)
                    let avg = (posData0 / 4 + posData1 / 4 + posData2 / 4 + posData3 / 4)
                    if avg > avgStarVal - darkDelta {
                        passed = false
                        break
                    }
                }
                if !passed {
                    print("Skipping possible star at \(centroid) because its shape did not look like a star")
                    continue
                }
                
                //let sum = pixels.reduce((0, 0)) { ($0.0 + $1.0, $0.1 + $1.1) }
                //let centroid = (Double(sum.0) / Double(pixels.count), Double(sum.1) / Double(pixels.count))
                stars.append(StarLocation(
                    u: centroid.0,
                    v: centroid.1
                ))
            }
        }
        let endTime = Date()
        let timeInterval: Double = endTime.timeIntervalSince(startTime)
        print("Total time for flood-fill: \(timeInterval) seconds")
        return stars
    }
}

// Goes from a pixel to an index in the flattened array.
func pix2Pos(y: Int, x: Int, width: Int, numChannels: Int) -> Int {
    return y * width * numChannels + x * numChannels
}

func getAvgRGB(data: UnsafePointer<UInt8>, pos: Int, numChannels: Int, ignoreChan: Int?) -> UInt8 {
    var sm: UInt16 = 0
    for (idx, i) in (pos..<pos + numChannels).enumerated() {
        if idx == ignoreChan {
            continue
        }
        sm += UInt16(data[i])
    }
    return UInt8(sm / 3)
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
