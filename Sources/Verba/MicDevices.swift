import Foundation
import CoreAudio

/// Enumerate CoreAudio input devices and read/set the system default input.
/// Used to let the user pick which microphone Verba records from. We select a
/// device by switching the default input around a recording (and restoring it
/// after), which keeps the proven AVAudioRecorder pipeline untouched.
enum MicDevices {

    struct Device: Identifiable, Equatable {
        let id: AudioDeviceID
        let uid: String      // stable across reconnects; what we persist
        let name: String
    }

    private static func address(_ selector: AudioObjectPropertySelector,
                                _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: kAudioObjectPropertyElementMain)
    }

    /// All devices that expose at least one input channel, in CoreAudio order.
    static func inputs() -> [Device] {
        var addr = address(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size) == noErr else { return [] }
        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        guard count > 0 else { return [] }
        var ids = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &ids) == noErr else { return [] }

        return ids.compactMap { id in
            guard inputChannelCount(id) > 0, let uid = stringProp(id, kAudioDevicePropertyDeviceUID) else { return nil }
            let name = stringProp(id, kAudioObjectPropertyName, scope: kAudioObjectPropertyScopeGlobal) ?? "Microphone"
            return Device(id: id, uid: uid, name: name)
        }
    }

    /// UID of the current system default input device, if any.
    static func defaultInputUID() -> String? {
        guard let id = defaultInputID() else { return nil }
        return stringProp(id, kAudioDevicePropertyDeviceUID)
    }

    /// Human-readable name of the current system default input device, if any. Read straight off the
    /// device (exactly like `defaultInputUID`) rather than by scanning `inputs()`, so naming the
    /// device stays two property reads instead of a full enumeration of the audio hardware.
    /// This is what lets a failed capture NAME the device it recorded from.
    static func defaultInputName() -> String? {
        guard let id = defaultInputID() else { return nil }
        return stringProp(id, kAudioObjectPropertyName)
    }

    static func defaultInputID() -> AudioDeviceID? {
        var addr = address(kAudioHardwarePropertyDefaultInputDevice)
        var dev = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &dev) == noErr, dev != 0 else { return nil }
        return dev
    }

    /// Resolve a persisted UID back to a live device id.
    ///
    /// nil means "no such input device is connected right now", and every caller MUST read that as
    /// "record from the system default input" rather than as a failure. A saved mic that is
    /// unplugged, powered off, or came from another Mac is the normal case, not a broken one — the
    /// recording has to happen anyway. (See `AudioRecorder.chosenMicToApply`.)
    static func id(forUID uid: String) -> AudioDeviceID? {
        guard !uid.isEmpty else { return nil }
        return inputs().first { $0.uid == uid }?.id
    }

    static func name(forUID uid: String) -> String? {
        inputs().first { $0.uid == uid }?.name
    }

    @discardableResult
    static func setDefaultInput(_ id: AudioDeviceID) -> Bool {
        var addr = address(kAudioHardwarePropertyDefaultInputDevice)
        var dev = id
        let st = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil,
                                            UInt32(MemoryLayout<AudioDeviceID>.size), &dev)
        return st == noErr
    }

    // MARK: - Property readers

    private static func inputChannelCount(_ id: AudioDeviceID) -> Int {
        var addr = address(kAudioDevicePropertyStreamConfiguration, kAudioObjectPropertyScopeInput)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size) == noErr, size > 0 else { return 0 }
        let bufList = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { bufList.deallocate() }
        guard AudioObjectGetPropertyData(id, &addr, 0, nil, &size, bufList) == noErr else { return 0 }
        let abl = UnsafeMutableAudioBufferListPointer(bufList.assumingMemoryBound(to: AudioBufferList.self))
        return abl.reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private static func stringProp(_ id: AudioDeviceID, _ selector: AudioObjectPropertySelector,
                                   scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal) -> String? {
        var addr = address(selector, scope)
        var cf: CFString? = nil
        var size = UInt32(MemoryLayout<CFString?>.size)
        let st = withUnsafeMutablePointer(to: &cf) { ptr -> OSStatus in
            AudioObjectGetPropertyData(id, &addr, 0, nil, &size, ptr)
        }
        guard st == noErr, let s = cf else { return nil }
        return s as String
    }
}
