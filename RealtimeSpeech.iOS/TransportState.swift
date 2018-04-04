//
//  TransportState.swift
//  RealtimeSpeech.iOS
//
//  Created by Mannie Tagarira on 4/3/18.
//  Copyright © 2018 Microsoft. All rights reserved.
//

import UIKit

internal enum TransportState: String {
    case listen, stop
    
    internal var next: TransportState {
        switch self {
        case .listen : return .stop
        case .stop : return .listen
        }
    }

}

extension TransportState { // Theming
    
    internal var color: UIColor {
        switch self {
        case .listen : return .red
        case .stop : return .blue
        }
    }
    
    internal func cornerRadius(for width: CGFloat) -> CGFloat {
        switch self {
        case .listen : return width / 2
        case .stop : return 1
        }
    }
    
}
