//
//  MMSearchQueryParserTests.swift
//  MonkiMapSearchParserTests
//
//  Created by Rémi Bardon on 19/10/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import XCTest
@testable import MonkiMapSearchParser

internal final class MonkiMapSearchParserTests: XCTestCase {
	
	func testSearchQueryDescriptionIsCorrect() {
		let query = MMSearchQuery(filters: [
			.kind("indoor_parkour_park"),
			.creation(.greaterThanOrEqualTo("2021-01-01")),
			.imagesCount(.between(1, and: 10)),
		])
		XCTAssertEqual(query.description, "kind:indoor_parkour_park created:>=2021-01-01 images:1..10")
	}
	
	func testDecodingStringFilterWorks() {
		XCTAssertNoThrow(try MMSearchFilter(from: "IMAX"))
	}
	
	func testDecodingStringFilterWithSpacesThrowsError() {
		XCTAssertThrowsError(try MMSearchFilter(from: "   La Dame du Lac"))
		XCTAssertThrowsError(try MMSearchFilter(from: "La Dame du Lac   "))
		XCTAssertThrowsError(try MMSearchFilter(from: "\tLa Dame du Lac"))
	}
	
	func testDecodingStringFilterWithDiacriticsWorks() {
		XCTAssertEqual(try MMSearchFilter(from: "Äé':/"), .word("Äé':/"))
	}
	
	func testDecodingStringQueryWorks() {
		let expected = MMSearchQuery(.word("La"), .word("Dame"), .word("du"), .word("Lac"))
		XCTAssertEqual(try MMSearchQuery(from: expected.description), expected)
		XCTAssertEqual(try MMSearchQuery(from: "La Dame du Lac"), expected)
		XCTAssertEqual(try MMSearchQuery(from: "La Dame du Lac     "), expected)
		XCTAssertEqual(try MMSearchQuery(from: "La Dame du Lac  \t   "), expected)
		XCTAssertEqual(try MMSearchQuery(from: " \t   La Dame du Lac     "), expected)
		XCTAssertEqual(try MMSearchQuery(from: "     La Dame du Lac"), expected)
	}
	
	func testDecodingQuotedStringFilterWorks() {
		XCTAssertEqual(try MMSearchFilter(from: "\"La Dame du Lac\""), .quotedString("La Dame du Lac"))
	}
	
	func testDecodingQuotedStringQueryWorks() {
		let expected = MMSearchQuery(.quotedString("La Dame du Lac"), .quotedString("Another text"))
		XCTAssertEqual(try MMSearchQuery(from: expected.description), expected)
		XCTAssertEqual(try MMSearchQuery(from: "   \"La Dame du Lac\"  \t  \"Another text\" "), expected)
	}
	
	func testBasicFilterDecodingWorks() {
		XCTAssertNoThrow(try MMSearchFilter(from: "kind:indoor_parkour_park"))
	}
	
	func testFilterDecodingWithWhitespacesThrows() {
		XCTAssertThrowsError(try MMSearchFilter(from: "  \t  kind:indoor_parkour_park       "))
	}
	
	func testSimpleQueryDecodingWorks() {
		let query = MMSearchQuery(filters: [
			.kind("indoor_parkour_park"),
			.creation(.greaterThanOrEqualTo("2021-01-01")),
			.imagesCount(.between(1, and: 10)),
		])
		XCTAssertNoThrow(try MMSearchQuery(from: query.description))
	}
	
	func testQueryDecodingSkipsWhitespaces() throws {
		let res = try MMSearchQuery(from: "  created:>2021-01-01   ")
		XCTAssertEqual(res, MMSearchQuery(.creation(.greaterThan("2021-01-01"))))
	}
	
	func testQueryDecodingWithWhitespacesWorks() throws {
		let query = MMSearchQuery(filters: [
			.kind("indoor_parkour_park"),
			.creation(.greaterThanOrEqualTo("2021-01-01")),
			.imagesCount(.between(1, and: 10)),
		])
		let res = try MMSearchQuery(from: "     \(query)    \t ")
		XCTAssertEqual(res, query)
	}
	
	func testDecodingUsernameWorks() throws {
		let res = try MMSearchFilter(from: "creator:@remi_bardon")
		XCTAssertEqual(res, .creator(.username("remi_bardon")))
	}
	
	func testDecodingUserIdWorks() throws {
		// FIXME: Use `user_` prefix
		let res = try MMSearchFilter(from: "creator:2f365abc-d755-4257-9641-5dad3068bc6a")
		XCTAssertEqual(res, .creator(.userId("2f365abc-d755-4257-9641-5dad3068bc6a")))
	}
	
	func testDecodingBadUserIdThrows() {
		XCTAssertThrowsError(try MMSearchFilter(from: "creator:G0000000-0000-4000-0000-000000000000"))
	}
	
	func testDecodingPropertiesCountWorks() throws {
		let res = try MMSearchFilter(from: "properties:benefit:5")
		XCTAssertEqual(res, .propertiesCount(kind: "benefit", range: .equalTo(5)))
	}
	
	func testDecodingPropertiesWorks() throws {
		let res = try MMSearchFilter(from: "properties:feature/big_wall:true")
		XCTAssertEqual(res, .hasProperty(kind: "feature", id: "big_wall", true))
	}
	
	func testDecodingExtendedBoolWorks() throws {
		let res = try MMSearchFilter(from: "draft:only")
		XCTAssertEqual(res, .isDraft(.only))
	}
	
	func testQualifierPrefixIsTreatedAsTextIfNoColon() throws {
		let res = try MMSearchQuery(from: "category")
		XCTAssertEqual(res, MMSearchQuery(.word("category")))
	}
	
	func testQualifierSuffixIsEmptyIfNothingAfterColon() throws {
		let res = try MMSearchQuery(from: "category:")
		XCTAssertEqual(res, MMSearchQuery(.category("")))
		XCTAssertEqual(MMSearchQuery(.category("")).description, "category:")
	}
	
	func testOneBadQualifierDoesntBreakAQuery() {
		XCTAssertTrue(MMSearchQuery.validate("properties:feature/big_wall:true"))
		XCTAssertTrue(MMSearchQuery.validate("properties:feature/big_wall:true properties"))
		XCTAssertFalse(MMSearchQuery.validate("properties:feature/big_wall:true properties:feature/med"))
	}
	
	func testEmptyQueryIsValid() {
		XCTAssertNoThrow(try MMSearchQuery(from: ""))
		XCTAssertTrue(MMSearchQuery.validate(""))
	}
	
}
