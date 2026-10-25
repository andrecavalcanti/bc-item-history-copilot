/// <summary>
/// A root-cause finding proposed by the drop-ship investigator agent.
/// The agent can only create records with status New. Reviewing, accepting and carrying out
/// the fix are done by a person; the agent never changes ledger entries or documents.
/// </summary>
table 50101 "DSI Drop Ship Finding"
{
    Caption = 'DSI Drop Ship Finding';
    DataClassification = CustomerContent;
    LookupPageId = "DSI Drop Ship Findings";
    DrillDownPageId = "DSI Drop Ship Findings";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(4; "Imbalance Qty."; Decimal)
        {
            Caption = 'Imbalance Qty.';
            DecimalPlaces = 0 : 5;
        }
        field(5; "Root Cause"; Text[2048])
        {
            Caption = 'Root Cause';
        }
        field(6; "Proposed Fix"; Text[2048])
        {
            Caption = 'Proposed Fix';
        }
        field(7; Evidence; Text[2048])
        {
            Caption = 'Evidence';
        }
        field(8; Confidence; Enum "DSI Finding Confidence")
        {
            Caption = 'Confidence';
        }
        field(9; Status; Enum "DSI Finding Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(10; "Reviewed By"; Code[50])
        {
            Caption = 'Reviewed By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(11; "Reviewed At"; DateTime)
        {
            Caption = 'Reviewed At';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ItemLocation; "Item No.", "Location Code", Status) { }
    }

    trigger OnInsert()
    var
        FindingReview: Codeunit "DSI Finding Review";
    begin
        // A new finding always starts unreviewed, whatever the caller sent.
        Status := Status::New;
        Clear("Reviewed By");
        Clear("Reviewed At");
        FindingReview.LogFindingCreated(Rec);
    end;
}
