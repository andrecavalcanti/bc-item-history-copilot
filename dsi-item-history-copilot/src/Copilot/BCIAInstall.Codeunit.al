codeunit 50100 "BCIA Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerDatabase()
    var
        CapabilityRegistration: Codeunit "BCIA Capability Registration";
    begin
        CapabilityRegistration.RegisterCapability();
    end;
}
