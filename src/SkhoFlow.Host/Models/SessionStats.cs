namespace SkhoFlow.Host.Models;

public sealed class SessionStats
{
    public string DeviceName { get; set; } = "";
    public int Fps { get; set; }
    public int LatencyMs { get; set; }
    public int BitrateKbps { get; set; }
    public int DroppedFrames { get; set; }
    public double UptimeSeconds { get; set; }
    public string Encoder { get; set; } = "";
    public string Resolution { get; set; } = "";
}
