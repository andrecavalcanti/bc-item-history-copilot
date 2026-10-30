/// <summary>
/// Tests for the BC side of the investigation agent: the read tools it relies on,
/// and the rules that keep its write access safe.
/// </summary>
codeunit 50151 "BCIA Investigation Agent Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        TestLibrary: Codeunit "BCIA Test Library";
        FindingReview: Codeunit "BCIA Finding Review";

    [Test]
    procedure ImbalanceQueryReturnsOnlyUnbalancedLocations()
    var
        Item: Record Item;
        BalancedLocationCode: Code[10];
        UnbalancedLocationCode: Code[10];
    begin
        // [SCENARIO] The drop-ship tool returns only item/location combinations that do not net to zero

        // [GIVEN] A balanced drop shipment at one location and an unbalanced one (10 in, 6 out) at another
        LibraryInventory.CreateItem(Item);
        BalancedLocationCode := TestLibrary.NewLocationCode();
        UnbalancedLocationCode := TestLibrary.NewLocationCode();
        TestLibrary.MockItemLedgerEntry(Item."No.", BalancedLocationCode, "Item Ledger Entry Type"::Purchase, 5, true);
        TestLibrary.MockItemLedgerEntry(Item."No.", BalancedLocationCode, "Item Ledger Entry Type"::Sale, -5, true);
        TestLibrary.MockItemLedgerEntry(Item."No.", UnbalancedLocationCode, "Item Ledger Entry Type"::Purchase, 10, true);
        TestLibrary.MockItemLedgerEntry(Item."No.", UnbalancedLocationCode, "Item Ledger Entry Type"::Sale, -6, true);

        // [WHEN] / [THEN] Only the unbalanced location is returned, with a net quantity of 4
        Assert.AreEqual(1, CountDropShipImbalances(Item."No."), 'number of imbalanced locations');
        Assert.AreEqual(4, GetDropShipImbalance(Item."No.", UnbalancedLocationCode), 'net quantity at the unbalanced location');
    end;

    [Test]
    procedure ImbalanceQueryIgnoresNormalEntries()
    var
        Item: Record Item;
    begin
        // [SCENARIO] Normal (non drop-ship) stock never shows up as a drop-ship imbalance

        // [GIVEN] An item with 10 units of normal stock and no drop-ship entries
        LibraryInventory.CreateItem(Item);
        TestLibrary.MockItemLedgerEntry(Item."No.", TestLibrary.NewLocationCode(), "Item Ledger Entry Type"::Purchase, 10, false);

        // [WHEN] / [THEN] The drop-ship tool returns nothing for the item
        Assert.AreEqual(0, CountDropShipImbalances(Item."No."), 'number of imbalanced locations');
    end;

    [Test]
    procedure NegativeInventoryQueryReturnsOpenNegativeQuantity()
    var
        Item: Record Item;
        NegativeInventory: Query "BCIA Negative Inventory API";
        LocationCode: Code[10];
    begin
        // [SCENARIO] The negative inventory tool sums open outbound entries that could not be applied

        // [GIVEN] Two open outbound entries of 3 and 2 at one location, and normal stock at another
        LibraryInventory.CreateItem(Item);
        LocationCode := TestLibrary.NewLocationCode();
        TestLibrary.MockOpenNegativeEntry(Item."No.", LocationCode, 3);
        TestLibrary.MockOpenNegativeEntry(Item."No.", LocationCode, 2);
        TestLibrary.MockItemLedgerEntry(Item."No.", TestLibrary.NewLocationCode(), "Item Ledger Entry Type"::Purchase, 10, false);

        // [WHEN] The tool is read for the item
        NegativeInventory.SetRange(itemNo, Item."No.");
        NegativeInventory.Open();

        // [THEN] One line is returned: the location with -5 from 2 entries
        Assert.IsTrue(NegativeInventory.Read(), 'a negative inventory line is expected');
        Assert.AreEqual(LocationCode, NegativeInventory.locationCode, 'location');
        Assert.AreEqual(-5, NegativeInventory.openNegativeQuantity, 'open negative quantity');
        Assert.AreEqual(2, NegativeInventory.entryCount, 'entry count');
        Assert.IsFalse(NegativeInventory.Read(), 'only one line is expected');
        NegativeInventory.Close();
    end;

    [Test]
    procedure NewFindingAlwaysStartsAsNew()
    var
        Finding: Record "BCIA Investigation Finding";
    begin
        // [SCENARIO] Even if a caller (the agent) sends another status, a new finding is always unreviewed

        // [GIVEN] A finding that arrives with status Done and a reviewer already filled in
        Finding.Init();
        Finding."Problem Type" := Finding."Problem Type"::DropShipment;
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
    procedure FindingWithoutProblemTypeIsRejected()
    var
        Finding: Record "BCIA Investigation Finding";
    begin
        // [SCENARIO] Every finding must say which problem it is about

        // [GIVEN] A finding without a problem type
        Finding.Init();
        Finding."Root Cause" := 'Test root cause';

        // [WHEN] It is inserted
        asserterror Finding.Insert(true);

        // [THEN] An error asks for the problem type
        Assert.ExpectedError('Specify the problem type');
    end;

    [Test]
    procedure AcceptRecordsReviewer()
    var
        Finding: Record "BCIA Investigation Finding";
    begin
        // [SCENARIO] Accepting a finding records who reviewed it and when

        // [GIVEN] A new negative inventory finding
        TestLibrary.CreateFinding(Finding, Finding."Problem Type"::NegativeInventory);

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
        Finding: Record "BCIA Investigation Finding";
    begin
        // [SCENARIO] A decision cannot be overwritten: a rejected finding cannot be accepted later

        // [GIVEN] A rejected finding
        TestLibrary.CreateFinding(Finding, Finding."Problem Type"::DropShipment);
        FindingReview.Reject(Finding);

        // [WHEN] Someone tries to accept it
        asserterror FindingReview.Accept(Finding);

        // [THEN] An error explains that only new findings can be reviewed
        Assert.ExpectedError('Only findings with status New');
    end;

    [Test]
    procedure OnlyAcceptedFindingCanBeMarkedDone()
    var
        Finding: Record "BCIA Investigation Finding";
    begin
        // [SCENARIO] A finding must be accepted before it can be marked as done

        // [GIVEN] A new, unreviewed finding
        TestLibrary.CreateFinding(Finding, Finding."Problem Type"::DropShipment);

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

    local procedure CountDropShipImbalances(ItemNo: Code[20]) Result: Integer
    var
        DropShipImbalance: Query "BCIA Drop Ship Imbalance API";
    begin
        DropShipImbalance.SetRange(itemNo, ItemNo);
        DropShipImbalance.Open();
        while DropShipImbalance.Read() do
            Result += 1;
        DropShipImbalance.Close();
    end;

    local procedure GetDropShipImbalance(ItemNo: Code[20]; LocationCode: Code[10]) NetQuantity: Decimal
    var
        DropShipImbalance: Query "BCIA Drop Ship Imbalance API";
    begin
        DropShipImbalance.SetRange(itemNo, ItemNo);
        DropShipImbalance.SetRange(locationCode, LocationCode);
        DropShipImbalance.Open();
        if DropShipImbalance.Read() then
            NetQuantity := DropShipImbalance.netQuantity;
        DropShipImbalance.Close();
    end;
}
