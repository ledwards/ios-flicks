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

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var networkErrorAlert: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var movies: [NSDictionary] = []
    var endpoint: String!
    var name: String!
    var lastPageLoaded = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "refreshCallback:", forControlEvents: .ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        collectionView.hidden = true
        
        let segmentedControl = UISegmentedControl(items: ["List", "Collection"])
        segmentedControl.sizeToFit()
        let segmentedButton = UIBarButtonItem(customView: segmentedControl)
        segmentedControl.addTarget(self, action: "segmentedButtonTapped:", forControlEvents: .ValueChanged)
        navigationItem.rightBarButtonItem = segmentedButton
        segmentedControl.selectedSegmentIndex = 0
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Search", style: .Plain, target: self, action: "search:")
        
        collectionView.dataSource = self
        
        tableView.dataSource = self
        tableView.delegate = self
        networkErrorAlert.hidden = true
        searchBar.hidden = true
        
        networkRequest()
        
        let tableFooterView: UIView = UIView(frame: CGRectMake(0, 0, 320, 50))
        let loadingView: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        loadingView.startAnimating()
        loadingView.center = tableFooterView.center
        tableFooterView.addSubview(loadingView)
        self.tableView.tableFooterView = tableFooterView
    }
    
    func segmentedButtonTapped(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.tableView.hidden = false
            self.collectionView.hidden = true
        case 1:
            self.tableView.hidden = true
            self.collectionView.hidden = false
        default:
            break
        }
    }
    
    func search(sender: UIView) {
        self.searchBar.hidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return movies.count
    }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        let movie = movies[indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        if indexPath.row == self.movies.count - 1 {
            networkRequest()
        }

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
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MovieCollectionCell", forIndexPath: indexPath) as! MovieCollectionCell
        let movie = movies[indexPath.item]
        
        if indexPath.item == self.movies.count - 1 {
            networkRequest()
        }
        
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
        var indexPath: NSIndexPath? = nil
        if let _ = sender as? MovieCell {
            let cell = sender as! MovieCell
            indexPath = tableView.indexPathForCell(cell)
            cell.selectionStyle = .Blue
        } else if let _ = sender as? MovieCollectionCell {
            let cell = sender as! MovieCollectionCell
            indexPath = collectionView.indexPathForCell(cell)
        }
        let movie = movies[indexPath!.row]
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        let backItem = UIBarButtonItem()

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
        let page = refreshControl == nil ? self.lastPageLoaded + 1 : 1
        let url = NSURL(string: "http://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)&page=\(page)")
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
                        let movies = responseDictionary["results"] as! [NSDictionary]
                        let page = responseDictionary["page"] as! Int
                        if let refreshControl = refreshControl {
                            refreshControl.endRefreshing()
                        }
                        self.populateViews(movies, page: page)
                        self.networkErrorAlert.hidden = true

                    }
                } else {
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    self.networkErrorAlert.hidden = false
                }
        })
        task.resume()
    }
    
    func populateViews(movies: [NSDictionary], page: Int) {
        self.movies += movies
        self.lastPageLoaded = page
        MBProgressHUD.hideHUDForView(self.view, animated: true)
        self.tableView.reloadData()
        self.collectionView.reloadData()
    }
}
