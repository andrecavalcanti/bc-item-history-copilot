permissionset 50100 "DSI Item Hist Copilt"
{
    Caption = 'DSI Item History Copilot';
    Assignable = true;

    Permissions =
        tabledata "DSI Copilot Setup" = RIMD,
        table "DSI Copilot Setup" = X,
        page "DSI Copilot Setup" = X,
        page "DSI Explain Item History" = X,
        codeunit "DSI Item History Builder" = X,
        codeunit "DSI Item History AI" = X,
        codeunit "DSI Capability Registration" = X,
        query "DSI Item Qty By Location" = X,
        tabledata "Item Ledger Entry" = R,
        // Drop-ship investigator agent
        tabledata "DSI Drop Ship Finding" = RIM,
        table "DSI Drop Ship Finding" = X,
        tabledata "Sales Line" = R,
        tabledata "Purchase Line" = R,
        query "DSI Drop Ship Imbalance API" = X,
        page "DSI Drop Ship Entries API" = X,
        page "DSI Drop Ship Sales Lines API" = X,
        page "DSI Drop Ship Purch Lines API" = X,
        page "DSI Drop Ship Finding API" = X,
        page "DSI Drop Ship Findings" = X,
        codeunit "DSI Finding Review" = X;
}
