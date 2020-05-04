//
//  DataSources.swift
//  Negpho
//
//  Created by Negar Jafari on 4/30/20.
//  Copyright © 2020 Negar Jafari. All rights reserved.
//

import UIKit

class DataSources: NSObject {
    class ProcessDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
        typealias Process = (UIImage) -> UIImage
        var processes: [ImageProcess] = []
        let callback: (ImageProcess) -> Void
        var cachedImages = [String: UIImage]()
        private var thumbnail: UIImage? = nil
        var userImage: UIImage? = nil {
            didSet {
                guard let image = self.userImage else { return }
                guard let data = image.jpegData(compressionQuality: 50) else { return }
                let thumb = UIImage(data: data)
                self.thumbnail = thumb
            }
        }
        
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! FiltersCollectionViewCell
            let imageProcessor = processes[indexPath.item]
            
            if let image = thumbnail { //cell.imageView.image {
                if let cached = cachedImages[imageProcessor.title] {
                    cell.imageView.image = cached
                } else {
                    let newImage = try? imageProcessor.process(image: image)
                    cell.imageView.image = newImage
                    cachedImages[imageProcessor.title] = newImage
                }
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
            return CGSize(width: collectionView.frame.size.width, height: 75)
        }
    }
}
