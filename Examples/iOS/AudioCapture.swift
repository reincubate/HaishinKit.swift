import AVFoundation
import Foundation
import HaishinKit

protocol AudioCaptureDelegate: AnyObject {
    func audioCapture(_ audioCapture: AudioCapture, buffer: AVAudioBuffer, time: AVAudioTime)
}

final class AudioCapture {
    var isRunning: Atomic<Bool> = .init(false)
    var delegate: (any AudioCaptureDelegate)?
    private let audioEngine = AVAudioEngine()
}

extension AudioCapture: Running {
    func startRunning() {
        guard !isRunning.value else {
            return
        }
        let input = audioEngine.inputNode
        let mixer = audioEngine.mainMixerNode
        audioEngine.connect(input, to: mixer, format: input.inputFormat(forBus: 0))
        input.installTap(onBus: 0, bufferSize: 1024, format: input.inputFormat(forBus: 0)) { buffer, when in
            self.delegate?.audioCapture(self, buffer: buffer, time: when)
        }
        do {
            try audioEngine.start()
            isRunning.mutate { $0 = true }
        } catch {
            logger.error(error)
        }
    }

    func stopRunning() {
        guard isRunning.value else {
            return
        }
        audioEngine.stop()
        isRunning.mutate { $0 = false }
    }
}
