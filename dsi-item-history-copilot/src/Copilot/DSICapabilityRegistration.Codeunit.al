/// <summary>
/// Single place that registers the Copilot capability.
/// Called from both the Install and Upgrade codeunits so new and existing installs behave the same.
/// </summary>
codeunit 50104 "DSI Capability Registration"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        LearnMoreUrlTxt: Label 'https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/ai-build-capability-in-al', Locked = true;

    procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"DSI Explain Item History") then
            exit;

        CopilotCapability.RegisterCapability(
            Enum::"Copilot Capability"::"DSI Explain Item History",
            Enum::"Copilot Availability"::Preview,
            Enum::"Copilot Billing Type"::"Custom Billed",
            LearnMoreUrlTxt);
    end;
}
