//
//  StreamableActors.swift
//  swift-streamable-actors
//
//  Created by Malcolm Hall on 21/01/2026.
//

/// A macro that transforms an actor's stored properties into observable AsyncStreams.
/// It automatically generates private shadow storage and static stream factory methods.
@attached(member, names: arbitrary)
@attached(memberAttribute)
public macro Streamable() = #externalMacro(module: "StreamableActorsMacros", type: "StreamableMacro")

/// An internal accessor macro used by @Streamable to redirect property access to shadow storage.
@attached(accessor)
public macro StreamableProperty() = #externalMacro(module: "StreamableActorsMacros", type: "StreamablePropertyMacro")

/// Prevents the @Streamable macro from generating a stream or shadow storage for this property.
@attached(peer)
public macro StreamableIgnored() = #externalMacro(module: "StreamableActorsMacros", type: "StreamableIgnoredMacro")
