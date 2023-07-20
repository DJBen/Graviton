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
//        let sConv = Date()
//        let kernel: [CGFloat] = [0.111, 0.111, 0.111, 0.111, 0.111, 0.111, 0.111, 0.111, 0.111]
//        let img = applyConvFilter(to: self, with: kernel)!
//        let eConv = Date()
//        let eConvDt = eConv.timeIntervalSince(sConv)
//        print("Conv took \(eConvDt)")
        
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
//        let STAR_PIX_THRESH = 150
        // Skips to speed-up star searching
        let SKIP_STEP = 1 // 3
        
        let numChannels: Int
        switch cgImg.alphaInfo {
            case .none:
                numChannels = 3
            case .first, .premultipliedFirst, .noneSkipFirst, .last, .premultipliedLast, .noneSkipLast:
                numChannels = 4
            case .alphaOnly:
                fatalError("Cannot handle an image with alpha only")
            @unknown default:
                print("Unknown alpha info")
                numChannels = 3
        }
        
        let rng = SeededGenerator(seed: 7)
        var pixSamples: [UInt8] = []
        let numSamples = 1000
        for _ in 0..<numSamples {
            let y = rng.nextInt(upper: height)
            let x = rng.nextInt(upper: width)
            let dataIdx = pix2Pos(y: y, x: x, width: width, numChannels: numChannels)
            let dataVal = getAvgRGB(data: data, pos: dataIdx, numChannels: numChannels)
            pixSamples.append(dataVal)
        }
        pixSamples.sort()
        let INIT_STAR_PIX_THRESH: UInt8 = pixSamples[numSamples/2] + 30
        let STAR_PIX_DELTA: UInt8 = 20
        
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
                let dataIdx = pix2Pos(y: y, x: x, width: width, numChannels: numChannels)
                let dataVal = getAvgRGB(data: data, pos: dataIdx, numChannels: numChannels)
                visited[visIdx] = true
                if dataVal < INIT_STAR_PIX_THRESH {
                    continue
                }
                // We have a candidate star. To make sure, see if the previous pixels have a sufficient delta
                var starPixThresh = INIT_STAR_PIX_THRESH
                let pixDelta = 10
                if x >= pixDelta {
                    let prevDataIdx = pix2Pos(y: y, x: x - pixDelta, width: width, numChannels: numChannels)
                    let prevDataVal = getAvgRGB(data: data, pos: prevDataIdx, numChannels: numChannels)
                    if dataVal < prevDataVal + STAR_PIX_DELTA {
                        continue // delta too small
                    }
                    // Modify the pixel threshold
                    starPixThresh = max(starPixThresh, prevDataVal / 2 + dataVal / 2)
                }
                if y >= pixDelta {
                    let prevDataIdx = pix2Pos(y: y - pixDelta, x: x, width: width, numChannels: numChannels)
                    let prevDataVal = getAvgRGB(data: data, pos: prevDataIdx, numChannels: numChannels)
                    if dataVal < prevDataVal + STAR_PIX_DELTA {
                        continue // delta too small
                    }
                    // Modify the pixel threshold
                    starPixThresh = max(starPixThresh, prevDataVal / 2 + dataVal / 2)
                }
                
                // TODO: determine threading
//                starLock.lock()
//                if visited[visIdx] {
//                    // another thread already filled this, so just continue
//                    starLock.unlock()
//                    continue
//                }
                
                visited[visIdx] = true
                var pixels: [(Int, Int)] = [(x, y)]
                var stack: [(Int, Int)] = [(x, y)]
                var sumRGB: UInt32 = 0

                // Run flood fill
                while let (x, y) = stack.popLast() {
                    if pixels.count > MAX_PIX_FOR_STAR {
                        // We do not have a star, this probably just noise. Exit now to avoid filling
                        // too much of the image.
                        break
                    }
                    for dx in -5...5 {
                        for dy in -5...5 {
                            let nx = x + dx
                            let ny = y + dy
                            let nxVisIdx = pix2Pos(y: ny, x: nx, width: width, numChannels: 1)
                            if nx >= 0 && nx < width && ny >= 0 && ny < height && !visited[nxVisIdx] {
                                visited[nxVisIdx] = true
                                let nxDataIdx = pix2Pos(y: ny, x: nx, width: width, numChannels: numChannels)
                                let nxDataVal = getAvgRGB(data: data, pos: nxDataIdx, numChannels: numChannels)
                                if nxDataVal > starPixThresh {
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
                if pixels.count < MIN_PIX_FOR_STAR {
//                    print("Flooded too little: \(pixels.count) at (\(x),\(y))")
                    continue
                }
                if pixels.count > MAX_PIX_FOR_STAR {
//                    print("Flooded too much: \(pixels.count) at (\(x),\(y))")
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
                let expandWindow = 10
                // The pixel value must drop this much for the image to be considered "dark"
                let darkDelta: UInt8 = 10
                minX = max(0, minX - expandWindow)
                maxX = min(width - 1, maxX + expandWindow)
                minY = max(0, minY - expandWindow)
                maxY = min(height - 1, maxY + expandWindow)
                var passed = true
                for (testU, testV) in [
                    (minX, minY),
                    (minX, maxY - 1),
                    (maxX - 1, minY),
                    (maxX - 1, maxY - 1)
                ] {
                    // avg the 2x2 area
                    let posData0 = getAvgRGB(data: data, pos: pix2Pos(y: testV, x: testU, width: width, numChannels: numChannels), numChannels: numChannels)
                    let posData1 = getAvgRGB(data: data, pos: pix2Pos(y: testV, x: testU + 1, width: width, numChannels: numChannels), numChannels: numChannels)
                    let posData2 = getAvgRGB(data: data, pos: pix2Pos(y: testV + 1, x: testU, width: width, numChannels: numChannels), numChannels: numChannels)
                    let posData3 = getAvgRGB(data: data, pos: pix2Pos(y: testV + 1, x: testU + 1, width: width, numChannels: numChannels), numChannels: numChannels)
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

// DOES NOT WORK, SOME WEIRD TRANSLATE
//func applyConvFilter(to image: UIImage, with kernel: [CGFloat]) -> UIImage? {
//    guard let ciImage = CIImage(image: image) else { return nil }
//
//    let kernelMatrix = CIVector(values: kernel, count: 9)
//
//    // Remove alpha channel from the original image
//    guard let rgbImage = CIFilter(name: "CIColorMatrix", parameters: [
//        "inputImage": ciImage,
//        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0)
//    ])?.outputImage else { return nil }
//
//    // Create convolution filter
//    let convolutionFilter = CIFilter(name: "CIConvolution3X3", parameters: [
//        kCIInputImageKey: rgbImage,
//        "inputWeights": CIVector(values: kernel, count: 9),
//        "inputBias": 0
//    ])
//
//    // Apply convolution filter
//    guard let convolutedCIImage = convolutionFilter?.outputImage else { return nil }
//
//    let context = CIContext(options: nil)
//    guard let cgImage = context.createCGImage(convolutedCIImage, from: convolutedCIImage.extent) else { return nil }
//
//    return UIImage(cgImage: cgImage)
//}

// Goes from a pixel to an index in the flattened array.
func pix2Pos(y: Int, x: Int, width: Int, numChannels: Int) -> Int {
    return y * width * numChannels + x * numChannels
}

func getAvgRGB(data: UnsafePointer<UInt8>, pos: Int, numChannels: Int) -> UInt8 {
    let d1 = UInt16(data[pos])
    let d2 = UInt16(data[pos + 1])
    let d3 = UInt16(data[pos + 2])
    return UInt8((d1 + d2 + d3) / 3)
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
