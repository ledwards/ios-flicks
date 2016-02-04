//
//  DetailViewController.swift
//  Flicks
//
//  Created by Lee Edwards on 2/2/16.
//  Copyright © 2016 Lee Edwards. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var infoView: UIView!
    
    var movie: NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + infoView.frame.size.height)

        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        titleLabel.text = title
        overviewLabel.text = overview
        overviewLabel.sizeToFit()        
        self.navigationItem.title = title
        
        if let posterPath = movie["poster_path"] as? String {
            loadImage(posterPath)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadImage(posterPath: String) {
        let smallBaseUrl = "http://image.tmdb.org/t/p/w500"
        let largeBaseUrl = "http://image.tmdb.org/t/p/w1920"

        let smallImageUrl = NSURL(string: smallBaseUrl + posterPath)
        let largeImageUrl = NSURL(string: largeBaseUrl + posterPath)

        let smallImageRequest = NSURLRequest(URL: smallImageUrl!)
        let largeImageRequest = NSURLRequest(URL: largeImageUrl!)
        
        self.posterImageView.setImageWithURLRequest(
            smallImageRequest,
            placeholderImage: nil,
            success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in
                self.posterImageView.alpha = 0.0
                self.posterImageView.image = smallImage
                
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.posterImageView.alpha = 1.0
                },
                completion: { (sucess) -> Void in
                    self.posterImageView.setImageWithURLRequest(
                        largeImageRequest,
                        placeholderImage: smallImage,
                        success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                            self.posterImageView.image = largeImage
                        },
                        failure: { (request, response, error) -> Void in })
                })
            },
            failure: { (request, response, error) -> Void in })
    }
}
