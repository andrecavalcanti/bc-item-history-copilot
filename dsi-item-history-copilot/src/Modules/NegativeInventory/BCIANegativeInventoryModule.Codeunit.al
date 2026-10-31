/// <summary>
/// Negative inventory module. An outbound entry that could not be applied to stock stays open with a
/// negative remaining quantity until a receipt covers it. Such entries mean inventory went below zero.
/// </summary>
codeunit 58007 "BCIA Negative Inventory Module" implements "BCIA Problem Module"
{
    Access = Public;

    var
        PromptRuleTxt: Label 'Negative inventory: checks.negativeInventory.locations lists each location with open outbound entries that could not be applied to stock, with openNegativeQuantity (always negative) and entryCount. Flag every listed location and suggest checking whether a shipment or consumption was posted before its receipt, or the receipt was posted at another location. If the list is empty, do not mention negative inventory unless asked.', Locked = true;

    procedure AddItemChecks(ItemNo: Code[20]; var Checks: JsonObject)
    var
        NegativeInventory: Query "BCIA Negative Inventory API";
        Locations: JsonArray;
        Section: JsonObject;
    begin
        NegativeInventory.SetRange(itemNo, ItemNo);
        NegativeInventory.Open();
        while NegativeInventory.Read() do
            Locations.Add(LocationToJson(NegativeInventory.locationCode, NegativeInventory.openNegativeQuantity, NegativeInventory.entryCount));
        NegativeInventory.Close();

        Section.Add('hasNegativeInventory', Locations.Count() > 0);
        Section.Add('locations', Locations);
        Checks.Add('negativeInventory', Section);
    end;

    procedure GetPromptRules(): Text
    begin
        exit(PromptRuleTxt);
    end;

    local procedure LocationToJson(LocationCode: Code[10]; OpenNegativeQuantity: Decimal; EntryCount: Integer) Line: JsonObject
    begin
        Line.Add('location', LocationCode);
        Line.Add('openNegativeQuantity', OpenNegativeQuantity);
        Line.Add('entryCount', EntryCount);
    end;
}
