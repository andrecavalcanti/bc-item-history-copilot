/// <summary>
/// A root-cause finding proposed by the investigation agent, for any problem type.
/// The agent can only create records with status New. Reviewing, accepting and carrying out
/// the fix are done by a person; the agent never changes ledger entries or documents.
/// </summary>
table 50101 "BCIA Investigation Finding"
{
    Caption = 'BCIA Investigation Finding';
    DataClassification = CustomerContent;
    LookupPageId = "BCIA Investigation Findings";
    DrillDownPageId = "BCIA Investigation Findings";

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
        field(4; Quantity; Decimal)
        {
            Caption = 'Affected Quantity';
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
        field(8; Confidence; Enum "BCIA Finding Confidence")
        {
            Caption = 'Confidence';
        }
        field(9; Status; Enum "BCIA Finding Status")
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
        field(12; "Problem Type"; Enum "BCIA Problem Type")
        {
            Caption = 'Problem Type';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(ProblemItemLocation; "Problem Type", "Item No.", "Location Code", Status) { }
    }

    var
        ProblemTypeMissingErr: Label 'Specify the problem type of the finding.';

    trigger OnInsert()
    var
        FindingReview: Codeunit "BCIA Finding Review";
    begin
        // Every finding must say which kind of problem it is about.
        if "Problem Type" = "Problem Type"::" " then
            Error(ProblemTypeMissingErr);

        // A new finding always starts unreviewed, whatever the caller sent.
        Status := Status::New;
        Clear("Reviewed By");
        Clear("Reviewed At");
        FindingReview.LogFindingCreated(Rec);
    end;
}
