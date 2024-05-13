import HaishinKit
import Logboard
import MediaPlayer
import ReplayKit
import VideoToolbox

let logger = LBLogger.with(HaishinKitIdentifier)

@available(iOS 10.0, *)
open class SampleHandler: RPBroadcastSampleHandler {
    private var slider: UISlider?

    private lazy var rtmpConnection: RTMPConnection = {
        let conneciton = RTMPConnection()
        conneciton.addEventListener(.rtmpStatus, selector: #selector(rtmpStatusEvent), observer: self)
        conneciton.addEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        return conneciton
    }()

    private lazy var rtmpStream: RTMPStream = {
        FeatureUtil.setEnabled(for: .multiTrackAudioMixing, isEnabled: true)
        return RTMPStream(connection: rtmpConnection)
    }()

    private var needVideoConfiguration = true

    deinit {
        rtmpConnection.removeEventListener(.ioError, selector: #selector(rtmpErrorHandler), observer: self)
        rtmpConnection.removeEventListener(.rtmpStatus, selector: #selector(rtmpStatusEvent), observer: self)
    }

    override open func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        /*
         let socket = SocketAppender()
         socket.connect("192.168.1.9", port: 22222)
         logger.level = .debug
         logger.appender = socket
         logger.level = .debug
         */
        LBLogger.with(HaishinKitIdentifier).level = .info
        // rtmpStream.audioMixerSettings = .init(sampleRate: 0, channels: 2)
        rtmpStream.audioMixerSettings.tracks[1] = .default
        rtmpConnection.connect(Preference.defaultInstance.uri!, arguments: nil)
        // The volume of the audioApp can be obtained even when muted. A hack to synchronize with the volume.
        DispatchQueue.main.async {
            let volumeView = MPVolumeView(frame: CGRect.zero)
            if let slider = volumeView.subviews.compactMap({ $0 as? UISlider }).first {
                self.slider = slider
            }
        }
    }

    override open func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            if needVideoConfiguration, let dimensions = sampleBuffer.formatDescription?.dimensions {
                rtmpStream.videoSettings.videoSize = .init(
                    width: CGFloat(dimensions.width),
                    height: CGFloat(dimensions.height)
                )
                rtmpStream.videoSettings.profileLevel = kVTProfileLevel_H264_Baseline_AutoLevel as String
                needVideoConfiguration = false
            }
            rtmpStream.append(sampleBuffer)
        case .audioMic:
            if CMSampleBufferDataIsReady(sampleBuffer) {
                rtmpStream.append(sampleBuffer, track: 0)
            }
        case .audioApp:
            if let volume = slider?.value {
                rtmpStream.audioMixerSettings.tracks[1]?.volume = volume * 0.5
            }
            if CMSampleBufferDataIsReady(sampleBuffer) {
                rtmpStream.append(sampleBuffer, track: 1)
            }
        @unknown default:
            break
        }
    }

    @objc
    private func rtmpErrorHandler(_ notification: Notification) {
        logger.info(notification)
        rtmpConnection.connect(Preference.defaultInstance.uri!)
    }

    @objc
    private func rtmpStatusEvent(_ status: Notification) {
        let e = Event.from(status)
        logger.info(e)
        guard
            let data: ASObject = e.data as? ASObject,
            let code: String = data["code"] as? String else {
            return
        }
        switch code {
        case RTMPConnection.Code.connectSuccess.rawValue:
            rtmpStream.publish(Preference.defaultInstance.streamName!)
        default:
            break
        }
    }
}
