//
//  NewsArticle+CoreDataProperties.swift
//  NewsReaderLAB12
//
//  Created by iosdev on 25/02/2019.
//  Copyright © 2019 san. All rights reserved.
//
//

import Foundation
import CoreData


extension NewsArticle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewsArticle> {
        return NSFetchRequest<NewsArticle>(entityName: "NewsArticle")
    }

    @NSManaged public var author: String?
    @NSManaged public var title: String?
    @NSManaged public var newsDescription: String?
    @NSManaged public var url: String?
    @NSManaged public var urlToImage: String?
    @NSManaged public var content: String?

}
