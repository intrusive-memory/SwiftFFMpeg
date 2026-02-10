# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

For detailed project documentation, architecture, and development guidelines, see **[AGENTS.md](AGENTS.md)**.

## Quick Reference

**Project**: SwiftFFMpeg - Swift wrapper for FFmpeg API for audio/video processing

**Version**: 8.0.1 | **FFmpeg**: 8.0 | **Platform**: macOS 26.0+ | **Swift**: 6.2+

**Status**: Experimental - not production-ready

**Key Components**:
- Format I/O: `AVFormatContext`, `AVIO`, `AVStream`
- Codecs: `AVCodec`, `AVCodecContext`, `AVCodecParameters`
- Frames/Packets: `AVFrame`, `AVPacket` (manual memory management via `unref()`)
- Audio: `SwrContext` (resampling), `AVSampleFormat`, filters
- Video: `SwsContext` (scaling), `AVPixelFormat`, filters
- Filtering: `AVFilter` (audio/video filter graphs)

**Important Notes**:
- ONLY supports macOS 26.0+ (NEVER add code for older platforms)
- MUST use `xcodebuild` for building, NOT `swift build`
- ALWAYS call `unref()` on packets and frames after use (manual memory management)
- Requires FFmpeg 8.0 installed via Homebrew (`brew install ffmpeg`)
- Not thread-safe by default - synchronize access manually
- See [AGENTS.md](AGENTS.md) for complete workflow, patterns, and extended documentation

**Memory Management Pattern**:
```swift
let pkt = AVPacket()
defer { pkt.unref() }  // Always cleanup

let frame = AVFrame()
defer { frame.unref() }  // Always cleanup
```

**Build Commands**:
```bash
xcodebuild -scheme SwiftFFmpeg -destination 'platform=macOS,arch=arm64' build
xcodebuild -scheme SwiftFFmpeg -destination 'platform=macOS,arch=arm64' test
```
