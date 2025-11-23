# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftFFmpeg is a Swift wrapper for the FFmpeg API, providing comprehensive audio/video processing capabilities. The library is experimental and under active development.

**Status**: ⚠️ EXPERIMENTAL - NOT READY FOR PRODUCTION

**Platforms**: macOS 26.0+

## ⚠️ Version Management

SwiftFFmpeg maintains separate branches for different FFmpeg versions:
- **8.0** - FFmpeg 8.0 (branch: `ffmpeg-8.0`)
- **7.1.2** - FFmpeg 7.1.2 (branch: `ffmpeg-7.1.2`)
- **7.0.3** - FFmpeg 7.0.3 (branch: `ffmpeg-7.0.3`)

Each version branch includes:
- Version-specific configuration and documentation
- Full CI/CD pipeline with automated testing
- Build artifacts for verified working releases

**IMPORTANT**: When working on this project, ensure changes are compatible with the target FFmpeg version.

## Essential Build Commands

**Build Requirements:**
- **Apple Silicon (arm64) Mac** required for development
- **macOS 26.0+** required
- **Xcode 17.0+** required
- **FFmpeg** installed via Homebrew

**Build commands:**
```bash
# Build the package
swift build

# Run tests
swift test

# Run specific test
swift test --filter <TestName>

# Clean build artifacts
swift package clean
```

**FFmpeg Installation:**
```bash
# Install FFmpeg via Homebrew
brew install ffmpeg

# Verify FFmpeg version
ffmpeg -version
```

## Core Architecture Patterns

### FFmpeg Wrapper Design

SwiftFFmpeg provides Swift-friendly wrappers around FFmpeg's C API:

1. **Format Contexts**: `AVFormatContext` - Handle input/output media files
2. **Codec Contexts**: `AVCodecContext` - Encode/decode audio and video
3. **Frames**: `AVFrame` - Raw audio/video data
4. **Packets**: `AVPacket` - Compressed audio/video data
5. **Streams**: Access media streams within containers

### Memory Management

**CRITICAL**: FFmpeg resources must be properly managed:
- Use `unref()` to release packets and frames after use
- Format and codec contexts are automatically cleaned up
- Always use `defer` blocks for cleanup when appropriate

```swift
let pkt = AVPacket()
defer { pkt.unref() }

let frame = AVFrame()
defer { frame.unref() }
```

## Key Directories

- `Sources/SwiftFFmpeg/` - Main library source code
- `Sources/CFFmpeg/` - FFmpeg C bindings
- `Sources/Examples/` - Example usage code
- `Tests/` - Test suites

## Testing Requirements

- **Minimum coverage**: 80% (current coverage TBD)
- **Test framework**: Swift Testing for new tests
- Use `@Test("description")` macro, not `func test...`
- All tests must pass before merging PRs

## Development Workflow

**⚠️ CRITICAL: See [`.claude/WORKFLOW.md`](.claude/WORKFLOW.md) for complete development workflow.**

This project follows a **strict branch-based workflow**:

### Quick Reference

- **Development branch**: `development` (all work happens here)
- **Main branch**: `main` (protected, PR-only)
- **Workflow**: `development` → PR → CI passes → Merge → Tag → Release
- **NEVER** commit directly to `main`
- **NEVER** delete the `development` branch

### CI/CD Requirements

**Main branch is protected:**
- Direct pushes blocked (PRs only)
- No PR review required
- GitHub Actions must pass before merge:
  - macOS Tests: Unit tests on macOS platform
  - Code Quality: TODOs, large files, print statements

**See [`.claude/WORKFLOW.md`](.claude/WORKFLOW.md) for:**
- Complete branch strategy
- Commit message conventions
- PR creation templates
- Tagging and release process
- Version numbering (semver)
- Emergency hotfix procedures

## Common Patterns

### Opening a Media File

```swift
import SwiftFFmpeg

let fmtCtx = try AVFormatContext(url: "path/to/video.mp4")
try fmtCtx.findStreamInfo()

// Dump format information
fmtCtx.dumpFormat(isOutput: false)

// Access video stream
guard let stream = fmtCtx.videoStream else {
    fatalError("No video stream.")
}
```

### Decoding Video Frames

```swift
guard let codec = AVCodec.findDecoderById(stream.codecParameters.codecId) else {
    fatalError("Codec not found.")
}

let codecCtx = AVCodecContext(codec: codec)
codecCtx.setParameters(stream.codecParameters)
try codecCtx.openCodec()

let pkt = AVPacket()
let frame = AVFrame()

while let _ = try? fmtCtx.readFrame(into: pkt) {
    defer { pkt.unref() }

    if pkt.streamIndex != stream.index {
        continue
    }

    try codecCtx.sendPacket(pkt)

    while true {
        do {
            try codecCtx.receiveFrame(frame)
            // Process frame here
            frame.unref()
        } catch let err as AVError where err == .tryAgain || err == .eof {
            break
        }
    }
}
```

## Documentation Resources

- `README.md` - User-facing overview
- `CLAUDE.md` - This file - architecture guide
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html) - Official FFmpeg docs
- [API Documentation](https://sunlubo.github.io/SwiftFFmpeg) - Generated API docs

## Project Metadata

- **Version**: TBD (Development version with automated version bump workflow)
- **Swift**: 6.2+
- **Platforms**: macOS 26.0+
- **Dependencies**: FFmpeg (via Homebrew)
- **License**: MIT
- **Status**: Experimental

## Important Reminders

- This library is experimental and not ready for production use
- Always ensure FFmpeg version compatibility
- Memory management is critical - use proper cleanup
- When tagging versions, tag the merge commit of the PR, push the tag, then create a GitHub release
- ALWAYS work on the `development` branch
- NEVER commit directly to `main`
