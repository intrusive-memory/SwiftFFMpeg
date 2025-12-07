# CLAUDE.md

SwiftFFmpeg is a Swift wrapper for the FFmpeg API for audio/video processing.

**Status**: Experimental | **Platform**: macOS 26.0+ | **Swift**: 6.2+

## Build

```bash
brew install ffmpeg    # Install FFmpeg
swift build            # Build
swift test             # Test
```

## Memory Management

**CRITICAL**: Always `unref()` packets and frames after use:

```swift
let pkt = AVPacket()
defer { pkt.unref() }

let frame = AVFrame()
defer { frame.unref() }
```

## Core Usage Patterns

### Read Media File

```swift
import SwiftFFmpeg

let fmtCtx = try AVFormatContext(url: "input.mp4")
try fmtCtx.findStreamInfo()

guard let stream = fmtCtx.audioStream else { fatalError("No audio") }
```

### Decode Frames

```swift
let codec = AVCodec.findDecoderById(stream.codecParameters.codecId)!
let codecCtx = AVCodecContext(codec: codec)
try codecCtx.setParameters(stream.codecParameters)
try codecCtx.openCodec()

let pkt = AVPacket()
let frame = AVFrame()

while let _ = try? fmtCtx.readFrame(into: pkt) {
    defer { pkt.unref() }
    if pkt.streamIndex != stream.index { continue }

    try codecCtx.sendPacket(pkt)
    while true {
        do {
            try codecCtx.receiveFrame(frame)
            // Process frame
            frame.unref()
        } catch let err as AVError where err == .tryAgain || err == .eof {
            break
        }
    }
}
```

### Resample Audio

```swift
let resampler = try SwrContext(
    inputChannelLayout: AVChannelLayoutStereo,
    inputSampleFormat: .floatPlanar,
    inputSampleRate: 48000,
    outputChannelLayout: AVChannelLayoutMono,
    outputSampleFormat: .int16,
    outputSampleRate: 44100
)
try resampler.initialize()
```

### Remove Trailing Silence

```swift
// Filter string: reverse → remove start silence → reverse back
let filterString = "areverse,silenceremove=start_periods=1:start_threshold=0.001,areverse"
```

See `docs/AUDIO_PROCESSING.md` for complete implementation.

## Common Codec IDs

| Format | Codec ID |
|--------|----------|
| AAC (M4A) | `.AAC` |
| MP3 | `.MP3` |
| WAV | `.PCM_S16LE` |
| AIFF | `.PCM_S16BE` |
| FLAC | `.FLAC` |

## Channel Layouts

```swift
AVChannelLayoutMono      // 1 channel
AVChannelLayoutStereo    // 2 channels
AVChannelLayout5Point1   // 6 channels (5.1)
```

## Sample Formats

```swift
.int16        // Signed 16-bit (CD quality)
.float        // 32-bit float
.floatPlanar  // Planar 32-bit float
```

## Key Directories

- `Sources/SwiftFFmpeg/` - Library source
- `Sources/Examples/` - Working examples
- `docs/` - Extended documentation

## Workflow

- Work on `development` branch
- PR to `main` (protected)
- See `.claude/WORKFLOW.md` for details
