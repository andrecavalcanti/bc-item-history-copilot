pageextension 58000 "BCIA Item Card" extends "Item Card"
{
    actions
    {
        addlast(Prompting)
        {
            action(BCIAExplainHistory)
            {
                ApplicationArea = All;
                Caption = 'Explain inventory history';
                Image = Sparkle;
                ToolTip = 'Use Copilot to explain recent inventory movements for this item.';

                trigger OnAction()
                var
                    ExplainPage: Page "BCIA Explain Item History";
                begin
                    ExplainPage.SetItem(Rec."No.");
                    ExplainPage.RunModal();
                end;
            }
        }
    }
}
