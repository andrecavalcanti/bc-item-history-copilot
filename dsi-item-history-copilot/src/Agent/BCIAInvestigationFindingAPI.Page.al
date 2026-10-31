/// <summary>
/// API page exposed to the agent as an MCP tool.
/// Read and create only: the agent can list findings (to avoid duplicates) and propose new ones.
/// Modify and delete are not allowed here; status changes happen on the BCIA Investigation Findings page.
/// </summary>
page 58007 "BCIA Investigation Finding API"
{
    PageType = API;
    APIPublisher = 'andreCavalcanti';
    APIGroup = 'itemHistory';
    APIVersion = 'v1.0';
    EntityName = 'investigationFinding';
    EntitySetName = 'investigationFindings';
    Caption = 'BCIA Investigation Findings';
    SourceTable = "BCIA Investigation Finding";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId)
                {
                    Editable = false;
                }
                field(entryNo; Rec."Entry No.")
                {
                    Editable = false;
                }
                field(problemType; Rec."Problem Type") { }
                field(itemNo; Rec."Item No.") { }
                field(locationCode; Rec."Location Code") { }
                field(quantity; Rec.Quantity) { }
                field(rootCause; Rec."Root Cause") { }
                field(proposedFix; Rec."Proposed Fix") { }
                field(evidence; Rec.Evidence) { }
                field(confidence; Rec.Confidence) { }
                field(status; Rec.Status)
                {
                    Editable = false;
                }
                field(createdAt; Rec.SystemCreatedAt)
                {
                    Editable = false;
                }
            }
        }
    }
}
