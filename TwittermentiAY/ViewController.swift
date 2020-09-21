//
//  ViewController.swift
//  Twittermenti
//
//  Created by Angela Yu on 17/07/2019.
//  Copyright © 2019 London App Brewery. All rights reserved.
//

import UIKit
import SwifteriOS
import CoreML
import SwiftyJSON

class ViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sentimentLabel: UILabel!
    
    let swifter = Swifter(consumerKey: Constants.twitter.API_key, consumerSecret: Constants.twitter.secret_API_key)
    
    let classifier = TweetSentimentClassifier()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func predictPressed(_ sender: Any) {
        fetchTweets()
    }
    
    func fetchTweets(){
        
        if let searchText = textField.text {
            //count: default = 15, max = 100
            //language ISO code specified to fetch English only, since model trained in English
            swifter.searchTweet(using: searchText, lang: "en", count: Constants.searchCount, tweetMode: .extended, success: { (result, metadata) in
                //print("result: \(result)")
                
                var tweets = [TweetSentimentClassifierInput]()
                
                //100 count start 0 end 99
                for i in 0 ..< Constants.searchCount {
                    if let tweet = result[i]["full_text"].string{
                        tweets.append(TweetSentimentClassifierInput(text: tweet))
                    }
                }
                
                self.makePredictions(with: tweets)
                
            }) { (error) in
                print("Error in API request: \(error)")
            }
        }
    }
    
    func makePredictions(with source: [TweetSentimentClassifierInput]){
        do{
            let predictions = try self.classifier.predictions(inputs: source)
            
            //calculate overall sentiment score
            var score = 0
            for p in predictions{
                if p.label == "Pos"{
                    score += 1
                }else if p.label == "Neg"{
                    score -= 1
                }
            }
            
            updateUI(score: score)
            
        }catch{
            print("Error predicting sentiments: \(error)")
        }
        
    }
    
    func updateUI(score: Int){
        if score > 20 {
            self.sentimentLabel.text = "😍"
        }else if score > 10 {
            self.sentimentLabel.text = "😊"
        }else if score > 1 {
            self.sentimentLabel.text = "🙂"
        }else if score < -1 {
            self.sentimentLabel.text = "🙁"
        }else if score < -10 {
            self.sentimentLabel.text = "☹️"
        }else if score < -20 {
            self.sentimentLabel.text = "😡"
        }else{
            self.sentimentLabel.text = "😐"
        }
    }
    
    
    //MARK: - Keyboard manager
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
}

