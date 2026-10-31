/// <summary>
/// Runs every registered problem module, so callers don't need to know which modules exist.
/// </summary>
codeunit 58009 "BCIA Problem Modules"
{
    Access = Public;

    /// <summary>
    /// Returns the checks of all modules for one item, each under its own key.
    /// </summary>
    procedure BuildItemChecks(ItemNo: Code[20]) Checks: JsonObject
    var
        ProblemModule: Interface "BCIA Problem Module";
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"BCIA Problem Type".Ordinals() do begin
            ProblemModule := Enum::"BCIA Problem Type".FromInteger(Ordinal);
            ProblemModule.AddItemChecks(ItemNo, Checks);
        end;
    end;

    /// <summary>
    /// Returns the prompt rules of all modules, one per line, each starting with "- ".
    /// </summary>
    procedure GetPromptRules() Rules: Text
    var
        ProblemModule: Interface "BCIA Problem Module";
        RulesBuilder: TextBuilder;
        Rule: Text;
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"BCIA Problem Type".Ordinals() do begin
            ProblemModule := Enum::"BCIA Problem Type".FromInteger(Ordinal);
            Rule := ProblemModule.GetPromptRules();
            if Rule <> '' then
                RulesBuilder.AppendLine('- ' + Rule);
        end;
        Rules := RulesBuilder.ToText();
    end;
}
