import AVFoundation
import Foundation

#if os(iOS) || os(macOS)
extension AVCaptureDevice {
    func videoFormat(width: Int32, height: Int32, frameRate: Float64, isMultiCamSupported: Bool) -> AVCaptureDevice.Format? {
        if #available(iOS 13.0, *), isMultiCamSupported {
            return formats.first {
                $0.canUseMultiCam && $0.isFrameRateSupported(frameRate) && width <= $0.formatDescription.dimensions.width && height <= $0.formatDescription.dimensions.height
            } ?? formats.last {
                $0.canUseMultiCam && $0.isFrameRateSupported(frameRate) && $0.formatDescription.dimensions.width < width && $0.formatDescription.dimensions.height < height
            }
        } else {
            return formats.first {
                $0.isFrameRateSupported(frameRate) && width <= $0.formatDescription.dimensions.width && height <= $0.formatDescription.dimensions.height
            } ?? formats.last {
                $0.isFrameRateSupported(frameRate) && $0.formatDescription.dimensions.width < width && $0.formatDescription.dimensions.height < height
            }
        }
    }
}
#endif
