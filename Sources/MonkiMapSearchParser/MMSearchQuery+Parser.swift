//
//  MMSearchQuery+Parser.swift
//  MonkiMapSearchParser
//
//  Created by Rémi Bardon on 19/10/2021.
//  Copyright © 2021 Monki Projects. All rights reserved.
//

import SwiftParsec

protocol Parseable {
	
	static var parser: GenericParser<String, (), Self> { get }
	
}

fileprivate let string = StringParser.string
fileprivate let character = StringParser.character
fileprivate let word = StringParser
	.satisfy { $0.unicodeScalars.allSatisfy(CharacterSet.whitespaces.inverted.contains) }
	.many1.stringValue

extension MMSearchQuery: Parseable {
	
	public init(from string: String) throws {
		self = try Self.parser.run(sourceName: "", input: string)
	}
	
	static let parser: GenericParser<String, (), Self> = {
		let spaces = StringParser.spaces
		let filters = MMSearchFilter.parser.dividedBy1(spaces)
		let query = spaces *> filters <* spaces <* StringParser.eof
		
		return Self.init(filters:) <^> query
	}()
	
}

extension MMSearchFilter: Parseable {
	
	public init(from string: String) throws {
		self = try (Self.parser <* StringParser.eof).run(sourceName: "", input: string)
	}
	
	static let parser: GenericParser<String, (), Self> = {
		let string = StringParser.string
		
		let noSpace = StringParser.space.noOccurence
		
		let separator = character(":")
		let quote = character("\"")
		let identifier = (StringParser.alphaNumeric <|> StringParser.oneOf("_+-")).many1.stringValue
		
		let stringParser = noSpace *> word
		let quotedStringParser = quote.attempt *> GenericParser.noneOf("\"").many.stringValue <* quote
		
		let draftParser    = string("draft").attempt    *> separator *> ExtendedBoolToken.parser
		let kindParser     = string("kind").attempt     *> separator *> identifier
		let categoryParser = string("category").attempt *> separator *> identifier
		let creatorParser  = string("creator").attempt  *> separator *> UserToken.parser
		let creationParser = string("created").attempt  *> separator *> RangeToken<DateToken>.parser
		
		let imagesCountParser = string("images").attempt *> separator *> RangeToken<UInt8>.parser
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
		let proprtiesPrefix = string("properties").attempt *> separator
		let propertiesParser = proprtiesPrefix *> (propertiesCountParser <|> hasPropertyParser)
		
		let parser = GenericParser.choice([
			Self.quotedString <^> quotedStringParser,
			Self.isDraft      <^> draftParser,
			Self.kind         <^> kindParser,
			Self.category     <^> categoryParser,
			Self.creator      <^> creatorParser,
			Self.creation     <^> creationParser,
			Self.imagesCount  <^> imagesCountParser,
			propertiesParser,
			Self.string <^> stringParser,
		])
		
		return parser
	}()
	
}

extension ExtendedBoolToken: Parseable {
	
	static let parser: GenericParser<String, (), Self> = {
		let boolParser = Self.bool <^> Bool.parser
		let onlyParser = string("only") *> GenericParser(result: Self.only)
		
		return boolParser <|> onlyParser
	}()
	
}

extension UserToken: Parseable {
	
	static let parser: GenericParser<String, (), Self> = {
		let username = string("@").attempt *> word <?> "username"
		let uuid = (StringParser.hexadecimalDigit <|> character("-")).count(36).stringValue <?> "UUID"
		
		return GenericParser.choice([
			Self.username <^> username,
			Self.userId   <^> uuid,
		])
	}()
	
}

extension DateToken: Parseable {
	
	static let parser: GenericParser<String, (), Self> = {
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
	
	static var parser: GenericParser<String, (), Self> {
		return GenericParser.fail("Not implemented")
	}
	
	static func parser(value: GenericParser<String, (), T>) -> GenericParser<String, (), Self> {
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
	
	static var parser: GenericParser<String, (), Self> {
		return Self.parser(value: T.parser)
	}
	
}

extension RangeToken where T == String {
	
	static var parser: GenericParser<String, (), Self> {
		let dot = character(".")
		let value = StringParser.anyCharacter.manyTill(.space <|> dot).stringValue
		return Self.parser(value: value)
	}
	
}

import Foundation

extension Bool: Parseable {
	
	static let parser: GenericParser<String, (), Self> = {
		let trueParser  = string("true")  *> GenericParser(result: true)
		let falseParser = string("false") *> GenericParser(result: false)
		
		return trueParser <|> falseParser
	}()
	
}

extension UInt8: Parseable {
	
	static let parser: GenericParser<String, (), Self> = {
		return (UInt8.init(_:) <^> StringParser.decimalDigit.many1.stringValue).flatMap { value in
			if let value = value {
				return GenericParser(result: value)
			} else {
				return GenericParser.fail("Invalid `UInt8`")
			}
		}
	}()
	
}
