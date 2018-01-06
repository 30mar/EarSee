//
//  CameraVC
//  See
//
//  Created by Macbook on 12/21/17.
//  Copyright © 2017 Macbookodev. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision
enum FlashState{
    case on
    case off
}


class CameraVC: UIViewController {
    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var photoData: Data?
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    @IBOutlet weak var FlashButton: RoundedShadowButton!
    @IBOutlet weak var identificationLAbel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var roundedLabelView: RoundedShadowView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    var flashControlState: FlashState = .off
    var speechSynthesizer = AVSpeechSynthesizer()

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        spinner.isHidden = true
        //preview layer will fit inside the bounds of the camera
        previewLayer.frame = cameraView.bounds
       speechSynthesizer.delegate = self
        
    }
    override func viewWillAppear(_ animated: Bool) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCAmeraView))
        tap.numberOfTapsRequired = 1
        super.viewWillAppear(true)
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)
           // we  if the device can add a photo "not available on the simulator"
            if captureSession.canAddInput(input) == true{
                captureSession.addInput(input)
            }
            cameraOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(cameraOutput)==true{
                captureSession.addOutput(cameraOutput!)
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
               //this is to maintain aspect ratio
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
        }catch{
            debugPrint("error here \(error.localizedDescription)")
        }
    }
    @objc func didTapCAmeraView(){
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String:previewPixelType,kCVPixelBufferWidthKey as String:160,kCVPixelBufferHeightKey as String:160]
        
        if flashControlState == .off {
            settings.flashMode = .off
        }
        else {
            settings.flashMode = .on
        }
settings.previewPhotoFormat = previewFormat
        cameraOutput.capturePhoto(with: settings, delegate: self)
        
        
    }
    func resultsMethod(request:VNRequest,error:Error?){
        //handle changing the label text
         guard let results = request.results as? [VNClassificationObservation] else{
            return
        }
        for classification in results {
            if classification.confidence < 0.5 {
                let unknownObjectMessage = "Not sure what this is, please try again"
                self.identificationLAbel.text = unknownObjectMessage
                sythesizeSpeechFromString(fromString: unknownObjectMessage)
                self.confidenceLabel.text = ""
                break
            }
            else {
                //this is what it thinks it is as a string ex: remote controller
                let identification = classification.identifier
                let confidence = Int(classification.confidence * 100)
                self.identificationLAbel.text = identification
                self.confidenceLabel.text = "CONFIDENCE: \(confidence) %"
                sythesizeSpeechFromString(fromString: "This looks like a \(identification) and I'm \(confidence) percent sure.")
                break
            }
        }
    }
    // this function will speak any string we pass in
    func sythesizeSpeechFromString(fromString string:String){
        let speechUtternts = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speechUtternts)
        
    }
    @IBAction func flashWasPressed(_ sender: Any) {
        switch flashControlState {
        case .off:
            FlashButton.setTitle("FLASH ON", for: .normal)
            flashControlState = .on
        case .on:
            FlashButton.setTitle("FlASH OFf", for: .normal)
            flashControlState = .off
        }
    }
}
extension CameraVC: AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint("there is an errpr \(error.localizedDescription)")
        }
        else{
            photoData = photo.fileDataRepresentation()
            //here we try to pass it to vision machine learning model
            do{
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handel = VNImageRequestHandler(data: photoData!)
                try handel.perform([request])
            }catch{
                debugPrint("print the error is \(error.localizedDescription)")
            }
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
            
        }
    }
}

extension CameraVC: AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
         //code to do after finishing speech
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.stopAnimating()
        self.spinner.isHidden = true
    }
}
