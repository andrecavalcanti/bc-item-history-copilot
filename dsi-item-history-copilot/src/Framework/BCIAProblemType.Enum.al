/// <summary>
/// The problem types the investigation framework knows about. Each value is backed by a module
/// that implements "BCIA Problem Module". Used by the Copilot evidence and by investigation findings.
/// Value names have no spaces because agents send them through the API (e.g. "DropShipment").
/// </summary>
enum 50103 "BCIA Problem Type" implements "BCIA Problem Module"
{
    Extensible = true;
    Caption = 'BCIA Problem Type';

    value(0; " ")
    {
        Caption = ' ', Locked = true;
        Implementation = "BCIA Problem Module" = "BCIA No Problem Module";
    }
    value(1; DropShipment)
    {
        Caption = 'Drop Shipment';
        Implementation = "BCIA Problem Module" = "BCIA Drop Ship Module";
    }
    value(2; NegativeInventory)
    {
        Caption = 'Negative Inventory';
        Implementation = "BCIA Problem Module" = "BCIA Negative Inventory Module";
    }
}
