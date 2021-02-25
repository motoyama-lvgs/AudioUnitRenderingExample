//
//  InputMeterViewController.swift
//  AudioUnitRenderingExample
//
//  Created by Yuki Yasoshima on 2020/07/25.
//  Copyright © 2020 Yuki Yasoshima. All rights reserved.
//

import UIKit
import Combine

class InputMeterViewController: UIViewController {
    @IBOutlet private weak var baseView: UIView!
    @IBOutlet private weak var levelConstraint: NSLayoutConstraint!
    @IBOutlet private weak var peakConstraint: NSLayoutConstraint!
    @IBOutlet private weak var meterLabel: UILabel!
    
    private let meter = InputMeter()
    private var displayLink: CADisplayLink?
    
    // Set: Arrayと違って、①値はUniqueになり、②順序は担保されない
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        meter.lostPublisher.sink { [weak self] _ in
            // lostした場合はalertが出る
            self?.showAlert(title: "Lost", message: nil)
        }.store(in: &cancellables)
        
        // 多分音の可視化されている部分の動きをここの制約で制御している
        levelConstraint.constant = 0.0
        peakConstraint.constant = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            // 計測開始
            try meter.start()
        } catch {
            let message = (error as? InputMeter.StartError).flatMap { "\($0)" }
            showAlert(title: "Error", message: message)
        }
        
        // CADisplayLink: 画面のリフレッシュレートと同期して描画させるタイマーオブジェクト
        displayLink = CADisplayLink(target: self, selector: #selector(updateMeter))
        // 生成したCADisplayLinkのinstanceをmain loopに追加してあげている感じ
        displayLink?.add(to: .main, forMode: .default)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 後始末
        displayLink?.invalidate()
        displayLink = nil
        // 計測終了
        meter.stop()
    }
}

private extension InputMeterViewController {
    func showAlert(title: String, message: String?) {
        // ありふれたalert
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default) { [weak self] _ in self?.popViewController() })
        present(alert, animated: true, completion: nil)
    }
    
    func popViewController() {
        // popToRootViewController: 1番最初のcontrollerに戻る
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func updateMeter() {
        let value = meter.value
        
        // barの横幅を元に、levelとpeakの長さを算出し制約に反映する
        let maxWidth = baseView.frame.width
        levelConstraint.constant = CGFloat(value.level) * maxWidth
        peakConstraint.constant = CGFloat(value.peak) * maxWidth
        
        // 表示用にdecibelに変換
        let dbValue = String(format: "%.1f", decibelFromLinear(value.peak))
        meterLabel.text = "\(dbValue) dB"
    }
}
