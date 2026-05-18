using System;
using System.Text.Json.Serialization;

namespace SkhoFlow.Host.Models;

public sealed class PairedDevice
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString("N");

    [JsonPropertyName("name")]
    public string Name { get; set; } = "iPhone";

    [JsonPropertyName("model")]
    public string Model { get; set; } = "";

    [JsonPropertyName("publicKey")]
    public string PublicKeyBase64 { get; set; } = "";

    [JsonPropertyName("paired")]
    public DateTimeOffset PairedAt { get; set; } = DateTimeOffset.UtcNow;

    [JsonPropertyName("lastSeen")]
    public DateTimeOffset LastSeen { get; set; } = DateTimeOffset.UtcNow;

    [JsonIgnore]
    public bool IsOnline { get; set; }
}
