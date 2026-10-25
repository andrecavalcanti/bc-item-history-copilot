/// <summary>
/// Human review of agent findings: accept, reject or mark as done.
/// Kept separate from the pages so the rules can be tested with the AL Test Tool.
/// </summary>
codeunit 50105 "DSI Finding Review"
{
    Access = Public;
    Permissions = tabledata "DSI Drop Ship Finding" = rm;

    var
        OnlyNewCanBeReviewedErr: Label 'Only findings with status New can be accepted or rejected. Finding %1 has status %2.', Comment = '%1 = Entry No., %2 = Status';
        OnlyAcceptedCanBeDoneErr: Label 'Only accepted findings can be marked as done. Finding %1 has status %2.', Comment = '%1 = Entry No., %2 = Status';
        TelemetryCategoryTxt: Label 'DSI Drop Ship Agent', Locked = true;
        FindingCreatedTxt: Label 'Drop-ship finding created', Locked = true;
        FindingReviewedTxt: Label 'Drop-ship finding reviewed', Locked = true;

    procedure Accept(var Finding: Record "DSI Drop Ship Finding")
    begin
        if Finding.Status <> Finding.Status::New then
            Error(OnlyNewCanBeReviewedErr, Finding."Entry No.", Finding.Status);
        SetStatus(Finding, Finding.Status::Accepted);
    end;

    procedure Reject(var Finding: Record "DSI Drop Ship Finding")
    begin
        if Finding.Status <> Finding.Status::New then
            Error(OnlyNewCanBeReviewedErr, Finding."Entry No.", Finding.Status);
        SetStatus(Finding, Finding.Status::Rejected);
    end;

    procedure MarkDone(var Finding: Record "DSI Drop Ship Finding")
    begin
        if Finding.Status <> Finding.Status::Accepted then
            Error(OnlyAcceptedCanBeDoneErr, Finding."Entry No.", Finding.Status);
        SetStatus(Finding, Finding.Status::Done);
    end;

    procedure LogFindingCreated(Finding: Record "DSI Drop Ship Finding")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        // System metadata only: no item numbers, quantities or free text.
        CustomDimensions.Add('Category', TelemetryCategoryTxt);
        CustomDimensions.Add('Confidence', Format(Finding.Confidence, 0, 9));
        Session.LogMessage('DSI0101', FindingCreatedTxt, Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    local procedure SetStatus(var Finding: Record "DSI Drop Ship Finding"; NewStatus: Enum "DSI Finding Status")
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        Finding.Status := NewStatus;
        Finding."Reviewed By" := CopyStr(UserId(), 1, MaxStrLen(Finding."Reviewed By"));
        Finding."Reviewed At" := CurrentDateTime();
        Finding.Modify(true);

        CustomDimensions.Add('Category', TelemetryCategoryTxt);
        CustomDimensions.Add('NewStatus', Format(NewStatus, 0, 9));
        Session.LogMessage('DSI0102', FindingReviewedTxt, Verbosity::Normal, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;
}
