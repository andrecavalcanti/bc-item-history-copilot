pageextension 50100 "DSI Item Card" extends "Item Card"
{
    actions
    {
        addlast(Prompting)
        {
            action(DSIExplainHistory)
            {
                ApplicationArea = All;
                Caption = 'Explain inventory history';
                Image = Sparkle;
                ToolTip = 'Use Copilot to explain recent inventory movements for this item.';

                trigger OnAction()
                var
                    ExplainPage: Page "DSI Explain Item History";
                begin
                    ExplainPage.SetItem(Rec."No.");
                    ExplainPage.RunModal();
                end;
            }
        }
    }
}
