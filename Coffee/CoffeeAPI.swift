//
//  CoffeeAPI.swift
//  Coffee
//
//  Created by Andreas on 08/12/15.
//  Copyright © 2015 Andreas Aronsson. All rights reserved.
//

import Foundation
import QuadratTouch
import MapKit
import RealmSwift

struct API {
    struct notifications {
        static let venuesUpdated = "venues_updated";
    }
}

class CoffeeAPI
{
    static let sharedInstance = CoffeeAPI();
    
    var session:Session?;
    
    init()
    {
        // Initialize the Foursquare client
    
        
        let client = Client(clientID: "URWVCEPK0DRA31YVGCLSF0QDNP5XZPXQZZXQEMFCEKBY5FVS", clientSecret: "HSVOL0DZ3RAAJZDGBM4XKAXQIWUAD1ZCADSGSIUGHAKPTII3", redirectURL: "");
        
        let configuration = Configuration(client:client);
        Session.setupSharedSessionWithConfiguration(configuration);
        
        self.session = Session.sharedSession();
    }
    
    func getCoffeeShopsWithLocation(location:CLLocation)
    {
        if let session = self.session
        {
            // Provide the user location and the hard-coded Foursquare category ID for "Food"
            // see https://developer.foursquare.com/categorytree for all categories
            var parameters = location.parameters();
            parameters += [Parameter.categoryId: "4d4b7105d754a06374d81259"];
            parameters += [Parameter.radius: "2000"];
            //gets 50 results
            parameters += [Parameter.limit: "5"];
            
            // Start a "search", i.e. an async call to Foursquare that should return venue data
            let searchTask = session.venues.search(parameters)
                {
                    (result) -> Void in
                    
                    if let response = result.response
                    {
                        if let venues = response["venues"] as? [[String: AnyObject]]
                        {
                            autoreleasepool
                                {
                                    let realm = try! Realm(); // Note: no error handling
                                    realm.beginWrite();
                                    
                                    for venue:[String: AnyObject] in venues
                                    {
                                        let venueObject: Venue = Venue();
                                        
                                        if let id = venue["id"] as? String
                                        {
                                            venueObject.id = id;
                                        }
                                        
                                        if let name = venue["name"] as? String
                                        {
                                            venueObject.name = name;
                                        }
                                        
                                        if  let location = venue["location"] as? [String: AnyObject]
                                        {
                                            if let longitude = location["lng"] as? Float
                                            {
                                                venueObject.longitude = longitude;
                                            }
                                            
                                            if let latitude = location["lat"] as? Float
                                            {
                                                venueObject.latitude = latitude;
                                            }
                                            
                                            if let formattedAddress = location["formattedAddress"] as? [String]
                                            {
                                                venueObject.address = formattedAddress.joinWithSeparator(" ");
                                            }
                                            
                                            
                                        }
                                         print(result.response)
                                        realm.add(venueObject, update: true);
                                    }
                                    
                                    do {
                                        try realm.commitWrite();
                                        print("Committing write...");
                                    }
                                    catch (let e)
                                    {
                                        print("Y U NO REALM ? \(e)");
                                    }
                            }
                            
                            NSNotificationCenter.defaultCenter().postNotificationName(API.notifications.venuesUpdated, object: nil, userInfo: nil);
                        }
                    }
            }
            
            searchTask.start()
        }
    }
}

extension CLLocation
{
    func parameters() -> Parameters
    {
        let ll      = "\(self.coordinate.latitude),\(self.coordinate.longitude)"
        let llAcc   = "\(self.horizontalAccuracy)"
        let alt     = "\(self.altitude)"
        let altAcc  = "\(self.verticalAccuracy)"
        let parameters = [
            Parameter.ll:ll,
            Parameter.llAcc:llAcc,
            Parameter.alt:alt,
            Parameter.altAcc:altAcc
        ]
        return parameters
    }
}