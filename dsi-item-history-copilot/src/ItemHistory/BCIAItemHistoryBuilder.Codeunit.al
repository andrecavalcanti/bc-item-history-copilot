/// <summary>
/// Builds the evidence JSON sent to the model. No AI calls here: this part is deterministic
/// and is the part to cover with AL Test Tool tests.
/// The general part (entries and totals) is built here; problem-specific checks come from the
/// problem modules (see enum "BCIA Problem Type"), under the "checks" key.
/// </summary>
codeunit 58002 "BCIA Item History Builder"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure BuildEvidence(ItemNo: Code[20]; MaxEntries: Integer) Output: Text
    var
        Result: JsonObject;
        Entries: JsonArray;
        EntriesShown: Integer;
        OlderEntriesOmitted: Boolean;
        ProblemModules: Codeunit "BCIA Problem Modules";
    begin
        if MaxEntries <= 0 then
            MaxEntries := 50;

        Entries := BuildRecentEntries(ItemNo, MaxEntries, EntriesShown, OlderEntriesOmitted);

        Result.Add('itemNo', ItemNo);
        Result.Add('entriesShown', EntriesShown);
        Result.Add('maxEntries', MaxEntries);
        Result.Add('olderEntriesOmitted', OlderEntriesOmitted);
        Result.Add('totals', BuildTotals(ItemNo));
        Result.Add('totalsByLocation', BuildTotalsByLocation(ItemNo));
        Result.Add('checks', ProblemModules.BuildItemChecks(ItemNo));
        Result.Add('entries', Entries);
        Result.WriteTo(Output);
    end;

    local procedure BuildRecentEntries(ItemNo: Code[20]; MaxEntries: Integer; var EntriesShown: Integer; var OlderEntriesOmitted: Boolean) Entries: JsonArray
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        HasMoreEntries: Boolean;
    begin
        ItemLedgerEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        ItemLedgerEntry.SetLoadFields("Entry No.", "Posting Date", "Entry Type", "Document Type",
            "Document No.", "Location Code", Quantity, "Remaining Quantity", "Drop Shipment", Open);
        ItemLedgerEntry.SetCurrentKey("Item No.", "Posting Date");
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.Ascending(false);
        if not ItemLedgerEntry.FindSet() then
            exit;

        repeat
            Entries.Add(EntryToJson(ItemLedgerEntry));
            EntriesShown += 1;
            HasMoreEntries := ItemLedgerEntry.Next() <> 0;
        until (not HasMoreEntries) or (EntriesShown >= MaxEntries);

        // Older entries are omitted only when another entry exists beyond the limit.
        OlderEntriesOmitted := HasMoreEntries;
    end;

    local procedure EntryToJson(ItemLedgerEntry: Record "Item Ledger Entry") Entry: JsonObject
    begin
        Entry.Add('entryNo', ItemLedgerEntry."Entry No.");
        Entry.Add('postingDate', ItemLedgerEntry."Posting Date");
        Entry.Add('entryType', Format(ItemLedgerEntry."Entry Type"));
        Entry.Add('documentType', Format(ItemLedgerEntry."Document Type"));
        Entry.Add('documentNo', ItemLedgerEntry."Document No.");
        Entry.Add('location', ItemLedgerEntry."Location Code");
        Entry.Add('quantity', ItemLedgerEntry.Quantity);
        Entry.Add('remainingQuantity', ItemLedgerEntry."Remaining Quantity");
        Entry.Add('open', ItemLedgerEntry.Open);
        Entry.Add('dropShipment', ItemLedgerEntry."Drop Shipment");
    end;

    local procedure BuildTotals(ItemNo: Code[20]) Totals: JsonObject
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.CalcSums(Quantity);
        Totals.Add('allEntries', ItemLedgerEntry.Quantity);

        ItemLedgerEntry.SetRange("Drop Shipment", true);
        ItemLedgerEntry.CalcSums(Quantity);
        Totals.Add('dropShipEntries', ItemLedgerEntry.Quantity);

        ItemLedgerEntry.SetRange("Drop Shipment", false);
        ItemLedgerEntry.CalcSums(Quantity);
        Totals.Add('normalEntries', ItemLedgerEntry.Quantity);
    end;

    local procedure BuildTotalsByLocation(ItemNo: Code[20]) Locations: JsonArray
    var
        QtyByLocation: Query "BCIA Item Qty By Location";
    begin
        QtyByLocation.SetRange(ItemNo, ItemNo);
        QtyByLocation.Open();
        while QtyByLocation.Read() do
            Locations.Add(LocationLineToJson(QtyByLocation.LocationCode, QtyByLocation.DropShipment,
                QtyByLocation.Quantity, QtyByLocation.EntryCount));
        QtyByLocation.Close();
    end;

    local procedure LocationLineToJson(LocationCode: Code[10]; DropShipment: Boolean; Quantity: Decimal; EntryCount: Integer) Line: JsonObject
    begin
        Line.Add('location', LocationCode);
        Line.Add('dropShipment', DropShipment);
        Line.Add('quantity', Quantity);
        Line.Add('entryCount', EntryCount);
    end;
}
