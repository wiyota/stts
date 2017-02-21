//
//  Contentful.swift
//  stts
//

import Foundation

class Contentful: StatusPageService {
    override var url: URL { return URL(string: "http://status.contentful.com")! }
    override var statusPageID: String { return "4bv17htq00cz" }
}
