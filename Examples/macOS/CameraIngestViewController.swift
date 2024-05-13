import AVFoundation
import Cocoa
import HaishinKit
import VideoToolbox

extension NSPopUpButton {
    fileprivate func present(mediaType: AVMediaType) {
        let devices = AVCaptureDevice.devices(for: mediaType)
        devices.forEach {
            self.addItem(withTitle: $0.localizedName)
        }
    }
}

final class CameraIngestViewController: NSViewController {
    @IBOutlet private weak var lfView: MTHKView!
    @IBOutlet private weak var audioPopUpButton: NSPopUpButton!
    @IBOutlet private weak var cameraPopUpButton: NSPopUpButton!
    @IBOutlet private weak var urlField: NSTextField!
    private let netStreamSwitcher: NetStreamSwitcher = .init()
    private var stream: IOStream {
        return netStreamSwitcher.stream
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        urlField.stringValue = Preference.defaultInstance.uri ?? ""
        audioPopUpButton?.present(mediaType: .audio)
        cameraPopUpButton?.present(mediaType: .video)
        netStreamSwitcher.uri = Preference.defaultInstance.uri ?? ""
        lfView?.attachStream(stream)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        stream.attachAudio(DeviceUtil.device(withLocalizedName: audioPopUpButton.titleOfSelectedItem!, mediaType: .audio))

        var audios = AVCaptureDevice.devices(for: .audio)
        audios.removeFirst()
        if let device = audios.first, FeatureUtil.isEnabled(for: .multiTrackAudioMixing) {
            stream.attachAudio(device, track: 1)
        }

        stream.attachCamera(DeviceUtil.device(withLocalizedName: cameraPopUpButton.titleOfSelectedItem!, mediaType: .video), track: 0)
        var videos = AVCaptureDevice.devices(for: .video)
        videos.removeFirst()
        if let device = videos.first {
            stream.attachCamera(device, track: 1)
        }
    }

    @IBAction private func publishOrStop(_ sender: NSButton) {
        // Publish
        if sender.title == "Publish" {
            sender.title = "Stop"
            netStreamSwitcher.open(.ingest)
        } else {
            // Stop
            sender.title = "Publish"
            netStreamSwitcher.close()
        }
    }

    @IBAction private func orientation(_ sender: AnyObject) {
        lfView.rotate(byDegrees: 90)
    }

    @IBAction private func mirror(_ sender: AnyObject) {
        stream.videoCapture(for: 0)?.isVideoMirrored.toggle()
    }

    @IBAction private func selectAudio(_ sender: AnyObject) {
        let device = DeviceUtil.device(withLocalizedName: audioPopUpButton.titleOfSelectedItem!, mediaType: .audio)
        stream.attachAudio(device)
    }

    @IBAction private func selectCamera(_ sender: AnyObject) {
        let device = DeviceUtil.device(withLocalizedName: cameraPopUpButton.titleOfSelectedItem!, mediaType: .video)
        stream.attachCamera(device, track: 0)
    }
}
