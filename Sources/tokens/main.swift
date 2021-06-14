import ArgumentParser
import Files
import Tokenizer

struct Tokens: ParsableCommand {

    @Argument(help: "string to tokenize")
    var arg: String = ""
    
    @Option(name: [.short, .long], help: "input file")
    var inputFile: String = ""
    
    @Option(name: [.short, .long], help: "symbols to tokenize")
    var symbols: String = ""
    
    @Option(name: [.short, .long], parsing: .upToNextOption, help: "keywords to tokenize")
    var keywords: [String] = []
    
    @Flag(name: [.short, .long], help: "strip comments from collected tokens")
    var filterComments: Bool = false
    
    mutating func run() throws {

        if arg.count > 0 {

            let tokens = Tokenizer(source: arg, filterComments: filterComments,
                                   symbols: Set(symbols.components(separatedBy: ",")),
                                   keywords: Set(keywords)).tokenize()
            print(tokens.map { $0.description }.joined(separator: ", "))

        } else if inputFile.count > 0  {
            
            do {
                let content = try File(path: inputFile).readAsString()
                let tokens = Tokenizer(source: content, filterComments: filterComments,
                                       symbols: Set(symbols.components(separatedBy: ",")),
                                       keywords: Set(keywords)).tokenize()
                print(tokens.map { $0.description }.joined(separator: ", "))
            } catch (let error) {
                print(error)
            }
        }
    }
}

Tokens.main()


