/// <summary>
/// Tests for the deterministic part of the Copilot feature: the evidence JSON.
/// No Azure OpenAI calls are made here, so the tests are fast, free and repeatable.
/// </summary>
codeunit 50150 "BCIA Item History Builder Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        HistoryBuilder: Codeunit "BCIA Item History Builder";
        IsInitialized: Boolean;
        LocationNotFoundErr: Label 'No drop-shipment line found for location %1 in totalsByLocation.', Comment = '%1 = Location Code';

    [Test]
    procedure NoEntriesReturnsZeroTotals()
    var
        Item: Record Item;
        Evidence: JsonObject;
    begin
        // [SCENARIO] An item without ledger entries returns empty evidence with zero totals
        Initialize();

        // [GIVEN] A new item with no ledger entries
        LibraryInventory.CreateItem(Item);

        // [WHEN] Evidence is built
        Evidence := ReadEvidence(Item."No.", 50);

        // [THEN] No entries are shown and all totals are zero
        Assert.AreEqual(0, GetInteger(Evidence, '$.entriesShown'), 'entriesShown');
        Assert.AreEqual(0, GetDecimal(Evidence, '$.totals.allEntries'), 'totals.allEntries');
        Assert.AreEqual(0, GetDecimal(Evidence, '$.totals.dropShipEntries'), 'totals.dropShipEntries');
        Assert.IsFalse(GetBoolean(Evidence, '$.olderEntriesOmitted'), 'olderEntriesOmitted');
    end;

    [Test]
    procedure NormalEntriesOnlyHaveZeroDropShipTotal()
    var
        Item: Record Item;
        Evidence: JsonObject;
        LocationCode: Code[10];
    begin
        // [SCENARIO] Normal inventory movements are totalled and the drop-ship total stays zero
        Initialize();

        // [GIVEN] An item with a purchase of 10 and a sale of 3, no drop shipment
        LibraryInventory.CreateItem(Item);
        LocationCode := NewLocationCode();
        MockItemLedgerEntry(Item."No.", LocationCode, WorkDate(), "Item Ledger Entry Type"::Purchase, 10, false);
        MockItemLedgerEntry(Item."No.", LocationCode, WorkDate() + 1, "Item Ledger Entry Type"::Sale, -3, false);

        // [WHEN] Evidence is built
        Evidence := ReadEvidence(Item."No.", 50);

        // [THEN] Totals are calculated by AL, not left to the model
        Assert.AreEqual(7, GetDecimal(Evidence, '$.totals.allEntries'), 'totals.allEntries');
        Assert.AreEqual(7, GetDecimal(Evidence, '$.totals.normalEntries'), 'totals.normalEntries');
        Assert.AreEqual(0, GetDecimal(Evidence, '$.totals.dropShipEntries'), 'totals.dropShipEntries');
        Assert.AreEqual(2, GetInteger(Evidence, '$.entriesShown'), 'entriesShown');
    end;

    [Test]
    procedure BalancedDropShipmentNetsToZero()
    var
        Item: Record Item;
        Evidence: JsonObject;
        LocationCode: Code[10];
    begin
        // [SCENARIO] A standard drop shipment (receipt and shipment of the same quantity) nets to zero
        Initialize();

        // [GIVEN] A drop-ship purchase receipt of 5 and a drop-ship sales shipment of 5
        LibraryInventory.CreateItem(Item);
        LocationCode := NewLocationCode();
        MockItemLedgerEntry(Item."No.", LocationCode, WorkDate(), "Item Ledger Entry Type"::Purchase, 5, true);
        MockItemLedgerEntry(Item."No.", LocationCode, WorkDate(), "Item Ledger Entry Type"::Sale, -5, true);

        // [WHEN] Evidence is built
        Evidence := ReadEvidence(Item."No.", 50);

        // [THEN] The drop-ship total and the location's drop-ship line are both zero
        Assert.AreEqual(0, GetDecimal(Evidence, '$.totals.dropShipEntries'), 'totals.dropShipEntries');
        Assert.AreEqual(0, GetLocationDropShipQty(Evidence, LocationCode), 'totalsByLocation drop-ship quantity');
    end;

    [Test]
    procedure UnbalancedDropShipmentIsReportedPerLocation()
    var
        Item: Record Item;
        Evidence: JsonObject;
        BalancedLocationCode: Code[10];
        UnbalancedLocationCode: Code[10];
    begin
        // [SCENARIO] A drop-ship imbalance shows in the totals and points to the right location
        Initialize();

        // [GIVEN] A balanced drop shipment at one location
        LibraryInventory.CreateItem(Item);
        BalancedLocationCode := NewLocationCode();
        MockItemLedgerEntry(Item."No.", BalancedLocationCode, WorkDate(), "Item Ledger Entry Type"::Purchase, 4, true);
        MockItemLedgerEntry(Item."No.", BalancedLocationCode, WorkDate(), "Item Ledger Entry Type"::Sale, -4, true);

        // [GIVEN] An unbalanced drop shipment at another location: 10 received, 6 shipped
        UnbalancedLocationCode := NewLocationCode();
        MockItemLedgerEntry(Item."No.", UnbalancedLocationCode, WorkDate(), "Item Ledger Entry Type"::Purchase, 10, true);
        MockItemLedgerEntry(Item."No.", UnbalancedLocationCode, WorkDate() + 1, "Item Ledger Entry Type"::Sale, -6, true);

        // [WHEN] Evidence is built
        Evidence := ReadEvidence(Item."No.", 50);

        // [THEN] The total drop-ship imbalance is 4, all of it at the unbalanced location
        Assert.AreEqual(4, GetDecimal(Evidence, '$.totals.dropShipEntries'), 'totals.dropShipEntries');
        Assert.AreEqual(4, GetLocationDropShipQty(Evidence, UnbalancedLocationCode), 'unbalanced location');
        Assert.AreEqual(0, GetLocationDropShipQty(Evidence, BalancedLocationCode), 'balanced location');
    end;

    [Test]
    procedure EntryLimitMarksOlderEntriesOmitted()
    var
        Item: Record Item;
        Evidence: JsonObject;
    begin
        // [SCENARIO] When an item has more entries than the limit, only the limit is sent and the omission is flagged
        Initialize();

        // [GIVEN] An item with 6 ledger entries
        LibraryInventory.CreateItem(Item);
        MockEntries(Item."No.", 6);

        // [WHEN] Evidence is built with a limit of 5
        Evidence := ReadEvidence(Item."No.", 5);

        // [THEN] 5 entries are shown and older entries are flagged as omitted
        Assert.AreEqual(5, GetInteger(Evidence, '$.entriesShown'), 'entriesShown');
        Assert.IsTrue(GetBoolean(Evidence, '$.olderEntriesOmitted'), 'olderEntriesOmitted');

        // [THEN] Totals still cover all 6 entries, not only the 5 shown
        Assert.AreEqual(6, GetDecimal(Evidence, '$.totals.allEntries'), 'totals.allEntries');
    end;

    [Test]
    procedure EntryCountEqualToLimitIsNotFlaggedAsOmitted()
    var
        Item: Record Item;
        Evidence: JsonObject;
    begin
        // [SCENARIO] An item with exactly the limit of entries is complete, so nothing is flagged as omitted
        Initialize();

        // [GIVEN] An item with exactly 5 ledger entries
        LibraryInventory.CreateItem(Item);
        MockEntries(Item."No.", 5);

        // [WHEN] Evidence is built with a limit of 5
        Evidence := ReadEvidence(Item."No.", 5);

        // [THEN] All 5 entries are shown and nothing is flagged as omitted
        Assert.AreEqual(5, GetInteger(Evidence, '$.entriesShown'), 'entriesShown');
        Assert.IsFalse(GetBoolean(Evidence, '$.olderEntriesOmitted'), 'olderEntriesOmitted');
    end;

    [Test]
    procedure MostRecentEntryComesFirst()
    var
        Item: Record Item;
        Evidence: JsonObject;
        NewestEntryNo: Integer;
    begin
        // [SCENARIO] Entries are sent newest first, so the limit keeps the most recent history
        Initialize();

        // [GIVEN] Three entries on different dates, the newest posted last
        LibraryInventory.CreateItem(Item);
        MockItemLedgerEntry(Item."No.", '', WorkDate() - 2, "Item Ledger Entry Type"::Purchase, 1, false);
        MockItemLedgerEntry(Item."No.", '', WorkDate() - 1, "Item Ledger Entry Type"::Purchase, 1, false);
        NewestEntryNo := MockItemLedgerEntry(Item."No.", '', WorkDate(), "Item Ledger Entry Type"::Purchase, 1, false);

        // [WHEN] Evidence is built
        Evidence := ReadEvidence(Item."No.", 50);

        // [THEN] The first entry is the newest one
        Assert.AreEqual(NewestEntryNo, GetInteger(Evidence, '$.entries[0].entryNo'), 'first entry should be the newest');
    end;

    [Test]
    procedure ZeroLimitFallsBackToDefault()
    var
        Item: Record Item;
        Evidence: JsonObject;
    begin
        // [SCENARIO] A missing or zero limit falls back to the default of 50
        Initialize();

        // [GIVEN] Any item
        LibraryInventory.CreateItem(Item);

        // [WHEN] Evidence is built with a limit of 0
        Evidence := ReadEvidence(Item."No.", 0);

        // [THEN] The default limit of 50 is used
        Assert.AreEqual(50, GetInteger(Evidence, '$.maxEntries'), 'maxEntries');
    end;

    [Test]
    procedure PostedItemJournalIsIncludedInTotals()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Evidence: JsonObject;
    begin
        // [SCENARIO] Real posting through the item journal is picked up by the evidence builder
        Initialize();

        // [GIVEN] A positive adjustment of 12 posted through the item journal
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 12);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Evidence is built
        Evidence := ReadEvidence(Item."No.", 50);

        // [THEN] The posted quantity appears in the totals as a normal entry
        Assert.AreEqual(12, GetDecimal(Evidence, '$.totals.allEntries'), 'totals.allEntries');
        Assert.AreEqual(12, GetDecimal(Evidence, '$.totals.normalEntries'), 'totals.normalEntries');
        Assert.AreEqual(1, GetInteger(Evidence, '$.entriesShown'), 'entriesShown');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        // Shared setup for all tests goes here. Each test creates its own item,
        // so tests do not depend on each other or on demo data.
        IsInitialized := true;
    end;

    local procedure ReadEvidence(ItemNo: Code[20]; MaxEntries: Integer) Evidence: JsonObject
    begin
        Evidence.ReadFrom(HistoryBuilder.BuildEvidence(ItemNo, MaxEntries));
    end;

    local procedure MockEntries(ItemNo: Code[20]; EntryCount: Integer)
    var
        Counter: Integer;
    begin
        for Counter := 1 to EntryCount do
            MockItemLedgerEntry(ItemNo, '', WorkDate() - EntryCount + Counter, "Item Ledger Entry Type"::Purchase, 1, false);
    end;

    local procedure MockItemLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10]; PostingDate: Date; EntryType: Enum "Item Ledger Entry Type"; Qty: Decimal; DropShipment: Boolean): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Location Code" := LocationCode;
        ItemLedgerEntry."Posting Date" := PostingDate;
        ItemLedgerEntry."Entry Type" := EntryType;
        ItemLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        ItemLedgerEntry.Quantity := Qty;
        ItemLedgerEntry."Drop Shipment" := DropShipment;
        ItemLedgerEntry.Positive := Qty > 0;
        ItemLedgerEntry.Open := Qty > 0;
        if Qty > 0 then
            ItemLedgerEntry."Remaining Quantity" := Qty;
        // Test-only mock data: triggers are skipped on purpose to create exact ledger situations
        // (such as an unbalanced drop shipment) that standard posting would not produce.
        ItemLedgerEntry.Insert();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure GetNextItemLedgerEntryNo(): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetLoadFields("Entry No.");
        if ItemLedgerEntry.FindLast() then
            exit(ItemLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure NewLocationCode(): Code[10]
    begin
        exit(CopyStr(LibraryUtility.GenerateGUID(), 1, 10));
    end;

    local procedure GetDecimal(Evidence: JsonObject; Path: Text): Decimal
    var
        Token: JsonToken;
    begin
        Evidence.SelectToken(Path, Token);
        exit(Token.AsValue().AsDecimal());
    end;

    local procedure GetInteger(Evidence: JsonObject; Path: Text): Integer
    var
        Token: JsonToken;
    begin
        Evidence.SelectToken(Path, Token);
        exit(Token.AsValue().AsInteger());
    end;

    local procedure GetBoolean(Evidence: JsonObject; Path: Text): Boolean
    var
        Token: JsonToken;
    begin
        Evidence.SelectToken(Path, Token);
        exit(Token.AsValue().AsBoolean());
    end;

    local procedure GetLocationDropShipQty(Evidence: JsonObject; LocationCode: Code[10]): Decimal
    var
        LinesToken: JsonToken;
        LineToken: JsonToken;
        Line: JsonObject;
    begin
        Evidence.Get('totalsByLocation', LinesToken);
        foreach LineToken in LinesToken.AsArray() do begin
            Line := LineToken.AsObject();
            if IsDropShipLineForLocation(Line, LocationCode) then
                exit(GetLineDecimal(Line, 'quantity'));
        end;
        Error(LocationNotFoundErr, LocationCode);
    end;

    local procedure IsDropShipLineForLocation(Line: JsonObject; LocationCode: Code[10]): Boolean
    var
        ValueToken: JsonToken;
    begin
        Line.Get('location', ValueToken);
        if ValueToken.AsValue().AsCode() <> LocationCode then
            exit(false);
        Line.Get('dropShipment', ValueToken);
        exit(ValueToken.AsValue().AsBoolean());
    end;

    local procedure GetLineDecimal(Line: JsonObject; KeyName: Text): Decimal
    var
        ValueToken: JsonToken;
    begin
        Line.Get(KeyName, ValueToken);
        exit(ValueToken.AsValue().AsDecimal());
    end;
}
