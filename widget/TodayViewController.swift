//
//  TodayViewController.swift
//  widget
//
//  Created by Andrey Dolgov on 1/30/16.
//  Copyright © 2016 Andrey Dolgov. All rights reserved.
//

import Cocoa
import NotificationCenter

class TodayViewController: NSViewController, NCWidgetProviding, NCWidgetListViewDelegate, NCWidgetSearchViewDelegate {

    let timerInterval = NSTimeInterval(60);
    let brentUrl = NSURL(string: "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quote%20where%20symbol%20in%20(%22BZH16.NYM%22)&diagnostics=false&env=store://datatables.org/alltableswithkeys&format=json")
    
    let currencyURL = NSURL(string: "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.xchange%20where%20pair%20in%20(%22USDRUB%22,%22EURRUB%22)&env=store://datatables.org/alltableswithkeys&format=json")
    
    var timer = NSTimer()
    
    @IBOutlet weak var brentValue: NSTextField!
    @IBOutlet weak var eurValue: NSTextField!
    @IBOutlet weak var usdValue: NSTextField!
    @IBOutlet var listViewController: NCWidgetListViewController!
    var searchController: NCWidgetSearchViewController?
    
    // MARK: - NSViewController

    override var nibName: String? {
        return "TodayViewController"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the widget list view controller.
        // The contents property should contain an object for each row in the list.
        updateValues();
        timer = NSTimer.scheduledTimerWithTimeInterval(timerInterval, target: self, selector: "updateValues", userInfo: nil, repeats: true);
    }

    func getRandomColor() -> NSColor{
        
        let randomRed:CGFloat = CGFloat(drand48())
        
        let randomGreen:CGFloat = CGFloat(drand48())
        
        let randomBlue:CGFloat = CGFloat(drand48())
        
        return NSColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
        
    }
    
    func updateUSDEUR(){
        let task = NSURLSession.sharedSession().dataTaskWithURL(currencyURL!) { (data, response, error) -> Void in
            
            if error != nil {
                print("thers an error in the log")
            } else {
                
                dispatch_async(dispatch_get_main_queue()) {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []);
                        
                        if let dict = json as? [String: AnyObject] {
                            if let query = dict["query"] as? [String: AnyObject] {
                                if let results = query["results"] as? [String: AnyObject] {
                                    if let rates = results["rate"] as? [AnyObject]{
                                        for rate in rates {
                                            let id = rate["id"] as? String
                                            let rate = rate["Rate"] as! String;
                                            if (id! == "USDRUB"){
                                                self.usdValue.textColor = self.getRandomColor()
                                                self.usdValue.stringValue = (rate).substringToIndex(rate.endIndex.predecessor())
                                            }
                                            
                                            if (id! == "EURRUB"){
                                                self.usdValue.textColor = self.getRandomColor()
                                                self.eurValue.stringValue = (rate).substringToIndex(rate.endIndex.predecessor())
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } catch {
                        // failure
                        print("Fetch failed: \((error as NSError).localizedDescription)")
                    }
                }
            }
            
        }
        task.resume()
    }
    
    func updateBrent(){
        let task = NSURLSession.sharedSession().dataTaskWithURL(brentUrl!) { (data, response, error) -> Void in
            
            if error != nil {
                print("thers an error in the log")
            } else {
                
                dispatch_async(dispatch_get_main_queue()) {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []);
                        
                        if let dict = json as? [String: AnyObject] {
                            if let query = dict["query"] as? [String: AnyObject] {
                                if let results = query["results"] as? [String: AnyObject] {
                                    if let quote = results["quote"] as? [String: AnyObject]{
                                        let lastPrice = quote["LastTradePriceOnly"] as! String
                                        self.brentValue.textColor = self.getRandomColor();
                                        self.brentValue.stringValue = (lastPrice).substringToIndex(lastPrice.endIndex.predecessor())
                                    }
                                }
                            }
                        }
                    } catch {
                        // failure
                        print("Fetch failed: \((error as NSError).localizedDescription)")
                    }
                }
            }
            
        }
        task.resume()
    }
    
    func updateValues() {
        updateBrent()
        updateUSDEUR()
    }

    
    override func dismissViewController(viewController: NSViewController) {
        super.dismissViewController(viewController)

        // The search controller has been dismissed and is no longer needed.
        if viewController == self.searchController {
            self.searchController = nil
        }
    }

    // MARK: - NCWidgetProviding

    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        // Refresh the widget's contents in preparation for a snapshot.
        // Call the completion handler block after the widget's contents have been
        // refreshed. Pass NCUpdateResultNoData to indicate that nothing has changed
        // or NCUpdateResultNewData to indicate that there is new data since the
        // last invocation of this method.
        completionHandler(.NoData)
    }

    func widgetMarginInsetsForProposedMarginInsets(var defaultMarginInset: NSEdgeInsets) -> NSEdgeInsets {
        // Override the left margin so that the list view is flush with the edge.
        defaultMarginInset.left = 0
        return defaultMarginInset
    }

    var widgetAllowsEditing: Bool {
        // Return true to indicate that the widget supports editing of content and
        // that the list view should be allowed to enter an edit mode.
        return false
    }

    func widgetDidBeginEditing() {
        // The user has clicked the edit button.
        // Put the list view into editing mode.
        self.listViewController.editing = true
    }

    func widgetDidEndEditing() {
        // The user has clicked the Done button, begun editing another widget,
        // or the Notification Center has been closed.
        // Take the list view out of editing mode.
        self.listViewController.editing = false
    }

    // MARK: - NCWidgetListViewDelegate

    func widgetList(list: NCWidgetListViewController!, viewControllerForRow row: Int) -> NSViewController! {
        // Return a new view controller subclass for displaying an item of widget
        // content. The NCWidgetListViewController will set the representedObject
        // of this view controller to one of the objects in its contents array.
        return ListRowViewController()
    }

    func widgetListPerformAddAction(list: NCWidgetListViewController!) {
        // The user has clicked the add button in the list view.
        // Display a search controller for adding new content to the widget.
        self.searchController = NCWidgetSearchViewController()
        self.searchController!.delegate = self

        // Present the search view controller with an animation.
        // Implement dismissViewController to observe when the view controller
        // has been dismissed and is no longer needed.
        self.presentViewControllerInWidget(self.searchController)
    }

    func widgetList(list: NCWidgetListViewController!, shouldReorderRow row: Int) -> Bool {
        // Return true to allow the item to be reordered in the list by the user.
        return true
    }

    func widgetList(list: NCWidgetListViewController!, didReorderRow row: Int, toRow newIndex: Int) {
        // The user has reordered an item in the list.
    }

    func widgetList(list: NCWidgetListViewController!, shouldRemoveRow row: Int) -> Bool {
        // Return true to allow the item to be removed from the list by the user.
        return true
    }

    func widgetList(list: NCWidgetListViewController!, didRemoveRow row: Int) {
        // The user has removed an item from the list.
    }

    // MARK: - NCWidgetSearchViewDelegate

    func widgetSearch(searchController: NCWidgetSearchViewController!, searchForTerm searchTerm: String!, maxResults max: Int) {
        // The user has entered a search term. Set the controller's searchResults property to the matching items.
        searchController.searchResults = []
    }

    func widgetSearchTermCleared(searchController: NCWidgetSearchViewController!) {
        // The user has cleared the search field. Remove the search results.
        searchController.searchResults = nil
    }

    func widgetSearch(searchController: NCWidgetSearchViewController!, resultSelected object: AnyObject!) {
        // The user has selected a search result from the list.
    }

}
