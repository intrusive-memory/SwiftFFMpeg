# AGENTS.md

This file provides comprehensive documentation for AI agents working with the SwiftFFMpeg codebase.

**Current Version**: 8.0.1 (February 2026)

---

## Project Overview

SwiftFFMpeg is a Swift wrapper for the FFmpeg API, providing Swift-native interfaces for audio and video processing. The library wraps FFmpeg's C API with Swift types, automatic memory management, and error handling.

**Status**: Experimental - not production-ready. API is subject to change.

**FFmpeg Version**: 8.0 (Homebrew)

## Project Structure

- `Sources/SwiftFFmpeg/` - Library target (Swift wrappers for FFmpeg C API)
- `Sources/Examples/` - Executable examples demonstrating usage patterns
- `Sources/CFFmpeg/` - System library module (pkg-config integration)
- `Tests/Tests/` - Unit tests for core types
- `Docs/` - Extended documentation (audio processing, concatenation)
- `Plugins/FetchFFmpegXCFrameworks/` - SPM plugin for downloading prebuilt FFmpeg frameworks

## Key Components

### Format and I/O

| File | Purpose |
|------|---------|
| `AVFormatContext.swift` | Format I/O context - opens files, reads/writes containers (MP4, MKV, etc.), stream management |
| `AVFormat.swift` | Input/output format definitions (container formats) |
| `AVIO.swift` | Custom I/O context for reading/writing data from memory or custom sources |
| `AVStream.swift` | Stream within a container (audio/video track) with codec parameters and metadata |

### Codec and Encoding/Decoding

| File | Purpose |
|------|---------|
| `AVCodec.swift` | Codec definitions - find encoders/decoders by name or ID |
| `AVCodecContext.swift` | Codec context for encoding/decoding - configuration, state management |
| `AVCodecParameters.swift` | Codec-specific parameters (resolution, sample rate, etc.) |
| `AVCodecParser.swift` | Stream parsing - extract packets from raw byte streams |

### Frames and Packets

| File | Purpose |
|------|---------|
| `AVFrame.swift` | Decoded audio/video frame - raw samples/pixels, memory-managed with `unref()` |
| `AVPacket.swift` | Encoded data packet - compressed audio/video, memory-managed with `unref()` |
| `AVBuffer.swift` | Reference-counted buffer management |
| `AVFrameSideData.swift` | Frame metadata (HDR, motion vectors, etc.) |

### Audio Processing

| File | Purpose |
|------|---------|
| `SwrContext.swift` | Audio resampling context - sample rate conversion, format conversion, channel remixing |
| `AVSampleFormat.swift` | Audio sample format definitions (int16, float, planar) |
| `AVSamples.swift` | Audio sample utilities |
| `AudioUtil.swift` | Helper functions for audio operations |

### Video Processing

| File | Purpose |
|------|---------|
| `SwsContext.swift` | Video scaling/conversion context - resolution scaling, pixel format conversion, color space conversion |
| `AVPixelFormat.swift` | Pixel format definitions (RGB, YUV, etc.) |
| `AVImage.swift` | Image buffer allocation and management |
| `VideoUtil.swift` | Helper functions for video operations |

### Filtering

| File | Purpose |
|------|---------|
| `AVFilter.swift` | Audio/video filter graph system - chain filters (silenceremove, scale, etc.), complex processing pipelines |

### Other Components

| File | Purpose |
|------|---------|
| `AVError.swift` | Error type with FFmpeg error code mapping |
| `AVOption.swift` | Generic option setting for FFmpeg objects |
| `AVLog.swift` | Logging configuration |
| `Timestamp.swift` | Time representation and conversion utilities |
| `Math.swift` | Rational number (AVRational) for precise timing |
| `AVConcat.swift` | Concatenation protocol for joining media files |
| `AVBitStreamFilter.swift` | Bitstream filters for modifying encoded packets |

## Core Types and Memory Management

### Memory Management Rules

**CRITICAL**: FFmpeg uses manual memory management. Always call `unref()` on frames and packets after use.

```swift
let pkt = AVPacket()
defer { pkt.unref() }  // Release packet memory

let frame = AVFrame()
defer { frame.unref() }  // Release frame memory
```

**Cleanup pattern:**
- Packets and frames: `unref()` after use
- Contexts: Automatically deallocated via `deinit`
- Buffers: Reference-counted via `AVBuffer`

### Core Workflow Pattern

1. **Open input**: `AVFormatContext(url:)` opens a media file
2. **Find streams**: `findStreamInfo()` reads stream metadata
3. **Setup decoder**: Create `AVCodecContext`, configure with stream parameters
4. **Read packets**: `readFrame(into:)` reads encoded packets
5. **Decode frames**: `sendPacket()` + `receiveFrame()` decodes to raw frames
6. **Process**: Apply filters, resample audio, scale video
7. **Encode frames**: `sendFrame()` + `receivePacket()` encodes to packets
8. **Write output**: `interleavedWriteFrame()` writes packets to file

## Example Patterns

### Read and Decode Audio

```swift
import SwiftFFmpeg

let fmtCtx = try AVFormatContext(url: "input.m4a")
try fmtCtx.findStreamInfo()

guard let stream = fmtCtx.audioStream else { fatalError("No audio") }
guard let codec = AVCodec.findDecoderById(stream.codecParameters.codecId) else {
    fatalError("Decoder not found")
}

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

// Convert frame
let outFrame = AVFrame()
outFrame.sampleRate = 44100
outFrame.sampleFormat = .int16
outFrame.channelLayout = AVChannelLayoutMono
outFrame.sampleCount = try resampler.getOutSamples(Int64(inputFrame.sampleCount))
try outFrame.allocBuffer()

try resampler.convert(
    dst: outFrame.data.baseAddress!,
    dstCount: outFrame.sampleCount,
    src: UnsafeMutablePointer(mutating: inputFrame.data.baseAddress!),
    srcCount: inputFrame.sampleCount
)
```

### Apply Audio Filter

```swift
// Remove trailing silence by reversing, removing start silence, and reversing back
let filterString = "areverse,silenceremove=start_periods=1:start_threshold=0.001,areverse"

let filterGraph = AVFilterGraph()
// Configure filter graph with filterString
// Process frames through filter graph
```

### Encode and Export

```swift
let outputCtx = try AVFormatContext(format: nil, filename: "output.m4a")

guard let encoder = AVCodec.findEncoderById(.AAC) else {
    fatalError("Encoder not found")
}

let outputStream = outputCtx.addStream(codec: encoder)
let encoderCtx = AVCodecContext(codec: encoder)

encoderCtx.sampleRate = 44100
encoderCtx.channelLayout = AVChannelLayoutStereo
encoderCtx.sampleFormat = .floatPlanar
encoderCtx.bitRate = 256000

try encoderCtx.openCodec()
outputStream.codecParameters.copy(from: encoderCtx)

outputCtx.pb = try AVIOContext(url: "output.m4a", flags: .write)
try outputCtx.writeHeader()

// Encode frames...

try outputCtx.writeTrailer()
```

## Common Codec IDs

| Format | Codec ID | Description |
|--------|----------|-------------|
| AAC (M4A) | `.AAC` | High quality compressed audio |
| MP3 | `.MP3` | Universal compressed audio |
| WAV | `.PCM_S16LE` | Uncompressed little-endian PCM |
| AIFF | `.PCM_S16BE` | Uncompressed big-endian PCM |
| FLAC | `.FLAC` | Lossless compressed audio |
| H.264 | `.H264` | High quality video codec |
| HEVC/H.265 | `.HEVC` | Next-gen video codec |

## Channel Layouts

```swift
AVChannelLayoutMono         // 1 channel
AVChannelLayoutStereo       // 2 channels (L, R)
AVChannelLayout2Point1      // 3 channels (L, R, LFE)
AVChannelLayout5Point1      // 6 channels (L, R, C, LFE, SL, SR)
AVChannelLayout7Point1      // 8 channels
```

## Sample Formats

```swift
.int16         // Signed 16-bit (CD quality, interleaved)
.int32         // Signed 32-bit
.float         // 32-bit float (interleaved)
.floatPlanar   // 32-bit float (planar - separate buffers per channel)
.int16Planar   // Signed 16-bit (planar)
```

**Interleaved vs Planar:**
- **Interleaved**: Samples from all channels are mixed (L, R, L, R, L, R...)
- **Planar**: Each channel has its own buffer (LLLLLL..., RRRRRR...)

## Build and Test

**CRITICAL**: This library links against system FFmpeg via pkg-config. You MUST have FFmpeg installed.

### Prerequisites

```bash
brew install ffmpeg
```

### Build

**Use xcodebuild** (per global instructions):

```bash
xcodebuild -scheme SwiftFFmpeg -destination 'platform=macOS,arch=arm64' build
```

For examples:

```bash
xcodebuild -scheme Examples -destination 'platform=macOS,arch=arm64' build
# Binary at DerivedData/.../Build/Products/Debug/Examples
```

### Test

```bash
xcodebuild -scheme SwiftFFmpeg -destination 'platform=macOS,arch=arm64' test
```

## Dependencies

| Package | Purpose |
|---------|---------|
| CFFmpeg (system library) | FFmpeg C API via pkg-config (libavformat, libavcodec, libavutil, libavfilter, libswscale, libswresample) |
| SwiftFixtureManager | Test fixture management |

**No Swift package dependencies** - this is a low-level wrapper around FFmpeg.

## Design Patterns

- **Swift wrappers**: Each FFmpeg C type has a Swift class with automatic memory management
- **Error handling**: FFmpeg error codes are thrown as `AVError` with descriptive messages
- **Reference counting**: `AVFrame` and `AVPacket` use manual `unref()`, contexts use Swift ARC
- **Type safety**: Enums for codec IDs, sample formats, pixel formats, channel layouts
- **Memory safety**: Uses `defer` pattern for cleanup, RAII via `deinit`
- **Sendable conformance**: Types are not Sendable - use on a single thread or synchronize access

## Extended Documentation

See `Docs/` directory for detailed guides:

- **AUDIO_PROCESSING.md**: Silence detection/removal, format export, resampling, common operations
- **CONCAT_USAGE.md**: Concatenating multiple audio/video files

## Workflow

- Work on `development` branch
- PR to `main` (protected, requires CI)
- See `.claude/WORKFLOW.md` for complete workflow requirements

## CI/CD

GitHub Actions tests on macOS 26+ with Swift 6.2+. All tests must pass before merge.

## License

GNU Lesser General Public License v2.1 (same as FFmpeg)

## Known Limitations

- Experimental - API may change
- Not all FFmpeg features are wrapped
- Some advanced features require direct C API usage
- Not thread-safe by default - synchronize access manually
- Requires system FFmpeg installation (Homebrew on macOS)
