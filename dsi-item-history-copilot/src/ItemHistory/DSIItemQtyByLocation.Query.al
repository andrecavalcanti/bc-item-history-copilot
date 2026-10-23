/// <summary>
/// Set-based totals per location and drop-ship flag for one item.
/// Lets AL do the arithmetic so the model never has to.
/// </summary>
query 50100 "DSI Item Qty By Location"
{
    Caption = 'DSI Item Qty By Location';
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    Access = Internal;

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            column(ItemNo; "Item No.") { }
            column(LocationCode; "Location Code") { }
            column(DropShipment; "Drop Shipment") { }
            column(Quantity; Quantity)
            {
                Method = Sum;
            }
            column(EntryCount)
            {
                Method = Count;
            }
        }
    }
}
