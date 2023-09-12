import AVFoundation

#if os(iOS)
extension AVCaptureDevice.Format {
	var canUseMultiCam: Bool {
		if #available(iOS 13.0, *) {
			return true
		}
		return false
	}
}

import UIKit
/// The namespace of DeviceUtil.
public enum DeviceUtil {
    /// Looks up the AVCaptureVideoOrientation by a Notification.
    public static func videoOrientation(by notification: Notification) -> AVCaptureVideoOrientation? {
        guard let device: UIDevice = notification.object as? UIDevice else {
            return nil
        }
        return videoOrientation(by: device.orientation)
    }

    /// Looks up the  AVCaptureVideoOrientation by an UIDeviceOrientation.
    public static func videoOrientation(by orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation? {
        switch orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return nil
        }
    }

    /// Looks up the AVCaptureVideoOrientation by an UIInterfaceOrientation.
    public static func videoOrientation(by orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation? {
        switch orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return nil
        }
    }

    /// Device is connected a headphone or not.
    public static func isHeadphoneConnected(_ ports: Set<AVAudioSession.Port> = [.headphones, .bluetoothLE, .bluetoothHFP, .bluetoothA2DP]) -> Bool {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        for description in outputs where ports.contains(description.portType) {
            return true
        }
        return false
    }

    /// Device is disconnected a headphone or not.
    public static func isHeadphoneDisconnected(_ notification: Notification, ports: Set<AVAudioSession.Port> = [.headphones, .bluetoothLE, .bluetoothHFP, .bluetoothA2DP]) -> Bool {
        guard let previousRoute = notification.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription else {
            return false
        }
        var isHeadohoneConnected = false
        for output in previousRoute.outputs where ports.contains(output.portType) {
            isHeadohoneConnected = true
            break
        }
        if !isHeadohoneConnected {
            return false
        }
        return !DeviceUtil.isHeadphoneConnected(ports)
    }
}
#elseif os(macOS)
extension AVCaptureDevice.Format {
    var canUseMultiCam: Bool {
        return true
    }
}
#endif

#if os(iOS) || os(macOS)
extension AVFrameRateRange {
//    func clamp(rate: Float64) -> Float64 {
//        max(minFrameRate, min(maxFrameRate, rate))
//    }
//
//    func contains(frameRate: Float64) -> Bool {
//        (minFrameRate...maxFrameRate) ~= frameRate
//    }
}

//extension AVCaptureDevice.Format {
//    func isFrameRateSupported(_ frameRate: Float64) -> Bool {
//        var durations: [CMTime] = []
//        var frameRates: [Float64] = []
//        for range in videoSupportedFrameRateRanges {
//            if range.minFrameRate == range.maxFrameRate {
//                durations.append(range.minFrameDuration)
//                frameRates.append(range.maxFrameRate)
//                continue
//            }
//            if range.contains(frameRate: frameRate) {
//                return true
//            }
//            return false
//        }
//        let diff = frameRates.map { abs($0 - frameRate) }
//        if let minElement: Float64 = diff.min() {
//            for i in 0..<diff.count where diff[i] == minElement {
//                return true
//            }
//        }
//        return false
//    }
//}

#elseif os(macOS)
/// The namespace of DeviceUtil.
public enum DeviceUtil {
    /// Lookup device by localizedName and mediaType.
    public static func device(withLocalizedName: String, mediaType: AVMediaType) -> AVCaptureDevice? {
        AVCaptureDevice.devices().first {
            $0.hasMediaType(mediaType) && $0.localizedName == withLocalizedName
        }
    }
}
#endif
