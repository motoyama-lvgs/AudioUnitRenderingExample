//
//  AudioSession.swift
//  AudioUnitRenderingExample
//
//  Created by Yuki Yasoshima on 2020/07/26.
//  Copyright © 2020 Yuki Yasoshima. All rights reserved.
//

import Foundation
import AVFoundation
import Combine

private func printAudioSession(message: String) {
    let session = AVAudioSession.sharedInstance()
    print("AVAudioSession \(message) sampleRate : \(session.sampleRate) - outputChannelCount : \(session.outputNumberOfChannels) - inputChannelCount : \(session.inputNumberOfChannels)")
}

class AudioSession {
    // singleton化
    static let shared = AudioSession()
    
    // combine framework
    let rerouteSubject = PassthroughSubject<Void, Never>()
    let lostSubject = PassthroughSubject<Void, Never>()
    
    // outputNumberOfChannels
    // : The current number of hardware output channels. Is key-value observable.
    var hasOutput: Bool { session.outputNumberOfChannels > 0 }
    // isInputAvailable
    // : True if input hardware is available.
    // inputNumberOfChannels
    // : The current number of hardware input channels. Is key-value observable.
    var hasInput: Bool { session.isInputAvailable && session.inputNumberOfChannels > 0 }
    // rxでいうところのdispose
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let session = AVAudioSession.sharedInstance()
        
        // イヤホン、airpodsなどの接続の際に発火する
        let routePublisher = NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification, object: session)
        // OperationQueue
        // : https://qiita.com/shiz/items/693241f41344a9df6d6f
        let routeShared = routePublisher.map { _ in Void() }.receive(on: OperationQueue.main).share()
        routeShared.sink { _ in printAudioSession(message: "routeChanged") }.store(in: &cancellables)
        // rerouteSubjectに流す
        routeShared.subscribe(rerouteSubject).store(in: &cancellables)
        
        // interruptionNotification
        // : Notification sent to registered listeners when the system has interrupted the audio session and when the interruption has ended.
        let interruptionPublisher = NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification, object: session)
        // mediaServicesWereLostNotification
        // : Notification sent to registered listeners if the media server is killed.
        let lostPublisher = NotificationCenter.default.publisher(for: AVAudioSession.mediaServicesWereLostNotification, object: session)
        // mediaServicesWereResetNotification
        // : Notification sent to registered listeners when the media server restarts.
        let resetPublisher = NotificationCenter.default.publisher(for: AVAudioSession.mediaServicesWereResetNotification, object: session)
        
        // lostSubjectに流す
        interruptionPublisher
            .merge(with: lostPublisher, resetPublisher)
            .map { _ in Void() }
            .receive(on: OperationQueue.main)
            .subscribe(lostSubject)
            .store(in: &cancellables)
    }
    
    func activate(category: AVAudioSession.Category) throws {
        let session = AVAudioSession.sharedInstance()
        // categoryのset(record/playbackなど)
        try session.setCategory(category)
        // active化
        try session.setActive(true, options: [])
        
        printAudioSession(message: "activated")
    }
    
    func deactivate() {
        try? session.setActive(false, options: [])
    }
}

private extension AudioSession {
    var session: AVAudioSession { AVAudioSession.sharedInstance() }
}
