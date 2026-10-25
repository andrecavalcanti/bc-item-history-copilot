/// <summary>
/// Read-only API page exposed to the agent as an MCP tool.
/// Drop-ship item ledger entries with the order links the agent needs to trace a root cause.
/// </summary>
page 50104 "DSI Drop Ship Entries API"
{
    PageType = API;
    APIPublisher = 'andreCavalcanti';
    APIGroup = 'itemHistory';
    APIVersion = 'v1.0';
    EntityName = 'dropShipEntry';
    EntitySetName = 'dropShipEntries';
    Caption = 'DSI Drop Ship Entries';
    SourceTable = "Item Ledger Entry";
    SourceTableView = where("Drop Shipment" = const(true));
    ODataKeyFields = SystemId;
    DataAccessIntent = ReadOnly;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId) { }
                field(entryNo; Rec."Entry No.") { }
                field(itemNo; Rec."Item No.") { }
                field(postingDate; Rec."Posting Date") { }
                field(entryType; Rec."Entry Type") { }
                field(documentType; Rec."Document Type") { }
                field(documentNo; Rec."Document No.") { }
                field(documentLineNo; Rec."Document Line No.") { }
                field(locationCode; Rec."Location Code") { }
                field(quantity; Rec.Quantity) { }
                field(remainingQuantity; Rec."Remaining Quantity") { }
                field(isOpen; Rec.Open) { }
                field(sourceType; Rec."Source Type") { }
                field(sourceNo; Rec."Source No.") { }
                field(orderType; Rec."Order Type") { }
                field(orderNo; Rec."Order No.") { }
                field(orderLineNo; Rec."Order Line No.") { }
            }
        }
    }
}
