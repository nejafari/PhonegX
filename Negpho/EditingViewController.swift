//
//  EditingViewController.swift
//  Negpho
//
//  Created by Negar Jafari on 11/22/19.
//  Copyright © 2019 Negar Jafari. All rights reserved.
//

import UIKit
import CoreImage
import Photos
import Combine
import CoreImage.CIFilterBuiltins

class EditingViewController: UIViewController {
    
    @IBOutlet weak var renderView: UIView!
    @IBOutlet weak var canvasView: CanvasView!
    override func viewDidLoad() {
        super.viewDidLoad()
        image.map { img in myImage.image = img }
        lightsDataSource.editingViewController = self
    }
    
    @IBAction func CancelButton(_ sender: Any) {
        guard let nav = navigationController else { return }
        nav.popViewController(animated: true)
    }
    @IBAction func clearButton(_ sender: Any) {
        undoManager?.undo()
    }
    
    var imageContrast: Int = 1 {
        didSet {
            guard imageContrast != oldValue else { return }
        }
    }
    
    let brighnessQueue = DispatchQueue(label: "", qos: .userInitiated, attributes: .concurrent)
    
    func adjustContrast(image: CIImage, level: Float) {
        brighnessQueue.async {
            guard let filter = CIFilter(name: "CIColorControls") else { fatalError("Unable to create filter.") }
            filter.setValue(NSNumber(value: level), forKey: "inputContrast")
            let rawimgData = image
            filter.setValue(rawimgData, forKey: "inputImage")
            let outpuImage = filter.value(forKey: "outputImage")
            DispatchQueue.main.async {
                self.myImage.image = UIImage(ciImage: outpuImage as! CIImage)
            }
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        
        func renderCompositeImage() -> UIImage? {
            UIGraphicsBeginImageContext(renderView.bounds.size)
            //[UIImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
            renderView.layer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image
        }
        
        guard myImage.image != nil else {
            let alert = UIAlertController(title: "No image", message: "", preferredStyle: .alert)
            let verifiedAlert = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(verifiedAlert)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        guard let image = renderCompositeImage() else {
            let alert = UIAlertController(title: "Error creating image", message: "", preferredStyle: .alert)
            let verifiedAlert = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(verifiedAlert)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                return
            }
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: image.jpegData(compressionQuality: 80)!, options: nil)
            }) { [weak self] success, error in
                guard let self = self else { return }
                if success {
                    let ac = UIAlertController(title: "Saved!", message: "Your image has been saved to your photos.", preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    DispatchQueue.main.async { self.present(ac, animated: true) }
                } else {
                    let message = error.map { $0.localizedDescription } ?? "Unknown"
                    let ac = UIAlertController(title: "Save error", message: message, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    DispatchQueue.main.async { self.present(ac, animated: true) }
                }
            }
        }
    }
    
    func addImage(_ image: UIImage) {
        self.image = image
        self.originalImage = image
    }
    
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            myImage.image = image
        }
    }
    var originalImage: UIImage?
    @IBOutlet var myImage: UIImageView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var toolbar: UIToolbar!
    var filters: [(UIImage) -> UIImage] = []
    var context = CIContext();
    var outputImage = CIImage();
    var newUIImage = UIImage();
    
    var stackedProcessor = Processor()// {
//        didSet {
//            guard let original = self.originalImage else { return }
//            self.image = try? stackedProcessor.process(image: original)
//        }
//    }
    
    lazy var processesDataSource: ProcessDataSource = {
        return ProcessDataSource { [weak self] process in
            guard let self = self else { return }
            guard let original = self.originalImage else { return }
            
            self.stackedProcessor.push(process: process)
            self.image = try? self.stackedProcessor.process(image: original)
//            guard let original = self.originalImage else { return }
//            self.image = process(original)
        }
    }()
    
    let lightsDataSource = LightsDataSource()
    
    var showsFilterCollectionView: Bool = false {
        didSet { collectionView.isHidden = !showsFilterCollectionView }
    }
    
    var showsLightCollectionView: Bool = false {
        didSet { collectionView.isHidden = !showsLightCollectionView }
    }
}

extension EditingViewController {
    
    @IBAction func filterButton(_ sender: UIBarButtonItem) {
        showsFilterCollectionView.toggle()
        collectionView.dataSource = showsFilterCollectionView ? processesDataSource : nil
        collectionView.delegate = showsFilterCollectionView ? processesDataSource : nil
    }
    
    @IBAction func handleCrop(_ sender: UIBarButtonItem) {
        showsFilterCollectionView = false
        myImage.transform = myImage.transform.concatenating(CGAffineTransform(rotationAngle: CGFloat(Double.pi/2)));
    }
    
    @IBAction func lightButton(_ sender: UIBarButtonItem) {
        showsLightCollectionView.toggle()
        collectionView.dataSource = showsLightCollectionView ? lightsDataSource : nil
        collectionView.delegate = showsLightCollectionView ? lightsDataSource : nil
        
    }
    
    @IBAction func handleColor(_ sender: UIBarButtonItem) {
        canvasView.isUserInteractionEnabled.toggle()
    }
    
    @IBAction func handleSliderValue(_ sender: UISlider!) {
    }
}

class ProcessDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    typealias Process = (UIImage) -> UIImage
    var processes: [ImageProcess] = []
    let callback: (ImageProcess) -> Void
    
    init(callback: @escaping (ImageProcess) -> Void) {
        self.callback = callback
        
        processes.append(Sepia())
        processes.append(Noir())
        processes.append(Chrome())
        
        /*
        func SepiaProcess(image: UIImage) throws -> UIImage {
            guard let cgimage = image.cgImage else { return image }
            let ciimage = CIImage(cgImage: cgimage)
            
            guard let filter = CIFilter(name: "CISepiaTone") else { fatalError("Unable to create filter.") }
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            filter.setValue(0.8, forKey: kCIInputIntensityKey)
            
            guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
            let newImage = UIImage(ciImage: output)
            return newImage
        }
        
        func NoirProcess(image: UIImage) throws -> UIImage {
            guard let cgimage = image.cgImage else { return image }
            let ciimage = CIImage(cgImage: cgimage)
            
            guard let filter = CIFilter(name: "CIPhotoEffectNoir") else { fatalError("Unable to create filter.") }
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            
            guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
            guard let cgImage = output.createCGImage() else { return image }
            let newImage = UIImage(cgImage: cgImage)
            return newImage
        }
        
        func FaidProcess(image: UIImage) throws -> UIImage {
            guard let cgimage = image.cgImage else { return image }
            let ciimage = CIImage(cgImage: cgimage)
            
            guard let filter = CIFilter(name: "CIPhotoEffectFade") else { fatalError("Unable to create filter.") }
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            
            guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
            guard let cgImage = output.createCGImage() else { return image }
            let newImage = UIImage(cgImage: cgImage)
            return newImage
        }
        
        func CCProcess(image: UIImage) throws -> UIImage {
            guard let cgimage = image.cgImage else { return image }
            let ciimage = CIImage(cgImage: cgimage)
            
            guard let filter = CIFilter(name: "CIColorControls") else { fatalError("Unable to create filter.") }
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            filter.setValue(0.8, forKey: kCIInputContrastKey)
            
            guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
            guard let cgImage = output.createCGImage() else { return image }
            let newImage = UIImage(cgImage: cgImage)
            return newImage
        }
        
        func ChromProcess(image: UIImage) throws -> UIImage {
            guard let cgimage = image.cgImage else { return image }
            let ciimage = CIImage(cgImage: cgimage)
            
            guard let filter = CIFilter(name: "CIPhotoEffectChrome") else { fatalError("Unable to create filter.") }
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            
            guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
            guard let cgImage = output.createCGImage() else { return image }
            let newImage = UIImage(cgImage: cgImage)
            return newImage
        }
        
        func InstantProcess(image: UIImage) throws -> UIImage {
            guard let cgimage = image.cgImage else { return image }
            let ciimage = CIImage(cgImage: cgimage)
            
            guard let filter = CIFilter(name: "CIPhotoEffectInstant") else { fatalError("Unable to create filter.") }
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            
            guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
            guard let cgImage = output.createCGImage() else { return image }
            let newImage = UIImage(cgImage: cgImage)
            return newImage
        }
        
        func BlueProcess(image: UIImage) throws -> UIImage {
            guard let cgimage = image.cgImage else { return image }
            let ciimage = CIImage(cgImage: cgimage)
            
            guard let filter = CIFilter(name: "CIPhotoEffectProcess") else { fatalError("Unable to create filter.") }
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            
            guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
            guard let cgImage = output.createCGImage() else { return image }
            let newImage = UIImage(cgImage: cgImage)
            return newImage
        }
        
        func GammaProcess(image: UIImage) throws -> UIImage {
            guard let cgimage = image.cgImage else { return image }
            let ciimage = CIImage(cgImage: cgimage)
            
            guard let filter = CIFilter(name: "CIGammaAdjust") else { fatalError("Unable to create filter.") }
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            
            guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
            guard let cgImage = output.createCGImage() else { return image }
            let newImage = UIImage(cgImage: cgImage)
            return newImage
        }
        
        func MonoProcess(image: UIImage) throws -> UIImage {
            guard let cgimage = image.cgImage else { return image }
            let ciimage = CIImage(cgImage: cgimage)
            
            guard let filter = CIFilter(name: "CIPhotoEffectMono") else { fatalError("Unable to create filter.") }
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            
            guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
            guard let cgImage = output.createCGImage() else { return image }
            let newImage = UIImage(cgImage: cgImage)
            return newImage
        }
        
        func MatrixProcess(image: UIImage) throws -> UIImage {
            guard let cgimage = image.cgImage else { return image }
            let ciimage = CIImage(cgImage: cgimage)
            
            guard let filter = CIFilter(name: "CIColorMatrix") else { fatalError("Unable to create filter.") }
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            
            guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
            guard let cgImage = output.createCGImage() else { return image }
            let newImage = UIImage(cgImage: cgImage)
            return newImage
        }
        
        func ExposureProcess(image: UIImage) throws -> UIImage {
            guard let cgimage = image.cgImage else { return image }
            let ciimage = CIImage(cgImage: cgimage)
            
            guard let filter = CIFilter(name: "CIExposureAdjust") else { fatalError("Unable to create filter.") }
            filter.setValue(ciimage, forKey: kCIInputImageKey)
            filter.setValue(0.8, forKey: kCIInputEVKey)
            
            guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
            guard let cgImage = output.createCGImage() else { return image }
            let newImage = UIImage(cgImage: cgImage)
            return newImage
        }
        */
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return processes.count
    }
    
    //hereeeeeeeeeeeeeeeeee
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! filtersCollectionViewCell
        let imageProcessor = processes[indexPath.item]
        
        if let image = cell.imageView.image {
            
            cell.imageView.image = try? imageProcessor.process(image: image)
        
        }
        cell.layer.cornerRadius = 12
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageProcess = processes[indexPath.item]
//        let filter: (UIImage) -> UIImage = { image in
//            guard let updated = try? imageProcess.process(image: image) else { return image }
//            return updated
//        }
        callback(imageProcess)
    }
}

class LightsDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    weak var editingViewController: EditingViewController?
    
    private var sliderObserver: AnyCancellable?
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SliderCell", for: indexPath) as! SliderCell
        sliderObserver = cell.slider.publisher(for: \.value)
            .removeDuplicates()
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak editingViewController] value in
                guard let vc = editingViewController, let image = vc.image?.cgImage else {
                    return
                }
                vc.adjustContrast(image: CIImage(cgImage: image), level: value)
            })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // do nothing, just return
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width, height: 44)
    }
}

class SliderCell: UICollectionViewCell {
    @IBOutlet var slider: UISlider!
}

extension CIImage {
    func createCGImage() -> CGImage? {
        let context = CIContext()
        return context.createCGImage(self, from: self.extent)
    }
}



//        let exposure: (UIImage) -> UIImage = { image in
//                   guard let cgimage = image.cgImage else { return image }
//                   let ciimage = CIImage(cgImage: cgimage)
//
//                   guard let filter = CIFilter(name: "CIExposureAdjust") else { fatalError("Unable to create filter.") }
//                   filter.setValue(ciimage, forKey: kCIInputImageKey)
//                   filter.setValue(0.8, forKey: kCIInputEVKey)
//
//                   guard let output = filter.value(forKey: kCIOutputImageKey) as? CIImage else { fatalError() }
//                   guard let cgImage = output.createCGImage() else { return image }
//                   let newImage = UIImage(cgImage: cgImage)
//                   return newImage
//               }
//               processes.append(exposure)
