//
//  TransportState.swift
//  RealtimeSpeech.iOS
//
//  Created by Mannie Tagarira on 4/3/18.
//  Copyright © 2018 Microsoft. All rights reserved.
//

import UIKit

internal enum TransportState: String {
    case record, stop, transcribe
    
    internal var next: TransportState {
        switch self {
        case .record: return .transcribe
        case .transcribe: return .stop
        case .stop: return .record
        }
    }

}

extension TransportState { // Theming
    
    internal var primaryColor: UIColor {
        switch self {
        case .record: return .red
        case .transcribe: return .gray
        case .stop: return .orange
        }
    }

    internal var secondaryColor: UIColor {
        switch self {
        case .record: return .darkText
        case .transcribe: return .orange
        case .stop: return .darkGray
        }
    }

}
