//
//  StreamableMacroError.swift
//  swift-streamable-actors
//
//  Created by Malcolm Hall on 20/01/2026.
//

enum StreamableMacroError: CustomStringConvertible, Error {
    case onlyActors

    var description: String {
        switch self {
        case .onlyActors: return "@Streamable can only be applied to an 'actor'."
        }
    }
}
