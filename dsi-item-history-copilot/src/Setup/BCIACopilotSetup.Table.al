table 58000 "BCIA Copilot Setup"
{
    Caption = 'BCIA Copilot Setup';
    DataClassification = SystemMetadata;
    DataPerCompany = false;
    Access = Internal;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; Endpoint; Text[250])
        {
            Caption = 'Azure OpenAI Endpoint';
            ExtendedDatatype = URL;

            trigger OnValidate()
            begin
                Endpoint := NormalizeEndpoint(Endpoint);
            end;
        }
        field(3; Deployment; Text[100])
        {
            Caption = 'Deployment Name';
        }
        field(4; "Max Ledger Entries"; Integer)
        {
            Caption = 'Max Ledger Entries Sent';
            InitValue = 50;
            MinValue = 5;
            MaxValue = 200;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        ApiKeyStorageKeyTok: Label 'BCIA-AOAI-ApiKey', Locked = true;
        AzureDomainTok: Label '.azure.com', Locked = true;
        MissingSetupErr: Label 'Fill in the endpoint, deployment name and API key on the BCIA Copilot Setup page first.';

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;

    [NonDebuggable]
    procedure SetApiKey(NewApiKey: SecretText)
    begin
        if NewApiKey.IsEmpty() then begin
            if IsolatedStorage.Contains(ApiKeyStorageKeyTok, DataScope::Module) then
                IsolatedStorage.Delete(ApiKeyStorageKeyTok, DataScope::Module);
            exit;
        end;
        IsolatedStorage.Set(ApiKeyStorageKeyTok, NewApiKey, DataScope::Module);
    end;

    [NonDebuggable]
    procedure GetApiKey() ApiKey: SecretText
    begin
        if IsolatedStorage.Contains(ApiKeyStorageKeyTok, DataScope::Module) then
            IsolatedStorage.Get(ApiKeyStorageKeyTok, DataScope::Module, ApiKey);
    end;

    procedure HasApiKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(ApiKeyStorageKeyTok, DataScope::Module));
    end;

    procedure TestIsComplete()
    begin
        if (Endpoint = '') or (Deployment = '') or (not HasApiKey()) then
            Error(MissingSetupErr);
    end;

    /// <summary>
    /// Foundry shows the endpoint with a path (…azure.com/openai/…). The AI module needs only the base URL.
    /// </summary>
    local procedure NormalizeEndpoint(Value: Text[250]): Text[250]
    var
        DomainPos: Integer;
    begin
        Value := DelChr(Value, '<>', ' ');
        DomainPos := StrPos(LowerCase(Value), AzureDomainTok);
        if DomainPos > 0 then
            Value := CopyStr(Value, 1, DomainPos + StrLen(AzureDomainTok) - 1);
        if (Value <> '') and (not Value.EndsWith('/')) then
            Value += '/';
        exit(Value);
    end;
}
