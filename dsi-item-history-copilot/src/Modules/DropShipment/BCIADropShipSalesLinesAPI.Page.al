/// <summary>
/// Read-only API page exposed to the agent as an MCP tool.
/// Open drop-ship sales order lines and the purchase order line each one is linked to.
/// </summary>
page 58005 "BCIA Drop Ship Sales Lines API"
{
    PageType = API;
    APIPublisher = 'andreCavalcanti';
    APIGroup = 'itemHistory';
    APIVersion = 'v1.0';
    EntityName = 'dropShipSalesLine';
    EntitySetName = 'dropShipSalesLines';
    Caption = 'BCIA Drop Ship Sales Lines';
    SourceTable = "Sales Line";
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
                field(sellToCustomerNo; Rec."Sell-to Customer No.") { }
                field(itemNo; Rec."No.") { }
                field(locationCode; Rec."Location Code") { }
                field(quantity; Rec.Quantity) { }
                field(quantityShipped; Rec."Quantity Shipped") { }
                field(quantityInvoiced; Rec."Quantity Invoiced") { }
                field(outstandingQuantity; Rec."Outstanding Quantity") { }
                field(purchaseOrderNo; Rec."Purchase Order No.") { }
                field(purchaseOrderLineNo; Rec."Purch. Order Line No.") { }
            }
        }
    }
}
