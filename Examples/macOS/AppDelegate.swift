import Cocoa
import HaishinKit
import Logboard

let logger = LBLogger.with("com.haishinkit.Exsample.macOS")

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        LBLogger.with(HaishinKitIdentifier).level = .info
        FeatureUtil.setEnabled(for: .multiTrackAudioMixing, isEnabled: true)
    }
}
