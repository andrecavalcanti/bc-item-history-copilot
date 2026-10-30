/// <summary>
/// Drop shipment module. Drop-ship receipts and shipments are posted together, so drop-ship
/// item ledger entries must net to zero per item and location. Any other result is a problem.
/// </summary>
codeunit 50106 "BCIA Drop Ship Module" implements "BCIA Problem Module"
{
    Access = Public;

    var
        PromptRuleTxt: Label 'Drop shipment: drop-ship entries must net to zero per location. checks.dropShipment.unbalancedLocations lists each location where they do not, with its netQuantity. Flag every listed location and suggest checking the linked sales and purchase lines. If the list is empty, do not mention drop shipment unless asked.', Locked = true;

    procedure AddItemChecks(ItemNo: Code[20]; var Checks: JsonObject)
    var
        DropShipImbalance: Query "BCIA Drop Ship Imbalance API";
        UnbalancedLocations: JsonArray;
        Section: JsonObject;
    begin
        // The query only returns combinations whose sum is not zero (HAVING), so SQL does the check.
        DropShipImbalance.SetRange(itemNo, ItemNo);
        DropShipImbalance.Open();
        while DropShipImbalance.Read() do
            UnbalancedLocations.Add(LocationToJson(DropShipImbalance.locationCode, DropShipImbalance.netQuantity));
        DropShipImbalance.Close();

        Section.Add('balanced', UnbalancedLocations.Count() = 0);
        Section.Add('unbalancedLocations', UnbalancedLocations);
        Checks.Add('dropShipment', Section);
    end;

    procedure GetPromptRules(): Text
    begin
        exit(PromptRuleTxt);
    end;

    local procedure LocationToJson(LocationCode: Code[10]; NetQuantity: Decimal) Line: JsonObject
    begin
        Line.Add('location', LocationCode);
        Line.Add('netQuantity', NetQuantity);
    end;
}
