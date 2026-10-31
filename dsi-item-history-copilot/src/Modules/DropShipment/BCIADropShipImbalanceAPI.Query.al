/// <summary>
/// Read-only API query exposed to the agent as an MCP tool.
/// Returns item/location combinations where drop-ship item ledger entries do not net to zero.
/// The filter on netQuantity is applied to the summed value (HAVING), so balanced combinations are excluded in SQL.
/// </summary>
query 58001 "BCIA Drop Ship Imbalance API"
{
    QueryType = API;
    APIPublisher = 'andreCavalcanti';
    APIGroup = 'itemHistory';
    APIVersion = 'v1.0';
    EntityName = 'dropShipImbalance';
    EntitySetName = 'dropShipImbalances';
    Caption = 'BCIA Drop Ship Imbalances';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableFilter = "Drop Shipment" = const(true);

            column(itemNo; "Item No.") { }
            column(locationCode; "Location Code") { }
            column(netQuantity; Quantity)
            {
                Method = Sum;
                ColumnFilter = netQuantity = filter(<> 0);
            }
            column(entryCount)
            {
                Method = Count;
            }
        }
    }
}
