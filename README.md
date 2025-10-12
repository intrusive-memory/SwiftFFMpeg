# SwiftFFmpeg

![Tests](https://github.com/intrusive-memory/SwiftFFMpeg/actions/workflows/tests.yml/badge.svg)

A Swift wrapper for the FFmpeg API.

> Note: SwiftFFmpeg is still in development, and the API is not guaranteed to be stable. It's subject to change without warning.

## Version Branches and Tags

SwiftFFmpeg maintains separate branches for different FFmpeg versions. Each branch is tagged with the corresponding FFmpeg version number:

- **8.0** - FFmpeg 8.0 (branch: `ffmpeg-8.0`)
- **7.1.2** - FFmpeg 7.1.2 (branch: `ffmpeg-7.1.2`)
- **7.0.3** - FFmpeg 7.0.3 (branch: `ffmpeg-7.0.3`)

Each version branch includes:
- Version-specific configuration and documentation
- Full CI/CD pipeline with automated testing
- Build artifacts for verified working releases

See the [releases page](https://github.com/intrusive-memory/SwiftFFMpeg/releases) for detailed release notes.

## Installation

### Prerequisites

You need to install [FFmpeg](http://ffmpeg.org/) before using this library. On macOS:

```bash
brew install ffmpeg
```

**Important:** Make sure the FFmpeg version you install matches the SwiftFFmpeg version you're using.

### Swift Package Manager

SwiftFFmpeg uses [SwiftPM](https://swift.org/package-manager/) as its build tool and links against the FFmpeg libraries provided by your system installation.

To depend on SwiftFFmpeg in your own project, add a `dependencies` clause to your `Package.swift`. Choose the version that matches your FFmpeg installation:

#### For FFmpeg 8.0:
```swift
dependencies: [
    .package(url: "https://github.com/intrusive-memory/SwiftFFmpeg.git", exact: "8.0")
]
```

#### For FFmpeg 7.1.2:
```swift
dependencies: [
    .package(url: "https://github.com/intrusive-memory/SwiftFFmpeg.git", exact: "7.1.2")
]
```

#### For FFmpeg 7.0.3:
```swift
dependencies: [
    .package(url: "https://github.com/intrusive-memory/SwiftFFmpeg.git", exact: "7.0.3")
]
```

SwiftPM will automatically discover the system libraries via `pkg-config`. Make sure your environment can locate FFmpeg's `.pc` files (Homebrew handles this automatically).

## Documentation

- [API documentation](https://sunlubo.github.io/SwiftFFmpeg)

## Usage

```swift
import Foundation
import SwiftFFmpeg

if CommandLine.argc < 2 {
    print("Usage: \(CommandLine.arguments[0]) <input file>")
    exit(1)
}
let input = CommandLine.arguments[1]

let fmtCtx = try AVFormatContext(url: input)
try fmtCtx.findStreamInfo()

fmtCtx.dumpFormat(isOutput: false)

guard let stream = fmtCtx.videoStream else {
    fatalError("No video stream.")
}
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
        } catch let err as AVError where err == .tryAgain || err == .eof {
            break
        }

        let str = String(
            format: "Frame %3d (type=%@, size=%5d bytes) pts %4lld key_frame %d",
            codecCtx.frameNumber,
            frame.pictureType.description,
            frame.pktSize,
            frame.pts,
            frame.isKeyFrame
        )
        print(str)

        frame.unref()
    }
}

print("Done.")
```
