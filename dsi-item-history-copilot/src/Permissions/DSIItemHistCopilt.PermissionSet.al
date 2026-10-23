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
        tabledata "Item Ledger Entry" = R;
}
