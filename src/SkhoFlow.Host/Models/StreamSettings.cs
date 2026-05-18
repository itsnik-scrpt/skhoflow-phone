using System.Text.Json.Serialization;

namespace SkhoFlow.Host.Models;

public enum VideoCodec { H264, H265, AV1 }
public enum EncoderKind { Auto, NVENC, AMF, QuickSync, Software }

public sealed class StreamSettings
{
    [JsonPropertyName("width")] public int Width { get; set; } = 1920;
    [JsonPropertyName("height")] public int Height { get; set; } = 1080;
    [JsonPropertyName("fps")] public int Fps { get; set; } = 60;
    [JsonPropertyName("bitrateKbps")] public int BitrateKbps { get; set; } = 20000;
    [JsonPropertyName("codec")] public VideoCodec Codec { get; set; } = VideoCodec.H264;
    [JsonPropertyName("encoder")] public EncoderKind Encoder { get; set; } = EncoderKind.Auto;
    [JsonPropertyName("hdr")] public bool Hdr { get; set; } = false;
    [JsonPropertyName("audioEnabled")] public bool AudioEnabled { get; set; } = true;
    [JsonPropertyName("audioBitrateKbps")] public int AudioBitrateKbps { get; set; } = 192;
    [JsonPropertyName("captureCursor")] public bool CaptureCursor { get; set; } = true;
    [JsonPropertyName("port")] public int Port { get; set; } = 47989;
    [JsonPropertyName("controlPort")] public int ControlPort { get; set; } = 47990;
}
