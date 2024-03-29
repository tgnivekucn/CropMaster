//
//  ViewController.swift
//  CropMaster
//
//  Created by 粘光裕 on 2023/12/17.
//

import UIKit

class ViewController: UIViewController, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func pressButtonAction(_ sender: UIButton) {
        presentPhotoPicker()
    }

    private func presentPhotoPicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary // For picking from the photo library
        present(picker, animated: true)
    }

    private func showCustomCropEditorView(image: UIImage) {
        let view = ImageCropEdiorView(frame: CGRect(origin: .zero, size: CGSize(width: self.view.frame.width, height: self.view.frame.height)))
        view.setupView(image: image) { image in
            print("test11 image: \(image)")
        }
        self.view.addSubview(view)
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)

        if let pickedImage = info[.originalImage] as? UIImage {
            showCustomCropEditorView(image: pickedImage)
            
//            let customEditorVC = CustomImageEditorViewController()
//            customEditorVC.passResultImageClosure = { image in
//                // do something to the cropped image
//                print("test11 got result cropped image: \(image)")
//            }
//            customEditorVC.imageToEdit = pickedImage
//            self.navigationController?.pushViewController(customEditorVC, animated: false)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Handle cancellation
        dismiss(animated: true, completion: nil)
    }

}
