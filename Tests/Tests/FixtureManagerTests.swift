//
//  FixtureManagerTests.swift
//  Tests
//
//  Tests for the FixtureManager functionality.
//

import XCTest
@testable import SwiftFFmpeg

final class FixtureManagerTests: XCTestCase {

  static let allTests = [
    ("testFixturesExist", testFixturesExist),
    ("testAllFixtures", testAllFixtures),
    ("testFixturesByCategory", testFixturesByCategory),
    ("testFixtureByIndex", testFixtureByIndex),
    ("testFixturesByExtension", testFixturesByExtension),
    ("testFixturesByPattern", testFixturesByPattern),
    ("testFixtureProperties", testFixtureProperties),
    ("testTemporaryCopy", testTemporaryCopy),
    ("testTemporaryDirectory", testTemporaryDirectory),
  ]

  func testFixturesExist() throws {
    try skipIfFixturesUnavailable()
    XCTAssertTrue(FileManager.default.fileExists(atPath: FixtureManager.fixturesDirectory.path))
  }

  func testAllFixtures() throws {
    try skipIfFixturesUnavailable()

    let allFixtures = FixtureManager.allFixtures
    XCTAssertFalse(allFixtures.isEmpty, "Expected fixtures to be present")

    // Verify fixtures are sorted by index
    for i in 1..<allFixtures.count {
      XCTAssertLessThanOrEqual(allFixtures[i-1].index, allFixtures[i].index)
    }

    print("Found \(allFixtures.count) fixtures")
  }

  func testFixturesByCategory() throws {
    try skipIfFixturesUnavailable()

    let actionFixtures = FixtureManager.fixtures(in: .action)
    let narratorFixtures = FixtureManager.fixtures(in: .narrator)

    XCTAssertFalse(actionFixtures.isEmpty, "Expected action fixtures")
    XCTAssertFalse(narratorFixtures.isEmpty, "Expected narrator fixtures")

    // Verify all action fixtures have the correct category
    for fixture in actionFixtures {
      XCTAssertEqual(fixture.category, .action)
    }

    // Verify all narrator fixtures have the correct category
    for fixture in narratorFixtures {
      XCTAssertEqual(fixture.category, .narrator)
    }

    print("Action fixtures: \(actionFixtures.count)")
    print("Narrator fixtures: \(narratorFixtures.count)")
  }

  func testFixtureByIndex() throws {
    try skipIfFixturesUnavailable()

    // Test getting fixture by index
    let fixture0 = FixtureManager.fixture(at: 0)
    XCTAssertNotNil(fixture0)
    XCTAssertEqual(fixture0?.index, 0)

    // Test non-existent index
    let nonExistent = FixtureManager.fixture(at: 9999)
    XCTAssertNil(nonExistent)
  }

  func testFixturesByExtension() throws {
    try skipIfFixturesUnavailable()

    let cafFixtures = FixtureManager.fixtures(withExtension: "caf")
    XCTAssertFalse(cafFixtures.isEmpty, "Expected CAF fixtures")

    // Verify all have .caf extension
    for fixture in cafFixtures {
      XCTAssertEqual(fixture.fileExtension.lowercased(), "caf")
    }
  }

  func testFixturesByPattern() throws {
    try skipIfFixturesUnavailable()

    // Test pattern matching with a pattern that exists in our fixtures
    let allFixtures = FixtureManager.allFixtures
    guard let firstFixture = allFixtures.first else {
      throw XCTSkip("No fixtures available for pattern test")
    }

    // Use a word from the first fixture's name for the pattern test
    let patternWord = firstFixture.name.components(separatedBy: "_").first ?? firstFixture.name
    let matchingFixtures = FixtureManager.fixtures(matching: patternWord)

    XCTAssertFalse(matchingFixtures.isEmpty, "Expected fixtures matching '\(patternWord)'")

    for fixture in matchingFixtures {
      XCTAssertTrue(
        fixture.name.localizedCaseInsensitiveContains(patternWord),
        "Expected fixture name to contain '\(patternWord)'"
      )
    }

    print("Found \(matchingFixtures.count) fixtures matching '\(patternWord)'")
  }

  func testFixtureProperties() throws {
    try skipIfFixturesUnavailable()

    guard let fixture = FixtureManager.firstFixture else {
      XCTFail("No fixtures available")
      return
    }

    // Test properties
    XCTAssertTrue(fixture.exists, "Fixture file should exist")
    XCTAssertNotNil(fixture.fileSize, "Should be able to get file size")
    XCTAssertGreaterThan(fixture.fileSize ?? 0, 0, "File size should be greater than 0")
    XCTAssertFalse(fixture.path.isEmpty, "Path should not be empty")
    XCTAssertFalse(fixture.filename.isEmpty, "Filename should not be empty")

    print("Fixture: \(fixture)")
    print("Debug: \(fixture.debugDescription)")
  }

  func testTemporaryCopy() throws {
    try skipIfFixturesUnavailable()

    guard let fixture = FixtureManager.firstFixture else {
      XCTFail("No fixtures available")
      return
    }

    let tempURL = try FixtureManager.temporaryCopy(of: fixture)
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }

    XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))

    // Verify size matches
    let originalSize = fixture.fileSize
    let attributes = try FileManager.default.attributesOfItem(atPath: tempURL.path)
    let tempSize = attributes[.size] as? UInt64

    XCTAssertEqual(originalSize, tempSize)
  }

  func testTemporaryDirectory() throws {
    try skipIfFixturesUnavailable()

    let allFixtures = FixtureManager.allFixtures
    guard allFixtures.count >= 2 else {
      throw XCTSkip("Not enough fixtures for this test (need at least 2)")
    }

    // Use available fixtures (up to 3)
    let fixtureCount = min(allFixtures.count, 3)
    let fixturesToCopy = Array(allFixtures.prefix(fixtureCount))
    let tempDir = try FixtureManager.temporaryDirectory(withFixtures: fixturesToCopy)
    defer {
      try? FileManager.default.removeItem(at: tempDir)
    }

    XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.path))

    // Verify all fixtures were copied
    for fixture in fixturesToCopy {
      let copiedFile = tempDir.appendingPathComponent(fixture.url.lastPathComponent)
      XCTAssertTrue(
        FileManager.default.fileExists(atPath: copiedFile.path),
        "Expected \(fixture.url.lastPathComponent) to be copied"
      )
    }
  }

  func testAccessFromXCTestCase() throws {
    // Test the convenience property
    try skipIfFixturesUnavailable()

    let allFixtures = fixtures.allFixtures
    XCTAssertFalse(allFixtures.isEmpty)

    let firstFixture = fixtures.firstFixture
    XCTAssertNotNil(firstFixture)
  }

  func testCategoryAccessor() throws {
    try skipIfFixturesUnavailable()

    let actionFromCategory = FixtureManager.FixtureCategory.action.fixtures
    let actionFromManager = FixtureManager.fixtures(in: .action)

    XCTAssertEqual(actionFromCategory.count, actionFromManager.count)
  }

  func testRandomFixture() throws {
    try skipIfFixturesUnavailable()

    let random1 = FixtureManager.randomFixture
    XCTAssertNotNil(random1)

    // Getting random fixtures should return valid fixtures
    for _ in 0..<10 {
      let random = FixtureManager.randomFixture
      XCTAssertNotNil(random)
      XCTAssertTrue(random?.exists ?? false)
    }
  }
}
