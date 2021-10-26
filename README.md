# Monki Map Search Parser

[![Tests](https://github.com/MonkiProjects/monki-map-search-parser/actions/workflows/test.yml/badge.svg)](https://github.com/MonkiProjects/monki-map-search-parser/actions/workflows/test.yml)

This repository defines the grammar and the parser for searching places in the Monki Map app.

## Search grammar

### Search based on a place's name or summary

| Qualifier | Example |
| --------- | ------- |
| `…` (anything that does not match other qualifiers) | `La Dame du Lac` includes places which contain "la", "dame", "du" **and** "lac" in their name **or** summary. |
| `"…"` | `"La Dame du Lac"` includes places which contain "la dame du lac" in their name **or** summary. **This keeps the order of words**. |

These qualifiers are case-insensitive (i.e. "A" = "a"), and diacritics-sensitive (i.e. "à" ≠ "a").
One day we will make it diacritics-insensitive too, to make searching for places easier.

### Search based on whether a place is a draft

| Qualifier | Example |
| --------- | ------- |
| `draft:false` | Do not include draft places in results |
| `draft:true`  | Includes draft places |
| `draft:only`  | Includes only draft places |

When not provided, default value should be customizable in the app settings.

### Search based on the place kind

| Qualifier | Example |
| --------- | ------- |
| `kind:KIND_ID` | `kind:indoor_parkour_park` includes only indoor parkour parks |

<!-- TODO: Add link to list -->

### Search based on the place category

| Qualifier | Example |
| --------- | ------- |
| `category:CATEGORY_ID` | Includes places of category `CATEGORY_ID` |

<!-- TODO: Add link to list -->

### Search based on the place creator

| Qualifier | Example |
| --------- | ------- |
| `creator:USER_ID`    | Includes places created by `USER_ID` |
| `creator:@USER_NAME` | Includes places created by `@USER_NAME` |

### Images

| Qualifier | Example |
| --------- | ------- |
| `images:n`       | `images:1` includes places with exactly 1 image |
| `images:<RANGE>` | `images:>5` includes places with more than 5 images |
|                  | `images:>=10` includes places with 10 or more images |
|                  | `images:<5` includes places with less than 5 images |
|                  | `images:<=3` includes places with 3 or less images |
|                  | `images:1..10` includes places with 1 to 10 images |

`<RANGE>` is a number range (`>n`, `>=n`, `<n`, `<=`, `x..y`).

### Creation date

| Qualifier | Example |
| --------- | ------- |
| `created:TIMESTAMP` | `created:>2021-10-13` includes places created after October 13th, 2021 |
|                     | `created:>=2021-01-01` includes places created on or after January 1st, 2021 |
|                     | `created:<2021-10-13` includes place created before October 13th, 2021 |
|                     | `created:<=2020-12-31` includes places created before 2021 |

`TIMESTAMP` can be a date or a date with time, as defined by [ISO 8601](http://en.wikipedia.org/wiki/ISO_8601).

### Place properties

| Qualifier | Example |
| --------- | ------- |
| `properties:PROPERTY_KIND/PROPERTY_ID:true`  | `properties:feature/big_wall:true` includes places with a big wall |
| `properties:PROPERTY_KIND/PROPERTY_ID:false` | `properties:hazard/high_drop:false` includes places without high drops |
| `properties:PROPERTY_KIND:n`                 | `properties:benefit:5` includes places with 5 benefits, no matter which |
| `properties:PROPERTY_KIND:<RANGE>`           | `properties:benefit:>5` includes places with more than 5 benefits, no matter which |

<!-- TODO: Add link to list -->

`<RANGE>` is a number range (`>n`, `>=n`, `<n`, `<=`, `x..y`).
