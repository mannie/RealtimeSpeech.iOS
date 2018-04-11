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
    @IBOutlet weak var languagePicker: UIPickerView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var translatedTextView: UITextView!
    
    private var recorder: AVAudioRecorder?
    
    private var currentState: TransportState = .stop
    
    private func update(state: TransportState, animate: Bool=true) {
        currentState = state
        
        switch state {
        case .record:
            recorder?.prepareToRecord()
            recorder?.record(forDuration: 15)
        case .transcribe:
            recorder?.stop()
            
            guard let url = recorder?.url, let data = try? Data(contentsOf: url) else {
                fatalError("Recorder yielded empty data")
            }
            upload(data)
        case .stop:
            recorder?.deleteRecording()
        }

        let updates = {
            let control = (button: self.toggleButton, layer: self.toggleButton.layer)
            let state = (current: state, next: state.next)
    
            control.layer.borderColor = state.next.primaryColor.cgColor
            control.layer.borderWidth = 1
            control.layer.cornerRadius = control.button.frame.width / 2
            
            control.button.setTitle(state.next.rawValue.uppercased(), for: .normal)
            control.button.setTitleColor(state.next.secondaryColor, for: .normal)
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
    
    fileprivate var languages: [Language] = []
    fileprivate var language: Language?
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        update(state: .stop, animate: false)
        
        textView.isEditable = false
        textView.textAlignment = .center
        textView.text = ""
        
        translatedTextView.isEditable = false
        translatedTextView.textAlignment = .center
        translatedTextView.text = ""
        
//        fetchLanguages()
        
        let temp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let url = URL(fileURLWithPath: "audio.wav", isDirectory: false, relativeTo: temp)
        guard let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16_000, channels: 1, interleaved: true) else {
            fatalError("Unable to prepare recording environment")
        }
        recorder = try? AVAudioRecorder(url: url, format: format)
        recorder?.prepareToRecord()
    }
    
    
}

fileprivate extension ViewController {

    struct Language {
        let key: String
        let name: String
    }
    
    fileprivate func fetchLanguages() {
        guard let url = URL(string: "https://dev.microsofttranslator.com/languages?api-version=1.0") else {
            fatalError("Invalid streaming URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(API.speech.key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any],
            let languages = json?["text"] as? [String:[String:String]] else {
                    return
            }
            
            self.languages = languages.keys.compactMap {
                guard let name = languages[$0]?["name"] else {
                    return nil
                }
                return Language(key: $0, name: name)
            }.sorted { $0.name < $1.name }

            DispatchQueue.main.async {
                self.language = self.languages.first
                self.languagePicker.reloadAllComponents()
            }
        }
        task.resume()
    }
    
    fileprivate func upload(_ data: Data?) {
        guard let url = URL(string: "https://speech.platform.bing.com/speech/recognition/interactive/cognitiveservices/v1?language=en-US&format=simple") else {
            fatalError("Invalid streaming URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("audio/wav; codec=audio/pcm; samplerate=16000", forHTTPHeaderField: "Content-Type")
        request.setValue(API.speech.key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")

        let task = URLSession.shared.uploadTask(with: request, from: data) { (data, response, error) in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any],
                let text = json?["DisplayText"] as? String else {
                    return
            }
            
            DispatchQueue.main.async {
                self.textView.text = text
            }

            if let language = self.language {
                self.translate(text: text, to: language)
            } else {
                self.update(state: .stop)
            }
        }
        task.resume()
    }

    fileprivate func translate(text: String, to language: Language) {
        guard let url = URL(string: "https://api.microsofttranslator.com/V2/Http.svc/Translate?to=\(language.key)&text=\(text.sanitizedForQuery)") else {
            fatalError("Invalid streaming URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("582d6e4efafa434ca32e74d6c4de72f9", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
                return
            }
            
            DispatchQueue.main.async {
                self.translatedTextView.text = ""
            }
            
            self.update(state: .stop)
        }
        task.resume()
    }
    
}

extension ViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languages.count
    }
    
}

extension ViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        language = languages[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.languages[row].name
    }
    
}

extension String {
    
    var sanitizedForQuery: String {
        return trimmingCharacters(in: .whitespacesAndNewlines).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
    
}
