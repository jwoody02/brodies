//
//  Fetcher.swift
//  Egg.
//
//  Created by Jordan Wood on 5/26/22.
//
import Photos
import PhotosUI
import UIKit
@objc
class Fetcher: NSObject,  PHPhotoLibraryChangeObserver {
    private var imageManager = PHCachingImageManager()
    private var fetchResult: PHFetchResult<PHAsset>!

    override init() {
        let options = PHFetchOptions()
        options.sortDescriptors = [ NSSortDescriptor(key: "modificationDate", ascending: true) ] // or "creationDate"
        self.fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        super.init()
        PHPhotoLibrary.shared().register(self)
    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Photos may call this method on a background queue; switch to the main queue to update the UI.
        DispatchQueue.main.async { [weak self]  in
            guard let sSelf = self else { return }

            if let changeDetails = changeInstance.changeDetails(for: sSelf.fetchResult) {
                let updateBlock = { () -> Void in
                    self?.fetchResult = changeDetails.fetchResultAfterChanges
                }
            }
        }
    }

    func requestLastCreateImage(targetSize:CGSize, completion: @escaping (UIImage) -> Void) -> Int32 {
        let asset  = self.fetchResult.lastObject as! PHAsset
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        
        return self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options, resultHandler: { (result, info)->Void in
            if let result = result {
                completion(result)
            }
        })
    }

    func requestPreviewImageAtIndex(index: Int, targetSize: CGSize, completion: @escaping (UIImage) -> Void) -> Int32 {
        assert(index >= 0 && index < self.fetchResult.count, "Index out of bounds")
        let asset = self.fetchResult[index] as! PHAsset
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        return self.imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { (image, info)->Void in
            if let image = image {
                completion(image)
            }
        }
    }

    func requestFullImageAtIndex(index: Int, completion: @escaping (UIImage) -> Void) {
        assert(index >= 0 && index < self.fetchResult.count, "Index out of bounds")
        let asset = self.fetchResult[index] as! PHAsset
        self.imageManager.requestImageData(for: asset, options: nil) { (data, dataUTI, orientation, info) -> Void in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            }
        }
    }
}
