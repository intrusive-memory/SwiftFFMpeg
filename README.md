# SwiftFFmpeg

![Tests](https://github.com/intrusive-memory/SwiftFFMpeg/actions/workflows/tests.yml/badge.svg)
![Experimental](https://img.shields.io/badge/status-experimental-yellow.svg)

A Swift wrapper for the FFmpeg API.

> **⚠️ EXPERIMENTAL - NOT READY FOR PRODUCTION**
>
> This library is experimental and incomplete. It is being developed as a learning exercise and proof of concept. The API is unstable and subject to change without warning. Features may be missing, incomplete, or non-functional. **Do not use this library in production environments.**

## Version

**Current Version**: 8.0.1

This version is compatible with **FFmpeg 8.0** installed via Homebrew.

See the [releases page](https://github.com/intrusive-memory/SwiftFFMpeg/releases) for detailed release notes.

## Installation

### Prerequisites

You need to install [FFmpeg](http://ffmpeg.org/) before using this library. On macOS:

```bash
brew install ffmpeg
```

### Swift Package Manager

SwiftFFmpeg uses [SwiftPM](https://swift.org/package-manager/) as its build tool and links against the FFmpeg libraries provided by your system installation.

Add SwiftFFmpeg to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/intrusive-memory/SwiftFFmpeg.git", from: "8.0.1")
]
```

Then add `SwiftFFmpeg` to your target's dependencies:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftFFmpeg"]
)
```

SwiftPM will automatically discover the system libraries via `pkg-config`. Homebrew handles this automatically.

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

## License

This project is licensed under the [GNU Lesser General Public License v2.1](LICENSE), the same license used by FFmpeg.
