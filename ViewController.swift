//
//  ViewController.swift
//  Modified on 2018/02/20.
//
import UIKit
import AVFoundation
import CoreML

class ViewController: UIViewController, FrameExtractorDelegate {
    let newHeight:CGFloat = 224.0
    let newWidth:CGFloat = 224.0

    var frameExtractor: FrameExtractor!
    let model = Resnet50()

    var prediction:Resnet50Output?
    var predictionReady = false
    var flag = 0

    var maxProb:Double = 0.0
    var labelWithMaxProb = "0"
    
    var secondMaxProb:Double = 0.0
    var labelWithSecondMaxProb = "0"

    var sortedPredictions: [(key: String, value: Double)] = []
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var resultProbLabel: UILabel!
    /*@IBAction func flipButton(_ sender: UIButton) {
     frameExtractor.flipCamera()
     }*/


    override func viewDidLoad() {
        super.viewDidLoad()
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self

    }

    func captured(image: CMSampleBuffer) {
        if let imageBuffer = CMSampleBufferGetImageBuffer(image) {
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext(options: nil)
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(cgImage: cgImage)
                }
                DispatchQueue.global(qos: .userInteractive).async {
                    let newImageBuffer = self.newPixelBufferFrom(cgImage: cgImage)
                    guard let prediction = try? self.model.prediction(image: newImageBuffer!) else {
                        fatalError("Unexpected runtime error.")
                    }
                    let dict = prediction.classLabelProbs
                    
                    if !dict.isEmpty {
                        self.sortedPredictions = dict.sorted{ $0.value > $1.value }
                        if self.sortedPredictions.count == 1 {
                            self.labelWithMaxProb = self.sortedPredictions.first!.key
                            self.maxProb = self.sortedPredictions.first!.value
                        }
                        else {
                            self.labelWithMaxProb = self.sortedPredictions.first!.key
                            self.maxProb = self.sortedPredictions.first!.value
                            
                            self.labelWithSecondMaxProb = self.sortedPredictions[1].key
                            self.secondMaxProb = self.sortedPredictions[1].value
                        }
                    }
                    
                    
                    DispatchQueue.main.async {
                        self.resultLabel.text = self.sortedPredictions.count == 1
                            ? self.labelWithMaxProb : "1. \(self.labelWithMaxProb)\n 2. \(self.labelWithSecondMaxProb)"
                        
                        self.resultProbLabel.text = self.sortedPredictions.count == 1
                            ? String(format:"%.4f%", self.maxProb) : String(format:"%.4f%", self.maxProb) + "\n" + String(format:"%.4f%", self.secondMaxProb) }
                    
                }
            }
        }
        self.flag = self.flag + 1
    }

    func newPixelBufferFrom(cgImage:CGImage) -> CVPixelBuffer?{
        let options:[String: Any] = [kCVPixelBufferCGImageCompatibilityKey as String: true, kCVPixelBufferCGBitmapContextCompatibilityKey as String: true]
        var pxbuffer:CVPixelBuffer?
        let frameWidth = newWidth
        let frameHeight = newHeight

        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(frameWidth), Int(frameHeight), kCVPixelFormatType_32ARGB, options as CFDictionary?, &pxbuffer)
        assert(status == kCVReturnSuccess && pxbuffer != nil, "newPixelBuffer failed")
        
        CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata, width: Int(frameWidth), height: Int(frameHeight), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        assert(context != nil, "context is nil")

        context!.concatenate(CGAffineTransform.identity)
        context!.draw(cgImage, in: CGRect(x: 0, y: 0, width: frameWidth, height: frameHeight))
        CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pxbuffer
    }

}
