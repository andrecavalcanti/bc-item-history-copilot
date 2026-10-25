/// <summary>
/// How confident the agent is in its root-cause classification.
/// </summary>
enum 50102 "DSI Finding Confidence"
{
    Extensible = false;

    value(0; Low)
    {
        Caption = 'Low';
    }
    value(1; Medium)
    {
        Caption = 'Medium';
    }
    value(2; High)
    {
        Caption = 'High';
    }
}
