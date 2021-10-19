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

extension MMSearchQuery: Parseable {
	
	public init(from string: String) throws {
		self = try Self.parser.run(sourceName: "", input: string)
	}
	
	static let parser: GenericParser<String, (), Self> = {
		let filter = MMSearchFilter.parser
		let filters = filter.dividedBy1(GenericParser.spaces)
		let query = StringParser.spaces *> filters <* StringParser.spaces <* StringParser.eof
		
		return Self.init(filters:) <^> query
	}()
	
}

extension MMSearchFilter: Parseable {
	
	public init(from string: String) throws {
		self = try Self.parser.run(sourceName: "", input: string)
	}
	
	static let parser: GenericParser<String, (), Self> = {
		let string = StringParser.string
		
		let separator = StringParser.character(":")
		let identifier = (StringParser.alphaNumeric <|> StringParser.oneOf("_+-")).many1.stringValue
		
		let draftParser    = Self.isDraft  <^> (string("draft").attempt    *> separator *> ExtendedBoolToken.parser)
		let kindParser     = Self.kind     <^> (string("kind").attempt     *> separator *> identifier)
		let categoryParser = Self.category <^> (string("category").attempt *> separator *> identifier)
		let creatorParser  = Self.creator  <^> (string("creator").attempt  *> separator *> UserToken.parser)
		let creationParser = Self.creation <^> (string("created").attempt  *> separator *> RangeToken.parser)
		
		let imagesCountParser = Self.imagesCount <^> (string("images").attempt *> separator *> RangeToken.parser)
		let propertiesCountParser = GenericParser.lift2(
			Self.propertiesCount,
			parser1: identifier,
			parser2: separator *> RangeToken.parser
		).attempt
		let hasPropertyParser = GenericParser.lift3(
			Self.hasProperty,
			parser1: identifier,
			parser2: .character("/") *> identifier,
			parser3: separator *> Bool.parser
		).attempt
		let propertiesParser = string("properties").attempt *> separator *> (propertiesCountParser <|> hasPropertyParser)
		
		let parser = GenericParser.choice([
			draftParser,
			kindParser,
			categoryParser,
			creatorParser,
			creationParser,
			imagesCountParser,
			propertiesParser,
		])
		
		return parser
	}()
	
}

extension MMSearchFilter.ExtendedBoolToken: Parseable {
	
	static let parser: GenericParser<String, (), Self> = {
		let string = StringParser.string
		
		let boolParser  = Self.bool <^> Bool.parser
		let onlyParser  = string("only") *> GenericParser(result: Self.only)
		
		return boolParser <|> onlyParser
	}()
	
}

extension MMSearchFilter.UserToken: Parseable {
	
	static let parser: GenericParser<String, (), Self> = {
		let string = StringParser.string
		let username = StringParser.noneOf(" ").many1.stringValue <?> "username"
		let userId = (StringParser.hexadecimalDigit <|> .character("-")).count(36).stringValue <?> "UUID"
		
		let usernameParser = Self.username <^> (string("@").attempt *> username)
		let userIdParser = Self.userId <^> userId
		
		return usernameParser <|> userIdParser
	}()
	
}

extension MMSearchFilter.DateToken: Parseable {
	
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

extension MMSearchFilter.RangeToken: Parseable {
	
	static var parser: GenericParser<String, (), Self> {
		return GenericParser.fail("Not implemented")
	}
	
	static func parser(value: GenericParser<String, (), T>) -> GenericParser<String, (), Self> {
		let geParser = Self.greaterThanOrEqualTo <^> (.string(">=").attempt *> value)
		let gtParser = Self.greaterThan          <^> (.character(">").attempt *> value)
		let leParser = Self.lessThanOrEqualTo    <^> (.string("<=").attempt *> value)
		let ltParser = Self.lessThan             <^> (.character("<").attempt *> value)
		let rangeParser = GenericParser.lift2(Self.between, parser1: value, parser2: (.string("..") *> value)).attempt
		let eqParser = Self.equalTo              <^> value
		
		return geParser <|> gtParser <|> leParser <|> ltParser <|> rangeParser <|> eqParser
	}
	
}

extension MMSearchFilter.RangeToken where T: Parseable {
	
	static var parser: GenericParser<String, (), Self> {
		return Self.parser(value: T.parser)
	}
	
}

extension MMSearchFilter.RangeToken where T == String {
	
	static var parser: GenericParser<String, (), Self> {
		let value = StringParser.anyCharacter.manyTill(.space <|> .character(".")).stringValue
		return Self.parser(value: value)
	}
	
}

import Foundation

extension Bool: Parseable {
	
	static let parser: GenericParser<String, (), Self> = {
		let string = StringParser.string
		
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
