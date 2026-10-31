/// <summary>
/// How confident the agent is in its root-cause classification, for any problem type.
/// </summary>
enum 58002 "BCIA Finding Confidence"
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
