//
//  NewsListViewController.swift
//  NewsReaderLAB12
//
//  Created by iosdev on 25/02/2019.
//  Copyright © 2019 san. All rights reserved.
//

import UIKit
import CoreData

//Structs to match and decode the JSON response
struct NewsDataInJson:Decodable {
    let articles:[Article]
}

struct Article:Decodable {
    //let source: Source
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let content: String?
}

struct Source: Decodable {
    let id: String?
    let name: String
}





class NewsListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {
    
    //This will hold news user is searching for
    var filteredNews = [NewsArticle]()
    
    //MARK: Properties
    @IBOutlet weak var tableView: UITableView!
    var fetchedResultsController:NSFetchedResultsController<NewsArticle>?
    //Initializing with nil value uses the same view you're searching to display results
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        getNewsData()
        //Implementing fetched results controller
        let fetchRequest: NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: PersitenceService.context, sectionNameKeyPath: "title", cacheName: "newsCache")
        //Setting the view controller to be the delegate for the fetchedResultsController and perform fetch
        fetchedResultsController!.delegate = self as NSFetchedResultsControllerDelegate; try? fetchedResultsController?.performFetch()
        
        super.viewDidLoad()
        
        //Setup new NavBar and implementing search bar
        navigationController?.navigationBar.prefersLargeTitles = true
        //Setup the Search Controller
        //This property on UISearchController conforms to the protocal UISearchResultsUpdating. This protocal allows your class to be informed as text changes within the UISearchBar
        searchController.searchResultsUpdater = self
        //By default, UISearchController will obscure the view it is presented over. This is useful if you are using another view controller for searchResultsController. In this instance, you have set the current view to show the results, so you do not want to obscure your view.
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search News"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        //Finally, by setting definesPresentationContext on your view controller to true, you ensure that the search bar does not remain on the screen if the user navigates to another view controller while the UISearchController is active.
        definesPresentationContext = true
        
        
        
    }
    
    //For automatically updating the UI on change in data
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("controllerDidChangeContent")
        tableView.reloadData()
    }
    
    //MARK: - UISearchResultsUpdatingDelegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    
    //MARK: UITableViewDataSource and Delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering(){
            //Prevents from creating duplicates rows in with same news article
            return 1
        }
        return fetchedResultsController!.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //Updates the table view if the user starts searching accodring to respective datasource
        if isFiltering(){
            return filteredNews.count
        }
        if let sections = fetchedResultsController!.sections, sections.count > 0 {
            return sections[section].numberOfObjects
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell", for: indexPath) as? NewsCell else {
            fatalError("The dequeued cell in not an instance of NewsCell")
        }
        let newsItem: NewsArticle
        if isFiltering() {
            newsItem = filteredNews[indexPath.row]
        } else {
            //Force Unwrapping
            newsItem = (self.fetchedResultsController?.object(at: indexPath))!
        }

        //ImageURL might be empty and cause nil errors
        if(newsItem.urlToImage ?? "" == ""){
            
            cell.newsImageView.image = UIImage(named: "defaultPhoto")
        }else{
            //Executes only if the url is not empty
            guard let imageURL = URL(string: newsItem.urlToImage!) else {
                fatalError("Image URL not found")
            }
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: imageURL)
                DispatchQueue.main.async {
                    cell.newsImageView.image = UIImage(data: data!)
                }
            }
        }
        cell.newsTitleLabel?.text = newsItem.title
        return cell
    }
    
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let newsDetailViewController = segue.destination as? NewsDetailViewController else {
            fatalError("Unexpected destination: \(segue.destination)")
        }
        
        guard let selectedNewsItemCell = sender as? NewsCell else {
            fatalError("unexpected sender: \(String(describing: sender))")
        }
        
        guard let indexPath = tableView.indexPath(for: selectedNewsItemCell) else {
            fatalError("The selected cell is not being displayed by the table")
        }
        
        let selectedNewsItem: NewsArticle
        if isFiltering() {
            selectedNewsItem = filteredNews[indexPath.row]
        } else {
            //Force Unwrapping NewsArticle
            selectedNewsItem = (self.fetchedResultsController?.object(at: indexPath))!
        }
        
        let urlToBePassed = selectedNewsItem.url!
        newsDetailViewController.newsDetailURL = urlToBePassed
    }
    
    
    
    
    
    //MARK: - Private instance methods
    
    func searchBarIsEmpty() -> Bool {
        //Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    //Filters the all nnews array based on searchText and stores results in filteredNewsArray
    func filterContentForSearchText(_ searchText: String){
        let allNews = self.fetchedResultsController?.fetchedObjects
        print(allNews!.count)
        //filter() takes a closure of type (news: NewsArticle) -> Bool. It then loops over all the elements of the array, and calls the closure, passing in the current element, for every one of the elements.
        //determines whether the newsItem should be part of the search results presented to the user. To do so, you need to return true if the current newsItem is to be included in the filtered array, or false otherwise.
        filteredNews = allNews!.filter({( news : NewsArticle) -> Bool in
            return news.title!.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    
    //Fetching news data from the api
    func getNewsData() {
        
        guard let url = URL(string: "https://newsapi.org/v2/top-headlines?country=us&apiKey=2d0505f066b445f1ad3dfed09ecec71d") else {
            fatalError("Failed to create URL")
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            //Handle data and saving it
            if let dataRecieved = data {
                do{
                    let newsData = try JSONDecoder().decode(NewsDataInJson.self, from: dataRecieved)
                    
                    DispatchQueue.main.async {
                        for(index, article) in newsData.articles.enumerated(){
                            //Creating the fetch request to check if teh article is already saved
                            let fetchRequest: NSFetchRequest<NewsArticle> = NewsArticle.fetchRequest()
                            fetchRequest.predicate = NSPredicate(format: "title == %@", article.title)
                            do{
                                let tempNews: [NewsArticle] = try PersitenceService.context.fetch(fetchRequest)
                                if(tempNews.count==0){
                                    print("Core data does not has this item")
                                    //Saving news items using core data
                                    let newsItem = NewsArticle(context: PersitenceService.context)
                                    newsItem.author = article.author
                                    newsItem.title = article.title
                                    newsItem.content = article.content
                                    newsItem.newsDescription = article.description
                                    newsItem.url = article.url
                                    newsItem.urlToImage = article.urlToImage
                                    PersitenceService.saveContext()
                                    print("Saved Item \(index + 1) times")
                                }else{
                                    print("This news article is already saved")
                                }
                            }catch{
                                fatalError("Cannot fetch saved data")
                            }

                        }
                    }
                    //print(newsData.articles[0].title)
                    //print(self.newsArray)
                }catch {
                    print("Error serializing json: \(error)")
                }
            }
            
        }
        task.resume()
    }
    
}
