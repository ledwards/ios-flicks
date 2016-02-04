//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Lee Edwards on 2/1/16.
//  Copyright © 2016 Lee Edwards. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkErrorAlert: UIView!
    
    var movies: [NSDictionary]?
    var endpoint: String!
    var name: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshCallback:", forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        
        
        tableView.dataSource = self
        tableView.delegate = self
        networkErrorAlert.hidden = true
        
        networkRequest()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return movies?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        let movie = movies![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview

        let baseUrl = "http://image.tmdb.org/t/p/w500"
        if let posterPath = movie["poster_path"] as? String {
            let imageUrl = NSURL(string: baseUrl + posterPath)
            let imageRequest = NSURLRequest(URL: imageUrl!)

            cell.posterView.setImageWithURLRequest(
                imageRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    if imageResponse != nil {
                        cell.posterView.alpha = 0.0
                        cell.posterView.image = image
                        UIView.animateWithDuration(0.3, animations: { () -> Void in
                            cell.posterView.alpha = 1.0
                        })
                    } else {
                        cell.posterView.image = image
                    }
                    self.networkErrorAlert.hidden = true
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    self.networkErrorAlert.hidden = false
                }
            )
        }
        
        return cell
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPathForCell(cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        let backItem = UIBarButtonItem()

        cell.selectionStyle = .Blue
        self.tableView.deselectRowAtIndexPath(indexPath!, animated: true)
        backItem.title = self.navigationController!.tabBarItem.title
        navigationItem.backBarButtonItem = backItem
        detailViewController.movie = movie
    }
    
    func refreshCallback(refreshControl: UIRefreshControl) {
        networkRequest(refreshControl)
    }
    
    func networkRequest(refreshControl: UIRefreshControl? = nil) {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string: "http://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )
        
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(data, options:[]) as? NSDictionary {
                        self.movies = responseDictionary["results"] as?[NSDictionary]
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                        self.tableView.reloadData()
                        self.networkErrorAlert.hidden = true
                        if let refreshControl = refreshControl {
                            refreshControl.endRefreshing()
                        }
                    }
                } else {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    self.networkErrorAlert.hidden = false
                }
        })
        task.resume()
    }
}
