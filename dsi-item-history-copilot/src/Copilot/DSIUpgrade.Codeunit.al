codeunit 50101 "DSI Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerDatabase()
    var
        CapabilityRegistration: Codeunit "DSI Capability Registration";
    begin
        CapabilityRegistration.RegisterCapability();
    end;
}
