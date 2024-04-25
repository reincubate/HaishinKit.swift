import AVFoundation

/// The IOAudioMixerError  error domain codes.
public enum IOAudioMixerError: Swift.Error {
    /// Mixer is unable to provide input data.
    case unableToProvideInputData
    /// Mixer is unable to make sure that all resamplers output the same audio format.
    case unableToEnforceAudioFormat
}

protocol IOAudioMixerDelegate: AnyObject {
    func audioMixer(_ audioMixer: any IOAudioMixerConvertible, track: UInt8, didInput buffer: AVAudioPCMBuffer, when: AVAudioTime)
    func audioMixer(_ audioMixer: any IOAudioMixerConvertible, didOutput audioFormat: AVAudioFormat)
    func audioMixer(_ audioMixer: any IOAudioMixerConvertible, didOutput audioBuffer: AVAudioPCMBuffer, when: AVAudioTime)
    func audioMixer(_ audioMixer: any IOAudioMixerConvertible, errorOccurred error: IOAudioUnitError)
}

/// Constraints on the audio mixier settings.
public struct IOAudioMixerSettings {
    /// The default value.
    public static let `default` = IOAudioMixerSettings()

    /// Specifies the channels of audio output.
    public let channels: UInt32
    /// Specifies the sampleRate of audio output.
    public let sampleRate: Float64
    /// Specifies the muted that indicates whether the audio output is muted.
    public var isMuted = false
    /// Specifies the main track number.
    public var mainTrack: UInt8 = 0
    /// Specifies the track settings.
    public var tracks: [UInt8: IOAudioMixerTrackSettings] = .init()

    /// Creates a new instance of a settings.
    public init(
        channels: UInt32 = 0,
        sampleRate: Float64 = 0
    ) {
        self.channels = channels
        self.sampleRate = sampleRate
    }

    func invalidateAudioFormat(_ oldValue: Self) -> Bool {
        return !(sampleRate == oldValue.sampleRate &&
                    channels == oldValue.channels)
    }

    func makeAudioFormat(_ format: AVAudioFormat?) -> AVAudioFormat? {
        guard let format else {
            return nil
        }
        return .init(
            commonFormat: format.commonFormat,
            sampleRate: min(sampleRate == 0 ? format.sampleRate : sampleRate, AudioCodecSettings.maximumSampleRate),
            channels: min(channels == 0 ? format.channelCount : channels, AudioCodecSettings.maximumNumberOfChannels),
            interleaved: format.isInterleaved
        )
    }
}

protocol IOAudioMixerConvertible: AnyObject {
    var delegate: (any IOAudioMixerDelegate)? { get set }
    var settings: IOAudioMixerSettings { get set }
    var inputFormats: [UInt8: AVAudioFormat] { get }
    var outputFormat: AVAudioFormat? { get }

    func append(_ track: UInt8, buffer: CMSampleBuffer)
    func append(_ track: UInt8, buffer: AVAudioPCMBuffer, when: AVAudioTime)
}

extension IOAudioMixerConvertible {
    static func makeAudioFormat(_ formatDescription: CMFormatDescription?) -> AVAudioFormat? {
        guard var inSourceFormat = formatDescription?.audioStreamBasicDescription else {
            return nil
        }
        if inSourceFormat.mFormatID == kAudioFormatLinearPCM && kLinearPCMFormatFlagIsBigEndian == (inSourceFormat.mFormatFlags & kLinearPCMFormatFlagIsBigEndian) {
            let interleaved = !((inSourceFormat.mFormatFlags & kLinearPCMFormatFlagIsNonInterleaved) == kLinearPCMFormatFlagIsNonInterleaved)
            if let channelLayout = Self.makeChannelLayout(inSourceFormat.mChannelsPerFrame) {
                return .init(
                    commonFormat: .pcmFormatInt16,
                    sampleRate: inSourceFormat.mSampleRate,
                    interleaved: interleaved,
                    channelLayout: channelLayout
                )
            }
            return .init(
                commonFormat: .pcmFormatInt16,
                sampleRate: inSourceFormat.mSampleRate,
                channels: inSourceFormat.mChannelsPerFrame,
                interleaved: interleaved
            )
        }
        if let layout = Self.makeChannelLayout(inSourceFormat.mChannelsPerFrame) {
            return .init(streamDescription: &inSourceFormat, channelLayout: layout)
        }
        return .init(streamDescription: &inSourceFormat)
    }

    private static func makeChannelLayout(_ numberOfChannels: UInt32) -> AVAudioChannelLayout? {
        guard 2 < numberOfChannels else {
            return nil
        }
        switch numberOfChannels {
        case 4:
            return AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_AudioUnit_4)
        case 5:
            return AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_AudioUnit_5)
        case 6:
            return AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_AudioUnit_6)
        case 8:
            return AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_AudioUnit_8)
        default:
            return AVAudioChannelLayout(layoutTag: kAudioChannelLayoutTag_DiscreteInOrder | numberOfChannels)
        }
    }
}