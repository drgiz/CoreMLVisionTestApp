//
//  ViewController.swift
//  CoreMLVisionTestApp
//
//  Created by Svyatoslav Bykov on 15.08.17.
//  Copyright © 2017 Svyatoslav Bykov. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var imageAgeGuessLabel: UILabel!
    @IBAction func getImageButton(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .savedPhotosAlbum
        present(picker, animated: true)
    }
    
    var inputImage: CIImage!
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true)
        imagePreview.image = nil
        imageAgeGuessLabel.text = "Analyzing Image…"
        guard let uiImage = info[UIImagePickerControllerOriginalImage] as? UIImage
            else { fatalError("no image from image picker") }
        let newImage = uiImage
        guard let ciImage = CIImage(image: newImage)
            else { fatalError("can't create CIImage from UIImage") }
        let orientation = CGImagePropertyOrientation(newImage.imageOrientation)
        inputImage = ciImage.applyingOrientation(Int32(orientation.rawValue))
        imagePreview.image = newImage
        let handler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try handler.perform([classificationRequest])
        } catch {
            print(error)
        }
    }
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: Ages().model)
            return VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
        } catch {
            fatalError("can't load Vision ML model: \(error)")
        }
    }()
    
    func handleClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation]
            else { fatalError("unexpected result type from VNCoreMLRequest") }
        guard let best = observations.first
            else { fatalError("can't get best result") }
        
        DispatchQueue.main.async {
            self.imageAgeGuessLabel.text = "Age: \"\(best.identifier)\" Confidence: \(best.confidence*100)%"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImageOrientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}
