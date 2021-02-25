//
//  InputMeter.swift
//  AudioUnitRenderingExample
//
//  Created by Yuki Yasoshima on 2020/07/24.
//  Copyright © 2020 Yuki Yasoshima. All rights reserved.
//

import Foundation
import Combine
import AVFoundation

class InputMeter {
    var value: InputMeterRendererValue { renderer.value }
    // subjectをpublisherに変換しているイメージ
    var lostPublisher: AnyPublisher<Void, Never> { lostSubject.eraseToAnyPublisher() }
    
    private let session: AudioSession
    private var engine: AVAudioEngine?
    private let renderer = InputMeterRenderer()
    private let lostSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    enum StartError: Error {
        case setupAudioSession
        case inputUnavailable
        case startEngine
    }
    
    // default値を.sharedでつっこむ。型から類推してくれてるっぽい
    init(session: AudioSession = .shared) {
        self.session = session
    }
    
    deinit {
        // 後始末
        stop()
    }
    
    func start() throws {
        do {
            // sessionをactivate
            try session.activate(category: .record)
        } catch {
            throw StartError.setupAudioSession
        }
        
        // 入力関連のhardware/channelが有効かcheck
        guard session.hasInput else {
            throw StartError.inputUnavailable
        }
        
        // イヤホン/aipodsの切り替えの際に発火
        AudioSession.shared.rerouteSubject.sink { [weak self] in
            self?.reroute()
        }.store(in: &cancellables)
        
        // 次のpublisherに渡しているだけ
        AudioSession.shared.lostSubject.subscribe(lostSubject).store(in: &cancellables)
        
        do {
            // engin開始
            try setupAndStartEngine()
        } catch {
            throw StartError.startEngine
        }
    }
    
    func stop() {
        // engineを止める(消す)
        disposeEngine()
        // disposeの中身を全部消す
        cancellables.removeAll()
        // deactive
        session.deactivate()
    }
}

private extension InputMeter {
    func setupAndStartEngine() throws {
        // avaudioenginのinstance作成
        let engine = AVAudioEngine()
        // 0から開始?(input)
        let inputFormat = engine.inputNode.inputFormat(forBus: 0)
        // objective-c経由でsinknodeを作成
        let sinkNode = renderer.makeSineNode(sampleRate: inputFormat.sampleRate);
        // enginにattach
        engine.attach(sinkNode)
        // engine内のinputnodeをsinknodeにつなげる
        engine.connect(engine.inputNode, to: sinkNode, format: nil)
        // 0から開始?(output)
        let outputFormat = engine.inputNode.outputFormat(forBus: 0)
        print("InputMeter Engine - format : \(outputFormat)")
        
        // ここで初めてスタート
        try engine.start()
        
        // instanceを保管しておく
        self.engine = engine
    }
    
    func disposeEngine() {
        // 止めてからnilにする
        engine?.stop()
        engine = nil
    }
    
    // hardwareに変更があったときに再起動するノリ
    func reroute() {
        disposeEngine()
        
        do {
            try setupAndStartEngine()
        } catch {
            // エラーの場合はlostSubjectにsendする
            self.lostSubject.send()
        }
    }
}
