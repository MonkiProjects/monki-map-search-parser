//
//  MMSearchQuery+Parser.swift
//  MonkiMapSearchParser
//
//  Created by Rémi Bardon on 19/10/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import SwiftParsec

internal protocol Parseable {
	
	static var parser: GenericParser<String, (), Self> { get }
	
}

fileprivate let string = StringParser.string
fileprivate let character = StringParser.character
fileprivate let wordParser = StringParser
	.satisfy { $0.unicodeScalars.allSatisfy(CharacterSet.whitespaces.inverted.contains) }
	.many1.stringValue

extension MMSearchQuery: Parseable {
	
	internal static let parser: GenericParser<String, (), Self> = {
		let spaces = StringParser.spaces
		let filters = MMSearchFilter.parser.dividedBy1(spaces)
		let query = spaces *> filters <* spaces <* StringParser.eof
		
		return Self.init(filters:) <^> query
	}()
	
	public init(from string: String) throws {
		self = try Self.parser.run(sourceName: "", input: string)
	}
	
	public static func validate(_ string: String) -> Bool {
		do {
			_ = try Self.parser.run(sourceName: "", input: string)
			return true
		} catch {
			return false
		}
	}
	
}

extension MMSearchFilter: Parseable {
	
	private static let separator = character(":")
	private static let identifier = (StringParser.alphaNumeric <|> StringParser.oneOf("_+-")).many.stringValue
	
	internal static let stringParser: GenericParser<String, (), Self> = {
		return Self.word <^> (StringParser.space.noOccurence *> wordParser)
	}()
	
	internal static let quotedStringParser: GenericParser<String, (), Self> = {
		let quote = character("\"")
		let parser = quote.attempt *> GenericParser.noneOf("\"").many.stringValue <* quote
		return Self.quotedString <^> parser
	}()
	
	internal static let isDraftParser: GenericParser<String, (), Self> = {
		let parser = (string("draft") *> separator).attempt *> ExtendedBoolToken.parser
		return Self.isDraft <^> parser
	}()
	
	internal static let kindParser: GenericParser<String, (), Self> = {
		let parser = (string("kind") *> separator).attempt *> identifier
		return Self.kind <^> parser
	}()
	
	internal static let categoryParser: GenericParser<String, (), Self> = {
		let parser = (string("category") *> separator).attempt *> identifier
		return Self.category <^> parser
	}()
	
	internal static let creatorParser: GenericParser<String, (), Self> = {
		let parser = (string("creator") *> separator).attempt *> UserToken.parser
		return Self.creator <^> parser
	}()
	
	internal static let creationParser: GenericParser<String, (), Self> = {
		let parser = (string("created")  *> separator).attempt *> RangeToken<DateToken>.parser
		return Self.creation <^> parser
	}()
	
	internal static let imagesCountParser: GenericParser<String, (), Self> = {
		let parser = (string("images") *> separator).attempt *> RangeToken<UInt8>.parser
		return Self.imagesCount <^> parser
	}()
	
	internal static let propertiesParser: GenericParser<String, (), Self> = {
		let propertiesCountParser = GenericParser.lift2(
			Self.propertiesCount,
			parser1: identifier,
			parser2: separator *> RangeToken.parser
		).attempt
		let hasPropertyParser = GenericParser.lift3(
			Self.hasProperty,
			parser1: identifier,
			parser2: character("/") *> identifier,
			parser3: separator *> Bool.parser
		).attempt
		let proprtiesPrefix = (string("properties") *> separator).attempt
		let parser = proprtiesPrefix *> (propertiesCountParser <|> hasPropertyParser)
		return parser
	}()
	
	internal static let parser: GenericParser<String, (), Self> = {
		return GenericParser.choice([
			Self.quotedStringParser,
			Self.isDraftParser,
			Self.kindParser,
			Self.categoryParser,
			Self.creatorParser,
			Self.creationParser,
			Self.imagesCountParser,
			Self.propertiesParser,
			Self.stringParser,
		])
	}()
	
	public init(from string: String) throws {
		self = try (Self.parser <* StringParser.eof).run(sourceName: "", input: string)
	}
	
}

extension ExtendedBoolToken: Parseable {
	
	internal static let parser: GenericParser<String, (), Self> = {
		let boolParser = Self.bool <^> Bool.parser
		let onlyParser = string("only") *> GenericParser(result: Self.only)
		
		return boolParser <|> onlyParser
	}()
	
}

extension UserToken: Parseable {
	
	internal static let parser: GenericParser<String, (), Self> = {
		let username = string("@").attempt *> wordParser <?> "username"
		let uuid = (StringParser.hexadecimalDigit <|> character("-")).count(36).stringValue <?> "UUID"
		
		return GenericParser.choice([
			Self.username <^> username,
			Self.userId   <^> uuid,
		])
	}()
	
}

extension DateToken: Parseable {
	
	internal static let parser: GenericParser<String, (), Self> = {
		let char = GenericParser.decimalDigit <|> StringParser.oneOf(":+-TWZ")
		return (Self.init(string:) <^> char.many1.stringValue).flatMap { value in
			if let value = value {
				return GenericParser(result: value)
			} else {
				return GenericParser.fail("Invalid date")
			}
		}
	}()
	
}

extension RangeToken: Parseable {
	
	internal static var parser: GenericParser<String, (), Self> {
		return GenericParser.fail("Not implemented")
	}
	
	internal static func parser(value: GenericParser<String, (), T>) -> GenericParser<String, (), Self> {
		let geParser    =   string(">=").attempt *> value
		let gtParser    = character(">").attempt *> value
		let leParser    =   string("<=").attempt *> value
		let ltParser    = character("<").attempt *> value
		let rangeParser =   string("..")         *> value
		
		return GenericParser.choice([
			Self.greaterThanOrEqualTo <^> geParser,
			Self.greaterThan          <^> gtParser,
			Self.lessThanOrEqualTo    <^> leParser,
			Self.lessThan             <^> ltParser,
			GenericParser.lift2(Self.between, parser1: value, parser2: rangeParser).attempt,
			Self.equalTo              <^> value,
		])
	}
	
}

extension RangeToken where T: Parseable {
	
	internal static var parser: GenericParser<String, (), Self> {
		return Self.parser(value: T.parser)
	}
	
}

extension RangeToken where T == String {
	
	internal static var parser: GenericParser<String, (), Self> {
		let dot = character(".")
		let value = StringParser.anyCharacter.manyTill(.space <|> dot).stringValue
		return Self.parser(value: value)
	}
	
}

import Foundation

extension Bool: Parseable {
	
	internal static let parser: GenericParser<String, (), Self> = {
		let trueParser  = string("true")  *> GenericParser(result: true)
		let falseParser = string("false") *> GenericParser(result: false)
		
		return trueParser <|> falseParser
	}()
	
}

extension UInt8: Parseable {
	
	internal static let parser: GenericParser<String, (), Self> = {
		return (UInt8.init(_:) <^> StringParser.decimalDigit.many1.stringValue).flatMap { value in
			if let value = value {
				return GenericParser(result: value)
			} else {
				return GenericParser.fail("Invalid `UInt8`")
			}
		}
	}()
	
}
