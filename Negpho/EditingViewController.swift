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
    
    let contrastQueue = DispatchQueue(label: "", qos: .userInitiated, attributes: .concurrent)
    func adjustContrast(image: CIImage, level: Float) {
        guard let image = self.image else { return }
        let contrast = Contrast(level: level, intensity: 0.3)
        stackedProcessor.replaceLast(with: contrast)
        
        contrastQueue.async {
            let newImage = try? self.stackedProcessor.process(image: image)
            DispatchQueue.main.async {
                self.myImage.image = newImage
            }
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        func renderCompositeImage() -> UIImage? {
            UIGraphicsBeginImageContext(renderView.bounds.size)
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
    var stackedProcessor = Processor()
    
    lazy var processesDataSource: ProcessDataSource = {
        return ProcessDataSource { [weak self] process in
            DispatchQueue(label: "processor", qos: .userInitiated).async {
                guard let self = self else { return }
                guard let image = self.image else { return }
                let newImage = try? process.process(image: image)
                DispatchQueue.main.async {
                    self.image = newImage
                }
            }
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
        processes.append(Sepia(intensity: 0.8))
        processes.append(Noir())
        processes.append(Fade())
        processes.append(Chrome())
        processes.append(Instant())
        processes.append(Blue())
        processes.append(Transfer())
        processes.append(Mono())
        processes.append(Monochrome(intensity: 1.00))
        processes.append(Vignette(intensity: 1.00))
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return processes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! filtersCollectionViewCell
        let imageProcessor = processes[indexPath.item]
        if let image = cell.imageView.image {
            cell.imageView.image = try? imageProcessor.process(image: image)
        }
        cell.layer.cornerRadius = 12
        cell.titleLabel.text = imageProcessor.title
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let imageProcess = processes[indexPath.item]
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
