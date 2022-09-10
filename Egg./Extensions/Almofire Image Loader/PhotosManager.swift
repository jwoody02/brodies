//
//  PhotosManager.swift
//  Egg.
//
//  Created by Jordan Wood on 7/10/22.
//

import UIKit
import Alamofire
import AlamofireImage

extension UInt64 {

    func megabytes() -> UInt64 {
        return self * 1024 * 1024
    }

}

class PhotosManager {

    lazy var photos: [Photo] = {
        guard let url = Bundle.main.url(forResource: "GlacierScenics", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let photos = try? PropertyListDecoder().decode([Photo].self, from: data) else { return [] }
        return photos
    }()

    let imageCache = AutoPurgingImageCache(
        memoryCapacity: UInt64(100).megabytes(),
        preferredMemoryUsageAfterPurge: UInt64(60).megabytes()
    )

    //MARK: - Image Downloading

    func retrieveImage(for url: String, completion: @escaping (UIImage) -> Void) -> Request {
        return Alamofire.request(url, method: .get).responseImage { response in
            guard let image = response.result.value else { return }
            completion(image)
            self.cache(image, for: url)
        }
    }

    //MARK: - Image Caching

    func cache(_ image: Image, for url: String) {
        imageCache.add(image, withIdentifier: url)
    }

    func cachedImage(for url: String) -> Image? {
        return imageCache.image(withIdentifier: url)
    }

}
struct Photo: Codable {

    let name: String
    let url: String
    let hashImage: String
}

