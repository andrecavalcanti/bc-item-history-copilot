codeunit 50100 "DSI Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerDatabase()
    var
        CapabilityRegistration: Codeunit "DSI Capability Registration";
    begin
        CapabilityRegistration.RegisterCapability();
    end;
}
