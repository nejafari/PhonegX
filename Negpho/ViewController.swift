//
//  ViewController.swift
//  Negpho
//
//  Created by Negar Jafari on 11/18/19.
//  Copyright © 2019 Negar Jafari. All rights reserved.
//

import UIKit
import CoreImage

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        var preferredStatusBarStyle: UIStatusBarStyle {
              return .lightContent
        }
    }
    //Upload image
    @IBAction func uploadButton(_ sender: Any) {
        let myAlert = UIAlertController(title: "Select Image:", message: "", preferredStyle: .actionSheet)
        let camera = UIAlertAction(title: "Camera", style: .default) {
            (ACTION) in if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
                    let image = UIImagePickerController()
                    image.delegate = self
                    image.sourceType = UIImagePickerController.SourceType.camera
                    image.allowsEditing = true
                    self.present(image, animated: true, completion: nil)
            }
        }
        let cameraRoll = UIAlertAction(title: "Camera Roll", style: .default) {
            (ACTION) in if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {
                    let image = UIImagePickerController()
                    image.delegate = self
                    image.sourceType = UIImagePickerController.SourceType.photoLibrary
                    image.allowsEditing = true
                    self.present(image, animated: true, completion: nil)
            }
        }
        myAlert.addAction(camera)
        myAlert.addAction(cameraRoll)
        self.present(myAlert, animated: true, completion: nil)
     }
    //image picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = pickedImage
        }
        self.dismiss(animated: true) {
            self.performSegue(withIdentifier: "launchEditor", sender: nil)
        }
    }
    //opening up editingviewcontroller after uploading
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let editing = segue.destination as? EditingViewController else { return }
        guard let image = imageView.image else {
            return
        }
        editing.addImage(image)
    }
 }
