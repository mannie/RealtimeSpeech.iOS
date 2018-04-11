//
//  ViewController.swift
//  RealtimeSpeech.iOS
//
//  Created by Mannie Tagarira on 4/3/18.
//  Copyright © 2018 Microsoft. All rights reserved.
//

import UIKit
import AVKit

internal final class ViewController: UIViewController {
    
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var textView: UITextView!
    
    private var recorder: AVAudioRecorder?
    
    private var currentState: TransportState = .stop
    
    private func update(state: TransportState, text: String?=nil, animate: Bool=true) {
        currentState = state
        
        switch state {
        case .record:
            let temp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let url = URL(fileURLWithPath: "audio.wav", isDirectory: false, relativeTo: temp)
            let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16_000, channels: 1, interleaved: true)
            recorder = try? AVAudioRecorder(url: url, format: format!)
            recorder?.prepareToRecord()
            recorder?.record()
        case .transcribe:
            recorder?.stop()
            let data = try! Data(contentsOf: recorder!.url)
            upload(data)
        case .stop:
            recorder?.deleteRecording()
            recorder = nil
        }

        let updates = {
            let control = (button: self.toggleButton, layer: self.toggleButton.layer)
            let state = (current: state, next: state.next)
    
            control.layer.borderColor = state.next.primaryColor.cgColor
            control.layer.borderWidth = 1
            control.layer.cornerRadius = control.button.frame.width / 2
            
            control.button.setTitle(state.next.rawValue.uppercased(), for: .normal)
            control.button.setTitleColor(state.next.secondaryColor, for: .normal)
            
            self.textView.text = text
            self.textView.scrollRangeToVisible(NSRange())
        }
        
        DispatchQueue.main.async {
            if animate {
                UIView.animate(withDuration: 0.1, animations: updates)
            } else {
                updates()
            }
        }
    }
    
    @IBAction func toggleState(_ sender: UIButton) {
        update(state: currentState.next)
    }
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        update(state: .stop, animate: false)
        textView.isEditable = false
    }
    
}

fileprivate extension ViewController {

    fileprivate func upload(_ data: Data?) {
        guard let url = URL(string: "https://speech.platform.bing.com/speech/recognition/interactive/cognitiveservices/v1?language=en-US&format=simple") else {
            fatalError("Invalid streaming URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("audio/wav; codec=audio/pcm; samplerate=16000", forHTTPHeaderField: "Content-Type")
        request.setValue(API.speech.key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")

        let task = URLSession.shared.uploadTask(with: request, from: data) { (data, response, error) in
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] else {
                return
            }
            let text = json?["DisplayText"] as? String
            self.update(state: .stop, text: text)
        }
        task.resume()
    }

}
