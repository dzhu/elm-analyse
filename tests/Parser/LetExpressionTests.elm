module Parser.LetExpressionTests exposing (..)

import Combine exposing ((*>), string, whitespace)
import Parser.CombineTestUtil exposing (..)
import Expect
import Parser.Declarations as Parser exposing (..)
import Parser.Tokens exposing (functionName)
import AST.Types as Types exposing (..)
import Test exposing (..)


all : Test
all =
    describe "LetExpressionTests"
        [ test "let body" <|
            \() ->
                parseFullStringState (emptyState |> pushIndent 2) "foo = bar\n  \n  john = doe" Parser.letBody
                    |> Expect.equal
                        (Just ([ FuncDecl { documentation = Nothing, signature = Nothing, declaration = { operatorDefinition = False, name = { value = "foo", range = { start = { row = 1, column = 0 }, end = { row = 1, column = 3 } } }, arguments = [], expression = FunctionOrValue "bar" } }, FuncDecl { documentation = Nothing, signature = Nothing, declaration = { operatorDefinition = False, name = { value = "john", range = { start = { row = 3, column = 2 }, end = { row = 3, column = 6 } } }, arguments = [], expression = FunctionOrValue "doe" } } ]))
        , test "let block" <|
            \() ->
                parseFullStringState emptyState "let\n  foo = bar\n  \n  john = doe\n in" Parser.letBlock
                    |> Expect.equal
                        (Just ([ FuncDecl { documentation = Nothing, signature = Nothing, declaration = { operatorDefinition = False, name = { value = "foo", range = { start = { row = 1, column = 1 }, end = { row = 1, column = 4 } } }, arguments = [], expression = FunctionOrValue "bar" } }, FuncDecl { documentation = Nothing, signature = Nothing, declaration = { operatorDefinition = False, name = { value = "john", range = { start = { row = 3, column = 1 }, end = { row = 3, column = 5 } } }, arguments = [], expression = FunctionOrValue "doe" } } ]))
        , test "correct let with indent" <|
            \() ->
                parseFullStringState (emptyState |> pushIndent 1) "let\n  bar = 1\n in\n  bar" Parser.expression
                    |> Expect.equal
                        (Just (LetExpression { declarations = [ FuncDecl { documentation = Nothing, signature = Nothing, declaration = { operatorDefinition = False, name = { value = "bar", range = { start = { row = 1, column = 1 }, end = { row = 1, column = 4 } } }, arguments = [], expression = Integer 1 } } ], expression = FunctionOrValue "bar" }))
        , test "let with deindented expression in in" <|
            \() ->
                parseFullStringState emptyState "let\n  bar = 1\n in\n   bar" Parser.expression
                    |> Expect.equal
                        (Just (LetExpression { declarations = [ FuncDecl { documentation = Nothing, signature = Nothing, declaration = { operatorDefinition = False, name = { value = "bar", range = { start = { row = 1, column = 1 }, end = { row = 1, column = 4 } } }, arguments = [], expression = Integer 1 } } ], expression = FunctionOrValue "bar" }))
        , test "let in list" <|
            \() ->
                parseFullStringState emptyState "[\n  let\n    bar = 1\n  in\n    bar\n ]" Parser.expression
                    |> Expect.equal
                        (Just (ListExpr ([ LetExpression { declarations = [ FuncDecl { documentation = Nothing, signature = Nothing, declaration = { operatorDefinition = False, name = { value = "bar", range = { start = { row = 2, column = 3 }, end = { row = 2, column = 6 } } }, arguments = [], expression = Integer 1 } } ], expression = FunctionOrValue "bar" } ])))
        , test "some let" <|
            \() ->
                parseFullStringState emptyState "let\n    _ = b\n in\n    z" (Parser.expression)
                    |> Expect.equal
                        (Just
                            (LetExpression
                                { declarations =
                                    ([ DestructuringDeclaration { pattern = AllPattern, expression = (FunctionOrValue "b") }
                                     ]
                                    )
                                , expression = (FunctionOrValue "z")
                                }
                            )
                        )
        , test "let inlined" <|
            \() ->
                parseFullStringState emptyState "let indent = String.length s in indent" (Parser.expression)
                    |> Expect.equal
                        (Just (LetExpression { declarations = [ FuncDecl { documentation = Nothing, signature = Nothing, declaration = { operatorDefinition = False, name = { value = "indent", range = { start = { row = 1, column = 4 }, end = { row = 1, column = 10 } } }, arguments = [], expression = Application ([ QualifiedExpr [ "String" ] { value = "length", range = { start = { row = 1, column = 20 }, end = { row = 1, column = 26 } } }, FunctionOrValue "s" ]) } } ], expression = FunctionOrValue "indent" }))
        , test "let starting after definition" <|
            \() ->
                parseFullStringState emptyState "foo = let\n  indent = 1\n in\n indent" (functionName *> string " = " *> Parser.expression)
                    |> Expect.equal
                        (Just (LetExpression { declarations = [ FuncDecl { documentation = Nothing, signature = Nothing, declaration = { operatorDefinition = False, name = { value = "indent", range = { start = { row = 1, column = 1 }, end = { row = 1, column = 7 } } }, arguments = [], expression = Integer 1 } } ], expression = FunctionOrValue "indent" }))
        ]
