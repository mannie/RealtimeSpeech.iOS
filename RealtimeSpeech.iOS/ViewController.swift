//
//  ViewController.swift
//  RealtimeSpeech.iOS
//
//  Created by Mannie Tagarira on 4/3/18.
//  Copyright © 2018 Microsoft. All rights reserved.
//

import UIKit

internal final class ViewController: UIViewController {
    
    @IBOutlet weak var toggleButton: UIButton!
    
    private var currentState: TransportState = .stop {
        didSet {
            updateVisualsForCurrentState(animate: true)
        }
    }
    
    private func updateVisualsForCurrentState(animate: Bool) {
        let control = (button: toggleButton, layer: toggleButton.layer)
        let state = (current: currentState, next: currentState.next)
        
        let updates = {
            control.button.setTitle(state.next.rawValue.uppercased(), for: .normal)
            
            control.layer.borderColor = state.current.color.cgColor
            control.layer.borderWidth = 1 / UIScreen.main.scale
            
            control.layer.cornerRadius = state.next.cornerRadius(for: control.button.frame.width)
        }
        
        if animate {
            UIView.animate(withDuration: 0.3, animations: updates)
        } else {
            updates()
        }
    }
    
    @IBAction func toggleTransport(_ sender: UIButton) {
        currentState = currentState.next
    }
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        updateVisualsForCurrentState(animate: false)
    }
    
}
