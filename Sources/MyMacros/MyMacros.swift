// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "MyMacrosMacros", type: "StringifyMacro")

@freestanding(declaration, names: arbitrary)
public macro myDeclaration(_ name: String) = #externalMacro(module: "MyMacrosMacros", type: "MyDeclarationMacro")

@freestanding(expression)
public macro myExpression(_ name: String, type: Any) = #externalMacro(module: "MyMacrosMacros", type: "MyExpressionMacro")

//@freestanding(codeItem)
//public macro MyCodeItemMacro(_ name: String) = #externalMacro(module: "MyMacrosMacros", type: "MyCodeItemMacro")

@attached(extension)
public macro myExtensionMacro() = #externalMacro(module: "MyMacrosMacros", type: "MyExtensionMacro")

@freestanding(expression)
public macro stringConnect(_ values: String...) -> String = #externalMacro(module: "MyMacrosMacros", type: "StringConnect")

@freestanding(expression)
public macro anotherStringConnect(_ values: String...) -> String = #externalMacro(module: "MyMacrosMacros", type: "StringConnect")

@freestanding(declaration)
public macro myError(_ message: Any) = #externalMacro(module: "MyMacrosMacros", type: "ErrorMacro")

@attached(peer, names: arbitrary)
public macro getter() = #externalMacro(module: "MyMacrosMacros", type: "GetterMacro")

@attached(member, names: arbitrary)
public macro deinitLog() = #externalMacro(module: "MyMacrosMacros", type: "DeinitLogMacro")

@attached(memberAttribute)
public macro getterMembers() = #externalMacro(module: "MyMacrosMacros", type: "GetterMembersMacro")

@attached(accessor, names: arbitrary)
public macro storageBacked() = #externalMacro(module: "MyMacrosMacros", type: "StorgeBackedMacro")

@attached(extension, conformances: Error)
public macro errorType() = #externalMacro(module: "MyMacrosMacros", type: "ErrorTypeMacro")
