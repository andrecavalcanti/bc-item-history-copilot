/// <summary>
/// Shared helpers for the investigation tests: creating exact item ledger situations and findings.
/// </summary>
codeunit 50153 "BCIA Test Library"
{
    var
        LibraryUtility: Codeunit "Library - Utility";

    procedure MockItemLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10]; EntryType: Enum "Item Ledger Entry Type"; Qty: Decimal; DropShipment: Boolean)
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
        ItemLedgerEntry.Open := Qty > 0;
        if Qty > 0 then
            ItemLedgerEntry."Remaining Quantity" := Qty;
        // Test-only mock data: triggers are skipped on purpose to create exact ledger situations.
        ItemLedgerEntry.Insert();
    end;

    /// <summary>
    /// An outbound entry that could not be applied to stock: open, with a negative remaining quantity.
    /// </summary>
    procedure MockOpenNegativeEntry(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := ItemNo;
        ItemLedgerEntry."Location Code" := LocationCode;
        ItemLedgerEntry."Posting Date" := WorkDate();
        ItemLedgerEntry."Entry Type" := "Item Ledger Entry Type"::Sale;
        ItemLedgerEntry."Document No." := LibraryUtility.GenerateGUID();
        ItemLedgerEntry.Quantity := -Abs(Qty);
        ItemLedgerEntry."Remaining Quantity" := -Abs(Qty);
        ItemLedgerEntry.Positive := false;
        ItemLedgerEntry.Open := true;
        // Test-only mock data: triggers are skipped on purpose to create exact ledger situations.
        ItemLedgerEntry.Insert();
    end;

    procedure CreateFinding(var Finding: Record "BCIA Investigation Finding"; ProblemType: Enum "BCIA Problem Type")
    begin
        Finding.Init();
        Finding."Problem Type" := ProblemType;
        Finding.Quantity := 4;
        Finding."Root Cause" := 'Test root cause';
        Finding."Proposed Fix" := 'Test proposed fix';
        Finding.Confidence := Finding.Confidence::Medium;
        Finding.Insert(true);
    end;

    procedure NewLocationCode(): Code[10]
    begin
        exit(CopyStr(LibraryUtility.GenerateGUID(), 1, 10));
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
}
