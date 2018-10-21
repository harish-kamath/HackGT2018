//
//  ViewController.swift
//  yolo-object-tracking
//
//  Created by Mikael Von Holst on 2017-12-19.
//  Copyright © 2017 Mikael Von Holst. All rights reserved.
//

import UIKit
import CoreML
import Vision
import AVFoundation
import Accelerate

class SSDViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate {
  var words: [String: Int] =  Dictionary(uniqueKeysWithValues: """
???
person
bicycle
car
motorcycle
airplane
bus
train
truck
boat
traffic light
fire hydrant
stop sign
parking meter
bench
bird
cat
dog
horse
sheep
cow
elephant
bear
zebra
giraffe
backpack
umbrella
handbag
tie
suitcase
frisbee
skis
snowboard
sports ball
kite
baseball bat
baseball glove
skateboard
surfboard
tennis racket
bottle
wine glass
cup
fork
knife
spoon
bowl
banana
apple
sandwich
orange
broccoli
carrot
hot dog
pizza
donut
cake
chair
couch
potted plant
bed
dining table
toilet
tv
laptop
mouse
remote
keyboard
cell phone
microwave
oven
toaster
sink
refrigerator
book
clock
vase
scissors
teddy bear
hair drier
toothbrush
""".split(separator: "\n").map{(String($0),0)})
  
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var frameLabel: UILabel!
  @IBOutlet weak var wrongLabel: UILabel!
    let semaphore = DispatchSemaphore(value: 1)
    var lastExecution = Date()
    var pred:[Prediction]!
    var screenHeight: Double?
    var screenWidth: Double?
    let ssdPostProcessor = SSDPostProcessor(numAnchors: 1917, numClasses: 90)
    var visionModel:VNCoreMLModel?

    
    private lazy var cameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.hd1280x720
        
        guard
            let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCamera)
            else { return session }
        session.addInput(input)
        return session
    }()

    let numBoxes = 100
    var boundingBoxes: [BoundingBox] = []
    let multiClass = true
  
  override func viewWillAppear(_ animated: Bool) {
    var worstWord = ""
    var worstVal = 0
    
    for (word,val) in words{
      if(val < worstVal){
        worstWord = word
        worstVal = val
      }
    }
    
    if(worstWord != ""){
      wrongLabel.text = "You need to practice: \(worstWord)"
      
    }
    else{
      wrongLabel.text = "Revisit a word."
    }
  }
    
    
    @objc func handleTap(sender: UITapGestureRecognizer? = nil) {
        let point = sender?.location(in: self.view)
        let x = point!.x
        let y = point!.y
        
        for p in pred {
            let z = p.finalPrediction
            let t = z.toCGRect(imgWidth: self.screenWidth!, imgHeight: self.screenWidth!, xOffset: 0, yOffset: (self.screenHeight! - self.screenWidth!)/2)
            let a = t.minX
            let b = t.maxX
            let c = t.minY
            let d = t.maxY
            //print(self.ssdPostProcessor.classNames![p.detectedClass])
            //print("X: \(x) Y: \(y)")
            //print("X: \(a) \(b) Y: \(c) \(d)")
            if((x >= a && x <= b) && (y >= c && y <= d)){
                print(self.ssdPostProcessor.classNames![p.detectedClass])
              let storyboard = UIStoryboard(name: "Main", bundle: nil)
              let controller = storyboard.instantiateViewController(withIdentifier: "labelChooser") as! ViewController
              controller.label = self.ssdPostProcessor.classNames![p.detectedClass]
              self.present(controller, animated: true, completion: {
                print("Done")
              })
                break
            }
        }
        
        // handling code
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap))
        tap.delegate = self // This is not required
        self.cameraView.addGestureRecognizer(tap)

        self.cameraView?.layer.addSublayer(self.cameraLayer)
      self.cameraView?.bringSubviewToFront(self.frameLabel)
        self.frameLabel.textAlignment = .left
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "MyQueue"))
        self.captureSession.addOutput(videoOutput)
        self.captureSession.startRunning()
        setupVision()

        setupBoxes()
        
        screenWidth = Double(view.frame.width)
        screenHeight = Double(view.frame.height)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cameraLayer.frame = cameraView.layer.bounds
    }
    
    func setupBoxes() {
        // Create shape layers for the bounding boxes.
        for _ in 0..<numBoxes {
            let box = BoundingBox()
            box.addToLayer(view.layer)
            self.boundingBoxes.append(box)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.cameraLayer.frame = self.cameraView?.bounds ?? .zero
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupVision() {
        guard let visionModel = try? VNCoreMLModel(for: ssd_mobilenet_feature_extractor().model)
            else { fatalError("Can't load VisionML model") }
        self.visionModel = visionModel
    }
    
    func processClassifications(for request: VNRequest, error: Error?) -> [Prediction]? {
        let thisExecution = Date()
        let executionTime = thisExecution.timeIntervalSince(lastExecution)
        let framesPerSecond:Double = 1/executionTime
        lastExecution = thisExecution
        guard let results = request.results as? [VNCoreMLFeatureValueObservation] else {
            return nil
        }
        guard results.count == 2 else {
            return nil
        }
        guard let boxPredictions = results[1].featureValue.multiArrayValue,
            let classPredictions = results[0].featureValue.multiArrayValue else {
            return nil
        }
        DispatchQueue.main.async {
            self.frameLabel.text = "FPS: \(framesPerSecond.format(f: ".3"))"
        }
        
        let predictions = self.ssdPostProcessor.postprocess(boxPredictions: boxPredictions, classPredictions: classPredictions)
        return predictions
    }

    func drawBoxes(predictions: [Prediction]) {
        pred = predictions
        for (index, prediction) in predictions.enumerated() {
            if let classNames = self.ssdPostProcessor.classNames {
                //print("Class: \(classNames[prediction.detectedClass])")
                
                let textColor: UIColor
              let c = classNames[prediction.detectedClass]
              let textLabel = words[c] ?? 0 < 3 ? String(format: "%@", c) : ""
                
                textColor = UIColor.white
                let rect = prediction.finalPrediction.toCGRect(imgWidth: self.screenWidth!, imgHeight: self.screenWidth!, xOffset: 0, yOffset: (self.screenHeight! - self.screenWidth!)/2)
                self.boundingBoxes[index].show(frame: rect,
                                               label: textLabel,
                                               color: words[c] ?? 0 < 3 ? UIColor.black : UIColor.green, textColor: textColor)
            }
        }
        for index in predictions.count..<self.numBoxes {
            self.boundingBoxes[index].hide()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        guard let visionModel = self.visionModel else {
            return
        }

        var requestOptions:[VNImageOption : Any] = [:]
      if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics:cameraIntrinsicData]
        }
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(EXIFOrientation.rightTop.rawValue))

        let trackingRequest = VNCoreMLRequest(model: visionModel) { (request, error) in
            guard let predictions = self.processClassifications(for: request, error: error) else { return }
            DispatchQueue.main.async {
                self.drawBoxes(predictions: predictions)
            }
            self.semaphore.signal()
        }
        trackingRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop

        
        self.semaphore.wait()
        do {
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation!, options: requestOptions)
            try imageRequestHandler.perform([trackingRequest])
        } catch {
            print(error)
            self.semaphore.signal()
            
        }
    }

    func sigmoid(_ val:Double) -> Double {
         return 1.0/(1.0 + exp(-val))
    }

    func softmax(_ values:[Double]) -> [Double] {
        if values.count == 1 { return [1.0]}
        guard let maxValue = values.max() else {
            fatalError("Softmax error")
        }
        let expValues = values.map { exp($0 - maxValue)}
        let expSum = expValues.reduce(0, +)
        return expValues.map({$0/expSum})
    }
    
    public static func softmax2(_ x: [Double]) -> [Double] {
        var x:[Float] = x.flatMap{Float($0)}
        let len = vDSP_Length(x.count)
        
        // Find the maximum value in the input array.
        var max: Float = 0
        vDSP_maxv(x, 1, &max, len)
        
        // Subtract the maximum from all the elements in the array.
        // Now the highest value in the array is 0.
        max = -max
        vDSP_vsadd(x, 1, &max, &x, 1, len)
        
        // Exponentiate all the elements in the array.
        var count = Int32(x.count)
        vvexpf(&x, x, &count)
        
        // Compute the sum of all exponentiated values.
        var sum: Float = 0
        vDSP_sve(x, 1, &sum, len)
        
        // Divide each element by the sum. This normalizes the array contents
        // so that they all add up to 1.
        vDSP_vsdiv(x, 1, &sum, &x, 1, len)
        
        let y:[Double] = x.flatMap{Double($0)}
        return y
    }
    
    enum EXIFOrientation : Int32 {
        case topLeft = 1
        case topRight
        case bottomRight
        case bottomLeft
        case leftTop
        case rightTop
        case rightBottom
        case leftBottom
        
        var isReflect:Bool {
            switch self {
            case .topLeft,.bottomRight,.rightTop,.leftBottom: return false
            default: return true
            }
        }
    }
    
    func compensatingEXIFOrientation(deviceOrientation:UIDeviceOrientation) -> EXIFOrientation
    {
        switch (deviceOrientation) {
        case (.landscapeRight): return .bottomRight
        case (.landscapeLeft): return .topLeft
        case (.portrait): return .rightTop
        case (.portraitUpsideDown): return .leftBottom
            
        case (.faceUp): return .rightTop
        case (.faceDown): return .rightTop
        case (_): fallthrough
        default:
            NSLog("Called in unrecognized orientation")
            return .rightTop
        }
    }
}
