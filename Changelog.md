# Changelog

All notable changes to this project will be documented in this file.

## [1.0.4] - 2021-06-14

### Changed

- Added `.char(Character)` token. Now identifiers can be extracted character by character.
- Numerical (integral) tokens have a subtype indicating the underlying type (binary, decimal, octal, hexadecimal).
- Added the ability to temporarily force numerical tokens to be parsed, in particular hexadecimals, since there is a sigificant lexical overlap between hexadecimals and identifiers that makes it a little tricky. The ability is enabled by setting `contextDependent` to, for example, `.hexadecimal`.