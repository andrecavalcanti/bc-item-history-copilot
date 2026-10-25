/// <summary>
/// Read-only API page exposed to the agent as an MCP tool.
/// Open drop-ship purchase order lines and the sales order line each one is linked to.
/// </summary>
page 50106 "DSI Drop Ship Purch Lines API"
{
    PageType = API;
    APIPublisher = 'andreCavalcanti';
    APIGroup = 'itemHistory';
    APIVersion = 'v1.0';
    EntityName = 'dropShipPurchaseLine';
    EntitySetName = 'dropShipPurchaseLines';
    Caption = 'DSI Drop Ship Purchase Lines';
    SourceTable = "Purchase Line";
    SourceTableView = where("Document Type" = const(Order), "Drop Shipment" = const(true));
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
                field(documentNo; Rec."Document No.") { }
                field(lineNo; Rec."Line No.") { }
                field(buyFromVendorNo; Rec."Buy-from Vendor No.") { }
                field(itemNo; Rec."No.") { }
                field(locationCode; Rec."Location Code") { }
                field(quantity; Rec.Quantity) { }
                field(quantityReceived; Rec."Quantity Received") { }
                field(quantityInvoiced; Rec."Quantity Invoiced") { }
                field(outstandingQuantity; Rec."Outstanding Quantity") { }
                field(salesOrderNo; Rec."Sales Order No.") { }
                field(salesOrderLineNo; Rec."Sales Order Line No.") { }
            }
        }
    }
}
