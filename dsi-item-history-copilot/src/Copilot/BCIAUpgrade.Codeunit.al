codeunit 50101 "BCIA Upgrade"
{
    Subtype = Upgrade;
    Access = Internal;

    trigger OnUpgradePerDatabase()
    var
        CapabilityRegistration: Codeunit "BCIA Capability Registration";
    begin
        CapabilityRegistration.RegisterCapability();
    end;
}
