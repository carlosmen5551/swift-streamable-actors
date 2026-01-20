import Foundation

/// A macro that transforms an actor's stored properties into observable AsyncStreams.
/// It automatically generates private shadow storage and static stream factory methods.
@attached(member, names: arbitrary)
@attached(memberAttribute)
public macro Streamable() = #externalMacro(module: "StreamableMacros", type: "StreamableMacro")

/// An internal accessor macro used by @Streamable to redirect property access to shadow storage.
@attached(accessor)
public macro StreamedProperty() = #externalMacro(module: "StreamableMacros", type: "StreamablePropertyMacro")

/// Prevents the @Streamable macro from generating a stream or shadow storage for this property.
@attached(peer)
public macro StreamableIgnored() = #externalMacro(module: "StreamableMacros", type: "StreamableIgnoredMacro")
