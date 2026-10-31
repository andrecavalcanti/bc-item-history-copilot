/// <summary>
/// Read-only API query exposed to the agent as an MCP tool, and used by the negative inventory module.
/// Open outbound entries could not be applied to stock: inventory went below zero and no receipt has
/// covered it yet. Returns their remaining (negative) quantity per item and location.
/// </summary>
query 58002 "BCIA Negative Inventory API"
{
    QueryType = API;
    APIPublisher = 'andreCavalcanti';
    APIGroup = 'itemHistory';
    APIVersion = 'v1.0';
    EntityName = 'negativeInventoryLine';
    EntitySetName = 'negativeInventoryLines';
    Caption = 'BCIA Negative Inventory';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableFilter = Open = const(true), Positive = const(false);

            column(itemNo; "Item No.") { }
            column(locationCode; "Location Code") { }
            column(openNegativeQuantity; "Remaining Quantity")
            {
                Method = Sum;
            }
            column(entryCount)
            {
                Method = Count;
            }
        }
    }
}
