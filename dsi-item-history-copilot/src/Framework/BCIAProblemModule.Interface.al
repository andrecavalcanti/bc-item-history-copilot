/// <summary>
/// One investigable problem type (drop shipment, negative inventory, ...).
/// Each module adds its own facts to the Copilot evidence and explains to the model how to read them.
/// The rule stays the same for every module: AL calculates the facts, the model only explains them.
/// To add a problem type: create a codeunit that implements this interface and add a value to
/// enum "BCIA Problem Type" (the enum is extensible, so another app can add modules too).
/// </summary>
interface "BCIA Problem Module"
{
    /// <summary>
    /// Adds this module's checks for one item to the evidence, under its own key.
    /// </summary>
    procedure AddItemChecks(ItemNo: Code[20]; var Checks: JsonObject);

    /// <summary>
    /// Returns one rule for the Copilot system prompt that explains how to read this module's checks.
    /// Return an empty text when the module has nothing to add.
    /// </summary>
    procedure GetPromptRules(): Text;
}
