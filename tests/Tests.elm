module Tests exposing (..)

import Interfaces.InterfaceTest as InterfaceTest
import Interfaces.DependencyTests as DependencyTests
import Analyser.PostProcessingTests as PostProcessingTests
import Test exposing (Test)
import Parser.Tests as ParserTests
import Analyser.Checks.NoSignatureTests
import Analyser.Checks.UnusedVariableTests
import Analyser.Checks.NotExposeAllTests
import Analyser.Checks.NoImportAllTests
import Analyser.Checks.UnnecessaryParensTests


all : Test
all =
    Test.concat
        [ Analyser.Checks.UnnecessaryParensTests.all
        , Analyser.Checks.UnusedVariableTests.all
        , Analyser.Checks.NoSignatureTests.all
        , Analyser.Checks.NoImportAllTests.all
        , Analyser.Checks.NotExposeAllTests.all
        , InterfaceTest.all
        , DependencyTests.all
        , PostProcessingTests.all
        , ParserTests.all
        ]
