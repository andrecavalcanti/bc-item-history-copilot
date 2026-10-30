/// <summary>
/// Review status of a drop-ship finding. Agents can only create findings with status New;
/// every other status is set by a person on the BCIA Investigation Findings page.
/// </summary>
enum 50101 "BCIA Finding Status"
{
    Extensible = false;

    value(0; New)
    {
        Caption = 'New';
    }
    value(1; Accepted)
    {
        Caption = 'Accepted';
    }
    value(2; Rejected)
    {
        Caption = 'Rejected';
    }
    value(3; Done)
    {
        Caption = 'Done';
    }
}
