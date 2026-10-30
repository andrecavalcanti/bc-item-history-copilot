/// <summary>
/// Implementation for the blank problem type. Adds nothing, so the blank value is safe in loops.
/// </summary>
codeunit 50108 "BCIA No Problem Module" implements "BCIA Problem Module"
{
    Access = Internal;

    procedure AddItemChecks(ItemNo: Code[20]; var Checks: JsonObject)
    begin
    end;

    procedure GetPromptRules(): Text
    begin
        exit('');
    end;
}
