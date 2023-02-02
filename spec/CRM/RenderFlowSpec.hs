module CRM.RenderFlowSpec where

import "crm" CRM.Example.LockDoor (SLockDoorVertex (..), lockDoorMachine)
import "crm" CRM.Example.RiskManager.Application (riskApplication)
import "crm" CRM.Render (Mermaid (..), baseMachineAsGraph, renderGraph)
import "crm" CRM.RenderFlow (MachineLabel (..), TreeMetadata (..), renderFlow)
import "crm" CRM.StateMachine (StateMachineT (..), stateless)
import "base" Data.Functor.Identity (Identity)
import "base" Data.List (singleton)
import "hspec" Test.Hspec

spec :: Spec
spec =
  describe "RenderFlow" $ do
    describe "renderFlow" $ do
      it "renders correctly a base machine" $ do
        renderFlow @Identity (LeafLabel "lockMachine") (Basic $ lockDoorMachine SIsLockClosed)
          `shouldBe` Right
            ( Mermaid "state lockMachine {"
                <> ( renderGraph . baseMachineAsGraph @_ @_ @_ @_ @Identity $
                      lockDoorMachine SIsLockClosed
                   )
                <> Mermaid "}"
            , MachineLabel "lockMachine"
            , MachineLabel "lockMachine"
            )

      it "renders correctly a Compose machine" $ do
        renderFlow
          @Identity
          (BinaryLabel (LeafLabel "show") (LeafLabel "length"))
          ( Compose
              (stateless $ show @Int)
              (stateless length)
          )
          `shouldBe` Right
            ( Mermaid "state show {\n\n}\nstate length {\n\n}\nshow --> length"
            , MachineLabel "show"
            , MachineLabel "length"
            )

      it "renders correctly a Parallel machine" $ do
        renderFlow
          @Identity
          (BinaryLabel (LeafLabel "foo") (LeafLabel "bar"))
          ( Parallel
              (stateless $ show @Int)
              (stateless $ length @[] @String)
          )
          `shouldBe` Right
            ( Mermaid "state foo {\n\n}\nstate bar {\n\n}\nstate fork_foobar <<fork>>\nstate join_foobar <<join>>\nfork_foobar --> foo\nfork_foobar --> bar\nfoo --> join_foobar\nbar --> join_foobar"
            , MachineLabel "fork_foobar"
            , MachineLabel "join_foobar"
            )

      it "renders correctly an Alternative machine" $ do
        renderFlow
          @Identity
          (BinaryLabel (LeafLabel "foo") (LeafLabel "bar"))
          ( Alternative
              (stateless $ show @Int)
              (stateless $ length @[] @String)
          )
          `shouldBe` Right
            ( Mermaid "state foo {\n\n}\nstate bar {\n\n}\nstate fork_choice_foobar <<choice>>\nstate join_choice_foobar <<choice>>\nfork_choice_foobar --> foo\nfork_choice_foobar --> bar\nfoo --> join_choice_foobar\nbar --> join_choice_foobar"
            , MachineLabel "fork_choice_foobar"
            , MachineLabel "join_choice_foobar"
            )

      it "renders correctly a Feedback machine" $ do
        renderFlow
          @Identity
          (BinaryLabel (LeafLabel "foo") (LeafLabel "bar"))
          ( Feedback
              (stateless $ singleton @Int)
              (stateless $ singleton @Int)
          )
          `shouldBe` Right
            ( Mermaid "state foo {\n\n}\nstate bar {\n\n}\nfoo --> bar\nbar --> foo"
            , MachineLabel "foo"
            , MachineLabel "foo"
            )

      it "renders correctly a Kleisli machine" $ do
        renderFlow
          @Identity
          (BinaryLabel (LeafLabel "show") (LeafLabel "length"))
          ( Kleisli
              (stateless $ singleton @Int)
              (stateless $ singleton @Int)
          )
          `shouldBe` Right
            ( Mermaid "state show {\n\n}\nstate length {\n\n}\nshow --> length"
            , MachineLabel "show"
            , MachineLabel "length"
            )

      it "renders correctly the RiskManager machine" $ do
        renderFlow
          @Identity
          ( BinaryLabel
              ( BinaryLabel
                  ( BinaryLabel
                      (LeafLabel "aggregate")
                      (LeafLabel "policy")
                  )
                  (LeafLabel "projection")
              )
              (LeafLabel "mconcat")
          )
          riskApplication
          `shouldBe` Right
            ( Mermaid "state aggregate {\nNoDataVertex --> CollectedUserDataVertex\nCollectedUserDataVertex --> CollectedLoanDetailsFirstVertex\nCollectedUserDataVertex --> ReceivedCreditBureauDataFirstVertex\nCollectedLoanDetailsFirstVertex --> CollectedAllDataVertex\nReceivedCreditBureauDataFirstVertex --> CollectedAllDataVertex\n\n}\nstate policy {\n\n}\naggregate --> policy\npolicy --> aggregate\nstate projection {\n\n}\naggregate --> projection\nstate mconcat {\n\n}\nprojection --> mconcat"
            , "aggregate"
            , "mconcat"
            )
