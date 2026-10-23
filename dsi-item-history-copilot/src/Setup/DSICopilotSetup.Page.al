page 50100 "DSI Copilot Setup"
{
    Caption = 'DSI Copilot Setup';
    PageType = Card;
    SourceTable = "DSI Copilot Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(AzureOpenAI)
            {
                Caption = 'Azure OpenAI (Foundry)';

                field(Endpoint; Rec.Endpoint)
                {
                    ToolTip = 'The base URL of your resource, for example https://myresource.openai.azure.com/. Anything after .azure.com is removed automatically.';
                }
                field(Deployment; Rec.Deployment)
                {
                    ToolTip = 'The deployment name you gave the model in Foundry.';
                }
                field(ApiKeyField; ApiKeyText)
                {
                    Caption = 'API Key';
                    ExtendedDatatype = Masked;
                    ToolTip = 'The API key from Foundry. It is stored in isolated storage, never in a table. Leave empty and confirm to remove the stored key.';

                    trigger OnValidate()
                    begin
                        Rec.SetApiKey(ApiKeyText);
                        ApiKeyText := GetKeyPlaceholder();
                    end;
                }
            }
            group(Limits)
            {
                Caption = 'Limits';

                field("Max Ledger Entries"; Rec."Max Ledger Entries")
                {
                    ToolTip = 'How many recent item ledger entries are sent to the model. Lower values use fewer tokens.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                Caption = 'Test Connection';
                Image = TestReport;
                ToolTip = 'Sends a short test prompt to your deployment.';

                trigger OnAction()
                var
                    ItemHistoryAI: Codeunit "DSI Item History AI";
                begin
                    CurrPage.SaveRecord();
                    ItemHistoryAI.TestConnection();
                end;
            }
            action(CopilotCapabilities)
            {
                Caption = 'Copilot & Agent Capabilities';
                Image = Setup;
                ToolTip = 'Open the page where admins activate or deactivate Copilot capabilities.';
                RunObject = page "Copilot AI Capabilities";
            }
        }
        area(Promoted)
        {
            actionref(TestConnection_Promoted; TestConnection) { }
            actionref(CopilotCapabilities_Promoted; CopilotCapabilities) { }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
        ApiKeyText := GetKeyPlaceholder();
    end;

    local procedure GetKeyPlaceholder(): Text
    begin
        if Rec.HasApiKey() then
            exit('********');
        exit('');
    end;

    var
        [NonDebuggable]
        ApiKeyText: Text;
}
