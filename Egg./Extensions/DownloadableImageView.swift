//
//  DownloadableImageView.swift
//  Egg.
//
//  Created by Jordan Wood on 7/26/22.
//

import UIKit
// 1
let imageCache = NSCache<AnyObject, AnyObject>()
class DownloadableImageView: UIImageView {
    
    var urlString: String?
    // 2
    var dataTask: URLSessionDataTask?
    
    func downloadWithUrlSession(at cell: UICollectionViewCell, urlStr: String) {
        urlString = urlStr
        
        guard let url = URL(string: urlStr) else { return  }
        // 3
        image = nil
        
        if let imageFromCache = imageCache.object(forKey: urlStr as AnyObject) as? UIImage {
            self.image = imageFromCache
            return
        }
        
        self.dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data) else {
                return
            }
            
            DispatchQueue.main.async {
                if self.urlString == urlStr { // 4
                    self.image = image
                }
                
                imageCache.setObject(image, forKey: urlStr as AnyObject)
            }
        }
        
        dataTask?.resume()
    }
    // 5
    func cancelLoadingImage() {
        dataTask?.cancel()
        dataTask = nil
    }
}
