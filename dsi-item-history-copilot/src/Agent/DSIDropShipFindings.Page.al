/// <summary>
/// Where a person reviews the agent's findings and records the decision.
/// </summary>
page 50108 "DSI Drop Ship Findings"
{
    Caption = 'DSI Drop Ship Findings';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "DSI Drop Ship Finding";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Findings)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ToolTip = 'Specifies the number of the finding.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies whether the finding is new, accepted, rejected or done.';
                    StyleExpr = StatusStyle;
                }
                field("Item No."; Rec."Item No.")
                {
                    ToolTip = 'Specifies the item with the drop-ship imbalance.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ToolTip = 'Specifies the location with the drop-ship imbalance.';
                }
                field("Imbalance Qty."; Rec."Imbalance Qty.")
                {
                    ToolTip = 'Specifies the net quantity of drop-ship entries that should have been zero.';
                }
                field(Confidence; Rec.Confidence)
                {
                    ToolTip = 'Specifies how confident the agent is in its root cause.';
                }
                field("Root Cause"; Rec."Root Cause")
                {
                    ToolTip = 'Specifies the root cause proposed by the agent.';
                }
                field("Proposed Fix"; Rec."Proposed Fix")
                {
                    ToolTip = 'Specifies the fix proposed by the agent. A person must carry it out.';
                }
                field(Evidence; Rec.Evidence)
                {
                    ToolTip = 'Specifies the documents and entries the agent based its finding on.';
                }
                field(SystemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created At';
                    ToolTip = 'Specifies when the finding was created.';
                }
                field("Reviewed By"; Rec."Reviewed By")
                {
                    ToolTip = 'Specifies who reviewed the finding.';
                }
                field("Reviewed At"; Rec."Reviewed At")
                {
                    ToolTip = 'Specifies when the finding was reviewed.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Accept)
            {
                ApplicationArea = All;
                Caption = 'Accept';
                Image = Approve;
                ToolTip = 'Accept the finding. You then carry out the proposed fix yourself and mark it as done.';

                trigger OnAction()
                var
                    FindingReview: Codeunit "DSI Finding Review";
                begin
                    FindingReview.Accept(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Reject)
            {
                ApplicationArea = All;
                Caption = 'Reject';
                Image = Reject;
                ToolTip = 'Reject the finding because the root cause or fix is wrong.';

                trigger OnAction()
                var
                    FindingReview: Codeunit "DSI Finding Review";
                begin
                    FindingReview.Reject(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(MarkDone)
            {
                ApplicationArea = All;
                Caption = 'Mark as Done';
                Image = Completed;
                ToolTip = 'Mark an accepted finding as done after you have carried out the fix.';

                trigger OnAction()
                var
                    FindingReview: Codeunit "DSI Finding Review";
                begin
                    FindingReview.MarkDone(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ItemLedgerEntries)
            {
                ApplicationArea = All;
                Caption = 'Item Ledger Entries';
                Image = ItemLedger;
                ToolTip = 'Open the drop-ship item ledger entries for this item and location.';

                trigger OnAction()
                var
                    ItemLedgerEntry: Record "Item Ledger Entry";
                begin
                    ItemLedgerEntry.SetRange("Item No.", Rec."Item No.");
                    ItemLedgerEntry.SetRange("Location Code", Rec."Location Code");
                    ItemLedgerEntry.SetRange("Drop Shipment", true);
                    Page.Run(Page::"Item Ledger Entries", ItemLedgerEntry);
                end;
            }
        }
        area(Promoted)
        {
            actionref(Accept_Promoted; Accept) { }
            actionref(Reject_Promoted; Reject) { }
            actionref(MarkDone_Promoted; MarkDone) { }
            actionref(ItemLedgerEntries_Promoted; ItemLedgerEntries) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StatusStyle := GetStatusStyle();
    end;

    local procedure GetStatusStyle(): Text
    begin
        case Rec.Status of
            Rec.Status::New:
                exit('Attention');
            Rec.Status::Accepted:
                exit('Ambiguous');
            Rec.Status::Rejected:
                exit('Subordinate');
            Rec.Status::Done:
                exit('Favorable');
        end;
    end;

    var
        StatusStyle: Text;
}
