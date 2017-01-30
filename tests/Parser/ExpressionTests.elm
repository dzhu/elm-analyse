module Parser.ExpressionTests exposing (..)

import Combine exposing ((*>), whitespace)
import Parser.CombineTestUtil exposing (..)
import Expect
import Parser.Declarations exposing (..)
import AST.Types exposing (..)
import Test exposing (..)


all : Test
all =
    describe "ExpressionTests"
        [ test "empty" <|
            \() ->
                parseFullStringWithNullState "" expression
                    |> Expect.equal Nothing
        , test "String literal" <|
            \() ->
                parseFullStringWithNullState "\"Bar\"" expression
                    |> Expect.equal (Just (Literal "Bar"))
        , test "character literal" <|
            \() ->
                parseFullStringWithNullState "'c'" expression
                    |> Expect.equal (Just (CharLiteral 'c'))
        , test "tuple expression" <|
            \() ->
                parseFullStringWithNullState "(1,2)" expression
                    |> Expect.equal (Just (TupledExpression [ Integer 1, Integer 2 ]))
        , test "prefix expression" <|
            \() ->
                parseFullStringWithNullState "(,)" expression
                    |> Expect.equal (Just (PrefixOperator ","))
        , test "String literal multiline" <|
            \() ->
                parseFullStringWithNullState "\"\"\"Bar foo \n a\"\"\"" expression
                    |> Expect.equal (Just (Literal "Bar foo \n a"))
        , test "Type expression" <|
            \() ->
                parseFullStringWithNullState "Bar" expression
                    |> Expect.equal (Just (FunctionOrValue "Bar"))
        , test "Type expression" <|
            \() ->
                parseFullStringWithNullState "bar" expression
                    |> Expect.equal (Just (FunctionOrValue "bar"))
        , test "operator" <|
            \() ->
                parseFullStringWithNullState "++" expression
                    |> Expect.equal (Just (Operator "++"))
        , test "parenthesizedExpression" <|
            \() ->
                parseFullStringWithNullState "(bar)" expression
                    |> Expect.equal (Just (ParenthesizedExpression { expression = (FunctionOrValue "bar"), range = { start = { row = 1, column = 0 }, end = { row = 1, column = 5 } } }))
        , test "expressionNotApplication simple" <|
            \() ->
                parseFullStringWithNullState "foo" expression
                    |> Expect.equal (Just (FunctionOrValue "foo"))
        , test "unit application" <|
            \() ->
                parseFullStringWithNullState "Task.succeed ()" expression
                    |> Expect.equal
                        (Just
                            (Application
                                [ QualifiedExpr [ "Task" ] { value = "succeed", range = { start = { row = 1, column = 5 }, end = { row = 1, column = 12 } } }
                                , UnitExpr
                                ]
                            )
                        )
        , test "compoundExpression" <|
            \() ->
                parseFullStringWithNullState "foo bar" expression
                    |> Expect.equal
                        (Just
                            (Application
                                [ FunctionOrValue "foo"
                                , FunctionOrValue "bar"
                                ]
                            )
                        )
        , test "compoundExpression 2" <|
            \() ->
                parseFullStringWithNullState "{ key = value } ! []" expression
                    |> Expect.equal
                        (Just (Application ([ RecordExpr ([ ( "key", FunctionOrValue "value" ) ]), Operator "!", ListExpr [] ])))
        , test "ifBlockExpression" <|
            \() ->
                parseFullStringWithNullState "if True then foo else bar" expression
                    |> Expect.equal
                        (Just
                            (IfBlock
                                (FunctionOrValue "True")
                                (FunctionOrValue "foo")
                                (FunctionOrValue "bar")
                            )
                        )
        , test "nestedIfExpression" <|
            \() ->
                parseFullStringWithNullState "if True then if False then foo else baz else bar" expression
                    |> Expect.equal
                        (Just
                            (IfBlock
                                (FunctionOrValue "True")
                                (IfBlock
                                    (FunctionOrValue "False")
                                    (FunctionOrValue "foo")
                                    (FunctionOrValue "baz")
                                )
                                (FunctionOrValue "bar")
                            )
                        )
        , test "recordExpression" <|
            \() ->
                parseFullStringWithNullState "{ model = 0, view = view, update = update }" expression
                    |> Expect.equal
                        (Just
                            (RecordExpr
                                [ ( "model", Integer 0 )
                                , ( "view", FunctionOrValue "view" )
                                , ( "update", FunctionOrValue "update" )
                                ]
                            )
                        )
        , test "recordExpression with comment" <|
            \() ->
                parseFullStringWithNullState "{ foo = 1 -- bar\n , baz = 2 }" expression
                    |> Expect.equal
                        (Just
                            (RecordExpr
                                [ ( "foo", Integer 1 )
                                , ( "baz", Integer 2 )
                                ]
                            )
                        )
        , test "listExpression" <|
            \() ->
                parseFullStringWithNullState "[ class \"a\", text \"Foo\"]" expression
                    |> Expect.equal
                        (Just
                            (ListExpr
                                [ Application [ FunctionOrValue "class", Literal "a" ]
                                , Application [ FunctionOrValue "text", Literal "Foo" ]
                                ]
                            )
                        )
        , test "listExpression empty" <|
            \() ->
                parseFullStringWithNullState "[\n]" expression
                    |> Expect.equal (Just (ListExpr []))
        , test "listExpression on indent" <|
            \() ->
                parseFullStringWithNullState "  [\n]" (whitespace *> expression)
                    |> Expect.equal (Just (ListExpr []))
        , test "qualified expression" <|
            \() ->
                parseFullStringWithNullState "Html.text" expression
                    |> Expect.equal (Just (QualifiedExpr [ "Html" ] { value = "text", range = { start = { row = 1, column = 5 }, end = { row = 1, column = 9 } } }))
        , test "record access" <|
            \() ->
                parseFullStringWithNullState "foo.bar" expression
                    |> Expect.equal (Just (RecordAccess [ "foo", "bar" ]))
        , test "record update" <|
            \() ->
                parseFullStringWithNullState "{ model | count = 1, loading = True }" expression
                    |> Expect.equal
                        (Just
                            (RecordUpdateExpression
                                { name = "model"
                                , updates =
                                    [ ( "count", Integer 1 )
                                    , ( "loading", FunctionOrValue "True" )
                                    ]
                                }
                            )
                        )
        , test "record update no spacing" <|
            \() ->
                parseFullStringWithNullState "{model| count = 1, loading = True }" expression
                    |> Expect.equal
                        (Just
                            (RecordUpdateExpression
                                { name = "model"
                                , updates =
                                    [ ( "count", Integer 1 )
                                    , ( "loading", FunctionOrValue "True" )
                                    ]
                                }
                            )
                        )
        , test "record access as function" <|
            \() ->
                parseFullStringWithNullState "List.map .name people" expression
                    |> Expect.equal
                        (Just
                            (Application
                                [ QualifiedExpr [ "List" ] { value = "map", range = { start = { row = 1, column = 5 }, end = { row = 1, column = 8 } } }
                                , RecordAccessFunction ".name"
                                , FunctionOrValue "people"
                                ]
                            )
                        )
        , test "prefix notation" <|
            \() ->
                parseFullStringWithNullState "(::) x" expression
                    |> Expect.equal
                        (Just <|
                            Application
                                [ PrefixOperator "::"
                                , FunctionOrValue "x"
                                ]
                        )
        ]
