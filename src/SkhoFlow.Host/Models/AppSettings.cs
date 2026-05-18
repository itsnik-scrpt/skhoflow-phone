using System.Text.Json.Serialization;

namespace SkhoFlow.Host.Models;

public sealed class AppSettings
{
    [JsonPropertyName("hostName")]
    public string HostName { get; set; } = System.Environment.MachineName;

    [JsonPropertyName("startWithWindows")]
    public bool StartWithWindows { get; set; } = false;

    [JsonPropertyName("minimizeToTray")]
    public bool MinimizeToTray { get; set; } = true;

    [JsonPropertyName("requirePin")]
    public bool RequirePin { get; set; } = true;

    [JsonPropertyName("autoStartHosting")]
    public bool AutoStartHosting { get; set; } = true;

    [JsonPropertyName("stream")]
    public StreamSettings Stream { get; set; } = new();
}
