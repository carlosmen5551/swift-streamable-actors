//
//  StreamablePlugin.swift
//  swift-streamable-actors
//
//  Created by Malcolm Hall on 20/01/2026.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct StreamablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StreamableMacro.self,
        StreamablePropertyMacro.self,
        StreamableIgnoredMacro.self
    ]
}
