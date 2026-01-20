//
//  StreamableIgnoredMacro.swift
//  swift-streamable-actors
//
//  Created by Malcolm Hall on 20/01/2026.
//


import SwiftSyntax
import SwiftSyntaxMacros
import Foundation

public struct StreamableMacro: MemberMacro, MemberAttributeMacro {
    
    // 1. Attribute Pass: Tag everything with @StreamedProperty except Ignored ones
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        
        guard let actorDecl = node.parent?.parent?.as(ActorDeclSyntax.self) else {
            return []
        }
        
        guard let varDecl = member.as(VariableDeclSyntax.self),
              varDecl.bindingSpecifier.tokenKind != .keyword(.let) else { return [] }
        
        let isIgnored = varDecl.attributes.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.description.contains("StreamableIgnored") ?? false
        }
        
        return isIgnored ? [] : ["@StreamedProperty"]
    }
    
    // 2. Member Pass: Generate Storage, Observers, and Factories
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let actorDecl = declaration.as(ActorDeclSyntax.self) else {
            throw StreamableMacroError.onlyActors
        }
        let actorName = actorDecl.name.text
        var members: [DeclSyntax] = []
        
        for member in actorDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let type = binding.typeAnnotation?.type.description.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            
            let isIgnored = varDecl.attributes.contains { attr in
                attr.as(AttributeSyntax.self)?.attributeName.description.contains("StreamableIgnored") ?? false
            }
            if isIgnored || varDecl.bindingSpecifier.tokenKind == .keyword(.let) { continue }
            
            let capName = identifier.prefix(1).uppercased() + identifier.dropFirst()
            let initialValue = binding.initializer?.value.description ?? "nil"
            
            // Hidden Backing Storage (The _count)
            members.append("""
            private var _\(raw: identifier): \(raw: type) = \(raw: initialValue)
            """)
            
            // Observer Dictionary
            members.append("""
            private var \(raw: identifier)Observers: [UUID: AsyncStream<\(raw: type)>.Continuation] = [:]
            """)
            
            // Private Helpers
            members.append("""
            private func register\(raw: capName)Stream(id: UUID, continuation: AsyncStream<\(raw: type)>.Continuation) {
                self.\(raw: identifier)Observers[id] = continuation
                continuation.yield(_\(raw: identifier))
            }
            """)
            
            members.append("""
            private func remove\(raw: capName)Subscriber(id: UUID) {
                self.\(raw: identifier)Observers.removeValue(forKey: id)
            }
            """)
            
            // Public Static Factory
            members.append("""
            public static func \(raw: identifier)Stream(for actor: \(raw: actorName)) async -> AsyncStream<\(raw: type)> {
                let (stream, continuation) = AsyncStream.makeStream(of: \(raw: type).self)
                let id = UUID()
                await actor.register\(raw: capName)Stream(id: id, continuation: continuation)
                continuation.onTermination = { @Sendable _ in
                    Task { await actor.remove\(raw: capName)Subscriber(id: id) }
                }
                return stream
            }
            """)
        }
        return members
    }
}

public struct StreamablePropertyMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        
        let isInsideActor = context.lexicalContext.contains {
            $0.as(ActorDeclSyntax.self) != nil
        }
        if !isInsideActor { return [] }
        
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let identifier = varDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return []
        }
        
        return [
            """
            get { _\(raw: identifier) }
            """,
            """
            set {
                _\(raw: identifier) = newValue
                for obs in \(raw: identifier)Observers.values {
                    obs.yield(newValue)
                }
            }
            """
        ]
    }
}


public struct StreamableIgnoredMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // This macro does nothing by design; 
        // it is used as a marker for @Streamable to ignore properties.
        return []
    }
}
