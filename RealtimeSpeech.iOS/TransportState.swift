//
//  TransportState.swift
//  RealtimeSpeech.iOS
//
//  Created by Mannie Tagarira on 4/3/18.
//  Copyright © 2018 Microsoft. All rights reserved.
//

import UIKit

internal enum TransportState: String {
    case record, stop
    
    internal var next: TransportState {
        switch self {
        case .record: return .stop
        case .stop: return .record
        }
    }

}

extension TransportState { // Theming
    
    internal var primaryColor: UIColor {
        switch self {
        case .record: return .red
        case .stop: return .orange
        }
    }

    internal var secondaryColor: UIColor {
        switch self {
        case .record: return .darkText
        case .stop: return .darkGray
        }
    }

}
