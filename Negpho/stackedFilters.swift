//
//  stackedFilters.swift
//  Negpho
//
//  Created by Negar Jafari on 3/11/20.
//  Copyright © 2020 Negar Jafari. All rights reserved.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

protocol ImageProcess {
       func process(image: UIImage) throws -> UIImage
   }

enum ProcessError: Error {
    case InputImageFailed
    case OutputImageFailed
}

struct AnyImageProcess: ImageProcess {
    private let f: (UIImage) throws -> UIImage
    
    init(process: @escaping (UIImage) throws -> UIImage) {
        self.f = process
    }
    func process(image: UIImage) throws -> UIImage {
        try f(image)
    }
}

extension ImageProcess {
    static func empty() ->ImageProcess {
        return AnyImageProcess(process: {image in return image})
    }
    static func compose(first: ImageProcess, second: ImageProcess) throws ->ImageProcess {
        return AnyImageProcess{try second.process(image: first.process(image: $0))}
    }
    static func concat(processes: [ImageProcess]) throws->ImageProcess {
        try processes.reduce(AnyImageProcess.empty(), {try compose(first: $0, second: $1)})
    }
}

extension ImageProcess {
    func append(other:ImageProcess) throws->ImageProcess {
        try AnyImageProcess.compose(first: self, second: other)
    }
}

final class Processor: ImageProcess {
    var processes:[ImageProcess]=[]
    
    func push(process: ImageProcess) {
        processes.append(process)
    }
     func dropLastProcess() {
        processes = processes.dropLast()
    }
     func replaceLast(with process: ImageProcess) {
        dropLastProcess()
        push(process: process)
    }
    
    func process(image: UIImage) throws -> UIImage {
        try AnyImageProcess.concat(processes: processes).process(image: image)
    }
}

struct Sepia: ImageProcess {
    let context = CIContext()
    let intensity: Float
    let filter = CIFilter.sepiaTone()
    
    func process(image: UIImage) throws -> UIImage {
        let input = CIImage(image: image)
        filter.intensity = intensity
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage
            else {
                throw ProcessError.InputImageFailed
        }
        guard let cgImage = context.createCGImage(output, from: output.extent)
            else {
                throw ProcessError.OutputImageFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

struct Noir: ImageProcess {
    let context = CIContext()
    let filter = CIFilter.photoEffectNoir()
    
    func process(image: UIImage) throws -> UIImage {
        let input = CIImage(image: image)
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage
            else {
                throw ProcessError.InputImageFailed
        }
        guard let cgImage = context.createCGImage(output, from: output.extent)
            else {
                throw ProcessError.OutputImageFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

struct Fade: ImageProcess {
    let context = CIContext()
    let filter = CIFilter.photoEffectFade()
    
    func process(image: UIImage) throws -> UIImage {
        let input = CIImage(image: image)
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage
            else {
                throw ProcessError.InputImageFailed
        }
        guard let cgImage = context.createCGImage(output, from: output.extent)
            else {
                throw ProcessError.OutputImageFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

struct Chrome: ImageProcess {
    let context = CIContext()
    let filter = CIFilter.photoEffectChrome()
    
    func process(image: UIImage) throws -> UIImage {
        let input = CIImage(image: image)
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage
            else {
                throw ProcessError.InputImageFailed
        }
        guard let cgImage = context.createCGImage(output, from: output.extent)
            else {
                throw ProcessError.OutputImageFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

struct Instant: ImageProcess {
    let context = CIContext()
    let filter = CIFilter.photoEffectInstant()
    
    func process(image: UIImage) throws -> UIImage {
        let input = CIImage(image: image)
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage
            else {
                throw ProcessError.InputImageFailed
        }
        guard let cgImage = context.createCGImage(output, from: output.extent)
            else {
                throw ProcessError.OutputImageFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

struct Blue: ImageProcess {
    let context = CIContext()
    let filter = CIFilter.photoEffectProcess()
    
    func process(image: UIImage) throws -> UIImage {
        let input = CIImage(image: image)
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage
            else {
                throw ProcessError.InputImageFailed
        }
        guard let cgImage = context.createCGImage(output, from: output.extent)
            else {
                throw ProcessError.OutputImageFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

struct Transfer: ImageProcess {
    let context = CIContext()
    let filter = CIFilter.photoEffectTransfer()
    
    func process(image: UIImage) throws -> UIImage {
        let input = CIImage(image: image)
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage
            else {
                throw ProcessError.InputImageFailed
        }
        guard let cgImage = context.createCGImage(output, from: output.extent)
            else {
                throw ProcessError.OutputImageFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

struct Mono: ImageProcess {
    let context = CIContext()
    let filter = CIFilter.photoEffectMono()
    
    func process(image: UIImage) throws -> UIImage {
        let input = CIImage(image: image)
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage
            else {
                throw ProcessError.InputImageFailed
        }
        guard let cgImage = context.createCGImage(output, from: output.extent)
            else {
                throw ProcessError.OutputImageFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

struct Monochrome: ImageProcess {
    let context = CIContext()
    let intensity: Float
    let filter = CIFilter.colorMonochrome()
    
    func process(image: UIImage) throws -> UIImage {
        let input = CIImage(image: image)
        filter.intensity = intensity
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage
            else {
                throw ProcessError.InputImageFailed
        }
        guard let cgImage = context.createCGImage(output, from: output.extent)
            else {
                throw ProcessError.OutputImageFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

struct Vignette: ImageProcess {
    let context = CIContext()
    let intensity: Float
    let filter = CIFilter.vignette()
    
    func process(image: UIImage) throws -> UIImage {
        let input = CIImage(image: image)
        filter.intensity = intensity
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage
            else {
                throw ProcessError.InputImageFailed
        }
        guard let cgImage = context.createCGImage(output, from: output.extent)
            else {
                throw ProcessError.OutputImageFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

struct Contrast: ImageProcess {
    let context = CIContext()
    let level: Float
    let intensity: Float
    let filter = CIFilter.colorControls()
    
    func process(image: UIImage) throws -> UIImage {
        let input = CIImage(image: image)
        filter.setValue(level, forKey: kCIInputContrastKey)
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage
            else {
                throw ProcessError.InputImageFailed
        }
        guard let cgImage = context.createCGImage(output, from: output.extent)
            else {
                throw ProcessError.OutputImageFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

class stackedFilters: UIView {

}

