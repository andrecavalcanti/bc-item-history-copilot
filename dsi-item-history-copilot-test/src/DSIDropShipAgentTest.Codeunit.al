/// <summary>
/// Tests for the BC side of the drop-ship investigator agent:
/// the imbalance query the agent reads, and the rules that keep the agent's write access safe.
/// </summary>
codeunit 50151 "DSI Drop Ship Agent Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        FindingReview: Codeunit "DSI Finding Review";

    [Test]
    procedure ImbalanceQueryReturnsOnlyUnbalancedLocations()
    var
        Item: Record Item;
        BalancedLocationCode: Code[10];
        UnbalancedLocationCode: Code[10];
    begin
        // [SCENARIO] The agent's imbalance tool returns only item/location combinations that do not net to zero

        // [GIVEN] A balanced drop shipment at one location and an unbalanced one (10 in, 6 out) at another
        LibraryInventory.CreateItem(Item);
        BalancedLocationCode := NewLocationCode();
        UnbalancedLocationCode := NewLocationCode();
        MockDropShipEntry(Item."No.", BalancedLocationCode, "Item Ledger Entry Type"::Purchase, 5);
        MockDropShipEntry(Item."No.", BalancedLocationCode, "Item Ledger Entry Type"::Sale, -5);
        MockDropShipEntry(Item."No.", UnbalancedLocationCode, "Item Ledger Entry Type"::Purchase, 10);
        MockDropShipEntry(Item."No.", UnbalancedLocationCode, "Item Ledger Entry Type"::Sale, -6);

        // [WHEN] / [THEN] Only the unbalanced location is returned, with a net quantity of 4
        Assert.AreEqual(1, CountImbalances(Item."No."), 'number of imbalanced locations');
        Assert.AreEqual(4, GetImbalance(Item."No.", UnbalancedLocationCode), 'net quantity at the unbalanced location');
    end;

    [Test]
    procedure ImbalanceQueryIgnoresNormalEntries()
    var
        Item: Record Item;
        LocationCode: Code[10];
    begin
        // [SCENARIO] Normal (non drop-ship) stock never shows up as a drop-ship imbalance

        // [GIVEN] An item with 10 units of normal stock and no drop-ship entries
        LibraryInventory.CreateItem(Item);
        LocationCode := NewLocationCode();
        MockItemLedgerEntry(Item."No.", LocationCode, "Item Ledger Entry Type"::Purchase, 10, false);

        // [WHEN] / [THEN] The imbalance query returns nothing for the item
        Assert.AreEqual(0, CountImbalances(Item."No."), 'number of imbalanced locations');
    end;

    [Test]
    procedure NewFindingAlwaysStartsAsNew()
    var
        Finding: Record "DSI Drop Ship Finding";
    begin
        // [SCENARIO] Even if a caller (the agent) sends another status, a new finding is always unreviewed

        // [GIVEN] A finding that arrives with status Done and a reviewer already filled in
        Finding.Init();
        Finding."Root Cause" := 'Test root cause';
        Finding.Status := Finding.Status::Done;
        Finding."Reviewed By" := 'SOMEONE';

        // [WHEN] It is inserted with triggers, as the API page does
        Finding.Insert(true);

        // [THEN] Status is New and no reviewer is recorded
        Finding.Get(Finding."Entry No.");
        Assert.IsTrue(Finding.Status = Finding.Status::New, 'status after insert should be New');
        Assert.AreEqual('', Finding."Reviewed By", 'reviewed by after insert');
    end;

    [Test]
    procedure AcceptRecordsReviewer()
    var
        Finding: Record "DSI Drop Ship Finding";
    begin
        // [SCENARIO] Accepting a finding records who reviewed it and when

        // [GIVEN] A new finding
        CreateFinding(Finding);

        // [WHEN] A person accepts it
        FindingReview.Accept(Finding);

        // [THEN] Status, reviewer and review time are set
        Finding.Get(Finding."Entry No.");
        Assert.IsTrue(Finding.Status = Finding.Status::Accepted, 'status should be Accepted');
        Assert.AreEqual(CopyStr(UserId(), 1, MaxStrLen(Finding."Reviewed By")), Finding."Reviewed By", 'reviewed by');
        Assert.AreNotEqual(0DT, Finding."Reviewed At", 'reviewed at');
    end;

    [Test]
    procedure RejectedFindingCannotBeAccepted()
    var
        Finding: Record "DSI Drop Ship Finding";
    begin
        // [SCENARIO] A decision cannot be overwritten: a rejected finding cannot be accepted later

        // [GIVEN] A rejected finding
        CreateFinding(Finding);
        FindingReview.Reject(Finding);

        // [WHEN] Someone tries to accept it
        asserterror FindingReview.Accept(Finding);

        // [THEN] An error explains that only new findings can be reviewed
        Assert.ExpectedError('Only findings with status New');
    end;

    [Test]
    procedure OnlyAcceptedFindingCanBeMarkedDone()
    var
        Finding: Record "DSI Drop Ship Finding";
    begin
        // [SCENARIO] A finding must be accepted before it can be marked as done

        // [GIVEN] A new, unreviewed finding
        CreateFinding(Finding);

        // [WHEN] Someone tries to mark it as done
        asserterror FindingReview.MarkDone(Finding);

        // [THEN] An error explains that it must be accepted first
        Assert.ExpectedError('Only accepted findings');

        // [WHEN] It is accepted and then marked as done
        Finding.Get(Finding."Entry No.");
        FindingReview.Accept(Finding);
        FindingReview.MarkDone(Finding);

        // [THEN] Its status is Done
        Finding.Get(Finding."Entry No.");
        Assert.IsTrue(Finding.Status = Finding.Status::Done, 'status should be Done');
    end;

    local procedure CreateFinding(var Finding: Record "DSI Drop Ship Finding")
    begin
        Finding.Init();
        Finding."Imbalance Qty." := 4;
        Finding."Root Cause" := 'Test root cause';
        Finding."Proposed Fix" := 'Test proposed fix';
        Finding.Confidence := Finding.Confidence::Medium;
        Finding.Insert(true);
    end;

    local procedure CountImbalances(ItemNo: Code[20]) Result: Integer
    var
        DropShipImbalance: Query "DSI Drop Ship Imbalance API";
    begin
        DropShipImbalance.SetRange(itemNo, ItemNo);
        DropShipImbalance.Open();
        while DropShipImbalance.Read() do
            Result += 1;
        DropShipImbalance.Close();
    end;

    local procedure GetImbalance(ItemNo: Code[20]; LocationCode: Code[10]) NetQuantity: Decimal
    var
        DropShipImbalance: Query "DSI Drop Ship Imbalance API";
    begin
        DropShipImbalance.SetRange(itemNo, ItemNo);
        DropShipImbalance.SetRange(locationCode, LocationCode);
        DropShipImbalance.Open();
        if DropShipImbalance.Read() then
            NetQuantity := DropShipImbalance.netQuantity;
        DropShipImbalance.Close();
    end;

    local procedure MockDropShipEntry(ItemNo: Code[20]; LocationCode: Code[10]; EntryType: Enum "Item Ledger Entry Type"; Qty: Decimal)
    begin
        MockItemLedgerEntry(ItemNo, LocationCode, EntryType, Qty, true);
    end;

    local procedure MockItemLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10]; EntryType: Enum "Item Ledger Entry Type"; Qty: Decimal; DropShipment: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Location Code" := LocationCode;
        ItemLedgerEntry."Posting Date" := WorkDate();
        ItemLedgerEntry."Entry Type" := EntryType;
        ItemLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        ItemLedgerEntry.Quantity := Qty;
        ItemLedgerEntry."Drop Shipment" := DropShipment;
        ItemLedgerEntry.Positive := Qty > 0;
        // Test-only mock data: triggers are skipped on purpose to create exact ledger situations.
        ItemLedgerEntry.Insert();
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
}
