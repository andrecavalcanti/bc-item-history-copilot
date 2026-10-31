/// <summary>
/// Tests for the investigation framework: every problem module plugs into the Copilot evidence
/// and the system prompt, and each module reports exactly what it should.
/// </summary>
codeunit 58052 "BCIA Problem Module Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        TestLibrary: Codeunit "BCIA Test Library";
        ProblemModules: Codeunit "BCIA Problem Modules";
        HistoryBuilder: Codeunit "BCIA Item History Builder";

    [Test]
    procedure EveryProblemTypeHasPromptRules()
    var
        ProblemModule: Interface "BCIA Problem Module";
        ProblemType: Enum "BCIA Problem Type";
        Ordinal: Integer;
    begin
        // [SCENARIO] A module without prompt rules would add facts the model doesn't know how to read

        // [WHEN] / [THEN] Every problem type except the blank one returns prompt rules
        foreach Ordinal in Enum::"BCIA Problem Type".Ordinals() do begin
            ProblemType := Enum::"BCIA Problem Type".FromInteger(Ordinal);
            ProblemModule := ProblemType;
            if ProblemType <> ProblemType::" " then
                Assert.AreNotEqual('', ProblemModule.GetPromptRules(), StrSubstNo('prompt rules for %1', ProblemType));
        end;
    end;

    [Test]
    procedure PromptRulesIncludeEveryModule()
    var
        Rules: Text;
    begin
        // [SCENARIO] The Copilot system prompt gets the rules of every module

        // [WHEN] The combined rules are built
        Rules := ProblemModules.GetPromptRules();

        // [THEN] Both modules are included
        Assert.IsTrue(Rules.Contains('checks.dropShipment'), 'drop shipment rule is missing');
        Assert.IsTrue(Rules.Contains('checks.negativeInventory'), 'negative inventory rule is missing');
    end;

    [Test]
    procedure EvidenceContainsChecksFromEveryModule()
    var
        Item: Record Item;
        Evidence: JsonObject;
        Token: JsonToken;
    begin
        // [SCENARIO] The Copilot evidence for an item includes a section from every module

        // [GIVEN] Any item
        LibraryInventory.CreateItem(Item);

        // [WHEN] Evidence is built
        Evidence.ReadFrom(HistoryBuilder.BuildEvidence(Item."No.", 50));

        // [THEN] Both module sections are present
        Assert.IsTrue(Evidence.SelectToken('$.checks.dropShipment', Token), 'checks.dropShipment is missing');
        Assert.IsTrue(Evidence.SelectToken('$.checks.negativeInventory', Token), 'checks.negativeInventory is missing');
    end;

    [Test]
    procedure DropShipModuleListsUnbalancedLocation()
    var
        Item: Record Item;
        Checks: JsonObject;
        LocationCode: Code[10];
    begin
        // [SCENARIO] The drop-ship module reports the unbalanced location and its net quantity

        // [GIVEN] A drop shipment with 10 received and 6 shipped
        LibraryInventory.CreateItem(Item);
        LocationCode := TestLibrary.NewLocationCode();
        TestLibrary.MockItemLedgerEntry(Item."No.", LocationCode, "Item Ledger Entry Type"::Purchase, 10, true);
        TestLibrary.MockItemLedgerEntry(Item."No.", LocationCode, "Item Ledger Entry Type"::Sale, -6, true);

        // [WHEN] The checks are built
        Checks := ProblemModules.BuildItemChecks(Item."No.");

        // [THEN] The location is listed with a net quantity of 4 and the item is not balanced
        Assert.IsFalse(GetBoolean(Checks, '$.dropShipment.balanced'), 'balanced');
        Assert.AreEqual(LocationCode, GetText(Checks, '$.dropShipment.unbalancedLocations[0].location'), 'location');
        Assert.AreEqual(4, GetDecimal(Checks, '$.dropShipment.unbalancedLocations[0].netQuantity'), 'net quantity');
    end;

    [Test]
    procedure NegativeInventoryModuleListsLocation()
    var
        Item: Record Item;
        Checks: JsonObject;
        LocationCode: Code[10];
    begin
        // [SCENARIO] The negative inventory module reports where stock went below zero

        // [GIVEN] An open outbound entry of 7 that could not be applied to stock
        LibraryInventory.CreateItem(Item);
        LocationCode := TestLibrary.NewLocationCode();
        TestLibrary.MockOpenNegativeEntry(Item."No.", LocationCode, 7);

        // [WHEN] The checks are built
        Checks := ProblemModules.BuildItemChecks(Item."No.");

        // [THEN] The location is listed with -7
        Assert.IsTrue(GetBoolean(Checks, '$.negativeInventory.hasNegativeInventory'), 'hasNegativeInventory');
        Assert.AreEqual(LocationCode, GetText(Checks, '$.negativeInventory.locations[0].location'), 'location');
        Assert.AreEqual(-7, GetDecimal(Checks, '$.negativeInventory.locations[0].openNegativeQuantity'), 'open negative quantity');
    end;

    [Test]
    procedure HealthyItemHasNoFlags()
    var
        Item: Record Item;
        Checks: JsonObject;
    begin
        // [SCENARIO] An item with normal, covered stock raises no flag in any module

        // [GIVEN] An item with a normal purchase of 10
        LibraryInventory.CreateItem(Item);
        TestLibrary.MockItemLedgerEntry(Item."No.", TestLibrary.NewLocationCode(), "Item Ledger Entry Type"::Purchase, 10, false);

        // [WHEN] The checks are built
        Checks := ProblemModules.BuildItemChecks(Item."No.");

        // [THEN] Drop shipment is balanced and there is no negative inventory
        Assert.IsTrue(GetBoolean(Checks, '$.dropShipment.balanced'), 'drop shipment should be balanced');
        Assert.IsFalse(GetBoolean(Checks, '$.negativeInventory.hasNegativeInventory'), 'no negative inventory expected');
    end;

    local procedure GetBoolean(Json: JsonObject; Path: Text): Boolean
    var
        Token: JsonToken;
    begin
        Json.SelectToken(Path, Token);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure GetDecimal(Json: JsonObject; Path: Text): Decimal
    var
        Token: JsonToken;
    begin
        Json.SelectToken(Path, Token);
        exit(Token.AsValue().AsDecimal());
    end;

    local procedure GetText(Json: JsonObject; Path: Text): Text
    var
        Token: JsonToken;
    begin
        Json.SelectToken(Path, Token);
        exit(Token.AsValue().AsText());
    end;
}
