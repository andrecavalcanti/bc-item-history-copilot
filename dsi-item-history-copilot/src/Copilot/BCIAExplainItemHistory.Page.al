page 58003 "BCIA Explain Item History"
{
    Caption = 'Explain inventory history';
    PageType = PromptDialog;
    Extensible = false;
    IsPreview = true;
    PromptMode = Prompt;
    DataCaptionExpression = ItemNo;

    layout
    {
        area(Prompt)
        {
            field(UserQuestionField; UserQuestion)
            {
                ApplicationArea = All;
                ShowCaption = false;
                MultiLine = true;
                InstructionalText = 'Ask about this item''s inventory history, or leave blank for a summary.';
            }
        }
        area(Content)
        {
            field(AnswerField; AnswerText)
            {
                ApplicationArea = All;
                ShowCaption = false;
                MultiLine = true;
                Editable = false;
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(Generate)
            {
                Caption = 'Generate';
                ToolTip = 'Explain the inventory history with Copilot.';

                trigger OnAction()
                begin
                    RunGeneration();
                end;
            }
            systemaction(Regenerate)
            {
                Caption = 'Regenerate';
                ToolTip = 'Generate a new explanation.';

                trigger OnAction()
                begin
                    RunGeneration();
                end;
            }
            systemaction(OK)
            {
                Caption = 'Keep it';
                ToolTip = 'Close and keep the explanation.';
            }
            systemaction(Cancel)
            {
                Caption = 'Discard';
                ToolTip = 'Close without keeping the explanation.';
            }
        }
    }

    var
        ItemNo: Code[20];
        UserQuestion: Text;
        AnswerText: Text;

    procedure SetItem(NewItemNo: Code[20])
    begin
        ItemNo := NewItemNo;
    end;

    procedure GetAnswer(): Text
    begin
        exit(AnswerText);
    end;

    local procedure RunGeneration()
    var
        ItemHistoryAI: Codeunit "BCIA Item History AI";
    begin
        AnswerText := ItemHistoryAI.Explain(ItemNo, UserQuestion);
    end;
}
