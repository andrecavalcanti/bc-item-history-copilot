permissionset 58000 "BCIA Investigation"
{
    Caption = 'BCIA Investigation Assistant';
    Assignable = true;

    Permissions =
        // Copilot: explain inventory history
        tabledata "BCIA Copilot Setup" = RIMD,
        table "BCIA Copilot Setup" = X,
        page "BCIA Copilot Setup" = X,
        page "BCIA Explain Item History" = X,
        codeunit "BCIA Item History Builder" = X,
        codeunit "BCIA Item History AI" = X,
        codeunit "BCIA Capability Registration" = X,
        query "BCIA Item Qty By Location" = X,
        tabledata "Item Ledger Entry" = R,
        // Investigation framework and modules
        codeunit "BCIA Problem Modules" = X,
        codeunit "BCIA No Problem Module" = X,
        codeunit "BCIA Drop Ship Module" = X,
        codeunit "BCIA Negative Inventory Module" = X,
        query "BCIA Drop Ship Imbalance API" = X,
        query "BCIA Negative Inventory API" = X,
        // Investigation agent: read tools, findings and review
        tabledata "BCIA Investigation Finding" = RIM,
        table "BCIA Investigation Finding" = X,
        tabledata "Sales Line" = R,
        tabledata "Purchase Line" = R,
        page "BCIA Item Entries API" = X,
        page "BCIA Drop Ship Sales Lines API" = X,
        page "BCIA Drop Ship Purch Lines API" = X,
        page "BCIA Investigation Finding API" = X,
        page "BCIA Investigation Findings" = X,
        codeunit "BCIA Finding Review" = X;
}
