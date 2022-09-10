//
//  StoryServer.swift
//  Mf_3
//
//  Created by Ferhat Abdullahoglu on 6.07.2019.
//  Copyright © 2019 Ferhat Abdullahoglu. All rights reserved.
//

import Foundation



class StoryServer: NSObject {

    
    // ==================================================== //
    // MARK: Properties
    // ==================================================== //
    
    // -----------------------------------
    // Public properties
    // -----------------------------------
    /// Story container
    var stories: [FAStory]?
    
    // -----------------------------------
    
    
    // -----------------------------------
    // Private properties
    // -----------------------------------
    
    // -----------------------------------
    
    
    // ==================================================== //
    // MARK: Init
    // ==================================================== //
    override init() {
        super.init()
        
        /// create the built in stories
        do {
            
            //
            // get the content from the config file
            //
            let data = try Data(contentsOf: Bundle.main.url(forResource: "Stories", withExtension: "json")!, options: [.mappedIfSafe])
            
            //
            // convert to json
            //
            guard let json = try JSONSerialization.jsonObject(with: data, options: [.mutableLeaves, .allowFragments]) as? NSDictionary else {return}
            
            //
            // extract the story data from the config
            //
            guard let _stories = json["stories"] as? [Any] else {return}
            
            //
            // go over all elements to initialize story objects
            // from each
            //
            for _story in _stories {
                let data = try JSONSerialization.data(withJSONObject: _story, options: [])
                
                let _story = try JSONDecoder().decode(FAStory.self, from: data)
                
                if self.stories == nil {
                    self.stories = [_story]
                } else {
                    self.stories?.append(_story)
                }
            }
            
            
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    // ==================================================== //
    // MARK: Methods
    // ==================================================== //
    
    // -----------------------------------
    // Public methods
    // -----------------------------------
    
    // -----------------------------------
    
    
    // -----------------------------------
    // Private methods
    // -----------------------------------
 
    // -----------------------------------
}
