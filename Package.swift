// swift-tools-version:6.2
import PackageDescription

let package = Package(
  name: "SwiftFFmpeg",
  platforms: [.macOS("26")],
  products: [
    .library(
      name: "SwiftFFmpeg",
      targets: ["SwiftFFmpeg"]
    )
  ],
  targets: [
    .plugin(  name: "FetchFFmpegXCFrameworks",
              capability: .command(
                intent: .custom(
                    verb: "download-ffmpeg-xcframeworks",
                    description: "Download the FFmpeg 7.0.3 XCFramework artifact from intrusive-memory/ffmpeg-framework into the package."
                    ),
                    permissions: [
                      .writeToPackageDirectory(reason: "Place the downloaded FFmpeg XCFrameworks under the xcframework/ directory.")
                    ]
                )
            ),

    .systemLibrary(
      name: "CFFmpeg",
      pkgConfig: "libavformat",
      providers: [
        .brew(["ffmpeg"])
      ]
    ),
    .target(
      name: "SwiftFFmpeg",
      dependencies: ["CFFmpeg"],
      swiftSettings: [
        .swiftLanguageMode(.v5)
      ]
    ),
    .executableTarget(
      name: "Examples",
      dependencies: ["SwiftFFmpeg"],
      swiftSettings: [
        .swiftLanguageMode(.v5)
      ]
    ),
    .testTarget(
      name: "Tests",
      dependencies: ["SwiftFFmpeg"],
      swiftSettings: [
        .swiftLanguageMode(.v5)
      ]
    ),
  ]
)
