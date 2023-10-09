import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

// MARK: - StringifyMacro

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }
        
        return "(\(argument), \(literal: argument.description))"
    }
}

// MARK: - MyCodeItemMacro

public struct MyCodeItemMacro: CodeItemMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        [
            "",
        ]
    }
}

// MARK: - MyDeclarationMacro

public struct MyDeclarationMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let argument = node.argumentList.first?.expression.as(StringLiteralExprSyntax.self) else {
            fatalError("compiler bug: the macro does not have any arguments")
        }
        return [
            """
            struct \(raw: argument.representedLiteralValue ?? "") {}
            """,
        ]
    }
}

// MARK: - MyExpressionMacro

public struct MyExpressionMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        #"""
        print("""
            \#(raw: node.argumentList.map(\.expression))
        """)
        """#
    }
}

// MARK: - MyExtensionMacro

public struct MyExtensionMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        []
    }
}

// MARK: - StringConnect

public struct StringConnect: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        let result = node.argumentList.map({
            "\($0.expression)"
        }).joined(separator: #"+"+"+"#)
        
        return .init(stringLiteral: result)
    }
}

// MARK: - ErrorMacro

struct ErrorMacro: DeclarationMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let firstElement = node.argumentList.first,
              let stringLiteral = firstElement.expression
            .as(StringLiteralExprSyntax.self),
              stringLiteral.segments.count == 1,
              case let .stringSegment(messageString) = stringLiteral.segments.first
        else {
            throw MacroExpansionErrorMessage("#error macro requires a string literal")
        }
        
        context.diagnose(
            Diagnostic(
                node: Syntax(node),
                message: MacroExpansionErrorMessage(messageString.content.description)
            )
        )
        
        return []
    }
}

// MARK: - UnwrapMacro

struct UnwrapMacro: CodeItemMacro {
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard !node.argumentList.isEmpty else {
            throw MacroExpansionErrorMessage("'#unwrap' requires arguments")
        }
        let errorThrower = node.trailingClosure
        let identifiers = try node.argumentList.map { argument in
            guard let declReferenceExpr = argument.expression.as(DeclReferenceExprSyntax.self) else {
                throw MacroExpansionErrorMessage("Arguments must be identifiers")
            }
            return declReferenceExpr.baseName
        }
        
        func elseBlock(_ token: TokenSyntax) -> CodeBlockSyntax {
            let expr: ExprSyntax
            if let errorThrower {
                expr = """
              \(errorThrower)("\(raw: token.text)")
              """
            } else {
                expr = """
              fatalError("'\(raw: token.text)' is nil")
              """
            }
            return .init(
                statements: .init([
                    .init(
                        leadingTrivia: " ",
                        item: .expr(expr),
                        trailingTrivia: " "
                    ),
                ])
            )
        }
        
        return identifiers.map { identifier -> CodeBlockItemSyntax in
            "guard let \(raw: identifier.text) else \(elseBlock(identifier))"
        }
    }
}

public struct GetterMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard 
            let variable = declaration.as(VariableDeclSyntax.self),
            let binding = variable.bindings.first,
            let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self),
            let typeAnnotationType = binding.typeAnnotation?.type
        else {
            throw MacroExpansionErrorMessage("Must attached to variables with explicit type declarations")
        }
        
        let identifierName = identifierPattern.identifier.text
        
        let newFunction = try FunctionDeclSyntax("public func get\(raw: identifierName.prefix(1).capitalized + identifierName.dropFirst())() -> \(typeAnnotationType)", bodyBuilder: {
            ExprSyntax(stringLiteral: identifierName)
        })
        
        return [DeclSyntax(newFunction)]
    }
}

public struct DeinitLogMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard declaration.as(ClassDeclSyntax.self) != nil else {
            throw MacroExpansionErrorMessage("Can only declare classes.")
        }
        
        return [
            #"deinit { print("\(self) was deinited.") }"#,
        ]
    }
}

public struct GetterMembersMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        guard
            let variable = member.as(VariableDeclSyntax.self),
            let binding = variable.bindings.first,
            binding.typeAnnotation?.type != nil
        else {
            return []
        }
        
        return ["@getter"]
    }
}

public struct StorgeBackedMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard
            let variable = declaration.as(VariableDeclSyntax.self),
            let binding = variable.bindings.first,
            let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self),
            let typeAnnotationType = binding.typeAnnotation?.type.as(OptionalTypeSyntax.self),
            let typeIdentifier = typeAnnotationType.wrappedType.as(IdentifierTypeSyntax.self)?.name
        else {
            throw MacroExpansionErrorMessage("Must attached to variables with explicit optional type declarations")
        }
        
        let identifierName = identifierPattern.identifier.text
        return [
            #"""
            set {
                _storage["\#(raw: identifierName)"] = newValue
            }
            get {
                _storage["\#(raw: identifierName)"] as? \#(typeIdentifier)
            }
            """#
        ]
    }
}

public struct ErrorTypeMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let errorExtension: DeclSyntax =
                 """
                 extension \(type.trimmed): Error {}
                 """
        
        guard let extensionDecl = errorExtension.as(ExtensionDeclSyntax.self) else {
            return []
        }
        
        return [extensionDecl]
    }
}

// MARK: - MyMacrosPlugin

@main
struct MyMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        MyDeclarationMacro.self,
        MyCodeItemMacro.self,
        MyExpressionMacro.self,
        StringConnect.self,
        ErrorMacro.self,
        UnwrapMacro.self,
        GetterMacro.self,
        DeinitLogMacro.self,
        GetterMembersMacro.self,
        StorgeBackedMacro.self,
        ErrorTypeMacro.self,
    ]
}
