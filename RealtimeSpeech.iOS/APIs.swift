//
//  APIs.swift
//  RealtimeSpeech.iOS
//
//  Created by Mannie Tagarira on 4/10/18.
//  Copyright © 2018 Microsoft. All rights reserved.
//

import Foundation

internal struct API {

    internal let key: String
    
    private static let info = Bundle.main.apis
    internal static let speech = API(key: info["Speech"]?["Key"] ?? "")
    
}

fileprivate extension Bundle {
    
    fileprivate typealias APIInfoDictionary = [String:[String:String]]
    fileprivate var apis: APIInfoDictionary {
        guard
            let url = url(forResource: "APIs", withExtension: "plist"),
            let apis = NSDictionary(contentsOf: url) as? APIInfoDictionary else {
                fatalError("Failed to load or parse API info")
        }
        return apis
    }
    
}
